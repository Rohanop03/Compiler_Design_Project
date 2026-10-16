%{
/*
 * parser.y - Bison token-reporting driver for the scanner
 * Compiler Design Lab - BCSE307P, VIT
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *message);
extern FILE *yyin;
extern int yylineno;

enum {
    C_KEYWORD,
    C_IDENTIFIER,
    C_INTEGER,
    C_DECIMAL,
    C_STRING,
    C_CHARACTER,
    C_BOOLEAN,
    C_ARITH,
    C_REL,
    C_LOGIC,
    C_ASSIGN,
    C_INCDEC,
    C_DELIMITER,
    C_COMMENT,
    N_CAT
};

static const char *cat_name[N_CAT] = {
    "KEYWORD", "IDENTIFIER", "INTEGER", "DECIMAL", "STRING", "CHARACTER",
    "BOOLEAN", "ARITHMETIC OPERATOR", "RELATIONAL OPERATOR",
    "LOGICAL OPERATOR", "ASSIGNMENT OPERATOR", "INC/DEC OPERATOR",
    "DELIMITER", "COMMENT"
};

static int cat_count[N_CAT];
static int token_count;
static int error_count;

#define MAX_SYMBOLS 200
static struct {
    char name[32];
    int first_line;
    int uses;
} symtab[MAX_SYMBOLS];
static int n_symbols;

static void add_symbol(const char *name, int line)
{
    int i;
    for (i = 0; i < n_symbols; ++i) {
        if (strcmp(symtab[i].name, name) == 0) {
            ++symtab[i].uses;
            return;
        }
    }

    if (n_symbols < MAX_SYMBOLS) {
        strcpy(symtab[n_symbols].name, name);
        symtab[n_symbols].first_line = line;
        symtab[n_symbols].uses = 1;
        ++n_symbols;
    }
}

#define MAX_ERRORS 100
static struct {
    int line;
    char msg[64];
    char lexeme[32];
} errs[MAX_ERRORS];

static void shorten(char *out, size_t out_size, const char *text)
{
    if (strlen(text) > 22)
        snprintf(out, out_size, "%.19s...", text);
    else
        snprintf(out, out_size, "%s", text);
}

void report_error(int line, const char *message, const char *lexeme)
{
    char shown[23];
    shorten(shown, sizeof shown, lexeme);
    printf("%4d   %-22s ** LEXICAL ERROR: %s\n", line, shown, message);

    if (error_count < MAX_ERRORS) {
        errs[error_count].line = line;
        snprintf(errs[error_count].msg, sizeof errs[error_count].msg,
                 "%s", message);
        snprintf(errs[error_count].lexeme, sizeof errs[error_count].lexeme,
                 "%s", lexeme);
    }
    ++error_count;
}

static void emit(int cat, char *text, int line)
{
    char shown[23];
    shorten(shown, sizeof shown, text);
    printf("%4d   %-22s %s\n", line, shown, cat_name[cat]);
    ++cat_count[cat];
    if (cat != C_COMMENT)
        ++token_count;
    free(text);
}
%}

%define parse.error verbose

%union {
    struct {
        char *text;
        int line;
        int end_line;
    } tok;
}

%token <tok> KEYWORD IDENTIFIER INT_LIT DEC_LIT STRING_LIT CHAR_LIT BOOL_LIT
%token <tok> ARITH_OP REL_OP LOGIC_OP ASSIGN_OP INCDEC_OP DELIMITER
%token <tok> COMMENT_TOK ML_COMMENT_TOK

%%

program
    : %empty
    | program token
    ;

token
    : KEYWORD        { emit(C_KEYWORD, $1.text, $1.line); }
    | IDENTIFIER     {
                         add_symbol($1.text, $1.line);
                         emit(C_IDENTIFIER, $1.text, $1.line);
                     }
    | INT_LIT        { emit(C_INTEGER, $1.text, $1.line); }
    | DEC_LIT        { emit(C_DECIMAL, $1.text, $1.line); }
    | STRING_LIT     { emit(C_STRING, $1.text, $1.line); }
    | CHAR_LIT       { emit(C_CHARACTER, $1.text, $1.line); }
    | BOOL_LIT       { emit(C_BOOLEAN, $1.text, $1.line); }
    | ARITH_OP       { emit(C_ARITH, $1.text, $1.line); }
    | REL_OP         { emit(C_REL, $1.text, $1.line); }
    | LOGIC_OP       { emit(C_LOGIC, $1.text, $1.line); }
    | ASSIGN_OP      { emit(C_ASSIGN, $1.text, $1.line); }
    | INCDEC_OP      { emit(C_INCDEC, $1.text, $1.line); }
    | DELIMITER      { emit(C_DELIMITER, $1.text, $1.line); }
    | COMMENT_TOK    { emit(C_COMMENT, $1.text, $1.line); }
    | ML_COMMENT_TOK {
                         printf("%4d   %-22s COMMENT (multiline, lines %d-%d)\n",
                                $1.line, $1.text, $1.line, $1.end_line);
                         ++cat_count[C_COMMENT];
                         free($1.text);
                     }
    ;

%%

void yyerror(const char *message)
{
    fprintf(stderr, "Line %d: token driver error: %s\n", yylineno, message);
}

static void print_summary(void)
{
    int i;
    printf("\n================ TOKEN SUMMARY ================\n");
    for (i = 0; i < N_CAT; ++i) {
        if (cat_count[i])
            printf("%-22s : %d\n", cat_name[i], cat_count[i]);
    }

    printf("\n================ SYMBOL TABLE =================\n");
    printf("%-4s %-20s %-11s %s\n", "No.", "Identifier", "First line", "Uses");
    for (i = 0; i < n_symbols; ++i) {
        printf("%-4d %-20s %-11d %d\n", i + 1, symtab[i].name,
               symtab[i].first_line, symtab[i].uses);
    }

    if (error_count) {
        printf("\n================ ERROR REPORT =================\n");
        for (i = 0; i < error_count && i < MAX_ERRORS; ++i) {
            printf("Line %-4d %-36s %s\n", errs[i].line,
                   errs[i].msg, errs[i].lexeme);
        }
    }

    printf("\nTotal tokens: %d (comments: %d)\nLexical errors: %d\n",
           token_count, cat_count[C_COMMENT], error_count);
}

int main(int argc, char **argv)
{
    int parse_status;
    if (argc != 2) {
        fprintf(stderr, "Usage: %s input.txt\n", argv[0]);
        return EXIT_FAILURE;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror(argv[1]);
        return EXIT_FAILURE;
    }

    printf("LINE   LEXEME                 TOKEN\n");
    printf("----   ------                 -----\n");
    parse_status = yyparse();
    print_summary();
    fclose(yyin);

    return (parse_status || error_count) ? EXIT_FAILURE : EXIT_SUCCESS;
}

