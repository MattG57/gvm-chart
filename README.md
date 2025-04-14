# GitHub Value and MongoDB Chart ( 4/2025 release)

This repository contains a Helm chart for deploying a GitHub Value application alongside a MongoDB instance. The MongoDB chart is included as a dependency. The parent chart or the child chart can be used via the manage script.

[Watch the Getting Started Video](https://raw.githubusercontent.com/MattG57/gvm-chart/main/Getting%20Started%20video.mp4)

## Prerequisites
- A Kubernetes cluster (AKS, GKE, EKS, etc.).
- Helm 3.x installed and configured.
- kubectl configured with cluster access.

## Network Diagram
<img width="1115" alt="image" src="https://github.com/user-attachments/assets/fd95b638-a2f2-4fe0-9a4e-46159167eeea" />


## Repository Structure
```
.
├── Chart.lock
├── Chart.yaml
├── Getting Started video.mp4
├── README.md
├── aks-values.yaml
├── build
│   ├── Dockerfile
│   ├── Dockerfile-single-stage
│   ├── build.sh
│   └── entrypoint.sh
├── charts
│   ├── mongodb-16.4.1.tgz
│   └── value-app-chart-0.1.0.tgz
├── config-flow-analysis.md
├── env_vars.sh
├── env_vars.sh.meli
├── gke-values.yaml
├── how-to-format-pem-file.txt
├── nginx-ingress-stack-configurable
│   ├── README.md
│   ├── image-1.png
│   ├── image-2.png
│   ├── image-3.png
│   ├── image-4.png
│   ├── image.png
│   ├── ingress-config-example.sh
│   ├── ingress-config.sh
│   ├── render-templates.sh
│   └── templates
│       ├── app-ingress-basic.yaml
│       ├── app-ingress-oauth.yaml
│       ├── app-ingress-simple.yaml
│       ├── check-oauth-connectivity.sh
│       ├── cluster-issuer.yaml
│       ├── create-temp-cert.sh
│       ├── create_pw.sh
│       ├── ingress-nginx-values.yaml
│       ├── install-cert-manager.sh
│       ├── install-ingress-nginx.sh
│       ├── install-oauth2-proxy.sh
│       ├── oauth-ingress.yaml
│       ├── oauth2-proxy-values.yaml
│       ├── setup-i.sh
│       ├── test-deployment.yaml
│       └── troubleshoot.sh
├── operational-notes.md
├── premium-retain.yaml
├── scripts
│   ├── config-replica-endpts.sh
│   ├── install-cert-manager.sh
│   ├── manage-gvm-chart.sh
│   ├── mongodb-external-service.yaml
│   ├── reconfig.js
│   └── setup-helm.sh
├── templates
│   ├── ingress.yaml
│   ├── mongodb-pvc.yaml
│   └── premium-retain.yaml
└── value-app-chart
    ├── Chart.yaml
    └── templates
        ├── _helpers.tpl
        ├── app-deployment.yaml
        ├── service.yaml
        └── serviceaccount.yaml

9 directories, 57 files
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
Usage: ./manage-gvm-chart.sh <install|upgrade> <values-file> <parent|child> <mongodb-type> [namespace]
  mongodb-type: 'local' or 'external'
```
Example for installing the parent (umbrella) chart using GKE values:
```bash
./scripts/manage-gvm-chart.sh install gke-values.yaml parent internal
```
Or upgrading the child chart for AKS in a custom namespace:
```bash
./scripts/manage-gvm-chart.sh upgrade aks-values.yaml child external mynamespace
```
By default, the namespace is “default.”

## Configuration & Secrets
The manage-gvm-chart.sh script prompts for all configuration and handles sensitive information securely (e.g., MONGODB_ROOT_PASSWORD, private keys) so that they are never stored directly in the values.yaml file. Non-sensitive configurations such as application ID, port numbers, and basic environment-specific settings are also managed through the startup script to avoid confusion.  
Note: The script optionally saves all of this config in a env_vars.sh file which is convenient for repeated installs or upgrades, but reduces security so remember to save this file to a secure location and delete it from the repo folder. (env_vars.sh is ignored by .gitignore)

## Additional MongoDB Configuration
• config-replica-endpts.sh reconfigures the MongoDB replica set with external endpoints when using a LoadBalancer.  
• mongodb-external-service.yaml can be applied to expose MongoDB externally for certain use cases.

## Operational Guidance
. The operational-notes.md file describes critical operational considerations for PVs, Backup, and data lifecycle customization options.

## License
MIT
