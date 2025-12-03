# 5. MAP WIND DATA
#-------------------------
# Code has been edited from source. Has graphic errors but displaying correctly

get_europe_sf <- function() {
  eur_sf <- giscoR::gisco_get_countries(
    year = "2016", epsg = "4326",
    resolution = "10", region = c("Europe", "Asia")
  )
  
  return(eur_sf)
}

# bounding box
crsLONGLAT <- "+proj=longlat +datum=WGS84 +no_defs"

get_bounding_box <- function(bbox, bb) {
  bbox <- st_sfc(
    st_polygon(list(cbind(
      c(-25, 48.5, 48.5, -25, -25),
      c(32.000, 32.000, 69.5, 69.5, 32.000)
    ))),
    crs = crsLONGLAT
  )
  
  bb <- sf::st_bbox(bbox)
  
  return(bb)
}

# colors
cols <- c(
  '#feebe2', '#d84594', '#bc2b8a', '#7a0177'
)

newcol <- colorRampPalette(cols)
ncols <- 6
cols2 <- newcol(ncols)

# breaks
vmin <- min(df$vel, na.rm = T)
vmax <- max(df$vel, na.rm = T)

brk <- classInt::classIntervals(df$vel,
                                n = 6,
                                style = "fisher"
)$brks %>%
  head(-1) %>%
  tail(-1) %>%
  append(vmax)

breaks <- c(vmin, brk)

# Plot
make_wind_map <- function(eur_sf, bb) {
  eur_sf <- get_europe_sf()
  bb <- get_bounding_box()
  
  p <- df %>%
    ggplot() +
    metR::geom_streamline(
      data = df,
      aes(
        x = lon, y = lat, dx = u, dy = v,
        color = sqrt(after_stat(dx)^2 + ..dy..^2)
      ),
      L = 2, res = 2, n = 60,
      arrow = NULL, lineend = "round",
      alpha = .85
    ) +
    geom_sf(
      data = eur_sf,
      fill = NA,
      color = "#07CFF7",
      size = .25,
      alpha = .99
    ) +
    coord_sf(
      crs = crsLONGLAT,
      xlim = c(bb["xmin"], bb["xmax"]),
      ylim = c(bb["ymin"], bb["ymax"])
    ) +
    scale_color_gradientn(
      name = "Average speed (m/s)",
      colours = cols2,
      breaks = breaks,
      labels = round(breaks, 1),
      limits = c(vmin, vmax)
    ) +
    guides(
      fill = "none",
      color = guide_legend(
        override.aes = list(size = 3, alpha = 1, shape = 15),
        direction = "horizontal",
        keyheight = unit(2.5, units = "mm"),
        keywidth = unit(15, units = "mm"),
        title.position = "top",
        title.hjust = .5,
        label.hjust = .5,
        nrow = 1,
        byrow = T,
        reverse = F,
        label.position = "bottom"
      )
    ) +
    theme_bw() +
  return(p)
}

p <- make_wind_map()

p
ggsave(
  filename = "eur_wind_27august2022.png",
  width = 8.5, height = 7, dpi = 600, device = "png", p
)
