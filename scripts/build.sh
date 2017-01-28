#!/bin/bash

docker build \
  -t arhea/cassandra:2.1 \
  -f ../containers/2.1/Dockerfile \
  ../

docker build \
  -t arhea/cassandra:3.0 \
  -f ../containers/3.0/Dockerfile \
  ../

docker build \
  -t arhea/cassandra:3.9 \
  -f ../containers/3.9/Dockerfile \
  ../

docker build \
  -t arhea/cassandra:latest \
  -f ../containers/latest/Dockerfile \
  ../

docker push arhea/cassandra:2.1
docker push arhea/cassandra:3.0
docker push arhea/cassandra:3.9
docker push arhea/cassandra:latest
