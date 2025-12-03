# NC Polygon
#------------

get_state_border <- function(){
  main_path <- getwd()
  state_border <- geodata::gadm(
    country = "USA",
    level = 1,
    path = main_path
  ) |> 
  sf::st_as_sf()
  return(state_border)
}

state_border <- get_state_border()

# Get state names
unique(
  state_border$NAME_1
)

# Filter for NC geometry
nc_sf <- state_border |> 
  dplyr::filter(
    NAME_1 == "North Carolina"
  )
# Use %in% c() to collect multiple boundaries

# Delete remaining boundaries
otherStates <- state_border |> 
  dplyr::filter(
    NAME_1 != "North Carolina"
  ) |> 
  sf::st_union()
rm(otherStates)
