##############################################################################################################################################################
#### Calculate ground structure from DTM ####
# Smooths the DTM and then substracts the original DTM. Suitable for finding strip roads in forests and other ground structures.
# Calculation by 4x4km tiles (to handle memory problems)
# R.Bienz / 23.07.2019
##############################################################################################################################################################
library(imager)
library(raster)
library(rgdal)
library(future)
plan(multisession,workers=8L) # for multi core processing
setwd("...")
rasterOptions(tmpdir= ".../temp/",todisk=TRUE, progress="text")

##############################################################################################################################################################
#### Import of DTM-Files ####
dtm_kt <- raster("data/DTM_2019_Milan.tif") # Import DTM for whole area. Used for data extraction by clipping extents.
files <- list.files(path="data/DTM/",pattern="*.tif$") # DTM tiles 4x4km. They are only used to define the clipping extents 
for(i in files) {assign(unlist(strsplit(i, "[.]"))[1], raster(paste("data/DTM/",i,sep=""))) } # Load Tiles
raster_names <- unlist(strsplit(files,"[.]"))
raster_names <- raster_names[raster_names!="tif"]

##############################################################################################################################################################
#### Calculate structure for each tile with overlap ####
overlap <- 10 # Define overlap in m to omit edge effects

for(i in 1:length(raster_names)){
  temp_ras <- eval(as.symbol(raster_names[i]))
  clip_ext <- extent(temp_ras)
  clip_ext <- clip_ext +overlap
  temp <- crop(dtm_kt,clip_ext)
  
  ### Convert to cimg ###
  dtm_img <- as.cimg(t(matrix(temp[],ncol = ncol(temp),byrow = T)))
  dtm_img[is.na(dtm_img)] <- 0
  
  ### Method: Smoothing surface and substract DTM ###
  dtm_iso <- isoblur(dtm_img,3)
  dtm_iso <- dtm_img-dtm_iso
  dtm_iso[dtm_iso<(-1)] <- -1 # Set all values < -1 to -1
  dtm_iso[dtm_iso>1] <- 1 # Set all values > 1 to 1
  
  ### Convert back to raster ###
  mag_ras <- raster(matrix(dtm_iso[],ncol = ncol(temp),byrow=T))
  
  ### Assign coordinate system and export ###
  crs(mag_ras) <- crs(temp)
  extent(mag_ras) <- extent(temp)
  mag_ras_crop <- crop(mag_ras,extent(temp_ras)) # clip files to original extent
  writeRaster(mag_ras_crop,filename = paste("wd/",raster_names[i],"_diff.tif",sep=""),overwrite=T)
  
  print(paste(i,"/",length(raster_names)))
}


##############################################################################################################################################################
#### Read all tiles and build one file ####
files_diff<-list.files(path="wd/",pattern="*.tif$")
for(i in files_diff) {assign(unlist(strsplit(i, "[.]"))[1], raster(paste("wd/",i,sep=""))) } 
diff_namen <- unlist(strsplit(files_diff,"[.]"))
diff_namen <- diff_namen[diff_namen!="tif"]

raster_list <- list() 
for (i in diff_namen){
  raster_list <- append(raster_list,eval(as.symbol(i)))}

raster_list$fun <- mean


mos <- do.call(mosaic, raster_list)
writeRaster(mos,filename="result/dtm_diff_kt_over.tif",overwrite=T)



