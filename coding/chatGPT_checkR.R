###############################################################################
######## chatGPT validation script ##############################################
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

## load in data 
chatgpt_df <- read.csv("ml_applied2sample_peRspective_coded342obs.csv")
names(chatgpt_df)

###let's find the correlation between these
misrep_sub <- subset(chatgpt_df,select=c(text_id,out_misrep,openai_is_misrep_prob,openai_somewhat_misrep_prob,
                                         openai_not_misrep_prob))
### now change to long 
misrep_sub_long = misrep_sub %>% 
  gather(key=type,value=probability, -c(text_id,out_misrep) )

## now categorize
misrep_sub_long$group <- "Not misrepresentation"
misrep_sub_long$group[misrep_sub_long$type=="openai_is_misrep_prob"] <- "Misrepresentation"
misrep_sub_long$group[misrep_sub_long$type=="openai_somewhat_misrep_prob"] <- "Somewhat Misrepresentation"


### that worked. Now let's find the IQR. 
misrep_sub_long_iqr <- misrep_sub_long %>%
  group_by(out_misrep,group) %>%
  summarize(med_prob = median(probability), pct25 = quantile(probability,0.25), 
            pct75=quantile(probability,0.75))


p<-ggplot(data=chatgpt_df, aes(x=dose, y=len)) +
  geom_bar(stat="identity")
p

test_ggplot_reg <- ggplot(misrep_sub_long_iqr, aes(x=out_misrep, y=med_prob, group=as.factor(group),
                                                   col=as.factor(group),fill=as.factor(group))) +
  geom_line(linewidth=1.2) + 
  geom_ribbon(aes(ymin=pct25,ymax=pct75), alpha=0.4) + #### very important command; makes the CIs 
  theme_minimal() 
test_ggplot_reg

### looks like the data did not perform very well. We'll need to hone in and create a better example. Let's 
# use the text id of something very misrep 

