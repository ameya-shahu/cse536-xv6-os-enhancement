#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "stdbool.h"
#include "stdlib.h"

#define REG_COUNT 40

// sret require registers
#define SSTATUS 8
#define SEPC 15

// mret require registers
#define MSTATUS 24
#define MEPC 32
#define STVEC 12

#define SATP 19
#define MACVENDORID 20

// pmp registers
#define PMPCFG0 38
#define PMPADDR0 39


// Struct to keep VM registers (Sample; feel free to change.)
struct vm_reg {
    int     code;
    int     mode;
    uint64  val;
};
typedef struct vm_reg vm_reg;

// Keep the virtual state of the VM's privileged registers
struct vm_virtual_state {
    // Register Array
    vm_reg reg_array[REG_COUNT];
    int priv_mode;
    bool is_pmp;
    pagetable_t vm_ptable;
};
typedef struct vm_virtual_state vm_virtual_state;
pagetable_t host_ptable = NULL;

vm_virtual_state vm_state;

void uvmcopy_copmp(pagetable_t old, pagetable_t new, uint64 sz){
  pte_t *pte;
  uint64 pa, i;
  uint flags;
 
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    mappages(new, i, PGSIZE, (uint64)pa, flags);
  }

  for(i = 0x80000000; i < 0x80400000; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    mappages(new, i, PGSIZE, (uint64)pa, flags);
    }
}

void sret_manager(struct proc *p){
    if(vm_state.priv_mode >= 1){
        unsigned long sstatus = vm_state.reg_array[SSTATUS].val;
        unsigned long spp_bit = (sstatus >> 8) & 0x1; // get SPP bit
        sstatus &= ~(1UL << 8); // Clear the SPP bit

        unsigned long spie_bit = (sstatus >> 5) & 0x1; // get the previous interrupt enable bit (spie)
        sstatus |= spie_bit << 1; // set SIE bit to SPIE
        sstatus &= ~(1UL << 5); // set SPIE bit to 1

        // set the current privilege level (priv) to spp
        if(spp_bit){
            vm_state.priv_mode = 1;
        }
        else{
            vm_state.priv_mode = 0;
        }

        vm_state.reg_array[SSTATUS].val = sstatus; // write sstatus register

        p->trapframe->epc = vm_state.reg_array[SEPC].val; // set the program count to the value of sepc
    }
    else{
        setkilled(p);
        
        trap_and_emulate_init();
    }
}

void mret_manager(struct proc *p){
    if(vm_state.priv_mode >= 2){
        unsigned long mstatus = vm_state.reg_array[MSTATUS].val;

        unsigned long int mpp = (mstatus >> 11) & 0x1; // Extract the previous privilege level (mpp)
        mstatus &= ~MSTATUS_MPP_MASK; // clear MPP bits

        unsigned long int mpie = (mstatus >> 7) & 0x1; // Extract the previous interrupt enable bit (MPIE) from mstatus

        mstatus |= mpie << 3; // set MIE bit to MPIE
        mstatus &= (1 << 0x7); // set MPIE bit to 1
        mstatus &= ~(1 << 0x17); // clear MPRV bit

        
        // set the current privilege level (priv) to mpp
        if(mpp){
            vm_state.priv_mode = 1;
        }
        else{
            vm_state.priv_mode = 0;
        }

        vm_state.reg_array[MSTATUS].val = mstatus; // write mstatus register

        p->trapframe->epc = vm_state.reg_array[MEPC].val; // set the program count to the value of mepc
    }
    else{
        setkilled(p);
        
        trap_and_emulate_init();
    }
    if(vm_state.is_pmp){
        vm_state.vm_ptable = proc_pagetable(p);
        uvmcopy_copmp(p->pagetable, vm_state.vm_ptable, p->sz);
        uvmunmap(vm_state.vm_ptable, 0x0000000080000000, 1, 0);
        p->pagetable = vm_state.vm_ptable;
    }
}

int find_csr(unsigned int uimm){
    for (int i = 0; i < REG_COUNT; i++) {
        if (vm_state.reg_array[i].code == uimm) {
            return i;
        }
    }
    return -1;
}

void csrr_manager(struct proc *p, unsigned int rs1, unsigned int rd, unsigned int uimm){
    int csr_idx = find_csr(uimm);
    if(csr_idx == -1) return;

    if(vm_state.priv_mode >= vm_state.reg_array[csr_idx].mode){
        uint32 csr_value = vm_state.reg_array[csr_idx].val;
        uint64* rd_reg_ptr = &(p->trapframe->ra) + rd - 1;
        *rd_reg_ptr = csr_value;    
    }
    else{
        setkilled(p);
        
        trap_and_emulate_init();
    }

    p->trapframe->epc += 4;
}


void csrw_manager(struct proc *p, unsigned int rs1, unsigned int rd, unsigned int uimm){
    int csr_idx = find_csr(uimm);
    if(csr_idx == -1) return;

    if(vm_state.priv_mode >= vm_state.reg_array[csr_idx].mode){
        uint64* rs1_ptr= &(p->trapframe->ra) + rs1 - 1;

        if((csr_idx == MACVENDORID) && (*rs1_ptr == 0x0)){ // invalid write operation for machineVendorId register
            setkilled(p);
            
            trap_and_emulate_init();
        }

        //If writing to PMP registers, enable pmp
        if((csr_idx == PMPADDR0) || (csr_idx == PMPCFG0)){
            vm_state.is_pmp = true;
        }

        vm_state.reg_array[csr_idx].val = *rs1_ptr;
    }else{
        setkilled(p);
        
        trap_and_emulate_init();
    }
    p->trapframe->epc += 4;
}

void ecall_manager(struct proc *p){
    vm_state.reg_array[SEPC].val = p->trapframe->epc;
    p->trapframe->epc = vm_state.reg_array[STVEC].val;
    vm_state.priv_mode = 1;
}


void trap_and_emulate(void) {
    /* Comes here when a VM tries to execute a supervisor instruction. */
    struct proc *p = myproc();

    uint64 virtual_addr = r_sepc();
    /* Retrieve all required values from the instruction */
    uint64 addr     = walkaddr(p->pagetable, virtual_addr) | (virtual_addr & 0xFFF);
    uint32 instruction = *((uint32*)(addr));
    uint32 op       = instruction & 0x7F;
    uint32 rd       = (instruction >> 7) & 0x1F;
    uint32 funct3   = (instruction >> 12) & 0x7;
    uint32 rs1      = (instruction >> 15) & 0x1F;
    uint32 uimm     = (instruction >> 20) & 0xFFF;

    if((funct3 == 0x0) && (uimm == 0)){
        printf("(EC at %p)\n", p->trapframe->epc);
        ecall_manager(p);
    }
    else{
        printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
        virtual_addr, op, rd, funct3, rs1, uimm);

        if((funct3 == 0x0) && (uimm == 0x102)){
            sret_manager(p);
        } 
        else if((funct3 == 0x0) && (uimm == 0x302)){
            mret_manager(p);
        }
        else if(funct3 == 0x1){
            csrw_manager(p, rs1, rd, uimm);
        }
        else if(funct3 == 0x2){
            csrr_manager(p, rs1, rd, uimm);
        }
        else{
            printf("Instruction is not correct.\n");
            setkilled(p);
            host_ptable = NULL;
            trap_and_emulate_init();
        }
    }
}

void trap_and_emulate_init(void) {
    /* Create and initialize all state for the VM */
    vm_state.is_pmp = false;

    // User trap init
    vm_state.reg_array[0] = (vm_reg){.code = 0x000, .mode = 0, .val = 0};
    vm_state.reg_array[1] = (vm_reg){.code = 0x004, .mode = 0, .val = 0};
    vm_state.reg_array[2] = (vm_reg){.code = 0x005, .mode = 0, .val = 0};

    // User trap handling init
    vm_state.reg_array[3] = (vm_reg){.code = 0x040, .mode = 0, .val = 0};
    vm_state.reg_array[4] = (vm_reg){.code = 0x041, .mode = 0, .val = 0};
    vm_state.reg_array[5] = (vm_reg){.code = 0x042, .mode = 0, .val = 0};
    vm_state.reg_array[6] = (vm_reg){.code = 0x043, .mode = 0, .val = 0};
    vm_state.reg_array[7] = (vm_reg){.code = 0x044, .mode = 0, .val = 0};

    // Supervisor trap setup init
    vm_state.reg_array[8] = (vm_reg){.code = 0x100, .mode = 1, .val = 0};
    vm_state.reg_array[9] = (vm_reg){.code = 0x102, .mode = 1, .val = 0};
    vm_state.reg_array[10] = (vm_reg){.code = 0x103, .mode = 1, .val = 0};
    vm_state.reg_array[11] = (vm_reg){.code = 0x104, .mode = 1, .val = 0};
    vm_state.reg_array[12] = (vm_reg){.code = 0x105, .mode = 1, .val = 0};
    vm_state.reg_array[13] = (vm_reg){.code = 0x106, .mode = 1, .val = 0};


    // Supervisor trap handling init
    vm_state.reg_array[14] = (vm_reg){.code = 0x140, .mode = 1, .val = 0};
    vm_state.reg_array[15] = (vm_reg){.code = 0x141, .mode = 1, .val = 0};
    vm_state.reg_array[16] = (vm_reg){.code = 0x142, .mode = 1, .val = 0};
    vm_state.reg_array[17] = (vm_reg){.code = 0x143, .mode = 1, .val = 0};
    vm_state.reg_array[18] = (vm_reg){.code = 0x144, .mode = 1, .val = 0};

    // Supervisor page table register
    vm_state.reg_array[19] = (vm_reg){.code = 0x180, .mode = 1, .val = 0};


    // Machine information registers init
    vm_state.reg_array[20] = (vm_reg){.code = 0xf11, .mode = 1, .val = 0x637365353336}; // hexa code for CSE536
    vm_state.reg_array[21] = (vm_reg){.code = 0xf12, .mode = 2, .val = 0};
    vm_state.reg_array[22] = (vm_reg){.code = 0xf13, .mode = 2, .val = 0};
    vm_state.reg_array[23] = (vm_reg){.code = 0xf14, .mode = 2, .val = 0};

    // Machine trap setup registers init
    vm_state.reg_array[24] = (vm_reg){.code = 0x300, .mode = 2, .val = 0};
    vm_state.reg_array[25] = (vm_reg){.code = 0x301, .mode = 2, .val = 0};
    vm_state.reg_array[26] = (vm_reg){.code = 0x302, .mode = 2, .val = 0};
    vm_state.reg_array[27] = (vm_reg){.code = 0x303, .mode = 2, .val = 0};
    vm_state.reg_array[28] = (vm_reg){.code = 0x304, .mode = 2, .val = 0};
    vm_state.reg_array[29] = (vm_reg){.code = 0x305, .mode = 2, .val = 0};
    vm_state.reg_array[30] = (vm_reg){.code = 0x306, .mode = 2, .val = 0};

    // Machine trap handling registers init
    vm_state.reg_array[31] = (vm_reg){.code = 0x340, .mode = 2, .val = 0};
    vm_state.reg_array[32] = (vm_reg){.code = 0x341, .mode = 2, .val = 0};
    vm_state.reg_array[33] = (vm_reg){.code = 0x342, .mode = 2, .val = 0};
    vm_state.reg_array[34] = (vm_reg){.code = 0x343, .mode = 2, .val = 0};
    vm_state.reg_array[35] = (vm_reg){.code = 0x344, .mode = 2, .val = 0};
    vm_state.reg_array[36] = (vm_reg){.code = 0x34a, .mode = 2, .val = 0};
    vm_state.reg_array[37] = (vm_reg){.code = 0x34b, .mode = 2, .val = 0};
    
    // pmp register init
    vm_state.reg_array[38] = (vm_reg){.code = 0x3a0, .mode = 2, .val = 0};
    vm_state.reg_array[39] = (vm_reg){.code = 0x3b0, .mode = 2, .val = 0};

    vm_state.priv_mode = 2;
    vm_state.vm_ptable = NULL;
}
