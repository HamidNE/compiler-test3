%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void reset();
void declare_initalize(int id, int type_);
void declare_only(int id, int type_);
void assign_only(int id);
void declare_const(int id, int type);
void calc_lowp(char*);
void calc_highp(char*);
void cond_lowp(char*);
void cond_highp(char*);
void switch_test ();
void open_brace();
void close_brace ();
void switch_expr();
void print_symbol_table();
char * get_type(int type);

int new_scope();
int exit_scope();
int opened_scopes = 0;
int nesting_arr[100];
int nesting_last_index = -1;

int exitFlag=0;
int next_reg = 1; // The register number to be written in the next instruction
int next_cond_reg = 11;
int first_for = 1;
int is_first = 1; // check if is the first operation for consistent register counts
int is_first_cond = 1;
int after_hp = 0; // a high priority operation is done
int after_hp_cond = 0; // a high priority operation is done
int declared[26];
int is_constant[26];// for each variable store 1 if it constant
int scope[26]; // a scope number for each variable
int cscope = 0;
int next_case = 0;
int current_scope = 0;
int variable_initialized[26];
int type[26];
%}
// definitions
%union {
	char CHR;
	int INTGR;
	double DBL;
	char * STRNG;
}
%start statement
%token IF ELSE ELSEIF FOR WHILE SWITCH CASE DO BREAK DEFAULT
%token TYPE_INT TYPE_DBL TYPE_STR TYPE_CHR TYPE_CONST show_symbol_table
%token <INTGR> ID
%token <INTGR> NUM
%token <DBL> DOUBLING_NUM
%token <CHR> CHAR_VALUE
%token <STRNG> STRING_VALUE
%type <INTGR> math_expr
%type <INTGR> high_priority_expr
%type <INTGR> math_element
%left '~' '^' '&' '|'
%left '+' '-'
%left '*' '/'
%left AND OR NOT EQ NOTEQ GTE LTE GT LT INC DEC
/*Other type defs depend on non-terminal nodes that you are going to make*/
//TODO error handling when assigning float for char for example (conflicting types)
// Production rules
%%

statement	: variable_declaration_statement ';' {reset();}
			| assign_statement ';' {reset();}
			| constant_declaration_statement ';' {reset();}
			| conditional_statement {reset();}
			| math_expr ';' {reset();}
			| show_symbol_table ';' {print_symbol_table();}
			| statement variable_declaration_statement ';' {reset();}
			| statement assign_statement ';' {reset();}
			| statement constant_declaration_statement ';' {reset();}
			| statement conditional_statement {reset();}
			| statement math_expr ';' {reset();}
			| open_brace statement close_brace statement {;}
			| statement open_brace statement close_brace {;}
			| statement show_symbol_table ';' {print_symbol_table();}
			;

conditional_statement :
			if_statement {;}
			|while_loop {;}
			|for_loop {;}
			|do_while {;}
			|switch_statement{;}
			;
switch_statement:
			SWITCH '(' math_expr ')' {switch_expr();new_scope();} switch_body
			;
switch_body:
			open_brace cases {int tmp = exit_scope(); printf("label%d%c:\nlabel%d:\n",tmp,'a'-1+next_case,tmp);} close_brace
			|open_brace cases default {int tmp = exit_scope();printf("label%d%c:\nlabel%d:\n",tmp,'a'-1+next_case,tmp);} close_brace
cases: CASE {if(next_case>0)
								{printf("label%d%c:\n",nesting_arr[nesting_last_index],'a'-1+next_case);}
							next_case++;}
							math_expr  {switch_test();}':' statement case_break{;}
			|cases cases {;}
			;
case_break: // CAN BE EMPTY
			| BREAK ';' {printf("JMP label%d\n",nesting_arr[nesting_last_index]);}
default: DEFAULT ':' statement {;}

do_while: DO '{' {printf("label:%d\n",new_scope()); open_brace();} statement '}' {close_brace();} WHILE '('condition')' {printf("JT R10,label%d\n",exit_scope());}
for_loop:
			FOR '(' assign_statement for_sep1 condition for_sep2 assign_statement ')'for_ob statement for_cb {;}
for_sep1 : ';' {printf("MOV RF,0\n");
								printf("label%d:\n",new_scope());reset();}
for_sep2 : ';' {printf("JF R10, label%da\n",nesting_arr[nesting_last_index]);
								printf("CMPE RF,0\n");
								printf("JT R10, label%db\n", nesting_arr[nesting_last_index]);}
for_ob : '{' {printf("label%db:\n",nesting_arr[nesting_last_index]);
							printf("MOV RF,1\n");
							open_brace();
							reset();}
for_cb : '}' {printf("JMP label%d\n",nesting_arr[nesting_last_index]);
							printf("label%da:\n",exit_scope());
							close_brace();
						}

while_loop :
			WHILE {printf("label%d:\n",new_scope());} '(' condition ')' while_open_brace statement while_closed_brace {;}
			;
while_open_brace : '{' {printf("JF R10, label%da\n",nesting_arr[nesting_last_index]);reset();open_brace();}
while_closed_brace : '}' {printf("JMP label%d\n",nesting_arr[nesting_last_index]);
													printf("label%da:\n",exit_scope());reset();close_brace();}
if_statement :
			IF '(' condition ')'if_open_brace statement if_closed_brace {;}
			| IF '(' condition ')'if_open_brace statement if_closed_brace ELSE_FINAL statement if_closed_brace {;}
			| IF '(' condition ')'if_open_brace statement if_closed_brace ELSE if_statement {;}
			;
ELSE_FINAL : ELSE '{' {printf("JT R10, label%d\n",new_scope());open_brace();reset();}
if_open_brace : '{' {printf("JF R10, label%d\n",new_scope());open_brace();reset();}
if_closed_brace : '}' {printf("label%d:\n",exit_scope());close_brace();}
;

condition :
			'(' condition ')' {;}
		| condition OR high_p_condition {cond_lowp("OR");}
			| condition AND high_p_condition {cond_lowp("AND");}
			| NOT condition {printf("NOT R10\n");}
			| high_p_condition {;}
			;

high_p_condition :
			math_expr EQ math_expr {cond_highp("CMPE");}
			| math_expr NOTEQ math_expr {cond_highp("CMPNE");}
			| math_expr GTE math_expr {cond_highp("CMPGE");}
			| math_expr GT math_expr {cond_highp("CMPG");}
			| math_expr LTE math_expr {cond_highp("CMPLE");}
			| math_expr LT math_expr {cond_highp("CMPL");}
			;


math_expr	:
 			'('math_expr')'											{$$=$2;}
			|math_expr '+' high_priority_expr    { calc_lowp("ADD"); }
			| math_expr '-' high_priority_expr    		{ calc_lowp("SUB"); }
		  | '~' math_expr 													{
																												$$ = ~$2;
																												if(after_hp)
																													printf("NOT R4\n");
																												else
																													printf("NOT R%d\n",next_reg-1);
																											}
			| math_expr '|' high_priority_expr				{ calc_lowp("OR"); }
			| math_expr '&' high_priority_expr				{ calc_lowp("AND"); }
			| math_expr '^' high_priority_expr				{ calc_lowp("XOR"); }
			|high_priority_expr												{	$$=$1;}
			;

high_priority_expr:		high_priority_expr '*' math_element		{ calc_highp("MUL"); }
						|high_priority_expr '/' math_element						{ calc_highp("DIV"); }
						|math_element																		{ $$=$1; }
						;

//TODO: ID type check
math_element:	NUM			  				{$$=$1;
																printf("MOV R%d, %d\n",next_reg++ ,$1);}
				| DOUBLING_NUM					{$$=$1;
																printf("MOV R%d, %f\n",next_reg++,$1);}
				| ID 										{$$=$1;
																	if(declared[$1] == 1){
																		if(variable_initialized[$1] == 1){
																			$$=$1;
																			printf("MOV R%d, %c\n",next_reg++,$1+'a');
																		} else {
																			printf("Error: %c is not set\n", $1+'a');
																		}
																	} else {
																		printf("Error: %c is not declared\n", $1+'a');
																	}
																}
				| '('math_expr')'				{$$=$2;}
				;
assign_statement:
//TODO assign statement for char !
	ID '=' math_expr	{	assign_only($1);}

variable_declaration_statement:
	TYPE_INT ID 	{ 	declare_only($2,1);}
	|TYPE_DBL ID	{ 	declare_only($2,2);}
	|TYPE_CHR ID	{ 	declare_only($2,3);}
	|TYPE_INT ID '=' math_expr	{ 	declare_initalize($2,1);}
	|TYPE_DBL ID '=' math_expr	{ 	declare_initalize($2,2);}
	|TYPE_CHR ID '=' CHAR_VALUE	{if(declared[$2] == 0) {
																	declared[$2] = 1;
																	type[$2] = 3;
																	scope[$2] = cscope;
																	is_constant[$2] = 0;
																	variable_initialized[$2] = 1;
																	printf("MOV %c,'%c'\n",$2+'a',$4+'a');

																} else {
																	printf("Syntax Error : %c is an already declared variable\n", $2 + 'a');
																}
															}
		|TYPE_CHR ID '=' DOUBLING_NUM { printf("Syntax Error : char can not be assigned a floating number\n");}
	;

open_brace: '{' { open_brace(); } ;
close_brace: '}' { close_brace(); };

//TODO edit to match normal declaration registers
constant_declaration_statement:
	TYPE_CONST TYPE_INT ID '=' math_expr			{ 	declare_const($3,1);
																						}

	| TYPE_CONST TYPE_DBL ID '=' math_expr		{ 	declare_const($3,2);
																						}
	| TYPE_CONST TYPE_CHR ID '=' CHAR_VALUE			{
																								if(declared[$3] == 0) {
																									declared[$3] = 1;
																									type[$3] = 3;
																									scope[$3] = cscope;
																									is_constant[$3] = 1;
																									variable_initialized[$3] = 1;
																									printf("MOV %c,'%c'\n",$3+'a',$5+'a');

																								} else {
																									printf("Syntax Error : %c is an already declared variable\n", $3 + 'a');
																								}
																							}
;


%%
//Normal C-code
int main(void)
{
	return yyparse();
}
void print_symbol_table()
{
	printf("Symbol Table:\n=============\n");
	printf("Symbol\t\tType\t\tInitialized\t\tConstant\t\tScope\t\t\n");
	for (int i = 0 ; i < 26 ; i ++){
		if(declared[i] == 1)
		{
			printf("%c\t\t%s\t\t",i+'a',get_type(type[i]));
			if(variable_initialized[i] == 1)
				printf("true\t\t\t");
			else printf("false\t\t\t");
			if(is_constant[i] == 1)
				printf("true\t\t\t");
			else printf("false\t\t\t");

			printf("%d\n", scope[i]);
		}
	}
}
char * get_type(int type){
	if(type == 1)
		return "int";
	if(type == 2)
		return "float";
	if(type == 3)
		return "char";
}
void calc_lowp (char * op) {
	/*$$ = $1 + $3;*/
	if(is_first){
		printf("%s R0,R%d,R%d\n", op, --next_reg ,--next_reg );
		is_first=0;
	}
	else{
		if(after_hp){
			printf("%s R0,R%d,R4\n",op, --next_reg);
			after_hp = 0;
		}
		else{
			printf("%s R0,R%d,R0\n",op, --next_reg);
		}
		}
}

void calc_highp (char * op) {
	if(!after_hp){
		printf("%s R4,R%d,R%d\n", op, --next_reg ,--next_reg );
		after_hp = 1;
		is_first = 0;
	}
	else{
		printf("%s R4,R%d,R4\n", op, --next_reg );
	}
}

void cond_lowp (char * op) {
printf("%s R10,R10,R14\n",op);
}

void cond_highp (char * op) {
	if(!after_hp_cond){
		printf("%s R10,R%d,R%d\n", op, --next_reg ,--next_reg );
		after_hp_cond = 1;
		is_first_cond = 0;
	}
	else{
		printf("%s R14,R%d,R%d\n", op, --next_reg, --next_reg );
	}
}
void switch_test () {
	if(is_first){
		printf("CMPE R10,RS,R%d\n", --next_reg );
		is_first=0;
	}
	else{
		if(after_hp){
			printf("CMPE R10,RS,R4\n", --next_reg);
		}
		else{
			printf("CMPE R10,RS,R0\n", --next_reg);
		}
		}
		printf("JF R10,label%d%c\n",nesting_arr[nesting_last_index],'a'-1+next_case);
		reset();
}
void declare_only(int id,int type_)
{
	if(declared[id] == 0) {
	declared[id] = 1;
	type[id] = type_;
	scope[id] = cscope;
	variable_initialized[id] = 0;
	is_constant[id] = 0;
	} else {
		printf("Syntax Error : %c is an already declared variable\n", id + 'a');
	}
}
void assign_only(int id){
	if(declared[id] == 1) {
		if (is_constant[id] == 0) {
			variable_initialized[id] = 1;
			if(is_first){
				printf("MOV %c,R%d\n",id+'a',--next_reg);
				}else{
					if(after_hp)
						printf("MOV %c,R4\n",id+'a');
					else
						printf("MOV %c,R0\n",id+'a');
				}
			} else {
				printf("Syntax Error : %c is a constant\n", id + 'a');
			}
	} else {
		printf("Syntax Error : %c is not declared\n", id + 'a');
	}
}

void switch_expr(){
	if(is_first){
		printf("MOV RS,R%d\n",--next_reg);
		}else{
			if(after_hp)
				printf("MOV RS,R4\n");
			else
				printf("MOV RS,R0\n");
		}
	}

void declare_const(int id, int _type)
{
	if(declared[id] == 0) {
			declared[id] = 1;
			type[id] = _type;
			scope[id] = cscope;
			variable_initialized[id] = 1;
			is_constant[id] = 1;
			if(is_first){
				printf("MOV %c,R%d\n",id+'a',--next_reg);
		}else{
			if(after_hp)
				printf("MOV %c,R4\n",id+'a');
			else
				printf("MOV %c,R0\n",id+'a');
			}
	} else {
		printf("Syntax Error : %c is an already declared variable\n", id + 'a');
	}
}
void declare_initalize(int id, int _type){
	if(declared[id] == 0) {
		declared[id] = 1;
		type[id] = _type;
		scope[id] = cscope;
		variable_initialized[id] = 1;
		is_constant[id] = 0;
		if(is_first){
			printf("MOV %c,R%d\n",id+'a',--next_reg);
		}else{
			if(after_hp)
				printf("MOV %c,R4\n",id+'a');
			else
				printf("MOV %c,R0\n",id+'a');
			}
	} else {
		printf("Syntax Error : %c is an already declared variable\n", id + 'a');
	}
}
void reset()
{
	next_reg = 1;
	is_first = 1;
	after_hp = 0;
	is_first_cond = 1;
	after_hp_cond = 0;
	printf("\n");
}
int yyerror(char* s)
{
  fprintf(stderr, "%s\n",s);
  return 1;
}
int yywrap()
{
  return(1);
}

void open_brace() {
	cscope++;
}

void close_brace () {
	for (int i = 0; i < 26; i++) {
			if (scope[i] == cscope ) {
				scope[i] = -1;
				declared[i] = 0;
			}
	}
	cscope--;
}


int new_scope()
{
	opened_scopes ++;
	nesting_last_index ++;
	nesting_arr[nesting_last_index] = opened_scopes;
	return opened_scopes;
}
int exit_scope()
{
	int tmp = nesting_arr[nesting_last_index];
	nesting_last_index --;
	return tmp;
}
