/**
 * @file compiler.l
 * @date March 3, 2018
 * @author Hamid Nasr
 * @brief lex file of a compiler for a C++ like language
 * @ref https://github.com/jengelsma/yacc-tutorial
 */
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "y.tab.h"
%}

DIGIT [0-9]
ALPHA [a-z]
ALPHA_CAPITAL [A-Z]
ALNUM [0-9a-zA-Z]

%option noyywrap

%%

"do"        return(DO);
"if"        return(IF);
"for"       return(FOR);
"else"      return(ELSE);
"case"      return(CASE);
"break"     return(BREAK);
"while"     return(WHILE);
"switch"    return(SWITCH);
"default"   return(DEFAULT);

[*+-/=%;~&|^(){}:]  {return yytext[0];}

"||"		return(OR);
"=="		return(EQ);
">"			return(GT);
"<"			return(LT);
"&&"		return(AND);
"!"			return(NOT);
">="		return(GTE);
"++"		return(INC);
"--"		return(DEC);
"<="		return(LTE);
"!="        return(NOTEQ);


"int"			return TYPE_INT;
"char"			return TYPE_CHR;
"float"			return TYPE_FLT;
"string"  		return TYPE_STR;
"const"   		return TYPE_CONST;
"exit"			return exit_command;
"symbol_table"  return show_symbol_table;

[ \t\n]+        ;       /* ignore whitespace */

\-?{DIGIT}*"."{DIGIT}+      {	yylval.FLT   = atof(yytext);    return FLOATING_NUM;}
\-?{DIGIT}+				 	{	yylval.INTGR = atoi(yytext);    return NUM;}
\'.\'						{ 	yylval.INTGR = yytext[1]-'a';   return(CHAR_VALUE); }
{ALPHA}						{	yylval.INTGR = *yytext-'a';     return(ID);}

\"[0-9a-zA-Z ]+\" 			{ 	yylval.STRNG = yytext; return(STRING_VALUE); }

[0-9]+(\.[0-9]+)?([eE][0-9]+)?  {yylval.f = atof(yytext); return NUM;}
[-+()*/]                        {return yytext[0];}
[ \t\f\v\n]                     {;}

"//".*                	    ;
"/*"(.|\n)*"*/"     		;

%%