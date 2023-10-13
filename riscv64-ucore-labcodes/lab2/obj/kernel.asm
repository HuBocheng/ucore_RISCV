
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
ffffffffc020004e:	45b010ef          	jal	ra,ffffffffc0201ca8 <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fe000ef          	jal	ra,ffffffffc0200450 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00002517          	auipc	a0,0x2
ffffffffc020005a:	c6a50513          	addi	a0,a0,-918 # ffffffffc0201cc0 <etext+0x6>
ffffffffc020005e:	090000ef          	jal	ra,ffffffffc02000ee <cputs>

    print_kerninfo();
ffffffffc0200062:	0dc000ef          	jal	ra,ffffffffc020013e <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200066:	404000ef          	jal	ra,ffffffffc020046a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020006a:	352010ef          	jal	ra,ffffffffc02013bc <pmm_init>

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
ffffffffc02000aa:	6d4010ef          	jal	ra,ffffffffc020177e <vprintfmt>
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
ffffffffc02000de:	6a0010ef          	jal	ra,ffffffffc020177e <vprintfmt>
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
ffffffffc0200144:	bd050513          	addi	a0,a0,-1072 # ffffffffc0201d10 <etext+0x56>
void print_kerninfo(void) {
ffffffffc0200148:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014a:	f6dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014e:	00000597          	auipc	a1,0x0
ffffffffc0200152:	ee858593          	addi	a1,a1,-280 # ffffffffc0200036 <kern_init>
ffffffffc0200156:	00002517          	auipc	a0,0x2
ffffffffc020015a:	bda50513          	addi	a0,a0,-1062 # ffffffffc0201d30 <etext+0x76>
ffffffffc020015e:	f59ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200162:	00002597          	auipc	a1,0x2
ffffffffc0200166:	b5858593          	addi	a1,a1,-1192 # ffffffffc0201cba <etext>
ffffffffc020016a:	00002517          	auipc	a0,0x2
ffffffffc020016e:	be650513          	addi	a0,a0,-1050 # ffffffffc0201d50 <etext+0x96>
ffffffffc0200172:	f45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200176:	00006597          	auipc	a1,0x6
ffffffffc020017a:	ea258593          	addi	a1,a1,-350 # ffffffffc0206018 <edata>
ffffffffc020017e:	00002517          	auipc	a0,0x2
ffffffffc0200182:	bf250513          	addi	a0,a0,-1038 # ffffffffc0201d70 <etext+0xb6>
ffffffffc0200186:	f31ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018a:	00006597          	auipc	a1,0x6
ffffffffc020018e:	2f658593          	addi	a1,a1,758 # ffffffffc0206480 <end>
ffffffffc0200192:	00002517          	auipc	a0,0x2
ffffffffc0200196:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0201d90 <etext+0xd6>
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
ffffffffc02001c4:	bf050513          	addi	a0,a0,-1040 # ffffffffc0201db0 <etext+0xf6>
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
ffffffffc02001d4:	b1060613          	addi	a2,a2,-1264 # ffffffffc0201ce0 <etext+0x26>
ffffffffc02001d8:	04e00593          	li	a1,78
ffffffffc02001dc:	00002517          	auipc	a0,0x2
ffffffffc02001e0:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0201cf8 <etext+0x3e>
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
ffffffffc02001f0:	cd460613          	addi	a2,a2,-812 # ffffffffc0201ec0 <commands+0xe0>
ffffffffc02001f4:	00002597          	auipc	a1,0x2
ffffffffc02001f8:	cec58593          	addi	a1,a1,-788 # ffffffffc0201ee0 <commands+0x100>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	cec50513          	addi	a0,a0,-788 # ffffffffc0201ee8 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200206:	eb1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020020a:	00002617          	auipc	a2,0x2
ffffffffc020020e:	cee60613          	addi	a2,a2,-786 # ffffffffc0201ef8 <commands+0x118>
ffffffffc0200212:	00002597          	auipc	a1,0x2
ffffffffc0200216:	d0e58593          	addi	a1,a1,-754 # ffffffffc0201f20 <commands+0x140>
ffffffffc020021a:	00002517          	auipc	a0,0x2
ffffffffc020021e:	cce50513          	addi	a0,a0,-818 # ffffffffc0201ee8 <commands+0x108>
ffffffffc0200222:	e95ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200226:	00002617          	auipc	a2,0x2
ffffffffc020022a:	d0a60613          	addi	a2,a2,-758 # ffffffffc0201f30 <commands+0x150>
ffffffffc020022e:	00002597          	auipc	a1,0x2
ffffffffc0200232:	d2258593          	addi	a1,a1,-734 # ffffffffc0201f50 <commands+0x170>
ffffffffc0200236:	00002517          	auipc	a0,0x2
ffffffffc020023a:	cb250513          	addi	a0,a0,-846 # ffffffffc0201ee8 <commands+0x108>
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
ffffffffc0200274:	bb850513          	addi	a0,a0,-1096 # ffffffffc0201e28 <commands+0x48>
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
ffffffffc0200296:	bbe50513          	addi	a0,a0,-1090 # ffffffffc0201e50 <commands+0x70>
ffffffffc020029a:	e1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (tf != NULL) {
ffffffffc020029e:	000c0563          	beqz	s8,ffffffffc02002a8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a2:	8562                	mv	a0,s8
ffffffffc02002a4:	3a6000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002a8:	00002c97          	auipc	s9,0x2
ffffffffc02002ac:	b38c8c93          	addi	s9,s9,-1224 # ffffffffc0201de0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b0:	00002997          	auipc	s3,0x2
ffffffffc02002b4:	bc898993          	addi	s3,s3,-1080 # ffffffffc0201e78 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00002917          	auipc	s2,0x2
ffffffffc02002bc:	bc890913          	addi	s2,s2,-1080 # ffffffffc0201e80 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002c0:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c2:	00002b17          	auipc	s6,0x2
ffffffffc02002c6:	bc6b0b13          	addi	s6,s6,-1082 # ffffffffc0201e88 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ca:	00002a97          	auipc	s5,0x2
ffffffffc02002ce:	c16a8a93          	addi	s5,s5,-1002 # ffffffffc0201ee0 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d2:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d4:	854e                	mv	a0,s3
ffffffffc02002d6:	035010ef          	jal	ra,ffffffffc0201b0a <readline>
ffffffffc02002da:	842a                	mv	s0,a0
ffffffffc02002dc:	dd65                	beqz	a0,ffffffffc02002d4 <kmonitor+0x6a>
ffffffffc02002de:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e4:	c999                	beqz	a1,ffffffffc02002fa <kmonitor+0x90>
ffffffffc02002e6:	854a                	mv	a0,s2
ffffffffc02002e8:	1a3010ef          	jal	ra,ffffffffc0201c8a <strchr>
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
ffffffffc0200302:	ae2d0d13          	addi	s10,s10,-1310 # ffffffffc0201de0 <commands>
    if (argc == 0) {
ffffffffc0200306:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200308:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	0d61                	addi	s10,s10,24
ffffffffc020030c:	155010ef          	jal	ra,ffffffffc0201c60 <strcmp>
ffffffffc0200310:	c919                	beqz	a0,ffffffffc0200326 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200312:	2405                	addiw	s0,s0,1
ffffffffc0200314:	09740463          	beq	s0,s7,ffffffffc020039c <kmonitor+0x132>
ffffffffc0200318:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031c:	6582                	ld	a1,0(sp)
ffffffffc020031e:	0d61                	addi	s10,s10,24
ffffffffc0200320:	141010ef          	jal	ra,ffffffffc0201c60 <strcmp>
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
ffffffffc0200386:	105010ef          	jal	ra,ffffffffc0201c8a <strchr>
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
ffffffffc02003a2:	b0a50513          	addi	a0,a0,-1270 # ffffffffc0201ea8 <commands+0xc8>
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
ffffffffc02003e2:	b8250513          	addi	a0,a0,-1150 # ffffffffc0201f60 <commands+0x180>
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
ffffffffc02003f8:	44450513          	addi	a0,a0,1092 # ffffffffc0202838 <best_fit_pmm_manager+0xf0>
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
ffffffffc0200424:	7c0010ef          	jal	ra,ffffffffc0201be4 <sbi_set_timer>
}
ffffffffc0200428:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042a:	00006797          	auipc	a5,0x6
ffffffffc020042e:	0007bb23          	sd	zero,22(a5) # ffffffffc0206440 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200432:	00002517          	auipc	a0,0x2
ffffffffc0200436:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0201f80 <commands+0x1a0>
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
ffffffffc020044c:	7980106f          	j	ffffffffc0201be4 <sbi_set_timer>

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
ffffffffc0200456:	7720106f          	j	ffffffffc0201bc8 <sbi_console_putchar>

ffffffffc020045a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045a:	7a60106f          	j	ffffffffc0201c00 <sbi_console_getchar>

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
ffffffffc0200488:	c1450513          	addi	a0,a0,-1004 # ffffffffc0202098 <commands+0x2b8>
{
ffffffffc020048c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048e:	c29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200492:	640c                	ld	a1,8(s0)
ffffffffc0200494:	00002517          	auipc	a0,0x2
ffffffffc0200498:	c1c50513          	addi	a0,a0,-996 # ffffffffc02020b0 <commands+0x2d0>
ffffffffc020049c:	c1bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a0:	680c                	ld	a1,16(s0)
ffffffffc02004a2:	00002517          	auipc	a0,0x2
ffffffffc02004a6:	c2650513          	addi	a0,a0,-986 # ffffffffc02020c8 <commands+0x2e8>
ffffffffc02004aa:	c0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004ae:	6c0c                	ld	a1,24(s0)
ffffffffc02004b0:	00002517          	auipc	a0,0x2
ffffffffc02004b4:	c3050513          	addi	a0,a0,-976 # ffffffffc02020e0 <commands+0x300>
ffffffffc02004b8:	bffff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004bc:	700c                	ld	a1,32(s0)
ffffffffc02004be:	00002517          	auipc	a0,0x2
ffffffffc02004c2:	c3a50513          	addi	a0,a0,-966 # ffffffffc02020f8 <commands+0x318>
ffffffffc02004c6:	bf1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004ca:	740c                	ld	a1,40(s0)
ffffffffc02004cc:	00002517          	auipc	a0,0x2
ffffffffc02004d0:	c4450513          	addi	a0,a0,-956 # ffffffffc0202110 <commands+0x330>
ffffffffc02004d4:	be3ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d8:	780c                	ld	a1,48(s0)
ffffffffc02004da:	00002517          	auipc	a0,0x2
ffffffffc02004de:	c4e50513          	addi	a0,a0,-946 # ffffffffc0202128 <commands+0x348>
ffffffffc02004e2:	bd5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e6:	7c0c                	ld	a1,56(s0)
ffffffffc02004e8:	00002517          	auipc	a0,0x2
ffffffffc02004ec:	c5850513          	addi	a0,a0,-936 # ffffffffc0202140 <commands+0x360>
ffffffffc02004f0:	bc7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f4:	602c                	ld	a1,64(s0)
ffffffffc02004f6:	00002517          	auipc	a0,0x2
ffffffffc02004fa:	c6250513          	addi	a0,a0,-926 # ffffffffc0202158 <commands+0x378>
ffffffffc02004fe:	bb9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200502:	642c                	ld	a1,72(s0)
ffffffffc0200504:	00002517          	auipc	a0,0x2
ffffffffc0200508:	c6c50513          	addi	a0,a0,-916 # ffffffffc0202170 <commands+0x390>
ffffffffc020050c:	babff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200510:	682c                	ld	a1,80(s0)
ffffffffc0200512:	00002517          	auipc	a0,0x2
ffffffffc0200516:	c7650513          	addi	a0,a0,-906 # ffffffffc0202188 <commands+0x3a8>
ffffffffc020051a:	b9dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051e:	6c2c                	ld	a1,88(s0)
ffffffffc0200520:	00002517          	auipc	a0,0x2
ffffffffc0200524:	c8050513          	addi	a0,a0,-896 # ffffffffc02021a0 <commands+0x3c0>
ffffffffc0200528:	b8fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052c:	702c                	ld	a1,96(s0)
ffffffffc020052e:	00002517          	auipc	a0,0x2
ffffffffc0200532:	c8a50513          	addi	a0,a0,-886 # ffffffffc02021b8 <commands+0x3d8>
ffffffffc0200536:	b81ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053a:	742c                	ld	a1,104(s0)
ffffffffc020053c:	00002517          	auipc	a0,0x2
ffffffffc0200540:	c9450513          	addi	a0,a0,-876 # ffffffffc02021d0 <commands+0x3f0>
ffffffffc0200544:	b73ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200548:	782c                	ld	a1,112(s0)
ffffffffc020054a:	00002517          	auipc	a0,0x2
ffffffffc020054e:	c9e50513          	addi	a0,a0,-866 # ffffffffc02021e8 <commands+0x408>
ffffffffc0200552:	b65ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200556:	7c2c                	ld	a1,120(s0)
ffffffffc0200558:	00002517          	auipc	a0,0x2
ffffffffc020055c:	ca850513          	addi	a0,a0,-856 # ffffffffc0202200 <commands+0x420>
ffffffffc0200560:	b57ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200564:	604c                	ld	a1,128(s0)
ffffffffc0200566:	00002517          	auipc	a0,0x2
ffffffffc020056a:	cb250513          	addi	a0,a0,-846 # ffffffffc0202218 <commands+0x438>
ffffffffc020056e:	b49ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200572:	644c                	ld	a1,136(s0)
ffffffffc0200574:	00002517          	auipc	a0,0x2
ffffffffc0200578:	cbc50513          	addi	a0,a0,-836 # ffffffffc0202230 <commands+0x450>
ffffffffc020057c:	b3bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200580:	684c                	ld	a1,144(s0)
ffffffffc0200582:	00002517          	auipc	a0,0x2
ffffffffc0200586:	cc650513          	addi	a0,a0,-826 # ffffffffc0202248 <commands+0x468>
ffffffffc020058a:	b2dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058e:	6c4c                	ld	a1,152(s0)
ffffffffc0200590:	00002517          	auipc	a0,0x2
ffffffffc0200594:	cd050513          	addi	a0,a0,-816 # ffffffffc0202260 <commands+0x480>
ffffffffc0200598:	b1fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059c:	704c                	ld	a1,160(s0)
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	cda50513          	addi	a0,a0,-806 # ffffffffc0202278 <commands+0x498>
ffffffffc02005a6:	b11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005aa:	744c                	ld	a1,168(s0)
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	ce450513          	addi	a0,a0,-796 # ffffffffc0202290 <commands+0x4b0>
ffffffffc02005b4:	b03ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b8:	784c                	ld	a1,176(s0)
ffffffffc02005ba:	00002517          	auipc	a0,0x2
ffffffffc02005be:	cee50513          	addi	a0,a0,-786 # ffffffffc02022a8 <commands+0x4c8>
ffffffffc02005c2:	af5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c6:	7c4c                	ld	a1,184(s0)
ffffffffc02005c8:	00002517          	auipc	a0,0x2
ffffffffc02005cc:	cf850513          	addi	a0,a0,-776 # ffffffffc02022c0 <commands+0x4e0>
ffffffffc02005d0:	ae7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d4:	606c                	ld	a1,192(s0)
ffffffffc02005d6:	00002517          	auipc	a0,0x2
ffffffffc02005da:	d0250513          	addi	a0,a0,-766 # ffffffffc02022d8 <commands+0x4f8>
ffffffffc02005de:	ad9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e2:	646c                	ld	a1,200(s0)
ffffffffc02005e4:	00002517          	auipc	a0,0x2
ffffffffc02005e8:	d0c50513          	addi	a0,a0,-756 # ffffffffc02022f0 <commands+0x510>
ffffffffc02005ec:	acbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f0:	686c                	ld	a1,208(s0)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	d1650513          	addi	a0,a0,-746 # ffffffffc0202308 <commands+0x528>
ffffffffc02005fa:	abdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200600:	00002517          	auipc	a0,0x2
ffffffffc0200604:	d2050513          	addi	a0,a0,-736 # ffffffffc0202320 <commands+0x540>
ffffffffc0200608:	aafff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060c:	706c                	ld	a1,224(s0)
ffffffffc020060e:	00002517          	auipc	a0,0x2
ffffffffc0200612:	d2a50513          	addi	a0,a0,-726 # ffffffffc0202338 <commands+0x558>
ffffffffc0200616:	aa1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061a:	746c                	ld	a1,232(s0)
ffffffffc020061c:	00002517          	auipc	a0,0x2
ffffffffc0200620:	d3450513          	addi	a0,a0,-716 # ffffffffc0202350 <commands+0x570>
ffffffffc0200624:	a93ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200628:	786c                	ld	a1,240(s0)
ffffffffc020062a:	00002517          	auipc	a0,0x2
ffffffffc020062e:	d3e50513          	addi	a0,a0,-706 # ffffffffc0202368 <commands+0x588>
ffffffffc0200632:	a85ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200638:	6402                	ld	s0,0(sp)
ffffffffc020063a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	d4450513          	addi	a0,a0,-700 # ffffffffc0202380 <commands+0x5a0>
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
ffffffffc0200656:	d4650513          	addi	a0,a0,-698 # ffffffffc0202398 <commands+0x5b8>
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
ffffffffc020066e:	d4650513          	addi	a0,a0,-698 # ffffffffc02023b0 <commands+0x5d0>
ffffffffc0200672:	a45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	d4e50513          	addi	a0,a0,-690 # ffffffffc02023c8 <commands+0x5e8>
ffffffffc0200682:	a35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	d5650513          	addi	a0,a0,-682 # ffffffffc02023e0 <commands+0x600>
ffffffffc0200692:	a25ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	d5a50513          	addi	a0,a0,-678 # ffffffffc02023f8 <commands+0x618>
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
ffffffffc02006c0:	8e070713          	addi	a4,a4,-1824 # ffffffffc0201f9c <commands+0x1bc>
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
ffffffffc02006d2:	96250513          	addi	a0,a0,-1694 # ffffffffc0202030 <commands+0x250>
ffffffffc02006d6:	9e1ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc02006da:	00002517          	auipc	a0,0x2
ffffffffc02006de:	93650513          	addi	a0,a0,-1738 # ffffffffc0202010 <commands+0x230>
ffffffffc02006e2:	9d5ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc02006e6:	00002517          	auipc	a0,0x2
ffffffffc02006ea:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0201fd0 <commands+0x1f0>
ffffffffc02006ee:	9c9ff06f          	j	ffffffffc02000b6 <cprintf>
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
ffffffffc02006f2:	00002517          	auipc	a0,0x2
ffffffffc02006f6:	95e50513          	addi	a0,a0,-1698 # ffffffffc0202050 <commands+0x270>
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
ffffffffc0200732:	94a50513          	addi	a0,a0,-1718 # ffffffffc0202078 <commands+0x298>
ffffffffc0200736:	981ff06f          	j	ffffffffc02000b6 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc020073a:	00002517          	auipc	a0,0x2
ffffffffc020073e:	8b650513          	addi	a0,a0,-1866 # ffffffffc0201ff0 <commands+0x210>
ffffffffc0200742:	975ff06f          	j	ffffffffc02000b6 <cprintf>
        print_trapframe(tf);
ffffffffc0200746:	f05ff06f          	j	ffffffffc020064a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020074a:	06400593          	li	a1,100
ffffffffc020074e:	00002517          	auipc	a0,0x2
ffffffffc0200752:	91a50513          	addi	a0,a0,-1766 # ffffffffc0202068 <commands+0x288>
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
ffffffffc0200780:	49e010ef          	jal	ra,ffffffffc0201c1e <sbi_shutdown>
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

ffffffffc0200856 <best_fit_init>:
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
best_fit_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200862:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200866:	8082                	ret

ffffffffc0200868 <best_fit_nr_free_pages>:

static size_t
best_fit_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200868:	00006517          	auipc	a0,0x6
ffffffffc020086c:	bf056503          	lwu	a0,-1040(a0) # ffffffffc0206458 <free_area+0x10>
ffffffffc0200870:	8082                	ret

ffffffffc0200872 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200872:	c15d                	beqz	a0,ffffffffc0200918 <best_fit_alloc_pages+0xa6>
    if (n > nr_free)
ffffffffc0200874:	00006617          	auipc	a2,0x6
ffffffffc0200878:	bd460613          	addi	a2,a2,-1068 # ffffffffc0206448 <free_area>
ffffffffc020087c:	01062803          	lw	a6,16(a2)
ffffffffc0200880:	86aa                	mv	a3,a0
ffffffffc0200882:	02081793          	slli	a5,a6,0x20
ffffffffc0200886:	9381                	srli	a5,a5,0x20
ffffffffc0200888:	08a7e663          	bltu	a5,a0,ffffffffc0200914 <best_fit_alloc_pages+0xa2>
    size_t min_size = nr_free + 1;
ffffffffc020088c:	0018059b          	addiw	a1,a6,1
ffffffffc0200890:	1582                	slli	a1,a1,0x20
ffffffffc0200892:	9181                	srli	a1,a1,0x20
    list_entry_t *le = &free_list;
ffffffffc0200894:	87b2                	mv	a5,a2
    struct Page *best_fit_page = NULL;
ffffffffc0200896:	4501                	li	a0,0
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm)
{
    return listelm->next;
ffffffffc0200898:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc020089a:	00c78e63          	beq	a5,a2,ffffffffc02008b6 <best_fit_alloc_pages+0x44>
        if (p->property >= n && p->property < min_size)
ffffffffc020089e:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02008a2:	fed76be3          	bltu	a4,a3,ffffffffc0200898 <best_fit_alloc_pages+0x26>
ffffffffc02008a6:	feb779e3          	bleu	a1,a4,ffffffffc0200898 <best_fit_alloc_pages+0x26>
        struct Page *p = le2page(le, page_link);
ffffffffc02008aa:	fe878513          	addi	a0,a5,-24
ffffffffc02008ae:	679c                	ld	a5,8(a5)
ffffffffc02008b0:	85ba                	mv	a1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02008b2:	fec796e3          	bne	a5,a2,ffffffffc020089e <best_fit_alloc_pages+0x2c>
    if (best_fit_page != NULL)
ffffffffc02008b6:	c125                	beqz	a0,ffffffffc0200916 <best_fit_alloc_pages+0xa4>
    __list_del(listelm->prev, listelm->next);
ffffffffc02008b8:	7118                	ld	a4,32(a0)
ffffffffc02008ba:	6d0c                	ld	a1,24(a0)
        if (best_fit_page->property > n)
ffffffffc02008bc:	4910                	lw	a2,16(a0)
ffffffffc02008be:	0006889b          	sext.w	a7,a3
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next)
{
    prev->next = next;
ffffffffc02008c2:	e598                	sd	a4,8(a1)
    next->prev = prev;
ffffffffc02008c4:	e30c                	sd	a1,0(a4)
ffffffffc02008c6:	02061713          	slli	a4,a2,0x20
ffffffffc02008ca:	9301                	srli	a4,a4,0x20
ffffffffc02008cc:	02e6f863          	bleu	a4,a3,ffffffffc02008fc <best_fit_alloc_pages+0x8a>
            struct Page *p = best_fit_page + n;
ffffffffc02008d0:	00269713          	slli	a4,a3,0x2
ffffffffc02008d4:	9736                	add	a4,a4,a3
ffffffffc02008d6:	070e                	slli	a4,a4,0x3
ffffffffc02008d8:	972a                	add	a4,a4,a0
            p->property = best_fit_page->property - n;
ffffffffc02008da:	4116063b          	subw	a2,a2,a7
ffffffffc02008de:	cb10                	sw	a2,16(a4)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a **single-word(32bits)** quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) // 原子操作或1来设置一位（传入mod是__NOP表示掩码不变）
{
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02008e0:	4689                	li	a3,2
ffffffffc02008e2:	00870613          	addi	a2,a4,8
ffffffffc02008e6:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02008ea:	6394                	ld	a3,0(a5)
            list_add_before(&free_list, &(p->page_link));
ffffffffc02008ec:	01870613          	addi	a2,a4,24
    prev->next = next->prev = elm;
ffffffffc02008f0:	0107a803          	lw	a6,16(a5)
ffffffffc02008f4:	e690                	sd	a2,8(a3)
ffffffffc02008f6:	e390                	sd	a2,0(a5)
    elm->next = next;
ffffffffc02008f8:	f31c                	sd	a5,32(a4)
    elm->prev = prev;
ffffffffc02008fa:	ef14                	sd	a3,24(a4)
        nr_free -= n;
ffffffffc02008fc:	4118083b          	subw	a6,a6,a7
ffffffffc0200900:	00006797          	auipc	a5,0x6
ffffffffc0200904:	b507ac23          	sw	a6,-1192(a5) # ffffffffc0206458 <free_area+0x10>
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) // 原子操作与0来清除（传入mod是__NOT表示掩码取反）
{
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200908:	57f5                	li	a5,-3
ffffffffc020090a:	00850713          	addi	a4,a0,8
ffffffffc020090e:	60f7302f          	amoand.d	zero,a5,(a4)
ffffffffc0200912:	8082                	ret
        return NULL;
ffffffffc0200914:	4501                	li	a0,0
}
ffffffffc0200916:	8082                	ret
{
ffffffffc0200918:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020091a:	00002697          	auipc	a3,0x2
ffffffffc020091e:	af668693          	addi	a3,a3,-1290 # ffffffffc0202410 <commands+0x630>
ffffffffc0200922:	00002617          	auipc	a2,0x2
ffffffffc0200926:	af660613          	addi	a2,a2,-1290 # ffffffffc0202418 <commands+0x638>
ffffffffc020092a:	07600593          	li	a1,118
ffffffffc020092e:	00002517          	auipc	a0,0x2
ffffffffc0200932:	b0250513          	addi	a0,a0,-1278 # ffffffffc0202430 <commands+0x650>
{
ffffffffc0200936:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200938:	a75ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020093c <best_fit_check>:

// LAB2: below code is used to check the best fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void)
{
ffffffffc020093c:	715d                	addi	sp,sp,-80
ffffffffc020093e:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc0200940:	00006917          	auipc	s2,0x6
ffffffffc0200944:	b0890913          	addi	s2,s2,-1272 # ffffffffc0206448 <free_area>
ffffffffc0200948:	00893783          	ld	a5,8(s2)
ffffffffc020094c:	e486                	sd	ra,72(sp)
ffffffffc020094e:	e0a2                	sd	s0,64(sp)
ffffffffc0200950:	fc26                	sd	s1,56(sp)
ffffffffc0200952:	f44e                	sd	s3,40(sp)
ffffffffc0200954:	f052                	sd	s4,32(sp)
ffffffffc0200956:	ec56                	sd	s5,24(sp)
ffffffffc0200958:	e85a                	sd	s6,16(sp)
ffffffffc020095a:	e45e                	sd	s7,8(sp)
ffffffffc020095c:	e062                	sd	s8,0(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020095e:	2d278363          	beq	a5,s2,ffffffffc0200c24 <best_fit_check+0x2e8>
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr)
{
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200962:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200966:	8305                	srli	a4,a4,0x1
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200968:	8b05                	andi	a4,a4,1
ffffffffc020096a:	2c070163          	beqz	a4,ffffffffc0200c2c <best_fit_check+0x2f0>
    int count = 0, total = 0;
ffffffffc020096e:	4401                	li	s0,0
ffffffffc0200970:	4481                	li	s1,0
ffffffffc0200972:	a031                	j	ffffffffc020097e <best_fit_check+0x42>
ffffffffc0200974:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0200978:	8b09                	andi	a4,a4,2
ffffffffc020097a:	2a070963          	beqz	a4,ffffffffc0200c2c <best_fit_check+0x2f0>
        count++, total += p->property;
ffffffffc020097e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200982:	679c                	ld	a5,8(a5)
ffffffffc0200984:	2485                	addiw	s1,s1,1
ffffffffc0200986:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200988:	ff2796e3          	bne	a5,s2,ffffffffc0200974 <best_fit_check+0x38>
ffffffffc020098c:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc020098e:	1ef000ef          	jal	ra,ffffffffc020137c <nr_free_pages>
ffffffffc0200992:	37351d63          	bne	a0,s3,ffffffffc0200d0c <best_fit_check+0x3d0>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200996:	4505                	li	a0,1
ffffffffc0200998:	15b000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc020099c:	8a2a                	mv	s4,a0
ffffffffc020099e:	3a050763          	beqz	a0,ffffffffc0200d4c <best_fit_check+0x410>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02009a2:	4505                	li	a0,1
ffffffffc02009a4:	14f000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc02009a8:	89aa                	mv	s3,a0
ffffffffc02009aa:	38050163          	beqz	a0,ffffffffc0200d2c <best_fit_check+0x3f0>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009ae:	4505                	li	a0,1
ffffffffc02009b0:	143000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc02009b4:	8aaa                	mv	s5,a0
ffffffffc02009b6:	30050b63          	beqz	a0,ffffffffc0200ccc <best_fit_check+0x390>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02009ba:	293a0963          	beq	s4,s3,ffffffffc0200c4c <best_fit_check+0x310>
ffffffffc02009be:	28aa0763          	beq	s4,a0,ffffffffc0200c4c <best_fit_check+0x310>
ffffffffc02009c2:	28a98563          	beq	s3,a0,ffffffffc0200c4c <best_fit_check+0x310>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02009c6:	000a2783          	lw	a5,0(s4)
ffffffffc02009ca:	2a079163          	bnez	a5,ffffffffc0200c6c <best_fit_check+0x330>
ffffffffc02009ce:	0009a783          	lw	a5,0(s3)
ffffffffc02009d2:	28079d63          	bnez	a5,ffffffffc0200c6c <best_fit_check+0x330>
ffffffffc02009d6:	411c                	lw	a5,0(a0)
ffffffffc02009d8:	28079a63          	bnez	a5,ffffffffc0200c6c <best_fit_check+0x330>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } // page-pages是page的偏移量，加上nbase就是ppn（物理页编号）
ffffffffc02009dc:	00006797          	auipc	a5,0x6
ffffffffc02009e0:	a9c78793          	addi	a5,a5,-1380 # ffffffffc0206478 <pages>
ffffffffc02009e4:	639c                	ld	a5,0(a5)
ffffffffc02009e6:	00002717          	auipc	a4,0x2
ffffffffc02009ea:	a6270713          	addi	a4,a4,-1438 # ffffffffc0202448 <commands+0x668>
ffffffffc02009ee:	630c                	ld	a1,0(a4)
ffffffffc02009f0:	40fa0733          	sub	a4,s4,a5
ffffffffc02009f4:	870d                	srai	a4,a4,0x3
ffffffffc02009f6:	02b70733          	mul	a4,a4,a1
ffffffffc02009fa:	00002697          	auipc	a3,0x2
ffffffffc02009fe:	2d668693          	addi	a3,a3,726 # ffffffffc0202cd0 <nbase>
ffffffffc0200a02:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200a04:	00006697          	auipc	a3,0x6
ffffffffc0200a08:	a2468693          	addi	a3,a3,-1500 # ffffffffc0206428 <npage>
ffffffffc0200a0c:	6294                	ld	a3,0(a3)
ffffffffc0200a0e:	06b2                	slli	a3,a3,0xc
ffffffffc0200a10:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a12:	0732                	slli	a4,a4,0xc
ffffffffc0200a14:	26d77c63          	bleu	a3,a4,ffffffffc0200c8c <best_fit_check+0x350>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } // page-pages是page的偏移量，加上nbase就是ppn（物理页编号）
ffffffffc0200a18:	40f98733          	sub	a4,s3,a5
ffffffffc0200a1c:	870d                	srai	a4,a4,0x3
ffffffffc0200a1e:	02b70733          	mul	a4,a4,a1
ffffffffc0200a22:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a24:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200a26:	42d77363          	bleu	a3,a4,ffffffffc0200e4c <best_fit_check+0x510>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } // page-pages是page的偏移量，加上nbase就是ppn（物理页编号）
ffffffffc0200a2a:	40f507b3          	sub	a5,a0,a5
ffffffffc0200a2e:	878d                	srai	a5,a5,0x3
ffffffffc0200a30:	02b787b3          	mul	a5,a5,a1
ffffffffc0200a34:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a36:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200a38:	3ed7fa63          	bleu	a3,a5,ffffffffc0200e2c <best_fit_check+0x4f0>
    assert(alloc_page() == NULL);
ffffffffc0200a3c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200a3e:	00093c03          	ld	s8,0(s2)
ffffffffc0200a42:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200a46:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200a4a:	00006797          	auipc	a5,0x6
ffffffffc0200a4e:	a127b323          	sd	s2,-1530(a5) # ffffffffc0206450 <free_area+0x8>
ffffffffc0200a52:	00006797          	auipc	a5,0x6
ffffffffc0200a56:	9f27bb23          	sd	s2,-1546(a5) # ffffffffc0206448 <free_area>
    nr_free = 0;
ffffffffc0200a5a:	00006797          	auipc	a5,0x6
ffffffffc0200a5e:	9e07af23          	sw	zero,-1538(a5) # ffffffffc0206458 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200a62:	091000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200a66:	3a051363          	bnez	a0,ffffffffc0200e0c <best_fit_check+0x4d0>
    free_page(p0);
ffffffffc0200a6a:	4585                	li	a1,1
ffffffffc0200a6c:	8552                	mv	a0,s4
ffffffffc0200a6e:	0c9000ef          	jal	ra,ffffffffc0201336 <free_pages>
    free_page(p1);
ffffffffc0200a72:	4585                	li	a1,1
ffffffffc0200a74:	854e                	mv	a0,s3
ffffffffc0200a76:	0c1000ef          	jal	ra,ffffffffc0201336 <free_pages>
    free_page(p2);
ffffffffc0200a7a:	4585                	li	a1,1
ffffffffc0200a7c:	8556                	mv	a0,s5
ffffffffc0200a7e:	0b9000ef          	jal	ra,ffffffffc0201336 <free_pages>
    assert(nr_free == 3);
ffffffffc0200a82:	01092703          	lw	a4,16(s2)
ffffffffc0200a86:	478d                	li	a5,3
ffffffffc0200a88:	36f71263          	bne	a4,a5,ffffffffc0200dec <best_fit_check+0x4b0>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a8c:	4505                	li	a0,1
ffffffffc0200a8e:	065000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200a92:	89aa                	mv	s3,a0
ffffffffc0200a94:	32050c63          	beqz	a0,ffffffffc0200dcc <best_fit_check+0x490>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a98:	4505                	li	a0,1
ffffffffc0200a9a:	059000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200a9e:	8aaa                	mv	s5,a0
ffffffffc0200aa0:	30050663          	beqz	a0,ffffffffc0200dac <best_fit_check+0x470>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200aa4:	4505                	li	a0,1
ffffffffc0200aa6:	04d000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200aaa:	8a2a                	mv	s4,a0
ffffffffc0200aac:	2e050063          	beqz	a0,ffffffffc0200d8c <best_fit_check+0x450>
    assert(alloc_page() == NULL);
ffffffffc0200ab0:	4505                	li	a0,1
ffffffffc0200ab2:	041000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200ab6:	2a051b63          	bnez	a0,ffffffffc0200d6c <best_fit_check+0x430>
    free_page(p0);
ffffffffc0200aba:	4585                	li	a1,1
ffffffffc0200abc:	854e                	mv	a0,s3
ffffffffc0200abe:	079000ef          	jal	ra,ffffffffc0201336 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200ac2:	00893783          	ld	a5,8(s2)
ffffffffc0200ac6:	1f278363          	beq	a5,s2,ffffffffc0200cac <best_fit_check+0x370>
    assert((p = alloc_page()) == p0);
ffffffffc0200aca:	4505                	li	a0,1
ffffffffc0200acc:	027000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200ad0:	54a99e63          	bne	s3,a0,ffffffffc020102c <best_fit_check+0x6f0>
    assert(alloc_page() == NULL);
ffffffffc0200ad4:	4505                	li	a0,1
ffffffffc0200ad6:	01d000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200ada:	52051963          	bnez	a0,ffffffffc020100c <best_fit_check+0x6d0>
    assert(nr_free == 0);
ffffffffc0200ade:	01092783          	lw	a5,16(s2)
ffffffffc0200ae2:	50079563          	bnez	a5,ffffffffc0200fec <best_fit_check+0x6b0>
    free_page(p);
ffffffffc0200ae6:	854e                	mv	a0,s3
ffffffffc0200ae8:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200aea:	00006797          	auipc	a5,0x6
ffffffffc0200aee:	9587bf23          	sd	s8,-1698(a5) # ffffffffc0206448 <free_area>
ffffffffc0200af2:	00006797          	auipc	a5,0x6
ffffffffc0200af6:	9577bf23          	sd	s7,-1698(a5) # ffffffffc0206450 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0200afa:	00006797          	auipc	a5,0x6
ffffffffc0200afe:	9567af23          	sw	s6,-1698(a5) # ffffffffc0206458 <free_area+0x10>
    free_page(p);
ffffffffc0200b02:	035000ef          	jal	ra,ffffffffc0201336 <free_pages>
    free_page(p1);
ffffffffc0200b06:	4585                	li	a1,1
ffffffffc0200b08:	8556                	mv	a0,s5
ffffffffc0200b0a:	02d000ef          	jal	ra,ffffffffc0201336 <free_pages>
    free_page(p2);
ffffffffc0200b0e:	4585                	li	a1,1
ffffffffc0200b10:	8552                	mv	a0,s4
ffffffffc0200b12:	025000ef          	jal	ra,ffffffffc0201336 <free_pages>

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200b16:	4515                	li	a0,5
ffffffffc0200b18:	7da000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200b1c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200b1e:	4a050763          	beqz	a0,ffffffffc0200fcc <best_fit_check+0x690>
ffffffffc0200b22:	651c                	ld	a5,8(a0)
ffffffffc0200b24:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200b26:	8b85                	andi	a5,a5,1
ffffffffc0200b28:	48079263          	bnez	a5,ffffffffc0200fac <best_fit_check+0x670>
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200b2c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200b2e:	00093b03          	ld	s6,0(s2)
ffffffffc0200b32:	00893a83          	ld	s5,8(s2)
ffffffffc0200b36:	00006797          	auipc	a5,0x6
ffffffffc0200b3a:	9127b923          	sd	s2,-1774(a5) # ffffffffc0206448 <free_area>
ffffffffc0200b3e:	00006797          	auipc	a5,0x6
ffffffffc0200b42:	9127b923          	sd	s2,-1774(a5) # ffffffffc0206450 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200b46:	7ac000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200b4a:	44051163          	bnez	a0,ffffffffc0200f8c <best_fit_check+0x650>
#endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200b4e:	4589                	li	a1,2
ffffffffc0200b50:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200b54:	01092b83          	lw	s7,16(s2)
    free_pages(p0 + 4, 1);
ffffffffc0200b58:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200b5c:	00006797          	auipc	a5,0x6
ffffffffc0200b60:	8e07ae23          	sw	zero,-1796(a5) # ffffffffc0206458 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200b64:	7d2000ef          	jal	ra,ffffffffc0201336 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200b68:	8562                	mv	a0,s8
ffffffffc0200b6a:	4585                	li	a1,1
ffffffffc0200b6c:	7ca000ef          	jal	ra,ffffffffc0201336 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200b70:	4511                	li	a0,4
ffffffffc0200b72:	780000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200b76:	3e051b63          	bnez	a0,ffffffffc0200f6c <best_fit_check+0x630>
ffffffffc0200b7a:	0309b783          	ld	a5,48(s3)
ffffffffc0200b7e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200b80:	8b85                	andi	a5,a5,1
ffffffffc0200b82:	3c078563          	beqz	a5,ffffffffc0200f4c <best_fit_check+0x610>
ffffffffc0200b86:	0389a703          	lw	a4,56(s3)
ffffffffc0200b8a:	4789                	li	a5,2
ffffffffc0200b8c:	3cf71063          	bne	a4,a5,ffffffffc0200f4c <best_fit_check+0x610>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200b90:	4505                	li	a0,1
ffffffffc0200b92:	760000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200b96:	8a2a                	mv	s4,a0
ffffffffc0200b98:	38050a63          	beqz	a0,ffffffffc0200f2c <best_fit_check+0x5f0>
    assert(alloc_pages(2) != NULL); // best fit feature
ffffffffc0200b9c:	4509                	li	a0,2
ffffffffc0200b9e:	754000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200ba2:	36050563          	beqz	a0,ffffffffc0200f0c <best_fit_check+0x5d0>
    assert(p0 + 4 == p1);
ffffffffc0200ba6:	354c1363          	bne	s8,s4,ffffffffc0200eec <best_fit_check+0x5b0>
#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200baa:	854e                	mv	a0,s3
ffffffffc0200bac:	4595                	li	a1,5
ffffffffc0200bae:	788000ef          	jal	ra,ffffffffc0201336 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200bb2:	4515                	li	a0,5
ffffffffc0200bb4:	73e000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200bb8:	89aa                	mv	s3,a0
ffffffffc0200bba:	30050963          	beqz	a0,ffffffffc0200ecc <best_fit_check+0x590>
    assert(alloc_page() == NULL);
ffffffffc0200bbe:	4505                	li	a0,1
ffffffffc0200bc0:	732000ef          	jal	ra,ffffffffc02012f2 <alloc_pages>
ffffffffc0200bc4:	2e051463          	bnez	a0,ffffffffc0200eac <best_fit_check+0x570>

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    assert(nr_free == 0);
ffffffffc0200bc8:	01092783          	lw	a5,16(s2)
ffffffffc0200bcc:	2c079063          	bnez	a5,ffffffffc0200e8c <best_fit_check+0x550>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200bd0:	4595                	li	a1,5
ffffffffc0200bd2:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200bd4:	00006797          	auipc	a5,0x6
ffffffffc0200bd8:	8977a223          	sw	s7,-1916(a5) # ffffffffc0206458 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0200bdc:	00006797          	auipc	a5,0x6
ffffffffc0200be0:	8767b623          	sd	s6,-1940(a5) # ffffffffc0206448 <free_area>
ffffffffc0200be4:	00006797          	auipc	a5,0x6
ffffffffc0200be8:	8757b623          	sd	s5,-1940(a5) # ffffffffc0206450 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0200bec:	74a000ef          	jal	ra,ffffffffc0201336 <free_pages>
    return listelm->next;
ffffffffc0200bf0:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200bf4:	01278963          	beq	a5,s2,ffffffffc0200c06 <best_fit_check+0x2ca>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0200bf8:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200bfc:	679c                	ld	a5,8(a5)
ffffffffc0200bfe:	34fd                	addiw	s1,s1,-1
ffffffffc0200c00:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200c02:	ff279be3          	bne	a5,s2,ffffffffc0200bf8 <best_fit_check+0x2bc>
    }
    assert(count == 0);
ffffffffc0200c06:	26049363          	bnez	s1,ffffffffc0200e6c <best_fit_check+0x530>
    assert(total == 0);
ffffffffc0200c0a:	e06d                	bnez	s0,ffffffffc0200cec <best_fit_check+0x3b0>
#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
}
ffffffffc0200c0c:	60a6                	ld	ra,72(sp)
ffffffffc0200c0e:	6406                	ld	s0,64(sp)
ffffffffc0200c10:	74e2                	ld	s1,56(sp)
ffffffffc0200c12:	7942                	ld	s2,48(sp)
ffffffffc0200c14:	79a2                	ld	s3,40(sp)
ffffffffc0200c16:	7a02                	ld	s4,32(sp)
ffffffffc0200c18:	6ae2                	ld	s5,24(sp)
ffffffffc0200c1a:	6b42                	ld	s6,16(sp)
ffffffffc0200c1c:	6ba2                	ld	s7,8(sp)
ffffffffc0200c1e:	6c02                	ld	s8,0(sp)
ffffffffc0200c20:	6161                	addi	sp,sp,80
ffffffffc0200c22:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0200c24:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200c26:	4401                	li	s0,0
ffffffffc0200c28:	4481                	li	s1,0
ffffffffc0200c2a:	b395                	j	ffffffffc020098e <best_fit_check+0x52>
        assert(PageProperty(p));
ffffffffc0200c2c:	00002697          	auipc	a3,0x2
ffffffffc0200c30:	82468693          	addi	a3,a3,-2012 # ffffffffc0202450 <commands+0x670>
ffffffffc0200c34:	00001617          	auipc	a2,0x1
ffffffffc0200c38:	7e460613          	addi	a2,a2,2020 # ffffffffc0202418 <commands+0x638>
ffffffffc0200c3c:	13100593          	li	a1,305
ffffffffc0200c40:	00001517          	auipc	a0,0x1
ffffffffc0200c44:	7f050513          	addi	a0,a0,2032 # ffffffffc0202430 <commands+0x650>
ffffffffc0200c48:	f64ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c4c:	00002697          	auipc	a3,0x2
ffffffffc0200c50:	89468693          	addi	a3,a3,-1900 # ffffffffc02024e0 <commands+0x700>
ffffffffc0200c54:	00001617          	auipc	a2,0x1
ffffffffc0200c58:	7c460613          	addi	a2,a2,1988 # ffffffffc0202418 <commands+0x638>
ffffffffc0200c5c:	0fb00593          	li	a1,251
ffffffffc0200c60:	00001517          	auipc	a0,0x1
ffffffffc0200c64:	7d050513          	addi	a0,a0,2000 # ffffffffc0202430 <commands+0x650>
ffffffffc0200c68:	f44ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c6c:	00002697          	auipc	a3,0x2
ffffffffc0200c70:	89c68693          	addi	a3,a3,-1892 # ffffffffc0202508 <commands+0x728>
ffffffffc0200c74:	00001617          	auipc	a2,0x1
ffffffffc0200c78:	7a460613          	addi	a2,a2,1956 # ffffffffc0202418 <commands+0x638>
ffffffffc0200c7c:	0fc00593          	li	a1,252
ffffffffc0200c80:	00001517          	auipc	a0,0x1
ffffffffc0200c84:	7b050513          	addi	a0,a0,1968 # ffffffffc0202430 <commands+0x650>
ffffffffc0200c88:	f24ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200c8c:	00002697          	auipc	a3,0x2
ffffffffc0200c90:	8bc68693          	addi	a3,a3,-1860 # ffffffffc0202548 <commands+0x768>
ffffffffc0200c94:	00001617          	auipc	a2,0x1
ffffffffc0200c98:	78460613          	addi	a2,a2,1924 # ffffffffc0202418 <commands+0x638>
ffffffffc0200c9c:	0fe00593          	li	a1,254
ffffffffc0200ca0:	00001517          	auipc	a0,0x1
ffffffffc0200ca4:	79050513          	addi	a0,a0,1936 # ffffffffc0202430 <commands+0x650>
ffffffffc0200ca8:	f04ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200cac:	00002697          	auipc	a3,0x2
ffffffffc0200cb0:	92468693          	addi	a3,a3,-1756 # ffffffffc02025d0 <commands+0x7f0>
ffffffffc0200cb4:	00001617          	auipc	a2,0x1
ffffffffc0200cb8:	76460613          	addi	a2,a2,1892 # ffffffffc0202418 <commands+0x638>
ffffffffc0200cbc:	11700593          	li	a1,279
ffffffffc0200cc0:	00001517          	auipc	a0,0x1
ffffffffc0200cc4:	77050513          	addi	a0,a0,1904 # ffffffffc0202430 <commands+0x650>
ffffffffc0200cc8:	ee4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ccc:	00001697          	auipc	a3,0x1
ffffffffc0200cd0:	7f468693          	addi	a3,a3,2036 # ffffffffc02024c0 <commands+0x6e0>
ffffffffc0200cd4:	00001617          	auipc	a2,0x1
ffffffffc0200cd8:	74460613          	addi	a2,a2,1860 # ffffffffc0202418 <commands+0x638>
ffffffffc0200cdc:	0f900593          	li	a1,249
ffffffffc0200ce0:	00001517          	auipc	a0,0x1
ffffffffc0200ce4:	75050513          	addi	a0,a0,1872 # ffffffffc0202430 <commands+0x650>
ffffffffc0200ce8:	ec4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total == 0);
ffffffffc0200cec:	00002697          	auipc	a3,0x2
ffffffffc0200cf0:	a1468693          	addi	a3,a3,-1516 # ffffffffc0202700 <commands+0x920>
ffffffffc0200cf4:	00001617          	auipc	a2,0x1
ffffffffc0200cf8:	72460613          	addi	a2,a2,1828 # ffffffffc0202418 <commands+0x638>
ffffffffc0200cfc:	17400593          	li	a1,372
ffffffffc0200d00:	00001517          	auipc	a0,0x1
ffffffffc0200d04:	73050513          	addi	a0,a0,1840 # ffffffffc0202430 <commands+0x650>
ffffffffc0200d08:	ea4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(total == nr_free_pages());
ffffffffc0200d0c:	00001697          	auipc	a3,0x1
ffffffffc0200d10:	75468693          	addi	a3,a3,1876 # ffffffffc0202460 <commands+0x680>
ffffffffc0200d14:	00001617          	auipc	a2,0x1
ffffffffc0200d18:	70460613          	addi	a2,a2,1796 # ffffffffc0202418 <commands+0x638>
ffffffffc0200d1c:	13400593          	li	a1,308
ffffffffc0200d20:	00001517          	auipc	a0,0x1
ffffffffc0200d24:	71050513          	addi	a0,a0,1808 # ffffffffc0202430 <commands+0x650>
ffffffffc0200d28:	e84ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d2c:	00001697          	auipc	a3,0x1
ffffffffc0200d30:	77468693          	addi	a3,a3,1908 # ffffffffc02024a0 <commands+0x6c0>
ffffffffc0200d34:	00001617          	auipc	a2,0x1
ffffffffc0200d38:	6e460613          	addi	a2,a2,1764 # ffffffffc0202418 <commands+0x638>
ffffffffc0200d3c:	0f800593          	li	a1,248
ffffffffc0200d40:	00001517          	auipc	a0,0x1
ffffffffc0200d44:	6f050513          	addi	a0,a0,1776 # ffffffffc0202430 <commands+0x650>
ffffffffc0200d48:	e64ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d4c:	00001697          	auipc	a3,0x1
ffffffffc0200d50:	73468693          	addi	a3,a3,1844 # ffffffffc0202480 <commands+0x6a0>
ffffffffc0200d54:	00001617          	auipc	a2,0x1
ffffffffc0200d58:	6c460613          	addi	a2,a2,1732 # ffffffffc0202418 <commands+0x638>
ffffffffc0200d5c:	0f700593          	li	a1,247
ffffffffc0200d60:	00001517          	auipc	a0,0x1
ffffffffc0200d64:	6d050513          	addi	a0,a0,1744 # ffffffffc0202430 <commands+0x650>
ffffffffc0200d68:	e44ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d6c:	00002697          	auipc	a3,0x2
ffffffffc0200d70:	83c68693          	addi	a3,a3,-1988 # ffffffffc02025a8 <commands+0x7c8>
ffffffffc0200d74:	00001617          	auipc	a2,0x1
ffffffffc0200d78:	6a460613          	addi	a2,a2,1700 # ffffffffc0202418 <commands+0x638>
ffffffffc0200d7c:	11400593          	li	a1,276
ffffffffc0200d80:	00001517          	auipc	a0,0x1
ffffffffc0200d84:	6b050513          	addi	a0,a0,1712 # ffffffffc0202430 <commands+0x650>
ffffffffc0200d88:	e24ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d8c:	00001697          	auipc	a3,0x1
ffffffffc0200d90:	73468693          	addi	a3,a3,1844 # ffffffffc02024c0 <commands+0x6e0>
ffffffffc0200d94:	00001617          	auipc	a2,0x1
ffffffffc0200d98:	68460613          	addi	a2,a2,1668 # ffffffffc0202418 <commands+0x638>
ffffffffc0200d9c:	11200593          	li	a1,274
ffffffffc0200da0:	00001517          	auipc	a0,0x1
ffffffffc0200da4:	69050513          	addi	a0,a0,1680 # ffffffffc0202430 <commands+0x650>
ffffffffc0200da8:	e04ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200dac:	00001697          	auipc	a3,0x1
ffffffffc0200db0:	6f468693          	addi	a3,a3,1780 # ffffffffc02024a0 <commands+0x6c0>
ffffffffc0200db4:	00001617          	auipc	a2,0x1
ffffffffc0200db8:	66460613          	addi	a2,a2,1636 # ffffffffc0202418 <commands+0x638>
ffffffffc0200dbc:	11100593          	li	a1,273
ffffffffc0200dc0:	00001517          	auipc	a0,0x1
ffffffffc0200dc4:	67050513          	addi	a0,a0,1648 # ffffffffc0202430 <commands+0x650>
ffffffffc0200dc8:	de4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200dcc:	00001697          	auipc	a3,0x1
ffffffffc0200dd0:	6b468693          	addi	a3,a3,1716 # ffffffffc0202480 <commands+0x6a0>
ffffffffc0200dd4:	00001617          	auipc	a2,0x1
ffffffffc0200dd8:	64460613          	addi	a2,a2,1604 # ffffffffc0202418 <commands+0x638>
ffffffffc0200ddc:	11000593          	li	a1,272
ffffffffc0200de0:	00001517          	auipc	a0,0x1
ffffffffc0200de4:	65050513          	addi	a0,a0,1616 # ffffffffc0202430 <commands+0x650>
ffffffffc0200de8:	dc4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 3);
ffffffffc0200dec:	00001697          	auipc	a3,0x1
ffffffffc0200df0:	7d468693          	addi	a3,a3,2004 # ffffffffc02025c0 <commands+0x7e0>
ffffffffc0200df4:	00001617          	auipc	a2,0x1
ffffffffc0200df8:	62460613          	addi	a2,a2,1572 # ffffffffc0202418 <commands+0x638>
ffffffffc0200dfc:	10e00593          	li	a1,270
ffffffffc0200e00:	00001517          	auipc	a0,0x1
ffffffffc0200e04:	63050513          	addi	a0,a0,1584 # ffffffffc0202430 <commands+0x650>
ffffffffc0200e08:	da4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e0c:	00001697          	auipc	a3,0x1
ffffffffc0200e10:	79c68693          	addi	a3,a3,1948 # ffffffffc02025a8 <commands+0x7c8>
ffffffffc0200e14:	00001617          	auipc	a2,0x1
ffffffffc0200e18:	60460613          	addi	a2,a2,1540 # ffffffffc0202418 <commands+0x638>
ffffffffc0200e1c:	10900593          	li	a1,265
ffffffffc0200e20:	00001517          	auipc	a0,0x1
ffffffffc0200e24:	61050513          	addi	a0,a0,1552 # ffffffffc0202430 <commands+0x650>
ffffffffc0200e28:	d84ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e2c:	00001697          	auipc	a3,0x1
ffffffffc0200e30:	75c68693          	addi	a3,a3,1884 # ffffffffc0202588 <commands+0x7a8>
ffffffffc0200e34:	00001617          	auipc	a2,0x1
ffffffffc0200e38:	5e460613          	addi	a2,a2,1508 # ffffffffc0202418 <commands+0x638>
ffffffffc0200e3c:	10000593          	li	a1,256
ffffffffc0200e40:	00001517          	auipc	a0,0x1
ffffffffc0200e44:	5f050513          	addi	a0,a0,1520 # ffffffffc0202430 <commands+0x650>
ffffffffc0200e48:	d64ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e4c:	00001697          	auipc	a3,0x1
ffffffffc0200e50:	71c68693          	addi	a3,a3,1820 # ffffffffc0202568 <commands+0x788>
ffffffffc0200e54:	00001617          	auipc	a2,0x1
ffffffffc0200e58:	5c460613          	addi	a2,a2,1476 # ffffffffc0202418 <commands+0x638>
ffffffffc0200e5c:	0ff00593          	li	a1,255
ffffffffc0200e60:	00001517          	auipc	a0,0x1
ffffffffc0200e64:	5d050513          	addi	a0,a0,1488 # ffffffffc0202430 <commands+0x650>
ffffffffc0200e68:	d44ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(count == 0);
ffffffffc0200e6c:	00002697          	auipc	a3,0x2
ffffffffc0200e70:	88468693          	addi	a3,a3,-1916 # ffffffffc02026f0 <commands+0x910>
ffffffffc0200e74:	00001617          	auipc	a2,0x1
ffffffffc0200e78:	5a460613          	addi	a2,a2,1444 # ffffffffc0202418 <commands+0x638>
ffffffffc0200e7c:	17300593          	li	a1,371
ffffffffc0200e80:	00001517          	auipc	a0,0x1
ffffffffc0200e84:	5b050513          	addi	a0,a0,1456 # ffffffffc0202430 <commands+0x650>
ffffffffc0200e88:	d24ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200e8c:	00001697          	auipc	a3,0x1
ffffffffc0200e90:	77c68693          	addi	a3,a3,1916 # ffffffffc0202608 <commands+0x828>
ffffffffc0200e94:	00001617          	auipc	a2,0x1
ffffffffc0200e98:	58460613          	addi	a2,a2,1412 # ffffffffc0202418 <commands+0x638>
ffffffffc0200e9c:	16700593          	li	a1,359
ffffffffc0200ea0:	00001517          	auipc	a0,0x1
ffffffffc0200ea4:	59050513          	addi	a0,a0,1424 # ffffffffc0202430 <commands+0x650>
ffffffffc0200ea8:	d04ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200eac:	00001697          	auipc	a3,0x1
ffffffffc0200eb0:	6fc68693          	addi	a3,a3,1788 # ffffffffc02025a8 <commands+0x7c8>
ffffffffc0200eb4:	00001617          	auipc	a2,0x1
ffffffffc0200eb8:	56460613          	addi	a2,a2,1380 # ffffffffc0202418 <commands+0x638>
ffffffffc0200ebc:	16100593          	li	a1,353
ffffffffc0200ec0:	00001517          	auipc	a0,0x1
ffffffffc0200ec4:	57050513          	addi	a0,a0,1392 # ffffffffc0202430 <commands+0x650>
ffffffffc0200ec8:	ce4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200ecc:	00002697          	auipc	a3,0x2
ffffffffc0200ed0:	80468693          	addi	a3,a3,-2044 # ffffffffc02026d0 <commands+0x8f0>
ffffffffc0200ed4:	00001617          	auipc	a2,0x1
ffffffffc0200ed8:	54460613          	addi	a2,a2,1348 # ffffffffc0202418 <commands+0x638>
ffffffffc0200edc:	16000593          	li	a1,352
ffffffffc0200ee0:	00001517          	auipc	a0,0x1
ffffffffc0200ee4:	55050513          	addi	a0,a0,1360 # ffffffffc0202430 <commands+0x650>
ffffffffc0200ee8:	cc4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200eec:	00001697          	auipc	a3,0x1
ffffffffc0200ef0:	7d468693          	addi	a3,a3,2004 # ffffffffc02026c0 <commands+0x8e0>
ffffffffc0200ef4:	00001617          	auipc	a2,0x1
ffffffffc0200ef8:	52460613          	addi	a2,a2,1316 # ffffffffc0202418 <commands+0x638>
ffffffffc0200efc:	15800593          	li	a1,344
ffffffffc0200f00:	00001517          	auipc	a0,0x1
ffffffffc0200f04:	53050513          	addi	a0,a0,1328 # ffffffffc0202430 <commands+0x650>
ffffffffc0200f08:	ca4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(2) != NULL); // best fit feature
ffffffffc0200f0c:	00001697          	auipc	a3,0x1
ffffffffc0200f10:	79c68693          	addi	a3,a3,1948 # ffffffffc02026a8 <commands+0x8c8>
ffffffffc0200f14:	00001617          	auipc	a2,0x1
ffffffffc0200f18:	50460613          	addi	a2,a2,1284 # ffffffffc0202418 <commands+0x638>
ffffffffc0200f1c:	15700593          	li	a1,343
ffffffffc0200f20:	00001517          	auipc	a0,0x1
ffffffffc0200f24:	51050513          	addi	a0,a0,1296 # ffffffffc0202430 <commands+0x650>
ffffffffc0200f28:	c84ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200f2c:	00001697          	auipc	a3,0x1
ffffffffc0200f30:	75c68693          	addi	a3,a3,1884 # ffffffffc0202688 <commands+0x8a8>
ffffffffc0200f34:	00001617          	auipc	a2,0x1
ffffffffc0200f38:	4e460613          	addi	a2,a2,1252 # ffffffffc0202418 <commands+0x638>
ffffffffc0200f3c:	15600593          	li	a1,342
ffffffffc0200f40:	00001517          	auipc	a0,0x1
ffffffffc0200f44:	4f050513          	addi	a0,a0,1264 # ffffffffc0202430 <commands+0x650>
ffffffffc0200f48:	c64ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200f4c:	00001697          	auipc	a3,0x1
ffffffffc0200f50:	70c68693          	addi	a3,a3,1804 # ffffffffc0202658 <commands+0x878>
ffffffffc0200f54:	00001617          	auipc	a2,0x1
ffffffffc0200f58:	4c460613          	addi	a2,a2,1220 # ffffffffc0202418 <commands+0x638>
ffffffffc0200f5c:	15400593          	li	a1,340
ffffffffc0200f60:	00001517          	auipc	a0,0x1
ffffffffc0200f64:	4d050513          	addi	a0,a0,1232 # ffffffffc0202430 <commands+0x650>
ffffffffc0200f68:	c44ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f6c:	00001697          	auipc	a3,0x1
ffffffffc0200f70:	6d468693          	addi	a3,a3,1748 # ffffffffc0202640 <commands+0x860>
ffffffffc0200f74:	00001617          	auipc	a2,0x1
ffffffffc0200f78:	4a460613          	addi	a2,a2,1188 # ffffffffc0202418 <commands+0x638>
ffffffffc0200f7c:	15300593          	li	a1,339
ffffffffc0200f80:	00001517          	auipc	a0,0x1
ffffffffc0200f84:	4b050513          	addi	a0,a0,1200 # ffffffffc0202430 <commands+0x650>
ffffffffc0200f88:	c24ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f8c:	00001697          	auipc	a3,0x1
ffffffffc0200f90:	61c68693          	addi	a3,a3,1564 # ffffffffc02025a8 <commands+0x7c8>
ffffffffc0200f94:	00001617          	auipc	a2,0x1
ffffffffc0200f98:	48460613          	addi	a2,a2,1156 # ffffffffc0202418 <commands+0x638>
ffffffffc0200f9c:	14700593          	li	a1,327
ffffffffc0200fa0:	00001517          	auipc	a0,0x1
ffffffffc0200fa4:	49050513          	addi	a0,a0,1168 # ffffffffc0202430 <commands+0x650>
ffffffffc0200fa8:	c04ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageProperty(p0));
ffffffffc0200fac:	00001697          	auipc	a3,0x1
ffffffffc0200fb0:	67c68693          	addi	a3,a3,1660 # ffffffffc0202628 <commands+0x848>
ffffffffc0200fb4:	00001617          	auipc	a2,0x1
ffffffffc0200fb8:	46460613          	addi	a2,a2,1124 # ffffffffc0202418 <commands+0x638>
ffffffffc0200fbc:	13e00593          	li	a1,318
ffffffffc0200fc0:	00001517          	auipc	a0,0x1
ffffffffc0200fc4:	47050513          	addi	a0,a0,1136 # ffffffffc0202430 <commands+0x650>
ffffffffc0200fc8:	be4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != NULL);
ffffffffc0200fcc:	00001697          	auipc	a3,0x1
ffffffffc0200fd0:	64c68693          	addi	a3,a3,1612 # ffffffffc0202618 <commands+0x838>
ffffffffc0200fd4:	00001617          	auipc	a2,0x1
ffffffffc0200fd8:	44460613          	addi	a2,a2,1092 # ffffffffc0202418 <commands+0x638>
ffffffffc0200fdc:	13d00593          	li	a1,317
ffffffffc0200fe0:	00001517          	auipc	a0,0x1
ffffffffc0200fe4:	45050513          	addi	a0,a0,1104 # ffffffffc0202430 <commands+0x650>
ffffffffc0200fe8:	bc4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free == 0);
ffffffffc0200fec:	00001697          	auipc	a3,0x1
ffffffffc0200ff0:	61c68693          	addi	a3,a3,1564 # ffffffffc0202608 <commands+0x828>
ffffffffc0200ff4:	00001617          	auipc	a2,0x1
ffffffffc0200ff8:	42460613          	addi	a2,a2,1060 # ffffffffc0202418 <commands+0x638>
ffffffffc0200ffc:	11d00593          	li	a1,285
ffffffffc0201000:	00001517          	auipc	a0,0x1
ffffffffc0201004:	43050513          	addi	a0,a0,1072 # ffffffffc0202430 <commands+0x650>
ffffffffc0201008:	ba4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc020100c:	00001697          	auipc	a3,0x1
ffffffffc0201010:	59c68693          	addi	a3,a3,1436 # ffffffffc02025a8 <commands+0x7c8>
ffffffffc0201014:	00001617          	auipc	a2,0x1
ffffffffc0201018:	40460613          	addi	a2,a2,1028 # ffffffffc0202418 <commands+0x638>
ffffffffc020101c:	11b00593          	li	a1,283
ffffffffc0201020:	00001517          	auipc	a0,0x1
ffffffffc0201024:	41050513          	addi	a0,a0,1040 # ffffffffc0202430 <commands+0x650>
ffffffffc0201028:	b84ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020102c:	00001697          	auipc	a3,0x1
ffffffffc0201030:	5bc68693          	addi	a3,a3,1468 # ffffffffc02025e8 <commands+0x808>
ffffffffc0201034:	00001617          	auipc	a2,0x1
ffffffffc0201038:	3e460613          	addi	a2,a2,996 # ffffffffc0202418 <commands+0x638>
ffffffffc020103c:	11a00593          	li	a1,282
ffffffffc0201040:	00001517          	auipc	a0,0x1
ffffffffc0201044:	3f050513          	addi	a0,a0,1008 # ffffffffc0202430 <commands+0x650>
ffffffffc0201048:	b64ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020104c <best_fit_free_pages>:
{
ffffffffc020104c:	1141                	addi	sp,sp,-16
ffffffffc020104e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201050:	18058063          	beqz	a1,ffffffffc02011d0 <best_fit_free_pages+0x184>
    for (; p != base + n; p++)
ffffffffc0201054:	00259693          	slli	a3,a1,0x2
ffffffffc0201058:	96ae                	add	a3,a3,a1
ffffffffc020105a:	068e                	slli	a3,a3,0x3
ffffffffc020105c:	96aa                	add	a3,a3,a0
ffffffffc020105e:	02d50d63          	beq	a0,a3,ffffffffc0201098 <best_fit_free_pages+0x4c>
ffffffffc0201062:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201064:	8b85                	andi	a5,a5,1
ffffffffc0201066:	14079563          	bnez	a5,ffffffffc02011b0 <best_fit_free_pages+0x164>
ffffffffc020106a:	651c                	ld	a5,8(a0)
ffffffffc020106c:	8385                	srli	a5,a5,0x1
ffffffffc020106e:	8b85                	andi	a5,a5,1
ffffffffc0201070:	14079063          	bnez	a5,ffffffffc02011b0 <best_fit_free_pages+0x164>
ffffffffc0201074:	87aa                	mv	a5,a0
ffffffffc0201076:	a809                	j	ffffffffc0201088 <best_fit_free_pages+0x3c>
ffffffffc0201078:	6798                	ld	a4,8(a5)
ffffffffc020107a:	8b05                	andi	a4,a4,1
ffffffffc020107c:	12071a63          	bnez	a4,ffffffffc02011b0 <best_fit_free_pages+0x164>
ffffffffc0201080:	6798                	ld	a4,8(a5)
ffffffffc0201082:	8b09                	andi	a4,a4,2
ffffffffc0201084:	12071663          	bnez	a4,ffffffffc02011b0 <best_fit_free_pages+0x164>
        p->flags = 0;
ffffffffc0201088:	0007b423          	sd	zero,8(a5)
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020108c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201090:	02878793          	addi	a5,a5,40
ffffffffc0201094:	fed792e3          	bne	a5,a3,ffffffffc0201078 <best_fit_free_pages+0x2c>
    base->property = n;
ffffffffc0201098:	2581                	sext.w	a1,a1
ffffffffc020109a:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020109c:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02010a0:	4789                	li	a5,2
ffffffffc02010a2:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02010a6:	00005697          	auipc	a3,0x5
ffffffffc02010aa:	3a268693          	addi	a3,a3,930 # ffffffffc0206448 <free_area>
ffffffffc02010ae:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02010b0:	669c                	ld	a5,8(a3)
ffffffffc02010b2:	9db9                	addw	a1,a1,a4
ffffffffc02010b4:	00005717          	auipc	a4,0x5
ffffffffc02010b8:	3ab72223          	sw	a1,932(a4) # ffffffffc0206458 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc02010bc:	08d78f63          	beq	a5,a3,ffffffffc020115a <best_fit_free_pages+0x10e>
            struct Page *page = le2page(le, page_link);
ffffffffc02010c0:	fe878713          	addi	a4,a5,-24
ffffffffc02010c4:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list))
ffffffffc02010c6:	4801                	li	a6,0
ffffffffc02010c8:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02010cc:	00e56a63          	bltu	a0,a4,ffffffffc02010e0 <best_fit_free_pages+0x94>
    return listelm->next;
ffffffffc02010d0:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02010d2:	02d70563          	beq	a4,a3,ffffffffc02010fc <best_fit_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list)
ffffffffc02010d6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02010d8:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02010dc:	fee57ae3          	bleu	a4,a0,ffffffffc02010d0 <best_fit_free_pages+0x84>
ffffffffc02010e0:	00080663          	beqz	a6,ffffffffc02010ec <best_fit_free_pages+0xa0>
ffffffffc02010e4:	00005817          	auipc	a6,0x5
ffffffffc02010e8:	36b83223          	sd	a1,868(a6) # ffffffffc0206448 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02010ec:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc02010ee:	e390                	sd	a2,0(a5)
ffffffffc02010f0:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc02010f2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02010f4:	ed0c                	sd	a1,24(a0)
    if (le != &free_list)
ffffffffc02010f6:	02d59163          	bne	a1,a3,ffffffffc0201118 <best_fit_free_pages+0xcc>
ffffffffc02010fa:	a091                	j	ffffffffc020113e <best_fit_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc02010fc:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02010fe:	f114                	sd	a3,32(a0)
ffffffffc0201100:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201102:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201104:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201106:	00d70563          	beq	a4,a3,ffffffffc0201110 <best_fit_free_pages+0xc4>
ffffffffc020110a:	4805                	li	a6,1
ffffffffc020110c:	87ba                	mv	a5,a4
ffffffffc020110e:	b7e9                	j	ffffffffc02010d8 <best_fit_free_pages+0x8c>
ffffffffc0201110:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201112:	85be                	mv	a1,a5
    if (le != &free_list)
ffffffffc0201114:	02d78163          	beq	a5,a3,ffffffffc0201136 <best_fit_free_pages+0xea>
        if (prev_page + prev_page->property == base)
ffffffffc0201118:	ff85a803          	lw	a6,-8(a1)
        struct Page *prev_page = le2page(le, page_link);
ffffffffc020111c:	fe858613          	addi	a2,a1,-24
        if (prev_page + prev_page->property == base)
ffffffffc0201120:	02081713          	slli	a4,a6,0x20
ffffffffc0201124:	9301                	srli	a4,a4,0x20
ffffffffc0201126:	00271793          	slli	a5,a4,0x2
ffffffffc020112a:	97ba                	add	a5,a5,a4
ffffffffc020112c:	078e                	slli	a5,a5,0x3
ffffffffc020112e:	97b2                	add	a5,a5,a2
ffffffffc0201130:	02f50e63          	beq	a0,a5,ffffffffc020116c <best_fit_free_pages+0x120>
ffffffffc0201134:	711c                	ld	a5,32(a0)
    if (next_le != &free_list)
ffffffffc0201136:	fe878713          	addi	a4,a5,-24
ffffffffc020113a:	00d78d63          	beq	a5,a3,ffffffffc0201154 <best_fit_free_pages+0x108>
        if (base + base->property == next_page)
ffffffffc020113e:	490c                	lw	a1,16(a0)
ffffffffc0201140:	02059613          	slli	a2,a1,0x20
ffffffffc0201144:	9201                	srli	a2,a2,0x20
ffffffffc0201146:	00261693          	slli	a3,a2,0x2
ffffffffc020114a:	96b2                	add	a3,a3,a2
ffffffffc020114c:	068e                	slli	a3,a3,0x3
ffffffffc020114e:	96aa                	add	a3,a3,a0
ffffffffc0201150:	04d70063          	beq	a4,a3,ffffffffc0201190 <best_fit_free_pages+0x144>
}
ffffffffc0201154:	60a2                	ld	ra,8(sp)
ffffffffc0201156:	0141                	addi	sp,sp,16
ffffffffc0201158:	8082                	ret
ffffffffc020115a:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020115c:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201160:	e398                	sd	a4,0(a5)
ffffffffc0201162:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201164:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201166:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201168:	0141                	addi	sp,sp,16
ffffffffc020116a:	8082                	ret
            prev_page->property += base->property;
ffffffffc020116c:	491c                	lw	a5,16(a0)
ffffffffc020116e:	0107883b          	addw	a6,a5,a6
ffffffffc0201172:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201176:	57f5                	li	a5,-3
ffffffffc0201178:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020117c:	01853803          	ld	a6,24(a0)
ffffffffc0201180:	7118                	ld	a4,32(a0)
            base = prev_page;
ffffffffc0201182:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0201184:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0201188:	659c                	ld	a5,8(a1)
ffffffffc020118a:	01073023          	sd	a6,0(a4)
ffffffffc020118e:	b765                	j	ffffffffc0201136 <best_fit_free_pages+0xea>
            base->property += next_page->property;
ffffffffc0201190:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201194:	ff078693          	addi	a3,a5,-16
ffffffffc0201198:	9db9                	addw	a1,a1,a4
ffffffffc020119a:	c90c                	sw	a1,16(a0)
ffffffffc020119c:	5775                	li	a4,-3
ffffffffc020119e:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02011a2:	6398                	ld	a4,0(a5)
ffffffffc02011a4:	679c                	ld	a5,8(a5)
}
ffffffffc02011a6:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02011a8:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02011aa:	e398                	sd	a4,0(a5)
ffffffffc02011ac:	0141                	addi	sp,sp,16
ffffffffc02011ae:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02011b0:	00001697          	auipc	a3,0x1
ffffffffc02011b4:	56068693          	addi	a3,a3,1376 # ffffffffc0202710 <commands+0x930>
ffffffffc02011b8:	00001617          	auipc	a2,0x1
ffffffffc02011bc:	26060613          	addi	a2,a2,608 # ffffffffc0202418 <commands+0x638>
ffffffffc02011c0:	0a400593          	li	a1,164
ffffffffc02011c4:	00001517          	auipc	a0,0x1
ffffffffc02011c8:	26c50513          	addi	a0,a0,620 # ffffffffc0202430 <commands+0x650>
ffffffffc02011cc:	9e0ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc02011d0:	00001697          	auipc	a3,0x1
ffffffffc02011d4:	24068693          	addi	a3,a3,576 # ffffffffc0202410 <commands+0x630>
ffffffffc02011d8:	00001617          	auipc	a2,0x1
ffffffffc02011dc:	24060613          	addi	a2,a2,576 # ffffffffc0202418 <commands+0x638>
ffffffffc02011e0:	0a000593          	li	a1,160
ffffffffc02011e4:	00001517          	auipc	a0,0x1
ffffffffc02011e8:	24c50513          	addi	a0,a0,588 # ffffffffc0202430 <commands+0x650>
ffffffffc02011ec:	9c0ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02011f0 <best_fit_init_memmap>:
{
ffffffffc02011f0:	1141                	addi	sp,sp,-16
ffffffffc02011f2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02011f4:	c1e9                	beqz	a1,ffffffffc02012b6 <best_fit_init_memmap+0xc6>
    for (; p != base + n; p++)
ffffffffc02011f6:	00259693          	slli	a3,a1,0x2
ffffffffc02011fa:	96ae                	add	a3,a3,a1
ffffffffc02011fc:	068e                	slli	a3,a3,0x3
ffffffffc02011fe:	96aa                	add	a3,a3,a0
ffffffffc0201200:	02d50263          	beq	a0,a3,ffffffffc0201224 <best_fit_init_memmap+0x34>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201204:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc0201206:	87aa                	mv	a5,a0
ffffffffc0201208:	8b05                	andi	a4,a4,1
ffffffffc020120a:	e709                	bnez	a4,ffffffffc0201214 <best_fit_init_memmap+0x24>
ffffffffc020120c:	a069                	j	ffffffffc0201296 <best_fit_init_memmap+0xa6>
ffffffffc020120e:	6798                	ld	a4,8(a5)
ffffffffc0201210:	8b05                	andi	a4,a4,1
ffffffffc0201212:	c351                	beqz	a4,ffffffffc0201296 <best_fit_init_memmap+0xa6>
        p->flags = 0;
ffffffffc0201214:	0007b423          	sd	zero,8(a5)
ffffffffc0201218:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020121c:	02878793          	addi	a5,a5,40
ffffffffc0201220:	fed797e3          	bne	a5,a3,ffffffffc020120e <best_fit_init_memmap+0x1e>
    base->property = n;
ffffffffc0201224:	2581                	sext.w	a1,a1
ffffffffc0201226:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201228:	4789                	li	a5,2
ffffffffc020122a:	00850713          	addi	a4,a0,8
ffffffffc020122e:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201232:	00005697          	auipc	a3,0x5
ffffffffc0201236:	21668693          	addi	a3,a3,534 # ffffffffc0206448 <free_area>
ffffffffc020123a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020123c:	669c                	ld	a5,8(a3)
ffffffffc020123e:	9db9                	addw	a1,a1,a4
ffffffffc0201240:	00005717          	auipc	a4,0x5
ffffffffc0201244:	20b72c23          	sw	a1,536(a4) # ffffffffc0206458 <free_area+0x10>
    if (list_empty(&free_list))
ffffffffc0201248:	00d79763          	bne	a5,a3,ffffffffc0201256 <best_fit_init_memmap+0x66>
ffffffffc020124c:	a01d                	j	ffffffffc0201272 <best_fit_init_memmap+0x82>
    return listelm->next;
ffffffffc020124e:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201250:	02d70a63          	beq	a4,a3,ffffffffc0201284 <best_fit_init_memmap+0x94>
ffffffffc0201254:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201256:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc020125a:	fee57ae3          	bleu	a4,a0,ffffffffc020124e <best_fit_init_memmap+0x5e>
    __list_add(elm, listelm->prev, listelm);
ffffffffc020125e:	6398                	ld	a4,0(a5)
                list_add_before(le, &(base->page_link));
ffffffffc0201260:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc0201264:	e394                	sd	a3,0(a5)
}
ffffffffc0201266:	60a2                	ld	ra,8(sp)
ffffffffc0201268:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc020126a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020126c:	ed18                	sd	a4,24(a0)
ffffffffc020126e:	0141                	addi	sp,sp,16
ffffffffc0201270:	8082                	ret
ffffffffc0201272:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201274:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201278:	e398                	sd	a4,0(a5)
ffffffffc020127a:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020127c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020127e:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201280:	0141                	addi	sp,sp,16
ffffffffc0201282:	8082                	ret
                list_add(le, &(base->page_link));
ffffffffc0201284:	01850713          	addi	a4,a0,24
}
ffffffffc0201288:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020128a:	e798                	sd	a4,8(a5)
ffffffffc020128c:	e298                	sd	a4,0(a3)
    elm->next = next;
ffffffffc020128e:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc0201290:	ed1c                	sd	a5,24(a0)
ffffffffc0201292:	0141                	addi	sp,sp,16
ffffffffc0201294:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201296:	00001697          	auipc	a3,0x1
ffffffffc020129a:	4a268693          	addi	a3,a3,1186 # ffffffffc0202738 <commands+0x958>
ffffffffc020129e:	00001617          	auipc	a2,0x1
ffffffffc02012a2:	17a60613          	addi	a2,a2,378 # ffffffffc0202418 <commands+0x638>
ffffffffc02012a6:	04d00593          	li	a1,77
ffffffffc02012aa:	00001517          	auipc	a0,0x1
ffffffffc02012ae:	18650513          	addi	a0,a0,390 # ffffffffc0202430 <commands+0x650>
ffffffffc02012b2:	8faff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc02012b6:	00001697          	auipc	a3,0x1
ffffffffc02012ba:	15a68693          	addi	a3,a3,346 # ffffffffc0202410 <commands+0x630>
ffffffffc02012be:	00001617          	auipc	a2,0x1
ffffffffc02012c2:	15a60613          	addi	a2,a2,346 # ffffffffc0202418 <commands+0x638>
ffffffffc02012c6:	04900593          	li	a1,73
ffffffffc02012ca:	00001517          	auipc	a0,0x1
ffffffffc02012ce:	16650513          	addi	a0,a0,358 # ffffffffc0202430 <commands+0x650>
ffffffffc02012d2:	8daff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02012d6 <pa2page.part.0>:
static inline int page_ref_dec(struct Page *page)
{
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc02012d6:	1141                	addi	sp,sp,-16
{
    if (PPN(pa) >= npage)
    {
        panic("pa2page called with invalid pa");
ffffffffc02012d8:	00001617          	auipc	a2,0x1
ffffffffc02012dc:	4c060613          	addi	a2,a2,1216 # ffffffffc0202798 <best_fit_pmm_manager+0x50>
ffffffffc02012e0:	07200593          	li	a1,114
ffffffffc02012e4:	00001517          	auipc	a0,0x1
ffffffffc02012e8:	4d450513          	addi	a0,a0,1236 # ffffffffc02027b8 <best_fit_pmm_manager+0x70>
static inline struct Page *pa2page(uintptr_t pa)
ffffffffc02012ec:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc02012ee:	8beff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02012f2 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02012f2:	100027f3          	csrr	a5,sstatus
ffffffffc02012f6:	8b89                	andi	a5,a5,2
ffffffffc02012f8:	eb89                	bnez	a5,ffffffffc020130a <alloc_pages+0x18>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02012fa:	00005797          	auipc	a5,0x5
ffffffffc02012fe:	16e78793          	addi	a5,a5,366 # ffffffffc0206468 <pmm_manager>
ffffffffc0201302:	639c                	ld	a5,0(a5)
ffffffffc0201304:	0187b303          	ld	t1,24(a5)
ffffffffc0201308:	8302                	jr	t1
{
ffffffffc020130a:	1141                	addi	sp,sp,-16
ffffffffc020130c:	e406                	sd	ra,8(sp)
ffffffffc020130e:	e022                	sd	s0,0(sp)
ffffffffc0201310:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201312:	952ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201316:	00005797          	auipc	a5,0x5
ffffffffc020131a:	15278793          	addi	a5,a5,338 # ffffffffc0206468 <pmm_manager>
ffffffffc020131e:	639c                	ld	a5,0(a5)
ffffffffc0201320:	8522                	mv	a0,s0
ffffffffc0201322:	6f9c                	ld	a5,24(a5)
ffffffffc0201324:	9782                	jalr	a5
ffffffffc0201326:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201328:	936ff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc020132c:	8522                	mv	a0,s0
ffffffffc020132e:	60a2                	ld	ra,8(sp)
ffffffffc0201330:	6402                	ld	s0,0(sp)
ffffffffc0201332:	0141                	addi	sp,sp,16
ffffffffc0201334:	8082                	ret

ffffffffc0201336 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201336:	100027f3          	csrr	a5,sstatus
ffffffffc020133a:	8b89                	andi	a5,a5,2
ffffffffc020133c:	eb89                	bnez	a5,ffffffffc020134e <free_pages+0x18>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020133e:	00005797          	auipc	a5,0x5
ffffffffc0201342:	12a78793          	addi	a5,a5,298 # ffffffffc0206468 <pmm_manager>
ffffffffc0201346:	639c                	ld	a5,0(a5)
ffffffffc0201348:	0207b303          	ld	t1,32(a5)
ffffffffc020134c:	8302                	jr	t1
{
ffffffffc020134e:	1101                	addi	sp,sp,-32
ffffffffc0201350:	ec06                	sd	ra,24(sp)
ffffffffc0201352:	e822                	sd	s0,16(sp)
ffffffffc0201354:	e426                	sd	s1,8(sp)
ffffffffc0201356:	842a                	mv	s0,a0
ffffffffc0201358:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020135a:	90aff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020135e:	00005797          	auipc	a5,0x5
ffffffffc0201362:	10a78793          	addi	a5,a5,266 # ffffffffc0206468 <pmm_manager>
ffffffffc0201366:	639c                	ld	a5,0(a5)
ffffffffc0201368:	85a6                	mv	a1,s1
ffffffffc020136a:	8522                	mv	a0,s0
ffffffffc020136c:	739c                	ld	a5,32(a5)
ffffffffc020136e:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201370:	6442                	ld	s0,16(sp)
ffffffffc0201372:	60e2                	ld	ra,24(sp)
ffffffffc0201374:	64a2                	ld	s1,8(sp)
ffffffffc0201376:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201378:	8e6ff06f          	j	ffffffffc020045e <intr_enable>

ffffffffc020137c <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020137c:	100027f3          	csrr	a5,sstatus
ffffffffc0201380:	8b89                	andi	a5,a5,2
ffffffffc0201382:	eb89                	bnez	a5,ffffffffc0201394 <nr_free_pages+0x18>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201384:	00005797          	auipc	a5,0x5
ffffffffc0201388:	0e478793          	addi	a5,a5,228 # ffffffffc0206468 <pmm_manager>
ffffffffc020138c:	639c                	ld	a5,0(a5)
ffffffffc020138e:	0287b303          	ld	t1,40(a5)
ffffffffc0201392:	8302                	jr	t1
{
ffffffffc0201394:	1141                	addi	sp,sp,-16
ffffffffc0201396:	e406                	sd	ra,8(sp)
ffffffffc0201398:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020139a:	8caff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020139e:	00005797          	auipc	a5,0x5
ffffffffc02013a2:	0ca78793          	addi	a5,a5,202 # ffffffffc0206468 <pmm_manager>
ffffffffc02013a6:	639c                	ld	a5,0(a5)
ffffffffc02013a8:	779c                	ld	a5,40(a5)
ffffffffc02013aa:	9782                	jalr	a5
ffffffffc02013ac:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02013ae:	8b0ff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02013b2:	8522                	mv	a0,s0
ffffffffc02013b4:	60a2                	ld	ra,8(sp)
ffffffffc02013b6:	6402                	ld	s0,0(sp)
ffffffffc02013b8:	0141                	addi	sp,sp,16
ffffffffc02013ba:	8082                	ret

ffffffffc02013bc <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02013bc:	00001797          	auipc	a5,0x1
ffffffffc02013c0:	38c78793          	addi	a5,a5,908 # ffffffffc0202748 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02013c4:	638c                	ld	a1,0(a5)
    // 0x8000-0x7cb9=0x0347个不可用，这些页存的是结构体page的数据
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void)
{
ffffffffc02013c6:	715d                	addi	sp,sp,-80
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02013c8:	00001517          	auipc	a0,0x1
ffffffffc02013cc:	40050513          	addi	a0,a0,1024 # ffffffffc02027c8 <best_fit_pmm_manager+0x80>
{
ffffffffc02013d0:	e486                	sd	ra,72(sp)
ffffffffc02013d2:	e0a2                	sd	s0,64(sp)
ffffffffc02013d4:	f052                	sd	s4,32(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02013d6:	00005717          	auipc	a4,0x5
ffffffffc02013da:	08f73923          	sd	a5,146(a4) # ffffffffc0206468 <pmm_manager>
{
ffffffffc02013de:	fc26                	sd	s1,56(sp)
ffffffffc02013e0:	f84a                	sd	s2,48(sp)
ffffffffc02013e2:	f44e                	sd	s3,40(sp)
ffffffffc02013e4:	ec56                	sd	s5,24(sp)
ffffffffc02013e6:	e85a                	sd	s6,16(sp)
ffffffffc02013e8:	e45e                	sd	s7,8(sp)
ffffffffc02013ea:	e062                	sd	s8,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02013ec:	00005a17          	auipc	s4,0x5
ffffffffc02013f0:	07ca0a13          	addi	s4,s4,124 # ffffffffc0206468 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02013f4:	cc3fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pmm_manager->init();
ffffffffc02013f8:	000a3783          	ld	a5,0(s4)
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02013fc:	4445                	li	s0,17
ffffffffc02013fe:	046e                	slli	s0,s0,0x1b
    pmm_manager->init();
ffffffffc0201400:	679c                	ld	a5,8(a5)
ffffffffc0201402:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移:
ffffffffc0201404:	57f5                	li	a5,-3
ffffffffc0201406:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201408:	00001517          	auipc	a0,0x1
ffffffffc020140c:	3d850513          	addi	a0,a0,984 # ffffffffc02027e0 <best_fit_pmm_manager+0x98>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移:
ffffffffc0201410:	00005717          	auipc	a4,0x5
ffffffffc0201414:	06f73023          	sd	a5,96(a4) # ffffffffc0206470 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc0201418:	c9ffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020141c:	40100613          	li	a2,1025
ffffffffc0201420:	fff40693          	addi	a3,s0,-1
ffffffffc0201424:	0656                	slli	a2,a2,0x15
ffffffffc0201426:	07e005b7          	lui	a1,0x7e00
ffffffffc020142a:	00001517          	auipc	a0,0x1
ffffffffc020142e:	3ce50513          	addi	a0,a0,974 # ffffffffc02027f8 <best_fit_pmm_manager+0xb0>
ffffffffc0201432:	c85fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("maxpa: 0x%016lx.\n", maxpa); // test point
ffffffffc0201436:	85a2                	mv	a1,s0
ffffffffc0201438:	00001517          	auipc	a0,0x1
ffffffffc020143c:	3f050513          	addi	a0,a0,1008 # ffffffffc0202828 <best_fit_pmm_manager+0xe0>
ffffffffc0201440:	c77fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201444:	000887b7          	lui	a5,0x88
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc0201448:	000885b7          	lui	a1,0x88
ffffffffc020144c:	00001517          	auipc	a0,0x1
ffffffffc0201450:	3f450513          	addi	a0,a0,1012 # ffffffffc0202840 <best_fit_pmm_manager+0xf8>
    npage = maxpa / PGSIZE;
ffffffffc0201454:	00005717          	auipc	a4,0x5
ffffffffc0201458:	fcf73a23          	sd	a5,-44(a4) # ffffffffc0206428 <npage>
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
ffffffffc020145c:	c5bfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("nbase: 0x%016lx.\n", nbase); // test point，为0x8000_0
ffffffffc0201460:	000805b7          	lui	a1,0x80
ffffffffc0201464:	00001517          	auipc	a0,0x1
ffffffffc0201468:	3f450513          	addi	a0,a0,1012 # ffffffffc0202858 <best_fit_pmm_manager+0x110>
ffffffffc020146c:	c4bfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201470:	00006697          	auipc	a3,0x6
ffffffffc0201474:	00f68693          	addi	a3,a3,15 # ffffffffc020747f <end+0xfff>
ffffffffc0201478:	75fd                	lui	a1,0xfffff
ffffffffc020147a:	8eed                	and	a3,a3,a1
ffffffffc020147c:	00005797          	auipc	a5,0x5
ffffffffc0201480:	fed7be23          	sd	a3,-4(a5) # ffffffffc0206478 <pages>
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc0201484:	c02007b7          	lui	a5,0xc0200
ffffffffc0201488:	24f6ec63          	bltu	a3,a5,ffffffffc02016e0 <pmm_init+0x324>
ffffffffc020148c:	00005997          	auipc	s3,0x5
ffffffffc0201490:	fe498993          	addi	s3,s3,-28 # ffffffffc0206470 <va_pa_offset>
ffffffffc0201494:	0009b583          	ld	a1,0(s3)
ffffffffc0201498:	00001517          	auipc	a0,0x1
ffffffffc020149c:	41050513          	addi	a0,a0,1040 # ffffffffc02028a8 <best_fit_pmm_manager+0x160>
ffffffffc02014a0:	00005917          	auipc	s2,0x5
ffffffffc02014a4:	f8890913          	addi	s2,s2,-120 # ffffffffc0206428 <npage>
ffffffffc02014a8:	40b685b3          	sub	a1,a3,a1
ffffffffc02014ac:	c0bfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02014b0:	00093703          	ld	a4,0(s2)
ffffffffc02014b4:	000807b7          	lui	a5,0x80
ffffffffc02014b8:	00005a97          	auipc	s5,0x5
ffffffffc02014bc:	fc0a8a93          	addi	s5,s5,-64 # ffffffffc0206478 <pages>
ffffffffc02014c0:	02f70963          	beq	a4,a5,ffffffffc02014f2 <pmm_init+0x136>
ffffffffc02014c4:	4681                	li	a3,0
ffffffffc02014c6:	4701                	li	a4,0
ffffffffc02014c8:	00005a97          	auipc	s5,0x5
ffffffffc02014cc:	fb0a8a93          	addi	s5,s5,-80 # ffffffffc0206478 <pages>
ffffffffc02014d0:	4585                	li	a1,1
ffffffffc02014d2:	fff80637          	lui	a2,0xfff80
        SetPageReserved(pages + i);
ffffffffc02014d6:	000ab783          	ld	a5,0(s5)
ffffffffc02014da:	97b6                	add	a5,a5,a3
ffffffffc02014dc:	07a1                	addi	a5,a5,8
ffffffffc02014de:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02014e2:	00093783          	ld	a5,0(s2)
ffffffffc02014e6:	0705                	addi	a4,a4,1
ffffffffc02014e8:	02868693          	addi	a3,a3,40
ffffffffc02014ec:	97b2                	add	a5,a5,a2
ffffffffc02014ee:	fef764e3          	bltu	a4,a5,ffffffffc02014d6 <pmm_init+0x11a>
ffffffffc02014f2:	4481                	li	s1,0
    for (size_t i = 0; i < 5; i++)
ffffffffc02014f4:	4401                	li	s0,0
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc02014f6:	c0200b37          	lui	s6,0xc0200
ffffffffc02014fa:	00001c17          	auipc	s8,0x1
ffffffffc02014fe:	3d6c0c13          	addi	s8,s8,982 # ffffffffc02028d0 <best_fit_pmm_manager+0x188>
    for (size_t i = 0; i < 5; i++)
ffffffffc0201502:	4b95                	li	s7,5
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201504:	000ab683          	ld	a3,0(s5)
ffffffffc0201508:	96a6                	add	a3,a3,s1
ffffffffc020150a:	1966e563          	bltu	a3,s6,ffffffffc0201694 <pmm_init+0x2d8>
ffffffffc020150e:	0009b603          	ld	a2,0(s3)
ffffffffc0201512:	85a2                	mv	a1,s0
ffffffffc0201514:	8562                	mv	a0,s8
ffffffffc0201516:	40c68633          	sub	a2,a3,a2
    for (size_t i = 0; i < 5; i++)
ffffffffc020151a:	0405                	addi	s0,s0,1
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc020151c:	b9bfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0201520:	02848493          	addi	s1,s1,40
    for (size_t i = 0; i < 5; i++)
ffffffffc0201524:	ff7410e3          	bne	s0,s7,ffffffffc0201504 <pmm_init+0x148>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc0201528:	00093783          	ld	a5,0(s2)
ffffffffc020152c:	000ab403          	ld	s0,0(s5)
ffffffffc0201530:	00279693          	slli	a3,a5,0x2
ffffffffc0201534:	96be                	add	a3,a3,a5
ffffffffc0201536:	068e                	slli	a3,a3,0x3
ffffffffc0201538:	9436                	add	s0,s0,a3
ffffffffc020153a:	fec006b7          	lui	a3,0xfec00
ffffffffc020153e:	9436                	add	s0,s0,a3
ffffffffc0201540:	1b646c63          	bltu	s0,s6,ffffffffc02016f8 <pmm_init+0x33c>
ffffffffc0201544:	0009b683          	ld	a3,0(s3)
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc0201548:	02800593          	li	a1,40
ffffffffc020154c:	00001517          	auipc	a0,0x1
ffffffffc0201550:	3ac50513          	addi	a0,a0,940 # ffffffffc02028f8 <best_fit_pmm_manager+0x1b0>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201554:	6485                	lui	s1,0x1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc0201556:	8c15                	sub	s0,s0,a3
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201558:	14fd                	addi	s1,s1,-1
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point
ffffffffc020155a:	b5dfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc020155e:	85a2                	mv	a1,s0
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201560:	94a2                	add	s1,s1,s0
ffffffffc0201562:	7b7d                	lui	s6,0xfffff
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
ffffffffc0201564:	00001517          	auipc	a0,0x1
ffffffffc0201568:	3b450513          	addi	a0,a0,948 # ffffffffc0202918 <best_fit_pmm_manager+0x1d0>
ffffffffc020156c:	b4bfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0201570:	0164fb33          	and	s6,s1,s6
    cprintf("mem_begin: 0x%016lx.\n", mem_begin); // test point
ffffffffc0201574:	85da                	mv	a1,s6
ffffffffc0201576:	00001517          	auipc	a0,0x1
ffffffffc020157a:	3ba50513          	addi	a0,a0,954 # ffffffffc0202930 <best_fit_pmm_manager+0x1e8>
ffffffffc020157e:	b39fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc0201582:	4bc5                	li	s7,17
ffffffffc0201584:	01bb9593          	slli	a1,s7,0x1b
ffffffffc0201588:	00001517          	auipc	a0,0x1
ffffffffc020158c:	3c050513          	addi	a0,a0,960 # ffffffffc0202948 <best_fit_pmm_manager+0x200>
    if (freemem < mem_end)
ffffffffc0201590:	0bee                	slli	s7,s7,0x1b
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point
ffffffffc0201592:	b25fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (freemem < mem_end)
ffffffffc0201596:	0d746763          	bltu	s0,s7,ffffffffc0201664 <pmm_init+0x2a8>
    if (PPN(pa) >= npage)
ffffffffc020159a:	00093783          	ld	a5,0(s2)
ffffffffc020159e:	00cb5493          	srli	s1,s6,0xc
ffffffffc02015a2:	10f4f563          	bleu	a5,s1,ffffffffc02016ac <pmm_init+0x2f0>
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02015a6:	fff80437          	lui	s0,0xfff80
ffffffffc02015aa:	008486b3          	add	a3,s1,s0
ffffffffc02015ae:	00269413          	slli	s0,a3,0x2
ffffffffc02015b2:	000ab583          	ld	a1,0(s5)
ffffffffc02015b6:	9436                	add	s0,s0,a3
ffffffffc02015b8:	040e                	slli	s0,s0,0x3
    cprintf("mem_begin对应的页结构记录(结构体page)虚拟地址: 0x%016lx.\n", pa2page(mem_begin));        // test point
ffffffffc02015ba:	95a2                	add	a1,a1,s0
ffffffffc02015bc:	00001517          	auipc	a0,0x1
ffffffffc02015c0:	3a450513          	addi	a0,a0,932 # ffffffffc0202960 <best_fit_pmm_manager+0x218>
ffffffffc02015c4:	af3fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc02015c8:	00093783          	ld	a5,0(s2)
ffffffffc02015cc:	0ef4f063          	bleu	a5,s1,ffffffffc02016ac <pmm_init+0x2f0>
    return &pages[PPN(pa) - nbase];
ffffffffc02015d0:	000ab683          	ld	a3,0(s5)
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc02015d4:	c02004b7          	lui	s1,0xc0200
ffffffffc02015d8:	96a2                	add	a3,a3,s0
ffffffffc02015da:	0c96eb63          	bltu	a3,s1,ffffffffc02016b0 <pmm_init+0x2f4>
ffffffffc02015de:	0009b583          	ld	a1,0(s3)
ffffffffc02015e2:	00001517          	auipc	a0,0x1
ffffffffc02015e6:	3ce50513          	addi	a0,a0,974 # ffffffffc02029b0 <best_fit_pmm_manager+0x268>
ffffffffc02015ea:	40b685b3          	sub	a1,a3,a1
ffffffffc02015ee:	ac9fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("可用空闲页的数目: 0x%016lx.\n", (mem_end - mem_begin) / PGSIZE); // test point
ffffffffc02015f2:	45c5                	li	a1,17
ffffffffc02015f4:	05ee                	slli	a1,a1,0x1b
ffffffffc02015f6:	416585b3          	sub	a1,a1,s6
ffffffffc02015fa:	81b1                	srli	a1,a1,0xc
ffffffffc02015fc:	00001517          	auipc	a0,0x1
ffffffffc0201600:	40450513          	addi	a0,a0,1028 # ffffffffc0202a00 <best_fit_pmm_manager+0x2b8>
ffffffffc0201604:	ab3fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201608:	000a3783          	ld	a5,0(s4)
ffffffffc020160c:	7b9c                	ld	a5,48(a5)
ffffffffc020160e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201610:	00001517          	auipc	a0,0x1
ffffffffc0201614:	41850513          	addi	a0,a0,1048 # ffffffffc0202a28 <best_fit_pmm_manager+0x2e0>
ffffffffc0201618:	a9ffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    satp_virtual = (pte_t *)boot_page_table_sv39;
ffffffffc020161c:	00004697          	auipc	a3,0x4
ffffffffc0201620:	9e468693          	addi	a3,a3,-1564 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201624:	00005797          	auipc	a5,0x5
ffffffffc0201628:	e0d7b623          	sd	a3,-500(a5) # ffffffffc0206430 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020162c:	0896ee63          	bltu	a3,s1,ffffffffc02016c8 <pmm_init+0x30c>
ffffffffc0201630:	0009b783          	ld	a5,0(s3)
}
ffffffffc0201634:	6406                	ld	s0,64(sp)
ffffffffc0201636:	60a6                	ld	ra,72(sp)
ffffffffc0201638:	74e2                	ld	s1,56(sp)
ffffffffc020163a:	7942                	ld	s2,48(sp)
ffffffffc020163c:	79a2                	ld	s3,40(sp)
ffffffffc020163e:	7a02                	ld	s4,32(sp)
ffffffffc0201640:	6ae2                	ld	s5,24(sp)
ffffffffc0201642:	6b42                	ld	s6,16(sp)
ffffffffc0201644:	6ba2                	ld	s7,8(sp)
ffffffffc0201646:	6c02                	ld	s8,0(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201648:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc020164a:	8e9d                	sub	a3,a3,a5
ffffffffc020164c:	00005797          	auipc	a5,0x5
ffffffffc0201650:	e0d7ba23          	sd	a3,-492(a5) # ffffffffc0206460 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201654:	00001517          	auipc	a0,0x1
ffffffffc0201658:	3f450513          	addi	a0,a0,1012 # ffffffffc0202a48 <best_fit_pmm_manager+0x300>
ffffffffc020165c:	8636                	mv	a2,a3
}
ffffffffc020165e:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201660:	a57fe06f          	j	ffffffffc02000b6 <cprintf>
    if (PPN(pa) >= npage)
ffffffffc0201664:	00093783          	ld	a5,0(s2)
ffffffffc0201668:	80b1                	srli	s1,s1,0xc
ffffffffc020166a:	04f4f163          	bleu	a5,s1,ffffffffc02016ac <pmm_init+0x2f0>
    pmm_manager->init_memmap(base, n);
ffffffffc020166e:	000a3703          	ld	a4,0(s4)
    return &pages[PPN(pa) - nbase];
ffffffffc0201672:	fff80537          	lui	a0,0xfff80
ffffffffc0201676:	94aa                	add	s1,s1,a0
ffffffffc0201678:	00249793          	slli	a5,s1,0x2
ffffffffc020167c:	000ab503          	ld	a0,0(s5)
ffffffffc0201680:	94be                	add	s1,s1,a5
ffffffffc0201682:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201684:	416b8bb3          	sub	s7,s7,s6
ffffffffc0201688:	048e                	slli	s1,s1,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020168a:	00cbd593          	srli	a1,s7,0xc
ffffffffc020168e:	9526                	add	a0,a0,s1
ffffffffc0201690:	9782                	jalr	a5
ffffffffc0201692:	b721                	j	ffffffffc020159a <pmm_init+0x1de>
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
ffffffffc0201694:	00001617          	auipc	a2,0x1
ffffffffc0201698:	1dc60613          	addi	a2,a2,476 # ffffffffc0202870 <best_fit_pmm_manager+0x128>
ffffffffc020169c:	08a00593          	li	a1,138
ffffffffc02016a0:	00001517          	auipc	a0,0x1
ffffffffc02016a4:	1f850513          	addi	a0,a0,504 # ffffffffc0202898 <best_fit_pmm_manager+0x150>
ffffffffc02016a8:	d05fe0ef          	jal	ra,ffffffffc02003ac <__panic>
ffffffffc02016ac:	c2bff0ef          	jal	ra,ffffffffc02012d6 <pa2page.part.0>
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point
ffffffffc02016b0:	00001617          	auipc	a2,0x1
ffffffffc02016b4:	1c060613          	addi	a2,a2,448 # ffffffffc0202870 <best_fit_pmm_manager+0x128>
ffffffffc02016b8:	09e00593          	li	a1,158
ffffffffc02016bc:	00001517          	auipc	a0,0x1
ffffffffc02016c0:	1dc50513          	addi	a0,a0,476 # ffffffffc0202898 <best_fit_pmm_manager+0x150>
ffffffffc02016c4:	ce9fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02016c8:	00001617          	auipc	a2,0x1
ffffffffc02016cc:	1a860613          	addi	a2,a2,424 # ffffffffc0202870 <best_fit_pmm_manager+0x128>
ffffffffc02016d0:	0b900593          	li	a1,185
ffffffffc02016d4:	00001517          	auipc	a0,0x1
ffffffffc02016d8:	1c450513          	addi	a0,a0,452 # ffffffffc0202898 <best_fit_pmm_manager+0x150>
ffffffffc02016dc:	cd1fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
ffffffffc02016e0:	00001617          	auipc	a2,0x1
ffffffffc02016e4:	19060613          	addi	a2,a2,400 # ffffffffc0202870 <best_fit_pmm_manager+0x128>
ffffffffc02016e8:	07e00593          	li	a1,126
ffffffffc02016ec:	00001517          	auipc	a0,0x1
ffffffffc02016f0:	1ac50513          	addi	a0,a0,428 # ffffffffc0202898 <best_fit_pmm_manager+0x150>
ffffffffc02016f4:	cb9fe0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
ffffffffc02016f8:	86a2                	mv	a3,s0
ffffffffc02016fa:	00001617          	auipc	a2,0x1
ffffffffc02016fe:	17660613          	addi	a2,a2,374 # ffffffffc0202870 <best_fit_pmm_manager+0x128>
ffffffffc0201702:	09000593          	li	a1,144
ffffffffc0201706:	00001517          	auipc	a0,0x1
ffffffffc020170a:	19250513          	addi	a0,a0,402 # ffffffffc0202898 <best_fit_pmm_manager+0x150>
ffffffffc020170e:	c9ffe0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201712 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201712:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201716:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201718:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020171c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020171e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201722:	f022                	sd	s0,32(sp)
ffffffffc0201724:	ec26                	sd	s1,24(sp)
ffffffffc0201726:	e84a                	sd	s2,16(sp)
ffffffffc0201728:	f406                	sd	ra,40(sp)
ffffffffc020172a:	e44e                	sd	s3,8(sp)
ffffffffc020172c:	84aa                	mv	s1,a0
ffffffffc020172e:	892e                	mv	s2,a1
ffffffffc0201730:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201734:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0201736:	03067e63          	bleu	a6,a2,ffffffffc0201772 <printnum+0x60>
ffffffffc020173a:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020173c:	00805763          	blez	s0,ffffffffc020174a <printnum+0x38>
ffffffffc0201740:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201742:	85ca                	mv	a1,s2
ffffffffc0201744:	854e                	mv	a0,s3
ffffffffc0201746:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201748:	fc65                	bnez	s0,ffffffffc0201740 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020174a:	1a02                	slli	s4,s4,0x20
ffffffffc020174c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201750:	00001797          	auipc	a5,0x1
ffffffffc0201754:	4c878793          	addi	a5,a5,1224 # ffffffffc0202c18 <error_string+0x38>
ffffffffc0201758:	9a3e                	add	s4,s4,a5
}
ffffffffc020175a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020175c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201760:	70a2                	ld	ra,40(sp)
ffffffffc0201762:	69a2                	ld	s3,8(sp)
ffffffffc0201764:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201766:	85ca                	mv	a1,s2
ffffffffc0201768:	8326                	mv	t1,s1
}
ffffffffc020176a:	6942                	ld	s2,16(sp)
ffffffffc020176c:	64e2                	ld	s1,24(sp)
ffffffffc020176e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201770:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201772:	03065633          	divu	a2,a2,a6
ffffffffc0201776:	8722                	mv	a4,s0
ffffffffc0201778:	f9bff0ef          	jal	ra,ffffffffc0201712 <printnum>
ffffffffc020177c:	b7f9                	j	ffffffffc020174a <printnum+0x38>

ffffffffc020177e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020177e:	7119                	addi	sp,sp,-128
ffffffffc0201780:	f4a6                	sd	s1,104(sp)
ffffffffc0201782:	f0ca                	sd	s2,96(sp)
ffffffffc0201784:	e8d2                	sd	s4,80(sp)
ffffffffc0201786:	e4d6                	sd	s5,72(sp)
ffffffffc0201788:	e0da                	sd	s6,64(sp)
ffffffffc020178a:	fc5e                	sd	s7,56(sp)
ffffffffc020178c:	f862                	sd	s8,48(sp)
ffffffffc020178e:	f06a                	sd	s10,32(sp)
ffffffffc0201790:	fc86                	sd	ra,120(sp)
ffffffffc0201792:	f8a2                	sd	s0,112(sp)
ffffffffc0201794:	ecce                	sd	s3,88(sp)
ffffffffc0201796:	f466                	sd	s9,40(sp)
ffffffffc0201798:	ec6e                	sd	s11,24(sp)
ffffffffc020179a:	892a                	mv	s2,a0
ffffffffc020179c:	84ae                	mv	s1,a1
ffffffffc020179e:	8d32                	mv	s10,a2
ffffffffc02017a0:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02017a2:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017a4:	00001a17          	auipc	s4,0x1
ffffffffc02017a8:	2e4a0a13          	addi	s4,s4,740 # ffffffffc0202a88 <best_fit_pmm_manager+0x340>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02017ac:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02017b0:	00001c17          	auipc	s8,0x1
ffffffffc02017b4:	430c0c13          	addi	s8,s8,1072 # ffffffffc0202be0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02017b8:	000d4503          	lbu	a0,0(s10)
ffffffffc02017bc:	02500793          	li	a5,37
ffffffffc02017c0:	001d0413          	addi	s0,s10,1
ffffffffc02017c4:	00f50e63          	beq	a0,a5,ffffffffc02017e0 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc02017c8:	c521                	beqz	a0,ffffffffc0201810 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02017ca:	02500993          	li	s3,37
ffffffffc02017ce:	a011                	j	ffffffffc02017d2 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc02017d0:	c121                	beqz	a0,ffffffffc0201810 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc02017d2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02017d4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02017d6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02017d8:	fff44503          	lbu	a0,-1(s0) # fffffffffff7ffff <end+0x3fd79b7f>
ffffffffc02017dc:	ff351ae3          	bne	a0,s3,ffffffffc02017d0 <vprintfmt+0x52>
ffffffffc02017e0:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02017e4:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02017e8:	4981                	li	s3,0
ffffffffc02017ea:	4801                	li	a6,0
        width = precision = -1;
ffffffffc02017ec:	5cfd                	li	s9,-1
ffffffffc02017ee:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017f0:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc02017f4:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017f6:	fdd6069b          	addiw	a3,a2,-35
ffffffffc02017fa:	0ff6f693          	andi	a3,a3,255
ffffffffc02017fe:	00140d13          	addi	s10,s0,1
ffffffffc0201802:	20d5e563          	bltu	a1,a3,ffffffffc0201a0c <vprintfmt+0x28e>
ffffffffc0201806:	068a                	slli	a3,a3,0x2
ffffffffc0201808:	96d2                	add	a3,a3,s4
ffffffffc020180a:	4294                	lw	a3,0(a3)
ffffffffc020180c:	96d2                	add	a3,a3,s4
ffffffffc020180e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201810:	70e6                	ld	ra,120(sp)
ffffffffc0201812:	7446                	ld	s0,112(sp)
ffffffffc0201814:	74a6                	ld	s1,104(sp)
ffffffffc0201816:	7906                	ld	s2,96(sp)
ffffffffc0201818:	69e6                	ld	s3,88(sp)
ffffffffc020181a:	6a46                	ld	s4,80(sp)
ffffffffc020181c:	6aa6                	ld	s5,72(sp)
ffffffffc020181e:	6b06                	ld	s6,64(sp)
ffffffffc0201820:	7be2                	ld	s7,56(sp)
ffffffffc0201822:	7c42                	ld	s8,48(sp)
ffffffffc0201824:	7ca2                	ld	s9,40(sp)
ffffffffc0201826:	7d02                	ld	s10,32(sp)
ffffffffc0201828:	6de2                	ld	s11,24(sp)
ffffffffc020182a:	6109                	addi	sp,sp,128
ffffffffc020182c:	8082                	ret
    if (lflag >= 2) {
ffffffffc020182e:	4705                	li	a4,1
ffffffffc0201830:	008a8593          	addi	a1,s5,8
ffffffffc0201834:	01074463          	blt	a4,a6,ffffffffc020183c <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0201838:	26080363          	beqz	a6,ffffffffc0201a9e <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc020183c:	000ab603          	ld	a2,0(s5)
ffffffffc0201840:	46c1                	li	a3,16
ffffffffc0201842:	8aae                	mv	s5,a1
ffffffffc0201844:	a06d                	j	ffffffffc02018ee <vprintfmt+0x170>
            goto reswitch;
ffffffffc0201846:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020184a:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020184c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020184e:	b765                	j	ffffffffc02017f6 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0201850:	000aa503          	lw	a0,0(s5)
ffffffffc0201854:	85a6                	mv	a1,s1
ffffffffc0201856:	0aa1                	addi	s5,s5,8
ffffffffc0201858:	9902                	jalr	s2
            break;
ffffffffc020185a:	bfb9                	j	ffffffffc02017b8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020185c:	4705                	li	a4,1
ffffffffc020185e:	008a8993          	addi	s3,s5,8
ffffffffc0201862:	01074463          	blt	a4,a6,ffffffffc020186a <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0201866:	22080463          	beqz	a6,ffffffffc0201a8e <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc020186a:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc020186e:	24044463          	bltz	s0,ffffffffc0201ab6 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0201872:	8622                	mv	a2,s0
ffffffffc0201874:	8ace                	mv	s5,s3
ffffffffc0201876:	46a9                	li	a3,10
ffffffffc0201878:	a89d                	j	ffffffffc02018ee <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc020187a:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020187e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201880:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0201882:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201886:	8fb5                	xor	a5,a5,a3
ffffffffc0201888:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020188c:	1ad74363          	blt	a4,a3,ffffffffc0201a32 <vprintfmt+0x2b4>
ffffffffc0201890:	00369793          	slli	a5,a3,0x3
ffffffffc0201894:	97e2                	add	a5,a5,s8
ffffffffc0201896:	639c                	ld	a5,0(a5)
ffffffffc0201898:	18078d63          	beqz	a5,ffffffffc0201a32 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc020189c:	86be                	mv	a3,a5
ffffffffc020189e:	00001617          	auipc	a2,0x1
ffffffffc02018a2:	42a60613          	addi	a2,a2,1066 # ffffffffc0202cc8 <error_string+0xe8>
ffffffffc02018a6:	85a6                	mv	a1,s1
ffffffffc02018a8:	854a                	mv	a0,s2
ffffffffc02018aa:	240000ef          	jal	ra,ffffffffc0201aea <printfmt>
ffffffffc02018ae:	b729                	j	ffffffffc02017b8 <vprintfmt+0x3a>
            lflag ++;
ffffffffc02018b0:	00144603          	lbu	a2,1(s0)
ffffffffc02018b4:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018b6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02018b8:	bf3d                	j	ffffffffc02017f6 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc02018ba:	4705                	li	a4,1
ffffffffc02018bc:	008a8593          	addi	a1,s5,8
ffffffffc02018c0:	01074463          	blt	a4,a6,ffffffffc02018c8 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02018c4:	1e080263          	beqz	a6,ffffffffc0201aa8 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc02018c8:	000ab603          	ld	a2,0(s5)
ffffffffc02018cc:	46a1                	li	a3,8
ffffffffc02018ce:	8aae                	mv	s5,a1
ffffffffc02018d0:	a839                	j	ffffffffc02018ee <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc02018d2:	03000513          	li	a0,48
ffffffffc02018d6:	85a6                	mv	a1,s1
ffffffffc02018d8:	e03e                	sd	a5,0(sp)
ffffffffc02018da:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02018dc:	85a6                	mv	a1,s1
ffffffffc02018de:	07800513          	li	a0,120
ffffffffc02018e2:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02018e4:	0aa1                	addi	s5,s5,8
ffffffffc02018e6:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc02018ea:	6782                	ld	a5,0(sp)
ffffffffc02018ec:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02018ee:	876e                	mv	a4,s11
ffffffffc02018f0:	85a6                	mv	a1,s1
ffffffffc02018f2:	854a                	mv	a0,s2
ffffffffc02018f4:	e1fff0ef          	jal	ra,ffffffffc0201712 <printnum>
            break;
ffffffffc02018f8:	b5c1                	j	ffffffffc02017b8 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02018fa:	000ab603          	ld	a2,0(s5)
ffffffffc02018fe:	0aa1                	addi	s5,s5,8
ffffffffc0201900:	1c060663          	beqz	a2,ffffffffc0201acc <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0201904:	00160413          	addi	s0,a2,1
ffffffffc0201908:	17b05c63          	blez	s11,ffffffffc0201a80 <vprintfmt+0x302>
ffffffffc020190c:	02d00593          	li	a1,45
ffffffffc0201910:	14b79263          	bne	a5,a1,ffffffffc0201a54 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201914:	00064783          	lbu	a5,0(a2)
ffffffffc0201918:	0007851b          	sext.w	a0,a5
ffffffffc020191c:	c905                	beqz	a0,ffffffffc020194c <vprintfmt+0x1ce>
ffffffffc020191e:	000cc563          	bltz	s9,ffffffffc0201928 <vprintfmt+0x1aa>
ffffffffc0201922:	3cfd                	addiw	s9,s9,-1
ffffffffc0201924:	036c8263          	beq	s9,s6,ffffffffc0201948 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0201928:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020192a:	18098463          	beqz	s3,ffffffffc0201ab2 <vprintfmt+0x334>
ffffffffc020192e:	3781                	addiw	a5,a5,-32
ffffffffc0201930:	18fbf163          	bleu	a5,s7,ffffffffc0201ab2 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0201934:	03f00513          	li	a0,63
ffffffffc0201938:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020193a:	0405                	addi	s0,s0,1
ffffffffc020193c:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201940:	3dfd                	addiw	s11,s11,-1
ffffffffc0201942:	0007851b          	sext.w	a0,a5
ffffffffc0201946:	fd61                	bnez	a0,ffffffffc020191e <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc0201948:	e7b058e3          	blez	s11,ffffffffc02017b8 <vprintfmt+0x3a>
ffffffffc020194c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020194e:	85a6                	mv	a1,s1
ffffffffc0201950:	02000513          	li	a0,32
ffffffffc0201954:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201956:	e60d81e3          	beqz	s11,ffffffffc02017b8 <vprintfmt+0x3a>
ffffffffc020195a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020195c:	85a6                	mv	a1,s1
ffffffffc020195e:	02000513          	li	a0,32
ffffffffc0201962:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201964:	fe0d94e3          	bnez	s11,ffffffffc020194c <vprintfmt+0x1ce>
ffffffffc0201968:	bd81                	j	ffffffffc02017b8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020196a:	4705                	li	a4,1
ffffffffc020196c:	008a8593          	addi	a1,s5,8
ffffffffc0201970:	01074463          	blt	a4,a6,ffffffffc0201978 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0201974:	12080063          	beqz	a6,ffffffffc0201a94 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0201978:	000ab603          	ld	a2,0(s5)
ffffffffc020197c:	46a9                	li	a3,10
ffffffffc020197e:	8aae                	mv	s5,a1
ffffffffc0201980:	b7bd                	j	ffffffffc02018ee <vprintfmt+0x170>
ffffffffc0201982:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc0201986:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020198a:	846a                	mv	s0,s10
ffffffffc020198c:	b5ad                	j	ffffffffc02017f6 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc020198e:	85a6                	mv	a1,s1
ffffffffc0201990:	02500513          	li	a0,37
ffffffffc0201994:	9902                	jalr	s2
            break;
ffffffffc0201996:	b50d                	j	ffffffffc02017b8 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc0201998:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc020199c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02019a0:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019a2:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc02019a4:	e40dd9e3          	bgez	s11,ffffffffc02017f6 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc02019a8:	8de6                	mv	s11,s9
ffffffffc02019aa:	5cfd                	li	s9,-1
ffffffffc02019ac:	b5a9                	j	ffffffffc02017f6 <vprintfmt+0x78>
            goto reswitch;
ffffffffc02019ae:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc02019b2:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019b6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02019b8:	bd3d                	j	ffffffffc02017f6 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc02019ba:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc02019be:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019c2:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02019c4:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02019c8:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02019cc:	fcd56ce3          	bltu	a0,a3,ffffffffc02019a4 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc02019d0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02019d2:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02019d6:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02019da:	0196873b          	addw	a4,a3,s9
ffffffffc02019de:	0017171b          	slliw	a4,a4,0x1
ffffffffc02019e2:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc02019e6:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc02019ea:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02019ee:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02019f2:	fcd57fe3          	bleu	a3,a0,ffffffffc02019d0 <vprintfmt+0x252>
ffffffffc02019f6:	b77d                	j	ffffffffc02019a4 <vprintfmt+0x226>
            if (width < 0)
ffffffffc02019f8:	fffdc693          	not	a3,s11
ffffffffc02019fc:	96fd                	srai	a3,a3,0x3f
ffffffffc02019fe:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201a02:	00144603          	lbu	a2,1(s0)
ffffffffc0201a06:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a08:	846a                	mv	s0,s10
ffffffffc0201a0a:	b3f5                	j	ffffffffc02017f6 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0201a0c:	85a6                	mv	a1,s1
ffffffffc0201a0e:	02500513          	li	a0,37
ffffffffc0201a12:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201a14:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201a18:	02500793          	li	a5,37
ffffffffc0201a1c:	8d22                	mv	s10,s0
ffffffffc0201a1e:	d8f70de3          	beq	a4,a5,ffffffffc02017b8 <vprintfmt+0x3a>
ffffffffc0201a22:	02500713          	li	a4,37
ffffffffc0201a26:	1d7d                	addi	s10,s10,-1
ffffffffc0201a28:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0201a2c:	fee79de3          	bne	a5,a4,ffffffffc0201a26 <vprintfmt+0x2a8>
ffffffffc0201a30:	b361                	j	ffffffffc02017b8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201a32:	00001617          	auipc	a2,0x1
ffffffffc0201a36:	28660613          	addi	a2,a2,646 # ffffffffc0202cb8 <error_string+0xd8>
ffffffffc0201a3a:	85a6                	mv	a1,s1
ffffffffc0201a3c:	854a                	mv	a0,s2
ffffffffc0201a3e:	0ac000ef          	jal	ra,ffffffffc0201aea <printfmt>
ffffffffc0201a42:	bb9d                	j	ffffffffc02017b8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201a44:	00001617          	auipc	a2,0x1
ffffffffc0201a48:	26c60613          	addi	a2,a2,620 # ffffffffc0202cb0 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0201a4c:	00001417          	auipc	s0,0x1
ffffffffc0201a50:	26540413          	addi	s0,s0,613 # ffffffffc0202cb1 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201a54:	8532                	mv	a0,a2
ffffffffc0201a56:	85e6                	mv	a1,s9
ffffffffc0201a58:	e032                	sd	a2,0(sp)
ffffffffc0201a5a:	e43e                	sd	a5,8(sp)
ffffffffc0201a5c:	1de000ef          	jal	ra,ffffffffc0201c3a <strnlen>
ffffffffc0201a60:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201a64:	6602                	ld	a2,0(sp)
ffffffffc0201a66:	01b05d63          	blez	s11,ffffffffc0201a80 <vprintfmt+0x302>
ffffffffc0201a6a:	67a2                	ld	a5,8(sp)
ffffffffc0201a6c:	2781                	sext.w	a5,a5
ffffffffc0201a6e:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0201a70:	6522                	ld	a0,8(sp)
ffffffffc0201a72:	85a6                	mv	a1,s1
ffffffffc0201a74:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201a76:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201a78:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201a7a:	6602                	ld	a2,0(sp)
ffffffffc0201a7c:	fe0d9ae3          	bnez	s11,ffffffffc0201a70 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201a80:	00064783          	lbu	a5,0(a2)
ffffffffc0201a84:	0007851b          	sext.w	a0,a5
ffffffffc0201a88:	e8051be3          	bnez	a0,ffffffffc020191e <vprintfmt+0x1a0>
ffffffffc0201a8c:	b335                	j	ffffffffc02017b8 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc0201a8e:	000aa403          	lw	s0,0(s5)
ffffffffc0201a92:	bbf1                	j	ffffffffc020186e <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc0201a94:	000ae603          	lwu	a2,0(s5)
ffffffffc0201a98:	46a9                	li	a3,10
ffffffffc0201a9a:	8aae                	mv	s5,a1
ffffffffc0201a9c:	bd89                	j	ffffffffc02018ee <vprintfmt+0x170>
ffffffffc0201a9e:	000ae603          	lwu	a2,0(s5)
ffffffffc0201aa2:	46c1                	li	a3,16
ffffffffc0201aa4:	8aae                	mv	s5,a1
ffffffffc0201aa6:	b5a1                	j	ffffffffc02018ee <vprintfmt+0x170>
ffffffffc0201aa8:	000ae603          	lwu	a2,0(s5)
ffffffffc0201aac:	46a1                	li	a3,8
ffffffffc0201aae:	8aae                	mv	s5,a1
ffffffffc0201ab0:	bd3d                	j	ffffffffc02018ee <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0201ab2:	9902                	jalr	s2
ffffffffc0201ab4:	b559                	j	ffffffffc020193a <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc0201ab6:	85a6                	mv	a1,s1
ffffffffc0201ab8:	02d00513          	li	a0,45
ffffffffc0201abc:	e03e                	sd	a5,0(sp)
ffffffffc0201abe:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201ac0:	8ace                	mv	s5,s3
ffffffffc0201ac2:	40800633          	neg	a2,s0
ffffffffc0201ac6:	46a9                	li	a3,10
ffffffffc0201ac8:	6782                	ld	a5,0(sp)
ffffffffc0201aca:	b515                	j	ffffffffc02018ee <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc0201acc:	01b05663          	blez	s11,ffffffffc0201ad8 <vprintfmt+0x35a>
ffffffffc0201ad0:	02d00693          	li	a3,45
ffffffffc0201ad4:	f6d798e3          	bne	a5,a3,ffffffffc0201a44 <vprintfmt+0x2c6>
ffffffffc0201ad8:	00001417          	auipc	s0,0x1
ffffffffc0201adc:	1d940413          	addi	s0,s0,473 # ffffffffc0202cb1 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ae0:	02800513          	li	a0,40
ffffffffc0201ae4:	02800793          	li	a5,40
ffffffffc0201ae8:	bd1d                	j	ffffffffc020191e <vprintfmt+0x1a0>

ffffffffc0201aea <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201aea:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201aec:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201af0:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201af2:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201af4:	ec06                	sd	ra,24(sp)
ffffffffc0201af6:	f83a                	sd	a4,48(sp)
ffffffffc0201af8:	fc3e                	sd	a5,56(sp)
ffffffffc0201afa:	e0c2                	sd	a6,64(sp)
ffffffffc0201afc:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201afe:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201b00:	c7fff0ef          	jal	ra,ffffffffc020177e <vprintfmt>
}
ffffffffc0201b04:	60e2                	ld	ra,24(sp)
ffffffffc0201b06:	6161                	addi	sp,sp,80
ffffffffc0201b08:	8082                	ret

ffffffffc0201b0a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201b0a:	715d                	addi	sp,sp,-80
ffffffffc0201b0c:	e486                	sd	ra,72(sp)
ffffffffc0201b0e:	e0a2                	sd	s0,64(sp)
ffffffffc0201b10:	fc26                	sd	s1,56(sp)
ffffffffc0201b12:	f84a                	sd	s2,48(sp)
ffffffffc0201b14:	f44e                	sd	s3,40(sp)
ffffffffc0201b16:	f052                	sd	s4,32(sp)
ffffffffc0201b18:	ec56                	sd	s5,24(sp)
ffffffffc0201b1a:	e85a                	sd	s6,16(sp)
ffffffffc0201b1c:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc0201b1e:	c901                	beqz	a0,ffffffffc0201b2e <readline+0x24>
        cprintf("%s", prompt);
ffffffffc0201b20:	85aa                	mv	a1,a0
ffffffffc0201b22:	00001517          	auipc	a0,0x1
ffffffffc0201b26:	1a650513          	addi	a0,a0,422 # ffffffffc0202cc8 <error_string+0xe8>
ffffffffc0201b2a:	d8cfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
readline(const char *prompt) {
ffffffffc0201b2e:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201b30:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201b32:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201b34:	4aa9                	li	s5,10
ffffffffc0201b36:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201b38:	00004b97          	auipc	s7,0x4
ffffffffc0201b3c:	4e0b8b93          	addi	s7,s7,1248 # ffffffffc0206018 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201b40:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201b44:	deafe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201b48:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201b4a:	00054b63          	bltz	a0,ffffffffc0201b60 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201b4e:	00a95b63          	ble	a0,s2,ffffffffc0201b64 <readline+0x5a>
ffffffffc0201b52:	029a5463          	ble	s1,s4,ffffffffc0201b7a <readline+0x70>
        c = getchar();
ffffffffc0201b56:	dd8fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201b5a:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201b5c:	fe0559e3          	bgez	a0,ffffffffc0201b4e <readline+0x44>
            return NULL;
ffffffffc0201b60:	4501                	li	a0,0
ffffffffc0201b62:	a099                	j	ffffffffc0201ba8 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0201b64:	03341463          	bne	s0,s3,ffffffffc0201b8c <readline+0x82>
ffffffffc0201b68:	e8b9                	bnez	s1,ffffffffc0201bbe <readline+0xb4>
        c = getchar();
ffffffffc0201b6a:	dc4fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc0201b6e:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201b70:	fe0548e3          	bltz	a0,ffffffffc0201b60 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201b74:	fea958e3          	ble	a0,s2,ffffffffc0201b64 <readline+0x5a>
ffffffffc0201b78:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201b7a:	8522                	mv	a0,s0
ffffffffc0201b7c:	d6efe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i ++] = c;
ffffffffc0201b80:	009b87b3          	add	a5,s7,s1
ffffffffc0201b84:	00878023          	sb	s0,0(a5)
ffffffffc0201b88:	2485                	addiw	s1,s1,1
ffffffffc0201b8a:	bf6d                	j	ffffffffc0201b44 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0201b8c:	01540463          	beq	s0,s5,ffffffffc0201b94 <readline+0x8a>
ffffffffc0201b90:	fb641ae3          	bne	s0,s6,ffffffffc0201b44 <readline+0x3a>
            cputchar(c);
ffffffffc0201b94:	8522                	mv	a0,s0
ffffffffc0201b96:	d54fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i] = '\0';
ffffffffc0201b9a:	00004517          	auipc	a0,0x4
ffffffffc0201b9e:	47e50513          	addi	a0,a0,1150 # ffffffffc0206018 <edata>
ffffffffc0201ba2:	94aa                	add	s1,s1,a0
ffffffffc0201ba4:	00048023          	sb	zero,0(s1) # ffffffffc0200000 <kern_entry>
            return buf;
        }
    }
}
ffffffffc0201ba8:	60a6                	ld	ra,72(sp)
ffffffffc0201baa:	6406                	ld	s0,64(sp)
ffffffffc0201bac:	74e2                	ld	s1,56(sp)
ffffffffc0201bae:	7942                	ld	s2,48(sp)
ffffffffc0201bb0:	79a2                	ld	s3,40(sp)
ffffffffc0201bb2:	7a02                	ld	s4,32(sp)
ffffffffc0201bb4:	6ae2                	ld	s5,24(sp)
ffffffffc0201bb6:	6b42                	ld	s6,16(sp)
ffffffffc0201bb8:	6ba2                	ld	s7,8(sp)
ffffffffc0201bba:	6161                	addi	sp,sp,80
ffffffffc0201bbc:	8082                	ret
            cputchar(c);
ffffffffc0201bbe:	4521                	li	a0,8
ffffffffc0201bc0:	d2afe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            i --;
ffffffffc0201bc4:	34fd                	addiw	s1,s1,-1
ffffffffc0201bc6:	bfbd                	j	ffffffffc0201b44 <readline+0x3a>

ffffffffc0201bc8 <sbi_console_putchar>:
    return ret_val;
}

void sbi_console_putchar(unsigned char ch)
{
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201bc8:	00004797          	auipc	a5,0x4
ffffffffc0201bcc:	44078793          	addi	a5,a5,1088 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile(
ffffffffc0201bd0:	6398                	ld	a4,0(a5)
ffffffffc0201bd2:	4781                	li	a5,0
ffffffffc0201bd4:	88ba                	mv	a7,a4
ffffffffc0201bd6:	852a                	mv	a0,a0
ffffffffc0201bd8:	85be                	mv	a1,a5
ffffffffc0201bda:	863e                	mv	a2,a5
ffffffffc0201bdc:	00000073          	ecall
ffffffffc0201be0:	87aa                	mv	a5,a0
}
ffffffffc0201be2:	8082                	ret

ffffffffc0201be4 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value)
{
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201be4:	00005797          	auipc	a5,0x5
ffffffffc0201be8:	85478793          	addi	a5,a5,-1964 # ffffffffc0206438 <SBI_SET_TIMER>
    __asm__ volatile(
ffffffffc0201bec:	6398                	ld	a4,0(a5)
ffffffffc0201bee:	4781                	li	a5,0
ffffffffc0201bf0:	88ba                	mv	a7,a4
ffffffffc0201bf2:	852a                	mv	a0,a0
ffffffffc0201bf4:	85be                	mv	a1,a5
ffffffffc0201bf6:	863e                	mv	a2,a5
ffffffffc0201bf8:	00000073          	ecall
ffffffffc0201bfc:	87aa                	mv	a5,a0
}
ffffffffc0201bfe:	8082                	ret

ffffffffc0201c00 <sbi_console_getchar>:

int sbi_console_getchar(void)
{
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201c00:	00004797          	auipc	a5,0x4
ffffffffc0201c04:	40078793          	addi	a5,a5,1024 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile(
ffffffffc0201c08:	639c                	ld	a5,0(a5)
ffffffffc0201c0a:	4501                	li	a0,0
ffffffffc0201c0c:	88be                	mv	a7,a5
ffffffffc0201c0e:	852a                	mv	a0,a0
ffffffffc0201c10:	85aa                	mv	a1,a0
ffffffffc0201c12:	862a                	mv	a2,a0
ffffffffc0201c14:	00000073          	ecall
ffffffffc0201c18:	852a                	mv	a0,a0
}
ffffffffc0201c1a:	2501                	sext.w	a0,a0
ffffffffc0201c1c:	8082                	ret

ffffffffc0201c1e <sbi_shutdown>:

void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201c1e:	00004797          	auipc	a5,0x4
ffffffffc0201c22:	3f278793          	addi	a5,a5,1010 # ffffffffc0206010 <SBI_SHUTDOWN>
    __asm__ volatile(
ffffffffc0201c26:	6398                	ld	a4,0(a5)
ffffffffc0201c28:	4781                	li	a5,0
ffffffffc0201c2a:	88ba                	mv	a7,a4
ffffffffc0201c2c:	853e                	mv	a0,a5
ffffffffc0201c2e:	85be                	mv	a1,a5
ffffffffc0201c30:	863e                	mv	a2,a5
ffffffffc0201c32:	00000073          	ecall
ffffffffc0201c36:	87aa                	mv	a5,a0
ffffffffc0201c38:	8082                	ret

ffffffffc0201c3a <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201c3a:	c185                	beqz	a1,ffffffffc0201c5a <strnlen+0x20>
ffffffffc0201c3c:	00054783          	lbu	a5,0(a0)
ffffffffc0201c40:	cf89                	beqz	a5,ffffffffc0201c5a <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0201c42:	4781                	li	a5,0
ffffffffc0201c44:	a021                	j	ffffffffc0201c4c <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201c46:	00074703          	lbu	a4,0(a4)
ffffffffc0201c4a:	c711                	beqz	a4,ffffffffc0201c56 <strnlen+0x1c>
        cnt ++;
ffffffffc0201c4c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201c4e:	00f50733          	add	a4,a0,a5
ffffffffc0201c52:	fef59ae3          	bne	a1,a5,ffffffffc0201c46 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0201c56:	853e                	mv	a0,a5
ffffffffc0201c58:	8082                	ret
    size_t cnt = 0;
ffffffffc0201c5a:	4781                	li	a5,0
}
ffffffffc0201c5c:	853e                	mv	a0,a5
ffffffffc0201c5e:	8082                	ret

ffffffffc0201c60 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201c60:	00054783          	lbu	a5,0(a0)
ffffffffc0201c64:	0005c703          	lbu	a4,0(a1) # fffffffffffff000 <end+0x3fdf8b80>
ffffffffc0201c68:	cb91                	beqz	a5,ffffffffc0201c7c <strcmp+0x1c>
ffffffffc0201c6a:	00e79c63          	bne	a5,a4,ffffffffc0201c82 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0201c6e:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201c70:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0201c74:	0585                	addi	a1,a1,1
ffffffffc0201c76:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201c7a:	fbe5                	bnez	a5,ffffffffc0201c6a <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201c7c:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201c7e:	9d19                	subw	a0,a0,a4
ffffffffc0201c80:	8082                	ret
ffffffffc0201c82:	0007851b          	sext.w	a0,a5
ffffffffc0201c86:	9d19                	subw	a0,a0,a4
ffffffffc0201c88:	8082                	ret

ffffffffc0201c8a <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201c8a:	00054783          	lbu	a5,0(a0)
ffffffffc0201c8e:	cb91                	beqz	a5,ffffffffc0201ca2 <strchr+0x18>
        if (*s == c) {
ffffffffc0201c90:	00b79563          	bne	a5,a1,ffffffffc0201c9a <strchr+0x10>
ffffffffc0201c94:	a809                	j	ffffffffc0201ca6 <strchr+0x1c>
ffffffffc0201c96:	00b78763          	beq	a5,a1,ffffffffc0201ca4 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0201c9a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201c9c:	00054783          	lbu	a5,0(a0)
ffffffffc0201ca0:	fbfd                	bnez	a5,ffffffffc0201c96 <strchr+0xc>
    }
    return NULL;
ffffffffc0201ca2:	4501                	li	a0,0
}
ffffffffc0201ca4:	8082                	ret
ffffffffc0201ca6:	8082                	ret

ffffffffc0201ca8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201ca8:	ca01                	beqz	a2,ffffffffc0201cb8 <memset+0x10>
ffffffffc0201caa:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201cac:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201cae:	0785                	addi	a5,a5,1
ffffffffc0201cb0:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201cb4:	fec79de3          	bne	a5,a2,ffffffffc0201cae <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201cb8:	8082                	ret
