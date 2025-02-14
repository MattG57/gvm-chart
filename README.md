# GitHub Value and MongoDB Chart ( 2/2025 release)

This repository contains a Helm chart for deploying a GitHub Value application alongside a MongoDB instance. The MongoDB chart is included as a dependency.

[Watch the Getting Started Video](https://raw.githubusercontent.com/MattG57/gvm-chart/main/Getting%20Started%20video.mp4)

## Prerequisites
- A Kubernetes cluster (AKS, GKE, etc.).
- Helm 3.x installed and configured.
- kubectl configured with cluster access.

## Network Diagram
<img width="1115" alt="image" src="https://github.com/user-attachments/assets/fd95b638-a2f2-4fe0-9a4e-46159167eeea" />


## Repository Structure
```
.
├── Chart.yaml # umbrella/parent chart
├── README.md
├── aks-values.yaml
├── gke-values.yaml
├── build/
│   ├── Dockerfile
│   ├── build.sh  # builds the docker image for the app 
│   └── entrypoint.sh
├── env_vars.sh    #temporary storage of secrets when testing, is not tracked by github
├── operational-notes.md
├── scripts/
│   ├── config-replica-endpts.sh  # necessary when deploying mongodb as a replicaset
│   ├── manage-gvm-chart.sh       (active script for install/upgrade)
│   ├── mongodb-external-service.yaml
│   ├── reconfig.js   # example input to the config-replica-endpts.sh script
│   ├── setup-helm.sh
└── value-app-chart/
    ├── Chart.yaml  #child/app chart
    ├── templates/
    │   ├── _helpers.tpl
    │   ├── app-deployment.yaml
    │   ├── configmap-github-value.yaml
    │   ├── service.yaml
    │   └── serviceaccount.yaml
    └── values.yaml
```

## Setting Up Helm
Before deploying, initialize Helm and add any required repositories:
```bash
./scripts/setup-helm.sh
```

## Using the Manage Script
Use the “manage-gvm-chart.sh” script to install or upgrade the chart. This script will also prompt for required environment variables.

Syntax:
```bash
./scripts/manage-gvm-chart.sh <install|upgrade> <values-file> <parent|child> [namespace]
```
Example for installing the parent (umbrella) chart using GKE values:
```bash
./scripts/manage-gvm-chart.sh install gke-values.yaml parent
```
Or upgrading the child chart for AKS in a custom namespace:
```bash
./scripts/manage-gvm-chart.sh upgrade aks-values.yaml child my-namespace
```
By default, the namespace is “default.”

## Configuration & Secrets
The manage-gvm-chart.sh script prompts for sensitive information (e.g., MONGODB_ROOT_PASSWORD, private keys) so that they are never stored directly in the values.yaml file. Non-sensitive configurations such as application ID, port numbers, and basic environment-specific settings remain in the chart's values.yaml files.

## Additional MongoDB Configuration
• config-replica-endpts.sh reconfigures the MongoDB replica set with external endpoints when using a LoadBalancer.  
• mongodb-external-service.yaml can be applied to expose MongoDB externally for certain use cases.

## Operational Guidance
. The operational-notes.md file describes critical operational considerations for PVs, Backup, and data lifecycle customization options.

## License
MIT
