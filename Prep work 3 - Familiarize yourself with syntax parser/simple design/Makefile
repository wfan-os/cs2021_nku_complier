all: a.out

a.out: parser.tab.c
	gcc parser.tab.c

parser.tab.c: parser.y
	bison parser.y
	