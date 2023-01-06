#!/usr/bin/env sh
set -eu

[ -d reports ] && rm -rf reports
mkdir reports

echo Benchmarking compilers
./test.sh clang
./test.sh clang asan
./test.sh gcc
./test.sh gcc asan

chown -R $(logname) $REPORTDIR

echo Collecting results
#python3 merge.py reports
