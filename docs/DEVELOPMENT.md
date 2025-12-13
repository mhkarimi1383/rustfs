# RustFS Local Development Guide

This guide explains how to set up and run a local development environment for RustFS. You have two options:

1. **Nix development shell** - Recommended for native development
2. **Docker Compose** - For containerized development

## Option 1: Nix Development Shell (Recommended)

The project includes a Nix Flake that provides a reproducible development environment with all required dependencies.

### Prerequisites

- [Nix](https://nixos.org/download.html) with Flakes support enabled
- [direnv](https://direnv.net/) (optional, but recommended for automatic environment loading)

### Setup

#### With direnv (automatic):
```bash
direnv allow
```

This automatically loads the development environment when you enter the directory.

#### Without direnv (manual):
```bash
nix develop
```

### Available Shells

```bash
# Full development shell with all tools (recommended)
nix develop

# Minimal shell with only essential Rust tools
nix develop .#minimal

# Documentation and script tools only
nix develop .#docs
```

### Development Workflow with Nix

Once inside the development shell, all standard development commands are available:

```bash
make fmt              # Format code
make fmt-check        # Check formatting
make clippy           # Run clippy checks
make check            # Verify compilation
make test             # Run tests
make pre-commit       # Run all checks

./build-rustfs.sh     # Build RustFS
./build-rustfs.sh --dev  # Development build
```

The Nix shell automatically:
- Configures rustfmt to use the 130-column max width from `rustfmt.toml`
- Sets up proper environment variables for KMS e2e tests
- Provides all build dependencies (protobuf, flatbuffers, openssl, etc.)
- Includes development tools (rust-analyzer, cargo-nextest, etc.)

## Option 2: Docker Development Environment

Alternatively, you can use Docker Compose for a containerized development environment.

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Quick Start (Docker)

The Docker development environment is configured as a Docker Compose profile named `dev`.

### 1. Setup Console UI (Optional)

If you want to use the Console UI, you must download the static assets first. The default source checkout does not include them.

```bash
bash scripts/static.sh
```

### 2. Start the Environment

To start the development container:

```bash
docker compose --profile dev up -d rustfs-dev
```

**Note**: The first run will take some time (5-10 minutes) because it builds the docker image and compiles all Rust dependencies from source. Subsequent runs will be much faster.

### 3. View Logs

To follow the application logs:

```bash
docker compose --profile dev logs -f rustfs-dev
```

### 4. Access the Services

- **S3 API**: `http://localhost:9010`
- **Console UI**: `http://localhost:9011/rustfs/console/index.html`

## Docker Workflow

### Making Changes
The source code from your local `rustfs` directory is mounted into the container at `/app`. You can edit files in your preferred IDE on your host machine.

### Applying Changes
Since the application runs via `cargo run`, you need to restart the container to pick up changes. Thanks to incremental compilation, this is fast.

```bash
docker compose --profile dev restart rustfs-dev
```

### Rebuilding Dependencies
If you modify `Cargo.toml` or `Cargo.lock`, you generally need to rebuild the Docker image to update the cached dependencies layer:

```bash
docker compose --profile dev build rustfs-dev
```

## Troubleshooting

### Docker-specific Issues

#### `VolumeNotFound` Error
If you see an error like `Error: Custom { kind: Other, error: VolumeNotFound }`, it means the `rustfs` binary was started without valid volume arguments.
The development image uses `entrypoint.sh` to parse the `RUSTFS_VOLUMES` environment variable (supporting `{N..M}` syntax), create the directories, and pass them to `cargo run`. Ensure your `RUSTFS_VOLUMES` variable is correctly formatted.

#### Slow Initial Build
This is expected. The `dev` stage in `Dockerfile.source` compiles all dependencies from scratch. Because the `/usr/local/cargo/registry` is mounted as a volume, these compiled artifacts are preserved between restarts, making future builds fast.

### Nix-specific Issues

#### Flake not found
If you encounter flake errors, ensure you have Nix with Flakes support:
```bash
nix flake --version
```

#### direnv not auto-loading
Make sure direnv is installed and the hook is added to your shell:
```bash
eval "$(direnv hook bash)"  # for bash
# or for zsh:
eval "$(direnv hook zsh)"
```

Then run `direnv allow` in the project directory.

#### Slow first environment load
The first time you load the Nix shell, it may take time to download and build dependencies. Subsequent loads are much faster due to caching.
