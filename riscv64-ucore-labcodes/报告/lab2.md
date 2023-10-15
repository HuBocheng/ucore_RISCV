<h1><center>lab2实验报告</center></h1>
<h5><center>组员：杜鑫 胡博程 刘心源</center></h5>

# 一、基本练习

###  练习1：理解first-fit 连续物理内存分配算法（思考题）

First-Fit首次适应算法通过保持一个空闲块列表（free list），并在接收到内存请求时，扫描列表以找到第一个足够大的块来满足请求。如果选择的块明显大于所请求的大小，它通常会被分割，剩余的部分会被添加回空闲块列表。

##### 程序总体的执行流

1.  `entry.S`
   - 
2. ``kern_init()`函数初始化pmm，涉及三个部分
   - `init_pmm_manager()`函数初始化内存管理器，通过结构体指针、函数指针选取内存分配算法 
   - `page_init()` 函数设置 `pages` 数组，跟踪每个物理页的状态，初始化了空闲页列表
   - `check_alloc_page()`函数调用物理内存管理器的 `check` 方法来验证分配和释放函数的正确性。 `check` 方法具体实现依赖于传入`pmm_manager`的指针变量



在`kern/mm/default_pmm.c`中实现了first-fit 连续物理内存分配算法，分配器维护一个称为“空闲列表”的空闲块列表，当接收到内存请求时，它沿着列表扫描，寻找第一个足够大的块来满足请求。如果选择的块明显大于请求的大小，那么通常会将其分割，并将剩余部分添加到列表中作为另一个空闲块。

##### 数据结构和变量

- `free_area_t free_area`：一个空闲区域结构，包含一个空闲列表（`list_entry_t`类型，里面有俩指针）和一个空闲块计数器。

- `free_list`：空闲内存块`free_area`的列表。

- `nr_free`：空闲内存块`free_area`的数量



##### default_init函数

初始化`free_area`中的列表`free_list`和计数器`nr_free`

```c
static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
}
```

调用`list_init`函数，将前项和后项指针都指向自己

PS：`list_init`定义在`list.h`中，用于初始化双向链表的节点



##### default_init_memmap函数

初始化一个给定基地址和大小的空闲内存块。

遍历从 `base` 开始的每一个页面，然后设置它们的属性。确保每一页都被预留（`PageReserved(p)`）。然后清除每一页的标志和属性，并设置其引用计数为0。



##### default_alloc_pages函数

根据首次适应算法（在`free_list`中查找第一个大小大于或等于n的空闲块，然后调整空闲块的大小，并返回分配块的地址）从空闲列表中分配所需数量的页。



##### default_free_pages函数

将给定的页释放回空闲列表，并尝试合并相邻的空闲块成大的空闲块。



##### basic_check和default_check函数

用于验证分配器的正确性。



默认的DRAM物理内存地址范围：[0x80000000,0x88000000)

|0x8000_0000|----------|0x8020 0000|----------|0x8020 7000|----------|0x8034 7000|----------|0x8800 0000|

	      		openSBI						kernel映像						Page结构体				空闲页资源



### 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）

 `make grade`结果如下

```bash
 make grade
>>>>>>>>>> here_make>>>>>>>>>>>
gmake[1]: 进入目录“/home/ffang/riscv/labcodes/lab2” + cc kern/init/entry.S + cc kern/init/init.c + cc kern/libs/stdio.c + cc kern/debug/kdebug.c + cc kern/debug/kmonitor.c + cc kern/debug/panic.c + cc kern/driver/clock.c + cc kern/driver/console.c + cc kern/driver/intr.c + cc kern/trap/trap.c + cc kern/trap/trapentry.S + cc kern/mm/best_fit_pmm.c + cc kern/mm/default_pmm.c + cc kern/mm/pmm.c + cc libs/printfmt.c + cc libs/readline.c + cc libs/sbi.c + cc libs/string.c + ld bin/kernel riscv64-unknown-elf-objcopy bin/kernel --strip-all -O binary bin/ucore.img gmake[1]: 离开目录“/home/ffang/riscv/labcodes/lab2”
>>>>>>>>>> here_make>>>>>>>>>>>
<<<<<<<<<<<<<<< here_run_qemu <<<<<<<<<<<<<<<<<<
try to run qemu
qemu pid=9773
<<<<<<<<<<<<<<< here_run_check <<<<<<<<<<<<<<<<<<
  -check physical_memory_map_information:    OK
  -check_best_fit:                           OK
  -check ticks:                              OK
```

.

# 二、扩展练习

### Challenge 1：buddy system（伙伴系统）分配算法（需要编程）



### Challenge 2: 任意大小的内存单元slub分配算法（需要编程）



### Challenge 3: 硬件的可用物理内存范围的获取方法（思考题）

可以使用设备树来传递硬件信息给操作系统，包括可用的物理内存范围。设备树是一种数据结构，用于描述计算机硬件的各种属性，如内存大小、缓存大小、处理器类型等。OpenSBI 作为 RISC-V 架构上的固件层，可以利用设备树来提供硬件的相关信息给上层的操作系统



设备树提供了一种标准的方法来描述系统硬件。在设备树中，内存通常由一个或多个“memory”节点描述，这些节点包含描述物理内存范围的属性。例如：

```
memory@80000000 {
    device_type = "memory";
    reg = <0x80000000 0x10000000>;
};
```





OpenSBI 固件完成对于包括物理内存在内的各外设的扫描，将扫描结果以**设备树二进制对象（DTB，Device Tree Blob）**的格式保存在物理内存中的某个地方。而这个放置的物理地址将放在 `a1` 寄存器中，而将会把 HART ID （**HART，Hardware Thread，硬件线程，可以理解为执行的 CPU 核**）放在 `a0` 寄存器上。

# 三、本实验重要知识点

### 虚拟地址空间的布局

```c++
/* *
 * 详细描述了虚拟地址空间的布局。它包括内核空间、用户空间和一些保留区域。例如：
    KERNBASE 到 KERNTOP 是内核的物理内存映射区域。
    USERBASE 到 USERTOP 是用户空间的虚拟地址范围。
 * Virtual memory map:虚拟内存映射                                Permissions
 *                                                              kernel/user
 *
 *     4G ------------------> +---------------------------------+
 *                            |                                 |
 *                            |         Empty Memory (*)        |
 *                            |                                 |
 *                            +---------------------------------+ 0xFB000000
 *                            |   Cur. Page Table (Kern, RW)    | RW/-- PTSIZE
 *     VPT -----------------> +---------------------------------+ 0xFAC00000
 *                            |        Invalid Memory (*)       | --/--
 *     KERNTOP -------------> +---------------------------------+ 0xF8000000
 *                            |                                 |
 *                            |    Remapped Physical Memory     | RW/-- KMEMSIZE
 *                            |                                 |
 *     KERNBASE ------------> +---------------------------------+ 0xC0000000
 *                            |        Invalid Memory (*)       | --/--
 *     USERTOP -------------> +---------------------------------+ 0xB0000000
 *                            |           User stack            |
 *                            +---------------------------------+
 *                            |                                 |
 *                            :                                 :
 *                            |         ~~~~~~~~~~~~~~~~        |
 *                            :                                 :
 *                            |                                 |
 *                            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *                            |       User Program & Heap       |
 *     UTEXT ---------------> +---------------------------------+ 0x00800000
 *                            |        Invalid Memory (*)       | --/--
 *                            |  - - - - - - - - - - - - - - -  |
 *                            |    User STAB Data (optional)    |
 *     USERBASE, USTAB------> +---------------------------------+ 0x00200000
 *                            |        Invalid Memory (*)       | --/--
 *     0 -------------------> +---------------------------------+ 0x00000000
 * (*) Note: The kernel ensures that "Invalid Memory" is *never* mapped.
 *     "Empty Memory" is normally unmapped, but user programs may map pages
 *     there if desired.
 *  
 * */
```

1. 用户栈的顶部地址 `USTACKTOP`，并将其设置为与用户空间的顶部地址 `USERTOP` 相同

   - 保护内核空间：将用户栈放在用户空间的顶部有助于防止栈溢出错误影响内核空间。因为用户空间和内核空间通常是分开的，用户栈在顶部意味着它远离内核空间
   - 利用虚拟内存：用户栈的大小可以动态变化。将用户栈放在地址空间的顶部可以使栈有更多的空间来动态增长（向下增长），而不会与其他如堆（heap）等区域发生冲突。
   - 简化内存管理：通过将用户栈放在固定的位置（用户空间的顶部），操作系统可以更容易地管理和分配栈空间，因为它总是知道栈的起始地址

2. 内核如何处理“无效内存”（Invalid Memory）和“空内存”（Empty Memory）区域

   - “无效内存”区域是不会被映射到物理内存的。

     这意味着，如果试图访问这些区域的地址，将会触发一个异常或错误，因为这些地址没有对应的物理内存。保持这些区域为无效内存有助于捕获和防止某些类型的程序错误，如空指针解引用。

   - “空内存”区域通常也是未映射的

     意味着在默认情况下，这些地址没有映射到物理内存。但与“无效内存”不同，用户程序可以根据需要将页面映射到“空内存”区域。这提供了一些灵活性，允许用户程序使用更多的虚拟地址空间





在RISC-V架构下使用`sv39`模式，其中39指的是虚拟地址空间的大小，即 39 位。这个转换通过一个三级页表进行。其中`sv39`的标准页大小是4KB，这意味着**每个页包含 4096 个字节**。由于虚拟地址有 39 位，所以 sv39 能够支持的**虚拟地址空间大小是 512GB**。但物理地址可以更长，例如 56 位。这允许系统访问更大的物理内存空间。

这种转换过程使用虚拟地址的不同部分来索引页表中的不同级别，并最终解析出物理地址。下面是这一过程的基本步骤：

### 虚拟地址划分

```c++
// Sv39 linear address structure
// +-------9--------+-------9--------+--------9---------+----------12----------+
// |      VPN2      |      VPN1      |       VPN0       |  Offset within Page  |
// +----------------+----------------+------------------+----------------------+

// Sv39 in RISC-V64 uses 39-bit virtual address to access 56-bit physical address!
// Sv39 page table entry:
// +-------10--------+--------26-------+--------9----------+--------9--------+---2----+-------8-------+
// |    Reserved     |      PPN[2]     |      PPN[1]       |      PPN[0]     |Reserved|D|A|G|U|X|W|R|V|
// +-----------------+-----------------+-------------------+-----------------+--------+---------------+
```



在`sv39`模式下，一个39位的虚拟地址通常被划分为多个部分：27位的页号和12位的页内偏移，用于在三级页表中进行查找：

- **VPN[2]:** 虚拟地址的[38:30]位，用于在一级页表中进行查找。
- **VPN[1]:** 虚拟地址的[29:21]位，用于在二级页表中进行查找。
- **VPN[0]:** 虚拟地址的[20:12]位，用于在三级页表中进行查找。
- **Offset:** 虚拟地址的[11:0]位，用于在找到的物理页中找到确切的字节。

整个Sv39的虚拟内存空间里，有512（2的9次方）个大大页，每个大大页里有512个大页，每个大页里有512个页，每个页里有4096个字节，整个虚拟内存空间里就有512∗512∗512∗4096个字节，是512GiB的地址空间。

### 分级页表

如果页表项非法（没有对应的物理页）则只需要用一个非法的页表项来覆盖这个大页而不需要分别建立一大堆页表项

### 页表查找过程

1. **一级页表查找：**
   - 使用`satp`寄存器（存储一级页表基地址）和VPN[2]来找到一级页表项（PTE）。
   - 检查PTE的有效位和其他权限位是否满足要求。
   - 如果PTE无效或不允许所需的访问类型，则触发一个异常。
   - 否则，PTE中的物理页号（PPN）字段指向二级页表的基地址。
2. **二级页表查找：**
   - 使用一级页表查找到的PPN和VPN[1]找到二级页表项。
   - 再次检查PTE的有效位和权限位。
   - 如果PTE无效或不允许所需的访问类型，则触发一个异常。
   - 否则，PTE中的PPN字段指向三级页表的基地址。
3. **三级页表查找：**
   - 使用二级页表查找到的PPN和VPN[0]找到三级页表项。
   - 再次检查PTE的有效位和权限位。
   - 如果PTE无效或不允许所需的访问类型，则触发一个异常。
   - 否则，PTE中的PPN字段指向目标物理页的基地址。
4. **物理地址计算：**
   - 使用三级页表查找到的PPN和原始虚拟地址的Offset部分拼接形成最终的物理地址。

这个过程中，虚拟地址的各个部分用于在页表的不同级别中进行查找，并最终找到物理地址。这个过程通常在硬件层面自动进行，对上层的软件来说是透明的。在实际实现中，硬件和操作系统可能还会使用TLB（Translation Lookaside Buffer）等缓存机制来加速虚拟地址到物理地址的转换过程。





在页表转换中，**虚拟页面号（VPN，Virtual Page Number）用于索引页表（页表是个数组，虚拟页面号索引页表数组的项，每个页表项64位8字节）**，并从中得到相应的页表条目（Page Table Entry，PTE）。每一个PTE包含一个物理页面号（PPN，Physical Page Number）以及一些控制位，如有效位、可读位、可写位等。在 `sv39` 模式下，每个PTE是64位，其中包含一个物理页号和一些标志位。

在多级页表中，最高层的页表基址通常存储在一个特定的寄存器中。在 RISC-V 架构中，这个寄存器通常被称为 `satp`（在某些文档中也可能被称为 `ptbr`，页表基址寄存器）。

下面是 VPN22 是如何用于一级页表中查找的具体步骤：

### 步骤 1: 获取一级页表基址

- 从 `satp` 寄存器中获取一级页表的物理基址。

### 步骤 2: 使用 VPN2 索引一级页表

- 使用 VPN2乘以页表条目的大小（在 RISC-V 中，通常是 8 字节，因为每个 PTE 是 64 位）得到在一级页表中的偏移。
  $$
  Offset=VPN[2]×PTE sizeOffset=VPN[2]×PTE size
  $$
  
- 将一级页表的基址与上述偏移相加，得到目标页表条目在物理内存中的地址：
  $$
  PTE address=Level-1 Page Table Base Address+Offset
  $$
  

### 步骤 3: 获取 PTE

- **从计算得到的物理地址处读取 PTE**。这个 PTE 包含下一级页表的物理基址以及一些控制和状态位。

### 步骤 4: 检查 PTE 的有效性

- 检查 PTE 中的控制位，确保这个条目是有效的，并且允许请求的访问类型（例如，读、写或执行）。
- 如果 PTE 无效或不允许请求的访问类型，则触发一个页面错误或者其他类型的异常，这取决于操作系统的具体实现。

### 步骤 5: 使用 PTE 获取下一级页表的基址

- 如果 PTE 是有效的，那么它包含下一级（二级）页表的物理基址。这个地址将用于后续的地址转换过程，使用 VPN11 和 VPN00 作为索引来访问更低级别的页表。



### 页表基址

在翻译的过程中，我们首先需要知道树状页表的根节点的物理地址。这一般保存在一个特殊寄存器里。对于RISCV架构，是一个叫做`satp`（Supervisor Address Translation and Protection Register）的CSR。实际上，`satp`里面**存的不是最高级页表的起始物理地址，而是它所在的物理页号**。除了物理页号，`satp`还包含其他信息。



# buddy_system设计文档

数据结构

```c
/* buddy system 的结构体 */
#define MAX_BUDDY_ORDER 14 // 0x7cb9 31929，不到2的15次方个页
typedef struct
{
    unsigned int max_order;                       // 实际最大块的大小
    list_entry_t free_array[MAX_BUDDY_ORDER + 1]; // 伙伴堆数组
    unsigned int nr_free;                         // 伙伴系统中剩余的空闲块
} free_buddy_t;
```

实现思路

将之前的单个free_list拓展为一个free_list数组，数组的第i项负责维护大小为2^i个页的块。

初始化函数`buddy_system_init`：数组中的每一个free_list的初始化，next prev指针指向自己

初始化空闲内存块函数`buddy_system_init_memmap`：除了清除标记等，直接将最大的这个内存块的首页的free_list连接在数组最后一个元素的链表后面

分配内存块函数`buddy_system_alloc_pages`：分配的内存块向上取到2的幂次的数，找到这个幂次大小的块对应的数组元素（free_list）查看这个链表中有没有空闲的块，有的话分配，没的话就从大的块中切割，**注意切割的时候设置好flags**

释放内存函数`buddy_system_free_pages`：找到释放的块的大小及其对应的`free_array`数组下标，把块添加到对应下标的free_list中，然后检测是否存在内存块合并的情况（当两个空闲的内存块相邻的时候，也就是伙伴块相邻的时候可以合并），合并的时候从`free_array`数组中删除小块，添加一个大块，并且循环检测执行。

寻找伙伴块函数`get_buddy`：可以使用下面的公式计算伙伴块地址buddyAddr：
$$
buddyAddr=blockAddr  \quad XOR \quad  blockSize
$$
但是由于我们的内存地址不是从0开始，而且我们只需要依照已知Page结构体的地址找到其伙伴Page结构体的地址，而一个Page结构体的大小为0x28，我们可以减去第一个Page结构体的地址，然后令相对地址和0x28*blockSize进行按位与操作，得到伙伴Page结构体的地址。

