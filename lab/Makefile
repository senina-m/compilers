ADRESSFLAGS=-fsanitize=address

all: build_ast

build_ast:  main.l main.y
		bison -d main.y
		flex main.l
		cc  $(ADRESSFLAGS) -o $@ main.tab.c lex.yy.c ast.c -lm -O3 -I.

test_grammer: test-grammer.y main.l
		bison -d test-grammer.y
		flex main.l
		cc  $(ADRESSFLAGS) -o $@ test-grammer.tab.c lex.yy.c ast.c -lm -O3 -I.
clean:
		rm -rf *.tab.h
		rm -rf *.tab.c
		rm -rf *.yy.c
		rm build_ast
		rm test_grammer
