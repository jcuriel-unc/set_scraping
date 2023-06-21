################################################################################
################# Introduction to R and Regression base file ##################
################################################################################
################# 06/14/2023 ###################################################

## load in packages 
library(tidyverse) ## for efficient cleaning of data frames 
library(stringi) #processing strings
library(stringr) #processing strings; yes, apparently diff 
library(wru) ## for predicting race of profs 
library(foreign) ## for reading in of csv files and such 
library(rstudioapi) ## for efficient grabbing of working directory info 
library(ggplot2) ## for cool plots 
library(irr) #inter reliability package 
library(rstudioapi) ### for directory things 
library(MASS) ### for advancing a Masshole agenda
##nah, actually for simulating and creating pred probs 
######## First step: set the working directory 
###setting directory 
main_wd <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(main_wd)

### first thing to note: object based scripting 

tt <- 5*8
tt
tt*9

## things are stored in objects; fewer limitations in naming than python
## can be done with = or <- 

r.r <- 5*7
r.r # this would weird out python 

#### step 2: understanding objects 

## things can take a variety of forms, like vectors, matrices, data frames, lists, etc. Need to know which you're 
## dealing with 



## vector 

vec_ex <- c(1,2,3,4,5,6,7,8)
vec_ex
class(vec_ex) ## vectors will just state the type of data; can check with is.vector() for boolean statement 
is.vector(vec_ex) ## TRUE 

#### matrix 
N = 100
M = 20
set.seed(1337) ## making replicable 
test_matrix <- matrix( rnorm(N*M,mean=0,sd=1), N, M)  ### new command!!! 
class(test_matrix)
is.matrix(test_matrix)
## what is going on? 
?rnorm ## randomly generates values on normal curve given mean and standard deviation

## matrix() takes a vector and shoves into matrix object given N rows and M columns 
## doesn't work if what's being stored cannot fit in...

bad_matrix <- matrix( rnorm(133,mean=0,sd=1), N, M) ## got warning; let's check 
colSums(is.na(bad_matrix)) ### nothing missing... so what happened? 

### same 133 numbers put into the matrix and repeated, as opposed to unique values 

### Data frame ; just matrices that can be labeled and processed in diff ways 

test_data_frame <- as.data.frame(test_matrix)
class(test_data_frame)
dim(test_data_frame) ## rows then columns 

## check column names? 
colnames(test_data_frame)
## or 
colnames(test_data_frame)

## all v based; let's change 

name_seq <- paste0("col",sep="_",str_pad(seq(1,20,by=1), pad="0",side="left",width=3))
name_seq
### What just happened!?

## str_pad ; fills which ever side of a vector with a "pad" which can be what you specify; important for 
# n digit long numeric vars converted to strings

## seq: creates a vector of numbers from start point, end point, and by (jump) set of numbers 
## example 
test_seq <- seq(1,20,by=1)
test_seq_str <- as.character(test_seq) # converts to string 
test_seq_str
test_seq
### same order; what if we sort by whatever its coded as? 
sort(test_seq)
sort(test_seq_str) ## different order; if string padded? 
sort(str_pad(seq(1,20,by=1), pad="0",side="left",width=3)) #different, but same order 

#### change names now 
colnames(test_data_frame) <- name_seq
names(test_data_frame) ## are different now! same length is important though

## can now call columns as vectors 
test_data_frame$col_002 

## can also do 
test_data_frame[,2]

## and also a specific value
test_data_frame[2,2]

### list objects? irritating, though store lots of things 
list_variable = list(test_seq,test_matrix,test_data_frame)
list_variable ## sloppy way to call everything 

## we can pull from it, though

test_subset1 <- list_variable[[1]]
test_subset1

## the matrix? 

test_subset2 <- list_variable[[2]]
class(test_subset2)

## so yeah, can extract, but usually unnecessary unless you're doing something complex, like creating a package 
# with a giant output 


##### Regressions and such 

### goal : find and quantify correlation between vars 

## do basic descriptive stuff first 

summary(test_data_frame) #figure out the range of values for all the cols 

### let's create an independently distributed y var 

set.seed(2581) ## Gabe's last four ssn digits 
y_var = rnorm(100, mean=0,sd=1)

cor(y_var,test_data_frame$col_001) # 0.05846667

### can we plot this? Yes 

###first: bind data (can only do if same length)
test_data_frame2 <- cbind(y_var, test_data_frame)
colnames(test_data_frame2)### good, it worked 

### Here is where we pull in the "ggplot2" pkg, which is also in python. VERY popular

ggplot(test_data_frame2, aes(col_001,y_var)) + geom_point()

### what's going on with the above? 

?ggplot
#first, provide the data frame. The "aes" command takes the form of first the x axis variable, and then the 
# y axis. The geom_point is one of many extensions to tell the plot how to plot the data 

## what if we wanted to create a linear regression? The lm cmd!!! 
test_model0 <- lm(y_var ~ col_003 + col_004, data = test_data_frame2)

test_model <- lm(y_var ~., data = test_data_frame2)
## syntax note: first comes the dependent variable. the "~" tells to predict by the ensuing vars, with the "." noting 
## all other vars in the data frame 

###take a look at the regression
summary(test_model)


###estimate: the average expected slope
## std. error = standard error
## .s = significant at p<0.1 level; * is p<0.05; ** p<0.01 

## recall that all vars created independently of each other... 


###### presenting results! 
### we want two things: first, the table (usually for appendices) and a nice plot 

###table: use stargazer to export 
library(stargazer)
stargazer(test_model)
### note that tables are silly
stargazer(
  test_model,
  type = "text",
  keep.stat = c("n", "rsq", "adj.rsq"),
  omit = c("Constant"),
  title = "Modeling Spuriousness - OLS Regression",
  out="test_model.html"
)


### now modeling!
## note: most adaptable/cool means is to break down into matrix components 

### first, grab the coef matrix 

test_coef <- coef(test_model)
class(test_coef) # vector, or one row matrix 
test_coef
### the variance covariance matrix!!! 
test_vcov <- vcov(test_model)
class(test_vcov)
dim(test_vcov) ## very important that it is a square 
#'* some colorfull comment *`# 


#### yethe 

### now, let's do some simulations!!!! 
library(MASS)
set.seed(77)
random_beta_draws <- mvrnorm(10000, test_coef, test_vcov)
## arguments: 1) how many draws, 2) the coef matrix, 3) the variance-covariance matrix 

## note: since we did a linear regression, vals can technically be -inf to inf; no need to transform 
## *cough, logistic regressions, cough* ###

### now let's model, based upon col_008, which is sig 

### create a data frame to predict onto 

mean_vals <- apply(test_data_frame, 2, mean) ## what the Hell is this withcraft!? 
mean_vals
## apply fxn takes one function and applies it to every dimension of a df, i.e. either rows or columns
#just tell it the df you want to apply to, 1= rows and 2 = columns, and then the fxn 

###let's make a sequence of column 8 vals 
summary(test_data_frame$col_019) ## let's just do -3 to 3 

pred_seq <- seq(-3,3,by=0.1)
length(pred_seq) ## 61 length...
### now let's make a data frame from that vector 
pred_df <- as.data.frame(replicate(length(pred_seq), mean_vals))
pred_df <- t(pred_df) #transpose, making rows into cols, vice versa 
pred_df <- as.data.frame(pred_df)
###let's take a look at this 
View(pred_df) ## cool! 

## recall, col 8 only has its mean vals; let's replace with the sequence 
pred_df$col_019 <- pred_seq ## must be same length 

## note: we need an intercept 
pred_df <- cbind(1,pred_df)

### ok, now lets bring those simulated betas back in 

### now its time for matrix multiplication 
head(random_beta_draws)
pred_probs <- as.matrix(pred_df) %*% t(random_beta_draws)

View(pred_probs)
## so what do we have? A data frame where each row refelcts an increasing value of column 8 and everything is held
# to its mean. From there, the columns reflect one of 10000 values we simulated for what the beta values could 
# be, which we can collapse and get the 95% CI for col8x on y, and plot the predicted vals 

### time for another apply fxn 

pred_prob_df <-apply(pred_probs, 1,quantile, probs=c(0.025,.5,.975) )
dim(pred_prob_df) 
View(pred_prob_df)


### so we now have a data frame with the range effect of col 8 varying on y. Let's get this plotted out 
pred_prob_df <- t(pred_prob_df)
pred_prob_df <- as.data.frame(pred_prob_df)
colnames(pred_prob_df) <- c("low_ci","median_est","upp_ci")
pred_prob_df <- cbind(pred_prob_df, pred_seq)
head(pred_prob_df)
### now its time for ggplot 

test_ggplot_reg <- ggplot(pred_prob_df, aes(x=pred_seq, y=median_est)) +
  geom_line(linewidth=1.2) + 
  geom_ribbon(aes(ymin=low_ci,ymax=upp_ci), alpha=0.4) + #### very important command; makes the CIs 
  theme_minimal() + ## cleans up the presentation of the plot 
  labs(title="An example of a regression plot", x="Number of hedgehogs owned", y="Interest in badgers", 
       caption="This plot is brought to you by the Avengers")

test_ggplot_reg

###note: do we have range of x vals? no. That's not good, since it belies realistic potential of data 
test_ggplot_reg <- test_ggplot_reg +
  geom_density(data=test_data_frame2,aes(x=col_019,y=after_stat(scaled)-1), col="blue",linewidth=1.2)

test_ggplot_reg

### now let's save this thing 
ggsave("example_plot.png" ,test_ggplot_reg, scale=1,width=9,height=6,units = c("in"), dpi=400,bg="white")


### Finally, let's learn how to check for outliers 
## purpose of measure: identify outlying observations 

test_cook<-cooks.distance(test_model) ## works on model object 
test_cook ## very long; let's just look at max vals 

test_cook[which.max(test_cook)] ## we see here that the 91st value pulled; that means it is an outlier 

### let's visualize 


## identify cutpoint by knowing number of obs in reg (100 for us), the number of vars (20), relative to 4
N = nrow(test_data_frame)
k = ncol(test_data_frame)
cutoff = 4/ (N-k-1)

plot(cooks.distance(test_model),type="b",pch=18,col="red")
abline(h=cutoff,lty=2) ## what does this mean? Everything above line is an outlying obs; should control for 

## pulls row numbers 
outliers <-test_cook[which(test_cook>cutoff)]
outliers <-as.data.frame(outliers)
### make row number a column 
outliers$row_num <- rownames(outliers)
head(outliers)

### let's merge back on that original data 
test_data_frame2$row_num <- rownames(test_data_frame2)
head(test_data_frame2)

### let's merge! 

test_data_frame2 <- merge(test_data_frame2, outliers, by="row_num",all.x=T)

###let's check for missing 
sum(is.na(test_data_frame2$outliers)) ## missing 93; good 

### add in var for outlier dummy 
test_data_frame2$outlier_dummy <- 0
test_data_frame2$outlier_dummy[is.na(test_data_frame2$outliers)==F] <- 1


### 
test_model_cd <- lm(y_var ~., data = subset(test_data_frame2, select=-c(row_num,outliers)))
summary(test_model_cd)

### woot! added in control; could also drop
