CONTEXT="demo-context"
minikube start --driver=docker
kubectl create namespace $CONTEXT-hello-bye
kubectl config set-context $CONTEXT --cluster=minikube --user=minikube --namespace=$CONTEXT-hello-bye
kubectl config use-context $CONTEXT
kubectl apply -f hello-bye-deployment.yaml
kubectl get deployments
kubectl get replicasets
kubectl get pods
kubectl apply -f hello-service.yaml 
kubectl get svc
kubectl get endpointslice
kubectl apply -f bye-service.yaml
kubectl get svc
kubectl get deployment,replicaset,pod
echo "will wait for 2 minutes for starting of pod"
kubectl rollout status deployment/hello-bye --timeout=120s
kubectl get deployment,replicaset,pod
./port-forward.sh
sleep 2
./test-api.sh
kubectl get pods -A
docker ps -a
docker images
echo "if still pods are not initialized, then run below commands"
echo "kubectl get pods -A"
echo "docker ps -a"
echo "docker images"
echo "kubectl get deployment,replicaset,pod"
echo "./port-forward.sh"
echo "sleep 2"
echo "./test-api.sh"
