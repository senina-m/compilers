%{
    # include <stdio.h>
# include <stdlib.h>
# include <stdbool.h>
# include <string.h>

#define YYERROR_VERBOSE 1

void yyerror(const char *str)
{
   fprintf(stderr, "Error: %s\n",str);
}

int yywrap()
{
   return 1;
}

struct tree {
    struct tree *child;
    struct tree *next;
    char *text;
    int num;
};

struct tree *new_tree_node (char *text, struct tree *child, struct tree *next)
{
    struct tree *node = malloc(sizeof(struct tree));
    node->text = text;
    node->child = child;
    node->next = next;
    return node;
}

struct tree *new_tree_node_int (int num, struct tree *child, struct tree *next)
{
    struct tree *node = malloc(sizeof(struct tree));
    node->text = NULL;
    node->num = num;
    node->child = child;
    node->next = next;
    return node;
}

static void print_tree(struct tree *cur, int lvl, FILE* fl) {
    for(int i = 0; i < lvl; i++) fprintf(fl, "  ");
    if (cur->text)
        fprintf(fl, "%s\n", cur->text);
    else
        fprintf(fl, "n: %d\n", cur->num);
    if (cur->child != NULL)
      print_tree(cur->child, lvl + 1, fl);
    if (cur->next != NULL)
      print_tree(cur->next, lvl, fl);
}

struct vars_adresses {
    char* var;
    int addr;
    struct vars_adresses* next;
};

static struct vars_adresses* table = NULL;

static void add_var(char* var, int adress)
{
    if (table == NULL)
    {
        table = malloc(sizeof(struct vars_adresses));
        table->next = NULL;
        table->var = var;
        table->addr = adress;
    }
    else
    {
        struct vars_adresses* table_cur = table;
        while (table_cur->next != NULL)
            table_cur = table_cur->next;
        table_cur->next = malloc(sizeof(struct vars_adresses));
        table_cur->next->next = NULL;
        table_cur->next->var = var;
        table_cur->next->addr = adress;
    }
}

static int get_var(char* var)
{
    struct vars_adresses* table_cur = table;
    while (table_cur != NULL)
    {
        if (strcmp(table_cur->var, var) == 0)
            return table_cur->addr;
        table_cur = table_cur->next;
    }
    return -1;
}

static void translate_vars(struct tree *cur, FILE* fl, int num)
{
    fprintf(fl, "%s:\ndata 0 * 1\n", cur->text);
    add_var(cur->text, num);
    if (cur->next)
        translate_vars(cur->next, fl, num + 1);
}

static int translate_expression(struct tree *cur, FILE* fl, int you_ind)
{
    if (cur->text == NULL)
    {
        fprintf(fl, "addi x%d, x0, %d\n", you_ind, cur->num);
        return you_ind + 1;
    }
    else if (strcmp(cur->text, "not") == 0)
    {
        int end_ind = translate_expression(cur->child, fl, you_ind + 1);
        fprintf(fl, "xori x%d, x%d, 4095\n", you_ind, you_ind + 1);
        return end_ind;
    }
    else if (strcmp(cur->text, "+") == 0)
    {
        int end_ind1 = translate_expression(cur->child, fl, you_ind + 1);
        int end_ind2 = translate_expression(cur->child->next, fl, end_ind1);
        fprintf(fl, "add x%d, x%d, x%d\n", you_ind, you_ind + 1, end_ind1);
        return end_ind2;
    }
    else if (strcmp(cur->text, "-") == 0)
    {
        if (cur->child->next == NULL)
        {
            int end_ind = translate_expression(cur->child, fl, you_ind + 1);
            fprintf(fl, "sub x%d, x0, x%d\n", you_ind, you_ind + 1);
            return end_ind;
        }
        else
        {
            int end_ind1 = translate_expression(cur->child, fl, you_ind + 1);
            int end_ind2 = translate_expression(cur->child->next, fl, end_ind1);
            fprintf(fl, "sub x%d, x%d, x%d\n", you_ind, you_ind + 1, end_ind1);
            return end_ind2;
        }
    }
    else if (strcmp(cur->text, "*") == 0)
    {
        int end_ind1 = translate_expression(cur->child, fl, you_ind + 1);
        int end_ind2 = translate_expression(cur->child->next, fl, end_ind1);
        fprintf(fl, "mul x%d, x%d, x%d\n", you_ind, you_ind + 1, end_ind1);
        return end_ind2;
    }
    else if (strcmp(cur->text, "/") == 0)
    {
        int end_ind1 = translate_expression(cur->child, fl, you_ind + 1);
        int end_ind2 = translate_expression(cur->child->next, fl, end_ind1);
        fprintf(fl, "div x%d, x%d, x%d\n", you_ind, you_ind + 1, end_ind1);
        return end_ind2;
    }
    else
    {
        fprintf(fl, "lw x%d, x0, %d\n", you_ind, get_var(cur->text));
        return you_ind + 1;
    }
    return you_ind;
}

static int cycles_count = 0;

static void tree_to_asm(struct tree *cur, FILE* fl) {
    if (cur == NULL)
        return;
    if (cur->text == NULL)
        fprintf(fl, ";strange\n");
    else if (strcmp(cur->text, "program") == 0)
    {
        fprintf(fl, "jal x1, MAIN\n");
        tree_to_asm(cur->child, fl);
        tree_to_asm(cur->child->next, fl);
    }
    else if (strcmp(cur->text, "Calculations") == 0)
    {
        fprintf(fl, "MAIN:\n");
        tree_to_asm(cur->child, fl);
    }
    else if (strcmp(cur->text, "=") == 0)
    {
        translate_expression(cur->child->next, fl, 1);
        fprintf(fl, "sw x0, %d, x1\n", get_var(cur->child->text));
        tree_to_asm(cur->next, fl);
    }
    else if (strcmp(cur->text, "vars") == 0)
        translate_vars(cur->child, fl, 1);
    else if (strcmp(cur->text, "composed") == 0)
    {
        tree_to_asm(cur->child, fl);
        tree_to_asm(cur->next, fl);
    }
    else if (strcmp(cur->text, "while") == 0)
    {
        int cycle = cycles_count++;
        fprintf(fl, "START_CYCLE_%d:\n", cycle);
        int end_ind1 = translate_expression(cur->child->child, fl, 1);
        int end_ind2 = translate_expression(cur->child->child->next, fl, end_ind1);
        if (strcmp(cur->child->text, ">") == 0)
        {
            fprintf(fl, "blt x%d, x%d, END_CYCLE_%d\n", 1, end_ind1, cycle);
            fprintf(fl, "beq x%d, x%d, END_CYCLE_%d\n", 1, end_ind1, cycle);
        } else if (strcmp(cur->child->text, "<") == 0)
        {
            fprintf(fl, "bge x%d, x%d, END_CYCLE_%d\n", 1, end_ind1, cycle);
            fprintf(fl, "beq x%d, x%d, END_CYCLE_%d\n", 1, end_ind1, cycle);
        } else if (strcmp(cur->child->text, "==") == 0)
        {
            fprintf(fl, "bne x%d, x%d, END_CYCLE_%d\n", 1, end_ind1, cycle);
        }
        tree_to_asm(cur->child->next, fl);
        fprintf(fl, "jal x1, START_CYCLE_%d\n", cycle);  
        fprintf(fl, "END_CYCLE_%d:\n", cycle);
    }
}
int yylex();
void main();
%}

%start program
%union {
   struct tree *node;
   char *text;
   int num;
}

%token<text> IDENT
%token<num> CONST 
%token VAR EQ IF THEN ELSE BEGIN_T END
%type<node> program vars var_list calculation_disc operators_list operator assignment
%type<node> expression underexpression bin_op operand complex_op compose_op

%left '+' '-'
%left '*' '/'
%%

program: vars calculation_disc ';' {$$ = new_tree_node("program", new_tree_node("vars", $1, NULL), NULL);
                                $$->child->next = $2;
                                FILE* fl = fopen("tree.tr", "w");
                                FILE* fl2 = fopen("code.s", "w");
                                print_tree($$, 0, fl);
                                tree_to_asm($$, fl2);
                                fprintf(fl2, "ebreak\n");
                                fclose(fl);
                                fclose(fl2);};

vars: VAR var_list {$$ = $2;};

var_list: IDENT {$$ = new_tree_node($1, NULL, NULL);}
    | IDENT ',' var_list {$$ = new_tree_node($1, NULL, NULL); $$->next = $3;};

calculation_disc: operators_list {$$=new_tree_node("Calculations", $1, NULL);};

operators_list: operator {$$=$1;}
    | operator operators_list {$$=$1; $$->next = $2;};

operator: assignment {$$=new_tree_node("=", $1, NULL);}
    | complex_op {$$=$1;};

assignment: IDENT ":=" expression ';' {$$=new_tree_node($1, NULL, $3);};

expression: '-' underexpression {$$=new_tree_node("-", $2, NULL);}
    | underexpression {$$=$1;};

underexpression: '(' expression ')' {$$=$2;}
    | operand {$$=$1;}
    | underexpression bin_op underexpression {$$=$2; $$->child = $1; $$->child->next = $3;};

bin_op: '-' {$$=new_tree_node("-", NULL, NULL);}
    | '+' {$$=new_tree_node("+", NULL, NULL);}
    | '*' {$$=new_tree_node("*", NULL, NULL);}
    | '/' {$$=new_tree_node("/", NULL, NULL);}
    | '<' {$$=new_tree_node("<", NULL, NULL);}
    | '>' {$$=new_tree_node(">", NULL, NULL);}
    | EQ {$$=new_tree_node("==", NULL, NULL);};

operand: IDENT {$$ = new_tree_node($1, NULL, NULL);}
    | CONST {$$ = new_tree_node_int($1, NULL, NULL);};

complex_op: IF expression THEN operator {$$=new_tree_node("if", $2, NULL);
                                        $$->child->next = $4;}
    | compose_op {$$=new_tree_node("composed", $1, NULL);};

compose_op: BEGIN_T operators_list END {$$=$2;};

%%