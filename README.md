# Nix eResearch demo

Pure Nix demo for a presentation on reproducible eResearch environments.

The environment combines:

- R and R packages;
- Python and Python packages;
- genomics command-line tools such as PLINK, bcftools, samtools, htslib, bedtools, and vcftools;
- geospatial tooling such as GDAL, Python `geopandas`, and R `terra`;
- Quarto.

The flake is split into small files so each demo concept can be shown in isolation:

- `flake.nix` — small top-level composition file.
- `nix/overlay-clipr.nix` — overlay that bumps an existing Nixpkgs R package.
- `nix/r-env.nix` — R environment using Nixpkgs packages and the overlay.
- `nix/python-env.nix` — Python environment.
- `nix/demo-packages.nix` — shared package list used by both the dev shell and container.
- `nix/docker-image.nix` — Docker/OCI image generation with `dockerTools.buildLayeredImage`.

It demonstrates how to go beyond the package set in pinned `nixpkgs`:

**Override an existing package with an overlay:** `nix/overlay-clipr.nix` replaces `rPackages.clipr` with a newer CRAN version than the one available at this `nixpkgs` pin. This is the pattern for bumping a package while keeping the rest of the package set pinned.

## Run the demo

Because this is a Git repository, make sure the flake files are tracked before running Nix commands:

```bash
git add flake.nix nix nixos scripts/demo-check.sh README.md presentation-plan.md
```

Then run:

```bash
nix develop -c ./scripts/demo-check.sh
```

or:

```bash
nix run .#demo-check
```

## Build and run the container image

The same flake can also build a Docker/OCI-style image containing the same tools as the dev shell.

Build the image tarball:

```bash
nix build .#dockerImage
```

Load it into Docker:

```bash
docker load < result
```

Or with Podman:

```bash
podman load < result
```

Run the smoke test directly from the image:

```bash
docker run --rm nix-demo:latest demo-check
```

Run the image interactively, then launch the smoke test from inside the container:

```bash
docker run --rm -it nix-demo:latest
```

Inside the container:

```bash
demo-check
```

Podman equivalent:

```bash
podman run --rm -it nix-demo:latest
```

The intended presentation move is to run the same command on:

1. local Linux machine;
2. Windows VM under WSL;
3. HPC;
4. inside a container built by Nix.

## Boot the NixOS demo VM

The flake also defines a disposable, terminal-based NixOS QEMU VM in
`nixos/demo-vm/configuration.nix`. It declares a `demo` user, SSH, nginx,
firewall rules, and host-to-guest port forwarding. `just vm` shares only the
`nixos/demo-vm/` directory into the guest as `/etc/nixos`, so the VM has the
familiar editable `/etc/nixos/configuration.nix` without exposing the rest of
this repository. That entry file contains VM/store bootstrapping and imports
`/etc/nixos/demo.nix`, the compact file intended for the live configuration
demo.

Start it with:

```bash
just vm
```

The VM opens its serial console in the current terminal, including over SSH;
no graphical display is required. Log in as `demo` with password `demo`.
Shut down cleanly with `sudo poweroff`, or exit QEMU immediately with
`Ctrl-a`, then `x`. While the VM is running, another terminal on the host can
also use:

```bash
ssh -p 2222 demo@localhost
curl http://localhost:8080
```

To inspect or change the configuration from inside the VM:

```bash
cd /etc/nixos
vim demo.nix
sudo nixos-rebuild switch
```

For example, add `pkgs.cowsay` to `environment.systemPackages`, rebuild, then
run `cowsay declarative systems`. Changes to `/etc/nixos/demo.nix` persist in
`nixos/demo-vm/demo.nix` on the host. The VM uses a
self-contained Nix store image plus a writable store on its virtual disk, so
the first guest rebuild may download or build dependencies but subsequent
rebuilds can reuse those paths.

The VM's persistent, sparse disk image is `demo.qcow2` in the directory from
which the command is run. Delete it to reset the VM and its guest-built Nix
store. The demo password and passwordless `sudo` are intentionally insecure
and must only be used for this local VM.

See `presentation-plan.md` for the talk outline.
