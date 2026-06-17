# Custom R package demo: build a package directly in this project.
#
# This is the pattern for packages that are not yet in nixpkgs, project-local
# packages, or patched/pinned versions that should travel with the project.

{ pkgs }:

# pkgs.rPackages.buildRPackage rec {
#   pname = "praise";
#   version = "1.0.0";
#   src = pkgs.fetchurl {
#     url = "https://cran.r-project.org/src/contrib/${pname}_${version}.tar.gz";
#     hash = "sha256-XANedP0F36WbA6/g1fTFP780FE4XXpDFPQnGuu313r0=";
#   };
# }
let
  luna-base =
    with pkgs;
    stdenv.mkDerivation rec {
      pname = "luna-base";
      version = "1.0.0";
      enableParallelBuilding = true;

      src = fetchFromGitHub {
        owner = "remnrem";
        repo = "luna-base";
        rev = "refs/tags/v${version}";
        hash = "sha256-IWftBR1rU5yejdmngg6eFrLe/Pyfq/Qok/fq/cXyKX8=";
      };

      nativeBuildInputs = [
        autoPatchelfHook
      ];

      buildInputs = [
        fftw
      ];

      installPhase = ''
        runHook preInstall

        install -Dm755 luna "$out/bin/luna"
        install -Dm755 destrat "$out/bin/destrat"
        install -Dm755 behead "$out/bin/behead"
        install -Dm755 tocol "$out/bin/tocol"
        find . -name '*.h' -exec install -Dm644 {} $out/include/{} \;

        # These do not have .h extensions
        mkdir -p $out/include/stats
        find stats/Eigen/ -maxdepth 1 -type f -exec cp {} $out/include/stats/Eigen/ \;

        mkdir -p $out/lib
        cp *.a *.so *.o $out/lib/

        runHook postInstall
      '';
    };
in

pkgs.rPackages.buildRPackage {
  name = "lunar";
  src = pkgs.fetchFromGitHub {
    owner = "remnrem";
    repo = "luna";
    rev = "036fec226135f2f4c5712ac10fec81cd06e8faf5";
    sha256 = "sha256-jtXi1VV6k5YyUEcXJued8vs3BWu2gvdSXPaCglytbnw=";
  };
  propagatedBuildInputs =
    with pkgs;
    [
      fftw
      luna-base
      eigen
    ]
    ++ (with rPackages; [
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
    patch -p1 < ${./Makevars.patch}
  '';

  configurePhase = ''
    export FFTW=${pkgs.fftw}
    export LUNA_BASE=${luna-base}
  '';
}
