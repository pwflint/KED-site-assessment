# Rayshader Render
#------------------
# The output of this script renders the entire state according to raster values in the same color.
# It is not visually clear. Review assigning different colors and different cell heights so urban
# areas and forested areas are clearer. 

h <- nrow(forest_height_nc)
w <- ncol(forest_height_nc)

rayshader::plot_gg(
  ggobj = p,
  width = w/1000,
  height = h/1000,
  scale = 150,
  solid = FALSE,
  soliddepth = 0,
  shadow = TRUE,
  shadow_intensity = .8,
  offset_edges = FALSE,
  sunangle = 315,
  window.size = c(800, 800),
  zoom = .4,
  phi = 30,
  theta = -30,
  multicore = TRUE
)

rayshader::render_camera(
  phi = 50,
  theta = 45,
  zoom = .7
)

# 9. Render Output
#-----------------

rayshader::render_highquality(
  filename = "nc-forest-height-2020.png",
  preview = T,
  interactive = F,
  light = T,
  lightdirection = c(
    315, 310, 315, 310
  ),
  lightintensity = c(
    1000, 1500, 150, 100
  ),
  lightaltitude = c(
    15, 15, 80, 80
  ),
  ground_material = 
    rayrender::microfacet(
      roughness = .6
    ),
  width = 4000,
  height = 4000
)
