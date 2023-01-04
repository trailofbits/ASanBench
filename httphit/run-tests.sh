#/usr/bin/env sh

PEER_1_HOST=root@146.190.34.7
PEER_2_HOST=root@146.190.38.105

echo Synchronizing stress script
scp main.go $PEER_1_HOST:httphit
scp main.go $PEER_2_HOST:httphit
ssh $PEER_1_HOST -- 'cd httphit; go build'
ssh $PEER_2_HOST -- 'cd httphit; go build'

echo Running benchmark battery
./beat-it.sh asan clang
./beat-it.sh asan gcc
./beat-it.sh noasan clang
./beat-it.sh noasan gcc

echo Processing atop measurements
for f in *-atop; do
    atopsar -r $f -m | tail -n +7 | head -n60 | tr -s '[:space:]' | \
        cut -d' ' -f3 | tr -d 'M' | tr '[:space:]' '+' | \
        xargs -I {} -- printf 'scale=2\n({}0)/60\n' | bc > $f-summary

    atopsar -r $f -O | tail -n +7 | head -n60 | \
        tr -s '[:space:]' | cut -d' ' -f4 > $f-summary
done

echo Cleaning data
for f in nginx-*; do grep -vI ' 0' $f > $f-clean; done

gnuplot plot.plt > plot.svg
