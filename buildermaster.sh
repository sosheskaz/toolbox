#!/usr/bin/env bash

set -euo pipefail

export DOCKER_BUILDKIT=1

PLATFORMS=("linux/amd64" "linux/arm64")
REPOS=("ericmiller/toolbox" "ghcr.io/sosheskaz/toolbox")
TARGETS=(lite lint standard heavy)

# Layer cache lives beside the images on GHCR, one ref per target. The package is
# public, so PR builds import it without credentials; only the push path has the
# credentials to export.
CACHE_REPO="${CACHE_REPO:-ghcr.io/sosheskaz/toolbox}"

PLATFORMS_CSV="$(IFS=,; echo "${PLATFORMS[*]}")"

BUILDARGS=()
if [[ "${PUSH:-false}" = "true" ]]
then BUILDARGS+=("--push")
fi
if [[ "${NOCACHE:-false}" = "true" ]]
then BUILDARGS+=("--no-cache")
fi
if [[ "${PULL:-true}" = "true" ]]
then BUILDARGS+=("--pull")
fi

for TARGET in "${TARGETS[@]}"
do
  TAGARGS=()
  for REPO in "${REPOS[@]}"
  do
    TAGARGS+=("--tag=${REPO}:${TARGET}")
    if [[ "${TARGET}" == "standard" ]]
    then
      TAGARGS+=("--tag=${REPO}:latest")
    fi
  done

  CACHEARGS=()
  if [[ "${NOCACHE:-false}" != "true" ]]
  then
    # Importing a ref that does not exist yet logs an error and continues, so the
    # first build of a new target needs no special-casing.
    CACHEARGS+=("--cache-from=type=registry,ref=${CACHE_REPO}:buildcache-${TARGET}")
    if [[ "${PUSH:-false}" = "true" ]]
    then CACHEARGS+=("--cache-to=type=registry,ref=${CACHE_REPO}:buildcache-${TARGET},mode=max")
    fi
  fi

  docker buildx build \
    --platform="${PLATFORMS_CSV}" \
    "${TAGARGS[@]}" \
    --target="${TARGET}" \
    "${BUILDARGS[@]}" \
    "${CACHEARGS[@]}" \
    .
done
