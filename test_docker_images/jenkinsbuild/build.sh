#!/bin/bash
export APP_NAME=jenkins
export APP_VERSION_ORIG=2.436-jdk17
export APP_VERSION_BUILD=${APP_VERSION_ORIG}_1
export PULL_IMAGE=jenkins/jenkins:${APP_VERSION_ORIG}
export PUSH_IMAGE=jenkins/jenkins:${APP_VERSION_BUILD}

  if [ -z "$PULL_REGISTRY"  ]; then
      echo "PULL_REGISTRY is not specified"
      exit 1
  fi

  if [ -z "$PUSH_REGISTRY"  ]; then
      echo "PUSH_REGISTRY is not specified"
      exit 1
  fi

  echo "Build version $APP_VERSION_BUILD of $APP_NAME and push to $PUSH_REGISTRY"
  docker  build --build-arg PULL_REGISTRY=$PULL_REGISTRY --build-arg IMAGE=$PULL_IMAGE -t  $PUSH_REGISTRY/$PUSH_IMAGE .
  echo docker push $PUSH_REGISTRY/$PUSH_IMAGE
  docker push $PUSH_REGISTRY/$PUSH_IMAGE

