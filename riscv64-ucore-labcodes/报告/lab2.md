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

