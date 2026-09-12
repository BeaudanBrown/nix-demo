{ pkgs, ... }:

{
  networking = {
    hostName = "demo";
    firewall.allowedTCPPorts = [ 80 ];
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

  services.nginx = {
    enable = true;
    virtualHosts.localhost.root = pkgs.writeTextDir "index.html" ''
      <!doctype html>
      <title>NixOS demo VM</title>
      <h1>NixOS demo VM</h1>
      <p>This web server, user account, SSH service, and firewall are declared in <code>/etc/nixos/demo.nix</code>.</p>
    '';
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    vim
  ];
}
