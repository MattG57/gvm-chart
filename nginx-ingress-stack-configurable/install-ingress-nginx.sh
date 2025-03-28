helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm uninstall nginx --namespace ingress-nginx --ignore-not-found=true
helm install nginx ingress-nginx/ingress-nginx \
  -f "$(dirname "$0")/ingress-nginx-values.yaml" --namespace ingress-nginx --create-namespace
