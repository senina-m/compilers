struct tree {
    struct tree *child;
    struct tree *next;
    char *text;
    int num;
};

struct vars_adresses {
    char* var;
    int addr;
    struct vars_adresses* next;
};

void yyerror(char *s, ...);
extern int yylineno; 
struct tree *new_tree_node (char *text, struct tree *child, struct tree *next);
struct tree *new_tree_node_int (int num, struct tree *child, struct tree *next);
void print_tree(struct tree *cur, int lvl, FILE* fl);
void add_var(char* var, int adress);
int get_var(char* var);
void translate_vars(struct tree *cur, FILE* fl, int num);
int translate_expression(struct tree *cur, FILE* fl, int you_ind);
void tree_to_asm(struct tree *cur, FILE* fl);
int yylex();
