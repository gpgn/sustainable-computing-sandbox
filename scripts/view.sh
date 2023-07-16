#!/bin/sh

VIEW_TARGETS="all kepler flyte"

# -- Usage & params block
usage="
SYNOPSYS
	view.sh
		[--help]
		[--target]

EXAMPLE
	view.sh \
		--target requirements
"

check_params() {
	if [ -z "$view_target" ]; then
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

view_target=

while [ "$1" != "" ]; do
	case $1 in
		--target )	shift
							view_target="$1" ;;
		--help )			echo "$usage"
							exit 0
	esac
	shift
done

check_params

# --- View block

view_kepler() {
	echo "    🖥️ Forwarding & opening Grafana dashboard (can be accessed with credentials admin:admin) ..."
	kubectl -n monitoring port-forward svc/grafana 3000 &
	xdg-open http://localhost:3000/d/NhnADUW4z/kepler-exporter-dashboard
}

view_flyte() {
	echo "    🖥️ Forwarding & opening Flyte console ..."
	kubectl -n flyte port-forward svc/flyteconsole 8080:80 &
	xdg-open http://localhost:8080/console
}

view_all() {
	view_kepler
	view_flyte
}

case $view_target in
    all         			 )		view_all 						;;
    kepler       			 )		view_kepler 					;;
    flyte        			 )		view_flyte 						;;
    *           			 )      echo "⚠️ Error, unsupported view target '$view_target'. Expected one of [$VIEW_TARGETS]" >&2;
                        			exit 1
esac
