# polylabelr 1.0.0

## Bug Fixes

- We now condition the use of `std::result_of` on the C++ standard version
  since it was removed in C++20, and then replace it by `std::invoke_result`.

# polylabelr 0.3.0

## Features

- add `poi_multi()` to handle multi-polygons ([0c6e15a](https://github.com/jolars/polylabelr/commit/0c6e15a921907ad2f3f670ee791166d8fe6051fa)), closes [#7](https://github.com/jolars/polylabelr/issues/7)

## Documentation

- adapt news file to work with release-please ([5179f43](https://github.com/jolars/polylabelr/commit/5179f43fd1f622325baa2dbcb2ee7cd83759aef9))

# polylabelr 0.2.0

## New features

- `poi()` supports simple features objects from the `sf` package (#2, thanks @kent37).

## Bug fixes

- The `CITATION` file now correctly displays the year of the package.

# polylabelr 0.1.0

- First release.
