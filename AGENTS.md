# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Overview

**polylabelr** is an R package wrapping Mapbox's C++ `polylabel` library. It exposes
`poi()`, which finds the approximate pole of inaccessibility (visual center) of a
polygon, and `poi_multi()` for lists of polygons.

## Commands

The environment is provided by devenv (loaded automatically by direnv), which supplies
R with `Rcpp`, `testthat`, `devtools`, `roxygen2`, `covr`, `spelling`, and `sf`.

```sh
Rscript -e 'devtools::load_all()'                      # compile + load for interactive work
Rscript -e 'devtools::test()'                          # run all tests
Rscript -e 'devtools::test(filter = "poi-sf")'         # run one test file (tests/testthat/test-poi-sf.R)
Rscript -e 'devtools::document()'                      # regenerate NAMESPACE and man/ from roxygen
Rscript -e 'Rcpp::compileAttributes()'                 # regenerate RcppExports after editing src/poi.cpp
Rscript -e 'devtools::check()'                         # full R CMD check
Rscript -e 'devtools::build_readme()'                  # README.md is generated; edit README.Rmd only
```

Generated files that must never be hand-edited: `NAMESPACE`, `man/*.Rd`,
`R/RcppExports.R`, `src/RcppExports.cpp`, `README.md`.

## Architecture

Everything funnels into a single C++ entry point. `src/poi.cpp` exports `poi_cpp(poly_list,
precision)`, which takes a **list of two-column numeric matrices** — the first matrix is the
outer ring, the rest are holes — and returns `c(x, y, dist)`. All R-level complexity is about
reducing arbitrary geometry inputs to that list of rings.

The R layer is S3 dispatch on `poi()`:

- `poi.default()` (`R/poi.R`) is the base case. It runs input through
  `grDevices::xy.coords()` and then splits the coordinates on `NA` values, which act as ring
  separators (matching `graphics::polypath()` semantics). Every other method eventually
  delegates here.
- `R/poi_sf.R` holds the simple-features methods. `poi.sf` → `poi.sfc` → per-geometry
  methods; `poi.POLYGON` `rbind`s its rings back into one `NA`-free matrix stack and hands
  off to `poi.default`. Points and lines return their first coordinate. Unsupported `sfg`
  types warn and return `NA`.
- Methods that must choose among several candidate points (`poi.MULTIPOLYGON`,
  `poi.GEOMETRYCOLLECTION`, `poi_multi.list`) all use `which_max_dist()` in `R/utils.R`,
  which picks the candidate with the largest `$dist` and tolerates `NA` entries from
  unsupported geometries.

`sf` is a soft dependency (Suggests); sf tests use `skip_if_not_installed("sf")`.

## Vendored Mapbox headers

`inst/include/mapbox/` contains vendored upstream headers (`polylabel.hpp`, `geometry.hpp`,
`variant.hpp`, and friends), reachable via `-I../inst/include/` in `src/Makevars`. These are
**locally patched** and should not be refreshed from upstream wholesale:

- `geometry.hpp` had GCC diagnostic pragmas removed because they tripped `R CMD check`.
- `variant.hpp` conditions `std::result_of` on the C++ standard version, falling back to
  `std::invoke_result` for C++20 where `std::result_of` was removed.

License attribution for each vendored file lives in `inst/COPYRIGHTS`; update it if the set
of vendored files changes.

## Conventions

- Semantic versioning; `NEWS.md` is maintained in release-please format.
- `tests/spelling.R` spell-checks documentation — add legitimate new terms to
  `inst/WORDLIST`.
- New tests generally assert both a numeric property of the result and that the point lies
  inside the polygon, using the `point_in_polygon()` helper in
  `tests/testthat/helper_point_in_polygon.R`.
