{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      demoVm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./nixos/demo-vm/configuration.nix ];
      };
    in
    {
      nixosConfigurations.demo = demoVm;
    }
    // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import ./nix/overlay-clipr.nix) ];
        };

        rEnv = import ./nix/r-env.nix {
          inherit pkgs;
        };

        pythonEnv = import ./nix/python-env.nix { inherit pkgs; };

        demoPackages = import ./nix/demo-packages.nix {
          inherit pkgs rEnv pythonEnv;
        };

        demoWeb = import ./nix/demo-web.nix { inherit pkgs; };

        demoCheck = pkgs.writeShellApplication {
          name = "demo-check";
          runtimeInputs = demoPackages;
          text = builtins.readFile ./scripts/demo-check.sh;
        };

        runContainer = pkgs.writeShellApplication {
          name = "run-container";
          runtimeInputs = [ pkgs.podman ];
          text = ''
            set -euo pipefail

            tmpdir="$(mktemp -d)"
            cleanup() {
              set +e
              if [[ -n "''${tmpdir:-}" && -d "$tmpdir" ]]; then
                if declare -p podman_ephemeral >/dev/null 2>&1; then
                  "''${podman_ephemeral[@]}" system reset --force >/dev/null 2>&1
                fi
                podman unshare rm -rf "$tmpdir" >/dev/null 2>&1 || rm -rf "$tmpdir" >/dev/null 2>&1 || true
              fi
            }
            trap cleanup EXIT

            export HOME="$tmpdir/home"
            mkdir -p "$HOME/.config/containers" "$tmpdir/storage" "$tmpdir/run" "$tmpdir/tmp"

            cat > "$HOME/.config/containers/policy.json" <<'EOF'
            {
              "default": [
                { "type": "insecureAcceptAnything" }
              ]
            }
            EOF

            podman_ephemeral=(
              podman
              --root "$tmpdir/storage"
              --runroot "$tmpdir/run"
              --tmpdir "$tmpdir/tmp"
            )

            echo "Loading nix-demo:latest into ephemeral Podman storage..."
            "''${podman_ephemeral[@]}" load --quiet --input ${self.packages.${system}.dockerImage}

            echo "Serving demo-web at http://grill:8001 (Ctrl+C to stop)..."
            "''${podman_ephemeral[@]}" run --rm -it -p 8001:8000 nix-demo:latest
          '';
        };
      in
      {
        devShells = {
          default = import ./nix/dev-shell.nix { inherit pkgs; };

          presentation = pkgs.mkShell {
            packages = with pkgs; [
              presenterm
              just
              fd
              bashInteractive
            ];
          };

          research = pkgs.mkShell {
            packages = demoPackages;
          };
        };

        apps = {
          demo-check = {
            type = "app";
            program = "${demoCheck}/bin/demo-check";
          };

          run-container = {
            type = "app";
            program = "${runContainer}/bin/run-container";
          };
        } // pkgs.lib.optionalAttrs (system == "x86_64-linux") {
          demo-vm = {
            type = "app";
            program = "${demoVm.config.system.build.vm}/bin/run-demo-vm";
          };
        };

        packages = {
          demo-web = demoWeb;
          demo-check = demoCheck;
          run-container = runContainer;
          dockerImage = import ./nix/docker-image.nix {
            inherit pkgs demoWeb;
          };
        } // pkgs.lib.optionalAttrs (system == "x86_64-linux") {
          demo-vm = demoVm.config.system.build.vm;
        };
      });
}
