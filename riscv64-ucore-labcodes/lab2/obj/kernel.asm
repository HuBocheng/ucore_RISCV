
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址，lui加载高20位进入t0，低12位为页内偏移量我们不需要
    # boot_page_table_sv39 是一个全局符号，它指向系统启动时使用的页表的开始位置
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号（物理地址右移12位得到物理页号）
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39 39位虚拟地址模式
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
ffffffffc0200032:	00006517          	auipc	a0,0x6
ffffffffc0200036:	fe650513          	addi	a0,a0,-26 # ffffffffc0206018 <buf>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	52e60613          	addi	a2,a2,1326 # ffffffffc0206568 <end>
ffffffffc0200042:	1141                	addi	sp,sp,-16
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
ffffffffc0200048:	e406                	sd	ra,8(sp)
ffffffffc020004a:	1ab010ef          	jal	ra,ffffffffc02019f4 <memset>
ffffffffc020004e:	3f8000ef          	jal	ra,ffffffffc0200446 <cons_init>
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	9b650513          	addi	a0,a0,-1610 # ffffffffc0201a08 <etext+0x2>
ffffffffc020005a:	08e000ef          	jal	ra,ffffffffc02000e8 <cputs>
ffffffffc020005e:	0da000ef          	jal	ra,ffffffffc0200138 <print_kerninfo>
ffffffffc0200062:	3fe000ef          	jal	ra,ffffffffc0200460 <idt_init>
ffffffffc0200066:	0b8010ef          	jal	ra,ffffffffc020111e <pmm_init>
ffffffffc020006a:	3f6000ef          	jal	ra,ffffffffc0200460 <idt_init>
ffffffffc020006e:	396000ef          	jal	ra,ffffffffc0200404 <clock_init>
ffffffffc0200072:	3e2000ef          	jal	ra,ffffffffc0200454 <intr_enable>
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x44>

ffffffffc0200078 <cputch>:
ffffffffc0200078:	1141                	addi	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
ffffffffc0200080:	3c8000ef          	jal	ra,ffffffffc0200448 <cons_putc>
ffffffffc0200084:	401c                	lw	a5,0(s0)
ffffffffc0200086:	60a2                	ld	ra,8(sp)
ffffffffc0200088:	2785                	addiw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	addi	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
ffffffffc0200092:	1101                	addi	sp,sp,-32
ffffffffc0200094:	86ae                	mv	a3,a1
ffffffffc0200096:	862a                	mv	a2,a0
ffffffffc0200098:	006c                	addi	a1,sp,12
ffffffffc020009a:	00000517          	auipc	a0,0x0
ffffffffc020009e:	fde50513          	addi	a0,a0,-34 # ffffffffc0200078 <cputch>
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
ffffffffc02000a4:	c602                	sw	zero,12(sp)
ffffffffc02000a6:	424010ef          	jal	ra,ffffffffc02014ca <vprintfmt>
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	addi	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
ffffffffc02000b2:	711d                	addi	sp,sp,-96
ffffffffc02000b4:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
ffffffffc02000b8:	f42e                	sd	a1,40(sp)
ffffffffc02000ba:	f832                	sd	a2,48(sp)
ffffffffc02000bc:	fc36                	sd	a3,56(sp)
ffffffffc02000be:	862a                	mv	a2,a0
ffffffffc02000c0:	004c                	addi	a1,sp,4
ffffffffc02000c2:	00000517          	auipc	a0,0x0
ffffffffc02000c6:	fb650513          	addi	a0,a0,-74 # ffffffffc0200078 <cputch>
ffffffffc02000ca:	869a                	mv	a3,t1
ffffffffc02000cc:	ec06                	sd	ra,24(sp)
ffffffffc02000ce:	e0ba                	sd	a4,64(sp)
ffffffffc02000d0:	e4be                	sd	a5,72(sp)
ffffffffc02000d2:	e8c2                	sd	a6,80(sp)
ffffffffc02000d4:	ecc6                	sd	a7,88(sp)
ffffffffc02000d6:	e41a                	sd	t1,8(sp)
ffffffffc02000d8:	c202                	sw	zero,4(sp)
ffffffffc02000da:	3f0010ef          	jal	ra,ffffffffc02014ca <vprintfmt>
ffffffffc02000de:	60e2                	ld	ra,24(sp)
ffffffffc02000e0:	4512                	lw	a0,4(sp)
ffffffffc02000e2:	6125                	addi	sp,sp,96
ffffffffc02000e4:	8082                	ret

ffffffffc02000e6 <cputchar>:
ffffffffc02000e6:	a68d                	j	ffffffffc0200448 <cons_putc>

ffffffffc02000e8 <cputs>:
ffffffffc02000e8:	1101                	addi	sp,sp,-32
ffffffffc02000ea:	e822                	sd	s0,16(sp)
ffffffffc02000ec:	ec06                	sd	ra,24(sp)
ffffffffc02000ee:	e426                	sd	s1,8(sp)
ffffffffc02000f0:	842a                	mv	s0,a0
ffffffffc02000f2:	00054503          	lbu	a0,0(a0)
ffffffffc02000f6:	c51d                	beqz	a0,ffffffffc0200124 <cputs+0x3c>
ffffffffc02000f8:	0405                	addi	s0,s0,1
ffffffffc02000fa:	4485                	li	s1,1
ffffffffc02000fc:	9c81                	subw	s1,s1,s0
ffffffffc02000fe:	34a000ef          	jal	ra,ffffffffc0200448 <cons_putc>
ffffffffc0200102:	008487bb          	addw	a5,s1,s0
ffffffffc0200106:	0405                	addi	s0,s0,1
ffffffffc0200108:	fff44503          	lbu	a0,-1(s0)
ffffffffc020010c:	f96d                	bnez	a0,ffffffffc02000fe <cputs+0x16>
ffffffffc020010e:	0017841b          	addiw	s0,a5,1
ffffffffc0200112:	4529                	li	a0,10
ffffffffc0200114:	334000ef          	jal	ra,ffffffffc0200448 <cons_putc>
ffffffffc0200118:	8522                	mv	a0,s0
ffffffffc020011a:	60e2                	ld	ra,24(sp)
ffffffffc020011c:	6442                	ld	s0,16(sp)
ffffffffc020011e:	64a2                	ld	s1,8(sp)
ffffffffc0200120:	6105                	addi	sp,sp,32
ffffffffc0200122:	8082                	ret
ffffffffc0200124:	4405                	li	s0,1
ffffffffc0200126:	b7f5                	j	ffffffffc0200112 <cputs+0x2a>

ffffffffc0200128 <getchar>:
ffffffffc0200128:	1141                	addi	sp,sp,-16
ffffffffc020012a:	e406                	sd	ra,8(sp)
ffffffffc020012c:	324000ef          	jal	ra,ffffffffc0200450 <cons_getc>
ffffffffc0200130:	dd75                	beqz	a0,ffffffffc020012c <getchar+0x4>
ffffffffc0200132:	60a2                	ld	ra,8(sp)
ffffffffc0200134:	0141                	addi	sp,sp,16
ffffffffc0200136:	8082                	ret

ffffffffc0200138 <print_kerninfo>:
ffffffffc0200138:	1141                	addi	sp,sp,-16
ffffffffc020013a:	00002517          	auipc	a0,0x2
ffffffffc020013e:	91e50513          	addi	a0,a0,-1762 # ffffffffc0201a58 <etext+0x52>
ffffffffc0200142:	e406                	sd	ra,8(sp)
ffffffffc0200144:	f6fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200148:	00000597          	auipc	a1,0x0
ffffffffc020014c:	eea58593          	addi	a1,a1,-278 # ffffffffc0200032 <kern_init>
ffffffffc0200150:	00002517          	auipc	a0,0x2
ffffffffc0200154:	92850513          	addi	a0,a0,-1752 # ffffffffc0201a78 <etext+0x72>
ffffffffc0200158:	f5bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020015c:	00002597          	auipc	a1,0x2
ffffffffc0200160:	8aa58593          	addi	a1,a1,-1878 # ffffffffc0201a06 <etext>
ffffffffc0200164:	00002517          	auipc	a0,0x2
ffffffffc0200168:	93450513          	addi	a0,a0,-1740 # ffffffffc0201a98 <etext+0x92>
ffffffffc020016c:	f47ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200170:	00006597          	auipc	a1,0x6
ffffffffc0200174:	ea858593          	addi	a1,a1,-344 # ffffffffc0206018 <buf>
ffffffffc0200178:	00002517          	auipc	a0,0x2
ffffffffc020017c:	94050513          	addi	a0,a0,-1728 # ffffffffc0201ab8 <etext+0xb2>
ffffffffc0200180:	f33ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200184:	00006597          	auipc	a1,0x6
ffffffffc0200188:	3e458593          	addi	a1,a1,996 # ffffffffc0206568 <end>
ffffffffc020018c:	00002517          	auipc	a0,0x2
ffffffffc0200190:	94c50513          	addi	a0,a0,-1716 # ffffffffc0201ad8 <etext+0xd2>
ffffffffc0200194:	f1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200198:	00006597          	auipc	a1,0x6
ffffffffc020019c:	7cf58593          	addi	a1,a1,1999 # ffffffffc0206967 <end+0x3ff>
ffffffffc02001a0:	00000797          	auipc	a5,0x0
ffffffffc02001a4:	e9278793          	addi	a5,a5,-366 # ffffffffc0200032 <kern_init>
ffffffffc02001a8:	40f587b3          	sub	a5,a1,a5
ffffffffc02001ac:	43f7d593          	srai	a1,a5,0x3f
ffffffffc02001b0:	60a2                	ld	ra,8(sp)
ffffffffc02001b2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001b6:	95be                	add	a1,a1,a5
ffffffffc02001b8:	85a9                	srai	a1,a1,0xa
ffffffffc02001ba:	00002517          	auipc	a0,0x2
ffffffffc02001be:	93e50513          	addi	a0,a0,-1730 # ffffffffc0201af8 <etext+0xf2>
ffffffffc02001c2:	0141                	addi	sp,sp,16
ffffffffc02001c4:	b5fd                	j	ffffffffc02000b2 <cprintf>

ffffffffc02001c6 <print_stackframe>:
ffffffffc02001c6:	1141                	addi	sp,sp,-16
ffffffffc02001c8:	00002617          	auipc	a2,0x2
ffffffffc02001cc:	86060613          	addi	a2,a2,-1952 # ffffffffc0201a28 <etext+0x22>
ffffffffc02001d0:	04e00593          	li	a1,78
ffffffffc02001d4:	00002517          	auipc	a0,0x2
ffffffffc02001d8:	86c50513          	addi	a0,a0,-1940 # ffffffffc0201a40 <etext+0x3a>
ffffffffc02001dc:	e406                	sd	ra,8(sp)
ffffffffc02001de:	1c6000ef          	jal	ra,ffffffffc02003a4 <__panic>

ffffffffc02001e2 <mon_help>:
ffffffffc02001e2:	1141                	addi	sp,sp,-16
ffffffffc02001e4:	00002617          	auipc	a2,0x2
ffffffffc02001e8:	a2460613          	addi	a2,a2,-1500 # ffffffffc0201c08 <commands+0xe0>
ffffffffc02001ec:	00002597          	auipc	a1,0x2
ffffffffc02001f0:	a3c58593          	addi	a1,a1,-1476 # ffffffffc0201c28 <commands+0x100>
ffffffffc02001f4:	00002517          	auipc	a0,0x2
ffffffffc02001f8:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0201c30 <commands+0x108>
ffffffffc02001fc:	e406                	sd	ra,8(sp)
ffffffffc02001fe:	eb5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200202:	00002617          	auipc	a2,0x2
ffffffffc0200206:	a3e60613          	addi	a2,a2,-1474 # ffffffffc0201c40 <commands+0x118>
ffffffffc020020a:	00002597          	auipc	a1,0x2
ffffffffc020020e:	a5e58593          	addi	a1,a1,-1442 # ffffffffc0201c68 <commands+0x140>
ffffffffc0200212:	00002517          	auipc	a0,0x2
ffffffffc0200216:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0201c30 <commands+0x108>
ffffffffc020021a:	e99ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020021e:	00002617          	auipc	a2,0x2
ffffffffc0200222:	a5a60613          	addi	a2,a2,-1446 # ffffffffc0201c78 <commands+0x150>
ffffffffc0200226:	00002597          	auipc	a1,0x2
ffffffffc020022a:	a7258593          	addi	a1,a1,-1422 # ffffffffc0201c98 <commands+0x170>
ffffffffc020022e:	00002517          	auipc	a0,0x2
ffffffffc0200232:	a0250513          	addi	a0,a0,-1534 # ffffffffc0201c30 <commands+0x108>
ffffffffc0200236:	e7dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020023a:	60a2                	ld	ra,8(sp)
ffffffffc020023c:	4501                	li	a0,0
ffffffffc020023e:	0141                	addi	sp,sp,16
ffffffffc0200240:	8082                	ret

ffffffffc0200242 <mon_kerninfo>:
ffffffffc0200242:	1141                	addi	sp,sp,-16
ffffffffc0200244:	e406                	sd	ra,8(sp)
ffffffffc0200246:	ef3ff0ef          	jal	ra,ffffffffc0200138 <print_kerninfo>
ffffffffc020024a:	60a2                	ld	ra,8(sp)
ffffffffc020024c:	4501                	li	a0,0
ffffffffc020024e:	0141                	addi	sp,sp,16
ffffffffc0200250:	8082                	ret

ffffffffc0200252 <mon_backtrace>:
ffffffffc0200252:	1141                	addi	sp,sp,-16
ffffffffc0200254:	e406                	sd	ra,8(sp)
ffffffffc0200256:	f71ff0ef          	jal	ra,ffffffffc02001c6 <print_stackframe>
ffffffffc020025a:	60a2                	ld	ra,8(sp)
ffffffffc020025c:	4501                	li	a0,0
ffffffffc020025e:	0141                	addi	sp,sp,16
ffffffffc0200260:	8082                	ret

ffffffffc0200262 <kmonitor>:
ffffffffc0200262:	7115                	addi	sp,sp,-224
ffffffffc0200264:	e962                	sd	s8,144(sp)
ffffffffc0200266:	8c2a                	mv	s8,a0
ffffffffc0200268:	00002517          	auipc	a0,0x2
ffffffffc020026c:	90850513          	addi	a0,a0,-1784 # ffffffffc0201b70 <commands+0x48>
ffffffffc0200270:	ed86                	sd	ra,216(sp)
ffffffffc0200272:	e9a2                	sd	s0,208(sp)
ffffffffc0200274:	e5a6                	sd	s1,200(sp)
ffffffffc0200276:	e1ca                	sd	s2,192(sp)
ffffffffc0200278:	fd4e                	sd	s3,184(sp)
ffffffffc020027a:	f952                	sd	s4,176(sp)
ffffffffc020027c:	f556                	sd	s5,168(sp)
ffffffffc020027e:	f15a                	sd	s6,160(sp)
ffffffffc0200280:	ed5e                	sd	s7,152(sp)
ffffffffc0200282:	e566                	sd	s9,136(sp)
ffffffffc0200284:	e16a                	sd	s10,128(sp)
ffffffffc0200286:	e2dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020028a:	00002517          	auipc	a0,0x2
ffffffffc020028e:	90e50513          	addi	a0,a0,-1778 # ffffffffc0201b98 <commands+0x70>
ffffffffc0200292:	e21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200296:	000c0563          	beqz	s8,ffffffffc02002a0 <kmonitor+0x3e>
ffffffffc020029a:	8562                	mv	a0,s8
ffffffffc020029c:	3a2000ef          	jal	ra,ffffffffc020063e <print_trapframe>
ffffffffc02002a0:	00002c97          	auipc	s9,0x2
ffffffffc02002a4:	888c8c93          	addi	s9,s9,-1912 # ffffffffc0201b28 <commands>
ffffffffc02002a8:	00002997          	auipc	s3,0x2
ffffffffc02002ac:	91898993          	addi	s3,s3,-1768 # ffffffffc0201bc0 <commands+0x98>
ffffffffc02002b0:	00002917          	auipc	s2,0x2
ffffffffc02002b4:	91890913          	addi	s2,s2,-1768 # ffffffffc0201bc8 <commands+0xa0>
ffffffffc02002b8:	4a3d                	li	s4,15
ffffffffc02002ba:	00002b17          	auipc	s6,0x2
ffffffffc02002be:	916b0b13          	addi	s6,s6,-1770 # ffffffffc0201bd0 <commands+0xa8>
ffffffffc02002c2:	00002a97          	auipc	s5,0x2
ffffffffc02002c6:	966a8a93          	addi	s5,s5,-1690 # ffffffffc0201c28 <commands+0x100>
ffffffffc02002ca:	4b8d                	li	s7,3
ffffffffc02002cc:	854e                	mv	a0,s3
ffffffffc02002ce:	588010ef          	jal	ra,ffffffffc0201856 <readline>
ffffffffc02002d2:	842a                	mv	s0,a0
ffffffffc02002d4:	dd65                	beqz	a0,ffffffffc02002cc <kmonitor+0x6a>
ffffffffc02002d6:	00054583          	lbu	a1,0(a0)
ffffffffc02002da:	4481                	li	s1,0
ffffffffc02002dc:	c999                	beqz	a1,ffffffffc02002f2 <kmonitor+0x90>
ffffffffc02002de:	854a                	mv	a0,s2
ffffffffc02002e0:	6f6010ef          	jal	ra,ffffffffc02019d6 <strchr>
ffffffffc02002e4:	c925                	beqz	a0,ffffffffc0200354 <kmonitor+0xf2>
ffffffffc02002e6:	00144583          	lbu	a1,1(s0)
ffffffffc02002ea:	00040023          	sb	zero,0(s0)
ffffffffc02002ee:	0405                	addi	s0,s0,1
ffffffffc02002f0:	f5fd                	bnez	a1,ffffffffc02002de <kmonitor+0x7c>
ffffffffc02002f2:	dce9                	beqz	s1,ffffffffc02002cc <kmonitor+0x6a>
ffffffffc02002f4:	6582                	ld	a1,0(sp)
ffffffffc02002f6:	00002d17          	auipc	s10,0x2
ffffffffc02002fa:	832d0d13          	addi	s10,s10,-1998 # ffffffffc0201b28 <commands>
ffffffffc02002fe:	8556                	mv	a0,s5
ffffffffc0200300:	4401                	li	s0,0
ffffffffc0200302:	0d61                	addi	s10,s10,24
ffffffffc0200304:	6a8010ef          	jal	ra,ffffffffc02019ac <strcmp>
ffffffffc0200308:	c919                	beqz	a0,ffffffffc020031e <kmonitor+0xbc>
ffffffffc020030a:	2405                	addiw	s0,s0,1
ffffffffc020030c:	09740463          	beq	s0,s7,ffffffffc0200394 <kmonitor+0x132>
ffffffffc0200310:	000d3503          	ld	a0,0(s10)
ffffffffc0200314:	6582                	ld	a1,0(sp)
ffffffffc0200316:	0d61                	addi	s10,s10,24
ffffffffc0200318:	694010ef          	jal	ra,ffffffffc02019ac <strcmp>
ffffffffc020031c:	f57d                	bnez	a0,ffffffffc020030a <kmonitor+0xa8>
ffffffffc020031e:	00141793          	slli	a5,s0,0x1
ffffffffc0200322:	97a2                	add	a5,a5,s0
ffffffffc0200324:	078e                	slli	a5,a5,0x3
ffffffffc0200326:	97e6                	add	a5,a5,s9
ffffffffc0200328:	6b9c                	ld	a5,16(a5)
ffffffffc020032a:	8662                	mv	a2,s8
ffffffffc020032c:	002c                	addi	a1,sp,8
ffffffffc020032e:	fff4851b          	addiw	a0,s1,-1
ffffffffc0200332:	9782                	jalr	a5
ffffffffc0200334:	f8055ce3          	bgez	a0,ffffffffc02002cc <kmonitor+0x6a>
ffffffffc0200338:	60ee                	ld	ra,216(sp)
ffffffffc020033a:	644e                	ld	s0,208(sp)
ffffffffc020033c:	64ae                	ld	s1,200(sp)
ffffffffc020033e:	690e                	ld	s2,192(sp)
ffffffffc0200340:	79ea                	ld	s3,184(sp)
ffffffffc0200342:	7a4a                	ld	s4,176(sp)
ffffffffc0200344:	7aaa                	ld	s5,168(sp)
ffffffffc0200346:	7b0a                	ld	s6,160(sp)
ffffffffc0200348:	6bea                	ld	s7,152(sp)
ffffffffc020034a:	6c4a                	ld	s8,144(sp)
ffffffffc020034c:	6caa                	ld	s9,136(sp)
ffffffffc020034e:	6d0a                	ld	s10,128(sp)
ffffffffc0200350:	612d                	addi	sp,sp,224
ffffffffc0200352:	8082                	ret
ffffffffc0200354:	00044783          	lbu	a5,0(s0)
ffffffffc0200358:	dfc9                	beqz	a5,ffffffffc02002f2 <kmonitor+0x90>
ffffffffc020035a:	03448863          	beq	s1,s4,ffffffffc020038a <kmonitor+0x128>
ffffffffc020035e:	00349793          	slli	a5,s1,0x3
ffffffffc0200362:	0118                	addi	a4,sp,128
ffffffffc0200364:	97ba                	add	a5,a5,a4
ffffffffc0200366:	f887b023          	sd	s0,-128(a5)
ffffffffc020036a:	00044583          	lbu	a1,0(s0)
ffffffffc020036e:	2485                	addiw	s1,s1,1
ffffffffc0200370:	e591                	bnez	a1,ffffffffc020037c <kmonitor+0x11a>
ffffffffc0200372:	b749                	j	ffffffffc02002f4 <kmonitor+0x92>
ffffffffc0200374:	0405                	addi	s0,s0,1
ffffffffc0200376:	00044583          	lbu	a1,0(s0)
ffffffffc020037a:	ddad                	beqz	a1,ffffffffc02002f4 <kmonitor+0x92>
ffffffffc020037c:	854a                	mv	a0,s2
ffffffffc020037e:	658010ef          	jal	ra,ffffffffc02019d6 <strchr>
ffffffffc0200382:	d96d                	beqz	a0,ffffffffc0200374 <kmonitor+0x112>
ffffffffc0200384:	00044583          	lbu	a1,0(s0)
ffffffffc0200388:	bf91                	j	ffffffffc02002dc <kmonitor+0x7a>
ffffffffc020038a:	45c1                	li	a1,16
ffffffffc020038c:	855a                	mv	a0,s6
ffffffffc020038e:	d25ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200392:	b7f1                	j	ffffffffc020035e <kmonitor+0xfc>
ffffffffc0200394:	6582                	ld	a1,0(sp)
ffffffffc0200396:	00002517          	auipc	a0,0x2
ffffffffc020039a:	85a50513          	addi	a0,a0,-1958 # ffffffffc0201bf0 <commands+0xc8>
ffffffffc020039e:	d15ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02003a2:	b72d                	j	ffffffffc02002cc <kmonitor+0x6a>

ffffffffc02003a4 <__panic>:
ffffffffc02003a4:	00006317          	auipc	t1,0x6
ffffffffc02003a8:	07430313          	addi	t1,t1,116 # ffffffffc0206418 <is_panic>
ffffffffc02003ac:	00032303          	lw	t1,0(t1)
ffffffffc02003b0:	715d                	addi	sp,sp,-80
ffffffffc02003b2:	ec06                	sd	ra,24(sp)
ffffffffc02003b4:	e822                	sd	s0,16(sp)
ffffffffc02003b6:	f436                	sd	a3,40(sp)
ffffffffc02003b8:	f83a                	sd	a4,48(sp)
ffffffffc02003ba:	fc3e                	sd	a5,56(sp)
ffffffffc02003bc:	e0c2                	sd	a6,64(sp)
ffffffffc02003be:	e4c6                	sd	a7,72(sp)
ffffffffc02003c0:	02031c63          	bnez	t1,ffffffffc02003f8 <__panic+0x54>
ffffffffc02003c4:	4785                	li	a5,1
ffffffffc02003c6:	8432                	mv	s0,a2
ffffffffc02003c8:	00006717          	auipc	a4,0x6
ffffffffc02003cc:	04f72823          	sw	a5,80(a4) # ffffffffc0206418 <is_panic>
ffffffffc02003d0:	862e                	mv	a2,a1
ffffffffc02003d2:	103c                	addi	a5,sp,40
ffffffffc02003d4:	85aa                	mv	a1,a0
ffffffffc02003d6:	00002517          	auipc	a0,0x2
ffffffffc02003da:	8d250513          	addi	a0,a0,-1838 # ffffffffc0201ca8 <commands+0x180>
ffffffffc02003de:	e43e                	sd	a5,8(sp)
ffffffffc02003e0:	cd3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02003e4:	65a2                	ld	a1,8(sp)
ffffffffc02003e6:	8522                	mv	a0,s0
ffffffffc02003e8:	cabff0ef          	jal	ra,ffffffffc0200092 <vcprintf>
ffffffffc02003ec:	00002517          	auipc	a0,0x2
ffffffffc02003f0:	07450513          	addi	a0,a0,116 # ffffffffc0202460 <commands+0x938>
ffffffffc02003f4:	cbfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02003f8:	062000ef          	jal	ra,ffffffffc020045a <intr_disable>
ffffffffc02003fc:	4501                	li	a0,0
ffffffffc02003fe:	e65ff0ef          	jal	ra,ffffffffc0200262 <kmonitor>
ffffffffc0200402:	bfed                	j	ffffffffc02003fc <__panic+0x58>

ffffffffc0200404 <clock_init>:
ffffffffc0200404:	1141                	addi	sp,sp,-16
ffffffffc0200406:	e406                	sd	ra,8(sp)
ffffffffc0200408:	02000793          	li	a5,32
ffffffffc020040c:	1047a7f3          	csrrs	a5,sie,a5
ffffffffc0200410:	c0102573          	rdtime	a0
ffffffffc0200414:	67e1                	lui	a5,0x18
ffffffffc0200416:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020041a:	953e                	add	a0,a0,a5
ffffffffc020041c:	514010ef          	jal	ra,ffffffffc0201930 <sbi_set_timer>
ffffffffc0200420:	60a2                	ld	ra,8(sp)
ffffffffc0200422:	00006797          	auipc	a5,0x6
ffffffffc0200426:	0207bf23          	sd	zero,62(a5) # ffffffffc0206460 <ticks>
ffffffffc020042a:	00002517          	auipc	a0,0x2
ffffffffc020042e:	89e50513          	addi	a0,a0,-1890 # ffffffffc0201cc8 <commands+0x1a0>
ffffffffc0200432:	0141                	addi	sp,sp,16
ffffffffc0200434:	b9bd                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200436 <clock_set_next_event>:
ffffffffc0200436:	c0102573          	rdtime	a0
ffffffffc020043a:	67e1                	lui	a5,0x18
ffffffffc020043c:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200440:	953e                	add	a0,a0,a5
ffffffffc0200442:	4ee0106f          	j	ffffffffc0201930 <sbi_set_timer>

ffffffffc0200446 <cons_init>:
ffffffffc0200446:	8082                	ret

ffffffffc0200448 <cons_putc>:
ffffffffc0200448:	0ff57513          	andi	a0,a0,255
ffffffffc020044c:	4c80106f          	j	ffffffffc0201914 <sbi_console_putchar>

ffffffffc0200450 <cons_getc>:
ffffffffc0200450:	4fc0106f          	j	ffffffffc020194c <sbi_console_getchar>

ffffffffc0200454 <intr_enable>:
ffffffffc0200454:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200458:	8082                	ret

ffffffffc020045a <intr_disable>:
ffffffffc020045a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020045e:	8082                	ret

ffffffffc0200460 <idt_init>:
ffffffffc0200460:	14005073          	csrwi	sscratch,0
ffffffffc0200464:	00000797          	auipc	a5,0x0
ffffffffc0200468:	31c78793          	addi	a5,a5,796 # ffffffffc0200780 <__alltraps>
ffffffffc020046c:	10579073          	csrw	stvec,a5
ffffffffc0200470:	8082                	ret

ffffffffc0200472 <print_regs>:
ffffffffc0200472:	610c                	ld	a1,0(a0)
ffffffffc0200474:	1141                	addi	sp,sp,-16
ffffffffc0200476:	e022                	sd	s0,0(sp)
ffffffffc0200478:	842a                	mv	s0,a0
ffffffffc020047a:	00002517          	auipc	a0,0x2
ffffffffc020047e:	96650513          	addi	a0,a0,-1690 # ffffffffc0201de0 <commands+0x2b8>
ffffffffc0200482:	e406                	sd	ra,8(sp)
ffffffffc0200484:	c2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200488:	640c                	ld	a1,8(s0)
ffffffffc020048a:	00002517          	auipc	a0,0x2
ffffffffc020048e:	96e50513          	addi	a0,a0,-1682 # ffffffffc0201df8 <commands+0x2d0>
ffffffffc0200492:	c21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200496:	680c                	ld	a1,16(s0)
ffffffffc0200498:	00002517          	auipc	a0,0x2
ffffffffc020049c:	97850513          	addi	a0,a0,-1672 # ffffffffc0201e10 <commands+0x2e8>
ffffffffc02004a0:	c13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02004a4:	6c0c                	ld	a1,24(s0)
ffffffffc02004a6:	00002517          	auipc	a0,0x2
ffffffffc02004aa:	98250513          	addi	a0,a0,-1662 # ffffffffc0201e28 <commands+0x300>
ffffffffc02004ae:	c05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02004b2:	700c                	ld	a1,32(s0)
ffffffffc02004b4:	00002517          	auipc	a0,0x2
ffffffffc02004b8:	98c50513          	addi	a0,a0,-1652 # ffffffffc0201e40 <commands+0x318>
ffffffffc02004bc:	bf7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02004c0:	740c                	ld	a1,40(s0)
ffffffffc02004c2:	00002517          	auipc	a0,0x2
ffffffffc02004c6:	99650513          	addi	a0,a0,-1642 # ffffffffc0201e58 <commands+0x330>
ffffffffc02004ca:	be9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02004ce:	780c                	ld	a1,48(s0)
ffffffffc02004d0:	00002517          	auipc	a0,0x2
ffffffffc02004d4:	9a050513          	addi	a0,a0,-1632 # ffffffffc0201e70 <commands+0x348>
ffffffffc02004d8:	bdbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02004dc:	7c0c                	ld	a1,56(s0)
ffffffffc02004de:	00002517          	auipc	a0,0x2
ffffffffc02004e2:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0201e88 <commands+0x360>
ffffffffc02004e6:	bcdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02004ea:	602c                	ld	a1,64(s0)
ffffffffc02004ec:	00002517          	auipc	a0,0x2
ffffffffc02004f0:	9b450513          	addi	a0,a0,-1612 # ffffffffc0201ea0 <commands+0x378>
ffffffffc02004f4:	bbfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02004f8:	642c                	ld	a1,72(s0)
ffffffffc02004fa:	00002517          	auipc	a0,0x2
ffffffffc02004fe:	9be50513          	addi	a0,a0,-1602 # ffffffffc0201eb8 <commands+0x390>
ffffffffc0200502:	bb1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200506:	682c                	ld	a1,80(s0)
ffffffffc0200508:	00002517          	auipc	a0,0x2
ffffffffc020050c:	9c850513          	addi	a0,a0,-1592 # ffffffffc0201ed0 <commands+0x3a8>
ffffffffc0200510:	ba3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200514:	6c2c                	ld	a1,88(s0)
ffffffffc0200516:	00002517          	auipc	a0,0x2
ffffffffc020051a:	9d250513          	addi	a0,a0,-1582 # ffffffffc0201ee8 <commands+0x3c0>
ffffffffc020051e:	b95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200522:	702c                	ld	a1,96(s0)
ffffffffc0200524:	00002517          	auipc	a0,0x2
ffffffffc0200528:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0201f00 <commands+0x3d8>
ffffffffc020052c:	b87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200530:	742c                	ld	a1,104(s0)
ffffffffc0200532:	00002517          	auipc	a0,0x2
ffffffffc0200536:	9e650513          	addi	a0,a0,-1562 # ffffffffc0201f18 <commands+0x3f0>
ffffffffc020053a:	b79ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020053e:	782c                	ld	a1,112(s0)
ffffffffc0200540:	00002517          	auipc	a0,0x2
ffffffffc0200544:	9f050513          	addi	a0,a0,-1552 # ffffffffc0201f30 <commands+0x408>
ffffffffc0200548:	b6bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020054c:	7c2c                	ld	a1,120(s0)
ffffffffc020054e:	00002517          	auipc	a0,0x2
ffffffffc0200552:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0201f48 <commands+0x420>
ffffffffc0200556:	b5dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020055a:	604c                	ld	a1,128(s0)
ffffffffc020055c:	00002517          	auipc	a0,0x2
ffffffffc0200560:	a0450513          	addi	a0,a0,-1532 # ffffffffc0201f60 <commands+0x438>
ffffffffc0200564:	b4fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200568:	644c                	ld	a1,136(s0)
ffffffffc020056a:	00002517          	auipc	a0,0x2
ffffffffc020056e:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0201f78 <commands+0x450>
ffffffffc0200572:	b41ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200576:	684c                	ld	a1,144(s0)
ffffffffc0200578:	00002517          	auipc	a0,0x2
ffffffffc020057c:	a1850513          	addi	a0,a0,-1512 # ffffffffc0201f90 <commands+0x468>
ffffffffc0200580:	b33ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200584:	6c4c                	ld	a1,152(s0)
ffffffffc0200586:	00002517          	auipc	a0,0x2
ffffffffc020058a:	a2250513          	addi	a0,a0,-1502 # ffffffffc0201fa8 <commands+0x480>
ffffffffc020058e:	b25ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200592:	704c                	ld	a1,160(s0)
ffffffffc0200594:	00002517          	auipc	a0,0x2
ffffffffc0200598:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0201fc0 <commands+0x498>
ffffffffc020059c:	b17ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02005a0:	744c                	ld	a1,168(s0)
ffffffffc02005a2:	00002517          	auipc	a0,0x2
ffffffffc02005a6:	a3650513          	addi	a0,a0,-1482 # ffffffffc0201fd8 <commands+0x4b0>
ffffffffc02005aa:	b09ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02005ae:	784c                	ld	a1,176(s0)
ffffffffc02005b0:	00002517          	auipc	a0,0x2
ffffffffc02005b4:	a4050513          	addi	a0,a0,-1472 # ffffffffc0201ff0 <commands+0x4c8>
ffffffffc02005b8:	afbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02005bc:	7c4c                	ld	a1,184(s0)
ffffffffc02005be:	00002517          	auipc	a0,0x2
ffffffffc02005c2:	a4a50513          	addi	a0,a0,-1462 # ffffffffc0202008 <commands+0x4e0>
ffffffffc02005c6:	aedff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02005ca:	606c                	ld	a1,192(s0)
ffffffffc02005cc:	00002517          	auipc	a0,0x2
ffffffffc02005d0:	a5450513          	addi	a0,a0,-1452 # ffffffffc0202020 <commands+0x4f8>
ffffffffc02005d4:	adfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02005d8:	646c                	ld	a1,200(s0)
ffffffffc02005da:	00002517          	auipc	a0,0x2
ffffffffc02005de:	a5e50513          	addi	a0,a0,-1442 # ffffffffc0202038 <commands+0x510>
ffffffffc02005e2:	ad1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02005e6:	686c                	ld	a1,208(s0)
ffffffffc02005e8:	00002517          	auipc	a0,0x2
ffffffffc02005ec:	a6850513          	addi	a0,a0,-1432 # ffffffffc0202050 <commands+0x528>
ffffffffc02005f0:	ac3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02005f4:	6c6c                	ld	a1,216(s0)
ffffffffc02005f6:	00002517          	auipc	a0,0x2
ffffffffc02005fa:	a7250513          	addi	a0,a0,-1422 # ffffffffc0202068 <commands+0x540>
ffffffffc02005fe:	ab5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200602:	706c                	ld	a1,224(s0)
ffffffffc0200604:	00002517          	auipc	a0,0x2
ffffffffc0200608:	a7c50513          	addi	a0,a0,-1412 # ffffffffc0202080 <commands+0x558>
ffffffffc020060c:	aa7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200610:	746c                	ld	a1,232(s0)
ffffffffc0200612:	00002517          	auipc	a0,0x2
ffffffffc0200616:	a8650513          	addi	a0,a0,-1402 # ffffffffc0202098 <commands+0x570>
ffffffffc020061a:	a99ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020061e:	786c                	ld	a1,240(s0)
ffffffffc0200620:	00002517          	auipc	a0,0x2
ffffffffc0200624:	a9050513          	addi	a0,a0,-1392 # ffffffffc02020b0 <commands+0x588>
ffffffffc0200628:	a8bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020062c:	7c6c                	ld	a1,248(s0)
ffffffffc020062e:	6402                	ld	s0,0(sp)
ffffffffc0200630:	60a2                	ld	ra,8(sp)
ffffffffc0200632:	00002517          	auipc	a0,0x2
ffffffffc0200636:	a9650513          	addi	a0,a0,-1386 # ffffffffc02020c8 <commands+0x5a0>
ffffffffc020063a:	0141                	addi	sp,sp,16
ffffffffc020063c:	bc9d                	j	ffffffffc02000b2 <cprintf>

ffffffffc020063e <print_trapframe>:
ffffffffc020063e:	1141                	addi	sp,sp,-16
ffffffffc0200640:	e022                	sd	s0,0(sp)
ffffffffc0200642:	85aa                	mv	a1,a0
ffffffffc0200644:	842a                	mv	s0,a0
ffffffffc0200646:	00002517          	auipc	a0,0x2
ffffffffc020064a:	a9a50513          	addi	a0,a0,-1382 # ffffffffc02020e0 <commands+0x5b8>
ffffffffc020064e:	e406                	sd	ra,8(sp)
ffffffffc0200650:	a63ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200654:	8522                	mv	a0,s0
ffffffffc0200656:	e1dff0ef          	jal	ra,ffffffffc0200472 <print_regs>
ffffffffc020065a:	10043583          	ld	a1,256(s0)
ffffffffc020065e:	00002517          	auipc	a0,0x2
ffffffffc0200662:	a9a50513          	addi	a0,a0,-1382 # ffffffffc02020f8 <commands+0x5d0>
ffffffffc0200666:	a4dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020066a:	10843583          	ld	a1,264(s0)
ffffffffc020066e:	00002517          	auipc	a0,0x2
ffffffffc0200672:	aa250513          	addi	a0,a0,-1374 # ffffffffc0202110 <commands+0x5e8>
ffffffffc0200676:	a3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020067a:	11043583          	ld	a1,272(s0)
ffffffffc020067e:	00002517          	auipc	a0,0x2
ffffffffc0200682:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0202128 <commands+0x600>
ffffffffc0200686:	a2dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020068a:	11843583          	ld	a1,280(s0)
ffffffffc020068e:	6402                	ld	s0,0(sp)
ffffffffc0200690:	60a2                	ld	ra,8(sp)
ffffffffc0200692:	00002517          	auipc	a0,0x2
ffffffffc0200696:	aae50513          	addi	a0,a0,-1362 # ffffffffc0202140 <commands+0x618>
ffffffffc020069a:	0141                	addi	sp,sp,16
ffffffffc020069c:	bc19                	j	ffffffffc02000b2 <cprintf>

ffffffffc020069e <interrupt_handler>:
ffffffffc020069e:	11853783          	ld	a5,280(a0)
ffffffffc02006a2:	577d                	li	a4,-1
ffffffffc02006a4:	8305                	srli	a4,a4,0x1
ffffffffc02006a6:	8ff9                	and	a5,a5,a4
ffffffffc02006a8:	472d                	li	a4,11
ffffffffc02006aa:	08f76163          	bltu	a4,a5,ffffffffc020072c <interrupt_handler+0x8e>
ffffffffc02006ae:	00001717          	auipc	a4,0x1
ffffffffc02006b2:	63670713          	addi	a4,a4,1590 # ffffffffc0201ce4 <commands+0x1bc>
ffffffffc02006b6:	078a                	slli	a5,a5,0x2
ffffffffc02006b8:	97ba                	add	a5,a5,a4
ffffffffc02006ba:	439c                	lw	a5,0(a5)
ffffffffc02006bc:	97ba                	add	a5,a5,a4
ffffffffc02006be:	8782                	jr	a5
ffffffffc02006c0:	00001517          	auipc	a0,0x1
ffffffffc02006c4:	6b850513          	addi	a0,a0,1720 # ffffffffc0201d78 <commands+0x250>
ffffffffc02006c8:	b2ed                	j	ffffffffc02000b2 <cprintf>
ffffffffc02006ca:	00001517          	auipc	a0,0x1
ffffffffc02006ce:	68e50513          	addi	a0,a0,1678 # ffffffffc0201d58 <commands+0x230>
ffffffffc02006d2:	b2c5                	j	ffffffffc02000b2 <cprintf>
ffffffffc02006d4:	00001517          	auipc	a0,0x1
ffffffffc02006d8:	64450513          	addi	a0,a0,1604 # ffffffffc0201d18 <commands+0x1f0>
ffffffffc02006dc:	bad9                	j	ffffffffc02000b2 <cprintf>
ffffffffc02006de:	00001517          	auipc	a0,0x1
ffffffffc02006e2:	6ba50513          	addi	a0,a0,1722 # ffffffffc0201d98 <commands+0x270>
ffffffffc02006e6:	b2f1                	j	ffffffffc02000b2 <cprintf>
ffffffffc02006e8:	1141                	addi	sp,sp,-16
ffffffffc02006ea:	e406                	sd	ra,8(sp)
ffffffffc02006ec:	e022                	sd	s0,0(sp)
ffffffffc02006ee:	d49ff0ef          	jal	ra,ffffffffc0200436 <clock_set_next_event>
ffffffffc02006f2:	00006717          	auipc	a4,0x6
ffffffffc02006f6:	d6e70713          	addi	a4,a4,-658 # ffffffffc0206460 <ticks>
ffffffffc02006fa:	631c                	ld	a5,0(a4)
ffffffffc02006fc:	06400693          	li	a3,100
ffffffffc0200700:	0785                	addi	a5,a5,1
ffffffffc0200702:	00006617          	auipc	a2,0x6
ffffffffc0200706:	d4f63f23          	sd	a5,-674(a2) # ffffffffc0206460 <ticks>
ffffffffc020070a:	631c                	ld	a5,0(a4)
ffffffffc020070c:	02d78163          	beq	a5,a3,ffffffffc020072e <interrupt_handler+0x90>
ffffffffc0200710:	60a2                	ld	ra,8(sp)
ffffffffc0200712:	6402                	ld	s0,0(sp)
ffffffffc0200714:	0141                	addi	sp,sp,16
ffffffffc0200716:	8082                	ret
ffffffffc0200718:	00001517          	auipc	a0,0x1
ffffffffc020071c:	6a850513          	addi	a0,a0,1704 # ffffffffc0201dc0 <commands+0x298>
ffffffffc0200720:	ba49                	j	ffffffffc02000b2 <cprintf>
ffffffffc0200722:	00001517          	auipc	a0,0x1
ffffffffc0200726:	61650513          	addi	a0,a0,1558 # ffffffffc0201d38 <commands+0x210>
ffffffffc020072a:	b261                	j	ffffffffc02000b2 <cprintf>
ffffffffc020072c:	bf09                	j	ffffffffc020063e <print_trapframe>
ffffffffc020072e:	06400593          	li	a1,100
ffffffffc0200732:	00001517          	auipc	a0,0x1
ffffffffc0200736:	67e50513          	addi	a0,a0,1662 # ffffffffc0201db0 <commands+0x288>
ffffffffc020073a:	00006797          	auipc	a5,0x6
ffffffffc020073e:	d207b323          	sd	zero,-730(a5) # ffffffffc0206460 <ticks>
ffffffffc0200742:	00006417          	auipc	s0,0x6
ffffffffc0200746:	cde40413          	addi	s0,s0,-802 # ffffffffc0206420 <num>
ffffffffc020074a:	969ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020074e:	6018                	ld	a4,0(s0)
ffffffffc0200750:	47a9                	li	a5,10
ffffffffc0200752:	00f70963          	beq	a4,a5,ffffffffc0200764 <interrupt_handler+0xc6>
ffffffffc0200756:	601c                	ld	a5,0(s0)
ffffffffc0200758:	0785                	addi	a5,a5,1
ffffffffc020075a:	00006717          	auipc	a4,0x6
ffffffffc020075e:	ccf73323          	sd	a5,-826(a4) # ffffffffc0206420 <num>
ffffffffc0200762:	b77d                	j	ffffffffc0200710 <interrupt_handler+0x72>
ffffffffc0200764:	206010ef          	jal	ra,ffffffffc020196a <sbi_shutdown>
ffffffffc0200768:	b7fd                	j	ffffffffc0200756 <interrupt_handler+0xb8>

ffffffffc020076a <trap>:
ffffffffc020076a:	11853783          	ld	a5,280(a0)
ffffffffc020076e:	0007c763          	bltz	a5,ffffffffc020077c <trap+0x12>
ffffffffc0200772:	472d                	li	a4,11
ffffffffc0200774:	00f76363          	bltu	a4,a5,ffffffffc020077a <trap+0x10>
ffffffffc0200778:	8082                	ret
ffffffffc020077a:	b5d1                	j	ffffffffc020063e <print_trapframe>
ffffffffc020077c:	b70d                	j	ffffffffc020069e <interrupt_handler>
	...

ffffffffc0200780 <__alltraps>:
ffffffffc0200780:	14011073          	csrw	sscratch,sp
ffffffffc0200784:	712d                	addi	sp,sp,-288
ffffffffc0200786:	e002                	sd	zero,0(sp)
ffffffffc0200788:	e406                	sd	ra,8(sp)
ffffffffc020078a:	ec0e                	sd	gp,24(sp)
ffffffffc020078c:	f012                	sd	tp,32(sp)
ffffffffc020078e:	f416                	sd	t0,40(sp)
ffffffffc0200790:	f81a                	sd	t1,48(sp)
ffffffffc0200792:	fc1e                	sd	t2,56(sp)
ffffffffc0200794:	e0a2                	sd	s0,64(sp)
ffffffffc0200796:	e4a6                	sd	s1,72(sp)
ffffffffc0200798:	e8aa                	sd	a0,80(sp)
ffffffffc020079a:	ecae                	sd	a1,88(sp)
ffffffffc020079c:	f0b2                	sd	a2,96(sp)
ffffffffc020079e:	f4b6                	sd	a3,104(sp)
ffffffffc02007a0:	f8ba                	sd	a4,112(sp)
ffffffffc02007a2:	fcbe                	sd	a5,120(sp)
ffffffffc02007a4:	e142                	sd	a6,128(sp)
ffffffffc02007a6:	e546                	sd	a7,136(sp)
ffffffffc02007a8:	e94a                	sd	s2,144(sp)
ffffffffc02007aa:	ed4e                	sd	s3,152(sp)
ffffffffc02007ac:	f152                	sd	s4,160(sp)
ffffffffc02007ae:	f556                	sd	s5,168(sp)
ffffffffc02007b0:	f95a                	sd	s6,176(sp)
ffffffffc02007b2:	fd5e                	sd	s7,184(sp)
ffffffffc02007b4:	e1e2                	sd	s8,192(sp)
ffffffffc02007b6:	e5e6                	sd	s9,200(sp)
ffffffffc02007b8:	e9ea                	sd	s10,208(sp)
ffffffffc02007ba:	edee                	sd	s11,216(sp)
ffffffffc02007bc:	f1f2                	sd	t3,224(sp)
ffffffffc02007be:	f5f6                	sd	t4,232(sp)
ffffffffc02007c0:	f9fa                	sd	t5,240(sp)
ffffffffc02007c2:	fdfe                	sd	t6,248(sp)
ffffffffc02007c4:	14001473          	csrrw	s0,sscratch,zero
ffffffffc02007c8:	100024f3          	csrr	s1,sstatus
ffffffffc02007cc:	14102973          	csrr	s2,sepc
ffffffffc02007d0:	143029f3          	csrr	s3,stval
ffffffffc02007d4:	14202a73          	csrr	s4,scause
ffffffffc02007d8:	e822                	sd	s0,16(sp)
ffffffffc02007da:	e226                	sd	s1,256(sp)
ffffffffc02007dc:	e64a                	sd	s2,264(sp)
ffffffffc02007de:	ea4e                	sd	s3,272(sp)
ffffffffc02007e0:	ee52                	sd	s4,280(sp)
ffffffffc02007e2:	850a                	mv	a0,sp
ffffffffc02007e4:	f87ff0ef          	jal	ra,ffffffffc020076a <trap>

ffffffffc02007e8 <__trapret>:
ffffffffc02007e8:	6492                	ld	s1,256(sp)
ffffffffc02007ea:	6932                	ld	s2,264(sp)
ffffffffc02007ec:	10049073          	csrw	sstatus,s1
ffffffffc02007f0:	14191073          	csrw	sepc,s2
ffffffffc02007f4:	60a2                	ld	ra,8(sp)
ffffffffc02007f6:	61e2                	ld	gp,24(sp)
ffffffffc02007f8:	7202                	ld	tp,32(sp)
ffffffffc02007fa:	72a2                	ld	t0,40(sp)
ffffffffc02007fc:	7342                	ld	t1,48(sp)
ffffffffc02007fe:	73e2                	ld	t2,56(sp)
ffffffffc0200800:	6406                	ld	s0,64(sp)
ffffffffc0200802:	64a6                	ld	s1,72(sp)
ffffffffc0200804:	6546                	ld	a0,80(sp)
ffffffffc0200806:	65e6                	ld	a1,88(sp)
ffffffffc0200808:	7606                	ld	a2,96(sp)
ffffffffc020080a:	76a6                	ld	a3,104(sp)
ffffffffc020080c:	7746                	ld	a4,112(sp)
ffffffffc020080e:	77e6                	ld	a5,120(sp)
ffffffffc0200810:	680a                	ld	a6,128(sp)
ffffffffc0200812:	68aa                	ld	a7,136(sp)
ffffffffc0200814:	694a                	ld	s2,144(sp)
ffffffffc0200816:	69ea                	ld	s3,152(sp)
ffffffffc0200818:	7a0a                	ld	s4,160(sp)
ffffffffc020081a:	7aaa                	ld	s5,168(sp)
ffffffffc020081c:	7b4a                	ld	s6,176(sp)
ffffffffc020081e:	7bea                	ld	s7,184(sp)
ffffffffc0200820:	6c0e                	ld	s8,192(sp)
ffffffffc0200822:	6cae                	ld	s9,200(sp)
ffffffffc0200824:	6d4e                	ld	s10,208(sp)
ffffffffc0200826:	6dee                	ld	s11,216(sp)
ffffffffc0200828:	7e0e                	ld	t3,224(sp)
ffffffffc020082a:	7eae                	ld	t4,232(sp)
ffffffffc020082c:	7f4e                	ld	t5,240(sp)
ffffffffc020082e:	7fee                	ld	t6,248(sp)
ffffffffc0200830:	6142                	ld	sp,16(sp)
ffffffffc0200832:	10200073          	sret

ffffffffc0200836 <buddy_system_init>:
ffffffffc0200836:	00006797          	auipc	a5,0x6
ffffffffc020083a:	c3a78793          	addi	a5,a5,-966 # ffffffffc0206470 <buddy_s+0x8>
ffffffffc020083e:	00006717          	auipc	a4,0x6
ffffffffc0200842:	d2270713          	addi	a4,a4,-734 # ffffffffc0206560 <buddy_s+0xf8>
ffffffffc0200846:	e79c                	sd	a5,8(a5)
ffffffffc0200848:	e39c                	sd	a5,0(a5)
ffffffffc020084a:	07c1                	addi	a5,a5,16
ffffffffc020084c:	fee79de3          	bne	a5,a4,ffffffffc0200846 <buddy_system_init+0x10>
ffffffffc0200850:	00006797          	auipc	a5,0x6
ffffffffc0200854:	c007ac23          	sw	zero,-1000(a5) # ffffffffc0206468 <buddy_s>
ffffffffc0200858:	00006797          	auipc	a5,0x6
ffffffffc020085c:	d007a423          	sw	zero,-760(a5) # ffffffffc0206560 <buddy_s+0xf8>
ffffffffc0200860:	8082                	ret

ffffffffc0200862 <buddy_system_nr_free_pages>:
ffffffffc0200862:	00006517          	auipc	a0,0x6
ffffffffc0200866:	cfe56503          	lwu	a0,-770(a0) # ffffffffc0206560 <buddy_s+0xf8>
ffffffffc020086a:	8082                	ret

ffffffffc020086c <buddy_system_init_memmap>:
ffffffffc020086c:	1141                	addi	sp,sp,-16
ffffffffc020086e:	e406                	sd	ra,8(sp)
ffffffffc0200870:	c1e9                	beqz	a1,ffffffffc0200932 <buddy_system_init_memmap+0xc6>
ffffffffc0200872:	fff58793          	addi	a5,a1,-1
ffffffffc0200876:	8fed                	and	a5,a5,a1
ffffffffc0200878:	cb99                	beqz	a5,ffffffffc020088e <buddy_system_init_memmap+0x22>
ffffffffc020087a:	4785                	li	a5,1
ffffffffc020087c:	a011                	j	ffffffffc0200880 <buddy_system_init_memmap+0x14>
ffffffffc020087e:	87ba                	mv	a5,a4
ffffffffc0200880:	8185                	srli	a1,a1,0x1
ffffffffc0200882:	00179713          	slli	a4,a5,0x1
ffffffffc0200886:	fde5                	bnez	a1,ffffffffc020087e <buddy_system_init_memmap+0x12>
ffffffffc0200888:	55fd                	li	a1,-1
ffffffffc020088a:	8185                	srli	a1,a1,0x1
ffffffffc020088c:	8dfd                	and	a1,a1,a5
ffffffffc020088e:	0015d793          	srli	a5,a1,0x1
ffffffffc0200892:	4601                	li	a2,0
ffffffffc0200894:	c781                	beqz	a5,ffffffffc020089c <buddy_system_init_memmap+0x30>
ffffffffc0200896:	8385                	srli	a5,a5,0x1
ffffffffc0200898:	2605                	addiw	a2,a2,1
ffffffffc020089a:	fff5                	bnez	a5,ffffffffc0200896 <buddy_system_init_memmap+0x2a>
ffffffffc020089c:	00259693          	slli	a3,a1,0x2
ffffffffc02008a0:	96ae                	add	a3,a3,a1
ffffffffc02008a2:	068e                	slli	a3,a3,0x3
ffffffffc02008a4:	96aa                	add	a3,a3,a0
ffffffffc02008a6:	02d50563          	beq	a0,a3,ffffffffc02008d0 <buddy_system_init_memmap+0x64>
ffffffffc02008aa:	651c                	ld	a5,8(a0)
ffffffffc02008ac:	8b85                	andi	a5,a5,1
ffffffffc02008ae:	c3b5                	beqz	a5,ffffffffc0200912 <buddy_system_init_memmap+0xa6>
ffffffffc02008b0:	87aa                	mv	a5,a0
ffffffffc02008b2:	587d                	li	a6,-1
ffffffffc02008b4:	a021                	j	ffffffffc02008bc <buddy_system_init_memmap+0x50>
ffffffffc02008b6:	6798                	ld	a4,8(a5)
ffffffffc02008b8:	8b05                	andi	a4,a4,1
ffffffffc02008ba:	cf21                	beqz	a4,ffffffffc0200912 <buddy_system_init_memmap+0xa6>
ffffffffc02008bc:	0007b423          	sd	zero,8(a5)
ffffffffc02008c0:	0107a823          	sw	a6,16(a5)
ffffffffc02008c4:	0007a023          	sw	zero,0(a5)
ffffffffc02008c8:	02878793          	addi	a5,a5,40
ffffffffc02008cc:	fed795e3          	bne	a5,a3,ffffffffc02008b6 <buddy_system_init_memmap+0x4a>
ffffffffc02008d0:	02061793          	slli	a5,a2,0x20
ffffffffc02008d4:	9381                	srli	a5,a5,0x20
ffffffffc02008d6:	00006697          	auipc	a3,0x6
ffffffffc02008da:	b9268693          	addi	a3,a3,-1134 # ffffffffc0206468 <buddy_s>
ffffffffc02008de:	0792                	slli	a5,a5,0x4
ffffffffc02008e0:	00f68833          	add	a6,a3,a5
ffffffffc02008e4:	01083703          	ld	a4,16(a6)
ffffffffc02008e8:	00006897          	auipc	a7,0x6
ffffffffc02008ec:	c6b8ac23          	sw	a1,-904(a7) # ffffffffc0206560 <buddy_s+0xf8>
ffffffffc02008f0:	00006897          	auipc	a7,0x6
ffffffffc02008f4:	b6c8ac23          	sw	a2,-1160(a7) # ffffffffc0206468 <buddy_s>
ffffffffc02008f8:	01850593          	addi	a1,a0,24
ffffffffc02008fc:	e30c                	sd	a1,0(a4)
ffffffffc02008fe:	60a2                	ld	ra,8(sp)
ffffffffc0200900:	07a1                	addi	a5,a5,8
ffffffffc0200902:	00b83823          	sd	a1,16(a6)
ffffffffc0200906:	97b6                	add	a5,a5,a3
ffffffffc0200908:	f118                	sd	a4,32(a0)
ffffffffc020090a:	ed1c                	sd	a5,24(a0)
ffffffffc020090c:	c910                	sw	a2,16(a0)
ffffffffc020090e:	0141                	addi	sp,sp,16
ffffffffc0200910:	8082                	ret
ffffffffc0200912:	00002697          	auipc	a3,0x2
ffffffffc0200916:	bde68693          	addi	a3,a3,-1058 # ffffffffc02024f0 <commands+0x9c8>
ffffffffc020091a:	00002617          	auipc	a2,0x2
ffffffffc020091e:	b9e60613          	addi	a2,a2,-1122 # ffffffffc02024b8 <commands+0x990>
ffffffffc0200922:	09700593          	li	a1,151
ffffffffc0200926:	00002517          	auipc	a0,0x2
ffffffffc020092a:	baa50513          	addi	a0,a0,-1110 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc020092e:	a77ff0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc0200932:	00002697          	auipc	a3,0x2
ffffffffc0200936:	b7e68693          	addi	a3,a3,-1154 # ffffffffc02024b0 <commands+0x988>
ffffffffc020093a:	00002617          	auipc	a2,0x2
ffffffffc020093e:	b7e60613          	addi	a2,a2,-1154 # ffffffffc02024b8 <commands+0x990>
ffffffffc0200942:	08e00593          	li	a1,142
ffffffffc0200946:	00002517          	auipc	a0,0x2
ffffffffc020094a:	b8a50513          	addi	a0,a0,-1142 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc020094e:	a57ff0ef          	jal	ra,ffffffffc02003a4 <__panic>

ffffffffc0200952 <buddy_system_alloc_pages>:
ffffffffc0200952:	7139                	addi	sp,sp,-64
ffffffffc0200954:	fc06                	sd	ra,56(sp)
ffffffffc0200956:	f822                	sd	s0,48(sp)
ffffffffc0200958:	f426                	sd	s1,40(sp)
ffffffffc020095a:	f04a                	sd	s2,32(sp)
ffffffffc020095c:	ec4e                	sd	s3,24(sp)
ffffffffc020095e:	e852                	sd	s4,16(sp)
ffffffffc0200960:	e456                	sd	s5,8(sp)
ffffffffc0200962:	18050663          	beqz	a0,ffffffffc0200aee <buddy_system_alloc_pages+0x19c>
ffffffffc0200966:	00006797          	auipc	a5,0x6
ffffffffc020096a:	bfa7e783          	lwu	a5,-1030(a5) # ffffffffc0206560 <buddy_s+0xf8>
ffffffffc020096e:	08a7ed63          	bltu	a5,a0,ffffffffc0200a08 <buddy_system_alloc_pages+0xb6>
ffffffffc0200972:	fff50793          	addi	a5,a0,-1
ffffffffc0200976:	8fe9                	and	a5,a5,a0
ffffffffc0200978:	12079e63          	bnez	a5,ffffffffc0200ab4 <buddy_system_alloc_pages+0x162>
ffffffffc020097c:	00155793          	srli	a5,a0,0x1
ffffffffc0200980:	14078063          	beqz	a5,ffffffffc0200ac0 <buddy_system_alloc_pages+0x16e>
ffffffffc0200984:	4e81                	li	t4,0
ffffffffc0200986:	a011                	j	ffffffffc020098a <buddy_system_alloc_pages+0x38>
ffffffffc0200988:	8eba                	mv	t4,a4
ffffffffc020098a:	8385                	srli	a5,a5,0x1
ffffffffc020098c:	001e871b          	addiw	a4,t4,1
ffffffffc0200990:	ffe5                	bnez	a5,ffffffffc0200988 <buddy_system_alloc_pages+0x36>
ffffffffc0200992:	2e89                	addiw	t4,t4,2
ffffffffc0200994:	02071793          	slli	a5,a4,0x20
ffffffffc0200998:	83f1                	srli	a5,a5,0x1c
ffffffffc020099a:	004e9f93          	slli	t6,t4,0x4
ffffffffc020099e:	82f6                	mv	t0,t4
ffffffffc02009a0:	89f6                	mv	s3,t4
ffffffffc02009a2:	00878393          	addi	t2,a5,8
ffffffffc02009a6:	0fa1                	addi	t6,t6,8
ffffffffc02009a8:	00006e17          	auipc	t3,0x6
ffffffffc02009ac:	ac0e0e13          	addi	t3,t3,-1344 # ffffffffc0206468 <buddy_s>
ffffffffc02009b0:	000e2883          	lw	a7,0(t3)
ffffffffc02009b4:	00fe0333          	add	t1,t3,a5
ffffffffc02009b8:	01033783          	ld	a5,16(t1)
ffffffffc02009bc:	00228f13          	addi	t5,t0,2
ffffffffc02009c0:	00429413          	slli	s0,t0,0x4
ffffffffc02009c4:	0f12                	slli	t5,t5,0x4
ffffffffc02009c6:	02089913          	slli	s2,a7,0x20
ffffffffc02009ca:	93f2                	add	t2,t2,t3
ffffffffc02009cc:	9ff2                	add	t6,t6,t3
ffffffffc02009ce:	02095913          	srli	s2,s2,0x20
ffffffffc02009d2:	9f72                	add	t5,t5,t3
ffffffffc02009d4:	9472                	add	s0,s0,t3
ffffffffc02009d6:	2285                	addiw	t0,t0,1
ffffffffc02009d8:	4485                	li	s1,1
ffffffffc02009da:	0af39a63          	bne	t2,a5,ffffffffc0200a8e <buddy_system_alloc_pages+0x13c>
ffffffffc02009de:	03d8e563          	bltu	a7,t4,ffffffffc0200a08 <buddy_system_alloc_pages+0xb6>
ffffffffc02009e2:	681c                	ld	a5,16(s0)
ffffffffc02009e4:	03f79d63          	bne	a5,t6,ffffffffc0200a1e <buddy_system_alloc_pages+0xcc>
ffffffffc02009e8:	8716                	mv	a4,t0
ffffffffc02009ea:	87fa                	mv	a5,t5
ffffffffc02009ec:	a811                	j	ffffffffc0200a00 <buddy_system_alloc_pages+0xae>
ffffffffc02009ee:	6390                	ld	a2,0(a5)
ffffffffc02009f0:	ff878693          	addi	a3,a5,-8
ffffffffc02009f4:	00170593          	addi	a1,a4,1
ffffffffc02009f8:	07c1                	addi	a5,a5,16
ffffffffc02009fa:	02d61463          	bne	a2,a3,ffffffffc0200a22 <buddy_system_alloc_pages+0xd0>
ffffffffc02009fe:	872e                	mv	a4,a1
ffffffffc0200a00:	0007081b          	sext.w	a6,a4
ffffffffc0200a04:	ff08f5e3          	bgeu	a7,a6,ffffffffc02009ee <buddy_system_alloc_pages+0x9c>
ffffffffc0200a08:	4701                	li	a4,0
ffffffffc0200a0a:	70e2                	ld	ra,56(sp)
ffffffffc0200a0c:	7442                	ld	s0,48(sp)
ffffffffc0200a0e:	74a2                	ld	s1,40(sp)
ffffffffc0200a10:	7902                	ld	s2,32(sp)
ffffffffc0200a12:	69e2                	ld	s3,24(sp)
ffffffffc0200a14:	6a42                	ld	s4,16(sp)
ffffffffc0200a16:	6aa2                	ld	s5,8(sp)
ffffffffc0200a18:	853a                	mv	a0,a4
ffffffffc0200a1a:	6121                	addi	sp,sp,64
ffffffffc0200a1c:	8082                	ret
ffffffffc0200a1e:	874e                	mv	a4,s3
ffffffffc0200a20:	8876                	mv	a6,t4
ffffffffc0200a22:	c755                	beqz	a4,ffffffffc0200ace <buddy_system_alloc_pages+0x17c>
ffffffffc0200a24:	0ae96563          	bltu	s2,a4,ffffffffc0200ace <buddy_system_alloc_pages+0x17c>
ffffffffc0200a28:	00471793          	slli	a5,a4,0x4
ffffffffc0200a2c:	00fe06b3          	add	a3,t3,a5
ffffffffc0200a30:	6a94                	ld	a3,16(a3)
ffffffffc0200a32:	07a1                	addi	a5,a5,8
ffffffffc0200a34:	97f2                	add	a5,a5,t3
ffffffffc0200a36:	0cf68c63          	beq	a3,a5,ffffffffc0200b0e <buddy_system_alloc_pages+0x1bc>
ffffffffc0200a3a:	fff7061b          	addiw	a2,a4,-1
ffffffffc0200a3e:	00c495bb          	sllw	a1,s1,a2
ffffffffc0200a42:	00259793          	slli	a5,a1,0x2
ffffffffc0200a46:	97ae                	add	a5,a5,a1
ffffffffc0200a48:	078e                	slli	a5,a5,0x3
ffffffffc0200a4a:	0006ba83          	ld	s5,0(a3)
ffffffffc0200a4e:	0086ba03          	ld	s4,8(a3)
ffffffffc0200a52:	17a1                	addi	a5,a5,-24
ffffffffc0200a54:	fec6ac23          	sw	a2,-8(a3)
ffffffffc0200a58:	97b6                	add	a5,a5,a3
ffffffffc0200a5a:	177d                	addi	a4,a4,-1
ffffffffc0200a5c:	cb90                	sw	a2,16(a5)
ffffffffc0200a5e:	0712                	slli	a4,a4,0x4
ffffffffc0200a60:	014ab423          	sd	s4,8(s5)
ffffffffc0200a64:	00ee05b3          	add	a1,t3,a4
ffffffffc0200a68:	015a3023          	sd	s5,0(s4)
ffffffffc0200a6c:	6990                	ld	a2,16(a1)
ffffffffc0200a6e:	0721                	addi	a4,a4,8
ffffffffc0200a70:	e994                	sd	a3,16(a1)
ffffffffc0200a72:	9772                	add	a4,a4,t3
ffffffffc0200a74:	e298                	sd	a4,0(a3)
ffffffffc0200a76:	01878713          	addi	a4,a5,24
ffffffffc0200a7a:	e218                	sd	a4,0(a2)
ffffffffc0200a7c:	e698                	sd	a4,8(a3)
ffffffffc0200a7e:	f390                	sd	a2,32(a5)
ffffffffc0200a80:	ef94                	sd	a3,24(a5)
ffffffffc0200a82:	f908e3e3          	bltu	a7,a6,ffffffffc0200a08 <buddy_system_alloc_pages+0xb6>
ffffffffc0200a86:	01033783          	ld	a5,16(t1)
ffffffffc0200a8a:	f4f38ae3          	beq	t2,a5,ffffffffc02009de <buddy_system_alloc_pages+0x8c>
ffffffffc0200a8e:	6794                	ld	a3,8(a5)
ffffffffc0200a90:	6390                	ld	a2,0(a5)
ffffffffc0200a92:	fe878713          	addi	a4,a5,-24
ffffffffc0200a96:	17c1                	addi	a5,a5,-16
ffffffffc0200a98:	e614                	sd	a3,8(a2)
ffffffffc0200a9a:	e290                	sd	a2,0(a3)
ffffffffc0200a9c:	4689                	li	a3,2
ffffffffc0200a9e:	40d7b02f          	amoor.d	zero,a3,(a5)
ffffffffc0200aa2:	d725                	beqz	a4,ffffffffc0200a0a <buddy_system_alloc_pages+0xb8>
ffffffffc0200aa4:	0f8e2783          	lw	a5,248(t3)
ffffffffc0200aa8:	9f89                	subw	a5,a5,a0
ffffffffc0200aaa:	00006697          	auipc	a3,0x6
ffffffffc0200aae:	aaf6ab23          	sw	a5,-1354(a3) # ffffffffc0206560 <buddy_s+0xf8>
ffffffffc0200ab2:	bfa1                	j	ffffffffc0200a0a <buddy_system_alloc_pages+0xb8>
ffffffffc0200ab4:	4785                	li	a5,1
ffffffffc0200ab6:	8105                	srli	a0,a0,0x1
ffffffffc0200ab8:	0786                	slli	a5,a5,0x1
ffffffffc0200aba:	fd75                	bnez	a0,ffffffffc0200ab6 <buddy_system_alloc_pages+0x164>
ffffffffc0200abc:	853e                	mv	a0,a5
ffffffffc0200abe:	bd7d                	j	ffffffffc020097c <buddy_system_alloc_pages+0x2a>
ffffffffc0200ac0:	4fe1                	li	t6,24
ffffffffc0200ac2:	4285                	li	t0,1
ffffffffc0200ac4:	43a1                	li	t2,8
ffffffffc0200ac6:	4985                	li	s3,1
ffffffffc0200ac8:	4e85                	li	t4,1
ffffffffc0200aca:	4781                	li	a5,0
ffffffffc0200acc:	bdf1                	j	ffffffffc02009a8 <buddy_system_alloc_pages+0x56>
ffffffffc0200ace:	00001697          	auipc	a3,0x1
ffffffffc0200ad2:	6a268693          	addi	a3,a3,1698 # ffffffffc0202170 <commands+0x648>
ffffffffc0200ad6:	00002617          	auipc	a2,0x2
ffffffffc0200ada:	9e260613          	addi	a2,a2,-1566 # ffffffffc02024b8 <commands+0x990>
ffffffffc0200ade:	04a00593          	li	a1,74
ffffffffc0200ae2:	00002517          	auipc	a0,0x2
ffffffffc0200ae6:	9ee50513          	addi	a0,a0,-1554 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc0200aea:	8bbff0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc0200aee:	00001697          	auipc	a3,0x1
ffffffffc0200af2:	66a68693          	addi	a3,a3,1642 # ffffffffc0202158 <commands+0x630>
ffffffffc0200af6:	00002617          	auipc	a2,0x2
ffffffffc0200afa:	9c260613          	addi	a2,a2,-1598 # ffffffffc02024b8 <commands+0x990>
ffffffffc0200afe:	0a800593          	li	a1,168
ffffffffc0200b02:	00002517          	auipc	a0,0x2
ffffffffc0200b06:	9ce50513          	addi	a0,a0,-1586 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc0200b0a:	89bff0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc0200b0e:	00001697          	auipc	a3,0x1
ffffffffc0200b12:	67a68693          	addi	a3,a3,1658 # ffffffffc0202188 <commands+0x660>
ffffffffc0200b16:	00002617          	auipc	a2,0x2
ffffffffc0200b1a:	9a260613          	addi	a2,a2,-1630 # ffffffffc02024b8 <commands+0x990>
ffffffffc0200b1e:	04b00593          	li	a1,75
ffffffffc0200b22:	00002517          	auipc	a0,0x2
ffffffffc0200b26:	9ae50513          	addi	a0,a0,-1618 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc0200b2a:	87bff0ef          	jal	ra,ffffffffc02003a4 <__panic>

ffffffffc0200b2e <show_buddy_array.constprop.4>:
ffffffffc0200b2e:	00006797          	auipc	a5,0x6
ffffffffc0200b32:	93a78793          	addi	a5,a5,-1734 # ffffffffc0206468 <buddy_s>
ffffffffc0200b36:	4398                	lw	a4,0(a5)
ffffffffc0200b38:	711d                	addi	sp,sp,-96
ffffffffc0200b3a:	ec86                	sd	ra,88(sp)
ffffffffc0200b3c:	e8a2                	sd	s0,80(sp)
ffffffffc0200b3e:	e4a6                	sd	s1,72(sp)
ffffffffc0200b40:	e0ca                	sd	s2,64(sp)
ffffffffc0200b42:	fc4e                	sd	s3,56(sp)
ffffffffc0200b44:	f852                	sd	s4,48(sp)
ffffffffc0200b46:	f456                	sd	s5,40(sp)
ffffffffc0200b48:	f05a                	sd	s6,32(sp)
ffffffffc0200b4a:	ec5e                	sd	s7,24(sp)
ffffffffc0200b4c:	e862                	sd	s8,16(sp)
ffffffffc0200b4e:	e466                	sd	s9,8(sp)
ffffffffc0200b50:	47b5                	li	a5,13
ffffffffc0200b52:	0ae7fc63          	bgeu	a5,a4,ffffffffc0200c0a <show_buddy_array.constprop.4+0xdc>
ffffffffc0200b56:	00002517          	auipc	a0,0x2
ffffffffc0200b5a:	a2a50513          	addi	a0,a0,-1494 # ffffffffc0202580 <buddy_system_pmm_manager+0x80>
ffffffffc0200b5e:	d54ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200b62:	00006497          	auipc	s1,0x6
ffffffffc0200b66:	90e48493          	addi	s1,s1,-1778 # ffffffffc0206470 <buddy_s+0x8>
ffffffffc0200b6a:	4785                	li	a5,1
ffffffffc0200b6c:	4901                	li	s2,0
ffffffffc0200b6e:	00002b17          	auipc	s6,0x2
ffffffffc0200b72:	a52b0b13          	addi	s6,s6,-1454 # ffffffffc02025c0 <buddy_system_pmm_manager+0xc0>
ffffffffc0200b76:	4a85                	li	s5,1
ffffffffc0200b78:	00002a17          	auipc	s4,0x2
ffffffffc0200b7c:	a60a0a13          	addi	s4,s4,-1440 # ffffffffc02025d8 <buddy_system_pmm_manager+0xd8>
ffffffffc0200b80:	00002997          	auipc	s3,0x2
ffffffffc0200b84:	a6098993          	addi	s3,s3,-1440 # ffffffffc02025e0 <buddy_system_pmm_manager+0xe0>
ffffffffc0200b88:	4c39                	li	s8,14
ffffffffc0200b8a:	00002c97          	auipc	s9,0x2
ffffffffc0200b8e:	8d6c8c93          	addi	s9,s9,-1834 # ffffffffc0202460 <commands+0x938>
ffffffffc0200b92:	4bbd                	li	s7,15
ffffffffc0200b94:	a029                	j	ffffffffc0200b9e <show_buddy_array.constprop.4+0x70>
ffffffffc0200b96:	2905                	addiw	s2,s2,1
ffffffffc0200b98:	04c1                	addi	s1,s1,16
ffffffffc0200b9a:	03790f63          	beq	s2,s7,ffffffffc0200bd8 <show_buddy_array.constprop.4+0xaa>
ffffffffc0200b9e:	6480                	ld	s0,8(s1)
ffffffffc0200ba0:	fe940be3          	beq	s0,s1,ffffffffc0200b96 <show_buddy_array.constprop.4+0x68>
ffffffffc0200ba4:	85ca                	mv	a1,s2
ffffffffc0200ba6:	855a                	mv	a0,s6
ffffffffc0200ba8:	d0aff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200bac:	ff842583          	lw	a1,-8(s0)
ffffffffc0200bb0:	8552                	mv	a0,s4
ffffffffc0200bb2:	00ba95bb          	sllw	a1,s5,a1
ffffffffc0200bb6:	cfcff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200bba:	fe840593          	addi	a1,s0,-24
ffffffffc0200bbe:	854e                	mv	a0,s3
ffffffffc0200bc0:	cf2ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200bc4:	6400                	ld	s0,8(s0)
ffffffffc0200bc6:	fc941fe3          	bne	s0,s1,ffffffffc0200ba4 <show_buddy_array.constprop.4+0x76>
ffffffffc0200bca:	01890e63          	beq	s2,s8,ffffffffc0200be6 <show_buddy_array.constprop.4+0xb8>
ffffffffc0200bce:	8566                	mv	a0,s9
ffffffffc0200bd0:	ce2ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200bd4:	4781                	li	a5,0
ffffffffc0200bd6:	b7c1                	j	ffffffffc0200b96 <show_buddy_array.constprop.4+0x68>
ffffffffc0200bd8:	c799                	beqz	a5,ffffffffc0200be6 <show_buddy_array.constprop.4+0xb8>
ffffffffc0200bda:	00002517          	auipc	a0,0x2
ffffffffc0200bde:	a1e50513          	addi	a0,a0,-1506 # ffffffffc02025f8 <buddy_system_pmm_manager+0xf8>
ffffffffc0200be2:	cd0ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200be6:	6446                	ld	s0,80(sp)
ffffffffc0200be8:	60e6                	ld	ra,88(sp)
ffffffffc0200bea:	64a6                	ld	s1,72(sp)
ffffffffc0200bec:	6906                	ld	s2,64(sp)
ffffffffc0200bee:	79e2                	ld	s3,56(sp)
ffffffffc0200bf0:	7a42                	ld	s4,48(sp)
ffffffffc0200bf2:	7aa2                	ld	s5,40(sp)
ffffffffc0200bf4:	7b02                	ld	s6,32(sp)
ffffffffc0200bf6:	6be2                	ld	s7,24(sp)
ffffffffc0200bf8:	6c42                	ld	s8,16(sp)
ffffffffc0200bfa:	6ca2                	ld	s9,8(sp)
ffffffffc0200bfc:	00002517          	auipc	a0,0x2
ffffffffc0200c00:	a1450513          	addi	a0,a0,-1516 # ffffffffc0202610 <buddy_system_pmm_manager+0x110>
ffffffffc0200c04:	6125                	addi	sp,sp,96
ffffffffc0200c06:	cacff06f          	j	ffffffffc02000b2 <cprintf>
ffffffffc0200c0a:	00002697          	auipc	a3,0x2
ffffffffc0200c0e:	92e68693          	addi	a3,a3,-1746 # ffffffffc0202538 <buddy_system_pmm_manager+0x38>
ffffffffc0200c12:	00002617          	auipc	a2,0x2
ffffffffc0200c16:	8a660613          	addi	a2,a2,-1882 # ffffffffc02024b8 <commands+0x990>
ffffffffc0200c1a:	05f00593          	li	a1,95
ffffffffc0200c1e:	00002517          	auipc	a0,0x2
ffffffffc0200c22:	8b250513          	addi	a0,a0,-1870 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc0200c26:	f7eff0ef          	jal	ra,ffffffffc02003a4 <__panic>

ffffffffc0200c2a <buddy_system_check>:
ffffffffc0200c2a:	7179                	addi	sp,sp,-48
ffffffffc0200c2c:	e44e                	sd	s3,8(sp)
ffffffffc0200c2e:	00006997          	auipc	s3,0x6
ffffffffc0200c32:	83a98993          	addi	s3,s3,-1990 # ffffffffc0206468 <buddy_s>
ffffffffc0200c36:	0f89a583          	lw	a1,248(s3)
ffffffffc0200c3a:	00001517          	auipc	a0,0x1
ffffffffc0200c3e:	57650513          	addi	a0,a0,1398 # ffffffffc02021b0 <commands+0x688>
ffffffffc0200c42:	f406                	sd	ra,40(sp)
ffffffffc0200c44:	f022                	sd	s0,32(sp)
ffffffffc0200c46:	ec26                	sd	s1,24(sp)
ffffffffc0200c48:	e84a                	sd	s2,16(sp)
ffffffffc0200c4a:	c68ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200c4e:	00001517          	auipc	a0,0x1
ffffffffc0200c52:	58250513          	addi	a0,a0,1410 # ffffffffc02021d0 <commands+0x6a8>
ffffffffc0200c56:	c5cff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200c5a:	4515                	li	a0,5
ffffffffc0200c5c:	444000ef          	jal	ra,ffffffffc02010a0 <alloc_pages>
ffffffffc0200c60:	84aa                	mv	s1,a0
ffffffffc0200c62:	ecdff0ef          	jal	ra,ffffffffc0200b2e <show_buddy_array.constprop.4>
ffffffffc0200c66:	00001517          	auipc	a0,0x1
ffffffffc0200c6a:	58250513          	addi	a0,a0,1410 # ffffffffc02021e8 <commands+0x6c0>
ffffffffc0200c6e:	c44ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200c72:	4515                	li	a0,5
ffffffffc0200c74:	42c000ef          	jal	ra,ffffffffc02010a0 <alloc_pages>
ffffffffc0200c78:	842a                	mv	s0,a0
ffffffffc0200c7a:	eb5ff0ef          	jal	ra,ffffffffc0200b2e <show_buddy_array.constprop.4>
ffffffffc0200c7e:	00001517          	auipc	a0,0x1
ffffffffc0200c82:	58250513          	addi	a0,a0,1410 # ffffffffc0202200 <commands+0x6d8>
ffffffffc0200c86:	c2cff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200c8a:	4515                	li	a0,5
ffffffffc0200c8c:	414000ef          	jal	ra,ffffffffc02010a0 <alloc_pages>
ffffffffc0200c90:	892a                	mv	s2,a0
ffffffffc0200c92:	e9dff0ef          	jal	ra,ffffffffc0200b2e <show_buddy_array.constprop.4>
ffffffffc0200c96:	85a6                	mv	a1,s1
ffffffffc0200c98:	00001517          	auipc	a0,0x1
ffffffffc0200c9c:	58050513          	addi	a0,a0,1408 # ffffffffc0202218 <commands+0x6f0>
ffffffffc0200ca0:	c12ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200ca4:	85a2                	mv	a1,s0
ffffffffc0200ca6:	00001517          	auipc	a0,0x1
ffffffffc0200caa:	59250513          	addi	a0,a0,1426 # ffffffffc0202238 <commands+0x710>
ffffffffc0200cae:	c04ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200cb2:	85ca                	mv	a1,s2
ffffffffc0200cb4:	00001517          	auipc	a0,0x1
ffffffffc0200cb8:	5a450513          	addi	a0,a0,1444 # ffffffffc0202258 <commands+0x730>
ffffffffc0200cbc:	bf6ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200cc0:	14848163          	beq	s1,s0,ffffffffc0200e02 <buddy_system_check+0x1d8>
ffffffffc0200cc4:	13248f63          	beq	s1,s2,ffffffffc0200e02 <buddy_system_check+0x1d8>
ffffffffc0200cc8:	13240d63          	beq	s0,s2,ffffffffc0200e02 <buddy_system_check+0x1d8>
ffffffffc0200ccc:	409c                	lw	a5,0(s1)
ffffffffc0200cce:	14079a63          	bnez	a5,ffffffffc0200e22 <buddy_system_check+0x1f8>
ffffffffc0200cd2:	401c                	lw	a5,0(s0)
ffffffffc0200cd4:	14079763          	bnez	a5,ffffffffc0200e22 <buddy_system_check+0x1f8>
ffffffffc0200cd8:	00092783          	lw	a5,0(s2)
ffffffffc0200cdc:	14079363          	bnez	a5,ffffffffc0200e22 <buddy_system_check+0x1f8>
ffffffffc0200ce0:	00005797          	auipc	a5,0x5
ffffffffc0200ce4:	77078793          	addi	a5,a5,1904 # ffffffffc0206450 <pages>
ffffffffc0200ce8:	639c                	ld	a5,0(a5)
ffffffffc0200cea:	00001717          	auipc	a4,0x1
ffffffffc0200cee:	4be70713          	addi	a4,a4,1214 # ffffffffc02021a8 <commands+0x680>
ffffffffc0200cf2:	630c                	ld	a1,0(a4)
ffffffffc0200cf4:	40f48733          	sub	a4,s1,a5
ffffffffc0200cf8:	870d                	srai	a4,a4,0x3
ffffffffc0200cfa:	02b70733          	mul	a4,a4,a1
ffffffffc0200cfe:	00002697          	auipc	a3,0x2
ffffffffc0200d02:	eaa68693          	addi	a3,a3,-342 # ffffffffc0202ba8 <nbase>
ffffffffc0200d06:	6290                	ld	a2,0(a3)
ffffffffc0200d08:	00005697          	auipc	a3,0x5
ffffffffc0200d0c:	74068693          	addi	a3,a3,1856 # ffffffffc0206448 <npage>
ffffffffc0200d10:	6294                	ld	a3,0(a3)
ffffffffc0200d12:	06b2                	slli	a3,a3,0xc
ffffffffc0200d14:	9732                	add	a4,a4,a2
ffffffffc0200d16:	0732                	slli	a4,a4,0xc
ffffffffc0200d18:	12d77563          	bgeu	a4,a3,ffffffffc0200e42 <buddy_system_check+0x218>
ffffffffc0200d1c:	40f40733          	sub	a4,s0,a5
ffffffffc0200d20:	870d                	srai	a4,a4,0x3
ffffffffc0200d22:	02b70733          	mul	a4,a4,a1
ffffffffc0200d26:	9732                	add	a4,a4,a2
ffffffffc0200d28:	0732                	slli	a4,a4,0xc
ffffffffc0200d2a:	12d77c63          	bgeu	a4,a3,ffffffffc0200e62 <buddy_system_check+0x238>
ffffffffc0200d2e:	40f907b3          	sub	a5,s2,a5
ffffffffc0200d32:	878d                	srai	a5,a5,0x3
ffffffffc0200d34:	02b787b3          	mul	a5,a5,a1
ffffffffc0200d38:	97b2                	add	a5,a5,a2
ffffffffc0200d3a:	07b2                	slli	a5,a5,0xc
ffffffffc0200d3c:	14d7f363          	bgeu	a5,a3,ffffffffc0200e82 <buddy_system_check+0x258>
ffffffffc0200d40:	4505                	li	a0,1
ffffffffc0200d42:	00006797          	auipc	a5,0x6
ffffffffc0200d46:	8007af23          	sw	zero,-2018(a5) # ffffffffc0206560 <buddy_s+0xf8>
ffffffffc0200d4a:	356000ef          	jal	ra,ffffffffc02010a0 <alloc_pages>
ffffffffc0200d4e:	14051a63          	bnez	a0,ffffffffc0200ea2 <buddy_system_check+0x278>
ffffffffc0200d52:	00001517          	auipc	a0,0x1
ffffffffc0200d56:	60650513          	addi	a0,a0,1542 # ffffffffc0202358 <commands+0x830>
ffffffffc0200d5a:	b58ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200d5e:	8526                	mv	a0,s1
ffffffffc0200d60:	4595                	li	a1,5
ffffffffc0200d62:	37c000ef          	jal	ra,ffffffffc02010de <free_pages>
ffffffffc0200d66:	0f89a583          	lw	a1,248(s3)
ffffffffc0200d6a:	00001517          	auipc	a0,0x1
ffffffffc0200d6e:	60e50513          	addi	a0,a0,1550 # ffffffffc0202378 <commands+0x850>
ffffffffc0200d72:	b40ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200d76:	db9ff0ef          	jal	ra,ffffffffc0200b2e <show_buddy_array.constprop.4>
ffffffffc0200d7a:	00001517          	auipc	a0,0x1
ffffffffc0200d7e:	62e50513          	addi	a0,a0,1582 # ffffffffc02023a8 <commands+0x880>
ffffffffc0200d82:	b30ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200d86:	8522                	mv	a0,s0
ffffffffc0200d88:	4595                	li	a1,5
ffffffffc0200d8a:	354000ef          	jal	ra,ffffffffc02010de <free_pages>
ffffffffc0200d8e:	0f89a583          	lw	a1,248(s3)
ffffffffc0200d92:	00001517          	auipc	a0,0x1
ffffffffc0200d96:	63650513          	addi	a0,a0,1590 # ffffffffc02023c8 <commands+0x8a0>
ffffffffc0200d9a:	b18ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200d9e:	d91ff0ef          	jal	ra,ffffffffc0200b2e <show_buddy_array.constprop.4>
ffffffffc0200da2:	00001517          	auipc	a0,0x1
ffffffffc0200da6:	65650513          	addi	a0,a0,1622 # ffffffffc02023f8 <commands+0x8d0>
ffffffffc0200daa:	b08ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200dae:	854a                	mv	a0,s2
ffffffffc0200db0:	4595                	li	a1,5
ffffffffc0200db2:	32c000ef          	jal	ra,ffffffffc02010de <free_pages>
ffffffffc0200db6:	0f89a583          	lw	a1,248(s3)
ffffffffc0200dba:	00001517          	auipc	a0,0x1
ffffffffc0200dbe:	65e50513          	addi	a0,a0,1630 # ffffffffc0202418 <commands+0x8f0>
ffffffffc0200dc2:	af0ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200dc6:	d69ff0ef          	jal	ra,ffffffffc0200b2e <show_buddy_array.constprop.4>
ffffffffc0200dca:	6791                	lui	a5,0x4
ffffffffc0200dcc:	6511                	lui	a0,0x4
ffffffffc0200dce:	00005717          	auipc	a4,0x5
ffffffffc0200dd2:	78f72923          	sw	a5,1938(a4) # ffffffffc0206560 <buddy_s+0xf8>
ffffffffc0200dd6:	2ca000ef          	jal	ra,ffffffffc02010a0 <alloc_pages>
ffffffffc0200dda:	842a                	mv	s0,a0
ffffffffc0200ddc:	00001517          	auipc	a0,0x1
ffffffffc0200de0:	66c50513          	addi	a0,a0,1644 # ffffffffc0202448 <commands+0x920>
ffffffffc0200de4:	aceff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200de8:	d47ff0ef          	jal	ra,ffffffffc0200b2e <show_buddy_array.constprop.4>
ffffffffc0200dec:	8522                	mv	a0,s0
ffffffffc0200dee:	6591                	lui	a1,0x4
ffffffffc0200df0:	2ee000ef          	jal	ra,ffffffffc02010de <free_pages>
ffffffffc0200df4:	7402                	ld	s0,32(sp)
ffffffffc0200df6:	70a2                	ld	ra,40(sp)
ffffffffc0200df8:	64e2                	ld	s1,24(sp)
ffffffffc0200dfa:	6942                	ld	s2,16(sp)
ffffffffc0200dfc:	69a2                	ld	s3,8(sp)
ffffffffc0200dfe:	6145                	addi	sp,sp,48
ffffffffc0200e00:	b33d                	j	ffffffffc0200b2e <show_buddy_array.constprop.4>
ffffffffc0200e02:	00001697          	auipc	a3,0x1
ffffffffc0200e06:	47668693          	addi	a3,a3,1142 # ffffffffc0202278 <commands+0x750>
ffffffffc0200e0a:	00001617          	auipc	a2,0x1
ffffffffc0200e0e:	6ae60613          	addi	a2,a2,1710 # ffffffffc02024b8 <commands+0x990>
ffffffffc0200e12:	13200593          	li	a1,306
ffffffffc0200e16:	00001517          	auipc	a0,0x1
ffffffffc0200e1a:	6ba50513          	addi	a0,a0,1722 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc0200e1e:	d86ff0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc0200e22:	00001697          	auipc	a3,0x1
ffffffffc0200e26:	47e68693          	addi	a3,a3,1150 # ffffffffc02022a0 <commands+0x778>
ffffffffc0200e2a:	00001617          	auipc	a2,0x1
ffffffffc0200e2e:	68e60613          	addi	a2,a2,1678 # ffffffffc02024b8 <commands+0x990>
ffffffffc0200e32:	13300593          	li	a1,307
ffffffffc0200e36:	00001517          	auipc	a0,0x1
ffffffffc0200e3a:	69a50513          	addi	a0,a0,1690 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc0200e3e:	d66ff0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc0200e42:	00001697          	auipc	a3,0x1
ffffffffc0200e46:	49e68693          	addi	a3,a3,1182 # ffffffffc02022e0 <commands+0x7b8>
ffffffffc0200e4a:	00001617          	auipc	a2,0x1
ffffffffc0200e4e:	66e60613          	addi	a2,a2,1646 # ffffffffc02024b8 <commands+0x990>
ffffffffc0200e52:	13500593          	li	a1,309
ffffffffc0200e56:	00001517          	auipc	a0,0x1
ffffffffc0200e5a:	67a50513          	addi	a0,a0,1658 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc0200e5e:	d46ff0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc0200e62:	00001697          	auipc	a3,0x1
ffffffffc0200e66:	49e68693          	addi	a3,a3,1182 # ffffffffc0202300 <commands+0x7d8>
ffffffffc0200e6a:	00001617          	auipc	a2,0x1
ffffffffc0200e6e:	64e60613          	addi	a2,a2,1614 # ffffffffc02024b8 <commands+0x990>
ffffffffc0200e72:	13600593          	li	a1,310
ffffffffc0200e76:	00001517          	auipc	a0,0x1
ffffffffc0200e7a:	65a50513          	addi	a0,a0,1626 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc0200e7e:	d26ff0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc0200e82:	00001697          	auipc	a3,0x1
ffffffffc0200e86:	49e68693          	addi	a3,a3,1182 # ffffffffc0202320 <commands+0x7f8>
ffffffffc0200e8a:	00001617          	auipc	a2,0x1
ffffffffc0200e8e:	62e60613          	addi	a2,a2,1582 # ffffffffc02024b8 <commands+0x990>
ffffffffc0200e92:	13700593          	li	a1,311
ffffffffc0200e96:	00001517          	auipc	a0,0x1
ffffffffc0200e9a:	63a50513          	addi	a0,a0,1594 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc0200e9e:	d06ff0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc0200ea2:	00001697          	auipc	a3,0x1
ffffffffc0200ea6:	49e68693          	addi	a3,a3,1182 # ffffffffc0202340 <commands+0x818>
ffffffffc0200eaa:	00001617          	auipc	a2,0x1
ffffffffc0200eae:	60e60613          	addi	a2,a2,1550 # ffffffffc02024b8 <commands+0x990>
ffffffffc0200eb2:	13d00593          	li	a1,317
ffffffffc0200eb6:	00001517          	auipc	a0,0x1
ffffffffc0200eba:	61a50513          	addi	a0,a0,1562 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc0200ebe:	ce6ff0ef          	jal	ra,ffffffffc02003a4 <__panic>

ffffffffc0200ec2 <buddy_system_free_pages>:
ffffffffc0200ec2:	7179                	addi	sp,sp,-48
ffffffffc0200ec4:	f406                	sd	ra,40(sp)
ffffffffc0200ec6:	f022                	sd	s0,32(sp)
ffffffffc0200ec8:	ec26                	sd	s1,24(sp)
ffffffffc0200eca:	e84a                	sd	s2,16(sp)
ffffffffc0200ecc:	e44e                	sd	s3,8(sp)
ffffffffc0200ece:	16058b63          	beqz	a1,ffffffffc0201044 <buddy_system_free_pages+0x182>
ffffffffc0200ed2:	4918                	lw	a4,16(a0)
ffffffffc0200ed4:	fff58793          	addi	a5,a1,-1 # 3fff <kern_entry-0xffffffffc01fc001>
ffffffffc0200ed8:	4485                	li	s1,1
ffffffffc0200eda:	00e494bb          	sllw	s1,s1,a4
ffffffffc0200ede:	8fed                	and	a5,a5,a1
ffffffffc0200ee0:	842a                	mv	s0,a0
ffffffffc0200ee2:	0004861b          	sext.w	a2,s1
ffffffffc0200ee6:	14079963          	bnez	a5,ffffffffc0201038 <buddy_system_free_pages+0x176>
ffffffffc0200eea:	02049793          	slli	a5,s1,0x20
ffffffffc0200eee:	9381                	srli	a5,a5,0x20
ffffffffc0200ef0:	16b79a63          	bne	a5,a1,ffffffffc0201064 <buddy_system_free_pages+0x1a2>
ffffffffc0200ef4:	00005797          	auipc	a5,0x5
ffffffffc0200ef8:	55c78793          	addi	a5,a5,1372 # ffffffffc0206450 <pages>
ffffffffc0200efc:	639c                	ld	a5,0(a5)
ffffffffc0200efe:	00001717          	auipc	a4,0x1
ffffffffc0200f02:	2aa70713          	addi	a4,a4,682 # ffffffffc02021a8 <commands+0x680>
ffffffffc0200f06:	630c                	ld	a1,0(a4)
ffffffffc0200f08:	40f407b3          	sub	a5,s0,a5
ffffffffc0200f0c:	878d                	srai	a5,a5,0x3
ffffffffc0200f0e:	02b787b3          	mul	a5,a5,a1
ffffffffc0200f12:	00002717          	auipc	a4,0x2
ffffffffc0200f16:	c9670713          	addi	a4,a4,-874 # ffffffffc0202ba8 <nbase>
ffffffffc0200f1a:	630c                	ld	a1,0(a4)
ffffffffc0200f1c:	00001517          	auipc	a0,0x1
ffffffffc0200f20:	56450513          	addi	a0,a0,1380 # ffffffffc0202480 <commands+0x958>
ffffffffc0200f24:	95be                	add	a1,a1,a5
ffffffffc0200f26:	98cff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200f2a:	4810                	lw	a2,16(s0)
ffffffffc0200f2c:	4785                	li	a5,1
ffffffffc0200f2e:	3fdf1eb7          	lui	t4,0x3fdf1
ffffffffc0200f32:	00c796bb          	sllw	a3,a5,a2
ffffffffc0200f36:	00269793          	slli	a5,a3,0x2
ffffffffc0200f3a:	02061713          	slli	a4,a2,0x20
ffffffffc0200f3e:	ce8e8e93          	addi	t4,t4,-792 # 3fdf0ce8 <kern_entry-0xffffffff8040f318>
ffffffffc0200f42:	97b6                	add	a5,a5,a3
ffffffffc0200f44:	9301                	srli	a4,a4,0x20
ffffffffc0200f46:	00005517          	auipc	a0,0x5
ffffffffc0200f4a:	52250513          	addi	a0,a0,1314 # ffffffffc0206468 <buddy_s>
ffffffffc0200f4e:	0712                	slli	a4,a4,0x4
ffffffffc0200f50:	01d406b3          	add	a3,s0,t4
ffffffffc0200f54:	078e                	slli	a5,a5,0x3
ffffffffc0200f56:	00e50833          	add	a6,a0,a4
ffffffffc0200f5a:	8fb5                	xor	a5,a5,a3
ffffffffc0200f5c:	01083583          	ld	a1,16(a6)
ffffffffc0200f60:	41d787b3          	sub	a5,a5,t4
ffffffffc0200f64:	6794                	ld	a3,8(a5)
ffffffffc0200f66:	01840e13          	addi	t3,s0,24
ffffffffc0200f6a:	01c5b023          	sd	t3,0(a1)
ffffffffc0200f6e:	0721                	addi	a4,a4,8
ffffffffc0200f70:	01c83823          	sd	t3,16(a6)
ffffffffc0200f74:	972a                	add	a4,a4,a0
ffffffffc0200f76:	8285                	srli	a3,a3,0x1
ffffffffc0200f78:	ec18                	sd	a4,24(s0)
ffffffffc0200f7a:	f00c                	sd	a1,32(s0)
ffffffffc0200f7c:	0016f713          	andi	a4,a3,1
ffffffffc0200f80:	00840f13          	addi	t5,s0,8
ffffffffc0200f84:	eb49                	bnez	a4,ffffffffc0201016 <buddy_system_free_pages+0x154>
ffffffffc0200f86:	4118                	lw	a4,0(a0)
ffffffffc0200f88:	08e67763          	bgeu	a2,a4,ffffffffc0201016 <buddy_system_free_pages+0x154>
ffffffffc0200f8c:	53fd                	li	t2,-1
ffffffffc0200f8e:	52f5                	li	t0,-3
ffffffffc0200f90:	4f85                	li	t6,1
ffffffffc0200f92:	0087fd63          	bgeu	a5,s0,ffffffffc0200fac <buddy_system_free_pages+0xea>
ffffffffc0200f96:	00742823          	sw	t2,16(s0)
ffffffffc0200f9a:	605f302f          	amoand.d	zero,t0,(t5)
ffffffffc0200f9e:	8722                	mv	a4,s0
ffffffffc0200fa0:	00878f13          	addi	t5,a5,8
ffffffffc0200fa4:	843e                	mv	s0,a5
ffffffffc0200fa6:	01878e13          	addi	t3,a5,24
ffffffffc0200faa:	87ba                	mv	a5,a4
ffffffffc0200fac:	6c14                	ld	a3,24(s0)
ffffffffc0200fae:	7018                	ld	a4,32(s0)
ffffffffc0200fb0:	4810                	lw	a2,16(s0)
ffffffffc0200fb2:	01d405b3          	add	a1,s0,t4
ffffffffc0200fb6:	e698                	sd	a4,8(a3)
ffffffffc0200fb8:	2605                	addiw	a2,a2,1
ffffffffc0200fba:	e314                	sd	a3,0(a4)
ffffffffc0200fbc:	0006091b          	sext.w	s2,a2
ffffffffc0200fc0:	0187b983          	ld	s3,24(a5)
ffffffffc0200fc4:	0207b303          	ld	t1,32(a5)
ffffffffc0200fc8:	02061713          	slli	a4,a2,0x20
ffffffffc0200fcc:	012f97bb          	sllw	a5,t6,s2
ffffffffc0200fd0:	00279693          	slli	a3,a5,0x2
ffffffffc0200fd4:	9301                	srli	a4,a4,0x20
ffffffffc0200fd6:	0712                	slli	a4,a4,0x4
ffffffffc0200fd8:	96be                	add	a3,a3,a5
ffffffffc0200fda:	0069b423          	sd	t1,8(s3)
ffffffffc0200fde:	00e508b3          	add	a7,a0,a4
ffffffffc0200fe2:	068e                	slli	a3,a3,0x3
ffffffffc0200fe4:	0108b803          	ld	a6,16(a7)
ffffffffc0200fe8:	00b6c7b3          	xor	a5,a3,a1
ffffffffc0200fec:	01333023          	sd	s3,0(t1)
ffffffffc0200ff0:	41d787b3          	sub	a5,a5,t4
ffffffffc0200ff4:	6794                	ld	a3,8(a5)
ffffffffc0200ff6:	c810                	sw	a2,16(s0)
ffffffffc0200ff8:	01c83023          	sd	t3,0(a6)
ffffffffc0200ffc:	0721                	addi	a4,a4,8
ffffffffc0200ffe:	01c8b823          	sd	t3,16(a7)
ffffffffc0201002:	972a                	add	a4,a4,a0
ffffffffc0201004:	ec18                	sd	a4,24(s0)
ffffffffc0201006:	03043023          	sd	a6,32(s0)
ffffffffc020100a:	0026f713          	andi	a4,a3,2
ffffffffc020100e:	e701                	bnez	a4,ffffffffc0201016 <buddy_system_free_pages+0x154>
ffffffffc0201010:	4118                	lw	a4,0(a0)
ffffffffc0201012:	f8e960e3          	bltu	s2,a4,ffffffffc0200f92 <buddy_system_free_pages+0xd0>
ffffffffc0201016:	57f5                	li	a5,-3
ffffffffc0201018:	60ff302f          	amoand.d	zero,a5,(t5)
ffffffffc020101c:	0f852783          	lw	a5,248(a0)
ffffffffc0201020:	70a2                	ld	ra,40(sp)
ffffffffc0201022:	7402                	ld	s0,32(sp)
ffffffffc0201024:	9cbd                	addw	s1,s1,a5
ffffffffc0201026:	00005797          	auipc	a5,0x5
ffffffffc020102a:	5297ad23          	sw	s1,1338(a5) # ffffffffc0206560 <buddy_s+0xf8>
ffffffffc020102e:	6942                	ld	s2,16(sp)
ffffffffc0201030:	64e2                	ld	s1,24(sp)
ffffffffc0201032:	69a2                	ld	s3,8(sp)
ffffffffc0201034:	6145                	addi	sp,sp,48
ffffffffc0201036:	8082                	ret
ffffffffc0201038:	4785                	li	a5,1
ffffffffc020103a:	8185                	srli	a1,a1,0x1
ffffffffc020103c:	0786                	slli	a5,a5,0x1
ffffffffc020103e:	fdf5                	bnez	a1,ffffffffc020103a <buddy_system_free_pages+0x178>
ffffffffc0201040:	85be                	mv	a1,a5
ffffffffc0201042:	b565                	j	ffffffffc0200eea <buddy_system_free_pages+0x28>
ffffffffc0201044:	00001697          	auipc	a3,0x1
ffffffffc0201048:	46c68693          	addi	a3,a3,1132 # ffffffffc02024b0 <commands+0x988>
ffffffffc020104c:	00001617          	auipc	a2,0x1
ffffffffc0201050:	46c60613          	addi	a2,a2,1132 # ffffffffc02024b8 <commands+0x990>
ffffffffc0201054:	0e800593          	li	a1,232
ffffffffc0201058:	00001517          	auipc	a0,0x1
ffffffffc020105c:	47850513          	addi	a0,a0,1144 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc0201060:	b44ff0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc0201064:	00001697          	auipc	a3,0x1
ffffffffc0201068:	40468693          	addi	a3,a3,1028 # ffffffffc0202468 <commands+0x940>
ffffffffc020106c:	00001617          	auipc	a2,0x1
ffffffffc0201070:	44c60613          	addi	a2,a2,1100 # ffffffffc02024b8 <commands+0x990>
ffffffffc0201074:	0ea00593          	li	a1,234
ffffffffc0201078:	00001517          	auipc	a0,0x1
ffffffffc020107c:	45850513          	addi	a0,a0,1112 # ffffffffc02024d0 <commands+0x9a8>
ffffffffc0201080:	b24ff0ef          	jal	ra,ffffffffc02003a4 <__panic>

ffffffffc0201084 <pa2page.part.0>:
ffffffffc0201084:	1141                	addi	sp,sp,-16
ffffffffc0201086:	00001617          	auipc	a2,0x1
ffffffffc020108a:	5ea60613          	addi	a2,a2,1514 # ffffffffc0202670 <buddy_system_pmm_manager+0x170>
ffffffffc020108e:	07200593          	li	a1,114
ffffffffc0201092:	00001517          	auipc	a0,0x1
ffffffffc0201096:	5fe50513          	addi	a0,a0,1534 # ffffffffc0202690 <buddy_system_pmm_manager+0x190>
ffffffffc020109a:	e406                	sd	ra,8(sp)
ffffffffc020109c:	b08ff0ef          	jal	ra,ffffffffc02003a4 <__panic>

ffffffffc02010a0 <alloc_pages>:
ffffffffc02010a0:	100027f3          	csrr	a5,sstatus
ffffffffc02010a4:	8b89                	andi	a5,a5,2
ffffffffc02010a6:	e799                	bnez	a5,ffffffffc02010b4 <alloc_pages+0x14>
ffffffffc02010a8:	00005797          	auipc	a5,0x5
ffffffffc02010ac:	3807b783          	ld	a5,896(a5) # ffffffffc0206428 <pmm_manager>
ffffffffc02010b0:	6f9c                	ld	a5,24(a5)
ffffffffc02010b2:	8782                	jr	a5
ffffffffc02010b4:	1141                	addi	sp,sp,-16
ffffffffc02010b6:	e406                	sd	ra,8(sp)
ffffffffc02010b8:	e022                	sd	s0,0(sp)
ffffffffc02010ba:	842a                	mv	s0,a0
ffffffffc02010bc:	b9eff0ef          	jal	ra,ffffffffc020045a <intr_disable>
ffffffffc02010c0:	00005797          	auipc	a5,0x5
ffffffffc02010c4:	3687b783          	ld	a5,872(a5) # ffffffffc0206428 <pmm_manager>
ffffffffc02010c8:	6f9c                	ld	a5,24(a5)
ffffffffc02010ca:	8522                	mv	a0,s0
ffffffffc02010cc:	9782                	jalr	a5
ffffffffc02010ce:	842a                	mv	s0,a0
ffffffffc02010d0:	b84ff0ef          	jal	ra,ffffffffc0200454 <intr_enable>
ffffffffc02010d4:	60a2                	ld	ra,8(sp)
ffffffffc02010d6:	8522                	mv	a0,s0
ffffffffc02010d8:	6402                	ld	s0,0(sp)
ffffffffc02010da:	0141                	addi	sp,sp,16
ffffffffc02010dc:	8082                	ret

ffffffffc02010de <free_pages>:
ffffffffc02010de:	100027f3          	csrr	a5,sstatus
ffffffffc02010e2:	8b89                	andi	a5,a5,2
ffffffffc02010e4:	e799                	bnez	a5,ffffffffc02010f2 <free_pages+0x14>
ffffffffc02010e6:	00005797          	auipc	a5,0x5
ffffffffc02010ea:	3427b783          	ld	a5,834(a5) # ffffffffc0206428 <pmm_manager>
ffffffffc02010ee:	739c                	ld	a5,32(a5)
ffffffffc02010f0:	8782                	jr	a5
ffffffffc02010f2:	1101                	addi	sp,sp,-32
ffffffffc02010f4:	ec06                	sd	ra,24(sp)
ffffffffc02010f6:	e822                	sd	s0,16(sp)
ffffffffc02010f8:	e426                	sd	s1,8(sp)
ffffffffc02010fa:	842a                	mv	s0,a0
ffffffffc02010fc:	84ae                	mv	s1,a1
ffffffffc02010fe:	b5cff0ef          	jal	ra,ffffffffc020045a <intr_disable>
ffffffffc0201102:	00005797          	auipc	a5,0x5
ffffffffc0201106:	3267b783          	ld	a5,806(a5) # ffffffffc0206428 <pmm_manager>
ffffffffc020110a:	739c                	ld	a5,32(a5)
ffffffffc020110c:	85a6                	mv	a1,s1
ffffffffc020110e:	8522                	mv	a0,s0
ffffffffc0201110:	9782                	jalr	a5
ffffffffc0201112:	6442                	ld	s0,16(sp)
ffffffffc0201114:	60e2                	ld	ra,24(sp)
ffffffffc0201116:	64a2                	ld	s1,8(sp)
ffffffffc0201118:	6105                	addi	sp,sp,32
ffffffffc020111a:	b3aff06f          	j	ffffffffc0200454 <intr_enable>

ffffffffc020111e <pmm_init>:
ffffffffc020111e:	00001797          	auipc	a5,0x1
ffffffffc0201122:	3e278793          	addi	a5,a5,994 # ffffffffc0202500 <buddy_system_pmm_manager>
ffffffffc0201126:	638c                	ld	a1,0(a5)
ffffffffc0201128:	715d                	addi	sp,sp,-80
ffffffffc020112a:	e486                	sd	ra,72(sp)
ffffffffc020112c:	e0a2                	sd	s0,64(sp)
ffffffffc020112e:	fc26                	sd	s1,56(sp)
ffffffffc0201130:	f84a                	sd	s2,48(sp)
ffffffffc0201132:	f44e                	sd	s3,40(sp)
ffffffffc0201134:	f052                	sd	s4,32(sp)
ffffffffc0201136:	ec56                	sd	s5,24(sp)
ffffffffc0201138:	e85a                	sd	s6,16(sp)
ffffffffc020113a:	e45e                	sd	s7,8(sp)
ffffffffc020113c:	e062                	sd	s8,0(sp)
ffffffffc020113e:	00005997          	auipc	s3,0x5
ffffffffc0201142:	2ea98993          	addi	s3,s3,746 # ffffffffc0206428 <pmm_manager>
ffffffffc0201146:	00001517          	auipc	a0,0x1
ffffffffc020114a:	55a50513          	addi	a0,a0,1370 # ffffffffc02026a0 <buddy_system_pmm_manager+0x1a0>
ffffffffc020114e:	00f9b023          	sd	a5,0(s3)
ffffffffc0201152:	f61fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0201156:	0009b783          	ld	a5,0(s3)
ffffffffc020115a:	00005917          	auipc	s2,0x5
ffffffffc020115e:	2e690913          	addi	s2,s2,742 # ffffffffc0206440 <va_pa_offset>
ffffffffc0201162:	4445                	li	s0,17
ffffffffc0201164:	679c                	ld	a5,8(a5)
ffffffffc0201166:	046e                	slli	s0,s0,0x1b
ffffffffc0201168:	00005a17          	auipc	s4,0x5
ffffffffc020116c:	2e0a0a13          	addi	s4,s4,736 # ffffffffc0206448 <npage>
ffffffffc0201170:	9782                	jalr	a5
ffffffffc0201172:	57f5                	li	a5,-3
ffffffffc0201174:	07fa                	slli	a5,a5,0x1e
ffffffffc0201176:	00001517          	auipc	a0,0x1
ffffffffc020117a:	54250513          	addi	a0,a0,1346 # ffffffffc02026b8 <buddy_system_pmm_manager+0x1b8>
ffffffffc020117e:	00f93023          	sd	a5,0(s2)
ffffffffc0201182:	f31fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0201186:	40100613          	li	a2,1025
ffffffffc020118a:	fff40693          	addi	a3,s0,-1
ffffffffc020118e:	0656                	slli	a2,a2,0x15
ffffffffc0201190:	07e005b7          	lui	a1,0x7e00
ffffffffc0201194:	00001517          	auipc	a0,0x1
ffffffffc0201198:	53c50513          	addi	a0,a0,1340 # ffffffffc02026d0 <buddy_system_pmm_manager+0x1d0>
ffffffffc020119c:	f17fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02011a0:	85a2                	mv	a1,s0
ffffffffc02011a2:	00001517          	auipc	a0,0x1
ffffffffc02011a6:	55e50513          	addi	a0,a0,1374 # ffffffffc0202700 <buddy_system_pmm_manager+0x200>
ffffffffc02011aa:	f09fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02011ae:	000887b7          	lui	a5,0x88
ffffffffc02011b2:	000885b7          	lui	a1,0x88
ffffffffc02011b6:	00001517          	auipc	a0,0x1
ffffffffc02011ba:	56250513          	addi	a0,a0,1378 # ffffffffc0202718 <buddy_system_pmm_manager+0x218>
ffffffffc02011be:	00fa3023          	sd	a5,0(s4)
ffffffffc02011c2:	ef1fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02011c6:	000805b7          	lui	a1,0x80
ffffffffc02011ca:	00001517          	auipc	a0,0x1
ffffffffc02011ce:	56650513          	addi	a0,a0,1382 # ffffffffc0202730 <buddy_system_pmm_manager+0x230>
ffffffffc02011d2:	ee1fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02011d6:	77fd                	lui	a5,0xfffff
ffffffffc02011d8:	00006697          	auipc	a3,0x6
ffffffffc02011dc:	38f68693          	addi	a3,a3,911 # ffffffffc0207567 <end+0xfff>
ffffffffc02011e0:	8efd                	and	a3,a3,a5
ffffffffc02011e2:	00005497          	auipc	s1,0x5
ffffffffc02011e6:	26e48493          	addi	s1,s1,622 # ffffffffc0206450 <pages>
ffffffffc02011ea:	e094                	sd	a3,0(s1)
ffffffffc02011ec:	c02007b7          	lui	a5,0xc0200
ffffffffc02011f0:	22f6ee63          	bltu	a3,a5,ffffffffc020142c <pmm_init+0x30e>
ffffffffc02011f4:	00093583          	ld	a1,0(s2)
ffffffffc02011f8:	00001517          	auipc	a0,0x1
ffffffffc02011fc:	58850513          	addi	a0,a0,1416 # ffffffffc0202780 <buddy_system_pmm_manager+0x280>
ffffffffc0201200:	40b685b3          	sub	a1,a3,a1
ffffffffc0201204:	eaffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0201208:	000a3503          	ld	a0,0(s4)
ffffffffc020120c:	000807b7          	lui	a5,0x80
ffffffffc0201210:	4681                	li	a3,0
ffffffffc0201212:	4701                	li	a4,0
ffffffffc0201214:	4585                	li	a1,1
ffffffffc0201216:	fff80637          	lui	a2,0xfff80
ffffffffc020121a:	00f50f63          	beq	a0,a5,ffffffffc0201238 <pmm_init+0x11a>
ffffffffc020121e:	609c                	ld	a5,0(s1)
ffffffffc0201220:	97b6                	add	a5,a5,a3
ffffffffc0201222:	07a1                	addi	a5,a5,8
ffffffffc0201224:	40b7b02f          	amoor.d	zero,a1,(a5)
ffffffffc0201228:	000a3783          	ld	a5,0(s4)
ffffffffc020122c:	0705                	addi	a4,a4,1
ffffffffc020122e:	02868693          	addi	a3,a3,40
ffffffffc0201232:	97b2                	add	a5,a5,a2
ffffffffc0201234:	fef765e3          	bltu	a4,a5,ffffffffc020121e <pmm_init+0x100>
ffffffffc0201238:	6094                	ld	a3,0(s1)
ffffffffc020123a:	c02007b7          	lui	a5,0xc0200
ffffffffc020123e:	1af6e063          	bltu	a3,a5,ffffffffc02013de <pmm_init+0x2c0>
ffffffffc0201242:	02800a93          	li	s5,40
ffffffffc0201246:	4401                	li	s0,0
ffffffffc0201248:	00001b97          	auipc	s7,0x1
ffffffffc020124c:	560b8b93          	addi	s7,s7,1376 # ffffffffc02027a8 <buddy_system_pmm_manager+0x2a8>
ffffffffc0201250:	4b15                	li	s6,5
ffffffffc0201252:	c0200c37          	lui	s8,0xc0200
ffffffffc0201256:	a039                	j	ffffffffc0201264 <pmm_init+0x146>
ffffffffc0201258:	6094                	ld	a3,0(s1)
ffffffffc020125a:	96d6                	add	a3,a3,s5
ffffffffc020125c:	028a8a93          	addi	s5,s5,40
ffffffffc0201260:	1786ef63          	bltu	a3,s8,ffffffffc02013de <pmm_init+0x2c0>
ffffffffc0201264:	00093603          	ld	a2,0(s2)
ffffffffc0201268:	85a2                	mv	a1,s0
ffffffffc020126a:	855e                	mv	a0,s7
ffffffffc020126c:	0405                	addi	s0,s0,1
ffffffffc020126e:	40c68633          	sub	a2,a3,a2
ffffffffc0201272:	e41fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0201276:	ff6411e3          	bne	s0,s6,ffffffffc0201258 <pmm_init+0x13a>
ffffffffc020127a:	000a3703          	ld	a4,0(s4)
ffffffffc020127e:	6080                	ld	s0,0(s1)
ffffffffc0201280:	00271793          	slli	a5,a4,0x2
ffffffffc0201284:	97ba                	add	a5,a5,a4
ffffffffc0201286:	078e                	slli	a5,a5,0x3
ffffffffc0201288:	943e                	add	s0,s0,a5
ffffffffc020128a:	fec007b7          	lui	a5,0xfec00
ffffffffc020128e:	943e                	add	s0,s0,a5
ffffffffc0201290:	c02007b7          	lui	a5,0xc0200
ffffffffc0201294:	1af46863          	bltu	s0,a5,ffffffffc0201444 <pmm_init+0x326>
ffffffffc0201298:	00093783          	ld	a5,0(s2)
ffffffffc020129c:	02800593          	li	a1,40
ffffffffc02012a0:	00001517          	auipc	a0,0x1
ffffffffc02012a4:	53050513          	addi	a0,a0,1328 # ffffffffc02027d0 <buddy_system_pmm_manager+0x2d0>
ffffffffc02012a8:	6a85                	lui	s5,0x1
ffffffffc02012aa:	8c1d                	sub	s0,s0,a5
ffffffffc02012ac:	1afd                	addi	s5,s5,-1
ffffffffc02012ae:	e05fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02012b2:	77fd                	lui	a5,0xfffff
ffffffffc02012b4:	85a2                	mv	a1,s0
ffffffffc02012b6:	9aa2                	add	s5,s5,s0
ffffffffc02012b8:	00001517          	auipc	a0,0x1
ffffffffc02012bc:	53850513          	addi	a0,a0,1336 # ffffffffc02027f0 <buddy_system_pmm_manager+0x2f0>
ffffffffc02012c0:	00fafab3          	and	s5,s5,a5
ffffffffc02012c4:	deffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02012c8:	85d6                	mv	a1,s5
ffffffffc02012ca:	00001517          	auipc	a0,0x1
ffffffffc02012ce:	53e50513          	addi	a0,a0,1342 # ffffffffc0202808 <buddy_system_pmm_manager+0x308>
ffffffffc02012d2:	de1fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02012d6:	4b45                	li	s6,17
ffffffffc02012d8:	01bb1593          	slli	a1,s6,0x1b
ffffffffc02012dc:	00001517          	auipc	a0,0x1
ffffffffc02012e0:	54450513          	addi	a0,a0,1348 # ffffffffc0202820 <buddy_system_pmm_manager+0x320>
ffffffffc02012e4:	0b6e                	slli	s6,s6,0x1b
ffffffffc02012e6:	dcdfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02012ea:	00cadb93          	srli	s7,s5,0xc
ffffffffc02012ee:	0d646263          	bltu	s0,s6,ffffffffc02013b2 <pmm_init+0x294>
ffffffffc02012f2:	000a3783          	ld	a5,0(s4)
ffffffffc02012f6:	10fbf063          	bgeu	s7,a5,ffffffffc02013f6 <pmm_init+0x2d8>
ffffffffc02012fa:	fff807b7          	lui	a5,0xfff80
ffffffffc02012fe:	97de                	add	a5,a5,s7
ffffffffc0201300:	00279413          	slli	s0,a5,0x2
ffffffffc0201304:	608c                	ld	a1,0(s1)
ffffffffc0201306:	943e                	add	s0,s0,a5
ffffffffc0201308:	040e                	slli	s0,s0,0x3
ffffffffc020130a:	95a2                	add	a1,a1,s0
ffffffffc020130c:	00001517          	auipc	a0,0x1
ffffffffc0201310:	52c50513          	addi	a0,a0,1324 # ffffffffc0202838 <buddy_system_pmm_manager+0x338>
ffffffffc0201314:	d9ffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0201318:	000a3783          	ld	a5,0(s4)
ffffffffc020131c:	0cfbfd63          	bgeu	s7,a5,ffffffffc02013f6 <pmm_init+0x2d8>
ffffffffc0201320:	6094                	ld	a3,0(s1)
ffffffffc0201322:	c02004b7          	lui	s1,0xc0200
ffffffffc0201326:	96a2                	add	a3,a3,s0
ffffffffc0201328:	0c96e963          	bltu	a3,s1,ffffffffc02013fa <pmm_init+0x2dc>
ffffffffc020132c:	00093583          	ld	a1,0(s2)
ffffffffc0201330:	00001517          	auipc	a0,0x1
ffffffffc0201334:	55850513          	addi	a0,a0,1368 # ffffffffc0202888 <buddy_system_pmm_manager+0x388>
ffffffffc0201338:	40b685b3          	sub	a1,a3,a1
ffffffffc020133c:	d77fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0201340:	45c5                	li	a1,17
ffffffffc0201342:	05ee                	slli	a1,a1,0x1b
ffffffffc0201344:	415585b3          	sub	a1,a1,s5
ffffffffc0201348:	81b1                	srli	a1,a1,0xc
ffffffffc020134a:	00001517          	auipc	a0,0x1
ffffffffc020134e:	58e50513          	addi	a0,a0,1422 # ffffffffc02028d8 <buddy_system_pmm_manager+0x3d8>
ffffffffc0201352:	d61fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0201356:	0009b783          	ld	a5,0(s3)
ffffffffc020135a:	7b9c                	ld	a5,48(a5)
ffffffffc020135c:	9782                	jalr	a5
ffffffffc020135e:	00001517          	auipc	a0,0x1
ffffffffc0201362:	5a250513          	addi	a0,a0,1442 # ffffffffc0202900 <buddy_system_pmm_manager+0x400>
ffffffffc0201366:	d4dfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020136a:	00004597          	auipc	a1,0x4
ffffffffc020136e:	c9658593          	addi	a1,a1,-874 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201372:	00005797          	auipc	a5,0x5
ffffffffc0201376:	0cb7b323          	sd	a1,198(a5) # ffffffffc0206438 <satp_virtual>
ffffffffc020137a:	0895ec63          	bltu	a1,s1,ffffffffc0201412 <pmm_init+0x2f4>
ffffffffc020137e:	00093783          	ld	a5,0(s2)
ffffffffc0201382:	6406                	ld	s0,64(sp)
ffffffffc0201384:	60a6                	ld	ra,72(sp)
ffffffffc0201386:	74e2                	ld	s1,56(sp)
ffffffffc0201388:	7942                	ld	s2,48(sp)
ffffffffc020138a:	79a2                	ld	s3,40(sp)
ffffffffc020138c:	7a02                	ld	s4,32(sp)
ffffffffc020138e:	6ae2                	ld	s5,24(sp)
ffffffffc0201390:	6b42                	ld	s6,16(sp)
ffffffffc0201392:	6ba2                	ld	s7,8(sp)
ffffffffc0201394:	6c02                	ld	s8,0(sp)
ffffffffc0201396:	40f586b3          	sub	a3,a1,a5
ffffffffc020139a:	00005797          	auipc	a5,0x5
ffffffffc020139e:	08d7bb23          	sd	a3,150(a5) # ffffffffc0206430 <satp_physical>
ffffffffc02013a2:	00001517          	auipc	a0,0x1
ffffffffc02013a6:	57e50513          	addi	a0,a0,1406 # ffffffffc0202920 <buddy_system_pmm_manager+0x420>
ffffffffc02013aa:	8636                	mv	a2,a3
ffffffffc02013ac:	6161                	addi	sp,sp,80
ffffffffc02013ae:	d05fe06f          	j	ffffffffc02000b2 <cprintf>
ffffffffc02013b2:	000a3783          	ld	a5,0(s4)
ffffffffc02013b6:	04fbf063          	bgeu	s7,a5,ffffffffc02013f6 <pmm_init+0x2d8>
ffffffffc02013ba:	0009b683          	ld	a3,0(s3)
ffffffffc02013be:	fff80737          	lui	a4,0xfff80
ffffffffc02013c2:	975e                	add	a4,a4,s7
ffffffffc02013c4:	6088                	ld	a0,0(s1)
ffffffffc02013c6:	00271793          	slli	a5,a4,0x2
ffffffffc02013ca:	97ba                	add	a5,a5,a4
ffffffffc02013cc:	6a98                	ld	a4,16(a3)
ffffffffc02013ce:	415b0b33          	sub	s6,s6,s5
ffffffffc02013d2:	078e                	slli	a5,a5,0x3
ffffffffc02013d4:	00cb5593          	srli	a1,s6,0xc
ffffffffc02013d8:	953e                	add	a0,a0,a5
ffffffffc02013da:	9702                	jalr	a4
ffffffffc02013dc:	bf19                	j	ffffffffc02012f2 <pmm_init+0x1d4>
ffffffffc02013de:	00001617          	auipc	a2,0x1
ffffffffc02013e2:	36a60613          	addi	a2,a2,874 # ffffffffc0202748 <buddy_system_pmm_manager+0x248>
ffffffffc02013e6:	08d00593          	li	a1,141
ffffffffc02013ea:	00001517          	auipc	a0,0x1
ffffffffc02013ee:	38650513          	addi	a0,a0,902 # ffffffffc0202770 <buddy_system_pmm_manager+0x270>
ffffffffc02013f2:	fb3fe0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc02013f6:	c8fff0ef          	jal	ra,ffffffffc0201084 <pa2page.part.0>
ffffffffc02013fa:	00001617          	auipc	a2,0x1
ffffffffc02013fe:	34e60613          	addi	a2,a2,846 # ffffffffc0202748 <buddy_system_pmm_manager+0x248>
ffffffffc0201402:	0a100593          	li	a1,161
ffffffffc0201406:	00001517          	auipc	a0,0x1
ffffffffc020140a:	36a50513          	addi	a0,a0,874 # ffffffffc0202770 <buddy_system_pmm_manager+0x270>
ffffffffc020140e:	f97fe0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc0201412:	86ae                	mv	a3,a1
ffffffffc0201414:	00001617          	auipc	a2,0x1
ffffffffc0201418:	33460613          	addi	a2,a2,820 # ffffffffc0202748 <buddy_system_pmm_manager+0x248>
ffffffffc020141c:	0bc00593          	li	a1,188
ffffffffc0201420:	00001517          	auipc	a0,0x1
ffffffffc0201424:	35050513          	addi	a0,a0,848 # ffffffffc0202770 <buddy_system_pmm_manager+0x270>
ffffffffc0201428:	f7dfe0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc020142c:	00001617          	auipc	a2,0x1
ffffffffc0201430:	31c60613          	addi	a2,a2,796 # ffffffffc0202748 <buddy_system_pmm_manager+0x248>
ffffffffc0201434:	08100593          	li	a1,129
ffffffffc0201438:	00001517          	auipc	a0,0x1
ffffffffc020143c:	33850513          	addi	a0,a0,824 # ffffffffc0202770 <buddy_system_pmm_manager+0x270>
ffffffffc0201440:	f65fe0ef          	jal	ra,ffffffffc02003a4 <__panic>
ffffffffc0201444:	86a2                	mv	a3,s0
ffffffffc0201446:	00001617          	auipc	a2,0x1
ffffffffc020144a:	30260613          	addi	a2,a2,770 # ffffffffc0202748 <buddy_system_pmm_manager+0x248>
ffffffffc020144e:	09300593          	li	a1,147
ffffffffc0201452:	00001517          	auipc	a0,0x1
ffffffffc0201456:	31e50513          	addi	a0,a0,798 # ffffffffc0202770 <buddy_system_pmm_manager+0x270>
ffffffffc020145a:	f4bfe0ef          	jal	ra,ffffffffc02003a4 <__panic>

ffffffffc020145e <printnum>:
ffffffffc020145e:	02069813          	slli	a6,a3,0x20
ffffffffc0201462:	7179                	addi	sp,sp,-48
ffffffffc0201464:	02085813          	srli	a6,a6,0x20
ffffffffc0201468:	e052                	sd	s4,0(sp)
ffffffffc020146a:	03067a33          	remu	s4,a2,a6
ffffffffc020146e:	f022                	sd	s0,32(sp)
ffffffffc0201470:	ec26                	sd	s1,24(sp)
ffffffffc0201472:	e84a                	sd	s2,16(sp)
ffffffffc0201474:	f406                	sd	ra,40(sp)
ffffffffc0201476:	e44e                	sd	s3,8(sp)
ffffffffc0201478:	84aa                	mv	s1,a0
ffffffffc020147a:	892e                	mv	s2,a1
ffffffffc020147c:	fff7041b          	addiw	s0,a4,-1
ffffffffc0201480:	2a01                	sext.w	s4,s4
ffffffffc0201482:	03067e63          	bgeu	a2,a6,ffffffffc02014be <printnum+0x60>
ffffffffc0201486:	89be                	mv	s3,a5
ffffffffc0201488:	00805763          	blez	s0,ffffffffc0201496 <printnum+0x38>
ffffffffc020148c:	347d                	addiw	s0,s0,-1
ffffffffc020148e:	85ca                	mv	a1,s2
ffffffffc0201490:	854e                	mv	a0,s3
ffffffffc0201492:	9482                	jalr	s1
ffffffffc0201494:	fc65                	bnez	s0,ffffffffc020148c <printnum+0x2e>
ffffffffc0201496:	1a02                	slli	s4,s4,0x20
ffffffffc0201498:	020a5a13          	srli	s4,s4,0x20
ffffffffc020149c:	00001797          	auipc	a5,0x1
ffffffffc02014a0:	65478793          	addi	a5,a5,1620 # ffffffffc0202af0 <error_string+0x38>
ffffffffc02014a4:	9a3e                	add	s4,s4,a5
ffffffffc02014a6:	7402                	ld	s0,32(sp)
ffffffffc02014a8:	000a4503          	lbu	a0,0(s4)
ffffffffc02014ac:	70a2                	ld	ra,40(sp)
ffffffffc02014ae:	69a2                	ld	s3,8(sp)
ffffffffc02014b0:	6a02                	ld	s4,0(sp)
ffffffffc02014b2:	85ca                	mv	a1,s2
ffffffffc02014b4:	8326                	mv	t1,s1
ffffffffc02014b6:	6942                	ld	s2,16(sp)
ffffffffc02014b8:	64e2                	ld	s1,24(sp)
ffffffffc02014ba:	6145                	addi	sp,sp,48
ffffffffc02014bc:	8302                	jr	t1
ffffffffc02014be:	03065633          	divu	a2,a2,a6
ffffffffc02014c2:	8722                	mv	a4,s0
ffffffffc02014c4:	f9bff0ef          	jal	ra,ffffffffc020145e <printnum>
ffffffffc02014c8:	b7f9                	j	ffffffffc0201496 <printnum+0x38>

ffffffffc02014ca <vprintfmt>:
ffffffffc02014ca:	7119                	addi	sp,sp,-128
ffffffffc02014cc:	f4a6                	sd	s1,104(sp)
ffffffffc02014ce:	f0ca                	sd	s2,96(sp)
ffffffffc02014d0:	e8d2                	sd	s4,80(sp)
ffffffffc02014d2:	e4d6                	sd	s5,72(sp)
ffffffffc02014d4:	e0da                	sd	s6,64(sp)
ffffffffc02014d6:	fc5e                	sd	s7,56(sp)
ffffffffc02014d8:	f862                	sd	s8,48(sp)
ffffffffc02014da:	f06a                	sd	s10,32(sp)
ffffffffc02014dc:	fc86                	sd	ra,120(sp)
ffffffffc02014de:	f8a2                	sd	s0,112(sp)
ffffffffc02014e0:	ecce                	sd	s3,88(sp)
ffffffffc02014e2:	f466                	sd	s9,40(sp)
ffffffffc02014e4:	ec6e                	sd	s11,24(sp)
ffffffffc02014e6:	892a                	mv	s2,a0
ffffffffc02014e8:	84ae                	mv	s1,a1
ffffffffc02014ea:	8d32                	mv	s10,a2
ffffffffc02014ec:	8ab6                	mv	s5,a3
ffffffffc02014ee:	5b7d                	li	s6,-1
ffffffffc02014f0:	00001a17          	auipc	s4,0x1
ffffffffc02014f4:	470a0a13          	addi	s4,s4,1136 # ffffffffc0202960 <buddy_system_pmm_manager+0x460>
ffffffffc02014f8:	05e00b93          	li	s7,94
ffffffffc02014fc:	00001c17          	auipc	s8,0x1
ffffffffc0201500:	5bcc0c13          	addi	s8,s8,1468 # ffffffffc0202ab8 <error_string>
ffffffffc0201504:	000d4503          	lbu	a0,0(s10)
ffffffffc0201508:	02500793          	li	a5,37
ffffffffc020150c:	001d0413          	addi	s0,s10,1
ffffffffc0201510:	00f50e63          	beq	a0,a5,ffffffffc020152c <vprintfmt+0x62>
ffffffffc0201514:	c521                	beqz	a0,ffffffffc020155c <vprintfmt+0x92>
ffffffffc0201516:	02500993          	li	s3,37
ffffffffc020151a:	a011                	j	ffffffffc020151e <vprintfmt+0x54>
ffffffffc020151c:	c121                	beqz	a0,ffffffffc020155c <vprintfmt+0x92>
ffffffffc020151e:	85a6                	mv	a1,s1
ffffffffc0201520:	0405                	addi	s0,s0,1
ffffffffc0201522:	9902                	jalr	s2
ffffffffc0201524:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201528:	ff351ae3          	bne	a0,s3,ffffffffc020151c <vprintfmt+0x52>
ffffffffc020152c:	00044603          	lbu	a2,0(s0)
ffffffffc0201530:	02000793          	li	a5,32
ffffffffc0201534:	4981                	li	s3,0
ffffffffc0201536:	4801                	li	a6,0
ffffffffc0201538:	5cfd                	li	s9,-1
ffffffffc020153a:	5dfd                	li	s11,-1
ffffffffc020153c:	05500593          	li	a1,85
ffffffffc0201540:	4525                	li	a0,9
ffffffffc0201542:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0201546:	0ff6f693          	andi	a3,a3,255
ffffffffc020154a:	00140d13          	addi	s10,s0,1
ffffffffc020154e:	20d5e563          	bltu	a1,a3,ffffffffc0201758 <vprintfmt+0x28e>
ffffffffc0201552:	068a                	slli	a3,a3,0x2
ffffffffc0201554:	96d2                	add	a3,a3,s4
ffffffffc0201556:	4294                	lw	a3,0(a3)
ffffffffc0201558:	96d2                	add	a3,a3,s4
ffffffffc020155a:	8682                	jr	a3
ffffffffc020155c:	70e6                	ld	ra,120(sp)
ffffffffc020155e:	7446                	ld	s0,112(sp)
ffffffffc0201560:	74a6                	ld	s1,104(sp)
ffffffffc0201562:	7906                	ld	s2,96(sp)
ffffffffc0201564:	69e6                	ld	s3,88(sp)
ffffffffc0201566:	6a46                	ld	s4,80(sp)
ffffffffc0201568:	6aa6                	ld	s5,72(sp)
ffffffffc020156a:	6b06                	ld	s6,64(sp)
ffffffffc020156c:	7be2                	ld	s7,56(sp)
ffffffffc020156e:	7c42                	ld	s8,48(sp)
ffffffffc0201570:	7ca2                	ld	s9,40(sp)
ffffffffc0201572:	7d02                	ld	s10,32(sp)
ffffffffc0201574:	6de2                	ld	s11,24(sp)
ffffffffc0201576:	6109                	addi	sp,sp,128
ffffffffc0201578:	8082                	ret
ffffffffc020157a:	4705                	li	a4,1
ffffffffc020157c:	008a8593          	addi	a1,s5,8 # 1008 <kern_entry-0xffffffffc01feff8>
ffffffffc0201580:	01074463          	blt	a4,a6,ffffffffc0201588 <vprintfmt+0xbe>
ffffffffc0201584:	26080363          	beqz	a6,ffffffffc02017ea <vprintfmt+0x320>
ffffffffc0201588:	000ab603          	ld	a2,0(s5)
ffffffffc020158c:	46c1                	li	a3,16
ffffffffc020158e:	8aae                	mv	s5,a1
ffffffffc0201590:	a06d                	j	ffffffffc020163a <vprintfmt+0x170>
ffffffffc0201592:	00144603          	lbu	a2,1(s0)
ffffffffc0201596:	4985                	li	s3,1
ffffffffc0201598:	846a                	mv	s0,s10
ffffffffc020159a:	b765                	j	ffffffffc0201542 <vprintfmt+0x78>
ffffffffc020159c:	000aa503          	lw	a0,0(s5)
ffffffffc02015a0:	85a6                	mv	a1,s1
ffffffffc02015a2:	0aa1                	addi	s5,s5,8
ffffffffc02015a4:	9902                	jalr	s2
ffffffffc02015a6:	bfb9                	j	ffffffffc0201504 <vprintfmt+0x3a>
ffffffffc02015a8:	4705                	li	a4,1
ffffffffc02015aa:	008a8993          	addi	s3,s5,8
ffffffffc02015ae:	01074463          	blt	a4,a6,ffffffffc02015b6 <vprintfmt+0xec>
ffffffffc02015b2:	22080463          	beqz	a6,ffffffffc02017da <vprintfmt+0x310>
ffffffffc02015b6:	000ab403          	ld	s0,0(s5)
ffffffffc02015ba:	24044463          	bltz	s0,ffffffffc0201802 <vprintfmt+0x338>
ffffffffc02015be:	8622                	mv	a2,s0
ffffffffc02015c0:	8ace                	mv	s5,s3
ffffffffc02015c2:	46a9                	li	a3,10
ffffffffc02015c4:	a89d                	j	ffffffffc020163a <vprintfmt+0x170>
ffffffffc02015c6:	000aa783          	lw	a5,0(s5)
ffffffffc02015ca:	4719                	li	a4,6
ffffffffc02015cc:	0aa1                	addi	s5,s5,8
ffffffffc02015ce:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02015d2:	8fb5                	xor	a5,a5,a3
ffffffffc02015d4:	40d786bb          	subw	a3,a5,a3
ffffffffc02015d8:	1ad74363          	blt	a4,a3,ffffffffc020177e <vprintfmt+0x2b4>
ffffffffc02015dc:	00369793          	slli	a5,a3,0x3
ffffffffc02015e0:	97e2                	add	a5,a5,s8
ffffffffc02015e2:	639c                	ld	a5,0(a5)
ffffffffc02015e4:	18078d63          	beqz	a5,ffffffffc020177e <vprintfmt+0x2b4>
ffffffffc02015e8:	86be                	mv	a3,a5
ffffffffc02015ea:	00001617          	auipc	a2,0x1
ffffffffc02015ee:	5b660613          	addi	a2,a2,1462 # ffffffffc0202ba0 <error_string+0xe8>
ffffffffc02015f2:	85a6                	mv	a1,s1
ffffffffc02015f4:	854a                	mv	a0,s2
ffffffffc02015f6:	240000ef          	jal	ra,ffffffffc0201836 <printfmt>
ffffffffc02015fa:	b729                	j	ffffffffc0201504 <vprintfmt+0x3a>
ffffffffc02015fc:	00144603          	lbu	a2,1(s0)
ffffffffc0201600:	2805                	addiw	a6,a6,1
ffffffffc0201602:	846a                	mv	s0,s10
ffffffffc0201604:	bf3d                	j	ffffffffc0201542 <vprintfmt+0x78>
ffffffffc0201606:	4705                	li	a4,1
ffffffffc0201608:	008a8593          	addi	a1,s5,8
ffffffffc020160c:	01074463          	blt	a4,a6,ffffffffc0201614 <vprintfmt+0x14a>
ffffffffc0201610:	1e080263          	beqz	a6,ffffffffc02017f4 <vprintfmt+0x32a>
ffffffffc0201614:	000ab603          	ld	a2,0(s5)
ffffffffc0201618:	46a1                	li	a3,8
ffffffffc020161a:	8aae                	mv	s5,a1
ffffffffc020161c:	a839                	j	ffffffffc020163a <vprintfmt+0x170>
ffffffffc020161e:	03000513          	li	a0,48
ffffffffc0201622:	85a6                	mv	a1,s1
ffffffffc0201624:	e03e                	sd	a5,0(sp)
ffffffffc0201626:	9902                	jalr	s2
ffffffffc0201628:	85a6                	mv	a1,s1
ffffffffc020162a:	07800513          	li	a0,120
ffffffffc020162e:	9902                	jalr	s2
ffffffffc0201630:	0aa1                	addi	s5,s5,8
ffffffffc0201632:	ff8ab603          	ld	a2,-8(s5)
ffffffffc0201636:	6782                	ld	a5,0(sp)
ffffffffc0201638:	46c1                	li	a3,16
ffffffffc020163a:	876e                	mv	a4,s11
ffffffffc020163c:	85a6                	mv	a1,s1
ffffffffc020163e:	854a                	mv	a0,s2
ffffffffc0201640:	e1fff0ef          	jal	ra,ffffffffc020145e <printnum>
ffffffffc0201644:	b5c1                	j	ffffffffc0201504 <vprintfmt+0x3a>
ffffffffc0201646:	000ab603          	ld	a2,0(s5)
ffffffffc020164a:	0aa1                	addi	s5,s5,8
ffffffffc020164c:	1c060663          	beqz	a2,ffffffffc0201818 <vprintfmt+0x34e>
ffffffffc0201650:	00160413          	addi	s0,a2,1
ffffffffc0201654:	17b05c63          	blez	s11,ffffffffc02017cc <vprintfmt+0x302>
ffffffffc0201658:	02d00593          	li	a1,45
ffffffffc020165c:	14b79263          	bne	a5,a1,ffffffffc02017a0 <vprintfmt+0x2d6>
ffffffffc0201660:	00064783          	lbu	a5,0(a2)
ffffffffc0201664:	0007851b          	sext.w	a0,a5
ffffffffc0201668:	c905                	beqz	a0,ffffffffc0201698 <vprintfmt+0x1ce>
ffffffffc020166a:	000cc563          	bltz	s9,ffffffffc0201674 <vprintfmt+0x1aa>
ffffffffc020166e:	3cfd                	addiw	s9,s9,-1
ffffffffc0201670:	036c8263          	beq	s9,s6,ffffffffc0201694 <vprintfmt+0x1ca>
ffffffffc0201674:	85a6                	mv	a1,s1
ffffffffc0201676:	18098463          	beqz	s3,ffffffffc02017fe <vprintfmt+0x334>
ffffffffc020167a:	3781                	addiw	a5,a5,-32
ffffffffc020167c:	18fbf163          	bgeu	s7,a5,ffffffffc02017fe <vprintfmt+0x334>
ffffffffc0201680:	03f00513          	li	a0,63
ffffffffc0201684:	9902                	jalr	s2
ffffffffc0201686:	0405                	addi	s0,s0,1
ffffffffc0201688:	fff44783          	lbu	a5,-1(s0)
ffffffffc020168c:	3dfd                	addiw	s11,s11,-1
ffffffffc020168e:	0007851b          	sext.w	a0,a5
ffffffffc0201692:	fd61                	bnez	a0,ffffffffc020166a <vprintfmt+0x1a0>
ffffffffc0201694:	e7b058e3          	blez	s11,ffffffffc0201504 <vprintfmt+0x3a>
ffffffffc0201698:	3dfd                	addiw	s11,s11,-1
ffffffffc020169a:	85a6                	mv	a1,s1
ffffffffc020169c:	02000513          	li	a0,32
ffffffffc02016a0:	9902                	jalr	s2
ffffffffc02016a2:	e60d81e3          	beqz	s11,ffffffffc0201504 <vprintfmt+0x3a>
ffffffffc02016a6:	3dfd                	addiw	s11,s11,-1
ffffffffc02016a8:	85a6                	mv	a1,s1
ffffffffc02016aa:	02000513          	li	a0,32
ffffffffc02016ae:	9902                	jalr	s2
ffffffffc02016b0:	fe0d94e3          	bnez	s11,ffffffffc0201698 <vprintfmt+0x1ce>
ffffffffc02016b4:	bd81                	j	ffffffffc0201504 <vprintfmt+0x3a>
ffffffffc02016b6:	4705                	li	a4,1
ffffffffc02016b8:	008a8593          	addi	a1,s5,8
ffffffffc02016bc:	01074463          	blt	a4,a6,ffffffffc02016c4 <vprintfmt+0x1fa>
ffffffffc02016c0:	12080063          	beqz	a6,ffffffffc02017e0 <vprintfmt+0x316>
ffffffffc02016c4:	000ab603          	ld	a2,0(s5)
ffffffffc02016c8:	46a9                	li	a3,10
ffffffffc02016ca:	8aae                	mv	s5,a1
ffffffffc02016cc:	b7bd                	j	ffffffffc020163a <vprintfmt+0x170>
ffffffffc02016ce:	00144603          	lbu	a2,1(s0)
ffffffffc02016d2:	02d00793          	li	a5,45
ffffffffc02016d6:	846a                	mv	s0,s10
ffffffffc02016d8:	b5ad                	j	ffffffffc0201542 <vprintfmt+0x78>
ffffffffc02016da:	85a6                	mv	a1,s1
ffffffffc02016dc:	02500513          	li	a0,37
ffffffffc02016e0:	9902                	jalr	s2
ffffffffc02016e2:	b50d                	j	ffffffffc0201504 <vprintfmt+0x3a>
ffffffffc02016e4:	000aac83          	lw	s9,0(s5)
ffffffffc02016e8:	00144603          	lbu	a2,1(s0)
ffffffffc02016ec:	0aa1                	addi	s5,s5,8
ffffffffc02016ee:	846a                	mv	s0,s10
ffffffffc02016f0:	e40dd9e3          	bgez	s11,ffffffffc0201542 <vprintfmt+0x78>
ffffffffc02016f4:	8de6                	mv	s11,s9
ffffffffc02016f6:	5cfd                	li	s9,-1
ffffffffc02016f8:	b5a9                	j	ffffffffc0201542 <vprintfmt+0x78>
ffffffffc02016fa:	00144603          	lbu	a2,1(s0)
ffffffffc02016fe:	03000793          	li	a5,48
ffffffffc0201702:	846a                	mv	s0,s10
ffffffffc0201704:	bd3d                	j	ffffffffc0201542 <vprintfmt+0x78>
ffffffffc0201706:	fd060c9b          	addiw	s9,a2,-48
ffffffffc020170a:	00144603          	lbu	a2,1(s0)
ffffffffc020170e:	846a                	mv	s0,s10
ffffffffc0201710:	fd06069b          	addiw	a3,a2,-48
ffffffffc0201714:	0006089b          	sext.w	a7,a2
ffffffffc0201718:	fcd56ce3          	bltu	a0,a3,ffffffffc02016f0 <vprintfmt+0x226>
ffffffffc020171c:	0405                	addi	s0,s0,1
ffffffffc020171e:	002c969b          	slliw	a3,s9,0x2
ffffffffc0201722:	00044603          	lbu	a2,0(s0)
ffffffffc0201726:	0196873b          	addw	a4,a3,s9
ffffffffc020172a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020172e:	0117073b          	addw	a4,a4,a7
ffffffffc0201732:	fd06069b          	addiw	a3,a2,-48
ffffffffc0201736:	fd070c9b          	addiw	s9,a4,-48
ffffffffc020173a:	0006089b          	sext.w	a7,a2
ffffffffc020173e:	fcd57fe3          	bgeu	a0,a3,ffffffffc020171c <vprintfmt+0x252>
ffffffffc0201742:	b77d                	j	ffffffffc02016f0 <vprintfmt+0x226>
ffffffffc0201744:	fffdc693          	not	a3,s11
ffffffffc0201748:	96fd                	srai	a3,a3,0x3f
ffffffffc020174a:	00ddfdb3          	and	s11,s11,a3
ffffffffc020174e:	00144603          	lbu	a2,1(s0)
ffffffffc0201752:	2d81                	sext.w	s11,s11
ffffffffc0201754:	846a                	mv	s0,s10
ffffffffc0201756:	b3f5                	j	ffffffffc0201542 <vprintfmt+0x78>
ffffffffc0201758:	85a6                	mv	a1,s1
ffffffffc020175a:	02500513          	li	a0,37
ffffffffc020175e:	9902                	jalr	s2
ffffffffc0201760:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201764:	02500793          	li	a5,37
ffffffffc0201768:	8d22                	mv	s10,s0
ffffffffc020176a:	d8f70de3          	beq	a4,a5,ffffffffc0201504 <vprintfmt+0x3a>
ffffffffc020176e:	02500713          	li	a4,37
ffffffffc0201772:	1d7d                	addi	s10,s10,-1
ffffffffc0201774:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0201778:	fee79de3          	bne	a5,a4,ffffffffc0201772 <vprintfmt+0x2a8>
ffffffffc020177c:	b361                	j	ffffffffc0201504 <vprintfmt+0x3a>
ffffffffc020177e:	00001617          	auipc	a2,0x1
ffffffffc0201782:	41260613          	addi	a2,a2,1042 # ffffffffc0202b90 <error_string+0xd8>
ffffffffc0201786:	85a6                	mv	a1,s1
ffffffffc0201788:	854a                	mv	a0,s2
ffffffffc020178a:	0ac000ef          	jal	ra,ffffffffc0201836 <printfmt>
ffffffffc020178e:	bb9d                	j	ffffffffc0201504 <vprintfmt+0x3a>
ffffffffc0201790:	00001617          	auipc	a2,0x1
ffffffffc0201794:	3f860613          	addi	a2,a2,1016 # ffffffffc0202b88 <error_string+0xd0>
ffffffffc0201798:	00001417          	auipc	s0,0x1
ffffffffc020179c:	3f140413          	addi	s0,s0,1009 # ffffffffc0202b89 <error_string+0xd1>
ffffffffc02017a0:	8532                	mv	a0,a2
ffffffffc02017a2:	85e6                	mv	a1,s9
ffffffffc02017a4:	e032                	sd	a2,0(sp)
ffffffffc02017a6:	e43e                	sd	a5,8(sp)
ffffffffc02017a8:	1de000ef          	jal	ra,ffffffffc0201986 <strnlen>
ffffffffc02017ac:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02017b0:	6602                	ld	a2,0(sp)
ffffffffc02017b2:	01b05d63          	blez	s11,ffffffffc02017cc <vprintfmt+0x302>
ffffffffc02017b6:	67a2                	ld	a5,8(sp)
ffffffffc02017b8:	2781                	sext.w	a5,a5
ffffffffc02017ba:	e43e                	sd	a5,8(sp)
ffffffffc02017bc:	6522                	ld	a0,8(sp)
ffffffffc02017be:	85a6                	mv	a1,s1
ffffffffc02017c0:	e032                	sd	a2,0(sp)
ffffffffc02017c2:	3dfd                	addiw	s11,s11,-1
ffffffffc02017c4:	9902                	jalr	s2
ffffffffc02017c6:	6602                	ld	a2,0(sp)
ffffffffc02017c8:	fe0d9ae3          	bnez	s11,ffffffffc02017bc <vprintfmt+0x2f2>
ffffffffc02017cc:	00064783          	lbu	a5,0(a2)
ffffffffc02017d0:	0007851b          	sext.w	a0,a5
ffffffffc02017d4:	e8051be3          	bnez	a0,ffffffffc020166a <vprintfmt+0x1a0>
ffffffffc02017d8:	b335                	j	ffffffffc0201504 <vprintfmt+0x3a>
ffffffffc02017da:	000aa403          	lw	s0,0(s5)
ffffffffc02017de:	bbf1                	j	ffffffffc02015ba <vprintfmt+0xf0>
ffffffffc02017e0:	000ae603          	lwu	a2,0(s5)
ffffffffc02017e4:	46a9                	li	a3,10
ffffffffc02017e6:	8aae                	mv	s5,a1
ffffffffc02017e8:	bd89                	j	ffffffffc020163a <vprintfmt+0x170>
ffffffffc02017ea:	000ae603          	lwu	a2,0(s5)
ffffffffc02017ee:	46c1                	li	a3,16
ffffffffc02017f0:	8aae                	mv	s5,a1
ffffffffc02017f2:	b5a1                	j	ffffffffc020163a <vprintfmt+0x170>
ffffffffc02017f4:	000ae603          	lwu	a2,0(s5)
ffffffffc02017f8:	46a1                	li	a3,8
ffffffffc02017fa:	8aae                	mv	s5,a1
ffffffffc02017fc:	bd3d                	j	ffffffffc020163a <vprintfmt+0x170>
ffffffffc02017fe:	9902                	jalr	s2
ffffffffc0201800:	b559                	j	ffffffffc0201686 <vprintfmt+0x1bc>
ffffffffc0201802:	85a6                	mv	a1,s1
ffffffffc0201804:	02d00513          	li	a0,45
ffffffffc0201808:	e03e                	sd	a5,0(sp)
ffffffffc020180a:	9902                	jalr	s2
ffffffffc020180c:	8ace                	mv	s5,s3
ffffffffc020180e:	40800633          	neg	a2,s0
ffffffffc0201812:	46a9                	li	a3,10
ffffffffc0201814:	6782                	ld	a5,0(sp)
ffffffffc0201816:	b515                	j	ffffffffc020163a <vprintfmt+0x170>
ffffffffc0201818:	01b05663          	blez	s11,ffffffffc0201824 <vprintfmt+0x35a>
ffffffffc020181c:	02d00693          	li	a3,45
ffffffffc0201820:	f6d798e3          	bne	a5,a3,ffffffffc0201790 <vprintfmt+0x2c6>
ffffffffc0201824:	00001417          	auipc	s0,0x1
ffffffffc0201828:	36540413          	addi	s0,s0,869 # ffffffffc0202b89 <error_string+0xd1>
ffffffffc020182c:	02800513          	li	a0,40
ffffffffc0201830:	02800793          	li	a5,40
ffffffffc0201834:	bd1d                	j	ffffffffc020166a <vprintfmt+0x1a0>

ffffffffc0201836 <printfmt>:
ffffffffc0201836:	715d                	addi	sp,sp,-80
ffffffffc0201838:	02810313          	addi	t1,sp,40
ffffffffc020183c:	f436                	sd	a3,40(sp)
ffffffffc020183e:	869a                	mv	a3,t1
ffffffffc0201840:	ec06                	sd	ra,24(sp)
ffffffffc0201842:	f83a                	sd	a4,48(sp)
ffffffffc0201844:	fc3e                	sd	a5,56(sp)
ffffffffc0201846:	e0c2                	sd	a6,64(sp)
ffffffffc0201848:	e4c6                	sd	a7,72(sp)
ffffffffc020184a:	e41a                	sd	t1,8(sp)
ffffffffc020184c:	c7fff0ef          	jal	ra,ffffffffc02014ca <vprintfmt>
ffffffffc0201850:	60e2                	ld	ra,24(sp)
ffffffffc0201852:	6161                	addi	sp,sp,80
ffffffffc0201854:	8082                	ret

ffffffffc0201856 <readline>:
ffffffffc0201856:	715d                	addi	sp,sp,-80
ffffffffc0201858:	e486                	sd	ra,72(sp)
ffffffffc020185a:	e0a2                	sd	s0,64(sp)
ffffffffc020185c:	fc26                	sd	s1,56(sp)
ffffffffc020185e:	f84a                	sd	s2,48(sp)
ffffffffc0201860:	f44e                	sd	s3,40(sp)
ffffffffc0201862:	f052                	sd	s4,32(sp)
ffffffffc0201864:	ec56                	sd	s5,24(sp)
ffffffffc0201866:	e85a                	sd	s6,16(sp)
ffffffffc0201868:	e45e                	sd	s7,8(sp)
ffffffffc020186a:	c901                	beqz	a0,ffffffffc020187a <readline+0x24>
ffffffffc020186c:	85aa                	mv	a1,a0
ffffffffc020186e:	00001517          	auipc	a0,0x1
ffffffffc0201872:	33250513          	addi	a0,a0,818 # ffffffffc0202ba0 <error_string+0xe8>
ffffffffc0201876:	83dfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020187a:	4481                	li	s1,0
ffffffffc020187c:	497d                	li	s2,31
ffffffffc020187e:	49a1                	li	s3,8
ffffffffc0201880:	4aa9                	li	s5,10
ffffffffc0201882:	4b35                	li	s6,13
ffffffffc0201884:	00004b97          	auipc	s7,0x4
ffffffffc0201888:	794b8b93          	addi	s7,s7,1940 # ffffffffc0206018 <buf>
ffffffffc020188c:	3fe00a13          	li	s4,1022
ffffffffc0201890:	899fe0ef          	jal	ra,ffffffffc0200128 <getchar>
ffffffffc0201894:	842a                	mv	s0,a0
ffffffffc0201896:	00054b63          	bltz	a0,ffffffffc02018ac <readline+0x56>
ffffffffc020189a:	00a95b63          	bge	s2,a0,ffffffffc02018b0 <readline+0x5a>
ffffffffc020189e:	029a5463          	bge	s4,s1,ffffffffc02018c6 <readline+0x70>
ffffffffc02018a2:	887fe0ef          	jal	ra,ffffffffc0200128 <getchar>
ffffffffc02018a6:	842a                	mv	s0,a0
ffffffffc02018a8:	fe0559e3          	bgez	a0,ffffffffc020189a <readline+0x44>
ffffffffc02018ac:	4501                	li	a0,0
ffffffffc02018ae:	a099                	j	ffffffffc02018f4 <readline+0x9e>
ffffffffc02018b0:	03341463          	bne	s0,s3,ffffffffc02018d8 <readline+0x82>
ffffffffc02018b4:	e8b9                	bnez	s1,ffffffffc020190a <readline+0xb4>
ffffffffc02018b6:	873fe0ef          	jal	ra,ffffffffc0200128 <getchar>
ffffffffc02018ba:	842a                	mv	s0,a0
ffffffffc02018bc:	fe0548e3          	bltz	a0,ffffffffc02018ac <readline+0x56>
ffffffffc02018c0:	fea958e3          	bge	s2,a0,ffffffffc02018b0 <readline+0x5a>
ffffffffc02018c4:	4481                	li	s1,0
ffffffffc02018c6:	8522                	mv	a0,s0
ffffffffc02018c8:	81ffe0ef          	jal	ra,ffffffffc02000e6 <cputchar>
ffffffffc02018cc:	009b87b3          	add	a5,s7,s1
ffffffffc02018d0:	00878023          	sb	s0,0(a5)
ffffffffc02018d4:	2485                	addiw	s1,s1,1
ffffffffc02018d6:	bf6d                	j	ffffffffc0201890 <readline+0x3a>
ffffffffc02018d8:	01540463          	beq	s0,s5,ffffffffc02018e0 <readline+0x8a>
ffffffffc02018dc:	fb641ae3          	bne	s0,s6,ffffffffc0201890 <readline+0x3a>
ffffffffc02018e0:	8522                	mv	a0,s0
ffffffffc02018e2:	805fe0ef          	jal	ra,ffffffffc02000e6 <cputchar>
ffffffffc02018e6:	00004517          	auipc	a0,0x4
ffffffffc02018ea:	73250513          	addi	a0,a0,1842 # ffffffffc0206018 <buf>
ffffffffc02018ee:	94aa                	add	s1,s1,a0
ffffffffc02018f0:	00048023          	sb	zero,0(s1) # ffffffffc0200000 <kern_entry>
ffffffffc02018f4:	60a6                	ld	ra,72(sp)
ffffffffc02018f6:	6406                	ld	s0,64(sp)
ffffffffc02018f8:	74e2                	ld	s1,56(sp)
ffffffffc02018fa:	7942                	ld	s2,48(sp)
ffffffffc02018fc:	79a2                	ld	s3,40(sp)
ffffffffc02018fe:	7a02                	ld	s4,32(sp)
ffffffffc0201900:	6ae2                	ld	s5,24(sp)
ffffffffc0201902:	6b42                	ld	s6,16(sp)
ffffffffc0201904:	6ba2                	ld	s7,8(sp)
ffffffffc0201906:	6161                	addi	sp,sp,80
ffffffffc0201908:	8082                	ret
ffffffffc020190a:	4521                	li	a0,8
ffffffffc020190c:	fdafe0ef          	jal	ra,ffffffffc02000e6 <cputchar>
ffffffffc0201910:	34fd                	addiw	s1,s1,-1
ffffffffc0201912:	bfbd                	j	ffffffffc0201890 <readline+0x3a>

ffffffffc0201914 <sbi_console_putchar>:
ffffffffc0201914:	00004797          	auipc	a5,0x4
ffffffffc0201918:	6f478793          	addi	a5,a5,1780 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc020191c:	6398                	ld	a4,0(a5)
ffffffffc020191e:	4781                	li	a5,0
ffffffffc0201920:	88ba                	mv	a7,a4
ffffffffc0201922:	852a                	mv	a0,a0
ffffffffc0201924:	85be                	mv	a1,a5
ffffffffc0201926:	863e                	mv	a2,a5
ffffffffc0201928:	00000073          	ecall
ffffffffc020192c:	87aa                	mv	a5,a0
ffffffffc020192e:	8082                	ret

ffffffffc0201930 <sbi_set_timer>:
ffffffffc0201930:	00005797          	auipc	a5,0x5
ffffffffc0201934:	b2878793          	addi	a5,a5,-1240 # ffffffffc0206458 <SBI_SET_TIMER>
ffffffffc0201938:	6398                	ld	a4,0(a5)
ffffffffc020193a:	4781                	li	a5,0
ffffffffc020193c:	88ba                	mv	a7,a4
ffffffffc020193e:	852a                	mv	a0,a0
ffffffffc0201940:	85be                	mv	a1,a5
ffffffffc0201942:	863e                	mv	a2,a5
ffffffffc0201944:	00000073          	ecall
ffffffffc0201948:	87aa                	mv	a5,a0
ffffffffc020194a:	8082                	ret

ffffffffc020194c <sbi_console_getchar>:
ffffffffc020194c:	00004797          	auipc	a5,0x4
ffffffffc0201950:	6b478793          	addi	a5,a5,1716 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc0201954:	639c                	ld	a5,0(a5)
ffffffffc0201956:	4501                	li	a0,0
ffffffffc0201958:	88be                	mv	a7,a5
ffffffffc020195a:	852a                	mv	a0,a0
ffffffffc020195c:	85aa                	mv	a1,a0
ffffffffc020195e:	862a                	mv	a2,a0
ffffffffc0201960:	00000073          	ecall
ffffffffc0201964:	852a                	mv	a0,a0
ffffffffc0201966:	2501                	sext.w	a0,a0
ffffffffc0201968:	8082                	ret

ffffffffc020196a <sbi_shutdown>:
ffffffffc020196a:	00004797          	auipc	a5,0x4
ffffffffc020196e:	6a678793          	addi	a5,a5,1702 # ffffffffc0206010 <SBI_SHUTDOWN>
ffffffffc0201972:	6398                	ld	a4,0(a5)
ffffffffc0201974:	4781                	li	a5,0
ffffffffc0201976:	88ba                	mv	a7,a4
ffffffffc0201978:	853e                	mv	a0,a5
ffffffffc020197a:	85be                	mv	a1,a5
ffffffffc020197c:	863e                	mv	a2,a5
ffffffffc020197e:	00000073          	ecall
ffffffffc0201982:	87aa                	mv	a5,a0
ffffffffc0201984:	8082                	ret

ffffffffc0201986 <strnlen>:
ffffffffc0201986:	c185                	beqz	a1,ffffffffc02019a6 <strnlen+0x20>
ffffffffc0201988:	00054783          	lbu	a5,0(a0)
ffffffffc020198c:	cf89                	beqz	a5,ffffffffc02019a6 <strnlen+0x20>
ffffffffc020198e:	4781                	li	a5,0
ffffffffc0201990:	a021                	j	ffffffffc0201998 <strnlen+0x12>
ffffffffc0201992:	00074703          	lbu	a4,0(a4) # fffffffffff80000 <end+0x3fd79a98>
ffffffffc0201996:	c711                	beqz	a4,ffffffffc02019a2 <strnlen+0x1c>
ffffffffc0201998:	0785                	addi	a5,a5,1
ffffffffc020199a:	00f50733          	add	a4,a0,a5
ffffffffc020199e:	fef59ae3          	bne	a1,a5,ffffffffc0201992 <strnlen+0xc>
ffffffffc02019a2:	853e                	mv	a0,a5
ffffffffc02019a4:	8082                	ret
ffffffffc02019a6:	4781                	li	a5,0
ffffffffc02019a8:	853e                	mv	a0,a5
ffffffffc02019aa:	8082                	ret

ffffffffc02019ac <strcmp>:
ffffffffc02019ac:	00054783          	lbu	a5,0(a0)
ffffffffc02019b0:	0005c703          	lbu	a4,0(a1)
ffffffffc02019b4:	cb91                	beqz	a5,ffffffffc02019c8 <strcmp+0x1c>
ffffffffc02019b6:	00e79c63          	bne	a5,a4,ffffffffc02019ce <strcmp+0x22>
ffffffffc02019ba:	0505                	addi	a0,a0,1
ffffffffc02019bc:	00054783          	lbu	a5,0(a0)
ffffffffc02019c0:	0585                	addi	a1,a1,1
ffffffffc02019c2:	0005c703          	lbu	a4,0(a1)
ffffffffc02019c6:	fbe5                	bnez	a5,ffffffffc02019b6 <strcmp+0xa>
ffffffffc02019c8:	4501                	li	a0,0
ffffffffc02019ca:	9d19                	subw	a0,a0,a4
ffffffffc02019cc:	8082                	ret
ffffffffc02019ce:	0007851b          	sext.w	a0,a5
ffffffffc02019d2:	9d19                	subw	a0,a0,a4
ffffffffc02019d4:	8082                	ret

ffffffffc02019d6 <strchr>:
ffffffffc02019d6:	00054783          	lbu	a5,0(a0)
ffffffffc02019da:	cb91                	beqz	a5,ffffffffc02019ee <strchr+0x18>
ffffffffc02019dc:	00b79563          	bne	a5,a1,ffffffffc02019e6 <strchr+0x10>
ffffffffc02019e0:	a809                	j	ffffffffc02019f2 <strchr+0x1c>
ffffffffc02019e2:	00b78763          	beq	a5,a1,ffffffffc02019f0 <strchr+0x1a>
ffffffffc02019e6:	0505                	addi	a0,a0,1
ffffffffc02019e8:	00054783          	lbu	a5,0(a0)
ffffffffc02019ec:	fbfd                	bnez	a5,ffffffffc02019e2 <strchr+0xc>
ffffffffc02019ee:	4501                	li	a0,0
ffffffffc02019f0:	8082                	ret
ffffffffc02019f2:	8082                	ret

ffffffffc02019f4 <memset>:
ffffffffc02019f4:	ca01                	beqz	a2,ffffffffc0201a04 <memset+0x10>
ffffffffc02019f6:	962a                	add	a2,a2,a0
ffffffffc02019f8:	87aa                	mv	a5,a0
ffffffffc02019fa:	0785                	addi	a5,a5,1
ffffffffc02019fc:	feb78fa3          	sb	a1,-1(a5)
ffffffffc0201a00:	fec79de3          	bne	a5,a2,ffffffffc02019fa <memset+0x6>
ffffffffc0201a04:	8082                	ret
