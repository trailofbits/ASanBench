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

### NGINX Benchmark

The NGINX benchmark requires modification of the scripts. The `beat-it.sh` and `run-it.sh` scripts have hardcoded addresses which will need to be modified to connect via SSH. On the NGINX setup server, clone the NGINX repository in the home directory of the SSH user then copy the `nginx.conf` file. Create the `/dev/shm/nginx` directory then copy `page.html` (see `nginx.conf`). The client host(s) will need to have the `httphit` Golang files copied over.

Once the hosts have been setup, run:
```shell
$ ./run-tests.sh
```

Which will run a battery of tests with the `REQS` and `DEADLINE` variables in `beat-it.sh` then download and process all data. The script will produce a multi-plot graph with Gnuplot (saved as `plot.svg`).

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
