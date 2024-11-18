#' Pole of Inaccessibility for Multi-Polygons
#'
#' This function is a convenience function to be used with
#' multi-polygons (lists of polygons). The function
#' simply calls [poi()] for each polygon in the list
#' and returns the point wit the maximum distance to
#' the boundaries of the enclosing polygon.
#'
#' @param polygons a list, each element containing
#'   entries `x` and `y`. See [poi()] for details
#'   about what these need to be.
#' @param ... arguments passed on to [poi()]
#'
#' @inherit poi return
#' @inheritDotParams poi
#'
#' @seealso [poi()]
#'
#' @export
#'
#' @examples
#' p1 <- rbind(
#'   c(0, 0),
#'   c(1, 0),
#'   c(3, 2),
#'   c(2, 4),
#'   c(1, 4),
#'   c(0, 0),
#'   c(NA, NA),
#'   c(1, 1),
#'   c(1, 2),
#'   c(2, 2),
#'   c(1, 1)
#' )
#' p2 <- rbind(
#'   c(3, 0),
#'   c(4, 0),
#'   c(4, 1),
#'   c(3, 1),
#'   c(3, 0),
#'   c(NA, NA),
#'   c(3.3, 0.8),
#'   c(3.8, 0.8),
#'   c(3.8, 0.3),
#'   c(3.3, 0.3),
#'   c(3.3, 0.3)
#' )
#' p3 <- rbind(
#'   c(3, 3),
#'   c(4, 2),
#'   c(4, 3),
#'   c(3, 3)
#' )
#' mpol <- list(p1, p2, p3)
#'
#' plot.new()
#' plot.window(c(0, 4), c(0, 4), asp = 1)
#' for (i in seq_along(mpol)) {
#'   polypath(mpol[[i]])
#' }
#'
#' res <- poi_multi(mpol, precision = 1e-5)
#' points(res, pch = 19, col = "steelblue4")
#'
#' res
poi_multi <- function(polygons, ...) {
  UseMethod("poi_multi")
}

#' @export
poi_multi.list <- function(polygons, ...) {
  pois <- lapply(polygons, poi, ...)
  pois[[which_max_dist(pois)]]
}
