```bash
#!/bin/bash

set -euo pipefail

# ============================================================
# Rancher + Minikube Complete Setup
#
# What this script does:
#
# 1. Checks Minikube
# 2. Creates rancher-net
# 3. Connects Minikube to rancher-net
# 4. Starts Rancher
# 5. Configures rancher.local on Ubuntu
# 6. Configures rancher.local inside Minikube
# 7. Waits for Rancher
# 8. Verifies Ubuntu -> Rancher
# 9. Verifies Minikube -> Rancher
# 10. Gets Rancher bootstrap password
# 11. Logs into Rancher API
# 12. Creates Generic Import cluster "minikube"
# 13. Gets the generated registration manifest
# 14. Applies the manifest to Minikube
# 15. Waits for cattle-cluster-agent
# 16. Displays final Rancher status
#
# Rancher URL:
#     https://rancher.local
#
# ============================================================

set +e
command -v jq >/dev/null 2>&1
JQ_EXISTS=$?
set -e

if [ "$JQ_EXISTS" -ne 0 ]; then
    echo "ERROR: jq is required."
    echo
    echo "Install it with:"
    echo
    echo "    sudo apt update && sudo apt install -y jq"
    exit 1
fi

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

RANCHER_NAME="rancher"
RANCHER_HOST="rancher.local"
RANCHER_URL="https://${RANCHER_HOST}"

RANCHER_NETWORK="rancher-net"
RANCHER_SUBNET="172.21.0.0/16"

RANCHER_IMAGE="rancher/rancher:latest"

CLUSTER_NAME="minikube"

echo
echo "============================================================"
echo " Rancher + Minikube Complete Installation"
echo "============================================================"
echo
echo "Rancher URL : $RANCHER_URL"
echo "Cluster     : $CLUSTER_NAME"
echo

# ------------------------------------------------------------
# 1. Check Minikube
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 1: Checking Minikube"
echo "============================================================"

if ! minikube status >/dev/null 2>&1; then
    echo
    echo "ERROR: Minikube is not running."
    echo
    echo "Start it first:"
    echo
    echo "    minikube start --driver=docker"
    exit 1
fi

minikube status

echo
echo "Minikube is running."
echo

# ------------------------------------------------------------
# 2. Remove previous Rancher container
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 2: Removing old Rancher container"
echo "============================================================"

docker rm -f "$RANCHER_NAME" 2>/dev/null || true

echo "Old Rancher container removed."
echo

# ------------------------------------------------------------
# 3. Create Rancher Docker network
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 3: Creating Rancher Docker network"
echo "============================================================"

if docker network inspect "$RANCHER_NETWORK" >/dev/null 2>&1; then
    echo "Network $RANCHER_NETWORK already exists."
else
    docker network create \
        --subnet="$RANCHER_SUBNET" \
        "$RANCHER_NETWORK"

    echo "Network created."
fi

echo

# ------------------------------------------------------------
# 4. Connect Minikube to Rancher network
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 4: Connecting Minikube to Rancher network"
echo "============================================================"

docker network connect "$RANCHER_NETWORK" minikube 2>/dev/null || true

echo
echo "Checking Minikube IP on rancher-net..."

MINIKUBE_RANCHER_IP=$(
    docker inspect minikube \
    --format '{{range .NetworkSettings.Networks}}{{if eq .NetworkID ""}}{{end}}{{end}}' \
    2>/dev/null || true
)

docker network inspect "$RANCHER_NETWORK" \
    --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{println}}{{end}}'

echo

# ------------------------------------------------------------
# 5. Start Rancher
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 5: Starting Rancher"
echo "============================================================"

docker run -d \
    --name "$RANCHER_NAME" \
    --restart=unless-stopped \
    --network "$RANCHER_NETWORK" \
    -p 80:80 \
    -p 443:443 \
    --privileged \
    "$RANCHER_IMAGE"

echo
echo "Rancher container started."
echo

# ------------------------------------------------------------
# 6. Get Rancher IP
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 6: Getting Rancher IP"
echo "============================================================"

RANCHER_IP=""

for i in {1..30}; do

    RANCHER_IP=$(
        docker inspect "$RANCHER_NAME" \
            --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
            2>/dev/null
    )

    if [ -n "$RANCHER_IP" ]; then
        break
    fi

    sleep 1
done

if [ -z "$RANCHER_IP" ]; then
    echo "ERROR: Could not determine Rancher IP."
    exit 1
fi

echo "Rancher IP: $RANCHER_IP"
echo

# ------------------------------------------------------------
# 7. Configure Ubuntu /etc/hosts
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 7: Configuring Ubuntu /etc/hosts"
echo "============================================================"

sudo sed -i "/[[:space:]]${RANCHER_HOST}$/d" /etc/hosts

echo "$RANCHER_IP $RANCHER_HOST" | sudo tee -a /etc/hosts >/dev/null

echo
echo "Verifying:"
getent hosts "$RANCHER_HOST"

echo

# ------------------------------------------------------------
# 8. Configure Minikube /etc/hosts
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 8: Configuring Minikube /etc/hosts"
echo "============================================================"

docker exec minikube sh -c \
    "echo '$RANCHER_IP $RANCHER_HOST' >> /etc/hosts"

echo
echo "Verifying inside Minikube:"
docker exec minikube getent hosts "$RANCHER_HOST"

echo

# ------------------------------------------------------------
# 9. Wait for Rancher
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 9: Waiting for Rancher"
echo "============================================================"

RANCHER_READY="false"

for i in {1..60}; do

    if curl \
        --insecure \
        --silent \
        --fail \
        "$RANCHER_URL/ping" >/dev/null 2>&1
    then
        RANCHER_READY="true"
        break
    fi

    echo "Waiting for Rancher... $i/60"
    sleep 5
done

if [ "$RANCHER_READY" != "true" ]; then

    echo
    echo "ERROR: Rancher did not become ready."
    echo
    echo "Check:"
    echo
    echo "    docker logs rancher"
    exit 1
fi

echo
echo "Rancher is ready."
echo

# ------------------------------------------------------------
# 10. Test Ubuntu -> Rancher
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 10: Testing Ubuntu -> Rancher"
echo "============================================================"

PING_RESULT=$(curl \
    --insecure \
    --silent \
    "$RANCHER_URL/ping")

echo "Rancher response: $PING_RESULT"

if [ "$PING_RESULT" != "pong" ]; then
    echo "ERROR: Ubuntu cannot reach Rancher."
    exit 1
fi

echo

# ------------------------------------------------------------
# 11. Test Minikube -> Rancher
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 11: Testing Minikube -> Rancher"
echo "============================================================"

MINIKUBE_PING=$(
    docker exec minikube \
        curl \
        --insecure \
        --silent \
        "$RANCHER_URL/ping"
)

echo "Minikube response: $MINIKUBE_PING"

if [ "$MINIKUBE_PING" != "pong" ]; then
    echo
    echo "ERROR: Minikube cannot reach Rancher."
    echo
    echo "Testing Rancher IP directly:"
    docker exec minikube \
        curl \
        --insecure \
        "$RANCHER_IP/ping"
    exit 1
fi

echo
echo "Minikube can reach Rancher."
echo

# ------------------------------------------------------------
# 12. Get Rancher bootstrap password
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 12: Getting Rancher bootstrap password"
echo "============================================================"

BOOTSTRAP_PASSWORD=""

for i in {1..30}; do

    BOOTSTRAP_PASSWORD=$(
        docker logs "$RANCHER_NAME" 2>&1 |
        grep "Bootstrap Password" |
        tail -1 |
        sed 's/.*Bootstrap Password:[[:space:]]*//' |
        tr -d '\r'
    )

    if [ -n "$BOOTSTRAP_PASSWORD" ]; then
        break
    fi

    sleep 2
done

if [ -z "$BOOTSTRAP_PASSWORD" ]; then
    echo
    echo "ERROR: Could not find Rancher bootstrap password."
    echo
    echo "Check:"
    echo
    echo "    docker logs rancher 2>&1 | grep 'Bootstrap Password'"
    exit 1
fi

echo
echo "Bootstrap password obtained."
echo

# ------------------------------------------------------------
# 13. Login to Rancher API
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 13: Logging into Rancher API"
echo "============================================================"

LOGIN_RESPONSE=$(
    curl \
        --insecure \
        --silent \
        --fail \
        -X POST \
        "$RANCHER_URL/v3-public/localProviders/local?action=login" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg username "admin" \
            --arg password "$BOOTSTRAP_PASSWORD" \
            '{
                description: "setup-rancher-script",
                responseType: "token",
                username: $username,
                password: $password
            }')"
)

RANCHER_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token // empty')

if [ -z "$RANCHER_TOKEN" ]; then
    echo
    echo "ERROR: Rancher API login failed."
    echo
    echo "$LOGIN_RESPONSE"
    exit 1
fi

echo "Rancher API login successful."
echo

# ------------------------------------------------------------
# 14. Check whether minikube already exists
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 14: Checking existing Rancher cluster"
echo "============================================================"

CLUSTER_ID=$(
    curl \
        --insecure \
        --silent \
        --fail \
        "$RANCHER_URL/v3/clusters" \
        -H "Authorization: Bearer $RANCHER_TOKEN" |
    jq -r \
        --arg NAME "$CLUSTER_NAME" \
        '.data[] | select(.name == $NAME) | .id' |
    head -1
)

if [ -n "$CLUSTER_ID" ] && [ "$CLUSTER_ID" != "null" ]; then

    echo "Cluster '$CLUSTER_NAME' already exists."
    echo "Cluster ID: $CLUSTER_ID"

else

    # --------------------------------------------------------
    # 15. Create Generic Import cluster
    # --------------------------------------------------------

    echo
    echo "============================================================"
    echo "STEP 15: Creating Generic Import cluster"
    echo "============================================================"

    CREATE_RESPONSE=$(
        curl \
            --insecure \
            --silent \
            --fail \
            -X POST \
            "$RANCHER_URL/v1/provisioning.cattle.io.clusters" \
            -H "Authorization: Bearer $RANCHER_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$(jq -n \
                --arg NAME "$CLUSTER_NAME" \
                '{
                    type: "provisioning.cattle.io.cluster",
                    metadata: {
                        namespace: "fleet-default",
                        name: $NAME
                    },
                    spec: {}
                }')"
    )

    echo "$CREATE_RESPONSE" | jq .

    echo
    echo "Generic Import cluster created."
fi

echo

# ------------------------------------------------------------
# 16. Get Rancher management cluster ID
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 16: Getting Rancher cluster ID"
echo "============================================================"

for i in {1..30}; do

    CLUSTER_ID=$(
        curl \
            --insecure \
            --silent \
            "$RANCHER_URL/v3/clusters" \
            -H "Authorization: Bearer $RANCHER_TOKEN" |
        jq -r \
            --arg NAME "$CLUSTER_NAME" \
            '.data[] | select(.name == $NAME) | .id' |
        head -1
    )

    if [ -n "$CLUSTER_ID" ] && [ "$CLUSTER_ID" != "null" ]; then
        break
    fi

    echo "Waiting for Rancher cluster ID..."
    sleep 2
done

if [ -z "$CLUSTER_ID" ] || [ "$CLUSTER_ID" = "null" ]; then
    echo
    echo "ERROR: Could not obtain Rancher cluster ID."
    exit 1
fi

echo
echo "Cluster ID: $CLUSTER_ID"
echo

# ------------------------------------------------------------
# 17. Generate registration token
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 17: Generating registration token"
echo "============================================================"

REGISTRATION_RESPONSE=$(
    curl \
        --insecure \
        --silent \
        --fail \
        -X POST \
        "$RANCHER_URL/v3/clusterregistrationtokens" \
        -H "Authorization: Bearer $RANCHER_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg CLUSTER_ID "$CLUSTER_ID" \
            '{
                clusterId: $CLUSTER_ID
            }')"
)

echo "$REGISTRATION_RESPONSE" | jq .

echo

# ------------------------------------------------------------
# 18. Get registration manifest URL
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 18: Waiting for registration manifest"
echo "============================================================"

MANIFEST_URL=""

for i in {1..60}; do

    REGISTRATION_JSON=$(
        curl \
            --insecure \
            --silent \
            "$RANCHER_URL/v3/clusterregistrationtokens?clusterId=$CLUSTER_ID" \
            -H "Authorization: Bearer $RANCHER_TOKEN"
    )

    MANIFEST_URL=$(
        echo "$REGISTRATION_JSON" |
        jq -r \
            '.data[] |
             select(.name == "default-token") |
             .manifestUrl // empty' |
        head -1
    )

    if [ -n "$MANIFEST_URL" ]; then
        break
    fi

    echo "Waiting for registration manifest... $i/60"
    sleep 2
done

if [ -z "$MANIFEST_URL" ]; then
    echo
    echo "ERROR: Registration manifest URL was not generated."
    echo
    echo "$REGISTRATION_JSON" | jq .
    exit 1
fi

echo
echo "Registration manifest:"
echo
echo "$MANIFEST_URL"
echo

# ------------------------------------------------------------
# 19. Verify manifest uses rancher.local
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 19: Verifying registration manifest"
echo "============================================================"

curl \
    --insecure \
    --silent \
    --fail \
    "$MANIFEST_URL" \
    -o /tmp/rancher-import.yaml

CATTLE_SERVER=$(
    grep -A1 "name: CATTLE_SERVER" /tmp/rancher-import.yaml |
    grep "value:" |
    sed 's/.*value:[[:space:]]*//' |
    tr -d '"'
)

echo
echo "CATTLE_SERVER = $CATTLE_SERVER"
echo

if [ "$CATTLE_SERVER" != "$RANCHER_URL" ]; then

    echo
    echo "ERROR: CATTLE_SERVER is not $RANCHER_URL"
    echo "Refusing to register cluster."
    exit 1
fi

echo "CATTLE_SERVER verification successful."
echo

# ------------------------------------------------------------
# 20. Import Minikube
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 20: Registering Minikube with Rancher"
echo "============================================================"

kubectl apply -f /tmp/rancher-import.yaml

echo
echo "Rancher registration manifest applied."
echo

# ------------------------------------------------------------
# 21. Wait for cattle-cluster-agent
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 21: Waiting for cattle-cluster-agent"
echo "============================================================"

for i in {1..60}; do

    if kubectl get deployment cattle-cluster-agent \
        -n cattle-system >/dev/null 2>&1
    then

        READY_REPLICAS=$(
            kubectl get deployment cattle-cluster-agent \
                -n cattle-system \
                -o jsonpath='{.status.readyReplicas}' 2>/dev/null
        )

        if [ "${READY_REPLICAS:-0}" -ge 1 ]; then
            break
        fi
    fi

    echo "Waiting for cattle-cluster-agent... $i/60"
    sleep 5
done

echo

# ------------------------------------------------------------
# 22. Show cattle-system
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 22: Rancher agent status"
echo "============================================================"

kubectl get pods -n cattle-system

echo

# ------------------------------------------------------------
# 23. Final cluster status
# ------------------------------------------------------------

echo "============================================================"
echo "STEP 23: Final Kubernetes status"
echo "============================================================"

kubectl get nodes

echo

echo "============================================================"
echo "STEP 24: Final Rancher cluster status"
echo "============================================================"

FINAL_CLUSTER=$(
    curl \
        --insecure \
        --silent \
        "$RANCHER_URL/v3/clusters/$CLUSTER_ID" \
        -H "Authorization: Bearer $RANCHER_TOKEN"
)

echo "$FINAL_CLUSTER" |
    jq '{
        id: .id,
        name: .name,
        state: .state,
        version: .status.version.gitVersion
    }'

echo

echo "============================================================"
echo " SUCCESS"
echo "============================================================"
echo
echo "Rancher URL:"
echo
echo "    $RANCHER_URL"
echo
echo "Rancher cluster:"
echo
echo "    $CLUSTER_NAME"
echo
echo "Cluster ID:"
echo
echo "    $CLUSTER_ID"
echo
echo "Registration manifest:"
echo
echo "    /tmp/rancher-import.yaml"
echo
echo "Your Minikube cluster should now appear as ACTIVE"
echo "in Rancher."
echo
echo "============================================================"
```
