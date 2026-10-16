# Flex/Bison Lexical Analyzer

Compiler Design Lab submission package for a token-reporting lexical analyzer.

## Package contents

| File | Purpose |
|---|---|
| `lexer.l` | Flex scanner rules |
| `parser.y` | Bison token driver, symbol table, and reports |
| `input.txt` | Valid sample program |
| `errors.txt` | Eleven deliberate lexical errors |
| `Makefile` | Repeatable build and test commands |
| `run_tests.sh` | Automated test script |
| `VERIFICATION.txt` | Recorded build and test result for this package |

Generated files and the compiled executable are intentionally not included. They
are created on the target Linux/WSL machine, avoiding platform incompatibilities.

## Requirements on Ubuntu or WSL

Install the tools once:

```bash
sudo apt update
sudo apt install flex bison build-essential
```

## Build

Open a terminal in this extracted folder and run:

```bash
make
```

This creates an executable named `lexer`.

Equivalent manual commands are:

```bash
bison -Wall -d -o parser.tab.c parser.y
flex -o lex.yy.c lexer.l
gcc -std=c11 -Wall -Wextra -pedantic -D_POSIX_C_SOURCE=200809L \
    -o lexer parser.tab.c lex.yy.c
```

## Run

Valid program:

```bash
./lexer input.txt
```

Error test:

```bash
./lexer errors.txt
```

The error test deliberately returns exit status `1` because it finds lexical
errors. That status is expected, not a build failure.

## Automated verification

```bash
sh run_tests.sh
```

Alternatively:

```bash
make test
```

Both commands create `valid_output.txt` and `error_output.txt`. The test succeeds
only if the valid input exits normally and the error input reports all eleven
deliberate lexical errors.

## Clean generated files

```bash
make clean
```

## Language rules represented

- Keywords: `num`, `dec`, `text`, `letter`, `flag`, `check`, `otherwise`,
  `repeat`, `show`, `ask`, `task`, `give`, `stop`, `skip`, `none`, `fixed`
- Boolean literals: `yes`, `no`
- Identifiers: letter or underscore first; maximum 31 characters
- Integer range: 0 through 2147483647
- Decimal literals: digits on both sides of one decimal point
- String and character escapes: `\n`, `\t`, `\r`, `\0`, `\\`, `\'`, `\"`
- Arithmetic, relational, logical, assignment, and increment/decrement operators
- Single-line and multiline comments

The scanner reports malformed numbers, invalid or unterminated literals,
overlong identifiers, illegal characters, and unterminated multiline comments.

