{ lib, modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
    ./demo.nix
  ];

  system.stateVersion = "26.05";

  # Keep the traditional `nixos-rebuild switch` workflow available inside the
  # VM, using the pinned Nixpkgs source that built this system.
  nix.nixPath = [
    "nixpkgs=${pkgs.path}"
    "nixos-config=/etc/nixos/configuration.nix"
  ];

  # The generated QEMU runner boots the kernel directly. Disable GRUB so an
  # in-guest `nixos-rebuild switch` never tries to install a bootloader onto
  # the disposable VM disk.
  boot.loader.grub.enable = false;

  # The QEMU launcher exposes only this configuration directory with the 9p
  # tag "shared", placing the editable file at the conventional location.
  virtualisation.sharedDirectories.shared.target = lib.mkForce "/etc/nixos";

  virtualisation = {
    # Leave enough memory and disk for evaluating and switching a NixOS
    # configuration in-guest. The disk image is sparse on the host.
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
        guest.port = 80;
      }
    ];
  };
}
