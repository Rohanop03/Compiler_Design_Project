CC := gcc
CFLAGS := -std=c11 -Wall -Wextra -pedantic -D_POSIX_C_SOURCE=200809L
TARGET := lexer

.PHONY: all clean test

all: $(TARGET)

parser.tab.c parser.tab.h &: parser.y
	bison -Wall -d -o parser.tab.c parser.y

lex.yy.c: lexer.l parser.tab.h
	flex -o lex.yy.c lexer.l

$(TARGET): parser.tab.c lex.yy.c
	$(CC) $(CFLAGS) -o $(TARGET) parser.tab.c lex.yy.c

test: $(TARGET)
	./$(TARGET) input.txt > valid_output.txt
	@./$(TARGET) errors.txt > error_output.txt; status=$$?; \
	if [ $$status -ne 1 ]; then \
		echo "Expected errors.txt to return status 1, got $$status"; \
		exit 1; \
	fi
	@grep -q "Lexical errors: 11" error_output.txt
	@echo "Tests passed. See valid_output.txt and error_output.txt."

clean:
	rm -f $(TARGET) lex.yy.c parser.tab.c parser.tab.h \
	      valid_output.txt error_output.txt

