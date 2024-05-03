#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "buf.h"
#include "proc.h"

#include <stdbool.h>

// entry.S needs one stack per CPU.
__attribute__ ((aligned (16))) char ustack[STSIZE * NCPU];
__attribute__ ((aligned (16))) char kstack[STSIZE * NCPU];

// our unikernel has a single process.
struct proc p;

// kernel allocator routines
#define KMEMSTART 0x80000000
#define KMEMSIZE  1024
int alloc_pages = 0;

void usertrapret(void);

// simple page-by-page memory allocator
void* kalloc(void) {
    if (alloc_pages == KMEMSIZE) {
        panic("panic!");
    }
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
    alloc_pages++;
    return (void*) addr;
}

void usertrap(void) {
  /* traps here when back from the userspace code. */
  p.trapframe->epc = r_sepc() + 4;
  usertrapret();
}

void usertrapret(void) {
    // Set-up for process entry and exit
    p.trapframe->kernel_sp = (uint64) kstack+PGSIZE;

    // Set return trap location
    p.trapframe->kernel_trap = (uint64) usertrap;
    w_stvec((uint64) p.trapframe->kernel_trap);

    // Save hart id
    p.trapframe->kernel_hartid = r_tp();

    // set S Previous Privilege mode to User.
    unsigned long x = r_sstatus();
    x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    x |= SSTATUS_SPIE; // enable interrupts in user mode
    w_sstatus(x);

    // Set entry location
    w_sepc((uint64) p.trapframe->epc);

    asm("sret");
}

// Creates the user-level process and sets-up initial
void create_process(void) {
    // allocate trapframe memory
    p.trapframe = (struct trapframe*) kalloc();

    // entry point
    p.trapframe->epc = (uint64) process_entry;

    // initial stack values
    p.trapframe->a1 = (uint64) ustack+PGSIZE;

    // usertrapret
    usertrapret();
}

void kernel_entry(void) {
  create_process();

  /* Nothing to go back to */
  while (true);
}
