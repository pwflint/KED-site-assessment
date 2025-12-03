# 1. GET WIND DATA
#----------------------

get_wind_data <- function(time_range, mean_wind_data, eur_wind_df) {
  
  time_range <- seq(ymd_hms(paste(2023, 7, 27, 00, 00, 00, sep = "-")),
                    ymd_hms(paste(2023, 7, 28, 00, 00, 00, sep = "-")),
                    by = "1 hours"
  )
  
  mean_wind_data <- rWind::wind.dl_2(time_range, -28.5, 58.5, 34.0, 73.5) %>%
    rWind::wind.mean()
  
  eur_wind_df <- as.data.frame(mean_wind_data)
  return(eur_wind_df)
}

