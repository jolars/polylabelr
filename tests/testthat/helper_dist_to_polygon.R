#' Distance from a Point to a Polygon Outline
#'
#' @param x x and y coordinates of the point
#' @param rings a list of two-column matrices, one per ring
#'
#' @return The smallest distance from the point to any edge of any ring.
#' @keywords internal
#' @noRd
dist_to_polygon <- function(x, rings) {
  point <- grDevices::xy.coords(x)
  px <- point$x[1]
  py <- point$y[1]

  min_dist <- Inf

  for (ring in rings) {
    n <- nrow(ring)
    j <- n

    for (i in seq_len(n)) {
      ax <- ring[i, 1]
      ay <- ring[i, 2]
      dx <- ring[j, 1] - ax
      dy <- ring[j, 2] - ay

      if (dx != 0 || dy != 0) {
        t <- ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)

        if (t > 1) {
          ax <- ring[j, 1]
          ay <- ring[j, 2]
        } else if (t > 0) {
          ax <- ax + dx * t
          ay <- ay + dy * t
        }
      }

      min_dist <- min(min_dist, sqrt((px - ax)^2 + (py - ay)^2))

      j <- i
    }
  }

  min_dist
}
