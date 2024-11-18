#' Check If Point Is Inside Polygon
#'
#' @param x x coordinate of point
#' @param y y coordinate of point
#' @param polygon x and y coordinates of polygon
#'
#' @return
#' @keywords internal
#' @noRd
#'
#' @examples
point_in_polygon <- function(x, polygon) {
  point <- grDevices::xy.coords(x)
  polygon <- grDevices::xy.coords(polygon)

  n <- length(polygon$x)

  j <- n

  inside <- FALSE

  for (i in seq_len(n)) {
    if (((polygon$y[i] >= point$y) != (polygon$y[j] >= point$y)) &&
      (point$x <= (polygon$x[j] - polygon$x[i]) * (point$y - polygon$y[i]) /
        (polygon$y[j] - polygon$y[i]) + polygon$x[i])) {
      inside <- !inside
    }

    j <- i
  }

  inside
}
