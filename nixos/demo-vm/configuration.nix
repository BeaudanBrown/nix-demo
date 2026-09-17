{ lib, modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
    ./demo.nix
  ];

  system.stateVersion = "26.05";

  programs.bash.loginShellInit = ''
    if [[ $- == *i* && "$USER" == demo ]]; then
      printf '%s\n' \
        'systemctl status demo-web --no-pager' \
        'cd /etc/nix-demo/nixos/demo-vm' \
        'http://grill:8080' \
        'http://grill:3000' \
        ""
    fi
  '';

  # Keep the traditional `nixos-rebuild switch` workflow available inside the
  # VM, using the pinned Nixpkgs source that built this system.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.nixPath = [
    "nixpkgs=${pkgs.path}"
    "nixos-config=/etc/nixos/configuration.nix"
  ];

  # The generated QEMU runner boots the kernel directly. Disable GRUB so an
  # in-guest `nixos-rebuild switch` never tries to install a bootloader onto
  # the disposable VM disk.
  boot.loader.grub.enable = false;

  # Keep the conventional rebuild entry point, but evaluate the live source
  # tree where relative imports of the package and app retain their layout.
  environment.etc."nixos/configuration.nix".text = ''
    import /etc/nix-demo/nixos/demo-vm/configuration.nix
  '';

  # Share only the configuration, package definitions, and application source.
  # SHARED_DIR is set by `just vm` to the host's nixos/demo-vm directory.
  virtualisation.sharedDirectories = {
    shared.target = lib.mkForce "/etc/nix-demo/nixos/demo-vm";
    demoPackages = {
      source = "\"\${SHARED_DIR}/../../nix\"";
      target = "/etc/nix-demo/nix";
      securityModel = "none";
    };
    demoApp = {
      source = "\"\${SHARED_DIR}/../../app\"";
      target = "/etc/nix-demo/app";
      securityModel = "none";
    };
  };

  virtualisation = {
    # Leave enough memory and disk for evaluating and switching a NixOS
    # configuration in-guest. The disk image is sparse on the host.
    cores = 4;
    memorySize = 2048;
    diskSize = 8192;

    # Avoid the 9p host-store plus overlayfs cache issue that can make newly
    # realised .drv paths appear missing to Nix inside the guest. The system
    # closure is instead supplied as a self-contained read-only store image,
    # with a persistent writable layer on the VM disk for guest rebuilds.
    mountHostNixStore = false;
    useNixStoreImage = true;
    writableStore = true;
    writableStoreUseTmpfs = false;

    # Use the serial console so the demo also works over SSH.
    graphics = false;
    forwardPorts = [
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
      {
        from = "host";
        host.port = 8080;
        guest.port = 8000;
      }
      {
        # Prepare forwarding before the live in-guest monitoring rebuild.
        from = "host";
        host.port = 3000;
        guest.port = 3000;
      }
    ];
  };
}
