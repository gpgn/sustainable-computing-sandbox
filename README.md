# Sustainable computing sandbox

🌱 Experimental environment to develop on energy- and carbon-aware cloud-native software. 

## Components

- Local cloud infrastructure
- Energy consumption monitoring stack
- Carbon emission monitoring stack
- Machine learning infrastructure and workloads
- Visualization stack
- Execution management tool

## Requirements

This project uses the [just](https://github.com/casey/just) command runner for ergonomic development. To install:

```sh
cargo install just
brew install just  # on macOS
```

## Installation

To deploy the entire stack:

```sh
just install requirements   # will download and install all necessary requirements
just deploy all             # will deploy infra, and all other components
```

To deploy specific components:

```sh
just deploy infra  # will only spin up a local cluster
just deploy [energy-monitoring|carbon-monitoring|machine-learning|visualization]
```

## Usasge

To run a workload, for example to test energy consumption or carbon emission monitoring:

```sh
just run [machine-learning]  # will run all workloads defined in machine-learning
```

If deployed, visualizations can be found at:
- [Grafana dashboard](#)

## Teardown

To clean up:

```sh
just teardown infra  # will remove the entire cluster, including applications 
just teardown [energy-monitoring|carbon-monitoring|machine-learning|visualization]
```
