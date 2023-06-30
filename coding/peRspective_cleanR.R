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
models2run <- c("TOXICITY","SEVERE_TOXICITY","IDENTITY_ATTACK","INSULT","PROFANITY",
                "SEXUALLY_EXPLICIT","THREAT","FLIRTATION","ATTACK_ON_AUTHOR","INFLAMMATORY",
                "OBSCENE")


### now apply perspective 
unc_df_persp <- unc_df %>%
  prsp_stream(text = comment,
              text_id = row_id,
              score_model = models2run)

