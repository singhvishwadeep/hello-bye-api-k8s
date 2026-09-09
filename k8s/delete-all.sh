./kill-port-forward.sh
minikube delete
docker stop $(docker ps -q)
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images -q)