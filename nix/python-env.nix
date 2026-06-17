{ pkgs }:
[
  (pkgs.python3.withPackages (
    ps: with ps; [
      pandas
      requests
      python-dotenv
      openpyxl
      geopandas
    ]
  ))
]
