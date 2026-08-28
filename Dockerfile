# Consumed by FROM. Renovate's dockerfile manager expands these natively, so they
# must NOT carry a `# renovate:` annotation — that would register each twice.
ARG ALPINE_VERSION=3.24
ARG DEBIAN_VERSION=13.6
ARG GO_VERSION=1.26.6
ARG GOLANGCI_LINT_VERSION=v2.12.2
ARG HADOLINT_VERSION=v2.15.1
ARG SHELLCHECK_VERSION=v0.11.0
ARG YQ_VERSION=4.53.6

# Consumed by download URLs. Tracked by the custom regex manager in renovate.json.
# extractVersion reconciles the upstream tag shape with the value each URL needs.
# renovate: datasource=github-releases depName=google/go-containerregistry
ARG CRANE_VERSION=v0.21.9
# renovate: datasource=github-releases depName=cli/cli extractVersion=^v(?<version>.+)$
ARG GITHUB_CLI_VERSION=2.97.0
# renovate: datasource=github-releases depName=helm/helm extractVersion=^v(?<version>.+)$
ARG HELM_VERSION=4.2.4
# renovate: datasource=github-releases depName=kubernetes/kubernetes extractVersion=^v(?<version>.+)$
ARG KUBECTL_VERSION=1.36.4
# renovate: datasource=github-releases depName=stackrox/kube-linter extractVersion=^v(?<version>.+)$
ARG KUBE_LINTER_VERSION=0.8.3
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize extractVersion=^kustomize/(?<version>v.+)$
ARG KUSTOMIZE_VERSION=v5.8.1
# renovate: datasource=github-releases depName=anthropics/claude-code extractVersion=^v(?<version>.+)$
ARG CLAUDE_CODE_VERSION=2.1.251
# renovate: datasource=github-releases depName=openai/codex extractVersion=^rust-v(?<version>.+)$
ARG CODEX_VERSION=0.147.0
# renovate: datasource=github-releases depName=jdx/mise extractVersion=^v(?<version>.+)$
ARG MISE_VERSION=2026.8.10
# renovate: datasource=pypi depName=ansible-lint
ARG ANSIBLE_LINT_VERSION=26.6.0
# renovate: datasource=pypi depName=ruff
ARG RUFF_VERSION=0.16.4
# renovate: datasource=pypi depName=uv
ARG UV_VERSION=0.12.5
# renovate: datasource=pypi depName=yamllint
ARG YAMLLINT_VERSION=1.38.0

FROM hadolint/hadolint:${HADOLINT_VERSION} AS hadolint
FROM mikefarah/yq:${YQ_VERSION} AS yq
FROM koalaman/shellcheck:${SHELLCHECK_VERSION} AS shellcheck
FROM golang:${GO_VERSION} AS golang
FROM golangci/golangci-lint:${GOLANGCI_LINT_VERSION} AS golangci-lint

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS downloader

RUN apk --no-cache add \
    curl \
    pigz \
    tar \
  && ln -s /usr/bin/pigz gzip \
  && ln -s /usr/bin/pigz gunzip \
  && ln -s /usr/bin/pigz gzcat \
  && ln -s /usr/bin/pigz zcat

FROM --platform=$BUILDPLATFORM downloader AS kustomize
ARG KUSTOMIZE_VERSION
ARG TARGETOS
ARG TARGETARCH
RUN --mount=type=tmpfs,target=/tmp \
  curl -fsSL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz -o /tmp/kustomize.tar.gz \
  && tar -xzf /tmp/kustomize.tar.gz \
  && mv kustomize /kustomize

FROM --platform=$BUILDPLATFORM downloader AS crane
ARG CRANE_VERSION
ARG TARGETOS
ARG TARGETARCH
RUN --mount=type=tmpfs,target=/tmp \
  (if [ "${TARGETARCH}" = "amd64" ]; then curl -fsSL https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_${TARGETOS}_x86_64.tar.gz -o /tmp/crane.tar.gz; \
  else curl -fsSL https://github.com/google/go-containerregistry/releases/download/${CRANE_VERSION}/go-containerregistry_${TARGETOS}_${TARGETARCH}.tar.gz -o /tmp/crane.tar.gz; fi) \
  && tar -C /tmp -xzf /tmp/crane.tar.gz \
  && mv /tmp/crane /crane

FROM --platform=$BUILDPLATFORM downloader AS helm
ARG HELM_VERSION
ARG TARGETOS
ARG TARGETARCH
RUN --mount=type=tmpfs,target=/tmp \
  curl -fsSL https://get.helm.sh/helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz -o /tmp/helm.tar.gz \
  && tar -C /tmp -xzf /tmp/helm.tar.gz \
  && mv /tmp/${TARGETOS}-${TARGETARCH}/helm /helm

FROM --platform=$BUILDPLATFORM downloader AS kubectl
ARG KUBECTL_VERSION
ARG TARGETOS
ARG TARGETARCH
RUN curl -fsSL --compressed https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/${TARGETOS}/${TARGETARCH}/kubectl -o /kubectl \
  && chmod +x /kubectl

FROM --platform=$BUILDPLATFORM downloader AS kube-linter
ARG KUBE_LINTER_VERSION
ARG TARGETOS
ARG TARGETARCH
RUN --mount=type=tmpfs,target=/tmp \
  suffix=${TARGETOS}_${TARGETARCH}; if [ "${TARGETARCH}" = "amd64" ]; then suffix="${TARGETOS}"; fi; \
  curl -fsSL https://github.com/stackrox/kube-linter/releases/download/v${KUBE_LINTER_VERSION}/kube-linter-${suffix}.tar.gz -o /tmp/kube-linter.tar.gz \
  && tar -C /usr/bin -xzf /tmp/kube-linter.tar.gz

FROM --platform=$BUILDPLATFORM downloader AS gh
ARG GITHUB_CLI_VERSION
ARG TARGETOS
ARG TARGETARCH
RUN --mount=type=tmpfs,target=/tmp \
  curl -fsSL https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz -o /tmp/gh.tar.gz \
  && tar -C /tmp -xzf /tmp/gh.tar.gz \
  && mv /tmp/gh_${GITHUB_CLI_VERSION}_${TARGETOS}_${TARGETARCH}/bin/gh /usr/bin/gh

FROM --platform=$BUILDPLATFORM downloader AS mise
ARG MISE_VERSION
ARG TARGETARCH
RUN --mount=type=tmpfs,target=/tmp \
  arch=${TARGETARCH}; if [ "${TARGETARCH}" = "amd64" ]; then arch=x64; fi; \
  curl -fsSL https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-${arch}.tar.gz -o /tmp/mise.tar.gz \
  && tar -C /tmp -xzf /tmp/mise.tar.gz \
  && mv /tmp/mise/bin/mise /mise

FROM debian:${DEBIAN_VERSION} AS lite

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  apt-get update \
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
    xxd

COPY --from=yq /usr/bin/yq /usr/bin/yq
COPY --from=crane /crane /usr/bin/crane

FROM lite AS lint

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  apt-get update \
  && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-virtualenv

ARG UV_VERSION
RUN virtualenv /opt/uv \
  && /opt/uv/bin/pip install uv==${UV_VERSION} \
  && ln -s /opt/uv/bin/uv /usr/bin/

ARG ANSIBLE_LINT_VERSION
ARG RUFF_VERSION
ARG YAMLLINT_VERSION
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

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  apt-get update \
  && apt-get install -y --no-install-recommends \
    curl \
    git \
    less \
    ncat \
    ripgrep \
    rsync

COPY --from=helm /helm /usr/bin/helm
COPY --from=kubectl /kubectl /usr/bin/kubectl
COPY --from=kustomize /kustomize /usr/bin/kustomize
# mise resolves each repo's own pinned toolchain from its config, so the image
# ships the launcher rather than a guess at which tools a repo wants.
COPY --from=mise /mise /usr/bin/mise

FROM standard AS heavy
COPY --from=gh /usr/bin/gh /usr/bin/gh

# mise data and config live outside $HOME so anything installed through it
# resolves for whichever user the image runs as, not just root.
ENV MISE_DATA_DIR=/opt/mise \
    MISE_CONFIG_DIR=/opt/mise \
    PATH=/opt/mise/shims:${PATH}

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  apt-get update \
  && apt-get install -y --no-install-recommends \
    nmap \
    openssh-client \
    python3 \
    python3-pip

# Both agents ship a native binary, so mise installs them directly with no Node
# runtime involved.
FROM heavy AS claude
ARG CLAUDE_CODE_VERSION

RUN mise use -g -y claude@${CLAUDE_CODE_VERSION} \
  && claude --version

FROM heavy AS codex
ARG CODEX_VERSION

# codex ships helper binaries beside the entrypoint, so it is installed through
# shims rather than symlinking one path out of the install directory.
RUN mise use -g -y codex@${CODEX_VERSION} \
  && codex --version

FROM standard AS default
