/* This file contains code for a generic page fault handler for processes. */
#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "elf.h"

#include "sleeplock.h"
#include "fs.h"
#include "buf.h"

int loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz);
int flags2perm(int flags);

/* CSE 536: (2.4) read current time. */
uint64 read_current_timestamp() {
  uint64 curticks = 0;
  acquire(&tickslock);
  curticks = ticks;
  wakeup(&ticks);
  release(&tickslock);
  return curticks;
}

bool psa_tracker[PSASIZE];

/* All blocks are free during initialization. */
void init_psa_regions(void)
{
    for (int i = 0; i < PSASIZE; i++) 
        psa_tracker[i] = false;
}

/* Evict heap page to disk when resident pages exceed limit */
void evict_page_to_disk(struct proc* p) {
    /* Find free block */
    int blockno = -1;
    
    for(int i = 0; i < (PSASIZE - 4); i++){
      bool isEmptyBlocks = (psa_tracker[i] == false) 
                      && (psa_tracker[i+1] == false) 
                      && (psa_tracker[i+2] == false)  
                      && (psa_tracker[i+3] == false);
                                   
      if(isEmptyBlocks){
        blockno = i;
        break;
      }
    }
    
    if(blockno == -1) 
      panic("No Contiguous PSA block available");
      
      
    /* Find victim page using FIFO. */
    int heap_victim_idx = -1;
    uint64 min_load_time = 0xFFFFFFFFFFFFFFFF; // set all bits to 1 as max value
    
    for(int i = 0; i < MAXHEAP; i++){
      bool isValidHeap = (p->heap_tracker[i].addr != 0xFFFFFFFFFFFFFFFF)
                        && (p->heap_tracker[i].loaded == 0)
                        && (p->heap_tracker[i].startblock == -1);
                        
      if(isValidHeap){
        if(min_load_time > p->heap_tracker[i].last_load_time){
          heap_victim_idx = i;
          min_load_time = p->heap_tracker[i].last_load_time;
        }
      }
    }
    
    if(heap_victim_idx == -1)
      panic("Something went wrong in FIFO algorithm.");
      
    
    
    /* Print statement. */
    print_evict_page(p->heap_tracker[heap_victim_idx].addr, blockno);
    
    /* Read memory from the user to kernel memory first. */
    void *copy_user_block = kalloc();
    copyin(p->pagetable, copy_user_block, p->heap_tracker[heap_victim_idx].addr, PGSIZE);
    
    /* Write to the disk blocks. Below is a template as to how this works. There is
     * definitely a better way but this works for now. :p */
     
    for(int i= 0; i < 4; i++){
      struct buf* b;
      b = bread(1, PSASTART+(blockno + i));
      // Copy page contents to b.data using memmove.
      memmove(b->data, copy_user_block + (i * BSIZE), BSIZE);
      bwrite(b);
      brelse(b);
      psa_tracker[blockno + i] = true; // change block's tracker status
    }
    
        

    /* Unmap swapped out page */
    uvmunmap(p->pagetable, p->heap_tracker[heap_victim_idx].addr, 1, 1);
    /* Update the resident heap tracker. */
    p->heap_tracker[heap_victim_idx].startblock = blockno;
    p->heap_tracker[heap_victim_idx].loaded = true;
    
    kfree(copy_user_block);
}

/* Retrieve faulted page from disk. */
void retrieve_page_from_disk(struct proc* p, uint64 uvaddr) {
    /* Find where the page is located in disk */
    int heap_idx = -1;
    
    for(int i = 0; i< MAXHEAP; i++){
      if(uvaddr == p->heap_tracker[i].addr){
        heap_idx = i;
        break;
      }
    }
    
    if ((heap_idx == -1))
      panic("Heap tracker issue while retrieving page from disk");
      
    int disk_startblock = p->heap_tracker[heap_idx].startblock;

    /* Print statement. */
    print_retrieve_page(uvaddr, disk_startblock);

    /* Create a kernel page to read memory temporarily into first. */
    void* temp_block = kalloc();
    
    /* Read the disk block into temp kernel page. */
    for(int i = 0; i < 4; i++){
      struct buf* b;
      b = bread(1, PSASTART+(disk_startblock + i));
      memmove(temp_block + (BSIZE * i), b->data, BSIZE);
      brelse(b);
      psa_tracker[disk_startblock + i] = false; // change block's tracker status
    }

    /* Copy from temp kernel page to uvaddr (use copyout) */
    copyout(p->pagetable, uvaddr, temp_block, PGSIZE);
    
    p->heap_tracker[heap_idx].loaded = false;
    p->heap_tracker[heap_idx].startblock = -1;
    
    kfree(temp_block);
}


void page_fault_handler(void) 
{
    /* Current process struct */
    struct proc *p = myproc();
    
    /*variables for allocate and load*/
    struct elfhdr elf;
    struct inode *ip;
    struct proghdr ph;
   
    /* Track whether the heap page should be brought back from disk or not. */
    bool load_from_disk = false;

    /* Find faulting address. */
    uint64 faulting_addr = r_stval() & (~(0xFFF));
    print_page_fault(p->name, faulting_addr);
    
    
    /* cow checking*/
    if((p->cow_enabled) && (r_scause() == 15)){
      if(copy_on_write(p, faulting_addr) == 1)
        goto out;    
    }
    

    /*Check if the fault address is a heap page. Use p->heap_tracker */
    int heap_idx = -1;
    
    for(int i = 0; i< MAXHEAP; i++){
      if(faulting_addr == p->heap_tracker[i].addr){
        if(p->heap_tracker[i].loaded==true){
            load_from_disk = true;
        }
        heap_idx = i;
        break;
      }
    }
    
    /* if heap index found then jump to heap handler*/
    if ((heap_idx != -1)) {
        goto heap_handle;
    } 
   
    /* If it came here, it is a page from the program binary that we must load. */
    
    /* Following code is referred from exec.c*/
    begin_op();
    if((ip = namei(p->name)) == 0){
      end_op();
    }
    ilock(ip);

    // Check ELF header
    if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
      goto bad;

    if(elf.magic != ELF_MAGIC)
      goto bad;
   
    for(int i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
      if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
        goto bad;
      if(ph.type != ELF_PROG_LOAD)
        continue;
      if(ph.memsz < ph.filesz)
        goto bad;
      if(ph.vaddr + ph.memsz < ph.vaddr)
        goto bad;
      if(ph.vaddr % PGSIZE != 0)
        goto bad;
      
      /* Check if faulting base addr is in current segment the allocate memory and load segment*/
      if((faulting_addr >= ph.vaddr) && (faulting_addr < (ph.vaddr + ph.memsz))){
      
        uvmalloc(p->pagetable, ph.vaddr, ph.vaddr + ph.memsz, flags2perm(ph.flags));
        
        if(loadseg(p->pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
          goto bad;
        break;
      }
  }
  iunlockput(ip);
  end_op();
  ip = 0;
  print_load_seg(faulting_addr, ph.off, ph.memsz);
    //print_load_seg(faulting_addr, 0, 0);

    /* Go to out, since the remainder of this code is for the heap. */
    goto out;

heap_handle:
    /* 2.4: Check if resident pages are more than heap pages. If yes, evict. */
    if (p->resident_heap_pages == MAXRESHEAP) {
        evict_page_to_disk(p);
        p->resident_heap_pages--;
    }

    /* 2.3: Map a heap page into the process' address space. (Hint: check growproc) */
    uint64 sz1 = uvmalloc(p->pagetable, faulting_addr, faulting_addr + PGSIZE, PTE_W);
    
    /* If not loaded from disk then update process size */ 
    if(!load_from_disk){
       p->sz = sz1;
    }
    
    /* 2.4: Update the last load time for the loaded heap page in p->heap_tracker. */
    p->heap_tracker[heap_idx].last_load_time = read_current_timestamp();
    p->heap_tracker[heap_idx].loaded = 0;

    /* 2.4: Heap page was swapped to disk previously. We must load it from disk. */
    //if (p->heap_tracker[heap_idx].startblock != -1) {
    if(load_from_disk){
        retrieve_page_from_disk(p, faulting_addr);
    }

    /* Track that another heap page has been brought into memory. */
    p->resident_heap_pages++;

out:
    /* Flush stale page table entries. This is important to always do. */
    sfence_vma();
    return;

bad:
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  if(ip){
    iunlockput(ip);
    end_op();
  }
  return;
}
