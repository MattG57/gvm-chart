#!/bin/bash

if [ -f "./env_vars.sh" ]; then
    set -a && source ./env_vars.sh && set +a
    echo "Environment variables loaded from env_vars.sh."
else
    echo "env_vars.sh not found. Skipping loading environment variables."
fi

# Get directory of the script and navigate to chart directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

# Check if the values file argument is provided
if [ $# -ne 1 ]; then
    echo "Error: Missing required argument <values-file>"
    echo "Usage: ./deploy-gvm-chart.sh <values-file>"
    echo "Example: ./deploy-gvm-chart.sh aks-values.yaml"
    exit 1
fi

VALUES_FILE="$CHART_DIR/$1"

# Check if the values file exists
if [ ! -f "$VALUES_FILE" ]; then
    echo "Error: Values file '$VALUES_FILE' not found"
    exit 1
fi

# Function to URL-encode a string
url_encode() {
    local encoded=""
    local length="${#1}"
    for ((i = 0; i < length; i++)); do
        local c="${1:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) encoded+="$c" ;;
            *) encoded+=$(printf '%%%02X' "'$c") ;;
        esac
    done
    echo "$encoded"
}

# Prompt for sensitive data if not set in the environment
if [ -z "$MONGODB_ROOT_PASSWORD" ]; then
    read -s -p "Enter the MongoDB root password: " MONGODB_ROOT_PASSWORD
    echo
    if [ -z "$MONGODB_ROOT_PASSWORD" ]; then
        echo "Error: MongoDB root password cannot be empty."
        exit 1
    fi
fi

# Prompt for the GitHub App private key file path if not set in the environment
if [ -z "$PRIVATE_KEY_FILE" ]; then
    read -p "Enter path to GitHub App private key file: " PRIVATE_KEY_FILE
    if [ ! -f "$PRIVATE_KEY_FILE" ]; then
        echo "Error: Private key file '$PRIVATE_KEY_FILE' not found."
        exit 1
    fi
fi

# Prompt for the GitHub webhook secret if not set in the environment
if [ -z "$WEBHOOK_SECRET" ]; then
    read -s -p "Enter the GitHub webhook secret: " WEBHOOK_SECRET
    echo
    if [ -z "$WEBHOOK_SECRET" ]; then
        echo "Error: GitHub webhook secret cannot be empty."
        exit 1
    fi
fi



# Encode values
ENCODED_PASSWORD=$(url_encode "$MONGODB_ROOT_PASSWORD")
WEBHOOK_SECRET_B64=$(echo -n "$WEBHOOK_SECRET" | base64 | tr -d '\n')

# Construct MongoDB URI
MONGODB_URI="mongodb://root:${ENCODED_PASSWORD}@gvm-release-mongodb:27017/"

MONGODB_URI_B64=$(echo -n "$MONGODB_URI" | base64 | tr -d '\n')
# Prompt to export variables for testing
read -p "Do you want to save these variables to env_vars.sh? [y/N]: " export_choice
if [[ "$export_choice" =~ ^[Yy]$ ]]; then
  # Define the file to store environment variables
  ENV_VARS_FILE="./env_vars.sh"

  # Write sensitive variables to the env_vars.sh file
cat <<EOF > "$ENV_VARS_FILE"
# Environment variables for the deployment script

export MONGODB_ROOT_PASSWORD="$MONGODB_ROOT_PASSWORD"
export MONGODB_URI="$MONGODB_URI"
export PRIVATE_KEY_FILE="$PRIVATE_KEY_FILE"
export WEBHOOK_SECRET="$WEBHOOK_SECRET"
EOF

  # Add env_vars.sh to .gitignore to prevent it from being committed to version control
  if ! grep -q "^env_vars.sh$" .gitignore; then
      echo "env_vars.sh" >> .gitignore
      echo "$ENV_VARS_FILE added to .gitignore to prevent accidental inclusion in version control."
  fi

else
  echo "Environment variables not exported."
fi


# Create Kubernetes Secret
kubectl create secret generic github-value-secret \
  --from-literal=MONGODB_URI="$MONGODB_URI" \
  --from-file=GITHUB_APP_PRIVATE_KEY="$PRIVATE_KEY_FILE" \
  --from-literal=GITHUB_WEBHOOK_SECRET="$WEBHOOK_SECRET" \
  --namespace default --dry-run=client -o yaml | kubectl apply -f -

# Deploy MongoDB with Helm
helm install gvm-release "$CHART_DIR" -f "$VALUES_FILE" -n default --set mongodb.auth.rootPassword="$MONGODB_ROOT_PASSWORD" #--dry-run --debug

echo " github-value-secret created in defaut Namespace,  $CHART_DIR gvm-release initiated"
