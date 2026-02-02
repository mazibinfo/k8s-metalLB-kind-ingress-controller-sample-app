# ELK Stack Helm Chart

A comprehensive Helm chart for deploying the ELK Stack (Elasticsearch, Logstash, Kibana) with Filebeat on Kubernetes.

## Components

- **Elasticsearch**: Search and analytics engine
- **Logstash**: Data processing pipeline
- **Kibana**: Visualization and management interface
- **Filebeat**: Lightweight log shipper (DaemonSet)

## Installation

### Basic Installation

```bash
helm install elk-stack ./elk-stack -n logging --create-namespace
```

### Install with Custom Values

```bash
helm install elk-stack ./elk-stack -n logging --create-namespace -f custom-values.yaml
```

### Upgrade

```bash
helm upgrade elk-stack ./elk-stack -n logging
```

### Uninstall

```bash
helm uninstall elk-stack -n logging
```

## Configuration

The chart is fully configurable via the `values.yaml` file. Below are some key configurations:

### Elasticsearch

```yaml
elasticsearch:
  enabled: true
  replicas: 1
  security:
    username: "elastic"
    password: "changeme123"  # CHANGE THIS!
  persistence:
    enabled: true
    size: "2Gi"
```

### Kibana

```yaml
kibana:
  enabled: true
  replicas: 1
  ingress:
    enabled: true
    hosts:
      - host: kibana.localhost
```

### Logstash

```yaml
logstash:
  enabled: true
  replicas: 1
  config:
    logstashConf: |
      # Your custom Logstash configuration
```

### Filebeat

```yaml
filebeat:
  enabled: true
  daemonSet:
    enabled: true
  config:
    filebeatYml: |
      # Your custom Filebeat configuration
```

## Directory Structure

```
elk-stack/
├── Chart.yaml                  # Chart metadata
├── values.yaml                 # Default configuration values
├── templates/
│   ├── NOTES.txt              # Post-installation notes
│   ├── namespace.yaml         # Namespace definition
│   ├── elasticsearch/
│   │   ├── deployment.yaml    # Elasticsearch deployment
│   │   ├── service.yaml       # Elasticsearch service
│   │   ├── secret.yaml        # Elasticsearch credentials
│   │   └── pvc.yaml          # Persistent volume claim
│   ├── kibana/
│   │   ├── deployment.yaml    # Kibana deployment
│   │   ├── service.yaml       # Kibana service
│   │   ├── ingress.yaml       # Kibana ingress
│   │   └── secret.yaml        # Kibana service account token
│   ├── logstash/
│   │   ├── deployment.yaml    # Logstash deployment
│   │   ├── service.yaml       # Logstash service
│   │   └── configmap.yaml     # Logstash configuration
│   └── filebeat/
│       ├── daemonset.yaml           # Filebeat DaemonSet
│       ├── configmap.yaml           # Filebeat configuration
│       ├── serviceaccount.yaml      # Service account
│       ├── clusterrole.yaml         # Cluster role
│       └── clusterrolebinding.yaml  # Cluster role binding
```

## Accessing the Stack

### Kibana

If ingress is enabled:
```bash
# Access via the configured hostname
curl http://kibana.localhost
```

If ingress is disabled:
```bash
# Port forward to access locally
kubectl port-forward -n logging svc/kibana 5601:5601
# Access at http://localhost:5601
```

### Elasticsearch

```bash
# Port forward to access locally
kubectl port-forward -n logging svc/elasticsearch 9200:9200

# Test connection
curl -u elastic:changeme123 http://localhost:9200
```

## Security Considerations

1. **Change Default Passwords**: Update the Elasticsearch password in `values.yaml`
2. **Enable TLS**: For production, enable SSL/TLS for Elasticsearch
3. **Encryption Keys**: Generate new encryption keys for Kibana
4. **RBAC**: Review and adjust Filebeat RBAC permissions as needed

## Resource Requirements

Default resource allocations:

- **Elasticsearch**: 1Gi memory (request), 2Gi (limit)
- **Kibana**: 512Mi memory (request), 1Gi (limit)
- **Logstash**: 512Mi memory (request), 1Gi (limit)
- **Filebeat**: 100Mi memory (request), 200Mi (limit)

Adjust these in `values.yaml` based on your workload.

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n logging
```

### View Logs

```bash
# Elasticsearch
kubectl logs -n logging deployment/elasticsearch

# Kibana
kubectl logs -n logging deployment/kibana

# Logstash
kubectl logs -n logging deployment/logstash

# Filebeat (specific pod)
kubectl logs -n logging daemonset/filebeat
```

### Verify Configuration

```bash
# Check values
helm get values elk-stack -n logging

# Check all resources
helm get manifest elk-stack -n logging
```

## Version Information

- Chart Version: 1.0.0
- ELK Stack Version: 8.19.1

## License

This chart is provided as-is for use with the Elastic Stack.
