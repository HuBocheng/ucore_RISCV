#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>
#include <stdio.h>

/* In the first fit algorithm, the allocator keeps a list of free blocks (known as the free list) and,
   on receiving a request for memory, scans along the list for the first block that is large enough to
   satisfy the request. If the chosen block is significantly larger than that requested, then it is
   usually split, and the remainder added to the list as another free block.
   Please see Page 196~198, Section 8.2 of Yan Wei Min's chinese book "Data Structure -- C programming language"
*/
// you should rewrite functions: default_init,default_init_memmap,default_alloc_pages, default_free_pages.
/*
 * Details of FFMA
 * (1) Prepare: In order to implement the First-Fit Mem Alloc (FFMA), we should manage the free mem block use some list.
 *              The struct free_area_t is used for the management of free mem blocks. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list implementation.
 *              You should know howto USE: list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *              Another tricky method is to transform a general list struct to a special struct (such as struct page):
 *              you can find some MACRO: le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.)
 * (2) default_init: you can reuse the  demo default_init fun to init the free_list and set nr_free to 0.
 *              free_list is used to record the free mem blocks. nr_free is the total number for free mem blocks.
 * (3) default_init_memmap:  CALL GRAPH: kern_init --> pmm_init-->page_init-->init_memmap--> pmm_manager->init_memmap
 *              This fun is used to init a free block (with parameter: addr_base, page_number).
 *              First you should init each page (in memlayout.h) in this free block, include:
 *                  p->flags should be set bit PG_property (means this page is valid. In pmm_init fun (in pmm.c),
 *                  the bit PG_reserved is setted in p->flags)
 *                  if this page  is free and is not the first page of free block, p->property should be set to 0.
 *                  if this page  is free and is the first page of free block, p->property should be set to total num of block.
 *                  p->ref should be 0, because now p is free and no reference.
 *                  We can use p->page_link to link this page to free_list, (such as: list_add_before(&free_list, &(p->page_link)); )
 *              Finally, we should sum the number of free mem block: nr_free+=n
 * (4) default_alloc_pages: search find a first free block (block size >=n) in free list and reszie the free block, return the addr
 *              of malloced block.
 *              (4.1) So you should search freelist like this:
 *                       list_entry_t le = &free_list;
 *                       while((le=list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) In while loop, get the struct page and check the p->property (record the num of free block) >=n?
 *                       struct Page *p = le2page(le, page_link);
 *                       if(p->property >= n){ ...
 *                 (4.1.2) If we find this p, then it' means we find a free block(block size >=n), and the first n pages can be malloced.
 *                     Some flag bits of this page should be setted: PG_reserved =1, PG_property =0
 *                     unlink the pages from free_list
 *                     (4.1.2.1) If (p->property >n), we should re-caluclate number of the the rest of this free block,
 *                           (such as: le2page(le,page_link))->property = p->property - n;)
 *                 (4.1.3)  re-caluclate nr_free (number of the the rest of all free block)
 *                 (4.1.4)  return p
 *               (4.2) If we can not find a free block (block size >=n), then return NULL
 * (5) default_free_pages: relink the pages into  free list, maybe merge small free blocks into big free blocks.
 *               (5.1) according the base addr of withdrawed blocks, search free list, find the correct position
 *                     (from low to high addr), and insert the pages. (may use list_next, le2page, list_add_before)
 *               (5.2) reset the fields of pages, such as p->ref, p->flags (PageProperty)
 *               (5.3) try to merge low addr or high addr blocks. Notice: should change some pages's p->property correctly.
 */
free_area_t free_area; // 一个空闲区域的结构，其中包含一个空闲列表（list_entry_t类型，里面有俩指针）和一个空闲块计数器。

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
}

static void
default_init_memmap(struct Page *base, size_t n)
// 初始化一个给定地址和大小的空闲块。
// base: 指向第一个页面的指。n: 页数。
{
    assert(n > 0);
    // 遍历从 base 开始的每一个页面，
    // 确保每一页都被预留（PageReserved(p)）。然后清除每一页的标志和属性，并设置其引用计数为0
    struct Page *p = base;

    // test point begin
    for (; p != base + 3; p++)
    {
        cprintf("p的虚拟地址: 0x%016lx.\n", (uintptr_t)p);
    }
    // test point end

    p = base;//将 p 设置为指向这段物理页面的起始地址
    for (; p != base + n; p++)
    {//从基地址 base 开始，对 n 个连续的物理页面进行初始化
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0); // 设置引用计数(page的ref成员)为0
    }
    // 设置基本页面的属性
    // 空闲块中第一个页的property属性标志整个空闲块中总页数
    base->property = n;
    // 将这个页面标记为空闲块开始的页面
    // 将page->flag的PG_property位，也就是第1位（总共0-63有64位）设置为1
    SetPageProperty(base);
    // 更新空闲区域的结构中的空闲块的数量
    nr_free += n;

    // 将新的空闲块添加到空闲列表中
    // 空闲链表为空就直接添加
    if (list_empty(&free_list))
    {
        list_add(&free_list, &(base->page_link));
        // 这个函数将在para2节点插入在para1后面
    }
    else // 非空的话就遍历链表，找到合适的位置插入
    {
        list_entry_t *le = &free_list;             // 哨兵节点，表示链表的开始和结束。
        while ((le = list_next(le)) != &free_list) // 遍历一轮链表
        {
            struct Page *page = le2page(le, page_link); // le2page从给定的链表节点le获取到包含它的struct Page实例。
            if (base < page)                            // 找到了合适的位置，链表是排序的，便于后续搜索，插入要维持有序状态
            {
                list_add_before(le, &(base->page_link)); // 在当前链表条目之前插入新页面。
                break;
            }
            else if (list_next(le) == &free_list) // 到了链表尾部，循环一轮的最后，直接添加
            {
                list_add(le, &(base->page_link));
            }
        }
    }
}

static struct Page *
default_alloc_pages(size_t n) // 根据首次适应算法从空闲列表中分配所需数量的页
{
    assert(n > 0);
    // 不够分
    if (n > nr_free)
    {
        return NULL;
    }
    // 遍历空闲列表，找到第一个空闲块大小大于等于n的块
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
    {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n)
        {
            page = p;
            break;
        }
    }
    if (page != NULL) // 找到了要分配的页，获取这个块前面的链表条目，并从空闲列表中删除这个块。
    {
        list_entry_t *prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) // 找到的空闲块比请求的大，它将被拆分为两部分
        {
            struct Page *p = page + n;        // p指向第二部分的第一个页面
            p->property = page->property - n; // 更新第二部分的空闲块大小
            SetPageProperty(p);               // 设置第二部分的第一个页面的属性
            list_add(prev, &(p->page_link));  // 将第二部分添加到空闲列表中
        }
        // 更新空闲页面计数 nr_free，并清除已分配块的属性标志。
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}

// 释放一段连续的物理页面，base 是要释放的页面的起始地址，n 是要释放的页面数量
static void
default_free_pages(struct Page *base, size_t n)
{
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++)
    {
        assert(!PageReserved(p) && !PageProperty(p));//确保页面不是保留的，也不是空闲块的第一个页面
        p->flags = 0;//清除页面的标志
        set_page_ref(p, 0);//设置页面的引用计数为0
    }
    base->property = n;//将要释放的页面中的第一个页面的property属性设置为n，表示需要释放n个页面
    SetPageProperty(base);//将页面的标志设置为 PG_property，表示这是一个空闲块的第一个页面。
    nr_free += n;//将要释放的页面数量 n 加到空闲页面计数 nr_free 中，表示这些页面现在是空闲的

    /**
     * 用 list_empty 宏检查空闲页面链表是否为空
     * 如果为空，则将要添加的页面作为链表的头节点，并返回
     * 否则，函数遍历空闲页面链表，找到要添加的页面在链表中的位置，并将其插入到链表中
    */
    if (list_empty(&free_list))
    {
        list_add(&free_list, &(base->page_link));
    }
    else
    {
        list_entry_t *le = &free_list;
        while ((le = list_next(le)) != &free_list)//遍历一轮链表
        {
            struct Page *page = le2page(le, page_link);//使用 le2page 宏将链表节点转换为页面结构体
            //比较要添加的页面的地址和当前节点所对应的页面的地址的大小
            //保证链表中页面地址的升序排列
            if (base < page)
            {
                list_add_before(le, &(base->page_link));
                break;
            }
            else if (list_next(le) == &free_list)
            {
                list_add(le, &(base->page_link));//加在链表末尾
            }
        }
    }

    //合并空闲页面链表中相邻的空闲块
    //判断空闲块之前的块
    list_entry_t *le = list_prev(&(base->page_link));//取空闲块的前一个页面的链表节点
    if (le != &free_list)//如果 le 不等于空闲页面链表的头节点，则说明空闲块的前一个页面存在
    {
        /***
         * 函数使用 le2page 宏将链表节点转换为页面结构体，并将其赋值给指针 p
         * 如果 p 的 property 字段加上 p 的地址等于 base 的地址，则说明 p 和 base 是相邻的空闲块，可以将它们合并成一个更大的空闲块
         * 然后使用 ClearPageProperty 宏将 base 的 PG_property 标志位清除
         * 使用 list_del 宏将 base 从空闲页面链表中删除。
         * 函数将 base 的地址更新为 p 的地址，表示合并后的空闲块的起始页面为 p。
        */
        p = le2page(le, page_link);
        if (p + p->property == base)
        {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }
    
    //判断空闲块之后的块
    le = list_next(&(base->page_link));
    if (le != &free_list)
    {
        p = le2page(le, page_link);
        if (base + base->property == p)
        {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}

static void
basic_check(void)
{
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
    assert((p1 = alloc_pages(3)) != NULL);
    assert(alloc_page() == NULL);
    assert(p0 + 2 == p1);

    p2 = p0 + 1;
    free_page(p0);
    free_pages(p1, 3);
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);

    assert((p0 = alloc_page()) == p2 - 1);
    free_page(p0);
    assert((p0 = alloc_pages(2)) == p2 + 1);

    free_pages(p0, 2);
    free_page(p2);

    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
}
// 这个结构体在
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};