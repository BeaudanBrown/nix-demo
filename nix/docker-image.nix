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
