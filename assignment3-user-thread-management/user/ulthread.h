#ifndef __UTHREAD_H__
#define __UTHREAD_H__

#include <stdbool.h>

#define MAXULTHREADS 100

typedef enum ulthread_state ulthread_state;
typedef enum ulthread_scheduling_algorithm ulthread_scheduling_algorithm;
typedef struct user_thread user_thread;
typedef struct thread_context thread_context;

enum ulthread_state {
  FREE,
  RUNNABLE,
  YIELD,
};

enum ulthread_scheduling_algorithm {
  ROUNDROBIN,   
  PRIORITY,     
  FCFS,         // first-come-first serve
};

/* struct to maintain context of the thread*/
/* reference -  https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/proc.h */
struct thread_context {
  uint64 ra;
  uint64 sp;
  uint64 s0;
  uint64 s1;
  uint64 s2;
  uint64 s3;
  uint64 s4;
  uint64 s5;
  uint64 s6;
  uint64 s7;
  uint64 s8;
  uint64 s9;
  uint64 s10;
  uint64 s11;
};

/* Structure to maintain user threads */
struct user_thread{
    int id;
    ulthread_state state;
    int priority;
    uint64 create_time;
    thread_context context;
};


#endif
