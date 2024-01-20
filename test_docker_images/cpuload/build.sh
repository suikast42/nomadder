#!/bin/bash
set -e
docker  build  .  -t suikast42/cpuload:latest
o docker push suikast42/cpuload:latest