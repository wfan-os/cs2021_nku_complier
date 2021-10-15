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
#include <unordered_map>
using namespace std;

struct ident{
	char* identifier;
	double value;
};

FILE* yyin;
char idStr[1024];
unordered_map<string, double> symtab;

int yylex();
extern int yyparse();
void yyerror(const char* s);
int isdigit(int t);
int check_ident(char*);
%}

//利用这个定义属性栈
%union{
	double num;
	char*	id;
}

//利用这个定义非终结符的属性
%type <num> lines
%type <num> expr
%type <num> term
%type <num> factor

// OPERAND
%token ADD
%token MINUS
%token MUL
%token DIV
%token L_PAREN
%token R_PAREN
%token EQUAL

// IDENTIFIER
%token <id> ID

// NUMBER
%token <num> NUMBER

// SEMI
%token semi

// EXIT
%token EXIT


%left ADD MINUS
%left MUL DIV
%right EQUAL
%nonassoc UMINUS

%%

lines:	lines expr semi{ printf("%f\n", $2); }
	 |	lines EXIT semi{ exit(0); }
	 |	lines EXIT EQUAL expr semi{ yyerror("cannot declare exit!\n"); }
	 |	lines semi
	 |  ID{
		if(check_ident($1)) yyerror("this identifier has been declared!\n");
		string tmp($1);
		symtab[tmp] = 0.0;
	}
	 |
     ;

expr:	expr ADD term{$$ = $1 + $3;}
	|	expr MINUS term{$$ = $1 - $3;}
	//赋值表达式的值是等式右边表达式的值
	|   ID EQUAL expr{
		 $$ = $3;

		 //检查这个symbol是否已经被声明
		if(check_ident($1)) yyerror("this identifier has been declared!\n");
		 
		 //我们需要注册这个symbol
		 string tmp($1);
		 symtab[tmp] = $3;
	}
	|	term{$$ = $1;}

term:	term MUL factor{$$ = $1 * $3;}
	|	term DIV factor{
		if($3 == 0.0)
			yyerror("divided by zero.\n");
		else
			$$ = $1 / $3;
	}
	|	factor{$$ = $1;}

factor:	NUMBER{$$ = $1;}
	  | ID{
		//在factor里用说明使用的是已经声明的symbol
		if(!check_ident($1)) yyerror("we cannot use an identifier that has not been declared!\n");

		string tmp($1);
		$$ = symtab[tmp];
	  }
	  | L_PAREN expr R_PAREN{$$ = $2;}
	  | MINUS expr %prec UMINUS{$$ = -$2;}


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
			yylval.num = 0.0;
			while(isdigit(t)) {
				yylval.num = yylval.num * 10 + t - '0';
				t = getchar();
			}
			ungetc(t, stdin);
			return NUMBER;
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
			ungetc(t, stdin);
			if(!strcmp(idStr, "exit"))
				return EXIT;

			yylval.id = idStr;

			return ID;
		}
		else if (t == '+' || t == '-' || t == '*' || t == '/' || t == '(' || t == ')' || t == '=')
		{
			switch (t)
			{
			case '+': return ADD;
			case '-': return MINUS;
			case '*': return MUL;
			case '/': return DIV;
			case '(': return L_PAREN;
			case ')': return R_PAREN;
			case '=': return EQUAL;
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

int check_ident(char* s)
{
	string tmp(s);
	if(symtab.find(tmp) == symtab.end()) return 0;
	else return 1;
}