library(readr)
library(jsonlite)
library(dplyr)

# Loads sites data
sites_data <- read_csv('subjects_screened_by_sites_phase1.csv')

# Checks for missing columns in any rows
if (any(colSums(is.na(sites_data)) > 0)) {
  stop("Data is missing in some rows.")
}

# Summarizes the total subjects screened by country
subjects_screened_by_country <- sites_data %>%
  group_by(Country) %>%
  summarize(Total_Subjects = sum(Subjects_Screened, na.rm = TRUE)) %>%
  ungroup()

# Writes the summarized data to a CSV file
write_csv(subjects_screened_by_country, 'subjects_screened_by_countries_phase1.csv', col_names = TRUE)

# Prepares a list to hold site data
sites <- list()

# Populates the list with site data
for (i in 1:nrow(sites_data)) {
  ORISITEID <- as.character(sites_data$ORISITEID[i])
  sites[[ORISITEID]] <- sites_data[i, ]
}

# Loads the map template
html_template <- readLines('screening_map_template.html', warn = FALSE)
html_template <- paste(html_template, collapse = "\n")

# Generates data-points
data_points <- ""

for (trial_site_id in names(sites)) {
  country <- sites[[trial_site_id]]$Country
  site_name <- sites[[trial_site_id]]$Site_Name
  latitude <- sites[[trial_site_id]]$Latitude
  longitude <- sites[[trial_site_id]]$Longitude
  investigator <- sites[[trial_site_id]]$Investigator
  subjects_screened <- sites[[trial_site_id]]$Subjects_Screened

  # Calculate the total area for the subjects screened
  total_area <- 100000000 * subjects_screened # 100.000.000 square meters per subject

  # Calculate the radius based on the area
  radius_size <- as.integer(sqrt(total_area / pi)) # sqrt(Area / pi)

  site_name_print <- gsub("'", "\\\\'", site_name, fixed = TRUE)

  data_points <- paste0(data_points, sprintf("var circle%s = L.circle([%s, %s], {
    color: '#B0B0B0',
    fillColor: '#B0B0B0',
    fillOpacity: 0.9,
    radius: %s,
    site_name: '%s',
    investigator: '%s',
    subjects_screened: '%s',
    trial_site_id: %s
}).addTo(map).on('mouseover', onClick);\n", i, latitude, longitude, radius_size, site_name_print, investigator, subjects_screened, i))

    data_points <- paste0(data_points, sprintf("
  var label%s = L.marker([%s, %s], {
  icon: L.divIcon({
    className: 'label',
    html: '<div style=\"font-size: 20px; font-weight: bold; color: black; text-align: center;\">%s</div>',
    iconSize: [100, 40]
  })
}).addTo(map);", i, latitude, longitude, subjects_screened))
}

html_template <- gsub("\\[---DATAPOINTS---\\]", data_points, html_template)

# Writes the modified HTML to a new file
writeLines(html_template, 'map_of_phase_1_subjects_screened.html')
