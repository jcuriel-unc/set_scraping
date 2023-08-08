###############################################################################
######## SET Precision and Recall CalculatR ##############################################
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
library(stargazer)
###setting directory 
main_wd <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(main_wd)

### read in the open ai data and such 
ml_models_set_df <- read.csv("openai_predictions.csv")

### let's find some corrs 
complete_lm <- lm((TOXICITY2)*100 ~ total_toxicity, data=ml_models_set_df)
summary(complete_lm)

### now lets try the openai data 
openai_lm <- lm((openai_is_toxic)*100 ~ total_toxicity, data=ml_models_set_df)
summary(openai_lm) ## r-squared of 16; half that of the peRspective data; goes in right direction  

### plot out the data of interest 
ggplot_persp_corr_all <- ggplot(ml_models_set_df, aes(x=total_toxicity,y=(TOXICITY2)*100,
                                                  group=as.factor(coded_toxic),
                                                  col=as.factor(coded_toxic))) +
  geom_point() +
  theme_minimal() + ## cleans up the presentation of the plot 
  labs(title="Comparison of correlation of manual coding \n on peRspective scores",
       x="Aggregated manual coding of comments", y="peRspective Toxicity score", 
       caption=paste0("X-axis reflects the average of the two coders. /n 
                      R-squared = 0.3133, coef = 10.66, p<0.01"))+
  scale_color_discrete(name = "Manual coding", labels = c("Not toxic", "Toxic")) + ylim(0,100)+
  stat_smooth(method = "lm",
              formula = y ~ x,
              geom = "smooth")
ggplot_persp_corr_all

### now open ai here 
ggplot_openai_corr_all <- ggplot(ml_models_set_df, aes(x=total_toxicity,y=(openai_is_toxic)*100,
                                                      group=as.factor(coded_toxic),
                                                      col=as.factor(coded_toxic))) +
  geom_point() +
  theme_minimal() + ## cleans up the presentation of the plot 
  labs(title="Comparison of correlation of manual coding \n on open AI scores",
       x="Aggregated manual coding of comments", y="open AI Toxicity score", 
       caption=paste0("X-axis reflects the average of the two coders. /n 
                      R-squared = 0.1626, coef = 8.3480, p<0.01"))+
  scale_color_discrete(name = "Manual coding", labels = c("Not toxic", "Toxic")) + ylim(0,100)+
  stat_smooth(method = "lm",
              formula = y ~ x,
              geom = "smooth")
ggplot_openai_corr_all
### lets ggsave here 

ggsave("plots/complete_perspective_corr_plot.png" ,ggplot_persp_corr_all, 
       scale=1,width=9,height=6,units = c("in"), dpi=400,bg="white")
ggsave("plots/complete_openai_corr_plot.png" ,ggplot_openai_corr_all, 
       scale=1,width=9,height=6,units = c("in"), dpi=400,bg="white")

### good. Now can find reliability (f1) scores and such 

