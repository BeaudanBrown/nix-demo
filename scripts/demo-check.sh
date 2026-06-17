#!/usr/bin/env bash
set -euo pipefail

section() {
  printf '\n== %s ==\n' "$1"
}

section "Machine"
uname -a

section "Nix"
nix --version

section "Core tools"
R --version | head -n 1
python --version

if command -v plink2 >/dev/null 2>&1; then
  plink2 --version | head -n 1
elif command -v plink >/dev/null 2>&1; then
  plink --version | head -n 1
else
  echo "PLINK not found" >&2
  exit 1
fi

bcftools --version | head -n 1
samtools --version | head -n 1
bedtools --version
vcftools --version 2>&1 | head -n 1
gdalinfo --version
quarto --version

section "R packages"
Rscript --vanilla - <<'RSCRIPT'
packages <- c(
  "targets",
  "tarchetypes",
  "data.table",
  "ggplot2",
  "dplyr",
  "readr",
  "reticulate",
  "terra",
  "clipr"
)

for (pkg in packages) {
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  cat(sprintf("%-12s %s\n", pkg, as.character(packageVersion(pkg))))
}
RSCRIPT

section "Python packages"
python - <<'PYTHON'
from importlib.metadata import version

packages = [
    "pandas",
    "requests",
    "python-dotenv",
    "geopandas",
]

for package in packages:
    print(f"{package:<14} {version(package)}")
PYTHON
