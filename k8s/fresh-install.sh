minikube start --driver=docker
kubectl create namespace cust1-context-hello-bye
kubectl config set-context cust1-context --cluster=minikube --user=minikube --namespace=cust1-context-hello-bye
kubectl config use-context cust1-context
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
#kubectl rollout status deployment/hello-bye --timeout=120s
kubectl get deployment,replicaset,pod
./port-forward.sh
./test-api.sh
