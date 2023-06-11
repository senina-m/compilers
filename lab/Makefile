all: build_ast

build_ast:  main.l main.y
		bison -d main.y
		flex main.l
		cc -o $@ main.tab.c lex.yy.c ast.c -lm -O3 -I.
clean:
		rm -rf *.tab.h
		rm -rf *.tab.c
		rm -rf *.yy.c
		rm build_ast
