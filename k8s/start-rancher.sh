#!/bin/bash

set -e

RANCHER_HOST="rancher.local"

echo "=========================================="
echo " Starting Minikube + Rancher"
echo "=========================================="

echo
echo "Starting Minikube..."
#minikube start --driver=docker

echo
echo "Checking Rancher container..."
if docker ps -a --format '{{.Names}}' | grep -q "^rancher$"; then
    docker start rancher 2>/dev/null || true
else
    echo "ERROR: Rancher container does not exist."
    echo "Run setup-rancher.sh first."
    exit 1
fi

echo
echo "Waiting for Rancher..."

for i in {1..60}; do
    if curl --insecure --silent --fail \
        "https://${RANCHER_HOST}/ping" >/dev/null 2>&1
    then
        break
    fi

    echo "Waiting... $i/60"
    sleep 5
done

echo
echo "Testing Rancher from Ubuntu..."

curl --insecure \
    "https://${RANCHER_HOST}/ping"

echo
echo

echo "Testing Rancher from Minikube..."

docker exec minikube \
    curl --insecure \
    "https://${RANCHER_HOST}/ping"

echo
echo

echo "Checking Rancher agent..."

kubectl get pods -n cattle-system

echo
echo "Checking application Pods..."

kubectl get pods -A

echo
echo "=========================================="
echo " Rancher + Minikube started successfully"
echo "=========================================="
echo
echo "Rancher:"
echo "https://${RANCHER_HOST}"
echo
