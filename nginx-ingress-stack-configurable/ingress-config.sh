#!/bin/bash

# DNS Configuration
DOMAIN="www.gvm-chart.com"

# Namespace Configuration
DEFAULT_NAMESPACE="default" # Namespace for the test application and oauth pods (in addition to cert-manager and nginx-ingress namespaces)

# Application Service Configuration
SERVICE_NAMESPACE="default" # Namespace where the existing application to be secured is deployed
SERVICE_NAME="gvm-release-value-app-chart"
SERVICE_PORT="80"

# Certificate Configuration
CERT_EMAIL="mgunter@gmail.com"
CERT_ISSUER="letsencrypt"  # letsencrypt-stage or letsencrypt-prod
CERT_URL="https://acme-v02.api.letsencrypt.org/directory" # or use https://acme-staging-v02.api.letsencrypt.org/directory for testing
#CERT_URL="https://acme-staging-v02.api.letsencrypt.org/directory" # or use https://acme-v02.api.letsencrypt.org/directory for production


# Basic Auth Configuration
BASIC_AUTH_USERNAME="admin"
BASIC_AUTH_PASSWORD="abc123"

# OAuth Configuration
OAUTH_CLIENT_ID="Iv23ctTOujmWo7QF5hdH"
OAUTH_CLIENT_SECRET="d12e2229a190bc7b35c561a0bf7ffa67aafee0b7"
OAUTH_COOKIE_SECRET="8bcd9d2851c7a49f59f85096b2dab1d9"
OAUTH_PROVIDER="github"
GITHUB_ORG="octodemo"
