{ pkgs, rEnv, pythonEnv }:
[
  # General Unix/reproducibility tools
  pkgs.bashInteractive
  pkgs.coreutils
  pkgs.findutils
  pkgs.gnugrep
  pkgs.gnused
  pkgs.gawk
  pkgs.git
  pkgs.curl
  pkgs.wget
  pkgs.jq
  pkgs.tree
  pkgs.which
  pkgs.nix

  # Small data-wrangling tools
  pkgs.duckdb
  pkgs.sqlite
  pkgs.miller
  pkgs.csvkit

  # Genomics tools
  pkgs.plink-ng
  pkgs.bcftools
  pkgs.samtools
  pkgs.htslib
  pkgs.bedtools
  pkgs.vcftools
  pkgs.seqkit
  pkgs.fastqc
  pkgs.minimap2

  # Geospatial tools
  pkgs.gdal
  pkgs.proj
  pkgs.geos

  # Workflow / pipeline helpers
  pkgs.nextflow
  pkgs.snakefmt

  # Publication / reporting tools
  pkgs.quarto
  pkgs.pandoc
  pkgs.graphviz
  pkgs.texliveMinimal
] ++ rEnv ++ pythonEnv
