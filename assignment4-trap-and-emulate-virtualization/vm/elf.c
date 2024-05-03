#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "buf.h"
#include "elf.h"

#include <stdbool.h>

// Task: Read the ELF header, perform a sanity check, and return binary entry point
uint64 read_kernel_elf(void) {
    struct elfhdr elf;
    memmove((void*) &elf, (void*) RAMDISK, sizeof(elf));
    if(elf.magic != ELF_MAGIC)
        panic (NULL);
    return elf.entry;
}