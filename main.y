%{
#  include <stdio.h>
#  include "ast.h"

extern int yylex();
%}

%token VAR IF THEN ELSE BEGIN_T END
%token ASSIGN
%token MINUS PLUS MULT DIV LESS GREATER EQUALS
%token LCBR RCBR
%token LBR RBR
%token SEMICOLON COMMA
%token<num> CONST 
%token<text> IDENT

%left LESS GREATER EQUALS
%left PLUS MINUS
%left MULT DIV

%type<node> program vars var_list calculation operator assignment complex_op compose_op expression operand

%start program
%union {
    struct Node* node;
    char* text;
    int num;
}

%%
program: vars calculation SEMICOLON     {   FILE* f_ast = fopen(FILENAME_AST, "w");
                                            FILE* f_asm = fopen(FILENAME_ASM, "w");
                                            $$ = create_node("programm");
                                            add_child($$, $1);
                                            add_child($$, $2);
                                            print_ast(f_ast, $$, 0);
                                            if (f_ast) fclose(f_ast);
                                            print_asm(f_asm, $$);
                                            fprintf(f_asm, "ebreak\n");
                                            if (f_asm) fclose(f_asm);
                                            delete_node($$);
                                        };

vars: VAR var_list SEMICOLON            {$$ = $2;};

var_list: IDENT                         {$$ = create_node($1);}
    | IDENT COMMA var_list              {$$ = create_node($1); add_child($$, $3);};

calculation: operator                   {$$ = create_node("calc"); add_child($$, $1);};
    | calculation operator              {$$ = $1; add_child($$, $2);}

operator: assignment SEMICOLON          {$$ = $1;};
    | complex_op                        {$$ = $1;};

assignment: IDENT ASSIGN expression     {$$ = create_node(":=");
                                            add_child($$, create_node($1));
                                            add_child($$, $3);
                                        };

expression: operand                     {$$ = $1;}
    | LCBR expression RCBR              {$$ = $2;}
    | MINUS expression                  {$$ = create_node("-"); add_child($$, $2);}
    | expression MINUS expression       {$$ = create_node("-"); add_child($$, $1); add_child($$, $3);}
    | expression PLUS expression        {$$ = create_node("+"); add_child($$, $1); add_child($$, $3);}
    | expression MULT expression        {$$ = create_node("*"); add_child($$, $1); add_child($$, $3);}
    | expression DIV expression         {$$ = create_node("/"); add_child($$, $1); add_child($$, $3);}
    | expression GREATER expression     {$$ = create_node(">"); add_child($$, $1); add_child($$, $3);}
    | expression LESS expression        {$$ = create_node("<"); add_child($$, $1); add_child($$, $3);}
    | expression EQUALS expression      {$$ = create_node("=="); add_child($$, $1); add_child($$, $3);};


operand: IDENT                          {$$ = create_node($1);}
    | CONST                             {$$ = create_node_int($1);};

complex_op: IF expression THEN operator ELSE operator {$$ = create_node("if");
                                                        add_child($$, $2);
                                                        add_child($$, $4);
                                                        add_child($$, $6);}
    |       compose_op                                 {$$ = $1;};

compose_op: BEGIN_T calculation END     {$$=$2;};
%%
