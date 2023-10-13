<h1><center>lab2实验报告</center></h1>
<h5><center>组员：杜鑫 胡博程 刘心源</center></h5>

# 一、基本练习

###  练习1:理解first-fit 连续物理内存分配算法（思考题）

程序总体的执行流：

1.  `entry.S`
   - 
2. ``kern_init()`函数初始化pmm，涉及三个部分
   - `init_pmm_manager()`函数初始化内存管理器，通过结构体指针、函数指针选取内存分配算法 
   - `page_init()` 函数设置 `pages` 数组，跟踪每个物理页的状态，初始化了空闲页列表
   - `check_alloc_page()`函数调用物理内存管理器的 `check` 方法来验证分配和释放函数的正确性。 `check` 方法具体实现依赖于传入`pmm_manager`的指针变量



在`kern/mm/default_pmm.c`中实现了first-fit 连续物理内存分配算法，分配器维护一个称为“空闲列表”的空闲块列表，当接收到内存请求时，它沿着列表扫描，寻找第一个足够大的块来满足请求。如果选择的块明显大于请求的大小，那么通常会将其分割，并将剩余部分添加到列表中作为另一个空闲块。

数据结构和变量:

- `free_area_t free_area`：一个空闲区域结构，包含一个空闲列表（list_entry_t类型，里面有俩指针）和一个空闲块计数器。

- `free_list`：空闲内存块`free_area`的列表。

- `nr_free`：空闲内存块`free_area`的数量



`default_init`函数——初始化`free_area`中的链表和计数器

```c
static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
}
```

调用`list_init`函数，将前项和后项指针都指向自己



`default_init_memmap`函数——初始化一个给定地址和大小的空闲块。

遍历从 `base` 开始的每一个页面，然后设置它们的属性。确保每一页都被预留（`PageReserved(p)`）。然后清除每一页的标志和属性，并设置其引用计数为0。





`default_alloc_pages`函数——根据首次适应算法从空闲列表中分配所需数量的页。



`default_free_pages`函数——将给定的页释放回空闲列表，并尝试合并相邻的空闲块。



`basic_check`和`default_check`函数——用于验证分配器的正确性。





0x8000_0000|----------|0x8020 0000|----------|0x8020 7000|----------|0x8034 7000|----------|0x8800 0000|

​						openSBI						kernl映像						Page结构体				空闲页资源



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



# 三、本实验重要知识点

在RISC-V架构下使用`sv39`模式，虚拟地址到物理地址的转换通过一个三级页表进行。这种转换过程使用虚拟地址的不同部分来索引页表中的不同级别，并最终解析出物理地址。下面是这一过程的基本步骤：

### 虚拟地址划分

在`sv39`模式下，一个39位的虚拟地址通常被划分为多个部分，用于在三级页表中进行查找：

- **VPN[2]:** 虚拟地址的[38:30]位，用于在一级页表中进行查找。
- **VPN[1]:** 虚拟地址的[29:21]位，用于在二级页表中进行查找。
- **VPN[0]:** 虚拟地址的[20:12]位，用于在三级页表中进行查找。
- **Offset:** 虚拟地址的[11:0]位，用于在找到的物理页中找到确切的字节。

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