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

test_that("pois are correct for polygons with many vertices per ring", {
  # rings longer than the block size used internally to skip batches of edges
  theta <- head(seq(0, 2 * pi, length.out = 201), -1)

  # annulus: outer ring of radius 10, hole of radius 5
  outer <- cbind(10 * cos(theta), 10 * sin(theta))
  inner <- cbind(5 * cos(rev(theta)), 5 * sin(rev(theta)))

  p <- poi(rbind(outer, c(NA, NA), inner), precision = 0.001)

  # the widest gap is midway between the two circles
  expect_equal(sqrt(p$x^2 + p$y^2), 7.5, tolerance = 0.001)
  expect_equal(p$dist, 2.5, tolerance = 0.001)
  expect_equal(p$dist, dist_to_polygon(p, list(outer, inner)), tolerance = 1e-9)
  expect_true(point_in_polygon(p, outer))
  expect_false(point_in_polygon(p, inner))

  # star, whose blocks of consecutive edges have heavily overlapping bounding
  # boxes, so the scan cannot skip its way out of much
  radius <- rep(c(10, 4), length.out = 100)
  phi <- head(seq(0, 2 * pi, length.out = 101), -1)
  star <- cbind(radius * cos(phi), radius * sin(phi))

  p <- poi(star, precision = 0.001)

  expect_equal(p$dist, dist_to_polygon(p, list(star)), tolerance = 1e-9)
  expect_true(point_in_polygon(p, star))
})
