#ifndef __KERN_MM_MEMLAYOUT_H__
#define __KERN_MM_MEMLAYOUT_H__

/* All physical memory mapped at this address */
#define KERNBASE 0xFFFFFFFFC0200000 // = 0x80200000(物理内存里内核的起始位置, KERN_BEGIN_PADDR) + 0xFFFFFFFF40000000(偏移量, PHYSICAL_MEMORY_OFFSET)
// 把原有内存映射到虚拟内存空间的最后一页
#define KMEMSIZE 0x7E00000 // the maximum amount of physical memory
// 0x7E00000 = 0x8000000 - 0x200000
// QEMU 缺省的RAM为 0x80000000到0x88000000, 128MiB, 0x80000000到0x80200000被OpenSBI占用
#define KERNTOP (KERNBASE + KMEMSIZE) // 0x88000000对应的虚拟地址

#define PHYSICAL_MEMORY_END 0x88000000
#define PHYSICAL_MEMORY_OFFSET 0xFFFFFFFF40000000
#define KERNEL_BEGIN_PADDR 0x80200000
#define KERNEL_BEGIN_VADDR 0xFFFFFFFFC0200000

#define KSTACKPAGE 2                     // # of pages in kernel stack
#define KSTACKSIZE (KSTACKPAGE * PGSIZE) // sizeof kernel stack

#ifndef __ASSEMBLER__

#include <defs.h>
#include <atomic.h>
#include <list.h>

typedef uintptr_t pte_t;
typedef uintptr_t pde_t;

/* *
 * struct Page - Page descriptor structures. Each Page describes one
 * physical page. In kern/mm/pmm.h, you can find lots of useful functions
 * that convert Page to other data types, such as physical address.
 * */
struct Page
{
    int ref;                // page frame's reference counter表示有多少个实体（例如进程、文件等）正在使用这个页面
    uint64_t flags;         // array of flags that describe the status of the page frame
    unsigned int property;  // the num of free block, used in first fit pm manager空闲块数目，BS中是这个块的大小（存的是幂次，2的这个property是块大小）
    list_entry_t page_link; // free list link
};

/* Flags describing the status of a page frame */
#define PG_reserved 0 // ***if this bit=1: the Page is reserved for kernel, cannot be used in alloc/free_pages; otherwise, this bit=0
#define PG_property 1 // ***if this bit=1: the Page is the head page of a free memory block
//(contains some continuous_addrress pages), and can be used in alloc_pages;
// if this bit=0: if the Page is the the head page of a free memory block,
// then this Page and the memory block is alloced. Or this Page isn't the head page.

// ***综上————flags是00表示这个页不被占用且（是空闲块头页 或 ），
// 01表示这个页不被内核占用的，且空闲
// 10表示这个页是是被占用块的头页

// 第二位为0表示个页是空闲的，且不是空闲块的头页 或 是被占用块的头页
// 第二位为1表示这个页是空闲块的头页

#define SetPageReserved(page) set_bit(PG_reserved, &((page)->flags))
#define ClearPageReserved(page) clear_bit(PG_reserved, &((page)->flags))
#define PageReserved(page) test_bit(PG_reserved, &((page)->flags))

#define SetPageProperty(page) set_bit(PG_property, &((page)->flags))
#define ClearPageProperty(page) clear_bit(PG_property, &((page)->flags))
#define PageProperty(page) test_bit(PG_property, &((page)->flags))

// convert list entry to page
#define le2page(le, member) \
    to_struct((le), struct Page, member) // 由Page中链表的结构找到Page结构体的地址

/* free_area_t - maintains a doubly linked list to record free (unused) pages */
typedef struct
{
    list_entry_t free_list; // the list header
    unsigned int nr_free;   // number of free pages in this free list
} free_area_t;

/* buddy system 的结构体 */
#define MAX_BUDDY_ORDER 14 // 0x7cb9 31929，不到2的15次方个页
typedef struct
{
    unsigned int max_order;                       // 实际最大块的大小
    list_entry_t free_array[MAX_BUDDY_ORDER + 1]; // 伙伴堆数组
    unsigned int nr_free;                         // 伙伴系统中剩余的空闲块
} free_buddy_t;

#endif /* !__ASSEMBLER__ */

#endif /* !__KERN_MM_MEMLAYOUT_H__ */
