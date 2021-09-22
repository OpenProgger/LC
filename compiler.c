#include <stdio.h>
#include <stdlib.h>

int label_count;

typedef struct List {
	struct List * cdr;
	struct List * car;
} List;

static void* gettoken() {
	char look = getchar();
	while(look == ' ' || look == '\n') { look = getchar(); }
	return (List*)(unsigned long)look;
}

void* getlist() {
	List* token = gettoken();
	if ((unsigned long)token == ')') return 0;
	List* result = calloc(1, sizeof(List));
	token = (unsigned long)token == '(' ? getlist() : token;
	*result = (List){ .car = token, .cdr = getlist()};
	return result;
}

void compile(List *exp) {
	if (((unsigned long)exp | 0xFF) == 0xFF ) {
		printf("mov rdi, %lu\n", (unsigned long)exp);
		printf("call get_val\n");
	} else if ((unsigned long)exp->car == 'l') {
		int label = label_count++;
		printf("call L%d\n", label);
		printf("mov rsi, rdi\n");
		printf("mov rdi, %lu\n", (unsigned long)(exp->cdr->car->car));
		printf("call set_var\n");
		compile(exp->cdr->cdr->car);
		printf("ret\n");
		printf("L%d:\n", label);
		printf("pop rdi\n");
		printf("call gen_closure\n");
	} else { /* function call */
		compile(exp->car);
		printf("push rax\n");
		compile(exp->cdr->car);
		printf("pop rdi\n");
		printf("mov rsi, rax\n");
		printf("call apply\n");
	}
}

int main() {
	printf(".globl app\napp:\n");
	List* token = gettoken();
	compile((unsigned long)token == '(' ? getlist() : token);
	printf("ret\n");
	return 0;
}
