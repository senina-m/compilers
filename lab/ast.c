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
    printf("node: %s\n", node->name);
    return node;
}

Node* create_node_int(int val){
    printf("val=%i\n", val);
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
    printf("%s -> %s\n", node->name, child->name);
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


void print_ast(FILE* f_ast, Node *node, size_t tabs) {
    if (!node) return;
    print_tabs(f_ast, tabs);
    
    if (node->name[0] == '#') fprintf(f_ast, "%s(%i)\n", node->name, node->val);
    else fprintf(f_ast, "%s\n", node->name);

    for (size_t i = 0; i < node->children_num; i++)
        print_ast(f_ast, node->children[i], tabs + 1);
}

void print_asm(FILE* f_asm, Node *node) {
    if (!node) return;
    fprintf(f_asm, "some asm");

    
    // if (strcmp(node->name, "int")) fprintf(f_asm, "%s\n", node->name);
    // else fprintf(f_asm, "%s(%i)\n", node->name, node->val);

    // for (size_t i = 0; i < node->children_num; i++)
    //     print_asm(f_asm, node->children[i]);
}

int main() {
  printf("> "); 
  return yyparse(FILENAME_AST, FILENAME_ASM);
}
