set terminal svg size 1400 800

set multiplot layout 3,2 title ""

set title "Latency of HTTP GET Requests (GCC)"
set xlabel "Time (ms)"
set ylabel "Latency (us)"

set logscale y

stats "nginx-noasan-gcc-clean" nooutput
noasan_median = STATS_median_y
stats "nginx-asan-gcc-clean" nooutput
asan_median = STATS_median_y

plot "nginx-noasan-gcc-clean" every 100 u 1:2 w p ps .5 pt 2 t "No ASan Latency", \
     "nginx-asan-gcc-clean" every 100 u 1:2 w p ps .5 pt 2 t "ASan Latency", \
     '' u 1:(noasan_median) every 10000 w l ls 2 lw 2 lc "red" t sprintf("Median No ASan Latency (%dus)", noasan_median), \
     '' u 1:(asan_median) every 10000 w l ls 2 lw 2 lc "green" t sprintf("Median ASan Latency (%dus)", asan_median)

set title "Latency of HTTP GET Requests (Clang)"
set xlabel "Time (ms)"
set ylabel "Latency (us)"

set logscale y

stats "nginx-noasan-clang-clean" nooutput
noasan_median = STATS_median_y
stats "nginx-asan-clang-clean" nooutput
asan_median = STATS_median_y

plot "nginx-noasan-clang-clean" every 100 u 1:2 w p ps .5 pt 2 t "No ASan Latency", \
     "nginx-asan-clang-clean" every 100 u 1:2 w p ps .5 pt 2 t "ASan Latency", \
     '' u 1:(noasan_median) every 10000 w l ls 2 lw 2 lc "red" t sprintf("Median No ASan Latency (%dus)", noasan_median), \
     '' u 1:(asan_median) every 10000 w l ls 2 lw 2 lc "green" t sprintf("Median ASan Latency (%dus)", asan_median)

set title "Throughput of HTTP GET Requests (GCC)"
set ylabel "Throughput (requests per second)"
set yrange [0:]
unset logscale y
plot "nginx-noasan-gcc-tp" u 1:2 w l t "No ASan Throughput", \
     "nginx-asan-gcc-tp" u 1:2 w l t "ASan Throughput"


set title "Throughput of HTTP GET Requests (Clang)"
set ylabel "Throughput (requests per second)"
set yrange [0:]
unset logscale y
plot "nginx-noasan-clang-tp" u 1:2 w l t "No ASan Throughput", \
     "nginx-asan-clang-tp" u 1:2 w l t "ASan Throughput"


set yrange [0:120]
set ylabel "CPU Usage (%)"
set xlabel "Time (s)"

set title "CPU Usage of NGINX (GCC)"
plot "nginx-noasan-gcc-atop-summary" u 1 w l t "No ASan CPU Usage", \
     "nginx-asan-gcc-atop-summary" u 1 w l t "ASan CPU Usage"


set title "CPU Usage of NGINX (Clang)"
plot "nginx-noasan-clang-atop-summary" u 1 w l t "No ASan CPU Usage", \
     "nginx-asan-clang-atop-summary" u 1 w l t "ASan CPU Usage"

