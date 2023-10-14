#ifndef __KERN_MM_PMM_H__
#define __KERN_MM_PMM_H__

#include <assert.h>
#include <atomic.h>
#include <defs.h>
#include <memlayout.h>
#include <mmu.h>
#include <riscv.h>

// pmm_manager is a physical memory management class. A special pmm manager -
// XXX_pmm_manager
// only needs to implement the methods in pmm_manager class, then
// XXX_pmm_manager can be used
// by ucore to manage the total physical memory space.
struct pmm_manager {
    const char *name;  // XXX_pmm_manager's name
    void (*init)(
        void);  // 初始化XXX_pmm_manager内部的数据结构（如空闲页面的链表）
    void (*init_memmap)(
        struct Page *base,
        size_t n);  //知道了可用的物理页面数目之后，进行更详细的初始化
    struct Page *(*alloc_pages)(
        size_t n);  // 分配至少n个物理页面, 根据分配算法可能返回不同的结果
    void (*free_pages)(struct Page *base, size_t n);  // free >=n pages with
                                                      // "base" addr of Page
                                                      // descriptor
                                                      // structures(memlayout.h)
    size_t (*nr_free_pages)(void);  // 返回空闲物理页面的数目
    void (*check)(void);            // 测试正确性
};

extern const struct pmm_manager *pmm_manager;

void pmm_init(void);

struct Page *alloc_pages(size_t n);
void free_pages(struct Page *base, size_t n);
size_t nr_free_pages(void); // 返回空闲物理页面的数目

#define alloc_page() alloc_pages(1) //分配一个物理页面
#define free_page(page) free_pages(page, 1) //释放一个物理页面，它调用 free_pages 函数，并将 n 设置为 1。

// first_ppn表示第一个可分配物理内存页的下标
#define first_ppn 0
/* *
 * PADDR - takes a kernel virtual address (an address that points above
 * KERNBASE), where the machine's maximum 256MB of physical memory is mapped and returns
 * the corresponding physical address.  It panics if you pass it a non-kernel
 * virtual address.
 * 用于将一个内核虚拟地址转换为对应的物理地址，它会检查传入的地址是否为内核虚拟地址，如果不是则会触发 panic 异常。
 * */
#define PADDR(kva)                                                 \
    ({                                                             \
        uintptr_t __m_kva = (uintptr_t)(kva);                      \
        if (__m_kva < KERNBASE)                                    \
        {                                                          \
            panic("PADDR called with invalid kva %08lx", __m_kva); \
        }                                                          \
        __m_kva - va_pa_offset;                                    \
    })

/* *
 * KADDR - takes a physical address and returns the corresponding kernel virtual
 * address. It panics if you pass an invalid physical address.
 * */
/*
#define KADDR(pa)                                                \
    ({                                                           \
        uintptr_t __m_pa = (pa);                                 \
        size_t __m_ppn = PPN(__m_pa);                            \
        if (__m_ppn >= npage) {                                  \
            panic("KADDR called with invalid pa %08lx", __m_pa); \
        }                                                        \
        (void *)(__m_pa + va_pa_offset);                         \
    })
*/

extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

/*page-pages是page的偏移量，加上nbase就是ppn（物理页编号）
这段代码定义了一个静态内联函数 page2ppn，它的作用是将 Page 结构体指针转换为对应的物理页面号。
通过计算 Page 结构体指针和 pages 数组之间的偏移量，加上 nbase 变量的值，得到物理页面号。
*/
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; } 

/*
将 Page 结构体指针转换为对应的物理地址。
具体来说，它通过调用 page2ppn 函数获取物理页面号，然后将物理页面号左移 PGSHIFT（12） 位，得到物理地址
这个12就是offset，因为一个页面大小是2^12=4096
*/
static inline uintptr_t page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
}

//获取 Page 结构体中的 ref 成员，即页面的引用计数。
static inline int page_ref(struct Page *page) { return page->ref; }

//设置 Page 结构体中的 ref 成员，即页面的引用计数
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }

static inline int page_ref_inc(struct Page *page)
{
    //将 Page 结构体中的 ref 成员加 1，并返回新的引用计数
    page->ref += 1;
    return page->ref;
}

static inline int page_ref_dec(struct Page *page)
{
    //将 Page 结构体中的 ref 成员减 1，并返回新的引用计
    page->ref -= 1;
    return page->ref;
}

/*
它的作用是将物理地址转换为对应的 Page 结构体指针。
通过 PPN 宏获取物理页面号，然后判断物理页面号是否大于等于全局变量 npage
如果是，则表示物理地址无效，会触发 panic 异常
如果物理地址有效，则通过 pages 数组和物理页面号计算出对应的 Page 结构体指针，并返回该指针。
*/
static inline struct Page *pa2page(uintptr_t pa)
{
    if (PPN(pa) >= npage)
    {
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
}

//刷新 TLB 缓存。执行 sfence.vm 指令来刷新 TLB 缓存，以确保 TLB 缓存中的虚拟地址和物理地址映射关系与页表中的一致
static inline void flush_tlb() { asm volatile("sfence.vm"); }
extern char bootstack[], bootstacktop[]; // defined in entry.S

#endif /* !__KERN_MM_PMM_H__ */
