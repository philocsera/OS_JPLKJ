
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	52813103          	ld	sp,1320(sp) # 8000a528 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000016:	04a000ef          	jal	80000060 <start>

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
    80000056:	14d79073          	csrw	stimecmp,a5
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
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd9d87>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	dfe78793          	addi	a5,a5,-514 # 80000e7e <main>
    80000088:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000008c:	4781                	li	a5,0
    8000008e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000092:	67c1                	lui	a5,0x10
    80000094:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
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
    800000b8:	f65ff0ef          	jal	8000001c <timerinit>
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
// user write() system calls to the console go here.
// uses sleep() and UART interrupts.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000d0:	7119                	addi	sp,sp,-128
    800000d2:	fc86                	sd	ra,120(sp)
    800000d4:	f8a2                	sd	s0,112(sp)
    800000d6:	f4a6                	sd	s1,104(sp)
    800000d8:	0100                	addi	s0,sp,128
  char buf[32]; // move batches from user space to uart.
  int i = 0;

  while(i < n){
    800000da:	06c05a63          	blez	a2,8000014e <consolewrite+0x7e>
    800000de:	f0ca                	sd	s2,96(sp)
    800000e0:	ecce                	sd	s3,88(sp)
    800000e2:	e8d2                	sd	s4,80(sp)
    800000e4:	e4d6                	sd	s5,72(sp)
    800000e6:	e0da                	sd	s6,64(sp)
    800000e8:	fc5e                	sd	s7,56(sp)
    800000ea:	f862                	sd	s8,48(sp)
    800000ec:	f466                	sd	s9,40(sp)
    800000ee:	8aaa                	mv	s5,a0
    800000f0:	8b2e                	mv	s6,a1
    800000f2:	8a32                	mv	s4,a2
  int i = 0;
    800000f4:	4481                	li	s1,0
    int nn = sizeof(buf);
    if(nn > n - i)
    800000f6:	02000c13          	li	s8,32
    800000fa:	02000c93          	li	s9,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    800000fe:	5bfd                	li	s7,-1
    80000100:	a035                	j	8000012c <consolewrite+0x5c>
    if(nn > n - i)
    80000102:	0009099b          	sext.w	s3,s2
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    80000106:	86ce                	mv	a3,s3
    80000108:	01648633          	add	a2,s1,s6
    8000010c:	85d6                	mv	a1,s5
    8000010e:	f8040513          	addi	a0,s0,-128
    80000112:	22e020ef          	jal	80002340 <either_copyin>
    80000116:	03750e63          	beq	a0,s7,80000152 <consolewrite+0x82>
      break;
    uartwrite(buf, nn);
    8000011a:	85ce                	mv	a1,s3
    8000011c:	f8040513          	addi	a0,s0,-128
    80000120:	778000ef          	jal	80000898 <uartwrite>
    i += nn;
    80000124:	009904bb          	addw	s1,s2,s1
  while(i < n){
    80000128:	0144da63          	bge	s1,s4,8000013c <consolewrite+0x6c>
    if(nn > n - i)
    8000012c:	409a093b          	subw	s2,s4,s1
    80000130:	0009079b          	sext.w	a5,s2
    80000134:	fcfc57e3          	bge	s8,a5,80000102 <consolewrite+0x32>
    80000138:	8966                	mv	s2,s9
    8000013a:	b7e1                	j	80000102 <consolewrite+0x32>
    8000013c:	7906                	ld	s2,96(sp)
    8000013e:	69e6                	ld	s3,88(sp)
    80000140:	6a46                	ld	s4,80(sp)
    80000142:	6aa6                	ld	s5,72(sp)
    80000144:	6b06                	ld	s6,64(sp)
    80000146:	7be2                	ld	s7,56(sp)
    80000148:	7c42                	ld	s8,48(sp)
    8000014a:	7ca2                	ld	s9,40(sp)
    8000014c:	a819                	j	80000162 <consolewrite+0x92>
  int i = 0;
    8000014e:	4481                	li	s1,0
    80000150:	a809                	j	80000162 <consolewrite+0x92>
    80000152:	7906                	ld	s2,96(sp)
    80000154:	69e6                	ld	s3,88(sp)
    80000156:	6a46                	ld	s4,80(sp)
    80000158:	6aa6                	ld	s5,72(sp)
    8000015a:	6b06                	ld	s6,64(sp)
    8000015c:	7be2                	ld	s7,56(sp)
    8000015e:	7c42                	ld	s8,48(sp)
    80000160:	7ca2                	ld	s9,40(sp)
  }

  return i;
}
    80000162:	8526                	mv	a0,s1
    80000164:	70e6                	ld	ra,120(sp)
    80000166:	7446                	ld	s0,112(sp)
    80000168:	74a6                	ld	s1,104(sp)
    8000016a:	6109                	addi	sp,sp,128
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dst indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00012517          	auipc	a0,0x12
    80000190:	3e450513          	addi	a0,a0,996 # 80012570 <cons>
    80000194:	27d000ef          	jal	80000c10 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00012497          	auipc	s1,0x12
    8000019c:	3d848493          	addi	s1,s1,984 # 80012570 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00012917          	auipc	s2,0x12
    800001a4:	46890913          	addi	s2,s2,1128 # 80012608 <cons+0x98>
  while(n > 0){
    800001a8:	0b305d63          	blez	s3,80000262 <consoleread+0xf4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	0af71263          	bne	a4,a5,80000258 <consoleread+0xea>
      if(killed(myproc())){
    800001b8:	758010ef          	jal	80001910 <myproc>
    800001bc:	016020ef          	jal	800021d2 <killed>
    800001c0:	e12d                	bnez	a0,80000222 <consoleread+0xb4>
      sleep(&cons.r, &cons.lock);
    800001c2:	85a6                	mv	a1,s1
    800001c4:	854a                	mv	a0,s2
    800001c6:	5d5010ef          	jal	80001f9a <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef703e3          	beq	a4,a5,800001b8 <consoleread+0x4a>
    800001d6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001d8:	00012717          	auipc	a4,0x12
    800001dc:	39870713          	addi	a4,a4,920 # 80012570 <cons>
    800001e0:	0017869b          	addiw	a3,a5,1
    800001e4:	08d72c23          	sw	a3,152(a4)
    800001e8:	07f7f693          	andi	a3,a5,127
    800001ec:	9736                	add	a4,a4,a3
    800001ee:	01874703          	lbu	a4,24(a4)
    800001f2:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001f6:	4691                	li	a3,4
    800001f8:	04db8663          	beq	s7,a3,80000244 <consoleread+0xd6>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    800001fc:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000200:	4685                	li	a3,1
    80000202:	faf40613          	addi	a2,s0,-81
    80000206:	85d2                	mv	a1,s4
    80000208:	8556                	mv	a0,s5
    8000020a:	0ec020ef          	jal	800022f6 <either_copyout>
    8000020e:	57fd                	li	a5,-1
    80000210:	04f50863          	beq	a0,a5,80000260 <consoleread+0xf2>
      break;

    dst++;
    80000214:	0a05                	addi	s4,s4,1
    --n;
    80000216:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000218:	47a9                	li	a5,10
    8000021a:	04fb8d63          	beq	s7,a5,80000274 <consoleread+0x106>
    8000021e:	6be2                	ld	s7,24(sp)
    80000220:	b761                	j	800001a8 <consoleread+0x3a>
        release(&cons.lock);
    80000222:	00012517          	auipc	a0,0x12
    80000226:	34e50513          	addi	a0,a0,846 # 80012570 <cons>
    8000022a:	27f000ef          	jal	80000ca8 <release>
        return -1;
    8000022e:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000230:	60e6                	ld	ra,88(sp)
    80000232:	6446                	ld	s0,80(sp)
    80000234:	64a6                	ld	s1,72(sp)
    80000236:	6906                	ld	s2,64(sp)
    80000238:	79e2                	ld	s3,56(sp)
    8000023a:	7a42                	ld	s4,48(sp)
    8000023c:	7aa2                	ld	s5,40(sp)
    8000023e:	7b02                	ld	s6,32(sp)
    80000240:	6125                	addi	sp,sp,96
    80000242:	8082                	ret
      if(n < target){
    80000244:	0009871b          	sext.w	a4,s3
    80000248:	01677a63          	bgeu	a4,s6,8000025c <consoleread+0xee>
        cons.r--;
    8000024c:	00012717          	auipc	a4,0x12
    80000250:	3af72e23          	sw	a5,956(a4) # 80012608 <cons+0x98>
    80000254:	6be2                	ld	s7,24(sp)
    80000256:	a031                	j	80000262 <consoleread+0xf4>
    80000258:	ec5e                	sd	s7,24(sp)
    8000025a:	bfbd                	j	800001d8 <consoleread+0x6a>
    8000025c:	6be2                	ld	s7,24(sp)
    8000025e:	a011                	j	80000262 <consoleread+0xf4>
    80000260:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    80000262:	00012517          	auipc	a0,0x12
    80000266:	30e50513          	addi	a0,a0,782 # 80012570 <cons>
    8000026a:	23f000ef          	jal	80000ca8 <release>
  return target - n;
    8000026e:	413b053b          	subw	a0,s6,s3
    80000272:	bf7d                	j	80000230 <consoleread+0xc2>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	b7f5                	j	80000262 <consoleread+0xf4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50863          	beq	a0,a5,80000294 <consputc+0x1c>
    uartputc_sync(c);
    80000288:	6a4000ef          	jal	8000092c <uartputc_sync>
}
    8000028c:	60a2                	ld	ra,8(sp)
    8000028e:	6402                	ld	s0,0(sp)
    80000290:	0141                	addi	sp,sp,16
    80000292:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000294:	4521                	li	a0,8
    80000296:	696000ef          	jal	8000092c <uartputc_sync>
    8000029a:	02000513          	li	a0,32
    8000029e:	68e000ef          	jal	8000092c <uartputc_sync>
    800002a2:	4521                	li	a0,8
    800002a4:	688000ef          	jal	8000092c <uartputc_sync>
    800002a8:	b7d5                	j	8000028c <consputc+0x14>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	1000                	addi	s0,sp,32
    800002b4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b6:	00012517          	auipc	a0,0x12
    800002ba:	2ba50513          	addi	a0,a0,698 # 80012570 <cons>
    800002be:	153000ef          	jal	80000c10 <acquire>

  switch(c){
    800002c2:	47d5                	li	a5,21
    800002c4:	08f48f63          	beq	s1,a5,80000362 <consoleintr+0xb8>
    800002c8:	0297c563          	blt	a5,s1,800002f2 <consoleintr+0x48>
    800002cc:	47a1                	li	a5,8
    800002ce:	0ef48463          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    800002d2:	47c1                	li	a5,16
    800002d4:	10f49563          	bne	s1,a5,800003de <consoleintr+0x134>
  case C('P'):  // Print process list.
    procdump();
    800002d8:	1a0020ef          	jal	80002478 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002dc:	00012517          	auipc	a0,0x12
    800002e0:	29450513          	addi	a0,a0,660 # 80012570 <cons>
    800002e4:	1c5000ef          	jal	80000ca8 <release>
}
    800002e8:	60e2                	ld	ra,24(sp)
    800002ea:	6442                	ld	s0,16(sp)
    800002ec:	64a2                	ld	s1,8(sp)
    800002ee:	6105                	addi	sp,sp,32
    800002f0:	8082                	ret
  switch(c){
    800002f2:	07f00793          	li	a5,127
    800002f6:	0cf48063          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002fa:	00012717          	auipc	a4,0x12
    800002fe:	27670713          	addi	a4,a4,630 # 80012570 <cons>
    80000302:	0a072783          	lw	a5,160(a4)
    80000306:	09872703          	lw	a4,152(a4)
    8000030a:	9f99                	subw	a5,a5,a4
    8000030c:	07f00713          	li	a4,127
    80000310:	fcf766e3          	bltu	a4,a5,800002dc <consoleintr+0x32>
      c = (c == '\r') ? '\n' : c;
    80000314:	47b5                	li	a5,13
    80000316:	0cf48763          	beq	s1,a5,800003e4 <consoleintr+0x13a>
      consputc(c);
    8000031a:	8526                	mv	a0,s1
    8000031c:	f5dff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000320:	00012797          	auipc	a5,0x12
    80000324:	25078793          	addi	a5,a5,592 # 80012570 <cons>
    80000328:	0a07a683          	lw	a3,160(a5)
    8000032c:	0016871b          	addiw	a4,a3,1
    80000330:	0007061b          	sext.w	a2,a4
    80000334:	0ae7a023          	sw	a4,160(a5)
    80000338:	07f6f693          	andi	a3,a3,127
    8000033c:	97b6                	add	a5,a5,a3
    8000033e:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000342:	47a9                	li	a5,10
    80000344:	0cf48563          	beq	s1,a5,8000040e <consoleintr+0x164>
    80000348:	4791                	li	a5,4
    8000034a:	0cf48263          	beq	s1,a5,8000040e <consoleintr+0x164>
    8000034e:	00012797          	auipc	a5,0x12
    80000352:	2ba7a783          	lw	a5,698(a5) # 80012608 <cons+0x98>
    80000356:	9f1d                	subw	a4,a4,a5
    80000358:	08000793          	li	a5,128
    8000035c:	f8f710e3          	bne	a4,a5,800002dc <consoleintr+0x32>
    80000360:	a07d                	j	8000040e <consoleintr+0x164>
    80000362:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    80000364:	00012717          	auipc	a4,0x12
    80000368:	20c70713          	addi	a4,a4,524 # 80012570 <cons>
    8000036c:	0a072783          	lw	a5,160(a4)
    80000370:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000374:	00012497          	auipc	s1,0x12
    80000378:	1fc48493          	addi	s1,s1,508 # 80012570 <cons>
    while(cons.e != cons.w &&
    8000037c:	4929                	li	s2,10
    8000037e:	02f70863          	beq	a4,a5,800003ae <consoleintr+0x104>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000382:	37fd                	addiw	a5,a5,-1
    80000384:	07f7f713          	andi	a4,a5,127
    80000388:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000038a:	01874703          	lbu	a4,24(a4)
    8000038e:	03270263          	beq	a4,s2,800003b2 <consoleintr+0x108>
      cons.e--;
    80000392:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000396:	10000513          	li	a0,256
    8000039a:	edfff0ef          	jal	80000278 <consputc>
    while(cons.e != cons.w &&
    8000039e:	0a04a783          	lw	a5,160(s1)
    800003a2:	09c4a703          	lw	a4,156(s1)
    800003a6:	fcf71ee3          	bne	a4,a5,80000382 <consoleintr+0xd8>
    800003aa:	6902                	ld	s2,0(sp)
    800003ac:	bf05                	j	800002dc <consoleintr+0x32>
    800003ae:	6902                	ld	s2,0(sp)
    800003b0:	b735                	j	800002dc <consoleintr+0x32>
    800003b2:	6902                	ld	s2,0(sp)
    800003b4:	b725                	j	800002dc <consoleintr+0x32>
    if(cons.e != cons.w){
    800003b6:	00012717          	auipc	a4,0x12
    800003ba:	1ba70713          	addi	a4,a4,442 # 80012570 <cons>
    800003be:	0a072783          	lw	a5,160(a4)
    800003c2:	09c72703          	lw	a4,156(a4)
    800003c6:	f0f70be3          	beq	a4,a5,800002dc <consoleintr+0x32>
      cons.e--;
    800003ca:	37fd                	addiw	a5,a5,-1
    800003cc:	00012717          	auipc	a4,0x12
    800003d0:	24f72223          	sw	a5,580(a4) # 80012610 <cons+0xa0>
      consputc(BACKSPACE);
    800003d4:	10000513          	li	a0,256
    800003d8:	ea1ff0ef          	jal	80000278 <consputc>
    800003dc:	b701                	j	800002dc <consoleintr+0x32>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003de:	ee048fe3          	beqz	s1,800002dc <consoleintr+0x32>
    800003e2:	bf21                	j	800002fa <consoleintr+0x50>
      consputc(c);
    800003e4:	4529                	li	a0,10
    800003e6:	e93ff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800003ea:	00012797          	auipc	a5,0x12
    800003ee:	18678793          	addi	a5,a5,390 # 80012570 <cons>
    800003f2:	0a07a703          	lw	a4,160(a5)
    800003f6:	0017069b          	addiw	a3,a4,1
    800003fa:	0006861b          	sext.w	a2,a3
    800003fe:	0ad7a023          	sw	a3,160(a5)
    80000402:	07f77713          	andi	a4,a4,127
    80000406:	97ba                	add	a5,a5,a4
    80000408:	4729                	li	a4,10
    8000040a:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000040e:	00012797          	auipc	a5,0x12
    80000412:	1ec7af23          	sw	a2,510(a5) # 8001260c <cons+0x9c>
        wakeup(&cons.r);
    80000416:	00012517          	auipc	a0,0x12
    8000041a:	1f250513          	addi	a0,a0,498 # 80012608 <cons+0x98>
    8000041e:	3c9010ef          	jal	80001fe6 <wakeup>
    80000422:	bd6d                	j	800002dc <consoleintr+0x32>

0000000080000424 <consoleinit>:

void
consoleinit(void)
{
    80000424:	1141                	addi	sp,sp,-16
    80000426:	e406                	sd	ra,8(sp)
    80000428:	e022                	sd	s0,0(sp)
    8000042a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000042c:	00007597          	auipc	a1,0x7
    80000430:	bd458593          	addi	a1,a1,-1068 # 80007000 <etext>
    80000434:	00012517          	auipc	a0,0x12
    80000438:	13c50513          	addi	a0,a0,316 # 80012570 <cons>
    8000043c:	754000ef          	jal	80000b90 <initlock>

  uartinit();
    80000440:	400000ef          	jal	80000840 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000444:	00023797          	auipc	a5,0x23
    80000448:	49c78793          	addi	a5,a5,1180 # 800238e0 <devsw>
    8000044c:	00000717          	auipc	a4,0x0
    80000450:	d2270713          	addi	a4,a4,-734 # 8000016e <consoleread>
    80000454:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000456:	00000717          	auipc	a4,0x0
    8000045a:	c7a70713          	addi	a4,a4,-902 # 800000d0 <consolewrite>
    8000045e:	ef98                	sd	a4,24(a5)
}
    80000460:	60a2                	ld	ra,8(sp)
    80000462:	6402                	ld	s0,0(sp)
    80000464:	0141                	addi	sp,sp,16
    80000466:	8082                	ret

0000000080000468 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    80000468:	7139                	addi	sp,sp,-64
    8000046a:	fc06                	sd	ra,56(sp)
    8000046c:	f822                	sd	s0,48(sp)
    8000046e:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    80000470:	c219                	beqz	a2,80000476 <printint+0xe>
    80000472:	08054063          	bltz	a0,800004f2 <printint+0x8a>
    x = -xx;
  else
    x = xx;
    80000476:	4881                	li	a7,0
    80000478:	fc840693          	addi	a3,s0,-56

  i = 0;
    8000047c:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    8000047e:	00007617          	auipc	a2,0x7
    80000482:	39a60613          	addi	a2,a2,922 # 80007818 <digits>
    80000486:	883e                	mv	a6,a5
    80000488:	2785                	addiw	a5,a5,1
    8000048a:	02b57733          	remu	a4,a0,a1
    8000048e:	9732                	add	a4,a4,a2
    80000490:	00074703          	lbu	a4,0(a4)
    80000494:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000498:	872a                	mv	a4,a0
    8000049a:	02b55533          	divu	a0,a0,a1
    8000049e:	0685                	addi	a3,a3,1
    800004a0:	feb773e3          	bgeu	a4,a1,80000486 <printint+0x1e>

  if(sign)
    800004a4:	00088a63          	beqz	a7,800004b8 <printint+0x50>
    buf[i++] = '-';
    800004a8:	1781                	addi	a5,a5,-32
    800004aa:	97a2                	add	a5,a5,s0
    800004ac:	02d00713          	li	a4,45
    800004b0:	fee78423          	sb	a4,-24(a5)
    800004b4:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    800004b8:	02f05963          	blez	a5,800004ea <printint+0x82>
    800004bc:	f426                	sd	s1,40(sp)
    800004be:	f04a                	sd	s2,32(sp)
    800004c0:	fc840713          	addi	a4,s0,-56
    800004c4:	00f704b3          	add	s1,a4,a5
    800004c8:	fff70913          	addi	s2,a4,-1
    800004cc:	993e                	add	s2,s2,a5
    800004ce:	37fd                	addiw	a5,a5,-1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    800004d8:	fff4c503          	lbu	a0,-1(s1)
    800004dc:	d9dff0ef          	jal	80000278 <consputc>
  while(--i >= 0)
    800004e0:	14fd                	addi	s1,s1,-1
    800004e2:	ff249be3          	bne	s1,s2,800004d8 <printint+0x70>
    800004e6:	74a2                	ld	s1,40(sp)
    800004e8:	7902                	ld	s2,32(sp)
}
    800004ea:	70e2                	ld	ra,56(sp)
    800004ec:	7442                	ld	s0,48(sp)
    800004ee:	6121                	addi	sp,sp,64
    800004f0:	8082                	ret
    x = -xx;
    800004f2:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800004f6:	4885                	li	a7,1
    x = -xx;
    800004f8:	b741                	j	80000478 <printint+0x10>

00000000800004fa <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004fa:	7131                	addi	sp,sp,-192
    800004fc:	fc86                	sd	ra,120(sp)
    800004fe:	f8a2                	sd	s0,112(sp)
    80000500:	e8d2                	sd	s4,80(sp)
    80000502:	0100                	addi	s0,sp,128
    80000504:	8a2a                	mv	s4,a0
    80000506:	e40c                	sd	a1,8(s0)
    80000508:	e810                	sd	a2,16(s0)
    8000050a:	ec14                	sd	a3,24(s0)
    8000050c:	f018                	sd	a4,32(s0)
    8000050e:	f41c                	sd	a5,40(s0)
    80000510:	03043823          	sd	a6,48(s0)
    80000514:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    80000518:	0000a797          	auipc	a5,0xa
    8000051c:	02c7a783          	lw	a5,44(a5) # 8000a544 <panicking>
    80000520:	c3a1                	beqz	a5,80000560 <printf+0x66>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000522:	00840793          	addi	a5,s0,8
    80000526:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    8000052a:	000a4503          	lbu	a0,0(s4)
    8000052e:	28050763          	beqz	a0,800007bc <printf+0x2c2>
    80000532:	f4a6                	sd	s1,104(sp)
    80000534:	f0ca                	sd	s2,96(sp)
    80000536:	ecce                	sd	s3,88(sp)
    80000538:	e4d6                	sd	s5,72(sp)
    8000053a:	e0da                	sd	s6,64(sp)
    8000053c:	f862                	sd	s8,48(sp)
    8000053e:	f466                	sd	s9,40(sp)
    80000540:	f06a                	sd	s10,32(sp)
    80000542:	ec6e                	sd	s11,24(sp)
    80000544:	4981                	li	s3,0
    if(cx != '%'){
    80000546:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    8000054a:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    8000054e:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    80000552:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000556:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    8000055a:	07000d93          	li	s11,112
    8000055e:	a01d                	j	80000584 <printf+0x8a>
    acquire(&pr.lock);
    80000560:	00012517          	auipc	a0,0x12
    80000564:	0b850513          	addi	a0,a0,184 # 80012618 <pr>
    80000568:	6a8000ef          	jal	80000c10 <acquire>
    8000056c:	bf5d                	j	80000522 <printf+0x28>
      consputc(cx);
    8000056e:	d0bff0ef          	jal	80000278 <consputc>
      continue;
    80000572:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000574:	0014899b          	addiw	s3,s1,1
    80000578:	013a07b3          	add	a5,s4,s3
    8000057c:	0007c503          	lbu	a0,0(a5)
    80000580:	20050b63          	beqz	a0,80000796 <printf+0x29c>
    if(cx != '%'){
    80000584:	ff5515e3          	bne	a0,s5,8000056e <printf+0x74>
    i++;
    80000588:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    8000058c:	009a07b3          	add	a5,s4,s1
    80000590:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000594:	20090b63          	beqz	s2,800007aa <printf+0x2b0>
    80000598:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    8000059c:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    8000059e:	c789                	beqz	a5,800005a8 <printf+0xae>
    800005a0:	009a0733          	add	a4,s4,s1
    800005a4:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    800005a8:	03690963          	beq	s2,s6,800005da <printf+0xe0>
    } else if(c0 == 'l' && c1 == 'd'){
    800005ac:	05890363          	beq	s2,s8,800005f2 <printf+0xf8>
    } else if(c0 == 'u'){
    800005b0:	0d990663          	beq	s2,s9,8000067c <printf+0x182>
    } else if(c0 == 'x'){
    800005b4:	11a90d63          	beq	s2,s10,800006ce <printf+0x1d4>
    } else if(c0 == 'p'){
    800005b8:	15b90663          	beq	s2,s11,80000704 <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    800005bc:	06300793          	li	a5,99
    800005c0:	18f90563          	beq	s2,a5,8000074a <printf+0x250>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    800005c4:	07300793          	li	a5,115
    800005c8:	18f90b63          	beq	s2,a5,8000075e <printf+0x264>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800005cc:	03591b63          	bne	s2,s5,80000602 <printf+0x108>
      consputc('%');
    800005d0:	02500513          	li	a0,37
    800005d4:	ca5ff0ef          	jal	80000278 <consputc>
    800005d8:	bf71                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, int), 10, 1);
    800005da:	f8843783          	ld	a5,-120(s0)
    800005de:	00878713          	addi	a4,a5,8
    800005e2:	f8e43423          	sd	a4,-120(s0)
    800005e6:	4605                	li	a2,1
    800005e8:	45a9                	li	a1,10
    800005ea:	4388                	lw	a0,0(a5)
    800005ec:	e7dff0ef          	jal	80000468 <printint>
    800005f0:	b751                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'd'){
    800005f2:	01678f63          	beq	a5,s6,80000610 <printf+0x116>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005f6:	03878b63          	beq	a5,s8,8000062c <printf+0x132>
    } else if(c0 == 'l' && c1 == 'u'){
    800005fa:	09978e63          	beq	a5,s9,80000696 <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'x'){
    800005fe:	0fa78563          	beq	a5,s10,800006e8 <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000602:	8556                	mv	a0,s5
    80000604:	c75ff0ef          	jal	80000278 <consputc>
      consputc(c0);
    80000608:	854a                	mv	a0,s2
    8000060a:	c6fff0ef          	jal	80000278 <consputc>
    8000060e:	b79d                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000610:	f8843783          	ld	a5,-120(s0)
    80000614:	00878713          	addi	a4,a5,8
    80000618:	f8e43423          	sd	a4,-120(s0)
    8000061c:	4605                	li	a2,1
    8000061e:	45a9                	li	a1,10
    80000620:	6388                	ld	a0,0(a5)
    80000622:	e47ff0ef          	jal	80000468 <printint>
      i += 1;
    80000626:	0029849b          	addiw	s1,s3,2
    8000062a:	b7a9                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    8000062c:	06400793          	li	a5,100
    80000630:	02f68863          	beq	a3,a5,80000660 <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000634:	07500793          	li	a5,117
    80000638:	06f68d63          	beq	a3,a5,800006b2 <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000063c:	07800793          	li	a5,120
    80000640:	fcf691e3          	bne	a3,a5,80000602 <printf+0x108>
      printint(va_arg(ap, uint64), 16, 0);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4601                	li	a2,0
    80000652:	45c1                	li	a1,16
    80000654:	6388                	ld	a0,0(a5)
    80000656:	e13ff0ef          	jal	80000468 <printint>
      i += 2;
    8000065a:	0039849b          	addiw	s1,s3,3
    8000065e:	bf19                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000660:	f8843783          	ld	a5,-120(s0)
    80000664:	00878713          	addi	a4,a5,8
    80000668:	f8e43423          	sd	a4,-120(s0)
    8000066c:	4605                	li	a2,1
    8000066e:	45a9                	li	a1,10
    80000670:	6388                	ld	a0,0(a5)
    80000672:	df7ff0ef          	jal	80000468 <printint>
      i += 2;
    80000676:	0039849b          	addiw	s1,s3,3
    8000067a:	bded                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 10, 0);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4601                	li	a2,0
    8000068a:	45a9                	li	a1,10
    8000068c:	0007e503          	lwu	a0,0(a5)
    80000690:	dd9ff0ef          	jal	80000468 <printint>
    80000694:	b5c5                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	4601                	li	a2,0
    800006a4:	45a9                	li	a1,10
    800006a6:	6388                	ld	a0,0(a5)
    800006a8:	dc1ff0ef          	jal	80000468 <printint>
      i += 1;
    800006ac:	0029849b          	addiw	s1,s3,2
    800006b0:	b5d1                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4601                	li	a2,0
    800006c0:	45a9                	li	a1,10
    800006c2:	6388                	ld	a0,0(a5)
    800006c4:	da5ff0ef          	jal	80000468 <printint>
      i += 2;
    800006c8:	0039849b          	addiw	s1,s3,3
    800006cc:	b565                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 16, 0);
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	4601                	li	a2,0
    800006dc:	45c1                	li	a1,16
    800006de:	0007e503          	lwu	a0,0(a5)
    800006e2:	d87ff0ef          	jal	80000468 <printint>
    800006e6:	b579                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 16, 0);
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	4601                	li	a2,0
    800006f6:	45c1                	li	a1,16
    800006f8:	6388                	ld	a0,0(a5)
    800006fa:	d6fff0ef          	jal	80000468 <printint>
      i += 1;
    800006fe:	0029849b          	addiw	s1,s3,2
    80000702:	bd8d                	j	80000574 <printf+0x7a>
    80000704:	fc5e                	sd	s7,56(sp)
      printptr(va_arg(ap, uint64));
    80000706:	f8843783          	ld	a5,-120(s0)
    8000070a:	00878713          	addi	a4,a5,8
    8000070e:	f8e43423          	sd	a4,-120(s0)
    80000712:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000716:	03000513          	li	a0,48
    8000071a:	b5fff0ef          	jal	80000278 <consputc>
  consputc('x');
    8000071e:	07800513          	li	a0,120
    80000722:	b57ff0ef          	jal	80000278 <consputc>
    80000726:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000728:	00007b97          	auipc	s7,0x7
    8000072c:	0f0b8b93          	addi	s7,s7,240 # 80007818 <digits>
    80000730:	03c9d793          	srli	a5,s3,0x3c
    80000734:	97de                	add	a5,a5,s7
    80000736:	0007c503          	lbu	a0,0(a5)
    8000073a:	b3fff0ef          	jal	80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000073e:	0992                	slli	s3,s3,0x4
    80000740:	397d                	addiw	s2,s2,-1
    80000742:	fe0917e3          	bnez	s2,80000730 <printf+0x236>
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	b535                	j	80000574 <printf+0x7a>
      consputc(va_arg(ap, uint));
    8000074a:	f8843783          	ld	a5,-120(s0)
    8000074e:	00878713          	addi	a4,a5,8
    80000752:	f8e43423          	sd	a4,-120(s0)
    80000756:	4388                	lw	a0,0(a5)
    80000758:	b21ff0ef          	jal	80000278 <consputc>
    8000075c:	bd21                	j	80000574 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    8000075e:	f8843783          	ld	a5,-120(s0)
    80000762:	00878713          	addi	a4,a5,8
    80000766:	f8e43423          	sd	a4,-120(s0)
    8000076a:	0007b903          	ld	s2,0(a5)
    8000076e:	00090d63          	beqz	s2,80000788 <printf+0x28e>
      for(; *s; s++)
    80000772:	00094503          	lbu	a0,0(s2)
    80000776:	de050fe3          	beqz	a0,80000574 <printf+0x7a>
        consputc(*s);
    8000077a:	affff0ef          	jal	80000278 <consputc>
      for(; *s; s++)
    8000077e:	0905                	addi	s2,s2,1
    80000780:	00094503          	lbu	a0,0(s2)
    80000784:	f97d                	bnez	a0,8000077a <printf+0x280>
    80000786:	b3fd                	j	80000574 <printf+0x7a>
        s = "(null)";
    80000788:	00007917          	auipc	s2,0x7
    8000078c:	88090913          	addi	s2,s2,-1920 # 80007008 <etext+0x8>
      for(; *s; s++)
    80000790:	02800513          	li	a0,40
    80000794:	b7dd                	j	8000077a <printf+0x280>
    80000796:	74a6                	ld	s1,104(sp)
    80000798:	7906                	ld	s2,96(sp)
    8000079a:	69e6                	ld	s3,88(sp)
    8000079c:	6aa6                	ld	s5,72(sp)
    8000079e:	6b06                	ld	s6,64(sp)
    800007a0:	7c42                	ld	s8,48(sp)
    800007a2:	7ca2                	ld	s9,40(sp)
    800007a4:	7d02                	ld	s10,32(sp)
    800007a6:	6de2                	ld	s11,24(sp)
    800007a8:	a811                	j	800007bc <printf+0x2c2>
    800007aa:	74a6                	ld	s1,104(sp)
    800007ac:	7906                	ld	s2,96(sp)
    800007ae:	69e6                	ld	s3,88(sp)
    800007b0:	6aa6                	ld	s5,72(sp)
    800007b2:	6b06                	ld	s6,64(sp)
    800007b4:	7c42                	ld	s8,48(sp)
    800007b6:	7ca2                	ld	s9,40(sp)
    800007b8:	7d02                	ld	s10,32(sp)
    800007ba:	6de2                	ld	s11,24(sp)
    }

  }
  va_end(ap);

  if(panicking == 0)
    800007bc:	0000a797          	auipc	a5,0xa
    800007c0:	d887a783          	lw	a5,-632(a5) # 8000a544 <panicking>
    800007c4:	c799                	beqz	a5,800007d2 <printf+0x2d8>
    release(&pr.lock);

  return 0;
}
    800007c6:	4501                	li	a0,0
    800007c8:	70e6                	ld	ra,120(sp)
    800007ca:	7446                	ld	s0,112(sp)
    800007cc:	6a46                	ld	s4,80(sp)
    800007ce:	6129                	addi	sp,sp,192
    800007d0:	8082                	ret
    release(&pr.lock);
    800007d2:	00012517          	auipc	a0,0x12
    800007d6:	e4650513          	addi	a0,a0,-442 # 80012618 <pr>
    800007da:	4ce000ef          	jal	80000ca8 <release>
  return 0;
    800007de:	b7e5                	j	800007c6 <printf+0x2cc>

00000000800007e0 <panic>:

void
panic(char *s)
{
    800007e0:	1101                	addi	sp,sp,-32
    800007e2:	ec06                	sd	ra,24(sp)
    800007e4:	e822                	sd	s0,16(sp)
    800007e6:	e426                	sd	s1,8(sp)
    800007e8:	e04a                	sd	s2,0(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  panicking = 1;
    800007ee:	4905                	li	s2,1
    800007f0:	0000a797          	auipc	a5,0xa
    800007f4:	d527aa23          	sw	s2,-684(a5) # 8000a544 <panicking>
  printf("panic: ");
    800007f8:	00007517          	auipc	a0,0x7
    800007fc:	82050513          	addi	a0,a0,-2016 # 80007018 <etext+0x18>
    80000800:	cfbff0ef          	jal	800004fa <printf>
  printf("%s\n", s);
    80000804:	85a6                	mv	a1,s1
    80000806:	00007517          	auipc	a0,0x7
    8000080a:	81a50513          	addi	a0,a0,-2022 # 80007020 <etext+0x20>
    8000080e:	cedff0ef          	jal	800004fa <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000812:	0000a797          	auipc	a5,0xa
    80000816:	d327a723          	sw	s2,-722(a5) # 8000a540 <panicked>
  for(;;)
    8000081a:	a001                	j	8000081a <panic+0x3a>

000000008000081c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000081c:	1141                	addi	sp,sp,-16
    8000081e:	e406                	sd	ra,8(sp)
    80000820:	e022                	sd	s0,0(sp)
    80000822:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    80000824:	00007597          	auipc	a1,0x7
    80000828:	80458593          	addi	a1,a1,-2044 # 80007028 <etext+0x28>
    8000082c:	00012517          	auipc	a0,0x12
    80000830:	dec50513          	addi	a0,a0,-532 # 80012618 <pr>
    80000834:	35c000ef          	jal	80000b90 <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    80000840:	1141                	addi	sp,sp,-16
    80000842:	e406                	sd	ra,8(sp)
    80000844:	e022                	sd	s0,0(sp)
    80000846:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000848:	100007b7          	lui	a5,0x10000
    8000084c:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000850:	10000737          	lui	a4,0x10000
    80000854:	f8000693          	li	a3,-128
    80000858:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000085c:	468d                	li	a3,3
    8000085e:	10000637          	lui	a2,0x10000
    80000862:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000866:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000086a:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000086e:	10000737          	lui	a4,0x10000
    80000872:	461d                	li	a2,7
    80000874:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000878:	00d780a3          	sb	a3,1(a5)

  initlock(&tx_lock, "uart");
    8000087c:	00006597          	auipc	a1,0x6
    80000880:	7b458593          	addi	a1,a1,1972 # 80007030 <etext+0x30>
    80000884:	00012517          	auipc	a0,0x12
    80000888:	dac50513          	addi	a0,a0,-596 # 80012630 <tx_lock>
    8000088c:	304000ef          	jal	80000b90 <initlock>
}
    80000890:	60a2                	ld	ra,8(sp)
    80000892:	6402                	ld	s0,0(sp)
    80000894:	0141                	addi	sp,sp,16
    80000896:	8082                	ret

0000000080000898 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000898:	715d                	addi	sp,sp,-80
    8000089a:	e486                	sd	ra,72(sp)
    8000089c:	e0a2                	sd	s0,64(sp)
    8000089e:	fc26                	sd	s1,56(sp)
    800008a0:	ec56                	sd	s5,24(sp)
    800008a2:	0880                	addi	s0,sp,80
    800008a4:	8aaa                	mv	s5,a0
    800008a6:	84ae                	mv	s1,a1
  acquire(&tx_lock);
    800008a8:	00012517          	auipc	a0,0x12
    800008ac:	d8850513          	addi	a0,a0,-632 # 80012630 <tx_lock>
    800008b0:	360000ef          	jal	80000c10 <acquire>

  int i = 0;
  while(i < n){ 
    800008b4:	06905063          	blez	s1,80000914 <uartwrite+0x7c>
    800008b8:	f84a                	sd	s2,48(sp)
    800008ba:	f44e                	sd	s3,40(sp)
    800008bc:	f052                	sd	s4,32(sp)
    800008be:	e85a                	sd	s6,16(sp)
    800008c0:	e45e                	sd	s7,8(sp)
    800008c2:	8a56                	mv	s4,s5
    800008c4:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    800008c6:	0000a497          	auipc	s1,0xa
    800008ca:	c8648493          	addi	s1,s1,-890 # 8000a54c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    800008ce:	00012997          	auipc	s3,0x12
    800008d2:	d6298993          	addi	s3,s3,-670 # 80012630 <tx_lock>
    800008d6:	0000a917          	auipc	s2,0xa
    800008da:	c7290913          	addi	s2,s2,-910 # 8000a548 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    800008de:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    800008e2:	4b05                	li	s6,1
    800008e4:	a005                	j	80000904 <uartwrite+0x6c>
      sleep(&tx_chan, &tx_lock);
    800008e6:	85ce                	mv	a1,s3
    800008e8:	854a                	mv	a0,s2
    800008ea:	6b0010ef          	jal	80001f9a <sleep>
    while(tx_busy != 0){
    800008ee:	409c                	lw	a5,0(s1)
    800008f0:	fbfd                	bnez	a5,800008e6 <uartwrite+0x4e>
    WriteReg(THR, buf[i]);
    800008f2:	000a4783          	lbu	a5,0(s4)
    800008f6:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    800008fa:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    800008fe:	0a05                	addi	s4,s4,1
    80000900:	015a0563          	beq	s4,s5,8000090a <uartwrite+0x72>
    while(tx_busy != 0){
    80000904:	409c                	lw	a5,0(s1)
    80000906:	f3e5                	bnez	a5,800008e6 <uartwrite+0x4e>
    80000908:	b7ed                	j	800008f2 <uartwrite+0x5a>
    8000090a:	7942                	ld	s2,48(sp)
    8000090c:	79a2                	ld	s3,40(sp)
    8000090e:	7a02                	ld	s4,32(sp)
    80000910:	6b42                	ld	s6,16(sp)
    80000912:	6ba2                	ld	s7,8(sp)
  }

  release(&tx_lock);
    80000914:	00012517          	auipc	a0,0x12
    80000918:	d1c50513          	addi	a0,a0,-740 # 80012630 <tx_lock>
    8000091c:	38c000ef          	jal	80000ca8 <release>
}
    80000920:	60a6                	ld	ra,72(sp)
    80000922:	6406                	ld	s0,64(sp)
    80000924:	74e2                	ld	s1,56(sp)
    80000926:	6ae2                	ld	s5,24(sp)
    80000928:	6161                	addi	sp,sp,80
    8000092a:	8082                	ret

000000008000092c <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000092c:	1101                	addi	sp,sp,-32
    8000092e:	ec06                	sd	ra,24(sp)
    80000930:	e822                	sd	s0,16(sp)
    80000932:	e426                	sd	s1,8(sp)
    80000934:	1000                	addi	s0,sp,32
    80000936:	84aa                	mv	s1,a0
  if(panicking == 0)
    80000938:	0000a797          	auipc	a5,0xa
    8000093c:	c0c7a783          	lw	a5,-1012(a5) # 8000a544 <panicking>
    80000940:	cf95                	beqz	a5,8000097c <uartputc_sync+0x50>
    push_off();

  if(panicked){
    80000942:	0000a797          	auipc	a5,0xa
    80000946:	bfe7a783          	lw	a5,-1026(a5) # 8000a540 <panicked>
    8000094a:	ef85                	bnez	a5,80000982 <uartputc_sync+0x56>
    for(;;)
      ;
  }

  // wait for UART to set Transmit Holding Empty in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000094c:	10000737          	lui	a4,0x10000
    80000950:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000952:	00074783          	lbu	a5,0(a4)
    80000956:	0207f793          	andi	a5,a5,32
    8000095a:	dfe5                	beqz	a5,80000952 <uartputc_sync+0x26>
    ;
  WriteReg(THR, c);
    8000095c:	0ff4f513          	zext.b	a0,s1
    80000960:	100007b7          	lui	a5,0x10000
    80000964:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    80000968:	0000a797          	auipc	a5,0xa
    8000096c:	bdc7a783          	lw	a5,-1060(a5) # 8000a544 <panicking>
    80000970:	cb91                	beqz	a5,80000984 <uartputc_sync+0x58>
    pop_off();
}
    80000972:	60e2                	ld	ra,24(sp)
    80000974:	6442                	ld	s0,16(sp)
    80000976:	64a2                	ld	s1,8(sp)
    80000978:	6105                	addi	sp,sp,32
    8000097a:	8082                	ret
    push_off();
    8000097c:	254000ef          	jal	80000bd0 <push_off>
    80000980:	b7c9                	j	80000942 <uartputc_sync+0x16>
    for(;;)
    80000982:	a001                	j	80000982 <uartputc_sync+0x56>
    pop_off();
    80000984:	2d0000ef          	jal	80000c54 <pop_off>
}
    80000988:	b7ed                	j	80000972 <uartputc_sync+0x46>

000000008000098a <uartgetc>:

// try to read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000098a:	1141                	addi	sp,sp,-16
    8000098c:	e422                	sd	s0,8(sp)
    8000098e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000990:	100007b7          	lui	a5,0x10000
    80000994:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    80000996:	0007c783          	lbu	a5,0(a5)
    8000099a:	8b85                	andi	a5,a5,1
    8000099c:	cb81                	beqz	a5,800009ac <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009a6:	6422                	ld	s0,8(sp)
    800009a8:	0141                	addi	sp,sp,16
    800009aa:	8082                	ret
    return -1;
    800009ac:	557d                	li	a0,-1
    800009ae:	bfe5                	j	800009a6 <uartgetc+0x1c>

00000000800009b0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009b0:	1101                	addi	sp,sp,-32
    800009b2:	ec06                	sd	ra,24(sp)
    800009b4:	e822                	sd	s0,16(sp)
    800009b6:	e426                	sd	s1,8(sp)
    800009b8:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0789                	addi	a5,a5,2 # 10000002 <_entry-0x6ffffffe>
    800009c0:	0007c783          	lbu	a5,0(a5)

  acquire(&tx_lock);
    800009c4:	00012517          	auipc	a0,0x12
    800009c8:	c6c50513          	addi	a0,a0,-916 # 80012630 <tx_lock>
    800009cc:	244000ef          	jal	80000c10 <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    800009d0:	100007b7          	lui	a5,0x10000
    800009d4:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009d6:	0007c783          	lbu	a5,0(a5)
    800009da:	0207f793          	andi	a5,a5,32
    800009de:	eb89                	bnez	a5,800009f0 <uartintr+0x40>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    800009e0:	00012517          	auipc	a0,0x12
    800009e4:	c5050513          	addi	a0,a0,-944 # 80012630 <tx_lock>
    800009e8:	2c0000ef          	jal	80000ca8 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ec:	54fd                	li	s1,-1
    800009ee:	a831                	j	80000a0a <uartintr+0x5a>
    tx_busy = 0;
    800009f0:	0000a797          	auipc	a5,0xa
    800009f4:	b407ae23          	sw	zero,-1188(a5) # 8000a54c <tx_busy>
    wakeup(&tx_chan);
    800009f8:	0000a517          	auipc	a0,0xa
    800009fc:	b5050513          	addi	a0,a0,-1200 # 8000a548 <tx_chan>
    80000a00:	5e6010ef          	jal	80001fe6 <wakeup>
    80000a04:	bff1                	j	800009e0 <uartintr+0x30>
      break;
    consoleintr(c);
    80000a06:	8a5ff0ef          	jal	800002aa <consoleintr>
    int c = uartgetc();
    80000a0a:	f81ff0ef          	jal	8000098a <uartgetc>
    if(c == -1)
    80000a0e:	fe951ce3          	bne	a0,s1,80000a06 <uartintr+0x56>
  }
}
    80000a12:	60e2                	ld	ra,24(sp)
    80000a14:	6442                	ld	s0,16(sp)
    80000a16:	64a2                	ld	s1,8(sp)
    80000a18:	6105                	addi	sp,sp,32
    80000a1a:	8082                	ret

0000000080000a1c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a1c:	1101                	addi	sp,sp,-32
    80000a1e:	ec06                	sd	ra,24(sp)
    80000a20:	e822                	sd	s0,16(sp)
    80000a22:	e426                	sd	s1,8(sp)
    80000a24:	e04a                	sd	s2,0(sp)
    80000a26:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a28:	03451793          	slli	a5,a0,0x34
    80000a2c:	e7a9                	bnez	a5,80000a76 <kfree+0x5a>
    80000a2e:	84aa                	mv	s1,a0
    80000a30:	00024797          	auipc	a5,0x24
    80000a34:	04878793          	addi	a5,a5,72 # 80024a78 <end>
    80000a38:	02f56f63          	bltu	a0,a5,80000a76 <kfree+0x5a>
    80000a3c:	47c5                	li	a5,17
    80000a3e:	07ee                	slli	a5,a5,0x1b
    80000a40:	02f57b63          	bgeu	a0,a5,80000a76 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a44:	6605                	lui	a2,0x1
    80000a46:	4585                	li	a1,1
    80000a48:	29c000ef          	jal	80000ce4 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a4c:	00012917          	auipc	s2,0x12
    80000a50:	bfc90913          	addi	s2,s2,-1028 # 80012648 <kmem>
    80000a54:	854a                	mv	a0,s2
    80000a56:	1ba000ef          	jal	80000c10 <acquire>
  r->next = kmem.freelist;
    80000a5a:	01893783          	ld	a5,24(s2)
    80000a5e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a60:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a64:	854a                	mv	a0,s2
    80000a66:	242000ef          	jal	80000ca8 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6902                	ld	s2,0(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    panic("kfree");
    80000a76:	00006517          	auipc	a0,0x6
    80000a7a:	5c250513          	addi	a0,a0,1474 # 80007038 <etext+0x38>
    80000a7e:	d63ff0ef          	jal	800007e0 <panic>

0000000080000a82 <freerange>:
{
    80000a82:	7179                	addi	sp,sp,-48
    80000a84:	f406                	sd	ra,40(sp)
    80000a86:	f022                	sd	s0,32(sp)
    80000a88:	ec26                	sd	s1,24(sp)
    80000a8a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a8c:	6785                	lui	a5,0x1
    80000a8e:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a92:	00e504b3          	add	s1,a0,a4
    80000a96:	777d                	lui	a4,0xfffff
    80000a98:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	94be                	add	s1,s1,a5
    80000a9c:	0295e263          	bltu	a1,s1,80000ac0 <freerange+0x3e>
    80000aa0:	e84a                	sd	s2,16(sp)
    80000aa2:	e44e                	sd	s3,8(sp)
    80000aa4:	e052                	sd	s4,0(sp)
    80000aa6:	892e                	mv	s2,a1
    kfree(p);
    80000aa8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aaa:	6985                	lui	s3,0x1
    kfree(p);
    80000aac:	01448533          	add	a0,s1,s4
    80000ab0:	f6dff0ef          	jal	80000a1c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab4:	94ce                	add	s1,s1,s3
    80000ab6:	fe997be3          	bgeu	s2,s1,80000aac <freerange+0x2a>
    80000aba:	6942                	ld	s2,16(sp)
    80000abc:	69a2                	ld	s3,8(sp)
    80000abe:	6a02                	ld	s4,0(sp)
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6145                	addi	sp,sp,48
    80000ac8:	8082                	ret

0000000080000aca <kinit>:
{
    80000aca:	1141                	addi	sp,sp,-16
    80000acc:	e406                	sd	ra,8(sp)
    80000ace:	e022                	sd	s0,0(sp)
    80000ad0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad2:	00006597          	auipc	a1,0x6
    80000ad6:	56e58593          	addi	a1,a1,1390 # 80007040 <etext+0x40>
    80000ada:	00012517          	auipc	a0,0x12
    80000ade:	b6e50513          	addi	a0,a0,-1170 # 80012648 <kmem>
    80000ae2:	0ae000ef          	jal	80000b90 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ae6:	45c5                	li	a1,17
    80000ae8:	05ee                	slli	a1,a1,0x1b
    80000aea:	00024517          	auipc	a0,0x24
    80000aee:	f8e50513          	addi	a0,a0,-114 # 80024a78 <end>
    80000af2:	f91ff0ef          	jal	80000a82 <freerange>
}
    80000af6:	60a2                	ld	ra,8(sp)
    80000af8:	6402                	ld	s0,0(sp)
    80000afa:	0141                	addi	sp,sp,16
    80000afc:	8082                	ret

0000000080000afe <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afe:	1101                	addi	sp,sp,-32
    80000b00:	ec06                	sd	ra,24(sp)
    80000b02:	e822                	sd	s0,16(sp)
    80000b04:	e426                	sd	s1,8(sp)
    80000b06:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b08:	00012497          	auipc	s1,0x12
    80000b0c:	b4048493          	addi	s1,s1,-1216 # 80012648 <kmem>
    80000b10:	8526                	mv	a0,s1
    80000b12:	0fe000ef          	jal	80000c10 <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c485                	beqz	s1,80000b40 <kalloc+0x42>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00012517          	auipc	a0,0x12
    80000b20:	b2c50513          	addi	a0,a0,-1236 # 80012648 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	182000ef          	jal	80000ca8 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2a:	6605                	lui	a2,0x1
    80000b2c:	4595                	li	a1,5
    80000b2e:	8526                	mv	a0,s1
    80000b30:	1b4000ef          	jal	80000ce4 <memset>
  return (void*)r;
}
    80000b34:	8526                	mv	a0,s1
    80000b36:	60e2                	ld	ra,24(sp)
    80000b38:	6442                	ld	s0,16(sp)
    80000b3a:	64a2                	ld	s1,8(sp)
    80000b3c:	6105                	addi	sp,sp,32
    80000b3e:	8082                	ret
  release(&kmem.lock);
    80000b40:	00012517          	auipc	a0,0x12
    80000b44:	b0850513          	addi	a0,a0,-1272 # 80012648 <kmem>
    80000b48:	160000ef          	jal	80000ca8 <release>
  if(r)
    80000b4c:	b7e5                	j	80000b34 <kalloc+0x36>

0000000080000b4e <freemem_count>:
// Walk the free list and return the number of free bytes of physical
// memory. Used by sys_sysinfo to expose memory pressure to userspace
// (and through it to the LLM bridge).
uint64
freemem_count(void)
{
    80000b4e:	1101                	addi	sp,sp,-32
    80000b50:	ec06                	sd	ra,24(sp)
    80000b52:	e822                	sd	s0,16(sp)
    80000b54:	e426                	sd	s1,8(sp)
    80000b56:	1000                	addi	s0,sp,32
  struct run *r;
  uint64 n = 0;

  acquire(&kmem.lock);
    80000b58:	00012497          	auipc	s1,0x12
    80000b5c:	af048493          	addi	s1,s1,-1296 # 80012648 <kmem>
    80000b60:	8526                	mv	a0,s1
    80000b62:	0ae000ef          	jal	80000c10 <acquire>
  for(r = kmem.freelist; r; r = r->next)
    80000b66:	6c9c                	ld	a5,24(s1)
    80000b68:	c395                	beqz	a5,80000b8c <freemem_count+0x3e>
  uint64 n = 0;
    80000b6a:	4481                	li	s1,0
    n++;
    80000b6c:	0485                	addi	s1,s1,1
  for(r = kmem.freelist; r; r = r->next)
    80000b6e:	639c                	ld	a5,0(a5)
    80000b70:	fff5                	bnez	a5,80000b6c <freemem_count+0x1e>
  release(&kmem.lock);
    80000b72:	00012517          	auipc	a0,0x12
    80000b76:	ad650513          	addi	a0,a0,-1322 # 80012648 <kmem>
    80000b7a:	12e000ef          	jal	80000ca8 <release>
  return n * PGSIZE;
}
    80000b7e:	00c49513          	slli	a0,s1,0xc
    80000b82:	60e2                	ld	ra,24(sp)
    80000b84:	6442                	ld	s0,16(sp)
    80000b86:	64a2                	ld	s1,8(sp)
    80000b88:	6105                	addi	sp,sp,32
    80000b8a:	8082                	ret
  uint64 n = 0;
    80000b8c:	4481                	li	s1,0
    80000b8e:	b7d5                	j	80000b72 <freemem_count+0x24>

0000000080000b90 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b90:	1141                	addi	sp,sp,-16
    80000b92:	e422                	sd	s0,8(sp)
    80000b94:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b96:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b98:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b9c:	00053823          	sd	zero,16(a0)
}
    80000ba0:	6422                	ld	s0,8(sp)
    80000ba2:	0141                	addi	sp,sp,16
    80000ba4:	8082                	ret

0000000080000ba6 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ba6:	411c                	lw	a5,0(a0)
    80000ba8:	e399                	bnez	a5,80000bae <holding+0x8>
    80000baa:	4501                	li	a0,0
  return r;
}
    80000bac:	8082                	ret
{
    80000bae:	1101                	addi	sp,sp,-32
    80000bb0:	ec06                	sd	ra,24(sp)
    80000bb2:	e822                	sd	s0,16(sp)
    80000bb4:	e426                	sd	s1,8(sp)
    80000bb6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bb8:	6904                	ld	s1,16(a0)
    80000bba:	53b000ef          	jal	800018f4 <mycpu>
    80000bbe:	40a48533          	sub	a0,s1,a0
    80000bc2:	00153513          	seqz	a0,a0
}
    80000bc6:	60e2                	ld	ra,24(sp)
    80000bc8:	6442                	ld	s0,16(sp)
    80000bca:	64a2                	ld	s1,8(sp)
    80000bcc:	6105                	addi	sp,sp,32
    80000bce:	8082                	ret

0000000080000bd0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bda:	100024f3          	csrr	s1,sstatus
    80000bde:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000be2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000be4:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000be8:	50d000ef          	jal	800018f4 <mycpu>
    80000bec:	5d3c                	lw	a5,120(a0)
    80000bee:	cb99                	beqz	a5,80000c04 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf0:	505000ef          	jal	800018f4 <mycpu>
    80000bf4:	5d3c                	lw	a5,120(a0)
    80000bf6:	2785                	addiw	a5,a5,1
    80000bf8:	dd3c                	sw	a5,120(a0)
}
    80000bfa:	60e2                	ld	ra,24(sp)
    80000bfc:	6442                	ld	s0,16(sp)
    80000bfe:	64a2                	ld	s1,8(sp)
    80000c00:	6105                	addi	sp,sp,32
    80000c02:	8082                	ret
    mycpu()->intena = old;
    80000c04:	4f1000ef          	jal	800018f4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	b7cd                	j	80000bf0 <push_off+0x20>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	fb5ff0ef          	jal	80000bd0 <push_off>
  if(holding(lk))
    80000c20:	8526                	mv	a0,s1
    80000c22:	f85ff0ef          	jal	80000ba6 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c26:	4705                	li	a4,1
  if(holding(lk))
    80000c28:	e105                	bnez	a0,80000c48 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2a:	87ba                	mv	a5,a4
    80000c2c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c30:	2781                	sext.w	a5,a5
    80000c32:	ffe5                	bnez	a5,80000c2a <acquire+0x1a>
  __sync_synchronize();
    80000c34:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000c38:	4bd000ef          	jal	800018f4 <mycpu>
    80000c3c:	e888                	sd	a0,16(s1)
}
    80000c3e:	60e2                	ld	ra,24(sp)
    80000c40:	6442                	ld	s0,16(sp)
    80000c42:	64a2                	ld	s1,8(sp)
    80000c44:	6105                	addi	sp,sp,32
    80000c46:	8082                	ret
    panic("acquire");
    80000c48:	00006517          	auipc	a0,0x6
    80000c4c:	40050513          	addi	a0,a0,1024 # 80007048 <etext+0x48>
    80000c50:	b91ff0ef          	jal	800007e0 <panic>

0000000080000c54 <pop_off>:

void
pop_off(void)
{
    80000c54:	1141                	addi	sp,sp,-16
    80000c56:	e406                	sd	ra,8(sp)
    80000c58:	e022                	sd	s0,0(sp)
    80000c5a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c5c:	499000ef          	jal	800018f4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c60:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c64:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c66:	e78d                	bnez	a5,80000c90 <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c68:	5d3c                	lw	a5,120(a0)
    80000c6a:	02f05963          	blez	a5,80000c9c <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000c6e:	37fd                	addiw	a5,a5,-1
    80000c70:	0007871b          	sext.w	a4,a5
    80000c74:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c76:	eb09                	bnez	a4,80000c88 <pop_off+0x34>
    80000c78:	5d7c                	lw	a5,124(a0)
    80000c7a:	c799                	beqz	a5,80000c88 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c80:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c84:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c88:	60a2                	ld	ra,8(sp)
    80000c8a:	6402                	ld	s0,0(sp)
    80000c8c:	0141                	addi	sp,sp,16
    80000c8e:	8082                	ret
    panic("pop_off - interruptible");
    80000c90:	00006517          	auipc	a0,0x6
    80000c94:	3c050513          	addi	a0,a0,960 # 80007050 <etext+0x50>
    80000c98:	b49ff0ef          	jal	800007e0 <panic>
    panic("pop_off");
    80000c9c:	00006517          	auipc	a0,0x6
    80000ca0:	3cc50513          	addi	a0,a0,972 # 80007068 <etext+0x68>
    80000ca4:	b3dff0ef          	jal	800007e0 <panic>

0000000080000ca8 <release>:
{
    80000ca8:	1101                	addi	sp,sp,-32
    80000caa:	ec06                	sd	ra,24(sp)
    80000cac:	e822                	sd	s0,16(sp)
    80000cae:	e426                	sd	s1,8(sp)
    80000cb0:	1000                	addi	s0,sp,32
    80000cb2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cb4:	ef3ff0ef          	jal	80000ba6 <holding>
    80000cb8:	c105                	beqz	a0,80000cd8 <release+0x30>
  lk->cpu = 0;
    80000cba:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cbe:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000cc2:	0310000f          	fence	rw,w
    80000cc6:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000cca:	f8bff0ef          	jal	80000c54 <pop_off>
}
    80000cce:	60e2                	ld	ra,24(sp)
    80000cd0:	6442                	ld	s0,16(sp)
    80000cd2:	64a2                	ld	s1,8(sp)
    80000cd4:	6105                	addi	sp,sp,32
    80000cd6:	8082                	ret
    panic("release");
    80000cd8:	00006517          	auipc	a0,0x6
    80000cdc:	39850513          	addi	a0,a0,920 # 80007070 <etext+0x70>
    80000ce0:	b01ff0ef          	jal	800007e0 <panic>

0000000080000ce4 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce4:	1141                	addi	sp,sp,-16
    80000ce6:	e422                	sd	s0,8(sp)
    80000ce8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cea:	ca19                	beqz	a2,80000d00 <memset+0x1c>
    80000cec:	87aa                	mv	a5,a0
    80000cee:	1602                	slli	a2,a2,0x20
    80000cf0:	9201                	srli	a2,a2,0x20
    80000cf2:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x12>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	c205                	beqz	a2,80000d66 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	02a5e263          	bltu	a1,a0,80000d6c <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d4c:	1602                	slli	a2,a2,0x20
    80000d4e:	9201                	srli	a2,a2,0x20
    80000d50:	00c587b3          	add	a5,a1,a2
{
    80000d54:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d56:	0585                	addi	a1,a1,1
    80000d58:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffda589>
    80000d5a:	fff5c683          	lbu	a3,-1(a1)
    80000d5e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d62:	feb79ae3          	bne	a5,a1,80000d56 <memmove+0x16>

  return dst;
}
    80000d66:	6422                	ld	s0,8(sp)
    80000d68:	0141                	addi	sp,sp,16
    80000d6a:	8082                	ret
  if(s < d && s + n > d){
    80000d6c:	02061693          	slli	a3,a2,0x20
    80000d70:	9281                	srli	a3,a3,0x20
    80000d72:	00d58733          	add	a4,a1,a3
    80000d76:	fce57be3          	bgeu	a0,a4,80000d4c <memmove+0xc>
    d += n;
    80000d7a:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d7c:	fff6079b          	addiw	a5,a2,-1
    80000d80:	1782                	slli	a5,a5,0x20
    80000d82:	9381                	srli	a5,a5,0x20
    80000d84:	fff7c793          	not	a5,a5
    80000d88:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8a:	177d                	addi	a4,a4,-1
    80000d8c:	16fd                	addi	a3,a3,-1
    80000d8e:	00074603          	lbu	a2,0(a4)
    80000d92:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d96:	fef71ae3          	bne	a4,a5,80000d8a <memmove+0x4a>
    80000d9a:	b7f1                	j	80000d66 <memmove+0x26>

0000000080000d9c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e406                	sd	ra,8(sp)
    80000da0:	e022                	sd	s0,0(sp)
    80000da2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da4:	f9dff0ef          	jal	80000d40 <memmove>
}
    80000da8:	60a2                	ld	ra,8(sp)
    80000daa:	6402                	ld	s0,0(sp)
    80000dac:	0141                	addi	sp,sp,16
    80000dae:	8082                	ret

0000000080000db0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db0:	1141                	addi	sp,sp,-16
    80000db2:	e422                	sd	s0,8(sp)
    80000db4:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000db6:	ce11                	beqz	a2,80000dd2 <strncmp+0x22>
    80000db8:	00054783          	lbu	a5,0(a0)
    80000dbc:	cf89                	beqz	a5,80000dd6 <strncmp+0x26>
    80000dbe:	0005c703          	lbu	a4,0(a1)
    80000dc2:	00f71a63          	bne	a4,a5,80000dd6 <strncmp+0x26>
    n--, p++, q++;
    80000dc6:	367d                	addiw	a2,a2,-1
    80000dc8:	0505                	addi	a0,a0,1
    80000dca:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dcc:	f675                	bnez	a2,80000db8 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	a801                	j	80000de0 <strncmp+0x30>
    80000dd2:	4501                	li	a0,0
    80000dd4:	a031                	j	80000de0 <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000dd6:	00054503          	lbu	a0,0(a0)
    80000dda:	0005c783          	lbu	a5,0(a1)
    80000dde:	9d1d                	subw	a0,a0,a5
}
    80000de0:	6422                	ld	s0,8(sp)
    80000de2:	0141                	addi	sp,sp,16
    80000de4:	8082                	ret

0000000080000de6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000de6:	1141                	addi	sp,sp,-16
    80000de8:	e422                	sd	s0,8(sp)
    80000dea:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dec:	87aa                	mv	a5,a0
    80000dee:	86b2                	mv	a3,a2
    80000df0:	367d                	addiw	a2,a2,-1
    80000df2:	02d05563          	blez	a3,80000e1c <strncpy+0x36>
    80000df6:	0785                	addi	a5,a5,1
    80000df8:	0005c703          	lbu	a4,0(a1)
    80000dfc:	fee78fa3          	sb	a4,-1(a5)
    80000e00:	0585                	addi	a1,a1,1
    80000e02:	f775                	bnez	a4,80000dee <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e04:	873e                	mv	a4,a5
    80000e06:	9fb5                	addw	a5,a5,a3
    80000e08:	37fd                	addiw	a5,a5,-1
    80000e0a:	00c05963          	blez	a2,80000e1c <strncpy+0x36>
    *s++ = 0;
    80000e0e:	0705                	addi	a4,a4,1
    80000e10:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e14:	40e786bb          	subw	a3,a5,a4
    80000e18:	fed04be3          	bgtz	a3,80000e0e <strncpy+0x28>
  return os;
}
    80000e1c:	6422                	ld	s0,8(sp)
    80000e1e:	0141                	addi	sp,sp,16
    80000e20:	8082                	ret

0000000080000e22 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e22:	1141                	addi	sp,sp,-16
    80000e24:	e422                	sd	s0,8(sp)
    80000e26:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e28:	02c05363          	blez	a2,80000e4e <safestrcpy+0x2c>
    80000e2c:	fff6069b          	addiw	a3,a2,-1
    80000e30:	1682                	slli	a3,a3,0x20
    80000e32:	9281                	srli	a3,a3,0x20
    80000e34:	96ae                	add	a3,a3,a1
    80000e36:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e38:	00d58963          	beq	a1,a3,80000e4a <safestrcpy+0x28>
    80000e3c:	0585                	addi	a1,a1,1
    80000e3e:	0785                	addi	a5,a5,1
    80000e40:	fff5c703          	lbu	a4,-1(a1)
    80000e44:	fee78fa3          	sb	a4,-1(a5)
    80000e48:	fb65                	bnez	a4,80000e38 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e4a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e4e:	6422                	ld	s0,8(sp)
    80000e50:	0141                	addi	sp,sp,16
    80000e52:	8082                	ret

0000000080000e54 <strlen>:

int
strlen(const char *s)
{
    80000e54:	1141                	addi	sp,sp,-16
    80000e56:	e422                	sd	s0,8(sp)
    80000e58:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e5a:	00054783          	lbu	a5,0(a0)
    80000e5e:	cf91                	beqz	a5,80000e7a <strlen+0x26>
    80000e60:	0505                	addi	a0,a0,1
    80000e62:	87aa                	mv	a5,a0
    80000e64:	86be                	mv	a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	ff65                	bnez	a4,80000e64 <strlen+0x10>
    80000e6e:	40a6853b          	subw	a0,a3,a0
    80000e72:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e74:	6422                	ld	s0,8(sp)
    80000e76:	0141                	addi	sp,sp,16
    80000e78:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e7a:	4501                	li	a0,0
    80000e7c:	bfe5                	j	80000e74 <strlen+0x20>

0000000080000e7e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e7e:	1141                	addi	sp,sp,-16
    80000e80:	e406                	sd	ra,8(sp)
    80000e82:	e022                	sd	s0,0(sp)
    80000e84:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e86:	25f000ef          	jal	800018e4 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e8a:	00009717          	auipc	a4,0x9
    80000e8e:	6c670713          	addi	a4,a4,1734 # 8000a550 <started>
  if(cpuid() == 0){
    80000e92:	c51d                	beqz	a0,80000ec0 <main+0x42>
    while(started == 0)
    80000e94:	431c                	lw	a5,0(a4)
    80000e96:	2781                	sext.w	a5,a5
    80000e98:	dff5                	beqz	a5,80000e94 <main+0x16>
      ;
    __sync_synchronize();
    80000e9a:	0330000f          	fence	rw,rw
    printf("hart %d starting\n", cpuid());
    80000e9e:	247000ef          	jal	800018e4 <cpuid>
    80000ea2:	85aa                	mv	a1,a0
    80000ea4:	00006517          	auipc	a0,0x6
    80000ea8:	1f450513          	addi	a0,a0,500 # 80007098 <etext+0x98>
    80000eac:	e4eff0ef          	jal	800004fa <printf>
    kvminithart();    // turn on paging
    80000eb0:	080000ef          	jal	80000f30 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb4:	6f6010ef          	jal	800025aa <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eb8:	0d1040ef          	jal	80005788 <plicinithart>
  }

  scheduler();        
    80000ebc:	701000ef          	jal	80001dbc <scheduler>
    consoleinit();
    80000ec0:	d64ff0ef          	jal	80000424 <consoleinit>
    printfinit();
    80000ec4:	959ff0ef          	jal	8000081c <printfinit>
    printf("\n");
    80000ec8:	00006517          	auipc	a0,0x6
    80000ecc:	1b050513          	addi	a0,a0,432 # 80007078 <etext+0x78>
    80000ed0:	e2aff0ef          	jal	800004fa <printf>
    printf("xv6 kernel is booting\n");
    80000ed4:	00006517          	auipc	a0,0x6
    80000ed8:	1ac50513          	addi	a0,a0,428 # 80007080 <etext+0x80>
    80000edc:	e1eff0ef          	jal	800004fa <printf>
    printf("\n");
    80000ee0:	00006517          	auipc	a0,0x6
    80000ee4:	19850513          	addi	a0,a0,408 # 80007078 <etext+0x78>
    80000ee8:	e12ff0ef          	jal	800004fa <printf>
    kinit();         // physical page allocator
    80000eec:	bdfff0ef          	jal	80000aca <kinit>
    kvminit();       // create kernel page table
    80000ef0:	2ca000ef          	jal	800011ba <kvminit>
    kvminithart();   // turn on paging
    80000ef4:	03c000ef          	jal	80000f30 <kvminithart>
    procinit();      // process table
    80000ef8:	137000ef          	jal	8000182e <procinit>
    trapinit();      // trap vectors
    80000efc:	68a010ef          	jal	80002586 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f00:	6aa010ef          	jal	800025aa <trapinithart>
    plicinit();      // set up interrupt controller
    80000f04:	06b040ef          	jal	8000576e <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f08:	081040ef          	jal	80005788 <plicinithart>
    binit();         // buffer cache
    80000f0c:	741010ef          	jal	80002e4c <binit>
    iinit();         // inode table
    80000f10:	4c6020ef          	jal	800033d6 <iinit>
    fileinit();      // file table
    80000f14:	3b8030ef          	jal	800042cc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f18:	161040ef          	jal	80005878 <virtio_disk_init>
    userinit();      // first user process
    80000f1c:	4dd000ef          	jal	80001bf8 <userinit>
    __sync_synchronize();
    80000f20:	0330000f          	fence	rw,rw
    started = 1;
    80000f24:	4785                	li	a5,1
    80000f26:	00009717          	auipc	a4,0x9
    80000f2a:	62f72523          	sw	a5,1578(a4) # 8000a550 <started>
    80000f2e:	b779                	j	80000ebc <main+0x3e>

0000000080000f30 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000f30:	1141                	addi	sp,sp,-16
    80000f32:	e422                	sd	s0,8(sp)
    80000f34:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f36:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f3a:	00009797          	auipc	a5,0x9
    80000f3e:	61e7b783          	ld	a5,1566(a5) # 8000a558 <kernel_pagetable>
    80000f42:	83b1                	srli	a5,a5,0xc
    80000f44:	577d                	li	a4,-1
    80000f46:	177e                	slli	a4,a4,0x3f
    80000f48:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f4a:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f4e:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f52:	6422                	ld	s0,8(sp)
    80000f54:	0141                	addi	sp,sp,16
    80000f56:	8082                	ret

0000000080000f58 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f58:	7139                	addi	sp,sp,-64
    80000f5a:	fc06                	sd	ra,56(sp)
    80000f5c:	f822                	sd	s0,48(sp)
    80000f5e:	f426                	sd	s1,40(sp)
    80000f60:	f04a                	sd	s2,32(sp)
    80000f62:	ec4e                	sd	s3,24(sp)
    80000f64:	e852                	sd	s4,16(sp)
    80000f66:	e456                	sd	s5,8(sp)
    80000f68:	e05a                	sd	s6,0(sp)
    80000f6a:	0080                	addi	s0,sp,64
    80000f6c:	84aa                	mv	s1,a0
    80000f6e:	89ae                	mv	s3,a1
    80000f70:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000f72:	57fd                	li	a5,-1
    80000f74:	83e9                	srli	a5,a5,0x1a
    80000f76:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000f78:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000f7a:	02b7fc63          	bgeu	a5,a1,80000fb2 <walk+0x5a>
    panic("walk");
    80000f7e:	00006517          	auipc	a0,0x6
    80000f82:	13250513          	addi	a0,a0,306 # 800070b0 <etext+0xb0>
    80000f86:	85bff0ef          	jal	800007e0 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000f8a:	060a8263          	beqz	s5,80000fee <walk+0x96>
    80000f8e:	b71ff0ef          	jal	80000afe <kalloc>
    80000f92:	84aa                	mv	s1,a0
    80000f94:	c139                	beqz	a0,80000fda <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000f96:	6605                	lui	a2,0x1
    80000f98:	4581                	li	a1,0
    80000f9a:	d4bff0ef          	jal	80000ce4 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000f9e:	00c4d793          	srli	a5,s1,0xc
    80000fa2:	07aa                	slli	a5,a5,0xa
    80000fa4:	0017e793          	ori	a5,a5,1
    80000fa8:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000fac:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffda57f>
    80000fae:	036a0063          	beq	s4,s6,80000fce <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000fb2:	0149d933          	srl	s2,s3,s4
    80000fb6:	1ff97913          	andi	s2,s2,511
    80000fba:	090e                	slli	s2,s2,0x3
    80000fbc:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000fbe:	00093483          	ld	s1,0(s2)
    80000fc2:	0014f793          	andi	a5,s1,1
    80000fc6:	d3f1                	beqz	a5,80000f8a <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000fc8:	80a9                	srli	s1,s1,0xa
    80000fca:	04b2                	slli	s1,s1,0xc
    80000fcc:	b7c5                	j	80000fac <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000fce:	00c9d513          	srli	a0,s3,0xc
    80000fd2:	1ff57513          	andi	a0,a0,511
    80000fd6:	050e                	slli	a0,a0,0x3
    80000fd8:	9526                	add	a0,a0,s1
}
    80000fda:	70e2                	ld	ra,56(sp)
    80000fdc:	7442                	ld	s0,48(sp)
    80000fde:	74a2                	ld	s1,40(sp)
    80000fe0:	7902                	ld	s2,32(sp)
    80000fe2:	69e2                	ld	s3,24(sp)
    80000fe4:	6a42                	ld	s4,16(sp)
    80000fe6:	6aa2                	ld	s5,8(sp)
    80000fe8:	6b02                	ld	s6,0(sp)
    80000fea:	6121                	addi	sp,sp,64
    80000fec:	8082                	ret
        return 0;
    80000fee:	4501                	li	a0,0
    80000ff0:	b7ed                	j	80000fda <walk+0x82>

0000000080000ff2 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000ff2:	57fd                	li	a5,-1
    80000ff4:	83e9                	srli	a5,a5,0x1a
    80000ff6:	00b7f463          	bgeu	a5,a1,80000ffe <walkaddr+0xc>
    return 0;
    80000ffa:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000ffc:	8082                	ret
{
    80000ffe:	1141                	addi	sp,sp,-16
    80001000:	e406                	sd	ra,8(sp)
    80001002:	e022                	sd	s0,0(sp)
    80001004:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001006:	4601                	li	a2,0
    80001008:	f51ff0ef          	jal	80000f58 <walk>
  if(pte == 0)
    8000100c:	c105                	beqz	a0,8000102c <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    8000100e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001010:	0117f693          	andi	a3,a5,17
    80001014:	4745                	li	a4,17
    return 0;
    80001016:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001018:	00e68663          	beq	a3,a4,80001024 <walkaddr+0x32>
}
    8000101c:	60a2                	ld	ra,8(sp)
    8000101e:	6402                	ld	s0,0(sp)
    80001020:	0141                	addi	sp,sp,16
    80001022:	8082                	ret
  pa = PTE2PA(*pte);
    80001024:	83a9                	srli	a5,a5,0xa
    80001026:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000102a:	bfcd                	j	8000101c <walkaddr+0x2a>
    return 0;
    8000102c:	4501                	li	a0,0
    8000102e:	b7fd                	j	8000101c <walkaddr+0x2a>

0000000080001030 <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001030:	715d                	addi	sp,sp,-80
    80001032:	e486                	sd	ra,72(sp)
    80001034:	e0a2                	sd	s0,64(sp)
    80001036:	fc26                	sd	s1,56(sp)
    80001038:	f84a                	sd	s2,48(sp)
    8000103a:	f44e                	sd	s3,40(sp)
    8000103c:	f052                	sd	s4,32(sp)
    8000103e:	ec56                	sd	s5,24(sp)
    80001040:	e85a                	sd	s6,16(sp)
    80001042:	e45e                	sd	s7,8(sp)
    80001044:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001046:	03459793          	slli	a5,a1,0x34
    8000104a:	e7a9                	bnez	a5,80001094 <mappages+0x64>
    8000104c:	8aaa                	mv	s5,a0
    8000104e:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    80001050:	03461793          	slli	a5,a2,0x34
    80001054:	e7b1                	bnez	a5,800010a0 <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    80001056:	ca39                	beqz	a2,800010ac <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    80001058:	77fd                	lui	a5,0xfffff
    8000105a:	963e                	add	a2,a2,a5
    8000105c:	00b609b3          	add	s3,a2,a1
  a = va;
    80001060:	892e                	mv	s2,a1
    80001062:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001066:	6b85                	lui	s7,0x1
    80001068:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    8000106c:	4605                	li	a2,1
    8000106e:	85ca                	mv	a1,s2
    80001070:	8556                	mv	a0,s5
    80001072:	ee7ff0ef          	jal	80000f58 <walk>
    80001076:	c539                	beqz	a0,800010c4 <mappages+0x94>
    if(*pte & PTE_V)
    80001078:	611c                	ld	a5,0(a0)
    8000107a:	8b85                	andi	a5,a5,1
    8000107c:	ef95                	bnez	a5,800010b8 <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000107e:	80b1                	srli	s1,s1,0xc
    80001080:	04aa                	slli	s1,s1,0xa
    80001082:	0164e4b3          	or	s1,s1,s6
    80001086:	0014e493          	ori	s1,s1,1
    8000108a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000108c:	05390863          	beq	s2,s3,800010dc <mappages+0xac>
    a += PGSIZE;
    80001090:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001092:	bfd9                	j	80001068 <mappages+0x38>
    panic("mappages: va not aligned");
    80001094:	00006517          	auipc	a0,0x6
    80001098:	02450513          	addi	a0,a0,36 # 800070b8 <etext+0xb8>
    8000109c:	f44ff0ef          	jal	800007e0 <panic>
    panic("mappages: size not aligned");
    800010a0:	00006517          	auipc	a0,0x6
    800010a4:	03850513          	addi	a0,a0,56 # 800070d8 <etext+0xd8>
    800010a8:	f38ff0ef          	jal	800007e0 <panic>
    panic("mappages: size");
    800010ac:	00006517          	auipc	a0,0x6
    800010b0:	04c50513          	addi	a0,a0,76 # 800070f8 <etext+0xf8>
    800010b4:	f2cff0ef          	jal	800007e0 <panic>
      panic("mappages: remap");
    800010b8:	00006517          	auipc	a0,0x6
    800010bc:	05050513          	addi	a0,a0,80 # 80007108 <etext+0x108>
    800010c0:	f20ff0ef          	jal	800007e0 <panic>
      return -1;
    800010c4:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800010c6:	60a6                	ld	ra,72(sp)
    800010c8:	6406                	ld	s0,64(sp)
    800010ca:	74e2                	ld	s1,56(sp)
    800010cc:	7942                	ld	s2,48(sp)
    800010ce:	79a2                	ld	s3,40(sp)
    800010d0:	7a02                	ld	s4,32(sp)
    800010d2:	6ae2                	ld	s5,24(sp)
    800010d4:	6b42                	ld	s6,16(sp)
    800010d6:	6ba2                	ld	s7,8(sp)
    800010d8:	6161                	addi	sp,sp,80
    800010da:	8082                	ret
  return 0;
    800010dc:	4501                	li	a0,0
    800010de:	b7e5                	j	800010c6 <mappages+0x96>

00000000800010e0 <kvmmap>:
{
    800010e0:	1141                	addi	sp,sp,-16
    800010e2:	e406                	sd	ra,8(sp)
    800010e4:	e022                	sd	s0,0(sp)
    800010e6:	0800                	addi	s0,sp,16
    800010e8:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800010ea:	86b2                	mv	a3,a2
    800010ec:	863e                	mv	a2,a5
    800010ee:	f43ff0ef          	jal	80001030 <mappages>
    800010f2:	e509                	bnez	a0,800010fc <kvmmap+0x1c>
}
    800010f4:	60a2                	ld	ra,8(sp)
    800010f6:	6402                	ld	s0,0(sp)
    800010f8:	0141                	addi	sp,sp,16
    800010fa:	8082                	ret
    panic("kvmmap");
    800010fc:	00006517          	auipc	a0,0x6
    80001100:	01c50513          	addi	a0,a0,28 # 80007118 <etext+0x118>
    80001104:	edcff0ef          	jal	800007e0 <panic>

0000000080001108 <kvmmake>:
{
    80001108:	1101                	addi	sp,sp,-32
    8000110a:	ec06                	sd	ra,24(sp)
    8000110c:	e822                	sd	s0,16(sp)
    8000110e:	e426                	sd	s1,8(sp)
    80001110:	e04a                	sd	s2,0(sp)
    80001112:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001114:	9ebff0ef          	jal	80000afe <kalloc>
    80001118:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000111a:	6605                	lui	a2,0x1
    8000111c:	4581                	li	a1,0
    8000111e:	bc7ff0ef          	jal	80000ce4 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001122:	4719                	li	a4,6
    80001124:	6685                	lui	a3,0x1
    80001126:	10000637          	lui	a2,0x10000
    8000112a:	100005b7          	lui	a1,0x10000
    8000112e:	8526                	mv	a0,s1
    80001130:	fb1ff0ef          	jal	800010e0 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001134:	4719                	li	a4,6
    80001136:	6685                	lui	a3,0x1
    80001138:	10001637          	lui	a2,0x10001
    8000113c:	100015b7          	lui	a1,0x10001
    80001140:	8526                	mv	a0,s1
    80001142:	f9fff0ef          	jal	800010e0 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    80001146:	4719                	li	a4,6
    80001148:	040006b7          	lui	a3,0x4000
    8000114c:	0c000637          	lui	a2,0xc000
    80001150:	0c0005b7          	lui	a1,0xc000
    80001154:	8526                	mv	a0,s1
    80001156:	f8bff0ef          	jal	800010e0 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000115a:	00006917          	auipc	s2,0x6
    8000115e:	ea690913          	addi	s2,s2,-346 # 80007000 <etext>
    80001162:	4729                	li	a4,10
    80001164:	80006697          	auipc	a3,0x80006
    80001168:	e9c68693          	addi	a3,a3,-356 # 7000 <_entry-0x7fff9000>
    8000116c:	4605                	li	a2,1
    8000116e:	067e                	slli	a2,a2,0x1f
    80001170:	85b2                	mv	a1,a2
    80001172:	8526                	mv	a0,s1
    80001174:	f6dff0ef          	jal	800010e0 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001178:	46c5                	li	a3,17
    8000117a:	06ee                	slli	a3,a3,0x1b
    8000117c:	4719                	li	a4,6
    8000117e:	412686b3          	sub	a3,a3,s2
    80001182:	864a                	mv	a2,s2
    80001184:	85ca                	mv	a1,s2
    80001186:	8526                	mv	a0,s1
    80001188:	f59ff0ef          	jal	800010e0 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000118c:	4729                	li	a4,10
    8000118e:	6685                	lui	a3,0x1
    80001190:	00005617          	auipc	a2,0x5
    80001194:	e7060613          	addi	a2,a2,-400 # 80006000 <_trampoline>
    80001198:	040005b7          	lui	a1,0x4000
    8000119c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000119e:	05b2                	slli	a1,a1,0xc
    800011a0:	8526                	mv	a0,s1
    800011a2:	f3fff0ef          	jal	800010e0 <kvmmap>
  proc_mapstacks(kpgtbl);
    800011a6:	8526                	mv	a0,s1
    800011a8:	5ee000ef          	jal	80001796 <proc_mapstacks>
}
    800011ac:	8526                	mv	a0,s1
    800011ae:	60e2                	ld	ra,24(sp)
    800011b0:	6442                	ld	s0,16(sp)
    800011b2:	64a2                	ld	s1,8(sp)
    800011b4:	6902                	ld	s2,0(sp)
    800011b6:	6105                	addi	sp,sp,32
    800011b8:	8082                	ret

00000000800011ba <kvminit>:
{
    800011ba:	1141                	addi	sp,sp,-16
    800011bc:	e406                	sd	ra,8(sp)
    800011be:	e022                	sd	s0,0(sp)
    800011c0:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800011c2:	f47ff0ef          	jal	80001108 <kvmmake>
    800011c6:	00009797          	auipc	a5,0x9
    800011ca:	38a7b923          	sd	a0,914(a5) # 8000a558 <kernel_pagetable>
}
    800011ce:	60a2                	ld	ra,8(sp)
    800011d0:	6402                	ld	s0,0(sp)
    800011d2:	0141                	addi	sp,sp,16
    800011d4:	8082                	ret

00000000800011d6 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800011d6:	1101                	addi	sp,sp,-32
    800011d8:	ec06                	sd	ra,24(sp)
    800011da:	e822                	sd	s0,16(sp)
    800011dc:	e426                	sd	s1,8(sp)
    800011de:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800011e0:	91fff0ef          	jal	80000afe <kalloc>
    800011e4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800011e6:	c509                	beqz	a0,800011f0 <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800011e8:	6605                	lui	a2,0x1
    800011ea:	4581                	li	a1,0
    800011ec:	af9ff0ef          	jal	80000ce4 <memset>
  return pagetable;
}
    800011f0:	8526                	mv	a0,s1
    800011f2:	60e2                	ld	ra,24(sp)
    800011f4:	6442                	ld	s0,16(sp)
    800011f6:	64a2                	ld	s1,8(sp)
    800011f8:	6105                	addi	sp,sp,32
    800011fa:	8082                	ret

00000000800011fc <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800011fc:	7139                	addi	sp,sp,-64
    800011fe:	fc06                	sd	ra,56(sp)
    80001200:	f822                	sd	s0,48(sp)
    80001202:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001204:	03459793          	slli	a5,a1,0x34
    80001208:	e38d                	bnez	a5,8000122a <uvmunmap+0x2e>
    8000120a:	f04a                	sd	s2,32(sp)
    8000120c:	ec4e                	sd	s3,24(sp)
    8000120e:	e852                	sd	s4,16(sp)
    80001210:	e456                	sd	s5,8(sp)
    80001212:	e05a                	sd	s6,0(sp)
    80001214:	8a2a                	mv	s4,a0
    80001216:	892e                	mv	s2,a1
    80001218:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000121a:	0632                	slli	a2,a2,0xc
    8000121c:	00b609b3          	add	s3,a2,a1
    80001220:	6b05                	lui	s6,0x1
    80001222:	0535f963          	bgeu	a1,s3,80001274 <uvmunmap+0x78>
    80001226:	f426                	sd	s1,40(sp)
    80001228:	a015                	j	8000124c <uvmunmap+0x50>
    8000122a:	f426                	sd	s1,40(sp)
    8000122c:	f04a                	sd	s2,32(sp)
    8000122e:	ec4e                	sd	s3,24(sp)
    80001230:	e852                	sd	s4,16(sp)
    80001232:	e456                	sd	s5,8(sp)
    80001234:	e05a                	sd	s6,0(sp)
    panic("uvmunmap: not aligned");
    80001236:	00006517          	auipc	a0,0x6
    8000123a:	eea50513          	addi	a0,a0,-278 # 80007120 <etext+0x120>
    8000123e:	da2ff0ef          	jal	800007e0 <panic>
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    80001242:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001246:	995a                	add	s2,s2,s6
    80001248:	03397563          	bgeu	s2,s3,80001272 <uvmunmap+0x76>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    8000124c:	4601                	li	a2,0
    8000124e:	85ca                	mv	a1,s2
    80001250:	8552                	mv	a0,s4
    80001252:	d07ff0ef          	jal	80000f58 <walk>
    80001256:	84aa                	mv	s1,a0
    80001258:	d57d                	beqz	a0,80001246 <uvmunmap+0x4a>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    8000125a:	611c                	ld	a5,0(a0)
    8000125c:	0017f713          	andi	a4,a5,1
    80001260:	d37d                	beqz	a4,80001246 <uvmunmap+0x4a>
    if(do_free){
    80001262:	fe0a80e3          	beqz	s5,80001242 <uvmunmap+0x46>
      uint64 pa = PTE2PA(*pte);
    80001266:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001268:	00c79513          	slli	a0,a5,0xc
    8000126c:	fb0ff0ef          	jal	80000a1c <kfree>
    80001270:	bfc9                	j	80001242 <uvmunmap+0x46>
    80001272:	74a2                	ld	s1,40(sp)
    80001274:	7902                	ld	s2,32(sp)
    80001276:	69e2                	ld	s3,24(sp)
    80001278:	6a42                	ld	s4,16(sp)
    8000127a:	6aa2                	ld	s5,8(sp)
    8000127c:	6b02                	ld	s6,0(sp)
  }
}
    8000127e:	70e2                	ld	ra,56(sp)
    80001280:	7442                	ld	s0,48(sp)
    80001282:	6121                	addi	sp,sp,64
    80001284:	8082                	ret

0000000080001286 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001286:	1101                	addi	sp,sp,-32
    80001288:	ec06                	sd	ra,24(sp)
    8000128a:	e822                	sd	s0,16(sp)
    8000128c:	e426                	sd	s1,8(sp)
    8000128e:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001290:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001292:	00b67d63          	bgeu	a2,a1,800012ac <uvmdealloc+0x26>
    80001296:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001298:	6785                	lui	a5,0x1
    8000129a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000129c:	00f60733          	add	a4,a2,a5
    800012a0:	76fd                	lui	a3,0xfffff
    800012a2:	8f75                	and	a4,a4,a3
    800012a4:	97ae                	add	a5,a5,a1
    800012a6:	8ff5                	and	a5,a5,a3
    800012a8:	00f76863          	bltu	a4,a5,800012b8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800012ac:	8526                	mv	a0,s1
    800012ae:	60e2                	ld	ra,24(sp)
    800012b0:	6442                	ld	s0,16(sp)
    800012b2:	64a2                	ld	s1,8(sp)
    800012b4:	6105                	addi	sp,sp,32
    800012b6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800012b8:	8f99                	sub	a5,a5,a4
    800012ba:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800012bc:	4685                	li	a3,1
    800012be:	0007861b          	sext.w	a2,a5
    800012c2:	85ba                	mv	a1,a4
    800012c4:	f39ff0ef          	jal	800011fc <uvmunmap>
    800012c8:	b7d5                	j	800012ac <uvmdealloc+0x26>

00000000800012ca <uvmalloc>:
  if(newsz < oldsz)
    800012ca:	08b66f63          	bltu	a2,a1,80001368 <uvmalloc+0x9e>
{
    800012ce:	7139                	addi	sp,sp,-64
    800012d0:	fc06                	sd	ra,56(sp)
    800012d2:	f822                	sd	s0,48(sp)
    800012d4:	ec4e                	sd	s3,24(sp)
    800012d6:	e852                	sd	s4,16(sp)
    800012d8:	e456                	sd	s5,8(sp)
    800012da:	0080                	addi	s0,sp,64
    800012dc:	8aaa                	mv	s5,a0
    800012de:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800012e0:	6785                	lui	a5,0x1
    800012e2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800012e4:	95be                	add	a1,a1,a5
    800012e6:	77fd                	lui	a5,0xfffff
    800012e8:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012ec:	08c9f063          	bgeu	s3,a2,8000136c <uvmalloc+0xa2>
    800012f0:	f426                	sd	s1,40(sp)
    800012f2:	f04a                	sd	s2,32(sp)
    800012f4:	e05a                	sd	s6,0(sp)
    800012f6:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012f8:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800012fc:	803ff0ef          	jal	80000afe <kalloc>
    80001300:	84aa                	mv	s1,a0
    if(mem == 0){
    80001302:	c515                	beqz	a0,8000132e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001304:	6605                	lui	a2,0x1
    80001306:	4581                	li	a1,0
    80001308:	9ddff0ef          	jal	80000ce4 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000130c:	875a                	mv	a4,s6
    8000130e:	86a6                	mv	a3,s1
    80001310:	6605                	lui	a2,0x1
    80001312:	85ca                	mv	a1,s2
    80001314:	8556                	mv	a0,s5
    80001316:	d1bff0ef          	jal	80001030 <mappages>
    8000131a:	e915                	bnez	a0,8000134e <uvmalloc+0x84>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000131c:	6785                	lui	a5,0x1
    8000131e:	993e                	add	s2,s2,a5
    80001320:	fd496ee3          	bltu	s2,s4,800012fc <uvmalloc+0x32>
  return newsz;
    80001324:	8552                	mv	a0,s4
    80001326:	74a2                	ld	s1,40(sp)
    80001328:	7902                	ld	s2,32(sp)
    8000132a:	6b02                	ld	s6,0(sp)
    8000132c:	a811                	j	80001340 <uvmalloc+0x76>
      uvmdealloc(pagetable, a, oldsz);
    8000132e:	864e                	mv	a2,s3
    80001330:	85ca                	mv	a1,s2
    80001332:	8556                	mv	a0,s5
    80001334:	f53ff0ef          	jal	80001286 <uvmdealloc>
      return 0;
    80001338:	4501                	li	a0,0
    8000133a:	74a2                	ld	s1,40(sp)
    8000133c:	7902                	ld	s2,32(sp)
    8000133e:	6b02                	ld	s6,0(sp)
}
    80001340:	70e2                	ld	ra,56(sp)
    80001342:	7442                	ld	s0,48(sp)
    80001344:	69e2                	ld	s3,24(sp)
    80001346:	6a42                	ld	s4,16(sp)
    80001348:	6aa2                	ld	s5,8(sp)
    8000134a:	6121                	addi	sp,sp,64
    8000134c:	8082                	ret
      kfree(mem);
    8000134e:	8526                	mv	a0,s1
    80001350:	eccff0ef          	jal	80000a1c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001354:	864e                	mv	a2,s3
    80001356:	85ca                	mv	a1,s2
    80001358:	8556                	mv	a0,s5
    8000135a:	f2dff0ef          	jal	80001286 <uvmdealloc>
      return 0;
    8000135e:	4501                	li	a0,0
    80001360:	74a2                	ld	s1,40(sp)
    80001362:	7902                	ld	s2,32(sp)
    80001364:	6b02                	ld	s6,0(sp)
    80001366:	bfe9                	j	80001340 <uvmalloc+0x76>
    return oldsz;
    80001368:	852e                	mv	a0,a1
}
    8000136a:	8082                	ret
  return newsz;
    8000136c:	8532                	mv	a0,a2
    8000136e:	bfc9                	j	80001340 <uvmalloc+0x76>

0000000080001370 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
    80001380:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001382:	84aa                	mv	s1,a0
    80001384:	6905                	lui	s2,0x1
    80001386:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001388:	4985                	li	s3,1
    8000138a:	a819                	j	800013a0 <freewalk+0x30>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000138c:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000138e:	00c79513          	slli	a0,a5,0xc
    80001392:	fdfff0ef          	jal	80001370 <freewalk>
      pagetable[i] = 0;
    80001396:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000139a:	04a1                	addi	s1,s1,8
    8000139c:	01248f63          	beq	s1,s2,800013ba <freewalk+0x4a>
    pte_t pte = pagetable[i];
    800013a0:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800013a2:	00f7f713          	andi	a4,a5,15
    800013a6:	ff3703e3          	beq	a4,s3,8000138c <freewalk+0x1c>
    } else if(pte & PTE_V){
    800013aa:	8b85                	andi	a5,a5,1
    800013ac:	d7fd                	beqz	a5,8000139a <freewalk+0x2a>
      panic("freewalk: leaf");
    800013ae:	00006517          	auipc	a0,0x6
    800013b2:	d8a50513          	addi	a0,a0,-630 # 80007138 <etext+0x138>
    800013b6:	c2aff0ef          	jal	800007e0 <panic>
    }
  }
  kfree((void*)pagetable);
    800013ba:	8552                	mv	a0,s4
    800013bc:	e60ff0ef          	jal	80000a1c <kfree>
}
    800013c0:	70a2                	ld	ra,40(sp)
    800013c2:	7402                	ld	s0,32(sp)
    800013c4:	64e2                	ld	s1,24(sp)
    800013c6:	6942                	ld	s2,16(sp)
    800013c8:	69a2                	ld	s3,8(sp)
    800013ca:	6a02                	ld	s4,0(sp)
    800013cc:	6145                	addi	sp,sp,48
    800013ce:	8082                	ret

00000000800013d0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800013d0:	1101                	addi	sp,sp,-32
    800013d2:	ec06                	sd	ra,24(sp)
    800013d4:	e822                	sd	s0,16(sp)
    800013d6:	e426                	sd	s1,8(sp)
    800013d8:	1000                	addi	s0,sp,32
    800013da:	84aa                	mv	s1,a0
  if(sz > 0)
    800013dc:	e989                	bnez	a1,800013ee <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800013de:	8526                	mv	a0,s1
    800013e0:	f91ff0ef          	jal	80001370 <freewalk>
}
    800013e4:	60e2                	ld	ra,24(sp)
    800013e6:	6442                	ld	s0,16(sp)
    800013e8:	64a2                	ld	s1,8(sp)
    800013ea:	6105                	addi	sp,sp,32
    800013ec:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800013ee:	6785                	lui	a5,0x1
    800013f0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013f2:	95be                	add	a1,a1,a5
    800013f4:	4685                	li	a3,1
    800013f6:	00c5d613          	srli	a2,a1,0xc
    800013fa:	4581                	li	a1,0
    800013fc:	e01ff0ef          	jal	800011fc <uvmunmap>
    80001400:	bff9                	j	800013de <uvmfree+0xe>

0000000080001402 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001402:	ce49                	beqz	a2,8000149c <uvmcopy+0x9a>
{
    80001404:	715d                	addi	sp,sp,-80
    80001406:	e486                	sd	ra,72(sp)
    80001408:	e0a2                	sd	s0,64(sp)
    8000140a:	fc26                	sd	s1,56(sp)
    8000140c:	f84a                	sd	s2,48(sp)
    8000140e:	f44e                	sd	s3,40(sp)
    80001410:	f052                	sd	s4,32(sp)
    80001412:	ec56                	sd	s5,24(sp)
    80001414:	e85a                	sd	s6,16(sp)
    80001416:	e45e                	sd	s7,8(sp)
    80001418:	0880                	addi	s0,sp,80
    8000141a:	8aaa                	mv	s5,a0
    8000141c:	8b2e                	mv	s6,a1
    8000141e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001420:	4481                	li	s1,0
    80001422:	a029                	j	8000142c <uvmcopy+0x2a>
    80001424:	6785                	lui	a5,0x1
    80001426:	94be                	add	s1,s1,a5
    80001428:	0544fe63          	bgeu	s1,s4,80001484 <uvmcopy+0x82>
    if((pte = walk(old, i, 0)) == 0)
    8000142c:	4601                	li	a2,0
    8000142e:	85a6                	mv	a1,s1
    80001430:	8556                	mv	a0,s5
    80001432:	b27ff0ef          	jal	80000f58 <walk>
    80001436:	d57d                	beqz	a0,80001424 <uvmcopy+0x22>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    80001438:	6118                	ld	a4,0(a0)
    8000143a:	00177793          	andi	a5,a4,1
    8000143e:	d3fd                	beqz	a5,80001424 <uvmcopy+0x22>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    80001440:	00a75593          	srli	a1,a4,0xa
    80001444:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001448:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    8000144c:	eb2ff0ef          	jal	80000afe <kalloc>
    80001450:	89aa                	mv	s3,a0
    80001452:	c105                	beqz	a0,80001472 <uvmcopy+0x70>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001454:	6605                	lui	a2,0x1
    80001456:	85de                	mv	a1,s7
    80001458:	8e9ff0ef          	jal	80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000145c:	874a                	mv	a4,s2
    8000145e:	86ce                	mv	a3,s3
    80001460:	6605                	lui	a2,0x1
    80001462:	85a6                	mv	a1,s1
    80001464:	855a                	mv	a0,s6
    80001466:	bcbff0ef          	jal	80001030 <mappages>
    8000146a:	dd4d                	beqz	a0,80001424 <uvmcopy+0x22>
      kfree(mem);
    8000146c:	854e                	mv	a0,s3
    8000146e:	daeff0ef          	jal	80000a1c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001472:	4685                	li	a3,1
    80001474:	00c4d613          	srli	a2,s1,0xc
    80001478:	4581                	li	a1,0
    8000147a:	855a                	mv	a0,s6
    8000147c:	d81ff0ef          	jal	800011fc <uvmunmap>
  return -1;
    80001480:	557d                	li	a0,-1
    80001482:	a011                	j	80001486 <uvmcopy+0x84>
  return 0;
    80001484:	4501                	li	a0,0
}
    80001486:	60a6                	ld	ra,72(sp)
    80001488:	6406                	ld	s0,64(sp)
    8000148a:	74e2                	ld	s1,56(sp)
    8000148c:	7942                	ld	s2,48(sp)
    8000148e:	79a2                	ld	s3,40(sp)
    80001490:	7a02                	ld	s4,32(sp)
    80001492:	6ae2                	ld	s5,24(sp)
    80001494:	6b42                	ld	s6,16(sp)
    80001496:	6ba2                	ld	s7,8(sp)
    80001498:	6161                	addi	sp,sp,80
    8000149a:	8082                	ret
  return 0;
    8000149c:	4501                	li	a0,0
}
    8000149e:	8082                	ret

00000000800014a0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800014a0:	1141                	addi	sp,sp,-16
    800014a2:	e406                	sd	ra,8(sp)
    800014a4:	e022                	sd	s0,0(sp)
    800014a6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800014a8:	4601                	li	a2,0
    800014aa:	aafff0ef          	jal	80000f58 <walk>
  if(pte == 0)
    800014ae:	c901                	beqz	a0,800014be <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800014b0:	611c                	ld	a5,0(a0)
    800014b2:	9bbd                	andi	a5,a5,-17
    800014b4:	e11c                	sd	a5,0(a0)
}
    800014b6:	60a2                	ld	ra,8(sp)
    800014b8:	6402                	ld	s0,0(sp)
    800014ba:	0141                	addi	sp,sp,16
    800014bc:	8082                	ret
    panic("uvmclear");
    800014be:	00006517          	auipc	a0,0x6
    800014c2:	c8a50513          	addi	a0,a0,-886 # 80007148 <etext+0x148>
    800014c6:	b1aff0ef          	jal	800007e0 <panic>

00000000800014ca <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800014ca:	c6dd                	beqz	a3,80001578 <copyinstr+0xae>
{
    800014cc:	715d                	addi	sp,sp,-80
    800014ce:	e486                	sd	ra,72(sp)
    800014d0:	e0a2                	sd	s0,64(sp)
    800014d2:	fc26                	sd	s1,56(sp)
    800014d4:	f84a                	sd	s2,48(sp)
    800014d6:	f44e                	sd	s3,40(sp)
    800014d8:	f052                	sd	s4,32(sp)
    800014da:	ec56                	sd	s5,24(sp)
    800014dc:	e85a                	sd	s6,16(sp)
    800014de:	e45e                	sd	s7,8(sp)
    800014e0:	0880                	addi	s0,sp,80
    800014e2:	8a2a                	mv	s4,a0
    800014e4:	8b2e                	mv	s6,a1
    800014e6:	8bb2                	mv	s7,a2
    800014e8:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    800014ea:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800014ec:	6985                	lui	s3,0x1
    800014ee:	a825                	j	80001526 <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800014f0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800014f4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800014f6:	37fd                	addiw	a5,a5,-1
    800014f8:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800014fc:	60a6                	ld	ra,72(sp)
    800014fe:	6406                	ld	s0,64(sp)
    80001500:	74e2                	ld	s1,56(sp)
    80001502:	7942                	ld	s2,48(sp)
    80001504:	79a2                	ld	s3,40(sp)
    80001506:	7a02                	ld	s4,32(sp)
    80001508:	6ae2                	ld	s5,24(sp)
    8000150a:	6b42                	ld	s6,16(sp)
    8000150c:	6ba2                	ld	s7,8(sp)
    8000150e:	6161                	addi	sp,sp,80
    80001510:	8082                	ret
    80001512:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    80001516:	9742                	add	a4,a4,a6
      --max;
    80001518:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    8000151c:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    80001520:	04e58463          	beq	a1,a4,80001568 <copyinstr+0x9e>
{
    80001524:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    80001526:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000152a:	85a6                	mv	a1,s1
    8000152c:	8552                	mv	a0,s4
    8000152e:	ac5ff0ef          	jal	80000ff2 <walkaddr>
    if(pa0 == 0)
    80001532:	cd0d                	beqz	a0,8000156c <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001534:	417486b3          	sub	a3,s1,s7
    80001538:	96ce                	add	a3,a3,s3
    if(n > max)
    8000153a:	00d97363          	bgeu	s2,a3,80001540 <copyinstr+0x76>
    8000153e:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    80001540:	955e                	add	a0,a0,s7
    80001542:	8d05                	sub	a0,a0,s1
    while(n > 0){
    80001544:	c695                	beqz	a3,80001570 <copyinstr+0xa6>
    80001546:	87da                	mv	a5,s6
    80001548:	885a                	mv	a6,s6
      if(*p == '\0'){
    8000154a:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000154e:	96da                	add	a3,a3,s6
    80001550:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001552:	00f60733          	add	a4,a2,a5
    80001556:	00074703          	lbu	a4,0(a4)
    8000155a:	db59                	beqz	a4,800014f0 <copyinstr+0x26>
        *dst = *p;
    8000155c:	00e78023          	sb	a4,0(a5)
      dst++;
    80001560:	0785                	addi	a5,a5,1
    while(n > 0){
    80001562:	fed797e3          	bne	a5,a3,80001550 <copyinstr+0x86>
    80001566:	b775                	j	80001512 <copyinstr+0x48>
    80001568:	4781                	li	a5,0
    8000156a:	b771                	j	800014f6 <copyinstr+0x2c>
      return -1;
    8000156c:	557d                	li	a0,-1
    8000156e:	b779                	j	800014fc <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    80001570:	6b85                	lui	s7,0x1
    80001572:	9ba6                	add	s7,s7,s1
    80001574:	87da                	mv	a5,s6
    80001576:	b77d                	j	80001524 <copyinstr+0x5a>
  int got_null = 0;
    80001578:	4781                	li	a5,0
  if(got_null){
    8000157a:	37fd                	addiw	a5,a5,-1
    8000157c:	0007851b          	sext.w	a0,a5
}
    80001580:	8082                	ret

0000000080001582 <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80001582:	1141                	addi	sp,sp,-16
    80001584:	e406                	sd	ra,8(sp)
    80001586:	e022                	sd	s0,0(sp)
    80001588:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    8000158a:	4601                	li	a2,0
    8000158c:	9cdff0ef          	jal	80000f58 <walk>
  if (pte == 0) {
    80001590:	c519                	beqz	a0,8000159e <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    80001592:	6108                	ld	a0,0(a0)
    80001594:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    80001596:	60a2                	ld	ra,8(sp)
    80001598:	6402                	ld	s0,0(sp)
    8000159a:	0141                	addi	sp,sp,16
    8000159c:	8082                	ret
    return 0;
    8000159e:	4501                	li	a0,0
    800015a0:	bfdd                	j	80001596 <ismapped+0x14>

00000000800015a2 <vmfault>:
{
    800015a2:	7179                	addi	sp,sp,-48
    800015a4:	f406                	sd	ra,40(sp)
    800015a6:	f022                	sd	s0,32(sp)
    800015a8:	ec26                	sd	s1,24(sp)
    800015aa:	e44e                	sd	s3,8(sp)
    800015ac:	1800                	addi	s0,sp,48
    800015ae:	89aa                	mv	s3,a0
    800015b0:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    800015b2:	35e000ef          	jal	80001910 <myproc>
  if (va >= p->sz)
    800015b6:	653c                	ld	a5,72(a0)
    800015b8:	00f4ea63          	bltu	s1,a5,800015cc <vmfault+0x2a>
    return 0;
    800015bc:	4981                	li	s3,0
}
    800015be:	854e                	mv	a0,s3
    800015c0:	70a2                	ld	ra,40(sp)
    800015c2:	7402                	ld	s0,32(sp)
    800015c4:	64e2                	ld	s1,24(sp)
    800015c6:	69a2                	ld	s3,8(sp)
    800015c8:	6145                	addi	sp,sp,48
    800015ca:	8082                	ret
    800015cc:	e84a                	sd	s2,16(sp)
    800015ce:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    800015d0:	77fd                	lui	a5,0xfffff
    800015d2:	8cfd                	and	s1,s1,a5
  if(ismapped(pagetable, va)) {
    800015d4:	85a6                	mv	a1,s1
    800015d6:	854e                	mv	a0,s3
    800015d8:	fabff0ef          	jal	80001582 <ismapped>
    return 0;
    800015dc:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    800015de:	c119                	beqz	a0,800015e4 <vmfault+0x42>
    800015e0:	6942                	ld	s2,16(sp)
    800015e2:	bff1                	j	800015be <vmfault+0x1c>
    800015e4:	e052                	sd	s4,0(sp)
  mem = (uint64) kalloc();
    800015e6:	d18ff0ef          	jal	80000afe <kalloc>
    800015ea:	8a2a                	mv	s4,a0
  if(mem == 0)
    800015ec:	c90d                	beqz	a0,8000161e <vmfault+0x7c>
  mem = (uint64) kalloc();
    800015ee:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800015f0:	6605                	lui	a2,0x1
    800015f2:	4581                	li	a1,0
    800015f4:	ef0ff0ef          	jal	80000ce4 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800015f8:	4759                	li	a4,22
    800015fa:	86d2                	mv	a3,s4
    800015fc:	6605                	lui	a2,0x1
    800015fe:	85a6                	mv	a1,s1
    80001600:	05093503          	ld	a0,80(s2)
    80001604:	a2dff0ef          	jal	80001030 <mappages>
    80001608:	e501                	bnez	a0,80001610 <vmfault+0x6e>
    8000160a:	6942                	ld	s2,16(sp)
    8000160c:	6a02                	ld	s4,0(sp)
    8000160e:	bf45                	j	800015be <vmfault+0x1c>
    kfree((void *)mem);
    80001610:	8552                	mv	a0,s4
    80001612:	c0aff0ef          	jal	80000a1c <kfree>
    return 0;
    80001616:	4981                	li	s3,0
    80001618:	6942                	ld	s2,16(sp)
    8000161a:	6a02                	ld	s4,0(sp)
    8000161c:	b74d                	j	800015be <vmfault+0x1c>
    8000161e:	6942                	ld	s2,16(sp)
    80001620:	6a02                	ld	s4,0(sp)
    80001622:	bf71                	j	800015be <vmfault+0x1c>

0000000080001624 <copyout>:
  while(len > 0){
    80001624:	c2cd                	beqz	a3,800016c6 <copyout+0xa2>
{
    80001626:	711d                	addi	sp,sp,-96
    80001628:	ec86                	sd	ra,88(sp)
    8000162a:	e8a2                	sd	s0,80(sp)
    8000162c:	e4a6                	sd	s1,72(sp)
    8000162e:	f852                	sd	s4,48(sp)
    80001630:	f05a                	sd	s6,32(sp)
    80001632:	ec5e                	sd	s7,24(sp)
    80001634:	e862                	sd	s8,16(sp)
    80001636:	1080                	addi	s0,sp,96
    80001638:	8c2a                	mv	s8,a0
    8000163a:	8b2e                	mv	s6,a1
    8000163c:	8bb2                	mv	s7,a2
    8000163e:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001640:	74fd                	lui	s1,0xfffff
    80001642:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    80001644:	57fd                	li	a5,-1
    80001646:	83e9                	srli	a5,a5,0x1a
    80001648:	0897e163          	bltu	a5,s1,800016ca <copyout+0xa6>
    8000164c:	e0ca                	sd	s2,64(sp)
    8000164e:	fc4e                	sd	s3,56(sp)
    80001650:	f456                	sd	s5,40(sp)
    80001652:	e466                	sd	s9,8(sp)
    80001654:	e06a                	sd	s10,0(sp)
    80001656:	6d05                	lui	s10,0x1
    80001658:	8cbe                	mv	s9,a5
    8000165a:	a015                	j	8000167e <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000165c:	409b0533          	sub	a0,s6,s1
    80001660:	0009861b          	sext.w	a2,s3
    80001664:	85de                	mv	a1,s7
    80001666:	954a                	add	a0,a0,s2
    80001668:	ed8ff0ef          	jal	80000d40 <memmove>
    len -= n;
    8000166c:	413a0a33          	sub	s4,s4,s3
    src += n;
    80001670:	9bce                	add	s7,s7,s3
  while(len > 0){
    80001672:	040a0363          	beqz	s4,800016b8 <copyout+0x94>
    if(va0 >= MAXVA)
    80001676:	055cec63          	bltu	s9,s5,800016ce <copyout+0xaa>
    8000167a:	84d6                	mv	s1,s5
    8000167c:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    8000167e:	85a6                	mv	a1,s1
    80001680:	8562                	mv	a0,s8
    80001682:	971ff0ef          	jal	80000ff2 <walkaddr>
    80001686:	892a                	mv	s2,a0
    if(pa0 == 0) {
    80001688:	e901                	bnez	a0,80001698 <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    8000168a:	4601                	li	a2,0
    8000168c:	85a6                	mv	a1,s1
    8000168e:	8562                	mv	a0,s8
    80001690:	f13ff0ef          	jal	800015a2 <vmfault>
    80001694:	892a                	mv	s2,a0
    80001696:	c139                	beqz	a0,800016dc <copyout+0xb8>
    pte = walk(pagetable, va0, 0);
    80001698:	4601                	li	a2,0
    8000169a:	85a6                	mv	a1,s1
    8000169c:	8562                	mv	a0,s8
    8000169e:	8bbff0ef          	jal	80000f58 <walk>
    if((*pte & PTE_W) == 0)
    800016a2:	611c                	ld	a5,0(a0)
    800016a4:	8b91                	andi	a5,a5,4
    800016a6:	c3b1                	beqz	a5,800016ea <copyout+0xc6>
    n = PGSIZE - (dstva - va0);
    800016a8:	01a48ab3          	add	s5,s1,s10
    800016ac:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    800016b0:	fb3a76e3          	bgeu	s4,s3,8000165c <copyout+0x38>
    800016b4:	89d2                	mv	s3,s4
    800016b6:	b75d                	j	8000165c <copyout+0x38>
  return 0;
    800016b8:	4501                	li	a0,0
    800016ba:	6906                	ld	s2,64(sp)
    800016bc:	79e2                	ld	s3,56(sp)
    800016be:	7aa2                	ld	s5,40(sp)
    800016c0:	6ca2                	ld	s9,8(sp)
    800016c2:	6d02                	ld	s10,0(sp)
    800016c4:	a80d                	j	800016f6 <copyout+0xd2>
    800016c6:	4501                	li	a0,0
}
    800016c8:	8082                	ret
      return -1;
    800016ca:	557d                	li	a0,-1
    800016cc:	a02d                	j	800016f6 <copyout+0xd2>
    800016ce:	557d                	li	a0,-1
    800016d0:	6906                	ld	s2,64(sp)
    800016d2:	79e2                	ld	s3,56(sp)
    800016d4:	7aa2                	ld	s5,40(sp)
    800016d6:	6ca2                	ld	s9,8(sp)
    800016d8:	6d02                	ld	s10,0(sp)
    800016da:	a831                	j	800016f6 <copyout+0xd2>
        return -1;
    800016dc:	557d                	li	a0,-1
    800016de:	6906                	ld	s2,64(sp)
    800016e0:	79e2                	ld	s3,56(sp)
    800016e2:	7aa2                	ld	s5,40(sp)
    800016e4:	6ca2                	ld	s9,8(sp)
    800016e6:	6d02                	ld	s10,0(sp)
    800016e8:	a039                	j	800016f6 <copyout+0xd2>
      return -1;
    800016ea:	557d                	li	a0,-1
    800016ec:	6906                	ld	s2,64(sp)
    800016ee:	79e2                	ld	s3,56(sp)
    800016f0:	7aa2                	ld	s5,40(sp)
    800016f2:	6ca2                	ld	s9,8(sp)
    800016f4:	6d02                	ld	s10,0(sp)
}
    800016f6:	60e6                	ld	ra,88(sp)
    800016f8:	6446                	ld	s0,80(sp)
    800016fa:	64a6                	ld	s1,72(sp)
    800016fc:	7a42                	ld	s4,48(sp)
    800016fe:	7b02                	ld	s6,32(sp)
    80001700:	6be2                	ld	s7,24(sp)
    80001702:	6c42                	ld	s8,16(sp)
    80001704:	6125                	addi	sp,sp,96
    80001706:	8082                	ret

0000000080001708 <copyin>:
  while(len > 0){
    80001708:	c6c9                	beqz	a3,80001792 <copyin+0x8a>
{
    8000170a:	715d                	addi	sp,sp,-80
    8000170c:	e486                	sd	ra,72(sp)
    8000170e:	e0a2                	sd	s0,64(sp)
    80001710:	fc26                	sd	s1,56(sp)
    80001712:	f84a                	sd	s2,48(sp)
    80001714:	f44e                	sd	s3,40(sp)
    80001716:	f052                	sd	s4,32(sp)
    80001718:	ec56                	sd	s5,24(sp)
    8000171a:	e85a                	sd	s6,16(sp)
    8000171c:	e45e                	sd	s7,8(sp)
    8000171e:	e062                	sd	s8,0(sp)
    80001720:	0880                	addi	s0,sp,80
    80001722:	8baa                	mv	s7,a0
    80001724:	8aae                	mv	s5,a1
    80001726:	8932                	mv	s2,a2
    80001728:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    8000172a:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    8000172c:	6b05                	lui	s6,0x1
    8000172e:	a035                	j	8000175a <copyin+0x52>
    80001730:	412984b3          	sub	s1,s3,s2
    80001734:	94da                	add	s1,s1,s6
    if(n > len)
    80001736:	009a7363          	bgeu	s4,s1,8000173c <copyin+0x34>
    8000173a:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000173c:	413905b3          	sub	a1,s2,s3
    80001740:	0004861b          	sext.w	a2,s1
    80001744:	95aa                	add	a1,a1,a0
    80001746:	8556                	mv	a0,s5
    80001748:	df8ff0ef          	jal	80000d40 <memmove>
    len -= n;
    8000174c:	409a0a33          	sub	s4,s4,s1
    dst += n;
    80001750:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001752:	01698933          	add	s2,s3,s6
  while(len > 0){
    80001756:	020a0163          	beqz	s4,80001778 <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ce                	mv	a1,s3
    80001760:	855e                	mv	a0,s7
    80001762:	891ff0ef          	jal	80000ff2 <walkaddr>
    if(pa0 == 0) {
    80001766:	f569                	bnez	a0,80001730 <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001768:	4601                	li	a2,0
    8000176a:	85ce                	mv	a1,s3
    8000176c:	855e                	mv	a0,s7
    8000176e:	e35ff0ef          	jal	800015a2 <vmfault>
    80001772:	fd5d                	bnez	a0,80001730 <copyin+0x28>
        return -1;
    80001774:	557d                	li	a0,-1
    80001776:	a011                	j	8000177a <copyin+0x72>
  return 0;
    80001778:	4501                	li	a0,0
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6c02                	ld	s8,0(sp)
    8000178e:	6161                	addi	sp,sp,80
    80001790:	8082                	ret
  return 0;
    80001792:	4501                	li	a0,0
}
    80001794:	8082                	ret

0000000080001796 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001796:	7139                	addi	sp,sp,-64
    80001798:	fc06                	sd	ra,56(sp)
    8000179a:	f822                	sd	s0,48(sp)
    8000179c:	f426                	sd	s1,40(sp)
    8000179e:	f04a                	sd	s2,32(sp)
    800017a0:	ec4e                	sd	s3,24(sp)
    800017a2:	e852                	sd	s4,16(sp)
    800017a4:	e456                	sd	s5,8(sp)
    800017a6:	e05a                	sd	s6,0(sp)
    800017a8:	0080                	addi	s0,sp,64
    800017aa:	8a2a                	mv	s4,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800017ac:	00011497          	auipc	s1,0x11
    800017b0:	2ec48493          	addi	s1,s1,748 # 80012a98 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800017b4:	8b26                	mv	s6,s1
    800017b6:	faaab937          	lui	s2,0xfaaab
    800017ba:	aab90913          	addi	s2,s2,-1365 # fffffffffaaaaaab <end+0xffffffff7aa86033>
    800017be:	0932                	slli	s2,s2,0xc
    800017c0:	aab90913          	addi	s2,s2,-1365
    800017c4:	0932                	slli	s2,s2,0xc
    800017c6:	aab90913          	addi	s2,s2,-1365
    800017ca:	0932                	slli	s2,s2,0xc
    800017cc:	aab90913          	addi	s2,s2,-1365
    800017d0:	040009b7          	lui	s3,0x4000
    800017d4:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800017d6:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800017d8:	00017a97          	auipc	s5,0x17
    800017dc:	2c0a8a93          	addi	s5,s5,704 # 80018a98 <tickslock>
    char *pa = kalloc();
    800017e0:	b1eff0ef          	jal	80000afe <kalloc>
    800017e4:	862a                	mv	a2,a0
    if(pa == 0)
    800017e6:	cd15                	beqz	a0,80001822 <proc_mapstacks+0x8c>
    uint64 va = KSTACK((int) (p - proc));
    800017e8:	416485b3          	sub	a1,s1,s6
    800017ec:	859d                	srai	a1,a1,0x7
    800017ee:	032585b3          	mul	a1,a1,s2
    800017f2:	2585                	addiw	a1,a1,1
    800017f4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017f8:	4719                	li	a4,6
    800017fa:	6685                	lui	a3,0x1
    800017fc:	40b985b3          	sub	a1,s3,a1
    80001800:	8552                	mv	a0,s4
    80001802:	8dfff0ef          	jal	800010e0 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001806:	18048493          	addi	s1,s1,384
    8000180a:	fd549be3          	bne	s1,s5,800017e0 <proc_mapstacks+0x4a>
  }
}
    8000180e:	70e2                	ld	ra,56(sp)
    80001810:	7442                	ld	s0,48(sp)
    80001812:	74a2                	ld	s1,40(sp)
    80001814:	7902                	ld	s2,32(sp)
    80001816:	69e2                	ld	s3,24(sp)
    80001818:	6a42                	ld	s4,16(sp)
    8000181a:	6aa2                	ld	s5,8(sp)
    8000181c:	6b02                	ld	s6,0(sp)
    8000181e:	6121                	addi	sp,sp,64
    80001820:	8082                	ret
      panic("kalloc");
    80001822:	00006517          	auipc	a0,0x6
    80001826:	93650513          	addi	a0,a0,-1738 # 80007158 <etext+0x158>
    8000182a:	fb7fe0ef          	jal	800007e0 <panic>

000000008000182e <procinit>:

// initialize the proc table.
void
procinit(void)
{
    8000182e:	7139                	addi	sp,sp,-64
    80001830:	fc06                	sd	ra,56(sp)
    80001832:	f822                	sd	s0,48(sp)
    80001834:	f426                	sd	s1,40(sp)
    80001836:	f04a                	sd	s2,32(sp)
    80001838:	ec4e                	sd	s3,24(sp)
    8000183a:	e852                	sd	s4,16(sp)
    8000183c:	e456                	sd	s5,8(sp)
    8000183e:	e05a                	sd	s6,0(sp)
    80001840:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001842:	00006597          	auipc	a1,0x6
    80001846:	91e58593          	addi	a1,a1,-1762 # 80007160 <etext+0x160>
    8000184a:	00011517          	auipc	a0,0x11
    8000184e:	e1e50513          	addi	a0,a0,-482 # 80012668 <pid_lock>
    80001852:	b3eff0ef          	jal	80000b90 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001856:	00006597          	auipc	a1,0x6
    8000185a:	91258593          	addi	a1,a1,-1774 # 80007168 <etext+0x168>
    8000185e:	00011517          	auipc	a0,0x11
    80001862:	e2250513          	addi	a0,a0,-478 # 80012680 <wait_lock>
    80001866:	b2aff0ef          	jal	80000b90 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186a:	00011497          	auipc	s1,0x11
    8000186e:	22e48493          	addi	s1,s1,558 # 80012a98 <proc>
      initlock(&p->lock, "proc");
    80001872:	00006b17          	auipc	s6,0x6
    80001876:	906b0b13          	addi	s6,s6,-1786 # 80007178 <etext+0x178>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000187a:	8aa6                	mv	s5,s1
    8000187c:	faaab937          	lui	s2,0xfaaab
    80001880:	aab90913          	addi	s2,s2,-1365 # fffffffffaaaaaab <end+0xffffffff7aa86033>
    80001884:	0932                	slli	s2,s2,0xc
    80001886:	aab90913          	addi	s2,s2,-1365
    8000188a:	0932                	slli	s2,s2,0xc
    8000188c:	aab90913          	addi	s2,s2,-1365
    80001890:	0932                	slli	s2,s2,0xc
    80001892:	aab90913          	addi	s2,s2,-1365
    80001896:	040009b7          	lui	s3,0x4000
    8000189a:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    8000189c:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000189e:	00017a17          	auipc	s4,0x17
    800018a2:	1faa0a13          	addi	s4,s4,506 # 80018a98 <tickslock>
      initlock(&p->lock, "proc");
    800018a6:	85da                	mv	a1,s6
    800018a8:	8526                	mv	a0,s1
    800018aa:	ae6ff0ef          	jal	80000b90 <initlock>
      p->state = UNUSED;
    800018ae:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800018b2:	415487b3          	sub	a5,s1,s5
    800018b6:	879d                	srai	a5,a5,0x7
    800018b8:	032787b3          	mul	a5,a5,s2
    800018bc:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffda589>
    800018be:	00d7979b          	slliw	a5,a5,0xd
    800018c2:	40f987b3          	sub	a5,s3,a5
    800018c6:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c8:	18048493          	addi	s1,s1,384
    800018cc:	fd449de3          	bne	s1,s4,800018a6 <procinit+0x78>
  }
}
    800018d0:	70e2                	ld	ra,56(sp)
    800018d2:	7442                	ld	s0,48(sp)
    800018d4:	74a2                	ld	s1,40(sp)
    800018d6:	7902                	ld	s2,32(sp)
    800018d8:	69e2                	ld	s3,24(sp)
    800018da:	6a42                	ld	s4,16(sp)
    800018dc:	6aa2                	ld	s5,8(sp)
    800018de:	6b02                	ld	s6,0(sp)
    800018e0:	6121                	addi	sp,sp,64
    800018e2:	8082                	ret

00000000800018e4 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800018e4:	1141                	addi	sp,sp,-16
    800018e6:	e422                	sd	s0,8(sp)
    800018e8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018ea:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018ec:	2501                	sext.w	a0,a0
    800018ee:	6422                	ld	s0,8(sp)
    800018f0:	0141                	addi	sp,sp,16
    800018f2:	8082                	ret

00000000800018f4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800018f4:	1141                	addi	sp,sp,-16
    800018f6:	e422                	sd	s0,8(sp)
    800018f8:	0800                	addi	s0,sp,16
    800018fa:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018fc:	2781                	sext.w	a5,a5
    800018fe:	079e                	slli	a5,a5,0x7
  return c;
}
    80001900:	00011517          	auipc	a0,0x11
    80001904:	d9850513          	addi	a0,a0,-616 # 80012698 <cpus>
    80001908:	953e                	add	a0,a0,a5
    8000190a:	6422                	ld	s0,8(sp)
    8000190c:	0141                	addi	sp,sp,16
    8000190e:	8082                	ret

0000000080001910 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001910:	1101                	addi	sp,sp,-32
    80001912:	ec06                	sd	ra,24(sp)
    80001914:	e822                	sd	s0,16(sp)
    80001916:	e426                	sd	s1,8(sp)
    80001918:	1000                	addi	s0,sp,32
  push_off();
    8000191a:	ab6ff0ef          	jal	80000bd0 <push_off>
    8000191e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001920:	2781                	sext.w	a5,a5
    80001922:	079e                	slli	a5,a5,0x7
    80001924:	00011717          	auipc	a4,0x11
    80001928:	d4470713          	addi	a4,a4,-700 # 80012668 <pid_lock>
    8000192c:	97ba                	add	a5,a5,a4
    8000192e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001930:	b24ff0ef          	jal	80000c54 <pop_off>
  return p;
}
    80001934:	8526                	mv	a0,s1
    80001936:	60e2                	ld	ra,24(sp)
    80001938:	6442                	ld	s0,16(sp)
    8000193a:	64a2                	ld	s1,8(sp)
    8000193c:	6105                	addi	sp,sp,32
    8000193e:	8082                	ret

0000000080001940 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001940:	7179                	addi	sp,sp,-48
    80001942:	f406                	sd	ra,40(sp)
    80001944:	f022                	sd	s0,32(sp)
    80001946:	ec26                	sd	s1,24(sp)
    80001948:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    8000194a:	fc7ff0ef          	jal	80001910 <myproc>
    8000194e:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    80001950:	b58ff0ef          	jal	80000ca8 <release>

  if (first) {
    80001954:	00009797          	auipc	a5,0x9
    80001958:	bbc7a783          	lw	a5,-1092(a5) # 8000a510 <first.1>
    8000195c:	cf8d                	beqz	a5,80001996 <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    8000195e:	4505                	li	a0,1
    80001960:	733010ef          	jal	80003892 <fsinit>

    first = 0;
    80001964:	00009797          	auipc	a5,0x9
    80001968:	ba07a623          	sw	zero,-1108(a5) # 8000a510 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    8000196c:	0330000f          	fence	rw,rw

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    80001970:	00006517          	auipc	a0,0x6
    80001974:	81050513          	addi	a0,a0,-2032 # 80007180 <etext+0x180>
    80001978:	fca43823          	sd	a0,-48(s0)
    8000197c:	fc043c23          	sd	zero,-40(s0)
    80001980:	fd040593          	addi	a1,s0,-48
    80001984:	018030ef          	jal	8000499c <kexec>
    80001988:	6cbc                	ld	a5,88(s1)
    8000198a:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    8000198c:	6cbc                	ld	a5,88(s1)
    8000198e:	7bb8                	ld	a4,112(a5)
    80001990:	57fd                	li	a5,-1
    80001992:	02f70d63          	beq	a4,a5,800019cc <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    80001996:	42d000ef          	jal	800025c2 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    8000199a:	68a8                	ld	a0,80(s1)
    8000199c:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000199e:	04000737          	lui	a4,0x4000
    800019a2:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    800019a4:	0732                	slli	a4,a4,0xc
    800019a6:	00004797          	auipc	a5,0x4
    800019aa:	6f678793          	addi	a5,a5,1782 # 8000609c <userret>
    800019ae:	00004697          	auipc	a3,0x4
    800019b2:	65268693          	addi	a3,a3,1618 # 80006000 <_trampoline>
    800019b6:	8f95                	sub	a5,a5,a3
    800019b8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800019ba:	577d                	li	a4,-1
    800019bc:	177e                	slli	a4,a4,0x3f
    800019be:	8d59                	or	a0,a0,a4
    800019c0:	9782                	jalr	a5
}
    800019c2:	70a2                	ld	ra,40(sp)
    800019c4:	7402                	ld	s0,32(sp)
    800019c6:	64e2                	ld	s1,24(sp)
    800019c8:	6145                	addi	sp,sp,48
    800019ca:	8082                	ret
      panic("exec");
    800019cc:	00005517          	auipc	a0,0x5
    800019d0:	7bc50513          	addi	a0,a0,1980 # 80007188 <etext+0x188>
    800019d4:	e0dfe0ef          	jal	800007e0 <panic>

00000000800019d8 <allocpid>:
{
    800019d8:	1101                	addi	sp,sp,-32
    800019da:	ec06                	sd	ra,24(sp)
    800019dc:	e822                	sd	s0,16(sp)
    800019de:	e426                	sd	s1,8(sp)
    800019e0:	e04a                	sd	s2,0(sp)
    800019e2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800019e4:	00011917          	auipc	s2,0x11
    800019e8:	c8490913          	addi	s2,s2,-892 # 80012668 <pid_lock>
    800019ec:	854a                	mv	a0,s2
    800019ee:	a22ff0ef          	jal	80000c10 <acquire>
  pid = nextpid;
    800019f2:	00009797          	auipc	a5,0x9
    800019f6:	b2278793          	addi	a5,a5,-1246 # 8000a514 <nextpid>
    800019fa:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800019fc:	0014871b          	addiw	a4,s1,1
    80001a00:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a02:	854a                	mv	a0,s2
    80001a04:	aa4ff0ef          	jal	80000ca8 <release>
}
    80001a08:	8526                	mv	a0,s1
    80001a0a:	60e2                	ld	ra,24(sp)
    80001a0c:	6442                	ld	s0,16(sp)
    80001a0e:	64a2                	ld	s1,8(sp)
    80001a10:	6902                	ld	s2,0(sp)
    80001a12:	6105                	addi	sp,sp,32
    80001a14:	8082                	ret

0000000080001a16 <proc_pagetable>:
{
    80001a16:	1101                	addi	sp,sp,-32
    80001a18:	ec06                	sd	ra,24(sp)
    80001a1a:	e822                	sd	s0,16(sp)
    80001a1c:	e426                	sd	s1,8(sp)
    80001a1e:	e04a                	sd	s2,0(sp)
    80001a20:	1000                	addi	s0,sp,32
    80001a22:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a24:	fb2ff0ef          	jal	800011d6 <uvmcreate>
    80001a28:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a2a:	cd05                	beqz	a0,80001a62 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a2c:	4729                	li	a4,10
    80001a2e:	00004697          	auipc	a3,0x4
    80001a32:	5d268693          	addi	a3,a3,1490 # 80006000 <_trampoline>
    80001a36:	6605                	lui	a2,0x1
    80001a38:	040005b7          	lui	a1,0x4000
    80001a3c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a3e:	05b2                	slli	a1,a1,0xc
    80001a40:	df0ff0ef          	jal	80001030 <mappages>
    80001a44:	02054663          	bltz	a0,80001a70 <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a48:	4719                	li	a4,6
    80001a4a:	05893683          	ld	a3,88(s2)
    80001a4e:	6605                	lui	a2,0x1
    80001a50:	020005b7          	lui	a1,0x2000
    80001a54:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a56:	05b6                	slli	a1,a1,0xd
    80001a58:	8526                	mv	a0,s1
    80001a5a:	dd6ff0ef          	jal	80001030 <mappages>
    80001a5e:	00054f63          	bltz	a0,80001a7c <proc_pagetable+0x66>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret
    uvmfree(pagetable, 0);
    80001a70:	4581                	li	a1,0
    80001a72:	8526                	mv	a0,s1
    80001a74:	95dff0ef          	jal	800013d0 <uvmfree>
    return 0;
    80001a78:	4481                	li	s1,0
    80001a7a:	b7e5                	j	80001a62 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a7c:	4681                	li	a3,0
    80001a7e:	4605                	li	a2,1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	8526                	mv	a0,s1
    80001a8a:	f72ff0ef          	jal	800011fc <uvmunmap>
    uvmfree(pagetable, 0);
    80001a8e:	4581                	li	a1,0
    80001a90:	8526                	mv	a0,s1
    80001a92:	93fff0ef          	jal	800013d0 <uvmfree>
    return 0;
    80001a96:	4481                	li	s1,0
    80001a98:	b7e9                	j	80001a62 <proc_pagetable+0x4c>

0000000080001a9a <proc_freepagetable>:
{
    80001a9a:	1101                	addi	sp,sp,-32
    80001a9c:	ec06                	sd	ra,24(sp)
    80001a9e:	e822                	sd	s0,16(sp)
    80001aa0:	e426                	sd	s1,8(sp)
    80001aa2:	e04a                	sd	s2,0(sp)
    80001aa4:	1000                	addi	s0,sp,32
    80001aa6:	84aa                	mv	s1,a0
    80001aa8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aaa:	4681                	li	a3,0
    80001aac:	4605                	li	a2,1
    80001aae:	040005b7          	lui	a1,0x4000
    80001ab2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ab4:	05b2                	slli	a1,a1,0xc
    80001ab6:	f46ff0ef          	jal	800011fc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001aba:	4681                	li	a3,0
    80001abc:	4605                	li	a2,1
    80001abe:	020005b7          	lui	a1,0x2000
    80001ac2:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ac4:	05b6                	slli	a1,a1,0xd
    80001ac6:	8526                	mv	a0,s1
    80001ac8:	f34ff0ef          	jal	800011fc <uvmunmap>
  uvmfree(pagetable, sz);
    80001acc:	85ca                	mv	a1,s2
    80001ace:	8526                	mv	a0,s1
    80001ad0:	901ff0ef          	jal	800013d0 <uvmfree>
}
    80001ad4:	60e2                	ld	ra,24(sp)
    80001ad6:	6442                	ld	s0,16(sp)
    80001ad8:	64a2                	ld	s1,8(sp)
    80001ada:	6902                	ld	s2,0(sp)
    80001adc:	6105                	addi	sp,sp,32
    80001ade:	8082                	ret

0000000080001ae0 <freeproc>:
{
    80001ae0:	1101                	addi	sp,sp,-32
    80001ae2:	ec06                	sd	ra,24(sp)
    80001ae4:	e822                	sd	s0,16(sp)
    80001ae6:	e426                	sd	s1,8(sp)
    80001ae8:	1000                	addi	s0,sp,32
    80001aea:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001aec:	6d28                	ld	a0,88(a0)
    80001aee:	c119                	beqz	a0,80001af4 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001af0:	f2dfe0ef          	jal	80000a1c <kfree>
  p->trapframe = 0;
    80001af4:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001af8:	68a8                	ld	a0,80(s1)
    80001afa:	c501                	beqz	a0,80001b02 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001afc:	64ac                	ld	a1,72(s1)
    80001afe:	f9dff0ef          	jal	80001a9a <proc_freepagetable>
  p->pagetable = 0;
    80001b02:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b06:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b0a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b0e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b12:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b16:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b1a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b1e:	0204a623          	sw	zero,44(s1)
  p->priority = 0;
    80001b22:	1604a423          	sw	zero,360(s1)
  p->trace_mask = 0;
    80001b26:	1604a623          	sw	zero,364(s1)
  p->run_ticks = 0;
    80001b2a:	1604b823          	sd	zero,368(s1)
  p->sleep_ticks = 0;
    80001b2e:	1604bc23          	sd	zero,376(s1)
  p->state = UNUSED;
    80001b32:	0004ac23          	sw	zero,24(s1)
}
    80001b36:	60e2                	ld	ra,24(sp)
    80001b38:	6442                	ld	s0,16(sp)
    80001b3a:	64a2                	ld	s1,8(sp)
    80001b3c:	6105                	addi	sp,sp,32
    80001b3e:	8082                	ret

0000000080001b40 <allocproc>:
{
    80001b40:	1101                	addi	sp,sp,-32
    80001b42:	ec06                	sd	ra,24(sp)
    80001b44:	e822                	sd	s0,16(sp)
    80001b46:	e426                	sd	s1,8(sp)
    80001b48:	e04a                	sd	s2,0(sp)
    80001b4a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b4c:	00011497          	auipc	s1,0x11
    80001b50:	f4c48493          	addi	s1,s1,-180 # 80012a98 <proc>
    80001b54:	00017917          	auipc	s2,0x17
    80001b58:	f4490913          	addi	s2,s2,-188 # 80018a98 <tickslock>
    acquire(&p->lock);
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	8b2ff0ef          	jal	80000c10 <acquire>
    if(p->state == UNUSED) {
    80001b62:	4c9c                	lw	a5,24(s1)
    80001b64:	cb91                	beqz	a5,80001b78 <allocproc+0x38>
      release(&p->lock);
    80001b66:	8526                	mv	a0,s1
    80001b68:	940ff0ef          	jal	80000ca8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b6c:	18048493          	addi	s1,s1,384
    80001b70:	ff2496e3          	bne	s1,s2,80001b5c <allocproc+0x1c>
  return 0;
    80001b74:	4481                	li	s1,0
    80001b76:	a891                	j	80001bca <allocproc+0x8a>
  p->pid = allocpid();
    80001b78:	e61ff0ef          	jal	800019d8 <allocpid>
    80001b7c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001b7e:	4785                	li	a5,1
    80001b80:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001b82:	f7dfe0ef          	jal	80000afe <kalloc>
    80001b86:	892a                	mv	s2,a0
    80001b88:	eca8                	sd	a0,88(s1)
    80001b8a:	c539                	beqz	a0,80001bd8 <allocproc+0x98>
  p->pagetable = proc_pagetable(p);
    80001b8c:	8526                	mv	a0,s1
    80001b8e:	e89ff0ef          	jal	80001a16 <proc_pagetable>
    80001b92:	892a                	mv	s2,a0
    80001b94:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001b96:	c929                	beqz	a0,80001be8 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001b98:	07000613          	li	a2,112
    80001b9c:	4581                	li	a1,0
    80001b9e:	06048513          	addi	a0,s1,96
    80001ba2:	942ff0ef          	jal	80000ce4 <memset>
  p->context.ra = (uint64)forkret;
    80001ba6:	00000797          	auipc	a5,0x0
    80001baa:	d9a78793          	addi	a5,a5,-614 # 80001940 <forkret>
    80001bae:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001bb0:	60bc                	ld	a5,64(s1)
    80001bb2:	6705                	lui	a4,0x1
    80001bb4:	97ba                	add	a5,a5,a4
    80001bb6:	f4bc                	sd	a5,104(s1)
  p->priority = 10;
    80001bb8:	47a9                	li	a5,10
    80001bba:	16f4a423          	sw	a5,360(s1)
  p->trace_mask = 0;
    80001bbe:	1604a623          	sw	zero,364(s1)
  p->run_ticks = 0;
    80001bc2:	1604b823          	sd	zero,368(s1)
  p->sleep_ticks = 0;
    80001bc6:	1604bc23          	sd	zero,376(s1)
}
    80001bca:	8526                	mv	a0,s1
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6902                	ld	s2,0(sp)
    80001bd4:	6105                	addi	sp,sp,32
    80001bd6:	8082                	ret
    freeproc(p);
    80001bd8:	8526                	mv	a0,s1
    80001bda:	f07ff0ef          	jal	80001ae0 <freeproc>
    release(&p->lock);
    80001bde:	8526                	mv	a0,s1
    80001be0:	8c8ff0ef          	jal	80000ca8 <release>
    return 0;
    80001be4:	84ca                	mv	s1,s2
    80001be6:	b7d5                	j	80001bca <allocproc+0x8a>
    freeproc(p);
    80001be8:	8526                	mv	a0,s1
    80001bea:	ef7ff0ef          	jal	80001ae0 <freeproc>
    release(&p->lock);
    80001bee:	8526                	mv	a0,s1
    80001bf0:	8b8ff0ef          	jal	80000ca8 <release>
    return 0;
    80001bf4:	84ca                	mv	s1,s2
    80001bf6:	bfd1                	j	80001bca <allocproc+0x8a>

0000000080001bf8 <userinit>:
{
    80001bf8:	1101                	addi	sp,sp,-32
    80001bfa:	ec06                	sd	ra,24(sp)
    80001bfc:	e822                	sd	s0,16(sp)
    80001bfe:	e426                	sd	s1,8(sp)
    80001c00:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c02:	f3fff0ef          	jal	80001b40 <allocproc>
    80001c06:	84aa                	mv	s1,a0
  initproc = p;
    80001c08:	00009797          	auipc	a5,0x9
    80001c0c:	94a7bc23          	sd	a0,-1704(a5) # 8000a560 <initproc>
  p->cwd = namei("/");
    80001c10:	00005517          	auipc	a0,0x5
    80001c14:	58050513          	addi	a0,a0,1408 # 80007190 <etext+0x190>
    80001c18:	19c020ef          	jal	80003db4 <namei>
    80001c1c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001c20:	478d                	li	a5,3
    80001c22:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001c24:	8526                	mv	a0,s1
    80001c26:	882ff0ef          	jal	80000ca8 <release>
}
    80001c2a:	60e2                	ld	ra,24(sp)
    80001c2c:	6442                	ld	s0,16(sp)
    80001c2e:	64a2                	ld	s1,8(sp)
    80001c30:	6105                	addi	sp,sp,32
    80001c32:	8082                	ret

0000000080001c34 <growproc>:
{
    80001c34:	1101                	addi	sp,sp,-32
    80001c36:	ec06                	sd	ra,24(sp)
    80001c38:	e822                	sd	s0,16(sp)
    80001c3a:	e426                	sd	s1,8(sp)
    80001c3c:	e04a                	sd	s2,0(sp)
    80001c3e:	1000                	addi	s0,sp,32
    80001c40:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001c42:	ccfff0ef          	jal	80001910 <myproc>
    80001c46:	892a                	mv	s2,a0
  sz = p->sz;
    80001c48:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001c4a:	02905963          	blez	s1,80001c7c <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001c4e:	00b48633          	add	a2,s1,a1
    80001c52:	020007b7          	lui	a5,0x2000
    80001c56:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    80001c58:	07b6                	slli	a5,a5,0xd
    80001c5a:	02c7ea63          	bltu	a5,a2,80001c8e <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001c5e:	4691                	li	a3,4
    80001c60:	6928                	ld	a0,80(a0)
    80001c62:	e68ff0ef          	jal	800012ca <uvmalloc>
    80001c66:	85aa                	mv	a1,a0
    80001c68:	c50d                	beqz	a0,80001c92 <growproc+0x5e>
  p->sz = sz;
    80001c6a:	04b93423          	sd	a1,72(s2)
  return 0;
    80001c6e:	4501                	li	a0,0
}
    80001c70:	60e2                	ld	ra,24(sp)
    80001c72:	6442                	ld	s0,16(sp)
    80001c74:	64a2                	ld	s1,8(sp)
    80001c76:	6902                	ld	s2,0(sp)
    80001c78:	6105                	addi	sp,sp,32
    80001c7a:	8082                	ret
  } else if(n < 0){
    80001c7c:	fe04d7e3          	bgez	s1,80001c6a <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001c80:	00b48633          	add	a2,s1,a1
    80001c84:	6928                	ld	a0,80(a0)
    80001c86:	e00ff0ef          	jal	80001286 <uvmdealloc>
    80001c8a:	85aa                	mv	a1,a0
    80001c8c:	bff9                	j	80001c6a <growproc+0x36>
      return -1;
    80001c8e:	557d                	li	a0,-1
    80001c90:	b7c5                	j	80001c70 <growproc+0x3c>
      return -1;
    80001c92:	557d                	li	a0,-1
    80001c94:	bff1                	j	80001c70 <growproc+0x3c>

0000000080001c96 <kfork>:
{
    80001c96:	7139                	addi	sp,sp,-64
    80001c98:	fc06                	sd	ra,56(sp)
    80001c9a:	f822                	sd	s0,48(sp)
    80001c9c:	f04a                	sd	s2,32(sp)
    80001c9e:	e456                	sd	s5,8(sp)
    80001ca0:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001ca2:	c6fff0ef          	jal	80001910 <myproc>
    80001ca6:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001ca8:	e99ff0ef          	jal	80001b40 <allocproc>
    80001cac:	10050663          	beqz	a0,80001db8 <kfork+0x122>
    80001cb0:	ec4e                	sd	s3,24(sp)
    80001cb2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001cb4:	048ab603          	ld	a2,72(s5)
    80001cb8:	692c                	ld	a1,80(a0)
    80001cba:	050ab503          	ld	a0,80(s5)
    80001cbe:	f44ff0ef          	jal	80001402 <uvmcopy>
    80001cc2:	04054a63          	bltz	a0,80001d16 <kfork+0x80>
    80001cc6:	f426                	sd	s1,40(sp)
    80001cc8:	e852                	sd	s4,16(sp)
  np->sz = p->sz;
    80001cca:	048ab783          	ld	a5,72(s5)
    80001cce:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001cd2:	058ab683          	ld	a3,88(s5)
    80001cd6:	87b6                	mv	a5,a3
    80001cd8:	0589b703          	ld	a4,88(s3)
    80001cdc:	12068693          	addi	a3,a3,288
    80001ce0:	0007b803          	ld	a6,0(a5)
    80001ce4:	6788                	ld	a0,8(a5)
    80001ce6:	6b8c                	ld	a1,16(a5)
    80001ce8:	6f90                	ld	a2,24(a5)
    80001cea:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001cee:	e708                	sd	a0,8(a4)
    80001cf0:	eb0c                	sd	a1,16(a4)
    80001cf2:	ef10                	sd	a2,24(a4)
    80001cf4:	02078793          	addi	a5,a5,32
    80001cf8:	02070713          	addi	a4,a4,32
    80001cfc:	fed792e3          	bne	a5,a3,80001ce0 <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001d00:	0589b783          	ld	a5,88(s3)
    80001d04:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001d08:	0d0a8493          	addi	s1,s5,208
    80001d0c:	0d098913          	addi	s2,s3,208
    80001d10:	150a8a13          	addi	s4,s5,336
    80001d14:	a831                	j	80001d30 <kfork+0x9a>
    freeproc(np);
    80001d16:	854e                	mv	a0,s3
    80001d18:	dc9ff0ef          	jal	80001ae0 <freeproc>
    release(&np->lock);
    80001d1c:	854e                	mv	a0,s3
    80001d1e:	f8bfe0ef          	jal	80000ca8 <release>
    return -1;
    80001d22:	597d                	li	s2,-1
    80001d24:	69e2                	ld	s3,24(sp)
    80001d26:	a051                	j	80001daa <kfork+0x114>
  for(i = 0; i < NOFILE; i++)
    80001d28:	04a1                	addi	s1,s1,8
    80001d2a:	0921                	addi	s2,s2,8
    80001d2c:	01448963          	beq	s1,s4,80001d3e <kfork+0xa8>
    if(p->ofile[i])
    80001d30:	6088                	ld	a0,0(s1)
    80001d32:	d97d                	beqz	a0,80001d28 <kfork+0x92>
      np->ofile[i] = filedup(p->ofile[i]);
    80001d34:	61a020ef          	jal	8000434e <filedup>
    80001d38:	00a93023          	sd	a0,0(s2)
    80001d3c:	b7f5                	j	80001d28 <kfork+0x92>
  np->cwd = idup(p->cwd);
    80001d3e:	150ab503          	ld	a0,336(s5)
    80001d42:	027010ef          	jal	80003568 <idup>
    80001d46:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001d4a:	4641                	li	a2,16
    80001d4c:	158a8593          	addi	a1,s5,344
    80001d50:	15898513          	addi	a0,s3,344
    80001d54:	8ceff0ef          	jal	80000e22 <safestrcpy>
  np->priority = p->priority;
    80001d58:	168aa783          	lw	a5,360(s5)
    80001d5c:	16f9a423          	sw	a5,360(s3)
  np->trace_mask = p->trace_mask;
    80001d60:	16caa783          	lw	a5,364(s5)
    80001d64:	16f9a623          	sw	a5,364(s3)
  np->run_ticks = 0;
    80001d68:	1609b823          	sd	zero,368(s3)
  np->sleep_ticks = 0;
    80001d6c:	1609bc23          	sd	zero,376(s3)
  pid = np->pid;
    80001d70:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001d74:	854e                	mv	a0,s3
    80001d76:	f33fe0ef          	jal	80000ca8 <release>
  acquire(&wait_lock);
    80001d7a:	00011497          	auipc	s1,0x11
    80001d7e:	90648493          	addi	s1,s1,-1786 # 80012680 <wait_lock>
    80001d82:	8526                	mv	a0,s1
    80001d84:	e8dfe0ef          	jal	80000c10 <acquire>
  np->parent = p;
    80001d88:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001d8c:	8526                	mv	a0,s1
    80001d8e:	f1bfe0ef          	jal	80000ca8 <release>
  acquire(&np->lock);
    80001d92:	854e                	mv	a0,s3
    80001d94:	e7dfe0ef          	jal	80000c10 <acquire>
  np->state = RUNNABLE;
    80001d98:	478d                	li	a5,3
    80001d9a:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001d9e:	854e                	mv	a0,s3
    80001da0:	f09fe0ef          	jal	80000ca8 <release>
  return pid;
    80001da4:	74a2                	ld	s1,40(sp)
    80001da6:	69e2                	ld	s3,24(sp)
    80001da8:	6a42                	ld	s4,16(sp)
}
    80001daa:	854a                	mv	a0,s2
    80001dac:	70e2                	ld	ra,56(sp)
    80001dae:	7442                	ld	s0,48(sp)
    80001db0:	7902                	ld	s2,32(sp)
    80001db2:	6aa2                	ld	s5,8(sp)
    80001db4:	6121                	addi	sp,sp,64
    80001db6:	8082                	ret
    return -1;
    80001db8:	597d                	li	s2,-1
    80001dba:	bfc5                	j	80001daa <kfork+0x114>

0000000080001dbc <scheduler>:
{
    80001dbc:	715d                	addi	sp,sp,-80
    80001dbe:	e486                	sd	ra,72(sp)
    80001dc0:	e0a2                	sd	s0,64(sp)
    80001dc2:	fc26                	sd	s1,56(sp)
    80001dc4:	f84a                	sd	s2,48(sp)
    80001dc6:	f44e                	sd	s3,40(sp)
    80001dc8:	f052                	sd	s4,32(sp)
    80001dca:	ec56                	sd	s5,24(sp)
    80001dcc:	e85a                	sd	s6,16(sp)
    80001dce:	e45e                	sd	s7,8(sp)
    80001dd0:	e062                	sd	s8,0(sp)
    80001dd2:	0880                	addi	s0,sp,80
    80001dd4:	8792                	mv	a5,tp
  int id = r_tp();
    80001dd6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001dd8:	00779c13          	slli	s8,a5,0x7
    80001ddc:	00011717          	auipc	a4,0x11
    80001de0:	88c70713          	addi	a4,a4,-1908 # 80012668 <pid_lock>
    80001de4:	9762                	add	a4,a4,s8
    80001de6:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &best->context);
    80001dea:	00011717          	auipc	a4,0x11
    80001dee:	8b670713          	addi	a4,a4,-1866 # 800126a0 <cpus+0x8>
    80001df2:	9c3a                	add	s8,s8,a4
    struct proc *best = 0;
    80001df4:	4b81                	li	s7,0
      if(p->state == RUNNABLE) {
    80001df6:	4a0d                	li	s4,3
        if(p->state == SLEEPING)
    80001df8:	4a89                	li	s5,2
    for(p = proc; p < &proc[NPROC]; p++) {
    80001dfa:	00017997          	auipc	s3,0x17
    80001dfe:	c9e98993          	addi	s3,s3,-866 # 80018a98 <tickslock>
      c->proc = best;
    80001e02:	079e                	slli	a5,a5,0x7
    80001e04:	00011b17          	auipc	s6,0x11
    80001e08:	864b0b13          	addi	s6,s6,-1948 # 80012668 <pid_lock>
    80001e0c:	9b3e                	add	s6,s6,a5
    80001e0e:	a8bd                	j	80001e8c <scheduler+0xd0>
        if(best == 0 || p->priority < best->priority) {
    80001e10:	04090663          	beqz	s2,80001e5c <scheduler+0xa0>
    80001e14:	1684a703          	lw	a4,360(s1)
    80001e18:	16892783          	lw	a5,360(s2)
    80001e1c:	00f75763          	bge	a4,a5,80001e2a <scheduler+0x6e>
            release(&best->lock);
    80001e20:	854a                	mv	a0,s2
    80001e22:	e87fe0ef          	jal	80000ca8 <release>
          best = p;
    80001e26:	8926                	mv	s2,s1
    80001e28:	a801                	j	80001e38 <scheduler+0x7c>
          release(&p->lock);
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	e7dfe0ef          	jal	80000ca8 <release>
    80001e30:	a021                	j	80001e38 <scheduler+0x7c>
        release(&p->lock);
    80001e32:	8526                	mv	a0,s1
    80001e34:	e75fe0ef          	jal	80000ca8 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e38:	18048493          	addi	s1,s1,384
    80001e3c:	03348263          	beq	s1,s3,80001e60 <scheduler+0xa4>
      acquire(&p->lock);
    80001e40:	8526                	mv	a0,s1
    80001e42:	dcffe0ef          	jal	80000c10 <acquire>
      if(p->state == RUNNABLE) {
    80001e46:	4c9c                	lw	a5,24(s1)
    80001e48:	fd4784e3          	beq	a5,s4,80001e10 <scheduler+0x54>
        if(p->state == SLEEPING)
    80001e4c:	ff5793e3          	bne	a5,s5,80001e32 <scheduler+0x76>
          p->sleep_ticks++;
    80001e50:	1784b783          	ld	a5,376(s1)
    80001e54:	0785                	addi	a5,a5,1
    80001e56:	16f4bc23          	sd	a5,376(s1)
    80001e5a:	bfe1                	j	80001e32 <scheduler+0x76>
          best = p;
    80001e5c:	8926                	mv	s2,s1
    80001e5e:	bfe9                	j	80001e38 <scheduler+0x7c>
    if(best != 0) {
    80001e60:	04090763          	beqz	s2,80001eae <scheduler+0xf2>
      best->state = RUNNING;
    80001e64:	4791                	li	a5,4
    80001e66:	00f92c23          	sw	a5,24(s2)
      best->run_ticks++;
    80001e6a:	17093783          	ld	a5,368(s2)
    80001e6e:	0785                	addi	a5,a5,1
    80001e70:	16f93823          	sd	a5,368(s2)
      c->proc = best;
    80001e74:	032b3823          	sd	s2,48(s6)
      swtch(&c->context, &best->context);
    80001e78:	06090593          	addi	a1,s2,96
    80001e7c:	8562                	mv	a0,s8
    80001e7e:	69e000ef          	jal	8000251c <swtch>
      c->proc = 0;
    80001e82:	020b3823          	sd	zero,48(s6)
      release(&best->lock);
    80001e86:	854a                	mv	a0,s2
    80001e88:	e21fe0ef          	jal	80000ca8 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e90:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e94:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001e9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e9e:	10079073          	csrw	sstatus,a5
    struct proc *best = 0;
    80001ea2:	895e                	mv	s2,s7
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ea4:	00011497          	auipc	s1,0x11
    80001ea8:	bf448493          	addi	s1,s1,-1036 # 80012a98 <proc>
    80001eac:	bf51                	j	80001e40 <scheduler+0x84>
      asm volatile("wfi");
    80001eae:	10500073          	wfi
    80001eb2:	bfe9                	j	80001e8c <scheduler+0xd0>

0000000080001eb4 <sched>:
{
    80001eb4:	7179                	addi	sp,sp,-48
    80001eb6:	f406                	sd	ra,40(sp)
    80001eb8:	f022                	sd	s0,32(sp)
    80001eba:	ec26                	sd	s1,24(sp)
    80001ebc:	e84a                	sd	s2,16(sp)
    80001ebe:	e44e                	sd	s3,8(sp)
    80001ec0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ec2:	a4fff0ef          	jal	80001910 <myproc>
    80001ec6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ec8:	cdffe0ef          	jal	80000ba6 <holding>
    80001ecc:	c92d                	beqz	a0,80001f3e <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ece:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ed0:	2781                	sext.w	a5,a5
    80001ed2:	079e                	slli	a5,a5,0x7
    80001ed4:	00010717          	auipc	a4,0x10
    80001ed8:	79470713          	addi	a4,a4,1940 # 80012668 <pid_lock>
    80001edc:	97ba                	add	a5,a5,a4
    80001ede:	0a87a703          	lw	a4,168(a5)
    80001ee2:	4785                	li	a5,1
    80001ee4:	06f71363          	bne	a4,a5,80001f4a <sched+0x96>
  if(p->state == RUNNING)
    80001ee8:	4c98                	lw	a4,24(s1)
    80001eea:	4791                	li	a5,4
    80001eec:	06f70563          	beq	a4,a5,80001f56 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ef4:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001ef6:	e7b5                	bnez	a5,80001f62 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ef8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001efa:	00010917          	auipc	s2,0x10
    80001efe:	76e90913          	addi	s2,s2,1902 # 80012668 <pid_lock>
    80001f02:	2781                	sext.w	a5,a5
    80001f04:	079e                	slli	a5,a5,0x7
    80001f06:	97ca                	add	a5,a5,s2
    80001f08:	0ac7a983          	lw	s3,172(a5)
    80001f0c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f0e:	2781                	sext.w	a5,a5
    80001f10:	079e                	slli	a5,a5,0x7
    80001f12:	00010597          	auipc	a1,0x10
    80001f16:	78e58593          	addi	a1,a1,1934 # 800126a0 <cpus+0x8>
    80001f1a:	95be                	add	a1,a1,a5
    80001f1c:	06048513          	addi	a0,s1,96
    80001f20:	5fc000ef          	jal	8000251c <swtch>
    80001f24:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f26:	2781                	sext.w	a5,a5
    80001f28:	079e                	slli	a5,a5,0x7
    80001f2a:	993e                	add	s2,s2,a5
    80001f2c:	0b392623          	sw	s3,172(s2)
}
    80001f30:	70a2                	ld	ra,40(sp)
    80001f32:	7402                	ld	s0,32(sp)
    80001f34:	64e2                	ld	s1,24(sp)
    80001f36:	6942                	ld	s2,16(sp)
    80001f38:	69a2                	ld	s3,8(sp)
    80001f3a:	6145                	addi	sp,sp,48
    80001f3c:	8082                	ret
    panic("sched p->lock");
    80001f3e:	00005517          	auipc	a0,0x5
    80001f42:	25a50513          	addi	a0,a0,602 # 80007198 <etext+0x198>
    80001f46:	89bfe0ef          	jal	800007e0 <panic>
    panic("sched locks");
    80001f4a:	00005517          	auipc	a0,0x5
    80001f4e:	25e50513          	addi	a0,a0,606 # 800071a8 <etext+0x1a8>
    80001f52:	88ffe0ef          	jal	800007e0 <panic>
    panic("sched RUNNING");
    80001f56:	00005517          	auipc	a0,0x5
    80001f5a:	26250513          	addi	a0,a0,610 # 800071b8 <etext+0x1b8>
    80001f5e:	883fe0ef          	jal	800007e0 <panic>
    panic("sched interruptible");
    80001f62:	00005517          	auipc	a0,0x5
    80001f66:	26650513          	addi	a0,a0,614 # 800071c8 <etext+0x1c8>
    80001f6a:	877fe0ef          	jal	800007e0 <panic>

0000000080001f6e <yield>:
{
    80001f6e:	1101                	addi	sp,sp,-32
    80001f70:	ec06                	sd	ra,24(sp)
    80001f72:	e822                	sd	s0,16(sp)
    80001f74:	e426                	sd	s1,8(sp)
    80001f76:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f78:	999ff0ef          	jal	80001910 <myproc>
    80001f7c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f7e:	c93fe0ef          	jal	80000c10 <acquire>
  p->state = RUNNABLE;
    80001f82:	478d                	li	a5,3
    80001f84:	cc9c                	sw	a5,24(s1)
  sched();
    80001f86:	f2fff0ef          	jal	80001eb4 <sched>
  release(&p->lock);
    80001f8a:	8526                	mv	a0,s1
    80001f8c:	d1dfe0ef          	jal	80000ca8 <release>
}
    80001f90:	60e2                	ld	ra,24(sp)
    80001f92:	6442                	ld	s0,16(sp)
    80001f94:	64a2                	ld	s1,8(sp)
    80001f96:	6105                	addi	sp,sp,32
    80001f98:	8082                	ret

0000000080001f9a <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001f9a:	7179                	addi	sp,sp,-48
    80001f9c:	f406                	sd	ra,40(sp)
    80001f9e:	f022                	sd	s0,32(sp)
    80001fa0:	ec26                	sd	s1,24(sp)
    80001fa2:	e84a                	sd	s2,16(sp)
    80001fa4:	e44e                	sd	s3,8(sp)
    80001fa6:	1800                	addi	s0,sp,48
    80001fa8:	89aa                	mv	s3,a0
    80001faa:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001fac:	965ff0ef          	jal	80001910 <myproc>
    80001fb0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001fb2:	c5ffe0ef          	jal	80000c10 <acquire>
  release(lk);
    80001fb6:	854a                	mv	a0,s2
    80001fb8:	cf1fe0ef          	jal	80000ca8 <release>

  // Go to sleep.
  p->chan = chan;
    80001fbc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001fc0:	4789                	li	a5,2
    80001fc2:	cc9c                	sw	a5,24(s1)

  sched();
    80001fc4:	ef1ff0ef          	jal	80001eb4 <sched>

  // Tidy up.
  p->chan = 0;
    80001fc8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001fcc:	8526                	mv	a0,s1
    80001fce:	cdbfe0ef          	jal	80000ca8 <release>
  acquire(lk);
    80001fd2:	854a                	mv	a0,s2
    80001fd4:	c3dfe0ef          	jal	80000c10 <acquire>
}
    80001fd8:	70a2                	ld	ra,40(sp)
    80001fda:	7402                	ld	s0,32(sp)
    80001fdc:	64e2                	ld	s1,24(sp)
    80001fde:	6942                	ld	s2,16(sp)
    80001fe0:	69a2                	ld	s3,8(sp)
    80001fe2:	6145                	addi	sp,sp,48
    80001fe4:	8082                	ret

0000000080001fe6 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80001fe6:	7139                	addi	sp,sp,-64
    80001fe8:	fc06                	sd	ra,56(sp)
    80001fea:	f822                	sd	s0,48(sp)
    80001fec:	f426                	sd	s1,40(sp)
    80001fee:	f04a                	sd	s2,32(sp)
    80001ff0:	ec4e                	sd	s3,24(sp)
    80001ff2:	e852                	sd	s4,16(sp)
    80001ff4:	e456                	sd	s5,8(sp)
    80001ff6:	0080                	addi	s0,sp,64
    80001ff8:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001ffa:	00011497          	auipc	s1,0x11
    80001ffe:	a9e48493          	addi	s1,s1,-1378 # 80012a98 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002002:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002004:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002006:	00017917          	auipc	s2,0x17
    8000200a:	a9290913          	addi	s2,s2,-1390 # 80018a98 <tickslock>
    8000200e:	a801                	j	8000201e <wakeup+0x38>
      }
      release(&p->lock);
    80002010:	8526                	mv	a0,s1
    80002012:	c97fe0ef          	jal	80000ca8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002016:	18048493          	addi	s1,s1,384
    8000201a:	03248263          	beq	s1,s2,8000203e <wakeup+0x58>
    if(p != myproc()){
    8000201e:	8f3ff0ef          	jal	80001910 <myproc>
    80002022:	fea48ae3          	beq	s1,a0,80002016 <wakeup+0x30>
      acquire(&p->lock);
    80002026:	8526                	mv	a0,s1
    80002028:	be9fe0ef          	jal	80000c10 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000202c:	4c9c                	lw	a5,24(s1)
    8000202e:	ff3791e3          	bne	a5,s3,80002010 <wakeup+0x2a>
    80002032:	709c                	ld	a5,32(s1)
    80002034:	fd479ee3          	bne	a5,s4,80002010 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002038:	0154ac23          	sw	s5,24(s1)
    8000203c:	bfd1                	j	80002010 <wakeup+0x2a>
    }
  }
}
    8000203e:	70e2                	ld	ra,56(sp)
    80002040:	7442                	ld	s0,48(sp)
    80002042:	74a2                	ld	s1,40(sp)
    80002044:	7902                	ld	s2,32(sp)
    80002046:	69e2                	ld	s3,24(sp)
    80002048:	6a42                	ld	s4,16(sp)
    8000204a:	6aa2                	ld	s5,8(sp)
    8000204c:	6121                	addi	sp,sp,64
    8000204e:	8082                	ret

0000000080002050 <reparent>:
{
    80002050:	7179                	addi	sp,sp,-48
    80002052:	f406                	sd	ra,40(sp)
    80002054:	f022                	sd	s0,32(sp)
    80002056:	ec26                	sd	s1,24(sp)
    80002058:	e84a                	sd	s2,16(sp)
    8000205a:	e44e                	sd	s3,8(sp)
    8000205c:	e052                	sd	s4,0(sp)
    8000205e:	1800                	addi	s0,sp,48
    80002060:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002062:	00011497          	auipc	s1,0x11
    80002066:	a3648493          	addi	s1,s1,-1482 # 80012a98 <proc>
      pp->parent = initproc;
    8000206a:	00008a17          	auipc	s4,0x8
    8000206e:	4f6a0a13          	addi	s4,s4,1270 # 8000a560 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002072:	00017997          	auipc	s3,0x17
    80002076:	a2698993          	addi	s3,s3,-1498 # 80018a98 <tickslock>
    8000207a:	a029                	j	80002084 <reparent+0x34>
    8000207c:	18048493          	addi	s1,s1,384
    80002080:	01348b63          	beq	s1,s3,80002096 <reparent+0x46>
    if(pp->parent == p){
    80002084:	7c9c                	ld	a5,56(s1)
    80002086:	ff279be3          	bne	a5,s2,8000207c <reparent+0x2c>
      pp->parent = initproc;
    8000208a:	000a3503          	ld	a0,0(s4)
    8000208e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002090:	f57ff0ef          	jal	80001fe6 <wakeup>
    80002094:	b7e5                	j	8000207c <reparent+0x2c>
}
    80002096:	70a2                	ld	ra,40(sp)
    80002098:	7402                	ld	s0,32(sp)
    8000209a:	64e2                	ld	s1,24(sp)
    8000209c:	6942                	ld	s2,16(sp)
    8000209e:	69a2                	ld	s3,8(sp)
    800020a0:	6a02                	ld	s4,0(sp)
    800020a2:	6145                	addi	sp,sp,48
    800020a4:	8082                	ret

00000000800020a6 <kexit>:
{
    800020a6:	7179                	addi	sp,sp,-48
    800020a8:	f406                	sd	ra,40(sp)
    800020aa:	f022                	sd	s0,32(sp)
    800020ac:	ec26                	sd	s1,24(sp)
    800020ae:	e84a                	sd	s2,16(sp)
    800020b0:	e44e                	sd	s3,8(sp)
    800020b2:	e052                	sd	s4,0(sp)
    800020b4:	1800                	addi	s0,sp,48
    800020b6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020b8:	859ff0ef          	jal	80001910 <myproc>
    800020bc:	89aa                	mv	s3,a0
  if(p == initproc)
    800020be:	00008797          	auipc	a5,0x8
    800020c2:	4a27b783          	ld	a5,1186(a5) # 8000a560 <initproc>
    800020c6:	0d050493          	addi	s1,a0,208
    800020ca:	15050913          	addi	s2,a0,336
    800020ce:	00a79f63          	bne	a5,a0,800020ec <kexit+0x46>
    panic("init exiting");
    800020d2:	00005517          	auipc	a0,0x5
    800020d6:	10e50513          	addi	a0,a0,270 # 800071e0 <etext+0x1e0>
    800020da:	f06fe0ef          	jal	800007e0 <panic>
      fileclose(f);
    800020de:	2b6020ef          	jal	80004394 <fileclose>
      p->ofile[fd] = 0;
    800020e2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020e6:	04a1                	addi	s1,s1,8
    800020e8:	01248563          	beq	s1,s2,800020f2 <kexit+0x4c>
    if(p->ofile[fd]){
    800020ec:	6088                	ld	a0,0(s1)
    800020ee:	f965                	bnez	a0,800020de <kexit+0x38>
    800020f0:	bfdd                	j	800020e6 <kexit+0x40>
  begin_op();
    800020f2:	697010ef          	jal	80003f88 <begin_op>
  iput(p->cwd);
    800020f6:	1509b503          	ld	a0,336(s3)
    800020fa:	626010ef          	jal	80003720 <iput>
  end_op();
    800020fe:	6f5010ef          	jal	80003ff2 <end_op>
  p->cwd = 0;
    80002102:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002106:	00010497          	auipc	s1,0x10
    8000210a:	57a48493          	addi	s1,s1,1402 # 80012680 <wait_lock>
    8000210e:	8526                	mv	a0,s1
    80002110:	b01fe0ef          	jal	80000c10 <acquire>
  reparent(p);
    80002114:	854e                	mv	a0,s3
    80002116:	f3bff0ef          	jal	80002050 <reparent>
  wakeup(p->parent);
    8000211a:	0389b503          	ld	a0,56(s3)
    8000211e:	ec9ff0ef          	jal	80001fe6 <wakeup>
  acquire(&p->lock);
    80002122:	854e                	mv	a0,s3
    80002124:	aedfe0ef          	jal	80000c10 <acquire>
  p->xstate = status;
    80002128:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000212c:	4795                	li	a5,5
    8000212e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002132:	8526                	mv	a0,s1
    80002134:	b75fe0ef          	jal	80000ca8 <release>
  sched();
    80002138:	d7dff0ef          	jal	80001eb4 <sched>
  panic("zombie exit");
    8000213c:	00005517          	auipc	a0,0x5
    80002140:	0b450513          	addi	a0,a0,180 # 800071f0 <etext+0x1f0>
    80002144:	e9cfe0ef          	jal	800007e0 <panic>

0000000080002148 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    80002148:	7179                	addi	sp,sp,-48
    8000214a:	f406                	sd	ra,40(sp)
    8000214c:	f022                	sd	s0,32(sp)
    8000214e:	ec26                	sd	s1,24(sp)
    80002150:	e84a                	sd	s2,16(sp)
    80002152:	e44e                	sd	s3,8(sp)
    80002154:	1800                	addi	s0,sp,48
    80002156:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002158:	00011497          	auipc	s1,0x11
    8000215c:	94048493          	addi	s1,s1,-1728 # 80012a98 <proc>
    80002160:	00017997          	auipc	s3,0x17
    80002164:	93898993          	addi	s3,s3,-1736 # 80018a98 <tickslock>
    acquire(&p->lock);
    80002168:	8526                	mv	a0,s1
    8000216a:	aa7fe0ef          	jal	80000c10 <acquire>
    if(p->pid == pid){
    8000216e:	589c                	lw	a5,48(s1)
    80002170:	01278b63          	beq	a5,s2,80002186 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002174:	8526                	mv	a0,s1
    80002176:	b33fe0ef          	jal	80000ca8 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000217a:	18048493          	addi	s1,s1,384
    8000217e:	ff3495e3          	bne	s1,s3,80002168 <kkill+0x20>
  }
  return -1;
    80002182:	557d                	li	a0,-1
    80002184:	a819                	j	8000219a <kkill+0x52>
      p->killed = 1;
    80002186:	4785                	li	a5,1
    80002188:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000218a:	4c98                	lw	a4,24(s1)
    8000218c:	4789                	li	a5,2
    8000218e:	00f70d63          	beq	a4,a5,800021a8 <kkill+0x60>
      release(&p->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	b15fe0ef          	jal	80000ca8 <release>
      return 0;
    80002198:	4501                	li	a0,0
}
    8000219a:	70a2                	ld	ra,40(sp)
    8000219c:	7402                	ld	s0,32(sp)
    8000219e:	64e2                	ld	s1,24(sp)
    800021a0:	6942                	ld	s2,16(sp)
    800021a2:	69a2                	ld	s3,8(sp)
    800021a4:	6145                	addi	sp,sp,48
    800021a6:	8082                	ret
        p->state = RUNNABLE;
    800021a8:	478d                	li	a5,3
    800021aa:	cc9c                	sw	a5,24(s1)
    800021ac:	b7dd                	j	80002192 <kkill+0x4a>

00000000800021ae <setkilled>:

void
setkilled(struct proc *p)
{
    800021ae:	1101                	addi	sp,sp,-32
    800021b0:	ec06                	sd	ra,24(sp)
    800021b2:	e822                	sd	s0,16(sp)
    800021b4:	e426                	sd	s1,8(sp)
    800021b6:	1000                	addi	s0,sp,32
    800021b8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021ba:	a57fe0ef          	jal	80000c10 <acquire>
  p->killed = 1;
    800021be:	4785                	li	a5,1
    800021c0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	ae5fe0ef          	jal	80000ca8 <release>
}
    800021c8:	60e2                	ld	ra,24(sp)
    800021ca:	6442                	ld	s0,16(sp)
    800021cc:	64a2                	ld	s1,8(sp)
    800021ce:	6105                	addi	sp,sp,32
    800021d0:	8082                	ret

00000000800021d2 <killed>:

int
killed(struct proc *p)
{
    800021d2:	1101                	addi	sp,sp,-32
    800021d4:	ec06                	sd	ra,24(sp)
    800021d6:	e822                	sd	s0,16(sp)
    800021d8:	e426                	sd	s1,8(sp)
    800021da:	e04a                	sd	s2,0(sp)
    800021dc:	1000                	addi	s0,sp,32
    800021de:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800021e0:	a31fe0ef          	jal	80000c10 <acquire>
  k = p->killed;
    800021e4:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	abffe0ef          	jal	80000ca8 <release>
  return k;
}
    800021ee:	854a                	mv	a0,s2
    800021f0:	60e2                	ld	ra,24(sp)
    800021f2:	6442                	ld	s0,16(sp)
    800021f4:	64a2                	ld	s1,8(sp)
    800021f6:	6902                	ld	s2,0(sp)
    800021f8:	6105                	addi	sp,sp,32
    800021fa:	8082                	ret

00000000800021fc <kwait>:
{
    800021fc:	715d                	addi	sp,sp,-80
    800021fe:	e486                	sd	ra,72(sp)
    80002200:	e0a2                	sd	s0,64(sp)
    80002202:	fc26                	sd	s1,56(sp)
    80002204:	f84a                	sd	s2,48(sp)
    80002206:	f44e                	sd	s3,40(sp)
    80002208:	f052                	sd	s4,32(sp)
    8000220a:	ec56                	sd	s5,24(sp)
    8000220c:	e85a                	sd	s6,16(sp)
    8000220e:	e45e                	sd	s7,8(sp)
    80002210:	e062                	sd	s8,0(sp)
    80002212:	0880                	addi	s0,sp,80
    80002214:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002216:	efaff0ef          	jal	80001910 <myproc>
    8000221a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000221c:	00010517          	auipc	a0,0x10
    80002220:	46450513          	addi	a0,a0,1124 # 80012680 <wait_lock>
    80002224:	9edfe0ef          	jal	80000c10 <acquire>
    havekids = 0;
    80002228:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000222a:	4a15                	li	s4,5
        havekids = 1;
    8000222c:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000222e:	00017997          	auipc	s3,0x17
    80002232:	86a98993          	addi	s3,s3,-1942 # 80018a98 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002236:	00010c17          	auipc	s8,0x10
    8000223a:	44ac0c13          	addi	s8,s8,1098 # 80012680 <wait_lock>
    8000223e:	a871                	j	800022da <kwait+0xde>
          pid = pp->pid;
    80002240:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002244:	000b0c63          	beqz	s6,8000225c <kwait+0x60>
    80002248:	4691                	li	a3,4
    8000224a:	02c48613          	addi	a2,s1,44
    8000224e:	85da                	mv	a1,s6
    80002250:	05093503          	ld	a0,80(s2)
    80002254:	bd0ff0ef          	jal	80001624 <copyout>
    80002258:	02054b63          	bltz	a0,8000228e <kwait+0x92>
          freeproc(pp);
    8000225c:	8526                	mv	a0,s1
    8000225e:	883ff0ef          	jal	80001ae0 <freeproc>
          release(&pp->lock);
    80002262:	8526                	mv	a0,s1
    80002264:	a45fe0ef          	jal	80000ca8 <release>
          release(&wait_lock);
    80002268:	00010517          	auipc	a0,0x10
    8000226c:	41850513          	addi	a0,a0,1048 # 80012680 <wait_lock>
    80002270:	a39fe0ef          	jal	80000ca8 <release>
}
    80002274:	854e                	mv	a0,s3
    80002276:	60a6                	ld	ra,72(sp)
    80002278:	6406                	ld	s0,64(sp)
    8000227a:	74e2                	ld	s1,56(sp)
    8000227c:	7942                	ld	s2,48(sp)
    8000227e:	79a2                	ld	s3,40(sp)
    80002280:	7a02                	ld	s4,32(sp)
    80002282:	6ae2                	ld	s5,24(sp)
    80002284:	6b42                	ld	s6,16(sp)
    80002286:	6ba2                	ld	s7,8(sp)
    80002288:	6c02                	ld	s8,0(sp)
    8000228a:	6161                	addi	sp,sp,80
    8000228c:	8082                	ret
            release(&pp->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	a19fe0ef          	jal	80000ca8 <release>
            release(&wait_lock);
    80002294:	00010517          	auipc	a0,0x10
    80002298:	3ec50513          	addi	a0,a0,1004 # 80012680 <wait_lock>
    8000229c:	a0dfe0ef          	jal	80000ca8 <release>
            return -1;
    800022a0:	59fd                	li	s3,-1
    800022a2:	bfc9                	j	80002274 <kwait+0x78>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a4:	18048493          	addi	s1,s1,384
    800022a8:	03348063          	beq	s1,s3,800022c8 <kwait+0xcc>
      if(pp->parent == p){
    800022ac:	7c9c                	ld	a5,56(s1)
    800022ae:	ff279be3          	bne	a5,s2,800022a4 <kwait+0xa8>
        acquire(&pp->lock);
    800022b2:	8526                	mv	a0,s1
    800022b4:	95dfe0ef          	jal	80000c10 <acquire>
        if(pp->state == ZOMBIE){
    800022b8:	4c9c                	lw	a5,24(s1)
    800022ba:	f94783e3          	beq	a5,s4,80002240 <kwait+0x44>
        release(&pp->lock);
    800022be:	8526                	mv	a0,s1
    800022c0:	9e9fe0ef          	jal	80000ca8 <release>
        havekids = 1;
    800022c4:	8756                	mv	a4,s5
    800022c6:	bff9                	j	800022a4 <kwait+0xa8>
    if(!havekids || killed(p)){
    800022c8:	cf19                	beqz	a4,800022e6 <kwait+0xea>
    800022ca:	854a                	mv	a0,s2
    800022cc:	f07ff0ef          	jal	800021d2 <killed>
    800022d0:	e919                	bnez	a0,800022e6 <kwait+0xea>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022d2:	85e2                	mv	a1,s8
    800022d4:	854a                	mv	a0,s2
    800022d6:	cc5ff0ef          	jal	80001f9a <sleep>
    havekids = 0;
    800022da:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800022dc:	00010497          	auipc	s1,0x10
    800022e0:	7bc48493          	addi	s1,s1,1980 # 80012a98 <proc>
    800022e4:	b7e1                	j	800022ac <kwait+0xb0>
      release(&wait_lock);
    800022e6:	00010517          	auipc	a0,0x10
    800022ea:	39a50513          	addi	a0,a0,922 # 80012680 <wait_lock>
    800022ee:	9bbfe0ef          	jal	80000ca8 <release>
      return -1;
    800022f2:	59fd                	li	s3,-1
    800022f4:	b741                	j	80002274 <kwait+0x78>

00000000800022f6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800022f6:	7179                	addi	sp,sp,-48
    800022f8:	f406                	sd	ra,40(sp)
    800022fa:	f022                	sd	s0,32(sp)
    800022fc:	ec26                	sd	s1,24(sp)
    800022fe:	e84a                	sd	s2,16(sp)
    80002300:	e44e                	sd	s3,8(sp)
    80002302:	e052                	sd	s4,0(sp)
    80002304:	1800                	addi	s0,sp,48
    80002306:	84aa                	mv	s1,a0
    80002308:	892e                	mv	s2,a1
    8000230a:	89b2                	mv	s3,a2
    8000230c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000230e:	e02ff0ef          	jal	80001910 <myproc>
  if(user_dst){
    80002312:	cc99                	beqz	s1,80002330 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80002314:	86d2                	mv	a3,s4
    80002316:	864e                	mv	a2,s3
    80002318:	85ca                	mv	a1,s2
    8000231a:	6928                	ld	a0,80(a0)
    8000231c:	b08ff0ef          	jal	80001624 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002320:	70a2                	ld	ra,40(sp)
    80002322:	7402                	ld	s0,32(sp)
    80002324:	64e2                	ld	s1,24(sp)
    80002326:	6942                	ld	s2,16(sp)
    80002328:	69a2                	ld	s3,8(sp)
    8000232a:	6a02                	ld	s4,0(sp)
    8000232c:	6145                	addi	sp,sp,48
    8000232e:	8082                	ret
    memmove((char *)dst, src, len);
    80002330:	000a061b          	sext.w	a2,s4
    80002334:	85ce                	mv	a1,s3
    80002336:	854a                	mv	a0,s2
    80002338:	a09fe0ef          	jal	80000d40 <memmove>
    return 0;
    8000233c:	8526                	mv	a0,s1
    8000233e:	b7cd                	j	80002320 <either_copyout+0x2a>

0000000080002340 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002340:	7179                	addi	sp,sp,-48
    80002342:	f406                	sd	ra,40(sp)
    80002344:	f022                	sd	s0,32(sp)
    80002346:	ec26                	sd	s1,24(sp)
    80002348:	e84a                	sd	s2,16(sp)
    8000234a:	e44e                	sd	s3,8(sp)
    8000234c:	e052                	sd	s4,0(sp)
    8000234e:	1800                	addi	s0,sp,48
    80002350:	892a                	mv	s2,a0
    80002352:	84ae                	mv	s1,a1
    80002354:	89b2                	mv	s3,a2
    80002356:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002358:	db8ff0ef          	jal	80001910 <myproc>
  if(user_src){
    8000235c:	cc99                	beqz	s1,8000237a <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    8000235e:	86d2                	mv	a3,s4
    80002360:	864e                	mv	a2,s3
    80002362:	85ca                	mv	a1,s2
    80002364:	6928                	ld	a0,80(a0)
    80002366:	ba2ff0ef          	jal	80001708 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000236a:	70a2                	ld	ra,40(sp)
    8000236c:	7402                	ld	s0,32(sp)
    8000236e:	64e2                	ld	s1,24(sp)
    80002370:	6942                	ld	s2,16(sp)
    80002372:	69a2                	ld	s3,8(sp)
    80002374:	6a02                	ld	s4,0(sp)
    80002376:	6145                	addi	sp,sp,48
    80002378:	8082                	ret
    memmove(dst, (char*)src, len);
    8000237a:	000a061b          	sext.w	a2,s4
    8000237e:	85ce                	mv	a1,s3
    80002380:	854a                	mv	a0,s2
    80002382:	9bffe0ef          	jal	80000d40 <memmove>
    return 0;
    80002386:	8526                	mv	a0,s1
    80002388:	b7cd                	j	8000236a <either_copyin+0x2a>

000000008000238a <proc_count>:

// Number of processes whose state != UNUSED.
uint64
proc_count(void)
{
    8000238a:	7179                	addi	sp,sp,-48
    8000238c:	f406                	sd	ra,40(sp)
    8000238e:	f022                	sd	s0,32(sp)
    80002390:	ec26                	sd	s1,24(sp)
    80002392:	e84a                	sd	s2,16(sp)
    80002394:	e44e                	sd	s3,8(sp)
    80002396:	1800                	addi	s0,sp,48
  struct proc *p;
  uint64 n = 0;
    80002398:	4901                	li	s2,0

  for(p = proc; p < &proc[NPROC]; p++){
    8000239a:	00010497          	auipc	s1,0x10
    8000239e:	6fe48493          	addi	s1,s1,1790 # 80012a98 <proc>
    800023a2:	00016997          	auipc	s3,0x16
    800023a6:	6f698993          	addi	s3,s3,1782 # 80018a98 <tickslock>
    acquire(&p->lock);
    800023aa:	8526                	mv	a0,s1
    800023ac:	865fe0ef          	jal	80000c10 <acquire>
    if(p->state != UNUSED)
    800023b0:	4c9c                	lw	a5,24(s1)
      n++;
    800023b2:	00f037b3          	snez	a5,a5
    800023b6:	993e                	add	s2,s2,a5
    release(&p->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	8effe0ef          	jal	80000ca8 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023be:	18048493          	addi	s1,s1,384
    800023c2:	ff3494e3          	bne	s1,s3,800023aa <proc_count+0x20>
  }
  return n;
}
    800023c6:	854a                	mv	a0,s2
    800023c8:	70a2                	ld	ra,40(sp)
    800023ca:	7402                	ld	s0,32(sp)
    800023cc:	64e2                	ld	s1,24(sp)
    800023ce:	6942                	ld	s2,16(sp)
    800023d0:	69a2                	ld	s3,8(sp)
    800023d2:	6145                	addi	sp,sp,48
    800023d4:	8082                	ret

00000000800023d6 <proclist_fill>:
// `out` is a kernel pointer to `max` proc_info entries; returns the count
// actually written. Used by sys_proclist to give the LLM bridge a
// schedhint-friendly view of currently live processes.
int
proclist_fill(struct proc_info *out, int max)
{
    800023d6:	7139                	addi	sp,sp,-64
    800023d8:	fc06                	sd	ra,56(sp)
    800023da:	f822                	sd	s0,48(sp)
    800023dc:	f04a                	sd	s2,32(sp)
    800023de:	0080                	addi	s0,sp,64
  struct proc *p;
  int n = 0;

  for(p = proc; p < &proc[NPROC] && n < max; p++){
    800023e0:	08b05563          	blez	a1,8000246a <proclist_fill+0x94>
    800023e4:	f426                	sd	s1,40(sp)
    800023e6:	ec4e                	sd	s3,24(sp)
    800023e8:	e852                	sd	s4,16(sp)
    800023ea:	e456                	sd	s5,8(sp)
    800023ec:	8aaa                	mv	s5,a0
    800023ee:	89ae                	mv	s3,a1
  int n = 0;
    800023f0:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC] && n < max; p++){
    800023f2:	00010497          	auipc	s1,0x10
    800023f6:	6a648493          	addi	s1,s1,1702 # 80012a98 <proc>
    800023fa:	00016a17          	auipc	s4,0x16
    800023fe:	69ea0a13          	addi	s4,s4,1694 # 80018a98 <tickslock>
    80002402:	a811                	j	80002416 <proclist_fill+0x40>
      out[n].run_ticks = p->run_ticks;
      out[n].sleep_ticks = p->sleep_ticks;
      safestrcpy(out[n].name, p->name, sizeof(out[n].name));
      n++;
    }
    release(&p->lock);
    80002404:	8526                	mv	a0,s1
    80002406:	8a3fe0ef          	jal	80000ca8 <release>
  for(p = proc; p < &proc[NPROC] && n < max; p++){
    8000240a:	18048493          	addi	s1,s1,384
    8000240e:	07448063          	beq	s1,s4,8000246e <proclist_fill+0x98>
    80002412:	05395263          	bge	s2,s3,80002456 <proclist_fill+0x80>
    acquire(&p->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	ff8fe0ef          	jal	80000c10 <acquire>
    if(p->state != UNUSED){
    8000241c:	4c9c                	lw	a5,24(s1)
    8000241e:	d3fd                	beqz	a5,80002404 <proclist_fill+0x2e>
      out[n].pid = p->pid;
    80002420:	00191513          	slli	a0,s2,0x1
    80002424:	954a                	add	a0,a0,s2
    80002426:	0512                	slli	a0,a0,0x4
    80002428:	9556                	add	a0,a0,s5
    8000242a:	589c                	lw	a5,48(s1)
    8000242c:	c11c                	sw	a5,0(a0)
      out[n].state = (int)p->state;
    8000242e:	4c9c                	lw	a5,24(s1)
    80002430:	c15c                	sw	a5,4(a0)
      out[n].priority = p->priority;
    80002432:	1684a783          	lw	a5,360(s1)
    80002436:	c51c                	sw	a5,8(a0)
      out[n].run_ticks = p->run_ticks;
    80002438:	1704b783          	ld	a5,368(s1)
    8000243c:	e91c                	sd	a5,16(a0)
      out[n].sleep_ticks = p->sleep_ticks;
    8000243e:	1784b783          	ld	a5,376(s1)
    80002442:	ed1c                	sd	a5,24(a0)
      safestrcpy(out[n].name, p->name, sizeof(out[n].name));
    80002444:	4641                	li	a2,16
    80002446:	15848593          	addi	a1,s1,344
    8000244a:	02050513          	addi	a0,a0,32
    8000244e:	9d5fe0ef          	jal	80000e22 <safestrcpy>
      n++;
    80002452:	2905                	addiw	s2,s2,1
    80002454:	bf45                	j	80002404 <proclist_fill+0x2e>
    80002456:	74a2                	ld	s1,40(sp)
    80002458:	69e2                	ld	s3,24(sp)
    8000245a:	6a42                	ld	s4,16(sp)
    8000245c:	6aa2                	ld	s5,8(sp)
  }
  return n;
}
    8000245e:	854a                	mv	a0,s2
    80002460:	70e2                	ld	ra,56(sp)
    80002462:	7442                	ld	s0,48(sp)
    80002464:	7902                	ld	s2,32(sp)
    80002466:	6121                	addi	sp,sp,64
    80002468:	8082                	ret
  int n = 0;
    8000246a:	4901                	li	s2,0
    8000246c:	bfcd                	j	8000245e <proclist_fill+0x88>
    8000246e:	74a2                	ld	s1,40(sp)
    80002470:	69e2                	ld	s3,24(sp)
    80002472:	6a42                	ld	s4,16(sp)
    80002474:	6aa2                	ld	s5,8(sp)
    80002476:	b7e5                	j	8000245e <proclist_fill+0x88>

0000000080002478 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002478:	715d                	addi	sp,sp,-80
    8000247a:	e486                	sd	ra,72(sp)
    8000247c:	e0a2                	sd	s0,64(sp)
    8000247e:	fc26                	sd	s1,56(sp)
    80002480:	f84a                	sd	s2,48(sp)
    80002482:	f44e                	sd	s3,40(sp)
    80002484:	f052                	sd	s4,32(sp)
    80002486:	ec56                	sd	s5,24(sp)
    80002488:	e85a                	sd	s6,16(sp)
    8000248a:	e45e                	sd	s7,8(sp)
    8000248c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000248e:	00005517          	auipc	a0,0x5
    80002492:	bea50513          	addi	a0,a0,-1046 # 80007078 <etext+0x78>
    80002496:	864fe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000249a:	00010497          	auipc	s1,0x10
    8000249e:	75648493          	addi	s1,s1,1878 # 80012bf0 <proc+0x158>
    800024a2:	00016917          	auipc	s2,0x16
    800024a6:	74e90913          	addi	s2,s2,1870 # 80018bf0 <buf.0+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024aa:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024ac:	00005997          	auipc	s3,0x5
    800024b0:	d5498993          	addi	s3,s3,-684 # 80007200 <etext+0x200>
    printf("%d %s %s", p->pid, state, p->name);
    800024b4:	00005a97          	auipc	s5,0x5
    800024b8:	d54a8a93          	addi	s5,s5,-684 # 80007208 <etext+0x208>
    printf("\n");
    800024bc:	00005a17          	auipc	s4,0x5
    800024c0:	bbca0a13          	addi	s4,s4,-1092 # 80007078 <etext+0x78>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024c4:	00005b97          	auipc	s7,0x5
    800024c8:	36cb8b93          	addi	s7,s7,876 # 80007830 <states.0>
    800024cc:	a829                	j	800024e6 <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    800024ce:	ed86a583          	lw	a1,-296(a3)
    800024d2:	8556                	mv	a0,s5
    800024d4:	826fe0ef          	jal	800004fa <printf>
    printf("\n");
    800024d8:	8552                	mv	a0,s4
    800024da:	820fe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024de:	18048493          	addi	s1,s1,384
    800024e2:	03248263          	beq	s1,s2,80002506 <procdump+0x8e>
    if(p->state == UNUSED)
    800024e6:	86a6                	mv	a3,s1
    800024e8:	ec04a783          	lw	a5,-320(s1)
    800024ec:	dbed                	beqz	a5,800024de <procdump+0x66>
      state = "???";
    800024ee:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024f0:	fcfb6fe3          	bltu	s6,a5,800024ce <procdump+0x56>
    800024f4:	02079713          	slli	a4,a5,0x20
    800024f8:	01d75793          	srli	a5,a4,0x1d
    800024fc:	97de                	add	a5,a5,s7
    800024fe:	6390                	ld	a2,0(a5)
    80002500:	f679                	bnez	a2,800024ce <procdump+0x56>
      state = "???";
    80002502:	864e                	mv	a2,s3
    80002504:	b7e9                	j	800024ce <procdump+0x56>
  }
}
    80002506:	60a6                	ld	ra,72(sp)
    80002508:	6406                	ld	s0,64(sp)
    8000250a:	74e2                	ld	s1,56(sp)
    8000250c:	7942                	ld	s2,48(sp)
    8000250e:	79a2                	ld	s3,40(sp)
    80002510:	7a02                	ld	s4,32(sp)
    80002512:	6ae2                	ld	s5,24(sp)
    80002514:	6b42                	ld	s6,16(sp)
    80002516:	6ba2                	ld	s7,8(sp)
    80002518:	6161                	addi	sp,sp,80
    8000251a:	8082                	ret

000000008000251c <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    8000251c:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    80002520:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    80002524:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    80002526:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    80002528:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    8000252c:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    80002530:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    80002534:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    80002538:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    8000253c:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    80002540:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    80002544:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    80002548:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    8000254c:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    80002550:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    80002554:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    80002558:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    8000255a:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    8000255c:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    80002560:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    80002564:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    80002568:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    8000256c:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    80002570:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    80002574:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    80002578:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    8000257c:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    80002580:	0685bd83          	ld	s11,104(a1)
        
        ret
    80002584:	8082                	ret

0000000080002586 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002586:	1141                	addi	sp,sp,-16
    80002588:	e406                	sd	ra,8(sp)
    8000258a:	e022                	sd	s0,0(sp)
    8000258c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000258e:	00005597          	auipc	a1,0x5
    80002592:	cba58593          	addi	a1,a1,-838 # 80007248 <etext+0x248>
    80002596:	00016517          	auipc	a0,0x16
    8000259a:	50250513          	addi	a0,a0,1282 # 80018a98 <tickslock>
    8000259e:	df2fe0ef          	jal	80000b90 <initlock>
}
    800025a2:	60a2                	ld	ra,8(sp)
    800025a4:	6402                	ld	s0,0(sp)
    800025a6:	0141                	addi	sp,sp,16
    800025a8:	8082                	ret

00000000800025aa <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025aa:	1141                	addi	sp,sp,-16
    800025ac:	e422                	sd	s0,8(sp)
    800025ae:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025b0:	00003797          	auipc	a5,0x3
    800025b4:	16078793          	addi	a5,a5,352 # 80005710 <kernelvec>
    800025b8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800025bc:	6422                	ld	s0,8(sp)
    800025be:	0141                	addi	sp,sp,16
    800025c0:	8082                	ret

00000000800025c2 <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    800025c2:	1141                	addi	sp,sp,-16
    800025c4:	e406                	sd	ra,8(sp)
    800025c6:	e022                	sd	s0,0(sp)
    800025c8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800025ca:	b46ff0ef          	jal	80001910 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800025d2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025d4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800025d8:	04000737          	lui	a4,0x4000
    800025dc:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    800025de:	0732                	slli	a4,a4,0xc
    800025e0:	00004797          	auipc	a5,0x4
    800025e4:	a2078793          	addi	a5,a5,-1504 # 80006000 <_trampoline>
    800025e8:	00004697          	auipc	a3,0x4
    800025ec:	a1868693          	addi	a3,a3,-1512 # 80006000 <_trampoline>
    800025f0:	8f95                	sub	a5,a5,a3
    800025f2:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025f4:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800025f8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800025fa:	18002773          	csrr	a4,satp
    800025fe:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002600:	6d38                	ld	a4,88(a0)
    80002602:	613c                	ld	a5,64(a0)
    80002604:	6685                	lui	a3,0x1
    80002606:	97b6                	add	a5,a5,a3
    80002608:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000260a:	6d3c                	ld	a5,88(a0)
    8000260c:	00000717          	auipc	a4,0x0
    80002610:	0f870713          	addi	a4,a4,248 # 80002704 <usertrap>
    80002614:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002616:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002618:	8712                	mv	a4,tp
    8000261a:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000261c:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002620:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002624:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002628:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000262c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000262e:	6f9c                	ld	a5,24(a5)
    80002630:	14179073          	csrw	sepc,a5
}
    80002634:	60a2                	ld	ra,8(sp)
    80002636:	6402                	ld	s0,0(sp)
    80002638:	0141                	addi	sp,sp,16
    8000263a:	8082                	ret

000000008000263c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000263c:	1101                	addi	sp,sp,-32
    8000263e:	ec06                	sd	ra,24(sp)
    80002640:	e822                	sd	s0,16(sp)
    80002642:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    80002644:	aa0ff0ef          	jal	800018e4 <cpuid>
    80002648:	cd11                	beqz	a0,80002664 <clockintr+0x28>
  asm volatile("csrr %0, time" : "=r" (x) );
    8000264a:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    8000264e:	000f4737          	lui	a4,0xf4
    80002652:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80002656:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80002658:	14d79073          	csrw	stimecmp,a5
}
    8000265c:	60e2                	ld	ra,24(sp)
    8000265e:	6442                	ld	s0,16(sp)
    80002660:	6105                	addi	sp,sp,32
    80002662:	8082                	ret
    80002664:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    80002666:	00016497          	auipc	s1,0x16
    8000266a:	43248493          	addi	s1,s1,1074 # 80018a98 <tickslock>
    8000266e:	8526                	mv	a0,s1
    80002670:	da0fe0ef          	jal	80000c10 <acquire>
    ticks++;
    80002674:	00008517          	auipc	a0,0x8
    80002678:	ef450513          	addi	a0,a0,-268 # 8000a568 <ticks>
    8000267c:	411c                	lw	a5,0(a0)
    8000267e:	2785                	addiw	a5,a5,1
    80002680:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80002682:	965ff0ef          	jal	80001fe6 <wakeup>
    release(&tickslock);
    80002686:	8526                	mv	a0,s1
    80002688:	e20fe0ef          	jal	80000ca8 <release>
    8000268c:	64a2                	ld	s1,8(sp)
    8000268e:	bf75                	j	8000264a <clockintr+0xe>

0000000080002690 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002690:	1101                	addi	sp,sp,-32
    80002692:	ec06                	sd	ra,24(sp)
    80002694:	e822                	sd	s0,16(sp)
    80002696:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002698:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    8000269c:	57fd                	li	a5,-1
    8000269e:	17fe                	slli	a5,a5,0x3f
    800026a0:	07a5                	addi	a5,a5,9
    800026a2:	00f70c63          	beq	a4,a5,800026ba <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800026a6:	57fd                	li	a5,-1
    800026a8:	17fe                	slli	a5,a5,0x3f
    800026aa:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800026ac:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800026ae:	04f70763          	beq	a4,a5,800026fc <devintr+0x6c>
  }
}
    800026b2:	60e2                	ld	ra,24(sp)
    800026b4:	6442                	ld	s0,16(sp)
    800026b6:	6105                	addi	sp,sp,32
    800026b8:	8082                	ret
    800026ba:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    800026bc:	100030ef          	jal	800057bc <plic_claim>
    800026c0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800026c2:	47a9                	li	a5,10
    800026c4:	00f50963          	beq	a0,a5,800026d6 <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    800026c8:	4785                	li	a5,1
    800026ca:	00f50963          	beq	a0,a5,800026dc <devintr+0x4c>
    return 1;
    800026ce:	4505                	li	a0,1
    } else if(irq){
    800026d0:	e889                	bnez	s1,800026e2 <devintr+0x52>
    800026d2:	64a2                	ld	s1,8(sp)
    800026d4:	bff9                	j	800026b2 <devintr+0x22>
      uartintr();
    800026d6:	adafe0ef          	jal	800009b0 <uartintr>
    if(irq)
    800026da:	a819                	j	800026f0 <devintr+0x60>
      virtio_disk_intr();
    800026dc:	5a6030ef          	jal	80005c82 <virtio_disk_intr>
    if(irq)
    800026e0:	a801                	j	800026f0 <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    800026e2:	85a6                	mv	a1,s1
    800026e4:	00005517          	auipc	a0,0x5
    800026e8:	b6c50513          	addi	a0,a0,-1172 # 80007250 <etext+0x250>
    800026ec:	e0ffd0ef          	jal	800004fa <printf>
      plic_complete(irq);
    800026f0:	8526                	mv	a0,s1
    800026f2:	0ea030ef          	jal	800057dc <plic_complete>
    return 1;
    800026f6:	4505                	li	a0,1
    800026f8:	64a2                	ld	s1,8(sp)
    800026fa:	bf65                	j	800026b2 <devintr+0x22>
    clockintr();
    800026fc:	f41ff0ef          	jal	8000263c <clockintr>
    return 2;
    80002700:	4509                	li	a0,2
    80002702:	bf45                	j	800026b2 <devintr+0x22>

0000000080002704 <usertrap>:
{
    80002704:	1101                	addi	sp,sp,-32
    80002706:	ec06                	sd	ra,24(sp)
    80002708:	e822                	sd	s0,16(sp)
    8000270a:	e426                	sd	s1,8(sp)
    8000270c:	e04a                	sd	s2,0(sp)
    8000270e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002710:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002714:	1007f793          	andi	a5,a5,256
    80002718:	eba5                	bnez	a5,80002788 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000271a:	00003797          	auipc	a5,0x3
    8000271e:	ff678793          	addi	a5,a5,-10 # 80005710 <kernelvec>
    80002722:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002726:	9eaff0ef          	jal	80001910 <myproc>
    8000272a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000272c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000272e:	14102773          	csrr	a4,sepc
    80002732:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002734:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002738:	47a1                	li	a5,8
    8000273a:	04f70d63          	beq	a4,a5,80002794 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    8000273e:	f53ff0ef          	jal	80002690 <devintr>
    80002742:	892a                	mv	s2,a0
    80002744:	e945                	bnez	a0,800027f4 <usertrap+0xf0>
    80002746:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    8000274a:	47bd                	li	a5,15
    8000274c:	08f70863          	beq	a4,a5,800027dc <usertrap+0xd8>
    80002750:	14202773          	csrr	a4,scause
    80002754:	47b5                	li	a5,13
    80002756:	08f70363          	beq	a4,a5,800027dc <usertrap+0xd8>
    8000275a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    8000275e:	5890                	lw	a2,48(s1)
    80002760:	00005517          	auipc	a0,0x5
    80002764:	b3050513          	addi	a0,a0,-1232 # 80007290 <etext+0x290>
    80002768:	d93fd0ef          	jal	800004fa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000276c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002770:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    80002774:	00005517          	auipc	a0,0x5
    80002778:	b4c50513          	addi	a0,a0,-1204 # 800072c0 <etext+0x2c0>
    8000277c:	d7ffd0ef          	jal	800004fa <printf>
    setkilled(p);
    80002780:	8526                	mv	a0,s1
    80002782:	a2dff0ef          	jal	800021ae <setkilled>
    80002786:	a035                	j	800027b2 <usertrap+0xae>
    panic("usertrap: not from user mode");
    80002788:	00005517          	auipc	a0,0x5
    8000278c:	ae850513          	addi	a0,a0,-1304 # 80007270 <etext+0x270>
    80002790:	850fe0ef          	jal	800007e0 <panic>
    if(killed(p))
    80002794:	a3fff0ef          	jal	800021d2 <killed>
    80002798:	ed15                	bnez	a0,800027d4 <usertrap+0xd0>
    p->trapframe->epc += 4;
    8000279a:	6cb8                	ld	a4,88(s1)
    8000279c:	6f1c                	ld	a5,24(a4)
    8000279e:	0791                	addi	a5,a5,4
    800027a0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027a2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027a6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027aa:	10079073          	csrw	sstatus,a5
    syscall();
    800027ae:	246000ef          	jal	800029f4 <syscall>
  if(killed(p))
    800027b2:	8526                	mv	a0,s1
    800027b4:	a1fff0ef          	jal	800021d2 <killed>
    800027b8:	e139                	bnez	a0,800027fe <usertrap+0xfa>
  prepare_return();
    800027ba:	e09ff0ef          	jal	800025c2 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800027be:	68a8                	ld	a0,80(s1)
    800027c0:	8131                	srli	a0,a0,0xc
    800027c2:	57fd                	li	a5,-1
    800027c4:	17fe                	slli	a5,a5,0x3f
    800027c6:	8d5d                	or	a0,a0,a5
}
    800027c8:	60e2                	ld	ra,24(sp)
    800027ca:	6442                	ld	s0,16(sp)
    800027cc:	64a2                	ld	s1,8(sp)
    800027ce:	6902                	ld	s2,0(sp)
    800027d0:	6105                	addi	sp,sp,32
    800027d2:	8082                	ret
      kexit(-1);
    800027d4:	557d                	li	a0,-1
    800027d6:	8d1ff0ef          	jal	800020a6 <kexit>
    800027da:	b7c1                	j	8000279a <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800027dc:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e0:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    800027e4:	164d                	addi	a2,a2,-13 # ff3 <_entry-0x7ffff00d>
    800027e6:	00163613          	seqz	a2,a2
    800027ea:	68a8                	ld	a0,80(s1)
    800027ec:	db7fe0ef          	jal	800015a2 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    800027f0:	f169                	bnez	a0,800027b2 <usertrap+0xae>
    800027f2:	b7a5                	j	8000275a <usertrap+0x56>
  if(killed(p))
    800027f4:	8526                	mv	a0,s1
    800027f6:	9ddff0ef          	jal	800021d2 <killed>
    800027fa:	c511                	beqz	a0,80002806 <usertrap+0x102>
    800027fc:	a011                	j	80002800 <usertrap+0xfc>
    800027fe:	4901                	li	s2,0
    kexit(-1);
    80002800:	557d                	li	a0,-1
    80002802:	8a5ff0ef          	jal	800020a6 <kexit>
  if(which_dev == 2)
    80002806:	4789                	li	a5,2
    80002808:	faf919e3          	bne	s2,a5,800027ba <usertrap+0xb6>
    yield();
    8000280c:	f62ff0ef          	jal	80001f6e <yield>
    80002810:	b76d                	j	800027ba <usertrap+0xb6>

0000000080002812 <kerneltrap>:
{
    80002812:	7179                	addi	sp,sp,-48
    80002814:	f406                	sd	ra,40(sp)
    80002816:	f022                	sd	s0,32(sp)
    80002818:	ec26                	sd	s1,24(sp)
    8000281a:	e84a                	sd	s2,16(sp)
    8000281c:	e44e                	sd	s3,8(sp)
    8000281e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002820:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002824:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002828:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000282c:	1004f793          	andi	a5,s1,256
    80002830:	c795                	beqz	a5,8000285c <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002832:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002836:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002838:	eb85                	bnez	a5,80002868 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    8000283a:	e57ff0ef          	jal	80002690 <devintr>
    8000283e:	c91d                	beqz	a0,80002874 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    80002840:	4789                	li	a5,2
    80002842:	04f50a63          	beq	a0,a5,80002896 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002846:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000284a:	10049073          	csrw	sstatus,s1
}
    8000284e:	70a2                	ld	ra,40(sp)
    80002850:	7402                	ld	s0,32(sp)
    80002852:	64e2                	ld	s1,24(sp)
    80002854:	6942                	ld	s2,16(sp)
    80002856:	69a2                	ld	s3,8(sp)
    80002858:	6145                	addi	sp,sp,48
    8000285a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000285c:	00005517          	auipc	a0,0x5
    80002860:	a8c50513          	addi	a0,a0,-1396 # 800072e8 <etext+0x2e8>
    80002864:	f7dfd0ef          	jal	800007e0 <panic>
    panic("kerneltrap: interrupts enabled");
    80002868:	00005517          	auipc	a0,0x5
    8000286c:	aa850513          	addi	a0,a0,-1368 # 80007310 <etext+0x310>
    80002870:	f71fd0ef          	jal	800007e0 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002874:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002878:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    8000287c:	85ce                	mv	a1,s3
    8000287e:	00005517          	auipc	a0,0x5
    80002882:	ab250513          	addi	a0,a0,-1358 # 80007330 <etext+0x330>
    80002886:	c75fd0ef          	jal	800004fa <printf>
    panic("kerneltrap");
    8000288a:	00005517          	auipc	a0,0x5
    8000288e:	ace50513          	addi	a0,a0,-1330 # 80007358 <etext+0x358>
    80002892:	f4ffd0ef          	jal	800007e0 <panic>
  if(which_dev == 2 && myproc() != 0)
    80002896:	87aff0ef          	jal	80001910 <myproc>
    8000289a:	d555                	beqz	a0,80002846 <kerneltrap+0x34>
    yield();
    8000289c:	ed2ff0ef          	jal	80001f6e <yield>
    800028a0:	b75d                	j	80002846 <kerneltrap+0x34>

00000000800028a2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800028a2:	1101                	addi	sp,sp,-32
    800028a4:	ec06                	sd	ra,24(sp)
    800028a6:	e822                	sd	s0,16(sp)
    800028a8:	e426                	sd	s1,8(sp)
    800028aa:	1000                	addi	s0,sp,32
    800028ac:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800028ae:	862ff0ef          	jal	80001910 <myproc>
  switch (n) {
    800028b2:	4795                	li	a5,5
    800028b4:	0497e163          	bltu	a5,s1,800028f6 <argraw+0x54>
    800028b8:	048a                	slli	s1,s1,0x2
    800028ba:	00005717          	auipc	a4,0x5
    800028be:	fa670713          	addi	a4,a4,-90 # 80007860 <states.0+0x30>
    800028c2:	94ba                	add	s1,s1,a4
    800028c4:	409c                	lw	a5,0(s1)
    800028c6:	97ba                	add	a5,a5,a4
    800028c8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800028ca:	6d3c                	ld	a5,88(a0)
    800028cc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800028ce:	60e2                	ld	ra,24(sp)
    800028d0:	6442                	ld	s0,16(sp)
    800028d2:	64a2                	ld	s1,8(sp)
    800028d4:	6105                	addi	sp,sp,32
    800028d6:	8082                	ret
    return p->trapframe->a1;
    800028d8:	6d3c                	ld	a5,88(a0)
    800028da:	7fa8                	ld	a0,120(a5)
    800028dc:	bfcd                	j	800028ce <argraw+0x2c>
    return p->trapframe->a2;
    800028de:	6d3c                	ld	a5,88(a0)
    800028e0:	63c8                	ld	a0,128(a5)
    800028e2:	b7f5                	j	800028ce <argraw+0x2c>
    return p->trapframe->a3;
    800028e4:	6d3c                	ld	a5,88(a0)
    800028e6:	67c8                	ld	a0,136(a5)
    800028e8:	b7dd                	j	800028ce <argraw+0x2c>
    return p->trapframe->a4;
    800028ea:	6d3c                	ld	a5,88(a0)
    800028ec:	6bc8                	ld	a0,144(a5)
    800028ee:	b7c5                	j	800028ce <argraw+0x2c>
    return p->trapframe->a5;
    800028f0:	6d3c                	ld	a5,88(a0)
    800028f2:	6fc8                	ld	a0,152(a5)
    800028f4:	bfe9                	j	800028ce <argraw+0x2c>
  panic("argraw");
    800028f6:	00005517          	auipc	a0,0x5
    800028fa:	a7250513          	addi	a0,a0,-1422 # 80007368 <etext+0x368>
    800028fe:	ee3fd0ef          	jal	800007e0 <panic>

0000000080002902 <fetchaddr>:
{
    80002902:	1101                	addi	sp,sp,-32
    80002904:	ec06                	sd	ra,24(sp)
    80002906:	e822                	sd	s0,16(sp)
    80002908:	e426                	sd	s1,8(sp)
    8000290a:	e04a                	sd	s2,0(sp)
    8000290c:	1000                	addi	s0,sp,32
    8000290e:	84aa                	mv	s1,a0
    80002910:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002912:	ffffe0ef          	jal	80001910 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002916:	653c                	ld	a5,72(a0)
    80002918:	02f4f663          	bgeu	s1,a5,80002944 <fetchaddr+0x42>
    8000291c:	00848713          	addi	a4,s1,8
    80002920:	02e7e463          	bltu	a5,a4,80002948 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002924:	46a1                	li	a3,8
    80002926:	8626                	mv	a2,s1
    80002928:	85ca                	mv	a1,s2
    8000292a:	6928                	ld	a0,80(a0)
    8000292c:	dddfe0ef          	jal	80001708 <copyin>
    80002930:	00a03533          	snez	a0,a0
    80002934:	40a00533          	neg	a0,a0
}
    80002938:	60e2                	ld	ra,24(sp)
    8000293a:	6442                	ld	s0,16(sp)
    8000293c:	64a2                	ld	s1,8(sp)
    8000293e:	6902                	ld	s2,0(sp)
    80002940:	6105                	addi	sp,sp,32
    80002942:	8082                	ret
    return -1;
    80002944:	557d                	li	a0,-1
    80002946:	bfcd                	j	80002938 <fetchaddr+0x36>
    80002948:	557d                	li	a0,-1
    8000294a:	b7fd                	j	80002938 <fetchaddr+0x36>

000000008000294c <fetchstr>:
{
    8000294c:	7179                	addi	sp,sp,-48
    8000294e:	f406                	sd	ra,40(sp)
    80002950:	f022                	sd	s0,32(sp)
    80002952:	ec26                	sd	s1,24(sp)
    80002954:	e84a                	sd	s2,16(sp)
    80002956:	e44e                	sd	s3,8(sp)
    80002958:	1800                	addi	s0,sp,48
    8000295a:	892a                	mv	s2,a0
    8000295c:	84ae                	mv	s1,a1
    8000295e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002960:	fb1fe0ef          	jal	80001910 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002964:	86ce                	mv	a3,s3
    80002966:	864a                	mv	a2,s2
    80002968:	85a6                	mv	a1,s1
    8000296a:	6928                	ld	a0,80(a0)
    8000296c:	b5ffe0ef          	jal	800014ca <copyinstr>
    80002970:	00054c63          	bltz	a0,80002988 <fetchstr+0x3c>
  return strlen(buf);
    80002974:	8526                	mv	a0,s1
    80002976:	cdefe0ef          	jal	80000e54 <strlen>
}
    8000297a:	70a2                	ld	ra,40(sp)
    8000297c:	7402                	ld	s0,32(sp)
    8000297e:	64e2                	ld	s1,24(sp)
    80002980:	6942                	ld	s2,16(sp)
    80002982:	69a2                	ld	s3,8(sp)
    80002984:	6145                	addi	sp,sp,48
    80002986:	8082                	ret
    return -1;
    80002988:	557d                	li	a0,-1
    8000298a:	bfc5                	j	8000297a <fetchstr+0x2e>

000000008000298c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    8000298c:	1101                	addi	sp,sp,-32
    8000298e:	ec06                	sd	ra,24(sp)
    80002990:	e822                	sd	s0,16(sp)
    80002992:	e426                	sd	s1,8(sp)
    80002994:	1000                	addi	s0,sp,32
    80002996:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002998:	f0bff0ef          	jal	800028a2 <argraw>
    8000299c:	c088                	sw	a0,0(s1)
}
    8000299e:	60e2                	ld	ra,24(sp)
    800029a0:	6442                	ld	s0,16(sp)
    800029a2:	64a2                	ld	s1,8(sp)
    800029a4:	6105                	addi	sp,sp,32
    800029a6:	8082                	ret

00000000800029a8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800029a8:	1101                	addi	sp,sp,-32
    800029aa:	ec06                	sd	ra,24(sp)
    800029ac:	e822                	sd	s0,16(sp)
    800029ae:	e426                	sd	s1,8(sp)
    800029b0:	1000                	addi	s0,sp,32
    800029b2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800029b4:	eefff0ef          	jal	800028a2 <argraw>
    800029b8:	e088                	sd	a0,0(s1)
}
    800029ba:	60e2                	ld	ra,24(sp)
    800029bc:	6442                	ld	s0,16(sp)
    800029be:	64a2                	ld	s1,8(sp)
    800029c0:	6105                	addi	sp,sp,32
    800029c2:	8082                	ret

00000000800029c4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800029c4:	7179                	addi	sp,sp,-48
    800029c6:	f406                	sd	ra,40(sp)
    800029c8:	f022                	sd	s0,32(sp)
    800029ca:	ec26                	sd	s1,24(sp)
    800029cc:	e84a                	sd	s2,16(sp)
    800029ce:	1800                	addi	s0,sp,48
    800029d0:	84ae                	mv	s1,a1
    800029d2:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800029d4:	fd840593          	addi	a1,s0,-40
    800029d8:	fd1ff0ef          	jal	800029a8 <argaddr>
  return fetchstr(addr, buf, max);
    800029dc:	864a                	mv	a2,s2
    800029de:	85a6                	mv	a1,s1
    800029e0:	fd843503          	ld	a0,-40(s0)
    800029e4:	f69ff0ef          	jal	8000294c <fetchstr>
}
    800029e8:	70a2                	ld	ra,40(sp)
    800029ea:	7402                	ld	s0,32(sp)
    800029ec:	64e2                	ld	s1,24(sp)
    800029ee:	6942                	ld	s2,16(sp)
    800029f0:	6145                	addi	sp,sp,48
    800029f2:	8082                	ret

00000000800029f4 <syscall>:
[SYS_proclist] "proclist",
};

void
syscall(void)
{
    800029f4:	7179                	addi	sp,sp,-48
    800029f6:	f406                	sd	ra,40(sp)
    800029f8:	f022                	sd	s0,32(sp)
    800029fa:	ec26                	sd	s1,24(sp)
    800029fc:	e84a                	sd	s2,16(sp)
    800029fe:	e44e                	sd	s3,8(sp)
    80002a00:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002a02:	f0ffe0ef          	jal	80001910 <myproc>
    80002a06:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002a08:	05853903          	ld	s2,88(a0)
    80002a0c:	0a893783          	ld	a5,168(s2)
    80002a10:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002a14:	37fd                	addiw	a5,a5,-1
    80002a16:	4765                	li	a4,25
    80002a18:	04f76d63          	bltu	a4,a5,80002a72 <syscall+0x7e>
    80002a1c:	00399713          	slli	a4,s3,0x3
    80002a20:	00005797          	auipc	a5,0x5
    80002a24:	e5878793          	addi	a5,a5,-424 # 80007878 <syscalls>
    80002a28:	97ba                	add	a5,a5,a4
    80002a2a:	639c                	ld	a5,0(a5)
    80002a2c:	c3b9                	beqz	a5,80002a72 <syscall+0x7e>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002a2e:	9782                	jalr	a5
    80002a30:	06a93823          	sd	a0,112(s2)

    // Bridge-friendly trace line: emitted only when this proc has the
    // matching bit set in its trace_mask. Format is parsed by osdoc /
    // bridge.py, so the prefix and field order must stay stable.
    if(p->trace_mask & (1 << num)) {
    80002a34:	16c4a783          	lw	a5,364(s1)
    80002a38:	4137d7bb          	sraw	a5,a5,s3
    80002a3c:	8b85                	andi	a5,a5,1
    80002a3e:	c7b9                	beqz	a5,80002a8c <syscall+0x98>
      char *nm = (num < NELEM(syscall_names) && syscall_names[num])
    80002a40:	098e                	slli	s3,s3,0x3
    80002a42:	00005797          	auipc	a5,0x5
    80002a46:	e3678793          	addi	a5,a5,-458 # 80007878 <syscalls>
    80002a4a:	97ce                	add	a5,a5,s3
    80002a4c:	6ff4                	ld	a3,216(a5)
    80002a4e:	ce89                	beqz	a3,80002a68 <syscall+0x74>
                   ? syscall_names[num] : "?";
      printf("<<TRACE>> pid=%d name=%s call=%s ret=%d\n",
             p->pid, p->name, nm, (int)p->trapframe->a0);
    80002a50:	6cbc                	ld	a5,88(s1)
      printf("<<TRACE>> pid=%d name=%s call=%s ret=%d\n",
    80002a52:	5bb8                	lw	a4,112(a5)
    80002a54:	15848613          	addi	a2,s1,344
    80002a58:	588c                	lw	a1,48(s1)
    80002a5a:	00005517          	auipc	a0,0x5
    80002a5e:	91e50513          	addi	a0,a0,-1762 # 80007378 <etext+0x378>
    80002a62:	a99fd0ef          	jal	800004fa <printf>
    80002a66:	a01d                	j	80002a8c <syscall+0x98>
                   ? syscall_names[num] : "?";
    80002a68:	00005697          	auipc	a3,0x5
    80002a6c:	90868693          	addi	a3,a3,-1784 # 80007370 <etext+0x370>
    80002a70:	b7c5                	j	80002a50 <syscall+0x5c>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002a72:	86ce                	mv	a3,s3
    80002a74:	15848613          	addi	a2,s1,344
    80002a78:	588c                	lw	a1,48(s1)
    80002a7a:	00005517          	auipc	a0,0x5
    80002a7e:	92e50513          	addi	a0,a0,-1746 # 800073a8 <etext+0x3a8>
    80002a82:	a79fd0ef          	jal	800004fa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002a86:	6cbc                	ld	a5,88(s1)
    80002a88:	577d                	li	a4,-1
    80002a8a:	fbb8                	sd	a4,112(a5)
  }
}
    80002a8c:	70a2                	ld	ra,40(sp)
    80002a8e:	7402                	ld	s0,32(sp)
    80002a90:	64e2                	ld	s1,24(sp)
    80002a92:	6942                	ld	s2,16(sp)
    80002a94:	69a2                	ld	s3,8(sp)
    80002a96:	6145                	addi	sp,sp,48
    80002a98:	8082                	ret

0000000080002a9a <sys_exit>:
// Sized to NPROC (param.h) so a single snapshot covers the whole table.
#define PROCLIST_MAX NPROC

uint64
sys_exit(void)
{
    80002a9a:	1101                	addi	sp,sp,-32
    80002a9c:	ec06                	sd	ra,24(sp)
    80002a9e:	e822                	sd	s0,16(sp)
    80002aa0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002aa2:	fec40593          	addi	a1,s0,-20
    80002aa6:	4501                	li	a0,0
    80002aa8:	ee5ff0ef          	jal	8000298c <argint>
  kexit(n);
    80002aac:	fec42503          	lw	a0,-20(s0)
    80002ab0:	df6ff0ef          	jal	800020a6 <kexit>
  return 0;  // not reached
}
    80002ab4:	4501                	li	a0,0
    80002ab6:	60e2                	ld	ra,24(sp)
    80002ab8:	6442                	ld	s0,16(sp)
    80002aba:	6105                	addi	sp,sp,32
    80002abc:	8082                	ret

0000000080002abe <sys_getpid>:

uint64
sys_getpid(void)
{
    80002abe:	1141                	addi	sp,sp,-16
    80002ac0:	e406                	sd	ra,8(sp)
    80002ac2:	e022                	sd	s0,0(sp)
    80002ac4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ac6:	e4bfe0ef          	jal	80001910 <myproc>
}
    80002aca:	5908                	lw	a0,48(a0)
    80002acc:	60a2                	ld	ra,8(sp)
    80002ace:	6402                	ld	s0,0(sp)
    80002ad0:	0141                	addi	sp,sp,16
    80002ad2:	8082                	ret

0000000080002ad4 <sys_fork>:

uint64
sys_fork(void)
{
    80002ad4:	1141                	addi	sp,sp,-16
    80002ad6:	e406                	sd	ra,8(sp)
    80002ad8:	e022                	sd	s0,0(sp)
    80002ada:	0800                	addi	s0,sp,16
  return kfork();
    80002adc:	9baff0ef          	jal	80001c96 <kfork>
}
    80002ae0:	60a2                	ld	ra,8(sp)
    80002ae2:	6402                	ld	s0,0(sp)
    80002ae4:	0141                	addi	sp,sp,16
    80002ae6:	8082                	ret

0000000080002ae8 <sys_wait>:

uint64
sys_wait(void)
{
    80002ae8:	1101                	addi	sp,sp,-32
    80002aea:	ec06                	sd	ra,24(sp)
    80002aec:	e822                	sd	s0,16(sp)
    80002aee:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002af0:	fe840593          	addi	a1,s0,-24
    80002af4:	4501                	li	a0,0
    80002af6:	eb3ff0ef          	jal	800029a8 <argaddr>
  return kwait(p);
    80002afa:	fe843503          	ld	a0,-24(s0)
    80002afe:	efeff0ef          	jal	800021fc <kwait>
}
    80002b02:	60e2                	ld	ra,24(sp)
    80002b04:	6442                	ld	s0,16(sp)
    80002b06:	6105                	addi	sp,sp,32
    80002b08:	8082                	ret

0000000080002b0a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002b0a:	7179                	addi	sp,sp,-48
    80002b0c:	f406                	sd	ra,40(sp)
    80002b0e:	f022                	sd	s0,32(sp)
    80002b10:	ec26                	sd	s1,24(sp)
    80002b12:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    80002b14:	fd840593          	addi	a1,s0,-40
    80002b18:	4501                	li	a0,0
    80002b1a:	e73ff0ef          	jal	8000298c <argint>
  argint(1, &t);
    80002b1e:	fdc40593          	addi	a1,s0,-36
    80002b22:	4505                	li	a0,1
    80002b24:	e69ff0ef          	jal	8000298c <argint>
  addr = myproc()->sz;
    80002b28:	de9fe0ef          	jal	80001910 <myproc>
    80002b2c:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    80002b2e:	fdc42703          	lw	a4,-36(s0)
    80002b32:	4785                	li	a5,1
    80002b34:	02f70763          	beq	a4,a5,80002b62 <sys_sbrk+0x58>
    80002b38:	fd842783          	lw	a5,-40(s0)
    80002b3c:	0207c363          	bltz	a5,80002b62 <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    80002b40:	97a6                	add	a5,a5,s1
    80002b42:	0297ee63          	bltu	a5,s1,80002b7e <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    80002b46:	02000737          	lui	a4,0x2000
    80002b4a:	177d                	addi	a4,a4,-1 # 1ffffff <_entry-0x7e000001>
    80002b4c:	0736                	slli	a4,a4,0xd
    80002b4e:	02f76a63          	bltu	a4,a5,80002b82 <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    80002b52:	dbffe0ef          	jal	80001910 <myproc>
    80002b56:	fd842703          	lw	a4,-40(s0)
    80002b5a:	653c                	ld	a5,72(a0)
    80002b5c:	97ba                	add	a5,a5,a4
    80002b5e:	e53c                	sd	a5,72(a0)
    80002b60:	a039                	j	80002b6e <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    80002b62:	fd842503          	lw	a0,-40(s0)
    80002b66:	8ceff0ef          	jal	80001c34 <growproc>
    80002b6a:	00054863          	bltz	a0,80002b7a <sys_sbrk+0x70>
  }
  return addr;
}
    80002b6e:	8526                	mv	a0,s1
    80002b70:	70a2                	ld	ra,40(sp)
    80002b72:	7402                	ld	s0,32(sp)
    80002b74:	64e2                	ld	s1,24(sp)
    80002b76:	6145                	addi	sp,sp,48
    80002b78:	8082                	ret
      return -1;
    80002b7a:	54fd                	li	s1,-1
    80002b7c:	bfcd                	j	80002b6e <sys_sbrk+0x64>
      return -1;
    80002b7e:	54fd                	li	s1,-1
    80002b80:	b7fd                	j	80002b6e <sys_sbrk+0x64>
      return -1;
    80002b82:	54fd                	li	s1,-1
    80002b84:	b7ed                	j	80002b6e <sys_sbrk+0x64>

0000000080002b86 <sys_pause>:

uint64
sys_pause(void)
{
    80002b86:	7139                	addi	sp,sp,-64
    80002b88:	fc06                	sd	ra,56(sp)
    80002b8a:	f822                	sd	s0,48(sp)
    80002b8c:	f04a                	sd	s2,32(sp)
    80002b8e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002b90:	fcc40593          	addi	a1,s0,-52
    80002b94:	4501                	li	a0,0
    80002b96:	df7ff0ef          	jal	8000298c <argint>
  if(n < 0)
    80002b9a:	fcc42783          	lw	a5,-52(s0)
    80002b9e:	0607c763          	bltz	a5,80002c0c <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    80002ba2:	00016517          	auipc	a0,0x16
    80002ba6:	ef650513          	addi	a0,a0,-266 # 80018a98 <tickslock>
    80002baa:	866fe0ef          	jal	80000c10 <acquire>
  ticks0 = ticks;
    80002bae:	00008917          	auipc	s2,0x8
    80002bb2:	9ba92903          	lw	s2,-1606(s2) # 8000a568 <ticks>
  while(ticks - ticks0 < n){
    80002bb6:	fcc42783          	lw	a5,-52(s0)
    80002bba:	cf8d                	beqz	a5,80002bf4 <sys_pause+0x6e>
    80002bbc:	f426                	sd	s1,40(sp)
    80002bbe:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002bc0:	00016997          	auipc	s3,0x16
    80002bc4:	ed898993          	addi	s3,s3,-296 # 80018a98 <tickslock>
    80002bc8:	00008497          	auipc	s1,0x8
    80002bcc:	9a048493          	addi	s1,s1,-1632 # 8000a568 <ticks>
    if(killed(myproc())){
    80002bd0:	d41fe0ef          	jal	80001910 <myproc>
    80002bd4:	dfeff0ef          	jal	800021d2 <killed>
    80002bd8:	ed0d                	bnez	a0,80002c12 <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80002bda:	85ce                	mv	a1,s3
    80002bdc:	8526                	mv	a0,s1
    80002bde:	bbcff0ef          	jal	80001f9a <sleep>
  while(ticks - ticks0 < n){
    80002be2:	409c                	lw	a5,0(s1)
    80002be4:	412787bb          	subw	a5,a5,s2
    80002be8:	fcc42703          	lw	a4,-52(s0)
    80002bec:	fee7e2e3          	bltu	a5,a4,80002bd0 <sys_pause+0x4a>
    80002bf0:	74a2                	ld	s1,40(sp)
    80002bf2:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002bf4:	00016517          	auipc	a0,0x16
    80002bf8:	ea450513          	addi	a0,a0,-348 # 80018a98 <tickslock>
    80002bfc:	8acfe0ef          	jal	80000ca8 <release>
  return 0;
    80002c00:	4501                	li	a0,0
}
    80002c02:	70e2                	ld	ra,56(sp)
    80002c04:	7442                	ld	s0,48(sp)
    80002c06:	7902                	ld	s2,32(sp)
    80002c08:	6121                	addi	sp,sp,64
    80002c0a:	8082                	ret
    n = 0;
    80002c0c:	fc042623          	sw	zero,-52(s0)
    80002c10:	bf49                	j	80002ba2 <sys_pause+0x1c>
      release(&tickslock);
    80002c12:	00016517          	auipc	a0,0x16
    80002c16:	e8650513          	addi	a0,a0,-378 # 80018a98 <tickslock>
    80002c1a:	88efe0ef          	jal	80000ca8 <release>
      return -1;
    80002c1e:	557d                	li	a0,-1
    80002c20:	74a2                	ld	s1,40(sp)
    80002c22:	69e2                	ld	s3,24(sp)
    80002c24:	bff9                	j	80002c02 <sys_pause+0x7c>

0000000080002c26 <sys_kill>:

uint64
sys_kill(void)
{
    80002c26:	1101                	addi	sp,sp,-32
    80002c28:	ec06                	sd	ra,24(sp)
    80002c2a:	e822                	sd	s0,16(sp)
    80002c2c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002c2e:	fec40593          	addi	a1,s0,-20
    80002c32:	4501                	li	a0,0
    80002c34:	d59ff0ef          	jal	8000298c <argint>
  return kkill(pid);
    80002c38:	fec42503          	lw	a0,-20(s0)
    80002c3c:	d0cff0ef          	jal	80002148 <kkill>
}
    80002c40:	60e2                	ld	ra,24(sp)
    80002c42:	6442                	ld	s0,16(sp)
    80002c44:	6105                	addi	sp,sp,32
    80002c46:	8082                	ret

0000000080002c48 <sys_setpriority>:

uint64
sys_setpriority(void)
{
    80002c48:	7179                	addi	sp,sp,-48
    80002c4a:	f406                	sd	ra,40(sp)
    80002c4c:	f022                	sd	s0,32(sp)
    80002c4e:	1800                	addi	s0,sp,48
  int pid, priority;

  argint(0, &pid);
    80002c50:	fdc40593          	addi	a1,s0,-36
    80002c54:	4501                	li	a0,0
    80002c56:	d37ff0ef          	jal	8000298c <argint>
  argint(1, &priority);
    80002c5a:	fd840593          	addi	a1,s0,-40
    80002c5e:	4505                	li	a0,1
    80002c60:	d2dff0ef          	jal	8000298c <argint>

  // Validate priority range [0, 20]
  if(priority < 0 || priority > 20)
    80002c64:	fd842703          	lw	a4,-40(s0)
    80002c68:	47d1                	li	a5,20
    return -1;
    80002c6a:	557d                	li	a0,-1
  if(priority < 0 || priority > 20)
    80002c6c:	04e7e963          	bltu	a5,a4,80002cbe <sys_setpriority+0x76>
    80002c70:	ec26                	sd	s1,24(sp)
    80002c72:	e84a                	sd	s2,16(sp)

  // Find the process with the given pid and set its priority
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    80002c74:	00010497          	auipc	s1,0x10
    80002c78:	e2448493          	addi	s1,s1,-476 # 80012a98 <proc>
    80002c7c:	00016917          	auipc	s2,0x16
    80002c80:	e1c90913          	addi	s2,s2,-484 # 80018a98 <tickslock>
    acquire(&p->lock);
    80002c84:	8526                	mv	a0,s1
    80002c86:	f8bfd0ef          	jal	80000c10 <acquire>
    if(p->pid == pid) {
    80002c8a:	5898                	lw	a4,48(s1)
    80002c8c:	fdc42783          	lw	a5,-36(s0)
    80002c90:	00f70d63          	beq	a4,a5,80002caa <sys_setpriority+0x62>
      p->priority = priority;
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002c94:	8526                	mv	a0,s1
    80002c96:	812fe0ef          	jal	80000ca8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002c9a:	18048493          	addi	s1,s1,384
    80002c9e:	ff2493e3          	bne	s1,s2,80002c84 <sys_setpriority+0x3c>
  }
  return -1;  // pid not found
    80002ca2:	557d                	li	a0,-1
    80002ca4:	64e2                	ld	s1,24(sp)
    80002ca6:	6942                	ld	s2,16(sp)
    80002ca8:	a819                	j	80002cbe <sys_setpriority+0x76>
      p->priority = priority;
    80002caa:	fd842783          	lw	a5,-40(s0)
    80002cae:	16f4a423          	sw	a5,360(s1)
      release(&p->lock);
    80002cb2:	8526                	mv	a0,s1
    80002cb4:	ff5fd0ef          	jal	80000ca8 <release>
      return 0;
    80002cb8:	4501                	li	a0,0
    80002cba:	64e2                	ld	s1,24(sp)
    80002cbc:	6942                	ld	s2,16(sp)
}
    80002cbe:	70a2                	ld	ra,40(sp)
    80002cc0:	7402                	ld	s0,32(sp)
    80002cc2:	6145                	addi	sp,sp,48
    80002cc4:	8082                	ret

0000000080002cc6 <sys_getpriority>:

uint64
sys_getpriority(void)
{
    80002cc6:	7179                	addi	sp,sp,-48
    80002cc8:	f406                	sd	ra,40(sp)
    80002cca:	f022                	sd	s0,32(sp)
    80002ccc:	ec26                	sd	s1,24(sp)
    80002cce:	e84a                	sd	s2,16(sp)
    80002cd0:	1800                	addi	s0,sp,48
  int pid;

  argint(0, &pid);
    80002cd2:	fdc40593          	addi	a1,s0,-36
    80002cd6:	4501                	li	a0,0
    80002cd8:	cb5ff0ef          	jal	8000298c <argint>

  // Find the process with the given pid and return its priority
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    80002cdc:	00010497          	auipc	s1,0x10
    80002ce0:	dbc48493          	addi	s1,s1,-580 # 80012a98 <proc>
    80002ce4:	00016917          	auipc	s2,0x16
    80002ce8:	db490913          	addi	s2,s2,-588 # 80018a98 <tickslock>
    acquire(&p->lock);
    80002cec:	8526                	mv	a0,s1
    80002cee:	f23fd0ef          	jal	80000c10 <acquire>
    if(p->pid == pid) {
    80002cf2:	5898                	lw	a4,48(s1)
    80002cf4:	fdc42783          	lw	a5,-36(s0)
    80002cf8:	00f70b63          	beq	a4,a5,80002d0e <sys_getpriority+0x48>
      int prio = p->priority;
      release(&p->lock);
      return prio;
    }
    release(&p->lock);
    80002cfc:	8526                	mv	a0,s1
    80002cfe:	fabfd0ef          	jal	80000ca8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002d02:	18048493          	addi	s1,s1,384
    80002d06:	ff2493e3          	bne	s1,s2,80002cec <sys_getpriority+0x26>
  }
  return -1;  // pid not found
    80002d0a:	557d                	li	a0,-1
    80002d0c:	a039                	j	80002d1a <sys_getpriority+0x54>
      int prio = p->priority;
    80002d0e:	1684a903          	lw	s2,360(s1)
      release(&p->lock);
    80002d12:	8526                	mv	a0,s1
    80002d14:	f95fd0ef          	jal	80000ca8 <release>
      return prio;
    80002d18:	854a                	mv	a0,s2
}
    80002d1a:	70a2                	ld	ra,40(sp)
    80002d1c:	7402                	ld	s0,32(sp)
    80002d1e:	64e2                	ld	s1,24(sp)
    80002d20:	6942                	ld	s2,16(sp)
    80002d22:	6145                	addi	sp,sp,48
    80002d24:	8082                	ret

0000000080002d26 <sys_trace>:
// Set the calling process's syscall trace mask.
// `mask` is a bitmap indexed by SYS_* numbers; bit n set means "log
// every invocation of syscall number n by this proc and its children".
uint64
sys_trace(void)
{
    80002d26:	1101                	addi	sp,sp,-32
    80002d28:	ec06                	sd	ra,24(sp)
    80002d2a:	e822                	sd	s0,16(sp)
    80002d2c:	1000                	addi	s0,sp,32
  int mask;
  argint(0, &mask);
    80002d2e:	fec40593          	addi	a1,s0,-20
    80002d32:	4501                	li	a0,0
    80002d34:	c59ff0ef          	jal	8000298c <argint>
  myproc()->trace_mask = mask;
    80002d38:	bd9fe0ef          	jal	80001910 <myproc>
    80002d3c:	fec42783          	lw	a5,-20(s0)
    80002d40:	16f52623          	sw	a5,364(a0)
  return 0;
}
    80002d44:	4501                	li	a0,0
    80002d46:	60e2                	ld	ra,24(sp)
    80002d48:	6442                	ld	s0,16(sp)
    80002d4a:	6105                	addi	sp,sp,32
    80002d4c:	8082                	ret

0000000080002d4e <sys_sysinfo>:

// Copy a sysinfo struct (free memory + active proc count) to userspace.
uint64
sys_sysinfo(void)
{
    80002d4e:	7179                	addi	sp,sp,-48
    80002d50:	f406                	sd	ra,40(sp)
    80002d52:	f022                	sd	s0,32(sp)
    80002d54:	1800                	addi	s0,sp,48
  struct sysinfo info;
  uint64 addr;

  argaddr(0, &addr);
    80002d56:	fd840593          	addi	a1,s0,-40
    80002d5a:	4501                	li	a0,0
    80002d5c:	c4dff0ef          	jal	800029a8 <argaddr>
  info.freemem = freemem_count();
    80002d60:	deffd0ef          	jal	80000b4e <freemem_count>
    80002d64:	fea43023          	sd	a0,-32(s0)
  info.nproc = proc_count();
    80002d68:	e22ff0ef          	jal	8000238a <proc_count>
    80002d6c:	fea43423          	sd	a0,-24(s0)
  if(copyout(myproc()->pagetable, addr, (char *)&info, sizeof(info)) < 0)
    80002d70:	ba1fe0ef          	jal	80001910 <myproc>
    80002d74:	46c1                	li	a3,16
    80002d76:	fe040613          	addi	a2,s0,-32
    80002d7a:	fd843583          	ld	a1,-40(s0)
    80002d7e:	6928                	ld	a0,80(a0)
    80002d80:	8a5fe0ef          	jal	80001624 <copyout>
    return -1;
  return 0;
}
    80002d84:	957d                	srai	a0,a0,0x3f
    80002d86:	70a2                	ld	ra,40(sp)
    80002d88:	7402                	ld	s0,32(sp)
    80002d8a:	6145                	addi	sp,sp,48
    80002d8c:	8082                	ret

0000000080002d8e <sys_proclist>:
//   arg0: user pointer to struct proc_info[]
//   arg1: max number of entries the caller's buffer can hold
// Returns the number of entries written, or -1 on copyout failure.
uint64
sys_proclist(void)
{
    80002d8e:	7179                	addi	sp,sp,-48
    80002d90:	f406                	sd	ra,40(sp)
    80002d92:	f022                	sd	s0,32(sp)
    80002d94:	e84a                	sd	s2,16(sp)
    80002d96:	1800                	addi	s0,sp,48
  uint64 uaddr;
  int max;
  static struct proc_info buf[PROCLIST_MAX];
  int n;

  argaddr(0, &uaddr);
    80002d98:	fd840593          	addi	a1,s0,-40
    80002d9c:	4501                	li	a0,0
    80002d9e:	c0bff0ef          	jal	800029a8 <argaddr>
  argint(1, &max);
    80002da2:	fd440593          	addi	a1,s0,-44
    80002da6:	4505                	li	a0,1
    80002da8:	be5ff0ef          	jal	8000298c <argint>
  if(max <= 0)
    80002dac:	fd442783          	lw	a5,-44(s0)
    return 0;
    80002db0:	4901                	li	s2,0
  if(max <= 0)
    80002db2:	04f05763          	blez	a5,80002e00 <sys_proclist+0x72>
    80002db6:	ec26                	sd	s1,24(sp)
  if(max > PROCLIST_MAX)
    80002db8:	04000713          	li	a4,64
    80002dbc:	00f75663          	bge	a4,a5,80002dc8 <sys_proclist+0x3a>
    max = PROCLIST_MAX;
    80002dc0:	04000793          	li	a5,64
    80002dc4:	fcf42a23          	sw	a5,-44(s0)

  n = proclist_fill(buf, max);
    80002dc8:	fd442583          	lw	a1,-44(s0)
    80002dcc:	00016517          	auipc	a0,0x16
    80002dd0:	ce450513          	addi	a0,a0,-796 # 80018ab0 <buf.0>
    80002dd4:	e02ff0ef          	jal	800023d6 <proclist_fill>
    80002dd8:	84aa                	mv	s1,a0
  if(copyout(myproc()->pagetable, uaddr,
    80002dda:	b37fe0ef          	jal	80001910 <myproc>
    80002dde:	8926                	mv	s2,s1
    80002de0:	00149693          	slli	a3,s1,0x1
    80002de4:	96a6                	add	a3,a3,s1
    80002de6:	0692                	slli	a3,a3,0x4
    80002de8:	00016617          	auipc	a2,0x16
    80002dec:	cc860613          	addi	a2,a2,-824 # 80018ab0 <buf.0>
    80002df0:	fd843583          	ld	a1,-40(s0)
    80002df4:	6928                	ld	a0,80(a0)
    80002df6:	82ffe0ef          	jal	80001624 <copyout>
    80002dfa:	00054963          	bltz	a0,80002e0c <sys_proclist+0x7e>
    80002dfe:	64e2                	ld	s1,24(sp)
             (char *)buf, n * sizeof(struct proc_info)) < 0)
    return -1;
  return n;
}
    80002e00:	854a                	mv	a0,s2
    80002e02:	70a2                	ld	ra,40(sp)
    80002e04:	7402                	ld	s0,32(sp)
    80002e06:	6942                	ld	s2,16(sp)
    80002e08:	6145                	addi	sp,sp,48
    80002e0a:	8082                	ret
    return -1;
    80002e0c:	597d                	li	s2,-1
    80002e0e:	64e2                	ld	s1,24(sp)
    80002e10:	bfc5                	j	80002e00 <sys_proclist+0x72>

0000000080002e12 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e12:	1101                	addi	sp,sp,-32
    80002e14:	ec06                	sd	ra,24(sp)
    80002e16:	e822                	sd	s0,16(sp)
    80002e18:	e426                	sd	s1,8(sp)
    80002e1a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e1c:	00016517          	auipc	a0,0x16
    80002e20:	c7c50513          	addi	a0,a0,-900 # 80018a98 <tickslock>
    80002e24:	dedfd0ef          	jal	80000c10 <acquire>
  xticks = ticks;
    80002e28:	00007497          	auipc	s1,0x7
    80002e2c:	7404a483          	lw	s1,1856(s1) # 8000a568 <ticks>
  release(&tickslock);
    80002e30:	00016517          	auipc	a0,0x16
    80002e34:	c6850513          	addi	a0,a0,-920 # 80018a98 <tickslock>
    80002e38:	e71fd0ef          	jal	80000ca8 <release>
  return xticks;
}
    80002e3c:	02049513          	slli	a0,s1,0x20
    80002e40:	9101                	srli	a0,a0,0x20
    80002e42:	60e2                	ld	ra,24(sp)
    80002e44:	6442                	ld	s0,16(sp)
    80002e46:	64a2                	ld	s1,8(sp)
    80002e48:	6105                	addi	sp,sp,32
    80002e4a:	8082                	ret

0000000080002e4c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e4c:	7179                	addi	sp,sp,-48
    80002e4e:	f406                	sd	ra,40(sp)
    80002e50:	f022                	sd	s0,32(sp)
    80002e52:	ec26                	sd	s1,24(sp)
    80002e54:	e84a                	sd	s2,16(sp)
    80002e56:	e44e                	sd	s3,8(sp)
    80002e58:	e052                	sd	s4,0(sp)
    80002e5a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e5c:	00004597          	auipc	a1,0x4
    80002e60:	64458593          	addi	a1,a1,1604 # 800074a0 <etext+0x4a0>
    80002e64:	00017517          	auipc	a0,0x17
    80002e68:	84c50513          	addi	a0,a0,-1972 # 800196b0 <bcache>
    80002e6c:	d25fd0ef          	jal	80000b90 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e70:	0001f797          	auipc	a5,0x1f
    80002e74:	84078793          	addi	a5,a5,-1984 # 800216b0 <bcache+0x8000>
    80002e78:	0001f717          	auipc	a4,0x1f
    80002e7c:	aa070713          	addi	a4,a4,-1376 # 80021918 <bcache+0x8268>
    80002e80:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e84:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e88:	00017497          	auipc	s1,0x17
    80002e8c:	84048493          	addi	s1,s1,-1984 # 800196c8 <bcache+0x18>
    b->next = bcache.head.next;
    80002e90:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e92:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e94:	00004a17          	auipc	s4,0x4
    80002e98:	614a0a13          	addi	s4,s4,1556 # 800074a8 <etext+0x4a8>
    b->next = bcache.head.next;
    80002e9c:	2b893783          	ld	a5,696(s2)
    80002ea0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ea2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ea6:	85d2                	mv	a1,s4
    80002ea8:	01048513          	addi	a0,s1,16
    80002eac:	322010ef          	jal	800041ce <initsleeplock>
    bcache.head.next->prev = b;
    80002eb0:	2b893783          	ld	a5,696(s2)
    80002eb4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002eb6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eba:	45848493          	addi	s1,s1,1112
    80002ebe:	fd349fe3          	bne	s1,s3,80002e9c <binit+0x50>
  }
}
    80002ec2:	70a2                	ld	ra,40(sp)
    80002ec4:	7402                	ld	s0,32(sp)
    80002ec6:	64e2                	ld	s1,24(sp)
    80002ec8:	6942                	ld	s2,16(sp)
    80002eca:	69a2                	ld	s3,8(sp)
    80002ecc:	6a02                	ld	s4,0(sp)
    80002ece:	6145                	addi	sp,sp,48
    80002ed0:	8082                	ret

0000000080002ed2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ed2:	7179                	addi	sp,sp,-48
    80002ed4:	f406                	sd	ra,40(sp)
    80002ed6:	f022                	sd	s0,32(sp)
    80002ed8:	ec26                	sd	s1,24(sp)
    80002eda:	e84a                	sd	s2,16(sp)
    80002edc:	e44e                	sd	s3,8(sp)
    80002ede:	1800                	addi	s0,sp,48
    80002ee0:	892a                	mv	s2,a0
    80002ee2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ee4:	00016517          	auipc	a0,0x16
    80002ee8:	7cc50513          	addi	a0,a0,1996 # 800196b0 <bcache>
    80002eec:	d25fd0ef          	jal	80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ef0:	0001f497          	auipc	s1,0x1f
    80002ef4:	a784b483          	ld	s1,-1416(s1) # 80021968 <bcache+0x82b8>
    80002ef8:	0001f797          	auipc	a5,0x1f
    80002efc:	a2078793          	addi	a5,a5,-1504 # 80021918 <bcache+0x8268>
    80002f00:	02f48b63          	beq	s1,a5,80002f36 <bread+0x64>
    80002f04:	873e                	mv	a4,a5
    80002f06:	a021                	j	80002f0e <bread+0x3c>
    80002f08:	68a4                	ld	s1,80(s1)
    80002f0a:	02e48663          	beq	s1,a4,80002f36 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002f0e:	449c                	lw	a5,8(s1)
    80002f10:	ff279ce3          	bne	a5,s2,80002f08 <bread+0x36>
    80002f14:	44dc                	lw	a5,12(s1)
    80002f16:	ff3799e3          	bne	a5,s3,80002f08 <bread+0x36>
      b->refcnt++;
    80002f1a:	40bc                	lw	a5,64(s1)
    80002f1c:	2785                	addiw	a5,a5,1
    80002f1e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f20:	00016517          	auipc	a0,0x16
    80002f24:	79050513          	addi	a0,a0,1936 # 800196b0 <bcache>
    80002f28:	d81fd0ef          	jal	80000ca8 <release>
      acquiresleep(&b->lock);
    80002f2c:	01048513          	addi	a0,s1,16
    80002f30:	2d4010ef          	jal	80004204 <acquiresleep>
      return b;
    80002f34:	a889                	j	80002f86 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f36:	0001f497          	auipc	s1,0x1f
    80002f3a:	a2a4b483          	ld	s1,-1494(s1) # 80021960 <bcache+0x82b0>
    80002f3e:	0001f797          	auipc	a5,0x1f
    80002f42:	9da78793          	addi	a5,a5,-1574 # 80021918 <bcache+0x8268>
    80002f46:	00f48863          	beq	s1,a5,80002f56 <bread+0x84>
    80002f4a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f4c:	40bc                	lw	a5,64(s1)
    80002f4e:	cb91                	beqz	a5,80002f62 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f50:	64a4                	ld	s1,72(s1)
    80002f52:	fee49de3          	bne	s1,a4,80002f4c <bread+0x7a>
  panic("bget: no buffers");
    80002f56:	00004517          	auipc	a0,0x4
    80002f5a:	55a50513          	addi	a0,a0,1370 # 800074b0 <etext+0x4b0>
    80002f5e:	883fd0ef          	jal	800007e0 <panic>
      b->dev = dev;
    80002f62:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f66:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f6a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f6e:	4785                	li	a5,1
    80002f70:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f72:	00016517          	auipc	a0,0x16
    80002f76:	73e50513          	addi	a0,a0,1854 # 800196b0 <bcache>
    80002f7a:	d2ffd0ef          	jal	80000ca8 <release>
      acquiresleep(&b->lock);
    80002f7e:	01048513          	addi	a0,s1,16
    80002f82:	282010ef          	jal	80004204 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f86:	409c                	lw	a5,0(s1)
    80002f88:	cb89                	beqz	a5,80002f9a <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f8a:	8526                	mv	a0,s1
    80002f8c:	70a2                	ld	ra,40(sp)
    80002f8e:	7402                	ld	s0,32(sp)
    80002f90:	64e2                	ld	s1,24(sp)
    80002f92:	6942                	ld	s2,16(sp)
    80002f94:	69a2                	ld	s3,8(sp)
    80002f96:	6145                	addi	sp,sp,48
    80002f98:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f9a:	4581                	li	a1,0
    80002f9c:	8526                	mv	a0,s1
    80002f9e:	2d3020ef          	jal	80005a70 <virtio_disk_rw>
    b->valid = 1;
    80002fa2:	4785                	li	a5,1
    80002fa4:	c09c                	sw	a5,0(s1)
  return b;
    80002fa6:	b7d5                	j	80002f8a <bread+0xb8>

0000000080002fa8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fa8:	1101                	addi	sp,sp,-32
    80002faa:	ec06                	sd	ra,24(sp)
    80002fac:	e822                	sd	s0,16(sp)
    80002fae:	e426                	sd	s1,8(sp)
    80002fb0:	1000                	addi	s0,sp,32
    80002fb2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fb4:	0541                	addi	a0,a0,16
    80002fb6:	2cc010ef          	jal	80004282 <holdingsleep>
    80002fba:	c911                	beqz	a0,80002fce <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fbc:	4585                	li	a1,1
    80002fbe:	8526                	mv	a0,s1
    80002fc0:	2b1020ef          	jal	80005a70 <virtio_disk_rw>
}
    80002fc4:	60e2                	ld	ra,24(sp)
    80002fc6:	6442                	ld	s0,16(sp)
    80002fc8:	64a2                	ld	s1,8(sp)
    80002fca:	6105                	addi	sp,sp,32
    80002fcc:	8082                	ret
    panic("bwrite");
    80002fce:	00004517          	auipc	a0,0x4
    80002fd2:	4fa50513          	addi	a0,a0,1274 # 800074c8 <etext+0x4c8>
    80002fd6:	80bfd0ef          	jal	800007e0 <panic>

0000000080002fda <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fda:	1101                	addi	sp,sp,-32
    80002fdc:	ec06                	sd	ra,24(sp)
    80002fde:	e822                	sd	s0,16(sp)
    80002fe0:	e426                	sd	s1,8(sp)
    80002fe2:	e04a                	sd	s2,0(sp)
    80002fe4:	1000                	addi	s0,sp,32
    80002fe6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fe8:	01050913          	addi	s2,a0,16
    80002fec:	854a                	mv	a0,s2
    80002fee:	294010ef          	jal	80004282 <holdingsleep>
    80002ff2:	c135                	beqz	a0,80003056 <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    80002ff4:	854a                	mv	a0,s2
    80002ff6:	254010ef          	jal	8000424a <releasesleep>

  acquire(&bcache.lock);
    80002ffa:	00016517          	auipc	a0,0x16
    80002ffe:	6b650513          	addi	a0,a0,1718 # 800196b0 <bcache>
    80003002:	c0ffd0ef          	jal	80000c10 <acquire>
  b->refcnt--;
    80003006:	40bc                	lw	a5,64(s1)
    80003008:	37fd                	addiw	a5,a5,-1
    8000300a:	0007871b          	sext.w	a4,a5
    8000300e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003010:	e71d                	bnez	a4,8000303e <brelse+0x64>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003012:	68b8                	ld	a4,80(s1)
    80003014:	64bc                	ld	a5,72(s1)
    80003016:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003018:	68b8                	ld	a4,80(s1)
    8000301a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000301c:	0001e797          	auipc	a5,0x1e
    80003020:	69478793          	addi	a5,a5,1684 # 800216b0 <bcache+0x8000>
    80003024:	2b87b703          	ld	a4,696(a5)
    80003028:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000302a:	0001f717          	auipc	a4,0x1f
    8000302e:	8ee70713          	addi	a4,a4,-1810 # 80021918 <bcache+0x8268>
    80003032:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003034:	2b87b703          	ld	a4,696(a5)
    80003038:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000303a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000303e:	00016517          	auipc	a0,0x16
    80003042:	67250513          	addi	a0,a0,1650 # 800196b0 <bcache>
    80003046:	c63fd0ef          	jal	80000ca8 <release>
}
    8000304a:	60e2                	ld	ra,24(sp)
    8000304c:	6442                	ld	s0,16(sp)
    8000304e:	64a2                	ld	s1,8(sp)
    80003050:	6902                	ld	s2,0(sp)
    80003052:	6105                	addi	sp,sp,32
    80003054:	8082                	ret
    panic("brelse");
    80003056:	00004517          	auipc	a0,0x4
    8000305a:	47a50513          	addi	a0,a0,1146 # 800074d0 <etext+0x4d0>
    8000305e:	f82fd0ef          	jal	800007e0 <panic>

0000000080003062 <bpin>:

void
bpin(struct buf *b) {
    80003062:	1101                	addi	sp,sp,-32
    80003064:	ec06                	sd	ra,24(sp)
    80003066:	e822                	sd	s0,16(sp)
    80003068:	e426                	sd	s1,8(sp)
    8000306a:	1000                	addi	s0,sp,32
    8000306c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000306e:	00016517          	auipc	a0,0x16
    80003072:	64250513          	addi	a0,a0,1602 # 800196b0 <bcache>
    80003076:	b9bfd0ef          	jal	80000c10 <acquire>
  b->refcnt++;
    8000307a:	40bc                	lw	a5,64(s1)
    8000307c:	2785                	addiw	a5,a5,1
    8000307e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003080:	00016517          	auipc	a0,0x16
    80003084:	63050513          	addi	a0,a0,1584 # 800196b0 <bcache>
    80003088:	c21fd0ef          	jal	80000ca8 <release>
}
    8000308c:	60e2                	ld	ra,24(sp)
    8000308e:	6442                	ld	s0,16(sp)
    80003090:	64a2                	ld	s1,8(sp)
    80003092:	6105                	addi	sp,sp,32
    80003094:	8082                	ret

0000000080003096 <bunpin>:

void
bunpin(struct buf *b) {
    80003096:	1101                	addi	sp,sp,-32
    80003098:	ec06                	sd	ra,24(sp)
    8000309a:	e822                	sd	s0,16(sp)
    8000309c:	e426                	sd	s1,8(sp)
    8000309e:	1000                	addi	s0,sp,32
    800030a0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030a2:	00016517          	auipc	a0,0x16
    800030a6:	60e50513          	addi	a0,a0,1550 # 800196b0 <bcache>
    800030aa:	b67fd0ef          	jal	80000c10 <acquire>
  b->refcnt--;
    800030ae:	40bc                	lw	a5,64(s1)
    800030b0:	37fd                	addiw	a5,a5,-1
    800030b2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030b4:	00016517          	auipc	a0,0x16
    800030b8:	5fc50513          	addi	a0,a0,1532 # 800196b0 <bcache>
    800030bc:	bedfd0ef          	jal	80000ca8 <release>
}
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	64a2                	ld	s1,8(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret

00000000800030ca <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030ca:	1101                	addi	sp,sp,-32
    800030cc:	ec06                	sd	ra,24(sp)
    800030ce:	e822                	sd	s0,16(sp)
    800030d0:	e426                	sd	s1,8(sp)
    800030d2:	e04a                	sd	s2,0(sp)
    800030d4:	1000                	addi	s0,sp,32
    800030d6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030d8:	00d5d59b          	srliw	a1,a1,0xd
    800030dc:	0001f797          	auipc	a5,0x1f
    800030e0:	cb07a783          	lw	a5,-848(a5) # 80021d8c <sb+0x1c>
    800030e4:	9dbd                	addw	a1,a1,a5
    800030e6:	dedff0ef          	jal	80002ed2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030ea:	0074f713          	andi	a4,s1,7
    800030ee:	4785                	li	a5,1
    800030f0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030f4:	14ce                	slli	s1,s1,0x33
    800030f6:	90d9                	srli	s1,s1,0x36
    800030f8:	00950733          	add	a4,a0,s1
    800030fc:	05874703          	lbu	a4,88(a4)
    80003100:	00e7f6b3          	and	a3,a5,a4
    80003104:	c29d                	beqz	a3,8000312a <bfree+0x60>
    80003106:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003108:	94aa                	add	s1,s1,a0
    8000310a:	fff7c793          	not	a5,a5
    8000310e:	8f7d                	and	a4,a4,a5
    80003110:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003114:	7f9000ef          	jal	8000410c <log_write>
  brelse(bp);
    80003118:	854a                	mv	a0,s2
    8000311a:	ec1ff0ef          	jal	80002fda <brelse>
}
    8000311e:	60e2                	ld	ra,24(sp)
    80003120:	6442                	ld	s0,16(sp)
    80003122:	64a2                	ld	s1,8(sp)
    80003124:	6902                	ld	s2,0(sp)
    80003126:	6105                	addi	sp,sp,32
    80003128:	8082                	ret
    panic("freeing free block");
    8000312a:	00004517          	auipc	a0,0x4
    8000312e:	3ae50513          	addi	a0,a0,942 # 800074d8 <etext+0x4d8>
    80003132:	eaefd0ef          	jal	800007e0 <panic>

0000000080003136 <balloc>:
{
    80003136:	711d                	addi	sp,sp,-96
    80003138:	ec86                	sd	ra,88(sp)
    8000313a:	e8a2                	sd	s0,80(sp)
    8000313c:	e4a6                	sd	s1,72(sp)
    8000313e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003140:	0001f797          	auipc	a5,0x1f
    80003144:	c347a783          	lw	a5,-972(a5) # 80021d74 <sb+0x4>
    80003148:	0e078f63          	beqz	a5,80003246 <balloc+0x110>
    8000314c:	e0ca                	sd	s2,64(sp)
    8000314e:	fc4e                	sd	s3,56(sp)
    80003150:	f852                	sd	s4,48(sp)
    80003152:	f456                	sd	s5,40(sp)
    80003154:	f05a                	sd	s6,32(sp)
    80003156:	ec5e                	sd	s7,24(sp)
    80003158:	e862                	sd	s8,16(sp)
    8000315a:	e466                	sd	s9,8(sp)
    8000315c:	8baa                	mv	s7,a0
    8000315e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003160:	0001fb17          	auipc	s6,0x1f
    80003164:	c10b0b13          	addi	s6,s6,-1008 # 80021d70 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003168:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000316a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000316c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000316e:	6c89                	lui	s9,0x2
    80003170:	a0b5                	j	800031dc <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003172:	97ca                	add	a5,a5,s2
    80003174:	8e55                	or	a2,a2,a3
    80003176:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000317a:	854a                	mv	a0,s2
    8000317c:	791000ef          	jal	8000410c <log_write>
        brelse(bp);
    80003180:	854a                	mv	a0,s2
    80003182:	e59ff0ef          	jal	80002fda <brelse>
  bp = bread(dev, bno);
    80003186:	85a6                	mv	a1,s1
    80003188:	855e                	mv	a0,s7
    8000318a:	d49ff0ef          	jal	80002ed2 <bread>
    8000318e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003190:	40000613          	li	a2,1024
    80003194:	4581                	li	a1,0
    80003196:	05850513          	addi	a0,a0,88
    8000319a:	b4bfd0ef          	jal	80000ce4 <memset>
  log_write(bp);
    8000319e:	854a                	mv	a0,s2
    800031a0:	76d000ef          	jal	8000410c <log_write>
  brelse(bp);
    800031a4:	854a                	mv	a0,s2
    800031a6:	e35ff0ef          	jal	80002fda <brelse>
}
    800031aa:	6906                	ld	s2,64(sp)
    800031ac:	79e2                	ld	s3,56(sp)
    800031ae:	7a42                	ld	s4,48(sp)
    800031b0:	7aa2                	ld	s5,40(sp)
    800031b2:	7b02                	ld	s6,32(sp)
    800031b4:	6be2                	ld	s7,24(sp)
    800031b6:	6c42                	ld	s8,16(sp)
    800031b8:	6ca2                	ld	s9,8(sp)
}
    800031ba:	8526                	mv	a0,s1
    800031bc:	60e6                	ld	ra,88(sp)
    800031be:	6446                	ld	s0,80(sp)
    800031c0:	64a6                	ld	s1,72(sp)
    800031c2:	6125                	addi	sp,sp,96
    800031c4:	8082                	ret
    brelse(bp);
    800031c6:	854a                	mv	a0,s2
    800031c8:	e13ff0ef          	jal	80002fda <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031cc:	015c87bb          	addw	a5,s9,s5
    800031d0:	00078a9b          	sext.w	s5,a5
    800031d4:	004b2703          	lw	a4,4(s6)
    800031d8:	04eaff63          	bgeu	s5,a4,80003236 <balloc+0x100>
    bp = bread(dev, BBLOCK(b, sb));
    800031dc:	41fad79b          	sraiw	a5,s5,0x1f
    800031e0:	0137d79b          	srliw	a5,a5,0x13
    800031e4:	015787bb          	addw	a5,a5,s5
    800031e8:	40d7d79b          	sraiw	a5,a5,0xd
    800031ec:	01cb2583          	lw	a1,28(s6)
    800031f0:	9dbd                	addw	a1,a1,a5
    800031f2:	855e                	mv	a0,s7
    800031f4:	cdfff0ef          	jal	80002ed2 <bread>
    800031f8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031fa:	004b2503          	lw	a0,4(s6)
    800031fe:	000a849b          	sext.w	s1,s5
    80003202:	8762                	mv	a4,s8
    80003204:	fca4f1e3          	bgeu	s1,a0,800031c6 <balloc+0x90>
      m = 1 << (bi % 8);
    80003208:	00777693          	andi	a3,a4,7
    8000320c:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003210:	41f7579b          	sraiw	a5,a4,0x1f
    80003214:	01d7d79b          	srliw	a5,a5,0x1d
    80003218:	9fb9                	addw	a5,a5,a4
    8000321a:	4037d79b          	sraiw	a5,a5,0x3
    8000321e:	00f90633          	add	a2,s2,a5
    80003222:	05864603          	lbu	a2,88(a2)
    80003226:	00c6f5b3          	and	a1,a3,a2
    8000322a:	d5a1                	beqz	a1,80003172 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322c:	2705                	addiw	a4,a4,1
    8000322e:	2485                	addiw	s1,s1,1
    80003230:	fd471ae3          	bne	a4,s4,80003204 <balloc+0xce>
    80003234:	bf49                	j	800031c6 <balloc+0x90>
    80003236:	6906                	ld	s2,64(sp)
    80003238:	79e2                	ld	s3,56(sp)
    8000323a:	7a42                	ld	s4,48(sp)
    8000323c:	7aa2                	ld	s5,40(sp)
    8000323e:	7b02                	ld	s6,32(sp)
    80003240:	6be2                	ld	s7,24(sp)
    80003242:	6c42                	ld	s8,16(sp)
    80003244:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80003246:	00004517          	auipc	a0,0x4
    8000324a:	2aa50513          	addi	a0,a0,682 # 800074f0 <etext+0x4f0>
    8000324e:	aacfd0ef          	jal	800004fa <printf>
  return 0;
    80003252:	4481                	li	s1,0
    80003254:	b79d                	j	800031ba <balloc+0x84>

0000000080003256 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003256:	7179                	addi	sp,sp,-48
    80003258:	f406                	sd	ra,40(sp)
    8000325a:	f022                	sd	s0,32(sp)
    8000325c:	ec26                	sd	s1,24(sp)
    8000325e:	e84a                	sd	s2,16(sp)
    80003260:	e44e                	sd	s3,8(sp)
    80003262:	1800                	addi	s0,sp,48
    80003264:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003266:	47ad                	li	a5,11
    80003268:	02b7e663          	bltu	a5,a1,80003294 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    8000326c:	02059793          	slli	a5,a1,0x20
    80003270:	01e7d593          	srli	a1,a5,0x1e
    80003274:	00b504b3          	add	s1,a0,a1
    80003278:	0504a903          	lw	s2,80(s1)
    8000327c:	06091a63          	bnez	s2,800032f0 <bmap+0x9a>
      addr = balloc(ip->dev);
    80003280:	4108                	lw	a0,0(a0)
    80003282:	eb5ff0ef          	jal	80003136 <balloc>
    80003286:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000328a:	06090363          	beqz	s2,800032f0 <bmap+0x9a>
        return 0;
      ip->addrs[bn] = addr;
    8000328e:	0524a823          	sw	s2,80(s1)
    80003292:	a8b9                	j	800032f0 <bmap+0x9a>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003294:	ff45849b          	addiw	s1,a1,-12
    80003298:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000329c:	0ff00793          	li	a5,255
    800032a0:	06e7ee63          	bltu	a5,a4,8000331c <bmap+0xc6>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800032a4:	08052903          	lw	s2,128(a0)
    800032a8:	00091d63          	bnez	s2,800032c2 <bmap+0x6c>
      addr = balloc(ip->dev);
    800032ac:	4108                	lw	a0,0(a0)
    800032ae:	e89ff0ef          	jal	80003136 <balloc>
    800032b2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032b6:	02090d63          	beqz	s2,800032f0 <bmap+0x9a>
    800032ba:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    800032bc:	0929a023          	sw	s2,128(s3)
    800032c0:	a011                	j	800032c4 <bmap+0x6e>
    800032c2:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    800032c4:	85ca                	mv	a1,s2
    800032c6:	0009a503          	lw	a0,0(s3)
    800032ca:	c09ff0ef          	jal	80002ed2 <bread>
    800032ce:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032d0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032d4:	02049713          	slli	a4,s1,0x20
    800032d8:	01e75593          	srli	a1,a4,0x1e
    800032dc:	00b784b3          	add	s1,a5,a1
    800032e0:	0004a903          	lw	s2,0(s1)
    800032e4:	00090e63          	beqz	s2,80003300 <bmap+0xaa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800032e8:	8552                	mv	a0,s4
    800032ea:	cf1ff0ef          	jal	80002fda <brelse>
    return addr;
    800032ee:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    800032f0:	854a                	mv	a0,s2
    800032f2:	70a2                	ld	ra,40(sp)
    800032f4:	7402                	ld	s0,32(sp)
    800032f6:	64e2                	ld	s1,24(sp)
    800032f8:	6942                	ld	s2,16(sp)
    800032fa:	69a2                	ld	s3,8(sp)
    800032fc:	6145                	addi	sp,sp,48
    800032fe:	8082                	ret
      addr = balloc(ip->dev);
    80003300:	0009a503          	lw	a0,0(s3)
    80003304:	e33ff0ef          	jal	80003136 <balloc>
    80003308:	0005091b          	sext.w	s2,a0
      if(addr){
    8000330c:	fc090ee3          	beqz	s2,800032e8 <bmap+0x92>
        a[bn] = addr;
    80003310:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003314:	8552                	mv	a0,s4
    80003316:	5f7000ef          	jal	8000410c <log_write>
    8000331a:	b7f9                	j	800032e8 <bmap+0x92>
    8000331c:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    8000331e:	00004517          	auipc	a0,0x4
    80003322:	1ea50513          	addi	a0,a0,490 # 80007508 <etext+0x508>
    80003326:	cbafd0ef          	jal	800007e0 <panic>

000000008000332a <iget>:
{
    8000332a:	7179                	addi	sp,sp,-48
    8000332c:	f406                	sd	ra,40(sp)
    8000332e:	f022                	sd	s0,32(sp)
    80003330:	ec26                	sd	s1,24(sp)
    80003332:	e84a                	sd	s2,16(sp)
    80003334:	e44e                	sd	s3,8(sp)
    80003336:	e052                	sd	s4,0(sp)
    80003338:	1800                	addi	s0,sp,48
    8000333a:	89aa                	mv	s3,a0
    8000333c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000333e:	0001f517          	auipc	a0,0x1f
    80003342:	a5250513          	addi	a0,a0,-1454 # 80021d90 <itable>
    80003346:	8cbfd0ef          	jal	80000c10 <acquire>
  empty = 0;
    8000334a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000334c:	0001f497          	auipc	s1,0x1f
    80003350:	a5c48493          	addi	s1,s1,-1444 # 80021da8 <itable+0x18>
    80003354:	00020697          	auipc	a3,0x20
    80003358:	4e468693          	addi	a3,a3,1252 # 80023838 <log>
    8000335c:	a039                	j	8000336a <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000335e:	02090963          	beqz	s2,80003390 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003362:	08848493          	addi	s1,s1,136
    80003366:	02d48863          	beq	s1,a3,80003396 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000336a:	449c                	lw	a5,8(s1)
    8000336c:	fef059e3          	blez	a5,8000335e <iget+0x34>
    80003370:	4098                	lw	a4,0(s1)
    80003372:	ff3716e3          	bne	a4,s3,8000335e <iget+0x34>
    80003376:	40d8                	lw	a4,4(s1)
    80003378:	ff4713e3          	bne	a4,s4,8000335e <iget+0x34>
      ip->ref++;
    8000337c:	2785                	addiw	a5,a5,1
    8000337e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003380:	0001f517          	auipc	a0,0x1f
    80003384:	a1050513          	addi	a0,a0,-1520 # 80021d90 <itable>
    80003388:	921fd0ef          	jal	80000ca8 <release>
      return ip;
    8000338c:	8926                	mv	s2,s1
    8000338e:	a02d                	j	800033b8 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003390:	fbe9                	bnez	a5,80003362 <iget+0x38>
      empty = ip;
    80003392:	8926                	mv	s2,s1
    80003394:	b7f9                	j	80003362 <iget+0x38>
  if(empty == 0)
    80003396:	02090a63          	beqz	s2,800033ca <iget+0xa0>
  ip->dev = dev;
    8000339a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000339e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033a2:	4785                	li	a5,1
    800033a4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033a8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033ac:	0001f517          	auipc	a0,0x1f
    800033b0:	9e450513          	addi	a0,a0,-1564 # 80021d90 <itable>
    800033b4:	8f5fd0ef          	jal	80000ca8 <release>
}
    800033b8:	854a                	mv	a0,s2
    800033ba:	70a2                	ld	ra,40(sp)
    800033bc:	7402                	ld	s0,32(sp)
    800033be:	64e2                	ld	s1,24(sp)
    800033c0:	6942                	ld	s2,16(sp)
    800033c2:	69a2                	ld	s3,8(sp)
    800033c4:	6a02                	ld	s4,0(sp)
    800033c6:	6145                	addi	sp,sp,48
    800033c8:	8082                	ret
    panic("iget: no inodes");
    800033ca:	00004517          	auipc	a0,0x4
    800033ce:	15650513          	addi	a0,a0,342 # 80007520 <etext+0x520>
    800033d2:	c0efd0ef          	jal	800007e0 <panic>

00000000800033d6 <iinit>:
{
    800033d6:	7179                	addi	sp,sp,-48
    800033d8:	f406                	sd	ra,40(sp)
    800033da:	f022                	sd	s0,32(sp)
    800033dc:	ec26                	sd	s1,24(sp)
    800033de:	e84a                	sd	s2,16(sp)
    800033e0:	e44e                	sd	s3,8(sp)
    800033e2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800033e4:	00004597          	auipc	a1,0x4
    800033e8:	14c58593          	addi	a1,a1,332 # 80007530 <etext+0x530>
    800033ec:	0001f517          	auipc	a0,0x1f
    800033f0:	9a450513          	addi	a0,a0,-1628 # 80021d90 <itable>
    800033f4:	f9cfd0ef          	jal	80000b90 <initlock>
  for(i = 0; i < NINODE; i++) {
    800033f8:	0001f497          	auipc	s1,0x1f
    800033fc:	9c048493          	addi	s1,s1,-1600 # 80021db8 <itable+0x28>
    80003400:	00020997          	auipc	s3,0x20
    80003404:	44898993          	addi	s3,s3,1096 # 80023848 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003408:	00004917          	auipc	s2,0x4
    8000340c:	13090913          	addi	s2,s2,304 # 80007538 <etext+0x538>
    80003410:	85ca                	mv	a1,s2
    80003412:	8526                	mv	a0,s1
    80003414:	5bb000ef          	jal	800041ce <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003418:	08848493          	addi	s1,s1,136
    8000341c:	ff349ae3          	bne	s1,s3,80003410 <iinit+0x3a>
}
    80003420:	70a2                	ld	ra,40(sp)
    80003422:	7402                	ld	s0,32(sp)
    80003424:	64e2                	ld	s1,24(sp)
    80003426:	6942                	ld	s2,16(sp)
    80003428:	69a2                	ld	s3,8(sp)
    8000342a:	6145                	addi	sp,sp,48
    8000342c:	8082                	ret

000000008000342e <ialloc>:
{
    8000342e:	7139                	addi	sp,sp,-64
    80003430:	fc06                	sd	ra,56(sp)
    80003432:	f822                	sd	s0,48(sp)
    80003434:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003436:	0001f717          	auipc	a4,0x1f
    8000343a:	94672703          	lw	a4,-1722(a4) # 80021d7c <sb+0xc>
    8000343e:	4785                	li	a5,1
    80003440:	06e7f063          	bgeu	a5,a4,800034a0 <ialloc+0x72>
    80003444:	f426                	sd	s1,40(sp)
    80003446:	f04a                	sd	s2,32(sp)
    80003448:	ec4e                	sd	s3,24(sp)
    8000344a:	e852                	sd	s4,16(sp)
    8000344c:	e456                	sd	s5,8(sp)
    8000344e:	e05a                	sd	s6,0(sp)
    80003450:	8aaa                	mv	s5,a0
    80003452:	8b2e                	mv	s6,a1
    80003454:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003456:	0001fa17          	auipc	s4,0x1f
    8000345a:	91aa0a13          	addi	s4,s4,-1766 # 80021d70 <sb>
    8000345e:	00495593          	srli	a1,s2,0x4
    80003462:	018a2783          	lw	a5,24(s4)
    80003466:	9dbd                	addw	a1,a1,a5
    80003468:	8556                	mv	a0,s5
    8000346a:	a69ff0ef          	jal	80002ed2 <bread>
    8000346e:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003470:	05850993          	addi	s3,a0,88
    80003474:	00f97793          	andi	a5,s2,15
    80003478:	079a                	slli	a5,a5,0x6
    8000347a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000347c:	00099783          	lh	a5,0(s3)
    80003480:	cb9d                	beqz	a5,800034b6 <ialloc+0x88>
    brelse(bp);
    80003482:	b59ff0ef          	jal	80002fda <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003486:	0905                	addi	s2,s2,1
    80003488:	00ca2703          	lw	a4,12(s4)
    8000348c:	0009079b          	sext.w	a5,s2
    80003490:	fce7e7e3          	bltu	a5,a4,8000345e <ialloc+0x30>
    80003494:	74a2                	ld	s1,40(sp)
    80003496:	7902                	ld	s2,32(sp)
    80003498:	69e2                	ld	s3,24(sp)
    8000349a:	6a42                	ld	s4,16(sp)
    8000349c:	6aa2                	ld	s5,8(sp)
    8000349e:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    800034a0:	00004517          	auipc	a0,0x4
    800034a4:	0a050513          	addi	a0,a0,160 # 80007540 <etext+0x540>
    800034a8:	852fd0ef          	jal	800004fa <printf>
  return 0;
    800034ac:	4501                	li	a0,0
}
    800034ae:	70e2                	ld	ra,56(sp)
    800034b0:	7442                	ld	s0,48(sp)
    800034b2:	6121                	addi	sp,sp,64
    800034b4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800034b6:	04000613          	li	a2,64
    800034ba:	4581                	li	a1,0
    800034bc:	854e                	mv	a0,s3
    800034be:	827fd0ef          	jal	80000ce4 <memset>
      dip->type = type;
    800034c2:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800034c6:	8526                	mv	a0,s1
    800034c8:	445000ef          	jal	8000410c <log_write>
      brelse(bp);
    800034cc:	8526                	mv	a0,s1
    800034ce:	b0dff0ef          	jal	80002fda <brelse>
      return iget(dev, inum);
    800034d2:	0009059b          	sext.w	a1,s2
    800034d6:	8556                	mv	a0,s5
    800034d8:	e53ff0ef          	jal	8000332a <iget>
    800034dc:	74a2                	ld	s1,40(sp)
    800034de:	7902                	ld	s2,32(sp)
    800034e0:	69e2                	ld	s3,24(sp)
    800034e2:	6a42                	ld	s4,16(sp)
    800034e4:	6aa2                	ld	s5,8(sp)
    800034e6:	6b02                	ld	s6,0(sp)
    800034e8:	b7d9                	j	800034ae <ialloc+0x80>

00000000800034ea <iupdate>:
{
    800034ea:	1101                	addi	sp,sp,-32
    800034ec:	ec06                	sd	ra,24(sp)
    800034ee:	e822                	sd	s0,16(sp)
    800034f0:	e426                	sd	s1,8(sp)
    800034f2:	e04a                	sd	s2,0(sp)
    800034f4:	1000                	addi	s0,sp,32
    800034f6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800034f8:	415c                	lw	a5,4(a0)
    800034fa:	0047d79b          	srliw	a5,a5,0x4
    800034fe:	0001f597          	auipc	a1,0x1f
    80003502:	88a5a583          	lw	a1,-1910(a1) # 80021d88 <sb+0x18>
    80003506:	9dbd                	addw	a1,a1,a5
    80003508:	4108                	lw	a0,0(a0)
    8000350a:	9c9ff0ef          	jal	80002ed2 <bread>
    8000350e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003510:	05850793          	addi	a5,a0,88
    80003514:	40d8                	lw	a4,4(s1)
    80003516:	8b3d                	andi	a4,a4,15
    80003518:	071a                	slli	a4,a4,0x6
    8000351a:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000351c:	04449703          	lh	a4,68(s1)
    80003520:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003524:	04649703          	lh	a4,70(s1)
    80003528:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000352c:	04849703          	lh	a4,72(s1)
    80003530:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003534:	04a49703          	lh	a4,74(s1)
    80003538:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000353c:	44f8                	lw	a4,76(s1)
    8000353e:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003540:	03400613          	li	a2,52
    80003544:	05048593          	addi	a1,s1,80
    80003548:	00c78513          	addi	a0,a5,12
    8000354c:	ff4fd0ef          	jal	80000d40 <memmove>
  log_write(bp);
    80003550:	854a                	mv	a0,s2
    80003552:	3bb000ef          	jal	8000410c <log_write>
  brelse(bp);
    80003556:	854a                	mv	a0,s2
    80003558:	a83ff0ef          	jal	80002fda <brelse>
}
    8000355c:	60e2                	ld	ra,24(sp)
    8000355e:	6442                	ld	s0,16(sp)
    80003560:	64a2                	ld	s1,8(sp)
    80003562:	6902                	ld	s2,0(sp)
    80003564:	6105                	addi	sp,sp,32
    80003566:	8082                	ret

0000000080003568 <idup>:
{
    80003568:	1101                	addi	sp,sp,-32
    8000356a:	ec06                	sd	ra,24(sp)
    8000356c:	e822                	sd	s0,16(sp)
    8000356e:	e426                	sd	s1,8(sp)
    80003570:	1000                	addi	s0,sp,32
    80003572:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003574:	0001f517          	auipc	a0,0x1f
    80003578:	81c50513          	addi	a0,a0,-2020 # 80021d90 <itable>
    8000357c:	e94fd0ef          	jal	80000c10 <acquire>
  ip->ref++;
    80003580:	449c                	lw	a5,8(s1)
    80003582:	2785                	addiw	a5,a5,1
    80003584:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003586:	0001f517          	auipc	a0,0x1f
    8000358a:	80a50513          	addi	a0,a0,-2038 # 80021d90 <itable>
    8000358e:	f1afd0ef          	jal	80000ca8 <release>
}
    80003592:	8526                	mv	a0,s1
    80003594:	60e2                	ld	ra,24(sp)
    80003596:	6442                	ld	s0,16(sp)
    80003598:	64a2                	ld	s1,8(sp)
    8000359a:	6105                	addi	sp,sp,32
    8000359c:	8082                	ret

000000008000359e <ilock>:
{
    8000359e:	1101                	addi	sp,sp,-32
    800035a0:	ec06                	sd	ra,24(sp)
    800035a2:	e822                	sd	s0,16(sp)
    800035a4:	e426                	sd	s1,8(sp)
    800035a6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800035a8:	cd19                	beqz	a0,800035c6 <ilock+0x28>
    800035aa:	84aa                	mv	s1,a0
    800035ac:	451c                	lw	a5,8(a0)
    800035ae:	00f05c63          	blez	a5,800035c6 <ilock+0x28>
  acquiresleep(&ip->lock);
    800035b2:	0541                	addi	a0,a0,16
    800035b4:	451000ef          	jal	80004204 <acquiresleep>
  if(ip->valid == 0){
    800035b8:	40bc                	lw	a5,64(s1)
    800035ba:	cf89                	beqz	a5,800035d4 <ilock+0x36>
}
    800035bc:	60e2                	ld	ra,24(sp)
    800035be:	6442                	ld	s0,16(sp)
    800035c0:	64a2                	ld	s1,8(sp)
    800035c2:	6105                	addi	sp,sp,32
    800035c4:	8082                	ret
    800035c6:	e04a                	sd	s2,0(sp)
    panic("ilock");
    800035c8:	00004517          	auipc	a0,0x4
    800035cc:	f9050513          	addi	a0,a0,-112 # 80007558 <etext+0x558>
    800035d0:	a10fd0ef          	jal	800007e0 <panic>
    800035d4:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035d6:	40dc                	lw	a5,4(s1)
    800035d8:	0047d79b          	srliw	a5,a5,0x4
    800035dc:	0001e597          	auipc	a1,0x1e
    800035e0:	7ac5a583          	lw	a1,1964(a1) # 80021d88 <sb+0x18>
    800035e4:	9dbd                	addw	a1,a1,a5
    800035e6:	4088                	lw	a0,0(s1)
    800035e8:	8ebff0ef          	jal	80002ed2 <bread>
    800035ec:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035ee:	05850593          	addi	a1,a0,88
    800035f2:	40dc                	lw	a5,4(s1)
    800035f4:	8bbd                	andi	a5,a5,15
    800035f6:	079a                	slli	a5,a5,0x6
    800035f8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800035fa:	00059783          	lh	a5,0(a1)
    800035fe:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003602:	00259783          	lh	a5,2(a1)
    80003606:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000360a:	00459783          	lh	a5,4(a1)
    8000360e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003612:	00659783          	lh	a5,6(a1)
    80003616:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000361a:	459c                	lw	a5,8(a1)
    8000361c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000361e:	03400613          	li	a2,52
    80003622:	05b1                	addi	a1,a1,12
    80003624:	05048513          	addi	a0,s1,80
    80003628:	f18fd0ef          	jal	80000d40 <memmove>
    brelse(bp);
    8000362c:	854a                	mv	a0,s2
    8000362e:	9adff0ef          	jal	80002fda <brelse>
    ip->valid = 1;
    80003632:	4785                	li	a5,1
    80003634:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003636:	04449783          	lh	a5,68(s1)
    8000363a:	c399                	beqz	a5,80003640 <ilock+0xa2>
    8000363c:	6902                	ld	s2,0(sp)
    8000363e:	bfbd                	j	800035bc <ilock+0x1e>
      panic("ilock: no type");
    80003640:	00004517          	auipc	a0,0x4
    80003644:	f2050513          	addi	a0,a0,-224 # 80007560 <etext+0x560>
    80003648:	998fd0ef          	jal	800007e0 <panic>

000000008000364c <iunlock>:
{
    8000364c:	1101                	addi	sp,sp,-32
    8000364e:	ec06                	sd	ra,24(sp)
    80003650:	e822                	sd	s0,16(sp)
    80003652:	e426                	sd	s1,8(sp)
    80003654:	e04a                	sd	s2,0(sp)
    80003656:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003658:	c505                	beqz	a0,80003680 <iunlock+0x34>
    8000365a:	84aa                	mv	s1,a0
    8000365c:	01050913          	addi	s2,a0,16
    80003660:	854a                	mv	a0,s2
    80003662:	421000ef          	jal	80004282 <holdingsleep>
    80003666:	cd09                	beqz	a0,80003680 <iunlock+0x34>
    80003668:	449c                	lw	a5,8(s1)
    8000366a:	00f05b63          	blez	a5,80003680 <iunlock+0x34>
  releasesleep(&ip->lock);
    8000366e:	854a                	mv	a0,s2
    80003670:	3db000ef          	jal	8000424a <releasesleep>
}
    80003674:	60e2                	ld	ra,24(sp)
    80003676:	6442                	ld	s0,16(sp)
    80003678:	64a2                	ld	s1,8(sp)
    8000367a:	6902                	ld	s2,0(sp)
    8000367c:	6105                	addi	sp,sp,32
    8000367e:	8082                	ret
    panic("iunlock");
    80003680:	00004517          	auipc	a0,0x4
    80003684:	ef050513          	addi	a0,a0,-272 # 80007570 <etext+0x570>
    80003688:	958fd0ef          	jal	800007e0 <panic>

000000008000368c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000368c:	7179                	addi	sp,sp,-48
    8000368e:	f406                	sd	ra,40(sp)
    80003690:	f022                	sd	s0,32(sp)
    80003692:	ec26                	sd	s1,24(sp)
    80003694:	e84a                	sd	s2,16(sp)
    80003696:	e44e                	sd	s3,8(sp)
    80003698:	1800                	addi	s0,sp,48
    8000369a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000369c:	05050493          	addi	s1,a0,80
    800036a0:	08050913          	addi	s2,a0,128
    800036a4:	a021                	j	800036ac <itrunc+0x20>
    800036a6:	0491                	addi	s1,s1,4
    800036a8:	01248b63          	beq	s1,s2,800036be <itrunc+0x32>
    if(ip->addrs[i]){
    800036ac:	408c                	lw	a1,0(s1)
    800036ae:	dde5                	beqz	a1,800036a6 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    800036b0:	0009a503          	lw	a0,0(s3)
    800036b4:	a17ff0ef          	jal	800030ca <bfree>
      ip->addrs[i] = 0;
    800036b8:	0004a023          	sw	zero,0(s1)
    800036bc:	b7ed                	j	800036a6 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    800036be:	0809a583          	lw	a1,128(s3)
    800036c2:	ed89                	bnez	a1,800036dc <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800036c4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800036c8:	854e                	mv	a0,s3
    800036ca:	e21ff0ef          	jal	800034ea <iupdate>
}
    800036ce:	70a2                	ld	ra,40(sp)
    800036d0:	7402                	ld	s0,32(sp)
    800036d2:	64e2                	ld	s1,24(sp)
    800036d4:	6942                	ld	s2,16(sp)
    800036d6:	69a2                	ld	s3,8(sp)
    800036d8:	6145                	addi	sp,sp,48
    800036da:	8082                	ret
    800036dc:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800036de:	0009a503          	lw	a0,0(s3)
    800036e2:	ff0ff0ef          	jal	80002ed2 <bread>
    800036e6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800036e8:	05850493          	addi	s1,a0,88
    800036ec:	45850913          	addi	s2,a0,1112
    800036f0:	a021                	j	800036f8 <itrunc+0x6c>
    800036f2:	0491                	addi	s1,s1,4
    800036f4:	01248963          	beq	s1,s2,80003706 <itrunc+0x7a>
      if(a[j])
    800036f8:	408c                	lw	a1,0(s1)
    800036fa:	dde5                	beqz	a1,800036f2 <itrunc+0x66>
        bfree(ip->dev, a[j]);
    800036fc:	0009a503          	lw	a0,0(s3)
    80003700:	9cbff0ef          	jal	800030ca <bfree>
    80003704:	b7fd                	j	800036f2 <itrunc+0x66>
    brelse(bp);
    80003706:	8552                	mv	a0,s4
    80003708:	8d3ff0ef          	jal	80002fda <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000370c:	0809a583          	lw	a1,128(s3)
    80003710:	0009a503          	lw	a0,0(s3)
    80003714:	9b7ff0ef          	jal	800030ca <bfree>
    ip->addrs[NDIRECT] = 0;
    80003718:	0809a023          	sw	zero,128(s3)
    8000371c:	6a02                	ld	s4,0(sp)
    8000371e:	b75d                	j	800036c4 <itrunc+0x38>

0000000080003720 <iput>:
{
    80003720:	1101                	addi	sp,sp,-32
    80003722:	ec06                	sd	ra,24(sp)
    80003724:	e822                	sd	s0,16(sp)
    80003726:	e426                	sd	s1,8(sp)
    80003728:	1000                	addi	s0,sp,32
    8000372a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000372c:	0001e517          	auipc	a0,0x1e
    80003730:	66450513          	addi	a0,a0,1636 # 80021d90 <itable>
    80003734:	cdcfd0ef          	jal	80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003738:	4498                	lw	a4,8(s1)
    8000373a:	4785                	li	a5,1
    8000373c:	02f70063          	beq	a4,a5,8000375c <iput+0x3c>
  ip->ref--;
    80003740:	449c                	lw	a5,8(s1)
    80003742:	37fd                	addiw	a5,a5,-1
    80003744:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003746:	0001e517          	auipc	a0,0x1e
    8000374a:	64a50513          	addi	a0,a0,1610 # 80021d90 <itable>
    8000374e:	d5afd0ef          	jal	80000ca8 <release>
}
    80003752:	60e2                	ld	ra,24(sp)
    80003754:	6442                	ld	s0,16(sp)
    80003756:	64a2                	ld	s1,8(sp)
    80003758:	6105                	addi	sp,sp,32
    8000375a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000375c:	40bc                	lw	a5,64(s1)
    8000375e:	d3ed                	beqz	a5,80003740 <iput+0x20>
    80003760:	04a49783          	lh	a5,74(s1)
    80003764:	fff1                	bnez	a5,80003740 <iput+0x20>
    80003766:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80003768:	01048913          	addi	s2,s1,16
    8000376c:	854a                	mv	a0,s2
    8000376e:	297000ef          	jal	80004204 <acquiresleep>
    release(&itable.lock);
    80003772:	0001e517          	auipc	a0,0x1e
    80003776:	61e50513          	addi	a0,a0,1566 # 80021d90 <itable>
    8000377a:	d2efd0ef          	jal	80000ca8 <release>
    itrunc(ip);
    8000377e:	8526                	mv	a0,s1
    80003780:	f0dff0ef          	jal	8000368c <itrunc>
    ip->type = 0;
    80003784:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003788:	8526                	mv	a0,s1
    8000378a:	d61ff0ef          	jal	800034ea <iupdate>
    ip->valid = 0;
    8000378e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003792:	854a                	mv	a0,s2
    80003794:	2b7000ef          	jal	8000424a <releasesleep>
    acquire(&itable.lock);
    80003798:	0001e517          	auipc	a0,0x1e
    8000379c:	5f850513          	addi	a0,a0,1528 # 80021d90 <itable>
    800037a0:	c70fd0ef          	jal	80000c10 <acquire>
    800037a4:	6902                	ld	s2,0(sp)
    800037a6:	bf69                	j	80003740 <iput+0x20>

00000000800037a8 <iunlockput>:
{
    800037a8:	1101                	addi	sp,sp,-32
    800037aa:	ec06                	sd	ra,24(sp)
    800037ac:	e822                	sd	s0,16(sp)
    800037ae:	e426                	sd	s1,8(sp)
    800037b0:	1000                	addi	s0,sp,32
    800037b2:	84aa                	mv	s1,a0
  iunlock(ip);
    800037b4:	e99ff0ef          	jal	8000364c <iunlock>
  iput(ip);
    800037b8:	8526                	mv	a0,s1
    800037ba:	f67ff0ef          	jal	80003720 <iput>
}
    800037be:	60e2                	ld	ra,24(sp)
    800037c0:	6442                	ld	s0,16(sp)
    800037c2:	64a2                	ld	s1,8(sp)
    800037c4:	6105                	addi	sp,sp,32
    800037c6:	8082                	ret

00000000800037c8 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800037c8:	0001e717          	auipc	a4,0x1e
    800037cc:	5b472703          	lw	a4,1460(a4) # 80021d7c <sb+0xc>
    800037d0:	4785                	li	a5,1
    800037d2:	0ae7ff63          	bgeu	a5,a4,80003890 <ireclaim+0xc8>
{
    800037d6:	7139                	addi	sp,sp,-64
    800037d8:	fc06                	sd	ra,56(sp)
    800037da:	f822                	sd	s0,48(sp)
    800037dc:	f426                	sd	s1,40(sp)
    800037de:	f04a                	sd	s2,32(sp)
    800037e0:	ec4e                	sd	s3,24(sp)
    800037e2:	e852                	sd	s4,16(sp)
    800037e4:	e456                	sd	s5,8(sp)
    800037e6:	e05a                	sd	s6,0(sp)
    800037e8:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800037ea:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800037ec:	00050a1b          	sext.w	s4,a0
    800037f0:	0001ea97          	auipc	s5,0x1e
    800037f4:	580a8a93          	addi	s5,s5,1408 # 80021d70 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    800037f8:	00004b17          	auipc	s6,0x4
    800037fc:	d80b0b13          	addi	s6,s6,-640 # 80007578 <etext+0x578>
    80003800:	a099                	j	80003846 <ireclaim+0x7e>
    80003802:	85ce                	mv	a1,s3
    80003804:	855a                	mv	a0,s6
    80003806:	cf5fc0ef          	jal	800004fa <printf>
      ip = iget(dev, inum);
    8000380a:	85ce                	mv	a1,s3
    8000380c:	8552                	mv	a0,s4
    8000380e:	b1dff0ef          	jal	8000332a <iget>
    80003812:	89aa                	mv	s3,a0
    brelse(bp);
    80003814:	854a                	mv	a0,s2
    80003816:	fc4ff0ef          	jal	80002fda <brelse>
    if (ip) {
    8000381a:	00098f63          	beqz	s3,80003838 <ireclaim+0x70>
      begin_op();
    8000381e:	76a000ef          	jal	80003f88 <begin_op>
      ilock(ip);
    80003822:	854e                	mv	a0,s3
    80003824:	d7bff0ef          	jal	8000359e <ilock>
      iunlock(ip);
    80003828:	854e                	mv	a0,s3
    8000382a:	e23ff0ef          	jal	8000364c <iunlock>
      iput(ip);
    8000382e:	854e                	mv	a0,s3
    80003830:	ef1ff0ef          	jal	80003720 <iput>
      end_op();
    80003834:	7be000ef          	jal	80003ff2 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003838:	0485                	addi	s1,s1,1
    8000383a:	00caa703          	lw	a4,12(s5)
    8000383e:	0004879b          	sext.w	a5,s1
    80003842:	02e7fd63          	bgeu	a5,a4,8000387c <ireclaim+0xb4>
    80003846:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8000384a:	0044d593          	srli	a1,s1,0x4
    8000384e:	018aa783          	lw	a5,24(s5)
    80003852:	9dbd                	addw	a1,a1,a5
    80003854:	8552                	mv	a0,s4
    80003856:	e7cff0ef          	jal	80002ed2 <bread>
    8000385a:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    8000385c:	05850793          	addi	a5,a0,88
    80003860:	00f9f713          	andi	a4,s3,15
    80003864:	071a                	slli	a4,a4,0x6
    80003866:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003868:	00079703          	lh	a4,0(a5)
    8000386c:	c701                	beqz	a4,80003874 <ireclaim+0xac>
    8000386e:	00679783          	lh	a5,6(a5)
    80003872:	dbc1                	beqz	a5,80003802 <ireclaim+0x3a>
    brelse(bp);
    80003874:	854a                	mv	a0,s2
    80003876:	f64ff0ef          	jal	80002fda <brelse>
    if (ip) {
    8000387a:	bf7d                	j	80003838 <ireclaim+0x70>
}
    8000387c:	70e2                	ld	ra,56(sp)
    8000387e:	7442                	ld	s0,48(sp)
    80003880:	74a2                	ld	s1,40(sp)
    80003882:	7902                	ld	s2,32(sp)
    80003884:	69e2                	ld	s3,24(sp)
    80003886:	6a42                	ld	s4,16(sp)
    80003888:	6aa2                	ld	s5,8(sp)
    8000388a:	6b02                	ld	s6,0(sp)
    8000388c:	6121                	addi	sp,sp,64
    8000388e:	8082                	ret
    80003890:	8082                	ret

0000000080003892 <fsinit>:
fsinit(int dev) {
    80003892:	7179                	addi	sp,sp,-48
    80003894:	f406                	sd	ra,40(sp)
    80003896:	f022                	sd	s0,32(sp)
    80003898:	ec26                	sd	s1,24(sp)
    8000389a:	e84a                	sd	s2,16(sp)
    8000389c:	e44e                	sd	s3,8(sp)
    8000389e:	1800                	addi	s0,sp,48
    800038a0:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    800038a2:	4585                	li	a1,1
    800038a4:	e2eff0ef          	jal	80002ed2 <bread>
    800038a8:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038aa:	0001e997          	auipc	s3,0x1e
    800038ae:	4c698993          	addi	s3,s3,1222 # 80021d70 <sb>
    800038b2:	02000613          	li	a2,32
    800038b6:	05850593          	addi	a1,a0,88
    800038ba:	854e                	mv	a0,s3
    800038bc:	c84fd0ef          	jal	80000d40 <memmove>
  brelse(bp);
    800038c0:	854a                	mv	a0,s2
    800038c2:	f18ff0ef          	jal	80002fda <brelse>
  if(sb.magic != FSMAGIC)
    800038c6:	0009a703          	lw	a4,0(s3)
    800038ca:	102037b7          	lui	a5,0x10203
    800038ce:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038d2:	02f71363          	bne	a4,a5,800038f8 <fsinit+0x66>
  initlog(dev, &sb);
    800038d6:	0001e597          	auipc	a1,0x1e
    800038da:	49a58593          	addi	a1,a1,1178 # 80021d70 <sb>
    800038de:	8526                	mv	a0,s1
    800038e0:	62a000ef          	jal	80003f0a <initlog>
  ireclaim(dev);
    800038e4:	8526                	mv	a0,s1
    800038e6:	ee3ff0ef          	jal	800037c8 <ireclaim>
}
    800038ea:	70a2                	ld	ra,40(sp)
    800038ec:	7402                	ld	s0,32(sp)
    800038ee:	64e2                	ld	s1,24(sp)
    800038f0:	6942                	ld	s2,16(sp)
    800038f2:	69a2                	ld	s3,8(sp)
    800038f4:	6145                	addi	sp,sp,48
    800038f6:	8082                	ret
    panic("invalid file system");
    800038f8:	00004517          	auipc	a0,0x4
    800038fc:	ca050513          	addi	a0,a0,-864 # 80007598 <etext+0x598>
    80003900:	ee1fc0ef          	jal	800007e0 <panic>

0000000080003904 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003904:	1141                	addi	sp,sp,-16
    80003906:	e422                	sd	s0,8(sp)
    80003908:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000390a:	411c                	lw	a5,0(a0)
    8000390c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000390e:	415c                	lw	a5,4(a0)
    80003910:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003912:	04451783          	lh	a5,68(a0)
    80003916:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000391a:	04a51783          	lh	a5,74(a0)
    8000391e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003922:	04c56783          	lwu	a5,76(a0)
    80003926:	e99c                	sd	a5,16(a1)
}
    80003928:	6422                	ld	s0,8(sp)
    8000392a:	0141                	addi	sp,sp,16
    8000392c:	8082                	ret

000000008000392e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000392e:	457c                	lw	a5,76(a0)
    80003930:	0ed7eb63          	bltu	a5,a3,80003a26 <readi+0xf8>
{
    80003934:	7159                	addi	sp,sp,-112
    80003936:	f486                	sd	ra,104(sp)
    80003938:	f0a2                	sd	s0,96(sp)
    8000393a:	eca6                	sd	s1,88(sp)
    8000393c:	e0d2                	sd	s4,64(sp)
    8000393e:	fc56                	sd	s5,56(sp)
    80003940:	f85a                	sd	s6,48(sp)
    80003942:	f45e                	sd	s7,40(sp)
    80003944:	1880                	addi	s0,sp,112
    80003946:	8b2a                	mv	s6,a0
    80003948:	8bae                	mv	s7,a1
    8000394a:	8a32                	mv	s4,a2
    8000394c:	84b6                	mv	s1,a3
    8000394e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003950:	9f35                	addw	a4,a4,a3
    return 0;
    80003952:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003954:	0cd76063          	bltu	a4,a3,80003a14 <readi+0xe6>
    80003958:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    8000395a:	00e7f463          	bgeu	a5,a4,80003962 <readi+0x34>
    n = ip->size - off;
    8000395e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003962:	080a8f63          	beqz	s5,80003a00 <readi+0xd2>
    80003966:	e8ca                	sd	s2,80(sp)
    80003968:	f062                	sd	s8,32(sp)
    8000396a:	ec66                	sd	s9,24(sp)
    8000396c:	e86a                	sd	s10,16(sp)
    8000396e:	e46e                	sd	s11,8(sp)
    80003970:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003972:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003976:	5c7d                	li	s8,-1
    80003978:	a80d                	j	800039aa <readi+0x7c>
    8000397a:	020d1d93          	slli	s11,s10,0x20
    8000397e:	020ddd93          	srli	s11,s11,0x20
    80003982:	05890613          	addi	a2,s2,88
    80003986:	86ee                	mv	a3,s11
    80003988:	963a                	add	a2,a2,a4
    8000398a:	85d2                	mv	a1,s4
    8000398c:	855e                	mv	a0,s7
    8000398e:	969fe0ef          	jal	800022f6 <either_copyout>
    80003992:	05850763          	beq	a0,s8,800039e0 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003996:	854a                	mv	a0,s2
    80003998:	e42ff0ef          	jal	80002fda <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000399c:	013d09bb          	addw	s3,s10,s3
    800039a0:	009d04bb          	addw	s1,s10,s1
    800039a4:	9a6e                	add	s4,s4,s11
    800039a6:	0559f763          	bgeu	s3,s5,800039f4 <readi+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    800039aa:	00a4d59b          	srliw	a1,s1,0xa
    800039ae:	855a                	mv	a0,s6
    800039b0:	8a7ff0ef          	jal	80003256 <bmap>
    800039b4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800039b8:	c5b1                	beqz	a1,80003a04 <readi+0xd6>
    bp = bread(ip->dev, addr);
    800039ba:	000b2503          	lw	a0,0(s6)
    800039be:	d14ff0ef          	jal	80002ed2 <bread>
    800039c2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039c4:	3ff4f713          	andi	a4,s1,1023
    800039c8:	40ec87bb          	subw	a5,s9,a4
    800039cc:	413a86bb          	subw	a3,s5,s3
    800039d0:	8d3e                	mv	s10,a5
    800039d2:	2781                	sext.w	a5,a5
    800039d4:	0006861b          	sext.w	a2,a3
    800039d8:	faf671e3          	bgeu	a2,a5,8000397a <readi+0x4c>
    800039dc:	8d36                	mv	s10,a3
    800039de:	bf71                	j	8000397a <readi+0x4c>
      brelse(bp);
    800039e0:	854a                	mv	a0,s2
    800039e2:	df8ff0ef          	jal	80002fda <brelse>
      tot = -1;
    800039e6:	59fd                	li	s3,-1
      break;
    800039e8:	6946                	ld	s2,80(sp)
    800039ea:	7c02                	ld	s8,32(sp)
    800039ec:	6ce2                	ld	s9,24(sp)
    800039ee:	6d42                	ld	s10,16(sp)
    800039f0:	6da2                	ld	s11,8(sp)
    800039f2:	a831                	j	80003a0e <readi+0xe0>
    800039f4:	6946                	ld	s2,80(sp)
    800039f6:	7c02                	ld	s8,32(sp)
    800039f8:	6ce2                	ld	s9,24(sp)
    800039fa:	6d42                	ld	s10,16(sp)
    800039fc:	6da2                	ld	s11,8(sp)
    800039fe:	a801                	j	80003a0e <readi+0xe0>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a00:	89d6                	mv	s3,s5
    80003a02:	a031                	j	80003a0e <readi+0xe0>
    80003a04:	6946                	ld	s2,80(sp)
    80003a06:	7c02                	ld	s8,32(sp)
    80003a08:	6ce2                	ld	s9,24(sp)
    80003a0a:	6d42                	ld	s10,16(sp)
    80003a0c:	6da2                	ld	s11,8(sp)
  }
  return tot;
    80003a0e:	0009851b          	sext.w	a0,s3
    80003a12:	69a6                	ld	s3,72(sp)
}
    80003a14:	70a6                	ld	ra,104(sp)
    80003a16:	7406                	ld	s0,96(sp)
    80003a18:	64e6                	ld	s1,88(sp)
    80003a1a:	6a06                	ld	s4,64(sp)
    80003a1c:	7ae2                	ld	s5,56(sp)
    80003a1e:	7b42                	ld	s6,48(sp)
    80003a20:	7ba2                	ld	s7,40(sp)
    80003a22:	6165                	addi	sp,sp,112
    80003a24:	8082                	ret
    return 0;
    80003a26:	4501                	li	a0,0
}
    80003a28:	8082                	ret

0000000080003a2a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a2a:	457c                	lw	a5,76(a0)
    80003a2c:	10d7e063          	bltu	a5,a3,80003b2c <writei+0x102>
{
    80003a30:	7159                	addi	sp,sp,-112
    80003a32:	f486                	sd	ra,104(sp)
    80003a34:	f0a2                	sd	s0,96(sp)
    80003a36:	e8ca                	sd	s2,80(sp)
    80003a38:	e0d2                	sd	s4,64(sp)
    80003a3a:	fc56                	sd	s5,56(sp)
    80003a3c:	f85a                	sd	s6,48(sp)
    80003a3e:	f45e                	sd	s7,40(sp)
    80003a40:	1880                	addi	s0,sp,112
    80003a42:	8aaa                	mv	s5,a0
    80003a44:	8bae                	mv	s7,a1
    80003a46:	8a32                	mv	s4,a2
    80003a48:	8936                	mv	s2,a3
    80003a4a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a4c:	00e687bb          	addw	a5,a3,a4
    80003a50:	0ed7e063          	bltu	a5,a3,80003b30 <writei+0x106>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a54:	00043737          	lui	a4,0x43
    80003a58:	0cf76e63          	bltu	a4,a5,80003b34 <writei+0x10a>
    80003a5c:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a5e:	0a0b0f63          	beqz	s6,80003b1c <writei+0xf2>
    80003a62:	eca6                	sd	s1,88(sp)
    80003a64:	f062                	sd	s8,32(sp)
    80003a66:	ec66                	sd	s9,24(sp)
    80003a68:	e86a                	sd	s10,16(sp)
    80003a6a:	e46e                	sd	s11,8(sp)
    80003a6c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a72:	5c7d                	li	s8,-1
    80003a74:	a825                	j	80003aac <writei+0x82>
    80003a76:	020d1d93          	slli	s11,s10,0x20
    80003a7a:	020ddd93          	srli	s11,s11,0x20
    80003a7e:	05848513          	addi	a0,s1,88
    80003a82:	86ee                	mv	a3,s11
    80003a84:	8652                	mv	a2,s4
    80003a86:	85de                	mv	a1,s7
    80003a88:	953a                	add	a0,a0,a4
    80003a8a:	8b7fe0ef          	jal	80002340 <either_copyin>
    80003a8e:	05850a63          	beq	a0,s8,80003ae2 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a92:	8526                	mv	a0,s1
    80003a94:	678000ef          	jal	8000410c <log_write>
    brelse(bp);
    80003a98:	8526                	mv	a0,s1
    80003a9a:	d40ff0ef          	jal	80002fda <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a9e:	013d09bb          	addw	s3,s10,s3
    80003aa2:	012d093b          	addw	s2,s10,s2
    80003aa6:	9a6e                	add	s4,s4,s11
    80003aa8:	0569f063          	bgeu	s3,s6,80003ae8 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    80003aac:	00a9559b          	srliw	a1,s2,0xa
    80003ab0:	8556                	mv	a0,s5
    80003ab2:	fa4ff0ef          	jal	80003256 <bmap>
    80003ab6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003aba:	c59d                	beqz	a1,80003ae8 <writei+0xbe>
    bp = bread(ip->dev, addr);
    80003abc:	000aa503          	lw	a0,0(s5)
    80003ac0:	c12ff0ef          	jal	80002ed2 <bread>
    80003ac4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac6:	3ff97713          	andi	a4,s2,1023
    80003aca:	40ec87bb          	subw	a5,s9,a4
    80003ace:	413b06bb          	subw	a3,s6,s3
    80003ad2:	8d3e                	mv	s10,a5
    80003ad4:	2781                	sext.w	a5,a5
    80003ad6:	0006861b          	sext.w	a2,a3
    80003ada:	f8f67ee3          	bgeu	a2,a5,80003a76 <writei+0x4c>
    80003ade:	8d36                	mv	s10,a3
    80003ae0:	bf59                	j	80003a76 <writei+0x4c>
      brelse(bp);
    80003ae2:	8526                	mv	a0,s1
    80003ae4:	cf6ff0ef          	jal	80002fda <brelse>
  }

  if(off > ip->size)
    80003ae8:	04caa783          	lw	a5,76(s5)
    80003aec:	0327fa63          	bgeu	a5,s2,80003b20 <writei+0xf6>
    ip->size = off;
    80003af0:	052aa623          	sw	s2,76(s5)
    80003af4:	64e6                	ld	s1,88(sp)
    80003af6:	7c02                	ld	s8,32(sp)
    80003af8:	6ce2                	ld	s9,24(sp)
    80003afa:	6d42                	ld	s10,16(sp)
    80003afc:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003afe:	8556                	mv	a0,s5
    80003b00:	9ebff0ef          	jal	800034ea <iupdate>

  return tot;
    80003b04:	0009851b          	sext.w	a0,s3
    80003b08:	69a6                	ld	s3,72(sp)
}
    80003b0a:	70a6                	ld	ra,104(sp)
    80003b0c:	7406                	ld	s0,96(sp)
    80003b0e:	6946                	ld	s2,80(sp)
    80003b10:	6a06                	ld	s4,64(sp)
    80003b12:	7ae2                	ld	s5,56(sp)
    80003b14:	7b42                	ld	s6,48(sp)
    80003b16:	7ba2                	ld	s7,40(sp)
    80003b18:	6165                	addi	sp,sp,112
    80003b1a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b1c:	89da                	mv	s3,s6
    80003b1e:	b7c5                	j	80003afe <writei+0xd4>
    80003b20:	64e6                	ld	s1,88(sp)
    80003b22:	7c02                	ld	s8,32(sp)
    80003b24:	6ce2                	ld	s9,24(sp)
    80003b26:	6d42                	ld	s10,16(sp)
    80003b28:	6da2                	ld	s11,8(sp)
    80003b2a:	bfd1                	j	80003afe <writei+0xd4>
    return -1;
    80003b2c:	557d                	li	a0,-1
}
    80003b2e:	8082                	ret
    return -1;
    80003b30:	557d                	li	a0,-1
    80003b32:	bfe1                	j	80003b0a <writei+0xe0>
    return -1;
    80003b34:	557d                	li	a0,-1
    80003b36:	bfd1                	j	80003b0a <writei+0xe0>

0000000080003b38 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b38:	1141                	addi	sp,sp,-16
    80003b3a:	e406                	sd	ra,8(sp)
    80003b3c:	e022                	sd	s0,0(sp)
    80003b3e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b40:	4639                	li	a2,14
    80003b42:	a6efd0ef          	jal	80000db0 <strncmp>
}
    80003b46:	60a2                	ld	ra,8(sp)
    80003b48:	6402                	ld	s0,0(sp)
    80003b4a:	0141                	addi	sp,sp,16
    80003b4c:	8082                	ret

0000000080003b4e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b4e:	7139                	addi	sp,sp,-64
    80003b50:	fc06                	sd	ra,56(sp)
    80003b52:	f822                	sd	s0,48(sp)
    80003b54:	f426                	sd	s1,40(sp)
    80003b56:	f04a                	sd	s2,32(sp)
    80003b58:	ec4e                	sd	s3,24(sp)
    80003b5a:	e852                	sd	s4,16(sp)
    80003b5c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b5e:	04451703          	lh	a4,68(a0)
    80003b62:	4785                	li	a5,1
    80003b64:	00f71a63          	bne	a4,a5,80003b78 <dirlookup+0x2a>
    80003b68:	892a                	mv	s2,a0
    80003b6a:	89ae                	mv	s3,a1
    80003b6c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b6e:	457c                	lw	a5,76(a0)
    80003b70:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b72:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b74:	e39d                	bnez	a5,80003b9a <dirlookup+0x4c>
    80003b76:	a095                	j	80003bda <dirlookup+0x8c>
    panic("dirlookup not DIR");
    80003b78:	00004517          	auipc	a0,0x4
    80003b7c:	a3850513          	addi	a0,a0,-1480 # 800075b0 <etext+0x5b0>
    80003b80:	c61fc0ef          	jal	800007e0 <panic>
      panic("dirlookup read");
    80003b84:	00004517          	auipc	a0,0x4
    80003b88:	a4450513          	addi	a0,a0,-1468 # 800075c8 <etext+0x5c8>
    80003b8c:	c55fc0ef          	jal	800007e0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b90:	24c1                	addiw	s1,s1,16
    80003b92:	04c92783          	lw	a5,76(s2)
    80003b96:	04f4f163          	bgeu	s1,a5,80003bd8 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b9a:	4741                	li	a4,16
    80003b9c:	86a6                	mv	a3,s1
    80003b9e:	fc040613          	addi	a2,s0,-64
    80003ba2:	4581                	li	a1,0
    80003ba4:	854a                	mv	a0,s2
    80003ba6:	d89ff0ef          	jal	8000392e <readi>
    80003baa:	47c1                	li	a5,16
    80003bac:	fcf51ce3          	bne	a0,a5,80003b84 <dirlookup+0x36>
    if(de.inum == 0)
    80003bb0:	fc045783          	lhu	a5,-64(s0)
    80003bb4:	dff1                	beqz	a5,80003b90 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003bb6:	fc240593          	addi	a1,s0,-62
    80003bba:	854e                	mv	a0,s3
    80003bbc:	f7dff0ef          	jal	80003b38 <namecmp>
    80003bc0:	f961                	bnez	a0,80003b90 <dirlookup+0x42>
      if(poff)
    80003bc2:	000a0463          	beqz	s4,80003bca <dirlookup+0x7c>
        *poff = off;
    80003bc6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bca:	fc045583          	lhu	a1,-64(s0)
    80003bce:	00092503          	lw	a0,0(s2)
    80003bd2:	f58ff0ef          	jal	8000332a <iget>
    80003bd6:	a011                	j	80003bda <dirlookup+0x8c>
  return 0;
    80003bd8:	4501                	li	a0,0
}
    80003bda:	70e2                	ld	ra,56(sp)
    80003bdc:	7442                	ld	s0,48(sp)
    80003bde:	74a2                	ld	s1,40(sp)
    80003be0:	7902                	ld	s2,32(sp)
    80003be2:	69e2                	ld	s3,24(sp)
    80003be4:	6a42                	ld	s4,16(sp)
    80003be6:	6121                	addi	sp,sp,64
    80003be8:	8082                	ret

0000000080003bea <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003bea:	711d                	addi	sp,sp,-96
    80003bec:	ec86                	sd	ra,88(sp)
    80003bee:	e8a2                	sd	s0,80(sp)
    80003bf0:	e4a6                	sd	s1,72(sp)
    80003bf2:	e0ca                	sd	s2,64(sp)
    80003bf4:	fc4e                	sd	s3,56(sp)
    80003bf6:	f852                	sd	s4,48(sp)
    80003bf8:	f456                	sd	s5,40(sp)
    80003bfa:	f05a                	sd	s6,32(sp)
    80003bfc:	ec5e                	sd	s7,24(sp)
    80003bfe:	e862                	sd	s8,16(sp)
    80003c00:	e466                	sd	s9,8(sp)
    80003c02:	1080                	addi	s0,sp,96
    80003c04:	84aa                	mv	s1,a0
    80003c06:	8b2e                	mv	s6,a1
    80003c08:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c0a:	00054703          	lbu	a4,0(a0)
    80003c0e:	02f00793          	li	a5,47
    80003c12:	00f70e63          	beq	a4,a5,80003c2e <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c16:	cfbfd0ef          	jal	80001910 <myproc>
    80003c1a:	15053503          	ld	a0,336(a0)
    80003c1e:	94bff0ef          	jal	80003568 <idup>
    80003c22:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c24:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c28:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c2a:	4b85                	li	s7,1
    80003c2c:	a871                	j	80003cc8 <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    80003c2e:	4585                	li	a1,1
    80003c30:	4505                	li	a0,1
    80003c32:	ef8ff0ef          	jal	8000332a <iget>
    80003c36:	8a2a                	mv	s4,a0
    80003c38:	b7f5                	j	80003c24 <namex+0x3a>
      iunlockput(ip);
    80003c3a:	8552                	mv	a0,s4
    80003c3c:	b6dff0ef          	jal	800037a8 <iunlockput>
      return 0;
    80003c40:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c42:	8552                	mv	a0,s4
    80003c44:	60e6                	ld	ra,88(sp)
    80003c46:	6446                	ld	s0,80(sp)
    80003c48:	64a6                	ld	s1,72(sp)
    80003c4a:	6906                	ld	s2,64(sp)
    80003c4c:	79e2                	ld	s3,56(sp)
    80003c4e:	7a42                	ld	s4,48(sp)
    80003c50:	7aa2                	ld	s5,40(sp)
    80003c52:	7b02                	ld	s6,32(sp)
    80003c54:	6be2                	ld	s7,24(sp)
    80003c56:	6c42                	ld	s8,16(sp)
    80003c58:	6ca2                	ld	s9,8(sp)
    80003c5a:	6125                	addi	sp,sp,96
    80003c5c:	8082                	ret
      iunlock(ip);
    80003c5e:	8552                	mv	a0,s4
    80003c60:	9edff0ef          	jal	8000364c <iunlock>
      return ip;
    80003c64:	bff9                	j	80003c42 <namex+0x58>
      iunlockput(ip);
    80003c66:	8552                	mv	a0,s4
    80003c68:	b41ff0ef          	jal	800037a8 <iunlockput>
      return 0;
    80003c6c:	8a4e                	mv	s4,s3
    80003c6e:	bfd1                	j	80003c42 <namex+0x58>
  len = path - s;
    80003c70:	40998633          	sub	a2,s3,s1
    80003c74:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003c78:	099c5063          	bge	s8,s9,80003cf8 <namex+0x10e>
    memmove(name, s, DIRSIZ);
    80003c7c:	4639                	li	a2,14
    80003c7e:	85a6                	mv	a1,s1
    80003c80:	8556                	mv	a0,s5
    80003c82:	8befd0ef          	jal	80000d40 <memmove>
    80003c86:	84ce                	mv	s1,s3
  while(*path == '/')
    80003c88:	0004c783          	lbu	a5,0(s1)
    80003c8c:	01279763          	bne	a5,s2,80003c9a <namex+0xb0>
    path++;
    80003c90:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c92:	0004c783          	lbu	a5,0(s1)
    80003c96:	ff278de3          	beq	a5,s2,80003c90 <namex+0xa6>
    ilock(ip);
    80003c9a:	8552                	mv	a0,s4
    80003c9c:	903ff0ef          	jal	8000359e <ilock>
    if(ip->type != T_DIR){
    80003ca0:	044a1783          	lh	a5,68(s4)
    80003ca4:	f9779be3          	bne	a5,s7,80003c3a <namex+0x50>
    if(nameiparent && *path == '\0'){
    80003ca8:	000b0563          	beqz	s6,80003cb2 <namex+0xc8>
    80003cac:	0004c783          	lbu	a5,0(s1)
    80003cb0:	d7dd                	beqz	a5,80003c5e <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cb2:	4601                	li	a2,0
    80003cb4:	85d6                	mv	a1,s5
    80003cb6:	8552                	mv	a0,s4
    80003cb8:	e97ff0ef          	jal	80003b4e <dirlookup>
    80003cbc:	89aa                	mv	s3,a0
    80003cbe:	d545                	beqz	a0,80003c66 <namex+0x7c>
    iunlockput(ip);
    80003cc0:	8552                	mv	a0,s4
    80003cc2:	ae7ff0ef          	jal	800037a8 <iunlockput>
    ip = next;
    80003cc6:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003cc8:	0004c783          	lbu	a5,0(s1)
    80003ccc:	01279763          	bne	a5,s2,80003cda <namex+0xf0>
    path++;
    80003cd0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cd2:	0004c783          	lbu	a5,0(s1)
    80003cd6:	ff278de3          	beq	a5,s2,80003cd0 <namex+0xe6>
  if(*path == 0)
    80003cda:	cb8d                	beqz	a5,80003d0c <namex+0x122>
  while(*path != '/' && *path != 0)
    80003cdc:	0004c783          	lbu	a5,0(s1)
    80003ce0:	89a6                	mv	s3,s1
  len = path - s;
    80003ce2:	4c81                	li	s9,0
    80003ce4:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003ce6:	01278963          	beq	a5,s2,80003cf8 <namex+0x10e>
    80003cea:	d3d9                	beqz	a5,80003c70 <namex+0x86>
    path++;
    80003cec:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003cee:	0009c783          	lbu	a5,0(s3)
    80003cf2:	ff279ce3          	bne	a5,s2,80003cea <namex+0x100>
    80003cf6:	bfad                	j	80003c70 <namex+0x86>
    memmove(name, s, len);
    80003cf8:	2601                	sext.w	a2,a2
    80003cfa:	85a6                	mv	a1,s1
    80003cfc:	8556                	mv	a0,s5
    80003cfe:	842fd0ef          	jal	80000d40 <memmove>
    name[len] = 0;
    80003d02:	9cd6                	add	s9,s9,s5
    80003d04:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d08:	84ce                	mv	s1,s3
    80003d0a:	bfbd                	j	80003c88 <namex+0x9e>
  if(nameiparent){
    80003d0c:	f20b0be3          	beqz	s6,80003c42 <namex+0x58>
    iput(ip);
    80003d10:	8552                	mv	a0,s4
    80003d12:	a0fff0ef          	jal	80003720 <iput>
    return 0;
    80003d16:	4a01                	li	s4,0
    80003d18:	b72d                	j	80003c42 <namex+0x58>

0000000080003d1a <dirlink>:
{
    80003d1a:	7139                	addi	sp,sp,-64
    80003d1c:	fc06                	sd	ra,56(sp)
    80003d1e:	f822                	sd	s0,48(sp)
    80003d20:	f04a                	sd	s2,32(sp)
    80003d22:	ec4e                	sd	s3,24(sp)
    80003d24:	e852                	sd	s4,16(sp)
    80003d26:	0080                	addi	s0,sp,64
    80003d28:	892a                	mv	s2,a0
    80003d2a:	8a2e                	mv	s4,a1
    80003d2c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d2e:	4601                	li	a2,0
    80003d30:	e1fff0ef          	jal	80003b4e <dirlookup>
    80003d34:	e535                	bnez	a0,80003da0 <dirlink+0x86>
    80003d36:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d38:	04c92483          	lw	s1,76(s2)
    80003d3c:	c48d                	beqz	s1,80003d66 <dirlink+0x4c>
    80003d3e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d40:	4741                	li	a4,16
    80003d42:	86a6                	mv	a3,s1
    80003d44:	fc040613          	addi	a2,s0,-64
    80003d48:	4581                	li	a1,0
    80003d4a:	854a                	mv	a0,s2
    80003d4c:	be3ff0ef          	jal	8000392e <readi>
    80003d50:	47c1                	li	a5,16
    80003d52:	04f51b63          	bne	a0,a5,80003da8 <dirlink+0x8e>
    if(de.inum == 0)
    80003d56:	fc045783          	lhu	a5,-64(s0)
    80003d5a:	c791                	beqz	a5,80003d66 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d5c:	24c1                	addiw	s1,s1,16
    80003d5e:	04c92783          	lw	a5,76(s2)
    80003d62:	fcf4efe3          	bltu	s1,a5,80003d40 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003d66:	4639                	li	a2,14
    80003d68:	85d2                	mv	a1,s4
    80003d6a:	fc240513          	addi	a0,s0,-62
    80003d6e:	878fd0ef          	jal	80000de6 <strncpy>
  de.inum = inum;
    80003d72:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d76:	4741                	li	a4,16
    80003d78:	86a6                	mv	a3,s1
    80003d7a:	fc040613          	addi	a2,s0,-64
    80003d7e:	4581                	li	a1,0
    80003d80:	854a                	mv	a0,s2
    80003d82:	ca9ff0ef          	jal	80003a2a <writei>
    80003d86:	1541                	addi	a0,a0,-16
    80003d88:	00a03533          	snez	a0,a0
    80003d8c:	40a00533          	neg	a0,a0
    80003d90:	74a2                	ld	s1,40(sp)
}
    80003d92:	70e2                	ld	ra,56(sp)
    80003d94:	7442                	ld	s0,48(sp)
    80003d96:	7902                	ld	s2,32(sp)
    80003d98:	69e2                	ld	s3,24(sp)
    80003d9a:	6a42                	ld	s4,16(sp)
    80003d9c:	6121                	addi	sp,sp,64
    80003d9e:	8082                	ret
    iput(ip);
    80003da0:	981ff0ef          	jal	80003720 <iput>
    return -1;
    80003da4:	557d                	li	a0,-1
    80003da6:	b7f5                	j	80003d92 <dirlink+0x78>
      panic("dirlink read");
    80003da8:	00004517          	auipc	a0,0x4
    80003dac:	83050513          	addi	a0,a0,-2000 # 800075d8 <etext+0x5d8>
    80003db0:	a31fc0ef          	jal	800007e0 <panic>

0000000080003db4 <namei>:

struct inode*
namei(char *path)
{
    80003db4:	1101                	addi	sp,sp,-32
    80003db6:	ec06                	sd	ra,24(sp)
    80003db8:	e822                	sd	s0,16(sp)
    80003dba:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dbc:	fe040613          	addi	a2,s0,-32
    80003dc0:	4581                	li	a1,0
    80003dc2:	e29ff0ef          	jal	80003bea <namex>
}
    80003dc6:	60e2                	ld	ra,24(sp)
    80003dc8:	6442                	ld	s0,16(sp)
    80003dca:	6105                	addi	sp,sp,32
    80003dcc:	8082                	ret

0000000080003dce <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003dce:	1141                	addi	sp,sp,-16
    80003dd0:	e406                	sd	ra,8(sp)
    80003dd2:	e022                	sd	s0,0(sp)
    80003dd4:	0800                	addi	s0,sp,16
    80003dd6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dd8:	4585                	li	a1,1
    80003dda:	e11ff0ef          	jal	80003bea <namex>
}
    80003dde:	60a2                	ld	ra,8(sp)
    80003de0:	6402                	ld	s0,0(sp)
    80003de2:	0141                	addi	sp,sp,16
    80003de4:	8082                	ret

0000000080003de6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003de6:	1101                	addi	sp,sp,-32
    80003de8:	ec06                	sd	ra,24(sp)
    80003dea:	e822                	sd	s0,16(sp)
    80003dec:	e426                	sd	s1,8(sp)
    80003dee:	e04a                	sd	s2,0(sp)
    80003df0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003df2:	00020917          	auipc	s2,0x20
    80003df6:	a4690913          	addi	s2,s2,-1466 # 80023838 <log>
    80003dfa:	01892583          	lw	a1,24(s2)
    80003dfe:	02492503          	lw	a0,36(s2)
    80003e02:	8d0ff0ef          	jal	80002ed2 <bread>
    80003e06:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e08:	02892603          	lw	a2,40(s2)
    80003e0c:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e0e:	00c05f63          	blez	a2,80003e2c <write_head+0x46>
    80003e12:	00020717          	auipc	a4,0x20
    80003e16:	a5270713          	addi	a4,a4,-1454 # 80023864 <log+0x2c>
    80003e1a:	87aa                	mv	a5,a0
    80003e1c:	060a                	slli	a2,a2,0x2
    80003e1e:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003e20:	4314                	lw	a3,0(a4)
    80003e22:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003e24:	0711                	addi	a4,a4,4
    80003e26:	0791                	addi	a5,a5,4
    80003e28:	fec79ce3          	bne	a5,a2,80003e20 <write_head+0x3a>
  }
  bwrite(buf);
    80003e2c:	8526                	mv	a0,s1
    80003e2e:	97aff0ef          	jal	80002fa8 <bwrite>
  brelse(buf);
    80003e32:	8526                	mv	a0,s1
    80003e34:	9a6ff0ef          	jal	80002fda <brelse>
}
    80003e38:	60e2                	ld	ra,24(sp)
    80003e3a:	6442                	ld	s0,16(sp)
    80003e3c:	64a2                	ld	s1,8(sp)
    80003e3e:	6902                	ld	s2,0(sp)
    80003e40:	6105                	addi	sp,sp,32
    80003e42:	8082                	ret

0000000080003e44 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e44:	00020797          	auipc	a5,0x20
    80003e48:	a1c7a783          	lw	a5,-1508(a5) # 80023860 <log+0x28>
    80003e4c:	0af05e63          	blez	a5,80003f08 <install_trans+0xc4>
{
    80003e50:	715d                	addi	sp,sp,-80
    80003e52:	e486                	sd	ra,72(sp)
    80003e54:	e0a2                	sd	s0,64(sp)
    80003e56:	fc26                	sd	s1,56(sp)
    80003e58:	f84a                	sd	s2,48(sp)
    80003e5a:	f44e                	sd	s3,40(sp)
    80003e5c:	f052                	sd	s4,32(sp)
    80003e5e:	ec56                	sd	s5,24(sp)
    80003e60:	e85a                	sd	s6,16(sp)
    80003e62:	e45e                	sd	s7,8(sp)
    80003e64:	0880                	addi	s0,sp,80
    80003e66:	8b2a                	mv	s6,a0
    80003e68:	00020a97          	auipc	s5,0x20
    80003e6c:	9fca8a93          	addi	s5,s5,-1540 # 80023864 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e70:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003e72:	00003b97          	auipc	s7,0x3
    80003e76:	776b8b93          	addi	s7,s7,1910 # 800075e8 <etext+0x5e8>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e7a:	00020a17          	auipc	s4,0x20
    80003e7e:	9bea0a13          	addi	s4,s4,-1602 # 80023838 <log>
    80003e82:	a025                	j	80003eaa <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003e84:	000aa603          	lw	a2,0(s5)
    80003e88:	85ce                	mv	a1,s3
    80003e8a:	855e                	mv	a0,s7
    80003e8c:	e6efc0ef          	jal	800004fa <printf>
    80003e90:	a839                	j	80003eae <install_trans+0x6a>
    brelse(lbuf);
    80003e92:	854a                	mv	a0,s2
    80003e94:	946ff0ef          	jal	80002fda <brelse>
    brelse(dbuf);
    80003e98:	8526                	mv	a0,s1
    80003e9a:	940ff0ef          	jal	80002fda <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e9e:	2985                	addiw	s3,s3,1
    80003ea0:	0a91                	addi	s5,s5,4
    80003ea2:	028a2783          	lw	a5,40(s4)
    80003ea6:	04f9d663          	bge	s3,a5,80003ef2 <install_trans+0xae>
    if(recovering) {
    80003eaa:	fc0b1de3          	bnez	s6,80003e84 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003eae:	018a2583          	lw	a1,24(s4)
    80003eb2:	013585bb          	addw	a1,a1,s3
    80003eb6:	2585                	addiw	a1,a1,1
    80003eb8:	024a2503          	lw	a0,36(s4)
    80003ebc:	816ff0ef          	jal	80002ed2 <bread>
    80003ec0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ec2:	000aa583          	lw	a1,0(s5)
    80003ec6:	024a2503          	lw	a0,36(s4)
    80003eca:	808ff0ef          	jal	80002ed2 <bread>
    80003ece:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ed0:	40000613          	li	a2,1024
    80003ed4:	05890593          	addi	a1,s2,88
    80003ed8:	05850513          	addi	a0,a0,88
    80003edc:	e65fc0ef          	jal	80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ee0:	8526                	mv	a0,s1
    80003ee2:	8c6ff0ef          	jal	80002fa8 <bwrite>
    if(recovering == 0)
    80003ee6:	fa0b16e3          	bnez	s6,80003e92 <install_trans+0x4e>
      bunpin(dbuf);
    80003eea:	8526                	mv	a0,s1
    80003eec:	9aaff0ef          	jal	80003096 <bunpin>
    80003ef0:	b74d                	j	80003e92 <install_trans+0x4e>
}
    80003ef2:	60a6                	ld	ra,72(sp)
    80003ef4:	6406                	ld	s0,64(sp)
    80003ef6:	74e2                	ld	s1,56(sp)
    80003ef8:	7942                	ld	s2,48(sp)
    80003efa:	79a2                	ld	s3,40(sp)
    80003efc:	7a02                	ld	s4,32(sp)
    80003efe:	6ae2                	ld	s5,24(sp)
    80003f00:	6b42                	ld	s6,16(sp)
    80003f02:	6ba2                	ld	s7,8(sp)
    80003f04:	6161                	addi	sp,sp,80
    80003f06:	8082                	ret
    80003f08:	8082                	ret

0000000080003f0a <initlog>:
{
    80003f0a:	7179                	addi	sp,sp,-48
    80003f0c:	f406                	sd	ra,40(sp)
    80003f0e:	f022                	sd	s0,32(sp)
    80003f10:	ec26                	sd	s1,24(sp)
    80003f12:	e84a                	sd	s2,16(sp)
    80003f14:	e44e                	sd	s3,8(sp)
    80003f16:	1800                	addi	s0,sp,48
    80003f18:	892a                	mv	s2,a0
    80003f1a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f1c:	00020497          	auipc	s1,0x20
    80003f20:	91c48493          	addi	s1,s1,-1764 # 80023838 <log>
    80003f24:	00003597          	auipc	a1,0x3
    80003f28:	6e458593          	addi	a1,a1,1764 # 80007608 <etext+0x608>
    80003f2c:	8526                	mv	a0,s1
    80003f2e:	c63fc0ef          	jal	80000b90 <initlock>
  log.start = sb->logstart;
    80003f32:	0149a583          	lw	a1,20(s3)
    80003f36:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80003f38:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f3c:	854a                	mv	a0,s2
    80003f3e:	f95fe0ef          	jal	80002ed2 <bread>
  log.lh.n = lh->n;
    80003f42:	4d30                	lw	a2,88(a0)
    80003f44:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f46:	00c05f63          	blez	a2,80003f64 <initlog+0x5a>
    80003f4a:	87aa                	mv	a5,a0
    80003f4c:	00020717          	auipc	a4,0x20
    80003f50:	91870713          	addi	a4,a4,-1768 # 80023864 <log+0x2c>
    80003f54:	060a                	slli	a2,a2,0x2
    80003f56:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003f58:	4ff4                	lw	a3,92(a5)
    80003f5a:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f5c:	0791                	addi	a5,a5,4
    80003f5e:	0711                	addi	a4,a4,4
    80003f60:	fec79ce3          	bne	a5,a2,80003f58 <initlog+0x4e>
  brelse(buf);
    80003f64:	876ff0ef          	jal	80002fda <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f68:	4505                	li	a0,1
    80003f6a:	edbff0ef          	jal	80003e44 <install_trans>
  log.lh.n = 0;
    80003f6e:	00020797          	auipc	a5,0x20
    80003f72:	8e07a923          	sw	zero,-1806(a5) # 80023860 <log+0x28>
  write_head(); // clear the log
    80003f76:	e71ff0ef          	jal	80003de6 <write_head>
}
    80003f7a:	70a2                	ld	ra,40(sp)
    80003f7c:	7402                	ld	s0,32(sp)
    80003f7e:	64e2                	ld	s1,24(sp)
    80003f80:	6942                	ld	s2,16(sp)
    80003f82:	69a2                	ld	s3,8(sp)
    80003f84:	6145                	addi	sp,sp,48
    80003f86:	8082                	ret

0000000080003f88 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003f88:	1101                	addi	sp,sp,-32
    80003f8a:	ec06                	sd	ra,24(sp)
    80003f8c:	e822                	sd	s0,16(sp)
    80003f8e:	e426                	sd	s1,8(sp)
    80003f90:	e04a                	sd	s2,0(sp)
    80003f92:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003f94:	00020517          	auipc	a0,0x20
    80003f98:	8a450513          	addi	a0,a0,-1884 # 80023838 <log>
    80003f9c:	c75fc0ef          	jal	80000c10 <acquire>
  while(1){
    if(log.committing){
    80003fa0:	00020497          	auipc	s1,0x20
    80003fa4:	89848493          	addi	s1,s1,-1896 # 80023838 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003fa8:	4979                	li	s2,30
    80003faa:	a029                	j	80003fb4 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003fac:	85a6                	mv	a1,s1
    80003fae:	8526                	mv	a0,s1
    80003fb0:	febfd0ef          	jal	80001f9a <sleep>
    if(log.committing){
    80003fb4:	509c                	lw	a5,32(s1)
    80003fb6:	fbfd                	bnez	a5,80003fac <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003fb8:	4cd8                	lw	a4,28(s1)
    80003fba:	2705                	addiw	a4,a4,1
    80003fbc:	0027179b          	slliw	a5,a4,0x2
    80003fc0:	9fb9                	addw	a5,a5,a4
    80003fc2:	0017979b          	slliw	a5,a5,0x1
    80003fc6:	5494                	lw	a3,40(s1)
    80003fc8:	9fb5                	addw	a5,a5,a3
    80003fca:	00f95763          	bge	s2,a5,80003fd8 <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003fce:	85a6                	mv	a1,s1
    80003fd0:	8526                	mv	a0,s1
    80003fd2:	fc9fd0ef          	jal	80001f9a <sleep>
    80003fd6:	bff9                	j	80003fb4 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003fd8:	00020517          	auipc	a0,0x20
    80003fdc:	86050513          	addi	a0,a0,-1952 # 80023838 <log>
    80003fe0:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    80003fe2:	cc7fc0ef          	jal	80000ca8 <release>
      break;
    }
  }
}
    80003fe6:	60e2                	ld	ra,24(sp)
    80003fe8:	6442                	ld	s0,16(sp)
    80003fea:	64a2                	ld	s1,8(sp)
    80003fec:	6902                	ld	s2,0(sp)
    80003fee:	6105                	addi	sp,sp,32
    80003ff0:	8082                	ret

0000000080003ff2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003ff2:	7139                	addi	sp,sp,-64
    80003ff4:	fc06                	sd	ra,56(sp)
    80003ff6:	f822                	sd	s0,48(sp)
    80003ff8:	f426                	sd	s1,40(sp)
    80003ffa:	f04a                	sd	s2,32(sp)
    80003ffc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003ffe:	00020497          	auipc	s1,0x20
    80004002:	83a48493          	addi	s1,s1,-1990 # 80023838 <log>
    80004006:	8526                	mv	a0,s1
    80004008:	c09fc0ef          	jal	80000c10 <acquire>
  log.outstanding -= 1;
    8000400c:	4cdc                	lw	a5,28(s1)
    8000400e:	37fd                	addiw	a5,a5,-1
    80004010:	0007891b          	sext.w	s2,a5
    80004014:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80004016:	509c                	lw	a5,32(s1)
    80004018:	ef9d                	bnez	a5,80004056 <end_op+0x64>
    panic("log.committing");
  if(log.outstanding == 0){
    8000401a:	04091763          	bnez	s2,80004068 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    8000401e:	00020497          	auipc	s1,0x20
    80004022:	81a48493          	addi	s1,s1,-2022 # 80023838 <log>
    80004026:	4785                	li	a5,1
    80004028:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000402a:	8526                	mv	a0,s1
    8000402c:	c7dfc0ef          	jal	80000ca8 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004030:	549c                	lw	a5,40(s1)
    80004032:	04f04b63          	bgtz	a5,80004088 <end_op+0x96>
    acquire(&log.lock);
    80004036:	00020497          	auipc	s1,0x20
    8000403a:	80248493          	addi	s1,s1,-2046 # 80023838 <log>
    8000403e:	8526                	mv	a0,s1
    80004040:	bd1fc0ef          	jal	80000c10 <acquire>
    log.committing = 0;
    80004044:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80004048:	8526                	mv	a0,s1
    8000404a:	f9dfd0ef          	jal	80001fe6 <wakeup>
    release(&log.lock);
    8000404e:	8526                	mv	a0,s1
    80004050:	c59fc0ef          	jal	80000ca8 <release>
}
    80004054:	a025                	j	8000407c <end_op+0x8a>
    80004056:	ec4e                	sd	s3,24(sp)
    80004058:	e852                	sd	s4,16(sp)
    8000405a:	e456                	sd	s5,8(sp)
    panic("log.committing");
    8000405c:	00003517          	auipc	a0,0x3
    80004060:	5b450513          	addi	a0,a0,1460 # 80007610 <etext+0x610>
    80004064:	f7cfc0ef          	jal	800007e0 <panic>
    wakeup(&log);
    80004068:	0001f497          	auipc	s1,0x1f
    8000406c:	7d048493          	addi	s1,s1,2000 # 80023838 <log>
    80004070:	8526                	mv	a0,s1
    80004072:	f75fd0ef          	jal	80001fe6 <wakeup>
  release(&log.lock);
    80004076:	8526                	mv	a0,s1
    80004078:	c31fc0ef          	jal	80000ca8 <release>
}
    8000407c:	70e2                	ld	ra,56(sp)
    8000407e:	7442                	ld	s0,48(sp)
    80004080:	74a2                	ld	s1,40(sp)
    80004082:	7902                	ld	s2,32(sp)
    80004084:	6121                	addi	sp,sp,64
    80004086:	8082                	ret
    80004088:	ec4e                	sd	s3,24(sp)
    8000408a:	e852                	sd	s4,16(sp)
    8000408c:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    8000408e:	0001fa97          	auipc	s5,0x1f
    80004092:	7d6a8a93          	addi	s5,s5,2006 # 80023864 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004096:	0001fa17          	auipc	s4,0x1f
    8000409a:	7a2a0a13          	addi	s4,s4,1954 # 80023838 <log>
    8000409e:	018a2583          	lw	a1,24(s4)
    800040a2:	012585bb          	addw	a1,a1,s2
    800040a6:	2585                	addiw	a1,a1,1
    800040a8:	024a2503          	lw	a0,36(s4)
    800040ac:	e27fe0ef          	jal	80002ed2 <bread>
    800040b0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800040b2:	000aa583          	lw	a1,0(s5)
    800040b6:	024a2503          	lw	a0,36(s4)
    800040ba:	e19fe0ef          	jal	80002ed2 <bread>
    800040be:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800040c0:	40000613          	li	a2,1024
    800040c4:	05850593          	addi	a1,a0,88
    800040c8:	05848513          	addi	a0,s1,88
    800040cc:	c75fc0ef          	jal	80000d40 <memmove>
    bwrite(to);  // write the log
    800040d0:	8526                	mv	a0,s1
    800040d2:	ed7fe0ef          	jal	80002fa8 <bwrite>
    brelse(from);
    800040d6:	854e                	mv	a0,s3
    800040d8:	f03fe0ef          	jal	80002fda <brelse>
    brelse(to);
    800040dc:	8526                	mv	a0,s1
    800040de:	efdfe0ef          	jal	80002fda <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040e2:	2905                	addiw	s2,s2,1
    800040e4:	0a91                	addi	s5,s5,4
    800040e6:	028a2783          	lw	a5,40(s4)
    800040ea:	faf94ae3          	blt	s2,a5,8000409e <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800040ee:	cf9ff0ef          	jal	80003de6 <write_head>
    install_trans(0); // Now install writes to home locations
    800040f2:	4501                	li	a0,0
    800040f4:	d51ff0ef          	jal	80003e44 <install_trans>
    log.lh.n = 0;
    800040f8:	0001f797          	auipc	a5,0x1f
    800040fc:	7607a423          	sw	zero,1896(a5) # 80023860 <log+0x28>
    write_head();    // Erase the transaction from the log
    80004100:	ce7ff0ef          	jal	80003de6 <write_head>
    80004104:	69e2                	ld	s3,24(sp)
    80004106:	6a42                	ld	s4,16(sp)
    80004108:	6aa2                	ld	s5,8(sp)
    8000410a:	b735                	j	80004036 <end_op+0x44>

000000008000410c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000410c:	1101                	addi	sp,sp,-32
    8000410e:	ec06                	sd	ra,24(sp)
    80004110:	e822                	sd	s0,16(sp)
    80004112:	e426                	sd	s1,8(sp)
    80004114:	e04a                	sd	s2,0(sp)
    80004116:	1000                	addi	s0,sp,32
    80004118:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000411a:	0001f917          	auipc	s2,0x1f
    8000411e:	71e90913          	addi	s2,s2,1822 # 80023838 <log>
    80004122:	854a                	mv	a0,s2
    80004124:	aedfc0ef          	jal	80000c10 <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80004128:	02892603          	lw	a2,40(s2)
    8000412c:	47f5                	li	a5,29
    8000412e:	04c7cc63          	blt	a5,a2,80004186 <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004132:	0001f797          	auipc	a5,0x1f
    80004136:	7227a783          	lw	a5,1826(a5) # 80023854 <log+0x1c>
    8000413a:	04f05c63          	blez	a5,80004192 <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000413e:	4781                	li	a5,0
    80004140:	04c05f63          	blez	a2,8000419e <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004144:	44cc                	lw	a1,12(s1)
    80004146:	0001f717          	auipc	a4,0x1f
    8000414a:	71e70713          	addi	a4,a4,1822 # 80023864 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    8000414e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004150:	4314                	lw	a3,0(a4)
    80004152:	04b68663          	beq	a3,a1,8000419e <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80004156:	2785                	addiw	a5,a5,1
    80004158:	0711                	addi	a4,a4,4
    8000415a:	fef61be3          	bne	a2,a5,80004150 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000415e:	0621                	addi	a2,a2,8
    80004160:	060a                	slli	a2,a2,0x2
    80004162:	0001f797          	auipc	a5,0x1f
    80004166:	6d678793          	addi	a5,a5,1750 # 80023838 <log>
    8000416a:	97b2                	add	a5,a5,a2
    8000416c:	44d8                	lw	a4,12(s1)
    8000416e:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004170:	8526                	mv	a0,s1
    80004172:	ef1fe0ef          	jal	80003062 <bpin>
    log.lh.n++;
    80004176:	0001f717          	auipc	a4,0x1f
    8000417a:	6c270713          	addi	a4,a4,1730 # 80023838 <log>
    8000417e:	571c                	lw	a5,40(a4)
    80004180:	2785                	addiw	a5,a5,1
    80004182:	d71c                	sw	a5,40(a4)
    80004184:	a80d                	j	800041b6 <log_write+0xaa>
    panic("too big a transaction");
    80004186:	00003517          	auipc	a0,0x3
    8000418a:	49a50513          	addi	a0,a0,1178 # 80007620 <etext+0x620>
    8000418e:	e52fc0ef          	jal	800007e0 <panic>
    panic("log_write outside of trans");
    80004192:	00003517          	auipc	a0,0x3
    80004196:	4a650513          	addi	a0,a0,1190 # 80007638 <etext+0x638>
    8000419a:	e46fc0ef          	jal	800007e0 <panic>
  log.lh.block[i] = b->blockno;
    8000419e:	00878693          	addi	a3,a5,8
    800041a2:	068a                	slli	a3,a3,0x2
    800041a4:	0001f717          	auipc	a4,0x1f
    800041a8:	69470713          	addi	a4,a4,1684 # 80023838 <log>
    800041ac:	9736                	add	a4,a4,a3
    800041ae:	44d4                	lw	a3,12(s1)
    800041b0:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800041b2:	faf60fe3          	beq	a2,a5,80004170 <log_write+0x64>
  }
  release(&log.lock);
    800041b6:	0001f517          	auipc	a0,0x1f
    800041ba:	68250513          	addi	a0,a0,1666 # 80023838 <log>
    800041be:	aebfc0ef          	jal	80000ca8 <release>
}
    800041c2:	60e2                	ld	ra,24(sp)
    800041c4:	6442                	ld	s0,16(sp)
    800041c6:	64a2                	ld	s1,8(sp)
    800041c8:	6902                	ld	s2,0(sp)
    800041ca:	6105                	addi	sp,sp,32
    800041cc:	8082                	ret

00000000800041ce <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800041ce:	1101                	addi	sp,sp,-32
    800041d0:	ec06                	sd	ra,24(sp)
    800041d2:	e822                	sd	s0,16(sp)
    800041d4:	e426                	sd	s1,8(sp)
    800041d6:	e04a                	sd	s2,0(sp)
    800041d8:	1000                	addi	s0,sp,32
    800041da:	84aa                	mv	s1,a0
    800041dc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800041de:	00003597          	auipc	a1,0x3
    800041e2:	47a58593          	addi	a1,a1,1146 # 80007658 <etext+0x658>
    800041e6:	0521                	addi	a0,a0,8
    800041e8:	9a9fc0ef          	jal	80000b90 <initlock>
  lk->name = name;
    800041ec:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800041f0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800041f4:	0204a423          	sw	zero,40(s1)
}
    800041f8:	60e2                	ld	ra,24(sp)
    800041fa:	6442                	ld	s0,16(sp)
    800041fc:	64a2                	ld	s1,8(sp)
    800041fe:	6902                	ld	s2,0(sp)
    80004200:	6105                	addi	sp,sp,32
    80004202:	8082                	ret

0000000080004204 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004204:	1101                	addi	sp,sp,-32
    80004206:	ec06                	sd	ra,24(sp)
    80004208:	e822                	sd	s0,16(sp)
    8000420a:	e426                	sd	s1,8(sp)
    8000420c:	e04a                	sd	s2,0(sp)
    8000420e:	1000                	addi	s0,sp,32
    80004210:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004212:	00850913          	addi	s2,a0,8
    80004216:	854a                	mv	a0,s2
    80004218:	9f9fc0ef          	jal	80000c10 <acquire>
  while (lk->locked) {
    8000421c:	409c                	lw	a5,0(s1)
    8000421e:	c799                	beqz	a5,8000422c <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80004220:	85ca                	mv	a1,s2
    80004222:	8526                	mv	a0,s1
    80004224:	d77fd0ef          	jal	80001f9a <sleep>
  while (lk->locked) {
    80004228:	409c                	lw	a5,0(s1)
    8000422a:	fbfd                	bnez	a5,80004220 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    8000422c:	4785                	li	a5,1
    8000422e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004230:	ee0fd0ef          	jal	80001910 <myproc>
    80004234:	591c                	lw	a5,48(a0)
    80004236:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004238:	854a                	mv	a0,s2
    8000423a:	a6ffc0ef          	jal	80000ca8 <release>
}
    8000423e:	60e2                	ld	ra,24(sp)
    80004240:	6442                	ld	s0,16(sp)
    80004242:	64a2                	ld	s1,8(sp)
    80004244:	6902                	ld	s2,0(sp)
    80004246:	6105                	addi	sp,sp,32
    80004248:	8082                	ret

000000008000424a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000424a:	1101                	addi	sp,sp,-32
    8000424c:	ec06                	sd	ra,24(sp)
    8000424e:	e822                	sd	s0,16(sp)
    80004250:	e426                	sd	s1,8(sp)
    80004252:	e04a                	sd	s2,0(sp)
    80004254:	1000                	addi	s0,sp,32
    80004256:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004258:	00850913          	addi	s2,a0,8
    8000425c:	854a                	mv	a0,s2
    8000425e:	9b3fc0ef          	jal	80000c10 <acquire>
  lk->locked = 0;
    80004262:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004266:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000426a:	8526                	mv	a0,s1
    8000426c:	d7bfd0ef          	jal	80001fe6 <wakeup>
  release(&lk->lk);
    80004270:	854a                	mv	a0,s2
    80004272:	a37fc0ef          	jal	80000ca8 <release>
}
    80004276:	60e2                	ld	ra,24(sp)
    80004278:	6442                	ld	s0,16(sp)
    8000427a:	64a2                	ld	s1,8(sp)
    8000427c:	6902                	ld	s2,0(sp)
    8000427e:	6105                	addi	sp,sp,32
    80004280:	8082                	ret

0000000080004282 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004282:	7179                	addi	sp,sp,-48
    80004284:	f406                	sd	ra,40(sp)
    80004286:	f022                	sd	s0,32(sp)
    80004288:	ec26                	sd	s1,24(sp)
    8000428a:	e84a                	sd	s2,16(sp)
    8000428c:	1800                	addi	s0,sp,48
    8000428e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004290:	00850913          	addi	s2,a0,8
    80004294:	854a                	mv	a0,s2
    80004296:	97bfc0ef          	jal	80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000429a:	409c                	lw	a5,0(s1)
    8000429c:	ef81                	bnez	a5,800042b4 <holdingsleep+0x32>
    8000429e:	4481                	li	s1,0
  release(&lk->lk);
    800042a0:	854a                	mv	a0,s2
    800042a2:	a07fc0ef          	jal	80000ca8 <release>
  return r;
}
    800042a6:	8526                	mv	a0,s1
    800042a8:	70a2                	ld	ra,40(sp)
    800042aa:	7402                	ld	s0,32(sp)
    800042ac:	64e2                	ld	s1,24(sp)
    800042ae:	6942                	ld	s2,16(sp)
    800042b0:	6145                	addi	sp,sp,48
    800042b2:	8082                	ret
    800042b4:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    800042b6:	0284a983          	lw	s3,40(s1)
    800042ba:	e56fd0ef          	jal	80001910 <myproc>
    800042be:	5904                	lw	s1,48(a0)
    800042c0:	413484b3          	sub	s1,s1,s3
    800042c4:	0014b493          	seqz	s1,s1
    800042c8:	69a2                	ld	s3,8(sp)
    800042ca:	bfd9                	j	800042a0 <holdingsleep+0x1e>

00000000800042cc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800042cc:	1141                	addi	sp,sp,-16
    800042ce:	e406                	sd	ra,8(sp)
    800042d0:	e022                	sd	s0,0(sp)
    800042d2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800042d4:	00003597          	auipc	a1,0x3
    800042d8:	39458593          	addi	a1,a1,916 # 80007668 <etext+0x668>
    800042dc:	0001f517          	auipc	a0,0x1f
    800042e0:	6a450513          	addi	a0,a0,1700 # 80023980 <ftable>
    800042e4:	8adfc0ef          	jal	80000b90 <initlock>
}
    800042e8:	60a2                	ld	ra,8(sp)
    800042ea:	6402                	ld	s0,0(sp)
    800042ec:	0141                	addi	sp,sp,16
    800042ee:	8082                	ret

00000000800042f0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800042f0:	1101                	addi	sp,sp,-32
    800042f2:	ec06                	sd	ra,24(sp)
    800042f4:	e822                	sd	s0,16(sp)
    800042f6:	e426                	sd	s1,8(sp)
    800042f8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800042fa:	0001f517          	auipc	a0,0x1f
    800042fe:	68650513          	addi	a0,a0,1670 # 80023980 <ftable>
    80004302:	90ffc0ef          	jal	80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004306:	0001f497          	auipc	s1,0x1f
    8000430a:	69248493          	addi	s1,s1,1682 # 80023998 <ftable+0x18>
    8000430e:	00020717          	auipc	a4,0x20
    80004312:	62a70713          	addi	a4,a4,1578 # 80024938 <disk>
    if(f->ref == 0){
    80004316:	40dc                	lw	a5,4(s1)
    80004318:	cf89                	beqz	a5,80004332 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000431a:	02848493          	addi	s1,s1,40
    8000431e:	fee49ce3          	bne	s1,a4,80004316 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004322:	0001f517          	auipc	a0,0x1f
    80004326:	65e50513          	addi	a0,a0,1630 # 80023980 <ftable>
    8000432a:	97ffc0ef          	jal	80000ca8 <release>
  return 0;
    8000432e:	4481                	li	s1,0
    80004330:	a809                	j	80004342 <filealloc+0x52>
      f->ref = 1;
    80004332:	4785                	li	a5,1
    80004334:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004336:	0001f517          	auipc	a0,0x1f
    8000433a:	64a50513          	addi	a0,a0,1610 # 80023980 <ftable>
    8000433e:	96bfc0ef          	jal	80000ca8 <release>
}
    80004342:	8526                	mv	a0,s1
    80004344:	60e2                	ld	ra,24(sp)
    80004346:	6442                	ld	s0,16(sp)
    80004348:	64a2                	ld	s1,8(sp)
    8000434a:	6105                	addi	sp,sp,32
    8000434c:	8082                	ret

000000008000434e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000434e:	1101                	addi	sp,sp,-32
    80004350:	ec06                	sd	ra,24(sp)
    80004352:	e822                	sd	s0,16(sp)
    80004354:	e426                	sd	s1,8(sp)
    80004356:	1000                	addi	s0,sp,32
    80004358:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000435a:	0001f517          	auipc	a0,0x1f
    8000435e:	62650513          	addi	a0,a0,1574 # 80023980 <ftable>
    80004362:	8affc0ef          	jal	80000c10 <acquire>
  if(f->ref < 1)
    80004366:	40dc                	lw	a5,4(s1)
    80004368:	02f05063          	blez	a5,80004388 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    8000436c:	2785                	addiw	a5,a5,1
    8000436e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004370:	0001f517          	auipc	a0,0x1f
    80004374:	61050513          	addi	a0,a0,1552 # 80023980 <ftable>
    80004378:	931fc0ef          	jal	80000ca8 <release>
  return f;
}
    8000437c:	8526                	mv	a0,s1
    8000437e:	60e2                	ld	ra,24(sp)
    80004380:	6442                	ld	s0,16(sp)
    80004382:	64a2                	ld	s1,8(sp)
    80004384:	6105                	addi	sp,sp,32
    80004386:	8082                	ret
    panic("filedup");
    80004388:	00003517          	auipc	a0,0x3
    8000438c:	2e850513          	addi	a0,a0,744 # 80007670 <etext+0x670>
    80004390:	c50fc0ef          	jal	800007e0 <panic>

0000000080004394 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004394:	7139                	addi	sp,sp,-64
    80004396:	fc06                	sd	ra,56(sp)
    80004398:	f822                	sd	s0,48(sp)
    8000439a:	f426                	sd	s1,40(sp)
    8000439c:	0080                	addi	s0,sp,64
    8000439e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800043a0:	0001f517          	auipc	a0,0x1f
    800043a4:	5e050513          	addi	a0,a0,1504 # 80023980 <ftable>
    800043a8:	869fc0ef          	jal	80000c10 <acquire>
  if(f->ref < 1)
    800043ac:	40dc                	lw	a5,4(s1)
    800043ae:	04f05a63          	blez	a5,80004402 <fileclose+0x6e>
    panic("fileclose");
  if(--f->ref > 0){
    800043b2:	37fd                	addiw	a5,a5,-1
    800043b4:	0007871b          	sext.w	a4,a5
    800043b8:	c0dc                	sw	a5,4(s1)
    800043ba:	04e04e63          	bgtz	a4,80004416 <fileclose+0x82>
    800043be:	f04a                	sd	s2,32(sp)
    800043c0:	ec4e                	sd	s3,24(sp)
    800043c2:	e852                	sd	s4,16(sp)
    800043c4:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800043c6:	0004a903          	lw	s2,0(s1)
    800043ca:	0094ca83          	lbu	s5,9(s1)
    800043ce:	0104ba03          	ld	s4,16(s1)
    800043d2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800043d6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800043da:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800043de:	0001f517          	auipc	a0,0x1f
    800043e2:	5a250513          	addi	a0,a0,1442 # 80023980 <ftable>
    800043e6:	8c3fc0ef          	jal	80000ca8 <release>

  if(ff.type == FD_PIPE){
    800043ea:	4785                	li	a5,1
    800043ec:	04f90063          	beq	s2,a5,8000442c <fileclose+0x98>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800043f0:	3979                	addiw	s2,s2,-2
    800043f2:	4785                	li	a5,1
    800043f4:	0527f563          	bgeu	a5,s2,8000443e <fileclose+0xaa>
    800043f8:	7902                	ld	s2,32(sp)
    800043fa:	69e2                	ld	s3,24(sp)
    800043fc:	6a42                	ld	s4,16(sp)
    800043fe:	6aa2                	ld	s5,8(sp)
    80004400:	a00d                	j	80004422 <fileclose+0x8e>
    80004402:	f04a                	sd	s2,32(sp)
    80004404:	ec4e                	sd	s3,24(sp)
    80004406:	e852                	sd	s4,16(sp)
    80004408:	e456                	sd	s5,8(sp)
    panic("fileclose");
    8000440a:	00003517          	auipc	a0,0x3
    8000440e:	26e50513          	addi	a0,a0,622 # 80007678 <etext+0x678>
    80004412:	bcefc0ef          	jal	800007e0 <panic>
    release(&ftable.lock);
    80004416:	0001f517          	auipc	a0,0x1f
    8000441a:	56a50513          	addi	a0,a0,1386 # 80023980 <ftable>
    8000441e:	88bfc0ef          	jal	80000ca8 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    80004422:	70e2                	ld	ra,56(sp)
    80004424:	7442                	ld	s0,48(sp)
    80004426:	74a2                	ld	s1,40(sp)
    80004428:	6121                	addi	sp,sp,64
    8000442a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000442c:	85d6                	mv	a1,s5
    8000442e:	8552                	mv	a0,s4
    80004430:	336000ef          	jal	80004766 <pipeclose>
    80004434:	7902                	ld	s2,32(sp)
    80004436:	69e2                	ld	s3,24(sp)
    80004438:	6a42                	ld	s4,16(sp)
    8000443a:	6aa2                	ld	s5,8(sp)
    8000443c:	b7dd                	j	80004422 <fileclose+0x8e>
    begin_op();
    8000443e:	b4bff0ef          	jal	80003f88 <begin_op>
    iput(ff.ip);
    80004442:	854e                	mv	a0,s3
    80004444:	adcff0ef          	jal	80003720 <iput>
    end_op();
    80004448:	babff0ef          	jal	80003ff2 <end_op>
    8000444c:	7902                	ld	s2,32(sp)
    8000444e:	69e2                	ld	s3,24(sp)
    80004450:	6a42                	ld	s4,16(sp)
    80004452:	6aa2                	ld	s5,8(sp)
    80004454:	b7f9                	j	80004422 <fileclose+0x8e>

0000000080004456 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004456:	715d                	addi	sp,sp,-80
    80004458:	e486                	sd	ra,72(sp)
    8000445a:	e0a2                	sd	s0,64(sp)
    8000445c:	fc26                	sd	s1,56(sp)
    8000445e:	f44e                	sd	s3,40(sp)
    80004460:	0880                	addi	s0,sp,80
    80004462:	84aa                	mv	s1,a0
    80004464:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004466:	caafd0ef          	jal	80001910 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000446a:	409c                	lw	a5,0(s1)
    8000446c:	37f9                	addiw	a5,a5,-2
    8000446e:	4705                	li	a4,1
    80004470:	04f76063          	bltu	a4,a5,800044b0 <filestat+0x5a>
    80004474:	f84a                	sd	s2,48(sp)
    80004476:	892a                	mv	s2,a0
    ilock(f->ip);
    80004478:	6c88                	ld	a0,24(s1)
    8000447a:	924ff0ef          	jal	8000359e <ilock>
    stati(f->ip, &st);
    8000447e:	fb840593          	addi	a1,s0,-72
    80004482:	6c88                	ld	a0,24(s1)
    80004484:	c80ff0ef          	jal	80003904 <stati>
    iunlock(f->ip);
    80004488:	6c88                	ld	a0,24(s1)
    8000448a:	9c2ff0ef          	jal	8000364c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000448e:	46e1                	li	a3,24
    80004490:	fb840613          	addi	a2,s0,-72
    80004494:	85ce                	mv	a1,s3
    80004496:	05093503          	ld	a0,80(s2)
    8000449a:	98afd0ef          	jal	80001624 <copyout>
    8000449e:	41f5551b          	sraiw	a0,a0,0x1f
    800044a2:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    800044a4:	60a6                	ld	ra,72(sp)
    800044a6:	6406                	ld	s0,64(sp)
    800044a8:	74e2                	ld	s1,56(sp)
    800044aa:	79a2                	ld	s3,40(sp)
    800044ac:	6161                	addi	sp,sp,80
    800044ae:	8082                	ret
  return -1;
    800044b0:	557d                	li	a0,-1
    800044b2:	bfcd                	j	800044a4 <filestat+0x4e>

00000000800044b4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800044b4:	7179                	addi	sp,sp,-48
    800044b6:	f406                	sd	ra,40(sp)
    800044b8:	f022                	sd	s0,32(sp)
    800044ba:	e84a                	sd	s2,16(sp)
    800044bc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800044be:	00854783          	lbu	a5,8(a0)
    800044c2:	cfd1                	beqz	a5,8000455e <fileread+0xaa>
    800044c4:	ec26                	sd	s1,24(sp)
    800044c6:	e44e                	sd	s3,8(sp)
    800044c8:	84aa                	mv	s1,a0
    800044ca:	89ae                	mv	s3,a1
    800044cc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800044ce:	411c                	lw	a5,0(a0)
    800044d0:	4705                	li	a4,1
    800044d2:	04e78363          	beq	a5,a4,80004518 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800044d6:	470d                	li	a4,3
    800044d8:	04e78763          	beq	a5,a4,80004526 <fileread+0x72>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800044dc:	4709                	li	a4,2
    800044de:	06e79a63          	bne	a5,a4,80004552 <fileread+0x9e>
    ilock(f->ip);
    800044e2:	6d08                	ld	a0,24(a0)
    800044e4:	8baff0ef          	jal	8000359e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800044e8:	874a                	mv	a4,s2
    800044ea:	5094                	lw	a3,32(s1)
    800044ec:	864e                	mv	a2,s3
    800044ee:	4585                	li	a1,1
    800044f0:	6c88                	ld	a0,24(s1)
    800044f2:	c3cff0ef          	jal	8000392e <readi>
    800044f6:	892a                	mv	s2,a0
    800044f8:	00a05563          	blez	a0,80004502 <fileread+0x4e>
      f->off += r;
    800044fc:	509c                	lw	a5,32(s1)
    800044fe:	9fa9                	addw	a5,a5,a0
    80004500:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004502:	6c88                	ld	a0,24(s1)
    80004504:	948ff0ef          	jal	8000364c <iunlock>
    80004508:	64e2                	ld	s1,24(sp)
    8000450a:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    8000450c:	854a                	mv	a0,s2
    8000450e:	70a2                	ld	ra,40(sp)
    80004510:	7402                	ld	s0,32(sp)
    80004512:	6942                	ld	s2,16(sp)
    80004514:	6145                	addi	sp,sp,48
    80004516:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004518:	6908                	ld	a0,16(a0)
    8000451a:	388000ef          	jal	800048a2 <piperead>
    8000451e:	892a                	mv	s2,a0
    80004520:	64e2                	ld	s1,24(sp)
    80004522:	69a2                	ld	s3,8(sp)
    80004524:	b7e5                	j	8000450c <fileread+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004526:	02451783          	lh	a5,36(a0)
    8000452a:	03079693          	slli	a3,a5,0x30
    8000452e:	92c1                	srli	a3,a3,0x30
    80004530:	4725                	li	a4,9
    80004532:	02d76863          	bltu	a4,a3,80004562 <fileread+0xae>
    80004536:	0792                	slli	a5,a5,0x4
    80004538:	0001f717          	auipc	a4,0x1f
    8000453c:	3a870713          	addi	a4,a4,936 # 800238e0 <devsw>
    80004540:	97ba                	add	a5,a5,a4
    80004542:	639c                	ld	a5,0(a5)
    80004544:	c39d                	beqz	a5,8000456a <fileread+0xb6>
    r = devsw[f->major].read(1, addr, n);
    80004546:	4505                	li	a0,1
    80004548:	9782                	jalr	a5
    8000454a:	892a                	mv	s2,a0
    8000454c:	64e2                	ld	s1,24(sp)
    8000454e:	69a2                	ld	s3,8(sp)
    80004550:	bf75                	j	8000450c <fileread+0x58>
    panic("fileread");
    80004552:	00003517          	auipc	a0,0x3
    80004556:	13650513          	addi	a0,a0,310 # 80007688 <etext+0x688>
    8000455a:	a86fc0ef          	jal	800007e0 <panic>
    return -1;
    8000455e:	597d                	li	s2,-1
    80004560:	b775                	j	8000450c <fileread+0x58>
      return -1;
    80004562:	597d                	li	s2,-1
    80004564:	64e2                	ld	s1,24(sp)
    80004566:	69a2                	ld	s3,8(sp)
    80004568:	b755                	j	8000450c <fileread+0x58>
    8000456a:	597d                	li	s2,-1
    8000456c:	64e2                	ld	s1,24(sp)
    8000456e:	69a2                	ld	s3,8(sp)
    80004570:	bf71                	j	8000450c <fileread+0x58>

0000000080004572 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004572:	00954783          	lbu	a5,9(a0)
    80004576:	10078b63          	beqz	a5,8000468c <filewrite+0x11a>
{
    8000457a:	715d                	addi	sp,sp,-80
    8000457c:	e486                	sd	ra,72(sp)
    8000457e:	e0a2                	sd	s0,64(sp)
    80004580:	f84a                	sd	s2,48(sp)
    80004582:	f052                	sd	s4,32(sp)
    80004584:	e85a                	sd	s6,16(sp)
    80004586:	0880                	addi	s0,sp,80
    80004588:	892a                	mv	s2,a0
    8000458a:	8b2e                	mv	s6,a1
    8000458c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000458e:	411c                	lw	a5,0(a0)
    80004590:	4705                	li	a4,1
    80004592:	02e78763          	beq	a5,a4,800045c0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004596:	470d                	li	a4,3
    80004598:	02e78863          	beq	a5,a4,800045c8 <filewrite+0x56>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000459c:	4709                	li	a4,2
    8000459e:	0ce79c63          	bne	a5,a4,80004676 <filewrite+0x104>
    800045a2:	f44e                	sd	s3,40(sp)
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800045a4:	0ac05863          	blez	a2,80004654 <filewrite+0xe2>
    800045a8:	fc26                	sd	s1,56(sp)
    800045aa:	ec56                	sd	s5,24(sp)
    800045ac:	e45e                	sd	s7,8(sp)
    800045ae:	e062                	sd	s8,0(sp)
    int i = 0;
    800045b0:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800045b2:	6b85                	lui	s7,0x1
    800045b4:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800045b8:	6c05                	lui	s8,0x1
    800045ba:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800045be:	a8b5                	j	8000463a <filewrite+0xc8>
    ret = pipewrite(f->pipe, addr, n);
    800045c0:	6908                	ld	a0,16(a0)
    800045c2:	1fc000ef          	jal	800047be <pipewrite>
    800045c6:	a04d                	j	80004668 <filewrite+0xf6>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800045c8:	02451783          	lh	a5,36(a0)
    800045cc:	03079693          	slli	a3,a5,0x30
    800045d0:	92c1                	srli	a3,a3,0x30
    800045d2:	4725                	li	a4,9
    800045d4:	0ad76e63          	bltu	a4,a3,80004690 <filewrite+0x11e>
    800045d8:	0792                	slli	a5,a5,0x4
    800045da:	0001f717          	auipc	a4,0x1f
    800045de:	30670713          	addi	a4,a4,774 # 800238e0 <devsw>
    800045e2:	97ba                	add	a5,a5,a4
    800045e4:	679c                	ld	a5,8(a5)
    800045e6:	c7dd                	beqz	a5,80004694 <filewrite+0x122>
    ret = devsw[f->major].write(1, addr, n);
    800045e8:	4505                	li	a0,1
    800045ea:	9782                	jalr	a5
    800045ec:	a8b5                	j	80004668 <filewrite+0xf6>
      if(n1 > max)
    800045ee:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800045f2:	997ff0ef          	jal	80003f88 <begin_op>
      ilock(f->ip);
    800045f6:	01893503          	ld	a0,24(s2)
    800045fa:	fa5fe0ef          	jal	8000359e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800045fe:	8756                	mv	a4,s5
    80004600:	02092683          	lw	a3,32(s2)
    80004604:	01698633          	add	a2,s3,s6
    80004608:	4585                	li	a1,1
    8000460a:	01893503          	ld	a0,24(s2)
    8000460e:	c1cff0ef          	jal	80003a2a <writei>
    80004612:	84aa                	mv	s1,a0
    80004614:	00a05763          	blez	a0,80004622 <filewrite+0xb0>
        f->off += r;
    80004618:	02092783          	lw	a5,32(s2)
    8000461c:	9fa9                	addw	a5,a5,a0
    8000461e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004622:	01893503          	ld	a0,24(s2)
    80004626:	826ff0ef          	jal	8000364c <iunlock>
      end_op();
    8000462a:	9c9ff0ef          	jal	80003ff2 <end_op>

      if(r != n1){
    8000462e:	029a9563          	bne	s5,s1,80004658 <filewrite+0xe6>
        // error from writei
        break;
      }
      i += r;
    80004632:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004636:	0149da63          	bge	s3,s4,8000464a <filewrite+0xd8>
      int n1 = n - i;
    8000463a:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000463e:	0004879b          	sext.w	a5,s1
    80004642:	fafbd6e3          	bge	s7,a5,800045ee <filewrite+0x7c>
    80004646:	84e2                	mv	s1,s8
    80004648:	b75d                	j	800045ee <filewrite+0x7c>
    8000464a:	74e2                	ld	s1,56(sp)
    8000464c:	6ae2                	ld	s5,24(sp)
    8000464e:	6ba2                	ld	s7,8(sp)
    80004650:	6c02                	ld	s8,0(sp)
    80004652:	a039                	j	80004660 <filewrite+0xee>
    int i = 0;
    80004654:	4981                	li	s3,0
    80004656:	a029                	j	80004660 <filewrite+0xee>
    80004658:	74e2                	ld	s1,56(sp)
    8000465a:	6ae2                	ld	s5,24(sp)
    8000465c:	6ba2                	ld	s7,8(sp)
    8000465e:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    80004660:	033a1c63          	bne	s4,s3,80004698 <filewrite+0x126>
    80004664:	8552                	mv	a0,s4
    80004666:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004668:	60a6                	ld	ra,72(sp)
    8000466a:	6406                	ld	s0,64(sp)
    8000466c:	7942                	ld	s2,48(sp)
    8000466e:	7a02                	ld	s4,32(sp)
    80004670:	6b42                	ld	s6,16(sp)
    80004672:	6161                	addi	sp,sp,80
    80004674:	8082                	ret
    80004676:	fc26                	sd	s1,56(sp)
    80004678:	f44e                	sd	s3,40(sp)
    8000467a:	ec56                	sd	s5,24(sp)
    8000467c:	e45e                	sd	s7,8(sp)
    8000467e:	e062                	sd	s8,0(sp)
    panic("filewrite");
    80004680:	00003517          	auipc	a0,0x3
    80004684:	01850513          	addi	a0,a0,24 # 80007698 <etext+0x698>
    80004688:	958fc0ef          	jal	800007e0 <panic>
    return -1;
    8000468c:	557d                	li	a0,-1
}
    8000468e:	8082                	ret
      return -1;
    80004690:	557d                	li	a0,-1
    80004692:	bfd9                	j	80004668 <filewrite+0xf6>
    80004694:	557d                	li	a0,-1
    80004696:	bfc9                	j	80004668 <filewrite+0xf6>
    ret = (i == n ? n : -1);
    80004698:	557d                	li	a0,-1
    8000469a:	79a2                	ld	s3,40(sp)
    8000469c:	b7f1                	j	80004668 <filewrite+0xf6>

000000008000469e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000469e:	7179                	addi	sp,sp,-48
    800046a0:	f406                	sd	ra,40(sp)
    800046a2:	f022                	sd	s0,32(sp)
    800046a4:	ec26                	sd	s1,24(sp)
    800046a6:	e052                	sd	s4,0(sp)
    800046a8:	1800                	addi	s0,sp,48
    800046aa:	84aa                	mv	s1,a0
    800046ac:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800046ae:	0005b023          	sd	zero,0(a1)
    800046b2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800046b6:	c3bff0ef          	jal	800042f0 <filealloc>
    800046ba:	e088                	sd	a0,0(s1)
    800046bc:	c549                	beqz	a0,80004746 <pipealloc+0xa8>
    800046be:	c33ff0ef          	jal	800042f0 <filealloc>
    800046c2:	00aa3023          	sd	a0,0(s4)
    800046c6:	cd25                	beqz	a0,8000473e <pipealloc+0xa0>
    800046c8:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800046ca:	c34fc0ef          	jal	80000afe <kalloc>
    800046ce:	892a                	mv	s2,a0
    800046d0:	c12d                	beqz	a0,80004732 <pipealloc+0x94>
    800046d2:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    800046d4:	4985                	li	s3,1
    800046d6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800046da:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800046de:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800046e2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800046e6:	00003597          	auipc	a1,0x3
    800046ea:	cfa58593          	addi	a1,a1,-774 # 800073e0 <etext+0x3e0>
    800046ee:	ca2fc0ef          	jal	80000b90 <initlock>
  (*f0)->type = FD_PIPE;
    800046f2:	609c                	ld	a5,0(s1)
    800046f4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800046f8:	609c                	ld	a5,0(s1)
    800046fa:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800046fe:	609c                	ld	a5,0(s1)
    80004700:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004704:	609c                	ld	a5,0(s1)
    80004706:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000470a:	000a3783          	ld	a5,0(s4)
    8000470e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004712:	000a3783          	ld	a5,0(s4)
    80004716:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000471a:	000a3783          	ld	a5,0(s4)
    8000471e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004722:	000a3783          	ld	a5,0(s4)
    80004726:	0127b823          	sd	s2,16(a5)
  return 0;
    8000472a:	4501                	li	a0,0
    8000472c:	6942                	ld	s2,16(sp)
    8000472e:	69a2                	ld	s3,8(sp)
    80004730:	a01d                	j	80004756 <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004732:	6088                	ld	a0,0(s1)
    80004734:	c119                	beqz	a0,8000473a <pipealloc+0x9c>
    80004736:	6942                	ld	s2,16(sp)
    80004738:	a029                	j	80004742 <pipealloc+0xa4>
    8000473a:	6942                	ld	s2,16(sp)
    8000473c:	a029                	j	80004746 <pipealloc+0xa8>
    8000473e:	6088                	ld	a0,0(s1)
    80004740:	c10d                	beqz	a0,80004762 <pipealloc+0xc4>
    fileclose(*f0);
    80004742:	c53ff0ef          	jal	80004394 <fileclose>
  if(*f1)
    80004746:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000474a:	557d                	li	a0,-1
  if(*f1)
    8000474c:	c789                	beqz	a5,80004756 <pipealloc+0xb8>
    fileclose(*f1);
    8000474e:	853e                	mv	a0,a5
    80004750:	c45ff0ef          	jal	80004394 <fileclose>
  return -1;
    80004754:	557d                	li	a0,-1
}
    80004756:	70a2                	ld	ra,40(sp)
    80004758:	7402                	ld	s0,32(sp)
    8000475a:	64e2                	ld	s1,24(sp)
    8000475c:	6a02                	ld	s4,0(sp)
    8000475e:	6145                	addi	sp,sp,48
    80004760:	8082                	ret
  return -1;
    80004762:	557d                	li	a0,-1
    80004764:	bfcd                	j	80004756 <pipealloc+0xb8>

0000000080004766 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004766:	1101                	addi	sp,sp,-32
    80004768:	ec06                	sd	ra,24(sp)
    8000476a:	e822                	sd	s0,16(sp)
    8000476c:	e426                	sd	s1,8(sp)
    8000476e:	e04a                	sd	s2,0(sp)
    80004770:	1000                	addi	s0,sp,32
    80004772:	84aa                	mv	s1,a0
    80004774:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004776:	c9afc0ef          	jal	80000c10 <acquire>
  if(writable){
    8000477a:	02090763          	beqz	s2,800047a8 <pipeclose+0x42>
    pi->writeopen = 0;
    8000477e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004782:	21848513          	addi	a0,s1,536
    80004786:	861fd0ef          	jal	80001fe6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000478a:	2204b783          	ld	a5,544(s1)
    8000478e:	e785                	bnez	a5,800047b6 <pipeclose+0x50>
    release(&pi->lock);
    80004790:	8526                	mv	a0,s1
    80004792:	d16fc0ef          	jal	80000ca8 <release>
    kfree((char*)pi);
    80004796:	8526                	mv	a0,s1
    80004798:	a84fc0ef          	jal	80000a1c <kfree>
  } else
    release(&pi->lock);
}
    8000479c:	60e2                	ld	ra,24(sp)
    8000479e:	6442                	ld	s0,16(sp)
    800047a0:	64a2                	ld	s1,8(sp)
    800047a2:	6902                	ld	s2,0(sp)
    800047a4:	6105                	addi	sp,sp,32
    800047a6:	8082                	ret
    pi->readopen = 0;
    800047a8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800047ac:	21c48513          	addi	a0,s1,540
    800047b0:	837fd0ef          	jal	80001fe6 <wakeup>
    800047b4:	bfd9                	j	8000478a <pipeclose+0x24>
    release(&pi->lock);
    800047b6:	8526                	mv	a0,s1
    800047b8:	cf0fc0ef          	jal	80000ca8 <release>
}
    800047bc:	b7c5                	j	8000479c <pipeclose+0x36>

00000000800047be <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800047be:	711d                	addi	sp,sp,-96
    800047c0:	ec86                	sd	ra,88(sp)
    800047c2:	e8a2                	sd	s0,80(sp)
    800047c4:	e4a6                	sd	s1,72(sp)
    800047c6:	e0ca                	sd	s2,64(sp)
    800047c8:	fc4e                	sd	s3,56(sp)
    800047ca:	f852                	sd	s4,48(sp)
    800047cc:	f456                	sd	s5,40(sp)
    800047ce:	1080                	addi	s0,sp,96
    800047d0:	84aa                	mv	s1,a0
    800047d2:	8aae                	mv	s5,a1
    800047d4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800047d6:	93afd0ef          	jal	80001910 <myproc>
    800047da:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800047dc:	8526                	mv	a0,s1
    800047de:	c32fc0ef          	jal	80000c10 <acquire>
  while(i < n){
    800047e2:	0b405a63          	blez	s4,80004896 <pipewrite+0xd8>
    800047e6:	f05a                	sd	s6,32(sp)
    800047e8:	ec5e                	sd	s7,24(sp)
    800047ea:	e862                	sd	s8,16(sp)
  int i = 0;
    800047ec:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800047ee:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800047f0:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800047f4:	21c48b93          	addi	s7,s1,540
    800047f8:	a81d                	j	8000482e <pipewrite+0x70>
      release(&pi->lock);
    800047fa:	8526                	mv	a0,s1
    800047fc:	cacfc0ef          	jal	80000ca8 <release>
      return -1;
    80004800:	597d                	li	s2,-1
    80004802:	7b02                	ld	s6,32(sp)
    80004804:	6be2                	ld	s7,24(sp)
    80004806:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004808:	854a                	mv	a0,s2
    8000480a:	60e6                	ld	ra,88(sp)
    8000480c:	6446                	ld	s0,80(sp)
    8000480e:	64a6                	ld	s1,72(sp)
    80004810:	6906                	ld	s2,64(sp)
    80004812:	79e2                	ld	s3,56(sp)
    80004814:	7a42                	ld	s4,48(sp)
    80004816:	7aa2                	ld	s5,40(sp)
    80004818:	6125                	addi	sp,sp,96
    8000481a:	8082                	ret
      wakeup(&pi->nread);
    8000481c:	8562                	mv	a0,s8
    8000481e:	fc8fd0ef          	jal	80001fe6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004822:	85a6                	mv	a1,s1
    80004824:	855e                	mv	a0,s7
    80004826:	f74fd0ef          	jal	80001f9a <sleep>
  while(i < n){
    8000482a:	05495b63          	bge	s2,s4,80004880 <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    8000482e:	2204a783          	lw	a5,544(s1)
    80004832:	d7e1                	beqz	a5,800047fa <pipewrite+0x3c>
    80004834:	854e                	mv	a0,s3
    80004836:	99dfd0ef          	jal	800021d2 <killed>
    8000483a:	f161                	bnez	a0,800047fa <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000483c:	2184a783          	lw	a5,536(s1)
    80004840:	21c4a703          	lw	a4,540(s1)
    80004844:	2007879b          	addiw	a5,a5,512
    80004848:	fcf70ae3          	beq	a4,a5,8000481c <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000484c:	4685                	li	a3,1
    8000484e:	01590633          	add	a2,s2,s5
    80004852:	faf40593          	addi	a1,s0,-81
    80004856:	0509b503          	ld	a0,80(s3)
    8000485a:	eaffc0ef          	jal	80001708 <copyin>
    8000485e:	03650e63          	beq	a0,s6,8000489a <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004862:	21c4a783          	lw	a5,540(s1)
    80004866:	0017871b          	addiw	a4,a5,1
    8000486a:	20e4ae23          	sw	a4,540(s1)
    8000486e:	1ff7f793          	andi	a5,a5,511
    80004872:	97a6                	add	a5,a5,s1
    80004874:	faf44703          	lbu	a4,-81(s0)
    80004878:	00e78c23          	sb	a4,24(a5)
      i++;
    8000487c:	2905                	addiw	s2,s2,1
    8000487e:	b775                	j	8000482a <pipewrite+0x6c>
    80004880:	7b02                	ld	s6,32(sp)
    80004882:	6be2                	ld	s7,24(sp)
    80004884:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    80004886:	21848513          	addi	a0,s1,536
    8000488a:	f5cfd0ef          	jal	80001fe6 <wakeup>
  release(&pi->lock);
    8000488e:	8526                	mv	a0,s1
    80004890:	c18fc0ef          	jal	80000ca8 <release>
  return i;
    80004894:	bf95                	j	80004808 <pipewrite+0x4a>
  int i = 0;
    80004896:	4901                	li	s2,0
    80004898:	b7fd                	j	80004886 <pipewrite+0xc8>
    8000489a:	7b02                	ld	s6,32(sp)
    8000489c:	6be2                	ld	s7,24(sp)
    8000489e:	6c42                	ld	s8,16(sp)
    800048a0:	b7dd                	j	80004886 <pipewrite+0xc8>

00000000800048a2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800048a2:	715d                	addi	sp,sp,-80
    800048a4:	e486                	sd	ra,72(sp)
    800048a6:	e0a2                	sd	s0,64(sp)
    800048a8:	fc26                	sd	s1,56(sp)
    800048aa:	f84a                	sd	s2,48(sp)
    800048ac:	f44e                	sd	s3,40(sp)
    800048ae:	f052                	sd	s4,32(sp)
    800048b0:	ec56                	sd	s5,24(sp)
    800048b2:	0880                	addi	s0,sp,80
    800048b4:	84aa                	mv	s1,a0
    800048b6:	892e                	mv	s2,a1
    800048b8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800048ba:	856fd0ef          	jal	80001910 <myproc>
    800048be:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800048c0:	8526                	mv	a0,s1
    800048c2:	b4efc0ef          	jal	80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800048c6:	2184a703          	lw	a4,536(s1)
    800048ca:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800048ce:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800048d2:	02f71563          	bne	a4,a5,800048fc <piperead+0x5a>
    800048d6:	2244a783          	lw	a5,548(s1)
    800048da:	cb85                	beqz	a5,8000490a <piperead+0x68>
    if(killed(pr)){
    800048dc:	8552                	mv	a0,s4
    800048de:	8f5fd0ef          	jal	800021d2 <killed>
    800048e2:	ed19                	bnez	a0,80004900 <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800048e4:	85a6                	mv	a1,s1
    800048e6:	854e                	mv	a0,s3
    800048e8:	eb2fd0ef          	jal	80001f9a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800048ec:	2184a703          	lw	a4,536(s1)
    800048f0:	21c4a783          	lw	a5,540(s1)
    800048f4:	fef701e3          	beq	a4,a5,800048d6 <piperead+0x34>
    800048f8:	e85a                	sd	s6,16(sp)
    800048fa:	a809                	j	8000490c <piperead+0x6a>
    800048fc:	e85a                	sd	s6,16(sp)
    800048fe:	a039                	j	8000490c <piperead+0x6a>
      release(&pi->lock);
    80004900:	8526                	mv	a0,s1
    80004902:	ba6fc0ef          	jal	80000ca8 <release>
      return -1;
    80004906:	59fd                	li	s3,-1
    80004908:	a8b9                	j	80004966 <piperead+0xc4>
    8000490a:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000490c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    8000490e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004910:	05505363          	blez	s5,80004956 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004914:	2184a783          	lw	a5,536(s1)
    80004918:	21c4a703          	lw	a4,540(s1)
    8000491c:	02f70d63          	beq	a4,a5,80004956 <piperead+0xb4>
    ch = pi->data[pi->nread % PIPESIZE];
    80004920:	1ff7f793          	andi	a5,a5,511
    80004924:	97a6                	add	a5,a5,s1
    80004926:	0187c783          	lbu	a5,24(a5)
    8000492a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    8000492e:	4685                	li	a3,1
    80004930:	fbf40613          	addi	a2,s0,-65
    80004934:	85ca                	mv	a1,s2
    80004936:	050a3503          	ld	a0,80(s4)
    8000493a:	cebfc0ef          	jal	80001624 <copyout>
    8000493e:	03650e63          	beq	a0,s6,8000497a <piperead+0xd8>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    80004942:	2184a783          	lw	a5,536(s1)
    80004946:	2785                	addiw	a5,a5,1
    80004948:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000494c:	2985                	addiw	s3,s3,1
    8000494e:	0905                	addi	s2,s2,1
    80004950:	fd3a92e3          	bne	s5,s3,80004914 <piperead+0x72>
    80004954:	89d6                	mv	s3,s5
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004956:	21c48513          	addi	a0,s1,540
    8000495a:	e8cfd0ef          	jal	80001fe6 <wakeup>
  release(&pi->lock);
    8000495e:	8526                	mv	a0,s1
    80004960:	b48fc0ef          	jal	80000ca8 <release>
    80004964:	6b42                	ld	s6,16(sp)
  return i;
}
    80004966:	854e                	mv	a0,s3
    80004968:	60a6                	ld	ra,72(sp)
    8000496a:	6406                	ld	s0,64(sp)
    8000496c:	74e2                	ld	s1,56(sp)
    8000496e:	7942                	ld	s2,48(sp)
    80004970:	79a2                	ld	s3,40(sp)
    80004972:	7a02                	ld	s4,32(sp)
    80004974:	6ae2                	ld	s5,24(sp)
    80004976:	6161                	addi	sp,sp,80
    80004978:	8082                	ret
      if(i == 0)
    8000497a:	fc099ee3          	bnez	s3,80004956 <piperead+0xb4>
        i = -1;
    8000497e:	89aa                	mv	s3,a0
    80004980:	bfd9                	j	80004956 <piperead+0xb4>

0000000080004982 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80004982:	1141                	addi	sp,sp,-16
    80004984:	e422                	sd	s0,8(sp)
    80004986:	0800                	addi	s0,sp,16
    80004988:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000498a:	8905                	andi	a0,a0,1
    8000498c:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000498e:	8b89                	andi	a5,a5,2
    80004990:	c399                	beqz	a5,80004996 <flags2perm+0x14>
      perm |= PTE_W;
    80004992:	00456513          	ori	a0,a0,4
    return perm;
}
    80004996:	6422                	ld	s0,8(sp)
    80004998:	0141                	addi	sp,sp,16
    8000499a:	8082                	ret

000000008000499c <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    8000499c:	df010113          	addi	sp,sp,-528
    800049a0:	20113423          	sd	ra,520(sp)
    800049a4:	20813023          	sd	s0,512(sp)
    800049a8:	ffa6                	sd	s1,504(sp)
    800049aa:	fbca                	sd	s2,496(sp)
    800049ac:	0c00                	addi	s0,sp,528
    800049ae:	892a                	mv	s2,a0
    800049b0:	dea43c23          	sd	a0,-520(s0)
    800049b4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800049b8:	f59fc0ef          	jal	80001910 <myproc>
    800049bc:	84aa                	mv	s1,a0

  begin_op();
    800049be:	dcaff0ef          	jal	80003f88 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    800049c2:	854a                	mv	a0,s2
    800049c4:	bf0ff0ef          	jal	80003db4 <namei>
    800049c8:	c931                	beqz	a0,80004a1c <kexec+0x80>
    800049ca:	f3d2                	sd	s4,480(sp)
    800049cc:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800049ce:	bd1fe0ef          	jal	8000359e <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800049d2:	04000713          	li	a4,64
    800049d6:	4681                	li	a3,0
    800049d8:	e5040613          	addi	a2,s0,-432
    800049dc:	4581                	li	a1,0
    800049de:	8552                	mv	a0,s4
    800049e0:	f4ffe0ef          	jal	8000392e <readi>
    800049e4:	04000793          	li	a5,64
    800049e8:	00f51a63          	bne	a0,a5,800049fc <kexec+0x60>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    800049ec:	e5042703          	lw	a4,-432(s0)
    800049f0:	464c47b7          	lui	a5,0x464c4
    800049f4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800049f8:	02f70663          	beq	a4,a5,80004a24 <kexec+0x88>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800049fc:	8552                	mv	a0,s4
    800049fe:	dabfe0ef          	jal	800037a8 <iunlockput>
    end_op();
    80004a02:	df0ff0ef          	jal	80003ff2 <end_op>
  }
  return -1;
    80004a06:	557d                	li	a0,-1
    80004a08:	7a1e                	ld	s4,480(sp)
}
    80004a0a:	20813083          	ld	ra,520(sp)
    80004a0e:	20013403          	ld	s0,512(sp)
    80004a12:	74fe                	ld	s1,504(sp)
    80004a14:	795e                	ld	s2,496(sp)
    80004a16:	21010113          	addi	sp,sp,528
    80004a1a:	8082                	ret
    end_op();
    80004a1c:	dd6ff0ef          	jal	80003ff2 <end_op>
    return -1;
    80004a20:	557d                	li	a0,-1
    80004a22:	b7e5                	j	80004a0a <kexec+0x6e>
    80004a24:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    80004a26:	8526                	mv	a0,s1
    80004a28:	feffc0ef          	jal	80001a16 <proc_pagetable>
    80004a2c:	8b2a                	mv	s6,a0
    80004a2e:	2c050b63          	beqz	a0,80004d04 <kexec+0x368>
    80004a32:	f7ce                	sd	s3,488(sp)
    80004a34:	efd6                	sd	s5,472(sp)
    80004a36:	e7de                	sd	s7,456(sp)
    80004a38:	e3e2                	sd	s8,448(sp)
    80004a3a:	ff66                	sd	s9,440(sp)
    80004a3c:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004a3e:	e7042d03          	lw	s10,-400(s0)
    80004a42:	e8845783          	lhu	a5,-376(s0)
    80004a46:	12078963          	beqz	a5,80004b78 <kexec+0x1dc>
    80004a4a:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004a4c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004a4e:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004a50:	6c85                	lui	s9,0x1
    80004a52:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004a56:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004a5a:	6a85                	lui	s5,0x1
    80004a5c:	a085                	j	80004abc <kexec+0x120>
      panic("loadseg: address should exist");
    80004a5e:	00003517          	auipc	a0,0x3
    80004a62:	c4a50513          	addi	a0,a0,-950 # 800076a8 <etext+0x6a8>
    80004a66:	d7bfb0ef          	jal	800007e0 <panic>
    if(sz - i < PGSIZE)
    80004a6a:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004a6c:	8726                	mv	a4,s1
    80004a6e:	012c06bb          	addw	a3,s8,s2
    80004a72:	4581                	li	a1,0
    80004a74:	8552                	mv	a0,s4
    80004a76:	eb9fe0ef          	jal	8000392e <readi>
    80004a7a:	2501                	sext.w	a0,a0
    80004a7c:	24a49a63          	bne	s1,a0,80004cd0 <kexec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    80004a80:	012a893b          	addw	s2,s5,s2
    80004a84:	03397363          	bgeu	s2,s3,80004aaa <kexec+0x10e>
    pa = walkaddr(pagetable, va + i);
    80004a88:	02091593          	slli	a1,s2,0x20
    80004a8c:	9181                	srli	a1,a1,0x20
    80004a8e:	95de                	add	a1,a1,s7
    80004a90:	855a                	mv	a0,s6
    80004a92:	d60fc0ef          	jal	80000ff2 <walkaddr>
    80004a96:	862a                	mv	a2,a0
    if(pa == 0)
    80004a98:	d179                	beqz	a0,80004a5e <kexec+0xc2>
    if(sz - i < PGSIZE)
    80004a9a:	412984bb          	subw	s1,s3,s2
    80004a9e:	0004879b          	sext.w	a5,s1
    80004aa2:	fcfcf4e3          	bgeu	s9,a5,80004a6a <kexec+0xce>
    80004aa6:	84d6                	mv	s1,s5
    80004aa8:	b7c9                	j	80004a6a <kexec+0xce>
    sz = sz1;
    80004aaa:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004aae:	2d85                	addiw	s11,s11,1
    80004ab0:	038d0d1b          	addiw	s10,s10,56 # 1038 <_entry-0x7fffefc8>
    80004ab4:	e8845783          	lhu	a5,-376(s0)
    80004ab8:	08fdd063          	bge	s11,a5,80004b38 <kexec+0x19c>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004abc:	2d01                	sext.w	s10,s10
    80004abe:	03800713          	li	a4,56
    80004ac2:	86ea                	mv	a3,s10
    80004ac4:	e1840613          	addi	a2,s0,-488
    80004ac8:	4581                	li	a1,0
    80004aca:	8552                	mv	a0,s4
    80004acc:	e63fe0ef          	jal	8000392e <readi>
    80004ad0:	03800793          	li	a5,56
    80004ad4:	1cf51663          	bne	a0,a5,80004ca0 <kexec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    80004ad8:	e1842783          	lw	a5,-488(s0)
    80004adc:	4705                	li	a4,1
    80004ade:	fce798e3          	bne	a5,a4,80004aae <kexec+0x112>
    if(ph.memsz < ph.filesz)
    80004ae2:	e4043483          	ld	s1,-448(s0)
    80004ae6:	e3843783          	ld	a5,-456(s0)
    80004aea:	1af4ef63          	bltu	s1,a5,80004ca8 <kexec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004aee:	e2843783          	ld	a5,-472(s0)
    80004af2:	94be                	add	s1,s1,a5
    80004af4:	1af4ee63          	bltu	s1,a5,80004cb0 <kexec+0x314>
    if(ph.vaddr % PGSIZE != 0)
    80004af8:	df043703          	ld	a4,-528(s0)
    80004afc:	8ff9                	and	a5,a5,a4
    80004afe:	1a079d63          	bnez	a5,80004cb8 <kexec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004b02:	e1c42503          	lw	a0,-484(s0)
    80004b06:	e7dff0ef          	jal	80004982 <flags2perm>
    80004b0a:	86aa                	mv	a3,a0
    80004b0c:	8626                	mv	a2,s1
    80004b0e:	85ca                	mv	a1,s2
    80004b10:	855a                	mv	a0,s6
    80004b12:	fb8fc0ef          	jal	800012ca <uvmalloc>
    80004b16:	e0a43423          	sd	a0,-504(s0)
    80004b1a:	1a050363          	beqz	a0,80004cc0 <kexec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004b1e:	e2843b83          	ld	s7,-472(s0)
    80004b22:	e2042c03          	lw	s8,-480(s0)
    80004b26:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004b2a:	00098463          	beqz	s3,80004b32 <kexec+0x196>
    80004b2e:	4901                	li	s2,0
    80004b30:	bfa1                	j	80004a88 <kexec+0xec>
    sz = sz1;
    80004b32:	e0843903          	ld	s2,-504(s0)
    80004b36:	bfa5                	j	80004aae <kexec+0x112>
    80004b38:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    80004b3a:	8552                	mv	a0,s4
    80004b3c:	c6dfe0ef          	jal	800037a8 <iunlockput>
  end_op();
    80004b40:	cb2ff0ef          	jal	80003ff2 <end_op>
  p = myproc();
    80004b44:	dcdfc0ef          	jal	80001910 <myproc>
    80004b48:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004b4a:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004b4e:	6985                	lui	s3,0x1
    80004b50:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004b52:	99ca                	add	s3,s3,s2
    80004b54:	77fd                	lui	a5,0xfffff
    80004b56:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80004b5a:	4691                	li	a3,4
    80004b5c:	6609                	lui	a2,0x2
    80004b5e:	964e                	add	a2,a2,s3
    80004b60:	85ce                	mv	a1,s3
    80004b62:	855a                	mv	a0,s6
    80004b64:	f66fc0ef          	jal	800012ca <uvmalloc>
    80004b68:	892a                	mv	s2,a0
    80004b6a:	e0a43423          	sd	a0,-504(s0)
    80004b6e:	e519                	bnez	a0,80004b7c <kexec+0x1e0>
  if(pagetable)
    80004b70:	e1343423          	sd	s3,-504(s0)
    80004b74:	4a01                	li	s4,0
    80004b76:	aab1                	j	80004cd2 <kexec+0x336>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004b78:	4901                	li	s2,0
    80004b7a:	b7c1                	j	80004b3a <kexec+0x19e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    80004b7c:	75f9                	lui	a1,0xffffe
    80004b7e:	95aa                	add	a1,a1,a0
    80004b80:	855a                	mv	a0,s6
    80004b82:	91ffc0ef          	jal	800014a0 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80004b86:	7bfd                	lui	s7,0xfffff
    80004b88:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004b8a:	e0043783          	ld	a5,-512(s0)
    80004b8e:	6388                	ld	a0,0(a5)
    80004b90:	cd39                	beqz	a0,80004bee <kexec+0x252>
    80004b92:	e9040993          	addi	s3,s0,-368
    80004b96:	f9040c13          	addi	s8,s0,-112
    80004b9a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004b9c:	ab8fc0ef          	jal	80000e54 <strlen>
    80004ba0:	0015079b          	addiw	a5,a0,1
    80004ba4:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ba8:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004bac:	11796e63          	bltu	s2,s7,80004cc8 <kexec+0x32c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004bb0:	e0043d03          	ld	s10,-512(s0)
    80004bb4:	000d3a03          	ld	s4,0(s10)
    80004bb8:	8552                	mv	a0,s4
    80004bba:	a9afc0ef          	jal	80000e54 <strlen>
    80004bbe:	0015069b          	addiw	a3,a0,1
    80004bc2:	8652                	mv	a2,s4
    80004bc4:	85ca                	mv	a1,s2
    80004bc6:	855a                	mv	a0,s6
    80004bc8:	a5dfc0ef          	jal	80001624 <copyout>
    80004bcc:	10054063          	bltz	a0,80004ccc <kexec+0x330>
    ustack[argc] = sp;
    80004bd0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004bd4:	0485                	addi	s1,s1,1
    80004bd6:	008d0793          	addi	a5,s10,8
    80004bda:	e0f43023          	sd	a5,-512(s0)
    80004bde:	008d3503          	ld	a0,8(s10)
    80004be2:	c909                	beqz	a0,80004bf4 <kexec+0x258>
    if(argc >= MAXARG)
    80004be4:	09a1                	addi	s3,s3,8
    80004be6:	fb899be3          	bne	s3,s8,80004b9c <kexec+0x200>
  ip = 0;
    80004bea:	4a01                	li	s4,0
    80004bec:	a0dd                	j	80004cd2 <kexec+0x336>
  sp = sz;
    80004bee:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004bf2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004bf4:	00349793          	slli	a5,s1,0x3
    80004bf8:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffda518>
    80004bfc:	97a2                	add	a5,a5,s0
    80004bfe:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004c02:	00148693          	addi	a3,s1,1
    80004c06:	068e                	slli	a3,a3,0x3
    80004c08:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004c0c:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004c10:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004c14:	f5796ee3          	bltu	s2,s7,80004b70 <kexec+0x1d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004c18:	e9040613          	addi	a2,s0,-368
    80004c1c:	85ca                	mv	a1,s2
    80004c1e:	855a                	mv	a0,s6
    80004c20:	a05fc0ef          	jal	80001624 <copyout>
    80004c24:	0e054263          	bltz	a0,80004d08 <kexec+0x36c>
  p->trapframe->a1 = sp;
    80004c28:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004c2c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004c30:	df843783          	ld	a5,-520(s0)
    80004c34:	0007c703          	lbu	a4,0(a5)
    80004c38:	cf11                	beqz	a4,80004c54 <kexec+0x2b8>
    80004c3a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004c3c:	02f00693          	li	a3,47
    80004c40:	a039                	j	80004c4e <kexec+0x2b2>
      last = s+1;
    80004c42:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004c46:	0785                	addi	a5,a5,1
    80004c48:	fff7c703          	lbu	a4,-1(a5)
    80004c4c:	c701                	beqz	a4,80004c54 <kexec+0x2b8>
    if(*s == '/')
    80004c4e:	fed71ce3          	bne	a4,a3,80004c46 <kexec+0x2aa>
    80004c52:	bfc5                	j	80004c42 <kexec+0x2a6>
  safestrcpy(p->name, last, sizeof(p->name));
    80004c54:	4641                	li	a2,16
    80004c56:	df843583          	ld	a1,-520(s0)
    80004c5a:	158a8513          	addi	a0,s5,344
    80004c5e:	9c4fc0ef          	jal	80000e22 <safestrcpy>
  oldpagetable = p->pagetable;
    80004c62:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004c66:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004c6a:	e0843783          	ld	a5,-504(s0)
    80004c6e:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    80004c72:	058ab783          	ld	a5,88(s5)
    80004c76:	e6843703          	ld	a4,-408(s0)
    80004c7a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004c7c:	058ab783          	ld	a5,88(s5)
    80004c80:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004c84:	85e6                	mv	a1,s9
    80004c86:	e15fc0ef          	jal	80001a9a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004c8a:	0004851b          	sext.w	a0,s1
    80004c8e:	79be                	ld	s3,488(sp)
    80004c90:	7a1e                	ld	s4,480(sp)
    80004c92:	6afe                	ld	s5,472(sp)
    80004c94:	6b5e                	ld	s6,464(sp)
    80004c96:	6bbe                	ld	s7,456(sp)
    80004c98:	6c1e                	ld	s8,448(sp)
    80004c9a:	7cfa                	ld	s9,440(sp)
    80004c9c:	7d5a                	ld	s10,432(sp)
    80004c9e:	b3b5                	j	80004a0a <kexec+0x6e>
    80004ca0:	e1243423          	sd	s2,-504(s0)
    80004ca4:	7dba                	ld	s11,424(sp)
    80004ca6:	a035                	j	80004cd2 <kexec+0x336>
    80004ca8:	e1243423          	sd	s2,-504(s0)
    80004cac:	7dba                	ld	s11,424(sp)
    80004cae:	a015                	j	80004cd2 <kexec+0x336>
    80004cb0:	e1243423          	sd	s2,-504(s0)
    80004cb4:	7dba                	ld	s11,424(sp)
    80004cb6:	a831                	j	80004cd2 <kexec+0x336>
    80004cb8:	e1243423          	sd	s2,-504(s0)
    80004cbc:	7dba                	ld	s11,424(sp)
    80004cbe:	a811                	j	80004cd2 <kexec+0x336>
    80004cc0:	e1243423          	sd	s2,-504(s0)
    80004cc4:	7dba                	ld	s11,424(sp)
    80004cc6:	a031                	j	80004cd2 <kexec+0x336>
  ip = 0;
    80004cc8:	4a01                	li	s4,0
    80004cca:	a021                	j	80004cd2 <kexec+0x336>
    80004ccc:	4a01                	li	s4,0
  if(pagetable)
    80004cce:	a011                	j	80004cd2 <kexec+0x336>
    80004cd0:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80004cd2:	e0843583          	ld	a1,-504(s0)
    80004cd6:	855a                	mv	a0,s6
    80004cd8:	dc3fc0ef          	jal	80001a9a <proc_freepagetable>
  return -1;
    80004cdc:	557d                	li	a0,-1
  if(ip){
    80004cde:	000a1b63          	bnez	s4,80004cf4 <kexec+0x358>
    80004ce2:	79be                	ld	s3,488(sp)
    80004ce4:	7a1e                	ld	s4,480(sp)
    80004ce6:	6afe                	ld	s5,472(sp)
    80004ce8:	6b5e                	ld	s6,464(sp)
    80004cea:	6bbe                	ld	s7,456(sp)
    80004cec:	6c1e                	ld	s8,448(sp)
    80004cee:	7cfa                	ld	s9,440(sp)
    80004cf0:	7d5a                	ld	s10,432(sp)
    80004cf2:	bb21                	j	80004a0a <kexec+0x6e>
    80004cf4:	79be                	ld	s3,488(sp)
    80004cf6:	6afe                	ld	s5,472(sp)
    80004cf8:	6b5e                	ld	s6,464(sp)
    80004cfa:	6bbe                	ld	s7,456(sp)
    80004cfc:	6c1e                	ld	s8,448(sp)
    80004cfe:	7cfa                	ld	s9,440(sp)
    80004d00:	7d5a                	ld	s10,432(sp)
    80004d02:	b9ed                	j	800049fc <kexec+0x60>
    80004d04:	6b5e                	ld	s6,464(sp)
    80004d06:	b9dd                	j	800049fc <kexec+0x60>
  sz = sz1;
    80004d08:	e0843983          	ld	s3,-504(s0)
    80004d0c:	b595                	j	80004b70 <kexec+0x1d4>

0000000080004d0e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004d0e:	7179                	addi	sp,sp,-48
    80004d10:	f406                	sd	ra,40(sp)
    80004d12:	f022                	sd	s0,32(sp)
    80004d14:	ec26                	sd	s1,24(sp)
    80004d16:	e84a                	sd	s2,16(sp)
    80004d18:	1800                	addi	s0,sp,48
    80004d1a:	892e                	mv	s2,a1
    80004d1c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004d1e:	fdc40593          	addi	a1,s0,-36
    80004d22:	c6bfd0ef          	jal	8000298c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004d26:	fdc42703          	lw	a4,-36(s0)
    80004d2a:	47bd                	li	a5,15
    80004d2c:	02e7e963          	bltu	a5,a4,80004d5e <argfd+0x50>
    80004d30:	be1fc0ef          	jal	80001910 <myproc>
    80004d34:	fdc42703          	lw	a4,-36(s0)
    80004d38:	01a70793          	addi	a5,a4,26
    80004d3c:	078e                	slli	a5,a5,0x3
    80004d3e:	953e                	add	a0,a0,a5
    80004d40:	611c                	ld	a5,0(a0)
    80004d42:	c385                	beqz	a5,80004d62 <argfd+0x54>
    return -1;
  if(pfd)
    80004d44:	00090463          	beqz	s2,80004d4c <argfd+0x3e>
    *pfd = fd;
    80004d48:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004d4c:	4501                	li	a0,0
  if(pf)
    80004d4e:	c091                	beqz	s1,80004d52 <argfd+0x44>
    *pf = f;
    80004d50:	e09c                	sd	a5,0(s1)
}
    80004d52:	70a2                	ld	ra,40(sp)
    80004d54:	7402                	ld	s0,32(sp)
    80004d56:	64e2                	ld	s1,24(sp)
    80004d58:	6942                	ld	s2,16(sp)
    80004d5a:	6145                	addi	sp,sp,48
    80004d5c:	8082                	ret
    return -1;
    80004d5e:	557d                	li	a0,-1
    80004d60:	bfcd                	j	80004d52 <argfd+0x44>
    80004d62:	557d                	li	a0,-1
    80004d64:	b7fd                	j	80004d52 <argfd+0x44>

0000000080004d66 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004d66:	1101                	addi	sp,sp,-32
    80004d68:	ec06                	sd	ra,24(sp)
    80004d6a:	e822                	sd	s0,16(sp)
    80004d6c:	e426                	sd	s1,8(sp)
    80004d6e:	1000                	addi	s0,sp,32
    80004d70:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004d72:	b9ffc0ef          	jal	80001910 <myproc>
    80004d76:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004d78:	0d050793          	addi	a5,a0,208
    80004d7c:	4501                	li	a0,0
    80004d7e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004d80:	6398                	ld	a4,0(a5)
    80004d82:	cb19                	beqz	a4,80004d98 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004d84:	2505                	addiw	a0,a0,1
    80004d86:	07a1                	addi	a5,a5,8
    80004d88:	fed51ce3          	bne	a0,a3,80004d80 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004d8c:	557d                	li	a0,-1
}
    80004d8e:	60e2                	ld	ra,24(sp)
    80004d90:	6442                	ld	s0,16(sp)
    80004d92:	64a2                	ld	s1,8(sp)
    80004d94:	6105                	addi	sp,sp,32
    80004d96:	8082                	ret
      p->ofile[fd] = f;
    80004d98:	01a50793          	addi	a5,a0,26
    80004d9c:	078e                	slli	a5,a5,0x3
    80004d9e:	963e                	add	a2,a2,a5
    80004da0:	e204                	sd	s1,0(a2)
      return fd;
    80004da2:	b7f5                	j	80004d8e <fdalloc+0x28>

0000000080004da4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004da4:	715d                	addi	sp,sp,-80
    80004da6:	e486                	sd	ra,72(sp)
    80004da8:	e0a2                	sd	s0,64(sp)
    80004daa:	fc26                	sd	s1,56(sp)
    80004dac:	f84a                	sd	s2,48(sp)
    80004dae:	f44e                	sd	s3,40(sp)
    80004db0:	ec56                	sd	s5,24(sp)
    80004db2:	e85a                	sd	s6,16(sp)
    80004db4:	0880                	addi	s0,sp,80
    80004db6:	8b2e                	mv	s6,a1
    80004db8:	89b2                	mv	s3,a2
    80004dba:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004dbc:	fb040593          	addi	a1,s0,-80
    80004dc0:	80eff0ef          	jal	80003dce <nameiparent>
    80004dc4:	84aa                	mv	s1,a0
    80004dc6:	10050a63          	beqz	a0,80004eda <create+0x136>
    return 0;

  ilock(dp);
    80004dca:	fd4fe0ef          	jal	8000359e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004dce:	4601                	li	a2,0
    80004dd0:	fb040593          	addi	a1,s0,-80
    80004dd4:	8526                	mv	a0,s1
    80004dd6:	d79fe0ef          	jal	80003b4e <dirlookup>
    80004dda:	8aaa                	mv	s5,a0
    80004ddc:	c129                	beqz	a0,80004e1e <create+0x7a>
    iunlockput(dp);
    80004dde:	8526                	mv	a0,s1
    80004de0:	9c9fe0ef          	jal	800037a8 <iunlockput>
    ilock(ip);
    80004de4:	8556                	mv	a0,s5
    80004de6:	fb8fe0ef          	jal	8000359e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004dea:	4789                	li	a5,2
    80004dec:	02fb1463          	bne	s6,a5,80004e14 <create+0x70>
    80004df0:	044ad783          	lhu	a5,68(s5)
    80004df4:	37f9                	addiw	a5,a5,-2
    80004df6:	17c2                	slli	a5,a5,0x30
    80004df8:	93c1                	srli	a5,a5,0x30
    80004dfa:	4705                	li	a4,1
    80004dfc:	00f76c63          	bltu	a4,a5,80004e14 <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004e00:	8556                	mv	a0,s5
    80004e02:	60a6                	ld	ra,72(sp)
    80004e04:	6406                	ld	s0,64(sp)
    80004e06:	74e2                	ld	s1,56(sp)
    80004e08:	7942                	ld	s2,48(sp)
    80004e0a:	79a2                	ld	s3,40(sp)
    80004e0c:	6ae2                	ld	s5,24(sp)
    80004e0e:	6b42                	ld	s6,16(sp)
    80004e10:	6161                	addi	sp,sp,80
    80004e12:	8082                	ret
    iunlockput(ip);
    80004e14:	8556                	mv	a0,s5
    80004e16:	993fe0ef          	jal	800037a8 <iunlockput>
    return 0;
    80004e1a:	4a81                	li	s5,0
    80004e1c:	b7d5                	j	80004e00 <create+0x5c>
    80004e1e:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80004e20:	85da                	mv	a1,s6
    80004e22:	4088                	lw	a0,0(s1)
    80004e24:	e0afe0ef          	jal	8000342e <ialloc>
    80004e28:	8a2a                	mv	s4,a0
    80004e2a:	cd15                	beqz	a0,80004e66 <create+0xc2>
  ilock(ip);
    80004e2c:	f72fe0ef          	jal	8000359e <ilock>
  ip->major = major;
    80004e30:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004e34:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004e38:	4905                	li	s2,1
    80004e3a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004e3e:	8552                	mv	a0,s4
    80004e40:	eaafe0ef          	jal	800034ea <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004e44:	032b0763          	beq	s6,s2,80004e72 <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80004e48:	004a2603          	lw	a2,4(s4)
    80004e4c:	fb040593          	addi	a1,s0,-80
    80004e50:	8526                	mv	a0,s1
    80004e52:	ec9fe0ef          	jal	80003d1a <dirlink>
    80004e56:	06054563          	bltz	a0,80004ec0 <create+0x11c>
  iunlockput(dp);
    80004e5a:	8526                	mv	a0,s1
    80004e5c:	94dfe0ef          	jal	800037a8 <iunlockput>
  return ip;
    80004e60:	8ad2                	mv	s5,s4
    80004e62:	7a02                	ld	s4,32(sp)
    80004e64:	bf71                	j	80004e00 <create+0x5c>
    iunlockput(dp);
    80004e66:	8526                	mv	a0,s1
    80004e68:	941fe0ef          	jal	800037a8 <iunlockput>
    return 0;
    80004e6c:	8ad2                	mv	s5,s4
    80004e6e:	7a02                	ld	s4,32(sp)
    80004e70:	bf41                	j	80004e00 <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004e72:	004a2603          	lw	a2,4(s4)
    80004e76:	00003597          	auipc	a1,0x3
    80004e7a:	85258593          	addi	a1,a1,-1966 # 800076c8 <etext+0x6c8>
    80004e7e:	8552                	mv	a0,s4
    80004e80:	e9bfe0ef          	jal	80003d1a <dirlink>
    80004e84:	02054e63          	bltz	a0,80004ec0 <create+0x11c>
    80004e88:	40d0                	lw	a2,4(s1)
    80004e8a:	00003597          	auipc	a1,0x3
    80004e8e:	84658593          	addi	a1,a1,-1978 # 800076d0 <etext+0x6d0>
    80004e92:	8552                	mv	a0,s4
    80004e94:	e87fe0ef          	jal	80003d1a <dirlink>
    80004e98:	02054463          	bltz	a0,80004ec0 <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80004e9c:	004a2603          	lw	a2,4(s4)
    80004ea0:	fb040593          	addi	a1,s0,-80
    80004ea4:	8526                	mv	a0,s1
    80004ea6:	e75fe0ef          	jal	80003d1a <dirlink>
    80004eaa:	00054b63          	bltz	a0,80004ec0 <create+0x11c>
    dp->nlink++;  // for ".."
    80004eae:	04a4d783          	lhu	a5,74(s1)
    80004eb2:	2785                	addiw	a5,a5,1
    80004eb4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004eb8:	8526                	mv	a0,s1
    80004eba:	e30fe0ef          	jal	800034ea <iupdate>
    80004ebe:	bf71                	j	80004e5a <create+0xb6>
  ip->nlink = 0;
    80004ec0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004ec4:	8552                	mv	a0,s4
    80004ec6:	e24fe0ef          	jal	800034ea <iupdate>
  iunlockput(ip);
    80004eca:	8552                	mv	a0,s4
    80004ecc:	8ddfe0ef          	jal	800037a8 <iunlockput>
  iunlockput(dp);
    80004ed0:	8526                	mv	a0,s1
    80004ed2:	8d7fe0ef          	jal	800037a8 <iunlockput>
  return 0;
    80004ed6:	7a02                	ld	s4,32(sp)
    80004ed8:	b725                	j	80004e00 <create+0x5c>
    return 0;
    80004eda:	8aaa                	mv	s5,a0
    80004edc:	b715                	j	80004e00 <create+0x5c>

0000000080004ede <sys_dup>:
{
    80004ede:	7179                	addi	sp,sp,-48
    80004ee0:	f406                	sd	ra,40(sp)
    80004ee2:	f022                	sd	s0,32(sp)
    80004ee4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004ee6:	fd840613          	addi	a2,s0,-40
    80004eea:	4581                	li	a1,0
    80004eec:	4501                	li	a0,0
    80004eee:	e21ff0ef          	jal	80004d0e <argfd>
    return -1;
    80004ef2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004ef4:	02054363          	bltz	a0,80004f1a <sys_dup+0x3c>
    80004ef8:	ec26                	sd	s1,24(sp)
    80004efa:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80004efc:	fd843903          	ld	s2,-40(s0)
    80004f00:	854a                	mv	a0,s2
    80004f02:	e65ff0ef          	jal	80004d66 <fdalloc>
    80004f06:	84aa                	mv	s1,a0
    return -1;
    80004f08:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80004f0a:	00054d63          	bltz	a0,80004f24 <sys_dup+0x46>
  filedup(f);
    80004f0e:	854a                	mv	a0,s2
    80004f10:	c3eff0ef          	jal	8000434e <filedup>
  return fd;
    80004f14:	87a6                	mv	a5,s1
    80004f16:	64e2                	ld	s1,24(sp)
    80004f18:	6942                	ld	s2,16(sp)
}
    80004f1a:	853e                	mv	a0,a5
    80004f1c:	70a2                	ld	ra,40(sp)
    80004f1e:	7402                	ld	s0,32(sp)
    80004f20:	6145                	addi	sp,sp,48
    80004f22:	8082                	ret
    80004f24:	64e2                	ld	s1,24(sp)
    80004f26:	6942                	ld	s2,16(sp)
    80004f28:	bfcd                	j	80004f1a <sys_dup+0x3c>

0000000080004f2a <sys_read>:
{
    80004f2a:	7179                	addi	sp,sp,-48
    80004f2c:	f406                	sd	ra,40(sp)
    80004f2e:	f022                	sd	s0,32(sp)
    80004f30:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004f32:	fd840593          	addi	a1,s0,-40
    80004f36:	4505                	li	a0,1
    80004f38:	a71fd0ef          	jal	800029a8 <argaddr>
  argint(2, &n);
    80004f3c:	fe440593          	addi	a1,s0,-28
    80004f40:	4509                	li	a0,2
    80004f42:	a4bfd0ef          	jal	8000298c <argint>
  if(argfd(0, 0, &f) < 0)
    80004f46:	fe840613          	addi	a2,s0,-24
    80004f4a:	4581                	li	a1,0
    80004f4c:	4501                	li	a0,0
    80004f4e:	dc1ff0ef          	jal	80004d0e <argfd>
    80004f52:	87aa                	mv	a5,a0
    return -1;
    80004f54:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004f56:	0007ca63          	bltz	a5,80004f6a <sys_read+0x40>
  return fileread(f, p, n);
    80004f5a:	fe442603          	lw	a2,-28(s0)
    80004f5e:	fd843583          	ld	a1,-40(s0)
    80004f62:	fe843503          	ld	a0,-24(s0)
    80004f66:	d4eff0ef          	jal	800044b4 <fileread>
}
    80004f6a:	70a2                	ld	ra,40(sp)
    80004f6c:	7402                	ld	s0,32(sp)
    80004f6e:	6145                	addi	sp,sp,48
    80004f70:	8082                	ret

0000000080004f72 <sys_write>:
{
    80004f72:	7179                	addi	sp,sp,-48
    80004f74:	f406                	sd	ra,40(sp)
    80004f76:	f022                	sd	s0,32(sp)
    80004f78:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004f7a:	fd840593          	addi	a1,s0,-40
    80004f7e:	4505                	li	a0,1
    80004f80:	a29fd0ef          	jal	800029a8 <argaddr>
  argint(2, &n);
    80004f84:	fe440593          	addi	a1,s0,-28
    80004f88:	4509                	li	a0,2
    80004f8a:	a03fd0ef          	jal	8000298c <argint>
  if(argfd(0, 0, &f) < 0)
    80004f8e:	fe840613          	addi	a2,s0,-24
    80004f92:	4581                	li	a1,0
    80004f94:	4501                	li	a0,0
    80004f96:	d79ff0ef          	jal	80004d0e <argfd>
    80004f9a:	87aa                	mv	a5,a0
    return -1;
    80004f9c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004f9e:	0007ca63          	bltz	a5,80004fb2 <sys_write+0x40>
  return filewrite(f, p, n);
    80004fa2:	fe442603          	lw	a2,-28(s0)
    80004fa6:	fd843583          	ld	a1,-40(s0)
    80004faa:	fe843503          	ld	a0,-24(s0)
    80004fae:	dc4ff0ef          	jal	80004572 <filewrite>
}
    80004fb2:	70a2                	ld	ra,40(sp)
    80004fb4:	7402                	ld	s0,32(sp)
    80004fb6:	6145                	addi	sp,sp,48
    80004fb8:	8082                	ret

0000000080004fba <sys_close>:
{
    80004fba:	1101                	addi	sp,sp,-32
    80004fbc:	ec06                	sd	ra,24(sp)
    80004fbe:	e822                	sd	s0,16(sp)
    80004fc0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004fc2:	fe040613          	addi	a2,s0,-32
    80004fc6:	fec40593          	addi	a1,s0,-20
    80004fca:	4501                	li	a0,0
    80004fcc:	d43ff0ef          	jal	80004d0e <argfd>
    return -1;
    80004fd0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004fd2:	02054063          	bltz	a0,80004ff2 <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004fd6:	93bfc0ef          	jal	80001910 <myproc>
    80004fda:	fec42783          	lw	a5,-20(s0)
    80004fde:	07e9                	addi	a5,a5,26
    80004fe0:	078e                	slli	a5,a5,0x3
    80004fe2:	953e                	add	a0,a0,a5
    80004fe4:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80004fe8:	fe043503          	ld	a0,-32(s0)
    80004fec:	ba8ff0ef          	jal	80004394 <fileclose>
  return 0;
    80004ff0:	4781                	li	a5,0
}
    80004ff2:	853e                	mv	a0,a5
    80004ff4:	60e2                	ld	ra,24(sp)
    80004ff6:	6442                	ld	s0,16(sp)
    80004ff8:	6105                	addi	sp,sp,32
    80004ffa:	8082                	ret

0000000080004ffc <sys_fstat>:
{
    80004ffc:	1101                	addi	sp,sp,-32
    80004ffe:	ec06                	sd	ra,24(sp)
    80005000:	e822                	sd	s0,16(sp)
    80005002:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005004:	fe040593          	addi	a1,s0,-32
    80005008:	4505                	li	a0,1
    8000500a:	99ffd0ef          	jal	800029a8 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000500e:	fe840613          	addi	a2,s0,-24
    80005012:	4581                	li	a1,0
    80005014:	4501                	li	a0,0
    80005016:	cf9ff0ef          	jal	80004d0e <argfd>
    8000501a:	87aa                	mv	a5,a0
    return -1;
    8000501c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000501e:	0007c863          	bltz	a5,8000502e <sys_fstat+0x32>
  return filestat(f, st);
    80005022:	fe043583          	ld	a1,-32(s0)
    80005026:	fe843503          	ld	a0,-24(s0)
    8000502a:	c2cff0ef          	jal	80004456 <filestat>
}
    8000502e:	60e2                	ld	ra,24(sp)
    80005030:	6442                	ld	s0,16(sp)
    80005032:	6105                	addi	sp,sp,32
    80005034:	8082                	ret

0000000080005036 <sys_link>:
{
    80005036:	7169                	addi	sp,sp,-304
    80005038:	f606                	sd	ra,296(sp)
    8000503a:	f222                	sd	s0,288(sp)
    8000503c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000503e:	08000613          	li	a2,128
    80005042:	ed040593          	addi	a1,s0,-304
    80005046:	4501                	li	a0,0
    80005048:	97dfd0ef          	jal	800029c4 <argstr>
    return -1;
    8000504c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000504e:	0c054e63          	bltz	a0,8000512a <sys_link+0xf4>
    80005052:	08000613          	li	a2,128
    80005056:	f5040593          	addi	a1,s0,-176
    8000505a:	4505                	li	a0,1
    8000505c:	969fd0ef          	jal	800029c4 <argstr>
    return -1;
    80005060:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005062:	0c054463          	bltz	a0,8000512a <sys_link+0xf4>
    80005066:	ee26                	sd	s1,280(sp)
  begin_op();
    80005068:	f21fe0ef          	jal	80003f88 <begin_op>
  if((ip = namei(old)) == 0){
    8000506c:	ed040513          	addi	a0,s0,-304
    80005070:	d45fe0ef          	jal	80003db4 <namei>
    80005074:	84aa                	mv	s1,a0
    80005076:	c53d                	beqz	a0,800050e4 <sys_link+0xae>
  ilock(ip);
    80005078:	d26fe0ef          	jal	8000359e <ilock>
  if(ip->type == T_DIR){
    8000507c:	04449703          	lh	a4,68(s1)
    80005080:	4785                	li	a5,1
    80005082:	06f70663          	beq	a4,a5,800050ee <sys_link+0xb8>
    80005086:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80005088:	04a4d783          	lhu	a5,74(s1)
    8000508c:	2785                	addiw	a5,a5,1
    8000508e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005092:	8526                	mv	a0,s1
    80005094:	c56fe0ef          	jal	800034ea <iupdate>
  iunlock(ip);
    80005098:	8526                	mv	a0,s1
    8000509a:	db2fe0ef          	jal	8000364c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000509e:	fd040593          	addi	a1,s0,-48
    800050a2:	f5040513          	addi	a0,s0,-176
    800050a6:	d29fe0ef          	jal	80003dce <nameiparent>
    800050aa:	892a                	mv	s2,a0
    800050ac:	cd21                	beqz	a0,80005104 <sys_link+0xce>
  ilock(dp);
    800050ae:	cf0fe0ef          	jal	8000359e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800050b2:	00092703          	lw	a4,0(s2)
    800050b6:	409c                	lw	a5,0(s1)
    800050b8:	04f71363          	bne	a4,a5,800050fe <sys_link+0xc8>
    800050bc:	40d0                	lw	a2,4(s1)
    800050be:	fd040593          	addi	a1,s0,-48
    800050c2:	854a                	mv	a0,s2
    800050c4:	c57fe0ef          	jal	80003d1a <dirlink>
    800050c8:	02054b63          	bltz	a0,800050fe <sys_link+0xc8>
  iunlockput(dp);
    800050cc:	854a                	mv	a0,s2
    800050ce:	edafe0ef          	jal	800037a8 <iunlockput>
  iput(ip);
    800050d2:	8526                	mv	a0,s1
    800050d4:	e4cfe0ef          	jal	80003720 <iput>
  end_op();
    800050d8:	f1bfe0ef          	jal	80003ff2 <end_op>
  return 0;
    800050dc:	4781                	li	a5,0
    800050de:	64f2                	ld	s1,280(sp)
    800050e0:	6952                	ld	s2,272(sp)
    800050e2:	a0a1                	j	8000512a <sys_link+0xf4>
    end_op();
    800050e4:	f0ffe0ef          	jal	80003ff2 <end_op>
    return -1;
    800050e8:	57fd                	li	a5,-1
    800050ea:	64f2                	ld	s1,280(sp)
    800050ec:	a83d                	j	8000512a <sys_link+0xf4>
    iunlockput(ip);
    800050ee:	8526                	mv	a0,s1
    800050f0:	eb8fe0ef          	jal	800037a8 <iunlockput>
    end_op();
    800050f4:	efffe0ef          	jal	80003ff2 <end_op>
    return -1;
    800050f8:	57fd                	li	a5,-1
    800050fa:	64f2                	ld	s1,280(sp)
    800050fc:	a03d                	j	8000512a <sys_link+0xf4>
    iunlockput(dp);
    800050fe:	854a                	mv	a0,s2
    80005100:	ea8fe0ef          	jal	800037a8 <iunlockput>
  ilock(ip);
    80005104:	8526                	mv	a0,s1
    80005106:	c98fe0ef          	jal	8000359e <ilock>
  ip->nlink--;
    8000510a:	04a4d783          	lhu	a5,74(s1)
    8000510e:	37fd                	addiw	a5,a5,-1
    80005110:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005114:	8526                	mv	a0,s1
    80005116:	bd4fe0ef          	jal	800034ea <iupdate>
  iunlockput(ip);
    8000511a:	8526                	mv	a0,s1
    8000511c:	e8cfe0ef          	jal	800037a8 <iunlockput>
  end_op();
    80005120:	ed3fe0ef          	jal	80003ff2 <end_op>
  return -1;
    80005124:	57fd                	li	a5,-1
    80005126:	64f2                	ld	s1,280(sp)
    80005128:	6952                	ld	s2,272(sp)
}
    8000512a:	853e                	mv	a0,a5
    8000512c:	70b2                	ld	ra,296(sp)
    8000512e:	7412                	ld	s0,288(sp)
    80005130:	6155                	addi	sp,sp,304
    80005132:	8082                	ret

0000000080005134 <sys_unlink>:
{
    80005134:	7151                	addi	sp,sp,-240
    80005136:	f586                	sd	ra,232(sp)
    80005138:	f1a2                	sd	s0,224(sp)
    8000513a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000513c:	08000613          	li	a2,128
    80005140:	f3040593          	addi	a1,s0,-208
    80005144:	4501                	li	a0,0
    80005146:	87ffd0ef          	jal	800029c4 <argstr>
    8000514a:	16054063          	bltz	a0,800052aa <sys_unlink+0x176>
    8000514e:	eda6                	sd	s1,216(sp)
  begin_op();
    80005150:	e39fe0ef          	jal	80003f88 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005154:	fb040593          	addi	a1,s0,-80
    80005158:	f3040513          	addi	a0,s0,-208
    8000515c:	c73fe0ef          	jal	80003dce <nameiparent>
    80005160:	84aa                	mv	s1,a0
    80005162:	c945                	beqz	a0,80005212 <sys_unlink+0xde>
  ilock(dp);
    80005164:	c3afe0ef          	jal	8000359e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005168:	00002597          	auipc	a1,0x2
    8000516c:	56058593          	addi	a1,a1,1376 # 800076c8 <etext+0x6c8>
    80005170:	fb040513          	addi	a0,s0,-80
    80005174:	9c5fe0ef          	jal	80003b38 <namecmp>
    80005178:	10050e63          	beqz	a0,80005294 <sys_unlink+0x160>
    8000517c:	00002597          	auipc	a1,0x2
    80005180:	55458593          	addi	a1,a1,1364 # 800076d0 <etext+0x6d0>
    80005184:	fb040513          	addi	a0,s0,-80
    80005188:	9b1fe0ef          	jal	80003b38 <namecmp>
    8000518c:	10050463          	beqz	a0,80005294 <sys_unlink+0x160>
    80005190:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005192:	f2c40613          	addi	a2,s0,-212
    80005196:	fb040593          	addi	a1,s0,-80
    8000519a:	8526                	mv	a0,s1
    8000519c:	9b3fe0ef          	jal	80003b4e <dirlookup>
    800051a0:	892a                	mv	s2,a0
    800051a2:	0e050863          	beqz	a0,80005292 <sys_unlink+0x15e>
  ilock(ip);
    800051a6:	bf8fe0ef          	jal	8000359e <ilock>
  if(ip->nlink < 1)
    800051aa:	04a91783          	lh	a5,74(s2)
    800051ae:	06f05763          	blez	a5,8000521c <sys_unlink+0xe8>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800051b2:	04491703          	lh	a4,68(s2)
    800051b6:	4785                	li	a5,1
    800051b8:	06f70963          	beq	a4,a5,8000522a <sys_unlink+0xf6>
  memset(&de, 0, sizeof(de));
    800051bc:	4641                	li	a2,16
    800051be:	4581                	li	a1,0
    800051c0:	fc040513          	addi	a0,s0,-64
    800051c4:	b21fb0ef          	jal	80000ce4 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800051c8:	4741                	li	a4,16
    800051ca:	f2c42683          	lw	a3,-212(s0)
    800051ce:	fc040613          	addi	a2,s0,-64
    800051d2:	4581                	li	a1,0
    800051d4:	8526                	mv	a0,s1
    800051d6:	855fe0ef          	jal	80003a2a <writei>
    800051da:	47c1                	li	a5,16
    800051dc:	08f51b63          	bne	a0,a5,80005272 <sys_unlink+0x13e>
  if(ip->type == T_DIR){
    800051e0:	04491703          	lh	a4,68(s2)
    800051e4:	4785                	li	a5,1
    800051e6:	08f70d63          	beq	a4,a5,80005280 <sys_unlink+0x14c>
  iunlockput(dp);
    800051ea:	8526                	mv	a0,s1
    800051ec:	dbcfe0ef          	jal	800037a8 <iunlockput>
  ip->nlink--;
    800051f0:	04a95783          	lhu	a5,74(s2)
    800051f4:	37fd                	addiw	a5,a5,-1
    800051f6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800051fa:	854a                	mv	a0,s2
    800051fc:	aeefe0ef          	jal	800034ea <iupdate>
  iunlockput(ip);
    80005200:	854a                	mv	a0,s2
    80005202:	da6fe0ef          	jal	800037a8 <iunlockput>
  end_op();
    80005206:	dedfe0ef          	jal	80003ff2 <end_op>
  return 0;
    8000520a:	4501                	li	a0,0
    8000520c:	64ee                	ld	s1,216(sp)
    8000520e:	694e                	ld	s2,208(sp)
    80005210:	a849                	j	800052a2 <sys_unlink+0x16e>
    end_op();
    80005212:	de1fe0ef          	jal	80003ff2 <end_op>
    return -1;
    80005216:	557d                	li	a0,-1
    80005218:	64ee                	ld	s1,216(sp)
    8000521a:	a061                	j	800052a2 <sys_unlink+0x16e>
    8000521c:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    8000521e:	00002517          	auipc	a0,0x2
    80005222:	4ba50513          	addi	a0,a0,1210 # 800076d8 <etext+0x6d8>
    80005226:	dbafb0ef          	jal	800007e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000522a:	04c92703          	lw	a4,76(s2)
    8000522e:	02000793          	li	a5,32
    80005232:	f8e7f5e3          	bgeu	a5,a4,800051bc <sys_unlink+0x88>
    80005236:	e5ce                	sd	s3,200(sp)
    80005238:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000523c:	4741                	li	a4,16
    8000523e:	86ce                	mv	a3,s3
    80005240:	f1840613          	addi	a2,s0,-232
    80005244:	4581                	li	a1,0
    80005246:	854a                	mv	a0,s2
    80005248:	ee6fe0ef          	jal	8000392e <readi>
    8000524c:	47c1                	li	a5,16
    8000524e:	00f51c63          	bne	a0,a5,80005266 <sys_unlink+0x132>
    if(de.inum != 0)
    80005252:	f1845783          	lhu	a5,-232(s0)
    80005256:	efa1                	bnez	a5,800052ae <sys_unlink+0x17a>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005258:	29c1                	addiw	s3,s3,16
    8000525a:	04c92783          	lw	a5,76(s2)
    8000525e:	fcf9efe3          	bltu	s3,a5,8000523c <sys_unlink+0x108>
    80005262:	69ae                	ld	s3,200(sp)
    80005264:	bfa1                	j	800051bc <sys_unlink+0x88>
      panic("isdirempty: readi");
    80005266:	00002517          	auipc	a0,0x2
    8000526a:	48a50513          	addi	a0,a0,1162 # 800076f0 <etext+0x6f0>
    8000526e:	d72fb0ef          	jal	800007e0 <panic>
    80005272:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80005274:	00002517          	auipc	a0,0x2
    80005278:	49450513          	addi	a0,a0,1172 # 80007708 <etext+0x708>
    8000527c:	d64fb0ef          	jal	800007e0 <panic>
    dp->nlink--;
    80005280:	04a4d783          	lhu	a5,74(s1)
    80005284:	37fd                	addiw	a5,a5,-1
    80005286:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000528a:	8526                	mv	a0,s1
    8000528c:	a5efe0ef          	jal	800034ea <iupdate>
    80005290:	bfa9                	j	800051ea <sys_unlink+0xb6>
    80005292:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80005294:	8526                	mv	a0,s1
    80005296:	d12fe0ef          	jal	800037a8 <iunlockput>
  end_op();
    8000529a:	d59fe0ef          	jal	80003ff2 <end_op>
  return -1;
    8000529e:	557d                	li	a0,-1
    800052a0:	64ee                	ld	s1,216(sp)
}
    800052a2:	70ae                	ld	ra,232(sp)
    800052a4:	740e                	ld	s0,224(sp)
    800052a6:	616d                	addi	sp,sp,240
    800052a8:	8082                	ret
    return -1;
    800052aa:	557d                	li	a0,-1
    800052ac:	bfdd                	j	800052a2 <sys_unlink+0x16e>
    iunlockput(ip);
    800052ae:	854a                	mv	a0,s2
    800052b0:	cf8fe0ef          	jal	800037a8 <iunlockput>
    goto bad;
    800052b4:	694e                	ld	s2,208(sp)
    800052b6:	69ae                	ld	s3,200(sp)
    800052b8:	bff1                	j	80005294 <sys_unlink+0x160>

00000000800052ba <sys_open>:

uint64
sys_open(void)
{
    800052ba:	7131                	addi	sp,sp,-192
    800052bc:	fd06                	sd	ra,184(sp)
    800052be:	f922                	sd	s0,176(sp)
    800052c0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800052c2:	f4c40593          	addi	a1,s0,-180
    800052c6:	4505                	li	a0,1
    800052c8:	ec4fd0ef          	jal	8000298c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800052cc:	08000613          	li	a2,128
    800052d0:	f5040593          	addi	a1,s0,-176
    800052d4:	4501                	li	a0,0
    800052d6:	eeefd0ef          	jal	800029c4 <argstr>
    800052da:	87aa                	mv	a5,a0
    return -1;
    800052dc:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800052de:	0a07c263          	bltz	a5,80005382 <sys_open+0xc8>
    800052e2:	f526                	sd	s1,168(sp)

  begin_op();
    800052e4:	ca5fe0ef          	jal	80003f88 <begin_op>

  if(omode & O_CREATE){
    800052e8:	f4c42783          	lw	a5,-180(s0)
    800052ec:	2007f793          	andi	a5,a5,512
    800052f0:	c3d5                	beqz	a5,80005394 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    800052f2:	4681                	li	a3,0
    800052f4:	4601                	li	a2,0
    800052f6:	4589                	li	a1,2
    800052f8:	f5040513          	addi	a0,s0,-176
    800052fc:	aa9ff0ef          	jal	80004da4 <create>
    80005300:	84aa                	mv	s1,a0
    if(ip == 0){
    80005302:	c541                	beqz	a0,8000538a <sys_open+0xd0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005304:	04449703          	lh	a4,68(s1)
    80005308:	478d                	li	a5,3
    8000530a:	00f71763          	bne	a4,a5,80005318 <sys_open+0x5e>
    8000530e:	0464d703          	lhu	a4,70(s1)
    80005312:	47a5                	li	a5,9
    80005314:	0ae7ed63          	bltu	a5,a4,800053ce <sys_open+0x114>
    80005318:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000531a:	fd7fe0ef          	jal	800042f0 <filealloc>
    8000531e:	892a                	mv	s2,a0
    80005320:	c179                	beqz	a0,800053e6 <sys_open+0x12c>
    80005322:	ed4e                	sd	s3,152(sp)
    80005324:	a43ff0ef          	jal	80004d66 <fdalloc>
    80005328:	89aa                	mv	s3,a0
    8000532a:	0a054a63          	bltz	a0,800053de <sys_open+0x124>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000532e:	04449703          	lh	a4,68(s1)
    80005332:	478d                	li	a5,3
    80005334:	0cf70263          	beq	a4,a5,800053f8 <sys_open+0x13e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005338:	4789                	li	a5,2
    8000533a:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    8000533e:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005342:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005346:	f4c42783          	lw	a5,-180(s0)
    8000534a:	0017c713          	xori	a4,a5,1
    8000534e:	8b05                	andi	a4,a4,1
    80005350:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005354:	0037f713          	andi	a4,a5,3
    80005358:	00e03733          	snez	a4,a4
    8000535c:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005360:	4007f793          	andi	a5,a5,1024
    80005364:	c791                	beqz	a5,80005370 <sys_open+0xb6>
    80005366:	04449703          	lh	a4,68(s1)
    8000536a:	4789                	li	a5,2
    8000536c:	08f70d63          	beq	a4,a5,80005406 <sys_open+0x14c>
    itrunc(ip);
  }

  iunlock(ip);
    80005370:	8526                	mv	a0,s1
    80005372:	adafe0ef          	jal	8000364c <iunlock>
  end_op();
    80005376:	c7dfe0ef          	jal	80003ff2 <end_op>

  return fd;
    8000537a:	854e                	mv	a0,s3
    8000537c:	74aa                	ld	s1,168(sp)
    8000537e:	790a                	ld	s2,160(sp)
    80005380:	69ea                	ld	s3,152(sp)
}
    80005382:	70ea                	ld	ra,184(sp)
    80005384:	744a                	ld	s0,176(sp)
    80005386:	6129                	addi	sp,sp,192
    80005388:	8082                	ret
      end_op();
    8000538a:	c69fe0ef          	jal	80003ff2 <end_op>
      return -1;
    8000538e:	557d                	li	a0,-1
    80005390:	74aa                	ld	s1,168(sp)
    80005392:	bfc5                	j	80005382 <sys_open+0xc8>
    if((ip = namei(path)) == 0){
    80005394:	f5040513          	addi	a0,s0,-176
    80005398:	a1dfe0ef          	jal	80003db4 <namei>
    8000539c:	84aa                	mv	s1,a0
    8000539e:	c11d                	beqz	a0,800053c4 <sys_open+0x10a>
    ilock(ip);
    800053a0:	9fefe0ef          	jal	8000359e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800053a4:	04449703          	lh	a4,68(s1)
    800053a8:	4785                	li	a5,1
    800053aa:	f4f71de3          	bne	a4,a5,80005304 <sys_open+0x4a>
    800053ae:	f4c42783          	lw	a5,-180(s0)
    800053b2:	d3bd                	beqz	a5,80005318 <sys_open+0x5e>
      iunlockput(ip);
    800053b4:	8526                	mv	a0,s1
    800053b6:	bf2fe0ef          	jal	800037a8 <iunlockput>
      end_op();
    800053ba:	c39fe0ef          	jal	80003ff2 <end_op>
      return -1;
    800053be:	557d                	li	a0,-1
    800053c0:	74aa                	ld	s1,168(sp)
    800053c2:	b7c1                	j	80005382 <sys_open+0xc8>
      end_op();
    800053c4:	c2ffe0ef          	jal	80003ff2 <end_op>
      return -1;
    800053c8:	557d                	li	a0,-1
    800053ca:	74aa                	ld	s1,168(sp)
    800053cc:	bf5d                	j	80005382 <sys_open+0xc8>
    iunlockput(ip);
    800053ce:	8526                	mv	a0,s1
    800053d0:	bd8fe0ef          	jal	800037a8 <iunlockput>
    end_op();
    800053d4:	c1ffe0ef          	jal	80003ff2 <end_op>
    return -1;
    800053d8:	557d                	li	a0,-1
    800053da:	74aa                	ld	s1,168(sp)
    800053dc:	b75d                	j	80005382 <sys_open+0xc8>
      fileclose(f);
    800053de:	854a                	mv	a0,s2
    800053e0:	fb5fe0ef          	jal	80004394 <fileclose>
    800053e4:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    800053e6:	8526                	mv	a0,s1
    800053e8:	bc0fe0ef          	jal	800037a8 <iunlockput>
    end_op();
    800053ec:	c07fe0ef          	jal	80003ff2 <end_op>
    return -1;
    800053f0:	557d                	li	a0,-1
    800053f2:	74aa                	ld	s1,168(sp)
    800053f4:	790a                	ld	s2,160(sp)
    800053f6:	b771                	j	80005382 <sys_open+0xc8>
    f->type = FD_DEVICE;
    800053f8:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800053fc:	04649783          	lh	a5,70(s1)
    80005400:	02f91223          	sh	a5,36(s2)
    80005404:	bf3d                	j	80005342 <sys_open+0x88>
    itrunc(ip);
    80005406:	8526                	mv	a0,s1
    80005408:	a84fe0ef          	jal	8000368c <itrunc>
    8000540c:	b795                	j	80005370 <sys_open+0xb6>

000000008000540e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000540e:	7175                	addi	sp,sp,-144
    80005410:	e506                	sd	ra,136(sp)
    80005412:	e122                	sd	s0,128(sp)
    80005414:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005416:	b73fe0ef          	jal	80003f88 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000541a:	08000613          	li	a2,128
    8000541e:	f7040593          	addi	a1,s0,-144
    80005422:	4501                	li	a0,0
    80005424:	da0fd0ef          	jal	800029c4 <argstr>
    80005428:	02054363          	bltz	a0,8000544e <sys_mkdir+0x40>
    8000542c:	4681                	li	a3,0
    8000542e:	4601                	li	a2,0
    80005430:	4585                	li	a1,1
    80005432:	f7040513          	addi	a0,s0,-144
    80005436:	96fff0ef          	jal	80004da4 <create>
    8000543a:	c911                	beqz	a0,8000544e <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000543c:	b6cfe0ef          	jal	800037a8 <iunlockput>
  end_op();
    80005440:	bb3fe0ef          	jal	80003ff2 <end_op>
  return 0;
    80005444:	4501                	li	a0,0
}
    80005446:	60aa                	ld	ra,136(sp)
    80005448:	640a                	ld	s0,128(sp)
    8000544a:	6149                	addi	sp,sp,144
    8000544c:	8082                	ret
    end_op();
    8000544e:	ba5fe0ef          	jal	80003ff2 <end_op>
    return -1;
    80005452:	557d                	li	a0,-1
    80005454:	bfcd                	j	80005446 <sys_mkdir+0x38>

0000000080005456 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005456:	7135                	addi	sp,sp,-160
    80005458:	ed06                	sd	ra,152(sp)
    8000545a:	e922                	sd	s0,144(sp)
    8000545c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000545e:	b2bfe0ef          	jal	80003f88 <begin_op>
  argint(1, &major);
    80005462:	f6c40593          	addi	a1,s0,-148
    80005466:	4505                	li	a0,1
    80005468:	d24fd0ef          	jal	8000298c <argint>
  argint(2, &minor);
    8000546c:	f6840593          	addi	a1,s0,-152
    80005470:	4509                	li	a0,2
    80005472:	d1afd0ef          	jal	8000298c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005476:	08000613          	li	a2,128
    8000547a:	f7040593          	addi	a1,s0,-144
    8000547e:	4501                	li	a0,0
    80005480:	d44fd0ef          	jal	800029c4 <argstr>
    80005484:	02054563          	bltz	a0,800054ae <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005488:	f6841683          	lh	a3,-152(s0)
    8000548c:	f6c41603          	lh	a2,-148(s0)
    80005490:	458d                	li	a1,3
    80005492:	f7040513          	addi	a0,s0,-144
    80005496:	90fff0ef          	jal	80004da4 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000549a:	c911                	beqz	a0,800054ae <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000549c:	b0cfe0ef          	jal	800037a8 <iunlockput>
  end_op();
    800054a0:	b53fe0ef          	jal	80003ff2 <end_op>
  return 0;
    800054a4:	4501                	li	a0,0
}
    800054a6:	60ea                	ld	ra,152(sp)
    800054a8:	644a                	ld	s0,144(sp)
    800054aa:	610d                	addi	sp,sp,160
    800054ac:	8082                	ret
    end_op();
    800054ae:	b45fe0ef          	jal	80003ff2 <end_op>
    return -1;
    800054b2:	557d                	li	a0,-1
    800054b4:	bfcd                	j	800054a6 <sys_mknod+0x50>

00000000800054b6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800054b6:	7135                	addi	sp,sp,-160
    800054b8:	ed06                	sd	ra,152(sp)
    800054ba:	e922                	sd	s0,144(sp)
    800054bc:	e14a                	sd	s2,128(sp)
    800054be:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800054c0:	c50fc0ef          	jal	80001910 <myproc>
    800054c4:	892a                	mv	s2,a0
  
  begin_op();
    800054c6:	ac3fe0ef          	jal	80003f88 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800054ca:	08000613          	li	a2,128
    800054ce:	f6040593          	addi	a1,s0,-160
    800054d2:	4501                	li	a0,0
    800054d4:	cf0fd0ef          	jal	800029c4 <argstr>
    800054d8:	04054363          	bltz	a0,8000551e <sys_chdir+0x68>
    800054dc:	e526                	sd	s1,136(sp)
    800054de:	f6040513          	addi	a0,s0,-160
    800054e2:	8d3fe0ef          	jal	80003db4 <namei>
    800054e6:	84aa                	mv	s1,a0
    800054e8:	c915                	beqz	a0,8000551c <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    800054ea:	8b4fe0ef          	jal	8000359e <ilock>
  if(ip->type != T_DIR){
    800054ee:	04449703          	lh	a4,68(s1)
    800054f2:	4785                	li	a5,1
    800054f4:	02f71963          	bne	a4,a5,80005526 <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800054f8:	8526                	mv	a0,s1
    800054fa:	952fe0ef          	jal	8000364c <iunlock>
  iput(p->cwd);
    800054fe:	15093503          	ld	a0,336(s2)
    80005502:	a1efe0ef          	jal	80003720 <iput>
  end_op();
    80005506:	aedfe0ef          	jal	80003ff2 <end_op>
  p->cwd = ip;
    8000550a:	14993823          	sd	s1,336(s2)
  return 0;
    8000550e:	4501                	li	a0,0
    80005510:	64aa                	ld	s1,136(sp)
}
    80005512:	60ea                	ld	ra,152(sp)
    80005514:	644a                	ld	s0,144(sp)
    80005516:	690a                	ld	s2,128(sp)
    80005518:	610d                	addi	sp,sp,160
    8000551a:	8082                	ret
    8000551c:	64aa                	ld	s1,136(sp)
    end_op();
    8000551e:	ad5fe0ef          	jal	80003ff2 <end_op>
    return -1;
    80005522:	557d                	li	a0,-1
    80005524:	b7fd                	j	80005512 <sys_chdir+0x5c>
    iunlockput(ip);
    80005526:	8526                	mv	a0,s1
    80005528:	a80fe0ef          	jal	800037a8 <iunlockput>
    end_op();
    8000552c:	ac7fe0ef          	jal	80003ff2 <end_op>
    return -1;
    80005530:	557d                	li	a0,-1
    80005532:	64aa                	ld	s1,136(sp)
    80005534:	bff9                	j	80005512 <sys_chdir+0x5c>

0000000080005536 <sys_exec>:

uint64
sys_exec(void)
{
    80005536:	7121                	addi	sp,sp,-448
    80005538:	ff06                	sd	ra,440(sp)
    8000553a:	fb22                	sd	s0,432(sp)
    8000553c:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000553e:	e4840593          	addi	a1,s0,-440
    80005542:	4505                	li	a0,1
    80005544:	c64fd0ef          	jal	800029a8 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005548:	08000613          	li	a2,128
    8000554c:	f5040593          	addi	a1,s0,-176
    80005550:	4501                	li	a0,0
    80005552:	c72fd0ef          	jal	800029c4 <argstr>
    80005556:	87aa                	mv	a5,a0
    return -1;
    80005558:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000555a:	0c07c463          	bltz	a5,80005622 <sys_exec+0xec>
    8000555e:	f726                	sd	s1,424(sp)
    80005560:	f34a                	sd	s2,416(sp)
    80005562:	ef4e                	sd	s3,408(sp)
    80005564:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    80005566:	10000613          	li	a2,256
    8000556a:	4581                	li	a1,0
    8000556c:	e5040513          	addi	a0,s0,-432
    80005570:	f74fb0ef          	jal	80000ce4 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005574:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005578:	89a6                	mv	s3,s1
    8000557a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000557c:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005580:	00391513          	slli	a0,s2,0x3
    80005584:	e4040593          	addi	a1,s0,-448
    80005588:	e4843783          	ld	a5,-440(s0)
    8000558c:	953e                	add	a0,a0,a5
    8000558e:	b74fd0ef          	jal	80002902 <fetchaddr>
    80005592:	02054663          	bltz	a0,800055be <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    80005596:	e4043783          	ld	a5,-448(s0)
    8000559a:	c3a9                	beqz	a5,800055dc <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000559c:	d62fb0ef          	jal	80000afe <kalloc>
    800055a0:	85aa                	mv	a1,a0
    800055a2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800055a6:	cd01                	beqz	a0,800055be <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800055a8:	6605                	lui	a2,0x1
    800055aa:	e4043503          	ld	a0,-448(s0)
    800055ae:	b9efd0ef          	jal	8000294c <fetchstr>
    800055b2:	00054663          	bltz	a0,800055be <sys_exec+0x88>
    if(i >= NELEM(argv)){
    800055b6:	0905                	addi	s2,s2,1
    800055b8:	09a1                	addi	s3,s3,8
    800055ba:	fd4913e3          	bne	s2,s4,80005580 <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800055be:	f5040913          	addi	s2,s0,-176
    800055c2:	6088                	ld	a0,0(s1)
    800055c4:	c931                	beqz	a0,80005618 <sys_exec+0xe2>
    kfree(argv[i]);
    800055c6:	c56fb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800055ca:	04a1                	addi	s1,s1,8
    800055cc:	ff249be3          	bne	s1,s2,800055c2 <sys_exec+0x8c>
  return -1;
    800055d0:	557d                	li	a0,-1
    800055d2:	74ba                	ld	s1,424(sp)
    800055d4:	791a                	ld	s2,416(sp)
    800055d6:	69fa                	ld	s3,408(sp)
    800055d8:	6a5a                	ld	s4,400(sp)
    800055da:	a0a1                	j	80005622 <sys_exec+0xec>
      argv[i] = 0;
    800055dc:	0009079b          	sext.w	a5,s2
    800055e0:	078e                	slli	a5,a5,0x3
    800055e2:	fd078793          	addi	a5,a5,-48
    800055e6:	97a2                	add	a5,a5,s0
    800055e8:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    800055ec:	e5040593          	addi	a1,s0,-432
    800055f0:	f5040513          	addi	a0,s0,-176
    800055f4:	ba8ff0ef          	jal	8000499c <kexec>
    800055f8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800055fa:	f5040993          	addi	s3,s0,-176
    800055fe:	6088                	ld	a0,0(s1)
    80005600:	c511                	beqz	a0,8000560c <sys_exec+0xd6>
    kfree(argv[i]);
    80005602:	c1afb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005606:	04a1                	addi	s1,s1,8
    80005608:	ff349be3          	bne	s1,s3,800055fe <sys_exec+0xc8>
  return ret;
    8000560c:	854a                	mv	a0,s2
    8000560e:	74ba                	ld	s1,424(sp)
    80005610:	791a                	ld	s2,416(sp)
    80005612:	69fa                	ld	s3,408(sp)
    80005614:	6a5a                	ld	s4,400(sp)
    80005616:	a031                	j	80005622 <sys_exec+0xec>
  return -1;
    80005618:	557d                	li	a0,-1
    8000561a:	74ba                	ld	s1,424(sp)
    8000561c:	791a                	ld	s2,416(sp)
    8000561e:	69fa                	ld	s3,408(sp)
    80005620:	6a5a                	ld	s4,400(sp)
}
    80005622:	70fa                	ld	ra,440(sp)
    80005624:	745a                	ld	s0,432(sp)
    80005626:	6139                	addi	sp,sp,448
    80005628:	8082                	ret

000000008000562a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000562a:	7139                	addi	sp,sp,-64
    8000562c:	fc06                	sd	ra,56(sp)
    8000562e:	f822                	sd	s0,48(sp)
    80005630:	f426                	sd	s1,40(sp)
    80005632:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005634:	adcfc0ef          	jal	80001910 <myproc>
    80005638:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000563a:	fd840593          	addi	a1,s0,-40
    8000563e:	4501                	li	a0,0
    80005640:	b68fd0ef          	jal	800029a8 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005644:	fc840593          	addi	a1,s0,-56
    80005648:	fd040513          	addi	a0,s0,-48
    8000564c:	852ff0ef          	jal	8000469e <pipealloc>
    return -1;
    80005650:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005652:	0a054463          	bltz	a0,800056fa <sys_pipe+0xd0>
  fd0 = -1;
    80005656:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000565a:	fd043503          	ld	a0,-48(s0)
    8000565e:	f08ff0ef          	jal	80004d66 <fdalloc>
    80005662:	fca42223          	sw	a0,-60(s0)
    80005666:	08054163          	bltz	a0,800056e8 <sys_pipe+0xbe>
    8000566a:	fc843503          	ld	a0,-56(s0)
    8000566e:	ef8ff0ef          	jal	80004d66 <fdalloc>
    80005672:	fca42023          	sw	a0,-64(s0)
    80005676:	06054063          	bltz	a0,800056d6 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000567a:	4691                	li	a3,4
    8000567c:	fc440613          	addi	a2,s0,-60
    80005680:	fd843583          	ld	a1,-40(s0)
    80005684:	68a8                	ld	a0,80(s1)
    80005686:	f9ffb0ef          	jal	80001624 <copyout>
    8000568a:	00054e63          	bltz	a0,800056a6 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000568e:	4691                	li	a3,4
    80005690:	fc040613          	addi	a2,s0,-64
    80005694:	fd843583          	ld	a1,-40(s0)
    80005698:	0591                	addi	a1,a1,4
    8000569a:	68a8                	ld	a0,80(s1)
    8000569c:	f89fb0ef          	jal	80001624 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800056a0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800056a2:	04055c63          	bgez	a0,800056fa <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    800056a6:	fc442783          	lw	a5,-60(s0)
    800056aa:	07e9                	addi	a5,a5,26
    800056ac:	078e                	slli	a5,a5,0x3
    800056ae:	97a6                	add	a5,a5,s1
    800056b0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800056b4:	fc042783          	lw	a5,-64(s0)
    800056b8:	07e9                	addi	a5,a5,26
    800056ba:	078e                	slli	a5,a5,0x3
    800056bc:	94be                	add	s1,s1,a5
    800056be:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800056c2:	fd043503          	ld	a0,-48(s0)
    800056c6:	ccffe0ef          	jal	80004394 <fileclose>
    fileclose(wf);
    800056ca:	fc843503          	ld	a0,-56(s0)
    800056ce:	cc7fe0ef          	jal	80004394 <fileclose>
    return -1;
    800056d2:	57fd                	li	a5,-1
    800056d4:	a01d                	j	800056fa <sys_pipe+0xd0>
    if(fd0 >= 0)
    800056d6:	fc442783          	lw	a5,-60(s0)
    800056da:	0007c763          	bltz	a5,800056e8 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    800056de:	07e9                	addi	a5,a5,26
    800056e0:	078e                	slli	a5,a5,0x3
    800056e2:	97a6                	add	a5,a5,s1
    800056e4:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800056e8:	fd043503          	ld	a0,-48(s0)
    800056ec:	ca9fe0ef          	jal	80004394 <fileclose>
    fileclose(wf);
    800056f0:	fc843503          	ld	a0,-56(s0)
    800056f4:	ca1fe0ef          	jal	80004394 <fileclose>
    return -1;
    800056f8:	57fd                	li	a5,-1
}
    800056fa:	853e                	mv	a0,a5
    800056fc:	70e2                	ld	ra,56(sp)
    800056fe:	7442                	ld	s0,48(sp)
    80005700:	74a2                	ld	s1,40(sp)
    80005702:	6121                	addi	sp,sp,64
    80005704:	8082                	ret
	...

0000000080005710 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005710:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005712:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005714:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005716:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005718:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000571a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000571c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000571e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005720:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005722:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005724:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005726:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005728:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000572a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000572c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000572e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80005730:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80005732:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80005734:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    80005736:	8dcfd0ef          	jal	80002812 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    8000573a:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    8000573c:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    8000573e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80005740:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80005742:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    80005744:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    80005746:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    80005748:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    8000574a:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    8000574c:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    8000574e:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80005750:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80005752:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    80005754:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80005756:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80005758:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    8000575a:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    8000575c:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    8000575e:	10200073          	sret
	...

000000008000576e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000576e:	1141                	addi	sp,sp,-16
    80005770:	e422                	sd	s0,8(sp)
    80005772:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005774:	0c0007b7          	lui	a5,0xc000
    80005778:	4705                	li	a4,1
    8000577a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000577c:	0c0007b7          	lui	a5,0xc000
    80005780:	c3d8                	sw	a4,4(a5)
}
    80005782:	6422                	ld	s0,8(sp)
    80005784:	0141                	addi	sp,sp,16
    80005786:	8082                	ret

0000000080005788 <plicinithart>:

void
plicinithart(void)
{
    80005788:	1141                	addi	sp,sp,-16
    8000578a:	e406                	sd	ra,8(sp)
    8000578c:	e022                	sd	s0,0(sp)
    8000578e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005790:	954fc0ef          	jal	800018e4 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005794:	0085171b          	slliw	a4,a0,0x8
    80005798:	0c0027b7          	lui	a5,0xc002
    8000579c:	97ba                	add	a5,a5,a4
    8000579e:	40200713          	li	a4,1026
    800057a2:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800057a6:	00d5151b          	slliw	a0,a0,0xd
    800057aa:	0c2017b7          	lui	a5,0xc201
    800057ae:	97aa                	add	a5,a5,a0
    800057b0:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800057b4:	60a2                	ld	ra,8(sp)
    800057b6:	6402                	ld	s0,0(sp)
    800057b8:	0141                	addi	sp,sp,16
    800057ba:	8082                	ret

00000000800057bc <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800057bc:	1141                	addi	sp,sp,-16
    800057be:	e406                	sd	ra,8(sp)
    800057c0:	e022                	sd	s0,0(sp)
    800057c2:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800057c4:	920fc0ef          	jal	800018e4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800057c8:	00d5151b          	slliw	a0,a0,0xd
    800057cc:	0c2017b7          	lui	a5,0xc201
    800057d0:	97aa                	add	a5,a5,a0
  return irq;
}
    800057d2:	43c8                	lw	a0,4(a5)
    800057d4:	60a2                	ld	ra,8(sp)
    800057d6:	6402                	ld	s0,0(sp)
    800057d8:	0141                	addi	sp,sp,16
    800057da:	8082                	ret

00000000800057dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800057dc:	1101                	addi	sp,sp,-32
    800057de:	ec06                	sd	ra,24(sp)
    800057e0:	e822                	sd	s0,16(sp)
    800057e2:	e426                	sd	s1,8(sp)
    800057e4:	1000                	addi	s0,sp,32
    800057e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800057e8:	8fcfc0ef          	jal	800018e4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800057ec:	00d5151b          	slliw	a0,a0,0xd
    800057f0:	0c2017b7          	lui	a5,0xc201
    800057f4:	97aa                	add	a5,a5,a0
    800057f6:	c3c4                	sw	s1,4(a5)
}
    800057f8:	60e2                	ld	ra,24(sp)
    800057fa:	6442                	ld	s0,16(sp)
    800057fc:	64a2                	ld	s1,8(sp)
    800057fe:	6105                	addi	sp,sp,32
    80005800:	8082                	ret

0000000080005802 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005802:	1141                	addi	sp,sp,-16
    80005804:	e406                	sd	ra,8(sp)
    80005806:	e022                	sd	s0,0(sp)
    80005808:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000580a:	479d                	li	a5,7
    8000580c:	04a7ca63          	blt	a5,a0,80005860 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    80005810:	0001f797          	auipc	a5,0x1f
    80005814:	12878793          	addi	a5,a5,296 # 80024938 <disk>
    80005818:	97aa                	add	a5,a5,a0
    8000581a:	0187c783          	lbu	a5,24(a5)
    8000581e:	e7b9                	bnez	a5,8000586c <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005820:	00451693          	slli	a3,a0,0x4
    80005824:	0001f797          	auipc	a5,0x1f
    80005828:	11478793          	addi	a5,a5,276 # 80024938 <disk>
    8000582c:	6398                	ld	a4,0(a5)
    8000582e:	9736                	add	a4,a4,a3
    80005830:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005834:	6398                	ld	a4,0(a5)
    80005836:	9736                	add	a4,a4,a3
    80005838:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    8000583c:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005840:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005844:	97aa                	add	a5,a5,a0
    80005846:	4705                	li	a4,1
    80005848:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    8000584c:	0001f517          	auipc	a0,0x1f
    80005850:	10450513          	addi	a0,a0,260 # 80024950 <disk+0x18>
    80005854:	f92fc0ef          	jal	80001fe6 <wakeup>
}
    80005858:	60a2                	ld	ra,8(sp)
    8000585a:	6402                	ld	s0,0(sp)
    8000585c:	0141                	addi	sp,sp,16
    8000585e:	8082                	ret
    panic("free_desc 1");
    80005860:	00002517          	auipc	a0,0x2
    80005864:	eb850513          	addi	a0,a0,-328 # 80007718 <etext+0x718>
    80005868:	f79fa0ef          	jal	800007e0 <panic>
    panic("free_desc 2");
    8000586c:	00002517          	auipc	a0,0x2
    80005870:	ebc50513          	addi	a0,a0,-324 # 80007728 <etext+0x728>
    80005874:	f6dfa0ef          	jal	800007e0 <panic>

0000000080005878 <virtio_disk_init>:
{
    80005878:	1101                	addi	sp,sp,-32
    8000587a:	ec06                	sd	ra,24(sp)
    8000587c:	e822                	sd	s0,16(sp)
    8000587e:	e426                	sd	s1,8(sp)
    80005880:	e04a                	sd	s2,0(sp)
    80005882:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005884:	00002597          	auipc	a1,0x2
    80005888:	eb458593          	addi	a1,a1,-332 # 80007738 <etext+0x738>
    8000588c:	0001f517          	auipc	a0,0x1f
    80005890:	1d450513          	addi	a0,a0,468 # 80024a60 <disk+0x128>
    80005894:	afcfb0ef          	jal	80000b90 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005898:	100017b7          	lui	a5,0x10001
    8000589c:	4398                	lw	a4,0(a5)
    8000589e:	2701                	sext.w	a4,a4
    800058a0:	747277b7          	lui	a5,0x74727
    800058a4:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800058a8:	18f71063          	bne	a4,a5,80005a28 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800058ac:	100017b7          	lui	a5,0x10001
    800058b0:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    800058b2:	439c                	lw	a5,0(a5)
    800058b4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800058b6:	4709                	li	a4,2
    800058b8:	16e79863          	bne	a5,a4,80005a28 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800058bc:	100017b7          	lui	a5,0x10001
    800058c0:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    800058c2:	439c                	lw	a5,0(a5)
    800058c4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800058c6:	16e79163          	bne	a5,a4,80005a28 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800058ca:	100017b7          	lui	a5,0x10001
    800058ce:	47d8                	lw	a4,12(a5)
    800058d0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800058d2:	554d47b7          	lui	a5,0x554d4
    800058d6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800058da:	14f71763          	bne	a4,a5,80005a28 <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    800058de:	100017b7          	lui	a5,0x10001
    800058e2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800058e6:	4705                	li	a4,1
    800058e8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800058ea:	470d                	li	a4,3
    800058ec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800058ee:	10001737          	lui	a4,0x10001
    800058f2:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800058f4:	c7ffe737          	lui	a4,0xc7ffe
    800058f8:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd9ce7>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800058fc:	8ef9                	and	a3,a3,a4
    800058fe:	10001737          	lui	a4,0x10001
    80005902:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005904:	472d                	li	a4,11
    80005906:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005908:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    8000590c:	439c                	lw	a5,0(a5)
    8000590e:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005912:	8ba1                	andi	a5,a5,8
    80005914:	12078063          	beqz	a5,80005a34 <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005918:	100017b7          	lui	a5,0x10001
    8000591c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005920:	100017b7          	lui	a5,0x10001
    80005924:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    80005928:	439c                	lw	a5,0(a5)
    8000592a:	2781                	sext.w	a5,a5
    8000592c:	10079a63          	bnez	a5,80005a40 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005930:	100017b7          	lui	a5,0x10001
    80005934:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    80005938:	439c                	lw	a5,0(a5)
    8000593a:	2781                	sext.w	a5,a5
  if(max == 0)
    8000593c:	10078863          	beqz	a5,80005a4c <virtio_disk_init+0x1d4>
  if(max < NUM)
    80005940:	471d                	li	a4,7
    80005942:	10f77b63          	bgeu	a4,a5,80005a58 <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    80005946:	9b8fb0ef          	jal	80000afe <kalloc>
    8000594a:	0001f497          	auipc	s1,0x1f
    8000594e:	fee48493          	addi	s1,s1,-18 # 80024938 <disk>
    80005952:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005954:	9aafb0ef          	jal	80000afe <kalloc>
    80005958:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000595a:	9a4fb0ef          	jal	80000afe <kalloc>
    8000595e:	87aa                	mv	a5,a0
    80005960:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005962:	6088                	ld	a0,0(s1)
    80005964:	10050063          	beqz	a0,80005a64 <virtio_disk_init+0x1ec>
    80005968:	0001f717          	auipc	a4,0x1f
    8000596c:	fd873703          	ld	a4,-40(a4) # 80024940 <disk+0x8>
    80005970:	0e070a63          	beqz	a4,80005a64 <virtio_disk_init+0x1ec>
    80005974:	0e078863          	beqz	a5,80005a64 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    80005978:	6605                	lui	a2,0x1
    8000597a:	4581                	li	a1,0
    8000597c:	b68fb0ef          	jal	80000ce4 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005980:	0001f497          	auipc	s1,0x1f
    80005984:	fb848493          	addi	s1,s1,-72 # 80024938 <disk>
    80005988:	6605                	lui	a2,0x1
    8000598a:	4581                	li	a1,0
    8000598c:	6488                	ld	a0,8(s1)
    8000598e:	b56fb0ef          	jal	80000ce4 <memset>
  memset(disk.used, 0, PGSIZE);
    80005992:	6605                	lui	a2,0x1
    80005994:	4581                	li	a1,0
    80005996:	6888                	ld	a0,16(s1)
    80005998:	b4cfb0ef          	jal	80000ce4 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000599c:	100017b7          	lui	a5,0x10001
    800059a0:	4721                	li	a4,8
    800059a2:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800059a4:	4098                	lw	a4,0(s1)
    800059a6:	100017b7          	lui	a5,0x10001
    800059aa:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800059ae:	40d8                	lw	a4,4(s1)
    800059b0:	100017b7          	lui	a5,0x10001
    800059b4:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800059b8:	649c                	ld	a5,8(s1)
    800059ba:	0007869b          	sext.w	a3,a5
    800059be:	10001737          	lui	a4,0x10001
    800059c2:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800059c6:	9781                	srai	a5,a5,0x20
    800059c8:	10001737          	lui	a4,0x10001
    800059cc:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800059d0:	689c                	ld	a5,16(s1)
    800059d2:	0007869b          	sext.w	a3,a5
    800059d6:	10001737          	lui	a4,0x10001
    800059da:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800059de:	9781                	srai	a5,a5,0x20
    800059e0:	10001737          	lui	a4,0x10001
    800059e4:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800059e8:	10001737          	lui	a4,0x10001
    800059ec:	4785                	li	a5,1
    800059ee:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    800059f0:	00f48c23          	sb	a5,24(s1)
    800059f4:	00f48ca3          	sb	a5,25(s1)
    800059f8:	00f48d23          	sb	a5,26(s1)
    800059fc:	00f48da3          	sb	a5,27(s1)
    80005a00:	00f48e23          	sb	a5,28(s1)
    80005a04:	00f48ea3          	sb	a5,29(s1)
    80005a08:	00f48f23          	sb	a5,30(s1)
    80005a0c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005a10:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005a14:	100017b7          	lui	a5,0x10001
    80005a18:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    80005a1c:	60e2                	ld	ra,24(sp)
    80005a1e:	6442                	ld	s0,16(sp)
    80005a20:	64a2                	ld	s1,8(sp)
    80005a22:	6902                	ld	s2,0(sp)
    80005a24:	6105                	addi	sp,sp,32
    80005a26:	8082                	ret
    panic("could not find virtio disk");
    80005a28:	00002517          	auipc	a0,0x2
    80005a2c:	d2050513          	addi	a0,a0,-736 # 80007748 <etext+0x748>
    80005a30:	db1fa0ef          	jal	800007e0 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005a34:	00002517          	auipc	a0,0x2
    80005a38:	d3450513          	addi	a0,a0,-716 # 80007768 <etext+0x768>
    80005a3c:	da5fa0ef          	jal	800007e0 <panic>
    panic("virtio disk should not be ready");
    80005a40:	00002517          	auipc	a0,0x2
    80005a44:	d4850513          	addi	a0,a0,-696 # 80007788 <etext+0x788>
    80005a48:	d99fa0ef          	jal	800007e0 <panic>
    panic("virtio disk has no queue 0");
    80005a4c:	00002517          	auipc	a0,0x2
    80005a50:	d5c50513          	addi	a0,a0,-676 # 800077a8 <etext+0x7a8>
    80005a54:	d8dfa0ef          	jal	800007e0 <panic>
    panic("virtio disk max queue too short");
    80005a58:	00002517          	auipc	a0,0x2
    80005a5c:	d7050513          	addi	a0,a0,-656 # 800077c8 <etext+0x7c8>
    80005a60:	d81fa0ef          	jal	800007e0 <panic>
    panic("virtio disk kalloc");
    80005a64:	00002517          	auipc	a0,0x2
    80005a68:	d8450513          	addi	a0,a0,-636 # 800077e8 <etext+0x7e8>
    80005a6c:	d75fa0ef          	jal	800007e0 <panic>

0000000080005a70 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005a70:	7159                	addi	sp,sp,-112
    80005a72:	f486                	sd	ra,104(sp)
    80005a74:	f0a2                	sd	s0,96(sp)
    80005a76:	eca6                	sd	s1,88(sp)
    80005a78:	e8ca                	sd	s2,80(sp)
    80005a7a:	e4ce                	sd	s3,72(sp)
    80005a7c:	e0d2                	sd	s4,64(sp)
    80005a7e:	fc56                	sd	s5,56(sp)
    80005a80:	f85a                	sd	s6,48(sp)
    80005a82:	f45e                	sd	s7,40(sp)
    80005a84:	f062                	sd	s8,32(sp)
    80005a86:	ec66                	sd	s9,24(sp)
    80005a88:	1880                	addi	s0,sp,112
    80005a8a:	8a2a                	mv	s4,a0
    80005a8c:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005a8e:	00c52c83          	lw	s9,12(a0)
    80005a92:	001c9c9b          	slliw	s9,s9,0x1
    80005a96:	1c82                	slli	s9,s9,0x20
    80005a98:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005a9c:	0001f517          	auipc	a0,0x1f
    80005aa0:	fc450513          	addi	a0,a0,-60 # 80024a60 <disk+0x128>
    80005aa4:	96cfb0ef          	jal	80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    80005aa8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005aaa:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005aac:	0001fb17          	auipc	s6,0x1f
    80005ab0:	e8cb0b13          	addi	s6,s6,-372 # 80024938 <disk>
  for(int i = 0; i < 3; i++){
    80005ab4:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ab6:	0001fc17          	auipc	s8,0x1f
    80005aba:	faac0c13          	addi	s8,s8,-86 # 80024a60 <disk+0x128>
    80005abe:	a8b9                	j	80005b1c <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005ac0:	00fb0733          	add	a4,s6,a5
    80005ac4:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80005ac8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005aca:	0207c563          	bltz	a5,80005af4 <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    80005ace:	2905                	addiw	s2,s2,1
    80005ad0:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005ad2:	05590963          	beq	s2,s5,80005b24 <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    80005ad6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005ad8:	0001f717          	auipc	a4,0x1f
    80005adc:	e6070713          	addi	a4,a4,-416 # 80024938 <disk>
    80005ae0:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005ae2:	01874683          	lbu	a3,24(a4)
    80005ae6:	fee9                	bnez	a3,80005ac0 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80005ae8:	2785                	addiw	a5,a5,1
    80005aea:	0705                	addi	a4,a4,1
    80005aec:	fe979be3          	bne	a5,s1,80005ae2 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    80005af0:	57fd                	li	a5,-1
    80005af2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005af4:	01205d63          	blez	s2,80005b0e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005af8:	f9042503          	lw	a0,-112(s0)
    80005afc:	d07ff0ef          	jal	80005802 <free_desc>
      for(int j = 0; j < i; j++)
    80005b00:	4785                	li	a5,1
    80005b02:	0127d663          	bge	a5,s2,80005b0e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005b06:	f9442503          	lw	a0,-108(s0)
    80005b0a:	cf9ff0ef          	jal	80005802 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005b0e:	85e2                	mv	a1,s8
    80005b10:	0001f517          	auipc	a0,0x1f
    80005b14:	e4050513          	addi	a0,a0,-448 # 80024950 <disk+0x18>
    80005b18:	c82fc0ef          	jal	80001f9a <sleep>
  for(int i = 0; i < 3; i++){
    80005b1c:	f9040613          	addi	a2,s0,-112
    80005b20:	894e                	mv	s2,s3
    80005b22:	bf55                	j	80005ad6 <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005b24:	f9042503          	lw	a0,-112(s0)
    80005b28:	00451693          	slli	a3,a0,0x4

  if(write)
    80005b2c:	0001f797          	auipc	a5,0x1f
    80005b30:	e0c78793          	addi	a5,a5,-500 # 80024938 <disk>
    80005b34:	00a50713          	addi	a4,a0,10
    80005b38:	0712                	slli	a4,a4,0x4
    80005b3a:	973e                	add	a4,a4,a5
    80005b3c:	01703633          	snez	a2,s7
    80005b40:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005b42:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005b46:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005b4a:	6398                	ld	a4,0(a5)
    80005b4c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005b4e:	0a868613          	addi	a2,a3,168
    80005b52:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005b54:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005b56:	6390                	ld	a2,0(a5)
    80005b58:	00d605b3          	add	a1,a2,a3
    80005b5c:	4741                	li	a4,16
    80005b5e:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005b60:	4805                	li	a6,1
    80005b62:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    80005b66:	f9442703          	lw	a4,-108(s0)
    80005b6a:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005b6e:	0712                	slli	a4,a4,0x4
    80005b70:	963a                	add	a2,a2,a4
    80005b72:	058a0593          	addi	a1,s4,88
    80005b76:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005b78:	0007b883          	ld	a7,0(a5)
    80005b7c:	9746                	add	a4,a4,a7
    80005b7e:	40000613          	li	a2,1024
    80005b82:	c710                	sw	a2,8(a4)
  if(write)
    80005b84:	001bb613          	seqz	a2,s7
    80005b88:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005b8c:	00166613          	ori	a2,a2,1
    80005b90:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80005b94:	f9842583          	lw	a1,-104(s0)
    80005b98:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005b9c:	00250613          	addi	a2,a0,2
    80005ba0:	0612                	slli	a2,a2,0x4
    80005ba2:	963e                	add	a2,a2,a5
    80005ba4:	577d                	li	a4,-1
    80005ba6:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005baa:	0592                	slli	a1,a1,0x4
    80005bac:	98ae                	add	a7,a7,a1
    80005bae:	03068713          	addi	a4,a3,48
    80005bb2:	973e                	add	a4,a4,a5
    80005bb4:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80005bb8:	6398                	ld	a4,0(a5)
    80005bba:	972e                	add	a4,a4,a1
    80005bbc:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005bc0:	4689                	li	a3,2
    80005bc2:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80005bc6:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005bca:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80005bce:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005bd2:	6794                	ld	a3,8(a5)
    80005bd4:	0026d703          	lhu	a4,2(a3)
    80005bd8:	8b1d                	andi	a4,a4,7
    80005bda:	0706                	slli	a4,a4,0x1
    80005bdc:	96ba                	add	a3,a3,a4
    80005bde:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005be2:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005be6:	6798                	ld	a4,8(a5)
    80005be8:	00275783          	lhu	a5,2(a4)
    80005bec:	2785                	addiw	a5,a5,1
    80005bee:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005bf2:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005bf6:	100017b7          	lui	a5,0x10001
    80005bfa:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005bfe:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80005c02:	0001f917          	auipc	s2,0x1f
    80005c06:	e5e90913          	addi	s2,s2,-418 # 80024a60 <disk+0x128>
  while(b->disk == 1) {
    80005c0a:	4485                	li	s1,1
    80005c0c:	01079a63          	bne	a5,a6,80005c20 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    80005c10:	85ca                	mv	a1,s2
    80005c12:	8552                	mv	a0,s4
    80005c14:	b86fc0ef          	jal	80001f9a <sleep>
  while(b->disk == 1) {
    80005c18:	004a2783          	lw	a5,4(s4)
    80005c1c:	fe978ae3          	beq	a5,s1,80005c10 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    80005c20:	f9042903          	lw	s2,-112(s0)
    80005c24:	00290713          	addi	a4,s2,2
    80005c28:	0712                	slli	a4,a4,0x4
    80005c2a:	0001f797          	auipc	a5,0x1f
    80005c2e:	d0e78793          	addi	a5,a5,-754 # 80024938 <disk>
    80005c32:	97ba                	add	a5,a5,a4
    80005c34:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80005c38:	0001f997          	auipc	s3,0x1f
    80005c3c:	d0098993          	addi	s3,s3,-768 # 80024938 <disk>
    80005c40:	00491713          	slli	a4,s2,0x4
    80005c44:	0009b783          	ld	a5,0(s3)
    80005c48:	97ba                	add	a5,a5,a4
    80005c4a:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005c4e:	854a                	mv	a0,s2
    80005c50:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005c54:	bafff0ef          	jal	80005802 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005c58:	8885                	andi	s1,s1,1
    80005c5a:	f0fd                	bnez	s1,80005c40 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005c5c:	0001f517          	auipc	a0,0x1f
    80005c60:	e0450513          	addi	a0,a0,-508 # 80024a60 <disk+0x128>
    80005c64:	844fb0ef          	jal	80000ca8 <release>
}
    80005c68:	70a6                	ld	ra,104(sp)
    80005c6a:	7406                	ld	s0,96(sp)
    80005c6c:	64e6                	ld	s1,88(sp)
    80005c6e:	6946                	ld	s2,80(sp)
    80005c70:	69a6                	ld	s3,72(sp)
    80005c72:	6a06                	ld	s4,64(sp)
    80005c74:	7ae2                	ld	s5,56(sp)
    80005c76:	7b42                	ld	s6,48(sp)
    80005c78:	7ba2                	ld	s7,40(sp)
    80005c7a:	7c02                	ld	s8,32(sp)
    80005c7c:	6ce2                	ld	s9,24(sp)
    80005c7e:	6165                	addi	sp,sp,112
    80005c80:	8082                	ret

0000000080005c82 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005c82:	1101                	addi	sp,sp,-32
    80005c84:	ec06                	sd	ra,24(sp)
    80005c86:	e822                	sd	s0,16(sp)
    80005c88:	e426                	sd	s1,8(sp)
    80005c8a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005c8c:	0001f497          	auipc	s1,0x1f
    80005c90:	cac48493          	addi	s1,s1,-852 # 80024938 <disk>
    80005c94:	0001f517          	auipc	a0,0x1f
    80005c98:	dcc50513          	addi	a0,a0,-564 # 80024a60 <disk+0x128>
    80005c9c:	f75fa0ef          	jal	80000c10 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005ca0:	100017b7          	lui	a5,0x10001
    80005ca4:	53b8                	lw	a4,96(a5)
    80005ca6:	8b0d                	andi	a4,a4,3
    80005ca8:	100017b7          	lui	a5,0x10001
    80005cac:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80005cae:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005cb2:	689c                	ld	a5,16(s1)
    80005cb4:	0204d703          	lhu	a4,32(s1)
    80005cb8:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80005cbc:	04f70663          	beq	a4,a5,80005d08 <virtio_disk_intr+0x86>
    __sync_synchronize();
    80005cc0:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005cc4:	6898                	ld	a4,16(s1)
    80005cc6:	0204d783          	lhu	a5,32(s1)
    80005cca:	8b9d                	andi	a5,a5,7
    80005ccc:	078e                	slli	a5,a5,0x3
    80005cce:	97ba                	add	a5,a5,a4
    80005cd0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005cd2:	00278713          	addi	a4,a5,2
    80005cd6:	0712                	slli	a4,a4,0x4
    80005cd8:	9726                	add	a4,a4,s1
    80005cda:	01074703          	lbu	a4,16(a4)
    80005cde:	e321                	bnez	a4,80005d1e <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005ce0:	0789                	addi	a5,a5,2
    80005ce2:	0792                	slli	a5,a5,0x4
    80005ce4:	97a6                	add	a5,a5,s1
    80005ce6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005ce8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005cec:	afafc0ef          	jal	80001fe6 <wakeup>

    disk.used_idx += 1;
    80005cf0:	0204d783          	lhu	a5,32(s1)
    80005cf4:	2785                	addiw	a5,a5,1
    80005cf6:	17c2                	slli	a5,a5,0x30
    80005cf8:	93c1                	srli	a5,a5,0x30
    80005cfa:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005cfe:	6898                	ld	a4,16(s1)
    80005d00:	00275703          	lhu	a4,2(a4)
    80005d04:	faf71ee3          	bne	a4,a5,80005cc0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80005d08:	0001f517          	auipc	a0,0x1f
    80005d0c:	d5850513          	addi	a0,a0,-680 # 80024a60 <disk+0x128>
    80005d10:	f99fa0ef          	jal	80000ca8 <release>
}
    80005d14:	60e2                	ld	ra,24(sp)
    80005d16:	6442                	ld	s0,16(sp)
    80005d18:	64a2                	ld	s1,8(sp)
    80005d1a:	6105                	addi	sp,sp,32
    80005d1c:	8082                	ret
      panic("virtio_disk_intr status");
    80005d1e:	00002517          	auipc	a0,0x2
    80005d22:	ae250513          	addi	a0,a0,-1310 # 80007800 <etext+0x800>
    80005d26:	abbfa0ef          	jal	800007e0 <panic>
	...

0000000080006000 <_trampoline>:
    80006000:	14051073          	csrw	sscratch,a0
    80006004:	02000537          	lui	a0,0x2000
    80006008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000600a:	0536                	slli	a0,a0,0xd
    8000600c:	02153423          	sd	ra,40(a0)
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
    800060ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800060ae:	0536                	slli	a0,a0,0xd
    800060b0:	02853083          	ld	ra,40(a0)
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
