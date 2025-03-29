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

echo "Rendering templates with the following configuration:"
echo "Domain: $DOMAIN"
echo "Namespace: $DEFAULT_NAMESPACE"
echo "Service: $SERVICE_NAME:$SERVICE_PORT"
echo "Certificate Issuer: $CERT_ISSUER"
echo "OAuth Provider: $OAUTH_PROVIDER"

# Function to render a template file
render_template() {
  local template="$1"
  local output="$2"
  
  echo "Rendering $template to $output"
  
  # Create directory for output if needed
  mkdir -p "$(dirname "$output")"
  
  # Copy template to output
  cp "$template" "$output"
  
  # Replace placeholders with actual values
  sed -i.bak "s/{DOMAIN}/$DOMAIN/g" "$output"
  sed -i.bak "s/{DEFAULT_NAMESPACE}/$DEFAULT_NAMESPACE/g" "$output"
  sed -i.bak "s/{SERVICE_NAME}/$SERVICE_NAME/g" "$output"
  sed -i.bak "s/{SERVICE_PORT}/$SERVICE_PORT/g" "$output"
  sed -i.bak "s/{CERT_ISSUER}/$CERT_ISSUER/g" "$output"
  sed -i.bak "s/{CERT_EMAIL}/$CERT_EMAIL/g" "$output"
  sed -i.bak "s/{BASIC_AUTH_USERNAME}/$BASIC_AUTH_USERNAME/g" "$output"
  sed -i.bak "s/{BASIC_AUTH_PASSWORD}/$BASIC_AUTH_PASSWORD/g" "$output"
  sed -i.bak "s/{OAUTH_CLIENT_ID}/$OAUTH_CLIENT_ID/g" "$output"
  sed -i.bak "s/{OAUTH_CLIENT_SECRET}/$OAUTH_CLIENT_SECRET/g" "$output"
  sed -i.bak "s/{OAUTH_COOKIE_SECRET}/$OAUTH_COOKIE_SECRET/g" "$output"
  sed -i.bak "s/{OAUTH_PROVIDER}/$OAUTH_PROVIDER/g" "$output"
  
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
