%{
#  include <stdio.h>
#  include <stdlib.h>
#  include "ast.h"

extern int yylex();
%}

%start program
%union {
   struct tree *node;
   char *text;
   int num;
}

%token VAR IF THEN ELSE BEGIN_T END
%token ASSIGN
%token MINUS PLUS MULT DIV LESS GREATER EQ
%token LCBR RCBR
%token SEMICOLON COMMA

%left LESS MORE EQUALS
%left PLUS MINUS
%left MUL DIV

%token<num> CONST 
%token<text> IDENT

%type<node> program vars var_list calculation_disc operators_list operator assignment
%type<node> expression underexpression bin_op operand complex_op compose_op


%%
program: vars calculation_disc SEMICOLON {$$ = new_tree_node("program", new_tree_node("vars", $1, NULL), NULL);
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
    | IDENT COMMA var_list {$$ = new_tree_node($1, NULL, NULL); $$->next = $3;};

calculation_disc: operators_list {$$=new_tree_node("Calculations", $1, NULL);};

operators_list: operator {$$=$1;}
    | operator operators_list {$$=$1; $$->next = $2;};

operator: assignment {$$=new_tree_node("=", $1, NULL);}
    | complex_op {$$=$1;};

assignment: IDENT ASSIGN expression SEMICOLON {$$=new_tree_node($1, NULL, $3);};

expression: MINUS underexpression {$$=new_tree_node("-", $2, NULL);}
    | underexpression {$$=$1;};

underexpression: LCBR expression RCBR {$$=$2;}
    | operand {$$=$1;}
    | underexpression bin_op underexpression {$$=$2; $$->child = $1; $$->child->next = $3;};

bin_op: MINUS {$$=new_tree_node("-", NULL, NULL);}
    | PLUS {$$=new_tree_node("+", NULL, NULL);}
    | MULT {$$=new_tree_node("*", NULL, NULL);}
    | DIV {$$=new_tree_node("/", NULL, NULL);}
    | GREATER {$$=new_tree_node("<", NULL, NULL);}
    | LESS {$$=new_tree_node(">", NULL, NULL);}
    | EQ {$$=new_tree_node("==", NULL, NULL);};

operand: IDENT {$$ = new_tree_node($1, NULL, NULL);}
    | CONST {$$ = new_tree_node_int($1, NULL, NULL);};

complex_op: IF expression THEN operator {$$=new_tree_node("if", $2, NULL);
                                        $$->child->next = $4;}
    | compose_op {$$=new_tree_node("composed", $1, NULL);};

compose_op: BEGIN_T operators_list END {$$=$2;};
%%