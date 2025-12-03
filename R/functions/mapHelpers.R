# Mapping Helper Functions
# Reusable mapping functions for consistent map styling

#' Add scale bar to ggplot map
#'
#' @param plot ggplot object
#' @param location Location of scale bar ("bl", "br", "tl", "tr")
#' @param width_hint Width hint for scale bar (default: 0.25)
#' @return ggplot object with scale bar
add_scale_bar <- function(plot, location = "bl", width_hint = 0.25) {
  plot <- plot +
    ggspatial::annotation_scale(
      location = location,
      width_hint = width_hint,
      style = "ticks",
      line_col = "black",
      text_col = "black"
    )
  
  return(plot)
}

#' Add north arrow to ggplot map
#'
#' @param plot ggplot object
#' @param location Location of north arrow ("bl", "br", "tl", "tr")
#' @param which_north Grid north or true north (default: "grid")
#' @return ggplot object with north arrow
add_north_arrow <- function(plot, location = "bl", which_north = "grid") {
  plot <- plot +
    ggspatial::annotation_north_arrow(
      location = location,
      which_north = which_north,
      style = ggspatial::north_arrow_fancy_orienteering,
      height = unit(1.5, "cm"),
      width = unit(1.5, "cm")
    )
  
  return(plot)
}

#' Create base map for site location
#'
#' @param site_boundary sf object with site boundary
#' @param buffer_distance Buffer distance in meters for map extent
#' @param crs Coordinate reference system for map
#' @return ggplot object with base map
create_base_map <- function(site_boundary, buffer_distance = 1000, crs = NULL) {
  # Set CRS if provided
  if (!is.null(crs)) {
    site_boundary <- sf::st_transform(site_boundary, crs)
  }
  
  # Create buffered extent
  if (sf::st_is_longlat(site_boundary)) {
    # For geographic CRS, use degree buffer
    buffer_deg <- buffer_distance / 111000  # Approximate meters to degrees
    bbox <- sf::st_bbox(site_boundary)
    bbox_expanded <- bbox + c(-buffer_deg, -buffer_deg, buffer_deg, buffer_deg)
  } else {
    # For projected CRS, use meter buffer
    buffered <- sf::st_buffer(site_boundary, dist = buffer_distance)
    bbox_expanded <- sf::st_bbox(buffered)
  }
  
  # Create base map
  base_map <- ggplot2::ggplot() +
    ggplot2::coord_sf(
      xlim = c(bbox_expanded["xmin"], bbox_expanded["xmax"]),
      ylim = c(bbox_expanded["ymin"], bbox_expanded["ymax"]),
      crs = sf::st_crs(site_boundary),
      expand = FALSE
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text = ggplot2::element_text(size = 8),
      axis.title = ggplot2::element_blank()
    )
  
  return(base_map)
}

#' Create custom map theme
#'
#' @param base_size Base font size (default: 12)
#' @param base_family Base font family (default: "sans")
#' @return ggplot theme object
theme_site_map <- function(base_size = 12, base_family = "sans") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      axis.text = ggplot2::element_text(color = "black", size = base_size * 0.8),
      axis.title = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_line(color = "black"),
      legend.position = "right",
      legend.background = ggplot2::element_rect(fill = "white", color = "black", linewidth = 0.5),
      plot.title = ggplot2::element_text(size = base_size * 1.2, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = base_size, color = "gray40")
    )
}

#' Save map figure
#'
#' @param plot ggplot object
#' @param file_path Path to save file
#' @param width Figure width in inches (default: 10)
#' @param height Figure height in inches (default: 8)
#' @param dpi Resolution (default: 300)
save_map_figure <- function(plot, file_path, width = 10, height = 8, dpi = 300) {
  dir.create(dirname(file_path), showWarnings = FALSE, recursive = TRUE)
  
  ggplot2::ggsave(
    filename = file_path,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    device = "pdf"  # Can be changed to "png", "jpg", etc.
  )
  
  message(paste("Map saved to:", file_path))
}

