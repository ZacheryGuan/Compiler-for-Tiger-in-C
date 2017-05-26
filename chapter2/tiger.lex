%{
#include <string.h>
#include "util.h"
#include "tokens.h"
#include "errormsg.h"

int charPos=1;

int yywrap(void)
{
 charPos=1;
 return 1;
}


void adjust(void)
{
 EM_tokPos=charPos;
 charPos+=yyleng;
}

void str(){

}

%}

%state INITIAL
%state STR
%state CONTINUESTR
%state COMMENT

%%
int isString=0;

<INITIAL>{
	"/*" 		{adjust(); BEGIN(COMMENT);}
	\"  		{adjust(); str(); isString = TRUE; BEGIN(STR);}
	" "			{adjust(); continue;}
	[ \t]*   	{adjust(); continue;}
	[\n\r]+   	{adjust(); EM_newline(); continue;}
	","  		{adjust(); return COMMA;}
	":"  		{adjust(); return COLON;}
	";"  		{adjust(); return SEMICOLON;}
	"("  		{adjust(); return LPAREN;}
	")"  		{adjust(); return RPAREN;}
	"["  		{adjust(); return LBRACK;}
	"]"  		{adjust(); return RBRACK;}
	"{"  		{adjust(); return LBRACE;}
	"}"  		{adjust(); return RBRACE;}
	"."  		{adjust(); return DOT;}
	"+"  		{adjust(); return PLUS;}
	"-"  		{adjust(); return MINUS;}
	"*"  		{adjust(); return TIMES;}
	"/"  		{adjust(); return DIVIDE;}
	"="  		{adjust(); return EQ;}
	"<>" 		{adjust(); return NEQ;}
	"<"  		{adjust(); return LT;}
	"<=" 		{adjust(); return LE;}
	">"  		{adjust(); return GT;}
	">=" 		{adjust(); return GE;}
	"&"  		{adjust(); return AND;}
	"|"  		{adjust(); return OR;}
	":=" 		{adjust(); return ASSIGN;}
	array   	{adjust(); return ARRAY;}
	if      	{adjust(); return IF;}
	then    	{adjust(); return THEN;}
	else    	{adjust(); return ELSE;}
	while   	{adjust(); return WHILE;}
	for     	{adjust(); return FOR;}
	to      	{adjust(); return TO;}
	do      	{adjust(); return DO;}
	let     	{adjust(); return LET;}
	in      	{adjust(); return IN;}
	end     	{adjust(); return END;}
	of      	{adjust(); return OF;}
	break   	{adjust(); return BREAK;}
	nil     	{adjust(); return NIL;}
	function	{adjust(); return FUNCTION;}
	var     	{adjust(); return VAR;}
	type    	{adjust(); return TYPE;}

	[a-zA-Z]+[a-zA-Z0-9_]*  {adjust(); yylval.sval = String(yytext); return ID;}
	[0-9]+   				{adjust(); yylval.ival=atoi(yytext); return INT;}
	.    					{adjust(); EM_error(EM_tokPos,"illegal token");}
	<<EOF>> 				{return 0;}
}

<STR>{
    \" 				{adjust(); yylval.sval = String(str); str_del(); BEGIN(INITIAL); if(isString==1) return STRING;}
    \\n  			{adjust(); str_append('\n');}
    \\t 			{adjust(); str_append('\t');}
    \\^[a-zA-Z] 	{adjust();}
    \\[0-9]{3}  	{adjust(); str_append(atoi(yytext+1));}
    \\\"    		{adjust(); str_append('\"');}
    \\\\    		{adjust(); str_append('\\');}
    \\[^ntf\"\\] 	{adjust(); flag = FALSE; EM_error(EM_tokPos, "String is not completed with '\\%c'", yytext[1]);}
    [\n\r]+			{adjust(); EM_newline(); str_append('\n');}
    . 				{adjust(); str_append(yytext[0]);}
    <<EOF>> 		{adjust(); EM_error(EM_tokPos,"String is not completed with EOF!"); str_del(); return 0;}
    \\ 				{adjust(); BEGIN(CONTINUESTR);}
}

<CONTINUESTR>{
    \\ 			{adjust(); BEGIN(STR);}
    [\n\r]+   	{adjust(); EM_newline();}
    .    		{adjust();} 
    <<EOF>> 	{adjust(); EM_error(EM_tokPos,"Continued string is not completed with EOF!"); return 0;}
}

<COMMENT>{
	"*/" 		{adjust(); BEGIN(INITIAL);}
    [\n\r]+   	{adjust(); EM_newline(); continue;}
    . 			{adjust();} 
    <<EOF>> 	{adjust(); EM_error(EM_tokPos,"Comment is not completed with EOF"); return 0;}
}

%%
