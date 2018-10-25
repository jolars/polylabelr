context("poles of inaccessibility")

test_that("correct pois are computed for a variety of polygons", {
  # square
  x <- rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 1))
  p <- poi(x)
  expect_equal(c(p$x, p$y, p$dist), c(0.5, 0.5, 0.5))
  expect_true(point_in_polygon(p, x))

  # square with holes
  x <- c(0, 3, 3, 0, 0, 1, 2, 2, 1, 1)
  y <- c(0, 0, 3, 3, 0, 1, 1, 2, 2, 1)
  xy <- cbind(x, y)

  p <- poi(x, y, 0.001)
  expect_gte(p$dist, 0.58)
  expect_true(point_in_polygon(p, xy))

  # concave polygon
  x <- c(0, 4, 1, 6, 7, 7, 0, 0)
  y <- c(0, 0, 1, 2, 1, 3, 2, 0)

  p <- poi(x, y)

  expect_true(point_in_polygon(p, cbind(x, y)))
})
