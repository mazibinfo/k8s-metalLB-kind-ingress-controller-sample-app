# Prometheus + Grafana Monitoring Stack

Production-ready Prometheus and Grafana deployment for Kubernetes with best practices and automated configuration.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│                                                              │
│  ┌──────────────┐      ┌─────────────┐      ┌────────────┐ │
│  │  Prometheus  │◄─────┤   Metrics   │      │  Grafana   │ │
│  │              │      │   Scrapers  │◄─────┤            │ │
│  │  - API       │      │             │      │ - UI       │ │
│  │  - Nodes     │      │ - Pods      │      │ - Dashbds  │ │
│  │  - cAdvisor  │      │ - Services  │      │            │ │
│  │  - Endpoints │      │ - Nodes     │      │            │ │
│  └──────────────┘      └─────────────┘      └────────────┘ │
│         │                                          │         │
│         │                                          │         │
│  ┌──────▼──────┐                          ┌────────▼──────┐ │
│  │ Persistent  │                          │  Persistent   │ │
│  │  Storage    │                          │   Storage     │ │
│  │   (10Gi)    │                          │    (5Gi)      │ │
│  └─────────────┘                          └───────────────┘ │
└─────────────────────────────────────────────────────────────┘
         ▲                                          ▲
         │                                          │
         │                                          │
  prometheus.localhost                      grafana.localhost
```

## Features

### Prometheus
✅ **Automatic Service Discovery** - Discovers pods, services, nodes, and endpoints
✅ **Kubernetes Metrics** - Scrapes API server, nodes, and cAdvisor
✅ **Annotation-based Scraping** - Auto-discovers pods with `prometheus.io/scrape` annotation
✅ **30-day Retention** - Stores metrics for 30 days
✅ **RBAC Security** - Proper ServiceAccount and ClusterRole
✅ **Persistent Storage** - 10Gi PVC for metrics data
✅ **Health Checks** - Liveness and readiness probes
✅ **Resource Limits** - CPU and memory limits configured

### Grafana
✅ **Pre-configured Datasource** - Prometheus datasource auto-provisioned
✅ **Default Dashboard** - Kubernetes cluster overview dashboard included
✅ **Persistent Storage** - 5Gi PVC for dashboards and settings
✅ **Secure Admin** - Admin credentials in Kubernetes Secret
✅ **Health Checks** - Liveness and readiness probes
✅ **Resource Limits** - CPU and memory limits configured
✅ **Dashboard Provisioning** - Auto-loads dashboards on startup

## Quick Start

### 1. Deploy Prometheus

```bash
kubectl apply -f 01-prometheus-production.yaml
```

**What this creates:**
- Namespace: `monitoring`
- ServiceAccount with ClusterRole for metrics scraping
- ConfigMap with Prometheus scrape configuration
- PersistentVolumeClaim (10Gi) for metrics storage
- Deployment with Prometheus container
- Service for internal access
- Ingress at `prometheus.localhost`

### 2. Wait for Prometheus to be Ready

```bash
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s
```

### 3. Deploy Grafana

```bash
kubectl apply -f 02-grafana-production.yaml
```

**What this creates:**
- Secret with admin credentials
- ServiceAccount for Grafana
- ConfigMaps for datasources and dashboards
- PersistentVolumeClaim (5Gi) for Grafana data
- Deployment with Grafana container
- Service for internal access
- Ingress at `grafana.localhost`

### 4. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n monitoring

# Check services
kubectl get svc -n monitoring

# Check ingresses
kubectl get ingress -n monitoring
```

Expected output:
```
NAME                        READY   STATUS    RESTARTS   AGE
prometheus-xxxxxxxxxx-xxxxx 1/1     Running   0          2m
grafana-xxxxxxxxxx-xxxxx    1/1     Running   0          1m
```

## Access the Stack

### Prometheus UI
- URL: http://prometheus.localhost
- No authentication required
- Use for: Querying metrics, viewing targets, alerts

### Grafana UI
- URL: http://grafana.localhost
- Username: `admin`
- Password: `admin123` (change in production!)
- Use for: Visualizing metrics, creating dashboards

## Configuration

### Prometheus Scrape Targets

Prometheus is configured to scrape:

1. **Kubernetes API Server** - Control plane metrics
2. **Kubernetes Nodes** - Node-level metrics
3. **cAdvisor** - Container metrics (CPU, memory, network)
4. **Service Endpoints** - Services with annotation `prometheus.io/scrape: "true"`
5. **Pods** - Pods with annotation `prometheus.io/scrape: "true"`

### Enable Metrics for Your Pods

Add these annotations to your pod or service:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"        # Your metrics port
    prometheus.io/path: "/metrics"    # Your metrics path
```

Example for FluentBit (already configured):
```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "2020"
    prometheus.io/path: "/api/v1/metrics/prometheus"
```

### Custom Dashboards

To add custom Grafana dashboards:

1. **Via UI** (recommended for development):
   - Login to Grafana
   - Click "+" → "Import"
   - Enter dashboard ID from https://grafana.com/grafana/dashboards/
   - Or upload JSON file

2. **Via ConfigMap** (recommended for production):
   ```bash
   # Add dashboard JSON to ConfigMap
   kubectl edit configmap grafana-dashboards -n monitoring

   # Restart Grafana to load new dashboards
   kubectl rollout restart deployment/grafana -n monitoring
   ```

### Recommended Dashboards

Import these popular Grafana dashboards:

- **Kubernetes Cluster Monitoring**: ID 315
- **Node Exporter Full**: ID 1860
- **Kubernetes Pods**: ID 6417
- **Ingress NGINX**: ID 9614

## Security Best Practices

### Change Default Credentials

**Before production deployment:**

```bash
# Edit the secret
kubectl edit secret grafana-credentials -n monitoring

# Or create a new secret
kubectl create secret generic grafana-credentials \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=YOUR_SECURE_PASSWORD \
  --namespace=monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring
```

### RBAC Configuration

- Prometheus uses a **ClusterRole** to access cluster-wide metrics
- Grafana uses a **ServiceAccount** with minimal permissions
- All service accounts follow the principle of least privilege

### Network Policies (Optional)

To restrict network access:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: prometheus-netpol
  namespace: monitoring
spec:
  podSelector:
    matchLabels:
      app: prometheus
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: grafana
      ports:
        - protocol: TCP
          port: 9090
```

## Monitoring the Monitoring Stack

### Check Prometheus Targets

```bash
# Open Prometheus UI
open http://prometheus.localhost

# Or use kubectl port-forward
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Navigate to Status → Targets
```

All targets should show as "UP" in green.

### Check Grafana Health

```bash
# Check Grafana pod logs
kubectl logs -n monitoring -l app=grafana --tail=50

# Test Grafana API
kubectl port-forward -n monitoring svc/grafana 3000:3000
curl http://localhost:3000/api/health
```

Expected response: `{"database":"ok","version":"10.2.3"}`

## Persistence and Backup

### Prometheus Data

- **Storage**: 10Gi PVC
- **Retention**: 30 days
- **Path**: `/prometheus` in container
- **Backup**: Snapshot the PVC or use Prometheus remote write

### Grafana Data

- **Storage**: 5Gi PVC
- **Path**: `/var/lib/grafana` in container
- **Contains**: Dashboards, datasources, users, settings
- **Backup**: Snapshot the PVC or export dashboards as JSON

### Backup Commands

```bash
# Backup Grafana dashboards
kubectl exec -n monitoring -it <grafana-pod> -- \
  tar czf /tmp/grafana-backup.tar.gz /var/lib/grafana/

# Copy backup to local
kubectl cp monitoring/<grafana-pod>:/tmp/grafana-backup.tar.gz ./grafana-backup.tar.gz
```

## Scaling Considerations

### Prometheus

For larger clusters:

1. **Increase storage**:
   ```yaml
   resources:
     requests:
       storage: 50Gi  # Adjust based on metrics volume
   ```

2. **Increase retention**:
   ```yaml
   args:
     - '--storage.tsdb.retention.time=90d'  # 90 days
   ```

3. **Increase resources**:
   ```yaml
   resources:
     limits:
       memory: "4Gi"
       cpu: "2"
   ```

4. **Enable remote write** (for long-term storage):
   ```yaml
   remote_write:
     - url: "https://your-remote-storage.com/api/v1/write"
   ```

### Grafana

For multiple users:

1. **Increase resources**:
   ```yaml
   resources:
     limits:
       memory: "2Gi"
       cpu: "1"
   ```

2. **Enable external database** (PostgreSQL/MySQL):
   ```yaml
   env:
     - name: GF_DATABASE_TYPE
       value: "postgres"
     - name: GF_DATABASE_HOST
       value: "postgres:5432"
   ```

## Troubleshooting

### Prometheus Not Scraping Targets

```bash
# Check Prometheus logs
kubectl logs -n monitoring -l app=prometheus --tail=100

# Check ServiceAccount permissions
kubectl auth can-i list pods --as=system:serviceaccount:monitoring:prometheus -A

# Verify targets in Prometheus UI
open http://prometheus.localhost/targets
```

### Grafana Can't Connect to Prometheus

```bash
# Test connectivity from Grafana pod
kubectl exec -n monitoring -it <grafana-pod> -- \
  wget -O- http://prometheus:9090/api/v1/query?query=up

# Check datasource configuration
kubectl get configmap grafana-datasources -n monitoring -o yaml
```

### High Memory Usage

```bash
# Check Prometheus metrics
kubectl exec -n monitoring <prometheus-pod> -- \
  curl -s localhost:9090/metrics | grep process_resident_memory_bytes

# Reduce scrape frequency in ConfigMap
kubectl edit configmap prometheus-config -n monitoring
# Change: scrape_interval: 30s  (from 15s)

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n monitoring
```

## Cleanup

```bash
# Delete Grafana
kubectl delete -f 02-grafana-production.yaml

# Delete Prometheus
kubectl delete -f 01-prometheus-production.yaml

# Delete namespace and all resources
kubectl delete namespace monitoring

# Note: PVCs may be retained depending on your storage class
kubectl delete pvc -n monitoring --all
```

## Integration with EFK Stack

The Prometheus + Grafana stack complements the EFK (Elasticsearch, FluentBit, Kibana) stack:

- **EFK**: Logs collection, storage, and analysis
- **Prometheus + Grafana**: Metrics collection, storage, and visualization

Together they provide:
- **Logs**: Search, analyze, and visualize application logs (Kibana)
- **Metrics**: Monitor resource usage, performance, and SLIs (Grafana)
- **Observability**: Complete visibility into your Kubernetes cluster

## Next Steps

1. **Add custom dashboards** for your applications
2. **Configure alerting** in Prometheus with Alertmanager
3. **Set up remote storage** for long-term metrics retention
4. **Enable authentication** (OAuth, LDAP) for Grafana
5. **Create custom recording rules** in Prometheus
6. **Export important dashboards** as code (JSON)

## Support and Documentation

- Prometheus: https://prometheus.io/docs/
- Grafana: https://grafana.com/docs/grafana/latest/
- Kubernetes Monitoring: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/

---

**Status**: Production-ready ✅
**Last Updated**: 2026-01-25
**Maintained By**: DevOps Team
