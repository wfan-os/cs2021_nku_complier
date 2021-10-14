	.arch	armv7-a
	.arm
	.file	"test.c"
	@ 以下是代码段
	.text

	@ i是全局变量，但没有初始化，所以我们放在.bss段
	.globl	i
	.bss

	@ 保持内存对齐
	.align	2
	
	@ i是我们int实例出来的一个对象，因此是object类型，又因为int是4字节，因此i的size为4
	.type	i, %object
	.size	i, 4

	@ 上面只是通知汇编器我们定义的i是个什么变量，我们还需要给i以内存空间
i:
	.space	4

	@ j是初始化的全局变量，我们放在.data段，同时，因为j的大小是4字节(一个字)，我们于是用.word给j赋值；其余的跟i一样
	.globl	j
	.data
	.align	2
	.type	j, %object
	.size	j, 4
j:
	.word	101

	@ 以下是代码段
	.text
	@ 声明下面的代码段是一个函数
	.align	1
	.globl	doNothing
	.type	doNothing, %function
doNothing:
	push	{lr,fp}	@ 这里我们压栈保存返回地址和栈基地址
	add	fp, sp, #0	@ 提升fp指向sp
	sub	sp, sp, #4	@ 扩栈，留下4字节大小的栈空间(因为只要这么多)

	mov		r4, #1			@ r4存放我们的局部变量k，因为r4是局部变量寄存器
	str		r4, [sp, #4]	@ 这里我们把变量k放到内存中存储，注意是r7(fp)+4的位置，

	nop				@ 注意，这里很有趣，我们源文件这里是"0;;"，但是毫无意义，因此被翻译为空指令

	add		sp, #4			@ 回收之前的栈空间
	pop		{fp}				@ 弹栈，将之前保存的值返还回去
	pop		{lr}

	bx	lr			@ lr寄存器记录着返回地址，现在我们返回去
	.size	doNothing, .-doNothing

	.align	1
	.globl	func
	.type	func, %function
func:
	push	{lr, fp}
	add	fp, sp, #0
	@ 注意这里我们不需要扩栈了，因为没有新建变量

	@ 注意，在arm汇编中是从左至右一次放入r0,r1,r2,r3中的，例如这里调用func(x,y)，r0存储x，r1存储y
	cmp		r0, r1
	beq		.LABLE_of_func
	mov		r0, #5						@ 返回值放在r0
	b		.LABLE_return_of_func		@ 这两句相当于return 5;
.LABLE_of_func:
	bl		doNothing(PLT)				@ 因为这是汇编代码，还没分配具体的内存，因此不知道函数所在的内存地址；同时，目前操作系统规定代码段不能修改，因此均采用PLT表作为跳转，
										@ 这样我们编写汇编代码时就不需要关心函数的具体位置或偏移，只需要标注一下让汇编器自动往对应的PLT项跳转即可

	mov		r0, #6
.LABLE_return_of_func:
	pop		{fp}
	pop		{lr}
	bx   lr								@ 这次我们没有使用栈，就不用恢复栈了，把保存的值恢复出来即可
	.size	func, .-func

	.align	1
	.globl	main
	.type	main, %function
main:
	push	{lr, fp}
	add	fp, sp, #0
	sub	sp, sp, #20   @ 准备20的空间，因为我们有a[2][2]共16字节+ const int b 共4字节

	@ 局部变量a[2][2]的空间位于sp+4到sp+16的位置，从低地址向高地址增长
	mov r0, #0
	str r0, [sp, #4]		@ a[0][0] = 0
	str r0, [sp, #12]		@ a[1][0] = 0
	str r0, [sp, #16]		@ a[1][1] = 0
	mov r0, #1
	str r0, [sp, #8]		@ a[0][1] = 1

	@ 局部变量 const int b 存储于栈顶，我们可以看到先声明的变量放在高地址，后声明的变量放在低地址
	@ gcc给出的汇编是直接复制公式结果了，我们这里为体现过程要去计算
	mov r0, #5
	mov r1, #2
	mul r3, r1, r0		@ 计算5*2
	add r0, r3, #-9		@ 计算-9+5*2
	str r0, [sp]		@ const int b = -9+5*2

	@ 我们进入了while循环
.LABLE_WHILE_LOOP:
	@ 这一步代码的意思是：我们设置r0为b是否小于等于5的flag，若小于等于5，则r0为1，否则为0
	mov r0, #1
	ldr r1, [sp]
	cmp r1, #5
	bls .LABLE_not_set_flag 
	mov r0, #0
.LABLE_not_set_flag:
	
	and r0, r0, #0		@ 等价于0&&b<=5
	mvn r0, r0
	and r0, r0, #1      @ 这两步等价于!(0&&b<=5)
	cmp r0, #1
	bne .LABLE_END_LOOP @ 这里注意一下，在源程序中我们可以直接算出表达式的结果是1，因此while条件总是执行的，但这里我们为了体现计算条件表达式这一过程，我们设计如上“冗余”的代码
	
	mov r1, #8
	mov r0, #7
	bl	func(PLT)
	mov r1, #2
	mov r2, #1
	mul r1, r2, r1		@ r1 = 2*1
	ldr r2, [sp]		@ r2 = b
	add r1, r1, r2      @ r1 = 2*1 + b, 这里我们的目的是获得a[1][b]的偏移量，因为a一行两个元素，故1*2，又因为在b列，故1*2+b
	lsl r1, r1, #2      @ r1 = 4*(2*1+b), r1左移两位即r1乘4，之所以要乘四是因为a中每个元素都是int，占4个字节

	add r1, #4			@ 因为a的地址在sp+4的位置，所以r1要加4
	str r0, [sp, r1]	@ a[1][b] = r0 = func(7,8)
	ldr r0, [sp, #4]	@ r0 = a[0][0]
	
	ldr r1, [sp]			@ r1 = b
	cmp r1, #0
	mrs r1, cpsr
	and r1, r1, #0x40000000	@ 这步操作是为了获取b==0的布尔值结果，去掉其它结果，cmp指令的比较结果会写到cpsr寄存器的zero flag上，若相等则为1，不等则为0
	lsr r1, #30				@ 因为zero flag在第31位，所以要逻辑右移30位，得到结果：r1 = (b == 0)

	orr r0, r0, r1			@ 计算 a[0][0] || (b == 0)
	cmp r0, #0
	bgt .LABLE_WHILE_LOOP	@ 如果(a[0][0] || (b == 0))为真，则continue
	nop						@ 否则，直接break；因为我们这里是直接退出循环并不做任何操作，所以我们直接一个nop表示break;语句

.LABLE_END_LOOP:
	add r1, sp, #4		@ r1 = a的地址
	mov r0, #4
	bl	putarray(PLT)   @ 调用putarray()

	ldr r0, [sp]		@ r0 = b
	bl	putint(PLT)		@ 调用putint()

	mov r0, #0			@ return 0; r0存储函数返回值
	add sp, sp, #20		@ 回收栈空间

	pop		{fp}
	pop		{lr}
	bx   lr				@ 返回
	
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0"
	.section	.note.GNU-stack,"",%progbits