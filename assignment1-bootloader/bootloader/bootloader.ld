OUTPUT_ARCH( "riscv" )

/* Task: ensure the correct starting function. */
ENTRY( _entry )

SECTIONS
{
  /* Task: ensure the correct entry address based on where -kernel in QEMU jumps. */
  . = 0x80000000;

  /* Task lay out the sections as mentioned in the handout */
  
  /* Reference - 
  	1. Lecture #3 slides
  	2. https://github.com/mit-pdos/xv6-riscv/blob/riscv/kernel/kernel.ld*/
  	
  .text : {
    *(.text .text.*)
    PROVIDE(ecode = .);
  }

  .rodata : {
    *(.rodata .rodata.*)
    PROVIDE(erodata = .);
  }

  .data : {
    *(.data .data.*)
    PROVIDE(edata = .);
  }

  .bss : {
    *(.bss .bss.*)
    PROVIDE(ebss = .);
  }

  PROVIDE(end = .);
}
