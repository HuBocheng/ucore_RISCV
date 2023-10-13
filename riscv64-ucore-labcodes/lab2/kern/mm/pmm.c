#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <buddy_system_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <../sync/sync.h>
#include <riscv.h>

// virtual address of physical page array
struct Page *pages;
// amount of physical memory (in pages)
size_t npage = 0;
// the kernel image is mapped at VA=KERNBASE and PA=info.base
uint64_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
// DRAM_BASE defined in riscv.h as 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE;

// virtual address of boot-time page directory
uintptr_t *satp_virtual = NULL;
// physical address of boot-time page directory
uintptr_t satp_physical;

// physical memory management
const struct pmm_manager *pmm_manager;

static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void)
{
    // pmm_manager = &default_pmm_manager;
    pmm_manager = &best_fit_pmm_manager;
    // pmm_manager = &buddy_system_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n)
{
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n)
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
    }
    local_intr_restore(intr_flag);
    return page;
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
    }
    local_intr_restore(intr_flag);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void)
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
    }
    local_intr_restore(intr_flag);
    return ret;
}

static void page_init(void)
{
    va_pa_offset = PHYSICAL_MEMORY_OFFSET; // 设置虚拟到物理地址的偏移:

    // 获取物理内存信息，下面变量表示物理内存的开始、大小和结束地址
    uint64_t mem_begin = KERNEL_BEGIN_PADDR;
    uint64_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;
    uint64_t mem_end = PHYSICAL_MEMORY_END; // 硬编码取代 sbi_query_memory()接口

    // 打印物理内存映射信息
    cprintf("physcial memory map:\n");
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
            mem_end - 1);

    // 限制物理内存上限:
    uint64_t maxpa = mem_end;
    cprintf("maxpa: 0x%016lx.\n", maxpa); // test point

    // ctrl+左键点进去看一下KERNTOP具体实现（在memlayout.h中，KERNTOP是KERNBASE + KMEMSIZE）:
    if (maxpa > KERNTOP)
    {
        maxpa = KERNTOP;
    }

    // 初始化物理页面数组
    // end是链接脚本中定义的内核结束位置，其实是个常量指针
    extern char end[];

    // 求得总的物理页面数
    npage = maxpa / PGSIZE;
    cprintf("npage: 0x%016lx.\n", npage); // test point,为0x8800_0
    cprintf("nbase: 0x%016lx.\n", nbase); // test point，为0x8000_0

    // kernel在0x8020 0000开始加载，在end[]结束, pages是剩下的页的开始，是一个指向物理页面数组的指针
    // ROUNDUP是一个宏或函数，将给定的地址向上舍入到最接近的 PGSIZE 边界。保证最后的指针指向4kB对齐的地址
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
    cprintf("pages pythical address: 0x%016lx.\n", PADDR((uintptr_t)pages)); // test point
    // pages pythical address是0x8020 7000，有0x7000的位置被kernel映像占用

    // 将所有已经被内核使用的页面标记为已保留
    for (size_t i = 0; i < npage - nbase; i++)
    {
        SetPageReserved(pages + i);
    }

    // test ponit begin
    for (size_t i = 0; i < 5; i++)
    {
        cprintf("pages[%d] pythical address: 0x%016lx.\n", i, PADDR((uintptr_t)(pages + i))); // test point
    }
    // test point end

    // 初始化空闲页面列表
    // PADDR 宏将这个虚拟地址转换为物理地址
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 0x8034 7000 = 0x8020 7000 + 0x28 * 0x8000
    cprintf("page结构体大小: 0x%016lx.\n", sizeof(struct Page));                         // test point

    mem_begin = ROUNDUP(freemem, PGSIZE);
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
    cprintf("freemem: 0x%016lx.\n", freemem);     // test point
    cprintf("mem_begin: 0x%016lx.\n", mem_begin); // test point
    cprintf("mem_end: 0x%016lx.\n", mem_end);     // test point

    if (freemem < mem_end)
    {
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
    cprintf("mem_begin对应的页结构记录(结构体page)虚拟地址: 0x%016lx.\n", pa2page(mem_begin));        // test point
    cprintf("mem_begin对应的页结构记录(结构体page)物理地址: 0x%016lx.\n", PADDR(pa2page(mem_begin))); // test point

    cprintf("可用空闲页的数目: 0x%016lx.\n", (mem_end - mem_begin) / PGSIZE); // test point
    // 可用空闲页数目0x7cb9 ，0x7cb9>>12 + 0x80347000（membegin）=0x88000000（memend）
    // 从0x8800 0000到0x8000 0000总共0x8000个页，其中0x7cb9个页可用，也就是总共空闲页内存是0x7cb9000，也就是124MB
    // 0x8000-0x7cb9=0x0347个不可用，这些页存的是结构体page的数据
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void)
{
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // First we should init a physical memory manager(pmm) based on the framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();

    extern char boot_page_table_sv39[];
    satp_virtual = (pte_t *)boot_page_table_sv39;
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void)
{
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}
