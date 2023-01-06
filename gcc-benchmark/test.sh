#/usr/bin/env sh
set -eu

CCGCC="$1"
GCCCFLAGS=""
ASAN=""
[ $# -gt 1 ] && ASAN="-asan" && GCCCFLAGS="-fsanitize=address"

GCCDIR="$(pwd)/gcc"

TARGETDIR=$(mktemp -dp /dev/shm)
CC="$GCCDIR/sample/bin/gcc"
CFLAGS='-I/usr/include -I/usr/lib/gcc/x86_64-pc-linux-gnu/12.2.0/include/ -w -c'

PROGDIR=c-testsuite/tests/single-exec

alias gcc++=gcc

cd gcc;
make distclean || true;
CC=$CCGCC CXX=$CCGCC++ CXXFLAGS=$GCCCFLAGS CFLAGS=$GCCCFLAGS LDFLAGS='-lasan' ./configure --enable-languages=c --disable-bootstrap --disable-werror --prefix=$(pwd)/sample
CC=$CCGCC ./configure --enable-languages=c --disable-bootstrap --disable-werror --prefix=$GCCDIR/sample
ASAN_OPTIONS=detect_leaks=0 LD_PRELOAD=/usr/lib/libasan.so make -j
ASAN_OPTOINS=detect_leaks=0 make install
cd ..;

[ -f $CC ]                 || exit 1
command -v perf >/dev/null || exit 2

PERFFLAGS='stat -ad -x; --repeat=3 --no-big-num --no-csv-summary'
REPORTDIR='reports'
PERFREPORT="$REPORTDIR/$1$ASAN"

[ -d $REPORTDIR ] && rm -f $PERFREPORT*
[ -d $REPORTDIR ] || mkdir $REPORTDIR
echo writing results into \'$REPORTDIR\'

for f in $PROGDIR/*.c; do
    echo [$(date +%T)] benchmarking $f
    TARGET=$(basename $f .c)
    CCTARGET="$TARGETDIR/TARGET.o"
    perf $PERFFLAGS       -o $PERFREPORT-$TARGET      -- $CC $CFLAGS -o $CCTARGET $f
    perf stat -xr1 --null -o $PERFREPORT-$TARGET-null -- $CC $CFLAGS -o $CCTARGET $f
    rm -f $CCTARGET
done

rm -rf $TARGETDIR
