#!/bin/sh

# -a is for processing binary files as text
# -r is for recursive
# -i is for case insensitive
# -E is for interpreting the pattern as an extended regular expression
grep -ariE '(flag|fl4g|key|k3y|ctf|pass|p4ss|asis|secret|s3cret|s3cr3t|secr3t)'
