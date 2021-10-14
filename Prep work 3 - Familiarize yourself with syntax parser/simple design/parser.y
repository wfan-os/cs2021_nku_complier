%{
/********************************************************************************************************
parpser.y
YACC file
Date: 2021/10/15
wangxiaofan0828 <wangxiaofan0828@163.com>
*********************************************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef YYSTYPE
#define YYSTYPE double
#endif

int yylex();
extern int yyparse();
FILE* yyin;
void yyerror(const char* s);
int isdigit(int t);
%}

// OPERAND
%token ADD
%token MINUS
%token MUL
%token DIV
%token L_PAREN
%token R_PAREN

// SEMI
%token semi

// NUMBER
%token INTEGER


%left ADD MINUS
%left MUL DIV
%nonassoc UMINUS

%%

lines:	lines expr semi{ printf("%f\n", $2); }
	 |	lines semi
	 |
     ;

expr:	expr ADD term{ $$ = $1 + $3; }
	|	expr MINUS term{ $$ = $1 + $3; }
	|	term{ $$ = $1; }

term:	term MUL factor{ $$ = $1 * $3; }
	|	term DIV factor{ 
		if ($3 == 0.0)
			yyerror("divided by zero");
		else
			$$ = $1 / $3;
	 }
	|	factor{$$ = $1;}

factor:	INTEGER{ $$ = $1; }
	  | L_PAREN expr R_PAREN{ $$ = $2; }
	  | MINUS expr %prec UMINUS{ $$ = -$2; }


%%

// programs section

int yylex()
{
	int t;
	while (1) {
		t = getchar();
		if (t == ' ' || t == '\t' || t == '\n') {
			// do nothing
		}
		else if (isdigit(t)) {
			yylval = 0;
			while (isdigit(t)) {
				yylval = yylval * 10 + t - '0';
				t = getchar();
			}
			ungetc(t, stdin);
			return INTEGER;
		}
		else if (t == '+' || t == '-' || t == '*' || t == '/' || t == '(' || t == ')')
		{
			switch (t)
			{
			case '+': return ADD;
			case '-': return MINUS;
			case '*': return MUL;
			case '/': return DIV;
			case '(': return L_PAREN;
			case ')': return R_PAREN;
			}
		}
		else if (t == ';')
			return semi;
		else
		{
			char s[] = "Unknown token: ";
			strcat(s, (char*) &t);
			yyerror(s);
		}
	}
}

int main(void)
{
	yyin = stdin;
	do {
		yyparse();
	} while (!feof(yyin));
	return 0;
}

void yyerror(const char* s)
{
	fprintf(stderr, "Parse Error: %s\n", s);
	exit(1);
}

int isdigit(int t)
{
	if (t >= '0' && t <= '9')return 1;
	else return 0;
}