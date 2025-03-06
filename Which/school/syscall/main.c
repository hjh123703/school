#include <stdio.h>

extern int call_syscall(void);

int main()
{
	int my_pid = call_syscall();
	printf("getpid(): %d\n", my_pid);
	return 0;
}

