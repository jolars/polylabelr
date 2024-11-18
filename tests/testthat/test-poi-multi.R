test_that("poi detection for multi-polygons", {
  p1a <- rbind(
    c(0, 0),
    c(1, 0),
    c(3, 2),
    c(2, 4),
    c(1, 4),
    c(0, 0)
  )
  p1b <- rbind(
    c(1, 1),
    c(1, 2),
    c(2, 2),
    c(1, 1)
  )
  p1 <- rbind(p1a, c(NA, NA), p1b)
  p2 <- rbind(
    c(3, 0),
    c(4, 0),
    c(4, 1),
    c(3, 1),
    c(3, 0),
    c(NA, NA),
    c(3.3, 0.8),
    c(3.8, 0.8),
    c(3.8, 0.3),
    c(3.3, 0.3),
    c(3.3, 0.3)
  )
  p3 <- rbind(
    c(3, 3),
    c(4, 2),
    c(4, 3),
    c(3, 3)
  )
  mpol <- list(p1, p2, p3)

  plot.new()
  plot.window(c(0, 4), c(0, 4), asp = 1)
  for (i in seq_along(mpol)) {
    polypath(mpol[[i]])
  }

  res <- poi_multi(mpol, precision = 1e-3)
  res

  points(res, pch = 19, col = "steelblue4")

  expect_true(point_in_polygon(res, p1a))
  expect_false(point_in_polygon(res, p1b))
})
