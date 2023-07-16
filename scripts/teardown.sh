#!/bin/sh

TEARDOWN_TARGETS="all infra energy-monitoring carbon-monitoring machine-learning visualization"

# -- Usage & params block
usage="
SYNOPSYS
	teardown.sh
		[--help]
		[--target]

EXAMPLE
	teardown.sh \
		--target requirements
"

check_params() {
	if [ -z "$teardown_target" ]; then
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

teardown_target=

while [ "$1" != "" ]; do
	case $1 in
		--target )	shift
							teardown_target="$1" ;;
		--help )			echo "$usage"
							exit 0
	esac
	shift
done

check_params

# --- Teardown block

teardown_all() {
	teardown_infra
}

delete_cluster() {
    kind delete cluster --name=cluster-sustainable-computing-sandbox
}

delete_prometheus() {
	kubectl delete ns monitoring &
	kubectl delete --ignore-not-found customresourcedefinitions \
		prometheuses.monitoring.coreos.com \
		servicemonitors.monitoring.coreos.com \
		podmonitors.monitoring.coreos.com \
		alertmanagers.monitoring.coreos.com \
		prometheusrules.monitoring.coreos.com
	# sometimes namespace is stuck Terminating, need to remove finalizers:
	kubectl get namespace "monitoring" -o json \
	| tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
	| kubectl replace --raw /api/v1/namespaces/monitoring/finalize -f -
	rm -rf ./infra/k8s/kube-prometheus
}

delete_grafana() {
	helm -n grafana uninstall grafana
}

teardown_kepler() {
	helm -n kepler uninstall kepler
}

teardown_flyte() {
	helm -n flyte uninstall flyte-core
	helm -n flyte uninstall flyte-deps
}

teardown_infra() {
	delete_cluster
	rm -rf ./infra/k8s/kube-prometheus
	rm -rf ./infra/kepler
}

teardown_energy_monitoring() {
	echo "    ↪️ Tearing down energy monitoring stack ..."
	teardown_kepler
}

teardown_carbon_monitoring() {
	echo "    ↪️ Tearing down carbon monitoring stack ..."
}

teardown_machine_learning() {
	echo "    ↪️ Tearing down machine learning stack ..."
	teardown_flyte 
}

teardown_visualization() {
	echo "    ↪️ Tearing down visualization stack ..."
	delete_grafana
}

case $teardown_target in
    all         			 )		teardown_all 					;;
    infra       			 )		teardown_infra 					;;
    energy-monitoring        )		teardown_energy_monitoring 		;;
    carbon-monitoring        )		teardown_carbon_monitoring 		;;
    machine-learning         )		teardown_machine_learning 		;;
    visualization   	     )		teardown_visualization 			;;
    *           			 )      echo "⚠️ Error, unsupported teardown target '$teardown_target'. Expected one of [$TEARDOWN_TARGETS]" >&2;
                        			exit 1
esac
