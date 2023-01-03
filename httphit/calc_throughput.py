import sys

def main(fname):
    SECOND_MS = 1_000
    reqs_per_sec = []
    with open(fname) as f:
        until = 1 * SECOND_MS
        n_reqs = 0
        for time, _ in map(str.split, filter(str.strip, f)):
            if int(time) > until:
                reqs_per_sec.append((until, n_reqs))
                until += SECOND_MS
                n_reqs = 0
            n_reqs += 1
        reqs_per_sec.append((until, n_reqs))

    for ts, n_reqs in reqs_per_sec:
        print(ts, n_reqs)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(f"usage: {sys.argv[0]} <data>")
    main(sys.argv[1])
