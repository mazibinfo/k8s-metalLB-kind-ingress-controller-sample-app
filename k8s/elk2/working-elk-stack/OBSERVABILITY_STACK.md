# Complete Kubernetes Observability Stack

Production-ready logging and monitoring solution for Kubernetes clusters.

## Overview

This repository contains a complete observability stack combining:
- **EFK Stack**: Logging (Elasticsearch, FluentBit, Kibana)
- **Prometheus + Grafana**: Monitoring and metrics

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Kubernetes Cluster                               │
│                                                                          │
│  ┌────────────────────────────┐  ┌────────────────────────────────────┐│
│  │     LOGGING (EFK)          │  │     MONITORING (P+G)               ││
│  │                            │  │                                    ││
│  │  ┌──────────────────────┐  │  │  ┌─────────────┐  ┌────────────┐ ││
│  │  │   Elasticsearch      │  │  │  │ Prometheus  │  │  Grafana   │ ││
│  │  │  - Stores logs       │  │  │  │ - Scrapes   │  │  - Dashbds │ ││
│  │  │  - Indexes data      │  │  │  │ - Stores    │  │  - Alerts  │ ││
│  │  │  - REST API          │  │  │  │ - Queries   │  │  - UI      │ ││
│  │  └──────────────────────┘  │  │  └─────────────┘  └────────────┘ ││
│  │           ▲                │  │         ▲              │          ││
│  │           │                │  │         │              │          ││
│  │  ┌────────┴──────────┐    │  │  ┌──────┴──────┐       │          ││
│  │  │    FluentBit      │    │  │  │   Metrics   │       │          ││
│  │  │  (DaemonSet)      │    │  │  │   Targets   │       │          ││
│  │  │  - Collects logs  │    │  │  │  - Nodes    │       │          ││
│  │  │  - Parses JSON    │    │  │  │  - Pods     │       │          ││
│  │  │  - Enriches K8s   │    │  │  │  - Services │       │          ││
│  │  └───────────────────┘    │  │  └─────────────┘       │          ││
│  │           ▲                │  │                        │          ││
│  │           │                │  │                        │          ││
│  │  ┌────────┴──────────┐    │  │                ┌───────▼────────┐ ││
│  │  │    Kibana         │    │  │                │  User queries  │ ││
│  │  │  - Search logs    │    │  │                │  dashboards    │ ││
│  │  │  - Visualizations │    │  │                └────────────────┘ ││
│  │  │  - Dashboards     │    │  │                                    ││
│  │  └───────────────────┘    │  │                                    ││
│  └────────────────────────────┘  └────────────────────────────────────┘│
│         kibana.localhost              grafana.localhost                 │
│                                      prometheus.localhost                │
└─────────────────────────────────────────────────────────────────────────┘
```

## Components

### Logging Stack (EFK)

| Component | Purpose | Storage | Resources |
|-----------|---------|---------|-----------|
| **Elasticsearch** | Log storage and indexing | 2Gi PVC | 1Gi RAM, 500m CPU |
| **FluentBit** | Log collection (DaemonSet) | N/A | 200Mi RAM, 200m CPU |
| **Kibana** | Log visualization and search | N/A | 512Mi RAM, 500m CPU |

**Location**: Root directory
- `01-elasticsearch-production.yaml`
- `02-kibana-production.yaml`
- `03-fluentbit-production.yaml`

### Monitoring Stack (Prometheus + Grafana)

| Component | Purpose | Storage | Resources |
|-----------|---------|---------|-----------|
| **Prometheus** | Metrics collection and storage | 10Gi PVC | 1Gi RAM, 500m CPU |
| **Grafana** | Metrics visualization | 5Gi PVC | 512Mi RAM, 250m CPU |

**Location**: `prometheus-grafana/` directory
- `01-prometheus-production.yaml`
- `02-grafana-production.yaml`

## Key Features

### Automated Configuration ✨

Both stacks are fully automated with **no manual steps required**:

#### EFK Automation
- ✅ **Kibana Token**: Auto-created via initContainer
- ✅ **Index Templates**: Pre-configured to prevent mapping conflicts
- ✅ **FluentBit Parsing**: Automatic JSON parsing and Kubernetes metadata enrichment

#### Prometheus + Grafana Automation
- ✅ **Datasource**: Prometheus auto-configured in Grafana
- ✅ **Dashboards**: Pre-loaded Kubernetes overview dashboard
- ✅ **Service Discovery**: Auto-discovers annotated pods and services

### Security Best Practices 🔒

- **RBAC**: All components use ServiceAccounts with minimal required permissions
- **Secrets**: Credentials stored in Kubernetes Secrets
- **Security Contexts**: Non-root users, fsGroup settings
- **TLS Ready**: Can be configured for encrypted communication

### Production Ready 🚀

- **Health Checks**: Liveness and readiness probes
- **Resource Limits**: CPU and memory limits configured
- **Persistent Storage**: Data survives pod restarts
- **High Availability Ready**: Can be scaled with StatefulSets

## Quick Start

### Deploy Complete Stack

```bash
# 1. Deploy EFK Stack (Logging)
kubectl apply -f 01-elasticsearch-production.yaml
kubectl wait --for=condition=ready pod -l app=elasticsearch -n logging --timeout=300s

kubectl apply -f 02-kibana-production.yaml
kubectl wait --for=condition=ready pod -l app=kibana -n logging --timeout=300s

kubectl apply -f 03-fluentbit-production.yaml
kubectl wait --for=condition=ready pod -l app=fluent-bit -n logging --timeout=300s

# 2. Deploy Prometheus + Grafana (Monitoring)
cd prometheus-grafana
./deploy.sh
# Or manually:
# kubectl apply -f 01-prometheus-production.yaml
# kubectl apply -f 02-grafana-production.yaml
```

### Verify Deployment

```bash
# Check logging stack
kubectl get pods -n logging

# Check monitoring stack
kubectl get pods -n monitoring

# Check all services
kubectl get svc -A | grep -E 'logging|monitoring'

# Check ingresses
kubectl get ingress -A
```

## Access URLs

### Development (localhost)

| Service | URL | Credentials |
|---------|-----|-------------|
| Elasticsearch | http://elasticsearch.logging.svc:9200 | elastic / changeme123 |
| Kibana | http://kibana.localhost | (uses service account token) |
| Prometheus | http://prometheus.localhost | No auth |
| Grafana | http://grafana.localhost | admin / admin123 |

### Production Setup

For production, configure:
1. **TLS/HTTPS**: Enable SSL in ingress
2. **Authentication**: OAuth, LDAP, or SAML
3. **Change passwords**: Update all default credentials
4. **Resource limits**: Adjust based on cluster size
5. **Backup**: Configure regular backups for PVCs

## Use Cases

### When to Use Each Tool

#### Kibana (Logs)
- 🔍 **Debugging**: Search application errors and stack traces
- 📝 **Audit**: Track user actions and system events
- 🐛 **Troubleshooting**: Find why a specific request failed
- 📊 **Log Analysis**: Analyze log patterns and trends

Example queries:
```
kubernetes.namespace_name:"production" AND level:"error"
kubernetes.pod_name:my-app* AND message:*timeout*
```

#### Grafana (Metrics)
- 📈 **Performance**: Monitor CPU, memory, network usage
- 🎯 **SLIs/SLOs**: Track service level indicators
- ⚠️ **Alerting**: Get notified when metrics exceed thresholds
- 📊 **Capacity Planning**: Analyze resource trends

Example metrics:
```
rate(container_cpu_usage_seconds_total[5m])
container_memory_usage_bytes{namespace="production"}
```

### Complementary Use

**Scenario**: API request is slow

1. **Grafana**: Check CPU/memory spikes, request rate
2. **Kibana**: Search for error logs, stack traces, slow queries
3. **Correlation**: Match timestamp from metrics to logs

## Configuration Examples

### Enable Metrics for Your Application

Add annotations to your deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      annotations:
        # For Prometheus scraping
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
        - name: my-app
          image: my-app:latest
          ports:
            - containerPort: 8080
              name: metrics
```

### Structured Logging for FluentBit

Ensure your application logs in JSON format:

```json
{
  "timestamp": "2026-01-25T12:00:00Z",
  "level": "error",
  "message": "Database connection failed",
  "service": "api-gateway",
  "trace_id": "abc123",
  "error": {
    "type": "ConnectionError",
    "details": "Timeout after 30s"
  }
}
```

FluentBit will automatically:
- Parse JSON fields
- Add Kubernetes metadata (pod, namespace, labels)
- Send to Elasticsearch with proper structure

## Maintenance

### Regular Tasks

#### Daily
- Check pod health: `kubectl get pods -n logging -n monitoring`
- Review dashboards for anomalies

#### Weekly
- Review Elasticsearch indices: Check disk usage
- Update Grafana dashboards
- Check Prometheus targets: All should be "UP"

#### Monthly
- Backup Grafana dashboards and datasources
- Review and clean old Elasticsearch indices
- Update container images
- Review resource usage and adjust limits

### Updating Components

```bash
# Update image versions in YAML files
# Example: Update Elasticsearch from 8.19.1 to 8.20.0

# 1. Edit the deployment file
vim 01-elasticsearch-production.yaml

# 2. Change image version
# From: image: docker.elastic.co/elasticsearch/elasticsearch:8.19.1
# To:   image: docker.elastic.co/elasticsearch/elasticsearch:8.20.0

# 3. Apply the update
kubectl apply -f 01-elasticsearch-production.yaml

# 4. Monitor the rollout
kubectl rollout status deployment/elasticsearch -n logging
```

## Scaling

### Elasticsearch Cluster

For production, consider a 3-node cluster:

```yaml
spec:
  replicas: 3
  env:
    - name: discovery.type
      value: "zen"  # Change from single-node
    - name: cluster.initial_master_nodes
      value: "elasticsearch-0,elasticsearch-1,elasticsearch-2"
```

Use StatefulSet instead of Deployment for stable network identities.

### Prometheus Federation

For large clusters, use Prometheus federation:

```yaml
# Global Prometheus
scrape_configs:
  - job_name: 'federate'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~".+"}'
    static_configs:
      - targets:
          - 'prometheus-region-1:9090'
          - 'prometheus-region-2:9090'
```

## Troubleshooting

### Common Issues

#### FluentBit pods not ready
- **Cause**: Elasticsearch mapping conflict
- **Solution**: Delete problematic index, restart FluentBit
- **Prevention**: Index template is auto-created (already configured)

#### Kibana can't connect to Elasticsearch
- **Cause**: Missing or invalid service account token
- **Solution**: Token is auto-created by initContainer
- **Verify**: `kubectl get secret kibana-token -n logging`

#### Prometheus not scraping pods
- **Cause**: Missing annotations or RBAC permissions
- **Solution**: Add `prometheus.io/scrape: "true"` annotation
- **Verify**: Check targets at http://prometheus.localhost/targets

#### Grafana shows "No data"
- **Cause**: Datasource misconfiguration or no metrics
- **Solution**: Test datasource in Settings → Data Sources
- **Verify**: Query Prometheus directly: http://prometheus.localhost

### Debug Commands

```bash
# Check Elasticsearch health
kubectl exec -n logging <es-pod> -- \
  curl -u elastic:changeme123 http://localhost:9200/_cluster/health

# View FluentBit metrics
kubectl port-forward -n logging <fluentbit-pod> 2020:2020
curl http://localhost:2020/api/v1/metrics/prometheus

# Test Prometheus query
kubectl port-forward -n monitoring svc/prometheus 9090:9090
curl 'http://localhost:9090/api/v1/query?query=up'

# Export Grafana dashboard
kubectl exec -n monitoring <grafana-pod> -- \
  curl -u admin:admin123 http://localhost:3000/api/dashboards/uid/<dashboard-uid>
```

## Backup and Recovery

### Elasticsearch Snapshots

```bash
# Create snapshot repository (S3 example)
curl -X PUT "http://elasticsearch:9200/_snapshot/my_backup" \
  -H 'Content-Type: application/json' \
  -d'{
    "type": "s3",
    "settings": {
      "bucket": "my-elasticsearch-backups",
      "region": "us-east-1"
    }
  }'

# Create snapshot
curl -X PUT "http://elasticsearch:9200/_snapshot/my_backup/snapshot_1"
```

### Prometheus Data

```bash
# Snapshot the PVC
kubectl exec -n monitoring <prometheus-pod> -- \
  tar czf /tmp/prometheus-backup.tar.gz /prometheus

# Copy to local
kubectl cp monitoring/<prometheus-pod>:/tmp/prometheus-backup.tar.gz \
  ./prometheus-backup.tar.gz
```

### Grafana Dashboards

```bash
# Export all dashboards
kubectl exec -n monitoring <grafana-pod> -- \
  grafana-cli admin export-dashboards --path=/tmp/dashboards

# Backup as ConfigMap (production approach)
kubectl get configmap grafana-dashboards -n monitoring -o yaml > dashboards-backup.yaml
```

## Cost Optimization

### Storage

- Elasticsearch: Use lifecycle policies to delete old indices
- Prometheus: Adjust retention from 30d based on needs
- Grafana: Regularly export and delete unused dashboards

### Resources

- Start with minimal resources, scale as needed
- Use HorizontalPodAutoscaler for Grafana if needed
- Consider vertical scaling for Elasticsearch/Prometheus

### Sampling

- Prometheus: Increase scrape_interval for non-critical metrics
- FluentBit: Use filters to exclude verbose logs

## Security Hardening

### Network Policies

```yaml
# Example: Restrict Elasticsearch access
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: elasticsearch-netpol
  namespace: logging
spec:
  podSelector:
    matchLabels:
      app: elasticsearch
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: kibana
        - podSelector:
            matchLabels:
              app: fluent-bit
```

### Pod Security Standards

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: logging
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

## Contributing

When modifying configurations:

1. Test changes in development cluster first
2. Update README documentation
3. Verify automated features still work (initContainers)
4. Update version tags in deployment files
5. Test rollback procedures

## License

This configuration is provided as-is for production use.

## Support

For issues or questions:
- Check troubleshooting section above
- Review component logs
- Consult official documentation:
  - Elasticsearch: https://elastic.co/guide/
  - Kibana: https://elastic.co/guide/kibana/
  - FluentBit: https://docs.fluentbit.io/
  - Prometheus: https://prometheus.io/docs/
  - Grafana: https://grafana.com/docs/

---

**Version**: 1.0
**Last Updated**: 2026-01-25
**Tested On**: Kubernetes 1.28+
