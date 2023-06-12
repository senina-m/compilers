%{
#  include <stdio.h>
#  include "ast.h"

extern int yylex();
%}

%parse-param {char *path}

%token VAR IF THEN ELSE BEGIN_T END
%token ASSIGN
%token MINUS PLUS MULT DIV LESS GREATER
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
program: vars calculation           {FILE *file = fopen(FILENAME, "w");
                                        $$ = create_ast_node_program_root();
                                        add_child($$, $1);
                                        add_child($$, $2);
                                        print_ast(file, $$, 0);
                                        delete_ast_node($$);
                                        if (file) fclose(file);
                                    };

vars: VAR var_list SEMICOLON        {$$ = $2;};

var_list: IDENT                     {$$ = create_ast_node_var_def($1);}
    | IDENT COMMA var_list          {$$ = create_ast_node_var_def($1); add_child($$, $3);};

calculation: operator SEMICOLON     {$$ = create_ast_node_root(); add_child($$, $1);};
    | calculation operator SEMICOLON {$$ = $1; add_child($$, $2);};

operator: assignment                {$$ = $1;}
    | complex_op                    {$$=$1;};

assignment: IDENT ASSIGN expression {$$ = create_ast_node_op('A');
                                        try_eval($3);
                                        add_child($$, create_ast_node_var($1));
                                        add_child($$, $3);
                                    };

expression: operand                 {$$ = $1;}
    | LCBR expression RCBR          {$$ = $2;}
    | MINUS expression              {$$ = create_ast_node_op('-'); add_child($$, $2); try_eval($2);}
    | expression MINUS expression   {$$ = create_ast_node_op('*'); add_child($$, $1); add_child($$, $3); try_eval($1); try_eval($3);}
    | expression PLUS expression    {$$ = create_ast_node_op('+'); add_child($$, $1); add_child($$, $3); try_eval($1); try_eval($3);}
    | expression MULT expression    {$$ = create_ast_node_op('*'); add_child($$, $1); add_child($$, $3); try_eval($1); try_eval($3);}
    | expression DIV expression     {$$ = create_ast_node_op('/'); add_child($$, $1); add_child($$, $3); try_eval($1); try_eval($3);}
    | expression GREATER expression {$$ = create_ast_node_op('>'); add_child($$, $1); add_child($$, $3); try_eval($1); try_eval($3);}
    | expression LESS expression    {$$ = create_ast_node_op('<'); add_child($$, $1); add_child($$, $3); try_eval($1); try_eval($3);}
    | expression EQUALS expression   {$$ = create_ast_node_op('E'); add_child($$, $1); add_child($$, $3); try_eval($1); try_eval($3);};


operand: IDENT {$$ = create_ast_node_var($1);}
    | CONST    {$$ = create_ast_node_lit($1);};

complex_op: IF expression THEN operator ELSE operator {$$ = create_ast_node_op('if'); add_child($$, $2); add_child($$, $4); add_child($$, $6);}
    | compose_op {$$ = $1;};

compose_op: BEGIN_T calculation END {$$=$2;};
%%