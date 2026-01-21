#!/usr/bin/env Rscript
# ============================================================================
# Project: Asphalt Emissions Choropleth Map (2018)
# Purpose: Visualize U.S. state-level asphalt-related emissions using EPA data
# Data Source: EPA - AP_2018_State_County_Inventory.xlsx
# ============================================================================

# Load packages using pacman for package management
pacman::p_load(
  readxl,        # Read Excel files
  tidyverse,     # Data manipulation and visualization
  usmap,         # US map data and utilities
  sf,            # Simple features for spatial data
  ggplot2,       # Advanced plotting
  here           # Cross-platform file path handling
)

# ============================================================================
# 1. SETUP: Create directories and configure paths
# ============================================================================

# Create data directory if it doesn't exist
data_dir <- here::here("data")
if (!dir.exists(data_dir)) {
  dir.create(data_dir, showWarnings = FALSE)
  cat("✓ Created 'data' directory\n")
}

# Create plots directory if it doesn't exist
plots_dir <- here::here("plots")
if (!dir.exists(plots_dir)) {
  dir.create(plots_dir, showWarnings = FALSE)
  cat("✓ Created 'plots' directory\n")
}

# Set file path for EPA data
data_file <- here::here("data", "AP_2018_State_County_Inventory.xlsx")
data_url <- "https://pasteur.epa.gov/uploads/10.23719/1531683/AP_2018_State_County_Inventory.xlsx"

# ============================================================================
# 2. DATA ACQUISITION: Download EPA data if missing
# ============================================================================

if (!file.exists(data_file)) {
  cat("Downloading EPA asphalt emissions data...\n")
  
  tryCatch({
    download.file(
      url = data_url,
      destfile = data_file,
      mode = "wb",  # Binary mode for Excel file
      quiet = TRUE
    )
    cat("✓ Successfully downloaded data to 'data/AP_2018_State_County_Inventory.xlsx'\n")
  }, error = function(e) {
    cat("✗ Error downloading file:\n")
    print(e)
    stop("Failed to download EPA data file")
  })
} else {
  cat("✓ Data file already exists locally\n")
}

# ============================================================================
# 3. DATA LOADING: Read and prepare emissions data
# ============================================================================

cat("Reading emissions data from Excel file...\n")

tryCatch({
  # Read the "Output - State" sheet with quiet name repair
  emissions_data <- read_excel(
    data_file,
    sheet = "Output - State",
    .name_repair = "unique_quiet"
  )
  
  cat("✓ Successfully loaded emissions data\n")
}, error = function(e) {
  cat("✗ Error reading Excel file:\n")
  print(e)
  stop("Failed to read Excel file")
})

# ============================================================================
# 4. DATA PREPARATION: Extract and normalize columns
# ============================================================================

cat("Processing emissions data...\n")

# Create a mapping of state names to FIPS codes
state_fips_map <- data.frame(
  state_name = c(
    "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
    "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia",
    "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky",
    "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota",
    "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
    "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota",
    "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina",
    "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia",
    "Washington", "West Virginia", "Wisconsin", "Wyoming"
  ),
  fips = c(
    1, 2, 4, 5, 6, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22,
    23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 53, 54, 55, 56
  )
)

# Extract relevant columns and normalize state names
emissions_clean <- emissions_data %>%
  select(State, `Total kg/person`) %>%
  rename(emissions = `Total kg/person`) %>%
  mutate(
    # Normalize state names to match FIPS map
    state_name = State
  ) %>%
  left_join(state_fips_map, by = "state_name") %>%
  mutate(
    # Suppress warnings when converting to numeric
    emissions = suppressWarnings(as.numeric(emissions))
  ) %>%
  # Remove rows with missing state or emissions data
  filter(!is.na(state_name), !is.na(emissions), !is.na(fips)) %>%
  select(fips, emissions)

cat(sprintf("✓ Extracted emissions data for %d states\n", nrow(emissions_clean)))

# ============================================================================
# 5. MAP DATA: Get statistics for color scaling
# ============================================================================

cat("Preparing map visualization...\n")

# Get emissions statistics for color scaling
emissions_min <- min(emissions_clean$emissions, na.rm = TRUE)
emissions_max <- max(emissions_clean$emissions, na.rm = TRUE)
emissions_median <- median(emissions_clean$emissions, na.rm = TRUE)

cat(sprintf(
  "Emissions range: %.2f - %.2f kg/person (median: %.2f)\n",
  emissions_min, emissions_max, emissions_median
))

# ============================================================================
# 6. MAP VISUALIZATION: Create choropleth map
# ============================================================================

cat("Creating choropleth map...\n")

# Rename the emissions column to 'values' for plot_usmap
emissions_for_map <- emissions_clean %>%
  rename(values = emissions)

# Create the choropleth map
choropleth_map <- usmap::plot_usmap(
  regions = "states",
  data = emissions_for_map,
  values = "values",
  color = "grey50"
) +
  # Color scale: green (low) → yellow (medium) → red (high)
  scale_fill_gradient2(
    name = "Total Emissions\n(kg/person)",
    low = "#1b7837",        # Dark green
    mid = "#ffffbf",        # Yellow
    high = "#d73027",       # Red
    midpoint = emissions_median,
    limits = c(emissions_min, emissions_max),
    na.value = "white"
  ) +
  # Labels and titles
  labs(
    title = "U.S. Asphalt-Related Emissions by State (2018)",
    subtitle = "Total kg per capita from the EPA Air Pollutant Emissions Inventory",
    caption = "Data Source: EPA Air Pollutant Emissions Inventory (2018)"
  ) +
  # Styling
  theme(
    # Remove axes
    axis.title = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    # Background
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    # Legend styling
    legend.position = "right",
    # Title and caption styling
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, margin = margin(b = 10)),
    plot.caption = element_text(size = 9, hjust = 0, margin = margin(t = 10))
  )

cat("✓ Map created successfully\n")

# ============================================================================
# 7. OUTPUT: Save map as PNG
# ============================================================================

cat("Saving map as PNG...\n")

output_file <- here::here("plots", "asphalt_emissions_2018.png")

tryCatch({
  ggsave(
    output_file,
    choropleth_map,
    width = 14,
    height = 8,
    dpi = 300,
    bg = "white"
  )
  cat(sprintf("✓ Map saved to 'plots/asphalt_emissions_2018.png'\n"))
}, error = function(e) {
  cat("✗ Error saving map:\n")
  print(e)
  stop("Failed to save map as PNG")
})

# ============================================================================
# 8. COMPLETION MESSAGE
# ============================================================================

cat("\n")
cat("════════════════════════════════════════════════════════════════════════════════\n")
cat("✓ CHOROPLETH MAP CREATION COMPLETE\n")
cat("════════════════════════════════════════════════════════════════════════════════\n")
cat(sprintf("Data Points: %d states\n", nrow(emissions_clean)))
cat(sprintf("Emissions Range: %.2f - %.2f kg/person\n", emissions_min, emissions_max))
cat(sprintf("Output File: %s\n", output_file))
cat("════════════════════════════════════════════════════════════════════════════════\n\n")

# Return invisibly
invisible(choropleth_map)
