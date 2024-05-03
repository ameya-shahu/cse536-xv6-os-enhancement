/* These files have been taken from the open-source xv6 Operating System codebase (MIT License).  */

#include "types.h"
#include "param.h"
#include "layout.h"
#include "riscv.h"
#include "defs.h"
#include "buf.h"
#include "measurements.h"
#include <stdbool.h>


void main();
void timerinit();

/* entry.S needs one stack per CPU */
__attribute__ ((aligned (16))) char bl_stack[STSIZE * NCPU];

/* Context (SHA-256) for secure boot */
SHA256_CTX sha256_ctx;

/* Structure to collects system information */
struct sys_info {
  /* Bootloader binary addresses */
  uint64 bl_start;
  uint64 bl_end;
  /* Accessible DRAM addresses (excluding bootloader) */
  uint64 dr_start;
  uint64 dr_end;
  /* Kernel SHA-256 hashes */
  BYTE expected_kernel_measurement[32];
  BYTE observed_kernel_measurement[32];
};
struct sys_info* sys_info_ptr;

extern void _entry(void);
void panic(char *s)
{
  for(;;)
    ;
}

/* CSE 536: Boot into the RECOVERY kernel instead of NORMAL kernel
 * when hash verification fails. */
void setup_recovery_kernel(void) {
  uint64 kernel_load_addr       = find_kernel_load_addr(RECOVERY);
  uint64 kernel_binary_size     = find_kernel_size(RECOVERY);     
  uint64 kernel_entry           = find_kernel_entry_addr(RECOVERY);
  uint64 kernel_frm_off 	= find_kernel_off(RECOVERY);
  
  uint64 bytes_cpy = 0; // Counter to track size copied in main memory
  while(bytes_cpy < kernel_binary_size){
  
    /* Create temporary buffer */
    struct buf temp_buff = {};
    temp_buff.blockno = (kernel_frm_off + bytes_cpy) / BSIZE;
  	
    /* Copy kernel from disk to buffer */		
    kernel_copy(RECOVERY,&temp_buff);
    
    /* Copy kernel of BSIZE or in last run remaining size to main memory */
    uint64 copy_size = BSIZE < (kernel_binary_size - bytes_cpy) ? BSIZE : (kernel_binary_size - bytes_cpy);	
    memmove((void*)(kernel_load_addr + bytes_cpy), temp_buff.data, copy_size);
    
    bytes_cpy+=copy_size;
  }
  w_mepc((uint64) kernel_entry);
}

/* CSE 536: Function verifies if NORMAL kernel is expected or tampered. */
bool is_secure_boot(void) {
  uint64 kernel_binary_size     = find_kernel_size(NORMAL);
  bool verification = true;

  /* Read the binary and update the observed measurement 
   * (simplified template provided below) */
  sha256_init(&sha256_ctx);
  sha256_update(&sha256_ctx, (const unsigned char*) RAMDISK, kernel_binary_size);
  sha256_final(&sha256_ctx, sys_info_ptr->observed_kernel_measurement);

  /* Three more tasks required below: 
   *  1. Compare observed measurement with expected hash
   *  2. Setup the recovery kernel if comparison fails
   *  3. Copy expected kernel hash to the system information table */
   for(uint64 idx = 0; idx <32; idx++){
   	if(verification && (sys_info_ptr->observed_kernel_measurement[idx] != trusted_kernel_hash[idx])){
  	  verification = false;
   	}
   	//verification = (verification && (sys_info_ptr->observed_kernel_measurement[idx] == trusted_kernel_hash[idx]));
   	sys_info_ptr->expected_kernel_measurement[idx] = trusted_kernel_hash[idx];
   }
   
  if (!verification)
    setup_recovery_kernel();
  
  return verification;
}

// entry.S jumps here in machine mode on stack0.
void start()
{
  /* CSE 536: Define the system information table's location. */
  sys_info_ptr = (struct sys_info*) 0x80080000;

  // keep each CPU's hartid in its tp register, for cpuid().
  int id = r_mhartid();
  w_tp(id);

  // set M Previous Privilege mode to Supervisor, for mret.
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
  x |= MSTATUS_MPP_S;
  w_mstatus(x);

  // disable paging
  w_satp(0);

  /* CSE 536: Unless kernelpmp[1-2] booted, allow all memory 
   * regions to be accessed in S-mode. */ 
  #if !defined(KERNELPMP1) || !defined(KERNELPMP2)
    w_pmpaddr0(0x3fffffffffffffull);
    w_pmpcfg0(0xf);
  #endif

  /* CSE 536: With kernelpmp1, isolate upper 10MBs using TOR */ 
  #if defined(KERNELPMP1)
    w_pmpaddr0((KERNBASE + 117*1024*1024)>>2); // RWX accessible region from start location to start location +117MB
    w_pmpcfg0(0xf); // TOR config with RWX set (1111)
  #endif

  /* CSE 536: With kernelpmp2, isolate 118-120 MB and 122-126 MB using NAPOT */ 
  #if defined(KERNELPMP2)
    w_pmpaddr0((KERNBASE + 118*1024*1024)>>2); // RWX accessible region from start location to start location +118MB)
   
   
    w_pmpaddr1(((KERNBASE + 120*1024*1024)>>2) + ((2*1024*1024)>>3) - 1); // RWX accessible region start address from (start location + 120MB) to start address + 2MB
    
  
   w_pmpaddr2(((KERNBASE + 126*1024*1024)>>2) + ((2*1024*1024)>>3) - 1); // RWX accessible region start address from (start location + 122MB) to start address + 2MB
   
   w_pmpcfg0(0x1f1f0f); // NAPOT config with RWX bit set for pmp2cfg = 0001111, pmp1cfg=00011111 and TOR config with RWX bit set for pmp0cfg = 00001111
  #endif

  /* CSE 536: Verify if the kernel is untampered for secure boot */
  if (!is_secure_boot()) {
    /* Skip loading since we should have booted into a recovery kernel 
     * in the function is_secure_boot() */
    goto out;
  }
  
  /* CSE 536: Load the NORMAL kernel binary (assuming secure boot passed). */
  uint64 kernel_load_addr       = find_kernel_load_addr(NORMAL);
  uint64 kernel_binary_size     = find_kernel_size(NORMAL);     
  uint64 kernel_entry           = find_kernel_entry_addr(NORMAL);
  uint64 kernel_frm_off 	= find_kernel_off(NORMAL);
  
  uint64 bytes_cpy = 0; // Counter to track size copied in main memory
  while(bytes_cpy < kernel_binary_size){
    /* Create temporary buffer */
    struct buf temp_buff = {};
    temp_buff.blockno = (kernel_frm_off + bytes_cpy) / BSIZE;
    
    /* Copy kernel from disk to buffer */	
    kernel_copy(NORMAL,&temp_buff);
    uint64 copy_size = BSIZE < (kernel_binary_size - bytes_cpy) ? BSIZE : (kernel_binary_size - bytes_cpy);
    
    /* Copy kernel of BSIZE or in last run remaining size to main memory */	
    memmove((void*)(kernel_load_addr + bytes_cpy), temp_buff.data, copy_size);
    bytes_cpy+=copy_size;
  }
  /* CSE 536: Write the correct kernel entry point */
  w_mepc((uint64) kernel_entry);
 
 out:
  /* CSE 536: Provide system information to the kernel. */
  sys_info_ptr->bl_start = 0x80000000;
  sys_info_ptr->bl_end = end;
  sys_info_ptr->dr_start = KERNBASE;
  sys_info_ptr->dr_end = PHYSTOP;

  /* CSE 536: Send the observed hash value to the kernel (using sys_info_ptr) */

  // delegate all interrupts and exceptions to supervisor mode.
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);

  // return address fix
  uint64 addr = (uint64) panic;
  asm volatile("mv ra, %0" : : "r" (addr));

  // switch to supervisor mode and jump to main().
  asm volatile("mret");
}
