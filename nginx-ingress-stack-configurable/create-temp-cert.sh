#!/bin/bash

# Create a directory for certificates
mkdir -p ./tmp-certs

# Generate a self-signed certificate with proper domain name
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ./tmp-certs/tls.key \
  -out ./tmp-certs/tls.crt \
  -subj "/CN=www.gvm-chart.com" \
  -addext "subjectAltName = DNS:www.gvm-chart.com"

# Delete existing secret if it exists
kubectl delete secret tls-secret --ignore-not-found=true --namespace default

# Create the TLS secret in Kubernetes
kubectl create secret tls tls-secret \
  --key ./tmp-certs/tls.key \
  --cert ./tmp-certs/tls.crt \
  --namespace default

# Clean up temporary files
rm -rf ./tmp-certs

echo "Created temporary self-signed TLS secret 'tls-secret' for www.gvm-chart.com"
