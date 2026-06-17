# Nix eResearch presentation: demo plan

## Working title

**Nix for reproducible eResearch: one project, three machines**

## Core message

Nix lets us describe a research software environment once and reuse it across different platforms:

- my Linux machine;
- a Windows VM via WSL/NixOS-WSL;
- the HPC.

For the demo, the important point is not the Nix language itself. The important point is that a real mixed research environment — R, Python, and genomics command-line tools — can be made portable and repeatable.

## Demo repository

Use this folder:

```bash
cd nix-demo
```

This should be a **pure Nix** demo, not a `devenv` demo.

Current relevant files:

- `flake.nix` — small top-level composition file;
- `nix/overlay-clipr.nix` — overlay/version-bump demo;
- `nix/custom-praise.nix` — custom R package build demo;
- `nix/r-env.nix` — R environment;
- `nix/python-env.nix` — Python environment;
- `nix/demo-packages.nix` — shared dev shell/container package list;
- `nix/docker-image.nix` — container image generation demo;
- `scripts/demo-check.sh` — a quick cross-platform smoke test;
- `presentation-plan.md` — this document.

The older `devenv.nix` and `devenv.yaml` files can either be ignored or removed later if they become distracting.

## What the pure Nix demo environment contains

The flake is split into small imported files so each concept can be shown in isolation. Together, they demonstrate a realistic eResearch stack:

### R

Includes R plus packages such as:

- `targets`
- `tarchetypes`
- `data.table`
- `ggplot2`
- `dplyr`
- `readr`
- `reticulate`
- `terra`
- custom CRAN package `praise`, built directly with `buildRPackage`
- overlaid CRAN package `clipr`, bumped in `nix/overlay-clipr.nix`

### Python

Includes Python plus packages such as:

- `pandas`
- `requests`
- `python-dotenv`
- `geopandas`

### Genomics / geospatial / command-line tools

Includes:

- `plink-ng`
- `bcftools`
- `samtools`
- `htslib`
- `bedtools`
- `vcftools`
- `gdal`
- `quarto`

This maps well onto the kind of real research workflow where R is used for analysis/reporting, Python for glue/API/data work, and specialist binaries for domain-specific processing. It now deliberately spans two classic eResearch pain points: genomics tooling and geospatial/GDAL tooling.

## Main live demo command

The simplest version of the demo should be:

```bash
cd nix-demo
nix develop -c ./scripts/demo-check.sh
```

Alternative, if the flake app is working well:

```bash
nix run .#demo-check
```

The smoke test prints:

- machine information;
- Nix version;
- R version;
- Python version;
- PLINK version;
- bcftools version;
- samtools version;
- bedtools version;
- vcftools version;
- GDAL version;
- Quarto version;
- confirmation that selected R packages load;
- confirmation that selected Python packages import.

## Proposed presentation order

### 1. Open with the pain point

Start with the problem eResearch staff recognise immediately:

- research projects often mix R, Python, shell scripts, and specialised tools;
- Windows, Linux, and HPC environments drift apart;
- setup instructions become long and fragile;
- “works on my machine” becomes a support burden;
- rerunning an analysis six months later can be harder than it should be.

Suggested line:

> “I want to show the same research software environment running on three different machines with the same command.”

### 2. Briefly explain what Nix is doing

Keep this short.

Key points:

- `flake.nix` composes the environment from small declarative files;
- `flake.lock` pins the exact upstream inputs;
- `nix develop` enters the project environment;
- tools do not need to be installed globally;
- the project carries its environment recipe with it.

Suggested line:

> “The repository becomes not just code and data-processing scripts, but also a precise recipe for the software environment.”

### 3. Show `nix-demo/flake.nix`

Open the file and point out that the top-level flake mostly composes small demo files:

- `nix/r-env.nix` — R environment, including `terra`;
- `nix/python-env.nix` — Python environment, including `geopandas`;
- `nix/demo-packages.nix` — genomics/geospatial/system tools;
- `nix/docker-image.nix` — container image generation;
- `nix/overlay-clipr.nix` and `nix/custom-praise.nix` — package extension examples.

Do not explain every line. The audience just needs to see that the environment is declared in small, composable pieces.

Suggested line:

> “This is the whole point: R packages, Python packages, geospatial libraries, and genomics binaries are specified together.”

### 4. Show custom packaging and an overlay

Goal: show two different ways the project can go beyond exactly what is in the pinned `nixpkgs` package set.

#### A. Build a custom R package directly

Point out `nix/custom-praise.nix`:

```nix
customPraise = pkgs.rPackages.buildRPackage rec {
  pname = "praise";
  version = "1.0.0";
  src = pkgs.fetchurl {
    url = "https://cran.r-project.org/src/contrib/${pname}_${version}.tar.gz";
    hash = "...";
  };
};
```

Narrative:

> “This is the pattern for a package that is not in Nixpkgs yet, or for a project-local package/patched version that I want to add to this environment.”

#### B. Override an existing package with an overlay

Point out `nix/overlay-clipr.nix`:

```nix
projectOverlay = final: prev: {
  rPackages = prev.rPackages.override {
    overrides = {
      clipr = prev.rPackages.clipr.overrideAttrs (old: rec {
        version = "0.8.1";
        src = prev.fetchurl {
          url = "https://cran.r-project.org/src/contrib/clipr_${version}.tar.gz";
          hash = "...";
        };
      });
    };
  };
};
```

Narrative:

> “This is an overlay. It installs a change into the package set. Inside the overlay, `overrideAttrs` keeps the existing Nixpkgs recipe for `clipr` but swaps a few derivation attributes — here, the version and source hash. This is the simple pattern for bumping a package while keeping the rest of Nixpkgs pinned.”

Useful nuance:

> “For simple CRAN packages, this can be only a few lines. For harder packages, Nix gives us a structured place to declare system libraries, R dependencies, build flags, and patches.”

### 5. Run on local machine

On local Linux machine:

```bash
cd nix-demo
nix develop -c ./scripts/demo-check.sh
```

Narrative:

> “This is my normal machine. The tools are coming from the project environment, not from whatever I happened to install globally.”

### 6. Run on Windows VM under WSL

Switch to the Windows VM / WSL terminal and run the same thing:

```bash
cd nix-demo
nix develop -c ./scripts/demo-check.sh
```

Narrative:

> “Now the platform has changed, but the project command has not.”

This is a natural bridge to `wsl-nix/`.

### 7. Show `wsl-nix/` as the managed Windows researcher workstation

After showing that `nix-demo` works under WSL, open:

```bash
wsl-nix/configuration.nix
```

Use this as the more practical support story for Windows users.

Show that it can declare:

- NixOS-WSL setup;
- R and R packages;
- Positron configured with the Nix R environment;
- helper aliases for researchers;
- mounted Windows/home/S-drive locations;
- system-level packages.

Suggested line:

> “The project flake solves the project environment. NixOS-WSL solves the researcher workstation.”

### 8. Run on HPC

On the HPC, run the same core command if possible:

```bash
cd nix-demo
nix develop -c ./scripts/demo-check.sh
```

If the HPC requires an interactive job first, the shape might be:

```bash
# example only; adapt to the actual scheduler
salloc ...
cd nix-demo
nix develop -c ./scripts/demo-check.sh
```

Narrative:

> “This is where Nix becomes very relevant for eResearch: the same project environment can follow the project from laptop to WSL to HPC.”

Caveat to mention honestly:

- HPC Nix support depends on local policy and setup;
- possibilities include site-supported Nix, user-level Nix, nix-portable, or containers built from Nix;
- the point is to reduce per-project environment drift, not to bypass HPC administration.

### 9. Build and run a container image from the same flake

Goal: show that Nix can fit into existing container-based workflows rather than replacing them.

Build and load the image:

```bash
cd nix-demo
nix build .#dockerImage
docker load < result
```

Run the smoke test directly:

```bash
docker run --rm nix-demo:latest demo-check
```

Run interactively, then execute the check from inside the image:

```bash
docker run --rm -it nix-demo:latest
```

Inside the container:

```bash
demo-check
```

Podman equivalent:

```bash
podman load < result
podman run --rm -it nix-demo:latest
```

Narrative:

> “The same flake gives me an interactive development environment and a container image. So Nix can be the reproducible build/dependency layer, while Docker, Podman, Apptainer, or HPC container workflows remain the runtime/deployment layer.”

### 10. Close with what eResearch could do with this

Possible closing points:

- provide project templates for R/Python/genomics workflows;
- provide WSL/NixOS-WSL configurations for Windows researchers;
- make HPC onboarding easier;
- reduce environment debugging;
- improve reproducibility and handover;
- package difficult software stacks once and reuse them.

Suggested closing line:

> “Nix gives us a path from fragile setup instructions to reproducible research environments that can be shared, rebuilt, and supported.”

## Backup plan

Before the talk, pre-build the environment on all three machines.

Run once on each:

```bash
cd nix-demo
nix develop -c ./scripts/demo-check.sh
```

Save the output from each machine in case live network/cache access fails.

Potential files to create later:

```text
outputs/local.txt
outputs/wsl.txt
outputs/hpc.txt
```

If something fails live, show the saved output and explain that first-time realisation depends on cache/network availability.

## Locked-in demo items / talking points

Use this section as the running list of ideas to incorporate as they come up.

### Locked in: container image from the flake

A `dockerImage` output is provided using `pkgs.dockerTools.buildLayeredImage`.

Demo shape:

```bash
cd nix-demo
nix build .#dockerImage
docker load < result
docker run --rm nix-demo:latest demo-check
```

Interactive container demo:

```bash
docker run --rm -it nix-demo:latest
# inside container
demo-check
```

Talking point:

> “Nix does not have to replace container workflows. The same flake can provide a dev shell for researchers and a container image for Docker/Podman/Apptainer-style workflows.”

Why `buildLayeredImage` rather than `nix2container` for this talk:

- built into Nixpkgs;
- easier to explain;
- fewer moving parts;
- good enough to demonstrate compatibility with existing container workflows.

Mention as an aside:

> “For more advanced registry/push workflows, tools like `nix2container` exist.”

### Talking point: declarative rather than imperative setup

Traditional setup instructions are usually imperative:

> “Install this, then install that, then edit this config file, then set this environment variable, then hope everyone did the steps in the same order.”

Nix changes the framing to declarative:

> “This is the environment I want.”

Useful points to hit:

- setup becomes a specification rather than a sequence of manual steps;
- replication is easier because other people do not need to remember the order or avoid missing a step;
- undoing is easier: remove something from the declaration and rebuild/re-enter the environment;
- the broader machine state matters much less because the environment is isolated;
- the same declaration can be used by a human locally, a WSL workstation, CI, a container build, or an HPC workflow.

Possible line:

> “With imperative instructions, reproducibility depends on everyone doing the same steps correctly. With Nix, reproducibility comes from sharing the declaration.”

Another possible line:

> “Undo is not ‘work out what the install script changed’; undo is ‘declare the state without that thing in it’.”

### Talking point: Nix as content-addressed software / reproducible closures

Phrase carefully. Nix is historically input-addressed at the derivation level, with ongoing/content-addressed store work, but the useful audience-level idea is:

> “Nix treats software environments as immutable store paths identified by hashes of their build recipes and dependencies. Instead of ‘whatever is installed on this machine’, we get explicit, reproducible dependency closures.”

Possible simpler version for the talk:

> “A Nix environment is not just a name like ‘R 4.x’; it is a hashed closure of exact dependencies.”

Avoid overclaiming that all of Nix is purely content-addressed in the same way as Git/IPFS. Better wording:

> “Nix brings content-addressed-style thinking to software environments: immutable, hashed, reproducible dependency graphs.”

### Locked in: cross-compilation + binfmt emulation demo

Goal:

1. Build a binary for a different architecture.
2. Show that it cannot run natively.
3. Run it through binfmt/QEMU emulation.

Possible demo shape:

```bash
nix build .#hello-aarch64
file result/bin/hello-demo
./result/bin/hello-demo   # expected to fail on x86_64 without emulation
```

Then, with binfmt/QEMU available:

```bash
./result/bin/hello-demo
```

or explicitly:

```bash
qemu-aarch64 ./result/bin/hello-demo
```

Talking point:

> “Nix can describe not only what software we need, but what platform it is built for. Cross-compilation becomes part of the same reproducible build story.”

Need to prepare:

- decide target architecture, likely `aarch64-linux` from `x86_64-linux`;
- add a tiny C/Rust/Go hello binary to the flake;
- add a cross-compiled package output;
- check whether binfmt is available on local machine and WSL;
- decide whether to use transparent binfmt or explicit `qemu-aarch64` for reliability.

### Candidate demo/talking point: complex systems Nix makes easier

Strong candidates to consider:

1. **CUDA/GPU machine learning stack**
   - Usually painful because of driver/toolkit/Python library compatibility.
   - Nix can pin CUDA toolkit, Python, PyTorch/JAX, compilers, and system libraries.
   - Caveat: GPU drivers still depend on host/HPC setup.

2. **Geospatial stack**
   - R/Python geospatial environments are notoriously fragile: GDAL, PROJ, GEOS, `sf`, `terra`, Python `geopandas`, etc.
   - Very relevant to eResearch because many disciplines use GIS.
   - Nix makes the native library stack explicit rather than hoping R/Python packages find matching system libraries.

3. **LaTeX/Quarto publishing stack**
   - TinyTeX/TeXLive, Pandoc, Quarto, fonts, R/Python packages.
   - Good for reproducible reporting.
   - Visually understandable, but less technically impressive than CUDA/geospatial.

4. **Bioinformatics pipeline stack**
   - Aligners, samtools/bcftools/htslib, PLINK, R, Python, workflow tools.
   - This already aligns with `nix-demo` and `genes/`.

Current best recommendation:

> Use **geospatial** as the “Nix makes complex native dependency stacks trivial” talking point, and **bioinformatics/genomics** as the live demo stack.

Why geospatial is a good talking point:

- it is cross-disciplinary;
- many eResearch people have seen GDAL/PROJ pain;
- it clearly shows Nix solving native-library dependency issues that Conda/pip/R alone often struggle with.

Potential line:

> “If you have ever tried to get R `sf`, Python `geopandas`, GDAL, PROJ, and GEOS all agreeing with each other on three machines, you have already met the kind of problem Nix is good at.”

## Things to prepare

- Decide whether to delete or hide the old `devenv.nix` / `devenv.yaml` files.
- Generate and commit `flake.lock` before the presentation.
- Pre-run the demo on local, WSL, and HPC.
- Confirm whether the PLINK executable is `plink2` or `plink` on each platform.
- Test the direct `customPraise` R package build in `nix/custom-praise.nix`.
- Test the `clipr` version bump in `nix/overlay-clipr.nix`.
- Test `dockerTools.buildLayeredImage` as `.#dockerImage`.
- Add and test a cross-compiled binary demo plus binfmt/QEMU execution.
- Decide whether the HPC demo will be on login node, interactive compute job, or submitted batch job.
- Consider adding a tiny example R script and Python script if the smoke test feels too version-check-heavy.
- Prepare one slide on `flake.nix` vs `flake.lock`.
- Prepare one slide on project environment vs whole-machine WSL configuration.
- Prepare one slide on Nix + containers.
- Prepare one slide or short aside on hashed immutable dependency closures / content-addressed-style software.
