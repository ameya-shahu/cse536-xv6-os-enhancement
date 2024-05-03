#include <stddef.h>
#include "sha256.h"

struct buf;
struct context;
struct file;
struct inode;
struct pipe;
struct proc;
struct spinlock;
struct sleeplock;
struct stat;
struct superblock;

enum kernel {
    NORMAL,
    RECOVERY
};

// load.c
void            kernel_copy(enum kernel ktype, struct buf* b);

// string.c
int             memcmp(const void*, const void*, uint);
void*           memmove(void*, const void*, uint);
void*           memset(void*, int, uint);
char*           safestrcpy(char*, const char*, int);
int             strlen(const char*);
int             strncmp(const char*, const char*, uint);
char*           strncpy(char*, const char*, int);

// checks.c
int             assert_linker_symbols(void);
int             assert_stack_address(void);
void            panic(char *s);

// elf.c
uint64 find_kernel_load_addr(enum kernel ktype);
uint64 find_kernel_size(enum kernel ktype);
uint64 find_kernel_entry_addr(enum kernel ktype);
uint64 find_kernel_off(enum kernel ktype);

// Tracking the end of various sections
extern uint64 ecode;    // end of text
extern uint64 erodata;  // end of read-only data
extern uint64 ebss;     // end of bss
extern uint64 edata;    // end of data
extern uint64 end;      // end of binary

// number of elements in fixed-size array
#define NELEM(x) (sizeof(x)/sizeof((x)[0]))

/* Location of the QEMU ramdisk. */
#define RAMDISK         0x84000000
#define RECOVERYDISK    0x84500000
