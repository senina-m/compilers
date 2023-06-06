{
#include "main.tab.h"
%}

%%
[/][/].*\n      ; // comment

Var     {return VAR;}
==      {return EQ;}
IF      {return IF;}
ELSE      {return ELSE;}
THEN    {return THEN;}
Begin   {return BEGIN_T;}
End     {return END;}

[a-z]+  { yylval.text = strdup(yytext); return IDENT;} /* <Идент> */
[0-9]+	{ yylval.num = atoi(yytext); return CONST; } /* <Сonst> */

[ \t\r\n]       ; // whitespace
.	    {return (int) yytext[0];}

%%