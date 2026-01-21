# Implementation Plan: Asphalt Emissions Choropleth Map

## Overview
Create a U.S. choropleth map visualization of asphalt-related emissions by state using EPA data from 2018, styled with a green-yellow-red color scale representing emissions intensity.

## Phase 1: Project Setup
1. Create directory structure (`data/`, `plots/`)
2. Initialize R environment with required packages
3. Set up error handling and logging

## Phase 2: Data Acquisition & Preparation
1. Check if data file exists locally
2. Download Excel file from EPA URL if missing (binary mode)
3. Read "Output - State" sheet with quiet mode
4. Extract and validate columns:
   - State names (normalize to lowercase)
   - Total kg/person (convert to numeric, suppress warnings)
5. Merge emissions data with US map spatial data
6. Validate merge completeness

## Phase 3: Map Creation
1. Retrieve US map data using `usmap::us_map()`
2. Join map data with emissions data by state
3. Create base map with `usmap::plot_usmap()`
4. Configure color scale:
   - Dark green for low values
   - Yellow for medium values
   - Red for high values
5. Add styling:
   - Grey state borders
   - White background
   - Title with (2018) year
   - Descriptive subtitle
   - Data source caption

## Phase 4: Output & Documentation
1. Save map as PNG to `plots/` folder
2. Create documentation files:
   - README.md with map preview and citations
   - tasks.md with implementation checklist
   - walkthrough.md with step-by-step guide
3. Create .gitignore for R projects
4. Include links between all markdown files

## Phase 5: Testing & Validation
1. Verify folder creation
2. Check data merge accuracy
3. Validate color differentiation
4. Confirm PNG output quality
5. Test documentation completeness

## Key Technical Considerations
- Use `pacman::p_load()` for package management
- Use `here::here()` for cross-platform path handling
- Use `.name_repair = "unique_quiet"` for silent Excel reading
- Handle warnings with `suppressWarnings()` where appropriate
- Ensure state name matching with case normalization
- Use `linewidth` instead of `size` for ggplot polygon borders
