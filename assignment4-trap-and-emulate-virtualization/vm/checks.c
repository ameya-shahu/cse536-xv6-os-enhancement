#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "buf.h"

#include <stdbool.h>

void panic(char *s)
{
  for(;;)
    ;
}

int assert_linker_symbols(void) {
    return 0;
}

int assert_stack_address(void) {
    return 1;
}