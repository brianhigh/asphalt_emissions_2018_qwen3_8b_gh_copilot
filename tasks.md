# Tasks Checklist: Asphalt Emissions Choropleth Map

## Data Handling
- [ ] Create `data/` folder in script
- [ ] Download EPA Excel file if missing (binary mode)
- [ ] Read "Output - State" sheet with `.name_repair = "unique_quiet"`
- [ ] Extract State and Total kg/person columns
- [ ] Normalize state names to lowercase
- [ ] Convert emissions values to numeric (suppress warnings)
- [ ] Print success message after data read
- [ ] Validate data integrity

## Map Development
- [ ] Load usmap package and retrieve us_map() data
- [ ] Handle sf object format (geom column for usmap ≥ 0.7.0)
- [ ] Normalize state names in map data to lowercase
- [ ] Merge emissions data with map data
- [ ] Validate merge completeness (all 50 states + DC)
- [ ] Create color scale function (green → yellow → red)
- [ ] Build base map with usmap::plot_usmap()
- [ ] Add ggplot layers for color fill and state borders
- [ ] Style state borders with grey and appropriate linewidth
- [ ] Set white background

## Visualization Details
- [ ] Add title including "(2018)"
- [ ] Add descriptive subtitle
- [ ] Add caption with EPA data source
- [ ] Remove x-axis title and labels
- [ ] Remove y-axis title and labels
- [ ] Remove axis ticks
- [ ] Ensure colors are vivid and distinct (not washed out)

## Output & Files
- [ ] Create `plots/` folder in script
- [ ] Save map as PNG file
- [ ] Create README.md with map image link
- [ ] Add research paper citation to README
- [ ] Include DOI link in README
- [ ] Add Project Structure section to README
- [ ] Link all markdown files in README
- [ ] Create walkthrough.md with step-by-step guide
- [ ] Create tasks.md (this file)
- [ ] Create plan.md
- [ ] Create .gitignore for R projects
- [ ] Exclude VS Code and RStudio metadata
- [ ] DO NOT exclude data/ or plots/ folders

## Testing & Validation
- [ ] Verify both data/ and plots/ folders are created
- [ ] Check data download and read successfully
- [ ] Validate state name matching (lowercase comparison)
- [ ] Confirm all 50 states merge correctly
- [ ] Verify color scale renders properly
- [ ] Check PNG file output and quality
- [ ] Test error handling for missing downloads
- [ ] Verify all documentation files complete
- [ ] Check links in README work correctly
