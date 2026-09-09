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

echo "Creating new hello-api container..."
docker run -d --name hello-api --network hello-network -p 5000:5000 hello-api:$VERSION

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

echo "Creating new bye-api container..."
docker run -d --name bye-api --network hello-network -p 6000:6000 bye-api:$VERSION

echo "Done."
docker ps --filter name=bye-api
cd ..
