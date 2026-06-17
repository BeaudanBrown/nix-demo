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

        packages.demo-check = demoCheck;

        packages.dockerImage = import ./nix/docker-image.nix {
          inherit pkgs demoPackages demoCheck;
        };
      });
}
