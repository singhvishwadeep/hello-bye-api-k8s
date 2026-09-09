VERSION="1.0"
#create image
docker build -t hello-api:$VERSION .
# create container
docker network create hello-network
docker run -d --name hello-api --network hello-network -p 5000:5000 hello-api:$VERSION
# docker login
docker login
# tagging the image
docker tag hello-api:$VERSION vsdpsingh/hello-api:$VERSION
# pushing the image
docker push vsdpsingh/hello-api:$VERSION
# check here - https://hub.docker.com/repositories/vsdpsingh