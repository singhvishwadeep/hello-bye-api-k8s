# hello-bye-api-k8s
hello bye api for k8s

# FOR DOCKER

# Execute (change VERSION as per release)
./create-container-push-images.sh
./test-api.sh
./remove-all.sh

# Repositories
https://hub.docker.com/repositories/vsdpsingh


# FOR K8S

# Clean ALL
./delete-all.sh

# Fresh installation
./fresh-install.sh

# install loki, alloy and grafana for localhost:3000
./install-logging.sh

# install rancher
./install-rancher.sh

# install argocd
./install-argocd.sh
