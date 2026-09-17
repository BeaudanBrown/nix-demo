{ pkgs, demoWeb }:
pkgs.dockerTools.buildLayeredImage {
  name = "nix-demo";
  tag = "latest";

  contents = [
    demoWeb
    pkgs.bashInteractive
    pkgs.coreutils
  ];

  extraCommands = ''
    mkdir -p tmp work
    chmod 1777 tmp
  '';

  config = {
    Cmd = [ "${demoWeb}/bin/demo-web" ];
    WorkingDir = "/work";
    ExposedPorts."8000/tcp" = { };
  };
}
