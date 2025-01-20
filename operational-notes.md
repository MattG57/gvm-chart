# Persistent Volumes
To prevent persistent volumes created by the MongoDB chart from inadvertent deletion and to reuse them across deployments and upgrades, you can configure the following settings in your Helm chart values:

1. **Enable Persistent Storage:**
   Ensure that persistent storage is enabled in the Helm values file. This is typically enabled by default.

2. **Set `persistentVolumeReclaimPolicy` to `Retain`:**
   This policy ensures that the Persistent Volumes are not deleted when the Persistent Volume Claims (PVCs) are deleted. Instead, they are retained for reuse.

3. **Reuse Persistent Volumes:**
   You can reuse existing Persistent Volumes by ensuring that the PVCs created by the new deployment or upgrade match the existing PVs' specifications.

Here is an example configuration in the `values.yaml` file of the Bitnami MongoDB chart:

```yaml
persistence:
  enabled: true
  storageClass: "standard" # Adjust this to your storage class
  accessModes:
    - ReadWriteOnce
  size: 8Gi
  annotations: {}
  existingClaim: ""
  subPath: ""
  mountPath: /bitnami/mongodb
  volumeReclaimPolicy: Retain
```

By setting `volumeReclaimPolicy` to `Retain`, the persistent volumes will be retained even if the PVCs are deleted. Additionally, if you want to reuse an existing PVC, you can specify the `existingClaim` field with the name of the existing PVC.

For more detailed instructions, you can refer to the [Bitnami MongoDB Helm Chart documentation](https://github.com/bitnami/charts/tree/master/bitnami/mongodb).

# Existing PVC Reuse

The `existingClaim` field is configured in the `values.yaml` file of the Bitnami MongoDB Helm chart. This field allows you to specify an existing Persistent Volume Claim (PVC) to be reused by the MongoDB deployment.

Here is an example of how to configure it in the `values.yaml` file:

```yaml
persistence:
  enabled: true
  storageClass: "standard" # Adjust this to your storage class if needed
  accessModes:
    - ReadWriteOnce
  size: 8Gi # Adjust the size as needed
  annotations: {}
  existingClaim: "my-existing-pvc" # Name of the existing PVC
  subPath: ""
  mountPath: /bitnami/mongodb
  volumeReclaimPolicy: Retain
```

In this example, replace `"my-existing-pvc"` with the name of your existing Persistent Volume Claim. This configuration tells the MongoDB chart to use the specified existing PVC instead of creating a new one.

By reusing an existing PVC, you can ensure data persistence across deployments and upgrades. Make sure that the existing PVC has the correct specifications (e.g., access modes, storage class) to be compatible with the MongoDB chart's requirements.

# Data on PV

Yes, if you reuse an existing Persistent Volume Claim (PVC) across deployments, the data from the old deployment will become available in the new deployment. This is because the PVC is essentially a reference to a Persistent Volume (PV) that stores the data. As long as the PVC is reused, the underlying PV and its data are preserved and accessible to the new deployment.

Here’s how it works:

1. **Old Deployment:**
   - The old deployment uses a PVC to claim a PV.
   - Data is written to the PV.

2. **Reusing PVC in New Deployment:**
   - When deploying the new version, you configure the Helm chart to use the same PVC by setting the `existingClaim` field in the `values.yaml` file.
   - The new deployment will mount the same PV referenced by the reused PVC.
   - The data stored in the PV by the old deployment will be accessible to the new deployment.

This ensures data continuity and persistence across deployments. Here is an example configuration in the `values.yaml` file to reuse an existing PVC:

```yaml
persistence:
  enabled: true
  storageClass: "standard" # Adjust this to your storage class if needed
  accessModes:
    - ReadWriteOnce
  size: 8Gi # Adjust the size as needed
  annotations: {}
  existingClaim: "my-existing-pvc" # Name of the existing PVC
  subPath: ""
  mountPath: /bitnami/mongodb
  volumeReclaimPolicy: Retain
```

By reusing the PVC, the new deployment will have access to the data stored in the PV by the old deployment, ensuring data persistence and availability.

# Backup



Yes, you can include cron jobs in your Helm chart deployment to handle periodic backups. This is typically done by creating Kubernetes `CronJob` resources that schedule and manage the execution of backup tasks at specified intervals.

Here’s an example of how you can add a `CronJob` to the Bitnami MongoDB Helm chart to handle periodic backups:

1. **Define the `CronJob` in the Helm values file:**
   
   You can add a new section in your `values.yaml` file for configuring the backup cron job. Here’s an example configuration:

   ```yaml
   backup:
     enabled: true
     schedule: "0 2 * * *" # Cron schedule expression for the backup job
     image:
       repository: bitnami/mongodb
       tag: 4.4.6-debian-10-r0
     resources: {}
     persistentVolumeClaim:
       name: backup-pvc
     mongodb:
       host: "{{ .Release.Name }}-mongodb"
       port: 27017
       user: root
       password: example
       database: mydatabase
   ```

2. **Create the `CronJob` resource:**

   You can define the `CronJob` resource in a Helm template file, such as `templates/backup-cronjob.yaml`. Here’s an example template:

   ```yaml
   {{- if .Values.backup.enabled }}
   apiVersion: batch/v1beta1
   kind: CronJob
   metadata:
     name: {{ .Release.Name }}-mongodb-backup
   spec:
     schedule: "{{ .Values.backup.schedule }}"
     jobTemplate:
       spec:
         template:
           spec:
             containers:
             - name: backup
               image: "{{ .Values.backup.image.repository }}:{{ .Values.backup.image.tag }}"
               command:
               - /bin/sh
               - -c
               - >
                 mongodump --host {{ .Values.backup.mongodb.host }} --port {{ .Values.backup.mongodb.port }} --username {{ .Values.backup.mongodb.user }} --password {{ .Values.backup.mongodb.password }} --db {{ .Values.backup.mongodb.database }} --out /backup/$(date +\%F)
               volumeMounts:
               - name: backup-storage
                 mountPath: /backup
             restartPolicy: OnFailure
             volumes:
             - name: backup-storage
               persistentVolumeClaim:
                 claimName: {{ .Values.backup.persistentVolumeClaim.name }}
   {{- end }}
   ```

3. **Deploy the Helm chart:**

   When you deploy or upgrade the Helm chart with the above configurations, it will create a `CronJob` in your Kubernetes cluster that runs the backup command at the specified schedule.

By following the above steps, you can set up periodic backups for your MongoDB deployment using Kubernetes `CronJob` resources within the Helm chart configuration. Be sure to adjust the values and configurations according to your specific requirements and environment.
