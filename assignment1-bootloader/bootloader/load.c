//
// ramdisk that uses the disk image loaded by qemu -initrd fs.img
//

#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "layout.h"
#include "buf.h"

/* In-built function to load NORMAL/RECOVERY kernels */
void kernel_copy(enum kernel ktype, struct buf *b)
{
  if(b->blockno >= FSSIZE)
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
  char* addr = 0x0; 
  
  if (ktype == NORMAL)
    addr = (char *)RAMDISK + diskaddr;
  else if (ktype == RECOVERY)
    addr = (char *)RECOVERYDISK + diskaddr;

  memmove(b->data, addr, BSIZE);
  b->valid = 1;
}