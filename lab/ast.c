# include "ast.h"

void yyerror(char *s, ...) {
  va_list ap;
  va_start(ap, s);

  fprintf(stderr, "%d: error: ", yylineno);
  vfprintf(stderr, s, ap);
  fprintf(stderr, "\n");
}

char *alloc_string(char *str) {
    if (!str) return NULL;
    char *string = (char*) malloc(sizeof(char) * strlen(str) + 1);
    memset(string, 0, strlen(str) + 1);
    memcpy(string, str, strlen(str) + 1);
    return string;
}

Node *create_node(char* name) {

    Node* node = mmalloc(Node);
    node->name = name;
    node->children_num = 0;
    node->children = NULL;
    // printf("node: %s\n", node->name);
    return node;
}

Node* create_node_int(int val){
    // printf("val=%i\n", val);
    Node* node = create_node("#");
    node->val = val;
    return node;
}

void delete_node(Node *node) {
    if (!node) return;
    for (size_t i = 0; i < node->children_num; i++)
        delete_node(node->children[i]);
    free(node->children);
    // free(node->name);
    free(node);
}

void add_child(Node* node, Node* child) {
    // printf("%s -> %s\n", node->name, child->name);
    node->children_num++;
    Node** nodes = mmalloc_array(Node, node->children_num);
    for (size_t i = 0; i < node->children_num - 1; i++)
        nodes[i] = node->children[i];
    nodes[node->children_num - 1] = child;
    if (node->children) free(node->children);
    node->children = nodes;
}

static void print_tabs(FILE* f, size_t tabs){
    for(int i = 0; i < tabs; i++)
        fprintf(f, "\t");
}


void print_ast(FILE* f, Node *node, size_t tabs) {
    if (!node) return;
    print_tabs(f, tabs);
    
    if (node->name[0] == '#') fprintf(f, "%s(%i)\n", node->name, node->val);
    else fprintf(f, "%s\n", node->name);

    for (size_t i = 0; i < node->children_num; i++)
        print_ast(f, node->children[i], tabs + 1);
}

typedef struct vars_adresses {
    char* var;
    int addr;
    struct vars_adresses* next;
} Vars_addr;

static Vars_addr* table = NULL;

static void print_vars(){
    Vars_addr* table_node = table;
    printf("vars list: ");
    while (table_node != NULL){
        printf("%s, ", table_node->var);
        table_node = table_node->next;
    }
    printf("\n");
}

static int get_var(char* var){
    Vars_addr* table_node = table;
    while (table_node != NULL){
        if (strcmp(table_node->var, var) == 0)
            return table_node->addr;
        table_node = table_node->next;
    }
    return -1;
}

static void add_var(char* var, int adress){
    if (table == NULL){
        table = mmalloc(Vars_addr);
        table->next = NULL;
        table->var = var;
        table->addr = adress;
    } else {
        Vars_addr* table_cur = table;
        while (table_cur->next != NULL) table_cur = table_cur->next;
        table_cur->next = mmalloc(Vars_addr);
        table_cur->next->next = NULL;
        table_cur->next->var = var;
        table_cur->next->addr = adress;
    }
}

int print_asm_expr(FILE* f, Node *node, int ind) {
    printf("expr: %s\n", node->name);
    switch (node->name[0]){
    case '#': {
        fprintf(f, "addi x%d, x0, %d\n", ind, node->val);
        return ind + 1;
    }
    case '+': {
        int ind1 = print_asm_expr(f, node->children[0], ind + 1);
        int ind2 = print_asm_expr(f, node->children[1], ind1);
        fprintf(f, "add x%d, x%d, x%d\n", ind, ind + 1, ind1);
        return ind2;
    }
    case '-': {
        if (node->children_num == 1){
            int ind = print_asm_expr(f, node->children[0], ind);
            fprintf(f, "sub x%d, x0, x%d\n", ind, ind);
            return ind;
        }else{
            int ind1 = print_asm_expr(f, node->children[0], ind + 1);
            int ind2 = print_asm_expr(f, node->children[1], ind1);
            fprintf(f, "sub x%d, x%d, x%d\n", ind, ind + 1, ind1);
            return ind2;
        }
    }
    case '*': {
        int ind1 = print_asm_expr(f, node->children[0], ind + 1);
        int ind2 = print_asm_expr(f, node->children[1], ind1);
        fprintf(f, "mul x%d, x%d, x%d\n", ind, ind + 1, ind1);
        return ind2;
    }
    case '/': {
        int ind1 = print_asm_expr(f, node->children[0], ind + 1);
        int ind2 = print_asm_expr(f, node->children[1], ind1);
        fprintf(f, "div x%d, x%d, x%d\n", ind, ind + 1, ind1);
        return ind2;
    }
    case '>': {
        int ind1 = print_asm_expr(f, node->children[0], ind + 1);
        int ind2 = print_asm_expr(f, node->children[1], ind1);
        fprintf(f, "slt x%d, x%d, x%d\n", ind, ind1, ind + 1);
        return ind2;
    }
    case '<': {
        int ind1 = print_asm_expr(f, node->children[0], ind + 1);
        int ind2 = print_asm_expr(f, node->children[1], ind1);
        fprintf(f, "slt x%d, x%d, x%d\n", ind, ind + 1, ind1);
        return ind2;
    }
    case '=': {
        int ind1 = print_asm_expr(f, node->children[0], ind + 1);
        int ind2 = print_asm_expr(f, node->children[1], ind1);
        fprintf(f, "seq x%d, x%d, x%d\n", ind, ind + 1, ind1);
        return ind2;

    } default: {
        printf("Load word: %s to x%d\n", node->name, get_var(node->name));
        fprintf(f, "lw x%d, x0, %d\n", ind, get_var(node->name));
        return ind + 1;
    }
    }
    return ind;
}

static void load_vars(Node* node, FILE* f, int num){
    fprintf(f, "%s:\ndata 0 * 1\n", node->name);
    add_var(node->name, num);
    if (node->children_num == 1)
        load_vars(node->children[0], f, num + 1);
}

int if_num = 0;

void print_asm(FILE* f, Node* node) {
    if (node == NULL) return;

    if (node->name == NULL) fprintf(f, ";strange\n");
    else if (!strcmp(node->name, "programm")){
        printf("program \n");
        fprintf(f, "jal x1, MAIN\n");

        printf("vars \n");
        load_vars(node->children[0], f, 1);
        print_vars();
        fprintf(f, "MAIN:\n");

        // fprintf(f, "jal x1, MAIN\n");
        print_asm(f, node->children[1]);

    }    else if (!strcmp(node->name, "calc")){
        printf("calc \n");
        for (int i = 0; i < node->children_num; i++){
            print_asm(f, node->children[i]);
        }

    }else if (!strcmp(node->name, ":=")){
        printf("assign \n");
        print_asm_expr(f, node->children[0], 1);
        print_asm_expr(f, node->children[1], 1);    
        fprintf(f, "sw x0, %d, x1\n", get_var(node->children[0]->name));

    }else if (!strcmp(node->name, "IF")){
        if_num++;

        //todo print expr JMP to IF_THEN_%d or IF_ELSE_%d

        fprintf(f, "IF_THEN_%d:\n", if_num);
        int ind1 = print_asm_expr(f, node->children[1], 1);
        fprintf(f, "IF_ELSE_%d:\n", if_num);
        int ind2 = print_asm_expr(f, node->children[2], ind1);
    }
}

int main() {
  printf("> "); 
  return yyparse();
}
