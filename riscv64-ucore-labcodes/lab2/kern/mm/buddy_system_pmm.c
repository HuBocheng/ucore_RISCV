#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <buddy_system_pmm.h>

free_buddy_t buddy_s;
#define buddy_array (buddy_s.free_array)
#define max_order (buddy_s.max_order)
#define nr_free (buddy_s.nr_free)
#define mem_begin 0xffffffffc020f318

static int IS_POWER_OF_2(size_t n)
{
    if (n & (n - 1))
    {
        return 0;
    }
    else
    {
        return 1;
    }
}

static unsigned int getOrderOf2(size_t n)
{
    unsigned int order = 0;
    while (n >> 1)
    {
        n >>= 1;
        order++;
    }
    return order;
}

static size_t ROUNDDOWN2(size_t n)
{
    size_t res = 1;
    if (!IS_POWER_OF_2(n))
    {
        while (n)
        {
            n = n >> 1;
            res = res << 1;
        }
        return res >> 1;
    }
    else
    {
        return n;
    }
}

static size_t ROUNDUP2(size_t n)
{
    size_t res = 1;
    if (!IS_POWER_OF_2(n))
    {
        while (n)
        {
            n = n >> 1;
            res = res << 1;
        }
        return res;
    }
    else
    {
        return n;
    }
}

static void buddy_split(size_t n)
{
    assert(n > 0 && n <= max_order);
    assert(!list_empty(&(buddy_array[n])));
    struct Page *page_a;
    struct Page *page_b;

    page_a = le2page(list_next(&(buddy_array[n])), page_link);
    page_b = page_a + (1 << (n - 1)); // 找到a的伙伴块b
    page_a->property = n - 1;
    page_b->property = n - 1;

    list_del(list_next(&(buddy_array[n])));
    list_add(&(buddy_array[n - 1]), &(page_a->page_link));
    list_add(&(page_a->page_link), &(page_b->page_link));

    return;
}

static void
show_buddy_array(int left, int right) // 左闭右闭
{
    bool empty = 1; // 表示空闲链表数组为空
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
    cprintf("==================显示空闲链表数组==================\n");
    for (int i = left; i <= right; i++)
    {
        list_entry_t *le = &buddy_array[i];
        if (list_next(le) != &buddy_array[i])
        {
            empty = 0;

            while ((le = list_next(le)) != &buddy_array[i])
            {
                cprintf("No.%d的空闲链表有", i);
                struct Page *p = le2page(le, page_link);
                cprintf("%d页 ", 1 << (p->property));
                cprintf("【地址为%p】\n", p);
            }
            if (i != right)
            {
                cprintf("\n");
            }
        }
    }
    if (empty)
    {
        cprintf("无空闲块！！！\n");
    }
    cprintf("======================显示完成======================\n\n\n");
    return;
}

static void
buddy_system_init(void)
{
    // 初始化伙伴堆链表数组中的每个free_list头
    for (int i = 0; i < MAX_BUDDY_ORDER + 1; i++)
    {
        list_init(buddy_array + i);
    }
    max_order = 0;
    nr_free = 0;
    return;
}

// 空闲链表初始化的部分
static void
buddy_system_init_memmap(struct Page *base, size_t n) // base是第一个页的地址，n是页的数量
{
    assert(n > 0);
    size_t pnum;
    unsigned int order;
    pnum = ROUNDDOWN2(n);      // 将页数向下取整为2的幂，不到2的15幂，向下取，变成14
    order = getOrderOf2(pnum); // 求出页数对应的2的幂
    struct Page *p = base;
    // 初始化pages数组中范围内的每个Page
    for (; p != base + pnum; p++)
    {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = -1; // 全部初始化为非头页
        set_page_ref(p, 0);
    }
    max_order = order;
    nr_free = pnum;
    list_add(&(buddy_array[max_order]), &(base->page_link)); // 将第一页base插入数组的最后一个链表，作为初始化的最大块的头页
    // cprintf("base->page_link:%p\n", &(base->page_link));
    base->property = max_order; // 将第一页base的property设为最大块的2幂

    return;
}

static struct Page *
buddy_system_alloc_pages(size_t requested_pages)
{
    assert(requested_pages > 0);

    if (requested_pages > nr_free)
    {
        return NULL;
    }

    struct Page *allocated_page = NULL;
    size_t adjusted_pages = ROUNDUP2(requested_pages); // 如：求7个页，给8个页
    size_t order_of_2 = getOrderOf2(adjusted_pages);   // 求出所需页数对应的2的幂,为数组下标

    // 先找有没有合适的空闲块，没有的话得分割大块
    bool found = 0;
    while (!found)
    {
        if (!list_empty(&(buddy_array[order_of_2])))
        {
            allocated_page = le2page(list_next(&(buddy_array[order_of_2])), page_link);
            list_del(list_next(&(buddy_array[order_of_2]))); // 删除空闲链表中找到的空闲块
            SetPageProperty(allocated_page);                 // 头页设置flags的第二位为1
            found = 1;
        }
        else
        {
            int i;
            for (i = order_of_2 + 1; i <= max_order; ++i)
            {
                if (!list_empty(&(buddy_array[i])))
                {
                    // cprintf("空闲链表数组NO.%d将被分裂\n", i);
                    buddy_split(i);
                    break;
                }
            }
            // 找了一圈啥也没找见，只能分配失败了
            if (i > max_order)
            {
                break;
            }
        }
    }

    if (allocated_page != NULL)
    {
        nr_free -= adjusted_pages;
    }
    // show_buddy_array(0, MAX_BUDDY_ORDER); // test point
    return allocated_page;
}

struct Page *get_buddy(struct Page *block_addr, unsigned int block_size)
{
    size_t real_block_size = 1 << block_size;                    // 幂次转换成数
    size_t relative_block_addr = (size_t)block_addr - mem_begin; // 计算相对于初始化的第一个页的偏移量

    size_t sizeOfPage = real_block_size * sizeof(struct Page);                  // sizeof(struct Page)是0x28
    size_t buddy_relative_addr = (size_t)relative_block_addr ^ sizeOfPage;      // 异或得到伙伴块的相对地址
    struct Page *buddy_page = (struct Page *)(buddy_relative_addr + mem_begin); // 返回伙伴块指针
    return buddy_page;
}

static void
buddy_system_free_pages(struct Page *base, size_t n)
{
    assert(n > 0);
    unsigned int pnum = 1 << (base->property); // 块中页的数目
    assert(ROUNDUP2(n) == pnum);
    cprintf("BS算法将释放第NO.%d页开始的共%d页\n", page2ppn(base), pnum);
    struct Page *left_block = base; // 放块的头页
    struct Page *buddy = NULL;
    struct Page *tmp = NULL;

    list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 将当前块先插入对应链表中

    // show_buddy_array(0, MAX_BUDDY_ORDER); // test point
    // 当伙伴块空闲，且当前块不为最大块时，执行合并
    buddy = get_buddy(left_block, left_block->property);
    while (!PageProperty(buddy) && left_block->property < max_order)
    {
        if (left_block > buddy)
        {                                  // 若当前左块为更大块的右块
            left_block->property = -1;     // 将左块幂次置为无效
            ClearPageProperty(left_block); // 设置其空闲
            // 交换左右使得位置正确
            tmp = left_block;
            left_block = buddy;
            buddy = tmp;
        }
        // 删掉原来链表里的两个小块
        list_del(&(left_block->page_link));
        list_del(&(buddy->page_link));
        left_block->property += 1; // 左快头页设置幂次加一
        // cprintf("left_block->property=%d\n", left_block->property); //test point
        list_add(&(buddy_array[left_block->property]), &(left_block->page_link)); // 头插入相应链表
        // show_buddy_array(0, MAX_BUDDY_ORDER); // test point

        // 重置buddy开启下一轮循环***
        buddy = get_buddy(left_block, left_block->property);
    }
    ClearPageProperty(left_block); // 将回收块的头页设置为空闲
    nr_free += pnum;
    // show_buddy_array(); // test point

    return;
}

static size_t
buddy_system_nr_free_pages(void)
{
    return nr_free;
}

static void
basic_check(void)
{
    cprintf("总空闲块数目为：%d\n", nr_free);
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;

    cprintf("首先p0请求5页\n");
    p0 = alloc_pages(5);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    cprintf("然后p1请求5页\n");
    p1 = alloc_pages(5);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    cprintf("最后p2请求5页\n");
    p2 = alloc_pages(5);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    // cprintf("p0的物理地址0x%016lx.\n", PADDR(p0)); // 0x8020f318
    cprintf("p0的虚拟地址0x%016lx.\n", p0);
    // cprintf("p1的物理地址0x%016lx.\n", PADDR(p1)); // 0x8020f458,和p0相差0x140=0x28*5
    cprintf("p1的虚拟地址0x%016lx.\n", p1);
    // cprintf("p2的物理地址0x%016lx.\n", PADDR(p2)); // 0x8020f598,和p1相差0x140=0x28*5
    cprintf("p2的虚拟地址0x%016lx.\n", p2);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    // 假设空闲块数是0，看看能不能再分配
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    // 清空看nr_free能不能变
    cprintf("释放p0中。。。。。。");
    free_pages(p0, 5);
    cprintf("释放p0后，总空闲块数目为：%d\n", nr_free); // 变成了8
    show_buddy_array(0, MAX_BUDDY_ORDER);

    cprintf("释放p1中。。。。。。");
    free_pages(p1, 5);
    cprintf("释放p1后，总空闲块数目为：%d\n", nr_free); // 变成了16
    show_buddy_array(0, MAX_BUDDY_ORDER);

    cprintf("释放p2中。。。。。。");
    free_pages(p2, 5);
    cprintf("释放p2后，总空闲块数目为：%d\n", nr_free); // 变成了24
    show_buddy_array(0, MAX_BUDDY_ORDER);

    // 分配块全部收回，重置nr_free为最大值
    nr_free = 16384;

    struct Page *p3 = alloc_pages(16384);
    cprintf("分配p3之后(16384页)\n");
    show_buddy_array(0, MAX_BUDDY_ORDER);

    // 全部回收
    free_pages(p3, 16384);
    show_buddy_array(0, MAX_BUDDY_ORDER);
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
buddy_system_check(void)
{
    // int count = 0, total = 0;
    // list_entry_t *le = &free_list;
    // while ((le = list_next(le)) != &free_list)
    // {
    //     struct Page *p = le2page(le, page_link);
    //     assert(PageProperty(p));
    //     count++, total += p->property;
    // }
    // assert(total == nr_free_pages());

    basic_check();

    // struct Page *p0 = alloc_pages(5), *p1, *p2;
    // assert(p0 != NULL);
    // assert(!PageProperty(p0));

    // list_entry_t free_list_store = free_list;
    // list_init(&free_list);
    // assert(list_empty(&free_list));
    // assert(alloc_page() == NULL);

    // unsigned int nr_free_store = nr_free;
    // nr_free = 0;

    // free_pages(p0 + 2, 3);
    // assert(alloc_pages(4) == NULL);
    // assert(PageProperty(p0 + 2) && p0[2].property == 3);
    // assert((p1 = alloc_pages(3)) != NULL);
    // assert(alloc_page() == NULL);
    // assert(p0 + 2 == p1);

    // p2 = p0 + 1;
    // free_page(p0);
    // free_pages(p1, 3);
    // assert(PageProperty(p0) && p0->property == 1);
    // assert(PageProperty(p1) && p1->property == 3);

    // assert((p0 = alloc_page()) == p2 - 1);
    // free_page(p0);
    // assert((p0 = alloc_pages(2)) == p2 + 1);

    // free_pages(p0, 2);
    // free_page(p2);

    // assert((p0 = alloc_pages(5)) != NULL);
    // assert(alloc_page() == NULL);

    // assert(nr_free == 0);
    // nr_free = nr_free_store;

    // free_list = free_list_store;
    // free_pages(p0, 5);

    // le = &free_list;
    // while ((le = list_next(le)) != &free_list)
    // {
    //     struct Page *p = le2page(le, page_link);
    //     count--, total -= p->property;
    // }
    // assert(count == 0);
    // assert(total == 0);
}

// 这个结构体在
const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = buddy_system_check,
};
