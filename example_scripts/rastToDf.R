# Raster to Dataframe
# Raster files must be converted in ordered to be plotted using ggplot

forest_height_nc_df <- forest_height_nc |> 
  as.data.frame(
    xy = TRUE
  )

head(forest_height_nc_df)
names(forest_height_nc_df)[3]<-"height"

# Create interval breaks for height data
#---------------------------------------

breaks <- classInt::classIntervals(
  forest_height_nc_df$height,
  n = 7,
  style = "fisher"
)$brks
