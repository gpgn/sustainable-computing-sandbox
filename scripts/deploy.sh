#!/bin/sh

DEPLOY_TARGETS="all infra energy-monitoring carbon-monitoring machine-learning visualization"
CLUSTER_NAME="cluster-sustainable-computing-sandbox"

# -- Usage & params block
usage="
SYNOPSYS
	deploy.sh
		[--help]
		[--target]

EXAMPLE
	deploy.sh \
		--target requirements
"

check_params() {
	if [ -z "$deploy_target" ]; then
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

deploy_target=

while [ "$1" != "" ]; do
	case $1 in
		--target )	shift
							deploy_target="$1" ;;
		--help )			echo "$usage"
							exit 0
	esac
	shift
done

check_params

# --- Deploy block

deploy_all() {
	deploy_infra
	deploy_energy_monitoring
	deploy_carbon_monitoring
	deploy_machine_learning
	deploy_visualization
}

create_cluster() {
	if !(kind get clusters | grep -q $CLUSTER_NAME)
    then
        echo "    ⚙️ Creating cluster kind-$CLUSTER_NAME ..."
		kind create cluster --name=$CLUSTER_NAME --config=./infra/k8s/local-cluster-config.yaml
		kubectl cluster-info --context kind-$CLUSTER_NAME
	else
		echo "    ⚙️ Cluster kind-$CLUSTER_NAME already exists, skipping ..."
	fi
}

fetch_grafana_dashboards() {
	KEPLER_EXPORTER_GRAFANA_DASHBOARD_JSON=`curl -fsSL https://raw.githubusercontent.com/sustainable-computing-io/kepler/main/grafana-dashboards/Kepler-Exporter.json | sed '1 ! s/^/         /'`
	mkdir -p grafana-dashboards
	cat > ./grafana-dashboards/kepler-exporter-configmap.yaml<<-EOF
apiVersion: v1
data:
    kepler-exporter.json: |-
        $KEPLER_EXPORTER_GRAFANA_DASHBOARD_JSON
kind: ConfigMap
metadata:
    labels:
        app.kubernetes.io/component: grafana
        app.kubernetes.io/name: grafana
        app.kubernetes.io/part-of: kube-prometheus
        app.kubernetes.io/version: 9.5.3
    name: grafana-dashboard-kepler-exporter
    namespace: monitoring
EOF
}

deploy_prometheus() {
	if !(kubectl get deploy prometheus-operator -n monitoring --no-headers --ignore-not-found | grep -q prometheus-operator)
    then
        echo "    ⚙️ Deploying Prometheus operator ..."
		git clone --depth 1 https://github.com/prometheus-operator/kube-prometheus ./infra/k8s/kube-prometheus
		cd ./infra/k8s/kube-prometheus
		# fetch kepler-exporter grafana dashboard and inject in prometheus grafana deployment
		fetch_grafana_dashboards
		yq -i e '.items += [load("./grafana-dashboards/kepler-exporter-configmap.yaml")]' ./manifests/grafana-dashboardDefinitions.yaml
		yq -i e '.spec.template.spec.containers.0.volumeMounts += [ {"mountPath": "/grafana-dashboard-definitions/0/kepler-exporter", "name": "grafana-dashboard-kepler-exporter", "readOnly": false} ]' ./manifests/grafana-deployment.yaml
		yq -i e '.spec.template.spec.volumes += [ {"configMap": {"name": "grafana-dashboard-kepler-exporter"}, "name": "grafana-dashboard-kepler-exporter"} ]' ./manifests/grafana-deployment.yaml
		# apply prometheus manifests
		kubectl apply --server-side -f manifests/setup
		until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
		kubectl apply -f manifests/
	else
		echo "    ⚙️ Prometheus operator already exists, skipping ..."
	fi
	echo "    💡 Grafana deployment can be accessed with credentials admin:admin\n    Expose using: 'kubectl -n monitoring port-forward svc/grafana 3000'\n    And navigate to http://localhost:3000/d/NhnADUW4z/kepler-exporter-dashboard"
}

deploy_grafana() {
	if !(kubectl get deploy grafana -n grafana --no-headers --ignore-not-found | grep -q grafana)
    then
        echo "    ⚙️ Deploying Grafana ..."
		helm repo add grafana https://grafana.github.io/helm-charts
		helm repo update
		helm -n grafana install grafana grafana/grafana --create-namespace -f ./infra/grafana/values.yaml
		GRAFANA_POD=$(kubectl get pods --namespace grafana -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
		GRAFANA_PASSWORD=$(kubectl get secret -n grafana grafana -o jsonpath="{.data.admin-password}" | base64 -d)
		echo "    ⚙️ Grafana deployment can be accessed with credentials admin:$GRAFANA_PASSWORD\n    💡Expose using: 'kubectl -n grafana port-forward $GRAFANA_POD 3000'"
	else
		GRAFANA_POD=$(kubectl get pods --namespace grafana -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
		GRAFANA_PASSWORD=$(kubectl get secret -n grafana grafana -o jsonpath="{.data.admin-password}" | base64 -d)
		echo "    ⚙️ Grafana deployment already exists with credentials admin:$GRAFANA_PASSWORD\n    💡Expose using: 'kubectl -n grafana port-forward $GRAFANA_POD 3000', skipping deployment ..."
	fi
}

deploy_infra() {
	create_cluster
	deploy_prometheus
}

deploy_kepler() {
	git clone --depth 1 git@github.com:sustainable-computing-io/kepler.git ./infra/kepler
	cd ./infra/kepler
	make build-manifest OPTS="CI_DEPLOY PROMETHEUS_DEPLOY"
	kubectl apply -f _output/generated-manifest/deployment.yaml
}

deploy_energy_monitoring() {
	echo "⚙️ Deploying energy monitoring stack ..."
	deploy_kepler
}

deploy_carbon_monitoring() {
	echo "⚙️ Deploying carbon monitoring stack ..."
}

deploy_machine_learning() {
	echo "⚙️ Deploying machine learning stack ..."
}

deploy_visualization() {
	echo "⚙️ Deploying visualization stack ..."
}

case $deploy_target in
    all         			 )		deploy_all 						;;
    infra       			 )		deploy_infra 					;;
    energy-monitoring        )		deploy_energy_monitoring 		;;
    carbon-monitoring        )		deploy_carbon_monitoring 		;;
    machine-learning         )		deploy_machine_learning 		;;
    visualization   	     )		deploy_visualization 			;;
    *           			 )      echo "⚠️ Error, unsupported deploy target '$deploy_target'. Expected one of [$DEPLOY_TARGETS]" >&2;
                        			exit 1
esac
