#!/bin/bash

helm repo add oauth2-proxy https://oauth2-proxy.github.io/manifests
helm repo update

# More thorough cleanup
kubectl delete deployment -l app=oauth2-proxy --ignore-not-found=true
kubectl delete service -l app=oauth2-proxy --ignore-not-found=true
kubectl delete pod -l app=oauth2-proxy --ignore-not-found=true
kubectl delete cm -l app=oauth2-proxy --ignore-not-found=true
helm uninstall oauth2 --ignore-not-found=true

# Install with updated configuration
helm install oauth2 oauth2-proxy/oauth2-proxy \
  --namespace default \
  --values oauth2-proxy-values.yaml

# Wait for the pod to be ready
echo "Waiting for OAuth2 Proxy pod to be ready..."
kubectl wait --for=condition=ready pod -l app=oauth2-proxy --timeout=60s || true

# Get the actual service name
echo "Checking OAuth2 Proxy service name:"
OAUTH_SVC=$(kubectl get svc -l app=oauth2-proxy -o jsonpath='{.items[0].metadata.name}')
echo "Service name: $OAUTH_SVC"

echo "Checking OAuth2 Proxy logs:"
kubectl logs -l app=oauth2-proxy --tail=20 || true
