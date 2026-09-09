VERSION="1.0"
#create image
docker build -t bye-api:$VERSION .
# create container
docker network create hello-network
docker run -d --name bye-api --network hello-network -p 6000:6000 bye-api:$VERSION
# docker login
docker login
# tagging the image
docker tag bye-api:$VERSION vsdpsingh/bye-api:$VERSION
# pushing the image
docker push vsdpsingh/bye-api:$VERSION
# check here - https://hub.docker.com/repositories/vsdpsingh