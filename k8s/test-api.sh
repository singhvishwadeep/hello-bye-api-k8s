#!/bin/bash

# ============================================================
# HELLO-BYE API TEST
#
# Usage:
#   ./test-api.sh india
#   ./test-api.sh japan
#   ./test-api.sh canada
#   ./test-api.sh australia
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
# 1. Validate argument
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

# ------------------------------------------------------------
# 2. Verify namespace
# ------------------------------------------------------------

if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo
    echo "ERROR: Namespace '$NAMESPACE' does not exist."
    echo
    echo "Available namespaces:"
    kubectl get namespaces
    echo
    exit 1
fi

# ------------------------------------------------------------
# 3. Verify context
# ------------------------------------------------------------

if ! kubectl config get-contexts "$CONTEXT" >/dev/null 2>&1; then
    echo
    echo "ERROR: Kubernetes context '$CONTEXT' does not exist."
    echo
    echo "Available contexts:"
    kubectl config get-contexts
    echo
    exit 1
fi

# ------------------------------------------------------------
# 4. Switch to country context
# ------------------------------------------------------------

kubectl config use-context "$CONTEXT" >/dev/null

# ------------------------------------------------------------
# 5. Get Minikube IP
# ------------------------------------------------------------

MINIKUBE_IP=$(minikube ip)

if [ -z "$MINIKUBE_IP" ]; then
    echo
    echo "ERROR: Could not determine Minikube IP."
    echo
    exit 1
fi

# ------------------------------------------------------------
# 6. Get dynamic Ingress HTTP NodePort
# ------------------------------------------------------------

INGRESS_PORT=$(kubectl get svc ingress-nginx-controller \
    -n ingress-nginx \
    -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')

if [ -z "$INGRESS_PORT" ]; then
    echo
    echo "ERROR: Could not determine Ingress HTTP NodePort."
    echo
    echo "Ingress service:"
    kubectl get svc ingress-nginx-controller -n ingress-nginx
    echo
    exit 1
fi

# ------------------------------------------------------------
# 7. Verify Ingress exists
# ------------------------------------------------------------

INGRESS_NAME=$(kubectl get ingress \
    -n "$NAMESPACE" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [ -z "$INGRESS_NAME" ]; then
    echo
    echo "ERROR: No Ingress found in namespace '$NAMESPACE'."
    echo
    echo "Run:"
    echo "  kubectl get ingress -n $NAMESPACE"
    echo
    exit 1
fi

# ------------------------------------------------------------
# 8. URLs
# ------------------------------------------------------------

BASE_URL="http://${MINIKUBE_IP}:${INGRESS_PORT}"

# ------------------------------------------------------------
# 9. Header
# ------------------------------------------------------------

echo
echo "============================================================"
echo "                  HELLO-BYE API TEST"
echo "============================================================"
echo
echo "Country/Context : $CONTEXT"
echo "Namespace       : $NAMESPACE"
echo "Ingress         : $INGRESS_NAME"
echo "Host            : $HOST"
echo "Minikube IP     : $MINIKUBE_IP"
echo "Ingress Port    : $INGRESS_PORT"
echo "Base URL        : $BASE_URL"
echo
echo "============================================================"
echo

# ------------------------------------------------------------
# Function to test endpoint
# ------------------------------------------------------------

test_endpoint() {

    ENDPOINT="$1"

    echo "Testing $ENDPOINT"
    echo "------------------------------------------------------------"

    RESPONSE=$(curl -s \
        -w "\nHTTP_STATUS:%{http_code}" \
        -H "Host: ${HOST}" \
        "${BASE_URL}${ENDPOINT}")

    HTTP_STATUS=$(echo "$RESPONSE" | sed -n 's/HTTP_STATUS://p')
    BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

    echo "HTTP Status : $HTTP_STATUS"
    echo "Response:"
    echo "$BODY"

    echo

    if [ "$HTTP_STATUS" = "200" ]; then
        echo "RESULT      : PASS"
    else
        echo "RESULT      : FAIL"
    fi

    echo
}

# ------------------------------------------------------------
# 10. Run API tests
# ------------------------------------------------------------

test_endpoint "/hello-health"

test_endpoint "/bye-health"

test_endpoint "/hello"

test_endpoint "/bye"

# ------------------------------------------------------------
# 11. Final status
# ------------------------------------------------------------

echo "============================================================"
echo "                    TEST COMPLETE"
echo "============================================================"
echo
echo "Country    : $CONTEXT"
echo "Namespace  : $NAMESPACE"
echo "Host       : $HOST"
echo
echo "Tested:"
echo "  /hello-health"
echo "  /bye-health"
echo "  /hello"
echo "  /bye"
echo
echo "============================================================"
echo