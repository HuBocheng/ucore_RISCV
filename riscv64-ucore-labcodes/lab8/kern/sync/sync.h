#ifndef __KERN_SYNC_SYNC_H__
#define __KERN_SYNC_SYNC_H__

#include <defs.h>
#include <intr.h>
#include <sched.h>
#include <riscv.h>
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}
/*
do { ... } while (0)在宏定义中的作用主要是为了创建一个局部作用域，同时确保宏只执行一次。
这种结构能够确保宏的展开不会与周围的代码产生意外的交互，特别是在条件或循环语句中。
同时，它也能够让宏内的多条语句在展开时保持为一个单独的块，这样可以避免因宏展开导致的语法错误或未定义的行为。
*/
#define local_intr_save(x)      do { x = __intr_save(); } while (0)
#define local_intr_restore(x)   __intr_restore(x);

#endif /* !__KERN_SYNC_SYNC_H__ */

