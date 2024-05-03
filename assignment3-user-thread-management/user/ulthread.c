/* CSE 536: User-Level Threading Library */
#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"
#include "user/ulthread.h"
#include "kernel/riscv.h"

/* Standard definitions */
#include <stdbool.h>
#include <stddef.h> 

void ulthread_context_switch(user_thread* current, user_thread* next);

/* Global Variable require to maintain threads */
user_thread *user_threads;
uint64 threads_count = 0;
ulthread_scheduling_algorithm scheduling_algorithm;
int previous_running_tid;
int current_running_tid;

/* Get thread ID*/
int get_current_tid() {
    return current_running_tid;
}

/* Thread initialization */
void ulthread_init(int schedalgo) {
	scheduling_algorithm = schedalgo;
	threads_count += 1;
	user_threads = malloc(sizeof(user_thread));
	user_threads[0].state = RUNNABLE;
	previous_running_tid = 0;
	current_running_tid = 0;
}

/* Thread creation */
bool ulthread_create(uint64 start, uint64 stack, uint64 args[], int priority) {
	int tid = 1;
	while((tid < (threads_count)) && (user_threads[tid].state != FREE))
		tid++;
	
	if(tid > MAXULTHREADS) return false;
	
	if(threads_count == tid){
		void* buf = malloc((threads_count+1) * sizeof(user_thread));
		memmove(buf, (const void*) user_threads, (threads_count) * sizeof(user_thread));
		user_threads = buf;
		free(buf);
	}	
	
	threads_count++;
	user_threads[tid].id = tid;
	user_threads[tid].priority = priority;
	user_threads[tid].state = RUNNABLE;
	user_threads[tid].create_time = ctime();
	
	
	user_threads[tid].context.sp = stack;
	user_threads[tid].context.ra = start;
	user_threads[tid].context.s0 = args[0];
	user_threads[tid].context.s1 = args[1];
	user_threads[tid].context.s2 = args[2];
	user_threads[tid].context.s3 = args[3];
	user_threads[tid].context.s4 = args[4];
	user_threads[tid].context.s5 = args[5];
	
	previous_running_tid = 0;
	current_running_tid = 0;
	
    /* Please add thread-id instead of '0' here. */
    printf("[*] ultcreate(tid: %d, ra: %p, sp: %p)\n", tid, start, stack);

    return true;
}

int fcfs() {
	int next_id = -1;
	for(int i = 1; i < threads_count; i++){
		if(user_threads[i].state == RUNNABLE){
			if(next_id == -1){
				next_id = i;
			}
			else if(user_threads[i].create_time < user_threads[next_id].create_time){
				next_id = i;
			}
		}
	}
	
	return next_id;
}

int roundrobin(){
	for(int i=1; i< threads_count; i++){
		int id = (previous_running_tid + i) % threads_count;
		
		if(id == 0)
			continue;
			
		if(user_threads[id].state == RUNNABLE){
			return id;
		}
	}	
	return -1;
}

int prioritySchedule(){
	int next_id = -1;
	
	for(int i=1; i <= threads_count; i++){
		int id = (previous_running_tid + i) % threads_count;
		
		if(id == 0)
			continue;
			
		if(user_threads[id].state == RUNNABLE){
			if(next_id == -1){
				next_id = id;
			}
			else if(user_threads[next_id].priority < user_threads[id].priority){
				next_id = id;
			}
			else if(user_threads[next_id].priority == user_threads[id].priority){
				if(user_threads[next_id].create_time > user_threads[id].create_time)
					next_id = id;
			}
		}
	}
	
	return next_id;
}

/* Thread scheduler */
void ulthread_schedule(void) {
    while(1){
		int next_id = -1;
		
		if(scheduling_algorithm == ROUNDROBIN){
			next_id = roundrobin();
		}
		else if(scheduling_algorithm == PRIORITY){
			next_id = prioritySchedule();
		}
		else if(scheduling_algorithm == FCFS){
			next_id = fcfs();
		}
		
		if(previous_running_tid != 0){
			/* make yield process Runnable*/
			if(user_threads[previous_running_tid].state == YIELD)
				user_threads[previous_running_tid].state = RUNNABLE;
			
			
			/* if no process to schedule continue with previous process*/	
			if((next_id == -1) && (user_threads[previous_running_tid].state == RUNNABLE)){
				next_id = previous_running_tid;
			}
			else if(next_id == -1){
				break;
			}		
		}
		
		/* Add this statement to denote which thread-id is being scheduled next */
		printf("[*] ultschedule (next tid: %d)\n", next_id);
		
		current_running_tid = next_id;
		previous_running_tid = next_id;
		// Switch betwee thread contexts
		ulthread_context_switch(&(user_threads[0].context), &(user_threads[next_id].context));
    }
}

/* Yield CPU time to some other thread. */
void ulthread_yield(void) {
	int tid = current_running_tid;
	
	if(tid == 0)
		return;
		
	user_threads[tid].state = YIELD;
    /* Please add thread-id instead of '0' here. */
    printf("[*] ultyield(tid: %d)\n", tid);
    previous_running_tid = tid;
    current_running_tid = 0;
    
    ulthread_context_switch(&(user_threads[tid].context), &(user_threads[0].context));
}

/* Destroy thread */
void ulthread_destroy(void) {
	int tid = current_running_tid;
	
	if(tid == 0)
		return;
		
	user_threads[tid].state = FREE;
    /* Please add thread-id instead of '0' here. */
    printf("[*] ultdestroy(tid: %d)\n", tid);
    previous_running_tid = tid;
    current_running_tid = 0;
    
    ulthread_context_switch(&(user_threads[tid].context), &(user_threads[0].context));
}
