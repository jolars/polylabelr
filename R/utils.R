# Find the poi result with the largest $dist from a list of results
# some of which may be NA
which_max_dist <- function(pois) {
  which.max(
    vapply(
      pois,
      function(x) ifelse(is.list(x), x$dist, NA_real_),
      double(1)
    )
  )
}
