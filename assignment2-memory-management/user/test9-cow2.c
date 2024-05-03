#include "kernel/types.h"
#include "kernel/riscv.h"
#include "user/user.h"

int main(void) {
    printf("Running Test9-CoW\n");

    int npages = 5;
    void* heappages = sbrk(4096*npages);
    if (!heappages) {
        printf("\n[X] Heap memory allocation FAILED.\n");
        return -1;
    }

    fork(1);
    wait(0);

    printf("PID (%d) Exiting\n", getpid());

    return 0;
}