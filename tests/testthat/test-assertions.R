context("assertions")

test_that("erroneous input throws", {
  x <- rbind(c(0, 1), c(1, 1), c(1, 0), c(0, 0))

  expect_error(poi(x, precision = c(1, 0.5)))
  expect_error(poi(x, precision = "f"))
})
