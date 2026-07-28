library(terra)
library(sf)
library(lwgeom)
library(httr)

# Neighborhood-scale main image. Settled 2026-07-28 at v8, after Peter
# rejected the DEM-raster/hillshade approach entirely (real relief was
# present but a raster-color treatment - even after fixing a real
# percentile-stretch bug - read as "busy" and was dominated by the DEM's
# known building-void-fill artifact once color was added). See
# docs/ILLUSTRATION_NOTES.md for the full iteration history.
#
# Caller must source R/illustrate/basemap_tiles.R first (for get_basemap_tiles()).
#
# City of Raleigh Hydrology is RALEIGH-SPECIFIC. A parcel outside city
# limits needs an equivalent county/municipal source, not assumed to exist
# yet - see docs/DATA_SOURCE_RESEARCH.md's Hydrography section.
COR_HYDRO_URL <- "https://services.arcgis.com/v400IkDOw1ad7Yad/arcgis/rest/services/Hydrology/FeatureServer/0/query"

fetch_raleigh_hydrology <- function(display_poly_2264) {
  bb <- st_bbox(display_poly_2264)
  resp <- GET(COR_HYDRO_URL, query = list(
    geometry = sprintf("%f,%f,%f,%f", bb["xmin"], bb["ymin"], bb["xmax"], bb["ymax"]),
    geometryType = "esriGeometryEnvelope", inSR = 2264, spatialRel = "esriSpatialRelIntersects",
    outFields = "FTYPE,NAME,RCH_CODE", returnGeometry = "true", outSR = 2264, f = "geojson"
  ))
  tmp <- tempfile(fileext = ".geojson")
  writeLines(content(resp, as = "text", encoding = "UTF-8"), tmp)
  hydro <- st_read(tmp, quiet = TRUE)
  st_crs(hydro) <- 2264
  hydro[hydro$FTYPE %in% c("STREAM/RIVER", "CANAL/DITCH"), ]
}

halo_text <- function(x, y, labels, cex = 0.65, col = "grey25", r = 12) {
  offsets <- expand.grid(dx = c(-r, 0, r), dy = c(-r, 0, r))
  for (i in seq_len(nrow(offsets))) {
    if (offsets$dx[i] == 0 && offsets$dy[i] == 0) next
    text(x + offsets$dx[i], y + offsets$dy[i], labels, cex = cex, col = "white", font = 1)
  }
  text(x, y, labels, cex = cex, col = col, font = 1)
}

#' @param parcel_sf Parcel geometry (any CRS)
#' @param dem A SpatRaster from get_dem_clip(parcel_sf, buffer_ft) - caller
#'   supplies this so the same DEM fetch can be reused for other purposes
#'   (respects the native-resolution rule already enforced in dem.R)
#' @param huc12 The parcel's HUC12 sf object from get_watershed()$huc12
#' @param buffer_ft Display extent radius. NOT validated as a general
#'   "standard extent" - chosen for this test parcel because it happens to
#'   sit ~1,039 ft from its HUC12 boundary. Untested against a parcel that
#'   sits well inside its watershed with no boundary to show. Open research
#'   question, deferred by Peter to a future session.
#' @param major_reach_min_ft Local hydrology reaches (grouped by RCH_CODE)
#'   below this total length are dropped as visual clutter. 1000ft chosen
#'   from a real gap in this test parcel's data (1932/1598ft major reaches
#'   vs 601/214ft minor ones) - not a validated general threshold.
render_neighborhood_context <- function(parcel_sf, dem, huc12, buffer_ft = 2500,
                                         major_reach_min_ft = 1000, contour_interval_ft = 2,
                                         index_interval_ft = 10) {
  parcel_2264 <- st_transform(parcel_sf, 2264)
  display_poly <- st_as_sfc(st_bbox(st_buffer(parcel_2264, buffer_ft)), crs = 2264)

  dem_agg <- aggregate(dem, fact = 8, fun = "mean", na.rm = TRUE)  # smooths past the building-void artifact before contouring
  rng <- range(values(dem_agg), na.rm = TRUE)
  levels <- seq(floor(rng[1] / contour_interval_ft) * contour_interval_ft,
                ceiling(rng[2] / contour_interval_ft) * contour_interval_ft,
                by = contour_interval_ft)
  contours_sf <- st_as_sf(as.contour(dem_agg, levels = levels))
  contours_sf$is_index <- (contours_sf$level %% index_interval_ft) == 0
  contours_clip <- suppressWarnings(st_intersection(contours_sf, display_poly))

  huc12_2264 <- st_transform(huc12, 2264)
  # true boundary line extracted BEFORE clipping - clipping the polygon and
  # taking the result's boundary was a real bug: it silently included the
  # display box's own edges as if they were real watershed edge
  huc12_boundary_line <- st_cast(st_boundary(huc12_2264), "MULTILINESTRING")
  huc12_clip_line <- suppressWarnings(st_intersection(huc12_boundary_line, display_poly))
  huc12_pieces <- st_cast(huc12_clip_line, "LINESTRING")
  huc12_longest <- huc12_pieces[which.max(st_length(huc12_pieces))]
  huc12_label_xy <- st_coordinates(st_line_sample(huc12_longest, sample = 0.35))
  huc12_name <- huc12$name

  hydro_features <- fetch_raleigh_hydrology(display_poly)
  hydro_features$len_ft <- as.numeric(st_length(hydro_features))
  by_rch <- aggregate(len_ft ~ RCH_CODE, data = st_drop_geometry(hydro_features), sum, na.rm = TRUE)
  major_codes <- by_rch$RCH_CODE[by_rch$len_ft > major_reach_min_ft & !is.na(by_rch$RCH_CODE) & trimws(by_rch$RCH_CODE) != ""]
  major_hydro <- hydro_features[hydro_features$RCH_CODE %in% major_codes, ]

  arrow_specs <- lapply(major_codes, function(code) {
    grp <- hydro_features[hydro_features$RCH_CODE == code & !is.na(hydro_features$RCH_CODE), ]
    longest_seg <- grp[which.max(grp$len_ft), ]
    coords <- st_coordinates(longest_seg)[, c("X", "Y")]
    ends <- rbind(coords[1, ], coords[nrow(coords), ])
    elev_at_ends <- extract(dem, ends)[, 1]
    downstream_i <- which.min(elev_at_ends)
    tangent <- ends[downstream_i, ] - coords[max(1, nrow(coords) - 3), ]
    tangent <- tangent / sqrt(sum(tangent^2))
    list(start = ends[downstream_i, ], end = ends[downstream_i, ] + tangent * 80)
  })

  basemap <- get_basemap_tiles(display_poly)

  list(
    plot = function() {
      plotRGB(basemap, axes = FALSE, mar = c(0, 0, 0, 0))
      plot(st_geometry(contours_clip[!contours_clip$is_index, ]), add = TRUE, col = "grey55", lwd = 0.25)
      plot(st_geometry(contours_clip[contours_clip$is_index, ]), add = TRUE, col = "grey20", lwd = 0.3)
      if (nrow(major_hydro) > 0) plot(st_geometry(major_hydro), add = TRUE, col = "#2a5a8c", lwd = 1.6)
      for (a in arrow_specs) {
        arrows(a$start[1], a$start[2], a$end[1], a$end[2], length = 0.08, angle = 25, col = "#2a5a8c", lwd = 1.5)
        halo_text(a$end[1], a$end[2] - 28, paste("flows to", huc12_name), cex = 0.58, col = "#2a5a8c", r = 8)
      }
      plot(st_geometry(huc12_clip_line), add = TRUE, col = "#9a6a2f", lwd = 1.6, lty = 2)
      halo_text(huc12_label_xy[1, "X"], huc12_label_xy[1, "Y"], paste(huc12_name, "watershed boundary"),
                cex = 0.7, col = "#9a6a2f", r = 10)
      plot(st_geometry(parcel_2264), add = TRUE, border = "red", lwd = 2.5, col = NA)
    },
    display_poly = display_poly,
    major_hydro_count = nrow(major_hydro)
  )
}
