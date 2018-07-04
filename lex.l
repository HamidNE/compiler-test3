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
"to"		return(TO);
"of"		return(OF);
"for"		return(FOR);
"down"		return(DOWN);
"else"		return(ELSE);
"then"		return(THEN);
"case"		return(CASE);
"while"		return(WHILE);
"break"		return(BREAK);
"repeat"	return(REPEAT);
"switch"	return(SWITCH);
"continue"	return(CONTINUE);


"in"		return(IN);
"end"		return(END);
"read"		return(READ);
"true"		return(TRUE);
"false"		return(FALSE);
"write"		return(WRITE);
"return"	return(RETURN);
"program"	return(PROGRAM);


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
"bool"			return TYPE_BOL;
"char"			return TYPE_CHR;
"double"		return TYPE_DBL;
"string"  		return TYPE_STR;


"do"		return(DO);
"default"	return(DEFAULT);

[*+-/=%;~&|^(){}:]  {return yytext[0];}

"float"			return TYPE_FLT;
"const"   		return TYPE_CONST;
"symbol_table" 	return show_symbol_table;

[ \t\n]+        ;       /* ignore whitespace */

\-?{DIGIT}*"."{DIGIT}+      {	yylval.DBL = atof(yytext);
								return DOUBLING_NUM;}
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