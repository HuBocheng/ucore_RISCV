
bin/kernel：     文件格式 elf64-littleriscv


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
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号（**物理地址右移12位得到物理页号**）
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	00006517          	auipc	a0,0x6
ffffffffc020003a:	fe250513          	addi	a0,a0,-30 # ffffffffc0206018 <edata>
ffffffffc020003e:	00006617          	auipc	a2,0x6
ffffffffc0200042:	52a60613          	addi	a2,a2,1322 # ffffffffc0206568 <end>
int kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	1eb010ef          	jal	ra,ffffffffc0201a38 <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fe000ef          	jal	ra,ffffffffc0200450 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00002517          	auipc	a0,0x2
ffffffffc020005a:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0201a50 <etext+0x6>
ffffffffc020005e:	090000ef          	jal	ra,ffffffffc02000ee <cputs>

    print_kerninfo();
ffffffffc0200062:	0dc000ef          	jal	ra,ffffffffc020013e <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200066:	404000ef          	jal	ra,ffffffffc020046a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020006a:	0e2010ef          	jal	ra,ffffffffc020114c <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006e:	3fc000ef          	jal	ra,ffffffffc020046a <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200072:	39a000ef          	jal	ra,ffffffffc020040c <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200076:	3e8000ef          	jal	ra,ffffffffc020045e <intr_enable>



    /* do nothing */
    while (1)
        ;
ffffffffc020007a:	a001                	j	ffffffffc020007a <kern_init+0x44>

ffffffffc020007c <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020007c:	1141                	addi	sp,sp,-16
ffffffffc020007e:	e022                	sd	s0,0(sp)
ffffffffc0200080:	e406                	sd	ra,8(sp)
ffffffffc0200082:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200084:	3ce000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200088:	401c                	lw	a5,0(s0)
}
ffffffffc020008a:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc020008c:	2785                	addiw	a5,a5,1
ffffffffc020008e:	c01c                	sw	a5,0(s0)
}
ffffffffc0200090:	6402                	ld	s0,0(sp)
ffffffffc0200092:	0141                	addi	sp,sp,16
ffffffffc0200094:	8082                	ret

ffffffffc0200096 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200096:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	86ae                	mv	a3,a1
ffffffffc020009a:	862a                	mv	a2,a0
ffffffffc020009c:	006c                	addi	a1,sp,12
ffffffffc020009e:	00000517          	auipc	a0,0x0
ffffffffc02000a2:	fde50513          	addi	a0,a0,-34 # ffffffffc020007c <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a6:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a8:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000aa:	464010ef          	jal	ra,ffffffffc020150e <vprintfmt>
    return cnt;
}
ffffffffc02000ae:	60e2                	ld	ra,24(sp)
ffffffffc02000b0:	4532                	lw	a0,12(sp)
ffffffffc02000b2:	6105                	addi	sp,sp,32
ffffffffc02000b4:	8082                	ret

ffffffffc02000b6 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b6:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b8:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000bc:	f42e                	sd	a1,40(sp)
ffffffffc02000be:	f832                	sd	a2,48(sp)
ffffffffc02000c0:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c2:	862a                	mv	a2,a0
ffffffffc02000c4:	004c                	addi	a1,sp,4
ffffffffc02000c6:	00000517          	auipc	a0,0x0
ffffffffc02000ca:	fb650513          	addi	a0,a0,-74 # ffffffffc020007c <cputch>
ffffffffc02000ce:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d0:	ec06                	sd	ra,24(sp)
ffffffffc02000d2:	e0ba                	sd	a4,64(sp)
ffffffffc02000d4:	e4be                	sd	a5,72(sp)
ffffffffc02000d6:	e8c2                	sd	a6,80(sp)
ffffffffc02000d8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000da:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000dc:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000de:	430010ef          	jal	ra,ffffffffc020150e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e2:	60e2                	ld	ra,24(sp)
ffffffffc02000e4:	4512                	lw	a0,4(sp)
ffffffffc02000e6:	6125                	addi	sp,sp,96
ffffffffc02000e8:	8082                	ret

ffffffffc02000ea <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000ea:	3680006f          	j	ffffffffc0200452 <cons_putc>

ffffffffc02000ee <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ee:	1101                	addi	sp,sp,-32
ffffffffc02000f0:	e822                	sd	s0,16(sp)
ffffffffc02000f2:	ec06                	sd	ra,24(sp)
ffffffffc02000f4:	e426                	sd	s1,8(sp)
ffffffffc02000f6:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f8:	00054503          	lbu	a0,0(a0)
ffffffffc02000fc:	c51d                	beqz	a0,ffffffffc020012a <cputs+0x3c>
ffffffffc02000fe:	0405                	addi	s0,s0,1
ffffffffc0200100:	4485                	li	s1,1
ffffffffc0200102:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200104:	34e000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0200112:	f96d                	bnez	a0,ffffffffc0200104 <cputs+0x16>
ffffffffc0200114:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200118:	4529                	li	a0,10
ffffffffc020011a:	338000ef          	jal	ra,ffffffffc0200452 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011e:	8522                	mv	a0,s0
ffffffffc0200120:	60e2                	ld	ra,24(sp)
ffffffffc0200122:	6442                	ld	s0,16(sp)
ffffffffc0200124:	64a2                	ld	s1,8(sp)
ffffffffc0200126:	6105                	addi	sp,sp,32
ffffffffc0200128:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	4405                	li	s0,1
ffffffffc020012c:	b7f5                	j	ffffffffc0200118 <cputs+0x2a>

ffffffffc020012e <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012e:	1141                	addi	sp,sp,-16
ffffffffc0200130:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200132:	328000ef          	jal	ra,ffffffffc020045a <cons_getc>
ffffffffc0200136:	dd75                	beqz	a0,ffffffffc0200132 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200138:	60a2                	ld	ra,8(sp)
ffffffffc020013a:	0141                	addi	sp,sp,16
ffffffffc020013c:	8082                	ret

ffffffffc020013e <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013e:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200140:	00002517          	auipc	a0,0x2
ffffffffc0200144:	96050513          	addi	a0,a0,-1696 # ffffffffc0201aa0 <etext+0x56>
void print_kerninfo(void) {
ffffffffc0200148:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014a:	f6dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014e:	00000597          	auipc	a1,0x0
ffffffffc0200152:	ee858593          	addi	a1,a1,-280 # ffffffffc0200036 <kern_init>
ffffffffc0200156:	00002517          	auipc	a0,0x2
ffffffffc020015a:	96a50513          	addi	a0,a0,-1686 # ffffffffc0201ac0 <etext+0x76>
ffffffffc020015e:	f59ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200162:	00002597          	auipc	a1,0x2
ffffffffc0200166:	8e858593          	addi	a1,a1,-1816 # ffffffffc0201a4a <etext>
ffffffffc020016a:	00002517          	auipc	a0,0x2
ffffffffc020016e:	97650513          	addi	a0,a0,-1674 # ffffffffc0201ae0 <etext+0x96>
ffffffffc0200172:	f45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200176:	00006597          	auipc	a1,0x6
ffffffffc020017a:	ea258593          	addi	a1,a1,-350 # ffffffffc0206018 <edata>
ffffffffc020017e:	00002517          	auipc	a0,0x2
ffffffffc0200182:	98250513          	addi	a0,a0,-1662 # ffffffffc0201b00 <etext+0xb6>
ffffffffc0200186:	f31ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018a:	00006597          	auipc	a1,0x6
ffffffffc020018e:	3de58593          	addi	a1,a1,990 # ffffffffc0206568 <end>
ffffffffc0200192:	00002517          	auipc	a0,0x2
ffffffffc0200196:	98e50513          	addi	a0,a0,-1650 # ffffffffc0201b20 <etext+0xd6>
ffffffffc020019a:	f1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019e:	00006597          	auipc	a1,0x6
ffffffffc02001a2:	7c958593          	addi	a1,a1,1993 # ffffffffc0206967 <end+0x3ff>
ffffffffc02001a6:	00000797          	auipc	a5,0x0
ffffffffc02001aa:	e9078793          	addi	a5,a5,-368 # ffffffffc0200036 <kern_init>
ffffffffc02001ae:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b2:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b6:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b8:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001bc:	95be                	add	a1,a1,a5
ffffffffc02001be:	85a9                	srai	a1,a1,0xa
ffffffffc02001c0:	00002517          	auipc	a0,0x2
ffffffffc02001c4:	98050513          	addi	a0,a0,-1664 # ffffffffc0201b40 <etext+0xf6>
}
ffffffffc02001c8:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ca:	eedff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02001ce <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ce:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001d0:	00002617          	auipc	a2,0x2
ffffffffc02001d4:	8a060613          	addi	a2,a2,-1888 # ffffffffc0201a70 <etext+0x26>
ffffffffc02001d8:	04e00593          	li	a1,78
ffffffffc02001dc:	00002517          	auipc	a0,0x2
ffffffffc02001e0:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0201a88 <etext+0x3e>
void print_stackframe(void) {
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e6:	1c6000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001ea <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001ea:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001ec:	00002617          	auipc	a2,0x2
ffffffffc02001f0:	a6460613          	addi	a2,a2,-1436 # ffffffffc0201c50 <commands+0xe0>
ffffffffc02001f4:	00002597          	auipc	a1,0x2
ffffffffc02001f8:	a7c58593          	addi	a1,a1,-1412 # ffffffffc0201c70 <commands+0x100>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	a7c50513          	addi	a0,a0,-1412 # ffffffffc0201c78 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200206:	eb1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020020a:	00002617          	auipc	a2,0x2
ffffffffc020020e:	a7e60613          	addi	a2,a2,-1410 # ffffffffc0201c88 <commands+0x118>
ffffffffc0200212:	00002597          	auipc	a1,0x2
ffffffffc0200216:	a9e58593          	addi	a1,a1,-1378 # ffffffffc0201cb0 <commands+0x140>
ffffffffc020021a:	00002517          	auipc	a0,0x2
ffffffffc020021e:	a5e50513          	addi	a0,a0,-1442 # ffffffffc0201c78 <commands+0x108>
ffffffffc0200222:	e95ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200226:	00002617          	auipc	a2,0x2
ffffffffc020022a:	a9a60613          	addi	a2,a2,-1382 # ffffffffc0201cc0 <commands+0x150>
ffffffffc020022e:	00002597          	auipc	a1,0x2
ffffffffc0200232:	ab258593          	addi	a1,a1,-1358 # ffffffffc0201ce0 <commands+0x170>
ffffffffc0200236:	00002517          	auipc	a0,0x2
ffffffffc020023a:	a4250513          	addi	a0,a0,-1470 # ffffffffc0201c78 <commands+0x108>
ffffffffc020023e:	e79ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    }
    return 0;
}
ffffffffc0200242:	60a2                	ld	ra,8(sp)
ffffffffc0200244:	4501                	li	a0,0
ffffffffc0200246:	0141                	addi	sp,sp,16
ffffffffc0200248:	8082                	ret

ffffffffc020024a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
ffffffffc020024c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020024e:	ef1ff0ef          	jal	ra,ffffffffc020013e <print_kerninfo>
    return 0;
}
ffffffffc0200252:	60a2                	ld	ra,8(sp)
ffffffffc0200254:	4501                	li	a0,0
ffffffffc0200256:	0141                	addi	sp,sp,16
ffffffffc0200258:	8082                	ret

ffffffffc020025a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025a:	1141                	addi	sp,sp,-16
ffffffffc020025c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020025e:	f71ff0ef          	jal	ra,ffffffffc02001ce <print_stackframe>
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026a:	7115                	addi	sp,sp,-224
ffffffffc020026c:	e962                	sd	s8,144(sp)
ffffffffc020026e:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200270:	00002517          	auipc	a0,0x2
ffffffffc0200274:	94850513          	addi	a0,a0,-1720 # ffffffffc0201bb8 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200278:	ed86                	sd	ra,216(sp)
ffffffffc020027a:	e9a2                	sd	s0,208(sp)
ffffffffc020027c:	e5a6                	sd	s1,200(sp)
ffffffffc020027e:	e1ca                	sd	s2,192(sp)
ffffffffc0200280:	fd4e                	sd	s3,184(sp)
ffffffffc0200282:	f952                	sd	s4,176(sp)
ffffffffc0200284:	f556                	sd	s5,168(sp)
ffffffffc0200286:	f15a                	sd	s6,160(sp)
ffffffffc0200288:	ed5e                	sd	s7,152(sp)
ffffffffc020028a:	e566                	sd	s9,136(sp)
ffffffffc020028c:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020028e:	e29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200292:	00002517          	auipc	a0,0x2
ffffffffc0200296:	94e50513          	addi	a0,a0,-1714 # ffffffffc0201be0 <commands+0x70>
ffffffffc020029a:	e1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (tf != NULL) {
ffffffffc020029e:	000c0563          	beqz	s8,ffffffffc02002a8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a2:	8562                	mv	a0,s8
ffffffffc02002a4:	3a6000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002a8:	00002c97          	auipc	s9,0x2
ffffffffc02002ac:	8c8c8c93          	addi	s9,s9,-1848 # ffffffffc0201b70 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b0:	00002997          	auipc	s3,0x2
ffffffffc02002b4:	95898993          	addi	s3,s3,-1704 # ffffffffc0201c08 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00002917          	auipc	s2,0x2
ffffffffc02002bc:	95890913          	addi	s2,s2,-1704 # ffffffffc0201c10 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002c0:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c2:	00002b17          	auipc	s6,0x2
ffffffffc02002c6:	956b0b13          	addi	s6,s6,-1706 # ffffffffc0201c18 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ca:	00002a97          	auipc	s5,0x2
ffffffffc02002ce:	9a6a8a93          	addi	s5,s5,-1626 # ffffffffc0201c70 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d2:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d4:	854e                	mv	a0,s3
ffffffffc02002d6:	5c4010ef          	jal	ra,ffffffffc020189a <readline>
ffffffffc02002da:	842a                	mv	s0,a0
ffffffffc02002dc:	dd65                	beqz	a0,ffffffffc02002d4 <kmonitor+0x6a>
ffffffffc02002de:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e4:	c999                	beqz	a1,ffffffffc02002fa <kmonitor+0x90>
ffffffffc02002e6:	854a                	mv	a0,s2
ffffffffc02002e8:	732010ef          	jal	ra,ffffffffc0201a1a <strchr>
ffffffffc02002ec:	c925                	beqz	a0,ffffffffc020035c <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02002ee:	00144583          	lbu	a1,1(s0)
ffffffffc02002f2:	00040023          	sb	zero,0(s0)
ffffffffc02002f6:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002f8:	f5fd                	bnez	a1,ffffffffc02002e6 <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02002fa:	dce9                	beqz	s1,ffffffffc02002d4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002fc:	6582                	ld	a1,0(sp)
ffffffffc02002fe:	00002d17          	auipc	s10,0x2
ffffffffc0200302:	872d0d13          	addi	s10,s10,-1934 # ffffffffc0201b70 <commands>
    if (argc == 0) {
ffffffffc0200306:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200308:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	0d61                	addi	s10,s10,24
ffffffffc020030c:	6e4010ef          	jal	ra,ffffffffc02019f0 <strcmp>
ffffffffc0200310:	c919                	beqz	a0,ffffffffc0200326 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200312:	2405                	addiw	s0,s0,1
ffffffffc0200314:	09740463          	beq	s0,s7,ffffffffc020039c <kmonitor+0x132>
ffffffffc0200318:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031c:	6582                	ld	a1,0(sp)
ffffffffc020031e:	0d61                	addi	s10,s10,24
ffffffffc0200320:	6d0010ef          	jal	ra,ffffffffc02019f0 <strcmp>
ffffffffc0200324:	f57d                	bnez	a0,ffffffffc0200312 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200326:	00141793          	slli	a5,s0,0x1
ffffffffc020032a:	97a2                	add	a5,a5,s0
ffffffffc020032c:	078e                	slli	a5,a5,0x3
ffffffffc020032e:	97e6                	add	a5,a5,s9
ffffffffc0200330:	6b9c                	ld	a5,16(a5)
ffffffffc0200332:	8662                	mv	a2,s8
ffffffffc0200334:	002c                	addi	a1,sp,8
ffffffffc0200336:	fff4851b          	addiw	a0,s1,-1
ffffffffc020033a:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020033c:	f8055ce3          	bgez	a0,ffffffffc02002d4 <kmonitor+0x6a>
}
ffffffffc0200340:	60ee                	ld	ra,216(sp)
ffffffffc0200342:	644e                	ld	s0,208(sp)
ffffffffc0200344:	64ae                	ld	s1,200(sp)
ffffffffc0200346:	690e                	ld	s2,192(sp)
ffffffffc0200348:	79ea                	ld	s3,184(sp)
ffffffffc020034a:	7a4a                	ld	s4,176(sp)
ffffffffc020034c:	7aaa                	ld	s5,168(sp)
ffffffffc020034e:	7b0a                	ld	s6,160(sp)
ffffffffc0200350:	6bea                	ld	s7,152(sp)
ffffffffc0200352:	6c4a                	ld	s8,144(sp)
ffffffffc0200354:	6caa                	ld	s9,136(sp)
ffffffffc0200356:	6d0a                	ld	s10,128(sp)
ffffffffc0200358:	612d                	addi	sp,sp,224
ffffffffc020035a:	8082                	ret
        if (*buf == '\0') {
ffffffffc020035c:	00044783          	lbu	a5,0(s0)
ffffffffc0200360:	dfc9                	beqz	a5,ffffffffc02002fa <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc0200362:	03448863          	beq	s1,s4,ffffffffc0200392 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc0200366:	00349793          	slli	a5,s1,0x3
ffffffffc020036a:	0118                	addi	a4,sp,128
ffffffffc020036c:	97ba                	add	a5,a5,a4
ffffffffc020036e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200372:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200376:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200378:	e591                	bnez	a1,ffffffffc0200384 <kmonitor+0x11a>
ffffffffc020037a:	b749                	j	ffffffffc02002fc <kmonitor+0x92>
            buf ++;
ffffffffc020037c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037e:	00044583          	lbu	a1,0(s0)
ffffffffc0200382:	ddad                	beqz	a1,ffffffffc02002fc <kmonitor+0x92>
ffffffffc0200384:	854a                	mv	a0,s2
ffffffffc0200386:	694010ef          	jal	ra,ffffffffc0201a1a <strchr>
ffffffffc020038a:	d96d                	beqz	a0,ffffffffc020037c <kmonitor+0x112>
ffffffffc020038c:	00044583          	lbu	a1,0(s0)
ffffffffc0200390:	bf91                	j	ffffffffc02002e4 <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d21ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020039a:	b7f1                	j	ffffffffc0200366 <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	89a50513          	addi	a0,a0,-1894 # ffffffffc0201c38 <commands+0xc8>
ffffffffc02003a6:	d11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    return 0;
ffffffffc02003aa:	b72d                	j	ffffffffc02002d4 <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	06c30313          	addi	t1,t1,108 # ffffffffc0206418 <is_panic>
ffffffffc02003b4:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	02031c63          	bnez	t1,ffffffffc0200400 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	8432                	mv	s0,a2
ffffffffc02003d0:	00006717          	auipc	a4,0x6
ffffffffc02003d4:	04f72423          	sw	a5,72(a4) # ffffffffc0206418 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d8:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02003da:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003dc:	85aa                	mv	a1,a0
ffffffffc02003de:	00002517          	auipc	a0,0x2
ffffffffc02003e2:	91250513          	addi	a0,a0,-1774 # ffffffffc0201cf0 <commands+0x180>
    va_start(ap, fmt);
ffffffffc02003e6:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e8:	ccfff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003ec:	65a2                	ld	a1,8(sp)
ffffffffc02003ee:	8522                	mv	a0,s0
ffffffffc02003f0:	ca7ff0ef          	jal	ra,ffffffffc0200096 <vcprintf>
    cprintf("\n");
ffffffffc02003f4:	00002517          	auipc	a0,0x2
ffffffffc02003f8:	0b450513          	addi	a0,a0,180 # ffffffffc02024a8 <commands+0x938>
ffffffffc02003fc:	cbbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200400:	064000ef          	jal	ra,ffffffffc0200464 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200404:	4501                	li	a0,0
ffffffffc0200406:	e65ff0ef          	jal	ra,ffffffffc020026a <kmonitor>
ffffffffc020040a:	bfed                	j	ffffffffc0200404 <__panic+0x58>

ffffffffc020040c <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020040c:	1141                	addi	sp,sp,-16
ffffffffc020040e:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200410:	02000793          	li	a5,32
ffffffffc0200414:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200418:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020041c:	67e1                	lui	a5,0x18
ffffffffc020041e:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc0200422:	953e                	add	a0,a0,a5
ffffffffc0200424:	550010ef          	jal	ra,ffffffffc0201974 <sbi_set_timer>
}
ffffffffc0200428:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042a:	00006797          	auipc	a5,0x6
ffffffffc020042e:	0007bb23          	sd	zero,22(a5) # ffffffffc0206440 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200432:	00002517          	auipc	a0,0x2
ffffffffc0200436:	8de50513          	addi	a0,a0,-1826 # ffffffffc0201d10 <commands+0x1a0>
}
ffffffffc020043a:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020043c:	c7bff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc0200440 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200440:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200444:	67e1                	lui	a5,0x18
ffffffffc0200446:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020044a:	953e                	add	a0,a0,a5
ffffffffc020044c:	5280106f          	j	ffffffffc0201974 <sbi_set_timer>

ffffffffc0200450 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200450:	8082                	ret

ffffffffc0200452 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200452:	0ff57513          	andi	a0,a0,255
ffffffffc0200456:	5020106f          	j	ffffffffc0201958 <sbi_console_putchar>

ffffffffc020045a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045a:	5360106f          	j	ffffffffc0201990 <sbi_console_getchar>

ffffffffc020045e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200464:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200468:	8082                	ret

ffffffffc020046a <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020046a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020046e:	00000797          	auipc	a5,0x0
ffffffffc0200472:	33278793          	addi	a5,a5,818 # ffffffffc02007a0 <__alltraps>
ffffffffc0200476:	10579073          	csrw	stvec,a5
}
ffffffffc020047a:	8082                	ret

ffffffffc020047c <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047c:	610c                	ld	a1,0(a0)
{
ffffffffc020047e:	1141                	addi	sp,sp,-16
ffffffffc0200480:	e022                	sd	s0,0(sp)
ffffffffc0200482:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200484:	00002517          	auipc	a0,0x2
ffffffffc0200488:	9a450513          	addi	a0,a0,-1628 # ffffffffc0201e28 <commands+0x2b8>
{
ffffffffc020048c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048e:	c29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200492:	640c                	ld	a1,8(s0)
ffffffffc0200494:	00002517          	auipc	a0,0x2
ffffffffc0200498:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0201e40 <commands+0x2d0>
ffffffffc020049c:	c1bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a0:	680c                	ld	a1,16(s0)
ffffffffc02004a2:	00002517          	auipc	a0,0x2
ffffffffc02004a6:	9b650513          	addi	a0,a0,-1610 # ffffffffc0201e58 <commands+0x2e8>
ffffffffc02004aa:	c0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004ae:	6c0c                	ld	a1,24(s0)
ffffffffc02004b0:	00002517          	auipc	a0,0x2
ffffffffc02004b4:	9c050513          	addi	a0,a0,-1600 # ffffffffc0201e70 <commands+0x300>
ffffffffc02004b8:	bffff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004bc:	700c                	ld	a1,32(s0)
ffffffffc02004be:	00002517          	auipc	a0,0x2
ffffffffc02004c2:	9ca50513          	addi	a0,a0,-1590 # ffffffffc0201e88 <commands+0x318>
ffffffffc02004c6:	bf1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004ca:	740c                	ld	a1,40(s0)
ffffffffc02004cc:	00002517          	auipc	a0,0x2
ffffffffc02004d0:	9d450513          	addi	a0,a0,-1580 # ffffffffc0201ea0 <commands+0x330>
ffffffffc02004d4:	be3ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d8:	780c                	ld	a1,48(s0)
ffffffffc02004da:	00002517          	auipc	a0,0x2
ffffffffc02004de:	9de50513          	addi	a0,a0,-1570 # ffffffffc0201eb8 <commands+0x348>
ffffffffc02004e2:	bd5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e6:	7c0c                	ld	a1,56(s0)
ffffffffc02004e8:	00002517          	auipc	a0,0x2
ffffffffc02004ec:	9e850513          	addi	a0,a0,-1560 # ffffffffc0201ed0 <commands+0x360>
ffffffffc02004f0:	bc7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f4:	602c                	ld	a1,64(s0)
ffffffffc02004f6:	00002517          	auipc	a0,0x2
ffffffffc02004fa:	9f250513          	addi	a0,a0,-1550 # ffffffffc0201ee8 <commands+0x378>
ffffffffc02004fe:	bb9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200502:	642c                	ld	a1,72(s0)
ffffffffc0200504:	00002517          	auipc	a0,0x2
ffffffffc0200508:	9fc50513          	addi	a0,a0,-1540 # ffffffffc0201f00 <commands+0x390>
ffffffffc020050c:	babff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200510:	682c                	ld	a1,80(s0)
ffffffffc0200512:	00002517          	auipc	a0,0x2
ffffffffc0200516:	a0650513          	addi	a0,a0,-1530 # ffffffffc0201f18 <commands+0x3a8>
ffffffffc020051a:	b9dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051e:	6c2c                	ld	a1,88(s0)
ffffffffc0200520:	00002517          	auipc	a0,0x2
ffffffffc0200524:	a1050513          	addi	a0,a0,-1520 # ffffffffc0201f30 <commands+0x3c0>
ffffffffc0200528:	b8fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052c:	702c                	ld	a1,96(s0)
ffffffffc020052e:	00002517          	auipc	a0,0x2
ffffffffc0200532:	a1a50513          	addi	a0,a0,-1510 # ffffffffc0201f48 <commands+0x3d8>
ffffffffc0200536:	b81ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053a:	742c                	ld	a1,104(s0)
ffffffffc020053c:	00002517          	auipc	a0,0x2
ffffffffc0200540:	a2450513          	addi	a0,a0,-1500 # ffffffffc0201f60 <commands+0x3f0>
ffffffffc0200544:	b73ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200548:	782c                	ld	a1,112(s0)
ffffffffc020054a:	00002517          	auipc	a0,0x2
ffffffffc020054e:	a2e50513          	addi	a0,a0,-1490 # ffffffffc0201f78 <commands+0x408>
ffffffffc0200552:	b65ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200556:	7c2c                	ld	a1,120(s0)
ffffffffc0200558:	00002517          	auipc	a0,0x2
ffffffffc020055c:	a3850513          	addi	a0,a0,-1480 # ffffffffc0201f90 <commands+0x420>
ffffffffc0200560:	b57ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200564:	604c                	ld	a1,128(s0)
ffffffffc0200566:	00002517          	auipc	a0,0x2
ffffffffc020056a:	a4250513          	addi	a0,a0,-1470 # ffffffffc0201fa8 <commands+0x438>
ffffffffc020056e:	b49ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200572:	644c                	ld	a1,136(s0)
ffffffffc0200574:	00002517          	auipc	a0,0x2
ffffffffc0200578:	a4c50513          	addi	a0,a0,-1460 # ffffffffc0201fc0 <commands+0x450>
ffffffffc020057c:	b3bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200580:	684c                	ld	a1,144(s0)
ffffffffc0200582:	00002517          	auipc	a0,0x2
ffffffffc0200586:	a5650513          	addi	a0,a0,-1450 # ffffffffc0201fd8 <commands+0x468>
ffffffffc020058a:	b2dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058e:	6c4c                	ld	a1,152(s0)
ffffffffc0200590:	00002517          	auipc	a0,0x2
ffffffffc0200594:	a6050513          	addi	a0,a0,-1440 # ffffffffc0201ff0 <commands+0x480>
ffffffffc0200598:	b1fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059c:	704c                	ld	a1,160(s0)
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0202008 <commands+0x498>
ffffffffc02005a6:	b11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005aa:	744c                	ld	a1,168(s0)
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	a7450513          	addi	a0,a0,-1420 # ffffffffc0202020 <commands+0x4b0>
ffffffffc02005b4:	b03ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b8:	784c                	ld	a1,176(s0)
ffffffffc02005ba:	00002517          	auipc	a0,0x2
ffffffffc02005be:	a7e50513          	addi	a0,a0,-1410 # ffffffffc0202038 <commands+0x4c8>
ffffffffc02005c2:	af5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c6:	7c4c                	ld	a1,184(s0)
ffffffffc02005c8:	00002517          	auipc	a0,0x2
ffffffffc02005cc:	a8850513          	addi	a0,a0,-1400 # ffffffffc0202050 <commands+0x4e0>
ffffffffc02005d0:	ae7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d4:	606c                	ld	a1,192(s0)
ffffffffc02005d6:	00002517          	auipc	a0,0x2
ffffffffc02005da:	a9250513          	addi	a0,a0,-1390 # ffffffffc0202068 <commands+0x4f8>
ffffffffc02005de:	ad9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e2:	646c                	ld	a1,200(s0)
ffffffffc02005e4:	00002517          	auipc	a0,0x2
ffffffffc02005e8:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0202080 <commands+0x510>
ffffffffc02005ec:	acbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f0:	686c                	ld	a1,208(s0)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	aa650513          	addi	a0,a0,-1370 # ffffffffc0202098 <commands+0x528>
ffffffffc02005fa:	abdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200600:	00002517          	auipc	a0,0x2
ffffffffc0200604:	ab050513          	addi	a0,a0,-1360 # ffffffffc02020b0 <commands+0x540>
ffffffffc0200608:	aafff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060c:	706c                	ld	a1,224(s0)
ffffffffc020060e:	00002517          	auipc	a0,0x2
ffffffffc0200612:	aba50513          	addi	a0,a0,-1350 # ffffffffc02020c8 <commands+0x558>
ffffffffc0200616:	aa1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061a:	746c                	ld	a1,232(s0)
ffffffffc020061c:	00002517          	auipc	a0,0x2
ffffffffc0200620:	ac450513          	addi	a0,a0,-1340 # ffffffffc02020e0 <commands+0x570>
ffffffffc0200624:	a93ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200628:	786c                	ld	a1,240(s0)
ffffffffc020062a:	00002517          	auipc	a0,0x2
ffffffffc020062e:	ace50513          	addi	a0,a0,-1330 # ffffffffc02020f8 <commands+0x588>
ffffffffc0200632:	a85ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200638:	6402                	ld	s0,0(sp)
ffffffffc020063a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	ad450513          	addi	a0,a0,-1324 # ffffffffc0202110 <commands+0x5a0>
}
ffffffffc0200644:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200646:	a71ff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020064a <print_trapframe>:
{
ffffffffc020064a:	1141                	addi	sp,sp,-16
ffffffffc020064c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020064e:	85aa                	mv	a1,a0
{
ffffffffc0200650:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200652:	00002517          	auipc	a0,0x2
ffffffffc0200656:	ad650513          	addi	a0,a0,-1322 # ffffffffc0202128 <commands+0x5b8>
{
ffffffffc020065a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020065c:	a5bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200660:	8522                	mv	a0,s0
ffffffffc0200662:	e1bff0ef          	jal	ra,ffffffffc020047c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200666:	10043583          	ld	a1,256(s0)
ffffffffc020066a:	00002517          	auipc	a0,0x2
ffffffffc020066e:	ad650513          	addi	a0,a0,-1322 # ffffffffc0202140 <commands+0x5d0>
ffffffffc0200672:	a45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	ade50513          	addi	a0,a0,-1314 # ffffffffc0202158 <commands+0x5e8>
ffffffffc0200682:	a35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	ae650513          	addi	a0,a0,-1306 # ffffffffc0202170 <commands+0x600>
ffffffffc0200692:	a25ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	aea50513          	addi	a0,a0,-1302 # ffffffffc0202188 <commands+0x618>
}
ffffffffc02006a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a8:	a0fff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02006ac <interrupt_handler>:

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006ac:	11853783          	ld	a5,280(a0)
ffffffffc02006b0:	577d                	li	a4,-1
ffffffffc02006b2:	8305                	srli	a4,a4,0x1
ffffffffc02006b4:	8ff9                	and	a5,a5,a4
    switch (cause)
ffffffffc02006b6:	472d                	li	a4,11
ffffffffc02006b8:	08f76763          	bltu	a4,a5,ffffffffc0200746 <interrupt_handler+0x9a>
ffffffffc02006bc:	00001717          	auipc	a4,0x1
ffffffffc02006c0:	67070713          	addi	a4,a4,1648 # ffffffffc0201d2c <commands+0x1bc>
ffffffffc02006c4:	078a                	slli	a5,a5,0x2
ffffffffc02006c6:	97ba                	add	a5,a5,a4
ffffffffc02006c8:	439c                	lw	a5,0(a5)
ffffffffc02006ca:	97ba                	add	a5,a5,a4
ffffffffc02006cc:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc02006ce:	00001517          	auipc	a0,0x1
ffffffffc02006d2:	6f250513          	addi	a0,a0,1778 # ffffffffc0201dc0 <commands+0x250>
ffffffffc02006d6:	9e1ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc02006da:	00001517          	auipc	a0,0x1
ffffffffc02006de:	6c650513          	addi	a0,a0,1734 # ffffffffc0201da0 <commands+0x230>
ffffffffc02006e2:	9d5ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc02006e6:	00001517          	auipc	a0,0x1
ffffffffc02006ea:	67a50513          	addi	a0,a0,1658 # ffffffffc0201d60 <commands+0x1f0>
ffffffffc02006ee:	9c9ff06f          	j	ffffffffc02000b6 <cprintf>
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
ffffffffc02006f2:	00001517          	auipc	a0,0x1
ffffffffc02006f6:	6ee50513          	addi	a0,a0,1774 # ffffffffc0201de0 <commands+0x270>
ffffffffc02006fa:	9bdff06f          	j	ffffffffc02000b6 <cprintf>
{
ffffffffc02006fe:	1141                	addi	sp,sp,-16
ffffffffc0200700:	e406                	sd	ra,8(sp)
ffffffffc0200702:	e022                	sd	s0,0(sp)
        // read-only." -- privileged spec1.9.1, 4.1.4, p59
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // cprintf("Supervisor timer interrupt\n");
        // clear_csr(sip, SIP_STIP);
        clock_set_next_event();
ffffffffc0200704:	d3dff0ef          	jal	ra,ffffffffc0200440 <clock_set_next_event>
        ticks++;
ffffffffc0200708:	00006717          	auipc	a4,0x6
ffffffffc020070c:	d3870713          	addi	a4,a4,-712 # ffffffffc0206440 <ticks>
ffffffffc0200710:	631c                	ld	a5,0(a4)
        if (ticks == 100)
ffffffffc0200712:	06400693          	li	a3,100
        ticks++;
ffffffffc0200716:	0785                	addi	a5,a5,1
ffffffffc0200718:	00006617          	auipc	a2,0x6
ffffffffc020071c:	d2f63423          	sd	a5,-728(a2) # ffffffffc0206440 <ticks>
        if (ticks == 100)
ffffffffc0200720:	631c                	ld	a5,0(a4)
ffffffffc0200722:	02d78463          	beq	a5,a3,ffffffffc020074a <interrupt_handler+0x9e>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200726:	60a2                	ld	ra,8(sp)
ffffffffc0200728:	6402                	ld	s0,0(sp)
ffffffffc020072a:	0141                	addi	sp,sp,16
ffffffffc020072c:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc020072e:	00001517          	auipc	a0,0x1
ffffffffc0200732:	6da50513          	addi	a0,a0,1754 # ffffffffc0201e08 <commands+0x298>
ffffffffc0200736:	981ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc020073a:	00001517          	auipc	a0,0x1
ffffffffc020073e:	64650513          	addi	a0,a0,1606 # ffffffffc0201d80 <commands+0x210>
ffffffffc0200742:	975ff06f          	j	ffffffffc02000b6 <cprintf>
        print_trapframe(tf);
ffffffffc0200746:	f05ff06f          	j	ffffffffc020064a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020074a:	06400593          	li	a1,100
ffffffffc020074e:	00001517          	auipc	a0,0x1
ffffffffc0200752:	6aa50513          	addi	a0,a0,1706 # ffffffffc0201df8 <commands+0x288>
            ticks = 0;
ffffffffc0200756:	00006797          	auipc	a5,0x6
ffffffffc020075a:	ce07b523          	sd	zero,-790(a5) # ffffffffc0206440 <ticks>
            if (num == 10)
ffffffffc020075e:	00006417          	auipc	s0,0x6
ffffffffc0200762:	cc240413          	addi	s0,s0,-830 # ffffffffc0206420 <num>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200766:	951ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
            if (num == 10)
ffffffffc020076a:	6018                	ld	a4,0(s0)
ffffffffc020076c:	47a9                	li	a5,10
ffffffffc020076e:	00f70963          	beq	a4,a5,ffffffffc0200780 <interrupt_handler+0xd4>
            num++;
ffffffffc0200772:	601c                	ld	a5,0(s0)
ffffffffc0200774:	0785                	addi	a5,a5,1
ffffffffc0200776:	00006717          	auipc	a4,0x6
ffffffffc020077a:	caf73523          	sd	a5,-854(a4) # ffffffffc0206420 <num>
ffffffffc020077e:	b765                	j	ffffffffc0200726 <interrupt_handler+0x7a>
                sbi_shutdown();
ffffffffc0200780:	22e010ef          	jal	ra,ffffffffc02019ae <sbi_shutdown>
ffffffffc0200784:	b7fd                	j	ffffffffc0200772 <interrupt_handler+0xc6>

ffffffffc0200786 <trap>:
    }
}

static inline void trap_dispatch(struct trapframe *tf)
{
    if ((intptr_t)tf->cause < 0)
ffffffffc0200786:	11853783          	ld	a5,280(a0)
ffffffffc020078a:	0007c863          	bltz	a5,ffffffffc020079a <trap+0x14>
    switch (tf->cause)
ffffffffc020078e:	472d                	li	a4,11
ffffffffc0200790:	00f76363          	bltu	a4,a5,ffffffffc0200796 <trap+0x10>
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200794:	8082                	ret
        print_trapframe(tf);
ffffffffc0200796:	eb5ff06f          	j	ffffffffc020064a <print_trapframe>
        interrupt_handler(tf);
ffffffffc020079a:	f13ff06f          	j	ffffffffc02006ac <interrupt_handler>
	...

ffffffffc02007a0 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc02007a0:	14011073          	csrw	sscratch,sp
ffffffffc02007a4:	712d                	addi	sp,sp,-288
ffffffffc02007a6:	e002                	sd	zero,0(sp)
ffffffffc02007a8:	e406                	sd	ra,8(sp)
ffffffffc02007aa:	ec0e                	sd	gp,24(sp)
ffffffffc02007ac:	f012                	sd	tp,32(sp)
ffffffffc02007ae:	f416                	sd	t0,40(sp)
ffffffffc02007b0:	f81a                	sd	t1,48(sp)
ffffffffc02007b2:	fc1e                	sd	t2,56(sp)
ffffffffc02007b4:	e0a2                	sd	s0,64(sp)
ffffffffc02007b6:	e4a6                	sd	s1,72(sp)
ffffffffc02007b8:	e8aa                	sd	a0,80(sp)
ffffffffc02007ba:	ecae                	sd	a1,88(sp)
ffffffffc02007bc:	f0b2                	sd	a2,96(sp)
ffffffffc02007be:	f4b6                	sd	a3,104(sp)
ffffffffc02007c0:	f8ba                	sd	a4,112(sp)
ffffffffc02007c2:	fcbe                	sd	a5,120(sp)
ffffffffc02007c4:	e142                	sd	a6,128(sp)
ffffffffc02007c6:	e546                	sd	a7,136(sp)
ffffffffc02007c8:	e94a                	sd	s2,144(sp)
ffffffffc02007ca:	ed4e                	sd	s3,152(sp)
ffffffffc02007cc:	f152                	sd	s4,160(sp)
ffffffffc02007ce:	f556                	sd	s5,168(sp)
ffffffffc02007d0:	f95a                	sd	s6,176(sp)
ffffffffc02007d2:	fd5e                	sd	s7,184(sp)
ffffffffc02007d4:	e1e2                	sd	s8,192(sp)
ffffffffc02007d6:	e5e6                	sd	s9,200(sp)
ffffffffc02007d8:	e9ea                	sd	s10,208(sp)
ffffffffc02007da:	edee                	sd	s11,216(sp)
ffffffffc02007dc:	f1f2                	sd	t3,224(sp)
ffffffffc02007de:	f5f6                	sd	t4,232(sp)
ffffffffc02007e0:	f9fa                	sd	t5,240(sp)
ffffffffc02007e2:	fdfe                	sd	t6,248(sp)
ffffffffc02007e4:	14001473          	csrrw	s0,sscratch,zero
ffffffffc02007e8:	100024f3          	csrr	s1,sstatus
ffffffffc02007ec:	14102973          	csrr	s2,sepc
ffffffffc02007f0:	143029f3          	csrr	s3,stval
ffffffffc02007f4:	14202a73          	csrr	s4,scause
ffffffffc02007f8:	e822                	sd	s0,16(sp)
ffffffffc02007fa:	e226                	sd	s1,256(sp)
ffffffffc02007fc:	e64a                	sd	s2,264(sp)
ffffffffc02007fe:	ea4e                	sd	s3,272(sp)
ffffffffc0200800:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200802:	850a                	mv	a0,sp
    jal trap
ffffffffc0200804:	f83ff0ef          	jal	ra,ffffffffc0200786 <trap>

ffffffffc0200808 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200808:	6492                	ld	s1,256(sp)
ffffffffc020080a:	6932                	ld	s2,264(sp)
ffffffffc020080c:	10049073          	csrw	sstatus,s1
ffffffffc0200810:	14191073          	csrw	sepc,s2
ffffffffc0200814:	60a2                	ld	ra,8(sp)
ffffffffc0200816:	61e2                	ld	gp,24(sp)
ffffffffc0200818:	7202                	ld	tp,32(sp)
ffffffffc020081a:	72a2                	ld	t0,40(sp)
ffffffffc020081c:	7342                	ld	t1,48(sp)
ffffffffc020081e:	73e2                	ld	t2,56(sp)
ffffffffc0200820:	6406                	ld	s0,64(sp)
ffffffffc0200822:	64a6                	ld	s1,72(sp)
ffffffffc0200824:	6546                	ld	a0,80(sp)
ffffffffc0200826:	65e6                	ld	a1,88(sp)
ffffffffc0200828:	7606                	ld	a2,96(sp)
ffffffffc020082a:	76a6                	ld	a3,104(sp)
ffffffffc020082c:	7746                	ld	a4,112(sp)
ffffffffc020082e:	77e6                	ld	a5,120(sp)
ffffffffc0200830:	680a                	ld	a6,128(sp)
ffffffffc0200832:	68aa                	ld	a7,136(sp)
ffffffffc0200834:	694a                	ld	s2,144(sp)
ffffffffc0200836:	69ea                	ld	s3,152(sp)
ffffffffc0200838:	7a0a                	ld	s4,160(sp)
ffffffffc020083a:	7aaa                	ld	s5,168(sp)
ffffffffc020083c:	7b4a                	ld	s6,176(sp)
ffffffffc020083e:	7bea                	ld	s7,184(sp)
ffffffffc0200840:	6c0e                	ld	s8,192(sp)
ffffffffc0200842:	6cae                	ld	s9,200(sp)
ffffffffc0200844:	6d4e                	ld	s10,208(sp)
ffffffffc0200846:	6dee                	ld	s11,216(sp)
ffffffffc0200848:	7e0e                	ld	t3,224(sp)
ffffffffc020084a:	7eae                	ld	t4,232(sp)
ffffffffc020084c:	7f4e                	ld	t5,240(sp)
ffffffffc020084e:	7fee                	ld	t6,248(sp)
ffffffffc0200850:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200852:	10200073          	sret

ffffffffc0200856 <buddy_system_init>:

static void
buddy_system_init(void)
{
    // 初始化伙伴堆链表数组中的每个free_list头
    for (int i = 0; i < MAX_BUDDY_ORDER + 1; i++)
ffffffffc0200856:	00006797          	auipc	a5,0x6
ffffffffc020085a:	bfa78793          	addi	a5,a5,-1030 # ffffffffc0206450 <buddy_s+0x8>
ffffffffc020085e:	00006717          	auipc	a4,0x6
ffffffffc0200862:	ce270713          	addi	a4,a4,-798 # ffffffffc0206540 <buddy_s+0xf8>
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm)
{
    elm->prev = elm->next = elm;
ffffffffc0200866:	e79c                	sd	a5,8(a5)
ffffffffc0200868:	e39c                	sd	a5,0(a5)
ffffffffc020086a:	07c1                	addi	a5,a5,16
ffffffffc020086c:	fee79de3          	bne	a5,a4,ffffffffc0200866 <buddy_system_init+0x10>
    {
        list_init(buddy_array + i);
    }
    max_order = 0;
ffffffffc0200870:	00006797          	auipc	a5,0x6
ffffffffc0200874:	bc07ac23          	sw	zero,-1064(a5) # ffffffffc0206448 <buddy_s>
    nr_free = 0;
ffffffffc0200878:	00006797          	auipc	a5,0x6
ffffffffc020087c:	cc07a423          	sw	zero,-824(a5) # ffffffffc0206540 <buddy_s+0xf8>
    return;
}
ffffffffc0200880:	8082                	ret

ffffffffc0200882 <buddy_system_nr_free_pages>:

static size_t
buddy_system_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200882:	00006517          	auipc	a0,0x6
ffffffffc0200886:	cbe56503          	lwu	a0,-834(a0) # ffffffffc0206540 <buddy_s+0xf8>
ffffffffc020088a:	8082                	ret

ffffffffc020088c <buddy_system_init_memmap>:
{
ffffffffc020088c:	1141                	addi	sp,sp,-16
ffffffffc020088e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200890:	c1e9                	beqz	a1,ffffffffc0200952 <buddy_system_init_memmap+0xc6>
    if (n & (n - 1))
ffffffffc0200892:	fff58793          	addi	a5,a1,-1
ffffffffc0200896:	8fed                	and	a5,a5,a1
ffffffffc0200898:	cb99                	beqz	a5,ffffffffc02008ae <buddy_system_init_memmap+0x22>
    size_t res = 1;
ffffffffc020089a:	4785                	li	a5,1
ffffffffc020089c:	a011                	j	ffffffffc02008a0 <buddy_system_init_memmap+0x14>
            res = res << 1;
ffffffffc020089e:	87ba                	mv	a5,a4
            n = n >> 1;
ffffffffc02008a0:	8185                	srli	a1,a1,0x1
            res = res << 1;
ffffffffc02008a2:	00179713          	slli	a4,a5,0x1
        while (n)
ffffffffc02008a6:	fde5                	bnez	a1,ffffffffc020089e <buddy_system_init_memmap+0x12>
        return res >> 1;
ffffffffc02008a8:	55fd                	li	a1,-1
ffffffffc02008aa:	8185                	srli	a1,a1,0x1
ffffffffc02008ac:	8dfd                	and	a1,a1,a5
    while (n >> 1)
ffffffffc02008ae:	0015d793          	srli	a5,a1,0x1
    unsigned int order = 0;
ffffffffc02008b2:	4601                	li	a2,0
    while (n >> 1)
ffffffffc02008b4:	c781                	beqz	a5,ffffffffc02008bc <buddy_system_init_memmap+0x30>
ffffffffc02008b6:	8385                	srli	a5,a5,0x1
        order++;
ffffffffc02008b8:	2605                	addiw	a2,a2,1
    while (n >> 1)
ffffffffc02008ba:	fff5                	bnez	a5,ffffffffc02008b6 <buddy_system_init_memmap+0x2a>
    for (; p != base + pnum; p++)
ffffffffc02008bc:	00259693          	slli	a3,a1,0x2
ffffffffc02008c0:	96ae                	add	a3,a3,a1
ffffffffc02008c2:	068e                	slli	a3,a3,0x3
ffffffffc02008c4:	96aa                	add	a3,a3,a0
ffffffffc02008c6:	02d50563          	beq	a0,a3,ffffffffc02008f0 <buddy_system_init_memmap+0x64>
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr)
{
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02008ca:	651c                	ld	a5,8(a0)
        assert(PageReserved(p));
ffffffffc02008cc:	8b85                	andi	a5,a5,1
ffffffffc02008ce:	c3b5                	beqz	a5,ffffffffc0200932 <buddy_system_init_memmap+0xa6>
ffffffffc02008d0:	87aa                	mv	a5,a0
        p->property = -1; // 全部初始化为非头页
ffffffffc02008d2:	587d                	li	a6,-1
ffffffffc02008d4:	a021                	j	ffffffffc02008dc <buddy_system_init_memmap+0x50>
ffffffffc02008d6:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02008d8:	8b05                	andi	a4,a4,1
ffffffffc02008da:	cf21                	beqz	a4,ffffffffc0200932 <buddy_system_init_memmap+0xa6>
        p->flags = 0;
ffffffffc02008dc:	0007b423          	sd	zero,8(a5)
        p->property = -1; // 全部初始化为非头页
ffffffffc02008e0:	0107a823          	sw	a6,16(a5)
    return page2ppn(page) << PGSHIFT;
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02008e4:	0007a023          	sw	zero,0(a5)
    for (; p != base + pnum; p++)
ffffffffc02008e8:	02878793          	addi	a5,a5,40
ffffffffc02008ec:	fed795e3          	bne	a5,a3,ffffffffc02008d6 <buddy_system_init_memmap+0x4a>
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm)
{
    __list_add(elm, listelm, listelm->next);
ffffffffc02008f0:	02061793          	slli	a5,a2,0x20
ffffffffc02008f4:	9381                	srli	a5,a5,0x20
    max_order = order;
ffffffffc02008f6:	00006697          	auipc	a3,0x6
ffffffffc02008fa:	b5268693          	addi	a3,a3,-1198 # ffffffffc0206448 <buddy_s>
ffffffffc02008fe:	0792                	slli	a5,a5,0x4
ffffffffc0200900:	00f68833          	add	a6,a3,a5
ffffffffc0200904:	01083703          	ld	a4,16(a6)
    nr_free = pnum;
ffffffffc0200908:	00006897          	auipc	a7,0x6
ffffffffc020090c:	c2b8ac23          	sw	a1,-968(a7) # ffffffffc0206540 <buddy_s+0xf8>
    max_order = order;
ffffffffc0200910:	00006897          	auipc	a7,0x6
ffffffffc0200914:	b2c8ac23          	sw	a2,-1224(a7) # ffffffffc0206448 <buddy_s>
    list_add(&(buddy_array[max_order]), &(base->page_link)); // 将第一页base插入数组的最后一个链表，作为初始化的最大块的头页
ffffffffc0200918:	01850593          	addi	a1,a0,24
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next)
{
    // prev: 新节点 elm 的前一个节点。
    // next: 新节点 elm 的后一个节点。
    prev->next = next->prev = elm;
ffffffffc020091c:	e30c                	sd	a1,0(a4)
}
ffffffffc020091e:	60a2                	ld	ra,8(sp)
    list_add(&(buddy_array[max_order]), &(base->page_link)); // 将第一页base插入数组的最后一个链表，作为初始化的最大块的头页
ffffffffc0200920:	07a1                	addi	a5,a5,8
ffffffffc0200922:	00b83823          	sd	a1,16(a6)
ffffffffc0200926:	97b6                	add	a5,a5,a3
    elm->next = next;
ffffffffc0200928:	f118                	sd	a4,32(a0)
    elm->prev = prev;
ffffffffc020092a:	ed1c                	sd	a5,24(a0)
    base->property = max_order; // 将第一页base的property设为最大块的2幂
ffffffffc020092c:	c910                	sw	a2,16(a0)
}
ffffffffc020092e:	0141                	addi	sp,sp,16
ffffffffc0200930:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200932:	00002697          	auipc	a3,0x2
ffffffffc0200936:	c0668693          	addi	a3,a3,-1018 # ffffffffc0202538 <commands+0x9c8>
ffffffffc020093a:	00002617          	auipc	a2,0x2
ffffffffc020093e:	bc660613          	addi	a2,a2,-1082 # ffffffffc0202500 <commands+0x990>
ffffffffc0200942:	09700593          	li	a1,151
ffffffffc0200946:	00002517          	auipc	a0,0x2
ffffffffc020094a:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202518 <commands+0x9a8>
ffffffffc020094e:	a5fff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0200952:	00002697          	auipc	a3,0x2
ffffffffc0200956:	ba668693          	addi	a3,a3,-1114 # ffffffffc02024f8 <commands+0x988>
ffffffffc020095a:	00002617          	auipc	a2,0x2
ffffffffc020095e:	ba660613          	addi	a2,a2,-1114 # ffffffffc0202500 <commands+0x990>
ffffffffc0200962:	08e00593          	li	a1,142
ffffffffc0200966:	00002517          	auipc	a0,0x2
ffffffffc020096a:	bb250513          	addi	a0,a0,-1102 # ffffffffc0202518 <commands+0x9a8>
ffffffffc020096e:	a3fff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200972 <buddy_system_alloc_pages>:
{
ffffffffc0200972:	7139                	addi	sp,sp,-64
ffffffffc0200974:	fc06                	sd	ra,56(sp)
ffffffffc0200976:	f822                	sd	s0,48(sp)
ffffffffc0200978:	f426                	sd	s1,40(sp)
ffffffffc020097a:	f04a                	sd	s2,32(sp)
ffffffffc020097c:	ec4e                	sd	s3,24(sp)
ffffffffc020097e:	e852                	sd	s4,16(sp)
ffffffffc0200980:	e456                	sd	s5,8(sp)
    assert(requested_pages > 0);
ffffffffc0200982:	18050663          	beqz	a0,ffffffffc0200b0e <buddy_system_alloc_pages+0x19c>
    if (requested_pages > nr_free)
ffffffffc0200986:	00006797          	auipc	a5,0x6
ffffffffc020098a:	bba7e783          	lwu	a5,-1094(a5) # ffffffffc0206540 <buddy_s+0xf8>
ffffffffc020098e:	08a7ed63          	bltu	a5,a0,ffffffffc0200a28 <buddy_system_alloc_pages+0xb6>
    if (n & (n - 1))
ffffffffc0200992:	fff50793          	addi	a5,a0,-1
ffffffffc0200996:	8fe9                	and	a5,a5,a0
ffffffffc0200998:	12079e63          	bnez	a5,ffffffffc0200ad4 <buddy_system_alloc_pages+0x162>
    while (n >> 1)
ffffffffc020099c:	00155793          	srli	a5,a0,0x1
ffffffffc02009a0:	14078063          	beqz	a5,ffffffffc0200ae0 <buddy_system_alloc_pages+0x16e>
    unsigned int order = 0;
ffffffffc02009a4:	4e81                	li	t4,0
ffffffffc02009a6:	a011                	j	ffffffffc02009aa <buddy_system_alloc_pages+0x38>
        order++;
ffffffffc02009a8:	8eba                	mv	t4,a4
    while (n >> 1)
ffffffffc02009aa:	8385                	srli	a5,a5,0x1
        order++;
ffffffffc02009ac:	001e871b          	addiw	a4,t4,1
    while (n >> 1)
ffffffffc02009b0:	ffe5                	bnez	a5,ffffffffc02009a8 <buddy_system_alloc_pages+0x36>
ffffffffc02009b2:	2e89                	addiw	t4,t4,2
ffffffffc02009b4:	02071793          	slli	a5,a4,0x20
ffffffffc02009b8:	83f1                	srli	a5,a5,0x1c
ffffffffc02009ba:	004e9f93          	slli	t6,t4,0x4
ffffffffc02009be:	82f6                	mv	t0,t4
ffffffffc02009c0:	89f6                	mv	s3,t4
ffffffffc02009c2:	00878393          	addi	t2,a5,8
ffffffffc02009c6:	0fa1                	addi	t6,t6,8
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc02009c8:	00006e17          	auipc	t3,0x6
ffffffffc02009cc:	a80e0e13          	addi	t3,t3,-1408 # ffffffffc0206448 <buddy_s>
            for (i = order_of_2 + 1; i <= max_order; ++i)
ffffffffc02009d0:	000e2883          	lw	a7,0(t3)
    return list->next == list;
ffffffffc02009d4:	00fe0333          	add	t1,t3,a5
ffffffffc02009d8:	01033783          	ld	a5,16(t1)
ffffffffc02009dc:	00228f13          	addi	t5,t0,2
ffffffffc02009e0:	00429413          	slli	s0,t0,0x4
ffffffffc02009e4:	0f12                	slli	t5,t5,0x4
    assert(n > 0 && n <= max_order);
ffffffffc02009e6:	02089913          	slli	s2,a7,0x20
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc02009ea:	93f2                	add	t2,t2,t3
                if (!list_empty(&(buddy_array[i])))
ffffffffc02009ec:	9ff2                	add	t6,t6,t3
    assert(n > 0 && n <= max_order);
ffffffffc02009ee:	02095913          	srli	s2,s2,0x20
ffffffffc02009f2:	9f72                	add	t5,t5,t3
ffffffffc02009f4:	9472                	add	s0,s0,t3
ffffffffc02009f6:	2285                	addiw	t0,t0,1
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b
ffffffffc02009f8:	4485                	li	s1,1
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc02009fa:	0af39a63          	bne	t2,a5,ffffffffc0200aae <buddy_system_alloc_pages+0x13c>
            for (i = order_of_2 + 1; i <= max_order; ++i)
ffffffffc02009fe:	03d8e563          	bltu	a7,t4,ffffffffc0200a28 <buddy_system_alloc_pages+0xb6>
                if (!list_empty(&(buddy_array[i])))
ffffffffc0200a02:	681c                	ld	a5,16(s0)
ffffffffc0200a04:	03f79d63          	bne	a5,t6,ffffffffc0200a3e <buddy_system_alloc_pages+0xcc>
ffffffffc0200a08:	8716                	mv	a4,t0
ffffffffc0200a0a:	87fa                	mv	a5,t5
ffffffffc0200a0c:	a811                	j	ffffffffc0200a20 <buddy_system_alloc_pages+0xae>
ffffffffc0200a0e:	6390                	ld	a2,0(a5)
ffffffffc0200a10:	ff878693          	addi	a3,a5,-8
ffffffffc0200a14:	00170593          	addi	a1,a4,1
ffffffffc0200a18:	07c1                	addi	a5,a5,16
ffffffffc0200a1a:	02d61463          	bne	a2,a3,ffffffffc0200a42 <buddy_system_alloc_pages+0xd0>
ffffffffc0200a1e:	872e                	mv	a4,a1
ffffffffc0200a20:	0007081b          	sext.w	a6,a4
            for (i = order_of_2 + 1; i <= max_order; ++i)
ffffffffc0200a24:	ff08f5e3          	bleu	a6,a7,ffffffffc0200a0e <buddy_system_alloc_pages+0x9c>
        return NULL;
ffffffffc0200a28:	4701                	li	a4,0
}
ffffffffc0200a2a:	70e2                	ld	ra,56(sp)
ffffffffc0200a2c:	7442                	ld	s0,48(sp)
ffffffffc0200a2e:	74a2                	ld	s1,40(sp)
ffffffffc0200a30:	7902                	ld	s2,32(sp)
ffffffffc0200a32:	69e2                	ld	s3,24(sp)
ffffffffc0200a34:	6a42                	ld	s4,16(sp)
ffffffffc0200a36:	6aa2                	ld	s5,8(sp)
ffffffffc0200a38:	853a                	mv	a0,a4
ffffffffc0200a3a:	6121                	addi	sp,sp,64
ffffffffc0200a3c:	8082                	ret
                if (!list_empty(&(buddy_array[i])))
ffffffffc0200a3e:	874e                	mv	a4,s3
ffffffffc0200a40:	8876                	mv	a6,t4
    assert(n > 0 && n <= max_order);
ffffffffc0200a42:	c755                	beqz	a4,ffffffffc0200aee <buddy_system_alloc_pages+0x17c>
ffffffffc0200a44:	0ae96563          	bltu	s2,a4,ffffffffc0200aee <buddy_system_alloc_pages+0x17c>
ffffffffc0200a48:	00471793          	slli	a5,a4,0x4
ffffffffc0200a4c:	00fe06b3          	add	a3,t3,a5
ffffffffc0200a50:	6a94                	ld	a3,16(a3)
    assert(!list_empty(&(buddy_array[n])));
ffffffffc0200a52:	07a1                	addi	a5,a5,8
ffffffffc0200a54:	97f2                	add	a5,a5,t3
ffffffffc0200a56:	0cf68c63          	beq	a3,a5,ffffffffc0200b2e <buddy_system_alloc_pages+0x1bc>
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b
ffffffffc0200a5a:	fff7061b          	addiw	a2,a4,-1
ffffffffc0200a5e:	00c495bb          	sllw	a1,s1,a2
ffffffffc0200a62:	00259793          	slli	a5,a1,0x2
ffffffffc0200a66:	97ae                	add	a5,a5,a1
ffffffffc0200a68:	078e                	slli	a5,a5,0x3
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a6a:	0006ba83          	ld	s5,0(a3)
ffffffffc0200a6e:	0086ba03          	ld	s4,8(a3)
ffffffffc0200a72:	17a1                	addi	a5,a5,-24
    page_a->property = n - 1;
ffffffffc0200a74:	fec6ac23          	sw	a2,-8(a3)
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b
ffffffffc0200a78:	97b6                	add	a5,a5,a3
    list_add(&(buddy_array[n - 1]), &(page_a->page_link));
ffffffffc0200a7a:	177d                	addi	a4,a4,-1
    page_b->property = n - 1;
ffffffffc0200a7c:	cb90                	sw	a2,16(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a7e:	0712                	slli	a4,a4,0x4
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next)
{
    prev->next = next;
ffffffffc0200a80:	014ab423          	sd	s4,8(s5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a84:	00ee05b3          	add	a1,t3,a4
    next->prev = prev;
ffffffffc0200a88:	015a3023          	sd	s5,0(s4)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a8c:	6990                	ld	a2,16(a1)
    list_add(&(buddy_array[n - 1]), &(page_a->page_link));
ffffffffc0200a8e:	0721                	addi	a4,a4,8
    prev->next = next->prev = elm;
ffffffffc0200a90:	e994                	sd	a3,16(a1)
ffffffffc0200a92:	9772                	add	a4,a4,t3
    elm->prev = prev;
ffffffffc0200a94:	e298                	sd	a4,0(a3)
    list_add(&(page_a->page_link), &(page_b->page_link));
ffffffffc0200a96:	01878713          	addi	a4,a5,24
    prev->next = next->prev = elm;
ffffffffc0200a9a:	e218                	sd	a4,0(a2)
ffffffffc0200a9c:	e698                	sd	a4,8(a3)
    elm->next = next;
ffffffffc0200a9e:	f390                	sd	a2,32(a5)
    elm->prev = prev;
ffffffffc0200aa0:	ef94                	sd	a3,24(a5)
            if (i > max_order)
ffffffffc0200aa2:	f908e3e3          	bltu	a7,a6,ffffffffc0200a28 <buddy_system_alloc_pages+0xb6>
    return list->next == list;
ffffffffc0200aa6:	01033783          	ld	a5,16(t1)
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc0200aaa:	f4f38ae3          	beq	t2,a5,ffffffffc02009fe <buddy_system_alloc_pages+0x8c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200aae:	6794                	ld	a3,8(a5)
ffffffffc0200ab0:	6390                	ld	a2,0(a5)
            allocated_page = le2page(list_next(&(buddy_array[order_of_2])), page_link);
ffffffffc0200ab2:	fe878713          	addi	a4,a5,-24
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200ab6:	17c1                	addi	a5,a5,-16
    prev->next = next;
ffffffffc0200ab8:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0200aba:	e290                	sd	a2,0(a3)
ffffffffc0200abc:	4689                	li	a3,2
ffffffffc0200abe:	40d7b02f          	amoor.d	zero,a3,(a5)
    if (allocated_page != NULL)
ffffffffc0200ac2:	d725                	beqz	a4,ffffffffc0200a2a <buddy_system_alloc_pages+0xb8>
        nr_free -= adjusted_pages;
ffffffffc0200ac4:	0f8e2783          	lw	a5,248(t3)
ffffffffc0200ac8:	9f89                	subw	a5,a5,a0
ffffffffc0200aca:	00006697          	auipc	a3,0x6
ffffffffc0200ace:	a6f6ab23          	sw	a5,-1418(a3) # ffffffffc0206540 <buddy_s+0xf8>
ffffffffc0200ad2:	bfa1                	j	ffffffffc0200a2a <buddy_system_alloc_pages+0xb8>
    size_t res = 1;
ffffffffc0200ad4:	4785                	li	a5,1
            n = n >> 1;
ffffffffc0200ad6:	8105                	srli	a0,a0,0x1
            res = res << 1;
ffffffffc0200ad8:	0786                	slli	a5,a5,0x1
        while (n)
ffffffffc0200ada:	fd75                	bnez	a0,ffffffffc0200ad6 <buddy_system_alloc_pages+0x164>
            res = res << 1;
ffffffffc0200adc:	853e                	mv	a0,a5
ffffffffc0200ade:	bd7d                	j	ffffffffc020099c <buddy_system_alloc_pages+0x2a>
    while (n >> 1)
ffffffffc0200ae0:	4fe1                	li	t6,24
ffffffffc0200ae2:	4285                	li	t0,1
ffffffffc0200ae4:	43a1                	li	t2,8
ffffffffc0200ae6:	4985                	li	s3,1
ffffffffc0200ae8:	4e85                	li	t4,1
ffffffffc0200aea:	4781                	li	a5,0
ffffffffc0200aec:	bdf1                	j	ffffffffc02009c8 <buddy_system_alloc_pages+0x56>
    assert(n > 0 && n <= max_order);
ffffffffc0200aee:	00001697          	auipc	a3,0x1
ffffffffc0200af2:	6ca68693          	addi	a3,a3,1738 # ffffffffc02021b8 <commands+0x648>
ffffffffc0200af6:	00002617          	auipc	a2,0x2
ffffffffc0200afa:	a0a60613          	addi	a2,a2,-1526 # ffffffffc0202500 <commands+0x990>
ffffffffc0200afe:	04a00593          	li	a1,74
ffffffffc0200b02:	00002517          	auipc	a0,0x2
ffffffffc0200b06:	a1650513          	addi	a0,a0,-1514 # ffffffffc0202518 <commands+0x9a8>
ffffffffc0200b0a:	8a3ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(requested_pages > 0);
ffffffffc0200b0e:	00001697          	auipc	a3,0x1
ffffffffc0200b12:	69268693          	addi	a3,a3,1682 # ffffffffc02021a0 <commands+0x630>
ffffffffc0200b16:	00002617          	auipc	a2,0x2
ffffffffc0200b1a:	9ea60613          	addi	a2,a2,-1558 # ffffffffc0202500 <commands+0x990>
ffffffffc0200b1e:	0a800593          	li	a1,168
ffffffffc0200b22:	00002517          	auipc	a0,0x2
ffffffffc0200b26:	9f650513          	addi	a0,a0,-1546 # ffffffffc0202518 <commands+0x9a8>
ffffffffc0200b2a:	883ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!list_empty(&(buddy_array[n])));
ffffffffc0200b2e:	00001697          	auipc	a3,0x1
ffffffffc0200b32:	6a268693          	addi	a3,a3,1698 # ffffffffc02021d0 <commands+0x660>
ffffffffc0200b36:	00002617          	auipc	a2,0x2
ffffffffc0200b3a:	9ca60613          	addi	a2,a2,-1590 # ffffffffc0202500 <commands+0x990>
ffffffffc0200b3e:	04b00593          	li	a1,75
ffffffffc0200b42:	00002517          	auipc	a0,0x2
ffffffffc0200b46:	9d650513          	addi	a0,a0,-1578 # ffffffffc0202518 <commands+0x9a8>
ffffffffc0200b4a:	863ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200b4e <show_buddy_array.constprop.4>:
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200b4e:	00006797          	auipc	a5,0x6
ffffffffc0200b52:	8fa78793          	addi	a5,a5,-1798 # ffffffffc0206448 <buddy_s>
ffffffffc0200b56:	4398                	lw	a4,0(a5)
show_buddy_array(int left, int right) // 左闭右闭
ffffffffc0200b58:	711d                	addi	sp,sp,-96
ffffffffc0200b5a:	ec86                	sd	ra,88(sp)
ffffffffc0200b5c:	e8a2                	sd	s0,80(sp)
ffffffffc0200b5e:	e4a6                	sd	s1,72(sp)
ffffffffc0200b60:	e0ca                	sd	s2,64(sp)
ffffffffc0200b62:	fc4e                	sd	s3,56(sp)
ffffffffc0200b64:	f852                	sd	s4,48(sp)
ffffffffc0200b66:	f456                	sd	s5,40(sp)
ffffffffc0200b68:	f05a                	sd	s6,32(sp)
ffffffffc0200b6a:	ec5e                	sd	s7,24(sp)
ffffffffc0200b6c:	e862                	sd	s8,16(sp)
ffffffffc0200b6e:	e466                	sd	s9,8(sp)
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200b70:	47b5                	li	a5,13
ffffffffc0200b72:	0ae7fc63          	bleu	a4,a5,ffffffffc0200c2a <show_buddy_array.constprop.4+0xdc>
    cprintf("==================显示空闲链表数组==================\n");
ffffffffc0200b76:	00002517          	auipc	a0,0x2
ffffffffc0200b7a:	a5250513          	addi	a0,a0,-1454 # ffffffffc02025c8 <buddy_system_pmm_manager+0x80>
ffffffffc0200b7e:	d38ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    for (int i = left; i <= right; i++)
ffffffffc0200b82:	00006497          	auipc	s1,0x6
ffffffffc0200b86:	8ce48493          	addi	s1,s1,-1842 # ffffffffc0206450 <buddy_s+0x8>
    bool empty = 1; // 表示空闲链表数组为空
ffffffffc0200b8a:	4785                	li	a5,1
    for (int i = left; i <= right; i++)
ffffffffc0200b8c:	4901                	li	s2,0
                cprintf("No.%d的空闲链表有", i);
ffffffffc0200b8e:	00002b17          	auipc	s6,0x2
ffffffffc0200b92:	a7ab0b13          	addi	s6,s6,-1414 # ffffffffc0202608 <buddy_system_pmm_manager+0xc0>
                cprintf("%d页 ", 1 << (p->property));
ffffffffc0200b96:	4a85                	li	s5,1
ffffffffc0200b98:	00002a17          	auipc	s4,0x2
ffffffffc0200b9c:	a88a0a13          	addi	s4,s4,-1400 # ffffffffc0202620 <buddy_system_pmm_manager+0xd8>
                cprintf("【地址为%p】\n", p);
ffffffffc0200ba0:	00002997          	auipc	s3,0x2
ffffffffc0200ba4:	a8898993          	addi	s3,s3,-1400 # ffffffffc0202628 <buddy_system_pmm_manager+0xe0>
            if (i != right)
ffffffffc0200ba8:	4c39                	li	s8,14
                cprintf("\n");
ffffffffc0200baa:	00002c97          	auipc	s9,0x2
ffffffffc0200bae:	8fec8c93          	addi	s9,s9,-1794 # ffffffffc02024a8 <commands+0x938>
    for (int i = left; i <= right; i++)
ffffffffc0200bb2:	4bbd                	li	s7,15
ffffffffc0200bb4:	a029                	j	ffffffffc0200bbe <show_buddy_array.constprop.4+0x70>
ffffffffc0200bb6:	2905                	addiw	s2,s2,1
ffffffffc0200bb8:	04c1                	addi	s1,s1,16
ffffffffc0200bba:	03790f63          	beq	s2,s7,ffffffffc0200bf8 <show_buddy_array.constprop.4+0xaa>
    return listelm->next;
ffffffffc0200bbe:	6480                	ld	s0,8(s1)
        if (list_next(le) != &buddy_array[i])
ffffffffc0200bc0:	fe940be3          	beq	s0,s1,ffffffffc0200bb6 <show_buddy_array.constprop.4+0x68>
                cprintf("No.%d的空闲链表有", i);
ffffffffc0200bc4:	85ca                	mv	a1,s2
ffffffffc0200bc6:	855a                	mv	a0,s6
ffffffffc0200bc8:	ceeff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
                cprintf("%d页 ", 1 << (p->property));
ffffffffc0200bcc:	ff842583          	lw	a1,-8(s0)
ffffffffc0200bd0:	8552                	mv	a0,s4
ffffffffc0200bd2:	00ba95bb          	sllw	a1,s5,a1
ffffffffc0200bd6:	ce0ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
                cprintf("【地址为%p】\n", p);
ffffffffc0200bda:	fe840593          	addi	a1,s0,-24
ffffffffc0200bde:	854e                	mv	a0,s3
ffffffffc0200be0:	cd6ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200be4:	6400                	ld	s0,8(s0)
            while ((le = list_next(le)) != &buddy_array[i])
ffffffffc0200be6:	fc941fe3          	bne	s0,s1,ffffffffc0200bc4 <show_buddy_array.constprop.4+0x76>
            if (i != right)
ffffffffc0200bea:	01890e63          	beq	s2,s8,ffffffffc0200c06 <show_buddy_array.constprop.4+0xb8>
                cprintf("\n");
ffffffffc0200bee:	8566                	mv	a0,s9
ffffffffc0200bf0:	cc6ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
            empty = 0;
ffffffffc0200bf4:	4781                	li	a5,0
ffffffffc0200bf6:	b7c1                	j	ffffffffc0200bb6 <show_buddy_array.constprop.4+0x68>
    if (empty)
ffffffffc0200bf8:	c799                	beqz	a5,ffffffffc0200c06 <show_buddy_array.constprop.4+0xb8>
        cprintf("无空闲块！！！\n");
ffffffffc0200bfa:	00002517          	auipc	a0,0x2
ffffffffc0200bfe:	a4650513          	addi	a0,a0,-1466 # ffffffffc0202640 <buddy_system_pmm_manager+0xf8>
ffffffffc0200c02:	cb4ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
}
ffffffffc0200c06:	6446                	ld	s0,80(sp)
ffffffffc0200c08:	60e6                	ld	ra,88(sp)
ffffffffc0200c0a:	64a6                	ld	s1,72(sp)
ffffffffc0200c0c:	6906                	ld	s2,64(sp)
ffffffffc0200c0e:	79e2                	ld	s3,56(sp)
ffffffffc0200c10:	7a42                	ld	s4,48(sp)
ffffffffc0200c12:	7aa2                	ld	s5,40(sp)
ffffffffc0200c14:	7b02                	ld	s6,32(sp)
ffffffffc0200c16:	6be2                	ld	s7,24(sp)
ffffffffc0200c18:	6c42                	ld	s8,16(sp)
ffffffffc0200c1a:	6ca2                	ld	s9,8(sp)
    cprintf("======================显示完成======================\n\n\n");
ffffffffc0200c1c:	00002517          	auipc	a0,0x2
ffffffffc0200c20:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0202658 <buddy_system_pmm_manager+0x110>
}
ffffffffc0200c24:	6125                	addi	sp,sp,96
    cprintf("======================显示完成======================\n\n\n");
ffffffffc0200c26:	c90ff06f          	j	ffffffffc02000b6 <cprintf>
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200c2a:	00002697          	auipc	a3,0x2
ffffffffc0200c2e:	95668693          	addi	a3,a3,-1706 # ffffffffc0202580 <buddy_system_pmm_manager+0x38>
ffffffffc0200c32:	00002617          	auipc	a2,0x2
ffffffffc0200c36:	8ce60613          	addi	a2,a2,-1842 # ffffffffc0202500 <commands+0x990>
ffffffffc0200c3a:	05f00593          	li	a1,95
ffffffffc0200c3e:	00002517          	auipc	a0,0x2
ffffffffc0200c42:	8da50513          	addi	a0,a0,-1830 # ffffffffc0202518 <commands+0x9a8>
ffffffffc0200c46:	f66ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200c4a <buddy_system_check>:

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
buddy_system_check(void)
{
ffffffffc0200c4a:	7179                	addi	sp,sp,-48
ffffffffc0200c4c:	e44e                	sd	s3,8(sp)
    cprintf("总空闲块数目为：%d\n", nr_free);
ffffffffc0200c4e:	00005997          	auipc	s3,0x5
ffffffffc0200c52:	7fa98993          	addi	s3,s3,2042 # ffffffffc0206448 <buddy_s>
ffffffffc0200c56:	0f89a583          	lw	a1,248(s3)
ffffffffc0200c5a:	00001517          	auipc	a0,0x1
ffffffffc0200c5e:	59e50513          	addi	a0,a0,1438 # ffffffffc02021f8 <commands+0x688>
{
ffffffffc0200c62:	f406                	sd	ra,40(sp)
ffffffffc0200c64:	f022                	sd	s0,32(sp)
ffffffffc0200c66:	ec26                	sd	s1,24(sp)
ffffffffc0200c68:	e84a                	sd	s2,16(sp)
    cprintf("总空闲块数目为：%d\n", nr_free);
ffffffffc0200c6a:	c4cff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("首先p0请求5页\n");
ffffffffc0200c6e:	00001517          	auipc	a0,0x1
ffffffffc0200c72:	5aa50513          	addi	a0,a0,1450 # ffffffffc0202218 <commands+0x6a8>
ffffffffc0200c76:	c40ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    p0 = alloc_pages(5);
ffffffffc0200c7a:	4515                	li	a0,5
ffffffffc0200c7c:	446000ef          	jal	ra,ffffffffc02010c2 <alloc_pages>
ffffffffc0200c80:	84aa                	mv	s1,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200c82:	ecdff0ef          	jal	ra,ffffffffc0200b4e <show_buddy_array.constprop.4>
    cprintf("然后p1请求5页\n");
ffffffffc0200c86:	00001517          	auipc	a0,0x1
ffffffffc0200c8a:	5aa50513          	addi	a0,a0,1450 # ffffffffc0202230 <commands+0x6c0>
ffffffffc0200c8e:	c28ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    p1 = alloc_pages(5);
ffffffffc0200c92:	4515                	li	a0,5
ffffffffc0200c94:	42e000ef          	jal	ra,ffffffffc02010c2 <alloc_pages>
ffffffffc0200c98:	842a                	mv	s0,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200c9a:	eb5ff0ef          	jal	ra,ffffffffc0200b4e <show_buddy_array.constprop.4>
    cprintf("最后p2请求5页\n");
ffffffffc0200c9e:	00001517          	auipc	a0,0x1
ffffffffc0200ca2:	5aa50513          	addi	a0,a0,1450 # ffffffffc0202248 <commands+0x6d8>
ffffffffc0200ca6:	c10ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    p2 = alloc_pages(5);
ffffffffc0200caa:	4515                	li	a0,5
ffffffffc0200cac:	416000ef          	jal	ra,ffffffffc02010c2 <alloc_pages>
ffffffffc0200cb0:	892a                	mv	s2,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200cb2:	e9dff0ef          	jal	ra,ffffffffc0200b4e <show_buddy_array.constprop.4>
    cprintf("p0的虚拟地址0x%016lx.\n", p0);
ffffffffc0200cb6:	85a6                	mv	a1,s1
ffffffffc0200cb8:	00001517          	auipc	a0,0x1
ffffffffc0200cbc:	5a850513          	addi	a0,a0,1448 # ffffffffc0202260 <commands+0x6f0>
ffffffffc0200cc0:	bf6ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("p1的虚拟地址0x%016lx.\n", p1);
ffffffffc0200cc4:	85a2                	mv	a1,s0
ffffffffc0200cc6:	00001517          	auipc	a0,0x1
ffffffffc0200cca:	5ba50513          	addi	a0,a0,1466 # ffffffffc0202280 <commands+0x710>
ffffffffc0200cce:	be8ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("p2的虚拟地址0x%016lx.\n", p2);
ffffffffc0200cd2:	85ca                	mv	a1,s2
ffffffffc0200cd4:	00001517          	auipc	a0,0x1
ffffffffc0200cd8:	5cc50513          	addi	a0,a0,1484 # ffffffffc02022a0 <commands+0x730>
ffffffffc0200cdc:	bdaff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ce0:	14848263          	beq	s1,s0,ffffffffc0200e24 <buddy_system_check+0x1da>
ffffffffc0200ce4:	15248063          	beq	s1,s2,ffffffffc0200e24 <buddy_system_check+0x1da>
ffffffffc0200ce8:	13240e63          	beq	s0,s2,ffffffffc0200e24 <buddy_system_check+0x1da>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200cec:	409c                	lw	a5,0(s1)
ffffffffc0200cee:	14079b63          	bnez	a5,ffffffffc0200e44 <buddy_system_check+0x1fa>
ffffffffc0200cf2:	401c                	lw	a5,0(s0)
ffffffffc0200cf4:	14079863          	bnez	a5,ffffffffc0200e44 <buddy_system_check+0x1fa>
ffffffffc0200cf8:	00092783          	lw	a5,0(s2)
ffffffffc0200cfc:	14079463          	bnez	a5,ffffffffc0200e44 <buddy_system_check+0x1fa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } // page-pages是page的偏移量，加上nbase就是ppn（物理页编号）
ffffffffc0200d00:	00006797          	auipc	a5,0x6
ffffffffc0200d04:	86078793          	addi	a5,a5,-1952 # ffffffffc0206560 <pages>
ffffffffc0200d08:	639c                	ld	a5,0(a5)
ffffffffc0200d0a:	00001717          	auipc	a4,0x1
ffffffffc0200d0e:	4e670713          	addi	a4,a4,1254 # ffffffffc02021f0 <commands+0x680>
ffffffffc0200d12:	630c                	ld	a1,0(a4)
ffffffffc0200d14:	40f48733          	sub	a4,s1,a5
ffffffffc0200d18:	870d                	srai	a4,a4,0x3
ffffffffc0200d1a:	02b70733          	mul	a4,a4,a1
ffffffffc0200d1e:	00002697          	auipc	a3,0x2
ffffffffc0200d22:	ed268693          	addi	a3,a3,-302 # ffffffffc0202bf0 <nbase>
ffffffffc0200d26:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200d28:	00005697          	auipc	a3,0x5
ffffffffc0200d2c:	70068693          	addi	a3,a3,1792 # ffffffffc0206428 <npage>
ffffffffc0200d30:	6294                	ld	a3,0(a3)
ffffffffc0200d32:	06b2                	slli	a3,a3,0xc
ffffffffc0200d34:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d36:	0732                	slli	a4,a4,0xc
ffffffffc0200d38:	12d77663          	bleu	a3,a4,ffffffffc0200e64 <buddy_system_check+0x21a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } // page-pages是page的偏移量，加上nbase就是ppn（物理页编号）
ffffffffc0200d3c:	40f40733          	sub	a4,s0,a5
ffffffffc0200d40:	870d                	srai	a4,a4,0x3
ffffffffc0200d42:	02b70733          	mul	a4,a4,a1
ffffffffc0200d46:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d48:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d4a:	12d77d63          	bleu	a3,a4,ffffffffc0200e84 <buddy_system_check+0x23a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } // page-pages是page的偏移量，加上nbase就是ppn（物理页编号）
ffffffffc0200d4e:	40f907b3          	sub	a5,s2,a5
ffffffffc0200d52:	878d                	srai	a5,a5,0x3
ffffffffc0200d54:	02b787b3          	mul	a5,a5,a1
ffffffffc0200d58:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d5a:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d5c:	14d7f463          	bleu	a3,a5,ffffffffc0200ea4 <buddy_system_check+0x25a>
    assert(alloc_page() == NULL);
ffffffffc0200d60:	4505                	li	a0,1
    nr_free = 0;
ffffffffc0200d62:	00005797          	auipc	a5,0x5
ffffffffc0200d66:	7c07af23          	sw	zero,2014(a5) # ffffffffc0206540 <buddy_s+0xf8>
    assert(alloc_page() == NULL);
ffffffffc0200d6a:	358000ef          	jal	ra,ffffffffc02010c2 <alloc_pages>
ffffffffc0200d6e:	14051b63          	bnez	a0,ffffffffc0200ec4 <buddy_system_check+0x27a>
    cprintf("释放p0中。。。。。。");
ffffffffc0200d72:	00001517          	auipc	a0,0x1
ffffffffc0200d76:	62e50513          	addi	a0,a0,1582 # ffffffffc02023a0 <commands+0x830>
ffffffffc0200d7a:	b3cff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(p0, 5);
ffffffffc0200d7e:	8526                	mv	a0,s1
ffffffffc0200d80:	4595                	li	a1,5
ffffffffc0200d82:	384000ef          	jal	ra,ffffffffc0201106 <free_pages>
    cprintf("释放p0后，总空闲块数目为：%d\n", nr_free); // 变成了8
ffffffffc0200d86:	0f89a583          	lw	a1,248(s3)
ffffffffc0200d8a:	00001517          	auipc	a0,0x1
ffffffffc0200d8e:	63650513          	addi	a0,a0,1590 # ffffffffc02023c0 <commands+0x850>
ffffffffc0200d92:	b24ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200d96:	db9ff0ef          	jal	ra,ffffffffc0200b4e <show_buddy_array.constprop.4>
    cprintf("释放p1中。。。。。。");
ffffffffc0200d9a:	00001517          	auipc	a0,0x1
ffffffffc0200d9e:	65650513          	addi	a0,a0,1622 # ffffffffc02023f0 <commands+0x880>
ffffffffc0200da2:	b14ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(p1, 5);
ffffffffc0200da6:	8522                	mv	a0,s0
ffffffffc0200da8:	4595                	li	a1,5
ffffffffc0200daa:	35c000ef          	jal	ra,ffffffffc0201106 <free_pages>
    cprintf("释放p1后，总空闲块数目为：%d\n", nr_free); // 变成了16
ffffffffc0200dae:	0f89a583          	lw	a1,248(s3)
ffffffffc0200db2:	00001517          	auipc	a0,0x1
ffffffffc0200db6:	65e50513          	addi	a0,a0,1630 # ffffffffc0202410 <commands+0x8a0>
ffffffffc0200dba:	afcff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200dbe:	d91ff0ef          	jal	ra,ffffffffc0200b4e <show_buddy_array.constprop.4>
    cprintf("释放p2中。。。。。。");
ffffffffc0200dc2:	00001517          	auipc	a0,0x1
ffffffffc0200dc6:	67e50513          	addi	a0,a0,1662 # ffffffffc0202440 <commands+0x8d0>
ffffffffc0200dca:	aecff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(p2, 5);
ffffffffc0200dce:	854a                	mv	a0,s2
ffffffffc0200dd0:	4595                	li	a1,5
ffffffffc0200dd2:	334000ef          	jal	ra,ffffffffc0201106 <free_pages>
    cprintf("释放p2后，总空闲块数目为：%d\n", nr_free); // 变成了24
ffffffffc0200dd6:	0f89a583          	lw	a1,248(s3)
ffffffffc0200dda:	00001517          	auipc	a0,0x1
ffffffffc0200dde:	68650513          	addi	a0,a0,1670 # ffffffffc0202460 <commands+0x8f0>
ffffffffc0200de2:	ad4ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200de6:	d69ff0ef          	jal	ra,ffffffffc0200b4e <show_buddy_array.constprop.4>
    nr_free = 16384;
ffffffffc0200dea:	6791                	lui	a5,0x4
    struct Page *p3 = alloc_pages(16384);
ffffffffc0200dec:	6511                	lui	a0,0x4
    nr_free = 16384;
ffffffffc0200dee:	00005717          	auipc	a4,0x5
ffffffffc0200df2:	74f72923          	sw	a5,1874(a4) # ffffffffc0206540 <buddy_s+0xf8>
    struct Page *p3 = alloc_pages(16384);
ffffffffc0200df6:	2cc000ef          	jal	ra,ffffffffc02010c2 <alloc_pages>
ffffffffc0200dfa:	842a                	mv	s0,a0
    cprintf("分配p3之后(16384页)\n");
ffffffffc0200dfc:	00001517          	auipc	a0,0x1
ffffffffc0200e00:	69450513          	addi	a0,a0,1684 # ffffffffc0202490 <commands+0x920>
ffffffffc0200e04:	ab2ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e08:	d47ff0ef          	jal	ra,ffffffffc0200b4e <show_buddy_array.constprop.4>
    free_pages(p3, 16384);
ffffffffc0200e0c:	8522                	mv	a0,s0
ffffffffc0200e0e:	6591                	lui	a1,0x4
ffffffffc0200e10:	2f6000ef          	jal	ra,ffffffffc0201106 <free_pages>
    //     struct Page *p = le2page(le, page_link);
    //     count--, total -= p->property;
    // }
    // assert(count == 0);
    // assert(total == 0);
}
ffffffffc0200e14:	7402                	ld	s0,32(sp)
ffffffffc0200e16:	70a2                	ld	ra,40(sp)
ffffffffc0200e18:	64e2                	ld	s1,24(sp)
ffffffffc0200e1a:	6942                	ld	s2,16(sp)
ffffffffc0200e1c:	69a2                	ld	s3,8(sp)
ffffffffc0200e1e:	6145                	addi	sp,sp,48
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e20:	d2fff06f          	j	ffffffffc0200b4e <show_buddy_array.constprop.4>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e24:	00001697          	auipc	a3,0x1
ffffffffc0200e28:	49c68693          	addi	a3,a3,1180 # ffffffffc02022c0 <commands+0x750>
ffffffffc0200e2c:	00001617          	auipc	a2,0x1
ffffffffc0200e30:	6d460613          	addi	a2,a2,1748 # ffffffffc0202500 <commands+0x990>
ffffffffc0200e34:	13200593          	li	a1,306
ffffffffc0200e38:	00001517          	auipc	a0,0x1
ffffffffc0200e3c:	6e050513          	addi	a0,a0,1760 # ffffffffc0202518 <commands+0x9a8>
ffffffffc0200e40:	d6cff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e44:	00001697          	auipc	a3,0x1
ffffffffc0200e48:	4a468693          	addi	a3,a3,1188 # ffffffffc02022e8 <commands+0x778>
ffffffffc0200e4c:	00001617          	auipc	a2,0x1
ffffffffc0200e50:	6b460613          	addi	a2,a2,1716 # ffffffffc0202500 <commands+0x990>
ffffffffc0200e54:	13300593          	li	a1,307
ffffffffc0200e58:	00001517          	auipc	a0,0x1
ffffffffc0200e5c:	6c050513          	addi	a0,a0,1728 # ffffffffc0202518 <commands+0x9a8>
ffffffffc0200e60:	d4cff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e64:	00001697          	auipc	a3,0x1
ffffffffc0200e68:	4c468693          	addi	a3,a3,1220 # ffffffffc0202328 <commands+0x7b8>
ffffffffc0200e6c:	00001617          	auipc	a2,0x1
ffffffffc0200e70:	69460613          	addi	a2,a2,1684 # ffffffffc0202500 <commands+0x990>
ffffffffc0200e74:	13500593          	li	a1,309
ffffffffc0200e78:	00001517          	auipc	a0,0x1
ffffffffc0200e7c:	6a050513          	addi	a0,a0,1696 # ffffffffc0202518 <commands+0x9a8>
ffffffffc0200e80:	d2cff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e84:	00001697          	auipc	a3,0x1
ffffffffc0200e88:	4c468693          	addi	a3,a3,1220 # ffffffffc0202348 <commands+0x7d8>
ffffffffc0200e8c:	00001617          	auipc	a2,0x1
ffffffffc0200e90:	67460613          	addi	a2,a2,1652 # ffffffffc0202500 <commands+0x990>
ffffffffc0200e94:	13600593          	li	a1,310
ffffffffc0200e98:	00001517          	auipc	a0,0x1
ffffffffc0200e9c:	68050513          	addi	a0,a0,1664 # ffffffffc0202518 <commands+0x9a8>
ffffffffc0200ea0:	d0cff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ea4:	00001697          	auipc	a3,0x1
ffffffffc0200ea8:	4c468693          	addi	a3,a3,1220 # ffffffffc0202368 <commands+0x7f8>
ffffffffc0200eac:	00001617          	auipc	a2,0x1
ffffffffc0200eb0:	65460613          	addi	a2,a2,1620 # ffffffffc0202500 <commands+0x990>
ffffffffc0200eb4:	13700593          	li	a1,311
ffffffffc0200eb8:	00001517          	auipc	a0,0x1
ffffffffc0200ebc:	66050513          	addi	a0,a0,1632 # ffffffffc0202518 <commands+0x9a8>
ffffffffc0200ec0:	cecff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ec4:	00001697          	auipc	a3,0x1
ffffffffc0200ec8:	4c468693          	addi	a3,a3,1220 # ffffffffc0202388 <commands+0x818>
ffffffffc0200ecc:	00001617          	auipc	a2,0x1
ffffffffc0200ed0:	63460613          	addi	a2,a2,1588 # ffffffffc0202500 <commands+0x990>
ffffffffc0200ed4:	13d00593          	li	a1,317
ffffffffc0200ed8:	00001517          	auipc	a0,0x1
ffffffffc0200edc:	64050513          	addi	a0,a0,1600 # ffffffffc0202518 <commands+0x9a8>
ffffffffc0200ee0:	cccff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200ee4 <buddy_system_free_pages>:
{
ffffffffc0200ee4:	7179                	addi	sp,sp,-48
ffffffffc0200ee6:	f406                	sd	ra,40(sp)
ffffffffc0200ee8:	f022                	sd	s0,32(sp)
ffffffffc0200eea:	ec26                	sd	s1,24(sp)
ffffffffc0200eec:	e84a                	sd	s2,16(sp)
ffffffffc0200eee:	e44e                	sd	s3,8(sp)
    assert(n > 0);
ffffffffc0200ef0:	16058b63          	beqz	a1,ffffffffc0201066 <buddy_system_free_pages+0x182>
    unsigned int pnum = 1 << (base->property); // 块中页的数目
ffffffffc0200ef4:	4918                	lw	a4,16(a0)
    if (n & (n - 1))
ffffffffc0200ef6:	fff58793          	addi	a5,a1,-1 # 3fff <BASE_ADDRESS-0xffffffffc01fc001>
    unsigned int pnum = 1 << (base->property); // 块中页的数目
ffffffffc0200efa:	4485                	li	s1,1
ffffffffc0200efc:	00e494bb          	sllw	s1,s1,a4
    if (n & (n - 1))
ffffffffc0200f00:	8fed                	and	a5,a5,a1
ffffffffc0200f02:	842a                	mv	s0,a0
    unsigned int pnum = 1 << (base->property); // 块中页的数目
ffffffffc0200f04:	0004861b          	sext.w	a2,s1
    if (n & (n - 1))
ffffffffc0200f08:	14079963          	bnez	a5,ffffffffc020105a <buddy_system_free_pages+0x176>
    assert(ROUNDUP2(n) == pnum);
ffffffffc0200f0c:	02049793          	slli	a5,s1,0x20
ffffffffc0200f10:	9381                	srli	a5,a5,0x20
ffffffffc0200f12:	16b79a63          	bne	a5,a1,ffffffffc0201086 <buddy_system_free_pages+0x1a2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } // page-pages是page的偏移量，加上nbase就是ppn（物理页编号）
ffffffffc0200f16:	00005797          	auipc	a5,0x5
ffffffffc0200f1a:	64a78793          	addi	a5,a5,1610 # ffffffffc0206560 <pages>
ffffffffc0200f1e:	639c                	ld	a5,0(a5)
ffffffffc0200f20:	00001717          	auipc	a4,0x1
ffffffffc0200f24:	2d070713          	addi	a4,a4,720 # ffffffffc02021f0 <commands+0x680>
ffffffffc0200f28:	630c                	ld	a1,0(a4)
ffffffffc0200f2a:	40f407b3          	sub	a5,s0,a5
ffffffffc0200f2e:	878d                	srai	a5,a5,0x3
ffffffffc0200f30:	02b787b3          	mul	a5,a5,a1
ffffffffc0200f34:	00002717          	auipc	a4,0x2
ffffffffc0200f38:	cbc70713          	addi	a4,a4,-836 # ffffffffc0202bf0 <nbase>
    cprintf("BS算法将释放第NO.%d页开始的共%d页\n", page2ppn(base), pnum);
ffffffffc0200f3c:	630c                	ld	a1,0(a4)
ffffffffc0200f3e:	00001517          	auipc	a0,0x1
ffffffffc0200f42:	58a50513          	addi	a0,a0,1418 # ffffffffc02024c8 <commands+0x958>
ffffffffc0200f46:	95be                	add	a1,a1,a5
ffffffffc0200f48:	96eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 将当前块先插入对应链表中
ffffffffc0200f4c:	4810                	lw	a2,16(s0)
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc0200f4e:	4785                	li	a5,1
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc0200f50:	3fdf1eb7          	lui	t4,0x3fdf1
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc0200f54:	00c796bb          	sllw	a3,a5,a2
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc0200f58:	00269793          	slli	a5,a3,0x2
    __list_add(elm, listelm, listelm->next);
ffffffffc0200f5c:	02061713          	slli	a4,a2,0x20
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc0200f60:	ce8e8e93          	addi	t4,t4,-792 # 3fdf0ce8 <BASE_ADDRESS-0xffffffff8040f318>
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc0200f64:	97b6                	add	a5,a5,a3
ffffffffc0200f66:	9301                	srli	a4,a4,0x20
ffffffffc0200f68:	00005517          	auipc	a0,0x5
ffffffffc0200f6c:	4e050513          	addi	a0,a0,1248 # ffffffffc0206448 <buddy_s>
ffffffffc0200f70:	0712                	slli	a4,a4,0x4
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc0200f72:	01d406b3          	add	a3,s0,t4
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc0200f76:	078e                	slli	a5,a5,0x3
ffffffffc0200f78:	00e50833          	add	a6,a0,a4
    size_t buddy_relative_addr = (size_t)relative_block_addr ^ sizeOfPage;      // 异或得到伙伴块的相对地址
ffffffffc0200f7c:	8fb5                	xor	a5,a5,a3
ffffffffc0200f7e:	01083583          	ld	a1,16(a6)
    struct Page *buddy_page = (struct Page *)(buddy_relative_addr + mem_begin); // 返回伙伴块指针
ffffffffc0200f82:	41d787b3          	sub	a5,a5,t4
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200f86:	6794                	ld	a3,8(a5)
    list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 将当前块先插入对应链表中
ffffffffc0200f88:	01840e13          	addi	t3,s0,24
    prev->next = next->prev = elm;
ffffffffc0200f8c:	01c5b023          	sd	t3,0(a1)
ffffffffc0200f90:	0721                	addi	a4,a4,8
ffffffffc0200f92:	01c83823          	sd	t3,16(a6)
ffffffffc0200f96:	972a                	add	a4,a4,a0
ffffffffc0200f98:	8285                	srli	a3,a3,0x1
    elm->prev = prev;
ffffffffc0200f9a:	ec18                	sd	a4,24(s0)
    elm->next = next;
ffffffffc0200f9c:	f00c                	sd	a1,32(s0)
    while (!PageProperty(buddy) && left_block->property < max_order)
ffffffffc0200f9e:	0016f713          	andi	a4,a3,1
ffffffffc0200fa2:	00840f13          	addi	t5,s0,8
ffffffffc0200fa6:	eb49                	bnez	a4,ffffffffc0201038 <buddy_system_free_pages+0x154>
ffffffffc0200fa8:	4118                	lw	a4,0(a0)
ffffffffc0200faa:	08e67763          	bleu	a4,a2,ffffffffc0201038 <buddy_system_free_pages+0x154>
            left_block->property = -1;     // 将左块幂次置为无效
ffffffffc0200fae:	53fd                	li	t2,-1
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200fb0:	52f5                	li	t0,-3
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc0200fb2:	4f85                	li	t6,1
        if (left_block > buddy)
ffffffffc0200fb4:	0087fd63          	bleu	s0,a5,ffffffffc0200fce <buddy_system_free_pages+0xea>
            left_block->property = -1;     // 将左块幂次置为无效
ffffffffc0200fb8:	00742823          	sw	t2,16(s0)
ffffffffc0200fbc:	605f302f          	amoand.d	zero,t0,(t5)
ffffffffc0200fc0:	8722                	mv	a4,s0
ffffffffc0200fc2:	00878f13          	addi	t5,a5,8
ffffffffc0200fc6:	843e                	mv	s0,a5
ffffffffc0200fc8:	01878e13          	addi	t3,a5,24
ffffffffc0200fcc:	87ba                	mv	a5,a4
    __list_del(listelm->prev, listelm->next);
ffffffffc0200fce:	6c14                	ld	a3,24(s0)
ffffffffc0200fd0:	7018                	ld	a4,32(s0)
        left_block->property += 1; // 左快头页设置幂次加一
ffffffffc0200fd2:	4810                	lw	a2,16(s0)
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc0200fd4:	01d405b3          	add	a1,s0,t4
    prev->next = next;
ffffffffc0200fd8:	e698                	sd	a4,8(a3)
        left_block->property += 1; // 左快头页设置幂次加一
ffffffffc0200fda:	2605                	addiw	a2,a2,1
    next->prev = prev;
ffffffffc0200fdc:	e314                	sd	a3,0(a4)
ffffffffc0200fde:	0006091b          	sext.w	s2,a2
    __list_del(listelm->prev, listelm->next);
ffffffffc0200fe2:	0187b983          	ld	s3,24(a5)
ffffffffc0200fe6:	0207b303          	ld	t1,32(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200fea:	02061713          	slli	a4,a2,0x20
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc0200fee:	012f97bb          	sllw	a5,t6,s2
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc0200ff2:	00279693          	slli	a3,a5,0x2
ffffffffc0200ff6:	9301                	srli	a4,a4,0x20
ffffffffc0200ff8:	0712                	slli	a4,a4,0x4
ffffffffc0200ffa:	96be                	add	a3,a3,a5
    prev->next = next;
ffffffffc0200ffc:	0069b423          	sd	t1,8(s3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201000:	00e508b3          	add	a7,a0,a4
ffffffffc0201004:	068e                	slli	a3,a3,0x3
ffffffffc0201006:	0108b803          	ld	a6,16(a7)
    size_t buddy_relative_addr = (size_t)relative_block_addr ^ sizeOfPage;      // 异或得到伙伴块的相对地址
ffffffffc020100a:	00b6c7b3          	xor	a5,a3,a1
    next->prev = prev;
ffffffffc020100e:	01333023          	sd	s3,0(t1)
    struct Page *buddy_page = (struct Page *)(buddy_relative_addr + mem_begin); // 返回伙伴块指针
ffffffffc0201012:	41d787b3          	sub	a5,a5,t4
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201016:	6794                	ld	a3,8(a5)
        left_block->property += 1; // 左快头页设置幂次加一
ffffffffc0201018:	c810                	sw	a2,16(s0)
    prev->next = next->prev = elm;
ffffffffc020101a:	01c83023          	sd	t3,0(a6)
        list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 头插入相应链表
ffffffffc020101e:	0721                	addi	a4,a4,8
ffffffffc0201020:	01c8b823          	sd	t3,16(a7)
ffffffffc0201024:	972a                	add	a4,a4,a0
    elm->prev = prev;
ffffffffc0201026:	ec18                	sd	a4,24(s0)
    elm->next = next;
ffffffffc0201028:	03043023          	sd	a6,32(s0)
    while (!PageProperty(buddy) && left_block->property < max_order)
ffffffffc020102c:	0026f713          	andi	a4,a3,2
ffffffffc0201030:	e701                	bnez	a4,ffffffffc0201038 <buddy_system_free_pages+0x154>
ffffffffc0201032:	4118                	lw	a4,0(a0)
ffffffffc0201034:	f8e960e3          	bltu	s2,a4,ffffffffc0200fb4 <buddy_system_free_pages+0xd0>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201038:	57f5                	li	a5,-3
ffffffffc020103a:	60ff302f          	amoand.d	zero,a5,(t5)
    nr_free += pnum;
ffffffffc020103e:	0f852783          	lw	a5,248(a0)
}
ffffffffc0201042:	70a2                	ld	ra,40(sp)
ffffffffc0201044:	7402                	ld	s0,32(sp)
    nr_free += pnum;
ffffffffc0201046:	9cbd                	addw	s1,s1,a5
ffffffffc0201048:	00005797          	auipc	a5,0x5
ffffffffc020104c:	4e97ac23          	sw	s1,1272(a5) # ffffffffc0206540 <buddy_s+0xf8>
}
ffffffffc0201050:	6942                	ld	s2,16(sp)
ffffffffc0201052:	64e2                	ld	s1,24(sp)
ffffffffc0201054:	69a2                	ld	s3,8(sp)
ffffffffc0201056:	6145                	addi	sp,sp,48
ffffffffc0201058:	8082                	ret
    size_t res = 1;
ffffffffc020105a:	4785                	li	a5,1
            n = n >> 1;
ffffffffc020105c:	8185                	srli	a1,a1,0x1
            res = res << 1;
ffffffffc020105e:	0786                	slli	a5,a5,0x1
        while (n)
ffffffffc0201060:	fdf5                	bnez	a1,ffffffffc020105c <buddy_system_free_pages+0x178>
            res = res << 1;
ffffffffc0201062:	85be                	mv	a1,a5
ffffffffc0201064:	b565                	j	ffffffffc0200f0c <buddy_system_free_pages+0x28>
    assert(n > 0);
ffffffffc0201066:	00001697          	auipc	a3,0x1
ffffffffc020106a:	49268693          	addi	a3,a3,1170 # ffffffffc02024f8 <commands+0x988>
ffffffffc020106e:	00001617          	auipc	a2,0x1
ffffffffc0201072:	49260613          	addi	a2,a2,1170 # ffffffffc0202500 <commands+0x990>
ffffffffc0201076:	0e800593          	li	a1,232
ffffffffc020107a:	00001517          	auipc	a0,0x1
ffffffffc020107e:	49e50513          	addi	a0,a0,1182 # ffffffffc0202518 <commands+0x9a8>
ffffffffc0201082:	b2aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(ROUNDUP2(n) == pnum);
ffffffffc0201086:	00001697          	auipc	a3,0x1
ffffffffc020108a:	42a68693          	addi	a3,a3,1066 # ffffffffc02024b0 <commands+0x940>
ffffffffc020108e:	00001617          	auipc	a2,0x1
ffffffffc0201092:	47260613          	addi	a2,a2,1138 # ffffffffc0202500 <commands+0x990>
ffffffffc0201096:	0ea00593          	li	a1,234
ffffffffc020109a:	00001517          	auipc	a0,0x1
ffffffffc020109e:	47e50513          	addi	a0,a0,1150 # ffffffffc0202518 <commands+0x9a8>
ffffffffc02010a2:	b0aff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02010a6 <pa2page.part.0>:
static inline int page_ref_dec(struct Page *page)
{
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc02010a6:	1141                	addi	sp,sp,-16
{
    if (PPN(pa) >= npage)
    {
        panic("pa2page called with invalid pa");
ffffffffc02010a8:	00001617          	auipc	a2,0x1
ffffffffc02010ac:	61060613          	addi	a2,a2,1552 # ffffffffc02026b8 <buddy_system_pmm_manager+0x170>
ffffffffc02010b0:	07200593          	li	a1,114
ffffffffc02010b4:	00001517          	auipc	a0,0x1
ffffffffc02010b8:	62450513          	addi	a0,a0,1572 # ffffffffc02026d8 <buddy_system_pmm_manager+0x190>
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc02010bc:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc02010be:	aeeff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02010c2 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02010c2:	100027f3          	csrr	a5,sstatus
ffffffffc02010c6:	8b89                	andi	a5,a5,2
ffffffffc02010c8:	eb89                	bnez	a5,ffffffffc02010da <alloc_pages+0x18>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02010ca:	00005797          	auipc	a5,0x5
ffffffffc02010ce:	48678793          	addi	a5,a5,1158 # ffffffffc0206550 <pmm_manager>
ffffffffc02010d2:	639c                	ld	a5,0(a5)
ffffffffc02010d4:	0187b303          	ld	t1,24(a5)
ffffffffc02010d8:	8302                	jr	t1
{
ffffffffc02010da:	1141                	addi	sp,sp,-16
ffffffffc02010dc:	e406                	sd	ra,8(sp)
ffffffffc02010de:	e022                	sd	s0,0(sp)
ffffffffc02010e0:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02010e2:	b82ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02010e6:	00005797          	auipc	a5,0x5
ffffffffc02010ea:	46a78793          	addi	a5,a5,1130 # ffffffffc0206550 <pmm_manager>
ffffffffc02010ee:	639c                	ld	a5,0(a5)
ffffffffc02010f0:	8522                	mv	a0,s0
ffffffffc02010f2:	6f9c                	ld	a5,24(a5)
ffffffffc02010f4:	9782                	jalr	a5
ffffffffc02010f6:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02010f8:	b66ff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02010fc:	8522                	mv	a0,s0
ffffffffc02010fe:	60a2                	ld	ra,8(sp)
ffffffffc0201100:	6402                	ld	s0,0(sp)
ffffffffc0201102:	0141                	addi	sp,sp,16
ffffffffc0201104:	8082                	ret

ffffffffc0201106 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201106:	100027f3          	csrr	a5,sstatus
ffffffffc020110a:	8b89                	andi	a5,a5,2
ffffffffc020110c:	eb89                	bnez	a5,ffffffffc020111e <free_pages+0x18>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020110e:	00005797          	auipc	a5,0x5
ffffffffc0201112:	44278793          	addi	a5,a5,1090 # ffffffffc0206550 <pmm_manager>
ffffffffc0201116:	639c                	ld	a5,0(a5)
ffffffffc0201118:	0207b303          	ld	t1,32(a5)
ffffffffc020111c:	8302                	jr	t1
{
ffffffffc020111e:	1101                	addi	sp,sp,-32
ffffffffc0201120:	ec06                	sd	ra,24(sp)
ffffffffc0201122:	e822                	sd	s0,16(sp)
ffffffffc0201124:	e426                	sd	s1,8(sp)
ffffffffc0201126:	842a                	mv	s0,a0
ffffffffc0201128:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020112a:	b3aff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020112e:	00005797          	auipc	a5,0x5
ffffffffc0201132:	42278793          	addi	a5,a5,1058 # ffffffffc0206550 <pmm_manager>
ffffffffc0201136:	639c                	ld	a5,0(a5)
ffffffffc0201138:	85a6                	mv	a1,s1
ffffffffc020113a:	8522                	mv	a0,s0
ffffffffc020113c:	739c                	ld	a5,32(a5)
ffffffffc020113e:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201140:	6442                	ld	s0,16(sp)
ffffffffc0201142:	60e2                	ld	ra,24(sp)
ffffffffc0201144:	64a2                	ld	s1,8(sp)
ffffffffc0201146:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201148:	b16ff06f          	j	ffffffffc020045e <intr_enable>

ffffffffc020114c <pmm_init>:
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc020114c:	00001797          	auipc	a5,0x1
ffffffffc0201150:	3fc78793          	addi	a5,a5,1020 # ffffffffc0202548 <buddy_system_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201154:	638c                	ld	a1,0(a5)
    // 0x8000-0x7cb9=0x0347个不可用，这些页存的是结构体page的数据
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void)
{
ffffffffc0201156:	715d                	addi	sp,sp,-80
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201158:	00001517          	auipc	a0,0x1
ffffffffc020115c:	59050513          	addi	a0,a0,1424 # ffffffffc02026e8 <buddy_system_pmm_manager+0x1a0>
{
ffffffffc0201160:	e486                	sd	ra,72(sp)
ffffffffc0201162:	e0a2                	sd	s0,64(sp)
ffffffffc0201164:	f052                	sd	s4,32(sp)
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0201166:	00005717          	auipc	a4,0x5
ffffffffc020116a:	3ef73523          	sd	a5,1002(a4) # ffffffffc0206550 <pmm_manager>
{
ffffffffc020116e:	fc26                	sd	s1,56(sp)
ffffffffc0201170:	f84a                	sd	s2,48(sp)
ffffffffc0201172:	f44e                	sd	s3,40(sp)
ffffffffc0201174:	ec56                	sd	s5,24(sp)
ffffffffc0201176:	e85a                	sd	s6,16(sp)
ffffffffc0201178:	e45e                	sd	s7,8(sp)
ffffffffc020117a:	e062                	sd	s8,0(sp)
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc020117c:	00005a17          	auipc	s4,0x5
ffffffffc0201180:	3d4a0a13          	addi	s4,s4,980 # ffffffffc0206550 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201184:	f33fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pmm_manager->init();
ffffffffc0201188:	000a3783          	ld	a5,0(s4)
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020118c:	4445                	li	s0,17
ffffffffc020118e:	046e                	slli	s0,s0,0x1b
    pmm_manager->init();
ffffffffc0201190:	679c                	ld	a5,8(a5)
ffffffffc0201192:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移:
ffffffffc0201194:	57f5                	li	a5,-3
ffffffffc0201196:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201198:	00001517          	auipc	a0,0x1
ffffffffc020119c:	56850513          	addi	a0,a0,1384 # ffffffffc0202700 <buddy_system_pmm_manager+0x1b8>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移:
ffffffffc02011a0:	00005717          	auipc	a4,0x5
ffffffffc02011a4:	3af73c23          	sd	a5,952(a4) # ffffffffc0206558 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc02011a8:	f0ffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02011ac:	40100613          	li	a2,1025
ffffffffc02011b0:	fff40693          	addi	a3,s0,-1
ffffffffc02011b4:	0656                	slli	a2,a2,0x15
ffffffffc02011b6:	07e005b7          	lui	a1,0x7e00
ffffffffc02011ba:	00001517          	auipc	a0,0x1
ffffffffc02011be:	55e50513          	addi	a0,a0,1374 # ffffffffc0202718 <buddy_system_pmm_manager+0x1d0>
ffffffffc02011c2:	ef5fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("maxpa: 0x%016lx.\n", maxpa); // test point
ffffffffc02011c6:	85a2                	mv	a1,s0
ffffffffc02011c8:	00001517          	auipc	a0,0x1
ffffffffc02011cc:	58050513          	addi	a0,a0,1408 # ffffffffc0202748 <buddy_system_pmm_manager+0x200>
ffffffffc02011d0:	ee7fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02011d4:	000887b7          	lui	a5,0x88
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc02011d8:	000885b7          	lui	a1,0x88
ffffffffc02011dc:	00001517          	auipc	a0,0x1
ffffffffc02011e0:	58450513          	addi	a0,a0,1412 # ffffffffc0202760 <buddy_system_pmm_manager+0x218>
    npage = maxpa / PGSIZE;
ffffffffc02011e4:	00005717          	auipc	a4,0x5
ffffffffc02011e8:	24f73223          	sd	a5,580(a4) # ffffffffc0206428 <npage>
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc02011ec:	ecbfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("nbase: 0x%016lx.\n", nbase); // test point，为0x8000_0
ffffffffc02011f0:	000805b7          	lui	a1,0x80
ffffffffc02011f4:	00001517          	auipc	a0,0x1
ffffffffc02011f8:	58450513          	addi	a0,a0,1412 # ffffffffc0202778 <buddy_system_pmm_manager+0x230>
ffffffffc02011fc:	ebbfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201200:	00006697          	auipc	a3,0x6
ffffffffc0201204:	36768693          	addi	a3,a3,871 # ffffffffc0207567 <end+0xfff>
ffffffffc0201208:	75fd                	lui	a1,0xfffff
ffffffffc020120a:	8eed                	and	a3,a3,a1
ffffffffc020120c:	00005797          	auipc	a5,0x5
ffffffffc0201210:	34d7ba23          	sd	a3,852(a5) # ffffffffc0206560 <pages>
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc0201214:	c02007b7          	lui	a5,0xc0200
ffffffffc0201218:	24f6ec63          	bltu	a3,a5,ffffffffc0201470 <pmm_init+0x324>
ffffffffc020121c:	00005997          	auipc	s3,0x5
ffffffffc0201220:	33c98993          	addi	s3,s3,828 # ffffffffc0206558 <va_pa_offset>
ffffffffc0201224:	0009b583          	ld	a1,0(s3)
ffffffffc0201228:	00001517          	auipc	a0,0x1
ffffffffc020122c:	5a050513          	addi	a0,a0,1440 # ffffffffc02027c8 <buddy_system_pmm_manager+0x280>
ffffffffc0201230:	00005917          	auipc	s2,0x5
ffffffffc0201234:	1f890913          	addi	s2,s2,504 # ffffffffc0206428 <npage>
ffffffffc0201238:	40b685b3          	sub	a1,a3,a1
ffffffffc020123c:	e7bfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201240:	00093703          	ld	a4,0(s2)
ffffffffc0201244:	000807b7          	lui	a5,0x80
ffffffffc0201248:	00005a97          	auipc	s5,0x5
ffffffffc020124c:	318a8a93          	addi	s5,s5,792 # ffffffffc0206560 <pages>
ffffffffc0201250:	02f70963          	beq	a4,a5,ffffffffc0201282 <pmm_init+0x136>
ffffffffc0201254:	4681                	li	a3,0
ffffffffc0201256:	4701                	li	a4,0
ffffffffc0201258:	00005a97          	auipc	s5,0x5
ffffffffc020125c:	308a8a93          	addi	s5,s5,776 # ffffffffc0206560 <pages>
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201260:	4585                	li	a1,1
ffffffffc0201262:	fff80637          	lui	a2,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201266:	000ab783          	ld	a5,0(s5)
ffffffffc020126a:	97b6                	add	a5,a5,a3
ffffffffc020126c:	07a1                	addi	a5,a5,8
ffffffffc020126e:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201272:	00093783          	ld	a5,0(s2)
ffffffffc0201276:	0705                	addi	a4,a4,1
ffffffffc0201278:	02868693          	addi	a3,a3,40
ffffffffc020127c:	97b2                	add	a5,a5,a2
ffffffffc020127e:	fef764e3          	bltu	a4,a5,ffffffffc0201266 <pmm_init+0x11a>
ffffffffc0201282:	4481                	li	s1,0
    for (size_t i = 0; i < 5; i++)
ffffffffc0201284:	4401                	li	s0,0
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201286:	c0200b37          	lui	s6,0xc0200
ffffffffc020128a:	00001c17          	auipc	s8,0x1
ffffffffc020128e:	566c0c13          	addi	s8,s8,1382 # ffffffffc02027f0 <buddy_system_pmm_manager+0x2a8>
    for (size_t i = 0; i < 5; i++)
ffffffffc0201292:	4b95                	li	s7,5
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201294:	000ab683          	ld	a3,0(s5)
ffffffffc0201298:	96a6                	add	a3,a3,s1
ffffffffc020129a:	1966e563          	bltu	a3,s6,ffffffffc0201424 <pmm_init+0x2d8>
ffffffffc020129e:	0009b603          	ld	a2,0(s3)
ffffffffc02012a2:	85a2                	mv	a1,s0
ffffffffc02012a4:	8562                	mv	a0,s8
ffffffffc02012a6:	40c68633          	sub	a2,a3,a2
    for (size_t i = 0; i < 5; i++)
ffffffffc02012aa:	0405                	addi	s0,s0,1
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc02012ac:	e0bfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc02012b0:	02848493          	addi	s1,s1,40
    for (size_t i = 0; i < 5; i++)
ffffffffc02012b4:	ff7410e3          	bne	s0,s7,ffffffffc0201294 <pmm_init+0x148>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc02012b8:	00093783          	ld	a5,0(s2)
ffffffffc02012bc:	000ab403          	ld	s0,0(s5)
ffffffffc02012c0:	00279693          	slli	a3,a5,0x2
ffffffffc02012c4:	96be                	add	a3,a3,a5
ffffffffc02012c6:	068e                	slli	a3,a3,0x3
ffffffffc02012c8:	9436                	add	s0,s0,a3
ffffffffc02012ca:	fec006b7          	lui	a3,0xfec00
ffffffffc02012ce:	9436                	add	s0,s0,a3
ffffffffc02012d0:	1b646c63          	bltu	s0,s6,ffffffffc0201488 <pmm_init+0x33c>
ffffffffc02012d4:	0009b683          	ld	a3,0(s3)
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc02012d8:	02800593          	li	a1,40
ffffffffc02012dc:	00001517          	auipc	a0,0x1
ffffffffc02012e0:	53c50513          	addi	a0,a0,1340 # ffffffffc0202818 <buddy_system_pmm_manager+0x2d0>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02012e4:	6485                	lui	s1,0x1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc02012e6:	8c15                	sub	s0,s0,a3
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02012e8:	14fd                	addi	s1,s1,-1
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc02012ea:	dcdfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc02012ee:	85a2                	mv	a1,s0
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02012f0:	94a2                	add	s1,s1,s0
ffffffffc02012f2:	7b7d                	lui	s6,0xfffff
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc02012f4:	00001517          	auipc	a0,0x1
ffffffffc02012f8:	54450513          	addi	a0,a0,1348 # ffffffffc0202838 <buddy_system_pmm_manager+0x2f0>
ffffffffc02012fc:	dbbfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0201300:	0164fb33          	and	s6,s1,s6
    cprintf("mem_begin: 0x%016lx.\n", mem_begin); // test point
ffffffffc0201304:	85da                	mv	a1,s6
ffffffffc0201306:	00001517          	auipc	a0,0x1
ffffffffc020130a:	54a50513          	addi	a0,a0,1354 # ffffffffc0202850 <buddy_system_pmm_manager+0x308>
ffffffffc020130e:	da9fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc0201312:	4bc5                	li	s7,17
ffffffffc0201314:	01bb9593          	slli	a1,s7,0x1b
ffffffffc0201318:	00001517          	auipc	a0,0x1
ffffffffc020131c:	55050513          	addi	a0,a0,1360 # ffffffffc0202868 <buddy_system_pmm_manager+0x320>
    if (freemem < mem_end)
ffffffffc0201320:	0bee                	slli	s7,s7,0x1b
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc0201322:	d95fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (freemem < mem_end)
ffffffffc0201326:	0d746763          	bltu	s0,s7,ffffffffc02013f4 <pmm_init+0x2a8>
    if (PPN(pa) >= npage)
ffffffffc020132a:	00093783          	ld	a5,0(s2)
ffffffffc020132e:	00cb5493          	srli	s1,s6,0xc
ffffffffc0201332:	10f4f563          	bleu	a5,s1,ffffffffc020143c <pmm_init+0x2f0>
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201336:	fff80437          	lui	s0,0xfff80
ffffffffc020133a:	008486b3          	add	a3,s1,s0
ffffffffc020133e:	00269413          	slli	s0,a3,0x2
ffffffffc0201342:	000ab583          	ld	a1,0(s5)
ffffffffc0201346:	9436                	add	s0,s0,a3
ffffffffc0201348:	040e                	slli	s0,s0,0x3
    cprintf("mem_begin对应的页结构记录(结构体page)虚拟地址: 0x%016lx.\n", pa2page(mem_begin));        // test point
ffffffffc020134a:	95a2                	add	a1,a1,s0
ffffffffc020134c:	00001517          	auipc	a0,0x1
ffffffffc0201350:	53450513          	addi	a0,a0,1332 # ffffffffc0202880 <buddy_system_pmm_manager+0x338>
ffffffffc0201354:	d63fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc0201358:	00093783          	ld	a5,0(s2)
ffffffffc020135c:	0ef4f063          	bleu	a5,s1,ffffffffc020143c <pmm_init+0x2f0>
    return &pages[PPN(pa) - nbase];
ffffffffc0201360:	000ab683          	ld	a3,0(s5)
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc0201364:	c02004b7          	lui	s1,0xc0200
ffffffffc0201368:	96a2                	add	a3,a3,s0
ffffffffc020136a:	0c96eb63          	bltu	a3,s1,ffffffffc0201440 <pmm_init+0x2f4>
ffffffffc020136e:	0009b583          	ld	a1,0(s3)
ffffffffc0201372:	00001517          	auipc	a0,0x1
ffffffffc0201376:	55e50513          	addi	a0,a0,1374 # ffffffffc02028d0 <buddy_system_pmm_manager+0x388>
ffffffffc020137a:	40b685b3          	sub	a1,a3,a1
ffffffffc020137e:	d39fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("可用空闲页的数目: 0x%016lx.\n", (mem_end - mem_begin) / PGSIZE); // test point
ffffffffc0201382:	45c5                	li	a1,17
ffffffffc0201384:	05ee                	slli	a1,a1,0x1b
ffffffffc0201386:	416585b3          	sub	a1,a1,s6
ffffffffc020138a:	81b1                	srli	a1,a1,0xc
ffffffffc020138c:	00001517          	auipc	a0,0x1
ffffffffc0201390:	59450513          	addi	a0,a0,1428 # ffffffffc0202920 <buddy_system_pmm_manager+0x3d8>
ffffffffc0201394:	d23fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201398:	000a3783          	ld	a5,0(s4)
ffffffffc020139c:	7b9c                	ld	a5,48(a5)
ffffffffc020139e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02013a0:	00001517          	auipc	a0,0x1
ffffffffc02013a4:	5a850513          	addi	a0,a0,1448 # ffffffffc0202948 <buddy_system_pmm_manager+0x400>
ffffffffc02013a8:	d0ffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    satp_virtual = (pte_t *)boot_page_table_sv39;
ffffffffc02013ac:	00004697          	auipc	a3,0x4
ffffffffc02013b0:	c5468693          	addi	a3,a3,-940 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02013b4:	00005797          	auipc	a5,0x5
ffffffffc02013b8:	06d7be23          	sd	a3,124(a5) # ffffffffc0206430 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02013bc:	0896ee63          	bltu	a3,s1,ffffffffc0201458 <pmm_init+0x30c>
ffffffffc02013c0:	0009b783          	ld	a5,0(s3)
}
ffffffffc02013c4:	6406                	ld	s0,64(sp)
ffffffffc02013c6:	60a6                	ld	ra,72(sp)
ffffffffc02013c8:	74e2                	ld	s1,56(sp)
ffffffffc02013ca:	7942                	ld	s2,48(sp)
ffffffffc02013cc:	79a2                	ld	s3,40(sp)
ffffffffc02013ce:	7a02                	ld	s4,32(sp)
ffffffffc02013d0:	6ae2                	ld	s5,24(sp)
ffffffffc02013d2:	6b42                	ld	s6,16(sp)
ffffffffc02013d4:	6ba2                	ld	s7,8(sp)
ffffffffc02013d6:	6c02                	ld	s8,0(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02013d8:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc02013da:	8e9d                	sub	a3,a3,a5
ffffffffc02013dc:	00005797          	auipc	a5,0x5
ffffffffc02013e0:	16d7b623          	sd	a3,364(a5) # ffffffffc0206548 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02013e4:	00001517          	auipc	a0,0x1
ffffffffc02013e8:	58450513          	addi	a0,a0,1412 # ffffffffc0202968 <buddy_system_pmm_manager+0x420>
ffffffffc02013ec:	8636                	mv	a2,a3
}
ffffffffc02013ee:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02013f0:	cc7fe06f          	j	ffffffffc02000b6 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc02013f4:	00093783          	ld	a5,0(s2)
ffffffffc02013f8:	80b1                	srli	s1,s1,0xc
ffffffffc02013fa:	04f4f163          	bleu	a5,s1,ffffffffc020143c <pmm_init+0x2f0>
    pmm_manager->init_memmap(base, n);
ffffffffc02013fe:	000a3703          	ld	a4,0(s4)
    return &pages[PPN(pa) - nbase];
ffffffffc0201402:	fff80537          	lui	a0,0xfff80
ffffffffc0201406:	94aa                	add	s1,s1,a0
ffffffffc0201408:	00249793          	slli	a5,s1,0x2
ffffffffc020140c:	000ab503          	ld	a0,0(s5)
ffffffffc0201410:	94be                	add	s1,s1,a5
ffffffffc0201412:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201414:	416b8bb3          	sub	s7,s7,s6
ffffffffc0201418:	048e                	slli	s1,s1,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020141a:	00cbd593          	srli	a1,s7,0xc
ffffffffc020141e:	9526                	add	a0,a0,s1
ffffffffc0201420:	9782                	jalr	a5
ffffffffc0201422:	b721                	j	ffffffffc020132a <pmm_init+0x1de>
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201424:	00001617          	auipc	a2,0x1
ffffffffc0201428:	36c60613          	addi	a2,a2,876 # ffffffffc0202790 <buddy_system_pmm_manager+0x248>
ffffffffc020142c:	08a00593          	li	a1,138
ffffffffc0201430:	00001517          	auipc	a0,0x1
ffffffffc0201434:	38850513          	addi	a0,a0,904 # ffffffffc02027b8 <buddy_system_pmm_manager+0x270>
ffffffffc0201438:	f75fe0ef          	jal	ra,ffffffffc02003ac <__panic>
ffffffffc020143c:	c6bff0ef          	jal	ra,ffffffffc02010a6 <pa2page.part.0>
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc0201440:	00001617          	auipc	a2,0x1
ffffffffc0201444:	35060613          	addi	a2,a2,848 # ffffffffc0202790 <buddy_system_pmm_manager+0x248>
ffffffffc0201448:	09e00593          	li	a1,158
ffffffffc020144c:	00001517          	auipc	a0,0x1
ffffffffc0201450:	36c50513          	addi	a0,a0,876 # ffffffffc02027b8 <buddy_system_pmm_manager+0x270>
ffffffffc0201454:	f59fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201458:	00001617          	auipc	a2,0x1
ffffffffc020145c:	33860613          	addi	a2,a2,824 # ffffffffc0202790 <buddy_system_pmm_manager+0x248>
ffffffffc0201460:	0b900593          	li	a1,185
ffffffffc0201464:	00001517          	auipc	a0,0x1
ffffffffc0201468:	35450513          	addi	a0,a0,852 # ffffffffc02027b8 <buddy_system_pmm_manager+0x270>
ffffffffc020146c:	f41fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc0201470:	00001617          	auipc	a2,0x1
ffffffffc0201474:	32060613          	addi	a2,a2,800 # ffffffffc0202790 <buddy_system_pmm_manager+0x248>
ffffffffc0201478:	07e00593          	li	a1,126
ffffffffc020147c:	00001517          	auipc	a0,0x1
ffffffffc0201480:	33c50513          	addi	a0,a0,828 # ffffffffc02027b8 <buddy_system_pmm_manager+0x270>
ffffffffc0201484:	f29fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc0201488:	86a2                	mv	a3,s0
ffffffffc020148a:	00001617          	auipc	a2,0x1
ffffffffc020148e:	30660613          	addi	a2,a2,774 # ffffffffc0202790 <buddy_system_pmm_manager+0x248>
ffffffffc0201492:	09000593          	li	a1,144
ffffffffc0201496:	00001517          	auipc	a0,0x1
ffffffffc020149a:	32250513          	addi	a0,a0,802 # ffffffffc02027b8 <buddy_system_pmm_manager+0x270>
ffffffffc020149e:	f0ffe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02014a2 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02014a2:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02014a6:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02014a8:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02014ac:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02014ae:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02014b2:	f022                	sd	s0,32(sp)
ffffffffc02014b4:	ec26                	sd	s1,24(sp)
ffffffffc02014b6:	e84a                	sd	s2,16(sp)
ffffffffc02014b8:	f406                	sd	ra,40(sp)
ffffffffc02014ba:	e44e                	sd	s3,8(sp)
ffffffffc02014bc:	84aa                	mv	s1,a0
ffffffffc02014be:	892e                	mv	s2,a1
ffffffffc02014c0:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02014c4:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc02014c6:	03067e63          	bleu	a6,a2,ffffffffc0201502 <printnum+0x60>
ffffffffc02014ca:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02014cc:	00805763          	blez	s0,ffffffffc02014da <printnum+0x38>
ffffffffc02014d0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02014d2:	85ca                	mv	a1,s2
ffffffffc02014d4:	854e                	mv	a0,s3
ffffffffc02014d6:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02014d8:	fc65                	bnez	s0,ffffffffc02014d0 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014da:	1a02                	slli	s4,s4,0x20
ffffffffc02014dc:	020a5a13          	srli	s4,s4,0x20
ffffffffc02014e0:	00001797          	auipc	a5,0x1
ffffffffc02014e4:	65878793          	addi	a5,a5,1624 # ffffffffc0202b38 <error_string+0x38>
ffffffffc02014e8:	9a3e                	add	s4,s4,a5
}
ffffffffc02014ea:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014ec:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02014f0:	70a2                	ld	ra,40(sp)
ffffffffc02014f2:	69a2                	ld	s3,8(sp)
ffffffffc02014f4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014f6:	85ca                	mv	a1,s2
ffffffffc02014f8:	8326                	mv	t1,s1
}
ffffffffc02014fa:	6942                	ld	s2,16(sp)
ffffffffc02014fc:	64e2                	ld	s1,24(sp)
ffffffffc02014fe:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201500:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201502:	03065633          	divu	a2,a2,a6
ffffffffc0201506:	8722                	mv	a4,s0
ffffffffc0201508:	f9bff0ef          	jal	ra,ffffffffc02014a2 <printnum>
ffffffffc020150c:	b7f9                	j	ffffffffc02014da <printnum+0x38>

ffffffffc020150e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020150e:	7119                	addi	sp,sp,-128
ffffffffc0201510:	f4a6                	sd	s1,104(sp)
ffffffffc0201512:	f0ca                	sd	s2,96(sp)
ffffffffc0201514:	e8d2                	sd	s4,80(sp)
ffffffffc0201516:	e4d6                	sd	s5,72(sp)
ffffffffc0201518:	e0da                	sd	s6,64(sp)
ffffffffc020151a:	fc5e                	sd	s7,56(sp)
ffffffffc020151c:	f862                	sd	s8,48(sp)
ffffffffc020151e:	f06a                	sd	s10,32(sp)
ffffffffc0201520:	fc86                	sd	ra,120(sp)
ffffffffc0201522:	f8a2                	sd	s0,112(sp)
ffffffffc0201524:	ecce                	sd	s3,88(sp)
ffffffffc0201526:	f466                	sd	s9,40(sp)
ffffffffc0201528:	ec6e                	sd	s11,24(sp)
ffffffffc020152a:	892a                	mv	s2,a0
ffffffffc020152c:	84ae                	mv	s1,a1
ffffffffc020152e:	8d32                	mv	s10,a2
ffffffffc0201530:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201532:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201534:	00001a17          	auipc	s4,0x1
ffffffffc0201538:	474a0a13          	addi	s4,s4,1140 # ffffffffc02029a8 <buddy_system_pmm_manager+0x460>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020153c:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201540:	00001c17          	auipc	s8,0x1
ffffffffc0201544:	5c0c0c13          	addi	s8,s8,1472 # ffffffffc0202b00 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201548:	000d4503          	lbu	a0,0(s10)
ffffffffc020154c:	02500793          	li	a5,37
ffffffffc0201550:	001d0413          	addi	s0,s10,1
ffffffffc0201554:	00f50e63          	beq	a0,a5,ffffffffc0201570 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0201558:	c521                	beqz	a0,ffffffffc02015a0 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020155a:	02500993          	li	s3,37
ffffffffc020155e:	a011                	j	ffffffffc0201562 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0201560:	c121                	beqz	a0,ffffffffc02015a0 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0201562:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201564:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201566:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201568:	fff44503          	lbu	a0,-1(s0) # fffffffffff7ffff <end+0x3fd79a97>
ffffffffc020156c:	ff351ae3          	bne	a0,s3,ffffffffc0201560 <vprintfmt+0x52>
ffffffffc0201570:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201574:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201578:	4981                	li	s3,0
ffffffffc020157a:	4801                	li	a6,0
        width = precision = -1;
ffffffffc020157c:	5cfd                	li	s9,-1
ffffffffc020157e:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201580:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0201584:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201586:	fdd6069b          	addiw	a3,a2,-35
ffffffffc020158a:	0ff6f693          	andi	a3,a3,255
ffffffffc020158e:	00140d13          	addi	s10,s0,1
ffffffffc0201592:	20d5e563          	bltu	a1,a3,ffffffffc020179c <vprintfmt+0x28e>
ffffffffc0201596:	068a                	slli	a3,a3,0x2
ffffffffc0201598:	96d2                	add	a3,a3,s4
ffffffffc020159a:	4294                	lw	a3,0(a3)
ffffffffc020159c:	96d2                	add	a3,a3,s4
ffffffffc020159e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02015a0:	70e6                	ld	ra,120(sp)
ffffffffc02015a2:	7446                	ld	s0,112(sp)
ffffffffc02015a4:	74a6                	ld	s1,104(sp)
ffffffffc02015a6:	7906                	ld	s2,96(sp)
ffffffffc02015a8:	69e6                	ld	s3,88(sp)
ffffffffc02015aa:	6a46                	ld	s4,80(sp)
ffffffffc02015ac:	6aa6                	ld	s5,72(sp)
ffffffffc02015ae:	6b06                	ld	s6,64(sp)
ffffffffc02015b0:	7be2                	ld	s7,56(sp)
ffffffffc02015b2:	7c42                	ld	s8,48(sp)
ffffffffc02015b4:	7ca2                	ld	s9,40(sp)
ffffffffc02015b6:	7d02                	ld	s10,32(sp)
ffffffffc02015b8:	6de2                	ld	s11,24(sp)
ffffffffc02015ba:	6109                	addi	sp,sp,128
ffffffffc02015bc:	8082                	ret
    if (lflag >= 2) {
ffffffffc02015be:	4705                	li	a4,1
ffffffffc02015c0:	008a8593          	addi	a1,s5,8
ffffffffc02015c4:	01074463          	blt	a4,a6,ffffffffc02015cc <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc02015c8:	26080363          	beqz	a6,ffffffffc020182e <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc02015cc:	000ab603          	ld	a2,0(s5)
ffffffffc02015d0:	46c1                	li	a3,16
ffffffffc02015d2:	8aae                	mv	s5,a1
ffffffffc02015d4:	a06d                	j	ffffffffc020167e <vprintfmt+0x170>
            goto reswitch;
ffffffffc02015d6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02015da:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015dc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02015de:	b765                	j	ffffffffc0201586 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc02015e0:	000aa503          	lw	a0,0(s5)
ffffffffc02015e4:	85a6                	mv	a1,s1
ffffffffc02015e6:	0aa1                	addi	s5,s5,8
ffffffffc02015e8:	9902                	jalr	s2
            break;
ffffffffc02015ea:	bfb9                	j	ffffffffc0201548 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02015ec:	4705                	li	a4,1
ffffffffc02015ee:	008a8993          	addi	s3,s5,8
ffffffffc02015f2:	01074463          	blt	a4,a6,ffffffffc02015fa <vprintfmt+0xec>
    else if (lflag) {
ffffffffc02015f6:	22080463          	beqz	a6,ffffffffc020181e <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc02015fa:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc02015fe:	24044463          	bltz	s0,ffffffffc0201846 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0201602:	8622                	mv	a2,s0
ffffffffc0201604:	8ace                	mv	s5,s3
ffffffffc0201606:	46a9                	li	a3,10
ffffffffc0201608:	a89d                	j	ffffffffc020167e <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc020160a:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020160e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201610:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0201612:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201616:	8fb5                	xor	a5,a5,a3
ffffffffc0201618:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020161c:	1ad74363          	blt	a4,a3,ffffffffc02017c2 <vprintfmt+0x2b4>
ffffffffc0201620:	00369793          	slli	a5,a3,0x3
ffffffffc0201624:	97e2                	add	a5,a5,s8
ffffffffc0201626:	639c                	ld	a5,0(a5)
ffffffffc0201628:	18078d63          	beqz	a5,ffffffffc02017c2 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc020162c:	86be                	mv	a3,a5
ffffffffc020162e:	00001617          	auipc	a2,0x1
ffffffffc0201632:	5ba60613          	addi	a2,a2,1466 # ffffffffc0202be8 <error_string+0xe8>
ffffffffc0201636:	85a6                	mv	a1,s1
ffffffffc0201638:	854a                	mv	a0,s2
ffffffffc020163a:	240000ef          	jal	ra,ffffffffc020187a <printfmt>
ffffffffc020163e:	b729                	j	ffffffffc0201548 <vprintfmt+0x3a>
            lflag ++;
ffffffffc0201640:	00144603          	lbu	a2,1(s0)
ffffffffc0201644:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201646:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201648:	bf3d                	j	ffffffffc0201586 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc020164a:	4705                	li	a4,1
ffffffffc020164c:	008a8593          	addi	a1,s5,8
ffffffffc0201650:	01074463          	blt	a4,a6,ffffffffc0201658 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0201654:	1e080263          	beqz	a6,ffffffffc0201838 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc0201658:	000ab603          	ld	a2,0(s5)
ffffffffc020165c:	46a1                	li	a3,8
ffffffffc020165e:	8aae                	mv	s5,a1
ffffffffc0201660:	a839                	j	ffffffffc020167e <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0201662:	03000513          	li	a0,48
ffffffffc0201666:	85a6                	mv	a1,s1
ffffffffc0201668:	e03e                	sd	a5,0(sp)
ffffffffc020166a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020166c:	85a6                	mv	a1,s1
ffffffffc020166e:	07800513          	li	a0,120
ffffffffc0201672:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201674:	0aa1                	addi	s5,s5,8
ffffffffc0201676:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc020167a:	6782                	ld	a5,0(sp)
ffffffffc020167c:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020167e:	876e                	mv	a4,s11
ffffffffc0201680:	85a6                	mv	a1,s1
ffffffffc0201682:	854a                	mv	a0,s2
ffffffffc0201684:	e1fff0ef          	jal	ra,ffffffffc02014a2 <printnum>
            break;
ffffffffc0201688:	b5c1                	j	ffffffffc0201548 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020168a:	000ab603          	ld	a2,0(s5)
ffffffffc020168e:	0aa1                	addi	s5,s5,8
ffffffffc0201690:	1c060663          	beqz	a2,ffffffffc020185c <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0201694:	00160413          	addi	s0,a2,1
ffffffffc0201698:	17b05c63          	blez	s11,ffffffffc0201810 <vprintfmt+0x302>
ffffffffc020169c:	02d00593          	li	a1,45
ffffffffc02016a0:	14b79263          	bne	a5,a1,ffffffffc02017e4 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016a4:	00064783          	lbu	a5,0(a2)
ffffffffc02016a8:	0007851b          	sext.w	a0,a5
ffffffffc02016ac:	c905                	beqz	a0,ffffffffc02016dc <vprintfmt+0x1ce>
ffffffffc02016ae:	000cc563          	bltz	s9,ffffffffc02016b8 <vprintfmt+0x1aa>
ffffffffc02016b2:	3cfd                	addiw	s9,s9,-1
ffffffffc02016b4:	036c8263          	beq	s9,s6,ffffffffc02016d8 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc02016b8:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016ba:	18098463          	beqz	s3,ffffffffc0201842 <vprintfmt+0x334>
ffffffffc02016be:	3781                	addiw	a5,a5,-32
ffffffffc02016c0:	18fbf163          	bleu	a5,s7,ffffffffc0201842 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc02016c4:	03f00513          	li	a0,63
ffffffffc02016c8:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016ca:	0405                	addi	s0,s0,1
ffffffffc02016cc:	fff44783          	lbu	a5,-1(s0)
ffffffffc02016d0:	3dfd                	addiw	s11,s11,-1
ffffffffc02016d2:	0007851b          	sext.w	a0,a5
ffffffffc02016d6:	fd61                	bnez	a0,ffffffffc02016ae <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc02016d8:	e7b058e3          	blez	s11,ffffffffc0201548 <vprintfmt+0x3a>
ffffffffc02016dc:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02016de:	85a6                	mv	a1,s1
ffffffffc02016e0:	02000513          	li	a0,32
ffffffffc02016e4:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02016e6:	e60d81e3          	beqz	s11,ffffffffc0201548 <vprintfmt+0x3a>
ffffffffc02016ea:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02016ec:	85a6                	mv	a1,s1
ffffffffc02016ee:	02000513          	li	a0,32
ffffffffc02016f2:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02016f4:	fe0d94e3          	bnez	s11,ffffffffc02016dc <vprintfmt+0x1ce>
ffffffffc02016f8:	bd81                	j	ffffffffc0201548 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02016fa:	4705                	li	a4,1
ffffffffc02016fc:	008a8593          	addi	a1,s5,8
ffffffffc0201700:	01074463          	blt	a4,a6,ffffffffc0201708 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0201704:	12080063          	beqz	a6,ffffffffc0201824 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0201708:	000ab603          	ld	a2,0(s5)
ffffffffc020170c:	46a9                	li	a3,10
ffffffffc020170e:	8aae                	mv	s5,a1
ffffffffc0201710:	b7bd                	j	ffffffffc020167e <vprintfmt+0x170>
ffffffffc0201712:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc0201716:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020171a:	846a                	mv	s0,s10
ffffffffc020171c:	b5ad                	j	ffffffffc0201586 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc020171e:	85a6                	mv	a1,s1
ffffffffc0201720:	02500513          	li	a0,37
ffffffffc0201724:	9902                	jalr	s2
            break;
ffffffffc0201726:	b50d                	j	ffffffffc0201548 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc0201728:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc020172c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201730:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201732:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0201734:	e40dd9e3          	bgez	s11,ffffffffc0201586 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0201738:	8de6                	mv	s11,s9
ffffffffc020173a:	5cfd                	li	s9,-1
ffffffffc020173c:	b5a9                	j	ffffffffc0201586 <vprintfmt+0x78>
            goto reswitch;
ffffffffc020173e:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc0201742:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201746:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201748:	bd3d                	j	ffffffffc0201586 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc020174a:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc020174e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201752:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201754:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201758:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc020175c:	fcd56ce3          	bltu	a0,a3,ffffffffc0201734 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc0201760:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201762:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0201766:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020176a:	0196873b          	addw	a4,a3,s9
ffffffffc020176e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201772:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0201776:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc020177a:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020177e:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201782:	fcd57fe3          	bleu	a3,a0,ffffffffc0201760 <vprintfmt+0x252>
ffffffffc0201786:	b77d                	j	ffffffffc0201734 <vprintfmt+0x226>
            if (width < 0)
ffffffffc0201788:	fffdc693          	not	a3,s11
ffffffffc020178c:	96fd                	srai	a3,a3,0x3f
ffffffffc020178e:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201792:	00144603          	lbu	a2,1(s0)
ffffffffc0201796:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201798:	846a                	mv	s0,s10
ffffffffc020179a:	b3f5                	j	ffffffffc0201586 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc020179c:	85a6                	mv	a1,s1
ffffffffc020179e:	02500513          	li	a0,37
ffffffffc02017a2:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02017a4:	fff44703          	lbu	a4,-1(s0)
ffffffffc02017a8:	02500793          	li	a5,37
ffffffffc02017ac:	8d22                	mv	s10,s0
ffffffffc02017ae:	d8f70de3          	beq	a4,a5,ffffffffc0201548 <vprintfmt+0x3a>
ffffffffc02017b2:	02500713          	li	a4,37
ffffffffc02017b6:	1d7d                	addi	s10,s10,-1
ffffffffc02017b8:	fffd4783          	lbu	a5,-1(s10)
ffffffffc02017bc:	fee79de3          	bne	a5,a4,ffffffffc02017b6 <vprintfmt+0x2a8>
ffffffffc02017c0:	b361                	j	ffffffffc0201548 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02017c2:	00001617          	auipc	a2,0x1
ffffffffc02017c6:	41660613          	addi	a2,a2,1046 # ffffffffc0202bd8 <error_string+0xd8>
ffffffffc02017ca:	85a6                	mv	a1,s1
ffffffffc02017cc:	854a                	mv	a0,s2
ffffffffc02017ce:	0ac000ef          	jal	ra,ffffffffc020187a <printfmt>
ffffffffc02017d2:	bb9d                	j	ffffffffc0201548 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02017d4:	00001617          	auipc	a2,0x1
ffffffffc02017d8:	3fc60613          	addi	a2,a2,1020 # ffffffffc0202bd0 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc02017dc:	00001417          	auipc	s0,0x1
ffffffffc02017e0:	3f540413          	addi	s0,s0,1013 # ffffffffc0202bd1 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02017e4:	8532                	mv	a0,a2
ffffffffc02017e6:	85e6                	mv	a1,s9
ffffffffc02017e8:	e032                	sd	a2,0(sp)
ffffffffc02017ea:	e43e                	sd	a5,8(sp)
ffffffffc02017ec:	1de000ef          	jal	ra,ffffffffc02019ca <strnlen>
ffffffffc02017f0:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02017f4:	6602                	ld	a2,0(sp)
ffffffffc02017f6:	01b05d63          	blez	s11,ffffffffc0201810 <vprintfmt+0x302>
ffffffffc02017fa:	67a2                	ld	a5,8(sp)
ffffffffc02017fc:	2781                	sext.w	a5,a5
ffffffffc02017fe:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0201800:	6522                	ld	a0,8(sp)
ffffffffc0201802:	85a6                	mv	a1,s1
ffffffffc0201804:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201806:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201808:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020180a:	6602                	ld	a2,0(sp)
ffffffffc020180c:	fe0d9ae3          	bnez	s11,ffffffffc0201800 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201810:	00064783          	lbu	a5,0(a2)
ffffffffc0201814:	0007851b          	sext.w	a0,a5
ffffffffc0201818:	e8051be3          	bnez	a0,ffffffffc02016ae <vprintfmt+0x1a0>
ffffffffc020181c:	b335                	j	ffffffffc0201548 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc020181e:	000aa403          	lw	s0,0(s5)
ffffffffc0201822:	bbf1                	j	ffffffffc02015fe <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc0201824:	000ae603          	lwu	a2,0(s5)
ffffffffc0201828:	46a9                	li	a3,10
ffffffffc020182a:	8aae                	mv	s5,a1
ffffffffc020182c:	bd89                	j	ffffffffc020167e <vprintfmt+0x170>
ffffffffc020182e:	000ae603          	lwu	a2,0(s5)
ffffffffc0201832:	46c1                	li	a3,16
ffffffffc0201834:	8aae                	mv	s5,a1
ffffffffc0201836:	b5a1                	j	ffffffffc020167e <vprintfmt+0x170>
ffffffffc0201838:	000ae603          	lwu	a2,0(s5)
ffffffffc020183c:	46a1                	li	a3,8
ffffffffc020183e:	8aae                	mv	s5,a1
ffffffffc0201840:	bd3d                	j	ffffffffc020167e <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0201842:	9902                	jalr	s2
ffffffffc0201844:	b559                	j	ffffffffc02016ca <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc0201846:	85a6                	mv	a1,s1
ffffffffc0201848:	02d00513          	li	a0,45
ffffffffc020184c:	e03e                	sd	a5,0(sp)
ffffffffc020184e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201850:	8ace                	mv	s5,s3
ffffffffc0201852:	40800633          	neg	a2,s0
ffffffffc0201856:	46a9                	li	a3,10
ffffffffc0201858:	6782                	ld	a5,0(sp)
ffffffffc020185a:	b515                	j	ffffffffc020167e <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc020185c:	01b05663          	blez	s11,ffffffffc0201868 <vprintfmt+0x35a>
ffffffffc0201860:	02d00693          	li	a3,45
ffffffffc0201864:	f6d798e3          	bne	a5,a3,ffffffffc02017d4 <vprintfmt+0x2c6>
ffffffffc0201868:	00001417          	auipc	s0,0x1
ffffffffc020186c:	36940413          	addi	s0,s0,873 # ffffffffc0202bd1 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201870:	02800513          	li	a0,40
ffffffffc0201874:	02800793          	li	a5,40
ffffffffc0201878:	bd1d                	j	ffffffffc02016ae <vprintfmt+0x1a0>

ffffffffc020187a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020187a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020187c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201880:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201882:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201884:	ec06                	sd	ra,24(sp)
ffffffffc0201886:	f83a                	sd	a4,48(sp)
ffffffffc0201888:	fc3e                	sd	a5,56(sp)
ffffffffc020188a:	e0c2                	sd	a6,64(sp)
ffffffffc020188c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020188e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201890:	c7fff0ef          	jal	ra,ffffffffc020150e <vprintfmt>
}
ffffffffc0201894:	60e2                	ld	ra,24(sp)
ffffffffc0201896:	6161                	addi	sp,sp,80
ffffffffc0201898:	8082                	ret

ffffffffc020189a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020189a:	715d                	addi	sp,sp,-80
ffffffffc020189c:	e486                	sd	ra,72(sp)
ffffffffc020189e:	e0a2                	sd	s0,64(sp)
ffffffffc02018a0:	fc26                	sd	s1,56(sp)
ffffffffc02018a2:	f84a                	sd	s2,48(sp)
ffffffffc02018a4:	f44e                	sd	s3,40(sp)
ffffffffc02018a6:	f052                	sd	s4,32(sp)
ffffffffc02018a8:	ec56                	sd	s5,24(sp)
ffffffffc02018aa:	e85a                	sd	s6,16(sp)
ffffffffc02018ac:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02018ae:	c901                	beqz	a0,ffffffffc02018be <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02018b0:	85aa                	mv	a1,a0
ffffffffc02018b2:	00001517          	auipc	a0,0x1
ffffffffc02018b6:	33650513          	addi	a0,a0,822 # ffffffffc0202be8 <error_string+0xe8>
ffffffffc02018ba:	ffcfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
readline(const char *prompt) {
ffffffffc02018be:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02018c0:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02018c2:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02018c4:	4aa9                	li	s5,10
ffffffffc02018c6:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02018c8:	00004b97          	auipc	s7,0x4
ffffffffc02018cc:	750b8b93          	addi	s7,s7,1872 # ffffffffc0206018 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02018d0:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02018d4:	85bfe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc02018d8:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02018da:	00054b63          	bltz	a0,ffffffffc02018f0 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02018de:	00a95b63          	ble	a0,s2,ffffffffc02018f4 <readline+0x5a>
ffffffffc02018e2:	029a5463          	ble	s1,s4,ffffffffc020190a <readline+0x70>
        c = getchar();
ffffffffc02018e6:	849fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc02018ea:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02018ec:	fe0559e3          	bgez	a0,ffffffffc02018de <readline+0x44>
            return NULL;
ffffffffc02018f0:	4501                	li	a0,0
ffffffffc02018f2:	a099                	j	ffffffffc0201938 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02018f4:	03341463          	bne	s0,s3,ffffffffc020191c <readline+0x82>
ffffffffc02018f8:	e8b9                	bnez	s1,ffffffffc020194e <readline+0xb4>
        c = getchar();
ffffffffc02018fa:	835fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc02018fe:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201900:	fe0548e3          	bltz	a0,ffffffffc02018f0 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201904:	fea958e3          	ble	a0,s2,ffffffffc02018f4 <readline+0x5a>
ffffffffc0201908:	4481                	li	s1,0
            cputchar(c);
ffffffffc020190a:	8522                	mv	a0,s0
ffffffffc020190c:	fdefe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i ++] = c;
ffffffffc0201910:	009b87b3          	add	a5,s7,s1
ffffffffc0201914:	00878023          	sb	s0,0(a5)
ffffffffc0201918:	2485                	addiw	s1,s1,1
ffffffffc020191a:	bf6d                	j	ffffffffc02018d4 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc020191c:	01540463          	beq	s0,s5,ffffffffc0201924 <readline+0x8a>
ffffffffc0201920:	fb641ae3          	bne	s0,s6,ffffffffc02018d4 <readline+0x3a>
            cputchar(c);
ffffffffc0201924:	8522                	mv	a0,s0
ffffffffc0201926:	fc4fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i] = '\0';
ffffffffc020192a:	00004517          	auipc	a0,0x4
ffffffffc020192e:	6ee50513          	addi	a0,a0,1774 # ffffffffc0206018 <edata>
ffffffffc0201932:	94aa                	add	s1,s1,a0
ffffffffc0201934:	00048023          	sb	zero,0(s1) # ffffffffc0200000 <kern_entry>
            return buf;
        }
    }
}
ffffffffc0201938:	60a6                	ld	ra,72(sp)
ffffffffc020193a:	6406                	ld	s0,64(sp)
ffffffffc020193c:	74e2                	ld	s1,56(sp)
ffffffffc020193e:	7942                	ld	s2,48(sp)
ffffffffc0201940:	79a2                	ld	s3,40(sp)
ffffffffc0201942:	7a02                	ld	s4,32(sp)
ffffffffc0201944:	6ae2                	ld	s5,24(sp)
ffffffffc0201946:	6b42                	ld	s6,16(sp)
ffffffffc0201948:	6ba2                	ld	s7,8(sp)
ffffffffc020194a:	6161                	addi	sp,sp,80
ffffffffc020194c:	8082                	ret
            cputchar(c);
ffffffffc020194e:	4521                	li	a0,8
ffffffffc0201950:	f9afe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            i --;
ffffffffc0201954:	34fd                	addiw	s1,s1,-1
ffffffffc0201956:	bfbd                	j	ffffffffc02018d4 <readline+0x3a>

ffffffffc0201958 <sbi_console_putchar>:
    return ret_val;
}

void sbi_console_putchar(unsigned char ch)
{
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201958:	00004797          	auipc	a5,0x4
ffffffffc020195c:	6b078793          	addi	a5,a5,1712 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile(
ffffffffc0201960:	6398                	ld	a4,0(a5)
ffffffffc0201962:	4781                	li	a5,0
ffffffffc0201964:	88ba                	mv	a7,a4
ffffffffc0201966:	852a                	mv	a0,a0
ffffffffc0201968:	85be                	mv	a1,a5
ffffffffc020196a:	863e                	mv	a2,a5
ffffffffc020196c:	00000073          	ecall
ffffffffc0201970:	87aa                	mv	a5,a0
}
ffffffffc0201972:	8082                	ret

ffffffffc0201974 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value)
{
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201974:	00005797          	auipc	a5,0x5
ffffffffc0201978:	ac478793          	addi	a5,a5,-1340 # ffffffffc0206438 <SBI_SET_TIMER>
    __asm__ volatile(
ffffffffc020197c:	6398                	ld	a4,0(a5)
ffffffffc020197e:	4781                	li	a5,0
ffffffffc0201980:	88ba                	mv	a7,a4
ffffffffc0201982:	852a                	mv	a0,a0
ffffffffc0201984:	85be                	mv	a1,a5
ffffffffc0201986:	863e                	mv	a2,a5
ffffffffc0201988:	00000073          	ecall
ffffffffc020198c:	87aa                	mv	a5,a0
}
ffffffffc020198e:	8082                	ret

ffffffffc0201990 <sbi_console_getchar>:

int sbi_console_getchar(void)
{
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201990:	00004797          	auipc	a5,0x4
ffffffffc0201994:	67078793          	addi	a5,a5,1648 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile(
ffffffffc0201998:	639c                	ld	a5,0(a5)
ffffffffc020199a:	4501                	li	a0,0
ffffffffc020199c:	88be                	mv	a7,a5
ffffffffc020199e:	852a                	mv	a0,a0
ffffffffc02019a0:	85aa                	mv	a1,a0
ffffffffc02019a2:	862a                	mv	a2,a0
ffffffffc02019a4:	00000073          	ecall
ffffffffc02019a8:	852a                	mv	a0,a0
}
ffffffffc02019aa:	2501                	sext.w	a0,a0
ffffffffc02019ac:	8082                	ret

ffffffffc02019ae <sbi_shutdown>:

void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc02019ae:	00004797          	auipc	a5,0x4
ffffffffc02019b2:	66278793          	addi	a5,a5,1634 # ffffffffc0206010 <SBI_SHUTDOWN>
    __asm__ volatile(
ffffffffc02019b6:	6398                	ld	a4,0(a5)
ffffffffc02019b8:	4781                	li	a5,0
ffffffffc02019ba:	88ba                	mv	a7,a4
ffffffffc02019bc:	853e                	mv	a0,a5
ffffffffc02019be:	85be                	mv	a1,a5
ffffffffc02019c0:	863e                	mv	a2,a5
ffffffffc02019c2:	00000073          	ecall
ffffffffc02019c6:	87aa                	mv	a5,a0
ffffffffc02019c8:	8082                	ret

ffffffffc02019ca <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc02019ca:	c185                	beqz	a1,ffffffffc02019ea <strnlen+0x20>
ffffffffc02019cc:	00054783          	lbu	a5,0(a0)
ffffffffc02019d0:	cf89                	beqz	a5,ffffffffc02019ea <strnlen+0x20>
    size_t cnt = 0;
ffffffffc02019d2:	4781                	li	a5,0
ffffffffc02019d4:	a021                	j	ffffffffc02019dc <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc02019d6:	00074703          	lbu	a4,0(a4)
ffffffffc02019da:	c711                	beqz	a4,ffffffffc02019e6 <strnlen+0x1c>
        cnt ++;
ffffffffc02019dc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02019de:	00f50733          	add	a4,a0,a5
ffffffffc02019e2:	fef59ae3          	bne	a1,a5,ffffffffc02019d6 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc02019e6:	853e                	mv	a0,a5
ffffffffc02019e8:	8082                	ret
    size_t cnt = 0;
ffffffffc02019ea:	4781                	li	a5,0
}
ffffffffc02019ec:	853e                	mv	a0,a5
ffffffffc02019ee:	8082                	ret

ffffffffc02019f0 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02019f0:	00054783          	lbu	a5,0(a0)
ffffffffc02019f4:	0005c703          	lbu	a4,0(a1) # fffffffffffff000 <end+0x3fdf8a98>
ffffffffc02019f8:	cb91                	beqz	a5,ffffffffc0201a0c <strcmp+0x1c>
ffffffffc02019fa:	00e79c63          	bne	a5,a4,ffffffffc0201a12 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc02019fe:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a00:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0201a04:	0585                	addi	a1,a1,1
ffffffffc0201a06:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a0a:	fbe5                	bnez	a5,ffffffffc02019fa <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a0c:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201a0e:	9d19                	subw	a0,a0,a4
ffffffffc0201a10:	8082                	ret
ffffffffc0201a12:	0007851b          	sext.w	a0,a5
ffffffffc0201a16:	9d19                	subw	a0,a0,a4
ffffffffc0201a18:	8082                	ret

ffffffffc0201a1a <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201a1a:	00054783          	lbu	a5,0(a0)
ffffffffc0201a1e:	cb91                	beqz	a5,ffffffffc0201a32 <strchr+0x18>
        if (*s == c) {
ffffffffc0201a20:	00b79563          	bne	a5,a1,ffffffffc0201a2a <strchr+0x10>
ffffffffc0201a24:	a809                	j	ffffffffc0201a36 <strchr+0x1c>
ffffffffc0201a26:	00b78763          	beq	a5,a1,ffffffffc0201a34 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0201a2a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201a2c:	00054783          	lbu	a5,0(a0)
ffffffffc0201a30:	fbfd                	bnez	a5,ffffffffc0201a26 <strchr+0xc>
    }
    return NULL;
ffffffffc0201a32:	4501                	li	a0,0
}
ffffffffc0201a34:	8082                	ret
ffffffffc0201a36:	8082                	ret

ffffffffc0201a38 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201a38:	ca01                	beqz	a2,ffffffffc0201a48 <memset+0x10>
ffffffffc0201a3a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201a3c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201a3e:	0785                	addi	a5,a5,1
ffffffffc0201a40:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201a44:	fec79de3          	bne	a5,a2,ffffffffc0201a3e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201a48:	8082                	ret
