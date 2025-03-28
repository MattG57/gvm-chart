#!/bin/bash

echo "Checking actual OAuth2 proxy service name..."
kubectl get services | grep oauth

echo "Updating app-ingress-oauth.yaml with correct service name..."
SERVICE_NAME=$(kubectl get services | grep oauth | awk '{print $1}')
if [ -z "$SERVICE_NAME" ]; then
  echo "Error: No OAuth service found!"
  exit 1
else
  echo "Found OAuth service: $SERVICE_NAME"
  
  # Get namespace
  NAMESPACE=$(kubectl get service $SERVICE_NAME -o jsonpath='{.metadata.namespace}')
  echo "Service namespace: $NAMESPACE"
  
  # Update app-ingress-oauth.yaml with correct service reference
  sed -i.bak "s|nginx.ingress.kubernetes.io/auth-url: \"http://oauth2.default.svc.cluster.local/oauth2/auth\"|nginx.ingress.kubernetes.io/auth-url: \"http://$SERVICE_NAME.$NAMESPACE.svc.cluster.local/oauth2/auth\"|g" app-ingress-oauth.yaml
  
  echo "Updated app-ingress-oauth.yaml with correct service reference"
  echo "New auth-url value:"
  grep auth-url app-ingress-oauth.yaml
fi
