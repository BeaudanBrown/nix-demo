# Chaning something about a build, i.e. bumping a version

final: prev: {
  rPackages = prev.rPackages.override {
    overrides = {
      clipr = prev.rPackages.clipr.overrideAttrs (old: rec {
        version = "0.8.1";
        src = prev.fetchurl {
          url = "https://cran.r-project.org/src/contrib/clipr_${version}.tar.gz";
          hash = "sha256-Buh6nDh9oz9M6N6R0DfAkLkkaJtf9IfTwMdQa9TD8bY=";
        };
      });
    };
  };
}
