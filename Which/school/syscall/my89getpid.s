
.globl call_syscall
.text
call_syscall:
	mov $39, %rax 
	syscall
	ret
