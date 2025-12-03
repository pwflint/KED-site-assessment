
get_wind_points <- function() {
  # convert wind data into points
  eur_wind_pts <- eur_wind_df %>%
    sf::st_as_sf(coords = c("lon", "lat")) %>%
    sf::st_set_crs(4326)
  
  return(eur_wind_pts)
}

eur_wind_pts <- get_wind_points()

# Create a grid
get_wind_grid <- function() {
  eur_wind_grid <- eur_wind_pts %>%
    sf::st_make_grid(n = c(80, 100)) %>%
    sf::st_sf() %>%
    dplyr::mutate(id = row_number())
  
  return(eur_wind_grid)
}

eur_wind_grid <- get_wind_grid()

# Aggregate points onto a data frame
get_wind_grid_aggregated <- function() {
  
  eur_wind_grid_agg <- 
    sf::st_join(eur_wind_pts, eur_wind_grid, 
                join = sf::st_within) %>%
    sf::st_drop_geometry() %>%
    dplyr::group_by(id) %>%
    dplyr::summarise(
      n = n(), u = mean(ugrd10m), 
      v = mean(vgrd10m), speed = mean(speed)
    ) %>%
    dplyr::inner_join(eur_wind_grid, by="id") %>%
    dplyr::select(n, u, v, speed, geometry) %>%
    sf::st_as_sf() %>%
    na.omit()
  
  return(eur_wind_grid_agg)
}

eur_wind_grid_agg <- get_wind_grid_aggregated()

# Interpolate windspeeds for each point
get_wind_coords <- function() {
  coords <- eur_wind_grid_agg %>%
    st_centroid() %>%
    st_coordinates() %>%
    as_tibble() %>%
    rename(lon = X, lat = Y)
  return(coords)
}

coords <- get_wind_coords()

# Merge interpolated points onto a data frame
get_wind_df <- function() {
  eur_df <- coords %>%
    bind_cols(sf::st_drop_geometry(eur_wind_grid_agg))
  return(eur_df)
}

eur_df <- get_wind_df()

## interpolate the U component
get_u_interpolation <- function() {
  wu <- oce::interpBarnes(
    x = eur_df$lon,
    y = eur_df$lat,
    z = eur_df$u
  )
  return(wu)
}

wu <- get_u_interpolation()

dimension <- data.frame(lon = wu$xg, wu$zg) %>% dim()

## make a U component data table from interpolated matrix
get_u_table <- function() {
  udf <- data.frame(
    lon = wu$xg,
    wu$zg
  ) %>%
    gather(key = "lata", value = "u", 2:dimension[2]) %>%
    mutate(lat = rep(wu$yg, each = dimension[1])) %>%
    select(lon, lat, u) %>%
    as_tibble()
  
  return(udf)
}

udf <- get_u_table()

## interpolate the V component
get_u_interpolation <- function() {
  wv <- oce::interpBarnes(
    x = eur_df$lon,
    y = eur_df$lat,
    z = eur_df$v
  )
  return(wv)
}

wv <- get_u_interpolation()

## make the V component data table from interpolated matrix
get_v_table <- function() {
  vdf <- data.frame(lon = wv$xg, wv$zg) %>%
    gather(key = "lata", value = "v", 2:dimension[2]) %>%
    mutate(lat = rep(wv$yg, each = dimension[1])) %>%
    select(lon, lat, v) %>%
    as_tibble()
  return(vdf)
}

vdf <- get_v_table()

## merge the V and U component tables and compute velocity
get_final_table <- function() {
  df <- udf %>%
    bind_cols(vdf %>% select(v)) %>%
    mutate(vel = sqrt(u^2 + v^2))
  return(df)
}

df <- get_final_table()
