$ kubectl create namespace argocd
$ kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
vishwadeep@Ubuntu2604:~/Desktop/banking-services$ kubectl get pods -n argocd -w
NAME                                                READY   STATUS              RESTARTS   AGE
argocd-application-controller-0                     0/1     ContainerCreating   0          10s
argocd-applicationset-controller-79bbd8c9cd-pt9rw   0/1     ContainerCreating   0          10s
argocd-dex-server-6cdf75744-9brxf                   0/1     Init:0/1            0          10s
argocd-notifications-controller-65878667c-fd4jw     0/1     ContainerCreating   0          10s
argocd-redis-5f664b9b9c-wqvkg                       0/1     Init:0/1            0          10s
argocd-repo-server-7f58d7cdf7-s9bm2                 0/1     Init:0/1            0          10s
argocd-server-6ccd556fc9-89x7p                      0/1     ContainerCreating   0          10s
vishwadeep@Ubuntu2604:~/Desktop/banking-services$ kubectl get pods -n argocd
NAME                                                READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                     1/1     Running   0          2m32s
argocd-applicationset-controller-79bbd8c9cd-pt9rw   1/1     Running   0          2m32s
argocd-dex-server-6cdf75744-9brxf                   1/1     Running   0          2m32s
argocd-notifications-controller-65878667c-fd4jw     1/1     Running   0          2m32s
argocd-redis-5f664b9b9c-wqvkg                       1/1     Running   0          2m32s
argocd-repo-server-7f58d7cdf7-s9bm2                 1/1     Running   0          2m32s
argocd-server-6ccd556fc9-89x7p                      1/1     Running   0          2m32s
vishwadeep@Ubuntu2604:~/Desktop/banking-services$ 



vishwadeep@Ubuntu2604:~/Desktop/banking-services$ kubectl get svc -n argocd
NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
argocd-applicationset-controller          ClusterIP   10.109.236.101   <none>        7000/TCP,8080/TCP            2m50s
argocd-dex-server                         ClusterIP   10.109.6.110     <none>        5556/TCP,5557/TCP,5558/TCP   2m50s
argocd-metrics                            ClusterIP   10.104.252.87    <none>        8082/TCP                     2m50s
argocd-notifications-controller-metrics   ClusterIP   10.97.235.179    <none>        9001/TCP                     2m50s
argocd-redis                              ClusterIP   10.111.15.247    <none>        6379/TCP                     2m50s
argocd-repo-server                        ClusterIP   10.99.27.29      <none>        8081/TCP,8084/TCP            2m50s
argocd-server                             ClusterIP   10.96.10.44      <none>        80/TCP,443/TCP               2m50s
argocd-server-metrics                     ClusterIP   10.104.117.177   <none>        8083/TCP                     2m49s
vishwadeep@Ubuntu2604:~/Desktop/banking-services$ 

# port forwarding
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Argo CD UI
https://localhost:8080/

# argo cd password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
Xw6wvAJQpMtU3uYQ

username: admin
password: Xw6wvAJQpMtU3uYQ

# Install the Argo CD CLI
VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v${VERSION}/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ argocd version --client
argocd: v3.5.2+e258ee2
  BuildDate: 2026-08-27T09:34:36Z
  GitCommit: e258ee23c3e52266d407572f4bcdfe7d9ed36cb5
  GitTreeState: clean
  GoVersion: go1.26.4
  Compiler: gc
  Platform: linux/amd64
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ argocd login localhost:8080 \
  --username admin \
  --password Xw6wvAJQpMtU3uYQ \
  --insecure

Logged in Successfuly

# validate
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get pods -n argocd
NAME                                                READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                     1/1     Running   0          9m27s
argocd-applicationset-controller-79bbd8c9cd-pt9rw   1/1     Running   0          9m27s
argocd-dex-server-6cdf75744-9brxf                   1/1     Running   0          9m27s
argocd-notifications-controller-65878667c-fd4jw     1/1     Running   0          9m27s
argocd-redis-5f664b9b9c-wqvkg                       1/1     Running   0          9m27s
argocd-repo-server-7f58d7cdf7-s9bm2                 1/1     Running   0          9m27s
argocd-server-6ccd556fc9-89x7p                      1/1     Running   0          9m27s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 

Github PAT for my account
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