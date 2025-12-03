# Load Forest Height Data
#------------------------

forest_height_list <- lapply(
  rasterFiles,
  terra::rast
)
# Error: Will not create object
# Error message at this step: [rast] cannot open this file as a SpatRaster: `<fileName>.tif`
# Warning message: `<fileName>.tif' not recognized as a supported file format. (GDAL error 4) 

# Crop files to state boundary
forest_height_rasters <- lapply(
  forest_height_list,
  function(x){
    terra::crop(
      x,
      terra::vect(
        nc_sf
      ),
      snap = "in",
      mask = TRUE
    )
  }
)
    
# Create unified mosaic
forest_height_mosaic <- do.call(
    terra::mosaic,
    forest_height_rasters
    )
    # The result from ↑ this code will create a large file that will crash R.
# Aggregate and reduce resolution to practical size
forest_height_nc <- forest_height_mosaic |> 
    terra::aggregate(
    fact = 10
)
    