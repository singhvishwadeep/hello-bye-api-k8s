#rancher final steps 

# if want to clear everything
$ minikube delete --all --purge
$ docker rm -f $(docker ps -aq --filter "name=minikube") 2>/dev/null || true
$ docker rm -f rancher 2>/dev/null || true
$ docker network rm rancher-net 2>/dev/null || true
# remove rancher.local /etc/hosts
$ sudo sed -i '/rancher\.local/d' /etc/hosts
# clear all contexts
kubectl config delete-context cust1-context
kubectl config delete-cluster minikube
kubectl config delete-user minikube
# remove all networks
docker network rm banking-monitoring banking-network hello-network
# remove all images
docker image prune -a


# 1. Pull docker image
docker pull rancher/rancher:latest
# we will make our rancher available at https://rancher.local

#2. verify previous cleanup for rancher, 
# there shouldn't be any rancher docker
docker ps --filter name=rancher

#3. there shoudn't be any rancher network
# if present, docker network rm rancher-net
docker network ls | grep rancher

#4. check /etc/hosts shouldn't have any entry for rancher.local
# if present, remove line for rancher.local
grep -E 'rancher|172\.21\.0\.' /etc/hosts

#5. minikube should be running
docker ps --filter name=minikube
minikube status
kubectl get nodes

#6. Create the dedicated Docker network
docker network create rancher-net
# validate using below command - shows subnet 172.21.0.0/16
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker network inspect rancher-net --format '{{.Name}} {{.IPAM.Config}}'
rancher-net [{172.21.0.0/16 invalid Prefix 172.21.0.1 map[]}]
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 

#7. connect rancher-net to minikube
docker network connect rancher-net minikube
# Validate using below command
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker network inspect rancher-net \
  --format '{{range .Containers}}{{.Name}} -> {{.IPv4Address}}{{println}}{{end}}'
minikube -> 172.21.0.2/16
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 

#8. Start rancher docker container
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker run -d --name rancher --restart=unless-stopped --network rancher-net -p 80:80 -p 443:443 --privileged  rancher/rancher:latest
5b418fa0b7a6c81209461207419c18d9b5709db08de9b45b00241b33bc771f6c
# validate
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker ps --filter name=rancher
CONTAINER ID   IMAGE                    COMMAND           CREATED          STATUS          PORTS                                                                          NAMES
5b418fa0b7a6   rancher/rancher:latest   "entrypoint.sh"   18 seconds ago   Up 17 seconds   0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp   rancher
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 

#9. get rancher docker IP
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker inspect rancher --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
172.21.0.3
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$

#10. add this IP in /etc/hosts
$ echo "172.21.0.3 rancher.local" | sudo tee -a /etc/hosts
# validate from local, it should show pong
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ curl -k https://rancher.local/ping
pong
# validate from minikube, ping should show pong
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker exec minikube curl -k https://rancher.local/ping
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100     4  100     4    0     0    624      0 --:--:-- --:--:-- --:--:--   666
pong

#11. If Step 10 fails
# check route to minikube
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker exec minikube ip route
default via 192.168.49.1 dev eth0 
10.244.0.0/16 dev bridge proto kernel scope link src 10.244.0.1 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
172.21.0.0/16 dev eth1 proto kernel scope link src 172.21.0.2 
192.168.49.0/24 dev eth0 proto kernel scope link src 192.168.49.2 

# Test IP directly, instead of URL rancher.local
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker exec minikube curl -vk https://172.21.0.3/ping
pong

# Now set minikube /etc/hosts
$ docker exec minikube sh -c 'echo "172.21.0.3 rancher.local" >> /etc/hosts'
#validate above
$ docker exec minikube getent hosts rancher.local
172.21.0.3      rancher.local

# now it will be proper
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker exec minikube curl -k https://rancher.local/ping
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100     4  100     4    0     0    607      0 --:--:-- --:--:-- --:--:--   666
pong
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 

#12. Now open https://rancher.local in browser
# Proceed to rancher.local (unsafe)
# fetch password
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker logs rancher 2>&1 | grep -i "bootstrap password"
2026/09/08 23:44:29 [WARNING] A bootstrap password secret was found, but did not match the expected structure.
2026/09/08 23:44:29 [INFO] A bootstrap password has been generated for your admin user.
2026/09/08 23:44:29 [INFO] Bootstrap Password: 8qfc8kxxrf4kbbm89r8tfxllx8cf4jrp8z56t66dfx9l7lszwswsn6
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 
# New password: vj6CgmPl461F9145

#13. Validate server-url in Global Settings
server-url Modified
Default Explorer install url. Must be HTTPS. All nodes in your cluster must be able to reach this.
https://rancher.local



#14. import Existsing Cluster -> generic -> minikube -> Create
Run the kubectl command below on an existing Kubernetes cluster running a supported Kubernetes version to import it into Rancher:
kubectl apply -f https://rancher.local/v3/import/95b9bq5wkdbxmvcglsldqj7s8k8j7cmj5ct48nrp6nkcf8f47rpx7s_c-vhzxv.yaml
If you get a "certificate signed by unknown authority" error, your Rancher installation has a self-signed or untrusted SSL certificate. Run the command below instead to bypass the certificate verification:
curl --insecure -sfL https://rancher.local/v3/import/95b9bq5wkdbxmvcglsldqj7s8k8j7cmj5ct48nrp6nkcf8f47rpx7s_c-vhzxv.yaml | kubectl apply -f -
If you get permission errors creating some of the resources, your user may not have the cluster-admin role. Use this command to apply it:
kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user <your username from your kubeconfig>

#Validate Download the generated manifest without applying it
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ curl --insecure -sfL 'https://rancher.local/v3/import/d69kvg5nt2bjj796q47l762mh7b74w5s6zhrfcrd5svtj4wwm7sb6b_c-4mzcw.yaml' -o /tmp/rancher-import.yaml
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ sed -n '160,172p' /tmp/rancher-import.yaml
        key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
      containers:
        - name: cluster-register
          imagePullPolicy: IfNotPresent
          env:
          - name: CATTLE_SERVER
            value: "https://rancher.local"
          - name: CATTLE_CA_CHECKSUM
            value: "6f84b6750f75aaed2b3f39eb79dd8334f612d3ae11b79a935136da2c92f8f6ae"
          - name: CATTLE_CLUSTER
            value: "true"
          - name: CATTLE_K8S_MANAGED
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 
# above should have value: "https://rancher.local"
# now apply
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl apply -f /tmp/rancher-import.yaml
clusterrole.rbac.authorization.k8s.io/proxy-clusterrole-kubeapiserver unchanged
clusterrolebinding.rbac.authorization.k8s.io/proxy-role-binding-kubernetes-master unchanged
namespace/cattle-system unchanged
serviceaccount/cattle unchanged
clusterrolebinding.rbac.authorization.k8s.io/cattle-admin-binding unchanged
secret/cattle-credentials-ad6c77f760 unchanged
clusterrole.rbac.authorization.k8s.io/cattle-admin unchanged
deployment.apps/cattle-cluster-agent configured
service/cattle-cluster-agent unchanged
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 

# validate using namespace cattle-system
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get pods -n cattle-system
NAME                                   READY   STATUS                  RESTARTS   AGE
cattle-cluster-agent-579877d55-m6mgh   1/1     Running                 0          23s
helm-operation-tbx4f                   0/2     Init:ImagePullBackOff   0          103s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get pods -n cattle-system
NAME                                   READY   STATUS     RESTARTS   AGE
cattle-cluster-agent-579877d55-m6mgh   1/1     Running    0          2m23s
helm-operation-tbx4f                   1/2     NotReady   0          3m43s
rancher-webhook-5544559fc9-qp62z       1/1     Running    0          108s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 


#Debug using API
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ curl -k -s \
  -X POST \
  'https://rancher.local/v3-public/localProviders/local?action=login' \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"JGWbL04v0v4bP78q"}'
{"baseType":"token","expiresAt":"2026-09-09T15:24:58Z","id":"token-5v7pl","token":"token-5v7pl:cb9p4q796w4fkn4jbs74vxtzczgsfsl9kgtkxm8m2fbjvnxw55bzfg","type":"token"}
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ curl -k -s \
  'https://rancher.local/v3/clusters/c-4mzcw' \
  -H 'Authorization: Bearer token-5v7pl:cb9p4q796w4fkn4jbs74vxtzczgsfsl9kgtkxm8m2fbjvnxw55bzfg' | jq '{
    id,
    name,
    state,
    transitioning,
    transitionMessage,
    conditions
  }'
{
  "id": "c-4mzcw",
  "name": "minikube",
  "state": "unavailable",
  "transitioning": "yes",
  "transitionMessage": null,
  "conditions": [
    {
      "lastUpdateTime": "2026-09-08T23:14:17Z",
      "status": "True",
      "type": "CreatorMadeOwner"
    },
    {
      "lastUpdateTime": "2026-09-08T23:14:17Z",
      "status": "True",
      "type": "InitialRolesPopulated"
    },
    {
      "lastUpdateTime": "2026-09-08T23:14:17Z",
      "status": "True",
      "type": "BackingNamespaceCreated"
    },
    {
      "lastUpdateTime": "2026-09-08T23:14:17Z",
      "status": "True",
      "type": "DefaultProjectCreated"
    },
    {
      "lastUpdateTime": "2026-09-08T23:14:17Z",
      "status": "True",
      "type": "SystemProjectCreated"
    },
    {
      "lastUpdateTime": "2026-09-08T23:16:02Z",
      "status": "True",
      "type": "Pending"
    },
    {
      "lastUpdateTime": "2026-09-08T23:16:07Z",
      "status": "True",
      "type": "Provisioned"
    },
    {
      "lastUpdateTime": "2026-09-08T23:16:32Z",
      "status": "True",
      "type": "Waiting"
    },
    {
      "lastUpdateTime": "2026-09-08T23:14:18Z",
      "status": "True",
      "type": "NoDiskPressure"
    },
    {
      "lastUpdateTime": "2026-09-08T23:14:18Z",
      "status": "True",
      "type": "NoMemoryPressure"
    },
    {
      "lastUpdateTime": "2026-09-08T23:14:18Z",
      "status": "True",
      "type": "ServiceAccountSecretsMigrated"
    },
    {
      "lastUpdateTime": "2026-09-08T23:18:26Z",
      "status": "False",
      "type": "Connected"
    },
    {
      "lastUpdateTime": "2026-09-08T23:16:03Z",
      "status": "True",
      "type": "AgentTlsStrictCheck"
    },
    {
      "lastUpdateTime": "2026-09-08T23:16:06Z",
      "status": "True",
      "type": "AgentDeployed"
    },
    {
      "lastUpdateTime": "2026-09-08T23:16:03Z",
      "status": "True",
      "type": "SystemAccountCreated"
    },
    {
      "lastUpdateTime": "2026-09-08T23:16:08Z",
      "status": "True",
      "type": "Updated"
    },
    {
      "lastUpdateTime": "2026-09-08T23:16:08Z",
      "status": "True",
      "type": "GlobalAdminsSynced"
    },
    {
      "lastUpdateTime": "2026-09-08T23:18:26Z",
      "message": "Cluster agent is not connected",
      "reason": "Disconnected",
      "status": "False",
      "type": "Ready"
    }
  ]
}
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 



# rancher
docker pull rancher/rancher:latest
docker network create rancher-net
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker run -d \
  --name rancher \
  --restart=unless-stopped \
  --network rancher-net \
  -p 80:80 \
  -p 443:443 \
  --privileged \
  rancher/rancher:latest
ba250a3198ebf8c00744a8d9583cc9cf8ea4b1de1eaaee78c50be5746f6b8082
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker ps
CONTAINER ID   IMAGE                                 COMMAND                  CREATED          STATUS          PORTS                                                                                                                                  NAMES
ba250a3198eb   rancher/rancher:latest                "entrypoint.sh"          21 seconds ago   Up 20 seconds   0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp                                                           rancher
ae139b9aa4c9   gcr.io/k8s-minikube/kicbase:v0.0.50   "/usr/local/bin/entr…"   2 hours ago      Up 2 hours      127.0.0.1:32798->22/tcp, 127.0.0.1:32799->2376/tcp, 127.0.0.1:32800->5000/tcp, 127.0.0.1:32801->8443/tcp, 127.0.0.1:32802->32443/tcp   minikube
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker network inspect rancher-net
[
    {
        "Name": "rancher-net",
        "Id": "ef33526e6882a69e034b4f293b881b30b1d6b1989eeb419959365598b6db89de",
        "Created": "2026-09-08T10:22:20.473971678+05:30",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.21.0.0/16",
                    "Gateway": "172.21.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Options": {},
        "Labels": {},
        "Containers": {
            "ae139b9aa4c9b832f055896f35f47650b4b88b92859837385666b62ec242a60d": {
                "Name": "minikube",
                "EndpointID": "f3f102a8c2009266c0adf028cd898f8128ecc6af7ec9bbf738074660f070dc27",
                "MacAddress": "0e:79:ff:3a:d0:2f",
                "IPv4Address": "172.21.0.3/16",
                "IPv6Address": ""
            },
            "ba250a3198ebf8c00744a8d9583cc9cf8ea4b1de1eaaee78c50be5746f6b8082": {
                "Name": "rancher",
                "EndpointID": "e70ed80d840a982476d85b19885ad056eb00e7ca86cd9654e320b97ae57f86b3",
                "MacAddress": "56:f8:fa:2a:84:23",
                "IPv4Address": "172.21.0.2/16",
                "IPv6Address": ""
            }
        },
        "Status": {
            "IPAM": {
                "Subnets": {
                    "172.21.0.0/16": {
                        "IPsInUse": 5,
                        "DynamicIPsAvailable": 65531
                    }
                }
            }
        }
    }
]
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 
# Rancher UI: https://localhost
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 
# will take some time to load
docker logs -f rancher
#rancher password
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker logs rancher 2>&1 | grep -i "bootstrap password"
2026/09/08 05:05:51 [WARNING] A bootstrap password secret was found, but did not match the expected structure.
2026/09/08 05:05:52 [INFO] A bootstrap password has been generated for your admin user.
2026/09/08 05:05:52 [INFO] Bootstrap Password: kwmdt7x2fmstrz4hfxn6rt7wvr8xrtwv56p5ggd528pgnmnqhq8lvw
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 


# New password: IhfHjJeaTw08qy7W
# Rancher UI: https://localhost


#Registration of minikube to Rancher
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ curl --insecure -sfL https://localhost:4443/v3/import/c9jnpt556lcs49thwqtqmbc5627rsl4rq5qcp2rp7t4tmk95hhrtsd_c-bw7z9.yaml | kubectl apply -f -
clusterrole.rbac.authorization.k8s.io/proxy-clusterrole-kubeapiserver created
clusterrolebinding.rbac.authorization.k8s.io/proxy-role-binding-kubernetes-master created
namespace/cattle-system created
serviceaccount/cattle created
clusterrolebinding.rbac.authorization.k8s.io/cattle-admin-binding created
secret/cattle-credentials-89f74e1891 created
clusterrole.rbac.authorization.k8s.io/cattle-admin created
deployment.apps/cattle-cluster-agent created
service/cattle-cluster-agent created
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ curl --insecure -sfL https://localhost:4443/v3/import/c9jnpt556lcs49thwqtqmbc5627rsl4rq5qcp2rp7t4tmk95hhrtsd_c-bw7z9.yaml | kubectl apply -f -
clusterrole.rbac.authorization.k8s.io/proxy-clusterrole-kubeapiserver unchanged
clusterrolebinding.rbac.authorization.k8s.io/proxy-role-binding-kubernetes-master unchanged
namespace/cattle-system unchanged
serviceaccount/cattle unchanged
clusterrolebinding.rbac.authorization.k8s.io/cattle-admin-binding unchanged
secret/cattle-credentials-89f74e1891 unchanged
clusterrole.rbac.authorization.k8s.io/cattle-admin unchanged
deployment.apps/cattle-cluster-agent configured
service/cattle-cluster-agent unchanged
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ curl --insecure -sfL https://localhost:4443/v3/import/c9jnpt556lcs49thwqtqmbc5627rsl4rq5qcp2rp7t4tmk95hhrtsd_c-bw7z9.yaml | kubectl apply -f -^C
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get pods -A
NAMESPACE                 NAME                                    READY   STATUS    RESTARTS        AGE
cattle-system             cattle-cluster-agent-7b886cfbbc-jg9qn   0/1     Error     5 (2m33s ago)   5m16s
cust1-context-hello-bye   hello-bye-74bc9c6489-4xkxt              2/2     Running   0               59m
cust1-context-hello-bye   hello-bye-74bc9c6489-d5wkx              2/2     Running   0               59m
cust1-context-hello-bye   hello-bye-74bc9c6489-mrlt4              2/2     Running   0               59m
cust1-context-hello-bye   hello-bye-74bc9c6489-v5ffr              2/2     Running   0               59m
kube-system               coredns-7d764666f9-sfdpf                1/1     Running   0               59m
kube-system               etcd-minikube                           1/1     Running   0               59m
kube-system               kube-apiserver-minikube                 1/1     Running   0               59m
kube-system               kube-controller-manager-minikube        1/1     Running   0               59m
kube-system               kube-proxy-nb4n4                        1/1     Running   0               59m
kube-system               kube-scheduler-minikube                 1/1     Running   0               59m
kube-system               storage-provisioner                     1/1     Running   1 (58m ago)     59m
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get pods -n cattle-system
NAME                                    READY   STATUS             RESTARTS      AGE
cattle-cluster-agent-7b886cfbbc-jg9qn   0/1     CrashLoopBackOff   5 (85s ago)   5m38s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 

# Setup
Run the kubectl command below on an existing Kubernetes cluster running a supported Kubernetes version to import it into Rancher:
kubectl apply -f https://localhost/v3/import/qssrw97zw7jgqcfszgbnwfg4kdc5n8n7vr5vkv84d245kgq5t8x2fj_c-57n4j.yaml
If you get a "certificate signed by unknown authority" error, your Rancher installation has a self-signed or untrusted SSL certificate. Run the command below instead to bypass the certificate verification:
curl --insecure -sfL https://localhost/v3/import/qssrw97zw7jgqcfszgbnwfg4kdc5n8n7vr5vkv84d245kgq5t8x2fj_c-57n4j.yaml | kubectl apply -f -
If you get permission errors creating some of the resources, your user may not have the cluster-admin role. Use this command to apply it:
kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user <your username from your kubeconfig>


# rancher network
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get pods -n cattle-system
NAME                                    READY   STATUS             RESTARTS       AGE
cattle-cluster-agent-6c59d4bd79-89fbh   0/1     CrashLoopBackOff   6 (2m1s ago)   7m39s
cattle-cluster-agent-7b886cfbbc-pqsj2   0/1     CrashLoopBackOff   3 (14s ago)    60s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker network create rancher-net
ef33526e6882a69e034b4f293b881b30b1d6b1989eeb419959365598b6db89de
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker network connect rancher-net rancher
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker network connect rancher-net minikube
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker network inspect rancher-net
[
    {
        "Name": "rancher-net",
        "Id": "ef33526e6882a69e034b4f293b881b30b1d6b1989eeb419959365598b6db89de",
        "Created": "2026-09-08T10:22:20.473971678+05:30",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.21.0.0/16",
                    "Gateway": "172.21.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Options": {},
        "Labels": {},
        "Containers": {
            "ae139b9aa4c9b832f055896f35f47650b4b88b92859837385666b62ec242a60d": {
                "Name": "minikube",
                "EndpointID": "f3f102a8c2009266c0adf028cd898f8128ecc6af7ec9bbf738074660f070dc27",
                "MacAddress": "0e:79:ff:3a:d0:2f",
                "IPv4Address": "172.21.0.3/16",
                "IPv6Address": ""
            },
            "cb4a02dcb988c907327d6cceb4dbae0070822f213797edfc8da885f7e0fd8a66": {
                "Name": "rancher",
                "EndpointID": "12e6584d7e5ac74f420cfde5a36b1c71e6515f329a8c2d8f7f6266434097addd",
                "MacAddress": "26:a4:62:04:fb:86",
                "IPv4Address": "172.21.0.2/16",
                "IPv6Address": ""
            }
        },
        "Status": {
            "IPAM": {
                "Subnets": {
                    "172.21.0.0/16": {
                        "IPsInUse": 5,
                        "DynamicIPsAvailable": 65531
                    }
                }
            }
        }
    }
]
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ docker exec minikube curl -k -v https://rancher:443/ping
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0*   Trying 172.21.0.2:443...
* Connected to rancher (172.21.0.2) port 443 (#0)
* ALPN: offers h2,http/1.1
} [5 bytes data]
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
} [512 bytes data]
* TLSv1.3 (IN), TLS handshake, Server hello (2):
{ [122 bytes data]
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
{ [25 bytes data]
* TLSv1.3 (IN), TLS handshake, Certificate (11):
{ [955 bytes data]
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
{ [79 bytes data]
* TLSv1.3 (IN), TLS handshake, Finished (20):
{ [36 bytes data]
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
} [1 bytes data]
* TLSv1.3 (OUT), TLS handshake, Finished (20):
} [36 bytes data]
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
* ALPN: server accepted http/1.1
* Server certificate:
*  subject: O=dynamic; CN=dynamic
*  start date: Sep  8 03:37:15 2026 GMT
*  expire date: Sep  8 03:37:15 2027 GMT
*  issuer: O=dynamiclistener-org; CN=dynamiclistener-ca@1788842235
*  SSL certificate verify result: self-signed certificate in certificate chain (19), continuing anyway.
* using HTTP/1.1
} [5 bytes data]
> GET /ping HTTP/1.1
> Host: rancher
> User-Agent: curl/7.88.1
> Accept: */*
> 
{ [5 bytes data]
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
{ [122 bytes data]
< HTTP/1.1 200 OK
< Cache-Control: no-cache, no-store, must-revalidate
< X-Api-Cattle-Auth: false
< X-Content-Type-Options: nosniff
< Date: Tue, 08 Sep 2026 04:54:19 GMT
< Content-Length: 4
< Content-Type: text/plain; charset=utf-8
< 
{ [4 bytes data]
100     4  100     4    0     0    166      0 --:--:-- --:--:-- --:--:--   173
* Connection #0 to host rancher left intact
pong
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/kkubectl get deployment cattle-cluster-agent -n cattle-system \em \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="CATTLE_SERVER")].value}{"\n"}'
https://localhost
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl -n cattle-system set env deployment/cattle-cluster-agent \
  CATTLE_SERVER=https://rancher
deployment.apps/cattle-cluster-agent env updated
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get deployment cattle-cluster-agent -n cattle-system \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="CATTLE_SERVER")].value}{"\n"}'
https://rancher
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 




# to remove rancher
kubectl delete namespace cattle-system
docker network rm rancher-net
docker stop rancher
docker rm rancher