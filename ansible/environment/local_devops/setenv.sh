#!/bin/bash

export DOCKER_HOST=192.168.30.121
export TLS_SAN=tdp.private
export ENVIRONMENT="/mnt/c/IDE/Projects_Git/playground/nomadder/ansible/environment/local_devops"
export ANSIBLE_CONFIG="$ENVIRONMENT/../ansible.cfg"
export ANSIBLE_INVENTORY="$ENVIRONMENT/inventory/hosts.ini"
export ANSIBLE_DEBUG=False
export DOCKER_CERT_PATH="$ENVIRONMENT/docker_client"
export PULL_REGISTRY="registry.$TLS_SAN"
export PUSH_REGISTRY="$DOCKER_HOST:5001"
