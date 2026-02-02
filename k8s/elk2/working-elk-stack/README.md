# Working ELK Stack Configuration

This directory contains the **tested and working** ELK stack configuration that is currently running in your Kubernetes cluster.

## 📋 What's Included

### Stack Components:
1. **Elasticsearch** - Data storage and search engine
2. **Logstash** - Log processing pipeline
3. **Kibana** - Web UI for visualization
4. **Filebeat** - Log collector (DaemonSet running on all nodes)

### Configuration Files:
```
01-elasticsearch-production.yaml   # Elasticsearch with security enabled
02-kibana-production.yaml          # Kibana web UI
03-logstash-production.yaml        # Logstash with Beats input & routing
04-filebeat-all-namespaces.yaml    # Filebeat collecting from all namespaces
```

## 🔐 Security Configuration

**Credentials:**
- Username: `elastic`
- Password: `changeme123` (⚠️ Change this in production!)

**Location:** `01-elasticsearch-production.yaml:32`

## 🚀 Quick Start

### Deploy the Entire Stack:
```bash
cd /Users/ocv-mazib/k8s/elk2/working-elk-stack

# Deploy in order:
kubectl apply -f 01-elasticsearch-production.yaml
kubectl apply -f 02-kibana-production.yaml
kubectl apply -f 03-logstash-production.yaml
kubectl apply -f 04-filebeat-all-namespaces.yaml
```

### Or Deploy All at Once:
```bash
kubectl apply -f /Users/ocv-mazib/k8s/elk2/working-elk-stack/
```

### Verify Deployment:
```bash
# Check all pods are running
kubectl get pods -n logging

# Expected output:
# elasticsearch-xxxxx    1/1     Running
# kibana-xxxxx           1/1     Running
# logstash-xxxxx         1/1     Running
# filebeat-xxxxx         1/1     Running (one per node)
```

## 🔑 Create Kibana Service Account Token (First Time Setup)

**⚠️ IMPORTANT:** If this is a fresh deployment, you need to create the Kibana service account token manually (one-time only).

If Kibana is showing "Unable to connect to Elasticsearch" or the `kibana-token` secret doesn't exist, run these commands:

```bash
# Get the Elasticsearch pod name
ES_POD=$(kubectl get pod -n logging -l app=elasticsearch -o jsonpath='{.items[0].metadata.name}')

# Get the elastic password
ELASTIC_PASSWORD=$(kubectl get secret elastic-credentials -n logging -o jsonpath='{.data.password}' | base64 -d)

# Create the service account token
TOKEN=$(kubectl exec -n logging $ES_POD -- curl -s -X POST \
  -u elastic:$ELASTIC_PASSWORD \
  "http://localhost:9200/_security/service/elastic/kibana/credential/token/kibana-token" \
  | grep -o '"value":"[^"]*"' | cut -d'"' -f4)

# Verify token was created
echo "Token created: ${TOKEN:0:50}..."

# Create Kubernetes secret with the token
kubectl create secret generic kibana-token \
  --from-literal=token="$TOKEN" \
  --namespace=logging

# Verify secret was created
kubectl get secret kibana-token -n logging
```

**After creating the token, restart Kibana:**
```bash
kubectl rollout restart deployment/kibana -n logging
```

**You only need to do this once** - the token is stored in the Kubernetes secret and reused automatically.

## 🌐 Access Kibana

### Via Ingress (Recommended):
```bash
# Get the Ingress external IP (from MetalLB)
kubectl get ingress -n logging

# Access Kibana using the ingress hostname/IP
# Example: http://kibana.local or http://<EXTERNAL-IP>
```

### Login Credentials:
- Username: `elastic`
- Password: `changeme123`

**Note:** Make sure your Ingress controller is configured and the hostname resolves to your MetalLB IP.

## 📊 View Logs in Kibana

1. **Create Data View:**
   - Go to **Stack Management** → **Data Views**
   - Click **Create data view**
   - Index pattern: `filebeat-*`
   - Timestamp field: `@timestamp`
   - Click **Save**

2. **View Logs:**
   - Go to **Discover**
   - Select the `filebeat-*` data view
   - You'll see all logs from all namespaces!

3. **Useful Filters:**
   - `kubernetes.namespace: "default"` - Logs from default namespace
   - `kubernetes.pod.name: "pod-name"` - Logs from specific pod
   - `kubernetes.deployment.name: "deployment"` - Logs from deployment
   - `log.level: "error"` - Only error logs

## 🔧 Configuration Details

### Elasticsearch
- **Namespace:** `logging`
- **Port:** 9200
- **Storage:** 2Gi PVC
- **Memory:** 1-2Gi
- **Security:** Enabled with basic auth

### Kibana
- **Namespace:** `logging`
- **Port:** 5601
- **Connected to:** Elasticsearch

### Logstash
- **Namespace:** `logging`
- **Input:** Beats on port 5044 + HTTP on port 8080
- **Output:** Routes to appropriate Elasticsearch indices:
  - Filebeat → `filebeat-YYYY.MM.dd`
  - Other → `logstash-YYYY.MM.dd`

### Filebeat
- **Type:** DaemonSet (runs on all nodes)
- **Namespace:** `logging`
- **Collects from:** ALL namespaces
- **Autodiscover:** Enabled for Kubernetes
- **Output:** Logstash (not direct to Elasticsearch)

## 📝 What Logs Are Collected

Filebeat collects logs from:
- ✅ All pods in all namespaces
- ✅ Container stdout/stderr
- ✅ Kubernetes metadata (pod name, namespace, labels, etc.)
- ✅ Automatic multiline handling (stack traces, etc.)

**Available Fields:**
- `kubernetes.pod.name`
- `kubernetes.namespace`
- `kubernetes.deployment.name`
- `kubernetes.container.name`
- `kubernetes.labels.*`
- `message` - The actual log message
- `log.level` - Log level (if parsed)
- `@timestamp` - When the log was generated

## 🔄 Update Configuration

### To Update Any Component:

1. **Edit the YAML file**
2. **Apply changes:**
   ```bash
   kubectl apply -f <filename>.yaml
   ```
3. **Restart if needed:**
   ```bash
   kubectl rollout restart deployment/<name> -n logging
   # or
   kubectl rollout restart daemonset/<name> -n logging
   ```

### Example: Change Elasticsearch Password

1. Edit `01-elasticsearch-production.yaml:32`
2. Change password in the secret
3. Apply:
   ```bash
   kubectl apply -f 01-elasticsearch-production.yaml
   kubectl rollout restart deployment/elasticsearch -n logging
   ```
4. Update password in Kibana and Logstash configs too!

## 🗑️ Uninstall

### Remove Entire Stack:
```bash
kubectl delete -f /Users/ocv-mazib/k8s/elk2/working-elk-stack/
```

### Or Remove Individual Components:
```bash
kubectl delete -f 04-filebeat-all-namespaces.yaml
kubectl delete -f 03-logstash-production.yaml
kubectl delete -f 02-kibana-production.yaml
kubectl delete -f 01-elasticsearch-production.yaml
```

### Delete Data (Optional):
```bash
# This will delete all indexed logs
kubectl delete namespace logging
```

## 🎯 Common Use Cases

### 1. Debug Application Issues
```
Filter: kubernetes.deployment.name: "my-app"
AND log.level: "error"
```

### 2. Monitor Specific Namespace
```
Filter: kubernetes.namespace: "production"
```

### 3. Track Pod Restarts
```
Filter: message: *restart* OR message: *crash*
```

### 4. View Nginx Access Logs
```
Filter: kubernetes.container.name: "nginx"
```

## ⚠️ Important Notes

1. **Storage:** Elasticsearch uses a 2Gi PVC. Increase if needed in `01-elasticsearch-production.yaml:20`

2. **Memory:** Each component has memory limits. Adjust based on your cluster:
   - Elasticsearch: 1-2Gi
   - Kibana: 512Mi-1Gi
   - Logstash: 512Mi-1Gi
   - Filebeat: 100-200Mi per pod

3. **Security:** The password `changeme123` should be changed in production!

4. **Log Retention:** Logs are kept forever by default. Set up index lifecycle management (ILM) in Kibana to manage retention.

5. **No Metrics:** This stack only collects **logs**, not metrics (CPU/memory usage). Metricbeat was removed.

## 🔍 Troubleshooting

### Pods Not Starting?
```bash
kubectl describe pod <pod-name> -n logging
kubectl logs <pod-name> -n logging
```

### No Logs in Kibana?
```bash
# Check Filebeat is running
kubectl get pods -n logging -l app=filebeat

# Check Filebeat logs
kubectl logs -n logging -l app=filebeat --tail=50

# Check Elasticsearch indices
kubectl exec -n logging <elasticsearch-pod> -- curl -u elastic:changeme123 http://localhost:9200/_cat/indices?v
```

### Kibana Can't Connect?
```bash
# Check Elasticsearch is accessible from Kibana pod
kubectl exec -n logging <kibana-pod> -- curl -u elastic:changeme123 http://elasticsearch:9200
```

### Can't Access Kibana via Ingress?
```bash
# Check Ingress status
kubectl get ingress -n logging
kubectl describe ingress -n logging

# Check if MetalLB assigned an external IP
kubectl get svc -n logging

# Verify Ingress controller is running
kubectl get pods -n ingress-nginx  # or your ingress controller namespace

# Test from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -v http://kibana.logging.svc.cluster.local:5601
```

## 🌐 Networking Setup

This stack is designed to work with:
- **MetalLB** - For LoadBalancer services with external IPs
- **Ingress Controller** - For HTTP/HTTPS routing to Kibana

### Required Components:
1. MetalLB installed and configured with IP pool
2. Ingress controller (nginx, traefik, etc.) installed
3. Ingress resource configured for Kibana (see your ingress YAML)

### Example Ingress Configuration:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kibana-ingress
  namespace: logging
spec:
  ingressClassName: nginx  # or your ingress class
  rules:
  - host: kibana.local  # or your domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kibana
            port:
              number: 5601
```

## 📚 Additional Resources

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Filebeat Documentation](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [MetalLB Documentation](https://metallb.universe.tf/)
- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)

## 📅 Configuration Date

Created: January 15, 2026
- Elasticsearch: 8.19.1
- Kibana: 8.19.1
- Logstash: 8.19.1
- Filebeat: 8.19.1

---

**Status:** ✅ Tested and Working
**Purpose:** Log Collection and Analysis
**Kubernetes:** Compatible with KIND and production clusters
