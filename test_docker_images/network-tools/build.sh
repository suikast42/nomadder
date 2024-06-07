#!/bin/bash
set -e
docker  build  .  -t suikast42/nettools:latest
docker push suikast42/nettools:latest