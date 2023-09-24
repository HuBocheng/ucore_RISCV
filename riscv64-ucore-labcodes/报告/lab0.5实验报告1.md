<h1><center>lab0.5实验报告</center></h1>

<h5><center>组员：杜鑫 胡博程 刘心源</center></h5>

##  一、实验过程

#### 1、使用交叉编译器完成ucore内核的映像文件生成

进入lab0源代码的根目录下执行`make qemu`指令，make工具将解析Makefile文件，并执行交叉编译。

```makefile
.PHONY: qemu 
qemu: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
	$(V)$(QEMU) \
		-machine virt \
		-nographic \
		-bios default \
		-device loader,file=$(UCOREIMG),addr=0x80200000

```

`.PHONY`用于指定make工具的伪目标，之后带有$的变量名在Makefile文件中都被定义，随后在`$(QEMU)`命令下启动QEMU虚拟机设置机器类型为 `virt`，使用了 `-nographic` 选项，意味着不使用图形界面，而是在终端中运行。使用 `-bios default` 指定默认的 BIOS，并使用 `-device` 选项加载 `$(UCOREIMG)` 到指定的地址 `0x80200000`。

命令执行过后将在代码根目录生成多个文件夹，其中bin目录下含有ucore的`kernel`可执行文件和映像文件。

#### 2、使用qemu和gdb调试源代码

为了熟悉使用`qemu`和`gdb`进行调试工作，我们使用`gdb`调试`qemu`模拟的RISC-V计算机加电开始运行到执行应用程序的第一条指令（即跳转到`0x80200000`）这个阶段的执行过程。

我们在一个bash中输入`make debug`，同时打开另一个bash输入`make gdb`开启调试。

```bash
Reading symbols from bin/kernel...
The target architecture is set to "riscv:rv64".
Remote debugging using localhost:1234
0x0000000000001000 in ?? ()
(gdb) 
```

此时我们进入gdb调试界面。

输入指令`x/10i $pc`，可以显示即将执行的10条汇编指令。注意到地址为`0x1010`的指令有`jr`，因此实际程序执行到`0x1010`时就会跳转到`t0`。

```assembly
(gdb) x/10i $pc
=> 0x1000:      auipc   t0,0x0
   0x1004:      addi    a1,t0,32
   0x1008:      csrr    a0,mhartid
   0x100c:      ld      t0,24(t0)
   0x1010:      jr      t0  #在此处会跳转到$t0!
   0x1014:      unimp
   0x1016:      unimp
   0x1018:      unimp
   0x101a:      .2byte  0x8000
   0x101c:      unimp
```

我们使用`info r t0`可以显示`t0`寄存器的值，从而得出前面几条指令完成的功能（也就是练习1的解答，因此答案放在下面）

使用`si`进行单步执行，并查看涉及到的寄存器`t0`的结果～

```bash
0x0000000000001000 in ?? ()
(gdb) info r t0
t0             0x0      0
(gdb) si       
0x0000000000001004 in ?? ()
(gdb) info r t0
t0             0x1000   4096
(gdb) si
0x0000000000001008 in ?? ()
(gdb) info r t0
t0             0x1000   4096
(gdb) info r a1
a1             0x1020   4128
(gdb) info r a0
a0             0x0      0
(gdb) si
0x000000000000100c in ?? ()
(gdb) info r a0
a0             0x0      0
(gdb) info r mhartid
mhartid        0x0      0
(gdb) si
0x0000000000001010 in ?? ()
(gdb) info r t0
t0             0x80000000       2147483648
(gdb) si
0x0000000080000000 in ?? ()    #此时跳转到0x800000000
```

可以发现`mhartid`寄存器中值为0，表明当前线程id为0

程序在跳转到地址`0x80000000`之后继续执行。这个地址处加载`QEMU`自带的bootloader`OpenSBI.bin`，启动OpenSBI固件。(根据实验指导书)

> Qemu 开始执行任何指令之前，首先两个文件将被加载到 Qemu 的物理内存中：即作为 bootloader 的 OpenSBI.bin 被加载到物理内存以物理地址 0x80000000 开头的区域上，同时内核镜像 os.bin 被加载到以物理地址 0x80200000 开头的区域上

```assembly
=> 0x80000000:  csrr    a6,mhartid
   0x80000004:  bgtz    a6,0x80000108
   0x80000008:  auipc   t0,0x0
   0x8000000c:  addi    t0,t0,1032
   0x80000010:  auipc   t1,0x0
   0x80000014:  addi    t1,t1,-16
   0x80000018:  sd      t1,0(t0)
   0x8000001c:  auipc   t0,0x0
   0x80000020:  addi    t0,t0,1020
   0x80000024:  ld      t0,0(t0)
```

`csrr a6,mhartid`:从 `mhartid` (hardware thread ID) 控制和状态寄存器 (CSR) 读取当前硬件线程的 ID 并将其存储到寄存器 `a6` 中。

`bgtz a6,0x80000108`：如果 `a6` 的值大于零，则跳转到地址 `0x80000108`。这可能是为了确保只有主核（核心ID为0）执行后续的初始化代码。

后面的汇编代码涉及内存和寄存器初始化的过程

接下来输入指令`break *0x802000000`，bash输出如下：

```assembly
(gdb) break *0x80200000
Breakpoint 1 at 0x80200000: file kern/init/entry.S, line 7.
```

注意到`0x80200000`是`kernel.ld`中定义的`BASE_ADDRESS`（加载地址）所决定的，同时在`kernel.ld`中也定义了入口点ENTRY`kern_entry`，因此如果我们输入`break kern_entry`，也会得到同样的结果。

```assembly
(gdb) break kern_entry
Note: breakpoint 1 also set at pc 0x80200000.
Breakpoint 2 at 0x80200000: file kern/init/entry.S, line 7.
```

打开`entry.S`，观察相应的代码

```assembly
    .section .text,"ax",%progbits
    .globl kern_entry 
kern_entry:
    la sp, bootstacktop
    tail kern_init
```

`kern_entry`标签对应的汇编代码有两句，解释如下：

- `la sp, bootstacktop`：加载`bootstacktop`的地址到栈指针寄存器`sp`，从而设置栈顶；
- `tail kern_init`：尾调用函数`kern_init`，尾调用直接跳转到目标函数，意味着**当前函数的栈帧将被新调用的函数重用**。

输入`x/10i 0x80200000`，查看接下来的汇编代码：
```assembly
(gdb) x/10i 0x80200000
=> 0x80200000 <kern_entry>:	    auipc	sp,0x3
   0x80200004 <kern_entry+4>:	mv	    sp,sp
   0x80200008 <kern_entry+8>:	j	    0x8020000c <kern_init>
   0x8020000c <kern_init>:	    auipc	a0,0x3
   0x80200010 <kern_init+4>:	addi	a0,a0,-4
   0x80200014 <kern_init+8>:	auipc	a2,0x3
   0x80200018 <kern_init+12>:	addi	a2,a2,-12
   0x8020001c <kern_init+16>:	addi	sp,sp,-16
   0x8020001e <kern_init+18>:	li	    a1,0
   0x80200020 <kern_init+20>:	sub		a2,a2,a0
```

我们可以发现，在`kern_entry`之后紧接着就是`kern_init`符合我们刚查看的`entry.S`。

输入`continue`运行到`0x80200000`处，我们发现`make debug`的窗口有新输出如下：

```bash
OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)
```

证明OpenSBI此时已经启动。

输入指令`break kern_init`，得到输出：

```assembly
(gdb) break kern_init
Breakpoint 3 at 0x8020000c: file kern/init/init.c, line 8. 
```

这里就指向了之前显示为`<kern_init>`的地址`0x802000c` 

继续`continue`，然后输入`disassemble kern_init`查看`kern_init`对应的RISC-V代码

```assembly
Dump of assembler code for function kern_init:
=> 0x000000008020000c <+0>:	    auipc	a0,0x3
   0x0000000080200010 <+4>:		addi	a0,a0,-4 # 0x80203008
   0x0000000080200014 <+8>:		auipc	a2,0x3
   0x0000000080200018 <+12>:	addi	a2,a2,-12 # 0x80203008
   0x000000008020001c <+16>:	addi	sp,sp,-16
   0x000000008020001e <+18>:	li		a1,0
   0x0000000080200020 <+20>:	sub		a2,a2,a0
   0x0000000080200022 <+22>:	sd		ra,8(sp)
   0x0000000080200024 <+24>:	jal		ra,0x802004ce <memset>
   0x0000000080200028 <+28>:	auipc	a1,0x0
   0x000000008020002c <+32>:	addi	a1,a1,1208 # 0x802004e0
   0x0000000080200030 <+36>:	auipc	a0,0x0
   0x0000000080200034 <+40>:	addi	a0,a0,1232 # 0x80200500
   0x0000000080200038 <+44>:	jal		ra,0x80200058 <cprintf>
   0x000000008020003c <+48>:	j		0x8020003c <kern_init+48>
End of assembler dump.
```

观察发现这个函数的最后一条指令`0x000000008020003c <+48>:    j       0x8020003c <kern_init+48>`是跳转到自己开始的地址，所以代码将会一直循环下去。

继续`continue`，观察debug的窗口，发现有新输出：

```bash
(NKU.CST) os is loading ...   #没什么别的意思，就是把THU改成了NKU，看不顺眼😁
```

本次实验过程完结撒花～🎉



## 二、练习1问题

#### **Q1:RISC-V硬件加电后的几条指令在哪里？**

A1:在地址`0x1000`到地址`0x1010`。



#### **Q2:完成了哪些功能？**

根据寄存器结果以及对RISC-V汇编语言的部分查阅，得到每一条指令所完成功能：

- `auipc t0,0x0`：`auipc`是把立即数加到PC上。该指令**将立即数`0x0`左移20位并添加到程序计数器**（PC）的当前值上。将这个结果存储到`t0`寄存器中。此时`t0`中地址为`0x1000`；

- `addi a1,t0,32`：将立即数`32`加到`t0`上，并把这个结果存储在`a1`。此时`a1`的地址为`0x20`；

  P.s.`auipc`将立即数左移20位并添加到程序计数器上，这里涉及到RISC-V 指令集加载多位数（如32位）地址进入寄存器的操作，由于RISC-V指令均为32位，不可能用32位全部表示一个立即数（auipc和lui指令均只有20位表示立即数）所以我们想往寄存器载入32位地址不能只通过一条指令，而是分两条指令分别加载地址的高位和低位（`auipc`指令用于加载高位，`addi`指令用于加载低位）

- `csrr a0,mhartid`：读取状态寄存器`mhartid`，存储到`a0`中。`mhartid`为当前硬件线程的ID；

- `ld t0,24(t0)`：`ld`是从内存中加载一个双字（64位值），这里它从`t0+24`地址处读取一个双字（8字节），存到`t0`；

- `jr t0`：寄存器跳转，跳转到`t0`指向的地址处，这里为`0x80000000`。然后开始加载bootloader。此时RISC-V硬件加电操作完成。





## 三、本实验重要知识点

#### Qemu启动流程

加电 -> OpenSBI 启动 -> 跳转到 0x80200000 (kern/init/entry.S）-> 进入 kern_init() 函数（kern/

init/init.c) -> 调用 cprintf() 输出一行信息-> 结束

#### Makefile

make工具可以依照Makefile文件中的内容自动编译和链接程序，基本规则为

```makefile
target: dependencies
	commands
```

目标即要生成的文件，依赖即目标文件由哪些文件生成，命令即通过执行命令由依赖文件生成目标文件。注意每条命令之前必须有一个tab保持缩进

Makefile中的变量规则：

- $符号表示取变量的值，当变量名多于一个字符时，使用"( )"，定义变量可以在Makefile开头直接用字符串作为变量名
- **`$@`**: 目标文件名，这个变量代表规则中的目标名称。
- **`$<`**: 第一个依赖项，这个变量代表规则中的第一个依赖。
- **`$^`**: 所有的依赖项，列表形式
- **`$\*`**: 当前目标的前缀

对于伪目标（只是一个标签），用make调用的时候执行，使用伪目标是为了解决目录下有与make 命令同名的文件的情况，使用.PHONY关键字，下面是一个`make clean`命令的实现方式，用于删除当前目录中所有的 `.o` 文件，清理编译后生成的目标文件。

```makefile
.PHONY: clean
clean:
	rm -f *.o
```

#### bootloader

负责负责初始化硬件并把操作系统加载到内存里，这里我们用的QEMU 自带的 bootloader: OpenSBI 固件，OpenSBI 将找到操作系统内核的存储位置，并将其加入内存，将PC指向内核的初始化部分，执行操作系统源代码。

本次实验中，作为 bootloader 的 OpenSBI.bin 被加载到物理内存以物理地址 0x80000000 开头的区域上，同时内核镜像 os.bin 被加载到以物理地址 0x80200000 开头的区域上。

P.s. **固件** 是一种特定的计算机软件，他可以为设备更复杂的软件（如操作系统）提供标准化的操作环境，甚至直接作为操作系统，执行控制、监视和数据操作功能。

#### 复位地址

指的是 CPU 在上电的时候，或者按下复位键的时候，PC 被赋的初始值。本实验中，QEMU 模拟的riscv 处理器复位地址为`0x1000`（我们也在程序开始十条汇编指令处验证了这个地址），处理器将从此处开始执行复位代码，将会初始化CPU、内存和外设，之后启动boostloader，加载操作系统内核并将控制权交给操作系统。



## 四、本实验中遇到的问题

#### 环境变量命名冲突

在设定工具链环境变量的时候，使用了下面的命令

```bash
export QEMU=/home/ffang/riscv/qemu-4.1.1
export PATH=$QEMU/riscv32-softmmu:$QEMU/riscv64-softmmu:$PATH

export UCOREIMG=/home/ffang/riscv/labcodes/lab0/bin/ucore.img
export PATH=$UCOREIMG:$PATH
```

这与Makefile文档中的设定冲突，导致了编译使用的命令变成了`/home/ffang/riscv/qemu-4.1.1`但其实应该是`qemu-system-riscv64`

下面代码的意义是如果QEMU这个变量没有定义则增加QEMU作为环境变量，且取值为`qemu-system-riscv64`

```makefile
#ifndef GCCPREFIX
GCCPREFIX := riscv64-unknown-elf-
#endif

ifndef QEMU
QEMU := qemu-system-riscv64
endif
```

从而导致报错：`make: home/ffang/riscv/qemu-4.1.1: 权限不够`

修改环境变量命名，刷新环境变量，报错解除

```bash
export MYQEMU=/home/ffang/riscv/qemu-4.1.1
export PATH=$MYQEMU/riscv32-softmmu:$MYQEMU/riscv64-softmmu:$PATH

export MYUCOREIMG=/home/ffang/riscv/labcodes/lab0/bin/ucore.img
export PATH=$MYUCOREIMG:$PATH
```



#### 指令出现半字指令

有时在`kern_entry`入口处的十条汇编语句这里会出现下面的情况，发现`j       0x8020000a <kern_init>`和` auipc   a0,0x3`之间指令出现了16位的差距，但RISCV指令集的指令应该是规整的32位，不过为了提高代码密度，RISC-V 引入了一个叫做 "Compressed" 的可选扩展，该扩展为常用的操作提供了 16 位版本的指令，目的是减少程序和常用操作的大小，从而在存储和内存带宽上节省空间。

```bash
(gdb) x/10i 0x80200000
=> 0x80200000 <kern_entry>:     auipc   sp,0x3
   0x80200004 <kern_entry+4>:   mv      sp,sp
   0x80200008 <kern_entry+8>:   j       0x8020000a <kern_init>
   0x8020000a <kern_init>:      auipc   a0,0x3
   0x8020000e <kern_init+4>:    addi    a0,a0,-2
   0x80200012 <kern_init+8>:    auipc   a2,0x3
   0x80200016 <kern_init+12>:   addi    a2,a2,-10
   0x8020001a <kern_init+16>:   addi    sp,sp,-16
   0x8020001c <kern_init+18>:   li      a1,0
   0x8020001e <kern_init+20>:   sub     a2,a2,a0
```

使用命令`qemu-system-riscv64 -cpu help`查看该版本QEMU支持的RISCV处理器类型，发现有含‘c’（即支持指令压缩拓展的处理器）

```bash
any
rv64
rv64gcsu-v1.10.0
rv64gcsu-v1.9.1
rv64imacu-nommu
sifive-e51
sifive-u54
```

