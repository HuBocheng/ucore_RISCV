<h1><center>lab1实验报告</center></h1>
<h5><center>组员：杜鑫 胡博程 刘心源</center></h5>

#一、基本练习

###  练习1:理解内核启动中的程序入口操作
```assembly
    la sp, bootstacktop
```
- 操作：本条指令将`bootstacktop`的地址加载到堆栈指针`sp`中，即将`bootstacktop`作为堆栈的起始地址。
- 目的：在操作系统的内核启动过程中，需要初始化堆栈指针来设置一个区域存储局部变量和函数调用时的返回地址，因此需要将`bootstacktop`作为堆栈的起始地址。这样设置也可以确保内核有一个定义好的、不会与其他数据冲突的堆栈空间。

```assembly
    tail kern_init
```
- 操作：尾调用函数`kern_init`，直接跳转到`kern_init`函数的入口地址。
- 目的：`kern_init`是内核初始化的主函数，尾调用后开始内核的初始化。同时使用尾调用直接跳转到目标函数，意味着当前函数的栈帧将被新调用的函数重用，可以避免在函数返回时需要额外的栈空间，防止栈溢出～

### 练习2:完善中断处理
根据题目要求补充代码如下：
```c
    /* LAB1 EXERCISE2   2112614 :  */
    /*(1)设置下次时钟中断- clock_set_next_event()
        *(2)计数器（ticks）加一
        *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
    * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
    */
    clock_set_next_event();
    ticks++;
    if(ticks==100){
        ticks=0;
        print_ticks();
        if(num==10){
            sbi_shutdown();
        }
        num++;
    }
```
**实现过程**：
- 设置下一次时钟中断：调用`clock_set_next_event()`函数，设置下一次时钟中断的时间；
- 更新时间中断计数器`ticks`：每次时钟中断发生时，更新计数器`ticks`的值，`ticks++`；
- 100次时钟中断后打印消息：当计数器`ticks`加到100时，表示发生了100次时钟中断，此时调用函数`print_ticks()`打印消息`100ticks`，并将计数器`ticks`清零；
- 检查是否需要关机：使用变量`num`记录打印消息的次数，当计数器`ticks`累加到100时，`num++`。当`num`为10时，表示已经打印了10次消息，此时调用函数`sbi_shutdown()`关机。

**运行结果**：
```bash
    Special kernel symbols:
    entry  0x000000008020000a (virtual)
    etext  0x00000000802009a0 (virtual)
    edata  0x0000000080204010 (virtual)
    end    0x0000000080204028 (virtual)
    Kernel executable memory footprint: 17KB
    ++ setup timer interrupts
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
    100 ticks
```
约为1秒钟打印一次`100 ticks`，共打印了10次，之后关机。

**定时器中断处理流程**：
