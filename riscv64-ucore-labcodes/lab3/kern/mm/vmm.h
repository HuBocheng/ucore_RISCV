#ifndef __KERN_MM_VMM_H__
#define __KERN_MM_VMM_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <sync.h>

// pre define
struct mm_struct;

// the virtual continuous memory area(vma), [vm_start, vm_end),
// addr belong to a vma means  vma.vm_start<= addr <vma.vm_end
// vma——virtual memory area，是一段连续的虚拟内存区域，[vm_start, vm_end)
struct vma_struct
{
    struct mm_struct *vm_mm; // the set of vma using the same PDT
    uintptr_t vm_start;      // start addr of vma
    uintptr_t vm_end;        // end addr of vma, not include the vm_end itself
    uint_t vm_flags;         // flags of vma
    list_entry_t list_link;  // linear list link which sorted by start addr of vma
};

// 根据vma结构体中的list_link的地址得到整个结构体vma的头地址
#define le2vma(le, member) \
    to_struct((le), struct vma_struct, member)

#define VM_READ 0x00000001
#define VM_WRITE 0x00000002
#define VM_EXEC 0x00000004

// the control struct for a set of vma using the same PDT
// mm_struct——memory management struct，是一组使用相同页目录表(PDT)的虚拟内存区域
// 里面有很多连续的内存区域小块，每个小块都是一个vma_struct，这些小块都含有list_entry_t结构
// 可以通过le2vm的宏由list_entry_t结构找到整个结构体vma_struct
struct mm_struct
{
    list_entry_t mmap_list;        // linear list link which sorted by start addr of vma
    struct vma_struct *mmap_cache; // current accessed vma, used for speed purpose
    pde_t *pgdir;                  // the PDT of these vma
    int map_count;                 // the count of these vma
    void *sm_priv;                 // the private data for swap manager
};
// mmap_list链表连接了使用相同页目录项的vma（对应的是vma中的list_link变量），使用le2vm宏由链表找到完整结构体
// ***这是一个设计的trick，page和vma_struct都有一个list_entry_t的变量，这样就可以通过le2page和le2vm宏找到完整的结构体
// mmap_cache是一个指针，指向当前正在访问的vma，这样可以加快访问速度
// pgdir是页目录表的地址
// map_count是vma的数量
// sm_priv是swap manager的私有数据,void *类型，意味着它是一个指向任意数据的通用指针

struct vma_struct *find_vma(struct mm_struct *mm, uintptr_t addr);
struct vma_struct *vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags);
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma);

struct mm_struct *mm_create(void);
void mm_destroy(struct mm_struct *mm);

void vmm_init(void);

int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr);

extern volatile unsigned int pgfault_num;
extern struct mm_struct *check_mm_struct;

#endif /* !__KERN_MM_VMM_H__ */
