docker-build:
    nix build .#dockerImage
    docker load < result

docker:
    docker run --rm -it nix-demo:latest
