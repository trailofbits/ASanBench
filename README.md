# ASanBench
Characterizing Address Sanitizer performance overhead.

Each directory is responsible for benchmarking a specific aspect of Address Sanitizer:
- **cpp-benchmark** includes the snippet for characterizing instruction overhead.
- **gcc-benchmark** includes the scripts for measuring the overhead of compiling a suite of C programs with an instrumented compiler.
- **httphit** includes the scripts and graphs for measuring the overhead of compiling NGINX with ASan with GCC and Clang.

## Requirements

- The C++ benchmark needs [perf](https://perf.wiki.kernel.org/index.php/Tutorial), GCC, and Clang.
- The GCC benchmark needs Python3, GCC, Clang, [Gnuplot](http://www.gnuplot.info/).
- The NGINX benchmark needs the same dependencies as the GCC benchmark, and Golang (on NGINX client(s)), and atop (on NGINX host and script runner).

## Usage

### C++ Benchmark

Compile C++ with your compiler of choice with:
```shell
CXX -O2 -Wall [-fsanitize=address] test.cc -o test
```

Then benchmark to produce a report describing the process.
```shell
$ perf stat -addd --repeat=3 -- ./test
```

### NGINX Benchmark

The NGINX benchmark requires modification of the scripts. The `beat-it.sh` and `run-it.sh` scripts have hardcoded addresses which will need to be modified to connect via SSH.

#### Setup

On the NGINX host, do the following:
```shell
$ apt-get update
$ apt-get install make autoconf git gcc clang build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev libgd-dev libxml2 libxml2-dev uuid-dev
$ git clone https://github.com/nginx/nginx
$ mkdir /dev/shm/nginx
$ echo "Hello, World!" > /dev/shm/nginx/index.html
```

On the NGINX client(s), do the following:
```shell
$ apt-install golang
$ mkdir httphit
```

Finally, copy the necessary files to the client and server:
```shell
$ scp httphit/{main.go,go.mod} user@example.client:httphit
$ scp nginx.conf user@example.server:nginx
```

#### Execute

To configure how many requests are sent and for how long, modify `REQS` and `DEADLINE` in `beat-it.sh`.

Once the hosts have been setup, execute:
```shell
$ ./run-tests.sh
```
The script will automatically connect via SSH to the server and clients. The script will build and launch NGINX on the server host, start benchmarking the server on the clients, then record and collect all information. The script will produce a multi-plot graph with Gnuplot (saved as `plot.svg`).

#### What Happens
##### Server

The `beat-it.sh` script will connect to the NGINX host, (re-)compile NGINX with a specified compiler (and optionally ASan).
```shell
cd nginx;
./auto/configure --with-cc="$2 $ASAN ";
make -j$(nproc);
cd ..;

[ -d nginx/logs ] || mkdir nginx/logs;

./nginx/objs/nginx -p /root/nginx -c nginx.conf
```

In another session, `atop` is started on the NGINX host:
```shell
atop -gm -w $DATA-atop 1
```
The background process will record all CPU and memory usage of the system and save a report.

##### Clients

The clients will rebuild `httphit` then execute:
```shell
./httphit/httphit $REQS $DEADLINE $SERVER > $DATA
```

Which attempts to send `$REQS` HTTP GET requests to `$SERVER`, per second, for `$DEADLINE` seconds. The executable outputs the response time for each request in the format `<creation timestamp> <response time us>`. All requests which are dropped have a response time of 0us but are cleaned by `run-tests.sh`.

Note: The `httphit` script does _not_ produce as many requests as specified. You will have to increase `$REQS` until `calc_throughput.py` shows the number of requests you want.

### GCC Benchmark

Compiling GCC in the benchmark is straightforward:
```shell
$ git clone https://github.com/c-testsuite/c-testsuite
$ git clone https://github.com/gcc-mirror/gcc --depth=1
$ sudo ./bench.sh
```
Superuser privileges are required to use `perf stat` because some measurements are privileged.
