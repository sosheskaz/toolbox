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
| less | Pager, used by `git` |
| mise | Version manager; resolves a repo's own pinned toolchain |
| ncat | Networking utility (nmap project) |
| ripgrep | Fast recursive search (`rg`) |
| kubectl | Kubernetes CLI |
| helm | Kubernetes package manager |
| kustomize | Kubernetes manifest customization |

### heavy

Standard, plus several utilities that are larger or more specialized.

Includes everything in **standard**, plus:

| Tool | Description |
|------|-------------|
| gh | GitHub CLI |
| nmap | Network scanner |
| openssh-client | Git over SSH |
| python3 | Python runtime |

### claude

Heavy, plus the Claude Code CLI.

Includes everything in **heavy**, plus:

| Tool | Description |
|------|-------------|
| claude | Claude Code CLI |

### codex

Heavy, plus the Codex CLI. Identical to **claude** except for the agent itself.

Includes everything in **heavy**, plus:

| Tool | Description |
|------|-------------|
| codex | Codex CLI |

Both agents are installed at build time with `mise` into `/opt/mise` and exposed
on `PATH` directly, so no mise environment variables are set at runtime and
`mise` still behaves normally for whichever user the container runs as. Neither
agent needs a Node.js runtime.

**Codex sandboxing.** Codex sandboxes model-generated shell commands with
`bwrap`, which cannot create a user namespace inside an unprivileged container:

```
bwrap: No permissions to create a new namespace, likely because the kernel does
not allow non-privileged user namespaces.
```

The container is already the isolation boundary, so pass
`--sandbox danger-full-access` (or `--dangerously-bypass-approvals-and-sandbox`,
which is documented for exactly this case) when running `codex exec` here. The
image does not set either by default, so that the weaker posture is an explicit
choice by the caller rather than something the image decides for them.
