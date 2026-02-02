#!/bin/bash
# Prometheus + Grafana Deployment Script
# Deploys monitoring stack to Kubernetes with proper ordering and health checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Prometheus + Grafana Deployment${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Check kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}ERROR: kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check cluster connectivity
echo -e "${YELLOW}Checking Kubernetes cluster connectivity...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}ERROR: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to Kubernetes cluster${NC}"
echo ""

# Deploy Prometheus
echo -e "${YELLOW}1. Deploying Prometheus...${NC}"
kubectl apply -f 01-prometheus-production.yaml

echo ""
echo -e "${YELLOW}Waiting for Prometheus pod to be ready (timeout: 5 minutes)...${NC}"
if kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s; then
    echo -e "${GREEN}✓ Prometheus is ready${NC}"
else
    echo -e "${RED}✗ Prometheus failed to become ready${NC}"
    echo -e "${YELLOW}Checking Prometheus pod status:${NC}"
    kubectl get pods -n monitoring -l app=prometheus
    echo ""
    echo -e "${YELLOW}Prometheus pod logs:${NC}"
    kubectl logs -n monitoring -l app=prometheus --tail=50
    exit 1
fi
echo ""

# Deploy Grafana
echo -e "${YELLOW}2. Deploying Grafana...${NC}"
kubectl apply -f 02-grafana-production.yaml

echo ""
echo -e "${YELLOW}Waiting for Grafana pod to be ready (timeout: 5 minutes)...${NC}"
if kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s; then
    echo -e "${GREEN}✓ Grafana is ready${NC}"
else
    echo -e "${RED}✗ Grafana failed to become ready${NC}"
    echo -e "${YELLOW}Checking Grafana pod status:${NC}"
    kubectl get pods -n monitoring -l app=grafana
    echo ""
    echo -e "${YELLOW}Grafana pod logs:${NC}"
    kubectl logs -n monitoring -l app=grafana --tail=50
    exit 1
fi
echo ""

# Display deployment status
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

echo -e "${YELLOW}Checking deployment status:${NC}"
kubectl get pods -n monitoring
echo ""

echo -e "${YELLOW}Services:${NC}"
kubectl get svc -n monitoring
echo ""

echo -e "${YELLOW}Ingresses:${NC}"
kubectl get ingress -n monitoring
echo ""

# Get admin credentials
ADMIN_USER=$(kubectl get secret grafana-credentials -n monitoring -o jsonpath='{.data.admin-user}' | base64 -d)
ADMIN_PASS=$(kubectl get secret grafana-credentials -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d)

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Access Information${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${YELLOW}Prometheus UI:${NC}"
echo -e "  URL: http://prometheus.localhost"
echo -e "  No authentication required"
echo ""
echo -e "${YELLOW}Grafana UI:${NC}"
echo -e "  URL: http://grafana.localhost"
echo -e "  Username: ${GREEN}${ADMIN_USER}${NC}"
echo -e "  Password: ${GREEN}${ADMIN_PASS}${NC}"
echo -e "  ${RED}⚠ CHANGE PASSWORD IN PRODUCTION!${NC}"
echo ""

echo -e "${YELLOW}Verify Prometheus targets:${NC}"
echo -e "  Visit http://prometheus.localhost/targets"
echo -e "  All targets should show as 'UP'"
echo ""

echo -e "${YELLOW}Grafana datasource:${NC}"
echo -e "  Prometheus datasource is pre-configured"
echo -e "  Test: Settings → Data Sources → Prometheus → Test"
echo ""

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Next Steps${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo "1. Access Grafana at http://grafana.localhost"
echo "2. Login with admin credentials shown above"
echo "3. Navigate to Dashboards → Browse"
echo "4. Explore the pre-loaded Kubernetes dashboard"
echo "5. Import additional dashboards from https://grafana.com/grafana/dashboards/"
echo ""
echo "Recommended dashboards to import:"
echo "  - Kubernetes Cluster Monitoring: 315"
echo "  - Node Exporter Full: 1860"
echo "  - Kubernetes Pods: 6417"
echo ""
echo -e "${GREEN}Deployment completed successfully!${NC}"
