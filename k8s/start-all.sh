# 1. Start Minikube
minikube start

# 2. Start Loki
kubectl scale statefulset --all --replicas=1 -n loki
kubectl scale deployment --all --replicas=1 -n loki

# 3. Start Alloy
kubectl scale daemonset --all --replicas=1 -n alloy

# 4. Start Grafana
kubectl scale deployment --all --replicas=1 -n grafana

# 5. Start Rancher
kubectl scale deployment --all --replicas=1 -n cattle-system

# 6. Start Argo CD
kubectl scale deployment --all --replicas=1 -n argocd
kubectl scale statefulset --all --replicas=1 -n argocd

# 7. Start Hello-Bye application
kubectl scale deployment hello-bye --replicas=4 -n default

# 8. Check everything
kubectl get pods -A
