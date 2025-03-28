#!/bin/bash

echo "Checking web deployment status..."
kubectl get deployment web -n default

echo "Checking web service status..."
kubectl get service web -n default

echo "Checking service endpoints..."
kubectl get endpoints web -n default

echo "Checking ingress status..."
kubectl get ingress -n default

echo "Checking OAuth2 Proxy status..."
kubectl get pods -l app=oauth2-proxy
echo "Checking OAuth2 Proxy logs..."
kubectl logs -l app=oauth2-proxy --tail=50

echo "Checking nginx ingress controller logs..."
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=50
