#!/bin/bash

set -e

RANCHER_NAME="rancher"
RANCHER_HOST="rancher.local"
RANCHER_NETWORK="rancher-net"
RANCHER_IMAGE="rancher/rancher:latest"
RANCHER_SUBNET="172.21.0.0/16"

echo
echo "=============================================="
echo " Rancher + Minikube Installation"
echo "=============================================="
echo

# ------------------------------------------------------------
# 1. Check Minikube
# ------------------------------------------------------------

echo "Step 1: Checking Minikube..."

minikube status

echo
echo "Minikube is running."
echo

# ------------------------------------------------------------
# 2. Remove old Rancher container/network
# ------------------------------------------------------------

echo "Step 2: Removing old Rancher installation if present..."

docker rm -f "$RANCHER_NAME" 2>/dev/null || true
docker network rm "$RANCHER_NETWORK" 2>/dev/null || true

echo "Old Rancher installation removed."
echo

# ------------------------------------------------------------
# 3. Create Rancher Docker network
# ------------------------------------------------------------

echo "Step 3: Creating Docker network..."

docker network create \
    --subnet="$RANCHER_SUBNET" \
    "$RANCHER_NETWORK"

echo "Network created: $RANCHER_NETWORK"
echo

# ------------------------------------------------------------
# 4. Connect Minikube to Rancher network
# ------------------------------------------------------------

echo "Step 4: Connecting Minikube to Rancher network..."

docker network connect "$RANCHER_NETWORK" minikube 2>/dev/null || true

echo "Minikube connected to $RANCHER_NETWORK"
echo

# ------------------------------------------------------------
# 5. Start Rancher
# ------------------------------------------------------------

echo "Step 5: Starting Rancher..."

docker run -d \
    --name "$RANCHER_NAME" \
    --restart=unless-stopped \
    --network "$RANCHER_NETWORK" \
    -p 80:80 \
    -p 443:443 \
    --privileged \
    "$RANCHER_IMAGE"

echo "Rancher container started."
echo

# ------------------------------------------------------------
# 6. Get Rancher Docker IP
# ------------------------------------------------------------

echo "Step 6: Getting Rancher IP..."

RANCHER_IP=$(docker inspect rancher \
    --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

echo "Rancher IP: $RANCHER_IP"
echo

# ------------------------------------------------------------
# 7. Configure Ubuntu /etc/hosts
# ------------------------------------------------------------

echo "Step 7: Configuring Ubuntu hostname..."

sudo sed -i "/[[:space:]]$RANCHER_HOST$/d" /etc/hosts

echo "$RANCHER_IP $RANCHER_HOST" | sudo tee -a /etc/hosts

echo
echo "Ubuntu hostname configured."
echo

# ------------------------------------------------------------
# 8. Configure Minikube /etc/hosts
# ------------------------------------------------------------

echo "Step 8: Configuring Minikube hostname..."

docker exec minikube sh -c \
    "echo '$RANCHER_IP $RANCHER_HOST' >> /etc/hosts"

echo "Minikube hostname configured."
echo

# ------------------------------------------------------------
# 9. Verify Ubuntu hostname
# ------------------------------------------------------------

echo "Step 9: Verifying Ubuntu DNS..."

getent hosts "$RANCHER_HOST"

echo

# ------------------------------------------------------------
# 10. Wait for Rancher to become ready
# ------------------------------------------------------------

echo "Step 10: Waiting for Rancher..."

for i in {1..60}; do

    if curl --insecure --silent --fail \
        "https://$RANCHER_HOST/ping" >/dev/null 2>&1
    then
        echo "Rancher is ready."
        break
    fi

    echo "Waiting... ($i/60)"
    sleep 5

done

echo

# ------------------------------------------------------------
# 11. Test Rancher from Ubuntu
# ------------------------------------------------------------

echo "Step 11: Testing Rancher from Ubuntu..."

curl --insecure \
    "https://$RANCHER_HOST/ping"

echo
echo

# ------------------------------------------------------------
# 12. Test Rancher IP from Minikube
# ------------------------------------------------------------

echo "Step 12: Testing Rancher directly from Minikube..."

docker exec minikube \
    curl --insecure \
    "https://$RANCHER_IP/ping"

echo
echo

# ------------------------------------------------------------
# 13. Test Rancher hostname from Minikube
# ------------------------------------------------------------

echo "Step 13: Testing Rancher hostname from Minikube..."

docker exec minikube \
    getent hosts "$RANCHER_HOST"

echo

docker exec minikube \
    curl --insecure \
    "https://$RANCHER_HOST/ping"

echo
echo

# ------------------------------------------------------------
# 14. Display final information
# ------------------------------------------------------------

echo "=============================================="
echo " Rancher Installation Successful"
echo "=============================================="
echo
echo "Rancher IP      : $RANCHER_IP"
echo "Rancher URL     : https://$RANCHER_HOST"
echo "Docker Network  : $RANCHER_NETWORK"
echo
echo "Open Rancher:"
echo
echo "    https://$RANCHER_HOST"
echo
echo "Initial bootstrap password:"
echo
echo "    docker logs rancher 2>&1 | grep 'Bootstrap Password'"
echo
echo "=============================================="

