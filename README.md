# Surface Structure Extraction from DTM
This R script processes Digital Terrain Model (DTM) tiles to highlight ground structures such as skid trails in forests. It smooths the DTM, subtracts the original values, rescales the results, and outputs both individual processed tiles and a combined raster.

The example data was kindly provided by the Kanton of Aargau.


---

## Requirements
**R packages**:  
- [`imager`](https://cran.r-project.org/package=imager)  
- [`terra`](https://cran.r-project.org/package=terra)

---

## Usage
1. Place your DTM tiles (`.tif`) into the `data/` folder.
2. Run the script in R.
3. Results will be saved in:
   - `results/groundstrucutre_tiles/` → processed per-tile rasters  
   - `results/groundstructure.tif` → final merged raster

---

## Author
Script by [**R. Bienz**](https://waldfride-analytics.ch/), 03.10.2025