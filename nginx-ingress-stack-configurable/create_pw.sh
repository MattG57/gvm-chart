#!/bin/bash

# Ensure secrets directory exists
mkdir -p secrets

# TBD: parameterize username and password
htpasswd -nb admin abc123 > secrets/basic-auth.htpasswd

# Make sure we create basic-auth-secret (note the name matches the annotation in the ingress)
kubectl delete secret basic-auth-secret --ignore-not-found=true -n default # TBD: namespace
kubectl create secret generic basic-auth-secret \
  --from-file=auth=secrets/basic-auth.htpasswd \
  --namespace default # TBD: namespace
