#!/bin/bash

# DNS Configuration
DOMAIN="www.gvm-chart.com"

# Namespace Configuration
DEFAULT_NAMESPACE="default"

# Application Service Configuration
SERVICE_NAME="gvm-release-value-app-chart"
SERVICE_PORT="80"

# Certificate Configuration
CERT_EMAIL="mgunter@gmail.com"
CERT_ISSUER="letsencrypt"  # letsencrypt-stage or letsencrypt-prod
CERT_URL="https://acme-v02.api.letsencrypt.org/directory" # or use https://acme-staging-v02.api.letsencrypt.org/directory for testing

# Basic Auth Configuration
BASIC_AUTH_USERNAME="admin"
BASIC_AUTH_PASSWORD="__c___"

# OAuth Configuration
OAUTH_CLIENT_ID="Ov23ctali        VGTJ"
OAUTH_CLIENT_SECRET="dae97c55f09228ecadcd8           60120fd1"
OAUTH_COOKIE_SECRET="8bcd9d2851c                  b1d9"
OAUTH_PROVIDER="github"
GITHUB_ORG="octodemo"
