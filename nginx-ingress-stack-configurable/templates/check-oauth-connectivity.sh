#!/bin/bash

echo "Checking OAuth2 proxy service details..."
kubectl get service oauth2 -o wide

echo "Verifying OAuth2 proxy endpoints..."
kubectl get endpoints oauth2

echo "Creating temporary debug pod to test connectivity..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
  namespace: {DEFAULT_NAMESPACE}
spec:
  containers:
  - name: debug
    image: curlimages/curl
    command: ["/bin/sh", "-c", "sleep 3600"]
EOF

echo "Waiting for debug pod to be ready..."
kubectl wait --for=condition=ready pod debug-pod --timeout=60s

echo "Testing connectivity to OAuth2 proxy service..."
kubectl exec debug-pod -- curl -v http://oauth2.{DEFAULT_NAMESPACE}.svc.cluster.local/ping

echo "Cleaning up debug pod..."
kubectl delete pod debug-pod
