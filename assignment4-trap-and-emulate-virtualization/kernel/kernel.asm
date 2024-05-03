
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b4010113          	addi	sp,sp,-1216 # 80008b40 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	07a000ef          	jal	ra,80000090 <start>

000000008000001a <_entry_kernel>:
    8000001a:	6cf000ef          	jal	ra,80000ee8 <main>

000000008000001e <_entry_test>:
    8000001e:	a001                	j	8000001e <_entry_test>

0000000080000020 <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    80000020:	1141                	addi	sp,sp,-16
    80000022:	e422                	sd	s0,8(sp)
    80000024:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000026:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    8000002a:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002e:	0037979b          	slliw	a5,a5,0x3
    80000032:	02004737          	lui	a4,0x2004
    80000036:	97ba                	add	a5,a5,a4
    80000038:	0200c737          	lui	a4,0x200c
    8000003c:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000040:	000f4637          	lui	a2,0xf4
    80000044:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000048:	9732                	add	a4,a4,a2
    8000004a:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    8000004c:	00259693          	slli	a3,a1,0x2
    80000050:	96ae                	add	a3,a3,a1
    80000052:	068e                	slli	a3,a3,0x3
    80000054:	00009717          	auipc	a4,0x9
    80000058:	9ac70713          	addi	a4,a4,-1620 # 80008a00 <timer_scratch>
    8000005c:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005e:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    80000060:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000062:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000066:	00006797          	auipc	a5,0x6
    8000006a:	c4a78793          	addi	a5,a5,-950 # 80005cb0 <timervec>
    8000006e:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000072:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000076:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007a:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007e:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000082:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000086:	30479073          	csrw	mie,a5
}
    8000008a:	6422                	ld	s0,8(sp)
    8000008c:	0141                	addi	sp,sp,16
    8000008e:	8082                	ret

0000000080000090 <start>:
{
    80000090:	1141                	addi	sp,sp,-16
    80000092:	e406                	sd	ra,8(sp)
    80000094:	e022                	sd	s0,0(sp)
    80000096:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000098:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    8000009c:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    8000009e:	823e                	mv	tp,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    800000a0:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    800000a4:	7779                	lui	a4,0xffffe
    800000a6:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc4ff>
    800000aa:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000ac:	6705                	lui	a4,0x1
    800000ae:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000b2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000b4:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000b8:	00001797          	auipc	a5,0x1
    800000bc:	e3078793          	addi	a5,a5,-464 # 80000ee8 <main>
    800000c0:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000c4:	4781                	li	a5,0
    800000c6:	18079073          	csrw	satp,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000ca:	57fd                	li	a5,-1
    800000cc:	83a9                	srli	a5,a5,0xa
    800000ce:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000d2:	47bd                	li	a5,15
    800000d4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f48080e7          	jalr	-184(ra) # 80000020 <timerinit>
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000e0:	67c1                	lui	a5,0x10
    800000e2:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000e4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000e8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ec:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000f0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000f4:	10479073          	csrw	sie,a5
  asm volatile("mret");
    800000f8:	30200073          	mret
}
    800000fc:	60a2                	ld	ra,8(sp)
    800000fe:	6402                	ld	s0,0(sp)
    80000100:	0141                	addi	sp,sp,16
    80000102:	8082                	ret

0000000080000104 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000104:	715d                	addi	sp,sp,-80
    80000106:	e486                	sd	ra,72(sp)
    80000108:	e0a2                	sd	s0,64(sp)
    8000010a:	fc26                	sd	s1,56(sp)
    8000010c:	f84a                	sd	s2,48(sp)
    8000010e:	f44e                	sd	s3,40(sp)
    80000110:	f052                	sd	s4,32(sp)
    80000112:	ec56                	sd	s5,24(sp)
    80000114:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000116:	04c05763          	blez	a2,80000164 <consolewrite+0x60>
    8000011a:	8a2a                	mv	s4,a0
    8000011c:	84ae                	mv	s1,a1
    8000011e:	89b2                	mv	s3,a2
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	42a080e7          	jalr	1066(ra) # 80002558 <either_copyin>
    80000136:	01550d63          	beq	a0,s5,80000150 <consolewrite+0x4c>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7f2080e7          	jalr	2034(ra) # 80000930 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x20>
    8000014e:	894e                	mv	s2,s3
  }

  return i;
}
    80000150:	854a                	mv	a0,s2
    80000152:	60a6                	ld	ra,72(sp)
    80000154:	6406                	ld	s0,64(sp)
    80000156:	74e2                	ld	s1,56(sp)
    80000158:	7942                	ld	s2,48(sp)
    8000015a:	79a2                	ld	s3,40(sp)
    8000015c:	7a02                	ld	s4,32(sp)
    8000015e:	6ae2                	ld	s5,24(sp)
    80000160:	6161                	addi	sp,sp,80
    80000162:	8082                	ret
  for(i = 0; i < n; i++){
    80000164:	4901                	li	s2,0
    80000166:	b7ed                	j	80000150 <consolewrite+0x4c>

0000000080000168 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000168:	711d                	addi	sp,sp,-96
    8000016a:	ec86                	sd	ra,88(sp)
    8000016c:	e8a2                	sd	s0,80(sp)
    8000016e:	e4a6                	sd	s1,72(sp)
    80000170:	e0ca                	sd	s2,64(sp)
    80000172:	fc4e                	sd	s3,56(sp)
    80000174:	f852                	sd	s4,48(sp)
    80000176:	f456                	sd	s5,40(sp)
    80000178:	f05a                	sd	s6,32(sp)
    8000017a:	ec5e                	sd	s7,24(sp)
    8000017c:	1080                	addi	s0,sp,96
    8000017e:	8aaa                	mv	s5,a0
    80000180:	8a2e                	mv	s4,a1
    80000182:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000184:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000188:	00011517          	auipc	a0,0x11
    8000018c:	9b850513          	addi	a0,a0,-1608 # 80010b40 <cons>
    80000190:	00001097          	auipc	ra,0x1
    80000194:	ab8080e7          	jalr	-1352(ra) # 80000c48 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00011497          	auipc	s1,0x11
    8000019c:	9a848493          	addi	s1,s1,-1624 # 80010b40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00011917          	auipc	s2,0x11
    800001a4:	a3890913          	addi	s2,s2,-1480 # 80010bd8 <cons+0x98>
  while(n > 0){
    800001a8:	09305263          	blez	s3,8000022c <consoleread+0xc4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	02f71763          	bne	a4,a5,800001e2 <consoleread+0x7a>
      if(killed(myproc())){
    800001b8:	00002097          	auipc	ra,0x2
    800001bc:	86c080e7          	jalr	-1940(ra) # 80001a24 <myproc>
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	1e2080e7          	jalr	482(ra) # 800023a2 <killed>
    800001c8:	ed2d                	bnez	a0,80000242 <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001ca:	85a6                	mv	a1,s1
    800001cc:	854a                	mv	a0,s2
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	f2c080e7          	jalr	-212(ra) # 800020fa <sleep>
    while(cons.r == cons.w){
    800001d6:	0984a783          	lw	a5,152(s1)
    800001da:	09c4a703          	lw	a4,156(s1)
    800001de:	fcf70de3          	beq	a4,a5,800001b8 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e2:	00011717          	auipc	a4,0x11
    800001e6:	95e70713          	addi	a4,a4,-1698 # 80010b40 <cons>
    800001ea:	0017869b          	addiw	a3,a5,1
    800001ee:	08d72c23          	sw	a3,152(a4)
    800001f2:	07f7f693          	andi	a3,a5,127
    800001f6:	9736                	add	a4,a4,a3
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000200:	4691                	li	a3,4
    80000202:	06db8463          	beq	s7,a3,8000026a <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000206:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020a:	4685                	li	a3,1
    8000020c:	faf40613          	addi	a2,s0,-81
    80000210:	85d2                	mv	a1,s4
    80000212:	8556                	mv	a0,s5
    80000214:	00002097          	auipc	ra,0x2
    80000218:	2ee080e7          	jalr	750(ra) # 80002502 <either_copyout>
    8000021c:	57fd                	li	a5,-1
    8000021e:	00f50763          	beq	a0,a5,8000022c <consoleread+0xc4>
      break;

    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000226:	47a9                	li	a5,10
    80000228:	f8fb90e3          	bne	s7,a5,800001a8 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	91450513          	addi	a0,a0,-1772 # 80010b40 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	ac8080e7          	jalr	-1336(ra) # 80000cfc <release>

  return target - n;
    8000023c:	413b053b          	subw	a0,s6,s3
    80000240:	a811                	j	80000254 <consoleread+0xec>
        release(&cons.lock);
    80000242:	00011517          	auipc	a0,0x11
    80000246:	8fe50513          	addi	a0,a0,-1794 # 80010b40 <cons>
    8000024a:	00001097          	auipc	ra,0x1
    8000024e:	ab2080e7          	jalr	-1358(ra) # 80000cfc <release>
        return -1;
    80000252:	557d                	li	a0,-1
}
    80000254:	60e6                	ld	ra,88(sp)
    80000256:	6446                	ld	s0,80(sp)
    80000258:	64a6                	ld	s1,72(sp)
    8000025a:	6906                	ld	s2,64(sp)
    8000025c:	79e2                	ld	s3,56(sp)
    8000025e:	7a42                	ld	s4,48(sp)
    80000260:	7aa2                	ld	s5,40(sp)
    80000262:	7b02                	ld	s6,32(sp)
    80000264:	6be2                	ld	s7,24(sp)
    80000266:	6125                	addi	sp,sp,96
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677fe3          	bgeu	a4,s6,8000022c <consoleread+0xc4>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	96f72323          	sw	a5,-1690(a4) # 80010bd8 <cons+0x98>
    8000027a:	bf4d                	j	8000022c <consoleread+0xc4>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	5de080e7          	jalr	1502(ra) # 8000086a <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	5cc080e7          	jalr	1484(ra) # 8000086a <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	5c0080e7          	jalr	1472(ra) # 8000086a <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5b6080e7          	jalr	1462(ra) # 8000086a <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	87450513          	addi	a0,a0,-1932 # 80010b40 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	974080e7          	jalr	-1676(ra) # 80000c48 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2bc080e7          	jalr	700(ra) # 800025ae <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	84650513          	addi	a0,a0,-1978 # 80010b40 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9fa080e7          	jalr	-1542(ra) # 80000cfc <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	82270713          	addi	a4,a4,-2014 # 80010b40 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	7f878793          	addi	a5,a5,2040 # 80010b40 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8627a783          	lw	a5,-1950(a5) # 80010bd8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	7b670713          	addi	a4,a4,1974 # 80010b40 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	7a648493          	addi	s1,s1,1958 # 80010b40 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	76a70713          	addi	a4,a4,1898 # 80010b40 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	7ef72a23          	sw	a5,2036(a4) # 80010be0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	72e78793          	addi	a5,a5,1838 # 80010b40 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	7ac7a323          	sw	a2,1958(a5) # 80010bdc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	79a50513          	addi	a0,a0,1946 # 80010bd8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d18080e7          	jalr	-744(ra) # 8000215e <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	6e050513          	addi	a0,a0,1760 # 80010b40 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	750080e7          	jalr	1872(ra) # 80000bb8 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	3aa080e7          	jalr	938(ra) # 8000081a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	a6078793          	addi	a5,a5,-1440 # 80020ed8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce870713          	addi	a4,a4,-792 # 80000168 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7a70713          	addi	a4,a4,-902 # 80000104 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
  //   release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6a07aa23          	sw	zero,1716(a5) # 80010c00 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	44f72023          	sw	a5,1088(a4) # 800089c0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  if (fmt == 0)
    800005ba:	c90d                	beqz	a0,800005ec <printf+0x62>
    800005bc:	8a2a                	mv	s4,a0
  va_start(ap, fmt);
    800005be:	00840793          	addi	a5,s0,8
    800005c2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c6:	00054503          	lbu	a0,0(a0)
    800005ca:	20050063          	beqz	a0,800007ca <printf+0x240>
    800005ce:	4481                	li	s1,0
    if(c != '%'){
    800005d0:	02500b13          	li	s6,37
    switch(c){
    800005d4:	07000b93          	li	s7,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008a97          	auipc	s5,0x8
    800005dc:	a68a8a93          	addi	s5,s5,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	03400c13          	li	s8,52
  } while((x /= base) != 0);
    800005e8:	4d3d                	li	s10,15
    800005ea:	a025                	j	80000612 <printf+0x88>
    panic("null fmt");
    800005ec:	00008517          	auipc	a0,0x8
    800005f0:	a3c50513          	addi	a0,a0,-1476 # 80008028 <etext+0x28>
    800005f4:	00000097          	auipc	ra,0x0
    800005f8:	f4c080e7          	jalr	-180(ra) # 80000540 <panic>
      consputc(c);
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	c80080e7          	jalr	-896(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000604:	2485                	addiw	s1,s1,1
    80000606:	009a07b3          	add	a5,s4,s1
    8000060a:	0007c503          	lbu	a0,0(a5)
    8000060e:	1a050e63          	beqz	a0,800007ca <printf+0x240>
    if(c != '%'){
    80000612:	ff6515e3          	bne	a0,s6,800005fc <printf+0x72>
    c = fmt[++i] & 0xff;
    80000616:	2485                	addiw	s1,s1,1
    80000618:	009a07b3          	add	a5,s4,s1
    8000061c:	0007c783          	lbu	a5,0(a5)
    80000620:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000624:	1a078363          	beqz	a5,800007ca <printf+0x240>
    switch(c){
    80000628:	11778563          	beq	a5,s7,80000732 <printf+0x1a8>
    8000062c:	02fbee63          	bltu	s7,a5,80000668 <printf+0xde>
    80000630:	07878063          	beq	a5,s8,80000690 <printf+0x106>
    80000634:	06400713          	li	a4,100
    80000638:	02e79063          	bne	a5,a4,80000658 <printf+0xce>
      printint(va_arg(ap, int), 10, 1);
    8000063c:	f8843783          	ld	a5,-120(s0)
    80000640:	00878713          	addi	a4,a5,8
    80000644:	f8e43423          	sd	a4,-120(s0)
    80000648:	4605                	li	a2,1
    8000064a:	45a9                	li	a1,10
    8000064c:	4388                	lw	a0,0(a5)
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	e4e080e7          	jalr	-434(ra) # 8000049c <printint>
      break;
    80000656:	b77d                	j	80000604 <printf+0x7a>
    switch(c){
    80000658:	15679e63          	bne	a5,s6,800007b4 <printf+0x22a>
      consputc('%');
    8000065c:	855a                	mv	a0,s6
    8000065e:	00000097          	auipc	ra,0x0
    80000662:	c1e080e7          	jalr	-994(ra) # 8000027c <consputc>
      break;
    80000666:	bf79                	j	80000604 <printf+0x7a>
    switch(c){
    80000668:	11978863          	beq	a5,s9,80000778 <printf+0x1ee>
    8000066c:	07800713          	li	a4,120
    80000670:	14e79263          	bne	a5,a4,800007b4 <printf+0x22a>
      printint(va_arg(ap, int), 16, 1);
    80000674:	f8843783          	ld	a5,-120(s0)
    80000678:	00878713          	addi	a4,a5,8
    8000067c:	f8e43423          	sd	a4,-120(s0)
    80000680:	4605                	li	a2,1
    80000682:	45c1                	li	a1,16
    80000684:	4388                	lw	a0,0(a5)
    80000686:	00000097          	auipc	ra,0x0
    8000068a:	e16080e7          	jalr	-490(ra) # 8000049c <printint>
      break;
    8000068e:	bf9d                	j	80000604 <printf+0x7a>
      print4hex(va_arg(ap, int), 16, 1);
    80000690:	f8843783          	ld	a5,-120(s0)
    80000694:	00878713          	addi	a4,a5,8
    80000698:	f8e43423          	sd	a4,-120(s0)
    8000069c:	438c                	lw	a1,0(a5)
    x = xx;
    8000069e:	0005879b          	sext.w	a5,a1
  if(sign && (sign = xx < 0))
    800006a2:	0805c563          	bltz	a1,8000072c <printf+0x1a2>
    800006a6:	f8040693          	addi	a3,s0,-128
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006aa:	4901                	li	s2,0
    buf[i++] = digits[x % base];
    800006ac:	864a                	mv	a2,s2
    800006ae:	2905                	addiw	s2,s2,1
    800006b0:	00f7f713          	andi	a4,a5,15
    800006b4:	9756                	add	a4,a4,s5
    800006b6:	00074703          	lbu	a4,0(a4)
    800006ba:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    800006be:	0007871b          	sext.w	a4,a5
    800006c2:	0047d79b          	srliw	a5,a5,0x4
    800006c6:	0685                	addi	a3,a3,1
    800006c8:	feed62e3          	bltu	s10,a4,800006ac <printf+0x122>
  if(sign)
    800006cc:	0005dc63          	bgez	a1,800006e4 <printf+0x15a>
    buf[i++] = '-';
    800006d0:	f9090793          	addi	a5,s2,-112
    800006d4:	00878933          	add	s2,a5,s0
    800006d8:	02d00793          	li	a5,45
    800006dc:	fef90823          	sb	a5,-16(s2)
    800006e0:	0026091b          	addiw	s2,a2,2
  for (int p=4-i; p>=0; p--)
    800006e4:	4991                	li	s3,4
    800006e6:	412989bb          	subw	s3,s3,s2
    800006ea:	0009cc63          	bltz	s3,80000702 <printf+0x178>
    800006ee:	5dfd                	li	s11,-1
    consputc('0');
    800006f0:	03000513          	li	a0,48
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
  for (int p=4-i; p>=0; p--)
    800006fc:	39fd                	addiw	s3,s3,-1
    800006fe:	ffb999e3          	bne	s3,s11,800006f0 <printf+0x166>
  while(--i >= 0)
    80000702:	fff9099b          	addiw	s3,s2,-1
    80000706:	f609c7e3          	bltz	s3,80000674 <printf+0xea>
    8000070a:	f9090793          	addi	a5,s2,-112
    8000070e:	00878933          	add	s2,a5,s0
    80000712:	193d                	addi	s2,s2,-17
    80000714:	5dfd                	li	s11,-1
    consputc(buf[i]);
    80000716:	00094503          	lbu	a0,0(s2)
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000722:	39fd                	addiw	s3,s3,-1
    80000724:	197d                	addi	s2,s2,-1
    80000726:	ffb998e3          	bne	s3,s11,80000716 <printf+0x18c>
    8000072a:	b7a9                	j	80000674 <printf+0xea>
    x = -xx;
    8000072c:	40b007bb          	negw	a5,a1
    80000730:	bf9d                	j	800006a6 <printf+0x11c>
      printptr(va_arg(ap, uint64));
    80000732:	f8843783          	ld	a5,-120(s0)
    80000736:	00878713          	addi	a4,a5,8
    8000073a:	f8e43423          	sd	a4,-120(s0)
    8000073e:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000742:	03000513          	li	a0,48
    80000746:	00000097          	auipc	ra,0x0
    8000074a:	b36080e7          	jalr	-1226(ra) # 8000027c <consputc>
  consputc('x');
    8000074e:	07800513          	li	a0,120
    80000752:	00000097          	auipc	ra,0x0
    80000756:	b2a080e7          	jalr	-1238(ra) # 8000027c <consputc>
    8000075a:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000075c:	03c9d793          	srli	a5,s3,0x3c
    80000760:	97d6                	add	a5,a5,s5
    80000762:	0007c503          	lbu	a0,0(a5)
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	b16080e7          	jalr	-1258(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000076e:	0992                	slli	s3,s3,0x4
    80000770:	397d                	addiw	s2,s2,-1
    80000772:	fe0915e3          	bnez	s2,8000075c <printf+0x1d2>
    80000776:	b579                	j	80000604 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    80000778:	f8843783          	ld	a5,-120(s0)
    8000077c:	00878713          	addi	a4,a5,8
    80000780:	f8e43423          	sd	a4,-120(s0)
    80000784:	0007b903          	ld	s2,0(a5)
    80000788:	00090f63          	beqz	s2,800007a6 <printf+0x21c>
      for(; *s; s++)
    8000078c:	00094503          	lbu	a0,0(s2)
    80000790:	e6050ae3          	beqz	a0,80000604 <printf+0x7a>
        consputc(*s);
    80000794:	00000097          	auipc	ra,0x0
    80000798:	ae8080e7          	jalr	-1304(ra) # 8000027c <consputc>
      for(; *s; s++)
    8000079c:	0905                	addi	s2,s2,1
    8000079e:	00094503          	lbu	a0,0(s2)
    800007a2:	f96d                	bnez	a0,80000794 <printf+0x20a>
    800007a4:	b585                	j	80000604 <printf+0x7a>
        s = "(null)";
    800007a6:	00008917          	auipc	s2,0x8
    800007aa:	87a90913          	addi	s2,s2,-1926 # 80008020 <etext+0x20>
      for(; *s; s++)
    800007ae:	02800513          	li	a0,40
    800007b2:	b7cd                	j	80000794 <printf+0x20a>
      consputc('%');
    800007b4:	855a                	mv	a0,s6
    800007b6:	00000097          	auipc	ra,0x0
    800007ba:	ac6080e7          	jalr	-1338(ra) # 8000027c <consputc>
      consputc(c);
    800007be:	854a                	mv	a0,s2
    800007c0:	00000097          	auipc	ra,0x0
    800007c4:	abc080e7          	jalr	-1348(ra) # 8000027c <consputc>
      break;
    800007c8:	bd35                	j	80000604 <printf+0x7a>
}
    800007ca:	70e6                	ld	ra,120(sp)
    800007cc:	7446                	ld	s0,112(sp)
    800007ce:	74a6                	ld	s1,104(sp)
    800007d0:	7906                	ld	s2,96(sp)
    800007d2:	69e6                	ld	s3,88(sp)
    800007d4:	6a46                	ld	s4,80(sp)
    800007d6:	6aa6                	ld	s5,72(sp)
    800007d8:	6b06                	ld	s6,64(sp)
    800007da:	7be2                	ld	s7,56(sp)
    800007dc:	7c42                	ld	s8,48(sp)
    800007de:	7ca2                	ld	s9,40(sp)
    800007e0:	7d02                	ld	s10,32(sp)
    800007e2:	6de2                	ld	s11,24(sp)
    800007e4:	6129                	addi	sp,sp,192
    800007e6:	8082                	ret

00000000800007e8 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007e8:	1101                	addi	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007f2:	00010497          	auipc	s1,0x10
    800007f6:	3f648493          	addi	s1,s1,1014 # 80010be8 <pr>
    800007fa:	00008597          	auipc	a1,0x8
    800007fe:	83e58593          	addi	a1,a1,-1986 # 80008038 <etext+0x38>
    80000802:	8526                	mv	a0,s1
    80000804:	00000097          	auipc	ra,0x0
    80000808:	3b4080e7          	jalr	948(ra) # 80000bb8 <initlock>
  pr.locking = 1;
    8000080c:	4785                	li	a5,1
    8000080e:	cc9c                	sw	a5,24(s1)
}
    80000810:	60e2                	ld	ra,24(sp)
    80000812:	6442                	ld	s0,16(sp)
    80000814:	64a2                	ld	s1,8(sp)
    80000816:	6105                	addi	sp,sp,32
    80000818:	8082                	ret

000000008000081a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000081a:	1141                	addi	sp,sp,-16
    8000081c:	e406                	sd	ra,8(sp)
    8000081e:	e022                	sd	s0,0(sp)
    80000820:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000822:	100007b7          	lui	a5,0x10000
    80000826:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000082a:	f8000713          	li	a4,-128
    8000082e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000832:	470d                	li	a4,3
    80000834:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000838:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000083c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000840:	469d                	li	a3,7
    80000842:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000846:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000084a:	00008597          	auipc	a1,0x8
    8000084e:	80e58593          	addi	a1,a1,-2034 # 80008058 <digits+0x18>
    80000852:	00010517          	auipc	a0,0x10
    80000856:	3b650513          	addi	a0,a0,950 # 80010c08 <uart_tx_lock>
    8000085a:	00000097          	auipc	ra,0x0
    8000085e:	35e080e7          	jalr	862(ra) # 80000bb8 <initlock>
}
    80000862:	60a2                	ld	ra,8(sp)
    80000864:	6402                	ld	s0,0(sp)
    80000866:	0141                	addi	sp,sp,16
    80000868:	8082                	ret

000000008000086a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000086a:	1101                	addi	sp,sp,-32
    8000086c:	ec06                	sd	ra,24(sp)
    8000086e:	e822                	sd	s0,16(sp)
    80000870:	e426                	sd	s1,8(sp)
    80000872:	1000                	addi	s0,sp,32
    80000874:	84aa                	mv	s1,a0
  push_off();
    80000876:	00000097          	auipc	ra,0x0
    8000087a:	386080e7          	jalr	902(ra) # 80000bfc <push_off>
  //   for(;;)
  //     ;
  // }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000087e:	10000737          	lui	a4,0x10000
    80000882:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000886:	0207f793          	andi	a5,a5,32
    8000088a:	dfe5                	beqz	a5,80000882 <uartputc_sync+0x18>
    ;
  WriteReg(THR, c);
    8000088c:	0ff4f493          	zext.b	s1,s1
    80000890:	100007b7          	lui	a5,0x10000
    80000894:	00978023          	sb	s1,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000898:	00000097          	auipc	ra,0x0
    8000089c:	404080e7          	jalr	1028(ra) # 80000c9c <pop_off>
}
    800008a0:	60e2                	ld	ra,24(sp)
    800008a2:	6442                	ld	s0,16(sp)
    800008a4:	64a2                	ld	s1,8(sp)
    800008a6:	6105                	addi	sp,sp,32
    800008a8:	8082                	ret

00000000800008aa <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008aa:	00008797          	auipc	a5,0x8
    800008ae:	11e7b783          	ld	a5,286(a5) # 800089c8 <uart_tx_r>
    800008b2:	00008717          	auipc	a4,0x8
    800008b6:	11e73703          	ld	a4,286(a4) # 800089d0 <uart_tx_w>
    800008ba:	06f70a63          	beq	a4,a5,8000092e <uartstart+0x84>
{
    800008be:	7139                	addi	sp,sp,-64
    800008c0:	fc06                	sd	ra,56(sp)
    800008c2:	f822                	sd	s0,48(sp)
    800008c4:	f426                	sd	s1,40(sp)
    800008c6:	f04a                	sd	s2,32(sp)
    800008c8:	ec4e                	sd	s3,24(sp)
    800008ca:	e852                	sd	s4,16(sp)
    800008cc:	e456                	sd	s5,8(sp)
    800008ce:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d0:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008d4:	00010a17          	auipc	s4,0x10
    800008d8:	334a0a13          	addi	s4,s4,820 # 80010c08 <uart_tx_lock>
    uart_tx_r += 1;
    800008dc:	00008497          	auipc	s1,0x8
    800008e0:	0ec48493          	addi	s1,s1,236 # 800089c8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008e4:	00008997          	auipc	s3,0x8
    800008e8:	0ec98993          	addi	s3,s3,236 # 800089d0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008ec:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008f0:	02077713          	andi	a4,a4,32
    800008f4:	c705                	beqz	a4,8000091c <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008f6:	01f7f713          	andi	a4,a5,31
    800008fa:	9752                	add	a4,a4,s4
    800008fc:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000900:	0785                	addi	a5,a5,1
    80000902:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000904:	8526                	mv	a0,s1
    80000906:	00002097          	auipc	ra,0x2
    8000090a:	858080e7          	jalr	-1960(ra) # 8000215e <wakeup>
    
    WriteReg(THR, c);
    8000090e:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000912:	609c                	ld	a5,0(s1)
    80000914:	0009b703          	ld	a4,0(s3)
    80000918:	fcf71ae3          	bne	a4,a5,800008ec <uartstart+0x42>
  }
}
    8000091c:	70e2                	ld	ra,56(sp)
    8000091e:	7442                	ld	s0,48(sp)
    80000920:	74a2                	ld	s1,40(sp)
    80000922:	7902                	ld	s2,32(sp)
    80000924:	69e2                	ld	s3,24(sp)
    80000926:	6a42                	ld	s4,16(sp)
    80000928:	6aa2                	ld	s5,8(sp)
    8000092a:	6121                	addi	sp,sp,64
    8000092c:	8082                	ret
    8000092e:	8082                	ret

0000000080000930 <uartputc>:
{
    80000930:	7179                	addi	sp,sp,-48
    80000932:	f406                	sd	ra,40(sp)
    80000934:	f022                	sd	s0,32(sp)
    80000936:	ec26                	sd	s1,24(sp)
    80000938:	e84a                	sd	s2,16(sp)
    8000093a:	e44e                	sd	s3,8(sp)
    8000093c:	e052                	sd	s4,0(sp)
    8000093e:	1800                	addi	s0,sp,48
    80000940:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000942:	00010517          	auipc	a0,0x10
    80000946:	2c650513          	addi	a0,a0,710 # 80010c08 <uart_tx_lock>
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	2fe080e7          	jalr	766(ra) # 80000c48 <acquire>
  if(panicked){
    80000952:	00008797          	auipc	a5,0x8
    80000956:	06e7a783          	lw	a5,110(a5) # 800089c0 <panicked>
    8000095a:	e7c9                	bnez	a5,800009e4 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000095c:	00008717          	auipc	a4,0x8
    80000960:	07473703          	ld	a4,116(a4) # 800089d0 <uart_tx_w>
    80000964:	00008797          	auipc	a5,0x8
    80000968:	0647b783          	ld	a5,100(a5) # 800089c8 <uart_tx_r>
    8000096c:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000970:	00010997          	auipc	s3,0x10
    80000974:	29898993          	addi	s3,s3,664 # 80010c08 <uart_tx_lock>
    80000978:	00008497          	auipc	s1,0x8
    8000097c:	05048493          	addi	s1,s1,80 # 800089c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000980:	00008917          	auipc	s2,0x8
    80000984:	05090913          	addi	s2,s2,80 # 800089d0 <uart_tx_w>
    80000988:	00e79f63          	bne	a5,a4,800009a6 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000098c:	85ce                	mv	a1,s3
    8000098e:	8526                	mv	a0,s1
    80000990:	00001097          	auipc	ra,0x1
    80000994:	76a080e7          	jalr	1898(ra) # 800020fa <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000998:	00093703          	ld	a4,0(s2)
    8000099c:	609c                	ld	a5,0(s1)
    8000099e:	02078793          	addi	a5,a5,32
    800009a2:	fee785e3          	beq	a5,a4,8000098c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    800009a6:	00010497          	auipc	s1,0x10
    800009aa:	26248493          	addi	s1,s1,610 # 80010c08 <uart_tx_lock>
    800009ae:	01f77793          	andi	a5,a4,31
    800009b2:	97a6                	add	a5,a5,s1
    800009b4:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009b8:	0705                	addi	a4,a4,1
    800009ba:	00008797          	auipc	a5,0x8
    800009be:	00e7bb23          	sd	a4,22(a5) # 800089d0 <uart_tx_w>
  uartstart();
    800009c2:	00000097          	auipc	ra,0x0
    800009c6:	ee8080e7          	jalr	-280(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    800009ca:	8526                	mv	a0,s1
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	330080e7          	jalr	816(ra) # 80000cfc <release>
}
    800009d4:	70a2                	ld	ra,40(sp)
    800009d6:	7402                	ld	s0,32(sp)
    800009d8:	64e2                	ld	s1,24(sp)
    800009da:	6942                	ld	s2,16(sp)
    800009dc:	69a2                	ld	s3,8(sp)
    800009de:	6a02                	ld	s4,0(sp)
    800009e0:	6145                	addi	sp,sp,48
    800009e2:	8082                	ret
    for(;;)
    800009e4:	a001                	j	800009e4 <uartputc+0xb4>

00000000800009e6 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009e6:	1141                	addi	sp,sp,-16
    800009e8:	e422                	sd	s0,8(sp)
    800009ea:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ec:	100007b7          	lui	a5,0x10000
    800009f0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009f4:	8b85                	andi	a5,a5,1
    800009f6:	cb81                	beqz	a5,80000a06 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800009f8:	100007b7          	lui	a5,0x10000
    800009fc:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000a00:	6422                	ld	s0,8(sp)
    80000a02:	0141                	addi	sp,sp,16
    80000a04:	8082                	ret
    return -1;
    80000a06:	557d                	li	a0,-1
    80000a08:	bfe5                	j	80000a00 <uartgetc+0x1a>

0000000080000a0a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000a0a:	1101                	addi	sp,sp,-32
    80000a0c:	ec06                	sd	ra,24(sp)
    80000a0e:	e822                	sd	s0,16(sp)
    80000a10:	e426                	sd	s1,8(sp)
    80000a12:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a14:	54fd                	li	s1,-1
    80000a16:	a029                	j	80000a20 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a18:	00000097          	auipc	ra,0x0
    80000a1c:	8a6080e7          	jalr	-1882(ra) # 800002be <consoleintr>
    int c = uartgetc();
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	fc6080e7          	jalr	-58(ra) # 800009e6 <uartgetc>
    if(c == -1)
    80000a28:	fe9518e3          	bne	a0,s1,80000a18 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a2c:	00010497          	auipc	s1,0x10
    80000a30:	1dc48493          	addi	s1,s1,476 # 80010c08 <uart_tx_lock>
    80000a34:	8526                	mv	a0,s1
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	212080e7          	jalr	530(ra) # 80000c48 <acquire>
  uartstart();
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	e6c080e7          	jalr	-404(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    80000a46:	8526                	mv	a0,s1
    80000a48:	00000097          	auipc	ra,0x0
    80000a4c:	2b4080e7          	jalr	692(ra) # 80000cfc <release>
}
    80000a50:	60e2                	ld	ra,24(sp)
    80000a52:	6442                	ld	s0,16(sp)
    80000a54:	64a2                	ld	s1,8(sp)
    80000a56:	6105                	addi	sp,sp,32
    80000a58:	8082                	ret

0000000080000a5a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a5a:	1101                	addi	sp,sp,-32
    80000a5c:	ec06                	sd	ra,24(sp)
    80000a5e:	e822                	sd	s0,16(sp)
    80000a60:	e426                	sd	s1,8(sp)
    80000a62:	e04a                	sd	s2,0(sp)
    80000a64:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a66:	03451793          	slli	a5,a0,0x34
    80000a6a:	ebb9                	bnez	a5,80000ac0 <kfree+0x66>
    80000a6c:	84aa                	mv	s1,a0
    80000a6e:	00022797          	auipc	a5,0x22
    80000a72:	89278793          	addi	a5,a5,-1902 # 80022300 <end>
    80000a76:	04f56563          	bltu	a0,a5,80000ac0 <kfree+0x66>
    80000a7a:	47c5                	li	a5,17
    80000a7c:	07ee                	slli	a5,a5,0x1b
    80000a7e:	04f57163          	bgeu	a0,a5,80000ac0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a82:	6605                	lui	a2,0x1
    80000a84:	4585                	li	a1,1
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	2be080e7          	jalr	702(ra) # 80000d44 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a8e:	00010917          	auipc	s2,0x10
    80000a92:	1b290913          	addi	s2,s2,434 # 80010c40 <kmem>
    80000a96:	854a                	mv	a0,s2
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	1b0080e7          	jalr	432(ra) # 80000c48 <acquire>
  r->next = kmem.freelist;
    80000aa0:	01893783          	ld	a5,24(s2)
    80000aa4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000aa6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000aaa:	854a                	mv	a0,s2
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	250080e7          	jalr	592(ra) # 80000cfc <release>
}
    80000ab4:	60e2                	ld	ra,24(sp)
    80000ab6:	6442                	ld	s0,16(sp)
    80000ab8:	64a2                	ld	s1,8(sp)
    80000aba:	6902                	ld	s2,0(sp)
    80000abc:	6105                	addi	sp,sp,32
    80000abe:	8082                	ret
    panic("kfree");
    80000ac0:	00007517          	auipc	a0,0x7
    80000ac4:	5a050513          	addi	a0,a0,1440 # 80008060 <digits+0x20>
    80000ac8:	00000097          	auipc	ra,0x0
    80000acc:	a78080e7          	jalr	-1416(ra) # 80000540 <panic>

0000000080000ad0 <freerange>:
{
    80000ad0:	7179                	addi	sp,sp,-48
    80000ad2:	f406                	sd	ra,40(sp)
    80000ad4:	f022                	sd	s0,32(sp)
    80000ad6:	ec26                	sd	s1,24(sp)
    80000ad8:	e84a                	sd	s2,16(sp)
    80000ada:	e44e                	sd	s3,8(sp)
    80000adc:	e052                	sd	s4,0(sp)
    80000ade:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae0:	6785                	lui	a5,0x1
    80000ae2:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ae6:	00e504b3          	add	s1,a0,a4
    80000aea:	777d                	lui	a4,0xfffff
    80000aec:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aee:	94be                	add	s1,s1,a5
    80000af0:	0095ee63          	bltu	a1,s1,80000b0c <freerange+0x3c>
    80000af4:	892e                	mv	s2,a1
    kfree(p);
    80000af6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	6985                	lui	s3,0x1
    kfree(p);
    80000afa:	01448533          	add	a0,s1,s4
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f5c080e7          	jalr	-164(ra) # 80000a5a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94ce                	add	s1,s1,s3
    80000b08:	fe9979e3          	bgeu	s2,s1,80000afa <freerange+0x2a>
}
    80000b0c:	70a2                	ld	ra,40(sp)
    80000b0e:	7402                	ld	s0,32(sp)
    80000b10:	64e2                	ld	s1,24(sp)
    80000b12:	6942                	ld	s2,16(sp)
    80000b14:	69a2                	ld	s3,8(sp)
    80000b16:	6a02                	ld	s4,0(sp)
    80000b18:	6145                	addi	sp,sp,48
    80000b1a:	8082                	ret

0000000080000b1c <kinit>:
{
    80000b1c:	1141                	addi	sp,sp,-16
    80000b1e:	e406                	sd	ra,8(sp)
    80000b20:	e022                	sd	s0,0(sp)
    80000b22:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b24:	00007597          	auipc	a1,0x7
    80000b28:	54458593          	addi	a1,a1,1348 # 80008068 <digits+0x28>
    80000b2c:	00010517          	auipc	a0,0x10
    80000b30:	11450513          	addi	a0,a0,276 # 80010c40 <kmem>
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	084080e7          	jalr	132(ra) # 80000bb8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b3c:	45c5                	li	a1,17
    80000b3e:	05ee                	slli	a1,a1,0x1b
    80000b40:	00021517          	auipc	a0,0x21
    80000b44:	7c050513          	addi	a0,a0,1984 # 80022300 <end>
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	f88080e7          	jalr	-120(ra) # 80000ad0 <freerange>
}
    80000b50:	60a2                	ld	ra,8(sp)
    80000b52:	6402                	ld	s0,0(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b58:	1101                	addi	sp,sp,-32
    80000b5a:	ec06                	sd	ra,24(sp)
    80000b5c:	e822                	sd	s0,16(sp)
    80000b5e:	e426                	sd	s1,8(sp)
    80000b60:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b62:	00010497          	auipc	s1,0x10
    80000b66:	0de48493          	addi	s1,s1,222 # 80010c40 <kmem>
    80000b6a:	8526                	mv	a0,s1
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	0dc080e7          	jalr	220(ra) # 80000c48 <acquire>
  r = kmem.freelist;
    80000b74:	6c84                	ld	s1,24(s1)
  if(r)
    80000b76:	c885                	beqz	s1,80000ba6 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b78:	609c                	ld	a5,0(s1)
    80000b7a:	00010517          	auipc	a0,0x10
    80000b7e:	0c650513          	addi	a0,a0,198 # 80010c40 <kmem>
    80000b82:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	178080e7          	jalr	376(ra) # 80000cfc <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b8c:	6605                	lui	a2,0x1
    80000b8e:	4595                	li	a1,5
    80000b90:	8526                	mv	a0,s1
    80000b92:	00000097          	auipc	ra,0x0
    80000b96:	1b2080e7          	jalr	434(ra) # 80000d44 <memset>
  return (void*)r;
}
    80000b9a:	8526                	mv	a0,s1
    80000b9c:	60e2                	ld	ra,24(sp)
    80000b9e:	6442                	ld	s0,16(sp)
    80000ba0:	64a2                	ld	s1,8(sp)
    80000ba2:	6105                	addi	sp,sp,32
    80000ba4:	8082                	ret
  release(&kmem.lock);
    80000ba6:	00010517          	auipc	a0,0x10
    80000baa:	09a50513          	addi	a0,a0,154 # 80010c40 <kmem>
    80000bae:	00000097          	auipc	ra,0x0
    80000bb2:	14e080e7          	jalr	334(ra) # 80000cfc <release>
  if(r)
    80000bb6:	b7d5                	j	80000b9a <kalloc+0x42>

0000000080000bb8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bb8:	1141                	addi	sp,sp,-16
    80000bba:	e422                	sd	s0,8(sp)
    80000bbc:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bbe:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bc0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bc4:	00053823          	sd	zero,16(a0)
}
    80000bc8:	6422                	ld	s0,8(sp)
    80000bca:	0141                	addi	sp,sp,16
    80000bcc:	8082                	ret

0000000080000bce <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bce:	411c                	lw	a5,0(a0)
    80000bd0:	e399                	bnez	a5,80000bd6 <holding+0x8>
    80000bd2:	4501                	li	a0,0
  return r;
}
    80000bd4:	8082                	ret
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	6904                	ld	s1,16(a0)
    80000be2:	00001097          	auipc	ra,0x1
    80000be6:	e26080e7          	jalr	-474(ra) # 80001a08 <mycpu>
    80000bea:	40a48533          	sub	a0,s1,a0
    80000bee:	00153513          	seqz	a0,a0
}
    80000bf2:	60e2                	ld	ra,24(sp)
    80000bf4:	6442                	ld	s0,16(sp)
    80000bf6:	64a2                	ld	s1,8(sp)
    80000bf8:	6105                	addi	sp,sp,32
    80000bfa:	8082                	ret

0000000080000bfc <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bfc:	1101                	addi	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c06:	100024f3          	csrr	s1,sstatus
    80000c0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c0e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c10:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	df4080e7          	jalr	-524(ra) # 80001a08 <mycpu>
    80000c1c:	5d3c                	lw	a5,120(a0)
    80000c1e:	cf89                	beqz	a5,80000c38 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c20:	00001097          	auipc	ra,0x1
    80000c24:	de8080e7          	jalr	-536(ra) # 80001a08 <mycpu>
    80000c28:	5d3c                	lw	a5,120(a0)
    80000c2a:	2785                	addiw	a5,a5,1
    80000c2c:	dd3c                	sw	a5,120(a0)
}
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6105                	addi	sp,sp,32
    80000c36:	8082                	ret
    mycpu()->intena = old;
    80000c38:	00001097          	auipc	ra,0x1
    80000c3c:	dd0080e7          	jalr	-560(ra) # 80001a08 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c40:	8085                	srli	s1,s1,0x1
    80000c42:	8885                	andi	s1,s1,1
    80000c44:	dd64                	sw	s1,124(a0)
    80000c46:	bfe9                	j	80000c20 <push_off+0x24>

0000000080000c48 <acquire>:
{
    80000c48:	1101                	addi	sp,sp,-32
    80000c4a:	ec06                	sd	ra,24(sp)
    80000c4c:	e822                	sd	s0,16(sp)
    80000c4e:	e426                	sd	s1,8(sp)
    80000c50:	1000                	addi	s0,sp,32
    80000c52:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c54:	00000097          	auipc	ra,0x0
    80000c58:	fa8080e7          	jalr	-88(ra) # 80000bfc <push_off>
  if(holding(lk))
    80000c5c:	8526                	mv	a0,s1
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	f70080e7          	jalr	-144(ra) # 80000bce <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c66:	4705                	li	a4,1
  if(holding(lk))
    80000c68:	e115                	bnez	a0,80000c8c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c6a:	87ba                	mv	a5,a4
    80000c6c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c70:	2781                	sext.w	a5,a5
    80000c72:	ffe5                	bnez	a5,80000c6a <acquire+0x22>
  __sync_synchronize();
    80000c74:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c78:	00001097          	auipc	ra,0x1
    80000c7c:	d90080e7          	jalr	-624(ra) # 80001a08 <mycpu>
    80000c80:	e888                	sd	a0,16(s1)
}
    80000c82:	60e2                	ld	ra,24(sp)
    80000c84:	6442                	ld	s0,16(sp)
    80000c86:	64a2                	ld	s1,8(sp)
    80000c88:	6105                	addi	sp,sp,32
    80000c8a:	8082                	ret
    panic("acquire");
    80000c8c:	00007517          	auipc	a0,0x7
    80000c90:	3e450513          	addi	a0,a0,996 # 80008070 <digits+0x30>
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	8ac080e7          	jalr	-1876(ra) # 80000540 <panic>

0000000080000c9c <pop_off>:

void
pop_off(void)
{
    80000c9c:	1141                	addi	sp,sp,-16
    80000c9e:	e406                	sd	ra,8(sp)
    80000ca0:	e022                	sd	s0,0(sp)
    80000ca2:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000ca4:	00001097          	auipc	ra,0x1
    80000ca8:	d64080e7          	jalr	-668(ra) # 80001a08 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cb0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cb2:	e78d                	bnez	a5,80000cdc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cb4:	5d3c                	lw	a5,120(a0)
    80000cb6:	02f05b63          	blez	a5,80000cec <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cba:	37fd                	addiw	a5,a5,-1
    80000cbc:	0007871b          	sext.w	a4,a5
    80000cc0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cc2:	eb09                	bnez	a4,80000cd4 <pop_off+0x38>
    80000cc4:	5d7c                	lw	a5,124(a0)
    80000cc6:	c799                	beqz	a5,80000cd4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ccc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cd4:	60a2                	ld	ra,8(sp)
    80000cd6:	6402                	ld	s0,0(sp)
    80000cd8:	0141                	addi	sp,sp,16
    80000cda:	8082                	ret
    panic("pop_off - interruptible");
    80000cdc:	00007517          	auipc	a0,0x7
    80000ce0:	39c50513          	addi	a0,a0,924 # 80008078 <digits+0x38>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	85c080e7          	jalr	-1956(ra) # 80000540 <panic>
    panic("pop_off");
    80000cec:	00007517          	auipc	a0,0x7
    80000cf0:	3a450513          	addi	a0,a0,932 # 80008090 <digits+0x50>
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	84c080e7          	jalr	-1972(ra) # 80000540 <panic>

0000000080000cfc <release>:
{
    80000cfc:	1101                	addi	sp,sp,-32
    80000cfe:	ec06                	sd	ra,24(sp)
    80000d00:	e822                	sd	s0,16(sp)
    80000d02:	e426                	sd	s1,8(sp)
    80000d04:	1000                	addi	s0,sp,32
    80000d06:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	ec6080e7          	jalr	-314(ra) # 80000bce <holding>
    80000d10:	c115                	beqz	a0,80000d34 <release+0x38>
  lk->cpu = 0;
    80000d12:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d16:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d1a:	0f50000f          	fence	iorw,ow
    80000d1e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	f7a080e7          	jalr	-134(ra) # 80000c9c <pop_off>
}
    80000d2a:	60e2                	ld	ra,24(sp)
    80000d2c:	6442                	ld	s0,16(sp)
    80000d2e:	64a2                	ld	s1,8(sp)
    80000d30:	6105                	addi	sp,sp,32
    80000d32:	8082                	ret
    panic("release");
    80000d34:	00007517          	auipc	a0,0x7
    80000d38:	36450513          	addi	a0,a0,868 # 80008098 <digits+0x58>
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	804080e7          	jalr	-2044(ra) # 80000540 <panic>

0000000080000d44 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d44:	1141                	addi	sp,sp,-16
    80000d46:	e422                	sd	s0,8(sp)
    80000d48:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d4a:	ca19                	beqz	a2,80000d60 <memset+0x1c>
    80000d4c:	87aa                	mv	a5,a0
    80000d4e:	1602                	slli	a2,a2,0x20
    80000d50:	9201                	srli	a2,a2,0x20
    80000d52:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d56:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d5a:	0785                	addi	a5,a5,1
    80000d5c:	fee79de3          	bne	a5,a4,80000d56 <memset+0x12>
  }
  return dst;
}
    80000d60:	6422                	ld	s0,8(sp)
    80000d62:	0141                	addi	sp,sp,16
    80000d64:	8082                	ret

0000000080000d66 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d66:	1141                	addi	sp,sp,-16
    80000d68:	e422                	sd	s0,8(sp)
    80000d6a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d6c:	ca05                	beqz	a2,80000d9c <memcmp+0x36>
    80000d6e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d72:	1682                	slli	a3,a3,0x20
    80000d74:	9281                	srli	a3,a3,0x20
    80000d76:	0685                	addi	a3,a3,1
    80000d78:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d7a:	00054783          	lbu	a5,0(a0)
    80000d7e:	0005c703          	lbu	a4,0(a1)
    80000d82:	00e79863          	bne	a5,a4,80000d92 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d86:	0505                	addi	a0,a0,1
    80000d88:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d8a:	fed518e3          	bne	a0,a3,80000d7a <memcmp+0x14>
  }

  return 0;
    80000d8e:	4501                	li	a0,0
    80000d90:	a019                	j	80000d96 <memcmp+0x30>
      return *s1 - *s2;
    80000d92:	40e7853b          	subw	a0,a5,a4
}
    80000d96:	6422                	ld	s0,8(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret
  return 0;
    80000d9c:	4501                	li	a0,0
    80000d9e:	bfe5                	j	80000d96 <memcmp+0x30>

0000000080000da0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e422                	sd	s0,8(sp)
    80000da4:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000da6:	c205                	beqz	a2,80000dc6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000da8:	02a5e263          	bltu	a1,a0,80000dcc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dac:	1602                	slli	a2,a2,0x20
    80000dae:	9201                	srli	a2,a2,0x20
    80000db0:	00c587b3          	add	a5,a1,a2
{
    80000db4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000db6:	0585                	addi	a1,a1,1
    80000db8:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdcd01>
    80000dba:	fff5c683          	lbu	a3,-1(a1)
    80000dbe:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dc2:	fef59ae3          	bne	a1,a5,80000db6 <memmove+0x16>

  return dst;
}
    80000dc6:	6422                	ld	s0,8(sp)
    80000dc8:	0141                	addi	sp,sp,16
    80000dca:	8082                	ret
  if(s < d && s + n > d){
    80000dcc:	02061693          	slli	a3,a2,0x20
    80000dd0:	9281                	srli	a3,a3,0x20
    80000dd2:	00d58733          	add	a4,a1,a3
    80000dd6:	fce57be3          	bgeu	a0,a4,80000dac <memmove+0xc>
    d += n;
    80000dda:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ddc:	fff6079b          	addiw	a5,a2,-1
    80000de0:	1782                	slli	a5,a5,0x20
    80000de2:	9381                	srli	a5,a5,0x20
    80000de4:	fff7c793          	not	a5,a5
    80000de8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dea:	177d                	addi	a4,a4,-1
    80000dec:	16fd                	addi	a3,a3,-1
    80000dee:	00074603          	lbu	a2,0(a4)
    80000df2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000df6:	fee79ae3          	bne	a5,a4,80000dea <memmove+0x4a>
    80000dfa:	b7f1                	j	80000dc6 <memmove+0x26>

0000000080000dfc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dfc:	1141                	addi	sp,sp,-16
    80000dfe:	e406                	sd	ra,8(sp)
    80000e00:	e022                	sd	s0,0(sp)
    80000e02:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e04:	00000097          	auipc	ra,0x0
    80000e08:	f9c080e7          	jalr	-100(ra) # 80000da0 <memmove>
}
    80000e0c:	60a2                	ld	ra,8(sp)
    80000e0e:	6402                	ld	s0,0(sp)
    80000e10:	0141                	addi	sp,sp,16
    80000e12:	8082                	ret

0000000080000e14 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e14:	1141                	addi	sp,sp,-16
    80000e16:	e422                	sd	s0,8(sp)
    80000e18:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e1a:	ce11                	beqz	a2,80000e36 <strncmp+0x22>
    80000e1c:	00054783          	lbu	a5,0(a0)
    80000e20:	cf89                	beqz	a5,80000e3a <strncmp+0x26>
    80000e22:	0005c703          	lbu	a4,0(a1)
    80000e26:	00f71a63          	bne	a4,a5,80000e3a <strncmp+0x26>
    n--, p++, q++;
    80000e2a:	367d                	addiw	a2,a2,-1
    80000e2c:	0505                	addi	a0,a0,1
    80000e2e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e30:	f675                	bnez	a2,80000e1c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e32:	4501                	li	a0,0
    80000e34:	a809                	j	80000e46 <strncmp+0x32>
    80000e36:	4501                	li	a0,0
    80000e38:	a039                	j	80000e46 <strncmp+0x32>
  if(n == 0)
    80000e3a:	ca09                	beqz	a2,80000e4c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e3c:	00054503          	lbu	a0,0(a0)
    80000e40:	0005c783          	lbu	a5,0(a1)
    80000e44:	9d1d                	subw	a0,a0,a5
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret
    return 0;
    80000e4c:	4501                	li	a0,0
    80000e4e:	bfe5                	j	80000e46 <strncmp+0x32>

0000000080000e50 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e50:	1141                	addi	sp,sp,-16
    80000e52:	e422                	sd	s0,8(sp)
    80000e54:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86b2                	mv	a3,a2
    80000e5a:	367d                	addiw	a2,a2,-1
    80000e5c:	00d05963          	blez	a3,80000e6e <strncpy+0x1e>
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	0005c703          	lbu	a4,0(a1)
    80000e66:	fee78fa3          	sb	a4,-1(a5)
    80000e6a:	0585                	addi	a1,a1,1
    80000e6c:	f775                	bnez	a4,80000e58 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e6e:	873e                	mv	a4,a5
    80000e70:	9fb5                	addw	a5,a5,a3
    80000e72:	37fd                	addiw	a5,a5,-1
    80000e74:	00c05963          	blez	a2,80000e86 <strncpy+0x36>
    *s++ = 0;
    80000e78:	0705                	addi	a4,a4,1
    80000e7a:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e7e:	40e786bb          	subw	a3,a5,a4
    80000e82:	fed04be3          	bgtz	a3,80000e78 <strncpy+0x28>
  return os;
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret

0000000080000e8c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e8c:	1141                	addi	sp,sp,-16
    80000e8e:	e422                	sd	s0,8(sp)
    80000e90:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e92:	02c05363          	blez	a2,80000eb8 <safestrcpy+0x2c>
    80000e96:	fff6069b          	addiw	a3,a2,-1
    80000e9a:	1682                	slli	a3,a3,0x20
    80000e9c:	9281                	srli	a3,a3,0x20
    80000e9e:	96ae                	add	a3,a3,a1
    80000ea0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ea2:	00d58963          	beq	a1,a3,80000eb4 <safestrcpy+0x28>
    80000ea6:	0585                	addi	a1,a1,1
    80000ea8:	0785                	addi	a5,a5,1
    80000eaa:	fff5c703          	lbu	a4,-1(a1)
    80000eae:	fee78fa3          	sb	a4,-1(a5)
    80000eb2:	fb65                	bnez	a4,80000ea2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000eb4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret

0000000080000ebe <strlen>:

int
strlen(const char *s)
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e422                	sd	s0,8(sp)
    80000ec2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ec4:	00054783          	lbu	a5,0(a0)
    80000ec8:	cf91                	beqz	a5,80000ee4 <strlen+0x26>
    80000eca:	0505                	addi	a0,a0,1
    80000ecc:	87aa                	mv	a5,a0
    80000ece:	86be                	mv	a3,a5
    80000ed0:	0785                	addi	a5,a5,1
    80000ed2:	fff7c703          	lbu	a4,-1(a5)
    80000ed6:	ff65                	bnez	a4,80000ece <strlen+0x10>
    80000ed8:	40a6853b          	subw	a0,a3,a0
    80000edc:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000ede:	6422                	ld	s0,8(sp)
    80000ee0:	0141                	addi	sp,sp,16
    80000ee2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ee4:	4501                	li	a0,0
    80000ee6:	bfe5                	j	80000ede <strlen+0x20>

0000000080000ee8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ee8:	1141                	addi	sp,sp,-16
    80000eea:	e406                	sd	ra,8(sp)
    80000eec:	e022                	sd	s0,0(sp)
    80000eee:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	b08080e7          	jalr	-1272(ra) # 800019f8 <cpuid>
    trap_and_emulate_init();

    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ef8:	00008717          	auipc	a4,0x8
    80000efc:	ae070713          	addi	a4,a4,-1312 # 800089d8 <started>
  if(cpuid() == 0){
    80000f00:	c139                	beqz	a0,80000f46 <main+0x5e>
    while(started == 0)
    80000f02:	431c                	lw	a5,0(a4)
    80000f04:	2781                	sext.w	a5,a5
    80000f06:	dff5                	beqz	a5,80000f02 <main+0x1a>
      ;
    __sync_synchronize();
    80000f08:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f0c:	00001097          	auipc	ra,0x1
    80000f10:	aec080e7          	jalr	-1300(ra) # 800019f8 <cpuid>
    80000f14:	85aa                	mv	a1,a0
    80000f16:	00007517          	auipc	a0,0x7
    80000f1a:	1a250513          	addi	a0,a0,418 # 800080b8 <digits+0x78>
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	66c080e7          	jalr	1644(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	0e0080e7          	jalr	224(ra) # 80001006 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	7c2080e7          	jalr	1986(ra) # 800026f0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f36:	00005097          	auipc	ra,0x5
    80000f3a:	dba080e7          	jalr	-582(ra) # 80005cf0 <plicinithart>
  }

  scheduler();        
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	00a080e7          	jalr	10(ra) # 80001f48 <scheduler>
    consoleinit();
    80000f46:	fffff097          	auipc	ra,0xfffff
    80000f4a:	50a080e7          	jalr	1290(ra) # 80000450 <consoleinit>
    printfinit();
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	89a080e7          	jalr	-1894(ra) # 800007e8 <printfinit>
    printf("\n");
    80000f56:	00007517          	auipc	a0,0x7
    80000f5a:	17250513          	addi	a0,a0,370 # 800080c8 <digits+0x88>
    80000f5e:	fffff097          	auipc	ra,0xfffff
    80000f62:	62c080e7          	jalr	1580(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f66:	00007517          	auipc	a0,0x7
    80000f6a:	13a50513          	addi	a0,a0,314 # 800080a0 <digits+0x60>
    80000f6e:	fffff097          	auipc	ra,0xfffff
    80000f72:	61c080e7          	jalr	1564(ra) # 8000058a <printf>
    printf("\n");
    80000f76:	00007517          	auipc	a0,0x7
    80000f7a:	15250513          	addi	a0,a0,338 # 800080c8 <digits+0x88>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	60c080e7          	jalr	1548(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f86:	00000097          	auipc	ra,0x0
    80000f8a:	b96080e7          	jalr	-1130(ra) # 80000b1c <kinit>
    kvminit();       // create kernel page table
    80000f8e:	00000097          	auipc	ra,0x0
    80000f92:	32e080e7          	jalr	814(ra) # 800012bc <kvminit>
    kvminithart();   // turn on paging
    80000f96:	00000097          	auipc	ra,0x0
    80000f9a:	070080e7          	jalr	112(ra) # 80001006 <kvminithart>
    procinit();      // process table
    80000f9e:	00001097          	auipc	ra,0x1
    80000fa2:	9a6080e7          	jalr	-1626(ra) # 80001944 <procinit>
    trapinit();      // trap vectors
    80000fa6:	00001097          	auipc	ra,0x1
    80000faa:	722080e7          	jalr	1826(ra) # 800026c8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	742080e7          	jalr	1858(ra) # 800026f0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fb6:	00005097          	auipc	ra,0x5
    80000fba:	d24080e7          	jalr	-732(ra) # 80005cda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fbe:	00005097          	auipc	ra,0x5
    80000fc2:	d32080e7          	jalr	-718(ra) # 80005cf0 <plicinithart>
    binit();         // buffer cache
    80000fc6:	00002097          	auipc	ra,0x2
    80000fca:	ec4080e7          	jalr	-316(ra) # 80002e8a <binit>
    iinit();         // inode table
    80000fce:	00002097          	auipc	ra,0x2
    80000fd2:	562080e7          	jalr	1378(ra) # 80003530 <iinit>
    fileinit();      // file table
    80000fd6:	00003097          	auipc	ra,0x3
    80000fda:	4d8080e7          	jalr	1240(ra) # 800044ae <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	e1a080e7          	jalr	-486(ra) # 80005df8 <virtio_disk_init>
    userinit();      // first user process
    80000fe6:	00001097          	auipc	ra,0x1
    80000fea:	d44080e7          	jalr	-700(ra) # 80001d2a <userinit>
    trap_and_emulate_init();
    80000fee:	00005097          	auipc	ra,0x5
    80000ff2:	75a080e7          	jalr	1882(ra) # 80006748 <trap_and_emulate_init>
    __sync_synchronize();
    80000ff6:	0ff0000f          	fence
    started = 1;
    80000ffa:	4785                	li	a5,1
    80000ffc:	00008717          	auipc	a4,0x8
    80001000:	9cf72e23          	sw	a5,-1572(a4) # 800089d8 <started>
    80001004:	bf2d                	j	80000f3e <main+0x56>

0000000080001006 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001006:	1141                	addi	sp,sp,-16
    80001008:	e422                	sd	s0,8(sp)
    8000100a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000100c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001010:	00008797          	auipc	a5,0x8
    80001014:	9d07b783          	ld	a5,-1584(a5) # 800089e0 <kernel_pagetable>
    80001018:	83b1                	srli	a5,a5,0xc
    8000101a:	577d                	li	a4,-1
    8000101c:	177e                	slli	a4,a4,0x3f
    8000101e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001020:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001024:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001028:	6422                	ld	s0,8(sp)
    8000102a:	0141                	addi	sp,sp,16
    8000102c:	8082                	ret

000000008000102e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000102e:	7139                	addi	sp,sp,-64
    80001030:	fc06                	sd	ra,56(sp)
    80001032:	f822                	sd	s0,48(sp)
    80001034:	f426                	sd	s1,40(sp)
    80001036:	f04a                	sd	s2,32(sp)
    80001038:	ec4e                	sd	s3,24(sp)
    8000103a:	e852                	sd	s4,16(sp)
    8000103c:	e456                	sd	s5,8(sp)
    8000103e:	e05a                	sd	s6,0(sp)
    80001040:	0080                	addi	s0,sp,64
    80001042:	84aa                	mv	s1,a0
    80001044:	89ae                	mv	s3,a1
    80001046:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001048:	57fd                	li	a5,-1
    8000104a:	83e9                	srli	a5,a5,0x1a
    8000104c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000104e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001050:	04b7f263          	bgeu	a5,a1,80001094 <walk+0x66>
    panic("walk");
    80001054:	00007517          	auipc	a0,0x7
    80001058:	07c50513          	addi	a0,a0,124 # 800080d0 <digits+0x90>
    8000105c:	fffff097          	auipc	ra,0xfffff
    80001060:	4e4080e7          	jalr	1252(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001064:	060a8663          	beqz	s5,800010d0 <walk+0xa2>
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	af0080e7          	jalr	-1296(ra) # 80000b58 <kalloc>
    80001070:	84aa                	mv	s1,a0
    80001072:	c529                	beqz	a0,800010bc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001074:	6605                	lui	a2,0x1
    80001076:	4581                	li	a1,0
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	ccc080e7          	jalr	-820(ra) # 80000d44 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001080:	00c4d793          	srli	a5,s1,0xc
    80001084:	07aa                	slli	a5,a5,0xa
    80001086:	0017e793          	ori	a5,a5,1
    8000108a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000108e:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdccf7>
    80001090:	036a0063          	beq	s4,s6,800010b0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001094:	0149d933          	srl	s2,s3,s4
    80001098:	1ff97913          	andi	s2,s2,511
    8000109c:	090e                	slli	s2,s2,0x3
    8000109e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a0:	00093483          	ld	s1,0(s2)
    800010a4:	0014f793          	andi	a5,s1,1
    800010a8:	dfd5                	beqz	a5,80001064 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010aa:	80a9                	srli	s1,s1,0xa
    800010ac:	04b2                	slli	s1,s1,0xc
    800010ae:	b7c5                	j	8000108e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010b0:	00c9d513          	srli	a0,s3,0xc
    800010b4:	1ff57513          	andi	a0,a0,511
    800010b8:	050e                	slli	a0,a0,0x3
    800010ba:	9526                	add	a0,a0,s1
}
    800010bc:	70e2                	ld	ra,56(sp)
    800010be:	7442                	ld	s0,48(sp)
    800010c0:	74a2                	ld	s1,40(sp)
    800010c2:	7902                	ld	s2,32(sp)
    800010c4:	69e2                	ld	s3,24(sp)
    800010c6:	6a42                	ld	s4,16(sp)
    800010c8:	6aa2                	ld	s5,8(sp)
    800010ca:	6b02                	ld	s6,0(sp)
    800010cc:	6121                	addi	sp,sp,64
    800010ce:	8082                	ret
        return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7ed                	j	800010bc <walk+0x8e>

00000000800010d4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010d4:	57fd                	li	a5,-1
    800010d6:	83e9                	srli	a5,a5,0x1a
    800010d8:	00b7f463          	bgeu	a5,a1,800010e0 <walkaddr+0xc>
    return 0;
    800010dc:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010de:	8082                	ret
{
    800010e0:	1141                	addi	sp,sp,-16
    800010e2:	e406                	sd	ra,8(sp)
    800010e4:	e022                	sd	s0,0(sp)
    800010e6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010e8:	4601                	li	a2,0
    800010ea:	00000097          	auipc	ra,0x0
    800010ee:	f44080e7          	jalr	-188(ra) # 8000102e <walk>
  if(pte == 0)
    800010f2:	c105                	beqz	a0,80001112 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010f4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010f6:	0117f693          	andi	a3,a5,17
    800010fa:	4745                	li	a4,17
    return 0;
    800010fc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010fe:	00e68663          	beq	a3,a4,8000110a <walkaddr+0x36>
}
    80001102:	60a2                	ld	ra,8(sp)
    80001104:	6402                	ld	s0,0(sp)
    80001106:	0141                	addi	sp,sp,16
    80001108:	8082                	ret
  pa = PTE2PA(*pte);
    8000110a:	83a9                	srli	a5,a5,0xa
    8000110c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001110:	bfcd                	j	80001102 <walkaddr+0x2e>
    return 0;
    80001112:	4501                	li	a0,0
    80001114:	b7fd                	j	80001102 <walkaddr+0x2e>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	addi	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000112c:	c639                	beqz	a2,8000117a <mappages+0x64>
    8000112e:	8aaa                	mv	s5,a0
    80001130:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001132:	777d                	lui	a4,0xfffff
    80001134:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001138:	fff58993          	addi	s3,a1,-1
    8000113c:	99b2                	add	s3,s3,a2
    8000113e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001142:	893e                	mv	s2,a5
    80001144:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001148:	6b85                	lui	s7,0x1
    8000114a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114e:	4605                	li	a2,1
    80001150:	85ca                	mv	a1,s2
    80001152:	8556                	mv	a0,s5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	eda080e7          	jalr	-294(ra) # 8000102e <walk>
    8000115c:	cd1d                	beqz	a0,8000119a <mappages+0x84>
    if(*pte & PTE_V)
    8000115e:	611c                	ld	a5,0(a0)
    80001160:	8b85                	andi	a5,a5,1
    80001162:	e785                	bnez	a5,8000118a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001164:	80b1                	srli	s1,s1,0xc
    80001166:	04aa                	slli	s1,s1,0xa
    80001168:	0164e4b3          	or	s1,s1,s6
    8000116c:	0014e493          	ori	s1,s1,1
    80001170:	e104                	sd	s1,0(a0)
    if(a == last)
    80001172:	05390063          	beq	s2,s3,800011b2 <mappages+0x9c>
    a += PGSIZE;
    80001176:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001178:	bfc9                	j	8000114a <mappages+0x34>
    panic("mappages: size");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f5e50513          	addi	a0,a0,-162 # 800080d8 <digits+0x98>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3be080e7          	jalr	958(ra) # 80000540 <panic>
      panic("mappages: remap");
    8000118a:	00007517          	auipc	a0,0x7
    8000118e:	f5e50513          	addi	a0,a0,-162 # 800080e8 <digits+0xa8>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3ae080e7          	jalr	942(ra) # 80000540 <panic>
      return -1;
    8000119a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000119c:	60a6                	ld	ra,72(sp)
    8000119e:	6406                	ld	s0,64(sp)
    800011a0:	74e2                	ld	s1,56(sp)
    800011a2:	7942                	ld	s2,48(sp)
    800011a4:	79a2                	ld	s3,40(sp)
    800011a6:	7a02                	ld	s4,32(sp)
    800011a8:	6ae2                	ld	s5,24(sp)
    800011aa:	6b42                	ld	s6,16(sp)
    800011ac:	6ba2                	ld	s7,8(sp)
    800011ae:	6161                	addi	sp,sp,80
    800011b0:	8082                	ret
  return 0;
    800011b2:	4501                	li	a0,0
    800011b4:	b7e5                	j	8000119c <mappages+0x86>

00000000800011b6 <kvmmap>:
{
    800011b6:	1141                	addi	sp,sp,-16
    800011b8:	e406                	sd	ra,8(sp)
    800011ba:	e022                	sd	s0,0(sp)
    800011bc:	0800                	addi	s0,sp,16
    800011be:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011c0:	86b2                	mv	a3,a2
    800011c2:	863e                	mv	a2,a5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f52080e7          	jalr	-174(ra) # 80001116 <mappages>
    800011cc:	e509                	bnez	a0,800011d6 <kvmmap+0x20>
}
    800011ce:	60a2                	ld	ra,8(sp)
    800011d0:	6402                	ld	s0,0(sp)
    800011d2:	0141                	addi	sp,sp,16
    800011d4:	8082                	ret
    panic("kvmmap");
    800011d6:	00007517          	auipc	a0,0x7
    800011da:	f2250513          	addi	a0,a0,-222 # 800080f8 <digits+0xb8>
    800011de:	fffff097          	auipc	ra,0xfffff
    800011e2:	362080e7          	jalr	866(ra) # 80000540 <panic>

00000000800011e6 <kvmmake>:
{
    800011e6:	1101                	addi	sp,sp,-32
    800011e8:	ec06                	sd	ra,24(sp)
    800011ea:	e822                	sd	s0,16(sp)
    800011ec:	e426                	sd	s1,8(sp)
    800011ee:	e04a                	sd	s2,0(sp)
    800011f0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	966080e7          	jalr	-1690(ra) # 80000b58 <kalloc>
    800011fa:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011fc:	6605                	lui	a2,0x1
    800011fe:	4581                	li	a1,0
    80001200:	00000097          	auipc	ra,0x0
    80001204:	b44080e7          	jalr	-1212(ra) # 80000d44 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	6685                	lui	a3,0x1
    8000120c:	10000637          	lui	a2,0x10000
    80001210:	100005b7          	lui	a1,0x10000
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	fa0080e7          	jalr	-96(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000121e:	4719                	li	a4,6
    80001220:	6685                	lui	a3,0x1
    80001222:	10001637          	lui	a2,0x10001
    80001226:	100015b7          	lui	a1,0x10001
    8000122a:	8526                	mv	a0,s1
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f8a080e7          	jalr	-118(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001234:	4719                	li	a4,6
    80001236:	004006b7          	lui	a3,0x400
    8000123a:	0c000637          	lui	a2,0xc000
    8000123e:	0c0005b7          	lui	a1,0xc000
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f72080e7          	jalr	-142(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000124c:	00007917          	auipc	s2,0x7
    80001250:	db490913          	addi	s2,s2,-588 # 80008000 <etext>
    80001254:	4729                	li	a4,10
    80001256:	80007697          	auipc	a3,0x80007
    8000125a:	daa68693          	addi	a3,a3,-598 # 8000 <_entry-0x7fff8000>
    8000125e:	4605                	li	a2,1
    80001260:	067e                	slli	a2,a2,0x1f
    80001262:	85b2                	mv	a1,a2
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f50080e7          	jalr	-176(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000126e:	4719                	li	a4,6
    80001270:	46c5                	li	a3,17
    80001272:	06ee                	slli	a3,a3,0x1b
    80001274:	412686b3          	sub	a3,a3,s2
    80001278:	864a                	mv	a2,s2
    8000127a:	85ca                	mv	a1,s2
    8000127c:	8526                	mv	a0,s1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f38080e7          	jalr	-200(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001286:	4729                	li	a4,10
    80001288:	6685                	lui	a3,0x1
    8000128a:	00006617          	auipc	a2,0x6
    8000128e:	d7660613          	addi	a2,a2,-650 # 80007000 <_trampoline>
    80001292:	040005b7          	lui	a1,0x4000
    80001296:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001298:	05b2                	slli	a1,a1,0xc
    8000129a:	8526                	mv	a0,s1
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f1a080e7          	jalr	-230(ra) # 800011b6 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012a4:	8526                	mv	a0,s1
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	608080e7          	jalr	1544(ra) # 800018ae <proc_mapstacks>
}
    800012ae:	8526                	mv	a0,s1
    800012b0:	60e2                	ld	ra,24(sp)
    800012b2:	6442                	ld	s0,16(sp)
    800012b4:	64a2                	ld	s1,8(sp)
    800012b6:	6902                	ld	s2,0(sp)
    800012b8:	6105                	addi	sp,sp,32
    800012ba:	8082                	ret

00000000800012bc <kvminit>:
{
    800012bc:	1141                	addi	sp,sp,-16
    800012be:	e406                	sd	ra,8(sp)
    800012c0:	e022                	sd	s0,0(sp)
    800012c2:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f22080e7          	jalr	-222(ra) # 800011e6 <kvmmake>
    800012cc:	00007797          	auipc	a5,0x7
    800012d0:	70a7ba23          	sd	a0,1812(a5) # 800089e0 <kernel_pagetable>
}
    800012d4:	60a2                	ld	ra,8(sp)
    800012d6:	6402                	ld	s0,0(sp)
    800012d8:	0141                	addi	sp,sp,16
    800012da:	8082                	ret

00000000800012dc <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012dc:	715d                	addi	sp,sp,-80
    800012de:	e486                	sd	ra,72(sp)
    800012e0:	e0a2                	sd	s0,64(sp)
    800012e2:	fc26                	sd	s1,56(sp)
    800012e4:	f84a                	sd	s2,48(sp)
    800012e6:	f44e                	sd	s3,40(sp)
    800012e8:	f052                	sd	s4,32(sp)
    800012ea:	ec56                	sd	s5,24(sp)
    800012ec:	e85a                	sd	s6,16(sp)
    800012ee:	e45e                	sd	s7,8(sp)
    800012f0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012f2:	03459793          	slli	a5,a1,0x34
    800012f6:	e795                	bnez	a5,80001322 <uvmunmap+0x46>
    800012f8:	8a2a                	mv	s4,a0
    800012fa:	892e                	mv	s2,a1
    800012fc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fe:	0632                	slli	a2,a2,0xc
    80001300:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001306:	6b05                	lui	s6,0x1
    80001308:	0735e263          	bltu	a1,s3,8000136c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000130c:	60a6                	ld	ra,72(sp)
    8000130e:	6406                	ld	s0,64(sp)
    80001310:	74e2                	ld	s1,56(sp)
    80001312:	7942                	ld	s2,48(sp)
    80001314:	79a2                	ld	s3,40(sp)
    80001316:	7a02                	ld	s4,32(sp)
    80001318:	6ae2                	ld	s5,24(sp)
    8000131a:	6b42                	ld	s6,16(sp)
    8000131c:	6ba2                	ld	s7,8(sp)
    8000131e:	6161                	addi	sp,sp,80
    80001320:	8082                	ret
    panic("uvmunmap: not aligned");
    80001322:	00007517          	auipc	a0,0x7
    80001326:	dde50513          	addi	a0,a0,-546 # 80008100 <digits+0xc0>
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	216080e7          	jalr	534(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001332:	00007517          	auipc	a0,0x7
    80001336:	de650513          	addi	a0,a0,-538 # 80008118 <digits+0xd8>
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	206080e7          	jalr	518(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001342:	00007517          	auipc	a0,0x7
    80001346:	de650513          	addi	a0,a0,-538 # 80008128 <digits+0xe8>
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001352:	00007517          	auipc	a0,0x7
    80001356:	dee50513          	addi	a0,a0,-530 # 80008140 <digits+0x100>
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>
    *pte = 0;
    80001362:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001366:	995a                	add	s2,s2,s6
    80001368:	fb3972e3          	bgeu	s2,s3,8000130c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000136c:	4601                	li	a2,0
    8000136e:	85ca                	mv	a1,s2
    80001370:	8552                	mv	a0,s4
    80001372:	00000097          	auipc	ra,0x0
    80001376:	cbc080e7          	jalr	-836(ra) # 8000102e <walk>
    8000137a:	84aa                	mv	s1,a0
    8000137c:	d95d                	beqz	a0,80001332 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000137e:	6108                	ld	a0,0(a0)
    80001380:	00157793          	andi	a5,a0,1
    80001384:	dfdd                	beqz	a5,80001342 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001386:	3ff57793          	andi	a5,a0,1023
    8000138a:	fd7784e3          	beq	a5,s7,80001352 <uvmunmap+0x76>
    if(do_free){
    8000138e:	fc0a8ae3          	beqz	s5,80001362 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001392:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001394:	0532                	slli	a0,a0,0xc
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	6c4080e7          	jalr	1732(ra) # 80000a5a <kfree>
    8000139e:	b7d1                	j	80001362 <uvmunmap+0x86>

00000000800013a0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013a0:	1101                	addi	sp,sp,-32
    800013a2:	ec06                	sd	ra,24(sp)
    800013a4:	e822                	sd	s0,16(sp)
    800013a6:	e426                	sd	s1,8(sp)
    800013a8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	7ae080e7          	jalr	1966(ra) # 80000b58 <kalloc>
    800013b2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013b4:	c519                	beqz	a0,800013c2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b6:	6605                	lui	a2,0x1
    800013b8:	4581                	li	a1,0
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	98a080e7          	jalr	-1654(ra) # 80000d44 <memset>
  return pagetable;
}
    800013c2:	8526                	mv	a0,s1
    800013c4:	60e2                	ld	ra,24(sp)
    800013c6:	6442                	ld	s0,16(sp)
    800013c8:	64a2                	ld	s1,8(sp)
    800013ca:	6105                	addi	sp,sp,32
    800013cc:	8082                	ret

00000000800013ce <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ce:	7179                	addi	sp,sp,-48
    800013d0:	f406                	sd	ra,40(sp)
    800013d2:	f022                	sd	s0,32(sp)
    800013d4:	ec26                	sd	s1,24(sp)
    800013d6:	e84a                	sd	s2,16(sp)
    800013d8:	e44e                	sd	s3,8(sp)
    800013da:	e052                	sd	s4,0(sp)
    800013dc:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013de:	6785                	lui	a5,0x1
    800013e0:	04f67863          	bgeu	a2,a5,80001430 <uvmfirst+0x62>
    800013e4:	8a2a                	mv	s4,a0
    800013e6:	89ae                	mv	s3,a1
    800013e8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	76e080e7          	jalr	1902(ra) # 80000b58 <kalloc>
    800013f2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013f4:	6605                	lui	a2,0x1
    800013f6:	4581                	li	a1,0
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	94c080e7          	jalr	-1716(ra) # 80000d44 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001400:	4779                	li	a4,30
    80001402:	86ca                	mv	a3,s2
    80001404:	6605                	lui	a2,0x1
    80001406:	4581                	li	a1,0
    80001408:	8552                	mv	a0,s4
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	d0c080e7          	jalr	-756(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    80001412:	8626                	mv	a2,s1
    80001414:	85ce                	mv	a1,s3
    80001416:	854a                	mv	a0,s2
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	988080e7          	jalr	-1656(ra) # 80000da0 <memmove>
}
    80001420:	70a2                	ld	ra,40(sp)
    80001422:	7402                	ld	s0,32(sp)
    80001424:	64e2                	ld	s1,24(sp)
    80001426:	6942                	ld	s2,16(sp)
    80001428:	69a2                	ld	s3,8(sp)
    8000142a:	6a02                	ld	s4,0(sp)
    8000142c:	6145                	addi	sp,sp,48
    8000142e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001430:	00007517          	auipc	a0,0x7
    80001434:	d2850513          	addi	a0,a0,-728 # 80008158 <digits+0x118>
    80001438:	fffff097          	auipc	ra,0xfffff
    8000143c:	108080e7          	jalr	264(ra) # 80000540 <panic>

0000000080001440 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001440:	1101                	addi	sp,sp,-32
    80001442:	ec06                	sd	ra,24(sp)
    80001444:	e822                	sd	s0,16(sp)
    80001446:	e426                	sd	s1,8(sp)
    80001448:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000144a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000144c:	00b67d63          	bgeu	a2,a1,80001466 <uvmdealloc+0x26>
    80001450:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001452:	6785                	lui	a5,0x1
    80001454:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001456:	00f60733          	add	a4,a2,a5
    8000145a:	76fd                	lui	a3,0xfffff
    8000145c:	8f75                	and	a4,a4,a3
    8000145e:	97ae                	add	a5,a5,a1
    80001460:	8ff5                	and	a5,a5,a3
    80001462:	00f76863          	bltu	a4,a5,80001472 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001466:	8526                	mv	a0,s1
    80001468:	60e2                	ld	ra,24(sp)
    8000146a:	6442                	ld	s0,16(sp)
    8000146c:	64a2                	ld	s1,8(sp)
    8000146e:	6105                	addi	sp,sp,32
    80001470:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001472:	8f99                	sub	a5,a5,a4
    80001474:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001476:	4685                	li	a3,1
    80001478:	0007861b          	sext.w	a2,a5
    8000147c:	85ba                	mv	a1,a4
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	e5e080e7          	jalr	-418(ra) # 800012dc <uvmunmap>
    80001486:	b7c5                	j	80001466 <uvmdealloc+0x26>

0000000080001488 <uvmalloc>:
  if(newsz < oldsz)
    80001488:	0ab66563          	bltu	a2,a1,80001532 <uvmalloc+0xaa>
{
    8000148c:	7139                	addi	sp,sp,-64
    8000148e:	fc06                	sd	ra,56(sp)
    80001490:	f822                	sd	s0,48(sp)
    80001492:	f426                	sd	s1,40(sp)
    80001494:	f04a                	sd	s2,32(sp)
    80001496:	ec4e                	sd	s3,24(sp)
    80001498:	e852                	sd	s4,16(sp)
    8000149a:	e456                	sd	s5,8(sp)
    8000149c:	e05a                	sd	s6,0(sp)
    8000149e:	0080                	addi	s0,sp,64
    800014a0:	8aaa                	mv	s5,a0
    800014a2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014a4:	6785                	lui	a5,0x1
    800014a6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014a8:	95be                	add	a1,a1,a5
    800014aa:	77fd                	lui	a5,0xfffff
    800014ac:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b0:	08c9f363          	bgeu	s3,a2,80001536 <uvmalloc+0xae>
    800014b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014b6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	69e080e7          	jalr	1694(ra) # 80000b58 <kalloc>
    800014c2:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c4:	c51d                	beqz	a0,800014f2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014c6:	6605                	lui	a2,0x1
    800014c8:	4581                	li	a1,0
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	87a080e7          	jalr	-1926(ra) # 80000d44 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014d2:	875a                	mv	a4,s6
    800014d4:	86a6                	mv	a3,s1
    800014d6:	6605                	lui	a2,0x1
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	c3a080e7          	jalr	-966(ra) # 80001116 <mappages>
    800014e4:	e90d                	bnez	a0,80001516 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e6:	6785                	lui	a5,0x1
    800014e8:	993e                	add	s2,s2,a5
    800014ea:	fd4968e3          	bltu	s2,s4,800014ba <uvmalloc+0x32>
  return newsz;
    800014ee:	8552                	mv	a0,s4
    800014f0:	a809                	j	80001502 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014f2:	864e                	mv	a2,s3
    800014f4:	85ca                	mv	a1,s2
    800014f6:	8556                	mv	a0,s5
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	f48080e7          	jalr	-184(ra) # 80001440 <uvmdealloc>
      return 0;
    80001500:	4501                	li	a0,0
}
    80001502:	70e2                	ld	ra,56(sp)
    80001504:	7442                	ld	s0,48(sp)
    80001506:	74a2                	ld	s1,40(sp)
    80001508:	7902                	ld	s2,32(sp)
    8000150a:	69e2                	ld	s3,24(sp)
    8000150c:	6a42                	ld	s4,16(sp)
    8000150e:	6aa2                	ld	s5,8(sp)
    80001510:	6b02                	ld	s6,0(sp)
    80001512:	6121                	addi	sp,sp,64
    80001514:	8082                	ret
      kfree(mem);
    80001516:	8526                	mv	a0,s1
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	542080e7          	jalr	1346(ra) # 80000a5a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001520:	864e                	mv	a2,s3
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	f1a080e7          	jalr	-230(ra) # 80001440 <uvmdealloc>
      return 0;
    8000152e:	4501                	li	a0,0
    80001530:	bfc9                	j	80001502 <uvmalloc+0x7a>
    return oldsz;
    80001532:	852e                	mv	a0,a1
}
    80001534:	8082                	ret
  return newsz;
    80001536:	8532                	mv	a0,a2
    80001538:	b7e9                	j	80001502 <uvmalloc+0x7a>

000000008000153a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153a:	7179                	addi	sp,sp,-48
    8000153c:	f406                	sd	ra,40(sp)
    8000153e:	f022                	sd	s0,32(sp)
    80001540:	ec26                	sd	s1,24(sp)
    80001542:	e84a                	sd	s2,16(sp)
    80001544:	e44e                	sd	s3,8(sp)
    80001546:	e052                	sd	s4,0(sp)
    80001548:	1800                	addi	s0,sp,48
    8000154a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154c:	84aa                	mv	s1,a0
    8000154e:	6905                	lui	s2,0x1
    80001550:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001552:	4985                	li	s3,1
    80001554:	a829                	j	8000156e <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001556:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001558:	00c79513          	slli	a0,a5,0xc
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	fde080e7          	jalr	-34(ra) # 8000153a <freewalk>
      pagetable[i] = 0;
    80001564:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001568:	04a1                	addi	s1,s1,8
    8000156a:	03248163          	beq	s1,s2,8000158c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000156e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001570:	00f7f713          	andi	a4,a5,15
    80001574:	ff3701e3          	beq	a4,s3,80001556 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001578:	8b85                	andi	a5,a5,1
    8000157a:	d7fd                	beqz	a5,80001568 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000157c:	00007517          	auipc	a0,0x7
    80001580:	bfc50513          	addi	a0,a0,-1028 # 80008178 <digits+0x138>
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	fbc080e7          	jalr	-68(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158c:	8552                	mv	a0,s4
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	4cc080e7          	jalr	1228(ra) # 80000a5a <kfree>
}
    80001596:	70a2                	ld	ra,40(sp)
    80001598:	7402                	ld	s0,32(sp)
    8000159a:	64e2                	ld	s1,24(sp)
    8000159c:	6942                	ld	s2,16(sp)
    8000159e:	69a2                	ld	s3,8(sp)
    800015a0:	6a02                	ld	s4,0(sp)
    800015a2:	6145                	addi	sp,sp,48
    800015a4:	8082                	ret

00000000800015a6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a6:	1101                	addi	sp,sp,-32
    800015a8:	ec06                	sd	ra,24(sp)
    800015aa:	e822                	sd	s0,16(sp)
    800015ac:	e426                	sd	s1,8(sp)
    800015ae:	1000                	addi	s0,sp,32
    800015b0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b2:	e999                	bnez	a1,800015c8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b4:	8526                	mv	a0,s1
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f84080e7          	jalr	-124(ra) # 8000153a <freewalk>
}
    800015be:	60e2                	ld	ra,24(sp)
    800015c0:	6442                	ld	s0,16(sp)
    800015c2:	64a2                	ld	s1,8(sp)
    800015c4:	6105                	addi	sp,sp,32
    800015c6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c8:	6785                	lui	a5,0x1
    800015ca:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015cc:	95be                	add	a1,a1,a5
    800015ce:	4685                	li	a3,1
    800015d0:	00c5d613          	srli	a2,a1,0xc
    800015d4:	4581                	li	a1,0
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	d06080e7          	jalr	-762(ra) # 800012dc <uvmunmap>
    800015de:	bfd9                	j	800015b4 <uvmfree+0xe>

00000000800015e0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015e0:	c679                	beqz	a2,800016ae <uvmcopy+0xce>
{
    800015e2:	715d                	addi	sp,sp,-80
    800015e4:	e486                	sd	ra,72(sp)
    800015e6:	e0a2                	sd	s0,64(sp)
    800015e8:	fc26                	sd	s1,56(sp)
    800015ea:	f84a                	sd	s2,48(sp)
    800015ec:	f44e                	sd	s3,40(sp)
    800015ee:	f052                	sd	s4,32(sp)
    800015f0:	ec56                	sd	s5,24(sp)
    800015f2:	e85a                	sd	s6,16(sp)
    800015f4:	e45e                	sd	s7,8(sp)
    800015f6:	0880                	addi	s0,sp,80
    800015f8:	8b2a                	mv	s6,a0
    800015fa:	8aae                	mv	s5,a1
    800015fc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fe:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001600:	4601                	li	a2,0
    80001602:	85ce                	mv	a1,s3
    80001604:	855a                	mv	a0,s6
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	a28080e7          	jalr	-1496(ra) # 8000102e <walk>
    8000160e:	c531                	beqz	a0,8000165a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001610:	6118                	ld	a4,0(a0)
    80001612:	00177793          	andi	a5,a4,1
    80001616:	cbb1                	beqz	a5,8000166a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001618:	00a75593          	srli	a1,a4,0xa
    8000161c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001620:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	534080e7          	jalr	1332(ra) # 80000b58 <kalloc>
    8000162c:	892a                	mv	s2,a0
    8000162e:	c939                	beqz	a0,80001684 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001630:	6605                	lui	a2,0x1
    80001632:	85de                	mv	a1,s7
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	76c080e7          	jalr	1900(ra) # 80000da0 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163c:	8726                	mv	a4,s1
    8000163e:	86ca                	mv	a3,s2
    80001640:	6605                	lui	a2,0x1
    80001642:	85ce                	mv	a1,s3
    80001644:	8556                	mv	a0,s5
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	ad0080e7          	jalr	-1328(ra) # 80001116 <mappages>
    8000164e:	e515                	bnez	a0,8000167a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001650:	6785                	lui	a5,0x1
    80001652:	99be                	add	s3,s3,a5
    80001654:	fb49e6e3          	bltu	s3,s4,80001600 <uvmcopy+0x20>
    80001658:	a081                	j	80001698 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000165a:	00007517          	auipc	a0,0x7
    8000165e:	b2e50513          	addi	a0,a0,-1234 # 80008188 <digits+0x148>
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	ede080e7          	jalr	-290(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b3e50513          	addi	a0,a0,-1218 # 800081a8 <digits+0x168>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ece080e7          	jalr	-306(ra) # 80000540 <panic>
      kfree(mem);
    8000167a:	854a                	mv	a0,s2
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	3de080e7          	jalr	990(ra) # 80000a5a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001684:	4685                	li	a3,1
    80001686:	00c9d613          	srli	a2,s3,0xc
    8000168a:	4581                	li	a1,0
    8000168c:	8556                	mv	a0,s5
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	c4e080e7          	jalr	-946(ra) # 800012dc <uvmunmap>
  return -1;
    80001696:	557d                	li	a0,-1
}
    80001698:	60a6                	ld	ra,72(sp)
    8000169a:	6406                	ld	s0,64(sp)
    8000169c:	74e2                	ld	s1,56(sp)
    8000169e:	7942                	ld	s2,48(sp)
    800016a0:	79a2                	ld	s3,40(sp)
    800016a2:	7a02                	ld	s4,32(sp)
    800016a4:	6ae2                	ld	s5,24(sp)
    800016a6:	6b42                	ld	s6,16(sp)
    800016a8:	6ba2                	ld	s7,8(sp)
    800016aa:	6161                	addi	sp,sp,80
    800016ac:	8082                	ret
  return 0;
    800016ae:	4501                	li	a0,0
}
    800016b0:	8082                	ret

00000000800016b2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b2:	1141                	addi	sp,sp,-16
    800016b4:	e406                	sd	ra,8(sp)
    800016b6:	e022                	sd	s0,0(sp)
    800016b8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016ba:	4601                	li	a2,0
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	972080e7          	jalr	-1678(ra) # 8000102e <walk>
  if(pte == 0)
    800016c4:	c901                	beqz	a0,800016d4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c6:	611c                	ld	a5,0(a0)
    800016c8:	9bbd                	andi	a5,a5,-17
    800016ca:	e11c                	sd	a5,0(a0)
}
    800016cc:	60a2                	ld	ra,8(sp)
    800016ce:	6402                	ld	s0,0(sp)
    800016d0:	0141                	addi	sp,sp,16
    800016d2:	8082                	ret
    panic("uvmclear");
    800016d4:	00007517          	auipc	a0,0x7
    800016d8:	af450513          	addi	a0,a0,-1292 # 800081c8 <digits+0x188>
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	e64080e7          	jalr	-412(ra) # 80000540 <panic>

00000000800016e4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e4:	c6bd                	beqz	a3,80001752 <copyout+0x6e>
{
    800016e6:	715d                	addi	sp,sp,-80
    800016e8:	e486                	sd	ra,72(sp)
    800016ea:	e0a2                	sd	s0,64(sp)
    800016ec:	fc26                	sd	s1,56(sp)
    800016ee:	f84a                	sd	s2,48(sp)
    800016f0:	f44e                	sd	s3,40(sp)
    800016f2:	f052                	sd	s4,32(sp)
    800016f4:	ec56                	sd	s5,24(sp)
    800016f6:	e85a                	sd	s6,16(sp)
    800016f8:	e45e                	sd	s7,8(sp)
    800016fa:	e062                	sd	s8,0(sp)
    800016fc:	0880                	addi	s0,sp,80
    800016fe:	8b2a                	mv	s6,a0
    80001700:	8c2e                	mv	s8,a1
    80001702:	8a32                	mv	s4,a2
    80001704:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001706:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001708:	6a85                	lui	s5,0x1
    8000170a:	a015                	j	8000172e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170c:	9562                	add	a0,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	85d2                	mv	a1,s4
    80001714:	41250533          	sub	a0,a0,s2
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	688080e7          	jalr	1672(ra) # 80000da0 <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    src += n;
    80001724:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	99e080e7          	jalr	-1634(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    80001746:	fc99f3e3          	bgeu	s3,s1,8000170c <copyout+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	b7c1                	j	8000170c <copyout+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyout+0x74>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001770:	caa5                	beqz	a3,800017e0 <copyin+0x70>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	e062                	sd	s8,0(sp)
    80001788:	0880                	addi	s0,sp,80
    8000178a:	8b2a                	mv	s6,a0
    8000178c:	8a2e                	mv	s4,a1
    8000178e:	8c32                	mv	s8,a2
    80001790:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001792:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001794:	6a85                	lui	s5,0x1
    80001796:	a01d                	j	800017bc <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001798:	018505b3          	add	a1,a0,s8
    8000179c:	0004861b          	sext.w	a2,s1
    800017a0:	412585b3          	sub	a1,a1,s2
    800017a4:	8552                	mv	a0,s4
    800017a6:	fffff097          	auipc	ra,0xfffff
    800017aa:	5fa080e7          	jalr	1530(ra) # 80000da0 <memmove>

    len -= n;
    800017ae:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017b2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b8:	02098263          	beqz	s3,800017dc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017c0:	85ca                	mv	a1,s2
    800017c2:	855a                	mv	a0,s6
    800017c4:	00000097          	auipc	ra,0x0
    800017c8:	910080e7          	jalr	-1776(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    800017cc:	cd01                	beqz	a0,800017e4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ce:	418904b3          	sub	s1,s2,s8
    800017d2:	94d6                	add	s1,s1,s5
    800017d4:	fc99f2e3          	bgeu	s3,s1,80001798 <copyin+0x28>
    800017d8:	84ce                	mv	s1,s3
    800017da:	bf7d                	j	80001798 <copyin+0x28>
  }
  return 0;
    800017dc:	4501                	li	a0,0
    800017de:	a021                	j	800017e6 <copyin+0x76>
    800017e0:	4501                	li	a0,0
}
    800017e2:	8082                	ret
      return -1;
    800017e4:	557d                	li	a0,-1
}
    800017e6:	60a6                	ld	ra,72(sp)
    800017e8:	6406                	ld	s0,64(sp)
    800017ea:	74e2                	ld	s1,56(sp)
    800017ec:	7942                	ld	s2,48(sp)
    800017ee:	79a2                	ld	s3,40(sp)
    800017f0:	7a02                	ld	s4,32(sp)
    800017f2:	6ae2                	ld	s5,24(sp)
    800017f4:	6b42                	ld	s6,16(sp)
    800017f6:	6ba2                	ld	s7,8(sp)
    800017f8:	6c02                	ld	s8,0(sp)
    800017fa:	6161                	addi	sp,sp,80
    800017fc:	8082                	ret

00000000800017fe <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017fe:	c2dd                	beqz	a3,800018a4 <copyinstr+0xa6>
{
    80001800:	715d                	addi	sp,sp,-80
    80001802:	e486                	sd	ra,72(sp)
    80001804:	e0a2                	sd	s0,64(sp)
    80001806:	fc26                	sd	s1,56(sp)
    80001808:	f84a                	sd	s2,48(sp)
    8000180a:	f44e                	sd	s3,40(sp)
    8000180c:	f052                	sd	s4,32(sp)
    8000180e:	ec56                	sd	s5,24(sp)
    80001810:	e85a                	sd	s6,16(sp)
    80001812:	e45e                	sd	s7,8(sp)
    80001814:	0880                	addi	s0,sp,80
    80001816:	8a2a                	mv	s4,a0
    80001818:	8b2e                	mv	s6,a1
    8000181a:	8bb2                	mv	s7,a2
    8000181c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000181e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001820:	6985                	lui	s3,0x1
    80001822:	a02d                	j	8000184c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001824:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001828:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000182a:	37fd                	addiw	a5,a5,-1
    8000182c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001830:	60a6                	ld	ra,72(sp)
    80001832:	6406                	ld	s0,64(sp)
    80001834:	74e2                	ld	s1,56(sp)
    80001836:	7942                	ld	s2,48(sp)
    80001838:	79a2                	ld	s3,40(sp)
    8000183a:	7a02                	ld	s4,32(sp)
    8000183c:	6ae2                	ld	s5,24(sp)
    8000183e:	6b42                	ld	s6,16(sp)
    80001840:	6ba2                	ld	s7,8(sp)
    80001842:	6161                	addi	sp,sp,80
    80001844:	8082                	ret
    srcva = va0 + PGSIZE;
    80001846:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000184a:	c8a9                	beqz	s1,8000189c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000184c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001850:	85ca                	mv	a1,s2
    80001852:	8552                	mv	a0,s4
    80001854:	00000097          	auipc	ra,0x0
    80001858:	880080e7          	jalr	-1920(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000185c:	c131                	beqz	a0,800018a0 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000185e:	417906b3          	sub	a3,s2,s7
    80001862:	96ce                	add	a3,a3,s3
    80001864:	00d4f363          	bgeu	s1,a3,8000186a <copyinstr+0x6c>
    80001868:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000186a:	955e                	add	a0,a0,s7
    8000186c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001870:	daf9                	beqz	a3,80001846 <copyinstr+0x48>
    80001872:	87da                	mv	a5,s6
    80001874:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001876:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000187a:	96da                	add	a3,a3,s6
    8000187c:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000187e:	00f60733          	add	a4,a2,a5
    80001882:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdcd00>
    80001886:	df59                	beqz	a4,80001824 <copyinstr+0x26>
        *dst = *p;
    80001888:	00e78023          	sb	a4,0(a5)
      dst++;
    8000188c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000188e:	fed797e3          	bne	a5,a3,8000187c <copyinstr+0x7e>
    80001892:	14fd                	addi	s1,s1,-1
    80001894:	94c2                	add	s1,s1,a6
      --max;
    80001896:	8c8d                	sub	s1,s1,a1
      dst++;
    80001898:	8b3e                	mv	s6,a5
    8000189a:	b775                	j	80001846 <copyinstr+0x48>
    8000189c:	4781                	li	a5,0
    8000189e:	b771                	j	8000182a <copyinstr+0x2c>
      return -1;
    800018a0:	557d                	li	a0,-1
    800018a2:	b779                	j	80001830 <copyinstr+0x32>
  int got_null = 0;
    800018a4:	4781                	li	a5,0
  if(got_null){
    800018a6:	37fd                	addiw	a5,a5,-1
    800018a8:	0007851b          	sext.w	a0,a5
}
    800018ac:	8082                	ret

00000000800018ae <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800018ae:	7139                	addi	sp,sp,-64
    800018b0:	fc06                	sd	ra,56(sp)
    800018b2:	f822                	sd	s0,48(sp)
    800018b4:	f426                	sd	s1,40(sp)
    800018b6:	f04a                	sd	s2,32(sp)
    800018b8:	ec4e                	sd	s3,24(sp)
    800018ba:	e852                	sd	s4,16(sp)
    800018bc:	e456                	sd	s5,8(sp)
    800018be:	e05a                	sd	s6,0(sp)
    800018c0:	0080                	addi	s0,sp,64
    800018c2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c4:	0000f497          	auipc	s1,0xf
    800018c8:	7cc48493          	addi	s1,s1,1996 # 80011090 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018cc:	8b26                	mv	s6,s1
    800018ce:	00006a97          	auipc	s5,0x6
    800018d2:	732a8a93          	addi	s5,s5,1842 # 80008000 <etext>
    800018d6:	04000937          	lui	s2,0x4000
    800018da:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018dc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018de:	00015a17          	auipc	s4,0x15
    800018e2:	3b2a0a13          	addi	s4,s4,946 # 80016c90 <tickslock>
    char *pa = kalloc();
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	272080e7          	jalr	626(ra) # 80000b58 <kalloc>
    800018ee:	862a                	mv	a2,a0
    if(pa == 0)
    800018f0:	c131                	beqz	a0,80001934 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018f2:	416485b3          	sub	a1,s1,s6
    800018f6:	8591                	srai	a1,a1,0x4
    800018f8:	000ab783          	ld	a5,0(s5)
    800018fc:	02f585b3          	mul	a1,a1,a5
    80001900:	2585                	addiw	a1,a1,1
    80001902:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001906:	4719                	li	a4,6
    80001908:	6685                	lui	a3,0x1
    8000190a:	40b905b3          	sub	a1,s2,a1
    8000190e:	854e                	mv	a0,s3
    80001910:	00000097          	auipc	ra,0x0
    80001914:	8a6080e7          	jalr	-1882(ra) # 800011b6 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	17048493          	addi	s1,s1,368
    8000191c:	fd4495e3          	bne	s1,s4,800018e6 <proc_mapstacks+0x38>
  }
}
    80001920:	70e2                	ld	ra,56(sp)
    80001922:	7442                	ld	s0,48(sp)
    80001924:	74a2                	ld	s1,40(sp)
    80001926:	7902                	ld	s2,32(sp)
    80001928:	69e2                	ld	s3,24(sp)
    8000192a:	6a42                	ld	s4,16(sp)
    8000192c:	6aa2                	ld	s5,8(sp)
    8000192e:	6b02                	ld	s6,0(sp)
    80001930:	6121                	addi	sp,sp,64
    80001932:	8082                	ret
      panic("kalloc");
    80001934:	00007517          	auipc	a0,0x7
    80001938:	8a450513          	addi	a0,a0,-1884 # 800081d8 <digits+0x198>
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	c04080e7          	jalr	-1020(ra) # 80000540 <panic>

0000000080001944 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001944:	7139                	addi	sp,sp,-64
    80001946:	fc06                	sd	ra,56(sp)
    80001948:	f822                	sd	s0,48(sp)
    8000194a:	f426                	sd	s1,40(sp)
    8000194c:	f04a                	sd	s2,32(sp)
    8000194e:	ec4e                	sd	s3,24(sp)
    80001950:	e852                	sd	s4,16(sp)
    80001952:	e456                	sd	s5,8(sp)
    80001954:	e05a                	sd	s6,0(sp)
    80001956:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001958:	00007597          	auipc	a1,0x7
    8000195c:	88858593          	addi	a1,a1,-1912 # 800081e0 <digits+0x1a0>
    80001960:	0000f517          	auipc	a0,0xf
    80001964:	30050513          	addi	a0,a0,768 # 80010c60 <pid_lock>
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	250080e7          	jalr	592(ra) # 80000bb8 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001970:	00007597          	auipc	a1,0x7
    80001974:	87858593          	addi	a1,a1,-1928 # 800081e8 <digits+0x1a8>
    80001978:	0000f517          	auipc	a0,0xf
    8000197c:	30050513          	addi	a0,a0,768 # 80010c78 <wait_lock>
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	238080e7          	jalr	568(ra) # 80000bb8 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001988:	0000f497          	auipc	s1,0xf
    8000198c:	70848493          	addi	s1,s1,1800 # 80011090 <proc>
      initlock(&p->lock, "proc");
    80001990:	00007b17          	auipc	s6,0x7
    80001994:	868b0b13          	addi	s6,s6,-1944 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001998:	8aa6                	mv	s5,s1
    8000199a:	00006a17          	auipc	s4,0x6
    8000199e:	666a0a13          	addi	s4,s4,1638 # 80008000 <etext>
    800019a2:	04000937          	lui	s2,0x4000
    800019a6:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019a8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019aa:	00015997          	auipc	s3,0x15
    800019ae:	2e698993          	addi	s3,s3,742 # 80016c90 <tickslock>
      initlock(&p->lock, "proc");
    800019b2:	85da                	mv	a1,s6
    800019b4:	8526                	mv	a0,s1
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	202080e7          	jalr	514(ra) # 80000bb8 <initlock>
      p->state = UNUSED;
    800019be:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800019c2:	415487b3          	sub	a5,s1,s5
    800019c6:	8791                	srai	a5,a5,0x4
    800019c8:	000a3703          	ld	a4,0(s4)
    800019cc:	02e787b3          	mul	a5,a5,a4
    800019d0:	2785                	addiw	a5,a5,1
    800019d2:	00d7979b          	slliw	a5,a5,0xd
    800019d6:	40f907b3          	sub	a5,s2,a5
    800019da:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019dc:	17048493          	addi	s1,s1,368
    800019e0:	fd3499e3          	bne	s1,s3,800019b2 <procinit+0x6e>
  }
}
    800019e4:	70e2                	ld	ra,56(sp)
    800019e6:	7442                	ld	s0,48(sp)
    800019e8:	74a2                	ld	s1,40(sp)
    800019ea:	7902                	ld	s2,32(sp)
    800019ec:	69e2                	ld	s3,24(sp)
    800019ee:	6a42                	ld	s4,16(sp)
    800019f0:	6aa2                	ld	s5,8(sp)
    800019f2:	6b02                	ld	s6,0(sp)
    800019f4:	6121                	addi	sp,sp,64
    800019f6:	8082                	ret

00000000800019f8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019f8:	1141                	addi	sp,sp,-16
    800019fa:	e422                	sd	s0,8(sp)
    800019fc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019fe:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a00:	2501                	sext.w	a0,a0
    80001a02:	6422                	ld	s0,8(sp)
    80001a04:	0141                	addi	sp,sp,16
    80001a06:	8082                	ret

0000000080001a08 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a08:	1141                	addi	sp,sp,-16
    80001a0a:	e422                	sd	s0,8(sp)
    80001a0c:	0800                	addi	s0,sp,16
    80001a0e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a10:	2781                	sext.w	a5,a5
    80001a12:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a14:	0000f517          	auipc	a0,0xf
    80001a18:	27c50513          	addi	a0,a0,636 # 80010c90 <cpus>
    80001a1c:	953e                	add	a0,a0,a5
    80001a1e:	6422                	ld	s0,8(sp)
    80001a20:	0141                	addi	sp,sp,16
    80001a22:	8082                	ret

0000000080001a24 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	1000                	addi	s0,sp,32
  push_off();
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	1ce080e7          	jalr	462(ra) # 80000bfc <push_off>
    80001a36:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a38:	2781                	sext.w	a5,a5
    80001a3a:	079e                	slli	a5,a5,0x7
    80001a3c:	0000f717          	auipc	a4,0xf
    80001a40:	22470713          	addi	a4,a4,548 # 80010c60 <pid_lock>
    80001a44:	97ba                	add	a5,a5,a4
    80001a46:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	254080e7          	jalr	596(ra) # 80000c9c <pop_off>
  return p;
}
    80001a50:	8526                	mv	a0,s1
    80001a52:	60e2                	ld	ra,24(sp)
    80001a54:	6442                	ld	s0,16(sp)
    80001a56:	64a2                	ld	s1,8(sp)
    80001a58:	6105                	addi	sp,sp,32
    80001a5a:	8082                	ret

0000000080001a5c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a5c:	1141                	addi	sp,sp,-16
    80001a5e:	e406                	sd	ra,8(sp)
    80001a60:	e022                	sd	s0,0(sp)
    80001a62:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a64:	00000097          	auipc	ra,0x0
    80001a68:	fc0080e7          	jalr	-64(ra) # 80001a24 <myproc>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	290080e7          	jalr	656(ra) # 80000cfc <release>

  if (first) {
    80001a74:	00007797          	auipc	a5,0x7
    80001a78:	efc7a783          	lw	a5,-260(a5) # 80008970 <first.1>
    80001a7c:	eb89                	bnez	a5,80001a8e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a7e:	00001097          	auipc	ra,0x1
    80001a82:	c8a080e7          	jalr	-886(ra) # 80002708 <usertrapret>
}
    80001a86:	60a2                	ld	ra,8(sp)
    80001a88:	6402                	ld	s0,0(sp)
    80001a8a:	0141                	addi	sp,sp,16
    80001a8c:	8082                	ret
    first = 0;
    80001a8e:	00007797          	auipc	a5,0x7
    80001a92:	ee07a123          	sw	zero,-286(a5) # 80008970 <first.1>
    fsinit(ROOTDEV);
    80001a96:	4505                	li	a0,1
    80001a98:	00002097          	auipc	ra,0x2
    80001a9c:	a18080e7          	jalr	-1512(ra) # 800034b0 <fsinit>
    80001aa0:	bff9                	j	80001a7e <forkret+0x22>

0000000080001aa2 <allocpid>:
{
    80001aa2:	1101                	addi	sp,sp,-32
    80001aa4:	ec06                	sd	ra,24(sp)
    80001aa6:	e822                	sd	s0,16(sp)
    80001aa8:	e426                	sd	s1,8(sp)
    80001aaa:	e04a                	sd	s2,0(sp)
    80001aac:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aae:	0000f917          	auipc	s2,0xf
    80001ab2:	1b290913          	addi	s2,s2,434 # 80010c60 <pid_lock>
    80001ab6:	854a                	mv	a0,s2
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	190080e7          	jalr	400(ra) # 80000c48 <acquire>
  pid = nextpid;
    80001ac0:	00007797          	auipc	a5,0x7
    80001ac4:	eb478793          	addi	a5,a5,-332 # 80008974 <nextpid>
    80001ac8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aca:	0014871b          	addiw	a4,s1,1
    80001ace:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad0:	854a                	mv	a0,s2
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	22a080e7          	jalr	554(ra) # 80000cfc <release>
}
    80001ada:	8526                	mv	a0,s1
    80001adc:	60e2                	ld	ra,24(sp)
    80001ade:	6442                	ld	s0,16(sp)
    80001ae0:	64a2                	ld	s1,8(sp)
    80001ae2:	6902                	ld	s2,0(sp)
    80001ae4:	6105                	addi	sp,sp,32
    80001ae6:	8082                	ret

0000000080001ae8 <proc_pagetable>:
{
    80001ae8:	1101                	addi	sp,sp,-32
    80001aea:	ec06                	sd	ra,24(sp)
    80001aec:	e822                	sd	s0,16(sp)
    80001aee:	e426                	sd	s1,8(sp)
    80001af0:	e04a                	sd	s2,0(sp)
    80001af2:	1000                	addi	s0,sp,32
    80001af4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	8aa080e7          	jalr	-1878(ra) # 800013a0 <uvmcreate>
    80001afe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b00:	c121                	beqz	a0,80001b40 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b02:	4729                	li	a4,10
    80001b04:	00005697          	auipc	a3,0x5
    80001b08:	4fc68693          	addi	a3,a3,1276 # 80007000 <_trampoline>
    80001b0c:	6605                	lui	a2,0x1
    80001b0e:	040005b7          	lui	a1,0x4000
    80001b12:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b14:	05b2                	slli	a1,a1,0xc
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	600080e7          	jalr	1536(ra) # 80001116 <mappages>
    80001b1e:	02054863          	bltz	a0,80001b4e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b22:	4719                	li	a4,6
    80001b24:	05893683          	ld	a3,88(s2)
    80001b28:	6605                	lui	a2,0x1
    80001b2a:	020005b7          	lui	a1,0x2000
    80001b2e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b30:	05b6                	slli	a1,a1,0xd
    80001b32:	8526                	mv	a0,s1
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	5e2080e7          	jalr	1506(ra) # 80001116 <mappages>
    80001b3c:	02054163          	bltz	a0,80001b5e <proc_pagetable+0x76>
}
    80001b40:	8526                	mv	a0,s1
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6902                	ld	s2,0(sp)
    80001b4a:	6105                	addi	sp,sp,32
    80001b4c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b4e:	4581                	li	a1,0
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	a54080e7          	jalr	-1452(ra) # 800015a6 <uvmfree>
    return 0;
    80001b5a:	4481                	li	s1,0
    80001b5c:	b7d5                	j	80001b40 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b5e:	4681                	li	a3,0
    80001b60:	4605                	li	a2,1
    80001b62:	040005b7          	lui	a1,0x4000
    80001b66:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b68:	05b2                	slli	a1,a1,0xc
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	770080e7          	jalr	1904(ra) # 800012dc <uvmunmap>
    uvmfree(pagetable, 0);
    80001b74:	4581                	li	a1,0
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	a2e080e7          	jalr	-1490(ra) # 800015a6 <uvmfree>
    return 0;
    80001b80:	4481                	li	s1,0
    80001b82:	bf7d                	j	80001b40 <proc_pagetable+0x58>

0000000080001b84 <proc_freepagetable>:
{
    80001b84:	1101                	addi	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	e04a                	sd	s2,0(sp)
    80001b8e:	1000                	addi	s0,sp,32
    80001b90:	84aa                	mv	s1,a0
    80001b92:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b94:	4681                	li	a3,0
    80001b96:	4605                	li	a2,1
    80001b98:	040005b7          	lui	a1,0x4000
    80001b9c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b9e:	05b2                	slli	a1,a1,0xc
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	73c080e7          	jalr	1852(ra) # 800012dc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	020005b7          	lui	a1,0x2000
    80001bb0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bb2:	05b6                	slli	a1,a1,0xd
    80001bb4:	8526                	mv	a0,s1
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	726080e7          	jalr	1830(ra) # 800012dc <uvmunmap>
  uvmfree(pagetable, sz);
    80001bbe:	85ca                	mv	a1,s2
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	9e4080e7          	jalr	-1564(ra) # 800015a6 <uvmfree>
}
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6902                	ld	s2,0(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <freeproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	1000                	addi	s0,sp,32
    80001be0:	84aa                	mv	s1,a0
  if (strncmp(p->name, "vm-", 3) == 0) {
    80001be2:	460d                	li	a2,3
    80001be4:	00006597          	auipc	a1,0x6
    80001be8:	61c58593          	addi	a1,a1,1564 # 80008200 <digits+0x1c0>
    80001bec:	15850513          	addi	a0,a0,344
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	224080e7          	jalr	548(ra) # 80000e14 <strncmp>
    80001bf8:	c539                	beqz	a0,80001c46 <freeproc+0x70>
  if(p->trapframe)
    80001bfa:	6ca8                	ld	a0,88(s1)
    80001bfc:	c509                	beqz	a0,80001c06 <freeproc+0x30>
    kfree((void*)p->trapframe);
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	e5c080e7          	jalr	-420(ra) # 80000a5a <kfree>
  p->trapframe = 0;
    80001c06:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c0a:	68a8                	ld	a0,80(s1)
    80001c0c:	c511                	beqz	a0,80001c18 <freeproc+0x42>
    proc_freepagetable(p->pagetable, p->sz);
    80001c0e:	64ac                	ld	a1,72(s1)
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	f74080e7          	jalr	-140(ra) # 80001b84 <proc_freepagetable>
  p->pagetable = 0;
    80001c18:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c1c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c20:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c24:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c28:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c2c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c30:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c34:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c38:	0004ac23          	sw	zero,24(s1)
}
    80001c3c:	60e2                	ld	ra,24(sp)
    80001c3e:	6442                	ld	s0,16(sp)
    80001c40:	64a2                	ld	s1,8(sp)
    80001c42:	6105                	addi	sp,sp,32
    80001c44:	8082                	ret
    uvmunmap(p->pagetable, memaddr_start, memaddr_count, 0);
    80001c46:	4681                	li	a3,0
    80001c48:	40000613          	li	a2,1024
    80001c4c:	4585                	li	a1,1
    80001c4e:	05fe                	slli	a1,a1,0x1f
    80001c50:	68a8                	ld	a0,80(s1)
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	68a080e7          	jalr	1674(ra) # 800012dc <uvmunmap>
    80001c5a:	b745                	j	80001bfa <freeproc+0x24>

0000000080001c5c <allocproc>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c68:	0000f497          	auipc	s1,0xf
    80001c6c:	42848493          	addi	s1,s1,1064 # 80011090 <proc>
    80001c70:	00015917          	auipc	s2,0x15
    80001c74:	02090913          	addi	s2,s2,32 # 80016c90 <tickslock>
    acquire(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	fce080e7          	jalr	-50(ra) # 80000c48 <acquire>
    if(p->state == UNUSED) {
    80001c82:	4c9c                	lw	a5,24(s1)
    80001c84:	cf81                	beqz	a5,80001c9c <allocproc+0x40>
      release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	074080e7          	jalr	116(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c90:	17048493          	addi	s1,s1,368
    80001c94:	ff2492e3          	bne	s1,s2,80001c78 <allocproc+0x1c>
  return 0;
    80001c98:	4481                	li	s1,0
    80001c9a:	a889                	j	80001cec <allocproc+0x90>
  p->pid = allocpid();
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	e06080e7          	jalr	-506(ra) # 80001aa2 <allocpid>
    80001ca4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ca6:	4785                	li	a5,1
    80001ca8:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	eae080e7          	jalr	-338(ra) # 80000b58 <kalloc>
    80001cb2:	892a                	mv	s2,a0
    80001cb4:	eca8                	sd	a0,88(s1)
    80001cb6:	c131                	beqz	a0,80001cfa <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	e2e080e7          	jalr	-466(ra) # 80001ae8 <proc_pagetable>
    80001cc2:	892a                	mv	s2,a0
    80001cc4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cc6:	c531                	beqz	a0,80001d12 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001cc8:	07000613          	li	a2,112
    80001ccc:	4581                	li	a1,0
    80001cce:	06048513          	addi	a0,s1,96
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	072080e7          	jalr	114(ra) # 80000d44 <memset>
  p->context.ra = (uint64)forkret;
    80001cda:	00000797          	auipc	a5,0x0
    80001cde:	d8278793          	addi	a5,a5,-638 # 80001a5c <forkret>
    80001ce2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce4:	60bc                	ld	a5,64(s1)
    80001ce6:	6705                	lui	a4,0x1
    80001ce8:	97ba                	add	a5,a5,a4
    80001cea:	f4bc                	sd	a5,104(s1)
}
    80001cec:	8526                	mv	a0,s1
    80001cee:	60e2                	ld	ra,24(sp)
    80001cf0:	6442                	ld	s0,16(sp)
    80001cf2:	64a2                	ld	s1,8(sp)
    80001cf4:	6902                	ld	s2,0(sp)
    80001cf6:	6105                	addi	sp,sp,32
    80001cf8:	8082                	ret
    freeproc(p);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	eda080e7          	jalr	-294(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	ff6080e7          	jalr	-10(ra) # 80000cfc <release>
    return 0;
    80001d0e:	84ca                	mv	s1,s2
    80001d10:	bff1                	j	80001cec <allocproc+0x90>
    freeproc(p);
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	ec2080e7          	jalr	-318(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	fde080e7          	jalr	-34(ra) # 80000cfc <release>
    return 0;
    80001d26:	84ca                	mv	s1,s2
    80001d28:	b7d1                	j	80001cec <allocproc+0x90>

0000000080001d2a <userinit>:
{
    80001d2a:	1101                	addi	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	f28080e7          	jalr	-216(ra) # 80001c5c <allocproc>
    80001d3c:	84aa                	mv	s1,a0
  initproc = p;
    80001d3e:	00007797          	auipc	a5,0x7
    80001d42:	caa7b523          	sd	a0,-854(a5) # 800089e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d46:	03400613          	li	a2,52
    80001d4a:	00007597          	auipc	a1,0x7
    80001d4e:	c3658593          	addi	a1,a1,-970 # 80008980 <initcode>
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	67a080e7          	jalr	1658(ra) # 800013ce <uvmfirst>
  p->sz = PGSIZE;
    80001d5c:	6785                	lui	a5,0x1
    80001d5e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d60:	6cb8                	ld	a4,88(s1)
    80001d62:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d66:	6cb8                	ld	a4,88(s1)
    80001d68:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d6a:	4641                	li	a2,16
    80001d6c:	00006597          	auipc	a1,0x6
    80001d70:	49c58593          	addi	a1,a1,1180 # 80008208 <digits+0x1c8>
    80001d74:	15848513          	addi	a0,s1,344
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	114080e7          	jalr	276(ra) # 80000e8c <safestrcpy>
  p->cwd = namei("/");
    80001d80:	00006517          	auipc	a0,0x6
    80001d84:	49850513          	addi	a0,a0,1176 # 80008218 <digits+0x1d8>
    80001d88:	00002097          	auipc	ra,0x2
    80001d8c:	146080e7          	jalr	326(ra) # 80003ece <namei>
    80001d90:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d94:	478d                	li	a5,3
    80001d96:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d98:	8526                	mv	a0,s1
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	f62080e7          	jalr	-158(ra) # 80000cfc <release>
}
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6105                	addi	sp,sp,32
    80001daa:	8082                	ret

0000000080001dac <growproc>:
{
    80001dac:	1101                	addi	sp,sp,-32
    80001dae:	ec06                	sd	ra,24(sp)
    80001db0:	e822                	sd	s0,16(sp)
    80001db2:	e426                	sd	s1,8(sp)
    80001db4:	e04a                	sd	s2,0(sp)
    80001db6:	1000                	addi	s0,sp,32
    80001db8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	c6a080e7          	jalr	-918(ra) # 80001a24 <myproc>
    80001dc2:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dc4:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001dc6:	01204c63          	bgtz	s2,80001dde <growproc+0x32>
  } else if(n < 0){
    80001dca:	02094663          	bltz	s2,80001df6 <growproc+0x4a>
  p->sz = sz;
    80001dce:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dd0:	4501                	li	a0,0
}
    80001dd2:	60e2                	ld	ra,24(sp)
    80001dd4:	6442                	ld	s0,16(sp)
    80001dd6:	64a2                	ld	s1,8(sp)
    80001dd8:	6902                	ld	s2,0(sp)
    80001dda:	6105                	addi	sp,sp,32
    80001ddc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001dde:	4691                	li	a3,4
    80001de0:	00b90633          	add	a2,s2,a1
    80001de4:	6928                	ld	a0,80(a0)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	6a2080e7          	jalr	1698(ra) # 80001488 <uvmalloc>
    80001dee:	85aa                	mv	a1,a0
    80001df0:	fd79                	bnez	a0,80001dce <growproc+0x22>
      return -1;
    80001df2:	557d                	li	a0,-1
    80001df4:	bff9                	j	80001dd2 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001df6:	00b90633          	add	a2,s2,a1
    80001dfa:	6928                	ld	a0,80(a0)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	644080e7          	jalr	1604(ra) # 80001440 <uvmdealloc>
    80001e04:	85aa                	mv	a1,a0
    80001e06:	b7e1                	j	80001dce <growproc+0x22>

0000000080001e08 <fork>:
{
    80001e08:	7139                	addi	sp,sp,-64
    80001e0a:	fc06                	sd	ra,56(sp)
    80001e0c:	f822                	sd	s0,48(sp)
    80001e0e:	f426                	sd	s1,40(sp)
    80001e10:	f04a                	sd	s2,32(sp)
    80001e12:	ec4e                	sd	s3,24(sp)
    80001e14:	e852                	sd	s4,16(sp)
    80001e16:	e456                	sd	s5,8(sp)
    80001e18:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	c0a080e7          	jalr	-1014(ra) # 80001a24 <myproc>
    80001e22:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	e38080e7          	jalr	-456(ra) # 80001c5c <allocproc>
    80001e2c:	10050c63          	beqz	a0,80001f44 <fork+0x13c>
    80001e30:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e32:	048ab603          	ld	a2,72(s5)
    80001e36:	692c                	ld	a1,80(a0)
    80001e38:	050ab503          	ld	a0,80(s5)
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	7a4080e7          	jalr	1956(ra) # 800015e0 <uvmcopy>
    80001e44:	04054863          	bltz	a0,80001e94 <fork+0x8c>
  np->sz = p->sz;
    80001e48:	048ab783          	ld	a5,72(s5)
    80001e4c:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e50:	058ab683          	ld	a3,88(s5)
    80001e54:	87b6                	mv	a5,a3
    80001e56:	058a3703          	ld	a4,88(s4)
    80001e5a:	12068693          	addi	a3,a3,288
    80001e5e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e62:	6788                	ld	a0,8(a5)
    80001e64:	6b8c                	ld	a1,16(a5)
    80001e66:	6f90                	ld	a2,24(a5)
    80001e68:	01073023          	sd	a6,0(a4)
    80001e6c:	e708                	sd	a0,8(a4)
    80001e6e:	eb0c                	sd	a1,16(a4)
    80001e70:	ef10                	sd	a2,24(a4)
    80001e72:	02078793          	addi	a5,a5,32
    80001e76:	02070713          	addi	a4,a4,32
    80001e7a:	fed792e3          	bne	a5,a3,80001e5e <fork+0x56>
  np->trapframe->a0 = 0;
    80001e7e:	058a3783          	ld	a5,88(s4)
    80001e82:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e86:	0d0a8493          	addi	s1,s5,208
    80001e8a:	0d0a0913          	addi	s2,s4,208
    80001e8e:	150a8993          	addi	s3,s5,336
    80001e92:	a00d                	j	80001eb4 <fork+0xac>
    freeproc(np);
    80001e94:	8552                	mv	a0,s4
    80001e96:	00000097          	auipc	ra,0x0
    80001e9a:	d40080e7          	jalr	-704(ra) # 80001bd6 <freeproc>
    release(&np->lock);
    80001e9e:	8552                	mv	a0,s4
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	e5c080e7          	jalr	-420(ra) # 80000cfc <release>
    return -1;
    80001ea8:	597d                	li	s2,-1
    80001eaa:	a059                	j	80001f30 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001eac:	04a1                	addi	s1,s1,8
    80001eae:	0921                	addi	s2,s2,8
    80001eb0:	01348b63          	beq	s1,s3,80001ec6 <fork+0xbe>
    if(p->ofile[i])
    80001eb4:	6088                	ld	a0,0(s1)
    80001eb6:	d97d                	beqz	a0,80001eac <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb8:	00002097          	auipc	ra,0x2
    80001ebc:	688080e7          	jalr	1672(ra) # 80004540 <filedup>
    80001ec0:	00a93023          	sd	a0,0(s2)
    80001ec4:	b7e5                	j	80001eac <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ec6:	150ab503          	ld	a0,336(s5)
    80001eca:	00002097          	auipc	ra,0x2
    80001ece:	820080e7          	jalr	-2016(ra) # 800036ea <idup>
    80001ed2:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ed6:	4641                	li	a2,16
    80001ed8:	158a8593          	addi	a1,s5,344
    80001edc:	158a0513          	addi	a0,s4,344
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	fac080e7          	jalr	-84(ra) # 80000e8c <safestrcpy>
  pid = np->pid;
    80001ee8:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001eec:	8552                	mv	a0,s4
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	e0e080e7          	jalr	-498(ra) # 80000cfc <release>
  acquire(&wait_lock);
    80001ef6:	0000f497          	auipc	s1,0xf
    80001efa:	d8248493          	addi	s1,s1,-638 # 80010c78 <wait_lock>
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d48080e7          	jalr	-696(ra) # 80000c48 <acquire>
  np->parent = p;
    80001f08:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	dee080e7          	jalr	-530(ra) # 80000cfc <release>
  acquire(&np->lock);
    80001f16:	8552                	mv	a0,s4
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d30080e7          	jalr	-720(ra) # 80000c48 <acquire>
  np->state = RUNNABLE;
    80001f20:	478d                	li	a5,3
    80001f22:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f26:	8552                	mv	a0,s4
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	dd4080e7          	jalr	-556(ra) # 80000cfc <release>
}
    80001f30:	854a                	mv	a0,s2
    80001f32:	70e2                	ld	ra,56(sp)
    80001f34:	7442                	ld	s0,48(sp)
    80001f36:	74a2                	ld	s1,40(sp)
    80001f38:	7902                	ld	s2,32(sp)
    80001f3a:	69e2                	ld	s3,24(sp)
    80001f3c:	6a42                	ld	s4,16(sp)
    80001f3e:	6aa2                	ld	s5,8(sp)
    80001f40:	6121                	addi	sp,sp,64
    80001f42:	8082                	ret
    return -1;
    80001f44:	597d                	li	s2,-1
    80001f46:	b7ed                	j	80001f30 <fork+0x128>

0000000080001f48 <scheduler>:
{
    80001f48:	7139                	addi	sp,sp,-64
    80001f4a:	fc06                	sd	ra,56(sp)
    80001f4c:	f822                	sd	s0,48(sp)
    80001f4e:	f426                	sd	s1,40(sp)
    80001f50:	f04a                	sd	s2,32(sp)
    80001f52:	ec4e                	sd	s3,24(sp)
    80001f54:	e852                	sd	s4,16(sp)
    80001f56:	e456                	sd	s5,8(sp)
    80001f58:	e05a                	sd	s6,0(sp)
    80001f5a:	0080                	addi	s0,sp,64
    80001f5c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f5e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f60:	00779a93          	slli	s5,a5,0x7
    80001f64:	0000f717          	auipc	a4,0xf
    80001f68:	cfc70713          	addi	a4,a4,-772 # 80010c60 <pid_lock>
    80001f6c:	9756                	add	a4,a4,s5
    80001f6e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f72:	0000f717          	auipc	a4,0xf
    80001f76:	d2670713          	addi	a4,a4,-730 # 80010c98 <cpus+0x8>
    80001f7a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f7c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f7e:	4b11                	li	s6,4
        c->proc = p;
    80001f80:	079e                	slli	a5,a5,0x7
    80001f82:	0000fa17          	auipc	s4,0xf
    80001f86:	cdea0a13          	addi	s4,s4,-802 # 80010c60 <pid_lock>
    80001f8a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8c:	00015917          	auipc	s2,0x15
    80001f90:	d0490913          	addi	s2,s2,-764 # 80016c90 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9c:	10079073          	csrw	sstatus,a5
    80001fa0:	0000f497          	auipc	s1,0xf
    80001fa4:	0f048493          	addi	s1,s1,240 # 80011090 <proc>
    80001fa8:	a811                	j	80001fbc <scheduler+0x74>
      release(&p->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	d50080e7          	jalr	-688(ra) # 80000cfc <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	17048493          	addi	s1,s1,368
    80001fb8:	fd248ee3          	beq	s1,s2,80001f94 <scheduler+0x4c>
      acquire(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	c8a080e7          	jalr	-886(ra) # 80000c48 <acquire>
      if(p->state == RUNNABLE) {
    80001fc6:	4c9c                	lw	a5,24(s1)
    80001fc8:	ff3791e3          	bne	a5,s3,80001faa <scheduler+0x62>
        p->state = RUNNING;
    80001fcc:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fd0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fd4:	06048593          	addi	a1,s1,96
    80001fd8:	8556                	mv	a0,s5
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	684080e7          	jalr	1668(ra) # 8000265e <swtch>
        c->proc = 0;
    80001fe2:	020a3823          	sd	zero,48(s4)
    80001fe6:	b7d1                	j	80001faa <scheduler+0x62>

0000000080001fe8 <sched>:
{
    80001fe8:	7179                	addi	sp,sp,-48
    80001fea:	f406                	sd	ra,40(sp)
    80001fec:	f022                	sd	s0,32(sp)
    80001fee:	ec26                	sd	s1,24(sp)
    80001ff0:	e84a                	sd	s2,16(sp)
    80001ff2:	e44e                	sd	s3,8(sp)
    80001ff4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	a2e080e7          	jalr	-1490(ra) # 80001a24 <myproc>
    80001ffe:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	bce080e7          	jalr	-1074(ra) # 80000bce <holding>
    80002008:	c93d                	beqz	a0,8000207e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000200a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	0000f717          	auipc	a4,0xf
    80002014:	c5070713          	addi	a4,a4,-944 # 80010c60 <pid_lock>
    80002018:	97ba                	add	a5,a5,a4
    8000201a:	0a87a703          	lw	a4,168(a5)
    8000201e:	4785                	li	a5,1
    80002020:	06f71763          	bne	a4,a5,8000208e <sched+0xa6>
  if(p->state == RUNNING)
    80002024:	4c98                	lw	a4,24(s1)
    80002026:	4791                	li	a5,4
    80002028:	06f70b63          	beq	a4,a5,8000209e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002030:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002032:	efb5                	bnez	a5,800020ae <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002034:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002036:	0000f917          	auipc	s2,0xf
    8000203a:	c2a90913          	addi	s2,s2,-982 # 80010c60 <pid_lock>
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	97ca                	add	a5,a5,s2
    80002044:	0ac7a983          	lw	s3,172(a5)
    80002048:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000204a:	2781                	sext.w	a5,a5
    8000204c:	079e                	slli	a5,a5,0x7
    8000204e:	0000f597          	auipc	a1,0xf
    80002052:	c4a58593          	addi	a1,a1,-950 # 80010c98 <cpus+0x8>
    80002056:	95be                	add	a1,a1,a5
    80002058:	06048513          	addi	a0,s1,96
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	602080e7          	jalr	1538(ra) # 8000265e <swtch>
    80002064:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	993e                	add	s2,s2,a5
    8000206c:	0b392623          	sw	s3,172(s2)
}
    80002070:	70a2                	ld	ra,40(sp)
    80002072:	7402                	ld	s0,32(sp)
    80002074:	64e2                	ld	s1,24(sp)
    80002076:	6942                	ld	s2,16(sp)
    80002078:	69a2                	ld	s3,8(sp)
    8000207a:	6145                	addi	sp,sp,48
    8000207c:	8082                	ret
    panic("sched p->lock");
    8000207e:	00006517          	auipc	a0,0x6
    80002082:	1a250513          	addi	a0,a0,418 # 80008220 <digits+0x1e0>
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	4ba080e7          	jalr	1210(ra) # 80000540 <panic>
    panic("sched locks");
    8000208e:	00006517          	auipc	a0,0x6
    80002092:	1a250513          	addi	a0,a0,418 # 80008230 <digits+0x1f0>
    80002096:	ffffe097          	auipc	ra,0xffffe
    8000209a:	4aa080e7          	jalr	1194(ra) # 80000540 <panic>
    panic("sched running");
    8000209e:	00006517          	auipc	a0,0x6
    800020a2:	1a250513          	addi	a0,a0,418 # 80008240 <digits+0x200>
    800020a6:	ffffe097          	auipc	ra,0xffffe
    800020aa:	49a080e7          	jalr	1178(ra) # 80000540 <panic>
    panic("sched interruptible");
    800020ae:	00006517          	auipc	a0,0x6
    800020b2:	1a250513          	addi	a0,a0,418 # 80008250 <digits+0x210>
    800020b6:	ffffe097          	auipc	ra,0xffffe
    800020ba:	48a080e7          	jalr	1162(ra) # 80000540 <panic>

00000000800020be <yield>:
{
    800020be:	1101                	addi	sp,sp,-32
    800020c0:	ec06                	sd	ra,24(sp)
    800020c2:	e822                	sd	s0,16(sp)
    800020c4:	e426                	sd	s1,8(sp)
    800020c6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	95c080e7          	jalr	-1700(ra) # 80001a24 <myproc>
    800020d0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b76080e7          	jalr	-1162(ra) # 80000c48 <acquire>
  p->state = RUNNABLE;
    800020da:	478d                	li	a5,3
    800020dc:	cc9c                	sw	a5,24(s1)
  sched();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	f0a080e7          	jalr	-246(ra) # 80001fe8 <sched>
  release(&p->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	c14080e7          	jalr	-1004(ra) # 80000cfc <release>
}
    800020f0:	60e2                	ld	ra,24(sp)
    800020f2:	6442                	ld	s0,16(sp)
    800020f4:	64a2                	ld	s1,8(sp)
    800020f6:	6105                	addi	sp,sp,32
    800020f8:	8082                	ret

00000000800020fa <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020fa:	7179                	addi	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	1800                	addi	s0,sp,48
    80002108:	89aa                	mv	s3,a0
    8000210a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	918080e7          	jalr	-1768(ra) # 80001a24 <myproc>
    80002114:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	b32080e7          	jalr	-1230(ra) # 80000c48 <acquire>
  release(lk);
    8000211e:	854a                	mv	a0,s2
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	bdc080e7          	jalr	-1060(ra) # 80000cfc <release>

  // Go to sleep.
  p->chan = chan;
    80002128:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000212c:	4789                	li	a5,2
    8000212e:	cc9c                	sw	a5,24(s1)

  sched();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	eb8080e7          	jalr	-328(ra) # 80001fe8 <sched>

  // Tidy up.
  p->chan = 0;
    80002138:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	bbe080e7          	jalr	-1090(ra) # 80000cfc <release>
  acquire(lk);
    80002146:	854a                	mv	a0,s2
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b00080e7          	jalr	-1280(ra) # 80000c48 <acquire>
}
    80002150:	70a2                	ld	ra,40(sp)
    80002152:	7402                	ld	s0,32(sp)
    80002154:	64e2                	ld	s1,24(sp)
    80002156:	6942                	ld	s2,16(sp)
    80002158:	69a2                	ld	s3,8(sp)
    8000215a:	6145                	addi	sp,sp,48
    8000215c:	8082                	ret

000000008000215e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000215e:	7139                	addi	sp,sp,-64
    80002160:	fc06                	sd	ra,56(sp)
    80002162:	f822                	sd	s0,48(sp)
    80002164:	f426                	sd	s1,40(sp)
    80002166:	f04a                	sd	s2,32(sp)
    80002168:	ec4e                	sd	s3,24(sp)
    8000216a:	e852                	sd	s4,16(sp)
    8000216c:	e456                	sd	s5,8(sp)
    8000216e:	0080                	addi	s0,sp,64
    80002170:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002172:	0000f497          	auipc	s1,0xf
    80002176:	f1e48493          	addi	s1,s1,-226 # 80011090 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000217a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000217c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217e:	00015917          	auipc	s2,0x15
    80002182:	b1290913          	addi	s2,s2,-1262 # 80016c90 <tickslock>
    80002186:	a811                	j	8000219a <wakeup+0x3c>
      }
      release(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	b72080e7          	jalr	-1166(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002192:	17048493          	addi	s1,s1,368
    80002196:	03248663          	beq	s1,s2,800021c2 <wakeup+0x64>
    if(p != myproc()){
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	88a080e7          	jalr	-1910(ra) # 80001a24 <myproc>
    800021a2:	fea488e3          	beq	s1,a0,80002192 <wakeup+0x34>
      acquire(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	aa0080e7          	jalr	-1376(ra) # 80000c48 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021b0:	4c9c                	lw	a5,24(s1)
    800021b2:	fd379be3          	bne	a5,s3,80002188 <wakeup+0x2a>
    800021b6:	709c                	ld	a5,32(s1)
    800021b8:	fd4798e3          	bne	a5,s4,80002188 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021bc:	0154ac23          	sw	s5,24(s1)
    800021c0:	b7e1                	j	80002188 <wakeup+0x2a>
    }
  }
}
    800021c2:	70e2                	ld	ra,56(sp)
    800021c4:	7442                	ld	s0,48(sp)
    800021c6:	74a2                	ld	s1,40(sp)
    800021c8:	7902                	ld	s2,32(sp)
    800021ca:	69e2                	ld	s3,24(sp)
    800021cc:	6a42                	ld	s4,16(sp)
    800021ce:	6aa2                	ld	s5,8(sp)
    800021d0:	6121                	addi	sp,sp,64
    800021d2:	8082                	ret

00000000800021d4 <reparent>:
{
    800021d4:	7179                	addi	sp,sp,-48
    800021d6:	f406                	sd	ra,40(sp)
    800021d8:	f022                	sd	s0,32(sp)
    800021da:	ec26                	sd	s1,24(sp)
    800021dc:	e84a                	sd	s2,16(sp)
    800021de:	e44e                	sd	s3,8(sp)
    800021e0:	e052                	sd	s4,0(sp)
    800021e2:	1800                	addi	s0,sp,48
    800021e4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e6:	0000f497          	auipc	s1,0xf
    800021ea:	eaa48493          	addi	s1,s1,-342 # 80011090 <proc>
      pp->parent = initproc;
    800021ee:	00006a17          	auipc	s4,0x6
    800021f2:	7faa0a13          	addi	s4,s4,2042 # 800089e8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f6:	00015997          	auipc	s3,0x15
    800021fa:	a9a98993          	addi	s3,s3,-1382 # 80016c90 <tickslock>
    800021fe:	a029                	j	80002208 <reparent+0x34>
    80002200:	17048493          	addi	s1,s1,368
    80002204:	01348d63          	beq	s1,s3,8000221e <reparent+0x4a>
    if(pp->parent == p){
    80002208:	7c9c                	ld	a5,56(s1)
    8000220a:	ff279be3          	bne	a5,s2,80002200 <reparent+0x2c>
      pp->parent = initproc;
    8000220e:	000a3503          	ld	a0,0(s4)
    80002212:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f4a080e7          	jalr	-182(ra) # 8000215e <wakeup>
    8000221c:	b7d5                	j	80002200 <reparent+0x2c>
}
    8000221e:	70a2                	ld	ra,40(sp)
    80002220:	7402                	ld	s0,32(sp)
    80002222:	64e2                	ld	s1,24(sp)
    80002224:	6942                	ld	s2,16(sp)
    80002226:	69a2                	ld	s3,8(sp)
    80002228:	6a02                	ld	s4,0(sp)
    8000222a:	6145                	addi	sp,sp,48
    8000222c:	8082                	ret

000000008000222e <exit>:
{
    8000222e:	7179                	addi	sp,sp,-48
    80002230:	f406                	sd	ra,40(sp)
    80002232:	f022                	sd	s0,32(sp)
    80002234:	ec26                	sd	s1,24(sp)
    80002236:	e84a                	sd	s2,16(sp)
    80002238:	e44e                	sd	s3,8(sp)
    8000223a:	e052                	sd	s4,0(sp)
    8000223c:	1800                	addi	s0,sp,48
    8000223e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	7e4080e7          	jalr	2020(ra) # 80001a24 <myproc>
    80002248:	89aa                	mv	s3,a0
  if(p == initproc)
    8000224a:	00006797          	auipc	a5,0x6
    8000224e:	79e7b783          	ld	a5,1950(a5) # 800089e8 <initproc>
    80002252:	0d050493          	addi	s1,a0,208
    80002256:	15050913          	addi	s2,a0,336
    8000225a:	02a79363          	bne	a5,a0,80002280 <exit+0x52>
    panic("init exiting");
    8000225e:	00006517          	auipc	a0,0x6
    80002262:	00a50513          	addi	a0,a0,10 # 80008268 <digits+0x228>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2da080e7          	jalr	730(ra) # 80000540 <panic>
      fileclose(f);
    8000226e:	00002097          	auipc	ra,0x2
    80002272:	324080e7          	jalr	804(ra) # 80004592 <fileclose>
      p->ofile[fd] = 0;
    80002276:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000227a:	04a1                	addi	s1,s1,8
    8000227c:	01248563          	beq	s1,s2,80002286 <exit+0x58>
    if(p->ofile[fd]){
    80002280:	6088                	ld	a0,0(s1)
    80002282:	f575                	bnez	a0,8000226e <exit+0x40>
    80002284:	bfdd                	j	8000227a <exit+0x4c>
  begin_op();
    80002286:	00002097          	auipc	ra,0x2
    8000228a:	e48080e7          	jalr	-440(ra) # 800040ce <begin_op>
  iput(p->cwd);
    8000228e:	1509b503          	ld	a0,336(s3)
    80002292:	00001097          	auipc	ra,0x1
    80002296:	650080e7          	jalr	1616(ra) # 800038e2 <iput>
  end_op();
    8000229a:	00002097          	auipc	ra,0x2
    8000229e:	eae080e7          	jalr	-338(ra) # 80004148 <end_op>
  p->cwd = 0;
    800022a2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022a6:	0000f497          	auipc	s1,0xf
    800022aa:	9d248493          	addi	s1,s1,-1582 # 80010c78 <wait_lock>
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	998080e7          	jalr	-1640(ra) # 80000c48 <acquire>
  reparent(p);
    800022b8:	854e                	mv	a0,s3
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	f1a080e7          	jalr	-230(ra) # 800021d4 <reparent>
  wakeup(p->parent);
    800022c2:	0389b503          	ld	a0,56(s3)
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	e98080e7          	jalr	-360(ra) # 8000215e <wakeup>
  acquire(&p->lock);
    800022ce:	854e                	mv	a0,s3
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	978080e7          	jalr	-1672(ra) # 80000c48 <acquire>
  p->xstate = status;
    800022d8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022dc:	4795                	li	a5,5
    800022de:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	a18080e7          	jalr	-1512(ra) # 80000cfc <release>
  sched();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	cfc080e7          	jalr	-772(ra) # 80001fe8 <sched>
  panic("zombie exit");
    800022f4:	00006517          	auipc	a0,0x6
    800022f8:	f8450513          	addi	a0,a0,-124 # 80008278 <digits+0x238>
    800022fc:	ffffe097          	auipc	ra,0xffffe
    80002300:	244080e7          	jalr	580(ra) # 80000540 <panic>

0000000080002304 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002304:	7179                	addi	sp,sp,-48
    80002306:	f406                	sd	ra,40(sp)
    80002308:	f022                	sd	s0,32(sp)
    8000230a:	ec26                	sd	s1,24(sp)
    8000230c:	e84a                	sd	s2,16(sp)
    8000230e:	e44e                	sd	s3,8(sp)
    80002310:	1800                	addi	s0,sp,48
    80002312:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002314:	0000f497          	auipc	s1,0xf
    80002318:	d7c48493          	addi	s1,s1,-644 # 80011090 <proc>
    8000231c:	00015997          	auipc	s3,0x15
    80002320:	97498993          	addi	s3,s3,-1676 # 80016c90 <tickslock>
    acquire(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	922080e7          	jalr	-1758(ra) # 80000c48 <acquire>
    if(p->pid == pid){
    8000232e:	589c                	lw	a5,48(s1)
    80002330:	01278d63          	beq	a5,s2,8000234a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	9c6080e7          	jalr	-1594(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000233e:	17048493          	addi	s1,s1,368
    80002342:	ff3491e3          	bne	s1,s3,80002324 <kill+0x20>
  }
  return -1;
    80002346:	557d                	li	a0,-1
    80002348:	a829                	j	80002362 <kill+0x5e>
      p->killed = 1;
    8000234a:	4785                	li	a5,1
    8000234c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000234e:	4c98                	lw	a4,24(s1)
    80002350:	4789                	li	a5,2
    80002352:	00f70f63          	beq	a4,a5,80002370 <kill+0x6c>
      release(&p->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	9a4080e7          	jalr	-1628(ra) # 80000cfc <release>
      return 0;
    80002360:	4501                	li	a0,0
}
    80002362:	70a2                	ld	ra,40(sp)
    80002364:	7402                	ld	s0,32(sp)
    80002366:	64e2                	ld	s1,24(sp)
    80002368:	6942                	ld	s2,16(sp)
    8000236a:	69a2                	ld	s3,8(sp)
    8000236c:	6145                	addi	sp,sp,48
    8000236e:	8082                	ret
        p->state = RUNNABLE;
    80002370:	478d                	li	a5,3
    80002372:	cc9c                	sw	a5,24(s1)
    80002374:	b7cd                	j	80002356 <kill+0x52>

0000000080002376 <setkilled>:

void
setkilled(struct proc *p)
{
    80002376:	1101                	addi	sp,sp,-32
    80002378:	ec06                	sd	ra,24(sp)
    8000237a:	e822                	sd	s0,16(sp)
    8000237c:	e426                	sd	s1,8(sp)
    8000237e:	1000                	addi	s0,sp,32
    80002380:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	8c6080e7          	jalr	-1850(ra) # 80000c48 <acquire>
  p->killed = 1;
    8000238a:	4785                	li	a5,1
    8000238c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	96c080e7          	jalr	-1684(ra) # 80000cfc <release>
}
    80002398:	60e2                	ld	ra,24(sp)
    8000239a:	6442                	ld	s0,16(sp)
    8000239c:	64a2                	ld	s1,8(sp)
    8000239e:	6105                	addi	sp,sp,32
    800023a0:	8082                	ret

00000000800023a2 <killed>:

int
killed(struct proc *p)
{
    800023a2:	1101                	addi	sp,sp,-32
    800023a4:	ec06                	sd	ra,24(sp)
    800023a6:	e822                	sd	s0,16(sp)
    800023a8:	e426                	sd	s1,8(sp)
    800023aa:	e04a                	sd	s2,0(sp)
    800023ac:	1000                	addi	s0,sp,32
    800023ae:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	898080e7          	jalr	-1896(ra) # 80000c48 <acquire>
  k = p->killed;
    800023b8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	93e080e7          	jalr	-1730(ra) # 80000cfc <release>
  return k;
}
    800023c6:	854a                	mv	a0,s2
    800023c8:	60e2                	ld	ra,24(sp)
    800023ca:	6442                	ld	s0,16(sp)
    800023cc:	64a2                	ld	s1,8(sp)
    800023ce:	6902                	ld	s2,0(sp)
    800023d0:	6105                	addi	sp,sp,32
    800023d2:	8082                	ret

00000000800023d4 <wait>:
{
    800023d4:	715d                	addi	sp,sp,-80
    800023d6:	e486                	sd	ra,72(sp)
    800023d8:	e0a2                	sd	s0,64(sp)
    800023da:	fc26                	sd	s1,56(sp)
    800023dc:	f84a                	sd	s2,48(sp)
    800023de:	f44e                	sd	s3,40(sp)
    800023e0:	f052                	sd	s4,32(sp)
    800023e2:	ec56                	sd	s5,24(sp)
    800023e4:	e85a                	sd	s6,16(sp)
    800023e6:	e45e                	sd	s7,8(sp)
    800023e8:	e062                	sd	s8,0(sp)
    800023ea:	0880                	addi	s0,sp,80
    800023ec:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	636080e7          	jalr	1590(ra) # 80001a24 <myproc>
    800023f6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023f8:	0000f517          	auipc	a0,0xf
    800023fc:	88050513          	addi	a0,a0,-1920 # 80010c78 <wait_lock>
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	848080e7          	jalr	-1976(ra) # 80000c48 <acquire>
    havekids = 0;
    80002408:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000240a:	4a15                	li	s4,5
        havekids = 1;
    8000240c:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000240e:	00015997          	auipc	s3,0x15
    80002412:	88298993          	addi	s3,s3,-1918 # 80016c90 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002416:	0000fc17          	auipc	s8,0xf
    8000241a:	862c0c13          	addi	s8,s8,-1950 # 80010c78 <wait_lock>
    8000241e:	a0d1                	j	800024e2 <wait+0x10e>
          pid = pp->pid;
    80002420:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002424:	000b0e63          	beqz	s6,80002440 <wait+0x6c>
    80002428:	4691                	li	a3,4
    8000242a:	02c48613          	addi	a2,s1,44
    8000242e:	85da                	mv	a1,s6
    80002430:	05093503          	ld	a0,80(s2)
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	2b0080e7          	jalr	688(ra) # 800016e4 <copyout>
    8000243c:	04054163          	bltz	a0,8000247e <wait+0xaa>
          freeproc(pp);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	794080e7          	jalr	1940(ra) # 80001bd6 <freeproc>
          release(&pp->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	8b0080e7          	jalr	-1872(ra) # 80000cfc <release>
          release(&wait_lock);
    80002454:	0000f517          	auipc	a0,0xf
    80002458:	82450513          	addi	a0,a0,-2012 # 80010c78 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	8a0080e7          	jalr	-1888(ra) # 80000cfc <release>
}
    80002464:	854e                	mv	a0,s3
    80002466:	60a6                	ld	ra,72(sp)
    80002468:	6406                	ld	s0,64(sp)
    8000246a:	74e2                	ld	s1,56(sp)
    8000246c:	7942                	ld	s2,48(sp)
    8000246e:	79a2                	ld	s3,40(sp)
    80002470:	7a02                	ld	s4,32(sp)
    80002472:	6ae2                	ld	s5,24(sp)
    80002474:	6b42                	ld	s6,16(sp)
    80002476:	6ba2                	ld	s7,8(sp)
    80002478:	6c02                	ld	s8,0(sp)
    8000247a:	6161                	addi	sp,sp,80
    8000247c:	8082                	ret
            release(&pp->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	87c080e7          	jalr	-1924(ra) # 80000cfc <release>
            release(&wait_lock);
    80002488:	0000e517          	auipc	a0,0xe
    8000248c:	7f050513          	addi	a0,a0,2032 # 80010c78 <wait_lock>
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	86c080e7          	jalr	-1940(ra) # 80000cfc <release>
            return -1;
    80002498:	59fd                	li	s3,-1
    8000249a:	b7e9                	j	80002464 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000249c:	17048493          	addi	s1,s1,368
    800024a0:	03348463          	beq	s1,s3,800024c8 <wait+0xf4>
      if(pp->parent == p){
    800024a4:	7c9c                	ld	a5,56(s1)
    800024a6:	ff279be3          	bne	a5,s2,8000249c <wait+0xc8>
        acquire(&pp->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	79c080e7          	jalr	1948(ra) # 80000c48 <acquire>
        if(pp->state == ZOMBIE){
    800024b4:	4c9c                	lw	a5,24(s1)
    800024b6:	f74785e3          	beq	a5,s4,80002420 <wait+0x4c>
        release(&pp->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	840080e7          	jalr	-1984(ra) # 80000cfc <release>
        havekids = 1;
    800024c4:	8756                	mv	a4,s5
    800024c6:	bfd9                	j	8000249c <wait+0xc8>
    if(!havekids || killed(p)){
    800024c8:	c31d                	beqz	a4,800024ee <wait+0x11a>
    800024ca:	854a                	mv	a0,s2
    800024cc:	00000097          	auipc	ra,0x0
    800024d0:	ed6080e7          	jalr	-298(ra) # 800023a2 <killed>
    800024d4:	ed09                	bnez	a0,800024ee <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024d6:	85e2                	mv	a1,s8
    800024d8:	854a                	mv	a0,s2
    800024da:	00000097          	auipc	ra,0x0
    800024de:	c20080e7          	jalr	-992(ra) # 800020fa <sleep>
    havekids = 0;
    800024e2:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024e4:	0000f497          	auipc	s1,0xf
    800024e8:	bac48493          	addi	s1,s1,-1108 # 80011090 <proc>
    800024ec:	bf65                	j	800024a4 <wait+0xd0>
      release(&wait_lock);
    800024ee:	0000e517          	auipc	a0,0xe
    800024f2:	78a50513          	addi	a0,a0,1930 # 80010c78 <wait_lock>
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	806080e7          	jalr	-2042(ra) # 80000cfc <release>
      return -1;
    800024fe:	59fd                	li	s3,-1
    80002500:	b795                	j	80002464 <wait+0x90>

0000000080002502 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002502:	7179                	addi	sp,sp,-48
    80002504:	f406                	sd	ra,40(sp)
    80002506:	f022                	sd	s0,32(sp)
    80002508:	ec26                	sd	s1,24(sp)
    8000250a:	e84a                	sd	s2,16(sp)
    8000250c:	e44e                	sd	s3,8(sp)
    8000250e:	e052                	sd	s4,0(sp)
    80002510:	1800                	addi	s0,sp,48
    80002512:	84aa                	mv	s1,a0
    80002514:	892e                	mv	s2,a1
    80002516:	89b2                	mv	s3,a2
    80002518:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	50a080e7          	jalr	1290(ra) # 80001a24 <myproc>
  if(user_dst){
    80002522:	c08d                	beqz	s1,80002544 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002524:	86d2                	mv	a3,s4
    80002526:	864e                	mv	a2,s3
    80002528:	85ca                	mv	a1,s2
    8000252a:	6928                	ld	a0,80(a0)
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	1b8080e7          	jalr	440(ra) # 800016e4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002534:	70a2                	ld	ra,40(sp)
    80002536:	7402                	ld	s0,32(sp)
    80002538:	64e2                	ld	s1,24(sp)
    8000253a:	6942                	ld	s2,16(sp)
    8000253c:	69a2                	ld	s3,8(sp)
    8000253e:	6a02                	ld	s4,0(sp)
    80002540:	6145                	addi	sp,sp,48
    80002542:	8082                	ret
    memmove((char *)dst, src, len);
    80002544:	000a061b          	sext.w	a2,s4
    80002548:	85ce                	mv	a1,s3
    8000254a:	854a                	mv	a0,s2
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	854080e7          	jalr	-1964(ra) # 80000da0 <memmove>
    return 0;
    80002554:	8526                	mv	a0,s1
    80002556:	bff9                	j	80002534 <either_copyout+0x32>

0000000080002558 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002558:	7179                	addi	sp,sp,-48
    8000255a:	f406                	sd	ra,40(sp)
    8000255c:	f022                	sd	s0,32(sp)
    8000255e:	ec26                	sd	s1,24(sp)
    80002560:	e84a                	sd	s2,16(sp)
    80002562:	e44e                	sd	s3,8(sp)
    80002564:	e052                	sd	s4,0(sp)
    80002566:	1800                	addi	s0,sp,48
    80002568:	892a                	mv	s2,a0
    8000256a:	84ae                	mv	s1,a1
    8000256c:	89b2                	mv	s3,a2
    8000256e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	4b4080e7          	jalr	1204(ra) # 80001a24 <myproc>
  if(user_src){
    80002578:	c08d                	beqz	s1,8000259a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000257a:	86d2                	mv	a3,s4
    8000257c:	864e                	mv	a2,s3
    8000257e:	85ca                	mv	a1,s2
    80002580:	6928                	ld	a0,80(a0)
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	1ee080e7          	jalr	494(ra) # 80001770 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6a02                	ld	s4,0(sp)
    80002596:	6145                	addi	sp,sp,48
    80002598:	8082                	ret
    memmove(dst, (char*)src, len);
    8000259a:	000a061b          	sext.w	a2,s4
    8000259e:	85ce                	mv	a1,s3
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	7fe080e7          	jalr	2046(ra) # 80000da0 <memmove>
    return 0;
    800025aa:	8526                	mv	a0,s1
    800025ac:	bff9                	j	8000258a <either_copyin+0x32>

00000000800025ae <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ae:	715d                	addi	sp,sp,-80
    800025b0:	e486                	sd	ra,72(sp)
    800025b2:	e0a2                	sd	s0,64(sp)
    800025b4:	fc26                	sd	s1,56(sp)
    800025b6:	f84a                	sd	s2,48(sp)
    800025b8:	f44e                	sd	s3,40(sp)
    800025ba:	f052                	sd	s4,32(sp)
    800025bc:	ec56                	sd	s5,24(sp)
    800025be:	e85a                	sd	s6,16(sp)
    800025c0:	e45e                	sd	s7,8(sp)
    800025c2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025c4:	00006517          	auipc	a0,0x6
    800025c8:	b0450513          	addi	a0,a0,-1276 # 800080c8 <digits+0x88>
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fbe080e7          	jalr	-66(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d4:	0000f497          	auipc	s1,0xf
    800025d8:	c1448493          	addi	s1,s1,-1004 # 800111e8 <proc+0x158>
    800025dc:	00015917          	auipc	s2,0x15
    800025e0:	80c90913          	addi	s2,s2,-2036 # 80016de8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025e6:	00006997          	auipc	s3,0x6
    800025ea:	ca298993          	addi	s3,s3,-862 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800025ee:	00006a97          	auipc	s5,0x6
    800025f2:	ca2a8a93          	addi	s5,s5,-862 # 80008290 <digits+0x250>
    printf("\n");
    800025f6:	00006a17          	auipc	s4,0x6
    800025fa:	ad2a0a13          	addi	s4,s4,-1326 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025fe:	00006b97          	auipc	s7,0x6
    80002602:	cd2b8b93          	addi	s7,s7,-814 # 800082d0 <states.0>
    80002606:	a00d                	j	80002628 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002608:	ed86a583          	lw	a1,-296(a3)
    8000260c:	8556                	mv	a0,s5
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f7c080e7          	jalr	-132(ra) # 8000058a <printf>
    printf("\n");
    80002616:	8552                	mv	a0,s4
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f72080e7          	jalr	-142(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002620:	17048493          	addi	s1,s1,368
    80002624:	03248263          	beq	s1,s2,80002648 <procdump+0x9a>
    if(p->state == UNUSED)
    80002628:	86a6                	mv	a3,s1
    8000262a:	ec04a783          	lw	a5,-320(s1)
    8000262e:	dbed                	beqz	a5,80002620 <procdump+0x72>
      state = "???";
    80002630:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002632:	fcfb6be3          	bltu	s6,a5,80002608 <procdump+0x5a>
    80002636:	02079713          	slli	a4,a5,0x20
    8000263a:	01d75793          	srli	a5,a4,0x1d
    8000263e:	97de                	add	a5,a5,s7
    80002640:	6390                	ld	a2,0(a5)
    80002642:	f279                	bnez	a2,80002608 <procdump+0x5a>
      state = "???";
    80002644:	864e                	mv	a2,s3
    80002646:	b7c9                	j	80002608 <procdump+0x5a>
  }
}
    80002648:	60a6                	ld	ra,72(sp)
    8000264a:	6406                	ld	s0,64(sp)
    8000264c:	74e2                	ld	s1,56(sp)
    8000264e:	7942                	ld	s2,48(sp)
    80002650:	79a2                	ld	s3,40(sp)
    80002652:	7a02                	ld	s4,32(sp)
    80002654:	6ae2                	ld	s5,24(sp)
    80002656:	6b42                	ld	s6,16(sp)
    80002658:	6ba2                	ld	s7,8(sp)
    8000265a:	6161                	addi	sp,sp,80
    8000265c:	8082                	ret

000000008000265e <swtch>:
    8000265e:	00153023          	sd	ra,0(a0)
    80002662:	00253423          	sd	sp,8(a0)
    80002666:	e900                	sd	s0,16(a0)
    80002668:	ed04                	sd	s1,24(a0)
    8000266a:	03253023          	sd	s2,32(a0)
    8000266e:	03353423          	sd	s3,40(a0)
    80002672:	03453823          	sd	s4,48(a0)
    80002676:	03553c23          	sd	s5,56(a0)
    8000267a:	05653023          	sd	s6,64(a0)
    8000267e:	05753423          	sd	s7,72(a0)
    80002682:	05853823          	sd	s8,80(a0)
    80002686:	05953c23          	sd	s9,88(a0)
    8000268a:	07a53023          	sd	s10,96(a0)
    8000268e:	07b53423          	sd	s11,104(a0)
    80002692:	0005b083          	ld	ra,0(a1)
    80002696:	0085b103          	ld	sp,8(a1)
    8000269a:	6980                	ld	s0,16(a1)
    8000269c:	6d84                	ld	s1,24(a1)
    8000269e:	0205b903          	ld	s2,32(a1)
    800026a2:	0285b983          	ld	s3,40(a1)
    800026a6:	0305ba03          	ld	s4,48(a1)
    800026aa:	0385ba83          	ld	s5,56(a1)
    800026ae:	0405bb03          	ld	s6,64(a1)
    800026b2:	0485bb83          	ld	s7,72(a1)
    800026b6:	0505bc03          	ld	s8,80(a1)
    800026ba:	0585bc83          	ld	s9,88(a1)
    800026be:	0605bd03          	ld	s10,96(a1)
    800026c2:	0685bd83          	ld	s11,104(a1)
    800026c6:	8082                	ret

00000000800026c8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026c8:	1141                	addi	sp,sp,-16
    800026ca:	e406                	sd	ra,8(sp)
    800026cc:	e022                	sd	s0,0(sp)
    800026ce:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026d0:	00006597          	auipc	a1,0x6
    800026d4:	c3058593          	addi	a1,a1,-976 # 80008300 <states.0+0x30>
    800026d8:	00014517          	auipc	a0,0x14
    800026dc:	5b850513          	addi	a0,a0,1464 # 80016c90 <tickslock>
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	4d8080e7          	jalr	1240(ra) # 80000bb8 <initlock>
}
    800026e8:	60a2                	ld	ra,8(sp)
    800026ea:	6402                	ld	s0,0(sp)
    800026ec:	0141                	addi	sp,sp,16
    800026ee:	8082                	ret

00000000800026f0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f0:	1141                	addi	sp,sp,-16
    800026f2:	e422                	sd	s0,8(sp)
    800026f4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f6:	00003797          	auipc	a5,0x3
    800026fa:	52a78793          	addi	a5,a5,1322 # 80005c20 <kernelvec>
    800026fe:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002702:	6422                	ld	s0,8(sp)
    80002704:	0141                	addi	sp,sp,16
    80002706:	8082                	ret

0000000080002708 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002708:	1141                	addi	sp,sp,-16
    8000270a:	e406                	sd	ra,8(sp)
    8000270c:	e022                	sd	s0,0(sp)
    8000270e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	314080e7          	jalr	788(ra) # 80001a24 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002718:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000271c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002722:	00005697          	auipc	a3,0x5
    80002726:	8de68693          	addi	a3,a3,-1826 # 80007000 <_trampoline>
    8000272a:	00005717          	auipc	a4,0x5
    8000272e:	8d670713          	addi	a4,a4,-1834 # 80007000 <_trampoline>
    80002732:	8f15                	sub	a4,a4,a3
    80002734:	040007b7          	lui	a5,0x4000
    80002738:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000273a:	07b2                	slli	a5,a5,0xc
    8000273c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000273e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002742:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002744:	18002673          	csrr	a2,satp
    80002748:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000274a:	6d30                	ld	a2,88(a0)
    8000274c:	6138                	ld	a4,64(a0)
    8000274e:	6585                	lui	a1,0x1
    80002750:	972e                	add	a4,a4,a1
    80002752:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002754:	6d38                	ld	a4,88(a0)
    80002756:	00000617          	auipc	a2,0x0
    8000275a:	13460613          	addi	a2,a2,308 # 8000288a <usertrap>
    8000275e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002760:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002762:	8612                	mv	a2,tp
    80002764:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002766:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000276a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000276e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002772:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002776:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002778:	6f18                	ld	a4,24(a4)
    8000277a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000277e:	6928                	ld	a0,80(a0)
    80002780:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002782:	00005717          	auipc	a4,0x5
    80002786:	91a70713          	addi	a4,a4,-1766 # 8000709c <userret>
    8000278a:	8f15                	sub	a4,a4,a3
    8000278c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000278e:	577d                	li	a4,-1
    80002790:	177e                	slli	a4,a4,0x3f
    80002792:	8d59                	or	a0,a0,a4
    80002794:	9782                	jalr	a5
}
    80002796:	60a2                	ld	ra,8(sp)
    80002798:	6402                	ld	s0,0(sp)
    8000279a:	0141                	addi	sp,sp,16
    8000279c:	8082                	ret

000000008000279e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000279e:	1101                	addi	sp,sp,-32
    800027a0:	ec06                	sd	ra,24(sp)
    800027a2:	e822                	sd	s0,16(sp)
    800027a4:	e426                	sd	s1,8(sp)
    800027a6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027a8:	00014497          	auipc	s1,0x14
    800027ac:	4e848493          	addi	s1,s1,1256 # 80016c90 <tickslock>
    800027b0:	8526                	mv	a0,s1
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	496080e7          	jalr	1174(ra) # 80000c48 <acquire>
  ticks++;
    800027ba:	00006517          	auipc	a0,0x6
    800027be:	23650513          	addi	a0,a0,566 # 800089f0 <ticks>
    800027c2:	411c                	lw	a5,0(a0)
    800027c4:	2785                	addiw	a5,a5,1
    800027c6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c8:	00000097          	auipc	ra,0x0
    800027cc:	996080e7          	jalr	-1642(ra) # 8000215e <wakeup>
  release(&tickslock);
    800027d0:	8526                	mv	a0,s1
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	52a080e7          	jalr	1322(ra) # 80000cfc <release>
}
    800027da:	60e2                	ld	ra,24(sp)
    800027dc:	6442                	ld	s0,16(sp)
    800027de:	64a2                	ld	s1,8(sp)
    800027e0:	6105                	addi	sp,sp,32
    800027e2:	8082                	ret

00000000800027e4 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e4:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027e8:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    800027ea:	0807df63          	bgez	a5,80002888 <devintr+0xa4>
{
    800027ee:	1101                	addi	sp,sp,-32
    800027f0:	ec06                	sd	ra,24(sp)
    800027f2:	e822                	sd	s0,16(sp)
    800027f4:	e426                	sd	s1,8(sp)
    800027f6:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    800027f8:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    800027fc:	46a5                	li	a3,9
    800027fe:	00d70d63          	beq	a4,a3,80002818 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002802:	577d                	li	a4,-1
    80002804:	177e                	slli	a4,a4,0x3f
    80002806:	0705                	addi	a4,a4,1
    return 0;
    80002808:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000280a:	04e78e63          	beq	a5,a4,80002866 <devintr+0x82>
  }
}
    8000280e:	60e2                	ld	ra,24(sp)
    80002810:	6442                	ld	s0,16(sp)
    80002812:	64a2                	ld	s1,8(sp)
    80002814:	6105                	addi	sp,sp,32
    80002816:	8082                	ret
    int irq = plic_claim();
    80002818:	00003097          	auipc	ra,0x3
    8000281c:	510080e7          	jalr	1296(ra) # 80005d28 <plic_claim>
    80002820:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002822:	47a9                	li	a5,10
    80002824:	02f50763          	beq	a0,a5,80002852 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002828:	4785                	li	a5,1
    8000282a:	02f50963          	beq	a0,a5,8000285c <devintr+0x78>
    return 1;
    8000282e:	4505                	li	a0,1
    } else if(irq){
    80002830:	dcf9                	beqz	s1,8000280e <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002832:	85a6                	mv	a1,s1
    80002834:	00006517          	auipc	a0,0x6
    80002838:	ad450513          	addi	a0,a0,-1324 # 80008308 <states.0+0x38>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	d4e080e7          	jalr	-690(ra) # 8000058a <printf>
      plic_complete(irq);
    80002844:	8526                	mv	a0,s1
    80002846:	00003097          	auipc	ra,0x3
    8000284a:	506080e7          	jalr	1286(ra) # 80005d4c <plic_complete>
    return 1;
    8000284e:	4505                	li	a0,1
    80002850:	bf7d                	j	8000280e <devintr+0x2a>
      uartintr();
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	1b8080e7          	jalr	440(ra) # 80000a0a <uartintr>
    if(irq)
    8000285a:	b7ed                	j	80002844 <devintr+0x60>
      virtio_disk_intr();
    8000285c:	00004097          	auipc	ra,0x4
    80002860:	b68080e7          	jalr	-1176(ra) # 800063c4 <virtio_disk_intr>
    if(irq)
    80002864:	b7c5                	j	80002844 <devintr+0x60>
    if(cpuid() == 0){
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	192080e7          	jalr	402(ra) # 800019f8 <cpuid>
    8000286e:	c901                	beqz	a0,8000287e <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002870:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002874:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002876:	14479073          	csrw	sip,a5
    return 2;
    8000287a:	4509                	li	a0,2
    8000287c:	bf49                	j	8000280e <devintr+0x2a>
      clockintr();
    8000287e:	00000097          	auipc	ra,0x0
    80002882:	f20080e7          	jalr	-224(ra) # 8000279e <clockintr>
    80002886:	b7ed                	j	80002870 <devintr+0x8c>
}
    80002888:	8082                	ret

000000008000288a <usertrap>:
{
    8000288a:	1101                	addi	sp,sp,-32
    8000288c:	ec06                	sd	ra,24(sp)
    8000288e:	e822                	sd	s0,16(sp)
    80002890:	e426                	sd	s1,8(sp)
    80002892:	e04a                	sd	s2,0(sp)
    80002894:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002896:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000289a:	1007f793          	andi	a5,a5,256
    8000289e:	ebad                	bnez	a5,80002910 <usertrap+0x86>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a0:	00003797          	auipc	a5,0x3
    800028a4:	38078793          	addi	a5,a5,896 # 80005c20 <kernelvec>
    800028a8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ac:	fffff097          	auipc	ra,0xfffff
    800028b0:	178080e7          	jalr	376(ra) # 80001a24 <myproc>
    800028b4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028b6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b8:	14102773          	csrr	a4,sepc
    800028bc:	ef98                	sd	a4,24(a5)
  if(strncmp(p->name, "vm-", 3) == 0 && (r_scause() == 2 || r_scause() == 1)){
    800028be:	15850913          	addi	s2,a0,344
    800028c2:	460d                	li	a2,3
    800028c4:	00006597          	auipc	a1,0x6
    800028c8:	93c58593          	addi	a1,a1,-1732 # 80008200 <digits+0x1c0>
    800028cc:	854a                	mv	a0,s2
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	546080e7          	jalr	1350(ra) # 80000e14 <strncmp>
    800028d6:	e919                	bnez	a0,800028ec <usertrap+0x62>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d8:	14202773          	csrr	a4,scause
    800028dc:	4789                	li	a5,2
    800028de:	04f70163          	beq	a4,a5,80002920 <usertrap+0x96>
    800028e2:	14202773          	csrr	a4,scause
    800028e6:	4785                	li	a5,1
    800028e8:	02f70c63          	beq	a4,a5,80002920 <usertrap+0x96>
    800028ec:	14202773          	csrr	a4,scause
  else if(r_scause() == 8){
    800028f0:	47a1                	li	a5,8
    800028f2:	04f70b63          	beq	a4,a5,80002948 <usertrap+0xbe>
  } else if((which_dev = devintr()) != 0){
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	eee080e7          	jalr	-274(ra) # 800027e4 <devintr>
    800028fe:	892a                	mv	s2,a0
    80002900:	cd59                	beqz	a0,8000299e <usertrap+0x114>
  if(killed(p))
    80002902:	8526                	mv	a0,s1
    80002904:	00000097          	auipc	ra,0x0
    80002908:	a9e080e7          	jalr	-1378(ra) # 800023a2 <killed>
    8000290c:	cd61                	beqz	a0,800029e4 <usertrap+0x15a>
    8000290e:	a0f1                	j	800029da <usertrap+0x150>
    panic("usertrap: not from user mode");
    80002910:	00006517          	auipc	a0,0x6
    80002914:	a1850513          	addi	a0,a0,-1512 # 80008328 <states.0+0x58>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	c28080e7          	jalr	-984(ra) # 80000540 <panic>
    trap_and_emulate();
    80002920:	00004097          	auipc	ra,0x4
    80002924:	306080e7          	jalr	774(ra) # 80006c26 <trap_and_emulate>
  if(killed(p))
    80002928:	8526                	mv	a0,s1
    8000292a:	00000097          	auipc	ra,0x0
    8000292e:	a78080e7          	jalr	-1416(ra) # 800023a2 <killed>
    80002932:	e15d                	bnez	a0,800029d8 <usertrap+0x14e>
  usertrapret();
    80002934:	00000097          	auipc	ra,0x0
    80002938:	dd4080e7          	jalr	-556(ra) # 80002708 <usertrapret>
}
    8000293c:	60e2                	ld	ra,24(sp)
    8000293e:	6442                	ld	s0,16(sp)
    80002940:	64a2                	ld	s1,8(sp)
    80002942:	6902                	ld	s2,0(sp)
    80002944:	6105                	addi	sp,sp,32
    80002946:	8082                	ret
    if(killed(p))
    80002948:	8526                	mv	a0,s1
    8000294a:	00000097          	auipc	ra,0x0
    8000294e:	a58080e7          	jalr	-1448(ra) # 800023a2 <killed>
    80002952:	e10d                	bnez	a0,80002974 <usertrap+0xea>
	if(strncmp(p->name, "vm-", 3) == 0){
    80002954:	460d                	li	a2,3
    80002956:	00006597          	auipc	a1,0x6
    8000295a:	8aa58593          	addi	a1,a1,-1878 # 80008200 <digits+0x1c0>
    8000295e:	854a                	mv	a0,s2
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	4b4080e7          	jalr	1204(ra) # 80000e14 <strncmp>
    80002968:	ed01                	bnez	a0,80002980 <usertrap+0xf6>
      trap_and_emulate();
    8000296a:	00004097          	auipc	ra,0x4
    8000296e:	2bc080e7          	jalr	700(ra) # 80006c26 <trap_and_emulate>
    80002972:	bf5d                	j	80002928 <usertrap+0x9e>
      exit(-1);
    80002974:	557d                	li	a0,-1
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	8b8080e7          	jalr	-1864(ra) # 8000222e <exit>
    8000297e:	bfd9                	j	80002954 <usertrap+0xca>
    	p->trapframe->epc += 4;
    80002980:	6cb8                	ld	a4,88(s1)
    80002982:	6f1c                	ld	a5,24(a4)
    80002984:	0791                	addi	a5,a5,4
    80002986:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002988:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000298c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002990:	10079073          	csrw	sstatus,a5
    	syscall();
    80002994:	00000097          	auipc	ra,0x0
    80002998:	2aa080e7          	jalr	682(ra) # 80002c3e <syscall>
    8000299c:	b771                	j	80002928 <usertrap+0x9e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000299e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029a2:	5890                	lw	a2,48(s1)
    800029a4:	00006517          	auipc	a0,0x6
    800029a8:	9a450513          	addi	a0,a0,-1628 # 80008348 <states.0+0x78>
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	bde080e7          	jalr	-1058(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029b8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029bc:	00006517          	auipc	a0,0x6
    800029c0:	9bc50513          	addi	a0,a0,-1604 # 80008378 <states.0+0xa8>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	bc6080e7          	jalr	-1082(ra) # 8000058a <printf>
    setkilled(p);
    800029cc:	8526                	mv	a0,s1
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	9a8080e7          	jalr	-1624(ra) # 80002376 <setkilled>
    800029d6:	bf89                	j	80002928 <usertrap+0x9e>
  if(killed(p))
    800029d8:	4901                	li	s2,0
    exit(-1);
    800029da:	557d                	li	a0,-1
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	852080e7          	jalr	-1966(ra) # 8000222e <exit>
  if(which_dev == 2)
    800029e4:	4789                	li	a5,2
    800029e6:	f4f917e3          	bne	s2,a5,80002934 <usertrap+0xaa>
    yield();
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	6d4080e7          	jalr	1748(ra) # 800020be <yield>
    800029f2:	b789                	j	80002934 <usertrap+0xaa>

00000000800029f4 <kerneltrap>:
{
    800029f4:	7179                	addi	sp,sp,-48
    800029f6:	f406                	sd	ra,40(sp)
    800029f8:	f022                	sd	s0,32(sp)
    800029fa:	ec26                	sd	s1,24(sp)
    800029fc:	e84a                	sd	s2,16(sp)
    800029fe:	e44e                	sd	s3,8(sp)
    80002a00:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a02:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a06:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a0e:	1004f793          	andi	a5,s1,256
    80002a12:	cb85                	beqz	a5,80002a42 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a14:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a18:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a1a:	ef85                	bnez	a5,80002a52 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a1c:	00000097          	auipc	ra,0x0
    80002a20:	dc8080e7          	jalr	-568(ra) # 800027e4 <devintr>
    80002a24:	cd1d                	beqz	a0,80002a62 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a26:	4789                	li	a5,2
    80002a28:	06f50a63          	beq	a0,a5,80002a9c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a2c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a30:	10049073          	csrw	sstatus,s1
}
    80002a34:	70a2                	ld	ra,40(sp)
    80002a36:	7402                	ld	s0,32(sp)
    80002a38:	64e2                	ld	s1,24(sp)
    80002a3a:	6942                	ld	s2,16(sp)
    80002a3c:	69a2                	ld	s3,8(sp)
    80002a3e:	6145                	addi	sp,sp,48
    80002a40:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a42:	00006517          	auipc	a0,0x6
    80002a46:	95650513          	addi	a0,a0,-1706 # 80008398 <states.0+0xc8>
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	af6080e7          	jalr	-1290(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	96e50513          	addi	a0,a0,-1682 # 800083c0 <states.0+0xf0>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	ae6080e7          	jalr	-1306(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002a62:	85ce                	mv	a1,s3
    80002a64:	00006517          	auipc	a0,0x6
    80002a68:	97c50513          	addi	a0,a0,-1668 # 800083e0 <states.0+0x110>
    80002a6c:	ffffe097          	auipc	ra,0xffffe
    80002a70:	b1e080e7          	jalr	-1250(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a74:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a78:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a7c:	00006517          	auipc	a0,0x6
    80002a80:	97450513          	addi	a0,a0,-1676 # 800083f0 <states.0+0x120>
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	b06080e7          	jalr	-1274(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a8c:	00006517          	auipc	a0,0x6
    80002a90:	97c50513          	addi	a0,a0,-1668 # 80008408 <states.0+0x138>
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	aac080e7          	jalr	-1364(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a9c:	fffff097          	auipc	ra,0xfffff
    80002aa0:	f88080e7          	jalr	-120(ra) # 80001a24 <myproc>
    80002aa4:	d541                	beqz	a0,80002a2c <kerneltrap+0x38>
    80002aa6:	fffff097          	auipc	ra,0xfffff
    80002aaa:	f7e080e7          	jalr	-130(ra) # 80001a24 <myproc>
    80002aae:	4d18                	lw	a4,24(a0)
    80002ab0:	4791                	li	a5,4
    80002ab2:	f6f71de3          	bne	a4,a5,80002a2c <kerneltrap+0x38>
    yield();
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	608080e7          	jalr	1544(ra) # 800020be <yield>
    80002abe:	b7bd                	j	80002a2c <kerneltrap+0x38>

0000000080002ac0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ac0:	1101                	addi	sp,sp,-32
    80002ac2:	ec06                	sd	ra,24(sp)
    80002ac4:	e822                	sd	s0,16(sp)
    80002ac6:	e426                	sd	s1,8(sp)
    80002ac8:	1000                	addi	s0,sp,32
    80002aca:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002acc:	fffff097          	auipc	ra,0xfffff
    80002ad0:	f58080e7          	jalr	-168(ra) # 80001a24 <myproc>
  switch (n) {
    80002ad4:	4795                	li	a5,5
    80002ad6:	0497e163          	bltu	a5,s1,80002b18 <argraw+0x58>
    80002ada:	048a                	slli	s1,s1,0x2
    80002adc:	00006717          	auipc	a4,0x6
    80002ae0:	96470713          	addi	a4,a4,-1692 # 80008440 <states.0+0x170>
    80002ae4:	94ba                	add	s1,s1,a4
    80002ae6:	409c                	lw	a5,0(s1)
    80002ae8:	97ba                	add	a5,a5,a4
    80002aea:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aec:	6d3c                	ld	a5,88(a0)
    80002aee:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002af0:	60e2                	ld	ra,24(sp)
    80002af2:	6442                	ld	s0,16(sp)
    80002af4:	64a2                	ld	s1,8(sp)
    80002af6:	6105                	addi	sp,sp,32
    80002af8:	8082                	ret
    return p->trapframe->a1;
    80002afa:	6d3c                	ld	a5,88(a0)
    80002afc:	7fa8                	ld	a0,120(a5)
    80002afe:	bfcd                	j	80002af0 <argraw+0x30>
    return p->trapframe->a2;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	63c8                	ld	a0,128(a5)
    80002b04:	b7f5                	j	80002af0 <argraw+0x30>
    return p->trapframe->a3;
    80002b06:	6d3c                	ld	a5,88(a0)
    80002b08:	67c8                	ld	a0,136(a5)
    80002b0a:	b7dd                	j	80002af0 <argraw+0x30>
    return p->trapframe->a4;
    80002b0c:	6d3c                	ld	a5,88(a0)
    80002b0e:	6bc8                	ld	a0,144(a5)
    80002b10:	b7c5                	j	80002af0 <argraw+0x30>
    return p->trapframe->a5;
    80002b12:	6d3c                	ld	a5,88(a0)
    80002b14:	6fc8                	ld	a0,152(a5)
    80002b16:	bfe9                	j	80002af0 <argraw+0x30>
  panic("argraw");
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	90050513          	addi	a0,a0,-1792 # 80008418 <states.0+0x148>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	a20080e7          	jalr	-1504(ra) # 80000540 <panic>

0000000080002b28 <fetchaddr>:
{
    80002b28:	1101                	addi	sp,sp,-32
    80002b2a:	ec06                	sd	ra,24(sp)
    80002b2c:	e822                	sd	s0,16(sp)
    80002b2e:	e426                	sd	s1,8(sp)
    80002b30:	e04a                	sd	s2,0(sp)
    80002b32:	1000                	addi	s0,sp,32
    80002b34:	84aa                	mv	s1,a0
    80002b36:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	eec080e7          	jalr	-276(ra) # 80001a24 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b40:	653c                	ld	a5,72(a0)
    80002b42:	02f4f863          	bgeu	s1,a5,80002b72 <fetchaddr+0x4a>
    80002b46:	00848713          	addi	a4,s1,8
    80002b4a:	02e7e663          	bltu	a5,a4,80002b76 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b4e:	46a1                	li	a3,8
    80002b50:	8626                	mv	a2,s1
    80002b52:	85ca                	mv	a1,s2
    80002b54:	6928                	ld	a0,80(a0)
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	c1a080e7          	jalr	-998(ra) # 80001770 <copyin>
    80002b5e:	00a03533          	snez	a0,a0
    80002b62:	40a00533          	neg	a0,a0
}
    80002b66:	60e2                	ld	ra,24(sp)
    80002b68:	6442                	ld	s0,16(sp)
    80002b6a:	64a2                	ld	s1,8(sp)
    80002b6c:	6902                	ld	s2,0(sp)
    80002b6e:	6105                	addi	sp,sp,32
    80002b70:	8082                	ret
    return -1;
    80002b72:	557d                	li	a0,-1
    80002b74:	bfcd                	j	80002b66 <fetchaddr+0x3e>
    80002b76:	557d                	li	a0,-1
    80002b78:	b7fd                	j	80002b66 <fetchaddr+0x3e>

0000000080002b7a <fetchstr>:
{
    80002b7a:	7179                	addi	sp,sp,-48
    80002b7c:	f406                	sd	ra,40(sp)
    80002b7e:	f022                	sd	s0,32(sp)
    80002b80:	ec26                	sd	s1,24(sp)
    80002b82:	e84a                	sd	s2,16(sp)
    80002b84:	e44e                	sd	s3,8(sp)
    80002b86:	1800                	addi	s0,sp,48
    80002b88:	892a                	mv	s2,a0
    80002b8a:	84ae                	mv	s1,a1
    80002b8c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	e96080e7          	jalr	-362(ra) # 80001a24 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b96:	86ce                	mv	a3,s3
    80002b98:	864a                	mv	a2,s2
    80002b9a:	85a6                	mv	a1,s1
    80002b9c:	6928                	ld	a0,80(a0)
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	c60080e7          	jalr	-928(ra) # 800017fe <copyinstr>
    80002ba6:	00054e63          	bltz	a0,80002bc2 <fetchstr+0x48>
  return strlen(buf);
    80002baa:	8526                	mv	a0,s1
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	312080e7          	jalr	786(ra) # 80000ebe <strlen>
}
    80002bb4:	70a2                	ld	ra,40(sp)
    80002bb6:	7402                	ld	s0,32(sp)
    80002bb8:	64e2                	ld	s1,24(sp)
    80002bba:	6942                	ld	s2,16(sp)
    80002bbc:	69a2                	ld	s3,8(sp)
    80002bbe:	6145                	addi	sp,sp,48
    80002bc0:	8082                	ret
    return -1;
    80002bc2:	557d                	li	a0,-1
    80002bc4:	bfc5                	j	80002bb4 <fetchstr+0x3a>

0000000080002bc6 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bc6:	1101                	addi	sp,sp,-32
    80002bc8:	ec06                	sd	ra,24(sp)
    80002bca:	e822                	sd	s0,16(sp)
    80002bcc:	e426                	sd	s1,8(sp)
    80002bce:	1000                	addi	s0,sp,32
    80002bd0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	eee080e7          	jalr	-274(ra) # 80002ac0 <argraw>
    80002bda:	c088                	sw	a0,0(s1)
}
    80002bdc:	60e2                	ld	ra,24(sp)
    80002bde:	6442                	ld	s0,16(sp)
    80002be0:	64a2                	ld	s1,8(sp)
    80002be2:	6105                	addi	sp,sp,32
    80002be4:	8082                	ret

0000000080002be6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002be6:	1101                	addi	sp,sp,-32
    80002be8:	ec06                	sd	ra,24(sp)
    80002bea:	e822                	sd	s0,16(sp)
    80002bec:	e426                	sd	s1,8(sp)
    80002bee:	1000                	addi	s0,sp,32
    80002bf0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bf2:	00000097          	auipc	ra,0x0
    80002bf6:	ece080e7          	jalr	-306(ra) # 80002ac0 <argraw>
    80002bfa:	e088                	sd	a0,0(s1)
}
    80002bfc:	60e2                	ld	ra,24(sp)
    80002bfe:	6442                	ld	s0,16(sp)
    80002c00:	64a2                	ld	s1,8(sp)
    80002c02:	6105                	addi	sp,sp,32
    80002c04:	8082                	ret

0000000080002c06 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c06:	7179                	addi	sp,sp,-48
    80002c08:	f406                	sd	ra,40(sp)
    80002c0a:	f022                	sd	s0,32(sp)
    80002c0c:	ec26                	sd	s1,24(sp)
    80002c0e:	e84a                	sd	s2,16(sp)
    80002c10:	1800                	addi	s0,sp,48
    80002c12:	84ae                	mv	s1,a1
    80002c14:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c16:	fd840593          	addi	a1,s0,-40
    80002c1a:	00000097          	auipc	ra,0x0
    80002c1e:	fcc080e7          	jalr	-52(ra) # 80002be6 <argaddr>
  return fetchstr(addr, buf, max);
    80002c22:	864a                	mv	a2,s2
    80002c24:	85a6                	mv	a1,s1
    80002c26:	fd843503          	ld	a0,-40(s0)
    80002c2a:	00000097          	auipc	ra,0x0
    80002c2e:	f50080e7          	jalr	-176(ra) # 80002b7a <fetchstr>
}
    80002c32:	70a2                	ld	ra,40(sp)
    80002c34:	7402                	ld	s0,32(sp)
    80002c36:	64e2                	ld	s1,24(sp)
    80002c38:	6942                	ld	s2,16(sp)
    80002c3a:	6145                	addi	sp,sp,48
    80002c3c:	8082                	ret

0000000080002c3e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c3e:	1101                	addi	sp,sp,-32
    80002c40:	ec06                	sd	ra,24(sp)
    80002c42:	e822                	sd	s0,16(sp)
    80002c44:	e426                	sd	s1,8(sp)
    80002c46:	e04a                	sd	s2,0(sp)
    80002c48:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c4a:	fffff097          	auipc	ra,0xfffff
    80002c4e:	dda080e7          	jalr	-550(ra) # 80001a24 <myproc>
    80002c52:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c54:	05853903          	ld	s2,88(a0)
    80002c58:	0a893783          	ld	a5,168(s2)
    80002c5c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c60:	37fd                	addiw	a5,a5,-1
    80002c62:	4751                	li	a4,20
    80002c64:	00f76f63          	bltu	a4,a5,80002c82 <syscall+0x44>
    80002c68:	00369713          	slli	a4,a3,0x3
    80002c6c:	00005797          	auipc	a5,0x5
    80002c70:	7ec78793          	addi	a5,a5,2028 # 80008458 <syscalls>
    80002c74:	97ba                	add	a5,a5,a4
    80002c76:	639c                	ld	a5,0(a5)
    80002c78:	c789                	beqz	a5,80002c82 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c7a:	9782                	jalr	a5
    80002c7c:	06a93823          	sd	a0,112(s2)
    80002c80:	a839                	j	80002c9e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c82:	15848613          	addi	a2,s1,344
    80002c86:	588c                	lw	a1,48(s1)
    80002c88:	00005517          	auipc	a0,0x5
    80002c8c:	79850513          	addi	a0,a0,1944 # 80008420 <states.0+0x150>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	8fa080e7          	jalr	-1798(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c98:	6cbc                	ld	a5,88(s1)
    80002c9a:	577d                	li	a4,-1
    80002c9c:	fbb8                	sd	a4,112(a5)
  }
}
    80002c9e:	60e2                	ld	ra,24(sp)
    80002ca0:	6442                	ld	s0,16(sp)
    80002ca2:	64a2                	ld	s1,8(sp)
    80002ca4:	6902                	ld	s2,0(sp)
    80002ca6:	6105                	addi	sp,sp,32
    80002ca8:	8082                	ret

0000000080002caa <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002caa:	1101                	addi	sp,sp,-32
    80002cac:	ec06                	sd	ra,24(sp)
    80002cae:	e822                	sd	s0,16(sp)
    80002cb0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cb2:	fec40593          	addi	a1,s0,-20
    80002cb6:	4501                	li	a0,0
    80002cb8:	00000097          	auipc	ra,0x0
    80002cbc:	f0e080e7          	jalr	-242(ra) # 80002bc6 <argint>
  exit(n);
    80002cc0:	fec42503          	lw	a0,-20(s0)
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	56a080e7          	jalr	1386(ra) # 8000222e <exit>
  return 0;  // not reached
}
    80002ccc:	4501                	li	a0,0
    80002cce:	60e2                	ld	ra,24(sp)
    80002cd0:	6442                	ld	s0,16(sp)
    80002cd2:	6105                	addi	sp,sp,32
    80002cd4:	8082                	ret

0000000080002cd6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cd6:	1141                	addi	sp,sp,-16
    80002cd8:	e406                	sd	ra,8(sp)
    80002cda:	e022                	sd	s0,0(sp)
    80002cdc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	d46080e7          	jalr	-698(ra) # 80001a24 <myproc>
}
    80002ce6:	5908                	lw	a0,48(a0)
    80002ce8:	60a2                	ld	ra,8(sp)
    80002cea:	6402                	ld	s0,0(sp)
    80002cec:	0141                	addi	sp,sp,16
    80002cee:	8082                	ret

0000000080002cf0 <sys_fork>:

uint64
sys_fork(void)
{
    80002cf0:	1141                	addi	sp,sp,-16
    80002cf2:	e406                	sd	ra,8(sp)
    80002cf4:	e022                	sd	s0,0(sp)
    80002cf6:	0800                	addi	s0,sp,16
  return fork();
    80002cf8:	fffff097          	auipc	ra,0xfffff
    80002cfc:	110080e7          	jalr	272(ra) # 80001e08 <fork>
}
    80002d00:	60a2                	ld	ra,8(sp)
    80002d02:	6402                	ld	s0,0(sp)
    80002d04:	0141                	addi	sp,sp,16
    80002d06:	8082                	ret

0000000080002d08 <sys_wait>:

uint64
sys_wait(void)
{
    80002d08:	1101                	addi	sp,sp,-32
    80002d0a:	ec06                	sd	ra,24(sp)
    80002d0c:	e822                	sd	s0,16(sp)
    80002d0e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d10:	fe840593          	addi	a1,s0,-24
    80002d14:	4501                	li	a0,0
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	ed0080e7          	jalr	-304(ra) # 80002be6 <argaddr>
  return wait(p);
    80002d1e:	fe843503          	ld	a0,-24(s0)
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	6b2080e7          	jalr	1714(ra) # 800023d4 <wait>
}
    80002d2a:	60e2                	ld	ra,24(sp)
    80002d2c:	6442                	ld	s0,16(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret

0000000080002d32 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d32:	7179                	addi	sp,sp,-48
    80002d34:	f406                	sd	ra,40(sp)
    80002d36:	f022                	sd	s0,32(sp)
    80002d38:	ec26                	sd	s1,24(sp)
    80002d3a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d3c:	fdc40593          	addi	a1,s0,-36
    80002d40:	4501                	li	a0,0
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	e84080e7          	jalr	-380(ra) # 80002bc6 <argint>
  addr = myproc()->sz;
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	cda080e7          	jalr	-806(ra) # 80001a24 <myproc>
    80002d52:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d54:	fdc42503          	lw	a0,-36(s0)
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	054080e7          	jalr	84(ra) # 80001dac <growproc>
    80002d60:	00054863          	bltz	a0,80002d70 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d64:	8526                	mv	a0,s1
    80002d66:	70a2                	ld	ra,40(sp)
    80002d68:	7402                	ld	s0,32(sp)
    80002d6a:	64e2                	ld	s1,24(sp)
    80002d6c:	6145                	addi	sp,sp,48
    80002d6e:	8082                	ret
    return -1;
    80002d70:	54fd                	li	s1,-1
    80002d72:	bfcd                	j	80002d64 <sys_sbrk+0x32>

0000000080002d74 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d74:	7139                	addi	sp,sp,-64
    80002d76:	fc06                	sd	ra,56(sp)
    80002d78:	f822                	sd	s0,48(sp)
    80002d7a:	f426                	sd	s1,40(sp)
    80002d7c:	f04a                	sd	s2,32(sp)
    80002d7e:	ec4e                	sd	s3,24(sp)
    80002d80:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d82:	fcc40593          	addi	a1,s0,-52
    80002d86:	4501                	li	a0,0
    80002d88:	00000097          	auipc	ra,0x0
    80002d8c:	e3e080e7          	jalr	-450(ra) # 80002bc6 <argint>
  acquire(&tickslock);
    80002d90:	00014517          	auipc	a0,0x14
    80002d94:	f0050513          	addi	a0,a0,-256 # 80016c90 <tickslock>
    80002d98:	ffffe097          	auipc	ra,0xffffe
    80002d9c:	eb0080e7          	jalr	-336(ra) # 80000c48 <acquire>
  ticks0 = ticks;
    80002da0:	00006917          	auipc	s2,0x6
    80002da4:	c5092903          	lw	s2,-944(s2) # 800089f0 <ticks>
  while(ticks - ticks0 < n){
    80002da8:	fcc42783          	lw	a5,-52(s0)
    80002dac:	cf9d                	beqz	a5,80002dea <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dae:	00014997          	auipc	s3,0x14
    80002db2:	ee298993          	addi	s3,s3,-286 # 80016c90 <tickslock>
    80002db6:	00006497          	auipc	s1,0x6
    80002dba:	c3a48493          	addi	s1,s1,-966 # 800089f0 <ticks>
    if(killed(myproc())){
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	c66080e7          	jalr	-922(ra) # 80001a24 <myproc>
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	5dc080e7          	jalr	1500(ra) # 800023a2 <killed>
    80002dce:	ed15                	bnez	a0,80002e0a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002dd0:	85ce                	mv	a1,s3
    80002dd2:	8526                	mv	a0,s1
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	326080e7          	jalr	806(ra) # 800020fa <sleep>
  while(ticks - ticks0 < n){
    80002ddc:	409c                	lw	a5,0(s1)
    80002dde:	412787bb          	subw	a5,a5,s2
    80002de2:	fcc42703          	lw	a4,-52(s0)
    80002de6:	fce7ece3          	bltu	a5,a4,80002dbe <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002dea:	00014517          	auipc	a0,0x14
    80002dee:	ea650513          	addi	a0,a0,-346 # 80016c90 <tickslock>
    80002df2:	ffffe097          	auipc	ra,0xffffe
    80002df6:	f0a080e7          	jalr	-246(ra) # 80000cfc <release>
  return 0;
    80002dfa:	4501                	li	a0,0
}
    80002dfc:	70e2                	ld	ra,56(sp)
    80002dfe:	7442                	ld	s0,48(sp)
    80002e00:	74a2                	ld	s1,40(sp)
    80002e02:	7902                	ld	s2,32(sp)
    80002e04:	69e2                	ld	s3,24(sp)
    80002e06:	6121                	addi	sp,sp,64
    80002e08:	8082                	ret
      release(&tickslock);
    80002e0a:	00014517          	auipc	a0,0x14
    80002e0e:	e8650513          	addi	a0,a0,-378 # 80016c90 <tickslock>
    80002e12:	ffffe097          	auipc	ra,0xffffe
    80002e16:	eea080e7          	jalr	-278(ra) # 80000cfc <release>
      return -1;
    80002e1a:	557d                	li	a0,-1
    80002e1c:	b7c5                	j	80002dfc <sys_sleep+0x88>

0000000080002e1e <sys_kill>:

uint64
sys_kill(void)
{
    80002e1e:	1101                	addi	sp,sp,-32
    80002e20:	ec06                	sd	ra,24(sp)
    80002e22:	e822                	sd	s0,16(sp)
    80002e24:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e26:	fec40593          	addi	a1,s0,-20
    80002e2a:	4501                	li	a0,0
    80002e2c:	00000097          	auipc	ra,0x0
    80002e30:	d9a080e7          	jalr	-614(ra) # 80002bc6 <argint>
  return kill(pid);
    80002e34:	fec42503          	lw	a0,-20(s0)
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	4cc080e7          	jalr	1228(ra) # 80002304 <kill>
}
    80002e40:	60e2                	ld	ra,24(sp)
    80002e42:	6442                	ld	s0,16(sp)
    80002e44:	6105                	addi	sp,sp,32
    80002e46:	8082                	ret

0000000080002e48 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e48:	1101                	addi	sp,sp,-32
    80002e4a:	ec06                	sd	ra,24(sp)
    80002e4c:	e822                	sd	s0,16(sp)
    80002e4e:	e426                	sd	s1,8(sp)
    80002e50:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e52:	00014517          	auipc	a0,0x14
    80002e56:	e3e50513          	addi	a0,a0,-450 # 80016c90 <tickslock>
    80002e5a:	ffffe097          	auipc	ra,0xffffe
    80002e5e:	dee080e7          	jalr	-530(ra) # 80000c48 <acquire>
  xticks = ticks;
    80002e62:	00006497          	auipc	s1,0x6
    80002e66:	b8e4a483          	lw	s1,-1138(s1) # 800089f0 <ticks>
  release(&tickslock);
    80002e6a:	00014517          	auipc	a0,0x14
    80002e6e:	e2650513          	addi	a0,a0,-474 # 80016c90 <tickslock>
    80002e72:	ffffe097          	auipc	ra,0xffffe
    80002e76:	e8a080e7          	jalr	-374(ra) # 80000cfc <release>
  return xticks;
}
    80002e7a:	02049513          	slli	a0,s1,0x20
    80002e7e:	9101                	srli	a0,a0,0x20
    80002e80:	60e2                	ld	ra,24(sp)
    80002e82:	6442                	ld	s0,16(sp)
    80002e84:	64a2                	ld	s1,8(sp)
    80002e86:	6105                	addi	sp,sp,32
    80002e88:	8082                	ret

0000000080002e8a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e8a:	7179                	addi	sp,sp,-48
    80002e8c:	f406                	sd	ra,40(sp)
    80002e8e:	f022                	sd	s0,32(sp)
    80002e90:	ec26                	sd	s1,24(sp)
    80002e92:	e84a                	sd	s2,16(sp)
    80002e94:	e44e                	sd	s3,8(sp)
    80002e96:	e052                	sd	s4,0(sp)
    80002e98:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e9a:	00005597          	auipc	a1,0x5
    80002e9e:	66e58593          	addi	a1,a1,1646 # 80008508 <syscalls+0xb0>
    80002ea2:	00014517          	auipc	a0,0x14
    80002ea6:	e0650513          	addi	a0,a0,-506 # 80016ca8 <bcache>
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	d0e080e7          	jalr	-754(ra) # 80000bb8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eb2:	0001c797          	auipc	a5,0x1c
    80002eb6:	df678793          	addi	a5,a5,-522 # 8001eca8 <bcache+0x8000>
    80002eba:	0001c717          	auipc	a4,0x1c
    80002ebe:	05670713          	addi	a4,a4,86 # 8001ef10 <bcache+0x8268>
    80002ec2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ec6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eca:	00014497          	auipc	s1,0x14
    80002ece:	df648493          	addi	s1,s1,-522 # 80016cc0 <bcache+0x18>
    b->next = bcache.head.next;
    80002ed2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ed4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ed6:	00005a17          	auipc	s4,0x5
    80002eda:	63aa0a13          	addi	s4,s4,1594 # 80008510 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002ede:	2b893783          	ld	a5,696(s2)
    80002ee2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ee4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ee8:	85d2                	mv	a1,s4
    80002eea:	01048513          	addi	a0,s1,16
    80002eee:	00001097          	auipc	ra,0x1
    80002ef2:	496080e7          	jalr	1174(ra) # 80004384 <initsleeplock>
    bcache.head.next->prev = b;
    80002ef6:	2b893783          	ld	a5,696(s2)
    80002efa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002efc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f00:	45848493          	addi	s1,s1,1112
    80002f04:	fd349de3          	bne	s1,s3,80002ede <binit+0x54>
  }
}
    80002f08:	70a2                	ld	ra,40(sp)
    80002f0a:	7402                	ld	s0,32(sp)
    80002f0c:	64e2                	ld	s1,24(sp)
    80002f0e:	6942                	ld	s2,16(sp)
    80002f10:	69a2                	ld	s3,8(sp)
    80002f12:	6a02                	ld	s4,0(sp)
    80002f14:	6145                	addi	sp,sp,48
    80002f16:	8082                	ret

0000000080002f18 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f18:	7179                	addi	sp,sp,-48
    80002f1a:	f406                	sd	ra,40(sp)
    80002f1c:	f022                	sd	s0,32(sp)
    80002f1e:	ec26                	sd	s1,24(sp)
    80002f20:	e84a                	sd	s2,16(sp)
    80002f22:	e44e                	sd	s3,8(sp)
    80002f24:	1800                	addi	s0,sp,48
    80002f26:	892a                	mv	s2,a0
    80002f28:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f2a:	00014517          	auipc	a0,0x14
    80002f2e:	d7e50513          	addi	a0,a0,-642 # 80016ca8 <bcache>
    80002f32:	ffffe097          	auipc	ra,0xffffe
    80002f36:	d16080e7          	jalr	-746(ra) # 80000c48 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f3a:	0001c497          	auipc	s1,0x1c
    80002f3e:	0264b483          	ld	s1,38(s1) # 8001ef60 <bcache+0x82b8>
    80002f42:	0001c797          	auipc	a5,0x1c
    80002f46:	fce78793          	addi	a5,a5,-50 # 8001ef10 <bcache+0x8268>
    80002f4a:	02f48f63          	beq	s1,a5,80002f88 <bread+0x70>
    80002f4e:	873e                	mv	a4,a5
    80002f50:	a021                	j	80002f58 <bread+0x40>
    80002f52:	68a4                	ld	s1,80(s1)
    80002f54:	02e48a63          	beq	s1,a4,80002f88 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f58:	449c                	lw	a5,8(s1)
    80002f5a:	ff279ce3          	bne	a5,s2,80002f52 <bread+0x3a>
    80002f5e:	44dc                	lw	a5,12(s1)
    80002f60:	ff3799e3          	bne	a5,s3,80002f52 <bread+0x3a>
      b->refcnt++;
    80002f64:	40bc                	lw	a5,64(s1)
    80002f66:	2785                	addiw	a5,a5,1
    80002f68:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f6a:	00014517          	auipc	a0,0x14
    80002f6e:	d3e50513          	addi	a0,a0,-706 # 80016ca8 <bcache>
    80002f72:	ffffe097          	auipc	ra,0xffffe
    80002f76:	d8a080e7          	jalr	-630(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002f7a:	01048513          	addi	a0,s1,16
    80002f7e:	00001097          	auipc	ra,0x1
    80002f82:	440080e7          	jalr	1088(ra) # 800043be <acquiresleep>
      return b;
    80002f86:	a8b9                	j	80002fe4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f88:	0001c497          	auipc	s1,0x1c
    80002f8c:	fd04b483          	ld	s1,-48(s1) # 8001ef58 <bcache+0x82b0>
    80002f90:	0001c797          	auipc	a5,0x1c
    80002f94:	f8078793          	addi	a5,a5,-128 # 8001ef10 <bcache+0x8268>
    80002f98:	00f48863          	beq	s1,a5,80002fa8 <bread+0x90>
    80002f9c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f9e:	40bc                	lw	a5,64(s1)
    80002fa0:	cf81                	beqz	a5,80002fb8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fa2:	64a4                	ld	s1,72(s1)
    80002fa4:	fee49de3          	bne	s1,a4,80002f9e <bread+0x86>
  panic("bget: no buffers");
    80002fa8:	00005517          	auipc	a0,0x5
    80002fac:	57050513          	addi	a0,a0,1392 # 80008518 <syscalls+0xc0>
    80002fb0:	ffffd097          	auipc	ra,0xffffd
    80002fb4:	590080e7          	jalr	1424(ra) # 80000540 <panic>
      b->dev = dev;
    80002fb8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fbc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fc0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fc4:	4785                	li	a5,1
    80002fc6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fc8:	00014517          	auipc	a0,0x14
    80002fcc:	ce050513          	addi	a0,a0,-800 # 80016ca8 <bcache>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	d2c080e7          	jalr	-724(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002fd8:	01048513          	addi	a0,s1,16
    80002fdc:	00001097          	auipc	ra,0x1
    80002fe0:	3e2080e7          	jalr	994(ra) # 800043be <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fe4:	409c                	lw	a5,0(s1)
    80002fe6:	cb89                	beqz	a5,80002ff8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fe8:	8526                	mv	a0,s1
    80002fea:	70a2                	ld	ra,40(sp)
    80002fec:	7402                	ld	s0,32(sp)
    80002fee:	64e2                	ld	s1,24(sp)
    80002ff0:	6942                	ld	s2,16(sp)
    80002ff2:	69a2                	ld	s3,8(sp)
    80002ff4:	6145                	addi	sp,sp,48
    80002ff6:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ff8:	4581                	li	a1,0
    80002ffa:	8526                	mv	a0,s1
    80002ffc:	00003097          	auipc	ra,0x3
    80003000:	198080e7          	jalr	408(ra) # 80006194 <virtio_disk_rw>
    b->valid = 1;
    80003004:	4785                	li	a5,1
    80003006:	c09c                	sw	a5,0(s1)
  return b;
    80003008:	b7c5                	j	80002fe8 <bread+0xd0>

000000008000300a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000300a:	1101                	addi	sp,sp,-32
    8000300c:	ec06                	sd	ra,24(sp)
    8000300e:	e822                	sd	s0,16(sp)
    80003010:	e426                	sd	s1,8(sp)
    80003012:	1000                	addi	s0,sp,32
    80003014:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003016:	0541                	addi	a0,a0,16
    80003018:	00001097          	auipc	ra,0x1
    8000301c:	440080e7          	jalr	1088(ra) # 80004458 <holdingsleep>
    80003020:	cd01                	beqz	a0,80003038 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003022:	4585                	li	a1,1
    80003024:	8526                	mv	a0,s1
    80003026:	00003097          	auipc	ra,0x3
    8000302a:	16e080e7          	jalr	366(ra) # 80006194 <virtio_disk_rw>
}
    8000302e:	60e2                	ld	ra,24(sp)
    80003030:	6442                	ld	s0,16(sp)
    80003032:	64a2                	ld	s1,8(sp)
    80003034:	6105                	addi	sp,sp,32
    80003036:	8082                	ret
    panic("bwrite");
    80003038:	00005517          	auipc	a0,0x5
    8000303c:	4f850513          	addi	a0,a0,1272 # 80008530 <syscalls+0xd8>
    80003040:	ffffd097          	auipc	ra,0xffffd
    80003044:	500080e7          	jalr	1280(ra) # 80000540 <panic>

0000000080003048 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003048:	1101                	addi	sp,sp,-32
    8000304a:	ec06                	sd	ra,24(sp)
    8000304c:	e822                	sd	s0,16(sp)
    8000304e:	e426                	sd	s1,8(sp)
    80003050:	e04a                	sd	s2,0(sp)
    80003052:	1000                	addi	s0,sp,32
    80003054:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003056:	01050913          	addi	s2,a0,16
    8000305a:	854a                	mv	a0,s2
    8000305c:	00001097          	auipc	ra,0x1
    80003060:	3fc080e7          	jalr	1020(ra) # 80004458 <holdingsleep>
    80003064:	c925                	beqz	a0,800030d4 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003066:	854a                	mv	a0,s2
    80003068:	00001097          	auipc	ra,0x1
    8000306c:	3ac080e7          	jalr	940(ra) # 80004414 <releasesleep>

  acquire(&bcache.lock);
    80003070:	00014517          	auipc	a0,0x14
    80003074:	c3850513          	addi	a0,a0,-968 # 80016ca8 <bcache>
    80003078:	ffffe097          	auipc	ra,0xffffe
    8000307c:	bd0080e7          	jalr	-1072(ra) # 80000c48 <acquire>
  b->refcnt--;
    80003080:	40bc                	lw	a5,64(s1)
    80003082:	37fd                	addiw	a5,a5,-1
    80003084:	0007871b          	sext.w	a4,a5
    80003088:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000308a:	e71d                	bnez	a4,800030b8 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000308c:	68b8                	ld	a4,80(s1)
    8000308e:	64bc                	ld	a5,72(s1)
    80003090:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003092:	68b8                	ld	a4,80(s1)
    80003094:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003096:	0001c797          	auipc	a5,0x1c
    8000309a:	c1278793          	addi	a5,a5,-1006 # 8001eca8 <bcache+0x8000>
    8000309e:	2b87b703          	ld	a4,696(a5)
    800030a2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030a4:	0001c717          	auipc	a4,0x1c
    800030a8:	e6c70713          	addi	a4,a4,-404 # 8001ef10 <bcache+0x8268>
    800030ac:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030ae:	2b87b703          	ld	a4,696(a5)
    800030b2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030b4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030b8:	00014517          	auipc	a0,0x14
    800030bc:	bf050513          	addi	a0,a0,-1040 # 80016ca8 <bcache>
    800030c0:	ffffe097          	auipc	ra,0xffffe
    800030c4:	c3c080e7          	jalr	-964(ra) # 80000cfc <release>
}
    800030c8:	60e2                	ld	ra,24(sp)
    800030ca:	6442                	ld	s0,16(sp)
    800030cc:	64a2                	ld	s1,8(sp)
    800030ce:	6902                	ld	s2,0(sp)
    800030d0:	6105                	addi	sp,sp,32
    800030d2:	8082                	ret
    panic("brelse");
    800030d4:	00005517          	auipc	a0,0x5
    800030d8:	46450513          	addi	a0,a0,1124 # 80008538 <syscalls+0xe0>
    800030dc:	ffffd097          	auipc	ra,0xffffd
    800030e0:	464080e7          	jalr	1124(ra) # 80000540 <panic>

00000000800030e4 <bpin>:

void
bpin(struct buf *b) {
    800030e4:	1101                	addi	sp,sp,-32
    800030e6:	ec06                	sd	ra,24(sp)
    800030e8:	e822                	sd	s0,16(sp)
    800030ea:	e426                	sd	s1,8(sp)
    800030ec:	1000                	addi	s0,sp,32
    800030ee:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030f0:	00014517          	auipc	a0,0x14
    800030f4:	bb850513          	addi	a0,a0,-1096 # 80016ca8 <bcache>
    800030f8:	ffffe097          	auipc	ra,0xffffe
    800030fc:	b50080e7          	jalr	-1200(ra) # 80000c48 <acquire>
  b->refcnt++;
    80003100:	40bc                	lw	a5,64(s1)
    80003102:	2785                	addiw	a5,a5,1
    80003104:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003106:	00014517          	auipc	a0,0x14
    8000310a:	ba250513          	addi	a0,a0,-1118 # 80016ca8 <bcache>
    8000310e:	ffffe097          	auipc	ra,0xffffe
    80003112:	bee080e7          	jalr	-1042(ra) # 80000cfc <release>
}
    80003116:	60e2                	ld	ra,24(sp)
    80003118:	6442                	ld	s0,16(sp)
    8000311a:	64a2                	ld	s1,8(sp)
    8000311c:	6105                	addi	sp,sp,32
    8000311e:	8082                	ret

0000000080003120 <bunpin>:

void
bunpin(struct buf *b) {
    80003120:	1101                	addi	sp,sp,-32
    80003122:	ec06                	sd	ra,24(sp)
    80003124:	e822                	sd	s0,16(sp)
    80003126:	e426                	sd	s1,8(sp)
    80003128:	1000                	addi	s0,sp,32
    8000312a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000312c:	00014517          	auipc	a0,0x14
    80003130:	b7c50513          	addi	a0,a0,-1156 # 80016ca8 <bcache>
    80003134:	ffffe097          	auipc	ra,0xffffe
    80003138:	b14080e7          	jalr	-1260(ra) # 80000c48 <acquire>
  b->refcnt--;
    8000313c:	40bc                	lw	a5,64(s1)
    8000313e:	37fd                	addiw	a5,a5,-1
    80003140:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003142:	00014517          	auipc	a0,0x14
    80003146:	b6650513          	addi	a0,a0,-1178 # 80016ca8 <bcache>
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	bb2080e7          	jalr	-1102(ra) # 80000cfc <release>
}
    80003152:	60e2                	ld	ra,24(sp)
    80003154:	6442                	ld	s0,16(sp)
    80003156:	64a2                	ld	s1,8(sp)
    80003158:	6105                	addi	sp,sp,32
    8000315a:	8082                	ret

000000008000315c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000315c:	1101                	addi	sp,sp,-32
    8000315e:	ec06                	sd	ra,24(sp)
    80003160:	e822                	sd	s0,16(sp)
    80003162:	e426                	sd	s1,8(sp)
    80003164:	e04a                	sd	s2,0(sp)
    80003166:	1000                	addi	s0,sp,32
    80003168:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000316a:	00d5d59b          	srliw	a1,a1,0xd
    8000316e:	0001c797          	auipc	a5,0x1c
    80003172:	2167a783          	lw	a5,534(a5) # 8001f384 <sb+0x1c>
    80003176:	9dbd                	addw	a1,a1,a5
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	da0080e7          	jalr	-608(ra) # 80002f18 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003180:	0074f713          	andi	a4,s1,7
    80003184:	4785                	li	a5,1
    80003186:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000318a:	14ce                	slli	s1,s1,0x33
    8000318c:	90d9                	srli	s1,s1,0x36
    8000318e:	00950733          	add	a4,a0,s1
    80003192:	05874703          	lbu	a4,88(a4)
    80003196:	00e7f6b3          	and	a3,a5,a4
    8000319a:	c69d                	beqz	a3,800031c8 <bfree+0x6c>
    8000319c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000319e:	94aa                	add	s1,s1,a0
    800031a0:	fff7c793          	not	a5,a5
    800031a4:	8f7d                	and	a4,a4,a5
    800031a6:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031aa:	00001097          	auipc	ra,0x1
    800031ae:	0f6080e7          	jalr	246(ra) # 800042a0 <log_write>
  brelse(bp);
    800031b2:	854a                	mv	a0,s2
    800031b4:	00000097          	auipc	ra,0x0
    800031b8:	e94080e7          	jalr	-364(ra) # 80003048 <brelse>
}
    800031bc:	60e2                	ld	ra,24(sp)
    800031be:	6442                	ld	s0,16(sp)
    800031c0:	64a2                	ld	s1,8(sp)
    800031c2:	6902                	ld	s2,0(sp)
    800031c4:	6105                	addi	sp,sp,32
    800031c6:	8082                	ret
    panic("freeing free block");
    800031c8:	00005517          	auipc	a0,0x5
    800031cc:	37850513          	addi	a0,a0,888 # 80008540 <syscalls+0xe8>
    800031d0:	ffffd097          	auipc	ra,0xffffd
    800031d4:	370080e7          	jalr	880(ra) # 80000540 <panic>

00000000800031d8 <balloc>:
{
    800031d8:	711d                	addi	sp,sp,-96
    800031da:	ec86                	sd	ra,88(sp)
    800031dc:	e8a2                	sd	s0,80(sp)
    800031de:	e4a6                	sd	s1,72(sp)
    800031e0:	e0ca                	sd	s2,64(sp)
    800031e2:	fc4e                	sd	s3,56(sp)
    800031e4:	f852                	sd	s4,48(sp)
    800031e6:	f456                	sd	s5,40(sp)
    800031e8:	f05a                	sd	s6,32(sp)
    800031ea:	ec5e                	sd	s7,24(sp)
    800031ec:	e862                	sd	s8,16(sp)
    800031ee:	e466                	sd	s9,8(sp)
    800031f0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031f2:	0001c797          	auipc	a5,0x1c
    800031f6:	17a7a783          	lw	a5,378(a5) # 8001f36c <sb+0x4>
    800031fa:	cff5                	beqz	a5,800032f6 <balloc+0x11e>
    800031fc:	8baa                	mv	s7,a0
    800031fe:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003200:	0001cb17          	auipc	s6,0x1c
    80003204:	168b0b13          	addi	s6,s6,360 # 8001f368 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003208:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000320a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000320c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000320e:	6c89                	lui	s9,0x2
    80003210:	a061                	j	80003298 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003212:	97ca                	add	a5,a5,s2
    80003214:	8e55                	or	a2,a2,a3
    80003216:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000321a:	854a                	mv	a0,s2
    8000321c:	00001097          	auipc	ra,0x1
    80003220:	084080e7          	jalr	132(ra) # 800042a0 <log_write>
        brelse(bp);
    80003224:	854a                	mv	a0,s2
    80003226:	00000097          	auipc	ra,0x0
    8000322a:	e22080e7          	jalr	-478(ra) # 80003048 <brelse>
  bp = bread(dev, bno);
    8000322e:	85a6                	mv	a1,s1
    80003230:	855e                	mv	a0,s7
    80003232:	00000097          	auipc	ra,0x0
    80003236:	ce6080e7          	jalr	-794(ra) # 80002f18 <bread>
    8000323a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000323c:	40000613          	li	a2,1024
    80003240:	4581                	li	a1,0
    80003242:	05850513          	addi	a0,a0,88
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	afe080e7          	jalr	-1282(ra) # 80000d44 <memset>
  log_write(bp);
    8000324e:	854a                	mv	a0,s2
    80003250:	00001097          	auipc	ra,0x1
    80003254:	050080e7          	jalr	80(ra) # 800042a0 <log_write>
  brelse(bp);
    80003258:	854a                	mv	a0,s2
    8000325a:	00000097          	auipc	ra,0x0
    8000325e:	dee080e7          	jalr	-530(ra) # 80003048 <brelse>
}
    80003262:	8526                	mv	a0,s1
    80003264:	60e6                	ld	ra,88(sp)
    80003266:	6446                	ld	s0,80(sp)
    80003268:	64a6                	ld	s1,72(sp)
    8000326a:	6906                	ld	s2,64(sp)
    8000326c:	79e2                	ld	s3,56(sp)
    8000326e:	7a42                	ld	s4,48(sp)
    80003270:	7aa2                	ld	s5,40(sp)
    80003272:	7b02                	ld	s6,32(sp)
    80003274:	6be2                	ld	s7,24(sp)
    80003276:	6c42                	ld	s8,16(sp)
    80003278:	6ca2                	ld	s9,8(sp)
    8000327a:	6125                	addi	sp,sp,96
    8000327c:	8082                	ret
    brelse(bp);
    8000327e:	854a                	mv	a0,s2
    80003280:	00000097          	auipc	ra,0x0
    80003284:	dc8080e7          	jalr	-568(ra) # 80003048 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003288:	015c87bb          	addw	a5,s9,s5
    8000328c:	00078a9b          	sext.w	s5,a5
    80003290:	004b2703          	lw	a4,4(s6)
    80003294:	06eaf163          	bgeu	s5,a4,800032f6 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003298:	41fad79b          	sraiw	a5,s5,0x1f
    8000329c:	0137d79b          	srliw	a5,a5,0x13
    800032a0:	015787bb          	addw	a5,a5,s5
    800032a4:	40d7d79b          	sraiw	a5,a5,0xd
    800032a8:	01cb2583          	lw	a1,28(s6)
    800032ac:	9dbd                	addw	a1,a1,a5
    800032ae:	855e                	mv	a0,s7
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	c68080e7          	jalr	-920(ra) # 80002f18 <bread>
    800032b8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ba:	004b2503          	lw	a0,4(s6)
    800032be:	000a849b          	sext.w	s1,s5
    800032c2:	8762                	mv	a4,s8
    800032c4:	faa4fde3          	bgeu	s1,a0,8000327e <balloc+0xa6>
      m = 1 << (bi % 8);
    800032c8:	00777693          	andi	a3,a4,7
    800032cc:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032d0:	41f7579b          	sraiw	a5,a4,0x1f
    800032d4:	01d7d79b          	srliw	a5,a5,0x1d
    800032d8:	9fb9                	addw	a5,a5,a4
    800032da:	4037d79b          	sraiw	a5,a5,0x3
    800032de:	00f90633          	add	a2,s2,a5
    800032e2:	05864603          	lbu	a2,88(a2)
    800032e6:	00c6f5b3          	and	a1,a3,a2
    800032ea:	d585                	beqz	a1,80003212 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ec:	2705                	addiw	a4,a4,1
    800032ee:	2485                	addiw	s1,s1,1
    800032f0:	fd471ae3          	bne	a4,s4,800032c4 <balloc+0xec>
    800032f4:	b769                	j	8000327e <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800032f6:	00005517          	auipc	a0,0x5
    800032fa:	26250513          	addi	a0,a0,610 # 80008558 <syscalls+0x100>
    800032fe:	ffffd097          	auipc	ra,0xffffd
    80003302:	28c080e7          	jalr	652(ra) # 8000058a <printf>
  return 0;
    80003306:	4481                	li	s1,0
    80003308:	bfa9                	j	80003262 <balloc+0x8a>

000000008000330a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000330a:	7179                	addi	sp,sp,-48
    8000330c:	f406                	sd	ra,40(sp)
    8000330e:	f022                	sd	s0,32(sp)
    80003310:	ec26                	sd	s1,24(sp)
    80003312:	e84a                	sd	s2,16(sp)
    80003314:	e44e                	sd	s3,8(sp)
    80003316:	e052                	sd	s4,0(sp)
    80003318:	1800                	addi	s0,sp,48
    8000331a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000331c:	47ad                	li	a5,11
    8000331e:	02b7e863          	bltu	a5,a1,8000334e <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003322:	02059793          	slli	a5,a1,0x20
    80003326:	01e7d593          	srli	a1,a5,0x1e
    8000332a:	00b504b3          	add	s1,a0,a1
    8000332e:	0504a903          	lw	s2,80(s1)
    80003332:	06091e63          	bnez	s2,800033ae <bmap+0xa4>
      addr = balloc(ip->dev);
    80003336:	4108                	lw	a0,0(a0)
    80003338:	00000097          	auipc	ra,0x0
    8000333c:	ea0080e7          	jalr	-352(ra) # 800031d8 <balloc>
    80003340:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003344:	06090563          	beqz	s2,800033ae <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003348:	0524a823          	sw	s2,80(s1)
    8000334c:	a08d                	j	800033ae <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000334e:	ff45849b          	addiw	s1,a1,-12
    80003352:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003356:	0ff00793          	li	a5,255
    8000335a:	08e7e563          	bltu	a5,a4,800033e4 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000335e:	08052903          	lw	s2,128(a0)
    80003362:	00091d63          	bnez	s2,8000337c <bmap+0x72>
      addr = balloc(ip->dev);
    80003366:	4108                	lw	a0,0(a0)
    80003368:	00000097          	auipc	ra,0x0
    8000336c:	e70080e7          	jalr	-400(ra) # 800031d8 <balloc>
    80003370:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003374:	02090d63          	beqz	s2,800033ae <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003378:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000337c:	85ca                	mv	a1,s2
    8000337e:	0009a503          	lw	a0,0(s3)
    80003382:	00000097          	auipc	ra,0x0
    80003386:	b96080e7          	jalr	-1130(ra) # 80002f18 <bread>
    8000338a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000338c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003390:	02049713          	slli	a4,s1,0x20
    80003394:	01e75593          	srli	a1,a4,0x1e
    80003398:	00b784b3          	add	s1,a5,a1
    8000339c:	0004a903          	lw	s2,0(s1)
    800033a0:	02090063          	beqz	s2,800033c0 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033a4:	8552                	mv	a0,s4
    800033a6:	00000097          	auipc	ra,0x0
    800033aa:	ca2080e7          	jalr	-862(ra) # 80003048 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033ae:	854a                	mv	a0,s2
    800033b0:	70a2                	ld	ra,40(sp)
    800033b2:	7402                	ld	s0,32(sp)
    800033b4:	64e2                	ld	s1,24(sp)
    800033b6:	6942                	ld	s2,16(sp)
    800033b8:	69a2                	ld	s3,8(sp)
    800033ba:	6a02                	ld	s4,0(sp)
    800033bc:	6145                	addi	sp,sp,48
    800033be:	8082                	ret
      addr = balloc(ip->dev);
    800033c0:	0009a503          	lw	a0,0(s3)
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	e14080e7          	jalr	-492(ra) # 800031d8 <balloc>
    800033cc:	0005091b          	sext.w	s2,a0
      if(addr){
    800033d0:	fc090ae3          	beqz	s2,800033a4 <bmap+0x9a>
        a[bn] = addr;
    800033d4:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800033d8:	8552                	mv	a0,s4
    800033da:	00001097          	auipc	ra,0x1
    800033de:	ec6080e7          	jalr	-314(ra) # 800042a0 <log_write>
    800033e2:	b7c9                	j	800033a4 <bmap+0x9a>
  panic("bmap: out of range");
    800033e4:	00005517          	auipc	a0,0x5
    800033e8:	18c50513          	addi	a0,a0,396 # 80008570 <syscalls+0x118>
    800033ec:	ffffd097          	auipc	ra,0xffffd
    800033f0:	154080e7          	jalr	340(ra) # 80000540 <panic>

00000000800033f4 <iget>:
{
    800033f4:	7179                	addi	sp,sp,-48
    800033f6:	f406                	sd	ra,40(sp)
    800033f8:	f022                	sd	s0,32(sp)
    800033fa:	ec26                	sd	s1,24(sp)
    800033fc:	e84a                	sd	s2,16(sp)
    800033fe:	e44e                	sd	s3,8(sp)
    80003400:	e052                	sd	s4,0(sp)
    80003402:	1800                	addi	s0,sp,48
    80003404:	89aa                	mv	s3,a0
    80003406:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003408:	0001c517          	auipc	a0,0x1c
    8000340c:	f8050513          	addi	a0,a0,-128 # 8001f388 <itable>
    80003410:	ffffe097          	auipc	ra,0xffffe
    80003414:	838080e7          	jalr	-1992(ra) # 80000c48 <acquire>
  empty = 0;
    80003418:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000341a:	0001c497          	auipc	s1,0x1c
    8000341e:	f8648493          	addi	s1,s1,-122 # 8001f3a0 <itable+0x18>
    80003422:	0001e697          	auipc	a3,0x1e
    80003426:	a0e68693          	addi	a3,a3,-1522 # 80020e30 <log>
    8000342a:	a039                	j	80003438 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000342c:	02090b63          	beqz	s2,80003462 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003430:	08848493          	addi	s1,s1,136
    80003434:	02d48a63          	beq	s1,a3,80003468 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003438:	449c                	lw	a5,8(s1)
    8000343a:	fef059e3          	blez	a5,8000342c <iget+0x38>
    8000343e:	4098                	lw	a4,0(s1)
    80003440:	ff3716e3          	bne	a4,s3,8000342c <iget+0x38>
    80003444:	40d8                	lw	a4,4(s1)
    80003446:	ff4713e3          	bne	a4,s4,8000342c <iget+0x38>
      ip->ref++;
    8000344a:	2785                	addiw	a5,a5,1
    8000344c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000344e:	0001c517          	auipc	a0,0x1c
    80003452:	f3a50513          	addi	a0,a0,-198 # 8001f388 <itable>
    80003456:	ffffe097          	auipc	ra,0xffffe
    8000345a:	8a6080e7          	jalr	-1882(ra) # 80000cfc <release>
      return ip;
    8000345e:	8926                	mv	s2,s1
    80003460:	a03d                	j	8000348e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003462:	f7f9                	bnez	a5,80003430 <iget+0x3c>
    80003464:	8926                	mv	s2,s1
    80003466:	b7e9                	j	80003430 <iget+0x3c>
  if(empty == 0)
    80003468:	02090c63          	beqz	s2,800034a0 <iget+0xac>
  ip->dev = dev;
    8000346c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003470:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003474:	4785                	li	a5,1
    80003476:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000347a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000347e:	0001c517          	auipc	a0,0x1c
    80003482:	f0a50513          	addi	a0,a0,-246 # 8001f388 <itable>
    80003486:	ffffe097          	auipc	ra,0xffffe
    8000348a:	876080e7          	jalr	-1930(ra) # 80000cfc <release>
}
    8000348e:	854a                	mv	a0,s2
    80003490:	70a2                	ld	ra,40(sp)
    80003492:	7402                	ld	s0,32(sp)
    80003494:	64e2                	ld	s1,24(sp)
    80003496:	6942                	ld	s2,16(sp)
    80003498:	69a2                	ld	s3,8(sp)
    8000349a:	6a02                	ld	s4,0(sp)
    8000349c:	6145                	addi	sp,sp,48
    8000349e:	8082                	ret
    panic("iget: no inodes");
    800034a0:	00005517          	auipc	a0,0x5
    800034a4:	0e850513          	addi	a0,a0,232 # 80008588 <syscalls+0x130>
    800034a8:	ffffd097          	auipc	ra,0xffffd
    800034ac:	098080e7          	jalr	152(ra) # 80000540 <panic>

00000000800034b0 <fsinit>:
fsinit(int dev) {
    800034b0:	7179                	addi	sp,sp,-48
    800034b2:	f406                	sd	ra,40(sp)
    800034b4:	f022                	sd	s0,32(sp)
    800034b6:	ec26                	sd	s1,24(sp)
    800034b8:	e84a                	sd	s2,16(sp)
    800034ba:	e44e                	sd	s3,8(sp)
    800034bc:	1800                	addi	s0,sp,48
    800034be:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034c0:	4585                	li	a1,1
    800034c2:	00000097          	auipc	ra,0x0
    800034c6:	a56080e7          	jalr	-1450(ra) # 80002f18 <bread>
    800034ca:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034cc:	0001c997          	auipc	s3,0x1c
    800034d0:	e9c98993          	addi	s3,s3,-356 # 8001f368 <sb>
    800034d4:	02000613          	li	a2,32
    800034d8:	05850593          	addi	a1,a0,88
    800034dc:	854e                	mv	a0,s3
    800034de:	ffffe097          	auipc	ra,0xffffe
    800034e2:	8c2080e7          	jalr	-1854(ra) # 80000da0 <memmove>
  brelse(bp);
    800034e6:	8526                	mv	a0,s1
    800034e8:	00000097          	auipc	ra,0x0
    800034ec:	b60080e7          	jalr	-1184(ra) # 80003048 <brelse>
  if(sb.magic != FSMAGIC)
    800034f0:	0009a703          	lw	a4,0(s3)
    800034f4:	102037b7          	lui	a5,0x10203
    800034f8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034fc:	02f71263          	bne	a4,a5,80003520 <fsinit+0x70>
  initlog(dev, &sb);
    80003500:	0001c597          	auipc	a1,0x1c
    80003504:	e6858593          	addi	a1,a1,-408 # 8001f368 <sb>
    80003508:	854a                	mv	a0,s2
    8000350a:	00001097          	auipc	ra,0x1
    8000350e:	b2c080e7          	jalr	-1236(ra) # 80004036 <initlog>
}
    80003512:	70a2                	ld	ra,40(sp)
    80003514:	7402                	ld	s0,32(sp)
    80003516:	64e2                	ld	s1,24(sp)
    80003518:	6942                	ld	s2,16(sp)
    8000351a:	69a2                	ld	s3,8(sp)
    8000351c:	6145                	addi	sp,sp,48
    8000351e:	8082                	ret
    panic("invalid file system");
    80003520:	00005517          	auipc	a0,0x5
    80003524:	07850513          	addi	a0,a0,120 # 80008598 <syscalls+0x140>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	018080e7          	jalr	24(ra) # 80000540 <panic>

0000000080003530 <iinit>:
{
    80003530:	7179                	addi	sp,sp,-48
    80003532:	f406                	sd	ra,40(sp)
    80003534:	f022                	sd	s0,32(sp)
    80003536:	ec26                	sd	s1,24(sp)
    80003538:	e84a                	sd	s2,16(sp)
    8000353a:	e44e                	sd	s3,8(sp)
    8000353c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000353e:	00005597          	auipc	a1,0x5
    80003542:	07258593          	addi	a1,a1,114 # 800085b0 <syscalls+0x158>
    80003546:	0001c517          	auipc	a0,0x1c
    8000354a:	e4250513          	addi	a0,a0,-446 # 8001f388 <itable>
    8000354e:	ffffd097          	auipc	ra,0xffffd
    80003552:	66a080e7          	jalr	1642(ra) # 80000bb8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003556:	0001c497          	auipc	s1,0x1c
    8000355a:	e5a48493          	addi	s1,s1,-422 # 8001f3b0 <itable+0x28>
    8000355e:	0001e997          	auipc	s3,0x1e
    80003562:	8e298993          	addi	s3,s3,-1822 # 80020e40 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003566:	00005917          	auipc	s2,0x5
    8000356a:	05290913          	addi	s2,s2,82 # 800085b8 <syscalls+0x160>
    8000356e:	85ca                	mv	a1,s2
    80003570:	8526                	mv	a0,s1
    80003572:	00001097          	auipc	ra,0x1
    80003576:	e12080e7          	jalr	-494(ra) # 80004384 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000357a:	08848493          	addi	s1,s1,136
    8000357e:	ff3498e3          	bne	s1,s3,8000356e <iinit+0x3e>
}
    80003582:	70a2                	ld	ra,40(sp)
    80003584:	7402                	ld	s0,32(sp)
    80003586:	64e2                	ld	s1,24(sp)
    80003588:	6942                	ld	s2,16(sp)
    8000358a:	69a2                	ld	s3,8(sp)
    8000358c:	6145                	addi	sp,sp,48
    8000358e:	8082                	ret

0000000080003590 <ialloc>:
{
    80003590:	7139                	addi	sp,sp,-64
    80003592:	fc06                	sd	ra,56(sp)
    80003594:	f822                	sd	s0,48(sp)
    80003596:	f426                	sd	s1,40(sp)
    80003598:	f04a                	sd	s2,32(sp)
    8000359a:	ec4e                	sd	s3,24(sp)
    8000359c:	e852                	sd	s4,16(sp)
    8000359e:	e456                	sd	s5,8(sp)
    800035a0:	e05a                	sd	s6,0(sp)
    800035a2:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800035a4:	0001c717          	auipc	a4,0x1c
    800035a8:	dd072703          	lw	a4,-560(a4) # 8001f374 <sb+0xc>
    800035ac:	4785                	li	a5,1
    800035ae:	04e7f863          	bgeu	a5,a4,800035fe <ialloc+0x6e>
    800035b2:	8aaa                	mv	s5,a0
    800035b4:	8b2e                	mv	s6,a1
    800035b6:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035b8:	0001ca17          	auipc	s4,0x1c
    800035bc:	db0a0a13          	addi	s4,s4,-592 # 8001f368 <sb>
    800035c0:	00495593          	srli	a1,s2,0x4
    800035c4:	018a2783          	lw	a5,24(s4)
    800035c8:	9dbd                	addw	a1,a1,a5
    800035ca:	8556                	mv	a0,s5
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	94c080e7          	jalr	-1716(ra) # 80002f18 <bread>
    800035d4:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035d6:	05850993          	addi	s3,a0,88
    800035da:	00f97793          	andi	a5,s2,15
    800035de:	079a                	slli	a5,a5,0x6
    800035e0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035e2:	00099783          	lh	a5,0(s3)
    800035e6:	cf9d                	beqz	a5,80003624 <ialloc+0x94>
    brelse(bp);
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	a60080e7          	jalr	-1440(ra) # 80003048 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035f0:	0905                	addi	s2,s2,1
    800035f2:	00ca2703          	lw	a4,12(s4)
    800035f6:	0009079b          	sext.w	a5,s2
    800035fa:	fce7e3e3          	bltu	a5,a4,800035c0 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    800035fe:	00005517          	auipc	a0,0x5
    80003602:	fc250513          	addi	a0,a0,-62 # 800085c0 <syscalls+0x168>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	f84080e7          	jalr	-124(ra) # 8000058a <printf>
  return 0;
    8000360e:	4501                	li	a0,0
}
    80003610:	70e2                	ld	ra,56(sp)
    80003612:	7442                	ld	s0,48(sp)
    80003614:	74a2                	ld	s1,40(sp)
    80003616:	7902                	ld	s2,32(sp)
    80003618:	69e2                	ld	s3,24(sp)
    8000361a:	6a42                	ld	s4,16(sp)
    8000361c:	6aa2                	ld	s5,8(sp)
    8000361e:	6b02                	ld	s6,0(sp)
    80003620:	6121                	addi	sp,sp,64
    80003622:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003624:	04000613          	li	a2,64
    80003628:	4581                	li	a1,0
    8000362a:	854e                	mv	a0,s3
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	718080e7          	jalr	1816(ra) # 80000d44 <memset>
      dip->type = type;
    80003634:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003638:	8526                	mv	a0,s1
    8000363a:	00001097          	auipc	ra,0x1
    8000363e:	c66080e7          	jalr	-922(ra) # 800042a0 <log_write>
      brelse(bp);
    80003642:	8526                	mv	a0,s1
    80003644:	00000097          	auipc	ra,0x0
    80003648:	a04080e7          	jalr	-1532(ra) # 80003048 <brelse>
      return iget(dev, inum);
    8000364c:	0009059b          	sext.w	a1,s2
    80003650:	8556                	mv	a0,s5
    80003652:	00000097          	auipc	ra,0x0
    80003656:	da2080e7          	jalr	-606(ra) # 800033f4 <iget>
    8000365a:	bf5d                	j	80003610 <ialloc+0x80>

000000008000365c <iupdate>:
{
    8000365c:	1101                	addi	sp,sp,-32
    8000365e:	ec06                	sd	ra,24(sp)
    80003660:	e822                	sd	s0,16(sp)
    80003662:	e426                	sd	s1,8(sp)
    80003664:	e04a                	sd	s2,0(sp)
    80003666:	1000                	addi	s0,sp,32
    80003668:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000366a:	415c                	lw	a5,4(a0)
    8000366c:	0047d79b          	srliw	a5,a5,0x4
    80003670:	0001c597          	auipc	a1,0x1c
    80003674:	d105a583          	lw	a1,-752(a1) # 8001f380 <sb+0x18>
    80003678:	9dbd                	addw	a1,a1,a5
    8000367a:	4108                	lw	a0,0(a0)
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	89c080e7          	jalr	-1892(ra) # 80002f18 <bread>
    80003684:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003686:	05850793          	addi	a5,a0,88
    8000368a:	40d8                	lw	a4,4(s1)
    8000368c:	8b3d                	andi	a4,a4,15
    8000368e:	071a                	slli	a4,a4,0x6
    80003690:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003692:	04449703          	lh	a4,68(s1)
    80003696:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000369a:	04649703          	lh	a4,70(s1)
    8000369e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800036a2:	04849703          	lh	a4,72(s1)
    800036a6:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036aa:	04a49703          	lh	a4,74(s1)
    800036ae:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800036b2:	44f8                	lw	a4,76(s1)
    800036b4:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036b6:	03400613          	li	a2,52
    800036ba:	05048593          	addi	a1,s1,80
    800036be:	00c78513          	addi	a0,a5,12
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	6de080e7          	jalr	1758(ra) # 80000da0 <memmove>
  log_write(bp);
    800036ca:	854a                	mv	a0,s2
    800036cc:	00001097          	auipc	ra,0x1
    800036d0:	bd4080e7          	jalr	-1068(ra) # 800042a0 <log_write>
  brelse(bp);
    800036d4:	854a                	mv	a0,s2
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	972080e7          	jalr	-1678(ra) # 80003048 <brelse>
}
    800036de:	60e2                	ld	ra,24(sp)
    800036e0:	6442                	ld	s0,16(sp)
    800036e2:	64a2                	ld	s1,8(sp)
    800036e4:	6902                	ld	s2,0(sp)
    800036e6:	6105                	addi	sp,sp,32
    800036e8:	8082                	ret

00000000800036ea <idup>:
{
    800036ea:	1101                	addi	sp,sp,-32
    800036ec:	ec06                	sd	ra,24(sp)
    800036ee:	e822                	sd	s0,16(sp)
    800036f0:	e426                	sd	s1,8(sp)
    800036f2:	1000                	addi	s0,sp,32
    800036f4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036f6:	0001c517          	auipc	a0,0x1c
    800036fa:	c9250513          	addi	a0,a0,-878 # 8001f388 <itable>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	54a080e7          	jalr	1354(ra) # 80000c48 <acquire>
  ip->ref++;
    80003706:	449c                	lw	a5,8(s1)
    80003708:	2785                	addiw	a5,a5,1
    8000370a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000370c:	0001c517          	auipc	a0,0x1c
    80003710:	c7c50513          	addi	a0,a0,-900 # 8001f388 <itable>
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	5e8080e7          	jalr	1512(ra) # 80000cfc <release>
}
    8000371c:	8526                	mv	a0,s1
    8000371e:	60e2                	ld	ra,24(sp)
    80003720:	6442                	ld	s0,16(sp)
    80003722:	64a2                	ld	s1,8(sp)
    80003724:	6105                	addi	sp,sp,32
    80003726:	8082                	ret

0000000080003728 <ilock>:
{
    80003728:	1101                	addi	sp,sp,-32
    8000372a:	ec06                	sd	ra,24(sp)
    8000372c:	e822                	sd	s0,16(sp)
    8000372e:	e426                	sd	s1,8(sp)
    80003730:	e04a                	sd	s2,0(sp)
    80003732:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003734:	c115                	beqz	a0,80003758 <ilock+0x30>
    80003736:	84aa                	mv	s1,a0
    80003738:	451c                	lw	a5,8(a0)
    8000373a:	00f05f63          	blez	a5,80003758 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000373e:	0541                	addi	a0,a0,16
    80003740:	00001097          	auipc	ra,0x1
    80003744:	c7e080e7          	jalr	-898(ra) # 800043be <acquiresleep>
  if(ip->valid == 0){
    80003748:	40bc                	lw	a5,64(s1)
    8000374a:	cf99                	beqz	a5,80003768 <ilock+0x40>
}
    8000374c:	60e2                	ld	ra,24(sp)
    8000374e:	6442                	ld	s0,16(sp)
    80003750:	64a2                	ld	s1,8(sp)
    80003752:	6902                	ld	s2,0(sp)
    80003754:	6105                	addi	sp,sp,32
    80003756:	8082                	ret
    panic("ilock");
    80003758:	00005517          	auipc	a0,0x5
    8000375c:	e8050513          	addi	a0,a0,-384 # 800085d8 <syscalls+0x180>
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	de0080e7          	jalr	-544(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003768:	40dc                	lw	a5,4(s1)
    8000376a:	0047d79b          	srliw	a5,a5,0x4
    8000376e:	0001c597          	auipc	a1,0x1c
    80003772:	c125a583          	lw	a1,-1006(a1) # 8001f380 <sb+0x18>
    80003776:	9dbd                	addw	a1,a1,a5
    80003778:	4088                	lw	a0,0(s1)
    8000377a:	fffff097          	auipc	ra,0xfffff
    8000377e:	79e080e7          	jalr	1950(ra) # 80002f18 <bread>
    80003782:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003784:	05850593          	addi	a1,a0,88
    80003788:	40dc                	lw	a5,4(s1)
    8000378a:	8bbd                	andi	a5,a5,15
    8000378c:	079a                	slli	a5,a5,0x6
    8000378e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003790:	00059783          	lh	a5,0(a1)
    80003794:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003798:	00259783          	lh	a5,2(a1)
    8000379c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037a0:	00459783          	lh	a5,4(a1)
    800037a4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037a8:	00659783          	lh	a5,6(a1)
    800037ac:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037b0:	459c                	lw	a5,8(a1)
    800037b2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037b4:	03400613          	li	a2,52
    800037b8:	05b1                	addi	a1,a1,12
    800037ba:	05048513          	addi	a0,s1,80
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	5e2080e7          	jalr	1506(ra) # 80000da0 <memmove>
    brelse(bp);
    800037c6:	854a                	mv	a0,s2
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	880080e7          	jalr	-1920(ra) # 80003048 <brelse>
    ip->valid = 1;
    800037d0:	4785                	li	a5,1
    800037d2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037d4:	04449783          	lh	a5,68(s1)
    800037d8:	fbb5                	bnez	a5,8000374c <ilock+0x24>
      panic("ilock: no type");
    800037da:	00005517          	auipc	a0,0x5
    800037de:	e0650513          	addi	a0,a0,-506 # 800085e0 <syscalls+0x188>
    800037e2:	ffffd097          	auipc	ra,0xffffd
    800037e6:	d5e080e7          	jalr	-674(ra) # 80000540 <panic>

00000000800037ea <iunlock>:
{
    800037ea:	1101                	addi	sp,sp,-32
    800037ec:	ec06                	sd	ra,24(sp)
    800037ee:	e822                	sd	s0,16(sp)
    800037f0:	e426                	sd	s1,8(sp)
    800037f2:	e04a                	sd	s2,0(sp)
    800037f4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037f6:	c905                	beqz	a0,80003826 <iunlock+0x3c>
    800037f8:	84aa                	mv	s1,a0
    800037fa:	01050913          	addi	s2,a0,16
    800037fe:	854a                	mv	a0,s2
    80003800:	00001097          	auipc	ra,0x1
    80003804:	c58080e7          	jalr	-936(ra) # 80004458 <holdingsleep>
    80003808:	cd19                	beqz	a0,80003826 <iunlock+0x3c>
    8000380a:	449c                	lw	a5,8(s1)
    8000380c:	00f05d63          	blez	a5,80003826 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003810:	854a                	mv	a0,s2
    80003812:	00001097          	auipc	ra,0x1
    80003816:	c02080e7          	jalr	-1022(ra) # 80004414 <releasesleep>
}
    8000381a:	60e2                	ld	ra,24(sp)
    8000381c:	6442                	ld	s0,16(sp)
    8000381e:	64a2                	ld	s1,8(sp)
    80003820:	6902                	ld	s2,0(sp)
    80003822:	6105                	addi	sp,sp,32
    80003824:	8082                	ret
    panic("iunlock");
    80003826:	00005517          	auipc	a0,0x5
    8000382a:	dca50513          	addi	a0,a0,-566 # 800085f0 <syscalls+0x198>
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	d12080e7          	jalr	-750(ra) # 80000540 <panic>

0000000080003836 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003836:	7179                	addi	sp,sp,-48
    80003838:	f406                	sd	ra,40(sp)
    8000383a:	f022                	sd	s0,32(sp)
    8000383c:	ec26                	sd	s1,24(sp)
    8000383e:	e84a                	sd	s2,16(sp)
    80003840:	e44e                	sd	s3,8(sp)
    80003842:	e052                	sd	s4,0(sp)
    80003844:	1800                	addi	s0,sp,48
    80003846:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003848:	05050493          	addi	s1,a0,80
    8000384c:	08050913          	addi	s2,a0,128
    80003850:	a021                	j	80003858 <itrunc+0x22>
    80003852:	0491                	addi	s1,s1,4
    80003854:	01248d63          	beq	s1,s2,8000386e <itrunc+0x38>
    if(ip->addrs[i]){
    80003858:	408c                	lw	a1,0(s1)
    8000385a:	dde5                	beqz	a1,80003852 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000385c:	0009a503          	lw	a0,0(s3)
    80003860:	00000097          	auipc	ra,0x0
    80003864:	8fc080e7          	jalr	-1796(ra) # 8000315c <bfree>
      ip->addrs[i] = 0;
    80003868:	0004a023          	sw	zero,0(s1)
    8000386c:	b7dd                	j	80003852 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000386e:	0809a583          	lw	a1,128(s3)
    80003872:	e185                	bnez	a1,80003892 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003874:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003878:	854e                	mv	a0,s3
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	de2080e7          	jalr	-542(ra) # 8000365c <iupdate>
}
    80003882:	70a2                	ld	ra,40(sp)
    80003884:	7402                	ld	s0,32(sp)
    80003886:	64e2                	ld	s1,24(sp)
    80003888:	6942                	ld	s2,16(sp)
    8000388a:	69a2                	ld	s3,8(sp)
    8000388c:	6a02                	ld	s4,0(sp)
    8000388e:	6145                	addi	sp,sp,48
    80003890:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003892:	0009a503          	lw	a0,0(s3)
    80003896:	fffff097          	auipc	ra,0xfffff
    8000389a:	682080e7          	jalr	1666(ra) # 80002f18 <bread>
    8000389e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038a0:	05850493          	addi	s1,a0,88
    800038a4:	45850913          	addi	s2,a0,1112
    800038a8:	a021                	j	800038b0 <itrunc+0x7a>
    800038aa:	0491                	addi	s1,s1,4
    800038ac:	01248b63          	beq	s1,s2,800038c2 <itrunc+0x8c>
      if(a[j])
    800038b0:	408c                	lw	a1,0(s1)
    800038b2:	dde5                	beqz	a1,800038aa <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038b4:	0009a503          	lw	a0,0(s3)
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	8a4080e7          	jalr	-1884(ra) # 8000315c <bfree>
    800038c0:	b7ed                	j	800038aa <itrunc+0x74>
    brelse(bp);
    800038c2:	8552                	mv	a0,s4
    800038c4:	fffff097          	auipc	ra,0xfffff
    800038c8:	784080e7          	jalr	1924(ra) # 80003048 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038cc:	0809a583          	lw	a1,128(s3)
    800038d0:	0009a503          	lw	a0,0(s3)
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	888080e7          	jalr	-1912(ra) # 8000315c <bfree>
    ip->addrs[NDIRECT] = 0;
    800038dc:	0809a023          	sw	zero,128(s3)
    800038e0:	bf51                	j	80003874 <itrunc+0x3e>

00000000800038e2 <iput>:
{
    800038e2:	1101                	addi	sp,sp,-32
    800038e4:	ec06                	sd	ra,24(sp)
    800038e6:	e822                	sd	s0,16(sp)
    800038e8:	e426                	sd	s1,8(sp)
    800038ea:	e04a                	sd	s2,0(sp)
    800038ec:	1000                	addi	s0,sp,32
    800038ee:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038f0:	0001c517          	auipc	a0,0x1c
    800038f4:	a9850513          	addi	a0,a0,-1384 # 8001f388 <itable>
    800038f8:	ffffd097          	auipc	ra,0xffffd
    800038fc:	350080e7          	jalr	848(ra) # 80000c48 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003900:	4498                	lw	a4,8(s1)
    80003902:	4785                	li	a5,1
    80003904:	02f70363          	beq	a4,a5,8000392a <iput+0x48>
  ip->ref--;
    80003908:	449c                	lw	a5,8(s1)
    8000390a:	37fd                	addiw	a5,a5,-1
    8000390c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000390e:	0001c517          	auipc	a0,0x1c
    80003912:	a7a50513          	addi	a0,a0,-1414 # 8001f388 <itable>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	3e6080e7          	jalr	998(ra) # 80000cfc <release>
}
    8000391e:	60e2                	ld	ra,24(sp)
    80003920:	6442                	ld	s0,16(sp)
    80003922:	64a2                	ld	s1,8(sp)
    80003924:	6902                	ld	s2,0(sp)
    80003926:	6105                	addi	sp,sp,32
    80003928:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000392a:	40bc                	lw	a5,64(s1)
    8000392c:	dff1                	beqz	a5,80003908 <iput+0x26>
    8000392e:	04a49783          	lh	a5,74(s1)
    80003932:	fbf9                	bnez	a5,80003908 <iput+0x26>
    acquiresleep(&ip->lock);
    80003934:	01048913          	addi	s2,s1,16
    80003938:	854a                	mv	a0,s2
    8000393a:	00001097          	auipc	ra,0x1
    8000393e:	a84080e7          	jalr	-1404(ra) # 800043be <acquiresleep>
    release(&itable.lock);
    80003942:	0001c517          	auipc	a0,0x1c
    80003946:	a4650513          	addi	a0,a0,-1466 # 8001f388 <itable>
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	3b2080e7          	jalr	946(ra) # 80000cfc <release>
    itrunc(ip);
    80003952:	8526                	mv	a0,s1
    80003954:	00000097          	auipc	ra,0x0
    80003958:	ee2080e7          	jalr	-286(ra) # 80003836 <itrunc>
    ip->type = 0;
    8000395c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003960:	8526                	mv	a0,s1
    80003962:	00000097          	auipc	ra,0x0
    80003966:	cfa080e7          	jalr	-774(ra) # 8000365c <iupdate>
    ip->valid = 0;
    8000396a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000396e:	854a                	mv	a0,s2
    80003970:	00001097          	auipc	ra,0x1
    80003974:	aa4080e7          	jalr	-1372(ra) # 80004414 <releasesleep>
    acquire(&itable.lock);
    80003978:	0001c517          	auipc	a0,0x1c
    8000397c:	a1050513          	addi	a0,a0,-1520 # 8001f388 <itable>
    80003980:	ffffd097          	auipc	ra,0xffffd
    80003984:	2c8080e7          	jalr	712(ra) # 80000c48 <acquire>
    80003988:	b741                	j	80003908 <iput+0x26>

000000008000398a <iunlockput>:
{
    8000398a:	1101                	addi	sp,sp,-32
    8000398c:	ec06                	sd	ra,24(sp)
    8000398e:	e822                	sd	s0,16(sp)
    80003990:	e426                	sd	s1,8(sp)
    80003992:	1000                	addi	s0,sp,32
    80003994:	84aa                	mv	s1,a0
  iunlock(ip);
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	e54080e7          	jalr	-428(ra) # 800037ea <iunlock>
  iput(ip);
    8000399e:	8526                	mv	a0,s1
    800039a0:	00000097          	auipc	ra,0x0
    800039a4:	f42080e7          	jalr	-190(ra) # 800038e2 <iput>
}
    800039a8:	60e2                	ld	ra,24(sp)
    800039aa:	6442                	ld	s0,16(sp)
    800039ac:	64a2                	ld	s1,8(sp)
    800039ae:	6105                	addi	sp,sp,32
    800039b0:	8082                	ret

00000000800039b2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039b2:	1141                	addi	sp,sp,-16
    800039b4:	e422                	sd	s0,8(sp)
    800039b6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039b8:	411c                	lw	a5,0(a0)
    800039ba:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039bc:	415c                	lw	a5,4(a0)
    800039be:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039c0:	04451783          	lh	a5,68(a0)
    800039c4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039c8:	04a51783          	lh	a5,74(a0)
    800039cc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039d0:	04c56783          	lwu	a5,76(a0)
    800039d4:	e99c                	sd	a5,16(a1)
}
    800039d6:	6422                	ld	s0,8(sp)
    800039d8:	0141                	addi	sp,sp,16
    800039da:	8082                	ret

00000000800039dc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039dc:	457c                	lw	a5,76(a0)
    800039de:	0ed7e963          	bltu	a5,a3,80003ad0 <readi+0xf4>
{
    800039e2:	7159                	addi	sp,sp,-112
    800039e4:	f486                	sd	ra,104(sp)
    800039e6:	f0a2                	sd	s0,96(sp)
    800039e8:	eca6                	sd	s1,88(sp)
    800039ea:	e8ca                	sd	s2,80(sp)
    800039ec:	e4ce                	sd	s3,72(sp)
    800039ee:	e0d2                	sd	s4,64(sp)
    800039f0:	fc56                	sd	s5,56(sp)
    800039f2:	f85a                	sd	s6,48(sp)
    800039f4:	f45e                	sd	s7,40(sp)
    800039f6:	f062                	sd	s8,32(sp)
    800039f8:	ec66                	sd	s9,24(sp)
    800039fa:	e86a                	sd	s10,16(sp)
    800039fc:	e46e                	sd	s11,8(sp)
    800039fe:	1880                	addi	s0,sp,112
    80003a00:	8b2a                	mv	s6,a0
    80003a02:	8bae                	mv	s7,a1
    80003a04:	8a32                	mv	s4,a2
    80003a06:	84b6                	mv	s1,a3
    80003a08:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a0a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a0c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a0e:	0ad76063          	bltu	a4,a3,80003aae <readi+0xd2>
  if(off + n > ip->size)
    80003a12:	00e7f463          	bgeu	a5,a4,80003a1a <readi+0x3e>
    n = ip->size - off;
    80003a16:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a1a:	0a0a8963          	beqz	s5,80003acc <readi+0xf0>
    80003a1e:	4981                	li	s3,0
#if 0
    // Adil: Remove later
    printf("ip->dev; %d\n", ip->dev);
#endif

    m = min(n - tot, BSIZE - off%BSIZE);
    80003a20:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a24:	5c7d                	li	s8,-1
    80003a26:	a82d                	j	80003a60 <readi+0x84>
    80003a28:	020d1d93          	slli	s11,s10,0x20
    80003a2c:	020ddd93          	srli	s11,s11,0x20
    80003a30:	05890613          	addi	a2,s2,88
    80003a34:	86ee                	mv	a3,s11
    80003a36:	963a                	add	a2,a2,a4
    80003a38:	85d2                	mv	a1,s4
    80003a3a:	855e                	mv	a0,s7
    80003a3c:	fffff097          	auipc	ra,0xfffff
    80003a40:	ac6080e7          	jalr	-1338(ra) # 80002502 <either_copyout>
    80003a44:	05850d63          	beq	a0,s8,80003a9e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a48:	854a                	mv	a0,s2
    80003a4a:	fffff097          	auipc	ra,0xfffff
    80003a4e:	5fe080e7          	jalr	1534(ra) # 80003048 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a52:	013d09bb          	addw	s3,s10,s3
    80003a56:	009d04bb          	addw	s1,s10,s1
    80003a5a:	9a6e                	add	s4,s4,s11
    80003a5c:	0559f763          	bgeu	s3,s5,80003aaa <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a60:	00a4d59b          	srliw	a1,s1,0xa
    80003a64:	855a                	mv	a0,s6
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	8a4080e7          	jalr	-1884(ra) # 8000330a <bmap>
    80003a6e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a72:	cd85                	beqz	a1,80003aaa <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a74:	000b2503          	lw	a0,0(s6)
    80003a78:	fffff097          	auipc	ra,0xfffff
    80003a7c:	4a0080e7          	jalr	1184(ra) # 80002f18 <bread>
    80003a80:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a82:	3ff4f713          	andi	a4,s1,1023
    80003a86:	40ec87bb          	subw	a5,s9,a4
    80003a8a:	413a86bb          	subw	a3,s5,s3
    80003a8e:	8d3e                	mv	s10,a5
    80003a90:	2781                	sext.w	a5,a5
    80003a92:	0006861b          	sext.w	a2,a3
    80003a96:	f8f679e3          	bgeu	a2,a5,80003a28 <readi+0x4c>
    80003a9a:	8d36                	mv	s10,a3
    80003a9c:	b771                	j	80003a28 <readi+0x4c>
      brelse(bp);
    80003a9e:	854a                	mv	a0,s2
    80003aa0:	fffff097          	auipc	ra,0xfffff
    80003aa4:	5a8080e7          	jalr	1448(ra) # 80003048 <brelse>
      tot = -1;
    80003aa8:	59fd                	li	s3,-1
  }
  return tot;
    80003aaa:	0009851b          	sext.w	a0,s3
}
    80003aae:	70a6                	ld	ra,104(sp)
    80003ab0:	7406                	ld	s0,96(sp)
    80003ab2:	64e6                	ld	s1,88(sp)
    80003ab4:	6946                	ld	s2,80(sp)
    80003ab6:	69a6                	ld	s3,72(sp)
    80003ab8:	6a06                	ld	s4,64(sp)
    80003aba:	7ae2                	ld	s5,56(sp)
    80003abc:	7b42                	ld	s6,48(sp)
    80003abe:	7ba2                	ld	s7,40(sp)
    80003ac0:	7c02                	ld	s8,32(sp)
    80003ac2:	6ce2                	ld	s9,24(sp)
    80003ac4:	6d42                	ld	s10,16(sp)
    80003ac6:	6da2                	ld	s11,8(sp)
    80003ac8:	6165                	addi	sp,sp,112
    80003aca:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003acc:	89d6                	mv	s3,s5
    80003ace:	bff1                	j	80003aaa <readi+0xce>
    return 0;
    80003ad0:	4501                	li	a0,0
}
    80003ad2:	8082                	ret

0000000080003ad4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ad4:	457c                	lw	a5,76(a0)
    80003ad6:	10d7e863          	bltu	a5,a3,80003be6 <writei+0x112>
{
    80003ada:	7159                	addi	sp,sp,-112
    80003adc:	f486                	sd	ra,104(sp)
    80003ade:	f0a2                	sd	s0,96(sp)
    80003ae0:	eca6                	sd	s1,88(sp)
    80003ae2:	e8ca                	sd	s2,80(sp)
    80003ae4:	e4ce                	sd	s3,72(sp)
    80003ae6:	e0d2                	sd	s4,64(sp)
    80003ae8:	fc56                	sd	s5,56(sp)
    80003aea:	f85a                	sd	s6,48(sp)
    80003aec:	f45e                	sd	s7,40(sp)
    80003aee:	f062                	sd	s8,32(sp)
    80003af0:	ec66                	sd	s9,24(sp)
    80003af2:	e86a                	sd	s10,16(sp)
    80003af4:	e46e                	sd	s11,8(sp)
    80003af6:	1880                	addi	s0,sp,112
    80003af8:	8aaa                	mv	s5,a0
    80003afa:	8bae                	mv	s7,a1
    80003afc:	8a32                	mv	s4,a2
    80003afe:	8936                	mv	s2,a3
    80003b00:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b02:	00e687bb          	addw	a5,a3,a4
    80003b06:	0ed7e263          	bltu	a5,a3,80003bea <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b0a:	00043737          	lui	a4,0x43
    80003b0e:	0ef76063          	bltu	a4,a5,80003bee <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b12:	0c0b0863          	beqz	s6,80003be2 <writei+0x10e>
    80003b16:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b18:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b1c:	5c7d                	li	s8,-1
    80003b1e:	a091                	j	80003b62 <writei+0x8e>
    80003b20:	020d1d93          	slli	s11,s10,0x20
    80003b24:	020ddd93          	srli	s11,s11,0x20
    80003b28:	05848513          	addi	a0,s1,88
    80003b2c:	86ee                	mv	a3,s11
    80003b2e:	8652                	mv	a2,s4
    80003b30:	85de                	mv	a1,s7
    80003b32:	953a                	add	a0,a0,a4
    80003b34:	fffff097          	auipc	ra,0xfffff
    80003b38:	a24080e7          	jalr	-1500(ra) # 80002558 <either_copyin>
    80003b3c:	07850263          	beq	a0,s8,80003ba0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b40:	8526                	mv	a0,s1
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	75e080e7          	jalr	1886(ra) # 800042a0 <log_write>
    brelse(bp);
    80003b4a:	8526                	mv	a0,s1
    80003b4c:	fffff097          	auipc	ra,0xfffff
    80003b50:	4fc080e7          	jalr	1276(ra) # 80003048 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b54:	013d09bb          	addw	s3,s10,s3
    80003b58:	012d093b          	addw	s2,s10,s2
    80003b5c:	9a6e                	add	s4,s4,s11
    80003b5e:	0569f663          	bgeu	s3,s6,80003baa <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b62:	00a9559b          	srliw	a1,s2,0xa
    80003b66:	8556                	mv	a0,s5
    80003b68:	fffff097          	auipc	ra,0xfffff
    80003b6c:	7a2080e7          	jalr	1954(ra) # 8000330a <bmap>
    80003b70:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b74:	c99d                	beqz	a1,80003baa <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b76:	000aa503          	lw	a0,0(s5)
    80003b7a:	fffff097          	auipc	ra,0xfffff
    80003b7e:	39e080e7          	jalr	926(ra) # 80002f18 <bread>
    80003b82:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b84:	3ff97713          	andi	a4,s2,1023
    80003b88:	40ec87bb          	subw	a5,s9,a4
    80003b8c:	413b06bb          	subw	a3,s6,s3
    80003b90:	8d3e                	mv	s10,a5
    80003b92:	2781                	sext.w	a5,a5
    80003b94:	0006861b          	sext.w	a2,a3
    80003b98:	f8f674e3          	bgeu	a2,a5,80003b20 <writei+0x4c>
    80003b9c:	8d36                	mv	s10,a3
    80003b9e:	b749                	j	80003b20 <writei+0x4c>
      brelse(bp);
    80003ba0:	8526                	mv	a0,s1
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	4a6080e7          	jalr	1190(ra) # 80003048 <brelse>
  }

  if(off > ip->size)
    80003baa:	04caa783          	lw	a5,76(s5)
    80003bae:	0127f463          	bgeu	a5,s2,80003bb6 <writei+0xe2>
    ip->size = off;
    80003bb2:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bb6:	8556                	mv	a0,s5
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	aa4080e7          	jalr	-1372(ra) # 8000365c <iupdate>

  return tot;
    80003bc0:	0009851b          	sext.w	a0,s3
}
    80003bc4:	70a6                	ld	ra,104(sp)
    80003bc6:	7406                	ld	s0,96(sp)
    80003bc8:	64e6                	ld	s1,88(sp)
    80003bca:	6946                	ld	s2,80(sp)
    80003bcc:	69a6                	ld	s3,72(sp)
    80003bce:	6a06                	ld	s4,64(sp)
    80003bd0:	7ae2                	ld	s5,56(sp)
    80003bd2:	7b42                	ld	s6,48(sp)
    80003bd4:	7ba2                	ld	s7,40(sp)
    80003bd6:	7c02                	ld	s8,32(sp)
    80003bd8:	6ce2                	ld	s9,24(sp)
    80003bda:	6d42                	ld	s10,16(sp)
    80003bdc:	6da2                	ld	s11,8(sp)
    80003bde:	6165                	addi	sp,sp,112
    80003be0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003be2:	89da                	mv	s3,s6
    80003be4:	bfc9                	j	80003bb6 <writei+0xe2>
    return -1;
    80003be6:	557d                	li	a0,-1
}
    80003be8:	8082                	ret
    return -1;
    80003bea:	557d                	li	a0,-1
    80003bec:	bfe1                	j	80003bc4 <writei+0xf0>
    return -1;
    80003bee:	557d                	li	a0,-1
    80003bf0:	bfd1                	j	80003bc4 <writei+0xf0>

0000000080003bf2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bf2:	1141                	addi	sp,sp,-16
    80003bf4:	e406                	sd	ra,8(sp)
    80003bf6:	e022                	sd	s0,0(sp)
    80003bf8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bfa:	4639                	li	a2,14
    80003bfc:	ffffd097          	auipc	ra,0xffffd
    80003c00:	218080e7          	jalr	536(ra) # 80000e14 <strncmp>
}
    80003c04:	60a2                	ld	ra,8(sp)
    80003c06:	6402                	ld	s0,0(sp)
    80003c08:	0141                	addi	sp,sp,16
    80003c0a:	8082                	ret

0000000080003c0c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c0c:	7139                	addi	sp,sp,-64
    80003c0e:	fc06                	sd	ra,56(sp)
    80003c10:	f822                	sd	s0,48(sp)
    80003c12:	f426                	sd	s1,40(sp)
    80003c14:	f04a                	sd	s2,32(sp)
    80003c16:	ec4e                	sd	s3,24(sp)
    80003c18:	e852                	sd	s4,16(sp)
    80003c1a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c1c:	04451703          	lh	a4,68(a0)
    80003c20:	4785                	li	a5,1
    80003c22:	00f71a63          	bne	a4,a5,80003c36 <dirlookup+0x2a>
    80003c26:	892a                	mv	s2,a0
    80003c28:	89ae                	mv	s3,a1
    80003c2a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c2c:	457c                	lw	a5,76(a0)
    80003c2e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c30:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c32:	e79d                	bnez	a5,80003c60 <dirlookup+0x54>
    80003c34:	a8a5                	j	80003cac <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c36:	00005517          	auipc	a0,0x5
    80003c3a:	9c250513          	addi	a0,a0,-1598 # 800085f8 <syscalls+0x1a0>
    80003c3e:	ffffd097          	auipc	ra,0xffffd
    80003c42:	902080e7          	jalr	-1790(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003c46:	00005517          	auipc	a0,0x5
    80003c4a:	9ca50513          	addi	a0,a0,-1590 # 80008610 <syscalls+0x1b8>
    80003c4e:	ffffd097          	auipc	ra,0xffffd
    80003c52:	8f2080e7          	jalr	-1806(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c56:	24c1                	addiw	s1,s1,16
    80003c58:	04c92783          	lw	a5,76(s2)
    80003c5c:	04f4f763          	bgeu	s1,a5,80003caa <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c60:	4741                	li	a4,16
    80003c62:	86a6                	mv	a3,s1
    80003c64:	fc040613          	addi	a2,s0,-64
    80003c68:	4581                	li	a1,0
    80003c6a:	854a                	mv	a0,s2
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	d70080e7          	jalr	-656(ra) # 800039dc <readi>
    80003c74:	47c1                	li	a5,16
    80003c76:	fcf518e3          	bne	a0,a5,80003c46 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c7a:	fc045783          	lhu	a5,-64(s0)
    80003c7e:	dfe1                	beqz	a5,80003c56 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c80:	fc240593          	addi	a1,s0,-62
    80003c84:	854e                	mv	a0,s3
    80003c86:	00000097          	auipc	ra,0x0
    80003c8a:	f6c080e7          	jalr	-148(ra) # 80003bf2 <namecmp>
    80003c8e:	f561                	bnez	a0,80003c56 <dirlookup+0x4a>
      if(poff)
    80003c90:	000a0463          	beqz	s4,80003c98 <dirlookup+0x8c>
        *poff = off;
    80003c94:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c98:	fc045583          	lhu	a1,-64(s0)
    80003c9c:	00092503          	lw	a0,0(s2)
    80003ca0:	fffff097          	auipc	ra,0xfffff
    80003ca4:	754080e7          	jalr	1876(ra) # 800033f4 <iget>
    80003ca8:	a011                	j	80003cac <dirlookup+0xa0>
  return 0;
    80003caa:	4501                	li	a0,0
}
    80003cac:	70e2                	ld	ra,56(sp)
    80003cae:	7442                	ld	s0,48(sp)
    80003cb0:	74a2                	ld	s1,40(sp)
    80003cb2:	7902                	ld	s2,32(sp)
    80003cb4:	69e2                	ld	s3,24(sp)
    80003cb6:	6a42                	ld	s4,16(sp)
    80003cb8:	6121                	addi	sp,sp,64
    80003cba:	8082                	ret

0000000080003cbc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cbc:	711d                	addi	sp,sp,-96
    80003cbe:	ec86                	sd	ra,88(sp)
    80003cc0:	e8a2                	sd	s0,80(sp)
    80003cc2:	e4a6                	sd	s1,72(sp)
    80003cc4:	e0ca                	sd	s2,64(sp)
    80003cc6:	fc4e                	sd	s3,56(sp)
    80003cc8:	f852                	sd	s4,48(sp)
    80003cca:	f456                	sd	s5,40(sp)
    80003ccc:	f05a                	sd	s6,32(sp)
    80003cce:	ec5e                	sd	s7,24(sp)
    80003cd0:	e862                	sd	s8,16(sp)
    80003cd2:	e466                	sd	s9,8(sp)
    80003cd4:	1080                	addi	s0,sp,96
    80003cd6:	84aa                	mv	s1,a0
    80003cd8:	8b2e                	mv	s6,a1
    80003cda:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cdc:	00054703          	lbu	a4,0(a0)
    80003ce0:	02f00793          	li	a5,47
    80003ce4:	02f70263          	beq	a4,a5,80003d08 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ce8:	ffffe097          	auipc	ra,0xffffe
    80003cec:	d3c080e7          	jalr	-708(ra) # 80001a24 <myproc>
    80003cf0:	15053503          	ld	a0,336(a0)
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	9f6080e7          	jalr	-1546(ra) # 800036ea <idup>
    80003cfc:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003cfe:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d02:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d04:	4b85                	li	s7,1
    80003d06:	a875                	j	80003dc2 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003d08:	4585                	li	a1,1
    80003d0a:	4505                	li	a0,1
    80003d0c:	fffff097          	auipc	ra,0xfffff
    80003d10:	6e8080e7          	jalr	1768(ra) # 800033f4 <iget>
    80003d14:	8a2a                	mv	s4,a0
    80003d16:	b7e5                	j	80003cfe <namex+0x42>
      iunlockput(ip);
    80003d18:	8552                	mv	a0,s4
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	c70080e7          	jalr	-912(ra) # 8000398a <iunlockput>
      return 0;
    80003d22:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d24:	8552                	mv	a0,s4
    80003d26:	60e6                	ld	ra,88(sp)
    80003d28:	6446                	ld	s0,80(sp)
    80003d2a:	64a6                	ld	s1,72(sp)
    80003d2c:	6906                	ld	s2,64(sp)
    80003d2e:	79e2                	ld	s3,56(sp)
    80003d30:	7a42                	ld	s4,48(sp)
    80003d32:	7aa2                	ld	s5,40(sp)
    80003d34:	7b02                	ld	s6,32(sp)
    80003d36:	6be2                	ld	s7,24(sp)
    80003d38:	6c42                	ld	s8,16(sp)
    80003d3a:	6ca2                	ld	s9,8(sp)
    80003d3c:	6125                	addi	sp,sp,96
    80003d3e:	8082                	ret
      iunlock(ip);
    80003d40:	8552                	mv	a0,s4
    80003d42:	00000097          	auipc	ra,0x0
    80003d46:	aa8080e7          	jalr	-1368(ra) # 800037ea <iunlock>
      return ip;
    80003d4a:	bfe9                	j	80003d24 <namex+0x68>
      iunlockput(ip);
    80003d4c:	8552                	mv	a0,s4
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	c3c080e7          	jalr	-964(ra) # 8000398a <iunlockput>
      return 0;
    80003d56:	8a4e                	mv	s4,s3
    80003d58:	b7f1                	j	80003d24 <namex+0x68>
  len = path - s;
    80003d5a:	40998633          	sub	a2,s3,s1
    80003d5e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d62:	099c5863          	bge	s8,s9,80003df2 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003d66:	4639                	li	a2,14
    80003d68:	85a6                	mv	a1,s1
    80003d6a:	8556                	mv	a0,s5
    80003d6c:	ffffd097          	auipc	ra,0xffffd
    80003d70:	034080e7          	jalr	52(ra) # 80000da0 <memmove>
    80003d74:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d76:	0004c783          	lbu	a5,0(s1)
    80003d7a:	01279763          	bne	a5,s2,80003d88 <namex+0xcc>
    path++;
    80003d7e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d80:	0004c783          	lbu	a5,0(s1)
    80003d84:	ff278de3          	beq	a5,s2,80003d7e <namex+0xc2>
    ilock(ip);
    80003d88:	8552                	mv	a0,s4
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	99e080e7          	jalr	-1634(ra) # 80003728 <ilock>
    if(ip->type != T_DIR){
    80003d92:	044a1783          	lh	a5,68(s4)
    80003d96:	f97791e3          	bne	a5,s7,80003d18 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003d9a:	000b0563          	beqz	s6,80003da4 <namex+0xe8>
    80003d9e:	0004c783          	lbu	a5,0(s1)
    80003da2:	dfd9                	beqz	a5,80003d40 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003da4:	4601                	li	a2,0
    80003da6:	85d6                	mv	a1,s5
    80003da8:	8552                	mv	a0,s4
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	e62080e7          	jalr	-414(ra) # 80003c0c <dirlookup>
    80003db2:	89aa                	mv	s3,a0
    80003db4:	dd41                	beqz	a0,80003d4c <namex+0x90>
    iunlockput(ip);
    80003db6:	8552                	mv	a0,s4
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	bd2080e7          	jalr	-1070(ra) # 8000398a <iunlockput>
    ip = next;
    80003dc0:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003dc2:	0004c783          	lbu	a5,0(s1)
    80003dc6:	01279763          	bne	a5,s2,80003dd4 <namex+0x118>
    path++;
    80003dca:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dcc:	0004c783          	lbu	a5,0(s1)
    80003dd0:	ff278de3          	beq	a5,s2,80003dca <namex+0x10e>
  if(*path == 0)
    80003dd4:	cb9d                	beqz	a5,80003e0a <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003dd6:	0004c783          	lbu	a5,0(s1)
    80003dda:	89a6                	mv	s3,s1
  len = path - s;
    80003ddc:	4c81                	li	s9,0
    80003dde:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003de0:	01278963          	beq	a5,s2,80003df2 <namex+0x136>
    80003de4:	dbbd                	beqz	a5,80003d5a <namex+0x9e>
    path++;
    80003de6:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003de8:	0009c783          	lbu	a5,0(s3)
    80003dec:	ff279ce3          	bne	a5,s2,80003de4 <namex+0x128>
    80003df0:	b7ad                	j	80003d5a <namex+0x9e>
    memmove(name, s, len);
    80003df2:	2601                	sext.w	a2,a2
    80003df4:	85a6                	mv	a1,s1
    80003df6:	8556                	mv	a0,s5
    80003df8:	ffffd097          	auipc	ra,0xffffd
    80003dfc:	fa8080e7          	jalr	-88(ra) # 80000da0 <memmove>
    name[len] = 0;
    80003e00:	9cd6                	add	s9,s9,s5
    80003e02:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e06:	84ce                	mv	s1,s3
    80003e08:	b7bd                	j	80003d76 <namex+0xba>
  if(nameiparent){
    80003e0a:	f00b0de3          	beqz	s6,80003d24 <namex+0x68>
    iput(ip);
    80003e0e:	8552                	mv	a0,s4
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	ad2080e7          	jalr	-1326(ra) # 800038e2 <iput>
    return 0;
    80003e18:	4a01                	li	s4,0
    80003e1a:	b729                	j	80003d24 <namex+0x68>

0000000080003e1c <dirlink>:
{
    80003e1c:	7139                	addi	sp,sp,-64
    80003e1e:	fc06                	sd	ra,56(sp)
    80003e20:	f822                	sd	s0,48(sp)
    80003e22:	f426                	sd	s1,40(sp)
    80003e24:	f04a                	sd	s2,32(sp)
    80003e26:	ec4e                	sd	s3,24(sp)
    80003e28:	e852                	sd	s4,16(sp)
    80003e2a:	0080                	addi	s0,sp,64
    80003e2c:	892a                	mv	s2,a0
    80003e2e:	8a2e                	mv	s4,a1
    80003e30:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e32:	4601                	li	a2,0
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	dd8080e7          	jalr	-552(ra) # 80003c0c <dirlookup>
    80003e3c:	e93d                	bnez	a0,80003eb2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e3e:	04c92483          	lw	s1,76(s2)
    80003e42:	c49d                	beqz	s1,80003e70 <dirlink+0x54>
    80003e44:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e46:	4741                	li	a4,16
    80003e48:	86a6                	mv	a3,s1
    80003e4a:	fc040613          	addi	a2,s0,-64
    80003e4e:	4581                	li	a1,0
    80003e50:	854a                	mv	a0,s2
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	b8a080e7          	jalr	-1142(ra) # 800039dc <readi>
    80003e5a:	47c1                	li	a5,16
    80003e5c:	06f51163          	bne	a0,a5,80003ebe <dirlink+0xa2>
    if(de.inum == 0)
    80003e60:	fc045783          	lhu	a5,-64(s0)
    80003e64:	c791                	beqz	a5,80003e70 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e66:	24c1                	addiw	s1,s1,16
    80003e68:	04c92783          	lw	a5,76(s2)
    80003e6c:	fcf4ede3          	bltu	s1,a5,80003e46 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e70:	4639                	li	a2,14
    80003e72:	85d2                	mv	a1,s4
    80003e74:	fc240513          	addi	a0,s0,-62
    80003e78:	ffffd097          	auipc	ra,0xffffd
    80003e7c:	fd8080e7          	jalr	-40(ra) # 80000e50 <strncpy>
  de.inum = inum;
    80003e80:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e84:	4741                	li	a4,16
    80003e86:	86a6                	mv	a3,s1
    80003e88:	fc040613          	addi	a2,s0,-64
    80003e8c:	4581                	li	a1,0
    80003e8e:	854a                	mv	a0,s2
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	c44080e7          	jalr	-956(ra) # 80003ad4 <writei>
    80003e98:	1541                	addi	a0,a0,-16
    80003e9a:	00a03533          	snez	a0,a0
    80003e9e:	40a00533          	neg	a0,a0
}
    80003ea2:	70e2                	ld	ra,56(sp)
    80003ea4:	7442                	ld	s0,48(sp)
    80003ea6:	74a2                	ld	s1,40(sp)
    80003ea8:	7902                	ld	s2,32(sp)
    80003eaa:	69e2                	ld	s3,24(sp)
    80003eac:	6a42                	ld	s4,16(sp)
    80003eae:	6121                	addi	sp,sp,64
    80003eb0:	8082                	ret
    iput(ip);
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	a30080e7          	jalr	-1488(ra) # 800038e2 <iput>
    return -1;
    80003eba:	557d                	li	a0,-1
    80003ebc:	b7dd                	j	80003ea2 <dirlink+0x86>
      panic("dirlink read");
    80003ebe:	00004517          	auipc	a0,0x4
    80003ec2:	76250513          	addi	a0,a0,1890 # 80008620 <syscalls+0x1c8>
    80003ec6:	ffffc097          	auipc	ra,0xffffc
    80003eca:	67a080e7          	jalr	1658(ra) # 80000540 <panic>

0000000080003ece <namei>:

struct inode*
namei(char *path)
{
    80003ece:	1101                	addi	sp,sp,-32
    80003ed0:	ec06                	sd	ra,24(sp)
    80003ed2:	e822                	sd	s0,16(sp)
    80003ed4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ed6:	fe040613          	addi	a2,s0,-32
    80003eda:	4581                	li	a1,0
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	de0080e7          	jalr	-544(ra) # 80003cbc <namex>
}
    80003ee4:	60e2                	ld	ra,24(sp)
    80003ee6:	6442                	ld	s0,16(sp)
    80003ee8:	6105                	addi	sp,sp,32
    80003eea:	8082                	ret

0000000080003eec <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003eec:	1141                	addi	sp,sp,-16
    80003eee:	e406                	sd	ra,8(sp)
    80003ef0:	e022                	sd	s0,0(sp)
    80003ef2:	0800                	addi	s0,sp,16
    80003ef4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ef6:	4585                	li	a1,1
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	dc4080e7          	jalr	-572(ra) # 80003cbc <namex>
}
    80003f00:	60a2                	ld	ra,8(sp)
    80003f02:	6402                	ld	s0,0(sp)
    80003f04:	0141                	addi	sp,sp,16
    80003f06:	8082                	ret

0000000080003f08 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f08:	1101                	addi	sp,sp,-32
    80003f0a:	ec06                	sd	ra,24(sp)
    80003f0c:	e822                	sd	s0,16(sp)
    80003f0e:	e426                	sd	s1,8(sp)
    80003f10:	e04a                	sd	s2,0(sp)
    80003f12:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f14:	0001d917          	auipc	s2,0x1d
    80003f18:	f1c90913          	addi	s2,s2,-228 # 80020e30 <log>
    80003f1c:	01892583          	lw	a1,24(s2)
    80003f20:	02892503          	lw	a0,40(s2)
    80003f24:	fffff097          	auipc	ra,0xfffff
    80003f28:	ff4080e7          	jalr	-12(ra) # 80002f18 <bread>
    80003f2c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f2e:	02c92603          	lw	a2,44(s2)
    80003f32:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f34:	00c05f63          	blez	a2,80003f52 <write_head+0x4a>
    80003f38:	0001d717          	auipc	a4,0x1d
    80003f3c:	f2870713          	addi	a4,a4,-216 # 80020e60 <log+0x30>
    80003f40:	87aa                	mv	a5,a0
    80003f42:	060a                	slli	a2,a2,0x2
    80003f44:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003f46:	4314                	lw	a3,0(a4)
    80003f48:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003f4a:	0711                	addi	a4,a4,4
    80003f4c:	0791                	addi	a5,a5,4
    80003f4e:	fec79ce3          	bne	a5,a2,80003f46 <write_head+0x3e>
  }
  bwrite(buf);
    80003f52:	8526                	mv	a0,s1
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	0b6080e7          	jalr	182(ra) # 8000300a <bwrite>
  brelse(buf);
    80003f5c:	8526                	mv	a0,s1
    80003f5e:	fffff097          	auipc	ra,0xfffff
    80003f62:	0ea080e7          	jalr	234(ra) # 80003048 <brelse>
}
    80003f66:	60e2                	ld	ra,24(sp)
    80003f68:	6442                	ld	s0,16(sp)
    80003f6a:	64a2                	ld	s1,8(sp)
    80003f6c:	6902                	ld	s2,0(sp)
    80003f6e:	6105                	addi	sp,sp,32
    80003f70:	8082                	ret

0000000080003f72 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f72:	0001d797          	auipc	a5,0x1d
    80003f76:	eea7a783          	lw	a5,-278(a5) # 80020e5c <log+0x2c>
    80003f7a:	0af05d63          	blez	a5,80004034 <install_trans+0xc2>
{
    80003f7e:	7139                	addi	sp,sp,-64
    80003f80:	fc06                	sd	ra,56(sp)
    80003f82:	f822                	sd	s0,48(sp)
    80003f84:	f426                	sd	s1,40(sp)
    80003f86:	f04a                	sd	s2,32(sp)
    80003f88:	ec4e                	sd	s3,24(sp)
    80003f8a:	e852                	sd	s4,16(sp)
    80003f8c:	e456                	sd	s5,8(sp)
    80003f8e:	e05a                	sd	s6,0(sp)
    80003f90:	0080                	addi	s0,sp,64
    80003f92:	8b2a                	mv	s6,a0
    80003f94:	0001da97          	auipc	s5,0x1d
    80003f98:	ecca8a93          	addi	s5,s5,-308 # 80020e60 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f9c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f9e:	0001d997          	auipc	s3,0x1d
    80003fa2:	e9298993          	addi	s3,s3,-366 # 80020e30 <log>
    80003fa6:	a00d                	j	80003fc8 <install_trans+0x56>
    brelse(lbuf);
    80003fa8:	854a                	mv	a0,s2
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	09e080e7          	jalr	158(ra) # 80003048 <brelse>
    brelse(dbuf);
    80003fb2:	8526                	mv	a0,s1
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	094080e7          	jalr	148(ra) # 80003048 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fbc:	2a05                	addiw	s4,s4,1
    80003fbe:	0a91                	addi	s5,s5,4
    80003fc0:	02c9a783          	lw	a5,44(s3)
    80003fc4:	04fa5e63          	bge	s4,a5,80004020 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fc8:	0189a583          	lw	a1,24(s3)
    80003fcc:	014585bb          	addw	a1,a1,s4
    80003fd0:	2585                	addiw	a1,a1,1
    80003fd2:	0289a503          	lw	a0,40(s3)
    80003fd6:	fffff097          	auipc	ra,0xfffff
    80003fda:	f42080e7          	jalr	-190(ra) # 80002f18 <bread>
    80003fde:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fe0:	000aa583          	lw	a1,0(s5)
    80003fe4:	0289a503          	lw	a0,40(s3)
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	f30080e7          	jalr	-208(ra) # 80002f18 <bread>
    80003ff0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ff2:	40000613          	li	a2,1024
    80003ff6:	05890593          	addi	a1,s2,88
    80003ffa:	05850513          	addi	a0,a0,88
    80003ffe:	ffffd097          	auipc	ra,0xffffd
    80004002:	da2080e7          	jalr	-606(ra) # 80000da0 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004006:	8526                	mv	a0,s1
    80004008:	fffff097          	auipc	ra,0xfffff
    8000400c:	002080e7          	jalr	2(ra) # 8000300a <bwrite>
    if(recovering == 0)
    80004010:	f80b1ce3          	bnez	s6,80003fa8 <install_trans+0x36>
      bunpin(dbuf);
    80004014:	8526                	mv	a0,s1
    80004016:	fffff097          	auipc	ra,0xfffff
    8000401a:	10a080e7          	jalr	266(ra) # 80003120 <bunpin>
    8000401e:	b769                	j	80003fa8 <install_trans+0x36>
}
    80004020:	70e2                	ld	ra,56(sp)
    80004022:	7442                	ld	s0,48(sp)
    80004024:	74a2                	ld	s1,40(sp)
    80004026:	7902                	ld	s2,32(sp)
    80004028:	69e2                	ld	s3,24(sp)
    8000402a:	6a42                	ld	s4,16(sp)
    8000402c:	6aa2                	ld	s5,8(sp)
    8000402e:	6b02                	ld	s6,0(sp)
    80004030:	6121                	addi	sp,sp,64
    80004032:	8082                	ret
    80004034:	8082                	ret

0000000080004036 <initlog>:
{
    80004036:	7179                	addi	sp,sp,-48
    80004038:	f406                	sd	ra,40(sp)
    8000403a:	f022                	sd	s0,32(sp)
    8000403c:	ec26                	sd	s1,24(sp)
    8000403e:	e84a                	sd	s2,16(sp)
    80004040:	e44e                	sd	s3,8(sp)
    80004042:	1800                	addi	s0,sp,48
    80004044:	892a                	mv	s2,a0
    80004046:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004048:	0001d497          	auipc	s1,0x1d
    8000404c:	de848493          	addi	s1,s1,-536 # 80020e30 <log>
    80004050:	00004597          	auipc	a1,0x4
    80004054:	5e058593          	addi	a1,a1,1504 # 80008630 <syscalls+0x1d8>
    80004058:	8526                	mv	a0,s1
    8000405a:	ffffd097          	auipc	ra,0xffffd
    8000405e:	b5e080e7          	jalr	-1186(ra) # 80000bb8 <initlock>
  log.start = sb->logstart;
    80004062:	0149a583          	lw	a1,20(s3)
    80004066:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004068:	0109a783          	lw	a5,16(s3)
    8000406c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000406e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004072:	854a                	mv	a0,s2
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	ea4080e7          	jalr	-348(ra) # 80002f18 <bread>
  log.lh.n = lh->n;
    8000407c:	4d30                	lw	a2,88(a0)
    8000407e:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004080:	00c05f63          	blez	a2,8000409e <initlog+0x68>
    80004084:	87aa                	mv	a5,a0
    80004086:	0001d717          	auipc	a4,0x1d
    8000408a:	dda70713          	addi	a4,a4,-550 # 80020e60 <log+0x30>
    8000408e:	060a                	slli	a2,a2,0x2
    80004090:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004092:	4ff4                	lw	a3,92(a5)
    80004094:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004096:	0791                	addi	a5,a5,4
    80004098:	0711                	addi	a4,a4,4
    8000409a:	fec79ce3          	bne	a5,a2,80004092 <initlog+0x5c>
  brelse(buf);
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	faa080e7          	jalr	-86(ra) # 80003048 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040a6:	4505                	li	a0,1
    800040a8:	00000097          	auipc	ra,0x0
    800040ac:	eca080e7          	jalr	-310(ra) # 80003f72 <install_trans>
  log.lh.n = 0;
    800040b0:	0001d797          	auipc	a5,0x1d
    800040b4:	da07a623          	sw	zero,-596(a5) # 80020e5c <log+0x2c>
  write_head(); // clear the log
    800040b8:	00000097          	auipc	ra,0x0
    800040bc:	e50080e7          	jalr	-432(ra) # 80003f08 <write_head>
}
    800040c0:	70a2                	ld	ra,40(sp)
    800040c2:	7402                	ld	s0,32(sp)
    800040c4:	64e2                	ld	s1,24(sp)
    800040c6:	6942                	ld	s2,16(sp)
    800040c8:	69a2                	ld	s3,8(sp)
    800040ca:	6145                	addi	sp,sp,48
    800040cc:	8082                	ret

00000000800040ce <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040ce:	1101                	addi	sp,sp,-32
    800040d0:	ec06                	sd	ra,24(sp)
    800040d2:	e822                	sd	s0,16(sp)
    800040d4:	e426                	sd	s1,8(sp)
    800040d6:	e04a                	sd	s2,0(sp)
    800040d8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040da:	0001d517          	auipc	a0,0x1d
    800040de:	d5650513          	addi	a0,a0,-682 # 80020e30 <log>
    800040e2:	ffffd097          	auipc	ra,0xffffd
    800040e6:	b66080e7          	jalr	-1178(ra) # 80000c48 <acquire>
  while(1){
    if(log.committing){
    800040ea:	0001d497          	auipc	s1,0x1d
    800040ee:	d4648493          	addi	s1,s1,-698 # 80020e30 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040f2:	4979                	li	s2,30
    800040f4:	a039                	j	80004102 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040f6:	85a6                	mv	a1,s1
    800040f8:	8526                	mv	a0,s1
    800040fa:	ffffe097          	auipc	ra,0xffffe
    800040fe:	000080e7          	jalr	ra # 800020fa <sleep>
    if(log.committing){
    80004102:	50dc                	lw	a5,36(s1)
    80004104:	fbed                	bnez	a5,800040f6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004106:	5098                	lw	a4,32(s1)
    80004108:	2705                	addiw	a4,a4,1
    8000410a:	0027179b          	slliw	a5,a4,0x2
    8000410e:	9fb9                	addw	a5,a5,a4
    80004110:	0017979b          	slliw	a5,a5,0x1
    80004114:	54d4                	lw	a3,44(s1)
    80004116:	9fb5                	addw	a5,a5,a3
    80004118:	00f95963          	bge	s2,a5,8000412a <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000411c:	85a6                	mv	a1,s1
    8000411e:	8526                	mv	a0,s1
    80004120:	ffffe097          	auipc	ra,0xffffe
    80004124:	fda080e7          	jalr	-38(ra) # 800020fa <sleep>
    80004128:	bfe9                	j	80004102 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000412a:	0001d517          	auipc	a0,0x1d
    8000412e:	d0650513          	addi	a0,a0,-762 # 80020e30 <log>
    80004132:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004134:	ffffd097          	auipc	ra,0xffffd
    80004138:	bc8080e7          	jalr	-1080(ra) # 80000cfc <release>
      break;
    }
  }
}
    8000413c:	60e2                	ld	ra,24(sp)
    8000413e:	6442                	ld	s0,16(sp)
    80004140:	64a2                	ld	s1,8(sp)
    80004142:	6902                	ld	s2,0(sp)
    80004144:	6105                	addi	sp,sp,32
    80004146:	8082                	ret

0000000080004148 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004148:	7139                	addi	sp,sp,-64
    8000414a:	fc06                	sd	ra,56(sp)
    8000414c:	f822                	sd	s0,48(sp)
    8000414e:	f426                	sd	s1,40(sp)
    80004150:	f04a                	sd	s2,32(sp)
    80004152:	ec4e                	sd	s3,24(sp)
    80004154:	e852                	sd	s4,16(sp)
    80004156:	e456                	sd	s5,8(sp)
    80004158:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000415a:	0001d497          	auipc	s1,0x1d
    8000415e:	cd648493          	addi	s1,s1,-810 # 80020e30 <log>
    80004162:	8526                	mv	a0,s1
    80004164:	ffffd097          	auipc	ra,0xffffd
    80004168:	ae4080e7          	jalr	-1308(ra) # 80000c48 <acquire>
  log.outstanding -= 1;
    8000416c:	509c                	lw	a5,32(s1)
    8000416e:	37fd                	addiw	a5,a5,-1
    80004170:	0007891b          	sext.w	s2,a5
    80004174:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004176:	50dc                	lw	a5,36(s1)
    80004178:	e7b9                	bnez	a5,800041c6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000417a:	04091e63          	bnez	s2,800041d6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000417e:	0001d497          	auipc	s1,0x1d
    80004182:	cb248493          	addi	s1,s1,-846 # 80020e30 <log>
    80004186:	4785                	li	a5,1
    80004188:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000418a:	8526                	mv	a0,s1
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	b70080e7          	jalr	-1168(ra) # 80000cfc <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004194:	54dc                	lw	a5,44(s1)
    80004196:	06f04763          	bgtz	a5,80004204 <end_op+0xbc>
    acquire(&log.lock);
    8000419a:	0001d497          	auipc	s1,0x1d
    8000419e:	c9648493          	addi	s1,s1,-874 # 80020e30 <log>
    800041a2:	8526                	mv	a0,s1
    800041a4:	ffffd097          	auipc	ra,0xffffd
    800041a8:	aa4080e7          	jalr	-1372(ra) # 80000c48 <acquire>
    log.committing = 0;
    800041ac:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041b0:	8526                	mv	a0,s1
    800041b2:	ffffe097          	auipc	ra,0xffffe
    800041b6:	fac080e7          	jalr	-84(ra) # 8000215e <wakeup>
    release(&log.lock);
    800041ba:	8526                	mv	a0,s1
    800041bc:	ffffd097          	auipc	ra,0xffffd
    800041c0:	b40080e7          	jalr	-1216(ra) # 80000cfc <release>
}
    800041c4:	a03d                	j	800041f2 <end_op+0xaa>
    panic("log.committing");
    800041c6:	00004517          	auipc	a0,0x4
    800041ca:	47250513          	addi	a0,a0,1138 # 80008638 <syscalls+0x1e0>
    800041ce:	ffffc097          	auipc	ra,0xffffc
    800041d2:	372080e7          	jalr	882(ra) # 80000540 <panic>
    wakeup(&log);
    800041d6:	0001d497          	auipc	s1,0x1d
    800041da:	c5a48493          	addi	s1,s1,-934 # 80020e30 <log>
    800041de:	8526                	mv	a0,s1
    800041e0:	ffffe097          	auipc	ra,0xffffe
    800041e4:	f7e080e7          	jalr	-130(ra) # 8000215e <wakeup>
  release(&log.lock);
    800041e8:	8526                	mv	a0,s1
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	b12080e7          	jalr	-1262(ra) # 80000cfc <release>
}
    800041f2:	70e2                	ld	ra,56(sp)
    800041f4:	7442                	ld	s0,48(sp)
    800041f6:	74a2                	ld	s1,40(sp)
    800041f8:	7902                	ld	s2,32(sp)
    800041fa:	69e2                	ld	s3,24(sp)
    800041fc:	6a42                	ld	s4,16(sp)
    800041fe:	6aa2                	ld	s5,8(sp)
    80004200:	6121                	addi	sp,sp,64
    80004202:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004204:	0001da97          	auipc	s5,0x1d
    80004208:	c5ca8a93          	addi	s5,s5,-932 # 80020e60 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000420c:	0001da17          	auipc	s4,0x1d
    80004210:	c24a0a13          	addi	s4,s4,-988 # 80020e30 <log>
    80004214:	018a2583          	lw	a1,24(s4)
    80004218:	012585bb          	addw	a1,a1,s2
    8000421c:	2585                	addiw	a1,a1,1
    8000421e:	028a2503          	lw	a0,40(s4)
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	cf6080e7          	jalr	-778(ra) # 80002f18 <bread>
    8000422a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000422c:	000aa583          	lw	a1,0(s5)
    80004230:	028a2503          	lw	a0,40(s4)
    80004234:	fffff097          	auipc	ra,0xfffff
    80004238:	ce4080e7          	jalr	-796(ra) # 80002f18 <bread>
    8000423c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000423e:	40000613          	li	a2,1024
    80004242:	05850593          	addi	a1,a0,88
    80004246:	05848513          	addi	a0,s1,88
    8000424a:	ffffd097          	auipc	ra,0xffffd
    8000424e:	b56080e7          	jalr	-1194(ra) # 80000da0 <memmove>
    bwrite(to);  // write the log
    80004252:	8526                	mv	a0,s1
    80004254:	fffff097          	auipc	ra,0xfffff
    80004258:	db6080e7          	jalr	-586(ra) # 8000300a <bwrite>
    brelse(from);
    8000425c:	854e                	mv	a0,s3
    8000425e:	fffff097          	auipc	ra,0xfffff
    80004262:	dea080e7          	jalr	-534(ra) # 80003048 <brelse>
    brelse(to);
    80004266:	8526                	mv	a0,s1
    80004268:	fffff097          	auipc	ra,0xfffff
    8000426c:	de0080e7          	jalr	-544(ra) # 80003048 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004270:	2905                	addiw	s2,s2,1
    80004272:	0a91                	addi	s5,s5,4
    80004274:	02ca2783          	lw	a5,44(s4)
    80004278:	f8f94ee3          	blt	s2,a5,80004214 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000427c:	00000097          	auipc	ra,0x0
    80004280:	c8c080e7          	jalr	-884(ra) # 80003f08 <write_head>
    install_trans(0); // Now install writes to home locations
    80004284:	4501                	li	a0,0
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	cec080e7          	jalr	-788(ra) # 80003f72 <install_trans>
    log.lh.n = 0;
    8000428e:	0001d797          	auipc	a5,0x1d
    80004292:	bc07a723          	sw	zero,-1074(a5) # 80020e5c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004296:	00000097          	auipc	ra,0x0
    8000429a:	c72080e7          	jalr	-910(ra) # 80003f08 <write_head>
    8000429e:	bdf5                	j	8000419a <end_op+0x52>

00000000800042a0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042a0:	1101                	addi	sp,sp,-32
    800042a2:	ec06                	sd	ra,24(sp)
    800042a4:	e822                	sd	s0,16(sp)
    800042a6:	e426                	sd	s1,8(sp)
    800042a8:	e04a                	sd	s2,0(sp)
    800042aa:	1000                	addi	s0,sp,32
    800042ac:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042ae:	0001d917          	auipc	s2,0x1d
    800042b2:	b8290913          	addi	s2,s2,-1150 # 80020e30 <log>
    800042b6:	854a                	mv	a0,s2
    800042b8:	ffffd097          	auipc	ra,0xffffd
    800042bc:	990080e7          	jalr	-1648(ra) # 80000c48 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042c0:	02c92603          	lw	a2,44(s2)
    800042c4:	47f5                	li	a5,29
    800042c6:	06c7c563          	blt	a5,a2,80004330 <log_write+0x90>
    800042ca:	0001d797          	auipc	a5,0x1d
    800042ce:	b827a783          	lw	a5,-1150(a5) # 80020e4c <log+0x1c>
    800042d2:	37fd                	addiw	a5,a5,-1
    800042d4:	04f65e63          	bge	a2,a5,80004330 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042d8:	0001d797          	auipc	a5,0x1d
    800042dc:	b787a783          	lw	a5,-1160(a5) # 80020e50 <log+0x20>
    800042e0:	06f05063          	blez	a5,80004340 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042e4:	4781                	li	a5,0
    800042e6:	06c05563          	blez	a2,80004350 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042ea:	44cc                	lw	a1,12(s1)
    800042ec:	0001d717          	auipc	a4,0x1d
    800042f0:	b7470713          	addi	a4,a4,-1164 # 80020e60 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042f4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042f6:	4314                	lw	a3,0(a4)
    800042f8:	04b68c63          	beq	a3,a1,80004350 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042fc:	2785                	addiw	a5,a5,1
    800042fe:	0711                	addi	a4,a4,4
    80004300:	fef61be3          	bne	a2,a5,800042f6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004304:	0621                	addi	a2,a2,8
    80004306:	060a                	slli	a2,a2,0x2
    80004308:	0001d797          	auipc	a5,0x1d
    8000430c:	b2878793          	addi	a5,a5,-1240 # 80020e30 <log>
    80004310:	97b2                	add	a5,a5,a2
    80004312:	44d8                	lw	a4,12(s1)
    80004314:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004316:	8526                	mv	a0,s1
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	dcc080e7          	jalr	-564(ra) # 800030e4 <bpin>
    log.lh.n++;
    80004320:	0001d717          	auipc	a4,0x1d
    80004324:	b1070713          	addi	a4,a4,-1264 # 80020e30 <log>
    80004328:	575c                	lw	a5,44(a4)
    8000432a:	2785                	addiw	a5,a5,1
    8000432c:	d75c                	sw	a5,44(a4)
    8000432e:	a82d                	j	80004368 <log_write+0xc8>
    panic("too big a transaction");
    80004330:	00004517          	auipc	a0,0x4
    80004334:	31850513          	addi	a0,a0,792 # 80008648 <syscalls+0x1f0>
    80004338:	ffffc097          	auipc	ra,0xffffc
    8000433c:	208080e7          	jalr	520(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004340:	00004517          	auipc	a0,0x4
    80004344:	32050513          	addi	a0,a0,800 # 80008660 <syscalls+0x208>
    80004348:	ffffc097          	auipc	ra,0xffffc
    8000434c:	1f8080e7          	jalr	504(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004350:	00878693          	addi	a3,a5,8
    80004354:	068a                	slli	a3,a3,0x2
    80004356:	0001d717          	auipc	a4,0x1d
    8000435a:	ada70713          	addi	a4,a4,-1318 # 80020e30 <log>
    8000435e:	9736                	add	a4,a4,a3
    80004360:	44d4                	lw	a3,12(s1)
    80004362:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004364:	faf609e3          	beq	a2,a5,80004316 <log_write+0x76>
  }
  release(&log.lock);
    80004368:	0001d517          	auipc	a0,0x1d
    8000436c:	ac850513          	addi	a0,a0,-1336 # 80020e30 <log>
    80004370:	ffffd097          	auipc	ra,0xffffd
    80004374:	98c080e7          	jalr	-1652(ra) # 80000cfc <release>
}
    80004378:	60e2                	ld	ra,24(sp)
    8000437a:	6442                	ld	s0,16(sp)
    8000437c:	64a2                	ld	s1,8(sp)
    8000437e:	6902                	ld	s2,0(sp)
    80004380:	6105                	addi	sp,sp,32
    80004382:	8082                	ret

0000000080004384 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004384:	1101                	addi	sp,sp,-32
    80004386:	ec06                	sd	ra,24(sp)
    80004388:	e822                	sd	s0,16(sp)
    8000438a:	e426                	sd	s1,8(sp)
    8000438c:	e04a                	sd	s2,0(sp)
    8000438e:	1000                	addi	s0,sp,32
    80004390:	84aa                	mv	s1,a0
    80004392:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004394:	00004597          	auipc	a1,0x4
    80004398:	2ec58593          	addi	a1,a1,748 # 80008680 <syscalls+0x228>
    8000439c:	0521                	addi	a0,a0,8
    8000439e:	ffffd097          	auipc	ra,0xffffd
    800043a2:	81a080e7          	jalr	-2022(ra) # 80000bb8 <initlock>
  lk->name = name;
    800043a6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043aa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043ae:	0204a423          	sw	zero,40(s1)
}
    800043b2:	60e2                	ld	ra,24(sp)
    800043b4:	6442                	ld	s0,16(sp)
    800043b6:	64a2                	ld	s1,8(sp)
    800043b8:	6902                	ld	s2,0(sp)
    800043ba:	6105                	addi	sp,sp,32
    800043bc:	8082                	ret

00000000800043be <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043be:	1101                	addi	sp,sp,-32
    800043c0:	ec06                	sd	ra,24(sp)
    800043c2:	e822                	sd	s0,16(sp)
    800043c4:	e426                	sd	s1,8(sp)
    800043c6:	e04a                	sd	s2,0(sp)
    800043c8:	1000                	addi	s0,sp,32
    800043ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043cc:	00850913          	addi	s2,a0,8
    800043d0:	854a                	mv	a0,s2
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	876080e7          	jalr	-1930(ra) # 80000c48 <acquire>
  while (lk->locked) {
    800043da:	409c                	lw	a5,0(s1)
    800043dc:	cb89                	beqz	a5,800043ee <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043de:	85ca                	mv	a1,s2
    800043e0:	8526                	mv	a0,s1
    800043e2:	ffffe097          	auipc	ra,0xffffe
    800043e6:	d18080e7          	jalr	-744(ra) # 800020fa <sleep>
  while (lk->locked) {
    800043ea:	409c                	lw	a5,0(s1)
    800043ec:	fbed                	bnez	a5,800043de <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043ee:	4785                	li	a5,1
    800043f0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	632080e7          	jalr	1586(ra) # 80001a24 <myproc>
    800043fa:	591c                	lw	a5,48(a0)
    800043fc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043fe:	854a                	mv	a0,s2
    80004400:	ffffd097          	auipc	ra,0xffffd
    80004404:	8fc080e7          	jalr	-1796(ra) # 80000cfc <release>
}
    80004408:	60e2                	ld	ra,24(sp)
    8000440a:	6442                	ld	s0,16(sp)
    8000440c:	64a2                	ld	s1,8(sp)
    8000440e:	6902                	ld	s2,0(sp)
    80004410:	6105                	addi	sp,sp,32
    80004412:	8082                	ret

0000000080004414 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004414:	1101                	addi	sp,sp,-32
    80004416:	ec06                	sd	ra,24(sp)
    80004418:	e822                	sd	s0,16(sp)
    8000441a:	e426                	sd	s1,8(sp)
    8000441c:	e04a                	sd	s2,0(sp)
    8000441e:	1000                	addi	s0,sp,32
    80004420:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004422:	00850913          	addi	s2,a0,8
    80004426:	854a                	mv	a0,s2
    80004428:	ffffd097          	auipc	ra,0xffffd
    8000442c:	820080e7          	jalr	-2016(ra) # 80000c48 <acquire>
  lk->locked = 0;
    80004430:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004434:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004438:	8526                	mv	a0,s1
    8000443a:	ffffe097          	auipc	ra,0xffffe
    8000443e:	d24080e7          	jalr	-732(ra) # 8000215e <wakeup>
  release(&lk->lk);
    80004442:	854a                	mv	a0,s2
    80004444:	ffffd097          	auipc	ra,0xffffd
    80004448:	8b8080e7          	jalr	-1864(ra) # 80000cfc <release>
}
    8000444c:	60e2                	ld	ra,24(sp)
    8000444e:	6442                	ld	s0,16(sp)
    80004450:	64a2                	ld	s1,8(sp)
    80004452:	6902                	ld	s2,0(sp)
    80004454:	6105                	addi	sp,sp,32
    80004456:	8082                	ret

0000000080004458 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004458:	7179                	addi	sp,sp,-48
    8000445a:	f406                	sd	ra,40(sp)
    8000445c:	f022                	sd	s0,32(sp)
    8000445e:	ec26                	sd	s1,24(sp)
    80004460:	e84a                	sd	s2,16(sp)
    80004462:	e44e                	sd	s3,8(sp)
    80004464:	1800                	addi	s0,sp,48
    80004466:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004468:	00850913          	addi	s2,a0,8
    8000446c:	854a                	mv	a0,s2
    8000446e:	ffffc097          	auipc	ra,0xffffc
    80004472:	7da080e7          	jalr	2010(ra) # 80000c48 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004476:	409c                	lw	a5,0(s1)
    80004478:	ef99                	bnez	a5,80004496 <holdingsleep+0x3e>
    8000447a:	4481                	li	s1,0
  release(&lk->lk);
    8000447c:	854a                	mv	a0,s2
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	87e080e7          	jalr	-1922(ra) # 80000cfc <release>
  return r;
}
    80004486:	8526                	mv	a0,s1
    80004488:	70a2                	ld	ra,40(sp)
    8000448a:	7402                	ld	s0,32(sp)
    8000448c:	64e2                	ld	s1,24(sp)
    8000448e:	6942                	ld	s2,16(sp)
    80004490:	69a2                	ld	s3,8(sp)
    80004492:	6145                	addi	sp,sp,48
    80004494:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004496:	0284a983          	lw	s3,40(s1)
    8000449a:	ffffd097          	auipc	ra,0xffffd
    8000449e:	58a080e7          	jalr	1418(ra) # 80001a24 <myproc>
    800044a2:	5904                	lw	s1,48(a0)
    800044a4:	413484b3          	sub	s1,s1,s3
    800044a8:	0014b493          	seqz	s1,s1
    800044ac:	bfc1                	j	8000447c <holdingsleep+0x24>

00000000800044ae <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044ae:	1141                	addi	sp,sp,-16
    800044b0:	e406                	sd	ra,8(sp)
    800044b2:	e022                	sd	s0,0(sp)
    800044b4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044b6:	00004597          	auipc	a1,0x4
    800044ba:	1da58593          	addi	a1,a1,474 # 80008690 <syscalls+0x238>
    800044be:	0001d517          	auipc	a0,0x1d
    800044c2:	aba50513          	addi	a0,a0,-1350 # 80020f78 <ftable>
    800044c6:	ffffc097          	auipc	ra,0xffffc
    800044ca:	6f2080e7          	jalr	1778(ra) # 80000bb8 <initlock>
}
    800044ce:	60a2                	ld	ra,8(sp)
    800044d0:	6402                	ld	s0,0(sp)
    800044d2:	0141                	addi	sp,sp,16
    800044d4:	8082                	ret

00000000800044d6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044d6:	1101                	addi	sp,sp,-32
    800044d8:	ec06                	sd	ra,24(sp)
    800044da:	e822                	sd	s0,16(sp)
    800044dc:	e426                	sd	s1,8(sp)
    800044de:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044e0:	0001d517          	auipc	a0,0x1d
    800044e4:	a9850513          	addi	a0,a0,-1384 # 80020f78 <ftable>
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	760080e7          	jalr	1888(ra) # 80000c48 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044f0:	0001d497          	auipc	s1,0x1d
    800044f4:	aa048493          	addi	s1,s1,-1376 # 80020f90 <ftable+0x18>
    800044f8:	0001e717          	auipc	a4,0x1e
    800044fc:	a3870713          	addi	a4,a4,-1480 # 80021f30 <disk>
    if(f->ref == 0){
    80004500:	40dc                	lw	a5,4(s1)
    80004502:	cf99                	beqz	a5,80004520 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004504:	02848493          	addi	s1,s1,40
    80004508:	fee49ce3          	bne	s1,a4,80004500 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000450c:	0001d517          	auipc	a0,0x1d
    80004510:	a6c50513          	addi	a0,a0,-1428 # 80020f78 <ftable>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	7e8080e7          	jalr	2024(ra) # 80000cfc <release>
  return 0;
    8000451c:	4481                	li	s1,0
    8000451e:	a819                	j	80004534 <filealloc+0x5e>
      f->ref = 1;
    80004520:	4785                	li	a5,1
    80004522:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004524:	0001d517          	auipc	a0,0x1d
    80004528:	a5450513          	addi	a0,a0,-1452 # 80020f78 <ftable>
    8000452c:	ffffc097          	auipc	ra,0xffffc
    80004530:	7d0080e7          	jalr	2000(ra) # 80000cfc <release>
}
    80004534:	8526                	mv	a0,s1
    80004536:	60e2                	ld	ra,24(sp)
    80004538:	6442                	ld	s0,16(sp)
    8000453a:	64a2                	ld	s1,8(sp)
    8000453c:	6105                	addi	sp,sp,32
    8000453e:	8082                	ret

0000000080004540 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004540:	1101                	addi	sp,sp,-32
    80004542:	ec06                	sd	ra,24(sp)
    80004544:	e822                	sd	s0,16(sp)
    80004546:	e426                	sd	s1,8(sp)
    80004548:	1000                	addi	s0,sp,32
    8000454a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000454c:	0001d517          	auipc	a0,0x1d
    80004550:	a2c50513          	addi	a0,a0,-1492 # 80020f78 <ftable>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	6f4080e7          	jalr	1780(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    8000455c:	40dc                	lw	a5,4(s1)
    8000455e:	02f05263          	blez	a5,80004582 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004562:	2785                	addiw	a5,a5,1
    80004564:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004566:	0001d517          	auipc	a0,0x1d
    8000456a:	a1250513          	addi	a0,a0,-1518 # 80020f78 <ftable>
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	78e080e7          	jalr	1934(ra) # 80000cfc <release>
  return f;
}
    80004576:	8526                	mv	a0,s1
    80004578:	60e2                	ld	ra,24(sp)
    8000457a:	6442                	ld	s0,16(sp)
    8000457c:	64a2                	ld	s1,8(sp)
    8000457e:	6105                	addi	sp,sp,32
    80004580:	8082                	ret
    panic("filedup");
    80004582:	00004517          	auipc	a0,0x4
    80004586:	11650513          	addi	a0,a0,278 # 80008698 <syscalls+0x240>
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	fb6080e7          	jalr	-74(ra) # 80000540 <panic>

0000000080004592 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004592:	7139                	addi	sp,sp,-64
    80004594:	fc06                	sd	ra,56(sp)
    80004596:	f822                	sd	s0,48(sp)
    80004598:	f426                	sd	s1,40(sp)
    8000459a:	f04a                	sd	s2,32(sp)
    8000459c:	ec4e                	sd	s3,24(sp)
    8000459e:	e852                	sd	s4,16(sp)
    800045a0:	e456                	sd	s5,8(sp)
    800045a2:	0080                	addi	s0,sp,64
    800045a4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045a6:	0001d517          	auipc	a0,0x1d
    800045aa:	9d250513          	addi	a0,a0,-1582 # 80020f78 <ftable>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	69a080e7          	jalr	1690(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    800045b6:	40dc                	lw	a5,4(s1)
    800045b8:	06f05163          	blez	a5,8000461a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045bc:	37fd                	addiw	a5,a5,-1
    800045be:	0007871b          	sext.w	a4,a5
    800045c2:	c0dc                	sw	a5,4(s1)
    800045c4:	06e04363          	bgtz	a4,8000462a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045c8:	0004a903          	lw	s2,0(s1)
    800045cc:	0094ca83          	lbu	s5,9(s1)
    800045d0:	0104ba03          	ld	s4,16(s1)
    800045d4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045d8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045dc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045e0:	0001d517          	auipc	a0,0x1d
    800045e4:	99850513          	addi	a0,a0,-1640 # 80020f78 <ftable>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	714080e7          	jalr	1812(ra) # 80000cfc <release>

  if(ff.type == FD_PIPE){
    800045f0:	4785                	li	a5,1
    800045f2:	04f90d63          	beq	s2,a5,8000464c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045f6:	3979                	addiw	s2,s2,-2
    800045f8:	4785                	li	a5,1
    800045fa:	0527e063          	bltu	a5,s2,8000463a <fileclose+0xa8>
    begin_op();
    800045fe:	00000097          	auipc	ra,0x0
    80004602:	ad0080e7          	jalr	-1328(ra) # 800040ce <begin_op>
    iput(ff.ip);
    80004606:	854e                	mv	a0,s3
    80004608:	fffff097          	auipc	ra,0xfffff
    8000460c:	2da080e7          	jalr	730(ra) # 800038e2 <iput>
    end_op();
    80004610:	00000097          	auipc	ra,0x0
    80004614:	b38080e7          	jalr	-1224(ra) # 80004148 <end_op>
    80004618:	a00d                	j	8000463a <fileclose+0xa8>
    panic("fileclose");
    8000461a:	00004517          	auipc	a0,0x4
    8000461e:	08650513          	addi	a0,a0,134 # 800086a0 <syscalls+0x248>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	f1e080e7          	jalr	-226(ra) # 80000540 <panic>
    release(&ftable.lock);
    8000462a:	0001d517          	auipc	a0,0x1d
    8000462e:	94e50513          	addi	a0,a0,-1714 # 80020f78 <ftable>
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	6ca080e7          	jalr	1738(ra) # 80000cfc <release>
  }
}
    8000463a:	70e2                	ld	ra,56(sp)
    8000463c:	7442                	ld	s0,48(sp)
    8000463e:	74a2                	ld	s1,40(sp)
    80004640:	7902                	ld	s2,32(sp)
    80004642:	69e2                	ld	s3,24(sp)
    80004644:	6a42                	ld	s4,16(sp)
    80004646:	6aa2                	ld	s5,8(sp)
    80004648:	6121                	addi	sp,sp,64
    8000464a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000464c:	85d6                	mv	a1,s5
    8000464e:	8552                	mv	a0,s4
    80004650:	00000097          	auipc	ra,0x0
    80004654:	348080e7          	jalr	840(ra) # 80004998 <pipeclose>
    80004658:	b7cd                	j	8000463a <fileclose+0xa8>

000000008000465a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000465a:	715d                	addi	sp,sp,-80
    8000465c:	e486                	sd	ra,72(sp)
    8000465e:	e0a2                	sd	s0,64(sp)
    80004660:	fc26                	sd	s1,56(sp)
    80004662:	f84a                	sd	s2,48(sp)
    80004664:	f44e                	sd	s3,40(sp)
    80004666:	0880                	addi	s0,sp,80
    80004668:	84aa                	mv	s1,a0
    8000466a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000466c:	ffffd097          	auipc	ra,0xffffd
    80004670:	3b8080e7          	jalr	952(ra) # 80001a24 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004674:	409c                	lw	a5,0(s1)
    80004676:	37f9                	addiw	a5,a5,-2
    80004678:	4705                	li	a4,1
    8000467a:	04f76763          	bltu	a4,a5,800046c8 <filestat+0x6e>
    8000467e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004680:	6c88                	ld	a0,24(s1)
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	0a6080e7          	jalr	166(ra) # 80003728 <ilock>
    stati(f->ip, &st);
    8000468a:	fb840593          	addi	a1,s0,-72
    8000468e:	6c88                	ld	a0,24(s1)
    80004690:	fffff097          	auipc	ra,0xfffff
    80004694:	322080e7          	jalr	802(ra) # 800039b2 <stati>
    iunlock(f->ip);
    80004698:	6c88                	ld	a0,24(s1)
    8000469a:	fffff097          	auipc	ra,0xfffff
    8000469e:	150080e7          	jalr	336(ra) # 800037ea <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046a2:	46e1                	li	a3,24
    800046a4:	fb840613          	addi	a2,s0,-72
    800046a8:	85ce                	mv	a1,s3
    800046aa:	05093503          	ld	a0,80(s2)
    800046ae:	ffffd097          	auipc	ra,0xffffd
    800046b2:	036080e7          	jalr	54(ra) # 800016e4 <copyout>
    800046b6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046ba:	60a6                	ld	ra,72(sp)
    800046bc:	6406                	ld	s0,64(sp)
    800046be:	74e2                	ld	s1,56(sp)
    800046c0:	7942                	ld	s2,48(sp)
    800046c2:	79a2                	ld	s3,40(sp)
    800046c4:	6161                	addi	sp,sp,80
    800046c6:	8082                	ret
  return -1;
    800046c8:	557d                	li	a0,-1
    800046ca:	bfc5                	j	800046ba <filestat+0x60>

00000000800046cc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046cc:	7179                	addi	sp,sp,-48
    800046ce:	f406                	sd	ra,40(sp)
    800046d0:	f022                	sd	s0,32(sp)
    800046d2:	ec26                	sd	s1,24(sp)
    800046d4:	e84a                	sd	s2,16(sp)
    800046d6:	e44e                	sd	s3,8(sp)
    800046d8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046da:	00854783          	lbu	a5,8(a0)
    800046de:	c3d5                	beqz	a5,80004782 <fileread+0xb6>
    800046e0:	84aa                	mv	s1,a0
    800046e2:	89ae                	mv	s3,a1
    800046e4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046e6:	411c                	lw	a5,0(a0)
    800046e8:	4705                	li	a4,1
    800046ea:	04e78963          	beq	a5,a4,8000473c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046ee:	470d                	li	a4,3
    800046f0:	04e78d63          	beq	a5,a4,8000474a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046f4:	4709                	li	a4,2
    800046f6:	06e79e63          	bne	a5,a4,80004772 <fileread+0xa6>
    ilock(f->ip);
    800046fa:	6d08                	ld	a0,24(a0)
    800046fc:	fffff097          	auipc	ra,0xfffff
    80004700:	02c080e7          	jalr	44(ra) # 80003728 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004704:	874a                	mv	a4,s2
    80004706:	5094                	lw	a3,32(s1)
    80004708:	864e                	mv	a2,s3
    8000470a:	4585                	li	a1,1
    8000470c:	6c88                	ld	a0,24(s1)
    8000470e:	fffff097          	auipc	ra,0xfffff
    80004712:	2ce080e7          	jalr	718(ra) # 800039dc <readi>
    80004716:	892a                	mv	s2,a0
    80004718:	00a05563          	blez	a0,80004722 <fileread+0x56>
      f->off += r;
    8000471c:	509c                	lw	a5,32(s1)
    8000471e:	9fa9                	addw	a5,a5,a0
    80004720:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004722:	6c88                	ld	a0,24(s1)
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	0c6080e7          	jalr	198(ra) # 800037ea <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000472c:	854a                	mv	a0,s2
    8000472e:	70a2                	ld	ra,40(sp)
    80004730:	7402                	ld	s0,32(sp)
    80004732:	64e2                	ld	s1,24(sp)
    80004734:	6942                	ld	s2,16(sp)
    80004736:	69a2                	ld	s3,8(sp)
    80004738:	6145                	addi	sp,sp,48
    8000473a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000473c:	6908                	ld	a0,16(a0)
    8000473e:	00000097          	auipc	ra,0x0
    80004742:	3c2080e7          	jalr	962(ra) # 80004b00 <piperead>
    80004746:	892a                	mv	s2,a0
    80004748:	b7d5                	j	8000472c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000474a:	02451783          	lh	a5,36(a0)
    8000474e:	03079693          	slli	a3,a5,0x30
    80004752:	92c1                	srli	a3,a3,0x30
    80004754:	4725                	li	a4,9
    80004756:	02d76863          	bltu	a4,a3,80004786 <fileread+0xba>
    8000475a:	0792                	slli	a5,a5,0x4
    8000475c:	0001c717          	auipc	a4,0x1c
    80004760:	77c70713          	addi	a4,a4,1916 # 80020ed8 <devsw>
    80004764:	97ba                	add	a5,a5,a4
    80004766:	639c                	ld	a5,0(a5)
    80004768:	c38d                	beqz	a5,8000478a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000476a:	4505                	li	a0,1
    8000476c:	9782                	jalr	a5
    8000476e:	892a                	mv	s2,a0
    80004770:	bf75                	j	8000472c <fileread+0x60>
    panic("fileread");
    80004772:	00004517          	auipc	a0,0x4
    80004776:	f3e50513          	addi	a0,a0,-194 # 800086b0 <syscalls+0x258>
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	dc6080e7          	jalr	-570(ra) # 80000540 <panic>
    return -1;
    80004782:	597d                	li	s2,-1
    80004784:	b765                	j	8000472c <fileread+0x60>
      return -1;
    80004786:	597d                	li	s2,-1
    80004788:	b755                	j	8000472c <fileread+0x60>
    8000478a:	597d                	li	s2,-1
    8000478c:	b745                	j	8000472c <fileread+0x60>

000000008000478e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000478e:	00954783          	lbu	a5,9(a0)
    80004792:	10078e63          	beqz	a5,800048ae <filewrite+0x120>
{
    80004796:	715d                	addi	sp,sp,-80
    80004798:	e486                	sd	ra,72(sp)
    8000479a:	e0a2                	sd	s0,64(sp)
    8000479c:	fc26                	sd	s1,56(sp)
    8000479e:	f84a                	sd	s2,48(sp)
    800047a0:	f44e                	sd	s3,40(sp)
    800047a2:	f052                	sd	s4,32(sp)
    800047a4:	ec56                	sd	s5,24(sp)
    800047a6:	e85a                	sd	s6,16(sp)
    800047a8:	e45e                	sd	s7,8(sp)
    800047aa:	e062                	sd	s8,0(sp)
    800047ac:	0880                	addi	s0,sp,80
    800047ae:	892a                	mv	s2,a0
    800047b0:	8b2e                	mv	s6,a1
    800047b2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047b4:	411c                	lw	a5,0(a0)
    800047b6:	4705                	li	a4,1
    800047b8:	02e78263          	beq	a5,a4,800047dc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047bc:	470d                	li	a4,3
    800047be:	02e78563          	beq	a5,a4,800047e8 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047c2:	4709                	li	a4,2
    800047c4:	0ce79d63          	bne	a5,a4,8000489e <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047c8:	0ac05b63          	blez	a2,8000487e <filewrite+0xf0>
    int i = 0;
    800047cc:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800047ce:	6b85                	lui	s7,0x1
    800047d0:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047d4:	6c05                	lui	s8,0x1
    800047d6:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047da:	a851                	j	8000486e <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047dc:	6908                	ld	a0,16(a0)
    800047de:	00000097          	auipc	ra,0x0
    800047e2:	22a080e7          	jalr	554(ra) # 80004a08 <pipewrite>
    800047e6:	a045                	j	80004886 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047e8:	02451783          	lh	a5,36(a0)
    800047ec:	03079693          	slli	a3,a5,0x30
    800047f0:	92c1                	srli	a3,a3,0x30
    800047f2:	4725                	li	a4,9
    800047f4:	0ad76f63          	bltu	a4,a3,800048b2 <filewrite+0x124>
    800047f8:	0792                	slli	a5,a5,0x4
    800047fa:	0001c717          	auipc	a4,0x1c
    800047fe:	6de70713          	addi	a4,a4,1758 # 80020ed8 <devsw>
    80004802:	97ba                	add	a5,a5,a4
    80004804:	679c                	ld	a5,8(a5)
    80004806:	cbc5                	beqz	a5,800048b6 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004808:	4505                	li	a0,1
    8000480a:	9782                	jalr	a5
    8000480c:	a8ad                	j	80004886 <filewrite+0xf8>
      if(n1 > max)
    8000480e:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004812:	00000097          	auipc	ra,0x0
    80004816:	8bc080e7          	jalr	-1860(ra) # 800040ce <begin_op>
      ilock(f->ip);
    8000481a:	01893503          	ld	a0,24(s2)
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	f0a080e7          	jalr	-246(ra) # 80003728 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004826:	8756                	mv	a4,s5
    80004828:	02092683          	lw	a3,32(s2)
    8000482c:	01698633          	add	a2,s3,s6
    80004830:	4585                	li	a1,1
    80004832:	01893503          	ld	a0,24(s2)
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	29e080e7          	jalr	670(ra) # 80003ad4 <writei>
    8000483e:	84aa                	mv	s1,a0
    80004840:	00a05763          	blez	a0,8000484e <filewrite+0xc0>
        f->off += r;
    80004844:	02092783          	lw	a5,32(s2)
    80004848:	9fa9                	addw	a5,a5,a0
    8000484a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000484e:	01893503          	ld	a0,24(s2)
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	f98080e7          	jalr	-104(ra) # 800037ea <iunlock>
      end_op();
    8000485a:	00000097          	auipc	ra,0x0
    8000485e:	8ee080e7          	jalr	-1810(ra) # 80004148 <end_op>

      if(r != n1){
    80004862:	009a9f63          	bne	s5,s1,80004880 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004866:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000486a:	0149db63          	bge	s3,s4,80004880 <filewrite+0xf2>
      int n1 = n - i;
    8000486e:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004872:	0004879b          	sext.w	a5,s1
    80004876:	f8fbdce3          	bge	s7,a5,8000480e <filewrite+0x80>
    8000487a:	84e2                	mv	s1,s8
    8000487c:	bf49                	j	8000480e <filewrite+0x80>
    int i = 0;
    8000487e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004880:	033a1d63          	bne	s4,s3,800048ba <filewrite+0x12c>
    80004884:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004886:	60a6                	ld	ra,72(sp)
    80004888:	6406                	ld	s0,64(sp)
    8000488a:	74e2                	ld	s1,56(sp)
    8000488c:	7942                	ld	s2,48(sp)
    8000488e:	79a2                	ld	s3,40(sp)
    80004890:	7a02                	ld	s4,32(sp)
    80004892:	6ae2                	ld	s5,24(sp)
    80004894:	6b42                	ld	s6,16(sp)
    80004896:	6ba2                	ld	s7,8(sp)
    80004898:	6c02                	ld	s8,0(sp)
    8000489a:	6161                	addi	sp,sp,80
    8000489c:	8082                	ret
    panic("filewrite");
    8000489e:	00004517          	auipc	a0,0x4
    800048a2:	e2250513          	addi	a0,a0,-478 # 800086c0 <syscalls+0x268>
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	c9a080e7          	jalr	-870(ra) # 80000540 <panic>
    return -1;
    800048ae:	557d                	li	a0,-1
}
    800048b0:	8082                	ret
      return -1;
    800048b2:	557d                	li	a0,-1
    800048b4:	bfc9                	j	80004886 <filewrite+0xf8>
    800048b6:	557d                	li	a0,-1
    800048b8:	b7f9                	j	80004886 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800048ba:	557d                	li	a0,-1
    800048bc:	b7e9                	j	80004886 <filewrite+0xf8>

00000000800048be <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048be:	7179                	addi	sp,sp,-48
    800048c0:	f406                	sd	ra,40(sp)
    800048c2:	f022                	sd	s0,32(sp)
    800048c4:	ec26                	sd	s1,24(sp)
    800048c6:	e84a                	sd	s2,16(sp)
    800048c8:	e44e                	sd	s3,8(sp)
    800048ca:	e052                	sd	s4,0(sp)
    800048cc:	1800                	addi	s0,sp,48
    800048ce:	84aa                	mv	s1,a0
    800048d0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048d2:	0005b023          	sd	zero,0(a1)
    800048d6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048da:	00000097          	auipc	ra,0x0
    800048de:	bfc080e7          	jalr	-1028(ra) # 800044d6 <filealloc>
    800048e2:	e088                	sd	a0,0(s1)
    800048e4:	c551                	beqz	a0,80004970 <pipealloc+0xb2>
    800048e6:	00000097          	auipc	ra,0x0
    800048ea:	bf0080e7          	jalr	-1040(ra) # 800044d6 <filealloc>
    800048ee:	00aa3023          	sd	a0,0(s4)
    800048f2:	c92d                	beqz	a0,80004964 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	264080e7          	jalr	612(ra) # 80000b58 <kalloc>
    800048fc:	892a                	mv	s2,a0
    800048fe:	c125                	beqz	a0,8000495e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004900:	4985                	li	s3,1
    80004902:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004906:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000490a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000490e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004912:	00004597          	auipc	a1,0x4
    80004916:	dbe58593          	addi	a1,a1,-578 # 800086d0 <syscalls+0x278>
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	29e080e7          	jalr	670(ra) # 80000bb8 <initlock>
  (*f0)->type = FD_PIPE;
    80004922:	609c                	ld	a5,0(s1)
    80004924:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004928:	609c                	ld	a5,0(s1)
    8000492a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000492e:	609c                	ld	a5,0(s1)
    80004930:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004934:	609c                	ld	a5,0(s1)
    80004936:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000493a:	000a3783          	ld	a5,0(s4)
    8000493e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004942:	000a3783          	ld	a5,0(s4)
    80004946:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000494a:	000a3783          	ld	a5,0(s4)
    8000494e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004952:	000a3783          	ld	a5,0(s4)
    80004956:	0127b823          	sd	s2,16(a5)
  return 0;
    8000495a:	4501                	li	a0,0
    8000495c:	a025                	j	80004984 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000495e:	6088                	ld	a0,0(s1)
    80004960:	e501                	bnez	a0,80004968 <pipealloc+0xaa>
    80004962:	a039                	j	80004970 <pipealloc+0xb2>
    80004964:	6088                	ld	a0,0(s1)
    80004966:	c51d                	beqz	a0,80004994 <pipealloc+0xd6>
    fileclose(*f0);
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	c2a080e7          	jalr	-982(ra) # 80004592 <fileclose>
  if(*f1)
    80004970:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004974:	557d                	li	a0,-1
  if(*f1)
    80004976:	c799                	beqz	a5,80004984 <pipealloc+0xc6>
    fileclose(*f1);
    80004978:	853e                	mv	a0,a5
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	c18080e7          	jalr	-1000(ra) # 80004592 <fileclose>
  return -1;
    80004982:	557d                	li	a0,-1
}
    80004984:	70a2                	ld	ra,40(sp)
    80004986:	7402                	ld	s0,32(sp)
    80004988:	64e2                	ld	s1,24(sp)
    8000498a:	6942                	ld	s2,16(sp)
    8000498c:	69a2                	ld	s3,8(sp)
    8000498e:	6a02                	ld	s4,0(sp)
    80004990:	6145                	addi	sp,sp,48
    80004992:	8082                	ret
  return -1;
    80004994:	557d                	li	a0,-1
    80004996:	b7fd                	j	80004984 <pipealloc+0xc6>

0000000080004998 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004998:	1101                	addi	sp,sp,-32
    8000499a:	ec06                	sd	ra,24(sp)
    8000499c:	e822                	sd	s0,16(sp)
    8000499e:	e426                	sd	s1,8(sp)
    800049a0:	e04a                	sd	s2,0(sp)
    800049a2:	1000                	addi	s0,sp,32
    800049a4:	84aa                	mv	s1,a0
    800049a6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	2a0080e7          	jalr	672(ra) # 80000c48 <acquire>
  if(writable){
    800049b0:	02090d63          	beqz	s2,800049ea <pipeclose+0x52>
    pi->writeopen = 0;
    800049b4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049b8:	21848513          	addi	a0,s1,536
    800049bc:	ffffd097          	auipc	ra,0xffffd
    800049c0:	7a2080e7          	jalr	1954(ra) # 8000215e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049c4:	2204b783          	ld	a5,544(s1)
    800049c8:	eb95                	bnez	a5,800049fc <pipeclose+0x64>
    release(&pi->lock);
    800049ca:	8526                	mv	a0,s1
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	330080e7          	jalr	816(ra) # 80000cfc <release>
    kfree((char*)pi);
    800049d4:	8526                	mv	a0,s1
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	084080e7          	jalr	132(ra) # 80000a5a <kfree>
  } else
    release(&pi->lock);
}
    800049de:	60e2                	ld	ra,24(sp)
    800049e0:	6442                	ld	s0,16(sp)
    800049e2:	64a2                	ld	s1,8(sp)
    800049e4:	6902                	ld	s2,0(sp)
    800049e6:	6105                	addi	sp,sp,32
    800049e8:	8082                	ret
    pi->readopen = 0;
    800049ea:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049ee:	21c48513          	addi	a0,s1,540
    800049f2:	ffffd097          	auipc	ra,0xffffd
    800049f6:	76c080e7          	jalr	1900(ra) # 8000215e <wakeup>
    800049fa:	b7e9                	j	800049c4 <pipeclose+0x2c>
    release(&pi->lock);
    800049fc:	8526                	mv	a0,s1
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	2fe080e7          	jalr	766(ra) # 80000cfc <release>
}
    80004a06:	bfe1                	j	800049de <pipeclose+0x46>

0000000080004a08 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a08:	711d                	addi	sp,sp,-96
    80004a0a:	ec86                	sd	ra,88(sp)
    80004a0c:	e8a2                	sd	s0,80(sp)
    80004a0e:	e4a6                	sd	s1,72(sp)
    80004a10:	e0ca                	sd	s2,64(sp)
    80004a12:	fc4e                	sd	s3,56(sp)
    80004a14:	f852                	sd	s4,48(sp)
    80004a16:	f456                	sd	s5,40(sp)
    80004a18:	f05a                	sd	s6,32(sp)
    80004a1a:	ec5e                	sd	s7,24(sp)
    80004a1c:	e862                	sd	s8,16(sp)
    80004a1e:	1080                	addi	s0,sp,96
    80004a20:	84aa                	mv	s1,a0
    80004a22:	8aae                	mv	s5,a1
    80004a24:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a26:	ffffd097          	auipc	ra,0xffffd
    80004a2a:	ffe080e7          	jalr	-2(ra) # 80001a24 <myproc>
    80004a2e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a30:	8526                	mv	a0,s1
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	216080e7          	jalr	534(ra) # 80000c48 <acquire>
  while(i < n){
    80004a3a:	0b405663          	blez	s4,80004ae6 <pipewrite+0xde>
  int i = 0;
    80004a3e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a40:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a42:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a46:	21c48b93          	addi	s7,s1,540
    80004a4a:	a089                	j	80004a8c <pipewrite+0x84>
      release(&pi->lock);
    80004a4c:	8526                	mv	a0,s1
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	2ae080e7          	jalr	686(ra) # 80000cfc <release>
      return -1;
    80004a56:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a58:	854a                	mv	a0,s2
    80004a5a:	60e6                	ld	ra,88(sp)
    80004a5c:	6446                	ld	s0,80(sp)
    80004a5e:	64a6                	ld	s1,72(sp)
    80004a60:	6906                	ld	s2,64(sp)
    80004a62:	79e2                	ld	s3,56(sp)
    80004a64:	7a42                	ld	s4,48(sp)
    80004a66:	7aa2                	ld	s5,40(sp)
    80004a68:	7b02                	ld	s6,32(sp)
    80004a6a:	6be2                	ld	s7,24(sp)
    80004a6c:	6c42                	ld	s8,16(sp)
    80004a6e:	6125                	addi	sp,sp,96
    80004a70:	8082                	ret
      wakeup(&pi->nread);
    80004a72:	8562                	mv	a0,s8
    80004a74:	ffffd097          	auipc	ra,0xffffd
    80004a78:	6ea080e7          	jalr	1770(ra) # 8000215e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a7c:	85a6                	mv	a1,s1
    80004a7e:	855e                	mv	a0,s7
    80004a80:	ffffd097          	auipc	ra,0xffffd
    80004a84:	67a080e7          	jalr	1658(ra) # 800020fa <sleep>
  while(i < n){
    80004a88:	07495063          	bge	s2,s4,80004ae8 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004a8c:	2204a783          	lw	a5,544(s1)
    80004a90:	dfd5                	beqz	a5,80004a4c <pipewrite+0x44>
    80004a92:	854e                	mv	a0,s3
    80004a94:	ffffe097          	auipc	ra,0xffffe
    80004a98:	90e080e7          	jalr	-1778(ra) # 800023a2 <killed>
    80004a9c:	f945                	bnez	a0,80004a4c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a9e:	2184a783          	lw	a5,536(s1)
    80004aa2:	21c4a703          	lw	a4,540(s1)
    80004aa6:	2007879b          	addiw	a5,a5,512
    80004aaa:	fcf704e3          	beq	a4,a5,80004a72 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aae:	4685                	li	a3,1
    80004ab0:	01590633          	add	a2,s2,s5
    80004ab4:	faf40593          	addi	a1,s0,-81
    80004ab8:	0509b503          	ld	a0,80(s3)
    80004abc:	ffffd097          	auipc	ra,0xffffd
    80004ac0:	cb4080e7          	jalr	-844(ra) # 80001770 <copyin>
    80004ac4:	03650263          	beq	a0,s6,80004ae8 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ac8:	21c4a783          	lw	a5,540(s1)
    80004acc:	0017871b          	addiw	a4,a5,1
    80004ad0:	20e4ae23          	sw	a4,540(s1)
    80004ad4:	1ff7f793          	andi	a5,a5,511
    80004ad8:	97a6                	add	a5,a5,s1
    80004ada:	faf44703          	lbu	a4,-81(s0)
    80004ade:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ae2:	2905                	addiw	s2,s2,1
    80004ae4:	b755                	j	80004a88 <pipewrite+0x80>
  int i = 0;
    80004ae6:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ae8:	21848513          	addi	a0,s1,536
    80004aec:	ffffd097          	auipc	ra,0xffffd
    80004af0:	672080e7          	jalr	1650(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	206080e7          	jalr	518(ra) # 80000cfc <release>
  return i;
    80004afe:	bfa9                	j	80004a58 <pipewrite+0x50>

0000000080004b00 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b00:	715d                	addi	sp,sp,-80
    80004b02:	e486                	sd	ra,72(sp)
    80004b04:	e0a2                	sd	s0,64(sp)
    80004b06:	fc26                	sd	s1,56(sp)
    80004b08:	f84a                	sd	s2,48(sp)
    80004b0a:	f44e                	sd	s3,40(sp)
    80004b0c:	f052                	sd	s4,32(sp)
    80004b0e:	ec56                	sd	s5,24(sp)
    80004b10:	e85a                	sd	s6,16(sp)
    80004b12:	0880                	addi	s0,sp,80
    80004b14:	84aa                	mv	s1,a0
    80004b16:	892e                	mv	s2,a1
    80004b18:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b1a:	ffffd097          	auipc	ra,0xffffd
    80004b1e:	f0a080e7          	jalr	-246(ra) # 80001a24 <myproc>
    80004b22:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b24:	8526                	mv	a0,s1
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	122080e7          	jalr	290(ra) # 80000c48 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b2e:	2184a703          	lw	a4,536(s1)
    80004b32:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b36:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b3a:	02f71763          	bne	a4,a5,80004b68 <piperead+0x68>
    80004b3e:	2244a783          	lw	a5,548(s1)
    80004b42:	c39d                	beqz	a5,80004b68 <piperead+0x68>
    if(killed(pr)){
    80004b44:	8552                	mv	a0,s4
    80004b46:	ffffe097          	auipc	ra,0xffffe
    80004b4a:	85c080e7          	jalr	-1956(ra) # 800023a2 <killed>
    80004b4e:	e949                	bnez	a0,80004be0 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b50:	85a6                	mv	a1,s1
    80004b52:	854e                	mv	a0,s3
    80004b54:	ffffd097          	auipc	ra,0xffffd
    80004b58:	5a6080e7          	jalr	1446(ra) # 800020fa <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b5c:	2184a703          	lw	a4,536(s1)
    80004b60:	21c4a783          	lw	a5,540(s1)
    80004b64:	fcf70de3          	beq	a4,a5,80004b3e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b68:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b6a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b6c:	05505463          	blez	s5,80004bb4 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004b70:	2184a783          	lw	a5,536(s1)
    80004b74:	21c4a703          	lw	a4,540(s1)
    80004b78:	02f70e63          	beq	a4,a5,80004bb4 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b7c:	0017871b          	addiw	a4,a5,1
    80004b80:	20e4ac23          	sw	a4,536(s1)
    80004b84:	1ff7f793          	andi	a5,a5,511
    80004b88:	97a6                	add	a5,a5,s1
    80004b8a:	0187c783          	lbu	a5,24(a5)
    80004b8e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b92:	4685                	li	a3,1
    80004b94:	fbf40613          	addi	a2,s0,-65
    80004b98:	85ca                	mv	a1,s2
    80004b9a:	050a3503          	ld	a0,80(s4)
    80004b9e:	ffffd097          	auipc	ra,0xffffd
    80004ba2:	b46080e7          	jalr	-1210(ra) # 800016e4 <copyout>
    80004ba6:	01650763          	beq	a0,s6,80004bb4 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004baa:	2985                	addiw	s3,s3,1
    80004bac:	0905                	addi	s2,s2,1
    80004bae:	fd3a91e3          	bne	s5,s3,80004b70 <piperead+0x70>
    80004bb2:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bb4:	21c48513          	addi	a0,s1,540
    80004bb8:	ffffd097          	auipc	ra,0xffffd
    80004bbc:	5a6080e7          	jalr	1446(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	13a080e7          	jalr	314(ra) # 80000cfc <release>
  return i;
}
    80004bca:	854e                	mv	a0,s3
    80004bcc:	60a6                	ld	ra,72(sp)
    80004bce:	6406                	ld	s0,64(sp)
    80004bd0:	74e2                	ld	s1,56(sp)
    80004bd2:	7942                	ld	s2,48(sp)
    80004bd4:	79a2                	ld	s3,40(sp)
    80004bd6:	7a02                	ld	s4,32(sp)
    80004bd8:	6ae2                	ld	s5,24(sp)
    80004bda:	6b42                	ld	s6,16(sp)
    80004bdc:	6161                	addi	sp,sp,80
    80004bde:	8082                	ret
      release(&pi->lock);
    80004be0:	8526                	mv	a0,s1
    80004be2:	ffffc097          	auipc	ra,0xffffc
    80004be6:	11a080e7          	jalr	282(ra) # 80000cfc <release>
      return -1;
    80004bea:	59fd                	li	s3,-1
    80004bec:	bff9                	j	80004bca <piperead+0xca>

0000000080004bee <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004bee:	1141                	addi	sp,sp,-16
    80004bf0:	e422                	sd	s0,8(sp)
    80004bf2:	0800                	addi	s0,sp,16
    80004bf4:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004bf6:	8905                	andi	a0,a0,1
    80004bf8:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004bfa:	8b89                	andi	a5,a5,2
    80004bfc:	c399                	beqz	a5,80004c02 <flags2perm+0x14>
      perm |= PTE_W;
    80004bfe:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c02:	6422                	ld	s0,8(sp)
    80004c04:	0141                	addi	sp,sp,16
    80004c06:	8082                	ret

0000000080004c08 <exec>:

int
exec(char *path, char **argv)
{
    80004c08:	df010113          	addi	sp,sp,-528
    80004c0c:	20113423          	sd	ra,520(sp)
    80004c10:	20813023          	sd	s0,512(sp)
    80004c14:	ffa6                	sd	s1,504(sp)
    80004c16:	fbca                	sd	s2,496(sp)
    80004c18:	f7ce                	sd	s3,488(sp)
    80004c1a:	f3d2                	sd	s4,480(sp)
    80004c1c:	efd6                	sd	s5,472(sp)
    80004c1e:	ebda                	sd	s6,464(sp)
    80004c20:	e7de                	sd	s7,456(sp)
    80004c22:	e3e2                	sd	s8,448(sp)
    80004c24:	ff66                	sd	s9,440(sp)
    80004c26:	fb6a                	sd	s10,432(sp)
    80004c28:	f76e                	sd	s11,424(sp)
    80004c2a:	0c00                	addi	s0,sp,528
    80004c2c:	892a                	mv	s2,a0
    80004c2e:	dea43c23          	sd	a0,-520(s0)
    80004c32:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c36:	ffffd097          	auipc	ra,0xffffd
    80004c3a:	dee080e7          	jalr	-530(ra) # 80001a24 <myproc>
    80004c3e:	84aa                	mv	s1,a0

  begin_op();
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	48e080e7          	jalr	1166(ra) # 800040ce <begin_op>

  if((ip = namei(path)) == 0){
    80004c48:	854a                	mv	a0,s2
    80004c4a:	fffff097          	auipc	ra,0xfffff
    80004c4e:	284080e7          	jalr	644(ra) # 80003ece <namei>
    80004c52:	c92d                	beqz	a0,80004cc4 <exec+0xbc>
    80004c54:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	ad2080e7          	jalr	-1326(ra) # 80003728 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c5e:	04000713          	li	a4,64
    80004c62:	4681                	li	a3,0
    80004c64:	e5040613          	addi	a2,s0,-432
    80004c68:	4581                	li	a1,0
    80004c6a:	8552                	mv	a0,s4
    80004c6c:	fffff097          	auipc	ra,0xfffff
    80004c70:	d70080e7          	jalr	-656(ra) # 800039dc <readi>
    80004c74:	04000793          	li	a5,64
    80004c78:	00f51a63          	bne	a0,a5,80004c8c <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c7c:	e5042703          	lw	a4,-432(s0)
    80004c80:	464c47b7          	lui	a5,0x464c4
    80004c84:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c88:	04f70463          	beq	a4,a5,80004cd0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c8c:	8552                	mv	a0,s4
    80004c8e:	fffff097          	auipc	ra,0xfffff
    80004c92:	cfc080e7          	jalr	-772(ra) # 8000398a <iunlockput>
    end_op();
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	4b2080e7          	jalr	1202(ra) # 80004148 <end_op>
  }
  return -1;
    80004c9e:	557d                	li	a0,-1
}
    80004ca0:	20813083          	ld	ra,520(sp)
    80004ca4:	20013403          	ld	s0,512(sp)
    80004ca8:	74fe                	ld	s1,504(sp)
    80004caa:	795e                	ld	s2,496(sp)
    80004cac:	79be                	ld	s3,488(sp)
    80004cae:	7a1e                	ld	s4,480(sp)
    80004cb0:	6afe                	ld	s5,472(sp)
    80004cb2:	6b5e                	ld	s6,464(sp)
    80004cb4:	6bbe                	ld	s7,456(sp)
    80004cb6:	6c1e                	ld	s8,448(sp)
    80004cb8:	7cfa                	ld	s9,440(sp)
    80004cba:	7d5a                	ld	s10,432(sp)
    80004cbc:	7dba                	ld	s11,424(sp)
    80004cbe:	21010113          	addi	sp,sp,528
    80004cc2:	8082                	ret
    end_op();
    80004cc4:	fffff097          	auipc	ra,0xfffff
    80004cc8:	484080e7          	jalr	1156(ra) # 80004148 <end_op>
    return -1;
    80004ccc:	557d                	li	a0,-1
    80004cce:	bfc9                	j	80004ca0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	e16080e7          	jalr	-490(ra) # 80001ae8 <proc_pagetable>
    80004cda:	8b2a                	mv	s6,a0
    80004cdc:	d945                	beqz	a0,80004c8c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cde:	e7042d03          	lw	s10,-400(s0)
    80004ce2:	e8845783          	lhu	a5,-376(s0)
    80004ce6:	10078463          	beqz	a5,80004dee <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cea:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cec:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004cee:	6c85                	lui	s9,0x1
    80004cf0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004cf4:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004cf8:	6a85                	lui	s5,0x1
    80004cfa:	a0b5                	j	80004d66 <exec+0x15e>
      panic("loadseg: address should exist");
    80004cfc:	00004517          	auipc	a0,0x4
    80004d00:	9dc50513          	addi	a0,a0,-1572 # 800086d8 <syscalls+0x280>
    80004d04:	ffffc097          	auipc	ra,0xffffc
    80004d08:	83c080e7          	jalr	-1988(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
    80004d0c:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d0e:	8726                	mv	a4,s1
    80004d10:	012c06bb          	addw	a3,s8,s2
    80004d14:	4581                	li	a1,0
    80004d16:	8552                	mv	a0,s4
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	cc4080e7          	jalr	-828(ra) # 800039dc <readi>
    80004d20:	2501                	sext.w	a0,a0
    80004d22:	2aa49963          	bne	s1,a0,80004fd4 <exec+0x3cc>
  for(i = 0; i < sz; i += PGSIZE){
    80004d26:	012a893b          	addw	s2,s5,s2
    80004d2a:	03397563          	bgeu	s2,s3,80004d54 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004d2e:	02091593          	slli	a1,s2,0x20
    80004d32:	9181                	srli	a1,a1,0x20
    80004d34:	95de                	add	a1,a1,s7
    80004d36:	855a                	mv	a0,s6
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	39c080e7          	jalr	924(ra) # 800010d4 <walkaddr>
    80004d40:	862a                	mv	a2,a0
    if(pa == 0)
    80004d42:	dd4d                	beqz	a0,80004cfc <exec+0xf4>
    if(sz - i < PGSIZE)
    80004d44:	412984bb          	subw	s1,s3,s2
    80004d48:	0004879b          	sext.w	a5,s1
    80004d4c:	fcfcf0e3          	bgeu	s9,a5,80004d0c <exec+0x104>
    80004d50:	84d6                	mv	s1,s5
    80004d52:	bf6d                	j	80004d0c <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d54:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d58:	2d85                	addiw	s11,s11,1
    80004d5a:	038d0d1b          	addiw	s10,s10,56
    80004d5e:	e8845783          	lhu	a5,-376(s0)
    80004d62:	08fdd763          	bge	s11,a5,80004df0 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004d66:	2d01                	sext.w	s10,s10
    80004d68:	03800713          	li	a4,56
    80004d6c:	86ea                	mv	a3,s10
    80004d6e:	e1840613          	addi	a2,s0,-488
    80004d72:	4581                	li	a1,0
    80004d74:	8552                	mv	a0,s4
    80004d76:	fffff097          	auipc	ra,0xfffff
    80004d7a:	c66080e7          	jalr	-922(ra) # 800039dc <readi>
    80004d7e:	03800793          	li	a5,56
    80004d82:	24f51763          	bne	a0,a5,80004fd0 <exec+0x3c8>
    if(ph.type != ELF_PROG_LOAD)
    80004d86:	e1842783          	lw	a5,-488(s0)
    80004d8a:	4705                	li	a4,1
    80004d8c:	fce796e3          	bne	a5,a4,80004d58 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004d90:	e4043483          	ld	s1,-448(s0)
    80004d94:	e3843783          	ld	a5,-456(s0)
    80004d98:	24f4e963          	bltu	s1,a5,80004fea <exec+0x3e2>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004d9c:	e2843783          	ld	a5,-472(s0)
    80004da0:	94be                	add	s1,s1,a5
    80004da2:	24f4e763          	bltu	s1,a5,80004ff0 <exec+0x3e8>
    if(ph.vaddr % PGSIZE != 0)
    80004da6:	df043703          	ld	a4,-528(s0)
    80004daa:	8ff9                	and	a5,a5,a4
    80004dac:	24079563          	bnez	a5,80004ff6 <exec+0x3ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004db0:	e1c42503          	lw	a0,-484(s0)
    80004db4:	00000097          	auipc	ra,0x0
    80004db8:	e3a080e7          	jalr	-454(ra) # 80004bee <flags2perm>
    80004dbc:	86aa                	mv	a3,a0
    80004dbe:	8626                	mv	a2,s1
    80004dc0:	85ca                	mv	a1,s2
    80004dc2:	855a                	mv	a0,s6
    80004dc4:	ffffc097          	auipc	ra,0xffffc
    80004dc8:	6c4080e7          	jalr	1732(ra) # 80001488 <uvmalloc>
    80004dcc:	e0a43423          	sd	a0,-504(s0)
    80004dd0:	22050663          	beqz	a0,80004ffc <exec+0x3f4>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004dd4:	e2843b83          	ld	s7,-472(s0)
    80004dd8:	e2042c03          	lw	s8,-480(s0)
    80004ddc:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004de0:	00098463          	beqz	s3,80004de8 <exec+0x1e0>
    80004de4:	4901                	li	s2,0
    80004de6:	b7a1                	j	80004d2e <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004de8:	e0843903          	ld	s2,-504(s0)
    80004dec:	b7b5                	j	80004d58 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dee:	4901                	li	s2,0
  iunlockput(ip);
    80004df0:	8552                	mv	a0,s4
    80004df2:	fffff097          	auipc	ra,0xfffff
    80004df6:	b98080e7          	jalr	-1128(ra) # 8000398a <iunlockput>
  end_op();
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	34e080e7          	jalr	846(ra) # 80004148 <end_op>
  p = myproc();
    80004e02:	ffffd097          	auipc	ra,0xffffd
    80004e06:	c22080e7          	jalr	-990(ra) # 80001a24 <myproc>
    80004e0a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e0c:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004e10:	6985                	lui	s3,0x1
    80004e12:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004e14:	99ca                	add	s3,s3,s2
    80004e16:	77fd                	lui	a5,0xfffff
    80004e18:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e1c:	4691                	li	a3,4
    80004e1e:	6609                	lui	a2,0x2
    80004e20:	964e                	add	a2,a2,s3
    80004e22:	85ce                	mv	a1,s3
    80004e24:	855a                	mv	a0,s6
    80004e26:	ffffc097          	auipc	ra,0xffffc
    80004e2a:	662080e7          	jalr	1634(ra) # 80001488 <uvmalloc>
    80004e2e:	892a                	mv	s2,a0
    80004e30:	e0a43423          	sd	a0,-504(s0)
    80004e34:	e509                	bnez	a0,80004e3e <exec+0x236>
  if(pagetable)
    80004e36:	e1343423          	sd	s3,-504(s0)
    80004e3a:	4a01                	li	s4,0
    80004e3c:	aa61                	j	80004fd4 <exec+0x3cc>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e3e:	75f9                	lui	a1,0xffffe
    80004e40:	95aa                	add	a1,a1,a0
    80004e42:	855a                	mv	a0,s6
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	86e080e7          	jalr	-1938(ra) # 800016b2 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e4c:	7bfd                	lui	s7,0xfffff
    80004e4e:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004e50:	e0043783          	ld	a5,-512(s0)
    80004e54:	6388                	ld	a0,0(a5)
    80004e56:	c52d                	beqz	a0,80004ec0 <exec+0x2b8>
    80004e58:	e9040993          	addi	s3,s0,-368
    80004e5c:	f9040c13          	addi	s8,s0,-112
    80004e60:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	05c080e7          	jalr	92(ra) # 80000ebe <strlen>
    80004e6a:	0015079b          	addiw	a5,a0,1
    80004e6e:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e72:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e76:	19796663          	bltu	s2,s7,80005002 <exec+0x3fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e7a:	e0043d03          	ld	s10,-512(s0)
    80004e7e:	000d3a03          	ld	s4,0(s10)
    80004e82:	8552                	mv	a0,s4
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	03a080e7          	jalr	58(ra) # 80000ebe <strlen>
    80004e8c:	0015069b          	addiw	a3,a0,1
    80004e90:	8652                	mv	a2,s4
    80004e92:	85ca                	mv	a1,s2
    80004e94:	855a                	mv	a0,s6
    80004e96:	ffffd097          	auipc	ra,0xffffd
    80004e9a:	84e080e7          	jalr	-1970(ra) # 800016e4 <copyout>
    80004e9e:	16054463          	bltz	a0,80005006 <exec+0x3fe>
    ustack[argc] = sp;
    80004ea2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ea6:	0485                	addi	s1,s1,1
    80004ea8:	008d0793          	addi	a5,s10,8
    80004eac:	e0f43023          	sd	a5,-512(s0)
    80004eb0:	008d3503          	ld	a0,8(s10)
    80004eb4:	c909                	beqz	a0,80004ec6 <exec+0x2be>
    if(argc >= MAXARG)
    80004eb6:	09a1                	addi	s3,s3,8
    80004eb8:	fb8995e3          	bne	s3,s8,80004e62 <exec+0x25a>
  ip = 0;
    80004ebc:	4a01                	li	s4,0
    80004ebe:	aa19                	j	80004fd4 <exec+0x3cc>
  sp = sz;
    80004ec0:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004ec4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ec6:	00349793          	slli	a5,s1,0x3
    80004eca:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdcc90>
    80004ece:	97a2                	add	a5,a5,s0
    80004ed0:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004ed4:	00148693          	addi	a3,s1,1
    80004ed8:	068e                	slli	a3,a3,0x3
    80004eda:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ede:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004ee2:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004ee6:	f57968e3          	bltu	s2,s7,80004e36 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004eea:	e9040613          	addi	a2,s0,-368
    80004eee:	85ca                	mv	a1,s2
    80004ef0:	855a                	mv	a0,s6
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	7f2080e7          	jalr	2034(ra) # 800016e4 <copyout>
    80004efa:	10054863          	bltz	a0,8000500a <exec+0x402>
  p->trapframe->a1 = sp;
    80004efe:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004f02:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f06:	df843783          	ld	a5,-520(s0)
    80004f0a:	0007c703          	lbu	a4,0(a5)
    80004f0e:	cf11                	beqz	a4,80004f2a <exec+0x322>
    80004f10:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f12:	02f00693          	li	a3,47
    80004f16:	a039                	j	80004f24 <exec+0x31c>
      last = s+1;
    80004f18:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f1c:	0785                	addi	a5,a5,1
    80004f1e:	fff7c703          	lbu	a4,-1(a5)
    80004f22:	c701                	beqz	a4,80004f2a <exec+0x322>
    if(*s == '/')
    80004f24:	fed71ce3          	bne	a4,a3,80004f1c <exec+0x314>
    80004f28:	bfc5                	j	80004f18 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f2a:	158a8993          	addi	s3,s5,344
    80004f2e:	4641                	li	a2,16
    80004f30:	df843583          	ld	a1,-520(s0)
    80004f34:	854e                	mv	a0,s3
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	f56080e7          	jalr	-170(ra) # 80000e8c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f3e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f42:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004f46:	e0843783          	ld	a5,-504(s0)
    80004f4a:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f4e:	058ab783          	ld	a5,88(s5)
    80004f52:	e6843703          	ld	a4,-408(s0)
    80004f56:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f58:	058ab783          	ld	a5,88(s5)
    80004f5c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f60:	85e6                	mv	a1,s9
    80004f62:	ffffd097          	auipc	ra,0xffffd
    80004f66:	c22080e7          	jalr	-990(ra) # 80001b84 <proc_freepagetable>
  if (strncmp(p->name, "vm-", 3) == 0) {
    80004f6a:	460d                	li	a2,3
    80004f6c:	00003597          	auipc	a1,0x3
    80004f70:	29458593          	addi	a1,a1,660 # 80008200 <digits+0x1c0>
    80004f74:	854e                	mv	a0,s3
    80004f76:	ffffc097          	auipc	ra,0xffffc
    80004f7a:	e9e080e7          	jalr	-354(ra) # 80000e14 <strncmp>
    80004f7e:	c501                	beqz	a0,80004f86 <exec+0x37e>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f80:	0004851b          	sext.w	a0,s1
    80004f84:	bb31                	j	80004ca0 <exec+0x98>
    if((sz1 = uvmalloc(pagetable, memaddr, memaddr + 1024*PGSIZE, PTE_W)) == 0) {
    80004f86:	4691                	li	a3,4
    80004f88:	20100613          	li	a2,513
    80004f8c:	065a                	slli	a2,a2,0x16
    80004f8e:	4585                	li	a1,1
    80004f90:	05fe                	slli	a1,a1,0x1f
    80004f92:	855a                	mv	a0,s6
    80004f94:	ffffc097          	auipc	ra,0xffffc
    80004f98:	4f4080e7          	jalr	1268(ra) # 80001488 <uvmalloc>
    80004f9c:	cd19                	beqz	a0,80004fba <exec+0x3b2>
    printf("Created a VM process and allocated memory region (%p - %p).\n", memaddr, memaddr + 1024*PGSIZE);
    80004f9e:	20100613          	li	a2,513
    80004fa2:	065a                	slli	a2,a2,0x16
    80004fa4:	4585                	li	a1,1
    80004fa6:	05fe                	slli	a1,a1,0x1f
    80004fa8:	00003517          	auipc	a0,0x3
    80004fac:	78850513          	addi	a0,a0,1928 # 80008730 <syscalls+0x2d8>
    80004fb0:	ffffb097          	auipc	ra,0xffffb
    80004fb4:	5da080e7          	jalr	1498(ra) # 8000058a <printf>
    80004fb8:	b7e1                	j	80004f80 <exec+0x378>
      printf("Error: could not allocate memory at 0x80000000 for VM.\n");
    80004fba:	00003517          	auipc	a0,0x3
    80004fbe:	73e50513          	addi	a0,a0,1854 # 800086f8 <syscalls+0x2a0>
    80004fc2:	ffffb097          	auipc	ra,0xffffb
    80004fc6:	5c8080e7          	jalr	1480(ra) # 8000058a <printf>
  sz = sz1;
    80004fca:	e0843983          	ld	s3,-504(s0)
      goto bad;
    80004fce:	b5a5                	j	80004e36 <exec+0x22e>
    80004fd0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fd4:	e0843583          	ld	a1,-504(s0)
    80004fd8:	855a                	mv	a0,s6
    80004fda:	ffffd097          	auipc	ra,0xffffd
    80004fde:	baa080e7          	jalr	-1110(ra) # 80001b84 <proc_freepagetable>
  return -1;
    80004fe2:	557d                	li	a0,-1
  if(ip){
    80004fe4:	ca0a0ee3          	beqz	s4,80004ca0 <exec+0x98>
    80004fe8:	b155                	j	80004c8c <exec+0x84>
    80004fea:	e1243423          	sd	s2,-504(s0)
    80004fee:	b7dd                	j	80004fd4 <exec+0x3cc>
    80004ff0:	e1243423          	sd	s2,-504(s0)
    80004ff4:	b7c5                	j	80004fd4 <exec+0x3cc>
    80004ff6:	e1243423          	sd	s2,-504(s0)
    80004ffa:	bfe9                	j	80004fd4 <exec+0x3cc>
    80004ffc:	e1243423          	sd	s2,-504(s0)
    80005000:	bfd1                	j	80004fd4 <exec+0x3cc>
  ip = 0;
    80005002:	4a01                	li	s4,0
    80005004:	bfc1                	j	80004fd4 <exec+0x3cc>
    80005006:	4a01                	li	s4,0
  if(pagetable)
    80005008:	b7f1                	j	80004fd4 <exec+0x3cc>
  sz = sz1;
    8000500a:	e0843983          	ld	s3,-504(s0)
    8000500e:	b525                	j	80004e36 <exec+0x22e>

0000000080005010 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005010:	7179                	addi	sp,sp,-48
    80005012:	f406                	sd	ra,40(sp)
    80005014:	f022                	sd	s0,32(sp)
    80005016:	ec26                	sd	s1,24(sp)
    80005018:	e84a                	sd	s2,16(sp)
    8000501a:	1800                	addi	s0,sp,48
    8000501c:	892e                	mv	s2,a1
    8000501e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005020:	fdc40593          	addi	a1,s0,-36
    80005024:	ffffe097          	auipc	ra,0xffffe
    80005028:	ba2080e7          	jalr	-1118(ra) # 80002bc6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000502c:	fdc42703          	lw	a4,-36(s0)
    80005030:	47bd                	li	a5,15
    80005032:	02e7eb63          	bltu	a5,a4,80005068 <argfd+0x58>
    80005036:	ffffd097          	auipc	ra,0xffffd
    8000503a:	9ee080e7          	jalr	-1554(ra) # 80001a24 <myproc>
    8000503e:	fdc42703          	lw	a4,-36(s0)
    80005042:	01a70793          	addi	a5,a4,26
    80005046:	078e                	slli	a5,a5,0x3
    80005048:	953e                	add	a0,a0,a5
    8000504a:	611c                	ld	a5,0(a0)
    8000504c:	c385                	beqz	a5,8000506c <argfd+0x5c>
    return -1;
  if(pfd)
    8000504e:	00090463          	beqz	s2,80005056 <argfd+0x46>
    *pfd = fd;
    80005052:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005056:	4501                	li	a0,0
  if(pf)
    80005058:	c091                	beqz	s1,8000505c <argfd+0x4c>
    *pf = f;
    8000505a:	e09c                	sd	a5,0(s1)
}
    8000505c:	70a2                	ld	ra,40(sp)
    8000505e:	7402                	ld	s0,32(sp)
    80005060:	64e2                	ld	s1,24(sp)
    80005062:	6942                	ld	s2,16(sp)
    80005064:	6145                	addi	sp,sp,48
    80005066:	8082                	ret
    return -1;
    80005068:	557d                	li	a0,-1
    8000506a:	bfcd                	j	8000505c <argfd+0x4c>
    8000506c:	557d                	li	a0,-1
    8000506e:	b7fd                	j	8000505c <argfd+0x4c>

0000000080005070 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005070:	1101                	addi	sp,sp,-32
    80005072:	ec06                	sd	ra,24(sp)
    80005074:	e822                	sd	s0,16(sp)
    80005076:	e426                	sd	s1,8(sp)
    80005078:	1000                	addi	s0,sp,32
    8000507a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000507c:	ffffd097          	auipc	ra,0xffffd
    80005080:	9a8080e7          	jalr	-1624(ra) # 80001a24 <myproc>
    80005084:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005086:	0d050793          	addi	a5,a0,208
    8000508a:	4501                	li	a0,0
    8000508c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000508e:	6398                	ld	a4,0(a5)
    80005090:	cb19                	beqz	a4,800050a6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005092:	2505                	addiw	a0,a0,1
    80005094:	07a1                	addi	a5,a5,8
    80005096:	fed51ce3          	bne	a0,a3,8000508e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000509a:	557d                	li	a0,-1
}
    8000509c:	60e2                	ld	ra,24(sp)
    8000509e:	6442                	ld	s0,16(sp)
    800050a0:	64a2                	ld	s1,8(sp)
    800050a2:	6105                	addi	sp,sp,32
    800050a4:	8082                	ret
      p->ofile[fd] = f;
    800050a6:	01a50793          	addi	a5,a0,26
    800050aa:	078e                	slli	a5,a5,0x3
    800050ac:	963e                	add	a2,a2,a5
    800050ae:	e204                	sd	s1,0(a2)
      return fd;
    800050b0:	b7f5                	j	8000509c <fdalloc+0x2c>

00000000800050b2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050b2:	715d                	addi	sp,sp,-80
    800050b4:	e486                	sd	ra,72(sp)
    800050b6:	e0a2                	sd	s0,64(sp)
    800050b8:	fc26                	sd	s1,56(sp)
    800050ba:	f84a                	sd	s2,48(sp)
    800050bc:	f44e                	sd	s3,40(sp)
    800050be:	f052                	sd	s4,32(sp)
    800050c0:	ec56                	sd	s5,24(sp)
    800050c2:	e85a                	sd	s6,16(sp)
    800050c4:	0880                	addi	s0,sp,80
    800050c6:	8b2e                	mv	s6,a1
    800050c8:	89b2                	mv	s3,a2
    800050ca:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050cc:	fb040593          	addi	a1,s0,-80
    800050d0:	fffff097          	auipc	ra,0xfffff
    800050d4:	e1c080e7          	jalr	-484(ra) # 80003eec <nameiparent>
    800050d8:	84aa                	mv	s1,a0
    800050da:	14050b63          	beqz	a0,80005230 <create+0x17e>
    return 0;

  ilock(dp);
    800050de:	ffffe097          	auipc	ra,0xffffe
    800050e2:	64a080e7          	jalr	1610(ra) # 80003728 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050e6:	4601                	li	a2,0
    800050e8:	fb040593          	addi	a1,s0,-80
    800050ec:	8526                	mv	a0,s1
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	b1e080e7          	jalr	-1250(ra) # 80003c0c <dirlookup>
    800050f6:	8aaa                	mv	s5,a0
    800050f8:	c921                	beqz	a0,80005148 <create+0x96>
    iunlockput(dp);
    800050fa:	8526                	mv	a0,s1
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	88e080e7          	jalr	-1906(ra) # 8000398a <iunlockput>
    ilock(ip);
    80005104:	8556                	mv	a0,s5
    80005106:	ffffe097          	auipc	ra,0xffffe
    8000510a:	622080e7          	jalr	1570(ra) # 80003728 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000510e:	4789                	li	a5,2
    80005110:	02fb1563          	bne	s6,a5,8000513a <create+0x88>
    80005114:	044ad783          	lhu	a5,68(s5)
    80005118:	37f9                	addiw	a5,a5,-2
    8000511a:	17c2                	slli	a5,a5,0x30
    8000511c:	93c1                	srli	a5,a5,0x30
    8000511e:	4705                	li	a4,1
    80005120:	00f76d63          	bltu	a4,a5,8000513a <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005124:	8556                	mv	a0,s5
    80005126:	60a6                	ld	ra,72(sp)
    80005128:	6406                	ld	s0,64(sp)
    8000512a:	74e2                	ld	s1,56(sp)
    8000512c:	7942                	ld	s2,48(sp)
    8000512e:	79a2                	ld	s3,40(sp)
    80005130:	7a02                	ld	s4,32(sp)
    80005132:	6ae2                	ld	s5,24(sp)
    80005134:	6b42                	ld	s6,16(sp)
    80005136:	6161                	addi	sp,sp,80
    80005138:	8082                	ret
    iunlockput(ip);
    8000513a:	8556                	mv	a0,s5
    8000513c:	fffff097          	auipc	ra,0xfffff
    80005140:	84e080e7          	jalr	-1970(ra) # 8000398a <iunlockput>
    return 0;
    80005144:	4a81                	li	s5,0
    80005146:	bff9                	j	80005124 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005148:	85da                	mv	a1,s6
    8000514a:	4088                	lw	a0,0(s1)
    8000514c:	ffffe097          	auipc	ra,0xffffe
    80005150:	444080e7          	jalr	1092(ra) # 80003590 <ialloc>
    80005154:	8a2a                	mv	s4,a0
    80005156:	c529                	beqz	a0,800051a0 <create+0xee>
  ilock(ip);
    80005158:	ffffe097          	auipc	ra,0xffffe
    8000515c:	5d0080e7          	jalr	1488(ra) # 80003728 <ilock>
  ip->major = major;
    80005160:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005164:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005168:	4905                	li	s2,1
    8000516a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000516e:	8552                	mv	a0,s4
    80005170:	ffffe097          	auipc	ra,0xffffe
    80005174:	4ec080e7          	jalr	1260(ra) # 8000365c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005178:	032b0b63          	beq	s6,s2,800051ae <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000517c:	004a2603          	lw	a2,4(s4)
    80005180:	fb040593          	addi	a1,s0,-80
    80005184:	8526                	mv	a0,s1
    80005186:	fffff097          	auipc	ra,0xfffff
    8000518a:	c96080e7          	jalr	-874(ra) # 80003e1c <dirlink>
    8000518e:	06054f63          	bltz	a0,8000520c <create+0x15a>
  iunlockput(dp);
    80005192:	8526                	mv	a0,s1
    80005194:	ffffe097          	auipc	ra,0xffffe
    80005198:	7f6080e7          	jalr	2038(ra) # 8000398a <iunlockput>
  return ip;
    8000519c:	8ad2                	mv	s5,s4
    8000519e:	b759                	j	80005124 <create+0x72>
    iunlockput(dp);
    800051a0:	8526                	mv	a0,s1
    800051a2:	ffffe097          	auipc	ra,0xffffe
    800051a6:	7e8080e7          	jalr	2024(ra) # 8000398a <iunlockput>
    return 0;
    800051aa:	8ad2                	mv	s5,s4
    800051ac:	bfa5                	j	80005124 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051ae:	004a2603          	lw	a2,4(s4)
    800051b2:	00003597          	auipc	a1,0x3
    800051b6:	5be58593          	addi	a1,a1,1470 # 80008770 <syscalls+0x318>
    800051ba:	8552                	mv	a0,s4
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	c60080e7          	jalr	-928(ra) # 80003e1c <dirlink>
    800051c4:	04054463          	bltz	a0,8000520c <create+0x15a>
    800051c8:	40d0                	lw	a2,4(s1)
    800051ca:	00003597          	auipc	a1,0x3
    800051ce:	5ae58593          	addi	a1,a1,1454 # 80008778 <syscalls+0x320>
    800051d2:	8552                	mv	a0,s4
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	c48080e7          	jalr	-952(ra) # 80003e1c <dirlink>
    800051dc:	02054863          	bltz	a0,8000520c <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800051e0:	004a2603          	lw	a2,4(s4)
    800051e4:	fb040593          	addi	a1,s0,-80
    800051e8:	8526                	mv	a0,s1
    800051ea:	fffff097          	auipc	ra,0xfffff
    800051ee:	c32080e7          	jalr	-974(ra) # 80003e1c <dirlink>
    800051f2:	00054d63          	bltz	a0,8000520c <create+0x15a>
    dp->nlink++;  // for ".."
    800051f6:	04a4d783          	lhu	a5,74(s1)
    800051fa:	2785                	addiw	a5,a5,1
    800051fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005200:	8526                	mv	a0,s1
    80005202:	ffffe097          	auipc	ra,0xffffe
    80005206:	45a080e7          	jalr	1114(ra) # 8000365c <iupdate>
    8000520a:	b761                	j	80005192 <create+0xe0>
  ip->nlink = 0;
    8000520c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005210:	8552                	mv	a0,s4
    80005212:	ffffe097          	auipc	ra,0xffffe
    80005216:	44a080e7          	jalr	1098(ra) # 8000365c <iupdate>
  iunlockput(ip);
    8000521a:	8552                	mv	a0,s4
    8000521c:	ffffe097          	auipc	ra,0xffffe
    80005220:	76e080e7          	jalr	1902(ra) # 8000398a <iunlockput>
  iunlockput(dp);
    80005224:	8526                	mv	a0,s1
    80005226:	ffffe097          	auipc	ra,0xffffe
    8000522a:	764080e7          	jalr	1892(ra) # 8000398a <iunlockput>
  return 0;
    8000522e:	bddd                	j	80005124 <create+0x72>
    return 0;
    80005230:	8aaa                	mv	s5,a0
    80005232:	bdcd                	j	80005124 <create+0x72>

0000000080005234 <sys_dup>:
{
    80005234:	7179                	addi	sp,sp,-48
    80005236:	f406                	sd	ra,40(sp)
    80005238:	f022                	sd	s0,32(sp)
    8000523a:	ec26                	sd	s1,24(sp)
    8000523c:	e84a                	sd	s2,16(sp)
    8000523e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005240:	fd840613          	addi	a2,s0,-40
    80005244:	4581                	li	a1,0
    80005246:	4501                	li	a0,0
    80005248:	00000097          	auipc	ra,0x0
    8000524c:	dc8080e7          	jalr	-568(ra) # 80005010 <argfd>
    return -1;
    80005250:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005252:	02054363          	bltz	a0,80005278 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005256:	fd843903          	ld	s2,-40(s0)
    8000525a:	854a                	mv	a0,s2
    8000525c:	00000097          	auipc	ra,0x0
    80005260:	e14080e7          	jalr	-492(ra) # 80005070 <fdalloc>
    80005264:	84aa                	mv	s1,a0
    return -1;
    80005266:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005268:	00054863          	bltz	a0,80005278 <sys_dup+0x44>
  filedup(f);
    8000526c:	854a                	mv	a0,s2
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	2d2080e7          	jalr	722(ra) # 80004540 <filedup>
  return fd;
    80005276:	87a6                	mv	a5,s1
}
    80005278:	853e                	mv	a0,a5
    8000527a:	70a2                	ld	ra,40(sp)
    8000527c:	7402                	ld	s0,32(sp)
    8000527e:	64e2                	ld	s1,24(sp)
    80005280:	6942                	ld	s2,16(sp)
    80005282:	6145                	addi	sp,sp,48
    80005284:	8082                	ret

0000000080005286 <sys_read>:
{
    80005286:	7179                	addi	sp,sp,-48
    80005288:	f406                	sd	ra,40(sp)
    8000528a:	f022                	sd	s0,32(sp)
    8000528c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000528e:	fd840593          	addi	a1,s0,-40
    80005292:	4505                	li	a0,1
    80005294:	ffffe097          	auipc	ra,0xffffe
    80005298:	952080e7          	jalr	-1710(ra) # 80002be6 <argaddr>
  argint(2, &n);
    8000529c:	fe440593          	addi	a1,s0,-28
    800052a0:	4509                	li	a0,2
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	924080e7          	jalr	-1756(ra) # 80002bc6 <argint>
  if(argfd(0, 0, &f) < 0)
    800052aa:	fe840613          	addi	a2,s0,-24
    800052ae:	4581                	li	a1,0
    800052b0:	4501                	li	a0,0
    800052b2:	00000097          	auipc	ra,0x0
    800052b6:	d5e080e7          	jalr	-674(ra) # 80005010 <argfd>
    800052ba:	87aa                	mv	a5,a0
    return -1;
    800052bc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052be:	0007cc63          	bltz	a5,800052d6 <sys_read+0x50>
  return fileread(f, p, n);
    800052c2:	fe442603          	lw	a2,-28(s0)
    800052c6:	fd843583          	ld	a1,-40(s0)
    800052ca:	fe843503          	ld	a0,-24(s0)
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	3fe080e7          	jalr	1022(ra) # 800046cc <fileread>
}
    800052d6:	70a2                	ld	ra,40(sp)
    800052d8:	7402                	ld	s0,32(sp)
    800052da:	6145                	addi	sp,sp,48
    800052dc:	8082                	ret

00000000800052de <sys_write>:
{
    800052de:	7179                	addi	sp,sp,-48
    800052e0:	f406                	sd	ra,40(sp)
    800052e2:	f022                	sd	s0,32(sp)
    800052e4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052e6:	fd840593          	addi	a1,s0,-40
    800052ea:	4505                	li	a0,1
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	8fa080e7          	jalr	-1798(ra) # 80002be6 <argaddr>
  argint(2, &n);
    800052f4:	fe440593          	addi	a1,s0,-28
    800052f8:	4509                	li	a0,2
    800052fa:	ffffe097          	auipc	ra,0xffffe
    800052fe:	8cc080e7          	jalr	-1844(ra) # 80002bc6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005302:	fe840613          	addi	a2,s0,-24
    80005306:	4581                	li	a1,0
    80005308:	4501                	li	a0,0
    8000530a:	00000097          	auipc	ra,0x0
    8000530e:	d06080e7          	jalr	-762(ra) # 80005010 <argfd>
    80005312:	87aa                	mv	a5,a0
    return -1;
    80005314:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005316:	0007cc63          	bltz	a5,8000532e <sys_write+0x50>
  return filewrite(f, p, n);
    8000531a:	fe442603          	lw	a2,-28(s0)
    8000531e:	fd843583          	ld	a1,-40(s0)
    80005322:	fe843503          	ld	a0,-24(s0)
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	468080e7          	jalr	1128(ra) # 8000478e <filewrite>
}
    8000532e:	70a2                	ld	ra,40(sp)
    80005330:	7402                	ld	s0,32(sp)
    80005332:	6145                	addi	sp,sp,48
    80005334:	8082                	ret

0000000080005336 <sys_close>:
{
    80005336:	1101                	addi	sp,sp,-32
    80005338:	ec06                	sd	ra,24(sp)
    8000533a:	e822                	sd	s0,16(sp)
    8000533c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000533e:	fe040613          	addi	a2,s0,-32
    80005342:	fec40593          	addi	a1,s0,-20
    80005346:	4501                	li	a0,0
    80005348:	00000097          	auipc	ra,0x0
    8000534c:	cc8080e7          	jalr	-824(ra) # 80005010 <argfd>
    return -1;
    80005350:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005352:	02054463          	bltz	a0,8000537a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005356:	ffffc097          	auipc	ra,0xffffc
    8000535a:	6ce080e7          	jalr	1742(ra) # 80001a24 <myproc>
    8000535e:	fec42783          	lw	a5,-20(s0)
    80005362:	07e9                	addi	a5,a5,26
    80005364:	078e                	slli	a5,a5,0x3
    80005366:	953e                	add	a0,a0,a5
    80005368:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000536c:	fe043503          	ld	a0,-32(s0)
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	222080e7          	jalr	546(ra) # 80004592 <fileclose>
  return 0;
    80005378:	4781                	li	a5,0
}
    8000537a:	853e                	mv	a0,a5
    8000537c:	60e2                	ld	ra,24(sp)
    8000537e:	6442                	ld	s0,16(sp)
    80005380:	6105                	addi	sp,sp,32
    80005382:	8082                	ret

0000000080005384 <sys_fstat>:
{
    80005384:	1101                	addi	sp,sp,-32
    80005386:	ec06                	sd	ra,24(sp)
    80005388:	e822                	sd	s0,16(sp)
    8000538a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000538c:	fe040593          	addi	a1,s0,-32
    80005390:	4505                	li	a0,1
    80005392:	ffffe097          	auipc	ra,0xffffe
    80005396:	854080e7          	jalr	-1964(ra) # 80002be6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000539a:	fe840613          	addi	a2,s0,-24
    8000539e:	4581                	li	a1,0
    800053a0:	4501                	li	a0,0
    800053a2:	00000097          	auipc	ra,0x0
    800053a6:	c6e080e7          	jalr	-914(ra) # 80005010 <argfd>
    800053aa:	87aa                	mv	a5,a0
    return -1;
    800053ac:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053ae:	0007ca63          	bltz	a5,800053c2 <sys_fstat+0x3e>
  return filestat(f, st);
    800053b2:	fe043583          	ld	a1,-32(s0)
    800053b6:	fe843503          	ld	a0,-24(s0)
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	2a0080e7          	jalr	672(ra) # 8000465a <filestat>
}
    800053c2:	60e2                	ld	ra,24(sp)
    800053c4:	6442                	ld	s0,16(sp)
    800053c6:	6105                	addi	sp,sp,32
    800053c8:	8082                	ret

00000000800053ca <sys_link>:
{
    800053ca:	7169                	addi	sp,sp,-304
    800053cc:	f606                	sd	ra,296(sp)
    800053ce:	f222                	sd	s0,288(sp)
    800053d0:	ee26                	sd	s1,280(sp)
    800053d2:	ea4a                	sd	s2,272(sp)
    800053d4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053d6:	08000613          	li	a2,128
    800053da:	ed040593          	addi	a1,s0,-304
    800053de:	4501                	li	a0,0
    800053e0:	ffffe097          	auipc	ra,0xffffe
    800053e4:	826080e7          	jalr	-2010(ra) # 80002c06 <argstr>
    return -1;
    800053e8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ea:	10054e63          	bltz	a0,80005506 <sys_link+0x13c>
    800053ee:	08000613          	li	a2,128
    800053f2:	f5040593          	addi	a1,s0,-176
    800053f6:	4505                	li	a0,1
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	80e080e7          	jalr	-2034(ra) # 80002c06 <argstr>
    return -1;
    80005400:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005402:	10054263          	bltz	a0,80005506 <sys_link+0x13c>
  begin_op();
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	cc8080e7          	jalr	-824(ra) # 800040ce <begin_op>
  if((ip = namei(old)) == 0){
    8000540e:	ed040513          	addi	a0,s0,-304
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	abc080e7          	jalr	-1348(ra) # 80003ece <namei>
    8000541a:	84aa                	mv	s1,a0
    8000541c:	c551                	beqz	a0,800054a8 <sys_link+0xde>
  ilock(ip);
    8000541e:	ffffe097          	auipc	ra,0xffffe
    80005422:	30a080e7          	jalr	778(ra) # 80003728 <ilock>
  if(ip->type == T_DIR){
    80005426:	04449703          	lh	a4,68(s1)
    8000542a:	4785                	li	a5,1
    8000542c:	08f70463          	beq	a4,a5,800054b4 <sys_link+0xea>
  ip->nlink++;
    80005430:	04a4d783          	lhu	a5,74(s1)
    80005434:	2785                	addiw	a5,a5,1
    80005436:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000543a:	8526                	mv	a0,s1
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	220080e7          	jalr	544(ra) # 8000365c <iupdate>
  iunlock(ip);
    80005444:	8526                	mv	a0,s1
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	3a4080e7          	jalr	932(ra) # 800037ea <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000544e:	fd040593          	addi	a1,s0,-48
    80005452:	f5040513          	addi	a0,s0,-176
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	a96080e7          	jalr	-1386(ra) # 80003eec <nameiparent>
    8000545e:	892a                	mv	s2,a0
    80005460:	c935                	beqz	a0,800054d4 <sys_link+0x10a>
  ilock(dp);
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	2c6080e7          	jalr	710(ra) # 80003728 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000546a:	00092703          	lw	a4,0(s2)
    8000546e:	409c                	lw	a5,0(s1)
    80005470:	04f71d63          	bne	a4,a5,800054ca <sys_link+0x100>
    80005474:	40d0                	lw	a2,4(s1)
    80005476:	fd040593          	addi	a1,s0,-48
    8000547a:	854a                	mv	a0,s2
    8000547c:	fffff097          	auipc	ra,0xfffff
    80005480:	9a0080e7          	jalr	-1632(ra) # 80003e1c <dirlink>
    80005484:	04054363          	bltz	a0,800054ca <sys_link+0x100>
  iunlockput(dp);
    80005488:	854a                	mv	a0,s2
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	500080e7          	jalr	1280(ra) # 8000398a <iunlockput>
  iput(ip);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	44e080e7          	jalr	1102(ra) # 800038e2 <iput>
  end_op();
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	cac080e7          	jalr	-852(ra) # 80004148 <end_op>
  return 0;
    800054a4:	4781                	li	a5,0
    800054a6:	a085                	j	80005506 <sys_link+0x13c>
    end_op();
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	ca0080e7          	jalr	-864(ra) # 80004148 <end_op>
    return -1;
    800054b0:	57fd                	li	a5,-1
    800054b2:	a891                	j	80005506 <sys_link+0x13c>
    iunlockput(ip);
    800054b4:	8526                	mv	a0,s1
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	4d4080e7          	jalr	1236(ra) # 8000398a <iunlockput>
    end_op();
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	c8a080e7          	jalr	-886(ra) # 80004148 <end_op>
    return -1;
    800054c6:	57fd                	li	a5,-1
    800054c8:	a83d                	j	80005506 <sys_link+0x13c>
    iunlockput(dp);
    800054ca:	854a                	mv	a0,s2
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	4be080e7          	jalr	1214(ra) # 8000398a <iunlockput>
  ilock(ip);
    800054d4:	8526                	mv	a0,s1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	252080e7          	jalr	594(ra) # 80003728 <ilock>
  ip->nlink--;
    800054de:	04a4d783          	lhu	a5,74(s1)
    800054e2:	37fd                	addiw	a5,a5,-1
    800054e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	172080e7          	jalr	370(ra) # 8000365c <iupdate>
  iunlockput(ip);
    800054f2:	8526                	mv	a0,s1
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	496080e7          	jalr	1174(ra) # 8000398a <iunlockput>
  end_op();
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	c4c080e7          	jalr	-948(ra) # 80004148 <end_op>
  return -1;
    80005504:	57fd                	li	a5,-1
}
    80005506:	853e                	mv	a0,a5
    80005508:	70b2                	ld	ra,296(sp)
    8000550a:	7412                	ld	s0,288(sp)
    8000550c:	64f2                	ld	s1,280(sp)
    8000550e:	6952                	ld	s2,272(sp)
    80005510:	6155                	addi	sp,sp,304
    80005512:	8082                	ret

0000000080005514 <sys_unlink>:
{
    80005514:	7151                	addi	sp,sp,-240
    80005516:	f586                	sd	ra,232(sp)
    80005518:	f1a2                	sd	s0,224(sp)
    8000551a:	eda6                	sd	s1,216(sp)
    8000551c:	e9ca                	sd	s2,208(sp)
    8000551e:	e5ce                	sd	s3,200(sp)
    80005520:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005522:	08000613          	li	a2,128
    80005526:	f3040593          	addi	a1,s0,-208
    8000552a:	4501                	li	a0,0
    8000552c:	ffffd097          	auipc	ra,0xffffd
    80005530:	6da080e7          	jalr	1754(ra) # 80002c06 <argstr>
    80005534:	18054163          	bltz	a0,800056b6 <sys_unlink+0x1a2>
  begin_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	b96080e7          	jalr	-1130(ra) # 800040ce <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005540:	fb040593          	addi	a1,s0,-80
    80005544:	f3040513          	addi	a0,s0,-208
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	9a4080e7          	jalr	-1628(ra) # 80003eec <nameiparent>
    80005550:	84aa                	mv	s1,a0
    80005552:	c979                	beqz	a0,80005628 <sys_unlink+0x114>
  ilock(dp);
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	1d4080e7          	jalr	468(ra) # 80003728 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000555c:	00003597          	auipc	a1,0x3
    80005560:	21458593          	addi	a1,a1,532 # 80008770 <syscalls+0x318>
    80005564:	fb040513          	addi	a0,s0,-80
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	68a080e7          	jalr	1674(ra) # 80003bf2 <namecmp>
    80005570:	14050a63          	beqz	a0,800056c4 <sys_unlink+0x1b0>
    80005574:	00003597          	auipc	a1,0x3
    80005578:	20458593          	addi	a1,a1,516 # 80008778 <syscalls+0x320>
    8000557c:	fb040513          	addi	a0,s0,-80
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	672080e7          	jalr	1650(ra) # 80003bf2 <namecmp>
    80005588:	12050e63          	beqz	a0,800056c4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000558c:	f2c40613          	addi	a2,s0,-212
    80005590:	fb040593          	addi	a1,s0,-80
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	676080e7          	jalr	1654(ra) # 80003c0c <dirlookup>
    8000559e:	892a                	mv	s2,a0
    800055a0:	12050263          	beqz	a0,800056c4 <sys_unlink+0x1b0>
  ilock(ip);
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	184080e7          	jalr	388(ra) # 80003728 <ilock>
  if(ip->nlink < 1)
    800055ac:	04a91783          	lh	a5,74(s2)
    800055b0:	08f05263          	blez	a5,80005634 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055b4:	04491703          	lh	a4,68(s2)
    800055b8:	4785                	li	a5,1
    800055ba:	08f70563          	beq	a4,a5,80005644 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055be:	4641                	li	a2,16
    800055c0:	4581                	li	a1,0
    800055c2:	fc040513          	addi	a0,s0,-64
    800055c6:	ffffb097          	auipc	ra,0xffffb
    800055ca:	77e080e7          	jalr	1918(ra) # 80000d44 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ce:	4741                	li	a4,16
    800055d0:	f2c42683          	lw	a3,-212(s0)
    800055d4:	fc040613          	addi	a2,s0,-64
    800055d8:	4581                	li	a1,0
    800055da:	8526                	mv	a0,s1
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	4f8080e7          	jalr	1272(ra) # 80003ad4 <writei>
    800055e4:	47c1                	li	a5,16
    800055e6:	0af51563          	bne	a0,a5,80005690 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055ea:	04491703          	lh	a4,68(s2)
    800055ee:	4785                	li	a5,1
    800055f0:	0af70863          	beq	a4,a5,800056a0 <sys_unlink+0x18c>
  iunlockput(dp);
    800055f4:	8526                	mv	a0,s1
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	394080e7          	jalr	916(ra) # 8000398a <iunlockput>
  ip->nlink--;
    800055fe:	04a95783          	lhu	a5,74(s2)
    80005602:	37fd                	addiw	a5,a5,-1
    80005604:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005608:	854a                	mv	a0,s2
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	052080e7          	jalr	82(ra) # 8000365c <iupdate>
  iunlockput(ip);
    80005612:	854a                	mv	a0,s2
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	376080e7          	jalr	886(ra) # 8000398a <iunlockput>
  end_op();
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	b2c080e7          	jalr	-1236(ra) # 80004148 <end_op>
  return 0;
    80005624:	4501                	li	a0,0
    80005626:	a84d                	j	800056d8 <sys_unlink+0x1c4>
    end_op();
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	b20080e7          	jalr	-1248(ra) # 80004148 <end_op>
    return -1;
    80005630:	557d                	li	a0,-1
    80005632:	a05d                	j	800056d8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005634:	00003517          	auipc	a0,0x3
    80005638:	14c50513          	addi	a0,a0,332 # 80008780 <syscalls+0x328>
    8000563c:	ffffb097          	auipc	ra,0xffffb
    80005640:	f04080e7          	jalr	-252(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005644:	04c92703          	lw	a4,76(s2)
    80005648:	02000793          	li	a5,32
    8000564c:	f6e7f9e3          	bgeu	a5,a4,800055be <sys_unlink+0xaa>
    80005650:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005654:	4741                	li	a4,16
    80005656:	86ce                	mv	a3,s3
    80005658:	f1840613          	addi	a2,s0,-232
    8000565c:	4581                	li	a1,0
    8000565e:	854a                	mv	a0,s2
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	37c080e7          	jalr	892(ra) # 800039dc <readi>
    80005668:	47c1                	li	a5,16
    8000566a:	00f51b63          	bne	a0,a5,80005680 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000566e:	f1845783          	lhu	a5,-232(s0)
    80005672:	e7a1                	bnez	a5,800056ba <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005674:	29c1                	addiw	s3,s3,16
    80005676:	04c92783          	lw	a5,76(s2)
    8000567a:	fcf9ede3          	bltu	s3,a5,80005654 <sys_unlink+0x140>
    8000567e:	b781                	j	800055be <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005680:	00003517          	auipc	a0,0x3
    80005684:	11850513          	addi	a0,a0,280 # 80008798 <syscalls+0x340>
    80005688:	ffffb097          	auipc	ra,0xffffb
    8000568c:	eb8080e7          	jalr	-328(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005690:	00003517          	auipc	a0,0x3
    80005694:	12050513          	addi	a0,a0,288 # 800087b0 <syscalls+0x358>
    80005698:	ffffb097          	auipc	ra,0xffffb
    8000569c:	ea8080e7          	jalr	-344(ra) # 80000540 <panic>
    dp->nlink--;
    800056a0:	04a4d783          	lhu	a5,74(s1)
    800056a4:	37fd                	addiw	a5,a5,-1
    800056a6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056aa:	8526                	mv	a0,s1
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	fb0080e7          	jalr	-80(ra) # 8000365c <iupdate>
    800056b4:	b781                	j	800055f4 <sys_unlink+0xe0>
    return -1;
    800056b6:	557d                	li	a0,-1
    800056b8:	a005                	j	800056d8 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056ba:	854a                	mv	a0,s2
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	2ce080e7          	jalr	718(ra) # 8000398a <iunlockput>
  iunlockput(dp);
    800056c4:	8526                	mv	a0,s1
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	2c4080e7          	jalr	708(ra) # 8000398a <iunlockput>
  end_op();
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	a7a080e7          	jalr	-1414(ra) # 80004148 <end_op>
  return -1;
    800056d6:	557d                	li	a0,-1
}
    800056d8:	70ae                	ld	ra,232(sp)
    800056da:	740e                	ld	s0,224(sp)
    800056dc:	64ee                	ld	s1,216(sp)
    800056de:	694e                	ld	s2,208(sp)
    800056e0:	69ae                	ld	s3,200(sp)
    800056e2:	616d                	addi	sp,sp,240
    800056e4:	8082                	ret

00000000800056e6 <sys_open>:

uint64
sys_open(void)
{
    800056e6:	7131                	addi	sp,sp,-192
    800056e8:	fd06                	sd	ra,184(sp)
    800056ea:	f922                	sd	s0,176(sp)
    800056ec:	f526                	sd	s1,168(sp)
    800056ee:	f14a                	sd	s2,160(sp)
    800056f0:	ed4e                	sd	s3,152(sp)
    800056f2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800056f4:	f4c40593          	addi	a1,s0,-180
    800056f8:	4505                	li	a0,1
    800056fa:	ffffd097          	auipc	ra,0xffffd
    800056fe:	4cc080e7          	jalr	1228(ra) # 80002bc6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005702:	08000613          	li	a2,128
    80005706:	f5040593          	addi	a1,s0,-176
    8000570a:	4501                	li	a0,0
    8000570c:	ffffd097          	auipc	ra,0xffffd
    80005710:	4fa080e7          	jalr	1274(ra) # 80002c06 <argstr>
    80005714:	87aa                	mv	a5,a0
    return -1;
    80005716:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005718:	0a07c863          	bltz	a5,800057c8 <sys_open+0xe2>

  begin_op();
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	9b2080e7          	jalr	-1614(ra) # 800040ce <begin_op>

  if(omode & O_CREATE){
    80005724:	f4c42783          	lw	a5,-180(s0)
    80005728:	2007f793          	andi	a5,a5,512
    8000572c:	cbdd                	beqz	a5,800057e2 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    8000572e:	4681                	li	a3,0
    80005730:	4601                	li	a2,0
    80005732:	4589                	li	a1,2
    80005734:	f5040513          	addi	a0,s0,-176
    80005738:	00000097          	auipc	ra,0x0
    8000573c:	97a080e7          	jalr	-1670(ra) # 800050b2 <create>
    80005740:	84aa                	mv	s1,a0
    if(ip == 0){
    80005742:	c951                	beqz	a0,800057d6 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005744:	04449703          	lh	a4,68(s1)
    80005748:	478d                	li	a5,3
    8000574a:	00f71763          	bne	a4,a5,80005758 <sys_open+0x72>
    8000574e:	0464d703          	lhu	a4,70(s1)
    80005752:	47a5                	li	a5,9
    80005754:	0ce7ec63          	bltu	a5,a4,8000582c <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005758:	fffff097          	auipc	ra,0xfffff
    8000575c:	d7e080e7          	jalr	-642(ra) # 800044d6 <filealloc>
    80005760:	892a                	mv	s2,a0
    80005762:	c56d                	beqz	a0,8000584c <sys_open+0x166>
    80005764:	00000097          	auipc	ra,0x0
    80005768:	90c080e7          	jalr	-1780(ra) # 80005070 <fdalloc>
    8000576c:	89aa                	mv	s3,a0
    8000576e:	0c054a63          	bltz	a0,80005842 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005772:	04449703          	lh	a4,68(s1)
    80005776:	478d                	li	a5,3
    80005778:	0ef70563          	beq	a4,a5,80005862 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000577c:	4789                	li	a5,2
    8000577e:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005782:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005786:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    8000578a:	f4c42783          	lw	a5,-180(s0)
    8000578e:	0017c713          	xori	a4,a5,1
    80005792:	8b05                	andi	a4,a4,1
    80005794:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005798:	0037f713          	andi	a4,a5,3
    8000579c:	00e03733          	snez	a4,a4
    800057a0:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057a4:	4007f793          	andi	a5,a5,1024
    800057a8:	c791                	beqz	a5,800057b4 <sys_open+0xce>
    800057aa:	04449703          	lh	a4,68(s1)
    800057ae:	4789                	li	a5,2
    800057b0:	0cf70063          	beq	a4,a5,80005870 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    800057b4:	8526                	mv	a0,s1
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	034080e7          	jalr	52(ra) # 800037ea <iunlock>
  end_op();
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	98a080e7          	jalr	-1654(ra) # 80004148 <end_op>

  return fd;
    800057c6:	854e                	mv	a0,s3
}
    800057c8:	70ea                	ld	ra,184(sp)
    800057ca:	744a                	ld	s0,176(sp)
    800057cc:	74aa                	ld	s1,168(sp)
    800057ce:	790a                	ld	s2,160(sp)
    800057d0:	69ea                	ld	s3,152(sp)
    800057d2:	6129                	addi	sp,sp,192
    800057d4:	8082                	ret
      end_op();
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	972080e7          	jalr	-1678(ra) # 80004148 <end_op>
      return -1;
    800057de:	557d                	li	a0,-1
    800057e0:	b7e5                	j	800057c8 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800057e2:	f5040513          	addi	a0,s0,-176
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	6e8080e7          	jalr	1768(ra) # 80003ece <namei>
    800057ee:	84aa                	mv	s1,a0
    800057f0:	c905                	beqz	a0,80005820 <sys_open+0x13a>
    ilock(ip);
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	f36080e7          	jalr	-202(ra) # 80003728 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057fa:	04449703          	lh	a4,68(s1)
    800057fe:	4785                	li	a5,1
    80005800:	f4f712e3          	bne	a4,a5,80005744 <sys_open+0x5e>
    80005804:	f4c42783          	lw	a5,-180(s0)
    80005808:	dba1                	beqz	a5,80005758 <sys_open+0x72>
      iunlockput(ip);
    8000580a:	8526                	mv	a0,s1
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	17e080e7          	jalr	382(ra) # 8000398a <iunlockput>
      end_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	934080e7          	jalr	-1740(ra) # 80004148 <end_op>
      return -1;
    8000581c:	557d                	li	a0,-1
    8000581e:	b76d                	j	800057c8 <sys_open+0xe2>
      end_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	928080e7          	jalr	-1752(ra) # 80004148 <end_op>
      return -1;
    80005828:	557d                	li	a0,-1
    8000582a:	bf79                	j	800057c8 <sys_open+0xe2>
    iunlockput(ip);
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	15c080e7          	jalr	348(ra) # 8000398a <iunlockput>
    end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	912080e7          	jalr	-1774(ra) # 80004148 <end_op>
    return -1;
    8000583e:	557d                	li	a0,-1
    80005840:	b761                	j	800057c8 <sys_open+0xe2>
      fileclose(f);
    80005842:	854a                	mv	a0,s2
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	d4e080e7          	jalr	-690(ra) # 80004592 <fileclose>
    iunlockput(ip);
    8000584c:	8526                	mv	a0,s1
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	13c080e7          	jalr	316(ra) # 8000398a <iunlockput>
    end_op();
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	8f2080e7          	jalr	-1806(ra) # 80004148 <end_op>
    return -1;
    8000585e:	557d                	li	a0,-1
    80005860:	b7a5                	j	800057c8 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005862:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005866:	04649783          	lh	a5,70(s1)
    8000586a:	02f91223          	sh	a5,36(s2)
    8000586e:	bf21                	j	80005786 <sys_open+0xa0>
    itrunc(ip);
    80005870:	8526                	mv	a0,s1
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	fc4080e7          	jalr	-60(ra) # 80003836 <itrunc>
    8000587a:	bf2d                	j	800057b4 <sys_open+0xce>

000000008000587c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000587c:	7175                	addi	sp,sp,-144
    8000587e:	e506                	sd	ra,136(sp)
    80005880:	e122                	sd	s0,128(sp)
    80005882:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	84a080e7          	jalr	-1974(ra) # 800040ce <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000588c:	08000613          	li	a2,128
    80005890:	f7040593          	addi	a1,s0,-144
    80005894:	4501                	li	a0,0
    80005896:	ffffd097          	auipc	ra,0xffffd
    8000589a:	370080e7          	jalr	880(ra) # 80002c06 <argstr>
    8000589e:	02054963          	bltz	a0,800058d0 <sys_mkdir+0x54>
    800058a2:	4681                	li	a3,0
    800058a4:	4601                	li	a2,0
    800058a6:	4585                	li	a1,1
    800058a8:	f7040513          	addi	a0,s0,-144
    800058ac:	00000097          	auipc	ra,0x0
    800058b0:	806080e7          	jalr	-2042(ra) # 800050b2 <create>
    800058b4:	cd11                	beqz	a0,800058d0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	0d4080e7          	jalr	212(ra) # 8000398a <iunlockput>
  end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	88a080e7          	jalr	-1910(ra) # 80004148 <end_op>
  return 0;
    800058c6:	4501                	li	a0,0
}
    800058c8:	60aa                	ld	ra,136(sp)
    800058ca:	640a                	ld	s0,128(sp)
    800058cc:	6149                	addi	sp,sp,144
    800058ce:	8082                	ret
    end_op();
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	878080e7          	jalr	-1928(ra) # 80004148 <end_op>
    return -1;
    800058d8:	557d                	li	a0,-1
    800058da:	b7fd                	j	800058c8 <sys_mkdir+0x4c>

00000000800058dc <sys_mknod>:

uint64
sys_mknod(void)
{
    800058dc:	7135                	addi	sp,sp,-160
    800058de:	ed06                	sd	ra,152(sp)
    800058e0:	e922                	sd	s0,144(sp)
    800058e2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	7ea080e7          	jalr	2026(ra) # 800040ce <begin_op>
  argint(1, &major);
    800058ec:	f6c40593          	addi	a1,s0,-148
    800058f0:	4505                	li	a0,1
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	2d4080e7          	jalr	724(ra) # 80002bc6 <argint>
  argint(2, &minor);
    800058fa:	f6840593          	addi	a1,s0,-152
    800058fe:	4509                	li	a0,2
    80005900:	ffffd097          	auipc	ra,0xffffd
    80005904:	2c6080e7          	jalr	710(ra) # 80002bc6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005908:	08000613          	li	a2,128
    8000590c:	f7040593          	addi	a1,s0,-144
    80005910:	4501                	li	a0,0
    80005912:	ffffd097          	auipc	ra,0xffffd
    80005916:	2f4080e7          	jalr	756(ra) # 80002c06 <argstr>
    8000591a:	02054b63          	bltz	a0,80005950 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000591e:	f6841683          	lh	a3,-152(s0)
    80005922:	f6c41603          	lh	a2,-148(s0)
    80005926:	458d                	li	a1,3
    80005928:	f7040513          	addi	a0,s0,-144
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	786080e7          	jalr	1926(ra) # 800050b2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005934:	cd11                	beqz	a0,80005950 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	054080e7          	jalr	84(ra) # 8000398a <iunlockput>
  end_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	80a080e7          	jalr	-2038(ra) # 80004148 <end_op>
  return 0;
    80005946:	4501                	li	a0,0
}
    80005948:	60ea                	ld	ra,152(sp)
    8000594a:	644a                	ld	s0,144(sp)
    8000594c:	610d                	addi	sp,sp,160
    8000594e:	8082                	ret
    end_op();
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	7f8080e7          	jalr	2040(ra) # 80004148 <end_op>
    return -1;
    80005958:	557d                	li	a0,-1
    8000595a:	b7fd                	j	80005948 <sys_mknod+0x6c>

000000008000595c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000595c:	7135                	addi	sp,sp,-160
    8000595e:	ed06                	sd	ra,152(sp)
    80005960:	e922                	sd	s0,144(sp)
    80005962:	e526                	sd	s1,136(sp)
    80005964:	e14a                	sd	s2,128(sp)
    80005966:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005968:	ffffc097          	auipc	ra,0xffffc
    8000596c:	0bc080e7          	jalr	188(ra) # 80001a24 <myproc>
    80005970:	892a                	mv	s2,a0
  
  begin_op();
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	75c080e7          	jalr	1884(ra) # 800040ce <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000597a:	08000613          	li	a2,128
    8000597e:	f6040593          	addi	a1,s0,-160
    80005982:	4501                	li	a0,0
    80005984:	ffffd097          	auipc	ra,0xffffd
    80005988:	282080e7          	jalr	642(ra) # 80002c06 <argstr>
    8000598c:	04054b63          	bltz	a0,800059e2 <sys_chdir+0x86>
    80005990:	f6040513          	addi	a0,s0,-160
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	53a080e7          	jalr	1338(ra) # 80003ece <namei>
    8000599c:	84aa                	mv	s1,a0
    8000599e:	c131                	beqz	a0,800059e2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	d88080e7          	jalr	-632(ra) # 80003728 <ilock>
  if(ip->type != T_DIR){
    800059a8:	04449703          	lh	a4,68(s1)
    800059ac:	4785                	li	a5,1
    800059ae:	04f71063          	bne	a4,a5,800059ee <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059b2:	8526                	mv	a0,s1
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	e36080e7          	jalr	-458(ra) # 800037ea <iunlock>
  iput(p->cwd);
    800059bc:	15093503          	ld	a0,336(s2)
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	f22080e7          	jalr	-222(ra) # 800038e2 <iput>
  end_op();
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	780080e7          	jalr	1920(ra) # 80004148 <end_op>
  p->cwd = ip;
    800059d0:	14993823          	sd	s1,336(s2)
  return 0;
    800059d4:	4501                	li	a0,0
}
    800059d6:	60ea                	ld	ra,152(sp)
    800059d8:	644a                	ld	s0,144(sp)
    800059da:	64aa                	ld	s1,136(sp)
    800059dc:	690a                	ld	s2,128(sp)
    800059de:	610d                	addi	sp,sp,160
    800059e0:	8082                	ret
    end_op();
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	766080e7          	jalr	1894(ra) # 80004148 <end_op>
    return -1;
    800059ea:	557d                	li	a0,-1
    800059ec:	b7ed                	j	800059d6 <sys_chdir+0x7a>
    iunlockput(ip);
    800059ee:	8526                	mv	a0,s1
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	f9a080e7          	jalr	-102(ra) # 8000398a <iunlockput>
    end_op();
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	750080e7          	jalr	1872(ra) # 80004148 <end_op>
    return -1;
    80005a00:	557d                	li	a0,-1
    80005a02:	bfd1                	j	800059d6 <sys_chdir+0x7a>

0000000080005a04 <sys_exec>:

uint64
sys_exec(void)
{
    80005a04:	7121                	addi	sp,sp,-448
    80005a06:	ff06                	sd	ra,440(sp)
    80005a08:	fb22                	sd	s0,432(sp)
    80005a0a:	f726                	sd	s1,424(sp)
    80005a0c:	f34a                	sd	s2,416(sp)
    80005a0e:	ef4e                	sd	s3,408(sp)
    80005a10:	eb52                	sd	s4,400(sp)
    80005a12:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a14:	e4840593          	addi	a1,s0,-440
    80005a18:	4505                	li	a0,1
    80005a1a:	ffffd097          	auipc	ra,0xffffd
    80005a1e:	1cc080e7          	jalr	460(ra) # 80002be6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a22:	08000613          	li	a2,128
    80005a26:	f5040593          	addi	a1,s0,-176
    80005a2a:	4501                	li	a0,0
    80005a2c:	ffffd097          	auipc	ra,0xffffd
    80005a30:	1da080e7          	jalr	474(ra) # 80002c06 <argstr>
    80005a34:	87aa                	mv	a5,a0
    return -1;
    80005a36:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a38:	0c07c263          	bltz	a5,80005afc <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005a3c:	10000613          	li	a2,256
    80005a40:	4581                	li	a1,0
    80005a42:	e5040513          	addi	a0,s0,-432
    80005a46:	ffffb097          	auipc	ra,0xffffb
    80005a4a:	2fe080e7          	jalr	766(ra) # 80000d44 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a4e:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005a52:	89a6                	mv	s3,s1
    80005a54:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a56:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a5a:	00391513          	slli	a0,s2,0x3
    80005a5e:	e4040593          	addi	a1,s0,-448
    80005a62:	e4843783          	ld	a5,-440(s0)
    80005a66:	953e                	add	a0,a0,a5
    80005a68:	ffffd097          	auipc	ra,0xffffd
    80005a6c:	0c0080e7          	jalr	192(ra) # 80002b28 <fetchaddr>
    80005a70:	02054a63          	bltz	a0,80005aa4 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005a74:	e4043783          	ld	a5,-448(s0)
    80005a78:	c3b9                	beqz	a5,80005abe <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a7a:	ffffb097          	auipc	ra,0xffffb
    80005a7e:	0de080e7          	jalr	222(ra) # 80000b58 <kalloc>
    80005a82:	85aa                	mv	a1,a0
    80005a84:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a88:	cd11                	beqz	a0,80005aa4 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a8a:	6605                	lui	a2,0x1
    80005a8c:	e4043503          	ld	a0,-448(s0)
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	0ea080e7          	jalr	234(ra) # 80002b7a <fetchstr>
    80005a98:	00054663          	bltz	a0,80005aa4 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005a9c:	0905                	addi	s2,s2,1
    80005a9e:	09a1                	addi	s3,s3,8
    80005aa0:	fb491de3          	bne	s2,s4,80005a5a <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa4:	f5040913          	addi	s2,s0,-176
    80005aa8:	6088                	ld	a0,0(s1)
    80005aaa:	c921                	beqz	a0,80005afa <sys_exec+0xf6>
    kfree(argv[i]);
    80005aac:	ffffb097          	auipc	ra,0xffffb
    80005ab0:	fae080e7          	jalr	-82(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab4:	04a1                	addi	s1,s1,8
    80005ab6:	ff2499e3          	bne	s1,s2,80005aa8 <sys_exec+0xa4>
  return -1;
    80005aba:	557d                	li	a0,-1
    80005abc:	a081                	j	80005afc <sys_exec+0xf8>
      argv[i] = 0;
    80005abe:	0009079b          	sext.w	a5,s2
    80005ac2:	078e                	slli	a5,a5,0x3
    80005ac4:	fd078793          	addi	a5,a5,-48
    80005ac8:	97a2                	add	a5,a5,s0
    80005aca:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005ace:	e5040593          	addi	a1,s0,-432
    80005ad2:	f5040513          	addi	a0,s0,-176
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	132080e7          	jalr	306(ra) # 80004c08 <exec>
    80005ade:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae0:	f5040993          	addi	s3,s0,-176
    80005ae4:	6088                	ld	a0,0(s1)
    80005ae6:	c901                	beqz	a0,80005af6 <sys_exec+0xf2>
    kfree(argv[i]);
    80005ae8:	ffffb097          	auipc	ra,0xffffb
    80005aec:	f72080e7          	jalr	-142(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af0:	04a1                	addi	s1,s1,8
    80005af2:	ff3499e3          	bne	s1,s3,80005ae4 <sys_exec+0xe0>
  return ret;
    80005af6:	854a                	mv	a0,s2
    80005af8:	a011                	j	80005afc <sys_exec+0xf8>
  return -1;
    80005afa:	557d                	li	a0,-1
}
    80005afc:	70fa                	ld	ra,440(sp)
    80005afe:	745a                	ld	s0,432(sp)
    80005b00:	74ba                	ld	s1,424(sp)
    80005b02:	791a                	ld	s2,416(sp)
    80005b04:	69fa                	ld	s3,408(sp)
    80005b06:	6a5a                	ld	s4,400(sp)
    80005b08:	6139                	addi	sp,sp,448
    80005b0a:	8082                	ret

0000000080005b0c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b0c:	7139                	addi	sp,sp,-64
    80005b0e:	fc06                	sd	ra,56(sp)
    80005b10:	f822                	sd	s0,48(sp)
    80005b12:	f426                	sd	s1,40(sp)
    80005b14:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b16:	ffffc097          	auipc	ra,0xffffc
    80005b1a:	f0e080e7          	jalr	-242(ra) # 80001a24 <myproc>
    80005b1e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b20:	fd840593          	addi	a1,s0,-40
    80005b24:	4501                	li	a0,0
    80005b26:	ffffd097          	auipc	ra,0xffffd
    80005b2a:	0c0080e7          	jalr	192(ra) # 80002be6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b2e:	fc840593          	addi	a1,s0,-56
    80005b32:	fd040513          	addi	a0,s0,-48
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	d88080e7          	jalr	-632(ra) # 800048be <pipealloc>
    return -1;
    80005b3e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b40:	0c054463          	bltz	a0,80005c08 <sys_pipe+0xfc>
  fd0 = -1;
    80005b44:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b48:	fd043503          	ld	a0,-48(s0)
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	524080e7          	jalr	1316(ra) # 80005070 <fdalloc>
    80005b54:	fca42223          	sw	a0,-60(s0)
    80005b58:	08054b63          	bltz	a0,80005bee <sys_pipe+0xe2>
    80005b5c:	fc843503          	ld	a0,-56(s0)
    80005b60:	fffff097          	auipc	ra,0xfffff
    80005b64:	510080e7          	jalr	1296(ra) # 80005070 <fdalloc>
    80005b68:	fca42023          	sw	a0,-64(s0)
    80005b6c:	06054863          	bltz	a0,80005bdc <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b70:	4691                	li	a3,4
    80005b72:	fc440613          	addi	a2,s0,-60
    80005b76:	fd843583          	ld	a1,-40(s0)
    80005b7a:	68a8                	ld	a0,80(s1)
    80005b7c:	ffffc097          	auipc	ra,0xffffc
    80005b80:	b68080e7          	jalr	-1176(ra) # 800016e4 <copyout>
    80005b84:	02054063          	bltz	a0,80005ba4 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b88:	4691                	li	a3,4
    80005b8a:	fc040613          	addi	a2,s0,-64
    80005b8e:	fd843583          	ld	a1,-40(s0)
    80005b92:	0591                	addi	a1,a1,4
    80005b94:	68a8                	ld	a0,80(s1)
    80005b96:	ffffc097          	auipc	ra,0xffffc
    80005b9a:	b4e080e7          	jalr	-1202(ra) # 800016e4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b9e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ba0:	06055463          	bgez	a0,80005c08 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005ba4:	fc442783          	lw	a5,-60(s0)
    80005ba8:	07e9                	addi	a5,a5,26
    80005baa:	078e                	slli	a5,a5,0x3
    80005bac:	97a6                	add	a5,a5,s1
    80005bae:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bb2:	fc042783          	lw	a5,-64(s0)
    80005bb6:	07e9                	addi	a5,a5,26
    80005bb8:	078e                	slli	a5,a5,0x3
    80005bba:	94be                	add	s1,s1,a5
    80005bbc:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bc0:	fd043503          	ld	a0,-48(s0)
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	9ce080e7          	jalr	-1586(ra) # 80004592 <fileclose>
    fileclose(wf);
    80005bcc:	fc843503          	ld	a0,-56(s0)
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	9c2080e7          	jalr	-1598(ra) # 80004592 <fileclose>
    return -1;
    80005bd8:	57fd                	li	a5,-1
    80005bda:	a03d                	j	80005c08 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005bdc:	fc442783          	lw	a5,-60(s0)
    80005be0:	0007c763          	bltz	a5,80005bee <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005be4:	07e9                	addi	a5,a5,26
    80005be6:	078e                	slli	a5,a5,0x3
    80005be8:	97a6                	add	a5,a5,s1
    80005bea:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005bee:	fd043503          	ld	a0,-48(s0)
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	9a0080e7          	jalr	-1632(ra) # 80004592 <fileclose>
    fileclose(wf);
    80005bfa:	fc843503          	ld	a0,-56(s0)
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	994080e7          	jalr	-1644(ra) # 80004592 <fileclose>
    return -1;
    80005c06:	57fd                	li	a5,-1
}
    80005c08:	853e                	mv	a0,a5
    80005c0a:	70e2                	ld	ra,56(sp)
    80005c0c:	7442                	ld	s0,48(sp)
    80005c0e:	74a2                	ld	s1,40(sp)
    80005c10:	6121                	addi	sp,sp,64
    80005c12:	8082                	ret
	...

0000000080005c20 <kernelvec>:
    80005c20:	7111                	addi	sp,sp,-256
    80005c22:	e006                	sd	ra,0(sp)
    80005c24:	e40a                	sd	sp,8(sp)
    80005c26:	e80e                	sd	gp,16(sp)
    80005c28:	ec12                	sd	tp,24(sp)
    80005c2a:	f016                	sd	t0,32(sp)
    80005c2c:	f41a                	sd	t1,40(sp)
    80005c2e:	f81e                	sd	t2,48(sp)
    80005c30:	fc22                	sd	s0,56(sp)
    80005c32:	e0a6                	sd	s1,64(sp)
    80005c34:	e4aa                	sd	a0,72(sp)
    80005c36:	e8ae                	sd	a1,80(sp)
    80005c38:	ecb2                	sd	a2,88(sp)
    80005c3a:	f0b6                	sd	a3,96(sp)
    80005c3c:	f4ba                	sd	a4,104(sp)
    80005c3e:	f8be                	sd	a5,112(sp)
    80005c40:	fcc2                	sd	a6,120(sp)
    80005c42:	e146                	sd	a7,128(sp)
    80005c44:	e54a                	sd	s2,136(sp)
    80005c46:	e94e                	sd	s3,144(sp)
    80005c48:	ed52                	sd	s4,152(sp)
    80005c4a:	f156                	sd	s5,160(sp)
    80005c4c:	f55a                	sd	s6,168(sp)
    80005c4e:	f95e                	sd	s7,176(sp)
    80005c50:	fd62                	sd	s8,184(sp)
    80005c52:	e1e6                	sd	s9,192(sp)
    80005c54:	e5ea                	sd	s10,200(sp)
    80005c56:	e9ee                	sd	s11,208(sp)
    80005c58:	edf2                	sd	t3,216(sp)
    80005c5a:	f1f6                	sd	t4,224(sp)
    80005c5c:	f5fa                	sd	t5,232(sp)
    80005c5e:	f9fe                	sd	t6,240(sp)
    80005c60:	d95fc0ef          	jal	ra,800029f4 <kerneltrap>
    80005c64:	6082                	ld	ra,0(sp)
    80005c66:	6122                	ld	sp,8(sp)
    80005c68:	61c2                	ld	gp,16(sp)
    80005c6a:	7282                	ld	t0,32(sp)
    80005c6c:	7322                	ld	t1,40(sp)
    80005c6e:	73c2                	ld	t2,48(sp)
    80005c70:	7462                	ld	s0,56(sp)
    80005c72:	6486                	ld	s1,64(sp)
    80005c74:	6526                	ld	a0,72(sp)
    80005c76:	65c6                	ld	a1,80(sp)
    80005c78:	6666                	ld	a2,88(sp)
    80005c7a:	7686                	ld	a3,96(sp)
    80005c7c:	7726                	ld	a4,104(sp)
    80005c7e:	77c6                	ld	a5,112(sp)
    80005c80:	7866                	ld	a6,120(sp)
    80005c82:	688a                	ld	a7,128(sp)
    80005c84:	692a                	ld	s2,136(sp)
    80005c86:	69ca                	ld	s3,144(sp)
    80005c88:	6a6a                	ld	s4,152(sp)
    80005c8a:	7a8a                	ld	s5,160(sp)
    80005c8c:	7b2a                	ld	s6,168(sp)
    80005c8e:	7bca                	ld	s7,176(sp)
    80005c90:	7c6a                	ld	s8,184(sp)
    80005c92:	6c8e                	ld	s9,192(sp)
    80005c94:	6d2e                	ld	s10,200(sp)
    80005c96:	6dce                	ld	s11,208(sp)
    80005c98:	6e6e                	ld	t3,216(sp)
    80005c9a:	7e8e                	ld	t4,224(sp)
    80005c9c:	7f2e                	ld	t5,232(sp)
    80005c9e:	7fce                	ld	t6,240(sp)
    80005ca0:	6111                	addi	sp,sp,256
    80005ca2:	10200073          	sret
    80005ca6:	00000013          	nop
    80005caa:	00000013          	nop
    80005cae:	0001                	nop

0000000080005cb0 <timervec>:
    80005cb0:	34051573          	csrrw	a0,mscratch,a0
    80005cb4:	e10c                	sd	a1,0(a0)
    80005cb6:	e510                	sd	a2,8(a0)
    80005cb8:	e914                	sd	a3,16(a0)
    80005cba:	6d0c                	ld	a1,24(a0)
    80005cbc:	7110                	ld	a2,32(a0)
    80005cbe:	6194                	ld	a3,0(a1)
    80005cc0:	96b2                	add	a3,a3,a2
    80005cc2:	e194                	sd	a3,0(a1)
    80005cc4:	4589                	li	a1,2
    80005cc6:	14459073          	csrw	sip,a1
    80005cca:	6914                	ld	a3,16(a0)
    80005ccc:	6510                	ld	a2,8(a0)
    80005cce:	610c                	ld	a1,0(a0)
    80005cd0:	34051573          	csrrw	a0,mscratch,a0
    80005cd4:	30200073          	mret
	...

0000000080005cda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cda:	1141                	addi	sp,sp,-16
    80005cdc:	e422                	sd	s0,8(sp)
    80005cde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ce0:	0c0007b7          	lui	a5,0xc000
    80005ce4:	4705                	li	a4,1
    80005ce6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ce8:	c3d8                	sw	a4,4(a5)
}
    80005cea:	6422                	ld	s0,8(sp)
    80005cec:	0141                	addi	sp,sp,16
    80005cee:	8082                	ret

0000000080005cf0 <plicinithart>:

void
plicinithart(void)
{
    80005cf0:	1141                	addi	sp,sp,-16
    80005cf2:	e406                	sd	ra,8(sp)
    80005cf4:	e022                	sd	s0,0(sp)
    80005cf6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cf8:	ffffc097          	auipc	ra,0xffffc
    80005cfc:	d00080e7          	jalr	-768(ra) # 800019f8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d00:	0085171b          	slliw	a4,a0,0x8
    80005d04:	0c0027b7          	lui	a5,0xc002
    80005d08:	97ba                	add	a5,a5,a4
    80005d0a:	40200713          	li	a4,1026
    80005d0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d12:	00d5151b          	slliw	a0,a0,0xd
    80005d16:	0c2017b7          	lui	a5,0xc201
    80005d1a:	97aa                	add	a5,a5,a0
    80005d1c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d20:	60a2                	ld	ra,8(sp)
    80005d22:	6402                	ld	s0,0(sp)
    80005d24:	0141                	addi	sp,sp,16
    80005d26:	8082                	ret

0000000080005d28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d28:	1141                	addi	sp,sp,-16
    80005d2a:	e406                	sd	ra,8(sp)
    80005d2c:	e022                	sd	s0,0(sp)
    80005d2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d30:	ffffc097          	auipc	ra,0xffffc
    80005d34:	cc8080e7          	jalr	-824(ra) # 800019f8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d38:	00d5151b          	slliw	a0,a0,0xd
    80005d3c:	0c2017b7          	lui	a5,0xc201
    80005d40:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d42:	43c8                	lw	a0,4(a5)
    80005d44:	60a2                	ld	ra,8(sp)
    80005d46:	6402                	ld	s0,0(sp)
    80005d48:	0141                	addi	sp,sp,16
    80005d4a:	8082                	ret

0000000080005d4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d4c:	1101                	addi	sp,sp,-32
    80005d4e:	ec06                	sd	ra,24(sp)
    80005d50:	e822                	sd	s0,16(sp)
    80005d52:	e426                	sd	s1,8(sp)
    80005d54:	1000                	addi	s0,sp,32
    80005d56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	ca0080e7          	jalr	-864(ra) # 800019f8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d60:	00d5151b          	slliw	a0,a0,0xd
    80005d64:	0c2017b7          	lui	a5,0xc201
    80005d68:	97aa                	add	a5,a5,a0
    80005d6a:	c3c4                	sw	s1,4(a5)
}
    80005d6c:	60e2                	ld	ra,24(sp)
    80005d6e:	6442                	ld	s0,16(sp)
    80005d70:	64a2                	ld	s1,8(sp)
    80005d72:	6105                	addi	sp,sp,32
    80005d74:	8082                	ret

0000000080005d76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d76:	1141                	addi	sp,sp,-16
    80005d78:	e406                	sd	ra,8(sp)
    80005d7a:	e022                	sd	s0,0(sp)
    80005d7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d7e:	479d                	li	a5,7
    80005d80:	04a7cc63          	blt	a5,a0,80005dd8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d84:	0001c797          	auipc	a5,0x1c
    80005d88:	1ac78793          	addi	a5,a5,428 # 80021f30 <disk>
    80005d8c:	97aa                	add	a5,a5,a0
    80005d8e:	0187c783          	lbu	a5,24(a5)
    80005d92:	ebb9                	bnez	a5,80005de8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d94:	00451693          	slli	a3,a0,0x4
    80005d98:	0001c797          	auipc	a5,0x1c
    80005d9c:	19878793          	addi	a5,a5,408 # 80021f30 <disk>
    80005da0:	6398                	ld	a4,0(a5)
    80005da2:	9736                	add	a4,a4,a3
    80005da4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005da8:	6398                	ld	a4,0(a5)
    80005daa:	9736                	add	a4,a4,a3
    80005dac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005db0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005db4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005db8:	97aa                	add	a5,a5,a0
    80005dba:	4705                	li	a4,1
    80005dbc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005dc0:	0001c517          	auipc	a0,0x1c
    80005dc4:	18850513          	addi	a0,a0,392 # 80021f48 <disk+0x18>
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	396080e7          	jalr	918(ra) # 8000215e <wakeup>
}
    80005dd0:	60a2                	ld	ra,8(sp)
    80005dd2:	6402                	ld	s0,0(sp)
    80005dd4:	0141                	addi	sp,sp,16
    80005dd6:	8082                	ret
    panic("free_desc 1");
    80005dd8:	00003517          	auipc	a0,0x3
    80005ddc:	9e850513          	addi	a0,a0,-1560 # 800087c0 <syscalls+0x368>
    80005de0:	ffffa097          	auipc	ra,0xffffa
    80005de4:	760080e7          	jalr	1888(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005de8:	00003517          	auipc	a0,0x3
    80005dec:	9e850513          	addi	a0,a0,-1560 # 800087d0 <syscalls+0x378>
    80005df0:	ffffa097          	auipc	ra,0xffffa
    80005df4:	750080e7          	jalr	1872(ra) # 80000540 <panic>

0000000080005df8 <virtio_disk_init>:
{
    80005df8:	1101                	addi	sp,sp,-32
    80005dfa:	ec06                	sd	ra,24(sp)
    80005dfc:	e822                	sd	s0,16(sp)
    80005dfe:	e426                	sd	s1,8(sp)
    80005e00:	e04a                	sd	s2,0(sp)
    80005e02:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e04:	00003597          	auipc	a1,0x3
    80005e08:	9dc58593          	addi	a1,a1,-1572 # 800087e0 <syscalls+0x388>
    80005e0c:	0001c517          	auipc	a0,0x1c
    80005e10:	24c50513          	addi	a0,a0,588 # 80022058 <disk+0x128>
    80005e14:	ffffb097          	auipc	ra,0xffffb
    80005e18:	da4080e7          	jalr	-604(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e1c:	100017b7          	lui	a5,0x10001
    80005e20:	4398                	lw	a4,0(a5)
    80005e22:	2701                	sext.w	a4,a4
    80005e24:	747277b7          	lui	a5,0x74727
    80005e28:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e2c:	14f71b63          	bne	a4,a5,80005f82 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e30:	100017b7          	lui	a5,0x10001
    80005e34:	43dc                	lw	a5,4(a5)
    80005e36:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e38:	4709                	li	a4,2
    80005e3a:	14e79463          	bne	a5,a4,80005f82 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e3e:	100017b7          	lui	a5,0x10001
    80005e42:	479c                	lw	a5,8(a5)
    80005e44:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e46:	12e79e63          	bne	a5,a4,80005f82 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e4a:	100017b7          	lui	a5,0x10001
    80005e4e:	47d8                	lw	a4,12(a5)
    80005e50:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e52:	554d47b7          	lui	a5,0x554d4
    80005e56:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e5a:	12f71463          	bne	a4,a5,80005f82 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e5e:	100017b7          	lui	a5,0x10001
    80005e62:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e66:	4705                	li	a4,1
    80005e68:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6a:	470d                	li	a4,3
    80005e6c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e6e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e70:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e74:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc45f>
    80005e78:	8f75                	and	a4,a4,a3
    80005e7a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7c:	472d                	li	a4,11
    80005e7e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e80:	5bbc                	lw	a5,112(a5)
    80005e82:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e86:	8ba1                	andi	a5,a5,8
    80005e88:	10078563          	beqz	a5,80005f92 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e94:	43fc                	lw	a5,68(a5)
    80005e96:	2781                	sext.w	a5,a5
    80005e98:	10079563          	bnez	a5,80005fa2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e9c:	100017b7          	lui	a5,0x10001
    80005ea0:	5bdc                	lw	a5,52(a5)
    80005ea2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ea4:	10078763          	beqz	a5,80005fb2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005ea8:	471d                	li	a4,7
    80005eaa:	10f77c63          	bgeu	a4,a5,80005fc2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005eae:	ffffb097          	auipc	ra,0xffffb
    80005eb2:	caa080e7          	jalr	-854(ra) # 80000b58 <kalloc>
    80005eb6:	0001c497          	auipc	s1,0x1c
    80005eba:	07a48493          	addi	s1,s1,122 # 80021f30 <disk>
    80005ebe:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005ec0:	ffffb097          	auipc	ra,0xffffb
    80005ec4:	c98080e7          	jalr	-872(ra) # 80000b58 <kalloc>
    80005ec8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005eca:	ffffb097          	auipc	ra,0xffffb
    80005ece:	c8e080e7          	jalr	-882(ra) # 80000b58 <kalloc>
    80005ed2:	87aa                	mv	a5,a0
    80005ed4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005ed6:	6088                	ld	a0,0(s1)
    80005ed8:	cd6d                	beqz	a0,80005fd2 <virtio_disk_init+0x1da>
    80005eda:	0001c717          	auipc	a4,0x1c
    80005ede:	05e73703          	ld	a4,94(a4) # 80021f38 <disk+0x8>
    80005ee2:	cb65                	beqz	a4,80005fd2 <virtio_disk_init+0x1da>
    80005ee4:	c7fd                	beqz	a5,80005fd2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005ee6:	6605                	lui	a2,0x1
    80005ee8:	4581                	li	a1,0
    80005eea:	ffffb097          	auipc	ra,0xffffb
    80005eee:	e5a080e7          	jalr	-422(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005ef2:	0001c497          	auipc	s1,0x1c
    80005ef6:	03e48493          	addi	s1,s1,62 # 80021f30 <disk>
    80005efa:	6605                	lui	a2,0x1
    80005efc:	4581                	li	a1,0
    80005efe:	6488                	ld	a0,8(s1)
    80005f00:	ffffb097          	auipc	ra,0xffffb
    80005f04:	e44080e7          	jalr	-444(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f08:	6605                	lui	a2,0x1
    80005f0a:	4581                	li	a1,0
    80005f0c:	6888                	ld	a0,16(s1)
    80005f0e:	ffffb097          	auipc	ra,0xffffb
    80005f12:	e36080e7          	jalr	-458(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f16:	100017b7          	lui	a5,0x10001
    80005f1a:	4721                	li	a4,8
    80005f1c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f1e:	4098                	lw	a4,0(s1)
    80005f20:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f24:	40d8                	lw	a4,4(s1)
    80005f26:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f2a:	6498                	ld	a4,8(s1)
    80005f2c:	0007069b          	sext.w	a3,a4
    80005f30:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f34:	9701                	srai	a4,a4,0x20
    80005f36:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f3a:	6898                	ld	a4,16(s1)
    80005f3c:	0007069b          	sext.w	a3,a4
    80005f40:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f44:	9701                	srai	a4,a4,0x20
    80005f46:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f4a:	4705                	li	a4,1
    80005f4c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f4e:	00e48c23          	sb	a4,24(s1)
    80005f52:	00e48ca3          	sb	a4,25(s1)
    80005f56:	00e48d23          	sb	a4,26(s1)
    80005f5a:	00e48da3          	sb	a4,27(s1)
    80005f5e:	00e48e23          	sb	a4,28(s1)
    80005f62:	00e48ea3          	sb	a4,29(s1)
    80005f66:	00e48f23          	sb	a4,30(s1)
    80005f6a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f6e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f72:	0727a823          	sw	s2,112(a5)
}
    80005f76:	60e2                	ld	ra,24(sp)
    80005f78:	6442                	ld	s0,16(sp)
    80005f7a:	64a2                	ld	s1,8(sp)
    80005f7c:	6902                	ld	s2,0(sp)
    80005f7e:	6105                	addi	sp,sp,32
    80005f80:	8082                	ret
    panic("could not find virtio disk");
    80005f82:	00003517          	auipc	a0,0x3
    80005f86:	86e50513          	addi	a0,a0,-1938 # 800087f0 <syscalls+0x398>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5b6080e7          	jalr	1462(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f92:	00003517          	auipc	a0,0x3
    80005f96:	87e50513          	addi	a0,a0,-1922 # 80008810 <syscalls+0x3b8>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	5a6080e7          	jalr	1446(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005fa2:	00003517          	auipc	a0,0x3
    80005fa6:	88e50513          	addi	a0,a0,-1906 # 80008830 <syscalls+0x3d8>
    80005faa:	ffffa097          	auipc	ra,0xffffa
    80005fae:	596080e7          	jalr	1430(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005fb2:	00003517          	auipc	a0,0x3
    80005fb6:	89e50513          	addi	a0,a0,-1890 # 80008850 <syscalls+0x3f8>
    80005fba:	ffffa097          	auipc	ra,0xffffa
    80005fbe:	586080e7          	jalr	1414(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005fc2:	00003517          	auipc	a0,0x3
    80005fc6:	8ae50513          	addi	a0,a0,-1874 # 80008870 <syscalls+0x418>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	576080e7          	jalr	1398(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005fd2:	00003517          	auipc	a0,0x3
    80005fd6:	8be50513          	addi	a0,a0,-1858 # 80008890 <syscalls+0x438>
    80005fda:	ffffa097          	auipc	ra,0xffffa
    80005fde:	566080e7          	jalr	1382(ra) # 80000540 <panic>

0000000080005fe2 <virtio_disk_init_bootloader>:
{
    80005fe2:	1101                	addi	sp,sp,-32
    80005fe4:	ec06                	sd	ra,24(sp)
    80005fe6:	e822                	sd	s0,16(sp)
    80005fe8:	e426                	sd	s1,8(sp)
    80005fea:	e04a                	sd	s2,0(sp)
    80005fec:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fee:	00002597          	auipc	a1,0x2
    80005ff2:	7f258593          	addi	a1,a1,2034 # 800087e0 <syscalls+0x388>
    80005ff6:	0001c517          	auipc	a0,0x1c
    80005ffa:	06250513          	addi	a0,a0,98 # 80022058 <disk+0x128>
    80005ffe:	ffffb097          	auipc	ra,0xffffb
    80006002:	bba080e7          	jalr	-1094(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006006:	100017b7          	lui	a5,0x10001
    8000600a:	4398                	lw	a4,0(a5)
    8000600c:	2701                	sext.w	a4,a4
    8000600e:	747277b7          	lui	a5,0x74727
    80006012:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006016:	12f71763          	bne	a4,a5,80006144 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000601a:	100017b7          	lui	a5,0x10001
    8000601e:	43dc                	lw	a5,4(a5)
    80006020:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006022:	4709                	li	a4,2
    80006024:	12e79063          	bne	a5,a4,80006144 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006028:	100017b7          	lui	a5,0x10001
    8000602c:	479c                	lw	a5,8(a5)
    8000602e:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006030:	10e79a63          	bne	a5,a4,80006144 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006034:	100017b7          	lui	a5,0x10001
    80006038:	47d8                	lw	a4,12(a5)
    8000603a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000603c:	554d47b7          	lui	a5,0x554d4
    80006040:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006044:	10f71063          	bne	a4,a5,80006144 <virtio_disk_init_bootloader+0x162>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006048:	100017b7          	lui	a5,0x10001
    8000604c:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006050:	4705                	li	a4,1
    80006052:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006054:	470d                	li	a4,3
    80006056:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006058:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000605a:	c7ffe6b7          	lui	a3,0xc7ffe
    8000605e:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc45f>
    80006062:	8f75                	and	a4,a4,a3
    80006064:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006066:	472d                	li	a4,11
    80006068:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000606a:	5bbc                	lw	a5,112(a5)
    8000606c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006070:	8ba1                	andi	a5,a5,8
    80006072:	c3ed                	beqz	a5,80006154 <virtio_disk_init_bootloader+0x172>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006074:	100017b7          	lui	a5,0x10001
    80006078:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000607c:	43fc                	lw	a5,68(a5)
    8000607e:	2781                	sext.w	a5,a5
    80006080:	e3f5                	bnez	a5,80006164 <virtio_disk_init_bootloader+0x182>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006082:	100017b7          	lui	a5,0x10001
    80006086:	5bdc                	lw	a5,52(a5)
    80006088:	2781                	sext.w	a5,a5
  if(max == 0)
    8000608a:	c7ed                	beqz	a5,80006174 <virtio_disk_init_bootloader+0x192>
  if(max < NUM)
    8000608c:	471d                	li	a4,7
    8000608e:	0ef77b63          	bgeu	a4,a5,80006184 <virtio_disk_init_bootloader+0x1a2>
  disk.desc  = (void*) 0x77000000;
    80006092:	0001c497          	auipc	s1,0x1c
    80006096:	e9e48493          	addi	s1,s1,-354 # 80021f30 <disk>
    8000609a:	770007b7          	lui	a5,0x77000
    8000609e:	e09c                	sd	a5,0(s1)
  disk.avail = (void*) 0x77001000;
    800060a0:	770017b7          	lui	a5,0x77001
    800060a4:	e49c                	sd	a5,8(s1)
  disk.used  = (void*) 0x77002000;
    800060a6:	770027b7          	lui	a5,0x77002
    800060aa:	e89c                	sd	a5,16(s1)
  memset(disk.desc, 0, PGSIZE);
    800060ac:	6605                	lui	a2,0x1
    800060ae:	4581                	li	a1,0
    800060b0:	77000537          	lui	a0,0x77000
    800060b4:	ffffb097          	auipc	ra,0xffffb
    800060b8:	c90080e7          	jalr	-880(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060bc:	6605                	lui	a2,0x1
    800060be:	4581                	li	a1,0
    800060c0:	6488                	ld	a0,8(s1)
    800060c2:	ffffb097          	auipc	ra,0xffffb
    800060c6:	c82080e7          	jalr	-894(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    800060ca:	6605                	lui	a2,0x1
    800060cc:	4581                	li	a1,0
    800060ce:	6888                	ld	a0,16(s1)
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	c74080e7          	jalr	-908(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060d8:	100017b7          	lui	a5,0x10001
    800060dc:	4721                	li	a4,8
    800060de:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060e0:	4098                	lw	a4,0(s1)
    800060e2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060e6:	40d8                	lw	a4,4(s1)
    800060e8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060ec:	6498                	ld	a4,8(s1)
    800060ee:	0007069b          	sext.w	a3,a4
    800060f2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800060f6:	9701                	srai	a4,a4,0x20
    800060f8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800060fc:	6898                	ld	a4,16(s1)
    800060fe:	0007069b          	sext.w	a3,a4
    80006102:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006106:	9701                	srai	a4,a4,0x20
    80006108:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000610c:	4705                	li	a4,1
    8000610e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006110:	00e48c23          	sb	a4,24(s1)
    80006114:	00e48ca3          	sb	a4,25(s1)
    80006118:	00e48d23          	sb	a4,26(s1)
    8000611c:	00e48da3          	sb	a4,27(s1)
    80006120:	00e48e23          	sb	a4,28(s1)
    80006124:	00e48ea3          	sb	a4,29(s1)
    80006128:	00e48f23          	sb	a4,30(s1)
    8000612c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006130:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006134:	0727a823          	sw	s2,112(a5)
}
    80006138:	60e2                	ld	ra,24(sp)
    8000613a:	6442                	ld	s0,16(sp)
    8000613c:	64a2                	ld	s1,8(sp)
    8000613e:	6902                	ld	s2,0(sp)
    80006140:	6105                	addi	sp,sp,32
    80006142:	8082                	ret
    panic("could not find virtio disk");
    80006144:	00002517          	auipc	a0,0x2
    80006148:	6ac50513          	addi	a0,a0,1708 # 800087f0 <syscalls+0x398>
    8000614c:	ffffa097          	auipc	ra,0xffffa
    80006150:	3f4080e7          	jalr	1012(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006154:	00002517          	auipc	a0,0x2
    80006158:	6bc50513          	addi	a0,a0,1724 # 80008810 <syscalls+0x3b8>
    8000615c:	ffffa097          	auipc	ra,0xffffa
    80006160:	3e4080e7          	jalr	996(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006164:	00002517          	auipc	a0,0x2
    80006168:	6cc50513          	addi	a0,a0,1740 # 80008830 <syscalls+0x3d8>
    8000616c:	ffffa097          	auipc	ra,0xffffa
    80006170:	3d4080e7          	jalr	980(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006174:	00002517          	auipc	a0,0x2
    80006178:	6dc50513          	addi	a0,a0,1756 # 80008850 <syscalls+0x3f8>
    8000617c:	ffffa097          	auipc	ra,0xffffa
    80006180:	3c4080e7          	jalr	964(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006184:	00002517          	auipc	a0,0x2
    80006188:	6ec50513          	addi	a0,a0,1772 # 80008870 <syscalls+0x418>
    8000618c:	ffffa097          	auipc	ra,0xffffa
    80006190:	3b4080e7          	jalr	948(ra) # 80000540 <panic>

0000000080006194 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006194:	7159                	addi	sp,sp,-112
    80006196:	f486                	sd	ra,104(sp)
    80006198:	f0a2                	sd	s0,96(sp)
    8000619a:	eca6                	sd	s1,88(sp)
    8000619c:	e8ca                	sd	s2,80(sp)
    8000619e:	e4ce                	sd	s3,72(sp)
    800061a0:	e0d2                	sd	s4,64(sp)
    800061a2:	fc56                	sd	s5,56(sp)
    800061a4:	f85a                	sd	s6,48(sp)
    800061a6:	f45e                	sd	s7,40(sp)
    800061a8:	f062                	sd	s8,32(sp)
    800061aa:	ec66                	sd	s9,24(sp)
    800061ac:	e86a                	sd	s10,16(sp)
    800061ae:	1880                	addi	s0,sp,112
    800061b0:	8a2a                	mv	s4,a0
    800061b2:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061b4:	00c52c83          	lw	s9,12(a0)
    800061b8:	001c9c9b          	slliw	s9,s9,0x1
    800061bc:	1c82                	slli	s9,s9,0x20
    800061be:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061c2:	0001c517          	auipc	a0,0x1c
    800061c6:	e9650513          	addi	a0,a0,-362 # 80022058 <disk+0x128>
    800061ca:	ffffb097          	auipc	ra,0xffffb
    800061ce:	a7e080e7          	jalr	-1410(ra) # 80000c48 <acquire>
  for(int i = 0; i < 3; i++){
    800061d2:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800061d4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061d6:	0001cb17          	auipc	s6,0x1c
    800061da:	d5ab0b13          	addi	s6,s6,-678 # 80021f30 <disk>
  for(int i = 0; i < 3; i++){
    800061de:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061e0:	0001cc17          	auipc	s8,0x1c
    800061e4:	e78c0c13          	addi	s8,s8,-392 # 80022058 <disk+0x128>
    800061e8:	a095                	j	8000624c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800061ea:	00fb0733          	add	a4,s6,a5
    800061ee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061f2:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800061f4:	0207c563          	bltz	a5,8000621e <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800061f8:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800061fa:	0591                	addi	a1,a1,4
    800061fc:	05560d63          	beq	a2,s5,80006256 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006200:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006202:	0001c717          	auipc	a4,0x1c
    80006206:	d2e70713          	addi	a4,a4,-722 # 80021f30 <disk>
    8000620a:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000620c:	01874683          	lbu	a3,24(a4)
    80006210:	fee9                	bnez	a3,800061ea <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006212:	2785                	addiw	a5,a5,1
    80006214:	0705                	addi	a4,a4,1
    80006216:	fe979be3          	bne	a5,s1,8000620c <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    8000621a:	57fd                	li	a5,-1
    8000621c:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000621e:	00c05e63          	blez	a2,8000623a <virtio_disk_rw+0xa6>
    80006222:	060a                	slli	a2,a2,0x2
    80006224:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006228:	0009a503          	lw	a0,0(s3)
    8000622c:	00000097          	auipc	ra,0x0
    80006230:	b4a080e7          	jalr	-1206(ra) # 80005d76 <free_desc>
      for(int j = 0; j < i; j++)
    80006234:	0991                	addi	s3,s3,4
    80006236:	ffa999e3          	bne	s3,s10,80006228 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000623a:	85e2                	mv	a1,s8
    8000623c:	0001c517          	auipc	a0,0x1c
    80006240:	d0c50513          	addi	a0,a0,-756 # 80021f48 <disk+0x18>
    80006244:	ffffc097          	auipc	ra,0xffffc
    80006248:	eb6080e7          	jalr	-330(ra) # 800020fa <sleep>
  for(int i = 0; i < 3; i++){
    8000624c:	f9040993          	addi	s3,s0,-112
{
    80006250:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006252:	864a                	mv	a2,s2
    80006254:	b775                	j	80006200 <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006256:	f9042503          	lw	a0,-112(s0)
    8000625a:	00a50713          	addi	a4,a0,10
    8000625e:	0712                	slli	a4,a4,0x4

  if(write)
    80006260:	0001c797          	auipc	a5,0x1c
    80006264:	cd078793          	addi	a5,a5,-816 # 80021f30 <disk>
    80006268:	00e786b3          	add	a3,a5,a4
    8000626c:	01703633          	snez	a2,s7
    80006270:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006272:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006276:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000627a:	f6070613          	addi	a2,a4,-160
    8000627e:	6394                	ld	a3,0(a5)
    80006280:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006282:	00870593          	addi	a1,a4,8
    80006286:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006288:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000628a:	0007b803          	ld	a6,0(a5)
    8000628e:	9642                	add	a2,a2,a6
    80006290:	46c1                	li	a3,16
    80006292:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006294:	4585                	li	a1,1
    80006296:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    8000629a:	f9442683          	lw	a3,-108(s0)
    8000629e:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062a2:	0692                	slli	a3,a3,0x4
    800062a4:	9836                	add	a6,a6,a3
    800062a6:	058a0613          	addi	a2,s4,88
    800062aa:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800062ae:	0007b803          	ld	a6,0(a5)
    800062b2:	96c2                	add	a3,a3,a6
    800062b4:	40000613          	li	a2,1024
    800062b8:	c690                	sw	a2,8(a3)
  if(write)
    800062ba:	001bb613          	seqz	a2,s7
    800062be:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062c2:	00166613          	ori	a2,a2,1
    800062c6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062ca:	f9842603          	lw	a2,-104(s0)
    800062ce:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062d2:	00250693          	addi	a3,a0,2
    800062d6:	0692                	slli	a3,a3,0x4
    800062d8:	96be                	add	a3,a3,a5
    800062da:	58fd                	li	a7,-1
    800062dc:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062e0:	0612                	slli	a2,a2,0x4
    800062e2:	9832                	add	a6,a6,a2
    800062e4:	f9070713          	addi	a4,a4,-112
    800062e8:	973e                	add	a4,a4,a5
    800062ea:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800062ee:	6398                	ld	a4,0(a5)
    800062f0:	9732                	add	a4,a4,a2
    800062f2:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062f4:	4609                	li	a2,2
    800062f6:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800062fa:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062fe:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006302:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006306:	6794                	ld	a3,8(a5)
    80006308:	0026d703          	lhu	a4,2(a3)
    8000630c:	8b1d                	andi	a4,a4,7
    8000630e:	0706                	slli	a4,a4,0x1
    80006310:	96ba                	add	a3,a3,a4
    80006312:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006316:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000631a:	6798                	ld	a4,8(a5)
    8000631c:	00275783          	lhu	a5,2(a4)
    80006320:	2785                	addiw	a5,a5,1
    80006322:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006326:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000632a:	100017b7          	lui	a5,0x10001
    8000632e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006332:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006336:	0001c917          	auipc	s2,0x1c
    8000633a:	d2290913          	addi	s2,s2,-734 # 80022058 <disk+0x128>
  while(b->disk == 1) {
    8000633e:	4485                	li	s1,1
    80006340:	00b79c63          	bne	a5,a1,80006358 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006344:	85ca                	mv	a1,s2
    80006346:	8552                	mv	a0,s4
    80006348:	ffffc097          	auipc	ra,0xffffc
    8000634c:	db2080e7          	jalr	-590(ra) # 800020fa <sleep>
  while(b->disk == 1) {
    80006350:	004a2783          	lw	a5,4(s4)
    80006354:	fe9788e3          	beq	a5,s1,80006344 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006358:	f9042903          	lw	s2,-112(s0)
    8000635c:	00290713          	addi	a4,s2,2
    80006360:	0712                	slli	a4,a4,0x4
    80006362:	0001c797          	auipc	a5,0x1c
    80006366:	bce78793          	addi	a5,a5,-1074 # 80021f30 <disk>
    8000636a:	97ba                	add	a5,a5,a4
    8000636c:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006370:	0001c997          	auipc	s3,0x1c
    80006374:	bc098993          	addi	s3,s3,-1088 # 80021f30 <disk>
    80006378:	00491713          	slli	a4,s2,0x4
    8000637c:	0009b783          	ld	a5,0(s3)
    80006380:	97ba                	add	a5,a5,a4
    80006382:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006386:	854a                	mv	a0,s2
    80006388:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000638c:	00000097          	auipc	ra,0x0
    80006390:	9ea080e7          	jalr	-1558(ra) # 80005d76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006394:	8885                	andi	s1,s1,1
    80006396:	f0ed                	bnez	s1,80006378 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006398:	0001c517          	auipc	a0,0x1c
    8000639c:	cc050513          	addi	a0,a0,-832 # 80022058 <disk+0x128>
    800063a0:	ffffb097          	auipc	ra,0xffffb
    800063a4:	95c080e7          	jalr	-1700(ra) # 80000cfc <release>
}
    800063a8:	70a6                	ld	ra,104(sp)
    800063aa:	7406                	ld	s0,96(sp)
    800063ac:	64e6                	ld	s1,88(sp)
    800063ae:	6946                	ld	s2,80(sp)
    800063b0:	69a6                	ld	s3,72(sp)
    800063b2:	6a06                	ld	s4,64(sp)
    800063b4:	7ae2                	ld	s5,56(sp)
    800063b6:	7b42                	ld	s6,48(sp)
    800063b8:	7ba2                	ld	s7,40(sp)
    800063ba:	7c02                	ld	s8,32(sp)
    800063bc:	6ce2                	ld	s9,24(sp)
    800063be:	6d42                	ld	s10,16(sp)
    800063c0:	6165                	addi	sp,sp,112
    800063c2:	8082                	ret

00000000800063c4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063c4:	1101                	addi	sp,sp,-32
    800063c6:	ec06                	sd	ra,24(sp)
    800063c8:	e822                	sd	s0,16(sp)
    800063ca:	e426                	sd	s1,8(sp)
    800063cc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063ce:	0001c497          	auipc	s1,0x1c
    800063d2:	b6248493          	addi	s1,s1,-1182 # 80021f30 <disk>
    800063d6:	0001c517          	auipc	a0,0x1c
    800063da:	c8250513          	addi	a0,a0,-894 # 80022058 <disk+0x128>
    800063de:	ffffb097          	auipc	ra,0xffffb
    800063e2:	86a080e7          	jalr	-1942(ra) # 80000c48 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063e6:	10001737          	lui	a4,0x10001
    800063ea:	533c                	lw	a5,96(a4)
    800063ec:	8b8d                	andi	a5,a5,3
    800063ee:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063f0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063f4:	689c                	ld	a5,16(s1)
    800063f6:	0204d703          	lhu	a4,32(s1)
    800063fa:	0027d783          	lhu	a5,2(a5)
    800063fe:	04f70863          	beq	a4,a5,8000644e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006402:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006406:	6898                	ld	a4,16(s1)
    80006408:	0204d783          	lhu	a5,32(s1)
    8000640c:	8b9d                	andi	a5,a5,7
    8000640e:	078e                	slli	a5,a5,0x3
    80006410:	97ba                	add	a5,a5,a4
    80006412:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006414:	00278713          	addi	a4,a5,2
    80006418:	0712                	slli	a4,a4,0x4
    8000641a:	9726                	add	a4,a4,s1
    8000641c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006420:	e721                	bnez	a4,80006468 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006422:	0789                	addi	a5,a5,2
    80006424:	0792                	slli	a5,a5,0x4
    80006426:	97a6                	add	a5,a5,s1
    80006428:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000642a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000642e:	ffffc097          	auipc	ra,0xffffc
    80006432:	d30080e7          	jalr	-720(ra) # 8000215e <wakeup>

    disk.used_idx += 1;
    80006436:	0204d783          	lhu	a5,32(s1)
    8000643a:	2785                	addiw	a5,a5,1
    8000643c:	17c2                	slli	a5,a5,0x30
    8000643e:	93c1                	srli	a5,a5,0x30
    80006440:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006444:	6898                	ld	a4,16(s1)
    80006446:	00275703          	lhu	a4,2(a4)
    8000644a:	faf71ce3          	bne	a4,a5,80006402 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000644e:	0001c517          	auipc	a0,0x1c
    80006452:	c0a50513          	addi	a0,a0,-1014 # 80022058 <disk+0x128>
    80006456:	ffffb097          	auipc	ra,0xffffb
    8000645a:	8a6080e7          	jalr	-1882(ra) # 80000cfc <release>
}
    8000645e:	60e2                	ld	ra,24(sp)
    80006460:	6442                	ld	s0,16(sp)
    80006462:	64a2                	ld	s1,8(sp)
    80006464:	6105                	addi	sp,sp,32
    80006466:	8082                	ret
      panic("virtio_disk_intr status");
    80006468:	00002517          	auipc	a0,0x2
    8000646c:	44050513          	addi	a0,a0,1088 # 800088a8 <syscalls+0x450>
    80006470:	ffffa097          	auipc	ra,0xffffa
    80006474:	0d0080e7          	jalr	208(ra) # 80000540 <panic>

0000000080006478 <ramdiskinit>:
/* TODO: find the location of the QEMU ramdisk. */
#define RAMDISK 0x84000000

void
ramdiskinit(void)
{
    80006478:	1141                	addi	sp,sp,-16
    8000647a:	e422                	sd	s0,8(sp)
    8000647c:	0800                	addi	s0,sp,16
}
    8000647e:	6422                	ld	s0,8(sp)
    80006480:	0141                	addi	sp,sp,16
    80006482:	8082                	ret

0000000080006484 <ramdiskrw>:

// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
ramdiskrw(struct buf *b)
{
    80006484:	1101                	addi	sp,sp,-32
    80006486:	ec06                	sd	ra,24(sp)
    80006488:	e822                	sd	s0,16(sp)
    8000648a:	e426                	sd	s1,8(sp)
    8000648c:	1000                	addi	s0,sp,32
    panic("ramdiskrw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("ramdiskrw: nothing to do");
#endif

  if(b->blockno >= FSSIZE)
    8000648e:	454c                	lw	a1,12(a0)
    80006490:	7cf00793          	li	a5,1999
    80006494:	02b7ea63          	bltu	a5,a1,800064c8 <ramdiskrw+0x44>
    80006498:	84aa                	mv	s1,a0
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
    8000649a:	00a5959b          	slliw	a1,a1,0xa
    8000649e:	1582                	slli	a1,a1,0x20
    800064a0:	9181                	srli	a1,a1,0x20
  char *addr = (char *)RAMDISK + diskaddr;

  // read from the location
  memmove(b->data, addr, BSIZE);
    800064a2:	40000613          	li	a2,1024
    800064a6:	02100793          	li	a5,33
    800064aa:	07ea                	slli	a5,a5,0x1a
    800064ac:	95be                	add	a1,a1,a5
    800064ae:	05850513          	addi	a0,a0,88
    800064b2:	ffffb097          	auipc	ra,0xffffb
    800064b6:	8ee080e7          	jalr	-1810(ra) # 80000da0 <memmove>
  b->valid = 1;
    800064ba:	4785                	li	a5,1
    800064bc:	c09c                	sw	a5,0(s1)
    // read
    memmove(b->data, addr, BSIZE);
    b->flags |= B_VALID;
  }
#endif
}
    800064be:	60e2                	ld	ra,24(sp)
    800064c0:	6442                	ld	s0,16(sp)
    800064c2:	64a2                	ld	s1,8(sp)
    800064c4:	6105                	addi	sp,sp,32
    800064c6:	8082                	ret
    panic("ramdiskrw: blockno too big");
    800064c8:	00002517          	auipc	a0,0x2
    800064cc:	3f850513          	addi	a0,a0,1016 # 800088c0 <syscalls+0x468>
    800064d0:	ffffa097          	auipc	ra,0xffffa
    800064d4:	070080e7          	jalr	112(ra) # 80000540 <panic>

00000000800064d8 <dump_hex>:
#include "fs.h"
#include "buf.h"
#include <stddef.h>

/* Acknowledgement: https://gist.github.com/ccbrown/9722406 */
void dump_hex(const void* data, size_t size) {
    800064d8:	7119                	addi	sp,sp,-128
    800064da:	fc86                	sd	ra,120(sp)
    800064dc:	f8a2                	sd	s0,112(sp)
    800064de:	f4a6                	sd	s1,104(sp)
    800064e0:	f0ca                	sd	s2,96(sp)
    800064e2:	ecce                	sd	s3,88(sp)
    800064e4:	e8d2                	sd	s4,80(sp)
    800064e6:	e4d6                	sd	s5,72(sp)
    800064e8:	e0da                	sd	s6,64(sp)
    800064ea:	fc5e                	sd	s7,56(sp)
    800064ec:	f862                	sd	s8,48(sp)
    800064ee:	f466                	sd	s9,40(sp)
    800064f0:	0100                	addi	s0,sp,128
	char ascii[17];
	size_t i, j;
	ascii[16] = '\0';
    800064f2:	f8040c23          	sb	zero,-104(s0)
	for (i = 0; i < size; ++i) {
    800064f6:	c5e1                	beqz	a1,800065be <dump_hex+0xe6>
    800064f8:	89ae                	mv	s3,a1
    800064fa:	892a                	mv	s2,a0
    800064fc:	4481                	li	s1,0
		printf("%x ", ((unsigned char*)data)[i]);
    800064fe:	00002a97          	auipc	s5,0x2
    80006502:	3e2a8a93          	addi	s5,s5,994 # 800088e0 <syscalls+0x488>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    80006506:	05e00a13          	li	s4,94
			ascii[i % 16] = ((unsigned char*)data)[i];
		} else {
			ascii[i % 16] = '.';
    8000650a:	02e00b13          	li	s6,46
		}
		if ((i+1) % 8 == 0 || i+1 == size) {
			printf(" ");
			if ((i+1) % 16 == 0) {
				printf("|  %s \n", ascii);
    8000650e:	00002c17          	auipc	s8,0x2
    80006512:	3e2c0c13          	addi	s8,s8,994 # 800088f0 <syscalls+0x498>
			printf(" ");
    80006516:	00002b97          	auipc	s7,0x2
    8000651a:	3d2b8b93          	addi	s7,s7,978 # 800088e8 <syscalls+0x490>
    8000651e:	a839                	j	8000653c <dump_hex+0x64>
			ascii[i % 16] = '.';
    80006520:	00f4f793          	andi	a5,s1,15
    80006524:	fa078793          	addi	a5,a5,-96
    80006528:	97a2                	add	a5,a5,s0
    8000652a:	ff678423          	sb	s6,-24(a5)
		if ((i+1) % 8 == 0 || i+1 == size) {
    8000652e:	0485                	addi	s1,s1,1
    80006530:	0074f793          	andi	a5,s1,7
    80006534:	cb9d                	beqz	a5,8000656a <dump_hex+0x92>
    80006536:	0b348a63          	beq	s1,s3,800065ea <dump_hex+0x112>
	for (i = 0; i < size; ++i) {
    8000653a:	0905                	addi	s2,s2,1
		printf("%x ", ((unsigned char*)data)[i]);
    8000653c:	00094583          	lbu	a1,0(s2)
    80006540:	8556                	mv	a0,s5
    80006542:	ffffa097          	auipc	ra,0xffffa
    80006546:	048080e7          	jalr	72(ra) # 8000058a <printf>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    8000654a:	00094703          	lbu	a4,0(s2)
    8000654e:	fe07079b          	addiw	a5,a4,-32
    80006552:	0ff7f793          	zext.b	a5,a5
    80006556:	fcfa65e3          	bltu	s4,a5,80006520 <dump_hex+0x48>
			ascii[i % 16] = ((unsigned char*)data)[i];
    8000655a:	00f4f793          	andi	a5,s1,15
    8000655e:	fa078793          	addi	a5,a5,-96
    80006562:	97a2                	add	a5,a5,s0
    80006564:	fee78423          	sb	a4,-24(a5)
    80006568:	b7d9                	j	8000652e <dump_hex+0x56>
			printf(" ");
    8000656a:	855e                	mv	a0,s7
    8000656c:	ffffa097          	auipc	ra,0xffffa
    80006570:	01e080e7          	jalr	30(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    80006574:	00f4fc93          	andi	s9,s1,15
    80006578:	080c8263          	beqz	s9,800065fc <dump_hex+0x124>
			} else if (i+1 == size) {
    8000657c:	fb349fe3          	bne	s1,s3,8000653a <dump_hex+0x62>
				ascii[(i+1) % 16] = '\0';
    80006580:	fa0c8793          	addi	a5,s9,-96
    80006584:	97a2                	add	a5,a5,s0
    80006586:	fe078423          	sb	zero,-24(a5)
				if ((i+1) % 16 <= 8) {
    8000658a:	47a1                	li	a5,8
    8000658c:	0597f663          	bgeu	a5,s9,800065d8 <dump_hex+0x100>
					printf(" ");
				}
				for (j = (i+1) % 16; j < 16; ++j) {
					printf("   ");
    80006590:	00002917          	auipc	s2,0x2
    80006594:	36890913          	addi	s2,s2,872 # 800088f8 <syscalls+0x4a0>
				for (j = (i+1) % 16; j < 16; ++j) {
    80006598:	44bd                	li	s1,15
					printf("   ");
    8000659a:	854a                	mv	a0,s2
    8000659c:	ffffa097          	auipc	ra,0xffffa
    800065a0:	fee080e7          	jalr	-18(ra) # 8000058a <printf>
				for (j = (i+1) % 16; j < 16; ++j) {
    800065a4:	0c85                	addi	s9,s9,1
    800065a6:	ff94fae3          	bgeu	s1,s9,8000659a <dump_hex+0xc2>
				}
				printf("|  %s \n", ascii);
    800065aa:	f8840593          	addi	a1,s0,-120
    800065ae:	00002517          	auipc	a0,0x2
    800065b2:	34250513          	addi	a0,a0,834 # 800088f0 <syscalls+0x498>
    800065b6:	ffffa097          	auipc	ra,0xffffa
    800065ba:	fd4080e7          	jalr	-44(ra) # 8000058a <printf>
			}
		}
	}
    800065be:	70e6                	ld	ra,120(sp)
    800065c0:	7446                	ld	s0,112(sp)
    800065c2:	74a6                	ld	s1,104(sp)
    800065c4:	7906                	ld	s2,96(sp)
    800065c6:	69e6                	ld	s3,88(sp)
    800065c8:	6a46                	ld	s4,80(sp)
    800065ca:	6aa6                	ld	s5,72(sp)
    800065cc:	6b06                	ld	s6,64(sp)
    800065ce:	7be2                	ld	s7,56(sp)
    800065d0:	7c42                	ld	s8,48(sp)
    800065d2:	7ca2                	ld	s9,40(sp)
    800065d4:	6109                	addi	sp,sp,128
    800065d6:	8082                	ret
					printf(" ");
    800065d8:	00002517          	auipc	a0,0x2
    800065dc:	31050513          	addi	a0,a0,784 # 800088e8 <syscalls+0x490>
    800065e0:	ffffa097          	auipc	ra,0xffffa
    800065e4:	faa080e7          	jalr	-86(ra) # 8000058a <printf>
    800065e8:	b765                	j	80006590 <dump_hex+0xb8>
			printf(" ");
    800065ea:	855e                	mv	a0,s7
    800065ec:	ffffa097          	auipc	ra,0xffffa
    800065f0:	f9e080e7          	jalr	-98(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    800065f4:	00f9fc93          	andi	s9,s3,15
    800065f8:	f80c94e3          	bnez	s9,80006580 <dump_hex+0xa8>
				printf("|  %s \n", ascii);
    800065fc:	f8840593          	addi	a1,s0,-120
    80006600:	8562                	mv	a0,s8
    80006602:	ffffa097          	auipc	ra,0xffffa
    80006606:	f88080e7          	jalr	-120(ra) # 8000058a <printf>
	for (i = 0; i < size; ++i) {
    8000660a:	fb348ae3          	beq	s1,s3,800065be <dump_hex+0xe6>
    8000660e:	0905                	addi	s2,s2,1
    80006610:	b735                	j	8000653c <dump_hex+0x64>

0000000080006612 <uvmcopy_copmp>:
typedef struct vm_virtual_state vm_virtual_state;
pagetable_t host_ptable = NULL;

vm_virtual_state vm_state;

void uvmcopy_copmp(pagetable_t old, pagetable_t new, uint64 sz){
    80006612:	7179                	addi	sp,sp,-48
    80006614:	f406                	sd	ra,40(sp)
    80006616:	f022                	sd	s0,32(sp)
    80006618:	ec26                	sd	s1,24(sp)
    8000661a:	e84a                	sd	s2,16(sp)
    8000661c:	e44e                	sd	s3,8(sp)
    8000661e:	e052                	sd	s4,0(sp)
    80006620:	1800                	addi	s0,sp,48
    80006622:	892a                	mv	s2,a0
    80006624:	89ae                	mv	s3,a1
  pte_t *pte;
  uint64 pa, i;
  uint flags;
 
  for(i = 0; i < sz; i += PGSIZE){
    80006626:	ce1d                	beqz	a2,80006664 <uvmcopy_copmp+0x52>
    80006628:	8a32                	mv	s4,a2
    8000662a:	4481                	li	s1,0
    if((pte = walk(old, i, 0)) == 0)
    8000662c:	4601                	li	a2,0
    8000662e:	85a6                	mv	a1,s1
    80006630:	854a                	mv	a0,s2
    80006632:	ffffb097          	auipc	ra,0xffffb
    80006636:	9fc080e7          	jalr	-1540(ra) # 8000102e <walk>
    8000663a:	cd35                	beqz	a0,800066b6 <uvmcopy_copmp+0xa4>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000663c:	6118                	ld	a4,0(a0)
    8000663e:	00177793          	andi	a5,a4,1
    80006642:	c3d1                	beqz	a5,800066c6 <uvmcopy_copmp+0xb4>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80006644:	00a75693          	srli	a3,a4,0xa
    flags = PTE_FLAGS(*pte);
    mappages(new, i, PGSIZE, (uint64)pa, flags);
    80006648:	3ff77713          	andi	a4,a4,1023
    8000664c:	06b2                	slli	a3,a3,0xc
    8000664e:	6605                	lui	a2,0x1
    80006650:	85a6                	mv	a1,s1
    80006652:	854e                	mv	a0,s3
    80006654:	ffffb097          	auipc	ra,0xffffb
    80006658:	ac2080e7          	jalr	-1342(ra) # 80001116 <mappages>
  for(i = 0; i < sz; i += PGSIZE){
    8000665c:	6785                	lui	a5,0x1
    8000665e:	94be                	add	s1,s1,a5
    80006660:	fd44e6e3          	bltu	s1,s4,8000662c <uvmcopy_copmp+0x1a>
  }

  for(i = 0x80000000; i < 0x80400000; i += PGSIZE){
    80006664:	4485                	li	s1,1
    80006666:	04fe                	slli	s1,s1,0x1f
    80006668:	20100a13          	li	s4,513
    8000666c:	0a5a                	slli	s4,s4,0x16
    if((pte = walk(old, i, 0)) == 0)
    8000666e:	4601                	li	a2,0
    80006670:	85a6                	mv	a1,s1
    80006672:	854a                	mv	a0,s2
    80006674:	ffffb097          	auipc	ra,0xffffb
    80006678:	9ba080e7          	jalr	-1606(ra) # 8000102e <walk>
    8000667c:	cd29                	beqz	a0,800066d6 <uvmcopy_copmp+0xc4>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000667e:	6118                	ld	a4,0(a0)
    80006680:	00177793          	andi	a5,a4,1
    80006684:	c3ad                	beqz	a5,800066e6 <uvmcopy_copmp+0xd4>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80006686:	00a75693          	srli	a3,a4,0xa
    flags = PTE_FLAGS(*pte);
    mappages(new, i, PGSIZE, (uint64)pa, flags);
    8000668a:	3ff77713          	andi	a4,a4,1023
    8000668e:	06b2                	slli	a3,a3,0xc
    80006690:	6605                	lui	a2,0x1
    80006692:	85a6                	mv	a1,s1
    80006694:	854e                	mv	a0,s3
    80006696:	ffffb097          	auipc	ra,0xffffb
    8000669a:	a80080e7          	jalr	-1408(ra) # 80001116 <mappages>
  for(i = 0x80000000; i < 0x80400000; i += PGSIZE){
    8000669e:	6785                	lui	a5,0x1
    800066a0:	94be                	add	s1,s1,a5
    800066a2:	fd4496e3          	bne	s1,s4,8000666e <uvmcopy_copmp+0x5c>
    }
}
    800066a6:	70a2                	ld	ra,40(sp)
    800066a8:	7402                	ld	s0,32(sp)
    800066aa:	64e2                	ld	s1,24(sp)
    800066ac:	6942                	ld	s2,16(sp)
    800066ae:	69a2                	ld	s3,8(sp)
    800066b0:	6a02                	ld	s4,0(sp)
    800066b2:	6145                	addi	sp,sp,48
    800066b4:	8082                	ret
      panic("uvmcopy: pte should exist");
    800066b6:	00002517          	auipc	a0,0x2
    800066ba:	ad250513          	addi	a0,a0,-1326 # 80008188 <digits+0x148>
    800066be:	ffffa097          	auipc	ra,0xffffa
    800066c2:	e82080e7          	jalr	-382(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800066c6:	00002517          	auipc	a0,0x2
    800066ca:	ae250513          	addi	a0,a0,-1310 # 800081a8 <digits+0x168>
    800066ce:	ffffa097          	auipc	ra,0xffffa
    800066d2:	e72080e7          	jalr	-398(ra) # 80000540 <panic>
      panic("uvmcopy: pte should exist");
    800066d6:	00002517          	auipc	a0,0x2
    800066da:	ab250513          	addi	a0,a0,-1358 # 80008188 <digits+0x148>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	e62080e7          	jalr	-414(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800066e6:	00002517          	auipc	a0,0x2
    800066ea:	ac250513          	addi	a0,a0,-1342 # 800081a8 <digits+0x168>
    800066ee:	ffffa097          	auipc	ra,0xffffa
    800066f2:	e52080e7          	jalr	-430(ra) # 80000540 <panic>

00000000800066f6 <find_csr>:
        uvmunmap(vm_state.vm_ptable, 0x0000000080000000, 1, 0);
        p->pagetable = vm_state.vm_ptable;
    }
}

int find_csr(unsigned int uimm){
    800066f6:	1141                	addi	sp,sp,-16
    800066f8:	e422                	sd	s0,8(sp)
    800066fa:	0800                	addi	s0,sp,16
    800066fc:	86aa                	mv	a3,a0
    for (int i = 0; i < REG_COUNT; i++) {
    800066fe:	0001c797          	auipc	a5,0x1c
    80006702:	97278793          	addi	a5,a5,-1678 # 80022070 <vm_state>
    80006706:	4501                	li	a0,0
    80006708:	02800613          	li	a2,40
        if (vm_state.reg_array[i].code == uimm) {
    8000670c:	4398                	lw	a4,0(a5)
    8000670e:	00d70763          	beq	a4,a3,8000671c <find_csr+0x26>
    for (int i = 0; i < REG_COUNT; i++) {
    80006712:	2505                	addiw	a0,a0,1
    80006714:	07c1                	addi	a5,a5,16
    80006716:	fec51be3          	bne	a0,a2,8000670c <find_csr+0x16>
            return i;
        }
    }
    return -1;
    8000671a:	557d                	li	a0,-1
}
    8000671c:	6422                	ld	s0,8(sp)
    8000671e:	0141                	addi	sp,sp,16
    80006720:	8082                	ret

0000000080006722 <ecall_manager>:
        trap_and_emulate_init();
    }
    p->trapframe->epc += 4;
}

void ecall_manager(struct proc *p){
    80006722:	1141                	addi	sp,sp,-16
    80006724:	e422                	sd	s0,8(sp)
    80006726:	0800                	addi	s0,sp,16
    vm_state.reg_array[SEPC].val = p->trapframe->epc;
    80006728:	6d3c                	ld	a5,88(a0)
    8000672a:	6f98                	ld	a4,24(a5)
    8000672c:	0001c797          	auipc	a5,0x1c
    80006730:	94478793          	addi	a5,a5,-1724 # 80022070 <vm_state>
    80006734:	fff8                	sd	a4,248(a5)
    p->trapframe->epc = vm_state.reg_array[STVEC].val;
    80006736:	6d38                	ld	a4,88(a0)
    80006738:	67f4                	ld	a3,200(a5)
    8000673a:	ef14                	sd	a3,24(a4)
    vm_state.priv_mode = 1;
    8000673c:	4705                	li	a4,1
    8000673e:	28e7a023          	sw	a4,640(a5)
}
    80006742:	6422                	ld	s0,8(sp)
    80006744:	0141                	addi	sp,sp,16
    80006746:	8082                	ret

0000000080006748 <trap_and_emulate_init>:
            trap_and_emulate_init();
        }
    }
}

void trap_and_emulate_init(void) {
    80006748:	1141                	addi	sp,sp,-16
    8000674a:	e422                	sd	s0,8(sp)
    8000674c:	0800                	addi	s0,sp,16
    /* Create and initialize all state for the VM */
    vm_state.is_pmp = false;
    8000674e:	0001c797          	auipc	a5,0x1c
    80006752:	92278793          	addi	a5,a5,-1758 # 80022070 <vm_state>
    80006756:	28078223          	sb	zero,644(a5)

    // User trap init
    vm_state.reg_array[0] = (vm_reg){.code = 0x000, .mode = 0, .val = 0};
    8000675a:	0007a023          	sw	zero,0(a5)
    8000675e:	0007a223          	sw	zero,4(a5)
    80006762:	0007b423          	sd	zero,8(a5)
    vm_state.reg_array[1] = (vm_reg){.code = 0x004, .mode = 0, .val = 0};
    80006766:	4711                	li	a4,4
    80006768:	cb98                	sw	a4,16(a5)
    8000676a:	0007aa23          	sw	zero,20(a5)
    8000676e:	0007bc23          	sd	zero,24(a5)
    vm_state.reg_array[2] = (vm_reg){.code = 0x005, .mode = 0, .val = 0};
    80006772:	4715                	li	a4,5
    80006774:	d398                	sw	a4,32(a5)
    80006776:	0207a223          	sw	zero,36(a5)
    8000677a:	0207b423          	sd	zero,40(a5)

    // User trap handling init
    vm_state.reg_array[3] = (vm_reg){.code = 0x040, .mode = 0, .val = 0};
    8000677e:	04000713          	li	a4,64
    80006782:	db98                	sw	a4,48(a5)
    80006784:	0207aa23          	sw	zero,52(a5)
    80006788:	0207bc23          	sd	zero,56(a5)
    vm_state.reg_array[4] = (vm_reg){.code = 0x041, .mode = 0, .val = 0};
    8000678c:	04100713          	li	a4,65
    80006790:	c3b8                	sw	a4,64(a5)
    80006792:	0407a223          	sw	zero,68(a5)
    80006796:	0407b423          	sd	zero,72(a5)
    vm_state.reg_array[5] = (vm_reg){.code = 0x042, .mode = 0, .val = 0};
    8000679a:	04200713          	li	a4,66
    8000679e:	cbb8                	sw	a4,80(a5)
    800067a0:	0407aa23          	sw	zero,84(a5)
    800067a4:	0407bc23          	sd	zero,88(a5)
    vm_state.reg_array[6] = (vm_reg){.code = 0x043, .mode = 0, .val = 0};
    800067a8:	04300713          	li	a4,67
    800067ac:	d3b8                	sw	a4,96(a5)
    800067ae:	0607a223          	sw	zero,100(a5)
    800067b2:	0607b423          	sd	zero,104(a5)
    vm_state.reg_array[7] = (vm_reg){.code = 0x044, .mode = 0, .val = 0};
    800067b6:	04400713          	li	a4,68
    800067ba:	dbb8                	sw	a4,112(a5)
    800067bc:	0607aa23          	sw	zero,116(a5)
    800067c0:	0607bc23          	sd	zero,120(a5)

    // Supervisor trap setup init
    vm_state.reg_array[8] = (vm_reg){.code = 0x100, .mode = 1, .val = 0};
    800067c4:	10000713          	li	a4,256
    800067c8:	08e7a023          	sw	a4,128(a5)
    800067cc:	4705                	li	a4,1
    800067ce:	08e7a223          	sw	a4,132(a5)
    800067d2:	0807b423          	sd	zero,136(a5)
    vm_state.reg_array[9] = (vm_reg){.code = 0x102, .mode = 1, .val = 0};
    800067d6:	10200693          	li	a3,258
    800067da:	08d7a823          	sw	a3,144(a5)
    800067de:	08e7aa23          	sw	a4,148(a5)
    800067e2:	0807bc23          	sd	zero,152(a5)
    vm_state.reg_array[10] = (vm_reg){.code = 0x103, .mode = 1, .val = 0};
    800067e6:	10300693          	li	a3,259
    800067ea:	0ad7a023          	sw	a3,160(a5)
    800067ee:	0ae7a223          	sw	a4,164(a5)
    800067f2:	0a07b423          	sd	zero,168(a5)
    vm_state.reg_array[11] = (vm_reg){.code = 0x104, .mode = 1, .val = 0};
    800067f6:	10400693          	li	a3,260
    800067fa:	0ad7a823          	sw	a3,176(a5)
    800067fe:	0ae7aa23          	sw	a4,180(a5)
    80006802:	0a07bc23          	sd	zero,184(a5)
    vm_state.reg_array[12] = (vm_reg){.code = 0x105, .mode = 1, .val = 0};
    80006806:	10500693          	li	a3,261
    8000680a:	0cd7a023          	sw	a3,192(a5)
    8000680e:	0ce7a223          	sw	a4,196(a5)
    80006812:	0c07b423          	sd	zero,200(a5)
    vm_state.reg_array[13] = (vm_reg){.code = 0x106, .mode = 1, .val = 0};
    80006816:	10600693          	li	a3,262
    8000681a:	0cd7a823          	sw	a3,208(a5)
    8000681e:	0ce7aa23          	sw	a4,212(a5)
    80006822:	0c07bc23          	sd	zero,216(a5)


    // Supervisor trap handling init
    vm_state.reg_array[14] = (vm_reg){.code = 0x140, .mode = 1, .val = 0};
    80006826:	14000693          	li	a3,320
    8000682a:	0ed7a023          	sw	a3,224(a5)
    8000682e:	0ee7a223          	sw	a4,228(a5)
    80006832:	0e07b423          	sd	zero,232(a5)
    vm_state.reg_array[15] = (vm_reg){.code = 0x141, .mode = 1, .val = 0};
    80006836:	14100693          	li	a3,321
    8000683a:	0ed7a823          	sw	a3,240(a5)
    8000683e:	0ee7aa23          	sw	a4,244(a5)
    80006842:	0e07bc23          	sd	zero,248(a5)
    vm_state.reg_array[16] = (vm_reg){.code = 0x142, .mode = 1, .val = 0};
    80006846:	14200693          	li	a3,322
    8000684a:	10d7a023          	sw	a3,256(a5)
    8000684e:	10e7a223          	sw	a4,260(a5)
    80006852:	1007b423          	sd	zero,264(a5)
    vm_state.reg_array[17] = (vm_reg){.code = 0x143, .mode = 1, .val = 0};
    80006856:	14300693          	li	a3,323
    8000685a:	10d7a823          	sw	a3,272(a5)
    8000685e:	10e7aa23          	sw	a4,276(a5)
    80006862:	1007bc23          	sd	zero,280(a5)
    vm_state.reg_array[18] = (vm_reg){.code = 0x144, .mode = 1, .val = 0};
    80006866:	14400693          	li	a3,324
    8000686a:	12d7a023          	sw	a3,288(a5)
    8000686e:	12e7a223          	sw	a4,292(a5)
    80006872:	1207b423          	sd	zero,296(a5)

    // Supervisor page table register
    vm_state.reg_array[19] = (vm_reg){.code = 0x180, .mode = 1, .val = 0};
    80006876:	18000693          	li	a3,384
    8000687a:	12d7a823          	sw	a3,304(a5)
    8000687e:	12e7aa23          	sw	a4,308(a5)
    80006882:	1207bc23          	sd	zero,312(a5)


    // Machine information registers init
    vm_state.reg_array[20] = (vm_reg){.code = 0xf11, .mode = 1, .val = 0x637365353336}; // hexa code for CSE536
    80006886:	6685                	lui	a3,0x1
    80006888:	f1168613          	addi	a2,a3,-239 # f11 <_entry-0x7ffff0ef>
    8000688c:	14c7a023          	sw	a2,320(a5)
    80006890:	14e7a223          	sw	a4,324(a5)
    80006894:	00001717          	auipc	a4,0x1
    80006898:	77473703          	ld	a4,1908(a4) # 80008008 <etext+0x8>
    8000689c:	14e7b423          	sd	a4,328(a5)
    vm_state.reg_array[21] = (vm_reg){.code = 0xf12, .mode = 2, .val = 0};
    800068a0:	f1268713          	addi	a4,a3,-238
    800068a4:	14e7a823          	sw	a4,336(a5)
    800068a8:	4709                	li	a4,2
    800068aa:	14e7aa23          	sw	a4,340(a5)
    800068ae:	1407bc23          	sd	zero,344(a5)
    vm_state.reg_array[22] = (vm_reg){.code = 0xf13, .mode = 2, .val = 0};
    800068b2:	f1368613          	addi	a2,a3,-237
    800068b6:	16c7a023          	sw	a2,352(a5)
    800068ba:	16e7a223          	sw	a4,356(a5)
    800068be:	1607b423          	sd	zero,360(a5)
    vm_state.reg_array[23] = (vm_reg){.code = 0xf14, .mode = 2, .val = 0};
    800068c2:	f1468693          	addi	a3,a3,-236
    800068c6:	16d7a823          	sw	a3,368(a5)
    800068ca:	16e7aa23          	sw	a4,372(a5)
    800068ce:	1607bc23          	sd	zero,376(a5)

    // Machine trap setup registers init
    vm_state.reg_array[24] = (vm_reg){.code = 0x300, .mode = 2, .val = 0};
    800068d2:	30000693          	li	a3,768
    800068d6:	18d7a023          	sw	a3,384(a5)
    800068da:	18e7a223          	sw	a4,388(a5)
    800068de:	1807b423          	sd	zero,392(a5)
    vm_state.reg_array[25] = (vm_reg){.code = 0x301, .mode = 2, .val = 0};
    800068e2:	30100693          	li	a3,769
    800068e6:	18d7a823          	sw	a3,400(a5)
    800068ea:	18e7aa23          	sw	a4,404(a5)
    800068ee:	1807bc23          	sd	zero,408(a5)
    vm_state.reg_array[26] = (vm_reg){.code = 0x302, .mode = 2, .val = 0};
    800068f2:	30200693          	li	a3,770
    800068f6:	1ad7a023          	sw	a3,416(a5)
    800068fa:	1ae7a223          	sw	a4,420(a5)
    800068fe:	1a07b423          	sd	zero,424(a5)
    vm_state.reg_array[27] = (vm_reg){.code = 0x303, .mode = 2, .val = 0};
    80006902:	30300693          	li	a3,771
    80006906:	1ad7a823          	sw	a3,432(a5)
    8000690a:	1ae7aa23          	sw	a4,436(a5)
    8000690e:	1a07bc23          	sd	zero,440(a5)
    vm_state.reg_array[28] = (vm_reg){.code = 0x304, .mode = 2, .val = 0};
    80006912:	30400693          	li	a3,772
    80006916:	1cd7a023          	sw	a3,448(a5)
    8000691a:	1ce7a223          	sw	a4,452(a5)
    8000691e:	1c07b423          	sd	zero,456(a5)
    vm_state.reg_array[29] = (vm_reg){.code = 0x305, .mode = 2, .val = 0};
    80006922:	30500693          	li	a3,773
    80006926:	1cd7a823          	sw	a3,464(a5)
    8000692a:	1ce7aa23          	sw	a4,468(a5)
    8000692e:	1c07bc23          	sd	zero,472(a5)
    vm_state.reg_array[30] = (vm_reg){.code = 0x306, .mode = 2, .val = 0};
    80006932:	30600693          	li	a3,774
    80006936:	1ed7a023          	sw	a3,480(a5)
    8000693a:	1ee7a223          	sw	a4,484(a5)
    8000693e:	1e07b423          	sd	zero,488(a5)

    // Machine trap handling registers init
    vm_state.reg_array[31] = (vm_reg){.code = 0x340, .mode = 2, .val = 0};
    80006942:	34000693          	li	a3,832
    80006946:	1ed7a823          	sw	a3,496(a5)
    8000694a:	1ee7aa23          	sw	a4,500(a5)
    8000694e:	1e07bc23          	sd	zero,504(a5)
    vm_state.reg_array[32] = (vm_reg){.code = 0x341, .mode = 2, .val = 0};
    80006952:	34100693          	li	a3,833
    80006956:	20d7a023          	sw	a3,512(a5)
    8000695a:	20e7a223          	sw	a4,516(a5)
    8000695e:	2007b423          	sd	zero,520(a5)
    vm_state.reg_array[33] = (vm_reg){.code = 0x342, .mode = 2, .val = 0};
    80006962:	34200693          	li	a3,834
    80006966:	20d7a823          	sw	a3,528(a5)
    8000696a:	20e7aa23          	sw	a4,532(a5)
    8000696e:	2007bc23          	sd	zero,536(a5)
    vm_state.reg_array[34] = (vm_reg){.code = 0x343, .mode = 2, .val = 0};
    80006972:	34300693          	li	a3,835
    80006976:	22d7a023          	sw	a3,544(a5)
    8000697a:	22e7a223          	sw	a4,548(a5)
    8000697e:	2207b423          	sd	zero,552(a5)
    vm_state.reg_array[35] = (vm_reg){.code = 0x344, .mode = 2, .val = 0};
    80006982:	34400693          	li	a3,836
    80006986:	22d7a823          	sw	a3,560(a5)
    8000698a:	22e7aa23          	sw	a4,564(a5)
    8000698e:	2207bc23          	sd	zero,568(a5)
    vm_state.reg_array[36] = (vm_reg){.code = 0x34a, .mode = 2, .val = 0};
    80006992:	34a00693          	li	a3,842
    80006996:	24d7a023          	sw	a3,576(a5)
    8000699a:	24e7a223          	sw	a4,580(a5)
    8000699e:	2407b423          	sd	zero,584(a5)
    vm_state.reg_array[37] = (vm_reg){.code = 0x34b, .mode = 2, .val = 0};
    800069a2:	34b00693          	li	a3,843
    800069a6:	24d7a823          	sw	a3,592(a5)
    800069aa:	24e7aa23          	sw	a4,596(a5)
    800069ae:	2407bc23          	sd	zero,600(a5)
    
    // pmp register init
    vm_state.reg_array[38] = (vm_reg){.code = 0x3a0, .mode = 2, .val = 0};
    800069b2:	3a000693          	li	a3,928
    800069b6:	26d7a023          	sw	a3,608(a5)
    800069ba:	26e7a223          	sw	a4,612(a5)
    800069be:	2607b423          	sd	zero,616(a5)
    vm_state.reg_array[39] = (vm_reg){.code = 0x3b0, .mode = 2, .val = 0};
    800069c2:	3b000693          	li	a3,944
    800069c6:	26d7a823          	sw	a3,624(a5)
    800069ca:	26e7aa23          	sw	a4,628(a5)
    800069ce:	2607bc23          	sd	zero,632(a5)

    vm_state.priv_mode = 2;
    800069d2:	28e7a023          	sw	a4,640(a5)
    vm_state.vm_ptable = NULL;
    800069d6:	2807b423          	sd	zero,648(a5)
}
    800069da:	6422                	ld	s0,8(sp)
    800069dc:	0141                	addi	sp,sp,16
    800069de:	8082                	ret

00000000800069e0 <sret_manager>:
    if(vm_state.priv_mode >= 1){
    800069e0:	0001c797          	auipc	a5,0x1c
    800069e4:	9107a783          	lw	a5,-1776(a5) # 800222f0 <vm_state+0x280>
    800069e8:	02f05863          	blez	a5,80006a18 <sret_manager+0x38>
        unsigned long sstatus = vm_state.reg_array[SSTATUS].val;
    800069ec:	0001b697          	auipc	a3,0x1b
    800069f0:	68468693          	addi	a3,a3,1668 # 80022070 <vm_state>
    800069f4:	66d8                	ld	a4,136(a3)
        sstatus &= ~(1UL << 8); // Clear the SPP bit
    800069f6:	eff77613          	andi	a2,a4,-257
        sstatus |= spie_bit << 1; // set SIE bit to SPIE
    800069fa:	00465793          	srli	a5,a2,0x4
    800069fe:	8b89                	andi	a5,a5,2
    80006a00:	8fd1                	or	a5,a5,a2
        unsigned long spp_bit = (sstatus >> 8) & 0x1; // get SPP bit
    80006a02:	8321                	srli	a4,a4,0x8
        if(spp_bit){
    80006a04:	8b05                	andi	a4,a4,1
    80006a06:	28e6a023          	sw	a4,640(a3)
        sstatus &= ~(1UL << 5); // set SPIE bit to 1
    80006a0a:	fdf7f793          	andi	a5,a5,-33
        vm_state.reg_array[SSTATUS].val = sstatus; // write sstatus register
    80006a0e:	e6dc                	sd	a5,136(a3)
        p->trapframe->epc = vm_state.reg_array[SEPC].val; // set the program count to the value of sepc
    80006a10:	6d3c                	ld	a5,88(a0)
    80006a12:	7ef8                	ld	a4,248(a3)
    80006a14:	ef98                	sd	a4,24(a5)
    80006a16:	8082                	ret
void sret_manager(struct proc *p){
    80006a18:	1141                	addi	sp,sp,-16
    80006a1a:	e406                	sd	ra,8(sp)
    80006a1c:	e022                	sd	s0,0(sp)
    80006a1e:	0800                	addi	s0,sp,16
        setkilled(p);
    80006a20:	ffffc097          	auipc	ra,0xffffc
    80006a24:	956080e7          	jalr	-1706(ra) # 80002376 <setkilled>
        trap_and_emulate_init();
    80006a28:	00000097          	auipc	ra,0x0
    80006a2c:	d20080e7          	jalr	-736(ra) # 80006748 <trap_and_emulate_init>
}
    80006a30:	60a2                	ld	ra,8(sp)
    80006a32:	6402                	ld	s0,0(sp)
    80006a34:	0141                	addi	sp,sp,16
    80006a36:	8082                	ret

0000000080006a38 <mret_manager>:
void mret_manager(struct proc *p){
    80006a38:	1101                	addi	sp,sp,-32
    80006a3a:	ec06                	sd	ra,24(sp)
    80006a3c:	e822                	sd	s0,16(sp)
    80006a3e:	e426                	sd	s1,8(sp)
    80006a40:	e04a                	sd	s2,0(sp)
    80006a42:	1000                	addi	s0,sp,32
    80006a44:	84aa                	mv	s1,a0
    if(vm_state.priv_mode >= 2){
    80006a46:	0001c717          	auipc	a4,0x1c
    80006a4a:	8aa72703          	lw	a4,-1878(a4) # 800222f0 <vm_state+0x280>
    80006a4e:	4785                	li	a5,1
    80006a50:	04e7d063          	bge	a5,a4,80006a90 <mret_manager+0x58>
        unsigned long mstatus = vm_state.reg_array[MSTATUS].val;
    80006a54:	0001b797          	auipc	a5,0x1b
    80006a58:	61c78793          	addi	a5,a5,1564 # 80022070 <vm_state>
    80006a5c:	1887b703          	ld	a4,392(a5)
        unsigned long int mpp = (mstatus >> 11) & 0x1; // Extract the previous privilege level (mpp)
    80006a60:	00b75693          	srli	a3,a4,0xb
        if(mpp){
    80006a64:	8a85                	andi	a3,a3,1
    80006a66:	28d7a023          	sw	a3,640(a5)
        mstatus &= (1 << 0x7); // set MPIE bit to 1
    80006a6a:	08077713          	andi	a4,a4,128
        vm_state.reg_array[MSTATUS].val = mstatus; // write mstatus register
    80006a6e:	18e7b423          	sd	a4,392(a5)
        p->trapframe->epc = vm_state.reg_array[MEPC].val; // set the program count to the value of mepc
    80006a72:	6d38                	ld	a4,88(a0)
    80006a74:	2087b783          	ld	a5,520(a5)
    80006a78:	ef1c                	sd	a5,24(a4)
    if(vm_state.is_pmp){
    80006a7a:	0001c797          	auipc	a5,0x1c
    80006a7e:	87a7c783          	lbu	a5,-1926(a5) # 800222f4 <vm_state+0x284>
    80006a82:	e385                	bnez	a5,80006aa2 <mret_manager+0x6a>
}
    80006a84:	60e2                	ld	ra,24(sp)
    80006a86:	6442                	ld	s0,16(sp)
    80006a88:	64a2                	ld	s1,8(sp)
    80006a8a:	6902                	ld	s2,0(sp)
    80006a8c:	6105                	addi	sp,sp,32
    80006a8e:	8082                	ret
        setkilled(p);
    80006a90:	ffffc097          	auipc	ra,0xffffc
    80006a94:	8e6080e7          	jalr	-1818(ra) # 80002376 <setkilled>
        trap_and_emulate_init();
    80006a98:	00000097          	auipc	ra,0x0
    80006a9c:	cb0080e7          	jalr	-848(ra) # 80006748 <trap_and_emulate_init>
    80006aa0:	bfe9                	j	80006a7a <mret_manager+0x42>
        vm_state.vm_ptable = proc_pagetable(p);
    80006aa2:	8526                	mv	a0,s1
    80006aa4:	ffffb097          	auipc	ra,0xffffb
    80006aa8:	044080e7          	jalr	68(ra) # 80001ae8 <proc_pagetable>
    80006aac:	85aa                	mv	a1,a0
    80006aae:	0001b917          	auipc	s2,0x1b
    80006ab2:	5c290913          	addi	s2,s2,1474 # 80022070 <vm_state>
    80006ab6:	28a93423          	sd	a0,648(s2)
        uvmcopy_copmp(p->pagetable, vm_state.vm_ptable, p->sz);
    80006aba:	64b0                	ld	a2,72(s1)
    80006abc:	68a8                	ld	a0,80(s1)
    80006abe:	00000097          	auipc	ra,0x0
    80006ac2:	b54080e7          	jalr	-1196(ra) # 80006612 <uvmcopy_copmp>
        uvmunmap(vm_state.vm_ptable, 0x0000000080000000, 1, 0);
    80006ac6:	4681                	li	a3,0
    80006ac8:	4605                	li	a2,1
    80006aca:	4585                	li	a1,1
    80006acc:	05fe                	slli	a1,a1,0x1f
    80006ace:	28893503          	ld	a0,648(s2)
    80006ad2:	ffffb097          	auipc	ra,0xffffb
    80006ad6:	80a080e7          	jalr	-2038(ra) # 800012dc <uvmunmap>
        p->pagetable = vm_state.vm_ptable;
    80006ada:	28893783          	ld	a5,648(s2)
    80006ade:	e8bc                	sd	a5,80(s1)
}
    80006ae0:	b755                	j	80006a84 <mret_manager+0x4c>

0000000080006ae2 <csrr_manager>:
void csrr_manager(struct proc *p, unsigned int rs1, unsigned int rd, unsigned int uimm){
    80006ae2:	1101                	addi	sp,sp,-32
    80006ae4:	ec06                	sd	ra,24(sp)
    80006ae6:	e822                	sd	s0,16(sp)
    80006ae8:	e426                	sd	s1,8(sp)
    80006aea:	e04a                	sd	s2,0(sp)
    80006aec:	1000                	addi	s0,sp,32
    80006aee:	84aa                	mv	s1,a0
    80006af0:	8932                	mv	s2,a2
    int csr_idx = find_csr(uimm);
    80006af2:	8536                	mv	a0,a3
    80006af4:	00000097          	auipc	ra,0x0
    80006af8:	c02080e7          	jalr	-1022(ra) # 800066f6 <find_csr>
    if(csr_idx == -1) return;
    80006afc:	57fd                	li	a5,-1
    80006afe:	04f50263          	beq	a0,a5,80006b42 <csrr_manager+0x60>
    if(vm_state.priv_mode >= vm_state.reg_array[csr_idx].mode){
    80006b02:	0001b717          	auipc	a4,0x1b
    80006b06:	56e70713          	addi	a4,a4,1390 # 80022070 <vm_state>
    80006b0a:	00451793          	slli	a5,a0,0x4
    80006b0e:	97ba                	add	a5,a5,a4
    80006b10:	28072703          	lw	a4,640(a4)
    80006b14:	43dc                	lw	a5,4(a5)
    80006b16:	02f74c63          	blt	a4,a5,80006b4e <csrr_manager+0x6c>
        *rd_reg_ptr = csr_value;    
    80006b1a:	6cb8                	ld	a4,88(s1)
    80006b1c:	02091793          	slli	a5,s2,0x20
    80006b20:	01d7d613          	srli	a2,a5,0x1d
    80006b24:	9732                	add	a4,a4,a2
        uint32 csr_value = vm_state.reg_array[csr_idx].val;
    80006b26:	00451793          	slli	a5,a0,0x4
    80006b2a:	0001b697          	auipc	a3,0x1b
    80006b2e:	54668693          	addi	a3,a3,1350 # 80022070 <vm_state>
    80006b32:	97b6                	add	a5,a5,a3
        *rd_reg_ptr = csr_value;    
    80006b34:	0087e783          	lwu	a5,8(a5)
    80006b38:	f31c                	sd	a5,32(a4)
    p->trapframe->epc += 4;
    80006b3a:	6cb8                	ld	a4,88(s1)
    80006b3c:	6f1c                	ld	a5,24(a4)
    80006b3e:	0791                	addi	a5,a5,4
    80006b40:	ef1c                	sd	a5,24(a4)
}
    80006b42:	60e2                	ld	ra,24(sp)
    80006b44:	6442                	ld	s0,16(sp)
    80006b46:	64a2                	ld	s1,8(sp)
    80006b48:	6902                	ld	s2,0(sp)
    80006b4a:	6105                	addi	sp,sp,32
    80006b4c:	8082                	ret
        setkilled(p);
    80006b4e:	8526                	mv	a0,s1
    80006b50:	ffffc097          	auipc	ra,0xffffc
    80006b54:	826080e7          	jalr	-2010(ra) # 80002376 <setkilled>
        trap_and_emulate_init();
    80006b58:	00000097          	auipc	ra,0x0
    80006b5c:	bf0080e7          	jalr	-1040(ra) # 80006748 <trap_and_emulate_init>
    80006b60:	bfe9                	j	80006b3a <csrr_manager+0x58>

0000000080006b62 <csrw_manager>:
void csrw_manager(struct proc *p, unsigned int rs1, unsigned int rd, unsigned int uimm){
    80006b62:	7179                	addi	sp,sp,-48
    80006b64:	f406                	sd	ra,40(sp)
    80006b66:	f022                	sd	s0,32(sp)
    80006b68:	ec26                	sd	s1,24(sp)
    80006b6a:	e84a                	sd	s2,16(sp)
    80006b6c:	e44e                	sd	s3,8(sp)
    80006b6e:	e052                	sd	s4,0(sp)
    80006b70:	1800                	addi	s0,sp,48
    80006b72:	892a                	mv	s2,a0
    80006b74:	8a2e                	mv	s4,a1
    int csr_idx = find_csr(uimm);
    80006b76:	8536                	mv	a0,a3
    80006b78:	00000097          	auipc	ra,0x0
    80006b7c:	b7e080e7          	jalr	-1154(ra) # 800066f6 <find_csr>
    if(csr_idx == -1) return;
    80006b80:	57fd                	li	a5,-1
    80006b82:	06f50363          	beq	a0,a5,80006be8 <csrw_manager+0x86>
    80006b86:	84aa                	mv	s1,a0
    if(vm_state.priv_mode >= vm_state.reg_array[csr_idx].mode){
    80006b88:	0001b717          	auipc	a4,0x1b
    80006b8c:	4e870713          	addi	a4,a4,1256 # 80022070 <vm_state>
    80006b90:	00451793          	slli	a5,a0,0x4
    80006b94:	97ba                	add	a5,a5,a4
    80006b96:	28072703          	lw	a4,640(a4)
    80006b9a:	43dc                	lw	a5,4(a5)
    80006b9c:	06f74b63          	blt	a4,a5,80006c12 <csrw_manager+0xb0>
        uint64* rs1_ptr= &(p->trapframe->ra) + rs1 - 1;
    80006ba0:	05893983          	ld	s3,88(s2)
    80006ba4:	020a1793          	slli	a5,s4,0x20
    80006ba8:	01d7d593          	srli	a1,a5,0x1d
    80006bac:	99ae                	add	s3,s3,a1
    80006bae:	02098993          	addi	s3,s3,32
        if((csr_idx == MACVENDORID) && (*rs1_ptr == 0x0)){ // invalid write operation for machineVendorId register
    80006bb2:	47d1                	li	a5,20
    80006bb4:	04f50263          	beq	a0,a5,80006bf8 <csrw_manager+0x96>
        if((csr_idx == PMPADDR0) || (csr_idx == PMPCFG0)){
    80006bb8:	fda5079b          	addiw	a5,a0,-38
    80006bbc:	4705                	li	a4,1
    80006bbe:	00f76763          	bltu	a4,a5,80006bcc <csrw_manager+0x6a>
            vm_state.is_pmp = true;
    80006bc2:	4785                	li	a5,1
    80006bc4:	0001b717          	auipc	a4,0x1b
    80006bc8:	72f70823          	sb	a5,1840(a4) # 800222f4 <vm_state+0x284>
        vm_state.reg_array[csr_idx].val = *rs1_ptr;
    80006bcc:	0009b703          	ld	a4,0(s3)
    80006bd0:	0492                	slli	s1,s1,0x4
    80006bd2:	0001b797          	auipc	a5,0x1b
    80006bd6:	49e78793          	addi	a5,a5,1182 # 80022070 <vm_state>
    80006bda:	97a6                	add	a5,a5,s1
    80006bdc:	e798                	sd	a4,8(a5)
    p->trapframe->epc += 4;
    80006bde:	05893703          	ld	a4,88(s2)
    80006be2:	6f1c                	ld	a5,24(a4)
    80006be4:	0791                	addi	a5,a5,4
    80006be6:	ef1c                	sd	a5,24(a4)
}
    80006be8:	70a2                	ld	ra,40(sp)
    80006bea:	7402                	ld	s0,32(sp)
    80006bec:	64e2                	ld	s1,24(sp)
    80006bee:	6942                	ld	s2,16(sp)
    80006bf0:	69a2                	ld	s3,8(sp)
    80006bf2:	6a02                	ld	s4,0(sp)
    80006bf4:	6145                	addi	sp,sp,48
    80006bf6:	8082                	ret
        if((csr_idx == MACVENDORID) && (*rs1_ptr == 0x0)){ // invalid write operation for machineVendorId register
    80006bf8:	0009b783          	ld	a5,0(s3)
    80006bfc:	fbe1                	bnez	a5,80006bcc <csrw_manager+0x6a>
            setkilled(p);
    80006bfe:	854a                	mv	a0,s2
    80006c00:	ffffb097          	auipc	ra,0xffffb
    80006c04:	776080e7          	jalr	1910(ra) # 80002376 <setkilled>
            trap_and_emulate_init();
    80006c08:	00000097          	auipc	ra,0x0
    80006c0c:	b40080e7          	jalr	-1216(ra) # 80006748 <trap_and_emulate_init>
    80006c10:	bf75                	j	80006bcc <csrw_manager+0x6a>
        setkilled(p);
    80006c12:	854a                	mv	a0,s2
    80006c14:	ffffb097          	auipc	ra,0xffffb
    80006c18:	762080e7          	jalr	1890(ra) # 80002376 <setkilled>
        trap_and_emulate_init();
    80006c1c:	00000097          	auipc	ra,0x0
    80006c20:	b2c080e7          	jalr	-1236(ra) # 80006748 <trap_and_emulate_init>
    80006c24:	bf6d                	j	80006bde <csrw_manager+0x7c>

0000000080006c26 <trap_and_emulate>:
void trap_and_emulate(void) {
    80006c26:	7139                	addi	sp,sp,-64
    80006c28:	fc06                	sd	ra,56(sp)
    80006c2a:	f822                	sd	s0,48(sp)
    80006c2c:	f426                	sd	s1,40(sp)
    80006c2e:	f04a                	sd	s2,32(sp)
    80006c30:	ec4e                	sd	s3,24(sp)
    80006c32:	e852                	sd	s4,16(sp)
    80006c34:	e456                	sd	s5,8(sp)
    80006c36:	e05a                	sd	s6,0(sp)
    80006c38:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80006c3a:	ffffb097          	auipc	ra,0xffffb
    80006c3e:	dea080e7          	jalr	-534(ra) # 80001a24 <myproc>
    80006c42:	84aa                	mv	s1,a0
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80006c44:	141029f3          	csrr	s3,sepc
    uint64 addr     = walkaddr(p->pagetable, virtual_addr) | (virtual_addr & 0xFFF);
    80006c48:	85ce                	mv	a1,s3
    80006c4a:	6928                	ld	a0,80(a0)
    80006c4c:	ffffa097          	auipc	ra,0xffffa
    80006c50:	488080e7          	jalr	1160(ra) # 800010d4 <walkaddr>
    80006c54:	03499793          	slli	a5,s3,0x34
    80006c58:	93d1                	srli	a5,a5,0x34
    80006c5a:	8fc9                	or	a5,a5,a0
    uint32 instruction = *((uint32*)(addr));
    80006c5c:	4390                	lw	a2,0(a5)
    uint32 funct3   = (instruction >> 12) & 0x7;
    80006c5e:	00c6591b          	srliw	s2,a2,0xc
    80006c62:	00797913          	andi	s2,s2,7
    uint32 uimm     = (instruction >> 20) & 0xFFF;
    80006c66:	0146579b          	srliw	a5,a2,0x14
    80006c6a:	01465b1b          	srliw	s6,a2,0x14
    if((funct3 == 0x0) && (uimm == 0)){
    80006c6e:	00f967b3          	or	a5,s2,a5
    80006c72:	2781                	sext.w	a5,a5
    80006c74:	eb95                	bnez	a5,80006ca8 <trap_and_emulate+0x82>
        printf("(EC at %p)\n", p->trapframe->epc);
    80006c76:	6cbc                	ld	a5,88(s1)
    80006c78:	6f8c                	ld	a1,24(a5)
    80006c7a:	00002517          	auipc	a0,0x2
    80006c7e:	c8650513          	addi	a0,a0,-890 # 80008900 <syscalls+0x4a8>
    80006c82:	ffffa097          	auipc	ra,0xffffa
    80006c86:	908080e7          	jalr	-1784(ra) # 8000058a <printf>
        ecall_manager(p);
    80006c8a:	8526                	mv	a0,s1
    80006c8c:	00000097          	auipc	ra,0x0
    80006c90:	a96080e7          	jalr	-1386(ra) # 80006722 <ecall_manager>
}
    80006c94:	70e2                	ld	ra,56(sp)
    80006c96:	7442                	ld	s0,48(sp)
    80006c98:	74a2                	ld	s1,40(sp)
    80006c9a:	7902                	ld	s2,32(sp)
    80006c9c:	69e2                	ld	s3,24(sp)
    80006c9e:	6a42                	ld	s4,16(sp)
    80006ca0:	6aa2                	ld	s5,8(sp)
    80006ca2:	6b02                	ld	s6,0(sp)
    80006ca4:	6121                	addi	sp,sp,64
    80006ca6:	8082                	ret
    uint32 rd       = (instruction >> 7) & 0x1F;
    80006ca8:	00765a9b          	srliw	s5,a2,0x7
    80006cac:	01fafa93          	andi	s5,s5,31
    uint32 rs1      = (instruction >> 15) & 0x1F;
    80006cb0:	00f65a1b          	srliw	s4,a2,0xf
    80006cb4:	01fa7a13          	andi	s4,s4,31
        printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
    80006cb8:	885a                	mv	a6,s6
    80006cba:	87d2                	mv	a5,s4
    80006cbc:	874a                	mv	a4,s2
    80006cbe:	86d6                	mv	a3,s5
    80006cc0:	07f67613          	andi	a2,a2,127
    80006cc4:	85ce                	mv	a1,s3
    80006cc6:	00002517          	auipc	a0,0x2
    80006cca:	c4a50513          	addi	a0,a0,-950 # 80008910 <syscalls+0x4b8>
    80006cce:	ffffa097          	auipc	ra,0xffffa
    80006cd2:	8bc080e7          	jalr	-1860(ra) # 8000058a <printf>
        if((funct3 == 0x0) && (uimm == 0x102)){
    80006cd6:	04091c63          	bnez	s2,80006d2e <trap_and_emulate+0x108>
    80006cda:	10200793          	li	a5,258
    80006cde:	02fb0c63          	beq	s6,a5,80006d16 <trap_and_emulate+0xf0>
        else if((funct3 == 0x0) && (uimm == 0x302)){
    80006ce2:	30200793          	li	a5,770
    80006ce6:	02fb0e63          	beq	s6,a5,80006d22 <trap_and_emulate+0xfc>
            printf("Instruction is not correct.\n");
    80006cea:	00002517          	auipc	a0,0x2
    80006cee:	c6650513          	addi	a0,a0,-922 # 80008950 <syscalls+0x4f8>
    80006cf2:	ffffa097          	auipc	ra,0xffffa
    80006cf6:	898080e7          	jalr	-1896(ra) # 8000058a <printf>
            setkilled(p);
    80006cfa:	8526                	mv	a0,s1
    80006cfc:	ffffb097          	auipc	ra,0xffffb
    80006d00:	67a080e7          	jalr	1658(ra) # 80002376 <setkilled>
            host_ptable = NULL;
    80006d04:	00002797          	auipc	a5,0x2
    80006d08:	ce07ba23          	sd	zero,-780(a5) # 800089f8 <host_ptable>
            trap_and_emulate_init();
    80006d0c:	00000097          	auipc	ra,0x0
    80006d10:	a3c080e7          	jalr	-1476(ra) # 80006748 <trap_and_emulate_init>
}
    80006d14:	b741                	j	80006c94 <trap_and_emulate+0x6e>
            sret_manager(p);
    80006d16:	8526                	mv	a0,s1
    80006d18:	00000097          	auipc	ra,0x0
    80006d1c:	cc8080e7          	jalr	-824(ra) # 800069e0 <sret_manager>
    80006d20:	bf95                	j	80006c94 <trap_and_emulate+0x6e>
            mret_manager(p);
    80006d22:	8526                	mv	a0,s1
    80006d24:	00000097          	auipc	ra,0x0
    80006d28:	d14080e7          	jalr	-748(ra) # 80006a38 <mret_manager>
    80006d2c:	b7a5                	j	80006c94 <trap_and_emulate+0x6e>
        else if(funct3 == 0x1){
    80006d2e:	4785                	li	a5,1
    80006d30:	00f90e63          	beq	s2,a5,80006d4c <trap_and_emulate+0x126>
        else if(funct3 == 0x2){
    80006d34:	4789                	li	a5,2
    80006d36:	faf91ae3          	bne	s2,a5,80006cea <trap_and_emulate+0xc4>
            csrr_manager(p, rs1, rd, uimm);
    80006d3a:	86da                	mv	a3,s6
    80006d3c:	8656                	mv	a2,s5
    80006d3e:	85d2                	mv	a1,s4
    80006d40:	8526                	mv	a0,s1
    80006d42:	00000097          	auipc	ra,0x0
    80006d46:	da0080e7          	jalr	-608(ra) # 80006ae2 <csrr_manager>
    80006d4a:	b7a9                	j	80006c94 <trap_and_emulate+0x6e>
            csrw_manager(p, rs1, rd, uimm);
    80006d4c:	86da                	mv	a3,s6
    80006d4e:	8656                	mv	a2,s5
    80006d50:	85d2                	mv	a1,s4
    80006d52:	8526                	mv	a0,s1
    80006d54:	00000097          	auipc	ra,0x0
    80006d58:	e0e080e7          	jalr	-498(ra) # 80006b62 <csrw_manager>
    80006d5c:	bf25                	j	80006c94 <trap_and_emulate+0x6e>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
