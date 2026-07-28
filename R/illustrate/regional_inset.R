library(sf)
library(ggplot2)
library(ggrepel)
library(tigris)
library(httr)

# State-scale regional-orientation inset. Settled 2026-07-28 after six
# iterations (see docs/ILLUSTRATION_NOTES.md for the full history and the
# judgment calls behind each choice). Shows the parcel's Level III/IV
# ecoregion (clipped to the state boundary - the true unclipped EPA polygon
# spans multiple states and reads as an unrecognizable shape) and its HUC06
# river, against the state outline for scale.
#
# NOT cached: state boundary and NHD river geometry are fetched fresh per
# call. Peter's suggestion to cache the state-clipped ecoregion/HUC6 shapes
# as a reusable asset (avoiding repeated wide-extent fetches per parcel) is
# noted but not implemented - worth doing once this moves past prototyping.
#
# KNOWN LIMITATION, not solved: only the parcel's own HUC06 river is shown.
# A curated "other major rivers for context" set was attempted and dropped -
# the Catawba River (and likely others with major reservoir chains) returns
# only a fragment under a naive GNIS_NAME query, because long dammed
# stretches are classified as lake/reservoir features, not river reaches.
# See docs/DATA_SOURCE_RESEARCH.md's Hydrography section.
NHD_FLOWLINE_SMALLSCALE_URL <- "https://hydro.nationalmap.gov/arcgis/rest/services/nhd/MapServer/4/query"

#' @param parcel_sf Parcel geometry (any CRS)
#' @param river_name_override If NULL, guesses the HUC06's principal river
#'   as `paste(huc06_name, "River")` - this held for the Neuse test case but
#'   is a naming heuristic, not a guarantee (e.g. a "Pamlico" HUC06's river
#'   is arguably "Tar-Pamlico", not simply "Pamlico River"). Verify against
#'   real NHD GNIS names for any new basin before trusting the default.
render_regional_inset <- function(parcel_sf, eco, huc06, river_name_override = NULL,
                                   state_abbr = "NC") {
  nc <- states(cb = TRUE, resolution = "500k", progress_bar = FALSE)
  nc <- st_transform(nc[nc$STUSPS == state_abbr, ], 4326)

  l3_nc <- suppressWarnings(st_intersection(st_transform(eco$level3, 4326), nc))
  l4_nc <- suppressWarnings(st_intersection(st_transform(eco$level4, 4326), nc))
  parcel_pt <- st_transform(st_centroid(parcel_sf), 4326)

  river_name <- if (!is.null(river_name_override)) river_name_override else paste(huc06$name, "River")
  nc_bbox <- st_bbox(nc)
  resp <- GET(NHD_FLOWLINE_SMALLSCALE_URL, query = list(
    geometry = sprintf("%f,%f,%f,%f", nc_bbox["xmin"], nc_bbox["ymin"], nc_bbox["xmax"], nc_bbox["ymax"]),
    geometryType = "esriGeometryEnvelope", inSR = 4326, spatialRel = "esriSpatialRelIntersects",
    where = sprintf("GNIS_NAME = '%s'", river_name),
    outFields = "GNIS_NAME", returnGeometry = "true", f = "geojson"
  ))
  tmp <- tempfile(fileext = ".geojson")
  writeLines(content(resp, as = "text", encoding = "UTF-8"), tmp)
  river_sf <- st_read(tmp, quiet = TRUE)
  if (nrow(river_sf) == 0) {
    warning("No NHD flowline found for GNIS_NAME = '", river_name, "' - river name guess may be wrong for this basin.")
  } else {
    river_sf <- suppressWarnings(st_intersection(st_transform(river_sf, 4326), nc))
  }

  l3_lbl <- st_coordinates(st_point_on_surface(l3_nc))
  l4_lbl <- st_coordinates(st_point_on_surface(l4_nc))
  labels_df <- data.frame(
    x = c(l3_lbl[1, "X"], l4_lbl[1, "X"]),
    y = c(l3_lbl[1, "Y"], l4_lbl[1, "Y"]),
    label = c(toupper(eco$level3$US_L3NAME), eco$level4$US_L4NAME),
    color = c("grey40", "grey15")
  )

  p <- ggplot() +
    geom_sf(data = nc, fill = "white", color = "grey85", linewidth = 0.5) +
    geom_sf(data = l3_nc, fill = "grey95", color = "grey70", linewidth = 0.35) +
    geom_sf(data = l4_nc, fill = "grey87", color = "grey40", linewidth = 0.55)

  if (nrow(river_sf) > 0) {
    p <- p + geom_sf(data = river_sf, color = "#3d7ab5", linewidth = 0.7)
  }

  p +
    geom_sf(data = parcel_pt, size = 2.4, color = "black") +
    geom_label_repel(data = labels_df, aes(x = x, y = y, label = label, color = color),
                      fill = alpha("white", 0.85), label.size = NA, size = 3.2, family = "sans",
                      segment.color = "grey50", segment.size = 0.3, min.segment.length = 0.1,
                      seed = 42) +
    scale_color_identity() +
    coord_sf(datum = NA, xlim = nc_bbox[c("xmin", "xmax")], ylim = nc_bbox[c("ymin", "ymax")]) +
    theme_void() +
    theme(plot.background = element_rect(fill = "white", color = NA))
}
