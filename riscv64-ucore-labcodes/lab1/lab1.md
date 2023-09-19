<h1><center>lab1实验报告</center></h1>
<h5><center>组员：杜鑫 胡博程 刘心源</center></h5>

# 一、基本练习

###  练习1:理解内核启动中的程序入口操作

```asm
    la sp, bootstacktop
```

- 操作：本条指令将`bootstacktop`的地址加载到堆栈指针`sp`中，即将`bootstacktop`作为堆栈的起始地址。
- 目的：在操作系统的内核启动过程中，需要初始化堆栈指针来设置一个区域存储局部变量和函数调用时的返回地址，因此需要将`bootstacktop`作为堆栈的起始地址。这样设置也可以确保内核有一个定义好的、不会与其他数据冲突的堆栈空间。

```asm
    tail kern_init
```

- 操作：尾调用函数`kern_init`，直接跳转到`kern_init`函数的入口地址。
- 目的：`kern_init`是内核初始化的主函数，尾调用后开始内核的初始化。同时使用尾调用直接跳转到目标函数，意味着当前函数的栈帧将被新调用的函数重用，可以避免在函数返回时需要额外的栈空间，防止栈溢出～

### 练习2:完善中断处理

根据题目要求补充代码如下：

```c
    /* LAB1 EXERCISE2   2112614 :  */
    /*(1)设置下次时钟中断- clock_set_next_event()
        *(2)计数器（ticks）加一
        *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
    * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
    */
    clock_set_next_event();
    ticks++;
    if(ticks==100){
        ticks=0;
        print_ticks();
        if(num==10){
            sbi_shutdown();
        }
        num++;
    }
```

**实现过程**：

- 设置下一次时钟中断：调用`clock_set_next_event()`函数，设置下一次时钟中断的时间；
- 更新时间中断计数器`ticks`：每次时钟中断发生时，更新计数器`ticks`的值，`ticks++`；
- 100次时钟中断后打印消息：当计数器`ticks`加到100时，表示发生了100次时钟中断，此时调用函数`print_ticks()`打印消息`100ticks`，并将计数器`ticks`清零；
- 检查是否需要关机：使用变量`num`记录打印消息的次数，当计数器`ticks`累加到100时，`num++`。当`num`为10时，表示已经打印了10次消息，此时调用函数`sbi_shutdown()`关机。

**运行结果**：

```bash
    Special kernel symbols:
    entry  0x000000008020000a (virtual)
    etext  0x00000000802009a0 (virtual)
    edata  0x0000000080204010 (virtual)
    end    0x0000000080204028 (virtual)
    Kernel executable memory footprint: 17KB
    ++ setup timer interrupts
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
```

约为1秒钟打印一次`100 ticks`，共打印了10次，之后关机。

**定时器中断处理流程**：

- 初始化中断描述表IDT：在`trap.c`文件的`idt_init`函数中系统设置了异常向量地址并将`sscratch`寄存器设置为0，表示当前在内核模式下执行；

```c
void idt_init(void) {
    extern void __alltraps(void);
    write_csr(sscratch, 0);
    write_csr(stvec, &__alltraps);
}
```

- 中断入口：在`trapentry.S`文件中定义一个全局标签`__alltraps`，这是所有中断和异常入口的入口地址。在入口点它会保存所有的寄存器状态，然后调用`trap`函数；

```asm
    .globl __alltraps
    .align(2)
    __alltraps:
        SAVE_ALL
        move  a0, sp
        jal trap
    __trapret:
        RESTORE_ALL
        sret
```

- 中断处理：在`trap.c`文件中定义了`trap`函数，它根据`trapframe`结构中的`cause`字段来判断是中断还是异常，并调用相应的处理函数；

```c
void trap(struct trapframe *tf) {
    trap_dispatch(tf);
}
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
        interrupt_handler(tf);
    } else {
        exception_handler(tf);
    }
}
```

- 定时器中断处理：在`trap.c`文件中定义了`clock_interrupt_handler`函数，它会调用`clock_set_next_event`函数设置下一次时钟中断的时间，并更新计数器`ticks`的值。当计数器`ticks`加到100时，表示发生了100次时钟中断，此时调用函数`print_ticks()`打印消息`100ticks`，并将计数器`ticks`清零。使用变量`num`记录打印消息的次数，当计数器`ticks`累加到100时，`num++`。当`num`为10时，表示已经打印了10次消息，此时调用函数`sbi_shutdown()`关机。

# 二、扩展练习

### Challenge 1：描述与理解中断流程

中断机制，就是不管 CPU 现在手里在干啥活，收到“中断”的时候，都先放下来去处理其他事情，处理完其他事情可能再回来干手头的活。

本实验中，我们通过时钟中断

`kern/trap/trapentry.S`：中断入口点设置再在这个位置，用于保存和恢复上下文，并把上下文包装成结构体送到`trap` 函数处理

`kern/trap/trap.c(h)`：分发不同类型的中断给不同的 handler, 完成上下文切换之后对中断的具体处理



在kern/trap/trap.c的代码中写有中断处理函数`interrupt_handler`和异常处理函数`exception_handler`：

- `interrupt_handler`: 此函数根据`trapframe`中的`cause`字段处理各种中断。它识别中断的类型（软件、计时器或外部）并相应地行动。此函数中的一个关键部分是处理监督者计时器中断，其中系统处理时钟滴答并检查是否应打印滴答或关闭系统。

- `exception_handler`: 该函数根据`trapframe`中的`cause`字段处理各种异常。例如，它通过打印消息然后前进`epc`（程序计数器）来跳过非法指令或断点来处理非法指令和断点。其他异常类型是占位符，目前不做任何处理。

`tf` 是指向 `trapframe` 结构的指针，而`trapframe` 是一个特殊的数据结构，用于保存处理器的状态，当发生异常或中断时，处理器的当前状态（例如各种寄存器的值）会被保存到这个结构中，类似上课讲授的保存进程上下文context的数据结构PCB。



我们在内核初始化函数中有如下一段代码

```c
int kern_init(void)
{
    // 其他代码......

    // grade_backtrace();

    idt_init(); // init interrupt descriptor table

    // rdtime in mbare mode crashes
    clock_init(); // init clock interrupt

    intr_enable(); // enable irq interrupt

    // 其他代码......

    while (1)
        ;
}
```

`idt_init()`函数用于初始化中断，主要是初始化中断描述符表（IDT），它主要是为了告诉操作系统如何处理不同的中断和异常

`clock_init()`函数用于初始化时钟中断

`intr_enable()`函数用于使能中断



初始化中断函数`idt_init()`的分析在前文已经提及

下面是`clock_init()`与`intr_enable()`函数的解析

```c
// kern/driver/clock.c
/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    // timebase = sbi_timebase() / 500;
    clock_set_next_event();

    // initialize time counter 'ticks' to zero
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
```

- `set_csr(sie, MIP_STIP);`：在 `sie` (Supervisor Interrupt Enable) 寄存器中设置 `MIP_STIP` 位，从而允许时钟中断。
- `clock_set_next_event();`：预计这个函数设置下一个时钟中断事件。具体细节可能在另一部分代码中，但其基本目的是告诉硬件何时触发下一个时钟中断。
- `ticks = 0;`：初始化一个名为 `ticks` 的时间计数器为0。
- `cprintf("++ setup timer interrupts\n");`：在控制台上打印一条消息表示时钟中断已经设置。
- `clock_set_next_event`函数使用`get_cycles()` 这个函数返回当前的时间，`timebase`: 这个变量定义了两次连续的时钟中断之间的时间间隔，`sbi_set_timer(...)`: 这是一个RISC-V特定的函数，它告诉底层的 Supervisor Binary Interface (SBI) 在何时触发下一个时钟中断

```c
// kern/driver/intr.c
/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
```

`set_csr(sstatus, SSTATUS_SIE)`在 `sstatus` (Supervisor Status) 寄存器中设置 `SSTATUS_SIE` 位。这样，当任何中断发生时，CPU 就会被通知，并跳转到之前在 `idt_init()` 中设置的中断处理函数。

OS支持的中断处理方法：

- 编写相应的中断处理代码
- 在启动中正确设置控制寄存器
- CPU 捕获异常
- 控制转交给相应中断处理代码进行处理
- 返回正在运行的程序



而异常和中断不一样，异常恢复的时候要通常是要执行下一条指令，不是当前指令，这一点在Challenge3部分会有详细的体现。



### Challenge 2: 理解上下文切换机制



### Challenge 3: 完善异常中断

##### 完善目标

在 kern/trap/trap.c 的异常处理函数中捕获非法指令异常与断点异常，并针对两种异常进行处理，简单输出异常类型和异常指令触发地址，并相应调整`tf->epc`寄存器

##### 代码编写

仿照时钟中断的处理代码，我们在`kern/trap/trap.c`中找到了异常处理函数`exception_handler`，并针对两种异常进行捕获和处理，完善后的代码如下

```c
// kern/trap/trap.c
void exception_handler(struct trapframe *tf)
{
    switch (tf->cause)
    {
    case CAUSE_MISALIGNED_FETCH:
        break;
    case CAUSE_FAULT_FETCH:
        break;
    case CAUSE_ILLEGAL_INSTRUCTION:
        // 非法指令异常处理
        /* LAB1 CHALLENGE3   2111194 :  */
        /*(1)输出指令异常类型（ Illegal instruction）
         *(2)输出异常指令地址
         *(3)更新 tf->epc寄存器
         */
        cprintf("Exception type:Illegal instruction\n");
        cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
        tf->epc += 4; // Skip the illegal instruction
        break;

        break;
    case CAUSE_BREAKPOINT:
        // 断点异常处理
        /* LAB1 CHALLLENGE3   2111194 :  */
        /*(1)输出指令异常类型（ breakpoint）
         *(2)输出异常指令地址
         *(3)更新 tf->epc寄存器
         */
        cprintf("Exception type: breakpoint\n");
        cprintf("Iebreak caught at 0x%08x\n", tf->epc);
        tf->epc += 4; // Skip the illegal instruction
        break;
            
    // 其他代码......
            
    }
}
```

异常处理一共三步

- 通过传递来的`trapframe` 结构的指针`tf`的cause字段判断异常类型，进入对应的分支进行处理

- 分别输出异常类型与异常捕获的位置（通过`trapframe` 结构的指针`tf`中的`epc`寄存器获取异常捕获的位置）

P.S.前文我们提及过，在遇到中断或异常的时候会发生上下文context的切换，而`trapframe` 结构就是用于保存所有寄存器状态的，其中有一个专门的寄存器储存异常发生的位置，就是`epc`寄存器

- 通过`epc`寄存器递增4跳过非法指令

这是因为：`epc` 寄存器保存的是引起异常的那条指令的地址，亦是中断处理函数的返回地址，而RISCV大多数指令的长度为 32 位，即 4 个字节，将返回地址递增4即可跳过异常指令。



随后在内核初始化的函数中，我们直接调用两条汇编语句触发两种异常：

```c
// kern/init/init.c
int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);

    cons_init(); // init the console

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);

    print_kerninfo();

    // grade_backtrace();

    idt_init(); // init interrupt descriptor table

    // rdtime in mbare mode crashes
    clock_init(); // init clock interrupt

    intr_enable(); // enable irq interrupt

    asm volatile("ebreak"); // 插入断点指令

    asm volatile(".word 0x00000000"); // 一个无效的指令

    while (1)
        ;
}
```

##### 运行结果

```bash
Exception type: breakpoint
Iebreak caught at 0x80200050
Exception type:Illegal instruction
Illegal instruction caught at 0x80200054
```

##### 区分异常与中断

- **异常**：异常是由程序执行中的错误或特殊条件引起的。例如，除以零、非法指令或访问未分配的内存等都会触发异常。
- **中断：**中断是由外部设备或事件引起的，与当前执行的程序无关。例如，I/O 设备完成数据传输、定时器溢出或其他硬件事件都可能触发中断。

在kern/trap/trap.c代码中，内联函数`trap_dispatch`检查`trapframe`中的`cause`字段来判断。对于中断，它调用`interrupt_handler`；对于异常，它调用`exception_handler`。

```c
/* trap_dispatch - dispatch based on what type of trap occurred */
static inline void trap_dispatch(struct trapframe *tf)
{
    if ((intptr_t)tf->cause < 0)
    {
        // interrupts
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
    }
}
```

此外，异常和中断的处理方法是不一样的：

异常恢复的时候，OS可能会也可能不会执行引起异常的指令，就是说跳过还是不跳过异常指令是分情况的，例如非法指令或除以零，操作系统通常不会重新执行引起异常的指令，但是对于缺页异常等，OS是可以再次执行原先触发异常的指令。

而对于中断，中断的发生与当前指令的执行无关，故不需要对`epc`进行更改，不需要跳过返回地址指向的这个指令。

# 三、本实验重要知识点

### 上下文切换



# 四、实验中遇到的问题