#!/bin/bash

# ============================================================
# HELLO-BYE API - FRESH INSTALL
#
# Usage:
#   ./fresh-install.sh india
#   ./fresh-install.sh japan
#   ./fresh-install.sh america
#   ./fresh-install.sh greece
#   ./fresh-install.sh canada
#   ./fresh-install.sh australia
#
# Context:
#   india
#
# Namespace:
#   india-hello-bye
#
# Ingress Host:
#   india.local
# ============================================================

set -e

# ------------------------------------------------------------
# 1. Validate country/context argument
# ------------------------------------------------------------

if [ -z "$1" ]; then
    echo
    echo "ERROR: Country/context is required."
    echo
    echo "Usage:"
    echo "  $0 <country>"
    echo
    echo "Examples:"
    echo "  $0 india"
    echo "  $0 japan"
    echo "  $0 america"
    echo "  $0 greece"
    echo "  $0 canada"
    echo "  $0 australia"
    echo
    exit 1
fi

CONTEXT="$1"
NAMESPACE="${CONTEXT}-hello-bye"
HOST="${CONTEXT}.local"

echo
echo "============================================================"
echo "             HELLO-BYE API FRESH INSTALL"
echo "============================================================"
echo
echo "Country/Context : $CONTEXT"
echo "Namespace       : $NAMESPACE"
echo "Ingress Host    : $HOST"
echo
echo "============================================================"
echo


# ------------------------------------------------------------
# 2. Start Minikube
# ------------------------------------------------------------

echo "Starting Minikube..."

minikube start --driver=docker

echo


# ------------------------------------------------------------
# 3. Create namespace
# ------------------------------------------------------------

echo "Creating namespace: $NAMESPACE"

kubectl create namespace "$NAMESPACE" 2>/dev/null || \
echo "Namespace $NAMESPACE already exists."

echo


# ------------------------------------------------------------
# 4. Create Kubernetes context
#
# Context:
#   india
#
# Namespace:
#   india-hello-bye
# ------------------------------------------------------------

echo "Configuring Kubernetes context: $CONTEXT"

kubectl config set-context "$CONTEXT" \
    --cluster=minikube \
    --user=minikube \
    --namespace="$NAMESPACE"

kubectl config use-context "$CONTEXT"

echo

echo "Current context:"
kubectl config current-context

echo

echo "Current namespace:"
kubectl config view --minify \
    -o jsonpath='{..namespace}'

echo
echo


# ------------------------------------------------------------
# 5. Apply application deployment
# ------------------------------------------------------------

echo "============================================================"
echo "             APPLYING APPLICATION"
echo "============================================================"

echo
echo "Applying hello-bye deployment..."

kubectl apply -f hello-bye-deployment.yaml

echo


# ------------------------------------------------------------
# 6. Apply Services
# ------------------------------------------------------------

echo "Applying hello-service..."

kubectl apply -f hello-service.yaml

echo

echo "Applying bye-service..."

kubectl apply -f bye-service.yaml

echo


# ------------------------------------------------------------
# 7. Show application resources
# ------------------------------------------------------------

echo "============================================================"
echo "             APPLICATION RESOURCES"
echo "============================================================"

echo

echo "Deployments:"
kubectl get deployments

echo

echo "ReplicaSets:"
kubectl get replicasets

echo

echo "Pods:"
kubectl get pods

echo

echo "Services:"
kubectl get svc

echo


# ------------------------------------------------------------
# 8. Wait for application rollout
# ------------------------------------------------------------

echo "============================================================"
echo "             WAITING FOR APPLICATION"
echo "============================================================"

echo
echo "Waiting for hello-bye deployment to become ready..."

kubectl rollout status deployment/hello-bye \
    --timeout=120s

echo
echo "Application deployment is ready."

echo

kubectl get deployment,replicaset,pod

echo


# ------------------------------------------------------------
# 9. Enable NGINX Ingress
# ------------------------------------------------------------

echo "============================================================"
echo "             ENABLING NGINX INGRESS"
echo "============================================================"

echo

minikube addons enable ingress

echo


# ------------------------------------------------------------
# 10. Wait for Ingress Controller
# ------------------------------------------------------------

echo "Waiting for NGINX Ingress Controller..."

kubectl rollout status deployment/ingress-nginx-controller \
    -n ingress-nginx \
    --timeout=120s

echo

echo "NGINX Ingress Controller is ready."

echo


# ------------------------------------------------------------
# 11. Show Ingress Controller resources
# ------------------------------------------------------------

echo "Ingress Controller Pods:"

kubectl get pods -n ingress-nginx

echo

echo "Ingress Controller Services:"

kubectl get svc -n ingress-nginx

echo


# ------------------------------------------------------------
# 12. Wait for admission webhook endpoint
# ------------------------------------------------------------

echo "============================================================"
echo "             CHECKING ADMISSION WEBHOOK"
echo "============================================================"

echo

WEBHOOK_SERVICE="ingress-nginx-controller-admission"

echo "Waiting for admission webhook endpoint..."

for i in {1..60}; do

    WEBHOOK_ENDPOINTS=$(kubectl get endpoints \
        "$WEBHOOK_SERVICE" \
        -n ingress-nginx \
        -o jsonpath='{.subsets[*].addresses[*].ip}' \
        2>/dev/null || true)

    if [ -n "$WEBHOOK_ENDPOINTS" ]; then
        echo
        echo "Admission webhook is ready."
        echo "Endpoint: $WEBHOOK_ENDPOINTS"
        break
    fi

    echo "Waiting for admission webhook... ($i/60)"
    sleep 2

done

if [ -z "$WEBHOOK_ENDPOINTS" ]; then
    echo
    echo "ERROR: Admission webhook did not become ready."
    echo
    echo "Run:"
    echo "  kubectl get pods -n ingress-nginx"
    echo "  kubectl get svc -n ingress-nginx"
    echo "  kubectl get endpoints -n ingress-nginx"
    echo
    exit 1
fi

echo


# ------------------------------------------------------------
# 13. Generate country-specific Ingress
# ------------------------------------------------------------
#
# ingress.yaml contains:
#
#   host: __COUNTRY__.local
#
# For:
#
#   ./fresh-install.sh india
#
# it becomes:
#
#   host: india.local
#
# For:
#
#   ./fresh-install.sh japan
#
# it becomes:
#
#   host: japan.local
# ------------------------------------------------------------

echo "============================================================"
echo "             GENERATING INGRESS"
echo "============================================================"

echo

GENERATED_INGRESS="/tmp/${CONTEXT}-hello-bye-ingress.yaml"

sed "s/__COUNTRY__/${CONTEXT}/g" \
    ingress.yaml > "$GENERATED_INGRESS"

echo "Generated Ingress file:"
echo "  $GENERATED_INGRESS"

echo

echo "Ingress Host:"
echo "  $HOST"

echo


# ------------------------------------------------------------
# 14. Apply Ingress
# ------------------------------------------------------------

echo "Applying country-specific Ingress..."

kubectl apply -f "$GENERATED_INGRESS"

echo


# ------------------------------------------------------------
# 15. Verify Ingress
# ------------------------------------------------------------

echo "============================================================"
echo "             INGRESS"
echo "============================================================"

echo

kubectl get ingress -n "$NAMESPACE"

echo


# ------------------------------------------------------------
# 16. Get Minikube IP
# ------------------------------------------------------------

MINIKUBE_IP=$(minikube ip)

echo "Minikube IP:"
echo "  $MINIKUBE_IP"

echo


# ------------------------------------------------------------
# 17. Get dynamic Ingress NodePort
# ------------------------------------------------------------

INGRESS_PORT=$(kubectl get svc ingress-nginx-controller \
    -n ingress-nginx \
    -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')

if [ -z "$INGRESS_PORT" ]; then

    echo
    echo "ERROR: Could not determine Ingress HTTP NodePort."
    echo

    kubectl get svc ingress-nginx-controller \
        -n ingress-nginx

    exit 1
fi

echo "Ingress HTTP NodePort:"
echo "  $INGRESS_PORT"

echo


# ------------------------------------------------------------
# 18. Display URLs
# ------------------------------------------------------------

BASE_URL="http://${MINIKUBE_IP}:${INGRESS_PORT}"

echo "============================================================"
echo "             INGRESS INFORMATION"
echo "============================================================"

echo
echo "Country       : $CONTEXT"
echo "Namespace     : $NAMESPACE"
echo "Host          : $HOST"
echo "Minikube IP   : $MINIKUBE_IP"
echo "Ingress Port  : $INGRESS_PORT"
echo

echo "API URLs:"
echo
echo "  http://${MINIKUBE_IP}:${INGRESS_PORT}/hello"
echo "  http://${MINIKUBE_IP}:${INGRESS_PORT}/hello-health"
echo "  http://${MINIKUBE_IP}:${INGRESS_PORT}/bye"
echo "  http://${MINIKUBE_IP}:${INGRESS_PORT}/bye-health"
echo

echo "Host-based URLs:"
echo
echo "  http://${HOST}/hello"
echo "  http://${HOST}/hello-health"
echo "  http://${HOST}/bye"
echo "  http://${HOST}/bye-health"
echo

echo "============================================================"
echo


# ------------------------------------------------------------
# 19. Test API
# ------------------------------------------------------------

echo "============================================================"
echo "             TESTING API"
echo "============================================================"

echo
sleep 30
./test-api.sh "$CONTEXT"

echo


# ------------------------------------------------------------
# 20. Final resource status
# ------------------------------------------------------------

echo "============================================================"
echo "             FINAL STATUS"
echo "============================================================"

echo

echo "Context:"
kubectl config current-context

echo

echo "Namespace:"
echo "$NAMESPACE"

echo

echo "Deployments:"
kubectl get deployment -n "$NAMESPACE"

echo

echo "ReplicaSets:"
kubectl get replicaset -n "$NAMESPACE"

echo

echo "Pods:"
kubectl get pods -n "$NAMESPACE"

echo

echo "Services:"
kubectl get svc -n "$NAMESPACE"

echo

echo "Ingress:"
kubectl get ingress -n "$NAMESPACE"

echo


# ------------------------------------------------------------
# 21. Other cluster information
# ------------------------------------------------------------

echo "Ingress Controller:"
kubectl get pods -n ingress-nginx

echo

echo "All namespaces:"
kubectl get pods -A

echo


# ------------------------------------------------------------
# 22. Useful commands
# ------------------------------------------------------------

echo "============================================================"
echo "             USEFUL COMMANDS"
echo "============================================================"

echo

echo "Test this country:"
echo "  ./test-api.sh $CONTEXT"

echo

echo "Switch to this context:"
echo "  kubectl config use-context $CONTEXT"

echo

echo "View application:"
echo "  kubectl get deployment,replicaset,pod,svc"

echo

echo "View Ingress:"
echo "  kubectl get ingress -n $NAMESPACE"

echo

echo "============================================================"
echo "             INSTALL COMPLETE"
echo "============================================================"
echo
echo "Context    : $CONTEXT"
echo "Namespace  : $NAMESPACE"
echo "Host       : $HOST"
echo "============================================================"
echo