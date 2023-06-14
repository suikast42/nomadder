#!/bin/bash
export PULL_IMAGE=jenkins/jenkins:2.401.1-lts-jdk17
export PUSH_IMAGE=jenkins/jenkins:2.401.1-lts-jdk17_1

  if [ -z "$PULL_REGISTRY"  ]; then
      echo "PULL_REGISTRY is not specified"
      exit 1
  fi

  if [ -z "$PUSH_REGISTRY"  ]; then
      echo "PUSH_REGISTRY is not specified"
      exit 1
  fi

  echo "Build version $APP_VERSION of $APP_NAME and push to $PUSH_REGISTRY"
  docker  build --build-arg PULL_REGISTRY=$PULL_REGISTRY --build-arg IMAGE=$PULL_IMAGE -t  $PUSH_REGISTRY/$PUSH_IMAGE .
  echo docker push $PUSH_REGISTRY/$PUSH_IMAGE
  docker push $PUSH_REGISTRY/$PUSH_IMAGE

