#!/usr/bin/env bash

cd "$(dirname "$0")"

gh_latest() {
  gh release list -R "$1" --exclude-drafts --exclude-pre-releases --json=isLatest,tagName | jq -r 'map(select(.isLatest))|first.tagName'
}

./update-arg.py \
  CRANE_VERSION="$(gh_latest google/go-containerregistry)" \
  GO_VERSION="$(curl -fsSL https://go.dev/VERSION?m=text | head -n1 | sed 's/^go//g')" \
  GOLANGCI_LINT_VERSION="$(gh_latest golangci/golangci-lint)" \
  HELM_VERSION="$(gh_latest helm/helm | sed 's/^v//g')" \
  KUBECTL_VERSION="$(gh_latest kubernetes/kubernetes | sed 's/^v//g' )" \
  YQ_VERSION="$(gh_latest mikefarah/yq | sed 's/^v//g')" \
  KUSTOMIZE_VERSION="$(gh_latest kubernetes-sigs/kustomize | sed 's/kustomize\///g')" \
  GITHUB_CLI_VERSION="$(gh_latest cli/cli | sed 's/^v//g')" \
  DEBIAN_VERSION="$(crane ls debian | grep -E '^[0-9]+\.[0-9]+$' | grep -Ev '\.0$' | sort -V | tail -n1)" \
  --write
