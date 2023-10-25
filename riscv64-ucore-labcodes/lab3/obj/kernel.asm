
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02092b7          	lui	t0,0xc0209
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
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
ffffffffc0200028:	c0209137          	lui	sp,0xc0209

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:


int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	0000a517          	auipc	a0,0xa
ffffffffc020003a:	00a50513          	addi	a0,a0,10 # ffffffffc020a040 <edata>
ffffffffc020003e:	00011617          	auipc	a2,0x11
ffffffffc0200042:	56260613          	addi	a2,a2,1378 # ffffffffc02115a0 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	30e040ef          	jal	ra,ffffffffc020435c <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00004597          	auipc	a1,0x4
ffffffffc0200056:	33658593          	addi	a1,a1,822 # ffffffffc0204388 <etext+0x2>
ffffffffc020005a:	00004517          	auipc	a0,0x4
ffffffffc020005e:	34e50513          	addi	a0,a0,846 # ffffffffc02043a8 <etext+0x22>
ffffffffc0200062:	05c000ef          	jal	ra,ffffffffc02000be <cprintf>

    print_kerninfo();
ffffffffc0200066:	0a0000ef          	jal	ra,ffffffffc0200106 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	2ff010ef          	jal	ra,ffffffffc0201b68 <pmm_init>

    idt_init();                 // init interrupt descriptor table
ffffffffc020006e:	504000ef          	jal	ra,ffffffffc0200572 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200072:	5ca030ef          	jal	ra,ffffffffc020363c <vmm_init>

    ide_init();                 // init ide devices
ffffffffc0200076:	426000ef          	jal	ra,ffffffffc020049c <ide_init>
    swap_init();                // init swap
ffffffffc020007a:	7e4020ef          	jal	ra,ffffffffc020285e <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020007e:	356000ef          	jal	ra,ffffffffc02003d4 <clock_init>
    // intr_enable();              // enable irq interrupt



    /* do nothing */
    while (1);
ffffffffc0200082:	a001                	j	ffffffffc0200082 <kern_init+0x4c>

ffffffffc0200084 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200084:	1141                	addi	sp,sp,-16
ffffffffc0200086:	e022                	sd	s0,0(sp)
ffffffffc0200088:	e406                	sd	ra,8(sp)
ffffffffc020008a:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020008c:	39e000ef          	jal	ra,ffffffffc020042a <cons_putc>
    (*cnt) ++;
ffffffffc0200090:	401c                	lw	a5,0(s0)
}
ffffffffc0200092:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200094:	2785                	addiw	a5,a5,1
ffffffffc0200096:	c01c                	sw	a5,0(s0)
}
ffffffffc0200098:	6402                	ld	s0,0(sp)
ffffffffc020009a:	0141                	addi	sp,sp,16
ffffffffc020009c:	8082                	ret

ffffffffc020009e <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020009e:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a0:	86ae                	mv	a3,a1
ffffffffc02000a2:	862a                	mv	a2,a0
ffffffffc02000a4:	006c                	addi	a1,sp,12
ffffffffc02000a6:	00000517          	auipc	a0,0x0
ffffffffc02000aa:	fde50513          	addi	a0,a0,-34 # ffffffffc0200084 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ae:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000b0:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	5c3030ef          	jal	ra,ffffffffc0203e74 <vprintfmt>
    return cnt;
}
ffffffffc02000b6:	60e2                	ld	ra,24(sp)
ffffffffc02000b8:	4532                	lw	a0,12(sp)
ffffffffc02000ba:	6105                	addi	sp,sp,32
ffffffffc02000bc:	8082                	ret

ffffffffc02000be <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000be:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000c0:	02810313          	addi	t1,sp,40 # ffffffffc0209028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000c4:	f42e                	sd	a1,40(sp)
ffffffffc02000c6:	f832                	sd	a2,48(sp)
ffffffffc02000c8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ca:	862a                	mv	a2,a0
ffffffffc02000cc:	004c                	addi	a1,sp,4
ffffffffc02000ce:	00000517          	auipc	a0,0x0
ffffffffc02000d2:	fb650513          	addi	a0,a0,-74 # ffffffffc0200084 <cputch>
ffffffffc02000d6:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	ec06                	sd	ra,24(sp)
ffffffffc02000da:	e0ba                	sd	a4,64(sp)
ffffffffc02000dc:	e4be                	sd	a5,72(sp)
ffffffffc02000de:	e8c2                	sd	a6,80(sp)
ffffffffc02000e0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000e2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000e4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	58f030ef          	jal	ra,ffffffffc0203e74 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000ea:	60e2                	ld	ra,24(sp)
ffffffffc02000ec:	4512                	lw	a0,4(sp)
ffffffffc02000ee:	6125                	addi	sp,sp,96
ffffffffc02000f0:	8082                	ret

ffffffffc02000f2 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000f2:	3380006f          	j	ffffffffc020042a <cons_putc>

ffffffffc02000f6 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02000f6:	1141                	addi	sp,sp,-16
ffffffffc02000f8:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02000fa:	366000ef          	jal	ra,ffffffffc0200460 <cons_getc>
ffffffffc02000fe:	dd75                	beqz	a0,ffffffffc02000fa <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200100:	60a2                	ld	ra,8(sp)
ffffffffc0200102:	0141                	addi	sp,sp,16
ffffffffc0200104:	8082                	ret

ffffffffc0200106 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200106:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200108:	00004517          	auipc	a0,0x4
ffffffffc020010c:	2d850513          	addi	a0,a0,728 # ffffffffc02043e0 <etext+0x5a>
void print_kerninfo(void) {
ffffffffc0200110:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200112:	fadff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200116:	00000597          	auipc	a1,0x0
ffffffffc020011a:	f2058593          	addi	a1,a1,-224 # ffffffffc0200036 <kern_init>
ffffffffc020011e:	00004517          	auipc	a0,0x4
ffffffffc0200122:	2e250513          	addi	a0,a0,738 # ffffffffc0204400 <etext+0x7a>
ffffffffc0200126:	f99ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020012a:	00004597          	auipc	a1,0x4
ffffffffc020012e:	25c58593          	addi	a1,a1,604 # ffffffffc0204386 <etext>
ffffffffc0200132:	00004517          	auipc	a0,0x4
ffffffffc0200136:	2ee50513          	addi	a0,a0,750 # ffffffffc0204420 <etext+0x9a>
ffffffffc020013a:	f85ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020013e:	0000a597          	auipc	a1,0xa
ffffffffc0200142:	f0258593          	addi	a1,a1,-254 # ffffffffc020a040 <edata>
ffffffffc0200146:	00004517          	auipc	a0,0x4
ffffffffc020014a:	2fa50513          	addi	a0,a0,762 # ffffffffc0204440 <etext+0xba>
ffffffffc020014e:	f71ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200152:	00011597          	auipc	a1,0x11
ffffffffc0200156:	44e58593          	addi	a1,a1,1102 # ffffffffc02115a0 <end>
ffffffffc020015a:	00004517          	auipc	a0,0x4
ffffffffc020015e:	30650513          	addi	a0,a0,774 # ffffffffc0204460 <etext+0xda>
ffffffffc0200162:	f5dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200166:	00012597          	auipc	a1,0x12
ffffffffc020016a:	83958593          	addi	a1,a1,-1991 # ffffffffc021199f <end+0x3ff>
ffffffffc020016e:	00000797          	auipc	a5,0x0
ffffffffc0200172:	ec878793          	addi	a5,a5,-312 # ffffffffc0200036 <kern_init>
ffffffffc0200176:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020017a:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020017e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200180:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200184:	95be                	add	a1,a1,a5
ffffffffc0200186:	85a9                	srai	a1,a1,0xa
ffffffffc0200188:	00004517          	auipc	a0,0x4
ffffffffc020018c:	2f850513          	addi	a0,a0,760 # ffffffffc0204480 <etext+0xfa>
}
ffffffffc0200190:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200192:	f2dff06f          	j	ffffffffc02000be <cprintf>

ffffffffc0200196 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200196:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc0200198:	00004617          	auipc	a2,0x4
ffffffffc020019c:	21860613          	addi	a2,a2,536 # ffffffffc02043b0 <etext+0x2a>
ffffffffc02001a0:	04e00593          	li	a1,78
ffffffffc02001a4:	00004517          	auipc	a0,0x4
ffffffffc02001a8:	22450513          	addi	a0,a0,548 # ffffffffc02043c8 <etext+0x42>
void print_stackframe(void) {
ffffffffc02001ac:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001ae:	1c6000ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02001b2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001b2:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001b4:	00004617          	auipc	a2,0x4
ffffffffc02001b8:	3d460613          	addi	a2,a2,980 # ffffffffc0204588 <commands+0xd8>
ffffffffc02001bc:	00004597          	auipc	a1,0x4
ffffffffc02001c0:	3ec58593          	addi	a1,a1,1004 # ffffffffc02045a8 <commands+0xf8>
ffffffffc02001c4:	00004517          	auipc	a0,0x4
ffffffffc02001c8:	3ec50513          	addi	a0,a0,1004 # ffffffffc02045b0 <commands+0x100>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001cc:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001ce:	ef1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02001d2:	00004617          	auipc	a2,0x4
ffffffffc02001d6:	3ee60613          	addi	a2,a2,1006 # ffffffffc02045c0 <commands+0x110>
ffffffffc02001da:	00004597          	auipc	a1,0x4
ffffffffc02001de:	40e58593          	addi	a1,a1,1038 # ffffffffc02045e8 <commands+0x138>
ffffffffc02001e2:	00004517          	auipc	a0,0x4
ffffffffc02001e6:	3ce50513          	addi	a0,a0,974 # ffffffffc02045b0 <commands+0x100>
ffffffffc02001ea:	ed5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02001ee:	00004617          	auipc	a2,0x4
ffffffffc02001f2:	40a60613          	addi	a2,a2,1034 # ffffffffc02045f8 <commands+0x148>
ffffffffc02001f6:	00004597          	auipc	a1,0x4
ffffffffc02001fa:	42258593          	addi	a1,a1,1058 # ffffffffc0204618 <commands+0x168>
ffffffffc02001fe:	00004517          	auipc	a0,0x4
ffffffffc0200202:	3b250513          	addi	a0,a0,946 # ffffffffc02045b0 <commands+0x100>
ffffffffc0200206:	eb9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    }
    return 0;
}
ffffffffc020020a:	60a2                	ld	ra,8(sp)
ffffffffc020020c:	4501                	li	a0,0
ffffffffc020020e:	0141                	addi	sp,sp,16
ffffffffc0200210:	8082                	ret

ffffffffc0200212 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200212:	1141                	addi	sp,sp,-16
ffffffffc0200214:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200216:	ef1ff0ef          	jal	ra,ffffffffc0200106 <print_kerninfo>
    return 0;
}
ffffffffc020021a:	60a2                	ld	ra,8(sp)
ffffffffc020021c:	4501                	li	a0,0
ffffffffc020021e:	0141                	addi	sp,sp,16
ffffffffc0200220:	8082                	ret

ffffffffc0200222 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200222:	1141                	addi	sp,sp,-16
ffffffffc0200224:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200226:	f71ff0ef          	jal	ra,ffffffffc0200196 <print_stackframe>
    return 0;
}
ffffffffc020022a:	60a2                	ld	ra,8(sp)
ffffffffc020022c:	4501                	li	a0,0
ffffffffc020022e:	0141                	addi	sp,sp,16
ffffffffc0200230:	8082                	ret

ffffffffc0200232 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200232:	7115                	addi	sp,sp,-224
ffffffffc0200234:	e962                	sd	s8,144(sp)
ffffffffc0200236:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200238:	00004517          	auipc	a0,0x4
ffffffffc020023c:	2c050513          	addi	a0,a0,704 # ffffffffc02044f8 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200240:	ed86                	sd	ra,216(sp)
ffffffffc0200242:	e9a2                	sd	s0,208(sp)
ffffffffc0200244:	e5a6                	sd	s1,200(sp)
ffffffffc0200246:	e1ca                	sd	s2,192(sp)
ffffffffc0200248:	fd4e                	sd	s3,184(sp)
ffffffffc020024a:	f952                	sd	s4,176(sp)
ffffffffc020024c:	f556                	sd	s5,168(sp)
ffffffffc020024e:	f15a                	sd	s6,160(sp)
ffffffffc0200250:	ed5e                	sd	s7,152(sp)
ffffffffc0200252:	e566                	sd	s9,136(sp)
ffffffffc0200254:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200256:	e69ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020025a:	00004517          	auipc	a0,0x4
ffffffffc020025e:	2c650513          	addi	a0,a0,710 # ffffffffc0204520 <commands+0x70>
ffffffffc0200262:	e5dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    if (tf != NULL) {
ffffffffc0200266:	000c0563          	beqz	s8,ffffffffc0200270 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020026a:	8562                	mv	a0,s8
ffffffffc020026c:	4f2000ef          	jal	ra,ffffffffc020075e <print_trapframe>
ffffffffc0200270:	00004c97          	auipc	s9,0x4
ffffffffc0200274:	240c8c93          	addi	s9,s9,576 # ffffffffc02044b0 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc0200278:	00006997          	auipc	s3,0x6
ffffffffc020027c:	84898993          	addi	s3,s3,-1976 # ffffffffc0205ac0 <default_pmm_manager+0xa08>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200280:	00004917          	auipc	s2,0x4
ffffffffc0200284:	2c890913          	addi	s2,s2,712 # ffffffffc0204548 <commands+0x98>
        if (argc == MAXARGS - 1) {
ffffffffc0200288:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020028a:	00004b17          	auipc	s6,0x4
ffffffffc020028e:	2c6b0b13          	addi	s6,s6,710 # ffffffffc0204550 <commands+0xa0>
    if (argc == 0) {
ffffffffc0200292:	00004a97          	auipc	s5,0x4
ffffffffc0200296:	316a8a93          	addi	s5,s5,790 # ffffffffc02045a8 <commands+0xf8>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020029a:	4b8d                	li	s7,3
        if ((buf = readline("")) != NULL) {
ffffffffc020029c:	854e                	mv	a0,s3
ffffffffc020029e:	763030ef          	jal	ra,ffffffffc0204200 <readline>
ffffffffc02002a2:	842a                	mv	s0,a0
ffffffffc02002a4:	dd65                	beqz	a0,ffffffffc020029c <kmonitor+0x6a>
ffffffffc02002a6:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002aa:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002ac:	c999                	beqz	a1,ffffffffc02002c2 <kmonitor+0x90>
ffffffffc02002ae:	854a                	mv	a0,s2
ffffffffc02002b0:	08e040ef          	jal	ra,ffffffffc020433e <strchr>
ffffffffc02002b4:	c925                	beqz	a0,ffffffffc0200324 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02002b6:	00144583          	lbu	a1,1(s0)
ffffffffc02002ba:	00040023          	sb	zero,0(s0)
ffffffffc02002be:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002c0:	f5fd                	bnez	a1,ffffffffc02002ae <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02002c2:	dce9                	beqz	s1,ffffffffc020029c <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002c4:	6582                	ld	a1,0(sp)
ffffffffc02002c6:	00004d17          	auipc	s10,0x4
ffffffffc02002ca:	1ead0d13          	addi	s10,s10,490 # ffffffffc02044b0 <commands>
    if (argc == 0) {
ffffffffc02002ce:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d0:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002d2:	0d61                	addi	s10,s10,24
ffffffffc02002d4:	040040ef          	jal	ra,ffffffffc0204314 <strcmp>
ffffffffc02002d8:	c919                	beqz	a0,ffffffffc02002ee <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002da:	2405                	addiw	s0,s0,1
ffffffffc02002dc:	09740463          	beq	s0,s7,ffffffffc0200364 <kmonitor+0x132>
ffffffffc02002e0:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002e4:	6582                	ld	a1,0(sp)
ffffffffc02002e6:	0d61                	addi	s10,s10,24
ffffffffc02002e8:	02c040ef          	jal	ra,ffffffffc0204314 <strcmp>
ffffffffc02002ec:	f57d                	bnez	a0,ffffffffc02002da <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02002ee:	00141793          	slli	a5,s0,0x1
ffffffffc02002f2:	97a2                	add	a5,a5,s0
ffffffffc02002f4:	078e                	slli	a5,a5,0x3
ffffffffc02002f6:	97e6                	add	a5,a5,s9
ffffffffc02002f8:	6b9c                	ld	a5,16(a5)
ffffffffc02002fa:	8662                	mv	a2,s8
ffffffffc02002fc:	002c                	addi	a1,sp,8
ffffffffc02002fe:	fff4851b          	addiw	a0,s1,-1
ffffffffc0200302:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200304:	f8055ce3          	bgez	a0,ffffffffc020029c <kmonitor+0x6a>
}
ffffffffc0200308:	60ee                	ld	ra,216(sp)
ffffffffc020030a:	644e                	ld	s0,208(sp)
ffffffffc020030c:	64ae                	ld	s1,200(sp)
ffffffffc020030e:	690e                	ld	s2,192(sp)
ffffffffc0200310:	79ea                	ld	s3,184(sp)
ffffffffc0200312:	7a4a                	ld	s4,176(sp)
ffffffffc0200314:	7aaa                	ld	s5,168(sp)
ffffffffc0200316:	7b0a                	ld	s6,160(sp)
ffffffffc0200318:	6bea                	ld	s7,152(sp)
ffffffffc020031a:	6c4a                	ld	s8,144(sp)
ffffffffc020031c:	6caa                	ld	s9,136(sp)
ffffffffc020031e:	6d0a                	ld	s10,128(sp)
ffffffffc0200320:	612d                	addi	sp,sp,224
ffffffffc0200322:	8082                	ret
        if (*buf == '\0') {
ffffffffc0200324:	00044783          	lbu	a5,0(s0)
ffffffffc0200328:	dfc9                	beqz	a5,ffffffffc02002c2 <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc020032a:	03448863          	beq	s1,s4,ffffffffc020035a <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc020032e:	00349793          	slli	a5,s1,0x3
ffffffffc0200332:	0118                	addi	a4,sp,128
ffffffffc0200334:	97ba                	add	a5,a5,a4
ffffffffc0200336:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020033a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020033e:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200340:	e591                	bnez	a1,ffffffffc020034c <kmonitor+0x11a>
ffffffffc0200342:	b749                	j	ffffffffc02002c4 <kmonitor+0x92>
            buf ++;
ffffffffc0200344:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200346:	00044583          	lbu	a1,0(s0)
ffffffffc020034a:	ddad                	beqz	a1,ffffffffc02002c4 <kmonitor+0x92>
ffffffffc020034c:	854a                	mv	a0,s2
ffffffffc020034e:	7f1030ef          	jal	ra,ffffffffc020433e <strchr>
ffffffffc0200352:	d96d                	beqz	a0,ffffffffc0200344 <kmonitor+0x112>
ffffffffc0200354:	00044583          	lbu	a1,0(s0)
ffffffffc0200358:	bf91                	j	ffffffffc02002ac <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020035a:	45c1                	li	a1,16
ffffffffc020035c:	855a                	mv	a0,s6
ffffffffc020035e:	d61ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0200362:	b7f1                	j	ffffffffc020032e <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200364:	6582                	ld	a1,0(sp)
ffffffffc0200366:	00004517          	auipc	a0,0x4
ffffffffc020036a:	20a50513          	addi	a0,a0,522 # ffffffffc0204570 <commands+0xc0>
ffffffffc020036e:	d51ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    return 0;
ffffffffc0200372:	b72d                	j	ffffffffc020029c <kmonitor+0x6a>

ffffffffc0200374 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200374:	00011317          	auipc	t1,0x11
ffffffffc0200378:	0cc30313          	addi	t1,t1,204 # ffffffffc0211440 <is_panic>
ffffffffc020037c:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200380:	715d                	addi	sp,sp,-80
ffffffffc0200382:	ec06                	sd	ra,24(sp)
ffffffffc0200384:	e822                	sd	s0,16(sp)
ffffffffc0200386:	f436                	sd	a3,40(sp)
ffffffffc0200388:	f83a                	sd	a4,48(sp)
ffffffffc020038a:	fc3e                	sd	a5,56(sp)
ffffffffc020038c:	e0c2                	sd	a6,64(sp)
ffffffffc020038e:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200390:	02031c63          	bnez	t1,ffffffffc02003c8 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200394:	4785                	li	a5,1
ffffffffc0200396:	8432                	mv	s0,a2
ffffffffc0200398:	00011717          	auipc	a4,0x11
ffffffffc020039c:	0af72423          	sw	a5,168(a4) # ffffffffc0211440 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003a0:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02003a2:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003a4:	85aa                	mv	a1,a0
ffffffffc02003a6:	00004517          	auipc	a0,0x4
ffffffffc02003aa:	28250513          	addi	a0,a0,642 # ffffffffc0204628 <commands+0x178>
    va_start(ap, fmt);
ffffffffc02003ae:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003b0:	d0fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003b4:	65a2                	ld	a1,8(sp)
ffffffffc02003b6:	8522                	mv	a0,s0
ffffffffc02003b8:	ce7ff0ef          	jal	ra,ffffffffc020009e <vcprintf>
    cprintf("\n");
ffffffffc02003bc:	00005517          	auipc	a0,0x5
ffffffffc02003c0:	21c50513          	addi	a0,a0,540 # ffffffffc02055d8 <default_pmm_manager+0x520>
ffffffffc02003c4:	cfbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003c8:	132000ef          	jal	ra,ffffffffc02004fa <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02003cc:	4501                	li	a0,0
ffffffffc02003ce:	e65ff0ef          	jal	ra,ffffffffc0200232 <kmonitor>
ffffffffc02003d2:	bfed                	j	ffffffffc02003cc <__panic+0x58>

ffffffffc02003d4 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02003d4:	67e1                	lui	a5,0x18
ffffffffc02003d6:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc02003da:	00011717          	auipc	a4,0x11
ffffffffc02003de:	06f73723          	sd	a5,110(a4) # ffffffffc0211448 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02003e2:	c0102573          	rdtime	a0
static inline void sbi_set_timer(uint64_t stime_value)
{
#if __riscv_xlen == 32
	SBI_CALL_2(SBI_SET_TIMER, stime_value, stime_value >> 32);
#else
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02003e6:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02003e8:	953e                	add	a0,a0,a5
ffffffffc02003ea:	4601                	li	a2,0
ffffffffc02003ec:	4881                	li	a7,0
ffffffffc02003ee:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02003f2:	02000793          	li	a5,32
ffffffffc02003f6:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02003fa:	00004517          	auipc	a0,0x4
ffffffffc02003fe:	24e50513          	addi	a0,a0,590 # ffffffffc0204648 <commands+0x198>
    ticks = 0;
ffffffffc0200402:	00011797          	auipc	a5,0x11
ffffffffc0200406:	0607bb23          	sd	zero,118(a5) # ffffffffc0211478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020040a:	cb5ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc020040e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020040e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200412:	00011797          	auipc	a5,0x11
ffffffffc0200416:	03678793          	addi	a5,a5,54 # ffffffffc0211448 <timebase>
ffffffffc020041a:	639c                	ld	a5,0(a5)
ffffffffc020041c:	4581                	li	a1,0
ffffffffc020041e:	4601                	li	a2,0
ffffffffc0200420:	953e                	add	a0,a0,a5
ffffffffc0200422:	4881                	li	a7,0
ffffffffc0200424:	00000073          	ecall
ffffffffc0200428:	8082                	ret

ffffffffc020042a <cons_putc>:
#include <intr.h>
#include <mmu.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020042a:	100027f3          	csrr	a5,sstatus
ffffffffc020042e:	8b89                	andi	a5,a5,2
ffffffffc0200430:	0ff57513          	andi	a0,a0,255
ffffffffc0200434:	e799                	bnez	a5,ffffffffc0200442 <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200436:	4581                	li	a1,0
ffffffffc0200438:	4601                	li	a2,0
ffffffffc020043a:	4885                	li	a7,1
ffffffffc020043c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200440:	8082                	ret

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200442:	1101                	addi	sp,sp,-32
ffffffffc0200444:	ec06                	sd	ra,24(sp)
ffffffffc0200446:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200448:	0b2000ef          	jal	ra,ffffffffc02004fa <intr_disable>
ffffffffc020044c:	6522                	ld	a0,8(sp)
ffffffffc020044e:	4581                	li	a1,0
ffffffffc0200450:	4601                	li	a2,0
ffffffffc0200452:	4885                	li	a7,1
ffffffffc0200454:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200458:	60e2                	ld	ra,24(sp)
ffffffffc020045a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020045c:	0980006f          	j	ffffffffc02004f4 <intr_enable>

ffffffffc0200460 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200460:	100027f3          	csrr	a5,sstatus
ffffffffc0200464:	8b89                	andi	a5,a5,2
ffffffffc0200466:	eb89                	bnez	a5,ffffffffc0200478 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200468:	4501                	li	a0,0
ffffffffc020046a:	4581                	li	a1,0
ffffffffc020046c:	4601                	li	a2,0
ffffffffc020046e:	4889                	li	a7,2
ffffffffc0200470:	00000073          	ecall
ffffffffc0200474:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200476:	8082                	ret
int cons_getc(void) {
ffffffffc0200478:	1101                	addi	sp,sp,-32
ffffffffc020047a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020047c:	07e000ef          	jal	ra,ffffffffc02004fa <intr_disable>
ffffffffc0200480:	4501                	li	a0,0
ffffffffc0200482:	4581                	li	a1,0
ffffffffc0200484:	4601                	li	a2,0
ffffffffc0200486:	4889                	li	a7,2
ffffffffc0200488:	00000073          	ecall
ffffffffc020048c:	2501                	sext.w	a0,a0
ffffffffc020048e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200490:	064000ef          	jal	ra,ffffffffc02004f4 <intr_enable>
}
ffffffffc0200494:	60e2                	ld	ra,24(sp)
ffffffffc0200496:	6522                	ld	a0,8(sp)
ffffffffc0200498:	6105                	addi	sp,sp,32
ffffffffc020049a:	8082                	ret

ffffffffc020049c <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc020049c:	8082                	ret

ffffffffc020049e <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc020049e:	00253513          	sltiu	a0,a0,2
ffffffffc02004a2:	8082                	ret

ffffffffc02004a4 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02004a4:	03800513          	li	a0,56
ffffffffc02004a8:	8082                	ret

ffffffffc02004aa <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004aa:	0000a797          	auipc	a5,0xa
ffffffffc02004ae:	b9678793          	addi	a5,a5,-1130 # ffffffffc020a040 <edata>
ffffffffc02004b2:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc02004b6:	1141                	addi	sp,sp,-16
ffffffffc02004b8:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004ba:	95be                	add	a1,a1,a5
ffffffffc02004bc:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc02004c0:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004c2:	6ad030ef          	jal	ra,ffffffffc020436e <memcpy>
    return 0;
}
ffffffffc02004c6:	60a2                	ld	ra,8(sp)
ffffffffc02004c8:	4501                	li	a0,0
ffffffffc02004ca:	0141                	addi	sp,sp,16
ffffffffc02004cc:	8082                	ret

ffffffffc02004ce <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc02004ce:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004d0:	0095979b          	slliw	a5,a1,0x9
ffffffffc02004d4:	0000a517          	auipc	a0,0xa
ffffffffc02004d8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc020a040 <edata>
                   size_t nsecs) {
ffffffffc02004dc:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004de:	00969613          	slli	a2,a3,0x9
ffffffffc02004e2:	85ba                	mv	a1,a4
ffffffffc02004e4:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc02004e6:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004e8:	687030ef          	jal	ra,ffffffffc020436e <memcpy>
    return 0;
}
ffffffffc02004ec:	60a2                	ld	ra,8(sp)
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	0141                	addi	sp,sp,16
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004f4:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02004f8:	8082                	ret

ffffffffc02004fa <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004fa:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02004fe:	8082                	ret

ffffffffc0200500 <pgfault_handler>:
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf)
{
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200500:	10053783          	ld	a5,256(a0)
            trap_in_kernel(tf) ? 'K' : 'U',                   // U表示用户态，K表示内核态
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R'); // W表示写了不存在的页，R表示读了不存在的页
}

static int pgfault_handler(struct trapframe *tf)
{
ffffffffc0200504:	1141                	addi	sp,sp,-16
ffffffffc0200506:	e022                	sd	s0,0(sp)
ffffffffc0200508:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020050a:	1007f793          	andi	a5,a5,256
{
ffffffffc020050e:	842a                	mv	s0,a0
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc0200510:	11053583          	ld	a1,272(a0)
ffffffffc0200514:	05500613          	li	a2,85
ffffffffc0200518:	c399                	beqz	a5,ffffffffc020051e <pgfault_handler+0x1e>
ffffffffc020051a:	04b00613          	li	a2,75
ffffffffc020051e:	11843703          	ld	a4,280(s0)
ffffffffc0200522:	47bd                	li	a5,15
ffffffffc0200524:	05700693          	li	a3,87
ffffffffc0200528:	00f70463          	beq	a4,a5,ffffffffc0200530 <pgfault_handler+0x30>
ffffffffc020052c:	05200693          	li	a3,82
ffffffffc0200530:	00004517          	auipc	a0,0x4
ffffffffc0200534:	41050513          	addi	a0,a0,1040 # ffffffffc0204940 <commands+0x490>
ffffffffc0200538:	b87ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL)
ffffffffc020053c:	00011797          	auipc	a5,0x11
ffffffffc0200540:	05c78793          	addi	a5,a5,92 # ffffffffc0211598 <check_mm_struct>
ffffffffc0200544:	6388                	ld	a0,0(a5)
ffffffffc0200546:	c911                	beqz	a0,ffffffffc020055a <pgfault_handler+0x5a>
    {
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200548:	11043603          	ld	a2,272(s0)
ffffffffc020054c:	11843583          	ld	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200550:	6402                	ld	s0,0(sp)
ffffffffc0200552:	60a2                	ld	ra,8(sp)
ffffffffc0200554:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200556:	6240306f          	j	ffffffffc0203b7a <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc020055a:	00004617          	auipc	a2,0x4
ffffffffc020055e:	40660613          	addi	a2,a2,1030 # ffffffffc0204960 <commands+0x4b0>
ffffffffc0200562:	08100593          	li	a1,129
ffffffffc0200566:	00004517          	auipc	a0,0x4
ffffffffc020056a:	41250513          	addi	a0,a0,1042 # ffffffffc0204978 <commands+0x4c8>
ffffffffc020056e:	e07ff0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0200572 <idt_init>:
    write_csr(sscratch, 0);
ffffffffc0200572:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200576:	00000797          	auipc	a5,0x0
ffffffffc020057a:	4ca78793          	addi	a5,a5,1226 # ffffffffc0200a40 <__alltraps>
ffffffffc020057e:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SIE);
ffffffffc0200582:	100167f3          	csrrsi	a5,sstatus,2
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200586:	000407b7          	lui	a5,0x40
ffffffffc020058a:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020058e:	8082                	ret

ffffffffc0200590 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200590:	610c                	ld	a1,0(a0)
{
ffffffffc0200592:	1141                	addi	sp,sp,-16
ffffffffc0200594:	e022                	sd	s0,0(sp)
ffffffffc0200596:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200598:	00004517          	auipc	a0,0x4
ffffffffc020059c:	3f850513          	addi	a0,a0,1016 # ffffffffc0204990 <commands+0x4e0>
{
ffffffffc02005a0:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02005a2:	b1dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02005a6:	640c                	ld	a1,8(s0)
ffffffffc02005a8:	00004517          	auipc	a0,0x4
ffffffffc02005ac:	40050513          	addi	a0,a0,1024 # ffffffffc02049a8 <commands+0x4f8>
ffffffffc02005b0:	b0fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02005b4:	680c                	ld	a1,16(s0)
ffffffffc02005b6:	00004517          	auipc	a0,0x4
ffffffffc02005ba:	40a50513          	addi	a0,a0,1034 # ffffffffc02049c0 <commands+0x510>
ffffffffc02005be:	b01ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02005c2:	6c0c                	ld	a1,24(s0)
ffffffffc02005c4:	00004517          	auipc	a0,0x4
ffffffffc02005c8:	41450513          	addi	a0,a0,1044 # ffffffffc02049d8 <commands+0x528>
ffffffffc02005cc:	af3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02005d0:	700c                	ld	a1,32(s0)
ffffffffc02005d2:	00004517          	auipc	a0,0x4
ffffffffc02005d6:	41e50513          	addi	a0,a0,1054 # ffffffffc02049f0 <commands+0x540>
ffffffffc02005da:	ae5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02005de:	740c                	ld	a1,40(s0)
ffffffffc02005e0:	00004517          	auipc	a0,0x4
ffffffffc02005e4:	42850513          	addi	a0,a0,1064 # ffffffffc0204a08 <commands+0x558>
ffffffffc02005e8:	ad7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005ec:	780c                	ld	a1,48(s0)
ffffffffc02005ee:	00004517          	auipc	a0,0x4
ffffffffc02005f2:	43250513          	addi	a0,a0,1074 # ffffffffc0204a20 <commands+0x570>
ffffffffc02005f6:	ac9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005fa:	7c0c                	ld	a1,56(s0)
ffffffffc02005fc:	00004517          	auipc	a0,0x4
ffffffffc0200600:	43c50513          	addi	a0,a0,1084 # ffffffffc0204a38 <commands+0x588>
ffffffffc0200604:	abbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200608:	602c                	ld	a1,64(s0)
ffffffffc020060a:	00004517          	auipc	a0,0x4
ffffffffc020060e:	44650513          	addi	a0,a0,1094 # ffffffffc0204a50 <commands+0x5a0>
ffffffffc0200612:	aadff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200616:	642c                	ld	a1,72(s0)
ffffffffc0200618:	00004517          	auipc	a0,0x4
ffffffffc020061c:	45050513          	addi	a0,a0,1104 # ffffffffc0204a68 <commands+0x5b8>
ffffffffc0200620:	a9fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200624:	682c                	ld	a1,80(s0)
ffffffffc0200626:	00004517          	auipc	a0,0x4
ffffffffc020062a:	45a50513          	addi	a0,a0,1114 # ffffffffc0204a80 <commands+0x5d0>
ffffffffc020062e:	a91ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200632:	6c2c                	ld	a1,88(s0)
ffffffffc0200634:	00004517          	auipc	a0,0x4
ffffffffc0200638:	46450513          	addi	a0,a0,1124 # ffffffffc0204a98 <commands+0x5e8>
ffffffffc020063c:	a83ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200640:	702c                	ld	a1,96(s0)
ffffffffc0200642:	00004517          	auipc	a0,0x4
ffffffffc0200646:	46e50513          	addi	a0,a0,1134 # ffffffffc0204ab0 <commands+0x600>
ffffffffc020064a:	a75ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020064e:	742c                	ld	a1,104(s0)
ffffffffc0200650:	00004517          	auipc	a0,0x4
ffffffffc0200654:	47850513          	addi	a0,a0,1144 # ffffffffc0204ac8 <commands+0x618>
ffffffffc0200658:	a67ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020065c:	782c                	ld	a1,112(s0)
ffffffffc020065e:	00004517          	auipc	a0,0x4
ffffffffc0200662:	48250513          	addi	a0,a0,1154 # ffffffffc0204ae0 <commands+0x630>
ffffffffc0200666:	a59ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020066a:	7c2c                	ld	a1,120(s0)
ffffffffc020066c:	00004517          	auipc	a0,0x4
ffffffffc0200670:	48c50513          	addi	a0,a0,1164 # ffffffffc0204af8 <commands+0x648>
ffffffffc0200674:	a4bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200678:	604c                	ld	a1,128(s0)
ffffffffc020067a:	00004517          	auipc	a0,0x4
ffffffffc020067e:	49650513          	addi	a0,a0,1174 # ffffffffc0204b10 <commands+0x660>
ffffffffc0200682:	a3dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200686:	644c                	ld	a1,136(s0)
ffffffffc0200688:	00004517          	auipc	a0,0x4
ffffffffc020068c:	4a050513          	addi	a0,a0,1184 # ffffffffc0204b28 <commands+0x678>
ffffffffc0200690:	a2fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200694:	684c                	ld	a1,144(s0)
ffffffffc0200696:	00004517          	auipc	a0,0x4
ffffffffc020069a:	4aa50513          	addi	a0,a0,1194 # ffffffffc0204b40 <commands+0x690>
ffffffffc020069e:	a21ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02006a2:	6c4c                	ld	a1,152(s0)
ffffffffc02006a4:	00004517          	auipc	a0,0x4
ffffffffc02006a8:	4b450513          	addi	a0,a0,1204 # ffffffffc0204b58 <commands+0x6a8>
ffffffffc02006ac:	a13ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02006b0:	704c                	ld	a1,160(s0)
ffffffffc02006b2:	00004517          	auipc	a0,0x4
ffffffffc02006b6:	4be50513          	addi	a0,a0,1214 # ffffffffc0204b70 <commands+0x6c0>
ffffffffc02006ba:	a05ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02006be:	744c                	ld	a1,168(s0)
ffffffffc02006c0:	00004517          	auipc	a0,0x4
ffffffffc02006c4:	4c850513          	addi	a0,a0,1224 # ffffffffc0204b88 <commands+0x6d8>
ffffffffc02006c8:	9f7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02006cc:	784c                	ld	a1,176(s0)
ffffffffc02006ce:	00004517          	auipc	a0,0x4
ffffffffc02006d2:	4d250513          	addi	a0,a0,1234 # ffffffffc0204ba0 <commands+0x6f0>
ffffffffc02006d6:	9e9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02006da:	7c4c                	ld	a1,184(s0)
ffffffffc02006dc:	00004517          	auipc	a0,0x4
ffffffffc02006e0:	4dc50513          	addi	a0,a0,1244 # ffffffffc0204bb8 <commands+0x708>
ffffffffc02006e4:	9dbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006e8:	606c                	ld	a1,192(s0)
ffffffffc02006ea:	00004517          	auipc	a0,0x4
ffffffffc02006ee:	4e650513          	addi	a0,a0,1254 # ffffffffc0204bd0 <commands+0x720>
ffffffffc02006f2:	9cdff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006f6:	646c                	ld	a1,200(s0)
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	4f050513          	addi	a0,a0,1264 # ffffffffc0204be8 <commands+0x738>
ffffffffc0200700:	9bfff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200704:	686c                	ld	a1,208(s0)
ffffffffc0200706:	00004517          	auipc	a0,0x4
ffffffffc020070a:	4fa50513          	addi	a0,a0,1274 # ffffffffc0204c00 <commands+0x750>
ffffffffc020070e:	9b1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200712:	6c6c                	ld	a1,216(s0)
ffffffffc0200714:	00004517          	auipc	a0,0x4
ffffffffc0200718:	50450513          	addi	a0,a0,1284 # ffffffffc0204c18 <commands+0x768>
ffffffffc020071c:	9a3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200720:	706c                	ld	a1,224(s0)
ffffffffc0200722:	00004517          	auipc	a0,0x4
ffffffffc0200726:	50e50513          	addi	a0,a0,1294 # ffffffffc0204c30 <commands+0x780>
ffffffffc020072a:	995ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020072e:	746c                	ld	a1,232(s0)
ffffffffc0200730:	00004517          	auipc	a0,0x4
ffffffffc0200734:	51850513          	addi	a0,a0,1304 # ffffffffc0204c48 <commands+0x798>
ffffffffc0200738:	987ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020073c:	786c                	ld	a1,240(s0)
ffffffffc020073e:	00004517          	auipc	a0,0x4
ffffffffc0200742:	52250513          	addi	a0,a0,1314 # ffffffffc0204c60 <commands+0x7b0>
ffffffffc0200746:	979ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020074a:	7c6c                	ld	a1,248(s0)
}
ffffffffc020074c:	6402                	ld	s0,0(sp)
ffffffffc020074e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200750:	00004517          	auipc	a0,0x4
ffffffffc0200754:	52850513          	addi	a0,a0,1320 # ffffffffc0204c78 <commands+0x7c8>
}
ffffffffc0200758:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020075a:	965ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc020075e <print_trapframe>:
{
ffffffffc020075e:	1141                	addi	sp,sp,-16
ffffffffc0200760:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200762:	85aa                	mv	a1,a0
{
ffffffffc0200764:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200766:	00004517          	auipc	a0,0x4
ffffffffc020076a:	52a50513          	addi	a0,a0,1322 # ffffffffc0204c90 <commands+0x7e0>
{
ffffffffc020076e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200770:	94fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200774:	8522                	mv	a0,s0
ffffffffc0200776:	e1bff0ef          	jal	ra,ffffffffc0200590 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020077a:	10043583          	ld	a1,256(s0)
ffffffffc020077e:	00004517          	auipc	a0,0x4
ffffffffc0200782:	52a50513          	addi	a0,a0,1322 # ffffffffc0204ca8 <commands+0x7f8>
ffffffffc0200786:	939ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020078a:	10843583          	ld	a1,264(s0)
ffffffffc020078e:	00004517          	auipc	a0,0x4
ffffffffc0200792:	53250513          	addi	a0,a0,1330 # ffffffffc0204cc0 <commands+0x810>
ffffffffc0200796:	929ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020079a:	11043583          	ld	a1,272(s0)
ffffffffc020079e:	00004517          	auipc	a0,0x4
ffffffffc02007a2:	53a50513          	addi	a0,a0,1338 # ffffffffc0204cd8 <commands+0x828>
ffffffffc02007a6:	919ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007aa:	11843583          	ld	a1,280(s0)
}
ffffffffc02007ae:	6402                	ld	s0,0(sp)
ffffffffc02007b0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007b2:	00004517          	auipc	a0,0x4
ffffffffc02007b6:	53e50513          	addi	a0,a0,1342 # ffffffffc0204cf0 <commands+0x840>
}
ffffffffc02007ba:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007bc:	903ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc02007c0 <interrupt_handler>:
static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02007c0:	11853783          	ld	a5,280(a0)
ffffffffc02007c4:	577d                	li	a4,-1
ffffffffc02007c6:	8305                	srli	a4,a4,0x1
ffffffffc02007c8:	8ff9                	and	a5,a5,a4
    switch (cause)
ffffffffc02007ca:	472d                	li	a4,11
ffffffffc02007cc:	06f76f63          	bltu	a4,a5,ffffffffc020084a <interrupt_handler+0x8a>
ffffffffc02007d0:	00004717          	auipc	a4,0x4
ffffffffc02007d4:	e9470713          	addi	a4,a4,-364 # ffffffffc0204664 <commands+0x1b4>
ffffffffc02007d8:	078a                	slli	a5,a5,0x2
ffffffffc02007da:	97ba                	add	a5,a5,a4
ffffffffc02007dc:	439c                	lw	a5,0(a5)
ffffffffc02007de:	97ba                	add	a5,a5,a4
ffffffffc02007e0:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc02007e2:	00004517          	auipc	a0,0x4
ffffffffc02007e6:	10e50513          	addi	a0,a0,270 # ffffffffc02048f0 <commands+0x440>
ffffffffc02007ea:	8d5ff06f          	j	ffffffffc02000be <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc02007ee:	00004517          	auipc	a0,0x4
ffffffffc02007f2:	0e250513          	addi	a0,a0,226 # ffffffffc02048d0 <commands+0x420>
ffffffffc02007f6:	8c9ff06f          	j	ffffffffc02000be <cprintf>
        cprintf("User software interrupt\n");
ffffffffc02007fa:	00004517          	auipc	a0,0x4
ffffffffc02007fe:	09650513          	addi	a0,a0,150 # ffffffffc0204890 <commands+0x3e0>
ffffffffc0200802:	8bdff06f          	j	ffffffffc02000be <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200806:	00004517          	auipc	a0,0x4
ffffffffc020080a:	0aa50513          	addi	a0,a0,170 # ffffffffc02048b0 <commands+0x400>
ffffffffc020080e:	8b1ff06f          	j	ffffffffc02000be <cprintf>
        break;
    case IRQ_U_EXT:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_EXT:
        cprintf("Supervisor external interrupt\n");
ffffffffc0200812:	00004517          	auipc	a0,0x4
ffffffffc0200816:	10e50513          	addi	a0,a0,270 # ffffffffc0204920 <commands+0x470>
ffffffffc020081a:	8a5ff06f          	j	ffffffffc02000be <cprintf>
{
ffffffffc020081e:	1141                	addi	sp,sp,-16
ffffffffc0200820:	e406                	sd	ra,8(sp)
        clock_set_next_event();
ffffffffc0200822:	bedff0ef          	jal	ra,ffffffffc020040e <clock_set_next_event>
        ticks++;
ffffffffc0200826:	00011717          	auipc	a4,0x11
ffffffffc020082a:	c5270713          	addi	a4,a4,-942 # ffffffffc0211478 <ticks>
ffffffffc020082e:	631c                	ld	a5,0(a4)
        if (ticks == 100)
ffffffffc0200830:	06400693          	li	a3,100
        ticks++;
ffffffffc0200834:	0785                	addi	a5,a5,1
ffffffffc0200836:	00011617          	auipc	a2,0x11
ffffffffc020083a:	c4f63123          	sd	a5,-958(a2) # ffffffffc0211478 <ticks>
        if (ticks == 100)
ffffffffc020083e:	631c                	ld	a5,0(a4)
ffffffffc0200840:	00d78763          	beq	a5,a3,ffffffffc020084e <interrupt_handler+0x8e>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200844:	60a2                	ld	ra,8(sp)
ffffffffc0200846:	0141                	addi	sp,sp,16
ffffffffc0200848:	8082                	ret
        print_trapframe(tf);
ffffffffc020084a:	f15ff06f          	j	ffffffffc020075e <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020084e:	06400593          	li	a1,100
ffffffffc0200852:	00004517          	auipc	a0,0x4
ffffffffc0200856:	0be50513          	addi	a0,a0,190 # ffffffffc0204910 <commands+0x460>
            ticks = 0;
ffffffffc020085a:	00011797          	auipc	a5,0x11
ffffffffc020085e:	c007bf23          	sd	zero,-994(a5) # ffffffffc0211478 <ticks>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200862:	85dff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if (num == 10)
ffffffffc0200866:	00011797          	auipc	a5,0x11
ffffffffc020086a:	bea78793          	addi	a5,a5,-1046 # ffffffffc0211450 <num>
ffffffffc020086e:	6394                	ld	a3,0(a5)
ffffffffc0200870:	4729                	li	a4,10
ffffffffc0200872:	00e69863          	bne	a3,a4,ffffffffc0200882 <interrupt_handler+0xc2>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200876:	4501                	li	a0,0
ffffffffc0200878:	4581                	li	a1,0
ffffffffc020087a:	4601                	li	a2,0
ffffffffc020087c:	48a1                	li	a7,8
ffffffffc020087e:	00000073          	ecall
            num++;
ffffffffc0200882:	639c                	ld	a5,0(a5)
ffffffffc0200884:	0785                	addi	a5,a5,1
ffffffffc0200886:	00011717          	auipc	a4,0x11
ffffffffc020088a:	bcf73523          	sd	a5,-1078(a4) # ffffffffc0211450 <num>
ffffffffc020088e:	bf5d                	j	ffffffffc0200844 <interrupt_handler+0x84>

ffffffffc0200890 <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200890:	11853783          	ld	a5,280(a0)
ffffffffc0200894:	473d                	li	a4,15
ffffffffc0200896:	16f76563          	bltu	a4,a5,ffffffffc0200a00 <exception_handler+0x170>
ffffffffc020089a:	00004717          	auipc	a4,0x4
ffffffffc020089e:	dfa70713          	addi	a4,a4,-518 # ffffffffc0204694 <commands+0x1e4>
ffffffffc02008a2:	078a                	slli	a5,a5,0x2
ffffffffc02008a4:	97ba                	add	a5,a5,a4
ffffffffc02008a6:	439c                	lw	a5,0(a5)
{
ffffffffc02008a8:	1101                	addi	sp,sp,-32
ffffffffc02008aa:	e822                	sd	s0,16(sp)
ffffffffc02008ac:	ec06                	sd	ra,24(sp)
ffffffffc02008ae:	e426                	sd	s1,8(sp)
    switch (tf->cause)
ffffffffc02008b0:	97ba                	add	a5,a5,a4
ffffffffc02008b2:	842a                	mv	s0,a0
ffffffffc02008b4:	8782                	jr	a5
            print_trapframe(tf);
            panic("handle pgfault failed. %e\n", ret);
        }
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc02008b6:	00004517          	auipc	a0,0x4
ffffffffc02008ba:	fc250513          	addi	a0,a0,-62 # ffffffffc0204878 <commands+0x3c8>
ffffffffc02008be:	801ff0ef          	jal	ra,ffffffffc02000be <cprintf>
        if ((ret = pgfault_handler(tf)) != 0)
ffffffffc02008c2:	8522                	mv	a0,s0
ffffffffc02008c4:	c3dff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc02008c8:	84aa                	mv	s1,a0
ffffffffc02008ca:	12051d63          	bnez	a0,ffffffffc0200a04 <exception_handler+0x174>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc02008ce:	60e2                	ld	ra,24(sp)
ffffffffc02008d0:	6442                	ld	s0,16(sp)
ffffffffc02008d2:	64a2                	ld	s1,8(sp)
ffffffffc02008d4:	6105                	addi	sp,sp,32
ffffffffc02008d6:	8082                	ret
        cprintf("Instruction address misaligned\n");
ffffffffc02008d8:	00004517          	auipc	a0,0x4
ffffffffc02008dc:	e0050513          	addi	a0,a0,-512 # ffffffffc02046d8 <commands+0x228>
}
ffffffffc02008e0:	6442                	ld	s0,16(sp)
ffffffffc02008e2:	60e2                	ld	ra,24(sp)
ffffffffc02008e4:	64a2                	ld	s1,8(sp)
ffffffffc02008e6:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc02008e8:	fd6ff06f          	j	ffffffffc02000be <cprintf>
ffffffffc02008ec:	00004517          	auipc	a0,0x4
ffffffffc02008f0:	e0c50513          	addi	a0,a0,-500 # ffffffffc02046f8 <commands+0x248>
ffffffffc02008f4:	b7f5                	j	ffffffffc02008e0 <exception_handler+0x50>
        cprintf("Illegal instruction\n");
ffffffffc02008f6:	00004517          	auipc	a0,0x4
ffffffffc02008fa:	e2250513          	addi	a0,a0,-478 # ffffffffc0204718 <commands+0x268>
ffffffffc02008fe:	b7cd                	j	ffffffffc02008e0 <exception_handler+0x50>
        cprintf("Breakpoint\n");
ffffffffc0200900:	00004517          	auipc	a0,0x4
ffffffffc0200904:	e3050513          	addi	a0,a0,-464 # ffffffffc0204730 <commands+0x280>
ffffffffc0200908:	bfe1                	j	ffffffffc02008e0 <exception_handler+0x50>
        cprintf("Load address misaligned\n");
ffffffffc020090a:	00004517          	auipc	a0,0x4
ffffffffc020090e:	e3650513          	addi	a0,a0,-458 # ffffffffc0204740 <commands+0x290>
ffffffffc0200912:	b7f9                	j	ffffffffc02008e0 <exception_handler+0x50>
        cprintf("Load access fault\n");
ffffffffc0200914:	00004517          	auipc	a0,0x4
ffffffffc0200918:	e4c50513          	addi	a0,a0,-436 # ffffffffc0204760 <commands+0x2b0>
ffffffffc020091c:	fa2ff0ef          	jal	ra,ffffffffc02000be <cprintf>
        if ((ret = pgfault_handler(tf)) != 0)
ffffffffc0200920:	8522                	mv	a0,s0
ffffffffc0200922:	bdfff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc0200926:	84aa                	mv	s1,a0
ffffffffc0200928:	d15d                	beqz	a0,ffffffffc02008ce <exception_handler+0x3e>
            print_trapframe(tf);
ffffffffc020092a:	8522                	mv	a0,s0
ffffffffc020092c:	e33ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc0200930:	86a6                	mv	a3,s1
ffffffffc0200932:	00004617          	auipc	a2,0x4
ffffffffc0200936:	e4660613          	addi	a2,a2,-442 # ffffffffc0204778 <commands+0x2c8>
ffffffffc020093a:	0e500593          	li	a1,229
ffffffffc020093e:	00004517          	auipc	a0,0x4
ffffffffc0200942:	03a50513          	addi	a0,a0,58 # ffffffffc0204978 <commands+0x4c8>
ffffffffc0200946:	a2fff0ef          	jal	ra,ffffffffc0200374 <__panic>
        cprintf("AMO address misaligned\n");
ffffffffc020094a:	00004517          	auipc	a0,0x4
ffffffffc020094e:	e4e50513          	addi	a0,a0,-434 # ffffffffc0204798 <commands+0x2e8>
ffffffffc0200952:	b779                	j	ffffffffc02008e0 <exception_handler+0x50>
        cprintf("Store/AMO access fault\n");
ffffffffc0200954:	00004517          	auipc	a0,0x4
ffffffffc0200958:	e5c50513          	addi	a0,a0,-420 # ffffffffc02047b0 <commands+0x300>
ffffffffc020095c:	f62ff0ef          	jal	ra,ffffffffc02000be <cprintf>
        if ((ret = pgfault_handler(tf)) != 0)
ffffffffc0200960:	8522                	mv	a0,s0
ffffffffc0200962:	b9fff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc0200966:	84aa                	mv	s1,a0
ffffffffc0200968:	d13d                	beqz	a0,ffffffffc02008ce <exception_handler+0x3e>
            print_trapframe(tf);
ffffffffc020096a:	8522                	mv	a0,s0
ffffffffc020096c:	df3ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc0200970:	86a6                	mv	a3,s1
ffffffffc0200972:	00004617          	auipc	a2,0x4
ffffffffc0200976:	e0660613          	addi	a2,a2,-506 # ffffffffc0204778 <commands+0x2c8>
ffffffffc020097a:	0f000593          	li	a1,240
ffffffffc020097e:	00004517          	auipc	a0,0x4
ffffffffc0200982:	ffa50513          	addi	a0,a0,-6 # ffffffffc0204978 <commands+0x4c8>
ffffffffc0200986:	9efff0ef          	jal	ra,ffffffffc0200374 <__panic>
        cprintf("Environment call from U-mode\n");
ffffffffc020098a:	00004517          	auipc	a0,0x4
ffffffffc020098e:	e3e50513          	addi	a0,a0,-450 # ffffffffc02047c8 <commands+0x318>
ffffffffc0200992:	b7b9                	j	ffffffffc02008e0 <exception_handler+0x50>
        cprintf("Environment call from S-mode\n");
ffffffffc0200994:	00004517          	auipc	a0,0x4
ffffffffc0200998:	e5450513          	addi	a0,a0,-428 # ffffffffc02047e8 <commands+0x338>
ffffffffc020099c:	b791                	j	ffffffffc02008e0 <exception_handler+0x50>
        cprintf("Environment call from H-mode\n");
ffffffffc020099e:	00004517          	auipc	a0,0x4
ffffffffc02009a2:	e6a50513          	addi	a0,a0,-406 # ffffffffc0204808 <commands+0x358>
ffffffffc02009a6:	bf2d                	j	ffffffffc02008e0 <exception_handler+0x50>
        cprintf("Environment call from M-mode\n");
ffffffffc02009a8:	00004517          	auipc	a0,0x4
ffffffffc02009ac:	e8050513          	addi	a0,a0,-384 # ffffffffc0204828 <commands+0x378>
ffffffffc02009b0:	bf05                	j	ffffffffc02008e0 <exception_handler+0x50>
        cprintf("Instruction page fault\n");
ffffffffc02009b2:	00004517          	auipc	a0,0x4
ffffffffc02009b6:	e9650513          	addi	a0,a0,-362 # ffffffffc0204848 <commands+0x398>
ffffffffc02009ba:	b71d                	j	ffffffffc02008e0 <exception_handler+0x50>
        cprintf("Load page fault\n");
ffffffffc02009bc:	00004517          	auipc	a0,0x4
ffffffffc02009c0:	ea450513          	addi	a0,a0,-348 # ffffffffc0204860 <commands+0x3b0>
ffffffffc02009c4:	efaff0ef          	jal	ra,ffffffffc02000be <cprintf>
        if ((ret = pgfault_handler(tf)) != 0)
ffffffffc02009c8:	8522                	mv	a0,s0
ffffffffc02009ca:	b37ff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc02009ce:	84aa                	mv	s1,a0
ffffffffc02009d0:	ee050fe3          	beqz	a0,ffffffffc02008ce <exception_handler+0x3e>
            print_trapframe(tf);
ffffffffc02009d4:	8522                	mv	a0,s0
ffffffffc02009d6:	d89ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc02009da:	86a6                	mv	a3,s1
ffffffffc02009dc:	00004617          	auipc	a2,0x4
ffffffffc02009e0:	d9c60613          	addi	a2,a2,-612 # ffffffffc0204778 <commands+0x2c8>
ffffffffc02009e4:	10700593          	li	a1,263
ffffffffc02009e8:	00004517          	auipc	a0,0x4
ffffffffc02009ec:	f9050513          	addi	a0,a0,-112 # ffffffffc0204978 <commands+0x4c8>
ffffffffc02009f0:	985ff0ef          	jal	ra,ffffffffc0200374 <__panic>
}
ffffffffc02009f4:	6442                	ld	s0,16(sp)
ffffffffc02009f6:	60e2                	ld	ra,24(sp)
ffffffffc02009f8:	64a2                	ld	s1,8(sp)
ffffffffc02009fa:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc02009fc:	d63ff06f          	j	ffffffffc020075e <print_trapframe>
ffffffffc0200a00:	d5fff06f          	j	ffffffffc020075e <print_trapframe>
            print_trapframe(tf);
ffffffffc0200a04:	8522                	mv	a0,s0
ffffffffc0200a06:	d59ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a0a:	86a6                	mv	a3,s1
ffffffffc0200a0c:	00004617          	auipc	a2,0x4
ffffffffc0200a10:	d6c60613          	addi	a2,a2,-660 # ffffffffc0204778 <commands+0x2c8>
ffffffffc0200a14:	10f00593          	li	a1,271
ffffffffc0200a18:	00004517          	auipc	a0,0x4
ffffffffc0200a1c:	f6050513          	addi	a0,a0,-160 # ffffffffc0204978 <commands+0x4c8>
ffffffffc0200a20:	955ff0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0200a24 <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200a24:	11853783          	ld	a5,280(a0)
ffffffffc0200a28:	0007c463          	bltz	a5,ffffffffc0200a30 <trap+0xc>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200a2c:	e65ff06f          	j	ffffffffc0200890 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200a30:	d91ff06f          	j	ffffffffc02007c0 <interrupt_handler>
	...

ffffffffc0200a40 <__alltraps>:
    .endm

    .align 4
    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200a40:	14011073          	csrw	sscratch,sp
ffffffffc0200a44:	712d                	addi	sp,sp,-288
ffffffffc0200a46:	e406                	sd	ra,8(sp)
ffffffffc0200a48:	ec0e                	sd	gp,24(sp)
ffffffffc0200a4a:	f012                	sd	tp,32(sp)
ffffffffc0200a4c:	f416                	sd	t0,40(sp)
ffffffffc0200a4e:	f81a                	sd	t1,48(sp)
ffffffffc0200a50:	fc1e                	sd	t2,56(sp)
ffffffffc0200a52:	e0a2                	sd	s0,64(sp)
ffffffffc0200a54:	e4a6                	sd	s1,72(sp)
ffffffffc0200a56:	e8aa                	sd	a0,80(sp)
ffffffffc0200a58:	ecae                	sd	a1,88(sp)
ffffffffc0200a5a:	f0b2                	sd	a2,96(sp)
ffffffffc0200a5c:	f4b6                	sd	a3,104(sp)
ffffffffc0200a5e:	f8ba                	sd	a4,112(sp)
ffffffffc0200a60:	fcbe                	sd	a5,120(sp)
ffffffffc0200a62:	e142                	sd	a6,128(sp)
ffffffffc0200a64:	e546                	sd	a7,136(sp)
ffffffffc0200a66:	e94a                	sd	s2,144(sp)
ffffffffc0200a68:	ed4e                	sd	s3,152(sp)
ffffffffc0200a6a:	f152                	sd	s4,160(sp)
ffffffffc0200a6c:	f556                	sd	s5,168(sp)
ffffffffc0200a6e:	f95a                	sd	s6,176(sp)
ffffffffc0200a70:	fd5e                	sd	s7,184(sp)
ffffffffc0200a72:	e1e2                	sd	s8,192(sp)
ffffffffc0200a74:	e5e6                	sd	s9,200(sp)
ffffffffc0200a76:	e9ea                	sd	s10,208(sp)
ffffffffc0200a78:	edee                	sd	s11,216(sp)
ffffffffc0200a7a:	f1f2                	sd	t3,224(sp)
ffffffffc0200a7c:	f5f6                	sd	t4,232(sp)
ffffffffc0200a7e:	f9fa                	sd	t5,240(sp)
ffffffffc0200a80:	fdfe                	sd	t6,248(sp)
ffffffffc0200a82:	14002473          	csrr	s0,sscratch
ffffffffc0200a86:	100024f3          	csrr	s1,sstatus
ffffffffc0200a8a:	14102973          	csrr	s2,sepc
ffffffffc0200a8e:	143029f3          	csrr	s3,stval
ffffffffc0200a92:	14202a73          	csrr	s4,scause
ffffffffc0200a96:	e822                	sd	s0,16(sp)
ffffffffc0200a98:	e226                	sd	s1,256(sp)
ffffffffc0200a9a:	e64a                	sd	s2,264(sp)
ffffffffc0200a9c:	ea4e                	sd	s3,272(sp)
ffffffffc0200a9e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200aa0:	850a                	mv	a0,sp
    jal trap
ffffffffc0200aa2:	f83ff0ef          	jal	ra,ffffffffc0200a24 <trap>

ffffffffc0200aa6 <__trapret>:
    // sp should be the same as before "jal trap"
    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200aa6:	6492                	ld	s1,256(sp)
ffffffffc0200aa8:	6932                	ld	s2,264(sp)
ffffffffc0200aaa:	10049073          	csrw	sstatus,s1
ffffffffc0200aae:	14191073          	csrw	sepc,s2
ffffffffc0200ab2:	60a2                	ld	ra,8(sp)
ffffffffc0200ab4:	61e2                	ld	gp,24(sp)
ffffffffc0200ab6:	7202                	ld	tp,32(sp)
ffffffffc0200ab8:	72a2                	ld	t0,40(sp)
ffffffffc0200aba:	7342                	ld	t1,48(sp)
ffffffffc0200abc:	73e2                	ld	t2,56(sp)
ffffffffc0200abe:	6406                	ld	s0,64(sp)
ffffffffc0200ac0:	64a6                	ld	s1,72(sp)
ffffffffc0200ac2:	6546                	ld	a0,80(sp)
ffffffffc0200ac4:	65e6                	ld	a1,88(sp)
ffffffffc0200ac6:	7606                	ld	a2,96(sp)
ffffffffc0200ac8:	76a6                	ld	a3,104(sp)
ffffffffc0200aca:	7746                	ld	a4,112(sp)
ffffffffc0200acc:	77e6                	ld	a5,120(sp)
ffffffffc0200ace:	680a                	ld	a6,128(sp)
ffffffffc0200ad0:	68aa                	ld	a7,136(sp)
ffffffffc0200ad2:	694a                	ld	s2,144(sp)
ffffffffc0200ad4:	69ea                	ld	s3,152(sp)
ffffffffc0200ad6:	7a0a                	ld	s4,160(sp)
ffffffffc0200ad8:	7aaa                	ld	s5,168(sp)
ffffffffc0200ada:	7b4a                	ld	s6,176(sp)
ffffffffc0200adc:	7bea                	ld	s7,184(sp)
ffffffffc0200ade:	6c0e                	ld	s8,192(sp)
ffffffffc0200ae0:	6cae                	ld	s9,200(sp)
ffffffffc0200ae2:	6d4e                	ld	s10,208(sp)
ffffffffc0200ae4:	6dee                	ld	s11,216(sp)
ffffffffc0200ae6:	7e0e                	ld	t3,224(sp)
ffffffffc0200ae8:	7eae                	ld	t4,232(sp)
ffffffffc0200aea:	7f4e                	ld	t5,240(sp)
ffffffffc0200aec:	7fee                	ld	t6,248(sp)
ffffffffc0200aee:	6142                	ld	sp,16(sp)
    // go back from supervisor call
    sret
ffffffffc0200af0:	10200073          	sret
	...

ffffffffc0200b00 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200b00:	00011797          	auipc	a5,0x11
ffffffffc0200b04:	98078793          	addi	a5,a5,-1664 # ffffffffc0211480 <free_area>
ffffffffc0200b08:	e79c                	sd	a5,8(a5)
ffffffffc0200b0a:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200b0c:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200b10:	8082                	ret

ffffffffc0200b12 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200b12:	00011517          	auipc	a0,0x11
ffffffffc0200b16:	97e56503          	lwu	a0,-1666(a0) # ffffffffc0211490 <free_area+0x10>
ffffffffc0200b1a:	8082                	ret

ffffffffc0200b1c <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200b1c:	715d                	addi	sp,sp,-80
ffffffffc0200b1e:	f84a                	sd	s2,48(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200b20:	00011917          	auipc	s2,0x11
ffffffffc0200b24:	96090913          	addi	s2,s2,-1696 # ffffffffc0211480 <free_area>
ffffffffc0200b28:	00893783          	ld	a5,8(s2)
ffffffffc0200b2c:	e486                	sd	ra,72(sp)
ffffffffc0200b2e:	e0a2                	sd	s0,64(sp)
ffffffffc0200b30:	fc26                	sd	s1,56(sp)
ffffffffc0200b32:	f44e                	sd	s3,40(sp)
ffffffffc0200b34:	f052                	sd	s4,32(sp)
ffffffffc0200b36:	ec56                	sd	s5,24(sp)
ffffffffc0200b38:	e85a                	sd	s6,16(sp)
ffffffffc0200b3a:	e45e                	sd	s7,8(sp)
ffffffffc0200b3c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b3e:	31278f63          	beq	a5,s2,ffffffffc0200e5c <default_check+0x340>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200b42:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200b46:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200b48:	8b05                	andi	a4,a4,1
ffffffffc0200b4a:	30070d63          	beqz	a4,ffffffffc0200e64 <default_check+0x348>
    int count = 0, total = 0;
ffffffffc0200b4e:	4401                	li	s0,0
ffffffffc0200b50:	4481                	li	s1,0
ffffffffc0200b52:	a031                	j	ffffffffc0200b5e <default_check+0x42>
ffffffffc0200b54:	fe87b703          	ld	a4,-24(a5)
        assert(PageProperty(p));
ffffffffc0200b58:	8b09                	andi	a4,a4,2
ffffffffc0200b5a:	30070563          	beqz	a4,ffffffffc0200e64 <default_check+0x348>
        count ++, total += p->property;
ffffffffc0200b5e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200b62:	679c                	ld	a5,8(a5)
ffffffffc0200b64:	2485                	addiw	s1,s1,1
ffffffffc0200b66:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b68:	ff2796e3          	bne	a5,s2,ffffffffc0200b54 <default_check+0x38>
ffffffffc0200b6c:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200b6e:	411000ef          	jal	ra,ffffffffc020177e <nr_free_pages>
ffffffffc0200b72:	75351963          	bne	a0,s3,ffffffffc02012c4 <default_check+0x7a8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200b76:	4505                	li	a0,1
ffffffffc0200b78:	317000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200b7c:	8a2a                	mv	s4,a0
ffffffffc0200b7e:	48050363          	beqz	a0,ffffffffc0201004 <default_check+0x4e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200b82:	4505                	li	a0,1
ffffffffc0200b84:	30b000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200b88:	89aa                	mv	s3,a0
ffffffffc0200b8a:	74050d63          	beqz	a0,ffffffffc02012e4 <default_check+0x7c8>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200b8e:	4505                	li	a0,1
ffffffffc0200b90:	2ff000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200b94:	8aaa                	mv	s5,a0
ffffffffc0200b96:	4e050763          	beqz	a0,ffffffffc0201084 <default_check+0x568>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200b9a:	2f3a0563          	beq	s4,s3,ffffffffc0200e84 <default_check+0x368>
ffffffffc0200b9e:	2eaa0363          	beq	s4,a0,ffffffffc0200e84 <default_check+0x368>
ffffffffc0200ba2:	2ea98163          	beq	s3,a0,ffffffffc0200e84 <default_check+0x368>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ba6:	000a2783          	lw	a5,0(s4)
ffffffffc0200baa:	2e079d63          	bnez	a5,ffffffffc0200ea4 <default_check+0x388>
ffffffffc0200bae:	0009a783          	lw	a5,0(s3)
ffffffffc0200bb2:	2e079963          	bnez	a5,ffffffffc0200ea4 <default_check+0x388>
ffffffffc0200bb6:	411c                	lw	a5,0(a0)
ffffffffc0200bb8:	2e079663          	bnez	a5,ffffffffc0200ea4 <default_check+0x388>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200bbc:	00011797          	auipc	a5,0x11
ffffffffc0200bc0:	8f478793          	addi	a5,a5,-1804 # ffffffffc02114b0 <pages>
ffffffffc0200bc4:	639c                	ld	a5,0(a5)
ffffffffc0200bc6:	00004717          	auipc	a4,0x4
ffffffffc0200bca:	14270713          	addi	a4,a4,322 # ffffffffc0204d08 <commands+0x858>
ffffffffc0200bce:	630c                	ld	a1,0(a4)
ffffffffc0200bd0:	40fa0733          	sub	a4,s4,a5
ffffffffc0200bd4:	870d                	srai	a4,a4,0x3
ffffffffc0200bd6:	02b70733          	mul	a4,a4,a1
ffffffffc0200bda:	00005697          	auipc	a3,0x5
ffffffffc0200bde:	66e68693          	addi	a3,a3,1646 # ffffffffc0206248 <nbase>
ffffffffc0200be2:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200be4:	00011697          	auipc	a3,0x11
ffffffffc0200be8:	87c68693          	addi	a3,a3,-1924 # ffffffffc0211460 <npage>
ffffffffc0200bec:	6294                	ld	a3,0(a3)
ffffffffc0200bee:	06b2                	slli	a3,a3,0xc
ffffffffc0200bf0:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bf2:	0732                	slli	a4,a4,0xc
ffffffffc0200bf4:	2cd77863          	bleu	a3,a4,ffffffffc0200ec4 <default_check+0x3a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200bf8:	40f98733          	sub	a4,s3,a5
ffffffffc0200bfc:	870d                	srai	a4,a4,0x3
ffffffffc0200bfe:	02b70733          	mul	a4,a4,a1
ffffffffc0200c02:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c04:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200c06:	4ed77f63          	bleu	a3,a4,ffffffffc0201104 <default_check+0x5e8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c0a:	40f507b3          	sub	a5,a0,a5
ffffffffc0200c0e:	878d                	srai	a5,a5,0x3
ffffffffc0200c10:	02b787b3          	mul	a5,a5,a1
ffffffffc0200c14:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c16:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200c18:	34d7f663          	bleu	a3,a5,ffffffffc0200f64 <default_check+0x448>
    assert(alloc_page() == NULL);
ffffffffc0200c1c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200c1e:	00093c03          	ld	s8,0(s2)
ffffffffc0200c22:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200c26:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200c2a:	00011797          	auipc	a5,0x11
ffffffffc0200c2e:	8527bf23          	sd	s2,-1954(a5) # ffffffffc0211488 <free_area+0x8>
ffffffffc0200c32:	00011797          	auipc	a5,0x11
ffffffffc0200c36:	8527b723          	sd	s2,-1970(a5) # ffffffffc0211480 <free_area>
    nr_free = 0;
ffffffffc0200c3a:	00011797          	auipc	a5,0x11
ffffffffc0200c3e:	8407ab23          	sw	zero,-1962(a5) # ffffffffc0211490 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200c42:	24d000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200c46:	2e051f63          	bnez	a0,ffffffffc0200f44 <default_check+0x428>
    free_page(p0);
ffffffffc0200c4a:	4585                	li	a1,1
ffffffffc0200c4c:	8552                	mv	a0,s4
ffffffffc0200c4e:	2eb000ef          	jal	ra,ffffffffc0201738 <free_pages>
    free_page(p1);
ffffffffc0200c52:	4585                	li	a1,1
ffffffffc0200c54:	854e                	mv	a0,s3
ffffffffc0200c56:	2e3000ef          	jal	ra,ffffffffc0201738 <free_pages>
    free_page(p2);
ffffffffc0200c5a:	4585                	li	a1,1
ffffffffc0200c5c:	8556                	mv	a0,s5
ffffffffc0200c5e:	2db000ef          	jal	ra,ffffffffc0201738 <free_pages>
    assert(nr_free == 3);
ffffffffc0200c62:	01092703          	lw	a4,16(s2)
ffffffffc0200c66:	478d                	li	a5,3
ffffffffc0200c68:	2af71e63          	bne	a4,a5,ffffffffc0200f24 <default_check+0x408>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c6c:	4505                	li	a0,1
ffffffffc0200c6e:	221000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200c72:	89aa                	mv	s3,a0
ffffffffc0200c74:	28050863          	beqz	a0,ffffffffc0200f04 <default_check+0x3e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c78:	4505                	li	a0,1
ffffffffc0200c7a:	215000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200c7e:	8aaa                	mv	s5,a0
ffffffffc0200c80:	3e050263          	beqz	a0,ffffffffc0201064 <default_check+0x548>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c84:	4505                	li	a0,1
ffffffffc0200c86:	209000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200c8a:	8a2a                	mv	s4,a0
ffffffffc0200c8c:	3a050c63          	beqz	a0,ffffffffc0201044 <default_check+0x528>
    assert(alloc_page() == NULL);
ffffffffc0200c90:	4505                	li	a0,1
ffffffffc0200c92:	1fd000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200c96:	38051763          	bnez	a0,ffffffffc0201024 <default_check+0x508>
    free_page(p0);
ffffffffc0200c9a:	4585                	li	a1,1
ffffffffc0200c9c:	854e                	mv	a0,s3
ffffffffc0200c9e:	29b000ef          	jal	ra,ffffffffc0201738 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200ca2:	00893783          	ld	a5,8(s2)
ffffffffc0200ca6:	23278f63          	beq	a5,s2,ffffffffc0200ee4 <default_check+0x3c8>
    assert((p = alloc_page()) == p0);
ffffffffc0200caa:	4505                	li	a0,1
ffffffffc0200cac:	1e3000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200cb0:	32a99a63          	bne	s3,a0,ffffffffc0200fe4 <default_check+0x4c8>
    assert(alloc_page() == NULL);
ffffffffc0200cb4:	4505                	li	a0,1
ffffffffc0200cb6:	1d9000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200cba:	30051563          	bnez	a0,ffffffffc0200fc4 <default_check+0x4a8>
    assert(nr_free == 0);
ffffffffc0200cbe:	01092783          	lw	a5,16(s2)
ffffffffc0200cc2:	2e079163          	bnez	a5,ffffffffc0200fa4 <default_check+0x488>
    free_page(p);
ffffffffc0200cc6:	854e                	mv	a0,s3
ffffffffc0200cc8:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200cca:	00010797          	auipc	a5,0x10
ffffffffc0200cce:	7b87bb23          	sd	s8,1974(a5) # ffffffffc0211480 <free_area>
ffffffffc0200cd2:	00010797          	auipc	a5,0x10
ffffffffc0200cd6:	7b77bb23          	sd	s7,1974(a5) # ffffffffc0211488 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0200cda:	00010797          	auipc	a5,0x10
ffffffffc0200cde:	7b67ab23          	sw	s6,1974(a5) # ffffffffc0211490 <free_area+0x10>
    free_page(p);
ffffffffc0200ce2:	257000ef          	jal	ra,ffffffffc0201738 <free_pages>
    free_page(p1);
ffffffffc0200ce6:	4585                	li	a1,1
ffffffffc0200ce8:	8556                	mv	a0,s5
ffffffffc0200cea:	24f000ef          	jal	ra,ffffffffc0201738 <free_pages>
    free_page(p2);
ffffffffc0200cee:	4585                	li	a1,1
ffffffffc0200cf0:	8552                	mv	a0,s4
ffffffffc0200cf2:	247000ef          	jal	ra,ffffffffc0201738 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200cf6:	4515                	li	a0,5
ffffffffc0200cf8:	197000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200cfc:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200cfe:	28050363          	beqz	a0,ffffffffc0200f84 <default_check+0x468>
ffffffffc0200d02:	651c                	ld	a5,8(a0)
ffffffffc0200d04:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200d06:	8b85                	andi	a5,a5,1
ffffffffc0200d08:	54079e63          	bnez	a5,ffffffffc0201264 <default_check+0x748>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200d0c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d0e:	00093b03          	ld	s6,0(s2)
ffffffffc0200d12:	00893a83          	ld	s5,8(s2)
ffffffffc0200d16:	00010797          	auipc	a5,0x10
ffffffffc0200d1a:	7727b523          	sd	s2,1898(a5) # ffffffffc0211480 <free_area>
ffffffffc0200d1e:	00010797          	auipc	a5,0x10
ffffffffc0200d22:	7727b523          	sd	s2,1898(a5) # ffffffffc0211488 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200d26:	169000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200d2a:	50051d63          	bnez	a0,ffffffffc0201244 <default_check+0x728>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200d2e:	09098a13          	addi	s4,s3,144
ffffffffc0200d32:	8552                	mv	a0,s4
ffffffffc0200d34:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200d36:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc0200d3a:	00010797          	auipc	a5,0x10
ffffffffc0200d3e:	7407ab23          	sw	zero,1878(a5) # ffffffffc0211490 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200d42:	1f7000ef          	jal	ra,ffffffffc0201738 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200d46:	4511                	li	a0,4
ffffffffc0200d48:	147000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200d4c:	4c051c63          	bnez	a0,ffffffffc0201224 <default_check+0x708>
ffffffffc0200d50:	0989b783          	ld	a5,152(s3)
ffffffffc0200d54:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200d56:	8b85                	andi	a5,a5,1
ffffffffc0200d58:	4a078663          	beqz	a5,ffffffffc0201204 <default_check+0x6e8>
ffffffffc0200d5c:	0a89a703          	lw	a4,168(s3)
ffffffffc0200d60:	478d                	li	a5,3
ffffffffc0200d62:	4af71163          	bne	a4,a5,ffffffffc0201204 <default_check+0x6e8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200d66:	450d                	li	a0,3
ffffffffc0200d68:	127000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200d6c:	8c2a                	mv	s8,a0
ffffffffc0200d6e:	46050b63          	beqz	a0,ffffffffc02011e4 <default_check+0x6c8>
    assert(alloc_page() == NULL);
ffffffffc0200d72:	4505                	li	a0,1
ffffffffc0200d74:	11b000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200d78:	44051663          	bnez	a0,ffffffffc02011c4 <default_check+0x6a8>
    assert(p0 + 2 == p1);
ffffffffc0200d7c:	438a1463          	bne	s4,s8,ffffffffc02011a4 <default_check+0x688>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200d80:	4585                	li	a1,1
ffffffffc0200d82:	854e                	mv	a0,s3
ffffffffc0200d84:	1b5000ef          	jal	ra,ffffffffc0201738 <free_pages>
    free_pages(p1, 3);
ffffffffc0200d88:	458d                	li	a1,3
ffffffffc0200d8a:	8552                	mv	a0,s4
ffffffffc0200d8c:	1ad000ef          	jal	ra,ffffffffc0201738 <free_pages>
ffffffffc0200d90:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200d94:	04898c13          	addi	s8,s3,72
ffffffffc0200d98:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200d9a:	8b85                	andi	a5,a5,1
ffffffffc0200d9c:	3e078463          	beqz	a5,ffffffffc0201184 <default_check+0x668>
ffffffffc0200da0:	0189a703          	lw	a4,24(s3)
ffffffffc0200da4:	4785                	li	a5,1
ffffffffc0200da6:	3cf71f63          	bne	a4,a5,ffffffffc0201184 <default_check+0x668>
ffffffffc0200daa:	008a3783          	ld	a5,8(s4)
ffffffffc0200dae:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200db0:	8b85                	andi	a5,a5,1
ffffffffc0200db2:	3a078963          	beqz	a5,ffffffffc0201164 <default_check+0x648>
ffffffffc0200db6:	018a2703          	lw	a4,24(s4)
ffffffffc0200dba:	478d                	li	a5,3
ffffffffc0200dbc:	3af71463          	bne	a4,a5,ffffffffc0201164 <default_check+0x648>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200dc0:	4505                	li	a0,1
ffffffffc0200dc2:	0cd000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200dc6:	36a99f63          	bne	s3,a0,ffffffffc0201144 <default_check+0x628>
    free_page(p0);
ffffffffc0200dca:	4585                	li	a1,1
ffffffffc0200dcc:	16d000ef          	jal	ra,ffffffffc0201738 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200dd0:	4509                	li	a0,2
ffffffffc0200dd2:	0bd000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200dd6:	34aa1763          	bne	s4,a0,ffffffffc0201124 <default_check+0x608>

    free_pages(p0, 2);
ffffffffc0200dda:	4589                	li	a1,2
ffffffffc0200ddc:	15d000ef          	jal	ra,ffffffffc0201738 <free_pages>
    free_page(p2);
ffffffffc0200de0:	4585                	li	a1,1
ffffffffc0200de2:	8562                	mv	a0,s8
ffffffffc0200de4:	155000ef          	jal	ra,ffffffffc0201738 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200de8:	4515                	li	a0,5
ffffffffc0200dea:	0a5000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200dee:	89aa                	mv	s3,a0
ffffffffc0200df0:	48050a63          	beqz	a0,ffffffffc0201284 <default_check+0x768>
    assert(alloc_page() == NULL);
ffffffffc0200df4:	4505                	li	a0,1
ffffffffc0200df6:	099000ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0200dfa:	2e051563          	bnez	a0,ffffffffc02010e4 <default_check+0x5c8>

    assert(nr_free == 0);
ffffffffc0200dfe:	01092783          	lw	a5,16(s2)
ffffffffc0200e02:	2c079163          	bnez	a5,ffffffffc02010c4 <default_check+0x5a8>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200e06:	4595                	li	a1,5
ffffffffc0200e08:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200e0a:	00010797          	auipc	a5,0x10
ffffffffc0200e0e:	6977a323          	sw	s7,1670(a5) # ffffffffc0211490 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0200e12:	00010797          	auipc	a5,0x10
ffffffffc0200e16:	6767b723          	sd	s6,1646(a5) # ffffffffc0211480 <free_area>
ffffffffc0200e1a:	00010797          	auipc	a5,0x10
ffffffffc0200e1e:	6757b723          	sd	s5,1646(a5) # ffffffffc0211488 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0200e22:	117000ef          	jal	ra,ffffffffc0201738 <free_pages>
    return listelm->next;
ffffffffc0200e26:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e2a:	01278963          	beq	a5,s2,ffffffffc0200e3c <default_check+0x320>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200e2e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e32:	679c                	ld	a5,8(a5)
ffffffffc0200e34:	34fd                	addiw	s1,s1,-1
ffffffffc0200e36:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e38:	ff279be3          	bne	a5,s2,ffffffffc0200e2e <default_check+0x312>
    }
    assert(count == 0);
ffffffffc0200e3c:	26049463          	bnez	s1,ffffffffc02010a4 <default_check+0x588>
    assert(total == 0);
ffffffffc0200e40:	46041263          	bnez	s0,ffffffffc02012a4 <default_check+0x788>
}
ffffffffc0200e44:	60a6                	ld	ra,72(sp)
ffffffffc0200e46:	6406                	ld	s0,64(sp)
ffffffffc0200e48:	74e2                	ld	s1,56(sp)
ffffffffc0200e4a:	7942                	ld	s2,48(sp)
ffffffffc0200e4c:	79a2                	ld	s3,40(sp)
ffffffffc0200e4e:	7a02                	ld	s4,32(sp)
ffffffffc0200e50:	6ae2                	ld	s5,24(sp)
ffffffffc0200e52:	6b42                	ld	s6,16(sp)
ffffffffc0200e54:	6ba2                	ld	s7,8(sp)
ffffffffc0200e56:	6c02                	ld	s8,0(sp)
ffffffffc0200e58:	6161                	addi	sp,sp,80
ffffffffc0200e5a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e5c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200e5e:	4401                	li	s0,0
ffffffffc0200e60:	4481                	li	s1,0
ffffffffc0200e62:	b331                	j	ffffffffc0200b6e <default_check+0x52>
        assert(PageProperty(p));
ffffffffc0200e64:	00004697          	auipc	a3,0x4
ffffffffc0200e68:	eac68693          	addi	a3,a3,-340 # ffffffffc0204d10 <commands+0x860>
ffffffffc0200e6c:	00004617          	auipc	a2,0x4
ffffffffc0200e70:	eb460613          	addi	a2,a2,-332 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200e74:	0f000593          	li	a1,240
ffffffffc0200e78:	00004517          	auipc	a0,0x4
ffffffffc0200e7c:	ec050513          	addi	a0,a0,-320 # ffffffffc0204d38 <commands+0x888>
ffffffffc0200e80:	cf4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e84:	00004697          	auipc	a3,0x4
ffffffffc0200e88:	f4c68693          	addi	a3,a3,-180 # ffffffffc0204dd0 <commands+0x920>
ffffffffc0200e8c:	00004617          	auipc	a2,0x4
ffffffffc0200e90:	e9460613          	addi	a2,a2,-364 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200e94:	0bd00593          	li	a1,189
ffffffffc0200e98:	00004517          	auipc	a0,0x4
ffffffffc0200e9c:	ea050513          	addi	a0,a0,-352 # ffffffffc0204d38 <commands+0x888>
ffffffffc0200ea0:	cd4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ea4:	00004697          	auipc	a3,0x4
ffffffffc0200ea8:	f5468693          	addi	a3,a3,-172 # ffffffffc0204df8 <commands+0x948>
ffffffffc0200eac:	00004617          	auipc	a2,0x4
ffffffffc0200eb0:	e7460613          	addi	a2,a2,-396 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200eb4:	0be00593          	li	a1,190
ffffffffc0200eb8:	00004517          	auipc	a0,0x4
ffffffffc0200ebc:	e8050513          	addi	a0,a0,-384 # ffffffffc0204d38 <commands+0x888>
ffffffffc0200ec0:	cb4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200ec4:	00004697          	auipc	a3,0x4
ffffffffc0200ec8:	f7468693          	addi	a3,a3,-140 # ffffffffc0204e38 <commands+0x988>
ffffffffc0200ecc:	00004617          	auipc	a2,0x4
ffffffffc0200ed0:	e5460613          	addi	a2,a2,-428 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200ed4:	0c000593          	li	a1,192
ffffffffc0200ed8:	00004517          	auipc	a0,0x4
ffffffffc0200edc:	e6050513          	addi	a0,a0,-416 # ffffffffc0204d38 <commands+0x888>
ffffffffc0200ee0:	c94ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200ee4:	00004697          	auipc	a3,0x4
ffffffffc0200ee8:	fdc68693          	addi	a3,a3,-36 # ffffffffc0204ec0 <commands+0xa10>
ffffffffc0200eec:	00004617          	auipc	a2,0x4
ffffffffc0200ef0:	e3460613          	addi	a2,a2,-460 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200ef4:	0d900593          	li	a1,217
ffffffffc0200ef8:	00004517          	auipc	a0,0x4
ffffffffc0200efc:	e4050513          	addi	a0,a0,-448 # ffffffffc0204d38 <commands+0x888>
ffffffffc0200f00:	c74ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f04:	00004697          	auipc	a3,0x4
ffffffffc0200f08:	e6c68693          	addi	a3,a3,-404 # ffffffffc0204d70 <commands+0x8c0>
ffffffffc0200f0c:	00004617          	auipc	a2,0x4
ffffffffc0200f10:	e1460613          	addi	a2,a2,-492 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200f14:	0d200593          	li	a1,210
ffffffffc0200f18:	00004517          	auipc	a0,0x4
ffffffffc0200f1c:	e2050513          	addi	a0,a0,-480 # ffffffffc0204d38 <commands+0x888>
ffffffffc0200f20:	c54ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free == 3);
ffffffffc0200f24:	00004697          	auipc	a3,0x4
ffffffffc0200f28:	f8c68693          	addi	a3,a3,-116 # ffffffffc0204eb0 <commands+0xa00>
ffffffffc0200f2c:	00004617          	auipc	a2,0x4
ffffffffc0200f30:	df460613          	addi	a2,a2,-524 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200f34:	0d000593          	li	a1,208
ffffffffc0200f38:	00004517          	auipc	a0,0x4
ffffffffc0200f3c:	e0050513          	addi	a0,a0,-512 # ffffffffc0204d38 <commands+0x888>
ffffffffc0200f40:	c34ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f44:	00004697          	auipc	a3,0x4
ffffffffc0200f48:	f5468693          	addi	a3,a3,-172 # ffffffffc0204e98 <commands+0x9e8>
ffffffffc0200f4c:	00004617          	auipc	a2,0x4
ffffffffc0200f50:	dd460613          	addi	a2,a2,-556 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200f54:	0cb00593          	li	a1,203
ffffffffc0200f58:	00004517          	auipc	a0,0x4
ffffffffc0200f5c:	de050513          	addi	a0,a0,-544 # ffffffffc0204d38 <commands+0x888>
ffffffffc0200f60:	c14ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f64:	00004697          	auipc	a3,0x4
ffffffffc0200f68:	f1468693          	addi	a3,a3,-236 # ffffffffc0204e78 <commands+0x9c8>
ffffffffc0200f6c:	00004617          	auipc	a2,0x4
ffffffffc0200f70:	db460613          	addi	a2,a2,-588 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200f74:	0c200593          	li	a1,194
ffffffffc0200f78:	00004517          	auipc	a0,0x4
ffffffffc0200f7c:	dc050513          	addi	a0,a0,-576 # ffffffffc0204d38 <commands+0x888>
ffffffffc0200f80:	bf4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(p0 != NULL);
ffffffffc0200f84:	00004697          	auipc	a3,0x4
ffffffffc0200f88:	f8468693          	addi	a3,a3,-124 # ffffffffc0204f08 <commands+0xa58>
ffffffffc0200f8c:	00004617          	auipc	a2,0x4
ffffffffc0200f90:	d9460613          	addi	a2,a2,-620 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200f94:	0f800593          	li	a1,248
ffffffffc0200f98:	00004517          	auipc	a0,0x4
ffffffffc0200f9c:	da050513          	addi	a0,a0,-608 # ffffffffc0204d38 <commands+0x888>
ffffffffc0200fa0:	bd4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free == 0);
ffffffffc0200fa4:	00004697          	auipc	a3,0x4
ffffffffc0200fa8:	f5468693          	addi	a3,a3,-172 # ffffffffc0204ef8 <commands+0xa48>
ffffffffc0200fac:	00004617          	auipc	a2,0x4
ffffffffc0200fb0:	d7460613          	addi	a2,a2,-652 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200fb4:	0df00593          	li	a1,223
ffffffffc0200fb8:	00004517          	auipc	a0,0x4
ffffffffc0200fbc:	d8050513          	addi	a0,a0,-640 # ffffffffc0204d38 <commands+0x888>
ffffffffc0200fc0:	bb4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fc4:	00004697          	auipc	a3,0x4
ffffffffc0200fc8:	ed468693          	addi	a3,a3,-300 # ffffffffc0204e98 <commands+0x9e8>
ffffffffc0200fcc:	00004617          	auipc	a2,0x4
ffffffffc0200fd0:	d5460613          	addi	a2,a2,-684 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200fd4:	0dd00593          	li	a1,221
ffffffffc0200fd8:	00004517          	auipc	a0,0x4
ffffffffc0200fdc:	d6050513          	addi	a0,a0,-672 # ffffffffc0204d38 <commands+0x888>
ffffffffc0200fe0:	b94ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200fe4:	00004697          	auipc	a3,0x4
ffffffffc0200fe8:	ef468693          	addi	a3,a3,-268 # ffffffffc0204ed8 <commands+0xa28>
ffffffffc0200fec:	00004617          	auipc	a2,0x4
ffffffffc0200ff0:	d3460613          	addi	a2,a2,-716 # ffffffffc0204d20 <commands+0x870>
ffffffffc0200ff4:	0dc00593          	li	a1,220
ffffffffc0200ff8:	00004517          	auipc	a0,0x4
ffffffffc0200ffc:	d4050513          	addi	a0,a0,-704 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201000:	b74ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201004:	00004697          	auipc	a3,0x4
ffffffffc0201008:	d6c68693          	addi	a3,a3,-660 # ffffffffc0204d70 <commands+0x8c0>
ffffffffc020100c:	00004617          	auipc	a2,0x4
ffffffffc0201010:	d1460613          	addi	a2,a2,-748 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201014:	0b900593          	li	a1,185
ffffffffc0201018:	00004517          	auipc	a0,0x4
ffffffffc020101c:	d2050513          	addi	a0,a0,-736 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201020:	b54ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201024:	00004697          	auipc	a3,0x4
ffffffffc0201028:	e7468693          	addi	a3,a3,-396 # ffffffffc0204e98 <commands+0x9e8>
ffffffffc020102c:	00004617          	auipc	a2,0x4
ffffffffc0201030:	cf460613          	addi	a2,a2,-780 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201034:	0d600593          	li	a1,214
ffffffffc0201038:	00004517          	auipc	a0,0x4
ffffffffc020103c:	d0050513          	addi	a0,a0,-768 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201040:	b34ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201044:	00004697          	auipc	a3,0x4
ffffffffc0201048:	d6c68693          	addi	a3,a3,-660 # ffffffffc0204db0 <commands+0x900>
ffffffffc020104c:	00004617          	auipc	a2,0x4
ffffffffc0201050:	cd460613          	addi	a2,a2,-812 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201054:	0d400593          	li	a1,212
ffffffffc0201058:	00004517          	auipc	a0,0x4
ffffffffc020105c:	ce050513          	addi	a0,a0,-800 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201060:	b14ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201064:	00004697          	auipc	a3,0x4
ffffffffc0201068:	d2c68693          	addi	a3,a3,-724 # ffffffffc0204d90 <commands+0x8e0>
ffffffffc020106c:	00004617          	auipc	a2,0x4
ffffffffc0201070:	cb460613          	addi	a2,a2,-844 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201074:	0d300593          	li	a1,211
ffffffffc0201078:	00004517          	auipc	a0,0x4
ffffffffc020107c:	cc050513          	addi	a0,a0,-832 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201080:	af4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201084:	00004697          	auipc	a3,0x4
ffffffffc0201088:	d2c68693          	addi	a3,a3,-724 # ffffffffc0204db0 <commands+0x900>
ffffffffc020108c:	00004617          	auipc	a2,0x4
ffffffffc0201090:	c9460613          	addi	a2,a2,-876 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201094:	0bb00593          	li	a1,187
ffffffffc0201098:	00004517          	auipc	a0,0x4
ffffffffc020109c:	ca050513          	addi	a0,a0,-864 # ffffffffc0204d38 <commands+0x888>
ffffffffc02010a0:	ad4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(count == 0);
ffffffffc02010a4:	00004697          	auipc	a3,0x4
ffffffffc02010a8:	fb468693          	addi	a3,a3,-76 # ffffffffc0205058 <commands+0xba8>
ffffffffc02010ac:	00004617          	auipc	a2,0x4
ffffffffc02010b0:	c7460613          	addi	a2,a2,-908 # ffffffffc0204d20 <commands+0x870>
ffffffffc02010b4:	12500593          	li	a1,293
ffffffffc02010b8:	00004517          	auipc	a0,0x4
ffffffffc02010bc:	c8050513          	addi	a0,a0,-896 # ffffffffc0204d38 <commands+0x888>
ffffffffc02010c0:	ab4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free == 0);
ffffffffc02010c4:	00004697          	auipc	a3,0x4
ffffffffc02010c8:	e3468693          	addi	a3,a3,-460 # ffffffffc0204ef8 <commands+0xa48>
ffffffffc02010cc:	00004617          	auipc	a2,0x4
ffffffffc02010d0:	c5460613          	addi	a2,a2,-940 # ffffffffc0204d20 <commands+0x870>
ffffffffc02010d4:	11a00593          	li	a1,282
ffffffffc02010d8:	00004517          	auipc	a0,0x4
ffffffffc02010dc:	c6050513          	addi	a0,a0,-928 # ffffffffc0204d38 <commands+0x888>
ffffffffc02010e0:	a94ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010e4:	00004697          	auipc	a3,0x4
ffffffffc02010e8:	db468693          	addi	a3,a3,-588 # ffffffffc0204e98 <commands+0x9e8>
ffffffffc02010ec:	00004617          	auipc	a2,0x4
ffffffffc02010f0:	c3460613          	addi	a2,a2,-972 # ffffffffc0204d20 <commands+0x870>
ffffffffc02010f4:	11800593          	li	a1,280
ffffffffc02010f8:	00004517          	auipc	a0,0x4
ffffffffc02010fc:	c4050513          	addi	a0,a0,-960 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201100:	a74ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201104:	00004697          	auipc	a3,0x4
ffffffffc0201108:	d5468693          	addi	a3,a3,-684 # ffffffffc0204e58 <commands+0x9a8>
ffffffffc020110c:	00004617          	auipc	a2,0x4
ffffffffc0201110:	c1460613          	addi	a2,a2,-1004 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201114:	0c100593          	li	a1,193
ffffffffc0201118:	00004517          	auipc	a0,0x4
ffffffffc020111c:	c2050513          	addi	a0,a0,-992 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201120:	a54ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201124:	00004697          	auipc	a3,0x4
ffffffffc0201128:	ef468693          	addi	a3,a3,-268 # ffffffffc0205018 <commands+0xb68>
ffffffffc020112c:	00004617          	auipc	a2,0x4
ffffffffc0201130:	bf460613          	addi	a2,a2,-1036 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201134:	11200593          	li	a1,274
ffffffffc0201138:	00004517          	auipc	a0,0x4
ffffffffc020113c:	c0050513          	addi	a0,a0,-1024 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201140:	a34ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201144:	00004697          	auipc	a3,0x4
ffffffffc0201148:	eb468693          	addi	a3,a3,-332 # ffffffffc0204ff8 <commands+0xb48>
ffffffffc020114c:	00004617          	auipc	a2,0x4
ffffffffc0201150:	bd460613          	addi	a2,a2,-1068 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201154:	11000593          	li	a1,272
ffffffffc0201158:	00004517          	auipc	a0,0x4
ffffffffc020115c:	be050513          	addi	a0,a0,-1056 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201160:	a14ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201164:	00004697          	auipc	a3,0x4
ffffffffc0201168:	e6c68693          	addi	a3,a3,-404 # ffffffffc0204fd0 <commands+0xb20>
ffffffffc020116c:	00004617          	auipc	a2,0x4
ffffffffc0201170:	bb460613          	addi	a2,a2,-1100 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201174:	10e00593          	li	a1,270
ffffffffc0201178:	00004517          	auipc	a0,0x4
ffffffffc020117c:	bc050513          	addi	a0,a0,-1088 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201180:	9f4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201184:	00004697          	auipc	a3,0x4
ffffffffc0201188:	e2468693          	addi	a3,a3,-476 # ffffffffc0204fa8 <commands+0xaf8>
ffffffffc020118c:	00004617          	auipc	a2,0x4
ffffffffc0201190:	b9460613          	addi	a2,a2,-1132 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201194:	10d00593          	li	a1,269
ffffffffc0201198:	00004517          	auipc	a0,0x4
ffffffffc020119c:	ba050513          	addi	a0,a0,-1120 # ffffffffc0204d38 <commands+0x888>
ffffffffc02011a0:	9d4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02011a4:	00004697          	auipc	a3,0x4
ffffffffc02011a8:	df468693          	addi	a3,a3,-524 # ffffffffc0204f98 <commands+0xae8>
ffffffffc02011ac:	00004617          	auipc	a2,0x4
ffffffffc02011b0:	b7460613          	addi	a2,a2,-1164 # ffffffffc0204d20 <commands+0x870>
ffffffffc02011b4:	10800593          	li	a1,264
ffffffffc02011b8:	00004517          	auipc	a0,0x4
ffffffffc02011bc:	b8050513          	addi	a0,a0,-1152 # ffffffffc0204d38 <commands+0x888>
ffffffffc02011c0:	9b4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011c4:	00004697          	auipc	a3,0x4
ffffffffc02011c8:	cd468693          	addi	a3,a3,-812 # ffffffffc0204e98 <commands+0x9e8>
ffffffffc02011cc:	00004617          	auipc	a2,0x4
ffffffffc02011d0:	b5460613          	addi	a2,a2,-1196 # ffffffffc0204d20 <commands+0x870>
ffffffffc02011d4:	10700593          	li	a1,263
ffffffffc02011d8:	00004517          	auipc	a0,0x4
ffffffffc02011dc:	b6050513          	addi	a0,a0,-1184 # ffffffffc0204d38 <commands+0x888>
ffffffffc02011e0:	994ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011e4:	00004697          	auipc	a3,0x4
ffffffffc02011e8:	d9468693          	addi	a3,a3,-620 # ffffffffc0204f78 <commands+0xac8>
ffffffffc02011ec:	00004617          	auipc	a2,0x4
ffffffffc02011f0:	b3460613          	addi	a2,a2,-1228 # ffffffffc0204d20 <commands+0x870>
ffffffffc02011f4:	10600593          	li	a1,262
ffffffffc02011f8:	00004517          	auipc	a0,0x4
ffffffffc02011fc:	b4050513          	addi	a0,a0,-1216 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201200:	974ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201204:	00004697          	auipc	a3,0x4
ffffffffc0201208:	d4468693          	addi	a3,a3,-700 # ffffffffc0204f48 <commands+0xa98>
ffffffffc020120c:	00004617          	auipc	a2,0x4
ffffffffc0201210:	b1460613          	addi	a2,a2,-1260 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201214:	10500593          	li	a1,261
ffffffffc0201218:	00004517          	auipc	a0,0x4
ffffffffc020121c:	b2050513          	addi	a0,a0,-1248 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201220:	954ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201224:	00004697          	auipc	a3,0x4
ffffffffc0201228:	d0c68693          	addi	a3,a3,-756 # ffffffffc0204f30 <commands+0xa80>
ffffffffc020122c:	00004617          	auipc	a2,0x4
ffffffffc0201230:	af460613          	addi	a2,a2,-1292 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201234:	10400593          	li	a1,260
ffffffffc0201238:	00004517          	auipc	a0,0x4
ffffffffc020123c:	b0050513          	addi	a0,a0,-1280 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201240:	934ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201244:	00004697          	auipc	a3,0x4
ffffffffc0201248:	c5468693          	addi	a3,a3,-940 # ffffffffc0204e98 <commands+0x9e8>
ffffffffc020124c:	00004617          	auipc	a2,0x4
ffffffffc0201250:	ad460613          	addi	a2,a2,-1324 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201254:	0fe00593          	li	a1,254
ffffffffc0201258:	00004517          	auipc	a0,0x4
ffffffffc020125c:	ae050513          	addi	a0,a0,-1312 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201260:	914ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201264:	00004697          	auipc	a3,0x4
ffffffffc0201268:	cb468693          	addi	a3,a3,-844 # ffffffffc0204f18 <commands+0xa68>
ffffffffc020126c:	00004617          	auipc	a2,0x4
ffffffffc0201270:	ab460613          	addi	a2,a2,-1356 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201274:	0f900593          	li	a1,249
ffffffffc0201278:	00004517          	auipc	a0,0x4
ffffffffc020127c:	ac050513          	addi	a0,a0,-1344 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201280:	8f4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201284:	00004697          	auipc	a3,0x4
ffffffffc0201288:	db468693          	addi	a3,a3,-588 # ffffffffc0205038 <commands+0xb88>
ffffffffc020128c:	00004617          	auipc	a2,0x4
ffffffffc0201290:	a9460613          	addi	a2,a2,-1388 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201294:	11700593          	li	a1,279
ffffffffc0201298:	00004517          	auipc	a0,0x4
ffffffffc020129c:	aa050513          	addi	a0,a0,-1376 # ffffffffc0204d38 <commands+0x888>
ffffffffc02012a0:	8d4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(total == 0);
ffffffffc02012a4:	00004697          	auipc	a3,0x4
ffffffffc02012a8:	dc468693          	addi	a3,a3,-572 # ffffffffc0205068 <commands+0xbb8>
ffffffffc02012ac:	00004617          	auipc	a2,0x4
ffffffffc02012b0:	a7460613          	addi	a2,a2,-1420 # ffffffffc0204d20 <commands+0x870>
ffffffffc02012b4:	12600593          	li	a1,294
ffffffffc02012b8:	00004517          	auipc	a0,0x4
ffffffffc02012bc:	a8050513          	addi	a0,a0,-1408 # ffffffffc0204d38 <commands+0x888>
ffffffffc02012c0:	8b4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(total == nr_free_pages());
ffffffffc02012c4:	00004697          	auipc	a3,0x4
ffffffffc02012c8:	a8c68693          	addi	a3,a3,-1396 # ffffffffc0204d50 <commands+0x8a0>
ffffffffc02012cc:	00004617          	auipc	a2,0x4
ffffffffc02012d0:	a5460613          	addi	a2,a2,-1452 # ffffffffc0204d20 <commands+0x870>
ffffffffc02012d4:	0f300593          	li	a1,243
ffffffffc02012d8:	00004517          	auipc	a0,0x4
ffffffffc02012dc:	a6050513          	addi	a0,a0,-1440 # ffffffffc0204d38 <commands+0x888>
ffffffffc02012e0:	894ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012e4:	00004697          	auipc	a3,0x4
ffffffffc02012e8:	aac68693          	addi	a3,a3,-1364 # ffffffffc0204d90 <commands+0x8e0>
ffffffffc02012ec:	00004617          	auipc	a2,0x4
ffffffffc02012f0:	a3460613          	addi	a2,a2,-1484 # ffffffffc0204d20 <commands+0x870>
ffffffffc02012f4:	0ba00593          	li	a1,186
ffffffffc02012f8:	00004517          	auipc	a0,0x4
ffffffffc02012fc:	a4050513          	addi	a0,a0,-1472 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201300:	874ff0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0201304 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201304:	1141                	addi	sp,sp,-16
ffffffffc0201306:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201308:	18058063          	beqz	a1,ffffffffc0201488 <default_free_pages+0x184>
    for (; p != base + n; p ++) {
ffffffffc020130c:	00359693          	slli	a3,a1,0x3
ffffffffc0201310:	96ae                	add	a3,a3,a1
ffffffffc0201312:	068e                	slli	a3,a3,0x3
ffffffffc0201314:	96aa                	add	a3,a3,a0
ffffffffc0201316:	02d50d63          	beq	a0,a3,ffffffffc0201350 <default_free_pages+0x4c>
ffffffffc020131a:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020131c:	8b85                	andi	a5,a5,1
ffffffffc020131e:	14079563          	bnez	a5,ffffffffc0201468 <default_free_pages+0x164>
ffffffffc0201322:	651c                	ld	a5,8(a0)
ffffffffc0201324:	8385                	srli	a5,a5,0x1
ffffffffc0201326:	8b85                	andi	a5,a5,1
ffffffffc0201328:	14079063          	bnez	a5,ffffffffc0201468 <default_free_pages+0x164>
ffffffffc020132c:	87aa                	mv	a5,a0
ffffffffc020132e:	a809                	j	ffffffffc0201340 <default_free_pages+0x3c>
ffffffffc0201330:	6798                	ld	a4,8(a5)
ffffffffc0201332:	8b05                	andi	a4,a4,1
ffffffffc0201334:	12071a63          	bnez	a4,ffffffffc0201468 <default_free_pages+0x164>
ffffffffc0201338:	6798                	ld	a4,8(a5)
ffffffffc020133a:	8b09                	andi	a4,a4,2
ffffffffc020133c:	12071663          	bnez	a4,ffffffffc0201468 <default_free_pages+0x164>
        p->flags = 0;
ffffffffc0201340:	0007b423          	sd	zero,8(a5)
    return pa2page(PDE_ADDR(pde));
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201344:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201348:	04878793          	addi	a5,a5,72
ffffffffc020134c:	fed792e3          	bne	a5,a3,ffffffffc0201330 <default_free_pages+0x2c>
    base->property = n;
ffffffffc0201350:	2581                	sext.w	a1,a1
ffffffffc0201352:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc0201354:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201358:	4789                	li	a5,2
ffffffffc020135a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020135e:	00010697          	auipc	a3,0x10
ffffffffc0201362:	12268693          	addi	a3,a3,290 # ffffffffc0211480 <free_area>
ffffffffc0201366:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201368:	669c                	ld	a5,8(a3)
ffffffffc020136a:	9db9                	addw	a1,a1,a4
ffffffffc020136c:	00010717          	auipc	a4,0x10
ffffffffc0201370:	12b72223          	sw	a1,292(a4) # ffffffffc0211490 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0201374:	08d78f63          	beq	a5,a3,ffffffffc0201412 <default_free_pages+0x10e>
            struct Page* page = le2page(le, page_link);
ffffffffc0201378:	fe078713          	addi	a4,a5,-32
ffffffffc020137c:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020137e:	4801                	li	a6,0
ffffffffc0201380:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc0201384:	00e56a63          	bltu	a0,a4,ffffffffc0201398 <default_free_pages+0x94>
    return listelm->next;
ffffffffc0201388:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020138a:	02d70563          	beq	a4,a3,ffffffffc02013b4 <default_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc020138e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201390:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0201394:	fee57ae3          	bleu	a4,a0,ffffffffc0201388 <default_free_pages+0x84>
ffffffffc0201398:	00080663          	beqz	a6,ffffffffc02013a4 <default_free_pages+0xa0>
ffffffffc020139c:	00010817          	auipc	a6,0x10
ffffffffc02013a0:	0eb83223          	sd	a1,228(a6) # ffffffffc0211480 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02013a4:	638c                	ld	a1,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02013a6:	e390                	sd	a2,0(a5)
ffffffffc02013a8:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc02013aa:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02013ac:	f10c                	sd	a1,32(a0)
    if (le != &free_list) {
ffffffffc02013ae:	02d59163          	bne	a1,a3,ffffffffc02013d0 <default_free_pages+0xcc>
ffffffffc02013b2:	a091                	j	ffffffffc02013f6 <default_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc02013b4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02013b6:	f514                	sd	a3,40(a0)
ffffffffc02013b8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02013ba:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc02013bc:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02013be:	00d70563          	beq	a4,a3,ffffffffc02013c8 <default_free_pages+0xc4>
ffffffffc02013c2:	4805                	li	a6,1
ffffffffc02013c4:	87ba                	mv	a5,a4
ffffffffc02013c6:	b7e9                	j	ffffffffc0201390 <default_free_pages+0x8c>
ffffffffc02013c8:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02013ca:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc02013cc:	02d78163          	beq	a5,a3,ffffffffc02013ee <default_free_pages+0xea>
        if (p + p->property == base) {
ffffffffc02013d0:	ff85a803          	lw	a6,-8(a1)
        p = le2page(le, page_link);
ffffffffc02013d4:	fe058613          	addi	a2,a1,-32
        if (p + p->property == base) {
ffffffffc02013d8:	02081713          	slli	a4,a6,0x20
ffffffffc02013dc:	9301                	srli	a4,a4,0x20
ffffffffc02013de:	00371793          	slli	a5,a4,0x3
ffffffffc02013e2:	97ba                	add	a5,a5,a4
ffffffffc02013e4:	078e                	slli	a5,a5,0x3
ffffffffc02013e6:	97b2                	add	a5,a5,a2
ffffffffc02013e8:	02f50e63          	beq	a0,a5,ffffffffc0201424 <default_free_pages+0x120>
ffffffffc02013ec:	751c                	ld	a5,40(a0)
    if (le != &free_list) {
ffffffffc02013ee:	fe078713          	addi	a4,a5,-32
ffffffffc02013f2:	00d78d63          	beq	a5,a3,ffffffffc020140c <default_free_pages+0x108>
        if (base + base->property == p) {
ffffffffc02013f6:	4d0c                	lw	a1,24(a0)
ffffffffc02013f8:	02059613          	slli	a2,a1,0x20
ffffffffc02013fc:	9201                	srli	a2,a2,0x20
ffffffffc02013fe:	00361693          	slli	a3,a2,0x3
ffffffffc0201402:	96b2                	add	a3,a3,a2
ffffffffc0201404:	068e                	slli	a3,a3,0x3
ffffffffc0201406:	96aa                	add	a3,a3,a0
ffffffffc0201408:	04d70063          	beq	a4,a3,ffffffffc0201448 <default_free_pages+0x144>
}
ffffffffc020140c:	60a2                	ld	ra,8(sp)
ffffffffc020140e:	0141                	addi	sp,sp,16
ffffffffc0201410:	8082                	ret
ffffffffc0201412:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201414:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc0201418:	e398                	sd	a4,0(a5)
ffffffffc020141a:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020141c:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc020141e:	f11c                	sd	a5,32(a0)
}
ffffffffc0201420:	0141                	addi	sp,sp,16
ffffffffc0201422:	8082                	ret
            p->property += base->property;
ffffffffc0201424:	4d1c                	lw	a5,24(a0)
ffffffffc0201426:	0107883b          	addw	a6,a5,a6
ffffffffc020142a:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020142e:	57f5                	li	a5,-3
ffffffffc0201430:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201434:	02053803          	ld	a6,32(a0)
ffffffffc0201438:	7518                	ld	a4,40(a0)
            base = p;
ffffffffc020143a:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020143c:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0201440:	659c                	ld	a5,8(a1)
ffffffffc0201442:	01073023          	sd	a6,0(a4)
ffffffffc0201446:	b765                	j	ffffffffc02013ee <default_free_pages+0xea>
            base->property += p->property;
ffffffffc0201448:	ff87a703          	lw	a4,-8(a5)
ffffffffc020144c:	fe878693          	addi	a3,a5,-24
ffffffffc0201450:	9db9                	addw	a1,a1,a4
ffffffffc0201452:	cd0c                	sw	a1,24(a0)
ffffffffc0201454:	5775                	li	a4,-3
ffffffffc0201456:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020145a:	6398                	ld	a4,0(a5)
ffffffffc020145c:	679c                	ld	a5,8(a5)
}
ffffffffc020145e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201460:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201462:	e398                	sd	a4,0(a5)
ffffffffc0201464:	0141                	addi	sp,sp,16
ffffffffc0201466:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201468:	00004697          	auipc	a3,0x4
ffffffffc020146c:	c1068693          	addi	a3,a3,-1008 # ffffffffc0205078 <commands+0xbc8>
ffffffffc0201470:	00004617          	auipc	a2,0x4
ffffffffc0201474:	8b060613          	addi	a2,a2,-1872 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201478:	08300593          	li	a1,131
ffffffffc020147c:	00004517          	auipc	a0,0x4
ffffffffc0201480:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0204d38 <commands+0x888>
ffffffffc0201484:	ef1fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(n > 0);
ffffffffc0201488:	00004697          	auipc	a3,0x4
ffffffffc020148c:	c1868693          	addi	a3,a3,-1000 # ffffffffc02050a0 <commands+0xbf0>
ffffffffc0201490:	00004617          	auipc	a2,0x4
ffffffffc0201494:	89060613          	addi	a2,a2,-1904 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201498:	08000593          	li	a1,128
ffffffffc020149c:	00004517          	auipc	a0,0x4
ffffffffc02014a0:	89c50513          	addi	a0,a0,-1892 # ffffffffc0204d38 <commands+0x888>
ffffffffc02014a4:	ed1fe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02014a8 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02014a8:	cd51                	beqz	a0,ffffffffc0201544 <default_alloc_pages+0x9c>
    if (n > nr_free) {
ffffffffc02014aa:	00010597          	auipc	a1,0x10
ffffffffc02014ae:	fd658593          	addi	a1,a1,-42 # ffffffffc0211480 <free_area>
ffffffffc02014b2:	0105a803          	lw	a6,16(a1)
ffffffffc02014b6:	862a                	mv	a2,a0
ffffffffc02014b8:	02081793          	slli	a5,a6,0x20
ffffffffc02014bc:	9381                	srli	a5,a5,0x20
ffffffffc02014be:	00a7ee63          	bltu	a5,a0,ffffffffc02014da <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02014c2:	87ae                	mv	a5,a1
ffffffffc02014c4:	a801                	j	ffffffffc02014d4 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc02014c6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02014ca:	02071693          	slli	a3,a4,0x20
ffffffffc02014ce:	9281                	srli	a3,a3,0x20
ffffffffc02014d0:	00c6f763          	bleu	a2,a3,ffffffffc02014de <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02014d4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02014d6:	feb798e3          	bne	a5,a1,ffffffffc02014c6 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02014da:	4501                	li	a0,0
}
ffffffffc02014dc:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc02014de:	fe078513          	addi	a0,a5,-32
    if (page != NULL) {
ffffffffc02014e2:	dd6d                	beqz	a0,ffffffffc02014dc <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc02014e4:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014e8:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc02014ec:	00060e1b          	sext.w	t3,a2
ffffffffc02014f0:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02014f4:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02014f8:	02d67b63          	bleu	a3,a2,ffffffffc020152e <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02014fc:	00361693          	slli	a3,a2,0x3
ffffffffc0201500:	96b2                	add	a3,a3,a2
ffffffffc0201502:	068e                	slli	a3,a3,0x3
ffffffffc0201504:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0201506:	41c7073b          	subw	a4,a4,t3
ffffffffc020150a:	ce98                	sw	a4,24(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020150c:	00868613          	addi	a2,a3,8
ffffffffc0201510:	4709                	li	a4,2
ffffffffc0201512:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201516:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020151a:	02068613          	addi	a2,a3,32
    prev->next = next->prev = elm;
ffffffffc020151e:	0105a803          	lw	a6,16(a1)
ffffffffc0201522:	e310                	sd	a2,0(a4)
ffffffffc0201524:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201528:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc020152a:	0316b023          	sd	a7,32(a3)
        nr_free -= n;
ffffffffc020152e:	41c8083b          	subw	a6,a6,t3
ffffffffc0201532:	00010717          	auipc	a4,0x10
ffffffffc0201536:	f5072f23          	sw	a6,-162(a4) # ffffffffc0211490 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020153a:	5775                	li	a4,-3
ffffffffc020153c:	17a1                	addi	a5,a5,-24
ffffffffc020153e:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0201542:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201544:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201546:	00004697          	auipc	a3,0x4
ffffffffc020154a:	b5a68693          	addi	a3,a3,-1190 # ffffffffc02050a0 <commands+0xbf0>
ffffffffc020154e:	00003617          	auipc	a2,0x3
ffffffffc0201552:	7d260613          	addi	a2,a2,2002 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201556:	06200593          	li	a1,98
ffffffffc020155a:	00003517          	auipc	a0,0x3
ffffffffc020155e:	7de50513          	addi	a0,a0,2014 # ffffffffc0204d38 <commands+0x888>
default_alloc_pages(size_t n) {
ffffffffc0201562:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201564:	e11fe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0201568 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201568:	1141                	addi	sp,sp,-16
ffffffffc020156a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020156c:	c1fd                	beqz	a1,ffffffffc0201652 <default_init_memmap+0xea>
    for (; p != base + n; p ++) {
ffffffffc020156e:	00359693          	slli	a3,a1,0x3
ffffffffc0201572:	96ae                	add	a3,a3,a1
ffffffffc0201574:	068e                	slli	a3,a3,0x3
ffffffffc0201576:	96aa                	add	a3,a3,a0
ffffffffc0201578:	02d50463          	beq	a0,a3,ffffffffc02015a0 <default_init_memmap+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020157c:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc020157e:	87aa                	mv	a5,a0
ffffffffc0201580:	8b05                	andi	a4,a4,1
ffffffffc0201582:	e709                	bnez	a4,ffffffffc020158c <default_init_memmap+0x24>
ffffffffc0201584:	a07d                	j	ffffffffc0201632 <default_init_memmap+0xca>
ffffffffc0201586:	6798                	ld	a4,8(a5)
ffffffffc0201588:	8b05                	andi	a4,a4,1
ffffffffc020158a:	c745                	beqz	a4,ffffffffc0201632 <default_init_memmap+0xca>
        p->flags = p->property = 0;
ffffffffc020158c:	0007ac23          	sw	zero,24(a5)
ffffffffc0201590:	0007b423          	sd	zero,8(a5)
ffffffffc0201594:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201598:	04878793          	addi	a5,a5,72
ffffffffc020159c:	fed795e3          	bne	a5,a3,ffffffffc0201586 <default_init_memmap+0x1e>
    base->property = n;
ffffffffc02015a0:	2581                	sext.w	a1,a1
ffffffffc02015a2:	cd0c                	sw	a1,24(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015a4:	4789                	li	a5,2
ffffffffc02015a6:	00850713          	addi	a4,a0,8
ffffffffc02015aa:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02015ae:	00010697          	auipc	a3,0x10
ffffffffc02015b2:	ed268693          	addi	a3,a3,-302 # ffffffffc0211480 <free_area>
ffffffffc02015b6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02015b8:	669c                	ld	a5,8(a3)
ffffffffc02015ba:	9db9                	addw	a1,a1,a4
ffffffffc02015bc:	00010717          	auipc	a4,0x10
ffffffffc02015c0:	ecb72a23          	sw	a1,-300(a4) # ffffffffc0211490 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc02015c4:	04d78a63          	beq	a5,a3,ffffffffc0201618 <default_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc02015c8:	fe078713          	addi	a4,a5,-32
ffffffffc02015cc:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02015ce:	4801                	li	a6,0
ffffffffc02015d0:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc02015d4:	00e56a63          	bltu	a0,a4,ffffffffc02015e8 <default_init_memmap+0x80>
    return listelm->next;
ffffffffc02015d8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02015da:	02d70563          	beq	a4,a3,ffffffffc0201604 <default_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015de:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02015e0:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc02015e4:	fee57ae3          	bleu	a4,a0,ffffffffc02015d8 <default_init_memmap+0x70>
ffffffffc02015e8:	00080663          	beqz	a6,ffffffffc02015f4 <default_init_memmap+0x8c>
ffffffffc02015ec:	00010717          	auipc	a4,0x10
ffffffffc02015f0:	e8b73a23          	sd	a1,-364(a4) # ffffffffc0211480 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02015f4:	6398                	ld	a4,0(a5)
}
ffffffffc02015f6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02015f8:	e390                	sd	a2,0(a5)
ffffffffc02015fa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02015fc:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02015fe:	f118                	sd	a4,32(a0)
ffffffffc0201600:	0141                	addi	sp,sp,16
ffffffffc0201602:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201604:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201606:	f514                	sd	a3,40(a0)
ffffffffc0201608:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020160a:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc020160c:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020160e:	00d70e63          	beq	a4,a3,ffffffffc020162a <default_init_memmap+0xc2>
ffffffffc0201612:	4805                	li	a6,1
ffffffffc0201614:	87ba                	mv	a5,a4
ffffffffc0201616:	b7e9                	j	ffffffffc02015e0 <default_init_memmap+0x78>
}
ffffffffc0201618:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020161a:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc020161e:	e398                	sd	a4,0(a5)
ffffffffc0201620:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201622:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0201624:	f11c                	sd	a5,32(a0)
}
ffffffffc0201626:	0141                	addi	sp,sp,16
ffffffffc0201628:	8082                	ret
ffffffffc020162a:	60a2                	ld	ra,8(sp)
ffffffffc020162c:	e290                	sd	a2,0(a3)
ffffffffc020162e:	0141                	addi	sp,sp,16
ffffffffc0201630:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201632:	00004697          	auipc	a3,0x4
ffffffffc0201636:	a7668693          	addi	a3,a3,-1418 # ffffffffc02050a8 <commands+0xbf8>
ffffffffc020163a:	00003617          	auipc	a2,0x3
ffffffffc020163e:	6e660613          	addi	a2,a2,1766 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201642:	04900593          	li	a1,73
ffffffffc0201646:	00003517          	auipc	a0,0x3
ffffffffc020164a:	6f250513          	addi	a0,a0,1778 # ffffffffc0204d38 <commands+0x888>
ffffffffc020164e:	d27fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(n > 0);
ffffffffc0201652:	00004697          	auipc	a3,0x4
ffffffffc0201656:	a4e68693          	addi	a3,a3,-1458 # ffffffffc02050a0 <commands+0xbf0>
ffffffffc020165a:	00003617          	auipc	a2,0x3
ffffffffc020165e:	6c660613          	addi	a2,a2,1734 # ffffffffc0204d20 <commands+0x870>
ffffffffc0201662:	04600593          	li	a1,70
ffffffffc0201666:	00003517          	auipc	a0,0x3
ffffffffc020166a:	6d250513          	addi	a0,a0,1746 # ffffffffc0204d38 <commands+0x888>
ffffffffc020166e:	d07fe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0201672 <pa2page.part.4>:
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0201672:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201674:	00004617          	auipc	a2,0x4
ffffffffc0201678:	b3c60613          	addi	a2,a2,-1220 # ffffffffc02051b0 <default_pmm_manager+0xf8>
ffffffffc020167c:	06500593          	li	a1,101
ffffffffc0201680:	00004517          	auipc	a0,0x4
ffffffffc0201684:	b5050513          	addi	a0,a0,-1200 # ffffffffc02051d0 <default_pmm_manager+0x118>
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0201688:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020168a:	cebfe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020168e <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n)
{
ffffffffc020168e:	715d                	addi	sp,sp,-80
ffffffffc0201690:	e0a2                	sd	s0,64(sp)
ffffffffc0201692:	f84a                	sd	s2,48(sp)
ffffffffc0201694:	f44e                	sd	s3,40(sp)
ffffffffc0201696:	f052                	sd	s4,32(sp)
ffffffffc0201698:	ec56                	sd	s5,24(sp)
ffffffffc020169a:	e85a                	sd	s6,16(sp)
ffffffffc020169c:	e45e                	sd	s7,8(sp)
ffffffffc020169e:	e486                	sd	ra,72(sp)
ffffffffc02016a0:	fc26                	sd	s1,56(sp)
ffffffffc02016a2:	842a                	mv	s0,a0
ffffffffc02016a4:	00010917          	auipc	s2,0x10
ffffffffc02016a8:	df490913          	addi	s2,s2,-524 # ffffffffc0211498 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0)
ffffffffc02016ac:	4a05                	li	s4,1
ffffffffc02016ae:	00010a97          	auipc	s5,0x10
ffffffffc02016b2:	dc2a8a93          	addi	s5,s5,-574 # ffffffffc0211470 <swap_init_ok>
            break;

        extern struct mm_struct *check_mm_struct;
        cprintf("page %x, call swap_out in alloc_pages %d\n", page, n);
ffffffffc02016b6:	00004997          	auipc	s3,0x4
ffffffffc02016ba:	a5298993          	addi	s3,s3,-1454 # ffffffffc0205108 <default_pmm_manager+0x50>
        swap_out(check_mm_struct, n, 0);
ffffffffc02016be:	00050b9b          	sext.w	s7,a0
ffffffffc02016c2:	00010b17          	auipc	s6,0x10
ffffffffc02016c6:	ed6b0b13          	addi	s6,s6,-298 # ffffffffc0211598 <check_mm_struct>
ffffffffc02016ca:	a805                	j	ffffffffc02016fa <alloc_pages+0x6c>
            page = pmm_manager->alloc_pages(n);
ffffffffc02016cc:	00093783          	ld	a5,0(s2)
ffffffffc02016d0:	6f9c                	ld	a5,24(a5)
ffffffffc02016d2:	9782                	jalr	a5
ffffffffc02016d4:	84aa                	mv	s1,a0
        cprintf("page %x, call swap_out in alloc_pages %d\n", page, n);
ffffffffc02016d6:	8622                	mv	a2,s0
ffffffffc02016d8:	4581                	li	a1,0
ffffffffc02016da:	854e                	mv	a0,s3
        if (page != NULL || n > 1 || swap_init_ok == 0)
ffffffffc02016dc:	e0b1                	bnez	s1,ffffffffc0201720 <alloc_pages+0x92>
ffffffffc02016de:	048a6163          	bltu	s4,s0,ffffffffc0201720 <alloc_pages+0x92>
ffffffffc02016e2:	000aa783          	lw	a5,0(s5)
ffffffffc02016e6:	2781                	sext.w	a5,a5
ffffffffc02016e8:	cf85                	beqz	a5,ffffffffc0201720 <alloc_pages+0x92>
        cprintf("page %x, call swap_out in alloc_pages %d\n", page, n);
ffffffffc02016ea:	9d5fe0ef          	jal	ra,ffffffffc02000be <cprintf>
        swap_out(check_mm_struct, n, 0);
ffffffffc02016ee:	000b3503          	ld	a0,0(s6)
ffffffffc02016f2:	4601                	li	a2,0
ffffffffc02016f4:	85de                	mv	a1,s7
ffffffffc02016f6:	04f010ef          	jal	ra,ffffffffc0202f44 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016fa:	100027f3          	csrr	a5,sstatus
ffffffffc02016fe:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0201700:	8522                	mv	a0,s0
ffffffffc0201702:	d7e9                	beqz	a5,ffffffffc02016cc <alloc_pages+0x3e>
        intr_disable();
ffffffffc0201704:	df7fe0ef          	jal	ra,ffffffffc02004fa <intr_disable>
ffffffffc0201708:	00093783          	ld	a5,0(s2)
ffffffffc020170c:	8522                	mv	a0,s0
ffffffffc020170e:	6f9c                	ld	a5,24(a5)
ffffffffc0201710:	9782                	jalr	a5
ffffffffc0201712:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201714:	de1fe0ef          	jal	ra,ffffffffc02004f4 <intr_enable>
        cprintf("page %x, call swap_out in alloc_pages %d\n", page, n);
ffffffffc0201718:	8622                	mv	a2,s0
ffffffffc020171a:	4581                	li	a1,0
ffffffffc020171c:	854e                	mv	a0,s3
        if (page != NULL || n > 1 || swap_init_ok == 0)
ffffffffc020171e:	d0e1                	beqz	s1,ffffffffc02016de <alloc_pages+0x50>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0201720:	60a6                	ld	ra,72(sp)
ffffffffc0201722:	6406                	ld	s0,64(sp)
ffffffffc0201724:	8526                	mv	a0,s1
ffffffffc0201726:	7942                	ld	s2,48(sp)
ffffffffc0201728:	74e2                	ld	s1,56(sp)
ffffffffc020172a:	79a2                	ld	s3,40(sp)
ffffffffc020172c:	7a02                	ld	s4,32(sp)
ffffffffc020172e:	6ae2                	ld	s5,24(sp)
ffffffffc0201730:	6b42                	ld	s6,16(sp)
ffffffffc0201732:	6ba2                	ld	s7,8(sp)
ffffffffc0201734:	6161                	addi	sp,sp,80
ffffffffc0201736:	8082                	ret

ffffffffc0201738 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201738:	100027f3          	csrr	a5,sstatus
ffffffffc020173c:	8b89                	andi	a5,a5,2
ffffffffc020173e:	eb89                	bnez	a5,ffffffffc0201750 <free_pages+0x18>
{
    bool intr_flag;

    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201740:	00010797          	auipc	a5,0x10
ffffffffc0201744:	d5878793          	addi	a5,a5,-680 # ffffffffc0211498 <pmm_manager>
ffffffffc0201748:	639c                	ld	a5,0(a5)
ffffffffc020174a:	0207b303          	ld	t1,32(a5)
ffffffffc020174e:	8302                	jr	t1
{
ffffffffc0201750:	1101                	addi	sp,sp,-32
ffffffffc0201752:	ec06                	sd	ra,24(sp)
ffffffffc0201754:	e822                	sd	s0,16(sp)
ffffffffc0201756:	e426                	sd	s1,8(sp)
ffffffffc0201758:	842a                	mv	s0,a0
ffffffffc020175a:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020175c:	d9ffe0ef          	jal	ra,ffffffffc02004fa <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201760:	00010797          	auipc	a5,0x10
ffffffffc0201764:	d3878793          	addi	a5,a5,-712 # ffffffffc0211498 <pmm_manager>
ffffffffc0201768:	639c                	ld	a5,0(a5)
ffffffffc020176a:	85a6                	mv	a1,s1
ffffffffc020176c:	8522                	mv	a0,s0
ffffffffc020176e:	739c                	ld	a5,32(a5)
ffffffffc0201770:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201772:	6442                	ld	s0,16(sp)
ffffffffc0201774:	60e2                	ld	ra,24(sp)
ffffffffc0201776:	64a2                	ld	s1,8(sp)
ffffffffc0201778:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020177a:	d7bfe06f          	j	ffffffffc02004f4 <intr_enable>

ffffffffc020177e <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020177e:	100027f3          	csrr	a5,sstatus
ffffffffc0201782:	8b89                	andi	a5,a5,2
ffffffffc0201784:	eb89                	bnez	a5,ffffffffc0201796 <nr_free_pages+0x18>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201786:	00010797          	auipc	a5,0x10
ffffffffc020178a:	d1278793          	addi	a5,a5,-750 # ffffffffc0211498 <pmm_manager>
ffffffffc020178e:	639c                	ld	a5,0(a5)
ffffffffc0201790:	0287b303          	ld	t1,40(a5)
ffffffffc0201794:	8302                	jr	t1
{
ffffffffc0201796:	1141                	addi	sp,sp,-16
ffffffffc0201798:	e406                	sd	ra,8(sp)
ffffffffc020179a:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020179c:	d5ffe0ef          	jal	ra,ffffffffc02004fa <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02017a0:	00010797          	auipc	a5,0x10
ffffffffc02017a4:	cf878793          	addi	a5,a5,-776 # ffffffffc0211498 <pmm_manager>
ffffffffc02017a8:	639c                	ld	a5,0(a5)
ffffffffc02017aa:	779c                	ld	a5,40(a5)
ffffffffc02017ac:	9782                	jalr	a5
ffffffffc02017ae:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02017b0:	d45fe0ef          	jal	ra,ffffffffc02004f4 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02017b4:	8522                	mv	a0,s0
ffffffffc02017b6:	60a2                	ld	ra,8(sp)
ffffffffc02017b8:	6402                	ld	s0,0(sp)
ffffffffc02017ba:	0141                	addi	sp,sp,16
ffffffffc02017bc:	8082                	ret

ffffffffc02017be <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
ffffffffc02017be:	715d                	addi	sp,sp,-80
ffffffffc02017c0:	fc26                	sd	s1,56(sp)
     *   PTE_W           0x002                   // page table/directory entry
     * flags bit : Writeable
     *   PTE_U           0x004                   // page table/directory entry
     * flags bit : User can access
     */
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02017c2:	01e5d493          	srli	s1,a1,0x1e
ffffffffc02017c6:	1ff4f493          	andi	s1,s1,511
ffffffffc02017ca:	048e                	slli	s1,s1,0x3
ffffffffc02017cc:	94aa                	add	s1,s1,a0
    // &pgdir[PDX1(la)] 表示页目录表中索引为 PDX1(la) 的条目的地址

    if (!(*pdep1 & PTE_V)) // 如果该条目不存在（PTE_Valid信号为1）
ffffffffc02017ce:	6094                	ld	a3,0(s1)
{
ffffffffc02017d0:	f84a                	sd	s2,48(sp)
ffffffffc02017d2:	f44e                	sd	s3,40(sp)
ffffffffc02017d4:	f052                	sd	s4,32(sp)
ffffffffc02017d6:	e486                	sd	ra,72(sp)
ffffffffc02017d8:	e0a2                	sd	s0,64(sp)
ffffffffc02017da:	ec56                	sd	s5,24(sp)
ffffffffc02017dc:	e85a                	sd	s6,16(sp)
ffffffffc02017de:	e45e                	sd	s7,8(sp)
    if (!(*pdep1 & PTE_V)) // 如果该条目不存在（PTE_Valid信号为1）
ffffffffc02017e0:	0016f793          	andi	a5,a3,1
{
ffffffffc02017e4:	892e                	mv	s2,a1
ffffffffc02017e6:	8a32                	mv	s4,a2
ffffffffc02017e8:	00010997          	auipc	s3,0x10
ffffffffc02017ec:	c7898993          	addi	s3,s3,-904 # ffffffffc0211460 <npage>
    if (!(*pdep1 & PTE_V)) // 如果该条目不存在（PTE_Valid信号为1）
ffffffffc02017f0:	e3c9                	bnez	a5,ffffffffc0201872 <get_pte+0xb4>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) // 函数create参数为0表示不创建新的页目录项，或者不能再分配新的页
ffffffffc02017f2:	16060163          	beqz	a2,ffffffffc0201954 <get_pte+0x196>
ffffffffc02017f6:	4505                	li	a0,1
ffffffffc02017f8:	e97ff0ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc02017fc:	842a                	mv	s0,a0
ffffffffc02017fe:	14050b63          	beqz	a0,ffffffffc0201954 <get_pte+0x196>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201802:	00010b97          	auipc	s7,0x10
ffffffffc0201806:	caeb8b93          	addi	s7,s7,-850 # ffffffffc02114b0 <pages>
ffffffffc020180a:	000bb503          	ld	a0,0(s7)
ffffffffc020180e:	00003797          	auipc	a5,0x3
ffffffffc0201812:	4fa78793          	addi	a5,a5,1274 # ffffffffc0204d08 <commands+0x858>
ffffffffc0201816:	0007bb03          	ld	s6,0(a5)
ffffffffc020181a:	40a40533          	sub	a0,s0,a0
ffffffffc020181e:	850d                	srai	a0,a0,0x3
ffffffffc0201820:	03650533          	mul	a0,a0,s6
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201824:	4785                	li	a5,1
        {
            return NULL;
        }
        set_page_ref(page, 1);                              // 设置页面引用次数为1
        uintptr_t pa = page2pa(page);                       // 获取页面的物理地址
        memset(KADDR(pa), 0, PGSIZE);                       // 将页面清零
ffffffffc0201826:	00010997          	auipc	s3,0x10
ffffffffc020182a:	c3a98993          	addi	s3,s3,-966 # ffffffffc0211460 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020182e:	00080ab7          	lui	s5,0x80
ffffffffc0201832:	0009b703          	ld	a4,0(s3)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201836:	c01c                	sw	a5,0(s0)
ffffffffc0201838:	57fd                	li	a5,-1
ffffffffc020183a:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020183c:	9556                	add	a0,a0,s5
ffffffffc020183e:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201840:	0532                	slli	a0,a0,0xc
ffffffffc0201842:	16e7f063          	bleu	a4,a5,ffffffffc02019a2 <get_pte+0x1e4>
ffffffffc0201846:	00010797          	auipc	a5,0x10
ffffffffc020184a:	c5a78793          	addi	a5,a5,-934 # ffffffffc02114a0 <va_pa_offset>
ffffffffc020184e:	639c                	ld	a5,0(a5)
ffffffffc0201850:	6605                	lui	a2,0x1
ffffffffc0201852:	4581                	li	a1,0
ffffffffc0201854:	953e                	add	a0,a0,a5
ffffffffc0201856:	307020ef          	jal	ra,ffffffffc020435c <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020185a:	000bb683          	ld	a3,0(s7)
ffffffffc020185e:	40d406b3          	sub	a3,s0,a3
ffffffffc0201862:	868d                	srai	a3,a3,0x3
ffffffffc0201864:	036686b3          	mul	a3,a3,s6
ffffffffc0201868:	96d6                	add	a3,a3,s5

static inline void flush_tlb() { asm volatile("sfence.vma"); }

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020186a:	06aa                	slli	a3,a3,0xa
ffffffffc020186c:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); // 设置页目录项为新的页的物理地址
ffffffffc0201870:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201872:	77fd                	lui	a5,0xfffff
ffffffffc0201874:	068a                	slli	a3,a3,0x2
ffffffffc0201876:	0009b703          	ld	a4,0(s3)
ffffffffc020187a:	8efd                	and	a3,a3,a5
ffffffffc020187c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201880:	0ce7fc63          	bleu	a4,a5,ffffffffc0201958 <get_pte+0x19a>
ffffffffc0201884:	00010a97          	auipc	s5,0x10
ffffffffc0201888:	c1ca8a93          	addi	s5,s5,-996 # ffffffffc02114a0 <va_pa_offset>
ffffffffc020188c:	000ab403          	ld	s0,0(s5)
ffffffffc0201890:	01595793          	srli	a5,s2,0x15
ffffffffc0201894:	1ff7f793          	andi	a5,a5,511
ffffffffc0201898:	96a2                	add	a3,a3,s0
ffffffffc020189a:	00379413          	slli	s0,a5,0x3
ffffffffc020189e:	9436                	add	s0,s0,a3
    //    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V))
ffffffffc02018a0:	6014                	ld	a3,0(s0)
ffffffffc02018a2:	0016f793          	andi	a5,a3,1
ffffffffc02018a6:	ebbd                	bnez	a5,ffffffffc020191c <get_pte+0x15e>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02018a8:	0a0a0663          	beqz	s4,ffffffffc0201954 <get_pte+0x196>
ffffffffc02018ac:	4505                	li	a0,1
ffffffffc02018ae:	de1ff0ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc02018b2:	84aa                	mv	s1,a0
ffffffffc02018b4:	c145                	beqz	a0,ffffffffc0201954 <get_pte+0x196>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02018b6:	00010b97          	auipc	s7,0x10
ffffffffc02018ba:	bfab8b93          	addi	s7,s7,-1030 # ffffffffc02114b0 <pages>
ffffffffc02018be:	000bb503          	ld	a0,0(s7)
ffffffffc02018c2:	00003797          	auipc	a5,0x3
ffffffffc02018c6:	44678793          	addi	a5,a5,1094 # ffffffffc0204d08 <commands+0x858>
ffffffffc02018ca:	0007bb03          	ld	s6,0(a5)
ffffffffc02018ce:	40a48533          	sub	a0,s1,a0
ffffffffc02018d2:	850d                	srai	a0,a0,0x3
ffffffffc02018d4:	03650533          	mul	a0,a0,s6
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02018d8:	4785                	li	a5,1
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02018da:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02018de:	0009b703          	ld	a4,0(s3)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02018e2:	c09c                	sw	a5,0(s1)
ffffffffc02018e4:	57fd                	li	a5,-1
ffffffffc02018e6:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02018e8:	9552                	add	a0,a0,s4
ffffffffc02018ea:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02018ec:	0532                	slli	a0,a0,0xc
ffffffffc02018ee:	08e7fd63          	bleu	a4,a5,ffffffffc0201988 <get_pte+0x1ca>
ffffffffc02018f2:	000ab783          	ld	a5,0(s5)
ffffffffc02018f6:	6605                	lui	a2,0x1
ffffffffc02018f8:	4581                	li	a1,0
ffffffffc02018fa:	953e                	add	a0,a0,a5
ffffffffc02018fc:	261020ef          	jal	ra,ffffffffc020435c <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201900:	000bb683          	ld	a3,0(s7)
ffffffffc0201904:	40d486b3          	sub	a3,s1,a3
ffffffffc0201908:	868d                	srai	a3,a3,0x3
ffffffffc020190a:	036686b3          	mul	a3,a3,s6
ffffffffc020190e:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201910:	06aa                	slli	a3,a3,0xa
ffffffffc0201912:	0116e693          	ori	a3,a3,17
        //   	memset(pa, 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201916:	e014                	sd	a3,0(s0)
ffffffffc0201918:	0009b703          	ld	a4,0(s3)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020191c:	068a                	slli	a3,a3,0x2
ffffffffc020191e:	757d                	lui	a0,0xfffff
ffffffffc0201920:	8ee9                	and	a3,a3,a0
ffffffffc0201922:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201926:	04e7f563          	bleu	a4,a5,ffffffffc0201970 <get_pte+0x1b2>
ffffffffc020192a:	000ab503          	ld	a0,0(s5)
ffffffffc020192e:	00c95793          	srli	a5,s2,0xc
ffffffffc0201932:	1ff7f793          	andi	a5,a5,511
ffffffffc0201936:	96aa                	add	a3,a3,a0
ffffffffc0201938:	00379513          	slli	a0,a5,0x3
ffffffffc020193c:	9536                	add	a0,a0,a3
}
ffffffffc020193e:	60a6                	ld	ra,72(sp)
ffffffffc0201940:	6406                	ld	s0,64(sp)
ffffffffc0201942:	74e2                	ld	s1,56(sp)
ffffffffc0201944:	7942                	ld	s2,48(sp)
ffffffffc0201946:	79a2                	ld	s3,40(sp)
ffffffffc0201948:	7a02                	ld	s4,32(sp)
ffffffffc020194a:	6ae2                	ld	s5,24(sp)
ffffffffc020194c:	6b42                	ld	s6,16(sp)
ffffffffc020194e:	6ba2                	ld	s7,8(sp)
ffffffffc0201950:	6161                	addi	sp,sp,80
ffffffffc0201952:	8082                	ret
            return NULL;
ffffffffc0201954:	4501                	li	a0,0
ffffffffc0201956:	b7e5                	j	ffffffffc020193e <get_pte+0x180>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201958:	00003617          	auipc	a2,0x3
ffffffffc020195c:	7e060613          	addi	a2,a2,2016 # ffffffffc0205138 <default_pmm_manager+0x80>
ffffffffc0201960:	11f00593          	li	a1,287
ffffffffc0201964:	00003517          	auipc	a0,0x3
ffffffffc0201968:	7fc50513          	addi	a0,a0,2044 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc020196c:	a09fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201970:	00003617          	auipc	a2,0x3
ffffffffc0201974:	7c860613          	addi	a2,a2,1992 # ffffffffc0205138 <default_pmm_manager+0x80>
ffffffffc0201978:	12e00593          	li	a1,302
ffffffffc020197c:	00003517          	auipc	a0,0x3
ffffffffc0201980:	7e450513          	addi	a0,a0,2020 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0201984:	9f1fe0ef          	jal	ra,ffffffffc0200374 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201988:	86aa                	mv	a3,a0
ffffffffc020198a:	00003617          	auipc	a2,0x3
ffffffffc020198e:	7ae60613          	addi	a2,a2,1966 # ffffffffc0205138 <default_pmm_manager+0x80>
ffffffffc0201992:	12a00593          	li	a1,298
ffffffffc0201996:	00003517          	auipc	a0,0x3
ffffffffc020199a:	7ca50513          	addi	a0,a0,1994 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc020199e:	9d7fe0ef          	jal	ra,ffffffffc0200374 <__panic>
        memset(KADDR(pa), 0, PGSIZE);                       // 将页面清零
ffffffffc02019a2:	86aa                	mv	a3,a0
ffffffffc02019a4:	00003617          	auipc	a2,0x3
ffffffffc02019a8:	79460613          	addi	a2,a2,1940 # ffffffffc0205138 <default_pmm_manager+0x80>
ffffffffc02019ac:	11c00593          	li	a1,284
ffffffffc02019b0:	00003517          	auipc	a0,0x3
ffffffffc02019b4:	7b050513          	addi	a0,a0,1968 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02019b8:	9bdfe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02019bc <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02019bc:	1141                	addi	sp,sp,-16
ffffffffc02019be:	e022                	sd	s0,0(sp)
ffffffffc02019c0:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02019c2:	4601                	li	a2,0
{
ffffffffc02019c4:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02019c6:	df9ff0ef          	jal	ra,ffffffffc02017be <get_pte>
    if (ptep_store != NULL)
ffffffffc02019ca:	c011                	beqz	s0,ffffffffc02019ce <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02019cc:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02019ce:	c521                	beqz	a0,ffffffffc0201a16 <get_page+0x5a>
ffffffffc02019d0:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02019d2:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02019d4:	0017f713          	andi	a4,a5,1
ffffffffc02019d8:	e709                	bnez	a4,ffffffffc02019e2 <get_page+0x26>
}
ffffffffc02019da:	60a2                	ld	ra,8(sp)
ffffffffc02019dc:	6402                	ld	s0,0(sp)
ffffffffc02019de:	0141                	addi	sp,sp,16
ffffffffc02019e0:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc02019e2:	00010717          	auipc	a4,0x10
ffffffffc02019e6:	a7e70713          	addi	a4,a4,-1410 # ffffffffc0211460 <npage>
ffffffffc02019ea:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc02019ec:	078a                	slli	a5,a5,0x2
ffffffffc02019ee:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02019f0:	02e7f863          	bleu	a4,a5,ffffffffc0201a20 <get_page+0x64>
    return &pages[PPN(pa) - nbase];
ffffffffc02019f4:	fff80537          	lui	a0,0xfff80
ffffffffc02019f8:	97aa                	add	a5,a5,a0
ffffffffc02019fa:	00010697          	auipc	a3,0x10
ffffffffc02019fe:	ab668693          	addi	a3,a3,-1354 # ffffffffc02114b0 <pages>
ffffffffc0201a02:	6288                	ld	a0,0(a3)
ffffffffc0201a04:	60a2                	ld	ra,8(sp)
ffffffffc0201a06:	6402                	ld	s0,0(sp)
ffffffffc0201a08:	00379713          	slli	a4,a5,0x3
ffffffffc0201a0c:	97ba                	add	a5,a5,a4
ffffffffc0201a0e:	078e                	slli	a5,a5,0x3
ffffffffc0201a10:	953e                	add	a0,a0,a5
ffffffffc0201a12:	0141                	addi	sp,sp,16
ffffffffc0201a14:	8082                	ret
ffffffffc0201a16:	60a2                	ld	ra,8(sp)
ffffffffc0201a18:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc0201a1a:	4501                	li	a0,0
}
ffffffffc0201a1c:	0141                	addi	sp,sp,16
ffffffffc0201a1e:	8082                	ret
ffffffffc0201a20:	c53ff0ef          	jal	ra,ffffffffc0201672 <pa2page.part.4>

ffffffffc0201a24 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201a24:	1141                	addi	sp,sp,-16
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201a26:	4601                	li	a2,0
{
ffffffffc0201a28:	e406                	sd	ra,8(sp)
ffffffffc0201a2a:	e022                	sd	s0,0(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201a2c:	d93ff0ef          	jal	ra,ffffffffc02017be <get_pte>
    if (ptep != NULL)
ffffffffc0201a30:	c511                	beqz	a0,ffffffffc0201a3c <page_remove+0x18>
    if (*ptep & PTE_V)
ffffffffc0201a32:	611c                	ld	a5,0(a0)
ffffffffc0201a34:	842a                	mv	s0,a0
ffffffffc0201a36:	0017f713          	andi	a4,a5,1
ffffffffc0201a3a:	e709                	bnez	a4,ffffffffc0201a44 <page_remove+0x20>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201a3c:	60a2                	ld	ra,8(sp)
ffffffffc0201a3e:	6402                	ld	s0,0(sp)
ffffffffc0201a40:	0141                	addi	sp,sp,16
ffffffffc0201a42:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0201a44:	00010717          	auipc	a4,0x10
ffffffffc0201a48:	a1c70713          	addi	a4,a4,-1508 # ffffffffc0211460 <npage>
ffffffffc0201a4c:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201a4e:	078a                	slli	a5,a5,0x2
ffffffffc0201a50:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201a52:	04e7f063          	bleu	a4,a5,ffffffffc0201a92 <page_remove+0x6e>
    return &pages[PPN(pa) - nbase];
ffffffffc0201a56:	fff80737          	lui	a4,0xfff80
ffffffffc0201a5a:	97ba                	add	a5,a5,a4
ffffffffc0201a5c:	00010717          	auipc	a4,0x10
ffffffffc0201a60:	a5470713          	addi	a4,a4,-1452 # ffffffffc02114b0 <pages>
ffffffffc0201a64:	6308                	ld	a0,0(a4)
ffffffffc0201a66:	00379713          	slli	a4,a5,0x3
ffffffffc0201a6a:	97ba                	add	a5,a5,a4
ffffffffc0201a6c:	078e                	slli	a5,a5,0x3
ffffffffc0201a6e:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201a70:	411c                	lw	a5,0(a0)
ffffffffc0201a72:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201a76:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201a78:	cb09                	beqz	a4,ffffffffc0201a8a <page_remove+0x66>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0201a7a:	00043023          	sd	zero,0(s0)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201a7e:	12000073          	sfence.vma
}
ffffffffc0201a82:	60a2                	ld	ra,8(sp)
ffffffffc0201a84:	6402                	ld	s0,0(sp)
ffffffffc0201a86:	0141                	addi	sp,sp,16
ffffffffc0201a88:	8082                	ret
            free_page(page);
ffffffffc0201a8a:	4585                	li	a1,1
ffffffffc0201a8c:	cadff0ef          	jal	ra,ffffffffc0201738 <free_pages>
ffffffffc0201a90:	b7ed                	j	ffffffffc0201a7a <page_remove+0x56>
ffffffffc0201a92:	be1ff0ef          	jal	ra,ffffffffc0201672 <pa2page.part.4>

ffffffffc0201a96 <page_insert>:
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm)
{
ffffffffc0201a96:	7179                	addi	sp,sp,-48
ffffffffc0201a98:	87b2                	mv	a5,a2
ffffffffc0201a9a:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201a9c:	4605                	li	a2,1
{
ffffffffc0201a9e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201aa0:	85be                	mv	a1,a5
{
ffffffffc0201aa2:	ec26                	sd	s1,24(sp)
ffffffffc0201aa4:	f406                	sd	ra,40(sp)
ffffffffc0201aa6:	e84a                	sd	s2,16(sp)
ffffffffc0201aa8:	e44e                	sd	s3,8(sp)
ffffffffc0201aaa:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201aac:	d13ff0ef          	jal	ra,ffffffffc02017be <get_pte>
    if (ptep == NULL)
ffffffffc0201ab0:	c945                	beqz	a0,ffffffffc0201b60 <page_insert+0xca>
    page->ref += 1;
ffffffffc0201ab2:	4014                	lw	a3,0(s0)
    {
        return -E_NO_MEM;
    }
    page_ref_inc(page);
    if (*ptep & PTE_V)
ffffffffc0201ab4:	611c                	ld	a5,0(a0)
ffffffffc0201ab6:	892a                	mv	s2,a0
ffffffffc0201ab8:	0016871b          	addiw	a4,a3,1
ffffffffc0201abc:	c018                	sw	a4,0(s0)
ffffffffc0201abe:	0017f713          	andi	a4,a5,1
ffffffffc0201ac2:	e339                	bnez	a4,ffffffffc0201b08 <page_insert+0x72>
ffffffffc0201ac4:	00010797          	auipc	a5,0x10
ffffffffc0201ac8:	9ec78793          	addi	a5,a5,-1556 # ffffffffc02114b0 <pages>
ffffffffc0201acc:	639c                	ld	a5,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201ace:	00003717          	auipc	a4,0x3
ffffffffc0201ad2:	23a70713          	addi	a4,a4,570 # ffffffffc0204d08 <commands+0x858>
ffffffffc0201ad6:	40f407b3          	sub	a5,s0,a5
ffffffffc0201ada:	6300                	ld	s0,0(a4)
ffffffffc0201adc:	878d                	srai	a5,a5,0x3
ffffffffc0201ade:	000806b7          	lui	a3,0x80
ffffffffc0201ae2:	028787b3          	mul	a5,a5,s0
ffffffffc0201ae6:	97b6                	add	a5,a5,a3
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ae8:	07aa                	slli	a5,a5,0xa
ffffffffc0201aea:	8fc5                	or	a5,a5,s1
ffffffffc0201aec:	0017e793          	ori	a5,a5,1
        else
        {
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0201af0:	00f93023          	sd	a5,0(s2)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201af4:	12000073          	sfence.vma
    tlb_invalidate(pgdir, la);
    return 0;
ffffffffc0201af8:	4501                	li	a0,0
}
ffffffffc0201afa:	70a2                	ld	ra,40(sp)
ffffffffc0201afc:	7402                	ld	s0,32(sp)
ffffffffc0201afe:	64e2                	ld	s1,24(sp)
ffffffffc0201b00:	6942                	ld	s2,16(sp)
ffffffffc0201b02:	69a2                	ld	s3,8(sp)
ffffffffc0201b04:	6145                	addi	sp,sp,48
ffffffffc0201b06:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0201b08:	00010717          	auipc	a4,0x10
ffffffffc0201b0c:	95870713          	addi	a4,a4,-1704 # ffffffffc0211460 <npage>
ffffffffc0201b10:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201b12:	00279513          	slli	a0,a5,0x2
ffffffffc0201b16:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201b18:	04e57663          	bleu	a4,a0,ffffffffc0201b64 <page_insert+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b1c:	fff807b7          	lui	a5,0xfff80
ffffffffc0201b20:	953e                	add	a0,a0,a5
ffffffffc0201b22:	00010997          	auipc	s3,0x10
ffffffffc0201b26:	98e98993          	addi	s3,s3,-1650 # ffffffffc02114b0 <pages>
ffffffffc0201b2a:	0009b783          	ld	a5,0(s3)
ffffffffc0201b2e:	00351713          	slli	a4,a0,0x3
ffffffffc0201b32:	953a                	add	a0,a0,a4
ffffffffc0201b34:	050e                	slli	a0,a0,0x3
ffffffffc0201b36:	953e                	add	a0,a0,a5
        if (p == page)
ffffffffc0201b38:	00a40e63          	beq	s0,a0,ffffffffc0201b54 <page_insert+0xbe>
    page->ref -= 1;
ffffffffc0201b3c:	411c                	lw	a5,0(a0)
ffffffffc0201b3e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201b42:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201b44:	cb11                	beqz	a4,ffffffffc0201b58 <page_insert+0xc2>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0201b46:	00093023          	sd	zero,0(s2)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201b4a:	12000073          	sfence.vma
ffffffffc0201b4e:	0009b783          	ld	a5,0(s3)
ffffffffc0201b52:	bfb5                	j	ffffffffc0201ace <page_insert+0x38>
    page->ref -= 1;
ffffffffc0201b54:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201b56:	bfa5                	j	ffffffffc0201ace <page_insert+0x38>
            free_page(page);
ffffffffc0201b58:	4585                	li	a1,1
ffffffffc0201b5a:	bdfff0ef          	jal	ra,ffffffffc0201738 <free_pages>
ffffffffc0201b5e:	b7e5                	j	ffffffffc0201b46 <page_insert+0xb0>
        return -E_NO_MEM;
ffffffffc0201b60:	5571                	li	a0,-4
ffffffffc0201b62:	bf61                	j	ffffffffc0201afa <page_insert+0x64>
ffffffffc0201b64:	b0fff0ef          	jal	ra,ffffffffc0201672 <pa2page.part.4>

ffffffffc0201b68 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201b68:	00003797          	auipc	a5,0x3
ffffffffc0201b6c:	55078793          	addi	a5,a5,1360 # ffffffffc02050b8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b70:	638c                	ld	a1,0(a5)
{
ffffffffc0201b72:	711d                	addi	sp,sp,-96
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b74:	00003517          	auipc	a0,0x3
ffffffffc0201b78:	68450513          	addi	a0,a0,1668 # ffffffffc02051f8 <default_pmm_manager+0x140>
{
ffffffffc0201b7c:	ec86                	sd	ra,88(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201b7e:	00010717          	auipc	a4,0x10
ffffffffc0201b82:	90f73d23          	sd	a5,-1766(a4) # ffffffffc0211498 <pmm_manager>
{
ffffffffc0201b86:	e8a2                	sd	s0,80(sp)
ffffffffc0201b88:	e4a6                	sd	s1,72(sp)
ffffffffc0201b8a:	e0ca                	sd	s2,64(sp)
ffffffffc0201b8c:	fc4e                	sd	s3,56(sp)
ffffffffc0201b8e:	f852                	sd	s4,48(sp)
ffffffffc0201b90:	f456                	sd	s5,40(sp)
ffffffffc0201b92:	f05a                	sd	s6,32(sp)
ffffffffc0201b94:	ec5e                	sd	s7,24(sp)
ffffffffc0201b96:	e862                	sd	s8,16(sp)
ffffffffc0201b98:	e466                	sd	s9,8(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201b9a:	00010417          	auipc	s0,0x10
ffffffffc0201b9e:	8fe40413          	addi	s0,s0,-1794 # ffffffffc0211498 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201ba2:	d1cfe0ef          	jal	ra,ffffffffc02000be <cprintf>
    pmm_manager->init();
ffffffffc0201ba6:	601c                	ld	a5,0(s0)
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size);
ffffffffc0201ba8:	49c5                	li	s3,17
ffffffffc0201baa:	40100a13          	li	s4,1025
    pmm_manager->init();
ffffffffc0201bae:	679c                	ld	a5,8(a5)
ffffffffc0201bb0:	00010497          	auipc	s1,0x10
ffffffffc0201bb4:	8b048493          	addi	s1,s1,-1872 # ffffffffc0211460 <npage>
ffffffffc0201bb8:	00010917          	auipc	s2,0x10
ffffffffc0201bbc:	8f890913          	addi	s2,s2,-1800 # ffffffffc02114b0 <pages>
ffffffffc0201bc0:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201bc2:	57f5                	li	a5,-3
ffffffffc0201bc4:	07fa                	slli	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size);
ffffffffc0201bc6:	07e006b7          	lui	a3,0x7e00
ffffffffc0201bca:	01b99613          	slli	a2,s3,0x1b
ffffffffc0201bce:	015a1593          	slli	a1,s4,0x15
ffffffffc0201bd2:	00003517          	auipc	a0,0x3
ffffffffc0201bd6:	63e50513          	addi	a0,a0,1598 # ffffffffc0205210 <default_pmm_manager+0x158>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201bda:	00010717          	auipc	a4,0x10
ffffffffc0201bde:	8cf73323          	sd	a5,-1850(a4) # ffffffffc02114a0 <va_pa_offset>
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size);
ffffffffc0201be2:	cdcfe0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("physcial memory map:\n");
ffffffffc0201be6:	00003517          	auipc	a0,0x3
ffffffffc0201bea:	65a50513          	addi	a0,a0,1626 # ffffffffc0205240 <default_pmm_manager+0x188>
ffffffffc0201bee:	cd0fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201bf2:	01b99693          	slli	a3,s3,0x1b
ffffffffc0201bf6:	16fd                	addi	a3,a3,-1
ffffffffc0201bf8:	015a1613          	slli	a2,s4,0x15
ffffffffc0201bfc:	07e005b7          	lui	a1,0x7e00
ffffffffc0201c00:	00003517          	auipc	a0,0x3
ffffffffc0201c04:	65850513          	addi	a0,a0,1624 # ffffffffc0205258 <default_pmm_manager+0x1a0>
ffffffffc0201c08:	cb6fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201c0c:	777d                	lui	a4,0xfffff
ffffffffc0201c0e:	00011797          	auipc	a5,0x11
ffffffffc0201c12:	99178793          	addi	a5,a5,-1647 # ffffffffc021259f <end+0xfff>
ffffffffc0201c16:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201c18:	00088737          	lui	a4,0x88
ffffffffc0201c1c:	00010697          	auipc	a3,0x10
ffffffffc0201c20:	84e6b223          	sd	a4,-1980(a3) # ffffffffc0211460 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201c24:	00010717          	auipc	a4,0x10
ffffffffc0201c28:	88f73623          	sd	a5,-1908(a4) # ffffffffc02114b0 <pages>
ffffffffc0201c2c:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201c2e:	4701                	li	a4,0
ffffffffc0201c30:	4585                	li	a1,1
ffffffffc0201c32:	fff80637          	lui	a2,0xfff80
ffffffffc0201c36:	a019                	j	ffffffffc0201c3c <pmm_init+0xd4>
ffffffffc0201c38:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc0201c3c:	97b6                	add	a5,a5,a3
ffffffffc0201c3e:	07a1                	addi	a5,a5,8
ffffffffc0201c40:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0201c44:	609c                	ld	a5,0(s1)
ffffffffc0201c46:	0705                	addi	a4,a4,1
ffffffffc0201c48:	04868693          	addi	a3,a3,72
ffffffffc0201c4c:	00c78533          	add	a0,a5,a2
ffffffffc0201c50:	fea764e3          	bltu	a4,a0,ffffffffc0201c38 <pmm_init+0xd0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201c54:	00093503          	ld	a0,0(s2)
ffffffffc0201c58:	00379693          	slli	a3,a5,0x3
ffffffffc0201c5c:	96be                	add	a3,a3,a5
ffffffffc0201c5e:	fdc00737          	lui	a4,0xfdc00
ffffffffc0201c62:	972a                	add	a4,a4,a0
ffffffffc0201c64:	068e                	slli	a3,a3,0x3
ffffffffc0201c66:	96ba                	add	a3,a3,a4
ffffffffc0201c68:	c0200737          	lui	a4,0xc0200
ffffffffc0201c6c:	58e6ea63          	bltu	a3,a4,ffffffffc0202200 <pmm_init+0x698>
ffffffffc0201c70:	00010997          	auipc	s3,0x10
ffffffffc0201c74:	83098993          	addi	s3,s3,-2000 # ffffffffc02114a0 <va_pa_offset>
ffffffffc0201c78:	0009b703          	ld	a4,0(s3)
    if (freemem < mem_end)
ffffffffc0201c7c:	45c5                	li	a1,17
ffffffffc0201c7e:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201c80:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end)
ffffffffc0201c82:	44b6ef63          	bltu	a3,a1,ffffffffc02020e0 <pmm_init+0x578>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0201c86:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t *)boot_page_table_sv39;
ffffffffc0201c88:	0000f417          	auipc	s0,0xf
ffffffffc0201c8c:	7d040413          	addi	s0,s0,2000 # ffffffffc0211458 <boot_pgdir>
    pmm_manager->check();
ffffffffc0201c90:	7b9c                	ld	a5,48(a5)
ffffffffc0201c92:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201c94:	00003517          	auipc	a0,0x3
ffffffffc0201c98:	61450513          	addi	a0,a0,1556 # ffffffffc02052a8 <default_pmm_manager+0x1f0>
ffffffffc0201c9c:	c22fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    boot_pgdir = (pte_t *)boot_page_table_sv39;
ffffffffc0201ca0:	00007697          	auipc	a3,0x7
ffffffffc0201ca4:	36068693          	addi	a3,a3,864 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc0201ca8:	0000f797          	auipc	a5,0xf
ffffffffc0201cac:	7ad7b823          	sd	a3,1968(a5) # ffffffffc0211458 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201cb0:	c02007b7          	lui	a5,0xc0200
ffffffffc0201cb4:	0ef6ece3          	bltu	a3,a5,ffffffffc02025ac <pmm_init+0xa44>
ffffffffc0201cb8:	0009b783          	ld	a5,0(s3)
ffffffffc0201cbc:	8e9d                	sub	a3,a3,a5
ffffffffc0201cbe:	0000f797          	auipc	a5,0xf
ffffffffc0201cc2:	7ed7b523          	sd	a3,2026(a5) # ffffffffc02114a8 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();
ffffffffc0201cc6:	ab9ff0ef          	jal	ra,ffffffffc020177e <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201cca:	6098                	ld	a4,0(s1)
ffffffffc0201ccc:	c80007b7          	lui	a5,0xc8000
ffffffffc0201cd0:	83b1                	srli	a5,a5,0xc
    nr_free_store = nr_free_pages();
ffffffffc0201cd2:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201cd4:	0ae7ece3          	bltu	a5,a4,ffffffffc020258c <pmm_init+0xa24>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201cd8:	6008                	ld	a0,0(s0)
ffffffffc0201cda:	4c050363          	beqz	a0,ffffffffc02021a0 <pmm_init+0x638>
ffffffffc0201cde:	6785                	lui	a5,0x1
ffffffffc0201ce0:	17fd                	addi	a5,a5,-1
ffffffffc0201ce2:	8fe9                	and	a5,a5,a0
ffffffffc0201ce4:	2781                	sext.w	a5,a5
ffffffffc0201ce6:	4a079d63          	bnez	a5,ffffffffc02021a0 <pmm_init+0x638>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201cea:	4601                	li	a2,0
ffffffffc0201cec:	4581                	li	a1,0
ffffffffc0201cee:	ccfff0ef          	jal	ra,ffffffffc02019bc <get_page>
ffffffffc0201cf2:	4c051763          	bnez	a0,ffffffffc02021c0 <pmm_init+0x658>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0201cf6:	4505                	li	a0,1
ffffffffc0201cf8:	997ff0ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0201cfc:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201cfe:	6008                	ld	a0,0(s0)
ffffffffc0201d00:	4681                	li	a3,0
ffffffffc0201d02:	4601                	li	a2,0
ffffffffc0201d04:	85d6                	mv	a1,s5
ffffffffc0201d06:	d91ff0ef          	jal	ra,ffffffffc0201a96 <page_insert>
ffffffffc0201d0a:	52051763          	bnez	a0,ffffffffc0202238 <pmm_init+0x6d0>
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201d0e:	6008                	ld	a0,0(s0)
ffffffffc0201d10:	4601                	li	a2,0
ffffffffc0201d12:	4581                	li	a1,0
ffffffffc0201d14:	aabff0ef          	jal	ra,ffffffffc02017be <get_pte>
ffffffffc0201d18:	50050063          	beqz	a0,ffffffffc0202218 <pmm_init+0x6b0>
    assert(pte2page(*ptep) == p1);
ffffffffc0201d1c:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201d1e:	0017f713          	andi	a4,a5,1
ffffffffc0201d22:	46070363          	beqz	a4,ffffffffc0202188 <pmm_init+0x620>
    if (PPN(pa) >= npage) {
ffffffffc0201d26:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201d28:	078a                	slli	a5,a5,0x2
ffffffffc0201d2a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201d2c:	44c7f063          	bleu	a2,a5,ffffffffc020216c <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d30:	fff80737          	lui	a4,0xfff80
ffffffffc0201d34:	97ba                	add	a5,a5,a4
ffffffffc0201d36:	00379713          	slli	a4,a5,0x3
ffffffffc0201d3a:	00093683          	ld	a3,0(s2)
ffffffffc0201d3e:	97ba                	add	a5,a5,a4
ffffffffc0201d40:	078e                	slli	a5,a5,0x3
ffffffffc0201d42:	97b6                	add	a5,a5,a3
ffffffffc0201d44:	5efa9463          	bne	s5,a5,ffffffffc020232c <pmm_init+0x7c4>
    assert(page_ref(p1) == 1);
ffffffffc0201d48:	000aab83          	lw	s7,0(s5)
ffffffffc0201d4c:	4785                	li	a5,1
ffffffffc0201d4e:	5afb9f63          	bne	s7,a5,ffffffffc020230c <pmm_init+0x7a4>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201d52:	6008                	ld	a0,0(s0)
ffffffffc0201d54:	76fd                	lui	a3,0xfffff
ffffffffc0201d56:	611c                	ld	a5,0(a0)
ffffffffc0201d58:	078a                	slli	a5,a5,0x2
ffffffffc0201d5a:	8ff5                	and	a5,a5,a3
ffffffffc0201d5c:	00c7d713          	srli	a4,a5,0xc
ffffffffc0201d60:	58c77963          	bleu	a2,a4,ffffffffc02022f2 <pmm_init+0x78a>
ffffffffc0201d64:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d68:	97e2                	add	a5,a5,s8
ffffffffc0201d6a:	0007bb03          	ld	s6,0(a5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc0201d6e:	0b0a                	slli	s6,s6,0x2
ffffffffc0201d70:	00db7b33          	and	s6,s6,a3
ffffffffc0201d74:	00cb5793          	srli	a5,s6,0xc
ffffffffc0201d78:	56c7f063          	bleu	a2,a5,ffffffffc02022d8 <pmm_init+0x770>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d7c:	4601                	li	a2,0
ffffffffc0201d7e:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d80:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d82:	a3dff0ef          	jal	ra,ffffffffc02017be <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d86:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d88:	53651863          	bne	a0,s6,ffffffffc02022b8 <pmm_init+0x750>

    p2 = alloc_page();
ffffffffc0201d8c:	4505                	li	a0,1
ffffffffc0201d8e:	901ff0ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0201d92:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201d94:	6008                	ld	a0,0(s0)
ffffffffc0201d96:	46d1                	li	a3,20
ffffffffc0201d98:	6605                	lui	a2,0x1
ffffffffc0201d9a:	85da                	mv	a1,s6
ffffffffc0201d9c:	cfbff0ef          	jal	ra,ffffffffc0201a96 <page_insert>
ffffffffc0201da0:	4e051c63          	bnez	a0,ffffffffc0202298 <pmm_init+0x730>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201da4:	6008                	ld	a0,0(s0)
ffffffffc0201da6:	4601                	li	a2,0
ffffffffc0201da8:	6585                	lui	a1,0x1
ffffffffc0201daa:	a15ff0ef          	jal	ra,ffffffffc02017be <get_pte>
ffffffffc0201dae:	4c050563          	beqz	a0,ffffffffc0202278 <pmm_init+0x710>
    assert(*ptep & PTE_U);
ffffffffc0201db2:	611c                	ld	a5,0(a0)
ffffffffc0201db4:	0107f713          	andi	a4,a5,16
ffffffffc0201db8:	4a070063          	beqz	a4,ffffffffc0202258 <pmm_init+0x6f0>
    assert(*ptep & PTE_W);
ffffffffc0201dbc:	8b91                	andi	a5,a5,4
ffffffffc0201dbe:	66078763          	beqz	a5,ffffffffc020242c <pmm_init+0x8c4>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201dc2:	6008                	ld	a0,0(s0)
ffffffffc0201dc4:	611c                	ld	a5,0(a0)
ffffffffc0201dc6:	8bc1                	andi	a5,a5,16
ffffffffc0201dc8:	64078263          	beqz	a5,ffffffffc020240c <pmm_init+0x8a4>
    assert(page_ref(p2) == 1);
ffffffffc0201dcc:	000b2783          	lw	a5,0(s6)
ffffffffc0201dd0:	61779e63          	bne	a5,s7,ffffffffc02023ec <pmm_init+0x884>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201dd4:	4681                	li	a3,0
ffffffffc0201dd6:	6605                	lui	a2,0x1
ffffffffc0201dd8:	85d6                	mv	a1,s5
ffffffffc0201dda:	cbdff0ef          	jal	ra,ffffffffc0201a96 <page_insert>
ffffffffc0201dde:	5e051763          	bnez	a0,ffffffffc02023cc <pmm_init+0x864>
    assert(page_ref(p1) == 2);
ffffffffc0201de2:	000aa703          	lw	a4,0(s5)
ffffffffc0201de6:	4789                	li	a5,2
ffffffffc0201de8:	5cf71263          	bne	a4,a5,ffffffffc02023ac <pmm_init+0x844>
    assert(page_ref(p2) == 0);
ffffffffc0201dec:	000b2783          	lw	a5,0(s6)
ffffffffc0201df0:	58079e63          	bnez	a5,ffffffffc020238c <pmm_init+0x824>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201df4:	6008                	ld	a0,0(s0)
ffffffffc0201df6:	4601                	li	a2,0
ffffffffc0201df8:	6585                	lui	a1,0x1
ffffffffc0201dfa:	9c5ff0ef          	jal	ra,ffffffffc02017be <get_pte>
ffffffffc0201dfe:	56050763          	beqz	a0,ffffffffc020236c <pmm_init+0x804>
    assert(pte2page(*ptep) == p1);
ffffffffc0201e02:	6114                	ld	a3,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201e04:	0016f793          	andi	a5,a3,1
ffffffffc0201e08:	38078063          	beqz	a5,ffffffffc0202188 <pmm_init+0x620>
    if (PPN(pa) >= npage) {
ffffffffc0201e0c:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201e0e:	00269793          	slli	a5,a3,0x2
ffffffffc0201e12:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201e14:	34e7fc63          	bleu	a4,a5,ffffffffc020216c <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e18:	fff80737          	lui	a4,0xfff80
ffffffffc0201e1c:	97ba                	add	a5,a5,a4
ffffffffc0201e1e:	00379713          	slli	a4,a5,0x3
ffffffffc0201e22:	00093603          	ld	a2,0(s2)
ffffffffc0201e26:	97ba                	add	a5,a5,a4
ffffffffc0201e28:	078e                	slli	a5,a5,0x3
ffffffffc0201e2a:	97b2                	add	a5,a5,a2
ffffffffc0201e2c:	52fa9063          	bne	s5,a5,ffffffffc020234c <pmm_init+0x7e4>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201e30:	8ac1                	andi	a3,a3,16
ffffffffc0201e32:	6e069d63          	bnez	a3,ffffffffc020252c <pmm_init+0x9c4>

    page_remove(boot_pgdir, 0x0);
ffffffffc0201e36:	6008                	ld	a0,0(s0)
ffffffffc0201e38:	4581                	li	a1,0
ffffffffc0201e3a:	bebff0ef          	jal	ra,ffffffffc0201a24 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201e3e:	000aa703          	lw	a4,0(s5)
ffffffffc0201e42:	4785                	li	a5,1
ffffffffc0201e44:	6cf71463          	bne	a4,a5,ffffffffc020250c <pmm_init+0x9a4>
    assert(page_ref(p2) == 0);
ffffffffc0201e48:	000b2783          	lw	a5,0(s6)
ffffffffc0201e4c:	6a079063          	bnez	a5,ffffffffc02024ec <pmm_init+0x984>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0201e50:	6008                	ld	a0,0(s0)
ffffffffc0201e52:	6585                	lui	a1,0x1
ffffffffc0201e54:	bd1ff0ef          	jal	ra,ffffffffc0201a24 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201e58:	000aa783          	lw	a5,0(s5)
ffffffffc0201e5c:	66079863          	bnez	a5,ffffffffc02024cc <pmm_init+0x964>
    assert(page_ref(p2) == 0);
ffffffffc0201e60:	000b2783          	lw	a5,0(s6)
ffffffffc0201e64:	70079463          	bnez	a5,ffffffffc020256c <pmm_init+0xa04>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201e68:	00043b03          	ld	s6,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0201e6c:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e6e:	000b3783          	ld	a5,0(s6)
ffffffffc0201e72:	078a                	slli	a5,a5,0x2
ffffffffc0201e74:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201e76:	2eb7fb63          	bleu	a1,a5,ffffffffc020216c <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e7a:	fff80737          	lui	a4,0xfff80
ffffffffc0201e7e:	973e                	add	a4,a4,a5
ffffffffc0201e80:	00371793          	slli	a5,a4,0x3
ffffffffc0201e84:	00093603          	ld	a2,0(s2)
ffffffffc0201e88:	97ba                	add	a5,a5,a4
ffffffffc0201e8a:	078e                	slli	a5,a5,0x3
ffffffffc0201e8c:	00f60733          	add	a4,a2,a5
ffffffffc0201e90:	4314                	lw	a3,0(a4)
ffffffffc0201e92:	4705                	li	a4,1
ffffffffc0201e94:	6ae69c63          	bne	a3,a4,ffffffffc020254c <pmm_init+0x9e4>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201e98:	00003a97          	auipc	s5,0x3
ffffffffc0201e9c:	e70a8a93          	addi	s5,s5,-400 # ffffffffc0204d08 <commands+0x858>
ffffffffc0201ea0:	000ab703          	ld	a4,0(s5)
ffffffffc0201ea4:	4037d693          	srai	a3,a5,0x3
ffffffffc0201ea8:	00080bb7          	lui	s7,0x80
ffffffffc0201eac:	02e686b3          	mul	a3,a3,a4
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201eb0:	577d                	li	a4,-1
ffffffffc0201eb2:	8331                	srli	a4,a4,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201eb4:	96de                	add	a3,a3,s7
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201eb6:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201eb8:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201eba:	2ab77b63          	bleu	a1,a4,ffffffffc0202170 <pmm_init+0x608>

    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201ebe:	0009b783          	ld	a5,0(s3)
ffffffffc0201ec2:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201ec4:	629c                	ld	a5,0(a3)
ffffffffc0201ec6:	078a                	slli	a5,a5,0x2
ffffffffc0201ec8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201eca:	2ab7f163          	bleu	a1,a5,ffffffffc020216c <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ece:	417787b3          	sub	a5,a5,s7
ffffffffc0201ed2:	00379513          	slli	a0,a5,0x3
ffffffffc0201ed6:	97aa                	add	a5,a5,a0
ffffffffc0201ed8:	00379513          	slli	a0,a5,0x3
ffffffffc0201edc:	9532                	add	a0,a0,a2
ffffffffc0201ede:	4585                	li	a1,1
ffffffffc0201ee0:	859ff0ef          	jal	ra,ffffffffc0201738 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201ee4:	000b3503          	ld	a0,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0201ee8:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201eea:	050a                	slli	a0,a0,0x2
ffffffffc0201eec:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201eee:	26f57f63          	bleu	a5,a0,ffffffffc020216c <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ef2:	417507b3          	sub	a5,a0,s7
ffffffffc0201ef6:	00379513          	slli	a0,a5,0x3
ffffffffc0201efa:	00093703          	ld	a4,0(s2)
ffffffffc0201efe:	953e                	add	a0,a0,a5
ffffffffc0201f00:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc0201f02:	4585                	li	a1,1
ffffffffc0201f04:	953a                	add	a0,a0,a4
ffffffffc0201f06:	833ff0ef          	jal	ra,ffffffffc0201738 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0201f0a:	601c                	ld	a5,0(s0)
ffffffffc0201f0c:	0007b023          	sd	zero,0(a5)

    assert(nr_free_store == nr_free_pages());
ffffffffc0201f10:	86fff0ef          	jal	ra,ffffffffc020177e <nr_free_pages>
ffffffffc0201f14:	2caa1663          	bne	s4,a0,ffffffffc02021e0 <pmm_init+0x678>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201f18:	00003517          	auipc	a0,0x3
ffffffffc0201f1c:	6a850513          	addi	a0,a0,1704 # ffffffffc02055c0 <default_pmm_manager+0x508>
ffffffffc0201f20:	99efe0ef          	jal	ra,ffffffffc02000be <cprintf>
{
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();
ffffffffc0201f24:	85bff0ef          	jal	ra,ffffffffc020177e <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201f28:	6098                	ld	a4,0(s1)
ffffffffc0201f2a:	c02007b7          	lui	a5,0xc0200
    nr_free_store = nr_free_pages();
ffffffffc0201f2e:	8b2a                	mv	s6,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201f30:	00c71693          	slli	a3,a4,0xc
ffffffffc0201f34:	1cd7fd63          	bleu	a3,a5,ffffffffc020210e <pmm_init+0x5a6>
    {
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201f38:	83b1                	srli	a5,a5,0xc
ffffffffc0201f3a:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201f3c:	c0200a37          	lui	s4,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201f40:	1ce7f963          	bleu	a4,a5,ffffffffc0202112 <pmm_init+0x5aa>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201f44:	7c7d                	lui	s8,0xfffff
ffffffffc0201f46:	6b85                	lui	s7,0x1
ffffffffc0201f48:	a029                	j	ffffffffc0201f52 <pmm_init+0x3ea>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201f4a:	00ca5713          	srli	a4,s4,0xc
ffffffffc0201f4e:	1cf77263          	bleu	a5,a4,ffffffffc0202112 <pmm_init+0x5aa>
ffffffffc0201f52:	0009b583          	ld	a1,0(s3)
ffffffffc0201f56:	4601                	li	a2,0
ffffffffc0201f58:	95d2                	add	a1,a1,s4
ffffffffc0201f5a:	865ff0ef          	jal	ra,ffffffffc02017be <get_pte>
ffffffffc0201f5e:	1c050763          	beqz	a0,ffffffffc020212c <pmm_init+0x5c4>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201f62:	611c                	ld	a5,0(a0)
ffffffffc0201f64:	078a                	slli	a5,a5,0x2
ffffffffc0201f66:	0187f7b3          	and	a5,a5,s8
ffffffffc0201f6a:	1f479163          	bne	a5,s4,ffffffffc020214c <pmm_init+0x5e4>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0201f6e:	609c                	ld	a5,0(s1)
ffffffffc0201f70:	9a5e                	add	s4,s4,s7
ffffffffc0201f72:	6008                	ld	a0,0(s0)
ffffffffc0201f74:	00c79713          	slli	a4,a5,0xc
ffffffffc0201f78:	fcea69e3          	bltu	s4,a4,ffffffffc0201f4a <pmm_init+0x3e2>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc0201f7c:	611c                	ld	a5,0(a0)
ffffffffc0201f7e:	6a079363          	bnez	a5,ffffffffc0202624 <pmm_init+0xabc>

    struct Page *p;
    p = alloc_page();
ffffffffc0201f82:	4505                	li	a0,1
ffffffffc0201f84:	f0aff0ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0201f88:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201f8a:	6008                	ld	a0,0(s0)
ffffffffc0201f8c:	4699                	li	a3,6
ffffffffc0201f8e:	10000613          	li	a2,256
ffffffffc0201f92:	85d2                	mv	a1,s4
ffffffffc0201f94:	b03ff0ef          	jal	ra,ffffffffc0201a96 <page_insert>
ffffffffc0201f98:	66051663          	bnez	a0,ffffffffc0202604 <pmm_init+0xa9c>
    assert(page_ref(p) == 1);
ffffffffc0201f9c:	000a2703          	lw	a4,0(s4) # ffffffffc0200000 <kern_entry>
ffffffffc0201fa0:	4785                	li	a5,1
ffffffffc0201fa2:	64f71163          	bne	a4,a5,ffffffffc02025e4 <pmm_init+0xa7c>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201fa6:	6008                	ld	a0,0(s0)
ffffffffc0201fa8:	6b85                	lui	s7,0x1
ffffffffc0201faa:	4699                	li	a3,6
ffffffffc0201fac:	100b8613          	addi	a2,s7,256 # 1100 <BASE_ADDRESS-0xffffffffc01fef00>
ffffffffc0201fb0:	85d2                	mv	a1,s4
ffffffffc0201fb2:	ae5ff0ef          	jal	ra,ffffffffc0201a96 <page_insert>
ffffffffc0201fb6:	60051763          	bnez	a0,ffffffffc02025c4 <pmm_init+0xa5c>
    assert(page_ref(p) == 2);
ffffffffc0201fba:	000a2703          	lw	a4,0(s4)
ffffffffc0201fbe:	4789                	li	a5,2
ffffffffc0201fc0:	4ef71663          	bne	a4,a5,ffffffffc02024ac <pmm_init+0x944>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0201fc4:	00003597          	auipc	a1,0x3
ffffffffc0201fc8:	73458593          	addi	a1,a1,1844 # ffffffffc02056f8 <default_pmm_manager+0x640>
ffffffffc0201fcc:	10000513          	li	a0,256
ffffffffc0201fd0:	332020ef          	jal	ra,ffffffffc0204302 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201fd4:	100b8593          	addi	a1,s7,256
ffffffffc0201fd8:	10000513          	li	a0,256
ffffffffc0201fdc:	338020ef          	jal	ra,ffffffffc0204314 <strcmp>
ffffffffc0201fe0:	4a051663          	bnez	a0,ffffffffc020248c <pmm_init+0x924>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201fe4:	00093683          	ld	a3,0(s2)
ffffffffc0201fe8:	000abc83          	ld	s9,0(s5)
ffffffffc0201fec:	00080c37          	lui	s8,0x80
ffffffffc0201ff0:	40da06b3          	sub	a3,s4,a3
ffffffffc0201ff4:	868d                	srai	a3,a3,0x3
ffffffffc0201ff6:	039686b3          	mul	a3,a3,s9
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201ffa:	5afd                	li	s5,-1
ffffffffc0201ffc:	609c                	ld	a5,0(s1)
ffffffffc0201ffe:	00cada93          	srli	s5,s5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202002:	96e2                	add	a3,a3,s8
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202004:	0156f733          	and	a4,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0202008:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020200a:	16f77363          	bleu	a5,a4,ffffffffc0202170 <pmm_init+0x608>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020200e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202012:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202016:	96be                	add	a3,a3,a5
ffffffffc0202018:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fdedb60>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020201c:	2a2020ef          	jal	ra,ffffffffc02042be <strlen>
ffffffffc0202020:	44051663          	bnez	a0,ffffffffc020246c <pmm_init+0x904>

    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202024:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202028:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020202a:	000bb783          	ld	a5,0(s7)
ffffffffc020202e:	078a                	slli	a5,a5,0x2
ffffffffc0202030:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202032:	12e7fd63          	bleu	a4,a5,ffffffffc020216c <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0202036:	418787b3          	sub	a5,a5,s8
ffffffffc020203a:	00379693          	slli	a3,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020203e:	96be                	add	a3,a3,a5
ffffffffc0202040:	039686b3          	mul	a3,a3,s9
ffffffffc0202044:	96e2                	add	a3,a3,s8
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202046:	0156fab3          	and	s5,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc020204a:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020204c:	12eaf263          	bleu	a4,s5,ffffffffc0202170 <pmm_init+0x608>
ffffffffc0202050:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc0202054:	4585                	li	a1,1
ffffffffc0202056:	8552                	mv	a0,s4
ffffffffc0202058:	99b6                	add	s3,s3,a3
ffffffffc020205a:	edeff0ef          	jal	ra,ffffffffc0201738 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020205e:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0202062:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202064:	078a                	slli	a5,a5,0x2
ffffffffc0202066:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202068:	10e7f263          	bleu	a4,a5,ffffffffc020216c <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc020206c:	fff809b7          	lui	s3,0xfff80
ffffffffc0202070:	97ce                	add	a5,a5,s3
ffffffffc0202072:	00379513          	slli	a0,a5,0x3
ffffffffc0202076:	00093703          	ld	a4,0(s2)
ffffffffc020207a:	97aa                	add	a5,a5,a0
ffffffffc020207c:	00379513          	slli	a0,a5,0x3
    free_page(pde2page(pd0[0]));
ffffffffc0202080:	953a                	add	a0,a0,a4
ffffffffc0202082:	4585                	li	a1,1
ffffffffc0202084:	eb4ff0ef          	jal	ra,ffffffffc0201738 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202088:	000bb503          	ld	a0,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc020208c:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020208e:	050a                	slli	a0,a0,0x2
ffffffffc0202090:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202092:	0cf57d63          	bleu	a5,a0,ffffffffc020216c <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0202096:	013507b3          	add	a5,a0,s3
ffffffffc020209a:	00379513          	slli	a0,a5,0x3
ffffffffc020209e:	00093703          	ld	a4,0(s2)
ffffffffc02020a2:	953e                	add	a0,a0,a5
ffffffffc02020a4:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc02020a6:	4585                	li	a1,1
ffffffffc02020a8:	953a                	add	a0,a0,a4
ffffffffc02020aa:	e8eff0ef          	jal	ra,ffffffffc0201738 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc02020ae:	601c                	ld	a5,0(s0)
ffffffffc02020b0:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>

    assert(nr_free_store == nr_free_pages());
ffffffffc02020b4:	ecaff0ef          	jal	ra,ffffffffc020177e <nr_free_pages>
ffffffffc02020b8:	38ab1a63          	bne	s6,a0,ffffffffc020244c <pmm_init+0x8e4>
}
ffffffffc02020bc:	6446                	ld	s0,80(sp)
ffffffffc02020be:	60e6                	ld	ra,88(sp)
ffffffffc02020c0:	64a6                	ld	s1,72(sp)
ffffffffc02020c2:	6906                	ld	s2,64(sp)
ffffffffc02020c4:	79e2                	ld	s3,56(sp)
ffffffffc02020c6:	7a42                	ld	s4,48(sp)
ffffffffc02020c8:	7aa2                	ld	s5,40(sp)
ffffffffc02020ca:	7b02                	ld	s6,32(sp)
ffffffffc02020cc:	6be2                	ld	s7,24(sp)
ffffffffc02020ce:	6c42                	ld	s8,16(sp)
ffffffffc02020d0:	6ca2                	ld	s9,8(sp)

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02020d2:	00003517          	auipc	a0,0x3
ffffffffc02020d6:	69e50513          	addi	a0,a0,1694 # ffffffffc0205770 <default_pmm_manager+0x6b8>
}
ffffffffc02020da:	6125                	addi	sp,sp,96
    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02020dc:	fe3fd06f          	j	ffffffffc02000be <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02020e0:	6705                	lui	a4,0x1
ffffffffc02020e2:	177d                	addi	a4,a4,-1
ffffffffc02020e4:	96ba                	add	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc02020e6:	00c6d713          	srli	a4,a3,0xc
ffffffffc02020ea:	08f77163          	bleu	a5,a4,ffffffffc020216c <pmm_init+0x604>
    pmm_manager->init_memmap(base, n);
ffffffffc02020ee:	00043803          	ld	a6,0(s0)
    return &pages[PPN(pa) - nbase];
ffffffffc02020f2:	9732                	add	a4,a4,a2
ffffffffc02020f4:	00371793          	slli	a5,a4,0x3
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02020f8:	767d                	lui	a2,0xfffff
ffffffffc02020fa:	8ef1                	and	a3,a3,a2
ffffffffc02020fc:	97ba                	add	a5,a5,a4
    pmm_manager->init_memmap(base, n);
ffffffffc02020fe:	01083703          	ld	a4,16(a6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202102:	8d95                	sub	a1,a1,a3
ffffffffc0202104:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0202106:	81b1                	srli	a1,a1,0xc
ffffffffc0202108:	953e                	add	a0,a0,a5
ffffffffc020210a:	9702                	jalr	a4
ffffffffc020210c:	bead                	j	ffffffffc0201c86 <pmm_init+0x11e>
ffffffffc020210e:	6008                	ld	a0,0(s0)
ffffffffc0202110:	b5b5                	j	ffffffffc0201f7c <pmm_init+0x414>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202112:	86d2                	mv	a3,s4
ffffffffc0202114:	00003617          	auipc	a2,0x3
ffffffffc0202118:	02460613          	addi	a2,a2,36 # ffffffffc0205138 <default_pmm_manager+0x80>
ffffffffc020211c:	20200593          	li	a1,514
ffffffffc0202120:	00003517          	auipc	a0,0x3
ffffffffc0202124:	04050513          	addi	a0,a0,64 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202128:	a4cfe0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc020212c:	00003697          	auipc	a3,0x3
ffffffffc0202130:	4b468693          	addi	a3,a3,1204 # ffffffffc02055e0 <default_pmm_manager+0x528>
ffffffffc0202134:	00003617          	auipc	a2,0x3
ffffffffc0202138:	bec60613          	addi	a2,a2,-1044 # ffffffffc0204d20 <commands+0x870>
ffffffffc020213c:	20200593          	li	a1,514
ffffffffc0202140:	00003517          	auipc	a0,0x3
ffffffffc0202144:	02050513          	addi	a0,a0,32 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202148:	a2cfe0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020214c:	00003697          	auipc	a3,0x3
ffffffffc0202150:	4d468693          	addi	a3,a3,1236 # ffffffffc0205620 <default_pmm_manager+0x568>
ffffffffc0202154:	00003617          	auipc	a2,0x3
ffffffffc0202158:	bcc60613          	addi	a2,a2,-1076 # ffffffffc0204d20 <commands+0x870>
ffffffffc020215c:	20300593          	li	a1,515
ffffffffc0202160:	00003517          	auipc	a0,0x3
ffffffffc0202164:	00050513          	mv	a0,a0
ffffffffc0202168:	a0cfe0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc020216c:	d06ff0ef          	jal	ra,ffffffffc0201672 <pa2page.part.4>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202170:	00003617          	auipc	a2,0x3
ffffffffc0202174:	fc860613          	addi	a2,a2,-56 # ffffffffc0205138 <default_pmm_manager+0x80>
ffffffffc0202178:	06a00593          	li	a1,106
ffffffffc020217c:	00003517          	auipc	a0,0x3
ffffffffc0202180:	05450513          	addi	a0,a0,84 # ffffffffc02051d0 <default_pmm_manager+0x118>
ffffffffc0202184:	9f0fe0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202188:	00003617          	auipc	a2,0x3
ffffffffc020218c:	22060613          	addi	a2,a2,544 # ffffffffc02053a8 <default_pmm_manager+0x2f0>
ffffffffc0202190:	07000593          	li	a1,112
ffffffffc0202194:	00003517          	auipc	a0,0x3
ffffffffc0202198:	03c50513          	addi	a0,a0,60 # ffffffffc02051d0 <default_pmm_manager+0x118>
ffffffffc020219c:	9d8fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02021a0:	00003697          	auipc	a3,0x3
ffffffffc02021a4:	14868693          	addi	a3,a3,328 # ffffffffc02052e8 <default_pmm_manager+0x230>
ffffffffc02021a8:	00003617          	auipc	a2,0x3
ffffffffc02021ac:	b7860613          	addi	a2,a2,-1160 # ffffffffc0204d20 <commands+0x870>
ffffffffc02021b0:	1c600593          	li	a1,454
ffffffffc02021b4:	00003517          	auipc	a0,0x3
ffffffffc02021b8:	fac50513          	addi	a0,a0,-84 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02021bc:	9b8fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02021c0:	00003697          	auipc	a3,0x3
ffffffffc02021c4:	16068693          	addi	a3,a3,352 # ffffffffc0205320 <default_pmm_manager+0x268>
ffffffffc02021c8:	00003617          	auipc	a2,0x3
ffffffffc02021cc:	b5860613          	addi	a2,a2,-1192 # ffffffffc0204d20 <commands+0x870>
ffffffffc02021d0:	1c700593          	li	a1,455
ffffffffc02021d4:	00003517          	auipc	a0,0x3
ffffffffc02021d8:	f8c50513          	addi	a0,a0,-116 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02021dc:	998fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02021e0:	00003697          	auipc	a3,0x3
ffffffffc02021e4:	3b868693          	addi	a3,a3,952 # ffffffffc0205598 <default_pmm_manager+0x4e0>
ffffffffc02021e8:	00003617          	auipc	a2,0x3
ffffffffc02021ec:	b3860613          	addi	a2,a2,-1224 # ffffffffc0204d20 <commands+0x870>
ffffffffc02021f0:	1f300593          	li	a1,499
ffffffffc02021f4:	00003517          	auipc	a0,0x3
ffffffffc02021f8:	f6c50513          	addi	a0,a0,-148 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02021fc:	978fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202200:	00003617          	auipc	a2,0x3
ffffffffc0202204:	08060613          	addi	a2,a2,128 # ffffffffc0205280 <default_pmm_manager+0x1c8>
ffffffffc0202208:	08600593          	li	a1,134
ffffffffc020220c:	00003517          	auipc	a0,0x3
ffffffffc0202210:	f5450513          	addi	a0,a0,-172 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202214:	960fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202218:	00003697          	auipc	a3,0x3
ffffffffc020221c:	16068693          	addi	a3,a3,352 # ffffffffc0205378 <default_pmm_manager+0x2c0>
ffffffffc0202220:	00003617          	auipc	a2,0x3
ffffffffc0202224:	b0060613          	addi	a2,a2,-1280 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202228:	1cd00593          	li	a1,461
ffffffffc020222c:	00003517          	auipc	a0,0x3
ffffffffc0202230:	f3450513          	addi	a0,a0,-204 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202234:	940fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202238:	00003697          	auipc	a3,0x3
ffffffffc020223c:	11068693          	addi	a3,a3,272 # ffffffffc0205348 <default_pmm_manager+0x290>
ffffffffc0202240:	00003617          	auipc	a2,0x3
ffffffffc0202244:	ae060613          	addi	a2,a2,-1312 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202248:	1cb00593          	li	a1,459
ffffffffc020224c:	00003517          	auipc	a0,0x3
ffffffffc0202250:	f1450513          	addi	a0,a0,-236 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202254:	920fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202258:	00003697          	auipc	a3,0x3
ffffffffc020225c:	23868693          	addi	a3,a3,568 # ffffffffc0205490 <default_pmm_manager+0x3d8>
ffffffffc0202260:	00003617          	auipc	a2,0x3
ffffffffc0202264:	ac060613          	addi	a2,a2,-1344 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202268:	1d800593          	li	a1,472
ffffffffc020226c:	00003517          	auipc	a0,0x3
ffffffffc0202270:	ef450513          	addi	a0,a0,-268 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202274:	900fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202278:	00003697          	auipc	a3,0x3
ffffffffc020227c:	1e868693          	addi	a3,a3,488 # ffffffffc0205460 <default_pmm_manager+0x3a8>
ffffffffc0202280:	00003617          	auipc	a2,0x3
ffffffffc0202284:	aa060613          	addi	a2,a2,-1376 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202288:	1d700593          	li	a1,471
ffffffffc020228c:	00003517          	auipc	a0,0x3
ffffffffc0202290:	ed450513          	addi	a0,a0,-300 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202294:	8e0fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202298:	00003697          	auipc	a3,0x3
ffffffffc020229c:	19068693          	addi	a3,a3,400 # ffffffffc0205428 <default_pmm_manager+0x370>
ffffffffc02022a0:	00003617          	auipc	a2,0x3
ffffffffc02022a4:	a8060613          	addi	a2,a2,-1408 # ffffffffc0204d20 <commands+0x870>
ffffffffc02022a8:	1d600593          	li	a1,470
ffffffffc02022ac:	00003517          	auipc	a0,0x3
ffffffffc02022b0:	eb450513          	addi	a0,a0,-332 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02022b4:	8c0fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02022b8:	00003697          	auipc	a3,0x3
ffffffffc02022bc:	14868693          	addi	a3,a3,328 # ffffffffc0205400 <default_pmm_manager+0x348>
ffffffffc02022c0:	00003617          	auipc	a2,0x3
ffffffffc02022c4:	a6060613          	addi	a2,a2,-1440 # ffffffffc0204d20 <commands+0x870>
ffffffffc02022c8:	1d300593          	li	a1,467
ffffffffc02022cc:	00003517          	auipc	a0,0x3
ffffffffc02022d0:	e9450513          	addi	a0,a0,-364 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02022d4:	8a0fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02022d8:	86da                	mv	a3,s6
ffffffffc02022da:	00003617          	auipc	a2,0x3
ffffffffc02022de:	e5e60613          	addi	a2,a2,-418 # ffffffffc0205138 <default_pmm_manager+0x80>
ffffffffc02022e2:	1d200593          	li	a1,466
ffffffffc02022e6:	00003517          	auipc	a0,0x3
ffffffffc02022ea:	e7a50513          	addi	a0,a0,-390 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02022ee:	886fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc02022f2:	86be                	mv	a3,a5
ffffffffc02022f4:	00003617          	auipc	a2,0x3
ffffffffc02022f8:	e4460613          	addi	a2,a2,-444 # ffffffffc0205138 <default_pmm_manager+0x80>
ffffffffc02022fc:	1d100593          	li	a1,465
ffffffffc0202300:	00003517          	auipc	a0,0x3
ffffffffc0202304:	e6050513          	addi	a0,a0,-416 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202308:	86cfe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020230c:	00003697          	auipc	a3,0x3
ffffffffc0202310:	0dc68693          	addi	a3,a3,220 # ffffffffc02053e8 <default_pmm_manager+0x330>
ffffffffc0202314:	00003617          	auipc	a2,0x3
ffffffffc0202318:	a0c60613          	addi	a2,a2,-1524 # ffffffffc0204d20 <commands+0x870>
ffffffffc020231c:	1cf00593          	li	a1,463
ffffffffc0202320:	00003517          	auipc	a0,0x3
ffffffffc0202324:	e4050513          	addi	a0,a0,-448 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202328:	84cfe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020232c:	00003697          	auipc	a3,0x3
ffffffffc0202330:	0a468693          	addi	a3,a3,164 # ffffffffc02053d0 <default_pmm_manager+0x318>
ffffffffc0202334:	00003617          	auipc	a2,0x3
ffffffffc0202338:	9ec60613          	addi	a2,a2,-1556 # ffffffffc0204d20 <commands+0x870>
ffffffffc020233c:	1ce00593          	li	a1,462
ffffffffc0202340:	00003517          	auipc	a0,0x3
ffffffffc0202344:	e2050513          	addi	a0,a0,-480 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202348:	82cfe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020234c:	00003697          	auipc	a3,0x3
ffffffffc0202350:	08468693          	addi	a3,a3,132 # ffffffffc02053d0 <default_pmm_manager+0x318>
ffffffffc0202354:	00003617          	auipc	a2,0x3
ffffffffc0202358:	9cc60613          	addi	a2,a2,-1588 # ffffffffc0204d20 <commands+0x870>
ffffffffc020235c:	1e100593          	li	a1,481
ffffffffc0202360:	00003517          	auipc	a0,0x3
ffffffffc0202364:	e0050513          	addi	a0,a0,-512 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202368:	80cfe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020236c:	00003697          	auipc	a3,0x3
ffffffffc0202370:	0f468693          	addi	a3,a3,244 # ffffffffc0205460 <default_pmm_manager+0x3a8>
ffffffffc0202374:	00003617          	auipc	a2,0x3
ffffffffc0202378:	9ac60613          	addi	a2,a2,-1620 # ffffffffc0204d20 <commands+0x870>
ffffffffc020237c:	1e000593          	li	a1,480
ffffffffc0202380:	00003517          	auipc	a0,0x3
ffffffffc0202384:	de050513          	addi	a0,a0,-544 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202388:	fedfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020238c:	00003697          	auipc	a3,0x3
ffffffffc0202390:	19c68693          	addi	a3,a3,412 # ffffffffc0205528 <default_pmm_manager+0x470>
ffffffffc0202394:	00003617          	auipc	a2,0x3
ffffffffc0202398:	98c60613          	addi	a2,a2,-1652 # ffffffffc0204d20 <commands+0x870>
ffffffffc020239c:	1df00593          	li	a1,479
ffffffffc02023a0:	00003517          	auipc	a0,0x3
ffffffffc02023a4:	dc050513          	addi	a0,a0,-576 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02023a8:	fcdfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02023ac:	00003697          	auipc	a3,0x3
ffffffffc02023b0:	16468693          	addi	a3,a3,356 # ffffffffc0205510 <default_pmm_manager+0x458>
ffffffffc02023b4:	00003617          	auipc	a2,0x3
ffffffffc02023b8:	96c60613          	addi	a2,a2,-1684 # ffffffffc0204d20 <commands+0x870>
ffffffffc02023bc:	1de00593          	li	a1,478
ffffffffc02023c0:	00003517          	auipc	a0,0x3
ffffffffc02023c4:	da050513          	addi	a0,a0,-608 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02023c8:	fadfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02023cc:	00003697          	auipc	a3,0x3
ffffffffc02023d0:	11468693          	addi	a3,a3,276 # ffffffffc02054e0 <default_pmm_manager+0x428>
ffffffffc02023d4:	00003617          	auipc	a2,0x3
ffffffffc02023d8:	94c60613          	addi	a2,a2,-1716 # ffffffffc0204d20 <commands+0x870>
ffffffffc02023dc:	1dd00593          	li	a1,477
ffffffffc02023e0:	00003517          	auipc	a0,0x3
ffffffffc02023e4:	d8050513          	addi	a0,a0,-640 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02023e8:	f8dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02023ec:	00003697          	auipc	a3,0x3
ffffffffc02023f0:	0dc68693          	addi	a3,a3,220 # ffffffffc02054c8 <default_pmm_manager+0x410>
ffffffffc02023f4:	00003617          	auipc	a2,0x3
ffffffffc02023f8:	92c60613          	addi	a2,a2,-1748 # ffffffffc0204d20 <commands+0x870>
ffffffffc02023fc:	1db00593          	li	a1,475
ffffffffc0202400:	00003517          	auipc	a0,0x3
ffffffffc0202404:	d6050513          	addi	a0,a0,-672 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202408:	f6dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc020240c:	00003697          	auipc	a3,0x3
ffffffffc0202410:	0a468693          	addi	a3,a3,164 # ffffffffc02054b0 <default_pmm_manager+0x3f8>
ffffffffc0202414:	00003617          	auipc	a2,0x3
ffffffffc0202418:	90c60613          	addi	a2,a2,-1780 # ffffffffc0204d20 <commands+0x870>
ffffffffc020241c:	1da00593          	li	a1,474
ffffffffc0202420:	00003517          	auipc	a0,0x3
ffffffffc0202424:	d4050513          	addi	a0,a0,-704 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202428:	f4dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(*ptep & PTE_W);
ffffffffc020242c:	00003697          	auipc	a3,0x3
ffffffffc0202430:	07468693          	addi	a3,a3,116 # ffffffffc02054a0 <default_pmm_manager+0x3e8>
ffffffffc0202434:	00003617          	auipc	a2,0x3
ffffffffc0202438:	8ec60613          	addi	a2,a2,-1812 # ffffffffc0204d20 <commands+0x870>
ffffffffc020243c:	1d900593          	li	a1,473
ffffffffc0202440:	00003517          	auipc	a0,0x3
ffffffffc0202444:	d2050513          	addi	a0,a0,-736 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202448:	f2dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020244c:	00003697          	auipc	a3,0x3
ffffffffc0202450:	14c68693          	addi	a3,a3,332 # ffffffffc0205598 <default_pmm_manager+0x4e0>
ffffffffc0202454:	00003617          	auipc	a2,0x3
ffffffffc0202458:	8cc60613          	addi	a2,a2,-1844 # ffffffffc0204d20 <commands+0x870>
ffffffffc020245c:	21c00593          	li	a1,540
ffffffffc0202460:	00003517          	auipc	a0,0x3
ffffffffc0202464:	d0050513          	addi	a0,a0,-768 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202468:	f0dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020246c:	00003697          	auipc	a3,0x3
ffffffffc0202470:	2dc68693          	addi	a3,a3,732 # ffffffffc0205748 <default_pmm_manager+0x690>
ffffffffc0202474:	00003617          	auipc	a2,0x3
ffffffffc0202478:	8ac60613          	addi	a2,a2,-1876 # ffffffffc0204d20 <commands+0x870>
ffffffffc020247c:	21400593          	li	a1,532
ffffffffc0202480:	00003517          	auipc	a0,0x3
ffffffffc0202484:	ce050513          	addi	a0,a0,-800 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202488:	eedfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020248c:	00003697          	auipc	a3,0x3
ffffffffc0202490:	28468693          	addi	a3,a3,644 # ffffffffc0205710 <default_pmm_manager+0x658>
ffffffffc0202494:	00003617          	auipc	a2,0x3
ffffffffc0202498:	88c60613          	addi	a2,a2,-1908 # ffffffffc0204d20 <commands+0x870>
ffffffffc020249c:	21100593          	li	a1,529
ffffffffc02024a0:	00003517          	auipc	a0,0x3
ffffffffc02024a4:	cc050513          	addi	a0,a0,-832 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02024a8:	ecdfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02024ac:	00003697          	auipc	a3,0x3
ffffffffc02024b0:	23468693          	addi	a3,a3,564 # ffffffffc02056e0 <default_pmm_manager+0x628>
ffffffffc02024b4:	00003617          	auipc	a2,0x3
ffffffffc02024b8:	86c60613          	addi	a2,a2,-1940 # ffffffffc0204d20 <commands+0x870>
ffffffffc02024bc:	20d00593          	li	a1,525
ffffffffc02024c0:	00003517          	auipc	a0,0x3
ffffffffc02024c4:	ca050513          	addi	a0,a0,-864 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02024c8:	eadfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02024cc:	00003697          	auipc	a3,0x3
ffffffffc02024d0:	08c68693          	addi	a3,a3,140 # ffffffffc0205558 <default_pmm_manager+0x4a0>
ffffffffc02024d4:	00003617          	auipc	a2,0x3
ffffffffc02024d8:	84c60613          	addi	a2,a2,-1972 # ffffffffc0204d20 <commands+0x870>
ffffffffc02024dc:	1e900593          	li	a1,489
ffffffffc02024e0:	00003517          	auipc	a0,0x3
ffffffffc02024e4:	c8050513          	addi	a0,a0,-896 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02024e8:	e8dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02024ec:	00003697          	auipc	a3,0x3
ffffffffc02024f0:	03c68693          	addi	a3,a3,60 # ffffffffc0205528 <default_pmm_manager+0x470>
ffffffffc02024f4:	00003617          	auipc	a2,0x3
ffffffffc02024f8:	82c60613          	addi	a2,a2,-2004 # ffffffffc0204d20 <commands+0x870>
ffffffffc02024fc:	1e600593          	li	a1,486
ffffffffc0202500:	00003517          	auipc	a0,0x3
ffffffffc0202504:	c6050513          	addi	a0,a0,-928 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202508:	e6dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020250c:	00003697          	auipc	a3,0x3
ffffffffc0202510:	edc68693          	addi	a3,a3,-292 # ffffffffc02053e8 <default_pmm_manager+0x330>
ffffffffc0202514:	00003617          	auipc	a2,0x3
ffffffffc0202518:	80c60613          	addi	a2,a2,-2036 # ffffffffc0204d20 <commands+0x870>
ffffffffc020251c:	1e500593          	li	a1,485
ffffffffc0202520:	00003517          	auipc	a0,0x3
ffffffffc0202524:	c4050513          	addi	a0,a0,-960 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202528:	e4dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020252c:	00003697          	auipc	a3,0x3
ffffffffc0202530:	01468693          	addi	a3,a3,20 # ffffffffc0205540 <default_pmm_manager+0x488>
ffffffffc0202534:	00002617          	auipc	a2,0x2
ffffffffc0202538:	7ec60613          	addi	a2,a2,2028 # ffffffffc0204d20 <commands+0x870>
ffffffffc020253c:	1e200593          	li	a1,482
ffffffffc0202540:	00003517          	auipc	a0,0x3
ffffffffc0202544:	c2050513          	addi	a0,a0,-992 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202548:	e2dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020254c:	00003697          	auipc	a3,0x3
ffffffffc0202550:	02468693          	addi	a3,a3,36 # ffffffffc0205570 <default_pmm_manager+0x4b8>
ffffffffc0202554:	00002617          	auipc	a2,0x2
ffffffffc0202558:	7cc60613          	addi	a2,a2,1996 # ffffffffc0204d20 <commands+0x870>
ffffffffc020255c:	1ec00593          	li	a1,492
ffffffffc0202560:	00003517          	auipc	a0,0x3
ffffffffc0202564:	c0050513          	addi	a0,a0,-1024 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202568:	e0dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020256c:	00003697          	auipc	a3,0x3
ffffffffc0202570:	fbc68693          	addi	a3,a3,-68 # ffffffffc0205528 <default_pmm_manager+0x470>
ffffffffc0202574:	00002617          	auipc	a2,0x2
ffffffffc0202578:	7ac60613          	addi	a2,a2,1964 # ffffffffc0204d20 <commands+0x870>
ffffffffc020257c:	1ea00593          	li	a1,490
ffffffffc0202580:	00003517          	auipc	a0,0x3
ffffffffc0202584:	be050513          	addi	a0,a0,-1056 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202588:	dedfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020258c:	00003697          	auipc	a3,0x3
ffffffffc0202590:	d3c68693          	addi	a3,a3,-708 # ffffffffc02052c8 <default_pmm_manager+0x210>
ffffffffc0202594:	00002617          	auipc	a2,0x2
ffffffffc0202598:	78c60613          	addi	a2,a2,1932 # ffffffffc0204d20 <commands+0x870>
ffffffffc020259c:	1c500593          	li	a1,453
ffffffffc02025a0:	00003517          	auipc	a0,0x3
ffffffffc02025a4:	bc050513          	addi	a0,a0,-1088 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02025a8:	dcdfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02025ac:	00003617          	auipc	a2,0x3
ffffffffc02025b0:	cd460613          	addi	a2,a2,-812 # ffffffffc0205280 <default_pmm_manager+0x1c8>
ffffffffc02025b4:	0d300593          	li	a1,211
ffffffffc02025b8:	00003517          	auipc	a0,0x3
ffffffffc02025bc:	ba850513          	addi	a0,a0,-1112 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02025c0:	db5fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025c4:	00003697          	auipc	a3,0x3
ffffffffc02025c8:	0dc68693          	addi	a3,a3,220 # ffffffffc02056a0 <default_pmm_manager+0x5e8>
ffffffffc02025cc:	00002617          	auipc	a2,0x2
ffffffffc02025d0:	75460613          	addi	a2,a2,1876 # ffffffffc0204d20 <commands+0x870>
ffffffffc02025d4:	20c00593          	li	a1,524
ffffffffc02025d8:	00003517          	auipc	a0,0x3
ffffffffc02025dc:	b8850513          	addi	a0,a0,-1144 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02025e0:	d95fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p) == 1);
ffffffffc02025e4:	00003697          	auipc	a3,0x3
ffffffffc02025e8:	0a468693          	addi	a3,a3,164 # ffffffffc0205688 <default_pmm_manager+0x5d0>
ffffffffc02025ec:	00002617          	auipc	a2,0x2
ffffffffc02025f0:	73460613          	addi	a2,a2,1844 # ffffffffc0204d20 <commands+0x870>
ffffffffc02025f4:	20b00593          	li	a1,523
ffffffffc02025f8:	00003517          	auipc	a0,0x3
ffffffffc02025fc:	b6850513          	addi	a0,a0,-1176 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202600:	d75fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202604:	00003697          	auipc	a3,0x3
ffffffffc0202608:	04c68693          	addi	a3,a3,76 # ffffffffc0205650 <default_pmm_manager+0x598>
ffffffffc020260c:	00002617          	auipc	a2,0x2
ffffffffc0202610:	71460613          	addi	a2,a2,1812 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202614:	20a00593          	li	a1,522
ffffffffc0202618:	00003517          	auipc	a0,0x3
ffffffffc020261c:	b4850513          	addi	a0,a0,-1208 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202620:	d55fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0202624:	00003697          	auipc	a3,0x3
ffffffffc0202628:	01468693          	addi	a3,a3,20 # ffffffffc0205638 <default_pmm_manager+0x580>
ffffffffc020262c:	00002617          	auipc	a2,0x2
ffffffffc0202630:	6f460613          	addi	a2,a2,1780 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202634:	20600593          	li	a1,518
ffffffffc0202638:	00003517          	auipc	a0,0x3
ffffffffc020263c:	b2850513          	addi	a0,a0,-1240 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202640:	d35fd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0202644 <tlb_invalidate>:
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0202644:	12000073          	sfence.vma
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }
ffffffffc0202648:	8082                	ret

ffffffffc020264a <pgdir_alloc_page>:
{
ffffffffc020264a:	7179                	addi	sp,sp,-48
ffffffffc020264c:	e84a                	sd	s2,16(sp)
ffffffffc020264e:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0202650:	4505                	li	a0,1
{
ffffffffc0202652:	f022                	sd	s0,32(sp)
ffffffffc0202654:	ec26                	sd	s1,24(sp)
ffffffffc0202656:	e44e                	sd	s3,8(sp)
ffffffffc0202658:	f406                	sd	ra,40(sp)
ffffffffc020265a:	84ae                	mv	s1,a1
ffffffffc020265c:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc020265e:	830ff0ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc0202662:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0202664:	cd19                	beqz	a0,ffffffffc0202682 <pgdir_alloc_page+0x38>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0202666:	85aa                	mv	a1,a0
ffffffffc0202668:	86ce                	mv	a3,s3
ffffffffc020266a:	8626                	mv	a2,s1
ffffffffc020266c:	854a                	mv	a0,s2
ffffffffc020266e:	c28ff0ef          	jal	ra,ffffffffc0201a96 <page_insert>
ffffffffc0202672:	ed39                	bnez	a0,ffffffffc02026d0 <pgdir_alloc_page+0x86>
        if (swap_init_ok)
ffffffffc0202674:	0000f797          	auipc	a5,0xf
ffffffffc0202678:	dfc78793          	addi	a5,a5,-516 # ffffffffc0211470 <swap_init_ok>
ffffffffc020267c:	439c                	lw	a5,0(a5)
ffffffffc020267e:	2781                	sext.w	a5,a5
ffffffffc0202680:	eb89                	bnez	a5,ffffffffc0202692 <pgdir_alloc_page+0x48>
}
ffffffffc0202682:	8522                	mv	a0,s0
ffffffffc0202684:	70a2                	ld	ra,40(sp)
ffffffffc0202686:	7402                	ld	s0,32(sp)
ffffffffc0202688:	64e2                	ld	s1,24(sp)
ffffffffc020268a:	6942                	ld	s2,16(sp)
ffffffffc020268c:	69a2                	ld	s3,8(sp)
ffffffffc020268e:	6145                	addi	sp,sp,48
ffffffffc0202690:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0202692:	0000f797          	auipc	a5,0xf
ffffffffc0202696:	f0678793          	addi	a5,a5,-250 # ffffffffc0211598 <check_mm_struct>
ffffffffc020269a:	6388                	ld	a0,0(a5)
ffffffffc020269c:	4681                	li	a3,0
ffffffffc020269e:	8622                	mv	a2,s0
ffffffffc02026a0:	85a6                	mv	a1,s1
ffffffffc02026a2:	093000ef          	jal	ra,ffffffffc0202f34 <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc02026a6:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc02026a8:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1);
ffffffffc02026aa:	4785                	li	a5,1
ffffffffc02026ac:	fcf70be3          	beq	a4,a5,ffffffffc0202682 <pgdir_alloc_page+0x38>
ffffffffc02026b0:	00003697          	auipc	a3,0x3
ffffffffc02026b4:	b3068693          	addi	a3,a3,-1232 # ffffffffc02051e0 <default_pmm_manager+0x128>
ffffffffc02026b8:	00002617          	auipc	a2,0x2
ffffffffc02026bc:	66860613          	addi	a2,a2,1640 # ffffffffc0204d20 <commands+0x870>
ffffffffc02026c0:	1ab00593          	li	a1,427
ffffffffc02026c4:	00003517          	auipc	a0,0x3
ffffffffc02026c8:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc02026cc:	ca9fd0ef          	jal	ra,ffffffffc0200374 <__panic>
            free_page(page);
ffffffffc02026d0:	8522                	mv	a0,s0
ffffffffc02026d2:	4585                	li	a1,1
ffffffffc02026d4:	864ff0ef          	jal	ra,ffffffffc0201738 <free_pages>
            return NULL;
ffffffffc02026d8:	4401                	li	s0,0
ffffffffc02026da:	b765                	j	ffffffffc0202682 <pgdir_alloc_page+0x38>

ffffffffc02026dc <kmalloc>:
}

void *kmalloc(size_t n)
{
ffffffffc02026dc:	1141                	addi	sp,sp,-16
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02026de:	67d5                	lui	a5,0x15
{
ffffffffc02026e0:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02026e2:	fff50713          	addi	a4,a0,-1
ffffffffc02026e6:	17f9                	addi	a5,a5,-2
ffffffffc02026e8:	04e7ee63          	bltu	a5,a4,ffffffffc0202744 <kmalloc+0x68>
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc02026ec:	6785                	lui	a5,0x1
ffffffffc02026ee:	17fd                	addi	a5,a5,-1
ffffffffc02026f0:	953e                	add	a0,a0,a5
    base = alloc_pages(num_pages);
ffffffffc02026f2:	8131                	srli	a0,a0,0xc
ffffffffc02026f4:	f9bfe0ef          	jal	ra,ffffffffc020168e <alloc_pages>
    assert(base != NULL);
ffffffffc02026f8:	c159                	beqz	a0,ffffffffc020277e <kmalloc+0xa2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02026fa:	0000f797          	auipc	a5,0xf
ffffffffc02026fe:	db678793          	addi	a5,a5,-586 # ffffffffc02114b0 <pages>
ffffffffc0202702:	639c                	ld	a5,0(a5)
ffffffffc0202704:	8d1d                	sub	a0,a0,a5
ffffffffc0202706:	00002797          	auipc	a5,0x2
ffffffffc020270a:	60278793          	addi	a5,a5,1538 # ffffffffc0204d08 <commands+0x858>
ffffffffc020270e:	6394                	ld	a3,0(a5)
ffffffffc0202710:	850d                	srai	a0,a0,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202712:	0000f797          	auipc	a5,0xf
ffffffffc0202716:	d4e78793          	addi	a5,a5,-690 # ffffffffc0211460 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020271a:	02d50533          	mul	a0,a0,a3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020271e:	6398                	ld	a4,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202720:	000806b7          	lui	a3,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202724:	57fd                	li	a5,-1
ffffffffc0202726:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202728:	9536                	add	a0,a0,a3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020272a:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc020272c:	0532                	slli	a0,a0,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020272e:	02e7fb63          	bleu	a4,a5,ffffffffc0202764 <kmalloc+0x88>
ffffffffc0202732:	0000f797          	auipc	a5,0xf
ffffffffc0202736:	d6e78793          	addi	a5,a5,-658 # ffffffffc02114a0 <va_pa_offset>
ffffffffc020273a:	639c                	ld	a5,0(a5)
    ptr = page2kva(base);
    return ptr;
}
ffffffffc020273c:	60a2                	ld	ra,8(sp)
ffffffffc020273e:	953e                	add	a0,a0,a5
ffffffffc0202740:	0141                	addi	sp,sp,16
ffffffffc0202742:	8082                	ret
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0202744:	00003697          	auipc	a3,0x3
ffffffffc0202748:	a3c68693          	addi	a3,a3,-1476 # ffffffffc0205180 <default_pmm_manager+0xc8>
ffffffffc020274c:	00002617          	auipc	a2,0x2
ffffffffc0202750:	5d460613          	addi	a2,a2,1492 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202754:	22500593          	li	a1,549
ffffffffc0202758:	00003517          	auipc	a0,0x3
ffffffffc020275c:	a0850513          	addi	a0,a0,-1528 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc0202760:	c15fd0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc0202764:	86aa                	mv	a3,a0
ffffffffc0202766:	00003617          	auipc	a2,0x3
ffffffffc020276a:	9d260613          	addi	a2,a2,-1582 # ffffffffc0205138 <default_pmm_manager+0x80>
ffffffffc020276e:	06a00593          	li	a1,106
ffffffffc0202772:	00003517          	auipc	a0,0x3
ffffffffc0202776:	a5e50513          	addi	a0,a0,-1442 # ffffffffc02051d0 <default_pmm_manager+0x118>
ffffffffc020277a:	bfbfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(base != NULL);
ffffffffc020277e:	00003697          	auipc	a3,0x3
ffffffffc0202782:	a2268693          	addi	a3,a3,-1502 # ffffffffc02051a0 <default_pmm_manager+0xe8>
ffffffffc0202786:	00002617          	auipc	a2,0x2
ffffffffc020278a:	59a60613          	addi	a2,a2,1434 # ffffffffc0204d20 <commands+0x870>
ffffffffc020278e:	22800593          	li	a1,552
ffffffffc0202792:	00003517          	auipc	a0,0x3
ffffffffc0202796:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc020279a:	bdbfd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020279e <kfree>:

void kfree(void *ptr, size_t n)
{
ffffffffc020279e:	1141                	addi	sp,sp,-16
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02027a0:	67d5                	lui	a5,0x15
{
ffffffffc02027a2:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02027a4:	fff58713          	addi	a4,a1,-1
ffffffffc02027a8:	17f9                	addi	a5,a5,-2
ffffffffc02027aa:	04e7eb63          	bltu	a5,a4,ffffffffc0202800 <kfree+0x62>
    assert(ptr != NULL);
ffffffffc02027ae:	c941                	beqz	a0,ffffffffc020283e <kfree+0xa0>
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc02027b0:	6785                	lui	a5,0x1
ffffffffc02027b2:	17fd                	addi	a5,a5,-1
ffffffffc02027b4:	95be                	add	a1,a1,a5
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc02027b6:	c02007b7          	lui	a5,0xc0200
ffffffffc02027ba:	81b1                	srli	a1,a1,0xc
ffffffffc02027bc:	06f56463          	bltu	a0,a5,ffffffffc0202824 <kfree+0x86>
ffffffffc02027c0:	0000f797          	auipc	a5,0xf
ffffffffc02027c4:	ce078793          	addi	a5,a5,-800 # ffffffffc02114a0 <va_pa_offset>
ffffffffc02027c8:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc02027ca:	0000f717          	auipc	a4,0xf
ffffffffc02027ce:	c9670713          	addi	a4,a4,-874 # ffffffffc0211460 <npage>
ffffffffc02027d2:	6318                	ld	a4,0(a4)
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc02027d4:	40f507b3          	sub	a5,a0,a5
    if (PPN(pa) >= npage) {
ffffffffc02027d8:	83b1                	srli	a5,a5,0xc
ffffffffc02027da:	04e7f363          	bleu	a4,a5,ffffffffc0202820 <kfree+0x82>
    return &pages[PPN(pa) - nbase];
ffffffffc02027de:	fff80537          	lui	a0,0xfff80
ffffffffc02027e2:	97aa                	add	a5,a5,a0
ffffffffc02027e4:	0000f697          	auipc	a3,0xf
ffffffffc02027e8:	ccc68693          	addi	a3,a3,-820 # ffffffffc02114b0 <pages>
ffffffffc02027ec:	6288                	ld	a0,0(a3)
ffffffffc02027ee:	00379713          	slli	a4,a5,0x3
    base = kva2page(ptr);
    free_pages(base, num_pages);
}
ffffffffc02027f2:	60a2                	ld	ra,8(sp)
ffffffffc02027f4:	97ba                	add	a5,a5,a4
ffffffffc02027f6:	078e                	slli	a5,a5,0x3
    free_pages(base, num_pages);
ffffffffc02027f8:	953e                	add	a0,a0,a5
}
ffffffffc02027fa:	0141                	addi	sp,sp,16
    free_pages(base, num_pages);
ffffffffc02027fc:	f3dfe06f          	j	ffffffffc0201738 <free_pages>
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0202800:	00003697          	auipc	a3,0x3
ffffffffc0202804:	98068693          	addi	a3,a3,-1664 # ffffffffc0205180 <default_pmm_manager+0xc8>
ffffffffc0202808:	00002617          	auipc	a2,0x2
ffffffffc020280c:	51860613          	addi	a2,a2,1304 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202810:	22f00593          	li	a1,559
ffffffffc0202814:	00003517          	auipc	a0,0x3
ffffffffc0202818:	94c50513          	addi	a0,a0,-1716 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc020281c:	b59fd0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc0202820:	e53fe0ef          	jal	ra,ffffffffc0201672 <pa2page.part.4>
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0202824:	86aa                	mv	a3,a0
ffffffffc0202826:	00003617          	auipc	a2,0x3
ffffffffc020282a:	a5a60613          	addi	a2,a2,-1446 # ffffffffc0205280 <default_pmm_manager+0x1c8>
ffffffffc020282e:	06c00593          	li	a1,108
ffffffffc0202832:	00003517          	auipc	a0,0x3
ffffffffc0202836:	99e50513          	addi	a0,a0,-1634 # ffffffffc02051d0 <default_pmm_manager+0x118>
ffffffffc020283a:	b3bfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(ptr != NULL);
ffffffffc020283e:	00003697          	auipc	a3,0x3
ffffffffc0202842:	93268693          	addi	a3,a3,-1742 # ffffffffc0205170 <default_pmm_manager+0xb8>
ffffffffc0202846:	00002617          	auipc	a2,0x2
ffffffffc020284a:	4da60613          	addi	a2,a2,1242 # ffffffffc0204d20 <commands+0x870>
ffffffffc020284e:	23000593          	li	a1,560
ffffffffc0202852:	00003517          	auipc	a0,0x3
ffffffffc0202856:	90e50513          	addi	a0,a0,-1778 # ffffffffc0205160 <default_pmm_manager+0xa8>
ffffffffc020285a:	b1bfd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020285e <swap_init>:
unsigned int swap_in_seq_no[MAX_SEQ_NO], swap_out_seq_no[MAX_SEQ_NO];

static void check_swap(void);

int swap_init(void)
{
ffffffffc020285e:	7135                	addi	sp,sp,-160
ffffffffc0202860:	ed06                	sd	ra,152(sp)
ffffffffc0202862:	e922                	sd	s0,144(sp)
ffffffffc0202864:	e526                	sd	s1,136(sp)
ffffffffc0202866:	e14a                	sd	s2,128(sp)
ffffffffc0202868:	fcce                	sd	s3,120(sp)
ffffffffc020286a:	f8d2                	sd	s4,112(sp)
ffffffffc020286c:	f4d6                	sd	s5,104(sp)
ffffffffc020286e:	f0da                	sd	s6,96(sp)
ffffffffc0202870:	ecde                	sd	s7,88(sp)
ffffffffc0202872:	e8e2                	sd	s8,80(sp)
ffffffffc0202874:	e4e6                	sd	s9,72(sp)
ffffffffc0202876:	e0ea                	sd	s10,64(sp)
ffffffffc0202878:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc020287a:	40a010ef          	jal	ra,ffffffffc0203c84 <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc020287e:	0000f797          	auipc	a5,0xf
ffffffffc0202882:	cc278793          	addi	a5,a5,-830 # ffffffffc0211540 <max_swap_offset>
ffffffffc0202886:	6394                	ld	a3,0(a5)
ffffffffc0202888:	010007b7          	lui	a5,0x1000
ffffffffc020288c:	17e1                	addi	a5,a5,-8
ffffffffc020288e:	ff968713          	addi	a4,a3,-7
ffffffffc0202892:	44e7ed63          	bltu	a5,a4,ffffffffc0202cec <swap_init+0x48e>
           max_swap_offset < MAX_SWAP_OFFSET_LIMIT))
     {
          panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_clock; // use clock Page Replacement Algorithm
ffffffffc0202896:	00007797          	auipc	a5,0x7
ffffffffc020289a:	76a78793          	addi	a5,a5,1898 # ffffffffc020a000 <swap_manager_clock>
     // sm = &swap_manager_fifo; // use first in first out Page Replacement Algorithm
     int r = sm->init();
ffffffffc020289e:	6798                	ld	a4,8(a5)
     sm = &swap_manager_clock; // use clock Page Replacement Algorithm
ffffffffc02028a0:	0000f697          	auipc	a3,0xf
ffffffffc02028a4:	bcf6b423          	sd	a5,-1080(a3) # ffffffffc0211468 <sm>
     int r = sm->init();
ffffffffc02028a8:	9702                	jalr	a4
ffffffffc02028aa:	8b2a                	mv	s6,a0

     if (r == 0)
ffffffffc02028ac:	c10d                	beqz	a0,ffffffffc02028ce <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02028ae:	60ea                	ld	ra,152(sp)
ffffffffc02028b0:	644a                	ld	s0,144(sp)
ffffffffc02028b2:	855a                	mv	a0,s6
ffffffffc02028b4:	64aa                	ld	s1,136(sp)
ffffffffc02028b6:	690a                	ld	s2,128(sp)
ffffffffc02028b8:	79e6                	ld	s3,120(sp)
ffffffffc02028ba:	7a46                	ld	s4,112(sp)
ffffffffc02028bc:	7aa6                	ld	s5,104(sp)
ffffffffc02028be:	7b06                	ld	s6,96(sp)
ffffffffc02028c0:	6be6                	ld	s7,88(sp)
ffffffffc02028c2:	6c46                	ld	s8,80(sp)
ffffffffc02028c4:	6ca6                	ld	s9,72(sp)
ffffffffc02028c6:	6d06                	ld	s10,64(sp)
ffffffffc02028c8:	7de2                	ld	s11,56(sp)
ffffffffc02028ca:	610d                	addi	sp,sp,160
ffffffffc02028cc:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02028ce:	0000f797          	auipc	a5,0xf
ffffffffc02028d2:	b9a78793          	addi	a5,a5,-1126 # ffffffffc0211468 <sm>
ffffffffc02028d6:	639c                	ld	a5,0(a5)
ffffffffc02028d8:	00003517          	auipc	a0,0x3
ffffffffc02028dc:	f3850513          	addi	a0,a0,-200 # ffffffffc0205810 <default_pmm_manager+0x758>
    return listelm->next;
ffffffffc02028e0:	0000f417          	auipc	s0,0xf
ffffffffc02028e4:	ba040413          	addi	s0,s0,-1120 # ffffffffc0211480 <free_area>
ffffffffc02028e8:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc02028ea:	4785                	li	a5,1
ffffffffc02028ec:	0000f717          	auipc	a4,0xf
ffffffffc02028f0:	b8f72223          	sw	a5,-1148(a4) # ffffffffc0211470 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02028f4:	fcafd0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02028f8:	641c                	ld	a5,8(s0)
check_swap(void)
{
     // backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list)
ffffffffc02028fa:	30878d63          	beq	a5,s0,ffffffffc0202c14 <swap_init+0x3b6>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02028fe:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202902:	8305                	srli	a4,a4,0x1
     {
          struct Page *p = le2page(le, page_link);
          assert(PageProperty(p));
ffffffffc0202904:	8b05                	andi	a4,a4,1
ffffffffc0202906:	30070b63          	beqz	a4,ffffffffc0202c1c <swap_init+0x3be>
     int ret, count = 0, total = 0, i;
ffffffffc020290a:	4481                	li	s1,0
ffffffffc020290c:	4901                	li	s2,0
ffffffffc020290e:	a031                	j	ffffffffc020291a <swap_init+0xbc>
ffffffffc0202910:	fe87b703          	ld	a4,-24(a5)
          assert(PageProperty(p));
ffffffffc0202914:	8b09                	andi	a4,a4,2
ffffffffc0202916:	30070363          	beqz	a4,ffffffffc0202c1c <swap_init+0x3be>
          count++, total += p->property;
ffffffffc020291a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020291e:	679c                	ld	a5,8(a5)
ffffffffc0202920:	2905                	addiw	s2,s2,1
ffffffffc0202922:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list)
ffffffffc0202924:	fe8796e3          	bne	a5,s0,ffffffffc0202910 <swap_init+0xb2>
ffffffffc0202928:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc020292a:	e55fe0ef          	jal	ra,ffffffffc020177e <nr_free_pages>
ffffffffc020292e:	5d351b63          	bne	a0,s3,ffffffffc0202f04 <swap_init+0x6a6>
     cprintf("BEGIN check_swap: count %d, total %d\n", count, total);
ffffffffc0202932:	8626                	mv	a2,s1
ffffffffc0202934:	85ca                	mv	a1,s2
ffffffffc0202936:	00003517          	auipc	a0,0x3
ffffffffc020293a:	ef250513          	addi	a0,a0,-270 # ffffffffc0205828 <default_pmm_manager+0x770>
ffffffffc020293e:	f80fd0ef          	jal	ra,ffffffffc02000be <cprintf>

     // now we set the phy pages env
     struct mm_struct *mm = mm_create();
ffffffffc0202942:	33f000ef          	jal	ra,ffffffffc0203480 <mm_create>
ffffffffc0202946:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc0202948:	52050e63          	beqz	a0,ffffffffc0202e84 <swap_init+0x626>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc020294c:	0000f797          	auipc	a5,0xf
ffffffffc0202950:	c4c78793          	addi	a5,a5,-948 # ffffffffc0211598 <check_mm_struct>
ffffffffc0202954:	639c                	ld	a5,0(a5)
ffffffffc0202956:	54079763          	bnez	a5,ffffffffc0202ea4 <swap_init+0x646>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020295a:	0000f797          	auipc	a5,0xf
ffffffffc020295e:	afe78793          	addi	a5,a5,-1282 # ffffffffc0211458 <boot_pgdir>
ffffffffc0202962:	6398                	ld	a4,0(a5)
     check_mm_struct = mm;
ffffffffc0202964:	0000f797          	auipc	a5,0xf
ffffffffc0202968:	c2a7ba23          	sd	a0,-972(a5) # ffffffffc0211598 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc020296c:	631c                	ld	a5,0(a4)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020296e:	ec3a                	sd	a4,24(sp)
ffffffffc0202970:	ed18                	sd	a4,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0202972:	54079963          	bnez	a5,ffffffffc0202ec4 <swap_init+0x666>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202976:	6599                	lui	a1,0x6
ffffffffc0202978:	460d                	li	a2,3
ffffffffc020297a:	6505                	lui	a0,0x1
ffffffffc020297c:	351000ef          	jal	ra,ffffffffc02034cc <vma_create>
ffffffffc0202980:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202982:	56050163          	beqz	a0,ffffffffc0202ee4 <swap_init+0x686>

     insert_vma_struct(mm, vma);
ffffffffc0202986:	855e                	mv	a0,s7
ffffffffc0202988:	3b1000ef          	jal	ra,ffffffffc0203538 <insert_vma_struct>

     // setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc020298c:	00003517          	auipc	a0,0x3
ffffffffc0202990:	f0c50513          	addi	a0,a0,-244 # ffffffffc0205898 <default_pmm_manager+0x7e0>
ffffffffc0202994:	f2afd0ef          	jal	ra,ffffffffc02000be <cprintf>
     pte_t *temp_ptep = NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202998:	018bb503          	ld	a0,24(s7)
ffffffffc020299c:	4605                	li	a2,1
ffffffffc020299e:	6585                	lui	a1,0x1
ffffffffc02029a0:	e1ffe0ef          	jal	ra,ffffffffc02017be <get_pte>
     assert(temp_ptep != NULL);
ffffffffc02029a4:	44050063          	beqz	a0,ffffffffc0202de4 <swap_init+0x586>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02029a8:	00003517          	auipc	a0,0x3
ffffffffc02029ac:	f4050513          	addi	a0,a0,-192 # ffffffffc02058e8 <default_pmm_manager+0x830>
ffffffffc02029b0:	0000fa17          	auipc	s4,0xf
ffffffffc02029b4:	b08a0a13          	addi	s4,s4,-1272 # ffffffffc02114b8 <check_rp>
ffffffffc02029b8:	f06fd0ef          	jal	ra,ffffffffc02000be <cprintf>

     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc02029bc:	0000fa97          	auipc	s5,0xf
ffffffffc02029c0:	b1ca8a93          	addi	s5,s5,-1252 # ffffffffc02114d8 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02029c4:	89d2                	mv	s3,s4
     {
          check_rp[i] = alloc_page();
ffffffffc02029c6:	4505                	li	a0,1
ffffffffc02029c8:	cc7fe0ef          	jal	ra,ffffffffc020168e <alloc_pages>
ffffffffc02029cc:	00a9b023          	sd	a0,0(s3) # fffffffffff80000 <end+0x3fd6ea60>
          assert(check_rp[i] != NULL);
ffffffffc02029d0:	2c050e63          	beqz	a0,ffffffffc0202cac <swap_init+0x44e>
ffffffffc02029d4:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc02029d6:	8b89                	andi	a5,a5,2
ffffffffc02029d8:	2a079a63          	bnez	a5,ffffffffc0202c8c <swap_init+0x42e>
ffffffffc02029dc:	09a1                	addi	s3,s3,8
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc02029de:	ff5994e3          	bne	s3,s5,ffffffffc02029c6 <swap_init+0x168>
     }
     list_entry_t free_list_store = free_list;
ffffffffc02029e2:	601c                	ld	a5,0(s0)
ffffffffc02029e4:	00843983          	ld	s3,8(s0)
     assert(list_empty(&free_list));

     // assert(alloc_page() == NULL);

     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc02029e8:	0000fd17          	auipc	s10,0xf
ffffffffc02029ec:	ad0d0d13          	addi	s10,s10,-1328 # ffffffffc02114b8 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc02029f0:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc02029f2:	481c                	lw	a5,16(s0)
ffffffffc02029f4:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc02029f6:	0000f797          	auipc	a5,0xf
ffffffffc02029fa:	a887b923          	sd	s0,-1390(a5) # ffffffffc0211488 <free_area+0x8>
ffffffffc02029fe:	0000f797          	auipc	a5,0xf
ffffffffc0202a02:	a887b123          	sd	s0,-1406(a5) # ffffffffc0211480 <free_area>
     nr_free = 0;
ffffffffc0202a06:	0000f797          	auipc	a5,0xf
ffffffffc0202a0a:	a807a523          	sw	zero,-1398(a5) # ffffffffc0211490 <free_area+0x10>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
     {
          free_pages(check_rp[i], 1);
ffffffffc0202a0e:	000d3503          	ld	a0,0(s10)
ffffffffc0202a12:	4585                	li	a1,1
ffffffffc0202a14:	0d21                	addi	s10,s10,8
ffffffffc0202a16:	d23fe0ef          	jal	ra,ffffffffc0201738 <free_pages>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc0202a1a:	ff5d1ae3          	bne	s10,s5,ffffffffc0202a0e <swap_init+0x1b0>
     }
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202a1e:	01042d03          	lw	s10,16(s0)
ffffffffc0202a22:	4791                	li	a5,4
ffffffffc0202a24:	3afd1063          	bne	s10,a5,ffffffffc0202dc4 <swap_init+0x566>

     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202a28:	00003517          	auipc	a0,0x3
ffffffffc0202a2c:	f4850513          	addi	a0,a0,-184 # ffffffffc0205970 <default_pmm_manager+0x8b8>
ffffffffc0202a30:	e8efd0ef          	jal	ra,ffffffffc02000be <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202a34:	6705                	lui	a4,0x1
     // setup initial vir_page<->phy_page environment for page relpacement algorithm

     pgfault_num = 0;
ffffffffc0202a36:	0000f797          	auipc	a5,0xf
ffffffffc0202a3a:	a207af23          	sw	zero,-1474(a5) # ffffffffc0211474 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202a3e:	46a9                	li	a3,10
     pgfault_num = 0;
ffffffffc0202a40:	0000fd97          	auipc	s11,0xf
ffffffffc0202a44:	a34d8d93          	addi	s11,s11,-1484 # ffffffffc0211474 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202a48:	00d70023          	sb	a3,0(a4) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
     assert(pgfault_num == 1);
ffffffffc0202a4c:	000da783          	lw	a5,0(s11)
ffffffffc0202a50:	4605                	li	a2,1
ffffffffc0202a52:	2781                	sext.w	a5,a5
ffffffffc0202a54:	32c79863          	bne	a5,a2,ffffffffc0202d84 <swap_init+0x526>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202a58:	00d70823          	sb	a3,16(a4)
     assert(pgfault_num == 1);
ffffffffc0202a5c:	000da703          	lw	a4,0(s11)
ffffffffc0202a60:	2701                	sext.w	a4,a4
ffffffffc0202a62:	34f71163          	bne	a4,a5,ffffffffc0202da4 <swap_init+0x546>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202a66:	6709                	lui	a4,0x2
ffffffffc0202a68:	46ad                	li	a3,11
ffffffffc0202a6a:	00d70023          	sb	a3,0(a4) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
     assert(pgfault_num == 2);
ffffffffc0202a6e:	000da783          	lw	a5,0(s11)
ffffffffc0202a72:	4609                	li	a2,2
ffffffffc0202a74:	2781                	sext.w	a5,a5
ffffffffc0202a76:	28c79763          	bne	a5,a2,ffffffffc0202d04 <swap_init+0x4a6>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202a7a:	00d70823          	sb	a3,16(a4)
     assert(pgfault_num == 2);
ffffffffc0202a7e:	000da703          	lw	a4,0(s11)
ffffffffc0202a82:	2701                	sext.w	a4,a4
ffffffffc0202a84:	2af71063          	bne	a4,a5,ffffffffc0202d24 <swap_init+0x4c6>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202a88:	670d                	lui	a4,0x3
ffffffffc0202a8a:	46b1                	li	a3,12
ffffffffc0202a8c:	00d70023          	sb	a3,0(a4) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
     assert(pgfault_num == 3);
ffffffffc0202a90:	000da783          	lw	a5,0(s11)
ffffffffc0202a94:	460d                	li	a2,3
ffffffffc0202a96:	2781                	sext.w	a5,a5
ffffffffc0202a98:	2ac79663          	bne	a5,a2,ffffffffc0202d44 <swap_init+0x4e6>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202a9c:	00d70823          	sb	a3,16(a4)
     assert(pgfault_num == 3);
ffffffffc0202aa0:	000da703          	lw	a4,0(s11)
ffffffffc0202aa4:	2701                	sext.w	a4,a4
ffffffffc0202aa6:	2af71f63          	bne	a4,a5,ffffffffc0202d64 <swap_init+0x506>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202aaa:	6711                	lui	a4,0x4
ffffffffc0202aac:	46b5                	li	a3,13
ffffffffc0202aae:	00d70023          	sb	a3,0(a4) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
     assert(pgfault_num == 4);
ffffffffc0202ab2:	000da783          	lw	a5,0(s11)
ffffffffc0202ab6:	2781                	sext.w	a5,a5
ffffffffc0202ab8:	35a79663          	bne	a5,s10,ffffffffc0202e04 <swap_init+0x5a6>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0202abc:	00d70823          	sb	a3,16(a4)
     assert(pgfault_num == 4);
ffffffffc0202ac0:	000da703          	lw	a4,0(s11)
ffffffffc0202ac4:	2701                	sext.w	a4,a4
ffffffffc0202ac6:	34f71f63          	bne	a4,a5,ffffffffc0202e24 <swap_init+0x5c6>

     check_content_set();
     assert(nr_free == 0);
ffffffffc0202aca:	481c                	lw	a5,16(s0)
ffffffffc0202acc:	36079c63          	bnez	a5,ffffffffc0202e44 <swap_init+0x5e6>
ffffffffc0202ad0:	0000f797          	auipc	a5,0xf
ffffffffc0202ad4:	a0878793          	addi	a5,a5,-1528 # ffffffffc02114d8 <swap_in_seq_no>
ffffffffc0202ad8:	0000f717          	auipc	a4,0xf
ffffffffc0202adc:	a2870713          	addi	a4,a4,-1496 # ffffffffc0211500 <swap_out_seq_no>
ffffffffc0202ae0:	0000f617          	auipc	a2,0xf
ffffffffc0202ae4:	a2060613          	addi	a2,a2,-1504 # ffffffffc0211500 <swap_out_seq_no>
     for (i = 0; i < MAX_SEQ_NO; i++)
          swap_out_seq_no[i] = swap_in_seq_no[i] = -1;
ffffffffc0202ae8:	56fd                	li	a3,-1
ffffffffc0202aea:	c394                	sw	a3,0(a5)
ffffffffc0202aec:	c314                	sw	a3,0(a4)
ffffffffc0202aee:	0791                	addi	a5,a5,4
ffffffffc0202af0:	0711                	addi	a4,a4,4
     for (i = 0; i < MAX_SEQ_NO; i++)
ffffffffc0202af2:	fec79ce3          	bne	a5,a2,ffffffffc0202aea <swap_init+0x28c>
ffffffffc0202af6:	0000f697          	auipc	a3,0xf
ffffffffc0202afa:	a6a68693          	addi	a3,a3,-1430 # ffffffffc0211560 <check_ptep>
ffffffffc0202afe:	0000f817          	auipc	a6,0xf
ffffffffc0202b02:	9ba80813          	addi	a6,a6,-1606 # ffffffffc02114b8 <check_rp>
ffffffffc0202b06:	6705                	lui	a4,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202b08:	0000fc17          	auipc	s8,0xf
ffffffffc0202b0c:	958c0c13          	addi	s8,s8,-1704 # ffffffffc0211460 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b10:	0000fc97          	auipc	s9,0xf
ffffffffc0202b14:	9a0c8c93          	addi	s9,s9,-1632 # ffffffffc02114b0 <pages>
ffffffffc0202b18:	00003d17          	auipc	s10,0x3
ffffffffc0202b1c:	730d0d13          	addi	s10,s10,1840 # ffffffffc0206248 <nbase>

     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
     {
          check_ptep[i] = 0;
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202b20:	6562                	ld	a0,24(sp)
ffffffffc0202b22:	85ba                	mv	a1,a4
          check_ptep[i] = 0;
ffffffffc0202b24:	0006b023          	sd	zero,0(a3)
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202b28:	4601                	li	a2,0
ffffffffc0202b2a:	e842                	sd	a6,16(sp)
ffffffffc0202b2c:	e43a                	sd	a4,8(sp)
          check_ptep[i] = 0;
ffffffffc0202b2e:	e036                	sd	a3,0(sp)
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202b30:	c8ffe0ef          	jal	ra,ffffffffc02017be <get_pte>
ffffffffc0202b34:	6682                	ld	a3,0(sp)
          // cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
          assert(check_ptep[i] != NULL);
ffffffffc0202b36:	6722                	ld	a4,8(sp)
ffffffffc0202b38:	6842                	ld	a6,16(sp)
          check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0);
ffffffffc0202b3a:	e288                	sd	a0,0(a3)
          assert(check_ptep[i] != NULL);
ffffffffc0202b3c:	18050863          	beqz	a0,ffffffffc0202ccc <swap_init+0x46e>
          assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202b40:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202b42:	0017f613          	andi	a2,a5,1
ffffffffc0202b46:	10060b63          	beqz	a2,ffffffffc0202c5c <swap_init+0x3fe>
    if (PPN(pa) >= npage) {
ffffffffc0202b4a:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202b4e:	078a                	slli	a5,a5,0x2
ffffffffc0202b50:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202b52:	12c7f163          	bleu	a2,a5,ffffffffc0202c74 <swap_init+0x416>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b56:	000d3603          	ld	a2,0(s10)
ffffffffc0202b5a:	000cb583          	ld	a1,0(s9)
ffffffffc0202b5e:	00083503          	ld	a0,0(a6)
ffffffffc0202b62:	8f91                	sub	a5,a5,a2
ffffffffc0202b64:	00379613          	slli	a2,a5,0x3
ffffffffc0202b68:	97b2                	add	a5,a5,a2
ffffffffc0202b6a:	078e                	slli	a5,a5,0x3
ffffffffc0202b6c:	97ae                	add	a5,a5,a1
ffffffffc0202b6e:	0cf51763          	bne	a0,a5,ffffffffc0202c3c <swap_init+0x3de>
ffffffffc0202b72:	6785                	lui	a5,0x1
ffffffffc0202b74:	973e                	add	a4,a4,a5
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc0202b76:	6795                	lui	a5,0x5
ffffffffc0202b78:	06a1                	addi	a3,a3,8
ffffffffc0202b7a:	0821                	addi	a6,a6,8
ffffffffc0202b7c:	faf712e3          	bne	a4,a5,ffffffffc0202b20 <swap_init+0x2c2>
          assert((*check_ptep[i] & PTE_V));
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202b80:	00003517          	auipc	a0,0x3
ffffffffc0202b84:	eb850513          	addi	a0,a0,-328 # ffffffffc0205a38 <default_pmm_manager+0x980>
ffffffffc0202b88:	d36fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     cprintf("当前缺页次数%d\n", pgfault_num);
ffffffffc0202b8c:	000da583          	lw	a1,0(s11)
ffffffffc0202b90:	00003517          	auipc	a0,0x3
ffffffffc0202b94:	ed050513          	addi	a0,a0,-304 # ffffffffc0205a60 <default_pmm_manager+0x9a8>
ffffffffc0202b98:	2581                	sext.w	a1,a1
ffffffffc0202b9a:	d24fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     int ret = sm->check_swap();
ffffffffc0202b9e:	0000f797          	auipc	a5,0xf
ffffffffc0202ba2:	8ca78793          	addi	a5,a5,-1846 # ffffffffc0211468 <sm>
ffffffffc0202ba6:	639c                	ld	a5,0(a5)
ffffffffc0202ba8:	7f9c                	ld	a5,56(a5)
ffffffffc0202baa:	9782                	jalr	a5

     // now access the virt pages to test  page relpacement algorithm
     ret = check_content_access();
     assert(ret == 0);
ffffffffc0202bac:	2a051c63          	bnez	a0,ffffffffc0202e64 <swap_init+0x606>

     // restore kernel mem env
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
     {
          free_pages(check_rp[i], 1);
ffffffffc0202bb0:	000a3503          	ld	a0,0(s4)
ffffffffc0202bb4:	4585                	li	a1,1
ffffffffc0202bb6:	0a21                	addi	s4,s4,8
ffffffffc0202bb8:	b81fe0ef          	jal	ra,ffffffffc0201738 <free_pages>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++)
ffffffffc0202bbc:	ff5a1ae3          	bne	s4,s5,ffffffffc0202bb0 <swap_init+0x352>
     }

     // free_page(pte2page(*temp_ptep));

     mm_destroy(mm);
ffffffffc0202bc0:	855e                	mv	a0,s7
ffffffffc0202bc2:	245000ef          	jal	ra,ffffffffc0203606 <mm_destroy>

     nr_free = nr_free_store;
ffffffffc0202bc6:	77a2                	ld	a5,40(sp)
ffffffffc0202bc8:	0000f717          	auipc	a4,0xf
ffffffffc0202bcc:	8cf72423          	sw	a5,-1848(a4) # ffffffffc0211490 <free_area+0x10>
     free_list = free_list_store;
ffffffffc0202bd0:	7782                	ld	a5,32(sp)
ffffffffc0202bd2:	0000f717          	auipc	a4,0xf
ffffffffc0202bd6:	8af73723          	sd	a5,-1874(a4) # ffffffffc0211480 <free_area>
ffffffffc0202bda:	0000f797          	auipc	a5,0xf
ffffffffc0202bde:	8b37b723          	sd	s3,-1874(a5) # ffffffffc0211488 <free_area+0x8>

     le = &free_list;
     while ((le = list_next(le)) != &free_list)
ffffffffc0202be2:	00898a63          	beq	s3,s0,ffffffffc0202bf6 <swap_init+0x398>
     {
          struct Page *p = le2page(le, page_link);
          count--, total -= p->property;
ffffffffc0202be6:	ff89a783          	lw	a5,-8(s3)
    return listelm->next;
ffffffffc0202bea:	0089b983          	ld	s3,8(s3)
ffffffffc0202bee:	397d                	addiw	s2,s2,-1
ffffffffc0202bf0:	9c9d                	subw	s1,s1,a5
     while ((le = list_next(le)) != &free_list)
ffffffffc0202bf2:	fe899ae3          	bne	s3,s0,ffffffffc0202be6 <swap_init+0x388>
     }
     cprintf("count is %d, total is %d\n", count, total);
ffffffffc0202bf6:	8626                	mv	a2,s1
ffffffffc0202bf8:	85ca                	mv	a1,s2
ffffffffc0202bfa:	00003517          	auipc	a0,0x3
ffffffffc0202bfe:	e8e50513          	addi	a0,a0,-370 # ffffffffc0205a88 <default_pmm_manager+0x9d0>
ffffffffc0202c02:	cbcfd0ef          	jal	ra,ffffffffc02000be <cprintf>
     // assert(count == 0);

     cprintf("check_swap() succeeded!\n");
ffffffffc0202c06:	00003517          	auipc	a0,0x3
ffffffffc0202c0a:	ea250513          	addi	a0,a0,-350 # ffffffffc0205aa8 <default_pmm_manager+0x9f0>
ffffffffc0202c0e:	cb0fd0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0202c12:	b971                	j	ffffffffc02028ae <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc0202c14:	4481                	li	s1,0
ffffffffc0202c16:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list)
ffffffffc0202c18:	4981                	li	s3,0
ffffffffc0202c1a:	bb01                	j	ffffffffc020292a <swap_init+0xcc>
          assert(PageProperty(p));
ffffffffc0202c1c:	00002697          	auipc	a3,0x2
ffffffffc0202c20:	0f468693          	addi	a3,a3,244 # ffffffffc0204d10 <commands+0x860>
ffffffffc0202c24:	00002617          	auipc	a2,0x2
ffffffffc0202c28:	0fc60613          	addi	a2,a2,252 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202c2c:	0b900593          	li	a1,185
ffffffffc0202c30:	00003517          	auipc	a0,0x3
ffffffffc0202c34:	bd050513          	addi	a0,a0,-1072 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202c38:	f3cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202c3c:	00003697          	auipc	a3,0x3
ffffffffc0202c40:	dd468693          	addi	a3,a3,-556 # ffffffffc0205a10 <default_pmm_manager+0x958>
ffffffffc0202c44:	00002617          	auipc	a2,0x2
ffffffffc0202c48:	0dc60613          	addi	a2,a2,220 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202c4c:	0fb00593          	li	a1,251
ffffffffc0202c50:	00003517          	auipc	a0,0x3
ffffffffc0202c54:	bb050513          	addi	a0,a0,-1104 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202c58:	f1cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202c5c:	00002617          	auipc	a2,0x2
ffffffffc0202c60:	74c60613          	addi	a2,a2,1868 # ffffffffc02053a8 <default_pmm_manager+0x2f0>
ffffffffc0202c64:	07000593          	li	a1,112
ffffffffc0202c68:	00002517          	auipc	a0,0x2
ffffffffc0202c6c:	56850513          	addi	a0,a0,1384 # ffffffffc02051d0 <default_pmm_manager+0x118>
ffffffffc0202c70:	f04fd0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202c74:	00002617          	auipc	a2,0x2
ffffffffc0202c78:	53c60613          	addi	a2,a2,1340 # ffffffffc02051b0 <default_pmm_manager+0xf8>
ffffffffc0202c7c:	06500593          	li	a1,101
ffffffffc0202c80:	00002517          	auipc	a0,0x2
ffffffffc0202c84:	55050513          	addi	a0,a0,1360 # ffffffffc02051d0 <default_pmm_manager+0x118>
ffffffffc0202c88:	eecfd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0202c8c:	00003697          	auipc	a3,0x3
ffffffffc0202c90:	c9c68693          	addi	a3,a3,-868 # ffffffffc0205928 <default_pmm_manager+0x870>
ffffffffc0202c94:	00002617          	auipc	a2,0x2
ffffffffc0202c98:	08c60613          	addi	a2,a2,140 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202c9c:	0db00593          	li	a1,219
ffffffffc0202ca0:	00003517          	auipc	a0,0x3
ffffffffc0202ca4:	b6050513          	addi	a0,a0,-1184 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202ca8:	eccfd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(check_rp[i] != NULL);
ffffffffc0202cac:	00003697          	auipc	a3,0x3
ffffffffc0202cb0:	c6468693          	addi	a3,a3,-924 # ffffffffc0205910 <default_pmm_manager+0x858>
ffffffffc0202cb4:	00002617          	auipc	a2,0x2
ffffffffc0202cb8:	06c60613          	addi	a2,a2,108 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202cbc:	0da00593          	li	a1,218
ffffffffc0202cc0:	00003517          	auipc	a0,0x3
ffffffffc0202cc4:	b4050513          	addi	a0,a0,-1216 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202cc8:	eacfd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(check_ptep[i] != NULL);
ffffffffc0202ccc:	00003697          	auipc	a3,0x3
ffffffffc0202cd0:	d2c68693          	addi	a3,a3,-724 # ffffffffc02059f8 <default_pmm_manager+0x940>
ffffffffc0202cd4:	00002617          	auipc	a2,0x2
ffffffffc0202cd8:	04c60613          	addi	a2,a2,76 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202cdc:	0fa00593          	li	a1,250
ffffffffc0202ce0:	00003517          	auipc	a0,0x3
ffffffffc0202ce4:	b2050513          	addi	a0,a0,-1248 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202ce8:	e8cfd0ef          	jal	ra,ffffffffc0200374 <__panic>
          panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202cec:	00003617          	auipc	a2,0x3
ffffffffc0202cf0:	af460613          	addi	a2,a2,-1292 # ffffffffc02057e0 <default_pmm_manager+0x728>
ffffffffc0202cf4:	02700593          	li	a1,39
ffffffffc0202cf8:	00003517          	auipc	a0,0x3
ffffffffc0202cfc:	b0850513          	addi	a0,a0,-1272 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202d00:	e74fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 2);
ffffffffc0202d04:	00003697          	auipc	a3,0x3
ffffffffc0202d08:	cac68693          	addi	a3,a3,-852 # ffffffffc02059b0 <default_pmm_manager+0x8f8>
ffffffffc0202d0c:	00002617          	auipc	a2,0x2
ffffffffc0202d10:	01460613          	addi	a2,a2,20 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202d14:	09300593          	li	a1,147
ffffffffc0202d18:	00003517          	auipc	a0,0x3
ffffffffc0202d1c:	ae850513          	addi	a0,a0,-1304 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202d20:	e54fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 2);
ffffffffc0202d24:	00003697          	auipc	a3,0x3
ffffffffc0202d28:	c8c68693          	addi	a3,a3,-884 # ffffffffc02059b0 <default_pmm_manager+0x8f8>
ffffffffc0202d2c:	00002617          	auipc	a2,0x2
ffffffffc0202d30:	ff460613          	addi	a2,a2,-12 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202d34:	09500593          	li	a1,149
ffffffffc0202d38:	00003517          	auipc	a0,0x3
ffffffffc0202d3c:	ac850513          	addi	a0,a0,-1336 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202d40:	e34fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 3);
ffffffffc0202d44:	00003697          	auipc	a3,0x3
ffffffffc0202d48:	c8468693          	addi	a3,a3,-892 # ffffffffc02059c8 <default_pmm_manager+0x910>
ffffffffc0202d4c:	00002617          	auipc	a2,0x2
ffffffffc0202d50:	fd460613          	addi	a2,a2,-44 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202d54:	09700593          	li	a1,151
ffffffffc0202d58:	00003517          	auipc	a0,0x3
ffffffffc0202d5c:	aa850513          	addi	a0,a0,-1368 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202d60:	e14fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 3);
ffffffffc0202d64:	00003697          	auipc	a3,0x3
ffffffffc0202d68:	c6468693          	addi	a3,a3,-924 # ffffffffc02059c8 <default_pmm_manager+0x910>
ffffffffc0202d6c:	00002617          	auipc	a2,0x2
ffffffffc0202d70:	fb460613          	addi	a2,a2,-76 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202d74:	09900593          	li	a1,153
ffffffffc0202d78:	00003517          	auipc	a0,0x3
ffffffffc0202d7c:	a8850513          	addi	a0,a0,-1400 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202d80:	df4fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 1);
ffffffffc0202d84:	00003697          	auipc	a3,0x3
ffffffffc0202d88:	c1468693          	addi	a3,a3,-1004 # ffffffffc0205998 <default_pmm_manager+0x8e0>
ffffffffc0202d8c:	00002617          	auipc	a2,0x2
ffffffffc0202d90:	f9460613          	addi	a2,a2,-108 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202d94:	08f00593          	li	a1,143
ffffffffc0202d98:	00003517          	auipc	a0,0x3
ffffffffc0202d9c:	a6850513          	addi	a0,a0,-1432 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202da0:	dd4fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 1);
ffffffffc0202da4:	00003697          	auipc	a3,0x3
ffffffffc0202da8:	bf468693          	addi	a3,a3,-1036 # ffffffffc0205998 <default_pmm_manager+0x8e0>
ffffffffc0202dac:	00002617          	auipc	a2,0x2
ffffffffc0202db0:	f7460613          	addi	a2,a2,-140 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202db4:	09100593          	li	a1,145
ffffffffc0202db8:	00003517          	auipc	a0,0x3
ffffffffc0202dbc:	a4850513          	addi	a0,a0,-1464 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202dc0:	db4fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202dc4:	00003697          	auipc	a3,0x3
ffffffffc0202dc8:	b8468693          	addi	a3,a3,-1148 # ffffffffc0205948 <default_pmm_manager+0x890>
ffffffffc0202dcc:	00002617          	auipc	a2,0x2
ffffffffc0202dd0:	f5460613          	addi	a2,a2,-172 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202dd4:	0e900593          	li	a1,233
ffffffffc0202dd8:	00003517          	auipc	a0,0x3
ffffffffc0202ddc:	a2850513          	addi	a0,a0,-1496 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202de0:	d94fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(temp_ptep != NULL);
ffffffffc0202de4:	00003697          	auipc	a3,0x3
ffffffffc0202de8:	aec68693          	addi	a3,a3,-1300 # ffffffffc02058d0 <default_pmm_manager+0x818>
ffffffffc0202dec:	00002617          	auipc	a2,0x2
ffffffffc0202df0:	f3460613          	addi	a2,a2,-204 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202df4:	0d400593          	li	a1,212
ffffffffc0202df8:	00003517          	auipc	a0,0x3
ffffffffc0202dfc:	a0850513          	addi	a0,a0,-1528 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202e00:	d74fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 4);
ffffffffc0202e04:	00003697          	auipc	a3,0x3
ffffffffc0202e08:	bdc68693          	addi	a3,a3,-1060 # ffffffffc02059e0 <default_pmm_manager+0x928>
ffffffffc0202e0c:	00002617          	auipc	a2,0x2
ffffffffc0202e10:	f1460613          	addi	a2,a2,-236 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202e14:	09b00593          	li	a1,155
ffffffffc0202e18:	00003517          	auipc	a0,0x3
ffffffffc0202e1c:	9e850513          	addi	a0,a0,-1560 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202e20:	d54fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgfault_num == 4);
ffffffffc0202e24:	00003697          	auipc	a3,0x3
ffffffffc0202e28:	bbc68693          	addi	a3,a3,-1092 # ffffffffc02059e0 <default_pmm_manager+0x928>
ffffffffc0202e2c:	00002617          	auipc	a2,0x2
ffffffffc0202e30:	ef460613          	addi	a2,a2,-268 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202e34:	09d00593          	li	a1,157
ffffffffc0202e38:	00003517          	auipc	a0,0x3
ffffffffc0202e3c:	9c850513          	addi	a0,a0,-1592 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202e40:	d34fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(nr_free == 0);
ffffffffc0202e44:	00002697          	auipc	a3,0x2
ffffffffc0202e48:	0b468693          	addi	a3,a3,180 # ffffffffc0204ef8 <commands+0xa48>
ffffffffc0202e4c:	00002617          	auipc	a2,0x2
ffffffffc0202e50:	ed460613          	addi	a2,a2,-300 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202e54:	0f100593          	li	a1,241
ffffffffc0202e58:	00003517          	auipc	a0,0x3
ffffffffc0202e5c:	9a850513          	addi	a0,a0,-1624 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202e60:	d14fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(ret == 0);
ffffffffc0202e64:	00003697          	auipc	a3,0x3
ffffffffc0202e68:	c1468693          	addi	a3,a3,-1004 # ffffffffc0205a78 <default_pmm_manager+0x9c0>
ffffffffc0202e6c:	00002617          	auipc	a2,0x2
ffffffffc0202e70:	eb460613          	addi	a2,a2,-332 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202e74:	10300593          	li	a1,259
ffffffffc0202e78:	00003517          	auipc	a0,0x3
ffffffffc0202e7c:	98850513          	addi	a0,a0,-1656 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202e80:	cf4fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(mm != NULL);
ffffffffc0202e84:	00003697          	auipc	a3,0x3
ffffffffc0202e88:	9cc68693          	addi	a3,a3,-1588 # ffffffffc0205850 <default_pmm_manager+0x798>
ffffffffc0202e8c:	00002617          	auipc	a2,0x2
ffffffffc0202e90:	e9460613          	addi	a2,a2,-364 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202e94:	0c100593          	li	a1,193
ffffffffc0202e98:	00003517          	auipc	a0,0x3
ffffffffc0202e9c:	96850513          	addi	a0,a0,-1688 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202ea0:	cd4fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0202ea4:	00003697          	auipc	a3,0x3
ffffffffc0202ea8:	9bc68693          	addi	a3,a3,-1604 # ffffffffc0205860 <default_pmm_manager+0x7a8>
ffffffffc0202eac:	00002617          	auipc	a2,0x2
ffffffffc0202eb0:	e7460613          	addi	a2,a2,-396 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202eb4:	0c400593          	li	a1,196
ffffffffc0202eb8:	00003517          	auipc	a0,0x3
ffffffffc0202ebc:	94850513          	addi	a0,a0,-1720 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202ec0:	cb4fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0202ec4:	00003697          	auipc	a3,0x3
ffffffffc0202ec8:	9b468693          	addi	a3,a3,-1612 # ffffffffc0205878 <default_pmm_manager+0x7c0>
ffffffffc0202ecc:	00002617          	auipc	a2,0x2
ffffffffc0202ed0:	e5460613          	addi	a2,a2,-428 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202ed4:	0c900593          	li	a1,201
ffffffffc0202ed8:	00003517          	auipc	a0,0x3
ffffffffc0202edc:	92850513          	addi	a0,a0,-1752 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202ee0:	c94fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(vma != NULL);
ffffffffc0202ee4:	00003697          	auipc	a3,0x3
ffffffffc0202ee8:	9a468693          	addi	a3,a3,-1628 # ffffffffc0205888 <default_pmm_manager+0x7d0>
ffffffffc0202eec:	00002617          	auipc	a2,0x2
ffffffffc0202ef0:	e3460613          	addi	a2,a2,-460 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202ef4:	0cc00593          	li	a1,204
ffffffffc0202ef8:	00003517          	auipc	a0,0x3
ffffffffc0202efc:	90850513          	addi	a0,a0,-1784 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202f00:	c74fd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(total == nr_free_pages());
ffffffffc0202f04:	00002697          	auipc	a3,0x2
ffffffffc0202f08:	e4c68693          	addi	a3,a3,-436 # ffffffffc0204d50 <commands+0x8a0>
ffffffffc0202f0c:	00002617          	auipc	a2,0x2
ffffffffc0202f10:	e1460613          	addi	a2,a2,-492 # ffffffffc0204d20 <commands+0x870>
ffffffffc0202f14:	0bc00593          	li	a1,188
ffffffffc0202f18:	00003517          	auipc	a0,0x3
ffffffffc0202f1c:	8e850513          	addi	a0,a0,-1816 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0202f20:	c54fd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0202f24 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0202f24:	0000e797          	auipc	a5,0xe
ffffffffc0202f28:	54478793          	addi	a5,a5,1348 # ffffffffc0211468 <sm>
ffffffffc0202f2c:	639c                	ld	a5,0(a5)
ffffffffc0202f2e:	0107b303          	ld	t1,16(a5)
ffffffffc0202f32:	8302                	jr	t1

ffffffffc0202f34 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0202f34:	0000e797          	auipc	a5,0xe
ffffffffc0202f38:	53478793          	addi	a5,a5,1332 # ffffffffc0211468 <sm>
ffffffffc0202f3c:	639c                	ld	a5,0(a5)
ffffffffc0202f3e:	0207b303          	ld	t1,32(a5)
ffffffffc0202f42:	8302                	jr	t1

ffffffffc0202f44 <swap_out>:
{
ffffffffc0202f44:	711d                	addi	sp,sp,-96
ffffffffc0202f46:	ec86                	sd	ra,88(sp)
ffffffffc0202f48:	e8a2                	sd	s0,80(sp)
ffffffffc0202f4a:	e4a6                	sd	s1,72(sp)
ffffffffc0202f4c:	e0ca                	sd	s2,64(sp)
ffffffffc0202f4e:	fc4e                	sd	s3,56(sp)
ffffffffc0202f50:	f852                	sd	s4,48(sp)
ffffffffc0202f52:	f456                	sd	s5,40(sp)
ffffffffc0202f54:	f05a                	sd	s6,32(sp)
ffffffffc0202f56:	ec5e                	sd	s7,24(sp)
ffffffffc0202f58:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++i)
ffffffffc0202f5a:	cde9                	beqz	a1,ffffffffc0203034 <swap_out+0xf0>
ffffffffc0202f5c:	8ab2                	mv	s5,a2
ffffffffc0202f5e:	892a                	mv	s2,a0
ffffffffc0202f60:	8a2e                	mv	s4,a1
ffffffffc0202f62:	4401                	li	s0,0
ffffffffc0202f64:	0000e997          	auipc	s3,0xe
ffffffffc0202f68:	50498993          	addi	s3,s3,1284 # ffffffffc0211468 <sm>
               cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0202f6c:	00003b17          	auipc	s6,0x3
ffffffffc0202f70:	bbcb0b13          	addi	s6,s6,-1092 # ffffffffc0205b28 <default_pmm_manager+0xa70>
               cprintf("SWAP: failed to save\n");
ffffffffc0202f74:	00003b97          	auipc	s7,0x3
ffffffffc0202f78:	b9cb8b93          	addi	s7,s7,-1124 # ffffffffc0205b10 <default_pmm_manager+0xa58>
ffffffffc0202f7c:	a825                	j	ffffffffc0202fb4 <swap_out+0x70>
               cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0202f7e:	67a2                	ld	a5,8(sp)
ffffffffc0202f80:	8626                	mv	a2,s1
ffffffffc0202f82:	85a2                	mv	a1,s0
ffffffffc0202f84:	63b4                	ld	a3,64(a5)
ffffffffc0202f86:	855a                	mv	a0,s6
     for (i = 0; i != n; ++i)
ffffffffc0202f88:	2405                	addiw	s0,s0,1
               cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0202f8a:	82b1                	srli	a3,a3,0xc
ffffffffc0202f8c:	0685                	addi	a3,a3,1
ffffffffc0202f8e:	930fd0ef          	jal	ra,ffffffffc02000be <cprintf>
               *ptep = (page->pra_vaddr / PGSIZE + 1) << 8;
ffffffffc0202f92:	6522                	ld	a0,8(sp)
               free_page(page);
ffffffffc0202f94:	4585                	li	a1,1
               *ptep = (page->pra_vaddr / PGSIZE + 1) << 8;
ffffffffc0202f96:	613c                	ld	a5,64(a0)
ffffffffc0202f98:	83b1                	srli	a5,a5,0xc
ffffffffc0202f9a:	0785                	addi	a5,a5,1
ffffffffc0202f9c:	07a2                	slli	a5,a5,0x8
ffffffffc0202f9e:	00fc3023          	sd	a5,0(s8)
               free_page(page);
ffffffffc0202fa2:	f96fe0ef          	jal	ra,ffffffffc0201738 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0202fa6:	01893503          	ld	a0,24(s2)
ffffffffc0202faa:	85a6                	mv	a1,s1
ffffffffc0202fac:	e98ff0ef          	jal	ra,ffffffffc0202644 <tlb_invalidate>
     for (i = 0; i != n; ++i)
ffffffffc0202fb0:	048a0d63          	beq	s4,s0,ffffffffc020300a <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick); // 调用swap_out_victim，把要换出的页放到page里
ffffffffc0202fb4:	0009b783          	ld	a5,0(s3)
ffffffffc0202fb8:	8656                	mv	a2,s5
ffffffffc0202fba:	002c                	addi	a1,sp,8
ffffffffc0202fbc:	7b9c                	ld	a5,48(a5)
ffffffffc0202fbe:	854a                	mv	a0,s2
ffffffffc0202fc0:	9782                	jalr	a5
          if (r != 0)
ffffffffc0202fc2:	e12d                	bnez	a0,ffffffffc0203024 <swap_out+0xe0>
          v = page->pra_vaddr;                    // 要换出页面的虚拟地址
ffffffffc0202fc4:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0); // 找到页表项指针
ffffffffc0202fc6:	01893503          	ld	a0,24(s2)
ffffffffc0202fca:	4601                	li	a2,0
          v = page->pra_vaddr;                    // 要换出页面的虚拟地址
ffffffffc0202fcc:	63a4                	ld	s1,64(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0); // 找到页表项指针
ffffffffc0202fce:	85a6                	mv	a1,s1
ffffffffc0202fd0:	feefe0ef          	jal	ra,ffffffffc02017be <get_pte>
          assert((*ptep & PTE_V) != 0);           // 判断页表项是否有效
ffffffffc0202fd4:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0); // 找到页表项指针
ffffffffc0202fd6:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);           // 判断页表项是否有效
ffffffffc0202fd8:	8b85                	andi	a5,a5,1
ffffffffc0202fda:	cfb9                	beqz	a5,ffffffffc0203038 <swap_out+0xf4>
          if (swapfs_write((page->pra_vaddr / PGSIZE + 1) << 8, page) != 0)
ffffffffc0202fdc:	65a2                	ld	a1,8(sp)
ffffffffc0202fde:	61bc                	ld	a5,64(a1)
ffffffffc0202fe0:	83b1                	srli	a5,a5,0xc
ffffffffc0202fe2:	00178513          	addi	a0,a5,1
ffffffffc0202fe6:	0522                	slli	a0,a0,0x8
ffffffffc0202fe8:	57b000ef          	jal	ra,ffffffffc0203d62 <swapfs_write>
ffffffffc0202fec:	d949                	beqz	a0,ffffffffc0202f7e <swap_out+0x3a>
               cprintf("SWAP: failed to save\n");
ffffffffc0202fee:	855e                	mv	a0,s7
ffffffffc0202ff0:	8cefd0ef          	jal	ra,ffffffffc02000be <cprintf>
               sm->map_swappable(mm, v, page, 0);
ffffffffc0202ff4:	0009b783          	ld	a5,0(s3)
ffffffffc0202ff8:	6622                	ld	a2,8(sp)
ffffffffc0202ffa:	4681                	li	a3,0
ffffffffc0202ffc:	739c                	ld	a5,32(a5)
ffffffffc0202ffe:	85a6                	mv	a1,s1
ffffffffc0203000:	854a                	mv	a0,s2
     for (i = 0; i != n; ++i)
ffffffffc0203002:	2405                	addiw	s0,s0,1
               sm->map_swappable(mm, v, page, 0);
ffffffffc0203004:	9782                	jalr	a5
     for (i = 0; i != n; ++i)
ffffffffc0203006:	fa8a17e3          	bne	s4,s0,ffffffffc0202fb4 <swap_out+0x70>
}
ffffffffc020300a:	8522                	mv	a0,s0
ffffffffc020300c:	60e6                	ld	ra,88(sp)
ffffffffc020300e:	6446                	ld	s0,80(sp)
ffffffffc0203010:	64a6                	ld	s1,72(sp)
ffffffffc0203012:	6906                	ld	s2,64(sp)
ffffffffc0203014:	79e2                	ld	s3,56(sp)
ffffffffc0203016:	7a42                	ld	s4,48(sp)
ffffffffc0203018:	7aa2                	ld	s5,40(sp)
ffffffffc020301a:	7b02                	ld	s6,32(sp)
ffffffffc020301c:	6be2                	ld	s7,24(sp)
ffffffffc020301e:	6c42                	ld	s8,16(sp)
ffffffffc0203020:	6125                	addi	sp,sp,96
ffffffffc0203022:	8082                	ret
               cprintf("i %d, swap_out: call swap_out_victim failed\n", i);
ffffffffc0203024:	85a2                	mv	a1,s0
ffffffffc0203026:	00003517          	auipc	a0,0x3
ffffffffc020302a:	aa250513          	addi	a0,a0,-1374 # ffffffffc0205ac8 <default_pmm_manager+0xa10>
ffffffffc020302e:	890fd0ef          	jal	ra,ffffffffc02000be <cprintf>
               break;
ffffffffc0203032:	bfe1                	j	ffffffffc020300a <swap_out+0xc6>
     for (i = 0; i != n; ++i)
ffffffffc0203034:	4401                	li	s0,0
ffffffffc0203036:	bfd1                	j	ffffffffc020300a <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);           // 判断页表项是否有效
ffffffffc0203038:	00003697          	auipc	a3,0x3
ffffffffc020303c:	ac068693          	addi	a3,a3,-1344 # ffffffffc0205af8 <default_pmm_manager+0xa40>
ffffffffc0203040:	00002617          	auipc	a2,0x2
ffffffffc0203044:	ce060613          	addi	a2,a2,-800 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203048:	06300593          	li	a1,99
ffffffffc020304c:	00002517          	auipc	a0,0x2
ffffffffc0203050:	7b450513          	addi	a0,a0,1972 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc0203054:	b20fd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203058 <swap_in>:
{
ffffffffc0203058:	7179                	addi	sp,sp,-48
ffffffffc020305a:	e84a                	sd	s2,16(sp)
ffffffffc020305c:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc020305e:	4505                	li	a0,1
{
ffffffffc0203060:	ec26                	sd	s1,24(sp)
ffffffffc0203062:	e44e                	sd	s3,8(sp)
ffffffffc0203064:	f406                	sd	ra,40(sp)
ffffffffc0203066:	f022                	sd	s0,32(sp)
ffffffffc0203068:	84ae                	mv	s1,a1
ffffffffc020306a:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc020306c:	e22fe0ef          	jal	ra,ffffffffc020168e <alloc_pages>
     assert(result != NULL);
ffffffffc0203070:	c129                	beqz	a0,ffffffffc02030b2 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203072:	842a                	mv	s0,a0
ffffffffc0203074:	01893503          	ld	a0,24(s2)
ffffffffc0203078:	4601                	li	a2,0
ffffffffc020307a:	85a6                	mv	a1,s1
ffffffffc020307c:	f42fe0ef          	jal	ra,ffffffffc02017be <get_pte>
ffffffffc0203080:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203082:	6108                	ld	a0,0(a0)
ffffffffc0203084:	85a2                	mv	a1,s0
ffffffffc0203086:	437000ef          	jal	ra,ffffffffc0203cbc <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep) >> 8, addr);
ffffffffc020308a:	00093583          	ld	a1,0(s2)
ffffffffc020308e:	8626                	mv	a2,s1
ffffffffc0203090:	00002517          	auipc	a0,0x2
ffffffffc0203094:	71050513          	addi	a0,a0,1808 # ffffffffc02057a0 <default_pmm_manager+0x6e8>
ffffffffc0203098:	81a1                	srli	a1,a1,0x8
ffffffffc020309a:	824fd0ef          	jal	ra,ffffffffc02000be <cprintf>
}
ffffffffc020309e:	70a2                	ld	ra,40(sp)
     *ptr_result = result;
ffffffffc02030a0:	0089b023          	sd	s0,0(s3)
}
ffffffffc02030a4:	7402                	ld	s0,32(sp)
ffffffffc02030a6:	64e2                	ld	s1,24(sp)
ffffffffc02030a8:	6942                	ld	s2,16(sp)
ffffffffc02030aa:	69a2                	ld	s3,8(sp)
ffffffffc02030ac:	4501                	li	a0,0
ffffffffc02030ae:	6145                	addi	sp,sp,48
ffffffffc02030b0:	8082                	ret
     assert(result != NULL);
ffffffffc02030b2:	00002697          	auipc	a3,0x2
ffffffffc02030b6:	6de68693          	addi	a3,a3,1758 # ffffffffc0205790 <default_pmm_manager+0x6d8>
ffffffffc02030ba:	00002617          	auipc	a2,0x2
ffffffffc02030be:	c6660613          	addi	a2,a2,-922 # ffffffffc0204d20 <commands+0x870>
ffffffffc02030c2:	07c00593          	li	a1,124
ffffffffc02030c6:	00002517          	auipc	a0,0x2
ffffffffc02030ca:	73a50513          	addi	a0,a0,1850 # ffffffffc0205800 <default_pmm_manager+0x748>
ffffffffc02030ce:	aa6fd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02030d2 <_clock_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc02030d2:	0000e797          	auipc	a5,0xe
ffffffffc02030d6:	4ae78793          	addi	a5,a5,1198 # ffffffffc0211580 <pra_list_head>
    // 初始化pra_list_head为空链表
    list_init(&pra_list_head);
    // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
    curr_ptr = &pra_list_head;
    // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
    mm->sm_priv = &pra_list_head;
ffffffffc02030da:	f51c                	sd	a5,40(a0)
ffffffffc02030dc:	e79c                	sd	a5,8(a5)
ffffffffc02030de:	e39c                	sd	a5,0(a5)
    curr_ptr = &pra_list_head;
ffffffffc02030e0:	0000e717          	auipc	a4,0xe
ffffffffc02030e4:	4af73823          	sd	a5,1200(a4) # ffffffffc0211590 <curr_ptr>
    // cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);

    return 0;
}
ffffffffc02030e8:	4501                	li	a0,0
ffffffffc02030ea:	8082                	ret

ffffffffc02030ec <_clock_init>:

static int
_clock_init(void)
{
    return 0;
}
ffffffffc02030ec:	4501                	li	a0,0
ffffffffc02030ee:	8082                	ret

ffffffffc02030f0 <_clock_set_unswappable>:

static int
_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc02030f0:	4501                	li	a0,0
ffffffffc02030f2:	8082                	ret

ffffffffc02030f4 <_clock_tick_event>:

static int
_clock_tick_event(struct mm_struct *mm)
{
    return 0;
}
ffffffffc02030f4:	4501                	li	a0,0
ffffffffc02030f6:	8082                	ret

ffffffffc02030f8 <_clock_check_swap>:
{
ffffffffc02030f8:	1141                	addi	sp,sp,-16
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02030fa:	678d                	lui	a5,0x3
ffffffffc02030fc:	4731                	li	a4,12
{
ffffffffc02030fe:	e406                	sd	ra,8(sp)
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203100:	00e78023          	sb	a4,0(a5) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
    assert(pgfault_num == 4);
ffffffffc0203104:	0000e797          	auipc	a5,0xe
ffffffffc0203108:	37078793          	addi	a5,a5,880 # ffffffffc0211474 <pgfault_num>
ffffffffc020310c:	4398                	lw	a4,0(a5)
ffffffffc020310e:	4691                	li	a3,4
ffffffffc0203110:	2701                	sext.w	a4,a4
ffffffffc0203112:	08d71f63          	bne	a4,a3,ffffffffc02031b0 <_clock_check_swap+0xb8>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203116:	6685                	lui	a3,0x1
ffffffffc0203118:	4629                	li	a2,10
ffffffffc020311a:	00c68023          	sb	a2,0(a3) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
    assert(pgfault_num == 4);
ffffffffc020311e:	4394                	lw	a3,0(a5)
ffffffffc0203120:	2681                	sext.w	a3,a3
ffffffffc0203122:	20e69763          	bne	a3,a4,ffffffffc0203330 <_clock_check_swap+0x238>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203126:	6711                	lui	a4,0x4
ffffffffc0203128:	4635                	li	a2,13
ffffffffc020312a:	00c70023          	sb	a2,0(a4) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
    assert(pgfault_num == 4);
ffffffffc020312e:	4398                	lw	a4,0(a5)
ffffffffc0203130:	2701                	sext.w	a4,a4
ffffffffc0203132:	1cd71f63          	bne	a4,a3,ffffffffc0203310 <_clock_check_swap+0x218>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203136:	6689                	lui	a3,0x2
ffffffffc0203138:	462d                	li	a2,11
ffffffffc020313a:	00c68023          	sb	a2,0(a3) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
    assert(pgfault_num == 4);
ffffffffc020313e:	4394                	lw	a3,0(a5)
ffffffffc0203140:	2681                	sext.w	a3,a3
ffffffffc0203142:	1ae69763          	bne	a3,a4,ffffffffc02032f0 <_clock_check_swap+0x1f8>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203146:	6715                	lui	a4,0x5
ffffffffc0203148:	46b9                	li	a3,14
ffffffffc020314a:	00d70023          	sb	a3,0(a4) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num == 5);
ffffffffc020314e:	4398                	lw	a4,0(a5)
ffffffffc0203150:	4695                	li	a3,5
ffffffffc0203152:	2701                	sext.w	a4,a4
ffffffffc0203154:	16d71e63          	bne	a4,a3,ffffffffc02032d0 <_clock_check_swap+0x1d8>
    assert(pgfault_num == 5);
ffffffffc0203158:	4394                	lw	a3,0(a5)
ffffffffc020315a:	2681                	sext.w	a3,a3
ffffffffc020315c:	14e69a63          	bne	a3,a4,ffffffffc02032b0 <_clock_check_swap+0x1b8>
    assert(pgfault_num == 5);
ffffffffc0203160:	4398                	lw	a4,0(a5)
ffffffffc0203162:	2701                	sext.w	a4,a4
ffffffffc0203164:	12d71663          	bne	a4,a3,ffffffffc0203290 <_clock_check_swap+0x198>
    assert(pgfault_num == 5);
ffffffffc0203168:	4394                	lw	a3,0(a5)
ffffffffc020316a:	2681                	sext.w	a3,a3
ffffffffc020316c:	10e69263          	bne	a3,a4,ffffffffc0203270 <_clock_check_swap+0x178>
    assert(pgfault_num == 5);
ffffffffc0203170:	4398                	lw	a4,0(a5)
ffffffffc0203172:	2701                	sext.w	a4,a4
ffffffffc0203174:	0cd71e63          	bne	a4,a3,ffffffffc0203250 <_clock_check_swap+0x158>
    assert(pgfault_num == 5);
ffffffffc0203178:	4394                	lw	a3,0(a5)
ffffffffc020317a:	2681                	sext.w	a3,a3
ffffffffc020317c:	0ae69a63          	bne	a3,a4,ffffffffc0203230 <_clock_check_swap+0x138>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203180:	6715                	lui	a4,0x5
ffffffffc0203182:	46b9                	li	a3,14
ffffffffc0203184:	00d70023          	sb	a3,0(a4) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num == 5);
ffffffffc0203188:	4398                	lw	a4,0(a5)
ffffffffc020318a:	4695                	li	a3,5
ffffffffc020318c:	2701                	sext.w	a4,a4
ffffffffc020318e:	08d71163          	bne	a4,a3,ffffffffc0203210 <_clock_check_swap+0x118>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203192:	6705                	lui	a4,0x1
ffffffffc0203194:	00074683          	lbu	a3,0(a4) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc0203198:	4729                	li	a4,10
ffffffffc020319a:	04e69b63          	bne	a3,a4,ffffffffc02031f0 <_clock_check_swap+0xf8>
    assert(pgfault_num == 6);
ffffffffc020319e:	439c                	lw	a5,0(a5)
ffffffffc02031a0:	4719                	li	a4,6
ffffffffc02031a2:	2781                	sext.w	a5,a5
ffffffffc02031a4:	02e79663          	bne	a5,a4,ffffffffc02031d0 <_clock_check_swap+0xd8>
}
ffffffffc02031a8:	60a2                	ld	ra,8(sp)
ffffffffc02031aa:	4501                	li	a0,0
ffffffffc02031ac:	0141                	addi	sp,sp,16
ffffffffc02031ae:	8082                	ret
    assert(pgfault_num == 4);
ffffffffc02031b0:	00003697          	auipc	a3,0x3
ffffffffc02031b4:	83068693          	addi	a3,a3,-2000 # ffffffffc02059e0 <default_pmm_manager+0x928>
ffffffffc02031b8:	00002617          	auipc	a2,0x2
ffffffffc02031bc:	b6860613          	addi	a2,a2,-1176 # ffffffffc0204d20 <commands+0x870>
ffffffffc02031c0:	0a300593          	li	a1,163
ffffffffc02031c4:	00003517          	auipc	a0,0x3
ffffffffc02031c8:	9a450513          	addi	a0,a0,-1628 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc02031cc:	9a8fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 6);
ffffffffc02031d0:	00003697          	auipc	a3,0x3
ffffffffc02031d4:	9f068693          	addi	a3,a3,-1552 # ffffffffc0205bc0 <default_pmm_manager+0xb08>
ffffffffc02031d8:	00002617          	auipc	a2,0x2
ffffffffc02031dc:	b4860613          	addi	a2,a2,-1208 # ffffffffc0204d20 <commands+0x870>
ffffffffc02031e0:	0ba00593          	li	a1,186
ffffffffc02031e4:	00003517          	auipc	a0,0x3
ffffffffc02031e8:	98450513          	addi	a0,a0,-1660 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc02031ec:	988fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02031f0:	00003697          	auipc	a3,0x3
ffffffffc02031f4:	9a868693          	addi	a3,a3,-1624 # ffffffffc0205b98 <default_pmm_manager+0xae0>
ffffffffc02031f8:	00002617          	auipc	a2,0x2
ffffffffc02031fc:	b2860613          	addi	a2,a2,-1240 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203200:	0b800593          	li	a1,184
ffffffffc0203204:	00003517          	auipc	a0,0x3
ffffffffc0203208:	96450513          	addi	a0,a0,-1692 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc020320c:	968fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 5);
ffffffffc0203210:	00003697          	auipc	a3,0x3
ffffffffc0203214:	97068693          	addi	a3,a3,-1680 # ffffffffc0205b80 <default_pmm_manager+0xac8>
ffffffffc0203218:	00002617          	auipc	a2,0x2
ffffffffc020321c:	b0860613          	addi	a2,a2,-1272 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203220:	0b700593          	li	a1,183
ffffffffc0203224:	00003517          	auipc	a0,0x3
ffffffffc0203228:	94450513          	addi	a0,a0,-1724 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc020322c:	948fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 5);
ffffffffc0203230:	00003697          	auipc	a3,0x3
ffffffffc0203234:	95068693          	addi	a3,a3,-1712 # ffffffffc0205b80 <default_pmm_manager+0xac8>
ffffffffc0203238:	00002617          	auipc	a2,0x2
ffffffffc020323c:	ae860613          	addi	a2,a2,-1304 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203240:	0b500593          	li	a1,181
ffffffffc0203244:	00003517          	auipc	a0,0x3
ffffffffc0203248:	92450513          	addi	a0,a0,-1756 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc020324c:	928fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 5);
ffffffffc0203250:	00003697          	auipc	a3,0x3
ffffffffc0203254:	93068693          	addi	a3,a3,-1744 # ffffffffc0205b80 <default_pmm_manager+0xac8>
ffffffffc0203258:	00002617          	auipc	a2,0x2
ffffffffc020325c:	ac860613          	addi	a2,a2,-1336 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203260:	0b300593          	li	a1,179
ffffffffc0203264:	00003517          	auipc	a0,0x3
ffffffffc0203268:	90450513          	addi	a0,a0,-1788 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc020326c:	908fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 5);
ffffffffc0203270:	00003697          	auipc	a3,0x3
ffffffffc0203274:	91068693          	addi	a3,a3,-1776 # ffffffffc0205b80 <default_pmm_manager+0xac8>
ffffffffc0203278:	00002617          	auipc	a2,0x2
ffffffffc020327c:	aa860613          	addi	a2,a2,-1368 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203280:	0b100593          	li	a1,177
ffffffffc0203284:	00003517          	auipc	a0,0x3
ffffffffc0203288:	8e450513          	addi	a0,a0,-1820 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc020328c:	8e8fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 5);
ffffffffc0203290:	00003697          	auipc	a3,0x3
ffffffffc0203294:	8f068693          	addi	a3,a3,-1808 # ffffffffc0205b80 <default_pmm_manager+0xac8>
ffffffffc0203298:	00002617          	auipc	a2,0x2
ffffffffc020329c:	a8860613          	addi	a2,a2,-1400 # ffffffffc0204d20 <commands+0x870>
ffffffffc02032a0:	0af00593          	li	a1,175
ffffffffc02032a4:	00003517          	auipc	a0,0x3
ffffffffc02032a8:	8c450513          	addi	a0,a0,-1852 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc02032ac:	8c8fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 5);
ffffffffc02032b0:	00003697          	auipc	a3,0x3
ffffffffc02032b4:	8d068693          	addi	a3,a3,-1840 # ffffffffc0205b80 <default_pmm_manager+0xac8>
ffffffffc02032b8:	00002617          	auipc	a2,0x2
ffffffffc02032bc:	a6860613          	addi	a2,a2,-1432 # ffffffffc0204d20 <commands+0x870>
ffffffffc02032c0:	0ad00593          	li	a1,173
ffffffffc02032c4:	00003517          	auipc	a0,0x3
ffffffffc02032c8:	8a450513          	addi	a0,a0,-1884 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc02032cc:	8a8fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 5);
ffffffffc02032d0:	00003697          	auipc	a3,0x3
ffffffffc02032d4:	8b068693          	addi	a3,a3,-1872 # ffffffffc0205b80 <default_pmm_manager+0xac8>
ffffffffc02032d8:	00002617          	auipc	a2,0x2
ffffffffc02032dc:	a4860613          	addi	a2,a2,-1464 # ffffffffc0204d20 <commands+0x870>
ffffffffc02032e0:	0ab00593          	li	a1,171
ffffffffc02032e4:	00003517          	auipc	a0,0x3
ffffffffc02032e8:	88450513          	addi	a0,a0,-1916 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc02032ec:	888fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 4);
ffffffffc02032f0:	00002697          	auipc	a3,0x2
ffffffffc02032f4:	6f068693          	addi	a3,a3,1776 # ffffffffc02059e0 <default_pmm_manager+0x928>
ffffffffc02032f8:	00002617          	auipc	a2,0x2
ffffffffc02032fc:	a2860613          	addi	a2,a2,-1496 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203300:	0a900593          	li	a1,169
ffffffffc0203304:	00003517          	auipc	a0,0x3
ffffffffc0203308:	86450513          	addi	a0,a0,-1948 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc020330c:	868fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 4);
ffffffffc0203310:	00002697          	auipc	a3,0x2
ffffffffc0203314:	6d068693          	addi	a3,a3,1744 # ffffffffc02059e0 <default_pmm_manager+0x928>
ffffffffc0203318:	00002617          	auipc	a2,0x2
ffffffffc020331c:	a0860613          	addi	a2,a2,-1528 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203320:	0a700593          	li	a1,167
ffffffffc0203324:	00003517          	auipc	a0,0x3
ffffffffc0203328:	84450513          	addi	a0,a0,-1980 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc020332c:	848fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num == 4);
ffffffffc0203330:	00002697          	auipc	a3,0x2
ffffffffc0203334:	6b068693          	addi	a3,a3,1712 # ffffffffc02059e0 <default_pmm_manager+0x928>
ffffffffc0203338:	00002617          	auipc	a2,0x2
ffffffffc020333c:	9e860613          	addi	a2,a2,-1560 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203340:	0a500593          	li	a1,165
ffffffffc0203344:	00003517          	auipc	a0,0x3
ffffffffc0203348:	82450513          	addi	a0,a0,-2012 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc020334c:	828fd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203350 <_clock_map_swappable>:
    list_entry_t *entry = &(page->pra_page_link);     // 获取了指向当前页面的指针
ffffffffc0203350:	03060793          	addi	a5,a2,48
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203354:	c79d                	beqz	a5,ffffffffc0203382 <_clock_map_swappable+0x32>
ffffffffc0203356:	0000e717          	auipc	a4,0xe
ffffffffc020335a:	23a70713          	addi	a4,a4,570 # ffffffffc0211590 <curr_ptr>
ffffffffc020335e:	6318                	ld	a4,0(a4)
ffffffffc0203360:	c30d                	beqz	a4,ffffffffc0203382 <_clock_map_swappable+0x32>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203362:	0000e697          	auipc	a3,0xe
ffffffffc0203366:	21e68693          	addi	a3,a3,542 # ffffffffc0211580 <pra_list_head>
ffffffffc020336a:	6298                	ld	a4,0(a3)
    prev->next = next->prev = elm;
ffffffffc020336c:	0000e597          	auipc	a1,0xe
ffffffffc0203370:	20f5ba23          	sd	a5,532(a1) # ffffffffc0211580 <pra_list_head>
}
ffffffffc0203374:	4501                	li	a0,0
ffffffffc0203376:	e71c                	sd	a5,8(a4)
    page->visited = 1;
ffffffffc0203378:	4785                	li	a5,1
    elm->next = next;
ffffffffc020337a:	fe14                	sd	a3,56(a2)
    elm->prev = prev;
ffffffffc020337c:	fa18                	sd	a4,48(a2)
ffffffffc020337e:	ea1c                	sd	a5,16(a2)
}
ffffffffc0203380:	8082                	ret
{
ffffffffc0203382:	1141                	addi	sp,sp,-16
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203384:	00003697          	auipc	a3,0x3
ffffffffc0203388:	85468693          	addi	a3,a3,-1964 # ffffffffc0205bd8 <default_pmm_manager+0xb20>
ffffffffc020338c:	00002617          	auipc	a2,0x2
ffffffffc0203390:	99460613          	addi	a2,a2,-1644 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203394:	03900593          	li	a1,57
ffffffffc0203398:	00002517          	auipc	a0,0x2
ffffffffc020339c:	7d050513          	addi	a0,a0,2000 # ffffffffc0205b68 <default_pmm_manager+0xab0>
{
ffffffffc02033a0:	e406                	sd	ra,8(sp)
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc02033a2:	fd3fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02033a6 <_clock_swap_out_victim>:
    assert(head != NULL);
ffffffffc02033a6:	751c                	ld	a5,40(a0)
{
ffffffffc02033a8:	1101                	addi	sp,sp,-32
ffffffffc02033aa:	ec06                	sd	ra,24(sp)
ffffffffc02033ac:	e822                	sd	s0,16(sp)
ffffffffc02033ae:	e426                	sd	s1,8(sp)
ffffffffc02033b0:	e04a                	sd	s2,0(sp)
    assert(head != NULL);
ffffffffc02033b2:	c7ad                	beqz	a5,ffffffffc020341c <_clock_swap_out_victim+0x76>
    assert(in_tick == 0);
ffffffffc02033b4:	e641                	bnez	a2,ffffffffc020343c <_clock_swap_out_victim+0x96>
ffffffffc02033b6:	0000e497          	auipc	s1,0xe
ffffffffc02033ba:	1da48493          	addi	s1,s1,474 # ffffffffc0211590 <curr_ptr>
    return listelm->next;
ffffffffc02033be:	0000e717          	auipc	a4,0xe
ffffffffc02033c2:	1c270713          	addi	a4,a4,450 # ffffffffc0211580 <pra_list_head>
ffffffffc02033c6:	892e                	mv	s2,a1
ffffffffc02033c8:	6080                	ld	s0,0(s1)
ffffffffc02033ca:	6714                	ld	a3,8(a4)
ffffffffc02033cc:	a031                	j	ffffffffc02033d8 <_clock_swap_out_victim+0x32>
        if (page->visited == 0)
ffffffffc02033ce:	fe043783          	ld	a5,-32(s0)
ffffffffc02033d2:	cb91                	beqz	a5,ffffffffc02033e6 <_clock_swap_out_victim+0x40>
            page->visited = 0;
ffffffffc02033d4:	fe043023          	sd	zero,-32(s0)
ffffffffc02033d8:	6400                	ld	s0,8(s0)
        if (curr_ptr == &pra_list_head)
ffffffffc02033da:	fee41ae3          	bne	s0,a4,ffffffffc02033ce <_clock_swap_out_victim+0x28>
            curr_ptr = list_next(curr_ptr);
ffffffffc02033de:	8436                	mv	s0,a3
        if (page->visited == 0)
ffffffffc02033e0:	fe043783          	ld	a5,-32(s0)
ffffffffc02033e4:	fbe5                	bnez	a5,ffffffffc02033d4 <_clock_swap_out_victim+0x2e>
            cprintf("curr_ptr %p\n", curr_ptr);
ffffffffc02033e6:	85a2                	mv	a1,s0
ffffffffc02033e8:	00003517          	auipc	a0,0x3
ffffffffc02033ec:	83850513          	addi	a0,a0,-1992 # ffffffffc0205c20 <default_pmm_manager+0xb68>
ffffffffc02033f0:	0000e797          	auipc	a5,0xe
ffffffffc02033f4:	1a87b023          	sd	s0,416(a5) # ffffffffc0211590 <curr_ptr>
ffffffffc02033f8:	cc7fc0ef          	jal	ra,ffffffffc02000be <cprintf>
            list_del(curr_ptr);
ffffffffc02033fc:	609c                	ld	a5,0(s1)
        struct Page *page = le2page(curr_ptr, pra_page_link);
ffffffffc02033fe:	fd040413          	addi	s0,s0,-48
}
ffffffffc0203402:	60e2                	ld	ra,24(sp)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203404:	6398                	ld	a4,0(a5)
ffffffffc0203406:	679c                	ld	a5,8(a5)
ffffffffc0203408:	64a2                	ld	s1,8(sp)
ffffffffc020340a:	4501                	li	a0,0
    prev->next = next;
ffffffffc020340c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020340e:	e398                	sd	a4,0(a5)
            *ptr_page = page;
ffffffffc0203410:	00893023          	sd	s0,0(s2)
}
ffffffffc0203414:	6442                	ld	s0,16(sp)
ffffffffc0203416:	6902                	ld	s2,0(sp)
ffffffffc0203418:	6105                	addi	sp,sp,32
ffffffffc020341a:	8082                	ret
    assert(head != NULL);
ffffffffc020341c:	00002697          	auipc	a3,0x2
ffffffffc0203420:	7e468693          	addi	a3,a3,2020 # ffffffffc0205c00 <default_pmm_manager+0xb48>
ffffffffc0203424:	00002617          	auipc	a2,0x2
ffffffffc0203428:	8fc60613          	addi	a2,a2,-1796 # ffffffffc0204d20 <commands+0x870>
ffffffffc020342c:	04e00593          	li	a1,78
ffffffffc0203430:	00002517          	auipc	a0,0x2
ffffffffc0203434:	73850513          	addi	a0,a0,1848 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc0203438:	f3dfc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(in_tick == 0);
ffffffffc020343c:	00002697          	auipc	a3,0x2
ffffffffc0203440:	7d468693          	addi	a3,a3,2004 # ffffffffc0205c10 <default_pmm_manager+0xb58>
ffffffffc0203444:	00002617          	auipc	a2,0x2
ffffffffc0203448:	8dc60613          	addi	a2,a2,-1828 # ffffffffc0204d20 <commands+0x870>
ffffffffc020344c:	04f00593          	li	a1,79
ffffffffc0203450:	00002517          	auipc	a0,0x2
ffffffffc0203454:	71850513          	addi	a0,a0,1816 # ffffffffc0205b68 <default_pmm_manager+0xab0>
ffffffffc0203458:	f1dfc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020345c <check_vma_overlap.isra.0.part.1>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020345c:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020345e:	00002697          	auipc	a3,0x2
ffffffffc0203462:	7ea68693          	addi	a3,a3,2026 # ffffffffc0205c48 <default_pmm_manager+0xb90>
ffffffffc0203466:	00002617          	auipc	a2,0x2
ffffffffc020346a:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0204d20 <commands+0x870>
ffffffffc020346e:	08f00593          	li	a1,143
ffffffffc0203472:	00002517          	auipc	a0,0x2
ffffffffc0203476:	7f650513          	addi	a0,a0,2038 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020347a:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020347c:	ef9fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203480 <mm_create>:
{
ffffffffc0203480:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203482:	03000513          	li	a0,48
{
ffffffffc0203486:	e022                	sd	s0,0(sp)
ffffffffc0203488:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020348a:	a52ff0ef          	jal	ra,ffffffffc02026dc <kmalloc>
ffffffffc020348e:	842a                	mv	s0,a0
    if (mm != NULL)
ffffffffc0203490:	c115                	beqz	a0,ffffffffc02034b4 <mm_create+0x34>
        if (swap_init_ok)
ffffffffc0203492:	0000e797          	auipc	a5,0xe
ffffffffc0203496:	fde78793          	addi	a5,a5,-34 # ffffffffc0211470 <swap_init_ok>
ffffffffc020349a:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc020349c:	e408                	sd	a0,8(s0)
ffffffffc020349e:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc02034a0:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02034a4:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02034a8:	02052023          	sw	zero,32(a0)
        if (swap_init_ok)
ffffffffc02034ac:	2781                	sext.w	a5,a5
ffffffffc02034ae:	eb81                	bnez	a5,ffffffffc02034be <mm_create+0x3e>
            mm->sm_priv = NULL;
ffffffffc02034b0:	02053423          	sd	zero,40(a0)
}
ffffffffc02034b4:	8522                	mv	a0,s0
ffffffffc02034b6:	60a2                	ld	ra,8(sp)
ffffffffc02034b8:	6402                	ld	s0,0(sp)
ffffffffc02034ba:	0141                	addi	sp,sp,16
ffffffffc02034bc:	8082                	ret
            swap_init_mm(mm);
ffffffffc02034be:	a67ff0ef          	jal	ra,ffffffffc0202f24 <swap_init_mm>
}
ffffffffc02034c2:	8522                	mv	a0,s0
ffffffffc02034c4:	60a2                	ld	ra,8(sp)
ffffffffc02034c6:	6402                	ld	s0,0(sp)
ffffffffc02034c8:	0141                	addi	sp,sp,16
ffffffffc02034ca:	8082                	ret

ffffffffc02034cc <vma_create>:
{
ffffffffc02034cc:	1101                	addi	sp,sp,-32
ffffffffc02034ce:	e04a                	sd	s2,0(sp)
ffffffffc02034d0:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02034d2:	03000513          	li	a0,48
{
ffffffffc02034d6:	e822                	sd	s0,16(sp)
ffffffffc02034d8:	e426                	sd	s1,8(sp)
ffffffffc02034da:	ec06                	sd	ra,24(sp)
ffffffffc02034dc:	84ae                	mv	s1,a1
ffffffffc02034de:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02034e0:	9fcff0ef          	jal	ra,ffffffffc02026dc <kmalloc>
    if (vma != NULL)
ffffffffc02034e4:	c509                	beqz	a0,ffffffffc02034ee <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc02034e6:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc02034ea:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02034ec:	ed00                	sd	s0,24(a0)
}
ffffffffc02034ee:	60e2                	ld	ra,24(sp)
ffffffffc02034f0:	6442                	ld	s0,16(sp)
ffffffffc02034f2:	64a2                	ld	s1,8(sp)
ffffffffc02034f4:	6902                	ld	s2,0(sp)
ffffffffc02034f6:	6105                	addi	sp,sp,32
ffffffffc02034f8:	8082                	ret

ffffffffc02034fa <find_vma>:
    if (mm != NULL)
ffffffffc02034fa:	c51d                	beqz	a0,ffffffffc0203528 <find_vma+0x2e>
        vma = mm->mmap_cache; // 先查cache
ffffffffc02034fc:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02034fe:	c781                	beqz	a5,ffffffffc0203506 <find_vma+0xc>
ffffffffc0203500:	6798                	ld	a4,8(a5)
ffffffffc0203502:	02e5f663          	bleu	a4,a1,ffffffffc020352e <find_vma+0x34>
            list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc0203506:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc0203508:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc020350a:	00f50f63          	beq	a0,a5,ffffffffc0203528 <find_vma+0x2e>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020350e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203512:	fee5ebe3          	bltu	a1,a4,ffffffffc0203508 <find_vma+0xe>
ffffffffc0203516:	ff07b703          	ld	a4,-16(a5)
ffffffffc020351a:	fee5f7e3          	bleu	a4,a1,ffffffffc0203508 <find_vma+0xe>
                vma = le2vma(le, list_link);
ffffffffc020351e:	1781                	addi	a5,a5,-32
        if (vma != NULL)
ffffffffc0203520:	c781                	beqz	a5,ffffffffc0203528 <find_vma+0x2e>
            mm->mmap_cache = vma; // 更新cache
ffffffffc0203522:	e91c                	sd	a5,16(a0)
}
ffffffffc0203524:	853e                	mv	a0,a5
ffffffffc0203526:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc0203528:	4781                	li	a5,0
}
ffffffffc020352a:	853e                	mv	a0,a5
ffffffffc020352c:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020352e:	6b98                	ld	a4,16(a5)
ffffffffc0203530:	fce5fbe3          	bleu	a4,a1,ffffffffc0203506 <find_vma+0xc>
            mm->mmap_cache = vma; // 更新cache
ffffffffc0203534:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc0203536:	b7fd                	j	ffffffffc0203524 <find_vma+0x2a>

ffffffffc0203538 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203538:	6590                	ld	a2,8(a1)
ffffffffc020353a:	0105b803          	ld	a6,16(a1)
{
ffffffffc020353e:	1141                	addi	sp,sp,-16
ffffffffc0203540:	e406                	sd	ra,8(sp)
ffffffffc0203542:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203544:	01066863          	bltu	a2,a6,ffffffffc0203554 <insert_vma_struct+0x1c>
ffffffffc0203548:	a8b9                	j	ffffffffc02035a6 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020354a:	fe87b683          	ld	a3,-24(a5)
ffffffffc020354e:	04d66763          	bltu	a2,a3,ffffffffc020359c <insert_vma_struct+0x64>
ffffffffc0203552:	873e                	mv	a4,a5
ffffffffc0203554:	671c                	ld	a5,8(a4)
    while ((le = list_next(le)) != list)
ffffffffc0203556:	fef51ae3          	bne	a0,a5,ffffffffc020354a <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020355a:	02a70463          	beq	a4,a0,ffffffffc0203582 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020355e:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203562:	fe873883          	ld	a7,-24(a4)
ffffffffc0203566:	08d8f063          	bleu	a3,a7,ffffffffc02035e6 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020356a:	04d66e63          	bltu	a2,a3,ffffffffc02035c6 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc020356e:	00f50a63          	beq	a0,a5,ffffffffc0203582 <insert_vma_struct+0x4a>
ffffffffc0203572:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203576:	0506e863          	bltu	a3,a6,ffffffffc02035c6 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc020357a:	ff07b603          	ld	a2,-16(a5)
ffffffffc020357e:	02c6f263          	bleu	a2,a3,ffffffffc02035a2 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203582:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc0203584:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203586:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020358a:	e390                	sd	a2,0(a5)
ffffffffc020358c:	e710                	sd	a2,8(a4)
}
ffffffffc020358e:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203590:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203592:	f198                	sd	a4,32(a1)
    mm->map_count++;
ffffffffc0203594:	2685                	addiw	a3,a3,1
ffffffffc0203596:	d114                	sw	a3,32(a0)
}
ffffffffc0203598:	0141                	addi	sp,sp,16
ffffffffc020359a:	8082                	ret
    if (le_prev != list)
ffffffffc020359c:	fca711e3          	bne	a4,a0,ffffffffc020355e <insert_vma_struct+0x26>
ffffffffc02035a0:	bfd9                	j	ffffffffc0203576 <insert_vma_struct+0x3e>
ffffffffc02035a2:	ebbff0ef          	jal	ra,ffffffffc020345c <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02035a6:	00002697          	auipc	a3,0x2
ffffffffc02035aa:	79a68693          	addi	a3,a3,1946 # ffffffffc0205d40 <default_pmm_manager+0xc88>
ffffffffc02035ae:	00001617          	auipc	a2,0x1
ffffffffc02035b2:	77260613          	addi	a2,a2,1906 # ffffffffc0204d20 <commands+0x870>
ffffffffc02035b6:	09500593          	li	a1,149
ffffffffc02035ba:	00002517          	auipc	a0,0x2
ffffffffc02035be:	6ae50513          	addi	a0,a0,1710 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc02035c2:	db3fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02035c6:	00002697          	auipc	a3,0x2
ffffffffc02035ca:	7ba68693          	addi	a3,a3,1978 # ffffffffc0205d80 <default_pmm_manager+0xcc8>
ffffffffc02035ce:	00001617          	auipc	a2,0x1
ffffffffc02035d2:	75260613          	addi	a2,a2,1874 # ffffffffc0204d20 <commands+0x870>
ffffffffc02035d6:	08e00593          	li	a1,142
ffffffffc02035da:	00002517          	auipc	a0,0x2
ffffffffc02035de:	68e50513          	addi	a0,a0,1678 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc02035e2:	d93fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02035e6:	00002697          	auipc	a3,0x2
ffffffffc02035ea:	77a68693          	addi	a3,a3,1914 # ffffffffc0205d60 <default_pmm_manager+0xca8>
ffffffffc02035ee:	00001617          	auipc	a2,0x1
ffffffffc02035f2:	73260613          	addi	a2,a2,1842 # ffffffffc0204d20 <commands+0x870>
ffffffffc02035f6:	08d00593          	li	a1,141
ffffffffc02035fa:	00002517          	auipc	a0,0x2
ffffffffc02035fe:	66e50513          	addi	a0,a0,1646 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc0203602:	d73fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203606 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
ffffffffc0203606:	1141                	addi	sp,sp,-16
ffffffffc0203608:	e022                	sd	s0,0(sp)
ffffffffc020360a:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc020360c:	6508                	ld	a0,8(a0)
ffffffffc020360e:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203610:	00a40e63          	beq	s0,a0,ffffffffc020362c <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203614:	6118                	ld	a4,0(a0)
ffffffffc0203616:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link), sizeof(struct vma_struct)); // kfree vma
ffffffffc0203618:	03000593          	li	a1,48
ffffffffc020361c:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc020361e:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203620:	e398                	sd	a4,0(a5)
ffffffffc0203622:	97cff0ef          	jal	ra,ffffffffc020279e <kfree>
    return listelm->next;
ffffffffc0203626:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203628:	fea416e3          	bne	s0,a0,ffffffffc0203614 <mm_destroy+0xe>
    }
    kfree(mm, sizeof(struct mm_struct)); // kfree mm
ffffffffc020362c:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc020362e:	6402                	ld	s0,0(sp)
ffffffffc0203630:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); // kfree mm
ffffffffc0203632:	03000593          	li	a1,48
}
ffffffffc0203636:	0141                	addi	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); // kfree mm
ffffffffc0203638:	966ff06f          	j	ffffffffc020279e <kfree>

ffffffffc020363c <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc020363c:	715d                	addi	sp,sp,-80
ffffffffc020363e:	e486                	sd	ra,72(sp)
ffffffffc0203640:	e0a2                	sd	s0,64(sp)
ffffffffc0203642:	fc26                	sd	s1,56(sp)
ffffffffc0203644:	f84a                	sd	s2,48(sp)
ffffffffc0203646:	f052                	sd	s4,32(sp)
ffffffffc0203648:	f44e                	sd	s3,40(sp)
ffffffffc020364a:	ec56                	sd	s5,24(sp)
ffffffffc020364c:	e85a                	sd	s6,16(sp)
ffffffffc020364e:	e45e                	sd	s7,8(sp)

// check_vmm - check correctness of vmm
static void
check_vmm(void)
{
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203650:	92efe0ef          	jal	ra,ffffffffc020177e <nr_free_pages>
ffffffffc0203654:	892a                	mv	s2,a0
}

static void
check_vma_struct(void)
{
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203656:	928fe0ef          	jal	ra,ffffffffc020177e <nr_free_pages>
ffffffffc020365a:	8a2a                	mv	s4,a0

    struct mm_struct *mm = mm_create();
ffffffffc020365c:	e25ff0ef          	jal	ra,ffffffffc0203480 <mm_create>
    assert(mm != NULL);
ffffffffc0203660:	842a                	mv	s0,a0
ffffffffc0203662:	03200493          	li	s1,50
ffffffffc0203666:	e919                	bnez	a0,ffffffffc020367c <vmm_init+0x40>
ffffffffc0203668:	aeed                	j	ffffffffc0203a62 <vmm_init+0x426>
        vma->vm_start = vm_start;
ffffffffc020366a:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc020366c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020366e:	00053c23          	sd	zero,24(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203672:	14ed                	addi	s1,s1,-5
ffffffffc0203674:	8522                	mv	a0,s0
ffffffffc0203676:	ec3ff0ef          	jal	ra,ffffffffc0203538 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc020367a:	c88d                	beqz	s1,ffffffffc02036ac <vmm_init+0x70>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020367c:	03000513          	li	a0,48
ffffffffc0203680:	85cff0ef          	jal	ra,ffffffffc02026dc <kmalloc>
ffffffffc0203684:	85aa                	mv	a1,a0
ffffffffc0203686:	00248793          	addi	a5,s1,2
    if (vma != NULL)
ffffffffc020368a:	f165                	bnez	a0,ffffffffc020366a <vmm_init+0x2e>
        assert(vma != NULL);
ffffffffc020368c:	00002697          	auipc	a3,0x2
ffffffffc0203690:	1fc68693          	addi	a3,a3,508 # ffffffffc0205888 <default_pmm_manager+0x7d0>
ffffffffc0203694:	00001617          	auipc	a2,0x1
ffffffffc0203698:	68c60613          	addi	a2,a2,1676 # ffffffffc0204d20 <commands+0x870>
ffffffffc020369c:	0e700593          	li	a1,231
ffffffffc02036a0:	00002517          	auipc	a0,0x2
ffffffffc02036a4:	5c850513          	addi	a0,a0,1480 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc02036a8:	ccdfc0ef          	jal	ra,ffffffffc0200374 <__panic>
    for (i = step1; i >= 1; i--)
ffffffffc02036ac:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc02036b0:	1f900993          	li	s3,505
ffffffffc02036b4:	a819                	j	ffffffffc02036ca <vmm_init+0x8e>
        vma->vm_start = vm_start;
ffffffffc02036b6:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02036b8:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02036ba:	00053c23          	sd	zero,24(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02036be:	0495                	addi	s1,s1,5
ffffffffc02036c0:	8522                	mv	a0,s0
ffffffffc02036c2:	e77ff0ef          	jal	ra,ffffffffc0203538 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc02036c6:	03348a63          	beq	s1,s3,ffffffffc02036fa <vmm_init+0xbe>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02036ca:	03000513          	li	a0,48
ffffffffc02036ce:	80eff0ef          	jal	ra,ffffffffc02026dc <kmalloc>
ffffffffc02036d2:	85aa                	mv	a1,a0
ffffffffc02036d4:	00248793          	addi	a5,s1,2
    if (vma != NULL)
ffffffffc02036d8:	fd79                	bnez	a0,ffffffffc02036b6 <vmm_init+0x7a>
        assert(vma != NULL);
ffffffffc02036da:	00002697          	auipc	a3,0x2
ffffffffc02036de:	1ae68693          	addi	a3,a3,430 # ffffffffc0205888 <default_pmm_manager+0x7d0>
ffffffffc02036e2:	00001617          	auipc	a2,0x1
ffffffffc02036e6:	63e60613          	addi	a2,a2,1598 # ffffffffc0204d20 <commands+0x870>
ffffffffc02036ea:	0ee00593          	li	a1,238
ffffffffc02036ee:	00002517          	auipc	a0,0x2
ffffffffc02036f2:	57a50513          	addi	a0,a0,1402 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc02036f6:	c7ffc0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc02036fa:	6418                	ld	a4,8(s0)
ffffffffc02036fc:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc02036fe:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203702:	2ae40063          	beq	s0,a4,ffffffffc02039a2 <vmm_init+0x366>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203706:	fe873603          	ld	a2,-24(a4)
ffffffffc020370a:	ffe78693          	addi	a3,a5,-2
ffffffffc020370e:	20d61a63          	bne	a2,a3,ffffffffc0203922 <vmm_init+0x2e6>
ffffffffc0203712:	ff073683          	ld	a3,-16(a4)
ffffffffc0203716:	20d79663          	bne	a5,a3,ffffffffc0203922 <vmm_init+0x2e6>
ffffffffc020371a:	0795                	addi	a5,a5,5
ffffffffc020371c:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i++)
ffffffffc020371e:	feb792e3          	bne	a5,a1,ffffffffc0203702 <vmm_init+0xc6>
ffffffffc0203722:	499d                	li	s3,7
ffffffffc0203724:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203726:	1f900b93          	li	s7,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc020372a:	85a6                	mv	a1,s1
ffffffffc020372c:	8522                	mv	a0,s0
ffffffffc020372e:	dcdff0ef          	jal	ra,ffffffffc02034fa <find_vma>
ffffffffc0203732:	8b2a                	mv	s6,a0
        assert(vma1 != NULL);
ffffffffc0203734:	2e050763          	beqz	a0,ffffffffc0203a22 <vmm_init+0x3e6>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203738:	00148593          	addi	a1,s1,1
ffffffffc020373c:	8522                	mv	a0,s0
ffffffffc020373e:	dbdff0ef          	jal	ra,ffffffffc02034fa <find_vma>
ffffffffc0203742:	8aaa                	mv	s5,a0
        assert(vma2 != NULL);
ffffffffc0203744:	2a050f63          	beqz	a0,ffffffffc0203a02 <vmm_init+0x3c6>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203748:	85ce                	mv	a1,s3
ffffffffc020374a:	8522                	mv	a0,s0
ffffffffc020374c:	dafff0ef          	jal	ra,ffffffffc02034fa <find_vma>
        assert(vma3 == NULL);
ffffffffc0203750:	28051963          	bnez	a0,ffffffffc02039e2 <vmm_init+0x3a6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203754:	00348593          	addi	a1,s1,3
ffffffffc0203758:	8522                	mv	a0,s0
ffffffffc020375a:	da1ff0ef          	jal	ra,ffffffffc02034fa <find_vma>
        assert(vma4 == NULL);
ffffffffc020375e:	26051263          	bnez	a0,ffffffffc02039c2 <vmm_init+0x386>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203762:	00448593          	addi	a1,s1,4
ffffffffc0203766:	8522                	mv	a0,s0
ffffffffc0203768:	d93ff0ef          	jal	ra,ffffffffc02034fa <find_vma>
        assert(vma5 == NULL);
ffffffffc020376c:	2c051b63          	bnez	a0,ffffffffc0203a42 <vmm_init+0x406>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203770:	008b3783          	ld	a5,8(s6)
ffffffffc0203774:	1c979763          	bne	a5,s1,ffffffffc0203942 <vmm_init+0x306>
ffffffffc0203778:	010b3783          	ld	a5,16(s6)
ffffffffc020377c:	1d379363          	bne	a5,s3,ffffffffc0203942 <vmm_init+0x306>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203780:	008ab783          	ld	a5,8(s5)
ffffffffc0203784:	1c979f63          	bne	a5,s1,ffffffffc0203962 <vmm_init+0x326>
ffffffffc0203788:	010ab783          	ld	a5,16(s5)
ffffffffc020378c:	1d379b63          	bne	a5,s3,ffffffffc0203962 <vmm_init+0x326>
ffffffffc0203790:	0495                	addi	s1,s1,5
ffffffffc0203792:	0995                	addi	s3,s3,5
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203794:	f9749be3          	bne	s1,s7,ffffffffc020372a <vmm_init+0xee>
ffffffffc0203798:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc020379a:	59fd                	li	s3,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc020379c:	85a6                	mv	a1,s1
ffffffffc020379e:	8522                	mv	a0,s0
ffffffffc02037a0:	d5bff0ef          	jal	ra,ffffffffc02034fa <find_vma>
ffffffffc02037a4:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL)
ffffffffc02037a8:	c90d                	beqz	a0,ffffffffc02037da <vmm_init+0x19e>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc02037aa:	6914                	ld	a3,16(a0)
ffffffffc02037ac:	6510                	ld	a2,8(a0)
ffffffffc02037ae:	00002517          	auipc	a0,0x2
ffffffffc02037b2:	6f250513          	addi	a0,a0,1778 # ffffffffc0205ea0 <default_pmm_manager+0xde8>
ffffffffc02037b6:	909fc0ef          	jal	ra,ffffffffc02000be <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02037ba:	00002697          	auipc	a3,0x2
ffffffffc02037be:	70e68693          	addi	a3,a3,1806 # ffffffffc0205ec8 <default_pmm_manager+0xe10>
ffffffffc02037c2:	00001617          	auipc	a2,0x1
ffffffffc02037c6:	55e60613          	addi	a2,a2,1374 # ffffffffc0204d20 <commands+0x870>
ffffffffc02037ca:	11400593          	li	a1,276
ffffffffc02037ce:	00002517          	auipc	a0,0x2
ffffffffc02037d2:	49a50513          	addi	a0,a0,1178 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc02037d6:	b9ffc0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc02037da:	14fd                	addi	s1,s1,-1
    for (i = 4; i >= 0; i--)
ffffffffc02037dc:	fd3490e3          	bne	s1,s3,ffffffffc020379c <vmm_init+0x160>
    }

    mm_destroy(mm);
ffffffffc02037e0:	8522                	mv	a0,s0
ffffffffc02037e2:	e25ff0ef          	jal	ra,ffffffffc0203606 <mm_destroy>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02037e6:	f99fd0ef          	jal	ra,ffffffffc020177e <nr_free_pages>
ffffffffc02037ea:	28aa1c63          	bne	s4,a0,ffffffffc0203a82 <vmm_init+0x446>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02037ee:	00002517          	auipc	a0,0x2
ffffffffc02037f2:	71a50513          	addi	a0,a0,1818 # ffffffffc0205f08 <default_pmm_manager+0xe50>
ffffffffc02037f6:	8c9fc0ef          	jal	ra,ffffffffc02000be <cprintf>
// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void)
{
    // char *name = "check_pgfault";
    size_t nr_free_pages_store = nr_free_pages(); // 备份当前系统的空闲页面数量
ffffffffc02037fa:	f85fd0ef          	jal	ra,ffffffffc020177e <nr_free_pages>
ffffffffc02037fe:	89aa                	mv	s3,a0

    check_mm_struct = mm_create(); // 创建一个新的内存管理结构mm。用来管理一系列的连续虚拟内存区域。
ffffffffc0203800:	c81ff0ef          	jal	ra,ffffffffc0203480 <mm_create>
ffffffffc0203804:	0000e797          	auipc	a5,0xe
ffffffffc0203808:	d8a7ba23          	sd	a0,-620(a5) # ffffffffc0211598 <check_mm_struct>
ffffffffc020380c:	842a                	mv	s0,a0

    assert(check_mm_struct != NULL);
ffffffffc020380e:	2a050a63          	beqz	a0,ffffffffc0203ac2 <vmm_init+0x486>
    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir; // pgdir被设置为boot_pgdir，这是系统启动时的页目录
ffffffffc0203812:	0000e797          	auipc	a5,0xe
ffffffffc0203816:	c4678793          	addi	a5,a5,-954 # ffffffffc0211458 <boot_pgdir>
ffffffffc020381a:	6384                	ld	s1,0(a5)
    assert(pgdir[0] == 0);
ffffffffc020381c:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir; // pgdir被设置为boot_pgdir，这是系统启动时的页目录
ffffffffc020381e:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0203820:	32079d63          	bnez	a5,ffffffffc0203b5a <vmm_init+0x51e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203824:	03000513          	li	a0,48
ffffffffc0203828:	eb5fe0ef          	jal	ra,ffffffffc02026dc <kmalloc>
ffffffffc020382c:	8a2a                	mv	s4,a0
    if (vma != NULL)
ffffffffc020382e:	14050a63          	beqz	a0,ffffffffc0203982 <vmm_init+0x346>
        vma->vm_end = vm_end;
ffffffffc0203832:	002007b7          	lui	a5,0x200
ffffffffc0203836:	00fa3823          	sd	a5,16(s4)
        vma->vm_flags = vm_flags;
ffffffffc020383a:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE); // 创建一个新的虚拟内存区域（VMA）

    assert(vma != NULL);

    insert_vma_struct(mm, vma); // 将新创建的虚拟内存区域插入到mm管理的VMA列表中
ffffffffc020383c:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc020383e:	00fa3c23          	sd	a5,24(s4)
    insert_vma_struct(mm, vma); // 将新创建的虚拟内存区域插入到mm管理的VMA列表中
ffffffffc0203842:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc0203844:	000a3423          	sd	zero,8(s4)
    insert_vma_struct(mm, vma); // 将新创建的虚拟内存区域插入到mm管理的VMA列表中
ffffffffc0203848:	cf1ff0ef          	jal	ra,ffffffffc0203538 <insert_vma_struct>

    // 在新创建的VMA范围内进行内存访问和修改
    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc020384c:	10000593          	li	a1,256
ffffffffc0203850:	8522                	mv	a0,s0
ffffffffc0203852:	ca9ff0ef          	jal	ra,ffffffffc02034fa <find_vma>
ffffffffc0203856:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i++)
ffffffffc020385a:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc020385e:	2aaa1263          	bne	s4,a0,ffffffffc0203b02 <vmm_init+0x4c6>
    {
        *(char *)(addr + i) = i;
ffffffffc0203862:	00f78023          	sb	a5,0(a5) # 200000 <BASE_ADDRESS-0xffffffffc0000000>
        sum += i;
ffffffffc0203866:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i++)
ffffffffc0203868:	fee79de3          	bne	a5,a4,ffffffffc0203862 <vmm_init+0x226>
        sum += i;
ffffffffc020386c:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i++)
ffffffffc020386e:	10000793          	li	a5,256
        sum += i;
ffffffffc0203872:	35670713          	addi	a4,a4,854 # 1356 <BASE_ADDRESS-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i++)
ffffffffc0203876:	16400613          	li	a2,356
    {
        sum -= *(char *)(addr + i);
ffffffffc020387a:	0007c683          	lbu	a3,0(a5)
ffffffffc020387e:	0785                	addi	a5,a5,1
ffffffffc0203880:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i++)
ffffffffc0203882:	fec79ce3          	bne	a5,a2,ffffffffc020387a <vmm_init+0x23e>
    }
    assert(sum == 0);
ffffffffc0203886:	2a071a63          	bnez	a4,ffffffffc0203b3a <vmm_init+0x4fe>

    // 使用page_remove和free_page来释放前面访问和修改时分配的页面

    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc020388a:	4581                	li	a1,0
ffffffffc020388c:	8526                	mv	a0,s1
ffffffffc020388e:	996fe0ef          	jal	ra,ffffffffc0201a24 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203892:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc0203894:	0000e717          	auipc	a4,0xe
ffffffffc0203898:	bcc70713          	addi	a4,a4,-1076 # ffffffffc0211460 <npage>
ffffffffc020389c:	6318                	ld	a4,0(a4)
    return pa2page(PDE_ADDR(pde));
ffffffffc020389e:	078a                	slli	a5,a5,0x2
ffffffffc02038a0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02038a2:	28e7f063          	bleu	a4,a5,ffffffffc0203b22 <vmm_init+0x4e6>
    return &pages[PPN(pa) - nbase];
ffffffffc02038a6:	00003717          	auipc	a4,0x3
ffffffffc02038aa:	9a270713          	addi	a4,a4,-1630 # ffffffffc0206248 <nbase>
ffffffffc02038ae:	6318                	ld	a4,0(a4)
ffffffffc02038b0:	0000e697          	auipc	a3,0xe
ffffffffc02038b4:	c0068693          	addi	a3,a3,-1024 # ffffffffc02114b0 <pages>
ffffffffc02038b8:	6288                	ld	a0,0(a3)
ffffffffc02038ba:	8f99                	sub	a5,a5,a4
ffffffffc02038bc:	00379713          	slli	a4,a5,0x3
ffffffffc02038c0:	97ba                	add	a5,a5,a4
ffffffffc02038c2:	078e                	slli	a5,a5,0x3

    free_page(pde2page(pgdir[0]));
ffffffffc02038c4:	953e                	add	a0,a0,a5
ffffffffc02038c6:	4585                	li	a1,1
ffffffffc02038c8:	e71fd0ef          	jal	ra,ffffffffc0201738 <free_pages>

    pgdir[0] = 0;
ffffffffc02038cc:	0004b023          	sd	zero,0(s1)

    // 清除mm的pgdir指针，并使用mm_destroy销毁mm结构。
    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc02038d0:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc02038d2:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc02038d6:	d31ff0ef          	jal	ra,ffffffffc0203606 <mm_destroy>

    check_mm_struct = NULL;
    nr_free_pages_store--; // szx : Sv39第二级页表多占了一个内存页，所以执行此操作
ffffffffc02038da:	19fd                	addi	s3,s3,-1
    check_mm_struct = NULL;
ffffffffc02038dc:	0000e797          	auipc	a5,0xe
ffffffffc02038e0:	ca07be23          	sd	zero,-836(a5) # ffffffffc0211598 <check_mm_struct>

    // 比较当前系统的空闲页面数量与函数开始时的数量，以确保没有内存泄漏。
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02038e4:	e9bfd0ef          	jal	ra,ffffffffc020177e <nr_free_pages>
ffffffffc02038e8:	1aa99d63          	bne	s3,a0,ffffffffc0203aa2 <vmm_init+0x466>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc02038ec:	00002517          	auipc	a0,0x2
ffffffffc02038f0:	68450513          	addi	a0,a0,1668 # ffffffffc0205f70 <default_pmm_manager+0xeb8>
ffffffffc02038f4:	fcafc0ef          	jal	ra,ffffffffc02000be <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02038f8:	e87fd0ef          	jal	ra,ffffffffc020177e <nr_free_pages>
    nr_free_pages_store--; // szx : Sv39三级页表多占一个内存页，所以执行此操作
ffffffffc02038fc:	197d                	addi	s2,s2,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02038fe:	1ea91263          	bne	s2,a0,ffffffffc0203ae2 <vmm_init+0x4a6>
}
ffffffffc0203902:	6406                	ld	s0,64(sp)
ffffffffc0203904:	60a6                	ld	ra,72(sp)
ffffffffc0203906:	74e2                	ld	s1,56(sp)
ffffffffc0203908:	7942                	ld	s2,48(sp)
ffffffffc020390a:	79a2                	ld	s3,40(sp)
ffffffffc020390c:	7a02                	ld	s4,32(sp)
ffffffffc020390e:	6ae2                	ld	s5,24(sp)
ffffffffc0203910:	6b42                	ld	s6,16(sp)
ffffffffc0203912:	6ba2                	ld	s7,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203914:	00002517          	auipc	a0,0x2
ffffffffc0203918:	67c50513          	addi	a0,a0,1660 # ffffffffc0205f90 <default_pmm_manager+0xed8>
}
ffffffffc020391c:	6161                	addi	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc020391e:	fa0fc06f          	j	ffffffffc02000be <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203922:	00002697          	auipc	a3,0x2
ffffffffc0203926:	49668693          	addi	a3,a3,1174 # ffffffffc0205db8 <default_pmm_manager+0xd00>
ffffffffc020392a:	00001617          	auipc	a2,0x1
ffffffffc020392e:	3f660613          	addi	a2,a2,1014 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203932:	0f800593          	li	a1,248
ffffffffc0203936:	00002517          	auipc	a0,0x2
ffffffffc020393a:	33250513          	addi	a0,a0,818 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc020393e:	a37fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203942:	00002697          	auipc	a3,0x2
ffffffffc0203946:	4fe68693          	addi	a3,a3,1278 # ffffffffc0205e40 <default_pmm_manager+0xd88>
ffffffffc020394a:	00001617          	auipc	a2,0x1
ffffffffc020394e:	3d660613          	addi	a2,a2,982 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203952:	10900593          	li	a1,265
ffffffffc0203956:	00002517          	auipc	a0,0x2
ffffffffc020395a:	31250513          	addi	a0,a0,786 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc020395e:	a17fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203962:	00002697          	auipc	a3,0x2
ffffffffc0203966:	50e68693          	addi	a3,a3,1294 # ffffffffc0205e70 <default_pmm_manager+0xdb8>
ffffffffc020396a:	00001617          	auipc	a2,0x1
ffffffffc020396e:	3b660613          	addi	a2,a2,950 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203972:	10a00593          	li	a1,266
ffffffffc0203976:	00002517          	auipc	a0,0x2
ffffffffc020397a:	2f250513          	addi	a0,a0,754 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc020397e:	9f7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(vma != NULL);
ffffffffc0203982:	00002697          	auipc	a3,0x2
ffffffffc0203986:	f0668693          	addi	a3,a3,-250 # ffffffffc0205888 <default_pmm_manager+0x7d0>
ffffffffc020398a:	00001617          	auipc	a2,0x1
ffffffffc020398e:	39660613          	addi	a2,a2,918 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203992:	13000593          	li	a1,304
ffffffffc0203996:	00002517          	auipc	a0,0x2
ffffffffc020399a:	2d250513          	addi	a0,a0,722 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc020399e:	9d7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02039a2:	00002697          	auipc	a3,0x2
ffffffffc02039a6:	3fe68693          	addi	a3,a3,1022 # ffffffffc0205da0 <default_pmm_manager+0xce8>
ffffffffc02039aa:	00001617          	auipc	a2,0x1
ffffffffc02039ae:	37660613          	addi	a2,a2,886 # ffffffffc0204d20 <commands+0x870>
ffffffffc02039b2:	0f600593          	li	a1,246
ffffffffc02039b6:	00002517          	auipc	a0,0x2
ffffffffc02039ba:	2b250513          	addi	a0,a0,690 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc02039be:	9b7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma4 == NULL);
ffffffffc02039c2:	00002697          	auipc	a3,0x2
ffffffffc02039c6:	45e68693          	addi	a3,a3,1118 # ffffffffc0205e20 <default_pmm_manager+0xd68>
ffffffffc02039ca:	00001617          	auipc	a2,0x1
ffffffffc02039ce:	35660613          	addi	a2,a2,854 # ffffffffc0204d20 <commands+0x870>
ffffffffc02039d2:	10500593          	li	a1,261
ffffffffc02039d6:	00002517          	auipc	a0,0x2
ffffffffc02039da:	29250513          	addi	a0,a0,658 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc02039de:	997fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma3 == NULL);
ffffffffc02039e2:	00002697          	auipc	a3,0x2
ffffffffc02039e6:	42e68693          	addi	a3,a3,1070 # ffffffffc0205e10 <default_pmm_manager+0xd58>
ffffffffc02039ea:	00001617          	auipc	a2,0x1
ffffffffc02039ee:	33660613          	addi	a2,a2,822 # ffffffffc0204d20 <commands+0x870>
ffffffffc02039f2:	10300593          	li	a1,259
ffffffffc02039f6:	00002517          	auipc	a0,0x2
ffffffffc02039fa:	27250513          	addi	a0,a0,626 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc02039fe:	977fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma2 != NULL);
ffffffffc0203a02:	00002697          	auipc	a3,0x2
ffffffffc0203a06:	3fe68693          	addi	a3,a3,1022 # ffffffffc0205e00 <default_pmm_manager+0xd48>
ffffffffc0203a0a:	00001617          	auipc	a2,0x1
ffffffffc0203a0e:	31660613          	addi	a2,a2,790 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203a12:	10100593          	li	a1,257
ffffffffc0203a16:	00002517          	auipc	a0,0x2
ffffffffc0203a1a:	25250513          	addi	a0,a0,594 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc0203a1e:	957fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma1 != NULL);
ffffffffc0203a22:	00002697          	auipc	a3,0x2
ffffffffc0203a26:	3ce68693          	addi	a3,a3,974 # ffffffffc0205df0 <default_pmm_manager+0xd38>
ffffffffc0203a2a:	00001617          	auipc	a2,0x1
ffffffffc0203a2e:	2f660613          	addi	a2,a2,758 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203a32:	0ff00593          	li	a1,255
ffffffffc0203a36:	00002517          	auipc	a0,0x2
ffffffffc0203a3a:	23250513          	addi	a0,a0,562 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc0203a3e:	937fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma5 == NULL);
ffffffffc0203a42:	00002697          	auipc	a3,0x2
ffffffffc0203a46:	3ee68693          	addi	a3,a3,1006 # ffffffffc0205e30 <default_pmm_manager+0xd78>
ffffffffc0203a4a:	00001617          	auipc	a2,0x1
ffffffffc0203a4e:	2d660613          	addi	a2,a2,726 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203a52:	10700593          	li	a1,263
ffffffffc0203a56:	00002517          	auipc	a0,0x2
ffffffffc0203a5a:	21250513          	addi	a0,a0,530 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc0203a5e:	917fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(mm != NULL);
ffffffffc0203a62:	00002697          	auipc	a3,0x2
ffffffffc0203a66:	dee68693          	addi	a3,a3,-530 # ffffffffc0205850 <default_pmm_manager+0x798>
ffffffffc0203a6a:	00001617          	auipc	a2,0x1
ffffffffc0203a6e:	2b660613          	addi	a2,a2,694 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203a72:	0df00593          	li	a1,223
ffffffffc0203a76:	00002517          	auipc	a0,0x2
ffffffffc0203a7a:	1f250513          	addi	a0,a0,498 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc0203a7e:	8f7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203a82:	00002697          	auipc	a3,0x2
ffffffffc0203a86:	45e68693          	addi	a3,a3,1118 # ffffffffc0205ee0 <default_pmm_manager+0xe28>
ffffffffc0203a8a:	00001617          	auipc	a2,0x1
ffffffffc0203a8e:	29660613          	addi	a2,a2,662 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203a92:	11900593          	li	a1,281
ffffffffc0203a96:	00002517          	auipc	a0,0x2
ffffffffc0203a9a:	1d250513          	addi	a0,a0,466 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc0203a9e:	8d7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203aa2:	00002697          	auipc	a3,0x2
ffffffffc0203aa6:	43e68693          	addi	a3,a3,1086 # ffffffffc0205ee0 <default_pmm_manager+0xe28>
ffffffffc0203aaa:	00001617          	auipc	a2,0x1
ffffffffc0203aae:	27660613          	addi	a2,a2,630 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203ab2:	15400593          	li	a1,340
ffffffffc0203ab6:	00002517          	auipc	a0,0x2
ffffffffc0203aba:	1b250513          	addi	a0,a0,434 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc0203abe:	8b7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0203ac2:	00002697          	auipc	a3,0x2
ffffffffc0203ac6:	46668693          	addi	a3,a3,1126 # ffffffffc0205f28 <default_pmm_manager+0xe70>
ffffffffc0203aca:	00001617          	auipc	a2,0x1
ffffffffc0203ace:	25660613          	addi	a2,a2,598 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203ad2:	12900593          	li	a1,297
ffffffffc0203ad6:	00002517          	auipc	a0,0x2
ffffffffc0203ada:	19250513          	addi	a0,a0,402 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc0203ade:	897fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203ae2:	00002697          	auipc	a3,0x2
ffffffffc0203ae6:	3fe68693          	addi	a3,a3,1022 # ffffffffc0205ee0 <default_pmm_manager+0xe28>
ffffffffc0203aea:	00001617          	auipc	a2,0x1
ffffffffc0203aee:	23660613          	addi	a2,a2,566 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203af2:	0d400593          	li	a1,212
ffffffffc0203af6:	00002517          	auipc	a0,0x2
ffffffffc0203afa:	17250513          	addi	a0,a0,370 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc0203afe:	877fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0203b02:	00002697          	auipc	a3,0x2
ffffffffc0203b06:	43e68693          	addi	a3,a3,1086 # ffffffffc0205f40 <default_pmm_manager+0xe88>
ffffffffc0203b0a:	00001617          	auipc	a2,0x1
ffffffffc0203b0e:	21660613          	addi	a2,a2,534 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203b12:	13600593          	li	a1,310
ffffffffc0203b16:	00002517          	auipc	a0,0x2
ffffffffc0203b1a:	15250513          	addi	a0,a0,338 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc0203b1e:	857fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203b22:	00001617          	auipc	a2,0x1
ffffffffc0203b26:	68e60613          	addi	a2,a2,1678 # ffffffffc02051b0 <default_pmm_manager+0xf8>
ffffffffc0203b2a:	06500593          	li	a1,101
ffffffffc0203b2e:	00001517          	auipc	a0,0x1
ffffffffc0203b32:	6a250513          	addi	a0,a0,1698 # ffffffffc02051d0 <default_pmm_manager+0x118>
ffffffffc0203b36:	83ffc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(sum == 0);
ffffffffc0203b3a:	00002697          	auipc	a3,0x2
ffffffffc0203b3e:	42668693          	addi	a3,a3,1062 # ffffffffc0205f60 <default_pmm_manager+0xea8>
ffffffffc0203b42:	00001617          	auipc	a2,0x1
ffffffffc0203b46:	1de60613          	addi	a2,a2,478 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203b4a:	14200593          	li	a1,322
ffffffffc0203b4e:	00002517          	auipc	a0,0x2
ffffffffc0203b52:	11a50513          	addi	a0,a0,282 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc0203b56:	81ffc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0203b5a:	00002697          	auipc	a3,0x2
ffffffffc0203b5e:	d1e68693          	addi	a3,a3,-738 # ffffffffc0205878 <default_pmm_manager+0x7c0>
ffffffffc0203b62:	00001617          	auipc	a2,0x1
ffffffffc0203b66:	1be60613          	addi	a2,a2,446 # ffffffffc0204d20 <commands+0x870>
ffffffffc0203b6a:	12c00593          	li	a1,300
ffffffffc0203b6e:	00002517          	auipc	a0,0x2
ffffffffc0203b72:	0fa50513          	addi	a0,a0,250 # ffffffffc0205c68 <default_pmm_manager+0xbb0>
ffffffffc0203b76:	ffefc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203b7a <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr)
{
ffffffffc0203b7a:	7179                	addi	sp,sp,-48
    // mm mm_struct的结构体
    // error_code 错误码
    // addr 产生异常的地址
    int ret = -E_INVAL; // 返回值初始化为-E_INVAL，为无效值
    // try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr); // 找到地址对应的vma_struct结构体
ffffffffc0203b7c:	85b2                	mv	a1,a2
{
ffffffffc0203b7e:	f022                	sd	s0,32(sp)
ffffffffc0203b80:	ec26                	sd	s1,24(sp)
ffffffffc0203b82:	f406                	sd	ra,40(sp)
ffffffffc0203b84:	e84a                	sd	s2,16(sp)
ffffffffc0203b86:	8432                	mv	s0,a2
ffffffffc0203b88:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr); // 找到地址对应的vma_struct结构体
ffffffffc0203b8a:	971ff0ef          	jal	ra,ffffffffc02034fa <find_vma>

    pgfault_num++;
ffffffffc0203b8e:	0000e797          	auipc	a5,0xe
ffffffffc0203b92:	8e678793          	addi	a5,a5,-1818 # ffffffffc0211474 <pgfault_num>
ffffffffc0203b96:	439c                	lw	a5,0(a5)
ffffffffc0203b98:	2785                	addiw	a5,a5,1
ffffffffc0203b9a:	0000e717          	auipc	a4,0xe
ffffffffc0203b9e:	8cf72d23          	sw	a5,-1830(a4) # ffffffffc0211474 <pgfault_num>
    // If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr)
ffffffffc0203ba2:	c941                	beqz	a0,ffffffffc0203c32 <do_pgfault+0xb8>
ffffffffc0203ba4:	651c                	ld	a5,8(a0)
ffffffffc0203ba6:	08f46663          	bltu	s0,a5,ffffffffc0203c32 <do_pgfault+0xb8>
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U; // 定义页权限并初始化为用户模式。

    if (vma->vm_flags & VM_WRITE) // 检查vma是否可写
ffffffffc0203baa:	6d1c                	ld	a5,24(a0)
    uint32_t perm = PTE_U; // 定义页权限并初始化为用户模式。
ffffffffc0203bac:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) // 检查vma是否可写
ffffffffc0203bae:	8b89                	andi	a5,a5,2
ffffffffc0203bb0:	e3a5                	bnez	a5,ffffffffc0203c10 <do_pgfault+0x96>
    {
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE); // 将addr向下对齐到页面大小的整数倍，找到发生缺页的addr所在的页面的首地址
ffffffffc0203bb2:	767d                	lui	a2,0xfffff
     * VARIABLES:
     *   mm->pgdir : the PDT of these vma
     *
     */

    ptep = get_pte(mm->pgdir, addr, 1);
ffffffffc0203bb4:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE); // 将addr向下对齐到页面大小的整数倍，找到发生缺页的addr所在的页面的首地址
ffffffffc0203bb6:	8c71                	and	s0,s0,a2
    ptep = get_pte(mm->pgdir, addr, 1);
ffffffffc0203bb8:	85a2                	mv	a1,s0
ffffffffc0203bba:	4605                	li	a2,1
ffffffffc0203bbc:	c03fd0ef          	jal	ra,ffffffffc02017be <get_pte>
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // 传入参数为mm->pgdir，addr，1————页目录表的虚拟地址，线性地址，是否创建标志位

    if (*ptep == 0) // 检查页表条目是否为空，即该虚拟地址是否已经映射到物理页面
ffffffffc0203bc0:	610c                	ld	a1,0(a0)
ffffffffc0203bc2:	c9a9                	beqz	a1,ffffffffc0203c14 <do_pgfault+0x9a>
         *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
         *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
         *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
         *    swap_map_swappable ： 设置页面可交换
         */
        if (swap_init_ok)
ffffffffc0203bc4:	0000e797          	auipc	a5,0xe
ffffffffc0203bc8:	8ac78793          	addi	a5,a5,-1876 # ffffffffc0211470 <swap_init_ok>
ffffffffc0203bcc:	439c                	lw	a5,0(a5)
ffffffffc0203bce:	2781                	sext.w	a5,a5
ffffffffc0203bd0:	cbb5                	beqz	a5,ffffffffc0203c44 <do_pgfault+0xca>
            // map of phy addr <--->
            // logical addr
            //(3) make the page swappable.

            // (1) 尝试加载正确的磁盘页面的内容到内存中的页面
            int result = swap_in(mm, addr, &page); // ***在这里进swap_in函数
ffffffffc0203bd2:	0030                	addi	a2,sp,8
ffffffffc0203bd4:	85a2                	mv	a1,s0
ffffffffc0203bd6:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0203bd8:	e402                	sd	zero,8(sp)
            int result = swap_in(mm, addr, &page); // ***在这里进swap_in函数
ffffffffc0203bda:	c7eff0ef          	jal	ra,ffffffffc0203058 <swap_in>
            if (result != 0)
ffffffffc0203bde:	e93d                	bnez	a0,ffffffffc0203c54 <do_pgfault+0xda>
                cprintf("swap_in failed\n");
                goto failed;
            }

            // (2) 设置物理地址和逻辑地址的映射
            if (page_insert(mm->pgdir, page, addr, perm) != 0)
ffffffffc0203be0:	65a2                	ld	a1,8(sp)
ffffffffc0203be2:	6c88                	ld	a0,24(s1)
ffffffffc0203be4:	86ca                	mv	a3,s2
ffffffffc0203be6:	8622                	mv	a2,s0
ffffffffc0203be8:	eaffd0ef          	jal	ra,ffffffffc0201a96 <page_insert>
ffffffffc0203bec:	ed25                	bnez	a0,ffffffffc0203c64 <do_pgfault+0xea>
                cprintf("page_insert failed\n");
                goto failed;
            }

            // (3) 设置页面为可交换的
            if (swap_map_swappable(mm, addr, page, 1) != 0)
ffffffffc0203bee:	6622                	ld	a2,8(sp)
ffffffffc0203bf0:	4685                	li	a3,1
ffffffffc0203bf2:	85a2                	mv	a1,s0
ffffffffc0203bf4:	8526                	mv	a0,s1
ffffffffc0203bf6:	b3eff0ef          	jal	ra,ffffffffc0202f34 <swap_map_swappable>
ffffffffc0203bfa:	87aa                	mv	a5,a0
ffffffffc0203bfc:	ed25                	bnez	a0,ffffffffc0203c74 <do_pgfault+0xfa>
            {
                cprintf("swap_map_swappable failed\n");
                goto failed;
            }
            page->pra_vaddr = addr;
ffffffffc0203bfe:	6722                	ld	a4,8(sp)
ffffffffc0203c00:	e320                	sd	s0,64(a4)
    }

    ret = 0;
failed:
    return ret;
}
ffffffffc0203c02:	70a2                	ld	ra,40(sp)
ffffffffc0203c04:	7402                	ld	s0,32(sp)
ffffffffc0203c06:	64e2                	ld	s1,24(sp)
ffffffffc0203c08:	6942                	ld	s2,16(sp)
ffffffffc0203c0a:	853e                	mv	a0,a5
ffffffffc0203c0c:	6145                	addi	sp,sp,48
ffffffffc0203c0e:	8082                	ret
        perm |= (PTE_R | PTE_W);
ffffffffc0203c10:	4959                	li	s2,22
ffffffffc0203c12:	b745                	j	ffffffffc0203bb2 <do_pgfault+0x38>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) // 如果该地址未映射，则尝试为它分配一个新页面并设置适当的权限
ffffffffc0203c14:	6c88                	ld	a0,24(s1)
ffffffffc0203c16:	864a                	mv	a2,s2
ffffffffc0203c18:	85a2                	mv	a1,s0
ffffffffc0203c1a:	a31fe0ef          	jal	ra,ffffffffc020264a <pgdir_alloc_page>
    ret = 0;
ffffffffc0203c1e:	4781                	li	a5,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) // 如果该地址未映射，则尝试为它分配一个新页面并设置适当的权限
ffffffffc0203c20:	f16d                	bnez	a0,ffffffffc0203c02 <do_pgfault+0x88>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0203c22:	00002517          	auipc	a0,0x2
ffffffffc0203c26:	08650513          	addi	a0,a0,134 # ffffffffc0205ca8 <default_pmm_manager+0xbf0>
ffffffffc0203c2a:	c94fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM; // 表示没有可用内存
ffffffffc0203c2e:	57f1                	li	a5,-4
            goto failed;
ffffffffc0203c30:	bfc9                	j	ffffffffc0203c02 <do_pgfault+0x88>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0203c32:	85a2                	mv	a1,s0
ffffffffc0203c34:	00002517          	auipc	a0,0x2
ffffffffc0203c38:	04450513          	addi	a0,a0,68 # ffffffffc0205c78 <default_pmm_manager+0xbc0>
ffffffffc0203c3c:	c82fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    int ret = -E_INVAL; // 返回值初始化为-E_INVAL，为无效值
ffffffffc0203c40:	57f5                	li	a5,-3
        goto failed;
ffffffffc0203c42:	b7c1                	j	ffffffffc0203c02 <do_pgfault+0x88>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0203c44:	00002517          	auipc	a0,0x2
ffffffffc0203c48:	0d450513          	addi	a0,a0,212 # ffffffffc0205d18 <default_pmm_manager+0xc60>
ffffffffc0203c4c:	c72fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM; // 表示没有可用内存
ffffffffc0203c50:	57f1                	li	a5,-4
            goto failed;
ffffffffc0203c52:	bf45                	j	ffffffffc0203c02 <do_pgfault+0x88>
                cprintf("swap_in failed\n");
ffffffffc0203c54:	00002517          	auipc	a0,0x2
ffffffffc0203c58:	07c50513          	addi	a0,a0,124 # ffffffffc0205cd0 <default_pmm_manager+0xc18>
ffffffffc0203c5c:	c62fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM; // 表示没有可用内存
ffffffffc0203c60:	57f1                	li	a5,-4
ffffffffc0203c62:	b745                	j	ffffffffc0203c02 <do_pgfault+0x88>
                cprintf("page_insert failed\n");
ffffffffc0203c64:	00002517          	auipc	a0,0x2
ffffffffc0203c68:	07c50513          	addi	a0,a0,124 # ffffffffc0205ce0 <default_pmm_manager+0xc28>
ffffffffc0203c6c:	c52fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM; // 表示没有可用内存
ffffffffc0203c70:	57f1                	li	a5,-4
ffffffffc0203c72:	bf41                	j	ffffffffc0203c02 <do_pgfault+0x88>
                cprintf("swap_map_swappable failed\n");
ffffffffc0203c74:	00002517          	auipc	a0,0x2
ffffffffc0203c78:	08450513          	addi	a0,a0,132 # ffffffffc0205cf8 <default_pmm_manager+0xc40>
ffffffffc0203c7c:	c42fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM; // 表示没有可用内存
ffffffffc0203c80:	57f1                	li	a5,-4
ffffffffc0203c82:	b741                	j	ffffffffc0203c02 <do_pgfault+0x88>

ffffffffc0203c84 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0203c84:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203c86:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0203c88:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203c8a:	815fc0ef          	jal	ra,ffffffffc020049e <ide_device_valid>
ffffffffc0203c8e:	cd01                	beqz	a0,ffffffffc0203ca6 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203c90:	4505                	li	a0,1
ffffffffc0203c92:	813fc0ef          	jal	ra,ffffffffc02004a4 <ide_device_size>
}
ffffffffc0203c96:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203c98:	810d                	srli	a0,a0,0x3
ffffffffc0203c9a:	0000e797          	auipc	a5,0xe
ffffffffc0203c9e:	8aa7b323          	sd	a0,-1882(a5) # ffffffffc0211540 <max_swap_offset>
}
ffffffffc0203ca2:	0141                	addi	sp,sp,16
ffffffffc0203ca4:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0203ca6:	00002617          	auipc	a2,0x2
ffffffffc0203caa:	30260613          	addi	a2,a2,770 # ffffffffc0205fa8 <default_pmm_manager+0xef0>
ffffffffc0203cae:	45b5                	li	a1,13
ffffffffc0203cb0:	00002517          	auipc	a0,0x2
ffffffffc0203cb4:	31850513          	addi	a0,a0,792 # ffffffffc0205fc8 <default_pmm_manager+0xf10>
ffffffffc0203cb8:	ebcfc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203cbc <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0203cbc:	1141                	addi	sp,sp,-16
ffffffffc0203cbe:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203cc0:	00855793          	srli	a5,a0,0x8
ffffffffc0203cc4:	c7b5                	beqz	a5,ffffffffc0203d30 <swapfs_read+0x74>
ffffffffc0203cc6:	0000e717          	auipc	a4,0xe
ffffffffc0203cca:	87a70713          	addi	a4,a4,-1926 # ffffffffc0211540 <max_swap_offset>
ffffffffc0203cce:	6318                	ld	a4,0(a4)
ffffffffc0203cd0:	06e7f063          	bleu	a4,a5,ffffffffc0203d30 <swapfs_read+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203cd4:	0000d717          	auipc	a4,0xd
ffffffffc0203cd8:	7dc70713          	addi	a4,a4,2012 # ffffffffc02114b0 <pages>
ffffffffc0203cdc:	6310                	ld	a2,0(a4)
ffffffffc0203cde:	00001717          	auipc	a4,0x1
ffffffffc0203ce2:	02a70713          	addi	a4,a4,42 # ffffffffc0204d08 <commands+0x858>
ffffffffc0203ce6:	00002697          	auipc	a3,0x2
ffffffffc0203cea:	56268693          	addi	a3,a3,1378 # ffffffffc0206248 <nbase>
ffffffffc0203cee:	40c58633          	sub	a2,a1,a2
ffffffffc0203cf2:	630c                	ld	a1,0(a4)
ffffffffc0203cf4:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203cf6:	0000d717          	auipc	a4,0xd
ffffffffc0203cfa:	76a70713          	addi	a4,a4,1898 # ffffffffc0211460 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203cfe:	02b60633          	mul	a2,a2,a1
ffffffffc0203d02:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203d06:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d08:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d0a:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d0c:	57fd                	li	a5,-1
ffffffffc0203d0e:	83b1                	srli	a5,a5,0xc
ffffffffc0203d10:	8ff1                	and	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203d12:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d14:	02e7fa63          	bleu	a4,a5,ffffffffc0203d48 <swapfs_read+0x8c>
ffffffffc0203d18:	0000d797          	auipc	a5,0xd
ffffffffc0203d1c:	78878793          	addi	a5,a5,1928 # ffffffffc02114a0 <va_pa_offset>
ffffffffc0203d20:	639c                	ld	a5,0(a5)
}
ffffffffc0203d22:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d24:	46a1                	li	a3,8
ffffffffc0203d26:	963e                	add	a2,a2,a5
ffffffffc0203d28:	4505                	li	a0,1
}
ffffffffc0203d2a:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d2c:	f7efc06f          	j	ffffffffc02004aa <ide_read_secs>
ffffffffc0203d30:	86aa                	mv	a3,a0
ffffffffc0203d32:	00002617          	auipc	a2,0x2
ffffffffc0203d36:	2ae60613          	addi	a2,a2,686 # ffffffffc0205fe0 <default_pmm_manager+0xf28>
ffffffffc0203d3a:	45d1                	li	a1,20
ffffffffc0203d3c:	00002517          	auipc	a0,0x2
ffffffffc0203d40:	28c50513          	addi	a0,a0,652 # ffffffffc0205fc8 <default_pmm_manager+0xf10>
ffffffffc0203d44:	e30fc0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc0203d48:	86b2                	mv	a3,a2
ffffffffc0203d4a:	06a00593          	li	a1,106
ffffffffc0203d4e:	00001617          	auipc	a2,0x1
ffffffffc0203d52:	3ea60613          	addi	a2,a2,1002 # ffffffffc0205138 <default_pmm_manager+0x80>
ffffffffc0203d56:	00001517          	auipc	a0,0x1
ffffffffc0203d5a:	47a50513          	addi	a0,a0,1146 # ffffffffc02051d0 <default_pmm_manager+0x118>
ffffffffc0203d5e:	e16fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203d62 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0203d62:	1141                	addi	sp,sp,-16
ffffffffc0203d64:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d66:	00855793          	srli	a5,a0,0x8
ffffffffc0203d6a:	c7b5                	beqz	a5,ffffffffc0203dd6 <swapfs_write+0x74>
ffffffffc0203d6c:	0000d717          	auipc	a4,0xd
ffffffffc0203d70:	7d470713          	addi	a4,a4,2004 # ffffffffc0211540 <max_swap_offset>
ffffffffc0203d74:	6318                	ld	a4,0(a4)
ffffffffc0203d76:	06e7f063          	bleu	a4,a5,ffffffffc0203dd6 <swapfs_write+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d7a:	0000d717          	auipc	a4,0xd
ffffffffc0203d7e:	73670713          	addi	a4,a4,1846 # ffffffffc02114b0 <pages>
ffffffffc0203d82:	6310                	ld	a2,0(a4)
ffffffffc0203d84:	00001717          	auipc	a4,0x1
ffffffffc0203d88:	f8470713          	addi	a4,a4,-124 # ffffffffc0204d08 <commands+0x858>
ffffffffc0203d8c:	00002697          	auipc	a3,0x2
ffffffffc0203d90:	4bc68693          	addi	a3,a3,1212 # ffffffffc0206248 <nbase>
ffffffffc0203d94:	40c58633          	sub	a2,a1,a2
ffffffffc0203d98:	630c                	ld	a1,0(a4)
ffffffffc0203d9a:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203d9c:	0000d717          	auipc	a4,0xd
ffffffffc0203da0:	6c470713          	addi	a4,a4,1732 # ffffffffc0211460 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203da4:	02b60633          	mul	a2,a2,a1
ffffffffc0203da8:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203dac:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203dae:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203db0:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203db2:	57fd                	li	a5,-1
ffffffffc0203db4:	83b1                	srli	a5,a5,0xc
ffffffffc0203db6:	8ff1                	and	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0203db8:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203dba:	02e7fa63          	bleu	a4,a5,ffffffffc0203dee <swapfs_write+0x8c>
ffffffffc0203dbe:	0000d797          	auipc	a5,0xd
ffffffffc0203dc2:	6e278793          	addi	a5,a5,1762 # ffffffffc02114a0 <va_pa_offset>
ffffffffc0203dc6:	639c                	ld	a5,0(a5)
}
ffffffffc0203dc8:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203dca:	46a1                	li	a3,8
ffffffffc0203dcc:	963e                	add	a2,a2,a5
ffffffffc0203dce:	4505                	li	a0,1
}
ffffffffc0203dd0:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203dd2:	efcfc06f          	j	ffffffffc02004ce <ide_write_secs>
ffffffffc0203dd6:	86aa                	mv	a3,a0
ffffffffc0203dd8:	00002617          	auipc	a2,0x2
ffffffffc0203ddc:	20860613          	addi	a2,a2,520 # ffffffffc0205fe0 <default_pmm_manager+0xf28>
ffffffffc0203de0:	45e5                	li	a1,25
ffffffffc0203de2:	00002517          	auipc	a0,0x2
ffffffffc0203de6:	1e650513          	addi	a0,a0,486 # ffffffffc0205fc8 <default_pmm_manager+0xf10>
ffffffffc0203dea:	d8afc0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc0203dee:	86b2                	mv	a3,a2
ffffffffc0203df0:	06a00593          	li	a1,106
ffffffffc0203df4:	00001617          	auipc	a2,0x1
ffffffffc0203df8:	34460613          	addi	a2,a2,836 # ffffffffc0205138 <default_pmm_manager+0x80>
ffffffffc0203dfc:	00001517          	auipc	a0,0x1
ffffffffc0203e00:	3d450513          	addi	a0,a0,980 # ffffffffc02051d0 <default_pmm_manager+0x118>
ffffffffc0203e04:	d70fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203e08 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203e08:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203e0c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203e0e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203e12:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203e14:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203e18:	f022                	sd	s0,32(sp)
ffffffffc0203e1a:	ec26                	sd	s1,24(sp)
ffffffffc0203e1c:	e84a                	sd	s2,16(sp)
ffffffffc0203e1e:	f406                	sd	ra,40(sp)
ffffffffc0203e20:	e44e                	sd	s3,8(sp)
ffffffffc0203e22:	84aa                	mv	s1,a0
ffffffffc0203e24:	892e                	mv	s2,a1
ffffffffc0203e26:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203e2a:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0203e2c:	03067e63          	bleu	a6,a2,ffffffffc0203e68 <printnum+0x60>
ffffffffc0203e30:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203e32:	00805763          	blez	s0,ffffffffc0203e40 <printnum+0x38>
ffffffffc0203e36:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203e38:	85ca                	mv	a1,s2
ffffffffc0203e3a:	854e                	mv	a0,s3
ffffffffc0203e3c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203e3e:	fc65                	bnez	s0,ffffffffc0203e36 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203e40:	1a02                	slli	s4,s4,0x20
ffffffffc0203e42:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203e46:	00002797          	auipc	a5,0x2
ffffffffc0203e4a:	34a78793          	addi	a5,a5,842 # ffffffffc0206190 <error_string+0x38>
ffffffffc0203e4e:	9a3e                	add	s4,s4,a5
}
ffffffffc0203e50:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203e52:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203e56:	70a2                	ld	ra,40(sp)
ffffffffc0203e58:	69a2                	ld	s3,8(sp)
ffffffffc0203e5a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203e5c:	85ca                	mv	a1,s2
ffffffffc0203e5e:	8326                	mv	t1,s1
}
ffffffffc0203e60:	6942                	ld	s2,16(sp)
ffffffffc0203e62:	64e2                	ld	s1,24(sp)
ffffffffc0203e64:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203e66:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203e68:	03065633          	divu	a2,a2,a6
ffffffffc0203e6c:	8722                	mv	a4,s0
ffffffffc0203e6e:	f9bff0ef          	jal	ra,ffffffffc0203e08 <printnum>
ffffffffc0203e72:	b7f9                	j	ffffffffc0203e40 <printnum+0x38>

ffffffffc0203e74 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203e74:	7119                	addi	sp,sp,-128
ffffffffc0203e76:	f4a6                	sd	s1,104(sp)
ffffffffc0203e78:	f0ca                	sd	s2,96(sp)
ffffffffc0203e7a:	e8d2                	sd	s4,80(sp)
ffffffffc0203e7c:	e4d6                	sd	s5,72(sp)
ffffffffc0203e7e:	e0da                	sd	s6,64(sp)
ffffffffc0203e80:	fc5e                	sd	s7,56(sp)
ffffffffc0203e82:	f862                	sd	s8,48(sp)
ffffffffc0203e84:	f06a                	sd	s10,32(sp)
ffffffffc0203e86:	fc86                	sd	ra,120(sp)
ffffffffc0203e88:	f8a2                	sd	s0,112(sp)
ffffffffc0203e8a:	ecce                	sd	s3,88(sp)
ffffffffc0203e8c:	f466                	sd	s9,40(sp)
ffffffffc0203e8e:	ec6e                	sd	s11,24(sp)
ffffffffc0203e90:	892a                	mv	s2,a0
ffffffffc0203e92:	84ae                	mv	s1,a1
ffffffffc0203e94:	8d32                	mv	s10,a2
ffffffffc0203e96:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203e98:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203e9a:	00002a17          	auipc	s4,0x2
ffffffffc0203e9e:	166a0a13          	addi	s4,s4,358 # ffffffffc0206000 <default_pmm_manager+0xf48>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203ea2:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203ea6:	00002c17          	auipc	s8,0x2
ffffffffc0203eaa:	2b2c0c13          	addi	s8,s8,690 # ffffffffc0206158 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203eae:	000d4503          	lbu	a0,0(s10)
ffffffffc0203eb2:	02500793          	li	a5,37
ffffffffc0203eb6:	001d0413          	addi	s0,s10,1
ffffffffc0203eba:	00f50e63          	beq	a0,a5,ffffffffc0203ed6 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0203ebe:	c521                	beqz	a0,ffffffffc0203f06 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ec0:	02500993          	li	s3,37
ffffffffc0203ec4:	a011                	j	ffffffffc0203ec8 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0203ec6:	c121                	beqz	a0,ffffffffc0203f06 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0203ec8:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203eca:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203ecc:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ece:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203ed2:	ff351ae3          	bne	a0,s3,ffffffffc0203ec6 <vprintfmt+0x52>
ffffffffc0203ed6:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203eda:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203ede:	4981                	li	s3,0
ffffffffc0203ee0:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0203ee2:	5cfd                	li	s9,-1
ffffffffc0203ee4:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ee6:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0203eea:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203eec:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0203ef0:	0ff6f693          	andi	a3,a3,255
ffffffffc0203ef4:	00140d13          	addi	s10,s0,1
ffffffffc0203ef8:	20d5e563          	bltu	a1,a3,ffffffffc0204102 <vprintfmt+0x28e>
ffffffffc0203efc:	068a                	slli	a3,a3,0x2
ffffffffc0203efe:	96d2                	add	a3,a3,s4
ffffffffc0203f00:	4294                	lw	a3,0(a3)
ffffffffc0203f02:	96d2                	add	a3,a3,s4
ffffffffc0203f04:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203f06:	70e6                	ld	ra,120(sp)
ffffffffc0203f08:	7446                	ld	s0,112(sp)
ffffffffc0203f0a:	74a6                	ld	s1,104(sp)
ffffffffc0203f0c:	7906                	ld	s2,96(sp)
ffffffffc0203f0e:	69e6                	ld	s3,88(sp)
ffffffffc0203f10:	6a46                	ld	s4,80(sp)
ffffffffc0203f12:	6aa6                	ld	s5,72(sp)
ffffffffc0203f14:	6b06                	ld	s6,64(sp)
ffffffffc0203f16:	7be2                	ld	s7,56(sp)
ffffffffc0203f18:	7c42                	ld	s8,48(sp)
ffffffffc0203f1a:	7ca2                	ld	s9,40(sp)
ffffffffc0203f1c:	7d02                	ld	s10,32(sp)
ffffffffc0203f1e:	6de2                	ld	s11,24(sp)
ffffffffc0203f20:	6109                	addi	sp,sp,128
ffffffffc0203f22:	8082                	ret
    if (lflag >= 2) {
ffffffffc0203f24:	4705                	li	a4,1
ffffffffc0203f26:	008a8593          	addi	a1,s5,8
ffffffffc0203f2a:	01074463          	blt	a4,a6,ffffffffc0203f32 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc0203f2e:	26080363          	beqz	a6,ffffffffc0204194 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc0203f32:	000ab603          	ld	a2,0(s5)
ffffffffc0203f36:	46c1                	li	a3,16
ffffffffc0203f38:	8aae                	mv	s5,a1
ffffffffc0203f3a:	a06d                	j	ffffffffc0203fe4 <vprintfmt+0x170>
            goto reswitch;
ffffffffc0203f3c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203f40:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f42:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203f44:	b765                	j	ffffffffc0203eec <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0203f46:	000aa503          	lw	a0,0(s5)
ffffffffc0203f4a:	85a6                	mv	a1,s1
ffffffffc0203f4c:	0aa1                	addi	s5,s5,8
ffffffffc0203f4e:	9902                	jalr	s2
            break;
ffffffffc0203f50:	bfb9                	j	ffffffffc0203eae <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203f52:	4705                	li	a4,1
ffffffffc0203f54:	008a8993          	addi	s3,s5,8
ffffffffc0203f58:	01074463          	blt	a4,a6,ffffffffc0203f60 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0203f5c:	22080463          	beqz	a6,ffffffffc0204184 <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc0203f60:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0203f64:	24044463          	bltz	s0,ffffffffc02041ac <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0203f68:	8622                	mv	a2,s0
ffffffffc0203f6a:	8ace                	mv	s5,s3
ffffffffc0203f6c:	46a9                	li	a3,10
ffffffffc0203f6e:	a89d                	j	ffffffffc0203fe4 <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc0203f70:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203f74:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203f76:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0203f78:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203f7c:	8fb5                	xor	a5,a5,a3
ffffffffc0203f7e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203f82:	1ad74363          	blt	a4,a3,ffffffffc0204128 <vprintfmt+0x2b4>
ffffffffc0203f86:	00369793          	slli	a5,a3,0x3
ffffffffc0203f8a:	97e2                	add	a5,a5,s8
ffffffffc0203f8c:	639c                	ld	a5,0(a5)
ffffffffc0203f8e:	18078d63          	beqz	a5,ffffffffc0204128 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203f92:	86be                	mv	a3,a5
ffffffffc0203f94:	00002617          	auipc	a2,0x2
ffffffffc0203f98:	2ac60613          	addi	a2,a2,684 # ffffffffc0206240 <error_string+0xe8>
ffffffffc0203f9c:	85a6                	mv	a1,s1
ffffffffc0203f9e:	854a                	mv	a0,s2
ffffffffc0203fa0:	240000ef          	jal	ra,ffffffffc02041e0 <printfmt>
ffffffffc0203fa4:	b729                	j	ffffffffc0203eae <vprintfmt+0x3a>
            lflag ++;
ffffffffc0203fa6:	00144603          	lbu	a2,1(s0)
ffffffffc0203faa:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203fac:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203fae:	bf3d                	j	ffffffffc0203eec <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0203fb0:	4705                	li	a4,1
ffffffffc0203fb2:	008a8593          	addi	a1,s5,8
ffffffffc0203fb6:	01074463          	blt	a4,a6,ffffffffc0203fbe <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0203fba:	1e080263          	beqz	a6,ffffffffc020419e <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc0203fbe:	000ab603          	ld	a2,0(s5)
ffffffffc0203fc2:	46a1                	li	a3,8
ffffffffc0203fc4:	8aae                	mv	s5,a1
ffffffffc0203fc6:	a839                	j	ffffffffc0203fe4 <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0203fc8:	03000513          	li	a0,48
ffffffffc0203fcc:	85a6                	mv	a1,s1
ffffffffc0203fce:	e03e                	sd	a5,0(sp)
ffffffffc0203fd0:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203fd2:	85a6                	mv	a1,s1
ffffffffc0203fd4:	07800513          	li	a0,120
ffffffffc0203fd8:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203fda:	0aa1                	addi	s5,s5,8
ffffffffc0203fdc:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0203fe0:	6782                	ld	a5,0(sp)
ffffffffc0203fe2:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203fe4:	876e                	mv	a4,s11
ffffffffc0203fe6:	85a6                	mv	a1,s1
ffffffffc0203fe8:	854a                	mv	a0,s2
ffffffffc0203fea:	e1fff0ef          	jal	ra,ffffffffc0203e08 <printnum>
            break;
ffffffffc0203fee:	b5c1                	j	ffffffffc0203eae <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203ff0:	000ab603          	ld	a2,0(s5)
ffffffffc0203ff4:	0aa1                	addi	s5,s5,8
ffffffffc0203ff6:	1c060663          	beqz	a2,ffffffffc02041c2 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0203ffa:	00160413          	addi	s0,a2,1
ffffffffc0203ffe:	17b05c63          	blez	s11,ffffffffc0204176 <vprintfmt+0x302>
ffffffffc0204002:	02d00593          	li	a1,45
ffffffffc0204006:	14b79263          	bne	a5,a1,ffffffffc020414a <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020400a:	00064783          	lbu	a5,0(a2)
ffffffffc020400e:	0007851b          	sext.w	a0,a5
ffffffffc0204012:	c905                	beqz	a0,ffffffffc0204042 <vprintfmt+0x1ce>
ffffffffc0204014:	000cc563          	bltz	s9,ffffffffc020401e <vprintfmt+0x1aa>
ffffffffc0204018:	3cfd                	addiw	s9,s9,-1
ffffffffc020401a:	036c8263          	beq	s9,s6,ffffffffc020403e <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc020401e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204020:	18098463          	beqz	s3,ffffffffc02041a8 <vprintfmt+0x334>
ffffffffc0204024:	3781                	addiw	a5,a5,-32
ffffffffc0204026:	18fbf163          	bleu	a5,s7,ffffffffc02041a8 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc020402a:	03f00513          	li	a0,63
ffffffffc020402e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204030:	0405                	addi	s0,s0,1
ffffffffc0204032:	fff44783          	lbu	a5,-1(s0)
ffffffffc0204036:	3dfd                	addiw	s11,s11,-1
ffffffffc0204038:	0007851b          	sext.w	a0,a5
ffffffffc020403c:	fd61                	bnez	a0,ffffffffc0204014 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc020403e:	e7b058e3          	blez	s11,ffffffffc0203eae <vprintfmt+0x3a>
ffffffffc0204042:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204044:	85a6                	mv	a1,s1
ffffffffc0204046:	02000513          	li	a0,32
ffffffffc020404a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020404c:	e60d81e3          	beqz	s11,ffffffffc0203eae <vprintfmt+0x3a>
ffffffffc0204050:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204052:	85a6                	mv	a1,s1
ffffffffc0204054:	02000513          	li	a0,32
ffffffffc0204058:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020405a:	fe0d94e3          	bnez	s11,ffffffffc0204042 <vprintfmt+0x1ce>
ffffffffc020405e:	bd81                	j	ffffffffc0203eae <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204060:	4705                	li	a4,1
ffffffffc0204062:	008a8593          	addi	a1,s5,8
ffffffffc0204066:	01074463          	blt	a4,a6,ffffffffc020406e <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc020406a:	12080063          	beqz	a6,ffffffffc020418a <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc020406e:	000ab603          	ld	a2,0(s5)
ffffffffc0204072:	46a9                	li	a3,10
ffffffffc0204074:	8aae                	mv	s5,a1
ffffffffc0204076:	b7bd                	j	ffffffffc0203fe4 <vprintfmt+0x170>
ffffffffc0204078:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc020407c:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204080:	846a                	mv	s0,s10
ffffffffc0204082:	b5ad                	j	ffffffffc0203eec <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0204084:	85a6                	mv	a1,s1
ffffffffc0204086:	02500513          	li	a0,37
ffffffffc020408a:	9902                	jalr	s2
            break;
ffffffffc020408c:	b50d                	j	ffffffffc0203eae <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc020408e:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0204092:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0204096:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204098:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc020409a:	e40dd9e3          	bgez	s11,ffffffffc0203eec <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc020409e:	8de6                	mv	s11,s9
ffffffffc02040a0:	5cfd                	li	s9,-1
ffffffffc02040a2:	b5a9                	j	ffffffffc0203eec <vprintfmt+0x78>
            goto reswitch;
ffffffffc02040a4:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc02040a8:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040ac:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02040ae:	bd3d                	j	ffffffffc0203eec <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc02040b0:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc02040b4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040b8:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02040ba:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02040be:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02040c2:	fcd56ce3          	bltu	a0,a3,ffffffffc020409a <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc02040c6:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02040c8:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02040cc:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02040d0:	0196873b          	addw	a4,a3,s9
ffffffffc02040d4:	0017171b          	slliw	a4,a4,0x1
ffffffffc02040d8:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc02040dc:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc02040e0:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02040e4:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02040e8:	fcd57fe3          	bleu	a3,a0,ffffffffc02040c6 <vprintfmt+0x252>
ffffffffc02040ec:	b77d                	j	ffffffffc020409a <vprintfmt+0x226>
            if (width < 0)
ffffffffc02040ee:	fffdc693          	not	a3,s11
ffffffffc02040f2:	96fd                	srai	a3,a3,0x3f
ffffffffc02040f4:	00ddfdb3          	and	s11,s11,a3
ffffffffc02040f8:	00144603          	lbu	a2,1(s0)
ffffffffc02040fc:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040fe:	846a                	mv	s0,s10
ffffffffc0204100:	b3f5                	j	ffffffffc0203eec <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0204102:	85a6                	mv	a1,s1
ffffffffc0204104:	02500513          	li	a0,37
ffffffffc0204108:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020410a:	fff44703          	lbu	a4,-1(s0)
ffffffffc020410e:	02500793          	li	a5,37
ffffffffc0204112:	8d22                	mv	s10,s0
ffffffffc0204114:	d8f70de3          	beq	a4,a5,ffffffffc0203eae <vprintfmt+0x3a>
ffffffffc0204118:	02500713          	li	a4,37
ffffffffc020411c:	1d7d                	addi	s10,s10,-1
ffffffffc020411e:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0204122:	fee79de3          	bne	a5,a4,ffffffffc020411c <vprintfmt+0x2a8>
ffffffffc0204126:	b361                	j	ffffffffc0203eae <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204128:	00002617          	auipc	a2,0x2
ffffffffc020412c:	10860613          	addi	a2,a2,264 # ffffffffc0206230 <error_string+0xd8>
ffffffffc0204130:	85a6                	mv	a1,s1
ffffffffc0204132:	854a                	mv	a0,s2
ffffffffc0204134:	0ac000ef          	jal	ra,ffffffffc02041e0 <printfmt>
ffffffffc0204138:	bb9d                	j	ffffffffc0203eae <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020413a:	00002617          	auipc	a2,0x2
ffffffffc020413e:	0ee60613          	addi	a2,a2,238 # ffffffffc0206228 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0204142:	00002417          	auipc	s0,0x2
ffffffffc0204146:	0e740413          	addi	s0,s0,231 # ffffffffc0206229 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020414a:	8532                	mv	a0,a2
ffffffffc020414c:	85e6                	mv	a1,s9
ffffffffc020414e:	e032                	sd	a2,0(sp)
ffffffffc0204150:	e43e                	sd	a5,8(sp)
ffffffffc0204152:	18a000ef          	jal	ra,ffffffffc02042dc <strnlen>
ffffffffc0204156:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020415a:	6602                	ld	a2,0(sp)
ffffffffc020415c:	01b05d63          	blez	s11,ffffffffc0204176 <vprintfmt+0x302>
ffffffffc0204160:	67a2                	ld	a5,8(sp)
ffffffffc0204162:	2781                	sext.w	a5,a5
ffffffffc0204164:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0204166:	6522                	ld	a0,8(sp)
ffffffffc0204168:	85a6                	mv	a1,s1
ffffffffc020416a:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020416c:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020416e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204170:	6602                	ld	a2,0(sp)
ffffffffc0204172:	fe0d9ae3          	bnez	s11,ffffffffc0204166 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204176:	00064783          	lbu	a5,0(a2)
ffffffffc020417a:	0007851b          	sext.w	a0,a5
ffffffffc020417e:	e8051be3          	bnez	a0,ffffffffc0204014 <vprintfmt+0x1a0>
ffffffffc0204182:	b335                	j	ffffffffc0203eae <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc0204184:	000aa403          	lw	s0,0(s5)
ffffffffc0204188:	bbf1                	j	ffffffffc0203f64 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc020418a:	000ae603          	lwu	a2,0(s5)
ffffffffc020418e:	46a9                	li	a3,10
ffffffffc0204190:	8aae                	mv	s5,a1
ffffffffc0204192:	bd89                	j	ffffffffc0203fe4 <vprintfmt+0x170>
ffffffffc0204194:	000ae603          	lwu	a2,0(s5)
ffffffffc0204198:	46c1                	li	a3,16
ffffffffc020419a:	8aae                	mv	s5,a1
ffffffffc020419c:	b5a1                	j	ffffffffc0203fe4 <vprintfmt+0x170>
ffffffffc020419e:	000ae603          	lwu	a2,0(s5)
ffffffffc02041a2:	46a1                	li	a3,8
ffffffffc02041a4:	8aae                	mv	s5,a1
ffffffffc02041a6:	bd3d                	j	ffffffffc0203fe4 <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc02041a8:	9902                	jalr	s2
ffffffffc02041aa:	b559                	j	ffffffffc0204030 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc02041ac:	85a6                	mv	a1,s1
ffffffffc02041ae:	02d00513          	li	a0,45
ffffffffc02041b2:	e03e                	sd	a5,0(sp)
ffffffffc02041b4:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02041b6:	8ace                	mv	s5,s3
ffffffffc02041b8:	40800633          	neg	a2,s0
ffffffffc02041bc:	46a9                	li	a3,10
ffffffffc02041be:	6782                	ld	a5,0(sp)
ffffffffc02041c0:	b515                	j	ffffffffc0203fe4 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02041c2:	01b05663          	blez	s11,ffffffffc02041ce <vprintfmt+0x35a>
ffffffffc02041c6:	02d00693          	li	a3,45
ffffffffc02041ca:	f6d798e3          	bne	a5,a3,ffffffffc020413a <vprintfmt+0x2c6>
ffffffffc02041ce:	00002417          	auipc	s0,0x2
ffffffffc02041d2:	05b40413          	addi	s0,s0,91 # ffffffffc0206229 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02041d6:	02800513          	li	a0,40
ffffffffc02041da:	02800793          	li	a5,40
ffffffffc02041de:	bd1d                	j	ffffffffc0204014 <vprintfmt+0x1a0>

ffffffffc02041e0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02041e0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02041e2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02041e6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02041e8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02041ea:	ec06                	sd	ra,24(sp)
ffffffffc02041ec:	f83a                	sd	a4,48(sp)
ffffffffc02041ee:	fc3e                	sd	a5,56(sp)
ffffffffc02041f0:	e0c2                	sd	a6,64(sp)
ffffffffc02041f2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02041f4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02041f6:	c7fff0ef          	jal	ra,ffffffffc0203e74 <vprintfmt>
}
ffffffffc02041fa:	60e2                	ld	ra,24(sp)
ffffffffc02041fc:	6161                	addi	sp,sp,80
ffffffffc02041fe:	8082                	ret

ffffffffc0204200 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0204200:	715d                	addi	sp,sp,-80
ffffffffc0204202:	e486                	sd	ra,72(sp)
ffffffffc0204204:	e0a2                	sd	s0,64(sp)
ffffffffc0204206:	fc26                	sd	s1,56(sp)
ffffffffc0204208:	f84a                	sd	s2,48(sp)
ffffffffc020420a:	f44e                	sd	s3,40(sp)
ffffffffc020420c:	f052                	sd	s4,32(sp)
ffffffffc020420e:	ec56                	sd	s5,24(sp)
ffffffffc0204210:	e85a                	sd	s6,16(sp)
ffffffffc0204212:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc0204214:	c901                	beqz	a0,ffffffffc0204224 <readline+0x24>
        cprintf("%s", prompt);
ffffffffc0204216:	85aa                	mv	a1,a0
ffffffffc0204218:	00002517          	auipc	a0,0x2
ffffffffc020421c:	02850513          	addi	a0,a0,40 # ffffffffc0206240 <error_string+0xe8>
ffffffffc0204220:	e9ffb0ef          	jal	ra,ffffffffc02000be <cprintf>
readline(const char *prompt) {
ffffffffc0204224:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204226:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0204228:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020422a:	4aa9                	li	s5,10
ffffffffc020422c:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc020422e:	0000db97          	auipc	s7,0xd
ffffffffc0204232:	e12b8b93          	addi	s7,s7,-494 # ffffffffc0211040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204236:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020423a:	ebdfb0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc020423e:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0204240:	00054b63          	bltz	a0,ffffffffc0204256 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204244:	00a95b63          	ble	a0,s2,ffffffffc020425a <readline+0x5a>
ffffffffc0204248:	029a5463          	ble	s1,s4,ffffffffc0204270 <readline+0x70>
        c = getchar();
ffffffffc020424c:	eabfb0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc0204250:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0204252:	fe0559e3          	bgez	a0,ffffffffc0204244 <readline+0x44>
            return NULL;
ffffffffc0204256:	4501                	li	a0,0
ffffffffc0204258:	a099                	j	ffffffffc020429e <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc020425a:	03341463          	bne	s0,s3,ffffffffc0204282 <readline+0x82>
ffffffffc020425e:	e8b9                	bnez	s1,ffffffffc02042b4 <readline+0xb4>
        c = getchar();
ffffffffc0204260:	e97fb0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc0204264:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0204266:	fe0548e3          	bltz	a0,ffffffffc0204256 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020426a:	fea958e3          	ble	a0,s2,ffffffffc020425a <readline+0x5a>
ffffffffc020426e:	4481                	li	s1,0
            cputchar(c);
ffffffffc0204270:	8522                	mv	a0,s0
ffffffffc0204272:	e81fb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i ++] = c;
ffffffffc0204276:	009b87b3          	add	a5,s7,s1
ffffffffc020427a:	00878023          	sb	s0,0(a5)
ffffffffc020427e:	2485                	addiw	s1,s1,1
ffffffffc0204280:	bf6d                	j	ffffffffc020423a <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0204282:	01540463          	beq	s0,s5,ffffffffc020428a <readline+0x8a>
ffffffffc0204286:	fb641ae3          	bne	s0,s6,ffffffffc020423a <readline+0x3a>
            cputchar(c);
ffffffffc020428a:	8522                	mv	a0,s0
ffffffffc020428c:	e67fb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i] = '\0';
ffffffffc0204290:	0000d517          	auipc	a0,0xd
ffffffffc0204294:	db050513          	addi	a0,a0,-592 # ffffffffc0211040 <buf>
ffffffffc0204298:	94aa                	add	s1,s1,a0
ffffffffc020429a:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020429e:	60a6                	ld	ra,72(sp)
ffffffffc02042a0:	6406                	ld	s0,64(sp)
ffffffffc02042a2:	74e2                	ld	s1,56(sp)
ffffffffc02042a4:	7942                	ld	s2,48(sp)
ffffffffc02042a6:	79a2                	ld	s3,40(sp)
ffffffffc02042a8:	7a02                	ld	s4,32(sp)
ffffffffc02042aa:	6ae2                	ld	s5,24(sp)
ffffffffc02042ac:	6b42                	ld	s6,16(sp)
ffffffffc02042ae:	6ba2                	ld	s7,8(sp)
ffffffffc02042b0:	6161                	addi	sp,sp,80
ffffffffc02042b2:	8082                	ret
            cputchar(c);
ffffffffc02042b4:	4521                	li	a0,8
ffffffffc02042b6:	e3dfb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            i --;
ffffffffc02042ba:	34fd                	addiw	s1,s1,-1
ffffffffc02042bc:	bfbd                	j	ffffffffc020423a <readline+0x3a>

ffffffffc02042be <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02042be:	00054783          	lbu	a5,0(a0)
ffffffffc02042c2:	cb91                	beqz	a5,ffffffffc02042d6 <strlen+0x18>
    size_t cnt = 0;
ffffffffc02042c4:	4781                	li	a5,0
        cnt ++;
ffffffffc02042c6:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02042c8:	00f50733          	add	a4,a0,a5
ffffffffc02042cc:	00074703          	lbu	a4,0(a4)
ffffffffc02042d0:	fb7d                	bnez	a4,ffffffffc02042c6 <strlen+0x8>
    }
    return cnt;
}
ffffffffc02042d2:	853e                	mv	a0,a5
ffffffffc02042d4:	8082                	ret
    size_t cnt = 0;
ffffffffc02042d6:	4781                	li	a5,0
}
ffffffffc02042d8:	853e                	mv	a0,a5
ffffffffc02042da:	8082                	ret

ffffffffc02042dc <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc02042dc:	c185                	beqz	a1,ffffffffc02042fc <strnlen+0x20>
ffffffffc02042de:	00054783          	lbu	a5,0(a0)
ffffffffc02042e2:	cf89                	beqz	a5,ffffffffc02042fc <strnlen+0x20>
    size_t cnt = 0;
ffffffffc02042e4:	4781                	li	a5,0
ffffffffc02042e6:	a021                	j	ffffffffc02042ee <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc02042e8:	00074703          	lbu	a4,0(a4)
ffffffffc02042ec:	c711                	beqz	a4,ffffffffc02042f8 <strnlen+0x1c>
        cnt ++;
ffffffffc02042ee:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02042f0:	00f50733          	add	a4,a0,a5
ffffffffc02042f4:	fef59ae3          	bne	a1,a5,ffffffffc02042e8 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc02042f8:	853e                	mv	a0,a5
ffffffffc02042fa:	8082                	ret
    size_t cnt = 0;
ffffffffc02042fc:	4781                	li	a5,0
}
ffffffffc02042fe:	853e                	mv	a0,a5
ffffffffc0204300:	8082                	ret

ffffffffc0204302 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0204302:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0204304:	0585                	addi	a1,a1,1
ffffffffc0204306:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020430a:	0785                	addi	a5,a5,1
ffffffffc020430c:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0204310:	fb75                	bnez	a4,ffffffffc0204304 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0204312:	8082                	ret

ffffffffc0204314 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204314:	00054783          	lbu	a5,0(a0)
ffffffffc0204318:	0005c703          	lbu	a4,0(a1)
ffffffffc020431c:	cb91                	beqz	a5,ffffffffc0204330 <strcmp+0x1c>
ffffffffc020431e:	00e79c63          	bne	a5,a4,ffffffffc0204336 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0204322:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204324:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0204328:	0585                	addi	a1,a1,1
ffffffffc020432a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020432e:	fbe5                	bnez	a5,ffffffffc020431e <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204330:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0204332:	9d19                	subw	a0,a0,a4
ffffffffc0204334:	8082                	ret
ffffffffc0204336:	0007851b          	sext.w	a0,a5
ffffffffc020433a:	9d19                	subw	a0,a0,a4
ffffffffc020433c:	8082                	ret

ffffffffc020433e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020433e:	00054783          	lbu	a5,0(a0)
ffffffffc0204342:	cb91                	beqz	a5,ffffffffc0204356 <strchr+0x18>
        if (*s == c) {
ffffffffc0204344:	00b79563          	bne	a5,a1,ffffffffc020434e <strchr+0x10>
ffffffffc0204348:	a809                	j	ffffffffc020435a <strchr+0x1c>
ffffffffc020434a:	00b78763          	beq	a5,a1,ffffffffc0204358 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc020434e:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0204350:	00054783          	lbu	a5,0(a0)
ffffffffc0204354:	fbfd                	bnez	a5,ffffffffc020434a <strchr+0xc>
    }
    return NULL;
ffffffffc0204356:	4501                	li	a0,0
}
ffffffffc0204358:	8082                	ret
ffffffffc020435a:	8082                	ret

ffffffffc020435c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020435c:	ca01                	beqz	a2,ffffffffc020436c <memset+0x10>
ffffffffc020435e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0204360:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0204362:	0785                	addi	a5,a5,1
ffffffffc0204364:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204368:	fec79de3          	bne	a5,a2,ffffffffc0204362 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020436c:	8082                	ret

ffffffffc020436e <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020436e:	ca19                	beqz	a2,ffffffffc0204384 <memcpy+0x16>
ffffffffc0204370:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0204372:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0204374:	0585                	addi	a1,a1,1
ffffffffc0204376:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020437a:	0785                	addi	a5,a5,1
ffffffffc020437c:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0204380:	fec59ae3          	bne	a1,a2,ffffffffc0204374 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0204384:	8082                	ret
