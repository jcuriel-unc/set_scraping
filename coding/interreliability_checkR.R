################################################################################
############## Inter-reliability score checkR ##################################
################################################################################
############## 06/12/2023 - The Great Reddit Blackout ##########################
################################################################################
### load in packages 
library(tidyverse) ## for efficient cleaning of data frames 
library(wru) ## for predicting race of profs 
library(foreign) ## for reading in of csv files and such 
library(rstudioapi) ## for efficient grabbing of working directory info 
library(ggplot2) ## for cool plots 
library(irr)
###setting directory 
main_wd <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(main_wd)

### Read in the csv data 
local_files <-list.files(full.names=T)
local_files <- local_files[grepl(".csv",local_files)] ## subset to only include csv files 

## 
gabe_coms <- read.csv(local_files[2])
koen_coms <- read.csv(local_files[4]) 

### now subset to include only first 15  
gabe_coms <- gabe_coms[1:273,]
koen_coms <- koen_coms[1:273,]

dim(gabe_coms) ## 31 cols 

### lets create an aggregate index of the dims of interest 
koen_coms$outrage_agg <- rowSums(koen_coms[,grepl("out_", colnames(koen_coms))])
koen_coms$personal_attack_agg <- rowSums(koen_coms[,grepl("pa_", colnames(koen_coms))])
koen_coms$prejudice_agg <- rowSums(koen_coms[,grepl("pb_", colnames(koen_coms))])
### now same for Gabe 
gabe_coms$outrage_agg <- rowSums(gabe_coms[,grepl("out_", colnames(gabe_coms))])
gabe_coms$personal_attack_agg <- rowSums(gabe_coms[,grepl("pa_", colnames(gabe_coms))])
gabe_coms$prejudice_agg <- rowSums(gabe_coms[,grepl("pb_", colnames(gabe_coms))])


### good; note that the rows of coding comments starts at 9 
### We should be able to loop through all of these 

###create a df to store this info in 
irr_df <- as.data.frame(matrix(nrow=26,ncol=4))
colnames(irr_df) <- c("item","kappa_score","z_score","p_value")

### assign columns to items 
irr_df$item <- colnames(koen_coms[9:ncol(koen_coms)])

### now store these into the data frame via a loop 


for (i in 1:nrow(irr_df)) { ## starting off with first col of interest 
  temp_df <- cbind(gabe_coms[,i+8],koen_coms[,i+8])
  irr_score <- kappa2(temp_df, weight = "equal") ## note: kappa 2 is for categorical or ordinal data 
  ## store in df 
  irr_df$kappa_score[i] <- irr_score$value
  irr_df$z_score[i] <- irr_score$statistic
  irr_df$p_value[i] <- irr_score$p.value
}

### good. Let's take a look at the df 
View(irr_df) ### these will all be NA if everything is 0; need variance 

### Let's find these diffs 

diff_mat <- koen_coms[,9:34] - gabe_coms[9:34]
View(diff_mat)


### Subset out the comments 
diff_mat$row_number <- row_number(diff_mat)
View(diff_mat)


write.csv(diff_mat, "diff_mat06142023.csv", row.names = F)
