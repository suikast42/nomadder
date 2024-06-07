#!/bin/bash
set -e
docker  build  .  -t suikast42/cpuload:latest
docker push suikast42/cpuload:latest