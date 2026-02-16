# Toolbox

A group of heavy-duty containers that track latest versions, and contain a variety of tools. These
are built on a Debian base, for the purpose of broad compatibility and stability. These images tend
to be more "kitchen sink" than is generally best practice, but are largely there for development
usage or break-fix. These can be nice for `kubectl exec` or `docker run` debugging, because they
come batteries-included—not just the utilities you will need, but also utilities you _might_ need,
avoiding the need to install so much at runtime. These generally are not good production images.

## Image Targets

### lite

A basic shell and common utilities, striving to be broadly useful but also small.

| Tool | Description |
|------|-------------|
| bash | Shell |
| curl | HTTP client |
| wget | HTTP client |
| jq | JSON processor |
| yq | YAML/JSON/XML processor |
| crane | Container registry tool |
| dnsutils | DNS utilities (dig, nslookup, etc.) |
| coreutils | GNU core utilities |
| findutils | GNU find/xargs |
| htop | Process viewer |
| ping | ICMP ping (inetutils) |
| xxd | Hex dump utility |

### lint

Lite, plus linters and language toolchains. This is a pretty big image.

Includes everything in **lite**, plus:

| Tool | Description |
|------|-------------|
| go | Go toolchain |
| golangci-lint | Go linter runner |
| shellcheck | Shell script linter |
| hadolint | Dockerfile linter |
| kube-linter | Kubernetes manifest linter |
| ansible-lint | Ansible playbook linter |
| yamllint | YAML linter |
| ruff | Python linter/formatter |
| python3 | Python runtime |
| uv | Python package manager |

### standard

Lite, plus tools for Kubernetes and general ops work. Tagged as `latest`.

Includes everything in **lite**, plus:

| Tool | Description |
|------|-------------|
| git | Version control |
| ncat | Networking utility (nmap project) |
| kubectl | Kubernetes CLI |
| helm | Kubernetes package manager |
| kustomize | Kubernetes manifest customization |

### heavy

Standard, plus several utilities that are larger or more specialized.

Includes everything in **standard**, plus:

| Tool | Description |
|------|-------------|
| gh | GitHub CLI |
| kcl | KCL configuration language CLI |
| nmap | Network scanner |
| python3 | Python runtime |
