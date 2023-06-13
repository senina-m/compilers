# include <stdio.h>
# include <stdlib.h>
# include <stdbool.h>
# include <stdarg.h>
# include <string.h>

#define FILENAME_AST "/home/marsen/itmo/compilers/lab/ast.txt"
#define FILENAME_ASM "/home/marsen/itmo/compilers/lab/asm.txt"

#define mmalloc(T) ((T*)malloc(sizeof(T)))
#define mmalloc_array(T, count) ((T**)malloc(sizeof(T)*count))

typedef struct Node {
    size_t children_num;
    struct Node **children;
    char* name;
    int val;
} Node;

void yyerror(char *s, ...);
extern int yylineno;
int yylex();
int yyparse (void);


Node* create_node(char* name);
Node* create_node_int(int val);
void delete_node(Node *node);

void add_child(Node *node, Node *child);
void print_ast(FILE* f_ast, Node* node, size_t tabs);
void print_asm(FILE* f_asm, Node* node);

