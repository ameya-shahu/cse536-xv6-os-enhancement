#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

#include "user/ulthread.h"
#include <stdarg.h>

/* Stack region for different threads */
char stacks[PGSIZE*MAXULTHREADS];

/* Simple example that allocates heap memory and accesses it. */
void ul_start_func(void) {
    /* Start the thread here. */
    for (int i = 0; i < 1000; i++);

    printf("[.] started the thread function (tid = %d) \n", get_current_tid());

    /* Notify for a thread exit. */
    ulthread_destroy();
}

int
main(int argc, char *argv[])
{
    /* Clear the stack region */
    memset(&stacks, 0, sizeof(stacks));

    /* Initialize the user-level threading library */
    ulthread_init(ROUNDROBIN);

    /* Create a user-level thread */
    uint64 args[6] = {0,0,0,0,0,0};    
    ulthread_create((uint64) ul_start_func, (uint64) stacks+PGSIZE, args, -1);

    /* Schedule some of the threads */
    ulthread_schedule();

    printf("[*] User-Level Threading Test #1 Complete.\n");
    return 0;
}
