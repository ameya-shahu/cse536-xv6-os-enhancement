#include "kernel/types.h"
#include "kernel/riscv.h"
#include "user/user.h"

void assert_heap(void* heappages, int npages, int multiplier) {
    int *a;
    int count = 0;
    for (int i = 0; i < npages; i++) {
        a = ((int*) (heappages + i*PGSIZE));
        for (int j = 0; j < PGSIZE/sizeof(int); j++) {
            if (*a != count * multiplier)
                goto fail;
            a++;
        }
        count++;
    }
return;

fail:
    printf("\nHeap Assertion Failed[X] (Pid = %d)\n", getpid());
    exit(1);
}

void write_heap(void* heappages, int npages, int multiplier) {
    int* a;
    int count = 0;
    for (int i = 0; i < npages; i++) {
        a = ((int*) (heappages + i*PGSIZE));
        for (int j = 0; j < PGSIZE/sizeof(int); j++) {
            *a = count * multiplier;
            a++;
        }
        count++;
    }
}

int main(void) {
    printf("Running Test8-CoW\n");

    int npages = 5;
    void* heappages = sbrk(4096*npages);
    if (!heappages) {
        printf("\n[X] Heap memory allocation FAILED.\n");
        return -1;
    }

    /* Write random numbers to the allocated heap regions. */
    // loads the heap pages into the parent process's memory
    write_heap(heappages, npages, 2);

    /* Assert heap memory correctness by checking the regions. */
    assert_heap(heappages, npages, 2);

    int pid = fork(1);

    if(pid == 0) {
        printf("\nTesting [PID = %d]\n", getpid());
        for(int i = 0; i < 1000000; i++);
        write_heap(heappages, npages, 2);
        assert_heap(heappages, npages, 2);

        int pid2 = fork(0);
        if(pid2 == 0) {
            int pid3 = fork(1);
            if(pid3 == 0) {
                printf("\nTesting [PID = %d]\n", getpid());
                write_heap(heappages, npages, 3);
                assert_heap(heappages, npages, 3);
                printf("\nCoW Test Passed [PID = %d]\n\n", getpid());
                exit(0);
            } else {
                wait(0);
                printf("\nTesting [PID = %d]\n", getpid());
                write_heap(heappages, npages, 4);
                assert_heap(heappages, npages, 4);
                printf("\nCoW Test Passed [PID = %d]\n\n", getpid());
                exit(0);
            }
        }
    } else {
        wait(0);
        printf("\nTesting [PID = %d]\n", getpid());
        write_heap(heappages, npages, 5);
        assert_heap(heappages, npages, 5);
    }

    wait(0);

    printf("\nCoW Test Passed [PID = %d]\n\n", getpid());
    return 0;
fail:
    printf("\nCoW Test Failed[X]\n");
    return 0;
}