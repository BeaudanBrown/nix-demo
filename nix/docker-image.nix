{ pkgs, demoPackages, demoCheck }:
pkgs.dockerTools.buildLayeredImage {
  name = "nix-demo";
  tag = "latest";

  contents = demoPackages ++ [ demoCheck ];

  extraCommands = ''
    mkdir -p tmp work
    chmod 1777 tmp
  '';

  config = {
    Cmd = [ "/bin/bash" ];
    WorkingDir = "/work";
  };
}
