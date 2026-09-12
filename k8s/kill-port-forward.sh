#pkill all
#pkill -f "kubectl port-forward" 2>/dev/null || true
pkill -f "kubectl port-forward svc/hello-service"
pkill -f "kubectl port-forward svc/bye-service"
