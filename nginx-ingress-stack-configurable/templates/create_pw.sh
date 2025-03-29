#!/bin/bash

# Ensure secrets directory exists
mkdir -p secrets

# Use the configured username and password
htpasswd -nb {BASIC_AUTH_USERNAME} {BASIC_AUTH_PASSWORD} > secrets/basic-auth.htpasswd

# Make sure we create basic-auth-secret (note the name matches the annotation in the ingress)
kubectl delete secret basic-auth-secret --ignore-not-found=true -n {DEFAULT_NAMESPACE}
kubectl create secret generic basic-auth-secret \
  --from-file=auth=secrets/basic-auth.htpasswd \
  --namespace {DEFAULT_NAMESPACE}
