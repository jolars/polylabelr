#include <mapbox/geometry.hpp>
#include <mapbox/polylabel.hpp>
#include <Rcpp.h>

// [[Rcpp::export]]
Rcpp::NumericVector
poi_cpp(const Rcpp::List poly_list, const double precision = 1.0)
{
  auto n = poly_list.size();

  mapbox::geometry::polygon<double> poly;

  for (decltype(n) i = 0; i < n; ++i) {

    auto points = Rcpp::as<Rcpp::NumericMatrix>(poly_list(i));
    auto m = points.nrow();

    mapbox::geometry::linear_ring<double> ring;

    for (decltype(m) j = 0; j < m; ++j) {
      ring.emplace_back(points(j, 0), points(j, 1));
    }

    poly.push_back(std::move(ring));
  }

  mapbox::geometry::point<double> center;
  double best_dist;

  std::tie(center, best_dist) = mapbox::polylabel(poly, precision);

  Rcpp::NumericVector out{center.x, center.y, best_dist};

  return out;
}
