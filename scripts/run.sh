#!/bin/sh

RUN_TARGETS="machine-learning"

# -- Usage & params block
usage="
SYNOPSYS
	run.sh
		[--help]
		[--target]

EXAMPLE
	run.sh \
		--target requirements
"

check_params() {
	if [ -z "$run_target" ]; then
		echo "error: --target missing" >&2
		exit 1
	fi
}

wait_spin() {
    PID=$!
    i=1
    sp="🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛"
    echo -n ' '
    while [ -d /proc/$PID ]
    do
    printf "\b\b${sp:i++%${#sp}:1}"
    sleep 0.05
    done
}

run_target=

while [ "$1" != "" ]; do
	case $1 in
		--target )	shift
							run_target="$1" ;;
		--help )			echo "$usage"
							exit 0
	esac
	shift
done

check_params

# --- Run block

run_machine_learning() {
	echo "    ⚡ Running machine learning workload ..."
}

case $run_target in
    machine-learning	)		run_machine_learning	;;
    *           	    )      	echo "⚠️ Error, unsupported run target '$run_target'. Expected one of [$RUN_TARGETS]" >&2;
                        		exit 1
esac
