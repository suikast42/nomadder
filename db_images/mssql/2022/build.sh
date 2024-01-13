#!/bin/bash

if [ -z "$PUSH_REGISTRY" ] && [ -z "$DOCKER_HUB_ACCOUNT" ]; then
    echo "Error: PUSH_REGISTRY and DOCKER_HUB_ACCOUNT environment variable is not set."
    exit 1
fi

if [ -z "$PUSH_REGISTRY" ]; then
       echo "Build version $BUILD_VERSION push to dockerhub account $DOCKER_HUB_ACCOUNT"
       docker build \
       --build-arg  PULL_REGISTRY=${PULL_REGISTRY} \
       --build-arg  MINIO_CLI_VERSION=${MINIO_CLI_VERSION} \
       --build-arg  MSSQL_VERSION=${MSSQL_VERSION} \
       -t ${DOCKER_HUB_ACCOUNT}/mssql_server:${BUILD_VERSION} \
       .
       docker push  ${DOCKER_HUB_ACCOUNT}/mssql_server:${BUILD_VERSION}
else
       echo "Build version $BUILD_VERSION push to $PUSH_REGISTRY"
       docker build \
       --build-arg  PULL_REGISTRY=${PULL_REGISTRY} \
       --build-arg  MINIO_CLI_VERSION=${MINIO_CLI_VERSION} \
       --build-arg  MSSQL_VERSION=${MSSQL_VERSION} \
       -t ${PUSH_REGISTRY}/mssql/server:${BUILD_VERSION} \
       .
       docker push  ${PUSH_REGISTRY}/mssql/server:${BUILD_VERSION}
fi

