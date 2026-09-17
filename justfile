docker-build:
    nix build .#dockerImage --out-link output/demo-image \
    --extra-substituters https://attic.bepis.lol/fleet \
    --extra-trusted-public-keys 'fleet:TNxcGzYWUdJ40m2sDImRHOzX8DTbwYW/j84IILK2lYE='
    docker load < output/demo-image

docker:
    docker run --rm -it -p 8001:8000 nix-demo:latest

develop:
       nix develop \
       --extra-substituters https://attic.bepis.lol/fleet \
       --extra-trusted-public-keys 'fleet:TNxcGzYWUdJ40m2sDImRHOzX8DTbwYW/j84IILK2lYE='

# Enter the presentation environment explicitly, without direnv.
presentation-env:
    @nix develop .#presentation -c env SHELL="${SHELL:-bash}" "${SHELL:-bash}"

# Run this on the projector terminal. It publishes speaker notes locally.
present:
    presenterm slides.md --present --publish-speaker-notes -x

# Run this on the presenter terminal after `just present`.
notes:
    presenterm slides.md --listen-speaker-notes

# Boot the disposable NixOS VM, sharing only its editable configuration.
vm:
    SHARED_DIR="$PWD/nixos/demo-vm" nix run .#demo-vm
