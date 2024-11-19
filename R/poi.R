#' Pole of Inaccessibility (Visual Center) of a Polygon
#'
#' This function computes and returns the approximate
#' pole of inaccessibility for a polygon using a quadtree-based algorithm
#' developed by the people from Mapbox.
#'
#' If there are any `NA` values in the input, they
#' will be treated as separators for multiple paths (rings) of the
#' polygon, mimicking the behavior of [graphics::polypath()].
#'
#' @param x a vector of x coordinates or a matrix or data.frame
#'   of x and y coordinates, a list of components x and y,
#'   a time series (see [grDevices::xy.coords()] for details),
#'   or a simple features object from package `sf`.
#' @param y a vector of y coordinates. Only needs to be provided if
#'   `x` is vector.
#' @param precision the precision to use when computing the center
#'
#' @return A list with items
#'   \item{`x`}{x coordinate of the center}
#'   \item{`y`}{y coordinate of the center}
#'   \item{`dist`}{distance to the enclosing polygon}
#'
#' @source Garcia-Castellanos & Lombardo, 2007. Poles of inaccessibility: A
#'   calculation algorithm for the remotest places on earth Scottish
#'   Geographical Journal, Volume 123, 3, 227-233.
#'   \doi{10.1080/14702540801897809}
#' @source <https://github.com/mapbox/polylabel>
#' @source <https://blog.mapbox.com/a-new-algorithm-for-finding-a-visual-center-of-a-polygon-7c77e6492fbc>
#'
#' @seealso [grDevices::xy.coords()], [graphics::polypath()]
#'
#' @export
#'
#' @examples
#  # helper for plotting paths/polygons
#' plot_path <- function(x, y, ...) {
#'   plot.new()
#'   plot.window(range(x, na.rm = TRUE), range(y, na.rm = TRUE))
#'   polypath(x, y, ...)
#' }
#'
#' x <- c(5, 10, 10, 5, 5, 6, 6, 7, 7, 6, 8, 8, 9, 9, 8)
#' y <- c(5, 5, 10, 10, 5, 6, 7, 7, 6, 6, 8, 9, 9, 8, 8)
#'
#' plot_path(x, y, col = "grey", border = NA)
#'
#' points(poi(x, y))
#'
#' \dontrun{
#' # Find visual centers for North Carolina counties
#' library(sf)
#' nc <- st_read(system.file("shape/nc.shp", package = "sf"))
#' locations <- do.call(rbind, poi(nc, precision = 0.01))
#' plot(st_geometry(nc))
#' points(locations)
#' }
poi <- function(x, y = NULL, precision = 1.0) {
  UseMethod("poi")
}

#' @export
poi.default <- function(x, y = NULL, precision = 1.0) {
  xy <- grDevices::xy.coords(x, y)

  stopifnot(
    is.numeric(precision),
    length(precision) == 1
  )

  ends <- c(which(is.na(xy$x) | is.na(xy$y)), length(xy$x) + 1)
  n <- length(ends)

  polys <- vector("list", n)
  i <- start <- 1

  for (end in ends) {
    if (end > start) {
      ind <- start:(end - 1)
      polys[[i]] <- cbind(xy$x[ind], xy$y[ind])
      i <- i + 1
    }
    start <- end + 1
  }

  center <- poi_cpp(polys, precision)

  list(x = center[1], y = center[2], dist = center[3])
}
