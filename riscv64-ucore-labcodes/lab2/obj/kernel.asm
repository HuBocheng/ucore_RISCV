
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
    # t1 := 0xffffffff40000000 即虚实映射偏移量，这一步是得到虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号（物理地址右移12位抹除低12位后得到物理页号）
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39 39位虚拟地址模式
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    //一个按位或操作把satp的MODE字段，高1000后面全0，和三级页表的物理页号t1合并到一起
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    // satp放的是最高级页表的物理页号（44位），除此以外还有MODE字段（4位）、备用 ASID（address space identifier）16位
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
ffffffffc020004e:	38b010ef          	jal	ra,ffffffffc0201bd8 <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fe000ef          	jal	ra,ffffffffc0200450 <cons_init>
    const char *message = "(NKU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00002517          	auipc	a0,0x2
ffffffffc020005a:	b9a50513          	addi	a0,a0,-1126 # ffffffffc0201bf0 <etext+0x6>
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
ffffffffc02000aa:	604010ef          	jal	ra,ffffffffc02016ae <vprintfmt>
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
ffffffffc02000de:	5d0010ef          	jal	ra,ffffffffc02016ae <vprintfmt>
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
ffffffffc0200144:	b0050513          	addi	a0,a0,-1280 # ffffffffc0201c40 <etext+0x56>
void print_kerninfo(void) {
ffffffffc0200148:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014a:	f6dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014e:	00000597          	auipc	a1,0x0
ffffffffc0200152:	ee858593          	addi	a1,a1,-280 # ffffffffc0200036 <kern_init>
ffffffffc0200156:	00002517          	auipc	a0,0x2
ffffffffc020015a:	b0a50513          	addi	a0,a0,-1270 # ffffffffc0201c60 <etext+0x76>
ffffffffc020015e:	f59ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200162:	00002597          	auipc	a1,0x2
ffffffffc0200166:	a8858593          	addi	a1,a1,-1400 # ffffffffc0201bea <etext>
ffffffffc020016a:	00002517          	auipc	a0,0x2
ffffffffc020016e:	b1650513          	addi	a0,a0,-1258 # ffffffffc0201c80 <etext+0x96>
ffffffffc0200172:	f45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200176:	00006597          	auipc	a1,0x6
ffffffffc020017a:	ea258593          	addi	a1,a1,-350 # ffffffffc0206018 <edata>
ffffffffc020017e:	00002517          	auipc	a0,0x2
ffffffffc0200182:	b2250513          	addi	a0,a0,-1246 # ffffffffc0201ca0 <etext+0xb6>
ffffffffc0200186:	f31ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018a:	00006597          	auipc	a1,0x6
ffffffffc020018e:	3de58593          	addi	a1,a1,990 # ffffffffc0206568 <end>
ffffffffc0200192:	00002517          	auipc	a0,0x2
ffffffffc0200196:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0201cc0 <etext+0xd6>
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
ffffffffc02001c4:	b2050513          	addi	a0,a0,-1248 # ffffffffc0201ce0 <etext+0xf6>
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
ffffffffc02001d4:	a4060613          	addi	a2,a2,-1472 # ffffffffc0201c10 <etext+0x26>
ffffffffc02001d8:	04e00593          	li	a1,78
ffffffffc02001dc:	00002517          	auipc	a0,0x2
ffffffffc02001e0:	a4c50513          	addi	a0,a0,-1460 # ffffffffc0201c28 <etext+0x3e>
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
ffffffffc02001f0:	c0460613          	addi	a2,a2,-1020 # ffffffffc0201df0 <commands+0xe0>
ffffffffc02001f4:	00002597          	auipc	a1,0x2
ffffffffc02001f8:	c1c58593          	addi	a1,a1,-996 # ffffffffc0201e10 <commands+0x100>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	c1c50513          	addi	a0,a0,-996 # ffffffffc0201e18 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200206:	eb1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020020a:	00002617          	auipc	a2,0x2
ffffffffc020020e:	c1e60613          	addi	a2,a2,-994 # ffffffffc0201e28 <commands+0x118>
ffffffffc0200212:	00002597          	auipc	a1,0x2
ffffffffc0200216:	c3e58593          	addi	a1,a1,-962 # ffffffffc0201e50 <commands+0x140>
ffffffffc020021a:	00002517          	auipc	a0,0x2
ffffffffc020021e:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0201e18 <commands+0x108>
ffffffffc0200222:	e95ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200226:	00002617          	auipc	a2,0x2
ffffffffc020022a:	c3a60613          	addi	a2,a2,-966 # ffffffffc0201e60 <commands+0x150>
ffffffffc020022e:	00002597          	auipc	a1,0x2
ffffffffc0200232:	c5258593          	addi	a1,a1,-942 # ffffffffc0201e80 <commands+0x170>
ffffffffc0200236:	00002517          	auipc	a0,0x2
ffffffffc020023a:	be250513          	addi	a0,a0,-1054 # ffffffffc0201e18 <commands+0x108>
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
ffffffffc0200274:	ae850513          	addi	a0,a0,-1304 # ffffffffc0201d58 <commands+0x48>
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
ffffffffc0200296:	aee50513          	addi	a0,a0,-1298 # ffffffffc0201d80 <commands+0x70>
ffffffffc020029a:	e1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (tf != NULL) {
ffffffffc020029e:	000c0563          	beqz	s8,ffffffffc02002a8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a2:	8562                	mv	a0,s8
ffffffffc02002a4:	3a6000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002a8:	00002c97          	auipc	s9,0x2
ffffffffc02002ac:	a68c8c93          	addi	s9,s9,-1432 # ffffffffc0201d10 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b0:	00002997          	auipc	s3,0x2
ffffffffc02002b4:	af898993          	addi	s3,s3,-1288 # ffffffffc0201da8 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00002917          	auipc	s2,0x2
ffffffffc02002bc:	af890913          	addi	s2,s2,-1288 # ffffffffc0201db0 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002c0:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c2:	00002b17          	auipc	s6,0x2
ffffffffc02002c6:	af6b0b13          	addi	s6,s6,-1290 # ffffffffc0201db8 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ca:	00002a97          	auipc	s5,0x2
ffffffffc02002ce:	b46a8a93          	addi	s5,s5,-1210 # ffffffffc0201e10 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d2:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d4:	854e                	mv	a0,s3
ffffffffc02002d6:	764010ef          	jal	ra,ffffffffc0201a3a <readline>
ffffffffc02002da:	842a                	mv	s0,a0
ffffffffc02002dc:	dd65                	beqz	a0,ffffffffc02002d4 <kmonitor+0x6a>
ffffffffc02002de:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e4:	c999                	beqz	a1,ffffffffc02002fa <kmonitor+0x90>
ffffffffc02002e6:	854a                	mv	a0,s2
ffffffffc02002e8:	0d3010ef          	jal	ra,ffffffffc0201bba <strchr>
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
ffffffffc0200302:	a12d0d13          	addi	s10,s10,-1518 # ffffffffc0201d10 <commands>
    if (argc == 0) {
ffffffffc0200306:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200308:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	0d61                	addi	s10,s10,24
ffffffffc020030c:	085010ef          	jal	ra,ffffffffc0201b90 <strcmp>
ffffffffc0200310:	c919                	beqz	a0,ffffffffc0200326 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200312:	2405                	addiw	s0,s0,1
ffffffffc0200314:	09740463          	beq	s0,s7,ffffffffc020039c <kmonitor+0x132>
ffffffffc0200318:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031c:	6582                	ld	a1,0(sp)
ffffffffc020031e:	0d61                	addi	s10,s10,24
ffffffffc0200320:	071010ef          	jal	ra,ffffffffc0201b90 <strcmp>
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
ffffffffc0200386:	035010ef          	jal	ra,ffffffffc0201bba <strchr>
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
ffffffffc02003a2:	a3a50513          	addi	a0,a0,-1478 # ffffffffc0201dd8 <commands+0xc8>
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
ffffffffc02003e2:	ab250513          	addi	a0,a0,-1358 # ffffffffc0201e90 <commands+0x180>
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
ffffffffc02003f8:	25450513          	addi	a0,a0,596 # ffffffffc0202648 <commands+0x938>
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
ffffffffc0200424:	6f0010ef          	jal	ra,ffffffffc0201b14 <sbi_set_timer>
}
ffffffffc0200428:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042a:	00006797          	auipc	a5,0x6
ffffffffc020042e:	0007bb23          	sd	zero,22(a5) # ffffffffc0206440 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200432:	00002517          	auipc	a0,0x2
ffffffffc0200436:	a7e50513          	addi	a0,a0,-1410 # ffffffffc0201eb0 <commands+0x1a0>
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
ffffffffc020044c:	6c80106f          	j	ffffffffc0201b14 <sbi_set_timer>

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
ffffffffc0200456:	6a20106f          	j	ffffffffc0201af8 <sbi_console_putchar>

ffffffffc020045a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045a:	6d60106f          	j	ffffffffc0201b30 <sbi_console_getchar>

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
ffffffffc0200488:	b4450513          	addi	a0,a0,-1212 # ffffffffc0201fc8 <commands+0x2b8>
{
ffffffffc020048c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048e:	c29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200492:	640c                	ld	a1,8(s0)
ffffffffc0200494:	00002517          	auipc	a0,0x2
ffffffffc0200498:	b4c50513          	addi	a0,a0,-1204 # ffffffffc0201fe0 <commands+0x2d0>
ffffffffc020049c:	c1bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a0:	680c                	ld	a1,16(s0)
ffffffffc02004a2:	00002517          	auipc	a0,0x2
ffffffffc02004a6:	b5650513          	addi	a0,a0,-1194 # ffffffffc0201ff8 <commands+0x2e8>
ffffffffc02004aa:	c0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004ae:	6c0c                	ld	a1,24(s0)
ffffffffc02004b0:	00002517          	auipc	a0,0x2
ffffffffc02004b4:	b6050513          	addi	a0,a0,-1184 # ffffffffc0202010 <commands+0x300>
ffffffffc02004b8:	bffff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004bc:	700c                	ld	a1,32(s0)
ffffffffc02004be:	00002517          	auipc	a0,0x2
ffffffffc02004c2:	b6a50513          	addi	a0,a0,-1174 # ffffffffc0202028 <commands+0x318>
ffffffffc02004c6:	bf1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004ca:	740c                	ld	a1,40(s0)
ffffffffc02004cc:	00002517          	auipc	a0,0x2
ffffffffc02004d0:	b7450513          	addi	a0,a0,-1164 # ffffffffc0202040 <commands+0x330>
ffffffffc02004d4:	be3ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d8:	780c                	ld	a1,48(s0)
ffffffffc02004da:	00002517          	auipc	a0,0x2
ffffffffc02004de:	b7e50513          	addi	a0,a0,-1154 # ffffffffc0202058 <commands+0x348>
ffffffffc02004e2:	bd5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e6:	7c0c                	ld	a1,56(s0)
ffffffffc02004e8:	00002517          	auipc	a0,0x2
ffffffffc02004ec:	b8850513          	addi	a0,a0,-1144 # ffffffffc0202070 <commands+0x360>
ffffffffc02004f0:	bc7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f4:	602c                	ld	a1,64(s0)
ffffffffc02004f6:	00002517          	auipc	a0,0x2
ffffffffc02004fa:	b9250513          	addi	a0,a0,-1134 # ffffffffc0202088 <commands+0x378>
ffffffffc02004fe:	bb9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200502:	642c                	ld	a1,72(s0)
ffffffffc0200504:	00002517          	auipc	a0,0x2
ffffffffc0200508:	b9c50513          	addi	a0,a0,-1124 # ffffffffc02020a0 <commands+0x390>
ffffffffc020050c:	babff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200510:	682c                	ld	a1,80(s0)
ffffffffc0200512:	00002517          	auipc	a0,0x2
ffffffffc0200516:	ba650513          	addi	a0,a0,-1114 # ffffffffc02020b8 <commands+0x3a8>
ffffffffc020051a:	b9dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051e:	6c2c                	ld	a1,88(s0)
ffffffffc0200520:	00002517          	auipc	a0,0x2
ffffffffc0200524:	bb050513          	addi	a0,a0,-1104 # ffffffffc02020d0 <commands+0x3c0>
ffffffffc0200528:	b8fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052c:	702c                	ld	a1,96(s0)
ffffffffc020052e:	00002517          	auipc	a0,0x2
ffffffffc0200532:	bba50513          	addi	a0,a0,-1094 # ffffffffc02020e8 <commands+0x3d8>
ffffffffc0200536:	b81ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053a:	742c                	ld	a1,104(s0)
ffffffffc020053c:	00002517          	auipc	a0,0x2
ffffffffc0200540:	bc450513          	addi	a0,a0,-1084 # ffffffffc0202100 <commands+0x3f0>
ffffffffc0200544:	b73ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200548:	782c                	ld	a1,112(s0)
ffffffffc020054a:	00002517          	auipc	a0,0x2
ffffffffc020054e:	bce50513          	addi	a0,a0,-1074 # ffffffffc0202118 <commands+0x408>
ffffffffc0200552:	b65ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200556:	7c2c                	ld	a1,120(s0)
ffffffffc0200558:	00002517          	auipc	a0,0x2
ffffffffc020055c:	bd850513          	addi	a0,a0,-1064 # ffffffffc0202130 <commands+0x420>
ffffffffc0200560:	b57ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200564:	604c                	ld	a1,128(s0)
ffffffffc0200566:	00002517          	auipc	a0,0x2
ffffffffc020056a:	be250513          	addi	a0,a0,-1054 # ffffffffc0202148 <commands+0x438>
ffffffffc020056e:	b49ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200572:	644c                	ld	a1,136(s0)
ffffffffc0200574:	00002517          	auipc	a0,0x2
ffffffffc0200578:	bec50513          	addi	a0,a0,-1044 # ffffffffc0202160 <commands+0x450>
ffffffffc020057c:	b3bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200580:	684c                	ld	a1,144(s0)
ffffffffc0200582:	00002517          	auipc	a0,0x2
ffffffffc0200586:	bf650513          	addi	a0,a0,-1034 # ffffffffc0202178 <commands+0x468>
ffffffffc020058a:	b2dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058e:	6c4c                	ld	a1,152(s0)
ffffffffc0200590:	00002517          	auipc	a0,0x2
ffffffffc0200594:	c0050513          	addi	a0,a0,-1024 # ffffffffc0202190 <commands+0x480>
ffffffffc0200598:	b1fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059c:	704c                	ld	a1,160(s0)
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	c0a50513          	addi	a0,a0,-1014 # ffffffffc02021a8 <commands+0x498>
ffffffffc02005a6:	b11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005aa:	744c                	ld	a1,168(s0)
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	c1450513          	addi	a0,a0,-1004 # ffffffffc02021c0 <commands+0x4b0>
ffffffffc02005b4:	b03ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b8:	784c                	ld	a1,176(s0)
ffffffffc02005ba:	00002517          	auipc	a0,0x2
ffffffffc02005be:	c1e50513          	addi	a0,a0,-994 # ffffffffc02021d8 <commands+0x4c8>
ffffffffc02005c2:	af5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c6:	7c4c                	ld	a1,184(s0)
ffffffffc02005c8:	00002517          	auipc	a0,0x2
ffffffffc02005cc:	c2850513          	addi	a0,a0,-984 # ffffffffc02021f0 <commands+0x4e0>
ffffffffc02005d0:	ae7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d4:	606c                	ld	a1,192(s0)
ffffffffc02005d6:	00002517          	auipc	a0,0x2
ffffffffc02005da:	c3250513          	addi	a0,a0,-974 # ffffffffc0202208 <commands+0x4f8>
ffffffffc02005de:	ad9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e2:	646c                	ld	a1,200(s0)
ffffffffc02005e4:	00002517          	auipc	a0,0x2
ffffffffc02005e8:	c3c50513          	addi	a0,a0,-964 # ffffffffc0202220 <commands+0x510>
ffffffffc02005ec:	acbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f0:	686c                	ld	a1,208(s0)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	c4650513          	addi	a0,a0,-954 # ffffffffc0202238 <commands+0x528>
ffffffffc02005fa:	abdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200600:	00002517          	auipc	a0,0x2
ffffffffc0200604:	c5050513          	addi	a0,a0,-944 # ffffffffc0202250 <commands+0x540>
ffffffffc0200608:	aafff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060c:	706c                	ld	a1,224(s0)
ffffffffc020060e:	00002517          	auipc	a0,0x2
ffffffffc0200612:	c5a50513          	addi	a0,a0,-934 # ffffffffc0202268 <commands+0x558>
ffffffffc0200616:	aa1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061a:	746c                	ld	a1,232(s0)
ffffffffc020061c:	00002517          	auipc	a0,0x2
ffffffffc0200620:	c6450513          	addi	a0,a0,-924 # ffffffffc0202280 <commands+0x570>
ffffffffc0200624:	a93ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200628:	786c                	ld	a1,240(s0)
ffffffffc020062a:	00002517          	auipc	a0,0x2
ffffffffc020062e:	c6e50513          	addi	a0,a0,-914 # ffffffffc0202298 <commands+0x588>
ffffffffc0200632:	a85ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200638:	6402                	ld	s0,0(sp)
ffffffffc020063a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	c7450513          	addi	a0,a0,-908 # ffffffffc02022b0 <commands+0x5a0>
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
ffffffffc0200656:	c7650513          	addi	a0,a0,-906 # ffffffffc02022c8 <commands+0x5b8>
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
ffffffffc020066e:	c7650513          	addi	a0,a0,-906 # ffffffffc02022e0 <commands+0x5d0>
ffffffffc0200672:	a45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	c7e50513          	addi	a0,a0,-898 # ffffffffc02022f8 <commands+0x5e8>
ffffffffc0200682:	a35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	c8650513          	addi	a0,a0,-890 # ffffffffc0202310 <commands+0x600>
ffffffffc0200692:	a25ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	c8a50513          	addi	a0,a0,-886 # ffffffffc0202328 <commands+0x618>
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
ffffffffc02006bc:	00002717          	auipc	a4,0x2
ffffffffc02006c0:	81070713          	addi	a4,a4,-2032 # ffffffffc0201ecc <commands+0x1bc>
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
ffffffffc02006d2:	89250513          	addi	a0,a0,-1902 # ffffffffc0201f60 <commands+0x250>
ffffffffc02006d6:	9e1ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc02006da:	00002517          	auipc	a0,0x2
ffffffffc02006de:	86650513          	addi	a0,a0,-1946 # ffffffffc0201f40 <commands+0x230>
ffffffffc02006e2:	9d5ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc02006e6:	00002517          	auipc	a0,0x2
ffffffffc02006ea:	81a50513          	addi	a0,a0,-2022 # ffffffffc0201f00 <commands+0x1f0>
ffffffffc02006ee:	9c9ff06f          	j	ffffffffc02000b6 <cprintf>
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
ffffffffc02006f2:	00002517          	auipc	a0,0x2
ffffffffc02006f6:	88e50513          	addi	a0,a0,-1906 # ffffffffc0201f80 <commands+0x270>
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
ffffffffc0200732:	87a50513          	addi	a0,a0,-1926 # ffffffffc0201fa8 <commands+0x298>
ffffffffc0200736:	981ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc020073a:	00001517          	auipc	a0,0x1
ffffffffc020073e:	7e650513          	addi	a0,a0,2022 # ffffffffc0201f20 <commands+0x210>
ffffffffc0200742:	975ff06f          	j	ffffffffc02000b6 <cprintf>
        print_trapframe(tf);
ffffffffc0200746:	f05ff06f          	j	ffffffffc020064a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020074a:	06400593          	li	a1,100
ffffffffc020074e:	00002517          	auipc	a0,0x2
ffffffffc0200752:	84a50513          	addi	a0,a0,-1974 # ffffffffc0201f98 <commands+0x288>
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
ffffffffc0200780:	3ce010ef          	jal	ra,ffffffffc0201b4e <sbi_shutdown>
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
ffffffffc0200940:	e7c68693          	addi	a3,a3,-388 # ffffffffc02027b8 <commands+0xaa8>
ffffffffc0200944:	00002617          	auipc	a2,0x2
ffffffffc0200948:	e3c60613          	addi	a2,a2,-452 # ffffffffc0202780 <commands+0xa70>
ffffffffc020094c:	09b00593          	li	a1,155
ffffffffc0200950:	00002517          	auipc	a0,0x2
ffffffffc0200954:	e4850513          	addi	a0,a0,-440 # ffffffffc0202798 <commands+0xa88>
ffffffffc0200958:	a55ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc020095c:	00002697          	auipc	a3,0x2
ffffffffc0200960:	e1c68693          	addi	a3,a3,-484 # ffffffffc0202778 <commands+0xa68>
ffffffffc0200964:	00002617          	auipc	a2,0x2
ffffffffc0200968:	e1c60613          	addi	a2,a2,-484 # ffffffffc0202780 <commands+0xa70>
ffffffffc020096c:	09200593          	li	a1,146
ffffffffc0200970:	00002517          	auipc	a0,0x2
ffffffffc0200974:	e2850513          	addi	a0,a0,-472 # ffffffffc0202798 <commands+0xa88>
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
ffffffffc0200b1a:	84268693          	addi	a3,a3,-1982 # ffffffffc0202358 <commands+0x648>
ffffffffc0200b1e:	00002617          	auipc	a2,0x2
ffffffffc0200b22:	c6260613          	addi	a2,a2,-926 # ffffffffc0202780 <commands+0xa70>
ffffffffc0200b26:	04a00593          	li	a1,74
ffffffffc0200b2a:	00002517          	auipc	a0,0x2
ffffffffc0200b2e:	c6e50513          	addi	a0,a0,-914 # ffffffffc0202798 <commands+0xa88>
ffffffffc0200b32:	87bff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(requested_pages > 0);
ffffffffc0200b36:	00002697          	auipc	a3,0x2
ffffffffc0200b3a:	80a68693          	addi	a3,a3,-2038 # ffffffffc0202340 <commands+0x630>
ffffffffc0200b3e:	00002617          	auipc	a2,0x2
ffffffffc0200b42:	c4260613          	addi	a2,a2,-958 # ffffffffc0202780 <commands+0xa70>
ffffffffc0200b46:	0ac00593          	li	a1,172
ffffffffc0200b4a:	00002517          	auipc	a0,0x2
ffffffffc0200b4e:	c4e50513          	addi	a0,a0,-946 # ffffffffc0202798 <commands+0xa88>
ffffffffc0200b52:	85bff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!list_empty(&(buddy_array[n])));
ffffffffc0200b56:	00002697          	auipc	a3,0x2
ffffffffc0200b5a:	81a68693          	addi	a3,a3,-2022 # ffffffffc0202370 <commands+0x660>
ffffffffc0200b5e:	00002617          	auipc	a2,0x2
ffffffffc0200b62:	c2260613          	addi	a2,a2,-990 # ffffffffc0202780 <commands+0xa70>
ffffffffc0200b66:	04b00593          	li	a1,75
ffffffffc0200b6a:	00002517          	auipc	a0,0x2
ffffffffc0200b6e:	c2e50513          	addi	a0,a0,-978 # ffffffffc0202798 <commands+0xa88>
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
ffffffffc0200ba2:	caa50513          	addi	a0,a0,-854 # ffffffffc0202848 <buddy_system_pmm_manager+0x80>
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
ffffffffc0200bba:	cd2b0b13          	addi	s6,s6,-814 # ffffffffc0202888 <buddy_system_pmm_manager+0xc0>
                cprintf("%d页 ", 1 << (p->property));
ffffffffc0200bbe:	4a85                	li	s5,1
ffffffffc0200bc0:	00002a17          	auipc	s4,0x2
ffffffffc0200bc4:	ce0a0a13          	addi	s4,s4,-800 # ffffffffc02028a0 <buddy_system_pmm_manager+0xd8>
                cprintf("【地址为%p】\n", p);
ffffffffc0200bc8:	00002997          	auipc	s3,0x2
ffffffffc0200bcc:	ce098993          	addi	s3,s3,-800 # ffffffffc02028a8 <buddy_system_pmm_manager+0xe0>
            if (i != right)
ffffffffc0200bd0:	4c39                	li	s8,14
                cprintf("\n");
ffffffffc0200bd2:	00002c97          	auipc	s9,0x2
ffffffffc0200bd6:	a76c8c93          	addi	s9,s9,-1418 # ffffffffc0202648 <commands+0x938>
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
ffffffffc0200c26:	c9e50513          	addi	a0,a0,-866 # ffffffffc02028c0 <buddy_system_pmm_manager+0xf8>
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
ffffffffc0200c48:	c9450513          	addi	a0,a0,-876 # ffffffffc02028d8 <buddy_system_pmm_manager+0x110>
}
ffffffffc0200c4c:	6125                	addi	sp,sp,96
    cprintf("======================显示完成======================\n\n\n");
ffffffffc0200c4e:	c68ff06f          	j	ffffffffc02000b6 <cprintf>
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
ffffffffc0200c52:	00002697          	auipc	a3,0x2
ffffffffc0200c56:	bae68693          	addi	a3,a3,-1106 # ffffffffc0202800 <buddy_system_pmm_manager+0x38>
ffffffffc0200c5a:	00002617          	auipc	a2,0x2
ffffffffc0200c5e:	b2660613          	addi	a2,a2,-1242 # ffffffffc0202780 <commands+0xa70>
ffffffffc0200c62:	06300593          	li	a1,99
ffffffffc0200c66:	00002517          	auipc	a0,0x2
ffffffffc0200c6a:	b3250513          	addi	a0,a0,-1230 # ffffffffc0202798 <commands+0xa88>
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
ffffffffc0200c86:	71650513          	addi	a0,a0,1814 # ffffffffc0202398 <commands+0x688>
{
ffffffffc0200c8a:	f406                	sd	ra,40(sp)
ffffffffc0200c8c:	f022                	sd	s0,32(sp)
ffffffffc0200c8e:	ec26                	sd	s1,24(sp)
ffffffffc0200c90:	e84a                	sd	s2,16(sp)
    cprintf("总空闲块数目为：%d\n", nr_free);
ffffffffc0200c92:	c24ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("首先p0请求5页\n");
ffffffffc0200c96:	00001517          	auipc	a0,0x1
ffffffffc0200c9a:	72250513          	addi	a0,a0,1826 # ffffffffc02023b8 <commands+0x6a8>
ffffffffc0200c9e:	c18ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    p0 = alloc_pages(5);
ffffffffc0200ca2:	4515                	li	a0,5
ffffffffc0200ca4:	586000ef          	jal	ra,ffffffffc020122a <alloc_pages>
ffffffffc0200ca8:	84aa                	mv	s1,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200caa:	ecdff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>
    cprintf("然后p1请求5页\n");
ffffffffc0200cae:	00001517          	auipc	a0,0x1
ffffffffc0200cb2:	72250513          	addi	a0,a0,1826 # ffffffffc02023d0 <commands+0x6c0>
ffffffffc0200cb6:	c00ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    p1 = alloc_pages(5);
ffffffffc0200cba:	4515                	li	a0,5
ffffffffc0200cbc:	56e000ef          	jal	ra,ffffffffc020122a <alloc_pages>
ffffffffc0200cc0:	842a                	mv	s0,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200cc2:	eb5ff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>
    cprintf("最后p2请求5页\n");
ffffffffc0200cc6:	00001517          	auipc	a0,0x1
ffffffffc0200cca:	72250513          	addi	a0,a0,1826 # ffffffffc02023e8 <commands+0x6d8>
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
ffffffffc0200ce4:	72050513          	addi	a0,a0,1824 # ffffffffc0202400 <commands+0x6f0>
ffffffffc0200ce8:	bceff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("p1的虚拟地址0x%016lx.\n", p1);
ffffffffc0200cec:	85a2                	mv	a1,s0
ffffffffc0200cee:	00001517          	auipc	a0,0x1
ffffffffc0200cf2:	73250513          	addi	a0,a0,1842 # ffffffffc0202420 <commands+0x710>
ffffffffc0200cf6:	bc0ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("p2的虚拟地址0x%016lx.\n", p2);
ffffffffc0200cfa:	85ca                	mv	a1,s2
ffffffffc0200cfc:	00001517          	auipc	a0,0x1
ffffffffc0200d00:	74450513          	addi	a0,a0,1860 # ffffffffc0202440 <commands+0x730>
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
ffffffffc0200d36:	65e70713          	addi	a4,a4,1630 # ffffffffc0202390 <commands+0x680>
ffffffffc0200d3a:	630c                	ld	a1,0(a4)
ffffffffc0200d3c:	40f48733          	sub	a4,s1,a5
ffffffffc0200d40:	870d                	srai	a4,a4,0x3
ffffffffc0200d42:	02b70733          	mul	a4,a4,a1
ffffffffc0200d46:	00002697          	auipc	a3,0x2
ffffffffc0200d4a:	15268693          	addi	a3,a3,338 # ffffffffc0202e98 <nbase>
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
ffffffffc0200d9e:	7a650513          	addi	a0,a0,1958 # ffffffffc0202540 <commands+0x830>
ffffffffc0200da2:	b14ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(p0, 5);
ffffffffc0200da6:	4595                	li	a1,5
ffffffffc0200da8:	8526                	mv	a0,s1
ffffffffc0200daa:	4c4000ef          	jal	ra,ffffffffc020126e <free_pages>
    cprintf("释放p0后，总空闲块数目为：%d\n", nr_free); // 变成了8
ffffffffc0200dae:	0f89a583          	lw	a1,248(s3)
ffffffffc0200db2:	00001517          	auipc	a0,0x1
ffffffffc0200db6:	7ae50513          	addi	a0,a0,1966 # ffffffffc0202560 <commands+0x850>
ffffffffc0200dba:	afcff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200dbe:	db9ff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>
    cprintf("释放p1中。。。。。。\n");
ffffffffc0200dc2:	00001517          	auipc	a0,0x1
ffffffffc0200dc6:	7ce50513          	addi	a0,a0,1998 # ffffffffc0202590 <commands+0x880>
ffffffffc0200dca:	aecff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(p1, 5);
ffffffffc0200dce:	8522                	mv	a0,s0
ffffffffc0200dd0:	4595                	li	a1,5
ffffffffc0200dd2:	49c000ef          	jal	ra,ffffffffc020126e <free_pages>
    cprintf("释放p1后，总空闲块数目为：%d\n", nr_free); // 变成了16
ffffffffc0200dd6:	0f89a583          	lw	a1,248(s3)
ffffffffc0200dda:	00001517          	auipc	a0,0x1
ffffffffc0200dde:	7d650513          	addi	a0,a0,2006 # ffffffffc02025b0 <commands+0x8a0>
ffffffffc0200de2:	ad4ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200de6:	d91ff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>
    cprintf("释放p2中。。。。。。\n");
ffffffffc0200dea:	00001517          	auipc	a0,0x1
ffffffffc0200dee:	7f650513          	addi	a0,a0,2038 # ffffffffc02025e0 <commands+0x8d0>
ffffffffc0200df2:	ac4ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(p2, 5);
ffffffffc0200df6:	4595                	li	a1,5
ffffffffc0200df8:	854a                	mv	a0,s2
ffffffffc0200dfa:	474000ef          	jal	ra,ffffffffc020126e <free_pages>
    cprintf("释放p2后，总空闲块数目为：%d\n", nr_free); // 变成了24
ffffffffc0200dfe:	0f89a583          	lw	a1,248(s3)
ffffffffc0200e02:	00001517          	auipc	a0,0x1
ffffffffc0200e06:	7fe50513          	addi	a0,a0,2046 # ffffffffc0202600 <commands+0x8f0>
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
ffffffffc0200e24:	00002517          	auipc	a0,0x2
ffffffffc0200e28:	80c50513          	addi	a0,a0,-2036 # ffffffffc0202630 <commands+0x920>
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
ffffffffc0200e40:	00002517          	auipc	a0,0x2
ffffffffc0200e44:	81050513          	addi	a0,a0,-2032 # ffffffffc0202650 <commands+0x940>
ffffffffc0200e48:	a6eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("首先p0请求5页\n");
ffffffffc0200e4c:	00001517          	auipc	a0,0x1
ffffffffc0200e50:	56c50513          	addi	a0,a0,1388 # ffffffffc02023b8 <commands+0x6a8>
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
ffffffffc0200e76:	83e50513          	addi	a0,a0,-1986 # ffffffffc02026b0 <commands+0x9a0>
ffffffffc0200e7a:	a3cff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    p1 = alloc_pages(15);
ffffffffc0200e7e:	453d                	li	a0,15
ffffffffc0200e80:	3aa000ef          	jal	ra,ffffffffc020122a <alloc_pages>
ffffffffc0200e84:	892a                	mv	s2,a0
    show_buddy_array(0, MAX_BUDDY_ORDER);
ffffffffc0200e86:	cf1ff0ef          	jal	ra,ffffffffc0200b76 <show_buddy_array.constprop.4>

    cprintf("最后p2请求21页\n");
ffffffffc0200e8a:	00002517          	auipc	a0,0x2
ffffffffc0200e8e:	83e50513          	addi	a0,a0,-1986 # ffffffffc02026c8 <commands+0x9b8>
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
ffffffffc0200ea8:	55c50513          	addi	a0,a0,1372 # ffffffffc0202400 <commands+0x6f0>
ffffffffc0200eac:	a0aff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("p1的虚拟地址0x%016lx.\n", p1);
ffffffffc0200eb0:	85ca                	mv	a1,s2
ffffffffc0200eb2:	00001517          	auipc	a0,0x1
ffffffffc0200eb6:	56e50513          	addi	a0,a0,1390 # ffffffffc0202420 <commands+0x710>
ffffffffc0200eba:	9fcff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("p2的虚拟地址0x%016lx.\n", p2);
ffffffffc0200ebe:	85a6                	mv	a1,s1
ffffffffc0200ec0:	00001517          	auipc	a0,0x1
ffffffffc0200ec4:	58050513          	addi	a0,a0,1408 # ffffffffc0202440 <commands+0x730>
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
ffffffffc0200f0c:	55868693          	addi	a3,a3,1368 # ffffffffc0202460 <commands+0x750>
ffffffffc0200f10:	00002617          	auipc	a2,0x2
ffffffffc0200f14:	87060613          	addi	a2,a2,-1936 # ffffffffc0202780 <commands+0xa70>
ffffffffc0200f18:	13700593          	li	a1,311
ffffffffc0200f1c:	00002517          	auipc	a0,0x2
ffffffffc0200f20:	87c50513          	addi	a0,a0,-1924 # ffffffffc0202798 <commands+0xa88>
ffffffffc0200f24:	c88ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0->property == 3 && p1->property == 4 && p2->property == 5);
ffffffffc0200f28:	00001697          	auipc	a3,0x1
ffffffffc0200f2c:	7b868693          	addi	a3,a3,1976 # ffffffffc02026e0 <commands+0x9d0>
ffffffffc0200f30:	00002617          	auipc	a2,0x2
ffffffffc0200f34:	85060613          	addi	a2,a2,-1968 # ffffffffc0202780 <commands+0xa70>
ffffffffc0200f38:	17c00593          	li	a1,380
ffffffffc0200f3c:	00002517          	auipc	a0,0x2
ffffffffc0200f40:	85c50513          	addi	a0,a0,-1956 # ffffffffc0202798 <commands+0xa88>
ffffffffc0200f44:	c68ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f48:	00001697          	auipc	a3,0x1
ffffffffc0200f4c:	54068693          	addi	a3,a3,1344 # ffffffffc0202488 <commands+0x778>
ffffffffc0200f50:	00002617          	auipc	a2,0x2
ffffffffc0200f54:	83060613          	addi	a2,a2,-2000 # ffffffffc0202780 <commands+0xa70>
ffffffffc0200f58:	13800593          	li	a1,312
ffffffffc0200f5c:	00002517          	auipc	a0,0x2
ffffffffc0200f60:	83c50513          	addi	a0,a0,-1988 # ffffffffc0202798 <commands+0xa88>
ffffffffc0200f64:	c48ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f68:	00001697          	auipc	a3,0x1
ffffffffc0200f6c:	58068693          	addi	a3,a3,1408 # ffffffffc02024e8 <commands+0x7d8>
ffffffffc0200f70:	00002617          	auipc	a2,0x2
ffffffffc0200f74:	81060613          	addi	a2,a2,-2032 # ffffffffc0202780 <commands+0xa70>
ffffffffc0200f78:	13b00593          	li	a1,315
ffffffffc0200f7c:	00002517          	auipc	a0,0x2
ffffffffc0200f80:	81c50513          	addi	a0,a0,-2020 # ffffffffc0202798 <commands+0xa88>
ffffffffc0200f84:	c28ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f88:	00001697          	auipc	a3,0x1
ffffffffc0200f8c:	58068693          	addi	a3,a3,1408 # ffffffffc0202508 <commands+0x7f8>
ffffffffc0200f90:	00001617          	auipc	a2,0x1
ffffffffc0200f94:	7f060613          	addi	a2,a2,2032 # ffffffffc0202780 <commands+0xa70>
ffffffffc0200f98:	13c00593          	li	a1,316
ffffffffc0200f9c:	00001517          	auipc	a0,0x1
ffffffffc0200fa0:	7fc50513          	addi	a0,a0,2044 # ffffffffc0202798 <commands+0xa88>
ffffffffc0200fa4:	c08ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fa8:	00001697          	auipc	a3,0x1
ffffffffc0200fac:	58068693          	addi	a3,a3,1408 # ffffffffc0202528 <commands+0x818>
ffffffffc0200fb0:	00001617          	auipc	a2,0x1
ffffffffc0200fb4:	7d060613          	addi	a2,a2,2000 # ffffffffc0202780 <commands+0xa70>
ffffffffc0200fb8:	14200593          	li	a1,322
ffffffffc0200fbc:	00001517          	auipc	a0,0x1
ffffffffc0200fc0:	7dc50513          	addi	a0,a0,2012 # ffffffffc0202798 <commands+0xa88>
ffffffffc0200fc4:	be8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 == temp);
ffffffffc0200fc8:	00001697          	auipc	a3,0x1
ffffffffc0200fcc:	75868693          	addi	a3,a3,1880 # ffffffffc0202720 <commands+0xa10>
ffffffffc0200fd0:	00001617          	auipc	a2,0x1
ffffffffc0200fd4:	7b060613          	addi	a2,a2,1968 # ffffffffc0202780 <commands+0xa70>
ffffffffc0200fd8:	18400593          	li	a1,388
ffffffffc0200fdc:	00001517          	auipc	a0,0x1
ffffffffc0200fe0:	7bc50513          	addi	a0,a0,1980 # ffffffffc0202798 <commands+0xa88>
ffffffffc0200fe4:	bc8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageProperty(p0));
ffffffffc0200fe8:	00001697          	auipc	a3,0x1
ffffffffc0200fec:	6b068693          	addi	a3,a3,1712 # ffffffffc0202698 <commands+0x988>
ffffffffc0200ff0:	00001617          	auipc	a2,0x1
ffffffffc0200ff4:	79060613          	addi	a2,a2,1936 # ffffffffc0202780 <commands+0xa70>
ffffffffc0200ff8:	16c00593          	li	a1,364
ffffffffc0200ffc:	00001517          	auipc	a0,0x1
ffffffffc0201000:	79c50513          	addi	a0,a0,1948 # ffffffffc0202798 <commands+0xa88>
ffffffffc0201004:	ba8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != NULL);
ffffffffc0201008:	00001697          	auipc	a3,0x1
ffffffffc020100c:	68068693          	addi	a3,a3,1664 # ffffffffc0202688 <commands+0x978>
ffffffffc0201010:	00001617          	auipc	a2,0x1
ffffffffc0201014:	77060613          	addi	a2,a2,1904 # ffffffffc0202780 <commands+0xa70>
ffffffffc0201018:	16b00593          	li	a1,363
ffffffffc020101c:	00001517          	auipc	a0,0x1
ffffffffc0201020:	77c50513          	addi	a0,a0,1916 # ffffffffc0202798 <commands+0xa88>
ffffffffc0201024:	b88ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201028:	00001697          	auipc	a3,0x1
ffffffffc020102c:	4a068693          	addi	a3,a3,1184 # ffffffffc02024c8 <commands+0x7b8>
ffffffffc0201030:	00001617          	auipc	a2,0x1
ffffffffc0201034:	75060613          	addi	a2,a2,1872 # ffffffffc0202780 <commands+0xa70>
ffffffffc0201038:	13a00593          	li	a1,314
ffffffffc020103c:	00001517          	auipc	a0,0x1
ffffffffc0201040:	75c50513          	addi	a0,a0,1884 # ffffffffc0202798 <commands+0xa88>
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
ffffffffc0201086:	30e70713          	addi	a4,a4,782 # ffffffffc0202390 <commands+0x680>
ffffffffc020108a:	630c                	ld	a1,0(a4)
ffffffffc020108c:	40f407b3          	sub	a5,s0,a5
ffffffffc0201090:	878d                	srai	a5,a5,0x3
ffffffffc0201092:	02b787b3          	mul	a5,a5,a1
ffffffffc0201096:	00002717          	auipc	a4,0x2
ffffffffc020109a:	e0270713          	addi	a4,a4,-510 # ffffffffc0202e98 <nbase>
    cprintf("BS算法将释放第NO.%d页开始的共%d页\n", page2ppn(base), pnum);
ffffffffc020109e:	630c                	ld	a1,0(a4)
ffffffffc02010a0:	00001517          	auipc	a0,0x1
ffffffffc02010a4:	6a850513          	addi	a0,a0,1704 # ffffffffc0202748 <commands+0xa38>
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
ffffffffc02011d2:	56268693          	addi	a3,a3,1378 # ffffffffc0202730 <commands+0xa20>
ffffffffc02011d6:	00001617          	auipc	a2,0x1
ffffffffc02011da:	5aa60613          	addi	a2,a2,1450 # ffffffffc0202780 <commands+0xa70>
ffffffffc02011de:	0ef00593          	li	a1,239
ffffffffc02011e2:	00001517          	auipc	a0,0x1
ffffffffc02011e6:	5b650513          	addi	a0,a0,1462 # ffffffffc0202798 <commands+0xa88>
ffffffffc02011ea:	9c2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc02011ee:	00001697          	auipc	a3,0x1
ffffffffc02011f2:	58a68693          	addi	a3,a3,1418 # ffffffffc0202778 <commands+0xa68>
ffffffffc02011f6:	00001617          	auipc	a2,0x1
ffffffffc02011fa:	58a60613          	addi	a2,a2,1418 # ffffffffc0202780 <commands+0xa70>
ffffffffc02011fe:	0ed00593          	li	a1,237
ffffffffc0201202:	00001517          	auipc	a0,0x1
ffffffffc0201206:	59650513          	addi	a0,a0,1430 # ffffffffc0202798 <commands+0xa88>
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
ffffffffc0201214:	72860613          	addi	a2,a2,1832 # ffffffffc0202938 <buddy_system_pmm_manager+0x170>
ffffffffc0201218:	08200593          	li	a1,130
ffffffffc020121c:	00001517          	auipc	a0,0x1
ffffffffc0201220:	73c50513          	addi	a0,a0,1852 # ffffffffc0202958 <buddy_system_pmm_manager+0x190>
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
ffffffffc02012b8:	51478793          	addi	a5,a5,1300 # ffffffffc02027c8 <buddy_system_pmm_manager>
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
ffffffffc02012c4:	6a850513          	addi	a0,a0,1704 # ffffffffc0202968 <buddy_system_pmm_manager+0x1a0>
{
ffffffffc02012c8:	e486                	sd	ra,72(sp)
ffffffffc02012ca:	e0a2                	sd	s0,64(sp)
ffffffffc02012cc:	fc26                	sd	s1,56(sp)
ffffffffc02012ce:	f052                	sd	s4,32(sp)
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc02012d0:	00005717          	auipc	a4,0x5
ffffffffc02012d4:	28f73023          	sd	a5,640(a4) # ffffffffc0206550 <pmm_manager>
{
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
    cprintf("end pythical address: 0x%016lx.\n", PADDR((uintptr_t)end)); // test point
ffffffffc02012fa:	c02004b7          	lui	s1,0xc0200
    pmm_manager->init();
ffffffffc02012fe:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移: 硬编码0xFFFFFFFF40000000
ffffffffc0201300:	57f5                	li	a5,-3
ffffffffc0201302:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201304:	00001517          	auipc	a0,0x1
ffffffffc0201308:	67c50513          	addi	a0,a0,1660 # ffffffffc0202980 <buddy_system_pmm_manager+0x1b8>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移: 硬编码0xFFFFFFFF40000000
ffffffffc020130c:	00005717          	auipc	a4,0x5
ffffffffc0201310:	24f73623          	sd	a5,588(a4) # ffffffffc0206558 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc0201314:	da3fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201318:	40100613          	li	a2,1025
ffffffffc020131c:	fff40693          	addi	a3,s0,-1
ffffffffc0201320:	0656                	slli	a2,a2,0x15
ffffffffc0201322:	07e005b7          	lui	a1,0x7e00
ffffffffc0201326:	00001517          	auipc	a0,0x1
ffffffffc020132a:	67250513          	addi	a0,a0,1650 # ffffffffc0202998 <buddy_system_pmm_manager+0x1d0>
ffffffffc020132e:	d89fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("maxpa: 0x%016lx.\n", maxpa); // test point
ffffffffc0201332:	85a2                	mv	a1,s0
ffffffffc0201334:	00001517          	auipc	a0,0x1
ffffffffc0201338:	69450513          	addi	a0,a0,1684 # ffffffffc02029c8 <buddy_system_pmm_manager+0x200>
ffffffffc020133c:	d7bfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201340:	000887b7          	lui	a5,0x88
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc0201344:	000885b7          	lui	a1,0x88
ffffffffc0201348:	00001517          	auipc	a0,0x1
ffffffffc020134c:	69850513          	addi	a0,a0,1688 # ffffffffc02029e0 <buddy_system_pmm_manager+0x218>
    npage = maxpa / PGSIZE;
ffffffffc0201350:	00005717          	auipc	a4,0x5
ffffffffc0201354:	0cf73c23          	sd	a5,216(a4) # ffffffffc0206428 <npage>
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc0201358:	d5ffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("nbase: 0x%016lx.\n", nbase); // test point，为0x8000_0
ffffffffc020135c:	000805b7          	lui	a1,0x80
ffffffffc0201360:	00001517          	auipc	a0,0x1
ffffffffc0201364:	69850513          	addi	a0,a0,1688 # ffffffffc02029f8 <buddy_system_pmm_manager+0x230>
ffffffffc0201368:	d4ffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("end pythical address: 0x%016lx.\n", PADDR((uintptr_t)end)); // test point
ffffffffc020136c:	00005697          	auipc	a3,0x5
ffffffffc0201370:	1fc68693          	addi	a3,a3,508 # ffffffffc0206568 <end>
ffffffffc0201374:	2896ef63          	bltu	a3,s1,ffffffffc0201612 <pmm_init+0x35e>
ffffffffc0201378:	00005917          	auipc	s2,0x5
ffffffffc020137c:	1e090913          	addi	s2,s2,480 # ffffffffc0206558 <va_pa_offset>
ffffffffc0201380:	00093583          	ld	a1,0(s2)
ffffffffc0201384:	00001517          	auipc	a0,0x1
ffffffffc0201388:	6c450513          	addi	a0,a0,1732 # ffffffffc0202a48 <buddy_system_pmm_manager+0x280>
ffffffffc020138c:	40b685b3          	sub	a1,a3,a1
ffffffffc0201390:	d27fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201394:	00006697          	auipc	a3,0x6
ffffffffc0201398:	1d368693          	addi	a3,a3,467 # ffffffffc0207567 <end+0xfff>
ffffffffc020139c:	75fd                	lui	a1,0xfffff
ffffffffc020139e:	8eed                	and	a3,a3,a1
ffffffffc02013a0:	00005797          	auipc	a5,0x5
ffffffffc02013a4:	1cd7b023          	sd	a3,448(a5) # ffffffffc0206560 <pages>
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc02013a8:	2496e963          	bltu	a3,s1,ffffffffc02015fa <pmm_init+0x346>
ffffffffc02013ac:	00093583          	ld	a1,0(s2)
ffffffffc02013b0:	00001517          	auipc	a0,0x1
ffffffffc02013b4:	6c050513          	addi	a0,a0,1728 # ffffffffc0202a70 <buddy_system_pmm_manager+0x2a8>
ffffffffc02013b8:	00005997          	auipc	s3,0x5
ffffffffc02013bc:	07098993          	addi	s3,s3,112 # ffffffffc0206428 <npage>
ffffffffc02013c0:	40b685b3          	sub	a1,a3,a1
ffffffffc02013c4:	cf3fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02013c8:	0009b703          	ld	a4,0(s3)
ffffffffc02013cc:	000807b7          	lui	a5,0x80
ffffffffc02013d0:	00005a97          	auipc	s5,0x5
ffffffffc02013d4:	190a8a93          	addi	s5,s5,400 # ffffffffc0206560 <pages>
ffffffffc02013d8:	02f70963          	beq	a4,a5,ffffffffc020140a <pmm_init+0x156>
ffffffffc02013dc:	4681                	li	a3,0
ffffffffc02013de:	4701                	li	a4,0
ffffffffc02013e0:	00005a97          	auipc	s5,0x5
ffffffffc02013e4:	180a8a93          	addi	s5,s5,384 # ffffffffc0206560 <pages>
ffffffffc02013e8:	4585                	li	a1,1
ffffffffc02013ea:	fff80637          	lui	a2,0xfff80
        SetPageReserved(pages + i); // 在memlayout.h中，SetPageReserved是一个宏，将给定的页面标记为保留给内存使用的
ffffffffc02013ee:	000ab783          	ld	a5,0(s5)
ffffffffc02013f2:	97b6                	add	a5,a5,a3
ffffffffc02013f4:	07a1                	addi	a5,a5,8
ffffffffc02013f6:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02013fa:	0009b783          	ld	a5,0(s3)
ffffffffc02013fe:	0705                	addi	a4,a4,1
ffffffffc0201400:	02868693          	addi	a3,a3,40
ffffffffc0201404:	97b2                	add	a5,a5,a2
ffffffffc0201406:	fef764e3          	bltu	a4,a5,ffffffffc02013ee <pmm_init+0x13a>
ffffffffc020140a:	4481                	li	s1,0
    for (size_t i = 0; i < 5; i++)
ffffffffc020140c:	4401                	li	s0,0
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc020140e:	c0200b37          	lui	s6,0xc0200
ffffffffc0201412:	00001c17          	auipc	s8,0x1
ffffffffc0201416:	686c0c13          	addi	s8,s8,1670 # ffffffffc0202a98 <buddy_system_pmm_manager+0x2d0>
    for (size_t i = 0; i < 5; i++)
ffffffffc020141a:	4b95                	li	s7,5
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc020141c:	000ab683          	ld	a3,0(s5)
ffffffffc0201420:	96a6                	add	a3,a3,s1
ffffffffc0201422:	1966e563          	bltu	a3,s6,ffffffffc02015ac <pmm_init+0x2f8>
ffffffffc0201426:	00093603          	ld	a2,0(s2)
ffffffffc020142a:	85a2                	mv	a1,s0
ffffffffc020142c:	8562                	mv	a0,s8
ffffffffc020142e:	40c68633          	sub	a2,a3,a2
    for (size_t i = 0; i < 5; i++)
ffffffffc0201432:	0405                	addi	s0,s0,1
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201434:	c83fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0201438:	02848493          	addi	s1,s1,40 # ffffffffc0200028 <kern_entry+0x28>
    for (size_t i = 0; i < 5; i++)
ffffffffc020143c:	ff7410e3          	bne	s0,s7,ffffffffc020141c <pmm_init+0x168>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc0201440:	0009b783          	ld	a5,0(s3)
ffffffffc0201444:	000ab403          	ld	s0,0(s5)
ffffffffc0201448:	00279693          	slli	a3,a5,0x2
ffffffffc020144c:	96be                	add	a3,a3,a5
ffffffffc020144e:	068e                	slli	a3,a3,0x3
ffffffffc0201450:	9436                	add	s0,s0,a3
ffffffffc0201452:	fec006b7          	lui	a3,0xfec00
ffffffffc0201456:	9436                	add	s0,s0,a3
ffffffffc0201458:	19646463          	bltu	s0,s6,ffffffffc02015e0 <pmm_init+0x32c>
ffffffffc020145c:	00093683          	ld	a3,0(s2)
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc0201460:	02800593          	li	a1,40
ffffffffc0201464:	00001517          	auipc	a0,0x1
ffffffffc0201468:	65c50513          	addi	a0,a0,1628 # ffffffffc0202ac0 <buddy_system_pmm_manager+0x2f8>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020146c:	6485                	lui	s1,0x1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc020146e:	8c15                	sub	s0,s0,a3
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201470:	14fd                	addi	s1,s1,-1
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc0201472:	c45fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc0201476:	85a2                	mv	a1,s0
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201478:	94a2                	add	s1,s1,s0
ffffffffc020147a:	7b7d                	lui	s6,0xfffff
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc020147c:	00001517          	auipc	a0,0x1
ffffffffc0201480:	66450513          	addi	a0,a0,1636 # ffffffffc0202ae0 <buddy_system_pmm_manager+0x318>
ffffffffc0201484:	c33fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0201488:	0164fb33          	and	s6,s1,s6
    cprintf("mem_begin: 0x%016lx.\n", mem_begin); // test point
ffffffffc020148c:	85da                	mv	a1,s6
ffffffffc020148e:	00001517          	auipc	a0,0x1
ffffffffc0201492:	66a50513          	addi	a0,a0,1642 # ffffffffc0202af8 <buddy_system_pmm_manager+0x330>
ffffffffc0201496:	c21fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc020149a:	4bc5                	li	s7,17
ffffffffc020149c:	01bb9593          	slli	a1,s7,0x1b
ffffffffc02014a0:	00001517          	auipc	a0,0x1
ffffffffc02014a4:	67050513          	addi	a0,a0,1648 # ffffffffc0202b10 <buddy_system_pmm_manager+0x348>
    if (freemem < mem_end)
ffffffffc02014a8:	0bee                	slli	s7,s7,0x1b
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc02014aa:	c0dfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (freemem < mem_end)
ffffffffc02014ae:	0d746763          	bltu	s0,s7,ffffffffc020157c <pmm_init+0x2c8>
    if (PPN(pa) >= npage)
ffffffffc02014b2:	0009b783          	ld	a5,0(s3)
ffffffffc02014b6:	00cb5493          	srli	s1,s6,0xc
ffffffffc02014ba:	10f4f563          	bleu	a5,s1,ffffffffc02015c4 <pmm_init+0x310>
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02014be:	fff80437          	lui	s0,0xfff80
ffffffffc02014c2:	008486b3          	add	a3,s1,s0
ffffffffc02014c6:	00269413          	slli	s0,a3,0x2
ffffffffc02014ca:	000ab583          	ld	a1,0(s5)
ffffffffc02014ce:	9436                	add	s0,s0,a3
ffffffffc02014d0:	040e                	slli	s0,s0,0x3
    cprintf("mem_begin对应的页结构记录(结构体page)虚拟地址: 0x%016lx.\n", pa2page(mem_begin));        // test point
ffffffffc02014d2:	95a2                	add	a1,a1,s0
ffffffffc02014d4:	00001517          	auipc	a0,0x1
ffffffffc02014d8:	65450513          	addi	a0,a0,1620 # ffffffffc0202b28 <buddy_system_pmm_manager+0x360>
ffffffffc02014dc:	bdbfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc02014e0:	0009b783          	ld	a5,0(s3)
ffffffffc02014e4:	0ef4f063          	bleu	a5,s1,ffffffffc02015c4 <pmm_init+0x310>
    return &pages[PPN(pa) - nbase];
ffffffffc02014e8:	000ab683          	ld	a3,0(s5)
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc02014ec:	c02004b7          	lui	s1,0xc0200
ffffffffc02014f0:	96a2                	add	a3,a3,s0
ffffffffc02014f2:	0c96eb63          	bltu	a3,s1,ffffffffc02015c8 <pmm_init+0x314>
ffffffffc02014f6:	00093583          	ld	a1,0(s2)
ffffffffc02014fa:	00001517          	auipc	a0,0x1
ffffffffc02014fe:	67e50513          	addi	a0,a0,1662 # ffffffffc0202b78 <buddy_system_pmm_manager+0x3b0>
ffffffffc0201502:	40b685b3          	sub	a1,a3,a1
ffffffffc0201506:	bb1fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("可用空闲页的数目: 0x%016lx.\n", (mem_end - mem_begin) / PGSIZE); // test point
ffffffffc020150a:	45c5                	li	a1,17
ffffffffc020150c:	05ee                	slli	a1,a1,0x1b
ffffffffc020150e:	416585b3          	sub	a1,a1,s6
ffffffffc0201512:	81b1                	srli	a1,a1,0xc
ffffffffc0201514:	00001517          	auipc	a0,0x1
ffffffffc0201518:	6b450513          	addi	a0,a0,1716 # ffffffffc0202bc8 <buddy_system_pmm_manager+0x400>
ffffffffc020151c:	b9bfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201520:	000a3783          	ld	a5,0(s4)
ffffffffc0201524:	7b9c                	ld	a5,48(a5)
ffffffffc0201526:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201528:	00001517          	auipc	a0,0x1
ffffffffc020152c:	6c850513          	addi	a0,a0,1736 # ffffffffc0202bf0 <buddy_system_pmm_manager+0x428>
ffffffffc0201530:	b87fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    satp_virtual = (pte_t *)boot_page_table_sv39; // pte_t 页表项
ffffffffc0201534:	00004697          	auipc	a3,0x4
ffffffffc0201538:	acc68693          	addi	a3,a3,-1332 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020153c:	00005797          	auipc	a5,0x5
ffffffffc0201540:	eed7ba23          	sd	a3,-268(a5) # ffffffffc0206430 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201544:	0e96e363          	bltu	a3,s1,ffffffffc020162a <pmm_init+0x376>
ffffffffc0201548:	00093783          	ld	a5,0(s2)
}
ffffffffc020154c:	6406                	ld	s0,64(sp)
ffffffffc020154e:	60a6                	ld	ra,72(sp)
ffffffffc0201550:	74e2                	ld	s1,56(sp)
ffffffffc0201552:	7942                	ld	s2,48(sp)
ffffffffc0201554:	79a2                	ld	s3,40(sp)
ffffffffc0201556:	7a02                	ld	s4,32(sp)
ffffffffc0201558:	6ae2                	ld	s5,24(sp)
ffffffffc020155a:	6b42                	ld	s6,16(sp)
ffffffffc020155c:	6ba2                	ld	s7,8(sp)
ffffffffc020155e:	6c02                	ld	s8,0(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201560:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc0201562:	8e9d                	sub	a3,a3,a5
ffffffffc0201564:	00005797          	auipc	a5,0x5
ffffffffc0201568:	fed7b223          	sd	a3,-28(a5) # ffffffffc0206548 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020156c:	00001517          	auipc	a0,0x1
ffffffffc0201570:	6a450513          	addi	a0,a0,1700 # ffffffffc0202c10 <buddy_system_pmm_manager+0x448>
ffffffffc0201574:	8636                	mv	a2,a3
}
ffffffffc0201576:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201578:	b3ffe06f          	j	ffffffffc02000b6 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc020157c:	0009b783          	ld	a5,0(s3)
ffffffffc0201580:	80b1                	srli	s1,s1,0xc
ffffffffc0201582:	04f4f163          	bleu	a5,s1,ffffffffc02015c4 <pmm_init+0x310>
    pmm_manager->init_memmap(base, n);
ffffffffc0201586:	000a3703          	ld	a4,0(s4)
    return &pages[PPN(pa) - nbase];
ffffffffc020158a:	fff80537          	lui	a0,0xfff80
ffffffffc020158e:	94aa                	add	s1,s1,a0
ffffffffc0201590:	00249793          	slli	a5,s1,0x2
ffffffffc0201594:	000ab503          	ld	a0,0(s5)
ffffffffc0201598:	94be                	add	s1,s1,a5
ffffffffc020159a:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020159c:	416b8bb3          	sub	s7,s7,s6
ffffffffc02015a0:	048e                	slli	s1,s1,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02015a2:	00cbd593          	srli	a1,s7,0xc
ffffffffc02015a6:	9526                	add	a0,a0,s1
ffffffffc02015a8:	9782                	jalr	a5
ffffffffc02015aa:	b721                	j	ffffffffc02014b2 <pmm_init+0x1fe>
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc02015ac:	00001617          	auipc	a2,0x1
ffffffffc02015b0:	46460613          	addi	a2,a2,1124 # ffffffffc0202a10 <buddy_system_pmm_manager+0x248>
ffffffffc02015b4:	09200593          	li	a1,146
ffffffffc02015b8:	00001517          	auipc	a0,0x1
ffffffffc02015bc:	48050513          	addi	a0,a0,1152 # ffffffffc0202a38 <buddy_system_pmm_manager+0x270>
ffffffffc02015c0:	dedfe0ef          	jal	ra,ffffffffc02003ac <__panic>
ffffffffc02015c4:	c4bff0ef          	jal	ra,ffffffffc020120e <pa2page.part.0>
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc02015c8:	00001617          	auipc	a2,0x1
ffffffffc02015cc:	44860613          	addi	a2,a2,1096 # ffffffffc0202a10 <buddy_system_pmm_manager+0x248>
ffffffffc02015d0:	0a900593          	li	a1,169
ffffffffc02015d4:	00001517          	auipc	a0,0x1
ffffffffc02015d8:	46450513          	addi	a0,a0,1124 # ffffffffc0202a38 <buddy_system_pmm_manager+0x270>
ffffffffc02015dc:	dd1fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc02015e0:	86a2                	mv	a3,s0
ffffffffc02015e2:	00001617          	auipc	a2,0x1
ffffffffc02015e6:	42e60613          	addi	a2,a2,1070 # ffffffffc0202a10 <buddy_system_pmm_manager+0x248>
ffffffffc02015ea:	09900593          	li	a1,153
ffffffffc02015ee:	00001517          	auipc	a0,0x1
ffffffffc02015f2:	44a50513          	addi	a0,a0,1098 # ffffffffc0202a38 <buddy_system_pmm_manager+0x270>
ffffffffc02015f6:	db7fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc02015fa:	00001617          	auipc	a2,0x1
ffffffffc02015fe:	41660613          	addi	a2,a2,1046 # ffffffffc0202a10 <buddy_system_pmm_manager+0x248>
ffffffffc0201602:	08600593          	li	a1,134
ffffffffc0201606:	00001517          	auipc	a0,0x1
ffffffffc020160a:	43250513          	addi	a0,a0,1074 # ffffffffc0202a38 <buddy_system_pmm_manager+0x270>
ffffffffc020160e:	d9ffe0ef          	jal	ra,ffffffffc02003ac <__panic>
    cprintf("end pythical address: 0x%016lx.\n", PADDR((uintptr_t)end)); // test point
ffffffffc0201612:	00001617          	auipc	a2,0x1
ffffffffc0201616:	3fe60613          	addi	a2,a2,1022 # ffffffffc0202a10 <buddy_system_pmm_manager+0x248>
ffffffffc020161a:	08400593          	li	a1,132
ffffffffc020161e:	00001517          	auipc	a0,0x1
ffffffffc0201622:	41a50513          	addi	a0,a0,1050 # ffffffffc0202a38 <buddy_system_pmm_manager+0x270>
ffffffffc0201626:	d87fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020162a:	00001617          	auipc	a2,0x1
ffffffffc020162e:	3e660613          	addi	a2,a2,998 # ffffffffc0202a10 <buddy_system_pmm_manager+0x248>
ffffffffc0201632:	0c500593          	li	a1,197
ffffffffc0201636:	00001517          	auipc	a0,0x1
ffffffffc020163a:	40250513          	addi	a0,a0,1026 # ffffffffc0202a38 <buddy_system_pmm_manager+0x270>
ffffffffc020163e:	d6ffe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201642 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201642:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201646:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201648:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020164c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020164e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201652:	f022                	sd	s0,32(sp)
ffffffffc0201654:	ec26                	sd	s1,24(sp)
ffffffffc0201656:	e84a                	sd	s2,16(sp)
ffffffffc0201658:	f406                	sd	ra,40(sp)
ffffffffc020165a:	e44e                	sd	s3,8(sp)
ffffffffc020165c:	84aa                	mv	s1,a0
ffffffffc020165e:	892e                	mv	s2,a1
ffffffffc0201660:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201664:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0201666:	03067e63          	bleu	a6,a2,ffffffffc02016a2 <printnum+0x60>
ffffffffc020166a:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020166c:	00805763          	blez	s0,ffffffffc020167a <printnum+0x38>
ffffffffc0201670:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201672:	85ca                	mv	a1,s2
ffffffffc0201674:	854e                	mv	a0,s3
ffffffffc0201676:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201678:	fc65                	bnez	s0,ffffffffc0201670 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020167a:	1a02                	slli	s4,s4,0x20
ffffffffc020167c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201680:	00001797          	auipc	a5,0x1
ffffffffc0201684:	76078793          	addi	a5,a5,1888 # ffffffffc0202de0 <error_string+0x38>
ffffffffc0201688:	9a3e                	add	s4,s4,a5
}
ffffffffc020168a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020168c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201690:	70a2                	ld	ra,40(sp)
ffffffffc0201692:	69a2                	ld	s3,8(sp)
ffffffffc0201694:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201696:	85ca                	mv	a1,s2
ffffffffc0201698:	8326                	mv	t1,s1
}
ffffffffc020169a:	6942                	ld	s2,16(sp)
ffffffffc020169c:	64e2                	ld	s1,24(sp)
ffffffffc020169e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02016a0:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02016a2:	03065633          	divu	a2,a2,a6
ffffffffc02016a6:	8722                	mv	a4,s0
ffffffffc02016a8:	f9bff0ef          	jal	ra,ffffffffc0201642 <printnum>
ffffffffc02016ac:	b7f9                	j	ffffffffc020167a <printnum+0x38>

ffffffffc02016ae <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02016ae:	7119                	addi	sp,sp,-128
ffffffffc02016b0:	f4a6                	sd	s1,104(sp)
ffffffffc02016b2:	f0ca                	sd	s2,96(sp)
ffffffffc02016b4:	e8d2                	sd	s4,80(sp)
ffffffffc02016b6:	e4d6                	sd	s5,72(sp)
ffffffffc02016b8:	e0da                	sd	s6,64(sp)
ffffffffc02016ba:	fc5e                	sd	s7,56(sp)
ffffffffc02016bc:	f862                	sd	s8,48(sp)
ffffffffc02016be:	f06a                	sd	s10,32(sp)
ffffffffc02016c0:	fc86                	sd	ra,120(sp)
ffffffffc02016c2:	f8a2                	sd	s0,112(sp)
ffffffffc02016c4:	ecce                	sd	s3,88(sp)
ffffffffc02016c6:	f466                	sd	s9,40(sp)
ffffffffc02016c8:	ec6e                	sd	s11,24(sp)
ffffffffc02016ca:	892a                	mv	s2,a0
ffffffffc02016cc:	84ae                	mv	s1,a1
ffffffffc02016ce:	8d32                	mv	s10,a2
ffffffffc02016d0:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02016d2:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016d4:	00001a17          	auipc	s4,0x1
ffffffffc02016d8:	57ca0a13          	addi	s4,s4,1404 # ffffffffc0202c50 <buddy_system_pmm_manager+0x488>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016dc:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02016e0:	00001c17          	auipc	s8,0x1
ffffffffc02016e4:	6c8c0c13          	addi	s8,s8,1736 # ffffffffc0202da8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016e8:	000d4503          	lbu	a0,0(s10)
ffffffffc02016ec:	02500793          	li	a5,37
ffffffffc02016f0:	001d0413          	addi	s0,s10,1
ffffffffc02016f4:	00f50e63          	beq	a0,a5,ffffffffc0201710 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc02016f8:	c521                	beqz	a0,ffffffffc0201740 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016fa:	02500993          	li	s3,37
ffffffffc02016fe:	a011                	j	ffffffffc0201702 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0201700:	c121                	beqz	a0,ffffffffc0201740 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0201702:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201704:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201706:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201708:	fff44503          	lbu	a0,-1(s0) # fffffffffff7ffff <end+0x3fd79a97>
ffffffffc020170c:	ff351ae3          	bne	a0,s3,ffffffffc0201700 <vprintfmt+0x52>
ffffffffc0201710:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201714:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201718:	4981                	li	s3,0
ffffffffc020171a:	4801                	li	a6,0
        width = precision = -1;
ffffffffc020171c:	5cfd                	li	s9,-1
ffffffffc020171e:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201720:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0201724:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201726:	fdd6069b          	addiw	a3,a2,-35
ffffffffc020172a:	0ff6f693          	andi	a3,a3,255
ffffffffc020172e:	00140d13          	addi	s10,s0,1
ffffffffc0201732:	20d5e563          	bltu	a1,a3,ffffffffc020193c <vprintfmt+0x28e>
ffffffffc0201736:	068a                	slli	a3,a3,0x2
ffffffffc0201738:	96d2                	add	a3,a3,s4
ffffffffc020173a:	4294                	lw	a3,0(a3)
ffffffffc020173c:	96d2                	add	a3,a3,s4
ffffffffc020173e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201740:	70e6                	ld	ra,120(sp)
ffffffffc0201742:	7446                	ld	s0,112(sp)
ffffffffc0201744:	74a6                	ld	s1,104(sp)
ffffffffc0201746:	7906                	ld	s2,96(sp)
ffffffffc0201748:	69e6                	ld	s3,88(sp)
ffffffffc020174a:	6a46                	ld	s4,80(sp)
ffffffffc020174c:	6aa6                	ld	s5,72(sp)
ffffffffc020174e:	6b06                	ld	s6,64(sp)
ffffffffc0201750:	7be2                	ld	s7,56(sp)
ffffffffc0201752:	7c42                	ld	s8,48(sp)
ffffffffc0201754:	7ca2                	ld	s9,40(sp)
ffffffffc0201756:	7d02                	ld	s10,32(sp)
ffffffffc0201758:	6de2                	ld	s11,24(sp)
ffffffffc020175a:	6109                	addi	sp,sp,128
ffffffffc020175c:	8082                	ret
    if (lflag >= 2) {
ffffffffc020175e:	4705                	li	a4,1
ffffffffc0201760:	008a8593          	addi	a1,s5,8
ffffffffc0201764:	01074463          	blt	a4,a6,ffffffffc020176c <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0201768:	26080363          	beqz	a6,ffffffffc02019ce <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc020176c:	000ab603          	ld	a2,0(s5)
ffffffffc0201770:	46c1                	li	a3,16
ffffffffc0201772:	8aae                	mv	s5,a1
ffffffffc0201774:	a06d                	j	ffffffffc020181e <vprintfmt+0x170>
            goto reswitch;
ffffffffc0201776:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020177a:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020177c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020177e:	b765                	j	ffffffffc0201726 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0201780:	000aa503          	lw	a0,0(s5)
ffffffffc0201784:	85a6                	mv	a1,s1
ffffffffc0201786:	0aa1                	addi	s5,s5,8
ffffffffc0201788:	9902                	jalr	s2
            break;
ffffffffc020178a:	bfb9                	j	ffffffffc02016e8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020178c:	4705                	li	a4,1
ffffffffc020178e:	008a8993          	addi	s3,s5,8
ffffffffc0201792:	01074463          	blt	a4,a6,ffffffffc020179a <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0201796:	22080463          	beqz	a6,ffffffffc02019be <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc020179a:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc020179e:	24044463          	bltz	s0,ffffffffc02019e6 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc02017a2:	8622                	mv	a2,s0
ffffffffc02017a4:	8ace                	mv	s5,s3
ffffffffc02017a6:	46a9                	li	a3,10
ffffffffc02017a8:	a89d                	j	ffffffffc020181e <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc02017aa:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02017ae:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02017b0:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc02017b2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02017b6:	8fb5                	xor	a5,a5,a3
ffffffffc02017b8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02017bc:	1ad74363          	blt	a4,a3,ffffffffc0201962 <vprintfmt+0x2b4>
ffffffffc02017c0:	00369793          	slli	a5,a3,0x3
ffffffffc02017c4:	97e2                	add	a5,a5,s8
ffffffffc02017c6:	639c                	ld	a5,0(a5)
ffffffffc02017c8:	18078d63          	beqz	a5,ffffffffc0201962 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc02017cc:	86be                	mv	a3,a5
ffffffffc02017ce:	00001617          	auipc	a2,0x1
ffffffffc02017d2:	6c260613          	addi	a2,a2,1730 # ffffffffc0202e90 <error_string+0xe8>
ffffffffc02017d6:	85a6                	mv	a1,s1
ffffffffc02017d8:	854a                	mv	a0,s2
ffffffffc02017da:	240000ef          	jal	ra,ffffffffc0201a1a <printfmt>
ffffffffc02017de:	b729                	j	ffffffffc02016e8 <vprintfmt+0x3a>
            lflag ++;
ffffffffc02017e0:	00144603          	lbu	a2,1(s0)
ffffffffc02017e4:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017e6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02017e8:	bf3d                	j	ffffffffc0201726 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc02017ea:	4705                	li	a4,1
ffffffffc02017ec:	008a8593          	addi	a1,s5,8
ffffffffc02017f0:	01074463          	blt	a4,a6,ffffffffc02017f8 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02017f4:	1e080263          	beqz	a6,ffffffffc02019d8 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc02017f8:	000ab603          	ld	a2,0(s5)
ffffffffc02017fc:	46a1                	li	a3,8
ffffffffc02017fe:	8aae                	mv	s5,a1
ffffffffc0201800:	a839                	j	ffffffffc020181e <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0201802:	03000513          	li	a0,48
ffffffffc0201806:	85a6                	mv	a1,s1
ffffffffc0201808:	e03e                	sd	a5,0(sp)
ffffffffc020180a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020180c:	85a6                	mv	a1,s1
ffffffffc020180e:	07800513          	li	a0,120
ffffffffc0201812:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201814:	0aa1                	addi	s5,s5,8
ffffffffc0201816:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc020181a:	6782                	ld	a5,0(sp)
ffffffffc020181c:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020181e:	876e                	mv	a4,s11
ffffffffc0201820:	85a6                	mv	a1,s1
ffffffffc0201822:	854a                	mv	a0,s2
ffffffffc0201824:	e1fff0ef          	jal	ra,ffffffffc0201642 <printnum>
            break;
ffffffffc0201828:	b5c1                	j	ffffffffc02016e8 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020182a:	000ab603          	ld	a2,0(s5)
ffffffffc020182e:	0aa1                	addi	s5,s5,8
ffffffffc0201830:	1c060663          	beqz	a2,ffffffffc02019fc <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0201834:	00160413          	addi	s0,a2,1
ffffffffc0201838:	17b05c63          	blez	s11,ffffffffc02019b0 <vprintfmt+0x302>
ffffffffc020183c:	02d00593          	li	a1,45
ffffffffc0201840:	14b79263          	bne	a5,a1,ffffffffc0201984 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201844:	00064783          	lbu	a5,0(a2)
ffffffffc0201848:	0007851b          	sext.w	a0,a5
ffffffffc020184c:	c905                	beqz	a0,ffffffffc020187c <vprintfmt+0x1ce>
ffffffffc020184e:	000cc563          	bltz	s9,ffffffffc0201858 <vprintfmt+0x1aa>
ffffffffc0201852:	3cfd                	addiw	s9,s9,-1
ffffffffc0201854:	036c8263          	beq	s9,s6,ffffffffc0201878 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0201858:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020185a:	18098463          	beqz	s3,ffffffffc02019e2 <vprintfmt+0x334>
ffffffffc020185e:	3781                	addiw	a5,a5,-32
ffffffffc0201860:	18fbf163          	bleu	a5,s7,ffffffffc02019e2 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0201864:	03f00513          	li	a0,63
ffffffffc0201868:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020186a:	0405                	addi	s0,s0,1
ffffffffc020186c:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201870:	3dfd                	addiw	s11,s11,-1
ffffffffc0201872:	0007851b          	sext.w	a0,a5
ffffffffc0201876:	fd61                	bnez	a0,ffffffffc020184e <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc0201878:	e7b058e3          	blez	s11,ffffffffc02016e8 <vprintfmt+0x3a>
ffffffffc020187c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020187e:	85a6                	mv	a1,s1
ffffffffc0201880:	02000513          	li	a0,32
ffffffffc0201884:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201886:	e60d81e3          	beqz	s11,ffffffffc02016e8 <vprintfmt+0x3a>
ffffffffc020188a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020188c:	85a6                	mv	a1,s1
ffffffffc020188e:	02000513          	li	a0,32
ffffffffc0201892:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201894:	fe0d94e3          	bnez	s11,ffffffffc020187c <vprintfmt+0x1ce>
ffffffffc0201898:	bd81                	j	ffffffffc02016e8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020189a:	4705                	li	a4,1
ffffffffc020189c:	008a8593          	addi	a1,s5,8
ffffffffc02018a0:	01074463          	blt	a4,a6,ffffffffc02018a8 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc02018a4:	12080063          	beqz	a6,ffffffffc02019c4 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc02018a8:	000ab603          	ld	a2,0(s5)
ffffffffc02018ac:	46a9                	li	a3,10
ffffffffc02018ae:	8aae                	mv	s5,a1
ffffffffc02018b0:	b7bd                	j	ffffffffc020181e <vprintfmt+0x170>
ffffffffc02018b2:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc02018b6:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018ba:	846a                	mv	s0,s10
ffffffffc02018bc:	b5ad                	j	ffffffffc0201726 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc02018be:	85a6                	mv	a1,s1
ffffffffc02018c0:	02500513          	li	a0,37
ffffffffc02018c4:	9902                	jalr	s2
            break;
ffffffffc02018c6:	b50d                	j	ffffffffc02016e8 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc02018c8:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc02018cc:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02018d0:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018d2:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc02018d4:	e40dd9e3          	bgez	s11,ffffffffc0201726 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc02018d8:	8de6                	mv	s11,s9
ffffffffc02018da:	5cfd                	li	s9,-1
ffffffffc02018dc:	b5a9                	j	ffffffffc0201726 <vprintfmt+0x78>
            goto reswitch;
ffffffffc02018de:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc02018e2:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018e6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02018e8:	bd3d                	j	ffffffffc0201726 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc02018ea:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc02018ee:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018f2:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02018f4:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02018f8:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02018fc:	fcd56ce3          	bltu	a0,a3,ffffffffc02018d4 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc0201900:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201902:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0201906:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020190a:	0196873b          	addw	a4,a3,s9
ffffffffc020190e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201912:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0201916:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc020191a:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020191e:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201922:	fcd57fe3          	bleu	a3,a0,ffffffffc0201900 <vprintfmt+0x252>
ffffffffc0201926:	b77d                	j	ffffffffc02018d4 <vprintfmt+0x226>
            if (width < 0)
ffffffffc0201928:	fffdc693          	not	a3,s11
ffffffffc020192c:	96fd                	srai	a3,a3,0x3f
ffffffffc020192e:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201932:	00144603          	lbu	a2,1(s0)
ffffffffc0201936:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201938:	846a                	mv	s0,s10
ffffffffc020193a:	b3f5                	j	ffffffffc0201726 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc020193c:	85a6                	mv	a1,s1
ffffffffc020193e:	02500513          	li	a0,37
ffffffffc0201942:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201944:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201948:	02500793          	li	a5,37
ffffffffc020194c:	8d22                	mv	s10,s0
ffffffffc020194e:	d8f70de3          	beq	a4,a5,ffffffffc02016e8 <vprintfmt+0x3a>
ffffffffc0201952:	02500713          	li	a4,37
ffffffffc0201956:	1d7d                	addi	s10,s10,-1
ffffffffc0201958:	fffd4783          	lbu	a5,-1(s10)
ffffffffc020195c:	fee79de3          	bne	a5,a4,ffffffffc0201956 <vprintfmt+0x2a8>
ffffffffc0201960:	b361                	j	ffffffffc02016e8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201962:	00001617          	auipc	a2,0x1
ffffffffc0201966:	51e60613          	addi	a2,a2,1310 # ffffffffc0202e80 <error_string+0xd8>
ffffffffc020196a:	85a6                	mv	a1,s1
ffffffffc020196c:	854a                	mv	a0,s2
ffffffffc020196e:	0ac000ef          	jal	ra,ffffffffc0201a1a <printfmt>
ffffffffc0201972:	bb9d                	j	ffffffffc02016e8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201974:	00001617          	auipc	a2,0x1
ffffffffc0201978:	50460613          	addi	a2,a2,1284 # ffffffffc0202e78 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc020197c:	00001417          	auipc	s0,0x1
ffffffffc0201980:	4fd40413          	addi	s0,s0,1277 # ffffffffc0202e79 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201984:	8532                	mv	a0,a2
ffffffffc0201986:	85e6                	mv	a1,s9
ffffffffc0201988:	e032                	sd	a2,0(sp)
ffffffffc020198a:	e43e                	sd	a5,8(sp)
ffffffffc020198c:	1de000ef          	jal	ra,ffffffffc0201b6a <strnlen>
ffffffffc0201990:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201994:	6602                	ld	a2,0(sp)
ffffffffc0201996:	01b05d63          	blez	s11,ffffffffc02019b0 <vprintfmt+0x302>
ffffffffc020199a:	67a2                	ld	a5,8(sp)
ffffffffc020199c:	2781                	sext.w	a5,a5
ffffffffc020199e:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc02019a0:	6522                	ld	a0,8(sp)
ffffffffc02019a2:	85a6                	mv	a1,s1
ffffffffc02019a4:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02019a6:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02019a8:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02019aa:	6602                	ld	a2,0(sp)
ffffffffc02019ac:	fe0d9ae3          	bnez	s11,ffffffffc02019a0 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02019b0:	00064783          	lbu	a5,0(a2)
ffffffffc02019b4:	0007851b          	sext.w	a0,a5
ffffffffc02019b8:	e8051be3          	bnez	a0,ffffffffc020184e <vprintfmt+0x1a0>
ffffffffc02019bc:	b335                	j	ffffffffc02016e8 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc02019be:	000aa403          	lw	s0,0(s5)
ffffffffc02019c2:	bbf1                	j	ffffffffc020179e <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc02019c4:	000ae603          	lwu	a2,0(s5)
ffffffffc02019c8:	46a9                	li	a3,10
ffffffffc02019ca:	8aae                	mv	s5,a1
ffffffffc02019cc:	bd89                	j	ffffffffc020181e <vprintfmt+0x170>
ffffffffc02019ce:	000ae603          	lwu	a2,0(s5)
ffffffffc02019d2:	46c1                	li	a3,16
ffffffffc02019d4:	8aae                	mv	s5,a1
ffffffffc02019d6:	b5a1                	j	ffffffffc020181e <vprintfmt+0x170>
ffffffffc02019d8:	000ae603          	lwu	a2,0(s5)
ffffffffc02019dc:	46a1                	li	a3,8
ffffffffc02019de:	8aae                	mv	s5,a1
ffffffffc02019e0:	bd3d                	j	ffffffffc020181e <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc02019e2:	9902                	jalr	s2
ffffffffc02019e4:	b559                	j	ffffffffc020186a <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc02019e6:	85a6                	mv	a1,s1
ffffffffc02019e8:	02d00513          	li	a0,45
ffffffffc02019ec:	e03e                	sd	a5,0(sp)
ffffffffc02019ee:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02019f0:	8ace                	mv	s5,s3
ffffffffc02019f2:	40800633          	neg	a2,s0
ffffffffc02019f6:	46a9                	li	a3,10
ffffffffc02019f8:	6782                	ld	a5,0(sp)
ffffffffc02019fa:	b515                	j	ffffffffc020181e <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02019fc:	01b05663          	blez	s11,ffffffffc0201a08 <vprintfmt+0x35a>
ffffffffc0201a00:	02d00693          	li	a3,45
ffffffffc0201a04:	f6d798e3          	bne	a5,a3,ffffffffc0201974 <vprintfmt+0x2c6>
ffffffffc0201a08:	00001417          	auipc	s0,0x1
ffffffffc0201a0c:	47140413          	addi	s0,s0,1137 # ffffffffc0202e79 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201a10:	02800513          	li	a0,40
ffffffffc0201a14:	02800793          	li	a5,40
ffffffffc0201a18:	bd1d                	j	ffffffffc020184e <vprintfmt+0x1a0>

ffffffffc0201a1a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201a1a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201a1c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201a20:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201a22:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201a24:	ec06                	sd	ra,24(sp)
ffffffffc0201a26:	f83a                	sd	a4,48(sp)
ffffffffc0201a28:	fc3e                	sd	a5,56(sp)
ffffffffc0201a2a:	e0c2                	sd	a6,64(sp)
ffffffffc0201a2c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201a2e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201a30:	c7fff0ef          	jal	ra,ffffffffc02016ae <vprintfmt>
}
ffffffffc0201a34:	60e2                	ld	ra,24(sp)
ffffffffc0201a36:	6161                	addi	sp,sp,80
ffffffffc0201a38:	8082                	ret

ffffffffc0201a3a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201a3a:	715d                	addi	sp,sp,-80
ffffffffc0201a3c:	e486                	sd	ra,72(sp)
ffffffffc0201a3e:	e0a2                	sd	s0,64(sp)
ffffffffc0201a40:	fc26                	sd	s1,56(sp)
ffffffffc0201a42:	f84a                	sd	s2,48(sp)
ffffffffc0201a44:	f44e                	sd	s3,40(sp)
ffffffffc0201a46:	f052                	sd	s4,32(sp)
ffffffffc0201a48:	ec56                	sd	s5,24(sp)
ffffffffc0201a4a:	e85a                	sd	s6,16(sp)
ffffffffc0201a4c:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc0201a4e:	c901                	beqz	a0,ffffffffc0201a5e <readline+0x24>
        cprintf("%s", prompt);
ffffffffc0201a50:	85aa                	mv	a1,a0
ffffffffc0201a52:	00001517          	auipc	a0,0x1
ffffffffc0201a56:	43e50513          	addi	a0,a0,1086 # ffffffffc0202e90 <error_string+0xe8>
ffffffffc0201a5a:	e5cfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
readline(const char *prompt) {
ffffffffc0201a5e:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a60:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201a62:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201a64:	4aa9                	li	s5,10
ffffffffc0201a66:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201a68:	00004b97          	auipc	s7,0x4
ffffffffc0201a6c:	5b0b8b93          	addi	s7,s7,1456 # ffffffffc0206018 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a70:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201a74:	ebafe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201a78:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a7a:	00054b63          	bltz	a0,ffffffffc0201a90 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a7e:	00a95b63          	ble	a0,s2,ffffffffc0201a94 <readline+0x5a>
ffffffffc0201a82:	029a5463          	ble	s1,s4,ffffffffc0201aaa <readline+0x70>
        c = getchar();
ffffffffc0201a86:	ea8fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201a8a:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a8c:	fe0559e3          	bgez	a0,ffffffffc0201a7e <readline+0x44>
            return NULL;
ffffffffc0201a90:	4501                	li	a0,0
ffffffffc0201a92:	a099                	j	ffffffffc0201ad8 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0201a94:	03341463          	bne	s0,s3,ffffffffc0201abc <readline+0x82>
ffffffffc0201a98:	e8b9                	bnez	s1,ffffffffc0201aee <readline+0xb4>
        c = getchar();
ffffffffc0201a9a:	e94fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201a9e:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201aa0:	fe0548e3          	bltz	a0,ffffffffc0201a90 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201aa4:	fea958e3          	ble	a0,s2,ffffffffc0201a94 <readline+0x5a>
ffffffffc0201aa8:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201aaa:	8522                	mv	a0,s0
ffffffffc0201aac:	e3efe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i ++] = c;
ffffffffc0201ab0:	009b87b3          	add	a5,s7,s1
ffffffffc0201ab4:	00878023          	sb	s0,0(a5)
ffffffffc0201ab8:	2485                	addiw	s1,s1,1
ffffffffc0201aba:	bf6d                	j	ffffffffc0201a74 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0201abc:	01540463          	beq	s0,s5,ffffffffc0201ac4 <readline+0x8a>
ffffffffc0201ac0:	fb641ae3          	bne	s0,s6,ffffffffc0201a74 <readline+0x3a>
            cputchar(c);
ffffffffc0201ac4:	8522                	mv	a0,s0
ffffffffc0201ac6:	e24fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i] = '\0';
ffffffffc0201aca:	00004517          	auipc	a0,0x4
ffffffffc0201ace:	54e50513          	addi	a0,a0,1358 # ffffffffc0206018 <edata>
ffffffffc0201ad2:	94aa                	add	s1,s1,a0
ffffffffc0201ad4:	00048023          	sb	zero,0(s1) # ffffffffc0200000 <kern_entry>
            return buf;
        }
    }
}
ffffffffc0201ad8:	60a6                	ld	ra,72(sp)
ffffffffc0201ada:	6406                	ld	s0,64(sp)
ffffffffc0201adc:	74e2                	ld	s1,56(sp)
ffffffffc0201ade:	7942                	ld	s2,48(sp)
ffffffffc0201ae0:	79a2                	ld	s3,40(sp)
ffffffffc0201ae2:	7a02                	ld	s4,32(sp)
ffffffffc0201ae4:	6ae2                	ld	s5,24(sp)
ffffffffc0201ae6:	6b42                	ld	s6,16(sp)
ffffffffc0201ae8:	6ba2                	ld	s7,8(sp)
ffffffffc0201aea:	6161                	addi	sp,sp,80
ffffffffc0201aec:	8082                	ret
            cputchar(c);
ffffffffc0201aee:	4521                	li	a0,8
ffffffffc0201af0:	dfafe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            i --;
ffffffffc0201af4:	34fd                	addiw	s1,s1,-1
ffffffffc0201af6:	bfbd                	j	ffffffffc0201a74 <readline+0x3a>

ffffffffc0201af8 <sbi_console_putchar>:
    return ret_val;
}

void sbi_console_putchar(unsigned char ch)
{
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201af8:	00004797          	auipc	a5,0x4
ffffffffc0201afc:	51078793          	addi	a5,a5,1296 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile(
ffffffffc0201b00:	6398                	ld	a4,0(a5)
ffffffffc0201b02:	4781                	li	a5,0
ffffffffc0201b04:	88ba                	mv	a7,a4
ffffffffc0201b06:	852a                	mv	a0,a0
ffffffffc0201b08:	85be                	mv	a1,a5
ffffffffc0201b0a:	863e                	mv	a2,a5
ffffffffc0201b0c:	00000073          	ecall
ffffffffc0201b10:	87aa                	mv	a5,a0
}
ffffffffc0201b12:	8082                	ret

ffffffffc0201b14 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value)
{
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201b14:	00005797          	auipc	a5,0x5
ffffffffc0201b18:	92478793          	addi	a5,a5,-1756 # ffffffffc0206438 <SBI_SET_TIMER>
    __asm__ volatile(
ffffffffc0201b1c:	6398                	ld	a4,0(a5)
ffffffffc0201b1e:	4781                	li	a5,0
ffffffffc0201b20:	88ba                	mv	a7,a4
ffffffffc0201b22:	852a                	mv	a0,a0
ffffffffc0201b24:	85be                	mv	a1,a5
ffffffffc0201b26:	863e                	mv	a2,a5
ffffffffc0201b28:	00000073          	ecall
ffffffffc0201b2c:	87aa                	mv	a5,a0
}
ffffffffc0201b2e:	8082                	ret

ffffffffc0201b30 <sbi_console_getchar>:

int sbi_console_getchar(void)
{
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201b30:	00004797          	auipc	a5,0x4
ffffffffc0201b34:	4d078793          	addi	a5,a5,1232 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile(
ffffffffc0201b38:	639c                	ld	a5,0(a5)
ffffffffc0201b3a:	4501                	li	a0,0
ffffffffc0201b3c:	88be                	mv	a7,a5
ffffffffc0201b3e:	852a                	mv	a0,a0
ffffffffc0201b40:	85aa                	mv	a1,a0
ffffffffc0201b42:	862a                	mv	a2,a0
ffffffffc0201b44:	00000073          	ecall
ffffffffc0201b48:	852a                	mv	a0,a0
}
ffffffffc0201b4a:	2501                	sext.w	a0,a0
ffffffffc0201b4c:	8082                	ret

ffffffffc0201b4e <sbi_shutdown>:

void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201b4e:	00004797          	auipc	a5,0x4
ffffffffc0201b52:	4c278793          	addi	a5,a5,1218 # ffffffffc0206010 <SBI_SHUTDOWN>
    __asm__ volatile(
ffffffffc0201b56:	6398                	ld	a4,0(a5)
ffffffffc0201b58:	4781                	li	a5,0
ffffffffc0201b5a:	88ba                	mv	a7,a4
ffffffffc0201b5c:	853e                	mv	a0,a5
ffffffffc0201b5e:	85be                	mv	a1,a5
ffffffffc0201b60:	863e                	mv	a2,a5
ffffffffc0201b62:	00000073          	ecall
ffffffffc0201b66:	87aa                	mv	a5,a0
ffffffffc0201b68:	8082                	ret

ffffffffc0201b6a <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201b6a:	c185                	beqz	a1,ffffffffc0201b8a <strnlen+0x20>
ffffffffc0201b6c:	00054783          	lbu	a5,0(a0)
ffffffffc0201b70:	cf89                	beqz	a5,ffffffffc0201b8a <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0201b72:	4781                	li	a5,0
ffffffffc0201b74:	a021                	j	ffffffffc0201b7c <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201b76:	00074703          	lbu	a4,0(a4)
ffffffffc0201b7a:	c711                	beqz	a4,ffffffffc0201b86 <strnlen+0x1c>
        cnt ++;
ffffffffc0201b7c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201b7e:	00f50733          	add	a4,a0,a5
ffffffffc0201b82:	fef59ae3          	bne	a1,a5,ffffffffc0201b76 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0201b86:	853e                	mv	a0,a5
ffffffffc0201b88:	8082                	ret
    size_t cnt = 0;
ffffffffc0201b8a:	4781                	li	a5,0
}
ffffffffc0201b8c:	853e                	mv	a0,a5
ffffffffc0201b8e:	8082                	ret

ffffffffc0201b90 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201b90:	00054783          	lbu	a5,0(a0)
ffffffffc0201b94:	0005c703          	lbu	a4,0(a1) # fffffffffffff000 <end+0x3fdf8a98>
ffffffffc0201b98:	cb91                	beqz	a5,ffffffffc0201bac <strcmp+0x1c>
ffffffffc0201b9a:	00e79c63          	bne	a5,a4,ffffffffc0201bb2 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0201b9e:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ba0:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0201ba4:	0585                	addi	a1,a1,1
ffffffffc0201ba6:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201baa:	fbe5                	bnez	a5,ffffffffc0201b9a <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201bac:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201bae:	9d19                	subw	a0,a0,a4
ffffffffc0201bb0:	8082                	ret
ffffffffc0201bb2:	0007851b          	sext.w	a0,a5
ffffffffc0201bb6:	9d19                	subw	a0,a0,a4
ffffffffc0201bb8:	8082                	ret

ffffffffc0201bba <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201bba:	00054783          	lbu	a5,0(a0)
ffffffffc0201bbe:	cb91                	beqz	a5,ffffffffc0201bd2 <strchr+0x18>
        if (*s == c) {
ffffffffc0201bc0:	00b79563          	bne	a5,a1,ffffffffc0201bca <strchr+0x10>
ffffffffc0201bc4:	a809                	j	ffffffffc0201bd6 <strchr+0x1c>
ffffffffc0201bc6:	00b78763          	beq	a5,a1,ffffffffc0201bd4 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0201bca:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201bcc:	00054783          	lbu	a5,0(a0)
ffffffffc0201bd0:	fbfd                	bnez	a5,ffffffffc0201bc6 <strchr+0xc>
    }
    return NULL;
ffffffffc0201bd2:	4501                	li	a0,0
}
ffffffffc0201bd4:	8082                	ret
ffffffffc0201bd6:	8082                	ret

ffffffffc0201bd8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201bd8:	ca01                	beqz	a2,ffffffffc0201be8 <memset+0x10>
ffffffffc0201bda:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201bdc:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201bde:	0785                	addi	a5,a5,1
ffffffffc0201be0:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201be4:	fec79de3          	bne	a5,a2,ffffffffc0201bde <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201be8:	8082                	ret
