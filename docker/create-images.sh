VERSION="1.0"
cd hello-api
echo "Stopping hello-api..."
docker stop hello-api 2>/dev/null || true

echo "Removing hello-api container..."
docker rm hello-api 2>/dev/null || true

echo "Building fresh image..."
docker build --no-cache -t hello-api:$VERSION .
docker tag hello-api:$VERSION vsdpsingh/hello-api:$VERSION

docker push vsdpsingh/hello-api:$VERSION
echo "Done."
docker ps --filter name=hello-api
cd ..
cd bye-api
echo "Stopping bye-api..."
docker stop bye-api 2>/dev/null || true

echo "Removing bye-api container..."
docker rm bye-api 2>/dev/null || true

echo "Building fresh image..."
docker build --no-cache -t bye-api:$VERSION .
docker tag bye-api:$VERSION vsdpsingh/bye-api:$VERSION
docker push vsdpsingh/bye-api:$VERSION

echo "Done."
docker ps --filter name=bye-api
cd ..
