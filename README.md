# GitHub Value and MongoDB Chart

This Helm chart deploys the GitHub Value tracking application with MongoDB using Bitnami's MongoDB chart as a dependency.

## Prerequisites
- Kubernetes cluster (AKS, GKE, or other)
- Helm 3.x installed
- kubectl configured with cluster access

# Repository Structure
```
github-value-and-mongo-chart/
├── Chart.yaml
├── aks-values.yaml        # AKS-specific values
├── gke-values.yaml        # GKE-specific values
├── scripts/              # Common scripts for both environments
│   ├── config-replica-endpts.sh
│   ├── deploy-mongo.sh
│   ├── mongodb-external-service.yaml
│   ├── reconfig.js
│   └── setup-helm.sh
└── README.md
```


## Installation


Initialize Helm and add repositories
./scripts/setup-helm.sh

## For GKE Deployment (Uses standard storage class)
``` ./scripts/deploy-mongo.sh gke-values.yaml ```

## For AKS Deployment (Uses managed-csi storage class, and optionally, an external loadbalancer)
``` ./scripts/deploy-mongo.sh aks-values.yaml ```
- [Optional: modify the mongodb-external-service.yaml to include the client side ip addresses for any external mongodb client applications.]
  
``` kubetl apply -f ./scripts/mongodb-external-service.yaml ```

## Post install Configuration
``` kubectl get services ```
- [based on the listed external ip addresses create the reconfig.js file.]
  
``` ./config-replica-endpts.sh ```
- This Configures the MongoDB replica set to use external LoadBalancer endpoints in client-side urls.

## Scripts
``` ./config-replica-endpts.sh ```
- Configures the MongoDB replica set to use external LoadBalancer endpoints for communication.

``` ./setup-helm.sh ```
- Initializes Helm and adds required chart repositories.
### License
MIT
