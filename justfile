docker-build:
    nix build .#dockerImage \
    --extra-substituters https://attic.bepis.lol/fleet \
    --extra-trusted-public-keys 'fleet:TNxcGzYWUdJ40m2sDImRHOzX8DTbwYW/j84IILK2lYE='
    docker load < result

docker:
    docker run --rm -it nix-demo:latest

develop:
       nix develop \
       --extra-substituters https://attic.bepis.lol/fleet \
       --extra-trusted-public-keys 'fleet:TNxcGzYWUdJ40m2sDImRHOzX8DTbwYW/j84IILK2lYE='
