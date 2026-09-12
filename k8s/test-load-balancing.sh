#!/bin/bash

MINIKUBE_IP=$(minikube ip)

INGRESS_PORT=$(kubectl get svc ingress-nginx-controller \
  -n ingress-nginx \
  -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')

BASE_URL="http://${MINIKUBE_IP}:${INGRESS_PORT}"

TOTAL_REQUESTS=10000
CONCURRENCY=100

RESULT_DIR="/tmp/hello-bye-load-test"

rm -rf "$RESULT_DIR"
mkdir -p "$RESULT_DIR"

echo
echo "========================================"
echo "       HELLO-BYE 40K LOAD TEST"
echo "========================================"
echo "Minikube IP    : ${MINIKUBE_IP}"
echo "Ingress Port   : ${INGRESS_PORT}"
echo "Base URL       : ${BASE_URL}"
echo "Requests/API   : ${TOTAL_REQUESTS}"
echo "Concurrency    : ${CONCURRENCY}"
echo "Total Requests : 40000"
echo "========================================"
echo

test_endpoint() {

    ENDPOINT="$1"
    OUTPUT_FILE="${RESULT_DIR}/${ENDPOINT#/}.txt"

    echo
    echo "----------------------------------------"
    echo "Testing ${ENDPOINT}"
    echo "----------------------------------------"

    START_TIME=$(date +%s.%N)

    seq "$TOTAL_REQUESTS" | xargs -P "$CONCURRENCY" -I {} \
        curl -s --max-time 10 "${BASE_URL}${ENDPOINT}" >> "$OUTPUT_FILE"

    END_TIME=$(date +%s.%N)

    DURATION=$(awk "BEGIN {printf \"%.2f\", ${END_TIME}-${START_TIME}}")

    TOTAL_RESPONSES=$(wc -l < "$OUTPUT_FILE")

    echo "Requests        : ${TOTAL_REQUESTS}"
    echo "Responses       : ${TOTAL_RESPONSES}"
    echo "Failed/Missing  : $((TOTAL_REQUESTS - TOTAL_RESPONSES))"
    echo "Duration        : ${DURATION} seconds"

    echo
    echo "Pod distribution:"
    
    grep -o '"pod_name":"[^"]*"' "$OUTPUT_FILE" \
        | sed 's/"pod_name":"//;s/"//' \
        | sort \
        | uniq -c \
        | sort -nr
}

TEST_START=$(date +%s.%N)

test_endpoint "/hello"
test_endpoint "/hello-health"
test_endpoint "/bye"
test_endpoint "/bye-health"

TEST_END=$(date +%s.%N)

TOTAL_DURATION=$(awk "BEGIN {printf \"%.2f\", ${TEST_END}-${TEST_START}}")

echo
echo "========================================"
echo "           LOAD TEST COMPLETE"
echo "========================================"
echo "Total Requests : 40000"
echo "Total Duration : ${TOTAL_DURATION} seconds"
echo "========================================"
echo
echo "Results saved in:"
echo "${RESULT_DIR}"
echo

