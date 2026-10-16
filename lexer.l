%option noyywrap yylineno noinput nounput

%x COMMENT

%{
/*
 * lexer.l - Flex specification for the user-defined language
 * Compiler Design Lab - BCSE307P, VIT
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

/* Defined in parser.y. */
void report_error(int line, const char *message, const char *lexeme);

static int comment_line;

static char *copy_text(const char *s)
{
    char *p = malloc(strlen(s) + 1);
    if (!p) {
        perror("malloc");
        exit(EXIT_FAILURE);
    }
    strcpy(p, s);
    return p;
}

static void lex_error(const char *message)
{
    report_error(yylineno, message, yytext);
}

/* Allowed escapes: \n, \t, \r, \0, \\, \', and \". */
static int valid_escapes(const char *s)
{
    for (; *s; ++s) {
        if (*s == '\\') {
            ++s;
            if (*s == '\0' || strchr("ntr0\\'\"", *s) == NULL)
                return 0;
        }
    }
    return 1;
}

#define RET(T) do {                         \
    yylval.tok.text = copy_text(yytext);    \
    yylval.tok.line = yylineno;             \
    yylval.tok.end_line = yylineno;         \
    return (T);                             \
} while (0)
%}

D       [0-9]
L       [A-Za-z_]
ID      {L}({L}|{D})*
DEC     {D}+\.{D}+
STR     \"([^\"\\\n]|\\.)*\"
CHR     \'([^\'\\\n]|\\.)\'

%%

[ \t\r\n]+                         ;

 /* Comments are identified and returned to the parser. */
"//"[^\n]*                        { RET(COMMENT_TOK); }
"/*"                             { comment_line = yylineno; BEGIN(COMMENT); }
<COMMENT>"*/"                    {
                                      BEGIN(INITIAL);
                                      yylval.tok.text = copy_text("/* ... */");
                                      yylval.tok.line = comment_line;
                                      yylval.tok.end_line = yylineno;
                                      return ML_COMMENT_TOK;
                                  }
<COMMENT>\n                      ;
<COMMENT>.                       ;
<COMMENT><<EOF>>                 {
                                      report_error(comment_line,
                                          "unterminated multiline comment", "/*");
                                      BEGIN(INITIAL);
                                      return 0;
                                  }

 /* Reserved words must appear before the identifier rule. */
"num"|"dec"|"text"|"letter"|"flag" { RET(KEYWORD); }
"check"|"otherwise"|"repeat"         { RET(KEYWORD); }
"show"|"ask"|"task"|"give"          { RET(KEYWORD); }
"stop"|"skip"|"none"|"fixed"         { RET(KEYWORD); }
"yes"|"no"                            { RET(BOOL_LIT); }

 /* Numeric literals and numeric errors. */
{D}+(\.{D}*){2,}                 { lex_error("multiple decimal points in number"); }
{D}+(\.{D}*)?{L}({L}|{D})*      { lex_error("letters after digits in number"); }
{DEC}                            { RET(DEC_LIT); }
{D}+\.                          { lex_error("missing digits after decimal point"); }
{D}+                             {
                                      if (strlen(yytext) > 10 ||
                                          strtoll(yytext, NULL, 10) > 2147483647LL)
                                          lex_error("integer literal out of range");
                                      else
                                          RET(INT_LIT);
                                  }

 /* String and character literals. */
{STR}                            {
                                      if (valid_escapes(yytext))
                                          RET(STRING_LIT);
                                      else
                                          lex_error("invalid escape sequence");
                                  }
\"([^\"\\\n]|\\.)*             { lex_error("unterminated string literal"); }
\'\'                              { lex_error("empty character literal"); }
{CHR}                            {
                                      if (valid_escapes(yytext))
                                          RET(CHAR_LIT);
                                      else
                                          lex_error("invalid escape sequence");
                                  }
\'([^\'\\\n]|\\.)*\'              { lex_error("character literal too long"); }
\'([^\'\\\n]|\\.)*                { lex_error("unterminated character literal"); }

 /* Identifiers. */
{L}({L}|{D}){31,}                { lex_error("identifier longer than 31 characters"); }
{ID}                             { RET(IDENTIFIER); }

 /* Operators: longer forms must appear first. */
"++"|"--"                       { RET(INCDEC_OP); }
"+="|"-="|"*="|"/="|"%="        { RET(ASSIGN_OP); }
"=="|"!="|"<="|">="             { RET(REL_OP); }
"&&"|"||"                       { RET(LOGIC_OP); }
"<"|">"                         { RET(REL_OP); }
"!"                             { RET(LOGIC_OP); }
"="                             { RET(ASSIGN_OP); }
"+"|"-"|"*"|"/"|"%"             { RET(ARITH_OP); }

 /* Delimiters. */
"("|")"|"{"|"}"|"["|"]"|";"|"," { RET(DELIMITER); }

 /* Anything else. */
.                               { lex_error("illegal character"); }

%%

