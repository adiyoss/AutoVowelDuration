#--------------------------------------------------------------------#
# Analysis of dataset from Heller & Goldrick (2014) 
# As reported in Keshet, Adi, Cibelli, Gustafson, Clopper, & Goldrick 

# Note on terminology -
# Terms for the algorithmic methods in this code are different than 
# those used in the paper. Their correspondences are:
# HMM = Penn/FAVE (forced aligner)
# DLM = SED (structured prediction)
# DLM (no classifier) = SEDNC (structured prediction, no classifier)
#-------------------------------------------------------------------#

# Regression analysis package
library(lme4)

# lme convenience function
# Extracts estimated chi-sq stats p-values for each fixed effect 
# To be used with anova() comparing model with and without the fixed effect of interest
chiReport.func <- function(a){
	ifelse (
		a$"Pr(>Chisq)"[2] > .0001,
		return(paste("chisq(",a$"Chi Df"[2],")=",round(a$Chisq[2],2),", p = ",round(a	$"Pr(>Chisq)"[2],4),sep="")), # return chisq, p
		return(paste("chisq(",a$"Chi Df"[2],")=",round(a$Chisq[2],2),", p < .0001"))) # return p < .0001 for very small values of p
}

# Bootstrap analysis package
library(boot)

# Bootstrap function for mean differences in paired observations
boot.mean.dif.fnc <- function (data,indices){
  # get difference at each index
  d <- (data$Obs1[indices]-data$Obs2[indices])
  # calculate mean
  return(mean(d))
}

# Read in manual data 
dataMANUAL <- read.delim("durationData.txt",as.is=T)

# Read in aligned datasets and remove extraneous columns 
dataSED <- read.csv("structed_classifier_DL.csv",as.is=T)
dataSED = dataSED[,c("file_name","predicted_duration")]
dataSEDNC <- read.csv("structed_no_classifier_DL.csv", as.is=T)
dataSEDNC = dataSEDNC[,c("file_name","predicted_duration")]
dataPENN <- read.csv("fave_jordana.csv",as.is=T)
dataPENN = dataPENN[,c("file_name", "predicted_duration")]

# Make filename columns are consistent
dataMANUAL$File = gsub(".wav", "", dataMANUAL$File)
dataSED$file_name = tolower(gsub(".TextGrid", "", dataSED$file_name))
dataSEDNC$file_name = tolower(gsub(".TextGrid", "", dataSEDNC$file_name))
dataPENN$file_name = gsub(".textgrid", "", dataPENN$file_name)

# Exclude subjects 001, 008, 031 
# (These subjects did not give permission for data use beyond the original project)
excludeSubj = c("s001", "s008", "s031")
dataMANUAL = dataMANUAL[!(dataMANUAL$subj %in% excludeSubj),]
dataSED = dataSED[-(grep("008", dataSED$file_name, fixed = TRUE)),] 
dataSEDNC = dataSEDNC[-(grep("008", dataSEDNC$file_name, fixed = TRUE)),]

# Remove "lock", "hat" observations from the two data frames they appeared in
dataSED = dataSED[-(grep("lock", dataSED$file_name)),]
dataSED = dataSED[-(grep("hat", dataSED$file_name)),]
dataSEDNC = dataSEDNC[-(grep("lock", dataSEDNC$file_name)),]
dataSEDNC = dataSEDNC[-(grep("hat", dataSEDNC$file_name)),]

# total observations
nrow(dataMANUAL)
# 2395

# Failure rates for each
# (Data points which could not be algorithmically aligned)
1-(nrow(dataSED)/nrow(dataMANUAL))
# -0.002505219
1-(nrow(dataSEDNC)/nrow(dataMANUAL))
#  -0.002505219
1-(nrow(dataPENN)/nrow(dataMANUAL))
# 0

# Find observations common to all
MP <- intersect(dataMANUAL$File, dataSED$file_name)
MPS <- intersect(MP, dataSED$file_name)
MPS2 <- intersect(MPS, dataSED$file_name)

# Select common observations and sort by filename
# Rename duration column to be specific to each data source
dataMANUAL.matched <- dataMANUAL[is.element(dataMANUAL$File,MPS2),]
colnames(dataMANUAL.matched)[13] <- "duration.Manual"
dataMANUAL.matched <- dataMANUAL.matched[order(dataMANUAL.matched$File),]

dataSED.matched <- dataSED[is.element(dataSED$file_name,MPS2),]
colnames(dataSED.matched)[1] <- "File"
colnames(dataSED.matched)[2] <- "duration.SED"
dataSED.matched <- dataSED.matched[order(dataSED.matched$File),]

dataSEDNC.matched = dataSEDNC[is.element(dataSEDNC$file_name,MPS2),]
colnames(dataSEDNC.matched)[1] <- "File"
colnames(dataSEDNC.matched)[2] = "duration.SEDNC"
dataSEDNC.matched = dataSEDNC.matched[order(dataSEDNC.matched$File),]

dataPENN.matched <- dataPENN[is.element(dataPENN$file_name,MPS2),]
colnames(dataPENN.matched)[1] <- "File"
colnames(dataPENN.matched)[2] <- "duration.PENN"
dataPENN.matched <- dataPENN.matched[order(dataPENN.matched$File),]

# Merge datasets into one frame
dataMP <- merge(dataMANUAL.matched,dataPENN.matched,by="File")
dataMP2 <- merge(dataMP,dataSED.matched,by="File")
dataFull = merge(dataMP2, dataSEDNC.matched, by="File")

# Size of common set - make sure this equals the value reported above for nrow(dataMANUAL)
nrow(dataFull)
# 2395

# --------------------------------------------------------------------------------------------
## Density plot

# Compare the distribution of deviance of each algorithmic model to the manual model, and 
# plot that distribution

pdf(file="figures/HellerDensity.pdf", width = 5.25, height = 5)
cexStandard = 1.25																					# Baseline text size
axisMaxMin = max(abs((c(																			# Find good axis values 
	dataFull$duration.Manual - dataFull$duration.SED, 
	dataFull$duration.Manual - dataFull$duration.SEDNC, 
	dataFull$duration.Manual - dataFull$duration.PENN))))
axisMaxMin = axisMaxMin + (0.1* axisMaxMin)	
plot(density(dataFull$duration.Manual - dataFull$duration.SED), lwd = 2, col = "blue",				# Plot SED (DLM) deviance in blue
	main = "",																						# Suppress main title
	cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,						# Set text sizes
	xlim = c(-axisMaxMin, axisMaxMin), ylim = c(0, 30))												# Set x-axis limits
lines(density(dataFull$duration.Manual - dataFull$duration.SEDNC), lwd = 2, col = "red", lty = 2) 	# Plot SEDNC deviance in red
lines(density(dataFull$duration.Manual - dataFull$duration.PENN), lwd = 2, col = "black", lty = 4) 	# Plot Penn (HMM) deviance in black
legend("topright", c("DLM", "DLM (no classifier)", "HMM"), col = c("blue", "red", "black"),			# Legend
      lwd  = 2, lty = c(1, 2, 4), cex = 0.85)
dev.off()

# ---------------------------------------------------------------------------------------

## Metrics of error (MSE)

#Mean squared error of predictions: Structured Prediction
mean((dataFull$duration.SED - dataFull$duration.Manual)^2)*1000
#  1.561764

#Mean squared error of predictions: Structured Prediction (no classifier)
mean((dataFull$duration.SEDNC - dataFull$duration.Manual)^2)*1000
#  2.336025

#Mean squared error of predictions: Penn aligner
mean((dataFull$duration.PENN - dataFull$duration.Manual)^2)*1000
# 1.853601

#Compare MSE: Structured prediction vs. Penn aligner
#bootstrap 95% CI
pairedObs<- data.frame((dataFull$duration.PENN-dataFull$duration.Manual)^2,(dataFull$duration.SED-dataFull$duration.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

# Mean squared error of predictions
# Note: these and all bootstrap predictions will vary slightly from run to run
mean((dataFull$duration.PENN - dataFull$duration.Manual)^2 - (dataFull$duration.SED - dataFull$duration.Manual)^2 )
# 0.0002918373
# this is the mean difference in squared error across the two methods.

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.0005405129 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# 4.535996e-05 
# Interpretation: Interval does not include 0, so Penn (HMM) has significantly higher MSE than SED (DLM)

#Compare MSE: Structured prediction vs. without classifier
#bootstrap 95% CI
pairedObs<- data.frame((dataFull$duration.SEDNC-dataFull$duration.Manual)^2,(dataFull$duration.SED-dataFull$duration.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

#Mean squared error of predictions
mean((dataFull$duration.SEDNC - dataFull$duration.Manual)^2 - (dataFull$duration.SED - dataFull$duration.Manual)^2 )
# 0.0007742605
# this is the mean difference in squared error across the two methods.

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.001009028 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# 0.0005153437  
# Interpretation: Interval does not contain 0; SEDNC (DLM NC) has significantly higher MSE than SED (DLM)

#Compare MSE: Structured prediction without classifier vs. Penn aligner
#bootstrap 95% CI
pairedObs<- data.frame((dataFull$duration.SEDNC-dataFull$duration.Manual)^2,(dataFull$duration.PENN-dataFull$duration.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

#Mean squared error of predictions
mean((dataFull$duration.SEDNC - dataFull$duration.Manual)^2 - (dataFull$duration.PENN - dataFull$duration.Manual)^2 )
# 0.0004824232
# this is the mean difference in squared error across the two methods.

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
#  0.0007918015 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# 0.0001562128  
# Interpretation: Interval does not contain 0; SEDNC (DLM NC) has significantly higher MSE than Penn (HMM)

# ------------------------------------------------------------------------------------------
## Regression analyses

# For regressions: follow method of Sonderegger & Keshet (2012)
# Test 1: after trimming outliers, compare model parameters (for fit on training set)
# Test 2: compare predictions of models using leave-one-out method

# Prep regression analysis
# center/log transform density predictor
dataFull$logDur.Manual = log(dataFull$duration.Manual)
dataFull$logDur.SED = log(dataFull$duration.SED)
dataFull$logDur.SEDNC = log(dataFull$duration.SEDNC)
dataFull$logDur.PENN = log(dataFull$duration.PENN)

# For each algorithmic measure:
# Fit a regression model, then re-fit excluding observations where model residuals exceed 2.5 standard deviations from mean
# Assess significance of each fixed effect term using model comparison

# Basic model structure: 
# data.lmer = lmer(logDur~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=dataFull,control = lmerControl(optimizer = "bobyqa"),REML=F)

# Manual fit
dataManual.lmer = lmer(logDur.Manual~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=dataFull,control = lmerControl(optimizer = "bobyqa"),REML=F)
manualTrim = dataFull[abs(scale(resid(dataManual.lmer)))<2.5,] # Trim outlier residuals and then refit model
dataManualTrim.lmer = lmer(logDur.Manual~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=manualTrim,control = lmerControl(optimizer = "bobyqa"),REML=F)

summary(dataManualTrim.lmer)
# Fixed effects:
# 			  Estimate 	Std. Error t value
# (Intercept) -1.72217    0.04721  -36.48
# ContextCode -0.05741    0.01747   -3.29
# BlockCode    0.01181    0.01642    0.72

# Assess fixed effects by re-fitting model without predictor, anova() to compare model with and without predictor
chiReport.func(anova(dataManualTrim.lmer,update(dataManualTrim.lmer,.~.-ContextCode)))
# "chisq(1)=10, p = 0.0016"
chiReport.func(anova(dataManualTrim.lmer,update(dataManualTrim.lmer,.~.-BlockCode)))
# "chisq(1)=0.52, p = 0.473"

# Structured prediction fit
dataSED.lmer = lmer(logDur.SED~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=dataFull,control = lmerControl(optimizer = "bobyqa"),REML=F)
sedTrim = dataFull[abs(scale(resid(dataSED.lmer)))<2.5,]
dataSEDTrim.lmer = lmer(logDur.SED~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=sedTrim,control = lmerControl(optimizer = "bobyqa"),REML=F)

summary(dataSEDTrim.lmer)
#             Estimate Std. Error t value
# (Intercept) -1.79041    0.04453  -40.20
# ContextCode -0.07180    0.01879   -3.82
# BlockCode    0.01608    0.01770    0.91

chiReport.func(anova(dataSEDTrim.lmer,update(dataSEDTrim.lmer,.~.-ContextCode)))
# "chisq(1)=13.11, p = 3e-04"
chiReport.func(anova(dataSEDTrim.lmer,update(dataSEDTrim.lmer,.~.-BlockCode)))
#"chisq(1)=0.82, p = 0.3651"

# Structured prediction (no classifier) fit
dataSEDNC.lmer = lmer(logDur.SEDNC~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=dataFull,control = lmerControl(optimizer = "bobyqa"),REML=F)
sedncTrim = dataFull[abs(scale(resid(dataSEDNC.lmer)))<2.5,]
dataSEDNCTrim.lmer = lmer(logDur.SEDNC~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=sedncTrim,control = lmerControl(optimizer = "bobyqa"),REML=F)

summary(dataSEDNCTrim.lmer)
#            Estimate Std. Error t value
# (Intercept) -1.80015    0.04262  -42.24
# ContextCode -0.05861    0.01754   -3.34
# BlockCode    0.01515    0.01680    0.90

chiReport.func(anova(dataSEDNCTrim.lmer,update(dataSEDNCTrim.lmer,.~.-ContextCode)))
# "chisq(1)=10.2, p = 0.0014"
chiReport.func(anova(dataSEDNCTrim.lmer,update(dataSEDNCTrim.lmer,.~.-BlockCode)))
# "chisq(1)=0.81, p = 0.3688"

# Penn aligner fit
dataPENN.lmer = lmer(logDur.PENN~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=dataFull,control = lmerControl(optimizer = "bobyqa"),REML=F)
pennTrim = dataFull[abs(scale(resid(dataPENN.lmer)))<2.5,]
dataPENNTrim.lmer = lmer(logDur.PENN~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=pennTrim,control = lmerControl(optimizer = "bobyqa"),REML=F)

summary(dataPENNTrim.lmer)
# #            Estimate Std. Error t value
# (Intercept) -1.775437   0.046181  -38.45
# ContextCode -0.057771   0.018471   -3.13
# BlockCode    0.007923   0.014283    0.55

chiReport.func(anova(dataPENNTrim.lmer,update(dataPENNTrim.lmer,.~.-ContextCode)))
# "chisq(1)=8.81, p = 0.003"
chiReport.func(anova(dataPENNTrim.lmer,update(dataPENNTrim.lmer,.~.-BlockCode)))
# "chisq(1)=0.31, p = 0.5795"

## ---------------------------------------------------------------------------------
## Leave-one-out model predictions 

# Comparison 2: Predictions using leave-one-out method

# Generate predictions for test set
obs = c(1:length(dataFull$File))
dataFull2 = cbind(dataFull, obs)

# Predictions (these will be time-intensive)
manualPredict = double(length(dataFull$File))
for(i in 1:length(dataFull$File)){
  dataFull3 = subset(dataFull2, obs!=i)
  dataManual.lmer = lmer(logDur.Manual~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=dataFull3,control = lmerControl(optimizer = "bobyqa"),REML=F)
  manualTrim = dataFull3[abs(scale(resid(dataManual.lmer)))<2.5,]
  dataManualTrim.lmer = lmer(logDur.Manual~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=manualTrim,control = lmerControl(optimizer = "bobyqa"),REML=F)
  manPred = predict(dataManualTrim.lmer, newdata = dataFull2)
  manualPredict[i] = manPred[i]
}

sedPredict = double(length(dataFull$File))
for(i in 1:length(dataFull$File)){
  dataFull3 = subset(dataFull2, obs!=i)
  dataSED.lmer = lmer(logDur.SED~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=dataFull3,control = lmerControl(optimizer = "bobyqa"),REML=F)
  sedTrim = dataFull3[abs(scale(resid(dataSED.lmer)))<2.5,]
  dataSEDTrim.lmer = lmer(logDur.SED~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=sedTrim,control = lmerControl(optimizer = "bobyqa"),REML=F)
  sedPred = predict(dataSEDTrim.lmer, newdata = dataFull2)
  sedPredict[i] = sedPred[i]
}

sedncPredict = double(length(dataFull$File))
for(i in 1:length(dataFull$File)){
  dataFull3 = subset(dataFull2, obs!=i)
  dataSEDNC.lmer = lmer(logDur.SEDNC~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=dataFull3,control = lmerControl(optimizer = "bobyqa"),REML=F)
  sedncTrim = dataFull[abs(scale(resid(dataSEDNC.lmer)))<2.5,]
  dataSEDNCTrim.lmer = lmer(logDur.SEDNC~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=sedncTrim,control = lmerControl(optimizer = "bobyqa"),REML=F)
  sedncPred = predict(dataSEDNCTrim.lmer, newdata = dataFull2)
  sedncPredict[i] = sedncPred[i]
}

pennPredict = double(length(dataFull$File))
for(i in 1:length(dataFull$File)){
  dataFull3 = subset(dataFull2, obs!=i)
  dataPENN.lmer = lmer(logDur.PENN~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=dataFull3,control = lmerControl(optimizer = "bobyqa"),REML=F)
  pennTrim = dataFull[abs(scale(resid(dataPENN.lmer)))<2.5,]
  dataPENNTrim.lmer = lmer(logDur.PENN~ContextCode+BlockCode+(1+ContextCode||subject)+(1+ContextCode||word),data=pennTrim,control = lmerControl(optimizer = "bobyqa"),REML=F)
  pennPred = predict(dataPENNTrim.lmer, newdata = dataFull2)
  pennPredict[i] = pennPred[i]
}

#MSE for Structured Prediction
mean((exp(manualPredict)-exp(sedPredict))^2)*1000
# 0.4785495

#MSE for Structured Prediction (no classifier)
mean((exp(manualPredict)-exp(sedncPredict))^2) *1000
#  0.9351113

#MSE for penn aligner
mean((exp(manualPredict)-exp(pennPredict))^2) *1000
#  0.8345711

#Compare MSE: Structured prediction vs. Penn aligner
#bootstrap 95% CI
pairedObs<- data.frame((exp(pennPredict) - exp(manualPredict))^2,(exp(sedPredict) - exp(manualPredict))^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.0004278912 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# 0.0002945042 
# Interpretation: Interval does not contain 0, so PENN(HMM) has a higher MSE than SED (DLM)

#Compare MSE: Structured prediction vs. structured prediction (no classifier)
#bootstrap 95% CI
pairedObs<- data.frame((exp(sedncPredict) - exp(manualPredict))^2,(exp(sedPredict) - exp(manualPredict))^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
#  0.0005468904 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# 0.0003740818
# Interpretation: Interval does not contain 0, so SEDNC (DLM NC) has a higher MSE than SED (DLM)

#Compare MSE: Structured prediction (no classifier) vs. Penn aligner
#bootstrap 95% CI
pairedObs<- data.frame((exp(pennPredict) - exp(manualPredict))^2,(exp(sedncPredict) - exp(manualPredict))^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

#Mean squared error of predictions
boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 1.51538e-06 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# -0.0002047568 
# Interpretation: Interval contains 0, so we cannot be confident in a difference between SED (DLM) and SEDNC (DLM-NC)

# ---------------------------------------------------------------------------------------
## Plot leave-one-out model predictions

# Compare the distribution of deviance of each algorithmic model's preditions to the manual model's predictions, and plot that distribution

pdf(file="figures/HellerDensityPredictions.pdf", width = 5.25, height  = 5)
cexStandard = 1.25
# Set axis min-max to contain data points from all four sets of predictions
axisMaxMin = max(abs((c(
	manualPredict - sedPredict, 
	manualPredict - sedncPredict,  
	manualPredict - pennPredict))))
axisMaxMin = axisMaxMin + (0.3* axisMaxMin)	
plot(density(manualPredict - sedPredict), lwd = 2, col = "blue",
	main = "",
	cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,
	xlim = c(-axisMaxMin, axisMaxMin), ylim = c(0, 6))	
lines(density(manualPredict - sedncPredict), lwd = 2, col = "red", lty = 2)
lines(density(manualPredict - pennPredict), lwd = 2, col = "black", lty = 4)
legend("topright", c("DLM", "DLM (no classifier)", "HMM"), col = c("blue", "red", "black"),
      lwd  = 2, lty = c(1, 2, 4), cex = 0.85)
dev.off()
