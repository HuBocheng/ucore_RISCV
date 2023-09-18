
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    80200000:	00004117          	auipc	sp,0x4
    80200004:	00010113          	mv	sp,sp

    tail kern_init
    80200008:	a009                	j	8020000a <kern_init>

000000008020000a <kern_init>:
    8020000a:	00004517          	auipc	a0,0x4
    8020000e:	00650513          	addi	a0,a0,6 # 80204010 <ticks>
    80200012:	00004617          	auipc	a2,0x4
    80200016:	01660613          	addi	a2,a2,22 # 80204028 <end>
    8020001a:	1141                	addi	sp,sp,-16
    8020001c:	8e09                	sub	a2,a2,a0
    8020001e:	4581                	li	a1,0
    80200020:	e406                	sd	ra,8(sp)
    80200022:	16d000ef          	jal	ra,8020098e <memset>
    80200026:	148000ef          	jal	ra,8020016e <cons_init>
    8020002a:	00001597          	auipc	a1,0x1
    8020002e:	97658593          	addi	a1,a1,-1674 # 802009a0 <etext>
    80200032:	00001517          	auipc	a0,0x1
    80200036:	98e50513          	addi	a0,a0,-1650 # 802009c0 <etext+0x20>
    8020003a:	030000ef          	jal	ra,8020006a <cprintf>
    8020003e:	062000ef          	jal	ra,802000a0 <print_kerninfo>
    80200042:	13c000ef          	jal	ra,8020017e <idt_init>
    80200046:	0e6000ef          	jal	ra,8020012c <clock_init>
    8020004a:	12e000ef          	jal	ra,80200178 <intr_enable>
    8020004e:	a001                	j	8020004e <kern_init+0x44>

0000000080200050 <cputch>:
    80200050:	1141                	addi	sp,sp,-16
    80200052:	e022                	sd	s0,0(sp)
    80200054:	e406                	sd	ra,8(sp)
    80200056:	842e                	mv	s0,a1
    80200058:	118000ef          	jal	ra,80200170 <cons_putc>
    8020005c:	401c                	lw	a5,0(s0)
    8020005e:	60a2                	ld	ra,8(sp)
    80200060:	2785                	addiw	a5,a5,1
    80200062:	c01c                	sw	a5,0(s0)
    80200064:	6402                	ld	s0,0(sp)
    80200066:	0141                	addi	sp,sp,16
    80200068:	8082                	ret

000000008020006a <cprintf>:
    8020006a:	711d                	addi	sp,sp,-96
    8020006c:	02810313          	addi	t1,sp,40 # 80204028 <end>
    80200070:	8e2a                	mv	t3,a0
    80200072:	f42e                	sd	a1,40(sp)
    80200074:	f832                	sd	a2,48(sp)
    80200076:	fc36                	sd	a3,56(sp)
    80200078:	00000517          	auipc	a0,0x0
    8020007c:	fd850513          	addi	a0,a0,-40 # 80200050 <cputch>
    80200080:	004c                	addi	a1,sp,4
    80200082:	869a                	mv	a3,t1
    80200084:	8672                	mv	a2,t3
    80200086:	ec06                	sd	ra,24(sp)
    80200088:	e0ba                	sd	a4,64(sp)
    8020008a:	e4be                	sd	a5,72(sp)
    8020008c:	e8c2                	sd	a6,80(sp)
    8020008e:	ecc6                	sd	a7,88(sp)
    80200090:	e41a                	sd	t1,8(sp)
    80200092:	c202                	sw	zero,4(sp)
    80200094:	514000ef          	jal	ra,802005a8 <vprintfmt>
    80200098:	60e2                	ld	ra,24(sp)
    8020009a:	4512                	lw	a0,4(sp)
    8020009c:	6125                	addi	sp,sp,96
    8020009e:	8082                	ret

00000000802000a0 <print_kerninfo>:
    802000a0:	1141                	addi	sp,sp,-16
    802000a2:	00001517          	auipc	a0,0x1
    802000a6:	92650513          	addi	a0,a0,-1754 # 802009c8 <etext+0x28>
    802000aa:	e406                	sd	ra,8(sp)
    802000ac:	fbfff0ef          	jal	ra,8020006a <cprintf>
    802000b0:	00000597          	auipc	a1,0x0
    802000b4:	f5a58593          	addi	a1,a1,-166 # 8020000a <kern_init>
    802000b8:	00001517          	auipc	a0,0x1
    802000bc:	93050513          	addi	a0,a0,-1744 # 802009e8 <etext+0x48>
    802000c0:	fabff0ef          	jal	ra,8020006a <cprintf>
    802000c4:	00001597          	auipc	a1,0x1
    802000c8:	8dc58593          	addi	a1,a1,-1828 # 802009a0 <etext>
    802000cc:	00001517          	auipc	a0,0x1
    802000d0:	93c50513          	addi	a0,a0,-1732 # 80200a08 <etext+0x68>
    802000d4:	f97ff0ef          	jal	ra,8020006a <cprintf>
    802000d8:	00004597          	auipc	a1,0x4
    802000dc:	f3858593          	addi	a1,a1,-200 # 80204010 <ticks>
    802000e0:	00001517          	auipc	a0,0x1
    802000e4:	94850513          	addi	a0,a0,-1720 # 80200a28 <etext+0x88>
    802000e8:	f83ff0ef          	jal	ra,8020006a <cprintf>
    802000ec:	00004597          	auipc	a1,0x4
    802000f0:	f3c58593          	addi	a1,a1,-196 # 80204028 <end>
    802000f4:	00001517          	auipc	a0,0x1
    802000f8:	95450513          	addi	a0,a0,-1708 # 80200a48 <etext+0xa8>
    802000fc:	f6fff0ef          	jal	ra,8020006a <cprintf>
    80200100:	00004797          	auipc	a5,0x4
    80200104:	32778793          	addi	a5,a5,807 # 80204427 <end+0x3ff>
    80200108:	00000717          	auipc	a4,0x0
    8020010c:	f0270713          	addi	a4,a4,-254 # 8020000a <kern_init>
    80200110:	8f99                	sub	a5,a5,a4
    80200112:	43f7d593          	srai	a1,a5,0x3f
    80200116:	60a2                	ld	ra,8(sp)
    80200118:	3ff5f593          	andi	a1,a1,1023
    8020011c:	95be                	add	a1,a1,a5
    8020011e:	85a9                	srai	a1,a1,0xa
    80200120:	00001517          	auipc	a0,0x1
    80200124:	94850513          	addi	a0,a0,-1720 # 80200a68 <etext+0xc8>
    80200128:	0141                	addi	sp,sp,16
    8020012a:	b781                	j	8020006a <cprintf>

000000008020012c <clock_init>:
    8020012c:	1141                	addi	sp,sp,-16
    8020012e:	e406                	sd	ra,8(sp)
    80200130:	02000793          	li	a5,32
    80200134:	1047a7f3          	csrrs	a5,sie,a5
    80200138:	c0102573          	rdtime	a0
    8020013c:	67e1                	lui	a5,0x18
    8020013e:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    80200142:	953e                	add	a0,a0,a5
    80200144:	7fa000ef          	jal	ra,8020093e <sbi_set_timer>
    80200148:	60a2                	ld	ra,8(sp)
    8020014a:	00004797          	auipc	a5,0x4
    8020014e:	ec07b323          	sd	zero,-314(a5) # 80204010 <ticks>
    80200152:	00001517          	auipc	a0,0x1
    80200156:	94650513          	addi	a0,a0,-1722 # 80200a98 <etext+0xf8>
    8020015a:	0141                	addi	sp,sp,16
    8020015c:	b739                	j	8020006a <cprintf>

000000008020015e <clock_set_next_event>:
    8020015e:	c0102573          	rdtime	a0
    80200162:	67e1                	lui	a5,0x18
    80200164:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    80200168:	953e                	add	a0,a0,a5
    8020016a:	7d40006f          	j	8020093e <sbi_set_timer>

000000008020016e <cons_init>:
    8020016e:	8082                	ret

0000000080200170 <cons_putc>:
    80200170:	0ff57513          	andi	a0,a0,255
    80200174:	7b00006f          	j	80200924 <sbi_console_putchar>

0000000080200178 <intr_enable>:
    80200178:	100167f3          	csrrsi	a5,sstatus,2
    8020017c:	8082                	ret

000000008020017e <idt_init>:
    8020017e:	14005073          	csrwi	sscratch,0
    80200182:	00000797          	auipc	a5,0x0
    80200186:	30278793          	addi	a5,a5,770 # 80200484 <__alltraps>
    8020018a:	10579073          	csrw	stvec,a5
    8020018e:	8082                	ret

0000000080200190 <print_regs>:
    80200190:	610c                	ld	a1,0(a0)
    80200192:	1141                	addi	sp,sp,-16
    80200194:	e022                	sd	s0,0(sp)
    80200196:	842a                	mv	s0,a0
    80200198:	00001517          	auipc	a0,0x1
    8020019c:	92050513          	addi	a0,a0,-1760 # 80200ab8 <etext+0x118>
    802001a0:	e406                	sd	ra,8(sp)
    802001a2:	ec9ff0ef          	jal	ra,8020006a <cprintf>
    802001a6:	640c                	ld	a1,8(s0)
    802001a8:	00001517          	auipc	a0,0x1
    802001ac:	92850513          	addi	a0,a0,-1752 # 80200ad0 <etext+0x130>
    802001b0:	ebbff0ef          	jal	ra,8020006a <cprintf>
    802001b4:	680c                	ld	a1,16(s0)
    802001b6:	00001517          	auipc	a0,0x1
    802001ba:	93250513          	addi	a0,a0,-1742 # 80200ae8 <etext+0x148>
    802001be:	eadff0ef          	jal	ra,8020006a <cprintf>
    802001c2:	6c0c                	ld	a1,24(s0)
    802001c4:	00001517          	auipc	a0,0x1
    802001c8:	93c50513          	addi	a0,a0,-1732 # 80200b00 <etext+0x160>
    802001cc:	e9fff0ef          	jal	ra,8020006a <cprintf>
    802001d0:	700c                	ld	a1,32(s0)
    802001d2:	00001517          	auipc	a0,0x1
    802001d6:	94650513          	addi	a0,a0,-1722 # 80200b18 <etext+0x178>
    802001da:	e91ff0ef          	jal	ra,8020006a <cprintf>
    802001de:	740c                	ld	a1,40(s0)
    802001e0:	00001517          	auipc	a0,0x1
    802001e4:	95050513          	addi	a0,a0,-1712 # 80200b30 <etext+0x190>
    802001e8:	e83ff0ef          	jal	ra,8020006a <cprintf>
    802001ec:	780c                	ld	a1,48(s0)
    802001ee:	00001517          	auipc	a0,0x1
    802001f2:	95a50513          	addi	a0,a0,-1702 # 80200b48 <etext+0x1a8>
    802001f6:	e75ff0ef          	jal	ra,8020006a <cprintf>
    802001fa:	7c0c                	ld	a1,56(s0)
    802001fc:	00001517          	auipc	a0,0x1
    80200200:	96450513          	addi	a0,a0,-1692 # 80200b60 <etext+0x1c0>
    80200204:	e67ff0ef          	jal	ra,8020006a <cprintf>
    80200208:	602c                	ld	a1,64(s0)
    8020020a:	00001517          	auipc	a0,0x1
    8020020e:	96e50513          	addi	a0,a0,-1682 # 80200b78 <etext+0x1d8>
    80200212:	e59ff0ef          	jal	ra,8020006a <cprintf>
    80200216:	642c                	ld	a1,72(s0)
    80200218:	00001517          	auipc	a0,0x1
    8020021c:	97850513          	addi	a0,a0,-1672 # 80200b90 <etext+0x1f0>
    80200220:	e4bff0ef          	jal	ra,8020006a <cprintf>
    80200224:	682c                	ld	a1,80(s0)
    80200226:	00001517          	auipc	a0,0x1
    8020022a:	98250513          	addi	a0,a0,-1662 # 80200ba8 <etext+0x208>
    8020022e:	e3dff0ef          	jal	ra,8020006a <cprintf>
    80200232:	6c2c                	ld	a1,88(s0)
    80200234:	00001517          	auipc	a0,0x1
    80200238:	98c50513          	addi	a0,a0,-1652 # 80200bc0 <etext+0x220>
    8020023c:	e2fff0ef          	jal	ra,8020006a <cprintf>
    80200240:	702c                	ld	a1,96(s0)
    80200242:	00001517          	auipc	a0,0x1
    80200246:	99650513          	addi	a0,a0,-1642 # 80200bd8 <etext+0x238>
    8020024a:	e21ff0ef          	jal	ra,8020006a <cprintf>
    8020024e:	742c                	ld	a1,104(s0)
    80200250:	00001517          	auipc	a0,0x1
    80200254:	9a050513          	addi	a0,a0,-1632 # 80200bf0 <etext+0x250>
    80200258:	e13ff0ef          	jal	ra,8020006a <cprintf>
    8020025c:	782c                	ld	a1,112(s0)
    8020025e:	00001517          	auipc	a0,0x1
    80200262:	9aa50513          	addi	a0,a0,-1622 # 80200c08 <etext+0x268>
    80200266:	e05ff0ef          	jal	ra,8020006a <cprintf>
    8020026a:	7c2c                	ld	a1,120(s0)
    8020026c:	00001517          	auipc	a0,0x1
    80200270:	9b450513          	addi	a0,a0,-1612 # 80200c20 <etext+0x280>
    80200274:	df7ff0ef          	jal	ra,8020006a <cprintf>
    80200278:	604c                	ld	a1,128(s0)
    8020027a:	00001517          	auipc	a0,0x1
    8020027e:	9be50513          	addi	a0,a0,-1602 # 80200c38 <etext+0x298>
    80200282:	de9ff0ef          	jal	ra,8020006a <cprintf>
    80200286:	644c                	ld	a1,136(s0)
    80200288:	00001517          	auipc	a0,0x1
    8020028c:	9c850513          	addi	a0,a0,-1592 # 80200c50 <etext+0x2b0>
    80200290:	ddbff0ef          	jal	ra,8020006a <cprintf>
    80200294:	684c                	ld	a1,144(s0)
    80200296:	00001517          	auipc	a0,0x1
    8020029a:	9d250513          	addi	a0,a0,-1582 # 80200c68 <etext+0x2c8>
    8020029e:	dcdff0ef          	jal	ra,8020006a <cprintf>
    802002a2:	6c4c                	ld	a1,152(s0)
    802002a4:	00001517          	auipc	a0,0x1
    802002a8:	9dc50513          	addi	a0,a0,-1572 # 80200c80 <etext+0x2e0>
    802002ac:	dbfff0ef          	jal	ra,8020006a <cprintf>
    802002b0:	704c                	ld	a1,160(s0)
    802002b2:	00001517          	auipc	a0,0x1
    802002b6:	9e650513          	addi	a0,a0,-1562 # 80200c98 <etext+0x2f8>
    802002ba:	db1ff0ef          	jal	ra,8020006a <cprintf>
    802002be:	744c                	ld	a1,168(s0)
    802002c0:	00001517          	auipc	a0,0x1
    802002c4:	9f050513          	addi	a0,a0,-1552 # 80200cb0 <etext+0x310>
    802002c8:	da3ff0ef          	jal	ra,8020006a <cprintf>
    802002cc:	784c                	ld	a1,176(s0)
    802002ce:	00001517          	auipc	a0,0x1
    802002d2:	9fa50513          	addi	a0,a0,-1542 # 80200cc8 <etext+0x328>
    802002d6:	d95ff0ef          	jal	ra,8020006a <cprintf>
    802002da:	7c4c                	ld	a1,184(s0)
    802002dc:	00001517          	auipc	a0,0x1
    802002e0:	a0450513          	addi	a0,a0,-1532 # 80200ce0 <etext+0x340>
    802002e4:	d87ff0ef          	jal	ra,8020006a <cprintf>
    802002e8:	606c                	ld	a1,192(s0)
    802002ea:	00001517          	auipc	a0,0x1
    802002ee:	a0e50513          	addi	a0,a0,-1522 # 80200cf8 <etext+0x358>
    802002f2:	d79ff0ef          	jal	ra,8020006a <cprintf>
    802002f6:	646c                	ld	a1,200(s0)
    802002f8:	00001517          	auipc	a0,0x1
    802002fc:	a1850513          	addi	a0,a0,-1512 # 80200d10 <etext+0x370>
    80200300:	d6bff0ef          	jal	ra,8020006a <cprintf>
    80200304:	686c                	ld	a1,208(s0)
    80200306:	00001517          	auipc	a0,0x1
    8020030a:	a2250513          	addi	a0,a0,-1502 # 80200d28 <etext+0x388>
    8020030e:	d5dff0ef          	jal	ra,8020006a <cprintf>
    80200312:	6c6c                	ld	a1,216(s0)
    80200314:	00001517          	auipc	a0,0x1
    80200318:	a2c50513          	addi	a0,a0,-1492 # 80200d40 <etext+0x3a0>
    8020031c:	d4fff0ef          	jal	ra,8020006a <cprintf>
    80200320:	706c                	ld	a1,224(s0)
    80200322:	00001517          	auipc	a0,0x1
    80200326:	a3650513          	addi	a0,a0,-1482 # 80200d58 <etext+0x3b8>
    8020032a:	d41ff0ef          	jal	ra,8020006a <cprintf>
    8020032e:	746c                	ld	a1,232(s0)
    80200330:	00001517          	auipc	a0,0x1
    80200334:	a4050513          	addi	a0,a0,-1472 # 80200d70 <etext+0x3d0>
    80200338:	d33ff0ef          	jal	ra,8020006a <cprintf>
    8020033c:	786c                	ld	a1,240(s0)
    8020033e:	00001517          	auipc	a0,0x1
    80200342:	a4a50513          	addi	a0,a0,-1462 # 80200d88 <etext+0x3e8>
    80200346:	d25ff0ef          	jal	ra,8020006a <cprintf>
    8020034a:	7c6c                	ld	a1,248(s0)
    8020034c:	6402                	ld	s0,0(sp)
    8020034e:	60a2                	ld	ra,8(sp)
    80200350:	00001517          	auipc	a0,0x1
    80200354:	a5050513          	addi	a0,a0,-1456 # 80200da0 <etext+0x400>
    80200358:	0141                	addi	sp,sp,16
    8020035a:	bb01                	j	8020006a <cprintf>

000000008020035c <print_trapframe>:
    8020035c:	1141                	addi	sp,sp,-16
    8020035e:	e022                	sd	s0,0(sp)
    80200360:	85aa                	mv	a1,a0
    80200362:	842a                	mv	s0,a0
    80200364:	00001517          	auipc	a0,0x1
    80200368:	a5450513          	addi	a0,a0,-1452 # 80200db8 <etext+0x418>
    8020036c:	e406                	sd	ra,8(sp)
    8020036e:	cfdff0ef          	jal	ra,8020006a <cprintf>
    80200372:	8522                	mv	a0,s0
    80200374:	e1dff0ef          	jal	ra,80200190 <print_regs>
    80200378:	10043583          	ld	a1,256(s0)
    8020037c:	00001517          	auipc	a0,0x1
    80200380:	a5450513          	addi	a0,a0,-1452 # 80200dd0 <etext+0x430>
    80200384:	ce7ff0ef          	jal	ra,8020006a <cprintf>
    80200388:	10843583          	ld	a1,264(s0)
    8020038c:	00001517          	auipc	a0,0x1
    80200390:	a5c50513          	addi	a0,a0,-1444 # 80200de8 <etext+0x448>
    80200394:	cd7ff0ef          	jal	ra,8020006a <cprintf>
    80200398:	11043583          	ld	a1,272(s0)
    8020039c:	00001517          	auipc	a0,0x1
    802003a0:	a6450513          	addi	a0,a0,-1436 # 80200e00 <etext+0x460>
    802003a4:	cc7ff0ef          	jal	ra,8020006a <cprintf>
    802003a8:	11843583          	ld	a1,280(s0)
    802003ac:	6402                	ld	s0,0(sp)
    802003ae:	60a2                	ld	ra,8(sp)
    802003b0:	00001517          	auipc	a0,0x1
    802003b4:	a6850513          	addi	a0,a0,-1432 # 80200e18 <etext+0x478>
    802003b8:	0141                	addi	sp,sp,16
    802003ba:	b945                	j	8020006a <cprintf>

00000000802003bc <interrupt_handler>:
    802003bc:	11853783          	ld	a5,280(a0)
    802003c0:	472d                	li	a4,11
    802003c2:	0786                	slli	a5,a5,0x1
    802003c4:	8385                	srli	a5,a5,0x1
    802003c6:	06f76963          	bltu	a4,a5,80200438 <interrupt_handler+0x7c>
    802003ca:	00001717          	auipc	a4,0x1
    802003ce:	b1670713          	addi	a4,a4,-1258 # 80200ee0 <etext+0x540>
    802003d2:	078a                	slli	a5,a5,0x2
    802003d4:	97ba                	add	a5,a5,a4
    802003d6:	439c                	lw	a5,0(a5)
    802003d8:	97ba                	add	a5,a5,a4
    802003da:	8782                	jr	a5
    802003dc:	00001517          	auipc	a0,0x1
    802003e0:	ab450513          	addi	a0,a0,-1356 # 80200e90 <etext+0x4f0>
    802003e4:	b159                	j	8020006a <cprintf>
    802003e6:	00001517          	auipc	a0,0x1
    802003ea:	a8a50513          	addi	a0,a0,-1398 # 80200e70 <etext+0x4d0>
    802003ee:	b9b5                	j	8020006a <cprintf>
    802003f0:	00001517          	auipc	a0,0x1
    802003f4:	a4050513          	addi	a0,a0,-1472 # 80200e30 <etext+0x490>
    802003f8:	b98d                	j	8020006a <cprintf>
    802003fa:	00001517          	auipc	a0,0x1
    802003fe:	a5650513          	addi	a0,a0,-1450 # 80200e50 <etext+0x4b0>
    80200402:	b1a5                	j	8020006a <cprintf>
    80200404:	1141                	addi	sp,sp,-16
    80200406:	e406                	sd	ra,8(sp)
    80200408:	e022                	sd	s0,0(sp)
    8020040a:	d55ff0ef          	jal	ra,8020015e <clock_set_next_event>
    8020040e:	00004797          	auipc	a5,0x4
    80200412:	c0278793          	addi	a5,a5,-1022 # 80204010 <ticks>
    80200416:	6398                	ld	a4,0(a5)
    80200418:	06400693          	li	a3,100
    8020041c:	0705                	addi	a4,a4,1
    8020041e:	e398                	sd	a4,0(a5)
    80200420:	639c                	ld	a5,0(a5)
    80200422:	00d78c63          	beq	a5,a3,8020043a <interrupt_handler+0x7e>
    80200426:	60a2                	ld	ra,8(sp)
    80200428:	6402                	ld	s0,0(sp)
    8020042a:	0141                	addi	sp,sp,16
    8020042c:	8082                	ret
    8020042e:	00001517          	auipc	a0,0x1
    80200432:	a9250513          	addi	a0,a0,-1390 # 80200ec0 <etext+0x520>
    80200436:	b915                	j	8020006a <cprintf>
    80200438:	b715                	j	8020035c <print_trapframe>
    8020043a:	06400593          	li	a1,100
    8020043e:	00001517          	auipc	a0,0x1
    80200442:	a7250513          	addi	a0,a0,-1422 # 80200eb0 <etext+0x510>
    80200446:	00004797          	auipc	a5,0x4
    8020044a:	bc07b523          	sd	zero,-1078(a5) # 80204010 <ticks>
    8020044e:	00004417          	auipc	s0,0x4
    80200452:	bca40413          	addi	s0,s0,-1078 # 80204018 <num>
    80200456:	c15ff0ef          	jal	ra,8020006a <cprintf>
    8020045a:	6018                	ld	a4,0(s0)
    8020045c:	47a9                	li	a5,10
    8020045e:	00f70663          	beq	a4,a5,8020046a <interrupt_handler+0xae>
    80200462:	601c                	ld	a5,0(s0)
    80200464:	0785                	addi	a5,a5,1
    80200466:	e01c                	sd	a5,0(s0)
    80200468:	bf7d                	j	80200426 <interrupt_handler+0x6a>
    8020046a:	4ee000ef          	jal	ra,80200958 <sbi_shutdown>
    8020046e:	bfd5                	j	80200462 <interrupt_handler+0xa6>

0000000080200470 <trap>:
    80200470:	11853783          	ld	a5,280(a0)
    80200474:	0007c763          	bltz	a5,80200482 <trap+0x12>
    80200478:	472d                	li	a4,11
    8020047a:	00f76363          	bltu	a4,a5,80200480 <trap+0x10>
    8020047e:	8082                	ret
    80200480:	bdf1                	j	8020035c <print_trapframe>
    80200482:	bf2d                	j	802003bc <interrupt_handler>

0000000080200484 <__alltraps>:
    80200484:	14011073          	csrw	sscratch,sp
    80200488:	712d                	addi	sp,sp,-288
    8020048a:	e002                	sd	zero,0(sp)
    8020048c:	e406                	sd	ra,8(sp)
    8020048e:	ec0e                	sd	gp,24(sp)
    80200490:	f012                	sd	tp,32(sp)
    80200492:	f416                	sd	t0,40(sp)
    80200494:	f81a                	sd	t1,48(sp)
    80200496:	fc1e                	sd	t2,56(sp)
    80200498:	e0a2                	sd	s0,64(sp)
    8020049a:	e4a6                	sd	s1,72(sp)
    8020049c:	e8aa                	sd	a0,80(sp)
    8020049e:	ecae                	sd	a1,88(sp)
    802004a0:	f0b2                	sd	a2,96(sp)
    802004a2:	f4b6                	sd	a3,104(sp)
    802004a4:	f8ba                	sd	a4,112(sp)
    802004a6:	fcbe                	sd	a5,120(sp)
    802004a8:	e142                	sd	a6,128(sp)
    802004aa:	e546                	sd	a7,136(sp)
    802004ac:	e94a                	sd	s2,144(sp)
    802004ae:	ed4e                	sd	s3,152(sp)
    802004b0:	f152                	sd	s4,160(sp)
    802004b2:	f556                	sd	s5,168(sp)
    802004b4:	f95a                	sd	s6,176(sp)
    802004b6:	fd5e                	sd	s7,184(sp)
    802004b8:	e1e2                	sd	s8,192(sp)
    802004ba:	e5e6                	sd	s9,200(sp)
    802004bc:	e9ea                	sd	s10,208(sp)
    802004be:	edee                	sd	s11,216(sp)
    802004c0:	f1f2                	sd	t3,224(sp)
    802004c2:	f5f6                	sd	t4,232(sp)
    802004c4:	f9fa                	sd	t5,240(sp)
    802004c6:	fdfe                	sd	t6,248(sp)
    802004c8:	14001473          	csrrw	s0,sscratch,zero
    802004cc:	100024f3          	csrr	s1,sstatus
    802004d0:	14102973          	csrr	s2,sepc
    802004d4:	143029f3          	csrr	s3,stval
    802004d8:	14202a73          	csrr	s4,scause
    802004dc:	e822                	sd	s0,16(sp)
    802004de:	e226                	sd	s1,256(sp)
    802004e0:	e64a                	sd	s2,264(sp)
    802004e2:	ea4e                	sd	s3,272(sp)
    802004e4:	ee52                	sd	s4,280(sp)
    802004e6:	850a                	mv	a0,sp
    802004e8:	f89ff0ef          	jal	ra,80200470 <trap>

00000000802004ec <__trapret>:
    802004ec:	6492                	ld	s1,256(sp)
    802004ee:	6932                	ld	s2,264(sp)
    802004f0:	10049073          	csrw	sstatus,s1
    802004f4:	14191073          	csrw	sepc,s2
    802004f8:	60a2                	ld	ra,8(sp)
    802004fa:	61e2                	ld	gp,24(sp)
    802004fc:	7202                	ld	tp,32(sp)
    802004fe:	72a2                	ld	t0,40(sp)
    80200500:	7342                	ld	t1,48(sp)
    80200502:	73e2                	ld	t2,56(sp)
    80200504:	6406                	ld	s0,64(sp)
    80200506:	64a6                	ld	s1,72(sp)
    80200508:	6546                	ld	a0,80(sp)
    8020050a:	65e6                	ld	a1,88(sp)
    8020050c:	7606                	ld	a2,96(sp)
    8020050e:	76a6                	ld	a3,104(sp)
    80200510:	7746                	ld	a4,112(sp)
    80200512:	77e6                	ld	a5,120(sp)
    80200514:	680a                	ld	a6,128(sp)
    80200516:	68aa                	ld	a7,136(sp)
    80200518:	694a                	ld	s2,144(sp)
    8020051a:	69ea                	ld	s3,152(sp)
    8020051c:	7a0a                	ld	s4,160(sp)
    8020051e:	7aaa                	ld	s5,168(sp)
    80200520:	7b4a                	ld	s6,176(sp)
    80200522:	7bea                	ld	s7,184(sp)
    80200524:	6c0e                	ld	s8,192(sp)
    80200526:	6cae                	ld	s9,200(sp)
    80200528:	6d4e                	ld	s10,208(sp)
    8020052a:	6dee                	ld	s11,216(sp)
    8020052c:	7e0e                	ld	t3,224(sp)
    8020052e:	7eae                	ld	t4,232(sp)
    80200530:	7f4e                	ld	t5,240(sp)
    80200532:	7fee                	ld	t6,248(sp)
    80200534:	6142                	ld	sp,16(sp)
    80200536:	10200073          	sret

000000008020053a <printnum>:
    8020053a:	02069813          	slli	a6,a3,0x20
    8020053e:	7179                	addi	sp,sp,-48
    80200540:	02085813          	srli	a6,a6,0x20
    80200544:	e052                	sd	s4,0(sp)
    80200546:	03067a33          	remu	s4,a2,a6
    8020054a:	f022                	sd	s0,32(sp)
    8020054c:	ec26                	sd	s1,24(sp)
    8020054e:	e84a                	sd	s2,16(sp)
    80200550:	f406                	sd	ra,40(sp)
    80200552:	e44e                	sd	s3,8(sp)
    80200554:	84aa                	mv	s1,a0
    80200556:	892e                	mv	s2,a1
    80200558:	fff7041b          	addiw	s0,a4,-1
    8020055c:	2a01                	sext.w	s4,s4
    8020055e:	03067f63          	bgeu	a2,a6,8020059c <printnum+0x62>
    80200562:	89be                	mv	s3,a5
    80200564:	4785                	li	a5,1
    80200566:	00e7d763          	bge	a5,a4,80200574 <printnum+0x3a>
    8020056a:	347d                	addiw	s0,s0,-1
    8020056c:	85ca                	mv	a1,s2
    8020056e:	854e                	mv	a0,s3
    80200570:	9482                	jalr	s1
    80200572:	fc65                	bnez	s0,8020056a <printnum+0x30>
    80200574:	1a02                	slli	s4,s4,0x20
    80200576:	020a5a13          	srli	s4,s4,0x20
    8020057a:	00001797          	auipc	a5,0x1
    8020057e:	99678793          	addi	a5,a5,-1642 # 80200f10 <etext+0x570>
    80200582:	97d2                	add	a5,a5,s4
    80200584:	7402                	ld	s0,32(sp)
    80200586:	0007c503          	lbu	a0,0(a5)
    8020058a:	70a2                	ld	ra,40(sp)
    8020058c:	69a2                	ld	s3,8(sp)
    8020058e:	6a02                	ld	s4,0(sp)
    80200590:	85ca                	mv	a1,s2
    80200592:	87a6                	mv	a5,s1
    80200594:	6942                	ld	s2,16(sp)
    80200596:	64e2                	ld	s1,24(sp)
    80200598:	6145                	addi	sp,sp,48
    8020059a:	8782                	jr	a5
    8020059c:	03065633          	divu	a2,a2,a6
    802005a0:	8722                	mv	a4,s0
    802005a2:	f99ff0ef          	jal	ra,8020053a <printnum>
    802005a6:	b7f9                	j	80200574 <printnum+0x3a>

00000000802005a8 <vprintfmt>:
    802005a8:	7119                	addi	sp,sp,-128
    802005aa:	f4a6                	sd	s1,104(sp)
    802005ac:	f0ca                	sd	s2,96(sp)
    802005ae:	ecce                	sd	s3,88(sp)
    802005b0:	e8d2                	sd	s4,80(sp)
    802005b2:	e4d6                	sd	s5,72(sp)
    802005b4:	e0da                	sd	s6,64(sp)
    802005b6:	f862                	sd	s8,48(sp)
    802005b8:	fc86                	sd	ra,120(sp)
    802005ba:	f8a2                	sd	s0,112(sp)
    802005bc:	fc5e                	sd	s7,56(sp)
    802005be:	f466                	sd	s9,40(sp)
    802005c0:	f06a                	sd	s10,32(sp)
    802005c2:	ec6e                	sd	s11,24(sp)
    802005c4:	892a                	mv	s2,a0
    802005c6:	84ae                	mv	s1,a1
    802005c8:	8c32                	mv	s8,a2
    802005ca:	8a36                	mv	s4,a3
    802005cc:	02500993          	li	s3,37
    802005d0:	05500b13          	li	s6,85
    802005d4:	00001a97          	auipc	s5,0x1
    802005d8:	970a8a93          	addi	s5,s5,-1680 # 80200f44 <etext+0x5a4>
    802005dc:	000c4503          	lbu	a0,0(s8)
    802005e0:	001c0413          	addi	s0,s8,1
    802005e4:	01350a63          	beq	a0,s3,802005f8 <vprintfmt+0x50>
    802005e8:	cd0d                	beqz	a0,80200622 <vprintfmt+0x7a>
    802005ea:	85a6                	mv	a1,s1
    802005ec:	0405                	addi	s0,s0,1
    802005ee:	9902                	jalr	s2
    802005f0:	fff44503          	lbu	a0,-1(s0)
    802005f4:	ff351ae3          	bne	a0,s3,802005e8 <vprintfmt+0x40>
    802005f8:	02000d93          	li	s11,32
    802005fc:	4b81                	li	s7,0
    802005fe:	4601                	li	a2,0
    80200600:	5d7d                	li	s10,-1
    80200602:	5cfd                	li	s9,-1
    80200604:	00044683          	lbu	a3,0(s0)
    80200608:	00140c13          	addi	s8,s0,1
    8020060c:	fdd6859b          	addiw	a1,a3,-35
    80200610:	0ff5f593          	andi	a1,a1,255
    80200614:	02bb6663          	bltu	s6,a1,80200640 <vprintfmt+0x98>
    80200618:	058a                	slli	a1,a1,0x2
    8020061a:	95d6                	add	a1,a1,s5
    8020061c:	4198                	lw	a4,0(a1)
    8020061e:	9756                	add	a4,a4,s5
    80200620:	8702                	jr	a4
    80200622:	70e6                	ld	ra,120(sp)
    80200624:	7446                	ld	s0,112(sp)
    80200626:	74a6                	ld	s1,104(sp)
    80200628:	7906                	ld	s2,96(sp)
    8020062a:	69e6                	ld	s3,88(sp)
    8020062c:	6a46                	ld	s4,80(sp)
    8020062e:	6aa6                	ld	s5,72(sp)
    80200630:	6b06                	ld	s6,64(sp)
    80200632:	7be2                	ld	s7,56(sp)
    80200634:	7c42                	ld	s8,48(sp)
    80200636:	7ca2                	ld	s9,40(sp)
    80200638:	7d02                	ld	s10,32(sp)
    8020063a:	6de2                	ld	s11,24(sp)
    8020063c:	6109                	addi	sp,sp,128
    8020063e:	8082                	ret
    80200640:	85a6                	mv	a1,s1
    80200642:	02500513          	li	a0,37
    80200646:	9902                	jalr	s2
    80200648:	fff44703          	lbu	a4,-1(s0)
    8020064c:	02500793          	li	a5,37
    80200650:	8c22                	mv	s8,s0
    80200652:	f8f705e3          	beq	a4,a5,802005dc <vprintfmt+0x34>
    80200656:	02500713          	li	a4,37
    8020065a:	ffec4783          	lbu	a5,-2(s8)
    8020065e:	1c7d                	addi	s8,s8,-1
    80200660:	fee79de3          	bne	a5,a4,8020065a <vprintfmt+0xb2>
    80200664:	bfa5                	j	802005dc <vprintfmt+0x34>
    80200666:	00144783          	lbu	a5,1(s0)
    8020066a:	4725                	li	a4,9
    8020066c:	fd068d1b          	addiw	s10,a3,-48
    80200670:	fd07859b          	addiw	a1,a5,-48
    80200674:	0007869b          	sext.w	a3,a5
    80200678:	8462                	mv	s0,s8
    8020067a:	02b76563          	bltu	a4,a1,802006a4 <vprintfmt+0xfc>
    8020067e:	4525                	li	a0,9
    80200680:	00144783          	lbu	a5,1(s0)
    80200684:	002d171b          	slliw	a4,s10,0x2
    80200688:	01a7073b          	addw	a4,a4,s10
    8020068c:	0017171b          	slliw	a4,a4,0x1
    80200690:	9f35                	addw	a4,a4,a3
    80200692:	fd07859b          	addiw	a1,a5,-48
    80200696:	0405                	addi	s0,s0,1
    80200698:	fd070d1b          	addiw	s10,a4,-48
    8020069c:	0007869b          	sext.w	a3,a5
    802006a0:	feb570e3          	bgeu	a0,a1,80200680 <vprintfmt+0xd8>
    802006a4:	f60cd0e3          	bgez	s9,80200604 <vprintfmt+0x5c>
    802006a8:	8cea                	mv	s9,s10
    802006aa:	5d7d                	li	s10,-1
    802006ac:	bfa1                	j	80200604 <vprintfmt+0x5c>
    802006ae:	8db6                	mv	s11,a3
    802006b0:	8462                	mv	s0,s8
    802006b2:	bf89                	j	80200604 <vprintfmt+0x5c>
    802006b4:	8462                	mv	s0,s8
    802006b6:	4b85                	li	s7,1
    802006b8:	b7b1                	j	80200604 <vprintfmt+0x5c>
    802006ba:	4785                	li	a5,1
    802006bc:	008a0713          	addi	a4,s4,8
    802006c0:	00c7c463          	blt	a5,a2,802006c8 <vprintfmt+0x120>
    802006c4:	1a060263          	beqz	a2,80200868 <vprintfmt+0x2c0>
    802006c8:	000a3603          	ld	a2,0(s4)
    802006cc:	46c1                	li	a3,16
    802006ce:	8a3a                	mv	s4,a4
    802006d0:	000d879b          	sext.w	a5,s11
    802006d4:	8766                	mv	a4,s9
    802006d6:	85a6                	mv	a1,s1
    802006d8:	854a                	mv	a0,s2
    802006da:	e61ff0ef          	jal	ra,8020053a <printnum>
    802006de:	bdfd                	j	802005dc <vprintfmt+0x34>
    802006e0:	000a2503          	lw	a0,0(s4)
    802006e4:	85a6                	mv	a1,s1
    802006e6:	0a21                	addi	s4,s4,8
    802006e8:	9902                	jalr	s2
    802006ea:	bdcd                	j	802005dc <vprintfmt+0x34>
    802006ec:	4785                	li	a5,1
    802006ee:	008a0713          	addi	a4,s4,8
    802006f2:	00c7c463          	blt	a5,a2,802006fa <vprintfmt+0x152>
    802006f6:	16060463          	beqz	a2,8020085e <vprintfmt+0x2b6>
    802006fa:	000a3603          	ld	a2,0(s4)
    802006fe:	46a9                	li	a3,10
    80200700:	8a3a                	mv	s4,a4
    80200702:	b7f9                	j	802006d0 <vprintfmt+0x128>
    80200704:	03000513          	li	a0,48
    80200708:	85a6                	mv	a1,s1
    8020070a:	9902                	jalr	s2
    8020070c:	85a6                	mv	a1,s1
    8020070e:	07800513          	li	a0,120
    80200712:	9902                	jalr	s2
    80200714:	0a21                	addi	s4,s4,8
    80200716:	46c1                	li	a3,16
    80200718:	ff8a3603          	ld	a2,-8(s4)
    8020071c:	bf55                	j	802006d0 <vprintfmt+0x128>
    8020071e:	85a6                	mv	a1,s1
    80200720:	02500513          	li	a0,37
    80200724:	9902                	jalr	s2
    80200726:	bd5d                	j	802005dc <vprintfmt+0x34>
    80200728:	000a2d03          	lw	s10,0(s4)
    8020072c:	8462                	mv	s0,s8
    8020072e:	0a21                	addi	s4,s4,8
    80200730:	bf95                	j	802006a4 <vprintfmt+0xfc>
    80200732:	4785                	li	a5,1
    80200734:	008a0713          	addi	a4,s4,8
    80200738:	00c7c463          	blt	a5,a2,80200740 <vprintfmt+0x198>
    8020073c:	10060c63          	beqz	a2,80200854 <vprintfmt+0x2ac>
    80200740:	000a3603          	ld	a2,0(s4)
    80200744:	46a1                	li	a3,8
    80200746:	8a3a                	mv	s4,a4
    80200748:	b761                	j	802006d0 <vprintfmt+0x128>
    8020074a:	fffcc793          	not	a5,s9
    8020074e:	97fd                	srai	a5,a5,0x3f
    80200750:	00fcf7b3          	and	a5,s9,a5
    80200754:	00078c9b          	sext.w	s9,a5
    80200758:	8462                	mv	s0,s8
    8020075a:	b56d                	j	80200604 <vprintfmt+0x5c>
    8020075c:	000a3403          	ld	s0,0(s4)
    80200760:	008a0793          	addi	a5,s4,8
    80200764:	e43e                	sd	a5,8(sp)
    80200766:	12040163          	beqz	s0,80200888 <vprintfmt+0x2e0>
    8020076a:	0d905963          	blez	s9,8020083c <vprintfmt+0x294>
    8020076e:	02d00793          	li	a5,45
    80200772:	00140a13          	addi	s4,s0,1
    80200776:	12fd9863          	bne	s11,a5,802008a6 <vprintfmt+0x2fe>
    8020077a:	00044783          	lbu	a5,0(s0)
    8020077e:	0007851b          	sext.w	a0,a5
    80200782:	cb9d                	beqz	a5,802007b8 <vprintfmt+0x210>
    80200784:	547d                	li	s0,-1
    80200786:	05e00d93          	li	s11,94
    8020078a:	000d4563          	bltz	s10,80200794 <vprintfmt+0x1ec>
    8020078e:	3d7d                	addiw	s10,s10,-1
    80200790:	028d0263          	beq	s10,s0,802007b4 <vprintfmt+0x20c>
    80200794:	85a6                	mv	a1,s1
    80200796:	0c0b8e63          	beqz	s7,80200872 <vprintfmt+0x2ca>
    8020079a:	3781                	addiw	a5,a5,-32
    8020079c:	0cfdfb63          	bgeu	s11,a5,80200872 <vprintfmt+0x2ca>
    802007a0:	03f00513          	li	a0,63
    802007a4:	9902                	jalr	s2
    802007a6:	000a4783          	lbu	a5,0(s4)
    802007aa:	3cfd                	addiw	s9,s9,-1
    802007ac:	0a05                	addi	s4,s4,1
    802007ae:	0007851b          	sext.w	a0,a5
    802007b2:	ffe1                	bnez	a5,8020078a <vprintfmt+0x1e2>
    802007b4:	01905963          	blez	s9,802007c6 <vprintfmt+0x21e>
    802007b8:	3cfd                	addiw	s9,s9,-1
    802007ba:	85a6                	mv	a1,s1
    802007bc:	02000513          	li	a0,32
    802007c0:	9902                	jalr	s2
    802007c2:	fe0c9be3          	bnez	s9,802007b8 <vprintfmt+0x210>
    802007c6:	6a22                	ld	s4,8(sp)
    802007c8:	bd11                	j	802005dc <vprintfmt+0x34>
    802007ca:	4785                	li	a5,1
    802007cc:	008a0b93          	addi	s7,s4,8
    802007d0:	00c7c363          	blt	a5,a2,802007d6 <vprintfmt+0x22e>
    802007d4:	ce2d                	beqz	a2,8020084e <vprintfmt+0x2a6>
    802007d6:	000a3403          	ld	s0,0(s4)
    802007da:	08044e63          	bltz	s0,80200876 <vprintfmt+0x2ce>
    802007de:	8622                	mv	a2,s0
    802007e0:	8a5e                	mv	s4,s7
    802007e2:	46a9                	li	a3,10
    802007e4:	b5f5                	j	802006d0 <vprintfmt+0x128>
    802007e6:	000a2783          	lw	a5,0(s4)
    802007ea:	4619                	li	a2,6
    802007ec:	41f7d71b          	sraiw	a4,a5,0x1f
    802007f0:	8fb9                	xor	a5,a5,a4
    802007f2:	40e786bb          	subw	a3,a5,a4
    802007f6:	02d64663          	blt	a2,a3,80200822 <vprintfmt+0x27a>
    802007fa:	00369713          	slli	a4,a3,0x3
    802007fe:	00001797          	auipc	a5,0x1
    80200802:	92278793          	addi	a5,a5,-1758 # 80201120 <error_string>
    80200806:	97ba                	add	a5,a5,a4
    80200808:	639c                	ld	a5,0(a5)
    8020080a:	cf81                	beqz	a5,80200822 <vprintfmt+0x27a>
    8020080c:	86be                	mv	a3,a5
    8020080e:	00000617          	auipc	a2,0x0
    80200812:	73260613          	addi	a2,a2,1842 # 80200f40 <etext+0x5a0>
    80200816:	85a6                	mv	a1,s1
    80200818:	854a                	mv	a0,s2
    8020081a:	0ea000ef          	jal	ra,80200904 <printfmt>
    8020081e:	0a21                	addi	s4,s4,8
    80200820:	bb75                	j	802005dc <vprintfmt+0x34>
    80200822:	00000617          	auipc	a2,0x0
    80200826:	70e60613          	addi	a2,a2,1806 # 80200f30 <etext+0x590>
    8020082a:	85a6                	mv	a1,s1
    8020082c:	854a                	mv	a0,s2
    8020082e:	0d6000ef          	jal	ra,80200904 <printfmt>
    80200832:	0a21                	addi	s4,s4,8
    80200834:	b365                	j	802005dc <vprintfmt+0x34>
    80200836:	2605                	addiw	a2,a2,1
    80200838:	8462                	mv	s0,s8
    8020083a:	b3e9                	j	80200604 <vprintfmt+0x5c>
    8020083c:	00044783          	lbu	a5,0(s0)
    80200840:	00140a13          	addi	s4,s0,1
    80200844:	0007851b          	sext.w	a0,a5
    80200848:	ff95                	bnez	a5,80200784 <vprintfmt+0x1dc>
    8020084a:	6a22                	ld	s4,8(sp)
    8020084c:	bb41                	j	802005dc <vprintfmt+0x34>
    8020084e:	000a2403          	lw	s0,0(s4)
    80200852:	b761                	j	802007da <vprintfmt+0x232>
    80200854:	000a6603          	lwu	a2,0(s4)
    80200858:	46a1                	li	a3,8
    8020085a:	8a3a                	mv	s4,a4
    8020085c:	bd95                	j	802006d0 <vprintfmt+0x128>
    8020085e:	000a6603          	lwu	a2,0(s4)
    80200862:	46a9                	li	a3,10
    80200864:	8a3a                	mv	s4,a4
    80200866:	b5ad                	j	802006d0 <vprintfmt+0x128>
    80200868:	000a6603          	lwu	a2,0(s4)
    8020086c:	46c1                	li	a3,16
    8020086e:	8a3a                	mv	s4,a4
    80200870:	b585                	j	802006d0 <vprintfmt+0x128>
    80200872:	9902                	jalr	s2
    80200874:	bf0d                	j	802007a6 <vprintfmt+0x1fe>
    80200876:	85a6                	mv	a1,s1
    80200878:	02d00513          	li	a0,45
    8020087c:	9902                	jalr	s2
    8020087e:	8a5e                	mv	s4,s7
    80200880:	40800633          	neg	a2,s0
    80200884:	46a9                	li	a3,10
    80200886:	b5a9                	j	802006d0 <vprintfmt+0x128>
    80200888:	01905663          	blez	s9,80200894 <vprintfmt+0x2ec>
    8020088c:	02d00793          	li	a5,45
    80200890:	04fd9263          	bne	s11,a5,802008d4 <vprintfmt+0x32c>
    80200894:	00000a17          	auipc	s4,0x0
    80200898:	695a0a13          	addi	s4,s4,1685 # 80200f29 <etext+0x589>
    8020089c:	02800513          	li	a0,40
    802008a0:	02800793          	li	a5,40
    802008a4:	b5c5                	j	80200784 <vprintfmt+0x1dc>
    802008a6:	85ea                	mv	a1,s10
    802008a8:	8522                	mv	a0,s0
    802008aa:	0c8000ef          	jal	ra,80200972 <strnlen>
    802008ae:	40ac8cbb          	subw	s9,s9,a0
    802008b2:	01905963          	blez	s9,802008c4 <vprintfmt+0x31c>
    802008b6:	2d81                	sext.w	s11,s11
    802008b8:	3cfd                	addiw	s9,s9,-1
    802008ba:	85a6                	mv	a1,s1
    802008bc:	856e                	mv	a0,s11
    802008be:	9902                	jalr	s2
    802008c0:	fe0c9ce3          	bnez	s9,802008b8 <vprintfmt+0x310>
    802008c4:	00044783          	lbu	a5,0(s0)
    802008c8:	0007851b          	sext.w	a0,a5
    802008cc:	ea079ce3          	bnez	a5,80200784 <vprintfmt+0x1dc>
    802008d0:	6a22                	ld	s4,8(sp)
    802008d2:	b329                	j	802005dc <vprintfmt+0x34>
    802008d4:	85ea                	mv	a1,s10
    802008d6:	00000517          	auipc	a0,0x0
    802008da:	65250513          	addi	a0,a0,1618 # 80200f28 <etext+0x588>
    802008de:	094000ef          	jal	ra,80200972 <strnlen>
    802008e2:	40ac8cbb          	subw	s9,s9,a0
    802008e6:	00000a17          	auipc	s4,0x0
    802008ea:	643a0a13          	addi	s4,s4,1603 # 80200f29 <etext+0x589>
    802008ee:	00000417          	auipc	s0,0x0
    802008f2:	63a40413          	addi	s0,s0,1594 # 80200f28 <etext+0x588>
    802008f6:	02800513          	li	a0,40
    802008fa:	02800793          	li	a5,40
    802008fe:	fb904ce3          	bgtz	s9,802008b6 <vprintfmt+0x30e>
    80200902:	b549                	j	80200784 <vprintfmt+0x1dc>

0000000080200904 <printfmt>:
    80200904:	715d                	addi	sp,sp,-80
    80200906:	02810313          	addi	t1,sp,40
    8020090a:	f436                	sd	a3,40(sp)
    8020090c:	869a                	mv	a3,t1
    8020090e:	ec06                	sd	ra,24(sp)
    80200910:	f83a                	sd	a4,48(sp)
    80200912:	fc3e                	sd	a5,56(sp)
    80200914:	e0c2                	sd	a6,64(sp)
    80200916:	e4c6                	sd	a7,72(sp)
    80200918:	e41a                	sd	t1,8(sp)
    8020091a:	c8fff0ef          	jal	ra,802005a8 <vprintfmt>
    8020091e:	60e2                	ld	ra,24(sp)
    80200920:	6161                	addi	sp,sp,80
    80200922:	8082                	ret

0000000080200924 <sbi_console_putchar>:
    80200924:	4781                	li	a5,0
    80200926:	00003717          	auipc	a4,0x3
    8020092a:	6e273703          	ld	a4,1762(a4) # 80204008 <SBI_CONSOLE_PUTCHAR>
    8020092e:	88ba                	mv	a7,a4
    80200930:	852a                	mv	a0,a0
    80200932:	85be                	mv	a1,a5
    80200934:	863e                	mv	a2,a5
    80200936:	00000073          	ecall
    8020093a:	87aa                	mv	a5,a0
    8020093c:	8082                	ret

000000008020093e <sbi_set_timer>:
    8020093e:	4781                	li	a5,0
    80200940:	00003717          	auipc	a4,0x3
    80200944:	6e073703          	ld	a4,1760(a4) # 80204020 <SBI_SET_TIMER>
    80200948:	88ba                	mv	a7,a4
    8020094a:	852a                	mv	a0,a0
    8020094c:	85be                	mv	a1,a5
    8020094e:	863e                	mv	a2,a5
    80200950:	00000073          	ecall
    80200954:	87aa                	mv	a5,a0
    80200956:	8082                	ret

0000000080200958 <sbi_shutdown>:
    80200958:	4781                	li	a5,0
    8020095a:	00003717          	auipc	a4,0x3
    8020095e:	6a673703          	ld	a4,1702(a4) # 80204000 <SBI_SHUTDOWN>
    80200962:	88ba                	mv	a7,a4
    80200964:	853e                	mv	a0,a5
    80200966:	85be                	mv	a1,a5
    80200968:	863e                	mv	a2,a5
    8020096a:	00000073          	ecall
    8020096e:	87aa                	mv	a5,a0
    80200970:	8082                	ret

0000000080200972 <strnlen>:
    80200972:	4781                	li	a5,0
    80200974:	e589                	bnez	a1,8020097e <strnlen+0xc>
    80200976:	a811                	j	8020098a <strnlen+0x18>
    80200978:	0785                	addi	a5,a5,1
    8020097a:	00f58863          	beq	a1,a5,8020098a <strnlen+0x18>
    8020097e:	00f50733          	add	a4,a0,a5
    80200982:	00074703          	lbu	a4,0(a4)
    80200986:	fb6d                	bnez	a4,80200978 <strnlen+0x6>
    80200988:	85be                	mv	a1,a5
    8020098a:	852e                	mv	a0,a1
    8020098c:	8082                	ret

000000008020098e <memset>:
    8020098e:	ca01                	beqz	a2,8020099e <memset+0x10>
    80200990:	962a                	add	a2,a2,a0
    80200992:	87aa                	mv	a5,a0
    80200994:	0785                	addi	a5,a5,1
    80200996:	feb78fa3          	sb	a1,-1(a5)
    8020099a:	fec79de3          	bne	a5,a2,80200994 <memset+0x6>
    8020099e:	8082                	ret
