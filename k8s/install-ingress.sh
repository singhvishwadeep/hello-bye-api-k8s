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
