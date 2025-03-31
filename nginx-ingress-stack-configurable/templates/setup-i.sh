#!/bin/bash
set -e

# Process command line argument for starting step (default to 0)
start_step=0
if [ $# -gt 0 ]; then
  if [[ $1 =~ ^[0-9]+$ ]]; then
    start_step=$((($1 - 1)))  # Convert to 0-based index
    if [ $start_step -lt 0 ]; then
      start_step=0
    fi
  else
    echo "Error: Starting step must be a positive number."
    exit 1
  fi
fi

steps=(
  "Install cert-manager CRDs|kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.2/cert-manager.crds.yaml|kubectl get crds -n {DEFAULT_NAMESPACE}| grep cert-manager"
  "Create ClusterIssuer|kubectl apply -f cluster-issuer.yaml -n {DEFAULT_NAMESPACE}|kubectl get ClusterIssuer -n {DEFAULT_NAMESPACE}"
  "Install cert-manager|./install-cert-manager.sh|kubectl get pods -n cert-manager"
  "Create temporary TLS certificate|bash ./create-temp-cert.sh|kubectl get secret tls-secret -n {DEFAULT_NAMESPACE}"
  "Install nginx ingress controller|./install-ingress-nginx.sh|kubectl get pods -n ingress-nginx"
  " Configure DNS for controller external IP|kubectl get svc -n ingress-nginx|echo 'Confirm Loadbalancer was created and Configure DNS for controller external IP'"
  "Create basic auth secret|./create_pw.sh|kubectl get secret basic-auth-secret -n {DEFAULT_NAMESPACE}"
  "Deploy test web application| kubectl apply -f test-deployment.yaml |kubectl get svc {SERVICE_NAME} -n {SERVICE_NAMESPACE} && kubectl get endpoints {SERVICE_NAME} -n {SERVICE_NAMESPACE}"
  "Wait for controller cache to sync|sleep 30|echo 'Waited 30 seconds for controller cache to sync'"
  "Apply simple test ingress|kubectl apply -f app-ingress-simple.yaml |kubectl describe ingress simple-ingress "
  "Delete simple test ingress |kubectl delete -f app-ingress-simple.yaml |kubectl get ingress simple-ingress "
  "Apply basic-auth ingress|kubectl apply -f app-ingress-basic.yaml|kubectl describe ingress app-ingress-basic "
  "Delete basic-auth ingress |kubectl delete -f app-ingress-basic.yaml |kubectl get ingress app-ingress-basic "
  "Install oauth2-proxy|./install-oauth2-proxy.sh|kubectl get pods -l app=oauth2-proxy -n {DEFAULT_NAMESPACE}"
  "Apply app ingress with oauth|kubectl apply -f app-ingress-oauth.yaml |kubectl describe ingress app-ingress-oauth "
  "Apply app ingress for oauth traffic|kubectl apply -f oauth-ingress.yaml -n {DEFAULT_NAMESPACE}|kubectl describe ingress oauth-ingress -n {DEFAULT_NAMESPACE}"
)

if [ $start_step -ge ${#steps[@]} ]; then
  echo "Error: Starting step ($((start_step+1))) exceeds total steps (${#steps[@]})."
  exit 1
fi

echo "Starting from step $((start_step+1)): $(echo "${steps[$start_step]}" | cut -d'|' -f1)"

for i in $(seq $start_step $((${#steps[@]}-1))); do
  IFS='|' read -r desc cmd confirm <<< "${steps[$i]}"
  echo -e "\nStep $((i+1)): $desc"
  echo "+ $cmd"
  eval "$cmd"
  echo -e "\nConfirm:\n$confirm"
  
  # Get the next step description if available
  if [ $((i+1)) -lt ${#steps[@]} ]; then
    next_step_desc=$(echo "${steps[$((i+1))]}" | cut -d'|' -f1)
    read -p "Proceed with $((i+2)) [$next_step_desc]? (y/n): " yn
  else
    read -p "Complete setup? (y/n): " yn
  fi
  
  if [[ $yn != "y" ]]; then echo "Exiting..."; exit 1; fi
done

echo "Setup completed successfully."