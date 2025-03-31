#!/bin/bash
set -e

# Script to render template files with values from ingress-config.sh

# Source the configuration
if [ ! -f ./ingress-config.sh ]; then
  echo "Error: ingress-config.sh not found!"
  exit 1
fi

source ./ingress-config.sh

# Create output directory if it doesn't exist
OUTPUT_DIR="./rendered"
mkdir -p "$OUTPUT_DIR"

# Validation function
validate_config() {
  local has_errors=0
  
  # Domain validation
  if [ -z "$DOMAIN" ]; then
    echo "❌ ERROR: DOMAIN is empty"
    has_errors=1
  elif [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9\.-]*\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ WARNING: DOMAIN '$DOMAIN' may not be a valid domain name"
  fi
  
  # Namespace validation
  if [ -z "$DEFAULT_NAMESPACE" ]; then
    echo "❌ ERROR: DEFAULT_NAMESPACE is empty"
    has_errors=1
  elif ! kubectl get namespace "$DEFAULT_NAMESPACE" &>/dev/null; then
    echo "❌ WARNING: Namespace '$DEFAULT_NAMESPACE' does not exist in the cluster"
  fi
  
  if [ -z "$SERVICE_NAMESPACE" ]; then
    echo "❌ ERROR: SERVICE_NAMESPACE is empty"
    has_errors=1
  elif ! kubectl get namespace "$SERVICE_NAMESPACE" &>/dev/null; then
    echo "❌ WARNING: Namespace '$SERVICE_NAMESPACE' does not exist in the cluster"
  fi
  
  # Service validation
  if [ -z "$SERVICE_NAME" ]; then
    echo "❌ ERROR: SERVICE_NAME is empty"
    has_errors=1
  elif ! kubectl get service "$SERVICE_NAME" -n "$SERVICE_NAMESPACE" &>/dev/null; then
    echo "❌ WARNING: Service '$SERVICE_NAME' does not exist in namespace '$SERVICE_NAMESPACE'"
  fi
  
  # Port validation
  if [ -z "$SERVICE_PORT" ]; then
    echo "❌ ERROR: SERVICE_PORT is empty"
    has_errors=1
  elif ! [[ "$SERVICE_PORT" =~ ^[0-9]+$ ]]; then
    echo "❌ ERROR: SERVICE_PORT must be a number"
    has_errors=1
  fi
  
  # Certificate validation
  if [ -z "$CERT_EMAIL" ]; then
    echo "❌ ERROR: CERT_EMAIL is empty"
    has_errors=1
  elif [[ ! "$CERT_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ WARNING: CERT_EMAIL '$CERT_EMAIL' may not be a valid email address"
  fi
  
  if [ -z "$CERT_ISSUER" ]; then
    echo "❌ ERROR: CERT_ISSUER is empty"
    has_errors=1
  fi
  
  if [ -z "$CERT_URL" ]; then
    echo "❌ ERROR: CERT_URL is empty"
    has_errors=1
  elif [[ ! "$CERT_URL" =~ ^https://.*$ ]]; then
    echo "❌ WARNING: CERT_URL should start with https://"
  fi
  
  # Auth validation
  if [ -z "$BASIC_AUTH_USERNAME" ]; then
    echo "❌ ERROR: BASIC_AUTH_USERNAME is empty"
    has_errors=1
  fi
  
  if [ -z "$BASIC_AUTH_PASSWORD" ] || [ ${#BASIC_AUTH_PASSWORD} -lt 6 ]; then
    echo "❌ ERROR: BASIC_AUTH_PASSWORD is empty or too short (should be at least 6 characters)"
    has_errors=1
  fi
  
  # OAuth validation
  if [ -z "$OAUTH_PROVIDER" ]; then
    echo "❌ ERROR: OAUTH_PROVIDER is empty"
    has_errors=1
  elif [[ ! "$OAUTH_PROVIDER" =~ ^(github|google|gitlab|azure)$ ]]; then
    echo "❌ WARNING: OAUTH_PROVIDER '$OAUTH_PROVIDER' might not be supported"
  fi
  
  if [ -z "$OAUTH_CLIENT_ID" ] || [ ${#OAUTH_CLIENT_ID} -lt 10 ]; then
    echo "❌ ERROR: OAUTH_CLIENT_ID is empty or too short"
    has_errors=1
  fi
  
  if [ -z "$OAUTH_CLIENT_SECRET" ] || [ ${#OAUTH_CLIENT_SECRET} -lt 10 ]; then
    echo "❌ ERROR: OAUTH_CLIENT_SECRET is empty or too short"
    has_errors=1
  fi
  
  if [ -z "$OAUTH_COOKIE_SECRET" ] || [ ${#OAUTH_COOKIE_SECRET} -lt 16 ]; then
    echo "❌ ERROR: OAUTH_COOKIE_SECRET is empty or too short (should be at least 16 characters)"
    has_errors=1
  fi
  
  if [ "$OAUTH_PROVIDER" = "github" ] && [ -z "$GITHUB_ORG" ]; then
    echo "❌ WARNING: GITHUB_ORG is empty but OAUTH_PROVIDER is github"
  fi
  
  return $has_errors
}

# Validate configuration
echo "Validating configuration..."
if ! validate_config; then
  echo "❌ Validation failed. Please fix the issues above and try again."
  read -p "Continue anyway? (y/n): " continue_anyway
  if [[ "$continue_anyway" != "y" ]]; then
    exit 1
  fi
  echo "Continuing despite validation errors..."
fi

echo "Rendering templates with the following configuration:"
echo "Domain: $DOMAIN"
echo "Namespace: $DEFAULT_NAMESPACE"
echo "Service Namespace: $SERVICE_NAMESPACE"
echo "Service: $SERVICE_NAME:$SERVICE_PORT"
echo "Certificate Email: $CERT_EMAIL"
echo "Certificate Issuer: $CERT_ISSUER"
echo "Certificate URL: $CERT_URL"
echo "Basic Auth Username: $BASIC_AUTH_USERNAME"
echo "Basic Auth Password: [REDACTED]"
echo "OAuth Provider: $OAUTH_PROVIDER"
echo "OAuth Client ID: [REDACTED]"
echo "OAuth Client Secret: [REDACTED]"
echo "OAuth Cookie Secret: [REDACTED]"
echo "GitHub Organization: $GITHUB_ORG"

# Function to render a template file
render_template() {
  local template="$1"
  local output="$2"
  
  echo "Rendering $template to $output"
  
  # Create directory for output if needed
  mkdir -p "$(dirname "$output")"
  
  # Copy template to output
  cp "$template" "$output"
  
  # Use a different delimiter for sed to avoid issues with URLs containing slashes
  sed -i.bak "s#{DOMAIN}#$DOMAIN#g" "$output"
  sed -i.bak "s#{DEFAULT_NAMESPACE}#$DEFAULT_NAMESPACE#g" "$output"
  sed -i.bak "s#{SERVICE_NAMESPACE}#$SERVICE_NAMESPACE#g" "$output"
  sed -i.bak "s#{SERVICE_NAME}#$SERVICE_NAME#g" "$output"
  sed -i.bak "s#{SERVICE_PORT}#$SERVICE_PORT#g" "$output"
  sed -i.bak "s#{CERT_ISSUER}#$CERT_ISSUER#g" "$output"
  sed -i.bak "s#{CERT_EMAIL}#$CERT_EMAIL#g" "$output"
  sed -i.bak "s#{CERT_URL}#$CERT_URL#g" "$output" # This line had the issue with https:// URLs
  sed -i.bak "s#{BASIC_AUTH_USERNAME}#$BASIC_AUTH_USERNAME#g" "$output"
  sed -i.bak "s#{BASIC_AUTH_PASSWORD}#$BASIC_AUTH_PASSWORD#g" "$output"
  sed -i.bak "s#{OAUTH_CLIENT_ID}#$OAUTH_CLIENT_ID#g" "$output"
  sed -i.bak "s#{OAUTH_CLIENT_SECRET}#$OAUTH_CLIENT_SECRET#g" "$output"
  sed -i.bak "s#{OAUTH_COOKIE_SECRET}#$OAUTH_COOKIE_SECRET#g" "$output"
  sed -i.bak "s#{OAUTH_PROVIDER}#$OAUTH_PROVIDER#g" "$output"
  sed -i.bak "s#{GITHUB_ORG}#$GITHUB_ORG#g" "$output"
  
  # Remove backup files
  rm -f "$output.bak"
  
  # Make shell scripts executable
  if [[ "$output" == *.sh ]]; then
    chmod +x "$output"
  fi
}

# Render all template files
for template in templates/*.yaml templates/*.sh; do
  filename=$(basename "$template")
  render_template "$template" "$OUTPUT_DIR/$filename"
done

# Copy setup script from templates directory and render it
render_template "templates/setup-i.sh" "$OUTPUT_DIR/setup-i.sh"

# Copy any supporting files needed
cp templates/ingress-nginx-values.yaml "$OUTPUT_DIR/" 2>/dev/null || true

echo "All templates have been rendered to $OUTPUT_DIR/"
echo "You can now run the setup script from the rendered directory:"
echo "cd $OUTPUT_DIR && ./setup-i.sh"