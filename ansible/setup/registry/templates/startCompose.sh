#!/bin/bash -e
echo Bring compose up
docker compose   -f {{nexus_compose_dir}}/docker-compose.yml up -d  --build --force-recreate --remove-orphans
