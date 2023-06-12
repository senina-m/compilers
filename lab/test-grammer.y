%{
#  include <stdio.h>
#  include "ast.h"

extern int yylex();
%}

%parse-param {char *path}

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
    struct ast_node *node;
    char text[256];
    int num;
}

%%
program: vars calculation           {printf("program\n");};

vars: VAR var_list SEMICOLON        {printf("vars\n");};

var_list: IDENT                     {printf("var_list: IDENT\n");}
    | IDENT COMMA var_list          {printf("var_list: IDENT COMMA var_list\n");};

calculation: operator SEMICOLON      {printf("calculation: operator\n");}
    | calculation operator SEMICOLON {printf("calculation: calculation operator SEMICOLON\n");};

operator: assignment                {printf("operator: assignment\n");}
    | complex_op                    {printf("operator: complex_op\n");};

assignment: IDENT ASSIGN expression {printf("assignment: IDENT ASSIGN expression\n");};

expression: operand                 {printf("expression: operand\n");}
    | LCBR expression RCBR          {printf("expression: LCBR expression RCBR\n");}
    | MINUS expression              {printf("expression: LCBR MINUS expression RCBR\n");}
    | expression MINUS expression   {printf("expression: expression PLUS expression\n");}
    | expression PLUS expression    {printf("expression: expression PLUS expression\n");}
    | expression MULT expression    {printf("expression: expression MULT expression\n");}
    | expression DIV expression     {printf("expression: expression DIV expression\n");}
    | expression GREATER expression {printf("expression: expression GREATER expression\n");}
    | expression LESS expression    {printf("expression: expression LESS expression\n");}
    | expression EQUALS expression   {printf("expression: expression EQUALS expression\n");};


operand: IDENT {printf("operand: IDENT\n");}
    | CONST    {printf("operand: CONST\n");};

complex_op: IF expression THEN operator ELSE operator {printf("complex_op: IF expression THEN operator ELSE operator\n");}
    | compose_op {printf("complex_op: compose_op\n");};

compose_op: BEGIN_T calculation END {printf("compose_op: BEGIN_T calculation END\n");};
%%