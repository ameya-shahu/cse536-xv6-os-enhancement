# _entry should be the first function invoked when
# the QEMU CPU starts executing. It's location should
# according to the memory layout provided in param.h

.section .text
.global _entry
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + (hartid * 4096)
        la sp, stack0
        li a0, 1024*4
        csrr a1, mhartid
        addi a1, a1, 1
        mul a0, a0, a1
        add sp, sp, a0
        # jump to start() in start.c
        call start

.global _entry_kernel
_entry_kernel:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + (hartid * 4096)
        # jump to start() in start.c
        call main

.global _entry_test
_entry_test:
        # task: setup a per-CPU stack for C and jump to start() function

        # t1. use the stack0 region allocated in the start.c file as the
        # current CPU's stack pointer (sp)

        # t2. find the stack size from param.h and set correct stack
        # starting position (or sp) for each CPU. 
        # hints: a. current cpu id is stored in the 'mhartid' reg 
        #        b. current cpu sp is stack0 + (hartid * stacksize)

        # t3. jump to the start() function in start.c

spin:
        j spin
