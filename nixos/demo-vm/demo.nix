{ pkgs, ... }:

let
  demoWeb = import ../../nix/demo-web.nix { inherit pkgs; };
in
{
  # imports = [ ./monitoring.nix ];

  networking = {
    hostName = "demo";
    firewall.allowedTCPPorts = [ 8000 ];
  };

  users.users.demo = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    initialPassword = "demo";
  };
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  systemd.services.demo-web = {
    description = "Nix demo web application";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart = "${demoWeb}/bin/demo-web";
      DynamicUser = true;
      StateDirectory = "demo-web";
      WorkingDirectory = "/var/lib/demo-web";
      Restart = "on-failure";
    };
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    vim
  ];
}
