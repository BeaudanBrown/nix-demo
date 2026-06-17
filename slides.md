<!-- alignment: center -->
<!-- jump_to_middle -->

# Nix for reproducible research
## Beaudan Campbell-Brown

<!-- end_slide -->
<!-- alignment: center -->

# What is Nix?

**Nix is a tool for describing, building and deploying software reproducibly.**

<!-- column_layout: [1, 1] -->

<!-- column: 0 -->

## Traditional

- Imperative
- Stateful
- Fragmented
- Transient

<!-- column: 1 -->

## Nix

- Declarative
- Reproducible
- Universal
- Ephemeral

<!-- reset_layout -->
<!-- pause -->
# What is software

<!-- column_layout: [1, 1] -->

<!-- column: 0 -->

## Software

- Compiled binaries
- Scripts
- Full stack applications
- System libraries

<!-- column: 1 -->

## Also software

- Development environments
- Analysis pipelines
- Containers
- Linux systems

<!-- end_slide -->
<!-- alignment: center -->

# What is deploying software
Binary -> Location
<!-- pause -->
# What is updating software
New Binary -> Old Binary
<!-- pause -->
# What is breaking software
Old Binary -\\> Location
<!-- pause -->
# How is software
<!-- column_layout: [1, 1] -->

<!-- column: 0 -->

## Traditional

- Name referenced
- Mutable
- Disparate
- Convention

<!-- column: 1 -->

## Nix

- Hash referenced
- Immutable
- Centralised
- Explicit

<!-- end_slide -->
<!-- alignment: center -->

# Quick peek at how
## Start from a minimal trusted base
- shell: `bash`
- basic Unix tools: `coreutils`, `findutils`, `grep`, `sed`, `awk`
- archive tools: `tar`, `gzip`, `xz`, `bzip2`
- build tools: `make`, `patch`
- compiler toolchain: `gcc`, `binutils`, `libc`
<!-- pause -->

## Hash all the inputs for a Nix build
- Dependencies
- Source code
- Build instructions
- Hashes of external resources
<!-- pause -->
<!-- column_layout: [1, 8, 1] -->
<!-- column: 1 -->
## Reference Nix outputs by their hash
```bash +exec
dirs=$(fd . /nix/store --max-depth 1 --type d --format '{/}')
printf 'Nix store directories: %s\n\n' "$(printf '%s\n' "$dirs" | wc -l)"
printf '%s\n' "$dirs" | shuf -n 5
```
<!-- reset_layout -->
<!-- end_slide -->
<!-- alignment: center -->

# In practice
## Nixpkgs
![image:width:100%](images/nixpkgs.png)
- \>140,000 packages
- \>1,000,000 commits
- \>15,000 contributors
- Cross platform
- Cross architecture
<!-- end_slide -->
<!-- alignment: center -->
# In practice
<!-- column_layout: [1, 1] -->

<!-- column: 0 -->
## Binary substitutors
- Trusted
- Configurable
- Can build too
```bash +exec +acquire_terminal
# /etc/nix/nix.conf
/// nvim '+15' '+normal! wwvE' /etc/nix/nix.conf
```
<!-- pause -->

<!-- column: 1 -->
## Package manager
- Build
- Run
- Devshells
```bash +exec
nix run nixpkgs#cowsay "Wow!"
cowsay "Oh no!" || true
```
<!-- end_slide -->
<!-- alignment: center -->
# In research
## Environments
- Local
- HPC
- Collaborators
- Local in 6 months
<!-- pause -->
## Tooling
<!-- column_layout: [1, 1, 1] -->

<!-- column: 0 -->
### R
- install.packages()
- pak
- renv
- packrat
<!-- pause -->
<!-- column: 1 -->
### HPC
- Modules
- Apptainer
- Docker
<!-- pause -->
<!-- column: 2 -->
### Python
- pip
- venv
- virtualenv
- uv
- conda
- mamba
- micromamba
- pipenv
- poetry
- pdm
- pixi
- pip-tools
- pipx
- pyenv
- ...
<!-- reset_layout -->
<!-- pause -->
---
- README
<!-- end_slide -->
<!-- alignment: center -->
# In research
<!-- column_layout: [1, 1, 1] -->

<!-- column: 0 -->
```bash +exec +acquire_terminal
# R with packages
/// nvim '+/pkgs.R' '+normal! VGk' nix/r-env.nix
```
<!-- pause -->
<!-- column: 1 -->

```bash +exec +acquire_terminal
# Python with packages
/// nvim '+/python3' '+normal! VGk' nix/python-env.nix
```
<!-- pause -->
<!-- column: 2 -->
```bash +exec +acquire_terminal
# General packages
/// nvim '+/bashInteractive' '+normal! VG' nix/demo-packages.nix
```
<!-- reset_layout -->
<!-- pause -->
## For referrence...
![image:width:100%](images/gdal1.png)
<!-- end_slide -->
<!-- alignment: center -->
# Nix everything
## Real world example
```bash +exec +acquire_terminal
# Complex packages
/// nvim nix/moonlight.nix
```
<!-- pause -->
<!-- new_lines: 2 -->
## Infrastructure
```bash +exec +acquire_terminal
# Anything as code
/// nvim '+/nginxVhosts' ~/documents/nix-dotfiles/modules/hosted-services/server.nix
/// nvim '+/hostedServices' ~/documents/nix-dotfiles/modules/services/attic/nas.nix
```
<!-- pause -->
<!-- new_lines: 2 -->
## Even Docker
```bash +exec +acquire_terminal
# Better than Docker
/// nvim '+normal! GVggj' nix/docker-image.nix
```
<!-- end_slide -->
<!-- jump_to_middle -->
<!-- alignment: center -->
# Let's see what this baby can do!
