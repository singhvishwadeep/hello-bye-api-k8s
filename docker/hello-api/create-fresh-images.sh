#!/bin/bash
VERSION="1.0"
echo "Stopping hello-api..."
docker stop hello-api 2>/dev/null || true

echo "Removing hello-api container..."
docker rm hello-api 2>/dev/null || true

echo "Building fresh image..."
docker build --no-cache -t hello-api:$VERSION .

echo "Creating new user-api container..."
docker run -d --name hello-api --network hello-network -p 5000:5000 hello-api:$VERSION

echo "Done."
docker ps --filter name=hello-api
