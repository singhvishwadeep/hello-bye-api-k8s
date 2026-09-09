#!/bin/bash

set -e

echo "=========================================="
echo " Stopping Rancher + Minikube"
echo "=========================================="

echo
echo "Stopping Rancher..."
docker stop rancher 2>/dev/null || true

echo "Stopping Minikube..."
minikube stop

echo
echo "=========================================="
echo " Everything stopped"
echo "=========================================="
