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
library(arm)
###setting directory 
main_wd <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(main_wd)

##1100 

### Read in the csv data 
local_files <-list.files(full.names=T)
local_files <- local_files[grepl(".csv",local_files)] ## subset to only include csv files 

## read in the final data 
gabe_coms <- read.csv(local_files[grepl("gabe", local_files) & grepl("final", local_files)])
koen_coms <- read.csv(local_files[grepl("koen", local_files) & grepl("final", local_files)]) 

### since dealing with the final data, should be good to go. 

### now subset to include only first 1100  
#gabe_coms <- gabe_coms[1:1100,]
#koen_coms <- koen_coms[1:1100,]

dim(gabe_coms) ## 33 cols, 2800 rows  
sum(is.na(gabe_coms$out_emo_lang)==T) # no missing 
sum(is.na(koen_coms$out_emo_lang)==T) # no missing 

# gabe_coms$out_emo_lang[is.na(gabe_coms$out_emo_lang)==T] <- 0

### lets create an aggregate index of the dims of interest 
koen_coms$outrage_agg <- rowSums(koen_coms[,grepl("out_", colnames(koen_coms))])
koen_coms$personal_attack_agg <- rowSums(koen_coms[,grepl("pa_", colnames(koen_coms))])
koen_coms$prejudice_agg <- rowSums(koen_coms[,grepl("pb_", colnames(koen_coms))])
### now same for Gabe 
gabe_coms$outrage_agg <- rowSums(gabe_coms[,grepl("out_", colnames(gabe_coms))])
gabe_coms$personal_attack_agg <- rowSums(gabe_coms[,grepl("pa_", colnames(gabe_coms))])
gabe_coms$prejudice_agg <- rowSums(gabe_coms[,grepl("pb_", colnames(gabe_coms))])


## get rid of thumbs data 
gabe_coms <- subset(gabe_coms, select=-c(thumbs_up,thumbs_down))
koen_coms <- subset(koen_coms, select=-c(thumbs_up,thumbs_down))

### good; note that the rows of coding comments starts at 9 
### We should be able to loop through all of these 

###create a df to store this info in 
irr_df <- as.data.frame(matrix(nrow=26,ncol=6))
colnames(irr_df) <- c("item","kappa_score","z_score","p_value","gabe_num","koen_num")

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
  irr_df$gabe_num[i] <- sum(gabe_coms[i+8]) ## storing # of instances
  irr_df$koen_num[i] <- sum(koen_coms[i+8])
  

}


colSums(gabe_coms[,9:31])
colSums(koen_coms[,9:31])

### good. Let's take a look at the df 
View(irr_df) ### these will all be NA if everything is 0; need variance 

#### save the irr file 
write.csv(irr_df, "interrel_final.csv", row.names=F)


### let's add these and then take the average 
combined_matrix <- koen_coms[9:ncol(koen_coms)] + gabe_coms[9:ncol(gabe_coms)] ## adding together

#combined_matrix <- combined_matrix/2 ## finding average score 
class(combined_matrix) ## good, still data frame 

### going with 0 as not present, 1 = somewhat, 2 = present 

### find summary 
summary(combined_matrix)

### now let's rebind 

final_df <- cbind(koen_coms[,1:8], combined_matrix)

### let's clean a bit 
## removing all upper case instances 
final_df$comment <- str_replace_all(final_df$comment,final_df$prof_lastname,"")
final_df$comment <- str_replace_all(final_df$comment,final_df$prof_firstname,"")
## removing all title case 
final_df$comment <- str_replace_all(final_df$comment,str_to_title(final_df$prof_lastname),"")
final_df$comment <- str_replace_all(final_df$comment,str_to_title(final_df$prof_firstname),"")
## removing all lower case 
final_df$comment <- str_replace_all(final_df$comment,str_to_lower(final_df$prof_lastname),"")
final_df$comment <- str_replace_all(final_df$comment,str_to_lower(final_df$prof_firstname),"")
### now let's export as csv 
write.csv(final_df, "text_cleaning_data/scored_rmp_data_osu_final.csv", row.names = F)

### find the corr of the constructive v not 

cor(final_df$constructive, (final_df$outrage_agg+final_df$prejudice_agg+final_df$personal_attack_agg))

#View(combined_matrix)



### Let's find these diffs 

diff_mat <- koen_coms[,9:34] - gabe_coms[9:34]
View(diff_mat)


### Subset out the comments 
diff_mat$row_number <- row_number(diff_mat)
View(diff_mat)


write.csv(diff_mat, "diff_mat_first1100.csv", row.names = F)


### lets do practice logit 

log_seq <- seq(-100,100,by=1)

output_logit <- invlogit(log_seq)


## now plot 

test_log_plot <- plot(log_seq,output_logit,xlim=c(-5,5),ylim=c(0,1), xlab="Buckeyes consumed",
                      ylab="Prob of attack by badger",
                      main="Evidence of badgers seeking sugar")

### I will read in zip wru ext
library(zipWRUext2)
zip_seq <- unique(zip_all_census2$zcta5)
seq_tes<-seq(0,length(zip_seq),by=1)


##actions 
action_seq <- c("Commiting theft", "eating a hedgehog", "cursing in front of a child",
                "opening neighbor's mail", "majoring in pharmacy","advertising asbestos cars",
                "creating twitter bots","suing the military","blaspheming the infinite celestial camel")

for (i in 1:length(seq_tes)) {
  Sys.sleep(2)
  print(paste0("Badger",sep=" ", i,sep=" ", "found in ZIP code ", sample(zip_seq,1),
               sep= " ", action_seq[sample(seq(1,length(action_seq),by=1),1)] ))
  
}
