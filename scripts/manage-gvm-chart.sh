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
if [ $# -lt 4 ]; then
    echo "Error: Missing required arguments <install|upgrade> <values-file> <parent|child> <mongodb-type> [namespace]"
    echo "Usage: ./manage-gvm-chart.sh <install|upgrade> <values-file> <parent|child> <mongodb-type> [namespace]"
    echo "  mongodb-type: 'internal' or 'external'"
    exit 1
fi

ACTION="$1"        # install or upgrade
VALUES_ARG="$2"    # values file
CHART_TYPE="$3"    # parent or child
MONGODB_TYPE="$4"  # internal or external

# Default NAMESPACE to 'default' if not supplied
NAMESPACE="${5:-default}"

VALUES_FILE="$CHART_DIR/$VALUES_ARG"

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

# MongoDB URI handling based on type
if [ "$MONGODB_TYPE" == "external" ] && [ "$CHART_TYPE" == "child" ]; then
    echo "Using external MongoDB for child chart..."
    
    # Prompt for MongoDB external connection details if not set in environment
    if [ -z "$MONGODB_USERNAME" ]; then
        read -p "Enter MongoDB username: " MONGODB_USERNAME
        if [ -z "$MONGODB_USERNAME" ]; then
            echo "Error: MongoDB username cannot be empty."
            exit 1
        fi
    fi
    
    if [ -z "$MONGODB_PASSWORD" ]; then
        read -s -p "Enter MongoDB password: " MONGODB_PASSWORD
        echo
        if [ -z "$MONGODB_PASSWORD" ]; then
            echo "Error: MongoDB password cannot be empty."
            exit 1
        fi
    fi
    
    if [ -z "$MONGODB_URI_TEMPLATE" ]; then
        read -p "Enter MongoDB URI template (e.g., mongodb+srv://<username>:<password>@hostname.example.com/): " MONGODB_URI_TEMPLATE
        if [ -z "$MONGODB_URI_TEMPLATE" ]; then
            echo "Error: MongoDB URI template cannot be empty."
            exit 1
        fi
    fi
    
    # Replace placeholders in template with actual values
    ENCODED_PASSWORD=$(url_encode "$MONGODB_PASSWORD")
    ENCODED_USERNAME=$(url_encode "$MONGODB_USERNAME")
    
    # Replace placeholders in the URI template
    MONGODB_URI="${MONGODB_URI_TEMPLATE//<username>/$ENCODED_USERNAME}"
    MONGODB_URI="${MONGODB_URI//<password>/$ENCODED_PASSWORD}"
    
    # MongoDB deployment is not needed for external MongoDB
    USE_LOCAL_MONGODB="false"
    
else
    echo "Using local/internal MongoDB..."
    
    # Prompt for local MongoDB root password if not set in the environment
    if [ -z "$MONGODB_ROOT_PASSWORD" ]; then
        read -s -p "Enter the MongoDB root password: " MONGODB_ROOT_PASSWORD
        echo
        if [ -z "$MONGODB_ROOT_PASSWORD" ]; then
            echo "Error: MongoDB root password cannot be empty."
            exit 1
        fi
    fi
    
    # Construct MongoDB URI for local deployment
    ENCODED_PASSWORD=$(url_encode "$MONGODB_ROOT_PASSWORD")
    MONGODB_URI="mongodb://root:${ENCODED_PASSWORD}@gvm-release-mongodb:27017/"
    USE_LOCAL_MONGODB="true"
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

# Application configuration prompts
if [ -z "$APP_PORT" ]; then
    read -p "Enter application port [8080]: " APP_PORT
    APP_PORT=${APP_PORT:-8080}
fi

if [ -z "$BASE_URL" ]; then
    read -p "Enter base URL for callbacks: " BASE_URL
    if [ -z "$BASE_URL" ]; then
        echo "Warning: No base URL provided. Using default localhost."
        BASE_URL="http://localhost"
    fi
fi

if [ -z "$GITHUB_APP_ID" ]; then
    read -p "Enter GitHub App ID: " GITHUB_APP_ID
    if [ -z "$GITHUB_APP_ID" ]; then
        echo "Error: GitHub App ID cannot be empty."
        exit 1
    fi
fi

if [ -z "$APP_IMAGE_REPOSITORY" ]; then
    read -p "Enter application image repository [mgunter/github-value-mongodb30]: " APP_IMAGE_REPOSITORY
    APP_IMAGE_REPOSITORY=${APP_IMAGE_REPOSITORY:-mgunter/github-value-mongodb30}
fi

if [ -z "$APP_IMAGE_TAG" ]; then
    read -p "Enter application image tag [latest]: " APP_IMAGE_TAG
    APP_IMAGE_TAG=${APP_IMAGE_TAG:-latest}
fi

# Encode webhook secret for Kubernetes secret
WEBHOOK_SECRET_B64=$(echo -n "$WEBHOOK_SECRET" | base64 | tr -d '\n')
MONGODB_URI_B64=$(echo -n "$MONGODB_URI" | base64 | tr -d '\n')

# Prompt to export variables for testing
read -p "Do you want to save these variables to env_vars.sh? [y/N]: " export_choice
if [[ "$export_choice" =~ ^[Yy]$ ]]; then
  # Define the file to store environment variables
  ENV_VARS_FILE="./env_vars.sh"

  # Write sensitive variables to the env_vars.sh file
  cat <<EOF > "$ENV_VARS_FILE"
# Environment variables for the deployment script

export MONGODB_TYPE="$MONGODB_TYPE"
EOF

  # Add appropriate variables based on MongoDB type
  if [ "$MONGODB_TYPE" == "external" ]; then
    cat <<EOF >> "$ENV_VARS_FILE"
export MONGODB_USERNAME="$MONGODB_USERNAME"
export MONGODB_PASSWORD="$MONGODB_PASSWORD"
export MONGODB_URI_TEMPLATE="$MONGODB_URI_TEMPLATE"
EOF
  else
    cat <<EOF >> "$ENV_VARS_FILE"
export MONGODB_ROOT_PASSWORD="$MONGODB_ROOT_PASSWORD"
EOF
  fi

  # Add common variables
  cat <<EOF >> "$ENV_VARS_FILE"
export MONGODB_URI="$MONGODB_URI"
export PRIVATE_KEY_FILE="$PRIVATE_KEY_FILE"
export WEBHOOK_SECRET="$WEBHOOK_SECRET"
export APP_PORT="$APP_PORT"
export BASE_URL="$BASE_URL"
export GITHUB_APP_ID="$GITHUB_APP_ID"
export APP_IMAGE_REPOSITORY="$APP_IMAGE_REPOSITORY"
export APP_IMAGE_TAG="$APP_IMAGE_TAG"
EOF

  # Add env_vars.sh to .gitignore to prevent it from being committed to version control
  if ! grep -q "^env_vars.sh$" .gitignore 2>/dev/null; then
      echo "env_vars.sh" >> .gitignore
      echo "$ENV_VARS_FILE added to .gitignore to prevent accidental inclusion in version control."
  fi

else
  echo "Environment variables not saved in local file."
fi

# Create Kubernetes Secret
kubectl create secret generic github-value-secret \
  --from-literal=MONGODB_URI="$MONGODB_URI" \
  --from-file=GITHUB_APP_PRIVATE_KEY="$PRIVATE_KEY_FILE" \
  --from-literal=GITHUB_WEBHOOK_SECRET="$WEBHOOK_SECRET" \
  --namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Create ConfigMap
echo "Creating ConfigMap with application configuration..."
kubectl create configmap github-value-config \
  --from-literal=PORT="$APP_PORT" \
  --from-literal=BASE_URL="$BASE_URL" \
  --from-literal=GITHUB_APP_ID="$GITHUB_APP_ID" \
  # --from-literal=NODE_HEAP_SIZE="8120" # Uncomment if needed, 4GB is the currrent default
  --namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Show summary of created resources
echo "Created kubernetes resources:"
echo "Secret: github-value-secret"
echo "ConfigMap: github-value-config"

# Choose which chart to operate on
if [ "$CHART_TYPE" == "parent" ]; then
    TARGET_CHART_DIR="$CHART_DIR"
    
    # Helm action for parent chart (always includes MongoDB)
    if [ "$ACTION" == "install" ]; then
        helm install gvm-release "$TARGET_CHART_DIR" -f "$VALUES_FILE" -n "$NAMESPACE"  \
            --set mongodb.auth.rootPassword="$MONGODB_ROOT_PASSWORD" \
            --set value-app-chart.app.image.repository="$APP_IMAGE_REPOSITORY" \
            --set value-app-chart.app.image.tag="$APP_IMAGE_TAG" \
            --set value-app-chart.service.targetPort="$APP_PORT" 

    elif [ "$ACTION" == "upgrade" ]; then
        helm upgrade gvm-release "$TARGET_CHART_DIR" -f "$VALUES_FILE" -n "$NAMESPACE" \
            --set mongodb.auth.rootPassword="$MONGODB_ROOT_PASSWORD" \
            --set value-app-chart.app.image.repository="$APP_IMAGE_REPOSITORY" \
            --set value-app-chart.app.image.tag="$APP_IMAGE_TAG" \
            --set value-app-chart.service.targetPort="$APP_PORT"
    else
        echo "Invalid action: $ACTION"
        exit 1
    fi
else
    TARGET_CHART_DIR="$CHART_DIR/value-app-chart"
    
    # For child chart, extract the values from value-app-chart section into temporary values file
    TEMP_VALUES_FILE=$(mktemp)
    echo "Extracting child chart values from $VALUES_FILE..."
    
    # Check if yq is installed, otherwise use alternative approach
    if command -v yq &> /dev/null; then
        yq '.value-app-chart' "$VALUES_FILE" > "$TEMP_VALUES_FILE"
        echo "Values extracted using yq."
    else
        # Find the line number where value-app-chart section starts
        START_LINE=$(grep -n "value-app-chart:" "$VALUES_FILE" | cut -d: -f1)
        if [ -z "$START_LINE" ]; then
            echo "Warning: value-app-chart section not found in $VALUES_FILE"
            # Create empty file
            touch "$TEMP_VALUES_FILE"
        else
            # Extract the value-app-chart section with proper indentation fixed
            awk "NR > $START_LINE { print }" "$VALUES_FILE" | sed 's/^  //' > "$TEMP_VALUES_FILE"
            echo "Values extracted using awk/sed."
        fi
    fi
    
    # Common parameters for child chart
    CHILD_CHART_PARAMS="--set app.image.repository=$APP_IMAGE_REPOSITORY \
                --set app.image.tag=$APP_IMAGE_TAG \
                --set service.targetPort=$APP_PORT"
    
    # Helm action for child chart (MongoDB can be external or internal)
    if [ "$ACTION" == "install" ]; then
        if [ "$MONGODB_TYPE" == "external" ]; then
            helm install gvm-release "$TARGET_CHART_DIR" -f "$TEMP_VALUES_FILE" -n "$NAMESPACE" \
                --set mongodb.enabled=false \
                $CHILD_CHART_PARAMS
        else
            helm install gvm-release "$TARGET_CHART_DIR" -f "$TEMP_VALUES_FILE" -n "$NAMESPACE" \
                --set mongodb.auth.rootPassword="$MONGODB_ROOT_PASSWORD" \
                $CHILD_CHART_PARAMS
        fi
    elif [ "$ACTION" == "upgrade" ]; then
        if [ "$MONGODB_TYPE" == "external" ]; then
            helm upgrade gvm-release "$TARGET_CHART_DIR" -f "$TEMP_VALUES_FILE" -n "$NAMESPACE" \
                --set mongodb.enabled=false \
                $CHILD_CHART_PARAMS
        else
            helm upgrade gvm-release "$TARGET_CHART_DIR" -f "$TEMP_VALUES_FILE" -n "$NAMESPACE" \
                --set mongodb.auth.rootPassword="$MONGODB_ROOT_PASSWORD" \
                $CHILD_CHART_PARAMS
        fi
    else
        echo "Invalid action: $ACTION"
        exit 1
    fi
    
    # Clean up temporary file
    rm "$TEMP_VALUES_FILE"
    echo "Temporary values file cleaned up."
fi

echo "Action '$ACTION' completed on $CHART_TYPE chart with values from $VALUES_FILE in the $NAMESPACE namespace."
echo "MongoDB connection type: $MONGODB_TYPE"
echo ""
echo "NEXT STEPS:"
echo "1. Your application is now deployed but may not be securely accessible."
echo "2. For secure access with TLS and authentication, use the nginx-ingress-stack-configurable directory:"
echo "   cd $(dirname "$CHART_DIR")/nginx-ingress-stack-configurable"
echo "3. Configure your ingress settings in ingress-config.sh, run ./render-template.sh and then cd to rendered/ and run the setup script:"
echo "   ./setup-i.sh"
echo "4. This will set up nginx-ingress controller, cert-manager, and provide options for basic auth or OAuth via GitHub."
