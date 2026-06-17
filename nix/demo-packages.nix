{ pkgs, rEnv, pythonEnv }:
[
  # General tools
  pkgs.bashInteractive
  pkgs.coreutils
  # Genomics tools
  pkgs.plink-ng
  pkgs.bcftools
  pkgs.samtools
  pkgs.htslib
  pkgs.bedtools
  pkgs.vcftools
  # Geospatial thing I don't understand
  pkgs.gdal
  # Publication tools
  pkgs.quarto
  pkgs.texliveMinimal
] ++ rEnv ++ pythonEnv
