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
- `nix/custom-praise.nix` — complete custom R package build using `buildRPackage`.
- `nix/r-env.nix` — R environment using Nixpkgs packages, the overlay, and the custom package.
- `nix/python-env.nix` — Python environment.
- `nix/demo-packages.nix` — shared package list used by both the dev shell and container.
- `nix/docker-image.nix` — Docker/OCI image generation with `dockerTools.buildLayeredImage`.

It demonstrates two ways to go beyond the package set in pinned `nixpkgs`:

1. **Build a custom R package directly:** `nix/custom-praise.nix` uses `pkgs.rPackages.buildRPackage` to build `praise` from a CRAN source tarball and add it to the R environment. This is the pattern for packages that are not yet in Nixpkgs, or for local patched versions.
2. **Override an existing package with an overlay:** `nix/overlay-clipr.nix` replaces `rPackages.clipr` with a newer CRAN version than the one available at this `nixpkgs` pin. This is the pattern for bumping a package while keeping the rest of the package set pinned.

## Run the demo

Because this is a Git repository, make sure the flake files are tracked before running Nix commands:

```bash
git add flake.nix nix scripts/demo-check.sh README.md presentation-plan.md
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

See `presentation-plan.md` for the talk outline.
