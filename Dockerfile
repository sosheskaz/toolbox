ARG CRANE_VERSION=v0.20.6
ARG GO_VERSION=1.25.3
ARG GOLANGCI_LINT_VERSION=v2.5.0
ARG HADOLINT_VERSION=v2.14.0
ARG HELM_VERSION=3.19.0
ARG KUBECTL_VERSION=1.34.1
ARG SHELLCHECK_VERSION=v0.11.0
ARG YQ_VERSION=4.48.1
ARG DEBIAN_VERSION=13.1

FROM hadolint/hadolint:${HADOLINT_VERSION} AS hadolint
FROM mikefarah/yq:${YQ_VERSION} AS yq
FROM koalaman/shellcheck:${SHELLCHECK_VERSION} AS shellcheck
FROM golang:${GO_VERSION} AS golang
FROM golangci/golangci-lint:${GOLANGCI_LINT_VERSION} AS golangci-lint

FROM --platform=$BUILDPLATFORM alpine:3.20 AS downloader

RUN apk --no-cache add \
    curl \
    pigz \
    tar \
  && ln -s /usr/bin/pigz gzip \
  && ln -s /usr/bin/pigz gunzip \
  && ln -s /usr/bin/pigz gzcat \
  && ln -s /usr/bin/pigz zcat

FROM --platform=$BUILDPLATFORM downloader AS kustomize
ARG KUSTOMIZE_VERSION=v5.7.1
ARG TARGETOS
ARG TARGETARCH
RUN curl -fsSL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz -o kustomize.tar.gz \
  && tar -xzf kustomize.tar.gz \
  && mv kustomize /kustomize \
  && rm kustomize.tar.gz

FROM --platform=$BUILDPLATFORM downloader AS crane
ARG CRANE_VERSION=v0.20.6
ARG TARGETOS
ARG TARGETARCH
RUN (if [[ "${TARGETARCH}" = "amd64" ]]; then curl -fsSL https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_${TARGETOS}_x86_64.tar.gz -o crane.tar.gz; \
  else curl -fsSL https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_${TARGETOS}_${TARGETARCH}.tar.gz -o crane.tar.gz; fi) \
  && tar -xzf crane.tar.gz \
  && mv crane /crane \
  && rm crane.tar.gz

FROM --platform=$BUILDPLATFORM downloader AS helm
ARG HELM_VERSION=3.19.0
ARG TARGETOS
ARG TARGETARCH
RUN curl -fsSL https://get.helm.sh/helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz -o helm.tar.gz \
  && tar -xzf helm.tar.gz \
  && mv ${TARGETOS}-${TARGETARCH}/helm /helm \
  && rm -rf ${TARGETOS}-${TARGETARCH} helm.tar.gz

FROM --platform=$BUILDPLATFORM downloader AS kubectl
ARG KUBECTL_VERSION=1.34.1
ARG TARGETOS
ARG TARGETARCH
RUN curl -fsSL --compressed https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/${TARGETOS}/${TARGETARCH}/kubectl -o /kubectl \
  && chmod +x /kubectl

FROM --platform=$BUILDPLATFORM downloader AS kube-linter
ARG KUBE_LINTER_VERSION=0.7.6
ARG TARGETOS
ARG TARGETARCH
RUN suffix=${TARGETOS}_${TARGETARCH}; if [[ "${TARGETARCH}" == "amd64" ]]; then suffix="${TARGETOS}"; fi; \
  curl -fsSL https://github.com/stackrox/kube-linter/releases/download/v${KUBE_LINTER_VERSION}/kube-linter-${suffix}.tar.gz -o kube-linter.tar.gz \
  && tar -C /usr/bin -xvzf kube-linter.tar.gz \
  && rm kube-linter.tar.gz

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

FROM --platform=$BUILDPLATFORM downloader AS gh
ARG GITHUB_CLI_VERSION=2.81.0
ARG TARGETOS
ARG TARGETARCH
RUN curl -fsSL https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz -o gh.tar.gz \
  && tar -xzf gh.tar.gz \
  && mv gh_${GITHUB_CLI_VERSION}_${TARGETOS}_${TARGETARCH}/bin/gh /usr/bin/gh \
  && rm -rf gh.tar.gz gh_${GITHUB_CLI_VERSION}_${TARGETOS}_${TARGETARCH}

FROM debian:${DEBIAN_VERSION} AS lite

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    curl \
    ca-certificates \
    coreutils \
    dnsutils \
    findutils \
    htop \
    inetutils-ping \
    jq \
    wget \
    xxd \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=yq /usr/bin/yq /usr/bin/yq
COPY --from=crane /crane /usr/bin/crane

FROM lite AS lint

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-virtualenv \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ARG UV_VERSION=0.7.8
RUN virtualenv /opt/uv \
  && /opt/uv/bin/pip install uv==${UV_VERSION} \
  && ln -s /opt/uv/bin/uv /usr/bin/

ARG ANSIBLE_LINT_VERSION=25.9.2
ARG RUFF_VERSION=0.14.0
ARG YAMLLINT_VERSION=1.37.1
RUN uv tool install ansible-lint==${ANSIBLE_LINT_VERSION} \
  && uv tool install ruff==${RUFF_VERSION} \
  && uv tool install yamllint==${YAMLLINT_VERSION}

COPY --from=kube-linter /usr/bin/kube-linter /usr/bin/kube-linter
COPY --from=golang /usr/local/go/bin/ /opt/go/bin/
ENV GOROOT=/opt/go
RUN ln -s /opt/go/bin/* /usr/bin
COPY --from=golangci-lint /usr/bin/golangci-lint /usr/bin/golangci-lint
COPY --from=shellcheck /bin/shellcheck /usr/bin/shellcheck
COPY --from=hadolint /bin/hadolint /usr/bin/hadolint
COPY --from=kube-linter /usr/bin/kube-linter /usr/bin/kube-linter

FROM lite AS standard

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    curl \
    git \
    ncat \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=helm /helm /usr/bin/helm
COPY --from=kubectl /kubectl /usr/bin/kubectl
COPY --from=kustomize /kustomize /usr/bin/kustomize

FROM standard AS heavy
COPY --from=kcl /usr/bin/kcl /usr/bin/kcl
COPY --from=gh /usr/bin/gh /usr/bin/gh

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    nmap \
    python3 \
    python3-pip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

FROM standard AS default
