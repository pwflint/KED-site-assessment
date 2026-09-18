library(sf)

# Administrative outlines for orientation graphics: the state, for the
# regional inset. Census cartographic boundary files via tigris (the same
# source the July prototype used, now cached: the outline never changes
# between Census releases, so it is fetched once per machine).
#
# Vintage is the tigris default year at fetch time; recorded in the cache
# manifest by the caller.

get_state_outline <- function(state_abbr = "NC", resolution = "500k") {
  st <- tigris::states(cb = TRUE, resolution = resolution, progress_bar = FALSE)
  st <- st_transform(st[st$STUSPS == state_abbr, c("STUSPS", "NAME")], 4326)
  st
}
