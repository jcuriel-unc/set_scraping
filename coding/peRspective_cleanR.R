###############################################################################
######## peRspective on UNC script ##############################################
################################################################################
### load in packages 
library(tidyverse) ## for efficient cleaning of data frames 
library(wru) ## for predicting race of profs 
library(foreign) ## for reading in of csv files and such 
library(rstudioapi) ## for efficient grabbing of working directory info 
library(ggplot2) ## for cool plots 
library(irr)
library(arm)
library(peRspective)
library(grid)

###setting directory 
main_wd <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(main_wd)


### api key
pr_api <- "AIzaSyBcW836khRPsqS-Fkkm7P0LNfk4B98_sZ0"


### attempt to make use of api key 
Sys.setenv(perspective_api_key = pr_api)

### read in the UNC data 
unc_df <- read.csv("faculty characteristics web scraping - unc_comments_koen.csv")

###apply row id 
unc_df$row_id <- rownames(unc_df)

###grab models of interest 
models2run <- c("TOXICITY","SEVERE_TOXICITY","INSULT")


### now apply perspective 
unc_df_persp <- unc_df %>%
  prsp_stream(text = comment,
              text_id = row_id,
              score_model = models2run)
saveRDS(unc_df_persp, "perspective_unc_data.rds")

summary(unc_df_persp)

quantile(unc_df_persp$TOXICITY, seq(0,1,by=0.05))

### lets split this into 2, and then upload to google sheets, above and below 0.02
### merge back on the UNC data 
unc_df2 <- merge(unc_df,unc_df_persp, by.x = "row_id", by.y="text_id" )


### now we want to figure out data that will be cut 
length(which(unc_df2$TOXICITY<0.02))# 899 ; 65% of data can be cut 

### apply field 
unc_df2$above_threshold <- 0 
unc_df2$above_threshold[unc_df2$TOXICITY > 0.02] <- 1 

### now exclude the fields for blindness purposes 
unc_df2 <- subset(unc_df2, select=-c(TOXICITY,SEVERE_TOXICITY,INSULT))


### write out a csv to be safe 
write.csv(unc_df2, "unc_comment_data_with_persp.csv", row.names = F)
unc_df2 <- read.csv("unc_comment_data_with_persp.csv")

### re read in the data from Gabe and update 
rmp_ratings <- read.csv("thumbs_master_unc_data_comments.csv")

### looks like the data is missing the ID fields. We will see what we can do with the comment data. 
nrow(unc_df2) 
nrow(rmp_ratings)
### they are different lengths. Will need to see whats going on 
unc_df3 <- merge(unc_df2, rmp_ratings , by="comment")
### the above did not work. We will need to try again 


library(xtable)

xtable(unc_df_persp[1:5,1:4])

## anova script from gpt

# Example data
group1 <- c(5, 6, 7, 8, 9)
group2 <- c(2, 4, 6, 8, 10)
group3 <- c(3, 6, 9, 12, 15)

# Combine the data into a data frame
data <- data.frame(
  value = c(group1, group2, group3),
  group = rep(c("Group 1", "Group 2", "Group 3"), each = 5)
)

# Perform ANOVA
result <- aov(value ~ group, data = data)

# Print the ANOVA table
print(summary(result))

library(stargazer)

