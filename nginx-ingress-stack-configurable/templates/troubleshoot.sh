#!/bin/bash

echo "Checking web deployment status..."
kubectl get deployment {SERVICE_NAME} -n {DEFAULT_NAMESPACE}

echo "Checking web service status..."
kubectl get service {SERVICE_NAME} -n {DEFAULT_NAMESPACE}

echo "Checking service endpoints..."
kubectl get endpoints {SERVICE_NAME} -n {DEFAULT_NAMESPACE}

echo "Checking ingress status..."
kubectl get ingress -n {DEFAULT_NAMESPACE}

echo "Checking OAuth2 Proxy status..."
kubectl get pods -l app=oauth2-proxy
echo "Checking OAuth2 Proxy logs..."
kubectl logs -l app=oauth2-proxy --tail=50

echo "Checking nginx ingress controller logs..."
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=50
