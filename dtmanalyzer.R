##############################################################################################################################################################
#### Calculate surface structure from DTM ####
# Smooths the DTM and then substracts the original DTM. Suitable for finding skid trails in forests and other ground structures.
# R.Bienz / 05.09.2025
##############################################################################################################################################################
#### Setup ####
library(imager)
library(terra)

print(paste("Current working directory:",getwd()))

dir.create(paste0(getwd(),"/temp/"), recursive = T)
terraOptions(tempdir= paste0(getwd(),"/temp/"))

path_out_tiles <- "results/groundstrucutre_tiles/"
dir.create(path_out_tiles, recursive = T)

##############################################################################################################################################################
#### Import of DTM-Files ####
path_tiles <- "data/"
tile_files <- list.files(path_tiles, pattern = "\\.tif$", full.names = FALSE)
print(paste("Number of files:",length(tile_files)))

##############################################################################################################################################################
#### Calculate structure for each tile ####
process_tile <- function(tile_name, path_tiles, path_out_tiles) {
  # Load the tile
  tile_path <- paste0(path_tiles,tile_name)
  output_path <- file.path(path_out_tiles, paste0("groundstr_",basename(tile_path)))
  if (!file.exists(output_path)){
    tile <- rast(tile_path)
  
    ### Convert to cimg ###
    dtm_img <- as.cimg(t(matrix(tile[],ncol = ncol(tile),byrow = T)))
    dtm_img[is.na(dtm_img)] <- 0
    
    ### Smoothing surface and substract DTM ###
    dtm_iso <- isoblur(dtm_img,5)
    dtm_iso <- dtm_img-dtm_iso
    dtm_iso[dtm_iso<(-0.5)] <- -0.5 # Set all values < -1 to -1
    dtm_iso[dtm_iso>0.5] <- 0.5 # Set all values > 1 to 1
    
    ### Convert to raster ###
    difference <- rast(matrix(dtm_iso[],ncol = ncol(tile),byrow=T))
    
    ### Assign coordinate system and export ###
    crs(difference) <- crs(tile)
    ext(difference) <- ext(tile)
  
    ### Rescale to values between 0 and 62
    final_tile_res <- (difference+1) * 31
    
    # Save the processed tile
    writeRaster(final_tile_res, output_path, overwrite = TRUE, datatype = "INT1U")
  }
}

# Apply the processing to all tiles
lapply(tile_files, function(x) {
  message("Processing: ", x)
  process_tile(x, path_tiles, path_out_tiles)
})
##############################################################################################################################################################
#### Read all tiles and build one file ####
combine_rasters <- function(path_input, path_output){
  files_diff<-list.files(path=path_input,pattern="*.tif$", full.names=T)
  rlist <- list()
  for (i in files_diff){
    ras <- rast(i)
    rlist[[length(rlist)+1]] <- ras
  }
  if (length(rlist)>0){
    rsrc <- sprc(rlist)
    mosaic(rsrc, filename=path_output, fun="max",datatype = "INT1U", overwrite=T)
    print("All rasters combined.")
  }  else { print("No rasters found.")}
}

combine_rasters(path_out_tiles, "results/groundstructure.tif")

# delete temporary files
unlink("temp", recursive = TRUE)







