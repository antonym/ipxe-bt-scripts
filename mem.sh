#!/bin/sh

# this script parses an iPXE debug log to extract memory usage metadata
# debug for the malloc module must obviously be enabled.

# depends on: grep, awk, gnuplot, sed

input_file="${1:--}"

awk_spacers=',|[ ]|\\(|\\)|\\['
awk_program='
# Ipxe doesnt keep track of allocated blocks, only free blocks
# are tracked. The first freed block is the available memory area.
# the init variable is used to keep track of this

# the first field is the line number, the others are operation-specific

$2 == "Allocating" {
    mem += strtonum($3)
}

$2 == "Freeing" {
    subst = (strtonum($5) - strtonum($4))
    if (mem - subst < 0) {
        if (init == 0) {
            init = 1;
            mem = subst
        }
        else {
            print "freed too much data: ",subst > "/dev/stderr"
            exit 1
        }
    }
    mem -= subst
}

{
    print $1,mem
}
'

gnuplot_program='
set title "iPXE memory usage graph";
plot "-" with lines;
'

filter_escapes () {
    sed 's/[\x01-\x1F\x7F].*m//g' -- "$@"
}

line_numberer () {
    awk '{print NR,$0}'
}

filter_escapes "${input_file}" \
    | line_numberer \
    | grep -E '^[0-9]+ (Allocating|Freeing)' \
    | awk -F "${awk_spacers}" "${awk_program}" \
    | gnuplot --persist -e "${gnuplot_program}"
