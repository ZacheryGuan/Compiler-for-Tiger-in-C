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

/*functions to deal with string def*/
#define STRBLOCKLENGTH 1024
static char *strPointer = NULL;
static char *tmpString=NULL;
static int remainSpace=STRBLOCKLENGTH;

/*initialize*/
void str(){
	tmpString=(char*)checked_malloc(STRBLOCKLENGTH);
	memset(tmpString, 0, STRBLOCKLENGTH);	//fill with 0
	strPointer = tmpString;
	//setting '\0' always needs a byte
	remainSpace -= 1; 
}

/*expand sapce for large string*/
void str_expand(char c)
{
	//add another block
	int currentLength = strlen(tmpString) + 1;
	int newLength = currentLength + STRBLOCKLENGTH;
	//allocate new larger sapce
	char *newString = (char *)checked_malloc(newLength);
	//fill with 0
	memset(newString, 0, newLength);
	//add balance
	remainSpace += STRBLOCKLENGTH;
	//move old string content
	strcpy(newString, tmpString);
	//free old string's space
	free(tmpString);
	//move old string 
	tmpString = newString;
	//move string pointer to new string
	strPointer = newString + currentLength - 1;
	//append the character
	*strPointer = c;
	strPointer++;
}

/*append a character to the string*/
void str_append(char c)
{
	if (remainSpace > 0)
	{
		*strPointer = c;
		strPointer += 1;
	}
	else	//no enough space
	{
		str_expand(c);
	}
	remainSpace -= 1;
}

%
}

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

	/*String(char *s) is defined in util.h, used to allocate memory to given string s, and then return it.*/
	[a-zA-Z]+[a-zA-Z0-9_]*  {adjust(); yylval.sval = String(yytext); return ID;}
	
	[0-9]+   				{adjust(); yylval.ival=atoi(yytext); return INT;}
	.    					{adjust(); EM_error(EM_tokPos,"illegal token");}
	<<EOF>> 				{return 0;}
}

<STR>{
    \" 				{adjust(); yylval.sval = String(str); str_del(); BEGIN(INITIAL); if(isString==1) return STRING;}
    \\n  			{adjust(); str_append('\n');}
    \\t 			{adjust(); str_append('\t');}
    \\[0-9]{3}  	{adjust(); str_append(atoi(yytext+1));}
    \\\"    		{adjust(); str_append('\"');}
    \\\\    		{adjust(); str_append('\\');}
	
	/*error escapes*/
    \\[^ntf\"\\] 	{adjust(); flag = FALSE; EM_error(EM_tokPos, "String has  on '\\%c'", yytext[1]);}
    
	/*omit newlines*/
	[\n\r]+			{adjust(); EM_newline();}
	
    . 				{adjust(); str_append(yytext[0]);}
    <<EOF>> 		{adjust(); EM_error(EM_tokPos,"String is not completed on EOF!"); str_del(); return 0;} 
}

/*
<CONTINUESTR>{
    \\ 			{adjust(); BEGIN(STR);}
    [\n\r]+   	{adjust(); EM_newline();}
    .    		{adjust();} 
    <<EOF>> 	{adjust(); EM_error(EM_tokPos,"Continued string is not completed on EOF!"); return 0;}
}
*/

<COMMENT>{
	"*/" 		{adjust(); BEGIN(INITIAL);}
    [\n\r]+   	{adjust(); EM_newline(); continue;}
    . 			{adjust();} 
    <<EOF>> 	{adjust(); EM_error(EM_tokPos,"Comment is not completed on EOF"); return 0;}
}

%%
