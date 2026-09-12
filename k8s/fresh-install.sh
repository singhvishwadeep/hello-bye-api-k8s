CONTEXT="${1:demo-context}"
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
minikube addons enable ingress
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
# HTTP traffic entering the Minikube node on port 32310 will reach the NGINX Ingress Controller.
# vishwadeep@Ubuntu2604:~/Desktop/hello-bye-api-k8s/k8s$ kubectl get svc -n ingress-nginx
# NAME                                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
# ingress-nginx-controller             NodePort    10.102.107.151   <none>        80:32310/TCP,443:31807/TCP   94s
# ingress-nginx-controller-admission   ClusterIP   10.107.124.145   <none>        443/TCP                      94s

minikube ip
# We want to make setup as
# http://<minikube-ip>:32310/hello
# http://<minikube-ip>:32310/bye

kubectl apply -f ingress.yaml
kubectl get ingress -n $CONTEXT-hello-bye
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
echo "----------------------------------------------"
echo "Context:    $CONTEXT-hello-bye"
echo "----------------------------------------------"