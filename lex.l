/**
 * @file lex.l
 * @date March 3, 2017
 * @author Abdallah sobehy
 * @author Mostafa Fateen
 * @author Ramy Alfred
 * @author Yousra Samir
 * @brief lex file of a compiler for a C++ like language
 * @ref https://github.com/jengelsma/yacc-tutorial
 */
%{
#include "y.tab.h"
%}

DIGIT [0-9]
ALPHA [a-z]
ALPHA_CAPITAL [A-Z]
ALNUM [0-9a-zA-Z]

%%
"if"		return(IF);
"do"		return(DO);
"for"		return(FOR);
"else"		return(ELSE);
"case"		return(CASE);
"while"		return(WHILE);
"break"		return(BREAK);
"default"	return(DEFAULT);
"switch"	return(SWITCH);

[*+-/=%;~&|^(){}:]  {return yytext[0];}

"&&"		return(AND);
"||"		return(OR);
"!"			return(NOT);
"=="		return(EQ);
"!="		return(NOTEQ);
">="		return(GTE);
"<="		return(LTE);
">"			return(GT);
"<"			return(LT);
"++"		return(INC);
"--"		return(DEC);


"int"			return TYPE_INT;
"float"			return TYPE_FLT;
"double"		return TYPE_DBL;
"string"  		return TYPE_STR;
"char"			return TYPE_CHR;
"const"   		return TYPE_CONST;
"exit"			return exit_command;
"symbol_table" 	return show_symbol_table;

[ \t\n]+        ;       /* ignore whitespace */

\-?{DIGIT}*"."{DIGIT}+      {	yylval.FLT = atof(yytext);
								return FLOATING_NUM;}
\-?{DIGIT}+				 	{	yylval.INTGR = atoi(yytext);
								return NUM;}
\'.\'						{ 	yylval.INTGR = yytext[1]-'a';
								return(CHAR_VALUE); }
{ALPHA}						{	yylval.INTGR = *yytext-'a';
								return(ID);}

\"[0-9a-zA-Z ]+\" 			{ 	yylval.STRNG = yytext;
								return(STRING_VALUE); }

"//".*                		;
"/*"(.|\n)*"*/"     		;

%%
