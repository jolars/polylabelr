#include <Rcpp.h>
#include <mapbox/geometry.hpp>
#include <mapbox/polylabel.hpp>

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

  mapbox::geometry::point<double> center = mapbox::polylabel(poly, precision);

  // Find distance to polygon
  const mapbox::geometry::box<double> envelope =
    mapbox::geometry::envelope(poly.at(0));
  const mapbox::geometry::point<double> size{ envelope.max.x - envelope.min.x,
                                              envelope.max.y - envelope.min.y };
  const double cellSize = std::min(size.x, size.y);

  if (cellSize == 0) {
    return { envelope.min.x, envelope.min.y, 0.0 };
  } else {
    return { center.x,
             center.y,
             mapbox::detail::pointToPolygonDist(center, poly) };
  }
}
