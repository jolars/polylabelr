#pragma once

#include <mapbox/geometry/polygon.hpp>
#include <mapbox/geometry/envelope.hpp>
#include <mapbox/geometry/point.hpp>
#include <mapbox/geometry/point_arithmetic.hpp>

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <limits>
#include <queue>
#include <vector>

namespace mapbox {

namespace detail {

// number of consecutive edges grouped under a single bounding box for block-skip
constexpr std::size_t blockSize = 32;

// get squared distance from a point to a segment
template <class T>
T getSegDistSq(T px, T py, T x, T y, T bx, T by) {
    auto dx = bx - x;
    auto dy = by - y;

    if (dx != 0 || dy != 0) {

        auto t = ((px - x) * dx + (py - y) * dy) / (dx * dx + dy * dy);

        if (t > 1) {
            x = bx;
            y = by;

        } else if (t > 0) {
            x += dx * t;
            y += dy * t;
        }
    }

    dx = px - x;
    dy = py - y;

    return dx * dx + dy * dy;
}

template <class T>
T getSegDistSq(const geometry::point<T>& p,
               const geometry::point<T>& a,
               const geometry::point<T>& b) {
    return getSegDistSq(p.x, p.y, a.x, a.y, b.x, b.y);
}

// the polygon rings flattened into a single contiguous coordinate buffer for
// cache-friendly, pointer-chase-free access in the hot distance loop, plus one
// precomputed bounding box per block of blockSize consecutive edges (over both
// endpoints of every edge in it) so the distance scan can skip whole blocks in
// O(1). The block layout mirrors coords/ringEnds and is re-derived in the scan,
// so only the bounding boxes need storing: a flat [minX, minY, maxX, maxY] run
// per block, sized upfront from the ring lengths.
template <class T>
struct PolygonIndex {
    std::vector<T> coords;             // x and y interleaved, rings back to back
    std::vector<std::size_t> ringEnds; // end offset into coords for each ring
    std::vector<T> blocks;             // minX, minY, maxX, maxY for each block

    explicit PolygonIndex(const geometry::polygon<T>& polygon) {
        std::size_t numPoints = 0;
        for (const auto& ring : polygon) numPoints += ring.size();

        coords.reserve(numPoints * 2);
        ringEnds.reserve(polygon.size());

        for (const auto& ring : polygon) {
            if (ring.empty()) continue;

            for (const auto& p : ring) {
                coords.push_back(p.x);
                coords.push_back(p.y);
            }
            ringEnds.push_back(coords.size());
        }

        buildBlocks();
    }

private:
    void buildBlocks() {
        const std::size_t stride = blockSize * 2;

        std::size_t numBlocks = 0;
        std::size_t ringStart = 0;
        for (const auto ringEnd : ringEnds) {
            numBlocks += (ringEnd - ringStart + stride - 1) / stride;
            ringStart = ringEnd;
        }

        blocks.resize(numBlocks * 4);

        std::size_t g = 0;
        ringStart = 0;
        for (const auto ringEnd : ringEnds) {
            for (std::size_t s = ringStart; s < ringEnd; s += stride, g += 4) {
                const std::size_t end = std::min(s + stride, ringEnd);
                const std::size_t prev = s == ringStart ? ringEnd - 2 : s - 2;

                T minX = coords[prev], minY = coords[prev + 1];
                T maxX = minX, maxY = minY;

                for (std::size_t i = s; i < end; i += 2) {
                    const T px = coords[i], py = coords[i + 1];
                    if (px < minX) minX = px; else if (px > maxX) maxX = px;
                    if (py < minY) minY = py; else if (py > maxY) maxY = py;
                }

                blocks[g] = minX; blocks[g + 1] = minY;
                blocks[g + 2] = maxX; blocks[g + 3] = maxY;
            }
            ringStart = ringEnd;
        }
    }
};

template <class T>
struct Cell;

template <class T>
T pointToPolygonDist(Cell<T>& cell,
                     const PolygonIndex<T>& index,
                     T maxD,
                     const Cell<T>* seed);

template <class T>
struct Cell {
    Cell(T x_, T y_, T h_, const PolygonIndex<T>& index, T maxD, const Cell<T>* seed)
        : x(x_),
          y(y_),
          h(h_)
        {
            d = pointToPolygonDist(*this, index, maxD, seed);
            max = d + h * std::sqrt(T(2));
        }

    T x; // cell center x
    T y; // cell center y
    T h; // half the cell size
    // nsx1..nsy2 hold the nearest segment found below, so child cells can seed
    // their scan with it (a child is almost always nearest to the same segment)
    T nsx1 = 0, nsy1 = 0, nsx2 = 0, nsy2 = 0;
    T d; // distance from cell center to polygon
    T max; // max distance to polygon within a cell
};

// signed distance from cell center to polygon outline (negative if outside),
// also recording the nearest segment on the cell. maxD is a distance threshold:
// if a partial result proves the center is no farther than maxD from the outline,
// the scan bails out early and returns maxD, since the caller has already
// determined such a cell can't beat the best. seed is the parent cell (or null);
// its nearest segment is checked first so boundary cells reach the early-out
// threshold without scanning the whole outline.
template <class T>
T pointToPolygonDist(Cell<T>& cell,
                     const PolygonIndex<T>& index,
                     T maxD,
                     const Cell<T>* seed) {
    const T x = cell.x;
    const T y = cell.y;
    bool inside = false;
    T minDistSq = std::numeric_limits<T>::infinity();
    const T thresholdSq = maxD > 0 ? maxD * maxD : T(-1);

    if (seed != nullptr) {
        cell.nsx1 = seed->nsx1; cell.nsy1 = seed->nsy1;
        cell.nsx2 = seed->nsx2; cell.nsy2 = seed->nsy2;
        minDistSq = getSegDistSq(x, y, cell.nsx1, cell.nsy1, cell.nsx2, cell.nsy2);
        if (minDistSq <= thresholdSq) return maxD;
    }

    const auto& coords = index.coords;
    const auto& blocks = index.blocks;

    const std::size_t stride = blockSize * 2;
    std::size_t g = 0; // running block index into blocks
    std::size_t ringStart = 0;

    for (const auto ringEnd : index.ringEnds) {

        // previous vertex (b), starting from the last point in the ring; carried
        // across blocks so each block's first edge connects to the prior vertex
        T bx = coords[ringEnd - 2];
        T by = coords[ringEnd - 1];

        for (std::size_t s = ringStart; s < ringEnd; s += stride, g += 4) {
            const std::size_t end = std::min(s + stride, ringEnd);
            const T bminX = blocks[g], bminY = blocks[g + 1];
            const T bmaxX = blocks[g + 2], bmaxY = blocks[g + 3];

            // lower bound on the distance from (x, y) to any edge in this block
            const T dx = x < bminX ? bminX - x : (x > bmaxX ? x - bmaxX : T(0));
            const T dy = y < bminY ? bminY - y : (y > bmaxY ? y - bmaxY : T(0));
            const bool skipDist = dx * dx + dy * dy >= minDistSq;

            // this block's edges can only flip ray-cast parity if its bbox straddles
            // y and extends right of x; else no edge crosses the rightward ray
            const bool skipCross = y < bminY || y >= bmaxY || x > bmaxX;

            if (skipDist && skipCross) {
                bx = coords[end - 2];
                by = coords[end - 1];
                continue;
            }

            for (std::size_t i = s; i < end; i += 2) {
                const T ax = coords[i];
                const T ay = coords[i + 1];

                if (!skipCross && ((ay > y) != (by > y)) &&
                    (x < (bx - ax) * (y - ay) / (by - ay) + ax)) inside = !inside;

                if (!skipDist) {
                    const T distSq = getSegDistSq(x, y, ax, ay, bx, by);
                    if (distSq < minDistSq) {
                        minDistSq = distSq;
                        cell.nsx1 = ax; cell.nsy1 = ay;
                        cell.nsx2 = bx; cell.nsy2 = by;

                        // the point is already close enough to the outline that this cell
                        // can't possibly contain a better label position, so stop scanning
                        if (minDistSq <= thresholdSq) return maxD;
                    }
                }

                bx = ax;
                by = ay;
            }
        }
        ringStart = ringEnd;
    }

    return minDistSq == 0 ? T(0) : (inside ? 1 : -1) * std::sqrt(minDistSq);
}

// signed distance from a point to polygon outline (negative if point is outside)
template <class T>
T pointToPolygonDist(const geometry::point<T>& point, const geometry::polygon<T>& polygon) {
    const PolygonIndex<T> index(polygon);
    Cell<T> cell(point.x, point.y, 0, index,
                 -std::numeric_limits<T>::infinity(), nullptr);
    return cell.d;
}

// get polygon centroid (over the outer ring)
template <class T>
Cell<T> getCentroidCell(const PolygonIndex<T>& index) {
    const T noThreshold = -std::numeric_limits<T>::infinity();
    const auto& coords = index.coords;

    T area = 0;
    T x = 0;
    T y = 0;
    const std::size_t end = index.ringEnds.at(0);

    for (std::size_t i = 0, j = end - 2; i < end; j = i, i += 2) {
        const T ax = coords[i];
        const T ay = coords[i + 1];
        const T bx = coords[j];
        const T by = coords[j + 1];
        const T f = ax * by - bx * ay;
        x += (ax + bx) * f;
        y += (ay + by) * f;
        area += f * 3;
    }

    if (area == 0) {
        return Cell<T>(coords[0], coords[1], 0, index, noThreshold, nullptr);
    }

    Cell<T> centroid(x / area, y / area, 0, index, noThreshold, nullptr);

    if (centroid.d < 0) {
        return Cell<T>(coords[0], coords[1], 0, index, noThreshold, nullptr);
    }

    return centroid;
}

} // namespace detail

template <class T>
struct PolylabelResult {
    geometry::point<T> center; // pole of inaccessibility
    T distance; // distance from the center to the polygon outline
};

template <class T>
PolylabelResult<T> polylabelWithDistance(const geometry::polygon<T>& polygon,
                                         T precision = 1,
                                         bool debug = false) {
    using namespace detail;

    static_cast<void>(debug);

    // find the bounding box of the outer ring
    const geometry::box<T> envelope = geometry::envelope(polygon.at(0));

    const T width = envelope.max.x - envelope.min.x;
    const T height = envelope.max.y - envelope.min.y;
    const T cellSize = std::min(width, height);

    // NOTE: upstream instead short-circuits whenever cellSize <= precision. We
    // only bail out on degenerate polygons, so that a polygon smaller than the
    // requested precision still gets a real answer instead of a corner of its
    // bounding box.
    if (cellSize == 0) {
        return { envelope.min, T(0) };
    }

    const PolygonIndex<T> index(polygon);

    // a priority queue of cells in order of their "potential" (max distance to polygon)
    auto compareMax = [] (const Cell<T>& a, const Cell<T>& b) {
        return a.max < b.max;
    };
    using Queue = std::priority_queue<Cell<T>, std::vector<Cell<T>>, decltype(compareMax)>;
    Queue cellQueue(compareMax);

    // take centroid as the first best guess
    auto bestCell = getCentroidCell(index);

    // second guess: bounding box centroid
    Cell<T> bboxCell(envelope.min.x + width / 2, envelope.min.y + height / 2, 0, index,
                     -std::numeric_limits<T>::infinity(), nullptr);
    if (bboxCell.d > bestCell.d) {
        bestCell = bboxCell;
    }

    auto potentiallyQueue = [&] (T x, T y, T h, const Cell<T>* seed) {
        // a cell is only useful if it can beat the best (d > bestCell.d) or is
        // worth subdividing (max = d + h*sqrt(2) > bestCell.d + precision). Both fail
        // once d <= threshold, so the distance scan can bail there early.
        const T threshold =
            bestCell.d - std::max(T(0), h * std::sqrt(T(2)) - precision);
        const Cell<T> cell(x, y, h, index, threshold, seed);

        if (cell.max > bestCell.d + precision) cellQueue.push(cell);

        // update the best cell if we found a better one
        if (cell.d > bestCell.d) bestCell = cell;
    };

    // cover polygon with initial cells
    T h = cellSize / 2;
    for (T x = envelope.min.x; x < envelope.max.x; x += cellSize) {
        for (T y = envelope.min.y; y < envelope.max.y; y += cellSize) {
            potentiallyQueue(x + h, y + h, h, nullptr);
        }
    }

    while (!cellQueue.empty()) {
        // pick the most promising cell from the queue
        const Cell<T> cell = cellQueue.top();
        cellQueue.pop();

        // do not drill down further if there's no chance of a better solution
        if (cell.max - bestCell.d <= precision) break;

        // split the cell into four cells, seeding each with the parent's nearest segment
        h = cell.h / 2;
        potentiallyQueue(cell.x - h, cell.y - h, h, &cell);
        potentiallyQueue(cell.x + h, cell.y - h, h, &cell);
        potentiallyQueue(cell.x - h, cell.y + h, h, &cell);
        potentiallyQueue(cell.x + h, cell.y + h, h, &cell);
    }

    return { { bestCell.x, bestCell.y }, bestCell.d };
}

template <class T>
geometry::point<T> polylabel(const geometry::polygon<T>& polygon,
                             T precision = 1,
                             bool debug = false) {
    return polylabelWithDistance(polygon, precision, debug).center;
}

} // namespace mapbox
