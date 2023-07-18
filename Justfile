set export
set positional-arguments

default:
  just --list

install_targets := "requirements"
deploy_targets := "all infra energy-monitoring carbon-monitoring machine-learning visualization"
run_targets := "machine-learning"
view_targets := "all kepler flyte"


install $target:
    @if echo $install_targets | tr ' ' '\n' | grep -q $target; then \
        echo "📦 Installing $target ..."; \
        ./scripts/install.sh --target $target; \
    else \
        echo "⚠️ Only supported: install [$install_targets]"; \
    fi

init:
    @if command -v mullvad >/dev/null 2>&1; then \
        if ! mullvad status | grep -q Disconnected; then \
            printf '⚠️ Mullvad VPN active. Are you sure you want to continue? This may impact Flyte deployment on KinD (y/n) '; \
            read answer; \
            if [ "$answer" != "${answer#[Yy]}" ] ;then \
                just deploy all; \
            else \
                exit 0; \
            fi; \
        fi; \
    fi; \
    just deploy all
    @bash -c "echo -e '\x1b[32m✓\x1b[0m Full stack deployed, waiting for all Pods to be up and running ...'"
    kubectl wait pods -n flyte -l app.kubernetes.io/instance=flyte-core --for condition=Ready --timeout=600s
    kubectl wait pods -n monitoring -l app.kubernetes.io/part-of=kube-prometheus --for condition=Ready --timeout=600s
    just view

deploy $target:
    @if echo $deploy_targets | tr ' ' '\n' | grep -q $target; then \
        echo "📦 Deploying $target ..."; \
        ./scripts/deploy.sh --target $target; \
    else \
        echo "⚠️ Only supported: deploy [$deploy_targets]"; \
    fi

run $target:
    @if echo $run_targets | tr ' ' '\n' | grep -q $target; then \
        echo "📦 Running $target ..."; \
        ./scripts/run.sh --target $target; \
    else \
        echo "⚠️ Only supported: run [$run_targets]"; \
    fi

teardown $target="all":
    @if echo $deploy_targets | tr ' ' '\n' | grep -q $target; then \
        echo "📦 Tearing down $target ..."; \
        ./scripts/teardown.sh --target $target; \
    else \
        echo "⚠️ Only supported: teardown [$deploy_targets]"; \
    fi

view $target="all":
    @if echo $view_targets | tr ' ' '\n' | grep -q $target; then \
        echo "📦 Opening $target dashboard(s) ..."; \
        ./scripts/view.sh --target $target; \
    else \
        echo "⚠️ Only supported: view [$view_targets]"; \
    fi
