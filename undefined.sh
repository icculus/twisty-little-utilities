#!/bin/bash

# Pipe GCC output through this to just get a simple list of missing symbols,
#  minus spam, at link time:
#
#   gcc -o blah *.o 2>&1 |undefined.sh

grep " undefined reference to " |perl -w -p -e 's/\A.*? undefined reference to .//; s/.\Z//;' |sort |uniq

