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
#define YYSTYPE char*
#endif

char idStr[1024];
char numStr[1024];

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

// IDENTIFIER
%token ID

// NUMBER
%token INTEGER

// SEMI
%token semi

// EXIT
%token EXIT


%left ADD MINUS
%left MUL DIV
%nonassoc UMINUS

%%

lines:	lines expr semi{ printf("%s\n", $2); }
	 |	lines EXIT semi{ exit(0); }
	 |	lines semi
	 |
     ;

expr:	expr ADD term{
		$$ = (char *)malloc(1024*sizeof(char));
		strcpy($$, $1);
		strcat($$, $3);
		strcat($$, "+");
	}
	|	expr MINUS term{
		$$ = (char *)malloc(1024*sizeof(char));
		strcpy($$, $1);
		strcat($$, $3);
		strcat($$, "-");
	}
	|	term{
		$$ = (char *)malloc(1024*sizeof(char));
		strcpy($$, $1);
	}

term:	term MUL factor{
		$$ = (char *)malloc(1024*sizeof(char));
		strcpy($$, $1);
		strcat($$, $3);
		strcat($$, "*");
	}
	|	term DIV factor{ 
		$$ = (char *)malloc(1024*sizeof(char));
		strcpy($$, $1);
		strcat($$, $3);
		strcat($$, "/");
	 }
	|	factor{
		$$ = (char *)malloc(1024*sizeof(char));
		strcpy($$, $1);
	}

factor:	INTEGER{ 
		$$ = (char *)malloc(1024*sizeof(char));
		strcpy($$, $1);
		strcat($$, " ");
 		}
	  | L_PAREN expr R_PAREN{ 
		$$ = (char *)malloc(1024*sizeof(char));
		strcpy($$, $2);
	   }
	  | ID{
		$$ = (char *)malloc(1024*sizeof(char));
		strcpy($$, $1);
		strcat($$, " "); 
	  }
	  | MINUS expr %prec UMINUS{ 
		$$ = (char *)malloc(1024*sizeof(char));
		strcpy($$, " -");
		strcat($$, $2);
		strcat($$, " "); 
	   }


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
			int ti = 0;
			while (isdigit(t)) {
				numStr[ti] = t;
				t = getchar();
				ti++;
			}
			numStr[ti] = '\0';
			yylval = numStr;
			ungetc(t, stdin);
			return INTEGER;
		}
		else if ((t >= 'a' && t <= 'z') || (t >= 'A' && t <= 'Z') || (t == '_'))
		{
			int ti = 0;
			while((t >= 'a' && t <= 'z') || (t >= 'A' && t <= 'Z') || (t == '_') || isdigit(t))
			{
				idStr[ti] = t;
				ti++;
				t = getchar();
			}
			idStr[ti] = '\0';
			yylval = idStr;
			ungetc(t, stdin);
			if(!strcmp(idStr, "exit"))
				return EXIT;
			return ID;
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