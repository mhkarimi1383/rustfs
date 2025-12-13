{
  description = "RustFS development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # Rust toolchain
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [
            "rust-src"
            "rust-analyzer"
          ];
        };

        # Development dependencies
        devDependencies = with pkgs; [
          # Rust toolchain
          rustToolchain
          cargo-edit
          cargo-outdated
          cargo-audit
          cargo-deny
          cargo-nextest
          cargo-expand
          cargo-watch

          # Build tools
          pkg-config
          protobuf
          flatbuffers

          # Required system libraries for build
          openssl
          sqlite
          libclang
          llvmPackages.clang

          # Development tools
          git
          gnumake
          just
          direnv
          nix-direnv

          # Formatting and linting (optional, can use cargo tools)
          rustfmt
          clippy

          # Debugging and profiling
          gdb
          valgrind
          flamegraph

          # Container tools (optional)
          docker
          docker-compose
        ];

      in
      {
        devShells.default = pkgs.mkShell {
          name = "rustfs-dev";
          buildInputs = devDependencies;

          shellHook = ''
            echo "🚀 RustFS development environment loaded"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "📋 Available commands:"
            echo "  make fmt              - Format code"
            echo "  make fmt-check        - Check formatting"
            echo "  make clippy           - Run clippy checks"
            echo "  make check            - Verify compilation"
            echo "  make test             - Run tests"
            echo "  make pre-commit       - Run all checks"
            echo "  ./build-rustfs.sh     - Build RustFS"
            echo "  ./build-rustfs.sh --dev  - Dev build"
            echo ""
            echo "🔧 Rust info:"
            echo "  Toolchain: $(rustc --version)"
            echo "  Cargo: $(cargo --version)"
            echo ""
            echo "📊 Code style guide:"
            echo "  • Max width: 130 columns"
            echo "  • Fn call width: 90 columns"
            echo "  • Use snake_case for items"
            echo "  • Use PascalCase for types"
            echo "  • Use SCREAMING_SNAKE_CASE for constants"
            echo "  • Avoid unwrap()/expect() outside tests"
            echo "  • Bubble errors with Result types"
            echo ""
            echo "📚 See docs/DEVELOPMENT.md for more info"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          '';

          # Environment variables for development
          RUSTFLAGS = "-D warnings";
          RUST_BACKTRACE = "1";
          
          # Configure Rust for KMS e2e tests
          NO_PROXY = "127.0.0.1,localhost";
          HTTP_PROXY = "";
          HTTPS_PROXY = "";
        };

        # Alternative shell with minimal dependencies
        devShells.minimal = pkgs.mkShell {
          name = "rustfs-minimal";
          buildInputs = with pkgs; [
            rustToolchain
            pkg-config
            openssl
            protobuf
          ];

          shellHook = ''
            echo "🚀 RustFS minimal development environment loaded"
          '';
        };

        # Shell for documentation and scripts only
        devShells.docs = pkgs.mkShell {
          name = "rustfs-docs";
          buildInputs = with pkgs; [
            git
            gnumake
          ];

          shellHook = ''
            echo "📚 RustFS documentation environment loaded"
          '';
        };
      }
    );
}
