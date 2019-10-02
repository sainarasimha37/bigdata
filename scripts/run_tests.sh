#!/bin/sh

export PATH="$HOME/bin:$PATH"

cd "$(dirname "$(dirname "$0")")"

set -eux

# Re-build and re-start services
docker-compose build --build-arg version=v0.0 coordinator profiler query test_discoverer
docker-compose up -d coordinator profiler query querylb

# Clear cache
docker exec -ti $(basename "$(pwd)")_coordinator_1 sh -c 'rm -rf /dataset_cache/*'

# Clear index
scripts/docker_purge_source.sh datamart.test

sleep 2

# Re-profile
docker-compose up -d --force-recreate test_discoverer
sleep 10

# Run tests
DATAMART_VERSION=v0.0 pipenv run python tests