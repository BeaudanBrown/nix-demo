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
- `nix/demo-packages.nix` — package list for the research shell and smoke test.
- `nix/docker-image.nix` — Docker/OCI image generation with `dockerTools.buildLayeredImage`.

It demonstrates how to go beyond the package set in pinned `nixpkgs`:

**Override an existing package with an overlay:** `nix/overlay-clipr.nix` replaces `rPackages.clipr` with a newer CRAN version than the one available at this `nixpkgs` pin. This is the pattern for bumping a package while keeping the rest of the package set pinned.

## Present and demonstrate nix develop

The shells are separate: `just presentation-env` enters `.#presentation` (Presenterm, just,
fd, Bash), plain `nix develop` enters the lightweight web-development
environment, and `nix develop .#research` keeps the original research tools.
The presentation shell does not explicitly provide Python; host tools may
still be inherited. The recipe preserves your original `$SHELL` so slide
handoffs use your normal shell rather than Nix's build-time Bash. Neovim is
inherited from the host so editor demos use your globally configured version.

Before using the updated Git flake, track the new source files:

```bash
git add justfile nix/dev-shell.nix nix/demo-web.nix app/
```

Enter the presentation environment explicitly, then launch the presentation:

```bash
just presentation-env
just present
```

There is no `.envrc`, so this repository no longer automatically loads an
environment through direnv. If an older environment is still active, let your
normal shell process a prompt (or leave and re-enter the directory) before
running the recipe. `exit` leaves the presentation environment.

On the `nix develop` slide, execute the block to open your normal interactive
shell (`$SHELL`), including its usual prompt and startup hooks. It inherits
the presentation environment without a project direnv reload. Inspect Python
first, then enter the demo:

```bash
command -v python || echo "Python not on PATH"
python --version
nix develop
```

The slide terminal prints the full sequence once: `python --version`,
`nix develop`, `python --version`, and `python app/server.py`, followed by
`http://grill:8000` to open on T480. Entering the development shell prints no
additional checklist. The dev shell exports `DEMO_MODE=DEV`, which displays a
DEV badge on the page. Without that setting the badge reads PROD; run the later
built application outside `nix develop` to avoid inheriting DEV. These are demo
labels, not different security settings or proof of how the app was built.
The server binds to all interfaces by default for
this local/Tailnet demo (not production use); `HOST`, `PORT`, and
`DEMO_MESSAGE` can override its settings. `/info` returns JSON and `/health`
returns a health response.

Ctrl+C stops the server. `exit` leaves the development shell; a second `exit`
returns to Presenterm. `just present` and `just notes` use the tools already
provided by `just presentation-env`, without entering another Nix shell.

## Build the web application

`nix/demo-web.nix` packages the Python source, HTML, and local logo, then creates
a launcher referencing its declared Python in the store. No development shell
is required to run the result.

Stop the DEV server and exit `nix develop` first (so `DEMO_MODE=DEV` is no longer
inherited), then run from the presentation environment:

```bash
mkdir -p output
nix build .#demo-web --out-link output/demo-web
readlink -f output/demo-web
./output/demo-web/bin/demo-web
```

Open `http://grill:8000` on T480. The page now displays PROD. Ctrl+C stops the
server. Both demos use port 8000, so they run sequentially.

## Run the research demo

Because this is a Git repository, make sure the flake files are tracked before running Nix commands:

```bash
git add flake.nix nix nixos scripts/demo-check.sh README.md presentation-plan.md
```

Then run:

```bash
nix develop .#research -c ./scripts/demo-check.sh
```

or:

```bash
nix run .#demo-check
```

## Build and run the container image

`nix/docker-image.nix` reuses the exact `demo-web` package and includes its
runtime dependency closure, not the research tools or development shell.
The container starts the web app directly in `/work`, using its default PROD mode.

On the container slide, execute the left block to inspect the definition in
Neovim (`:q` returns). Advance once to reveal the right block, then execute it
to enter the command shell.

```bash
nix build .#dockerImage --out-link output/demo-image
docker load < output/demo-image
docker run --rm -it -p 8001:8000 nix-demo:latest
```

Open `http://grill:8001` on T480. Compare the container hostname and `/work`
with the local app at port 8000. Ctrl+C stops the container; `--rm` removes it.
The image stays loaded for reuse.

Nix builds the image without Docker. Grill's installed Docker client and daemon
load and run it. Exposed-port metadata alone doesn't publish a port;
`-p 8001:8000` does that at runtime. The Podman helper is not used in this demo,
and no `allow-new-privileges` override is needed.

## Boot the NixOS demo VM

The flake also defines a disposable, terminal-based NixOS QEMU VM in
`nixos/demo-vm/configuration.nix`. It declares a `demo` user, SSH, the packaged
web app as a systemd service, firewall rules, and host-to-guest port forwarding.
The service uses a dynamic user, starts at boot in `/var/lib/demo-web`, and
keeps the app's default PROD mode. Host port 8080 forwards to guest port 8000.

`just vm` shares three directories under `/etc/nix-demo`, preserving the
repository layout: `nixos/demo-vm/`, `nix/`, and `app/`. This lets the guest
rebuild the same package from the shared sources without exposing the whole
repository. `/etc/nixos/configuration.nix` is a generated entry point importing
`/etc/nix-demo/nixos/demo-vm/configuration.nix`; edit the shared source files,
not that generated entry point. `demo.nix` remains the compact definition for
the live demo.

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
cd /etc/nix-demo/nixos/demo-vm
vim demo.nix
sudo nixos-rebuild switch
```

For example, add `pkgs.cowsay` to `environment.systemPackages`, rebuild, then
run `cowsay declarative systems`. Changes to `/etc/nix-demo/nixos/demo-vm/demo.nix` persist in
`nixos/demo-vm/demo.nix` on the host. The VM uses a
self-contained Nix store image plus a writable store on its virtual disk, so
the first guest rebuild may download or build dependencies but subsequent
rebuilds can reuse those paths.

### Live monitoring-stack rebuild

Start the VM with the updated launcher (`just vm`) so host port 3000 is already
forwarded to the guest. In `demo.nix`, uncomment:

```nix
imports = [ ./monitoring.nix ];
```

Run `sudo nixos-rebuild switch` inside the guest, then open
`http://grill:3000`. The first rebuild may download/build the monitoring stack;
cache it before the talk. `monitoring.nix` enables node exporter, Prometheus,
and Grafana, provisions the data source and a CPU/memory/disk/network dashboard,
and makes that dashboard the home page. Allow a few scrape intervals for rate
graphs to populate. No login or UI configuration is needed on a fresh Grafana
database: anonymous users have Viewer access. Anyone who can reach port 3000
can view these metrics; this is intentionally a demo configuration.

Grafana's encryption key and initial admin password are generated on first
service start and retained in its data directory, not embedded in the Nix
store. Existing Grafana database preferences or credentials are not reset.

The VM's persistent, sparse disk image is `demo.qcow2` in the directory from
which the command is run. Delete it to reset the VM and its guest-built Nix
store. The demo password and passwordless `sudo` are intentionally insecure
and must only be used for this local VM.

See `presentation-plan.md` for the talk outline.
