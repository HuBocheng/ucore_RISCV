
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    80200000:	00003117          	auipc	sp,0x3
    80200004:	00010113          	mv	sp,sp

    tail kern_init
    80200008:	a009                	j	8020000a <kern_init>

000000008020000a <kern_init>:
#include <sbi.h>
int kern_init(void) __attribute__((noreturn));

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    8020000a:	00003517          	auipc	a0,0x3
    8020000e:	ffe50513          	addi	a0,a0,-2 # 80203008 <edata>
    80200012:	00003617          	auipc	a2,0x3
    80200016:	ff660613          	addi	a2,a2,-10 # 80203008 <edata>
int kern_init(void) {
    8020001a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001c:	4581                	li	a1,0
    8020001e:	8e09                	sub	a2,a2,a0
int kern_init(void) {
    80200020:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200022:	490000ef          	jal	ra,802004b2 <memset>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    80200026:	00000597          	auipc	a1,0x0
    8020002a:	4a258593          	addi	a1,a1,1186 # 802004c8 <memset+0x16>
    8020002e:	00000517          	auipc	a0,0x0
    80200032:	4ba50513          	addi	a0,a0,1210 # 802004e8 <memset+0x36>
    80200036:	020000ef          	jal	ra,80200056 <cprintf>
   while (1)
    8020003a:	a001                	j	8020003a <kern_init+0x30>

000000008020003c <cputch>:
    8020003c:	1141                	addi	sp,sp,-16
    8020003e:	e022                	sd	s0,0(sp)
    80200040:	e406                	sd	ra,8(sp)
    80200042:	842e                	mv	s0,a1
    80200044:	048000ef          	jal	ra,8020008c <cons_putc>
    80200048:	401c                	lw	a5,0(s0)
    8020004a:	60a2                	ld	ra,8(sp)
    8020004c:	2785                	addiw	a5,a5,1
    8020004e:	c01c                	sw	a5,0(s0)
    80200050:	6402                	ld	s0,0(sp)
    80200052:	0141                	addi	sp,sp,16
    80200054:	8082                	ret

0000000080200056 <cprintf>:
    80200056:	711d                	addi	sp,sp,-96
    80200058:	02810313          	addi	t1,sp,40 # 80203028 <edata+0x20>
    8020005c:	8e2a                	mv	t3,a0
    8020005e:	f42e                	sd	a1,40(sp)
    80200060:	f832                	sd	a2,48(sp)
    80200062:	fc36                	sd	a3,56(sp)
    80200064:	00000517          	auipc	a0,0x0
    80200068:	fd850513          	addi	a0,a0,-40 # 8020003c <cputch>
    8020006c:	004c                	addi	a1,sp,4
    8020006e:	869a                	mv	a3,t1
    80200070:	8672                	mv	a2,t3
    80200072:	ec06                	sd	ra,24(sp)
    80200074:	e0ba                	sd	a4,64(sp)
    80200076:	e4be                	sd	a5,72(sp)
    80200078:	e8c2                	sd	a6,80(sp)
    8020007a:	ecc6                	sd	a7,88(sp)
    8020007c:	e41a                	sd	t1,8(sp)
    8020007e:	c202                	sw	zero,4(sp)
    80200080:	080000ef          	jal	ra,80200100 <vprintfmt>
    80200084:	60e2                	ld	ra,24(sp)
    80200086:	4512                	lw	a0,4(sp)
    80200088:	6125                	addi	sp,sp,96
    8020008a:	8082                	ret

000000008020008c <cons_putc>:
    8020008c:	0ff57513          	andi	a0,a0,255
    80200090:	a6f5                	j	8020047c <sbi_console_putchar>

0000000080200092 <printnum>:
    80200092:	02069813          	slli	a6,a3,0x20
    80200096:	7179                	addi	sp,sp,-48
    80200098:	02085813          	srli	a6,a6,0x20
    8020009c:	e052                	sd	s4,0(sp)
    8020009e:	03067a33          	remu	s4,a2,a6
    802000a2:	f022                	sd	s0,32(sp)
    802000a4:	ec26                	sd	s1,24(sp)
    802000a6:	e84a                	sd	s2,16(sp)
    802000a8:	f406                	sd	ra,40(sp)
    802000aa:	e44e                	sd	s3,8(sp)
    802000ac:	84aa                	mv	s1,a0
    802000ae:	892e                	mv	s2,a1
    802000b0:	fff7041b          	addiw	s0,a4,-1
    802000b4:	2a01                	sext.w	s4,s4
    802000b6:	03067f63          	bgeu	a2,a6,802000f4 <printnum+0x62>
    802000ba:	89be                	mv	s3,a5
    802000bc:	4785                	li	a5,1
    802000be:	00e7d763          	bge	a5,a4,802000cc <printnum+0x3a>
    802000c2:	347d                	addiw	s0,s0,-1
    802000c4:	85ca                	mv	a1,s2
    802000c6:	854e                	mv	a0,s3
    802000c8:	9482                	jalr	s1
    802000ca:	fc65                	bnez	s0,802000c2 <printnum+0x30>
    802000cc:	1a02                	slli	s4,s4,0x20
    802000ce:	020a5a13          	srli	s4,s4,0x20
    802000d2:	00000797          	auipc	a5,0x0
    802000d6:	41e78793          	addi	a5,a5,1054 # 802004f0 <memset+0x3e>
    802000da:	97d2                	add	a5,a5,s4
    802000dc:	7402                	ld	s0,32(sp)
    802000de:	0007c503          	lbu	a0,0(a5)
    802000e2:	70a2                	ld	ra,40(sp)
    802000e4:	69a2                	ld	s3,8(sp)
    802000e6:	6a02                	ld	s4,0(sp)
    802000e8:	85ca                	mv	a1,s2
    802000ea:	87a6                	mv	a5,s1
    802000ec:	6942                	ld	s2,16(sp)
    802000ee:	64e2                	ld	s1,24(sp)
    802000f0:	6145                	addi	sp,sp,48
    802000f2:	8782                	jr	a5
    802000f4:	03065633          	divu	a2,a2,a6
    802000f8:	8722                	mv	a4,s0
    802000fa:	f99ff0ef          	jal	ra,80200092 <printnum>
    802000fe:	b7f9                	j	802000cc <printnum+0x3a>

0000000080200100 <vprintfmt>:
    80200100:	7119                	addi	sp,sp,-128
    80200102:	f4a6                	sd	s1,104(sp)
    80200104:	f0ca                	sd	s2,96(sp)
    80200106:	ecce                	sd	s3,88(sp)
    80200108:	e8d2                	sd	s4,80(sp)
    8020010a:	e4d6                	sd	s5,72(sp)
    8020010c:	e0da                	sd	s6,64(sp)
    8020010e:	f862                	sd	s8,48(sp)
    80200110:	fc86                	sd	ra,120(sp)
    80200112:	f8a2                	sd	s0,112(sp)
    80200114:	fc5e                	sd	s7,56(sp)
    80200116:	f466                	sd	s9,40(sp)
    80200118:	f06a                	sd	s10,32(sp)
    8020011a:	ec6e                	sd	s11,24(sp)
    8020011c:	892a                	mv	s2,a0
    8020011e:	84ae                	mv	s1,a1
    80200120:	8c32                	mv	s8,a2
    80200122:	8a36                	mv	s4,a3
    80200124:	02500993          	li	s3,37
    80200128:	05500b13          	li	s6,85
    8020012c:	00000a97          	auipc	s5,0x0
    80200130:	3f8a8a93          	addi	s5,s5,1016 # 80200524 <memset+0x72>
    80200134:	000c4503          	lbu	a0,0(s8)
    80200138:	001c0413          	addi	s0,s8,1
    8020013c:	01350a63          	beq	a0,s3,80200150 <vprintfmt+0x50>
    80200140:	cd0d                	beqz	a0,8020017a <vprintfmt+0x7a>
    80200142:	85a6                	mv	a1,s1
    80200144:	0405                	addi	s0,s0,1
    80200146:	9902                	jalr	s2
    80200148:	fff44503          	lbu	a0,-1(s0)
    8020014c:	ff351ae3          	bne	a0,s3,80200140 <vprintfmt+0x40>
    80200150:	02000d93          	li	s11,32
    80200154:	4b81                	li	s7,0
    80200156:	4601                	li	a2,0
    80200158:	5d7d                	li	s10,-1
    8020015a:	5cfd                	li	s9,-1
    8020015c:	00044683          	lbu	a3,0(s0)
    80200160:	00140c13          	addi	s8,s0,1
    80200164:	fdd6859b          	addiw	a1,a3,-35
    80200168:	0ff5f593          	andi	a1,a1,255
    8020016c:	02bb6663          	bltu	s6,a1,80200198 <vprintfmt+0x98>
    80200170:	058a                	slli	a1,a1,0x2
    80200172:	95d6                	add	a1,a1,s5
    80200174:	4198                	lw	a4,0(a1)
    80200176:	9756                	add	a4,a4,s5
    80200178:	8702                	jr	a4
    8020017a:	70e6                	ld	ra,120(sp)
    8020017c:	7446                	ld	s0,112(sp)
    8020017e:	74a6                	ld	s1,104(sp)
    80200180:	7906                	ld	s2,96(sp)
    80200182:	69e6                	ld	s3,88(sp)
    80200184:	6a46                	ld	s4,80(sp)
    80200186:	6aa6                	ld	s5,72(sp)
    80200188:	6b06                	ld	s6,64(sp)
    8020018a:	7be2                	ld	s7,56(sp)
    8020018c:	7c42                	ld	s8,48(sp)
    8020018e:	7ca2                	ld	s9,40(sp)
    80200190:	7d02                	ld	s10,32(sp)
    80200192:	6de2                	ld	s11,24(sp)
    80200194:	6109                	addi	sp,sp,128
    80200196:	8082                	ret
    80200198:	85a6                	mv	a1,s1
    8020019a:	02500513          	li	a0,37
    8020019e:	9902                	jalr	s2
    802001a0:	fff44703          	lbu	a4,-1(s0)
    802001a4:	02500793          	li	a5,37
    802001a8:	8c22                	mv	s8,s0
    802001aa:	f8f705e3          	beq	a4,a5,80200134 <vprintfmt+0x34>
    802001ae:	02500713          	li	a4,37
    802001b2:	ffec4783          	lbu	a5,-2(s8)
    802001b6:	1c7d                	addi	s8,s8,-1
    802001b8:	fee79de3          	bne	a5,a4,802001b2 <vprintfmt+0xb2>
    802001bc:	bfa5                	j	80200134 <vprintfmt+0x34>
    802001be:	00144783          	lbu	a5,1(s0)
    802001c2:	4725                	li	a4,9
    802001c4:	fd068d1b          	addiw	s10,a3,-48
    802001c8:	fd07859b          	addiw	a1,a5,-48
    802001cc:	0007869b          	sext.w	a3,a5
    802001d0:	8462                	mv	s0,s8
    802001d2:	02b76563          	bltu	a4,a1,802001fc <vprintfmt+0xfc>
    802001d6:	4525                	li	a0,9
    802001d8:	00144783          	lbu	a5,1(s0)
    802001dc:	002d171b          	slliw	a4,s10,0x2
    802001e0:	01a7073b          	addw	a4,a4,s10
    802001e4:	0017171b          	slliw	a4,a4,0x1
    802001e8:	9f35                	addw	a4,a4,a3
    802001ea:	fd07859b          	addiw	a1,a5,-48
    802001ee:	0405                	addi	s0,s0,1
    802001f0:	fd070d1b          	addiw	s10,a4,-48
    802001f4:	0007869b          	sext.w	a3,a5
    802001f8:	feb570e3          	bgeu	a0,a1,802001d8 <vprintfmt+0xd8>
    802001fc:	f60cd0e3          	bgez	s9,8020015c <vprintfmt+0x5c>
    80200200:	8cea                	mv	s9,s10
    80200202:	5d7d                	li	s10,-1
    80200204:	bfa1                	j	8020015c <vprintfmt+0x5c>
    80200206:	8db6                	mv	s11,a3
    80200208:	8462                	mv	s0,s8
    8020020a:	bf89                	j	8020015c <vprintfmt+0x5c>
    8020020c:	8462                	mv	s0,s8
    8020020e:	4b85                	li	s7,1
    80200210:	b7b1                	j	8020015c <vprintfmt+0x5c>
    80200212:	4785                	li	a5,1
    80200214:	008a0713          	addi	a4,s4,8
    80200218:	00c7c463          	blt	a5,a2,80200220 <vprintfmt+0x120>
    8020021c:	1a060263          	beqz	a2,802003c0 <vprintfmt+0x2c0>
    80200220:	000a3603          	ld	a2,0(s4)
    80200224:	46c1                	li	a3,16
    80200226:	8a3a                	mv	s4,a4
    80200228:	000d879b          	sext.w	a5,s11
    8020022c:	8766                	mv	a4,s9
    8020022e:	85a6                	mv	a1,s1
    80200230:	854a                	mv	a0,s2
    80200232:	e61ff0ef          	jal	ra,80200092 <printnum>
    80200236:	bdfd                	j	80200134 <vprintfmt+0x34>
    80200238:	000a2503          	lw	a0,0(s4)
    8020023c:	85a6                	mv	a1,s1
    8020023e:	0a21                	addi	s4,s4,8
    80200240:	9902                	jalr	s2
    80200242:	bdcd                	j	80200134 <vprintfmt+0x34>
    80200244:	4785                	li	a5,1
    80200246:	008a0713          	addi	a4,s4,8
    8020024a:	00c7c463          	blt	a5,a2,80200252 <vprintfmt+0x152>
    8020024e:	16060463          	beqz	a2,802003b6 <vprintfmt+0x2b6>
    80200252:	000a3603          	ld	a2,0(s4)
    80200256:	46a9                	li	a3,10
    80200258:	8a3a                	mv	s4,a4
    8020025a:	b7f9                	j	80200228 <vprintfmt+0x128>
    8020025c:	03000513          	li	a0,48
    80200260:	85a6                	mv	a1,s1
    80200262:	9902                	jalr	s2
    80200264:	85a6                	mv	a1,s1
    80200266:	07800513          	li	a0,120
    8020026a:	9902                	jalr	s2
    8020026c:	0a21                	addi	s4,s4,8
    8020026e:	46c1                	li	a3,16
    80200270:	ff8a3603          	ld	a2,-8(s4)
    80200274:	bf55                	j	80200228 <vprintfmt+0x128>
    80200276:	85a6                	mv	a1,s1
    80200278:	02500513          	li	a0,37
    8020027c:	9902                	jalr	s2
    8020027e:	bd5d                	j	80200134 <vprintfmt+0x34>
    80200280:	000a2d03          	lw	s10,0(s4)
    80200284:	8462                	mv	s0,s8
    80200286:	0a21                	addi	s4,s4,8
    80200288:	bf95                	j	802001fc <vprintfmt+0xfc>
    8020028a:	4785                	li	a5,1
    8020028c:	008a0713          	addi	a4,s4,8
    80200290:	00c7c463          	blt	a5,a2,80200298 <vprintfmt+0x198>
    80200294:	10060c63          	beqz	a2,802003ac <vprintfmt+0x2ac>
    80200298:	000a3603          	ld	a2,0(s4)
    8020029c:	46a1                	li	a3,8
    8020029e:	8a3a                	mv	s4,a4
    802002a0:	b761                	j	80200228 <vprintfmt+0x128>
    802002a2:	fffcc793          	not	a5,s9
    802002a6:	97fd                	srai	a5,a5,0x3f
    802002a8:	00fcf7b3          	and	a5,s9,a5
    802002ac:	00078c9b          	sext.w	s9,a5
    802002b0:	8462                	mv	s0,s8
    802002b2:	b56d                	j	8020015c <vprintfmt+0x5c>
    802002b4:	000a3403          	ld	s0,0(s4)
    802002b8:	008a0793          	addi	a5,s4,8
    802002bc:	e43e                	sd	a5,8(sp)
    802002be:	12040163          	beqz	s0,802003e0 <vprintfmt+0x2e0>
    802002c2:	0d905963          	blez	s9,80200394 <vprintfmt+0x294>
    802002c6:	02d00793          	li	a5,45
    802002ca:	00140a13          	addi	s4,s0,1
    802002ce:	12fd9863          	bne	s11,a5,802003fe <vprintfmt+0x2fe>
    802002d2:	00044783          	lbu	a5,0(s0)
    802002d6:	0007851b          	sext.w	a0,a5
    802002da:	cb9d                	beqz	a5,80200310 <vprintfmt+0x210>
    802002dc:	547d                	li	s0,-1
    802002de:	05e00d93          	li	s11,94
    802002e2:	000d4563          	bltz	s10,802002ec <vprintfmt+0x1ec>
    802002e6:	3d7d                	addiw	s10,s10,-1
    802002e8:	028d0263          	beq	s10,s0,8020030c <vprintfmt+0x20c>
    802002ec:	85a6                	mv	a1,s1
    802002ee:	0c0b8e63          	beqz	s7,802003ca <vprintfmt+0x2ca>
    802002f2:	3781                	addiw	a5,a5,-32
    802002f4:	0cfdfb63          	bgeu	s11,a5,802003ca <vprintfmt+0x2ca>
    802002f8:	03f00513          	li	a0,63
    802002fc:	9902                	jalr	s2
    802002fe:	000a4783          	lbu	a5,0(s4)
    80200302:	3cfd                	addiw	s9,s9,-1
    80200304:	0a05                	addi	s4,s4,1
    80200306:	0007851b          	sext.w	a0,a5
    8020030a:	ffe1                	bnez	a5,802002e2 <vprintfmt+0x1e2>
    8020030c:	01905963          	blez	s9,8020031e <vprintfmt+0x21e>
    80200310:	3cfd                	addiw	s9,s9,-1
    80200312:	85a6                	mv	a1,s1
    80200314:	02000513          	li	a0,32
    80200318:	9902                	jalr	s2
    8020031a:	fe0c9be3          	bnez	s9,80200310 <vprintfmt+0x210>
    8020031e:	6a22                	ld	s4,8(sp)
    80200320:	bd11                	j	80200134 <vprintfmt+0x34>
    80200322:	4785                	li	a5,1
    80200324:	008a0b93          	addi	s7,s4,8
    80200328:	00c7c363          	blt	a5,a2,8020032e <vprintfmt+0x22e>
    8020032c:	ce2d                	beqz	a2,802003a6 <vprintfmt+0x2a6>
    8020032e:	000a3403          	ld	s0,0(s4)
    80200332:	08044e63          	bltz	s0,802003ce <vprintfmt+0x2ce>
    80200336:	8622                	mv	a2,s0
    80200338:	8a5e                	mv	s4,s7
    8020033a:	46a9                	li	a3,10
    8020033c:	b5f5                	j	80200228 <vprintfmt+0x128>
    8020033e:	000a2783          	lw	a5,0(s4)
    80200342:	4619                	li	a2,6
    80200344:	41f7d71b          	sraiw	a4,a5,0x1f
    80200348:	8fb9                	xor	a5,a5,a4
    8020034a:	40e786bb          	subw	a3,a5,a4
    8020034e:	02d64663          	blt	a2,a3,8020037a <vprintfmt+0x27a>
    80200352:	00369713          	slli	a4,a3,0x3
    80200356:	00000797          	auipc	a5,0x0
    8020035a:	3aa78793          	addi	a5,a5,938 # 80200700 <error_string>
    8020035e:	97ba                	add	a5,a5,a4
    80200360:	639c                	ld	a5,0(a5)
    80200362:	cf81                	beqz	a5,8020037a <vprintfmt+0x27a>
    80200364:	86be                	mv	a3,a5
    80200366:	00000617          	auipc	a2,0x0
    8020036a:	1ba60613          	addi	a2,a2,442 # 80200520 <memset+0x6e>
    8020036e:	85a6                	mv	a1,s1
    80200370:	854a                	mv	a0,s2
    80200372:	0ea000ef          	jal	ra,8020045c <printfmt>
    80200376:	0a21                	addi	s4,s4,8
    80200378:	bb75                	j	80200134 <vprintfmt+0x34>
    8020037a:	00000617          	auipc	a2,0x0
    8020037e:	19660613          	addi	a2,a2,406 # 80200510 <memset+0x5e>
    80200382:	85a6                	mv	a1,s1
    80200384:	854a                	mv	a0,s2
    80200386:	0d6000ef          	jal	ra,8020045c <printfmt>
    8020038a:	0a21                	addi	s4,s4,8
    8020038c:	b365                	j	80200134 <vprintfmt+0x34>
    8020038e:	2605                	addiw	a2,a2,1
    80200390:	8462                	mv	s0,s8
    80200392:	b3e9                	j	8020015c <vprintfmt+0x5c>
    80200394:	00044783          	lbu	a5,0(s0)
    80200398:	00140a13          	addi	s4,s0,1
    8020039c:	0007851b          	sext.w	a0,a5
    802003a0:	ff95                	bnez	a5,802002dc <vprintfmt+0x1dc>
    802003a2:	6a22                	ld	s4,8(sp)
    802003a4:	bb41                	j	80200134 <vprintfmt+0x34>
    802003a6:	000a2403          	lw	s0,0(s4)
    802003aa:	b761                	j	80200332 <vprintfmt+0x232>
    802003ac:	000a6603          	lwu	a2,0(s4)
    802003b0:	46a1                	li	a3,8
    802003b2:	8a3a                	mv	s4,a4
    802003b4:	bd95                	j	80200228 <vprintfmt+0x128>
    802003b6:	000a6603          	lwu	a2,0(s4)
    802003ba:	46a9                	li	a3,10
    802003bc:	8a3a                	mv	s4,a4
    802003be:	b5ad                	j	80200228 <vprintfmt+0x128>
    802003c0:	000a6603          	lwu	a2,0(s4)
    802003c4:	46c1                	li	a3,16
    802003c6:	8a3a                	mv	s4,a4
    802003c8:	b585                	j	80200228 <vprintfmt+0x128>
    802003ca:	9902                	jalr	s2
    802003cc:	bf0d                	j	802002fe <vprintfmt+0x1fe>
    802003ce:	85a6                	mv	a1,s1
    802003d0:	02d00513          	li	a0,45
    802003d4:	9902                	jalr	s2
    802003d6:	8a5e                	mv	s4,s7
    802003d8:	40800633          	neg	a2,s0
    802003dc:	46a9                	li	a3,10
    802003de:	b5a9                	j	80200228 <vprintfmt+0x128>
    802003e0:	01905663          	blez	s9,802003ec <vprintfmt+0x2ec>
    802003e4:	02d00793          	li	a5,45
    802003e8:	04fd9263          	bne	s11,a5,8020042c <vprintfmt+0x32c>
    802003ec:	00000a17          	auipc	s4,0x0
    802003f0:	11da0a13          	addi	s4,s4,285 # 80200509 <memset+0x57>
    802003f4:	02800513          	li	a0,40
    802003f8:	02800793          	li	a5,40
    802003fc:	b5c5                	j	802002dc <vprintfmt+0x1dc>
    802003fe:	85ea                	mv	a1,s10
    80200400:	8522                	mv	a0,s0
    80200402:	094000ef          	jal	ra,80200496 <strnlen>
    80200406:	40ac8cbb          	subw	s9,s9,a0
    8020040a:	01905963          	blez	s9,8020041c <vprintfmt+0x31c>
    8020040e:	2d81                	sext.w	s11,s11
    80200410:	3cfd                	addiw	s9,s9,-1
    80200412:	85a6                	mv	a1,s1
    80200414:	856e                	mv	a0,s11
    80200416:	9902                	jalr	s2
    80200418:	fe0c9ce3          	bnez	s9,80200410 <vprintfmt+0x310>
    8020041c:	00044783          	lbu	a5,0(s0)
    80200420:	0007851b          	sext.w	a0,a5
    80200424:	ea079ce3          	bnez	a5,802002dc <vprintfmt+0x1dc>
    80200428:	6a22                	ld	s4,8(sp)
    8020042a:	b329                	j	80200134 <vprintfmt+0x34>
    8020042c:	85ea                	mv	a1,s10
    8020042e:	00000517          	auipc	a0,0x0
    80200432:	0da50513          	addi	a0,a0,218 # 80200508 <memset+0x56>
    80200436:	060000ef          	jal	ra,80200496 <strnlen>
    8020043a:	40ac8cbb          	subw	s9,s9,a0
    8020043e:	00000a17          	auipc	s4,0x0
    80200442:	0cba0a13          	addi	s4,s4,203 # 80200509 <memset+0x57>
    80200446:	00000417          	auipc	s0,0x0
    8020044a:	0c240413          	addi	s0,s0,194 # 80200508 <memset+0x56>
    8020044e:	02800513          	li	a0,40
    80200452:	02800793          	li	a5,40
    80200456:	fb904ce3          	bgtz	s9,8020040e <vprintfmt+0x30e>
    8020045a:	b549                	j	802002dc <vprintfmt+0x1dc>

000000008020045c <printfmt>:
    8020045c:	715d                	addi	sp,sp,-80
    8020045e:	02810313          	addi	t1,sp,40
    80200462:	f436                	sd	a3,40(sp)
    80200464:	869a                	mv	a3,t1
    80200466:	ec06                	sd	ra,24(sp)
    80200468:	f83a                	sd	a4,48(sp)
    8020046a:	fc3e                	sd	a5,56(sp)
    8020046c:	e0c2                	sd	a6,64(sp)
    8020046e:	e4c6                	sd	a7,72(sp)
    80200470:	e41a                	sd	t1,8(sp)
    80200472:	c8fff0ef          	jal	ra,80200100 <vprintfmt>
    80200476:	60e2                	ld	ra,24(sp)
    80200478:	6161                	addi	sp,sp,80
    8020047a:	8082                	ret

000000008020047c <sbi_console_putchar>:
    8020047c:	4781                	li	a5,0
    8020047e:	00003717          	auipc	a4,0x3
    80200482:	b8273703          	ld	a4,-1150(a4) # 80203000 <SBI_CONSOLE_PUTCHAR>
    80200486:	88ba                	mv	a7,a4
    80200488:	852a                	mv	a0,a0
    8020048a:	85be                	mv	a1,a5
    8020048c:	863e                	mv	a2,a5
    8020048e:	00000073          	ecall
    80200492:	87aa                	mv	a5,a0
    80200494:	8082                	ret

0000000080200496 <strnlen>:
    80200496:	4781                	li	a5,0
    80200498:	e589                	bnez	a1,802004a2 <strnlen+0xc>
    8020049a:	a811                	j	802004ae <strnlen+0x18>
    8020049c:	0785                	addi	a5,a5,1
    8020049e:	00f58863          	beq	a1,a5,802004ae <strnlen+0x18>
    802004a2:	00f50733          	add	a4,a0,a5
    802004a6:	00074703          	lbu	a4,0(a4)
    802004aa:	fb6d                	bnez	a4,8020049c <strnlen+0x6>
    802004ac:	85be                	mv	a1,a5
    802004ae:	852e                	mv	a0,a1
    802004b0:	8082                	ret

00000000802004b2 <memset>:
    802004b2:	ca01                	beqz	a2,802004c2 <memset+0x10>
    802004b4:	962a                	add	a2,a2,a0
    802004b6:	87aa                	mv	a5,a0
    802004b8:	0785                	addi	a5,a5,1
    802004ba:	feb78fa3          	sb	a1,-1(a5)
    802004be:	fec79de3          	bne	a5,a2,802004b8 <memset+0x6>
    802004c2:	8082                	ret
