#!/bin/bash

VERSION="1.0"

echo "Stopping bye-api..."
docker stop bye-api 2>/dev/null || true

echo "Removing bye-api container..."
docker rm bye-api 2>/dev/null || true

echo "Building fresh image..."
docker build --no-cache -t bye-api:$VERSION .

echo "Creating new user-api container..."
docker run -d --name bye-api --network hello-network -p 6000:6000 bye-api:$VERSION

echo "Done."
docker ps --filter name=bye-api
