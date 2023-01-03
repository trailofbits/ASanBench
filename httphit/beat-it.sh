#!/usr/bin/env sh
set -eu

REQS=30000
DEADLINE=60

[ $# -lt 2 ] && echo "$0 [no]asan <compiler>" && exit 2
DATA="nginx-$1-$2"
ASAN=''; [ "$1" == "asan" ] && ASAN='-fsanitize=address'

SERVER_HOST=root@146.190.121.78
PEER_1_HOST=root@146.190.34.7
PEER_2_HOST=root@146.190.38.105

SERVER=http://$(echo $SERVER_HOST | cut -d'@' -f2):8000

NGINX='./nginx/objs/nginx -p /root/nginx -c nginx.conf'
SERVER_CMD=$(cat <<EOF
cd nginx;
./auto/configure --with-cc="$2 $ASAN ";
make -j\$(nproc);
cd ..;
[ -d nginx/logs ] || mkdir nginx/logs;
$NGINX;
EOF)

BENCH_CMD="./httphit/httphit $REQS $DEADLINE $SERVER > $DATA"

echo Compiling and starting NGINX...
ssh $SERVER_HOST -- $SERVER_CMD
echo Benchmarking...
ssh $SERVER_HOST -- "pkill atop || true; rm -f $DATA-atop || true; atop -gm -w $DATA-atop 1" &
ssh $PEER_1_HOST -- $BENCH_CMD &
ssh $PEER_2_HOST -- $BENCH_CMD
ssh $SERVER_HOST -- $NGINX -s quit || true # quitting NGINX makes LeakSan cry
echo Done! Retrieving results...
scp $SERVER_HOST:$DATA-atop .
scp $PEER_1_HOST:$DATA peer1
scp $PEER_2_HOST:$DATA peer2
cat peer1 peer2 | sort -nk1 -o $DATA
rm -f peer1 peer2
echo Calculating throughput...
python3 calc_throughput.py $DATA > $DATA-tp
