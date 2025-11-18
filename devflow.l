%{
#include "devflow_types.h"
#include "devflow.tab.h"

/* Function prototypes */
void yyerror(const char *s);

extern int yylineno;
extern char *yytext;

%}

%option yylineno
%option noyywrap

/* Character classes */
DIGIT       [0-9]
LETTER      [a-zA-Z]
WHITESPACE  [ \t\r]
NEWLINE     \n
IDENTIFIER  {LETTER}({LETTER}|{DIGIT}|_)*
NUMBER      {DIGIT}+
STRING      \"([^"\\]|\\.)*\"

/* Comments */
COMMENT     #.*\n
MULTICOMMENT \/\*([^*]|\*+[^*/])*\*+\/

%%

"pipeline"          { return PIPELINE; }
"stage"             { return STAGE; }
"job"               { return JOB; }
"step"              { return STEP; }
"on"                { return ON; }
"service"           { return SERVICE; }
"image"             { return IMAGE; }
"port"              { return PORT; }
"env"               { return ENV; }
"artifact"          { return ARTIFACT; }
"matrix"            { return MATRIX; }
"if"                { return IF; }
"else"              { return ELSE; }
"for"               { return FOR; }
"in"                { return IN; }
"run"               { return RUN; }
"checkout"          { return CHECKOUT; }
"cache"             { return CACHE; }
"deploy"            { return DEPLOY; }
"notify"            { return NOTIFY; }
"push"              { return PUSH; }
"pull_request"      { return PULL_REQUEST; }
"schedule"          { return SCHEDULE; }
"manual"            { return MANUAL; }

"&&"                { return AND; }
"||"                { return OR; }
"=="                { return EQ; }
"!="                { return NE; }
"<="                { return LE; }
">="                { return GE; }
"<"                 { return LT; }
">"                 { return GT; }
"!"                 { return NOT; }
"="                 { return ASSIGN; }
"+"                 { return PLUS; }
"-"                 { return MINUS; }
"*"                 { return MULT; }
"/"                 { return DIV; }

"{"                 { return LBRACE; }
"}"                 { return RBRACE; }
"["                 { return LBRACKET; }
"]"                 { return RBRACKET; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }
","                 { return COMMA; }
";"                 { return SEMICOLON; }
":"                 { return COLON; }
"$"                 { return DOLLAR; }
"{{"                { return DOUBLE_LBRACE; }
"}}"                { return DOUBLE_RBRACE; }

{IDENTIFIER}        { 
                      yylval.string = strdup(yytext);
                      return IDENTIFIER; 
                    }

{NUMBER}            { 
                      yylval.number = atoi(yytext);
                      return NUMBER; 
                    }

{STRING}            { 
                      /* Remove quotes and unescape */
                      char *s = yytext;
                      int len = strlen(s);
                      char *result = malloc(len - 1);
                      int i, j = 0;
                      for (i = 1; i < len - 1; i++) {
                          if (s[i] == '\\' && i + 1 < len - 1) {
                              switch (s[i+1]) {
                                  case 'n': result[j++] = '\n'; i++; break;
                                  case 't': result[j++] = '\t'; i++; break;
                                  case 'r': result[j++] = '\r'; i++; break;
                                  case '\\': result[j++] = '\\'; i++; break;
                                  case '"': result[j++] = '"'; i++; break;
                                  default: result[j++] = s[i]; break;
                              }
                          } else {
                              result[j++] = s[i];
                          }
                      }
                      result[j] = '\0';
                      yylval.string = result;
                      return STRING_LITERAL; 
                    }

{COMMENT}           { /* Ignore comments */ }
{MULTICOMMENT}      { /* Ignore multi-line comments */ }
{WHITESPACE}+       { /* Ignore whitespace */ }
{NEWLINE}           { /* Ignore newlines */ }

.                   { 
                      fprintf(stderr, "Unexpected character: %s\n", yytext);
                      return yytext[0];
                    }

%%

