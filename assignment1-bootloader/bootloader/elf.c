#include "types.h"
#include "param.h"
#include "layout.h"
#include "riscv.h"
#include "defs.h"
#include "buf.h"
#include "elf.h"

#include <stdbool.h>

struct elfhdr* kernel_elfhdr;
struct proghdr* kernel_phdr;

uint64 find_kernel_load_addr(enum kernel ktype) {
    /* CSE 536: Get kernel load address from headers */
    kernel_elfhdr = (ktype == NORMAL) ? (struct elfhdr *)RAMDISK : (struct elfhdr *)RECOVERYDISK;
    kernel_phdr = (struct proghdr *)( ((char *)kernel_elfhdr) + kernel_elfhdr->phoff + kernel_elfhdr->phentsize);
    return kernel_phdr->vaddr;
}

uint64 find_kernel_size(enum kernel ktype) {
    /* CSE 536: Get kernel binary size from headers */
    kernel_elfhdr = (ktype == NORMAL) ? (struct elfhdr *)RAMDISK : (struct elfhdr *)RECOVERYDISK;
    return (kernel_elfhdr->shoff + (kernel_elfhdr->shentsize*kernel_elfhdr->shnum));
}

uint64 find_kernel_entry_addr(enum kernel ktype) {
    /* CSE 536: Get kernel entry point from headers */
    kernel_elfhdr = (ktype == NORMAL) ? (struct elfhdr *)RAMDISK : (struct elfhdr *)RECOVERYDISK;
    return kernel_elfhdr->entry;
}

/* To get the off position of kernel binary*/
uint64 find_kernel_off(enum kernel ktype){
    kernel_elfhdr = (ktype == NORMAL) ? (struct elfhdr *)RAMDISK : (struct elfhdr *)RECOVERYDISK;
    kernel_phdr = (struct proghdr *)( ((char *)kernel_elfhdr) + kernel_elfhdr->phoff + kernel_elfhdr->phentsize);
    return kernel_phdr->off;
}
