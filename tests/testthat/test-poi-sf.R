test_that("poi works with simple features", {
  skip_if_not_installed("sf")
  library(sf)

  # Create some test objects
  p <- st_point(c(1, 2))
  pts <- rbind(
    c(3.2, 4),
    c(3, 4.6),
    c(3.8, 4.4),
    c(3.5, 3.8),
    c(3.4, 3.6),
    c(3.9, 4.5)
  )
  mp <- st_multipoint(pts)
  ## MULTIPOINT ((3.2 4), (3 4.6), (3.8 4.4), (3.5 3.8), (3.4 3.6), (3.9 4.5))

  s1 <- rbind(c(0, 3), c(0, 4), c(1, 5), c(2, 5))
  ls <- st_linestring(s1)
  ## LINESTRING (0 3, 0 4, 1 5, 2 5)

  s2 <- rbind(c(0.2, 3), c(0.2, 4), c(1, 4.8), c(2, 4.8))
  s3 <- rbind(c(0, 4.4), c(0.6, 5))
  mls <- st_multilinestring(list(s1, s2, s3))
  ## MULTILINESTRING ((0 3, 0 4, 1 5, 2 5), (0.2 3, 0.2 4, 1 4.8, 2 4.8), (0 4.4, 0.6 5))

  p1 <- rbind(c(0, 0), c(1, 0), c(3, 2), c(2, 4), c(1, 4), c(0, 0))
  p2 <- rbind(c(1, 1), c(1, 2), c(2, 2), c(1, 1))
  pol <- st_polygon(list(p1, p2))
  # POLYGON ((0 0, 1 0, 3 2, 2 4, 1 4, 0 0), (1 1, 1 2, 2 2, 1 1))

  p3 <- rbind(c(3, 0), c(4, 0), c(4, 1), c(3, 1), c(3, 0))
  p4 <- rbind(c(3.3, 0.3), c(3.8, 0.3), c(3.8, 0.8), c(3.3, 0.8), c(3.3, 0.3))[
    5:1,
  ]
  p5 <- rbind(c(3, 3), c(4, 2), c(4, 3), c(3, 3))
  mpol <- st_multipolygon(list(list(p1, p2), list(p3, p4), list(p5)))
  ## MULTIPOLYGON (((0 0, 1 0, 3 2, 2 4, 1 4, 0 0), (1 1, 1 2, 2 2, 1 1)), ((3 0, 4 0, 4 1, 3 1, 3 0), (3.3 0.3, 3.3 0.8, 3.8 0.8, 3.8 0.3, 3.3 0.3)), ((3 3, 4 2, 4 3, 3 3)))

  gc <- st_geometrycollection(list(mp, mpol, ls))

  # These return the first point in the geometry
  expect_equal(poi(p), list(x = 1, y = 2, dist = 0))
  expect_equal(poi(mp), list(x = 3.2, y = 4, dist = 0))
  expect_equal(poi(ls), list(x = 0, y = 3, dist = 0))
  expect_equal(poi(mls), list(x = 0, y = 3, dist = 0))

  # They ignore precision
  expect_equal(poi(p, precision = 0.1), list(x = 1, y = 2, dist = 0))
  expect_equal(poi(mp, precision = 0.1), list(x = 3.2, y = 4, dist = 0))
  expect_equal(poi(ls, precision = 0.1), list(x = 0, y = 3, dist = 0))
  expect_equal(poi(mls, precision = 0.1), list(x = 0, y = 3, dist = 0))

  lo_res_poi <- list(x = 1.875, y = 2.625, dist = 0.625)
  hi_res_poi <- list(x = 1.59375, y = 2.90625, dist = 0.84129)

  expect_equal(poi(pol), lo_res_poi)
  expect_equal(poi(pol, precision = 0.1), hi_res_poi, tolerance = 0.00001)
  expect_equal(poi(mpol), lo_res_poi)
  expect_equal(poi(mpol, precision = 0.1), hi_res_poi, tolerance = 0.00001)
  expect_equal(poi(gc), lo_res_poi)
  expect_equal(poi(gc, precision = 0.1), hi_res_poi, tolerance = 0.00001)
  expect_silent(poi(gc))
})

test_that("poi works with sf objects", {
  skip_if_not_installed("sf")
  library(sf)

  p1 <- rbind(c(0, 0), c(1, 0), c(3, 2), c(2, 4), c(1, 4), c(0, 0))
  p2 <- rbind(c(1, 1), c(1, 2), c(2, 2), c(1, 1))
  pol <- st_polygon(list(p1, p2))

  # Test with sf object (data frame with geometry column)
  sf_obj <- st_sf(id = 1:2, geometry = st_sfc(pol, pol))
  result <- poi(sf_obj)

  expect_type(result, "list")
  expect_length(result, 2)
  expect_equal(result[[1]], result[[2]])
  expect_equal(result[[1]], list(x = 1.875, y = 2.625, dist = 0.625))
})

test_that("poi works with sfc objects", {
  skip_if_not_installed("sf")
  library(sf)

  p1 <- rbind(c(0, 0), c(1, 0), c(3, 2), c(2, 4), c(1, 4), c(0, 0))
  p2 <- rbind(c(1, 1), c(1, 2), c(2, 2), c(1, 1))
  pol <- st_polygon(list(p1, p2))

  # Test with sfc object (geometry list-column)
  sfc_obj <- st_sfc(pol, pol)
  result <- poi(sfc_obj)

  expect_type(result, "list")
  expect_length(result, 2)
  expect_equal(result[[1]], result[[2]])
  expect_equal(result[[1]], list(x = 1.875, y = 2.625, dist = 0.625))
})

test_that("poi warns on unsupported sfg geometry types", {
  skip_if_not_installed("sf")
  library(sf)

  # Create an unsupported geometry type
  unsupported <- structure(c(1, 2), class = c("XY", "UNSUPPORTED", "sfg"))

  expect_warning(
    result <- poi(unsupported),
    "poi\\(\\) does not support objects of type XY, UNSUPPORTED, sfg"
  )
  expect_true(is.na(result))
})
