#/usr/bin/env python3
import pprint
import csv
import statistics
import sys
from dataclasses import dataclass
from pathlib import Path

@dataclass
class Stats:
    cpu_clock: float
    page_faults: int
    cycles: int
    stalled_cycles_fe: int
    stalled_cycles_be: int
    insns: int
    branches: int
    branch_misses: int
    l1_misses: int

def read_files(path: Path, prefix: str) -> [Stats]:
    stats = []

    for file in path.glob(prefix + '*'):
        with open(file) as f:
            it = iter(f)
            next(it), next(it)
            records = list(csv.reader(f, delimiter=';'))
            stats.append(Stats(
                cpu_clock        =float(records[0][0]),
                page_faults      =int(records[3][0]),
                cycles           =int(records[4][0]),
                stalled_cycles_fe=int(records[5][0]),
                stalled_cycles_be=int(records[6][0]),
                insns            =int(records[7][0]),
                branches         =int(records[9][0]),
                branch_misses    =int(records[10][0]),
                l1_misses        =int(records[12][0]),
            ))
    return stats

def compare(path: Path, asan: str, noasan: str):
    asan   = read_files(path, asan)
    noasan = read_files(path, noasan)

    merged = [
        Stats(**{field:orig/instrumented for ((field, instrumented), orig)
                 in zip(san.__dict__.items(), nosan.__dict__.values())})
        for san, nosan in zip(asan, noasan)
    ]

    def select(field):
        return (getattr(elem, field) for elem in merged)

    mean = Stats(
        cpu_clock        =round(statistics.mean(select("cpu_clock")), 3),
        page_faults      =round(statistics.mean(select("page_faults")), 3),
        cycles           =round(statistics.mean(select("cycles")), 3),
        stalled_cycles_fe=round(statistics.mean(select("stalled_cycles_fe")), 3),
        stalled_cycles_be=round(statistics.mean(select("stalled_cycles_be")), 3),
        insns            =round(statistics.mean(select("insns")), 3),
        branches         =round(statistics.mean(select("branches")), 3),
        branch_misses    =round(statistics.mean(select("branch_misses")), 3),
        l1_misses        =round(statistics.mean(select("l1_misses")), 3)
    )

    stdev = Stats(
        cpu_clock        =round(statistics.pstdev(select("cpu_clock")), 3),
        page_faults      =round(statistics.pstdev(select("page_faults")), 3),
        cycles           =round(statistics.pstdev(select("cycles")), 3),
        stalled_cycles_fe=round(statistics.pstdev(select("stalled_cycles_fe")), 3),
        stalled_cycles_be=round(statistics.pstdev(select("stalled_cycles_be")), 3),
        insns            =round(statistics.pstdev(select("insns")), 3),
        branches         =round(statistics.pstdev(select("branches")), 3),
        branch_misses    =round(statistics.pstdev(select("branch_misses")), 3),
        l1_misses        =round(statistics.pstdev(select("l1_misses")), 3)
    )
    return mean, stdev

def print_stats(average, stdev):
    it = zip(average.__dict__.items(), stdev.__dict__.values())
    for ((name, val), dev) in it:
        # print(f"{name} = {val}±{dev}")
        print(f"{val}±{dev}")

def main(path: Path):
    cosmo = compare(path, "cosmo-asan", "cosmo-noasan")
    # gcc   = compare(path, "gcc-asan", "gcc-noasan")
    # llvm  = compare(path, "llvm-asan", "llvm-noasan")
    print_stats(*cosmo)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(f"usage: {sys.argv[0]} <REPORT DIR>")
    main(Path(sys.argv[1]))
