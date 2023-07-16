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
    just deploy all

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
        echo "📦 Opening $target dashboard ..."; \
        ./scripts/view.sh --target $target; \
    else \
        echo "⚠️ Only supported: view [$view_targets]"; \
    fi
