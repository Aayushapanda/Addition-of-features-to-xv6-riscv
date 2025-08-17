
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	00008117          	auipc	sp,0x8
    80000004:	9c010113          	addi	sp,sp,-1600 # 800079c0 <stack0>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
        # jump to start() in start.c
        call start
    80000016:	04a000ef          	jal	ra,80000060 <start>

000000008000001a <spin>:
spin:
        j spin
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
}

// ask each hart to generate timer interrupts.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
#define MIE_STIE (1L << 5)  // supervisor timer
static inline uint64
r_mie()
{
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000022:	304027f3          	csrr	a5,mie
  // enable supervisor-mode timer interrupts.
  w_mie(r_mie() | MIE_STIE);
    80000026:	0207e793          	ori	a5,a5,32
}

static inline void 
w_mie(uint64 x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
    8000002a:	30479073          	csrw	mie,a5
static inline uint64
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
    8000002e:	30a027f3          	csrr	a5,0x30a
  
  // enable the sstc extension (i.e. stimecmp).
  w_menvcfg(r_menvcfg() | (1L << 63)); 
    80000032:	577d                	li	a4,-1
    80000034:	177e                	slli	a4,a4,0x3f
    80000036:	8fd9                	or	a5,a5,a4

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
    80000038:	30a79073          	csrw	0x30a,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    8000003c:	306027f3          	csrr	a5,mcounteren
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000040:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000044:	30679073          	csrw	mcounteren,a5
// machine-mode cycle counter
static inline uint64
r_time()
{
  uint64 x;
  asm volatile("csrr %0, time" : "=r" (x) );
    80000048:	c01027f3          	rdtime	a5
  
  // ask for the very first timer interrupt.
  w_stimecmp(r_time() + 1000000);
    8000004c:	000f4737          	lui	a4,0xf4
    80000050:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000054:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80000056:	14d79073          	csrw	0x14d,a5
}
    8000005a:	6422                	ld	s0,8(sp)
    8000005c:	0141                	addi	sp,sp,16
    8000005e:	8082                	ret

0000000080000060 <start>:
{
    80000060:	1141                	addi	sp,sp,-16
    80000062:	e406                	sd	ra,8(sp)
    80000064:	e022                	sd	s0,0(sp)
    80000066:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000006c:	7779                	lui	a4,0xffffe
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdd917>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	e3878793          	addi	a5,a5,-456 # 80000eb8 <main>
    80000088:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000008c:	4781                	li	a5,0
    8000008e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000092:	67c1                	lui	a5,0x10
    80000094:	17fd                	addi	a5,a5,-1
    80000096:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000009a:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000009e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    800000a2:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    800000a6:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000aa:	57fd                	li	a5,-1
    800000ac:	83a9                	srli	a5,a5,0xa
    800000ae:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000b2:	47bd                	li	a5,15
    800000b4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000b8:	f65ff0ef          	jal	ra,8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000bc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000c0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000c2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000c4:	30200073          	mret
}
    800000c8:	60a2                	ld	ra,8(sp)
    800000ca:	6402                	ld	s0,0(sp)
    800000cc:	0141                	addi	sp,sp,16
    800000ce:	8082                	ret

00000000800000d0 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000d0:	715d                	addi	sp,sp,-80
    800000d2:	e486                	sd	ra,72(sp)
    800000d4:	e0a2                	sd	s0,64(sp)
    800000d6:	fc26                	sd	s1,56(sp)
    800000d8:	f84a                	sd	s2,48(sp)
    800000da:	f44e                	sd	s3,40(sp)
    800000dc:	f052                	sd	s4,32(sp)
    800000de:	ec56                	sd	s5,24(sp)
    800000e0:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    800000e2:	04c05263          	blez	a2,80000126 <consolewrite+0x56>
    800000e6:	8a2a                	mv	s4,a0
    800000e8:	84ae                	mv	s1,a1
    800000ea:	89b2                	mv	s3,a2
    800000ec:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    800000ee:	5afd                	li	s5,-1
    800000f0:	4685                	li	a3,1
    800000f2:	8626                	mv	a2,s1
    800000f4:	85d2                	mv	a1,s4
    800000f6:	fbf40513          	addi	a0,s0,-65
    800000fa:	16c020ef          	jal	ra,80002266 <either_copyin>
    800000fe:	01550a63          	beq	a0,s5,80000112 <consolewrite+0x42>
      break;
    uartputc(c);
    80000102:	fbf44503          	lbu	a0,-65(s0)
    80000106:	041000ef          	jal	ra,80000946 <uartputc>
  for(i = 0; i < n; i++){
    8000010a:	2905                	addiw	s2,s2,1
    8000010c:	0485                	addi	s1,s1,1
    8000010e:	ff2991e3          	bne	s3,s2,800000f0 <consolewrite+0x20>
  }

  return i;
}
    80000112:	854a                	mv	a0,s2
    80000114:	60a6                	ld	ra,72(sp)
    80000116:	6406                	ld	s0,64(sp)
    80000118:	74e2                	ld	s1,56(sp)
    8000011a:	7942                	ld	s2,48(sp)
    8000011c:	79a2                	ld	s3,40(sp)
    8000011e:	7a02                	ld	s4,32(sp)
    80000120:	6ae2                	ld	s5,24(sp)
    80000122:	6161                	addi	sp,sp,80
    80000124:	8082                	ret
  for(i = 0; i < n; i++){
    80000126:	4901                	li	s2,0
    80000128:	b7ed                	j	80000112 <consolewrite+0x42>

000000008000012a <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000012a:	7159                	addi	sp,sp,-112
    8000012c:	f486                	sd	ra,104(sp)
    8000012e:	f0a2                	sd	s0,96(sp)
    80000130:	eca6                	sd	s1,88(sp)
    80000132:	e8ca                	sd	s2,80(sp)
    80000134:	e4ce                	sd	s3,72(sp)
    80000136:	e0d2                	sd	s4,64(sp)
    80000138:	fc56                	sd	s5,56(sp)
    8000013a:	f85a                	sd	s6,48(sp)
    8000013c:	f45e                	sd	s7,40(sp)
    8000013e:	f062                	sd	s8,32(sp)
    80000140:	ec66                	sd	s9,24(sp)
    80000142:	e86a                	sd	s10,16(sp)
    80000144:	1880                	addi	s0,sp,112
    80000146:	8aaa                	mv	s5,a0
    80000148:	8a2e                	mv	s4,a1
    8000014a:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000014c:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000150:	00010517          	auipc	a0,0x10
    80000154:	87050513          	addi	a0,a0,-1936 # 8000f9c0 <cons>
    80000158:	2eb000ef          	jal	ra,80000c42 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000015c:	00010497          	auipc	s1,0x10
    80000160:	86448493          	addi	s1,s1,-1948 # 8000f9c0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000164:	00010917          	auipc	s2,0x10
    80000168:	8f490913          	addi	s2,s2,-1804 # 8000fa58 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    8000016c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000016e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    80000170:	4ca9                	li	s9,10
  while(n > 0){
    80000172:	07305363          	blez	s3,800001d8 <consoleread+0xae>
    while(cons.r == cons.w){
    80000176:	0984a783          	lw	a5,152(s1)
    8000017a:	09c4a703          	lw	a4,156(s1)
    8000017e:	02f71163          	bne	a4,a5,800001a0 <consoleread+0x76>
      if(killed(myproc())){
    80000182:	758010ef          	jal	ra,800018da <myproc>
    80000186:	773010ef          	jal	ra,800020f8 <killed>
    8000018a:	e125                	bnez	a0,800001ea <consoleread+0xc0>
      sleep(&cons.r, &cons.lock);
    8000018c:	85a6                	mv	a1,s1
    8000018e:	854a                	mv	a0,s2
    80000190:	531010ef          	jal	ra,80001ec0 <sleep>
    while(cons.r == cons.w){
    80000194:	0984a783          	lw	a5,152(s1)
    80000198:	09c4a703          	lw	a4,156(s1)
    8000019c:	fef703e3          	beq	a4,a5,80000182 <consoleread+0x58>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001a0:	0017871b          	addiw	a4,a5,1
    800001a4:	08e4ac23          	sw	a4,152(s1)
    800001a8:	07f7f713          	andi	a4,a5,127
    800001ac:	9726                	add	a4,a4,s1
    800001ae:	01874703          	lbu	a4,24(a4)
    800001b2:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001b6:	057d0f63          	beq	s10,s7,80000214 <consoleread+0xea>
    cbuf = c;
    800001ba:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001be:	4685                	li	a3,1
    800001c0:	f9f40613          	addi	a2,s0,-97
    800001c4:	85d2                	mv	a1,s4
    800001c6:	8556                	mv	a0,s5
    800001c8:	054020ef          	jal	ra,8000221c <either_copyout>
    800001cc:	01850663          	beq	a0,s8,800001d8 <consoleread+0xae>
    dst++;
    800001d0:	0a05                	addi	s4,s4,1
    --n;
    800001d2:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    800001d4:	f99d1fe3          	bne	s10,s9,80000172 <consoleread+0x48>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    800001d8:	0000f517          	auipc	a0,0xf
    800001dc:	7e850513          	addi	a0,a0,2024 # 8000f9c0 <cons>
    800001e0:	2fb000ef          	jal	ra,80000cda <release>

  return target - n;
    800001e4:	413b053b          	subw	a0,s6,s3
    800001e8:	a801                	j	800001f8 <consoleread+0xce>
        release(&cons.lock);
    800001ea:	0000f517          	auipc	a0,0xf
    800001ee:	7d650513          	addi	a0,a0,2006 # 8000f9c0 <cons>
    800001f2:	2e9000ef          	jal	ra,80000cda <release>
        return -1;
    800001f6:	557d                	li	a0,-1
}
    800001f8:	70a6                	ld	ra,104(sp)
    800001fa:	7406                	ld	s0,96(sp)
    800001fc:	64e6                	ld	s1,88(sp)
    800001fe:	6946                	ld	s2,80(sp)
    80000200:	69a6                	ld	s3,72(sp)
    80000202:	6a06                	ld	s4,64(sp)
    80000204:	7ae2                	ld	s5,56(sp)
    80000206:	7b42                	ld	s6,48(sp)
    80000208:	7ba2                	ld	s7,40(sp)
    8000020a:	7c02                	ld	s8,32(sp)
    8000020c:	6ce2                	ld	s9,24(sp)
    8000020e:	6d42                	ld	s10,16(sp)
    80000210:	6165                	addi	sp,sp,112
    80000212:	8082                	ret
      if(n < target){
    80000214:	0009871b          	sext.w	a4,s3
    80000218:	fd6770e3          	bgeu	a4,s6,800001d8 <consoleread+0xae>
        cons.r--;
    8000021c:	00010717          	auipc	a4,0x10
    80000220:	82f72e23          	sw	a5,-1988(a4) # 8000fa58 <cons+0x98>
    80000224:	bf55                	j	800001d8 <consoleread+0xae>

0000000080000226 <consputc>:
{
    80000226:	1141                	addi	sp,sp,-16
    80000228:	e406                	sd	ra,8(sp)
    8000022a:	e022                	sd	s0,0(sp)
    8000022c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000022e:	10000793          	li	a5,256
    80000232:	00f50863          	beq	a0,a5,80000242 <consputc+0x1c>
    uartputc_sync(c);
    80000236:	632000ef          	jal	ra,80000868 <uartputc_sync>
}
    8000023a:	60a2                	ld	ra,8(sp)
    8000023c:	6402                	ld	s0,0(sp)
    8000023e:	0141                	addi	sp,sp,16
    80000240:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000242:	4521                	li	a0,8
    80000244:	624000ef          	jal	ra,80000868 <uartputc_sync>
    80000248:	02000513          	li	a0,32
    8000024c:	61c000ef          	jal	ra,80000868 <uartputc_sync>
    80000250:	4521                	li	a0,8
    80000252:	616000ef          	jal	ra,80000868 <uartputc_sync>
    80000256:	b7d5                	j	8000023a <consputc+0x14>

0000000080000258 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    80000258:	1101                	addi	sp,sp,-32
    8000025a:	ec06                	sd	ra,24(sp)
    8000025c:	e822                	sd	s0,16(sp)
    8000025e:	e426                	sd	s1,8(sp)
    80000260:	e04a                	sd	s2,0(sp)
    80000262:	1000                	addi	s0,sp,32
    80000264:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    80000266:	0000f517          	auipc	a0,0xf
    8000026a:	75a50513          	addi	a0,a0,1882 # 8000f9c0 <cons>
    8000026e:	1d5000ef          	jal	ra,80000c42 <acquire>

  switch(c){
    80000272:	47d5                	li	a5,21
    80000274:	0af48063          	beq	s1,a5,80000314 <consoleintr+0xbc>
    80000278:	0297c663          	blt	a5,s1,800002a4 <consoleintr+0x4c>
    8000027c:	47a1                	li	a5,8
    8000027e:	0cf48f63          	beq	s1,a5,8000035c <consoleintr+0x104>
    80000282:	47c1                	li	a5,16
    80000284:	10f49063          	bne	s1,a5,80000384 <consoleintr+0x12c>
  case C('P'):  // Print process list.
    procdump();
    80000288:	028020ef          	jal	ra,800022b0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000028c:	0000f517          	auipc	a0,0xf
    80000290:	73450513          	addi	a0,a0,1844 # 8000f9c0 <cons>
    80000294:	247000ef          	jal	ra,80000cda <release>
}
    80000298:	60e2                	ld	ra,24(sp)
    8000029a:	6442                	ld	s0,16(sp)
    8000029c:	64a2                	ld	s1,8(sp)
    8000029e:	6902                	ld	s2,0(sp)
    800002a0:	6105                	addi	sp,sp,32
    800002a2:	8082                	ret
  switch(c){
    800002a4:	07f00793          	li	a5,127
    800002a8:	0af48a63          	beq	s1,a5,8000035c <consoleintr+0x104>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002ac:	0000f717          	auipc	a4,0xf
    800002b0:	71470713          	addi	a4,a4,1812 # 8000f9c0 <cons>
    800002b4:	0a072783          	lw	a5,160(a4)
    800002b8:	09872703          	lw	a4,152(a4)
    800002bc:	9f99                	subw	a5,a5,a4
    800002be:	07f00713          	li	a4,127
    800002c2:	fcf765e3          	bltu	a4,a5,8000028c <consoleintr+0x34>
      c = (c == '\r') ? '\n' : c;
    800002c6:	47b5                	li	a5,13
    800002c8:	0cf48163          	beq	s1,a5,8000038a <consoleintr+0x132>
      consputc(c);
    800002cc:	8526                	mv	a0,s1
    800002ce:	f59ff0ef          	jal	ra,80000226 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800002d2:	0000f797          	auipc	a5,0xf
    800002d6:	6ee78793          	addi	a5,a5,1774 # 8000f9c0 <cons>
    800002da:	0a07a683          	lw	a3,160(a5)
    800002de:	0016871b          	addiw	a4,a3,1
    800002e2:	0007061b          	sext.w	a2,a4
    800002e6:	0ae7a023          	sw	a4,160(a5)
    800002ea:	07f6f693          	andi	a3,a3,127
    800002ee:	97b6                	add	a5,a5,a3
    800002f0:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    800002f4:	47a9                	li	a5,10
    800002f6:	0af48f63          	beq	s1,a5,800003b4 <consoleintr+0x15c>
    800002fa:	4791                	li	a5,4
    800002fc:	0af48c63          	beq	s1,a5,800003b4 <consoleintr+0x15c>
    80000300:	0000f797          	auipc	a5,0xf
    80000304:	7587a783          	lw	a5,1880(a5) # 8000fa58 <cons+0x98>
    80000308:	9f1d                	subw	a4,a4,a5
    8000030a:	08000793          	li	a5,128
    8000030e:	f6f71fe3          	bne	a4,a5,8000028c <consoleintr+0x34>
    80000312:	a04d                	j	800003b4 <consoleintr+0x15c>
    while(cons.e != cons.w &&
    80000314:	0000f717          	auipc	a4,0xf
    80000318:	6ac70713          	addi	a4,a4,1708 # 8000f9c0 <cons>
    8000031c:	0a072783          	lw	a5,160(a4)
    80000320:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000324:	0000f497          	auipc	s1,0xf
    80000328:	69c48493          	addi	s1,s1,1692 # 8000f9c0 <cons>
    while(cons.e != cons.w &&
    8000032c:	4929                	li	s2,10
    8000032e:	f4f70fe3          	beq	a4,a5,8000028c <consoleintr+0x34>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000332:	37fd                	addiw	a5,a5,-1
    80000334:	07f7f713          	andi	a4,a5,127
    80000338:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000033a:	01874703          	lbu	a4,24(a4)
    8000033e:	f52707e3          	beq	a4,s2,8000028c <consoleintr+0x34>
      cons.e--;
    80000342:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000346:	10000513          	li	a0,256
    8000034a:	eddff0ef          	jal	ra,80000226 <consputc>
    while(cons.e != cons.w &&
    8000034e:	0a04a783          	lw	a5,160(s1)
    80000352:	09c4a703          	lw	a4,156(s1)
    80000356:	fcf71ee3          	bne	a4,a5,80000332 <consoleintr+0xda>
    8000035a:	bf0d                	j	8000028c <consoleintr+0x34>
    if(cons.e != cons.w){
    8000035c:	0000f717          	auipc	a4,0xf
    80000360:	66470713          	addi	a4,a4,1636 # 8000f9c0 <cons>
    80000364:	0a072783          	lw	a5,160(a4)
    80000368:	09c72703          	lw	a4,156(a4)
    8000036c:	f2f700e3          	beq	a4,a5,8000028c <consoleintr+0x34>
      cons.e--;
    80000370:	37fd                	addiw	a5,a5,-1
    80000372:	0000f717          	auipc	a4,0xf
    80000376:	6ef72723          	sw	a5,1774(a4) # 8000fa60 <cons+0xa0>
      consputc(BACKSPACE);
    8000037a:	10000513          	li	a0,256
    8000037e:	ea9ff0ef          	jal	ra,80000226 <consputc>
    80000382:	b729                	j	8000028c <consoleintr+0x34>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000384:	f00484e3          	beqz	s1,8000028c <consoleintr+0x34>
    80000388:	b715                	j	800002ac <consoleintr+0x54>
      consputc(c);
    8000038a:	4529                	li	a0,10
    8000038c:	e9bff0ef          	jal	ra,80000226 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000390:	0000f797          	auipc	a5,0xf
    80000394:	63078793          	addi	a5,a5,1584 # 8000f9c0 <cons>
    80000398:	0a07a703          	lw	a4,160(a5)
    8000039c:	0017069b          	addiw	a3,a4,1
    800003a0:	0006861b          	sext.w	a2,a3
    800003a4:	0ad7a023          	sw	a3,160(a5)
    800003a8:	07f77713          	andi	a4,a4,127
    800003ac:	97ba                	add	a5,a5,a4
    800003ae:	4729                	li	a4,10
    800003b0:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    800003b4:	0000f797          	auipc	a5,0xf
    800003b8:	6ac7a423          	sw	a2,1704(a5) # 8000fa5c <cons+0x9c>
        wakeup(&cons.r);
    800003bc:	0000f517          	auipc	a0,0xf
    800003c0:	69c50513          	addi	a0,a0,1692 # 8000fa58 <cons+0x98>
    800003c4:	349010ef          	jal	ra,80001f0c <wakeup>
    800003c8:	b5d1                	j	8000028c <consoleintr+0x34>

00000000800003ca <consoleinit>:

void
consoleinit(void)
{
    800003ca:	1141                	addi	sp,sp,-16
    800003cc:	e406                	sd	ra,8(sp)
    800003ce:	e022                	sd	s0,0(sp)
    800003d0:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    800003d2:	00007597          	auipc	a1,0x7
    800003d6:	c3e58593          	addi	a1,a1,-962 # 80007010 <etext+0x10>
    800003da:	0000f517          	auipc	a0,0xf
    800003de:	5e650513          	addi	a0,a0,1510 # 8000f9c0 <cons>
    800003e2:	7e0000ef          	jal	ra,80000bc2 <initlock>

  uartinit();
    800003e6:	436000ef          	jal	ra,8000081c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    800003ea:	00020797          	auipc	a5,0x20
    800003ee:	96678793          	addi	a5,a5,-1690 # 8001fd50 <devsw>
    800003f2:	00000717          	auipc	a4,0x0
    800003f6:	d3870713          	addi	a4,a4,-712 # 8000012a <consoleread>
    800003fa:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800003fc:	00000717          	auipc	a4,0x0
    80000400:	cd470713          	addi	a4,a4,-812 # 800000d0 <consolewrite>
    80000404:	ef98                	sd	a4,24(a5)
}
    80000406:	60a2                	ld	ra,8(sp)
    80000408:	6402                	ld	s0,0(sp)
    8000040a:	0141                	addi	sp,sp,16
    8000040c:	8082                	ret

000000008000040e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    8000040e:	7139                	addi	sp,sp,-64
    80000410:	fc06                	sd	ra,56(sp)
    80000412:	f822                	sd	s0,48(sp)
    80000414:	f426                	sd	s1,40(sp)
    80000416:	f04a                	sd	s2,32(sp)
    80000418:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    8000041a:	c219                	beqz	a2,80000420 <printint+0x12>
    8000041c:	06054f63          	bltz	a0,8000049a <printint+0x8c>
    x = -xx;
  else
    x = xx;
    80000420:	4881                	li	a7,0
    80000422:	fc840693          	addi	a3,s0,-56

  i = 0;
    80000426:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    80000428:	00007617          	auipc	a2,0x7
    8000042c:	c2860613          	addi	a2,a2,-984 # 80007050 <digits>
    80000430:	883e                	mv	a6,a5
    80000432:	2785                	addiw	a5,a5,1
    80000434:	02b57733          	remu	a4,a0,a1
    80000438:	9732                	add	a4,a4,a2
    8000043a:	00074703          	lbu	a4,0(a4)
    8000043e:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000442:	872a                	mv	a4,a0
    80000444:	02b55533          	divu	a0,a0,a1
    80000448:	0685                	addi	a3,a3,1
    8000044a:	feb773e3          	bgeu	a4,a1,80000430 <printint+0x22>

  if(sign)
    8000044e:	00088b63          	beqz	a7,80000464 <printint+0x56>
    buf[i++] = '-';
    80000452:	fe040713          	addi	a4,s0,-32
    80000456:	97ba                	add	a5,a5,a4
    80000458:	02d00713          	li	a4,45
    8000045c:	fee78423          	sb	a4,-24(a5)
    80000460:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    80000464:	02f05563          	blez	a5,8000048e <printint+0x80>
    80000468:	fc840713          	addi	a4,s0,-56
    8000046c:	00f704b3          	add	s1,a4,a5
    80000470:	fff70913          	addi	s2,a4,-1
    80000474:	993e                	add	s2,s2,a5
    80000476:	37fd                	addiw	a5,a5,-1
    80000478:	1782                	slli	a5,a5,0x20
    8000047a:	9381                	srli	a5,a5,0x20
    8000047c:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    80000480:	fff4c503          	lbu	a0,-1(s1)
    80000484:	da3ff0ef          	jal	ra,80000226 <consputc>
  while(--i >= 0)
    80000488:	14fd                	addi	s1,s1,-1
    8000048a:	ff249be3          	bne	s1,s2,80000480 <printint+0x72>
}
    8000048e:	70e2                	ld	ra,56(sp)
    80000490:	7442                	ld	s0,48(sp)
    80000492:	74a2                	ld	s1,40(sp)
    80000494:	7902                	ld	s2,32(sp)
    80000496:	6121                	addi	sp,sp,64
    80000498:	8082                	ret
    x = -xx;
    8000049a:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    8000049e:	4885                	li	a7,1
    x = -xx;
    800004a0:	b749                	j	80000422 <printint+0x14>

00000000800004a2 <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004a2:	7131                	addi	sp,sp,-192
    800004a4:	fc86                	sd	ra,120(sp)
    800004a6:	f8a2                	sd	s0,112(sp)
    800004a8:	f4a6                	sd	s1,104(sp)
    800004aa:	f0ca                	sd	s2,96(sp)
    800004ac:	ecce                	sd	s3,88(sp)
    800004ae:	e8d2                	sd	s4,80(sp)
    800004b0:	e4d6                	sd	s5,72(sp)
    800004b2:	e0da                	sd	s6,64(sp)
    800004b4:	fc5e                	sd	s7,56(sp)
    800004b6:	f862                	sd	s8,48(sp)
    800004b8:	f466                	sd	s9,40(sp)
    800004ba:	f06a                	sd	s10,32(sp)
    800004bc:	ec6e                	sd	s11,24(sp)
    800004be:	0100                	addi	s0,sp,128
    800004c0:	8a2a                	mv	s4,a0
    800004c2:	e40c                	sd	a1,8(s0)
    800004c4:	e810                	sd	a2,16(s0)
    800004c6:	ec14                	sd	a3,24(s0)
    800004c8:	f018                	sd	a4,32(s0)
    800004ca:	f41c                	sd	a5,40(s0)
    800004cc:	03043823          	sd	a6,48(s0)
    800004d0:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    800004d4:	00007797          	auipc	a5,0x7
    800004d8:	4b07a783          	lw	a5,1200(a5) # 80007984 <panicking>
    800004dc:	cb9d                	beqz	a5,80000512 <printf+0x70>
    acquire(&pr.lock);

  va_start(ap, fmt);
    800004de:	00840793          	addi	a5,s0,8
    800004e2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    800004e6:	000a4503          	lbu	a0,0(s4)
    800004ea:	24050363          	beqz	a0,80000730 <printf+0x28e>
    800004ee:	4981                	li	s3,0
    if(cx != '%'){
    800004f0:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    800004f4:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    800004f8:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    800004fc:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000500:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    80000504:	07000d93          	li	s11,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000508:	00007b97          	auipc	s7,0x7
    8000050c:	b48b8b93          	addi	s7,s7,-1208 # 80007050 <digits>
    80000510:	a01d                	j	80000536 <printf+0x94>
    acquire(&pr.lock);
    80000512:	0000f517          	auipc	a0,0xf
    80000516:	55650513          	addi	a0,a0,1366 # 8000fa68 <pr>
    8000051a:	728000ef          	jal	ra,80000c42 <acquire>
    8000051e:	b7c1                	j	800004de <printf+0x3c>
      consputc(cx);
    80000520:	d07ff0ef          	jal	ra,80000226 <consputc>
      continue;
    80000524:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000526:	0014899b          	addiw	s3,s1,1
    8000052a:	013a07b3          	add	a5,s4,s3
    8000052e:	0007c503          	lbu	a0,0(a5)
    80000532:	1e050f63          	beqz	a0,80000730 <printf+0x28e>
    if(cx != '%'){
    80000536:	ff5515e3          	bne	a0,s5,80000520 <printf+0x7e>
    i++;
    8000053a:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    8000053e:	009a07b3          	add	a5,s4,s1
    80000542:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000546:	1e090563          	beqz	s2,80000730 <printf+0x28e>
    8000054a:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    8000054e:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    80000550:	c789                	beqz	a5,8000055a <printf+0xb8>
    80000552:	009a0733          	add	a4,s4,s1
    80000556:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    8000055a:	03690863          	beq	s2,s6,8000058a <printf+0xe8>
    } else if(c0 == 'l' && c1 == 'd'){
    8000055e:	05890263          	beq	s2,s8,800005a2 <printf+0x100>
    } else if(c0 == 'u'){
    80000562:	0d990163          	beq	s2,s9,80000624 <printf+0x182>
    } else if(c0 == 'x'){
    80000566:	11a90863          	beq	s2,s10,80000676 <printf+0x1d4>
    } else if(c0 == 'p'){
    8000056a:	15b90163          	beq	s2,s11,800006ac <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    8000056e:	06300793          	li	a5,99
    80000572:	16f90963          	beq	s2,a5,800006e4 <printf+0x242>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    80000576:	07300793          	li	a5,115
    8000057a:	16f90f63          	beq	s2,a5,800006f8 <printf+0x256>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    8000057e:	03591c63          	bne	s2,s5,800005b6 <printf+0x114>
      consputc('%');
    80000582:	8556                	mv	a0,s5
    80000584:	ca3ff0ef          	jal	ra,80000226 <consputc>
    80000588:	bf79                	j	80000526 <printf+0x84>
      printint(va_arg(ap, int), 10, 1);
    8000058a:	f8843783          	ld	a5,-120(s0)
    8000058e:	00878713          	addi	a4,a5,8
    80000592:	f8e43423          	sd	a4,-120(s0)
    80000596:	4605                	li	a2,1
    80000598:	45a9                	li	a1,10
    8000059a:	4388                	lw	a0,0(a5)
    8000059c:	e73ff0ef          	jal	ra,8000040e <printint>
    800005a0:	b759                	j	80000526 <printf+0x84>
    } else if(c0 == 'l' && c1 == 'd'){
    800005a2:	03678163          	beq	a5,s6,800005c4 <printf+0x122>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005a6:	03878d63          	beq	a5,s8,800005e0 <printf+0x13e>
    } else if(c0 == 'l' && c1 == 'u'){
    800005aa:	09978a63          	beq	a5,s9,8000063e <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    800005ae:	03878b63          	beq	a5,s8,800005e4 <printf+0x142>
    } else if(c0 == 'l' && c1 == 'x'){
    800005b2:	0da78f63          	beq	a5,s10,80000690 <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    800005b6:	8556                	mv	a0,s5
    800005b8:	c6fff0ef          	jal	ra,80000226 <consputc>
      consputc(c0);
    800005bc:	854a                	mv	a0,s2
    800005be:	c69ff0ef          	jal	ra,80000226 <consputc>
    800005c2:	b795                	j	80000526 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 1);
    800005c4:	f8843783          	ld	a5,-120(s0)
    800005c8:	00878713          	addi	a4,a5,8
    800005cc:	f8e43423          	sd	a4,-120(s0)
    800005d0:	4605                	li	a2,1
    800005d2:	45a9                	li	a1,10
    800005d4:	6388                	ld	a0,0(a5)
    800005d6:	e39ff0ef          	jal	ra,8000040e <printint>
      i += 1;
    800005da:	0029849b          	addiw	s1,s3,2
    800005de:	b7a1                	j	80000526 <printf+0x84>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005e0:	03668463          	beq	a3,s6,80000608 <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    800005e4:	07968b63          	beq	a3,s9,8000065a <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    800005e8:	fda697e3          	bne	a3,s10,800005b6 <printf+0x114>
      printint(va_arg(ap, uint64), 16, 0);
    800005ec:	f8843783          	ld	a5,-120(s0)
    800005f0:	00878713          	addi	a4,a5,8
    800005f4:	f8e43423          	sd	a4,-120(s0)
    800005f8:	4601                	li	a2,0
    800005fa:	45c1                	li	a1,16
    800005fc:	6388                	ld	a0,0(a5)
    800005fe:	e11ff0ef          	jal	ra,8000040e <printint>
      i += 2;
    80000602:	0039849b          	addiw	s1,s3,3
    80000606:	b705                	j	80000526 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 1);
    80000608:	f8843783          	ld	a5,-120(s0)
    8000060c:	00878713          	addi	a4,a5,8
    80000610:	f8e43423          	sd	a4,-120(s0)
    80000614:	4605                	li	a2,1
    80000616:	45a9                	li	a1,10
    80000618:	6388                	ld	a0,0(a5)
    8000061a:	df5ff0ef          	jal	ra,8000040e <printint>
      i += 2;
    8000061e:	0039849b          	addiw	s1,s3,3
    80000622:	b711                	j	80000526 <printf+0x84>
      printint(va_arg(ap, uint32), 10, 0);
    80000624:	f8843783          	ld	a5,-120(s0)
    80000628:	00878713          	addi	a4,a5,8
    8000062c:	f8e43423          	sd	a4,-120(s0)
    80000630:	4601                	li	a2,0
    80000632:	45a9                	li	a1,10
    80000634:	0007e503          	lwu	a0,0(a5)
    80000638:	dd7ff0ef          	jal	ra,8000040e <printint>
    8000063c:	b5ed                	j	80000526 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 0);
    8000063e:	f8843783          	ld	a5,-120(s0)
    80000642:	00878713          	addi	a4,a5,8
    80000646:	f8e43423          	sd	a4,-120(s0)
    8000064a:	4601                	li	a2,0
    8000064c:	45a9                	li	a1,10
    8000064e:	6388                	ld	a0,0(a5)
    80000650:	dbfff0ef          	jal	ra,8000040e <printint>
      i += 1;
    80000654:	0029849b          	addiw	s1,s3,2
    80000658:	b5f9                	j	80000526 <printf+0x84>
      printint(va_arg(ap, uint64), 10, 0);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4601                	li	a2,0
    80000668:	45a9                	li	a1,10
    8000066a:	6388                	ld	a0,0(a5)
    8000066c:	da3ff0ef          	jal	ra,8000040e <printint>
      i += 2;
    80000670:	0039849b          	addiw	s1,s3,3
    80000674:	bd4d                	j	80000526 <printf+0x84>
      printint(va_arg(ap, uint32), 16, 0);
    80000676:	f8843783          	ld	a5,-120(s0)
    8000067a:	00878713          	addi	a4,a5,8
    8000067e:	f8e43423          	sd	a4,-120(s0)
    80000682:	4601                	li	a2,0
    80000684:	45c1                	li	a1,16
    80000686:	0007e503          	lwu	a0,0(a5)
    8000068a:	d85ff0ef          	jal	ra,8000040e <printint>
    8000068e:	bd61                	j	80000526 <printf+0x84>
      printint(va_arg(ap, uint64), 16, 0);
    80000690:	f8843783          	ld	a5,-120(s0)
    80000694:	00878713          	addi	a4,a5,8
    80000698:	f8e43423          	sd	a4,-120(s0)
    8000069c:	4601                	li	a2,0
    8000069e:	45c1                	li	a1,16
    800006a0:	6388                	ld	a0,0(a5)
    800006a2:	d6dff0ef          	jal	ra,8000040e <printint>
      i += 1;
    800006a6:	0029849b          	addiw	s1,s3,2
    800006aa:	bdb5                	j	80000526 <printf+0x84>
      printptr(va_arg(ap, uint64));
    800006ac:	f8843783          	ld	a5,-120(s0)
    800006b0:	00878713          	addi	a4,a5,8
    800006b4:	f8e43423          	sd	a4,-120(s0)
    800006b8:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006bc:	03000513          	li	a0,48
    800006c0:	b67ff0ef          	jal	ra,80000226 <consputc>
  consputc('x');
    800006c4:	856a                	mv	a0,s10
    800006c6:	b61ff0ef          	jal	ra,80000226 <consputc>
    800006ca:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	b51ff0ef          	jal	ra,80000226 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0917e3          	bnez	s2,800006cc <printf+0x22a>
    800006e2:	b591                	j	80000526 <printf+0x84>
      consputc(va_arg(ap, uint));
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	4388                	lw	a0,0(a5)
    800006f2:	b35ff0ef          	jal	ra,80000226 <consputc>
    800006f6:	bd05                	j	80000526 <printf+0x84>
      if((s = va_arg(ap, char*)) == 0)
    800006f8:	f8843783          	ld	a5,-120(s0)
    800006fc:	00878713          	addi	a4,a5,8
    80000700:	f8e43423          	sd	a4,-120(s0)
    80000704:	0007b903          	ld	s2,0(a5)
    80000708:	00090d63          	beqz	s2,80000722 <printf+0x280>
      for(; *s; s++)
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	e0050be3          	beqz	a0,80000526 <printf+0x84>
        consputc(*s);
    80000714:	b13ff0ef          	jal	ra,80000226 <consputc>
      for(; *s; s++)
    80000718:	0905                	addi	s2,s2,1
    8000071a:	00094503          	lbu	a0,0(s2)
    8000071e:	f97d                	bnez	a0,80000714 <printf+0x272>
    80000720:	b519                	j	80000526 <printf+0x84>
        s = "(null)";
    80000722:	00007917          	auipc	s2,0x7
    80000726:	8f690913          	addi	s2,s2,-1802 # 80007018 <etext+0x18>
      for(; *s; s++)
    8000072a:	02800513          	li	a0,40
    8000072e:	b7dd                	j	80000714 <printf+0x272>
    }

  }
  va_end(ap);

  if(panicking == 0)
    80000730:	00007797          	auipc	a5,0x7
    80000734:	2547a783          	lw	a5,596(a5) # 80007984 <panicking>
    80000738:	c38d                	beqz	a5,8000075a <printf+0x2b8>
    release(&pr.lock);

  return 0;
}
    8000073a:	4501                	li	a0,0
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	addi	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	0000f517          	auipc	a0,0xf
    8000075e:	30e50513          	addi	a0,a0,782 # 8000fa68 <pr>
    80000762:	578000ef          	jal	ra,80000cda <release>
  return 0;
    80000766:	bfd1                	j	8000073a <printf+0x298>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1141                	addi	sp,sp,-16
    8000076a:	e406                	sd	ra,8(sp)
    8000076c:	e022                	sd	s0,0(sp)
    8000076e:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    80000770:	00007597          	auipc	a1,0x7
    80000774:	8b058593          	addi	a1,a1,-1872 # 80007020 <etext+0x20>
    80000778:	0000f517          	auipc	a0,0xf
    8000077c:	2f050513          	addi	a0,a0,752 # 8000fa68 <pr>
    80000780:	442000ef          	jal	ra,80000bc2 <initlock>
}
    80000784:	60a2                	ld	ra,8(sp)
    80000786:	6402                	ld	s0,0(sp)
    80000788:	0141                	addi	sp,sp,16
    8000078a:	8082                	ret

000000008000078c <backtrace>:
void
backtrace(void)
{
    8000078c:	7179                	addi	sp,sp,-48
    8000078e:	f406                	sd	ra,40(sp)
    80000790:	f022                	sd	s0,32(sp)
    80000792:	ec26                	sd	s1,24(sp)
    80000794:	e84a                	sd	s2,16(sp)
    80000796:	e44e                	sd	s3,8(sp)
    80000798:	1800                	addi	s0,sp,48
typedef uint64 *pagetable_t; // 512 PTEs
static inline uint64
r_fp()
{
  uint64 x;
  asm volatile("mv %0, s0" : "=r" (x));
    8000079a:	84a2                	mv	s1,s0
  uint64 fp = r_fp();   // current frame pointer
  printf("backtrace:\n");
    8000079c:	00007517          	auipc	a0,0x7
    800007a0:	88c50513          	addi	a0,a0,-1908 # 80007028 <etext+0x28>
    800007a4:	cffff0ef          	jal	ra,800004a2 <printf>

  while (fp != 0) {
    // return address is stored at fp-8
    uint64 ra = *(uint64*)(fp - 8);
    printf("  %p\n", (void*)ra);
    800007a8:	00007917          	auipc	s2,0x7
    800007ac:	89090913          	addi	s2,s2,-1904 # 80007038 <etext+0x38>

    // previous frame pointer is stored at fp-16
    fp = *(uint64*)(fp - 16);

    // stop if we go outside the current kernel stack page
    if (fp == 0 || PGROUNDDOWN(fp) != PGROUNDDOWN(r_fp()))
    800007b0:	79fd                	lui	s3,0xfffff
  while (fp != 0) {
    800007b2:	cc91                	beqz	s1,800007ce <backtrace+0x42>
    printf("  %p\n", (void*)ra);
    800007b4:	ff84b583          	ld	a1,-8(s1)
    800007b8:	854a                	mv	a0,s2
    800007ba:	ce9ff0ef          	jal	ra,800004a2 <printf>
    fp = *(uint64*)(fp - 16);
    800007be:	ff04b483          	ld	s1,-16(s1)
    if (fp == 0 || PGROUNDDOWN(fp) != PGROUNDDOWN(r_fp()))
    800007c2:	c491                	beqz	s1,800007ce <backtrace+0x42>
    800007c4:	87a2                	mv	a5,s0
    800007c6:	8fa5                	xor	a5,a5,s1
    800007c8:	0137f7b3          	and	a5,a5,s3
    800007cc:	d3fd                	beqz	a5,800007b2 <backtrace+0x26>
      break;
  }
}
    800007ce:	70a2                	ld	ra,40(sp)
    800007d0:	7402                	ld	s0,32(sp)
    800007d2:	64e2                	ld	s1,24(sp)
    800007d4:	6942                	ld	s2,16(sp)
    800007d6:	69a2                	ld	s3,8(sp)
    800007d8:	6145                	addi	sp,sp,48
    800007da:	8082                	ret

00000000800007dc <panic>:
{
    800007dc:	1101                	addi	sp,sp,-32
    800007de:	ec06                	sd	ra,24(sp)
    800007e0:	e822                	sd	s0,16(sp)
    800007e2:	e426                	sd	s1,8(sp)
    800007e4:	e04a                	sd	s2,0(sp)
    800007e6:	1000                	addi	s0,sp,32
    800007e8:	84aa                	mv	s1,a0
  panicking = 1;
    800007ea:	4905                	li	s2,1
    800007ec:	00007797          	auipc	a5,0x7
    800007f0:	1927ac23          	sw	s2,408(a5) # 80007984 <panicking>
  printf("panic: ");
    800007f4:	00007517          	auipc	a0,0x7
    800007f8:	84c50513          	addi	a0,a0,-1972 # 80007040 <etext+0x40>
    800007fc:	ca7ff0ef          	jal	ra,800004a2 <printf>
  printf("%s\n", s);
    80000800:	85a6                	mv	a1,s1
    80000802:	00007517          	auipc	a0,0x7
    80000806:	84650513          	addi	a0,a0,-1978 # 80007048 <etext+0x48>
    8000080a:	c99ff0ef          	jal	ra,800004a2 <printf>
  backtrace();  
    8000080e:	f7fff0ef          	jal	ra,8000078c <backtrace>
  panicked = 1; // freeze uart output from other CPUs
    80000812:	00007797          	auipc	a5,0x7
    80000816:	1727a723          	sw	s2,366(a5) # 80007980 <panicked>
  for(;;)
    8000081a:	a001                	j	8000081a <panic+0x3e>

000000008000081c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000081c:	1141                	addi	sp,sp,-16
    8000081e:	e406                	sd	ra,8(sp)
    80000820:	e022                	sd	s0,0(sp)
    80000822:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000824:	100007b7          	lui	a5,0x10000
    80000828:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000082c:	f8000713          	li	a4,-128
    80000830:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000834:	470d                	li	a4,3
    80000836:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000083a:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000083e:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000842:	469d                	li	a3,7
    80000844:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000848:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000084c:	00007597          	auipc	a1,0x7
    80000850:	81c58593          	addi	a1,a1,-2020 # 80007068 <digits+0x18>
    80000854:	0000f517          	auipc	a0,0xf
    80000858:	22c50513          	addi	a0,a0,556 # 8000fa80 <uart_tx_lock>
    8000085c:	366000ef          	jal	ra,80000bc2 <initlock>
}
    80000860:	60a2                	ld	ra,8(sp)
    80000862:	6402                	ld	s0,0(sp)
    80000864:	0141                	addi	sp,sp,16
    80000866:	8082                	ret

0000000080000868 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000868:	1101                	addi	sp,sp,-32
    8000086a:	ec06                	sd	ra,24(sp)
    8000086c:	e822                	sd	s0,16(sp)
    8000086e:	e426                	sd	s1,8(sp)
    80000870:	1000                	addi	s0,sp,32
    80000872:	84aa                	mv	s1,a0
  if(panicking == 0)
    80000874:	00007797          	auipc	a5,0x7
    80000878:	1107a783          	lw	a5,272(a5) # 80007984 <panicking>
    8000087c:	cb89                	beqz	a5,8000088e <uartputc_sync+0x26>
    push_off();

  if(panicked){
    8000087e:	00007797          	auipc	a5,0x7
    80000882:	1027a783          	lw	a5,258(a5) # 80007980 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000886:	10000737          	lui	a4,0x10000
  if(panicked){
    8000088a:	c789                	beqz	a5,80000894 <uartputc_sync+0x2c>
    for(;;)
    8000088c:	a001                	j	8000088c <uartputc_sync+0x24>
    push_off();
    8000088e:	374000ef          	jal	ra,80000c02 <push_off>
    80000892:	b7f5                	j	8000087e <uartputc_sync+0x16>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000894:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000898:	0207f793          	andi	a5,a5,32
    8000089c:	dfe5                	beqz	a5,80000894 <uartputc_sync+0x2c>
    ;
  WriteReg(THR, c);
    8000089e:	0ff4f513          	zext.b	a0,s1
    800008a2:	100007b7          	lui	a5,0x10000
    800008a6:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    800008aa:	00007797          	auipc	a5,0x7
    800008ae:	0da7a783          	lw	a5,218(a5) # 80007984 <panicking>
    800008b2:	c791                	beqz	a5,800008be <uartputc_sync+0x56>
    pop_off();
}
    800008b4:	60e2                	ld	ra,24(sp)
    800008b6:	6442                	ld	s0,16(sp)
    800008b8:	64a2                	ld	s1,8(sp)
    800008ba:	6105                	addi	sp,sp,32
    800008bc:	8082                	ret
    pop_off();
    800008be:	3c8000ef          	jal	ra,80000c86 <pop_off>
}
    800008c2:	bfcd                	j	800008b4 <uartputc_sync+0x4c>

00000000800008c4 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008c4:	00007797          	auipc	a5,0x7
    800008c8:	0c47b783          	ld	a5,196(a5) # 80007988 <uart_tx_r>
    800008cc:	00007717          	auipc	a4,0x7
    800008d0:	0c473703          	ld	a4,196(a4) # 80007990 <uart_tx_w>
    800008d4:	06f70863          	beq	a4,a5,80000944 <uartstart+0x80>
{
    800008d8:	7139                	addi	sp,sp,-64
    800008da:	fc06                	sd	ra,56(sp)
    800008dc:	f822                	sd	s0,48(sp)
    800008de:	f426                	sd	s1,40(sp)
    800008e0:	f04a                	sd	s2,32(sp)
    800008e2:	ec4e                	sd	s3,24(sp)
    800008e4:	e852                	sd	s4,16(sp)
    800008e6:	e456                	sd	s5,8(sp)
    800008e8:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008ea:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008ee:	0000fa17          	auipc	s4,0xf
    800008f2:	192a0a13          	addi	s4,s4,402 # 8000fa80 <uart_tx_lock>
    uart_tx_r += 1;
    800008f6:	00007497          	auipc	s1,0x7
    800008fa:	09248493          	addi	s1,s1,146 # 80007988 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008fe:	00007997          	auipc	s3,0x7
    80000902:	09298993          	addi	s3,s3,146 # 80007990 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000906:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000090a:	02077713          	andi	a4,a4,32
    8000090e:	c315                	beqz	a4,80000932 <uartstart+0x6e>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000910:	01f7f713          	andi	a4,a5,31
    80000914:	9752                	add	a4,a4,s4
    80000916:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000091a:	0785                	addi	a5,a5,1
    8000091c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000091e:	8526                	mv	a0,s1
    80000920:	5ec010ef          	jal	ra,80001f0c <wakeup>
    
    WriteReg(THR, c);
    80000924:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	0009b703          	ld	a4,0(s3)
    8000092e:	fcf71ce3          	bne	a4,a5,80000906 <uartstart+0x42>
  }
}
    80000932:	70e2                	ld	ra,56(sp)
    80000934:	7442                	ld	s0,48(sp)
    80000936:	74a2                	ld	s1,40(sp)
    80000938:	7902                	ld	s2,32(sp)
    8000093a:	69e2                	ld	s3,24(sp)
    8000093c:	6a42                	ld	s4,16(sp)
    8000093e:	6aa2                	ld	s5,8(sp)
    80000940:	6121                	addi	sp,sp,64
    80000942:	8082                	ret
    80000944:	8082                	ret

0000000080000946 <uartputc>:
{
    80000946:	7179                	addi	sp,sp,-48
    80000948:	f406                	sd	ra,40(sp)
    8000094a:	f022                	sd	s0,32(sp)
    8000094c:	ec26                	sd	s1,24(sp)
    8000094e:	e84a                	sd	s2,16(sp)
    80000950:	e44e                	sd	s3,8(sp)
    80000952:	e052                	sd	s4,0(sp)
    80000954:	1800                	addi	s0,sp,48
    80000956:	8a2a                	mv	s4,a0
  if(panicking == 0)
    80000958:	00007797          	auipc	a5,0x7
    8000095c:	02c7a783          	lw	a5,44(a5) # 80007984 <panicking>
    80000960:	c7d1                	beqz	a5,800009ec <uartputc+0xa6>
  if(panicked){
    80000962:	00007797          	auipc	a5,0x7
    80000966:	01e7a783          	lw	a5,30(a5) # 80007980 <panicked>
    8000096a:	ebc1                	bnez	a5,800009fa <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000096c:	00007717          	auipc	a4,0x7
    80000970:	02473703          	ld	a4,36(a4) # 80007990 <uart_tx_w>
    80000974:	00007797          	auipc	a5,0x7
    80000978:	0147b783          	ld	a5,20(a5) # 80007988 <uart_tx_r>
    8000097c:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000980:	0000f997          	auipc	s3,0xf
    80000984:	10098993          	addi	s3,s3,256 # 8000fa80 <uart_tx_lock>
    80000988:	00007497          	auipc	s1,0x7
    8000098c:	00048493          	mv	s1,s1
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000990:	00007917          	auipc	s2,0x7
    80000994:	00090913          	mv	s2,s2
    80000998:	00e79d63          	bne	a5,a4,800009b2 <uartputc+0x6c>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000099c:	85ce                	mv	a1,s3
    8000099e:	8526                	mv	a0,s1
    800009a0:	520010ef          	jal	ra,80001ec0 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800009a4:	00093703          	ld	a4,0(s2) # 80007990 <uart_tx_w>
    800009a8:	609c                	ld	a5,0(s1)
    800009aa:	02078793          	addi	a5,a5,32
    800009ae:	fee787e3          	beq	a5,a4,8000099c <uartputc+0x56>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    800009b2:	01f77693          	andi	a3,a4,31
    800009b6:	0000f797          	auipc	a5,0xf
    800009ba:	0ca78793          	addi	a5,a5,202 # 8000fa80 <uart_tx_lock>
    800009be:	97b6                	add	a5,a5,a3
    800009c0:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009c4:	0705                	addi	a4,a4,1
    800009c6:	00007797          	auipc	a5,0x7
    800009ca:	fce7b523          	sd	a4,-54(a5) # 80007990 <uart_tx_w>
  uartstart();
    800009ce:	ef7ff0ef          	jal	ra,800008c4 <uartstart>
  if(panicking == 0)
    800009d2:	00007797          	auipc	a5,0x7
    800009d6:	fb27a783          	lw	a5,-78(a5) # 80007984 <panicking>
    800009da:	c38d                	beqz	a5,800009fc <uartputc+0xb6>
}
    800009dc:	70a2                	ld	ra,40(sp)
    800009de:	7402                	ld	s0,32(sp)
    800009e0:	64e2                	ld	s1,24(sp)
    800009e2:	6942                	ld	s2,16(sp)
    800009e4:	69a2                	ld	s3,8(sp)
    800009e6:	6a02                	ld	s4,0(sp)
    800009e8:	6145                	addi	sp,sp,48
    800009ea:	8082                	ret
    acquire(&uart_tx_lock);
    800009ec:	0000f517          	auipc	a0,0xf
    800009f0:	09450513          	addi	a0,a0,148 # 8000fa80 <uart_tx_lock>
    800009f4:	24e000ef          	jal	ra,80000c42 <acquire>
    800009f8:	b7ad                	j	80000962 <uartputc+0x1c>
    for(;;)
    800009fa:	a001                	j	800009fa <uartputc+0xb4>
    release(&uart_tx_lock);
    800009fc:	0000f517          	auipc	a0,0xf
    80000a00:	08450513          	addi	a0,a0,132 # 8000fa80 <uart_tx_lock>
    80000a04:	2d6000ef          	jal	ra,80000cda <release>
}
    80000a08:	bfd1                	j	800009dc <uartputc+0x96>

0000000080000a0a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000a0a:	1141                	addi	sp,sp,-16
    80000a0c:	e422                	sd	s0,8(sp)
    80000a0e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000a10:	100007b7          	lui	a5,0x10000
    80000a14:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a18:	8b85                	andi	a5,a5,1
    80000a1a:	cb91                	beqz	a5,80000a2e <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a1c:	100007b7          	lui	a5,0x10000
    80000a20:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a24:	0ff57513          	zext.b	a0,a0
  } else {
    return -1;
  }
}
    80000a28:	6422                	ld	s0,8(sp)
    80000a2a:	0141                	addi	sp,sp,16
    80000a2c:	8082                	ret
    return -1;
    80000a2e:	557d                	li	a0,-1
    80000a30:	bfe5                	j	80000a28 <uartgetc+0x1e>

0000000080000a32 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000a32:	1101                	addi	sp,sp,-32
    80000a34:	ec06                	sd	ra,24(sp)
    80000a36:	e822                	sd	s0,16(sp)
    80000a38:	e426                	sd	s1,8(sp)
    80000a3a:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    80000a3c:	100007b7          	lui	a5,0x10000
    80000a40:	0027c783          	lbu	a5,2(a5) # 10000002 <_entry-0x6ffffffe>

  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a44:	54fd                	li	s1,-1
    80000a46:	a019                	j	80000a4c <uartintr+0x1a>
      break;
    consoleintr(c);
    80000a48:	811ff0ef          	jal	ra,80000258 <consoleintr>
    int c = uartgetc();
    80000a4c:	fbfff0ef          	jal	ra,80000a0a <uartgetc>
    if(c == -1)
    80000a50:	fe951ce3          	bne	a0,s1,80000a48 <uartintr+0x16>
  }

  // send buffered characters.
  if(panicking == 0)
    80000a54:	00007797          	auipc	a5,0x7
    80000a58:	f307a783          	lw	a5,-208(a5) # 80007984 <panicking>
    80000a5c:	cf89                	beqz	a5,80000a76 <uartintr+0x44>
    acquire(&uart_tx_lock);
  uartstart();
    80000a5e:	e67ff0ef          	jal	ra,800008c4 <uartstart>
  if(panicking == 0)
    80000a62:	00007797          	auipc	a5,0x7
    80000a66:	f227a783          	lw	a5,-222(a5) # 80007984 <panicking>
    80000a6a:	cf89                	beqz	a5,80000a84 <uartintr+0x52>
    release(&uart_tx_lock);
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    acquire(&uart_tx_lock);
    80000a76:	0000f517          	auipc	a0,0xf
    80000a7a:	00a50513          	addi	a0,a0,10 # 8000fa80 <uart_tx_lock>
    80000a7e:	1c4000ef          	jal	ra,80000c42 <acquire>
    80000a82:	bff1                	j	80000a5e <uartintr+0x2c>
    release(&uart_tx_lock);
    80000a84:	0000f517          	auipc	a0,0xf
    80000a88:	ffc50513          	addi	a0,a0,-4 # 8000fa80 <uart_tx_lock>
    80000a8c:	24e000ef          	jal	ra,80000cda <release>
}
    80000a90:	bff1                	j	80000a6c <uartintr+0x3a>

0000000080000a92 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a92:	1101                	addi	sp,sp,-32
    80000a94:	ec06                	sd	ra,24(sp)
    80000a96:	e822                	sd	s0,16(sp)
    80000a98:	e426                	sd	s1,8(sp)
    80000a9a:	e04a                	sd	s2,0(sp)
    80000a9c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a9e:	03451793          	slli	a5,a0,0x34
    80000aa2:	e7a9                	bnez	a5,80000aec <kfree+0x5a>
    80000aa4:	84aa                	mv	s1,a0
    80000aa6:	00020797          	auipc	a5,0x20
    80000aaa:	44278793          	addi	a5,a5,1090 # 80020ee8 <end>
    80000aae:	02f56f63          	bltu	a0,a5,80000aec <kfree+0x5a>
    80000ab2:	47c5                	li	a5,17
    80000ab4:	07ee                	slli	a5,a5,0x1b
    80000ab6:	02f57b63          	bgeu	a0,a5,80000aec <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000aba:	6605                	lui	a2,0x1
    80000abc:	4585                	li	a1,1
    80000abe:	258000ef          	jal	ra,80000d16 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000ac2:	0000f917          	auipc	s2,0xf
    80000ac6:	ff690913          	addi	s2,s2,-10 # 8000fab8 <kmem>
    80000aca:	854a                	mv	a0,s2
    80000acc:	176000ef          	jal	ra,80000c42 <acquire>
  r->next = kmem.freelist;
    80000ad0:	01893783          	ld	a5,24(s2)
    80000ad4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ad6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000ada:	854a                	mv	a0,s2
    80000adc:	1fe000ef          	jal	ra,80000cda <release>
}
    80000ae0:	60e2                	ld	ra,24(sp)
    80000ae2:	6442                	ld	s0,16(sp)
    80000ae4:	64a2                	ld	s1,8(sp)
    80000ae6:	6902                	ld	s2,0(sp)
    80000ae8:	6105                	addi	sp,sp,32
    80000aea:	8082                	ret
    panic("kfree");
    80000aec:	00006517          	auipc	a0,0x6
    80000af0:	58450513          	addi	a0,a0,1412 # 80007070 <digits+0x20>
    80000af4:	ce9ff0ef          	jal	ra,800007dc <panic>

0000000080000af8 <freerange>:
{
    80000af8:	7179                	addi	sp,sp,-48
    80000afa:	f406                	sd	ra,40(sp)
    80000afc:	f022                	sd	s0,32(sp)
    80000afe:	ec26                	sd	s1,24(sp)
    80000b00:	e84a                	sd	s2,16(sp)
    80000b02:	e44e                	sd	s3,8(sp)
    80000b04:	e052                	sd	s4,0(sp)
    80000b06:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b08:	6785                	lui	a5,0x1
    80000b0a:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b0e:	94aa                	add	s1,s1,a0
    80000b10:	757d                	lui	a0,0xfffff
    80000b12:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b14:	94be                	add	s1,s1,a5
    80000b16:	0095ec63          	bltu	a1,s1,80000b2e <freerange+0x36>
    80000b1a:	892e                	mv	s2,a1
    kfree(p);
    80000b1c:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b1e:	6985                	lui	s3,0x1
    kfree(p);
    80000b20:	01448533          	add	a0,s1,s4
    80000b24:	f6fff0ef          	jal	ra,80000a92 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b28:	94ce                	add	s1,s1,s3
    80000b2a:	fe997be3          	bgeu	s2,s1,80000b20 <freerange+0x28>
}
    80000b2e:	70a2                	ld	ra,40(sp)
    80000b30:	7402                	ld	s0,32(sp)
    80000b32:	64e2                	ld	s1,24(sp)
    80000b34:	6942                	ld	s2,16(sp)
    80000b36:	69a2                	ld	s3,8(sp)
    80000b38:	6a02                	ld	s4,0(sp)
    80000b3a:	6145                	addi	sp,sp,48
    80000b3c:	8082                	ret

0000000080000b3e <kinit>:
{
    80000b3e:	1141                	addi	sp,sp,-16
    80000b40:	e406                	sd	ra,8(sp)
    80000b42:	e022                	sd	s0,0(sp)
    80000b44:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b46:	00006597          	auipc	a1,0x6
    80000b4a:	53258593          	addi	a1,a1,1330 # 80007078 <digits+0x28>
    80000b4e:	0000f517          	auipc	a0,0xf
    80000b52:	f6a50513          	addi	a0,a0,-150 # 8000fab8 <kmem>
    80000b56:	06c000ef          	jal	ra,80000bc2 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b5a:	45c5                	li	a1,17
    80000b5c:	05ee                	slli	a1,a1,0x1b
    80000b5e:	00020517          	auipc	a0,0x20
    80000b62:	38a50513          	addi	a0,a0,906 # 80020ee8 <end>
    80000b66:	f93ff0ef          	jal	ra,80000af8 <freerange>
}
    80000b6a:	60a2                	ld	ra,8(sp)
    80000b6c:	6402                	ld	s0,0(sp)
    80000b6e:	0141                	addi	sp,sp,16
    80000b70:	8082                	ret

0000000080000b72 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b7c:	0000f497          	auipc	s1,0xf
    80000b80:	f3c48493          	addi	s1,s1,-196 # 8000fab8 <kmem>
    80000b84:	8526                	mv	a0,s1
    80000b86:	0bc000ef          	jal	ra,80000c42 <acquire>
  r = kmem.freelist;
    80000b8a:	6c84                	ld	s1,24(s1)
  if(r)
    80000b8c:	c485                	beqz	s1,80000bb4 <kalloc+0x42>
    kmem.freelist = r->next;
    80000b8e:	609c                	ld	a5,0(s1)
    80000b90:	0000f517          	auipc	a0,0xf
    80000b94:	f2850513          	addi	a0,a0,-216 # 8000fab8 <kmem>
    80000b98:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b9a:	140000ef          	jal	ra,80000cda <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b9e:	6605                	lui	a2,0x1
    80000ba0:	4595                	li	a1,5
    80000ba2:	8526                	mv	a0,s1
    80000ba4:	172000ef          	jal	ra,80000d16 <memset>
  return (void*)r;
}
    80000ba8:	8526                	mv	a0,s1
    80000baa:	60e2                	ld	ra,24(sp)
    80000bac:	6442                	ld	s0,16(sp)
    80000bae:	64a2                	ld	s1,8(sp)
    80000bb0:	6105                	addi	sp,sp,32
    80000bb2:	8082                	ret
  release(&kmem.lock);
    80000bb4:	0000f517          	auipc	a0,0xf
    80000bb8:	f0450513          	addi	a0,a0,-252 # 8000fab8 <kmem>
    80000bbc:	11e000ef          	jal	ra,80000cda <release>
  if(r)
    80000bc0:	b7e5                	j	80000ba8 <kalloc+0x36>

0000000080000bc2 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bc2:	1141                	addi	sp,sp,-16
    80000bc4:	e422                	sd	s0,8(sp)
    80000bc6:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bc8:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bca:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bce:	00053823          	sd	zero,16(a0)
}
    80000bd2:	6422                	ld	s0,8(sp)
    80000bd4:	0141                	addi	sp,sp,16
    80000bd6:	8082                	ret

0000000080000bd8 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bd8:	411c                	lw	a5,0(a0)
    80000bda:	e399                	bnez	a5,80000be0 <holding+0x8>
    80000bdc:	4501                	li	a0,0
  return r;
}
    80000bde:	8082                	ret
{
    80000be0:	1101                	addi	sp,sp,-32
    80000be2:	ec06                	sd	ra,24(sp)
    80000be4:	e822                	sd	s0,16(sp)
    80000be6:	e426                	sd	s1,8(sp)
    80000be8:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bea:	6904                	ld	s1,16(a0)
    80000bec:	4d3000ef          	jal	ra,800018be <mycpu>
    80000bf0:	40a48533          	sub	a0,s1,a0
    80000bf4:	00153513          	seqz	a0,a0
}
    80000bf8:	60e2                	ld	ra,24(sp)
    80000bfa:	6442                	ld	s0,16(sp)
    80000bfc:	64a2                	ld	s1,8(sp)
    80000bfe:	6105                	addi	sp,sp,32
    80000c00:	8082                	ret

0000000080000c02 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c02:	1101                	addi	sp,sp,-32
    80000c04:	ec06                	sd	ra,24(sp)
    80000c06:	e822                	sd	s0,16(sp)
    80000c08:	e426                	sd	s1,8(sp)
    80000c0a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c0c:	100024f3          	csrr	s1,sstatus
    80000c10:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c14:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c16:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000c1a:	4a5000ef          	jal	ra,800018be <mycpu>
    80000c1e:	5d3c                	lw	a5,120(a0)
    80000c20:	cb99                	beqz	a5,80000c36 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c22:	49d000ef          	jal	ra,800018be <mycpu>
    80000c26:	5d3c                	lw	a5,120(a0)
    80000c28:	2785                	addiw	a5,a5,1
    80000c2a:	dd3c                	sw	a5,120(a0)
}
    80000c2c:	60e2                	ld	ra,24(sp)
    80000c2e:	6442                	ld	s0,16(sp)
    80000c30:	64a2                	ld	s1,8(sp)
    80000c32:	6105                	addi	sp,sp,32
    80000c34:	8082                	ret
    mycpu()->intena = old;
    80000c36:	489000ef          	jal	ra,800018be <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c3a:	8085                	srli	s1,s1,0x1
    80000c3c:	8885                	andi	s1,s1,1
    80000c3e:	dd64                	sw	s1,124(a0)
    80000c40:	b7cd                	j	80000c22 <push_off+0x20>

0000000080000c42 <acquire>:
{
    80000c42:	1101                	addi	sp,sp,-32
    80000c44:	ec06                	sd	ra,24(sp)
    80000c46:	e822                	sd	s0,16(sp)
    80000c48:	e426                	sd	s1,8(sp)
    80000c4a:	1000                	addi	s0,sp,32
    80000c4c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c4e:	fb5ff0ef          	jal	ra,80000c02 <push_off>
  if(holding(lk))
    80000c52:	8526                	mv	a0,s1
    80000c54:	f85ff0ef          	jal	ra,80000bd8 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c58:	4705                	li	a4,1
  if(holding(lk))
    80000c5a:	e105                	bnez	a0,80000c7a <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c5c:	87ba                	mv	a5,a4
    80000c5e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c62:	2781                	sext.w	a5,a5
    80000c64:	ffe5                	bnez	a5,80000c5c <acquire+0x1a>
  __sync_synchronize();
    80000c66:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c6a:	455000ef          	jal	ra,800018be <mycpu>
    80000c6e:	e888                	sd	a0,16(s1)
}
    80000c70:	60e2                	ld	ra,24(sp)
    80000c72:	6442                	ld	s0,16(sp)
    80000c74:	64a2                	ld	s1,8(sp)
    80000c76:	6105                	addi	sp,sp,32
    80000c78:	8082                	ret
    panic("acquire");
    80000c7a:	00006517          	auipc	a0,0x6
    80000c7e:	40650513          	addi	a0,a0,1030 # 80007080 <digits+0x30>
    80000c82:	b5bff0ef          	jal	ra,800007dc <panic>

0000000080000c86 <pop_off>:

void
pop_off(void)
{
    80000c86:	1141                	addi	sp,sp,-16
    80000c88:	e406                	sd	ra,8(sp)
    80000c8a:	e022                	sd	s0,0(sp)
    80000c8c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c8e:	431000ef          	jal	ra,800018be <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c92:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c96:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c98:	e78d                	bnez	a5,80000cc2 <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c9a:	5d3c                	lw	a5,120(a0)
    80000c9c:	02f05963          	blez	a5,80000cce <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000ca0:	37fd                	addiw	a5,a5,-1
    80000ca2:	0007871b          	sext.w	a4,a5
    80000ca6:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000ca8:	eb09                	bnez	a4,80000cba <pop_off+0x34>
    80000caa:	5d7c                	lw	a5,124(a0)
    80000cac:	c799                	beqz	a5,80000cba <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cb2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cb6:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cba:	60a2                	ld	ra,8(sp)
    80000cbc:	6402                	ld	s0,0(sp)
    80000cbe:	0141                	addi	sp,sp,16
    80000cc0:	8082                	ret
    panic("pop_off - interruptible");
    80000cc2:	00006517          	auipc	a0,0x6
    80000cc6:	3c650513          	addi	a0,a0,966 # 80007088 <digits+0x38>
    80000cca:	b13ff0ef          	jal	ra,800007dc <panic>
    panic("pop_off");
    80000cce:	00006517          	auipc	a0,0x6
    80000cd2:	3d250513          	addi	a0,a0,978 # 800070a0 <digits+0x50>
    80000cd6:	b07ff0ef          	jal	ra,800007dc <panic>

0000000080000cda <release>:
{
    80000cda:	1101                	addi	sp,sp,-32
    80000cdc:	ec06                	sd	ra,24(sp)
    80000cde:	e822                	sd	s0,16(sp)
    80000ce0:	e426                	sd	s1,8(sp)
    80000ce2:	1000                	addi	s0,sp,32
    80000ce4:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ce6:	ef3ff0ef          	jal	ra,80000bd8 <holding>
    80000cea:	c105                	beqz	a0,80000d0a <release+0x30>
  lk->cpu = 0;
    80000cec:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cf0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cf4:	0f50000f          	fence	iorw,ow
    80000cf8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cfc:	f8bff0ef          	jal	ra,80000c86 <pop_off>
}
    80000d00:	60e2                	ld	ra,24(sp)
    80000d02:	6442                	ld	s0,16(sp)
    80000d04:	64a2                	ld	s1,8(sp)
    80000d06:	6105                	addi	sp,sp,32
    80000d08:	8082                	ret
    panic("release");
    80000d0a:	00006517          	auipc	a0,0x6
    80000d0e:	39e50513          	addi	a0,a0,926 # 800070a8 <digits+0x58>
    80000d12:	acbff0ef          	jal	ra,800007dc <panic>

0000000080000d16 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d16:	1141                	addi	sp,sp,-16
    80000d18:	e422                	sd	s0,8(sp)
    80000d1a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d1c:	ca19                	beqz	a2,80000d32 <memset+0x1c>
    80000d1e:	87aa                	mv	a5,a0
    80000d20:	1602                	slli	a2,a2,0x20
    80000d22:	9201                	srli	a2,a2,0x20
    80000d24:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d28:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d2c:	0785                	addi	a5,a5,1
    80000d2e:	fee79de3          	bne	a5,a4,80000d28 <memset+0x12>
  }
  return dst;
}
    80000d32:	6422                	ld	s0,8(sp)
    80000d34:	0141                	addi	sp,sp,16
    80000d36:	8082                	ret

0000000080000d38 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d38:	1141                	addi	sp,sp,-16
    80000d3a:	e422                	sd	s0,8(sp)
    80000d3c:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d3e:	ca05                	beqz	a2,80000d6e <memcmp+0x36>
    80000d40:	fff6069b          	addiw	a3,a2,-1
    80000d44:	1682                	slli	a3,a3,0x20
    80000d46:	9281                	srli	a3,a3,0x20
    80000d48:	0685                	addi	a3,a3,1
    80000d4a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d4c:	00054783          	lbu	a5,0(a0)
    80000d50:	0005c703          	lbu	a4,0(a1)
    80000d54:	00e79863          	bne	a5,a4,80000d64 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d58:	0505                	addi	a0,a0,1
    80000d5a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d5c:	fed518e3          	bne	a0,a3,80000d4c <memcmp+0x14>
  }

  return 0;
    80000d60:	4501                	li	a0,0
    80000d62:	a019                	j	80000d68 <memcmp+0x30>
      return *s1 - *s2;
    80000d64:	40e7853b          	subw	a0,a5,a4
}
    80000d68:	6422                	ld	s0,8(sp)
    80000d6a:	0141                	addi	sp,sp,16
    80000d6c:	8082                	ret
  return 0;
    80000d6e:	4501                	li	a0,0
    80000d70:	bfe5                	j	80000d68 <memcmp+0x30>

0000000080000d72 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d72:	1141                	addi	sp,sp,-16
    80000d74:	e422                	sd	s0,8(sp)
    80000d76:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d78:	c205                	beqz	a2,80000d98 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d7a:	02a5e263          	bltu	a1,a0,80000d9e <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d7e:	1602                	slli	a2,a2,0x20
    80000d80:	9201                	srli	a2,a2,0x20
    80000d82:	00c587b3          	add	a5,a1,a2
{
    80000d86:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d88:	0585                	addi	a1,a1,1
    80000d8a:	0705                	addi	a4,a4,1
    80000d8c:	fff5c683          	lbu	a3,-1(a1)
    80000d90:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d94:	fef59ae3          	bne	a1,a5,80000d88 <memmove+0x16>

  return dst;
}
    80000d98:	6422                	ld	s0,8(sp)
    80000d9a:	0141                	addi	sp,sp,16
    80000d9c:	8082                	ret
  if(s < d && s + n > d){
    80000d9e:	02061693          	slli	a3,a2,0x20
    80000da2:	9281                	srli	a3,a3,0x20
    80000da4:	00d58733          	add	a4,a1,a3
    80000da8:	fce57be3          	bgeu	a0,a4,80000d7e <memmove+0xc>
    d += n;
    80000dac:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000dae:	fff6079b          	addiw	a5,a2,-1
    80000db2:	1782                	slli	a5,a5,0x20
    80000db4:	9381                	srli	a5,a5,0x20
    80000db6:	fff7c793          	not	a5,a5
    80000dba:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dbc:	177d                	addi	a4,a4,-1
    80000dbe:	16fd                	addi	a3,a3,-1
    80000dc0:	00074603          	lbu	a2,0(a4)
    80000dc4:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dc8:	fee79ae3          	bne	a5,a4,80000dbc <memmove+0x4a>
    80000dcc:	b7f1                	j	80000d98 <memmove+0x26>

0000000080000dce <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dce:	1141                	addi	sp,sp,-16
    80000dd0:	e406                	sd	ra,8(sp)
    80000dd2:	e022                	sd	s0,0(sp)
    80000dd4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd6:	f9dff0ef          	jal	ra,80000d72 <memmove>
}
    80000dda:	60a2                	ld	ra,8(sp)
    80000ddc:	6402                	ld	s0,0(sp)
    80000dde:	0141                	addi	sp,sp,16
    80000de0:	8082                	ret

0000000080000de2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de2:	1141                	addi	sp,sp,-16
    80000de4:	e422                	sd	s0,8(sp)
    80000de6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000de8:	ce11                	beqz	a2,80000e04 <strncmp+0x22>
    80000dea:	00054783          	lbu	a5,0(a0)
    80000dee:	cf89                	beqz	a5,80000e08 <strncmp+0x26>
    80000df0:	0005c703          	lbu	a4,0(a1)
    80000df4:	00f71a63          	bne	a4,a5,80000e08 <strncmp+0x26>
    n--, p++, q++;
    80000df8:	367d                	addiw	a2,a2,-1
    80000dfa:	0505                	addi	a0,a0,1
    80000dfc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dfe:	f675                	bnez	a2,80000dea <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e00:	4501                	li	a0,0
    80000e02:	a809                	j	80000e14 <strncmp+0x32>
    80000e04:	4501                	li	a0,0
    80000e06:	a039                	j	80000e14 <strncmp+0x32>
  if(n == 0)
    80000e08:	ca09                	beqz	a2,80000e1a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e0a:	00054503          	lbu	a0,0(a0)
    80000e0e:	0005c783          	lbu	a5,0(a1)
    80000e12:	9d1d                	subw	a0,a0,a5
}
    80000e14:	6422                	ld	s0,8(sp)
    80000e16:	0141                	addi	sp,sp,16
    80000e18:	8082                	ret
    return 0;
    80000e1a:	4501                	li	a0,0
    80000e1c:	bfe5                	j	80000e14 <strncmp+0x32>

0000000080000e1e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e1e:	1141                	addi	sp,sp,-16
    80000e20:	e422                	sd	s0,8(sp)
    80000e22:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e24:	872a                	mv	a4,a0
    80000e26:	8832                	mv	a6,a2
    80000e28:	367d                	addiw	a2,a2,-1
    80000e2a:	01005963          	blez	a6,80000e3c <strncpy+0x1e>
    80000e2e:	0705                	addi	a4,a4,1
    80000e30:	0005c783          	lbu	a5,0(a1)
    80000e34:	fef70fa3          	sb	a5,-1(a4)
    80000e38:	0585                	addi	a1,a1,1
    80000e3a:	f7f5                	bnez	a5,80000e26 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e3c:	86ba                	mv	a3,a4
    80000e3e:	00c05c63          	blez	a2,80000e56 <strncpy+0x38>
    *s++ = 0;
    80000e42:	0685                	addi	a3,a3,1
    80000e44:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e48:	fff6c793          	not	a5,a3
    80000e4c:	9fb9                	addw	a5,a5,a4
    80000e4e:	010787bb          	addw	a5,a5,a6
    80000e52:	fef048e3          	bgtz	a5,80000e42 <strncpy+0x24>
  return os;
}
    80000e56:	6422                	ld	s0,8(sp)
    80000e58:	0141                	addi	sp,sp,16
    80000e5a:	8082                	ret

0000000080000e5c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e5c:	1141                	addi	sp,sp,-16
    80000e5e:	e422                	sd	s0,8(sp)
    80000e60:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e62:	02c05363          	blez	a2,80000e88 <safestrcpy+0x2c>
    80000e66:	fff6069b          	addiw	a3,a2,-1
    80000e6a:	1682                	slli	a3,a3,0x20
    80000e6c:	9281                	srli	a3,a3,0x20
    80000e6e:	96ae                	add	a3,a3,a1
    80000e70:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e72:	00d58963          	beq	a1,a3,80000e84 <safestrcpy+0x28>
    80000e76:	0585                	addi	a1,a1,1
    80000e78:	0785                	addi	a5,a5,1
    80000e7a:	fff5c703          	lbu	a4,-1(a1)
    80000e7e:	fee78fa3          	sb	a4,-1(a5)
    80000e82:	fb65                	bnez	a4,80000e72 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e84:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e88:	6422                	ld	s0,8(sp)
    80000e8a:	0141                	addi	sp,sp,16
    80000e8c:	8082                	ret

0000000080000e8e <strlen>:

int
strlen(const char *s)
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e422                	sd	s0,8(sp)
    80000e92:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e94:	00054783          	lbu	a5,0(a0)
    80000e98:	cf91                	beqz	a5,80000eb4 <strlen+0x26>
    80000e9a:	0505                	addi	a0,a0,1
    80000e9c:	87aa                	mv	a5,a0
    80000e9e:	4685                	li	a3,1
    80000ea0:	9e89                	subw	a3,a3,a0
    80000ea2:	00f6853b          	addw	a0,a3,a5
    80000ea6:	0785                	addi	a5,a5,1
    80000ea8:	fff7c703          	lbu	a4,-1(a5)
    80000eac:	fb7d                	bnez	a4,80000ea2 <strlen+0x14>
    ;
  return n;
}
    80000eae:	6422                	ld	s0,8(sp)
    80000eb0:	0141                	addi	sp,sp,16
    80000eb2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eb4:	4501                	li	a0,0
    80000eb6:	bfe5                	j	80000eae <strlen+0x20>

0000000080000eb8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000eb8:	1141                	addi	sp,sp,-16
    80000eba:	e406                	sd	ra,8(sp)
    80000ebc:	e022                	sd	s0,0(sp)
    80000ebe:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec0:	1ef000ef          	jal	ra,800018ae <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ec4:	00007717          	auipc	a4,0x7
    80000ec8:	ad470713          	addi	a4,a4,-1324 # 80007998 <started>
  if(cpuid() == 0){
    80000ecc:	c51d                	beqz	a0,80000efa <main+0x42>
    while(started == 0)
    80000ece:	431c                	lw	a5,0(a4)
    80000ed0:	2781                	sext.w	a5,a5
    80000ed2:	dff5                	beqz	a5,80000ece <main+0x16>
      ;
    __sync_synchronize();
    80000ed4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ed8:	1d7000ef          	jal	ra,800018ae <cpuid>
    80000edc:	85aa                	mv	a1,a0
    80000ede:	00006517          	auipc	a0,0x6
    80000ee2:	1ea50513          	addi	a0,a0,490 # 800070c8 <digits+0x78>
    80000ee6:	dbcff0ef          	jal	ra,800004a2 <printf>
    kvminithart();    // turn on paging
    80000eea:	080000ef          	jal	ra,80000f6a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eee:	4f4010ef          	jal	ra,800023e2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef2:	332040ef          	jal	ra,80005224 <plicinithart>
  }

  scheduler();        
    80000ef6:	633000ef          	jal	ra,80001d28 <scheduler>
    consoleinit();
    80000efa:	cd0ff0ef          	jal	ra,800003ca <consoleinit>
    printfinit();
    80000efe:	86bff0ef          	jal	ra,80000768 <printfinit>
    printf("\n");
    80000f02:	00006517          	auipc	a0,0x6
    80000f06:	1d650513          	addi	a0,a0,470 # 800070d8 <digits+0x88>
    80000f0a:	d98ff0ef          	jal	ra,800004a2 <printf>
    printf("xv6 kernel is booting\n");
    80000f0e:	00006517          	auipc	a0,0x6
    80000f12:	1a250513          	addi	a0,a0,418 # 800070b0 <digits+0x60>
    80000f16:	d8cff0ef          	jal	ra,800004a2 <printf>
    printf("\n");
    80000f1a:	00006517          	auipc	a0,0x6
    80000f1e:	1be50513          	addi	a0,a0,446 # 800070d8 <digits+0x88>
    80000f22:	d80ff0ef          	jal	ra,800004a2 <printf>
    kinit();         // physical page allocator
    80000f26:	c19ff0ef          	jal	ra,80000b3e <kinit>
    kvminit();       // create kernel page table
    80000f2a:	2ca000ef          	jal	ra,800011f4 <kvminit>
    kvminithart();   // turn on paging
    80000f2e:	03c000ef          	jal	ra,80000f6a <kvminithart>
    procinit();      // process table
    80000f32:	0d5000ef          	jal	ra,80001806 <procinit>
    trapinit();      // trap vectors
    80000f36:	488010ef          	jal	ra,800023be <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3a:	4a8010ef          	jal	ra,800023e2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3e:	2d0040ef          	jal	ra,8000520e <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	2e2040ef          	jal	ra,80005224 <plicinithart>
    binit();         // buffer cache
    80000f46:	361010ef          	jal	ra,80002aa6 <binit>
    iinit();         // inode table
    80000f4a:	142020ef          	jal	ra,8000308c <iinit>
    fileinit();      // file table
    80000f4e:	6e1020ef          	jal	ra,80003e2e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f52:	3c2040ef          	jal	ra,80005314 <virtio_disk_init>
    userinit();      // first user process
    80000f56:	44b000ef          	jal	ra,80001ba0 <userinit>
    __sync_synchronize();
    80000f5a:	0ff0000f          	fence
    started = 1;
    80000f5e:	4785                	li	a5,1
    80000f60:	00007717          	auipc	a4,0x7
    80000f64:	a2f72c23          	sw	a5,-1480(a4) # 80007998 <started>
    80000f68:	b779                	j	80000ef6 <main+0x3e>

0000000080000f6a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f6a:	1141                	addi	sp,sp,-16
    80000f6c:	e422                	sd	s0,8(sp)
    80000f6e:	0800                	addi	s0,sp,16
  asm volatile("sfence.vma zero, zero");
    80000f70:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f74:	00007797          	auipc	a5,0x7
    80000f78:	a2c7b783          	ld	a5,-1492(a5) # 800079a0 <kernel_pagetable>
    80000f7c:	83b1                	srli	a5,a5,0xc
    80000f7e:	577d                	li	a4,-1
    80000f80:	177e                	slli	a4,a4,0x3f
    80000f82:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f84:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f88:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f8c:	6422                	ld	s0,8(sp)
    80000f8e:	0141                	addi	sp,sp,16
    80000f90:	8082                	ret

0000000080000f92 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f92:	7139                	addi	sp,sp,-64
    80000f94:	fc06                	sd	ra,56(sp)
    80000f96:	f822                	sd	s0,48(sp)
    80000f98:	f426                	sd	s1,40(sp)
    80000f9a:	f04a                	sd	s2,32(sp)
    80000f9c:	ec4e                	sd	s3,24(sp)
    80000f9e:	e852                	sd	s4,16(sp)
    80000fa0:	e456                	sd	s5,8(sp)
    80000fa2:	e05a                	sd	s6,0(sp)
    80000fa4:	0080                	addi	s0,sp,64
    80000fa6:	84aa                	mv	s1,a0
    80000fa8:	89ae                	mv	s3,a1
    80000faa:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fac:	57fd                	li	a5,-1
    80000fae:	83e9                	srli	a5,a5,0x1a
    80000fb0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fb2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fb4:	02b7fc63          	bgeu	a5,a1,80000fec <walk+0x5a>
    panic("walk");
    80000fb8:	00006517          	auipc	a0,0x6
    80000fbc:	12850513          	addi	a0,a0,296 # 800070e0 <digits+0x90>
    80000fc0:	81dff0ef          	jal	ra,800007dc <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fc4:	060a8263          	beqz	s5,80001028 <walk+0x96>
    80000fc8:	babff0ef          	jal	ra,80000b72 <kalloc>
    80000fcc:	84aa                	mv	s1,a0
    80000fce:	c139                	beqz	a0,80001014 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fd0:	6605                	lui	a2,0x1
    80000fd2:	4581                	li	a1,0
    80000fd4:	d43ff0ef          	jal	ra,80000d16 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000fd8:	00c4d793          	srli	a5,s1,0xc
    80000fdc:	07aa                	slli	a5,a5,0xa
    80000fde:	0017e793          	ori	a5,a5,1
    80000fe2:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000fe6:	3a5d                	addiw	s4,s4,-9
    80000fe8:	036a0063          	beq	s4,s6,80001008 <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000fec:	0149d933          	srl	s2,s3,s4
    80000ff0:	1ff97913          	andi	s2,s2,511
    80000ff4:	090e                	slli	s2,s2,0x3
    80000ff6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000ff8:	00093483          	ld	s1,0(s2)
    80000ffc:	0014f793          	andi	a5,s1,1
    80001000:	d3f1                	beqz	a5,80000fc4 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001002:	80a9                	srli	s1,s1,0xa
    80001004:	04b2                	slli	s1,s1,0xc
    80001006:	b7c5                	j	80000fe6 <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80001008:	00c9d513          	srli	a0,s3,0xc
    8000100c:	1ff57513          	andi	a0,a0,511
    80001010:	050e                	slli	a0,a0,0x3
    80001012:	9526                	add	a0,a0,s1
}
    80001014:	70e2                	ld	ra,56(sp)
    80001016:	7442                	ld	s0,48(sp)
    80001018:	74a2                	ld	s1,40(sp)
    8000101a:	7902                	ld	s2,32(sp)
    8000101c:	69e2                	ld	s3,24(sp)
    8000101e:	6a42                	ld	s4,16(sp)
    80001020:	6aa2                	ld	s5,8(sp)
    80001022:	6b02                	ld	s6,0(sp)
    80001024:	6121                	addi	sp,sp,64
    80001026:	8082                	ret
        return 0;
    80001028:	4501                	li	a0,0
    8000102a:	b7ed                	j	80001014 <walk+0x82>

000000008000102c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000102c:	57fd                	li	a5,-1
    8000102e:	83e9                	srli	a5,a5,0x1a
    80001030:	00b7f463          	bgeu	a5,a1,80001038 <walkaddr+0xc>
    return 0;
    80001034:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001036:	8082                	ret
{
    80001038:	1141                	addi	sp,sp,-16
    8000103a:	e406                	sd	ra,8(sp)
    8000103c:	e022                	sd	s0,0(sp)
    8000103e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001040:	4601                	li	a2,0
    80001042:	f51ff0ef          	jal	ra,80000f92 <walk>
  if(pte == 0)
    80001046:	c105                	beqz	a0,80001066 <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80001048:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000104a:	0117f693          	andi	a3,a5,17
    8000104e:	4745                	li	a4,17
    return 0;
    80001050:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001052:	00e68663          	beq	a3,a4,8000105e <walkaddr+0x32>
}
    80001056:	60a2                	ld	ra,8(sp)
    80001058:	6402                	ld	s0,0(sp)
    8000105a:	0141                	addi	sp,sp,16
    8000105c:	8082                	ret
  pa = PTE2PA(*pte);
    8000105e:	00a7d513          	srli	a0,a5,0xa
    80001062:	0532                	slli	a0,a0,0xc
  return pa;
    80001064:	bfcd                	j	80001056 <walkaddr+0x2a>
    return 0;
    80001066:	4501                	li	a0,0
    80001068:	b7fd                	j	80001056 <walkaddr+0x2a>

000000008000106a <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000106a:	715d                	addi	sp,sp,-80
    8000106c:	e486                	sd	ra,72(sp)
    8000106e:	e0a2                	sd	s0,64(sp)
    80001070:	fc26                	sd	s1,56(sp)
    80001072:	f84a                	sd	s2,48(sp)
    80001074:	f44e                	sd	s3,40(sp)
    80001076:	f052                	sd	s4,32(sp)
    80001078:	ec56                	sd	s5,24(sp)
    8000107a:	e85a                	sd	s6,16(sp)
    8000107c:	e45e                	sd	s7,8(sp)
    8000107e:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001080:	03459793          	slli	a5,a1,0x34
    80001084:	e7a9                	bnez	a5,800010ce <mappages+0x64>
    80001086:	8aaa                	mv	s5,a0
    80001088:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    8000108a:	03461793          	slli	a5,a2,0x34
    8000108e:	e7b1                	bnez	a5,800010da <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    80001090:	ca39                	beqz	a2,800010e6 <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    80001092:	79fd                	lui	s3,0xfffff
    80001094:	964e                	add	a2,a2,s3
    80001096:	00b609b3          	add	s3,a2,a1
  a = va;
    8000109a:	892e                	mv	s2,a1
    8000109c:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010a0:	6b85                	lui	s7,0x1
    800010a2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010a6:	4605                	li	a2,1
    800010a8:	85ca                	mv	a1,s2
    800010aa:	8556                	mv	a0,s5
    800010ac:	ee7ff0ef          	jal	ra,80000f92 <walk>
    800010b0:	c539                	beqz	a0,800010fe <mappages+0x94>
    if(*pte & PTE_V)
    800010b2:	611c                	ld	a5,0(a0)
    800010b4:	8b85                	andi	a5,a5,1
    800010b6:	ef95                	bnez	a5,800010f2 <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010b8:	80b1                	srli	s1,s1,0xc
    800010ba:	04aa                	slli	s1,s1,0xa
    800010bc:	0164e4b3          	or	s1,s1,s6
    800010c0:	0014e493          	ori	s1,s1,1
    800010c4:	e104                	sd	s1,0(a0)
    if(a == last)
    800010c6:	05390863          	beq	s2,s3,80001116 <mappages+0xac>
    a += PGSIZE;
    800010ca:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	bfd9                	j	800010a2 <mappages+0x38>
    panic("mappages: va not aligned");
    800010ce:	00006517          	auipc	a0,0x6
    800010d2:	01a50513          	addi	a0,a0,26 # 800070e8 <digits+0x98>
    800010d6:	f06ff0ef          	jal	ra,800007dc <panic>
    panic("mappages: size not aligned");
    800010da:	00006517          	auipc	a0,0x6
    800010de:	02e50513          	addi	a0,a0,46 # 80007108 <digits+0xb8>
    800010e2:	efaff0ef          	jal	ra,800007dc <panic>
    panic("mappages: size");
    800010e6:	00006517          	auipc	a0,0x6
    800010ea:	04250513          	addi	a0,a0,66 # 80007128 <digits+0xd8>
    800010ee:	eeeff0ef          	jal	ra,800007dc <panic>
      panic("mappages: remap");
    800010f2:	00006517          	auipc	a0,0x6
    800010f6:	04650513          	addi	a0,a0,70 # 80007138 <digits+0xe8>
    800010fa:	ee2ff0ef          	jal	ra,800007dc <panic>
      return -1;
    800010fe:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001100:	60a6                	ld	ra,72(sp)
    80001102:	6406                	ld	s0,64(sp)
    80001104:	74e2                	ld	s1,56(sp)
    80001106:	7942                	ld	s2,48(sp)
    80001108:	79a2                	ld	s3,40(sp)
    8000110a:	7a02                	ld	s4,32(sp)
    8000110c:	6ae2                	ld	s5,24(sp)
    8000110e:	6b42                	ld	s6,16(sp)
    80001110:	6ba2                	ld	s7,8(sp)
    80001112:	6161                	addi	sp,sp,80
    80001114:	8082                	ret
  return 0;
    80001116:	4501                	li	a0,0
    80001118:	b7e5                	j	80001100 <mappages+0x96>

000000008000111a <kvmmap>:
{
    8000111a:	1141                	addi	sp,sp,-16
    8000111c:	e406                	sd	ra,8(sp)
    8000111e:	e022                	sd	s0,0(sp)
    80001120:	0800                	addi	s0,sp,16
    80001122:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001124:	86b2                	mv	a3,a2
    80001126:	863e                	mv	a2,a5
    80001128:	f43ff0ef          	jal	ra,8000106a <mappages>
    8000112c:	e509                	bnez	a0,80001136 <kvmmap+0x1c>
}
    8000112e:	60a2                	ld	ra,8(sp)
    80001130:	6402                	ld	s0,0(sp)
    80001132:	0141                	addi	sp,sp,16
    80001134:	8082                	ret
    panic("kvmmap");
    80001136:	00006517          	auipc	a0,0x6
    8000113a:	01250513          	addi	a0,a0,18 # 80007148 <digits+0xf8>
    8000113e:	e9eff0ef          	jal	ra,800007dc <panic>

0000000080001142 <kvmmake>:
{
    80001142:	1101                	addi	sp,sp,-32
    80001144:	ec06                	sd	ra,24(sp)
    80001146:	e822                	sd	s0,16(sp)
    80001148:	e426                	sd	s1,8(sp)
    8000114a:	e04a                	sd	s2,0(sp)
    8000114c:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000114e:	a25ff0ef          	jal	ra,80000b72 <kalloc>
    80001152:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001154:	6605                	lui	a2,0x1
    80001156:	4581                	li	a1,0
    80001158:	bbfff0ef          	jal	ra,80000d16 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000115c:	4719                	li	a4,6
    8000115e:	6685                	lui	a3,0x1
    80001160:	10000637          	lui	a2,0x10000
    80001164:	100005b7          	lui	a1,0x10000
    80001168:	8526                	mv	a0,s1
    8000116a:	fb1ff0ef          	jal	ra,8000111a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000116e:	4719                	li	a4,6
    80001170:	6685                	lui	a3,0x1
    80001172:	10001637          	lui	a2,0x10001
    80001176:	100015b7          	lui	a1,0x10001
    8000117a:	8526                	mv	a0,s1
    8000117c:	f9fff0ef          	jal	ra,8000111a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    80001180:	4719                	li	a4,6
    80001182:	040006b7          	lui	a3,0x4000
    80001186:	0c000637          	lui	a2,0xc000
    8000118a:	0c0005b7          	lui	a1,0xc000
    8000118e:	8526                	mv	a0,s1
    80001190:	f8bff0ef          	jal	ra,8000111a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001194:	00006917          	auipc	s2,0x6
    80001198:	e6c90913          	addi	s2,s2,-404 # 80007000 <etext>
    8000119c:	4729                	li	a4,10
    8000119e:	80006697          	auipc	a3,0x80006
    800011a2:	e6268693          	addi	a3,a3,-414 # 7000 <_entry-0x7fff9000>
    800011a6:	4605                	li	a2,1
    800011a8:	067e                	slli	a2,a2,0x1f
    800011aa:	85b2                	mv	a1,a2
    800011ac:	8526                	mv	a0,s1
    800011ae:	f6dff0ef          	jal	ra,8000111a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	46c5                	li	a3,17
    800011b6:	06ee                	slli	a3,a3,0x1b
    800011b8:	412686b3          	sub	a3,a3,s2
    800011bc:	864a                	mv	a2,s2
    800011be:	85ca                	mv	a1,s2
    800011c0:	8526                	mv	a0,s1
    800011c2:	f59ff0ef          	jal	ra,8000111a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011c6:	4729                	li	a4,10
    800011c8:	6685                	lui	a3,0x1
    800011ca:	00005617          	auipc	a2,0x5
    800011ce:	e3660613          	addi	a2,a2,-458 # 80006000 <_trampoline>
    800011d2:	040005b7          	lui	a1,0x4000
    800011d6:	15fd                	addi	a1,a1,-1
    800011d8:	05b2                	slli	a1,a1,0xc
    800011da:	8526                	mv	a0,s1
    800011dc:	f3fff0ef          	jal	ra,8000111a <kvmmap>
  proc_mapstacks(kpgtbl);
    800011e0:	8526                	mv	a0,s1
    800011e2:	59a000ef          	jal	ra,8000177c <proc_mapstacks>
}
    800011e6:	8526                	mv	a0,s1
    800011e8:	60e2                	ld	ra,24(sp)
    800011ea:	6442                	ld	s0,16(sp)
    800011ec:	64a2                	ld	s1,8(sp)
    800011ee:	6902                	ld	s2,0(sp)
    800011f0:	6105                	addi	sp,sp,32
    800011f2:	8082                	ret

00000000800011f4 <kvminit>:
{
    800011f4:	1141                	addi	sp,sp,-16
    800011f6:	e406                	sd	ra,8(sp)
    800011f8:	e022                	sd	s0,0(sp)
    800011fa:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800011fc:	f47ff0ef          	jal	ra,80001142 <kvmmake>
    80001200:	00006797          	auipc	a5,0x6
    80001204:	7aa7b023          	sd	a0,1952(a5) # 800079a0 <kernel_pagetable>
}
    80001208:	60a2                	ld	ra,8(sp)
    8000120a:	6402                	ld	s0,0(sp)
    8000120c:	0141                	addi	sp,sp,16
    8000120e:	8082                	ret

0000000080001210 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001210:	7139                	addi	sp,sp,-64
    80001212:	fc06                	sd	ra,56(sp)
    80001214:	f822                	sd	s0,48(sp)
    80001216:	f426                	sd	s1,40(sp)
    80001218:	f04a                	sd	s2,32(sp)
    8000121a:	ec4e                	sd	s3,24(sp)
    8000121c:	e852                	sd	s4,16(sp)
    8000121e:	e456                	sd	s5,8(sp)
    80001220:	e05a                	sd	s6,0(sp)
    80001222:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001224:	03459793          	slli	a5,a1,0x34
    80001228:	e785                	bnez	a5,80001250 <uvmunmap+0x40>
    8000122a:	8a2a                	mv	s4,a0
    8000122c:	892e                	mv	s2,a1
    8000122e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001230:	0632                	slli	a2,a2,0xc
    80001232:	00b609b3          	add	s3,a2,a1
    80001236:	6b05                	lui	s6,0x1
    80001238:	0335e763          	bltu	a1,s3,80001266 <uvmunmap+0x56>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000123c:	70e2                	ld	ra,56(sp)
    8000123e:	7442                	ld	s0,48(sp)
    80001240:	74a2                	ld	s1,40(sp)
    80001242:	7902                	ld	s2,32(sp)
    80001244:	69e2                	ld	s3,24(sp)
    80001246:	6a42                	ld	s4,16(sp)
    80001248:	6aa2                	ld	s5,8(sp)
    8000124a:	6b02                	ld	s6,0(sp)
    8000124c:	6121                	addi	sp,sp,64
    8000124e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001250:	00006517          	auipc	a0,0x6
    80001254:	f0050513          	addi	a0,a0,-256 # 80007150 <digits+0x100>
    80001258:	d84ff0ef          	jal	ra,800007dc <panic>
    *pte = 0;
    8000125c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001260:	995a                	add	s2,s2,s6
    80001262:	fd397de3          	bgeu	s2,s3,8000123c <uvmunmap+0x2c>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    80001266:	4601                	li	a2,0
    80001268:	85ca                	mv	a1,s2
    8000126a:	8552                	mv	a0,s4
    8000126c:	d27ff0ef          	jal	ra,80000f92 <walk>
    80001270:	84aa                	mv	s1,a0
    80001272:	d57d                	beqz	a0,80001260 <uvmunmap+0x50>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    80001274:	611c                	ld	a5,0(a0)
    80001276:	0017f713          	andi	a4,a5,1
    8000127a:	d37d                	beqz	a4,80001260 <uvmunmap+0x50>
    if(do_free){
    8000127c:	fe0a80e3          	beqz	s5,8000125c <uvmunmap+0x4c>
      uint64 pa = PTE2PA(*pte);
    80001280:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001282:	00c79513          	slli	a0,a5,0xc
    80001286:	80dff0ef          	jal	ra,80000a92 <kfree>
    8000128a:	bfc9                	j	8000125c <uvmunmap+0x4c>

000000008000128c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000128c:	1101                	addi	sp,sp,-32
    8000128e:	ec06                	sd	ra,24(sp)
    80001290:	e822                	sd	s0,16(sp)
    80001292:	e426                	sd	s1,8(sp)
    80001294:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001296:	8ddff0ef          	jal	ra,80000b72 <kalloc>
    8000129a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000129c:	c509                	beqz	a0,800012a6 <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000129e:	6605                	lui	a2,0x1
    800012a0:	4581                	li	a1,0
    800012a2:	a75ff0ef          	jal	ra,80000d16 <memset>
  return pagetable;
}
    800012a6:	8526                	mv	a0,s1
    800012a8:	60e2                	ld	ra,24(sp)
    800012aa:	6442                	ld	s0,16(sp)
    800012ac:	64a2                	ld	s1,8(sp)
    800012ae:	6105                	addi	sp,sp,32
    800012b0:	8082                	ret

00000000800012b2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800012b2:	1101                	addi	sp,sp,-32
    800012b4:	ec06                	sd	ra,24(sp)
    800012b6:	e822                	sd	s0,16(sp)
    800012b8:	e426                	sd	s1,8(sp)
    800012ba:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800012bc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800012be:	00b67d63          	bgeu	a2,a1,800012d8 <uvmdealloc+0x26>
    800012c2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800012c4:	6785                	lui	a5,0x1
    800012c6:	17fd                	addi	a5,a5,-1
    800012c8:	00f60733          	add	a4,a2,a5
    800012cc:	767d                	lui	a2,0xfffff
    800012ce:	8f71                	and	a4,a4,a2
    800012d0:	97ae                	add	a5,a5,a1
    800012d2:	8ff1                	and	a5,a5,a2
    800012d4:	00f76863          	bltu	a4,a5,800012e4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800012d8:	8526                	mv	a0,s1
    800012da:	60e2                	ld	ra,24(sp)
    800012dc:	6442                	ld	s0,16(sp)
    800012de:	64a2                	ld	s1,8(sp)
    800012e0:	6105                	addi	sp,sp,32
    800012e2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800012e4:	8f99                	sub	a5,a5,a4
    800012e6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800012e8:	4685                	li	a3,1
    800012ea:	0007861b          	sext.w	a2,a5
    800012ee:	85ba                	mv	a1,a4
    800012f0:	f21ff0ef          	jal	ra,80001210 <uvmunmap>
    800012f4:	b7d5                	j	800012d8 <uvmdealloc+0x26>

00000000800012f6 <uvmalloc>:
  if(newsz < oldsz)
    800012f6:	08b66963          	bltu	a2,a1,80001388 <uvmalloc+0x92>
{
    800012fa:	7139                	addi	sp,sp,-64
    800012fc:	fc06                	sd	ra,56(sp)
    800012fe:	f822                	sd	s0,48(sp)
    80001300:	f426                	sd	s1,40(sp)
    80001302:	f04a                	sd	s2,32(sp)
    80001304:	ec4e                	sd	s3,24(sp)
    80001306:	e852                	sd	s4,16(sp)
    80001308:	e456                	sd	s5,8(sp)
    8000130a:	e05a                	sd	s6,0(sp)
    8000130c:	0080                	addi	s0,sp,64
    8000130e:	8aaa                	mv	s5,a0
    80001310:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001312:	6985                	lui	s3,0x1
    80001314:	19fd                	addi	s3,s3,-1
    80001316:	95ce                	add	a1,a1,s3
    80001318:	79fd                	lui	s3,0xfffff
    8000131a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000131e:	06c9f763          	bgeu	s3,a2,8000138c <uvmalloc+0x96>
    80001322:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001324:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001328:	84bff0ef          	jal	ra,80000b72 <kalloc>
    8000132c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000132e:	c11d                	beqz	a0,80001354 <uvmalloc+0x5e>
    memset(mem, 0, PGSIZE);
    80001330:	6605                	lui	a2,0x1
    80001332:	4581                	li	a1,0
    80001334:	9e3ff0ef          	jal	ra,80000d16 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001338:	875a                	mv	a4,s6
    8000133a:	86a6                	mv	a3,s1
    8000133c:	6605                	lui	a2,0x1
    8000133e:	85ca                	mv	a1,s2
    80001340:	8556                	mv	a0,s5
    80001342:	d29ff0ef          	jal	ra,8000106a <mappages>
    80001346:	e51d                	bnez	a0,80001374 <uvmalloc+0x7e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001348:	6785                	lui	a5,0x1
    8000134a:	993e                	add	s2,s2,a5
    8000134c:	fd496ee3          	bltu	s2,s4,80001328 <uvmalloc+0x32>
  return newsz;
    80001350:	8552                	mv	a0,s4
    80001352:	a039                	j	80001360 <uvmalloc+0x6a>
      uvmdealloc(pagetable, a, oldsz);
    80001354:	864e                	mv	a2,s3
    80001356:	85ca                	mv	a1,s2
    80001358:	8556                	mv	a0,s5
    8000135a:	f59ff0ef          	jal	ra,800012b2 <uvmdealloc>
      return 0;
    8000135e:	4501                	li	a0,0
}
    80001360:	70e2                	ld	ra,56(sp)
    80001362:	7442                	ld	s0,48(sp)
    80001364:	74a2                	ld	s1,40(sp)
    80001366:	7902                	ld	s2,32(sp)
    80001368:	69e2                	ld	s3,24(sp)
    8000136a:	6a42                	ld	s4,16(sp)
    8000136c:	6aa2                	ld	s5,8(sp)
    8000136e:	6b02                	ld	s6,0(sp)
    80001370:	6121                	addi	sp,sp,64
    80001372:	8082                	ret
      kfree(mem);
    80001374:	8526                	mv	a0,s1
    80001376:	f1cff0ef          	jal	ra,80000a92 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000137a:	864e                	mv	a2,s3
    8000137c:	85ca                	mv	a1,s2
    8000137e:	8556                	mv	a0,s5
    80001380:	f33ff0ef          	jal	ra,800012b2 <uvmdealloc>
      return 0;
    80001384:	4501                	li	a0,0
    80001386:	bfe9                	j	80001360 <uvmalloc+0x6a>
    return oldsz;
    80001388:	852e                	mv	a0,a1
}
    8000138a:	8082                	ret
  return newsz;
    8000138c:	8532                	mv	a0,a2
    8000138e:	bfc9                	j	80001360 <uvmalloc+0x6a>

0000000080001390 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001390:	7179                	addi	sp,sp,-48
    80001392:	f406                	sd	ra,40(sp)
    80001394:	f022                	sd	s0,32(sp)
    80001396:	ec26                	sd	s1,24(sp)
    80001398:	e84a                	sd	s2,16(sp)
    8000139a:	e44e                	sd	s3,8(sp)
    8000139c:	e052                	sd	s4,0(sp)
    8000139e:	1800                	addi	s0,sp,48
    800013a0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800013a2:	84aa                	mv	s1,a0
    800013a4:	6905                	lui	s2,0x1
    800013a6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800013a8:	4985                	li	s3,1
    800013aa:	a811                	j	800013be <freewalk+0x2e>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800013ac:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800013ae:	0532                	slli	a0,a0,0xc
    800013b0:	fe1ff0ef          	jal	ra,80001390 <freewalk>
      pagetable[i] = 0;
    800013b4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800013b8:	04a1                	addi	s1,s1,8
    800013ba:	01248f63          	beq	s1,s2,800013d8 <freewalk+0x48>
    pte_t pte = pagetable[i];
    800013be:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800013c0:	00f57793          	andi	a5,a0,15
    800013c4:	ff3784e3          	beq	a5,s3,800013ac <freewalk+0x1c>
    } else if(pte & PTE_V){
    800013c8:	8905                	andi	a0,a0,1
    800013ca:	d57d                	beqz	a0,800013b8 <freewalk+0x28>
      panic("freewalk: leaf");
    800013cc:	00006517          	auipc	a0,0x6
    800013d0:	d9c50513          	addi	a0,a0,-612 # 80007168 <digits+0x118>
    800013d4:	c08ff0ef          	jal	ra,800007dc <panic>
    }
  }
  kfree((void*)pagetable);
    800013d8:	8552                	mv	a0,s4
    800013da:	eb8ff0ef          	jal	ra,80000a92 <kfree>
}
    800013de:	70a2                	ld	ra,40(sp)
    800013e0:	7402                	ld	s0,32(sp)
    800013e2:	64e2                	ld	s1,24(sp)
    800013e4:	6942                	ld	s2,16(sp)
    800013e6:	69a2                	ld	s3,8(sp)
    800013e8:	6a02                	ld	s4,0(sp)
    800013ea:	6145                	addi	sp,sp,48
    800013ec:	8082                	ret

00000000800013ee <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800013ee:	1101                	addi	sp,sp,-32
    800013f0:	ec06                	sd	ra,24(sp)
    800013f2:	e822                	sd	s0,16(sp)
    800013f4:	e426                	sd	s1,8(sp)
    800013f6:	1000                	addi	s0,sp,32
    800013f8:	84aa                	mv	s1,a0
  if(sz > 0)
    800013fa:	e989                	bnez	a1,8000140c <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800013fc:	8526                	mv	a0,s1
    800013fe:	f93ff0ef          	jal	ra,80001390 <freewalk>
}
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000140c:	6605                	lui	a2,0x1
    8000140e:	167d                	addi	a2,a2,-1
    80001410:	962e                	add	a2,a2,a1
    80001412:	4685                	li	a3,1
    80001414:	8231                	srli	a2,a2,0xc
    80001416:	4581                	li	a1,0
    80001418:	df9ff0ef          	jal	ra,80001210 <uvmunmap>
    8000141c:	b7c5                	j	800013fc <uvmfree+0xe>

000000008000141e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000141e:	ce49                	beqz	a2,800014b8 <uvmcopy+0x9a>
{
    80001420:	715d                	addi	sp,sp,-80
    80001422:	e486                	sd	ra,72(sp)
    80001424:	e0a2                	sd	s0,64(sp)
    80001426:	fc26                	sd	s1,56(sp)
    80001428:	f84a                	sd	s2,48(sp)
    8000142a:	f44e                	sd	s3,40(sp)
    8000142c:	f052                	sd	s4,32(sp)
    8000142e:	ec56                	sd	s5,24(sp)
    80001430:	e85a                	sd	s6,16(sp)
    80001432:	e45e                	sd	s7,8(sp)
    80001434:	0880                	addi	s0,sp,80
    80001436:	8aaa                	mv	s5,a0
    80001438:	8b2e                	mv	s6,a1
    8000143a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000143c:	4481                	li	s1,0
    8000143e:	a029                	j	80001448 <uvmcopy+0x2a>
    80001440:	6785                	lui	a5,0x1
    80001442:	94be                	add	s1,s1,a5
    80001444:	0544fe63          	bgeu	s1,s4,800014a0 <uvmcopy+0x82>
    if((pte = walk(old, i, 0)) == 0)
    80001448:	4601                	li	a2,0
    8000144a:	85a6                	mv	a1,s1
    8000144c:	8556                	mv	a0,s5
    8000144e:	b45ff0ef          	jal	ra,80000f92 <walk>
    80001452:	d57d                	beqz	a0,80001440 <uvmcopy+0x22>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    80001454:	6118                	ld	a4,0(a0)
    80001456:	00177793          	andi	a5,a4,1
    8000145a:	d3fd                	beqz	a5,80001440 <uvmcopy+0x22>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    8000145c:	00a75593          	srli	a1,a4,0xa
    80001460:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001464:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001468:	f0aff0ef          	jal	ra,80000b72 <kalloc>
    8000146c:	89aa                	mv	s3,a0
    8000146e:	c105                	beqz	a0,8000148e <uvmcopy+0x70>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001470:	6605                	lui	a2,0x1
    80001472:	85de                	mv	a1,s7
    80001474:	8ffff0ef          	jal	ra,80000d72 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001478:	874a                	mv	a4,s2
    8000147a:	86ce                	mv	a3,s3
    8000147c:	6605                	lui	a2,0x1
    8000147e:	85a6                	mv	a1,s1
    80001480:	855a                	mv	a0,s6
    80001482:	be9ff0ef          	jal	ra,8000106a <mappages>
    80001486:	dd4d                	beqz	a0,80001440 <uvmcopy+0x22>
      kfree(mem);
    80001488:	854e                	mv	a0,s3
    8000148a:	e08ff0ef          	jal	ra,80000a92 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000148e:	4685                	li	a3,1
    80001490:	00c4d613          	srli	a2,s1,0xc
    80001494:	4581                	li	a1,0
    80001496:	855a                	mv	a0,s6
    80001498:	d79ff0ef          	jal	ra,80001210 <uvmunmap>
  return -1;
    8000149c:	557d                	li	a0,-1
    8000149e:	a011                	j	800014a2 <uvmcopy+0x84>
  return 0;
    800014a0:	4501                	li	a0,0
}
    800014a2:	60a6                	ld	ra,72(sp)
    800014a4:	6406                	ld	s0,64(sp)
    800014a6:	74e2                	ld	s1,56(sp)
    800014a8:	7942                	ld	s2,48(sp)
    800014aa:	79a2                	ld	s3,40(sp)
    800014ac:	7a02                	ld	s4,32(sp)
    800014ae:	6ae2                	ld	s5,24(sp)
    800014b0:	6b42                	ld	s6,16(sp)
    800014b2:	6ba2                	ld	s7,8(sp)
    800014b4:	6161                	addi	sp,sp,80
    800014b6:	8082                	ret
  return 0;
    800014b8:	4501                	li	a0,0
}
    800014ba:	8082                	ret

00000000800014bc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800014bc:	1141                	addi	sp,sp,-16
    800014be:	e406                	sd	ra,8(sp)
    800014c0:	e022                	sd	s0,0(sp)
    800014c2:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800014c4:	4601                	li	a2,0
    800014c6:	acdff0ef          	jal	ra,80000f92 <walk>
  if(pte == 0)
    800014ca:	c901                	beqz	a0,800014da <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800014cc:	611c                	ld	a5,0(a0)
    800014ce:	9bbd                	andi	a5,a5,-17
    800014d0:	e11c                	sd	a5,0(a0)
}
    800014d2:	60a2                	ld	ra,8(sp)
    800014d4:	6402                	ld	s0,0(sp)
    800014d6:	0141                	addi	sp,sp,16
    800014d8:	8082                	ret
    panic("uvmclear");
    800014da:	00006517          	auipc	a0,0x6
    800014de:	c9e50513          	addi	a0,a0,-866 # 80007178 <digits+0x128>
    800014e2:	afaff0ef          	jal	ra,800007dc <panic>

00000000800014e6 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800014e6:	c2d5                	beqz	a3,8000158a <copyinstr+0xa4>
{
    800014e8:	715d                	addi	sp,sp,-80
    800014ea:	e486                	sd	ra,72(sp)
    800014ec:	e0a2                	sd	s0,64(sp)
    800014ee:	fc26                	sd	s1,56(sp)
    800014f0:	f84a                	sd	s2,48(sp)
    800014f2:	f44e                	sd	s3,40(sp)
    800014f4:	f052                	sd	s4,32(sp)
    800014f6:	ec56                	sd	s5,24(sp)
    800014f8:	e85a                	sd	s6,16(sp)
    800014fa:	e45e                	sd	s7,8(sp)
    800014fc:	0880                	addi	s0,sp,80
    800014fe:	8a2a                	mv	s4,a0
    80001500:	8b2e                	mv	s6,a1
    80001502:	8bb2                	mv	s7,a2
    80001504:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001506:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001508:	6985                	lui	s3,0x1
    8000150a:	a035                	j	80001536 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000150c:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001510:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001512:	0017b793          	seqz	a5,a5
    80001516:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000151a:	60a6                	ld	ra,72(sp)
    8000151c:	6406                	ld	s0,64(sp)
    8000151e:	74e2                	ld	s1,56(sp)
    80001520:	7942                	ld	s2,48(sp)
    80001522:	79a2                	ld	s3,40(sp)
    80001524:	7a02                	ld	s4,32(sp)
    80001526:	6ae2                	ld	s5,24(sp)
    80001528:	6b42                	ld	s6,16(sp)
    8000152a:	6ba2                	ld	s7,8(sp)
    8000152c:	6161                	addi	sp,sp,80
    8000152e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001530:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001534:	c4b9                	beqz	s1,80001582 <copyinstr+0x9c>
    va0 = PGROUNDDOWN(srcva);
    80001536:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000153a:	85ca                	mv	a1,s2
    8000153c:	8552                	mv	a0,s4
    8000153e:	aefff0ef          	jal	ra,8000102c <walkaddr>
    if(pa0 == 0)
    80001542:	c131                	beqz	a0,80001586 <copyinstr+0xa0>
    n = PGSIZE - (srcva - va0);
    80001544:	41790833          	sub	a6,s2,s7
    80001548:	984e                	add	a6,a6,s3
    if(n > max)
    8000154a:	0104f363          	bgeu	s1,a6,80001550 <copyinstr+0x6a>
    8000154e:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001550:	955e                	add	a0,a0,s7
    80001552:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001556:	fc080de3          	beqz	a6,80001530 <copyinstr+0x4a>
    8000155a:	985a                	add	a6,a6,s6
    8000155c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000155e:	41650633          	sub	a2,a0,s6
    80001562:	14fd                	addi	s1,s1,-1
    80001564:	9b26                	add	s6,s6,s1
    80001566:	00f60733          	add	a4,a2,a5
    8000156a:	00074703          	lbu	a4,0(a4)
    8000156e:	df59                	beqz	a4,8000150c <copyinstr+0x26>
        *dst = *p;
    80001570:	00e78023          	sb	a4,0(a5)
      --max;
    80001574:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001578:	0785                	addi	a5,a5,1
    while(n > 0){
    8000157a:	ff0796e3          	bne	a5,a6,80001566 <copyinstr+0x80>
      dst++;
    8000157e:	8b42                	mv	s6,a6
    80001580:	bf45                	j	80001530 <copyinstr+0x4a>
    80001582:	4781                	li	a5,0
    80001584:	b779                	j	80001512 <copyinstr+0x2c>
      return -1;
    80001586:	557d                	li	a0,-1
    80001588:	bf49                	j	8000151a <copyinstr+0x34>
  int got_null = 0;
    8000158a:	4781                	li	a5,0
  if(got_null){
    8000158c:	0017b793          	seqz	a5,a5
    80001590:	40f00533          	neg	a0,a5
}
    80001594:	8082                	ret

0000000080001596 <ismapped>:
  return ka;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80001596:	1141                	addi	sp,sp,-16
    80001598:	e406                	sd	ra,8(sp)
    8000159a:	e022                	sd	s0,0(sp)
    8000159c:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    8000159e:	4601                	li	a2,0
    800015a0:	9f3ff0ef          	jal	ra,80000f92 <walk>
  if (pte == 0) {
    800015a4:	c519                	beqz	a0,800015b2 <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    800015a6:	6108                	ld	a0,0(a0)
    return 0;
    800015a8:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    800015aa:	60a2                	ld	ra,8(sp)
    800015ac:	6402                	ld	s0,0(sp)
    800015ae:	0141                	addi	sp,sp,16
    800015b0:	8082                	ret
    return 0;
    800015b2:	4501                	li	a0,0
    800015b4:	bfdd                	j	800015aa <ismapped+0x14>

00000000800015b6 <vmfault>:
{
    800015b6:	7179                	addi	sp,sp,-48
    800015b8:	f406                	sd	ra,40(sp)
    800015ba:	f022                	sd	s0,32(sp)
    800015bc:	ec26                	sd	s1,24(sp)
    800015be:	e84a                	sd	s2,16(sp)
    800015c0:	e44e                	sd	s3,8(sp)
    800015c2:	e052                	sd	s4,0(sp)
    800015c4:	1800                	addi	s0,sp,48
    800015c6:	89aa                	mv	s3,a0
    800015c8:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    800015ca:	310000ef          	jal	ra,800018da <myproc>
  if (va >= p->sz)
    800015ce:	693c                	ld	a5,80(a0)
    800015d0:	00f4ec63          	bltu	s1,a5,800015e8 <vmfault+0x32>
    return 0;
    800015d4:	4981                	li	s3,0
}
    800015d6:	854e                	mv	a0,s3
    800015d8:	70a2                	ld	ra,40(sp)
    800015da:	7402                	ld	s0,32(sp)
    800015dc:	64e2                	ld	s1,24(sp)
    800015de:	6942                	ld	s2,16(sp)
    800015e0:	69a2                	ld	s3,8(sp)
    800015e2:	6a02                	ld	s4,0(sp)
    800015e4:	6145                	addi	sp,sp,48
    800015e6:	8082                	ret
    800015e8:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    800015ea:	75fd                	lui	a1,0xfffff
    800015ec:	8ced                	and	s1,s1,a1
  if(ismapped(pagetable, va)) {
    800015ee:	85a6                	mv	a1,s1
    800015f0:	854e                	mv	a0,s3
    800015f2:	fa5ff0ef          	jal	ra,80001596 <ismapped>
    return 0;
    800015f6:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    800015f8:	fd79                	bnez	a0,800015d6 <vmfault+0x20>
  ka = (uint64) kalloc();
    800015fa:	d78ff0ef          	jal	ra,80000b72 <kalloc>
    800015fe:	8a2a                	mv	s4,a0
  if(ka == 0)
    80001600:	d979                	beqz	a0,800015d6 <vmfault+0x20>
  ka = (uint64) kalloc();
    80001602:	89aa                	mv	s3,a0
  memset((void *) ka, 0, PGSIZE);
    80001604:	6605                	lui	a2,0x1
    80001606:	4581                	li	a1,0
    80001608:	f0eff0ef          	jal	ra,80000d16 <memset>
  if (mappages(p->pagetable, va, PGSIZE, ka, PTE_W|PTE_U|PTE_R) != 0) {
    8000160c:	4759                	li	a4,22
    8000160e:	86d2                	mv	a3,s4
    80001610:	6605                	lui	a2,0x1
    80001612:	85a6                	mv	a1,s1
    80001614:	05893503          	ld	a0,88(s2) # 1058 <_entry-0x7fffefa8>
    80001618:	a53ff0ef          	jal	ra,8000106a <mappages>
    8000161c:	dd4d                	beqz	a0,800015d6 <vmfault+0x20>
    kfree((void *)ka);
    8000161e:	8552                	mv	a0,s4
    80001620:	c72ff0ef          	jal	ra,80000a92 <kfree>
    return 0;
    80001624:	4981                	li	s3,0
    80001626:	bf45                	j	800015d6 <vmfault+0x20>

0000000080001628 <copyout>:
  while(len > 0){
    80001628:	cec1                	beqz	a3,800016c0 <copyout+0x98>
{
    8000162a:	711d                	addi	sp,sp,-96
    8000162c:	ec86                	sd	ra,88(sp)
    8000162e:	e8a2                	sd	s0,80(sp)
    80001630:	e4a6                	sd	s1,72(sp)
    80001632:	e0ca                	sd	s2,64(sp)
    80001634:	fc4e                	sd	s3,56(sp)
    80001636:	f852                	sd	s4,48(sp)
    80001638:	f456                	sd	s5,40(sp)
    8000163a:	f05a                	sd	s6,32(sp)
    8000163c:	ec5e                	sd	s7,24(sp)
    8000163e:	e862                	sd	s8,16(sp)
    80001640:	e466                	sd	s9,8(sp)
    80001642:	e06a                	sd	s10,0(sp)
    80001644:	1080                	addi	s0,sp,96
    80001646:	8c2a                	mv	s8,a0
    80001648:	8b2e                	mv	s6,a1
    8000164a:	8bb2                	mv	s7,a2
    8000164c:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    8000164e:	74fd                	lui	s1,0xfffff
    80001650:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    80001652:	57fd                	li	a5,-1
    80001654:	83e9                	srli	a5,a5,0x1a
    80001656:	0697e763          	bltu	a5,s1,800016c4 <copyout+0x9c>
    8000165a:	6d05                	lui	s10,0x1
    8000165c:	8cbe                	mv	s9,a5
    8000165e:	a015                	j	80001682 <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001660:	409b0533          	sub	a0,s6,s1
    80001664:	0009861b          	sext.w	a2,s3
    80001668:	85de                	mv	a1,s7
    8000166a:	954a                	add	a0,a0,s2
    8000166c:	f06ff0ef          	jal	ra,80000d72 <memmove>
    len -= n;
    80001670:	413a0a33          	sub	s4,s4,s3
    src += n;
    80001674:	9bce                	add	s7,s7,s3
  while(len > 0){
    80001676:	040a0363          	beqz	s4,800016bc <copyout+0x94>
    if(va0 >= MAXVA)
    8000167a:	055ce763          	bltu	s9,s5,800016c8 <copyout+0xa0>
    va0 = PGROUNDDOWN(dstva);
    8000167e:	84d6                	mv	s1,s5
    dstva = va0 + PGSIZE;
    80001680:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    80001682:	85a6                	mv	a1,s1
    80001684:	8562                	mv	a0,s8
    80001686:	9a7ff0ef          	jal	ra,8000102c <walkaddr>
    8000168a:	892a                	mv	s2,a0
    if(pa0 == 0) {
    8000168c:	e901                	bnez	a0,8000169c <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    8000168e:	4601                	li	a2,0
    80001690:	85a6                	mv	a1,s1
    80001692:	8562                	mv	a0,s8
    80001694:	f23ff0ef          	jal	ra,800015b6 <vmfault>
    80001698:	892a                	mv	s2,a0
    8000169a:	c90d                	beqz	a0,800016cc <copyout+0xa4>
    pte = walk(pagetable, va0, 0);
    8000169c:	4601                	li	a2,0
    8000169e:	85a6                	mv	a1,s1
    800016a0:	8562                	mv	a0,s8
    800016a2:	8f1ff0ef          	jal	ra,80000f92 <walk>
    if((*pte & PTE_W) == 0)
    800016a6:	611c                	ld	a5,0(a0)
    800016a8:	8b91                	andi	a5,a5,4
    800016aa:	c39d                	beqz	a5,800016d0 <copyout+0xa8>
    n = PGSIZE - (dstva - va0);
    800016ac:	01a48ab3          	add	s5,s1,s10
    800016b0:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    800016b4:	fb3a76e3          	bgeu	s4,s3,80001660 <copyout+0x38>
    800016b8:	89d2                	mv	s3,s4
    800016ba:	b75d                	j	80001660 <copyout+0x38>
  return 0;
    800016bc:	4501                	li	a0,0
    800016be:	a811                	j	800016d2 <copyout+0xaa>
    800016c0:	4501                	li	a0,0
}
    800016c2:	8082                	ret
      return -1;
    800016c4:	557d                	li	a0,-1
    800016c6:	a031                	j	800016d2 <copyout+0xaa>
    800016c8:	557d                	li	a0,-1
    800016ca:	a021                	j	800016d2 <copyout+0xaa>
        return -1;
    800016cc:	557d                	li	a0,-1
    800016ce:	a011                	j	800016d2 <copyout+0xaa>
      return -1;
    800016d0:	557d                	li	a0,-1
}
    800016d2:	60e6                	ld	ra,88(sp)
    800016d4:	6446                	ld	s0,80(sp)
    800016d6:	64a6                	ld	s1,72(sp)
    800016d8:	6906                	ld	s2,64(sp)
    800016da:	79e2                	ld	s3,56(sp)
    800016dc:	7a42                	ld	s4,48(sp)
    800016de:	7aa2                	ld	s5,40(sp)
    800016e0:	7b02                	ld	s6,32(sp)
    800016e2:	6be2                	ld	s7,24(sp)
    800016e4:	6c42                	ld	s8,16(sp)
    800016e6:	6ca2                	ld	s9,8(sp)
    800016e8:	6d02                	ld	s10,0(sp)
    800016ea:	6125                	addi	sp,sp,96
    800016ec:	8082                	ret

00000000800016ee <copyin>:
  while(len > 0){
    800016ee:	c6c9                	beqz	a3,80001778 <copyin+0x8a>
{
    800016f0:	715d                	addi	sp,sp,-80
    800016f2:	e486                	sd	ra,72(sp)
    800016f4:	e0a2                	sd	s0,64(sp)
    800016f6:	fc26                	sd	s1,56(sp)
    800016f8:	f84a                	sd	s2,48(sp)
    800016fa:	f44e                	sd	s3,40(sp)
    800016fc:	f052                	sd	s4,32(sp)
    800016fe:	ec56                	sd	s5,24(sp)
    80001700:	e85a                	sd	s6,16(sp)
    80001702:	e45e                	sd	s7,8(sp)
    80001704:	e062                	sd	s8,0(sp)
    80001706:	0880                	addi	s0,sp,80
    80001708:	8baa                	mv	s7,a0
    8000170a:	8aae                	mv	s5,a1
    8000170c:	8932                	mv	s2,a2
    8000170e:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    80001710:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    80001712:	6b05                	lui	s6,0x1
    80001714:	a035                	j	80001740 <copyin+0x52>
    80001716:	412984b3          	sub	s1,s3,s2
    8000171a:	94da                	add	s1,s1,s6
    if(n > len)
    8000171c:	009a7363          	bgeu	s4,s1,80001722 <copyin+0x34>
    80001720:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001722:	413905b3          	sub	a1,s2,s3
    80001726:	0004861b          	sext.w	a2,s1
    8000172a:	95aa                	add	a1,a1,a0
    8000172c:	8556                	mv	a0,s5
    8000172e:	e44ff0ef          	jal	ra,80000d72 <memmove>
    len -= n;
    80001732:	409a0a33          	sub	s4,s4,s1
    dst += n;
    80001736:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001738:	01698933          	add	s2,s3,s6
  while(len > 0){
    8000173c:	020a0163          	beqz	s4,8000175e <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    80001740:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ce                	mv	a1,s3
    80001746:	855e                	mv	a0,s7
    80001748:	8e5ff0ef          	jal	ra,8000102c <walkaddr>
    if(pa0 == 0) {
    8000174c:	f569                	bnez	a0,80001716 <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    8000174e:	4601                	li	a2,0
    80001750:	85ce                	mv	a1,s3
    80001752:	855e                	mv	a0,s7
    80001754:	e63ff0ef          	jal	ra,800015b6 <vmfault>
    80001758:	fd5d                	bnez	a0,80001716 <copyin+0x28>
        return -1;
    8000175a:	557d                	li	a0,-1
    8000175c:	a011                	j	80001760 <copyin+0x72>
  return 0;
    8000175e:	4501                	li	a0,0
}
    80001760:	60a6                	ld	ra,72(sp)
    80001762:	6406                	ld	s0,64(sp)
    80001764:	74e2                	ld	s1,56(sp)
    80001766:	7942                	ld	s2,48(sp)
    80001768:	79a2                	ld	s3,40(sp)
    8000176a:	7a02                	ld	s4,32(sp)
    8000176c:	6ae2                	ld	s5,24(sp)
    8000176e:	6b42                	ld	s6,16(sp)
    80001770:	6ba2                	ld	s7,8(sp)
    80001772:	6c02                	ld	s8,0(sp)
    80001774:	6161                	addi	sp,sp,80
    80001776:	8082                	ret
  return 0;
    80001778:	4501                	li	a0,0
}
    8000177a:	8082                	ret

000000008000177c <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000177c:	7139                	addi	sp,sp,-64
    8000177e:	fc06                	sd	ra,56(sp)
    80001780:	f822                	sd	s0,48(sp)
    80001782:	f426                	sd	s1,40(sp)
    80001784:	f04a                	sd	s2,32(sp)
    80001786:	ec4e                	sd	s3,24(sp)
    80001788:	e852                	sd	s4,16(sp)
    8000178a:	e456                	sd	s5,8(sp)
    8000178c:	e05a                	sd	s6,0(sp)
    8000178e:	0080                	addi	s0,sp,64
    80001790:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001792:	0000e497          	auipc	s1,0xe
    80001796:	77648493          	addi	s1,s1,1910 # 8000ff08 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000179a:	8b26                	mv	s6,s1
    8000179c:	00006a97          	auipc	s5,0x6
    800017a0:	864a8a93          	addi	s5,s5,-1948 # 80007000 <etext>
    800017a4:	04000937          	lui	s2,0x4000
    800017a8:	197d                	addi	s2,s2,-1
    800017aa:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800017ac:	00014a17          	auipc	s4,0x14
    800017b0:	35ca0a13          	addi	s4,s4,860 # 80015b08 <tickslock>
    char *pa = kalloc();
    800017b4:	bbeff0ef          	jal	ra,80000b72 <kalloc>
    800017b8:	862a                	mv	a2,a0
    if(pa == 0)
    800017ba:	c121                	beqz	a0,800017fa <proc_mapstacks+0x7e>
    uint64 va = KSTACK((int) (p - proc));
    800017bc:	416485b3          	sub	a1,s1,s6
    800017c0:	8591                	srai	a1,a1,0x4
    800017c2:	000ab783          	ld	a5,0(s5)
    800017c6:	02f585b3          	mul	a1,a1,a5
    800017ca:	2585                	addiw	a1,a1,1
    800017cc:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017d0:	4719                	li	a4,6
    800017d2:	6685                	lui	a3,0x1
    800017d4:	40b905b3          	sub	a1,s2,a1
    800017d8:	854e                	mv	a0,s3
    800017da:	941ff0ef          	jal	ra,8000111a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800017de:	17048493          	addi	s1,s1,368
    800017e2:	fd4499e3          	bne	s1,s4,800017b4 <proc_mapstacks+0x38>
  }
}
    800017e6:	70e2                	ld	ra,56(sp)
    800017e8:	7442                	ld	s0,48(sp)
    800017ea:	74a2                	ld	s1,40(sp)
    800017ec:	7902                	ld	s2,32(sp)
    800017ee:	69e2                	ld	s3,24(sp)
    800017f0:	6a42                	ld	s4,16(sp)
    800017f2:	6aa2                	ld	s5,8(sp)
    800017f4:	6b02                	ld	s6,0(sp)
    800017f6:	6121                	addi	sp,sp,64
    800017f8:	8082                	ret
      panic("kalloc");
    800017fa:	00006517          	auipc	a0,0x6
    800017fe:	98e50513          	addi	a0,a0,-1650 # 80007188 <digits+0x138>
    80001802:	fdbfe0ef          	jal	ra,800007dc <panic>

0000000080001806 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001806:	7139                	addi	sp,sp,-64
    80001808:	fc06                	sd	ra,56(sp)
    8000180a:	f822                	sd	s0,48(sp)
    8000180c:	f426                	sd	s1,40(sp)
    8000180e:	f04a                	sd	s2,32(sp)
    80001810:	ec4e                	sd	s3,24(sp)
    80001812:	e852                	sd	s4,16(sp)
    80001814:	e456                	sd	s5,8(sp)
    80001816:	e05a                	sd	s6,0(sp)
    80001818:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000181a:	00006597          	auipc	a1,0x6
    8000181e:	97658593          	addi	a1,a1,-1674 # 80007190 <digits+0x140>
    80001822:	0000e517          	auipc	a0,0xe
    80001826:	2b650513          	addi	a0,a0,694 # 8000fad8 <pid_lock>
    8000182a:	b98ff0ef          	jal	ra,80000bc2 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000182e:	00006597          	auipc	a1,0x6
    80001832:	96a58593          	addi	a1,a1,-1686 # 80007198 <digits+0x148>
    80001836:	0000e517          	auipc	a0,0xe
    8000183a:	2ba50513          	addi	a0,a0,698 # 8000faf0 <wait_lock>
    8000183e:	b84ff0ef          	jal	ra,80000bc2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001842:	0000e497          	auipc	s1,0xe
    80001846:	6c648493          	addi	s1,s1,1734 # 8000ff08 <proc>
      initlock(&p->lock, "proc");
    8000184a:	00006b17          	auipc	s6,0x6
    8000184e:	95eb0b13          	addi	s6,s6,-1698 # 800071a8 <digits+0x158>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001852:	8aa6                	mv	s5,s1
    80001854:	00005a17          	auipc	s4,0x5
    80001858:	7aca0a13          	addi	s4,s4,1964 # 80007000 <etext>
    8000185c:	04000937          	lui	s2,0x4000
    80001860:	197d                	addi	s2,s2,-1
    80001862:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001864:	00014997          	auipc	s3,0x14
    80001868:	2a498993          	addi	s3,s3,676 # 80015b08 <tickslock>
      initlock(&p->lock, "proc");
    8000186c:	85da                	mv	a1,s6
    8000186e:	8526                	mv	a0,s1
    80001870:	b52ff0ef          	jal	ra,80000bc2 <initlock>
      p->state = UNUSED;
    80001874:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001878:	415487b3          	sub	a5,s1,s5
    8000187c:	8791                	srai	a5,a5,0x4
    8000187e:	000a3703          	ld	a4,0(s4)
    80001882:	02e787b3          	mul	a5,a5,a4
    80001886:	2785                	addiw	a5,a5,1
    80001888:	00d7979b          	slliw	a5,a5,0xd
    8000188c:	40f907b3          	sub	a5,s2,a5
    80001890:	e4bc                	sd	a5,72(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001892:	17048493          	addi	s1,s1,368
    80001896:	fd349be3          	bne	s1,s3,8000186c <procinit+0x66>
  }
}
    8000189a:	70e2                	ld	ra,56(sp)
    8000189c:	7442                	ld	s0,48(sp)
    8000189e:	74a2                	ld	s1,40(sp)
    800018a0:	7902                	ld	s2,32(sp)
    800018a2:	69e2                	ld	s3,24(sp)
    800018a4:	6a42                	ld	s4,16(sp)
    800018a6:	6aa2                	ld	s5,8(sp)
    800018a8:	6b02                	ld	s6,0(sp)
    800018aa:	6121                	addi	sp,sp,64
    800018ac:	8082                	ret

00000000800018ae <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800018ae:	1141                	addi	sp,sp,-16
    800018b0:	e422                	sd	s0,8(sp)
    800018b2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018b4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018b6:	2501                	sext.w	a0,a0
    800018b8:	6422                	ld	s0,8(sp)
    800018ba:	0141                	addi	sp,sp,16
    800018bc:	8082                	ret

00000000800018be <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800018be:	1141                	addi	sp,sp,-16
    800018c0:	e422                	sd	s0,8(sp)
    800018c2:	0800                	addi	s0,sp,16
    800018c4:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018c6:	2781                	sext.w	a5,a5
    800018c8:	079e                	slli	a5,a5,0x7
  return c;
}
    800018ca:	0000e517          	auipc	a0,0xe
    800018ce:	23e50513          	addi	a0,a0,574 # 8000fb08 <cpus>
    800018d2:	953e                	add	a0,a0,a5
    800018d4:	6422                	ld	s0,8(sp)
    800018d6:	0141                	addi	sp,sp,16
    800018d8:	8082                	ret

00000000800018da <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800018da:	1101                	addi	sp,sp,-32
    800018dc:	ec06                	sd	ra,24(sp)
    800018de:	e822                	sd	s0,16(sp)
    800018e0:	e426                	sd	s1,8(sp)
    800018e2:	1000                	addi	s0,sp,32
  push_off();
    800018e4:	b1eff0ef          	jal	ra,80000c02 <push_off>
    800018e8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800018ea:	2781                	sext.w	a5,a5
    800018ec:	079e                	slli	a5,a5,0x7
    800018ee:	0000e717          	auipc	a4,0xe
    800018f2:	1ea70713          	addi	a4,a4,490 # 8000fad8 <pid_lock>
    800018f6:	97ba                	add	a5,a5,a4
    800018f8:	7b84                	ld	s1,48(a5)
  pop_off();
    800018fa:	b8cff0ef          	jal	ra,80000c86 <pop_off>
  return p;
}
    800018fe:	8526                	mv	a0,s1
    80001900:	60e2                	ld	ra,24(sp)
    80001902:	6442                	ld	s0,16(sp)
    80001904:	64a2                	ld	s1,8(sp)
    80001906:	6105                	addi	sp,sp,32
    80001908:	8082                	ret

000000008000190a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    8000190a:	7179                	addi	sp,sp,-48
    8000190c:	f406                	sd	ra,40(sp)
    8000190e:	f022                	sd	s0,32(sp)
    80001910:	ec26                	sd	s1,24(sp)
    80001912:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001914:	fc7ff0ef          	jal	ra,800018da <myproc>
    80001918:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    8000191a:	bc0ff0ef          	jal	ra,80000cda <release>

  if (first) {
    8000191e:	00006797          	auipc	a5,0x6
    80001922:	0527a783          	lw	a5,82(a5) # 80007970 <first.1>
    80001926:	cf8d                	beqz	a5,80001960 <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80001928:	4505                	li	a0,1
    8000192a:	6f6010ef          	jal	ra,80003020 <fsinit>

    first = 0;
    8000192e:	00006797          	auipc	a5,0x6
    80001932:	0407a123          	sw	zero,66(a5) # 80007970 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    80001936:	0ff0000f          	fence

    // We can invoke exec() now that file system is initialized.
    // Put the return value (argc) of exec into a0.
    p->trapframe->a0 = exec("/init", (char *[]){ "/init", 0 });
    8000193a:	00006517          	auipc	a0,0x6
    8000193e:	87650513          	addi	a0,a0,-1930 # 800071b0 <digits+0x160>
    80001942:	fca43823          	sd	a0,-48(s0)
    80001946:	fc043c23          	sd	zero,-40(s0)
    8000194a:	fd040593          	addi	a1,s0,-48
    8000194e:	34b020ef          	jal	ra,80004498 <exec>
    80001952:	70bc                	ld	a5,96(s1)
    80001954:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    80001956:	70bc                	ld	a5,96(s1)
    80001958:	7bb8                	ld	a4,112(a5)
    8000195a:	57fd                	li	a5,-1
    8000195c:	02f70d63          	beq	a4,a5,80001996 <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    80001960:	29b000ef          	jal	ra,800023fa <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80001964:	6ca8                	ld	a0,88(s1)
    80001966:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80001968:	04000737          	lui	a4,0x4000
    8000196c:	00004797          	auipc	a5,0x4
    80001970:	73078793          	addi	a5,a5,1840 # 8000609c <userret>
    80001974:	00004697          	auipc	a3,0x4
    80001978:	68c68693          	addi	a3,a3,1676 # 80006000 <_trampoline>
    8000197c:	8f95                	sub	a5,a5,a3
    8000197e:	177d                	addi	a4,a4,-1
    80001980:	0732                	slli	a4,a4,0xc
    80001982:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001984:	577d                	li	a4,-1
    80001986:	177e                	slli	a4,a4,0x3f
    80001988:	8d59                	or	a0,a0,a4
    8000198a:	9782                	jalr	a5
}
    8000198c:	70a2                	ld	ra,40(sp)
    8000198e:	7402                	ld	s0,32(sp)
    80001990:	64e2                	ld	s1,24(sp)
    80001992:	6145                	addi	sp,sp,48
    80001994:	8082                	ret
      panic("exec");
    80001996:	00006517          	auipc	a0,0x6
    8000199a:	82250513          	addi	a0,a0,-2014 # 800071b8 <digits+0x168>
    8000199e:	e3ffe0ef          	jal	ra,800007dc <panic>

00000000800019a2 <allocpid>:
{
    800019a2:	1101                	addi	sp,sp,-32
    800019a4:	ec06                	sd	ra,24(sp)
    800019a6:	e822                	sd	s0,16(sp)
    800019a8:	e426                	sd	s1,8(sp)
    800019aa:	e04a                	sd	s2,0(sp)
    800019ac:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800019ae:	0000e917          	auipc	s2,0xe
    800019b2:	12a90913          	addi	s2,s2,298 # 8000fad8 <pid_lock>
    800019b6:	854a                	mv	a0,s2
    800019b8:	a8aff0ef          	jal	ra,80000c42 <acquire>
  pid = nextpid;
    800019bc:	00006797          	auipc	a5,0x6
    800019c0:	fb878793          	addi	a5,a5,-72 # 80007974 <nextpid>
    800019c4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800019c6:	0014871b          	addiw	a4,s1,1
    800019ca:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800019cc:	854a                	mv	a0,s2
    800019ce:	b0cff0ef          	jal	ra,80000cda <release>
}
    800019d2:	8526                	mv	a0,s1
    800019d4:	60e2                	ld	ra,24(sp)
    800019d6:	6442                	ld	s0,16(sp)
    800019d8:	64a2                	ld	s1,8(sp)
    800019da:	6902                	ld	s2,0(sp)
    800019dc:	6105                	addi	sp,sp,32
    800019de:	8082                	ret

00000000800019e0 <proc_pagetable>:
{
    800019e0:	1101                	addi	sp,sp,-32
    800019e2:	ec06                	sd	ra,24(sp)
    800019e4:	e822                	sd	s0,16(sp)
    800019e6:	e426                	sd	s1,8(sp)
    800019e8:	e04a                	sd	s2,0(sp)
    800019ea:	1000                	addi	s0,sp,32
    800019ec:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800019ee:	89fff0ef          	jal	ra,8000128c <uvmcreate>
    800019f2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800019f4:	cd05                	beqz	a0,80001a2c <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800019f6:	4729                	li	a4,10
    800019f8:	00004697          	auipc	a3,0x4
    800019fc:	60868693          	addi	a3,a3,1544 # 80006000 <_trampoline>
    80001a00:	6605                	lui	a2,0x1
    80001a02:	040005b7          	lui	a1,0x4000
    80001a06:	15fd                	addi	a1,a1,-1
    80001a08:	05b2                	slli	a1,a1,0xc
    80001a0a:	e60ff0ef          	jal	ra,8000106a <mappages>
    80001a0e:	02054663          	bltz	a0,80001a3a <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a12:	4719                	li	a4,6
    80001a14:	06093683          	ld	a3,96(s2)
    80001a18:	6605                	lui	a2,0x1
    80001a1a:	020005b7          	lui	a1,0x2000
    80001a1e:	15fd                	addi	a1,a1,-1
    80001a20:	05b6                	slli	a1,a1,0xd
    80001a22:	8526                	mv	a0,s1
    80001a24:	e46ff0ef          	jal	ra,8000106a <mappages>
    80001a28:	00054f63          	bltz	a0,80001a46 <proc_pagetable+0x66>
}
    80001a2c:	8526                	mv	a0,s1
    80001a2e:	60e2                	ld	ra,24(sp)
    80001a30:	6442                	ld	s0,16(sp)
    80001a32:	64a2                	ld	s1,8(sp)
    80001a34:	6902                	ld	s2,0(sp)
    80001a36:	6105                	addi	sp,sp,32
    80001a38:	8082                	ret
    uvmfree(pagetable, 0);
    80001a3a:	4581                	li	a1,0
    80001a3c:	8526                	mv	a0,s1
    80001a3e:	9b1ff0ef          	jal	ra,800013ee <uvmfree>
    return 0;
    80001a42:	4481                	li	s1,0
    80001a44:	b7e5                	j	80001a2c <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a46:	4681                	li	a3,0
    80001a48:	4605                	li	a2,1
    80001a4a:	040005b7          	lui	a1,0x4000
    80001a4e:	15fd                	addi	a1,a1,-1
    80001a50:	05b2                	slli	a1,a1,0xc
    80001a52:	8526                	mv	a0,s1
    80001a54:	fbcff0ef          	jal	ra,80001210 <uvmunmap>
    uvmfree(pagetable, 0);
    80001a58:	4581                	li	a1,0
    80001a5a:	8526                	mv	a0,s1
    80001a5c:	993ff0ef          	jal	ra,800013ee <uvmfree>
    return 0;
    80001a60:	4481                	li	s1,0
    80001a62:	b7e9                	j	80001a2c <proc_pagetable+0x4c>

0000000080001a64 <proc_freepagetable>:
{
    80001a64:	1101                	addi	sp,sp,-32
    80001a66:	ec06                	sd	ra,24(sp)
    80001a68:	e822                	sd	s0,16(sp)
    80001a6a:	e426                	sd	s1,8(sp)
    80001a6c:	e04a                	sd	s2,0(sp)
    80001a6e:	1000                	addi	s0,sp,32
    80001a70:	84aa                	mv	s1,a0
    80001a72:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a74:	4681                	li	a3,0
    80001a76:	4605                	li	a2,1
    80001a78:	040005b7          	lui	a1,0x4000
    80001a7c:	15fd                	addi	a1,a1,-1
    80001a7e:	05b2                	slli	a1,a1,0xc
    80001a80:	f90ff0ef          	jal	ra,80001210 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001a84:	4681                	li	a3,0
    80001a86:	4605                	li	a2,1
    80001a88:	020005b7          	lui	a1,0x2000
    80001a8c:	15fd                	addi	a1,a1,-1
    80001a8e:	05b6                	slli	a1,a1,0xd
    80001a90:	8526                	mv	a0,s1
    80001a92:	f7eff0ef          	jal	ra,80001210 <uvmunmap>
  uvmfree(pagetable, sz);
    80001a96:	85ca                	mv	a1,s2
    80001a98:	8526                	mv	a0,s1
    80001a9a:	955ff0ef          	jal	ra,800013ee <uvmfree>
}
    80001a9e:	60e2                	ld	ra,24(sp)
    80001aa0:	6442                	ld	s0,16(sp)
    80001aa2:	64a2                	ld	s1,8(sp)
    80001aa4:	6902                	ld	s2,0(sp)
    80001aa6:	6105                	addi	sp,sp,32
    80001aa8:	8082                	ret

0000000080001aaa <freeproc>:
{
    80001aaa:	1101                	addi	sp,sp,-32
    80001aac:	ec06                	sd	ra,24(sp)
    80001aae:	e822                	sd	s0,16(sp)
    80001ab0:	e426                	sd	s1,8(sp)
    80001ab2:	1000                	addi	s0,sp,32
    80001ab4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ab6:	7128                	ld	a0,96(a0)
    80001ab8:	c119                	beqz	a0,80001abe <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001aba:	fd9fe0ef          	jal	ra,80000a92 <kfree>
  p->trapframe = 0;
    80001abe:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001ac2:	6ca8                	ld	a0,88(s1)
    80001ac4:	c501                	beqz	a0,80001acc <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001ac6:	68ac                	ld	a1,80(s1)
    80001ac8:	f9dff0ef          	jal	ra,80001a64 <proc_freepagetable>
  p->pagetable = 0;
    80001acc:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001ad0:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001ad4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ad8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001adc:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001ae0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ae4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ae8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001aec:	0004ac23          	sw	zero,24(s1)
}
    80001af0:	60e2                	ld	ra,24(sp)
    80001af2:	6442                	ld	s0,16(sp)
    80001af4:	64a2                	ld	s1,8(sp)
    80001af6:	6105                	addi	sp,sp,32
    80001af8:	8082                	ret

0000000080001afa <allocproc>:
{
    80001afa:	1101                	addi	sp,sp,-32
    80001afc:	ec06                	sd	ra,24(sp)
    80001afe:	e822                	sd	s0,16(sp)
    80001b00:	e426                	sd	s1,8(sp)
    80001b02:	e04a                	sd	s2,0(sp)
    80001b04:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b06:	0000e497          	auipc	s1,0xe
    80001b0a:	40248493          	addi	s1,s1,1026 # 8000ff08 <proc>
    80001b0e:	00014917          	auipc	s2,0x14
    80001b12:	ffa90913          	addi	s2,s2,-6 # 80015b08 <tickslock>
    acquire(&p->lock);
    80001b16:	8526                	mv	a0,s1
    80001b18:	92aff0ef          	jal	ra,80000c42 <acquire>
    if(p->state == UNUSED) {
    80001b1c:	4c9c                	lw	a5,24(s1)
    80001b1e:	cb91                	beqz	a5,80001b32 <allocproc+0x38>
      release(&p->lock);
    80001b20:	8526                	mv	a0,s1
    80001b22:	9b8ff0ef          	jal	ra,80000cda <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b26:	17048493          	addi	s1,s1,368
    80001b2a:	ff2496e3          	bne	s1,s2,80001b16 <allocproc+0x1c>
  return 0;
    80001b2e:	4481                	li	s1,0
    80001b30:	a089                	j	80001b72 <allocproc+0x78>
  p->pid = allocpid();
    80001b32:	e71ff0ef          	jal	ra,800019a2 <allocpid>
    80001b36:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001b38:	4785                	li	a5,1
    80001b3a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001b3c:	836ff0ef          	jal	ra,80000b72 <kalloc>
    80001b40:	892a                	mv	s2,a0
    80001b42:	f0a8                	sd	a0,96(s1)
    80001b44:	cd15                	beqz	a0,80001b80 <allocproc+0x86>
  p->pagetable = proc_pagetable(p);
    80001b46:	8526                	mv	a0,s1
    80001b48:	e99ff0ef          	jal	ra,800019e0 <proc_pagetable>
    80001b4c:	892a                	mv	s2,a0
    80001b4e:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001b50:	c121                	beqz	a0,80001b90 <allocproc+0x96>
  memset(&p->context, 0, sizeof(p->context));
    80001b52:	07000613          	li	a2,112
    80001b56:	4581                	li	a1,0
    80001b58:	06848513          	addi	a0,s1,104
    80001b5c:	9baff0ef          	jal	ra,80000d16 <memset>
  p->context.ra = (uint64)forkret;
    80001b60:	00000797          	auipc	a5,0x0
    80001b64:	daa78793          	addi	a5,a5,-598 # 8000190a <forkret>
    80001b68:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001b6a:	64bc                	ld	a5,72(s1)
    80001b6c:	6705                	lui	a4,0x1
    80001b6e:	97ba                	add	a5,a5,a4
    80001b70:	f8bc                	sd	a5,112(s1)
}
    80001b72:	8526                	mv	a0,s1
    80001b74:	60e2                	ld	ra,24(sp)
    80001b76:	6442                	ld	s0,16(sp)
    80001b78:	64a2                	ld	s1,8(sp)
    80001b7a:	6902                	ld	s2,0(sp)
    80001b7c:	6105                	addi	sp,sp,32
    80001b7e:	8082                	ret
    freeproc(p);
    80001b80:	8526                	mv	a0,s1
    80001b82:	f29ff0ef          	jal	ra,80001aaa <freeproc>
    release(&p->lock);
    80001b86:	8526                	mv	a0,s1
    80001b88:	952ff0ef          	jal	ra,80000cda <release>
    return 0;
    80001b8c:	84ca                	mv	s1,s2
    80001b8e:	b7d5                	j	80001b72 <allocproc+0x78>
    freeproc(p);
    80001b90:	8526                	mv	a0,s1
    80001b92:	f19ff0ef          	jal	ra,80001aaa <freeproc>
    release(&p->lock);
    80001b96:	8526                	mv	a0,s1
    80001b98:	942ff0ef          	jal	ra,80000cda <release>
    return 0;
    80001b9c:	84ca                	mv	s1,s2
    80001b9e:	bfd1                	j	80001b72 <allocproc+0x78>

0000000080001ba0 <userinit>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001baa:	f51ff0ef          	jal	ra,80001afa <allocproc>
    80001bae:	84aa                	mv	s1,a0
  initproc = p;
    80001bb0:	00006797          	auipc	a5,0x6
    80001bb4:	dea7bc23          	sd	a0,-520(a5) # 800079a8 <initproc>
  p->cwd = namei("/");
    80001bb8:	00005517          	auipc	a0,0x5
    80001bbc:	60850513          	addi	a0,a0,1544 # 800071c0 <digits+0x170>
    80001bc0:	53f010ef          	jal	ra,800038fe <namei>
    80001bc4:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001bc8:	478d                	li	a5,3
    80001bca:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001bcc:	8526                	mv	a0,s1
    80001bce:	90cff0ef          	jal	ra,80000cda <release>
}
    80001bd2:	60e2                	ld	ra,24(sp)
    80001bd4:	6442                	ld	s0,16(sp)
    80001bd6:	64a2                	ld	s1,8(sp)
    80001bd8:	6105                	addi	sp,sp,32
    80001bda:	8082                	ret

0000000080001bdc <shrinkproc>:
{
    80001bdc:	1101                	addi	sp,sp,-32
    80001bde:	ec06                	sd	ra,24(sp)
    80001be0:	e822                	sd	s0,16(sp)
    80001be2:	e426                	sd	s1,8(sp)
    80001be4:	e04a                	sd	s2,0(sp)
    80001be6:	1000                	addi	s0,sp,32
    80001be8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001bea:	cf1ff0ef          	jal	ra,800018da <myproc>
  if(n > p->sz)
    80001bee:	692c                	ld	a1,80(a0)
    80001bf0:	0325e063          	bltu	a1,s2,80001c10 <shrinkproc+0x34>
    80001bf4:	84aa                	mv	s1,a0
  sz = uvmdealloc(p->pagetable, sz, sz - n);
    80001bf6:	41258633          	sub	a2,a1,s2
    80001bfa:	6d28                	ld	a0,88(a0)
    80001bfc:	eb6ff0ef          	jal	ra,800012b2 <uvmdealloc>
  p->sz = sz;
    80001c00:	e8a8                	sd	a0,80(s1)
  return 0;
    80001c02:	4501                	li	a0,0
}
    80001c04:	60e2                	ld	ra,24(sp)
    80001c06:	6442                	ld	s0,16(sp)
    80001c08:	64a2                	ld	s1,8(sp)
    80001c0a:	6902                	ld	s2,0(sp)
    80001c0c:	6105                	addi	sp,sp,32
    80001c0e:	8082                	ret
    return -1;
    80001c10:	557d                	li	a0,-1
    80001c12:	bfcd                	j	80001c04 <shrinkproc+0x28>

0000000080001c14 <fork>:
{
    80001c14:	7139                	addi	sp,sp,-64
    80001c16:	fc06                	sd	ra,56(sp)
    80001c18:	f822                	sd	s0,48(sp)
    80001c1a:	f426                	sd	s1,40(sp)
    80001c1c:	f04a                	sd	s2,32(sp)
    80001c1e:	ec4e                	sd	s3,24(sp)
    80001c20:	e852                	sd	s4,16(sp)
    80001c22:	e456                	sd	s5,8(sp)
    80001c24:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001c26:	cb5ff0ef          	jal	ra,800018da <myproc>
    80001c2a:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001c2c:	ecfff0ef          	jal	ra,80001afa <allocproc>
    80001c30:	0e050a63          	beqz	a0,80001d24 <fork+0x110>
    80001c34:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001c36:	050ab603          	ld	a2,80(s5)
    80001c3a:	6d2c                	ld	a1,88(a0)
    80001c3c:	058ab503          	ld	a0,88(s5)
    80001c40:	fdeff0ef          	jal	ra,8000141e <uvmcopy>
    80001c44:	04054863          	bltz	a0,80001c94 <fork+0x80>
  np->sz = p->sz;
    80001c48:	050ab783          	ld	a5,80(s5)
    80001c4c:	04f9b823          	sd	a5,80(s3)
  *(np->trapframe) = *(p->trapframe);
    80001c50:	060ab683          	ld	a3,96(s5)
    80001c54:	87b6                	mv	a5,a3
    80001c56:	0609b703          	ld	a4,96(s3)
    80001c5a:	12068693          	addi	a3,a3,288
    80001c5e:	0007b803          	ld	a6,0(a5)
    80001c62:	6788                	ld	a0,8(a5)
    80001c64:	6b8c                	ld	a1,16(a5)
    80001c66:	6f90                	ld	a2,24(a5)
    80001c68:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001c6c:	e708                	sd	a0,8(a4)
    80001c6e:	eb0c                	sd	a1,16(a4)
    80001c70:	ef10                	sd	a2,24(a4)
    80001c72:	02078793          	addi	a5,a5,32
    80001c76:	02070713          	addi	a4,a4,32
    80001c7a:	fed792e3          	bne	a5,a3,80001c5e <fork+0x4a>
  np->trapframe->a0 = 0;
    80001c7e:	0609b783          	ld	a5,96(s3)
    80001c82:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001c86:	0d8a8493          	addi	s1,s5,216
    80001c8a:	0d898913          	addi	s2,s3,216
    80001c8e:	158a8a13          	addi	s4,s5,344
    80001c92:	a829                	j	80001cac <fork+0x98>
    freeproc(np);
    80001c94:	854e                	mv	a0,s3
    80001c96:	e15ff0ef          	jal	ra,80001aaa <freeproc>
    release(&np->lock);
    80001c9a:	854e                	mv	a0,s3
    80001c9c:	83eff0ef          	jal	ra,80000cda <release>
    return -1;
    80001ca0:	597d                	li	s2,-1
    80001ca2:	a0bd                	j	80001d10 <fork+0xfc>
  for(i = 0; i < NOFILE; i++)
    80001ca4:	04a1                	addi	s1,s1,8
    80001ca6:	0921                	addi	s2,s2,8
    80001ca8:	01448963          	beq	s1,s4,80001cba <fork+0xa6>
    if(p->ofile[i])
    80001cac:	6088                	ld	a0,0(s1)
    80001cae:	d97d                	beqz	a0,80001ca4 <fork+0x90>
      np->ofile[i] = filedup(p->ofile[i]);
    80001cb0:	200020ef          	jal	ra,80003eb0 <filedup>
    80001cb4:	00a93023          	sd	a0,0(s2)
    80001cb8:	b7f5                	j	80001ca4 <fork+0x90>
  np->cwd = idup(p->cwd);
    80001cba:	158ab503          	ld	a0,344(s5)
    80001cbe:	558010ef          	jal	ra,80003216 <idup>
    80001cc2:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001cc6:	4641                	li	a2,16
    80001cc8:	160a8593          	addi	a1,s5,352
    80001ccc:	16098513          	addi	a0,s3,352
    80001cd0:	98cff0ef          	jal	ra,80000e5c <safestrcpy>
  pid = np->pid;
    80001cd4:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001cd8:	854e                	mv	a0,s3
    80001cda:	800ff0ef          	jal	ra,80000cda <release>
  acquire(&wait_lock);
    80001cde:	0000e497          	auipc	s1,0xe
    80001ce2:	e1248493          	addi	s1,s1,-494 # 8000faf0 <wait_lock>
    80001ce6:	8526                	mv	a0,s1
    80001ce8:	f5bfe0ef          	jal	ra,80000c42 <acquire>
  np->parent = p;
    80001cec:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001cf0:	8526                	mv	a0,s1
    80001cf2:	fe9fe0ef          	jal	ra,80000cda <release>
  acquire(&np->lock);
    80001cf6:	854e                	mv	a0,s3
    80001cf8:	f4bfe0ef          	jal	ra,80000c42 <acquire>
  np->state = RUNNABLE;
    80001cfc:	478d                	li	a5,3
    80001cfe:	00f9ac23          	sw	a5,24(s3)
  np->tracemask = p->tracemask;
    80001d02:	040aa783          	lw	a5,64(s5)
    80001d06:	04f9a023          	sw	a5,64(s3)
  release(&np->lock);
    80001d0a:	854e                	mv	a0,s3
    80001d0c:	fcffe0ef          	jal	ra,80000cda <release>
}
    80001d10:	854a                	mv	a0,s2
    80001d12:	70e2                	ld	ra,56(sp)
    80001d14:	7442                	ld	s0,48(sp)
    80001d16:	74a2                	ld	s1,40(sp)
    80001d18:	7902                	ld	s2,32(sp)
    80001d1a:	69e2                	ld	s3,24(sp)
    80001d1c:	6a42                	ld	s4,16(sp)
    80001d1e:	6aa2                	ld	s5,8(sp)
    80001d20:	6121                	addi	sp,sp,64
    80001d22:	8082                	ret
    return -1;
    80001d24:	597d                	li	s2,-1
    80001d26:	b7ed                	j	80001d10 <fork+0xfc>

0000000080001d28 <scheduler>:
{
    80001d28:	715d                	addi	sp,sp,-80
    80001d2a:	e486                	sd	ra,72(sp)
    80001d2c:	e0a2                	sd	s0,64(sp)
    80001d2e:	fc26                	sd	s1,56(sp)
    80001d30:	f84a                	sd	s2,48(sp)
    80001d32:	f44e                	sd	s3,40(sp)
    80001d34:	f052                	sd	s4,32(sp)
    80001d36:	ec56                	sd	s5,24(sp)
    80001d38:	e85a                	sd	s6,16(sp)
    80001d3a:	e45e                	sd	s7,8(sp)
    80001d3c:	e062                	sd	s8,0(sp)
    80001d3e:	0880                	addi	s0,sp,80
    80001d40:	8792                	mv	a5,tp
  int id = r_tp();
    80001d42:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001d44:	00779b13          	slli	s6,a5,0x7
    80001d48:	0000e717          	auipc	a4,0xe
    80001d4c:	d9070713          	addi	a4,a4,-624 # 8000fad8 <pid_lock>
    80001d50:	975a                	add	a4,a4,s6
    80001d52:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001d56:	0000e717          	auipc	a4,0xe
    80001d5a:	dba70713          	addi	a4,a4,-582 # 8000fb10 <cpus+0x8>
    80001d5e:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001d60:	4c11                	li	s8,4
        c->proc = p;
    80001d62:	079e                	slli	a5,a5,0x7
    80001d64:	0000ea17          	auipc	s4,0xe
    80001d68:	d74a0a13          	addi	s4,s4,-652 # 8000fad8 <pid_lock>
    80001d6c:	9a3e                	add	s4,s4,a5
        found = 1;
    80001d6e:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001d70:	00014997          	auipc	s3,0x14
    80001d74:	d9898993          	addi	s3,s3,-616 # 80015b08 <tickslock>
    80001d78:	a83d                	j	80001db6 <scheduler+0x8e>
      release(&p->lock);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	f5ffe0ef          	jal	ra,80000cda <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001d80:	17048493          	addi	s1,s1,368
    80001d84:	03348563          	beq	s1,s3,80001dae <scheduler+0x86>
      acquire(&p->lock);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	eb9fe0ef          	jal	ra,80000c42 <acquire>
      if(p->state == RUNNABLE) {
    80001d8e:	4c9c                	lw	a5,24(s1)
    80001d90:	ff2795e3          	bne	a5,s2,80001d7a <scheduler+0x52>
        p->state = RUNNING;
    80001d94:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001d98:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001d9c:	06848593          	addi	a1,s1,104
    80001da0:	855a                	mv	a0,s6
    80001da2:	5b2000ef          	jal	ra,80002354 <swtch>
        c->proc = 0;
    80001da6:	020a3823          	sd	zero,48(s4)
        found = 1;
    80001daa:	8ade                	mv	s5,s7
    80001dac:	b7f9                	j	80001d7a <scheduler+0x52>
    if(found == 0) {
    80001dae:	000a9463          	bnez	s5,80001db6 <scheduler+0x8e>
      asm volatile("wfi");
    80001db2:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001db6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001dba:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001dbe:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001dc2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001dc6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001dc8:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001dcc:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001dce:	0000e497          	auipc	s1,0xe
    80001dd2:	13a48493          	addi	s1,s1,314 # 8000ff08 <proc>
      if(p->state == RUNNABLE) {
    80001dd6:	490d                	li	s2,3
    80001dd8:	bf45                	j	80001d88 <scheduler+0x60>

0000000080001dda <sched>:
{
    80001dda:	7179                	addi	sp,sp,-48
    80001ddc:	f406                	sd	ra,40(sp)
    80001dde:	f022                	sd	s0,32(sp)
    80001de0:	ec26                	sd	s1,24(sp)
    80001de2:	e84a                	sd	s2,16(sp)
    80001de4:	e44e                	sd	s3,8(sp)
    80001de6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001de8:	af3ff0ef          	jal	ra,800018da <myproc>
    80001dec:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001dee:	debfe0ef          	jal	ra,80000bd8 <holding>
    80001df2:	c92d                	beqz	a0,80001e64 <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001df4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001df6:	2781                	sext.w	a5,a5
    80001df8:	079e                	slli	a5,a5,0x7
    80001dfa:	0000e717          	auipc	a4,0xe
    80001dfe:	cde70713          	addi	a4,a4,-802 # 8000fad8 <pid_lock>
    80001e02:	97ba                	add	a5,a5,a4
    80001e04:	0a87a703          	lw	a4,168(a5)
    80001e08:	4785                	li	a5,1
    80001e0a:	06f71363          	bne	a4,a5,80001e70 <sched+0x96>
  if(p->state == RUNNING)
    80001e0e:	4c98                	lw	a4,24(s1)
    80001e10:	4791                	li	a5,4
    80001e12:	06f70563          	beq	a4,a5,80001e7c <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e16:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001e1a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001e1c:	e7b5                	bnez	a5,80001e88 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e1e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001e20:	0000e917          	auipc	s2,0xe
    80001e24:	cb890913          	addi	s2,s2,-840 # 8000fad8 <pid_lock>
    80001e28:	2781                	sext.w	a5,a5
    80001e2a:	079e                	slli	a5,a5,0x7
    80001e2c:	97ca                	add	a5,a5,s2
    80001e2e:	0ac7a983          	lw	s3,172(a5)
    80001e32:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001e34:	2781                	sext.w	a5,a5
    80001e36:	079e                	slli	a5,a5,0x7
    80001e38:	0000e597          	auipc	a1,0xe
    80001e3c:	cd858593          	addi	a1,a1,-808 # 8000fb10 <cpus+0x8>
    80001e40:	95be                	add	a1,a1,a5
    80001e42:	06848513          	addi	a0,s1,104
    80001e46:	50e000ef          	jal	ra,80002354 <swtch>
    80001e4a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001e4c:	2781                	sext.w	a5,a5
    80001e4e:	079e                	slli	a5,a5,0x7
    80001e50:	97ca                	add	a5,a5,s2
    80001e52:	0b37a623          	sw	s3,172(a5)
}
    80001e56:	70a2                	ld	ra,40(sp)
    80001e58:	7402                	ld	s0,32(sp)
    80001e5a:	64e2                	ld	s1,24(sp)
    80001e5c:	6942                	ld	s2,16(sp)
    80001e5e:	69a2                	ld	s3,8(sp)
    80001e60:	6145                	addi	sp,sp,48
    80001e62:	8082                	ret
    panic("sched p->lock");
    80001e64:	00005517          	auipc	a0,0x5
    80001e68:	36450513          	addi	a0,a0,868 # 800071c8 <digits+0x178>
    80001e6c:	971fe0ef          	jal	ra,800007dc <panic>
    panic("sched locks");
    80001e70:	00005517          	auipc	a0,0x5
    80001e74:	36850513          	addi	a0,a0,872 # 800071d8 <digits+0x188>
    80001e78:	965fe0ef          	jal	ra,800007dc <panic>
    panic("sched RUNNING");
    80001e7c:	00005517          	auipc	a0,0x5
    80001e80:	36c50513          	addi	a0,a0,876 # 800071e8 <digits+0x198>
    80001e84:	959fe0ef          	jal	ra,800007dc <panic>
    panic("sched interruptible");
    80001e88:	00005517          	auipc	a0,0x5
    80001e8c:	37050513          	addi	a0,a0,880 # 800071f8 <digits+0x1a8>
    80001e90:	94dfe0ef          	jal	ra,800007dc <panic>

0000000080001e94 <yield>:
{
    80001e94:	1101                	addi	sp,sp,-32
    80001e96:	ec06                	sd	ra,24(sp)
    80001e98:	e822                	sd	s0,16(sp)
    80001e9a:	e426                	sd	s1,8(sp)
    80001e9c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001e9e:	a3dff0ef          	jal	ra,800018da <myproc>
    80001ea2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001ea4:	d9ffe0ef          	jal	ra,80000c42 <acquire>
  p->state = RUNNABLE;
    80001ea8:	478d                	li	a5,3
    80001eaa:	cc9c                	sw	a5,24(s1)
  sched();
    80001eac:	f2fff0ef          	jal	ra,80001dda <sched>
  release(&p->lock);
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	e29fe0ef          	jal	ra,80000cda <release>
}
    80001eb6:	60e2                	ld	ra,24(sp)
    80001eb8:	6442                	ld	s0,16(sp)
    80001eba:	64a2                	ld	s1,8(sp)
    80001ebc:	6105                	addi	sp,sp,32
    80001ebe:	8082                	ret

0000000080001ec0 <sleep>:

// Sleep on wait channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001ec0:	7179                	addi	sp,sp,-48
    80001ec2:	f406                	sd	ra,40(sp)
    80001ec4:	f022                	sd	s0,32(sp)
    80001ec6:	ec26                	sd	s1,24(sp)
    80001ec8:	e84a                	sd	s2,16(sp)
    80001eca:	e44e                	sd	s3,8(sp)
    80001ecc:	1800                	addi	s0,sp,48
    80001ece:	89aa                	mv	s3,a0
    80001ed0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001ed2:	a09ff0ef          	jal	ra,800018da <myproc>
    80001ed6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001ed8:	d6bfe0ef          	jal	ra,80000c42 <acquire>
  release(lk);
    80001edc:	854a                	mv	a0,s2
    80001ede:	dfdfe0ef          	jal	ra,80000cda <release>

  // Go to sleep.
  p->chan = chan;
    80001ee2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001ee6:	4789                	li	a5,2
    80001ee8:	cc9c                	sw	a5,24(s1)

  sched();
    80001eea:	ef1ff0ef          	jal	ra,80001dda <sched>

  // Tidy up.
  p->chan = 0;
    80001eee:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001ef2:	8526                	mv	a0,s1
    80001ef4:	de7fe0ef          	jal	ra,80000cda <release>
  acquire(lk);
    80001ef8:	854a                	mv	a0,s2
    80001efa:	d49fe0ef          	jal	ra,80000c42 <acquire>
}
    80001efe:	70a2                	ld	ra,40(sp)
    80001f00:	7402                	ld	s0,32(sp)
    80001f02:	64e2                	ld	s1,24(sp)
    80001f04:	6942                	ld	s2,16(sp)
    80001f06:	69a2                	ld	s3,8(sp)
    80001f08:	6145                	addi	sp,sp,48
    80001f0a:	8082                	ret

0000000080001f0c <wakeup>:

// Wake up all processes sleeping on wait channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80001f0c:	7139                	addi	sp,sp,-64
    80001f0e:	fc06                	sd	ra,56(sp)
    80001f10:	f822                	sd	s0,48(sp)
    80001f12:	f426                	sd	s1,40(sp)
    80001f14:	f04a                	sd	s2,32(sp)
    80001f16:	ec4e                	sd	s3,24(sp)
    80001f18:	e852                	sd	s4,16(sp)
    80001f1a:	e456                	sd	s5,8(sp)
    80001f1c:	0080                	addi	s0,sp,64
    80001f1e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001f20:	0000e497          	auipc	s1,0xe
    80001f24:	fe848493          	addi	s1,s1,-24 # 8000ff08 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001f28:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001f2a:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f2c:	00014917          	auipc	s2,0x14
    80001f30:	bdc90913          	addi	s2,s2,-1060 # 80015b08 <tickslock>
    80001f34:	a801                	j	80001f44 <wakeup+0x38>
      }
      release(&p->lock);
    80001f36:	8526                	mv	a0,s1
    80001f38:	da3fe0ef          	jal	ra,80000cda <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f3c:	17048493          	addi	s1,s1,368
    80001f40:	03248263          	beq	s1,s2,80001f64 <wakeup+0x58>
    if(p != myproc()){
    80001f44:	997ff0ef          	jal	ra,800018da <myproc>
    80001f48:	fea48ae3          	beq	s1,a0,80001f3c <wakeup+0x30>
      acquire(&p->lock);
    80001f4c:	8526                	mv	a0,s1
    80001f4e:	cf5fe0ef          	jal	ra,80000c42 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001f52:	4c9c                	lw	a5,24(s1)
    80001f54:	ff3791e3          	bne	a5,s3,80001f36 <wakeup+0x2a>
    80001f58:	709c                	ld	a5,32(s1)
    80001f5a:	fd479ee3          	bne	a5,s4,80001f36 <wakeup+0x2a>
        p->state = RUNNABLE;
    80001f5e:	0154ac23          	sw	s5,24(s1)
    80001f62:	bfd1                	j	80001f36 <wakeup+0x2a>
    }
  }
}
    80001f64:	70e2                	ld	ra,56(sp)
    80001f66:	7442                	ld	s0,48(sp)
    80001f68:	74a2                	ld	s1,40(sp)
    80001f6a:	7902                	ld	s2,32(sp)
    80001f6c:	69e2                	ld	s3,24(sp)
    80001f6e:	6a42                	ld	s4,16(sp)
    80001f70:	6aa2                	ld	s5,8(sp)
    80001f72:	6121                	addi	sp,sp,64
    80001f74:	8082                	ret

0000000080001f76 <reparent>:
{
    80001f76:	7179                	addi	sp,sp,-48
    80001f78:	f406                	sd	ra,40(sp)
    80001f7a:	f022                	sd	s0,32(sp)
    80001f7c:	ec26                	sd	s1,24(sp)
    80001f7e:	e84a                	sd	s2,16(sp)
    80001f80:	e44e                	sd	s3,8(sp)
    80001f82:	e052                	sd	s4,0(sp)
    80001f84:	1800                	addi	s0,sp,48
    80001f86:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f88:	0000e497          	auipc	s1,0xe
    80001f8c:	f8048493          	addi	s1,s1,-128 # 8000ff08 <proc>
      pp->parent = initproc;
    80001f90:	00006a17          	auipc	s4,0x6
    80001f94:	a18a0a13          	addi	s4,s4,-1512 # 800079a8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f98:	00014997          	auipc	s3,0x14
    80001f9c:	b7098993          	addi	s3,s3,-1168 # 80015b08 <tickslock>
    80001fa0:	a029                	j	80001faa <reparent+0x34>
    80001fa2:	17048493          	addi	s1,s1,368
    80001fa6:	01348b63          	beq	s1,s3,80001fbc <reparent+0x46>
    if(pp->parent == p){
    80001faa:	7c9c                	ld	a5,56(s1)
    80001fac:	ff279be3          	bne	a5,s2,80001fa2 <reparent+0x2c>
      pp->parent = initproc;
    80001fb0:	000a3503          	ld	a0,0(s4)
    80001fb4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80001fb6:	f57ff0ef          	jal	ra,80001f0c <wakeup>
    80001fba:	b7e5                	j	80001fa2 <reparent+0x2c>
}
    80001fbc:	70a2                	ld	ra,40(sp)
    80001fbe:	7402                	ld	s0,32(sp)
    80001fc0:	64e2                	ld	s1,24(sp)
    80001fc2:	6942                	ld	s2,16(sp)
    80001fc4:	69a2                	ld	s3,8(sp)
    80001fc6:	6a02                	ld	s4,0(sp)
    80001fc8:	6145                	addi	sp,sp,48
    80001fca:	8082                	ret

0000000080001fcc <exit>:
{
    80001fcc:	7179                	addi	sp,sp,-48
    80001fce:	f406                	sd	ra,40(sp)
    80001fd0:	f022                	sd	s0,32(sp)
    80001fd2:	ec26                	sd	s1,24(sp)
    80001fd4:	e84a                	sd	s2,16(sp)
    80001fd6:	e44e                	sd	s3,8(sp)
    80001fd8:	e052                	sd	s4,0(sp)
    80001fda:	1800                	addi	s0,sp,48
    80001fdc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001fde:	8fdff0ef          	jal	ra,800018da <myproc>
    80001fe2:	89aa                	mv	s3,a0
  if(p == initproc)
    80001fe4:	00006797          	auipc	a5,0x6
    80001fe8:	9c47b783          	ld	a5,-1596(a5) # 800079a8 <initproc>
    80001fec:	0d850493          	addi	s1,a0,216
    80001ff0:	15850913          	addi	s2,a0,344
    80001ff4:	00a79f63          	bne	a5,a0,80002012 <exit+0x46>
    panic("init exiting");
    80001ff8:	00005517          	auipc	a0,0x5
    80001ffc:	21850513          	addi	a0,a0,536 # 80007210 <digits+0x1c0>
    80002000:	fdcfe0ef          	jal	ra,800007dc <panic>
      fileclose(f);
    80002004:	6f3010ef          	jal	ra,80003ef6 <fileclose>
      p->ofile[fd] = 0;
    80002008:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000200c:	04a1                	addi	s1,s1,8
    8000200e:	01248563          	beq	s1,s2,80002018 <exit+0x4c>
    if(p->ofile[fd]){
    80002012:	6088                	ld	a0,0(s1)
    80002014:	f965                	bnez	a0,80002004 <exit+0x38>
    80002016:	bfdd                	j	8000200c <exit+0x40>
  begin_op();
    80002018:	2c3010ef          	jal	ra,80003ada <begin_op>
  iput(p->cwd);
    8000201c:	1589b503          	ld	a0,344(s3)
    80002020:	3aa010ef          	jal	ra,800033ca <iput>
  end_op();
    80002024:	327010ef          	jal	ra,80003b4a <end_op>
  p->cwd = 0;
    80002028:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    8000202c:	0000e497          	auipc	s1,0xe
    80002030:	ac448493          	addi	s1,s1,-1340 # 8000faf0 <wait_lock>
    80002034:	8526                	mv	a0,s1
    80002036:	c0dfe0ef          	jal	ra,80000c42 <acquire>
  reparent(p);
    8000203a:	854e                	mv	a0,s3
    8000203c:	f3bff0ef          	jal	ra,80001f76 <reparent>
  wakeup(p->parent);
    80002040:	0389b503          	ld	a0,56(s3)
    80002044:	ec9ff0ef          	jal	ra,80001f0c <wakeup>
  acquire(&p->lock);
    80002048:	854e                	mv	a0,s3
    8000204a:	bf9fe0ef          	jal	ra,80000c42 <acquire>
  p->xstate = status;
    8000204e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002052:	4795                	li	a5,5
    80002054:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002058:	8526                	mv	a0,s1
    8000205a:	c81fe0ef          	jal	ra,80000cda <release>
  sched();
    8000205e:	d7dff0ef          	jal	ra,80001dda <sched>
  panic("zombie exit");
    80002062:	00005517          	auipc	a0,0x5
    80002066:	1be50513          	addi	a0,a0,446 # 80007220 <digits+0x1d0>
    8000206a:	f72fe0ef          	jal	ra,800007dc <panic>

000000008000206e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000206e:	7179                	addi	sp,sp,-48
    80002070:	f406                	sd	ra,40(sp)
    80002072:	f022                	sd	s0,32(sp)
    80002074:	ec26                	sd	s1,24(sp)
    80002076:	e84a                	sd	s2,16(sp)
    80002078:	e44e                	sd	s3,8(sp)
    8000207a:	1800                	addi	s0,sp,48
    8000207c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000207e:	0000e497          	auipc	s1,0xe
    80002082:	e8a48493          	addi	s1,s1,-374 # 8000ff08 <proc>
    80002086:	00014997          	auipc	s3,0x14
    8000208a:	a8298993          	addi	s3,s3,-1406 # 80015b08 <tickslock>
    acquire(&p->lock);
    8000208e:	8526                	mv	a0,s1
    80002090:	bb3fe0ef          	jal	ra,80000c42 <acquire>
    if(p->pid == pid){
    80002094:	589c                	lw	a5,48(s1)
    80002096:	01278b63          	beq	a5,s2,800020ac <kill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000209a:	8526                	mv	a0,s1
    8000209c:	c3ffe0ef          	jal	ra,80000cda <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800020a0:	17048493          	addi	s1,s1,368
    800020a4:	ff3495e3          	bne	s1,s3,8000208e <kill+0x20>
  }
  return -1;
    800020a8:	557d                	li	a0,-1
    800020aa:	a819                	j	800020c0 <kill+0x52>
      p->killed = 1;
    800020ac:	4785                	li	a5,1
    800020ae:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800020b0:	4c98                	lw	a4,24(s1)
    800020b2:	4789                	li	a5,2
    800020b4:	00f70d63          	beq	a4,a5,800020ce <kill+0x60>
      release(&p->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	c21fe0ef          	jal	ra,80000cda <release>
      return 0;
    800020be:	4501                	li	a0,0
}
    800020c0:	70a2                	ld	ra,40(sp)
    800020c2:	7402                	ld	s0,32(sp)
    800020c4:	64e2                	ld	s1,24(sp)
    800020c6:	6942                	ld	s2,16(sp)
    800020c8:	69a2                	ld	s3,8(sp)
    800020ca:	6145                	addi	sp,sp,48
    800020cc:	8082                	ret
        p->state = RUNNABLE;
    800020ce:	478d                	li	a5,3
    800020d0:	cc9c                	sw	a5,24(s1)
    800020d2:	b7dd                	j	800020b8 <kill+0x4a>

00000000800020d4 <setkilled>:

void
setkilled(struct proc *p)
{
    800020d4:	1101                	addi	sp,sp,-32
    800020d6:	ec06                	sd	ra,24(sp)
    800020d8:	e822                	sd	s0,16(sp)
    800020da:	e426                	sd	s1,8(sp)
    800020dc:	1000                	addi	s0,sp,32
    800020de:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020e0:	b63fe0ef          	jal	ra,80000c42 <acquire>
  p->killed = 1;
    800020e4:	4785                	li	a5,1
    800020e6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800020e8:	8526                	mv	a0,s1
    800020ea:	bf1fe0ef          	jal	ra,80000cda <release>
}
    800020ee:	60e2                	ld	ra,24(sp)
    800020f0:	6442                	ld	s0,16(sp)
    800020f2:	64a2                	ld	s1,8(sp)
    800020f4:	6105                	addi	sp,sp,32
    800020f6:	8082                	ret

00000000800020f8 <killed>:

int
killed(struct proc *p)
{
    800020f8:	1101                	addi	sp,sp,-32
    800020fa:	ec06                	sd	ra,24(sp)
    800020fc:	e822                	sd	s0,16(sp)
    800020fe:	e426                	sd	s1,8(sp)
    80002100:	e04a                	sd	s2,0(sp)
    80002102:	1000                	addi	s0,sp,32
    80002104:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002106:	b3dfe0ef          	jal	ra,80000c42 <acquire>
  k = p->killed;
    8000210a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000210e:	8526                	mv	a0,s1
    80002110:	bcbfe0ef          	jal	ra,80000cda <release>
  return k;
}
    80002114:	854a                	mv	a0,s2
    80002116:	60e2                	ld	ra,24(sp)
    80002118:	6442                	ld	s0,16(sp)
    8000211a:	64a2                	ld	s1,8(sp)
    8000211c:	6902                	ld	s2,0(sp)
    8000211e:	6105                	addi	sp,sp,32
    80002120:	8082                	ret

0000000080002122 <wait>:
{
    80002122:	715d                	addi	sp,sp,-80
    80002124:	e486                	sd	ra,72(sp)
    80002126:	e0a2                	sd	s0,64(sp)
    80002128:	fc26                	sd	s1,56(sp)
    8000212a:	f84a                	sd	s2,48(sp)
    8000212c:	f44e                	sd	s3,40(sp)
    8000212e:	f052                	sd	s4,32(sp)
    80002130:	ec56                	sd	s5,24(sp)
    80002132:	e85a                	sd	s6,16(sp)
    80002134:	e45e                	sd	s7,8(sp)
    80002136:	e062                	sd	s8,0(sp)
    80002138:	0880                	addi	s0,sp,80
    8000213a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000213c:	f9eff0ef          	jal	ra,800018da <myproc>
    80002140:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002142:	0000e517          	auipc	a0,0xe
    80002146:	9ae50513          	addi	a0,a0,-1618 # 8000faf0 <wait_lock>
    8000214a:	af9fe0ef          	jal	ra,80000c42 <acquire>
    havekids = 0;
    8000214e:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002150:	4a15                	li	s4,5
        havekids = 1;
    80002152:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002154:	00014997          	auipc	s3,0x14
    80002158:	9b498993          	addi	s3,s3,-1612 # 80015b08 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000215c:	0000ec17          	auipc	s8,0xe
    80002160:	994c0c13          	addi	s8,s8,-1644 # 8000faf0 <wait_lock>
    havekids = 0;
    80002164:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002166:	0000e497          	auipc	s1,0xe
    8000216a:	da248493          	addi	s1,s1,-606 # 8000ff08 <proc>
    8000216e:	a899                	j	800021c4 <wait+0xa2>
          pid = pp->pid;
    80002170:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002174:	000b0c63          	beqz	s6,8000218c <wait+0x6a>
    80002178:	4691                	li	a3,4
    8000217a:	02c48613          	addi	a2,s1,44
    8000217e:	85da                	mv	a1,s6
    80002180:	05893503          	ld	a0,88(s2)
    80002184:	ca4ff0ef          	jal	ra,80001628 <copyout>
    80002188:	00054f63          	bltz	a0,800021a6 <wait+0x84>
          freeproc(pp);
    8000218c:	8526                	mv	a0,s1
    8000218e:	91dff0ef          	jal	ra,80001aaa <freeproc>
          release(&pp->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	b47fe0ef          	jal	ra,80000cda <release>
          release(&wait_lock);
    80002198:	0000e517          	auipc	a0,0xe
    8000219c:	95850513          	addi	a0,a0,-1704 # 8000faf0 <wait_lock>
    800021a0:	b3bfe0ef          	jal	ra,80000cda <release>
          return pid;
    800021a4:	a891                	j	800021f8 <wait+0xd6>
            release(&pp->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	b33fe0ef          	jal	ra,80000cda <release>
            release(&wait_lock);
    800021ac:	0000e517          	auipc	a0,0xe
    800021b0:	94450513          	addi	a0,a0,-1724 # 8000faf0 <wait_lock>
    800021b4:	b27fe0ef          	jal	ra,80000cda <release>
            return -1;
    800021b8:	59fd                	li	s3,-1
    800021ba:	a83d                	j	800021f8 <wait+0xd6>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800021bc:	17048493          	addi	s1,s1,368
    800021c0:	03348063          	beq	s1,s3,800021e0 <wait+0xbe>
      if(pp->parent == p){
    800021c4:	7c9c                	ld	a5,56(s1)
    800021c6:	ff279be3          	bne	a5,s2,800021bc <wait+0x9a>
        acquire(&pp->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	a77fe0ef          	jal	ra,80000c42 <acquire>
        if(pp->state == ZOMBIE){
    800021d0:	4c9c                	lw	a5,24(s1)
    800021d2:	f9478fe3          	beq	a5,s4,80002170 <wait+0x4e>
        release(&pp->lock);
    800021d6:	8526                	mv	a0,s1
    800021d8:	b03fe0ef          	jal	ra,80000cda <release>
        havekids = 1;
    800021dc:	8756                	mv	a4,s5
    800021de:	bff9                	j	800021bc <wait+0x9a>
    if(!havekids || killed(p)){
    800021e0:	c709                	beqz	a4,800021ea <wait+0xc8>
    800021e2:	854a                	mv	a0,s2
    800021e4:	f15ff0ef          	jal	ra,800020f8 <killed>
    800021e8:	c50d                	beqz	a0,80002212 <wait+0xf0>
      release(&wait_lock);
    800021ea:	0000e517          	auipc	a0,0xe
    800021ee:	90650513          	addi	a0,a0,-1786 # 8000faf0 <wait_lock>
    800021f2:	ae9fe0ef          	jal	ra,80000cda <release>
      return -1;
    800021f6:	59fd                	li	s3,-1
}
    800021f8:	854e                	mv	a0,s3
    800021fa:	60a6                	ld	ra,72(sp)
    800021fc:	6406                	ld	s0,64(sp)
    800021fe:	74e2                	ld	s1,56(sp)
    80002200:	7942                	ld	s2,48(sp)
    80002202:	79a2                	ld	s3,40(sp)
    80002204:	7a02                	ld	s4,32(sp)
    80002206:	6ae2                	ld	s5,24(sp)
    80002208:	6b42                	ld	s6,16(sp)
    8000220a:	6ba2                	ld	s7,8(sp)
    8000220c:	6c02                	ld	s8,0(sp)
    8000220e:	6161                	addi	sp,sp,80
    80002210:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002212:	85e2                	mv	a1,s8
    80002214:	854a                	mv	a0,s2
    80002216:	cabff0ef          	jal	ra,80001ec0 <sleep>
    havekids = 0;
    8000221a:	b7a9                	j	80002164 <wait+0x42>

000000008000221c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000221c:	7179                	addi	sp,sp,-48
    8000221e:	f406                	sd	ra,40(sp)
    80002220:	f022                	sd	s0,32(sp)
    80002222:	ec26                	sd	s1,24(sp)
    80002224:	e84a                	sd	s2,16(sp)
    80002226:	e44e                	sd	s3,8(sp)
    80002228:	e052                	sd	s4,0(sp)
    8000222a:	1800                	addi	s0,sp,48
    8000222c:	84aa                	mv	s1,a0
    8000222e:	892e                	mv	s2,a1
    80002230:	89b2                	mv	s3,a2
    80002232:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002234:	ea6ff0ef          	jal	ra,800018da <myproc>
  if(user_dst){
    80002238:	cc99                	beqz	s1,80002256 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    8000223a:	86d2                	mv	a3,s4
    8000223c:	864e                	mv	a2,s3
    8000223e:	85ca                	mv	a1,s2
    80002240:	6d28                	ld	a0,88(a0)
    80002242:	be6ff0ef          	jal	ra,80001628 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002246:	70a2                	ld	ra,40(sp)
    80002248:	7402                	ld	s0,32(sp)
    8000224a:	64e2                	ld	s1,24(sp)
    8000224c:	6942                	ld	s2,16(sp)
    8000224e:	69a2                	ld	s3,8(sp)
    80002250:	6a02                	ld	s4,0(sp)
    80002252:	6145                	addi	sp,sp,48
    80002254:	8082                	ret
    memmove((char *)dst, src, len);
    80002256:	000a061b          	sext.w	a2,s4
    8000225a:	85ce                	mv	a1,s3
    8000225c:	854a                	mv	a0,s2
    8000225e:	b15fe0ef          	jal	ra,80000d72 <memmove>
    return 0;
    80002262:	8526                	mv	a0,s1
    80002264:	b7cd                	j	80002246 <either_copyout+0x2a>

0000000080002266 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002266:	7179                	addi	sp,sp,-48
    80002268:	f406                	sd	ra,40(sp)
    8000226a:	f022                	sd	s0,32(sp)
    8000226c:	ec26                	sd	s1,24(sp)
    8000226e:	e84a                	sd	s2,16(sp)
    80002270:	e44e                	sd	s3,8(sp)
    80002272:	e052                	sd	s4,0(sp)
    80002274:	1800                	addi	s0,sp,48
    80002276:	892a                	mv	s2,a0
    80002278:	84ae                	mv	s1,a1
    8000227a:	89b2                	mv	s3,a2
    8000227c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000227e:	e5cff0ef          	jal	ra,800018da <myproc>
  if(user_src){
    80002282:	cc99                	beqz	s1,800022a0 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    80002284:	86d2                	mv	a3,s4
    80002286:	864e                	mv	a2,s3
    80002288:	85ca                	mv	a1,s2
    8000228a:	6d28                	ld	a0,88(a0)
    8000228c:	c62ff0ef          	jal	ra,800016ee <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002290:	70a2                	ld	ra,40(sp)
    80002292:	7402                	ld	s0,32(sp)
    80002294:	64e2                	ld	s1,24(sp)
    80002296:	6942                	ld	s2,16(sp)
    80002298:	69a2                	ld	s3,8(sp)
    8000229a:	6a02                	ld	s4,0(sp)
    8000229c:	6145                	addi	sp,sp,48
    8000229e:	8082                	ret
    memmove(dst, (char*)src, len);
    800022a0:	000a061b          	sext.w	a2,s4
    800022a4:	85ce                	mv	a1,s3
    800022a6:	854a                	mv	a0,s2
    800022a8:	acbfe0ef          	jal	ra,80000d72 <memmove>
    return 0;
    800022ac:	8526                	mv	a0,s1
    800022ae:	b7cd                	j	80002290 <either_copyin+0x2a>

00000000800022b0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800022b0:	715d                	addi	sp,sp,-80
    800022b2:	e486                	sd	ra,72(sp)
    800022b4:	e0a2                	sd	s0,64(sp)
    800022b6:	fc26                	sd	s1,56(sp)
    800022b8:	f84a                	sd	s2,48(sp)
    800022ba:	f44e                	sd	s3,40(sp)
    800022bc:	f052                	sd	s4,32(sp)
    800022be:	ec56                	sd	s5,24(sp)
    800022c0:	e85a                	sd	s6,16(sp)
    800022c2:	e45e                	sd	s7,8(sp)
    800022c4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800022c6:	00005517          	auipc	a0,0x5
    800022ca:	e1250513          	addi	a0,a0,-494 # 800070d8 <digits+0x88>
    800022ce:	9d4fe0ef          	jal	ra,800004a2 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800022d2:	0000e497          	auipc	s1,0xe
    800022d6:	d9648493          	addi	s1,s1,-618 # 80010068 <proc+0x160>
    800022da:	00014917          	auipc	s2,0x14
    800022de:	98e90913          	addi	s2,s2,-1650 # 80015c68 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022e2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800022e4:	00005997          	auipc	s3,0x5
    800022e8:	f4c98993          	addi	s3,s3,-180 # 80007230 <digits+0x1e0>
    printf("%d %s %s", p->pid, state, p->name);
    800022ec:	00005a97          	auipc	s5,0x5
    800022f0:	f4ca8a93          	addi	s5,s5,-180 # 80007238 <digits+0x1e8>
    printf("\n");
    800022f4:	00005a17          	auipc	s4,0x5
    800022f8:	de4a0a13          	addi	s4,s4,-540 # 800070d8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022fc:	00005b97          	auipc	s7,0x5
    80002300:	f7cb8b93          	addi	s7,s7,-132 # 80007278 <states.0>
    80002304:	a829                	j	8000231e <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    80002306:	ed06a583          	lw	a1,-304(a3)
    8000230a:	8556                	mv	a0,s5
    8000230c:	996fe0ef          	jal	ra,800004a2 <printf>
    printf("\n");
    80002310:	8552                	mv	a0,s4
    80002312:	990fe0ef          	jal	ra,800004a2 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002316:	17048493          	addi	s1,s1,368
    8000231a:	03248263          	beq	s1,s2,8000233e <procdump+0x8e>
    if(p->state == UNUSED)
    8000231e:	86a6                	mv	a3,s1
    80002320:	eb84a783          	lw	a5,-328(s1)
    80002324:	dbed                	beqz	a5,80002316 <procdump+0x66>
      state = "???";
    80002326:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002328:	fcfb6fe3          	bltu	s6,a5,80002306 <procdump+0x56>
    8000232c:	02079713          	slli	a4,a5,0x20
    80002330:	01d75793          	srli	a5,a4,0x1d
    80002334:	97de                	add	a5,a5,s7
    80002336:	6390                	ld	a2,0(a5)
    80002338:	f679                	bnez	a2,80002306 <procdump+0x56>
      state = "???";
    8000233a:	864e                	mv	a2,s3
    8000233c:	b7e9                	j	80002306 <procdump+0x56>
  }
}
    8000233e:	60a6                	ld	ra,72(sp)
    80002340:	6406                	ld	s0,64(sp)
    80002342:	74e2                	ld	s1,56(sp)
    80002344:	7942                	ld	s2,48(sp)
    80002346:	79a2                	ld	s3,40(sp)
    80002348:	7a02                	ld	s4,32(sp)
    8000234a:	6ae2                	ld	s5,24(sp)
    8000234c:	6b42                	ld	s6,16(sp)
    8000234e:	6ba2                	ld	s7,8(sp)
    80002350:	6161                	addi	sp,sp,80
    80002352:	8082                	ret

0000000080002354 <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    80002354:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    80002358:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    8000235c:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    8000235e:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    80002360:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    80002364:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    80002368:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    8000236c:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    80002370:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    80002374:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    80002378:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    8000237c:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    80002380:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    80002384:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    80002388:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    8000238c:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    80002390:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    80002392:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    80002394:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    80002398:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    8000239c:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    800023a0:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    800023a4:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    800023a8:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    800023ac:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    800023b0:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    800023b4:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    800023b8:	0685bd83          	ld	s11,104(a1)
        
        ret
    800023bc:	8082                	ret

00000000800023be <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800023be:	1141                	addi	sp,sp,-16
    800023c0:	e406                	sd	ra,8(sp)
    800023c2:	e022                	sd	s0,0(sp)
    800023c4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800023c6:	00005597          	auipc	a1,0x5
    800023ca:	ee258593          	addi	a1,a1,-286 # 800072a8 <states.0+0x30>
    800023ce:	00013517          	auipc	a0,0x13
    800023d2:	73a50513          	addi	a0,a0,1850 # 80015b08 <tickslock>
    800023d6:	fecfe0ef          	jal	ra,80000bc2 <initlock>
}
    800023da:	60a2                	ld	ra,8(sp)
    800023dc:	6402                	ld	s0,0(sp)
    800023de:	0141                	addi	sp,sp,16
    800023e0:	8082                	ret

00000000800023e2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800023e2:	1141                	addi	sp,sp,-16
    800023e4:	e422                	sd	s0,8(sp)
    800023e6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800023e8:	00003797          	auipc	a5,0x3
    800023ec:	dc878793          	addi	a5,a5,-568 # 800051b0 <kernelvec>
    800023f0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800023f4:	6422                	ld	s0,8(sp)
    800023f6:	0141                	addi	sp,sp,16
    800023f8:	8082                	ret

00000000800023fa <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    800023fa:	1141                	addi	sp,sp,-16
    800023fc:	e406                	sd	ra,8(sp)
    800023fe:	e022                	sd	s0,0(sp)
    80002400:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002402:	cd8ff0ef          	jal	ra,800018da <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002406:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000240a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000240c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002410:	04000737          	lui	a4,0x4000
    80002414:	00004797          	auipc	a5,0x4
    80002418:	bec78793          	addi	a5,a5,-1044 # 80006000 <_trampoline>
    8000241c:	00004697          	auipc	a3,0x4
    80002420:	be468693          	addi	a3,a3,-1052 # 80006000 <_trampoline>
    80002424:	8f95                	sub	a5,a5,a3
    80002426:	177d                	addi	a4,a4,-1
    80002428:	0732                	slli	a4,a4,0xc
    8000242a:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000242c:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002430:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002432:	18002773          	csrr	a4,satp
    80002436:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002438:	7138                	ld	a4,96(a0)
    8000243a:	653c                	ld	a5,72(a0)
    8000243c:	6685                	lui	a3,0x1
    8000243e:	97b6                	add	a5,a5,a3
    80002440:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002442:	713c                	ld	a5,96(a0)
    80002444:	00000717          	auipc	a4,0x0
    80002448:	0f470713          	addi	a4,a4,244 # 80002538 <usertrap>
    8000244c:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000244e:	713c                	ld	a5,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002450:	8712                	mv	a4,tp
    80002452:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002454:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002458:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000245c:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002460:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002464:	713c                	ld	a5,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002466:	6f9c                	ld	a5,24(a5)
    80002468:	14179073          	csrw	sepc,a5
}
    8000246c:	60a2                	ld	ra,8(sp)
    8000246e:	6402                	ld	s0,0(sp)
    80002470:	0141                	addi	sp,sp,16
    80002472:	8082                	ret

0000000080002474 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002474:	1101                	addi	sp,sp,-32
    80002476:	ec06                	sd	ra,24(sp)
    80002478:	e822                	sd	s0,16(sp)
    8000247a:	e426                	sd	s1,8(sp)
    8000247c:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    8000247e:	c30ff0ef          	jal	ra,800018ae <cpuid>
    80002482:	cd19                	beqz	a0,800024a0 <clockintr+0x2c>
  asm volatile("csrr %0, time" : "=r" (x) );
    80002484:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    80002488:	000f4737          	lui	a4,0xf4
    8000248c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80002490:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80002492:	14d79073          	csrw	0x14d,a5
}
    80002496:	60e2                	ld	ra,24(sp)
    80002498:	6442                	ld	s0,16(sp)
    8000249a:	64a2                	ld	s1,8(sp)
    8000249c:	6105                	addi	sp,sp,32
    8000249e:	8082                	ret
    acquire(&tickslock);
    800024a0:	00013497          	auipc	s1,0x13
    800024a4:	66848493          	addi	s1,s1,1640 # 80015b08 <tickslock>
    800024a8:	8526                	mv	a0,s1
    800024aa:	f98fe0ef          	jal	ra,80000c42 <acquire>
    ticks++;
    800024ae:	00005517          	auipc	a0,0x5
    800024b2:	50250513          	addi	a0,a0,1282 # 800079b0 <ticks>
    800024b6:	411c                	lw	a5,0(a0)
    800024b8:	2785                	addiw	a5,a5,1
    800024ba:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    800024bc:	a51ff0ef          	jal	ra,80001f0c <wakeup>
    release(&tickslock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	819fe0ef          	jal	ra,80000cda <release>
    800024c6:	bf7d                	j	80002484 <clockintr+0x10>

00000000800024c8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800024c8:	1101                	addi	sp,sp,-32
    800024ca:	ec06                	sd	ra,24(sp)
    800024cc:	e822                	sd	s0,16(sp)
    800024ce:	e426                	sd	s1,8(sp)
    800024d0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800024d2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    800024d6:	57fd                	li	a5,-1
    800024d8:	17fe                	slli	a5,a5,0x3f
    800024da:	07a5                	addi	a5,a5,9
    800024dc:	00f70d63          	beq	a4,a5,800024f6 <devintr+0x2e>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800024e0:	57fd                	li	a5,-1
    800024e2:	17fe                	slli	a5,a5,0x3f
    800024e4:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800024e6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800024e8:	04f70463          	beq	a4,a5,80002530 <devintr+0x68>
  }
}
    800024ec:	60e2                	ld	ra,24(sp)
    800024ee:	6442                	ld	s0,16(sp)
    800024f0:	64a2                	ld	s1,8(sp)
    800024f2:	6105                	addi	sp,sp,32
    800024f4:	8082                	ret
    int irq = plic_claim();
    800024f6:	563020ef          	jal	ra,80005258 <plic_claim>
    800024fa:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800024fc:	47a9                	li	a5,10
    800024fe:	02f50363          	beq	a0,a5,80002524 <devintr+0x5c>
    } else if(irq == VIRTIO0_IRQ){
    80002502:	4785                	li	a5,1
    80002504:	02f50363          	beq	a0,a5,8000252a <devintr+0x62>
    return 1;
    80002508:	4505                	li	a0,1
    } else if(irq){
    8000250a:	d0ed                	beqz	s1,800024ec <devintr+0x24>
      printf("unexpected interrupt irq=%d\n", irq);
    8000250c:	85a6                	mv	a1,s1
    8000250e:	00005517          	auipc	a0,0x5
    80002512:	da250513          	addi	a0,a0,-606 # 800072b0 <states.0+0x38>
    80002516:	f8dfd0ef          	jal	ra,800004a2 <printf>
      plic_complete(irq);
    8000251a:	8526                	mv	a0,s1
    8000251c:	55d020ef          	jal	ra,80005278 <plic_complete>
    return 1;
    80002520:	4505                	li	a0,1
    80002522:	b7e9                	j	800024ec <devintr+0x24>
      uartintr();
    80002524:	d0efe0ef          	jal	ra,80000a32 <uartintr>
    80002528:	bfcd                	j	8000251a <devintr+0x52>
      virtio_disk_intr();
    8000252a:	1be030ef          	jal	ra,800056e8 <virtio_disk_intr>
    8000252e:	b7f5                	j	8000251a <devintr+0x52>
    clockintr();
    80002530:	f45ff0ef          	jal	ra,80002474 <clockintr>
    return 2;
    80002534:	4509                	li	a0,2
    80002536:	bf5d                	j	800024ec <devintr+0x24>

0000000080002538 <usertrap>:
{
    80002538:	1101                	addi	sp,sp,-32
    8000253a:	ec06                	sd	ra,24(sp)
    8000253c:	e822                	sd	s0,16(sp)
    8000253e:	e426                	sd	s1,8(sp)
    80002540:	e04a                	sd	s2,0(sp)
    80002542:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002544:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002548:	1007f793          	andi	a5,a5,256
    8000254c:	eba5                	bnez	a5,800025bc <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000254e:	00003797          	auipc	a5,0x3
    80002552:	c6278793          	addi	a5,a5,-926 # 800051b0 <kernelvec>
    80002556:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000255a:	b80ff0ef          	jal	ra,800018da <myproc>
    8000255e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002560:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002562:	14102773          	csrr	a4,sepc
    80002566:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002568:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000256c:	47a1                	li	a5,8
    8000256e:	04f70d63          	beq	a4,a5,800025c8 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    80002572:	f57ff0ef          	jal	ra,800024c8 <devintr>
    80002576:	892a                	mv	s2,a0
    80002578:	e945                	bnez	a0,80002628 <usertrap+0xf0>
    8000257a:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    8000257e:	47bd                	li	a5,15
    80002580:	08f70863          	beq	a4,a5,80002610 <usertrap+0xd8>
    80002584:	14202773          	csrr	a4,scause
    80002588:	47b5                	li	a5,13
    8000258a:	08f70363          	beq	a4,a5,80002610 <usertrap+0xd8>
    8000258e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    80002592:	5890                	lw	a2,48(s1)
    80002594:	00005517          	auipc	a0,0x5
    80002598:	d5c50513          	addi	a0,a0,-676 # 800072f0 <states.0+0x78>
    8000259c:	f07fd0ef          	jal	ra,800004a2 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800025a0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800025a4:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    800025a8:	00005517          	auipc	a0,0x5
    800025ac:	d7850513          	addi	a0,a0,-648 # 80007320 <states.0+0xa8>
    800025b0:	ef3fd0ef          	jal	ra,800004a2 <printf>
    setkilled(p);
    800025b4:	8526                	mv	a0,s1
    800025b6:	b1fff0ef          	jal	ra,800020d4 <setkilled>
    800025ba:	a035                	j	800025e6 <usertrap+0xae>
    panic("usertrap: not from user mode");
    800025bc:	00005517          	auipc	a0,0x5
    800025c0:	d1450513          	addi	a0,a0,-748 # 800072d0 <states.0+0x58>
    800025c4:	a18fe0ef          	jal	ra,800007dc <panic>
    if(killed(p))
    800025c8:	b31ff0ef          	jal	ra,800020f8 <killed>
    800025cc:	ed15                	bnez	a0,80002608 <usertrap+0xd0>
    p->trapframe->epc += 4;
    800025ce:	70b8                	ld	a4,96(s1)
    800025d0:	6f1c                	ld	a5,24(a4)
    800025d2:	0791                	addi	a5,a5,4
    800025d4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025da:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025de:	10079073          	csrw	sstatus,a5
    syscall();
    800025e2:	246000ef          	jal	ra,80002828 <syscall>
  if(killed(p))
    800025e6:	8526                	mv	a0,s1
    800025e8:	b11ff0ef          	jal	ra,800020f8 <killed>
    800025ec:	e139                	bnez	a0,80002632 <usertrap+0xfa>
  prepare_return();
    800025ee:	e0dff0ef          	jal	ra,800023fa <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800025f2:	6ca8                	ld	a0,88(s1)
    800025f4:	8131                	srli	a0,a0,0xc
    800025f6:	57fd                	li	a5,-1
    800025f8:	17fe                	slli	a5,a5,0x3f
    800025fa:	8d5d                	or	a0,a0,a5
}
    800025fc:	60e2                	ld	ra,24(sp)
    800025fe:	6442                	ld	s0,16(sp)
    80002600:	64a2                	ld	s1,8(sp)
    80002602:	6902                	ld	s2,0(sp)
    80002604:	6105                	addi	sp,sp,32
    80002606:	8082                	ret
      exit(-1);
    80002608:	557d                	li	a0,-1
    8000260a:	9c3ff0ef          	jal	ra,80001fcc <exit>
    8000260e:	b7c1                	j	800025ce <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002610:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002614:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    80002618:	164d                	addi	a2,a2,-13
    8000261a:	00163613          	seqz	a2,a2
    8000261e:	6ca8                	ld	a0,88(s1)
    80002620:	f97fe0ef          	jal	ra,800015b6 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002624:	f169                	bnez	a0,800025e6 <usertrap+0xae>
    80002626:	b7a5                	j	8000258e <usertrap+0x56>
  if(killed(p))
    80002628:	8526                	mv	a0,s1
    8000262a:	acfff0ef          	jal	ra,800020f8 <killed>
    8000262e:	c511                	beqz	a0,8000263a <usertrap+0x102>
    80002630:	a011                	j	80002634 <usertrap+0xfc>
    80002632:	4901                	li	s2,0
    exit(-1);
    80002634:	557d                	li	a0,-1
    80002636:	997ff0ef          	jal	ra,80001fcc <exit>
  if(which_dev == 2)
    8000263a:	4789                	li	a5,2
    8000263c:	faf919e3          	bne	s2,a5,800025ee <usertrap+0xb6>
    yield();
    80002640:	855ff0ef          	jal	ra,80001e94 <yield>
    80002644:	b76d                	j	800025ee <usertrap+0xb6>

0000000080002646 <kerneltrap>:
{
    80002646:	7179                	addi	sp,sp,-48
    80002648:	f406                	sd	ra,40(sp)
    8000264a:	f022                	sd	s0,32(sp)
    8000264c:	ec26                	sd	s1,24(sp)
    8000264e:	e84a                	sd	s2,16(sp)
    80002650:	e44e                	sd	s3,8(sp)
    80002652:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002654:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002658:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000265c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002660:	1004f793          	andi	a5,s1,256
    80002664:	c795                	beqz	a5,80002690 <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002666:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000266a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000266c:	eb85                	bnez	a5,8000269c <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    8000266e:	e5bff0ef          	jal	ra,800024c8 <devintr>
    80002672:	c91d                	beqz	a0,800026a8 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    80002674:	4789                	li	a5,2
    80002676:	04f50a63          	beq	a0,a5,800026ca <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000267a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000267e:	10049073          	csrw	sstatus,s1
}
    80002682:	70a2                	ld	ra,40(sp)
    80002684:	7402                	ld	s0,32(sp)
    80002686:	64e2                	ld	s1,24(sp)
    80002688:	6942                	ld	s2,16(sp)
    8000268a:	69a2                	ld	s3,8(sp)
    8000268c:	6145                	addi	sp,sp,48
    8000268e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002690:	00005517          	auipc	a0,0x5
    80002694:	cb850513          	addi	a0,a0,-840 # 80007348 <states.0+0xd0>
    80002698:	944fe0ef          	jal	ra,800007dc <panic>
    panic("kerneltrap: interrupts enabled");
    8000269c:	00005517          	auipc	a0,0x5
    800026a0:	cd450513          	addi	a0,a0,-812 # 80007370 <states.0+0xf8>
    800026a4:	938fe0ef          	jal	ra,800007dc <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800026a8:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800026ac:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    800026b0:	85ce                	mv	a1,s3
    800026b2:	00005517          	auipc	a0,0x5
    800026b6:	cde50513          	addi	a0,a0,-802 # 80007390 <states.0+0x118>
    800026ba:	de9fd0ef          	jal	ra,800004a2 <printf>
    panic("kerneltrap");
    800026be:	00005517          	auipc	a0,0x5
    800026c2:	cfa50513          	addi	a0,a0,-774 # 800073b8 <states.0+0x140>
    800026c6:	916fe0ef          	jal	ra,800007dc <panic>
  if(which_dev == 2 && myproc() != 0)
    800026ca:	a10ff0ef          	jal	ra,800018da <myproc>
    800026ce:	d555                	beqz	a0,8000267a <kerneltrap+0x34>
    yield();
    800026d0:	fc4ff0ef          	jal	ra,80001e94 <yield>
    800026d4:	b75d                	j	8000267a <kerneltrap+0x34>

00000000800026d6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800026d6:	1101                	addi	sp,sp,-32
    800026d8:	ec06                	sd	ra,24(sp)
    800026da:	e822                	sd	s0,16(sp)
    800026dc:	e426                	sd	s1,8(sp)
    800026de:	1000                	addi	s0,sp,32
    800026e0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800026e2:	9f8ff0ef          	jal	ra,800018da <myproc>
  switch (n) {
    800026e6:	4795                	li	a5,5
    800026e8:	0497e163          	bltu	a5,s1,8000272a <argraw+0x54>
    800026ec:	048a                	slli	s1,s1,0x2
    800026ee:	00005717          	auipc	a4,0x5
    800026f2:	dc270713          	addi	a4,a4,-574 # 800074b0 <states.0+0x238>
    800026f6:	94ba                	add	s1,s1,a4
    800026f8:	409c                	lw	a5,0(s1)
    800026fa:	97ba                	add	a5,a5,a4
    800026fc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800026fe:	713c                	ld	a5,96(a0)
    80002700:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002702:	60e2                	ld	ra,24(sp)
    80002704:	6442                	ld	s0,16(sp)
    80002706:	64a2                	ld	s1,8(sp)
    80002708:	6105                	addi	sp,sp,32
    8000270a:	8082                	ret
    return p->trapframe->a1;
    8000270c:	713c                	ld	a5,96(a0)
    8000270e:	7fa8                	ld	a0,120(a5)
    80002710:	bfcd                	j	80002702 <argraw+0x2c>
    return p->trapframe->a2;
    80002712:	713c                	ld	a5,96(a0)
    80002714:	63c8                	ld	a0,128(a5)
    80002716:	b7f5                	j	80002702 <argraw+0x2c>
    return p->trapframe->a3;
    80002718:	713c                	ld	a5,96(a0)
    8000271a:	67c8                	ld	a0,136(a5)
    8000271c:	b7dd                	j	80002702 <argraw+0x2c>
    return p->trapframe->a4;
    8000271e:	713c                	ld	a5,96(a0)
    80002720:	6bc8                	ld	a0,144(a5)
    80002722:	b7c5                	j	80002702 <argraw+0x2c>
    return p->trapframe->a5;
    80002724:	713c                	ld	a5,96(a0)
    80002726:	6fc8                	ld	a0,152(a5)
    80002728:	bfe9                	j	80002702 <argraw+0x2c>
  panic("argraw");
    8000272a:	00005517          	auipc	a0,0x5
    8000272e:	c9e50513          	addi	a0,a0,-866 # 800073c8 <states.0+0x150>
    80002732:	8aafe0ef          	jal	ra,800007dc <panic>

0000000080002736 <fetchaddr>:
{
    80002736:	1101                	addi	sp,sp,-32
    80002738:	ec06                	sd	ra,24(sp)
    8000273a:	e822                	sd	s0,16(sp)
    8000273c:	e426                	sd	s1,8(sp)
    8000273e:	e04a                	sd	s2,0(sp)
    80002740:	1000                	addi	s0,sp,32
    80002742:	84aa                	mv	s1,a0
    80002744:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002746:	994ff0ef          	jal	ra,800018da <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000274a:	693c                	ld	a5,80(a0)
    8000274c:	02f4f663          	bgeu	s1,a5,80002778 <fetchaddr+0x42>
    80002750:	00848713          	addi	a4,s1,8
    80002754:	02e7e463          	bltu	a5,a4,8000277c <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002758:	46a1                	li	a3,8
    8000275a:	8626                	mv	a2,s1
    8000275c:	85ca                	mv	a1,s2
    8000275e:	6d28                	ld	a0,88(a0)
    80002760:	f8ffe0ef          	jal	ra,800016ee <copyin>
    80002764:	00a03533          	snez	a0,a0
    80002768:	40a00533          	neg	a0,a0
}
    8000276c:	60e2                	ld	ra,24(sp)
    8000276e:	6442                	ld	s0,16(sp)
    80002770:	64a2                	ld	s1,8(sp)
    80002772:	6902                	ld	s2,0(sp)
    80002774:	6105                	addi	sp,sp,32
    80002776:	8082                	ret
    return -1;
    80002778:	557d                	li	a0,-1
    8000277a:	bfcd                	j	8000276c <fetchaddr+0x36>
    8000277c:	557d                	li	a0,-1
    8000277e:	b7fd                	j	8000276c <fetchaddr+0x36>

0000000080002780 <fetchstr>:
{
    80002780:	7179                	addi	sp,sp,-48
    80002782:	f406                	sd	ra,40(sp)
    80002784:	f022                	sd	s0,32(sp)
    80002786:	ec26                	sd	s1,24(sp)
    80002788:	e84a                	sd	s2,16(sp)
    8000278a:	e44e                	sd	s3,8(sp)
    8000278c:	1800                	addi	s0,sp,48
    8000278e:	892a                	mv	s2,a0
    80002790:	84ae                	mv	s1,a1
    80002792:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002794:	946ff0ef          	jal	ra,800018da <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002798:	86ce                	mv	a3,s3
    8000279a:	864a                	mv	a2,s2
    8000279c:	85a6                	mv	a1,s1
    8000279e:	6d28                	ld	a0,88(a0)
    800027a0:	d47fe0ef          	jal	ra,800014e6 <copyinstr>
    800027a4:	00054c63          	bltz	a0,800027bc <fetchstr+0x3c>
  return strlen(buf);
    800027a8:	8526                	mv	a0,s1
    800027aa:	ee4fe0ef          	jal	ra,80000e8e <strlen>
}
    800027ae:	70a2                	ld	ra,40(sp)
    800027b0:	7402                	ld	s0,32(sp)
    800027b2:	64e2                	ld	s1,24(sp)
    800027b4:	6942                	ld	s2,16(sp)
    800027b6:	69a2                	ld	s3,8(sp)
    800027b8:	6145                	addi	sp,sp,48
    800027ba:	8082                	ret
    return -1;
    800027bc:	557d                	li	a0,-1
    800027be:	bfc5                	j	800027ae <fetchstr+0x2e>

00000000800027c0 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800027c0:	1101                	addi	sp,sp,-32
    800027c2:	ec06                	sd	ra,24(sp)
    800027c4:	e822                	sd	s0,16(sp)
    800027c6:	e426                	sd	s1,8(sp)
    800027c8:	1000                	addi	s0,sp,32
    800027ca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800027cc:	f0bff0ef          	jal	ra,800026d6 <argraw>
    800027d0:	c088                	sw	a0,0(s1)
}
    800027d2:	60e2                	ld	ra,24(sp)
    800027d4:	6442                	ld	s0,16(sp)
    800027d6:	64a2                	ld	s1,8(sp)
    800027d8:	6105                	addi	sp,sp,32
    800027da:	8082                	ret

00000000800027dc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800027dc:	1101                	addi	sp,sp,-32
    800027de:	ec06                	sd	ra,24(sp)
    800027e0:	e822                	sd	s0,16(sp)
    800027e2:	e426                	sd	s1,8(sp)
    800027e4:	1000                	addi	s0,sp,32
    800027e6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800027e8:	eefff0ef          	jal	ra,800026d6 <argraw>
    800027ec:	e088                	sd	a0,0(s1)
}
    800027ee:	60e2                	ld	ra,24(sp)
    800027f0:	6442                	ld	s0,16(sp)
    800027f2:	64a2                	ld	s1,8(sp)
    800027f4:	6105                	addi	sp,sp,32
    800027f6:	8082                	ret

00000000800027f8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800027f8:	7179                	addi	sp,sp,-48
    800027fa:	f406                	sd	ra,40(sp)
    800027fc:	f022                	sd	s0,32(sp)
    800027fe:	ec26                	sd	s1,24(sp)
    80002800:	e84a                	sd	s2,16(sp)
    80002802:	1800                	addi	s0,sp,48
    80002804:	84ae                	mv	s1,a1
    80002806:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002808:	fd840593          	addi	a1,s0,-40
    8000280c:	fd1ff0ef          	jal	ra,800027dc <argaddr>
  return fetchstr(addr, buf, max);
    80002810:	864a                	mv	a2,s2
    80002812:	85a6                	mv	a1,s1
    80002814:	fd843503          	ld	a0,-40(s0)
    80002818:	f69ff0ef          	jal	ra,80002780 <fetchstr>
}
    8000281c:	70a2                	ld	ra,40(sp)
    8000281e:	7402                	ld	s0,32(sp)
    80002820:	64e2                	ld	s1,24(sp)
    80002822:	6942                	ld	s2,16(sp)
    80002824:	6145                	addi	sp,sp,48
    80002826:	8082                	ret

0000000080002828 <syscall>:
};


void
syscall(void)
{
    80002828:	1101                	addi	sp,sp,-32
    8000282a:	ec06                	sd	ra,24(sp)
    8000282c:	e822                	sd	s0,16(sp)
    8000282e:	e426                	sd	s1,8(sp)
    80002830:	e04a                	sd	s2,0(sp)
    80002832:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002834:	8a6ff0ef          	jal	ra,800018da <myproc>
    80002838:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000283a:	713c                	ld	a5,96(a0)
    8000283c:	77dc                	ld	a5,168(a5)
    8000283e:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002842:	37fd                	addiw	a5,a5,-1
    80002844:	4755                	li	a4,21
    80002846:	04f76c63          	bltu	a4,a5,8000289e <syscall+0x76>
    8000284a:	00391713          	slli	a4,s2,0x3
    8000284e:	00005797          	auipc	a5,0x5
    80002852:	c7a78793          	addi	a5,a5,-902 # 800074c8 <syscalls>
    80002856:	97ba                	add	a5,a5,a4
    80002858:	639c                	ld	a5,0(a5)
    8000285a:	c3b1                	beqz	a5,8000289e <syscall+0x76>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    uint64 ret = syscalls[num]();    // run the actual syscall
    8000285c:	9782                	jalr	a5
    p->trapframe->a0 = ret;
    8000285e:	70bc                	ld	a5,96(s1)
    80002860:	fba8                	sd	a0,112(a5)
    if (p->tracemask & (1U << num)) {
    80002862:	4785                	li	a5,1
    80002864:	0127973b          	sllw	a4,a5,s2
    80002868:	40bc                	lw	a5,64(s1)
    8000286a:	8ff9                	and	a5,a5,a4
    8000286c:	2781                	sext.w	a5,a5
    8000286e:	c7a9                	beqz	a5,800028b8 <syscall+0x90>
      char *name = (num < NELEM(syscallnames) && syscallnames[num]) ?
    80002870:	090e                	slli	s2,s2,0x3
    80002872:	00005797          	auipc	a5,0x5
    80002876:	c5678793          	addi	a5,a5,-938 # 800074c8 <syscalls>
    8000287a:	993e                	add	s2,s2,a5
    8000287c:	0b893603          	ld	a2,184(s2)
    80002880:	ca11                	beqz	a2,80002894 <syscall+0x6c>
                    syscallnames[num] : "?";
      //The format is: "<pid>: syscall <name> -> <return value>"
      printf("%d: syscall %s -> %lld\n", p->pid, name, (long long)ret);
    80002882:	86aa                	mv	a3,a0
    80002884:	588c                	lw	a1,48(s1)
    80002886:	00005517          	auipc	a0,0x5
    8000288a:	b5250513          	addi	a0,a0,-1198 # 800073d8 <states.0+0x160>
    8000288e:	c15fd0ef          	jal	ra,800004a2 <printf>
    80002892:	a01d                	j	800028b8 <syscall+0x90>
                    syscallnames[num] : "?";
    80002894:	00005617          	auipc	a2,0x5
    80002898:	b3c60613          	addi	a2,a2,-1220 # 800073d0 <states.0+0x158>
    8000289c:	b7dd                	j	80002882 <syscall+0x5a>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000289e:	86ca                	mv	a3,s2
    800028a0:	16048613          	addi	a2,s1,352
    800028a4:	588c                	lw	a1,48(s1)
    800028a6:	00005517          	auipc	a0,0x5
    800028aa:	b4a50513          	addi	a0,a0,-1206 # 800073f0 <states.0+0x178>
    800028ae:	bf5fd0ef          	jal	ra,800004a2 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800028b2:	70bc                	ld	a5,96(s1)
    800028b4:	577d                	li	a4,-1
    800028b6:	fbb8                	sd	a4,112(a5)
  }
}
    800028b8:	60e2                	ld	ra,24(sp)
    800028ba:	6442                	ld	s0,16(sp)
    800028bc:	64a2                	ld	s1,8(sp)
    800028be:	6902                	ld	s2,0(sp)
    800028c0:	6105                	addi	sp,sp,32
    800028c2:	8082                	ret

00000000800028c4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800028c4:	1101                	addi	sp,sp,-32
    800028c6:	ec06                	sd	ra,24(sp)
    800028c8:	e822                	sd	s0,16(sp)
    800028ca:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800028cc:	fec40593          	addi	a1,s0,-20
    800028d0:	4501                	li	a0,0
    800028d2:	eefff0ef          	jal	ra,800027c0 <argint>
  exit(n);
    800028d6:	fec42503          	lw	a0,-20(s0)
    800028da:	ef2ff0ef          	jal	ra,80001fcc <exit>
  return 0;  // not reached
}
    800028de:	4501                	li	a0,0
    800028e0:	60e2                	ld	ra,24(sp)
    800028e2:	6442                	ld	s0,16(sp)
    800028e4:	6105                	addi	sp,sp,32
    800028e6:	8082                	ret

00000000800028e8 <sys_getpid>:

uint64
sys_getpid(void)
{
    800028e8:	1141                	addi	sp,sp,-16
    800028ea:	e406                	sd	ra,8(sp)
    800028ec:	e022                	sd	s0,0(sp)
    800028ee:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800028f0:	febfe0ef          	jal	ra,800018da <myproc>
}
    800028f4:	5908                	lw	a0,48(a0)
    800028f6:	60a2                	ld	ra,8(sp)
    800028f8:	6402                	ld	s0,0(sp)
    800028fa:	0141                	addi	sp,sp,16
    800028fc:	8082                	ret

00000000800028fe <sys_fork>:

uint64
sys_fork(void)
{
    800028fe:	1141                	addi	sp,sp,-16
    80002900:	e406                	sd	ra,8(sp)
    80002902:	e022                	sd	s0,0(sp)
    80002904:	0800                	addi	s0,sp,16
  return fork();
    80002906:	b0eff0ef          	jal	ra,80001c14 <fork>
}
    8000290a:	60a2                	ld	ra,8(sp)
    8000290c:	6402                	ld	s0,0(sp)
    8000290e:	0141                	addi	sp,sp,16
    80002910:	8082                	ret

0000000080002912 <sys_wait>:

uint64
sys_wait(void)
{
    80002912:	1101                	addi	sp,sp,-32
    80002914:	ec06                	sd	ra,24(sp)
    80002916:	e822                	sd	s0,16(sp)
    80002918:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000291a:	fe840593          	addi	a1,s0,-24
    8000291e:	4501                	li	a0,0
    80002920:	ebdff0ef          	jal	ra,800027dc <argaddr>
  return wait(p);
    80002924:	fe843503          	ld	a0,-24(s0)
    80002928:	ffaff0ef          	jal	ra,80002122 <wait>
}
    8000292c:	60e2                	ld	ra,24(sp)
    8000292e:	6442                	ld	s0,16(sp)
    80002930:	6105                	addi	sp,sp,32
    80002932:	8082                	ret

0000000080002934 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002934:	7179                	addi	sp,sp,-48
    80002936:	f406                	sd	ra,40(sp)
    80002938:	f022                	sd	s0,32(sp)
    8000293a:	ec26                	sd	s1,24(sp)
    8000293c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000293e:	fdc40593          	addi	a1,s0,-36
    80002942:	4501                	li	a0,0
    80002944:	e7dff0ef          	jal	ra,800027c0 <argint>
  addr = myproc()->sz;
    80002948:	f93fe0ef          	jal	ra,800018da <myproc>
    8000294c:	6924                	ld	s1,80(a0)
  if(n < 0) {
    8000294e:	fdc42503          	lw	a0,-36(s0)
    80002952:	00054f63          	bltz	a0,80002970 <sys_sbrk+0x3c>
      return -1;
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    myproc()->sz += n;
    80002956:	f85fe0ef          	jal	ra,800018da <myproc>
    8000295a:	fdc42703          	lw	a4,-36(s0)
    8000295e:	693c                	ld	a5,80(a0)
    80002960:	97ba                	add	a5,a5,a4
    80002962:	e93c                	sd	a5,80(a0)
  }
  return addr;
}
    80002964:	8526                	mv	a0,s1
    80002966:	70a2                	ld	ra,40(sp)
    80002968:	7402                	ld	s0,32(sp)
    8000296a:	64e2                	ld	s1,24(sp)
    8000296c:	6145                	addi	sp,sp,48
    8000296e:	8082                	ret
    if(shrinkproc(-n) < 0)
    80002970:	40a0053b          	negw	a0,a0
    80002974:	a68ff0ef          	jal	ra,80001bdc <shrinkproc>
    80002978:	fe0556e3          	bgez	a0,80002964 <sys_sbrk+0x30>
      return -1;
    8000297c:	54fd                	li	s1,-1
    8000297e:	b7dd                	j	80002964 <sys_sbrk+0x30>

0000000080002980 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002980:	7139                	addi	sp,sp,-64
    80002982:	fc06                	sd	ra,56(sp)
    80002984:	f822                	sd	s0,48(sp)
    80002986:	f426                	sd	s1,40(sp)
    80002988:	f04a                	sd	s2,32(sp)
    8000298a:	ec4e                	sd	s3,24(sp)
    8000298c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000298e:	fcc40593          	addi	a1,s0,-52
    80002992:	4501                	li	a0,0
    80002994:	e2dff0ef          	jal	ra,800027c0 <argint>
  backtrace();
    80002998:	df5fd0ef          	jal	ra,8000078c <backtrace>
  if(n < 0)
    8000299c:	fcc42783          	lw	a5,-52(s0)
    800029a0:	0607c563          	bltz	a5,80002a0a <sys_sleep+0x8a>
    n = 0;
  acquire(&tickslock);
    800029a4:	00013517          	auipc	a0,0x13
    800029a8:	16450513          	addi	a0,a0,356 # 80015b08 <tickslock>
    800029ac:	a96fe0ef          	jal	ra,80000c42 <acquire>
  ticks0 = ticks;
    800029b0:	00005917          	auipc	s2,0x5
    800029b4:	00092903          	lw	s2,0(s2) # 800079b0 <ticks>
  while(ticks - ticks0 < n){
    800029b8:	fcc42783          	lw	a5,-52(s0)
    800029bc:	cb8d                	beqz	a5,800029ee <sys_sleep+0x6e>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800029be:	00013997          	auipc	s3,0x13
    800029c2:	14a98993          	addi	s3,s3,330 # 80015b08 <tickslock>
    800029c6:	00005497          	auipc	s1,0x5
    800029ca:	fea48493          	addi	s1,s1,-22 # 800079b0 <ticks>
    if(killed(myproc())){
    800029ce:	f0dfe0ef          	jal	ra,800018da <myproc>
    800029d2:	f26ff0ef          	jal	ra,800020f8 <killed>
    800029d6:	ed0d                	bnez	a0,80002a10 <sys_sleep+0x90>
    sleep(&ticks, &tickslock);
    800029d8:	85ce                	mv	a1,s3
    800029da:	8526                	mv	a0,s1
    800029dc:	ce4ff0ef          	jal	ra,80001ec0 <sleep>
  while(ticks - ticks0 < n){
    800029e0:	409c                	lw	a5,0(s1)
    800029e2:	412787bb          	subw	a5,a5,s2
    800029e6:	fcc42703          	lw	a4,-52(s0)
    800029ea:	fee7e2e3          	bltu	a5,a4,800029ce <sys_sleep+0x4e>
  }
  release(&tickslock);
    800029ee:	00013517          	auipc	a0,0x13
    800029f2:	11a50513          	addi	a0,a0,282 # 80015b08 <tickslock>
    800029f6:	ae4fe0ef          	jal	ra,80000cda <release>
  return 0;
    800029fa:	4501                	li	a0,0
}
    800029fc:	70e2                	ld	ra,56(sp)
    800029fe:	7442                	ld	s0,48(sp)
    80002a00:	74a2                	ld	s1,40(sp)
    80002a02:	7902                	ld	s2,32(sp)
    80002a04:	69e2                	ld	s3,24(sp)
    80002a06:	6121                	addi	sp,sp,64
    80002a08:	8082                	ret
    n = 0;
    80002a0a:	fc042623          	sw	zero,-52(s0)
    80002a0e:	bf59                	j	800029a4 <sys_sleep+0x24>
      release(&tickslock);
    80002a10:	00013517          	auipc	a0,0x13
    80002a14:	0f850513          	addi	a0,a0,248 # 80015b08 <tickslock>
    80002a18:	ac2fe0ef          	jal	ra,80000cda <release>
      return -1;
    80002a1c:	557d                	li	a0,-1
    80002a1e:	bff9                	j	800029fc <sys_sleep+0x7c>

0000000080002a20 <sys_kill>:

uint64
sys_kill(void)
{
    80002a20:	1101                	addi	sp,sp,-32
    80002a22:	ec06                	sd	ra,24(sp)
    80002a24:	e822                	sd	s0,16(sp)
    80002a26:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002a28:	fec40593          	addi	a1,s0,-20
    80002a2c:	4501                	li	a0,0
    80002a2e:	d93ff0ef          	jal	ra,800027c0 <argint>
  return kill(pid);
    80002a32:	fec42503          	lw	a0,-20(s0)
    80002a36:	e38ff0ef          	jal	ra,8000206e <kill>
}
    80002a3a:	60e2                	ld	ra,24(sp)
    80002a3c:	6442                	ld	s0,16(sp)
    80002a3e:	6105                	addi	sp,sp,32
    80002a40:	8082                	ret

0000000080002a42 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002a42:	1101                	addi	sp,sp,-32
    80002a44:	ec06                	sd	ra,24(sp)
    80002a46:	e822                	sd	s0,16(sp)
    80002a48:	e426                	sd	s1,8(sp)
    80002a4a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002a4c:	00013517          	auipc	a0,0x13
    80002a50:	0bc50513          	addi	a0,a0,188 # 80015b08 <tickslock>
    80002a54:	9eefe0ef          	jal	ra,80000c42 <acquire>
  xticks = ticks;
    80002a58:	00005497          	auipc	s1,0x5
    80002a5c:	f584a483          	lw	s1,-168(s1) # 800079b0 <ticks>
  release(&tickslock);
    80002a60:	00013517          	auipc	a0,0x13
    80002a64:	0a850513          	addi	a0,a0,168 # 80015b08 <tickslock>
    80002a68:	a72fe0ef          	jal	ra,80000cda <release>
  return xticks;
}
    80002a6c:	02049513          	slli	a0,s1,0x20
    80002a70:	9101                	srli	a0,a0,0x20
    80002a72:	60e2                	ld	ra,24(sp)
    80002a74:	6442                	ld	s0,16(sp)
    80002a76:	64a2                	ld	s1,8(sp)
    80002a78:	6105                	addi	sp,sp,32
    80002a7a:	8082                	ret

0000000080002a7c <sys_trace>:
uint64
sys_trace(void)
{
    80002a7c:	7179                	addi	sp,sp,-48
    80002a7e:	f406                	sd	ra,40(sp)
    80002a80:	f022                	sd	s0,32(sp)
    80002a82:	ec26                	sd	s1,24(sp)
    80002a84:	1800                	addi	s0,sp,48
  int mask;
  
  argint(0, &mask);             // fetch the first argument
    80002a86:	fdc40593          	addi	a1,s0,-36
    80002a8a:	4501                	li	a0,0
    80002a8c:	d35ff0ef          	jal	ra,800027c0 <argint>
  myproc()->tracemask = (uint)mask;
    80002a90:	fdc42483          	lw	s1,-36(s0)
    80002a94:	e47fe0ef          	jal	ra,800018da <myproc>
    80002a98:	c124                	sw	s1,64(a0)
  return 0;
    80002a9a:	4501                	li	a0,0
    80002a9c:	70a2                	ld	ra,40(sp)
    80002a9e:	7402                	ld	s0,32(sp)
    80002aa0:	64e2                	ld	s1,24(sp)
    80002aa2:	6145                	addi	sp,sp,48
    80002aa4:	8082                	ret

0000000080002aa6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002aa6:	7179                	addi	sp,sp,-48
    80002aa8:	f406                	sd	ra,40(sp)
    80002aaa:	f022                	sd	s0,32(sp)
    80002aac:	ec26                	sd	s1,24(sp)
    80002aae:	e84a                	sd	s2,16(sp)
    80002ab0:	e44e                	sd	s3,8(sp)
    80002ab2:	e052                	sd	s4,0(sp)
    80002ab4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ab6:	00005597          	auipc	a1,0x5
    80002aba:	b8258593          	addi	a1,a1,-1150 # 80007638 <syscallnames+0xb8>
    80002abe:	00013517          	auipc	a0,0x13
    80002ac2:	06250513          	addi	a0,a0,98 # 80015b20 <bcache>
    80002ac6:	8fcfe0ef          	jal	ra,80000bc2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002aca:	0001b797          	auipc	a5,0x1b
    80002ace:	05678793          	addi	a5,a5,86 # 8001db20 <bcache+0x8000>
    80002ad2:	0001b717          	auipc	a4,0x1b
    80002ad6:	2b670713          	addi	a4,a4,694 # 8001dd88 <bcache+0x8268>
    80002ada:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ade:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ae2:	00013497          	auipc	s1,0x13
    80002ae6:	05648493          	addi	s1,s1,86 # 80015b38 <bcache+0x18>
    b->next = bcache.head.next;
    80002aea:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002aec:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002aee:	00005a17          	auipc	s4,0x5
    80002af2:	b52a0a13          	addi	s4,s4,-1198 # 80007640 <syscallnames+0xc0>
    b->next = bcache.head.next;
    80002af6:	2b893783          	ld	a5,696(s2)
    80002afa:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002afc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002b00:	85d2                	mv	a1,s4
    80002b02:	01048513          	addi	a0,s1,16
    80002b06:	22a010ef          	jal	ra,80003d30 <initsleeplock>
    bcache.head.next->prev = b;
    80002b0a:	2b893783          	ld	a5,696(s2)
    80002b0e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002b10:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002b14:	45848493          	addi	s1,s1,1112
    80002b18:	fd349fe3          	bne	s1,s3,80002af6 <binit+0x50>
  }
}
    80002b1c:	70a2                	ld	ra,40(sp)
    80002b1e:	7402                	ld	s0,32(sp)
    80002b20:	64e2                	ld	s1,24(sp)
    80002b22:	6942                	ld	s2,16(sp)
    80002b24:	69a2                	ld	s3,8(sp)
    80002b26:	6a02                	ld	s4,0(sp)
    80002b28:	6145                	addi	sp,sp,48
    80002b2a:	8082                	ret

0000000080002b2c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002b2c:	7179                	addi	sp,sp,-48
    80002b2e:	f406                	sd	ra,40(sp)
    80002b30:	f022                	sd	s0,32(sp)
    80002b32:	ec26                	sd	s1,24(sp)
    80002b34:	e84a                	sd	s2,16(sp)
    80002b36:	e44e                	sd	s3,8(sp)
    80002b38:	1800                	addi	s0,sp,48
    80002b3a:	892a                	mv	s2,a0
    80002b3c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002b3e:	00013517          	auipc	a0,0x13
    80002b42:	fe250513          	addi	a0,a0,-30 # 80015b20 <bcache>
    80002b46:	8fcfe0ef          	jal	ra,80000c42 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002b4a:	0001b497          	auipc	s1,0x1b
    80002b4e:	28e4b483          	ld	s1,654(s1) # 8001ddd8 <bcache+0x82b8>
    80002b52:	0001b797          	auipc	a5,0x1b
    80002b56:	23678793          	addi	a5,a5,566 # 8001dd88 <bcache+0x8268>
    80002b5a:	02f48b63          	beq	s1,a5,80002b90 <bread+0x64>
    80002b5e:	873e                	mv	a4,a5
    80002b60:	a021                	j	80002b68 <bread+0x3c>
    80002b62:	68a4                	ld	s1,80(s1)
    80002b64:	02e48663          	beq	s1,a4,80002b90 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002b68:	449c                	lw	a5,8(s1)
    80002b6a:	ff279ce3          	bne	a5,s2,80002b62 <bread+0x36>
    80002b6e:	44dc                	lw	a5,12(s1)
    80002b70:	ff3799e3          	bne	a5,s3,80002b62 <bread+0x36>
      b->refcnt++;
    80002b74:	40bc                	lw	a5,64(s1)
    80002b76:	2785                	addiw	a5,a5,1
    80002b78:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002b7a:	00013517          	auipc	a0,0x13
    80002b7e:	fa650513          	addi	a0,a0,-90 # 80015b20 <bcache>
    80002b82:	958fe0ef          	jal	ra,80000cda <release>
      acquiresleep(&b->lock);
    80002b86:	01048513          	addi	a0,s1,16
    80002b8a:	1dc010ef          	jal	ra,80003d66 <acquiresleep>
      return b;
    80002b8e:	a889                	j	80002be0 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002b90:	0001b497          	auipc	s1,0x1b
    80002b94:	2404b483          	ld	s1,576(s1) # 8001ddd0 <bcache+0x82b0>
    80002b98:	0001b797          	auipc	a5,0x1b
    80002b9c:	1f078793          	addi	a5,a5,496 # 8001dd88 <bcache+0x8268>
    80002ba0:	00f48863          	beq	s1,a5,80002bb0 <bread+0x84>
    80002ba4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ba6:	40bc                	lw	a5,64(s1)
    80002ba8:	cb91                	beqz	a5,80002bbc <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002baa:	64a4                	ld	s1,72(s1)
    80002bac:	fee49de3          	bne	s1,a4,80002ba6 <bread+0x7a>
  panic("bget: no buffers");
    80002bb0:	00005517          	auipc	a0,0x5
    80002bb4:	a9850513          	addi	a0,a0,-1384 # 80007648 <syscallnames+0xc8>
    80002bb8:	c25fd0ef          	jal	ra,800007dc <panic>
      b->dev = dev;
    80002bbc:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002bc0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002bc4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002bc8:	4785                	li	a5,1
    80002bca:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002bcc:	00013517          	auipc	a0,0x13
    80002bd0:	f5450513          	addi	a0,a0,-172 # 80015b20 <bcache>
    80002bd4:	906fe0ef          	jal	ra,80000cda <release>
      acquiresleep(&b->lock);
    80002bd8:	01048513          	addi	a0,s1,16
    80002bdc:	18a010ef          	jal	ra,80003d66 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002be0:	409c                	lw	a5,0(s1)
    80002be2:	cb89                	beqz	a5,80002bf4 <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002be4:	8526                	mv	a0,s1
    80002be6:	70a2                	ld	ra,40(sp)
    80002be8:	7402                	ld	s0,32(sp)
    80002bea:	64e2                	ld	s1,24(sp)
    80002bec:	6942                	ld	s2,16(sp)
    80002bee:	69a2                	ld	s3,8(sp)
    80002bf0:	6145                	addi	sp,sp,48
    80002bf2:	8082                	ret
    virtio_disk_rw(b, 0);
    80002bf4:	4581                	li	a1,0
    80002bf6:	8526                	mv	a0,s1
    80002bf8:	0d5020ef          	jal	ra,800054cc <virtio_disk_rw>
    b->valid = 1;
    80002bfc:	4785                	li	a5,1
    80002bfe:	c09c                	sw	a5,0(s1)
  return b;
    80002c00:	b7d5                	j	80002be4 <bread+0xb8>

0000000080002c02 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002c02:	1101                	addi	sp,sp,-32
    80002c04:	ec06                	sd	ra,24(sp)
    80002c06:	e822                	sd	s0,16(sp)
    80002c08:	e426                	sd	s1,8(sp)
    80002c0a:	1000                	addi	s0,sp,32
    80002c0c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002c0e:	0541                	addi	a0,a0,16
    80002c10:	1d4010ef          	jal	ra,80003de4 <holdingsleep>
    80002c14:	c911                	beqz	a0,80002c28 <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002c16:	4585                	li	a1,1
    80002c18:	8526                	mv	a0,s1
    80002c1a:	0b3020ef          	jal	ra,800054cc <virtio_disk_rw>
}
    80002c1e:	60e2                	ld	ra,24(sp)
    80002c20:	6442                	ld	s0,16(sp)
    80002c22:	64a2                	ld	s1,8(sp)
    80002c24:	6105                	addi	sp,sp,32
    80002c26:	8082                	ret
    panic("bwrite");
    80002c28:	00005517          	auipc	a0,0x5
    80002c2c:	a3850513          	addi	a0,a0,-1480 # 80007660 <syscallnames+0xe0>
    80002c30:	badfd0ef          	jal	ra,800007dc <panic>

0000000080002c34 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002c34:	1101                	addi	sp,sp,-32
    80002c36:	ec06                	sd	ra,24(sp)
    80002c38:	e822                	sd	s0,16(sp)
    80002c3a:	e426                	sd	s1,8(sp)
    80002c3c:	e04a                	sd	s2,0(sp)
    80002c3e:	1000                	addi	s0,sp,32
    80002c40:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002c42:	01050913          	addi	s2,a0,16
    80002c46:	854a                	mv	a0,s2
    80002c48:	19c010ef          	jal	ra,80003de4 <holdingsleep>
    80002c4c:	c13d                	beqz	a0,80002cb2 <brelse+0x7e>
    panic("brelse");

  releasesleep(&b->lock);
    80002c4e:	854a                	mv	a0,s2
    80002c50:	15c010ef          	jal	ra,80003dac <releasesleep>

  acquire(&bcache.lock);
    80002c54:	00013517          	auipc	a0,0x13
    80002c58:	ecc50513          	addi	a0,a0,-308 # 80015b20 <bcache>
    80002c5c:	fe7fd0ef          	jal	ra,80000c42 <acquire>
  b->refcnt--;
    80002c60:	40bc                	lw	a5,64(s1)
    80002c62:	37fd                	addiw	a5,a5,-1
    80002c64:	0007871b          	sext.w	a4,a5
    80002c68:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002c6a:	eb05                	bnez	a4,80002c9a <brelse+0x66>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002c6c:	68bc                	ld	a5,80(s1)
    80002c6e:	64b8                	ld	a4,72(s1)
    80002c70:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002c72:	64bc                	ld	a5,72(s1)
    80002c74:	68b8                	ld	a4,80(s1)
    80002c76:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002c78:	0001b797          	auipc	a5,0x1b
    80002c7c:	ea878793          	addi	a5,a5,-344 # 8001db20 <bcache+0x8000>
    80002c80:	2b87b703          	ld	a4,696(a5)
    80002c84:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002c86:	0001b717          	auipc	a4,0x1b
    80002c8a:	10270713          	addi	a4,a4,258 # 8001dd88 <bcache+0x8268>
    80002c8e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002c90:	2b87b703          	ld	a4,696(a5)
    80002c94:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002c96:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002c9a:	00013517          	auipc	a0,0x13
    80002c9e:	e8650513          	addi	a0,a0,-378 # 80015b20 <bcache>
    80002ca2:	838fe0ef          	jal	ra,80000cda <release>
}
    80002ca6:	60e2                	ld	ra,24(sp)
    80002ca8:	6442                	ld	s0,16(sp)
    80002caa:	64a2                	ld	s1,8(sp)
    80002cac:	6902                	ld	s2,0(sp)
    80002cae:	6105                	addi	sp,sp,32
    80002cb0:	8082                	ret
    panic("brelse");
    80002cb2:	00005517          	auipc	a0,0x5
    80002cb6:	9b650513          	addi	a0,a0,-1610 # 80007668 <syscallnames+0xe8>
    80002cba:	b23fd0ef          	jal	ra,800007dc <panic>

0000000080002cbe <bpin>:

void
bpin(struct buf *b) {
    80002cbe:	1101                	addi	sp,sp,-32
    80002cc0:	ec06                	sd	ra,24(sp)
    80002cc2:	e822                	sd	s0,16(sp)
    80002cc4:	e426                	sd	s1,8(sp)
    80002cc6:	1000                	addi	s0,sp,32
    80002cc8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002cca:	00013517          	auipc	a0,0x13
    80002cce:	e5650513          	addi	a0,a0,-426 # 80015b20 <bcache>
    80002cd2:	f71fd0ef          	jal	ra,80000c42 <acquire>
  b->refcnt++;
    80002cd6:	40bc                	lw	a5,64(s1)
    80002cd8:	2785                	addiw	a5,a5,1
    80002cda:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002cdc:	00013517          	auipc	a0,0x13
    80002ce0:	e4450513          	addi	a0,a0,-444 # 80015b20 <bcache>
    80002ce4:	ff7fd0ef          	jal	ra,80000cda <release>
}
    80002ce8:	60e2                	ld	ra,24(sp)
    80002cea:	6442                	ld	s0,16(sp)
    80002cec:	64a2                	ld	s1,8(sp)
    80002cee:	6105                	addi	sp,sp,32
    80002cf0:	8082                	ret

0000000080002cf2 <bunpin>:

void
bunpin(struct buf *b) {
    80002cf2:	1101                	addi	sp,sp,-32
    80002cf4:	ec06                	sd	ra,24(sp)
    80002cf6:	e822                	sd	s0,16(sp)
    80002cf8:	e426                	sd	s1,8(sp)
    80002cfa:	1000                	addi	s0,sp,32
    80002cfc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002cfe:	00013517          	auipc	a0,0x13
    80002d02:	e2250513          	addi	a0,a0,-478 # 80015b20 <bcache>
    80002d06:	f3dfd0ef          	jal	ra,80000c42 <acquire>
  b->refcnt--;
    80002d0a:	40bc                	lw	a5,64(s1)
    80002d0c:	37fd                	addiw	a5,a5,-1
    80002d0e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002d10:	00013517          	auipc	a0,0x13
    80002d14:	e1050513          	addi	a0,a0,-496 # 80015b20 <bcache>
    80002d18:	fc3fd0ef          	jal	ra,80000cda <release>
}
    80002d1c:	60e2                	ld	ra,24(sp)
    80002d1e:	6442                	ld	s0,16(sp)
    80002d20:	64a2                	ld	s1,8(sp)
    80002d22:	6105                	addi	sp,sp,32
    80002d24:	8082                	ret

0000000080002d26 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002d26:	1101                	addi	sp,sp,-32
    80002d28:	ec06                	sd	ra,24(sp)
    80002d2a:	e822                	sd	s0,16(sp)
    80002d2c:	e426                	sd	s1,8(sp)
    80002d2e:	e04a                	sd	s2,0(sp)
    80002d30:	1000                	addi	s0,sp,32
    80002d32:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002d34:	00d5d59b          	srliw	a1,a1,0xd
    80002d38:	0001b797          	auipc	a5,0x1b
    80002d3c:	4c47a783          	lw	a5,1220(a5) # 8001e1fc <sb+0x1c>
    80002d40:	9dbd                	addw	a1,a1,a5
    80002d42:	debff0ef          	jal	ra,80002b2c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002d46:	0074f713          	andi	a4,s1,7
    80002d4a:	4785                	li	a5,1
    80002d4c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002d50:	14ce                	slli	s1,s1,0x33
    80002d52:	90d9                	srli	s1,s1,0x36
    80002d54:	00950733          	add	a4,a0,s1
    80002d58:	05874703          	lbu	a4,88(a4)
    80002d5c:	00e7f6b3          	and	a3,a5,a4
    80002d60:	c29d                	beqz	a3,80002d86 <bfree+0x60>
    80002d62:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002d64:	94aa                	add	s1,s1,a0
    80002d66:	fff7c793          	not	a5,a5
    80002d6a:	8ff9                	and	a5,a5,a4
    80002d6c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80002d70:	6ef000ef          	jal	ra,80003c5e <log_write>
  brelse(bp);
    80002d74:	854a                	mv	a0,s2
    80002d76:	ebfff0ef          	jal	ra,80002c34 <brelse>
}
    80002d7a:	60e2                	ld	ra,24(sp)
    80002d7c:	6442                	ld	s0,16(sp)
    80002d7e:	64a2                	ld	s1,8(sp)
    80002d80:	6902                	ld	s2,0(sp)
    80002d82:	6105                	addi	sp,sp,32
    80002d84:	8082                	ret
    panic("freeing free block");
    80002d86:	00005517          	auipc	a0,0x5
    80002d8a:	8ea50513          	addi	a0,a0,-1814 # 80007670 <syscallnames+0xf0>
    80002d8e:	a4ffd0ef          	jal	ra,800007dc <panic>

0000000080002d92 <balloc>:
{
    80002d92:	711d                	addi	sp,sp,-96
    80002d94:	ec86                	sd	ra,88(sp)
    80002d96:	e8a2                	sd	s0,80(sp)
    80002d98:	e4a6                	sd	s1,72(sp)
    80002d9a:	e0ca                	sd	s2,64(sp)
    80002d9c:	fc4e                	sd	s3,56(sp)
    80002d9e:	f852                	sd	s4,48(sp)
    80002da0:	f456                	sd	s5,40(sp)
    80002da2:	f05a                	sd	s6,32(sp)
    80002da4:	ec5e                	sd	s7,24(sp)
    80002da6:	e862                	sd	s8,16(sp)
    80002da8:	e466                	sd	s9,8(sp)
    80002daa:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002dac:	0001b797          	auipc	a5,0x1b
    80002db0:	4387a783          	lw	a5,1080(a5) # 8001e1e4 <sb+0x4>
    80002db4:	0e078163          	beqz	a5,80002e96 <balloc+0x104>
    80002db8:	8baa                	mv	s7,a0
    80002dba:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002dbc:	0001bb17          	auipc	s6,0x1b
    80002dc0:	424b0b13          	addi	s6,s6,1060 # 8001e1e0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002dc4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002dc6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002dc8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002dca:	6c89                	lui	s9,0x2
    80002dcc:	a0b5                	j	80002e38 <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002dce:	974a                	add	a4,a4,s2
    80002dd0:	8fd5                	or	a5,a5,a3
    80002dd2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80002dd6:	854a                	mv	a0,s2
    80002dd8:	687000ef          	jal	ra,80003c5e <log_write>
        brelse(bp);
    80002ddc:	854a                	mv	a0,s2
    80002dde:	e57ff0ef          	jal	ra,80002c34 <brelse>
  bp = bread(dev, bno);
    80002de2:	85a6                	mv	a1,s1
    80002de4:	855e                	mv	a0,s7
    80002de6:	d47ff0ef          	jal	ra,80002b2c <bread>
    80002dea:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002dec:	40000613          	li	a2,1024
    80002df0:	4581                	li	a1,0
    80002df2:	05850513          	addi	a0,a0,88
    80002df6:	f21fd0ef          	jal	ra,80000d16 <memset>
  log_write(bp);
    80002dfa:	854a                	mv	a0,s2
    80002dfc:	663000ef          	jal	ra,80003c5e <log_write>
  brelse(bp);
    80002e00:	854a                	mv	a0,s2
    80002e02:	e33ff0ef          	jal	ra,80002c34 <brelse>
}
    80002e06:	8526                	mv	a0,s1
    80002e08:	60e6                	ld	ra,88(sp)
    80002e0a:	6446                	ld	s0,80(sp)
    80002e0c:	64a6                	ld	s1,72(sp)
    80002e0e:	6906                	ld	s2,64(sp)
    80002e10:	79e2                	ld	s3,56(sp)
    80002e12:	7a42                	ld	s4,48(sp)
    80002e14:	7aa2                	ld	s5,40(sp)
    80002e16:	7b02                	ld	s6,32(sp)
    80002e18:	6be2                	ld	s7,24(sp)
    80002e1a:	6c42                	ld	s8,16(sp)
    80002e1c:	6ca2                	ld	s9,8(sp)
    80002e1e:	6125                	addi	sp,sp,96
    80002e20:	8082                	ret
    brelse(bp);
    80002e22:	854a                	mv	a0,s2
    80002e24:	e11ff0ef          	jal	ra,80002c34 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002e28:	015c87bb          	addw	a5,s9,s5
    80002e2c:	00078a9b          	sext.w	s5,a5
    80002e30:	004b2703          	lw	a4,4(s6)
    80002e34:	06eaf163          	bgeu	s5,a4,80002e96 <balloc+0x104>
    bp = bread(dev, BBLOCK(b, sb));
    80002e38:	41fad79b          	sraiw	a5,s5,0x1f
    80002e3c:	0137d79b          	srliw	a5,a5,0x13
    80002e40:	015787bb          	addw	a5,a5,s5
    80002e44:	40d7d79b          	sraiw	a5,a5,0xd
    80002e48:	01cb2583          	lw	a1,28(s6)
    80002e4c:	9dbd                	addw	a1,a1,a5
    80002e4e:	855e                	mv	a0,s7
    80002e50:	cddff0ef          	jal	ra,80002b2c <bread>
    80002e54:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e56:	004b2503          	lw	a0,4(s6)
    80002e5a:	000a849b          	sext.w	s1,s5
    80002e5e:	8662                	mv	a2,s8
    80002e60:	fca4f1e3          	bgeu	s1,a0,80002e22 <balloc+0x90>
      m = 1 << (bi % 8);
    80002e64:	41f6579b          	sraiw	a5,a2,0x1f
    80002e68:	01d7d69b          	srliw	a3,a5,0x1d
    80002e6c:	00c6873b          	addw	a4,a3,a2
    80002e70:	00777793          	andi	a5,a4,7
    80002e74:	9f95                	subw	a5,a5,a3
    80002e76:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80002e7a:	4037571b          	sraiw	a4,a4,0x3
    80002e7e:	00e906b3          	add	a3,s2,a4
    80002e82:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    80002e86:	00d7f5b3          	and	a1,a5,a3
    80002e8a:	d1b1                	beqz	a1,80002dce <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e8c:	2605                	addiw	a2,a2,1
    80002e8e:	2485                	addiw	s1,s1,1
    80002e90:	fd4618e3          	bne	a2,s4,80002e60 <balloc+0xce>
    80002e94:	b779                	j	80002e22 <balloc+0x90>
  printf("balloc: out of blocks\n");
    80002e96:	00004517          	auipc	a0,0x4
    80002e9a:	7f250513          	addi	a0,a0,2034 # 80007688 <syscallnames+0x108>
    80002e9e:	e04fd0ef          	jal	ra,800004a2 <printf>
  return 0;
    80002ea2:	4481                	li	s1,0
    80002ea4:	b78d                	j	80002e06 <balloc+0x74>

0000000080002ea6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80002ea6:	7179                	addi	sp,sp,-48
    80002ea8:	f406                	sd	ra,40(sp)
    80002eaa:	f022                	sd	s0,32(sp)
    80002eac:	ec26                	sd	s1,24(sp)
    80002eae:	e84a                	sd	s2,16(sp)
    80002eb0:	e44e                	sd	s3,8(sp)
    80002eb2:	e052                	sd	s4,0(sp)
    80002eb4:	1800                	addi	s0,sp,48
    80002eb6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80002eb8:	47ad                	li	a5,11
    80002eba:	02b7e663          	bltu	a5,a1,80002ee6 <bmap+0x40>
    if((addr = ip->addrs[bn]) == 0){
    80002ebe:	02059793          	slli	a5,a1,0x20
    80002ec2:	01e7d593          	srli	a1,a5,0x1e
    80002ec6:	00b504b3          	add	s1,a0,a1
    80002eca:	0504a903          	lw	s2,80(s1)
    80002ece:	06091663          	bnez	s2,80002f3a <bmap+0x94>
      addr = balloc(ip->dev);
    80002ed2:	4108                	lw	a0,0(a0)
    80002ed4:	ebfff0ef          	jal	ra,80002d92 <balloc>
    80002ed8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002edc:	04090f63          	beqz	s2,80002f3a <bmap+0x94>
        return 0;
      ip->addrs[bn] = addr;
    80002ee0:	0524a823          	sw	s2,80(s1)
    80002ee4:	a899                	j	80002f3a <bmap+0x94>
    }
    return addr;
  }
  bn -= NDIRECT;
    80002ee6:	ff45849b          	addiw	s1,a1,-12
    80002eea:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80002eee:	0ff00793          	li	a5,255
    80002ef2:	06e7eb63          	bltu	a5,a4,80002f68 <bmap+0xc2>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80002ef6:	08052903          	lw	s2,128(a0)
    80002efa:	00091b63          	bnez	s2,80002f10 <bmap+0x6a>
      addr = balloc(ip->dev);
    80002efe:	4108                	lw	a0,0(a0)
    80002f00:	e93ff0ef          	jal	ra,80002d92 <balloc>
    80002f04:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002f08:	02090963          	beqz	s2,80002f3a <bmap+0x94>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80002f0c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80002f10:	85ca                	mv	a1,s2
    80002f12:	0009a503          	lw	a0,0(s3)
    80002f16:	c17ff0ef          	jal	ra,80002b2c <bread>
    80002f1a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80002f1c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80002f20:	02049713          	slli	a4,s1,0x20
    80002f24:	01e75593          	srli	a1,a4,0x1e
    80002f28:	00b784b3          	add	s1,a5,a1
    80002f2c:	0004a903          	lw	s2,0(s1)
    80002f30:	00090e63          	beqz	s2,80002f4c <bmap+0xa6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80002f34:	8552                	mv	a0,s4
    80002f36:	cffff0ef          	jal	ra,80002c34 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80002f3a:	854a                	mv	a0,s2
    80002f3c:	70a2                	ld	ra,40(sp)
    80002f3e:	7402                	ld	s0,32(sp)
    80002f40:	64e2                	ld	s1,24(sp)
    80002f42:	6942                	ld	s2,16(sp)
    80002f44:	69a2                	ld	s3,8(sp)
    80002f46:	6a02                	ld	s4,0(sp)
    80002f48:	6145                	addi	sp,sp,48
    80002f4a:	8082                	ret
      addr = balloc(ip->dev);
    80002f4c:	0009a503          	lw	a0,0(s3)
    80002f50:	e43ff0ef          	jal	ra,80002d92 <balloc>
    80002f54:	0005091b          	sext.w	s2,a0
      if(addr){
    80002f58:	fc090ee3          	beqz	s2,80002f34 <bmap+0x8e>
        a[bn] = addr;
    80002f5c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80002f60:	8552                	mv	a0,s4
    80002f62:	4fd000ef          	jal	ra,80003c5e <log_write>
    80002f66:	b7f9                	j	80002f34 <bmap+0x8e>
  panic("bmap: out of range");
    80002f68:	00004517          	auipc	a0,0x4
    80002f6c:	73850513          	addi	a0,a0,1848 # 800076a0 <syscallnames+0x120>
    80002f70:	86dfd0ef          	jal	ra,800007dc <panic>

0000000080002f74 <iget>:
{
    80002f74:	7179                	addi	sp,sp,-48
    80002f76:	f406                	sd	ra,40(sp)
    80002f78:	f022                	sd	s0,32(sp)
    80002f7a:	ec26                	sd	s1,24(sp)
    80002f7c:	e84a                	sd	s2,16(sp)
    80002f7e:	e44e                	sd	s3,8(sp)
    80002f80:	e052                	sd	s4,0(sp)
    80002f82:	1800                	addi	s0,sp,48
    80002f84:	89aa                	mv	s3,a0
    80002f86:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80002f88:	0001b517          	auipc	a0,0x1b
    80002f8c:	27850513          	addi	a0,a0,632 # 8001e200 <itable>
    80002f90:	cb3fd0ef          	jal	ra,80000c42 <acquire>
  empty = 0;
    80002f94:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80002f96:	0001b497          	auipc	s1,0x1b
    80002f9a:	28248493          	addi	s1,s1,642 # 8001e218 <itable+0x18>
    80002f9e:	0001d697          	auipc	a3,0x1d
    80002fa2:	d0a68693          	addi	a3,a3,-758 # 8001fca8 <log>
    80002fa6:	a039                	j	80002fb4 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80002fa8:	02090963          	beqz	s2,80002fda <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80002fac:	08848493          	addi	s1,s1,136
    80002fb0:	02d48863          	beq	s1,a3,80002fe0 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80002fb4:	449c                	lw	a5,8(s1)
    80002fb6:	fef059e3          	blez	a5,80002fa8 <iget+0x34>
    80002fba:	4098                	lw	a4,0(s1)
    80002fbc:	ff3716e3          	bne	a4,s3,80002fa8 <iget+0x34>
    80002fc0:	40d8                	lw	a4,4(s1)
    80002fc2:	ff4713e3          	bne	a4,s4,80002fa8 <iget+0x34>
      ip->ref++;
    80002fc6:	2785                	addiw	a5,a5,1
    80002fc8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80002fca:	0001b517          	auipc	a0,0x1b
    80002fce:	23650513          	addi	a0,a0,566 # 8001e200 <itable>
    80002fd2:	d09fd0ef          	jal	ra,80000cda <release>
      return ip;
    80002fd6:	8926                	mv	s2,s1
    80002fd8:	a02d                	j	80003002 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80002fda:	fbe9                	bnez	a5,80002fac <iget+0x38>
    80002fdc:	8926                	mv	s2,s1
    80002fde:	b7f9                	j	80002fac <iget+0x38>
  if(empty == 0)
    80002fe0:	02090a63          	beqz	s2,80003014 <iget+0xa0>
  ip->dev = dev;
    80002fe4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80002fe8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80002fec:	4785                	li	a5,1
    80002fee:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80002ff2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80002ff6:	0001b517          	auipc	a0,0x1b
    80002ffa:	20a50513          	addi	a0,a0,522 # 8001e200 <itable>
    80002ffe:	cddfd0ef          	jal	ra,80000cda <release>
}
    80003002:	854a                	mv	a0,s2
    80003004:	70a2                	ld	ra,40(sp)
    80003006:	7402                	ld	s0,32(sp)
    80003008:	64e2                	ld	s1,24(sp)
    8000300a:	6942                	ld	s2,16(sp)
    8000300c:	69a2                	ld	s3,8(sp)
    8000300e:	6a02                	ld	s4,0(sp)
    80003010:	6145                	addi	sp,sp,48
    80003012:	8082                	ret
    panic("iget: no inodes");
    80003014:	00004517          	auipc	a0,0x4
    80003018:	6a450513          	addi	a0,a0,1700 # 800076b8 <syscallnames+0x138>
    8000301c:	fc0fd0ef          	jal	ra,800007dc <panic>

0000000080003020 <fsinit>:
fsinit(int dev) {
    80003020:	7179                	addi	sp,sp,-48
    80003022:	f406                	sd	ra,40(sp)
    80003024:	f022                	sd	s0,32(sp)
    80003026:	ec26                	sd	s1,24(sp)
    80003028:	e84a                	sd	s2,16(sp)
    8000302a:	e44e                	sd	s3,8(sp)
    8000302c:	1800                	addi	s0,sp,48
    8000302e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003030:	4585                	li	a1,1
    80003032:	afbff0ef          	jal	ra,80002b2c <bread>
    80003036:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003038:	0001b997          	auipc	s3,0x1b
    8000303c:	1a898993          	addi	s3,s3,424 # 8001e1e0 <sb>
    80003040:	02000613          	li	a2,32
    80003044:	05850593          	addi	a1,a0,88
    80003048:	854e                	mv	a0,s3
    8000304a:	d29fd0ef          	jal	ra,80000d72 <memmove>
  brelse(bp);
    8000304e:	8526                	mv	a0,s1
    80003050:	be5ff0ef          	jal	ra,80002c34 <brelse>
  if(sb.magic != FSMAGIC)
    80003054:	0009a703          	lw	a4,0(s3)
    80003058:	102037b7          	lui	a5,0x10203
    8000305c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003060:	02f71063          	bne	a4,a5,80003080 <fsinit+0x60>
  initlog(dev, &sb);
    80003064:	0001b597          	auipc	a1,0x1b
    80003068:	17c58593          	addi	a1,a1,380 # 8001e1e0 <sb>
    8000306c:	854a                	mv	a0,s2
    8000306e:	1db000ef          	jal	ra,80003a48 <initlog>
}
    80003072:	70a2                	ld	ra,40(sp)
    80003074:	7402                	ld	s0,32(sp)
    80003076:	64e2                	ld	s1,24(sp)
    80003078:	6942                	ld	s2,16(sp)
    8000307a:	69a2                	ld	s3,8(sp)
    8000307c:	6145                	addi	sp,sp,48
    8000307e:	8082                	ret
    panic("invalid file system");
    80003080:	00004517          	auipc	a0,0x4
    80003084:	64850513          	addi	a0,a0,1608 # 800076c8 <syscallnames+0x148>
    80003088:	f54fd0ef          	jal	ra,800007dc <panic>

000000008000308c <iinit>:
{
    8000308c:	7179                	addi	sp,sp,-48
    8000308e:	f406                	sd	ra,40(sp)
    80003090:	f022                	sd	s0,32(sp)
    80003092:	ec26                	sd	s1,24(sp)
    80003094:	e84a                	sd	s2,16(sp)
    80003096:	e44e                	sd	s3,8(sp)
    80003098:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000309a:	00004597          	auipc	a1,0x4
    8000309e:	64658593          	addi	a1,a1,1606 # 800076e0 <syscallnames+0x160>
    800030a2:	0001b517          	auipc	a0,0x1b
    800030a6:	15e50513          	addi	a0,a0,350 # 8001e200 <itable>
    800030aa:	b19fd0ef          	jal	ra,80000bc2 <initlock>
  for(i = 0; i < NINODE; i++) {
    800030ae:	0001b497          	auipc	s1,0x1b
    800030b2:	17a48493          	addi	s1,s1,378 # 8001e228 <itable+0x28>
    800030b6:	0001d997          	auipc	s3,0x1d
    800030ba:	c0298993          	addi	s3,s3,-1022 # 8001fcb8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800030be:	00004917          	auipc	s2,0x4
    800030c2:	62a90913          	addi	s2,s2,1578 # 800076e8 <syscallnames+0x168>
    800030c6:	85ca                	mv	a1,s2
    800030c8:	8526                	mv	a0,s1
    800030ca:	467000ef          	jal	ra,80003d30 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800030ce:	08848493          	addi	s1,s1,136
    800030d2:	ff349ae3          	bne	s1,s3,800030c6 <iinit+0x3a>
}
    800030d6:	70a2                	ld	ra,40(sp)
    800030d8:	7402                	ld	s0,32(sp)
    800030da:	64e2                	ld	s1,24(sp)
    800030dc:	6942                	ld	s2,16(sp)
    800030de:	69a2                	ld	s3,8(sp)
    800030e0:	6145                	addi	sp,sp,48
    800030e2:	8082                	ret

00000000800030e4 <ialloc>:
{
    800030e4:	715d                	addi	sp,sp,-80
    800030e6:	e486                	sd	ra,72(sp)
    800030e8:	e0a2                	sd	s0,64(sp)
    800030ea:	fc26                	sd	s1,56(sp)
    800030ec:	f84a                	sd	s2,48(sp)
    800030ee:	f44e                	sd	s3,40(sp)
    800030f0:	f052                	sd	s4,32(sp)
    800030f2:	ec56                	sd	s5,24(sp)
    800030f4:	e85a                	sd	s6,16(sp)
    800030f6:	e45e                	sd	s7,8(sp)
    800030f8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800030fa:	0001b717          	auipc	a4,0x1b
    800030fe:	0f272703          	lw	a4,242(a4) # 8001e1ec <sb+0xc>
    80003102:	4785                	li	a5,1
    80003104:	04e7f663          	bgeu	a5,a4,80003150 <ialloc+0x6c>
    80003108:	8aaa                	mv	s5,a0
    8000310a:	8bae                	mv	s7,a1
    8000310c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000310e:	0001ba17          	auipc	s4,0x1b
    80003112:	0d2a0a13          	addi	s4,s4,210 # 8001e1e0 <sb>
    80003116:	00048b1b          	sext.w	s6,s1
    8000311a:	0044d793          	srli	a5,s1,0x4
    8000311e:	018a2583          	lw	a1,24(s4)
    80003122:	9dbd                	addw	a1,a1,a5
    80003124:	8556                	mv	a0,s5
    80003126:	a07ff0ef          	jal	ra,80002b2c <bread>
    8000312a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000312c:	05850993          	addi	s3,a0,88
    80003130:	00f4f793          	andi	a5,s1,15
    80003134:	079a                	slli	a5,a5,0x6
    80003136:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003138:	00099783          	lh	a5,0(s3)
    8000313c:	cf85                	beqz	a5,80003174 <ialloc+0x90>
    brelse(bp);
    8000313e:	af7ff0ef          	jal	ra,80002c34 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003142:	0485                	addi	s1,s1,1
    80003144:	00ca2703          	lw	a4,12(s4)
    80003148:	0004879b          	sext.w	a5,s1
    8000314c:	fce7e5e3          	bltu	a5,a4,80003116 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003150:	00004517          	auipc	a0,0x4
    80003154:	5a050513          	addi	a0,a0,1440 # 800076f0 <syscallnames+0x170>
    80003158:	b4afd0ef          	jal	ra,800004a2 <printf>
  return 0;
    8000315c:	4501                	li	a0,0
}
    8000315e:	60a6                	ld	ra,72(sp)
    80003160:	6406                	ld	s0,64(sp)
    80003162:	74e2                	ld	s1,56(sp)
    80003164:	7942                	ld	s2,48(sp)
    80003166:	79a2                	ld	s3,40(sp)
    80003168:	7a02                	ld	s4,32(sp)
    8000316a:	6ae2                	ld	s5,24(sp)
    8000316c:	6b42                	ld	s6,16(sp)
    8000316e:	6ba2                	ld	s7,8(sp)
    80003170:	6161                	addi	sp,sp,80
    80003172:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003174:	04000613          	li	a2,64
    80003178:	4581                	li	a1,0
    8000317a:	854e                	mv	a0,s3
    8000317c:	b9bfd0ef          	jal	ra,80000d16 <memset>
      dip->type = type;
    80003180:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003184:	854a                	mv	a0,s2
    80003186:	2d9000ef          	jal	ra,80003c5e <log_write>
      brelse(bp);
    8000318a:	854a                	mv	a0,s2
    8000318c:	aa9ff0ef          	jal	ra,80002c34 <brelse>
      return iget(dev, inum);
    80003190:	85da                	mv	a1,s6
    80003192:	8556                	mv	a0,s5
    80003194:	de1ff0ef          	jal	ra,80002f74 <iget>
    80003198:	b7d9                	j	8000315e <ialloc+0x7a>

000000008000319a <iupdate>:
{
    8000319a:	1101                	addi	sp,sp,-32
    8000319c:	ec06                	sd	ra,24(sp)
    8000319e:	e822                	sd	s0,16(sp)
    800031a0:	e426                	sd	s1,8(sp)
    800031a2:	e04a                	sd	s2,0(sp)
    800031a4:	1000                	addi	s0,sp,32
    800031a6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800031a8:	415c                	lw	a5,4(a0)
    800031aa:	0047d79b          	srliw	a5,a5,0x4
    800031ae:	0001b597          	auipc	a1,0x1b
    800031b2:	04a5a583          	lw	a1,74(a1) # 8001e1f8 <sb+0x18>
    800031b6:	9dbd                	addw	a1,a1,a5
    800031b8:	4108                	lw	a0,0(a0)
    800031ba:	973ff0ef          	jal	ra,80002b2c <bread>
    800031be:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800031c0:	05850793          	addi	a5,a0,88
    800031c4:	40c8                	lw	a0,4(s1)
    800031c6:	893d                	andi	a0,a0,15
    800031c8:	051a                	slli	a0,a0,0x6
    800031ca:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800031cc:	04449703          	lh	a4,68(s1)
    800031d0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800031d4:	04649703          	lh	a4,70(s1)
    800031d8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800031dc:	04849703          	lh	a4,72(s1)
    800031e0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800031e4:	04a49703          	lh	a4,74(s1)
    800031e8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800031ec:	44f8                	lw	a4,76(s1)
    800031ee:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800031f0:	03400613          	li	a2,52
    800031f4:	05048593          	addi	a1,s1,80
    800031f8:	0531                	addi	a0,a0,12
    800031fa:	b79fd0ef          	jal	ra,80000d72 <memmove>
  log_write(bp);
    800031fe:	854a                	mv	a0,s2
    80003200:	25f000ef          	jal	ra,80003c5e <log_write>
  brelse(bp);
    80003204:	854a                	mv	a0,s2
    80003206:	a2fff0ef          	jal	ra,80002c34 <brelse>
}
    8000320a:	60e2                	ld	ra,24(sp)
    8000320c:	6442                	ld	s0,16(sp)
    8000320e:	64a2                	ld	s1,8(sp)
    80003210:	6902                	ld	s2,0(sp)
    80003212:	6105                	addi	sp,sp,32
    80003214:	8082                	ret

0000000080003216 <idup>:
{
    80003216:	1101                	addi	sp,sp,-32
    80003218:	ec06                	sd	ra,24(sp)
    8000321a:	e822                	sd	s0,16(sp)
    8000321c:	e426                	sd	s1,8(sp)
    8000321e:	1000                	addi	s0,sp,32
    80003220:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003222:	0001b517          	auipc	a0,0x1b
    80003226:	fde50513          	addi	a0,a0,-34 # 8001e200 <itable>
    8000322a:	a19fd0ef          	jal	ra,80000c42 <acquire>
  ip->ref++;
    8000322e:	449c                	lw	a5,8(s1)
    80003230:	2785                	addiw	a5,a5,1
    80003232:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003234:	0001b517          	auipc	a0,0x1b
    80003238:	fcc50513          	addi	a0,a0,-52 # 8001e200 <itable>
    8000323c:	a9ffd0ef          	jal	ra,80000cda <release>
}
    80003240:	8526                	mv	a0,s1
    80003242:	60e2                	ld	ra,24(sp)
    80003244:	6442                	ld	s0,16(sp)
    80003246:	64a2                	ld	s1,8(sp)
    80003248:	6105                	addi	sp,sp,32
    8000324a:	8082                	ret

000000008000324c <ilock>:
{
    8000324c:	1101                	addi	sp,sp,-32
    8000324e:	ec06                	sd	ra,24(sp)
    80003250:	e822                	sd	s0,16(sp)
    80003252:	e426                	sd	s1,8(sp)
    80003254:	e04a                	sd	s2,0(sp)
    80003256:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003258:	c105                	beqz	a0,80003278 <ilock+0x2c>
    8000325a:	84aa                	mv	s1,a0
    8000325c:	451c                	lw	a5,8(a0)
    8000325e:	00f05d63          	blez	a5,80003278 <ilock+0x2c>
  acquiresleep(&ip->lock);
    80003262:	0541                	addi	a0,a0,16
    80003264:	303000ef          	jal	ra,80003d66 <acquiresleep>
  if(ip->valid == 0){
    80003268:	40bc                	lw	a5,64(s1)
    8000326a:	cf89                	beqz	a5,80003284 <ilock+0x38>
}
    8000326c:	60e2                	ld	ra,24(sp)
    8000326e:	6442                	ld	s0,16(sp)
    80003270:	64a2                	ld	s1,8(sp)
    80003272:	6902                	ld	s2,0(sp)
    80003274:	6105                	addi	sp,sp,32
    80003276:	8082                	ret
    panic("ilock");
    80003278:	00004517          	auipc	a0,0x4
    8000327c:	49050513          	addi	a0,a0,1168 # 80007708 <syscallnames+0x188>
    80003280:	d5cfd0ef          	jal	ra,800007dc <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003284:	40dc                	lw	a5,4(s1)
    80003286:	0047d79b          	srliw	a5,a5,0x4
    8000328a:	0001b597          	auipc	a1,0x1b
    8000328e:	f6e5a583          	lw	a1,-146(a1) # 8001e1f8 <sb+0x18>
    80003292:	9dbd                	addw	a1,a1,a5
    80003294:	4088                	lw	a0,0(s1)
    80003296:	897ff0ef          	jal	ra,80002b2c <bread>
    8000329a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000329c:	05850593          	addi	a1,a0,88
    800032a0:	40dc                	lw	a5,4(s1)
    800032a2:	8bbd                	andi	a5,a5,15
    800032a4:	079a                	slli	a5,a5,0x6
    800032a6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800032a8:	00059783          	lh	a5,0(a1)
    800032ac:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800032b0:	00259783          	lh	a5,2(a1)
    800032b4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800032b8:	00459783          	lh	a5,4(a1)
    800032bc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800032c0:	00659783          	lh	a5,6(a1)
    800032c4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800032c8:	459c                	lw	a5,8(a1)
    800032ca:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800032cc:	03400613          	li	a2,52
    800032d0:	05b1                	addi	a1,a1,12
    800032d2:	05048513          	addi	a0,s1,80
    800032d6:	a9dfd0ef          	jal	ra,80000d72 <memmove>
    brelse(bp);
    800032da:	854a                	mv	a0,s2
    800032dc:	959ff0ef          	jal	ra,80002c34 <brelse>
    ip->valid = 1;
    800032e0:	4785                	li	a5,1
    800032e2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800032e4:	04449783          	lh	a5,68(s1)
    800032e8:	f3d1                	bnez	a5,8000326c <ilock+0x20>
      panic("ilock: no type");
    800032ea:	00004517          	auipc	a0,0x4
    800032ee:	42650513          	addi	a0,a0,1062 # 80007710 <syscallnames+0x190>
    800032f2:	ceafd0ef          	jal	ra,800007dc <panic>

00000000800032f6 <iunlock>:
{
    800032f6:	1101                	addi	sp,sp,-32
    800032f8:	ec06                	sd	ra,24(sp)
    800032fa:	e822                	sd	s0,16(sp)
    800032fc:	e426                	sd	s1,8(sp)
    800032fe:	e04a                	sd	s2,0(sp)
    80003300:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003302:	c505                	beqz	a0,8000332a <iunlock+0x34>
    80003304:	84aa                	mv	s1,a0
    80003306:	01050913          	addi	s2,a0,16
    8000330a:	854a                	mv	a0,s2
    8000330c:	2d9000ef          	jal	ra,80003de4 <holdingsleep>
    80003310:	cd09                	beqz	a0,8000332a <iunlock+0x34>
    80003312:	449c                	lw	a5,8(s1)
    80003314:	00f05b63          	blez	a5,8000332a <iunlock+0x34>
  releasesleep(&ip->lock);
    80003318:	854a                	mv	a0,s2
    8000331a:	293000ef          	jal	ra,80003dac <releasesleep>
}
    8000331e:	60e2                	ld	ra,24(sp)
    80003320:	6442                	ld	s0,16(sp)
    80003322:	64a2                	ld	s1,8(sp)
    80003324:	6902                	ld	s2,0(sp)
    80003326:	6105                	addi	sp,sp,32
    80003328:	8082                	ret
    panic("iunlock");
    8000332a:	00004517          	auipc	a0,0x4
    8000332e:	3f650513          	addi	a0,a0,1014 # 80007720 <syscallnames+0x1a0>
    80003332:	caafd0ef          	jal	ra,800007dc <panic>

0000000080003336 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003336:	7179                	addi	sp,sp,-48
    80003338:	f406                	sd	ra,40(sp)
    8000333a:	f022                	sd	s0,32(sp)
    8000333c:	ec26                	sd	s1,24(sp)
    8000333e:	e84a                	sd	s2,16(sp)
    80003340:	e44e                	sd	s3,8(sp)
    80003342:	e052                	sd	s4,0(sp)
    80003344:	1800                	addi	s0,sp,48
    80003346:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003348:	05050493          	addi	s1,a0,80
    8000334c:	08050913          	addi	s2,a0,128
    80003350:	a021                	j	80003358 <itrunc+0x22>
    80003352:	0491                	addi	s1,s1,4
    80003354:	01248b63          	beq	s1,s2,8000336a <itrunc+0x34>
    if(ip->addrs[i]){
    80003358:	408c                	lw	a1,0(s1)
    8000335a:	dde5                	beqz	a1,80003352 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000335c:	0009a503          	lw	a0,0(s3)
    80003360:	9c7ff0ef          	jal	ra,80002d26 <bfree>
      ip->addrs[i] = 0;
    80003364:	0004a023          	sw	zero,0(s1)
    80003368:	b7ed                	j	80003352 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000336a:	0809a583          	lw	a1,128(s3)
    8000336e:	ed91                	bnez	a1,8000338a <itrunc+0x54>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003370:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003374:	854e                	mv	a0,s3
    80003376:	e25ff0ef          	jal	ra,8000319a <iupdate>
}
    8000337a:	70a2                	ld	ra,40(sp)
    8000337c:	7402                	ld	s0,32(sp)
    8000337e:	64e2                	ld	s1,24(sp)
    80003380:	6942                	ld	s2,16(sp)
    80003382:	69a2                	ld	s3,8(sp)
    80003384:	6a02                	ld	s4,0(sp)
    80003386:	6145                	addi	sp,sp,48
    80003388:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000338a:	0009a503          	lw	a0,0(s3)
    8000338e:	f9eff0ef          	jal	ra,80002b2c <bread>
    80003392:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003394:	05850493          	addi	s1,a0,88
    80003398:	45850913          	addi	s2,a0,1112
    8000339c:	a021                	j	800033a4 <itrunc+0x6e>
    8000339e:	0491                	addi	s1,s1,4
    800033a0:	01248963          	beq	s1,s2,800033b2 <itrunc+0x7c>
      if(a[j])
    800033a4:	408c                	lw	a1,0(s1)
    800033a6:	dde5                	beqz	a1,8000339e <itrunc+0x68>
        bfree(ip->dev, a[j]);
    800033a8:	0009a503          	lw	a0,0(s3)
    800033ac:	97bff0ef          	jal	ra,80002d26 <bfree>
    800033b0:	b7fd                	j	8000339e <itrunc+0x68>
    brelse(bp);
    800033b2:	8552                	mv	a0,s4
    800033b4:	881ff0ef          	jal	ra,80002c34 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800033b8:	0809a583          	lw	a1,128(s3)
    800033bc:	0009a503          	lw	a0,0(s3)
    800033c0:	967ff0ef          	jal	ra,80002d26 <bfree>
    ip->addrs[NDIRECT] = 0;
    800033c4:	0809a023          	sw	zero,128(s3)
    800033c8:	b765                	j	80003370 <itrunc+0x3a>

00000000800033ca <iput>:
{
    800033ca:	1101                	addi	sp,sp,-32
    800033cc:	ec06                	sd	ra,24(sp)
    800033ce:	e822                	sd	s0,16(sp)
    800033d0:	e426                	sd	s1,8(sp)
    800033d2:	e04a                	sd	s2,0(sp)
    800033d4:	1000                	addi	s0,sp,32
    800033d6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800033d8:	0001b517          	auipc	a0,0x1b
    800033dc:	e2850513          	addi	a0,a0,-472 # 8001e200 <itable>
    800033e0:	863fd0ef          	jal	ra,80000c42 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800033e4:	4498                	lw	a4,8(s1)
    800033e6:	4785                	li	a5,1
    800033e8:	02f70163          	beq	a4,a5,8000340a <iput+0x40>
  ip->ref--;
    800033ec:	449c                	lw	a5,8(s1)
    800033ee:	37fd                	addiw	a5,a5,-1
    800033f0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800033f2:	0001b517          	auipc	a0,0x1b
    800033f6:	e0e50513          	addi	a0,a0,-498 # 8001e200 <itable>
    800033fa:	8e1fd0ef          	jal	ra,80000cda <release>
}
    800033fe:	60e2                	ld	ra,24(sp)
    80003400:	6442                	ld	s0,16(sp)
    80003402:	64a2                	ld	s1,8(sp)
    80003404:	6902                	ld	s2,0(sp)
    80003406:	6105                	addi	sp,sp,32
    80003408:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000340a:	40bc                	lw	a5,64(s1)
    8000340c:	d3e5                	beqz	a5,800033ec <iput+0x22>
    8000340e:	04a49783          	lh	a5,74(s1)
    80003412:	ffe9                	bnez	a5,800033ec <iput+0x22>
    acquiresleep(&ip->lock);
    80003414:	01048913          	addi	s2,s1,16
    80003418:	854a                	mv	a0,s2
    8000341a:	14d000ef          	jal	ra,80003d66 <acquiresleep>
    release(&itable.lock);
    8000341e:	0001b517          	auipc	a0,0x1b
    80003422:	de250513          	addi	a0,a0,-542 # 8001e200 <itable>
    80003426:	8b5fd0ef          	jal	ra,80000cda <release>
    itrunc(ip);
    8000342a:	8526                	mv	a0,s1
    8000342c:	f0bff0ef          	jal	ra,80003336 <itrunc>
    ip->type = 0;
    80003430:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003434:	8526                	mv	a0,s1
    80003436:	d65ff0ef          	jal	ra,8000319a <iupdate>
    ip->valid = 0;
    8000343a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000343e:	854a                	mv	a0,s2
    80003440:	16d000ef          	jal	ra,80003dac <releasesleep>
    acquire(&itable.lock);
    80003444:	0001b517          	auipc	a0,0x1b
    80003448:	dbc50513          	addi	a0,a0,-580 # 8001e200 <itable>
    8000344c:	ff6fd0ef          	jal	ra,80000c42 <acquire>
    80003450:	bf71                	j	800033ec <iput+0x22>

0000000080003452 <iunlockput>:
{
    80003452:	1101                	addi	sp,sp,-32
    80003454:	ec06                	sd	ra,24(sp)
    80003456:	e822                	sd	s0,16(sp)
    80003458:	e426                	sd	s1,8(sp)
    8000345a:	1000                	addi	s0,sp,32
    8000345c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000345e:	e99ff0ef          	jal	ra,800032f6 <iunlock>
  iput(ip);
    80003462:	8526                	mv	a0,s1
    80003464:	f67ff0ef          	jal	ra,800033ca <iput>
}
    80003468:	60e2                	ld	ra,24(sp)
    8000346a:	6442                	ld	s0,16(sp)
    8000346c:	64a2                	ld	s1,8(sp)
    8000346e:	6105                	addi	sp,sp,32
    80003470:	8082                	ret

0000000080003472 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003472:	1141                	addi	sp,sp,-16
    80003474:	e422                	sd	s0,8(sp)
    80003476:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003478:	411c                	lw	a5,0(a0)
    8000347a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000347c:	415c                	lw	a5,4(a0)
    8000347e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003480:	04451783          	lh	a5,68(a0)
    80003484:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003488:	04a51783          	lh	a5,74(a0)
    8000348c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003490:	04c56783          	lwu	a5,76(a0)
    80003494:	e99c                	sd	a5,16(a1)
}
    80003496:	6422                	ld	s0,8(sp)
    80003498:	0141                	addi	sp,sp,16
    8000349a:	8082                	ret

000000008000349c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000349c:	457c                	lw	a5,76(a0)
    8000349e:	0cd7ef63          	bltu	a5,a3,8000357c <readi+0xe0>
{
    800034a2:	7159                	addi	sp,sp,-112
    800034a4:	f486                	sd	ra,104(sp)
    800034a6:	f0a2                	sd	s0,96(sp)
    800034a8:	eca6                	sd	s1,88(sp)
    800034aa:	e8ca                	sd	s2,80(sp)
    800034ac:	e4ce                	sd	s3,72(sp)
    800034ae:	e0d2                	sd	s4,64(sp)
    800034b0:	fc56                	sd	s5,56(sp)
    800034b2:	f85a                	sd	s6,48(sp)
    800034b4:	f45e                	sd	s7,40(sp)
    800034b6:	f062                	sd	s8,32(sp)
    800034b8:	ec66                	sd	s9,24(sp)
    800034ba:	e86a                	sd	s10,16(sp)
    800034bc:	e46e                	sd	s11,8(sp)
    800034be:	1880                	addi	s0,sp,112
    800034c0:	8b2a                	mv	s6,a0
    800034c2:	8bae                	mv	s7,a1
    800034c4:	8a32                	mv	s4,a2
    800034c6:	84b6                	mv	s1,a3
    800034c8:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800034ca:	9f35                	addw	a4,a4,a3
    return 0;
    800034cc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800034ce:	08d76663          	bltu	a4,a3,8000355a <readi+0xbe>
  if(off + n > ip->size)
    800034d2:	00e7f463          	bgeu	a5,a4,800034da <readi+0x3e>
    n = ip->size - off;
    800034d6:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800034da:	080a8f63          	beqz	s5,80003578 <readi+0xdc>
    800034de:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800034e0:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800034e4:	5c7d                	li	s8,-1
    800034e6:	a80d                	j	80003518 <readi+0x7c>
    800034e8:	020d1d93          	slli	s11,s10,0x20
    800034ec:	020ddd93          	srli	s11,s11,0x20
    800034f0:	05890793          	addi	a5,s2,88
    800034f4:	86ee                	mv	a3,s11
    800034f6:	963e                	add	a2,a2,a5
    800034f8:	85d2                	mv	a1,s4
    800034fa:	855e                	mv	a0,s7
    800034fc:	d21fe0ef          	jal	ra,8000221c <either_copyout>
    80003500:	05850763          	beq	a0,s8,8000354e <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003504:	854a                	mv	a0,s2
    80003506:	f2eff0ef          	jal	ra,80002c34 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000350a:	013d09bb          	addw	s3,s10,s3
    8000350e:	009d04bb          	addw	s1,s10,s1
    80003512:	9a6e                	add	s4,s4,s11
    80003514:	0559f163          	bgeu	s3,s5,80003556 <readi+0xba>
    uint addr = bmap(ip, off/BSIZE);
    80003518:	00a4d59b          	srliw	a1,s1,0xa
    8000351c:	855a                	mv	a0,s6
    8000351e:	989ff0ef          	jal	ra,80002ea6 <bmap>
    80003522:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003526:	c985                	beqz	a1,80003556 <readi+0xba>
    bp = bread(ip->dev, addr);
    80003528:	000b2503          	lw	a0,0(s6)
    8000352c:	e00ff0ef          	jal	ra,80002b2c <bread>
    80003530:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003532:	3ff4f613          	andi	a2,s1,1023
    80003536:	40cc87bb          	subw	a5,s9,a2
    8000353a:	413a873b          	subw	a4,s5,s3
    8000353e:	8d3e                	mv	s10,a5
    80003540:	2781                	sext.w	a5,a5
    80003542:	0007069b          	sext.w	a3,a4
    80003546:	faf6f1e3          	bgeu	a3,a5,800034e8 <readi+0x4c>
    8000354a:	8d3a                	mv	s10,a4
    8000354c:	bf71                	j	800034e8 <readi+0x4c>
      brelse(bp);
    8000354e:	854a                	mv	a0,s2
    80003550:	ee4ff0ef          	jal	ra,80002c34 <brelse>
      tot = -1;
    80003554:	59fd                	li	s3,-1
  }
  return tot;
    80003556:	0009851b          	sext.w	a0,s3
}
    8000355a:	70a6                	ld	ra,104(sp)
    8000355c:	7406                	ld	s0,96(sp)
    8000355e:	64e6                	ld	s1,88(sp)
    80003560:	6946                	ld	s2,80(sp)
    80003562:	69a6                	ld	s3,72(sp)
    80003564:	6a06                	ld	s4,64(sp)
    80003566:	7ae2                	ld	s5,56(sp)
    80003568:	7b42                	ld	s6,48(sp)
    8000356a:	7ba2                	ld	s7,40(sp)
    8000356c:	7c02                	ld	s8,32(sp)
    8000356e:	6ce2                	ld	s9,24(sp)
    80003570:	6d42                	ld	s10,16(sp)
    80003572:	6da2                	ld	s11,8(sp)
    80003574:	6165                	addi	sp,sp,112
    80003576:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003578:	89d6                	mv	s3,s5
    8000357a:	bff1                	j	80003556 <readi+0xba>
    return 0;
    8000357c:	4501                	li	a0,0
}
    8000357e:	8082                	ret

0000000080003580 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003580:	457c                	lw	a5,76(a0)
    80003582:	0ed7ea63          	bltu	a5,a3,80003676 <writei+0xf6>
{
    80003586:	7159                	addi	sp,sp,-112
    80003588:	f486                	sd	ra,104(sp)
    8000358a:	f0a2                	sd	s0,96(sp)
    8000358c:	eca6                	sd	s1,88(sp)
    8000358e:	e8ca                	sd	s2,80(sp)
    80003590:	e4ce                	sd	s3,72(sp)
    80003592:	e0d2                	sd	s4,64(sp)
    80003594:	fc56                	sd	s5,56(sp)
    80003596:	f85a                	sd	s6,48(sp)
    80003598:	f45e                	sd	s7,40(sp)
    8000359a:	f062                	sd	s8,32(sp)
    8000359c:	ec66                	sd	s9,24(sp)
    8000359e:	e86a                	sd	s10,16(sp)
    800035a0:	e46e                	sd	s11,8(sp)
    800035a2:	1880                	addi	s0,sp,112
    800035a4:	8aaa                	mv	s5,a0
    800035a6:	8bae                	mv	s7,a1
    800035a8:	8a32                	mv	s4,a2
    800035aa:	8936                	mv	s2,a3
    800035ac:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800035ae:	00e687bb          	addw	a5,a3,a4
    800035b2:	0cd7e463          	bltu	a5,a3,8000367a <writei+0xfa>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800035b6:	00043737          	lui	a4,0x43
    800035ba:	0cf76263          	bltu	a4,a5,8000367e <writei+0xfe>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800035be:	0a0b0a63          	beqz	s6,80003672 <writei+0xf2>
    800035c2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800035c4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800035c8:	5c7d                	li	s8,-1
    800035ca:	a825                	j	80003602 <writei+0x82>
    800035cc:	020d1d93          	slli	s11,s10,0x20
    800035d0:	020ddd93          	srli	s11,s11,0x20
    800035d4:	05848793          	addi	a5,s1,88
    800035d8:	86ee                	mv	a3,s11
    800035da:	8652                	mv	a2,s4
    800035dc:	85de                	mv	a1,s7
    800035de:	953e                	add	a0,a0,a5
    800035e0:	c87fe0ef          	jal	ra,80002266 <either_copyin>
    800035e4:	05850a63          	beq	a0,s8,80003638 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    800035e8:	8526                	mv	a0,s1
    800035ea:	674000ef          	jal	ra,80003c5e <log_write>
    brelse(bp);
    800035ee:	8526                	mv	a0,s1
    800035f0:	e44ff0ef          	jal	ra,80002c34 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800035f4:	013d09bb          	addw	s3,s10,s3
    800035f8:	012d093b          	addw	s2,s10,s2
    800035fc:	9a6e                	add	s4,s4,s11
    800035fe:	0569f063          	bgeu	s3,s6,8000363e <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    80003602:	00a9559b          	srliw	a1,s2,0xa
    80003606:	8556                	mv	a0,s5
    80003608:	89fff0ef          	jal	ra,80002ea6 <bmap>
    8000360c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003610:	c59d                	beqz	a1,8000363e <writei+0xbe>
    bp = bread(ip->dev, addr);
    80003612:	000aa503          	lw	a0,0(s5)
    80003616:	d16ff0ef          	jal	ra,80002b2c <bread>
    8000361a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000361c:	3ff97513          	andi	a0,s2,1023
    80003620:	40ac87bb          	subw	a5,s9,a0
    80003624:	413b073b          	subw	a4,s6,s3
    80003628:	8d3e                	mv	s10,a5
    8000362a:	2781                	sext.w	a5,a5
    8000362c:	0007069b          	sext.w	a3,a4
    80003630:	f8f6fee3          	bgeu	a3,a5,800035cc <writei+0x4c>
    80003634:	8d3a                	mv	s10,a4
    80003636:	bf59                	j	800035cc <writei+0x4c>
      brelse(bp);
    80003638:	8526                	mv	a0,s1
    8000363a:	dfaff0ef          	jal	ra,80002c34 <brelse>
  }

  if(off > ip->size)
    8000363e:	04caa783          	lw	a5,76(s5)
    80003642:	0127f463          	bgeu	a5,s2,8000364a <writei+0xca>
    ip->size = off;
    80003646:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000364a:	8556                	mv	a0,s5
    8000364c:	b4fff0ef          	jal	ra,8000319a <iupdate>

  return tot;
    80003650:	0009851b          	sext.w	a0,s3
}
    80003654:	70a6                	ld	ra,104(sp)
    80003656:	7406                	ld	s0,96(sp)
    80003658:	64e6                	ld	s1,88(sp)
    8000365a:	6946                	ld	s2,80(sp)
    8000365c:	69a6                	ld	s3,72(sp)
    8000365e:	6a06                	ld	s4,64(sp)
    80003660:	7ae2                	ld	s5,56(sp)
    80003662:	7b42                	ld	s6,48(sp)
    80003664:	7ba2                	ld	s7,40(sp)
    80003666:	7c02                	ld	s8,32(sp)
    80003668:	6ce2                	ld	s9,24(sp)
    8000366a:	6d42                	ld	s10,16(sp)
    8000366c:	6da2                	ld	s11,8(sp)
    8000366e:	6165                	addi	sp,sp,112
    80003670:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003672:	89da                	mv	s3,s6
    80003674:	bfd9                	j	8000364a <writei+0xca>
    return -1;
    80003676:	557d                	li	a0,-1
}
    80003678:	8082                	ret
    return -1;
    8000367a:	557d                	li	a0,-1
    8000367c:	bfe1                	j	80003654 <writei+0xd4>
    return -1;
    8000367e:	557d                	li	a0,-1
    80003680:	bfd1                	j	80003654 <writei+0xd4>

0000000080003682 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003682:	1141                	addi	sp,sp,-16
    80003684:	e406                	sd	ra,8(sp)
    80003686:	e022                	sd	s0,0(sp)
    80003688:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000368a:	4639                	li	a2,14
    8000368c:	f56fd0ef          	jal	ra,80000de2 <strncmp>
}
    80003690:	60a2                	ld	ra,8(sp)
    80003692:	6402                	ld	s0,0(sp)
    80003694:	0141                	addi	sp,sp,16
    80003696:	8082                	ret

0000000080003698 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003698:	7139                	addi	sp,sp,-64
    8000369a:	fc06                	sd	ra,56(sp)
    8000369c:	f822                	sd	s0,48(sp)
    8000369e:	f426                	sd	s1,40(sp)
    800036a0:	f04a                	sd	s2,32(sp)
    800036a2:	ec4e                	sd	s3,24(sp)
    800036a4:	e852                	sd	s4,16(sp)
    800036a6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800036a8:	04451703          	lh	a4,68(a0)
    800036ac:	4785                	li	a5,1
    800036ae:	00f71a63          	bne	a4,a5,800036c2 <dirlookup+0x2a>
    800036b2:	892a                	mv	s2,a0
    800036b4:	89ae                	mv	s3,a1
    800036b6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800036b8:	457c                	lw	a5,76(a0)
    800036ba:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800036bc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800036be:	e39d                	bnez	a5,800036e4 <dirlookup+0x4c>
    800036c0:	a095                	j	80003724 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    800036c2:	00004517          	auipc	a0,0x4
    800036c6:	06650513          	addi	a0,a0,102 # 80007728 <syscallnames+0x1a8>
    800036ca:	912fd0ef          	jal	ra,800007dc <panic>
      panic("dirlookup read");
    800036ce:	00004517          	auipc	a0,0x4
    800036d2:	07250513          	addi	a0,a0,114 # 80007740 <syscallnames+0x1c0>
    800036d6:	906fd0ef          	jal	ra,800007dc <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800036da:	24c1                	addiw	s1,s1,16
    800036dc:	04c92783          	lw	a5,76(s2)
    800036e0:	04f4f163          	bgeu	s1,a5,80003722 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800036e4:	4741                	li	a4,16
    800036e6:	86a6                	mv	a3,s1
    800036e8:	fc040613          	addi	a2,s0,-64
    800036ec:	4581                	li	a1,0
    800036ee:	854a                	mv	a0,s2
    800036f0:	dadff0ef          	jal	ra,8000349c <readi>
    800036f4:	47c1                	li	a5,16
    800036f6:	fcf51ce3          	bne	a0,a5,800036ce <dirlookup+0x36>
    if(de.inum == 0)
    800036fa:	fc045783          	lhu	a5,-64(s0)
    800036fe:	dff1                	beqz	a5,800036da <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003700:	fc240593          	addi	a1,s0,-62
    80003704:	854e                	mv	a0,s3
    80003706:	f7dff0ef          	jal	ra,80003682 <namecmp>
    8000370a:	f961                	bnez	a0,800036da <dirlookup+0x42>
      if(poff)
    8000370c:	000a0463          	beqz	s4,80003714 <dirlookup+0x7c>
        *poff = off;
    80003710:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003714:	fc045583          	lhu	a1,-64(s0)
    80003718:	00092503          	lw	a0,0(s2)
    8000371c:	859ff0ef          	jal	ra,80002f74 <iget>
    80003720:	a011                	j	80003724 <dirlookup+0x8c>
  return 0;
    80003722:	4501                	li	a0,0
}
    80003724:	70e2                	ld	ra,56(sp)
    80003726:	7442                	ld	s0,48(sp)
    80003728:	74a2                	ld	s1,40(sp)
    8000372a:	7902                	ld	s2,32(sp)
    8000372c:	69e2                	ld	s3,24(sp)
    8000372e:	6a42                	ld	s4,16(sp)
    80003730:	6121                	addi	sp,sp,64
    80003732:	8082                	ret

0000000080003734 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003734:	711d                	addi	sp,sp,-96
    80003736:	ec86                	sd	ra,88(sp)
    80003738:	e8a2                	sd	s0,80(sp)
    8000373a:	e4a6                	sd	s1,72(sp)
    8000373c:	e0ca                	sd	s2,64(sp)
    8000373e:	fc4e                	sd	s3,56(sp)
    80003740:	f852                	sd	s4,48(sp)
    80003742:	f456                	sd	s5,40(sp)
    80003744:	f05a                	sd	s6,32(sp)
    80003746:	ec5e                	sd	s7,24(sp)
    80003748:	e862                	sd	s8,16(sp)
    8000374a:	e466                	sd	s9,8(sp)
    8000374c:	1080                	addi	s0,sp,96
    8000374e:	84aa                	mv	s1,a0
    80003750:	8aae                	mv	s5,a1
    80003752:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003754:	00054703          	lbu	a4,0(a0)
    80003758:	02f00793          	li	a5,47
    8000375c:	00f70f63          	beq	a4,a5,8000377a <namex+0x46>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003760:	97afe0ef          	jal	ra,800018da <myproc>
    80003764:	15853503          	ld	a0,344(a0)
    80003768:	aafff0ef          	jal	ra,80003216 <idup>
    8000376c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000376e:	02f00913          	li	s2,47
  len = path - s;
    80003772:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003774:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003776:	4b85                	li	s7,1
    80003778:	a861                	j	80003810 <namex+0xdc>
    ip = iget(ROOTDEV, ROOTINO);
    8000377a:	4585                	li	a1,1
    8000377c:	4505                	li	a0,1
    8000377e:	ff6ff0ef          	jal	ra,80002f74 <iget>
    80003782:	89aa                	mv	s3,a0
    80003784:	b7ed                	j	8000376e <namex+0x3a>
      iunlockput(ip);
    80003786:	854e                	mv	a0,s3
    80003788:	ccbff0ef          	jal	ra,80003452 <iunlockput>
      return 0;
    8000378c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000378e:	854e                	mv	a0,s3
    80003790:	60e6                	ld	ra,88(sp)
    80003792:	6446                	ld	s0,80(sp)
    80003794:	64a6                	ld	s1,72(sp)
    80003796:	6906                	ld	s2,64(sp)
    80003798:	79e2                	ld	s3,56(sp)
    8000379a:	7a42                	ld	s4,48(sp)
    8000379c:	7aa2                	ld	s5,40(sp)
    8000379e:	7b02                	ld	s6,32(sp)
    800037a0:	6be2                	ld	s7,24(sp)
    800037a2:	6c42                	ld	s8,16(sp)
    800037a4:	6ca2                	ld	s9,8(sp)
    800037a6:	6125                	addi	sp,sp,96
    800037a8:	8082                	ret
      iunlock(ip);
    800037aa:	854e                	mv	a0,s3
    800037ac:	b4bff0ef          	jal	ra,800032f6 <iunlock>
      return ip;
    800037b0:	bff9                	j	8000378e <namex+0x5a>
      iunlockput(ip);
    800037b2:	854e                	mv	a0,s3
    800037b4:	c9fff0ef          	jal	ra,80003452 <iunlockput>
      return 0;
    800037b8:	89e6                	mv	s3,s9
    800037ba:	bfd1                	j	8000378e <namex+0x5a>
  len = path - s;
    800037bc:	40b48633          	sub	a2,s1,a1
    800037c0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800037c4:	079c5c63          	bge	s8,s9,8000383c <namex+0x108>
    memmove(name, s, DIRSIZ);
    800037c8:	4639                	li	a2,14
    800037ca:	8552                	mv	a0,s4
    800037cc:	da6fd0ef          	jal	ra,80000d72 <memmove>
  while(*path == '/')
    800037d0:	0004c783          	lbu	a5,0(s1)
    800037d4:	01279763          	bne	a5,s2,800037e2 <namex+0xae>
    path++;
    800037d8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800037da:	0004c783          	lbu	a5,0(s1)
    800037de:	ff278de3          	beq	a5,s2,800037d8 <namex+0xa4>
    ilock(ip);
    800037e2:	854e                	mv	a0,s3
    800037e4:	a69ff0ef          	jal	ra,8000324c <ilock>
    if(ip->type != T_DIR){
    800037e8:	04499783          	lh	a5,68(s3)
    800037ec:	f9779de3          	bne	a5,s7,80003786 <namex+0x52>
    if(nameiparent && *path == '\0'){
    800037f0:	000a8563          	beqz	s5,800037fa <namex+0xc6>
    800037f4:	0004c783          	lbu	a5,0(s1)
    800037f8:	dbcd                	beqz	a5,800037aa <namex+0x76>
    if((next = dirlookup(ip, name, 0)) == 0){
    800037fa:	865a                	mv	a2,s6
    800037fc:	85d2                	mv	a1,s4
    800037fe:	854e                	mv	a0,s3
    80003800:	e99ff0ef          	jal	ra,80003698 <dirlookup>
    80003804:	8caa                	mv	s9,a0
    80003806:	d555                	beqz	a0,800037b2 <namex+0x7e>
    iunlockput(ip);
    80003808:	854e                	mv	a0,s3
    8000380a:	c49ff0ef          	jal	ra,80003452 <iunlockput>
    ip = next;
    8000380e:	89e6                	mv	s3,s9
  while(*path == '/')
    80003810:	0004c783          	lbu	a5,0(s1)
    80003814:	05279363          	bne	a5,s2,8000385a <namex+0x126>
    path++;
    80003818:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000381a:	0004c783          	lbu	a5,0(s1)
    8000381e:	ff278de3          	beq	a5,s2,80003818 <namex+0xe4>
  if(*path == 0)
    80003822:	c78d                	beqz	a5,8000384c <namex+0x118>
    path++;
    80003824:	85a6                	mv	a1,s1
  len = path - s;
    80003826:	8cda                	mv	s9,s6
    80003828:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000382a:	01278963          	beq	a5,s2,8000383c <namex+0x108>
    8000382e:	d7d9                	beqz	a5,800037bc <namex+0x88>
    path++;
    80003830:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003832:	0004c783          	lbu	a5,0(s1)
    80003836:	ff279ce3          	bne	a5,s2,8000382e <namex+0xfa>
    8000383a:	b749                	j	800037bc <namex+0x88>
    memmove(name, s, len);
    8000383c:	2601                	sext.w	a2,a2
    8000383e:	8552                	mv	a0,s4
    80003840:	d32fd0ef          	jal	ra,80000d72 <memmove>
    name[len] = 0;
    80003844:	9cd2                	add	s9,s9,s4
    80003846:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000384a:	b759                	j	800037d0 <namex+0x9c>
  if(nameiparent){
    8000384c:	f40a81e3          	beqz	s5,8000378e <namex+0x5a>
    iput(ip);
    80003850:	854e                	mv	a0,s3
    80003852:	b79ff0ef          	jal	ra,800033ca <iput>
    return 0;
    80003856:	4981                	li	s3,0
    80003858:	bf1d                	j	8000378e <namex+0x5a>
  if(*path == 0)
    8000385a:	dbed                	beqz	a5,8000384c <namex+0x118>
  while(*path != '/' && *path != 0)
    8000385c:	0004c783          	lbu	a5,0(s1)
    80003860:	85a6                	mv	a1,s1
    80003862:	b7f1                	j	8000382e <namex+0xfa>

0000000080003864 <dirlink>:
{
    80003864:	7139                	addi	sp,sp,-64
    80003866:	fc06                	sd	ra,56(sp)
    80003868:	f822                	sd	s0,48(sp)
    8000386a:	f426                	sd	s1,40(sp)
    8000386c:	f04a                	sd	s2,32(sp)
    8000386e:	ec4e                	sd	s3,24(sp)
    80003870:	e852                	sd	s4,16(sp)
    80003872:	0080                	addi	s0,sp,64
    80003874:	892a                	mv	s2,a0
    80003876:	8a2e                	mv	s4,a1
    80003878:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000387a:	4601                	li	a2,0
    8000387c:	e1dff0ef          	jal	ra,80003698 <dirlookup>
    80003880:	e52d                	bnez	a0,800038ea <dirlink+0x86>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003882:	04c92483          	lw	s1,76(s2)
    80003886:	c48d                	beqz	s1,800038b0 <dirlink+0x4c>
    80003888:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000388a:	4741                	li	a4,16
    8000388c:	86a6                	mv	a3,s1
    8000388e:	fc040613          	addi	a2,s0,-64
    80003892:	4581                	li	a1,0
    80003894:	854a                	mv	a0,s2
    80003896:	c07ff0ef          	jal	ra,8000349c <readi>
    8000389a:	47c1                	li	a5,16
    8000389c:	04f51b63          	bne	a0,a5,800038f2 <dirlink+0x8e>
    if(de.inum == 0)
    800038a0:	fc045783          	lhu	a5,-64(s0)
    800038a4:	c791                	beqz	a5,800038b0 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800038a6:	24c1                	addiw	s1,s1,16
    800038a8:	04c92783          	lw	a5,76(s2)
    800038ac:	fcf4efe3          	bltu	s1,a5,8000388a <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    800038b0:	4639                	li	a2,14
    800038b2:	85d2                	mv	a1,s4
    800038b4:	fc240513          	addi	a0,s0,-62
    800038b8:	d66fd0ef          	jal	ra,80000e1e <strncpy>
  de.inum = inum;
    800038bc:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800038c0:	4741                	li	a4,16
    800038c2:	86a6                	mv	a3,s1
    800038c4:	fc040613          	addi	a2,s0,-64
    800038c8:	4581                	li	a1,0
    800038ca:	854a                	mv	a0,s2
    800038cc:	cb5ff0ef          	jal	ra,80003580 <writei>
    800038d0:	1541                	addi	a0,a0,-16
    800038d2:	00a03533          	snez	a0,a0
    800038d6:	40a00533          	neg	a0,a0
}
    800038da:	70e2                	ld	ra,56(sp)
    800038dc:	7442                	ld	s0,48(sp)
    800038de:	74a2                	ld	s1,40(sp)
    800038e0:	7902                	ld	s2,32(sp)
    800038e2:	69e2                	ld	s3,24(sp)
    800038e4:	6a42                	ld	s4,16(sp)
    800038e6:	6121                	addi	sp,sp,64
    800038e8:	8082                	ret
    iput(ip);
    800038ea:	ae1ff0ef          	jal	ra,800033ca <iput>
    return -1;
    800038ee:	557d                	li	a0,-1
    800038f0:	b7ed                	j	800038da <dirlink+0x76>
      panic("dirlink read");
    800038f2:	00004517          	auipc	a0,0x4
    800038f6:	e5e50513          	addi	a0,a0,-418 # 80007750 <syscallnames+0x1d0>
    800038fa:	ee3fc0ef          	jal	ra,800007dc <panic>

00000000800038fe <namei>:

struct inode*
namei(char *path)
{
    800038fe:	1101                	addi	sp,sp,-32
    80003900:	ec06                	sd	ra,24(sp)
    80003902:	e822                	sd	s0,16(sp)
    80003904:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003906:	fe040613          	addi	a2,s0,-32
    8000390a:	4581                	li	a1,0
    8000390c:	e29ff0ef          	jal	ra,80003734 <namex>
}
    80003910:	60e2                	ld	ra,24(sp)
    80003912:	6442                	ld	s0,16(sp)
    80003914:	6105                	addi	sp,sp,32
    80003916:	8082                	ret

0000000080003918 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003918:	1141                	addi	sp,sp,-16
    8000391a:	e406                	sd	ra,8(sp)
    8000391c:	e022                	sd	s0,0(sp)
    8000391e:	0800                	addi	s0,sp,16
    80003920:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003922:	4585                	li	a1,1
    80003924:	e11ff0ef          	jal	ra,80003734 <namex>
}
    80003928:	60a2                	ld	ra,8(sp)
    8000392a:	6402                	ld	s0,0(sp)
    8000392c:	0141                	addi	sp,sp,16
    8000392e:	8082                	ret

0000000080003930 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003930:	1101                	addi	sp,sp,-32
    80003932:	ec06                	sd	ra,24(sp)
    80003934:	e822                	sd	s0,16(sp)
    80003936:	e426                	sd	s1,8(sp)
    80003938:	e04a                	sd	s2,0(sp)
    8000393a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000393c:	0001c917          	auipc	s2,0x1c
    80003940:	36c90913          	addi	s2,s2,876 # 8001fca8 <log>
    80003944:	01892583          	lw	a1,24(s2)
    80003948:	02892503          	lw	a0,40(s2)
    8000394c:	9e0ff0ef          	jal	ra,80002b2c <bread>
    80003950:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003952:	02c92683          	lw	a3,44(s2)
    80003956:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003958:	02d05863          	blez	a3,80003988 <write_head+0x58>
    8000395c:	0001c797          	auipc	a5,0x1c
    80003960:	37c78793          	addi	a5,a5,892 # 8001fcd8 <log+0x30>
    80003964:	05c50713          	addi	a4,a0,92
    80003968:	36fd                	addiw	a3,a3,-1
    8000396a:	02069613          	slli	a2,a3,0x20
    8000396e:	01e65693          	srli	a3,a2,0x1e
    80003972:	0001c617          	auipc	a2,0x1c
    80003976:	36a60613          	addi	a2,a2,874 # 8001fcdc <log+0x34>
    8000397a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000397c:	4390                	lw	a2,0(a5)
    8000397e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003980:	0791                	addi	a5,a5,4
    80003982:	0711                	addi	a4,a4,4
    80003984:	fed79ce3          	bne	a5,a3,8000397c <write_head+0x4c>
  }
  bwrite(buf);
    80003988:	8526                	mv	a0,s1
    8000398a:	a78ff0ef          	jal	ra,80002c02 <bwrite>
  brelse(buf);
    8000398e:	8526                	mv	a0,s1
    80003990:	aa4ff0ef          	jal	ra,80002c34 <brelse>
}
    80003994:	60e2                	ld	ra,24(sp)
    80003996:	6442                	ld	s0,16(sp)
    80003998:	64a2                	ld	s1,8(sp)
    8000399a:	6902                	ld	s2,0(sp)
    8000399c:	6105                	addi	sp,sp,32
    8000399e:	8082                	ret

00000000800039a0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800039a0:	0001c797          	auipc	a5,0x1c
    800039a4:	3347a783          	lw	a5,820(a5) # 8001fcd4 <log+0x2c>
    800039a8:	08f05f63          	blez	a5,80003a46 <install_trans+0xa6>
{
    800039ac:	7139                	addi	sp,sp,-64
    800039ae:	fc06                	sd	ra,56(sp)
    800039b0:	f822                	sd	s0,48(sp)
    800039b2:	f426                	sd	s1,40(sp)
    800039b4:	f04a                	sd	s2,32(sp)
    800039b6:	ec4e                	sd	s3,24(sp)
    800039b8:	e852                	sd	s4,16(sp)
    800039ba:	e456                	sd	s5,8(sp)
    800039bc:	e05a                	sd	s6,0(sp)
    800039be:	0080                	addi	s0,sp,64
    800039c0:	8b2a                	mv	s6,a0
    800039c2:	0001ca97          	auipc	s5,0x1c
    800039c6:	316a8a93          	addi	s5,s5,790 # 8001fcd8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800039ca:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800039cc:	0001c997          	auipc	s3,0x1c
    800039d0:	2dc98993          	addi	s3,s3,732 # 8001fca8 <log>
    800039d4:	a829                	j	800039ee <install_trans+0x4e>
    brelse(lbuf);
    800039d6:	854a                	mv	a0,s2
    800039d8:	a5cff0ef          	jal	ra,80002c34 <brelse>
    brelse(dbuf);
    800039dc:	8526                	mv	a0,s1
    800039de:	a56ff0ef          	jal	ra,80002c34 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800039e2:	2a05                	addiw	s4,s4,1
    800039e4:	0a91                	addi	s5,s5,4
    800039e6:	02c9a783          	lw	a5,44(s3)
    800039ea:	04fa5463          	bge	s4,a5,80003a32 <install_trans+0x92>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800039ee:	0189a583          	lw	a1,24(s3)
    800039f2:	014585bb          	addw	a1,a1,s4
    800039f6:	2585                	addiw	a1,a1,1
    800039f8:	0289a503          	lw	a0,40(s3)
    800039fc:	930ff0ef          	jal	ra,80002b2c <bread>
    80003a00:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003a02:	000aa583          	lw	a1,0(s5)
    80003a06:	0289a503          	lw	a0,40(s3)
    80003a0a:	922ff0ef          	jal	ra,80002b2c <bread>
    80003a0e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003a10:	40000613          	li	a2,1024
    80003a14:	05890593          	addi	a1,s2,88
    80003a18:	05850513          	addi	a0,a0,88
    80003a1c:	b56fd0ef          	jal	ra,80000d72 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003a20:	8526                	mv	a0,s1
    80003a22:	9e0ff0ef          	jal	ra,80002c02 <bwrite>
    if(recovering == 0)
    80003a26:	fa0b18e3          	bnez	s6,800039d6 <install_trans+0x36>
      bunpin(dbuf);
    80003a2a:	8526                	mv	a0,s1
    80003a2c:	ac6ff0ef          	jal	ra,80002cf2 <bunpin>
    80003a30:	b75d                	j	800039d6 <install_trans+0x36>
}
    80003a32:	70e2                	ld	ra,56(sp)
    80003a34:	7442                	ld	s0,48(sp)
    80003a36:	74a2                	ld	s1,40(sp)
    80003a38:	7902                	ld	s2,32(sp)
    80003a3a:	69e2                	ld	s3,24(sp)
    80003a3c:	6a42                	ld	s4,16(sp)
    80003a3e:	6aa2                	ld	s5,8(sp)
    80003a40:	6b02                	ld	s6,0(sp)
    80003a42:	6121                	addi	sp,sp,64
    80003a44:	8082                	ret
    80003a46:	8082                	ret

0000000080003a48 <initlog>:
{
    80003a48:	7179                	addi	sp,sp,-48
    80003a4a:	f406                	sd	ra,40(sp)
    80003a4c:	f022                	sd	s0,32(sp)
    80003a4e:	ec26                	sd	s1,24(sp)
    80003a50:	e84a                	sd	s2,16(sp)
    80003a52:	e44e                	sd	s3,8(sp)
    80003a54:	1800                	addi	s0,sp,48
    80003a56:	892a                	mv	s2,a0
    80003a58:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003a5a:	0001c497          	auipc	s1,0x1c
    80003a5e:	24e48493          	addi	s1,s1,590 # 8001fca8 <log>
    80003a62:	00004597          	auipc	a1,0x4
    80003a66:	cfe58593          	addi	a1,a1,-770 # 80007760 <syscallnames+0x1e0>
    80003a6a:	8526                	mv	a0,s1
    80003a6c:	956fd0ef          	jal	ra,80000bc2 <initlock>
  log.start = sb->logstart;
    80003a70:	0149a583          	lw	a1,20(s3)
    80003a74:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003a76:	0109a783          	lw	a5,16(s3)
    80003a7a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003a7c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003a80:	854a                	mv	a0,s2
    80003a82:	8aaff0ef          	jal	ra,80002b2c <bread>
  log.lh.n = lh->n;
    80003a86:	4d34                	lw	a3,88(a0)
    80003a88:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003a8a:	02d05663          	blez	a3,80003ab6 <initlog+0x6e>
    80003a8e:	05c50793          	addi	a5,a0,92
    80003a92:	0001c717          	auipc	a4,0x1c
    80003a96:	24670713          	addi	a4,a4,582 # 8001fcd8 <log+0x30>
    80003a9a:	36fd                	addiw	a3,a3,-1
    80003a9c:	02069613          	slli	a2,a3,0x20
    80003aa0:	01e65693          	srli	a3,a2,0x1e
    80003aa4:	06050613          	addi	a2,a0,96
    80003aa8:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003aaa:	4390                	lw	a2,0(a5)
    80003aac:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003aae:	0791                	addi	a5,a5,4
    80003ab0:	0711                	addi	a4,a4,4
    80003ab2:	fed79ce3          	bne	a5,a3,80003aaa <initlog+0x62>
  brelse(buf);
    80003ab6:	97eff0ef          	jal	ra,80002c34 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003aba:	4505                	li	a0,1
    80003abc:	ee5ff0ef          	jal	ra,800039a0 <install_trans>
  log.lh.n = 0;
    80003ac0:	0001c797          	auipc	a5,0x1c
    80003ac4:	2007aa23          	sw	zero,532(a5) # 8001fcd4 <log+0x2c>
  write_head(); // clear the log
    80003ac8:	e69ff0ef          	jal	ra,80003930 <write_head>
}
    80003acc:	70a2                	ld	ra,40(sp)
    80003ace:	7402                	ld	s0,32(sp)
    80003ad0:	64e2                	ld	s1,24(sp)
    80003ad2:	6942                	ld	s2,16(sp)
    80003ad4:	69a2                	ld	s3,8(sp)
    80003ad6:	6145                	addi	sp,sp,48
    80003ad8:	8082                	ret

0000000080003ada <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003ada:	1101                	addi	sp,sp,-32
    80003adc:	ec06                	sd	ra,24(sp)
    80003ade:	e822                	sd	s0,16(sp)
    80003ae0:	e426                	sd	s1,8(sp)
    80003ae2:	e04a                	sd	s2,0(sp)
    80003ae4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003ae6:	0001c517          	auipc	a0,0x1c
    80003aea:	1c250513          	addi	a0,a0,450 # 8001fca8 <log>
    80003aee:	954fd0ef          	jal	ra,80000c42 <acquire>
  while(1){
    if(log.committing){
    80003af2:	0001c497          	auipc	s1,0x1c
    80003af6:	1b648493          	addi	s1,s1,438 # 8001fca8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003afa:	4979                	li	s2,30
    80003afc:	a029                	j	80003b06 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003afe:	85a6                	mv	a1,s1
    80003b00:	8526                	mv	a0,s1
    80003b02:	bbefe0ef          	jal	ra,80001ec0 <sleep>
    if(log.committing){
    80003b06:	50dc                	lw	a5,36(s1)
    80003b08:	fbfd                	bnez	a5,80003afe <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003b0a:	509c                	lw	a5,32(s1)
    80003b0c:	0017871b          	addiw	a4,a5,1
    80003b10:	0007069b          	sext.w	a3,a4
    80003b14:	0027179b          	slliw	a5,a4,0x2
    80003b18:	9fb9                	addw	a5,a5,a4
    80003b1a:	0017979b          	slliw	a5,a5,0x1
    80003b1e:	54d8                	lw	a4,44(s1)
    80003b20:	9fb9                	addw	a5,a5,a4
    80003b22:	00f95763          	bge	s2,a5,80003b30 <begin_op+0x56>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003b26:	85a6                	mv	a1,s1
    80003b28:	8526                	mv	a0,s1
    80003b2a:	b96fe0ef          	jal	ra,80001ec0 <sleep>
    80003b2e:	bfe1                	j	80003b06 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003b30:	0001c517          	auipc	a0,0x1c
    80003b34:	17850513          	addi	a0,a0,376 # 8001fca8 <log>
    80003b38:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80003b3a:	9a0fd0ef          	jal	ra,80000cda <release>
      break;
    }
  }
}
    80003b3e:	60e2                	ld	ra,24(sp)
    80003b40:	6442                	ld	s0,16(sp)
    80003b42:	64a2                	ld	s1,8(sp)
    80003b44:	6902                	ld	s2,0(sp)
    80003b46:	6105                	addi	sp,sp,32
    80003b48:	8082                	ret

0000000080003b4a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003b4a:	7139                	addi	sp,sp,-64
    80003b4c:	fc06                	sd	ra,56(sp)
    80003b4e:	f822                	sd	s0,48(sp)
    80003b50:	f426                	sd	s1,40(sp)
    80003b52:	f04a                	sd	s2,32(sp)
    80003b54:	ec4e                	sd	s3,24(sp)
    80003b56:	e852                	sd	s4,16(sp)
    80003b58:	e456                	sd	s5,8(sp)
    80003b5a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003b5c:	0001c497          	auipc	s1,0x1c
    80003b60:	14c48493          	addi	s1,s1,332 # 8001fca8 <log>
    80003b64:	8526                	mv	a0,s1
    80003b66:	8dcfd0ef          	jal	ra,80000c42 <acquire>
  log.outstanding -= 1;
    80003b6a:	509c                	lw	a5,32(s1)
    80003b6c:	37fd                	addiw	a5,a5,-1
    80003b6e:	0007891b          	sext.w	s2,a5
    80003b72:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80003b74:	50dc                	lw	a5,36(s1)
    80003b76:	ef9d                	bnez	a5,80003bb4 <end_op+0x6a>
    panic("log.committing");
  if(log.outstanding == 0){
    80003b78:	04091463          	bnez	s2,80003bc0 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80003b7c:	0001c497          	auipc	s1,0x1c
    80003b80:	12c48493          	addi	s1,s1,300 # 8001fca8 <log>
    80003b84:	4785                	li	a5,1
    80003b86:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80003b88:	8526                	mv	a0,s1
    80003b8a:	950fd0ef          	jal	ra,80000cda <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80003b8e:	54dc                	lw	a5,44(s1)
    80003b90:	04f04b63          	bgtz	a5,80003be6 <end_op+0x9c>
    acquire(&log.lock);
    80003b94:	0001c497          	auipc	s1,0x1c
    80003b98:	11448493          	addi	s1,s1,276 # 8001fca8 <log>
    80003b9c:	8526                	mv	a0,s1
    80003b9e:	8a4fd0ef          	jal	ra,80000c42 <acquire>
    log.committing = 0;
    80003ba2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80003ba6:	8526                	mv	a0,s1
    80003ba8:	b64fe0ef          	jal	ra,80001f0c <wakeup>
    release(&log.lock);
    80003bac:	8526                	mv	a0,s1
    80003bae:	92cfd0ef          	jal	ra,80000cda <release>
}
    80003bb2:	a00d                	j	80003bd4 <end_op+0x8a>
    panic("log.committing");
    80003bb4:	00004517          	auipc	a0,0x4
    80003bb8:	bb450513          	addi	a0,a0,-1100 # 80007768 <syscallnames+0x1e8>
    80003bbc:	c21fc0ef          	jal	ra,800007dc <panic>
    wakeup(&log);
    80003bc0:	0001c497          	auipc	s1,0x1c
    80003bc4:	0e848493          	addi	s1,s1,232 # 8001fca8 <log>
    80003bc8:	8526                	mv	a0,s1
    80003bca:	b42fe0ef          	jal	ra,80001f0c <wakeup>
  release(&log.lock);
    80003bce:	8526                	mv	a0,s1
    80003bd0:	90afd0ef          	jal	ra,80000cda <release>
}
    80003bd4:	70e2                	ld	ra,56(sp)
    80003bd6:	7442                	ld	s0,48(sp)
    80003bd8:	74a2                	ld	s1,40(sp)
    80003bda:	7902                	ld	s2,32(sp)
    80003bdc:	69e2                	ld	s3,24(sp)
    80003bde:	6a42                	ld	s4,16(sp)
    80003be0:	6aa2                	ld	s5,8(sp)
    80003be2:	6121                	addi	sp,sp,64
    80003be4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80003be6:	0001ca97          	auipc	s5,0x1c
    80003bea:	0f2a8a93          	addi	s5,s5,242 # 8001fcd8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80003bee:	0001ca17          	auipc	s4,0x1c
    80003bf2:	0baa0a13          	addi	s4,s4,186 # 8001fca8 <log>
    80003bf6:	018a2583          	lw	a1,24(s4)
    80003bfa:	012585bb          	addw	a1,a1,s2
    80003bfe:	2585                	addiw	a1,a1,1
    80003c00:	028a2503          	lw	a0,40(s4)
    80003c04:	f29fe0ef          	jal	ra,80002b2c <bread>
    80003c08:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80003c0a:	000aa583          	lw	a1,0(s5)
    80003c0e:	028a2503          	lw	a0,40(s4)
    80003c12:	f1bfe0ef          	jal	ra,80002b2c <bread>
    80003c16:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80003c18:	40000613          	li	a2,1024
    80003c1c:	05850593          	addi	a1,a0,88
    80003c20:	05848513          	addi	a0,s1,88
    80003c24:	94efd0ef          	jal	ra,80000d72 <memmove>
    bwrite(to);  // write the log
    80003c28:	8526                	mv	a0,s1
    80003c2a:	fd9fe0ef          	jal	ra,80002c02 <bwrite>
    brelse(from);
    80003c2e:	854e                	mv	a0,s3
    80003c30:	804ff0ef          	jal	ra,80002c34 <brelse>
    brelse(to);
    80003c34:	8526                	mv	a0,s1
    80003c36:	ffffe0ef          	jal	ra,80002c34 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003c3a:	2905                	addiw	s2,s2,1
    80003c3c:	0a91                	addi	s5,s5,4
    80003c3e:	02ca2783          	lw	a5,44(s4)
    80003c42:	faf94ae3          	blt	s2,a5,80003bf6 <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80003c46:	cebff0ef          	jal	ra,80003930 <write_head>
    install_trans(0); // Now install writes to home locations
    80003c4a:	4501                	li	a0,0
    80003c4c:	d55ff0ef          	jal	ra,800039a0 <install_trans>
    log.lh.n = 0;
    80003c50:	0001c797          	auipc	a5,0x1c
    80003c54:	0807a223          	sw	zero,132(a5) # 8001fcd4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80003c58:	cd9ff0ef          	jal	ra,80003930 <write_head>
    80003c5c:	bf25                	j	80003b94 <end_op+0x4a>

0000000080003c5e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80003c5e:	1101                	addi	sp,sp,-32
    80003c60:	ec06                	sd	ra,24(sp)
    80003c62:	e822                	sd	s0,16(sp)
    80003c64:	e426                	sd	s1,8(sp)
    80003c66:	e04a                	sd	s2,0(sp)
    80003c68:	1000                	addi	s0,sp,32
    80003c6a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80003c6c:	0001c917          	auipc	s2,0x1c
    80003c70:	03c90913          	addi	s2,s2,60 # 8001fca8 <log>
    80003c74:	854a                	mv	a0,s2
    80003c76:	fcdfc0ef          	jal	ra,80000c42 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80003c7a:	02c92603          	lw	a2,44(s2)
    80003c7e:	47f5                	li	a5,29
    80003c80:	06c7c363          	blt	a5,a2,80003ce6 <log_write+0x88>
    80003c84:	0001c797          	auipc	a5,0x1c
    80003c88:	0407a783          	lw	a5,64(a5) # 8001fcc4 <log+0x1c>
    80003c8c:	37fd                	addiw	a5,a5,-1
    80003c8e:	04f65c63          	bge	a2,a5,80003ce6 <log_write+0x88>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80003c92:	0001c797          	auipc	a5,0x1c
    80003c96:	0367a783          	lw	a5,54(a5) # 8001fcc8 <log+0x20>
    80003c9a:	04f05c63          	blez	a5,80003cf2 <log_write+0x94>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80003c9e:	4781                	li	a5,0
    80003ca0:	04c05f63          	blez	a2,80003cfe <log_write+0xa0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003ca4:	44cc                	lw	a1,12(s1)
    80003ca6:	0001c717          	auipc	a4,0x1c
    80003caa:	03270713          	addi	a4,a4,50 # 8001fcd8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80003cae:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003cb0:	4314                	lw	a3,0(a4)
    80003cb2:	04b68663          	beq	a3,a1,80003cfe <log_write+0xa0>
  for (i = 0; i < log.lh.n; i++) {
    80003cb6:	2785                	addiw	a5,a5,1
    80003cb8:	0711                	addi	a4,a4,4
    80003cba:	fef61be3          	bne	a2,a5,80003cb0 <log_write+0x52>
      break;
  }
  log.lh.block[i] = b->blockno;
    80003cbe:	0621                	addi	a2,a2,8
    80003cc0:	060a                	slli	a2,a2,0x2
    80003cc2:	0001c797          	auipc	a5,0x1c
    80003cc6:	fe678793          	addi	a5,a5,-26 # 8001fca8 <log>
    80003cca:	963e                	add	a2,a2,a5
    80003ccc:	44dc                	lw	a5,12(s1)
    80003cce:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80003cd0:	8526                	mv	a0,s1
    80003cd2:	fedfe0ef          	jal	ra,80002cbe <bpin>
    log.lh.n++;
    80003cd6:	0001c717          	auipc	a4,0x1c
    80003cda:	fd270713          	addi	a4,a4,-46 # 8001fca8 <log>
    80003cde:	575c                	lw	a5,44(a4)
    80003ce0:	2785                	addiw	a5,a5,1
    80003ce2:	d75c                	sw	a5,44(a4)
    80003ce4:	a815                	j	80003d18 <log_write+0xba>
    panic("too big a transaction");
    80003ce6:	00004517          	auipc	a0,0x4
    80003cea:	a9250513          	addi	a0,a0,-1390 # 80007778 <syscallnames+0x1f8>
    80003cee:	aeffc0ef          	jal	ra,800007dc <panic>
    panic("log_write outside of trans");
    80003cf2:	00004517          	auipc	a0,0x4
    80003cf6:	a9e50513          	addi	a0,a0,-1378 # 80007790 <syscallnames+0x210>
    80003cfa:	ae3fc0ef          	jal	ra,800007dc <panic>
  log.lh.block[i] = b->blockno;
    80003cfe:	00878713          	addi	a4,a5,8
    80003d02:	00271693          	slli	a3,a4,0x2
    80003d06:	0001c717          	auipc	a4,0x1c
    80003d0a:	fa270713          	addi	a4,a4,-94 # 8001fca8 <log>
    80003d0e:	9736                	add	a4,a4,a3
    80003d10:	44d4                	lw	a3,12(s1)
    80003d12:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80003d14:	faf60ee3          	beq	a2,a5,80003cd0 <log_write+0x72>
  }
  release(&log.lock);
    80003d18:	0001c517          	auipc	a0,0x1c
    80003d1c:	f9050513          	addi	a0,a0,-112 # 8001fca8 <log>
    80003d20:	fbbfc0ef          	jal	ra,80000cda <release>
}
    80003d24:	60e2                	ld	ra,24(sp)
    80003d26:	6442                	ld	s0,16(sp)
    80003d28:	64a2                	ld	s1,8(sp)
    80003d2a:	6902                	ld	s2,0(sp)
    80003d2c:	6105                	addi	sp,sp,32
    80003d2e:	8082                	ret

0000000080003d30 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003d30:	1101                	addi	sp,sp,-32
    80003d32:	ec06                	sd	ra,24(sp)
    80003d34:	e822                	sd	s0,16(sp)
    80003d36:	e426                	sd	s1,8(sp)
    80003d38:	e04a                	sd	s2,0(sp)
    80003d3a:	1000                	addi	s0,sp,32
    80003d3c:	84aa                	mv	s1,a0
    80003d3e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003d40:	00004597          	auipc	a1,0x4
    80003d44:	a7058593          	addi	a1,a1,-1424 # 800077b0 <syscallnames+0x230>
    80003d48:	0521                	addi	a0,a0,8
    80003d4a:	e79fc0ef          	jal	ra,80000bc2 <initlock>
  lk->name = name;
    80003d4e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80003d52:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003d56:	0204a423          	sw	zero,40(s1)
}
    80003d5a:	60e2                	ld	ra,24(sp)
    80003d5c:	6442                	ld	s0,16(sp)
    80003d5e:	64a2                	ld	s1,8(sp)
    80003d60:	6902                	ld	s2,0(sp)
    80003d62:	6105                	addi	sp,sp,32
    80003d64:	8082                	ret

0000000080003d66 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80003d66:	1101                	addi	sp,sp,-32
    80003d68:	ec06                	sd	ra,24(sp)
    80003d6a:	e822                	sd	s0,16(sp)
    80003d6c:	e426                	sd	s1,8(sp)
    80003d6e:	e04a                	sd	s2,0(sp)
    80003d70:	1000                	addi	s0,sp,32
    80003d72:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003d74:	00850913          	addi	s2,a0,8
    80003d78:	854a                	mv	a0,s2
    80003d7a:	ec9fc0ef          	jal	ra,80000c42 <acquire>
  while (lk->locked) {
    80003d7e:	409c                	lw	a5,0(s1)
    80003d80:	c799                	beqz	a5,80003d8e <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80003d82:	85ca                	mv	a1,s2
    80003d84:	8526                	mv	a0,s1
    80003d86:	93afe0ef          	jal	ra,80001ec0 <sleep>
  while (lk->locked) {
    80003d8a:	409c                	lw	a5,0(s1)
    80003d8c:	fbfd                	bnez	a5,80003d82 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80003d8e:	4785                	li	a5,1
    80003d90:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80003d92:	b49fd0ef          	jal	ra,800018da <myproc>
    80003d96:	591c                	lw	a5,48(a0)
    80003d98:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80003d9a:	854a                	mv	a0,s2
    80003d9c:	f3ffc0ef          	jal	ra,80000cda <release>
}
    80003da0:	60e2                	ld	ra,24(sp)
    80003da2:	6442                	ld	s0,16(sp)
    80003da4:	64a2                	ld	s1,8(sp)
    80003da6:	6902                	ld	s2,0(sp)
    80003da8:	6105                	addi	sp,sp,32
    80003daa:	8082                	ret

0000000080003dac <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80003dac:	1101                	addi	sp,sp,-32
    80003dae:	ec06                	sd	ra,24(sp)
    80003db0:	e822                	sd	s0,16(sp)
    80003db2:	e426                	sd	s1,8(sp)
    80003db4:	e04a                	sd	s2,0(sp)
    80003db6:	1000                	addi	s0,sp,32
    80003db8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003dba:	00850913          	addi	s2,a0,8
    80003dbe:	854a                	mv	a0,s2
    80003dc0:	e83fc0ef          	jal	ra,80000c42 <acquire>
  lk->locked = 0;
    80003dc4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003dc8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80003dcc:	8526                	mv	a0,s1
    80003dce:	93efe0ef          	jal	ra,80001f0c <wakeup>
  release(&lk->lk);
    80003dd2:	854a                	mv	a0,s2
    80003dd4:	f07fc0ef          	jal	ra,80000cda <release>
}
    80003dd8:	60e2                	ld	ra,24(sp)
    80003dda:	6442                	ld	s0,16(sp)
    80003ddc:	64a2                	ld	s1,8(sp)
    80003dde:	6902                	ld	s2,0(sp)
    80003de0:	6105                	addi	sp,sp,32
    80003de2:	8082                	ret

0000000080003de4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80003de4:	7179                	addi	sp,sp,-48
    80003de6:	f406                	sd	ra,40(sp)
    80003de8:	f022                	sd	s0,32(sp)
    80003dea:	ec26                	sd	s1,24(sp)
    80003dec:	e84a                	sd	s2,16(sp)
    80003dee:	e44e                	sd	s3,8(sp)
    80003df0:	1800                	addi	s0,sp,48
    80003df2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80003df4:	00850913          	addi	s2,a0,8
    80003df8:	854a                	mv	a0,s2
    80003dfa:	e49fc0ef          	jal	ra,80000c42 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80003dfe:	409c                	lw	a5,0(s1)
    80003e00:	ef89                	bnez	a5,80003e1a <holdingsleep+0x36>
    80003e02:	4481                	li	s1,0
  release(&lk->lk);
    80003e04:	854a                	mv	a0,s2
    80003e06:	ed5fc0ef          	jal	ra,80000cda <release>
  return r;
}
    80003e0a:	8526                	mv	a0,s1
    80003e0c:	70a2                	ld	ra,40(sp)
    80003e0e:	7402                	ld	s0,32(sp)
    80003e10:	64e2                	ld	s1,24(sp)
    80003e12:	6942                	ld	s2,16(sp)
    80003e14:	69a2                	ld	s3,8(sp)
    80003e16:	6145                	addi	sp,sp,48
    80003e18:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80003e1a:	0284a983          	lw	s3,40(s1)
    80003e1e:	abdfd0ef          	jal	ra,800018da <myproc>
    80003e22:	5904                	lw	s1,48(a0)
    80003e24:	413484b3          	sub	s1,s1,s3
    80003e28:	0014b493          	seqz	s1,s1
    80003e2c:	bfe1                	j	80003e04 <holdingsleep+0x20>

0000000080003e2e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80003e2e:	1141                	addi	sp,sp,-16
    80003e30:	e406                	sd	ra,8(sp)
    80003e32:	e022                	sd	s0,0(sp)
    80003e34:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80003e36:	00004597          	auipc	a1,0x4
    80003e3a:	98a58593          	addi	a1,a1,-1654 # 800077c0 <syscallnames+0x240>
    80003e3e:	0001c517          	auipc	a0,0x1c
    80003e42:	fb250513          	addi	a0,a0,-78 # 8001fdf0 <ftable>
    80003e46:	d7dfc0ef          	jal	ra,80000bc2 <initlock>
}
    80003e4a:	60a2                	ld	ra,8(sp)
    80003e4c:	6402                	ld	s0,0(sp)
    80003e4e:	0141                	addi	sp,sp,16
    80003e50:	8082                	ret

0000000080003e52 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80003e52:	1101                	addi	sp,sp,-32
    80003e54:	ec06                	sd	ra,24(sp)
    80003e56:	e822                	sd	s0,16(sp)
    80003e58:	e426                	sd	s1,8(sp)
    80003e5a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80003e5c:	0001c517          	auipc	a0,0x1c
    80003e60:	f9450513          	addi	a0,a0,-108 # 8001fdf0 <ftable>
    80003e64:	ddffc0ef          	jal	ra,80000c42 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003e68:	0001c497          	auipc	s1,0x1c
    80003e6c:	fa048493          	addi	s1,s1,-96 # 8001fe08 <ftable+0x18>
    80003e70:	0001d717          	auipc	a4,0x1d
    80003e74:	f3870713          	addi	a4,a4,-200 # 80020da8 <disk>
    if(f->ref == 0){
    80003e78:	40dc                	lw	a5,4(s1)
    80003e7a:	cf89                	beqz	a5,80003e94 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003e7c:	02848493          	addi	s1,s1,40
    80003e80:	fee49ce3          	bne	s1,a4,80003e78 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80003e84:	0001c517          	auipc	a0,0x1c
    80003e88:	f6c50513          	addi	a0,a0,-148 # 8001fdf0 <ftable>
    80003e8c:	e4ffc0ef          	jal	ra,80000cda <release>
  return 0;
    80003e90:	4481                	li	s1,0
    80003e92:	a809                	j	80003ea4 <filealloc+0x52>
      f->ref = 1;
    80003e94:	4785                	li	a5,1
    80003e96:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80003e98:	0001c517          	auipc	a0,0x1c
    80003e9c:	f5850513          	addi	a0,a0,-168 # 8001fdf0 <ftable>
    80003ea0:	e3bfc0ef          	jal	ra,80000cda <release>
}
    80003ea4:	8526                	mv	a0,s1
    80003ea6:	60e2                	ld	ra,24(sp)
    80003ea8:	6442                	ld	s0,16(sp)
    80003eaa:	64a2                	ld	s1,8(sp)
    80003eac:	6105                	addi	sp,sp,32
    80003eae:	8082                	ret

0000000080003eb0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80003eb0:	1101                	addi	sp,sp,-32
    80003eb2:	ec06                	sd	ra,24(sp)
    80003eb4:	e822                	sd	s0,16(sp)
    80003eb6:	e426                	sd	s1,8(sp)
    80003eb8:	1000                	addi	s0,sp,32
    80003eba:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80003ebc:	0001c517          	auipc	a0,0x1c
    80003ec0:	f3450513          	addi	a0,a0,-204 # 8001fdf0 <ftable>
    80003ec4:	d7ffc0ef          	jal	ra,80000c42 <acquire>
  if(f->ref < 1)
    80003ec8:	40dc                	lw	a5,4(s1)
    80003eca:	02f05063          	blez	a5,80003eea <filedup+0x3a>
    panic("filedup");
  f->ref++;
    80003ece:	2785                	addiw	a5,a5,1
    80003ed0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80003ed2:	0001c517          	auipc	a0,0x1c
    80003ed6:	f1e50513          	addi	a0,a0,-226 # 8001fdf0 <ftable>
    80003eda:	e01fc0ef          	jal	ra,80000cda <release>
  return f;
}
    80003ede:	8526                	mv	a0,s1
    80003ee0:	60e2                	ld	ra,24(sp)
    80003ee2:	6442                	ld	s0,16(sp)
    80003ee4:	64a2                	ld	s1,8(sp)
    80003ee6:	6105                	addi	sp,sp,32
    80003ee8:	8082                	ret
    panic("filedup");
    80003eea:	00004517          	auipc	a0,0x4
    80003eee:	8de50513          	addi	a0,a0,-1826 # 800077c8 <syscallnames+0x248>
    80003ef2:	8ebfc0ef          	jal	ra,800007dc <panic>

0000000080003ef6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80003ef6:	7139                	addi	sp,sp,-64
    80003ef8:	fc06                	sd	ra,56(sp)
    80003efa:	f822                	sd	s0,48(sp)
    80003efc:	f426                	sd	s1,40(sp)
    80003efe:	f04a                	sd	s2,32(sp)
    80003f00:	ec4e                	sd	s3,24(sp)
    80003f02:	e852                	sd	s4,16(sp)
    80003f04:	e456                	sd	s5,8(sp)
    80003f06:	0080                	addi	s0,sp,64
    80003f08:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80003f0a:	0001c517          	auipc	a0,0x1c
    80003f0e:	ee650513          	addi	a0,a0,-282 # 8001fdf0 <ftable>
    80003f12:	d31fc0ef          	jal	ra,80000c42 <acquire>
  if(f->ref < 1)
    80003f16:	40dc                	lw	a5,4(s1)
    80003f18:	04f05963          	blez	a5,80003f6a <fileclose+0x74>
    panic("fileclose");
  if(--f->ref > 0){
    80003f1c:	37fd                	addiw	a5,a5,-1
    80003f1e:	0007871b          	sext.w	a4,a5
    80003f22:	c0dc                	sw	a5,4(s1)
    80003f24:	04e04963          	bgtz	a4,80003f76 <fileclose+0x80>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80003f28:	0004a903          	lw	s2,0(s1)
    80003f2c:	0094ca83          	lbu	s5,9(s1)
    80003f30:	0104ba03          	ld	s4,16(s1)
    80003f34:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80003f38:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80003f3c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80003f40:	0001c517          	auipc	a0,0x1c
    80003f44:	eb050513          	addi	a0,a0,-336 # 8001fdf0 <ftable>
    80003f48:	d93fc0ef          	jal	ra,80000cda <release>

  if(ff.type == FD_PIPE){
    80003f4c:	4785                	li	a5,1
    80003f4e:	04f90363          	beq	s2,a5,80003f94 <fileclose+0x9e>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80003f52:	3979                	addiw	s2,s2,-2
    80003f54:	4785                	li	a5,1
    80003f56:	0327e663          	bltu	a5,s2,80003f82 <fileclose+0x8c>
    begin_op();
    80003f5a:	b81ff0ef          	jal	ra,80003ada <begin_op>
    iput(ff.ip);
    80003f5e:	854e                	mv	a0,s3
    80003f60:	c6aff0ef          	jal	ra,800033ca <iput>
    end_op();
    80003f64:	be7ff0ef          	jal	ra,80003b4a <end_op>
    80003f68:	a829                	j	80003f82 <fileclose+0x8c>
    panic("fileclose");
    80003f6a:	00004517          	auipc	a0,0x4
    80003f6e:	86650513          	addi	a0,a0,-1946 # 800077d0 <syscallnames+0x250>
    80003f72:	86bfc0ef          	jal	ra,800007dc <panic>
    release(&ftable.lock);
    80003f76:	0001c517          	auipc	a0,0x1c
    80003f7a:	e7a50513          	addi	a0,a0,-390 # 8001fdf0 <ftable>
    80003f7e:	d5dfc0ef          	jal	ra,80000cda <release>
  }
}
    80003f82:	70e2                	ld	ra,56(sp)
    80003f84:	7442                	ld	s0,48(sp)
    80003f86:	74a2                	ld	s1,40(sp)
    80003f88:	7902                	ld	s2,32(sp)
    80003f8a:	69e2                	ld	s3,24(sp)
    80003f8c:	6a42                	ld	s4,16(sp)
    80003f8e:	6aa2                	ld	s5,8(sp)
    80003f90:	6121                	addi	sp,sp,64
    80003f92:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80003f94:	85d6                	mv	a1,s5
    80003f96:	8552                	mv	a0,s4
    80003f98:	2ec000ef          	jal	ra,80004284 <pipeclose>
    80003f9c:	b7dd                	j	80003f82 <fileclose+0x8c>

0000000080003f9e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80003f9e:	715d                	addi	sp,sp,-80
    80003fa0:	e486                	sd	ra,72(sp)
    80003fa2:	e0a2                	sd	s0,64(sp)
    80003fa4:	fc26                	sd	s1,56(sp)
    80003fa6:	f84a                	sd	s2,48(sp)
    80003fa8:	f44e                	sd	s3,40(sp)
    80003faa:	0880                	addi	s0,sp,80
    80003fac:	84aa                	mv	s1,a0
    80003fae:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80003fb0:	92bfd0ef          	jal	ra,800018da <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80003fb4:	409c                	lw	a5,0(s1)
    80003fb6:	37f9                	addiw	a5,a5,-2
    80003fb8:	4705                	li	a4,1
    80003fba:	02f76f63          	bltu	a4,a5,80003ff8 <filestat+0x5a>
    80003fbe:	892a                	mv	s2,a0
    ilock(f->ip);
    80003fc0:	6c88                	ld	a0,24(s1)
    80003fc2:	a8aff0ef          	jal	ra,8000324c <ilock>
    stati(f->ip, &st);
    80003fc6:	fb840593          	addi	a1,s0,-72
    80003fca:	6c88                	ld	a0,24(s1)
    80003fcc:	ca6ff0ef          	jal	ra,80003472 <stati>
    iunlock(f->ip);
    80003fd0:	6c88                	ld	a0,24(s1)
    80003fd2:	b24ff0ef          	jal	ra,800032f6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80003fd6:	46e1                	li	a3,24
    80003fd8:	fb840613          	addi	a2,s0,-72
    80003fdc:	85ce                	mv	a1,s3
    80003fde:	05893503          	ld	a0,88(s2)
    80003fe2:	e46fd0ef          	jal	ra,80001628 <copyout>
    80003fe6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80003fea:	60a6                	ld	ra,72(sp)
    80003fec:	6406                	ld	s0,64(sp)
    80003fee:	74e2                	ld	s1,56(sp)
    80003ff0:	7942                	ld	s2,48(sp)
    80003ff2:	79a2                	ld	s3,40(sp)
    80003ff4:	6161                	addi	sp,sp,80
    80003ff6:	8082                	ret
  return -1;
    80003ff8:	557d                	li	a0,-1
    80003ffa:	bfc5                	j	80003fea <filestat+0x4c>

0000000080003ffc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80003ffc:	7179                	addi	sp,sp,-48
    80003ffe:	f406                	sd	ra,40(sp)
    80004000:	f022                	sd	s0,32(sp)
    80004002:	ec26                	sd	s1,24(sp)
    80004004:	e84a                	sd	s2,16(sp)
    80004006:	e44e                	sd	s3,8(sp)
    80004008:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000400a:	00854783          	lbu	a5,8(a0)
    8000400e:	cbc1                	beqz	a5,8000409e <fileread+0xa2>
    80004010:	84aa                	mv	s1,a0
    80004012:	89ae                	mv	s3,a1
    80004014:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004016:	411c                	lw	a5,0(a0)
    80004018:	4705                	li	a4,1
    8000401a:	04e78363          	beq	a5,a4,80004060 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000401e:	470d                	li	a4,3
    80004020:	04e78563          	beq	a5,a4,8000406a <fileread+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004024:	4709                	li	a4,2
    80004026:	06e79663          	bne	a5,a4,80004092 <fileread+0x96>
    ilock(f->ip);
    8000402a:	6d08                	ld	a0,24(a0)
    8000402c:	a20ff0ef          	jal	ra,8000324c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004030:	874a                	mv	a4,s2
    80004032:	5094                	lw	a3,32(s1)
    80004034:	864e                	mv	a2,s3
    80004036:	4585                	li	a1,1
    80004038:	6c88                	ld	a0,24(s1)
    8000403a:	c62ff0ef          	jal	ra,8000349c <readi>
    8000403e:	892a                	mv	s2,a0
    80004040:	00a05563          	blez	a0,8000404a <fileread+0x4e>
      f->off += r;
    80004044:	509c                	lw	a5,32(s1)
    80004046:	9fa9                	addw	a5,a5,a0
    80004048:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000404a:	6c88                	ld	a0,24(s1)
    8000404c:	aaaff0ef          	jal	ra,800032f6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004050:	854a                	mv	a0,s2
    80004052:	70a2                	ld	ra,40(sp)
    80004054:	7402                	ld	s0,32(sp)
    80004056:	64e2                	ld	s1,24(sp)
    80004058:	6942                	ld	s2,16(sp)
    8000405a:	69a2                	ld	s3,8(sp)
    8000405c:	6145                	addi	sp,sp,48
    8000405e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004060:	6908                	ld	a0,16(a0)
    80004062:	34e000ef          	jal	ra,800043b0 <piperead>
    80004066:	892a                	mv	s2,a0
    80004068:	b7e5                	j	80004050 <fileread+0x54>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000406a:	02451783          	lh	a5,36(a0)
    8000406e:	03079693          	slli	a3,a5,0x30
    80004072:	92c1                	srli	a3,a3,0x30
    80004074:	4725                	li	a4,9
    80004076:	02d76663          	bltu	a4,a3,800040a2 <fileread+0xa6>
    8000407a:	0792                	slli	a5,a5,0x4
    8000407c:	0001c717          	auipc	a4,0x1c
    80004080:	cd470713          	addi	a4,a4,-812 # 8001fd50 <devsw>
    80004084:	97ba                	add	a5,a5,a4
    80004086:	639c                	ld	a5,0(a5)
    80004088:	cf99                	beqz	a5,800040a6 <fileread+0xaa>
    r = devsw[f->major].read(1, addr, n);
    8000408a:	4505                	li	a0,1
    8000408c:	9782                	jalr	a5
    8000408e:	892a                	mv	s2,a0
    80004090:	b7c1                	j	80004050 <fileread+0x54>
    panic("fileread");
    80004092:	00003517          	auipc	a0,0x3
    80004096:	74e50513          	addi	a0,a0,1870 # 800077e0 <syscallnames+0x260>
    8000409a:	f42fc0ef          	jal	ra,800007dc <panic>
    return -1;
    8000409e:	597d                	li	s2,-1
    800040a0:	bf45                	j	80004050 <fileread+0x54>
      return -1;
    800040a2:	597d                	li	s2,-1
    800040a4:	b775                	j	80004050 <fileread+0x54>
    800040a6:	597d                	li	s2,-1
    800040a8:	b765                	j	80004050 <fileread+0x54>

00000000800040aa <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800040aa:	715d                	addi	sp,sp,-80
    800040ac:	e486                	sd	ra,72(sp)
    800040ae:	e0a2                	sd	s0,64(sp)
    800040b0:	fc26                	sd	s1,56(sp)
    800040b2:	f84a                	sd	s2,48(sp)
    800040b4:	f44e                	sd	s3,40(sp)
    800040b6:	f052                	sd	s4,32(sp)
    800040b8:	ec56                	sd	s5,24(sp)
    800040ba:	e85a                	sd	s6,16(sp)
    800040bc:	e45e                	sd	s7,8(sp)
    800040be:	e062                	sd	s8,0(sp)
    800040c0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800040c2:	00954783          	lbu	a5,9(a0)
    800040c6:	0e078863          	beqz	a5,800041b6 <filewrite+0x10c>
    800040ca:	892a                	mv	s2,a0
    800040cc:	8aae                	mv	s5,a1
    800040ce:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800040d0:	411c                	lw	a5,0(a0)
    800040d2:	4705                	li	a4,1
    800040d4:	02e78263          	beq	a5,a4,800040f8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800040d8:	470d                	li	a4,3
    800040da:	02e78463          	beq	a5,a4,80004102 <filewrite+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800040de:	4709                	li	a4,2
    800040e0:	0ce79563          	bne	a5,a4,800041aa <filewrite+0x100>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800040e4:	0ac05163          	blez	a2,80004186 <filewrite+0xdc>
    int i = 0;
    800040e8:	4981                	li	s3,0
    800040ea:	6b05                	lui	s6,0x1
    800040ec:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800040f0:	6b85                	lui	s7,0x1
    800040f2:	c00b8b9b          	addiw	s7,s7,-1024
    800040f6:	a041                	j	80004176 <filewrite+0xcc>
    ret = pipewrite(f->pipe, addr, n);
    800040f8:	6908                	ld	a0,16(a0)
    800040fa:	1e2000ef          	jal	ra,800042dc <pipewrite>
    800040fe:	8a2a                	mv	s4,a0
    80004100:	a071                	j	8000418c <filewrite+0xe2>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004102:	02451783          	lh	a5,36(a0)
    80004106:	03079693          	slli	a3,a5,0x30
    8000410a:	92c1                	srli	a3,a3,0x30
    8000410c:	4725                	li	a4,9
    8000410e:	0ad76663          	bltu	a4,a3,800041ba <filewrite+0x110>
    80004112:	0792                	slli	a5,a5,0x4
    80004114:	0001c717          	auipc	a4,0x1c
    80004118:	c3c70713          	addi	a4,a4,-964 # 8001fd50 <devsw>
    8000411c:	97ba                	add	a5,a5,a4
    8000411e:	679c                	ld	a5,8(a5)
    80004120:	cfd9                	beqz	a5,800041be <filewrite+0x114>
    ret = devsw[f->major].write(1, addr, n);
    80004122:	4505                	li	a0,1
    80004124:	9782                	jalr	a5
    80004126:	8a2a                	mv	s4,a0
    80004128:	a095                	j	8000418c <filewrite+0xe2>
    8000412a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000412e:	9adff0ef          	jal	ra,80003ada <begin_op>
      ilock(f->ip);
    80004132:	01893503          	ld	a0,24(s2)
    80004136:	916ff0ef          	jal	ra,8000324c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000413a:	8762                	mv	a4,s8
    8000413c:	02092683          	lw	a3,32(s2)
    80004140:	01598633          	add	a2,s3,s5
    80004144:	4585                	li	a1,1
    80004146:	01893503          	ld	a0,24(s2)
    8000414a:	c36ff0ef          	jal	ra,80003580 <writei>
    8000414e:	84aa                	mv	s1,a0
    80004150:	00a05763          	blez	a0,8000415e <filewrite+0xb4>
        f->off += r;
    80004154:	02092783          	lw	a5,32(s2)
    80004158:	9fa9                	addw	a5,a5,a0
    8000415a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000415e:	01893503          	ld	a0,24(s2)
    80004162:	994ff0ef          	jal	ra,800032f6 <iunlock>
      end_op();
    80004166:	9e5ff0ef          	jal	ra,80003b4a <end_op>

      if(r != n1){
    8000416a:	009c1f63          	bne	s8,s1,80004188 <filewrite+0xde>
        // error from writei
        break;
      }
      i += r;
    8000416e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004172:	0149db63          	bge	s3,s4,80004188 <filewrite+0xde>
      int n1 = n - i;
    80004176:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000417a:	84be                	mv	s1,a5
    8000417c:	2781                	sext.w	a5,a5
    8000417e:	fafb56e3          	bge	s6,a5,8000412a <filewrite+0x80>
    80004182:	84de                	mv	s1,s7
    80004184:	b75d                	j	8000412a <filewrite+0x80>
    int i = 0;
    80004186:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004188:	013a1f63          	bne	s4,s3,800041a6 <filewrite+0xfc>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000418c:	8552                	mv	a0,s4
    8000418e:	60a6                	ld	ra,72(sp)
    80004190:	6406                	ld	s0,64(sp)
    80004192:	74e2                	ld	s1,56(sp)
    80004194:	7942                	ld	s2,48(sp)
    80004196:	79a2                	ld	s3,40(sp)
    80004198:	7a02                	ld	s4,32(sp)
    8000419a:	6ae2                	ld	s5,24(sp)
    8000419c:	6b42                	ld	s6,16(sp)
    8000419e:	6ba2                	ld	s7,8(sp)
    800041a0:	6c02                	ld	s8,0(sp)
    800041a2:	6161                	addi	sp,sp,80
    800041a4:	8082                	ret
    ret = (i == n ? n : -1);
    800041a6:	5a7d                	li	s4,-1
    800041a8:	b7d5                	j	8000418c <filewrite+0xe2>
    panic("filewrite");
    800041aa:	00003517          	auipc	a0,0x3
    800041ae:	64650513          	addi	a0,a0,1606 # 800077f0 <syscallnames+0x270>
    800041b2:	e2afc0ef          	jal	ra,800007dc <panic>
    return -1;
    800041b6:	5a7d                	li	s4,-1
    800041b8:	bfd1                	j	8000418c <filewrite+0xe2>
      return -1;
    800041ba:	5a7d                	li	s4,-1
    800041bc:	bfc1                	j	8000418c <filewrite+0xe2>
    800041be:	5a7d                	li	s4,-1
    800041c0:	b7f1                	j	8000418c <filewrite+0xe2>

00000000800041c2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800041c2:	7179                	addi	sp,sp,-48
    800041c4:	f406                	sd	ra,40(sp)
    800041c6:	f022                	sd	s0,32(sp)
    800041c8:	ec26                	sd	s1,24(sp)
    800041ca:	e84a                	sd	s2,16(sp)
    800041cc:	e44e                	sd	s3,8(sp)
    800041ce:	e052                	sd	s4,0(sp)
    800041d0:	1800                	addi	s0,sp,48
    800041d2:	84aa                	mv	s1,a0
    800041d4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800041d6:	0005b023          	sd	zero,0(a1)
    800041da:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800041de:	c75ff0ef          	jal	ra,80003e52 <filealloc>
    800041e2:	e088                	sd	a0,0(s1)
    800041e4:	cd35                	beqz	a0,80004260 <pipealloc+0x9e>
    800041e6:	c6dff0ef          	jal	ra,80003e52 <filealloc>
    800041ea:	00aa3023          	sd	a0,0(s4)
    800041ee:	c52d                	beqz	a0,80004258 <pipealloc+0x96>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800041f0:	983fc0ef          	jal	ra,80000b72 <kalloc>
    800041f4:	892a                	mv	s2,a0
    800041f6:	cd31                	beqz	a0,80004252 <pipealloc+0x90>
    goto bad;
  pi->readopen = 1;
    800041f8:	4985                	li	s3,1
    800041fa:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800041fe:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004202:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004206:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000420a:	00003597          	auipc	a1,0x3
    8000420e:	21e58593          	addi	a1,a1,542 # 80007428 <states.0+0x1b0>
    80004212:	9b1fc0ef          	jal	ra,80000bc2 <initlock>
  (*f0)->type = FD_PIPE;
    80004216:	609c                	ld	a5,0(s1)
    80004218:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000421c:	609c                	ld	a5,0(s1)
    8000421e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004222:	609c                	ld	a5,0(s1)
    80004224:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004228:	609c                	ld	a5,0(s1)
    8000422a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000422e:	000a3783          	ld	a5,0(s4)
    80004232:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004236:	000a3783          	ld	a5,0(s4)
    8000423a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000423e:	000a3783          	ld	a5,0(s4)
    80004242:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004246:	000a3783          	ld	a5,0(s4)
    8000424a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000424e:	4501                	li	a0,0
    80004250:	a005                	j	80004270 <pipealloc+0xae>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004252:	6088                	ld	a0,0(s1)
    80004254:	e501                	bnez	a0,8000425c <pipealloc+0x9a>
    80004256:	a029                	j	80004260 <pipealloc+0x9e>
    80004258:	6088                	ld	a0,0(s1)
    8000425a:	c11d                	beqz	a0,80004280 <pipealloc+0xbe>
    fileclose(*f0);
    8000425c:	c9bff0ef          	jal	ra,80003ef6 <fileclose>
  if(*f1)
    80004260:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004264:	557d                	li	a0,-1
  if(*f1)
    80004266:	c789                	beqz	a5,80004270 <pipealloc+0xae>
    fileclose(*f1);
    80004268:	853e                	mv	a0,a5
    8000426a:	c8dff0ef          	jal	ra,80003ef6 <fileclose>
  return -1;
    8000426e:	557d                	li	a0,-1
}
    80004270:	70a2                	ld	ra,40(sp)
    80004272:	7402                	ld	s0,32(sp)
    80004274:	64e2                	ld	s1,24(sp)
    80004276:	6942                	ld	s2,16(sp)
    80004278:	69a2                	ld	s3,8(sp)
    8000427a:	6a02                	ld	s4,0(sp)
    8000427c:	6145                	addi	sp,sp,48
    8000427e:	8082                	ret
  return -1;
    80004280:	557d                	li	a0,-1
    80004282:	b7fd                	j	80004270 <pipealloc+0xae>

0000000080004284 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004284:	1101                	addi	sp,sp,-32
    80004286:	ec06                	sd	ra,24(sp)
    80004288:	e822                	sd	s0,16(sp)
    8000428a:	e426                	sd	s1,8(sp)
    8000428c:	e04a                	sd	s2,0(sp)
    8000428e:	1000                	addi	s0,sp,32
    80004290:	84aa                	mv	s1,a0
    80004292:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004294:	9affc0ef          	jal	ra,80000c42 <acquire>
  if(writable){
    80004298:	02090763          	beqz	s2,800042c6 <pipeclose+0x42>
    pi->writeopen = 0;
    8000429c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800042a0:	21848513          	addi	a0,s1,536
    800042a4:	c69fd0ef          	jal	ra,80001f0c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800042a8:	2204b783          	ld	a5,544(s1)
    800042ac:	e785                	bnez	a5,800042d4 <pipeclose+0x50>
    release(&pi->lock);
    800042ae:	8526                	mv	a0,s1
    800042b0:	a2bfc0ef          	jal	ra,80000cda <release>
    kfree((char*)pi);
    800042b4:	8526                	mv	a0,s1
    800042b6:	fdcfc0ef          	jal	ra,80000a92 <kfree>
  } else
    release(&pi->lock);
}
    800042ba:	60e2                	ld	ra,24(sp)
    800042bc:	6442                	ld	s0,16(sp)
    800042be:	64a2                	ld	s1,8(sp)
    800042c0:	6902                	ld	s2,0(sp)
    800042c2:	6105                	addi	sp,sp,32
    800042c4:	8082                	ret
    pi->readopen = 0;
    800042c6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800042ca:	21c48513          	addi	a0,s1,540
    800042ce:	c3ffd0ef          	jal	ra,80001f0c <wakeup>
    800042d2:	bfd9                	j	800042a8 <pipeclose+0x24>
    release(&pi->lock);
    800042d4:	8526                	mv	a0,s1
    800042d6:	a05fc0ef          	jal	ra,80000cda <release>
}
    800042da:	b7c5                	j	800042ba <pipeclose+0x36>

00000000800042dc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800042dc:	711d                	addi	sp,sp,-96
    800042de:	ec86                	sd	ra,88(sp)
    800042e0:	e8a2                	sd	s0,80(sp)
    800042e2:	e4a6                	sd	s1,72(sp)
    800042e4:	e0ca                	sd	s2,64(sp)
    800042e6:	fc4e                	sd	s3,56(sp)
    800042e8:	f852                	sd	s4,48(sp)
    800042ea:	f456                	sd	s5,40(sp)
    800042ec:	f05a                	sd	s6,32(sp)
    800042ee:	ec5e                	sd	s7,24(sp)
    800042f0:	e862                	sd	s8,16(sp)
    800042f2:	1080                	addi	s0,sp,96
    800042f4:	84aa                	mv	s1,a0
    800042f6:	8aae                	mv	s5,a1
    800042f8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800042fa:	de0fd0ef          	jal	ra,800018da <myproc>
    800042fe:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004300:	8526                	mv	a0,s1
    80004302:	941fc0ef          	jal	ra,80000c42 <acquire>
  while(i < n){
    80004306:	09405c63          	blez	s4,8000439e <pipewrite+0xc2>
  int i = 0;
    8000430a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000430c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000430e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004312:	21c48b93          	addi	s7,s1,540
    80004316:	a81d                	j	8000434c <pipewrite+0x70>
      release(&pi->lock);
    80004318:	8526                	mv	a0,s1
    8000431a:	9c1fc0ef          	jal	ra,80000cda <release>
      return -1;
    8000431e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004320:	854a                	mv	a0,s2
    80004322:	60e6                	ld	ra,88(sp)
    80004324:	6446                	ld	s0,80(sp)
    80004326:	64a6                	ld	s1,72(sp)
    80004328:	6906                	ld	s2,64(sp)
    8000432a:	79e2                	ld	s3,56(sp)
    8000432c:	7a42                	ld	s4,48(sp)
    8000432e:	7aa2                	ld	s5,40(sp)
    80004330:	7b02                	ld	s6,32(sp)
    80004332:	6be2                	ld	s7,24(sp)
    80004334:	6c42                	ld	s8,16(sp)
    80004336:	6125                	addi	sp,sp,96
    80004338:	8082                	ret
      wakeup(&pi->nread);
    8000433a:	8562                	mv	a0,s8
    8000433c:	bd1fd0ef          	jal	ra,80001f0c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004340:	85a6                	mv	a1,s1
    80004342:	855e                	mv	a0,s7
    80004344:	b7dfd0ef          	jal	ra,80001ec0 <sleep>
  while(i < n){
    80004348:	05495c63          	bge	s2,s4,800043a0 <pipewrite+0xc4>
    if(pi->readopen == 0 || killed(pr)){
    8000434c:	2204a783          	lw	a5,544(s1)
    80004350:	d7e1                	beqz	a5,80004318 <pipewrite+0x3c>
    80004352:	854e                	mv	a0,s3
    80004354:	da5fd0ef          	jal	ra,800020f8 <killed>
    80004358:	f161                	bnez	a0,80004318 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000435a:	2184a783          	lw	a5,536(s1)
    8000435e:	21c4a703          	lw	a4,540(s1)
    80004362:	2007879b          	addiw	a5,a5,512
    80004366:	fcf70ae3          	beq	a4,a5,8000433a <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000436a:	4685                	li	a3,1
    8000436c:	01590633          	add	a2,s2,s5
    80004370:	faf40593          	addi	a1,s0,-81
    80004374:	0589b503          	ld	a0,88(s3)
    80004378:	b76fd0ef          	jal	ra,800016ee <copyin>
    8000437c:	03650263          	beq	a0,s6,800043a0 <pipewrite+0xc4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004380:	21c4a783          	lw	a5,540(s1)
    80004384:	0017871b          	addiw	a4,a5,1
    80004388:	20e4ae23          	sw	a4,540(s1)
    8000438c:	1ff7f793          	andi	a5,a5,511
    80004390:	97a6                	add	a5,a5,s1
    80004392:	faf44703          	lbu	a4,-81(s0)
    80004396:	00e78c23          	sb	a4,24(a5)
      i++;
    8000439a:	2905                	addiw	s2,s2,1
    8000439c:	b775                	j	80004348 <pipewrite+0x6c>
  int i = 0;
    8000439e:	4901                	li	s2,0
  wakeup(&pi->nread);
    800043a0:	21848513          	addi	a0,s1,536
    800043a4:	b69fd0ef          	jal	ra,80001f0c <wakeup>
  release(&pi->lock);
    800043a8:	8526                	mv	a0,s1
    800043aa:	931fc0ef          	jal	ra,80000cda <release>
  return i;
    800043ae:	bf8d                	j	80004320 <pipewrite+0x44>

00000000800043b0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800043b0:	715d                	addi	sp,sp,-80
    800043b2:	e486                	sd	ra,72(sp)
    800043b4:	e0a2                	sd	s0,64(sp)
    800043b6:	fc26                	sd	s1,56(sp)
    800043b8:	f84a                	sd	s2,48(sp)
    800043ba:	f44e                	sd	s3,40(sp)
    800043bc:	f052                	sd	s4,32(sp)
    800043be:	ec56                	sd	s5,24(sp)
    800043c0:	e85a                	sd	s6,16(sp)
    800043c2:	0880                	addi	s0,sp,80
    800043c4:	84aa                	mv	s1,a0
    800043c6:	892e                	mv	s2,a1
    800043c8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800043ca:	d10fd0ef          	jal	ra,800018da <myproc>
    800043ce:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800043d0:	8526                	mv	a0,s1
    800043d2:	871fc0ef          	jal	ra,80000c42 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800043d6:	2184a703          	lw	a4,536(s1)
    800043da:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800043de:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800043e2:	02f71363          	bne	a4,a5,80004408 <piperead+0x58>
    800043e6:	2244a783          	lw	a5,548(s1)
    800043ea:	cf99                	beqz	a5,80004408 <piperead+0x58>
    if(killed(pr)){
    800043ec:	8552                	mv	a0,s4
    800043ee:	d0bfd0ef          	jal	ra,800020f8 <killed>
    800043f2:	e141                	bnez	a0,80004472 <piperead+0xc2>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800043f4:	85a6                	mv	a1,s1
    800043f6:	854e                	mv	a0,s3
    800043f8:	ac9fd0ef          	jal	ra,80001ec0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800043fc:	2184a703          	lw	a4,536(s1)
    80004400:	21c4a783          	lw	a5,540(s1)
    80004404:	fef701e3          	beq	a4,a5,800043e6 <piperead+0x36>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004408:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000440a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000440c:	05505163          	blez	s5,8000444e <piperead+0x9e>
    if(pi->nread == pi->nwrite)
    80004410:	2184a783          	lw	a5,536(s1)
    80004414:	21c4a703          	lw	a4,540(s1)
    80004418:	02f70b63          	beq	a4,a5,8000444e <piperead+0x9e>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000441c:	0017871b          	addiw	a4,a5,1
    80004420:	20e4ac23          	sw	a4,536(s1)
    80004424:	1ff7f793          	andi	a5,a5,511
    80004428:	97a6                	add	a5,a5,s1
    8000442a:	0187c783          	lbu	a5,24(a5)
    8000442e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004432:	4685                	li	a3,1
    80004434:	fbf40613          	addi	a2,s0,-65
    80004438:	85ca                	mv	a1,s2
    8000443a:	058a3503          	ld	a0,88(s4)
    8000443e:	9eafd0ef          	jal	ra,80001628 <copyout>
    80004442:	01650663          	beq	a0,s6,8000444e <piperead+0x9e>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004446:	2985                	addiw	s3,s3,1
    80004448:	0905                	addi	s2,s2,1
    8000444a:	fd3a93e3          	bne	s5,s3,80004410 <piperead+0x60>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000444e:	21c48513          	addi	a0,s1,540
    80004452:	abbfd0ef          	jal	ra,80001f0c <wakeup>
  release(&pi->lock);
    80004456:	8526                	mv	a0,s1
    80004458:	883fc0ef          	jal	ra,80000cda <release>
  return i;
}
    8000445c:	854e                	mv	a0,s3
    8000445e:	60a6                	ld	ra,72(sp)
    80004460:	6406                	ld	s0,64(sp)
    80004462:	74e2                	ld	s1,56(sp)
    80004464:	7942                	ld	s2,48(sp)
    80004466:	79a2                	ld	s3,40(sp)
    80004468:	7a02                	ld	s4,32(sp)
    8000446a:	6ae2                	ld	s5,24(sp)
    8000446c:	6b42                	ld	s6,16(sp)
    8000446e:	6161                	addi	sp,sp,80
    80004470:	8082                	ret
      release(&pi->lock);
    80004472:	8526                	mv	a0,s1
    80004474:	867fc0ef          	jal	ra,80000cda <release>
      return -1;
    80004478:	59fd                	li	s3,-1
    8000447a:	b7cd                	j	8000445c <piperead+0xac>

000000008000447c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000447c:	1141                	addi	sp,sp,-16
    8000447e:	e422                	sd	s0,8(sp)
    80004480:	0800                	addi	s0,sp,16
    80004482:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004484:	8905                	andi	a0,a0,1
    80004486:	c111                	beqz	a0,8000448a <flags2perm+0xe>
      perm = PTE_X;
    80004488:	4521                	li	a0,8
    if(flags & 0x2)
    8000448a:	8b89                	andi	a5,a5,2
    8000448c:	c399                	beqz	a5,80004492 <flags2perm+0x16>
      perm |= PTE_W;
    8000448e:	00456513          	ori	a0,a0,4
    return perm;
}
    80004492:	6422                	ld	s0,8(sp)
    80004494:	0141                	addi	sp,sp,16
    80004496:	8082                	ret

0000000080004498 <exec>:

int
exec(char *path, char **argv)
{
    80004498:	de010113          	addi	sp,sp,-544
    8000449c:	20113c23          	sd	ra,536(sp)
    800044a0:	20813823          	sd	s0,528(sp)
    800044a4:	20913423          	sd	s1,520(sp)
    800044a8:	21213023          	sd	s2,512(sp)
    800044ac:	ffce                	sd	s3,504(sp)
    800044ae:	fbd2                	sd	s4,496(sp)
    800044b0:	f7d6                	sd	s5,488(sp)
    800044b2:	f3da                	sd	s6,480(sp)
    800044b4:	efde                	sd	s7,472(sp)
    800044b6:	ebe2                	sd	s8,464(sp)
    800044b8:	e7e6                	sd	s9,456(sp)
    800044ba:	e3ea                	sd	s10,448(sp)
    800044bc:	ff6e                	sd	s11,440(sp)
    800044be:	1400                	addi	s0,sp,544
    800044c0:	892a                	mv	s2,a0
    800044c2:	dea43423          	sd	a0,-536(s0)
    800044c6:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800044ca:	c10fd0ef          	jal	ra,800018da <myproc>
    800044ce:	84aa                	mv	s1,a0

  begin_op();
    800044d0:	e0aff0ef          	jal	ra,80003ada <begin_op>

  if((ip = namei(path)) == 0){
    800044d4:	854a                	mv	a0,s2
    800044d6:	c28ff0ef          	jal	ra,800038fe <namei>
    800044da:	c13d                	beqz	a0,80004540 <exec+0xa8>
    800044dc:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800044de:	d6ffe0ef          	jal	ra,8000324c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800044e2:	04000713          	li	a4,64
    800044e6:	4681                	li	a3,0
    800044e8:	e5040613          	addi	a2,s0,-432
    800044ec:	4581                	li	a1,0
    800044ee:	8556                	mv	a0,s5
    800044f0:	fadfe0ef          	jal	ra,8000349c <readi>
    800044f4:	04000793          	li	a5,64
    800044f8:	00f51a63          	bne	a0,a5,8000450c <exec+0x74>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800044fc:	e5042703          	lw	a4,-432(s0)
    80004500:	464c47b7          	lui	a5,0x464c4
    80004504:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004508:	04f70063          	beq	a4,a5,80004548 <exec+0xb0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000450c:	8556                	mv	a0,s5
    8000450e:	f45fe0ef          	jal	ra,80003452 <iunlockput>
    end_op();
    80004512:	e38ff0ef          	jal	ra,80003b4a <end_op>
  }
  return -1;
    80004516:	557d                	li	a0,-1
}
    80004518:	21813083          	ld	ra,536(sp)
    8000451c:	21013403          	ld	s0,528(sp)
    80004520:	20813483          	ld	s1,520(sp)
    80004524:	20013903          	ld	s2,512(sp)
    80004528:	79fe                	ld	s3,504(sp)
    8000452a:	7a5e                	ld	s4,496(sp)
    8000452c:	7abe                	ld	s5,488(sp)
    8000452e:	7b1e                	ld	s6,480(sp)
    80004530:	6bfe                	ld	s7,472(sp)
    80004532:	6c5e                	ld	s8,464(sp)
    80004534:	6cbe                	ld	s9,456(sp)
    80004536:	6d1e                	ld	s10,448(sp)
    80004538:	7dfa                	ld	s11,440(sp)
    8000453a:	22010113          	addi	sp,sp,544
    8000453e:	8082                	ret
    end_op();
    80004540:	e0aff0ef          	jal	ra,80003b4a <end_op>
    return -1;
    80004544:	557d                	li	a0,-1
    80004546:	bfc9                	j	80004518 <exec+0x80>
  if((pagetable = proc_pagetable(p)) == 0)
    80004548:	8526                	mv	a0,s1
    8000454a:	c96fd0ef          	jal	ra,800019e0 <proc_pagetable>
    8000454e:	8b2a                	mv	s6,a0
    80004550:	dd55                	beqz	a0,8000450c <exec+0x74>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004552:	e7042783          	lw	a5,-400(s0)
    80004556:	e8845703          	lhu	a4,-376(s0)
    8000455a:	c325                	beqz	a4,800045ba <exec+0x122>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000455c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000455e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004562:	6a05                	lui	s4,0x1
    80004564:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004568:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000456c:	6d85                	lui	s11,0x1
    8000456e:	7d7d                	lui	s10,0xfffff
    80004570:	a411                	j	80004774 <exec+0x2dc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004572:	00003517          	auipc	a0,0x3
    80004576:	28e50513          	addi	a0,a0,654 # 80007800 <syscallnames+0x280>
    8000457a:	a62fc0ef          	jal	ra,800007dc <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000457e:	874a                	mv	a4,s2
    80004580:	009c86bb          	addw	a3,s9,s1
    80004584:	4581                	li	a1,0
    80004586:	8556                	mv	a0,s5
    80004588:	f15fe0ef          	jal	ra,8000349c <readi>
    8000458c:	2501                	sext.w	a0,a0
    8000458e:	18a91263          	bne	s2,a0,80004712 <exec+0x27a>
  for(i = 0; i < sz; i += PGSIZE){
    80004592:	009d84bb          	addw	s1,s11,s1
    80004596:	013d09bb          	addw	s3,s10,s3
    8000459a:	1b74fd63          	bgeu	s1,s7,80004754 <exec+0x2bc>
    pa = walkaddr(pagetable, va + i);
    8000459e:	02049593          	slli	a1,s1,0x20
    800045a2:	9181                	srli	a1,a1,0x20
    800045a4:	95e2                	add	a1,a1,s8
    800045a6:	855a                	mv	a0,s6
    800045a8:	a85fc0ef          	jal	ra,8000102c <walkaddr>
    800045ac:	862a                	mv	a2,a0
    if(pa == 0)
    800045ae:	d171                	beqz	a0,80004572 <exec+0xda>
      n = PGSIZE;
    800045b0:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800045b2:	fd49f6e3          	bgeu	s3,s4,8000457e <exec+0xe6>
      n = sz - i;
    800045b6:	894e                	mv	s2,s3
    800045b8:	b7d9                	j	8000457e <exec+0xe6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800045ba:	4901                	li	s2,0
  iunlockput(ip);
    800045bc:	8556                	mv	a0,s5
    800045be:	e95fe0ef          	jal	ra,80003452 <iunlockput>
  end_op();
    800045c2:	d88ff0ef          	jal	ra,80003b4a <end_op>
  p = myproc();
    800045c6:	b14fd0ef          	jal	ra,800018da <myproc>
    800045ca:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800045cc:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    800045d0:	6785                	lui	a5,0x1
    800045d2:	17fd                	addi	a5,a5,-1
    800045d4:	993e                	add	s2,s2,a5
    800045d6:	77fd                	lui	a5,0xfffff
    800045d8:	00f977b3          	and	a5,s2,a5
    800045dc:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800045e0:	4691                	li	a3,4
    800045e2:	6609                	lui	a2,0x2
    800045e4:	963e                	add	a2,a2,a5
    800045e6:	85be                	mv	a1,a5
    800045e8:	855a                	mv	a0,s6
    800045ea:	d0dfc0ef          	jal	ra,800012f6 <uvmalloc>
    800045ee:	8c2a                	mv	s8,a0
  ip = 0;
    800045f0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800045f2:	12050063          	beqz	a0,80004712 <exec+0x27a>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    800045f6:	75f9                	lui	a1,0xffffe
    800045f8:	95aa                	add	a1,a1,a0
    800045fa:	855a                	mv	a0,s6
    800045fc:	ec1fc0ef          	jal	ra,800014bc <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80004600:	7afd                	lui	s5,0xfffff
    80004602:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004604:	df043783          	ld	a5,-528(s0)
    80004608:	6388                	ld	a0,0(a5)
    8000460a:	c135                	beqz	a0,8000466e <exec+0x1d6>
    8000460c:	e9040993          	addi	s3,s0,-368
    80004610:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004614:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004616:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004618:	877fc0ef          	jal	ra,80000e8e <strlen>
    8000461c:	0015079b          	addiw	a5,a0,1
    80004620:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004624:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004628:	11596a63          	bltu	s2,s5,8000473c <exec+0x2a4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000462c:	df043d83          	ld	s11,-528(s0)
    80004630:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004634:	8552                	mv	a0,s4
    80004636:	859fc0ef          	jal	ra,80000e8e <strlen>
    8000463a:	0015069b          	addiw	a3,a0,1
    8000463e:	8652                	mv	a2,s4
    80004640:	85ca                	mv	a1,s2
    80004642:	855a                	mv	a0,s6
    80004644:	fe5fc0ef          	jal	ra,80001628 <copyout>
    80004648:	0e054e63          	bltz	a0,80004744 <exec+0x2ac>
    ustack[argc] = sp;
    8000464c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004650:	0485                	addi	s1,s1,1
    80004652:	008d8793          	addi	a5,s11,8
    80004656:	def43823          	sd	a5,-528(s0)
    8000465a:	008db503          	ld	a0,8(s11)
    8000465e:	c911                	beqz	a0,80004672 <exec+0x1da>
    if(argc >= MAXARG)
    80004660:	09a1                	addi	s3,s3,8
    80004662:	fb3c9be3          	bne	s9,s3,80004618 <exec+0x180>
  sz = sz1;
    80004666:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000466a:	4a81                	li	s5,0
    8000466c:	a05d                	j	80004712 <exec+0x27a>
  sp = sz;
    8000466e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004670:	4481                	li	s1,0
  ustack[argc] = 0;
    80004672:	00349793          	slli	a5,s1,0x3
    80004676:	f9040713          	addi	a4,s0,-112
    8000467a:	97ba                	add	a5,a5,a4
    8000467c:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffde018>
  sp -= (argc+1) * sizeof(uint64);
    80004680:	00148693          	addi	a3,s1,1
    80004684:	068e                	slli	a3,a3,0x3
    80004686:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000468a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000468e:	01597663          	bgeu	s2,s5,8000469a <exec+0x202>
  sz = sz1;
    80004692:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004696:	4a81                	li	s5,0
    80004698:	a8ad                	j	80004712 <exec+0x27a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000469a:	e9040613          	addi	a2,s0,-368
    8000469e:	85ca                	mv	a1,s2
    800046a0:	855a                	mv	a0,s6
    800046a2:	f87fc0ef          	jal	ra,80001628 <copyout>
    800046a6:	0a054363          	bltz	a0,8000474c <exec+0x2b4>
  p->trapframe->a1 = sp;
    800046aa:	060bb783          	ld	a5,96(s7) # 1060 <_entry-0x7fffefa0>
    800046ae:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800046b2:	de843783          	ld	a5,-536(s0)
    800046b6:	0007c703          	lbu	a4,0(a5)
    800046ba:	cf11                	beqz	a4,800046d6 <exec+0x23e>
    800046bc:	0785                	addi	a5,a5,1
    if(*s == '/')
    800046be:	02f00693          	li	a3,47
    800046c2:	a039                	j	800046d0 <exec+0x238>
      last = s+1;
    800046c4:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800046c8:	0785                	addi	a5,a5,1
    800046ca:	fff7c703          	lbu	a4,-1(a5)
    800046ce:	c701                	beqz	a4,800046d6 <exec+0x23e>
    if(*s == '/')
    800046d0:	fed71ce3          	bne	a4,a3,800046c8 <exec+0x230>
    800046d4:	bfc5                	j	800046c4 <exec+0x22c>
  safestrcpy(p->name, last, sizeof(p->name));
    800046d6:	4641                	li	a2,16
    800046d8:	de843583          	ld	a1,-536(s0)
    800046dc:	160b8513          	addi	a0,s7,352
    800046e0:	f7cfc0ef          	jal	ra,80000e5c <safestrcpy>
  oldpagetable = p->pagetable;
    800046e4:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800046e8:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800046ec:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800046f0:	060bb783          	ld	a5,96(s7)
    800046f4:	e6843703          	ld	a4,-408(s0)
    800046f8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800046fa:	060bb783          	ld	a5,96(s7)
    800046fe:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004702:	85ea                	mv	a1,s10
    80004704:	b60fd0ef          	jal	ra,80001a64 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004708:	0004851b          	sext.w	a0,s1
    8000470c:	b531                	j	80004518 <exec+0x80>
    8000470e:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004712:	df843583          	ld	a1,-520(s0)
    80004716:	855a                	mv	a0,s6
    80004718:	b4cfd0ef          	jal	ra,80001a64 <proc_freepagetable>
  if(ip){
    8000471c:	de0a98e3          	bnez	s5,8000450c <exec+0x74>
  return -1;
    80004720:	557d                	li	a0,-1
    80004722:	bbdd                	j	80004518 <exec+0x80>
    80004724:	df243c23          	sd	s2,-520(s0)
    80004728:	b7ed                	j	80004712 <exec+0x27a>
    8000472a:	df243c23          	sd	s2,-520(s0)
    8000472e:	b7d5                	j	80004712 <exec+0x27a>
    80004730:	df243c23          	sd	s2,-520(s0)
    80004734:	bff9                	j	80004712 <exec+0x27a>
    80004736:	df243c23          	sd	s2,-520(s0)
    8000473a:	bfe1                	j	80004712 <exec+0x27a>
  sz = sz1;
    8000473c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004740:	4a81                	li	s5,0
    80004742:	bfc1                	j	80004712 <exec+0x27a>
  sz = sz1;
    80004744:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004748:	4a81                	li	s5,0
    8000474a:	b7e1                	j	80004712 <exec+0x27a>
  sz = sz1;
    8000474c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004750:	4a81                	li	s5,0
    80004752:	b7c1                	j	80004712 <exec+0x27a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004754:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004758:	e0843783          	ld	a5,-504(s0)
    8000475c:	0017869b          	addiw	a3,a5,1
    80004760:	e0d43423          	sd	a3,-504(s0)
    80004764:	e0043783          	ld	a5,-512(s0)
    80004768:	0387879b          	addiw	a5,a5,56
    8000476c:	e8845703          	lhu	a4,-376(s0)
    80004770:	e4e6d6e3          	bge	a3,a4,800045bc <exec+0x124>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004774:	2781                	sext.w	a5,a5
    80004776:	e0f43023          	sd	a5,-512(s0)
    8000477a:	03800713          	li	a4,56
    8000477e:	86be                	mv	a3,a5
    80004780:	e1840613          	addi	a2,s0,-488
    80004784:	4581                	li	a1,0
    80004786:	8556                	mv	a0,s5
    80004788:	d15fe0ef          	jal	ra,8000349c <readi>
    8000478c:	03800793          	li	a5,56
    80004790:	f6f51fe3          	bne	a0,a5,8000470e <exec+0x276>
    if(ph.type != ELF_PROG_LOAD)
    80004794:	e1842783          	lw	a5,-488(s0)
    80004798:	4705                	li	a4,1
    8000479a:	fae79fe3          	bne	a5,a4,80004758 <exec+0x2c0>
    if(ph.memsz < ph.filesz)
    8000479e:	e4043483          	ld	s1,-448(s0)
    800047a2:	e3843783          	ld	a5,-456(s0)
    800047a6:	f6f4efe3          	bltu	s1,a5,80004724 <exec+0x28c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800047aa:	e2843783          	ld	a5,-472(s0)
    800047ae:	94be                	add	s1,s1,a5
    800047b0:	f6f4ede3          	bltu	s1,a5,8000472a <exec+0x292>
    if(ph.vaddr % PGSIZE != 0)
    800047b4:	de043703          	ld	a4,-544(s0)
    800047b8:	8ff9                	and	a5,a5,a4
    800047ba:	fbbd                	bnez	a5,80004730 <exec+0x298>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800047bc:	e1c42503          	lw	a0,-484(s0)
    800047c0:	cbdff0ef          	jal	ra,8000447c <flags2perm>
    800047c4:	86aa                	mv	a3,a0
    800047c6:	8626                	mv	a2,s1
    800047c8:	85ca                	mv	a1,s2
    800047ca:	855a                	mv	a0,s6
    800047cc:	b2bfc0ef          	jal	ra,800012f6 <uvmalloc>
    800047d0:	dea43c23          	sd	a0,-520(s0)
    800047d4:	d12d                	beqz	a0,80004736 <exec+0x29e>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800047d6:	e2843c03          	ld	s8,-472(s0)
    800047da:	e2042c83          	lw	s9,-480(s0)
    800047de:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800047e2:	f60b89e3          	beqz	s7,80004754 <exec+0x2bc>
    800047e6:	89de                	mv	s3,s7
    800047e8:	4481                	li	s1,0
    800047ea:	bb55                	j	8000459e <exec+0x106>

00000000800047ec <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800047ec:	7179                	addi	sp,sp,-48
    800047ee:	f406                	sd	ra,40(sp)
    800047f0:	f022                	sd	s0,32(sp)
    800047f2:	ec26                	sd	s1,24(sp)
    800047f4:	e84a                	sd	s2,16(sp)
    800047f6:	1800                	addi	s0,sp,48
    800047f8:	892e                	mv	s2,a1
    800047fa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800047fc:	fdc40593          	addi	a1,s0,-36
    80004800:	fc1fd0ef          	jal	ra,800027c0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004804:	fdc42703          	lw	a4,-36(s0)
    80004808:	47bd                	li	a5,15
    8000480a:	02e7e963          	bltu	a5,a4,8000483c <argfd+0x50>
    8000480e:	8ccfd0ef          	jal	ra,800018da <myproc>
    80004812:	fdc42703          	lw	a4,-36(s0)
    80004816:	01a70793          	addi	a5,a4,26
    8000481a:	078e                	slli	a5,a5,0x3
    8000481c:	953e                	add	a0,a0,a5
    8000481e:	651c                	ld	a5,8(a0)
    80004820:	c385                	beqz	a5,80004840 <argfd+0x54>
    return -1;
  if(pfd)
    80004822:	00090463          	beqz	s2,8000482a <argfd+0x3e>
    *pfd = fd;
    80004826:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000482a:	4501                	li	a0,0
  if(pf)
    8000482c:	c091                	beqz	s1,80004830 <argfd+0x44>
    *pf = f;
    8000482e:	e09c                	sd	a5,0(s1)
}
    80004830:	70a2                	ld	ra,40(sp)
    80004832:	7402                	ld	s0,32(sp)
    80004834:	64e2                	ld	s1,24(sp)
    80004836:	6942                	ld	s2,16(sp)
    80004838:	6145                	addi	sp,sp,48
    8000483a:	8082                	ret
    return -1;
    8000483c:	557d                	li	a0,-1
    8000483e:	bfcd                	j	80004830 <argfd+0x44>
    80004840:	557d                	li	a0,-1
    80004842:	b7fd                	j	80004830 <argfd+0x44>

0000000080004844 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004844:	1101                	addi	sp,sp,-32
    80004846:	ec06                	sd	ra,24(sp)
    80004848:	e822                	sd	s0,16(sp)
    8000484a:	e426                	sd	s1,8(sp)
    8000484c:	1000                	addi	s0,sp,32
    8000484e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004850:	88afd0ef          	jal	ra,800018da <myproc>
    80004854:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004856:	0d850793          	addi	a5,a0,216
    8000485a:	4501                	li	a0,0
    8000485c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000485e:	6398                	ld	a4,0(a5)
    80004860:	cb19                	beqz	a4,80004876 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004862:	2505                	addiw	a0,a0,1
    80004864:	07a1                	addi	a5,a5,8
    80004866:	fed51ce3          	bne	a0,a3,8000485e <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000486a:	557d                	li	a0,-1
}
    8000486c:	60e2                	ld	ra,24(sp)
    8000486e:	6442                	ld	s0,16(sp)
    80004870:	64a2                	ld	s1,8(sp)
    80004872:	6105                	addi	sp,sp,32
    80004874:	8082                	ret
      p->ofile[fd] = f;
    80004876:	01a50793          	addi	a5,a0,26
    8000487a:	078e                	slli	a5,a5,0x3
    8000487c:	963e                	add	a2,a2,a5
    8000487e:	e604                	sd	s1,8(a2)
      return fd;
    80004880:	b7f5                	j	8000486c <fdalloc+0x28>

0000000080004882 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004882:	715d                	addi	sp,sp,-80
    80004884:	e486                	sd	ra,72(sp)
    80004886:	e0a2                	sd	s0,64(sp)
    80004888:	fc26                	sd	s1,56(sp)
    8000488a:	f84a                	sd	s2,48(sp)
    8000488c:	f44e                	sd	s3,40(sp)
    8000488e:	f052                	sd	s4,32(sp)
    80004890:	ec56                	sd	s5,24(sp)
    80004892:	e85a                	sd	s6,16(sp)
    80004894:	0880                	addi	s0,sp,80
    80004896:	8b2e                	mv	s6,a1
    80004898:	89b2                	mv	s3,a2
    8000489a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000489c:	fb040593          	addi	a1,s0,-80
    800048a0:	878ff0ef          	jal	ra,80003918 <nameiparent>
    800048a4:	84aa                	mv	s1,a0
    800048a6:	10050b63          	beqz	a0,800049bc <create+0x13a>
    return 0;

  ilock(dp);
    800048aa:	9a3fe0ef          	jal	ra,8000324c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800048ae:	4601                	li	a2,0
    800048b0:	fb040593          	addi	a1,s0,-80
    800048b4:	8526                	mv	a0,s1
    800048b6:	de3fe0ef          	jal	ra,80003698 <dirlookup>
    800048ba:	8aaa                	mv	s5,a0
    800048bc:	c521                	beqz	a0,80004904 <create+0x82>
    iunlockput(dp);
    800048be:	8526                	mv	a0,s1
    800048c0:	b93fe0ef          	jal	ra,80003452 <iunlockput>
    ilock(ip);
    800048c4:	8556                	mv	a0,s5
    800048c6:	987fe0ef          	jal	ra,8000324c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800048ca:	000b059b          	sext.w	a1,s6
    800048ce:	4789                	li	a5,2
    800048d0:	02f59563          	bne	a1,a5,800048fa <create+0x78>
    800048d4:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffde15c>
    800048d8:	37f9                	addiw	a5,a5,-2
    800048da:	17c2                	slli	a5,a5,0x30
    800048dc:	93c1                	srli	a5,a5,0x30
    800048de:	4705                	li	a4,1
    800048e0:	00f76d63          	bltu	a4,a5,800048fa <create+0x78>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800048e4:	8556                	mv	a0,s5
    800048e6:	60a6                	ld	ra,72(sp)
    800048e8:	6406                	ld	s0,64(sp)
    800048ea:	74e2                	ld	s1,56(sp)
    800048ec:	7942                	ld	s2,48(sp)
    800048ee:	79a2                	ld	s3,40(sp)
    800048f0:	7a02                	ld	s4,32(sp)
    800048f2:	6ae2                	ld	s5,24(sp)
    800048f4:	6b42                	ld	s6,16(sp)
    800048f6:	6161                	addi	sp,sp,80
    800048f8:	8082                	ret
    iunlockput(ip);
    800048fa:	8556                	mv	a0,s5
    800048fc:	b57fe0ef          	jal	ra,80003452 <iunlockput>
    return 0;
    80004900:	4a81                	li	s5,0
    80004902:	b7cd                	j	800048e4 <create+0x62>
  if((ip = ialloc(dp->dev, type)) == 0){
    80004904:	85da                	mv	a1,s6
    80004906:	4088                	lw	a0,0(s1)
    80004908:	fdcfe0ef          	jal	ra,800030e4 <ialloc>
    8000490c:	8a2a                	mv	s4,a0
    8000490e:	cd1d                	beqz	a0,8000494c <create+0xca>
  ilock(ip);
    80004910:	93dfe0ef          	jal	ra,8000324c <ilock>
  ip->major = major;
    80004914:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004918:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000491c:	4905                	li	s2,1
    8000491e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004922:	8552                	mv	a0,s4
    80004924:	877fe0ef          	jal	ra,8000319a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004928:	000b059b          	sext.w	a1,s6
    8000492c:	03258563          	beq	a1,s2,80004956 <create+0xd4>
  if(dirlink(dp, name, ip->inum) < 0)
    80004930:	004a2603          	lw	a2,4(s4)
    80004934:	fb040593          	addi	a1,s0,-80
    80004938:	8526                	mv	a0,s1
    8000493a:	f2bfe0ef          	jal	ra,80003864 <dirlink>
    8000493e:	06054363          	bltz	a0,800049a4 <create+0x122>
  iunlockput(dp);
    80004942:	8526                	mv	a0,s1
    80004944:	b0ffe0ef          	jal	ra,80003452 <iunlockput>
  return ip;
    80004948:	8ad2                	mv	s5,s4
    8000494a:	bf69                	j	800048e4 <create+0x62>
    iunlockput(dp);
    8000494c:	8526                	mv	a0,s1
    8000494e:	b05fe0ef          	jal	ra,80003452 <iunlockput>
    return 0;
    80004952:	8ad2                	mv	s5,s4
    80004954:	bf41                	j	800048e4 <create+0x62>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004956:	004a2603          	lw	a2,4(s4)
    8000495a:	00003597          	auipc	a1,0x3
    8000495e:	ec658593          	addi	a1,a1,-314 # 80007820 <syscallnames+0x2a0>
    80004962:	8552                	mv	a0,s4
    80004964:	f01fe0ef          	jal	ra,80003864 <dirlink>
    80004968:	02054e63          	bltz	a0,800049a4 <create+0x122>
    8000496c:	40d0                	lw	a2,4(s1)
    8000496e:	00003597          	auipc	a1,0x3
    80004972:	eba58593          	addi	a1,a1,-326 # 80007828 <syscallnames+0x2a8>
    80004976:	8552                	mv	a0,s4
    80004978:	eedfe0ef          	jal	ra,80003864 <dirlink>
    8000497c:	02054463          	bltz	a0,800049a4 <create+0x122>
  if(dirlink(dp, name, ip->inum) < 0)
    80004980:	004a2603          	lw	a2,4(s4)
    80004984:	fb040593          	addi	a1,s0,-80
    80004988:	8526                	mv	a0,s1
    8000498a:	edbfe0ef          	jal	ra,80003864 <dirlink>
    8000498e:	00054b63          	bltz	a0,800049a4 <create+0x122>
    dp->nlink++;  // for ".."
    80004992:	04a4d783          	lhu	a5,74(s1)
    80004996:	2785                	addiw	a5,a5,1
    80004998:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000499c:	8526                	mv	a0,s1
    8000499e:	ffcfe0ef          	jal	ra,8000319a <iupdate>
    800049a2:	b745                	j	80004942 <create+0xc0>
  ip->nlink = 0;
    800049a4:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800049a8:	8552                	mv	a0,s4
    800049aa:	ff0fe0ef          	jal	ra,8000319a <iupdate>
  iunlockput(ip);
    800049ae:	8552                	mv	a0,s4
    800049b0:	aa3fe0ef          	jal	ra,80003452 <iunlockput>
  iunlockput(dp);
    800049b4:	8526                	mv	a0,s1
    800049b6:	a9dfe0ef          	jal	ra,80003452 <iunlockput>
  return 0;
    800049ba:	b72d                	j	800048e4 <create+0x62>
    return 0;
    800049bc:	8aaa                	mv	s5,a0
    800049be:	b71d                	j	800048e4 <create+0x62>

00000000800049c0 <sys_dup>:
{
    800049c0:	7179                	addi	sp,sp,-48
    800049c2:	f406                	sd	ra,40(sp)
    800049c4:	f022                	sd	s0,32(sp)
    800049c6:	ec26                	sd	s1,24(sp)
    800049c8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800049ca:	fd840613          	addi	a2,s0,-40
    800049ce:	4581                	li	a1,0
    800049d0:	4501                	li	a0,0
    800049d2:	e1bff0ef          	jal	ra,800047ec <argfd>
    return -1;
    800049d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800049d8:	00054f63          	bltz	a0,800049f6 <sys_dup+0x36>
  if((fd=fdalloc(f)) < 0)
    800049dc:	fd843503          	ld	a0,-40(s0)
    800049e0:	e65ff0ef          	jal	ra,80004844 <fdalloc>
    800049e4:	84aa                	mv	s1,a0
    return -1;
    800049e6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800049e8:	00054763          	bltz	a0,800049f6 <sys_dup+0x36>
  filedup(f);
    800049ec:	fd843503          	ld	a0,-40(s0)
    800049f0:	cc0ff0ef          	jal	ra,80003eb0 <filedup>
  return fd;
    800049f4:	87a6                	mv	a5,s1
}
    800049f6:	853e                	mv	a0,a5
    800049f8:	70a2                	ld	ra,40(sp)
    800049fa:	7402                	ld	s0,32(sp)
    800049fc:	64e2                	ld	s1,24(sp)
    800049fe:	6145                	addi	sp,sp,48
    80004a00:	8082                	ret

0000000080004a02 <sys_read>:
{
    80004a02:	7179                	addi	sp,sp,-48
    80004a04:	f406                	sd	ra,40(sp)
    80004a06:	f022                	sd	s0,32(sp)
    80004a08:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004a0a:	fd840593          	addi	a1,s0,-40
    80004a0e:	4505                	li	a0,1
    80004a10:	dcdfd0ef          	jal	ra,800027dc <argaddr>
  argint(2, &n);
    80004a14:	fe440593          	addi	a1,s0,-28
    80004a18:	4509                	li	a0,2
    80004a1a:	da7fd0ef          	jal	ra,800027c0 <argint>
  if(argfd(0, 0, &f) < 0)
    80004a1e:	fe840613          	addi	a2,s0,-24
    80004a22:	4581                	li	a1,0
    80004a24:	4501                	li	a0,0
    80004a26:	dc7ff0ef          	jal	ra,800047ec <argfd>
    80004a2a:	87aa                	mv	a5,a0
    return -1;
    80004a2c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004a2e:	0007ca63          	bltz	a5,80004a42 <sys_read+0x40>
  return fileread(f, p, n);
    80004a32:	fe442603          	lw	a2,-28(s0)
    80004a36:	fd843583          	ld	a1,-40(s0)
    80004a3a:	fe843503          	ld	a0,-24(s0)
    80004a3e:	dbeff0ef          	jal	ra,80003ffc <fileread>
}
    80004a42:	70a2                	ld	ra,40(sp)
    80004a44:	7402                	ld	s0,32(sp)
    80004a46:	6145                	addi	sp,sp,48
    80004a48:	8082                	ret

0000000080004a4a <sys_write>:
{
    80004a4a:	7179                	addi	sp,sp,-48
    80004a4c:	f406                	sd	ra,40(sp)
    80004a4e:	f022                	sd	s0,32(sp)
    80004a50:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004a52:	fd840593          	addi	a1,s0,-40
    80004a56:	4505                	li	a0,1
    80004a58:	d85fd0ef          	jal	ra,800027dc <argaddr>
  argint(2, &n);
    80004a5c:	fe440593          	addi	a1,s0,-28
    80004a60:	4509                	li	a0,2
    80004a62:	d5ffd0ef          	jal	ra,800027c0 <argint>
  if(argfd(0, 0, &f) < 0)
    80004a66:	fe840613          	addi	a2,s0,-24
    80004a6a:	4581                	li	a1,0
    80004a6c:	4501                	li	a0,0
    80004a6e:	d7fff0ef          	jal	ra,800047ec <argfd>
    80004a72:	87aa                	mv	a5,a0
    return -1;
    80004a74:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004a76:	0007ca63          	bltz	a5,80004a8a <sys_write+0x40>
  return filewrite(f, p, n);
    80004a7a:	fe442603          	lw	a2,-28(s0)
    80004a7e:	fd843583          	ld	a1,-40(s0)
    80004a82:	fe843503          	ld	a0,-24(s0)
    80004a86:	e24ff0ef          	jal	ra,800040aa <filewrite>
}
    80004a8a:	70a2                	ld	ra,40(sp)
    80004a8c:	7402                	ld	s0,32(sp)
    80004a8e:	6145                	addi	sp,sp,48
    80004a90:	8082                	ret

0000000080004a92 <sys_close>:
{
    80004a92:	1101                	addi	sp,sp,-32
    80004a94:	ec06                	sd	ra,24(sp)
    80004a96:	e822                	sd	s0,16(sp)
    80004a98:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004a9a:	fe040613          	addi	a2,s0,-32
    80004a9e:	fec40593          	addi	a1,s0,-20
    80004aa2:	4501                	li	a0,0
    80004aa4:	d49ff0ef          	jal	ra,800047ec <argfd>
    return -1;
    80004aa8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004aaa:	02054063          	bltz	a0,80004aca <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004aae:	e2dfc0ef          	jal	ra,800018da <myproc>
    80004ab2:	fec42783          	lw	a5,-20(s0)
    80004ab6:	07e9                	addi	a5,a5,26
    80004ab8:	078e                	slli	a5,a5,0x3
    80004aba:	97aa                	add	a5,a5,a0
    80004abc:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80004ac0:	fe043503          	ld	a0,-32(s0)
    80004ac4:	c32ff0ef          	jal	ra,80003ef6 <fileclose>
  return 0;
    80004ac8:	4781                	li	a5,0
}
    80004aca:	853e                	mv	a0,a5
    80004acc:	60e2                	ld	ra,24(sp)
    80004ace:	6442                	ld	s0,16(sp)
    80004ad0:	6105                	addi	sp,sp,32
    80004ad2:	8082                	ret

0000000080004ad4 <sys_fstat>:
{
    80004ad4:	1101                	addi	sp,sp,-32
    80004ad6:	ec06                	sd	ra,24(sp)
    80004ad8:	e822                	sd	s0,16(sp)
    80004ada:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80004adc:	fe040593          	addi	a1,s0,-32
    80004ae0:	4505                	li	a0,1
    80004ae2:	cfbfd0ef          	jal	ra,800027dc <argaddr>
  if(argfd(0, 0, &f) < 0)
    80004ae6:	fe840613          	addi	a2,s0,-24
    80004aea:	4581                	li	a1,0
    80004aec:	4501                	li	a0,0
    80004aee:	cffff0ef          	jal	ra,800047ec <argfd>
    80004af2:	87aa                	mv	a5,a0
    return -1;
    80004af4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004af6:	0007c863          	bltz	a5,80004b06 <sys_fstat+0x32>
  return filestat(f, st);
    80004afa:	fe043583          	ld	a1,-32(s0)
    80004afe:	fe843503          	ld	a0,-24(s0)
    80004b02:	c9cff0ef          	jal	ra,80003f9e <filestat>
}
    80004b06:	60e2                	ld	ra,24(sp)
    80004b08:	6442                	ld	s0,16(sp)
    80004b0a:	6105                	addi	sp,sp,32
    80004b0c:	8082                	ret

0000000080004b0e <sys_link>:
{
    80004b0e:	7169                	addi	sp,sp,-304
    80004b10:	f606                	sd	ra,296(sp)
    80004b12:	f222                	sd	s0,288(sp)
    80004b14:	ee26                	sd	s1,280(sp)
    80004b16:	ea4a                	sd	s2,272(sp)
    80004b18:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004b1a:	08000613          	li	a2,128
    80004b1e:	ed040593          	addi	a1,s0,-304
    80004b22:	4501                	li	a0,0
    80004b24:	cd5fd0ef          	jal	ra,800027f8 <argstr>
    return -1;
    80004b28:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004b2a:	0c054663          	bltz	a0,80004bf6 <sys_link+0xe8>
    80004b2e:	08000613          	li	a2,128
    80004b32:	f5040593          	addi	a1,s0,-176
    80004b36:	4505                	li	a0,1
    80004b38:	cc1fd0ef          	jal	ra,800027f8 <argstr>
    return -1;
    80004b3c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004b3e:	0a054c63          	bltz	a0,80004bf6 <sys_link+0xe8>
  begin_op();
    80004b42:	f99fe0ef          	jal	ra,80003ada <begin_op>
  if((ip = namei(old)) == 0){
    80004b46:	ed040513          	addi	a0,s0,-304
    80004b4a:	db5fe0ef          	jal	ra,800038fe <namei>
    80004b4e:	84aa                	mv	s1,a0
    80004b50:	c525                	beqz	a0,80004bb8 <sys_link+0xaa>
  ilock(ip);
    80004b52:	efafe0ef          	jal	ra,8000324c <ilock>
  if(ip->type == T_DIR){
    80004b56:	04449703          	lh	a4,68(s1)
    80004b5a:	4785                	li	a5,1
    80004b5c:	06f70263          	beq	a4,a5,80004bc0 <sys_link+0xb2>
  ip->nlink++;
    80004b60:	04a4d783          	lhu	a5,74(s1)
    80004b64:	2785                	addiw	a5,a5,1
    80004b66:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	e2efe0ef          	jal	ra,8000319a <iupdate>
  iunlock(ip);
    80004b70:	8526                	mv	a0,s1
    80004b72:	f84fe0ef          	jal	ra,800032f6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80004b76:	fd040593          	addi	a1,s0,-48
    80004b7a:	f5040513          	addi	a0,s0,-176
    80004b7e:	d9bfe0ef          	jal	ra,80003918 <nameiparent>
    80004b82:	892a                	mv	s2,a0
    80004b84:	c921                	beqz	a0,80004bd4 <sys_link+0xc6>
  ilock(dp);
    80004b86:	ec6fe0ef          	jal	ra,8000324c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80004b8a:	00092703          	lw	a4,0(s2)
    80004b8e:	409c                	lw	a5,0(s1)
    80004b90:	02f71f63          	bne	a4,a5,80004bce <sys_link+0xc0>
    80004b94:	40d0                	lw	a2,4(s1)
    80004b96:	fd040593          	addi	a1,s0,-48
    80004b9a:	854a                	mv	a0,s2
    80004b9c:	cc9fe0ef          	jal	ra,80003864 <dirlink>
    80004ba0:	02054763          	bltz	a0,80004bce <sys_link+0xc0>
  iunlockput(dp);
    80004ba4:	854a                	mv	a0,s2
    80004ba6:	8adfe0ef          	jal	ra,80003452 <iunlockput>
  iput(ip);
    80004baa:	8526                	mv	a0,s1
    80004bac:	81ffe0ef          	jal	ra,800033ca <iput>
  end_op();
    80004bb0:	f9bfe0ef          	jal	ra,80003b4a <end_op>
  return 0;
    80004bb4:	4781                	li	a5,0
    80004bb6:	a081                	j	80004bf6 <sys_link+0xe8>
    end_op();
    80004bb8:	f93fe0ef          	jal	ra,80003b4a <end_op>
    return -1;
    80004bbc:	57fd                	li	a5,-1
    80004bbe:	a825                	j	80004bf6 <sys_link+0xe8>
    iunlockput(ip);
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	891fe0ef          	jal	ra,80003452 <iunlockput>
    end_op();
    80004bc6:	f85fe0ef          	jal	ra,80003b4a <end_op>
    return -1;
    80004bca:	57fd                	li	a5,-1
    80004bcc:	a02d                	j	80004bf6 <sys_link+0xe8>
    iunlockput(dp);
    80004bce:	854a                	mv	a0,s2
    80004bd0:	883fe0ef          	jal	ra,80003452 <iunlockput>
  ilock(ip);
    80004bd4:	8526                	mv	a0,s1
    80004bd6:	e76fe0ef          	jal	ra,8000324c <ilock>
  ip->nlink--;
    80004bda:	04a4d783          	lhu	a5,74(s1)
    80004bde:	37fd                	addiw	a5,a5,-1
    80004be0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004be4:	8526                	mv	a0,s1
    80004be6:	db4fe0ef          	jal	ra,8000319a <iupdate>
  iunlockput(ip);
    80004bea:	8526                	mv	a0,s1
    80004bec:	867fe0ef          	jal	ra,80003452 <iunlockput>
  end_op();
    80004bf0:	f5bfe0ef          	jal	ra,80003b4a <end_op>
  return -1;
    80004bf4:	57fd                	li	a5,-1
}
    80004bf6:	853e                	mv	a0,a5
    80004bf8:	70b2                	ld	ra,296(sp)
    80004bfa:	7412                	ld	s0,288(sp)
    80004bfc:	64f2                	ld	s1,280(sp)
    80004bfe:	6952                	ld	s2,272(sp)
    80004c00:	6155                	addi	sp,sp,304
    80004c02:	8082                	ret

0000000080004c04 <sys_unlink>:
{
    80004c04:	7151                	addi	sp,sp,-240
    80004c06:	f586                	sd	ra,232(sp)
    80004c08:	f1a2                	sd	s0,224(sp)
    80004c0a:	eda6                	sd	s1,216(sp)
    80004c0c:	e9ca                	sd	s2,208(sp)
    80004c0e:	e5ce                	sd	s3,200(sp)
    80004c10:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80004c12:	08000613          	li	a2,128
    80004c16:	f3040593          	addi	a1,s0,-208
    80004c1a:	4501                	li	a0,0
    80004c1c:	bddfd0ef          	jal	ra,800027f8 <argstr>
    80004c20:	12054b63          	bltz	a0,80004d56 <sys_unlink+0x152>
  begin_op();
    80004c24:	eb7fe0ef          	jal	ra,80003ada <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80004c28:	fb040593          	addi	a1,s0,-80
    80004c2c:	f3040513          	addi	a0,s0,-208
    80004c30:	ce9fe0ef          	jal	ra,80003918 <nameiparent>
    80004c34:	84aa                	mv	s1,a0
    80004c36:	c54d                	beqz	a0,80004ce0 <sys_unlink+0xdc>
  ilock(dp);
    80004c38:	e14fe0ef          	jal	ra,8000324c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004c3c:	00003597          	auipc	a1,0x3
    80004c40:	be458593          	addi	a1,a1,-1052 # 80007820 <syscallnames+0x2a0>
    80004c44:	fb040513          	addi	a0,s0,-80
    80004c48:	a3bfe0ef          	jal	ra,80003682 <namecmp>
    80004c4c:	10050a63          	beqz	a0,80004d60 <sys_unlink+0x15c>
    80004c50:	00003597          	auipc	a1,0x3
    80004c54:	bd858593          	addi	a1,a1,-1064 # 80007828 <syscallnames+0x2a8>
    80004c58:	fb040513          	addi	a0,s0,-80
    80004c5c:	a27fe0ef          	jal	ra,80003682 <namecmp>
    80004c60:	10050063          	beqz	a0,80004d60 <sys_unlink+0x15c>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80004c64:	f2c40613          	addi	a2,s0,-212
    80004c68:	fb040593          	addi	a1,s0,-80
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	a2bfe0ef          	jal	ra,80003698 <dirlookup>
    80004c72:	892a                	mv	s2,a0
    80004c74:	0e050663          	beqz	a0,80004d60 <sys_unlink+0x15c>
  ilock(ip);
    80004c78:	dd4fe0ef          	jal	ra,8000324c <ilock>
  if(ip->nlink < 1)
    80004c7c:	04a91783          	lh	a5,74(s2)
    80004c80:	06f05463          	blez	a5,80004ce8 <sys_unlink+0xe4>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004c84:	04491703          	lh	a4,68(s2)
    80004c88:	4785                	li	a5,1
    80004c8a:	06f70563          	beq	a4,a5,80004cf4 <sys_unlink+0xf0>
  memset(&de, 0, sizeof(de));
    80004c8e:	4641                	li	a2,16
    80004c90:	4581                	li	a1,0
    80004c92:	fc040513          	addi	a0,s0,-64
    80004c96:	880fc0ef          	jal	ra,80000d16 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004c9a:	4741                	li	a4,16
    80004c9c:	f2c42683          	lw	a3,-212(s0)
    80004ca0:	fc040613          	addi	a2,s0,-64
    80004ca4:	4581                	li	a1,0
    80004ca6:	8526                	mv	a0,s1
    80004ca8:	8d9fe0ef          	jal	ra,80003580 <writei>
    80004cac:	47c1                	li	a5,16
    80004cae:	08f51563          	bne	a0,a5,80004d38 <sys_unlink+0x134>
  if(ip->type == T_DIR){
    80004cb2:	04491703          	lh	a4,68(s2)
    80004cb6:	4785                	li	a5,1
    80004cb8:	08f70663          	beq	a4,a5,80004d44 <sys_unlink+0x140>
  iunlockput(dp);
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	f94fe0ef          	jal	ra,80003452 <iunlockput>
  ip->nlink--;
    80004cc2:	04a95783          	lhu	a5,74(s2)
    80004cc6:	37fd                	addiw	a5,a5,-1
    80004cc8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004ccc:	854a                	mv	a0,s2
    80004cce:	cccfe0ef          	jal	ra,8000319a <iupdate>
  iunlockput(ip);
    80004cd2:	854a                	mv	a0,s2
    80004cd4:	f7efe0ef          	jal	ra,80003452 <iunlockput>
  end_op();
    80004cd8:	e73fe0ef          	jal	ra,80003b4a <end_op>
  return 0;
    80004cdc:	4501                	li	a0,0
    80004cde:	a079                	j	80004d6c <sys_unlink+0x168>
    end_op();
    80004ce0:	e6bfe0ef          	jal	ra,80003b4a <end_op>
    return -1;
    80004ce4:	557d                	li	a0,-1
    80004ce6:	a059                	j	80004d6c <sys_unlink+0x168>
    panic("unlink: nlink < 1");
    80004ce8:	00003517          	auipc	a0,0x3
    80004cec:	b4850513          	addi	a0,a0,-1208 # 80007830 <syscallnames+0x2b0>
    80004cf0:	aedfb0ef          	jal	ra,800007dc <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004cf4:	04c92703          	lw	a4,76(s2)
    80004cf8:	02000793          	li	a5,32
    80004cfc:	f8e7f9e3          	bgeu	a5,a4,80004c8e <sys_unlink+0x8a>
    80004d00:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004d04:	4741                	li	a4,16
    80004d06:	86ce                	mv	a3,s3
    80004d08:	f1840613          	addi	a2,s0,-232
    80004d0c:	4581                	li	a1,0
    80004d0e:	854a                	mv	a0,s2
    80004d10:	f8cfe0ef          	jal	ra,8000349c <readi>
    80004d14:	47c1                	li	a5,16
    80004d16:	00f51b63          	bne	a0,a5,80004d2c <sys_unlink+0x128>
    if(de.inum != 0)
    80004d1a:	f1845783          	lhu	a5,-232(s0)
    80004d1e:	ef95                	bnez	a5,80004d5a <sys_unlink+0x156>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004d20:	29c1                	addiw	s3,s3,16
    80004d22:	04c92783          	lw	a5,76(s2)
    80004d26:	fcf9efe3          	bltu	s3,a5,80004d04 <sys_unlink+0x100>
    80004d2a:	b795                	j	80004c8e <sys_unlink+0x8a>
      panic("isdirempty: readi");
    80004d2c:	00003517          	auipc	a0,0x3
    80004d30:	b1c50513          	addi	a0,a0,-1252 # 80007848 <syscallnames+0x2c8>
    80004d34:	aa9fb0ef          	jal	ra,800007dc <panic>
    panic("unlink: writei");
    80004d38:	00003517          	auipc	a0,0x3
    80004d3c:	b2850513          	addi	a0,a0,-1240 # 80007860 <syscallnames+0x2e0>
    80004d40:	a9dfb0ef          	jal	ra,800007dc <panic>
    dp->nlink--;
    80004d44:	04a4d783          	lhu	a5,74(s1)
    80004d48:	37fd                	addiw	a5,a5,-1
    80004d4a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004d4e:	8526                	mv	a0,s1
    80004d50:	c4afe0ef          	jal	ra,8000319a <iupdate>
    80004d54:	b7a5                	j	80004cbc <sys_unlink+0xb8>
    return -1;
    80004d56:	557d                	li	a0,-1
    80004d58:	a811                	j	80004d6c <sys_unlink+0x168>
    iunlockput(ip);
    80004d5a:	854a                	mv	a0,s2
    80004d5c:	ef6fe0ef          	jal	ra,80003452 <iunlockput>
  iunlockput(dp);
    80004d60:	8526                	mv	a0,s1
    80004d62:	ef0fe0ef          	jal	ra,80003452 <iunlockput>
  end_op();
    80004d66:	de5fe0ef          	jal	ra,80003b4a <end_op>
  return -1;
    80004d6a:	557d                	li	a0,-1
}
    80004d6c:	70ae                	ld	ra,232(sp)
    80004d6e:	740e                	ld	s0,224(sp)
    80004d70:	64ee                	ld	s1,216(sp)
    80004d72:	694e                	ld	s2,208(sp)
    80004d74:	69ae                	ld	s3,200(sp)
    80004d76:	616d                	addi	sp,sp,240
    80004d78:	8082                	ret

0000000080004d7a <sys_open>:

uint64
sys_open(void)
{
    80004d7a:	7131                	addi	sp,sp,-192
    80004d7c:	fd06                	sd	ra,184(sp)
    80004d7e:	f922                	sd	s0,176(sp)
    80004d80:	f526                	sd	s1,168(sp)
    80004d82:	f14a                	sd	s2,160(sp)
    80004d84:	ed4e                	sd	s3,152(sp)
    80004d86:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80004d88:	f4c40593          	addi	a1,s0,-180
    80004d8c:	4505                	li	a0,1
    80004d8e:	a33fd0ef          	jal	ra,800027c0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004d92:	08000613          	li	a2,128
    80004d96:	f5040593          	addi	a1,s0,-176
    80004d9a:	4501                	li	a0,0
    80004d9c:	a5dfd0ef          	jal	ra,800027f8 <argstr>
    80004da0:	87aa                	mv	a5,a0
    return -1;
    80004da2:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004da4:	0807cd63          	bltz	a5,80004e3e <sys_open+0xc4>

  begin_op();
    80004da8:	d33fe0ef          	jal	ra,80003ada <begin_op>

  if(omode & O_CREATE){
    80004dac:	f4c42783          	lw	a5,-180(s0)
    80004db0:	2007f793          	andi	a5,a5,512
    80004db4:	c3c5                	beqz	a5,80004e54 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    80004db6:	4681                	li	a3,0
    80004db8:	4601                	li	a2,0
    80004dba:	4589                	li	a1,2
    80004dbc:	f5040513          	addi	a0,s0,-176
    80004dc0:	ac3ff0ef          	jal	ra,80004882 <create>
    80004dc4:	84aa                	mv	s1,a0
    if(ip == 0){
    80004dc6:	c159                	beqz	a0,80004e4c <sys_open+0xd2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80004dc8:	04449703          	lh	a4,68(s1)
    80004dcc:	478d                	li	a5,3
    80004dce:	00f71763          	bne	a4,a5,80004ddc <sys_open+0x62>
    80004dd2:	0464d703          	lhu	a4,70(s1)
    80004dd6:	47a5                	li	a5,9
    80004dd8:	0ae7e963          	bltu	a5,a4,80004e8a <sys_open+0x110>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80004ddc:	876ff0ef          	jal	ra,80003e52 <filealloc>
    80004de0:	89aa                	mv	s3,a0
    80004de2:	0c050963          	beqz	a0,80004eb4 <sys_open+0x13a>
    80004de6:	a5fff0ef          	jal	ra,80004844 <fdalloc>
    80004dea:	892a                	mv	s2,a0
    80004dec:	0c054163          	bltz	a0,80004eae <sys_open+0x134>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80004df0:	04449703          	lh	a4,68(s1)
    80004df4:	478d                	li	a5,3
    80004df6:	0af70163          	beq	a4,a5,80004e98 <sys_open+0x11e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80004dfa:	4789                	li	a5,2
    80004dfc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80004e00:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80004e04:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80004e08:	f4c42783          	lw	a5,-180(s0)
    80004e0c:	0017c713          	xori	a4,a5,1
    80004e10:	8b05                	andi	a4,a4,1
    80004e12:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80004e16:	0037f713          	andi	a4,a5,3
    80004e1a:	00e03733          	snez	a4,a4
    80004e1e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80004e22:	4007f793          	andi	a5,a5,1024
    80004e26:	c791                	beqz	a5,80004e32 <sys_open+0xb8>
    80004e28:	04449703          	lh	a4,68(s1)
    80004e2c:	4789                	li	a5,2
    80004e2e:	06f70c63          	beq	a4,a5,80004ea6 <sys_open+0x12c>
    itrunc(ip);
  }

  iunlock(ip);
    80004e32:	8526                	mv	a0,s1
    80004e34:	cc2fe0ef          	jal	ra,800032f6 <iunlock>
  end_op();
    80004e38:	d13fe0ef          	jal	ra,80003b4a <end_op>

  return fd;
    80004e3c:	854a                	mv	a0,s2
}
    80004e3e:	70ea                	ld	ra,184(sp)
    80004e40:	744a                	ld	s0,176(sp)
    80004e42:	74aa                	ld	s1,168(sp)
    80004e44:	790a                	ld	s2,160(sp)
    80004e46:	69ea                	ld	s3,152(sp)
    80004e48:	6129                	addi	sp,sp,192
    80004e4a:	8082                	ret
      end_op();
    80004e4c:	cfffe0ef          	jal	ra,80003b4a <end_op>
      return -1;
    80004e50:	557d                	li	a0,-1
    80004e52:	b7f5                	j	80004e3e <sys_open+0xc4>
    if((ip = namei(path)) == 0){
    80004e54:	f5040513          	addi	a0,s0,-176
    80004e58:	aa7fe0ef          	jal	ra,800038fe <namei>
    80004e5c:	84aa                	mv	s1,a0
    80004e5e:	c115                	beqz	a0,80004e82 <sys_open+0x108>
    ilock(ip);
    80004e60:	becfe0ef          	jal	ra,8000324c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80004e64:	04449703          	lh	a4,68(s1)
    80004e68:	4785                	li	a5,1
    80004e6a:	f4f71fe3          	bne	a4,a5,80004dc8 <sys_open+0x4e>
    80004e6e:	f4c42783          	lw	a5,-180(s0)
    80004e72:	d7ad                	beqz	a5,80004ddc <sys_open+0x62>
      iunlockput(ip);
    80004e74:	8526                	mv	a0,s1
    80004e76:	ddcfe0ef          	jal	ra,80003452 <iunlockput>
      end_op();
    80004e7a:	cd1fe0ef          	jal	ra,80003b4a <end_op>
      return -1;
    80004e7e:	557d                	li	a0,-1
    80004e80:	bf7d                	j	80004e3e <sys_open+0xc4>
      end_op();
    80004e82:	cc9fe0ef          	jal	ra,80003b4a <end_op>
      return -1;
    80004e86:	557d                	li	a0,-1
    80004e88:	bf5d                	j	80004e3e <sys_open+0xc4>
    iunlockput(ip);
    80004e8a:	8526                	mv	a0,s1
    80004e8c:	dc6fe0ef          	jal	ra,80003452 <iunlockput>
    end_op();
    80004e90:	cbbfe0ef          	jal	ra,80003b4a <end_op>
    return -1;
    80004e94:	557d                	li	a0,-1
    80004e96:	b765                	j	80004e3e <sys_open+0xc4>
    f->type = FD_DEVICE;
    80004e98:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80004e9c:	04649783          	lh	a5,70(s1)
    80004ea0:	02f99223          	sh	a5,36(s3)
    80004ea4:	b785                	j	80004e04 <sys_open+0x8a>
    itrunc(ip);
    80004ea6:	8526                	mv	a0,s1
    80004ea8:	c8efe0ef          	jal	ra,80003336 <itrunc>
    80004eac:	b759                	j	80004e32 <sys_open+0xb8>
      fileclose(f);
    80004eae:	854e                	mv	a0,s3
    80004eb0:	846ff0ef          	jal	ra,80003ef6 <fileclose>
    iunlockput(ip);
    80004eb4:	8526                	mv	a0,s1
    80004eb6:	d9cfe0ef          	jal	ra,80003452 <iunlockput>
    end_op();
    80004eba:	c91fe0ef          	jal	ra,80003b4a <end_op>
    return -1;
    80004ebe:	557d                	li	a0,-1
    80004ec0:	bfbd                	j	80004e3e <sys_open+0xc4>

0000000080004ec2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80004ec2:	7175                	addi	sp,sp,-144
    80004ec4:	e506                	sd	ra,136(sp)
    80004ec6:	e122                	sd	s0,128(sp)
    80004ec8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80004eca:	c11fe0ef          	jal	ra,80003ada <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80004ece:	08000613          	li	a2,128
    80004ed2:	f7040593          	addi	a1,s0,-144
    80004ed6:	4501                	li	a0,0
    80004ed8:	921fd0ef          	jal	ra,800027f8 <argstr>
    80004edc:	02054363          	bltz	a0,80004f02 <sys_mkdir+0x40>
    80004ee0:	4681                	li	a3,0
    80004ee2:	4601                	li	a2,0
    80004ee4:	4585                	li	a1,1
    80004ee6:	f7040513          	addi	a0,s0,-144
    80004eea:	999ff0ef          	jal	ra,80004882 <create>
    80004eee:	c911                	beqz	a0,80004f02 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80004ef0:	d62fe0ef          	jal	ra,80003452 <iunlockput>
  end_op();
    80004ef4:	c57fe0ef          	jal	ra,80003b4a <end_op>
  return 0;
    80004ef8:	4501                	li	a0,0
}
    80004efa:	60aa                	ld	ra,136(sp)
    80004efc:	640a                	ld	s0,128(sp)
    80004efe:	6149                	addi	sp,sp,144
    80004f00:	8082                	ret
    end_op();
    80004f02:	c49fe0ef          	jal	ra,80003b4a <end_op>
    return -1;
    80004f06:	557d                	li	a0,-1
    80004f08:	bfcd                	j	80004efa <sys_mkdir+0x38>

0000000080004f0a <sys_mknod>:

uint64
sys_mknod(void)
{
    80004f0a:	7135                	addi	sp,sp,-160
    80004f0c:	ed06                	sd	ra,152(sp)
    80004f0e:	e922                	sd	s0,144(sp)
    80004f10:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80004f12:	bc9fe0ef          	jal	ra,80003ada <begin_op>
  argint(1, &major);
    80004f16:	f6c40593          	addi	a1,s0,-148
    80004f1a:	4505                	li	a0,1
    80004f1c:	8a5fd0ef          	jal	ra,800027c0 <argint>
  argint(2, &minor);
    80004f20:	f6840593          	addi	a1,s0,-152
    80004f24:	4509                	li	a0,2
    80004f26:	89bfd0ef          	jal	ra,800027c0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80004f2a:	08000613          	li	a2,128
    80004f2e:	f7040593          	addi	a1,s0,-144
    80004f32:	4501                	li	a0,0
    80004f34:	8c5fd0ef          	jal	ra,800027f8 <argstr>
    80004f38:	02054563          	bltz	a0,80004f62 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80004f3c:	f6841683          	lh	a3,-152(s0)
    80004f40:	f6c41603          	lh	a2,-148(s0)
    80004f44:	458d                	li	a1,3
    80004f46:	f7040513          	addi	a0,s0,-144
    80004f4a:	939ff0ef          	jal	ra,80004882 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80004f4e:	c911                	beqz	a0,80004f62 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80004f50:	d02fe0ef          	jal	ra,80003452 <iunlockput>
  end_op();
    80004f54:	bf7fe0ef          	jal	ra,80003b4a <end_op>
  return 0;
    80004f58:	4501                	li	a0,0
}
    80004f5a:	60ea                	ld	ra,152(sp)
    80004f5c:	644a                	ld	s0,144(sp)
    80004f5e:	610d                	addi	sp,sp,160
    80004f60:	8082                	ret
    end_op();
    80004f62:	be9fe0ef          	jal	ra,80003b4a <end_op>
    return -1;
    80004f66:	557d                	li	a0,-1
    80004f68:	bfcd                	j	80004f5a <sys_mknod+0x50>

0000000080004f6a <sys_chdir>:

uint64
sys_chdir(void)
{
    80004f6a:	7135                	addi	sp,sp,-160
    80004f6c:	ed06                	sd	ra,152(sp)
    80004f6e:	e922                	sd	s0,144(sp)
    80004f70:	e526                	sd	s1,136(sp)
    80004f72:	e14a                	sd	s2,128(sp)
    80004f74:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80004f76:	965fc0ef          	jal	ra,800018da <myproc>
    80004f7a:	892a                	mv	s2,a0
  
  begin_op();
    80004f7c:	b5ffe0ef          	jal	ra,80003ada <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80004f80:	08000613          	li	a2,128
    80004f84:	f6040593          	addi	a1,s0,-160
    80004f88:	4501                	li	a0,0
    80004f8a:	86ffd0ef          	jal	ra,800027f8 <argstr>
    80004f8e:	04054163          	bltz	a0,80004fd0 <sys_chdir+0x66>
    80004f92:	f6040513          	addi	a0,s0,-160
    80004f96:	969fe0ef          	jal	ra,800038fe <namei>
    80004f9a:	84aa                	mv	s1,a0
    80004f9c:	c915                	beqz	a0,80004fd0 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    80004f9e:	aaefe0ef          	jal	ra,8000324c <ilock>
  if(ip->type != T_DIR){
    80004fa2:	04449703          	lh	a4,68(s1)
    80004fa6:	4785                	li	a5,1
    80004fa8:	02f71863          	bne	a4,a5,80004fd8 <sys_chdir+0x6e>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80004fac:	8526                	mv	a0,s1
    80004fae:	b48fe0ef          	jal	ra,800032f6 <iunlock>
  iput(p->cwd);
    80004fb2:	15893503          	ld	a0,344(s2)
    80004fb6:	c14fe0ef          	jal	ra,800033ca <iput>
  end_op();
    80004fba:	b91fe0ef          	jal	ra,80003b4a <end_op>
  p->cwd = ip;
    80004fbe:	14993c23          	sd	s1,344(s2)
  return 0;
    80004fc2:	4501                	li	a0,0
}
    80004fc4:	60ea                	ld	ra,152(sp)
    80004fc6:	644a                	ld	s0,144(sp)
    80004fc8:	64aa                	ld	s1,136(sp)
    80004fca:	690a                	ld	s2,128(sp)
    80004fcc:	610d                	addi	sp,sp,160
    80004fce:	8082                	ret
    end_op();
    80004fd0:	b7bfe0ef          	jal	ra,80003b4a <end_op>
    return -1;
    80004fd4:	557d                	li	a0,-1
    80004fd6:	b7fd                	j	80004fc4 <sys_chdir+0x5a>
    iunlockput(ip);
    80004fd8:	8526                	mv	a0,s1
    80004fda:	c78fe0ef          	jal	ra,80003452 <iunlockput>
    end_op();
    80004fde:	b6dfe0ef          	jal	ra,80003b4a <end_op>
    return -1;
    80004fe2:	557d                	li	a0,-1
    80004fe4:	b7c5                	j	80004fc4 <sys_chdir+0x5a>

0000000080004fe6 <sys_exec>:

uint64
sys_exec(void)
{
    80004fe6:	7145                	addi	sp,sp,-464
    80004fe8:	e786                	sd	ra,456(sp)
    80004fea:	e3a2                	sd	s0,448(sp)
    80004fec:	ff26                	sd	s1,440(sp)
    80004fee:	fb4a                	sd	s2,432(sp)
    80004ff0:	f74e                	sd	s3,424(sp)
    80004ff2:	f352                	sd	s4,416(sp)
    80004ff4:	ef56                	sd	s5,408(sp)
    80004ff6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80004ff8:	e3840593          	addi	a1,s0,-456
    80004ffc:	4505                	li	a0,1
    80004ffe:	fdefd0ef          	jal	ra,800027dc <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005002:	08000613          	li	a2,128
    80005006:	f4040593          	addi	a1,s0,-192
    8000500a:	4501                	li	a0,0
    8000500c:	fecfd0ef          	jal	ra,800027f8 <argstr>
    80005010:	87aa                	mv	a5,a0
    return -1;
    80005012:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005014:	0a07c463          	bltz	a5,800050bc <sys_exec+0xd6>
  }
  memset(argv, 0, sizeof(argv));
    80005018:	10000613          	li	a2,256
    8000501c:	4581                	li	a1,0
    8000501e:	e4040513          	addi	a0,s0,-448
    80005022:	cf5fb0ef          	jal	ra,80000d16 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005026:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000502a:	89a6                	mv	s3,s1
    8000502c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000502e:	02000a13          	li	s4,32
    80005032:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005036:	00391793          	slli	a5,s2,0x3
    8000503a:	e3040593          	addi	a1,s0,-464
    8000503e:	e3843503          	ld	a0,-456(s0)
    80005042:	953e                	add	a0,a0,a5
    80005044:	ef2fd0ef          	jal	ra,80002736 <fetchaddr>
    80005048:	02054663          	bltz	a0,80005074 <sys_exec+0x8e>
      goto bad;
    }
    if(uarg == 0){
    8000504c:	e3043783          	ld	a5,-464(s0)
    80005050:	cf8d                	beqz	a5,8000508a <sys_exec+0xa4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005052:	b21fb0ef          	jal	ra,80000b72 <kalloc>
    80005056:	85aa                	mv	a1,a0
    80005058:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000505c:	cd01                	beqz	a0,80005074 <sys_exec+0x8e>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000505e:	6605                	lui	a2,0x1
    80005060:	e3043503          	ld	a0,-464(s0)
    80005064:	f1cfd0ef          	jal	ra,80002780 <fetchstr>
    80005068:	00054663          	bltz	a0,80005074 <sys_exec+0x8e>
    if(i >= NELEM(argv)){
    8000506c:	0905                	addi	s2,s2,1
    8000506e:	09a1                	addi	s3,s3,8
    80005070:	fd4911e3          	bne	s2,s4,80005032 <sys_exec+0x4c>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005074:	10048913          	addi	s2,s1,256
    80005078:	6088                	ld	a0,0(s1)
    8000507a:	c121                	beqz	a0,800050ba <sys_exec+0xd4>
    kfree(argv[i]);
    8000507c:	a17fb0ef          	jal	ra,80000a92 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005080:	04a1                	addi	s1,s1,8
    80005082:	ff249be3          	bne	s1,s2,80005078 <sys_exec+0x92>
  return -1;
    80005086:	557d                	li	a0,-1
    80005088:	a815                	j	800050bc <sys_exec+0xd6>
      argv[i] = 0;
    8000508a:	0a8e                	slli	s5,s5,0x3
    8000508c:	fc040793          	addi	a5,s0,-64
    80005090:	9abe                	add	s5,s5,a5
    80005092:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005096:	e4040593          	addi	a1,s0,-448
    8000509a:	f4040513          	addi	a0,s0,-192
    8000509e:	bfaff0ef          	jal	ra,80004498 <exec>
    800050a2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800050a4:	10048993          	addi	s3,s1,256
    800050a8:	6088                	ld	a0,0(s1)
    800050aa:	c511                	beqz	a0,800050b6 <sys_exec+0xd0>
    kfree(argv[i]);
    800050ac:	9e7fb0ef          	jal	ra,80000a92 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800050b0:	04a1                	addi	s1,s1,8
    800050b2:	ff349be3          	bne	s1,s3,800050a8 <sys_exec+0xc2>
  return ret;
    800050b6:	854a                	mv	a0,s2
    800050b8:	a011                	j	800050bc <sys_exec+0xd6>
  return -1;
    800050ba:	557d                	li	a0,-1
}
    800050bc:	60be                	ld	ra,456(sp)
    800050be:	641e                	ld	s0,448(sp)
    800050c0:	74fa                	ld	s1,440(sp)
    800050c2:	795a                	ld	s2,432(sp)
    800050c4:	79ba                	ld	s3,424(sp)
    800050c6:	7a1a                	ld	s4,416(sp)
    800050c8:	6afa                	ld	s5,408(sp)
    800050ca:	6179                	addi	sp,sp,464
    800050cc:	8082                	ret

00000000800050ce <sys_pipe>:

uint64
sys_pipe(void)
{
    800050ce:	7139                	addi	sp,sp,-64
    800050d0:	fc06                	sd	ra,56(sp)
    800050d2:	f822                	sd	s0,48(sp)
    800050d4:	f426                	sd	s1,40(sp)
    800050d6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800050d8:	803fc0ef          	jal	ra,800018da <myproc>
    800050dc:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800050de:	fd840593          	addi	a1,s0,-40
    800050e2:	4501                	li	a0,0
    800050e4:	ef8fd0ef          	jal	ra,800027dc <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800050e8:	fc840593          	addi	a1,s0,-56
    800050ec:	fd040513          	addi	a0,s0,-48
    800050f0:	8d2ff0ef          	jal	ra,800041c2 <pipealloc>
    return -1;
    800050f4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800050f6:	0a054463          	bltz	a0,8000519e <sys_pipe+0xd0>
  fd0 = -1;
    800050fa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800050fe:	fd043503          	ld	a0,-48(s0)
    80005102:	f42ff0ef          	jal	ra,80004844 <fdalloc>
    80005106:	fca42223          	sw	a0,-60(s0)
    8000510a:	08054163          	bltz	a0,8000518c <sys_pipe+0xbe>
    8000510e:	fc843503          	ld	a0,-56(s0)
    80005112:	f32ff0ef          	jal	ra,80004844 <fdalloc>
    80005116:	fca42023          	sw	a0,-64(s0)
    8000511a:	06054063          	bltz	a0,8000517a <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000511e:	4691                	li	a3,4
    80005120:	fc440613          	addi	a2,s0,-60
    80005124:	fd843583          	ld	a1,-40(s0)
    80005128:	6ca8                	ld	a0,88(s1)
    8000512a:	cfefc0ef          	jal	ra,80001628 <copyout>
    8000512e:	00054e63          	bltz	a0,8000514a <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005132:	4691                	li	a3,4
    80005134:	fc040613          	addi	a2,s0,-64
    80005138:	fd843583          	ld	a1,-40(s0)
    8000513c:	0591                	addi	a1,a1,4
    8000513e:	6ca8                	ld	a0,88(s1)
    80005140:	ce8fc0ef          	jal	ra,80001628 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005144:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005146:	04055c63          	bgez	a0,8000519e <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    8000514a:	fc442783          	lw	a5,-60(s0)
    8000514e:	07e9                	addi	a5,a5,26
    80005150:	078e                	slli	a5,a5,0x3
    80005152:	97a6                	add	a5,a5,s1
    80005154:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005158:	fc042503          	lw	a0,-64(s0)
    8000515c:	0569                	addi	a0,a0,26
    8000515e:	050e                	slli	a0,a0,0x3
    80005160:	94aa                	add	s1,s1,a0
    80005162:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80005166:	fd043503          	ld	a0,-48(s0)
    8000516a:	d8dfe0ef          	jal	ra,80003ef6 <fileclose>
    fileclose(wf);
    8000516e:	fc843503          	ld	a0,-56(s0)
    80005172:	d85fe0ef          	jal	ra,80003ef6 <fileclose>
    return -1;
    80005176:	57fd                	li	a5,-1
    80005178:	a01d                	j	8000519e <sys_pipe+0xd0>
    if(fd0 >= 0)
    8000517a:	fc442783          	lw	a5,-60(s0)
    8000517e:	0007c763          	bltz	a5,8000518c <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    80005182:	07e9                	addi	a5,a5,26
    80005184:	078e                	slli	a5,a5,0x3
    80005186:	94be                	add	s1,s1,a5
    80005188:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    8000518c:	fd043503          	ld	a0,-48(s0)
    80005190:	d67fe0ef          	jal	ra,80003ef6 <fileclose>
    fileclose(wf);
    80005194:	fc843503          	ld	a0,-56(s0)
    80005198:	d5ffe0ef          	jal	ra,80003ef6 <fileclose>
    return -1;
    8000519c:	57fd                	li	a5,-1
}
    8000519e:	853e                	mv	a0,a5
    800051a0:	70e2                	ld	ra,56(sp)
    800051a2:	7442                	ld	s0,48(sp)
    800051a4:	74a2                	ld	s1,40(sp)
    800051a6:	6121                	addi	sp,sp,64
    800051a8:	8082                	ret
    800051aa:	0000                	unimp
    800051ac:	0000                	unimp
	...

00000000800051b0 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    800051b0:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    800051b2:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    800051b4:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    800051b6:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    800051b8:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    800051ba:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    800051bc:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    800051be:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800051c0:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800051c2:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800051c4:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800051c6:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800051c8:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800051ca:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800051cc:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    800051ce:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800051d0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800051d2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800051d4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800051d6:	c70fd0ef          	jal	ra,80002646 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800051da:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800051dc:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800051de:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800051e0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800051e2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800051e4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800051e6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800051e8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800051ea:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800051ec:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800051ee:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800051f0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800051f2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800051f4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800051f6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800051f8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800051fa:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800051fc:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800051fe:	10200073          	sret
	...

000000008000520e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000520e:	1141                	addi	sp,sp,-16
    80005210:	e422                	sd	s0,8(sp)
    80005212:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005214:	0c0007b7          	lui	a5,0xc000
    80005218:	4705                	li	a4,1
    8000521a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000521c:	c3d8                	sw	a4,4(a5)
}
    8000521e:	6422                	ld	s0,8(sp)
    80005220:	0141                	addi	sp,sp,16
    80005222:	8082                	ret

0000000080005224 <plicinithart>:

void
plicinithart(void)
{
    80005224:	1141                	addi	sp,sp,-16
    80005226:	e406                	sd	ra,8(sp)
    80005228:	e022                	sd	s0,0(sp)
    8000522a:	0800                	addi	s0,sp,16
  int hart = cpuid();
    8000522c:	e82fc0ef          	jal	ra,800018ae <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005230:	0085171b          	slliw	a4,a0,0x8
    80005234:	0c0027b7          	lui	a5,0xc002
    80005238:	97ba                	add	a5,a5,a4
    8000523a:	40200713          	li	a4,1026
    8000523e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005242:	00d5151b          	slliw	a0,a0,0xd
    80005246:	0c2017b7          	lui	a5,0xc201
    8000524a:	953e                	add	a0,a0,a5
    8000524c:	00052023          	sw	zero,0(a0)
}
    80005250:	60a2                	ld	ra,8(sp)
    80005252:	6402                	ld	s0,0(sp)
    80005254:	0141                	addi	sp,sp,16
    80005256:	8082                	ret

0000000080005258 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005258:	1141                	addi	sp,sp,-16
    8000525a:	e406                	sd	ra,8(sp)
    8000525c:	e022                	sd	s0,0(sp)
    8000525e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005260:	e4efc0ef          	jal	ra,800018ae <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005264:	00d5179b          	slliw	a5,a0,0xd
    80005268:	0c201537          	lui	a0,0xc201
    8000526c:	953e                	add	a0,a0,a5
  return irq;
}
    8000526e:	4148                	lw	a0,4(a0)
    80005270:	60a2                	ld	ra,8(sp)
    80005272:	6402                	ld	s0,0(sp)
    80005274:	0141                	addi	sp,sp,16
    80005276:	8082                	ret

0000000080005278 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005278:	1101                	addi	sp,sp,-32
    8000527a:	ec06                	sd	ra,24(sp)
    8000527c:	e822                	sd	s0,16(sp)
    8000527e:	e426                	sd	s1,8(sp)
    80005280:	1000                	addi	s0,sp,32
    80005282:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005284:	e2afc0ef          	jal	ra,800018ae <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005288:	00d5151b          	slliw	a0,a0,0xd
    8000528c:	0c2017b7          	lui	a5,0xc201
    80005290:	97aa                	add	a5,a5,a0
    80005292:	c3c4                	sw	s1,4(a5)
}
    80005294:	60e2                	ld	ra,24(sp)
    80005296:	6442                	ld	s0,16(sp)
    80005298:	64a2                	ld	s1,8(sp)
    8000529a:	6105                	addi	sp,sp,32
    8000529c:	8082                	ret

000000008000529e <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    8000529e:	1141                	addi	sp,sp,-16
    800052a0:	e406                	sd	ra,8(sp)
    800052a2:	e022                	sd	s0,0(sp)
    800052a4:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800052a6:	479d                	li	a5,7
    800052a8:	04a7ca63          	blt	a5,a0,800052fc <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    800052ac:	0001c797          	auipc	a5,0x1c
    800052b0:	afc78793          	addi	a5,a5,-1284 # 80020da8 <disk>
    800052b4:	97aa                	add	a5,a5,a0
    800052b6:	0187c783          	lbu	a5,24(a5)
    800052ba:	e7b9                	bnez	a5,80005308 <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800052bc:	00451613          	slli	a2,a0,0x4
    800052c0:	0001c797          	auipc	a5,0x1c
    800052c4:	ae878793          	addi	a5,a5,-1304 # 80020da8 <disk>
    800052c8:	6394                	ld	a3,0(a5)
    800052ca:	96b2                	add	a3,a3,a2
    800052cc:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800052d0:	6398                	ld	a4,0(a5)
    800052d2:	9732                	add	a4,a4,a2
    800052d4:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800052d8:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800052dc:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800052e0:	953e                	add	a0,a0,a5
    800052e2:	4785                	li	a5,1
    800052e4:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800052e8:	0001c517          	auipc	a0,0x1c
    800052ec:	ad850513          	addi	a0,a0,-1320 # 80020dc0 <disk+0x18>
    800052f0:	c1dfc0ef          	jal	ra,80001f0c <wakeup>
}
    800052f4:	60a2                	ld	ra,8(sp)
    800052f6:	6402                	ld	s0,0(sp)
    800052f8:	0141                	addi	sp,sp,16
    800052fa:	8082                	ret
    panic("free_desc 1");
    800052fc:	00002517          	auipc	a0,0x2
    80005300:	57450513          	addi	a0,a0,1396 # 80007870 <syscallnames+0x2f0>
    80005304:	cd8fb0ef          	jal	ra,800007dc <panic>
    panic("free_desc 2");
    80005308:	00002517          	auipc	a0,0x2
    8000530c:	57850513          	addi	a0,a0,1400 # 80007880 <syscallnames+0x300>
    80005310:	cccfb0ef          	jal	ra,800007dc <panic>

0000000080005314 <virtio_disk_init>:
{
    80005314:	1101                	addi	sp,sp,-32
    80005316:	ec06                	sd	ra,24(sp)
    80005318:	e822                	sd	s0,16(sp)
    8000531a:	e426                	sd	s1,8(sp)
    8000531c:	e04a                	sd	s2,0(sp)
    8000531e:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005320:	00002597          	auipc	a1,0x2
    80005324:	57058593          	addi	a1,a1,1392 # 80007890 <syscallnames+0x310>
    80005328:	0001c517          	auipc	a0,0x1c
    8000532c:	ba850513          	addi	a0,a0,-1112 # 80020ed0 <disk+0x128>
    80005330:	893fb0ef          	jal	ra,80000bc2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005334:	100017b7          	lui	a5,0x10001
    80005338:	4398                	lw	a4,0(a5)
    8000533a:	2701                	sext.w	a4,a4
    8000533c:	747277b7          	lui	a5,0x74727
    80005340:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005344:	14f71063          	bne	a4,a5,80005484 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005348:	100017b7          	lui	a5,0x10001
    8000534c:	43dc                	lw	a5,4(a5)
    8000534e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005350:	4709                	li	a4,2
    80005352:	12e79963          	bne	a5,a4,80005484 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005356:	100017b7          	lui	a5,0x10001
    8000535a:	479c                	lw	a5,8(a5)
    8000535c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000535e:	12e79363          	bne	a5,a4,80005484 <virtio_disk_init+0x170>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005362:	100017b7          	lui	a5,0x10001
    80005366:	47d8                	lw	a4,12(a5)
    80005368:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000536a:	554d47b7          	lui	a5,0x554d4
    8000536e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005372:	10f71963          	bne	a4,a5,80005484 <virtio_disk_init+0x170>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005376:	100017b7          	lui	a5,0x10001
    8000537a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000537e:	4705                	li	a4,1
    80005380:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005382:	470d                	li	a4,3
    80005384:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005386:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005388:	c7ffe737          	lui	a4,0xc7ffe
    8000538c:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdd877>
    80005390:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005392:	2701                	sext.w	a4,a4
    80005394:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005396:	472d                	li	a4,11
    80005398:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000539a:	5bbc                	lw	a5,112(a5)
    8000539c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800053a0:	8ba1                	andi	a5,a5,8
    800053a2:	0e078763          	beqz	a5,80005490 <virtio_disk_init+0x17c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800053a6:	100017b7          	lui	a5,0x10001
    800053aa:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800053ae:	43fc                	lw	a5,68(a5)
    800053b0:	2781                	sext.w	a5,a5
    800053b2:	0e079563          	bnez	a5,8000549c <virtio_disk_init+0x188>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800053b6:	100017b7          	lui	a5,0x10001
    800053ba:	5bdc                	lw	a5,52(a5)
    800053bc:	2781                	sext.w	a5,a5
  if(max == 0)
    800053be:	0e078563          	beqz	a5,800054a8 <virtio_disk_init+0x194>
  if(max < NUM)
    800053c2:	471d                	li	a4,7
    800053c4:	0ef77863          	bgeu	a4,a5,800054b4 <virtio_disk_init+0x1a0>
  disk.desc = kalloc();
    800053c8:	faafb0ef          	jal	ra,80000b72 <kalloc>
    800053cc:	0001c497          	auipc	s1,0x1c
    800053d0:	9dc48493          	addi	s1,s1,-1572 # 80020da8 <disk>
    800053d4:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800053d6:	f9cfb0ef          	jal	ra,80000b72 <kalloc>
    800053da:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800053dc:	f96fb0ef          	jal	ra,80000b72 <kalloc>
    800053e0:	87aa                	mv	a5,a0
    800053e2:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800053e4:	6088                	ld	a0,0(s1)
    800053e6:	cd69                	beqz	a0,800054c0 <virtio_disk_init+0x1ac>
    800053e8:	0001c717          	auipc	a4,0x1c
    800053ec:	9c873703          	ld	a4,-1592(a4) # 80020db0 <disk+0x8>
    800053f0:	cb61                	beqz	a4,800054c0 <virtio_disk_init+0x1ac>
    800053f2:	c7f9                	beqz	a5,800054c0 <virtio_disk_init+0x1ac>
  memset(disk.desc, 0, PGSIZE);
    800053f4:	6605                	lui	a2,0x1
    800053f6:	4581                	li	a1,0
    800053f8:	91ffb0ef          	jal	ra,80000d16 <memset>
  memset(disk.avail, 0, PGSIZE);
    800053fc:	0001c497          	auipc	s1,0x1c
    80005400:	9ac48493          	addi	s1,s1,-1620 # 80020da8 <disk>
    80005404:	6605                	lui	a2,0x1
    80005406:	4581                	li	a1,0
    80005408:	6488                	ld	a0,8(s1)
    8000540a:	90dfb0ef          	jal	ra,80000d16 <memset>
  memset(disk.used, 0, PGSIZE);
    8000540e:	6605                	lui	a2,0x1
    80005410:	4581                	li	a1,0
    80005412:	6888                	ld	a0,16(s1)
    80005414:	903fb0ef          	jal	ra,80000d16 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005418:	100017b7          	lui	a5,0x10001
    8000541c:	4721                	li	a4,8
    8000541e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005420:	4098                	lw	a4,0(s1)
    80005422:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005426:	40d8                	lw	a4,4(s1)
    80005428:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000542c:	6498                	ld	a4,8(s1)
    8000542e:	0007069b          	sext.w	a3,a4
    80005432:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005436:	9701                	srai	a4,a4,0x20
    80005438:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000543c:	6898                	ld	a4,16(s1)
    8000543e:	0007069b          	sext.w	a3,a4
    80005442:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005446:	9701                	srai	a4,a4,0x20
    80005448:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000544c:	4705                	li	a4,1
    8000544e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005450:	00e48c23          	sb	a4,24(s1)
    80005454:	00e48ca3          	sb	a4,25(s1)
    80005458:	00e48d23          	sb	a4,26(s1)
    8000545c:	00e48da3          	sb	a4,27(s1)
    80005460:	00e48e23          	sb	a4,28(s1)
    80005464:	00e48ea3          	sb	a4,29(s1)
    80005468:	00e48f23          	sb	a4,30(s1)
    8000546c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005470:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005474:	0727a823          	sw	s2,112(a5)
}
    80005478:	60e2                	ld	ra,24(sp)
    8000547a:	6442                	ld	s0,16(sp)
    8000547c:	64a2                	ld	s1,8(sp)
    8000547e:	6902                	ld	s2,0(sp)
    80005480:	6105                	addi	sp,sp,32
    80005482:	8082                	ret
    panic("could not find virtio disk");
    80005484:	00002517          	auipc	a0,0x2
    80005488:	41c50513          	addi	a0,a0,1052 # 800078a0 <syscallnames+0x320>
    8000548c:	b50fb0ef          	jal	ra,800007dc <panic>
    panic("virtio disk FEATURES_OK unset");
    80005490:	00002517          	auipc	a0,0x2
    80005494:	43050513          	addi	a0,a0,1072 # 800078c0 <syscallnames+0x340>
    80005498:	b44fb0ef          	jal	ra,800007dc <panic>
    panic("virtio disk should not be ready");
    8000549c:	00002517          	auipc	a0,0x2
    800054a0:	44450513          	addi	a0,a0,1092 # 800078e0 <syscallnames+0x360>
    800054a4:	b38fb0ef          	jal	ra,800007dc <panic>
    panic("virtio disk has no queue 0");
    800054a8:	00002517          	auipc	a0,0x2
    800054ac:	45850513          	addi	a0,a0,1112 # 80007900 <syscallnames+0x380>
    800054b0:	b2cfb0ef          	jal	ra,800007dc <panic>
    panic("virtio disk max queue too short");
    800054b4:	00002517          	auipc	a0,0x2
    800054b8:	46c50513          	addi	a0,a0,1132 # 80007920 <syscallnames+0x3a0>
    800054bc:	b20fb0ef          	jal	ra,800007dc <panic>
    panic("virtio disk kalloc");
    800054c0:	00002517          	auipc	a0,0x2
    800054c4:	48050513          	addi	a0,a0,1152 # 80007940 <syscallnames+0x3c0>
    800054c8:	b14fb0ef          	jal	ra,800007dc <panic>

00000000800054cc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800054cc:	7119                	addi	sp,sp,-128
    800054ce:	fc86                	sd	ra,120(sp)
    800054d0:	f8a2                	sd	s0,112(sp)
    800054d2:	f4a6                	sd	s1,104(sp)
    800054d4:	f0ca                	sd	s2,96(sp)
    800054d6:	ecce                	sd	s3,88(sp)
    800054d8:	e8d2                	sd	s4,80(sp)
    800054da:	e4d6                	sd	s5,72(sp)
    800054dc:	e0da                	sd	s6,64(sp)
    800054de:	fc5e                	sd	s7,56(sp)
    800054e0:	f862                	sd	s8,48(sp)
    800054e2:	f466                	sd	s9,40(sp)
    800054e4:	f06a                	sd	s10,32(sp)
    800054e6:	ec6e                	sd	s11,24(sp)
    800054e8:	0100                	addi	s0,sp,128
    800054ea:	8aaa                	mv	s5,a0
    800054ec:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800054ee:	00c52d03          	lw	s10,12(a0)
    800054f2:	001d1d1b          	slliw	s10,s10,0x1
    800054f6:	1d02                	slli	s10,s10,0x20
    800054f8:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800054fc:	0001c517          	auipc	a0,0x1c
    80005500:	9d450513          	addi	a0,a0,-1580 # 80020ed0 <disk+0x128>
    80005504:	f3efb0ef          	jal	ra,80000c42 <acquire>
  for(int i = 0; i < 3; i++){
    80005508:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000550a:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000550c:	0001cb97          	auipc	s7,0x1c
    80005510:	89cb8b93          	addi	s7,s7,-1892 # 80020da8 <disk>
  for(int i = 0; i < 3; i++){
    80005514:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005516:	0001cc97          	auipc	s9,0x1c
    8000551a:	9bac8c93          	addi	s9,s9,-1606 # 80020ed0 <disk+0x128>
    8000551e:	a8a9                	j	80005578 <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005520:	00fb8733          	add	a4,s7,a5
    80005524:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005528:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000552a:	0207c563          	bltz	a5,80005554 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000552e:	2905                	addiw	s2,s2,1
    80005530:	0611                	addi	a2,a2,4
    80005532:	05690863          	beq	s2,s6,80005582 <virtio_disk_rw+0xb6>
    idx[i] = alloc_desc();
    80005536:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005538:	0001c717          	auipc	a4,0x1c
    8000553c:	87070713          	addi	a4,a4,-1936 # 80020da8 <disk>
    80005540:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005542:	01874683          	lbu	a3,24(a4)
    80005546:	fee9                	bnez	a3,80005520 <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80005548:	2785                	addiw	a5,a5,1
    8000554a:	0705                	addi	a4,a4,1
    8000554c:	fe979be3          	bne	a5,s1,80005542 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005550:	57fd                	li	a5,-1
    80005552:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005554:	01205b63          	blez	s2,8000556a <virtio_disk_rw+0x9e>
    80005558:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000555a:	000a2503          	lw	a0,0(s4)
    8000555e:	d41ff0ef          	jal	ra,8000529e <free_desc>
      for(int j = 0; j < i; j++)
    80005562:	2d85                	addiw	s11,s11,1
    80005564:	0a11                	addi	s4,s4,4
    80005566:	ffb91ae3          	bne	s2,s11,8000555a <virtio_disk_rw+0x8e>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000556a:	85e6                	mv	a1,s9
    8000556c:	0001c517          	auipc	a0,0x1c
    80005570:	85450513          	addi	a0,a0,-1964 # 80020dc0 <disk+0x18>
    80005574:	94dfc0ef          	jal	ra,80001ec0 <sleep>
  for(int i = 0; i < 3; i++){
    80005578:	f8040a13          	addi	s4,s0,-128
{
    8000557c:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000557e:	894e                	mv	s2,s3
    80005580:	bf5d                	j	80005536 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005582:	f8042583          	lw	a1,-128(s0)
    80005586:	00a58793          	addi	a5,a1,10
    8000558a:	0792                	slli	a5,a5,0x4

  if(write)
    8000558c:	0001c617          	auipc	a2,0x1c
    80005590:	81c60613          	addi	a2,a2,-2020 # 80020da8 <disk>
    80005594:	00f60733          	add	a4,a2,a5
    80005598:	018036b3          	snez	a3,s8
    8000559c:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000559e:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800055a2:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800055a6:	f6078693          	addi	a3,a5,-160
    800055aa:	6218                	ld	a4,0(a2)
    800055ac:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800055ae:	00878513          	addi	a0,a5,8
    800055b2:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800055b4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800055b6:	6208                	ld	a0,0(a2)
    800055b8:	96aa                	add	a3,a3,a0
    800055ba:	4741                	li	a4,16
    800055bc:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800055be:	4705                	li	a4,1
    800055c0:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800055c4:	f8442703          	lw	a4,-124(s0)
    800055c8:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800055cc:	0712                	slli	a4,a4,0x4
    800055ce:	953a                	add	a0,a0,a4
    800055d0:	058a8693          	addi	a3,s5,88
    800055d4:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800055d6:	6208                	ld	a0,0(a2)
    800055d8:	972a                	add	a4,a4,a0
    800055da:	40000693          	li	a3,1024
    800055de:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800055e0:	001c3c13          	seqz	s8,s8
    800055e4:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800055e6:	001c6c13          	ori	s8,s8,1
    800055ea:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800055ee:	f8842603          	lw	a2,-120(s0)
    800055f2:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800055f6:	0001b697          	auipc	a3,0x1b
    800055fa:	7b268693          	addi	a3,a3,1970 # 80020da8 <disk>
    800055fe:	00258713          	addi	a4,a1,2
    80005602:	0712                	slli	a4,a4,0x4
    80005604:	9736                	add	a4,a4,a3
    80005606:	587d                	li	a6,-1
    80005608:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000560c:	0612                	slli	a2,a2,0x4
    8000560e:	9532                	add	a0,a0,a2
    80005610:	f9078793          	addi	a5,a5,-112
    80005614:	97b6                	add	a5,a5,a3
    80005616:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80005618:	629c                	ld	a5,0(a3)
    8000561a:	97b2                	add	a5,a5,a2
    8000561c:	4605                	li	a2,1
    8000561e:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005620:	4509                	li	a0,2
    80005622:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    80005626:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000562a:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000562e:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005632:	6698                	ld	a4,8(a3)
    80005634:	00275783          	lhu	a5,2(a4)
    80005638:	8b9d                	andi	a5,a5,7
    8000563a:	0786                	slli	a5,a5,0x1
    8000563c:	97ba                	add	a5,a5,a4
    8000563e:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005642:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005646:	6698                	ld	a4,8(a3)
    80005648:	00275783          	lhu	a5,2(a4)
    8000564c:	2785                	addiw	a5,a5,1
    8000564e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005652:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005656:	100017b7          	lui	a5,0x10001
    8000565a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000565e:	004aa783          	lw	a5,4(s5)
    80005662:	00c79f63          	bne	a5,a2,80005680 <virtio_disk_rw+0x1b4>
    sleep(b, &disk.vdisk_lock);
    80005666:	0001c917          	auipc	s2,0x1c
    8000566a:	86a90913          	addi	s2,s2,-1942 # 80020ed0 <disk+0x128>
  while(b->disk == 1) {
    8000566e:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005670:	85ca                	mv	a1,s2
    80005672:	8556                	mv	a0,s5
    80005674:	84dfc0ef          	jal	ra,80001ec0 <sleep>
  while(b->disk == 1) {
    80005678:	004aa783          	lw	a5,4(s5)
    8000567c:	fe978ae3          	beq	a5,s1,80005670 <virtio_disk_rw+0x1a4>
  }

  disk.info[idx[0]].b = 0;
    80005680:	f8042903          	lw	s2,-128(s0)
    80005684:	00290793          	addi	a5,s2,2
    80005688:	00479713          	slli	a4,a5,0x4
    8000568c:	0001b797          	auipc	a5,0x1b
    80005690:	71c78793          	addi	a5,a5,1820 # 80020da8 <disk>
    80005694:	97ba                	add	a5,a5,a4
    80005696:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000569a:	0001b997          	auipc	s3,0x1b
    8000569e:	70e98993          	addi	s3,s3,1806 # 80020da8 <disk>
    800056a2:	00491713          	slli	a4,s2,0x4
    800056a6:	0009b783          	ld	a5,0(s3)
    800056aa:	97ba                	add	a5,a5,a4
    800056ac:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800056b0:	854a                	mv	a0,s2
    800056b2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800056b6:	be9ff0ef          	jal	ra,8000529e <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800056ba:	8885                	andi	s1,s1,1
    800056bc:	f0fd                	bnez	s1,800056a2 <virtio_disk_rw+0x1d6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800056be:	0001c517          	auipc	a0,0x1c
    800056c2:	81250513          	addi	a0,a0,-2030 # 80020ed0 <disk+0x128>
    800056c6:	e14fb0ef          	jal	ra,80000cda <release>
}
    800056ca:	70e6                	ld	ra,120(sp)
    800056cc:	7446                	ld	s0,112(sp)
    800056ce:	74a6                	ld	s1,104(sp)
    800056d0:	7906                	ld	s2,96(sp)
    800056d2:	69e6                	ld	s3,88(sp)
    800056d4:	6a46                	ld	s4,80(sp)
    800056d6:	6aa6                	ld	s5,72(sp)
    800056d8:	6b06                	ld	s6,64(sp)
    800056da:	7be2                	ld	s7,56(sp)
    800056dc:	7c42                	ld	s8,48(sp)
    800056de:	7ca2                	ld	s9,40(sp)
    800056e0:	7d02                	ld	s10,32(sp)
    800056e2:	6de2                	ld	s11,24(sp)
    800056e4:	6109                	addi	sp,sp,128
    800056e6:	8082                	ret

00000000800056e8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800056e8:	1101                	addi	sp,sp,-32
    800056ea:	ec06                	sd	ra,24(sp)
    800056ec:	e822                	sd	s0,16(sp)
    800056ee:	e426                	sd	s1,8(sp)
    800056f0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800056f2:	0001b497          	auipc	s1,0x1b
    800056f6:	6b648493          	addi	s1,s1,1718 # 80020da8 <disk>
    800056fa:	0001b517          	auipc	a0,0x1b
    800056fe:	7d650513          	addi	a0,a0,2006 # 80020ed0 <disk+0x128>
    80005702:	d40fb0ef          	jal	ra,80000c42 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005706:	10001737          	lui	a4,0x10001
    8000570a:	533c                	lw	a5,96(a4)
    8000570c:	8b8d                	andi	a5,a5,3
    8000570e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80005710:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005714:	689c                	ld	a5,16(s1)
    80005716:	0204d703          	lhu	a4,32(s1)
    8000571a:	0027d783          	lhu	a5,2(a5)
    8000571e:	04f70663          	beq	a4,a5,8000576a <virtio_disk_intr+0x82>
    __sync_synchronize();
    80005722:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005726:	6898                	ld	a4,16(s1)
    80005728:	0204d783          	lhu	a5,32(s1)
    8000572c:	8b9d                	andi	a5,a5,7
    8000572e:	078e                	slli	a5,a5,0x3
    80005730:	97ba                	add	a5,a5,a4
    80005732:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005734:	00278713          	addi	a4,a5,2
    80005738:	0712                	slli	a4,a4,0x4
    8000573a:	9726                	add	a4,a4,s1
    8000573c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80005740:	e321                	bnez	a4,80005780 <virtio_disk_intr+0x98>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005742:	0789                	addi	a5,a5,2
    80005744:	0792                	slli	a5,a5,0x4
    80005746:	97a6                	add	a5,a5,s1
    80005748:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000574a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000574e:	fbefc0ef          	jal	ra,80001f0c <wakeup>

    disk.used_idx += 1;
    80005752:	0204d783          	lhu	a5,32(s1)
    80005756:	2785                	addiw	a5,a5,1
    80005758:	17c2                	slli	a5,a5,0x30
    8000575a:	93c1                	srli	a5,a5,0x30
    8000575c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005760:	6898                	ld	a4,16(s1)
    80005762:	00275703          	lhu	a4,2(a4)
    80005766:	faf71ee3          	bne	a4,a5,80005722 <virtio_disk_intr+0x3a>
  }

  release(&disk.vdisk_lock);
    8000576a:	0001b517          	auipc	a0,0x1b
    8000576e:	76650513          	addi	a0,a0,1894 # 80020ed0 <disk+0x128>
    80005772:	d68fb0ef          	jal	ra,80000cda <release>
}
    80005776:	60e2                	ld	ra,24(sp)
    80005778:	6442                	ld	s0,16(sp)
    8000577a:	64a2                	ld	s1,8(sp)
    8000577c:	6105                	addi	sp,sp,32
    8000577e:	8082                	ret
      panic("virtio_disk_intr status");
    80005780:	00002517          	auipc	a0,0x2
    80005784:	1d850513          	addi	a0,a0,472 # 80007958 <syscallnames+0x3d8>
    80005788:	854fb0ef          	jal	ra,800007dc <panic>
	...

0000000080006000 <_trampoline>:
    80006000:	14051073          	csrw	sscratch,a0
    80006004:	02000537          	lui	a0,0x2000
    80006008:	357d                	addiw	a0,a0,-1
    8000600a:	0536                	slli	a0,a0,0xd
    8000600c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80006010:	02253823          	sd	sp,48(a0)
    80006014:	02353c23          	sd	gp,56(a0)
    80006018:	04453023          	sd	tp,64(a0)
    8000601c:	04553423          	sd	t0,72(a0)
    80006020:	04653823          	sd	t1,80(a0)
    80006024:	04753c23          	sd	t2,88(a0)
    80006028:	f120                	sd	s0,96(a0)
    8000602a:	f524                	sd	s1,104(a0)
    8000602c:	fd2c                	sd	a1,120(a0)
    8000602e:	e150                	sd	a2,128(a0)
    80006030:	e554                	sd	a3,136(a0)
    80006032:	e958                	sd	a4,144(a0)
    80006034:	ed5c                	sd	a5,152(a0)
    80006036:	0b053023          	sd	a6,160(a0)
    8000603a:	0b153423          	sd	a7,168(a0)
    8000603e:	0b253823          	sd	s2,176(a0)
    80006042:	0b353c23          	sd	s3,184(a0)
    80006046:	0d453023          	sd	s4,192(a0)
    8000604a:	0d553423          	sd	s5,200(a0)
    8000604e:	0d653823          	sd	s6,208(a0)
    80006052:	0d753c23          	sd	s7,216(a0)
    80006056:	0f853023          	sd	s8,224(a0)
    8000605a:	0f953423          	sd	s9,232(a0)
    8000605e:	0fa53823          	sd	s10,240(a0)
    80006062:	0fb53c23          	sd	s11,248(a0)
    80006066:	11c53023          	sd	t3,256(a0)
    8000606a:	11d53423          	sd	t4,264(a0)
    8000606e:	11e53823          	sd	t5,272(a0)
    80006072:	11f53c23          	sd	t6,280(a0)
    80006076:	140022f3          	csrr	t0,sscratch
    8000607a:	06553823          	sd	t0,112(a0)
    8000607e:	00853103          	ld	sp,8(a0)
    80006082:	02053203          	ld	tp,32(a0)
    80006086:	01053283          	ld	t0,16(a0)
    8000608a:	00053303          	ld	t1,0(a0)
    8000608e:	12000073          	sfence.vma
    80006092:	18031073          	csrw	satp,t1
    80006096:	12000073          	sfence.vma
    8000609a:	9282                	jalr	t0

000000008000609c <userret>:
    8000609c:	12000073          	sfence.vma
    800060a0:	18051073          	csrw	satp,a0
    800060a4:	12000073          	sfence.vma
    800060a8:	02000537          	lui	a0,0x2000
    800060ac:	357d                	addiw	a0,a0,-1
    800060ae:	0536                	slli	a0,a0,0xd
    800060b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800060b4:	03053103          	ld	sp,48(a0)
    800060b8:	03853183          	ld	gp,56(a0)
    800060bc:	04053203          	ld	tp,64(a0)
    800060c0:	04853283          	ld	t0,72(a0)
    800060c4:	05053303          	ld	t1,80(a0)
    800060c8:	05853383          	ld	t2,88(a0)
    800060cc:	7120                	ld	s0,96(a0)
    800060ce:	7524                	ld	s1,104(a0)
    800060d0:	7d2c                	ld	a1,120(a0)
    800060d2:	6150                	ld	a2,128(a0)
    800060d4:	6554                	ld	a3,136(a0)
    800060d6:	6958                	ld	a4,144(a0)
    800060d8:	6d5c                	ld	a5,152(a0)
    800060da:	0a053803          	ld	a6,160(a0)
    800060de:	0a853883          	ld	a7,168(a0)
    800060e2:	0b053903          	ld	s2,176(a0)
    800060e6:	0b853983          	ld	s3,184(a0)
    800060ea:	0c053a03          	ld	s4,192(a0)
    800060ee:	0c853a83          	ld	s5,200(a0)
    800060f2:	0d053b03          	ld	s6,208(a0)
    800060f6:	0d853b83          	ld	s7,216(a0)
    800060fa:	0e053c03          	ld	s8,224(a0)
    800060fe:	0e853c83          	ld	s9,232(a0)
    80006102:	0f053d03          	ld	s10,240(a0)
    80006106:	0f853d83          	ld	s11,248(a0)
    8000610a:	10053e03          	ld	t3,256(a0)
    8000610e:	10853e83          	ld	t4,264(a0)
    80006112:	11053f03          	ld	t5,272(a0)
    80006116:	11853f83          	ld	t6,280(a0)
    8000611a:	7928                	ld	a0,112(a0)
    8000611c:	10200073          	sret
	...
