# POI methods for simple features objects

# sf object delegates to the geometry
#' @export
poi.sf <- function(x, y = NULL, precision = 1.0) {
  poi(sf::st_geometry(x), y, precision)
}

#' @export
poi.sfc <- function(x, y = NULL, precision = 1.0) {
  lapply(x, poi, y=y, precision=precision)
}

#' @export
poi.MULTIPOLYGON <- function(x, y=NULL, precision = 1.0) {
  # Find the best point in each polygon, then the best of those
  pois <- lapply(x, poi.POLYGON, y=y, precision=precision)
  dists = vapply(pois, function(x) x$dist, double(1))
  pois[[which.max(dists)]]
}

#' @export
poi.POLYGON <- function(x, y=NULL, precision = 1.0) {
  # POLYGON may have holes, bind together the pieces
  x <- do.call(rbind, x)
  poi(x, precision=precision)
}

# MULTIPOLYGON and POLYGON are the only primitive geometries supported
#' @export
poi.sfg <- function(x, y=NULL, precision = 1.0) {
  stop('poi() does not support objects of type ', class(x), '.')
}
