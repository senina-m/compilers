# include <stdio.h>
# include <stdlib.h>
# include <stdbool.h>
#  include <stdarg.h>
# include <string.h>
# include "ast.h"

#define YYERROR_VERBOSE 1

void yyerror(char *s, ...) {
  va_list ap;
  va_start(ap, s);

  fprintf(stderr, "%d: error: ", yylineno);
  vfprintf(stderr, s, ap);
  fprintf(stderr, "\n");
}

struct tree *new_tree_node (char *text, struct tree *child, struct tree *next){
    struct tree *node = malloc(sizeof(struct tree));
    node->text = text;
    node->child = child;
    node->next = next;
    return node;
}

struct tree *new_tree_node_int (int num, struct tree *child, struct tree *next){
    struct tree *node = malloc(sizeof(struct tree));
    node->text = NULL;
    node->num = num;
    node->child = child;
    node->next = next;
    return node;
}

void print_tree(struct tree *cur, int lvl, FILE* fl) {
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

static struct vars_adresses* table = NULL;

void add_var(char* var, int adress) {
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

int get_var(char* var){
    struct vars_adresses* table_cur = table;
    while (table_cur != NULL)
    {
        if (strcmp(table_cur->var, var) == 0)
            return table_cur->addr;
        table_cur = table_cur->next;
    }
    return -1;
}

void translate_vars(struct tree *cur, FILE* fl, int num){
    fprintf(fl, "%s:\ndata 0 * 1\n", cur->text);
    add_var(cur->text, num);
    if (cur->next)
        translate_vars(cur->next, fl, num + 1);
}

int translate_expression(struct tree *cur, FILE* fl, int you_ind){
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

void tree_to_asm(struct tree *cur, FILE* fl) {
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

int main() {
  printf("> "); 
  return yyparse();
}
