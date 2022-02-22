#include <stdio.h>
#include <stdlib.h>

int label_count;

typedef struct Cell {
    struct Cell* cdr;
    struct Cell* car;
} Cell;

// Read single char
static void* gettoken() {
    char look = getchar();

    //Ignore whitespace
    while(look == ' ' || look == '\n') { look = getchar(); }

    return (Cell*)(unsigned long)look;
}

// Read cell
static void* getcell() {
    Cell* token = gettoken();

    // If empty, return empty cell
    if ((unsigned long)token == ')') return 0;

    Cell* result = calloc(1, sizeof(Cell));

    // Check for nested cell
    token = (unsigned long)token == '(' ? getcell() : token;

    *result = (Cell){ .car = token, .cdr = getcell()};
    return result;
}

// Compile lambda
void compile(Cell *exp) {
    // Check if symbol or cell
    if (((unsigned long)exp | 0xFF) == 0xFF ) {
        // Process symbol
        printf("mov rdi, %lu\n", (unsigned long)exp);
        printf("call get_val\n");
    } else if ((unsigned long)exp->car == 'l') {
        // Process lambda function
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
    } else {
        // Function call
        compile(exp->car);
        printf("push rax\n");
        compile(exp->cdr->car);
        printf("pop rdi\n");
        printf("mov rsi, rax\n");
        printf("call apply\n");
    }
}

int main() {
    // Make GAS happy
    printf(".globl app\napp:\n");

    // Parse source
    Cell* token = gettoken();

    // Compile source
    compile((unsigned long)token == '(' ? getcell() : token);
    printf("ret\n");
    return 0;
}
