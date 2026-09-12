kubectl delete pods -n argocd --all --grace-period=0 --force
kubectl delete deployment -n argocd --all --force --grace-period=0
kubectl delete statefulset -n argocd --all --force --grace-period=0
kubectl delete replicaset -n argocd --all --force --grace-period=0
kubectl delete service -n argocd --all
kubectl delete configmap -n argocd --all
kubectl delete secret -n argocd --all
kubectl delete role -n argocd --all
kubectl delete rolebinding -n argocd --all
kubectl delete networkpolicy -n argocd --all
kubectl delete serviceaccount -n argocd --all
kubectl delete crd applications.argoproj.io
kubectl delete crd applicationsets.argoproj.io
kubectl delete crd appprojects.argoproj.io
kubectl delete namespace argocd
kubectl create namespace argocd
kubectl get namespace argocd
#docker pull quay.io/argoproj/argocd:v3.5.2
#minikube image load quay.io/argoproj/argocd:v3.5.2
#kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd -w
echo "wait for 30sec for argocd installation"
sleep 30
kubectl get pods -n argocd
kubectl get svc -n argocd
# port forwarding
kubectl port-forward svc/argocd-server -n argocd 8081:443 &
# Argo CD UI
echo "https://localhost:8080/"
# argo cd password:
echo "argo cd password"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
