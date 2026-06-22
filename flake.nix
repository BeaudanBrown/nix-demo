{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import ./nix/overlay-clipr.nix) ];
        };

        customPraise = import ./nix/custom-praise.nix { inherit pkgs; };

        rEnv = import ./nix/r-env.nix {
          inherit pkgs;
        };

        # rEnv = import ./nix/r-env.nix {
        #   inherit pkgs customPraise;
        # };

        pythonEnv = import ./nix/python-env.nix { inherit pkgs; };

        demoPackages = import ./nix/demo-packages.nix {
          inherit pkgs rEnv pythonEnv;
        };

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

            echo "Running demo-check in nix-demo:latest..."
            "''${podman_ephemeral[@]}" run --rm nix-demo:latest -it
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = demoPackages ++ [
            pkgs.presenterm
          ];
        };

        apps.demo-check = {
          type = "app";
          program = "${demoCheck}/bin/demo-check";
        };

        apps.run-container = {
          type = "app";
          program = "${runContainer}/bin/run-container";
        };

        packages.demo-check = demoCheck;
        packages.run-container = runContainer;

        packages.dockerImage = import ./nix/docker-image.nix {
          inherit pkgs demoPackages demoCheck;
        };
      });
}
