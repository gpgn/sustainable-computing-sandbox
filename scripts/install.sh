#!/bin/bash

INSTALL_TARGETS="requirements"

# -- Usage & params block
usage="
SYNOPSIS
	install.sh
		[--help]
		[--target]

EXAMPLE
	install.sh
            --target [$INSTALL_TARGETS]
"

check_params() {
	if [ -z "$install_target" ]; then
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

install_target=

while [ "$1" != "" ]; do
	case $1 in
		--target )	shift
							install_target="$1" ;;
		--help )			echo "$usage"
							exit 0
	esac
	shift
done

check_params

# --- Install block

install_kind() {
    MIN_KIND_VERSION=0.20.0
    if !(echo a version $MIN_KIND_VERSION; kind --version) | sort -Vk3 | tail -1 | grep -q kind
    then
        echo "    ↪️ Installing kind v$MIN_KIND_VERSION ..."
        [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v$MIN_KIND_VERSION/kind-linux-amd64
        [ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v$MIN_KIND_VERSION/kind-linux-arm64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    else
        echo "    \x1b[32m✓\x1b[0m kind >= $MIN_KIND_VERSION already installed, skipping ..."
    fi
}

install_kubectl() {
    MIN_KUBECTL_VERSION=1.24.0
    if !(echo a version $MIN_KUBECTL_VERSION; echo "kubectl version $(kubectl version --client -o json | jq -r .clientVersion.gitVersion | cut -c2-)") | sort -Vk3 | tail -1 | grep -q kubectl
    then
        echo "    ↪️ Installing kubectl v$MIN_KUBECTL_VERSION..."
        [ $(uname -m) = x86_64 ] && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        [ $(uname -m) = aarch64 ] && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        kubectl version --client
    else
        echo "    \x1b[32m✓\x1b[0m kubectl >= $MIN_KUBECTL_VERSION already installed, skipping ..."
    fi
}

install_helm() {
    MIN_HELM_VERSION=3.12.1
    if !(echo a version $MIN_HELM_VERSION; echo "helm version $(helm version --short | cut -c2- | cut -d '+' -f 1)") | sort -Vk3 | tail -1 | grep -q helm
    then
        echo "    ↪️ Installing helm v$MIN_HELM_VERSION..."
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh
        rm ./get_helm.sh
    else
        echo "    \x1b[32m✓\x1b[0m helm >= $MIN_HELM_VERSION already installed, skipping ..."
    fi
}

install_yq() {
    if ! command -v yq &>/dev/null
    then
        echo "    ↪️ Installing yq ..."
        sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
        sudo chmod +x /usr/bin/yq
    else
        echo "    \x1b[32m✓\x1b[0m yq already installed, skipping ..."
    fi
}

install_go() {
    GO_VERSION=1.20.5
    if ! command -v go &>/dev/null
    then
        echo "    ↪️ Installing Golang v$GO_VERSION ..."
        curl -fsSL -o go$GO_VERSION.linux-amd64.tar.gz https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
    else
        echo "    \x1b[32m✓\x1b[0m Golang already installed, skipping ..."
    fi
}

install_requirements() {
    install_kind
    install_kubectl
    install_helm
    install_yq
    install_go
}

case $install_target in
    requirements )	install_requirements ;;
    * )             echo "⚠️ Error, unsupported install target '$install_target'. Expected one of [$INSTALL_TARGETS]" >&2;
                    exit 1
esac
