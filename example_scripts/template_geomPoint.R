## Template script for geom_point primitive using sample data. 

url <- "https://raw.githubusercontent.com/z3tt/graphic-design-ggplot2/main/data/london-bikes-custom.csv"
bikes <- readr::read_csv(url,
  ## col_types is specifying the data type for each variable. R will do this automatically,
  ## but it is helpful to include if the data type is known in advance. 
  col_types = "Dcfffilllddddc"
)

# this function is specifying how to handle the factor values for the "season" var.
bikes$season <- forcats::fct_inorder(bikes$season)

ggplot(
  bikes,
  aes(x = temp_feel, y = count)
) +
  # these are the basic aes args geom_point understands
  geom_point(
    color = "#28a87d",
    alpha = 1,
    shape = "X",
    stroke = 1,
    size = 4
  )

## an aes mapping can also be placed inside the geom_point function and combined with other mappings.
ggplot(
  bikes,
  aes(x = temp, y = temp_feel)
) +
  geom_point(
    aes(fill = weather_type == "clear",
        size = count),
    shape = 23,
    color = "black",
    alpha = .5
  )



# ?geom_point for additional arguments and aesthetics

# save plot
ggsave("plots/template_plot")
