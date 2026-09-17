<!-- alignment: center -->
<!-- jump_to_middle -->

# Nix in a Nutshell
## Beaudan Campbell-Brown

<!--
speaker_note: |
  - High level of what Nix is and why I use it
  - Shallow dive into the internals
  - Better at answering questions than I am presenting
-->

<!-- end_slide -->
<!-- alignment: center -->
<!-- jump_to_middle -->
# Plan

<!--
speaker_note: |
  - Why → how it works → how to use it → real examples
  - Interrupt with questions
  - Happy to slow down or follow an interesting tangent
  - Show things live where practical
-->

| Overview | | Suggestions | |
|---|---|---|---|
| Why Nix | <span style="color: #94e2d5">should make your life easier</span> | Ask questions | <span style="color: #94e2d5">what do you want to know</span> |
| How it works (briefly) | <span style="color: #94e2d5">rabbit hole</span> | Slow me down | <span style="color: #94e2d5">confused or interested</span> |
| How you use it | <span style="color: #94e2d5">language, tool, ecosystem</span> | Anything is possible | <span style="color: #94e2d5">yes it can do that¹</span> |
| How I am using it | <span style="color: #94e2d5">everything</span> | Live is impressive | <span style="color: #94e2d5">if I can show it I will</span> |

<!-- end_slide -->
<!-- alignment: center -->
<!-- jump_to_middle -->
# What is software

<!--
speaker_note: |
  - Left column
    - Software isn’t just the executable—it includes everything needed to run it
    - Scripts still depend on interpreters and external tools
    - Applications depend on services; libraries introduce version compatibility problems
  - Right column
    - An environment is itself something we can build and share
    - Reference your research pipeline: each stage consumes the previous stage’s outputs
    - Nix can produce containers, not just compete with them
    - Ansible/Puppet automate machine setup; NixOS applies Nix’s model to whole systems
  - Same building blocks, different scales
-->

| Software | | Also software | |
|---|---|---|---|
| Compiled binaries | <span style="color: #94e2d5">browser, git, ffmpeg</span> | Development environments | <span style="color: #94e2d5">postgres, R, toolchain</span> |
| Scripts | <span style="color: #94e2d5">bash, python</span> | Analysis pipelines | <span style="color: #94e2d5">load → clean → process</span> |
| Full stack applications | <span style="color: #94e2d5">multi-process, database, daemons</span> | Containers | <span style="color: #94e2d5">docker, SIF</span> |
| System libraries | <span style="color: #94e2d5">glibc, openssl, cuda</span> | Linux systems | <span style="color: #94e2d5">workstations, servers, VMs</span> |

<!-- end_slide -->
<!-- alignment: center -->
<!-- jump_to_middle -->
# How is software run

<!--
speaker_note: |
  - Left column
    - A name like `python` doesn’t identify a particular build
    - Software may rely on tools or libraries you forgot were installed
    - Your project stays unchanged, but an upgrade changes its surroundings
  - Right column
    - Pinning records more precise dependency choices
    - Manifests and build recipes make requirements explicit
    - Isolation reduces interference between projects—not all change
    - These approaches complement each other; we often combine them
  - Transition
    - Nix brings these ideas together around explicit build inputs and dependencies
-->

| How software runs | | How we manage it | |
|---|---|---|---|
| Name referenced | <span style="color: #f38ba8">executable names, library names</span> | Pin dependencies | <span style="color: #94e2d5">lockfiles, image digests</span> |
| Implicit dependencies | <span style="color: #f38ba8">assumes tools and libraries exist</span> | Declare dependencies | <span style="color: #94e2d5">manifests, build recipes</span> |
| Mutable | <span style="color: #f38ba8">upgrades, installs, removals</span> | Isolate environments | <span style="color: #94e2d5">venv, Conda, Docker</span> |

<!-- end_slide -->
<!-- alignment: center -->
<!-- jump_to_middle -->

# What is Nix?

<!--
speaker_note: |
  - Imperative → Declarative
    - Declare inputs and desired outputs
    - Compiler commands and Makefiles remain imperative
    - Nix encapsulates them as “pure” functional steps
  - Stateful → Hermetic
    - Explicit dependencies instead of ambient machine state
    - Sandboxing enforces the build boundary
  - Fragmented → Centralised
    - Explicit paths in `/nix/store`
    - Multiple versions coexist
    - Profiles—and many NixOS system paths—use symlinks to expose store content
    - Remove the target and the link no longer works; application data outside the store remains
  - Transient → Ephemeral
    - Returning to a project feels risky: the environment has drifted
    - Temporary shell, durable environment definition
    - Recreate the environment instead of preserving a fragile installation
    - Impermanence: reset an ephemeral root at boot; explicitly choose which state persists
    - Undeclared changes on the ephemeral filesystem disappear—not a full system rebuild each boot
-->

**Nix is a tool for configuring, building and deploying software reproducibly.**

| Traditional | | Nix | |
|---|---|---|---|
| Imperative | <span style="color: #f38ba8">step 1, step 2</span> | Declarative | <span style="color: #94e2d5">describe the state you want</span> |
| Stateful | <span style="color: #f38ba8">success depends on ambient environment</span> | Hermetic | <span style="color: #94e2d5">success is transferable</span> |
| Fragmented | <span style="color: #f38ba8">what does "install" do?</span> | Centralised | <span style="color: #94e2d5">everything in the /nix/store</span> |
| Transient | <span style="color: #f38ba8">contingent, works while it's there</span> | Ephemeral | <span style="color: #94e2d5">leaves no trace</span> |

<!-- end_slide -->
<!-- alignment: center -->
<!-- jump_to_middle -->
# Why Nix

<!--
speaker_note: |
  - Should be easy → Everything is code
    - Running software should be the easy part
    - Express setup as code we can inspect and debug
  - Docker often feels wrong → Changes can be fearless
    - Do I need a container for every tool?
    - Track configuration in Git; inspect and revert changes
    - Configuration history isn’t a backup of application data
  - Why am I following a README → Someone already did it
    - Manual instructions drift, miss steps, and assume machine state
    - Reuse a working package definition instead of repeating the setup
  - Too many tools → Everything is composable
    - Different tools for packages, environments, containers, and systems
    - Nix provides a shared model for composing these
    - Jenga versus Lego: changing a shared stack versus connecting explicit pieces
-->

| Traditional | | Nix | |
|---|---|---|---|
| Should be easy | <span style="color: #94e2d5">laziness, impatience, hubris</span> | Everything is code  | <span style="color: #94e2d5">debuggable & correct</span> |
| Docker often feels wrong | <span style="color: #94e2d5">a container for every tool?</span> | Changes can be fearless | <span style="color: #94e2d5">configuration tracked in Git</span> |
| Why am I following a README | <span style="color: #94e2d5">a script that doesn't work</span> | Someone already did it | <span style="color: #94e2d5">it works on OUR machine</span> |
| Too many tools | <span style="color: #94e2d5">I don't care how it's done</span> | Everything is composable | <span style="color: #94e2d5">software feels like lego</span> |

<!-- pause -->

<!-- end_slide -->
<!-- alignment: center -->

# Quick peek behind the scenes
<!-- column_layout: [1, 1] -->

<!-- column: 0 -->
## Start from a minimal trusted base
Think compiler bootstrapping, Nix assembly
- shell: `bash`
- basic Unix tools: `coreutils`, `findutils`, `grep`, `sed`, `awk`
- archive tools: `tar`, `gzip`, `xz`, `bzip2`
- build tools: `make`, `patch`
- compiler toolchain: `gcc`, `binutils`, `libc`
<!-- pause -->
<!-- column: 1 -->

## Identify by the inputs
- Dependencies
- Source code
- Build instructions
- Hashed
<!-- pause -->
<!-- reset_layout -->
## Downstream consumes from store
```bash +exec
# My /nix/store
/// dirs=$(fd . /nix/store --max-depth 1 --type d --format '{/}')
/// printf 'Nix store directories: %s\n\n' "$(printf '%s\n' "$dirs" | wc -l)"
/// printf '%s\n' "$dirs" | shuf -n 5
```
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
# nix run
## Run it. Don't install it.

<!--
speaker_note: |
  - Run a program without adding it to your normal PATH or global profile
  - Resolve: evaluate the package definition to identify the expected output and dependencies
  - Store, cache, and build are fallbacks—not three operations performed every time
  - A local hit skips downloading and building
  - Dependencies follow the same process; building an app need not mean building its compiler
  - Downloads and build outputs remain in /nix/store for reuse
  - nix run uses the host environment; it is not a container or runtime sandbox
  - This nixpkgs reference uses the registry; the project demos will use locked flake inputs
  - Before presenting, confirm cowsay is not already on Grill's PATH
  - Transition: That handles one program. What if a project needs a whole collection of tools?
-->

| Step | What Nix does |
|---|---|
| Resolve | <span style="color: #94e2d5">What store paths are required</span> |
| Check the store | <span style="color: #94e2d5">Do we already have them</span> |
| Check binary caches | <span style="color: #94e2d5">Does anyone else have them</span> |
| Build if needed | <span style="color: #94e2d5">Fine we'll do it</span> |
| Run | <span style="color: #94e2d5">Send it</span> |

```bash +exec
command -v cowsay || echo "Not on PATH"
/// printf '\n────────────────────────────────────────\n\n'
nix run nixpkgs#cowsay -- "Hello from Grill"
/// printf '\n────────────────────────────────────────\n\n'
command -v cowsay || echo "Still not on PATH"
```
<!-- end_slide -->
<!-- alignment: center -->
# nix develop
## A project's tools, without the setup instructions

<!--
speaker_note: |
  - Start in the presentation environment, not the web-development shell
  - The terminal block opens your normal interactive shell with its usual configuration
  - Inherits the presentation environment entered with just presentation-env
  - Connect all shell streams to /dev/tty so prompts are not captured by Presenterm
  - Shell exit status is ignored so Ctrl+C then Ctrl+D returns normally to the slide
  - First inspect command -v python and python --version; absence is fine too
  - The complete command sequence and browser URL are printed once when the terminal opens
  - Run nix develop manually, then python --version again and python app/server.py
  - Compare the Python path and version, then show the additional tools
  - Python 3.12 is selected in nix/dev-shell.nix; flake.lock pins the package set
  - Same store, cache, build process as nix run, but for a collection of tools
  - Run ruff check app/ and python app/server.py
  - Open http://grill:8000 on T480; the application is running from source on Grill
  - This is not a container: host files and inherited environment remain accessible
  - Ctrl+C stops the server; exit leaves nix develop; exit again returns to slides
  - Transition: Now we can work on the application. Let's turn it into something we can ship.
-->

| Ingredients | Examples |
|---|---|
| Languages | <span style="color: #94e2d5">Python, Node, Rust</span> |
| Runtime dependencies | <span style="color: #94e2d5">OpenSSL, SQLite, Python libraries</span> |
| Development tools | <span style="color: #94e2d5">Linters, formatters, debuggers</span> |
| Environment setup | <span style="color: #94e2d5">Variables and startup hooks</span> |

<!-- jump_to_middle -->

```bash +exec +acquire_terminal
# Inspect Python, then enter the project environment
/// printf '\033[>4;0m\033[>0u\033[3J\033[2J\033[H' >/dev/tty
/// printf 'python --version\nnix develop\npython --version\npython app/server.py\n\nhttp://grill:8000\n\n'
/// printf '\033[?25h' >/dev/tty
/// "${SHELL:-bash}" -i </dev/tty >/dev/tty 2>&1 || true
/// printf '\033[<u\033[?25l' >/dev/tty
```
<!-- end_slide -->
<!-- alignment: center -->
# nix build
## From source code to a runnable package

<!--
speaker_note: |
  - Source: changes → new hash → new store path; versions coexist in parallel
  - Build instructions: Python doesn't need compiling, but still needs packaging
  - Dependencies: sandboxed builds can only see declared inputs; version changes change the hash
  - Output: output/demo-web points to the immutable store output
  - Next: put this exact package into a container
-->

| Ingredient | What Nix does |
|---|---|
| Source | <span style="color: #94e2d5">Takes a snapshot of the application</span> |
| Build instructions | <span style="color: #94e2d5">Produces the package and its launcher</span> |
| Dependencies | <span style="color: #94e2d5">Connects the launcher to the required Python</span> |
| Output | <span style="color: #94e2d5">Stores the result immutably in /nix/store</span> |

<!-- jump_to_middle -->

```bash +exec +acquire_terminal
# Build and run the packaged application
/// printf '\033[>4;0m\033[>0u\033[3J\033[2J\033[H' >/dev/tty
/// printf 'nix build .#demo-web --out-link output/demo-web\n./output/demo-web/bin/demo-web\n\nhttp://grill:8000\n\n'
/// printf '\033[?25h' >/dev/tty
/// "${SHELL:-bash}" -i </dev/tty >/dev/tty 2>&1 || true
/// printf '\033[<u\033[?25l' >/dev/tty
```
<!-- end_slide -->
<!-- alignment: center -->
# Nix → container
## Same application. Different runtime.

<!--
speaker_note: |
  - Application: same application as in development; exact same package as the build output
  - Runtime closure: no base image; Nix injects the required store paths
  - Minimal image: app plus its runtime dependencies, not a full distribution, apt, or our development toolset; Python and its dependencies still take space
  - Dockerfile contrast: RUN apt-get update && apt-get install can resolve newer packages when that layer rebuilds against live repositories
  - Docker's cache can hide this drift; our locked Nix inputs pin the dependency definitions instead
  - Image configuration: starts the packaged app directly in /work, not a shell
  - Docker: handles runtime isolation and networking, using Grill's installed runtime; Nix builds the image contents
  - docker load imports the image; -p publishes port 8001, image metadata doesn't
  - Ctrl+C stops the container; --rm removes it, while the image stays loaded
  - Demo: PROD stays the same; hostname and working directory change
  - Open grill:8001 on T480
  - Next: describe the whole machine with NixOS
-->

| Part | Purpose |
|---|---|
| Application | <span style="color: #94e2d5">The exact package we just built</span> |
| Runtime dependencies | <span style="color: #94e2d5">Everything it needs to run—not the development tools</span> |
| Image configuration | <span style="color: #94e2d5">Startup command and working directory</span> |
| Docker | <span style="color: #94e2d5">Provides runtime isolation and networking</span> |

<!-- jump_to_middle -->
<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
### Describe the image

```bash +exec +acquire_terminal
# Image definition
/// nvim nix/docker-image.nix
```

<!-- pause -->
<!-- column: 1 -->
### Build and run it

```bash +exec +acquire_terminal
# Build, load and run the container
/// printf '\033[>4;0m\033[>0u\033[3J\033[2J\033[H' >/dev/tty
/// printf 'nix build .#dockerImage --out-link output/demo-image\ndocker load < output/demo-image && docker run --rm -it -p 8001:8000 nix-demo:latest\n\nhttp://grill:8001\n\n'
/// printf '\033[?25h' >/dev/tty
/// "${SHELL:-bash}" -i </dev/tty >/dev/tty 2>&1 || true
/// printf '\033[<u\033[?25l' >/dev/tty
```
<!-- reset_layout -->
<!-- end_slide -->
<!-- alignment: center -->
# Nix → NixOS VM
## Same application. Whole machine.

<!--
speaker_note: |
  - Application: reuse the same demo-web package, not another installation recipe.
  - Service: systemd starts the app at boot and manages its lifecycle.
  - System: users, networking, and firewall are part of the machine's declaration.
  - Shut down with sudo poweroff to return directly to the slides.
-->

| Part | Purpose |
|---|---|
| Application | <span style="color: #94e2d5">Reuses our packaged web app</span> |
| Service | <span style="color: #94e2d5">Starts automatically, managed by systemd</span> |
| System | <span style="color: #94e2d5">Declares users, networking, and firewall</span> |
| VM | <span style="color: #94e2d5">Boots the configuration as a complete machine</span> |

<!-- jump_to_middle -->
<!-- column_layout: [1, 1] -->
<!-- column: 0 -->
### Describe the machine

```bash +exec +acquire_terminal
# NixOS definition
/// nvim nixos/demo-vm/demo.nix
```

<!-- pause -->
<!-- column: 1 -->
### Boot the VM

```bash +exec +acquire_terminal
# Start the declared machine
/// clear >/dev/tty
/// just vm </dev/tty >/dev/tty 2>&1 || true
```
<!-- reset_layout -->
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
/// nvim '+/nginxVhosts' vendored/nix-dotfiles/modules/hosted-services/server.nix
/// nvim '+/hostedServices' vendored/nix-dotfiles/modules/services/attic/nas.nix
```
<!-- end_slide -->
<!-- jump_to_middle -->
<!-- alignment: center -->
# Let's see it!
