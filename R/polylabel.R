#' Title
#'
#' @param x a vector of x coordinates or a matrix or data.frame
#'   of x and y coordinates, a list of components x and y, or
#'   a time series (see [grDevices::xy.coords()] for details)
#' @param y a vector of y coordinates. Only needs to be provided if
#'   `x` is vector.
#' @param precision the precision to use when computing the center
#' @param ... arguments passed down to [grDevices::xy.coords()]
#'
#' @return A list with items `x` and `y`, representing the
#'   centroid of the polygon(s).
#'
#' @seealso [grDevices::xy.coords()], [graphics::polygon()]
#'
#' @export
#'
#' @examples
#' x <- rbind(c(2, 2),
#'            c(2.5, 2),
#'            c(2.5, 2.5),
#'            c(2, 2.5),
#'            c(NA, NA),
#'            c(0, 0),
#'            c(0, 1),
#'            c(1, 1),
#'            c(1, 0))
#' centroid <- centroid(x, precision = 0.5)
#' plot(x, type = 'n')
#' polygon(x)
#' points(centroid)
#'
centroid <- function(x, y = NULL, precision = 1.0, ...) {
  xy <- grDevices::xy.coords(x, y, ...)

  stopifnot(is.numeric(precision),
            length(precision) == 1)

  ends <- c(which(is.na(xy$x) | is.na(xy$y)), length(xy$x) + 1)
  n <- length(ends)

  points <- vector("list", n)
  i <- start <- 1

  for (end in ends) {
    if (end > start) {
      ind <- start:(end - 1)
      points[[i]] <- cbind(xy$x[ind], xy$y[ind])
      i <- i + 1
    }
    start <- end + 1
  }

  centroids <- vapply(points, polyCentroid, double(2), precision = precision)

  # squared distances to edges of polygon
  dist <- double(n)
  for (i in 1:n) {
    dist[i] <- min(colSums((t(points[[i]]) - centroids[, i])^2))
  }

  # return best distance
  grDevices::xy.coords(t(centroids[, which.max(dist)]), ...)
}
