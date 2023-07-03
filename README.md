# Sustainable Computing Sandbox

🌱 Experimental environment to develop on energy- and carbon-aware cloud-native software. 

## 📦 Components

- Local cloud infrastructure
- Energy consumption monitoring stack
- Carbon emission monitoring stack
- Machine learning infrastructure and workloads
- Visualization stack
- Execution management tool

## 📋 Requirements

This project uses the [just](https://github.com/casey/just) command runner for ergonomic development. To install with [cargo](https://doc.rust-lang.org/cargo/getting-started/installation.html):

```sh
cargo install just
```

## 🛠️ Installation

To deploy the entire stack:

```sh
just install requirements   # download and install all necessary requirements
just deploy all             # deploy infra, and all other components
```

To deploy specific components:

```sh
just deploy infra  # spin up a local cluster, without deploying other components
just deploy [energy-monitoring|carbon-monitoring|machine-learning|visualization]
```

## ⚡ Usage

To run a workload, for example to test energy consumption or carbon emission monitoring:

```sh
just run [machine-learning]  # run all workloads defined in machine-learning
```

If deployed, visualizations can be found at:
- [Kepler Grafana dashboard](http://localhost:3000/d/NhnADUW4z/kepler-exporter-dashboard)

## 🧹 Teardown

To clean up:

```sh
just teardown infra  # remove the entire cluster, including other components 
just teardown [energy-monitoring|carbon-monitoring|machine-learning|visualization]
```
