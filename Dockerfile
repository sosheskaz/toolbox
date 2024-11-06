ARG CRANE_VERSION=v0.20.2
ARG GO_VERSION=1.23.2
ARG GOLANGCI_LINT_VERSION=v1.61.0
ARG HELM_VERSION=3.16.2
ARG KUBECTL_VERSION=1.31.2
ARG YQ_VERSION=4.44.3

FROM cgr.dev/chainguard/crane:latest AS crane
FROM alpine/helm:3 AS helm
FROM bitnami/kubectl:latest AS kubectl
FROM mikefarah/yq:4 AS yq
FROM golang:1.23 AS golang
FROM golangci/golangci-lint:latest AS golangci-lint

FROM --platform=$BUILDPLATFORM alpine:3.20 AS downloader

RUN apk --no-cache add curl

FROM --platform=$BUILDPLATFORM downloader AS kustomize
ARG KUSTOMIZE_VERSION=v5.5.0
ARG TARGETOS
ARG TARGETARCH
RUN curl -fsSL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz -o kustomize.tar.gz \
  && tar -xzf kustomize.tar.gz \
  && mv kustomize /kustomize \
  && rm kustomize.tar.gz

FROM --platform=$BUILDPLATFORM downloader AS kcl

ARG KCL_VERSION=v0.10.0
ARG TARGETOS
ARG TARGETARCH
RUN mkdir -p /tmp/kcl \
  && cd /tmp/kcl \
  && curl -fsSL https://github.com/kcl-lang/cli/releases/download/${KCL_VERSION}/kcl-${KCL_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz -o kcl.tar.gz \
  && tar -xzf kcl.tar.gz \
  && mv kcl /usr/bin/kcl \
  && cd - \
  && rm -rf /tmp/kcl

FROM debian:bookworm AS lite

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    coreutils \
    dnsutils \
    findutils \
    htop \
    inetutils-ping \
    jq \
    wget \
    xxd \
  && rm -rf /var/lib/apt/lists/*

COPY --from=yq /usr/bin/yq /usr/bin/yq
COPY --from=crane /usr/bin/crane /usr/bin/crane

ENTRYPOINT ["/bin/bash"]

FROM lite AS standard

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    curl \
    git \
    ncat \
  && rm -rf /var/lib/apt/lists/*

COPY --from=helm /usr/bin/helm /usr/bin/helm
COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/bin/kubectl
COPY --from=kustomize /kustomize /usr/bin/kustomize

FROM standard AS heavy
COPY --from=kcl /usr/bin/kcl /usr/bin/kcl

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    gh \
    nmap \
  && rm -rf /var/lib/apt/lists/*

FROM standard AS default
