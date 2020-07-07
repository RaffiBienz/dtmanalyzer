##############################################################################################################################################################
#### Calculate ground structure from DTM ####
# Smooths the DTM and then substracts the original DTM. Suitable for finding strip roads in forests and other ground structures.
# R.Bienz / 23.07.2019
##############################################################################################################################################################
library(imager)
library(raster)
library(rgdal)

wd <- getwd() # Define working directory
setwd(wd)

dir.create("temp",showWarnings = F)
dir.create("wd",showWarnings = F)
dir.create("result",showWarnings = F)

rasterOptions(tmpdir= paste0(wd,"/temp/"),todisk=TRUE, progress="text")

##############################################################################################################################################################
#### Import DTM-Files ####
files <- list.files(path="data",pattern="*.tif$") 
for(i in files) {assign(unlist(strsplit(i, "[.]"))[1], raster(paste("data/",i,sep=""))) } # Load Tiles
raster_names <- unlist(strsplit(files,"[.]")) # create name list
raster_names <- raster_names[raster_names!="tif"]

##############################################################################################################################################################
#### Calculate structure for each tile with overlap ####
for(i in 1:length(raster_names)){
  temp <- eval(as.symbol(raster_names[i]))

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
  origin(mag_ras) <- c(0,0)
  writeRaster(mag_ras,filename = paste("wd/",raster_names[i],"_diff.tif",sep=""),overwrite=T)
  
  print(paste(i,"/",length(raster_names)))
}


##############################################################################################################################################################
#### Read all tiles and build one file ####
files_diff<-list.files(path="wd/",pattern="*.tif$")
for(i in files_diff) {assign(unlist(strsplit(i, "[.]"))[1], raster(paste("wd/",i,sep=""))) } 
diff_names <- unlist(strsplit(files_diff,"[.]"))
diff_names <- diff_names[diff_names!="tif"]

raster_list <- list() 
for (i in diff_names){
  raster_list <- append(raster_list,eval(as.symbol(i)))}

raster_list$fun <- mean
mos <- do.call(mosaic, raster_list)
writeRaster(mos,filename="result/dtm_diff_kt.tif",overwrite=T)

# delete temporary files
unlink("temp", recursive = TRUE)


