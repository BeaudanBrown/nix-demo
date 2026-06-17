{
  pkgs,
  moonlightRev ? "b36aadbbb8c278c40516efab8933689399d48deb",
  moonlightHash ? "sha256-DkCnS7cOu2GHHZaiuda+AWbwp/813mmL9G8v5ihiFpQ=",
  lunaRev ? "036fec226135f2f4c5712ac10fec81cd06e8faf5",
  lunaHash ? "sha256-jtXi1VV6k5YyUEcXJued8vs3BWu2gvdSXPaCglytbnw=",
  lunaBaseVersion ? "1.0.0",
  lunaBaseHash ? "sha256-IWftBR1rU5yejdmngg6eFrLe/Pyfq/Qok/fq/cXyKX8=",
}:
let
  luna-base = with pkgs; stdenv.mkDerivation rec {
    pname = "luna-base";
    version = lunaBaseVersion;
    enableParallelBuilding = true;

    src = fetchFromGitHub {
      owner = "remnrem";
      repo = "luna-base";
      rev = "refs/tags/v${version}";
      hash = lunaBaseHash;
    };

    nativeBuildInputs = [ autoPatchelfHook ];

    buildInputs = [
      fftw
      lightgbm
    ];

    makeFlags = [
      "FFTW=${fftw}"
      "LGBM=1"
      "LGBM_PATH=${lightgbm}"
    ];

    installPhase = ''
      runHook preInstall

      for exe in luna destrat regional behead dmerge tocol fixrows cgi-mapper simassoc; do
        install -Dm755 "$exe" "$out/bin/$exe"
      done
      find . -name '*.h' -exec install -Dm644 {} $out/include/{} \;

      # These do not have .h extensions.
      mkdir -p $out/include/stats
      find stats/Eigen/ -maxdepth 1 -type f -exec cp {} $out/include/stats/Eigen/ \;

      mkdir -p $out/lib
      cp *.a *.so *.o $out/lib/

      runHook postInstall
    '';

    meta = {
      description = "Library supporting large-scale objective studies of sleep, with LightGBM support";
      homepage = "https://zzz.bwh.harvard.edu/luna";
      license = lib.licenses.gpl3Plus;
      platforms = lib.platforms.linux;
      mainProgram = "luna";
    };
  };

  makevarsPatch = pkgs.writeText "lunar-Makevars.patch" ''
    diff --git a/src/Makevars b/src/Makevars
    index 5092f7d..6495039 100644
    --- a/src/Makevars
    +++ b/src/Makevars
    @@ -1,8 +1,4 @@
     CXX_STD = CXX17

    -PKG_CPPFLAGS=-I./include/ -I$(FFTW)/include/ ''${EXTRA_PKG_CPPFLAGS}
    -PKG_LIBS=include/libluna.a -L$(FFTW)/lib/ -lfftw3 ''${EXTRA_PKG_LIBS}
    -
    -# redundant
    -#PKG_CPPFLAGS=-I./include/ `pkg-config --cflags fftw3`
    -#PKG_LIBS=include/libluna.a `pkg-config --libs fftw3`
    +PKG_CPPFLAGS = -I''${LUNA_BASE}/include/ -I''${FFTW}/include/ ''${EXTRA_PKG_CPPFLAGS}
    +PKG_LIBS = ''${LUNA_BASE}/lib/libluna.a -L''${FFTW}/lib/ -lfftw3 ''${EXTRA_PKG_LIBS}
  '';

  lunar = pkgs.rPackages.buildRPackage {
    name = "lunar";

    src = pkgs.fetchFromGitHub {
      owner = "remnrem";
      repo = "luna";
      rev = lunaRev;
      hash = lunaHash;
    };

    propagatedBuildInputs = with pkgs; [
      fftw
      luna-base
      eigen
    ] ++ (with rPackages; [
      data_table
      git2r
      plotrix
      geosphere
      shiny
      DT
      shinyFiles
      xtable
      shinydashboard
      lubridate
      wkb
      digest
      aws_s3
      tidyverse
    ]);

    nativeBuildInputs = with pkgs; [
      stdenv.cc.cc
      patch
    ];

    patchPhase = ''
      patch -p1 < ${makevarsPatch}
      printf '%s\n' '#!/bin/sh' 'exit 0' > configure
      chmod +x configure
    '';

    configurePhase = ''
      export FFTW=${pkgs.fftw}
      export LUNA_BASE=${luna-base}
      export LGBM=1
      export LGBM_PATH=${pkgs.lightgbm}
      export EXTRA_PKG_CPPFLAGS="-DHAS_LGBM -I${pkgs.lightgbm}/include"
      export EXTRA_PKG_LIBS="-L${pkgs.lightgbm}/lib -Wl,-rpath,${pkgs.lightgbm}/lib -l_lightgbm"
    '';
  };

  moonlight-src = pkgs.fetchFromGitHub {
    owner = "remnrem";
    repo = "moonlight";
    rev = moonlightRev;
    hash = moonlightHash;
  };

  moonlightR = pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      lunar
      shiny
      shinybusy
      DT
      curl
      shinyFiles
      fs
      shinyjs
      shinythemes
      data_table
      plotrix
      geosphere
      lubridate
      wkb
      aws_s3
    ];
  };
in
pkgs.writeShellApplication {
  name = "moonlight";
  runtimeInputs = [
    moonlightR
    luna-base
  ];
  text = ''
    export MOONLIGHT_SERVER_MODE="''${MOONLIGHT_SERVER_MODE:-0}"
    exec R -q -e "shiny::runApp('${moonlight-src}', host = '0.0.0.0', port = 3838)"
  '';
}
