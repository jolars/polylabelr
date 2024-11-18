# POI methods for simple features objects

# sf and sfc objects delegate to the geometry
#' @export
poi.sf <- function(x, ...) {
  poi(sf::st_geometry(x), ...)
}

#' @export
poi.sfc <- function(x, ...) {
  lapply(x, poi, ...)
}

#' @export
poi.GEOMETRYCOLLECTION <- function(x, ...) {
  # Find the best point in each geometry. Some may not exist.
  pois <- lapply(x, function(s) suppressWarnings(poi(s, ...)))
  pois[[which_max_dist(pois)]]
}

#' @export
poi.MULTIPOLYGON <- function(x, ...) {
  # Find the best point in each polygon, then the best of those.
  # The constituent polygons are just lists so call poi.POLYGON directly.
  pois <- lapply(x, poi.POLYGON, ...)
  pois[[which_max_dist(pois)]]
}

#' @export
poi.POLYGON <- function(x, ...) {
  # POLYGON may have holes, bind together the pieces
  # poi.default figures it out...
  x <- do.call(rbind, x)
  poi(x, ...)
}

# Points and lines return a point. This is consistent with poi.default.
#' @export
poi.POINT <- function(x, ...) {
  poi(as.matrix(x), ...)
}

#' @export
poi.MULTIPOINT <- function(x, ...) {
  # Just pick the first point
  poi(as.matrix(x)[1, , drop = FALSE], ...)
}

#' @export
poi.LINESTRING <- function(x, ...) {
  # Just pick the first point
  poi(as.matrix(x)[1, , drop = FALSE], ...)
}

#' @export
poi.MULTILINESTRING <- function(x, ...) {
  # Just pick the first point
  poi(as.matrix(x[[1]])[1, , drop = FALSE], ...)
}

# Unsupported geometries get a warning and NA
#' @export
poi.sfg <- function(x, ...) {
  warning(
    "poi() does not support objects of type ",
    paste(class(x), collapse = ", "),
    "."
  )
  NA
}
