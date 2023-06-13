%option noyywrap nodefault yylineno

%{
#include <stdio.h>
#include "main.tab.h"
#include "ast.h"
%}

%%
[/][/].*\n      ; // comment

Var     {return VAR;}
IF      {return IF;}
ELSE    {return ELSE;}
THEN    {return THEN;}
Begin   {return BEGIN_T;}
End     {return END;}

":=" {return ASSIGN;}

"+" {return PLUS;}
"-" {return MINUS;}
"*" {return MULT;}
"/" {return DIV;}
"(" {return LCBR;}
")" {return RCBR;}
"{" {return LBR;}
"}" {return RBR;}
">" {return GREATER;}
"<"  {return LESS;}
"==" {return EQUALS;}
";" {return SEMICOLON;}
"," {return COMMA;}

[a-z]+  { yylval.text = strdup(yytext); return IDENT; return IDENT;} /* <Идент> */
[0-9]+	{ yylval.num = atoi(yytext); return CONST; } /* <Сonst> */

[ \t\r\n] ; // whitespace
.	{ yyerror("Mystery character \"%c\"\n", *yytext); }

%%