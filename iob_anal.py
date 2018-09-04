#!/usr/bin/python3

# Reads a debug log where every allocated io_buffer gets these logs:
# IOBAlloc <caller> <buffer_addr> <size>
# IOBFree <caller> <buffer_addr>

# Beware, ANSI escapes aren't removed by this script, don't forget to sed
# these away.

import sys
import json
import yaml
import argparse
from collections import defaultdict


IOB_ALLOC_FLAG = 'IOBAlloc'
IOB_FREE_FLAG = 'IOBFree'

SERIALIZERS = {
    'json': json.dumps,
    'pjson': lambda o: json.dumps(o, indent=4),
    'yaml': yaml.dump,
}

DEFAULT_SERIALIZER = 'pjson'

def analyse(input_file, limit):
    lines = input_file.readlines()

    # maps a memory address to its last caller, size, and status.
    # if status is false, the last caller is where it was last freed
    # if status is true, the last caller is where it was last allocated
    status = {}

    # counts the number of allocations per call site
    callers = defaultdict(int)

    def iob_alloc(i, line):
        if len(line) != 4:
            return

        caller = int(line[1], base=0)
        addr = int(line[2], base=0)
        size = int(line[3], base=0)

        status[addr] = (caller, size, True)
        callers[caller] += 1

    def iob_free(i, line):
        if len(line) != 3:
            return

        free_caller = int(line[1], base=0)
        addr = int(line[2], base=0)

        addr_status = status.get(addr, None)
        if addr_status is None:
            print("{}: freed unknown address 0x{:x} from 0x{:x}".format(i, addr, free_caller),
                  file=sys.stderr)
            return

        last_caller, size, valid = addr_status
        if not valid:
            print("{}: double freed 0x{:x} from 0x{:x} "
                  "(first freed on 0x{:x})".format(i, addr, free_caller, last_caller),
                  file=sys.stderr)
            return

        status[addr] = (free_caller, 0, False)

        callers[last_caller] -= 1

    ops = {
        IOB_ALLOC_FLAG: iob_alloc,
        IOB_FREE_FLAG: iob_free,
    }

    for i, line in enumerate(lines):
        if i == limit:
            break

        line = line.split()
        if len(line) == 0:
            continue

        op = ops.get(line[0])
        if op is None:
            continue

        op(i, line)

    callers = { hex(addr): count
                for addr, count in callers.items()
                if count != 0 }

    status = { hex(addr): { 'caller': hex(caller),
                            'size': size }
               for addr, (caller, size, valid) in status.items()
               if valid }

    return {
        'status': status,
        'callers': callers
    }

def main(*args, **kwargs):
    parser = argparse.ArgumentParser('io_buffer allocation analyser')
    parser.add_argument('--limit', type=int, default=-1)
    parser.add_argument('--serializer', default=DEFAULT_SERIALIZER)
    parser.add_argument('input', nargs='?', default='-')
    opts = parser.parse_args(*args, **kwargs)

    input_file = sys.stdin \
        if opts.input == '-' \
           else open(opts.input)

    serializer = SERIALIZERS.get(opts.serializer, None)
    if serializer is None:
        print("unknown serializer:", opts.serializer,
              file=sys.stderr)
        exit(1)

    print(serializer(analyse(input_file, opts.limit)))

if __name__ == '__main__':
    main()
