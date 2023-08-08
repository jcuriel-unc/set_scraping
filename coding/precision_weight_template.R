#############################################################################
### template function to calculate F1 scores. 
## #note: the goal I have is to take the fxn as seen in the site: 
# https://stats.stackexchange.com/questions/37411/calculating-precision-and-recall-in-r
# and proceed to weight the scores. I think I'll do so at a value of 2, such that 
# observations that are below said threshold will receive less weight, and those above 
# will be extra influential, i.e. I WANT to really keep these. The scores of 2 
## would therefore be the bread and butter essentially of the toxic coding 

# Function: evaluation metrics
## True positives (TP) - Correctly idd as success
## True negatives (TN) - Correctly idd as failure
## False positives (FP) - success incorrectly idd as failure
## False negatives (FN) - failure incorrectly idd as success
## Precision - P = TP/(TP+FP) how many idd actually success/failure
## Recall - R = TP/(TP+FN) how many of the successes correctly idd
## F-score - F = (2 * P * R)/(P + R) harm mean of precision and recall
prf <- function(predAct){
  ## predAct is two col dataframe of pred,act
  preds = predAct[,1]
  trues = predAct[,2]
  xTab <- table(preds, trues)
  clss <- as.character(sort(unique(preds)))
  r <- matrix(NA, ncol = 7, nrow = 1, 
              dimnames = list(c(),c('Acc',
                                    paste("P",clss[1],sep='_'), 
                                    paste("R",clss[1],sep='_'), 
                                    paste("F",clss[1],sep='_'), 
                                    paste("P",clss[2],sep='_'), 
                                    paste("R",clss[2],sep='_'), 
                                    paste("F",clss[2],sep='_'))))
  r[1,1] <- sum(xTab[1,1],xTab[2,2])/sum(xTab) # Accuracy
  r[1,2] <- xTab[1,1]/sum(xTab[,1]) # Miss Precision
  r[1,3] <- xTab[1,1]/sum(xTab[1,]) # Miss Recall
  r[1,4] <- (2*r[1,2]*r[1,3])/sum(r[1,2],r[1,3]) # Miss F
  r[1,5] <- xTab[2,2]/sum(xTab[,2]) # Hit Precision
  r[1,6] <- xTab[2,2]/sum(xTab[2,]) # Hit Recall
  r[1,7] <- (2*r[1,5]*r[1,6])/sum(r[1,5],r[1,6]) # Hit F
  r}

### second response: 

require(ROCR)

# Prepare data for plotting
data(ROCR.simple)
pred <- with(ROCR.simple, prediction(predictions, labels))
perf <- performance(pred, measure="acc", x.measure="cutoff")

# Get the cutoff for the best accuracy
bestAccInd <- which.max(perf@"y.values"[[1]])
bestMsg <- paste("best accuracy=", perf@"y.values"[[1]][bestAccInd], 
                 " at cutoff=", round(perf@"x.values"[[1]][bestAccInd], 4))

plot(perf, sub=bestMsg)