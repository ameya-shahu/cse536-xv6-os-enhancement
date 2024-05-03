void process_entry(void) {
  asm("ecall");
  asm("sret");
}