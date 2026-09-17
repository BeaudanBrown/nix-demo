{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "demo-web";
  version = "1.0";
  src = ../app;

  nativeBuildInputs = [ pkgs.makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/demo-web"
    cp server.py index.html "$out/share/demo-web/"
    cp -r static "$out/share/demo-web/static"

    makeWrapper ${pkgs.python312}/bin/python "$out/bin/demo-web" \
      --add-flags "$out/share/demo-web/server.py"

    runHook postInstall
  '';

  meta.mainProgram = "demo-web";
}
