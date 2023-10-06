
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
ffffffffc0200042:	44260613          	addi	a2,a2,1090 # ffffffffc0206480 <end>
int kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	5c7010ef          	jal	ra,ffffffffc0201e14 <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fe000ef          	jal	ra,ffffffffc0200450 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00002517          	auipc	a0,0x2
ffffffffc020005a:	dd250513          	addi	a0,a0,-558 # ffffffffc0201e28 <etext+0x2>
ffffffffc020005e:	090000ef          	jal	ra,ffffffffc02000ee <cputs>

    print_kerninfo();
ffffffffc0200062:	0dc000ef          	jal	ra,ffffffffc020013e <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200066:	404000ef          	jal	ra,ffffffffc020046a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020006a:	4be010ef          	jal	ra,ffffffffc0201528 <pmm_init>

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
ffffffffc02000aa:	041010ef          	jal	ra,ffffffffc02018ea <vprintfmt>
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
ffffffffc02000de:	00d010ef          	jal	ra,ffffffffc02018ea <vprintfmt>
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
ffffffffc0200144:	d3850513          	addi	a0,a0,-712 # ffffffffc0201e78 <etext+0x52>
void print_kerninfo(void) {
ffffffffc0200148:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014a:	f6dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014e:	00000597          	auipc	a1,0x0
ffffffffc0200152:	ee858593          	addi	a1,a1,-280 # ffffffffc0200036 <kern_init>
ffffffffc0200156:	00002517          	auipc	a0,0x2
ffffffffc020015a:	d4250513          	addi	a0,a0,-702 # ffffffffc0201e98 <etext+0x72>
ffffffffc020015e:	f59ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200162:	00002597          	auipc	a1,0x2
ffffffffc0200166:	cc458593          	addi	a1,a1,-828 # ffffffffc0201e26 <etext>
ffffffffc020016a:	00002517          	auipc	a0,0x2
ffffffffc020016e:	d4e50513          	addi	a0,a0,-690 # ffffffffc0201eb8 <etext+0x92>
ffffffffc0200172:	f45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200176:	00006597          	auipc	a1,0x6
ffffffffc020017a:	ea258593          	addi	a1,a1,-350 # ffffffffc0206018 <edata>
ffffffffc020017e:	00002517          	auipc	a0,0x2
ffffffffc0200182:	d5a50513          	addi	a0,a0,-678 # ffffffffc0201ed8 <etext+0xb2>
ffffffffc0200186:	f31ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018a:	00006597          	auipc	a1,0x6
ffffffffc020018e:	2f658593          	addi	a1,a1,758 # ffffffffc0206480 <end>
ffffffffc0200192:	00002517          	auipc	a0,0x2
ffffffffc0200196:	d6650513          	addi	a0,a0,-666 # ffffffffc0201ef8 <etext+0xd2>
ffffffffc020019a:	f1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019e:	00006597          	auipc	a1,0x6
ffffffffc02001a2:	6e158593          	addi	a1,a1,1761 # ffffffffc020687f <end+0x3ff>
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
ffffffffc02001c4:	d5850513          	addi	a0,a0,-680 # ffffffffc0201f18 <etext+0xf2>
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
ffffffffc02001d4:	c7860613          	addi	a2,a2,-904 # ffffffffc0201e48 <etext+0x22>
ffffffffc02001d8:	04e00593          	li	a1,78
ffffffffc02001dc:	00002517          	auipc	a0,0x2
ffffffffc02001e0:	c8450513          	addi	a0,a0,-892 # ffffffffc0201e60 <etext+0x3a>
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
ffffffffc02001f0:	e3c60613          	addi	a2,a2,-452 # ffffffffc0202028 <commands+0xe0>
ffffffffc02001f4:	00002597          	auipc	a1,0x2
ffffffffc02001f8:	e5458593          	addi	a1,a1,-428 # ffffffffc0202048 <commands+0x100>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	e5450513          	addi	a0,a0,-428 # ffffffffc0202050 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200206:	eb1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020020a:	00002617          	auipc	a2,0x2
ffffffffc020020e:	e5660613          	addi	a2,a2,-426 # ffffffffc0202060 <commands+0x118>
ffffffffc0200212:	00002597          	auipc	a1,0x2
ffffffffc0200216:	e7658593          	addi	a1,a1,-394 # ffffffffc0202088 <commands+0x140>
ffffffffc020021a:	00002517          	auipc	a0,0x2
ffffffffc020021e:	e3650513          	addi	a0,a0,-458 # ffffffffc0202050 <commands+0x108>
ffffffffc0200222:	e95ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200226:	00002617          	auipc	a2,0x2
ffffffffc020022a:	e7260613          	addi	a2,a2,-398 # ffffffffc0202098 <commands+0x150>
ffffffffc020022e:	00002597          	auipc	a1,0x2
ffffffffc0200232:	e8a58593          	addi	a1,a1,-374 # ffffffffc02020b8 <commands+0x170>
ffffffffc0200236:	00002517          	auipc	a0,0x2
ffffffffc020023a:	e1a50513          	addi	a0,a0,-486 # ffffffffc0202050 <commands+0x108>
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
ffffffffc0200274:	d2050513          	addi	a0,a0,-736 # ffffffffc0201f90 <commands+0x48>
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
ffffffffc0200296:	d2650513          	addi	a0,a0,-730 # ffffffffc0201fb8 <commands+0x70>
ffffffffc020029a:	e1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (tf != NULL) {
ffffffffc020029e:	000c0563          	beqz	s8,ffffffffc02002a8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a2:	8562                	mv	a0,s8
ffffffffc02002a4:	3a6000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002a8:	00002c97          	auipc	s9,0x2
ffffffffc02002ac:	ca0c8c93          	addi	s9,s9,-864 # ffffffffc0201f48 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b0:	00002997          	auipc	s3,0x2
ffffffffc02002b4:	d3098993          	addi	s3,s3,-720 # ffffffffc0201fe0 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00002917          	auipc	s2,0x2
ffffffffc02002bc:	d3090913          	addi	s2,s2,-720 # ffffffffc0201fe8 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002c0:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c2:	00002b17          	auipc	s6,0x2
ffffffffc02002c6:	d2eb0b13          	addi	s6,s6,-722 # ffffffffc0201ff0 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ca:	00002a97          	auipc	s5,0x2
ffffffffc02002ce:	d7ea8a93          	addi	s5,s5,-642 # ffffffffc0202048 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d2:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d4:	854e                	mv	a0,s3
ffffffffc02002d6:	1a1010ef          	jal	ra,ffffffffc0201c76 <readline>
ffffffffc02002da:	842a                	mv	s0,a0
ffffffffc02002dc:	dd65                	beqz	a0,ffffffffc02002d4 <kmonitor+0x6a>
ffffffffc02002de:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e4:	c999                	beqz	a1,ffffffffc02002fa <kmonitor+0x90>
ffffffffc02002e6:	854a                	mv	a0,s2
ffffffffc02002e8:	30f010ef          	jal	ra,ffffffffc0201df6 <strchr>
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
ffffffffc0200302:	c4ad0d13          	addi	s10,s10,-950 # ffffffffc0201f48 <commands>
    if (argc == 0) {
ffffffffc0200306:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200308:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	0d61                	addi	s10,s10,24
ffffffffc020030c:	2c1010ef          	jal	ra,ffffffffc0201dcc <strcmp>
ffffffffc0200310:	c919                	beqz	a0,ffffffffc0200326 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200312:	2405                	addiw	s0,s0,1
ffffffffc0200314:	09740463          	beq	s0,s7,ffffffffc020039c <kmonitor+0x132>
ffffffffc0200318:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031c:	6582                	ld	a1,0(sp)
ffffffffc020031e:	0d61                	addi	s10,s10,24
ffffffffc0200320:	2ad010ef          	jal	ra,ffffffffc0201dcc <strcmp>
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
ffffffffc0200386:	271010ef          	jal	ra,ffffffffc0201df6 <strchr>
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
ffffffffc02003a2:	c7250513          	addi	a0,a0,-910 # ffffffffc0202010 <commands+0xc8>
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
ffffffffc02003e2:	cea50513          	addi	a0,a0,-790 # ffffffffc02020c8 <commands+0x180>
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
ffffffffc02003f8:	6a450513          	addi	a0,a0,1700 # ffffffffc0202a98 <default_pmm_manager+0xf0>
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
ffffffffc0200424:	12d010ef          	jal	ra,ffffffffc0201d50 <sbi_set_timer>
}
ffffffffc0200428:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042a:	00006797          	auipc	a5,0x6
ffffffffc020042e:	0007bb23          	sd	zero,22(a5) # ffffffffc0206440 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200432:	00002517          	auipc	a0,0x2
ffffffffc0200436:	cb650513          	addi	a0,a0,-842 # ffffffffc02020e8 <commands+0x1a0>
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
ffffffffc020044c:	1050106f          	j	ffffffffc0201d50 <sbi_set_timer>

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
ffffffffc0200456:	0df0106f          	j	ffffffffc0201d34 <sbi_console_putchar>

ffffffffc020045a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045a:	1130106f          	j	ffffffffc0201d6c <sbi_console_getchar>

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
ffffffffc0200488:	d7c50513          	addi	a0,a0,-644 # ffffffffc0202200 <commands+0x2b8>
{
ffffffffc020048c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048e:	c29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200492:	640c                	ld	a1,8(s0)
ffffffffc0200494:	00002517          	auipc	a0,0x2
ffffffffc0200498:	d8450513          	addi	a0,a0,-636 # ffffffffc0202218 <commands+0x2d0>
ffffffffc020049c:	c1bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a0:	680c                	ld	a1,16(s0)
ffffffffc02004a2:	00002517          	auipc	a0,0x2
ffffffffc02004a6:	d8e50513          	addi	a0,a0,-626 # ffffffffc0202230 <commands+0x2e8>
ffffffffc02004aa:	c0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004ae:	6c0c                	ld	a1,24(s0)
ffffffffc02004b0:	00002517          	auipc	a0,0x2
ffffffffc02004b4:	d9850513          	addi	a0,a0,-616 # ffffffffc0202248 <commands+0x300>
ffffffffc02004b8:	bffff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004bc:	700c                	ld	a1,32(s0)
ffffffffc02004be:	00002517          	auipc	a0,0x2
ffffffffc02004c2:	da250513          	addi	a0,a0,-606 # ffffffffc0202260 <commands+0x318>
ffffffffc02004c6:	bf1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004ca:	740c                	ld	a1,40(s0)
ffffffffc02004cc:	00002517          	auipc	a0,0x2
ffffffffc02004d0:	dac50513          	addi	a0,a0,-596 # ffffffffc0202278 <commands+0x330>
ffffffffc02004d4:	be3ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d8:	780c                	ld	a1,48(s0)
ffffffffc02004da:	00002517          	auipc	a0,0x2
ffffffffc02004de:	db650513          	addi	a0,a0,-586 # ffffffffc0202290 <commands+0x348>
ffffffffc02004e2:	bd5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e6:	7c0c                	ld	a1,56(s0)
ffffffffc02004e8:	00002517          	auipc	a0,0x2
ffffffffc02004ec:	dc050513          	addi	a0,a0,-576 # ffffffffc02022a8 <commands+0x360>
ffffffffc02004f0:	bc7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f4:	602c                	ld	a1,64(s0)
ffffffffc02004f6:	00002517          	auipc	a0,0x2
ffffffffc02004fa:	dca50513          	addi	a0,a0,-566 # ffffffffc02022c0 <commands+0x378>
ffffffffc02004fe:	bb9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200502:	642c                	ld	a1,72(s0)
ffffffffc0200504:	00002517          	auipc	a0,0x2
ffffffffc0200508:	dd450513          	addi	a0,a0,-556 # ffffffffc02022d8 <commands+0x390>
ffffffffc020050c:	babff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200510:	682c                	ld	a1,80(s0)
ffffffffc0200512:	00002517          	auipc	a0,0x2
ffffffffc0200516:	dde50513          	addi	a0,a0,-546 # ffffffffc02022f0 <commands+0x3a8>
ffffffffc020051a:	b9dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051e:	6c2c                	ld	a1,88(s0)
ffffffffc0200520:	00002517          	auipc	a0,0x2
ffffffffc0200524:	de850513          	addi	a0,a0,-536 # ffffffffc0202308 <commands+0x3c0>
ffffffffc0200528:	b8fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052c:	702c                	ld	a1,96(s0)
ffffffffc020052e:	00002517          	auipc	a0,0x2
ffffffffc0200532:	df250513          	addi	a0,a0,-526 # ffffffffc0202320 <commands+0x3d8>
ffffffffc0200536:	b81ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053a:	742c                	ld	a1,104(s0)
ffffffffc020053c:	00002517          	auipc	a0,0x2
ffffffffc0200540:	dfc50513          	addi	a0,a0,-516 # ffffffffc0202338 <commands+0x3f0>
ffffffffc0200544:	b73ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200548:	782c                	ld	a1,112(s0)
ffffffffc020054a:	00002517          	auipc	a0,0x2
ffffffffc020054e:	e0650513          	addi	a0,a0,-506 # ffffffffc0202350 <commands+0x408>
ffffffffc0200552:	b65ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200556:	7c2c                	ld	a1,120(s0)
ffffffffc0200558:	00002517          	auipc	a0,0x2
ffffffffc020055c:	e1050513          	addi	a0,a0,-496 # ffffffffc0202368 <commands+0x420>
ffffffffc0200560:	b57ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200564:	604c                	ld	a1,128(s0)
ffffffffc0200566:	00002517          	auipc	a0,0x2
ffffffffc020056a:	e1a50513          	addi	a0,a0,-486 # ffffffffc0202380 <commands+0x438>
ffffffffc020056e:	b49ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200572:	644c                	ld	a1,136(s0)
ffffffffc0200574:	00002517          	auipc	a0,0x2
ffffffffc0200578:	e2450513          	addi	a0,a0,-476 # ffffffffc0202398 <commands+0x450>
ffffffffc020057c:	b3bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200580:	684c                	ld	a1,144(s0)
ffffffffc0200582:	00002517          	auipc	a0,0x2
ffffffffc0200586:	e2e50513          	addi	a0,a0,-466 # ffffffffc02023b0 <commands+0x468>
ffffffffc020058a:	b2dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058e:	6c4c                	ld	a1,152(s0)
ffffffffc0200590:	00002517          	auipc	a0,0x2
ffffffffc0200594:	e3850513          	addi	a0,a0,-456 # ffffffffc02023c8 <commands+0x480>
ffffffffc0200598:	b1fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059c:	704c                	ld	a1,160(s0)
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	e4250513          	addi	a0,a0,-446 # ffffffffc02023e0 <commands+0x498>
ffffffffc02005a6:	b11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005aa:	744c                	ld	a1,168(s0)
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	e4c50513          	addi	a0,a0,-436 # ffffffffc02023f8 <commands+0x4b0>
ffffffffc02005b4:	b03ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b8:	784c                	ld	a1,176(s0)
ffffffffc02005ba:	00002517          	auipc	a0,0x2
ffffffffc02005be:	e5650513          	addi	a0,a0,-426 # ffffffffc0202410 <commands+0x4c8>
ffffffffc02005c2:	af5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c6:	7c4c                	ld	a1,184(s0)
ffffffffc02005c8:	00002517          	auipc	a0,0x2
ffffffffc02005cc:	e6050513          	addi	a0,a0,-416 # ffffffffc0202428 <commands+0x4e0>
ffffffffc02005d0:	ae7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d4:	606c                	ld	a1,192(s0)
ffffffffc02005d6:	00002517          	auipc	a0,0x2
ffffffffc02005da:	e6a50513          	addi	a0,a0,-406 # ffffffffc0202440 <commands+0x4f8>
ffffffffc02005de:	ad9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e2:	646c                	ld	a1,200(s0)
ffffffffc02005e4:	00002517          	auipc	a0,0x2
ffffffffc02005e8:	e7450513          	addi	a0,a0,-396 # ffffffffc0202458 <commands+0x510>
ffffffffc02005ec:	acbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f0:	686c                	ld	a1,208(s0)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	e7e50513          	addi	a0,a0,-386 # ffffffffc0202470 <commands+0x528>
ffffffffc02005fa:	abdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200600:	00002517          	auipc	a0,0x2
ffffffffc0200604:	e8850513          	addi	a0,a0,-376 # ffffffffc0202488 <commands+0x540>
ffffffffc0200608:	aafff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060c:	706c                	ld	a1,224(s0)
ffffffffc020060e:	00002517          	auipc	a0,0x2
ffffffffc0200612:	e9250513          	addi	a0,a0,-366 # ffffffffc02024a0 <commands+0x558>
ffffffffc0200616:	aa1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061a:	746c                	ld	a1,232(s0)
ffffffffc020061c:	00002517          	auipc	a0,0x2
ffffffffc0200620:	e9c50513          	addi	a0,a0,-356 # ffffffffc02024b8 <commands+0x570>
ffffffffc0200624:	a93ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200628:	786c                	ld	a1,240(s0)
ffffffffc020062a:	00002517          	auipc	a0,0x2
ffffffffc020062e:	ea650513          	addi	a0,a0,-346 # ffffffffc02024d0 <commands+0x588>
ffffffffc0200632:	a85ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200638:	6402                	ld	s0,0(sp)
ffffffffc020063a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	eac50513          	addi	a0,a0,-340 # ffffffffc02024e8 <commands+0x5a0>
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
ffffffffc0200656:	eae50513          	addi	a0,a0,-338 # ffffffffc0202500 <commands+0x5b8>
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
ffffffffc020066e:	eae50513          	addi	a0,a0,-338 # ffffffffc0202518 <commands+0x5d0>
ffffffffc0200672:	a45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	eb650513          	addi	a0,a0,-330 # ffffffffc0202530 <commands+0x5e8>
ffffffffc0200682:	a35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	ebe50513          	addi	a0,a0,-322 # ffffffffc0202548 <commands+0x600>
ffffffffc0200692:	a25ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	ec250513          	addi	a0,a0,-318 # ffffffffc0202560 <commands+0x618>
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
ffffffffc02006c0:	a4870713          	addi	a4,a4,-1464 # ffffffffc0202104 <commands+0x1bc>
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
ffffffffc02006d2:	aca50513          	addi	a0,a0,-1334 # ffffffffc0202198 <commands+0x250>
ffffffffc02006d6:	9e1ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc02006da:	00002517          	auipc	a0,0x2
ffffffffc02006de:	a9e50513          	addi	a0,a0,-1378 # ffffffffc0202178 <commands+0x230>
ffffffffc02006e2:	9d5ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc02006e6:	00002517          	auipc	a0,0x2
ffffffffc02006ea:	a5250513          	addi	a0,a0,-1454 # ffffffffc0202138 <commands+0x1f0>
ffffffffc02006ee:	9c9ff06f          	j	ffffffffc02000b6 <cprintf>
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
ffffffffc02006f2:	00002517          	auipc	a0,0x2
ffffffffc02006f6:	ac650513          	addi	a0,a0,-1338 # ffffffffc02021b8 <commands+0x270>
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
ffffffffc0200732:	ab250513          	addi	a0,a0,-1358 # ffffffffc02021e0 <commands+0x298>
ffffffffc0200736:	981ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc020073a:	00002517          	auipc	a0,0x2
ffffffffc020073e:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0202158 <commands+0x210>
ffffffffc0200742:	975ff06f          	j	ffffffffc02000b6 <cprintf>
        print_trapframe(tf);
ffffffffc0200746:	f05ff06f          	j	ffffffffc020064a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020074a:	06400593          	li	a1,100
ffffffffc020074e:	00002517          	auipc	a0,0x2
ffffffffc0200752:	a8250513          	addi	a0,a0,-1406 # ffffffffc02021d0 <commands+0x288>
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
ffffffffc0200780:	60a010ef          	jal	ra,ffffffffc0201d8a <sbi_shutdown>
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

ffffffffc0200856 <default_init>:
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm)
{
    elm->prev = elm->next = elm;
ffffffffc0200856:	00006797          	auipc	a5,0x6
ffffffffc020085a:	bf278793          	addi	a5,a5,-1038 # ffffffffc0206448 <free_area>
ffffffffc020085e:	e79c                	sd	a5,8(a5)
ffffffffc0200860:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200862:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200866:	8082                	ret

ffffffffc0200868 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200868:	00006517          	auipc	a0,0x6
ffffffffc020086c:	bf056503          	lwu	a0,-1040(a0) # ffffffffc0206458 <free_area+0x10>
ffffffffc0200870:	8082                	ret

ffffffffc0200872 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200872:	715d                	addi	sp,sp,-80
ffffffffc0200874:	f84a                	sd	s2,48(sp)
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm)
{
    return listelm->next;
ffffffffc0200876:	00006917          	auipc	s2,0x6
ffffffffc020087a:	bd290913          	addi	s2,s2,-1070 # ffffffffc0206448 <free_area>
ffffffffc020087e:	00893783          	ld	a5,8(s2)
ffffffffc0200882:	e486                	sd	ra,72(sp)
ffffffffc0200884:	e0a2                	sd	s0,64(sp)
ffffffffc0200886:	fc26                	sd	s1,56(sp)
ffffffffc0200888:	f44e                	sd	s3,40(sp)
ffffffffc020088a:	f052                	sd	s4,32(sp)
ffffffffc020088c:	ec56                	sd	s5,24(sp)
ffffffffc020088e:	e85a                	sd	s6,16(sp)
ffffffffc0200890:	e45e                	sd	s7,8(sp)
ffffffffc0200892:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200894:	35278563          	beq	a5,s2,ffffffffc0200bde <default_check+0x36c>
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr)
{
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200898:	ff07b703          	ld	a4,-16(a5)
ffffffffc020089c:	8305                	srli	a4,a4,0x1
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020089e:	8b05                	andi	a4,a4,1
ffffffffc02008a0:	34070363          	beqz	a4,ffffffffc0200be6 <default_check+0x374>
    int count = 0, total = 0;
ffffffffc02008a4:	4401                	li	s0,0
ffffffffc02008a6:	4481                	li	s1,0
ffffffffc02008a8:	a031                	j	ffffffffc02008b4 <default_check+0x42>
ffffffffc02008aa:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc02008ae:	8b09                	andi	a4,a4,2
ffffffffc02008b0:	32070b63          	beqz	a4,ffffffffc0200be6 <default_check+0x374>
        count++, total += p->property;
ffffffffc02008b4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02008b8:	679c                	ld	a5,8(a5)
ffffffffc02008ba:	2485                	addiw	s1,s1,1
ffffffffc02008bc:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02008be:	ff2796e3          	bne	a5,s2,ffffffffc02008aa <default_check+0x38>
ffffffffc02008c2:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc02008c4:	425000ef          	jal	ra,ffffffffc02014e8 <nr_free_pages>
ffffffffc02008c8:	77351f63          	bne	a0,s3,ffffffffc0201046 <default_check+0x7d4>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02008cc:	4505                	li	a0,1
ffffffffc02008ce:	391000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc02008d2:	8a2a                	mv	s4,a0
ffffffffc02008d4:	4a050963          	beqz	a0,ffffffffc0200d86 <default_check+0x514>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02008d8:	4505                	li	a0,1
ffffffffc02008da:	385000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc02008de:	89aa                	mv	s3,a0
ffffffffc02008e0:	78050363          	beqz	a0,ffffffffc0201066 <default_check+0x7f4>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02008e4:	4505                	li	a0,1
ffffffffc02008e6:	379000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc02008ea:	8aaa                	mv	s5,a0
ffffffffc02008ec:	50050d63          	beqz	a0,ffffffffc0200e06 <default_check+0x594>
    cprintf("p0的虚拟地址: 0x%016lx.\n", (uintptr_t)p0);
ffffffffc02008f0:	85d2                	mv	a1,s4
ffffffffc02008f2:	00002517          	auipc	a0,0x2
ffffffffc02008f6:	d4e50513          	addi	a0,a0,-690 # ffffffffc0202640 <commands+0x6f8>
ffffffffc02008fa:	fbcff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("p1的虚拟地址: 0x%016lx.\n", (uintptr_t)p1);
ffffffffc02008fe:	85ce                	mv	a1,s3
ffffffffc0200900:	00002517          	auipc	a0,0x2
ffffffffc0200904:	d6050513          	addi	a0,a0,-672 # ffffffffc0202660 <commands+0x718>
ffffffffc0200908:	faeff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("p2的虚拟地址: 0x%016lx.\n", (uintptr_t)p2);
ffffffffc020090c:	85d6                	mv	a1,s5
ffffffffc020090e:	00002517          	auipc	a0,0x2
ffffffffc0200912:	d7250513          	addi	a0,a0,-654 # ffffffffc0202680 <commands+0x738>
ffffffffc0200916:	fa0ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020091a:	2f3a0663          	beq	s4,s3,ffffffffc0200c06 <default_check+0x394>
ffffffffc020091e:	2f5a0463          	beq	s4,s5,ffffffffc0200c06 <default_check+0x394>
ffffffffc0200922:	2f598263          	beq	s3,s5,ffffffffc0200c06 <default_check+0x394>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200926:	000a2783          	lw	a5,0(s4)
ffffffffc020092a:	2e079e63          	bnez	a5,ffffffffc0200c26 <default_check+0x3b4>
ffffffffc020092e:	0009a783          	lw	a5,0(s3)
ffffffffc0200932:	2e079a63          	bnez	a5,ffffffffc0200c26 <default_check+0x3b4>
ffffffffc0200936:	000aa783          	lw	a5,0(s5)
ffffffffc020093a:	2e079663          	bnez	a5,ffffffffc0200c26 <default_check+0x3b4>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020093e:	00006797          	auipc	a5,0x6
ffffffffc0200942:	b3a78793          	addi	a5,a5,-1222 # ffffffffc0206478 <pages>
ffffffffc0200946:	639c                	ld	a5,0(a5)
ffffffffc0200948:	00002717          	auipc	a4,0x2
ffffffffc020094c:	c3070713          	addi	a4,a4,-976 # ffffffffc0202578 <commands+0x630>
ffffffffc0200950:	630c                	ld	a1,0(a4)
ffffffffc0200952:	40fa0733          	sub	a4,s4,a5
ffffffffc0200956:	870d                	srai	a4,a4,0x3
ffffffffc0200958:	02b70733          	mul	a4,a4,a1
ffffffffc020095c:	00002697          	auipc	a3,0x2
ffffffffc0200960:	5d468693          	addi	a3,a3,1492 # ffffffffc0202f30 <nbase>
ffffffffc0200964:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200966:	00006697          	auipc	a3,0x6
ffffffffc020096a:	ac268693          	addi	a3,a3,-1342 # ffffffffc0206428 <npage>
ffffffffc020096e:	6294                	ld	a3,0(a3)
ffffffffc0200970:	06b2                	slli	a3,a3,0xc
ffffffffc0200972:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200974:	0732                	slli	a4,a4,0xc
ffffffffc0200976:	2cd77863          	bleu	a3,a4,ffffffffc0200c46 <default_check+0x3d4>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020097a:	40f98733          	sub	a4,s3,a5
ffffffffc020097e:	870d                	srai	a4,a4,0x3
ffffffffc0200980:	02b70733          	mul	a4,a4,a1
ffffffffc0200984:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200986:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200988:	4ed77f63          	bleu	a3,a4,ffffffffc0200e86 <default_check+0x614>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020098c:	40fa87b3          	sub	a5,s5,a5
ffffffffc0200990:	878d                	srai	a5,a5,0x3
ffffffffc0200992:	02b787b3          	mul	a5,a5,a1
ffffffffc0200996:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200998:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020099a:	34d7f663          	bleu	a3,a5,ffffffffc0200ce6 <default_check+0x474>
    assert(alloc_page() == NULL);
ffffffffc020099e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02009a0:	00093c03          	ld	s8,0(s2)
ffffffffc02009a4:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc02009a8:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc02009ac:	00006797          	auipc	a5,0x6
ffffffffc02009b0:	ab27b223          	sd	s2,-1372(a5) # ffffffffc0206450 <free_area+0x8>
ffffffffc02009b4:	00006797          	auipc	a5,0x6
ffffffffc02009b8:	a927ba23          	sd	s2,-1388(a5) # ffffffffc0206448 <free_area>
    nr_free = 0;
ffffffffc02009bc:	00006797          	auipc	a5,0x6
ffffffffc02009c0:	a807ae23          	sw	zero,-1380(a5) # ffffffffc0206458 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02009c4:	29b000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc02009c8:	2e051f63          	bnez	a0,ffffffffc0200cc6 <default_check+0x454>
    free_page(p0);
ffffffffc02009cc:	4585                	li	a1,1
ffffffffc02009ce:	8552                	mv	a0,s4
ffffffffc02009d0:	2d3000ef          	jal	ra,ffffffffc02014a2 <free_pages>
    free_page(p1);
ffffffffc02009d4:	4585                	li	a1,1
ffffffffc02009d6:	854e                	mv	a0,s3
ffffffffc02009d8:	2cb000ef          	jal	ra,ffffffffc02014a2 <free_pages>
    free_page(p2);
ffffffffc02009dc:	4585                	li	a1,1
ffffffffc02009de:	8556                	mv	a0,s5
ffffffffc02009e0:	2c3000ef          	jal	ra,ffffffffc02014a2 <free_pages>
    assert(nr_free == 3);
ffffffffc02009e4:	01092703          	lw	a4,16(s2)
ffffffffc02009e8:	478d                	li	a5,3
ffffffffc02009ea:	2af71e63          	bne	a4,a5,ffffffffc0200ca6 <default_check+0x434>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02009ee:	4505                	li	a0,1
ffffffffc02009f0:	26f000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc02009f4:	89aa                	mv	s3,a0
ffffffffc02009f6:	28050863          	beqz	a0,ffffffffc0200c86 <default_check+0x414>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02009fa:	4505                	li	a0,1
ffffffffc02009fc:	263000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200a00:	8aaa                	mv	s5,a0
ffffffffc0200a02:	3e050263          	beqz	a0,ffffffffc0200de6 <default_check+0x574>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a06:	4505                	li	a0,1
ffffffffc0200a08:	257000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200a0c:	8a2a                	mv	s4,a0
ffffffffc0200a0e:	3a050c63          	beqz	a0,ffffffffc0200dc6 <default_check+0x554>
    assert(alloc_page() == NULL);
ffffffffc0200a12:	4505                	li	a0,1
ffffffffc0200a14:	24b000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200a18:	38051763          	bnez	a0,ffffffffc0200da6 <default_check+0x534>
    free_page(p0);
ffffffffc0200a1c:	4585                	li	a1,1
ffffffffc0200a1e:	854e                	mv	a0,s3
ffffffffc0200a20:	283000ef          	jal	ra,ffffffffc02014a2 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200a24:	00893783          	ld	a5,8(s2)
ffffffffc0200a28:	23278f63          	beq	a5,s2,ffffffffc0200c66 <default_check+0x3f4>
    assert((p = alloc_page()) == p0);
ffffffffc0200a2c:	4505                	li	a0,1
ffffffffc0200a2e:	231000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200a32:	32a99a63          	bne	s3,a0,ffffffffc0200d66 <default_check+0x4f4>
    assert(alloc_page() == NULL);
ffffffffc0200a36:	4505                	li	a0,1
ffffffffc0200a38:	227000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200a3c:	30051563          	bnez	a0,ffffffffc0200d46 <default_check+0x4d4>
    assert(nr_free == 0);
ffffffffc0200a40:	01092783          	lw	a5,16(s2)
ffffffffc0200a44:	2e079163          	bnez	a5,ffffffffc0200d26 <default_check+0x4b4>
    free_page(p);
ffffffffc0200a48:	854e                	mv	a0,s3
ffffffffc0200a4a:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200a4c:	00006797          	auipc	a5,0x6
ffffffffc0200a50:	9f87be23          	sd	s8,-1540(a5) # ffffffffc0206448 <free_area>
ffffffffc0200a54:	00006797          	auipc	a5,0x6
ffffffffc0200a58:	9f77be23          	sd	s7,-1540(a5) # ffffffffc0206450 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0200a5c:	00006797          	auipc	a5,0x6
ffffffffc0200a60:	9f67ae23          	sw	s6,-1540(a5) # ffffffffc0206458 <free_area+0x10>
    free_page(p);
ffffffffc0200a64:	23f000ef          	jal	ra,ffffffffc02014a2 <free_pages>
    free_page(p1);
ffffffffc0200a68:	4585                	li	a1,1
ffffffffc0200a6a:	8556                	mv	a0,s5
ffffffffc0200a6c:	237000ef          	jal	ra,ffffffffc02014a2 <free_pages>
    free_page(p2);
ffffffffc0200a70:	4585                	li	a1,1
ffffffffc0200a72:	8552                	mv	a0,s4
ffffffffc0200a74:	22f000ef          	jal	ra,ffffffffc02014a2 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200a78:	4515                	li	a0,5
ffffffffc0200a7a:	1e5000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200a7e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200a80:	28050363          	beqz	a0,ffffffffc0200d06 <default_check+0x494>
ffffffffc0200a84:	651c                	ld	a5,8(a0)
ffffffffc0200a86:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200a88:	8b85                	andi	a5,a5,1
ffffffffc0200a8a:	54079e63          	bnez	a5,ffffffffc0200fe6 <default_check+0x774>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200a8e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200a90:	00093b03          	ld	s6,0(s2)
ffffffffc0200a94:	00893a83          	ld	s5,8(s2)
ffffffffc0200a98:	00006797          	auipc	a5,0x6
ffffffffc0200a9c:	9b27b823          	sd	s2,-1616(a5) # ffffffffc0206448 <free_area>
ffffffffc0200aa0:	00006797          	auipc	a5,0x6
ffffffffc0200aa4:	9b27b823          	sd	s2,-1616(a5) # ffffffffc0206450 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200aa8:	1b7000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200aac:	50051d63          	bnez	a0,ffffffffc0200fc6 <default_check+0x754>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200ab0:	05098a13          	addi	s4,s3,80
ffffffffc0200ab4:	8552                	mv	a0,s4
ffffffffc0200ab6:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200ab8:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc0200abc:	00006797          	auipc	a5,0x6
ffffffffc0200ac0:	9807ae23          	sw	zero,-1636(a5) # ffffffffc0206458 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200ac4:	1df000ef          	jal	ra,ffffffffc02014a2 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ac8:	4511                	li	a0,4
ffffffffc0200aca:	195000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200ace:	4c051c63          	bnez	a0,ffffffffc0200fa6 <default_check+0x734>
ffffffffc0200ad2:	0589b783          	ld	a5,88(s3)
ffffffffc0200ad6:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200ad8:	8b85                	andi	a5,a5,1
ffffffffc0200ada:	4a078663          	beqz	a5,ffffffffc0200f86 <default_check+0x714>
ffffffffc0200ade:	0609a703          	lw	a4,96(s3)
ffffffffc0200ae2:	478d                	li	a5,3
ffffffffc0200ae4:	4af71163          	bne	a4,a5,ffffffffc0200f86 <default_check+0x714>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200ae8:	450d                	li	a0,3
ffffffffc0200aea:	175000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200aee:	8c2a                	mv	s8,a0
ffffffffc0200af0:	46050b63          	beqz	a0,ffffffffc0200f66 <default_check+0x6f4>
    assert(alloc_page() == NULL);
ffffffffc0200af4:	4505                	li	a0,1
ffffffffc0200af6:	169000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200afa:	44051663          	bnez	a0,ffffffffc0200f46 <default_check+0x6d4>
    assert(p0 + 2 == p1);
ffffffffc0200afe:	438a1463          	bne	s4,s8,ffffffffc0200f26 <default_check+0x6b4>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200b02:	4585                	li	a1,1
ffffffffc0200b04:	854e                	mv	a0,s3
ffffffffc0200b06:	19d000ef          	jal	ra,ffffffffc02014a2 <free_pages>
    free_pages(p1, 3);
ffffffffc0200b0a:	458d                	li	a1,3
ffffffffc0200b0c:	8552                	mv	a0,s4
ffffffffc0200b0e:	195000ef          	jal	ra,ffffffffc02014a2 <free_pages>
ffffffffc0200b12:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200b16:	02898c13          	addi	s8,s3,40
ffffffffc0200b1a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200b1c:	8b85                	andi	a5,a5,1
ffffffffc0200b1e:	3e078463          	beqz	a5,ffffffffc0200f06 <default_check+0x694>
ffffffffc0200b22:	0109a703          	lw	a4,16(s3)
ffffffffc0200b26:	4785                	li	a5,1
ffffffffc0200b28:	3cf71f63          	bne	a4,a5,ffffffffc0200f06 <default_check+0x694>
ffffffffc0200b2c:	008a3783          	ld	a5,8(s4)
ffffffffc0200b30:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200b32:	8b85                	andi	a5,a5,1
ffffffffc0200b34:	3a078963          	beqz	a5,ffffffffc0200ee6 <default_check+0x674>
ffffffffc0200b38:	010a2703          	lw	a4,16(s4)
ffffffffc0200b3c:	478d                	li	a5,3
ffffffffc0200b3e:	3af71463          	bne	a4,a5,ffffffffc0200ee6 <default_check+0x674>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200b42:	4505                	li	a0,1
ffffffffc0200b44:	11b000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200b48:	36a99f63          	bne	s3,a0,ffffffffc0200ec6 <default_check+0x654>
    free_page(p0);
ffffffffc0200b4c:	4585                	li	a1,1
ffffffffc0200b4e:	155000ef          	jal	ra,ffffffffc02014a2 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200b52:	4509                	li	a0,2
ffffffffc0200b54:	10b000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200b58:	34aa1763          	bne	s4,a0,ffffffffc0200ea6 <default_check+0x634>

    free_pages(p0, 2);
ffffffffc0200b5c:	4589                	li	a1,2
ffffffffc0200b5e:	145000ef          	jal	ra,ffffffffc02014a2 <free_pages>
    free_page(p2);
ffffffffc0200b62:	4585                	li	a1,1
ffffffffc0200b64:	8562                	mv	a0,s8
ffffffffc0200b66:	13d000ef          	jal	ra,ffffffffc02014a2 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200b6a:	4515                	li	a0,5
ffffffffc0200b6c:	0f3000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200b70:	89aa                	mv	s3,a0
ffffffffc0200b72:	48050a63          	beqz	a0,ffffffffc0201006 <default_check+0x794>
    assert(alloc_page() == NULL);
ffffffffc0200b76:	4505                	li	a0,1
ffffffffc0200b78:	0e7000ef          	jal	ra,ffffffffc020145e <alloc_pages>
ffffffffc0200b7c:	2e051563          	bnez	a0,ffffffffc0200e66 <default_check+0x5f4>

    assert(nr_free == 0);
ffffffffc0200b80:	01092783          	lw	a5,16(s2)
ffffffffc0200b84:	2c079163          	bnez	a5,ffffffffc0200e46 <default_check+0x5d4>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200b88:	4595                	li	a1,5
ffffffffc0200b8a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200b8c:	00006797          	auipc	a5,0x6
ffffffffc0200b90:	8d77a623          	sw	s7,-1844(a5) # ffffffffc0206458 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0200b94:	00006797          	auipc	a5,0x6
ffffffffc0200b98:	8b67ba23          	sd	s6,-1868(a5) # ffffffffc0206448 <free_area>
ffffffffc0200b9c:	00006797          	auipc	a5,0x6
ffffffffc0200ba0:	8b57ba23          	sd	s5,-1868(a5) # ffffffffc0206450 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0200ba4:	0ff000ef          	jal	ra,ffffffffc02014a2 <free_pages>
    return listelm->next;
ffffffffc0200ba8:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200bac:	01278963          	beq	a5,s2,ffffffffc0200bbe <default_check+0x34c>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0200bb0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200bb4:	679c                	ld	a5,8(a5)
ffffffffc0200bb6:	34fd                	addiw	s1,s1,-1
ffffffffc0200bb8:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200bba:	ff279be3          	bne	a5,s2,ffffffffc0200bb0 <default_check+0x33e>
    }
    assert(count == 0);
ffffffffc0200bbe:	26049463          	bnez	s1,ffffffffc0200e26 <default_check+0x5b4>
    assert(total == 0);
ffffffffc0200bc2:	46041263          	bnez	s0,ffffffffc0201026 <default_check+0x7b4>
}
ffffffffc0200bc6:	60a6                	ld	ra,72(sp)
ffffffffc0200bc8:	6406                	ld	s0,64(sp)
ffffffffc0200bca:	74e2                	ld	s1,56(sp)
ffffffffc0200bcc:	7942                	ld	s2,48(sp)
ffffffffc0200bce:	79a2                	ld	s3,40(sp)
ffffffffc0200bd0:	7a02                	ld	s4,32(sp)
ffffffffc0200bd2:	6ae2                	ld	s5,24(sp)
ffffffffc0200bd4:	6b42                	ld	s6,16(sp)
ffffffffc0200bd6:	6ba2                	ld	s7,8(sp)
ffffffffc0200bd8:	6c02                	ld	s8,0(sp)
ffffffffc0200bda:	6161                	addi	sp,sp,80
ffffffffc0200bdc:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0200bde:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200be0:	4401                	li	s0,0
ffffffffc0200be2:	4481                	li	s1,0
ffffffffc0200be4:	b1c5                	j	ffffffffc02008c4 <default_check+0x52>
        assert(PageProperty(p));
ffffffffc0200be6:	00002697          	auipc	a3,0x2
ffffffffc0200bea:	99a68693          	addi	a3,a3,-1638 # ffffffffc0202580 <commands+0x638>
ffffffffc0200bee:	00002617          	auipc	a2,0x2
ffffffffc0200bf2:	9a260613          	addi	a2,a2,-1630 # ffffffffc0202590 <commands+0x648>
ffffffffc0200bf6:	12d00593          	li	a1,301
ffffffffc0200bfa:	00002517          	auipc	a0,0x2
ffffffffc0200bfe:	9ae50513          	addi	a0,a0,-1618 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200c02:	faaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c06:	00002697          	auipc	a3,0x2
ffffffffc0200c0a:	a9a68693          	addi	a3,a3,-1382 # ffffffffc02026a0 <commands+0x758>
ffffffffc0200c0e:	00002617          	auipc	a2,0x2
ffffffffc0200c12:	98260613          	addi	a2,a2,-1662 # ffffffffc0202590 <commands+0x648>
ffffffffc0200c16:	0f800593          	li	a1,248
ffffffffc0200c1a:	00002517          	auipc	a0,0x2
ffffffffc0200c1e:	98e50513          	addi	a0,a0,-1650 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200c22:	f8aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c26:	00002697          	auipc	a3,0x2
ffffffffc0200c2a:	aa268693          	addi	a3,a3,-1374 # ffffffffc02026c8 <commands+0x780>
ffffffffc0200c2e:	00002617          	auipc	a2,0x2
ffffffffc0200c32:	96260613          	addi	a2,a2,-1694 # ffffffffc0202590 <commands+0x648>
ffffffffc0200c36:	0f900593          	li	a1,249
ffffffffc0200c3a:	00002517          	auipc	a0,0x2
ffffffffc0200c3e:	96e50513          	addi	a0,a0,-1682 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200c42:	f6aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200c46:	00002697          	auipc	a3,0x2
ffffffffc0200c4a:	ac268693          	addi	a3,a3,-1342 # ffffffffc0202708 <commands+0x7c0>
ffffffffc0200c4e:	00002617          	auipc	a2,0x2
ffffffffc0200c52:	94260613          	addi	a2,a2,-1726 # ffffffffc0202590 <commands+0x648>
ffffffffc0200c56:	0fb00593          	li	a1,251
ffffffffc0200c5a:	00002517          	auipc	a0,0x2
ffffffffc0200c5e:	94e50513          	addi	a0,a0,-1714 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200c62:	f4aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200c66:	00002697          	auipc	a3,0x2
ffffffffc0200c6a:	b2a68693          	addi	a3,a3,-1238 # ffffffffc0202790 <commands+0x848>
ffffffffc0200c6e:	00002617          	auipc	a2,0x2
ffffffffc0200c72:	92260613          	addi	a2,a2,-1758 # ffffffffc0202590 <commands+0x648>
ffffffffc0200c76:	11400593          	li	a1,276
ffffffffc0200c7a:	00002517          	auipc	a0,0x2
ffffffffc0200c7e:	92e50513          	addi	a0,a0,-1746 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200c82:	f2aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c86:	00002697          	auipc	a3,0x2
ffffffffc0200c8a:	95a68693          	addi	a3,a3,-1702 # ffffffffc02025e0 <commands+0x698>
ffffffffc0200c8e:	00002617          	auipc	a2,0x2
ffffffffc0200c92:	90260613          	addi	a2,a2,-1790 # ffffffffc0202590 <commands+0x648>
ffffffffc0200c96:	10d00593          	li	a1,269
ffffffffc0200c9a:	00002517          	auipc	a0,0x2
ffffffffc0200c9e:	90e50513          	addi	a0,a0,-1778 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200ca2:	f0aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 3);
ffffffffc0200ca6:	00002697          	auipc	a3,0x2
ffffffffc0200caa:	ada68693          	addi	a3,a3,-1318 # ffffffffc0202780 <commands+0x838>
ffffffffc0200cae:	00002617          	auipc	a2,0x2
ffffffffc0200cb2:	8e260613          	addi	a2,a2,-1822 # ffffffffc0202590 <commands+0x648>
ffffffffc0200cb6:	10b00593          	li	a1,267
ffffffffc0200cba:	00002517          	auipc	a0,0x2
ffffffffc0200cbe:	8ee50513          	addi	a0,a0,-1810 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200cc2:	eeaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cc6:	00002697          	auipc	a3,0x2
ffffffffc0200cca:	aa268693          	addi	a3,a3,-1374 # ffffffffc0202768 <commands+0x820>
ffffffffc0200cce:	00002617          	auipc	a2,0x2
ffffffffc0200cd2:	8c260613          	addi	a2,a2,-1854 # ffffffffc0202590 <commands+0x648>
ffffffffc0200cd6:	10600593          	li	a1,262
ffffffffc0200cda:	00002517          	auipc	a0,0x2
ffffffffc0200cde:	8ce50513          	addi	a0,a0,-1842 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200ce2:	ecaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ce6:	00002697          	auipc	a3,0x2
ffffffffc0200cea:	a6268693          	addi	a3,a3,-1438 # ffffffffc0202748 <commands+0x800>
ffffffffc0200cee:	00002617          	auipc	a2,0x2
ffffffffc0200cf2:	8a260613          	addi	a2,a2,-1886 # ffffffffc0202590 <commands+0x648>
ffffffffc0200cf6:	0fd00593          	li	a1,253
ffffffffc0200cfa:	00002517          	auipc	a0,0x2
ffffffffc0200cfe:	8ae50513          	addi	a0,a0,-1874 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200d02:	eaaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != NULL);
ffffffffc0200d06:	00002697          	auipc	a3,0x2
ffffffffc0200d0a:	ad268693          	addi	a3,a3,-1326 # ffffffffc02027d8 <commands+0x890>
ffffffffc0200d0e:	00002617          	auipc	a2,0x2
ffffffffc0200d12:	88260613          	addi	a2,a2,-1918 # ffffffffc0202590 <commands+0x648>
ffffffffc0200d16:	13500593          	li	a1,309
ffffffffc0200d1a:	00002517          	auipc	a0,0x2
ffffffffc0200d1e:	88e50513          	addi	a0,a0,-1906 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200d22:	e8aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200d26:	00002697          	auipc	a3,0x2
ffffffffc0200d2a:	aa268693          	addi	a3,a3,-1374 # ffffffffc02027c8 <commands+0x880>
ffffffffc0200d2e:	00002617          	auipc	a2,0x2
ffffffffc0200d32:	86260613          	addi	a2,a2,-1950 # ffffffffc0202590 <commands+0x648>
ffffffffc0200d36:	11a00593          	li	a1,282
ffffffffc0200d3a:	00002517          	auipc	a0,0x2
ffffffffc0200d3e:	86e50513          	addi	a0,a0,-1938 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200d42:	e6aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d46:	00002697          	auipc	a3,0x2
ffffffffc0200d4a:	a2268693          	addi	a3,a3,-1502 # ffffffffc0202768 <commands+0x820>
ffffffffc0200d4e:	00002617          	auipc	a2,0x2
ffffffffc0200d52:	84260613          	addi	a2,a2,-1982 # ffffffffc0202590 <commands+0x648>
ffffffffc0200d56:	11800593          	li	a1,280
ffffffffc0200d5a:	00002517          	auipc	a0,0x2
ffffffffc0200d5e:	84e50513          	addi	a0,a0,-1970 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200d62:	e4aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d66:	00002697          	auipc	a3,0x2
ffffffffc0200d6a:	a4268693          	addi	a3,a3,-1470 # ffffffffc02027a8 <commands+0x860>
ffffffffc0200d6e:	00002617          	auipc	a2,0x2
ffffffffc0200d72:	82260613          	addi	a2,a2,-2014 # ffffffffc0202590 <commands+0x648>
ffffffffc0200d76:	11700593          	li	a1,279
ffffffffc0200d7a:	00002517          	auipc	a0,0x2
ffffffffc0200d7e:	82e50513          	addi	a0,a0,-2002 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200d82:	e2aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d86:	00002697          	auipc	a3,0x2
ffffffffc0200d8a:	85a68693          	addi	a3,a3,-1958 # ffffffffc02025e0 <commands+0x698>
ffffffffc0200d8e:	00002617          	auipc	a2,0x2
ffffffffc0200d92:	80260613          	addi	a2,a2,-2046 # ffffffffc0202590 <commands+0x648>
ffffffffc0200d96:	0f100593          	li	a1,241
ffffffffc0200d9a:	00002517          	auipc	a0,0x2
ffffffffc0200d9e:	80e50513          	addi	a0,a0,-2034 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200da2:	e0aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200da6:	00002697          	auipc	a3,0x2
ffffffffc0200daa:	9c268693          	addi	a3,a3,-1598 # ffffffffc0202768 <commands+0x820>
ffffffffc0200dae:	00001617          	auipc	a2,0x1
ffffffffc0200db2:	7e260613          	addi	a2,a2,2018 # ffffffffc0202590 <commands+0x648>
ffffffffc0200db6:	11100593          	li	a1,273
ffffffffc0200dba:	00001517          	auipc	a0,0x1
ffffffffc0200dbe:	7ee50513          	addi	a0,a0,2030 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200dc2:	deaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200dc6:	00002697          	auipc	a3,0x2
ffffffffc0200dca:	85a68693          	addi	a3,a3,-1958 # ffffffffc0202620 <commands+0x6d8>
ffffffffc0200dce:	00001617          	auipc	a2,0x1
ffffffffc0200dd2:	7c260613          	addi	a2,a2,1986 # ffffffffc0202590 <commands+0x648>
ffffffffc0200dd6:	10f00593          	li	a1,271
ffffffffc0200dda:	00001517          	auipc	a0,0x1
ffffffffc0200dde:	7ce50513          	addi	a0,a0,1998 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200de2:	dcaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200de6:	00002697          	auipc	a3,0x2
ffffffffc0200dea:	81a68693          	addi	a3,a3,-2022 # ffffffffc0202600 <commands+0x6b8>
ffffffffc0200dee:	00001617          	auipc	a2,0x1
ffffffffc0200df2:	7a260613          	addi	a2,a2,1954 # ffffffffc0202590 <commands+0x648>
ffffffffc0200df6:	10e00593          	li	a1,270
ffffffffc0200dfa:	00001517          	auipc	a0,0x1
ffffffffc0200dfe:	7ae50513          	addi	a0,a0,1966 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200e02:	daaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e06:	00002697          	auipc	a3,0x2
ffffffffc0200e0a:	81a68693          	addi	a3,a3,-2022 # ffffffffc0202620 <commands+0x6d8>
ffffffffc0200e0e:	00001617          	auipc	a2,0x1
ffffffffc0200e12:	78260613          	addi	a2,a2,1922 # ffffffffc0202590 <commands+0x648>
ffffffffc0200e16:	0f300593          	li	a1,243
ffffffffc0200e1a:	00001517          	auipc	a0,0x1
ffffffffc0200e1e:	78e50513          	addi	a0,a0,1934 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200e22:	d8aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(count == 0);
ffffffffc0200e26:	00002697          	auipc	a3,0x2
ffffffffc0200e2a:	b0268693          	addi	a3,a3,-1278 # ffffffffc0202928 <commands+0x9e0>
ffffffffc0200e2e:	00001617          	auipc	a2,0x1
ffffffffc0200e32:	76260613          	addi	a2,a2,1890 # ffffffffc0202590 <commands+0x648>
ffffffffc0200e36:	16300593          	li	a1,355
ffffffffc0200e3a:	00001517          	auipc	a0,0x1
ffffffffc0200e3e:	76e50513          	addi	a0,a0,1902 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200e42:	d6aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200e46:	00002697          	auipc	a3,0x2
ffffffffc0200e4a:	98268693          	addi	a3,a3,-1662 # ffffffffc02027c8 <commands+0x880>
ffffffffc0200e4e:	00001617          	auipc	a2,0x1
ffffffffc0200e52:	74260613          	addi	a2,a2,1858 # ffffffffc0202590 <commands+0x648>
ffffffffc0200e56:	15700593          	li	a1,343
ffffffffc0200e5a:	00001517          	auipc	a0,0x1
ffffffffc0200e5e:	74e50513          	addi	a0,a0,1870 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200e62:	d4aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e66:	00002697          	auipc	a3,0x2
ffffffffc0200e6a:	90268693          	addi	a3,a3,-1790 # ffffffffc0202768 <commands+0x820>
ffffffffc0200e6e:	00001617          	auipc	a2,0x1
ffffffffc0200e72:	72260613          	addi	a2,a2,1826 # ffffffffc0202590 <commands+0x648>
ffffffffc0200e76:	15500593          	li	a1,341
ffffffffc0200e7a:	00001517          	auipc	a0,0x1
ffffffffc0200e7e:	72e50513          	addi	a0,a0,1838 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200e82:	d2aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e86:	00002697          	auipc	a3,0x2
ffffffffc0200e8a:	8a268693          	addi	a3,a3,-1886 # ffffffffc0202728 <commands+0x7e0>
ffffffffc0200e8e:	00001617          	auipc	a2,0x1
ffffffffc0200e92:	70260613          	addi	a2,a2,1794 # ffffffffc0202590 <commands+0x648>
ffffffffc0200e96:	0fc00593          	li	a1,252
ffffffffc0200e9a:	00001517          	auipc	a0,0x1
ffffffffc0200e9e:	70e50513          	addi	a0,a0,1806 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200ea2:	d0aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200ea6:	00002697          	auipc	a3,0x2
ffffffffc0200eaa:	a4268693          	addi	a3,a3,-1470 # ffffffffc02028e8 <commands+0x9a0>
ffffffffc0200eae:	00001617          	auipc	a2,0x1
ffffffffc0200eb2:	6e260613          	addi	a2,a2,1762 # ffffffffc0202590 <commands+0x648>
ffffffffc0200eb6:	14f00593          	li	a1,335
ffffffffc0200eba:	00001517          	auipc	a0,0x1
ffffffffc0200ebe:	6ee50513          	addi	a0,a0,1774 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200ec2:	ceaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200ec6:	00002697          	auipc	a3,0x2
ffffffffc0200eca:	a0268693          	addi	a3,a3,-1534 # ffffffffc02028c8 <commands+0x980>
ffffffffc0200ece:	00001617          	auipc	a2,0x1
ffffffffc0200ed2:	6c260613          	addi	a2,a2,1730 # ffffffffc0202590 <commands+0x648>
ffffffffc0200ed6:	14d00593          	li	a1,333
ffffffffc0200eda:	00001517          	auipc	a0,0x1
ffffffffc0200ede:	6ce50513          	addi	a0,a0,1742 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200ee2:	ccaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200ee6:	00002697          	auipc	a3,0x2
ffffffffc0200eea:	9ba68693          	addi	a3,a3,-1606 # ffffffffc02028a0 <commands+0x958>
ffffffffc0200eee:	00001617          	auipc	a2,0x1
ffffffffc0200ef2:	6a260613          	addi	a2,a2,1698 # ffffffffc0202590 <commands+0x648>
ffffffffc0200ef6:	14b00593          	li	a1,331
ffffffffc0200efa:	00001517          	auipc	a0,0x1
ffffffffc0200efe:	6ae50513          	addi	a0,a0,1710 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200f02:	caaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200f06:	00002697          	auipc	a3,0x2
ffffffffc0200f0a:	97268693          	addi	a3,a3,-1678 # ffffffffc0202878 <commands+0x930>
ffffffffc0200f0e:	00001617          	auipc	a2,0x1
ffffffffc0200f12:	68260613          	addi	a2,a2,1666 # ffffffffc0202590 <commands+0x648>
ffffffffc0200f16:	14a00593          	li	a1,330
ffffffffc0200f1a:	00001517          	auipc	a0,0x1
ffffffffc0200f1e:	68e50513          	addi	a0,a0,1678 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200f22:	c8aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 + 2 == p1);
ffffffffc0200f26:	00002697          	auipc	a3,0x2
ffffffffc0200f2a:	94268693          	addi	a3,a3,-1726 # ffffffffc0202868 <commands+0x920>
ffffffffc0200f2e:	00001617          	auipc	a2,0x1
ffffffffc0200f32:	66260613          	addi	a2,a2,1634 # ffffffffc0202590 <commands+0x648>
ffffffffc0200f36:	14500593          	li	a1,325
ffffffffc0200f3a:	00001517          	auipc	a0,0x1
ffffffffc0200f3e:	66e50513          	addi	a0,a0,1646 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200f42:	c6aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f46:	00002697          	auipc	a3,0x2
ffffffffc0200f4a:	82268693          	addi	a3,a3,-2014 # ffffffffc0202768 <commands+0x820>
ffffffffc0200f4e:	00001617          	auipc	a2,0x1
ffffffffc0200f52:	64260613          	addi	a2,a2,1602 # ffffffffc0202590 <commands+0x648>
ffffffffc0200f56:	14400593          	li	a1,324
ffffffffc0200f5a:	00001517          	auipc	a0,0x1
ffffffffc0200f5e:	64e50513          	addi	a0,a0,1614 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200f62:	c4aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200f66:	00002697          	auipc	a3,0x2
ffffffffc0200f6a:	8e268693          	addi	a3,a3,-1822 # ffffffffc0202848 <commands+0x900>
ffffffffc0200f6e:	00001617          	auipc	a2,0x1
ffffffffc0200f72:	62260613          	addi	a2,a2,1570 # ffffffffc0202590 <commands+0x648>
ffffffffc0200f76:	14300593          	li	a1,323
ffffffffc0200f7a:	00001517          	auipc	a0,0x1
ffffffffc0200f7e:	62e50513          	addi	a0,a0,1582 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200f82:	c2aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200f86:	00002697          	auipc	a3,0x2
ffffffffc0200f8a:	89268693          	addi	a3,a3,-1902 # ffffffffc0202818 <commands+0x8d0>
ffffffffc0200f8e:	00001617          	auipc	a2,0x1
ffffffffc0200f92:	60260613          	addi	a2,a2,1538 # ffffffffc0202590 <commands+0x648>
ffffffffc0200f96:	14200593          	li	a1,322
ffffffffc0200f9a:	00001517          	auipc	a0,0x1
ffffffffc0200f9e:	60e50513          	addi	a0,a0,1550 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200fa2:	c0aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200fa6:	00002697          	auipc	a3,0x2
ffffffffc0200faa:	85a68693          	addi	a3,a3,-1958 # ffffffffc0202800 <commands+0x8b8>
ffffffffc0200fae:	00001617          	auipc	a2,0x1
ffffffffc0200fb2:	5e260613          	addi	a2,a2,1506 # ffffffffc0202590 <commands+0x648>
ffffffffc0200fb6:	14100593          	li	a1,321
ffffffffc0200fba:	00001517          	auipc	a0,0x1
ffffffffc0200fbe:	5ee50513          	addi	a0,a0,1518 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200fc2:	beaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fc6:	00001697          	auipc	a3,0x1
ffffffffc0200fca:	7a268693          	addi	a3,a3,1954 # ffffffffc0202768 <commands+0x820>
ffffffffc0200fce:	00001617          	auipc	a2,0x1
ffffffffc0200fd2:	5c260613          	addi	a2,a2,1474 # ffffffffc0202590 <commands+0x648>
ffffffffc0200fd6:	13b00593          	li	a1,315
ffffffffc0200fda:	00001517          	auipc	a0,0x1
ffffffffc0200fde:	5ce50513          	addi	a0,a0,1486 # ffffffffc02025a8 <commands+0x660>
ffffffffc0200fe2:	bcaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageProperty(p0));
ffffffffc0200fe6:	00002697          	auipc	a3,0x2
ffffffffc0200fea:	80268693          	addi	a3,a3,-2046 # ffffffffc02027e8 <commands+0x8a0>
ffffffffc0200fee:	00001617          	auipc	a2,0x1
ffffffffc0200ff2:	5a260613          	addi	a2,a2,1442 # ffffffffc0202590 <commands+0x648>
ffffffffc0200ff6:	13600593          	li	a1,310
ffffffffc0200ffa:	00001517          	auipc	a0,0x1
ffffffffc0200ffe:	5ae50513          	addi	a0,a0,1454 # ffffffffc02025a8 <commands+0x660>
ffffffffc0201002:	baaff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201006:	00002697          	auipc	a3,0x2
ffffffffc020100a:	90268693          	addi	a3,a3,-1790 # ffffffffc0202908 <commands+0x9c0>
ffffffffc020100e:	00001617          	auipc	a2,0x1
ffffffffc0201012:	58260613          	addi	a2,a2,1410 # ffffffffc0202590 <commands+0x648>
ffffffffc0201016:	15400593          	li	a1,340
ffffffffc020101a:	00001517          	auipc	a0,0x1
ffffffffc020101e:	58e50513          	addi	a0,a0,1422 # ffffffffc02025a8 <commands+0x660>
ffffffffc0201022:	b8aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total == 0);
ffffffffc0201026:	00002697          	auipc	a3,0x2
ffffffffc020102a:	91268693          	addi	a3,a3,-1774 # ffffffffc0202938 <commands+0x9f0>
ffffffffc020102e:	00001617          	auipc	a2,0x1
ffffffffc0201032:	56260613          	addi	a2,a2,1378 # ffffffffc0202590 <commands+0x648>
ffffffffc0201036:	16400593          	li	a1,356
ffffffffc020103a:	00001517          	auipc	a0,0x1
ffffffffc020103e:	56e50513          	addi	a0,a0,1390 # ffffffffc02025a8 <commands+0x660>
ffffffffc0201042:	b6aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total == nr_free_pages());
ffffffffc0201046:	00001697          	auipc	a3,0x1
ffffffffc020104a:	57a68693          	addi	a3,a3,1402 # ffffffffc02025c0 <commands+0x678>
ffffffffc020104e:	00001617          	auipc	a2,0x1
ffffffffc0201052:	54260613          	addi	a2,a2,1346 # ffffffffc0202590 <commands+0x648>
ffffffffc0201056:	13000593          	li	a1,304
ffffffffc020105a:	00001517          	auipc	a0,0x1
ffffffffc020105e:	54e50513          	addi	a0,a0,1358 # ffffffffc02025a8 <commands+0x660>
ffffffffc0201062:	b4aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201066:	00001697          	auipc	a3,0x1
ffffffffc020106a:	59a68693          	addi	a3,a3,1434 # ffffffffc0202600 <commands+0x6b8>
ffffffffc020106e:	00001617          	auipc	a2,0x1
ffffffffc0201072:	52260613          	addi	a2,a2,1314 # ffffffffc0202590 <commands+0x648>
ffffffffc0201076:	0f200593          	li	a1,242
ffffffffc020107a:	00001517          	auipc	a0,0x1
ffffffffc020107e:	52e50513          	addi	a0,a0,1326 # ffffffffc02025a8 <commands+0x660>
ffffffffc0201082:	b2aff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201086 <default_free_pages>:
{
ffffffffc0201086:	1141                	addi	sp,sp,-16
ffffffffc0201088:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020108a:	18058063          	beqz	a1,ffffffffc020120a <default_free_pages+0x184>
    for (; p != base + n; p++)
ffffffffc020108e:	00259693          	slli	a3,a1,0x2
ffffffffc0201092:	96ae                	add	a3,a3,a1
ffffffffc0201094:	068e                	slli	a3,a3,0x3
ffffffffc0201096:	96aa                	add	a3,a3,a0
ffffffffc0201098:	02d50d63          	beq	a0,a3,ffffffffc02010d2 <default_free_pages+0x4c>
ffffffffc020109c:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020109e:	8b85                	andi	a5,a5,1
ffffffffc02010a0:	14079563          	bnez	a5,ffffffffc02011ea <default_free_pages+0x164>
ffffffffc02010a4:	651c                	ld	a5,8(a0)
ffffffffc02010a6:	8385                	srli	a5,a5,0x1
ffffffffc02010a8:	8b85                	andi	a5,a5,1
ffffffffc02010aa:	14079063          	bnez	a5,ffffffffc02011ea <default_free_pages+0x164>
ffffffffc02010ae:	87aa                	mv	a5,a0
ffffffffc02010b0:	a809                	j	ffffffffc02010c2 <default_free_pages+0x3c>
ffffffffc02010b2:	6798                	ld	a4,8(a5)
ffffffffc02010b4:	8b05                	andi	a4,a4,1
ffffffffc02010b6:	12071a63          	bnez	a4,ffffffffc02011ea <default_free_pages+0x164>
ffffffffc02010ba:	6798                	ld	a4,8(a5)
ffffffffc02010bc:	8b09                	andi	a4,a4,2
ffffffffc02010be:	12071663          	bnez	a4,ffffffffc02011ea <default_free_pages+0x164>
        p->flags = 0;
ffffffffc02010c2:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02010c6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02010ca:	02878793          	addi	a5,a5,40
ffffffffc02010ce:	fed792e3          	bne	a5,a3,ffffffffc02010b2 <default_free_pages+0x2c>
    base->property = n;
ffffffffc02010d2:	2581                	sext.w	a1,a1
ffffffffc02010d4:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02010d6:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02010da:	4789                	li	a5,2
ffffffffc02010dc:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02010e0:	00005697          	auipc	a3,0x5
ffffffffc02010e4:	36868693          	addi	a3,a3,872 # ffffffffc0206448 <free_area>
ffffffffc02010e8:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02010ea:	669c                	ld	a5,8(a3)
ffffffffc02010ec:	9db9                	addw	a1,a1,a4
ffffffffc02010ee:	00005717          	auipc	a4,0x5
ffffffffc02010f2:	36b72523          	sw	a1,874(a4) # ffffffffc0206458 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc02010f6:	08d78f63          	beq	a5,a3,ffffffffc0201194 <default_free_pages+0x10e>
            struct Page *page = le2page(le, page_link);
ffffffffc02010fa:	fe878713          	addi	a4,a5,-24
ffffffffc02010fe:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc0201100:	4801                	li	a6,0
ffffffffc0201102:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0201106:	00e56a63          	bltu	a0,a4,ffffffffc020111a <default_free_pages+0x94>
    return listelm->next;
ffffffffc020110a:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020110c:	02d70563          	beq	a4,a3,ffffffffc0201136 <default_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list)
ffffffffc0201110:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201112:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201116:	fee57ae3          	bleu	a4,a0,ffffffffc020110a <default_free_pages+0x84>
ffffffffc020111a:	00080663          	beqz	a6,ffffffffc0201126 <default_free_pages+0xa0>
ffffffffc020111e:	00005817          	auipc	a6,0x5
ffffffffc0201122:	32b83523          	sd	a1,810(a6) # ffffffffc0206448 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201126:	638c                	ld	a1,0(a5)
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next)
{
    // prev: 新节点 elm 的前一个节点。
    // next: 新节点 elm 的后一个节点。
    prev->next = next->prev = elm;
ffffffffc0201128:	e390                	sd	a2,0(a5)
ffffffffc020112a:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc020112c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020112e:	ed0c                	sd	a1,24(a0)
    if (le != &free_list)
ffffffffc0201130:	02d59163          	bne	a1,a3,ffffffffc0201152 <default_free_pages+0xcc>
ffffffffc0201134:	a091                	j	ffffffffc0201178 <default_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc0201136:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201138:	f114                	sd	a3,32(a0)
ffffffffc020113a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020113c:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020113e:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201140:	00d70563          	beq	a4,a3,ffffffffc020114a <default_free_pages+0xc4>
ffffffffc0201144:	4805                	li	a6,1
ffffffffc0201146:	87ba                	mv	a5,a4
ffffffffc0201148:	b7e9                	j	ffffffffc0201112 <default_free_pages+0x8c>
ffffffffc020114a:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020114c:	85be                	mv	a1,a5
    if (le != &free_list)
ffffffffc020114e:	02d78163          	beq	a5,a3,ffffffffc0201170 <default_free_pages+0xea>
        if (p + p->property == base)
ffffffffc0201152:	ff85a803          	lw	a6,-8(a1)
        p = le2page(le, page_link);
ffffffffc0201156:	fe858613          	addi	a2,a1,-24
        if (p + p->property == base)
ffffffffc020115a:	02081713          	slli	a4,a6,0x20
ffffffffc020115e:	9301                	srli	a4,a4,0x20
ffffffffc0201160:	00271793          	slli	a5,a4,0x2
ffffffffc0201164:	97ba                	add	a5,a5,a4
ffffffffc0201166:	078e                	slli	a5,a5,0x3
ffffffffc0201168:	97b2                	add	a5,a5,a2
ffffffffc020116a:	02f50e63          	beq	a0,a5,ffffffffc02011a6 <default_free_pages+0x120>
ffffffffc020116e:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201170:	fe878713          	addi	a4,a5,-24
ffffffffc0201174:	00d78d63          	beq	a5,a3,ffffffffc020118e <default_free_pages+0x108>
        if (base + base->property == p)
ffffffffc0201178:	490c                	lw	a1,16(a0)
ffffffffc020117a:	02059613          	slli	a2,a1,0x20
ffffffffc020117e:	9201                	srli	a2,a2,0x20
ffffffffc0201180:	00261693          	slli	a3,a2,0x2
ffffffffc0201184:	96b2                	add	a3,a3,a2
ffffffffc0201186:	068e                	slli	a3,a3,0x3
ffffffffc0201188:	96aa                	add	a3,a3,a0
ffffffffc020118a:	04d70063          	beq	a4,a3,ffffffffc02011ca <default_free_pages+0x144>
}
ffffffffc020118e:	60a2                	ld	ra,8(sp)
ffffffffc0201190:	0141                	addi	sp,sp,16
ffffffffc0201192:	8082                	ret
ffffffffc0201194:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201196:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020119a:	e398                	sd	a4,0(a5)
ffffffffc020119c:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020119e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02011a0:	ed1c                	sd	a5,24(a0)
}
ffffffffc02011a2:	0141                	addi	sp,sp,16
ffffffffc02011a4:	8082                	ret
            p->property += base->property;
ffffffffc02011a6:	491c                	lw	a5,16(a0)
ffffffffc02011a8:	0107883b          	addw	a6,a5,a6
ffffffffc02011ac:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02011b0:	57f5                	li	a5,-3
ffffffffc02011b2:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02011b6:	01853803          	ld	a6,24(a0)
ffffffffc02011ba:	7118                	ld	a4,32(a0)
            base = p;
ffffffffc02011bc:	8532                	mv	a0,a2
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next)
{
    prev->next = next;
ffffffffc02011be:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02011c2:	659c                	ld	a5,8(a1)
ffffffffc02011c4:	01073023          	sd	a6,0(a4)
ffffffffc02011c8:	b765                	j	ffffffffc0201170 <default_free_pages+0xea>
            base->property += p->property;
ffffffffc02011ca:	ff87a703          	lw	a4,-8(a5)
ffffffffc02011ce:	ff078693          	addi	a3,a5,-16
ffffffffc02011d2:	9db9                	addw	a1,a1,a4
ffffffffc02011d4:	c90c                	sw	a1,16(a0)
ffffffffc02011d6:	5775                	li	a4,-3
ffffffffc02011d8:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02011dc:	6398                	ld	a4,0(a5)
ffffffffc02011de:	679c                	ld	a5,8(a5)
}
ffffffffc02011e0:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02011e2:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02011e4:	e398                	sd	a4,0(a5)
ffffffffc02011e6:	0141                	addi	sp,sp,16
ffffffffc02011e8:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02011ea:	00001697          	auipc	a3,0x1
ffffffffc02011ee:	75e68693          	addi	a3,a3,1886 # ffffffffc0202948 <commands+0xa00>
ffffffffc02011f2:	00001617          	auipc	a2,0x1
ffffffffc02011f6:	39e60613          	addi	a2,a2,926 # ffffffffc0202590 <commands+0x648>
ffffffffc02011fa:	0ae00593          	li	a1,174
ffffffffc02011fe:	00001517          	auipc	a0,0x1
ffffffffc0201202:	3aa50513          	addi	a0,a0,938 # ffffffffc02025a8 <commands+0x660>
ffffffffc0201206:	9a6ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc020120a:	00001697          	auipc	a3,0x1
ffffffffc020120e:	76668693          	addi	a3,a3,1894 # ffffffffc0202970 <commands+0xa28>
ffffffffc0201212:	00001617          	auipc	a2,0x1
ffffffffc0201216:	37e60613          	addi	a2,a2,894 # ffffffffc0202590 <commands+0x648>
ffffffffc020121a:	0aa00593          	li	a1,170
ffffffffc020121e:	00001517          	auipc	a0,0x1
ffffffffc0201222:	38a50513          	addi	a0,a0,906 # ffffffffc02025a8 <commands+0x660>
ffffffffc0201226:	986ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020122a <default_alloc_pages>:
    assert(n > 0);
ffffffffc020122a:	cd51                	beqz	a0,ffffffffc02012c6 <default_alloc_pages+0x9c>
    if (n > nr_free)
ffffffffc020122c:	00005597          	auipc	a1,0x5
ffffffffc0201230:	21c58593          	addi	a1,a1,540 # ffffffffc0206448 <free_area>
ffffffffc0201234:	0105a803          	lw	a6,16(a1)
ffffffffc0201238:	862a                	mv	a2,a0
ffffffffc020123a:	02081793          	slli	a5,a6,0x20
ffffffffc020123e:	9381                	srli	a5,a5,0x20
ffffffffc0201240:	00a7ee63          	bltu	a5,a0,ffffffffc020125c <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201244:	87ae                	mv	a5,a1
ffffffffc0201246:	a801                	j	ffffffffc0201256 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201248:	ff87a703          	lw	a4,-8(a5)
ffffffffc020124c:	02071693          	slli	a3,a4,0x20
ffffffffc0201250:	9281                	srli	a3,a3,0x20
ffffffffc0201252:	00c6f763          	bleu	a2,a3,ffffffffc0201260 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201256:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201258:	feb798e3          	bne	a5,a1,ffffffffc0201248 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020125c:	4501                	li	a0,0
}
ffffffffc020125e:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc0201260:	fe878513          	addi	a0,a5,-24
    if (page != NULL) // 找到了要分配的页，获取这个块前面的链表条目，并从空闲列表中删除这个块。
ffffffffc0201264:	dd6d                	beqz	a0,ffffffffc020125e <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc0201266:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020126a:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc020126e:	00060e1b          	sext.w	t3,a2
ffffffffc0201272:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201276:	01133023          	sd	a7,0(t1)
        if (page->property > n) // 找到的空闲块比请求的大，它将被拆分为两部分
ffffffffc020127a:	02d67b63          	bleu	a3,a2,ffffffffc02012b0 <default_alloc_pages+0x86>
            struct Page *p = page + n;        // p指向第二部分的第一个页面
ffffffffc020127e:	00261693          	slli	a3,a2,0x2
ffffffffc0201282:	96b2                	add	a3,a3,a2
ffffffffc0201284:	068e                	slli	a3,a3,0x3
ffffffffc0201286:	96aa                	add	a3,a3,a0
            p->property = page->property - n; // 更新第二部分的空闲块大小
ffffffffc0201288:	41c7073b          	subw	a4,a4,t3
ffffffffc020128c:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020128e:	00868613          	addi	a2,a3,8
ffffffffc0201292:	4709                	li	a4,2
ffffffffc0201294:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201298:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));  // 将第二部分添加到空闲列表中
ffffffffc020129c:	01868613          	addi	a2,a3,24
    prev->next = next->prev = elm;
ffffffffc02012a0:	0105a803          	lw	a6,16(a1)
ffffffffc02012a4:	e310                	sd	a2,0(a4)
ffffffffc02012a6:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02012aa:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc02012ac:	0116bc23          	sd	a7,24(a3)
        nr_free -= n;
ffffffffc02012b0:	41c8083b          	subw	a6,a6,t3
ffffffffc02012b4:	00005717          	auipc	a4,0x5
ffffffffc02012b8:	1b072223          	sw	a6,420(a4) # ffffffffc0206458 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02012bc:	5775                	li	a4,-3
ffffffffc02012be:	17c1                	addi	a5,a5,-16
ffffffffc02012c0:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc02012c4:	8082                	ret
{
ffffffffc02012c6:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02012c8:	00001697          	auipc	a3,0x1
ffffffffc02012cc:	6a868693          	addi	a3,a3,1704 # ffffffffc0202970 <commands+0xa28>
ffffffffc02012d0:	00001617          	auipc	a2,0x1
ffffffffc02012d4:	2c060613          	addi	a2,a2,704 # ffffffffc0202590 <commands+0x648>
ffffffffc02012d8:	08300593          	li	a1,131
ffffffffc02012dc:	00001517          	auipc	a0,0x1
ffffffffc02012e0:	2cc50513          	addi	a0,a0,716 # ffffffffc02025a8 <commands+0x660>
{
ffffffffc02012e4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02012e6:	8c6ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02012ea <default_init_memmap>:
{
ffffffffc02012ea:	7179                	addi	sp,sp,-48
ffffffffc02012ec:	f406                	sd	ra,40(sp)
ffffffffc02012ee:	f022                	sd	s0,32(sp)
ffffffffc02012f0:	ec26                	sd	s1,24(sp)
ffffffffc02012f2:	e84a                	sd	s2,16(sp)
ffffffffc02012f4:	e44e                	sd	s3,8(sp)
ffffffffc02012f6:	e052                	sd	s4,0(sp)
    assert(n > 0);
ffffffffc02012f8:	12058563          	beqz	a1,ffffffffc0201422 <default_init_memmap+0x138>
ffffffffc02012fc:	892e                	mv	s2,a1
ffffffffc02012fe:	842a                	mv	s0,a0
    for (; p != base + 3; p++)
ffffffffc0201300:	07850a13          	addi	s4,a0,120
ffffffffc0201304:	84aa                	mv	s1,a0
        cprintf("p的虚拟地址: 0x%016lx.\n", (uintptr_t)p);
ffffffffc0201306:	00001997          	auipc	s3,0x1
ffffffffc020130a:	67298993          	addi	s3,s3,1650 # ffffffffc0202978 <commands+0xa30>
ffffffffc020130e:	85a6                	mv	a1,s1
ffffffffc0201310:	854e                	mv	a0,s3
    for (; p != base + 3; p++)
ffffffffc0201312:	02848493          	addi	s1,s1,40
        cprintf("p的虚拟地址: 0x%016lx.\n", (uintptr_t)p);
ffffffffc0201316:	da1fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    for (; p != base + 3; p++)
ffffffffc020131a:	ff449ae3          	bne	s1,s4,ffffffffc020130e <default_init_memmap+0x24>
    for (; p != base + n; p++)
ffffffffc020131e:	00291693          	slli	a3,s2,0x2
ffffffffc0201322:	96ca                	add	a3,a3,s2
ffffffffc0201324:	068e                	slli	a3,a3,0x3
ffffffffc0201326:	96a2                	add	a3,a3,s0
ffffffffc0201328:	02d40463          	beq	s0,a3,ffffffffc0201350 <default_init_memmap+0x66>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020132c:	6418                	ld	a4,8(s0)
        assert(PageReserved(p));
ffffffffc020132e:	87a2                	mv	a5,s0
ffffffffc0201330:	8b05                	andi	a4,a4,1
ffffffffc0201332:	e709                	bnez	a4,ffffffffc020133c <default_init_memmap+0x52>
ffffffffc0201334:	a0f9                	j	ffffffffc0201402 <default_init_memmap+0x118>
ffffffffc0201336:	6798                	ld	a4,8(a5)
ffffffffc0201338:	8b05                	andi	a4,a4,1
ffffffffc020133a:	c761                	beqz	a4,ffffffffc0201402 <default_init_memmap+0x118>
        p->flags = p->property = 0;
ffffffffc020133c:	0007a823          	sw	zero,16(a5)
ffffffffc0201340:	0007b423          	sd	zero,8(a5)
ffffffffc0201344:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201348:	02878793          	addi	a5,a5,40
ffffffffc020134c:	fed795e3          	bne	a5,a3,ffffffffc0201336 <default_init_memmap+0x4c>
    base->property = n;
ffffffffc0201350:	2901                	sext.w	s2,s2
ffffffffc0201352:	01242823          	sw	s2,16(s0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201356:	4789                	li	a5,2
ffffffffc0201358:	00840713          	addi	a4,s0,8
ffffffffc020135c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201360:	00005697          	auipc	a3,0x5
ffffffffc0201364:	0e868693          	addi	a3,a3,232 # ffffffffc0206448 <free_area>
ffffffffc0201368:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020136a:	669c                	ld	a5,8(a3)
ffffffffc020136c:	0127093b          	addw	s2,a4,s2
ffffffffc0201370:	00005717          	auipc	a4,0x5
ffffffffc0201374:	0f272423          	sw	s2,232(a4) # ffffffffc0206458 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc0201378:	04d78e63          	beq	a5,a3,ffffffffc02013d4 <default_init_memmap+0xea>
            struct Page *page = le2page(le, page_link); // le2page从给定的链表节点le获取到包含它的struct Page实例。
ffffffffc020137c:	fe878713          	addi	a4,a5,-24
ffffffffc0201380:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc0201382:	4501                	li	a0,0
ffffffffc0201384:	01840613          	addi	a2,s0,24
            if (base < page)                            // 找到了合适的位置，链表是排序的，便于后续搜索，插入要维持有序状态
ffffffffc0201388:	00e46a63          	bltu	s0,a4,ffffffffc020139c <default_init_memmap+0xb2>
    return listelm->next;
ffffffffc020138c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list) // 到了链表尾部，循环一轮的最后，直接添加
ffffffffc020138e:	02d70963          	beq	a4,a3,ffffffffc02013c0 <default_init_memmap+0xd6>
        while ((le = list_next(le)) != &free_list) // 遍历一轮链表
ffffffffc0201392:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link); // le2page从给定的链表节点le获取到包含它的struct Page实例。
ffffffffc0201394:	fe878713          	addi	a4,a5,-24
            if (base < page)                            // 找到了合适的位置，链表是排序的，便于后续搜索，插入要维持有序状态
ffffffffc0201398:	fee47ae3          	bleu	a4,s0,ffffffffc020138c <default_init_memmap+0xa2>
ffffffffc020139c:	c509                	beqz	a0,ffffffffc02013a6 <default_init_memmap+0xbc>
ffffffffc020139e:	00005717          	auipc	a4,0x5
ffffffffc02013a2:	0ab73523          	sd	a1,170(a4) # ffffffffc0206448 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02013a6:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02013a8:	e390                	sd	a2,0(a5)
}
ffffffffc02013aa:	70a2                	ld	ra,40(sp)
ffffffffc02013ac:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02013ae:	f01c                	sd	a5,32(s0)
    elm->prev = prev;
ffffffffc02013b0:	ec18                	sd	a4,24(s0)
ffffffffc02013b2:	7402                	ld	s0,32(sp)
ffffffffc02013b4:	64e2                	ld	s1,24(sp)
ffffffffc02013b6:	6942                	ld	s2,16(sp)
ffffffffc02013b8:	69a2                	ld	s3,8(sp)
ffffffffc02013ba:	6a02                	ld	s4,0(sp)
ffffffffc02013bc:	6145                	addi	sp,sp,48
ffffffffc02013be:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02013c0:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02013c2:	f014                	sd	a3,32(s0)
ffffffffc02013c4:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02013c6:	ec1c                	sd	a5,24(s0)
                list_add(le, &(base->page_link));
ffffffffc02013c8:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) // 遍历一轮链表
ffffffffc02013ca:	02d70363          	beq	a4,a3,ffffffffc02013f0 <default_init_memmap+0x106>
ffffffffc02013ce:	4505                	li	a0,1
ffffffffc02013d0:	87ba                	mv	a5,a4
ffffffffc02013d2:	b7c9                	j	ffffffffc0201394 <default_init_memmap+0xaa>
        list_add(&free_list, &(base->page_link));
ffffffffc02013d4:	01840713          	addi	a4,s0,24
    elm->next = next;
ffffffffc02013d8:	f01c                	sd	a5,32(s0)
    elm->prev = prev;
ffffffffc02013da:	ec1c                	sd	a5,24(s0)
}
ffffffffc02013dc:	70a2                	ld	ra,40(sp)
ffffffffc02013de:	7402                	ld	s0,32(sp)
    prev->next = next->prev = elm;
ffffffffc02013e0:	e398                	sd	a4,0(a5)
ffffffffc02013e2:	e798                	sd	a4,8(a5)
ffffffffc02013e4:	64e2                	ld	s1,24(sp)
ffffffffc02013e6:	6942                	ld	s2,16(sp)
ffffffffc02013e8:	69a2                	ld	s3,8(sp)
ffffffffc02013ea:	6a02                	ld	s4,0(sp)
ffffffffc02013ec:	6145                	addi	sp,sp,48
ffffffffc02013ee:	8082                	ret
ffffffffc02013f0:	70a2                	ld	ra,40(sp)
ffffffffc02013f2:	7402                	ld	s0,32(sp)
ffffffffc02013f4:	e290                	sd	a2,0(a3)
ffffffffc02013f6:	64e2                	ld	s1,24(sp)
ffffffffc02013f8:	6942                	ld	s2,16(sp)
ffffffffc02013fa:	69a2                	ld	s3,8(sp)
ffffffffc02013fc:	6a02                	ld	s4,0(sp)
ffffffffc02013fe:	6145                	addi	sp,sp,48
ffffffffc0201400:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201402:	00001697          	auipc	a3,0x1
ffffffffc0201406:	59668693          	addi	a3,a3,1430 # ffffffffc0202998 <commands+0xa50>
ffffffffc020140a:	00001617          	auipc	a2,0x1
ffffffffc020140e:	18660613          	addi	a2,a2,390 # ffffffffc0202590 <commands+0x648>
ffffffffc0201412:	05900593          	li	a1,89
ffffffffc0201416:	00001517          	auipc	a0,0x1
ffffffffc020141a:	19250513          	addi	a0,a0,402 # ffffffffc02025a8 <commands+0x660>
ffffffffc020141e:	f8ffe0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0201422:	00001697          	auipc	a3,0x1
ffffffffc0201426:	54e68693          	addi	a3,a3,1358 # ffffffffc0202970 <commands+0xa28>
ffffffffc020142a:	00001617          	auipc	a2,0x1
ffffffffc020142e:	16660613          	addi	a2,a2,358 # ffffffffc0202590 <commands+0x648>
ffffffffc0201432:	04a00593          	li	a1,74
ffffffffc0201436:	00001517          	auipc	a0,0x1
ffffffffc020143a:	17250513          	addi	a0,a0,370 # ffffffffc02025a8 <commands+0x660>
ffffffffc020143e:	f6ffe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201442 <pa2page.part.0>:

static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0201442:	1141                	addi	sp,sp,-16
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
ffffffffc0201444:	00001617          	auipc	a2,0x1
ffffffffc0201448:	5b460613          	addi	a2,a2,1460 # ffffffffc02029f8 <default_pmm_manager+0x50>
ffffffffc020144c:	06b00593          	li	a1,107
ffffffffc0201450:	00001517          	auipc	a0,0x1
ffffffffc0201454:	5c850513          	addi	a0,a0,1480 # ffffffffc0202a18 <default_pmm_manager+0x70>
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0201458:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020145a:	f53fe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020145e <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020145e:	100027f3          	csrr	a5,sstatus
ffffffffc0201462:	8b89                	andi	a5,a5,2
ffffffffc0201464:	eb89                	bnez	a5,ffffffffc0201476 <alloc_pages+0x18>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201466:	00005797          	auipc	a5,0x5
ffffffffc020146a:	00278793          	addi	a5,a5,2 # ffffffffc0206468 <pmm_manager>
ffffffffc020146e:	639c                	ld	a5,0(a5)
ffffffffc0201470:	0187b303          	ld	t1,24(a5)
ffffffffc0201474:	8302                	jr	t1
{
ffffffffc0201476:	1141                	addi	sp,sp,-16
ffffffffc0201478:	e406                	sd	ra,8(sp)
ffffffffc020147a:	e022                	sd	s0,0(sp)
ffffffffc020147c:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020147e:	fe7fe0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201482:	00005797          	auipc	a5,0x5
ffffffffc0201486:	fe678793          	addi	a5,a5,-26 # ffffffffc0206468 <pmm_manager>
ffffffffc020148a:	639c                	ld	a5,0(a5)
ffffffffc020148c:	8522                	mv	a0,s0
ffffffffc020148e:	6f9c                	ld	a5,24(a5)
ffffffffc0201490:	9782                	jalr	a5
ffffffffc0201492:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201494:	fcbfe0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201498:	8522                	mv	a0,s0
ffffffffc020149a:	60a2                	ld	ra,8(sp)
ffffffffc020149c:	6402                	ld	s0,0(sp)
ffffffffc020149e:	0141                	addi	sp,sp,16
ffffffffc02014a0:	8082                	ret

ffffffffc02014a2 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02014a2:	100027f3          	csrr	a5,sstatus
ffffffffc02014a6:	8b89                	andi	a5,a5,2
ffffffffc02014a8:	eb89                	bnez	a5,ffffffffc02014ba <free_pages+0x18>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02014aa:	00005797          	auipc	a5,0x5
ffffffffc02014ae:	fbe78793          	addi	a5,a5,-66 # ffffffffc0206468 <pmm_manager>
ffffffffc02014b2:	639c                	ld	a5,0(a5)
ffffffffc02014b4:	0207b303          	ld	t1,32(a5)
ffffffffc02014b8:	8302                	jr	t1
{
ffffffffc02014ba:	1101                	addi	sp,sp,-32
ffffffffc02014bc:	ec06                	sd	ra,24(sp)
ffffffffc02014be:	e822                	sd	s0,16(sp)
ffffffffc02014c0:	e426                	sd	s1,8(sp)
ffffffffc02014c2:	842a                	mv	s0,a0
ffffffffc02014c4:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02014c6:	f9ffe0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02014ca:	00005797          	auipc	a5,0x5
ffffffffc02014ce:	f9e78793          	addi	a5,a5,-98 # ffffffffc0206468 <pmm_manager>
ffffffffc02014d2:	639c                	ld	a5,0(a5)
ffffffffc02014d4:	85a6                	mv	a1,s1
ffffffffc02014d6:	8522                	mv	a0,s0
ffffffffc02014d8:	739c                	ld	a5,32(a5)
ffffffffc02014da:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02014dc:	6442                	ld	s0,16(sp)
ffffffffc02014de:	60e2                	ld	ra,24(sp)
ffffffffc02014e0:	64a2                	ld	s1,8(sp)
ffffffffc02014e2:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02014e4:	f7bfe06f          	j	ffffffffc020045e <intr_enable>

ffffffffc02014e8 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02014e8:	100027f3          	csrr	a5,sstatus
ffffffffc02014ec:	8b89                	andi	a5,a5,2
ffffffffc02014ee:	eb89                	bnez	a5,ffffffffc0201500 <nr_free_pages+0x18>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02014f0:	00005797          	auipc	a5,0x5
ffffffffc02014f4:	f7878793          	addi	a5,a5,-136 # ffffffffc0206468 <pmm_manager>
ffffffffc02014f8:	639c                	ld	a5,0(a5)
ffffffffc02014fa:	0287b303          	ld	t1,40(a5)
ffffffffc02014fe:	8302                	jr	t1
{
ffffffffc0201500:	1141                	addi	sp,sp,-16
ffffffffc0201502:	e406                	sd	ra,8(sp)
ffffffffc0201504:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201506:	f5ffe0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020150a:	00005797          	auipc	a5,0x5
ffffffffc020150e:	f5e78793          	addi	a5,a5,-162 # ffffffffc0206468 <pmm_manager>
ffffffffc0201512:	639c                	ld	a5,0(a5)
ffffffffc0201514:	779c                	ld	a5,40(a5)
ffffffffc0201516:	9782                	jalr	a5
ffffffffc0201518:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020151a:	f45fe0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020151e:	8522                	mv	a0,s0
ffffffffc0201520:	60a2                	ld	ra,8(sp)
ffffffffc0201522:	6402                	ld	s0,0(sp)
ffffffffc0201524:	0141                	addi	sp,sp,16
ffffffffc0201526:	8082                	ret

ffffffffc0201528 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201528:	00001797          	auipc	a5,0x1
ffffffffc020152c:	48078793          	addi	a5,a5,1152 # ffffffffc02029a8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201530:	638c                	ld	a1,0(a5)
    // 0x8000-0x7cb9=0x0347个不可用，这些页存的是结构体page的数据
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void)
{
ffffffffc0201532:	715d                	addi	sp,sp,-80
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201534:	00001517          	auipc	a0,0x1
ffffffffc0201538:	4f450513          	addi	a0,a0,1268 # ffffffffc0202a28 <default_pmm_manager+0x80>
{
ffffffffc020153c:	e486                	sd	ra,72(sp)
ffffffffc020153e:	e0a2                	sd	s0,64(sp)
ffffffffc0201540:	f052                	sd	s4,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201542:	00005717          	auipc	a4,0x5
ffffffffc0201546:	f2f73323          	sd	a5,-218(a4) # ffffffffc0206468 <pmm_manager>
{
ffffffffc020154a:	fc26                	sd	s1,56(sp)
ffffffffc020154c:	f84a                	sd	s2,48(sp)
ffffffffc020154e:	f44e                	sd	s3,40(sp)
ffffffffc0201550:	ec56                	sd	s5,24(sp)
ffffffffc0201552:	e85a                	sd	s6,16(sp)
ffffffffc0201554:	e45e                	sd	s7,8(sp)
ffffffffc0201556:	e062                	sd	s8,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201558:	00005a17          	auipc	s4,0x5
ffffffffc020155c:	f10a0a13          	addi	s4,s4,-240 # ffffffffc0206468 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201560:	b57fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pmm_manager->init();
ffffffffc0201564:	000a3783          	ld	a5,0(s4)
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201568:	4445                	li	s0,17
ffffffffc020156a:	046e                	slli	s0,s0,0x1b
    pmm_manager->init();
ffffffffc020156c:	679c                	ld	a5,8(a5)
ffffffffc020156e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移:
ffffffffc0201570:	57f5                	li	a5,-3
ffffffffc0201572:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201574:	00001517          	auipc	a0,0x1
ffffffffc0201578:	4cc50513          	addi	a0,a0,1228 # ffffffffc0202a40 <default_pmm_manager+0x98>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移:
ffffffffc020157c:	00005717          	auipc	a4,0x5
ffffffffc0201580:	eef73a23          	sd	a5,-268(a4) # ffffffffc0206470 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc0201584:	b33fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201588:	40100613          	li	a2,1025
ffffffffc020158c:	fff40693          	addi	a3,s0,-1
ffffffffc0201590:	0656                	slli	a2,a2,0x15
ffffffffc0201592:	07e005b7          	lui	a1,0x7e00
ffffffffc0201596:	00001517          	auipc	a0,0x1
ffffffffc020159a:	4c250513          	addi	a0,a0,1218 # ffffffffc0202a58 <default_pmm_manager+0xb0>
ffffffffc020159e:	b19fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("maxpa: 0x%016lx.\n", maxpa); // test point
ffffffffc02015a2:	85a2                	mv	a1,s0
ffffffffc02015a4:	00001517          	auipc	a0,0x1
ffffffffc02015a8:	4e450513          	addi	a0,a0,1252 # ffffffffc0202a88 <default_pmm_manager+0xe0>
ffffffffc02015ac:	b0bfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02015b0:	000887b7          	lui	a5,0x88
    cprintf("npage: 0x%016lx.\n", npage); // test point
ffffffffc02015b4:	000885b7          	lui	a1,0x88
ffffffffc02015b8:	00001517          	auipc	a0,0x1
ffffffffc02015bc:	4e850513          	addi	a0,a0,1256 # ffffffffc0202aa0 <default_pmm_manager+0xf8>
    npage = maxpa / PGSIZE;
ffffffffc02015c0:	00005717          	auipc	a4,0x5
ffffffffc02015c4:	e6f73423          	sd	a5,-408(a4) # ffffffffc0206428 <npage>
    cprintf("npage: 0x%016lx.\n", npage); // test point
ffffffffc02015c8:	aeffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("nbase: 0x%016lx.\n", nbase); // test point
ffffffffc02015cc:	000805b7          	lui	a1,0x80
ffffffffc02015d0:	00001517          	auipc	a0,0x1
ffffffffc02015d4:	4e850513          	addi	a0,a0,1256 # ffffffffc0202ab8 <default_pmm_manager+0x110>
ffffffffc02015d8:	adffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02015dc:	00006697          	auipc	a3,0x6
ffffffffc02015e0:	ea368693          	addi	a3,a3,-349 # ffffffffc020747f <end+0xfff>
ffffffffc02015e4:	75fd                	lui	a1,0xfffff
ffffffffc02015e6:	8eed                	and	a3,a3,a1
ffffffffc02015e8:	00005797          	auipc	a5,0x5
ffffffffc02015ec:	e8d7b823          	sd	a3,-368(a5) # ffffffffc0206478 <pages>
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc02015f0:	c02007b7          	lui	a5,0xc0200
ffffffffc02015f4:	24f6ec63          	bltu	a3,a5,ffffffffc020184c <pmm_init+0x324>
ffffffffc02015f8:	00005997          	auipc	s3,0x5
ffffffffc02015fc:	e7898993          	addi	s3,s3,-392 # ffffffffc0206470 <va_pa_offset>
ffffffffc0201600:	0009b583          	ld	a1,0(s3)
ffffffffc0201604:	00001517          	auipc	a0,0x1
ffffffffc0201608:	50450513          	addi	a0,a0,1284 # ffffffffc0202b08 <default_pmm_manager+0x160>
ffffffffc020160c:	00005917          	auipc	s2,0x5
ffffffffc0201610:	e1c90913          	addi	s2,s2,-484 # ffffffffc0206428 <npage>
ffffffffc0201614:	40b685b3          	sub	a1,a3,a1
ffffffffc0201618:	a9ffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020161c:	00093703          	ld	a4,0(s2)
ffffffffc0201620:	000807b7          	lui	a5,0x80
ffffffffc0201624:	00005a97          	auipc	s5,0x5
ffffffffc0201628:	e54a8a93          	addi	s5,s5,-428 # ffffffffc0206478 <pages>
ffffffffc020162c:	02f70963          	beq	a4,a5,ffffffffc020165e <pmm_init+0x136>
ffffffffc0201630:	4681                	li	a3,0
ffffffffc0201632:	4701                	li	a4,0
ffffffffc0201634:	00005a97          	auipc	s5,0x5
ffffffffc0201638:	e44a8a93          	addi	s5,s5,-444 # ffffffffc0206478 <pages>
ffffffffc020163c:	4585                	li	a1,1
ffffffffc020163e:	fff80637          	lui	a2,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201642:	000ab783          	ld	a5,0(s5)
ffffffffc0201646:	97b6                	add	a5,a5,a3
ffffffffc0201648:	07a1                	addi	a5,a5,8
ffffffffc020164a:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020164e:	00093783          	ld	a5,0(s2)
ffffffffc0201652:	0705                	addi	a4,a4,1
ffffffffc0201654:	02868693          	addi	a3,a3,40
ffffffffc0201658:	97b2                	add	a5,a5,a2
ffffffffc020165a:	fef764e3          	bltu	a4,a5,ffffffffc0201642 <pmm_init+0x11a>
ffffffffc020165e:	4481                	li	s1,0
    for (size_t i = 0; i < 5; i++)
ffffffffc0201660:	4401                	li	s0,0
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201662:	c0200b37          	lui	s6,0xc0200
ffffffffc0201666:	00001c17          	auipc	s8,0x1
ffffffffc020166a:	4cac0c13          	addi	s8,s8,1226 # ffffffffc0202b30 <default_pmm_manager+0x188>
    for (size_t i = 0; i < 5; i++)
ffffffffc020166e:	4b95                	li	s7,5
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201670:	000ab683          	ld	a3,0(s5)
ffffffffc0201674:	96a6                	add	a3,a3,s1
ffffffffc0201676:	1966e563          	bltu	a3,s6,ffffffffc0201800 <pmm_init+0x2d8>
ffffffffc020167a:	0009b603          	ld	a2,0(s3)
ffffffffc020167e:	85a2                	mv	a1,s0
ffffffffc0201680:	8562                	mv	a0,s8
ffffffffc0201682:	40c68633          	sub	a2,a3,a2
    for (size_t i = 0; i < 5; i++)
ffffffffc0201686:	0405                	addi	s0,s0,1
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201688:	a2ffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020168c:	02848493          	addi	s1,s1,40
    for (size_t i = 0; i < 5; i++)
ffffffffc0201690:	ff7410e3          	bne	s0,s7,ffffffffc0201670 <pmm_init+0x148>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc0201694:	00093783          	ld	a5,0(s2)
ffffffffc0201698:	000ab403          	ld	s0,0(s5)
ffffffffc020169c:	00279693          	slli	a3,a5,0x2
ffffffffc02016a0:	96be                	add	a3,a3,a5
ffffffffc02016a2:	068e                	slli	a3,a3,0x3
ffffffffc02016a4:	9436                	add	s0,s0,a3
ffffffffc02016a6:	fec006b7          	lui	a3,0xfec00
ffffffffc02016aa:	9436                	add	s0,s0,a3
ffffffffc02016ac:	1b646c63          	bltu	s0,s6,ffffffffc0201864 <pmm_init+0x33c>
ffffffffc02016b0:	0009b683          	ld	a3,0(s3)
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc02016b4:	02800593          	li	a1,40
ffffffffc02016b8:	00001517          	auipc	a0,0x1
ffffffffc02016bc:	4a050513          	addi	a0,a0,1184 # ffffffffc0202b58 <default_pmm_manager+0x1b0>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02016c0:	6485                	lui	s1,0x1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc02016c2:	8c15                	sub	s0,s0,a3
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02016c4:	14fd                	addi	s1,s1,-1
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc02016c6:	9f1fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc02016ca:	85a2                	mv	a1,s0
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02016cc:	94a2                	add	s1,s1,s0
ffffffffc02016ce:	7b7d                	lui	s6,0xfffff
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc02016d0:	00001517          	auipc	a0,0x1
ffffffffc02016d4:	4a850513          	addi	a0,a0,1192 # ffffffffc0202b78 <default_pmm_manager+0x1d0>
ffffffffc02016d8:	9dffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc02016dc:	0164fb33          	and	s6,s1,s6
    cprintf("mem_begin: 0x%016lx.\n", mem_begin); // test point
ffffffffc02016e0:	85da                	mv	a1,s6
ffffffffc02016e2:	00001517          	auipc	a0,0x1
ffffffffc02016e6:	4ae50513          	addi	a0,a0,1198 # ffffffffc0202b90 <default_pmm_manager+0x1e8>
ffffffffc02016ea:	9cdfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc02016ee:	4bc5                	li	s7,17
ffffffffc02016f0:	01bb9593          	slli	a1,s7,0x1b
ffffffffc02016f4:	00001517          	auipc	a0,0x1
ffffffffc02016f8:	4b450513          	addi	a0,a0,1204 # ffffffffc0202ba8 <default_pmm_manager+0x200>
    if (freemem < mem_end)
ffffffffc02016fc:	0bee                	slli	s7,s7,0x1b
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc02016fe:	9b9fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (freemem < mem_end)
ffffffffc0201702:	0d746763          	bltu	s0,s7,ffffffffc02017d0 <pmm_init+0x2a8>
    if (PPN(pa) >= npage) {
ffffffffc0201706:	00093783          	ld	a5,0(s2)
ffffffffc020170a:	00cb5493          	srli	s1,s6,0xc
ffffffffc020170e:	10f4f563          	bleu	a5,s1,ffffffffc0201818 <pmm_init+0x2f0>
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201712:	fff80437          	lui	s0,0xfff80
ffffffffc0201716:	008486b3          	add	a3,s1,s0
ffffffffc020171a:	00269413          	slli	s0,a3,0x2
ffffffffc020171e:	000ab583          	ld	a1,0(s5)
ffffffffc0201722:	9436                	add	s0,s0,a3
ffffffffc0201724:	040e                	slli	s0,s0,0x3
    cprintf("mem_begin对应的页结构记录(结构体page)虚拟地址: 0x%016lx.\n", pa2page(mem_begin));        // test point
ffffffffc0201726:	95a2                	add	a1,a1,s0
ffffffffc0201728:	00001517          	auipc	a0,0x1
ffffffffc020172c:	49850513          	addi	a0,a0,1176 # ffffffffc0202bc0 <default_pmm_manager+0x218>
ffffffffc0201730:	987fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (PPN(pa) >= npage) {
ffffffffc0201734:	00093783          	ld	a5,0(s2)
ffffffffc0201738:	0ef4f063          	bleu	a5,s1,ffffffffc0201818 <pmm_init+0x2f0>
    return &pages[PPN(pa) - nbase];
ffffffffc020173c:	000ab683          	ld	a3,0(s5)
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc0201740:	c02004b7          	lui	s1,0xc0200
ffffffffc0201744:	96a2                	add	a3,a3,s0
ffffffffc0201746:	0c96eb63          	bltu	a3,s1,ffffffffc020181c <pmm_init+0x2f4>
ffffffffc020174a:	0009b583          	ld	a1,0(s3)
ffffffffc020174e:	00001517          	auipc	a0,0x1
ffffffffc0201752:	4c250513          	addi	a0,a0,1218 # ffffffffc0202c10 <default_pmm_manager+0x268>
ffffffffc0201756:	40b685b3          	sub	a1,a3,a1
ffffffffc020175a:	95dfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("可用空闲页的数目: 0x%016lx.\n", (mem_end - mem_begin) / PGSIZE); // test point
ffffffffc020175e:	45c5                	li	a1,17
ffffffffc0201760:	05ee                	slli	a1,a1,0x1b
ffffffffc0201762:	416585b3          	sub	a1,a1,s6
ffffffffc0201766:	81b1                	srli	a1,a1,0xc
ffffffffc0201768:	00001517          	auipc	a0,0x1
ffffffffc020176c:	4f850513          	addi	a0,a0,1272 # ffffffffc0202c60 <default_pmm_manager+0x2b8>
ffffffffc0201770:	947fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201774:	000a3783          	ld	a5,0(s4)
ffffffffc0201778:	7b9c                	ld	a5,48(a5)
ffffffffc020177a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020177c:	00001517          	auipc	a0,0x1
ffffffffc0201780:	50c50513          	addi	a0,a0,1292 # ffffffffc0202c88 <default_pmm_manager+0x2e0>
ffffffffc0201784:	933fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    satp_virtual = (pte_t *)boot_page_table_sv39;
ffffffffc0201788:	00004697          	auipc	a3,0x4
ffffffffc020178c:	87868693          	addi	a3,a3,-1928 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201790:	00005797          	auipc	a5,0x5
ffffffffc0201794:	cad7b023          	sd	a3,-864(a5) # ffffffffc0206430 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201798:	0896ee63          	bltu	a3,s1,ffffffffc0201834 <pmm_init+0x30c>
ffffffffc020179c:	0009b783          	ld	a5,0(s3)
}
ffffffffc02017a0:	6406                	ld	s0,64(sp)
ffffffffc02017a2:	60a6                	ld	ra,72(sp)
ffffffffc02017a4:	74e2                	ld	s1,56(sp)
ffffffffc02017a6:	7942                	ld	s2,48(sp)
ffffffffc02017a8:	79a2                	ld	s3,40(sp)
ffffffffc02017aa:	7a02                	ld	s4,32(sp)
ffffffffc02017ac:	6ae2                	ld	s5,24(sp)
ffffffffc02017ae:	6b42                	ld	s6,16(sp)
ffffffffc02017b0:	6ba2                	ld	s7,8(sp)
ffffffffc02017b2:	6c02                	ld	s8,0(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02017b4:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc02017b6:	8e9d                	sub	a3,a3,a5
ffffffffc02017b8:	00005797          	auipc	a5,0x5
ffffffffc02017bc:	cad7b423          	sd	a3,-856(a5) # ffffffffc0206460 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02017c0:	00001517          	auipc	a0,0x1
ffffffffc02017c4:	4e850513          	addi	a0,a0,1256 # ffffffffc0202ca8 <default_pmm_manager+0x300>
ffffffffc02017c8:	8636                	mv	a2,a3
}
ffffffffc02017ca:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02017cc:	8ebfe06f          	j	ffffffffc02000b6 <cprintf>
    if (PPN(pa) >= npage) {
ffffffffc02017d0:	00093783          	ld	a5,0(s2)
ffffffffc02017d4:	80b1                	srli	s1,s1,0xc
ffffffffc02017d6:	04f4f163          	bleu	a5,s1,ffffffffc0201818 <pmm_init+0x2f0>
    pmm_manager->init_memmap(base, n);
ffffffffc02017da:	000a3703          	ld	a4,0(s4)
    return &pages[PPN(pa) - nbase];
ffffffffc02017de:	fff80537          	lui	a0,0xfff80
ffffffffc02017e2:	94aa                	add	s1,s1,a0
ffffffffc02017e4:	00249793          	slli	a5,s1,0x2
ffffffffc02017e8:	000ab503          	ld	a0,0(s5)
ffffffffc02017ec:	94be                	add	s1,s1,a5
ffffffffc02017ee:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02017f0:	416b8bb3          	sub	s7,s7,s6
ffffffffc02017f4:	048e                	slli	s1,s1,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02017f6:	00cbd593          	srli	a1,s7,0xc
ffffffffc02017fa:	9526                	add	a0,a0,s1
ffffffffc02017fc:	9782                	jalr	a5
ffffffffc02017fe:	b721                	j	ffffffffc0201706 <pmm_init+0x1de>
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201800:	00001617          	auipc	a2,0x1
ffffffffc0201804:	2d060613          	addi	a2,a2,720 # ffffffffc0202ad0 <default_pmm_manager+0x128>
ffffffffc0201808:	08800593          	li	a1,136
ffffffffc020180c:	00001517          	auipc	a0,0x1
ffffffffc0201810:	2ec50513          	addi	a0,a0,748 # ffffffffc0202af8 <default_pmm_manager+0x150>
ffffffffc0201814:	b99fe0ef          	jal	ra,ffffffffc02003ac <__panic>
ffffffffc0201818:	c2bff0ef          	jal	ra,ffffffffc0201442 <pa2page.part.0>
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc020181c:	00001617          	auipc	a2,0x1
ffffffffc0201820:	2b460613          	addi	a2,a2,692 # ffffffffc0202ad0 <default_pmm_manager+0x128>
ffffffffc0201824:	09c00593          	li	a1,156
ffffffffc0201828:	00001517          	auipc	a0,0x1
ffffffffc020182c:	2d050513          	addi	a0,a0,720 # ffffffffc0202af8 <default_pmm_manager+0x150>
ffffffffc0201830:	b7dfe0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201834:	00001617          	auipc	a2,0x1
ffffffffc0201838:	29c60613          	addi	a2,a2,668 # ffffffffc0202ad0 <default_pmm_manager+0x128>
ffffffffc020183c:	0b700593          	li	a1,183
ffffffffc0201840:	00001517          	auipc	a0,0x1
ffffffffc0201844:	2b850513          	addi	a0,a0,696 # ffffffffc0202af8 <default_pmm_manager+0x150>
ffffffffc0201848:	b65fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc020184c:	00001617          	auipc	a2,0x1
ffffffffc0201850:	28460613          	addi	a2,a2,644 # ffffffffc0202ad0 <default_pmm_manager+0x128>
ffffffffc0201854:	07c00593          	li	a1,124
ffffffffc0201858:	00001517          	auipc	a0,0x1
ffffffffc020185c:	2a050513          	addi	a0,a0,672 # ffffffffc0202af8 <default_pmm_manager+0x150>
ffffffffc0201860:	b4dfe0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc0201864:	86a2                	mv	a3,s0
ffffffffc0201866:	00001617          	auipc	a2,0x1
ffffffffc020186a:	26a60613          	addi	a2,a2,618 # ffffffffc0202ad0 <default_pmm_manager+0x128>
ffffffffc020186e:	08e00593          	li	a1,142
ffffffffc0201872:	00001517          	auipc	a0,0x1
ffffffffc0201876:	28650513          	addi	a0,a0,646 # ffffffffc0202af8 <default_pmm_manager+0x150>
ffffffffc020187a:	b33fe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020187e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020187e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201882:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201884:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201888:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020188a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020188e:	f022                	sd	s0,32(sp)
ffffffffc0201890:	ec26                	sd	s1,24(sp)
ffffffffc0201892:	e84a                	sd	s2,16(sp)
ffffffffc0201894:	f406                	sd	ra,40(sp)
ffffffffc0201896:	e44e                	sd	s3,8(sp)
ffffffffc0201898:	84aa                	mv	s1,a0
ffffffffc020189a:	892e                	mv	s2,a1
ffffffffc020189c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02018a0:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc02018a2:	03067e63          	bleu	a6,a2,ffffffffc02018de <printnum+0x60>
ffffffffc02018a6:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02018a8:	00805763          	blez	s0,ffffffffc02018b6 <printnum+0x38>
ffffffffc02018ac:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02018ae:	85ca                	mv	a1,s2
ffffffffc02018b0:	854e                	mv	a0,s3
ffffffffc02018b2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02018b4:	fc65                	bnez	s0,ffffffffc02018ac <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02018b6:	1a02                	slli	s4,s4,0x20
ffffffffc02018b8:	020a5a13          	srli	s4,s4,0x20
ffffffffc02018bc:	00001797          	auipc	a5,0x1
ffffffffc02018c0:	5bc78793          	addi	a5,a5,1468 # ffffffffc0202e78 <error_string+0x38>
ffffffffc02018c4:	9a3e                	add	s4,s4,a5
}
ffffffffc02018c6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02018c8:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02018cc:	70a2                	ld	ra,40(sp)
ffffffffc02018ce:	69a2                	ld	s3,8(sp)
ffffffffc02018d0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02018d2:	85ca                	mv	a1,s2
ffffffffc02018d4:	8326                	mv	t1,s1
}
ffffffffc02018d6:	6942                	ld	s2,16(sp)
ffffffffc02018d8:	64e2                	ld	s1,24(sp)
ffffffffc02018da:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02018dc:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02018de:	03065633          	divu	a2,a2,a6
ffffffffc02018e2:	8722                	mv	a4,s0
ffffffffc02018e4:	f9bff0ef          	jal	ra,ffffffffc020187e <printnum>
ffffffffc02018e8:	b7f9                	j	ffffffffc02018b6 <printnum+0x38>

ffffffffc02018ea <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02018ea:	7119                	addi	sp,sp,-128
ffffffffc02018ec:	f4a6                	sd	s1,104(sp)
ffffffffc02018ee:	f0ca                	sd	s2,96(sp)
ffffffffc02018f0:	e8d2                	sd	s4,80(sp)
ffffffffc02018f2:	e4d6                	sd	s5,72(sp)
ffffffffc02018f4:	e0da                	sd	s6,64(sp)
ffffffffc02018f6:	fc5e                	sd	s7,56(sp)
ffffffffc02018f8:	f862                	sd	s8,48(sp)
ffffffffc02018fa:	f06a                	sd	s10,32(sp)
ffffffffc02018fc:	fc86                	sd	ra,120(sp)
ffffffffc02018fe:	f8a2                	sd	s0,112(sp)
ffffffffc0201900:	ecce                	sd	s3,88(sp)
ffffffffc0201902:	f466                	sd	s9,40(sp)
ffffffffc0201904:	ec6e                	sd	s11,24(sp)
ffffffffc0201906:	892a                	mv	s2,a0
ffffffffc0201908:	84ae                	mv	s1,a1
ffffffffc020190a:	8d32                	mv	s10,a2
ffffffffc020190c:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020190e:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201910:	00001a17          	auipc	s4,0x1
ffffffffc0201914:	3d8a0a13          	addi	s4,s4,984 # ffffffffc0202ce8 <default_pmm_manager+0x340>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201918:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020191c:	00001c17          	auipc	s8,0x1
ffffffffc0201920:	524c0c13          	addi	s8,s8,1316 # ffffffffc0202e40 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201924:	000d4503          	lbu	a0,0(s10)
ffffffffc0201928:	02500793          	li	a5,37
ffffffffc020192c:	001d0413          	addi	s0,s10,1
ffffffffc0201930:	00f50e63          	beq	a0,a5,ffffffffc020194c <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0201934:	c521                	beqz	a0,ffffffffc020197c <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201936:	02500993          	li	s3,37
ffffffffc020193a:	a011                	j	ffffffffc020193e <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc020193c:	c121                	beqz	a0,ffffffffc020197c <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc020193e:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201940:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201942:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201944:	fff44503          	lbu	a0,-1(s0) # fffffffffff7ffff <end+0x3fd79b7f>
ffffffffc0201948:	ff351ae3          	bne	a0,s3,ffffffffc020193c <vprintfmt+0x52>
ffffffffc020194c:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201950:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201954:	4981                	li	s3,0
ffffffffc0201956:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0201958:	5cfd                	li	s9,-1
ffffffffc020195a:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020195c:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0201960:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201962:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0201966:	0ff6f693          	andi	a3,a3,255
ffffffffc020196a:	00140d13          	addi	s10,s0,1
ffffffffc020196e:	20d5e563          	bltu	a1,a3,ffffffffc0201b78 <vprintfmt+0x28e>
ffffffffc0201972:	068a                	slli	a3,a3,0x2
ffffffffc0201974:	96d2                	add	a3,a3,s4
ffffffffc0201976:	4294                	lw	a3,0(a3)
ffffffffc0201978:	96d2                	add	a3,a3,s4
ffffffffc020197a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020197c:	70e6                	ld	ra,120(sp)
ffffffffc020197e:	7446                	ld	s0,112(sp)
ffffffffc0201980:	74a6                	ld	s1,104(sp)
ffffffffc0201982:	7906                	ld	s2,96(sp)
ffffffffc0201984:	69e6                	ld	s3,88(sp)
ffffffffc0201986:	6a46                	ld	s4,80(sp)
ffffffffc0201988:	6aa6                	ld	s5,72(sp)
ffffffffc020198a:	6b06                	ld	s6,64(sp)
ffffffffc020198c:	7be2                	ld	s7,56(sp)
ffffffffc020198e:	7c42                	ld	s8,48(sp)
ffffffffc0201990:	7ca2                	ld	s9,40(sp)
ffffffffc0201992:	7d02                	ld	s10,32(sp)
ffffffffc0201994:	6de2                	ld	s11,24(sp)
ffffffffc0201996:	6109                	addi	sp,sp,128
ffffffffc0201998:	8082                	ret
    if (lflag >= 2) {
ffffffffc020199a:	4705                	li	a4,1
ffffffffc020199c:	008a8593          	addi	a1,s5,8
ffffffffc02019a0:	01074463          	blt	a4,a6,ffffffffc02019a8 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc02019a4:	26080363          	beqz	a6,ffffffffc0201c0a <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc02019a8:	000ab603          	ld	a2,0(s5)
ffffffffc02019ac:	46c1                	li	a3,16
ffffffffc02019ae:	8aae                	mv	s5,a1
ffffffffc02019b0:	a06d                	j	ffffffffc0201a5a <vprintfmt+0x170>
            goto reswitch;
ffffffffc02019b2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02019b6:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019b8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02019ba:	b765                	j	ffffffffc0201962 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc02019bc:	000aa503          	lw	a0,0(s5)
ffffffffc02019c0:	85a6                	mv	a1,s1
ffffffffc02019c2:	0aa1                	addi	s5,s5,8
ffffffffc02019c4:	9902                	jalr	s2
            break;
ffffffffc02019c6:	bfb9                	j	ffffffffc0201924 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02019c8:	4705                	li	a4,1
ffffffffc02019ca:	008a8993          	addi	s3,s5,8
ffffffffc02019ce:	01074463          	blt	a4,a6,ffffffffc02019d6 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc02019d2:	22080463          	beqz	a6,ffffffffc0201bfa <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc02019d6:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc02019da:	24044463          	bltz	s0,ffffffffc0201c22 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc02019de:	8622                	mv	a2,s0
ffffffffc02019e0:	8ace                	mv	s5,s3
ffffffffc02019e2:	46a9                	li	a3,10
ffffffffc02019e4:	a89d                	j	ffffffffc0201a5a <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc02019e6:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02019ea:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02019ec:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc02019ee:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02019f2:	8fb5                	xor	a5,a5,a3
ffffffffc02019f4:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02019f8:	1ad74363          	blt	a4,a3,ffffffffc0201b9e <vprintfmt+0x2b4>
ffffffffc02019fc:	00369793          	slli	a5,a3,0x3
ffffffffc0201a00:	97e2                	add	a5,a5,s8
ffffffffc0201a02:	639c                	ld	a5,0(a5)
ffffffffc0201a04:	18078d63          	beqz	a5,ffffffffc0201b9e <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201a08:	86be                	mv	a3,a5
ffffffffc0201a0a:	00001617          	auipc	a2,0x1
ffffffffc0201a0e:	51e60613          	addi	a2,a2,1310 # ffffffffc0202f28 <error_string+0xe8>
ffffffffc0201a12:	85a6                	mv	a1,s1
ffffffffc0201a14:	854a                	mv	a0,s2
ffffffffc0201a16:	240000ef          	jal	ra,ffffffffc0201c56 <printfmt>
ffffffffc0201a1a:	b729                	j	ffffffffc0201924 <vprintfmt+0x3a>
            lflag ++;
ffffffffc0201a1c:	00144603          	lbu	a2,1(s0)
ffffffffc0201a20:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a22:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201a24:	bf3d                	j	ffffffffc0201962 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0201a26:	4705                	li	a4,1
ffffffffc0201a28:	008a8593          	addi	a1,s5,8
ffffffffc0201a2c:	01074463          	blt	a4,a6,ffffffffc0201a34 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0201a30:	1e080263          	beqz	a6,ffffffffc0201c14 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc0201a34:	000ab603          	ld	a2,0(s5)
ffffffffc0201a38:	46a1                	li	a3,8
ffffffffc0201a3a:	8aae                	mv	s5,a1
ffffffffc0201a3c:	a839                	j	ffffffffc0201a5a <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0201a3e:	03000513          	li	a0,48
ffffffffc0201a42:	85a6                	mv	a1,s1
ffffffffc0201a44:	e03e                	sd	a5,0(sp)
ffffffffc0201a46:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201a48:	85a6                	mv	a1,s1
ffffffffc0201a4a:	07800513          	li	a0,120
ffffffffc0201a4e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201a50:	0aa1                	addi	s5,s5,8
ffffffffc0201a52:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0201a56:	6782                	ld	a5,0(sp)
ffffffffc0201a58:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201a5a:	876e                	mv	a4,s11
ffffffffc0201a5c:	85a6                	mv	a1,s1
ffffffffc0201a5e:	854a                	mv	a0,s2
ffffffffc0201a60:	e1fff0ef          	jal	ra,ffffffffc020187e <printnum>
            break;
ffffffffc0201a64:	b5c1                	j	ffffffffc0201924 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201a66:	000ab603          	ld	a2,0(s5)
ffffffffc0201a6a:	0aa1                	addi	s5,s5,8
ffffffffc0201a6c:	1c060663          	beqz	a2,ffffffffc0201c38 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0201a70:	00160413          	addi	s0,a2,1
ffffffffc0201a74:	17b05c63          	blez	s11,ffffffffc0201bec <vprintfmt+0x302>
ffffffffc0201a78:	02d00593          	li	a1,45
ffffffffc0201a7c:	14b79263          	bne	a5,a1,ffffffffc0201bc0 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201a80:	00064783          	lbu	a5,0(a2)
ffffffffc0201a84:	0007851b          	sext.w	a0,a5
ffffffffc0201a88:	c905                	beqz	a0,ffffffffc0201ab8 <vprintfmt+0x1ce>
ffffffffc0201a8a:	000cc563          	bltz	s9,ffffffffc0201a94 <vprintfmt+0x1aa>
ffffffffc0201a8e:	3cfd                	addiw	s9,s9,-1
ffffffffc0201a90:	036c8263          	beq	s9,s6,ffffffffc0201ab4 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0201a94:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201a96:	18098463          	beqz	s3,ffffffffc0201c1e <vprintfmt+0x334>
ffffffffc0201a9a:	3781                	addiw	a5,a5,-32
ffffffffc0201a9c:	18fbf163          	bleu	a5,s7,ffffffffc0201c1e <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0201aa0:	03f00513          	li	a0,63
ffffffffc0201aa4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201aa6:	0405                	addi	s0,s0,1
ffffffffc0201aa8:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201aac:	3dfd                	addiw	s11,s11,-1
ffffffffc0201aae:	0007851b          	sext.w	a0,a5
ffffffffc0201ab2:	fd61                	bnez	a0,ffffffffc0201a8a <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc0201ab4:	e7b058e3          	blez	s11,ffffffffc0201924 <vprintfmt+0x3a>
ffffffffc0201ab8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201aba:	85a6                	mv	a1,s1
ffffffffc0201abc:	02000513          	li	a0,32
ffffffffc0201ac0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201ac2:	e60d81e3          	beqz	s11,ffffffffc0201924 <vprintfmt+0x3a>
ffffffffc0201ac6:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201ac8:	85a6                	mv	a1,s1
ffffffffc0201aca:	02000513          	li	a0,32
ffffffffc0201ace:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201ad0:	fe0d94e3          	bnez	s11,ffffffffc0201ab8 <vprintfmt+0x1ce>
ffffffffc0201ad4:	bd81                	j	ffffffffc0201924 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201ad6:	4705                	li	a4,1
ffffffffc0201ad8:	008a8593          	addi	a1,s5,8
ffffffffc0201adc:	01074463          	blt	a4,a6,ffffffffc0201ae4 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0201ae0:	12080063          	beqz	a6,ffffffffc0201c00 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0201ae4:	000ab603          	ld	a2,0(s5)
ffffffffc0201ae8:	46a9                	li	a3,10
ffffffffc0201aea:	8aae                	mv	s5,a1
ffffffffc0201aec:	b7bd                	j	ffffffffc0201a5a <vprintfmt+0x170>
ffffffffc0201aee:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc0201af2:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201af6:	846a                	mv	s0,s10
ffffffffc0201af8:	b5ad                	j	ffffffffc0201962 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0201afa:	85a6                	mv	a1,s1
ffffffffc0201afc:	02500513          	li	a0,37
ffffffffc0201b00:	9902                	jalr	s2
            break;
ffffffffc0201b02:	b50d                	j	ffffffffc0201924 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc0201b04:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0201b08:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201b0c:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b0e:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0201b10:	e40dd9e3          	bgez	s11,ffffffffc0201962 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0201b14:	8de6                	mv	s11,s9
ffffffffc0201b16:	5cfd                	li	s9,-1
ffffffffc0201b18:	b5a9                	j	ffffffffc0201962 <vprintfmt+0x78>
            goto reswitch;
ffffffffc0201b1a:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc0201b1e:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b22:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b24:	bd3d                	j	ffffffffc0201962 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc0201b26:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0201b2a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b2e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201b30:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201b34:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b38:	fcd56ce3          	bltu	a0,a3,ffffffffc0201b10 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b3c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b3e:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0201b42:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b46:	0196873b          	addw	a4,a3,s9
ffffffffc0201b4a:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b4e:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0201b52:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0201b56:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201b5a:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b5e:	fcd57fe3          	bleu	a3,a0,ffffffffc0201b3c <vprintfmt+0x252>
ffffffffc0201b62:	b77d                	j	ffffffffc0201b10 <vprintfmt+0x226>
            if (width < 0)
ffffffffc0201b64:	fffdc693          	not	a3,s11
ffffffffc0201b68:	96fd                	srai	a3,a3,0x3f
ffffffffc0201b6a:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201b6e:	00144603          	lbu	a2,1(s0)
ffffffffc0201b72:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b74:	846a                	mv	s0,s10
ffffffffc0201b76:	b3f5                	j	ffffffffc0201962 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0201b78:	85a6                	mv	a1,s1
ffffffffc0201b7a:	02500513          	li	a0,37
ffffffffc0201b7e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b80:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201b84:	02500793          	li	a5,37
ffffffffc0201b88:	8d22                	mv	s10,s0
ffffffffc0201b8a:	d8f70de3          	beq	a4,a5,ffffffffc0201924 <vprintfmt+0x3a>
ffffffffc0201b8e:	02500713          	li	a4,37
ffffffffc0201b92:	1d7d                	addi	s10,s10,-1
ffffffffc0201b94:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0201b98:	fee79de3          	bne	a5,a4,ffffffffc0201b92 <vprintfmt+0x2a8>
ffffffffc0201b9c:	b361                	j	ffffffffc0201924 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201b9e:	00001617          	auipc	a2,0x1
ffffffffc0201ba2:	37a60613          	addi	a2,a2,890 # ffffffffc0202f18 <error_string+0xd8>
ffffffffc0201ba6:	85a6                	mv	a1,s1
ffffffffc0201ba8:	854a                	mv	a0,s2
ffffffffc0201baa:	0ac000ef          	jal	ra,ffffffffc0201c56 <printfmt>
ffffffffc0201bae:	bb9d                	j	ffffffffc0201924 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201bb0:	00001617          	auipc	a2,0x1
ffffffffc0201bb4:	36060613          	addi	a2,a2,864 # ffffffffc0202f10 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0201bb8:	00001417          	auipc	s0,0x1
ffffffffc0201bbc:	35940413          	addi	s0,s0,857 # ffffffffc0202f11 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201bc0:	8532                	mv	a0,a2
ffffffffc0201bc2:	85e6                	mv	a1,s9
ffffffffc0201bc4:	e032                	sd	a2,0(sp)
ffffffffc0201bc6:	e43e                	sd	a5,8(sp)
ffffffffc0201bc8:	1de000ef          	jal	ra,ffffffffc0201da6 <strnlen>
ffffffffc0201bcc:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201bd0:	6602                	ld	a2,0(sp)
ffffffffc0201bd2:	01b05d63          	blez	s11,ffffffffc0201bec <vprintfmt+0x302>
ffffffffc0201bd6:	67a2                	ld	a5,8(sp)
ffffffffc0201bd8:	2781                	sext.w	a5,a5
ffffffffc0201bda:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0201bdc:	6522                	ld	a0,8(sp)
ffffffffc0201bde:	85a6                	mv	a1,s1
ffffffffc0201be0:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201be2:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201be4:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201be6:	6602                	ld	a2,0(sp)
ffffffffc0201be8:	fe0d9ae3          	bnez	s11,ffffffffc0201bdc <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bec:	00064783          	lbu	a5,0(a2)
ffffffffc0201bf0:	0007851b          	sext.w	a0,a5
ffffffffc0201bf4:	e8051be3          	bnez	a0,ffffffffc0201a8a <vprintfmt+0x1a0>
ffffffffc0201bf8:	b335                	j	ffffffffc0201924 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc0201bfa:	000aa403          	lw	s0,0(s5)
ffffffffc0201bfe:	bbf1                	j	ffffffffc02019da <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc0201c00:	000ae603          	lwu	a2,0(s5)
ffffffffc0201c04:	46a9                	li	a3,10
ffffffffc0201c06:	8aae                	mv	s5,a1
ffffffffc0201c08:	bd89                	j	ffffffffc0201a5a <vprintfmt+0x170>
ffffffffc0201c0a:	000ae603          	lwu	a2,0(s5)
ffffffffc0201c0e:	46c1                	li	a3,16
ffffffffc0201c10:	8aae                	mv	s5,a1
ffffffffc0201c12:	b5a1                	j	ffffffffc0201a5a <vprintfmt+0x170>
ffffffffc0201c14:	000ae603          	lwu	a2,0(s5)
ffffffffc0201c18:	46a1                	li	a3,8
ffffffffc0201c1a:	8aae                	mv	s5,a1
ffffffffc0201c1c:	bd3d                	j	ffffffffc0201a5a <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0201c1e:	9902                	jalr	s2
ffffffffc0201c20:	b559                	j	ffffffffc0201aa6 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc0201c22:	85a6                	mv	a1,s1
ffffffffc0201c24:	02d00513          	li	a0,45
ffffffffc0201c28:	e03e                	sd	a5,0(sp)
ffffffffc0201c2a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201c2c:	8ace                	mv	s5,s3
ffffffffc0201c2e:	40800633          	neg	a2,s0
ffffffffc0201c32:	46a9                	li	a3,10
ffffffffc0201c34:	6782                	ld	a5,0(sp)
ffffffffc0201c36:	b515                	j	ffffffffc0201a5a <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc0201c38:	01b05663          	blez	s11,ffffffffc0201c44 <vprintfmt+0x35a>
ffffffffc0201c3c:	02d00693          	li	a3,45
ffffffffc0201c40:	f6d798e3          	bne	a5,a3,ffffffffc0201bb0 <vprintfmt+0x2c6>
ffffffffc0201c44:	00001417          	auipc	s0,0x1
ffffffffc0201c48:	2cd40413          	addi	s0,s0,717 # ffffffffc0202f11 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c4c:	02800513          	li	a0,40
ffffffffc0201c50:	02800793          	li	a5,40
ffffffffc0201c54:	bd1d                	j	ffffffffc0201a8a <vprintfmt+0x1a0>

ffffffffc0201c56 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201c56:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201c58:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201c5c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201c5e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201c60:	ec06                	sd	ra,24(sp)
ffffffffc0201c62:	f83a                	sd	a4,48(sp)
ffffffffc0201c64:	fc3e                	sd	a5,56(sp)
ffffffffc0201c66:	e0c2                	sd	a6,64(sp)
ffffffffc0201c68:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201c6a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201c6c:	c7fff0ef          	jal	ra,ffffffffc02018ea <vprintfmt>
}
ffffffffc0201c70:	60e2                	ld	ra,24(sp)
ffffffffc0201c72:	6161                	addi	sp,sp,80
ffffffffc0201c74:	8082                	ret

ffffffffc0201c76 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201c76:	715d                	addi	sp,sp,-80
ffffffffc0201c78:	e486                	sd	ra,72(sp)
ffffffffc0201c7a:	e0a2                	sd	s0,64(sp)
ffffffffc0201c7c:	fc26                	sd	s1,56(sp)
ffffffffc0201c7e:	f84a                	sd	s2,48(sp)
ffffffffc0201c80:	f44e                	sd	s3,40(sp)
ffffffffc0201c82:	f052                	sd	s4,32(sp)
ffffffffc0201c84:	ec56                	sd	s5,24(sp)
ffffffffc0201c86:	e85a                	sd	s6,16(sp)
ffffffffc0201c88:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc0201c8a:	c901                	beqz	a0,ffffffffc0201c9a <readline+0x24>
        cprintf("%s", prompt);
ffffffffc0201c8c:	85aa                	mv	a1,a0
ffffffffc0201c8e:	00001517          	auipc	a0,0x1
ffffffffc0201c92:	29a50513          	addi	a0,a0,666 # ffffffffc0202f28 <error_string+0xe8>
ffffffffc0201c96:	c20fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
readline(const char *prompt) {
ffffffffc0201c9a:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201c9c:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201c9e:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201ca0:	4aa9                	li	s5,10
ffffffffc0201ca2:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201ca4:	00004b97          	auipc	s7,0x4
ffffffffc0201ca8:	374b8b93          	addi	s7,s7,884 # ffffffffc0206018 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201cac:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201cb0:	c7efe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201cb4:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201cb6:	00054b63          	bltz	a0,ffffffffc0201ccc <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201cba:	00a95b63          	ble	a0,s2,ffffffffc0201cd0 <readline+0x5a>
ffffffffc0201cbe:	029a5463          	ble	s1,s4,ffffffffc0201ce6 <readline+0x70>
        c = getchar();
ffffffffc0201cc2:	c6cfe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201cc6:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201cc8:	fe0559e3          	bgez	a0,ffffffffc0201cba <readline+0x44>
            return NULL;
ffffffffc0201ccc:	4501                	li	a0,0
ffffffffc0201cce:	a099                	j	ffffffffc0201d14 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0201cd0:	03341463          	bne	s0,s3,ffffffffc0201cf8 <readline+0x82>
ffffffffc0201cd4:	e8b9                	bnez	s1,ffffffffc0201d2a <readline+0xb4>
        c = getchar();
ffffffffc0201cd6:	c58fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201cda:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201cdc:	fe0548e3          	bltz	a0,ffffffffc0201ccc <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201ce0:	fea958e3          	ble	a0,s2,ffffffffc0201cd0 <readline+0x5a>
ffffffffc0201ce4:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201ce6:	8522                	mv	a0,s0
ffffffffc0201ce8:	c02fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i ++] = c;
ffffffffc0201cec:	009b87b3          	add	a5,s7,s1
ffffffffc0201cf0:	00878023          	sb	s0,0(a5)
ffffffffc0201cf4:	2485                	addiw	s1,s1,1
ffffffffc0201cf6:	bf6d                	j	ffffffffc0201cb0 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0201cf8:	01540463          	beq	s0,s5,ffffffffc0201d00 <readline+0x8a>
ffffffffc0201cfc:	fb641ae3          	bne	s0,s6,ffffffffc0201cb0 <readline+0x3a>
            cputchar(c);
ffffffffc0201d00:	8522                	mv	a0,s0
ffffffffc0201d02:	be8fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i] = '\0';
ffffffffc0201d06:	00004517          	auipc	a0,0x4
ffffffffc0201d0a:	31250513          	addi	a0,a0,786 # ffffffffc0206018 <edata>
ffffffffc0201d0e:	94aa                	add	s1,s1,a0
ffffffffc0201d10:	00048023          	sb	zero,0(s1) # ffffffffc0200000 <kern_entry>
            return buf;
        }
    }
}
ffffffffc0201d14:	60a6                	ld	ra,72(sp)
ffffffffc0201d16:	6406                	ld	s0,64(sp)
ffffffffc0201d18:	74e2                	ld	s1,56(sp)
ffffffffc0201d1a:	7942                	ld	s2,48(sp)
ffffffffc0201d1c:	79a2                	ld	s3,40(sp)
ffffffffc0201d1e:	7a02                	ld	s4,32(sp)
ffffffffc0201d20:	6ae2                	ld	s5,24(sp)
ffffffffc0201d22:	6b42                	ld	s6,16(sp)
ffffffffc0201d24:	6ba2                	ld	s7,8(sp)
ffffffffc0201d26:	6161                	addi	sp,sp,80
ffffffffc0201d28:	8082                	ret
            cputchar(c);
ffffffffc0201d2a:	4521                	li	a0,8
ffffffffc0201d2c:	bbefe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            i --;
ffffffffc0201d30:	34fd                	addiw	s1,s1,-1
ffffffffc0201d32:	bfbd                	j	ffffffffc0201cb0 <readline+0x3a>

ffffffffc0201d34 <sbi_console_putchar>:
    return ret_val;
}

void sbi_console_putchar(unsigned char ch)
{
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201d34:	00004797          	auipc	a5,0x4
ffffffffc0201d38:	2d478793          	addi	a5,a5,724 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile(
ffffffffc0201d3c:	6398                	ld	a4,0(a5)
ffffffffc0201d3e:	4781                	li	a5,0
ffffffffc0201d40:	88ba                	mv	a7,a4
ffffffffc0201d42:	852a                	mv	a0,a0
ffffffffc0201d44:	85be                	mv	a1,a5
ffffffffc0201d46:	863e                	mv	a2,a5
ffffffffc0201d48:	00000073          	ecall
ffffffffc0201d4c:	87aa                	mv	a5,a0
}
ffffffffc0201d4e:	8082                	ret

ffffffffc0201d50 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value)
{
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201d50:	00004797          	auipc	a5,0x4
ffffffffc0201d54:	6e878793          	addi	a5,a5,1768 # ffffffffc0206438 <SBI_SET_TIMER>
    __asm__ volatile(
ffffffffc0201d58:	6398                	ld	a4,0(a5)
ffffffffc0201d5a:	4781                	li	a5,0
ffffffffc0201d5c:	88ba                	mv	a7,a4
ffffffffc0201d5e:	852a                	mv	a0,a0
ffffffffc0201d60:	85be                	mv	a1,a5
ffffffffc0201d62:	863e                	mv	a2,a5
ffffffffc0201d64:	00000073          	ecall
ffffffffc0201d68:	87aa                	mv	a5,a0
}
ffffffffc0201d6a:	8082                	ret

ffffffffc0201d6c <sbi_console_getchar>:

int sbi_console_getchar(void)
{
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201d6c:	00004797          	auipc	a5,0x4
ffffffffc0201d70:	29478793          	addi	a5,a5,660 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile(
ffffffffc0201d74:	639c                	ld	a5,0(a5)
ffffffffc0201d76:	4501                	li	a0,0
ffffffffc0201d78:	88be                	mv	a7,a5
ffffffffc0201d7a:	852a                	mv	a0,a0
ffffffffc0201d7c:	85aa                	mv	a1,a0
ffffffffc0201d7e:	862a                	mv	a2,a0
ffffffffc0201d80:	00000073          	ecall
ffffffffc0201d84:	852a                	mv	a0,a0
}
ffffffffc0201d86:	2501                	sext.w	a0,a0
ffffffffc0201d88:	8082                	ret

ffffffffc0201d8a <sbi_shutdown>:

void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201d8a:	00004797          	auipc	a5,0x4
ffffffffc0201d8e:	28678793          	addi	a5,a5,646 # ffffffffc0206010 <SBI_SHUTDOWN>
    __asm__ volatile(
ffffffffc0201d92:	6398                	ld	a4,0(a5)
ffffffffc0201d94:	4781                	li	a5,0
ffffffffc0201d96:	88ba                	mv	a7,a4
ffffffffc0201d98:	853e                	mv	a0,a5
ffffffffc0201d9a:	85be                	mv	a1,a5
ffffffffc0201d9c:	863e                	mv	a2,a5
ffffffffc0201d9e:	00000073          	ecall
ffffffffc0201da2:	87aa                	mv	a5,a0
ffffffffc0201da4:	8082                	ret

ffffffffc0201da6 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201da6:	c185                	beqz	a1,ffffffffc0201dc6 <strnlen+0x20>
ffffffffc0201da8:	00054783          	lbu	a5,0(a0)
ffffffffc0201dac:	cf89                	beqz	a5,ffffffffc0201dc6 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0201dae:	4781                	li	a5,0
ffffffffc0201db0:	a021                	j	ffffffffc0201db8 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201db2:	00074703          	lbu	a4,0(a4)
ffffffffc0201db6:	c711                	beqz	a4,ffffffffc0201dc2 <strnlen+0x1c>
        cnt ++;
ffffffffc0201db8:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201dba:	00f50733          	add	a4,a0,a5
ffffffffc0201dbe:	fef59ae3          	bne	a1,a5,ffffffffc0201db2 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0201dc2:	853e                	mv	a0,a5
ffffffffc0201dc4:	8082                	ret
    size_t cnt = 0;
ffffffffc0201dc6:	4781                	li	a5,0
}
ffffffffc0201dc8:	853e                	mv	a0,a5
ffffffffc0201dca:	8082                	ret

ffffffffc0201dcc <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201dcc:	00054783          	lbu	a5,0(a0)
ffffffffc0201dd0:	0005c703          	lbu	a4,0(a1) # fffffffffffff000 <end+0x3fdf8b80>
ffffffffc0201dd4:	cb91                	beqz	a5,ffffffffc0201de8 <strcmp+0x1c>
ffffffffc0201dd6:	00e79c63          	bne	a5,a4,ffffffffc0201dee <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0201dda:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ddc:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0201de0:	0585                	addi	a1,a1,1
ffffffffc0201de2:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201de6:	fbe5                	bnez	a5,ffffffffc0201dd6 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201de8:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201dea:	9d19                	subw	a0,a0,a4
ffffffffc0201dec:	8082                	ret
ffffffffc0201dee:	0007851b          	sext.w	a0,a5
ffffffffc0201df2:	9d19                	subw	a0,a0,a4
ffffffffc0201df4:	8082                	ret

ffffffffc0201df6 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201df6:	00054783          	lbu	a5,0(a0)
ffffffffc0201dfa:	cb91                	beqz	a5,ffffffffc0201e0e <strchr+0x18>
        if (*s == c) {
ffffffffc0201dfc:	00b79563          	bne	a5,a1,ffffffffc0201e06 <strchr+0x10>
ffffffffc0201e00:	a809                	j	ffffffffc0201e12 <strchr+0x1c>
ffffffffc0201e02:	00b78763          	beq	a5,a1,ffffffffc0201e10 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0201e06:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201e08:	00054783          	lbu	a5,0(a0)
ffffffffc0201e0c:	fbfd                	bnez	a5,ffffffffc0201e02 <strchr+0xc>
    }
    return NULL;
ffffffffc0201e0e:	4501                	li	a0,0
}
ffffffffc0201e10:	8082                	ret
ffffffffc0201e12:	8082                	ret

ffffffffc0201e14 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201e14:	ca01                	beqz	a2,ffffffffc0201e24 <memset+0x10>
ffffffffc0201e16:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201e18:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201e1a:	0785                	addi	a5,a5,1
ffffffffc0201e1c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201e20:	fec79de3          	bne	a5,a2,ffffffffc0201e1a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201e24:	8082                	ret
