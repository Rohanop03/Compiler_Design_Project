#!/usr/bin/env sh
set -eu

make clean
make
./lexer input.txt > valid_output.txt

set +e
./lexer errors.txt > error_output.txt
error_status=$?
set -e

if [ "$error_status" -ne 1 ]; then
    echo "FAIL: errors.txt should return status 1, got $error_status" >&2
    exit 1
fi

if ! grep -q "Lexical errors: 11" error_output.txt; then
    echo "FAIL: errors.txt did not produce the expected 11 lexical errors" >&2
    exit 1
fi

echo "PASS: valid and error test cases completed."
echo "Results: valid_output.txt and error_output.txt"

