#include <mapbox/geometry.hpp>
#include <mapbox/polylabel.hpp>
#include <Rcpp.h>

// [[Rcpp::export]]
Rcpp::NumericVector
polyCentroid(const Rcpp::NumericMatrix points, const double precision = 1.0) {
  auto n = points.nrow();

  mapbox::geometry::polygon<double> poly;

  mapbox::geometry::linear_ring<double> ring;

  for (decltype(n) i = 0; i < n; ++i)
    ring.emplace_back(points(i, 0), points(i, 1));

  poly.push_back(std::move(ring));

  auto center = mapbox::polylabel(poly, precision);

  Rcpp::NumericVector out{center.x, center.y};

  return out;
}
