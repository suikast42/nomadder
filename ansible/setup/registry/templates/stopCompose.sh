#!/bin/bash -e
echo Bring compose down
docker compose   -f {{nexus_compose_dir}}/docker-compose.yml  down -v --remove-orphans
