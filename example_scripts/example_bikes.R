## Basic scatter plot of plot bikes$temp_feel versus bikes$count
ggplot(bikes, aes(temp_feel, count)) +
  geom_point(size = 2.2)

# Call basic grid for more advanced plot
ggplot(bikes, aes(temp_feel, count)) +

# Color points according to season    
  geom_point(
    aes(color = season),
    size = 2.2, alpha = .55
  ) +
  ## add a linear regression fitting for time of the day
  geom_smooth(
    aes(group = day_night),
    method = "lm", color = "black"
  ) +
  ## Facet the grid to separate data into day v. night and workday v. holiday
  facet_grid(
    day_night ~ is_workday,
    ## scale grid according to use of space
    scales = "free_y", space = "free_y"
  ) +
  ## add custom colors + legend styling
  scale_color_manual(
    values = c("#3c89d9", "#1ec99b", "#F7B01B", "#a26e7c"), name = "Season:",
    guide = guide_legend(override.aes = list(size = 5))
  ) +
  ## add labels + titles
  labs(
    x = "Feels-Like Temperature", y = NULL,
    caption = "Data: TfL (Transport for London), Jan 2015 — Dec 2016",
    title = "Reported bike rents versus feels-like temperature in London per time of day, period, and season."
  ) + 
  ## use different theme and typeface
  theme_light(base_size = 18, base_family = "Poppins") +
  ## adjust theme to fit plot
  theme(
    ## Basic adjustments
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "top",
    ## Advanced adjustments
    axis.text = element_text(family = "Yantramanav"),
    axis.title.x = element_text(hjust = 0, color = "grey30", margin = margin(t = 12)),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    panel.spacing = unit(1.2, "lines"),
    legend.text = element_text(size = rel(1)),
    ## for fitting a slide background
    legend.key = element_rect(color = "#f8f8f8", fill = "#f8f8f8"),
    legend.background = element_rect(color = "#f8f8f8", fill = "#f8f8f8"),
    plot.background = element_rect(color = "#f8f8f8", fill = "#f8f8f8")
  )

