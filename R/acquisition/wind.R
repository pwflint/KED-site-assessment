library(sf)
library(httr)

# NOAA NCEI Access Data Service API - confirmed no token required (unlike the
# classic CDO Web Services). GHCND daily summaries give WDF2 (direction of
# fastest 2-min wind) and WSF2/AWND (speed) per day - no wind-rose product
# exists directly, so the rose is built by binning many years of daily
# observations by direction, matching the approach the old research doc
# gestured at ("interpolate this from the downloaded dataset").
NCEI_STATIONS_URL <- "https://www.ncei.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt"
NCEI_DATA_URL <- "https://www.ncei.noaa.gov/access/services/data/v1"

GHCND_STATIONS_CACHE_DIR <- Sys.getenv("GHCND_STATIONS_CACHE_DIR", file.path(tempdir(), "ghcnd_cache"))

# NOTE: tempdir() is per-R-session, not persistent across script runs - callers
# who want real cross-run caching should set GHCND_STATIONS_CACHE_DIR to a stable path.
get_ghcnd_stations <- function(cache_path = file.path(GHCND_STATIONS_CACHE_DIR, "ghcnd-stations.txt")) {
  dir.create(dirname(cache_path), showWarnings = FALSE, recursive = TRUE)
  if (!file.exists(cache_path)) download.file(NCEI_STATIONS_URL, cache_path, quiet = TRUE)
  lines <- readLines(cache_path)
  data.frame(
    id = trimws(substr(lines, 1, 11)),
    lat = as.numeric(substr(lines, 13, 20)),
    lon = as.numeric(substr(lines, 22, 30)),
    name = trimws(substr(lines, 42, 71))
  )
}

# nearest station by great-circle distance - restricted to "USW" (Weather-Bureau-
# Army-Navy) stations: airport/NWS sites with full meteorological instrumentation.
# "US1" stations are CoCoRaHS volunteer rain gauges (precip only, no wind - this
# is exactly what nearest_station() picked before this filter was added, since
# CoCoRaHS sites are dense and often geometrically closer than the nearest real
# weather station). "USC" (COOP) stations have inconsistent wind reporting.
nearest_station <- function(lon, lat, stations = get_ghcnd_stations()) {
  usw <- stations[grepl("^USW", stations$id), ]
  d <- st_distance(
    st_sfc(st_point(c(lon, lat)), crs = 4326),
    st_as_sf(usw, coords = c("lon", "lat"), crs = 4326)
  )
  usw[which.min(d), ]
}

# PRD seasonal grouping: Winter Nov-Jan, Spring Feb-Apr, Summer May-Jul, Fall Aug-Oct
season_of_month <- function(m) {
  ifelse(m %in% c(11, 12, 1), "winter",
  ifelse(m %in% c(2, 3, 4), "spring",
  ifelse(m %in% c(5, 6, 7), "summer", "fall")))
}

get_daily_wind <- function(station_id, start_date, end_date) {
  resp <- GET(NCEI_DATA_URL, query = list(
    dataset = "daily-summaries",
    stations = station_id,
    startDate = start_date,
    endDate = end_date,
    dataTypes = "AWND,WSF2,WDF2",
    units = "metric",
    format = "json"
  ))
  txt <- content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(txt, simplifyVector = TRUE)
  if (length(parsed) == 0) stop("No wind data returned for station ", station_id)
  parsed$AWND <- as.numeric(parsed$AWND)
  parsed$WSF2 <- as.numeric(parsed$WSF2)
  parsed$WDF2 <- as.numeric(parsed$WDF2)
  parsed$month <- as.integer(substr(parsed$DATE, 6, 7))
  parsed$season <- season_of_month(parsed$month)
  parsed
}

# 8-point compass wind rose: frequency (% of days) and mean speed (m/s) per
# direction bin, per season
DIRECTIONS <- c("N", "NE", "E", "SE", "S", "SW", "W", "NW")

compass_bin <- function(deg) {
  bin <- floor(((deg + 22.5) %% 360) / 45) + 1
  DIRECTIONS[bin]
}

seasonal_wind_rose <- function(daily_wind) {
  daily_wind <- daily_wind[!is.na(daily_wind$WDF2), ]
  daily_wind$dir <- compass_bin(daily_wind$WDF2)

  seasons <- c("winter", "spring", "summer", "fall")
  rose <- expand.grid(season = seasons, dir = DIRECTIONS, stringsAsFactors = FALSE)
  rose$freq_pct <- NA_real_
  rose$mean_speed_ms <- NA_real_

  for (i in seq_len(nrow(rose))) {
    subset_rows <- daily_wind$season == rose$season[i] & daily_wind$dir == rose$dir[i]
    season_total <- sum(daily_wind$season == rose$season[i])
    rose$freq_pct[i] <- 100 * sum(subset_rows) / season_total
    rose$mean_speed_ms[i] <- mean(daily_wind$AWND[subset_rows], na.rm = TRUE)
  }
  rose
}

# --- orchestrator ---
get_wind_data <- function(parcel_sf, years_of_history = 10) {
  centroid <- st_transform(st_centroid(parcel_sf), 4326) |> st_coordinates()
  station <- nearest_station(centroid[1, "X"], centroid[1, "Y"])

  end_date <- Sys.Date() - 1
  start_date <- end_date - years_of_history * 365

  daily <- get_daily_wind(station$id, format(start_date), format(end_date))
  rose <- seasonal_wind_rose(daily)

  list(station = station, daily = daily, seasonal_rose = rose)
}
