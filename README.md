![Docker](https://github.com/jpwhite3/polyglot-ai-agents/workflows/Docker/badge.svg)

# Polyglot AI Agents Workspace

This repository contains Dockerfiles and build utilities to package advanced AI Coding Agents on top of the robust, developer-centric **Polyglot** base image. It enables running fully-functional autonomous AI agents with access to a rich set of developer tools, CLI runtimes, compilers, and hardware integrations.

Two agents are supported:
1. **Hermes Agent**: The agentic terminal/coding assistant by Nous Research (built on `NousResearch/hermes-agent`).
2. **OpenClaw**: A TypeScript-based autonomous personal AI assistant (built on `openclaw/openclaw`).

Additionally, this workspace installs:
* **Whisper.cpp**: Compiled from source for high-performance CPU-based local audio transcription.
* **FFmpeg**: Integrated for voice recording, processing, and formatting.

---

## Architecture & Base Image Integration

Both agents are built on top of the **`jpwhite3/polyglot:latest`** base image.

### Developer Tools Access

To enforce security best practices, the containers run as non-root users:
* **Hermes Agent** runs as `hermes` (UID `10000`).
* **OpenClaw** runs as `node` (UID `1000`).

In the original `polyglot` image, development environments (NVM, Rust/Cargo, Pipx, Claude CLI, etc.) are installed in the `/root` home directory. To make these tools accessible to the non-root agent users, both Dockerfiles:
1. Relax directory traversal permissions inside `/root` (`chmod 755`).
2. Retain intermediate folders (`.cargo`, `.nvm`, `.local`, `.opencode`, `.oh-my-zsh`) under `/root` with executable rights so that the agent users can locate and execute the development binaries.
3. Inherit the `PATH` configurations pointing to `/root/.cargo/bin`, `/root/.nvm/current/bin`, `/root/.local/bin`, and `/root/.opencode/bin`.

---

## Included Tools Reference

By layering on `jpwhite3/polyglot:latest`, both agent containers have access to:
* **Languages**: Python (venv, Poetry, Pipenv, Pipx), Java (openjdk-headless), .NET SDK, Ruby (rbenv, gem), Go, Node (nvm, npm), Rust (rustup, rustc).
* **CLI AI Tools**: Claude CLI, OpenCode CLI, Antigravity CLI.
* **Media & Audio Transcription**: Whisper.cpp (`whisper-cli`, `whisper-server`), FFmpeg (`ffmpeg`).
* **General CLI Tools**: `git`, `zsh` (Oh My Zsh integration), `curl`, `jq`, `less`, `make`, `ripgrep`, `lsof`, `procps`.

---

## Getting Started

### Prerequisites

Ensure the base `polyglot` image (`jpwhite3/polyglot:latest`) is built locally or pulled from the registry:
```bash
# To build the base image from source:
cd ../polyglot
make build
```
Verify `jpwhite3/polyglot:latest` is present in the local image cache:
```bash
docker images | grep jpwhite3/polyglot
```

### Build Instructions

The agent images can be built using the provided `Makefile`:

```bash
# Build the Hermes Agent container image (tagged polyglot-hermes:latest)
make build-hermes

# Build the OpenClaw container image (tagged polyglot-openclaw:latest)
make build-openclaw

# Build both images
make build-all
```

### Run Instructions

#### Running Hermes Agent

Start the Hermes Agent in an interactive terminal shell:
```bash
make run-hermes
```
This runs the container, mounts a persistent volume called `polyglot-hermes-data` to `/opt/data`, maps ports, and drops into the agent entrypoint.

#### Running OpenClaw Gateway

Start the OpenClaw Gateway server:
```bash
make run-openclaw
```
This launches the gateway, maps port `18789` for the web UI, and mounts a persistent volume `polyglot-openclaw-data` to `/home/node/.openclaw`. Access the control dashboard at:
[http://localhost:18789](http://localhost:18789)

---

## Verification & Testing

Verify that the binaries are properly compiled, installed, and accessible to the non-root container users:

### 1. Audio Transcription & Media verification
Check that `whisper-cli` and `ffmpeg` are available:
```bash
docker run --rm polyglot-hermes:latest whisper-cli --help
docker run --rm polyglot-openclaw:latest whisper-cli --help
docker run --rm polyglot-hermes:latest ffmpeg -version
```

### 2. Base Developer Tools verification
Ensure language runtimes are executable:
```bash
# Check Python
docker run --rm polyglot-hermes:latest python3 --version

# Check Node
docker run --rm polyglot-hermes:latest node --version

# Check Go
docker run --rm polyglot-hermes:latest go version

# Check Rust
docker run --rm polyglot-hermes:latest rustc --version

# Check Claude CLI
docker run --rm polyglot-hermes:latest command -v claude
```

---

## GitHub Actions CI/CD Pipeline

This repository includes a pre-configured GitHub Actions workflow located in `.github/workflows/docker-publish.yml` that automates testing and publishing the agent images to **GitHub Container Registry (GHCR)**.

### How it works
1. **Pull Requests / `develop` branch**: Triggers the `test` job which builds both images (using Docker Buildx and GHA registry cache) with `push: false` to ensure changes compile successfully without publishing.
2. **Main Branch / Version Tags (`v*`)**: Triggers the `publish` job which builds both images, authenticates with GHCR, computes the tag names, and pushes the images to `ghcr.io/jpwhite3/polyglot-hermes` and `ghcr.io/jpwhite3/polyglot-openclaw`.
3. **Weekly Rebuilds**: Runs automatically every Monday at 6:00 AM UTC to rebuild the agent images, ensuring they inherit the latest updates from the upstream `polyglot` image.

### Building in GitHub Actions (Parameterization)
Since the `jpwhite3/polyglot:latest` base image exists locally during development but is published as `ghcr.io/jpwhite3/polyglot:latest` in GitHub Container Registry, the Dockerfiles parameterize the base image with a build argument:

```dockerfile
ARG BASE_IMAGE=jpwhite3/polyglot:latest
FROM ${BASE_IMAGE} AS final
```

During local builds, this defaults to the local `jpwhite3/polyglot:latest` image. During the GitHub Actions pipeline runs, the workflow passes:
`--build-arg BASE_IMAGE=ghcr.io/${{ github.repository_owner }}/polyglot:latest`
to resolve the correct base image in the cloud.

### Repository Secrets
To push images successfully, make sure the following secret is configured in the GitHub repository:
- `CR_PAT`: A GitHub Personal Access Token (PAT) with `write:packages` and `read:packages` permissions.

---

## License

This project is open-source and available under the terms of the [MIT License](LICENSE).
