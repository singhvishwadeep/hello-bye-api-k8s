docker rmi -f $(docker images -q)
docker network rm hello-network
