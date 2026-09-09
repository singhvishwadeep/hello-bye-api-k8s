./kill-port-forward.sh
minikube delete
docker stop $(docker ps -q)
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images -q)

minikube delete --all --purge
docker rm -f $(docker ps -aq --filter "name=minikube") 2>/dev/null || true
docker rm -f rancher 2>/dev/null || true
docker network rm rancher-net 2>/dev/null || true
# remove rancher.local /etc/hosts
sudo sed -i '/rancher\.local/d' /etc/hosts
# clear all contexts
kubectl config delete-context cust1-context
kubectl config delete-cluster minikube
kubectl config delete-user minikube
# remove all networks
docker network rm banking-monitoring banking-network hello-network
# remove all images
docker image prune -a
