# Step-by-Step Walkthrough: Creating the Asphalt Emissions Choropleth Map

## Overview
This walkthrough explains how the R script creates a choropleth visualization of asphalt-related emissions across U.S. states using EPA data.

## Step 1: Project Initialization & Setup
**What happens:**
- The script loads all required packages using `pacman::p_load()`
- Creates `data/` directory for storing the Excel file
- Creates `plots/` directory for saving the output PNG
- Uses `here::here()` for cross-platform path management

**Why:**
- `pacman` ensures packages are loaded efficiently
- Directory creation is defensive programming—it ensures folders exist before use
- `here::here()` makes the project portable across Windows, macOS, and Linux

```r
pacman::p_load(readxl, tidyverse, usmap, sf, ggplot2, here)
dir.create(here::here("data"), showWarnings = FALSE)
dir.create(here::here("plots"), showWarnings = FALSE)
```

## Step 2: Conditional Data Download
**What happens:**
- Checks if the EPA Excel file already exists locally
- If missing, downloads it from the EPA URL in binary mode
- Saves to `data/AP_2018_State_County_Inventory.xlsx`

**Why:**
- Avoids re-downloading on subsequent runs
- Binary mode (`mode = "wb"`) preserves Excel file integrity
- Error handling prevents script failure on download issues

```r
if (!file.exists(data_file)) {
  download.file(url = data_url, destfile = data_file, mode = "wb", quiet = TRUE)
}
```

## Step 3: Data Loading (Excel → R)
**What happens:**
- Reads the "Output - State" sheet from the Excel file
- Uses `.name_repair = "unique_quiet"` to silence readxl messages
- Extracts State names and Total kg/person emissions values

**Why:**
- `.name_repair = "unique_quiet"` suppresses informational messages like "New names:"
- Quiet mode creates a cleaner output experience
- Explicit sheet selection ensures we read the correct data

```r
emissions_data <- read_excel(
  data_file,
  sheet = "Output - State",
  .name_repair = "unique_quiet"
)
```

## Step 4: Data Cleaning & Normalization
**What happens:**
- Selects State and emissions columns
- Converts state names to lowercase for consistent merging
- Converts emissions to numeric (with warnings suppressed)
- Removes rows with missing data

**Why:**
- Lowercase normalization ensures state name matching with map data
- Numeric conversion allows statistical operations (min, max, median)
- `suppressWarnings()` prevents clutter from coercion messages

```r
emissions_clean <- emissions_data %>%
  select(State, starts_with("Total")) %>%
  mutate(
    state_lower = tolower(State),
    emissions = suppressWarnings(as.numeric(emissions))
  )
```

## Step 5: Load US Map Data
**What happens:**
- Retrieves US map from the `usmap` package using `us_map()`
- Recognizes that usmap ≥ 0.7.0 returns an sf object with a `geom` column
- Normalizes state names to lowercase
- Prepares the geometry column for spatial operations

**Why:**
- usmap provides standardized U.S. state boundaries including Alaska and Hawaii
- SF (Simple Features) format is standard for spatial data in R
- Normalizing state names ensures successful merging with emissions data

```r
us_map_data <- usmap::us_map()
map_data_clean <- us_map_data %>%
  st_as_sf() %>%
  mutate(state_lower = tolower(state))
```

## Step 6: Merge Emissions with Map
**What happens:**
- Left-joins map data with emissions data using state names
- Filters to keep only states with both map and emissions data
- Provides feedback on merge success

**Why:**
- Left join ensures all map states are retained
- Data validation confirms we have complete coverage
- Diagnostic output helps debug any merge issues

```r
map_with_emissions <- map_data_clean %>%
  left_join(emissions_clean, by = "state_lower") %>%
  filter(!is.na(emissions))
```

## Step 7: Calculate Statistics for Color Scaling
**What happens:**
- Computes minimum, maximum, and median emissions values
- Uses median as the midpoint for the color gradient

**Why:**
- Color scale needs to be meaningful and centered appropriately
- Median is robust to outliers, providing good visual balance
- Statistics help interpret the map results

```r
emissions_min <- min(map_with_emissions$emissions, na.rm = TRUE)
emissions_max <- max(map_with_emissions$emissions, na.rm = TRUE)
emissions_median <- median(map_with_emissions$emissions, na.rm = TRUE)
```

## Step 8: Create the Choropleth Map
**What happens:**
- Uses `usmap::plot_usmap()` to create the base US map
- Fills states with color based on emissions values
- Applies a three-color gradient:
  - **Dark green** (#1b7837): Low emissions
  - **Yellow** (#ffffbf): Medium emissions (centered at median)
  - **Red** (#d73027): High emissions
- Adds grey state borders using appropriate linewidth
- Adds title, subtitle, and caption

**Why:**
- Three-color gradient (green → yellow → red) creates intuitive interpretation
- Green = safe/low, Red = concerning/high
- ggplot layers provide fine-grained control over appearance
- Title includes "(2018)" per requirements

```r
choropleth_map <- usmap::plot_usmap(
  data = map_with_emissions,
  values = "emissions",
  color = "grey50"
) +
  scale_fill_gradient2(
    low = "#1b7837",
    mid = "#ffffbf",
    high = "#d73027",
    midpoint = emissions_median
  ) +
  labs(title = "U.S. Asphalt-Related Emissions by State (2018)")
```

## Step 9: Style the Map
**What happens:**
- Removes axis titles, labels, and ticks
- Sets background to white
- Positions legend on the right
- Formats title, subtitle, and caption

**Why:**
- Axes are irrelevant for choropleth maps (they show arbitrary projections)
- White background is professional and print-friendly
- Proper typography makes the visualization more compelling

```r
theme(
  axis.title = element_blank(),
  axis.text = element_blank(),
  axis.ticks = element_blank(),
  plot.background = element_rect(fill = "white", color = NA)
)
```

## Step 10: Save as PNG
**What happens:**
- Saves the map to `plots/asphalt_emissions_2018.png`
- Uses 300 DPI for high-quality publication-ready output
- Sets white background
- Dimensions: 14" wide × 8" tall

**Why:**
- PNG format is widely compatible and lossless
- 300 DPI ensures print quality
- Dimensions provide a balanced, readable map

```r
ggsave(
  output_file,
  choropleth_map,
  width = 14, height = 8,
  dpi = 300,
  bg = "white"
)
```

## Step 11: Completion Reporting
**What happens:**
- Prints a completion summary with statistics
- Reports number of states mapped
- Shows emissions range
- Displays output file path

**Why:**
- Confirms successful execution
- Provides quick reference for map interpretation
- Helps validate results at a glance

## Key Technical Insights

### State Name Matching
The script uses lowercase normalization for state names:
```r
state_lower = tolower(State)  # In emissions data
state_lower = tolower(state)  # In map data
left_join(..., by = "state_lower")  # Match on lowercase
```
This ensures consistent merging even if EPA data uses different capitalization than map data.

### Color Scale Logic
The color gradient is centered at the **median** (not the mean):
```r
scale_fill_gradient2(
  low = "#1b7837", mid = "#ffffbf", high = "#d73027",
  midpoint = emissions_median
)
```
This balances the visual distribution—if one tail had extreme outliers, centering at the mean would wash out the middle colors.

### Error Handling
Each major step includes try-catch blocks:
```r
tryCatch({
  # Operation
  cat("✓ Success\n")
}, error = function(e) {
  cat("✗ Error:\n")
  print(e)
  stop("Meaningful error message")
})
```
This prevents silent failures and provides diagnostic information.

## Running the Script
```bash
Rscript asphalt_emissions.R
```

Or in RStudio: Source the file or run line by line for interactive debugging.

## Expected Output
1. **Console Messages:**
   - Confirmation of directory creation
   - Data download/load status
   - Merge success statistics
   - Completion summary with statistics

2. **Files Created:**
   - `data/AP_2018_State_County_Inventory.xlsx` (if not present)
   - `plots/asphalt_emissions_2018.png` (choropleth map)

3. **Visualization:**
   - 50-state choropleth with green-yellow-red color scale
   - Grey state borders
   - Title, subtitle, and caption
   - No axis labels or ticks
