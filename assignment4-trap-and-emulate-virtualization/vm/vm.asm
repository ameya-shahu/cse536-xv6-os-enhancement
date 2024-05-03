
vm/vm:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <_entry>:
   0:	00001117          	auipc	sp,0x1
   4:	01010113          	addi	sp,sp,16 # 1010 <stack0>
   8:	6505                	lui	a0,0x1
   a:	f14025f3          	csrr	a1,mhartid
   e:	0585                	addi	a1,a1,1
  10:	02b50533          	mul	a0,a0,a1
  14:	912a                	add	sp,sp,a0
  16:	006000ef          	jal	ra,1c <start>

000000000000001a <spin>:
  1a:	a001                	j	1a <spin>

000000000000001c <start>:
extern void _entry(void);

// entry.S jumps here in machine mode on stack0.
void
start()
{
  1c:	1141                	addi	sp,sp,-16
  1e:	e406                	sd	ra,8(sp)
  20:	e022                	sd	s0,0(sp)
  22:	0800                	addi	s0,sp,16
  assert_linker_symbols();
  24:	00000097          	auipc	ra,0x0
  28:	270080e7          	jalr	624(ra) # 294 <assert_linker_symbols>
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
  2c:	f14027f3          	csrr	a5,mhartid

  // keep each CPU's hartid in its tp register, for cpuid().
  int id = r_mhartid();
  w_tp(id);
  30:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
  32:	823e                	mv	tp,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
  34:	300027f3          	csrr	a5,mstatus

  // set M Previous Privilege mode to Supervisor, for mret.
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
  38:	7779                	lui	a4,0xffffe
  3a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <ustack+0xfffffffffffed71f>
  3e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
  40:	6705                	lui	a4,0x1
  42:	80070713          	addi	a4,a4,-2048 # 800 <process_entry+0x3d6>
  46:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
  48:	30079073          	csrw	mstatus,a5
  asm volatile("csrw satp, %0" : : "r" (x));
  4c:	4781                	li	a5,0
  4e:	18079073          	csrw	satp,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
  52:	200c07b7          	lui	a5,0x200c0
  56:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
  5a:	47bd                	li	a5,15
  5c:	3a079073          	csrw	pmpcfg0,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
  60:	00000797          	auipc	a5,0x0
  64:	3b878793          	addi	a5,a5,952 # 418 <kernel_entry>
  68:	34179073          	csrw	mepc,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
  6c:	67c1                	lui	a5,0x10
  6e:	17fd                	addi	a5,a5,-1 # ffff <kstack+0x6f1f>
  70:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
  74:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
  78:	104027f3          	csrr	a5,sie
  w_mepc((uint64)kernel_entry);
 
  // delegate all interrupts and exceptions to supervisor mode.
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
  7c:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
  80:	10479073          	csrw	sie,a5

  // switch to supervisor mode and jump to main().
  asm volatile("mret");
  84:	30200073          	mret
}
  88:	60a2                	ld	ra,8(sp)
  8a:	6402                	ld	s0,0(sp)
  8c:	0141                	addi	sp,sp,16
  8e:	8082                	ret

0000000000000090 <ramdiskrw>:

// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
ramdiskrw(struct buf *b)
{
  90:	1101                	addi	sp,sp,-32
  92:	ec06                	sd	ra,24(sp)
  94:	e822                	sd	s0,16(sp)
  96:	e426                	sd	s1,8(sp)
  98:	1000                	addi	s0,sp,32
  9a:	84aa                	mv	s1,a0
  /* Ramdisk is not even reading from the damn file.. */
  if(b->blockno >= FSSIZE)
  9c:	4558                	lw	a4,12(a0)
  9e:	7cf00793          	li	a5,1999
  a2:	02e7ea63          	bltu	a5,a4,d6 <userret+0x3a>
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
  a6:	44dc                	lw	a5,12(s1)
  a8:	00a7979b          	slliw	a5,a5,0xa
  ac:	1782                	slli	a5,a5,0x20
  ae:	9381                	srli	a5,a5,0x20
  char *addr = (char *)RAMDISK + diskaddr;

  // read from the location
  memmove(b->data, addr, BSIZE);
  b0:	40000613          	li	a2,1024
  b4:	02100593          	li	a1,33
  b8:	05ea                	slli	a1,a1,0x1a
  ba:	95be                	add	a1,a1,a5
  bc:	02848513          	addi	a0,s1,40
  c0:	00000097          	auipc	ra,0x0
  c4:	084080e7          	jalr	132(ra) # 144 <memmove>
  b->valid = 1;
  c8:	4785                	li	a5,1
  ca:	c09c                	sw	a5,0(s1)
}
  cc:	60e2                	ld	ra,24(sp)
  ce:	6442                	ld	s0,16(sp)
  d0:	64a2                	ld	s1,8(sp)
  d2:	6105                	addi	sp,sp,32
  d4:	8082                	ret
    panic("ramdiskrw: blockno too big");
  d6:	00000517          	auipc	a0,0x0
  da:	36a50513          	addi	a0,a0,874 # 440 <process_entry+0x16>
  de:	00000097          	auipc	ra,0x0
  e2:	1ae080e7          	jalr	430(ra) # 28c <panic>
  e6:	b7c1                	j	a6 <userret+0xa>

00000000000000e8 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
  e8:	1141                	addi	sp,sp,-16
  ea:	e422                	sd	s0,8(sp)
  ec:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  ee:	ca19                	beqz	a2,104 <memset+0x1c>
  f0:	87aa                	mv	a5,a0
  f2:	1602                	slli	a2,a2,0x20
  f4:	9201                	srli	a2,a2,0x20
  f6:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  fa:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  fe:	0785                	addi	a5,a5,1
 100:	fee79de3          	bne	a5,a4,fa <memset+0x12>
  }
  return dst;
}
 104:	6422                	ld	s0,8(sp)
 106:	0141                	addi	sp,sp,16
 108:	8082                	ret

000000000000010a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
 10a:	1141                	addi	sp,sp,-16
 10c:	e422                	sd	s0,8(sp)
 10e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
 110:	ca05                	beqz	a2,140 <memcmp+0x36>
 112:	fff6069b          	addiw	a3,a2,-1
 116:	1682                	slli	a3,a3,0x20
 118:	9281                	srli	a3,a3,0x20
 11a:	0685                	addi	a3,a3,1
 11c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
 11e:	00054783          	lbu	a5,0(a0)
 122:	0005c703          	lbu	a4,0(a1)
 126:	00e79863          	bne	a5,a4,136 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
 12a:	0505                	addi	a0,a0,1
 12c:	0585                	addi	a1,a1,1
  while(n-- > 0){
 12e:	fed518e3          	bne	a0,a3,11e <memcmp+0x14>
  }

  return 0;
 132:	4501                	li	a0,0
 134:	a019                	j	13a <memcmp+0x30>
      return *s1 - *s2;
 136:	40e7853b          	subw	a0,a5,a4
}
 13a:	6422                	ld	s0,8(sp)
 13c:	0141                	addi	sp,sp,16
 13e:	8082                	ret
  return 0;
 140:	4501                	li	a0,0
 142:	bfe5                	j	13a <memcmp+0x30>

0000000000000144 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
 144:	1141                	addi	sp,sp,-16
 146:	e422                	sd	s0,8(sp)
 148:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
 14a:	c205                	beqz	a2,16a <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
 14c:	02a5e263          	bltu	a1,a0,170 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
 150:	1602                	slli	a2,a2,0x20
 152:	9201                	srli	a2,a2,0x20
 154:	00c587b3          	add	a5,a1,a2
{
 158:	872a                	mv	a4,a0
      *d++ = *s++;
 15a:	0585                	addi	a1,a1,1
 15c:	0705                	addi	a4,a4,1
 15e:	fff5c683          	lbu	a3,-1(a1)
 162:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 166:	fef59ae3          	bne	a1,a5,15a <memmove+0x16>

  return dst;
}
 16a:	6422                	ld	s0,8(sp)
 16c:	0141                	addi	sp,sp,16
 16e:	8082                	ret
  if(s < d && s + n > d){
 170:	02061693          	slli	a3,a2,0x20
 174:	9281                	srli	a3,a3,0x20
 176:	00d58733          	add	a4,a1,a3
 17a:	fce57be3          	bgeu	a0,a4,150 <memmove+0xc>
    d += n;
 17e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
 180:	fff6079b          	addiw	a5,a2,-1
 184:	1782                	slli	a5,a5,0x20
 186:	9381                	srli	a5,a5,0x20
 188:	fff7c793          	not	a5,a5
 18c:	97ba                	add	a5,a5,a4
      *--d = *--s;
 18e:	177d                	addi	a4,a4,-1
 190:	16fd                	addi	a3,a3,-1
 192:	00074603          	lbu	a2,0(a4)
 196:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
 19a:	fee79ae3          	bne	a5,a4,18e <memmove+0x4a>
 19e:	b7f1                	j	16a <memmove+0x26>

00000000000001a0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
 1a0:	1141                	addi	sp,sp,-16
 1a2:	e406                	sd	ra,8(sp)
 1a4:	e022                	sd	s0,0(sp)
 1a6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 1a8:	00000097          	auipc	ra,0x0
 1ac:	f9c080e7          	jalr	-100(ra) # 144 <memmove>
}
 1b0:	60a2                	ld	ra,8(sp)
 1b2:	6402                	ld	s0,0(sp)
 1b4:	0141                	addi	sp,sp,16
 1b6:	8082                	ret

00000000000001b8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
 1b8:	1141                	addi	sp,sp,-16
 1ba:	e422                	sd	s0,8(sp)
 1bc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
 1be:	ce11                	beqz	a2,1da <strncmp+0x22>
 1c0:	00054783          	lbu	a5,0(a0)
 1c4:	cf89                	beqz	a5,1de <strncmp+0x26>
 1c6:	0005c703          	lbu	a4,0(a1)
 1ca:	00f71a63          	bne	a4,a5,1de <strncmp+0x26>
    n--, p++, q++;
 1ce:	367d                	addiw	a2,a2,-1
 1d0:	0505                	addi	a0,a0,1
 1d2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
 1d4:	f675                	bnez	a2,1c0 <strncmp+0x8>
  if(n == 0)
    return 0;
 1d6:	4501                	li	a0,0
 1d8:	a809                	j	1ea <strncmp+0x32>
 1da:	4501                	li	a0,0
 1dc:	a039                	j	1ea <strncmp+0x32>
  if(n == 0)
 1de:	ca09                	beqz	a2,1f0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
 1e0:	00054503          	lbu	a0,0(a0)
 1e4:	0005c783          	lbu	a5,0(a1)
 1e8:	9d1d                	subw	a0,a0,a5
}
 1ea:	6422                	ld	s0,8(sp)
 1ec:	0141                	addi	sp,sp,16
 1ee:	8082                	ret
    return 0;
 1f0:	4501                	li	a0,0
 1f2:	bfe5                	j	1ea <strncmp+0x32>

00000000000001f4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
 1f4:	1141                	addi	sp,sp,-16
 1f6:	e422                	sd	s0,8(sp)
 1f8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
 1fa:	87aa                	mv	a5,a0
 1fc:	86b2                	mv	a3,a2
 1fe:	367d                	addiw	a2,a2,-1
 200:	00d05963          	blez	a3,212 <strncpy+0x1e>
 204:	0785                	addi	a5,a5,1
 206:	0005c703          	lbu	a4,0(a1)
 20a:	fee78fa3          	sb	a4,-1(a5)
 20e:	0585                	addi	a1,a1,1
 210:	f775                	bnez	a4,1fc <strncpy+0x8>
    ;
  while(n-- > 0)
 212:	873e                	mv	a4,a5
 214:	9fb5                	addw	a5,a5,a3
 216:	37fd                	addiw	a5,a5,-1
 218:	00c05963          	blez	a2,22a <strncpy+0x36>
    *s++ = 0;
 21c:	0705                	addi	a4,a4,1
 21e:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
 222:	40e786bb          	subw	a3,a5,a4
 226:	fed04be3          	bgtz	a3,21c <strncpy+0x28>
  return os;
}
 22a:	6422                	ld	s0,8(sp)
 22c:	0141                	addi	sp,sp,16
 22e:	8082                	ret

0000000000000230 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
 230:	1141                	addi	sp,sp,-16
 232:	e422                	sd	s0,8(sp)
 234:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
 236:	02c05363          	blez	a2,25c <safestrcpy+0x2c>
 23a:	fff6069b          	addiw	a3,a2,-1
 23e:	1682                	slli	a3,a3,0x20
 240:	9281                	srli	a3,a3,0x20
 242:	96ae                	add	a3,a3,a1
 244:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
 246:	00d58963          	beq	a1,a3,258 <safestrcpy+0x28>
 24a:	0585                	addi	a1,a1,1
 24c:	0785                	addi	a5,a5,1
 24e:	fff5c703          	lbu	a4,-1(a1)
 252:	fee78fa3          	sb	a4,-1(a5)
 256:	fb65                	bnez	a4,246 <safestrcpy+0x16>
    ;
  *s = 0;
 258:	00078023          	sb	zero,0(a5)
  return os;
}
 25c:	6422                	ld	s0,8(sp)
 25e:	0141                	addi	sp,sp,16
 260:	8082                	ret

0000000000000262 <strlen>:

int
strlen(const char *s)
{
 262:	1141                	addi	sp,sp,-16
 264:	e422                	sd	s0,8(sp)
 266:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 268:	00054783          	lbu	a5,0(a0)
 26c:	cf91                	beqz	a5,288 <strlen+0x26>
 26e:	0505                	addi	a0,a0,1
 270:	87aa                	mv	a5,a0
 272:	86be                	mv	a3,a5
 274:	0785                	addi	a5,a5,1
 276:	fff7c703          	lbu	a4,-1(a5)
 27a:	ff65                	bnez	a4,272 <strlen+0x10>
 27c:	40a6853b          	subw	a0,a3,a0
 280:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 282:	6422                	ld	s0,8(sp)
 284:	0141                	addi	sp,sp,16
 286:	8082                	ret
  for(n = 0; s[n]; n++)
 288:	4501                	li	a0,0
 28a:	bfe5                	j	282 <strlen+0x20>

000000000000028c <panic>:
#include "buf.h"

#include <stdbool.h>

void panic(char *s)
{
 28c:	1141                	addi	sp,sp,-16
 28e:	e422                	sd	s0,8(sp)
 290:	0800                	addi	s0,sp,16
  for(;;)
 292:	a001                	j	292 <panic+0x6>

0000000000000294 <assert_linker_symbols>:
    ;
}

int assert_linker_symbols(void) {
 294:	1141                	addi	sp,sp,-16
 296:	e422                	sd	s0,8(sp)
 298:	0800                	addi	s0,sp,16
    return 0;
}
 29a:	4501                	li	a0,0
 29c:	6422                	ld	s0,8(sp)
 29e:	0141                	addi	sp,sp,16
 2a0:	8082                	ret

00000000000002a2 <assert_stack_address>:

int assert_stack_address(void) {
 2a2:	1141                	addi	sp,sp,-16
 2a4:	e422                	sd	s0,8(sp)
 2a6:	0800                	addi	s0,sp,16
    return 1;
 2a8:	4505                	li	a0,1
 2aa:	6422                	ld	s0,8(sp)
 2ac:	0141                	addi	sp,sp,16
 2ae:	8082                	ret

00000000000002b0 <read_kernel_elf>:
#include "elf.h"

#include <stdbool.h>

// Task: Read the ELF header, perform a sanity check, and return binary entry point
uint64 read_kernel_elf(void) {
 2b0:	715d                	addi	sp,sp,-80
 2b2:	e486                	sd	ra,72(sp)
 2b4:	e0a2                	sd	s0,64(sp)
 2b6:	0880                	addi	s0,sp,80
    struct elfhdr elf;
    memmove((void*) &elf, (void*) RAMDISK, sizeof(elf));
 2b8:	04000613          	li	a2,64
 2bc:	02100593          	li	a1,33
 2c0:	05ea                	slli	a1,a1,0x1a
 2c2:	fb040513          	addi	a0,s0,-80
 2c6:	00000097          	auipc	ra,0x0
 2ca:	e7e080e7          	jalr	-386(ra) # 144 <memmove>
    if(elf.magic != ELF_MAGIC)
 2ce:	fb042703          	lw	a4,-80(s0)
 2d2:	464c47b7          	lui	a5,0x464c4
 2d6:	57f78793          	addi	a5,a5,1407 # 464c457f <ustack+0x464b349f>
 2da:	00f71863          	bne	a4,a5,2ea <read_kernel_elf+0x3a>
        panic (NULL);
    return elf.entry;
 2de:	fc843503          	ld	a0,-56(s0)
 2e2:	60a6                	ld	ra,72(sp)
 2e4:	6406                	ld	s0,64(sp)
 2e6:	6161                	addi	sp,sp,80
 2e8:	8082                	ret
        panic (NULL);
 2ea:	4501                	li	a0,0
 2ec:	00000097          	auipc	ra,0x0
 2f0:	fa0080e7          	jalr	-96(ra) # 28c <panic>
 2f4:	b7ed                	j	2de <read_kernel_elf+0x2e>

00000000000002f6 <kalloc>:

void usertrapret(void);

// simple page-by-page memory allocator
void* kalloc(void) {
    if (alloc_pages == KMEMSIZE) {
 2f6:	00001717          	auipc	a4,0x1
 2fa:	d0a72703          	lw	a4,-758(a4) # 1000 <alloc_pages>
 2fe:	40000793          	li	a5,1024
 302:	02f70063          	beq	a4,a5,322 <kalloc+0x2c>
        panic("panic!");
    }
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
 306:	00001797          	auipc	a5,0x1
 30a:	cfa78793          	addi	a5,a5,-774 # 1000 <alloc_pages>
 30e:	4388                	lw	a0,0(a5)
    alloc_pages++;
 310:	0015071b          	addiw	a4,a0,1
 314:	c398                	sw	a4,0(a5)
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
 316:	00c5151b          	slliw	a0,a0,0xc
    return (void*) addr;
}
 31a:	4785                	li	a5,1
 31c:	07fe                	slli	a5,a5,0x1f
 31e:	953e                	add	a0,a0,a5
 320:	8082                	ret
void* kalloc(void) {
 322:	1141                	addi	sp,sp,-16
 324:	e406                	sd	ra,8(sp)
 326:	e022                	sd	s0,0(sp)
 328:	0800                	addi	s0,sp,16
        panic("panic!");
 32a:	00000517          	auipc	a0,0x0
 32e:	13650513          	addi	a0,a0,310 # 460 <process_entry+0x36>
 332:	00000097          	auipc	ra,0x0
 336:	f5a080e7          	jalr	-166(ra) # 28c <panic>
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
 33a:	00001797          	auipc	a5,0x1
 33e:	cc678793          	addi	a5,a5,-826 # 1000 <alloc_pages>
 342:	4388                	lw	a0,0(a5)
    alloc_pages++;
 344:	0015071b          	addiw	a4,a0,1
 348:	c398                	sw	a4,0(a5)
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
 34a:	00c5151b          	slliw	a0,a0,0xc
}
 34e:	4785                	li	a5,1
 350:	07fe                	slli	a5,a5,0x1f
 352:	953e                	add	a0,a0,a5
 354:	60a2                	ld	ra,8(sp)
 356:	6402                	ld	s0,0(sp)
 358:	0141                	addi	sp,sp,16
 35a:	8082                	ret

000000000000035c <usertrapret>:
  /* traps here when back from the userspace code. */
  p.trapframe->epc = r_sepc() + 4;
  usertrapret();
}

void usertrapret(void) {
 35c:	1141                	addi	sp,sp,-16
 35e:	e422                	sd	s0,8(sp)
 360:	0800                	addi	s0,sp,16
    // Set-up for process entry and exit
    p.trapframe->kernel_sp = (uint64) kstack+PGSIZE;
 362:	00009717          	auipc	a4,0x9
 366:	cae70713          	addi	a4,a4,-850 # 9010 <p>
 36a:	633c                	ld	a5,64(a4)
 36c:	0000a697          	auipc	a3,0xa
 370:	d7468693          	addi	a3,a3,-652 # a0e0 <kstack+0x1000>
 374:	e794                	sd	a3,8(a5)

    // Set return trap location
    p.trapframe->kernel_trap = (uint64) usertrap;
 376:	633c                	ld	a5,64(a4)
 378:	00000697          	auipc	a3,0x0
 37c:	03868693          	addi	a3,a3,56 # 3b0 <usertrap>
 380:	eb94                	sd	a3,16(a5)
    w_stvec((uint64) p.trapframe->kernel_trap);
 382:	633c                	ld	a5,64(a4)
  asm volatile("csrw stvec, %0" : : "r" (x));
 384:	6b94                	ld	a3,16(a5)
 386:	10569073          	csrw	stvec,a3
  asm volatile("mv %0, tp" : "=r" (x) );
 38a:	8692                	mv	a3,tp

    // Save hart id
    p.trapframe->kernel_hartid = r_tp();
 38c:	f394                	sd	a3,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
 38e:	100027f3          	csrr	a5,sstatus

    // set S Previous Privilege mode to User.
    unsigned long x = r_sstatus();
    x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
 392:	eff7f793          	andi	a5,a5,-257
    x |= SSTATUS_SPIE; // enable interrupts in user mode
 396:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
 39a:	10079073          	csrw	sstatus,a5
    w_sstatus(x);

    // Set entry location
    w_sepc((uint64) p.trapframe->epc);
 39e:	633c                	ld	a5,64(a4)
  asm volatile("csrw sepc, %0" : : "r" (x));
 3a0:	6f9c                	ld	a5,24(a5)
 3a2:	14179073          	csrw	sepc,a5

    asm("sret");
 3a6:	10200073          	sret
}
 3aa:	6422                	ld	s0,8(sp)
 3ac:	0141                	addi	sp,sp,16
 3ae:	8082                	ret

00000000000003b0 <usertrap>:
void usertrap(void) {
 3b0:	1141                	addi	sp,sp,-16
 3b2:	e406                	sd	ra,8(sp)
 3b4:	e022                	sd	s0,0(sp)
 3b6:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, sepc" : "=r" (x) );
 3b8:	141027f3          	csrr	a5,sepc
  p.trapframe->epc = r_sepc() + 4;
 3bc:	0791                	addi	a5,a5,4
 3be:	00009717          	auipc	a4,0x9
 3c2:	c9273703          	ld	a4,-878(a4) # 9050 <p+0x40>
 3c6:	ef1c                	sd	a5,24(a4)
  usertrapret();
 3c8:	00000097          	auipc	ra,0x0
 3cc:	f94080e7          	jalr	-108(ra) # 35c <usertrapret>
}
 3d0:	60a2                	ld	ra,8(sp)
 3d2:	6402                	ld	s0,0(sp)
 3d4:	0141                	addi	sp,sp,16
 3d6:	8082                	ret

00000000000003d8 <create_process>:

// Creates the user-level process and sets-up initial
void create_process(void) {
 3d8:	1141                	addi	sp,sp,-16
 3da:	e406                	sd	ra,8(sp)
 3dc:	e022                	sd	s0,0(sp)
 3de:	0800                	addi	s0,sp,16
    // allocate trapframe memory
    p.trapframe = (struct trapframe*) kalloc();
 3e0:	00000097          	auipc	ra,0x0
 3e4:	f16080e7          	jalr	-234(ra) # 2f6 <kalloc>
 3e8:	00009797          	auipc	a5,0x9
 3ec:	c2878793          	addi	a5,a5,-984 # 9010 <p>
 3f0:	e3a8                	sd	a0,64(a5)

    // entry point
    p.trapframe->epc = (uint64) process_entry;
 3f2:	00000717          	auipc	a4,0x0
 3f6:	03870713          	addi	a4,a4,56 # 42a <process_entry>
 3fa:	ed18                	sd	a4,24(a0)

    // initial stack values
    p.trapframe->a1 = (uint64) ustack+PGSIZE;
 3fc:	63bc                	ld	a5,64(a5)
 3fe:	00012717          	auipc	a4,0x12
 402:	ce270713          	addi	a4,a4,-798 # 120e0 <ustack+0x1000>
 406:	ffb8                	sd	a4,120(a5)

    // usertrapret
    usertrapret();
 408:	00000097          	auipc	ra,0x0
 40c:	f54080e7          	jalr	-172(ra) # 35c <usertrapret>
}
 410:	60a2                	ld	ra,8(sp)
 412:	6402                	ld	s0,0(sp)
 414:	0141                	addi	sp,sp,16
 416:	8082                	ret

0000000000000418 <kernel_entry>:

void kernel_entry(void) {
 418:	1141                	addi	sp,sp,-16
 41a:	e406                	sd	ra,8(sp)
 41c:	e022                	sd	s0,0(sp)
 41e:	0800                	addi	s0,sp,16
  create_process();
 420:	00000097          	auipc	ra,0x0
 424:	fb8080e7          	jalr	-72(ra) # 3d8 <create_process>

  /* Nothing to go back to */
  while (true);
 428:	a001                	j	428 <kernel_entry+0x10>

000000000000042a <process_entry>:
void process_entry(void) {
 42a:	1141                	addi	sp,sp,-16
 42c:	e422                	sd	s0,8(sp)
 42e:	0800                	addi	s0,sp,16
  asm("ecall");
 430:	00000073          	ecall
  asm("sret");
 434:	10200073          	sret
 438:	6422                	ld	s0,8(sp)
 43a:	0141                	addi	sp,sp,16
 43c:	8082                	ret
