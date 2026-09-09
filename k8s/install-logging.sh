helm repo add grafana https://grafana.github.io/helm-charts
helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm repo update
kubectl create namespace loki
kubectl get namespace loki
# install loki
helm upgrade --install loki grafana-community/loki -n loki -f monitoring/loki/values.yaml

# wait for everything to be up and running
kubectl get pods -n loki
kubectl get pvc -n loki

# install alloy
kubectl create namespace alloy
kubectl get namespace alloy

helm upgrade --install alloy grafana/alloy -n alloy -f monitoring/alloy/values.yaml
kubectl rollout restart daemonset/alloy -n alloy
kubectl get pods -n alloy

# validate from logs that alloy is working fine
kubectl logs -n alloy -l app.kubernetes.io/name=alloy -c alloy --tail=50

# port forward loki
kubectl port-forward -n loki svc/loki 3100:3100 &

echo "RUN curl -v http://localhost:3100/ready"
curl -v http://localhost:3100/ready
echo "CHECK LABELS: curl -s http://localhost:3100/loki/api/v1/labels"
curl -s "http://localhost:3100/loki/api/v1/labels"

curl -s "http://localhost:3100/loki/api/v1/labels"
curl -sG "http://localhost:3100/loki/api/v1/query_range"   --data-urlencode 'query={service_name="admin-api"}'   --data-urlencode 'limit=10'

curl -sG "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job=~".+"}' \
  --data-urlencode 'limit=10'


kubectl create namespace grafana
kubectl get namespace grafana
helm upgrade --install grafana grafana/grafana -n grafana
kubectl get pods -n grafana
echo "Sleeping for 60 sec for grafana to be up and running"
sleep 60
kubectl get pods -n grafana
echo "keep on checking here"
echo "kubectl get pods -n grafana"
echo "to check password for username admin"
kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
echo "The Grafana server can be accessed via port 80 on the following DNS name from within your cluster:

   grafana.grafana.svc.cluster.local

   Get the Grafana URL to visit by running these commands in the same shell:
     export POD_NAME=$(kubectl get pods --namespace grafana -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
     kubectl --namespace grafana port-forward $POD_NAME 3000 &"
echo "grafana available on localhost:3000 username: admin and password from above command and port forwarding"
echo "Add Data Source Loki and add URL: http://loki.loki.svc.cluster.local:3100"

# port forward loki
kubectl port-forward -n loki svc/loki 3100:3100 &
echo "make sure 3100 and 3000 port are forwarded and open localhost:3000"