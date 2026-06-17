# Container demo: build a Docker/OCI-style image from the same Nix environment.
#
# Build/load/run:
#   nix build .#dockerImage
#   docker load < result
#   docker run --rm -it nix-demo:latest
#   demo-check

{ pkgs, demoPackages, demoCheck }:

pkgs.dockerTools.buildLayeredImage {
  name = "nix-demo";
  tag = "latest";

  contents = demoPackages ++ [ demoCheck ];

  config = {
    Cmd = [ "/bin/bash" ];
    WorkingDir = "/work";
  };
}
