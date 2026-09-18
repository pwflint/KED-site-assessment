# Builds a site assessment report from live data for one parcel.
#
# Scope today: cover + sections 01 (Regional context), 02 (Topography and
# landform), 03 (Hydrology and drainage), 04 (Climate and wind), 05 (Soils
# and infiltration) and 06 (Microclimate) on real data, and 07 (Vulnerabilities
# and opportunities) from the practitioner's notes file when one exists; the
# other sections render their honest "not available" state. No prose is
# generated here (that is deliberately deferred): section 07's words are the
# practitioner's own, read from the notes file.
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
# Caches (all under data/, gitignored; KED_DATA_DIR moves them): the county
# building footprints (69 MB the first time), the PRISM normal grids (134 MB
# once, shared by every parcel), the GHCND station list and daily wind
# records, and the county road/hydrology/soil layers. A rebuild with warm
# caches makes live calls only for the parcel, DEM, flood, watershed,
# ecoregion and SSURGO tabular queries.

suppressPackageStartupMessages({library(sf); library(terra); library(jsonlite)})
for (f in c("R/acquisition/parcel.R", "R/acquisition/dem.R", "R/acquisition/building_footprint.R",
            "R/acquisition/watershed.R", "R/acquisition/flood.R", "R/acquisition/roads.R",
            "R/acquisition/ecoregion.R", "R/acquisition/hydrography.R", "R/acquisition/boundaries.R",
            "R/acquisition/local_cache.R", "R/acquisition/climate.R", "R/acquisition/wind.R",
            "R/acquisition/soil.R", "R/illustrate/basemap_tiles.R", "R/illustrate/neighborhood_context.R",
            "R/illustrate/parcel_building_mask.R", "R/illustrate/parcel_topography.R",
            "R/illustrate/parcel_hydrology.R", "R/illustrate/regional_orientation.R",
            "R/illustrate/climate_wind.R", "R/illustrate/parcel_soils.R",
            "R/acquisition/canopy.R", "R/illustrate/parcel_microclimate.R", "R/illustrate/site_synthesis.R",
            "R/report/render_report.R")) source(f)

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

# ---- section 01: regional context ------------------------------------------
message("Regional context ...")
eco <- get_ecoregion(parcel)
state_abbr <- "NC"
state <- cached_layer(state_abbr, "state_outline", function() get_state_outline(state_abbr),
                      "US Census cartographic boundary files (states, 1:500k) via tigris", "Census CB, tigris default year (2021)")
river_name <- paste(ws$huc06$name, "River")   # heuristic, see R/acquisition/hydrography.R
river <- cached_layer(state_abbr, paste0("river_", tolower(gsub("[^A-Za-z]", "", ws$huc06$name))),
                      function() get_principal_river(river_name, state),
                      NHD_FLOWLINE_SMALLSCALE_URL, "USGS NHD Flowline - Small Scale, as served")
reg <- prep_regional(parcel, eco, state, river, ws$huc06$name)
orient <- prep_neighborhood_orientation(parcel, roads, get_building_footprints(parcel, county = county, buffer_ft = 900),
                                        tools::toTitleCase(tolower(parcel$siteadd)))
rstats <- regional_stats(eco, ws)
svg_regional <- ggplot_to_svg(render_regional_inset_ked(reg), 7.6, 3.8)
svg_orient   <- ggplot_to_svg(render_neighborhood_orientation_ked(orient), 7.6, 6.2)

# ---- section 04: climate and wind ------------------------------------------
message("Climate and wind ...")
normals <- get_seasonal_normals(parcel)          # PRISM grids, cached under data/prism
wind <- get_wind_data(parcel)                    # nearest USW station, ten complete years, cached
cl <- prep_climate(normals, wind)
cstats <- climate_stats(cl)
svg_climate <- ggplot_to_svg(render_climate_chart_ked(cl), 7.6, 5.6)
svg_wind    <- ggplot_to_svg(render_wind_rose_ked(cl), 7.6, 7.0)

# ---- section 05: soils -----------------------------------------------------
message("Soils ...")
soil_polys <- cached_layer(county, "ssurgo_mupolygon", function() get_soil_polygons(nb_extent),
                           "https://sdmdataaccess.nrcs.usda.gov (mupolygon)", "SSURGO as served by Soil Data Access",
                           extent = nb_extent)
soil_ag <- get_mapunit_aggregates(unique(soil_polys$mukey))
soil_comps <- get_mapunit_components(unique(soil_polys$mukey))
own_mukeys <- unique(get_soil_polygons(parcel)$mukey)
soil_hz <- get_component_horizons(soil_comps$cokey[soil_comps$mukey %in% own_mukeys])
so <- prep_soils(parcel, soil_polys, soil_ag, soil_comps, soil_hz, roads, hydro)
sstats <- soils_stats(so)
svg_soil_map     <- ggplot_to_svg(render_soil_map_ked(so), 7.6, 7.2)
svg_soil_profile <- ggplot_to_svg(render_soil_profile_ked(so), 7.6, 5.2)

centroid <- st_coordinates(st_centroid(st_geometry(st_transform(parcel, 4326))))

# ---- section 07: the practitioner's notes ----------------------------------
# Site-specific judgment (narrative, vulnerabilities, opportunities, the
# zones to draw) lives in a gitignored notes file, never in this script:
# KED_PRACTITIONER_NOTES, or output/{slug}_notes.json when that exists.
slug <- address_slug(paste0(parcel$siteadd, ", ", parcel$scity, ", NC"))
notes_path <- Sys.getenv("KED_PRACTITIONER_NOTES", file.path(out_dir, paste0(slug, "_notes.json")))
notes <- if (file.exists(notes_path)) { message("Practitioner notes: ", notes_path); fromJSON(notes_path, simplifyVector = FALSE) } else NULL

# ---- section 06: microclimate ----------------------------------------------
message("Microclimate ...")
mc <- prep_microclimate(topo, lat_deg = centroid[2])
mstats <- microclimate_stats(mc, topo)
canopy_radius_ft <- 300
canopy_nearby <- get_canopy_extent(parcel, buffer_ft = canopy_radius_ft)   # 30 m NLCD, coarse; context only
canopy_nearby_pct <- if (inherits(canopy_nearby$canopy_pct_raster, "SpatRaster"))
  round(mean(values(canopy_nearby$canopy_pct_raster), na.rm = TRUE)) else NULL
mc_bb <- st_bbox(st_buffer(topo$parcel, 20)); mc_asp <- as.numeric((mc_bb["xmax"] - mc_bb["xmin"]) / (mc_bb["ymax"] - mc_bb["ymin"]))
svg_heat  <- ggplot_to_svg(render_heat_map_ked(mc), 7.6, 7.6 / mc_asp + 0.3)
svg_shade <- ggplot_to_svg(render_shade_pair_ked(mc), 7.6, 3.8 / mc_asp + 0.7)

# ---- section 07: synthesis graphics ----------------------------------------
message("Synthesis ...")
svg_sun <- ggplot_to_svg(render_sun_path_ked(topo, centroid[2]), 7.6, 7.4)
# The drafted opportunities plan (draft_zones/render_site_plan_ked) was rejected at
# review 2026-09-19 and is not built; see docs/ILLUSTRATION_NOTES.md, section 07.

payload <- list(
  client_name = client_name,
  address = paste0(parcel$siteadd, ", ", parcel$scity, ", NC"),
  coordinates = list(lat = centroid[2], lon = centroid[1]),
  assessment_date = format(Sys.Date()),
  practitioner = "Peter W Flint",
  county = parcel$cntyname,

  ecoregion_l3 = rstats$ecoregion_l3,
  ecoregion_l4 = rstats$ecoregion_l4,
  regional_map_svg = svg_regional,
  neighborhood_map_svg = svg_orient,

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

  annual_precip_in = cstats$annual_precip_in,
  seasonal_precip = cstats$seasonal_precip,
  seasonal_temp = cstats$seasonal_temp,
  seasonal_temp_high = cstats$seasonal_temp_high,
  seasonal_temp_low = cstats$seasonal_temp_low,
  warmest_month = cstats$warmest_month,
  warmest_month_high_f = cstats$warmest_month_high_f,
  coldest_month = cstats$coldest_month,
  coldest_month_low_f = cstats$coldest_month_low_f,
  wettest_month = cstats$wettest_month,
  driest_month = cstats$driest_month,
  months_avg_low_below_freezing = cstats$months_avg_low_below_freezing,
  prevailing_wind = cstats$prevailing_wind,
  wind_station_name = cstats$wind_station_name,
  wind_station_id = cstats$wind_station_id,
  wind_years = cstats$wind_years,
  wind_days = cstats$wind_days,
  climate_chart_svg = svg_climate,
  wind_rose_svg = svg_wind,

  soil_map_units = sstats$soil_map_units,
  dominant_soil = sstats$dominant_soil,
  dominant_soil_pct = sstats$dominant_soil_pct,
  drainage_class = sstats$drainage_class,
  hydrologic_group = sstats$hydrologic_group,
  available_water_in_top_40in = sstats$available_water_in_top_40in,
  soil_map_legend = sstats$soil_map_legend,
  soil_map_svg = svg_soil_map,
  soil_profile_svg = svg_soil_profile,

  building_footprint_sqft = mstats$building_footprint_sqft,
  open_ground_sqft = mstats$open_ground_sqft,
  south_facing_pct = mstats$south_facing_pct,
  warm_ground_pct = mstats$warm_ground_pct,
  cool_ground_pct = mstats$cool_ground_pct,
  building_height_ft_assumed = mstats$building_height_ft_assumed,
  shade_hours_window = mstats$shade_hours_window,
  winter_noon_sun_deg = mstats$winter_noon_sun_deg,
  winter_full_sun_pct = mstats$winter_full_sun_pct,
  winter_shade_2h_pct = mstats$winter_shade_2h_pct,
  winter_shade_4h_pct = mstats$winter_shade_4h_pct,
  summer_noon_sun_deg = mstats$summer_noon_sun_deg,
  summer_full_sun_pct = mstats$summer_full_sun_pct,
  summer_shade_2h_pct = mstats$summer_shade_2h_pct,
  summer_shade_4h_pct = mstats$summer_shade_4h_pct,
  canopy_cover_pct = NULL,
  canopy_cover_nearby_pct = canopy_nearby_pct,
  canopy_cover_nearby_radius_ft = canopy_radius_ft,
  heat_accumulation_map_svg = svg_heat,
  shade_map_svg = svg_shade,

  synthesis_narrative = notes$synthesis_narrative,
  vulnerabilities = notes$vulnerabilities,
  opportunities = notes$opportunities,
  sun_path_svg = svg_sun,

  data_sources = list(
    list(name = "NC OneMap parcels (NC1Map_Parcels)", url = "https://www.nconemap.gov", accessed = format(Sys.Date())),
    list(name = "NC OneMap 3 ft bare-earth DEM (DEM03)", url = "https://www.nconemap.gov", accessed = format(Sys.Date())),
    list(name = "NC building footprints (NC Spatial Data Download, 2020-2022 inventory)", url = "https://sdd.nc.gov", accessed = format(Sys.Date())),
    list(name = "EPA Level III and IV Ecoregions", url = "https://www.epa.gov/eco-research/ecoregions", accessed = format(Sys.Date())),
    list(name = "USGS National Hydrography Dataset (river linework)", url = "https://www.usgs.gov/national-hydrography", accessed = attr(river, "manifest")$downloaded %||% format(Sys.Date())),
    list(name = "US Census Bureau cartographic boundary files (state outline)", url = "https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html", accessed = attr(state, "manifest")$downloaded %||% format(Sys.Date())),
    list(name = "USGS Watershed Boundary Dataset (HUC06, HUC12)", url = "https://www.usgs.gov/national-hydrography/watershed-boundary-dataset", accessed = format(Sys.Date())),
    list(name = "FEMA National Flood Hazard Layer", url = "https://www.fema.gov/flood-maps/national-flood-hazard-layer", accessed = format(Sys.Date())),
    list(name = "City of Raleigh Hydrology", url = "https://services.arcgis.com/v400IkDOw1ad7Yad/arcgis/rest/services/Hydrology/FeatureServer", accessed = attr(hydro, "manifest")$downloaded %||% format(Sys.Date())),
    list(name = "OpenStreetMap contributors (roads)", url = "https://www.openstreetmap.org/copyright", accessed = attr(roads, "manifest")$downloaded %||% format(Sys.Date())),
    list(name = "PRISM Climate Group, Oregon State University (30-year normals 1991-2020, 4 km)", url = "https://prism.oregonstate.edu/normals/", accessed = format(Sys.Date())),
    list(name = sprintf("NOAA NCEI GHCN-Daily summaries, station %s (%s)", cstats$wind_station_id, cstats$wind_station_name), url = "https://www.ncei.noaa.gov/access/services/data/v1", accessed = format(Sys.Date())),
    list(name = "NRCS SSURGO via Soil Data Access (map unit polygons, components, horizons)", url = "https://sdmdataaccess.nrcs.usda.gov", accessed = attr(soil_polys, "manifest")$downloaded %||% format(Sys.Date())),
    list(name = "USFS NLCD Tree Canopy Cover, 30 m (canopy near the parcel)", url = "https://www.mrlc.gov/data/type/tree-canopy-cover", accessed = format(Sys.Date()))
  )
)

payload_path <- file.path(out_dir, paste0(slug, "_payload.json"))
write_json(payload, payload_path, auto_unbox = TRUE, null = "null", pretty = TRUE, digits = NA)
saveRDS(list(parcel = parcel, dem = wrap(dem), bldgs = bldgs, stats = stats, ws = ws, flood = flood, hstats = hstats,
             normals = normals, wind = wind, cstats = cstats, soils = so[c("own", "own_comps", "hz", "ag", "in_frame")], sstats = sstats,
             mstats = mstats),
        file.path(out_dir, paste0(slug, "_data.rds")))
out <- render_site_assessment(payload, out_dir = out_dir)
message("Wrote ", payload_path, "\nWrote ", out)
