#include "kernel/types.h"
#include "kernel/riscv.h"
#include "user/user.h"

int main(void) {
    printf("Running Test10-CoW\n");

    int npages = 5;
    void* heappages = sbrk(4096*npages);
    if (!heappages) {
        printf("\n[X] Heap memory allocation FAILED.\n");
        return -1;
    }

    int pid = fork(1);

    if(pid > 0) {
        // add a small delay in the parent process for a deterministic output
        for(int i = 0; i < 1000000000; i++);
    }

    printf("PID (%d) Exiting\n", getpid());

    return 0;
}