# Graphic Attributes
#--------------------

cols <- c(
  "white", "#ffd3af", "#fbe06e", "#6daa55", "#205544"
)

texture <- colorRampPalette(
  cols,
  bias = 3
)(8)

# Plotting

p <- ggplot(
        forest_height_nc_df
        ) +
  geom_raster(
    aes(
      x = x,
      y = y,
      fill = height
    )
  ) +
  scale_fill_gradientn(
    name = "Height in Meters",
    colors = texture,
    breaks = round(breaks, 0)
  ) +
  coord_sf(crs = 4326) +
  guides(
    fill = guide_legend(
      direction = "vertical",
      keyheight = unit(5, "mm"),
      keywidth = unit(5, "mm"),
      title.position = "top",
      label.position = "right",
      title.hjust = .5,
      label.hjust = .5,
      ncol = 1,
      byrow = FALSE
    )
  ) + 
  theme_minimal() +
  theme(
    axis.line = element_blank(),
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    legend.position = "right",
    legend.title = element_text(
      size = 11,
      color = "grey10"
    ),
    legend.text = element_text(
      size = 10,
      color = "grey10"
    ),
    panel.grid.major = element_line(
      color = "white"
    ),
    plot.background = element_rect(
      fill = "white", 
      color = NA
    ),
    legend.background = element_rect(
      fill = "white",
      color = NA
    ),
    panel.border = element_rect(
      fill = NA, 
      color = "white"
    ),
    plot.margin = unit(
      c(
        t = 0, r = 0, b = 0, l = 0
      ), 
      "lines"
    ) 
  ) +
  labs(title = "Height of Forest Canopy in North Carolina (2020)",
       fill = "Height in Meters",
       caption = "Data Source: Lang, Jetz, Schindler, and Wegner (2022)."
  )
p

