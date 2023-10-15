
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
    # t0 >>= 12，变为三级页表的物理页号（物理地址右移12位得到物理页号）
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39 39位虚拟地址模式
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
    #如果不加参数的， sfence.vma 会刷新整个 TLB 。你可以在后面加上一个虚拟地址，这样 sfence.vma 只会刷新这个虚拟地址的映射
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop) // 指向一个预先定义的虚拟地址 bootstacktop，这是内核栈的顶部。
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
ffffffffc020004e:	353010ef          	jal	ra,ffffffffc0201ba0 <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fe000ef          	jal	ra,ffffffffc0200450 <cons_init>
    const char *message = "(NKU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00002517          	auipc	a0,0x2
ffffffffc020005a:	b6250513          	addi	a0,a0,-1182 # ffffffffc0201bb8 <etext+0x6>
ffffffffc020005e:	090000ef          	jal	ra,ffffffffc02000ee <cputs>

    print_kerninfo();
ffffffffc0200062:	0dc000ef          	jal	ra,ffffffffc020013e <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table 初始化中断描述符表IDT
ffffffffc0200066:	404000ef          	jal	ra,ffffffffc020046a <idt_init>

    pmm_init();  // init physical memory management 物理内存管理
ffffffffc020006a:	24a010ef          	jal	ra,ffffffffc02012b4 <pmm_init>
    /* pmm_init()函数需要注册缺页中断处理程序，用于处理页面访问异常。
        当程序试图访问一个不存在的页面时，CPU会触发缺页异常，此时会调用缺页中断处理程序
        该程序会在物理内存中分配一个新的页面，并将其映射到虚拟地址空间中。
    */

    idt_init();  // init interrupt descriptor table
ffffffffc020006e:	3fc000ef          	jal	ra,ffffffffc020046a <idt_init>

    clock_init();   // init clock interrupt 时钟中断
ffffffffc0200072:	39a000ef          	jal	ra,ffffffffc020040c <clock_init>
    /*
    clock_init()函数需要注册时钟中断处理程序，用于定时触发时钟中断。
    当时钟中断被触发时，CPU会跳转到时钟中断处理程序，该程序会更新系统时间，并执行一些周期性的操作，如调度进程等
    */
    //这两个函数都需要使用中断描述符表，所以要在中断描述符表初始化之后再初始化时钟中断
    intr_enable();  // enable irq interrupt 开启中断
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
ffffffffc02000aa:	5cc010ef          	jal	ra,ffffffffc0201676 <vprintfmt>
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
ffffffffc02000de:	598010ef          	jal	ra,ffffffffc0201676 <vprintfmt>
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
ffffffffc0200144:	ac850513          	addi	a0,a0,-1336 # ffffffffc0201c08 <etext+0x56>
void print_kerninfo(void) {
ffffffffc0200148:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014a:	f6dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014e:	00000597          	auipc	a1,0x0
ffffffffc0200152:	ee858593          	addi	a1,a1,-280 # ffffffffc0200036 <kern_init>
ffffffffc0200156:	00002517          	auipc	a0,0x2
ffffffffc020015a:	ad250513          	addi	a0,a0,-1326 # ffffffffc0201c28 <etext+0x76>
ffffffffc020015e:	f59ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200162:	00002597          	auipc	a1,0x2
ffffffffc0200166:	a5058593          	addi	a1,a1,-1456 # ffffffffc0201bb2 <etext>
ffffffffc020016a:	00002517          	auipc	a0,0x2
ffffffffc020016e:	ade50513          	addi	a0,a0,-1314 # ffffffffc0201c48 <etext+0x96>
ffffffffc0200172:	f45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200176:	00006597          	auipc	a1,0x6
ffffffffc020017a:	ea258593          	addi	a1,a1,-350 # ffffffffc0206018 <edata>
ffffffffc020017e:	00002517          	auipc	a0,0x2
ffffffffc0200182:	aea50513          	addi	a0,a0,-1302 # ffffffffc0201c68 <etext+0xb6>
ffffffffc0200186:	f31ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018a:	00006597          	auipc	a1,0x6
ffffffffc020018e:	3de58593          	addi	a1,a1,990 # ffffffffc0206568 <end>
ffffffffc0200192:	00002517          	auipc	a0,0x2
ffffffffc0200196:	af650513          	addi	a0,a0,-1290 # ffffffffc0201c88 <etext+0xd6>
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
ffffffffc02001c4:	ae850513          	addi	a0,a0,-1304 # ffffffffc0201ca8 <etext+0xf6>
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
ffffffffc02001d4:	a0860613          	addi	a2,a2,-1528 # ffffffffc0201bd8 <etext+0x26>
ffffffffc02001d8:	04e00593          	li	a1,78
ffffffffc02001dc:	00002517          	auipc	a0,0x2
ffffffffc02001e0:	a1450513          	addi	a0,a0,-1516 # ffffffffc0201bf0 <etext+0x3e>
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
ffffffffc02001f0:	bcc60613          	addi	a2,a2,-1076 # ffffffffc0201db8 <commands+0xe0>
ffffffffc02001f4:	00002597          	auipc	a1,0x2
ffffffffc02001f8:	be458593          	addi	a1,a1,-1052 # ffffffffc0201dd8 <commands+0x100>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	be450513          	addi	a0,a0,-1052 # ffffffffc0201de0 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200206:	eb1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020020a:	00002617          	auipc	a2,0x2
ffffffffc020020e:	be660613          	addi	a2,a2,-1050 # ffffffffc0201df0 <commands+0x118>
ffffffffc0200212:	00002597          	auipc	a1,0x2
ffffffffc0200216:	c0658593          	addi	a1,a1,-1018 # ffffffffc0201e18 <commands+0x140>
ffffffffc020021a:	00002517          	auipc	a0,0x2
ffffffffc020021e:	bc650513          	addi	a0,a0,-1082 # ffffffffc0201de0 <commands+0x108>
ffffffffc0200222:	e95ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200226:	00002617          	auipc	a2,0x2
ffffffffc020022a:	c0260613          	addi	a2,a2,-1022 # ffffffffc0201e28 <commands+0x150>
ffffffffc020022e:	00002597          	auipc	a1,0x2
ffffffffc0200232:	c1a58593          	addi	a1,a1,-998 # ffffffffc0201e48 <commands+0x170>
ffffffffc0200236:	00002517          	auipc	a0,0x2
ffffffffc020023a:	baa50513          	addi	a0,a0,-1110 # ffffffffc0201de0 <commands+0x108>
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
ffffffffc0200274:	ab050513          	addi	a0,a0,-1360 # ffffffffc0201d20 <commands+0x48>
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
ffffffffc0200296:	ab650513          	addi	a0,a0,-1354 # ffffffffc0201d48 <commands+0x70>
ffffffffc020029a:	e1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (tf != NULL) {
ffffffffc020029e:	000c0563          	beqz	s8,ffffffffc02002a8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a2:	8562                	mv	a0,s8
ffffffffc02002a4:	3a6000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002a8:	00002c97          	auipc	s9,0x2
ffffffffc02002ac:	a30c8c93          	addi	s9,s9,-1488 # ffffffffc0201cd8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b0:	00002997          	auipc	s3,0x2
ffffffffc02002b4:	ac098993          	addi	s3,s3,-1344 # ffffffffc0201d70 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00002917          	auipc	s2,0x2
ffffffffc02002bc:	ac090913          	addi	s2,s2,-1344 # ffffffffc0201d78 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002c0:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c2:	00002b17          	auipc	s6,0x2
ffffffffc02002c6:	abeb0b13          	addi	s6,s6,-1346 # ffffffffc0201d80 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ca:	00002a97          	auipc	s5,0x2
ffffffffc02002ce:	b0ea8a93          	addi	s5,s5,-1266 # ffffffffc0201dd8 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d2:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d4:	854e                	mv	a0,s3
ffffffffc02002d6:	72c010ef          	jal	ra,ffffffffc0201a02 <readline>
ffffffffc02002da:	842a                	mv	s0,a0
ffffffffc02002dc:	dd65                	beqz	a0,ffffffffc02002d4 <kmonitor+0x6a>
ffffffffc02002de:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e4:	c999                	beqz	a1,ffffffffc02002fa <kmonitor+0x90>
ffffffffc02002e6:	854a                	mv	a0,s2
ffffffffc02002e8:	09b010ef          	jal	ra,ffffffffc0201b82 <strchr>
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
ffffffffc0200302:	9dad0d13          	addi	s10,s10,-1574 # ffffffffc0201cd8 <commands>
    if (argc == 0) {
ffffffffc0200306:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200308:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	0d61                	addi	s10,s10,24
ffffffffc020030c:	04d010ef          	jal	ra,ffffffffc0201b58 <strcmp>
ffffffffc0200310:	c919                	beqz	a0,ffffffffc0200326 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200312:	2405                	addiw	s0,s0,1
ffffffffc0200314:	09740463          	beq	s0,s7,ffffffffc020039c <kmonitor+0x132>
ffffffffc0200318:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031c:	6582                	ld	a1,0(sp)
ffffffffc020031e:	0d61                	addi	s10,s10,24
ffffffffc0200320:	039010ef          	jal	ra,ffffffffc0201b58 <strcmp>
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
ffffffffc0200386:	7fc010ef          	jal	ra,ffffffffc0201b82 <strchr>
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
ffffffffc02003a2:	a0250513          	addi	a0,a0,-1534 # ffffffffc0201da0 <commands+0xc8>
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
ffffffffc02003e2:	a7a50513          	addi	a0,a0,-1414 # ffffffffc0201e58 <commands+0x180>
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
ffffffffc02003f8:	21c50513          	addi	a0,a0,540 # ffffffffc0202610 <commands+0x938>
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
ffffffffc0200424:	6b8010ef          	jal	ra,ffffffffc0201adc <sbi_set_timer>
}
ffffffffc0200428:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042a:	00006797          	auipc	a5,0x6
ffffffffc020042e:	0007bb23          	sd	zero,22(a5) # ffffffffc0206440 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200432:	00002517          	auipc	a0,0x2
ffffffffc0200436:	a4650513          	addi	a0,a0,-1466 # ffffffffc0201e78 <commands+0x1a0>
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
ffffffffc020044c:	6900106f          	j	ffffffffc0201adc <sbi_set_timer>

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
ffffffffc0200456:	66a0106f          	j	ffffffffc0201ac0 <sbi_console_putchar>

ffffffffc020045a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045a:	69e0106f          	j	ffffffffc0201af8 <sbi_console_getchar>

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
ffffffffc0200488:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0201f90 <commands+0x2b8>
{
ffffffffc020048c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048e:	c29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200492:	640c                	ld	a1,8(s0)
ffffffffc0200494:	00002517          	auipc	a0,0x2
ffffffffc0200498:	b1450513          	addi	a0,a0,-1260 # ffffffffc0201fa8 <commands+0x2d0>
ffffffffc020049c:	c1bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a0:	680c                	ld	a1,16(s0)
ffffffffc02004a2:	00002517          	auipc	a0,0x2
ffffffffc02004a6:	b1e50513          	addi	a0,a0,-1250 # ffffffffc0201fc0 <commands+0x2e8>
ffffffffc02004aa:	c0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004ae:	6c0c                	ld	a1,24(s0)
ffffffffc02004b0:	00002517          	auipc	a0,0x2
ffffffffc02004b4:	b2850513          	addi	a0,a0,-1240 # ffffffffc0201fd8 <commands+0x300>
ffffffffc02004b8:	bffff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004bc:	700c                	ld	a1,32(s0)
ffffffffc02004be:	00002517          	auipc	a0,0x2
ffffffffc02004c2:	b3250513          	addi	a0,a0,-1230 # ffffffffc0201ff0 <commands+0x318>
ffffffffc02004c6:	bf1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004ca:	740c                	ld	a1,40(s0)
ffffffffc02004cc:	00002517          	auipc	a0,0x2
ffffffffc02004d0:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0202008 <commands+0x330>
ffffffffc02004d4:	be3ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d8:	780c                	ld	a1,48(s0)
ffffffffc02004da:	00002517          	auipc	a0,0x2
ffffffffc02004de:	b4650513          	addi	a0,a0,-1210 # ffffffffc0202020 <commands+0x348>
ffffffffc02004e2:	bd5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e6:	7c0c                	ld	a1,56(s0)
ffffffffc02004e8:	00002517          	auipc	a0,0x2
ffffffffc02004ec:	b5050513          	addi	a0,a0,-1200 # ffffffffc0202038 <commands+0x360>
ffffffffc02004f0:	bc7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f4:	602c                	ld	a1,64(s0)
ffffffffc02004f6:	00002517          	auipc	a0,0x2
ffffffffc02004fa:	b5a50513          	addi	a0,a0,-1190 # ffffffffc0202050 <commands+0x378>
ffffffffc02004fe:	bb9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200502:	642c                	ld	a1,72(s0)
ffffffffc0200504:	00002517          	auipc	a0,0x2
ffffffffc0200508:	b6450513          	addi	a0,a0,-1180 # ffffffffc0202068 <commands+0x390>
ffffffffc020050c:	babff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200510:	682c                	ld	a1,80(s0)
ffffffffc0200512:	00002517          	auipc	a0,0x2
ffffffffc0200516:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0202080 <commands+0x3a8>
ffffffffc020051a:	b9dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051e:	6c2c                	ld	a1,88(s0)
ffffffffc0200520:	00002517          	auipc	a0,0x2
ffffffffc0200524:	b7850513          	addi	a0,a0,-1160 # ffffffffc0202098 <commands+0x3c0>
ffffffffc0200528:	b8fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052c:	702c                	ld	a1,96(s0)
ffffffffc020052e:	00002517          	auipc	a0,0x2
ffffffffc0200532:	b8250513          	addi	a0,a0,-1150 # ffffffffc02020b0 <commands+0x3d8>
ffffffffc0200536:	b81ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053a:	742c                	ld	a1,104(s0)
ffffffffc020053c:	00002517          	auipc	a0,0x2
ffffffffc0200540:	b8c50513          	addi	a0,a0,-1140 # ffffffffc02020c8 <commands+0x3f0>
ffffffffc0200544:	b73ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200548:	782c                	ld	a1,112(s0)
ffffffffc020054a:	00002517          	auipc	a0,0x2
ffffffffc020054e:	b9650513          	addi	a0,a0,-1130 # ffffffffc02020e0 <commands+0x408>
ffffffffc0200552:	b65ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200556:	7c2c                	ld	a1,120(s0)
ffffffffc0200558:	00002517          	auipc	a0,0x2
ffffffffc020055c:	ba050513          	addi	a0,a0,-1120 # ffffffffc02020f8 <commands+0x420>
ffffffffc0200560:	b57ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200564:	604c                	ld	a1,128(s0)
ffffffffc0200566:	00002517          	auipc	a0,0x2
ffffffffc020056a:	baa50513          	addi	a0,a0,-1110 # ffffffffc0202110 <commands+0x438>
ffffffffc020056e:	b49ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200572:	644c                	ld	a1,136(s0)
ffffffffc0200574:	00002517          	auipc	a0,0x2
ffffffffc0200578:	bb450513          	addi	a0,a0,-1100 # ffffffffc0202128 <commands+0x450>
ffffffffc020057c:	b3bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200580:	684c                	ld	a1,144(s0)
ffffffffc0200582:	00002517          	auipc	a0,0x2
ffffffffc0200586:	bbe50513          	addi	a0,a0,-1090 # ffffffffc0202140 <commands+0x468>
ffffffffc020058a:	b2dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058e:	6c4c                	ld	a1,152(s0)
ffffffffc0200590:	00002517          	auipc	a0,0x2
ffffffffc0200594:	bc850513          	addi	a0,a0,-1080 # ffffffffc0202158 <commands+0x480>
ffffffffc0200598:	b1fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059c:	704c                	ld	a1,160(s0)
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202170 <commands+0x498>
ffffffffc02005a6:	b11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005aa:	744c                	ld	a1,168(s0)
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202188 <commands+0x4b0>
ffffffffc02005b4:	b03ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b8:	784c                	ld	a1,176(s0)
ffffffffc02005ba:	00002517          	auipc	a0,0x2
ffffffffc02005be:	be650513          	addi	a0,a0,-1050 # ffffffffc02021a0 <commands+0x4c8>
ffffffffc02005c2:	af5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c6:	7c4c                	ld	a1,184(s0)
ffffffffc02005c8:	00002517          	auipc	a0,0x2
ffffffffc02005cc:	bf050513          	addi	a0,a0,-1040 # ffffffffc02021b8 <commands+0x4e0>
ffffffffc02005d0:	ae7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d4:	606c                	ld	a1,192(s0)
ffffffffc02005d6:	00002517          	auipc	a0,0x2
ffffffffc02005da:	bfa50513          	addi	a0,a0,-1030 # ffffffffc02021d0 <commands+0x4f8>
ffffffffc02005de:	ad9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e2:	646c                	ld	a1,200(s0)
ffffffffc02005e4:	00002517          	auipc	a0,0x2
ffffffffc02005e8:	c0450513          	addi	a0,a0,-1020 # ffffffffc02021e8 <commands+0x510>
ffffffffc02005ec:	acbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f0:	686c                	ld	a1,208(s0)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0202200 <commands+0x528>
ffffffffc02005fa:	abdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200600:	00002517          	auipc	a0,0x2
ffffffffc0200604:	c1850513          	addi	a0,a0,-1000 # ffffffffc0202218 <commands+0x540>
ffffffffc0200608:	aafff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060c:	706c                	ld	a1,224(s0)
ffffffffc020060e:	00002517          	auipc	a0,0x2
ffffffffc0200612:	c2250513          	addi	a0,a0,-990 # ffffffffc0202230 <commands+0x558>
ffffffffc0200616:	aa1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061a:	746c                	ld	a1,232(s0)
ffffffffc020061c:	00002517          	auipc	a0,0x2
ffffffffc0200620:	c2c50513          	addi	a0,a0,-980 # ffffffffc0202248 <commands+0x570>
ffffffffc0200624:	a93ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200628:	786c                	ld	a1,240(s0)
ffffffffc020062a:	00002517          	auipc	a0,0x2
ffffffffc020062e:	c3650513          	addi	a0,a0,-970 # ffffffffc0202260 <commands+0x588>
ffffffffc0200632:	a85ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200638:	6402                	ld	s0,0(sp)
ffffffffc020063a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	c3c50513          	addi	a0,a0,-964 # ffffffffc0202278 <commands+0x5a0>
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
ffffffffc0200656:	c3e50513          	addi	a0,a0,-962 # ffffffffc0202290 <commands+0x5b8>
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
ffffffffc020066e:	c3e50513          	addi	a0,a0,-962 # ffffffffc02022a8 <commands+0x5d0>
ffffffffc0200672:	a45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	c4650513          	addi	a0,a0,-954 # ffffffffc02022c0 <commands+0x5e8>
ffffffffc0200682:	a35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	c4e50513          	addi	a0,a0,-946 # ffffffffc02022d8 <commands+0x600>
ffffffffc0200692:	a25ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	c5250513          	addi	a0,a0,-942 # ffffffffc02022f0 <commands+0x618>
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
ffffffffc02006c0:	7d870713          	addi	a4,a4,2008 # ffffffffc0201e94 <commands+0x1bc>
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
ffffffffc02006ce:	00002517          	auipc	a0,0x2
ffffffffc02006d2:	85a50513          	addi	a0,a0,-1958 # ffffffffc0201f28 <commands+0x250>
ffffffffc02006d6:	9e1ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc02006da:	00002517          	auipc	a0,0x2
ffffffffc02006de:	82e50513          	addi	a0,a0,-2002 # ffffffffc0201f08 <commands+0x230>
ffffffffc02006e2:	9d5ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc02006e6:	00001517          	auipc	a0,0x1
ffffffffc02006ea:	7e250513          	addi	a0,a0,2018 # ffffffffc0201ec8 <commands+0x1f0>
ffffffffc02006ee:	9c9ff06f          	j	ffffffffc02000b6 <cprintf>
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
ffffffffc02006f2:	00002517          	auipc	a0,0x2
ffffffffc02006f6:	85650513          	addi	a0,a0,-1962 # ffffffffc0201f48 <commands+0x270>
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
ffffffffc020072e:	00002517          	auipc	a0,0x2
ffffffffc0200732:	84250513          	addi	a0,a0,-1982 # ffffffffc0201f70 <commands+0x298>
ffffffffc0200736:	981ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc020073a:	00001517          	auipc	a0,0x1
ffffffffc020073e:	7ae50513          	addi	a0,a0,1966 # ffffffffc0201ee8 <commands+0x210>
ffffffffc0200742:	975ff06f          	j	ffffffffc02000b6 <cprintf>
        print_trapframe(tf);
ffffffffc0200746:	f05ff06f          	j	ffffffffc020064a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020074a:	06400593          	li	a1,100
ffffffffc020074e:	00002517          	auipc	a0,0x2
ffffffffc0200752:	81250513          	addi	a0,a0,-2030 # ffffffffc0201f60 <commands+0x288>
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
ffffffffc0200780:	396010ef          	jal	ra,ffffffffc0201b16 <sbi_shutdown>
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
ffffffffc0200890:	c5f1                	beqz	a1,ffffffffc020095c <buddy_system_init_memmap+0xd0>
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
ffffffffc02008ce:	c7bd                	beqz	a5,ffffffffc020093c <buddy_system_init_memmap+0xb0>
ffffffffc02008d0:	87aa                	mv	a5,a0
        p->property = -1; // 全部初始化为非头页
ffffffffc02008d2:	587d                	li	a6,-1
ffffffffc02008d4:	a021                	j	ffffffffc02008dc <buddy_system_init_memmap+0x50>
ffffffffc02008d6:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02008d8:	8b05                	andi	a4,a4,1
ffffffffc02008da:	c32d                	beqz	a4,ffffffffc020093c <buddy_system_init_memmap+0xb0>
        p->flags = 0;     // 清除所有flag标记
ffffffffc02008dc:	0007b423          	sd	zero,8(a5)
        p->property = -1; // 全部初始化为非头页
ffffffffc02008e0:	0107a823          	sw	a6,16(a5)

//获取 Page 结构体中的 ref 成员，即页面的引用计数。
static inline int page_ref(struct Page *page) { return page->ref; }

//设置 Page 结构体中的 ref 成员，即页面的引用计数
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
ffffffffc020091e:	07a1                	addi	a5,a5,8
ffffffffc0200920:	00b83823          	sd	a1,16(a6)
ffffffffc0200924:	97b6                	add	a5,a5,a3
    elm->next = next;
ffffffffc0200926:	f118                	sd	a4,32(a0)
    elm->prev = prev;
ffffffffc0200928:	ed1c                	sd	a5,24(a0)
    base->property = max_order; // 将第一页base的property设为最大块的2幂
ffffffffc020092a:	c910                	sw	a2,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020092c:	4789                	li	a5,2
ffffffffc020092e:	00850713          	addi	a4,a0,8
ffffffffc0200932:	40f7302f          	amoor.d	zero,a5,(a4)
}
ffffffffc0200936:	60a2                	ld	ra,8(sp)
ffffffffc0200938:	0141                	addi	sp,sp,16
ffffffffc020093a:	8082                	ret
        assert(PageReserved(p));
ffffffffc020093c:	00002697          	auipc	a3,0x2
ffffffffc0200940:	e4468693          	addi	a3,a3,-444 # ffffffffc0202780 <commands+0xaa8>
ffffffffc0200944:	00002617          	auipc	a2,0x2
ffffffffc0200948:	e0460613          	addi	a2,a2,-508 # ffffffffc0202748 <commands+0xa70>
ffffffffc020094c:	09b00593          	li	a1,155
ffffffffc0200950:	00002517          	auipc	a0,0x2
ffffffffc0200954:	e1050513          	addi	a0,a0,-496 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200958:	a55ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc020095c:	00002697          	auipc	a3,0x2
ffffffffc0200960:	de468693          	addi	a3,a3,-540 # ffffffffc0202740 <commands+0xa68>
ffffffffc0200964:	00002617          	auipc	a2,0x2
ffffffffc0200968:	de460613          	addi	a2,a2,-540 # ffffffffc0202748 <commands+0xa70>
ffffffffc020096c:	09200593          	li	a1,146
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	df050513          	addi	a0,a0,-528 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200978:	a35ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020097c <buddy_system_alloc_pages>:
{
ffffffffc020097c:	7179                	addi	sp,sp,-48
ffffffffc020097e:	f406                	sd	ra,40(sp)
ffffffffc0200980:	f022                	sd	s0,32(sp)
ffffffffc0200982:	ec26                	sd	s1,24(sp)
ffffffffc0200984:	e84a                	sd	s2,16(sp)
ffffffffc0200986:	e44e                	sd	s3,8(sp)
    assert(requested_pages > 0);
ffffffffc0200988:	1a050763          	beqz	a0,ffffffffc0200b36 <buddy_system_alloc_pages+0x1ba>
    if (requested_pages > nr_free)
ffffffffc020098c:	00006797          	auipc	a5,0x6
ffffffffc0200990:	bb47e783          	lwu	a5,-1100(a5) # ffffffffc0206540 <buddy_s+0xf8>
ffffffffc0200994:	08a7eb63          	bltu	a5,a0,ffffffffc0200a2a <buddy_system_alloc_pages+0xae>
    if (n & (n - 1))
ffffffffc0200998:	fff50793          	addi	a5,a0,-1
ffffffffc020099c:	8fe9                	and	a5,a5,a0
ffffffffc020099e:	14079f63          	bnez	a5,ffffffffc0200afc <buddy_system_alloc_pages+0x180>
    while (n >> 1)
ffffffffc02009a2:	00155793          	srli	a5,a0,0x1
ffffffffc02009a6:	16078163          	beqz	a5,ffffffffc0200b08 <buddy_system_alloc_pages+0x18c>
    unsigned int order = 0;
ffffffffc02009aa:	4e81                	li	t4,0
ffffffffc02009ac:	a011                	j	ffffffffc02009b0 <buddy_system_alloc_pages+0x34>
        order++;
ffffffffc02009ae:	8eba                	mv	t4,a4
    while (n >> 1)
ffffffffc02009b0:	8385                	srli	a5,a5,0x1
        order++;
ffffffffc02009b2:	001e871b          	addiw	a4,t4,1
    while (n >> 1)
ffffffffc02009b6:	ffe5                	bnez	a5,ffffffffc02009ae <buddy_system_alloc_pages+0x32>
ffffffffc02009b8:	02071793          	slli	a5,a4,0x20
ffffffffc02009bc:	2e89                	addiw	t4,t4,2
ffffffffc02009be:	9381                	srli	a5,a5,0x20
ffffffffc02009c0:	004e9293          	slli	t0,t4,0x4
ffffffffc02009c4:	0792                	slli	a5,a5,0x4
ffffffffc02009c6:	83f6                	mv	t2,t4
ffffffffc02009c8:	89f6                	mv	s3,t4
ffffffffc02009ca:	02a1                	addi	t0,t0,8
ffffffffc02009cc:	00878413          	addi	s0,a5,8
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc02009d0:	00006317          	auipc	t1,0x6
ffffffffc02009d4:	a7830313          	addi	t1,t1,-1416 # ffffffffc0206448 <buddy_s>
    return list->next == list;
ffffffffc02009d8:	00f30e33          	add	t3,t1,a5
ffffffffc02009dc:	010e3783          	ld	a5,16(t3)
ffffffffc02009e0:	00238f93          	addi	t6,t2,2
ffffffffc02009e4:	00439493          	slli	s1,t2,0x4
ffffffffc02009e8:	0f92                	slli	t6,t6,0x4
ffffffffc02009ea:	941a                	add	s0,s0,t1
                if (!list_empty(&(buddy_array[i])))
ffffffffc02009ec:	929a                	add	t0,t0,t1
ffffffffc02009ee:	9f9a                	add	t6,t6,t1
ffffffffc02009f0:	949a                	add	s1,s1,t1
ffffffffc02009f2:	2385                	addiw	t2,t2,1
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b，因为是大块分割的，直接加2的n-1次幂就行
ffffffffc02009f4:	4905                	li	s2,1
ffffffffc02009f6:	4f09                	li	t5,2
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc02009f8:	0cf41863          	bne	s0,a5,ffffffffc0200ac8 <buddy_system_alloc_pages+0x14c>
            for (i = order_of_2 + 1; i <= max_order; ++i)
ffffffffc02009fc:	00032883          	lw	a7,0(t1)
ffffffffc0200a00:	03d8e563          	bltu	a7,t4,ffffffffc0200a2a <buddy_system_alloc_pages+0xae>
                if (!list_empty(&(buddy_array[i])))
ffffffffc0200a04:	689c                	ld	a5,16(s1)
ffffffffc0200a06:	02579b63          	bne	a5,t0,ffffffffc0200a3c <buddy_system_alloc_pages+0xc0>
ffffffffc0200a0a:	871e                	mv	a4,t2
ffffffffc0200a0c:	87fe                	mv	a5,t6
ffffffffc0200a0e:	a811                	j	ffffffffc0200a22 <buddy_system_alloc_pages+0xa6>
ffffffffc0200a10:	638c                	ld	a1,0(a5)
ffffffffc0200a12:	ff878613          	addi	a2,a5,-8
ffffffffc0200a16:	00170813          	addi	a6,a4,1
ffffffffc0200a1a:	07c1                	addi	a5,a5,16
ffffffffc0200a1c:	02c59263          	bne	a1,a2,ffffffffc0200a40 <buddy_system_alloc_pages+0xc4>
ffffffffc0200a20:	8742                	mv	a4,a6
ffffffffc0200a22:	0007069b          	sext.w	a3,a4
            for (i = order_of_2 + 1; i <= max_order; ++i)
ffffffffc0200a26:	fed8f5e3          	bleu	a3,a7,ffffffffc0200a10 <buddy_system_alloc_pages+0x94>
        return NULL;
ffffffffc0200a2a:	4701                	li	a4,0
}
ffffffffc0200a2c:	70a2                	ld	ra,40(sp)
ffffffffc0200a2e:	7402                	ld	s0,32(sp)
ffffffffc0200a30:	64e2                	ld	s1,24(sp)
ffffffffc0200a32:	6942                	ld	s2,16(sp)
ffffffffc0200a34:	69a2                	ld	s3,8(sp)
ffffffffc0200a36:	853a                	mv	a0,a4
ffffffffc0200a38:	6145                	addi	sp,sp,48
ffffffffc0200a3a:	8082                	ret
                if (!list_empty(&(buddy_array[i])))
ffffffffc0200a3c:	874e                	mv	a4,s3
ffffffffc0200a3e:	86f6                	mv	a3,t4
    assert(n > 0 && n <= max_order);
ffffffffc0200a40:	cb79                	beqz	a4,ffffffffc0200b16 <buddy_system_alloc_pages+0x19a>
ffffffffc0200a42:	1882                	slli	a7,a7,0x20
ffffffffc0200a44:	0208d893          	srli	a7,a7,0x20
ffffffffc0200a48:	0ce8e763          	bltu	a7,a4,ffffffffc0200b16 <buddy_system_alloc_pages+0x19a>
ffffffffc0200a4c:	00471793          	slli	a5,a4,0x4
ffffffffc0200a50:	00f30633          	add	a2,t1,a5
ffffffffc0200a54:	6a10                	ld	a2,16(a2)
    assert(!list_empty(&(buddy_array[n])));
ffffffffc0200a56:	07a1                	addi	a5,a5,8
ffffffffc0200a58:	979a                	add	a5,a5,t1
ffffffffc0200a5a:	0ef60e63          	beq	a2,a5,ffffffffc0200b56 <buddy_system_alloc_pages+0x1da>
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b，因为是大块分割的，直接加2的n-1次幂就行
ffffffffc0200a5e:	fff7059b          	addiw	a1,a4,-1
ffffffffc0200a62:	00b9183b          	sllw	a6,s2,a1
ffffffffc0200a66:	00281793          	slli	a5,a6,0x2
ffffffffc0200a6a:	97c2                	add	a5,a5,a6
ffffffffc0200a6c:	078e                	slli	a5,a5,0x3
ffffffffc0200a6e:	17a1                	addi	a5,a5,-24
    page_a->property = n - 1;
ffffffffc0200a70:	feb62c23          	sw	a1,-8(a2)
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b，因为是大块分割的，直接加2的n-1次幂就行
ffffffffc0200a74:	97b2                	add	a5,a5,a2
    page_b->property = n - 1;
ffffffffc0200a76:	cb8c                	sw	a1,16(a5)
ffffffffc0200a78:	ff060593          	addi	a1,a2,-16
ffffffffc0200a7c:	41e5b02f          	amoor.d	zero,t5,(a1)
ffffffffc0200a80:	00878593          	addi	a1,a5,8
ffffffffc0200a84:	41e5b02f          	amoor.d	zero,t5,(a1)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a88:	660c                	ld	a1,8(a2)
ffffffffc0200a8a:	00063883          	ld	a7,0(a2)
    list_add(&(buddy_array[n - 1]), &(page_a->page_link));
ffffffffc0200a8e:	177d                	addi	a4,a4,-1
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a90:	0712                	slli	a4,a4,0x4
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next)
{
    prev->next = next;
ffffffffc0200a92:	00b8b423          	sd	a1,8(a7)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a96:	00e30833          	add	a6,t1,a4
    next->prev = prev;
ffffffffc0200a9a:	0115b023          	sd	a7,0(a1)
ffffffffc0200a9e:	0721                	addi	a4,a4,8
    __list_add(elm, listelm, listelm->next);
ffffffffc0200aa0:	01083583          	ld	a1,16(a6)
ffffffffc0200aa4:	971a                	add	a4,a4,t1
    prev->next = next->prev = elm;
ffffffffc0200aa6:	00c83823          	sd	a2,16(a6)
    elm->prev = prev;
ffffffffc0200aaa:	e218                	sd	a4,0(a2)
    list_add(&(page_a->page_link), &(page_b->page_link));
ffffffffc0200aac:	01878713          	addi	a4,a5,24
    prev->next = next->prev = elm;
ffffffffc0200ab0:	e198                	sd	a4,0(a1)
            if (i > max_order)
ffffffffc0200ab2:	00032803          	lw	a6,0(t1)
ffffffffc0200ab6:	e618                	sd	a4,8(a2)
    elm->next = next;
ffffffffc0200ab8:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc0200aba:	ef90                	sd	a2,24(a5)
ffffffffc0200abc:	f6d867e3          	bltu	a6,a3,ffffffffc0200a2a <buddy_system_alloc_pages+0xae>
    return list->next == list;
ffffffffc0200ac0:	010e3783          	ld	a5,16(t3)
        if (!list_empty(&(buddy_array[order_of_2])))
ffffffffc0200ac4:	f2f40ce3          	beq	s0,a5,ffffffffc02009fc <buddy_system_alloc_pages+0x80>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200ac8:	6794                	ld	a3,8(a5)
ffffffffc0200aca:	6390                	ld	a2,0(a5)
            allocated_page = le2page(list_next(&(buddy_array[order_of_2])), page_link);
ffffffffc0200acc:	fe878713          	addi	a4,a5,-24
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200ad0:	17c1                	addi	a5,a5,-16
    prev->next = next;
ffffffffc0200ad2:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0200ad4:	e290                	sd	a2,0(a3)
ffffffffc0200ad6:	56f5                	li	a3,-3
ffffffffc0200ad8:	60d7b02f          	amoand.d	zero,a3,(a5)
    if (allocated_page != NULL)
ffffffffc0200adc:	db21                	beqz	a4,ffffffffc0200a2c <buddy_system_alloc_pages+0xb0>
        nr_free -= adjusted_pages;
ffffffffc0200ade:	0f832783          	lw	a5,248(t1)
}
ffffffffc0200ae2:	70a2                	ld	ra,40(sp)
ffffffffc0200ae4:	7402                	ld	s0,32(sp)
        nr_free -= adjusted_pages;
ffffffffc0200ae6:	9f89                	subw	a5,a5,a0
ffffffffc0200ae8:	00006697          	auipc	a3,0x6
ffffffffc0200aec:	a4f6ac23          	sw	a5,-1448(a3) # ffffffffc0206540 <buddy_s+0xf8>
}
ffffffffc0200af0:	64e2                	ld	s1,24(sp)
ffffffffc0200af2:	6942                	ld	s2,16(sp)
ffffffffc0200af4:	69a2                	ld	s3,8(sp)
ffffffffc0200af6:	853a                	mv	a0,a4
ffffffffc0200af8:	6145                	addi	sp,sp,48
ffffffffc0200afa:	8082                	ret
    size_t res = 1;
ffffffffc0200afc:	4785                	li	a5,1
            n = n >> 1;
ffffffffc0200afe:	8105                	srli	a0,a0,0x1
            res = res << 1;
ffffffffc0200b00:	0786                	slli	a5,a5,0x1
        while (n)
ffffffffc0200b02:	fd75                	bnez	a0,ffffffffc0200afe <buddy_system_alloc_pages+0x182>
            res = res << 1;
ffffffffc0200b04:	853e                	mv	a0,a5
ffffffffc0200b06:	bd71                	j	ffffffffc02009a2 <buddy_system_alloc_pages+0x26>
    while (n >> 1)
ffffffffc0200b08:	4421                	li	s0,8
ffffffffc0200b0a:	4385                	li	t2,1
ffffffffc0200b0c:	4985                	li	s3,1
ffffffffc0200b0e:	42e1                	li	t0,24
ffffffffc0200b10:	4e85                	li	t4,1
ffffffffc0200b12:	4781                	li	a5,0
ffffffffc0200b14:	bd75                	j	ffffffffc02009d0 <buddy_system_alloc_pages+0x54>
    assert(n > 0 && n <= max_order);
ffffffffc0200b16:	00002697          	auipc	a3,0x2
ffffffffc0200b1a:	80a68693          	addi	a3,a3,-2038 # ffffffffc0202320 <commands+0x648>
ffffffffc0200b1e:	00002617          	auipc	a2,0x2
ffffffffc0200b22:	c2a60613          	addi	a2,a2,-982 # ffffffffc0202748 <commands+0xa70>
ffffffffc0200b26:	04a00593          	li	a1,74
ffffffffc0200b2a:	00002517          	auipc	a0,0x2
ffffffffc0200b2e:	c3650513          	addi	a0,a0,-970 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200b32:	87bff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(requested_pages > 0);
ffffffffc0200b36:	00001697          	auipc	a3,0x1
ffffffffc0200b3a:	7d268693          	addi	a3,a3,2002 # ffffffffc0202308 <commands+0x630>
ffffffffc0200b3e:	00002617          	auipc	a2,0x2
ffffffffc0200b42:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0202748 <commands+0xa70>
ffffffffc0200b46:	0ac00593          	li	a1,172
ffffffffc0200b4a:	00002517          	auipc	a0,0x2
ffffffffc0200b4e:	c1650513          	addi	a0,a0,-1002 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200b52:	85bff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!list_empty(&(buddy_array[n])));
ffffffffc0200b56:	00001697          	auipc	a3,0x1
ffffffffc0200b5a:	7e268693          	addi	a3,a3,2018 # ffffffffc0202338 <commands+0x660>
ffffffffc0200b5e:	00002617          	auipc	a2,0x2
ffffffffc0200b62:	bea60613          	addi	a2,a2,-1046 # ffffffffc0202748 <commands+0xa70>
ffffffffc0200b66:	04b00593          	li	a1,75
ffffffffc0200b6a:	00002517          	auipc	a0,0x2
ffffffffc0200b6e:	bf650513          	addi	a0,a0,-1034 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200b72:	83bff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200b76 <show_buddy_array.constprop.4>:
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200b76:	00006797          	auipc	a5,0x6
ffffffffc0200b7a:	8d278793          	addi	a5,a5,-1838 # ffffffffc0206448 <buddy_s>
ffffffffc0200b7e:	4398                	lw	a4,0(a5)
show_buddy_array(int left, int right) // 左闭右闭
ffffffffc0200b80:	711d                	addi	sp,sp,-96
ffffffffc0200b82:	ec86                	sd	ra,88(sp)
ffffffffc0200b84:	e8a2                	sd	s0,80(sp)
ffffffffc0200b86:	e4a6                	sd	s1,72(sp)
ffffffffc0200b88:	e0ca                	sd	s2,64(sp)
ffffffffc0200b8a:	fc4e                	sd	s3,56(sp)
ffffffffc0200b8c:	f852                	sd	s4,48(sp)
ffffffffc0200b8e:	f456                	sd	s5,40(sp)
ffffffffc0200b90:	f05a                	sd	s6,32(sp)
ffffffffc0200b92:	ec5e                	sd	s7,24(sp)
ffffffffc0200b94:	e862                	sd	s8,16(sp)
ffffffffc0200b96:	e466                	sd	s9,8(sp)
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200b98:	47b5                	li	a5,13
ffffffffc0200b9a:	0ae7fc63          	bleu	a4,a5,ffffffffc0200c52 <show_buddy_array.constprop.4+0xdc>
    cprintf("==================显示空闲链表数组==================\n");
ffffffffc0200b9e:	00002517          	auipc	a0,0x2
ffffffffc0200ba2:	c7250513          	addi	a0,a0,-910 # ffffffffc0202810 <buddy_system_pmm_manager+0x80>
ffffffffc0200ba6:	d10ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    for (int i = left; i <= right; i++)
ffffffffc0200baa:	00006497          	auipc	s1,0x6
ffffffffc0200bae:	8a648493          	addi	s1,s1,-1882 # ffffffffc0206450 <buddy_s+0x8>
    bool empty = 1; // 表示空闲链表数组为空
ffffffffc0200bb2:	4785                	li	a5,1
    for (int i = left; i <= right; i++)
ffffffffc0200bb4:	4901                	li	s2,0
                cprintf("No.%d的空闲链表有", i);
ffffffffc0200bb6:	00002b17          	auipc	s6,0x2
ffffffffc0200bba:	c9ab0b13          	addi	s6,s6,-870 # ffffffffc0202850 <buddy_system_pmm_manager+0xc0>
                cprintf("%d页 ", 1 << (p->property));
ffffffffc0200bbe:	4a85                	li	s5,1
ffffffffc0200bc0:	00002a17          	auipc	s4,0x2
ffffffffc0200bc4:	ca8a0a13          	addi	s4,s4,-856 # ffffffffc0202868 <buddy_system_pmm_manager+0xd8>
                cprintf("【地址为%p】\n", p);
ffffffffc0200bc8:	00002997          	auipc	s3,0x2
ffffffffc0200bcc:	ca898993          	addi	s3,s3,-856 # ffffffffc0202870 <buddy_system_pmm_manager+0xe0>
            if (i != right)
ffffffffc0200bd0:	4c39                	li	s8,14
                cprintf("\n");
ffffffffc0200bd2:	00002c97          	auipc	s9,0x2
ffffffffc0200bd6:	a3ec8c93          	addi	s9,s9,-1474 # ffffffffc0202610 <commands+0x938>
    for (int i = left; i <= right; i++)
ffffffffc0200bda:	4bbd                	li	s7,15
ffffffffc0200bdc:	a029                	j	ffffffffc0200be6 <show_buddy_array.constprop.4+0x70>
ffffffffc0200bde:	2905                	addiw	s2,s2,1
ffffffffc0200be0:	04c1                	addi	s1,s1,16
ffffffffc0200be2:	03790f63          	beq	s2,s7,ffffffffc0200c20 <show_buddy_array.constprop.4+0xaa>
    return listelm->next;
ffffffffc0200be6:	6480                	ld	s0,8(s1)
        if (list_next(le) != &buddy_array[i])
ffffffffc0200be8:	fe940be3          	beq	s0,s1,ffffffffc0200bde <show_buddy_array.constprop.4+0x68>
                cprintf("No.%d的空闲链表有", i);
ffffffffc0200bec:	85ca                	mv	a1,s2
ffffffffc0200bee:	855a                	mv	a0,s6
ffffffffc0200bf0:	cc6ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
                cprintf("%d页 ", 1 << (p->property));
ffffffffc0200bf4:	ff842583          	lw	a1,-8(s0)
ffffffffc0200bf8:	8552                	mv	a0,s4
ffffffffc0200bfa:	00ba95bb          	sllw	a1,s5,a1
ffffffffc0200bfe:	cb8ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
                cprintf("【地址为%p】\n", p);
ffffffffc0200c02:	fe840593          	addi	a1,s0,-24
ffffffffc0200c06:	854e                	mv	a0,s3
ffffffffc0200c08:	caeff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200c0c:	6400                	ld	s0,8(s0)
            while ((le = list_next(le)) != &buddy_array[i])
ffffffffc0200c0e:	fc941fe3          	bne	s0,s1,ffffffffc0200bec <show_buddy_array.constprop.4+0x76>
            if (i != right)
ffffffffc0200c12:	01890e63          	beq	s2,s8,ffffffffc0200c2e <show_buddy_array.constprop.4+0xb8>
                cprintf("\n");
ffffffffc0200c16:	8566                	mv	a0,s9
ffffffffc0200c18:	c9eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
            empty = 0;
ffffffffc0200c1c:	4781                	li	a5,0
ffffffffc0200c1e:	b7c1                	j	ffffffffc0200bde <show_buddy_array.constprop.4+0x68>
    if (empty)
ffffffffc0200c20:	c799                	beqz	a5,ffffffffc0200c2e <show_buddy_array.constprop.4+0xb8>
        cprintf("无空闲块！！！\n");
ffffffffc0200c22:	00002517          	auipc	a0,0x2
ffffffffc0200c26:	c6650513          	addi	a0,a0,-922 # ffffffffc0202888 <buddy_system_pmm_manager+0xf8>
ffffffffc0200c2a:	c8cff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
}
ffffffffc0200c2e:	6446                	ld	s0,80(sp)
ffffffffc0200c30:	60e6                	ld	ra,88(sp)
ffffffffc0200c32:	64a6                	ld	s1,72(sp)
ffffffffc0200c34:	6906                	ld	s2,64(sp)
ffffffffc0200c36:	79e2                	ld	s3,56(sp)
ffffffffc0200c38:	7a42                	ld	s4,48(sp)
ffffffffc0200c3a:	7aa2                	ld	s5,40(sp)
ffffffffc0200c3c:	7b02                	ld	s6,32(sp)
ffffffffc0200c3e:	6be2                	ld	s7,24(sp)
ffffffffc0200c40:	6c42                	ld	s8,16(sp)
ffffffffc0200c42:	6ca2                	ld	s9,8(sp)
    cprintf("======================显示完成======================\n\n\n");
ffffffffc0200c44:	00002517          	auipc	a0,0x2
ffffffffc0200c48:	c5c50513          	addi	a0,a0,-932 # ffffffffc02028a0 <buddy_system_pmm_manager+0x110>
}
ffffffffc0200c4c:	6125                	addi	sp,sp,96
    cprintf("======================显示完成======================\n\n\n");
ffffffffc0200c4e:	c68ff06f          	j	ffffffffc02000b6 <cprintf>
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200c52:	00002697          	auipc	a3,0x2
ffffffffc0200c56:	b7668693          	addi	a3,a3,-1162 # ffffffffc02027c8 <buddy_system_pmm_manager+0x38>
ffffffffc0200c5a:	00002617          	auipc	a2,0x2
ffffffffc0200c5e:	aee60613          	addi	a2,a2,-1298 # ffffffffc0202748 <commands+0xa70>
ffffffffc0200c62:	06300593          	li	a1,99
ffffffffc0200c66:	00002517          	auipc	a0,0x2
ffffffffc0200c6a:	afa50513          	addi	a0,a0,-1286 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200c6e:	f3eff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200c72 <buddy_system_check>:

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
buddy_system_check(void)
{
ffffffffc0200c72:	7179                	addi	sp,sp,-48
ffffffffc0200c74:	e44e                	sd	s3,8(sp)
    cprintf("总空闲块数目为：%d\n", nr_free);
ffffffffc0200c76:	00005997          	auipc	s3,0x5
ffffffffc0200c7a:	7d298993          	addi	s3,s3,2002 # ffffffffc0206448 <buddy_s>
ffffffffc0200c7e:	0f89a583          	lw	a1,248(s3)
ffffffffc0200c82:	00001517          	auipc	a0,0x1
ffffffffc0200c86:	6de50513          	addi	a0,a0,1758 # ffffffffc0202360 <commands+0x688>
{
ffffffffc0200c8a:	f406                	sd	ra,40(sp)
ffffffffc0200c8c:	f022                	sd	s0,32(sp)
ffffffffc0200c8e:	ec26                	sd	s1,24(sp)
ffffffffc0200c90:	e84a                	sd	s2,16(sp)
    cprintf("总空闲块数目为：%d\n", nr_free);
ffffffffc0200c92:	c24ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("首先p0请求5页\n");
ffffffffc0200c96:	00001517          	auipc	a0,0x1
ffffffffc0200c9a:	6ea50513          	addi	a0,a0,1770 # ffffffffc0202380 <commands+0x6a8>
ffffffffc0200c9e:	c18ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    p0 = alloc_pages(5);
ffffffffc0200ca2:	4515                	li	a0,5
ffffffffc0200ca4:	586000ef          	jal	ra,ffffffffc020122a <alloc_pages>
ffffffffc0200ca8:	84aa                	mv	s1,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200caa:	ecdff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>
    cprintf("然后p1请求5页\n");
ffffffffc0200cae:	00001517          	auipc	a0,0x1
ffffffffc0200cb2:	6ea50513          	addi	a0,a0,1770 # ffffffffc0202398 <commands+0x6c0>
ffffffffc0200cb6:	c00ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    p1 = alloc_pages(5);
ffffffffc0200cba:	4515                	li	a0,5
ffffffffc0200cbc:	56e000ef          	jal	ra,ffffffffc020122a <alloc_pages>
ffffffffc0200cc0:	842a                	mv	s0,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200cc2:	eb5ff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>
    cprintf("最后p2请求5页\n");
ffffffffc0200cc6:	00001517          	auipc	a0,0x1
ffffffffc0200cca:	6ea50513          	addi	a0,a0,1770 # ffffffffc02023b0 <commands+0x6d8>
ffffffffc0200cce:	be8ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    p2 = alloc_pages(5);
ffffffffc0200cd2:	4515                	li	a0,5
ffffffffc0200cd4:	556000ef          	jal	ra,ffffffffc020122a <alloc_pages>
ffffffffc0200cd8:	892a                	mv	s2,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200cda:	e9dff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>
    cprintf("p0的虚拟地址0x%016lx.\n", p0);
ffffffffc0200cde:	85a6                	mv	a1,s1
ffffffffc0200ce0:	00001517          	auipc	a0,0x1
ffffffffc0200ce4:	6e850513          	addi	a0,a0,1768 # ffffffffc02023c8 <commands+0x6f0>
ffffffffc0200ce8:	bceff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("p1的虚拟地址0x%016lx.\n", p1);
ffffffffc0200cec:	85a2                	mv	a1,s0
ffffffffc0200cee:	00001517          	auipc	a0,0x1
ffffffffc0200cf2:	6fa50513          	addi	a0,a0,1786 # ffffffffc02023e8 <commands+0x710>
ffffffffc0200cf6:	bc0ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("p2的虚拟地址0x%016lx.\n", p2);
ffffffffc0200cfa:	85ca                	mv	a1,s2
ffffffffc0200cfc:	00001517          	auipc	a0,0x1
ffffffffc0200d00:	70c50513          	addi	a0,a0,1804 # ffffffffc0202408 <commands+0x730>
ffffffffc0200d04:	bb2ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200d08:	20848063          	beq	s1,s0,ffffffffc0200f08 <buddy_system_check+0x296>
ffffffffc0200d0c:	1f248e63          	beq	s1,s2,ffffffffc0200f08 <buddy_system_check+0x296>
ffffffffc0200d10:	1f240c63          	beq	s0,s2,ffffffffc0200f08 <buddy_system_check+0x296>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200d14:	409c                	lw	a5,0(s1)
ffffffffc0200d16:	22079963          	bnez	a5,ffffffffc0200f48 <buddy_system_check+0x2d6>
ffffffffc0200d1a:	401c                	lw	a5,0(s0)
ffffffffc0200d1c:	22079663          	bnez	a5,ffffffffc0200f48 <buddy_system_check+0x2d6>
ffffffffc0200d20:	00092783          	lw	a5,0(s2)
ffffffffc0200d24:	22079263          	bnez	a5,ffffffffc0200f48 <buddy_system_check+0x2d6>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } 
ffffffffc0200d28:	00006797          	auipc	a5,0x6
ffffffffc0200d2c:	83878793          	addi	a5,a5,-1992 # ffffffffc0206560 <pages>
ffffffffc0200d30:	639c                	ld	a5,0(a5)
ffffffffc0200d32:	00001717          	auipc	a4,0x1
ffffffffc0200d36:	62670713          	addi	a4,a4,1574 # ffffffffc0202358 <commands+0x680>
ffffffffc0200d3a:	630c                	ld	a1,0(a4)
ffffffffc0200d3c:	40f48733          	sub	a4,s1,a5
ffffffffc0200d40:	870d                	srai	a4,a4,0x3
ffffffffc0200d42:	02b70733          	mul	a4,a4,a1
ffffffffc0200d46:	00002697          	auipc	a3,0x2
ffffffffc0200d4a:	0f268693          	addi	a3,a3,242 # ffffffffc0202e38 <nbase>
ffffffffc0200d4e:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200d50:	00005697          	auipc	a3,0x5
ffffffffc0200d54:	6d868693          	addi	a3,a3,1752 # ffffffffc0206428 <npage>
ffffffffc0200d58:	6294                	ld	a3,0(a3)
ffffffffc0200d5a:	06b2                	slli	a3,a3,0xc
ffffffffc0200d5c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d5e:	0732                	slli	a4,a4,0xc
ffffffffc0200d60:	2cd77463          	bleu	a3,a4,ffffffffc0201028 <buddy_system_check+0x3b6>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } 
ffffffffc0200d64:	40f40733          	sub	a4,s0,a5
ffffffffc0200d68:	870d                	srai	a4,a4,0x3
ffffffffc0200d6a:	02b70733          	mul	a4,a4,a1
ffffffffc0200d6e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d70:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d72:	1ed77b63          	bleu	a3,a4,ffffffffc0200f68 <buddy_system_check+0x2f6>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } 
ffffffffc0200d76:	40f907b3          	sub	a5,s2,a5
ffffffffc0200d7a:	878d                	srai	a5,a5,0x3
ffffffffc0200d7c:	02b787b3          	mul	a5,a5,a1
ffffffffc0200d80:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d82:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d84:	20d7f263          	bleu	a3,a5,ffffffffc0200f88 <buddy_system_check+0x316>
    assert(alloc_page() == NULL);
ffffffffc0200d88:	4505                	li	a0,1
    nr_free = 0;
ffffffffc0200d8a:	00005797          	auipc	a5,0x5
ffffffffc0200d8e:	7a07ab23          	sw	zero,1974(a5) # ffffffffc0206540 <buddy_s+0xf8>
    assert(alloc_page() == NULL);
ffffffffc0200d92:	498000ef          	jal	ra,ffffffffc020122a <alloc_pages>
ffffffffc0200d96:	20051963          	bnez	a0,ffffffffc0200fa8 <buddy_system_check+0x336>
    cprintf("释放p0中。。。。。。\n");
ffffffffc0200d9a:	00001517          	auipc	a0,0x1
ffffffffc0200d9e:	76e50513          	addi	a0,a0,1902 # ffffffffc0202508 <commands+0x830>
ffffffffc0200da2:	b14ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(p0, 5);
ffffffffc0200da6:	4595                	li	a1,5
ffffffffc0200da8:	8526                	mv	a0,s1
ffffffffc0200daa:	4c4000ef          	jal	ra,ffffffffc020126e <free_pages>
    cprintf("释放p0后，总空闲块数目为：%d\n", nr_free); // 变成了8
ffffffffc0200dae:	0f89a583          	lw	a1,248(s3)
ffffffffc0200db2:	00001517          	auipc	a0,0x1
ffffffffc0200db6:	77650513          	addi	a0,a0,1910 # ffffffffc0202528 <commands+0x850>
ffffffffc0200dba:	afcff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200dbe:	db9ff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>
    cprintf("释放p1中。。。。。。\n");
ffffffffc0200dc2:	00001517          	auipc	a0,0x1
ffffffffc0200dc6:	79650513          	addi	a0,a0,1942 # ffffffffc0202558 <commands+0x880>
ffffffffc0200dca:	aecff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(p1, 5);
ffffffffc0200dce:	8522                	mv	a0,s0
ffffffffc0200dd0:	4595                	li	a1,5
ffffffffc0200dd2:	49c000ef          	jal	ra,ffffffffc020126e <free_pages>
    cprintf("释放p1后，总空闲块数目为：%d\n", nr_free); // 变成了16
ffffffffc0200dd6:	0f89a583          	lw	a1,248(s3)
ffffffffc0200dda:	00001517          	auipc	a0,0x1
ffffffffc0200dde:	79e50513          	addi	a0,a0,1950 # ffffffffc0202578 <commands+0x8a0>
ffffffffc0200de2:	ad4ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200de6:	d91ff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>
    cprintf("释放p2中。。。。。。\n");
ffffffffc0200dea:	00001517          	auipc	a0,0x1
ffffffffc0200dee:	7be50513          	addi	a0,a0,1982 # ffffffffc02025a8 <commands+0x8d0>
ffffffffc0200df2:	ac4ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(p2, 5);
ffffffffc0200df6:	4595                	li	a1,5
ffffffffc0200df8:	854a                	mv	a0,s2
ffffffffc0200dfa:	474000ef          	jal	ra,ffffffffc020126e <free_pages>
    cprintf("释放p2后，总空闲块数目为：%d\n", nr_free); // 变成了24
ffffffffc0200dfe:	0f89a583          	lw	a1,248(s3)
ffffffffc0200e02:	00001517          	auipc	a0,0x1
ffffffffc0200e06:	7c650513          	addi	a0,a0,1990 # ffffffffc02025c8 <commands+0x8f0>
ffffffffc0200e0a:	aacff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e0e:	d69ff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>
    nr_free = 16384;
ffffffffc0200e12:	6791                	lui	a5,0x4
    struct Page *p3 = alloc_pages(16384);
ffffffffc0200e14:	6511                	lui	a0,0x4
    nr_free = 16384;
ffffffffc0200e16:	00005717          	auipc	a4,0x5
ffffffffc0200e1a:	72f72523          	sw	a5,1834(a4) # ffffffffc0206540 <buddy_s+0xf8>
    struct Page *p3 = alloc_pages(16384);
ffffffffc0200e1e:	40c000ef          	jal	ra,ffffffffc020122a <alloc_pages>
ffffffffc0200e22:	842a                	mv	s0,a0
    cprintf("分配p3之后(16384页)\n");
ffffffffc0200e24:	00001517          	auipc	a0,0x1
ffffffffc0200e28:	7d450513          	addi	a0,a0,2004 # ffffffffc02025f8 <commands+0x920>
ffffffffc0200e2c:	a8aff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e30:	d47ff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>
    free_pages(p3, 16384);
ffffffffc0200e34:	6591                	lui	a1,0x4
ffffffffc0200e36:	8522                	mv	a0,s0
ffffffffc0200e38:	436000ef          	jal	ra,ffffffffc020126e <free_pages>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e3c:	d3bff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>
    basic_check();

    // 一些复杂的操作
    cprintf("==========开始测试一些复杂的例子==========\n");
ffffffffc0200e40:	00001517          	auipc	a0,0x1
ffffffffc0200e44:	7d850513          	addi	a0,a0,2008 # ffffffffc0202618 <commands+0x940>
ffffffffc0200e48:	a6eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("首先p0请求5页\n");
ffffffffc0200e4c:	00001517          	auipc	a0,0x1
ffffffffc0200e50:	53450513          	addi	a0,a0,1332 # ffffffffc0202380 <commands+0x6a8>
ffffffffc0200e54:	a62ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200e58:	4515                	li	a0,5
ffffffffc0200e5a:	3d0000ef          	jal	ra,ffffffffc020122a <alloc_pages>
ffffffffc0200e5e:	842a                	mv	s0,a0
    assert(p0 != NULL);
ffffffffc0200e60:	1a050463          	beqz	a0,ffffffffc0201008 <buddy_system_check+0x396>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e64:	651c                	ld	a5,8(a0)
ffffffffc0200e66:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200e68:	8b85                	andi	a5,a5,1
ffffffffc0200e6a:	16079f63          	bnez	a5,ffffffffc0200fe8 <buddy_system_check+0x376>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e6e:	d09ff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>

    cprintf("然后p1请求15页\n");
ffffffffc0200e72:	00002517          	auipc	a0,0x2
ffffffffc0200e76:	80650513          	addi	a0,a0,-2042 # ffffffffc0202678 <commands+0x9a0>
ffffffffc0200e7a:	a3cff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    p1 = alloc_pages(15);
ffffffffc0200e7e:	453d                	li	a0,15
ffffffffc0200e80:	3aa000ef          	jal	ra,ffffffffc020122a <alloc_pages>
ffffffffc0200e84:	892a                	mv	s2,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e86:	cf1ff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>

    cprintf("最后p2请求21页\n");
ffffffffc0200e8a:	00002517          	auipc	a0,0x2
ffffffffc0200e8e:	80650513          	addi	a0,a0,-2042 # ffffffffc0202690 <commands+0x9b8>
ffffffffc0200e92:	a24ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    p2 = alloc_pages(21);
ffffffffc0200e96:	4555                	li	a0,21
ffffffffc0200e98:	392000ef          	jal	ra,ffffffffc020122a <alloc_pages>
ffffffffc0200e9c:	84aa                	mv	s1,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e9e:	cd9ff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>

    cprintf("p0的虚拟地址0x%016lx.\n", p0);
ffffffffc0200ea2:	85a2                	mv	a1,s0
ffffffffc0200ea4:	00001517          	auipc	a0,0x1
ffffffffc0200ea8:	52450513          	addi	a0,a0,1316 # ffffffffc02023c8 <commands+0x6f0>
ffffffffc0200eac:	a0aff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("p1的虚拟地址0x%016lx.\n", p1);
ffffffffc0200eb0:	85ca                	mv	a1,s2
ffffffffc0200eb2:	00001517          	auipc	a0,0x1
ffffffffc0200eb6:	53650513          	addi	a0,a0,1334 # ffffffffc02023e8 <commands+0x710>
ffffffffc0200eba:	9fcff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("p2的虚拟地址0x%016lx.\n", p2);
ffffffffc0200ebe:	85a6                	mv	a1,s1
ffffffffc0200ec0:	00001517          	auipc	a0,0x1
ffffffffc0200ec4:	54850513          	addi	a0,a0,1352 # ffffffffc0202408 <commands+0x730>
ffffffffc0200ec8:	9eeff0ef          	jal	ra,ffffffffc02000b6 <cprintf>

    // 检查幂次正确
    assert(p0->property == 3 && p1->property == 4 && p2->property == 5);
ffffffffc0200ecc:	4818                	lw	a4,16(s0)
ffffffffc0200ece:	478d                	li	a5,3
ffffffffc0200ed0:	04f71c63          	bne	a4,a5,ffffffffc0200f28 <buddy_system_check+0x2b6>
ffffffffc0200ed4:	01092703          	lw	a4,16(s2)
ffffffffc0200ed8:	4791                	li	a5,4
ffffffffc0200eda:	04f71763          	bne	a4,a5,ffffffffc0200f28 <buddy_system_check+0x2b6>
ffffffffc0200ede:	4898                	lw	a4,16(s1)
ffffffffc0200ee0:	4795                	li	a5,5
ffffffffc0200ee2:	04f71363          	bne	a4,a5,ffffffffc0200f28 <buddy_system_check+0x2b6>

    // 暂存p0，删后分配看看能不能找到
    struct Page *temp = p0;

    free_pages(p0, 5);
ffffffffc0200ee6:	8522                	mv	a0,s0
ffffffffc0200ee8:	4595                	li	a1,5
ffffffffc0200eea:	384000ef          	jal	ra,ffffffffc020126e <free_pages>

    p0 = alloc_pages(5);
ffffffffc0200eee:	4515                	li	a0,5
ffffffffc0200ef0:	33a000ef          	jal	ra,ffffffffc020122a <alloc_pages>
    assert(p0 == temp);
ffffffffc0200ef4:	0ca41a63          	bne	s0,a0,ffffffffc0200fc8 <buddy_system_check+0x356>
    show_buddy_array(0, MAX_BUDDY_ORDER);
}
ffffffffc0200ef8:	7402                	ld	s0,32(sp)
ffffffffc0200efa:	70a2                	ld	ra,40(sp)
ffffffffc0200efc:	64e2                	ld	s1,24(sp)
ffffffffc0200efe:	6942                	ld	s2,16(sp)
ffffffffc0200f00:	69a2                	ld	s3,8(sp)
ffffffffc0200f02:	6145                	addi	sp,sp,48
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200f04:	c73ff06f          	j	ffffffffc0200b76 <show_buddy_array.constprop.4>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f08:	00001697          	auipc	a3,0x1
ffffffffc0200f0c:	52068693          	addi	a3,a3,1312 # ffffffffc0202428 <commands+0x750>
ffffffffc0200f10:	00002617          	auipc	a2,0x2
ffffffffc0200f14:	83860613          	addi	a2,a2,-1992 # ffffffffc0202748 <commands+0xa70>
ffffffffc0200f18:	13700593          	li	a1,311
ffffffffc0200f1c:	00002517          	auipc	a0,0x2
ffffffffc0200f20:	84450513          	addi	a0,a0,-1980 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200f24:	c88ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0->property == 3 && p1->property == 4 && p2->property == 5);
ffffffffc0200f28:	00001697          	auipc	a3,0x1
ffffffffc0200f2c:	78068693          	addi	a3,a3,1920 # ffffffffc02026a8 <commands+0x9d0>
ffffffffc0200f30:	00002617          	auipc	a2,0x2
ffffffffc0200f34:	81860613          	addi	a2,a2,-2024 # ffffffffc0202748 <commands+0xa70>
ffffffffc0200f38:	17c00593          	li	a1,380
ffffffffc0200f3c:	00002517          	auipc	a0,0x2
ffffffffc0200f40:	82450513          	addi	a0,a0,-2012 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200f44:	c68ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f48:	00001697          	auipc	a3,0x1
ffffffffc0200f4c:	50868693          	addi	a3,a3,1288 # ffffffffc0202450 <commands+0x778>
ffffffffc0200f50:	00001617          	auipc	a2,0x1
ffffffffc0200f54:	7f860613          	addi	a2,a2,2040 # ffffffffc0202748 <commands+0xa70>
ffffffffc0200f58:	13800593          	li	a1,312
ffffffffc0200f5c:	00002517          	auipc	a0,0x2
ffffffffc0200f60:	80450513          	addi	a0,a0,-2044 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200f64:	c48ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f68:	00001697          	auipc	a3,0x1
ffffffffc0200f6c:	54868693          	addi	a3,a3,1352 # ffffffffc02024b0 <commands+0x7d8>
ffffffffc0200f70:	00001617          	auipc	a2,0x1
ffffffffc0200f74:	7d860613          	addi	a2,a2,2008 # ffffffffc0202748 <commands+0xa70>
ffffffffc0200f78:	13b00593          	li	a1,315
ffffffffc0200f7c:	00001517          	auipc	a0,0x1
ffffffffc0200f80:	7e450513          	addi	a0,a0,2020 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200f84:	c28ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f88:	00001697          	auipc	a3,0x1
ffffffffc0200f8c:	54868693          	addi	a3,a3,1352 # ffffffffc02024d0 <commands+0x7f8>
ffffffffc0200f90:	00001617          	auipc	a2,0x1
ffffffffc0200f94:	7b860613          	addi	a2,a2,1976 # ffffffffc0202748 <commands+0xa70>
ffffffffc0200f98:	13c00593          	li	a1,316
ffffffffc0200f9c:	00001517          	auipc	a0,0x1
ffffffffc0200fa0:	7c450513          	addi	a0,a0,1988 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200fa4:	c08ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fa8:	00001697          	auipc	a3,0x1
ffffffffc0200fac:	54868693          	addi	a3,a3,1352 # ffffffffc02024f0 <commands+0x818>
ffffffffc0200fb0:	00001617          	auipc	a2,0x1
ffffffffc0200fb4:	79860613          	addi	a2,a2,1944 # ffffffffc0202748 <commands+0xa70>
ffffffffc0200fb8:	14200593          	li	a1,322
ffffffffc0200fbc:	00001517          	auipc	a0,0x1
ffffffffc0200fc0:	7a450513          	addi	a0,a0,1956 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200fc4:	be8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 == temp);
ffffffffc0200fc8:	00001697          	auipc	a3,0x1
ffffffffc0200fcc:	72068693          	addi	a3,a3,1824 # ffffffffc02026e8 <commands+0xa10>
ffffffffc0200fd0:	00001617          	auipc	a2,0x1
ffffffffc0200fd4:	77860613          	addi	a2,a2,1912 # ffffffffc0202748 <commands+0xa70>
ffffffffc0200fd8:	18400593          	li	a1,388
ffffffffc0200fdc:	00001517          	auipc	a0,0x1
ffffffffc0200fe0:	78450513          	addi	a0,a0,1924 # ffffffffc0202760 <commands+0xa88>
ffffffffc0200fe4:	bc8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageProperty(p0));
ffffffffc0200fe8:	00001697          	auipc	a3,0x1
ffffffffc0200fec:	67868693          	addi	a3,a3,1656 # ffffffffc0202660 <commands+0x988>
ffffffffc0200ff0:	00001617          	auipc	a2,0x1
ffffffffc0200ff4:	75860613          	addi	a2,a2,1880 # ffffffffc0202748 <commands+0xa70>
ffffffffc0200ff8:	16c00593          	li	a1,364
ffffffffc0200ffc:	00001517          	auipc	a0,0x1
ffffffffc0201000:	76450513          	addi	a0,a0,1892 # ffffffffc0202760 <commands+0xa88>
ffffffffc0201004:	ba8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != NULL);
ffffffffc0201008:	00001697          	auipc	a3,0x1
ffffffffc020100c:	64868693          	addi	a3,a3,1608 # ffffffffc0202650 <commands+0x978>
ffffffffc0201010:	00001617          	auipc	a2,0x1
ffffffffc0201014:	73860613          	addi	a2,a2,1848 # ffffffffc0202748 <commands+0xa70>
ffffffffc0201018:	16b00593          	li	a1,363
ffffffffc020101c:	00001517          	auipc	a0,0x1
ffffffffc0201020:	74450513          	addi	a0,a0,1860 # ffffffffc0202760 <commands+0xa88>
ffffffffc0201024:	b88ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201028:	00001697          	auipc	a3,0x1
ffffffffc020102c:	46868693          	addi	a3,a3,1128 # ffffffffc0202490 <commands+0x7b8>
ffffffffc0201030:	00001617          	auipc	a2,0x1
ffffffffc0201034:	71860613          	addi	a2,a2,1816 # ffffffffc0202748 <commands+0xa70>
ffffffffc0201038:	13a00593          	li	a1,314
ffffffffc020103c:	00001517          	auipc	a0,0x1
ffffffffc0201040:	72450513          	addi	a0,a0,1828 # ffffffffc0202760 <commands+0xa88>
ffffffffc0201044:	b68ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201048 <buddy_system_free_pages>:
{
ffffffffc0201048:	1101                	addi	sp,sp,-32
ffffffffc020104a:	ec06                	sd	ra,24(sp)
ffffffffc020104c:	e822                	sd	s0,16(sp)
ffffffffc020104e:	e426                	sd	s1,8(sp)
ffffffffc0201050:	e04a                	sd	s2,0(sp)
    assert(n > 0);
ffffffffc0201052:	18058e63          	beqz	a1,ffffffffc02011ee <buddy_system_free_pages+0x1a6>
    unsigned int pnum = 1 << (base->property); // 块中页的数目
ffffffffc0201056:	4918                	lw	a4,16(a0)
    if (n & (n - 1))
ffffffffc0201058:	fff58793          	addi	a5,a1,-1 # 3fff <BASE_ADDRESS-0xffffffffc01fc001>
    unsigned int pnum = 1 << (base->property); // 块中页的数目
ffffffffc020105c:	4485                	li	s1,1
ffffffffc020105e:	00e494bb          	sllw	s1,s1,a4
    if (n & (n - 1))
ffffffffc0201062:	8fed                	and	a5,a5,a1
ffffffffc0201064:	842a                	mv	s0,a0
    unsigned int pnum = 1 << (base->property); // 块中页的数目
ffffffffc0201066:	0004861b          	sext.w	a2,s1
    if (n & (n - 1))
ffffffffc020106a:	14079a63          	bnez	a5,ffffffffc02011be <buddy_system_free_pages+0x176>
    assert(ROUNDUP2(n) == pnum);
ffffffffc020106e:	02049793          	slli	a5,s1,0x20
ffffffffc0201072:	9381                	srli	a5,a5,0x20
ffffffffc0201074:	14b79d63          	bne	a5,a1,ffffffffc02011ce <buddy_system_free_pages+0x186>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } 
ffffffffc0201078:	00005797          	auipc	a5,0x5
ffffffffc020107c:	4e878793          	addi	a5,a5,1256 # ffffffffc0206560 <pages>
ffffffffc0201080:	639c                	ld	a5,0(a5)
ffffffffc0201082:	00001717          	auipc	a4,0x1
ffffffffc0201086:	2d670713          	addi	a4,a4,726 # ffffffffc0202358 <commands+0x680>
ffffffffc020108a:	630c                	ld	a1,0(a4)
ffffffffc020108c:	40f407b3          	sub	a5,s0,a5
ffffffffc0201090:	878d                	srai	a5,a5,0x3
ffffffffc0201092:	02b787b3          	mul	a5,a5,a1
ffffffffc0201096:	00002717          	auipc	a4,0x2
ffffffffc020109a:	da270713          	addi	a4,a4,-606 # ffffffffc0202e38 <nbase>
    cprintf("BS算法将释放第NO.%d页开始的共%d页\n", page2ppn(base), pnum);
ffffffffc020109e:	630c                	ld	a1,0(a4)
ffffffffc02010a0:	00001517          	auipc	a0,0x1
ffffffffc02010a4:	67050513          	addi	a0,a0,1648 # ffffffffc0202710 <commands+0xa38>
ffffffffc02010a8:	95be                	add	a1,a1,a5
ffffffffc02010aa:	80cff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 将当前块先插入对应链表中
ffffffffc02010ae:	4810                	lw	a2,16(s0)
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc02010b0:	4785                	li	a5,1
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc02010b2:	3fdf1e37          	lui	t3,0x3fdf1
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc02010b6:	00c796bb          	sllw	a3,a5,a2
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc02010ba:	00269793          	slli	a5,a3,0x2
    __list_add(elm, listelm, listelm->next);
ffffffffc02010be:	02061713          	slli	a4,a2,0x20
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc02010c2:	ce8e0e13          	addi	t3,t3,-792 # 3fdf0ce8 <BASE_ADDRESS-0xffffffff8040f318>
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc02010c6:	97b6                	add	a5,a5,a3
ffffffffc02010c8:	9301                	srli	a4,a4,0x20
ffffffffc02010ca:	00005817          	auipc	a6,0x5
ffffffffc02010ce:	37e80813          	addi	a6,a6,894 # ffffffffc0206448 <buddy_s>
ffffffffc02010d2:	0712                	slli	a4,a4,0x4
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc02010d4:	01c406b3          	add	a3,s0,t3
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc02010d8:	078e                	slli	a5,a5,0x3
ffffffffc02010da:	00e80533          	add	a0,a6,a4
    size_t buddy_relative_addr = (size_t)relative_block_addr ^ sizeOfPage;      // 异或得到伙伴块的相对地址
ffffffffc02010de:	8fb5                	xor	a5,a5,a3
ffffffffc02010e0:	690c                	ld	a1,16(a0)
    struct Page *buddy_page = (struct Page *)(buddy_relative_addr + mem_begin); // 返回伙伴块指针
ffffffffc02010e2:	41c787b3          	sub	a5,a5,t3
ffffffffc02010e6:	6794                	ld	a3,8(a5)
    list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 将当前块先插入对应链表中
ffffffffc02010e8:	01840893          	addi	a7,s0,24
    prev->next = next->prev = elm;
ffffffffc02010ec:	0115b023          	sd	a7,0(a1)
ffffffffc02010f0:	0721                	addi	a4,a4,8
ffffffffc02010f2:	01153823          	sd	a7,16(a0)
ffffffffc02010f6:	9742                	add	a4,a4,a6
ffffffffc02010f8:	8285                	srli	a3,a3,0x1
    elm->prev = prev;
ffffffffc02010fa:	ec18                	sd	a4,24(s0)
    elm->next = next;
ffffffffc02010fc:	f00c                	sd	a1,32(s0)
    while (PageProperty(buddy) && left_block->property < max_order)
ffffffffc02010fe:	0016f713          	andi	a4,a3,1
ffffffffc0201102:	c761                	beqz	a4,ffffffffc02011ca <buddy_system_free_pages+0x182>
ffffffffc0201104:	00082703          	lw	a4,0(a6)
ffffffffc0201108:	0ce67163          	bleu	a4,a2,ffffffffc02011ca <buddy_system_free_pages+0x182>
ffffffffc020110c:	8622                	mv	a2,s0
            left_block->property = -1; // 将左块幂次置为无效
ffffffffc020110e:	5ffd                	li	t6,-1
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201110:	4f09                	li	t5,2
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc0201112:	4e85                	li	t4,1
        if (left_block > buddy)
ffffffffc0201114:	00c7fb63          	bleu	a2,a5,ffffffffc020112a <buddy_system_free_pages+0xe2>
            left_block->property = -1; // 将左块幂次置为无效
ffffffffc0201118:	01f62823          	sw	t6,16(a2)
ffffffffc020111c:	00840713          	addi	a4,s0,8
ffffffffc0201120:	41e7302f          	amoor.d	zero,t5,(a4)
ffffffffc0201124:	8732                	mv	a4,a2
ffffffffc0201126:	863e                	mv	a2,a5
ffffffffc0201128:	87ba                	mv	a5,a4
    __list_del(listelm->prev, listelm->next);
ffffffffc020112a:	6e14                	ld	a3,24(a2)
ffffffffc020112c:	7218                	ld	a4,32(a2)
        left_block->property += 1; // 左快头页设置幂次加一
ffffffffc020112e:	4a0c                	lw	a1,16(a2)
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量
ffffffffc0201130:	01c60533          	add	a0,a2,t3
    prev->next = next;
ffffffffc0201134:	e698                	sd	a4,8(a3)
        left_block->property += 1; // 左快头页设置幂次加一
ffffffffc0201136:	2585                	addiw	a1,a1,1
    next->prev = prev;
ffffffffc0201138:	e314                	sd	a3,0(a4)
ffffffffc020113a:	0005829b          	sext.w	t0,a1
    __list_del(listelm->prev, listelm->next);
ffffffffc020113e:	0187b903          	ld	s2,24(a5)
ffffffffc0201142:	0207b383          	ld	t2,32(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201146:	02059713          	slli	a4,a1,0x20
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
ffffffffc020114a:	005e97bb          	sllw	a5,t4,t0
    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
ffffffffc020114e:	00279693          	slli	a3,a5,0x2
ffffffffc0201152:	9301                	srli	a4,a4,0x20
ffffffffc0201154:	0712                	slli	a4,a4,0x4
ffffffffc0201156:	96be                	add	a3,a3,a5
    prev->next = next;
ffffffffc0201158:	00793423          	sd	t2,8(s2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020115c:	00e80333          	add	t1,a6,a4
ffffffffc0201160:	068e                	slli	a3,a3,0x3
ffffffffc0201162:	01033883          	ld	a7,16(t1)
    size_t buddy_relative_addr = (size_t)relative_block_addr ^ sizeOfPage;      // 异或得到伙伴块的相对地址
ffffffffc0201166:	00a6c7b3          	xor	a5,a3,a0
    next->prev = prev;
ffffffffc020116a:	0123b023          	sd	s2,0(t2)
    struct Page *buddy_page = (struct Page *)(buddy_relative_addr + mem_begin); // 返回伙伴块指针
ffffffffc020116e:	41c787b3          	sub	a5,a5,t3
        left_block->property += 1; // 左快头页设置幂次加一
ffffffffc0201172:	ca0c                	sw	a1,16(a2)
        list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 头插入相应链表
ffffffffc0201174:	01860693          	addi	a3,a2,24
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201178:	678c                	ld	a1,8(a5)
ffffffffc020117a:	0721                	addi	a4,a4,8
    prev->next = next->prev = elm;
ffffffffc020117c:	00d8b023          	sd	a3,0(a7)
ffffffffc0201180:	00d33823          	sd	a3,16(t1)
ffffffffc0201184:	9742                	add	a4,a4,a6
    elm->prev = prev;
ffffffffc0201186:	ee18                	sd	a4,24(a2)
    elm->next = next;
ffffffffc0201188:	03163023          	sd	a7,32(a2)
    while (PageProperty(buddy) && left_block->property < max_order)
ffffffffc020118c:	0025f713          	andi	a4,a1,2
ffffffffc0201190:	c709                	beqz	a4,ffffffffc020119a <buddy_system_free_pages+0x152>
ffffffffc0201192:	00082703          	lw	a4,0(a6)
ffffffffc0201196:	f6e2efe3          	bltu	t0,a4,ffffffffc0201114 <buddy_system_free_pages+0xcc>
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020119a:	4789                	li	a5,2
ffffffffc020119c:	00860713          	addi	a4,a2,8
ffffffffc02011a0:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += pnum;
ffffffffc02011a4:	0f882783          	lw	a5,248(a6)
}
ffffffffc02011a8:	60e2                	ld	ra,24(sp)
ffffffffc02011aa:	6442                	ld	s0,16(sp)
    nr_free += pnum;
ffffffffc02011ac:	9cbd                	addw	s1,s1,a5
ffffffffc02011ae:	00005797          	auipc	a5,0x5
ffffffffc02011b2:	3897a923          	sw	s1,914(a5) # ffffffffc0206540 <buddy_s+0xf8>
}
ffffffffc02011b6:	6902                	ld	s2,0(sp)
ffffffffc02011b8:	64a2                	ld	s1,8(sp)
ffffffffc02011ba:	6105                	addi	sp,sp,32
ffffffffc02011bc:	8082                	ret
    size_t res = 1;
ffffffffc02011be:	4785                	li	a5,1
            n = n >> 1;
ffffffffc02011c0:	8185                	srli	a1,a1,0x1
            res = res << 1;
ffffffffc02011c2:	0786                	slli	a5,a5,0x1
        while (n)
ffffffffc02011c4:	fdf5                	bnez	a1,ffffffffc02011c0 <buddy_system_free_pages+0x178>
            res = res << 1;
ffffffffc02011c6:	85be                	mv	a1,a5
ffffffffc02011c8:	b55d                	j	ffffffffc020106e <buddy_system_free_pages+0x26>
    while (PageProperty(buddy) && left_block->property < max_order)
ffffffffc02011ca:	8622                	mv	a2,s0
ffffffffc02011cc:	b7f9                	j	ffffffffc020119a <buddy_system_free_pages+0x152>
    assert(ROUNDUP2(n) == pnum);
ffffffffc02011ce:	00001697          	auipc	a3,0x1
ffffffffc02011d2:	52a68693          	addi	a3,a3,1322 # ffffffffc02026f8 <commands+0xa20>
ffffffffc02011d6:	00001617          	auipc	a2,0x1
ffffffffc02011da:	57260613          	addi	a2,a2,1394 # ffffffffc0202748 <commands+0xa70>
ffffffffc02011de:	0ef00593          	li	a1,239
ffffffffc02011e2:	00001517          	auipc	a0,0x1
ffffffffc02011e6:	57e50513          	addi	a0,a0,1406 # ffffffffc0202760 <commands+0xa88>
ffffffffc02011ea:	9c2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc02011ee:	00001697          	auipc	a3,0x1
ffffffffc02011f2:	55268693          	addi	a3,a3,1362 # ffffffffc0202740 <commands+0xa68>
ffffffffc02011f6:	00001617          	auipc	a2,0x1
ffffffffc02011fa:	55260613          	addi	a2,a2,1362 # ffffffffc0202748 <commands+0xa70>
ffffffffc02011fe:	0ed00593          	li	a1,237
ffffffffc0201202:	00001517          	auipc	a0,0x1
ffffffffc0201206:	55e50513          	addi	a0,a0,1374 # ffffffffc0202760 <commands+0xa88>
ffffffffc020120a:	9a2ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020120e <pa2page.part.0>:
它的作用是将物理地址转换为对应的 Page 结构体指针。
通过 PPN 宏获取物理页面号，然后判断物理页面号是否大于等于全局变量 npage
如果是，则表示物理地址无效，会触发 panic 异常
如果物理地址有效，则通过 pages 数组和物理页面号计算出对应的 Page 结构体指针，并返回该指针。
*/
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc020120e:	1141                	addi	sp,sp,-16
{
    if (PPN(pa) >= npage)
    {
        panic("pa2page called with invalid pa");
ffffffffc0201210:	00001617          	auipc	a2,0x1
ffffffffc0201214:	6f060613          	addi	a2,a2,1776 # ffffffffc0202900 <buddy_system_pmm_manager+0x170>
ffffffffc0201218:	08200593          	li	a1,130
ffffffffc020121c:	00001517          	auipc	a0,0x1
ffffffffc0201220:	70450513          	addi	a0,a0,1796 # ffffffffc0202920 <buddy_system_pmm_manager+0x190>
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc0201224:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201226:	986ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020122a <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020122a:	100027f3          	csrr	a5,sstatus
ffffffffc020122e:	8b89                	andi	a5,a5,2
ffffffffc0201230:	eb89                	bnez	a5,ffffffffc0201242 <alloc_pages+0x18>
    // 为确保内存管理修改相关数据时不被中断打断，提供两个功能，
    // 一个是保存 sstatus寄存器中的中断使能位(SIE)信息并屏蔽中断的功能，
    // 另一个是根据保存的中断使能位信息来使能中断的功能
    local_intr_save(intr_flag); // 禁止中断，保证物理内存管理器的操作原子性，即不能被其他中断打断
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201232:	00005797          	auipc	a5,0x5
ffffffffc0201236:	31e78793          	addi	a5,a5,798 # ffffffffc0206550 <pmm_manager>
ffffffffc020123a:	639c                	ld	a5,0(a5)
ffffffffc020123c:	0187b303          	ld	t1,24(a5)
ffffffffc0201240:	8302                	jr	t1
{
ffffffffc0201242:	1141                	addi	sp,sp,-16
ffffffffc0201244:	e406                	sd	ra,8(sp)
ffffffffc0201246:	e022                	sd	s0,0(sp)
ffffffffc0201248:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020124a:	a1aff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020124e:	00005797          	auipc	a5,0x5
ffffffffc0201252:	30278793          	addi	a5,a5,770 # ffffffffc0206550 <pmm_manager>
ffffffffc0201256:	639c                	ld	a5,0(a5)
ffffffffc0201258:	8522                	mv	a0,s0
ffffffffc020125a:	6f9c                	ld	a5,24(a5)
ffffffffc020125c:	9782                	jalr	a5
ffffffffc020125e:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201260:	9feff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag); // 恢复中断
    return page;
}
ffffffffc0201264:	8522                	mv	a0,s0
ffffffffc0201266:	60a2                	ld	ra,8(sp)
ffffffffc0201268:	6402                	ld	s0,0(sp)
ffffffffc020126a:	0141                	addi	sp,sp,16
ffffffffc020126c:	8082                	ret

ffffffffc020126e <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020126e:	100027f3          	csrr	a5,sstatus
ffffffffc0201272:	8b89                	andi	a5,a5,2
ffffffffc0201274:	eb89                	bnez	a5,ffffffffc0201286 <free_pages+0x18>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201276:	00005797          	auipc	a5,0x5
ffffffffc020127a:	2da78793          	addi	a5,a5,730 # ffffffffc0206550 <pmm_manager>
ffffffffc020127e:	639c                	ld	a5,0(a5)
ffffffffc0201280:	0207b303          	ld	t1,32(a5)
ffffffffc0201284:	8302                	jr	t1
{
ffffffffc0201286:	1101                	addi	sp,sp,-32
ffffffffc0201288:	ec06                	sd	ra,24(sp)
ffffffffc020128a:	e822                	sd	s0,16(sp)
ffffffffc020128c:	e426                	sd	s1,8(sp)
ffffffffc020128e:	842a                	mv	s0,a0
ffffffffc0201290:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201292:	9d2ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201296:	00005797          	auipc	a5,0x5
ffffffffc020129a:	2ba78793          	addi	a5,a5,698 # ffffffffc0206550 <pmm_manager>
ffffffffc020129e:	639c                	ld	a5,0(a5)
ffffffffc02012a0:	85a6                	mv	a1,s1
ffffffffc02012a2:	8522                	mv	a0,s0
ffffffffc02012a4:	739c                	ld	a5,32(a5)
ffffffffc02012a6:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02012a8:	6442                	ld	s0,16(sp)
ffffffffc02012aa:	60e2                	ld	ra,24(sp)
ffffffffc02012ac:	64a2                	ld	s1,8(sp)
ffffffffc02012ae:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02012b0:	9aeff06f          	j	ffffffffc020045e <intr_enable>

ffffffffc02012b4 <pmm_init>:
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc02012b4:	00001797          	auipc	a5,0x1
ffffffffc02012b8:	4dc78793          	addi	a5,a5,1244 # ffffffffc0202790 <buddy_system_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012bc:	638c                	ld	a1,0(a5)
    // 0x8000-0x7cb9=0x0347个不可用，这些页存的是结构体page的数据
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void)
{
ffffffffc02012be:	715d                	addi	sp,sp,-80
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012c0:	00001517          	auipc	a0,0x1
ffffffffc02012c4:	67050513          	addi	a0,a0,1648 # ffffffffc0202930 <buddy_system_pmm_manager+0x1a0>
{
ffffffffc02012c8:	e486                	sd	ra,72(sp)
ffffffffc02012ca:	e0a2                	sd	s0,64(sp)
ffffffffc02012cc:	f052                	sd	s4,32(sp)
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc02012ce:	00005717          	auipc	a4,0x5
ffffffffc02012d2:	28f73123          	sd	a5,642(a4) # ffffffffc0206550 <pmm_manager>
{
ffffffffc02012d6:	fc26                	sd	s1,56(sp)
ffffffffc02012d8:	f84a                	sd	s2,48(sp)
ffffffffc02012da:	f44e                	sd	s3,40(sp)
ffffffffc02012dc:	ec56                	sd	s5,24(sp)
ffffffffc02012de:	e85a                	sd	s6,16(sp)
ffffffffc02012e0:	e45e                	sd	s7,8(sp)
ffffffffc02012e2:	e062                	sd	s8,0(sp)
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc02012e4:	00005a17          	auipc	s4,0x5
ffffffffc02012e8:	26ca0a13          	addi	s4,s4,620 # ffffffffc0206550 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012ec:	dcbfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pmm_manager->init();
ffffffffc02012f0:	000a3783          	ld	a5,0(s4)
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02012f4:	4445                	li	s0,17
ffffffffc02012f6:	046e                	slli	s0,s0,0x1b
    pmm_manager->init();
ffffffffc02012f8:	679c                	ld	a5,8(a5)
ffffffffc02012fa:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移: 硬编码0xFFFFFFFF40000000
ffffffffc02012fc:	57f5                	li	a5,-3
ffffffffc02012fe:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201300:	00001517          	auipc	a0,0x1
ffffffffc0201304:	64850513          	addi	a0,a0,1608 # ffffffffc0202948 <buddy_system_pmm_manager+0x1b8>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移: 硬编码0xFFFFFFFF40000000
ffffffffc0201308:	00005717          	auipc	a4,0x5
ffffffffc020130c:	24f73823          	sd	a5,592(a4) # ffffffffc0206558 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc0201310:	da7fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201314:	40100613          	li	a2,1025
ffffffffc0201318:	fff40693          	addi	a3,s0,-1
ffffffffc020131c:	0656                	slli	a2,a2,0x15
ffffffffc020131e:	07e005b7          	lui	a1,0x7e00
ffffffffc0201322:	00001517          	auipc	a0,0x1
ffffffffc0201326:	63e50513          	addi	a0,a0,1598 # ffffffffc0202960 <buddy_system_pmm_manager+0x1d0>
ffffffffc020132a:	d8dfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("maxpa: 0x%016lx.\n", maxpa); // test point
ffffffffc020132e:	85a2                	mv	a1,s0
ffffffffc0201330:	00001517          	auipc	a0,0x1
ffffffffc0201334:	66050513          	addi	a0,a0,1632 # ffffffffc0202990 <buddy_system_pmm_manager+0x200>
ffffffffc0201338:	d7ffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020133c:	000887b7          	lui	a5,0x88
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc0201340:	000885b7          	lui	a1,0x88
ffffffffc0201344:	00001517          	auipc	a0,0x1
ffffffffc0201348:	66450513          	addi	a0,a0,1636 # ffffffffc02029a8 <buddy_system_pmm_manager+0x218>
    npage = maxpa / PGSIZE;
ffffffffc020134c:	00005717          	auipc	a4,0x5
ffffffffc0201350:	0cf73e23          	sd	a5,220(a4) # ffffffffc0206428 <npage>
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc0201354:	d63fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("nbase: 0x%016lx.\n", nbase); // test point，为0x8000_0
ffffffffc0201358:	000805b7          	lui	a1,0x80
ffffffffc020135c:	00001517          	auipc	a0,0x1
ffffffffc0201360:	66450513          	addi	a0,a0,1636 # ffffffffc02029c0 <buddy_system_pmm_manager+0x230>
ffffffffc0201364:	d53fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201368:	00006697          	auipc	a3,0x6
ffffffffc020136c:	1ff68693          	addi	a3,a3,511 # ffffffffc0207567 <end+0xfff>
ffffffffc0201370:	75fd                	lui	a1,0xfffff
ffffffffc0201372:	8eed                	and	a3,a3,a1
ffffffffc0201374:	00005797          	auipc	a5,0x5
ffffffffc0201378:	1ed7b623          	sd	a3,492(a5) # ffffffffc0206560 <pages>
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc020137c:	c02007b7          	lui	a5,0xc0200
ffffffffc0201380:	24f6ec63          	bltu	a3,a5,ffffffffc02015d8 <pmm_init+0x324>
ffffffffc0201384:	00005997          	auipc	s3,0x5
ffffffffc0201388:	1d498993          	addi	s3,s3,468 # ffffffffc0206558 <va_pa_offset>
ffffffffc020138c:	0009b583          	ld	a1,0(s3)
ffffffffc0201390:	00001517          	auipc	a0,0x1
ffffffffc0201394:	68050513          	addi	a0,a0,1664 # ffffffffc0202a10 <buddy_system_pmm_manager+0x280>
ffffffffc0201398:	00005917          	auipc	s2,0x5
ffffffffc020139c:	09090913          	addi	s2,s2,144 # ffffffffc0206428 <npage>
ffffffffc02013a0:	40b685b3          	sub	a1,a3,a1
ffffffffc02013a4:	d13fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02013a8:	00093703          	ld	a4,0(s2)
ffffffffc02013ac:	000807b7          	lui	a5,0x80
ffffffffc02013b0:	00005a97          	auipc	s5,0x5
ffffffffc02013b4:	1b0a8a93          	addi	s5,s5,432 # ffffffffc0206560 <pages>
ffffffffc02013b8:	02f70963          	beq	a4,a5,ffffffffc02013ea <pmm_init+0x136>
ffffffffc02013bc:	4681                	li	a3,0
ffffffffc02013be:	4701                	li	a4,0
ffffffffc02013c0:	00005a97          	auipc	s5,0x5
ffffffffc02013c4:	1a0a8a93          	addi	s5,s5,416 # ffffffffc0206560 <pages>
ffffffffc02013c8:	4585                	li	a1,1
ffffffffc02013ca:	fff80637          	lui	a2,0xfff80
        SetPageReserved(pages + i); // 在memlayout.h中，SetPageReserved是一个宏，将给定的页面标记为保留给内存使用的
ffffffffc02013ce:	000ab783          	ld	a5,0(s5)
ffffffffc02013d2:	97b6                	add	a5,a5,a3
ffffffffc02013d4:	07a1                	addi	a5,a5,8
ffffffffc02013d6:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02013da:	00093783          	ld	a5,0(s2)
ffffffffc02013de:	0705                	addi	a4,a4,1
ffffffffc02013e0:	02868693          	addi	a3,a3,40
ffffffffc02013e4:	97b2                	add	a5,a5,a2
ffffffffc02013e6:	fef764e3          	bltu	a4,a5,ffffffffc02013ce <pmm_init+0x11a>
ffffffffc02013ea:	4481                	li	s1,0
    for (size_t i = 0; i < 5; i++)
ffffffffc02013ec:	4401                	li	s0,0
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc02013ee:	c0200b37          	lui	s6,0xc0200
ffffffffc02013f2:	00001c17          	auipc	s8,0x1
ffffffffc02013f6:	646c0c13          	addi	s8,s8,1606 # ffffffffc0202a38 <buddy_system_pmm_manager+0x2a8>
    for (size_t i = 0; i < 5; i++)
ffffffffc02013fa:	4b95                	li	s7,5
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc02013fc:	000ab683          	ld	a3,0(s5)
ffffffffc0201400:	96a6                	add	a3,a3,s1
ffffffffc0201402:	1966e563          	bltu	a3,s6,ffffffffc020158c <pmm_init+0x2d8>
ffffffffc0201406:	0009b603          	ld	a2,0(s3)
ffffffffc020140a:	85a2                	mv	a1,s0
ffffffffc020140c:	8562                	mv	a0,s8
ffffffffc020140e:	40c68633          	sub	a2,a3,a2
    for (size_t i = 0; i < 5; i++)
ffffffffc0201412:	0405                	addi	s0,s0,1
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201414:	ca3fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0201418:	02848493          	addi	s1,s1,40
    for (size_t i = 0; i < 5; i++)
ffffffffc020141c:	ff7410e3          	bne	s0,s7,ffffffffc02013fc <pmm_init+0x148>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc0201420:	00093783          	ld	a5,0(s2)
ffffffffc0201424:	000ab403          	ld	s0,0(s5)
ffffffffc0201428:	00279693          	slli	a3,a5,0x2
ffffffffc020142c:	96be                	add	a3,a3,a5
ffffffffc020142e:	068e                	slli	a3,a3,0x3
ffffffffc0201430:	9436                	add	s0,s0,a3
ffffffffc0201432:	fec006b7          	lui	a3,0xfec00
ffffffffc0201436:	9436                	add	s0,s0,a3
ffffffffc0201438:	1b646c63          	bltu	s0,s6,ffffffffc02015f0 <pmm_init+0x33c>
ffffffffc020143c:	0009b683          	ld	a3,0(s3)
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc0201440:	02800593          	li	a1,40
ffffffffc0201444:	00001517          	auipc	a0,0x1
ffffffffc0201448:	61c50513          	addi	a0,a0,1564 # ffffffffc0202a60 <buddy_system_pmm_manager+0x2d0>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020144c:	6485                	lui	s1,0x1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc020144e:	8c15                	sub	s0,s0,a3
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201450:	14fd                	addi	s1,s1,-1
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc0201452:	c65fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc0201456:	85a2                	mv	a1,s0
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201458:	94a2                	add	s1,s1,s0
ffffffffc020145a:	7b7d                	lui	s6,0xfffff
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc020145c:	00001517          	auipc	a0,0x1
ffffffffc0201460:	62450513          	addi	a0,a0,1572 # ffffffffc0202a80 <buddy_system_pmm_manager+0x2f0>
ffffffffc0201464:	c53fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0201468:	0164fb33          	and	s6,s1,s6
    cprintf("mem_begin: 0x%016lx.\n", mem_begin); // test point
ffffffffc020146c:	85da                	mv	a1,s6
ffffffffc020146e:	00001517          	auipc	a0,0x1
ffffffffc0201472:	62a50513          	addi	a0,a0,1578 # ffffffffc0202a98 <buddy_system_pmm_manager+0x308>
ffffffffc0201476:	c41fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc020147a:	4bc5                	li	s7,17
ffffffffc020147c:	01bb9593          	slli	a1,s7,0x1b
ffffffffc0201480:	00001517          	auipc	a0,0x1
ffffffffc0201484:	63050513          	addi	a0,a0,1584 # ffffffffc0202ab0 <buddy_system_pmm_manager+0x320>
    if (freemem < mem_end)
ffffffffc0201488:	0bee                	slli	s7,s7,0x1b
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc020148a:	c2dfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (freemem < mem_end)
ffffffffc020148e:	0d746763          	bltu	s0,s7,ffffffffc020155c <pmm_init+0x2a8>
    if (PPN(pa) >= npage)
ffffffffc0201492:	00093783          	ld	a5,0(s2)
ffffffffc0201496:	00cb5493          	srli	s1,s6,0xc
ffffffffc020149a:	10f4f563          	bleu	a5,s1,ffffffffc02015a4 <pmm_init+0x2f0>
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020149e:	fff80437          	lui	s0,0xfff80
ffffffffc02014a2:	008486b3          	add	a3,s1,s0
ffffffffc02014a6:	00269413          	slli	s0,a3,0x2
ffffffffc02014aa:	000ab583          	ld	a1,0(s5)
ffffffffc02014ae:	9436                	add	s0,s0,a3
ffffffffc02014b0:	040e                	slli	s0,s0,0x3
    cprintf("mem_begin对应的页结构记录(结构体page)虚拟地址: 0x%016lx.\n", pa2page(mem_begin));        // test point
ffffffffc02014b2:	95a2                	add	a1,a1,s0
ffffffffc02014b4:	00001517          	auipc	a0,0x1
ffffffffc02014b8:	61450513          	addi	a0,a0,1556 # ffffffffc0202ac8 <buddy_system_pmm_manager+0x338>
ffffffffc02014bc:	bfbfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc02014c0:	00093783          	ld	a5,0(s2)
ffffffffc02014c4:	0ef4f063          	bleu	a5,s1,ffffffffc02015a4 <pmm_init+0x2f0>
    return &pages[PPN(pa) - nbase];
ffffffffc02014c8:	000ab683          	ld	a3,0(s5)
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc02014cc:	c02004b7          	lui	s1,0xc0200
ffffffffc02014d0:	96a2                	add	a3,a3,s0
ffffffffc02014d2:	0c96eb63          	bltu	a3,s1,ffffffffc02015a8 <pmm_init+0x2f4>
ffffffffc02014d6:	0009b583          	ld	a1,0(s3)
ffffffffc02014da:	00001517          	auipc	a0,0x1
ffffffffc02014de:	63e50513          	addi	a0,a0,1598 # ffffffffc0202b18 <buddy_system_pmm_manager+0x388>
ffffffffc02014e2:	40b685b3          	sub	a1,a3,a1
ffffffffc02014e6:	bd1fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("可用空闲页的数目: 0x%016lx.\n", (mem_end - mem_begin) / PGSIZE); // test point
ffffffffc02014ea:	45c5                	li	a1,17
ffffffffc02014ec:	05ee                	slli	a1,a1,0x1b
ffffffffc02014ee:	416585b3          	sub	a1,a1,s6
ffffffffc02014f2:	81b1                	srli	a1,a1,0xc
ffffffffc02014f4:	00001517          	auipc	a0,0x1
ffffffffc02014f8:	67450513          	addi	a0,a0,1652 # ffffffffc0202b68 <buddy_system_pmm_manager+0x3d8>
ffffffffc02014fc:	bbbfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201500:	000a3783          	ld	a5,0(s4)
ffffffffc0201504:	7b9c                	ld	a5,48(a5)
ffffffffc0201506:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201508:	00001517          	auipc	a0,0x1
ffffffffc020150c:	68850513          	addi	a0,a0,1672 # ffffffffc0202b90 <buddy_system_pmm_manager+0x400>
ffffffffc0201510:	ba7fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    satp_virtual = (pte_t *)boot_page_table_sv39; // pte_t 页表项
ffffffffc0201514:	00004697          	auipc	a3,0x4
ffffffffc0201518:	aec68693          	addi	a3,a3,-1300 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020151c:	00005797          	auipc	a5,0x5
ffffffffc0201520:	f0d7ba23          	sd	a3,-236(a5) # ffffffffc0206430 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201524:	0896ee63          	bltu	a3,s1,ffffffffc02015c0 <pmm_init+0x30c>
ffffffffc0201528:	0009b783          	ld	a5,0(s3)
}
ffffffffc020152c:	6406                	ld	s0,64(sp)
ffffffffc020152e:	60a6                	ld	ra,72(sp)
ffffffffc0201530:	74e2                	ld	s1,56(sp)
ffffffffc0201532:	7942                	ld	s2,48(sp)
ffffffffc0201534:	79a2                	ld	s3,40(sp)
ffffffffc0201536:	7a02                	ld	s4,32(sp)
ffffffffc0201538:	6ae2                	ld	s5,24(sp)
ffffffffc020153a:	6b42                	ld	s6,16(sp)
ffffffffc020153c:	6ba2                	ld	s7,8(sp)
ffffffffc020153e:	6c02                	ld	s8,0(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201540:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc0201542:	8e9d                	sub	a3,a3,a5
ffffffffc0201544:	00005797          	auipc	a5,0x5
ffffffffc0201548:	00d7b223          	sd	a3,4(a5) # ffffffffc0206548 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020154c:	00001517          	auipc	a0,0x1
ffffffffc0201550:	66450513          	addi	a0,a0,1636 # ffffffffc0202bb0 <buddy_system_pmm_manager+0x420>
ffffffffc0201554:	8636                	mv	a2,a3
}
ffffffffc0201556:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201558:	b5ffe06f          	j	ffffffffc02000b6 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc020155c:	00093783          	ld	a5,0(s2)
ffffffffc0201560:	80b1                	srli	s1,s1,0xc
ffffffffc0201562:	04f4f163          	bleu	a5,s1,ffffffffc02015a4 <pmm_init+0x2f0>
    pmm_manager->init_memmap(base, n);
ffffffffc0201566:	000a3703          	ld	a4,0(s4)
    return &pages[PPN(pa) - nbase];
ffffffffc020156a:	fff80537          	lui	a0,0xfff80
ffffffffc020156e:	94aa                	add	s1,s1,a0
ffffffffc0201570:	00249793          	slli	a5,s1,0x2
ffffffffc0201574:	000ab503          	ld	a0,0(s5)
ffffffffc0201578:	94be                	add	s1,s1,a5
ffffffffc020157a:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020157c:	416b8bb3          	sub	s7,s7,s6
ffffffffc0201580:	048e                	slli	s1,s1,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201582:	00cbd593          	srli	a1,s7,0xc
ffffffffc0201586:	9526                	add	a0,a0,s1
ffffffffc0201588:	9782                	jalr	a5
ffffffffc020158a:	b721                	j	ffffffffc0201492 <pmm_init+0x1de>
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc020158c:	00001617          	auipc	a2,0x1
ffffffffc0201590:	44c60613          	addi	a2,a2,1100 # ffffffffc02029d8 <buddy_system_pmm_manager+0x248>
ffffffffc0201594:	09100593          	li	a1,145
ffffffffc0201598:	00001517          	auipc	a0,0x1
ffffffffc020159c:	46850513          	addi	a0,a0,1128 # ffffffffc0202a00 <buddy_system_pmm_manager+0x270>
ffffffffc02015a0:	e0dfe0ef          	jal	ra,ffffffffc02003ac <__panic>
ffffffffc02015a4:	c6bff0ef          	jal	ra,ffffffffc020120e <pa2page.part.0>
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc02015a8:	00001617          	auipc	a2,0x1
ffffffffc02015ac:	43060613          	addi	a2,a2,1072 # ffffffffc02029d8 <buddy_system_pmm_manager+0x248>
ffffffffc02015b0:	0a800593          	li	a1,168
ffffffffc02015b4:	00001517          	auipc	a0,0x1
ffffffffc02015b8:	44c50513          	addi	a0,a0,1100 # ffffffffc0202a00 <buddy_system_pmm_manager+0x270>
ffffffffc02015bc:	df1fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02015c0:	00001617          	auipc	a2,0x1
ffffffffc02015c4:	41860613          	addi	a2,a2,1048 # ffffffffc02029d8 <buddy_system_pmm_manager+0x248>
ffffffffc02015c8:	0c400593          	li	a1,196
ffffffffc02015cc:	00001517          	auipc	a0,0x1
ffffffffc02015d0:	43450513          	addi	a0,a0,1076 # ffffffffc0202a00 <buddy_system_pmm_manager+0x270>
ffffffffc02015d4:	dd9fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc02015d8:	00001617          	auipc	a2,0x1
ffffffffc02015dc:	40060613          	addi	a2,a2,1024 # ffffffffc02029d8 <buddy_system_pmm_manager+0x248>
ffffffffc02015e0:	08500593          	li	a1,133
ffffffffc02015e4:	00001517          	auipc	a0,0x1
ffffffffc02015e8:	41c50513          	addi	a0,a0,1052 # ffffffffc0202a00 <buddy_system_pmm_manager+0x270>
ffffffffc02015ec:	dc1fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc02015f0:	86a2                	mv	a3,s0
ffffffffc02015f2:	00001617          	auipc	a2,0x1
ffffffffc02015f6:	3e660613          	addi	a2,a2,998 # ffffffffc02029d8 <buddy_system_pmm_manager+0x248>
ffffffffc02015fa:	09800593          	li	a1,152
ffffffffc02015fe:	00001517          	auipc	a0,0x1
ffffffffc0201602:	40250513          	addi	a0,a0,1026 # ffffffffc0202a00 <buddy_system_pmm_manager+0x270>
ffffffffc0201606:	da7fe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020160a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020160a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020160e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201610:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201614:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201616:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020161a:	f022                	sd	s0,32(sp)
ffffffffc020161c:	ec26                	sd	s1,24(sp)
ffffffffc020161e:	e84a                	sd	s2,16(sp)
ffffffffc0201620:	f406                	sd	ra,40(sp)
ffffffffc0201622:	e44e                	sd	s3,8(sp)
ffffffffc0201624:	84aa                	mv	s1,a0
ffffffffc0201626:	892e                	mv	s2,a1
ffffffffc0201628:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020162c:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc020162e:	03067e63          	bleu	a6,a2,ffffffffc020166a <printnum+0x60>
ffffffffc0201632:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201634:	00805763          	blez	s0,ffffffffc0201642 <printnum+0x38>
ffffffffc0201638:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020163a:	85ca                	mv	a1,s2
ffffffffc020163c:	854e                	mv	a0,s3
ffffffffc020163e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201640:	fc65                	bnez	s0,ffffffffc0201638 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201642:	1a02                	slli	s4,s4,0x20
ffffffffc0201644:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201648:	00001797          	auipc	a5,0x1
ffffffffc020164c:	73878793          	addi	a5,a5,1848 # ffffffffc0202d80 <error_string+0x38>
ffffffffc0201650:	9a3e                	add	s4,s4,a5
}
ffffffffc0201652:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201654:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201658:	70a2                	ld	ra,40(sp)
ffffffffc020165a:	69a2                	ld	s3,8(sp)
ffffffffc020165c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020165e:	85ca                	mv	a1,s2
ffffffffc0201660:	8326                	mv	t1,s1
}
ffffffffc0201662:	6942                	ld	s2,16(sp)
ffffffffc0201664:	64e2                	ld	s1,24(sp)
ffffffffc0201666:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201668:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020166a:	03065633          	divu	a2,a2,a6
ffffffffc020166e:	8722                	mv	a4,s0
ffffffffc0201670:	f9bff0ef          	jal	ra,ffffffffc020160a <printnum>
ffffffffc0201674:	b7f9                	j	ffffffffc0201642 <printnum+0x38>

ffffffffc0201676 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201676:	7119                	addi	sp,sp,-128
ffffffffc0201678:	f4a6                	sd	s1,104(sp)
ffffffffc020167a:	f0ca                	sd	s2,96(sp)
ffffffffc020167c:	e8d2                	sd	s4,80(sp)
ffffffffc020167e:	e4d6                	sd	s5,72(sp)
ffffffffc0201680:	e0da                	sd	s6,64(sp)
ffffffffc0201682:	fc5e                	sd	s7,56(sp)
ffffffffc0201684:	f862                	sd	s8,48(sp)
ffffffffc0201686:	f06a                	sd	s10,32(sp)
ffffffffc0201688:	fc86                	sd	ra,120(sp)
ffffffffc020168a:	f8a2                	sd	s0,112(sp)
ffffffffc020168c:	ecce                	sd	s3,88(sp)
ffffffffc020168e:	f466                	sd	s9,40(sp)
ffffffffc0201690:	ec6e                	sd	s11,24(sp)
ffffffffc0201692:	892a                	mv	s2,a0
ffffffffc0201694:	84ae                	mv	s1,a1
ffffffffc0201696:	8d32                	mv	s10,a2
ffffffffc0201698:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020169a:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020169c:	00001a17          	auipc	s4,0x1
ffffffffc02016a0:	554a0a13          	addi	s4,s4,1364 # ffffffffc0202bf0 <buddy_system_pmm_manager+0x460>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016a4:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02016a8:	00001c17          	auipc	s8,0x1
ffffffffc02016ac:	6a0c0c13          	addi	s8,s8,1696 # ffffffffc0202d48 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016b0:	000d4503          	lbu	a0,0(s10)
ffffffffc02016b4:	02500793          	li	a5,37
ffffffffc02016b8:	001d0413          	addi	s0,s10,1
ffffffffc02016bc:	00f50e63          	beq	a0,a5,ffffffffc02016d8 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc02016c0:	c521                	beqz	a0,ffffffffc0201708 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016c2:	02500993          	li	s3,37
ffffffffc02016c6:	a011                	j	ffffffffc02016ca <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc02016c8:	c121                	beqz	a0,ffffffffc0201708 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc02016ca:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016cc:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02016ce:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016d0:	fff44503          	lbu	a0,-1(s0) # fffffffffff7ffff <end+0x3fd79a97>
ffffffffc02016d4:	ff351ae3          	bne	a0,s3,ffffffffc02016c8 <vprintfmt+0x52>
ffffffffc02016d8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02016dc:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02016e0:	4981                	li	s3,0
ffffffffc02016e2:	4801                	li	a6,0
        width = precision = -1;
ffffffffc02016e4:	5cfd                	li	s9,-1
ffffffffc02016e6:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016e8:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc02016ec:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016ee:	fdd6069b          	addiw	a3,a2,-35
ffffffffc02016f2:	0ff6f693          	andi	a3,a3,255
ffffffffc02016f6:	00140d13          	addi	s10,s0,1
ffffffffc02016fa:	20d5e563          	bltu	a1,a3,ffffffffc0201904 <vprintfmt+0x28e>
ffffffffc02016fe:	068a                	slli	a3,a3,0x2
ffffffffc0201700:	96d2                	add	a3,a3,s4
ffffffffc0201702:	4294                	lw	a3,0(a3)
ffffffffc0201704:	96d2                	add	a3,a3,s4
ffffffffc0201706:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201708:	70e6                	ld	ra,120(sp)
ffffffffc020170a:	7446                	ld	s0,112(sp)
ffffffffc020170c:	74a6                	ld	s1,104(sp)
ffffffffc020170e:	7906                	ld	s2,96(sp)
ffffffffc0201710:	69e6                	ld	s3,88(sp)
ffffffffc0201712:	6a46                	ld	s4,80(sp)
ffffffffc0201714:	6aa6                	ld	s5,72(sp)
ffffffffc0201716:	6b06                	ld	s6,64(sp)
ffffffffc0201718:	7be2                	ld	s7,56(sp)
ffffffffc020171a:	7c42                	ld	s8,48(sp)
ffffffffc020171c:	7ca2                	ld	s9,40(sp)
ffffffffc020171e:	7d02                	ld	s10,32(sp)
ffffffffc0201720:	6de2                	ld	s11,24(sp)
ffffffffc0201722:	6109                	addi	sp,sp,128
ffffffffc0201724:	8082                	ret
    if (lflag >= 2) {
ffffffffc0201726:	4705                	li	a4,1
ffffffffc0201728:	008a8593          	addi	a1,s5,8
ffffffffc020172c:	01074463          	blt	a4,a6,ffffffffc0201734 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0201730:	26080363          	beqz	a6,ffffffffc0201996 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc0201734:	000ab603          	ld	a2,0(s5)
ffffffffc0201738:	46c1                	li	a3,16
ffffffffc020173a:	8aae                	mv	s5,a1
ffffffffc020173c:	a06d                	j	ffffffffc02017e6 <vprintfmt+0x170>
            goto reswitch;
ffffffffc020173e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201742:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201744:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201746:	b765                	j	ffffffffc02016ee <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0201748:	000aa503          	lw	a0,0(s5)
ffffffffc020174c:	85a6                	mv	a1,s1
ffffffffc020174e:	0aa1                	addi	s5,s5,8
ffffffffc0201750:	9902                	jalr	s2
            break;
ffffffffc0201752:	bfb9                	j	ffffffffc02016b0 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201754:	4705                	li	a4,1
ffffffffc0201756:	008a8993          	addi	s3,s5,8
ffffffffc020175a:	01074463          	blt	a4,a6,ffffffffc0201762 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc020175e:	22080463          	beqz	a6,ffffffffc0201986 <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc0201762:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0201766:	24044463          	bltz	s0,ffffffffc02019ae <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc020176a:	8622                	mv	a2,s0
ffffffffc020176c:	8ace                	mv	s5,s3
ffffffffc020176e:	46a9                	li	a3,10
ffffffffc0201770:	a89d                	j	ffffffffc02017e6 <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc0201772:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201776:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201778:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc020177a:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020177e:	8fb5                	xor	a5,a5,a3
ffffffffc0201780:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201784:	1ad74363          	blt	a4,a3,ffffffffc020192a <vprintfmt+0x2b4>
ffffffffc0201788:	00369793          	slli	a5,a3,0x3
ffffffffc020178c:	97e2                	add	a5,a5,s8
ffffffffc020178e:	639c                	ld	a5,0(a5)
ffffffffc0201790:	18078d63          	beqz	a5,ffffffffc020192a <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201794:	86be                	mv	a3,a5
ffffffffc0201796:	00001617          	auipc	a2,0x1
ffffffffc020179a:	69a60613          	addi	a2,a2,1690 # ffffffffc0202e30 <error_string+0xe8>
ffffffffc020179e:	85a6                	mv	a1,s1
ffffffffc02017a0:	854a                	mv	a0,s2
ffffffffc02017a2:	240000ef          	jal	ra,ffffffffc02019e2 <printfmt>
ffffffffc02017a6:	b729                	j	ffffffffc02016b0 <vprintfmt+0x3a>
            lflag ++;
ffffffffc02017a8:	00144603          	lbu	a2,1(s0)
ffffffffc02017ac:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017ae:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02017b0:	bf3d                	j	ffffffffc02016ee <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc02017b2:	4705                	li	a4,1
ffffffffc02017b4:	008a8593          	addi	a1,s5,8
ffffffffc02017b8:	01074463          	blt	a4,a6,ffffffffc02017c0 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02017bc:	1e080263          	beqz	a6,ffffffffc02019a0 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc02017c0:	000ab603          	ld	a2,0(s5)
ffffffffc02017c4:	46a1                	li	a3,8
ffffffffc02017c6:	8aae                	mv	s5,a1
ffffffffc02017c8:	a839                	j	ffffffffc02017e6 <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc02017ca:	03000513          	li	a0,48
ffffffffc02017ce:	85a6                	mv	a1,s1
ffffffffc02017d0:	e03e                	sd	a5,0(sp)
ffffffffc02017d2:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02017d4:	85a6                	mv	a1,s1
ffffffffc02017d6:	07800513          	li	a0,120
ffffffffc02017da:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02017dc:	0aa1                	addi	s5,s5,8
ffffffffc02017de:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc02017e2:	6782                	ld	a5,0(sp)
ffffffffc02017e4:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02017e6:	876e                	mv	a4,s11
ffffffffc02017e8:	85a6                	mv	a1,s1
ffffffffc02017ea:	854a                	mv	a0,s2
ffffffffc02017ec:	e1fff0ef          	jal	ra,ffffffffc020160a <printnum>
            break;
ffffffffc02017f0:	b5c1                	j	ffffffffc02016b0 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02017f2:	000ab603          	ld	a2,0(s5)
ffffffffc02017f6:	0aa1                	addi	s5,s5,8
ffffffffc02017f8:	1c060663          	beqz	a2,ffffffffc02019c4 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc02017fc:	00160413          	addi	s0,a2,1
ffffffffc0201800:	17b05c63          	blez	s11,ffffffffc0201978 <vprintfmt+0x302>
ffffffffc0201804:	02d00593          	li	a1,45
ffffffffc0201808:	14b79263          	bne	a5,a1,ffffffffc020194c <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020180c:	00064783          	lbu	a5,0(a2)
ffffffffc0201810:	0007851b          	sext.w	a0,a5
ffffffffc0201814:	c905                	beqz	a0,ffffffffc0201844 <vprintfmt+0x1ce>
ffffffffc0201816:	000cc563          	bltz	s9,ffffffffc0201820 <vprintfmt+0x1aa>
ffffffffc020181a:	3cfd                	addiw	s9,s9,-1
ffffffffc020181c:	036c8263          	beq	s9,s6,ffffffffc0201840 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0201820:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201822:	18098463          	beqz	s3,ffffffffc02019aa <vprintfmt+0x334>
ffffffffc0201826:	3781                	addiw	a5,a5,-32
ffffffffc0201828:	18fbf163          	bleu	a5,s7,ffffffffc02019aa <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc020182c:	03f00513          	li	a0,63
ffffffffc0201830:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201832:	0405                	addi	s0,s0,1
ffffffffc0201834:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201838:	3dfd                	addiw	s11,s11,-1
ffffffffc020183a:	0007851b          	sext.w	a0,a5
ffffffffc020183e:	fd61                	bnez	a0,ffffffffc0201816 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc0201840:	e7b058e3          	blez	s11,ffffffffc02016b0 <vprintfmt+0x3a>
ffffffffc0201844:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201846:	85a6                	mv	a1,s1
ffffffffc0201848:	02000513          	li	a0,32
ffffffffc020184c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020184e:	e60d81e3          	beqz	s11,ffffffffc02016b0 <vprintfmt+0x3a>
ffffffffc0201852:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201854:	85a6                	mv	a1,s1
ffffffffc0201856:	02000513          	li	a0,32
ffffffffc020185a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020185c:	fe0d94e3          	bnez	s11,ffffffffc0201844 <vprintfmt+0x1ce>
ffffffffc0201860:	bd81                	j	ffffffffc02016b0 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201862:	4705                	li	a4,1
ffffffffc0201864:	008a8593          	addi	a1,s5,8
ffffffffc0201868:	01074463          	blt	a4,a6,ffffffffc0201870 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc020186c:	12080063          	beqz	a6,ffffffffc020198c <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0201870:	000ab603          	ld	a2,0(s5)
ffffffffc0201874:	46a9                	li	a3,10
ffffffffc0201876:	8aae                	mv	s5,a1
ffffffffc0201878:	b7bd                	j	ffffffffc02017e6 <vprintfmt+0x170>
ffffffffc020187a:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc020187e:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201882:	846a                	mv	s0,s10
ffffffffc0201884:	b5ad                	j	ffffffffc02016ee <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0201886:	85a6                	mv	a1,s1
ffffffffc0201888:	02500513          	li	a0,37
ffffffffc020188c:	9902                	jalr	s2
            break;
ffffffffc020188e:	b50d                	j	ffffffffc02016b0 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc0201890:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0201894:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201898:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020189a:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc020189c:	e40dd9e3          	bgez	s11,ffffffffc02016ee <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc02018a0:	8de6                	mv	s11,s9
ffffffffc02018a2:	5cfd                	li	s9,-1
ffffffffc02018a4:	b5a9                	j	ffffffffc02016ee <vprintfmt+0x78>
            goto reswitch;
ffffffffc02018a6:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc02018aa:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018ae:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02018b0:	bd3d                	j	ffffffffc02016ee <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc02018b2:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc02018b6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018ba:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02018bc:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02018c0:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02018c4:	fcd56ce3          	bltu	a0,a3,ffffffffc020189c <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc02018c8:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02018ca:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02018ce:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02018d2:	0196873b          	addw	a4,a3,s9
ffffffffc02018d6:	0017171b          	slliw	a4,a4,0x1
ffffffffc02018da:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc02018de:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc02018e2:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02018e6:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02018ea:	fcd57fe3          	bleu	a3,a0,ffffffffc02018c8 <vprintfmt+0x252>
ffffffffc02018ee:	b77d                	j	ffffffffc020189c <vprintfmt+0x226>
            if (width < 0)
ffffffffc02018f0:	fffdc693          	not	a3,s11
ffffffffc02018f4:	96fd                	srai	a3,a3,0x3f
ffffffffc02018f6:	00ddfdb3          	and	s11,s11,a3
ffffffffc02018fa:	00144603          	lbu	a2,1(s0)
ffffffffc02018fe:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201900:	846a                	mv	s0,s10
ffffffffc0201902:	b3f5                	j	ffffffffc02016ee <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0201904:	85a6                	mv	a1,s1
ffffffffc0201906:	02500513          	li	a0,37
ffffffffc020190a:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020190c:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201910:	02500793          	li	a5,37
ffffffffc0201914:	8d22                	mv	s10,s0
ffffffffc0201916:	d8f70de3          	beq	a4,a5,ffffffffc02016b0 <vprintfmt+0x3a>
ffffffffc020191a:	02500713          	li	a4,37
ffffffffc020191e:	1d7d                	addi	s10,s10,-1
ffffffffc0201920:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0201924:	fee79de3          	bne	a5,a4,ffffffffc020191e <vprintfmt+0x2a8>
ffffffffc0201928:	b361                	j	ffffffffc02016b0 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020192a:	00001617          	auipc	a2,0x1
ffffffffc020192e:	4f660613          	addi	a2,a2,1270 # ffffffffc0202e20 <error_string+0xd8>
ffffffffc0201932:	85a6                	mv	a1,s1
ffffffffc0201934:	854a                	mv	a0,s2
ffffffffc0201936:	0ac000ef          	jal	ra,ffffffffc02019e2 <printfmt>
ffffffffc020193a:	bb9d                	j	ffffffffc02016b0 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020193c:	00001617          	auipc	a2,0x1
ffffffffc0201940:	4dc60613          	addi	a2,a2,1244 # ffffffffc0202e18 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0201944:	00001417          	auipc	s0,0x1
ffffffffc0201948:	4d540413          	addi	s0,s0,1237 # ffffffffc0202e19 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020194c:	8532                	mv	a0,a2
ffffffffc020194e:	85e6                	mv	a1,s9
ffffffffc0201950:	e032                	sd	a2,0(sp)
ffffffffc0201952:	e43e                	sd	a5,8(sp)
ffffffffc0201954:	1de000ef          	jal	ra,ffffffffc0201b32 <strnlen>
ffffffffc0201958:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020195c:	6602                	ld	a2,0(sp)
ffffffffc020195e:	01b05d63          	blez	s11,ffffffffc0201978 <vprintfmt+0x302>
ffffffffc0201962:	67a2                	ld	a5,8(sp)
ffffffffc0201964:	2781                	sext.w	a5,a5
ffffffffc0201966:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0201968:	6522                	ld	a0,8(sp)
ffffffffc020196a:	85a6                	mv	a1,s1
ffffffffc020196c:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020196e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201970:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201972:	6602                	ld	a2,0(sp)
ffffffffc0201974:	fe0d9ae3          	bnez	s11,ffffffffc0201968 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201978:	00064783          	lbu	a5,0(a2)
ffffffffc020197c:	0007851b          	sext.w	a0,a5
ffffffffc0201980:	e8051be3          	bnez	a0,ffffffffc0201816 <vprintfmt+0x1a0>
ffffffffc0201984:	b335                	j	ffffffffc02016b0 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc0201986:	000aa403          	lw	s0,0(s5)
ffffffffc020198a:	bbf1                	j	ffffffffc0201766 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc020198c:	000ae603          	lwu	a2,0(s5)
ffffffffc0201990:	46a9                	li	a3,10
ffffffffc0201992:	8aae                	mv	s5,a1
ffffffffc0201994:	bd89                	j	ffffffffc02017e6 <vprintfmt+0x170>
ffffffffc0201996:	000ae603          	lwu	a2,0(s5)
ffffffffc020199a:	46c1                	li	a3,16
ffffffffc020199c:	8aae                	mv	s5,a1
ffffffffc020199e:	b5a1                	j	ffffffffc02017e6 <vprintfmt+0x170>
ffffffffc02019a0:	000ae603          	lwu	a2,0(s5)
ffffffffc02019a4:	46a1                	li	a3,8
ffffffffc02019a6:	8aae                	mv	s5,a1
ffffffffc02019a8:	bd3d                	j	ffffffffc02017e6 <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc02019aa:	9902                	jalr	s2
ffffffffc02019ac:	b559                	j	ffffffffc0201832 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc02019ae:	85a6                	mv	a1,s1
ffffffffc02019b0:	02d00513          	li	a0,45
ffffffffc02019b4:	e03e                	sd	a5,0(sp)
ffffffffc02019b6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02019b8:	8ace                	mv	s5,s3
ffffffffc02019ba:	40800633          	neg	a2,s0
ffffffffc02019be:	46a9                	li	a3,10
ffffffffc02019c0:	6782                	ld	a5,0(sp)
ffffffffc02019c2:	b515                	j	ffffffffc02017e6 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02019c4:	01b05663          	blez	s11,ffffffffc02019d0 <vprintfmt+0x35a>
ffffffffc02019c8:	02d00693          	li	a3,45
ffffffffc02019cc:	f6d798e3          	bne	a5,a3,ffffffffc020193c <vprintfmt+0x2c6>
ffffffffc02019d0:	00001417          	auipc	s0,0x1
ffffffffc02019d4:	44940413          	addi	s0,s0,1097 # ffffffffc0202e19 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02019d8:	02800513          	li	a0,40
ffffffffc02019dc:	02800793          	li	a5,40
ffffffffc02019e0:	bd1d                	j	ffffffffc0201816 <vprintfmt+0x1a0>

ffffffffc02019e2 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02019e2:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02019e4:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02019e8:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02019ea:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02019ec:	ec06                	sd	ra,24(sp)
ffffffffc02019ee:	f83a                	sd	a4,48(sp)
ffffffffc02019f0:	fc3e                	sd	a5,56(sp)
ffffffffc02019f2:	e0c2                	sd	a6,64(sp)
ffffffffc02019f4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02019f6:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02019f8:	c7fff0ef          	jal	ra,ffffffffc0201676 <vprintfmt>
}
ffffffffc02019fc:	60e2                	ld	ra,24(sp)
ffffffffc02019fe:	6161                	addi	sp,sp,80
ffffffffc0201a00:	8082                	ret

ffffffffc0201a02 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201a02:	715d                	addi	sp,sp,-80
ffffffffc0201a04:	e486                	sd	ra,72(sp)
ffffffffc0201a06:	e0a2                	sd	s0,64(sp)
ffffffffc0201a08:	fc26                	sd	s1,56(sp)
ffffffffc0201a0a:	f84a                	sd	s2,48(sp)
ffffffffc0201a0c:	f44e                	sd	s3,40(sp)
ffffffffc0201a0e:	f052                	sd	s4,32(sp)
ffffffffc0201a10:	ec56                	sd	s5,24(sp)
ffffffffc0201a12:	e85a                	sd	s6,16(sp)
ffffffffc0201a14:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc0201a16:	c901                	beqz	a0,ffffffffc0201a26 <readline+0x24>
        cprintf("%s", prompt);
ffffffffc0201a18:	85aa                	mv	a1,a0
ffffffffc0201a1a:	00001517          	auipc	a0,0x1
ffffffffc0201a1e:	41650513          	addi	a0,a0,1046 # ffffffffc0202e30 <error_string+0xe8>
ffffffffc0201a22:	e94fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
readline(const char *prompt) {
ffffffffc0201a26:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a28:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201a2a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201a2c:	4aa9                	li	s5,10
ffffffffc0201a2e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201a30:	00004b97          	auipc	s7,0x4
ffffffffc0201a34:	5e8b8b93          	addi	s7,s7,1512 # ffffffffc0206018 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a38:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201a3c:	ef2fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201a40:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a42:	00054b63          	bltz	a0,ffffffffc0201a58 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a46:	00a95b63          	ble	a0,s2,ffffffffc0201a5c <readline+0x5a>
ffffffffc0201a4a:	029a5463          	ble	s1,s4,ffffffffc0201a72 <readline+0x70>
        c = getchar();
ffffffffc0201a4e:	ee0fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201a52:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a54:	fe0559e3          	bgez	a0,ffffffffc0201a46 <readline+0x44>
            return NULL;
ffffffffc0201a58:	4501                	li	a0,0
ffffffffc0201a5a:	a099                	j	ffffffffc0201aa0 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0201a5c:	03341463          	bne	s0,s3,ffffffffc0201a84 <readline+0x82>
ffffffffc0201a60:	e8b9                	bnez	s1,ffffffffc0201ab6 <readline+0xb4>
        c = getchar();
ffffffffc0201a62:	eccfe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201a66:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a68:	fe0548e3          	bltz	a0,ffffffffc0201a58 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a6c:	fea958e3          	ble	a0,s2,ffffffffc0201a5c <readline+0x5a>
ffffffffc0201a70:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201a72:	8522                	mv	a0,s0
ffffffffc0201a74:	e76fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i ++] = c;
ffffffffc0201a78:	009b87b3          	add	a5,s7,s1
ffffffffc0201a7c:	00878023          	sb	s0,0(a5)
ffffffffc0201a80:	2485                	addiw	s1,s1,1
ffffffffc0201a82:	bf6d                	j	ffffffffc0201a3c <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0201a84:	01540463          	beq	s0,s5,ffffffffc0201a8c <readline+0x8a>
ffffffffc0201a88:	fb641ae3          	bne	s0,s6,ffffffffc0201a3c <readline+0x3a>
            cputchar(c);
ffffffffc0201a8c:	8522                	mv	a0,s0
ffffffffc0201a8e:	e5cfe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i] = '\0';
ffffffffc0201a92:	00004517          	auipc	a0,0x4
ffffffffc0201a96:	58650513          	addi	a0,a0,1414 # ffffffffc0206018 <edata>
ffffffffc0201a9a:	94aa                	add	s1,s1,a0
ffffffffc0201a9c:	00048023          	sb	zero,0(s1) # ffffffffc0200000 <kern_entry>
            return buf;
        }
    }
}
ffffffffc0201aa0:	60a6                	ld	ra,72(sp)
ffffffffc0201aa2:	6406                	ld	s0,64(sp)
ffffffffc0201aa4:	74e2                	ld	s1,56(sp)
ffffffffc0201aa6:	7942                	ld	s2,48(sp)
ffffffffc0201aa8:	79a2                	ld	s3,40(sp)
ffffffffc0201aaa:	7a02                	ld	s4,32(sp)
ffffffffc0201aac:	6ae2                	ld	s5,24(sp)
ffffffffc0201aae:	6b42                	ld	s6,16(sp)
ffffffffc0201ab0:	6ba2                	ld	s7,8(sp)
ffffffffc0201ab2:	6161                	addi	sp,sp,80
ffffffffc0201ab4:	8082                	ret
            cputchar(c);
ffffffffc0201ab6:	4521                	li	a0,8
ffffffffc0201ab8:	e32fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            i --;
ffffffffc0201abc:	34fd                	addiw	s1,s1,-1
ffffffffc0201abe:	bfbd                	j	ffffffffc0201a3c <readline+0x3a>

ffffffffc0201ac0 <sbi_console_putchar>:
    return ret_val;
}

void sbi_console_putchar(unsigned char ch)
{
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201ac0:	00004797          	auipc	a5,0x4
ffffffffc0201ac4:	54878793          	addi	a5,a5,1352 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile(
ffffffffc0201ac8:	6398                	ld	a4,0(a5)
ffffffffc0201aca:	4781                	li	a5,0
ffffffffc0201acc:	88ba                	mv	a7,a4
ffffffffc0201ace:	852a                	mv	a0,a0
ffffffffc0201ad0:	85be                	mv	a1,a5
ffffffffc0201ad2:	863e                	mv	a2,a5
ffffffffc0201ad4:	00000073          	ecall
ffffffffc0201ad8:	87aa                	mv	a5,a0
}
ffffffffc0201ada:	8082                	ret

ffffffffc0201adc <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value)
{
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201adc:	00005797          	auipc	a5,0x5
ffffffffc0201ae0:	95c78793          	addi	a5,a5,-1700 # ffffffffc0206438 <SBI_SET_TIMER>
    __asm__ volatile(
ffffffffc0201ae4:	6398                	ld	a4,0(a5)
ffffffffc0201ae6:	4781                	li	a5,0
ffffffffc0201ae8:	88ba                	mv	a7,a4
ffffffffc0201aea:	852a                	mv	a0,a0
ffffffffc0201aec:	85be                	mv	a1,a5
ffffffffc0201aee:	863e                	mv	a2,a5
ffffffffc0201af0:	00000073          	ecall
ffffffffc0201af4:	87aa                	mv	a5,a0
}
ffffffffc0201af6:	8082                	ret

ffffffffc0201af8 <sbi_console_getchar>:

int sbi_console_getchar(void)
{
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201af8:	00004797          	auipc	a5,0x4
ffffffffc0201afc:	50878793          	addi	a5,a5,1288 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile(
ffffffffc0201b00:	639c                	ld	a5,0(a5)
ffffffffc0201b02:	4501                	li	a0,0
ffffffffc0201b04:	88be                	mv	a7,a5
ffffffffc0201b06:	852a                	mv	a0,a0
ffffffffc0201b08:	85aa                	mv	a1,a0
ffffffffc0201b0a:	862a                	mv	a2,a0
ffffffffc0201b0c:	00000073          	ecall
ffffffffc0201b10:	852a                	mv	a0,a0
}
ffffffffc0201b12:	2501                	sext.w	a0,a0
ffffffffc0201b14:	8082                	ret

ffffffffc0201b16 <sbi_shutdown>:

void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201b16:	00004797          	auipc	a5,0x4
ffffffffc0201b1a:	4fa78793          	addi	a5,a5,1274 # ffffffffc0206010 <SBI_SHUTDOWN>
    __asm__ volatile(
ffffffffc0201b1e:	6398                	ld	a4,0(a5)
ffffffffc0201b20:	4781                	li	a5,0
ffffffffc0201b22:	88ba                	mv	a7,a4
ffffffffc0201b24:	853e                	mv	a0,a5
ffffffffc0201b26:	85be                	mv	a1,a5
ffffffffc0201b28:	863e                	mv	a2,a5
ffffffffc0201b2a:	00000073          	ecall
ffffffffc0201b2e:	87aa                	mv	a5,a0
ffffffffc0201b30:	8082                	ret

ffffffffc0201b32 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201b32:	c185                	beqz	a1,ffffffffc0201b52 <strnlen+0x20>
ffffffffc0201b34:	00054783          	lbu	a5,0(a0)
ffffffffc0201b38:	cf89                	beqz	a5,ffffffffc0201b52 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0201b3a:	4781                	li	a5,0
ffffffffc0201b3c:	a021                	j	ffffffffc0201b44 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201b3e:	00074703          	lbu	a4,0(a4)
ffffffffc0201b42:	c711                	beqz	a4,ffffffffc0201b4e <strnlen+0x1c>
        cnt ++;
ffffffffc0201b44:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201b46:	00f50733          	add	a4,a0,a5
ffffffffc0201b4a:	fef59ae3          	bne	a1,a5,ffffffffc0201b3e <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0201b4e:	853e                	mv	a0,a5
ffffffffc0201b50:	8082                	ret
    size_t cnt = 0;
ffffffffc0201b52:	4781                	li	a5,0
}
ffffffffc0201b54:	853e                	mv	a0,a5
ffffffffc0201b56:	8082                	ret

ffffffffc0201b58 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201b58:	00054783          	lbu	a5,0(a0)
ffffffffc0201b5c:	0005c703          	lbu	a4,0(a1) # fffffffffffff000 <end+0x3fdf8a98>
ffffffffc0201b60:	cb91                	beqz	a5,ffffffffc0201b74 <strcmp+0x1c>
ffffffffc0201b62:	00e79c63          	bne	a5,a4,ffffffffc0201b7a <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0201b66:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201b68:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0201b6c:	0585                	addi	a1,a1,1
ffffffffc0201b6e:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201b72:	fbe5                	bnez	a5,ffffffffc0201b62 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201b74:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201b76:	9d19                	subw	a0,a0,a4
ffffffffc0201b78:	8082                	ret
ffffffffc0201b7a:	0007851b          	sext.w	a0,a5
ffffffffc0201b7e:	9d19                	subw	a0,a0,a4
ffffffffc0201b80:	8082                	ret

ffffffffc0201b82 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201b82:	00054783          	lbu	a5,0(a0)
ffffffffc0201b86:	cb91                	beqz	a5,ffffffffc0201b9a <strchr+0x18>
        if (*s == c) {
ffffffffc0201b88:	00b79563          	bne	a5,a1,ffffffffc0201b92 <strchr+0x10>
ffffffffc0201b8c:	a809                	j	ffffffffc0201b9e <strchr+0x1c>
ffffffffc0201b8e:	00b78763          	beq	a5,a1,ffffffffc0201b9c <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0201b92:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201b94:	00054783          	lbu	a5,0(a0)
ffffffffc0201b98:	fbfd                	bnez	a5,ffffffffc0201b8e <strchr+0xc>
    }
    return NULL;
ffffffffc0201b9a:	4501                	li	a0,0
}
ffffffffc0201b9c:	8082                	ret
ffffffffc0201b9e:	8082                	ret

ffffffffc0201ba0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201ba0:	ca01                	beqz	a2,ffffffffc0201bb0 <memset+0x10>
ffffffffc0201ba2:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201ba4:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201ba6:	0785                	addi	a5,a5,1
ffffffffc0201ba8:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201bac:	fec79de3          	bne	a5,a2,ffffffffc0201ba6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201bb0:	8082                	ret
