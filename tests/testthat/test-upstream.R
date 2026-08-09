# Test cases borrowed from the upstream 'polylabel' test suite, so that we keep
# reproducing its results now that we maintain our own C++ port of it. See
# https://github.com/mapbox/polylabel/blob/master/test/test.js
#
# water.rds holds the two fixtures from upstream's test/fixtures/, each a list of
# two-column matrices of ring coordinates.

# stack rings into the NA-separated form that poi() expects
stack_rings <- function(rings) {
  Reduce(function(a, b) rbind(a, c(NA, NA), b), rings)
}

test_that("upstream fixtures give upstream results", {
  water <- readRDS(test_path("water.rds"))

  cases <- list(
    list(rings = water$water1, precision = 1, x = 3865.85009765625, y = 2124.87841796875, dist = 288.8493574779127),
    list(rings = water$water1, precision = 50, x = 3854.296875, y = 2123.828125, dist = 278.5795872381558),
    list(rings = water$water2, precision = 1, x = 3263.5, y = 3263.5, dist = 960.5)
  )

  for (case in cases) {
    p <- poi(stack_rings(case$rings), precision = case$precision)

    # the algorithm guarantees a global optimum within `precision`, so we can
    # only ever be that far off upstream's distance, however the arithmetic
    # happens to round on a given platform
    expect_lte(abs(p$dist - case$dist), case$precision)

    # the reported distance must be the real distance to the outline
    expect_equal(p$dist, dist_to_polygon(p, case$rings), tolerance = 1e-9)

    expect_true(point_in_polygon(p, case$rings[[1]]))
  }
})

test_that("upstream fixtures are matched exactly", {
  # kept off CRAN because a platform that contracts multiply-adds differently
  # can pick an equally valid neighboring cell, which the assertions above
  # tolerate and these do not
  skip_on_cran()

  water <- readRDS(test_path("water.rds"))

  expect_identical(
    poi(stack_rings(water$water1), precision = 1),
    list(x = 3865.85009765625, y = 2124.87841796875, dist = 288.8493574779127)
  )
  expect_identical(
    poi(stack_rings(water$water1), precision = 50),
    list(x = 3854.296875, y = 2123.828125, dist = 278.5795872381558)
  )
  expect_identical(
    poi(stack_rings(water$water2)),
    list(x = 3263.5, y = 3263.5, dist = 960.5)
  )
})

test_that("degenerate polygons work", {
  # zero height, so there is no cell to subdivide at all
  flat <- rbind(c(0, 0), c(1, 0), c(2, 0), c(0, 0))
  expect_equal(poi(flat), list(x = 0, y = 0, dist = 0))

  # zero area but nonzero extent, so the search runs and has to fall back from a
  # centroid it cannot compute
  spike <- rbind(c(0, 0), c(1, 0), c(1, 1), c(1, 0), c(0, 0))
  expect_equal(poi(spike), list(x = 0, y = 0, dist = 0))
})

test_that("the result is never outside the polygon", {
  # https://github.com/mapbox/polylabel/issues/97: when every candidate cell
  # center falls outside the polygon and the precision is too coarse to drill
  # any further, the search used to return its first guess, which for a shape
  # like a crescent is nowhere near the polygon
  angle <- seq(-2.6, 2.6, length.out = 61)
  crescent <- rbind(
    cbind(10 * cos(angle), 10 * sin(angle)),
    cbind(9.3 * cos(rev(angle)), 9.3 * sin(rev(angle)))
  )

  for (precision in c(50, 30, 20, 15, 10, 5, 1)) {
    p <- poi(crescent, precision = precision)
    expect_gte(p$dist, 0)
  }
})
