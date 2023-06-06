/* simplest version of calculator */

%{

# include <stdio.h>
void yyerror(char *s);
int main();

%}

/* declare tokens */
%token NUMBER
%token ADD SUB MUL DIV
%token OP CP
%token EOL

%left ADD SUB
%left MUL DIV

%%

calclist: /* nothing */
 | calclist expr EOL { printf("= %d\n> ", $2); }
 | calclist EOL { printf("> "); } /* blank line or a comment */
 ;

expr: expr ADD expr { $$ = $1 + $3; }
 | expr SUB expr { $$ = $1 - $3; }
 | expr MUL expr { $$ = $1 * $3; }
 | expr DIV expr { $$ = $1 / $3; }
 | NUMBER
 | OP expr CP { $$ = $2; }
 ;

%%
int main()
{
  printf("> "); 
  yyparse();
  return 0;
}

void yyerror(char *s)
{
  fprintf(stderr, "error: %s\n", s);
}
