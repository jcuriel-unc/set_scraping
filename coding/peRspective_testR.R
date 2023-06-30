###############################################################################
######## peRspective test script ##############################################
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

### models of interest
peRspective::prsp_models
## link to manual - https://cran.r-project.org/web/packages/peRspective/peRspective.pdf

## these can be found on page 3 

## models in production - estimates toxicity and severe toxicity 

## experimental models - identity attack, insult, profanity, threat, sexually explicit, and flirtation

## New York Times moderation models - attack on author, attack on commenter (relevant only for RMP),
# inchoerent, inflamatory, likely to reject (general censoring of comment based on NYT algorithm), 
# obscene, spam, unsubstantial (seems akin to general comments)

### will need to read in each model separately; can ignore those not relevant 

## will first have to run form_request I believe 

## follow this up with prsp_score

## GET TOXICITY and SEVERE_TOXICITY Scores for each sentence of a comment
## Create a mock tibble
text_sample <- tibble(
  ctext = c("You wrote this? Wow. This is dumb and childish, please go f**** yourself.",
            "I don't know what to say about this but it's not good. The commenter is just an idiot",
            "This goes even further!",
            "What the hell is going on?",
            "Please. I don't get it. Explain it again",
            "Annoying and irrelevant! I'd rather watch the paint drying on the wall!"),
  textid = c("#efdcxct", "#ehfcsct",
             "#ekacxwt", "#ewatxad",
             "#ekacswt", "#ewftxwd")
)
## check class 
class(text_sample) # is a data frame; can be manipulated with tidyverse

### attempt to make use of api key 
Sys.setenv(perspective_api_key = pr_api)

## note: I have budget alerts, which trigger at $50. According to general API features, I can expect a 
# max of $30 per 1000 requests. Therefore, I should be able to keep this fairly straight forward I believe 

## GET TOXICITY and SEVERE_TOXICITY Scores for a dataset with a text column

var_run = readline(prompt =  "Enter yes (lowercase) to run sample code ") 

if(var_run=="yes"){
  text_sample %>%
    prsp_stream(text = ctext,
                text_id = textid,
                score_model = c("TOXICITY", "SEVERE_TOXICITY"))
}else{
  print("Did not run the sample test code; be sure to carefully budget.")
}

### now, read in the data from the first 1100 observations. 

rmp_df <- read.csv("text_cleaning_data/scored_rmp_data06212023.csv")
###create ID based on row number 
rmp_df$row_id <- rownames(rmp_df)


### good, now let's subset (so as to not have too many charges)

rmp_df_sub <- subset(rmp_df, outrage_agg > 0 | personal_attack_agg > 0 | prejudice_agg > 0)
dim(rmp_df_sub) # have 171 rows. Not terrible for a test 

## check for duplicate cols 

rmp_df_sub$dum=1
rmp_df_sub <- rmp_df_sub %>%
  group_by(row_id) %>%
  mutate(duplicate=sum(dum))
diag_sub <- subset(rmp_df_sub, duplicate>1) # no duplicates; good 

## look at the api models again 
peRspective::prsp_models

models2run <- c("TOXICITY","SEVERE_TOXICITY","IDENTITY_ATTACK","INSULT","PROFANITY",
                "SEXUALLY_EXPLICIT","THREAT","FLIRTATION","ATTACK_ON_AUTHOR","INFLAMMATORY",
                "OBSCENE")

length(models2run) ## 11. Therefore, running the full model would lead to over 10 times charges. Therefore,
# very likely to build up in one sitting. We will therefore want to be very careful in how we use this. Still,
# potentially very useful, as we should be able to see how this correlates with our own work. 

### now lets create a model 

var_run_actual_model = readline(prompt = "This is to run the model on the actual data. Type in YES 
                                if you are certain you'd like to run this, remembering the $30 per 1000
                                request limit. ")

### excellent! This actually works! Now I will run on the rest of the comments, while also reporting the time
## first run was test_output
if(var_run_actual_model=="YES"){
  start_time <- Sys.time()
  persp_rmp_output <- rmp_df_sub %>%
    prsp_stream(text = comment,
                text_id = row_id,
                score_model = models2run)
  end_time <- Sys.time()
  ## print out total time output 
  end_time - start_time
  
}else{
  "Did not run the actual model due to user input. "
}
#View(persp_rmp_output)

## Get the columns summed 

persp_rmp_output$aggregate_outrage <- (rowSums(persp_rmp_output[2:length(models2run)])/length(models2run))*100
##View(persp_rmp_output)

### now lets randomly sample the non outrage 

rmp_df_sub_nontoxic <- subset(rmp_df, outrage_agg == 0 & personal_attack_agg == 0 & prejudice_agg == 0)

set.seed(1337)
rmp_df_sub_nontoxic_sample <- sample_n(rmp_df_sub_nontoxic, nrow(persp_rmp_output))

### user prompt to run placebo model 
var_run_actual_model_nt = readline(prompt = "This is to run the model on the actual data. Type in YES 
                                if you are certain you'd like to run this, remembering the $30 per 1000
                                request limit. This is for the placebo data set.")

### now lets run the loop again, this time with the data from the non toxic sample
if(var_run_actual_model_nt=="YES"){
  start_time <- Sys.time()
  persp_rmp_output_nt <- rmp_df_sub_nontoxic_sample %>%
    prsp_stream(text = comment,
                text_id = row_id,
                score_model = models2run)
  end_time <- Sys.time()
  ## print out total time output 
  end_time - start_time
  
}else{
  "Did not run the actual model due to user input. "
}

persp_rmp_output_nt$aggregate_outrage <- 
  (rowSums(persp_rmp_output_nt[2:length(models2run)])/length(models2run))*100

### let's bind on the data 
persp_rmp_output$coded_toxic <- 1
persp_rmp_output_nt$coded_toxic <- 0   

persp_all_output <- rbind(persp_rmp_output,persp_rmp_output_nt)


###save this data for now 
saveRDS(persp_all_output, "peRspective_data_test_run06242023.rds")
persp_all_output <- readRDS("peRspective_data_test_run06242023.rds")

## subset again, just in case 
persp_rmp_output_nt <- subset(persp_all_output,coded_toxic==0 )
persp_rmp_output <- subset(persp_all_output,coded_toxic==1 )

### now let's merge the data 

rmp_df_persp_sub <- merge(persp_all_output, rmp_df,by.x="text_id", by.y="row_id")
nrow(rmp_df_persp_sub) ## looks like a success 

View(rmp_df_persp_sub)

## write out csv 

write.csv(rmp_df_persp_sub, "sample_peRspective_coded342obs.csv", row.names = F )
rmp_df_persp_sub <- read.csv("sample_peRspective_coded342obs.csv")

### let's create a ggplot comparing these 

ggplot_persp <- ggplot(rmp_df_persp_sub, aes(x=aggregate_outrage,fill=as.factor(coded_toxic))) +
  geom_density(alpha=0.4) + #### very important command; makes the CIs 
  theme_minimal() + ## cleans up the presentation of the plot 
  labs(title="Comparison of normalized aggregation of peRspective scoring",
       x="Normalized peRspective aggregate scores", y="Density", 
       caption=paste0("This plot was generated on ", Sys.Date(),sep="\n",
                      "By the Ohio Northern University SET-SURF Center."))+
  scale_fill_discrete(name = "Manual coding", labels = c("Not toxic", "Toxic"))

ggplot_persp

## check quantiles 
## first, non toxic 
quantile(persp_rmp_output_nt$aggregate_outrage, seq(0,1,by=0.05))
## given sample, about 85% of data falls below 15 for non toxic threshold. Over 95% 
# fall below a score of 20. Cool 
quantile(persp_rmp_output$aggregate_outrage, seq(0,1,by=0.05))
## given the first 1100 coded comments and those at least 1 on one of the dimensions, about half 
# of the data is above 15. Additionally, approximately 35% of data are above 20. THerefore, seems like 
#given this sample, we'd want to go with a cutoff between these two.

## Let's check the toxic dim alone 
quantile(persp_rmp_output$TOXICITY, seq(0,1,by=0.05))
quantile(persp_rmp_output_nt$TOXICITY, seq(0,1,by=0.05)) ## looking at non toxic, there is a big jump at 
# the 85th pct to 90th pct, and 90th to 95th. What's going on? Let's check 
quantile(persp_rmp_output_nt$TOXICITY, seq(0.85,1,by=0.01))
## looks like 92.5 and 94.5 are the big jumps. Let's check the comments of inteterest 

persp_rmp_output_nt_false_pos <- subset(persp_rmp_output_nt, TOXICITY > 0.148)
persp_rmp_output_nt_false_pos$text_id # length of 12 

## what about above the 30% threshold? Top 95% of comments 
persp_rmp_output_nt_false_pos2 <- subset(persp_rmp_output_nt, TOXICITY > 0.3)
persp_rmp_output_nt_false_pos2$text_id # 9, with 1st 4 the same, then 6, 7, 9, 10, 11

rmp_df_persp_sub$comment[rmp_df_persp_sub$text_id==persp_rmp_output_nt_false_pos$text_id[1]]
rmp_df_persp_sub$comment[rmp_df_persp_sub$text_id==persp_rmp_output_nt_false_pos$text_id[2]]
rmp_df_persp_sub$comment[rmp_df_persp_sub$text_id==persp_rmp_output_nt_false_pos$text_id[3]]
## 3 is definitely neg and not constructive 
rmp_df_persp_sub$comment[rmp_df_persp_sub$text_id==persp_rmp_output_nt_false_pos$text_id[4]] #this is odd 
rmp_df_persp_sub$comment[rmp_df_persp_sub$text_id==persp_rmp_output_nt_false_pos$text_id[5]] # Hell is trigger
rmp_df_persp_sub$comment[rmp_df_persp_sub$text_id==persp_rmp_output_nt_false_pos$text_id[6]] # pos, but 
# critiquing those who cannot do well in the class 
rmp_df_persp_sub$comment[rmp_df_persp_sub$text_id==persp_rmp_output_nt_false_pos$text_id[7]] # ibid
rmp_df_persp_sub$comment[rmp_df_persp_sub$text_id==persp_rmp_output_nt_false_pos$text_id[8]] # defn critical,
# and negative. Not constructive 
rmp_df_persp_sub$comment[rmp_df_persp_sub$text_id==persp_rmp_output_nt_false_pos$text_id[9]] # very neg 
rmp_df_persp_sub$comment[rmp_df_persp_sub$text_id==persp_rmp_output_nt_false_pos$text_id[10]] # mixed, not 
# constructive 
rmp_df_persp_sub$comment[rmp_df_persp_sub$text_id==persp_rmp_output_nt_false_pos$text_id[11]] # this should 
# actually be an insult in my mind 
rmp_df_persp_sub$comment[rmp_df_persp_sub$text_id==persp_rmp_output_nt_false_pos$text_id[12]] # neg on boring,
# and not constructive 

## the 30th pct gets rid of Hell one, the one about bored tone and take diff prof, and kind but boring one 
# at end 
### overall, these seem to suggest that the threshold of .15 is probably sufficient, especially since 
# there are unlikely to be attacks on other students 


## save ggplot 
ggsave("aggregate_perspective_plot_06242023.png" ,ggplot_persp, 
       scale=1,width=9,height=6,units = c("in"), dpi=400,bg="white")



## get total aggregate 
rmp_df_persp_sub$manual_agg <- rmp_df_persp_sub$personal_attack_agg+rmp_df_persp_sub$prejudice_agg+
  rmp_df_persp_sub$outrage_agg

### let's randomly sample based on vals 

text_sample <- rmp_df_persp_sub %>%
  group_by(round(manual_agg,0)) %>%
  sample_n(1)


### now, let's find the correlation between the overall scoring manually and the API 

ggplot_persp_corr <- ggplot(rmp_df_persp_sub, aes(x=manual_agg,y=aggregate_outrage,
                                                  group=as.factor(coded_toxic),
                                             col=as.factor(coded_toxic))) +
  geom_point() +
  theme_minimal() + ## cleans up the presentation of the plot 
  labs(title="Comparison of correlation of manual coding \n on peRspective scores, normalized",
       x="Aggregated manual coding of comments", y="Density", 
       caption=paste0("This plot was generated on ", Sys.Date(),sep="\n",
                      "By the Ohio Northern University SET-SURF Center."))+
  scale_color_discrete(name = "Manual coding", labels = c("Not toxic", "Toxic")) +
  stat_smooth(method = "lm",
              formula = y ~ x,
              geom = "smooth")
## old text code 
#geom_text(data=text_sample, aes(label=comment,x=manual_agg,y=aggregate_outrage,
#                                group=as.factor(coded_toxic),
#                                col=as.factor(coded_toxic)),size=0.9) 

### export this 
ggplot_persp_corr

## save ggplot 
ggsave("coding_perspective_corr_plot_06242023.png" ,ggplot_persp_corr, 
       scale=1,width=9,height=6,units = c("in"), dpi=400,bg="white")

### find corr 
cor(rmp_df_persp_sub$manual_agg,rmp_df_persp_sub$aggregate_outrage) # 0.5197896

## let's do a simple linear model 
test_lm <- lm(aggregate_outrage ~ manual_agg, data=rmp_df_persp_sub)
summary(test_lm) # explains 26.8 percent of the variance; not bad 


### check the nature of the toxicity 

## 0.05 would be the 85th pct for non toxic. It would be the 20th pct for toxic. If we assume a 15% prev 
# for toxicity, and 85 for non toxic, this means 
850*.15 #  127.5 are coded as FP 
150*.8 # 120 for toxic are TP 
## still a high rate; we'd need to discount some of the outliers 

### now lets create a folder for plots then save a loop to there 


for (i in 1:length(models2run)) {
  rmp_df_persp_sub$temp_var <- rmp_df_persp_sub[models2run[i]]
  rmp_df_persp_sub$temp_var <- unlist(rmp_df_persp_sub$temp_var)
  ## report medians 
  toxic_median <- rmp_df_persp_sub %>%
    group_by(coded_toxic) %>%
    summarize(quantile(temp_var, 0.5))
  ### get median and place in text 
  toxic_med0 = round(as.numeric(toxic_median[1,2]),2)
  toxic_med1 =  round(as.numeric(toxic_median[2,2]),2)
  ### create labels 
  header_label <- grobTree(textGrob("Median values", x=0.7,  y=0.95, hjust=0,
                                        gp=gpar(col="black", fontsize=10, fontface="italic"))) 
  notox_label <- grobTree(textGrob(paste0("Manual non-toxic: ",toxic_med0), x=0.7,  y=0.85, hjust=0,
                                   gp=gpar(col="#F8766D", fontsize=8))) 
  tox_label <- grobTree(textGrob(paste0("Manual toxic: ",toxic_med1), x=0.7,  y=0.75, hjust=0,
                                   gp=gpar(col="#00BFC4", fontsize=8))) 
  ### now plot 
  ggplot_persp_temp <- ggplot(rmp_df_persp_sub, aes(x=temp_var,fill=as.factor(coded_toxic))) +
    geom_density(alpha=0.4) + #### very important command; makes the CIs 
    theme_minimal() + ## cleans up the presentation of the plot 
    labs(title=paste0("Comparison of normalized aggregation of peRspective \n ", models2run[i], sep=" ",
                      "dimension") ,
         x=paste0("Probability on peRspective ", models2run[i], sep=" ", "dimension"), y="Density", 
         caption=paste0("This plot was generated on ", Sys.Date(),sep="\n",
                        "By the Ohio Northern University SET-SURF Center."))+
    scale_fill_discrete(name = "Manual coding", labels = c("Not toxic", "Toxic")) +
    scale_x_continuous(limits = c(0, 1)) + 
    annotation_custom(header_label) + annotation_custom(notox_label) +
    annotation_custom(tox_label)
## plot out 
  ggplot_persp_temp
  ## now save 
  sv_name = paste0("plots/comparison",sep="_",models2run[i],sep=".png")
  ggsave(sv_name ,ggplot_persp_temp, 
         scale=1,width=9,height=6,units = c("in"), dpi=400,bg="white")
}


### check insult as well 
quantile(persp_rmp_output_nt$INSULT,seq(0,1,by=0.05)) # so, big jumps at 90th to 95th, and 
# 95th to 100 
quantile(persp_rmp_output$INSULT,seq(0,1,by=0.05)) # If we go with a threshold of 0.1, we exclude 95% of the 
# non toxic, and 50% of toxic. let's check what these are, though 

test_sub <- subset(rmp_df_persp_sub,INSULT < 0.1 & coded_toxic==1 )
test_sub2 <- subset(rmp_df_persp_sub,INSULT > 0.1 & coded_toxic==1 )

rmp_df$comment[rmp_df$row_id== test_sub$text_id[1]]

summary(test_sub$manual_agg) # so a median of 2, and 75th of 2  
quantile(test_sub$manual_agg, seq(0,1,by=0.05)) # 8-th pct are 3+ 
quantile(test_sub2$manual_agg, seq(0,1,by=0.05)) # 50th of 3; 

### let's try finding out those obs either or on these dimensions 

length(which(persp_rmp_output$INSULT>0.1 | persp_rmp_output$TOXICITY > 0.05 ))/nrow(persp_rmp_output)
### we'd get 78%

### what about the non toxic? 
length(which(persp_rmp_output_nt$INSULT>0.1 | persp_rmp_output_nt$TOXICITY > 0.05 ))/nrow(persp_rmp_output_nt)
# we'd be getting 16% 


quantile(persp_rmp_output_nt$SEVERE_TOXICITY,seq(0,1,by=0.05))# max of 0.02. not much 

### what about the toxic data? 
quantile(persp_rmp_output$SEVERE_TOXICITY,seq(0,1,by=0.05))# max of 0.02. not much 
### might be able to use this as a way to bolster the scores? 


 
