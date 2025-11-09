%option noyywrap

%{
#include<bits/stdc++.h>
using namespace std;

ofstream yyoutlog;

string loglist;
int line = 1;   // Line counter

%}

/* ------------ Regular Definitions ------------ */

ws          [ \t\v\r]+
newline     \n

letter      [A-Za-z_]
digit       [0-9]

/* Identifiers: letter or _, followed by letters/digits/_ */
id          {letter}({letter}|{digit})*

/* Integer literal */
integers    {digit}+

/* Floating literal:
   1) d+ . d* (opt exp)
   2) . d+ (opt exp)
   3) d+ exp
*/
exp_part    ([eE][+-]?{digit}+)
floats      ( {digit}+"."{digit}*({exp_part})? | \
              "."{digit}+({exp_part})?         | \
              {digit}+{exp_part} )

%%

/* ----------- Ignore whitespace ----------- */
{ws}                { /* ignore */ }

/* ----------- Track newlines ----------- */
{newline}           { line++; }

/* ----------- KEYWORDS (must be above id) ----------- */

"if"                { loglist="Line no "+to_string(line)+": Token <IF> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return IF; }
"else"              { loglist="Line no "+to_string(line)+": Token <ELSE> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return ELSE; }
"for"               { loglist="Line no "+to_string(line)+": Token <FOR> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return FOR; }
"while"             { loglist="Line no "+to_string(line)+": Token <WHILE> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return WHILE; }
"do"                { loglist="Line no "+to_string(line)+": Token <DO> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return DO; }
"break"             { loglist="Line no "+to_string(line)+": Token <BREAK> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return BREAK; }
"switch"   { loglist="Line no "+to_string(line)+": Token <SWITCH> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return SWITCH; }
"case"     { loglist="Line no "+to_string(line)+": Token <CASE> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return CASE; }
"default"  { loglist="Line no "+to_string(line)+": Token <DEFAULT> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return DEFAULT; }

"int"               { loglist="Line no "+to_string(line)+": Token <INT> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return INT; }
"char"              { loglist="Line no "+to_string(line)+": Token <CHAR> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return CHAR; }
"float"             { loglist="Line no "+to_string(line)+": Token <FLOAT> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return FLOAT; }
"double"            { loglist="Line no "+to_string(line)+": Token <DOUBLE> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return DOUBLE; }
"void"              { loglist="Line no "+to_string(line)+": Token <VOID> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return VOID; }
"return"            { loglist="Line no "+to_string(line)+": Token <RETURN> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return RETURN; }
"continue"          { loglist="Line no "+to_string(line)+": Token <CONTINUE> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return CONTINUE; }
"goto"              { loglist="Line no "+to_string(line)+": Token <GOTO> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return GOTO; }
"printf"            { loglist="Line no "+to_string(line)+": Token <PRINTF> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return PRINTF; }


/* ----------- Identifiers ----------- */
{id}                {
                        loglist="Line no "+to_string(line)+": Token <ID> Lexeme "+yytext+"\n\n";
                        yyoutlog<<loglist;
                        return ID;
                    }

/* ----------- Integer ----------- */
{integers}          {
                        loglist="Line no "+to_string(line)+": Token <CONST_INT> Lexeme "+yytext+"\n\n";
                        yyoutlog<<loglist;
                        return CONST_INT;
                    }

/* ----------- Float ----------- */
{floats}            {
                        loglist="Line no "+to_string(line)+": Token <CONST_FLOAT> Lexeme "+yytext+"\n\n";
                        yyoutlog<<loglist;
                        return CONST_FLOAT;
                    }

/* ----------- Operators/ Punctuators ----------- */

"++" | "--"         { loglist="Line no "+to_string(line)+": Token <INCOP> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return INCOP; }
"==" | "<=" | ">=" | "!=" | "<" | ">"   
                    { loglist="Line no "+to_string(line)+": Token <RELOP> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return RELOP; }
"&&" | "||"         { loglist="Line no "+to_string(line)+": Token <LOGICOP> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return LOGICOP; }

"+" | "-"           { loglist="Line no "+to_string(line)+": Token <ADDOP> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return ADDOP; }
"*" | "/" | "%"     { loglist="Line no "+to_string(line)+": Token <MULOP> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return MULOP; }

"="                 { loglist="Line no "+to_string(line)+": Token <ASSIGNOP> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return ASSIGNOP; }
"!"                 { loglist="Line no "+to_string(line)+": Token <NOT> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return NOT; }

"("                 { loglist="Line no "+to_string(line)+": Token <LPAREN> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return LPAREN; }
")"                 { loglist="Line no "+to_string(line)+": Token <RPAREN> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return RPAREN; }
"{"                 { loglist="Line no "+to_string(line)+": Token <LCURL> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return LCURL; }
"}"                 { loglist="Line no "+to_string(line)+": Token <RCURL> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return RCURL; }
"["                 { loglist="Line no "+to_string(line)+": Token <LTHIRD> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return LTHIRD; }
"]"                 { loglist="Line no "+to_string(line)+": Token <RTHIRD> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return RTHIRD; }
","                 { loglist="Line no "+to_string(line)+": Token <COMMA> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return COMMA; }
":"                 { loglist="Line no "+to_string(line)+": Token <COLON> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return COLON; }
";"                 { loglist="Line no "+to_string(line)+": Token <SEMICOLON> Lexeme "+yytext+"\n\n"; yyoutlog<<loglist; return SEMICOLON; }

/* ----------- Unknown Character ----------- */
.                   {
                        loglist="Line no "+to_string(line)+": Unknown token "+string(yytext)+"\n\n";
                        yyoutlog<<loglist;
                    }

%%

int main(int argc, char *argv[])
{
    if(argc != 2) {
        cout<<"Please input file name"<<endl;
        return 0;
    }

    yyin = fopen(argv[1], "r");

    yyoutlog.open("log.txt", ios::trunc);

    if(yyin == NULL) {
        cout<<"File does not exist"<<endl;
        return 0;
    }

    yylex();

    yyoutlog.close();
    fclose(yyin);

    return 0;
}
