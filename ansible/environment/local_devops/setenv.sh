#!/bin/bash

export TLS_SAN=tdp.private
export ENVIRONMENT="$PWD/../environment/local_devops"
export ANSIBLE_CONFIG="$ENVIRONMENT/../ansible.cfg"
export ANSIBLE_INVENTORY="$ENVIRONMENT/inventory/hosts.ini"
export ANSIBLE_DEBUG=False
export PULL_REGISTRY="registry.$TLS_SAN"
export PUSH_REGISTRY="$DOCKER_HOST:5001"
