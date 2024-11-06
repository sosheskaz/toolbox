#!/usr/bin/env bash

set -euo pipefail

export DOCKER_BUILDKIT=1

PLATFORMS=("linux/amd64" "linux/arm64")
REPOS=("ericmiller/toolbox" "ghcr.io/sosheskaz/toolbox")
TARGETS=(lite standard heavy)

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


  docker buildx build \
    --platform="${PLATFORMS_CSV}" \
    "${TAGARGS[@]}" \
    --target="${TARGET}" \
    "${BUILDARGS[@]}" \
    .
done
