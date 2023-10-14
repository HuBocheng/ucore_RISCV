#ifndef __KERN_MM_MEMLAYOUT_H__
#define __KERN_MM_MEMLAYOUT_H__

/* This file contains the definitions for memory management in our OS. */

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

/* All physical memory mapped at this address */
#define KERNBASE            0xFFFFFFFFC0200000        //内核的基地址，所有的物理内存都映射到从这个地址开始的虚拟地址空间
#define KMEMSIZE            0x7E00000                 //内核可以使用的最大物理内存大小
#define KERNTOP             (KERNBASE + KMEMSIZE)     //内核虚拟地址空间的顶部地址

#define PHYSICAL_MEMORY_END         0x88000000
#define PHYSICAL_MEMORY_OFFSET      0xFFFFFFFF40000000 //物理地址和虚拟地址的偏移量
#define KERNEL_BEGIN_PADDR          0x80200000
#define KERNEL_BEGIN_VADDR          0xFFFFFFFFC0200000
/* *
 * Virtual page table. Entry PDX[VPT] in the PD (Page Directory) contains
 * a pointer to the page directory itself, thereby turning the PD into a page
 * table, which maps all the PTEs (Page Table Entry) containing the page mappings
 * for the entire virtual address space into that 4 Meg region starting at VPT.
 * */

#define KSTACKPAGE          2                           //内核栈的页面数量
#define KSTACKSIZE          (KSTACKPAGE * PGSIZE)       //内核栈的大小

#define USERTOP             0x80000000          //用户空间虚拟地址的顶部地址
#define USTACKTOP           USERTOP             //用户栈通常位于用户虚拟地址空间的顶部，并且向下增长
#define USTACKPAGE          256                         // 用户栈的页面数量
#define USTACKSIZE          (USTACKPAGE * PGSIZE)       // 用户栈的大小

#define USERBASE            0x00200000          //用户空间虚拟地址的基地址
#define UTEXT               0x00800000                  // 用户程序通常开始的虚拟地址
#define USTAB               USERBASE                    // the location of the user STABS data structure

#define USER_ACCESS(start, end)                     \
(USERBASE <= (start) && (start) < (end) && (end) <= USERTOP)//检查地址范围是否在用户空间内

#define KERN_ACCESS(start, end)                     \
(KERNBASE <= (start) && (start) < (end) && (end) <= KERNTOP)//检查地址范围是否在内核空间内

#ifndef __ASSEMBLER__

#include <defs.h>
#include <atomic.h>
#include <list.h>

typedef uintptr_t pte_t;
typedef uintptr_t pde_t;
typedef pte_t swap_entry_t; //the pte can also be a swap entry

/* *
 * struct Page - Page descriptor structures. Each Page describes one
 * physical page. In kern/mm/pmm.h, you can find lots of useful functions
 * that convert Page to other data types, such as physical address.
 * */
struct Page {
    int ref;                        // page frame's reference counter
    uint64_t flags;                 // array of flags that describe the status of the page frame
    unsigned int property;          // the num of free block, used in first fit pm manager
    list_entry_t page_link;         // free list link
    list_entry_t pra_page_link;     // used for pra (page replace algorithm)
    uintptr_t pra_vaddr;            // used for pra (page replace algorithm)
};

/* Flags describing the status of a page frame */
//页面保留标志。如果设置，则页面被内核保留，不能被分配或释放
#define PG_reserved                 0       // if this bit=1: the Page is reserved for kernel, cannot be used in alloc/free_pages; otherwise, this bit=0 
//页面属性标志。如果设置，表示页面是空闲内存块的头页面
#define PG_property                 1       // if this bit=1: the Page is the head page of a free memory block(contains some continuous_addrress pages), and can be used in alloc_pages; if this bit=0: if the Page is the the head page of a free memory block, then this Page and the memory block is alloced. Or this Page isn't the head page.

#define SetPageReserved(page)       set_bit(PG_reserved, &((page)->flags))//设置页面为保留状态
#define ClearPageReserved(page)     clear_bit(PG_reserved, &((page)->flags))//清除页面的保留状态
#define PageReserved(page)          test_bit(PG_reserved, &((page)->flags))//检查页面是否被保留
#define SetPageProperty(page)       set_bit(PG_property, &((page)->flags))//设置页面的属性标志
#define ClearPageProperty(page)     clear_bit(PG_property, &((page)->flags))//清除页面的属性标志
#define PageProperty(page)          test_bit(PG_property, &((page)->flags))//检查页面的属性标志是否被设置

/**le2page(le, member)，用于将双向链表节点（list_entry_t）转换为页面结构体（struct Page）
 * 使用了一个名为 to_struct 的函数，将双向链表节点的地址转换为页面结构体的地址
 * 其中，le 是双向链表节点的指针，member 是页面结构体在双向链表节点中的成员名
 * 这个宏定义在管理空闲页面时会用到
*/
#define le2page(le, member)                 \
    to_struct((le), struct Page, member)

/* free_area_t - maintains a doubly linked list to record free (unused) pages */
/**
 * free_area_t 结构体，用于维护一个双向链表，记录空闲页面的信息。
 * 它包含两个成员：free_list 是双向链表的头节点，用于链接所有空闲页面；nr_free 是空闲页面的数量
 * 这个结构体在管理空闲页面时会用到
*/
typedef struct {
    list_entry_t free_list;         // the list header
    unsigned int nr_free;           // # of free pages in this free list
} free_area_t;


#endif /* !__ASSEMBLER__ */

#endif /* !__KERN_MM_MEMLAYOUT_H__ */

