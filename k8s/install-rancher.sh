docker pull rancher/rancher:latest
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
docker network inspect rancher-net --format '{{.Name}} {{.IPAM.Config}}'


#7. connect rancher-net to minikube
docker network connect rancher-net minikube
# Validate using below command
docker network inspect rancher-net --format '{{range .Containers}}{{.Name}} -> {{.IPv4Address}}{{println}}{{end}}'

#8. Start rancher docker container
docker run -d --name rancher --restart=unless-stopped --network rancher-net -p 80:80 -p 443:443 --privileged  rancher/rancher:latest

# validate

docker ps --filter name=rancher

#9. get rancher docker IP
RANCHER_IP=`docker inspect rancher --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'`


#10. add this IP in /etc/hosts
sudo sed -i '/rancher\.local/d' /etc/hosts
echo "$RANCHER_IP rancher.local" | sudo tee -a /etc/hosts
curl -k https://rancher.local/ping

# validate from minikube, ping should show pong
docker exec minikube sh -c 'echo "$RANCHER_IP rancher.local" >> /etc/hosts'
docker exec minikube curl -k https://rancher.local/ping

echo "#11. If Step 10 fails
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
"

echo "wait for sometime"
echo "open: rancher.local"
echo "verify IP using docker inspect rancher --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"
echo "get password using: docker logs rancher 2>&1 | grep -i \"bootstrap password\""
echo "new password: mvaK5xS1oqjZha0u"


echo "14. import Existsing Cluster -> generic -> minikube -> Create
Run the kubectl command below on an existing Kubernetes cluster running a supported Kubernetes version to import it into Rancher:
kubectl apply -f https://rancher.local/v3/import/95b9bq5wkdbxmvcglsldqj7s8k8j7cmj5ct48nrp6nkcf8f47rpx7s_c-vhzxv.yaml
If you get a "certificate signed by unknown authority" error, your Rancher installation has a self-signed or untrusted SSL certificate. Run the command below instead to bypass the certificate verification:
curl --insecure -sfL https://rancher.local/v3/import/95b9bq5wkdbxmvcglsldqj7s8k8j7cmj5ct48nrp6nkcf8f47rpx7s_c-vhzxv.yaml | kubectl apply -f -
If you get permission errors creating some of the resources, your user may not have the cluster-admin role. Use this command to apply it:
kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user <your username from your kubeconfig>
"
echo "keep on checking logs here: docker logs rancher"
echo "wait for sometime for minikube to be Active"