# Builds a site assessment report from live data for one parcel.
#
# Scope today: cover + sections 02 (Topography and landform) and 03 (Hydrology
# and drainage) on real data; the other sections render their honest "not
# available" state until their pipelines are wired in. No prose is generated here (that is deliberately
# deferred), so the section shows numbers and graphics without a narrative.
#
# The site is passed by environment variable, never written into the repo:
# this repository is public and real client addresses stay out of tracked
# files. Everything this script writes goes to output/, which is gitignored.
#
#   KED_SITE_ADDRESS="123 Example St" KED_SITE_CITY="Raleigh" KED_SITE_COUNTY="Wake" \
#   KED_CLIENT_NAME="Client Name" KED_STREET_SIDE=E \
#   Rscript R/report/build_site_report.R
#
# KED_STREET_SIDE is the parcel edge that faces the street (E, W, N or S). It
# orients the ground profile and the "Street" label. It comes from the
# practitioner (or a road lookup), not from the terrain.
#
# Optional: BUILDING_FOOTPRINTS_CACHE_DIR points at a directory that already
# holds the county footprint download (tens of MB the first time).

suppressPackageStartupMessages({library(sf); library(terra); library(jsonlite)})
for (f in c("R/acquisition/parcel.R", "R/acquisition/dem.R", "R/acquisition/building_footprint.R",
            "R/acquisition/watershed.R", "R/acquisition/flood.R", "R/acquisition/roads.R",
            "R/acquisition/local_cache.R", "R/illustrate/basemap_tiles.R", "R/illustrate/neighborhood_context.R",
            "R/illustrate/parcel_building_mask.R", "R/illustrate/parcel_topography.R",
            "R/illustrate/parcel_hydrology.R", "R/report/render_report.R")) source(f)

need <- function(var) {
  v <- Sys.getenv(var)
  if (!nzchar(v)) stop("Set ", var, " (see the header of R/report/build_site_report.R)")
  v
}
address <- need("KED_SITE_ADDRESS"); city <- need("KED_SITE_CITY"); county <- need("KED_SITE_COUNTY")
street_side <- toupper(Sys.getenv("KED_STREET_SIDE", "E"))
client_name <- Sys.getenv("KED_CLIENT_NAME", "Site Assessment")
out_dir <- "output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- acquire ---------------------------------------------------------------
message("Parcel ...")
parcel <- get_parcel(address, city, county)
if (nrow(parcel) > 1) stop("Address matched ", nrow(parcel), " parcels; disambiguate before building.")
message("DEM ...")
dem <- get_dem_clip(parcel, buffer_ft = 45)
message("Building footprints ...")
bldgs <- get_building_footprints(parcel, county = county, buffer_ft = 45)

# ---- section 02: topography ------------------------------------------------
message("Topography ...")
topo <- prep_parcel_topography(parcel, dem, bldgs, street_side = street_side)
stats <- topography_stats(topo)
svg_base    <- ggplot_to_svg(render_parcel_base_map_ked(topo), 7.6, 5.2)
svg_slope   <- ggplot_to_svg(render_parcel_slope_drainage_ked(topo), 7.6, 5.2)
svg_profile <- ggplot_to_svg(render_parcel_profile_ked(topo), 5.4, 3.1)
svg_rose    <- ggplot_to_svg(render_aspect_rose_ked(topo), 3.4, 3.4)

# ---- section 03: hydrology -------------------------------------------------
message("Hydrology ...")
nb_extent <- st_as_sfc(st_bbox(st_buffer(st_transform(parcel, 2264), 2500)), crs = 2264)
ws <- get_watershed(parcel)
hucs <- get_huc12_in_extent(nb_extent)
flood <- check_flood_zone(parcel)
hydro <- cached_layer(county, "raleigh_hydrology", function() fetch_raleigh_hydrology(nb_extent),
                      COR_HYDRO_URL, "City of Raleigh Hydrology feature service; vintage not stated by source",
                      extent = nb_extent)
roads <- cached_layer(county, "osm_roads", function() get_osm_roads(nb_extent),
                      "https://www.openstreetmap.org (Overpass API)", paste("OpenStreetMap as of", Sys.Date()),
                      extent = nb_extent)
bldgs_n <- get_building_footprints(parcel, county = county, buffer_ft = 2500)
dem_n <- get_dem_clip(parcel, buffer_ft = 2500)
nb <- prep_neighborhood_hydrology(parcel, dem_n, ws, hucs, hydro, roads, bldgs_n, flood)
hstats <- hydrology_stats(topo, ws, flood, hucs)
svg_flow <- ggplot_to_svg(render_parcel_flow_ked(topo), 7.6, 5.2)
svg_nbhd <- ggplot_to_svg(render_neighborhood_hydrology_ked(nb), 7.6, 7.2)

centroid <- st_coordinates(st_centroid(st_geometry(st_transform(parcel, 4326))))

payload <- list(
  client_name = client_name,
  address = paste0(parcel$siteadd, ", ", parcel$scity, ", NC"),
  coordinates = list(lat = centroid[2], lon = centroid[1]),
  assessment_date = format(Sys.Date()),
  practitioner = "Peter W Flint",
  county = parcel$cntyname,

  elevation_change_ft = stats$elevation_change_ft,
  max_slope_pct = unname(stats$max_slope_pct),
  mean_slope_pct = stats$mean_slope_pct,
  parcel_area_acres = stats$parcel_area_acres,
  slope_distribution = stats$slope_distribution,
  erosion_risk_pct = stats$erosion_risk_pct,
  contour_map_svg = svg_base,
  slope_drainage_map_svg = svg_slope,
  elevation_profile_svg = svg_profile,
  aspect_rose_svg = svg_rose,

  watershed_name = hstats$watershed_name,
  basin_name = hstats$basin_name,
  huc06_name = hstats$basin_name,
  huc12_name = hstats$watershed_name,
  flood_zone = hstats$flood_zone,
  flood_zone_subtype = hstats$flood_zone_subtype,
  drainage_direction = hstats$drainage_direction,
  parcel_flow_map_svg = svg_flow,
  hydro_map_svg = svg_nbhd,

  data_sources = list(
    list(name = "NC OneMap parcels (NC1Map_Parcels)", url = "https://www.nconemap.gov", accessed = format(Sys.Date())),
    list(name = "NC OneMap 3 ft bare-earth DEM (DEM03)", url = "https://www.nconemap.gov", accessed = format(Sys.Date())),
    list(name = "NC building footprints (NC Spatial Data Download, 2020-2022 inventory)", url = "https://sdd.nc.gov", accessed = format(Sys.Date())),
    list(name = "USGS Watershed Boundary Dataset (HUC06, HUC12)", url = "https://www.usgs.gov/national-hydrography/watershed-boundary-dataset", accessed = format(Sys.Date())),
    list(name = "FEMA National Flood Hazard Layer", url = "https://www.fema.gov/flood-maps/national-flood-hazard-layer", accessed = format(Sys.Date())),
    list(name = "City of Raleigh Hydrology", url = "https://services.arcgis.com/v400IkDOw1ad7Yad/arcgis/rest/services/Hydrology/FeatureServer", accessed = attr(hydro, "manifest")$downloaded %||% format(Sys.Date())),
    list(name = "OpenStreetMap contributors (roads)", url = "https://www.openstreetmap.org/copyright", accessed = attr(roads, "manifest")$downloaded %||% format(Sys.Date()))
  )
)

slug <- address_slug(payload$address)
payload_path <- file.path(out_dir, paste0(slug, "_payload.json"))
write_json(payload, payload_path, auto_unbox = TRUE, null = "null", pretty = TRUE, digits = NA)
saveRDS(list(parcel = parcel, dem = wrap(dem), bldgs = bldgs, stats = stats, ws = ws, flood = flood, hstats = hstats),
        file.path(out_dir, paste0(slug, "_data.rds")))
out <- render_site_assessment(payload, out_dir = out_dir)
message("Wrote ", payload_path, "\nWrote ", out)
