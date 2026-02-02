#!/bin/bash
# Prometheus + Grafana Cleanup Script
# Safely removes monitoring stack from Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=====================================${NC}"
echo -e "${YELLOW}Prometheus + Grafana Cleanup${NC}"
echo -e "${YELLOW}=====================================${NC}"
echo ""

# Check if monitoring namespace exists
if ! kubectl get namespace monitoring &> /dev/null; then
    echo -e "${YELLOW}Monitoring namespace not found. Nothing to clean up.${NC}"
    exit 0
fi

# Show current resources
echo -e "${YELLOW}Current resources in monitoring namespace:${NC}"
kubectl get all -n monitoring
echo ""

# Confirm deletion
read -p "Are you sure you want to delete the monitoring stack? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Deleting Grafana...${NC}"
kubectl delete -f 02-grafana-production.yaml --ignore-not-found=true
echo -e "${GREEN}✓ Grafana deleted${NC}"
echo ""

echo -e "${YELLOW}Deleting Prometheus...${NC}"
kubectl delete -f 01-prometheus-production.yaml --ignore-not-found=true
echo -e "${GREEN}✓ Prometheus deleted${NC}"
echo ""

# Ask about PVCs
read -p "Delete PersistentVolumeClaims (this will delete all metrics and dashboard data)? (yes/no): " DELETE_PVC
if [ "$DELETE_PVC" = "yes" ]; then
    echo -e "${YELLOW}Deleting PVCs...${NC}"
    kubectl delete pvc -n monitoring --all
    echo -e "${GREEN}✓ PVCs deleted${NC}"
else
    echo -e "${YELLOW}Keeping PVCs for data retention${NC}"
fi
echo ""

# Ask about namespace
read -p "Delete monitoring namespace? (yes/no): " DELETE_NS
if [ "$DELETE_NS" = "yes" ]; then
    echo -e "${YELLOW}Deleting namespace...${NC}"
    kubectl delete namespace monitoring
    echo -e "${GREEN}✓ Namespace deleted${NC}"
else
    echo -e "${YELLOW}Keeping monitoring namespace${NC}"
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Cleanup Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

if [ "$DELETE_NS" != "yes" ]; then
    echo -e "${YELLOW}Remaining resources in monitoring namespace:${NC}"
    kubectl get all,pvc -n monitoring 2>/dev/null || echo "No resources remaining"
fi
