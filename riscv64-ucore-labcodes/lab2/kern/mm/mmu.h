#ifndef __KERN_MM_MMU_H__
#define __KERN_MM_MMU_H__

#ifndef __ASSEMBLER__
#include <defs.h>
#endif


#define PGSIZE          4096                    // bytes mapped by a page
#define PGSHIFT         12                      // log2(PGSIZE)
//在 RISC-V 架构中，物理地址的最低 12 位表示页面内偏移量，其余位表示物理页面号。
// physical/virtual page number of address
//也就是右移12位，获取物理地址对应的物理页面编号
#define PPN(la) (((uintptr_t)(la)) >> PGSHIFT)

// Sv39 linear address structure
// +-------9--------+-------9--------+--------9---------+----------12----------+
// |      VPN2      |      VPN1      |       VPN0       |  Offset within Page  |
// +----------------+----------------+------------------+----------------------+

// Sv39 in RISC-V64 uses 39-bit virtual address to access 56-bit physical address!
// Sv39 page table entry:（PTE）
// +-------10--------+--------26-------+--------9----------+--------9--------+---2----+-------8-------+
// |    Reserved     |      PPN[2]     |      PPN[1]       |      PPN[0]     |Reserved|D|A|G|U|X|W|R|V|
// +-----------------+-----------------+-------------------+-----------------+--------+---------------+

/* page directory and page table constants */
#define SV39_NENTRY          512                     // 每个页目录中包含的页表项数目

#define SV39_PGSIZE          4096                    // 一个页面的大小——映射的字节数
#define SV39_PGSHIFT         12                      // 12位，log2(PGSIZE)
#define SV39_PTSIZE          (PGSIZE * SV39NENTRY)   // 一个页目录项所映射的内存大小 
#define SV39_PTSHIFT         21                      // 21位，log2(PTSIZE)

//SV39_VPN0SHIFT、SV39_VPN1SHIFT 和 SV39_VPN2SHIFT 分别表示线性地址中 VPN0、VPN1 和 VPN2 开始的偏移量
//SV39_PTE_PPN_SHIFT 表示页表项中 PPN 字段的偏移量
#define SV39_VPN0SHIFT       12                      // offset of VPN0 in a linear address
#define SV39_VPN1SHIFT       21                      // offset of VPN1 in a linear address
#define SV39_VPN2SHIFT       30                      // offset of VPN2 in a linear address
#define SV39_PTE_PPN_SHIFT   10                      // offset of PPN in a physical address

/*
SV39_VPN0 和 SV39_VPN1，用于获取线性地址 la 中 VPN0 和 VPN1 的值
将线性地址 la 右移相应的偏移量，然后通过位掩码 0x1FF 获取对应的 VPN 值
0x1FF 的二进制表示为 0000000111111111，它的低 9 位都是 1，其余位都是 0
因此，将一个数与 0x1FF 进行按位与运算，就可以得到这个数的低 9 位。
*/
#define SV39_VPN0(la) ((((uintptr_t)(la)) >> SV39_VPN0SHIFT) & 0x1FF)
#define SV39_VPN1(la) ((((uintptr_t)(la)) >> SV39_VPN1SHIFT) & 0x1FF)
#define SV39_VPN2(la) ((((uintptr_t)(la)) >> SV39_VPN2SHIFT) & 0x1FF)
#define SV39_VPN(la, n) ((((uintptr_t)(la)) >> 12 >> (9 * n)) & 0x1FF)//这个可以求任意级别的VPN

// construct linear address from indexes and offset
/*
SV39_PGADDR 用于将 VPN0、VPN1 和 VPN2 以及偏移量 o 合并为一个线性地址
*/
#define SV39_PGADDR(v2, v1, v0, o) ((uintptr_t)((v2) << SV39_VPN2SHIFT | (v1) << SV39_VPN1SHIFT | (v0) << SV39_VPN0SHIFT | (o)))

// address in page table or page directory entry
// SV39_PTE_ADDR 用于从页表项中获取物理页面的地址
// 将PTE中的低9位清零，页表条目（PTE）的低9位用于存储元数据，如访问和权限位
// 左移3位，因为在SV39模式下，物理地址是按8字节对齐的，所以需要向左移动3位以恢复原始的物理地址。
// 将地址从页表条目格式转换为标准的物理地址格式
#define SV39_PTE_ADDR(pte)   (((uintptr_t)(pte) & ~0x1FF) << 3)

// 3-level pagetable
#define SV39_PT0                 0
#define SV39_PT1                 1
#define SV39_PT2                 2

// page table entry (PTE) fields
#define PTE_V     0x001 // Valid有效标志位，用于表示该页表项是否有效
#define PTE_R     0x002 // Read可读标志位，用于表示该页面是否可读
#define PTE_W     0x004 // Write可写标志位，用于表示该页面是否可写
#define PTE_X     0x008 // Execute可执行标志位，用于表示该页面是否可执行
#define PTE_U     0x010 // User用户/内核标志位，用于表示该页面是否属于用户空间或内核空间
#define PTE_G     0x020 // Global全局标志位，用于表示该页面是否是全局页面
#define PTE_A     0x040 // Accessed访问标志位，用于表示该页面是否被访问过
#define PTE_D     0x080 // Dirty脏页标志位，用于表示该页面是否被修改过
#define PTE_SOFT  0x300 // Reserved for Software保留位，用于软件使用

#define PAGE_TABLE_DIR (PTE_V) // 页表项标志位，用于表示该页表项是否为页表条目
#define READ_ONLY (PTE_R | PTE_V) // 只读标志位，用于表示该页面是否只读
#define READ_WRITE (PTE_R | PTE_W | PTE_V) // 可读可写标志位，用于表示该页面是否可读可写
#define EXEC_ONLY (PTE_X | PTE_V) // 只执行标志位，用于表示该页面是否只执行
#define READ_EXEC (PTE_R | PTE_X | PTE_V) // 可读可执行标志位，用于表示该页面是否可读可执行
#define READ_WRITE_EXEC (PTE_R | PTE_W | PTE_X | PTE_V) // 可读可写可执行标志位，用于表示该页面是否可读可写可执行

#define PTE_USER (PTE_R | PTE_W | PTE_X | PTE_U | PTE_V) // 用户标志位，用于表示该页面是否属于用户空间

#endif /* !__KERN_MM_MMU_H__ */

