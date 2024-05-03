#define NPROC        64  // maximum number of processes
#define NCPU          8  // maximum number of CPUs
#define NOFILE       16  // open files per process
#define NFILE       100  // open files per system
#define NINODE       50  // maximum number of active i-nodes
#define NDEV         10  // maximum major device number
#define ROOTDEV       1  // device number of file system root disk
#define MAXARG       32  // max exec arguments
#define MAXOPBLOCKS  10  // max # of blocks any FS op writes
#define LOGSIZE      (MAXOPBLOCKS*3)  // max data blocks in on-disk log
#define NBUF         (MAXOPBLOCKS*3)  // size of disk block cache
// #define FSSIZE       2000  // size of file system in blocks
#define MAXPATH      128   // maximum file path name
#define FSSIZE       3000  // size of file system in blocks

/* CSE 536: changed to 3000 to use the last 1000 blocks for page swapping. */
#define PSASTART                33       // Starting page save area (PSA) block
#define PSAEND                  1032     // Ending page save area (PSA) block
#define PSASIZE                 1000     // total size of the PSA

/* CSE 536: heap-related definitions. */
#define MAXHEAP                 1000     // maximum pages for heap allocation
#define MAXRESHEAP              100      // maximum in-memory pages for heap allocation
