{ pkgs }:

pkgs.mkShell {
  DEMO_MODE = "DEV";

  packages = with pkgs; [
    python312
    curl
    jq
    httpie
    ruff
  ];
}
