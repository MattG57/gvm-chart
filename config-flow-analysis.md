# Configuration Flow Analysis

This document traces how configuration values are defined and propagated through the GitHub Value Metrics (GVM) application deployment process.

## Configuration Flow Table

| Configuration Item | Initial Definition | Kubernetes Object | Pod Environment Variable | Notes |
|-------------------|-------------------|-------------------|--------------------------|-------|
| **MongoDB Configuration** | | | | |
| MongoDB URI | Generated in `manage-gvm-chart.sh` using password prompt or env var | Secret: `github-value-secret` | `MONGODB_URI` | URL-encoded password, generated differently for local vs external |
| MongoDB Root Password | Prompted in `manage-gvm-chart.sh` | Secret: implicitly used | N/A | Used to generate MongoDB URI for local deployment |
| MongoDB Username | Prompted in `manage-gvm-chart.sh` (external only) | N/A | Part of `MONGODB_URI` | Only used with external MongoDB |
| MongoDB Service Name | `gke-values.yaml`: `mongodb.service.name` | Service: `gvm-release-mongodb` | N/A | Used for internal DNS resolution |
| MongoDB Port | `gke-values.yaml`: `mongodb.service.port` | Service port: `27017` | N/A | Part of MongoDB URI |
| **GitHub App Configuration** | | | | |
| GitHub App ID | Prompted in `manage-gvm-chart.sh` | ConfigMap: `github-value-config` | `GITHUB_APP_ID` | Now configured in manage script |
| GitHub App Private Key | Prompted in `manage-gvm-chart.sh` | Secret: `github-value-secret` | File mounted from secret | File-based secret |
| GitHub Webhook Secret | Prompted in `manage-gvm-chart.sh` | Secret: `github-value-secret` | `GITHUB_WEBHOOK_SECRET` | |
| **Application Configuration** | | | | |
| Port | Prompted in `manage-gvm-chart.sh` | ConfigMap: `github-value-config` | `PORT` | Must match service targetPort |
| Base URL | Prompted in `manage-gvm-chart.sh` | ConfigMap: `github-value-config` | `BASE_URL` | External URL for callbacks |
| Image Repository | Prompted in `manage-gvm-chart.sh` | Set via helm --set | N/A | Default: mgunter/github-value-mongodb30 |
| Image Tag | Prompted in `manage-gvm-chart.sh` | Set via helm --set | N/A | Default: latest |
| Service Type | `gke-values.yaml`: `value-app-chart.service.type` | Service type: `LoadBalancer` | N/A | |
| Service Port | `gke-values.yaml`: `value-app-chart.service.port` | Service port: `80` | N/A | |
| Target Port | Prompted in `manage-gvm-chart.sh` | Set via helm --set | N/A | Matches PORT config value (default: 8080) |
| Node Port | `gke-values.yaml`: `value-app-chart.service.nodePort` | Service nodePort: `30080` | N/A | Only used with NodePort service type |
| Replica Count | `gke-values.yaml`: `value-app-chart.replicaCount` | Deployment replicas: `1` | N/A | |
| Image Pull Policy | `gke-values.yaml`: `value-app-chart.app.image.pullPolicy` | Deployment imagePullPolicy | N/A | |
| Command | `gke-values.yaml`: `value-app-chart.app.command` | Deployment command | N/A | How the application starts |
| **Resource Configuration** | | | | |
| CPU Requests | `gke-values.yaml`: `value-app-chart.app.resources.requests.cpu` | Deployment resource requests | N/A | |
| Memory Requests | `gke-values.yaml`: `value-app-chart.app.resources.requests.memory` | Deployment resource requests | N/A | |
| CPU Limits | `gke-values.yaml`: `value-app-chart.app.resources.limits.cpu` | Deployment resource limits | N/A | |
| Memory Limits | `gke-values.yaml`: `value-app-chart.app.resources.limits.memory` | Deployment resource limits | N/A | |
| **Security Configuration** | | | | |
| Run As User | `gke-values.yaml`: `value-app-chart.podSecurityContext.runAsUser` | Deployment securityContext | N/A | |
| Run As Group | `gke-values.yaml`: `value-app-chart.podSecurityContext.runAsGroup` | Deployment securityContext | N/A | |
| FS Group | `gke-values.yaml`: `value-app-chart.podSecurityContext.fsGroup` | Deployment securityContext | N/A | |
| **Storage Configuration** | | | | |
| Volumes | `gke-values.yaml`: `value-app-chart.app.volumes` | Deployment volumes | N/A | |
| Volume Mounts | `gke-values.yaml`: `value-app-chart.app.volumeMounts` | Deployment volumeMounts | N/A | |
| **Ingress Configuration** | | | | |
| Ingress Enabled | `gke-values.yaml`: `value-app-chart.ingress.enabled` | Ingress creation | N/A | |
| Ingress Class | `gke-values.yaml`: `value-app-chart.ingress.className` | Ingress class: `nginx` | N/A | |
| Ingress Host | `gke-values.yaml`: `value-app-chart.ingress.hosts[0].host` | Ingress host: `example.com` | N/A | |
| **Nginx Ingress Stack Config** | | | | |
| Domain | `nginx-ingress-stack-configurable/ingress-config.sh`: `DOMAIN` | Ingress host | N/A | Used when deploying nginx ingress stack |
| Service Name | `nginx-ingress-stack-configurable/ingress-config.sh`: `SERVICE_NAME` | Ingress backend service | N/A | Must match deployed service name |
| Service Port | `nginx-ingress-stack-configurable/ingress-config.sh`: `SERVICE_PORT` | Ingress backend service port | N/A | Must match deployed service port |
| Certificate Email | `nginx-ingress-stack-configurable/ingress-config.sh`: `CERT_EMAIL` | ClusterIssuer | N/A | For Let's Encrypt |
| Certificate Issuer | `nginx-ingress-stack-configurable/ingress-config.sh`: `CERT_ISSUER` | ClusterIssuer | N/A | Let's Encrypt production or staging |
| OAuth Settings | Various in `nginx-ingress-stack-configurable/ingress-config.sh` | OAuth2 Proxy deployment | N/A | When using OAuth authentication |

## Secret and ConfigMap Application Flow

The configuration is now consolidated in the `manage-gvm-chart.sh` script which creates both secrets and config maps:

1. **Secret Creation**: The script creates a Kubernetes secret named `github-value-secret`:
   ```bash
   kubectl create secret generic github-value-secret \
     --from-literal=MONGODB_URI="$MONGODB_URI" \
     --from-file=GITHUB_APP_PRIVATE_KEY="$PRIVATE_KEY_FILE" \
     --from-literal=GITHUB_WEBHOOK_SECRET="$WEBHOOK_SECRET" \
     --namespace "$NAMESPACE"
   ```

2. **ConfigMap Creation**: The script now also creates a ConfigMap named `github-value-config`:
   ```bash
   kubectl create configmap github-value-config \
     --from-literal=PORT="$APP_PORT" \
     --from-literal=BASE_URL="$BASE_URL" \
     --from-literal=GITHUB_APP_ID="$GITHUB_APP_ID" \
     --namespace "$NAMESPACE"
   ```

3. **Direct Helm Value Overrides**: The script also passes important values directly to Helm:
   ```bash
   # For parent chart
   --set value-app-chart.app.image.repository="$APP_IMAGE_REPOSITORY" \
   --set value-app-chart.app.image.tag="$APP_IMAGE_TAG" \
   --set value-app-chart.service.targetPort="$APP_PORT"
   
   # For child chart
   --set app.image.repository="$APP_IMAGE_REPOSITORY" \
   --set app.image.tag="$APP_IMAGE_TAG" \
   --set service.targetPort="$APP_PORT"
   ```

4. **Reference in Deployment**: The deployment template references these objects:
   ```yaml
   envFrom:
     - configMapRef:
         name: github-value-config
     - secretRef:
         name: github-value-secret
   ```

5. **Consistent Configuration Between Environments**: The consolidated approach ensures that:
   - Configuration is consistent whether using parent or child chart
   - External or local MongoDB connections are properly configured
   - Key application settings are prompted with sensible defaults
   - Configuration can be saved for reuse in future deployments

This consolidated approach improves visibility and management of configuration by:
- Centralizing all configuration in one script
- Explicitly capturing key application settings through prompts
- Separating sensitive from non-sensitive configuration
- Making the configuration process interactive and user-friendly
- Setting Helm values directly for critical parameters

## Configuration Flow Diagram

```
User Interaction                                              Kubernetes Resources
     |                                                                |
     v                                                                v
manage-gvm-chart.sh --------> Create Secret ------------> K8s Secret (github-value-secret)
     |                           |                                    |
     |                           v                                    |
     |                     Create ConfigMap ---------> K8s ConfigMap (github-value-config)
     |                           |                                    |
     |                           v                                    |
     +-----------------> Helm install/upgrade                         |
                              with --set                              |
                                |                                     |
                                v                                     |
                        Deployment Template <--------------------------
                                |
                                v
                        Container Environment
                        (env vars & mounted files)
```

## Notes on Security

1. Sensitive information (passwords, keys) flows through:
   - User input or environment variables
   - Kubernetes Secrets
   - Pod environment variables or mounted files

2. The `manage-gvm-chart.sh` script now handles:
   - Creation of both secrets and configmaps
   - URL-encoding of passwords for MongoDB URI
   - Storage of sensitive values in Kubernetes secrets
   - Direct setting of critical Helm values
   - Optional saving to local env_vars.sh file (gitignored)

3. The secret and configmap are created independently from Helm to:
   - Keep sensitive values out of Helm values files
   - Allow separation of duties (security admin vs. application deployer)
   - Avoid storing secrets in version control
   - Enable manual management of sensitive credentials

4. Additional configuration that could be included in future enhancements:
   - Resource limits and requests prompts
   - Autoscaling settings
   - Liveness and readiness probe configurations
   - Additional application environment variables
   - Persistent volume configurations for MongoDB

5. Nginx Ingress provides:
   - TLS termination
   - Authentication (Basic Auth or OAuth)
   - Secure access to the application
   - Configured through a separate deployment process
