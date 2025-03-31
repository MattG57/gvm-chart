#!/bin/bash

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set global.leaderElection.namespace=cert-manager \
  --create-namespace \
  --version v1.14.2 \
  --set installCRDs=false \
  --set controller.resources.requests.memory=128Mi \
  --set controller.resources.requests.cpu=100m \
  --set controller.resources.limits.memory=256Mi \
  --set controller.resources.limits.cpu=200m \
  --set webhook.resources.requests.memory=64Mi \
  --set webhook.resources.requests.cpu=50m \
  --set webhook.resources.limits.memory=128Mi \
  --set webhook.resources.limits.cpu=100m \
  --set cainjector.resources.requests.memory=64Mi \
  --set cainjector.resources.requests.cpu=50m \
  --set cainjector.resources.limits.memory=128Mi \
  --set cainjector.resources.limits.cpu=100m

