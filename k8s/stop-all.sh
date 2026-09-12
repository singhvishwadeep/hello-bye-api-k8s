# 1. Stop Argo CD
kubectl scale deployment --all --replicas=0 -n argocd
kubectl scale statefulset --all --replicas=0 -n argocd

# 2. Stop Rancher
kubectl scale deployment --all --replicas=0 -n cattle-system

# 3. Stop Alloy
kubectl scale daemonset --all --replicas=0 -n alloy

# 4. Stop Grafana
kubectl scale deployment --all --replicas=0 -n grafana

# 5. Stop Loki
kubectl scale statefulset --all --replicas=0 -n loki
kubectl scale deployment --all --replicas=0 -n loki

# 6. Stop Hello-Bye application
kubectl scale deployment hello-bye --replicas=0 -n default

# 7. Finally stop Minikube
minikube stop
