{
  pkgs,
  ...
}:

{
  packages = with pkgs; [
    bashInteractive
    autoconf
    go-task
    quartoMinimal
    pandoc
    llvmPackages.openmp
  ];

  languages = {
    r = {
      enable = true;

      package = (
        pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            Rcpp
            covr
            testthat
            spelling
            sf
            devtools
            usethis
            roxygen2
          ];
        }
      );
    };
  };
}
