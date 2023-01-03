#include <cstdint>
#include <cstdio>
#include <random>
#include <algorithm>
#include <chrono>
#include <iostream>
#include <sys/mman.h>

constexpr auto PAGE_SIZE = 4096;

#define PAGE_ALIGN(a) ((void *)((uint64_t)(a) & ~(PAGE_SIZE - 1)))

int main() {
    using std::chrono::high_resolution_clock;
    using std::chrono::duration_cast;

    auto xs = std::vector<uint64_t>(10000 * PAGE_SIZE);

    // disable THP support for backing array
    auto truncated = (uint64_t)xs.data() & PAGE_SIZE - 1;
    size_t length = sizeof(uint64_t) * xs.size() + truncated;
    if (madvise(PAGE_ALIGN(xs.data()), length, MADV_NOHUGEPAGE) < 0) {
        return EXIT_FAILURE;
    }

    std::random_device rdev;
    std::default_random_engine e(rdev());
    std::uniform_int_distribution<uint64_t> uniform_dist(0, 255);

    for (auto i = 0; i < xs.capacity(); ++i) {
        xs[i] = uniform_dist(e);
    }

    auto start = high_resolution_clock::now();

    volatile auto sum = 0;
  	// add leading cache entries from split cache lines
    for (auto i = 0; i < xs.size() / 8; i += 8) {
        sum += xs[i] + xs[std::max(i - 8 * 32, 0)];
    }

    auto elapsed = high_resolution_clock::now() - start;
    auto elapsed_us = duration_cast<std::chrono::microseconds>(elapsed);
    std::cout << elapsed_us.count() << '\n';
}
