# Configurable Nginx Ingress Setup

This directory contains a templating system for setting up Nginx Ingress with flexible authentication options.

## Configuration

Edit the `ingress-config.sh` file to configure:

- Domain name for ingress resources
- Kubernetes namespace
- Application service and port
- Certificate issuer settings
- Basic authentication credentials 
- OAuth2 Provider settings

## Usage

1. Edit `ingress-config.sh` with your specific settings
2. Run the template rendering script:
   ```bash
   ./render-templates.sh
   ```
3. Navigate to the rendered directory and run the setup script:
   ```bash
   cd rendered
   ./setup-i.sh
   ```

To start from a specific step:
```bash
./setup-i.sh 5  # Start from step 5
```

## Components

- Nginx Ingress Controller
- Cert-Manager with Let's Encrypt integration
- Basic authentication
- OAuth2 authentication (GitHub, Google, etc.)
- Sample web application

## Authentication Options

Two authentication methods are set up:
1. **Basic Auth**: Username/password authentication (configured in `ingress-config.sh`)
2. **OAuth2**: OAuth authentication (requires valid OAuth app registration)

## Verification

After setup, you can run:
```bash
./verify-oauth-service.sh
```
to validate the OAuth2 service configuration.

## Troubleshooting

If you encounter issues, run:
```bash
./troubleshoot.sh
```
to collect diagnostic information.

## Customization

The template system allows you to easily customize all aspects of the deployment by:

1. Modifying the `ingress-config.sh` file with your specific values
2. Running `render-templates.sh` to generate a custom configuration
3. Deploying the customized configuration

This approach makes it easy to manage multiple environments with different settings.
