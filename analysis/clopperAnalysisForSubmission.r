# ------------------------------------------------------------------ #
# Analysis of Clopper & Tamati (2014) vowel space data
# As reported in Keshet, Adi, Cibelli, Gustafson, Clopper, & Goldrick 

# This script analyzes both vowel durations and vowel distances.

# Note on terminology -
# Terms for the algorithmic methods in this code are different than 
# those used in the paper. Their correspondences are:
# HMM = Penn/FAVE (forced aligner)
# DLM = SED (structured prediction)
# DLM (no classifier) = SEDNC (structured prediction, no classifier)

# AE data subset refers to /ɛ-æ/
# C data subset refers to /ɑ-ɔ/
#------------------------------------------------------------------ #

# regression analysis package
library(lme4)
# for "rename" function
library(plyr)

# lme convenience function
# Extracts estimated chi-sq stats p-values for each fixed effect 
# To be used with anova() comparing model with and without the fixed effect of interest
chiReport.func <- function(a){
	ifelse (
		a$"Pr(>Chisq)"[2] > .0001,
		return(paste("chisq(",a$"Chi Df"[2],")=",round(a$Chisq[2],2),", p = ",round(a	$"Pr(>Chisq)"[2],4),sep="")), # return chisq, p
		return(paste("chisq(",a$"Chi Df"[2],")=",round(a$Chisq[2],2),", p < .0001"))) # return p < .0001 for very small values of p
}

#bootstrap analysis package
library(boot)

#bootstrap function for mean differences in paired observations
boot.mean.dif.fnc <- function (data,indices){
  # get difference at each index
  d <- (data$Obs1[indices]-data$Obs2[indices])
  # calculate mean
  return(mean(d))
}

#load data
dataMANUAL <- read.delim("manual_codedFactors_new.txt", as.is=T)
dataSED <- read.delim("dl_cy_class_new_praat_script.txt",as.is=T)
dataSEDNC <- read.delim("dl_cy_no_class_new_praat_script.txt",as.is=T)
dataPENN <- read.delim("fave_cy_new_praat_script.txt", as.is=T)

# total observations from manual data set
nrow(dataMANUAL)
#  777

# Add ".TextGrid" to manual file names to enable merging with algorithmic datasets
dataMANUAL$file_name = paste(dataMANUAL$Sound, ".TextGrid", sep = "")

# Use MANUAL sound column to add information to algorithmic data sets
dataPENN$Sound = gsub(".TextGrid", "", dataPENN$file_name)
for (i in 1:nrow(dataPENN)) {
  dataPENN$Vowel[i] = dataMANUAL[dataMANUAL$Sound == dataPENN$Sound[i],]$Vowel
  dataPENN$VowelPair[i] = dataMANUAL[dataMANUAL$Sound == dataPENN$Sound[i],]$VowelPair
  dataPENN$Condition[i] = dataMANUAL[dataMANUAL$Sound == dataPENN$Sound[i],]$Condition
  dataPENN$Talker[i] = dataMANUAL[dataMANUAL$Sound == dataPENN$Sound[i],]$Talker
  dataPENN$Item[i] = dataMANUAL[dataMANUAL$Sound == dataPENN$Sound[i],]$Item
  }

dataSED$Sound = gsub(".TextGrid", "", dataSED$file_name)
for (i in 1:nrow(dataSED)) {
  dataSED$Vowel[i] = dataMANUAL[dataMANUAL$Sound == dataSED$Sound[i],]$Vowel
  dataSED$VowelPair[i] = dataMANUAL[dataMANUAL$Sound == dataSED$Sound[i],]$VowelPair
  dataSED$Condition[i] = dataMANUAL[dataMANUAL$Sound == dataSED$Sound[i],]$Condition
  dataSED$Talker[i] = dataMANUAL[dataMANUAL$Sound == dataSED$Sound[i],]$Talker
  dataSED$Item[i] = dataMANUAL[dataMANUAL$Sound == dataSED$Sound[i],]$Item
  }

dataSEDNC$Sound = gsub(".TextGrid", "", dataSEDNC$file_name)
for (i in 1:nrow(dataSEDNC)) {
  dataSEDNC$Vowel[i] = dataMANUAL[dataMANUAL$Sound == dataSEDNC$Sound[i],]$Vowel
  dataSEDNC$VowelPair[i] = dataMANUAL[dataMANUAL$Sound == dataSEDNC$Sound[i],]$VowelPair
  dataSEDNC$Condition[i] = dataMANUAL[dataMANUAL$Sound == dataSEDNC$Sound[i],]$Condition
  dataSEDNC$Talker[i] = dataMANUAL[dataMANUAL$Sound == dataSEDNC$Sound[i],]$Talker
  dataSEDNC$Item[i] = dataMANUAL[dataMANUAL$Sound == dataSEDNC$Sound[i],]$Item
  }


# define vowel pairs
vowels = c("ae", "E", "c", "a")
vowelPairing = c("E", "ae", "a", "c")
vowelSets = data.frame(vowels, vowelPairing)


# Outlier removal: flag items outside 3 S.D. from mean in either F1 or F2
# (Note: the manual dataset had outliers removed from the start)
dataPENN$index = 1:nrow(dataPENN)
dataPENN$F1z = 0
dataPENN$F2z = 0
for (i in unique(dataPENN$Vowel)) { # Calculate z-score within vowel
	dataPENN[dataPENN$Vowel == i,]$F1z = scale(dataPENN[dataPENN$Vowel == i,]$predicted_F1)
	dataPENN[dataPENN$Vowel == i,]$F2z = scale(dataPENN[dataPENN$Vowel == i,]$predicted_F2)
	}
outliersPENN = c(
		dataPENN[abs(dataPENN$F1z)> 3,]$index, dataPENN[abs(dataPENN$F2z) > 3,]$index)
length(outliersPENN)/nrow(dataPENN)
# 0.04247104 (33 tokens)

dataSED$index = 1:nrow(dataSED)
dataSED$F1z = 0
dataSED$F2z = 0
for (i in unique(dataSED$Vowel)) {
	dataSED[dataSED$Vowel == i,]$F1z = scale(dataSED[dataSED$Vowel == i,]$predicted_F1)
	dataSED[dataSED$Vowel == i,]$F2z = scale(dataSED[dataSED$Vowel == i,]$predicted_F2)
	}
outliersSED = c(
		dataSED[abs(dataSED$F1z)> 3,]$index, dataSED[abs(dataSED$F2z) > 3,]$index)
length(outliersSED)/nrow(dataSED)
# 0.03088803 (24 tokens)

dataSEDNC$index = 1:nrow(dataSEDNC)
dataSEDNC$F1z = 0
dataSEDNC$F2z = 0
for (i in unique(dataSEDNC$Vowel)) {
	dataSEDNC[dataSEDNC$Vowel == i,]$F1z = scale(dataSEDNC[dataSEDNC$Vowel == i,]$predicted_F1)
	dataSEDNC[dataSEDNC$Vowel == i,]$F2z = scale(dataSEDNC[dataSEDNC$Vowel == i,]$predicted_F2)
	}
outliersSEDNC = c(
		dataSEDNC[abs(dataSEDNC$F1z)> 3,]$index, dataSEDNC[abs(dataSEDNC$F2z) > 3,]$index)
length(outliersSEDNC)/nrow(dataSEDNC)
#  0.02960103 (23 tokens)

# replacement rates for each
length(unique(outliersSED))/nrow(dataMANUAL)
# 0.02702703
length(unique(outliersSEDNC))/nrow(dataMANUAL)
#  0.02574003
length(unique(outliersPENN))/nrow(dataMANUAL)
# 0.03861004

# overall percentage of outliers
# (note: this assumes all algorithmic files are in the same order)
length(unique(c(outliersSED,outliersSEDNC,outliersPENN))) # 44 tokens
length(unique(c(outliersSED,outliersSEDNC,outliersPENN)))/nrow(dataMANUAL) # 5.66%

# Replace outliers from each data set with manual measurements
# (Replace if either F1 or F2 are extreme)
for (i in 1:nrow(dataPENN)) {
  if (dataPENN$index[i] %in% outliersPENN) {
    dataPENN$predicted_F1[i] = dataMANUAL[dataMANUAL$file_name == dataPENN$file_name[i],]$F1Bark
    dataPENN$predicted_F2[i] = dataMANUAL[dataMANUAL$file_name == dataPENN$file_name[i],]$F2Bark
  }
}

for (i in 1:nrow(dataSED)) {
  if (dataSED$index[i] %in% outliersSED) {
    dataSED$predicted_F1[i] = dataMANUAL[dataMANUAL$file_name == dataSED$file_name[i],]$F1Bark
    dataSED$predicted_F2[i] = dataMANUAL[dataMANUAL$file_name == dataSED$file_name[i],]$F2Bark
  }
}

for (i in 1:nrow(dataSEDNC)) {
  if (dataSEDNC$index[i] %in% outliersSEDNC) {
    dataSEDNC$predicted_F1[i] = dataMANUAL[dataMANUAL$file_name == dataSEDNC$file_name[i],]$F1Bark
    dataSEDNC$predicted_F2[i] = dataMANUAL[dataMANUAL$file_name == dataSEDNC$file_name[i],]$F2Bark
  }
}

# Calculate median vowel distance
medAll = c()
for (i in 1:length(dataPENN$Item)){
  med = median(sqrt((dataPENN$predicted_F1[dataPENN$Talker == dataPENN$Talker[i] & dataPENN$VowelPair == dataPENN$VowelPair[i] & dataPENN$Vowel!=dataPENN$Vowel[i] & dataPENN$Condition == dataPENN$Condition[i]] - dataPENN$predicted_F1[i])^2 + (dataPENN$predicted_F2[dataPENN$Talker== dataPENN$Talker[i] & dataPENN$VowelPair == dataPENN$VowelPair[i] & dataPENN$Vowel!=dataPENN$Vowel[i] & dataPENN$Condition == dataPENN$Condition[i]] - dataPENN$predicted_F2[i])^2))
  medAll = append(medAll, med)
}
dataPENN$MedianVowelDist = medAll

medAll = c()
for (i in 1:length(dataSED$Item)){
  med = median(sqrt((dataSED$predicted_F1[dataSED$Talker == dataSED$Talker[i] & dataSED$VowelPair == dataSED$VowelPair[i] & dataSED$Vowel!=dataSED$Vowel[i] & dataSED$Condition == dataSED$Condition[i]] - dataSED$predicted_F1[i])^2 + (dataSED$predicted_F2[dataSED$Talker== dataSED$Talker[i] & dataSED$VowelPair == dataSED$VowelPair[i] & dataSED$Vowel!=dataSED$Vowel[i] & dataSED$Condition == dataSED$Condition[i]] - dataSED$predicted_F2[i])^2))
  medAll = append(medAll, med)
}
dataSED$MedianVowelDist = medAll

medAll = c()
for (i in 1:length(dataSEDNC$Item)){
  med = median(sqrt((dataSEDNC$predicted_F1[dataSEDNC$Talker == dataSEDNC$Talker[i] & dataSEDNC$VowelPair == dataSEDNC$VowelPair[i] & dataSEDNC$Vowel!=dataSEDNC$Vowel[i] & dataSEDNC$Condition == dataSEDNC$Condition[i]] - dataSEDNC$predicted_F1[i])^2 + (dataSEDNC$predicted_F2[dataSEDNC$Talker== dataSEDNC$Talker[i] & dataSEDNC$VowelPair == dataSEDNC$VowelPair[i] & dataSEDNC$Vowel!=dataSEDNC$Vowel[i] & dataSEDNC$Condition == dataSEDNC$Condition[i]] - dataSEDNC$predicted_F2[i])^2))
  medAll = append(medAll, med)
}
dataSEDNC$MedianVowelDist = medAll


# Find observations common to all datasets
MP <- intersect(dataMANUAL$file_name,dataPENN$file_name)
MPS1 <- intersect(MP, dataSED$file_name) 
MPS = intersect(MPS1, dataSEDNC$file_name)

# Check: how many total data points?
length(MPS)
# 777 - This should match the number of points in the manul dataset, because we replace outliers with manual data points

# Select common observations and sort by filename
# Rename some columns to be specific to each data source
dataMANUAL.matched <- dataMANUAL[is.element(dataMANUAL$file_name,MPS),]
dataMANUAL.matched = rename(dataMANUAL.matched, c("Duration" = "duration.Manual", "MedianVowelDist" = "distance.Manual", "F1Bark" = "F1Bark.Manual", "F2Bark" = "F2Bark.Manual"))
dataMANUAL.matched <- dataMANUAL.matched[order(dataMANUAL.matched$file_name),]

dataSED.matched <- dataSED[is.element(dataSED$file_name,MPS),]
dataSED.matched = rename(dataSED.matched, c("predicted_duration" = "duration.SED", "MedianVowelDist" = "distance.SED", "predicted_F1" = "F1Bark.SED", "predicted_F2" = "F2Bark.SED"))
dataSED.matched <- dataSED.matched[order(dataSED.matched$file_name),]

dataPENN.matched <- dataPENN[is.element(dataPENN$file_name,MPS),]
dataPENN.matched= rename(dataPENN.matched, c("predicted_duration" = "duration.PENN", "MedianVowelDist" = "distance.PENN", "predicted_F1" = "F1Bark.PENN", "predicted_F2" = "F2Bark.PENN"))
dataPENN.matched <- dataPENN.matched[order(dataPENN.matched$file_name),]

dataSEDNC.matched <- dataSEDNC[is.element(dataSEDNC$file_name,MPS),]
dataSEDNC.matched = rename(dataSEDNC.matched, c("predicted_duration" = "duration.SEDNC", "MedianVowelDist" = "distance.SEDNC", "predicted_F1" = "F1Bark.SEDNC", "predicted_F2" = "F2Bark.SEDNC"))
dataSEDNC.matched <- dataSEDNC.matched[order(dataSEDNC.matched$file_name),]


# merge datasets into one frame (ignore warning)
# First select algorithmic columns of interest
dataPENN.stripped = subset(dataPENN.matched, select = c(file_name, duration.PENN, distance.PENN, F1Bark.PENN, F2Bark.PENN, Condition)) 
dataSED.stripped = subset(dataSED.matched, select = c(file_name, duration.SED, distance.SED, F1Bark.SED, F2Bark.SED))
dataSEDNC.stripped = subset(dataSEDNC.matched, select = c(file_name, duration.SEDNC, distance.SEDNC, F1Bark.SEDNC, F2Bark.SEDNC))
dataMP1 <- merge(dataMANUAL.matched,dataPENN.stripped,by="file_name") 
dataMP2 = merge(dataMP1, dataSEDNC.stripped, by="file_name")
dataFull <- merge(dataMP2,dataSED.stripped, by="file_name")

nrow(dataFull) # one more sanity check
# 777 

# Add contrast-coded categories for condition, dialectm from outside files
names = read.csv("filenames.txt", as.is = T)
subj = read.delim("subjects.txt", as.is =T)
dataFull = merge(dataFull, names)
dataFull = merge(dataFull, subj)

# Separate dataset into /ae-E/ set and /c-a/ set
ae = subset(dataFull, VowelPair=="ae-E")
c = subset(dataFull, VowelPair=="c-a")

# ------------------------------------------------------------------------------------------
## Plots - all data

# Compare the distribution of deviance of each algorithmic model to the manual model, and 
# plot that distribution

# density only - single plot
pdf(file="figures/allValuesDensity_Clopper_new.pdf", width = 5.25, height  = 5)
cexStandard = 1.25																					# Set standard text size
axisMaxMin = max(abs((c(																			# Find good axis ranges
	dataFull$duration.Manual - dataFull$duration.SED, 
	dataFull$duration.Manual - dataFull$duration.SEDNC, 
	dataFull$duration.Manual - dataFull$duration.PENN))))
axisMaxMin = axisMaxMin + (0.1* axisMaxMin)	
plot(density(dataFull$duration.Manual - dataFull$duration.SED), lwd = 2, col = "blue",				# Plot SED (DLM) in blue
	main = "", cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,			# Suppress title, set text sizes
	xlim = c(-axisMaxMin, axisMaxMin), ylim = c(0, 30))												# Axes
lines(density(dataFull$duration.Manual - dataFull$duration.SEDNC), lwd = 2, col = "red", lty = 2)	# Plot SEDNC (DLMNC) in red
lines(density(dataFull$duration.Manual - dataFull$duration.PENN), lwd = 2, col = "black", lty = 4)	# Plot PENN/FAVE (HMM) in black
legend("topright", c("DLM", "DLM (no classifier)", "HMM"), col = c("blue", "red", "black"),			# Legend
      lwd  = 2, lty = c(1, 2, 4), cex = 0.85)
dev.off()

# ----------------------------------------------------------------------------------------------
## Evaluating vowel durations, all data

#Mean squared error of predictions: Structured Prediction
mean((dataFull$duration.SED - dataFull$duration.Manual)^2)*1000
#  0.9486015

#Mean squared error of predictions: Structured Prediction (no classifier)
mean((dataFull$duration.SEDNC - dataFull$duration.Manual)^2)*1000
# 1.05524

#Mean squared error of predictions: Penn aligner
mean((dataFull$duration.PENN - dataFull$duration.Manual)^2)*1000
# 8.179183

#Compare MSE: Structured prediction vs. Penn aligner
# Is the squared error for the penn aligner worse than that of structured prediction?
# bootstrap 95% CI
# Note: values from bootstrap calculations will vary slightly from run to run
pairedObs<- data.frame((dataFull$duration.PENN-dataFull$duration.Manual)^2,(dataFull$duration.SED-dataFull$duration.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5]*1000 # upper 95th percentile
# 10.03489  
boot.ci(boot.results,type="perc")$perc[,4]*1000 # lower 95th percentile
#  5.140456
# Interpretation: CI does not contain 0: higher MSE for Penn than SED

#Compare MSE: Structured prediction (no classifier) vs. Penn aligner
#bootstrap 95% CI
pairedObs<- data.frame((dataFull$duration.PENN-dataFull$duration.Manual)^2,(dataFull$duration.SEDNC-dataFull$duration.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5]*1000 # upper 95th percentile
#  9.592466
boot.ci(boot.results,type="perc")$perc[,4]*1000 # lower 95th percentile
#5.042042
# Interpretation: CI does not contain 0:  higher MSE for Penn than SEDNC

#Compare MSE: structured prediction vs. structured prediction (no classifier)
#bootstrap 95% CI
pairedObs<- data.frame((dataFull$duration.SEDNC-dataFull$duration.Manual)^2,(dataFull$duration.SED-dataFull$duration.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5]*1000 # upper 95th percentile
# 0.3009405
boot.ci(boot.results,type="perc")$perc[,4]*1000 # lower 95th percentile
# -0.03809481 
# Interpretation: Interval contains 0, so we cannot be confident in a difference between SEDNC and SED

# ------------------------------------------------------------------------------
## Plots for all data - distance metric

pdf(file="figures/allValuesDistance_Density_Clopper_new.pdf", width = 5.25, height  = 5)
cexStandard = 1.25
axisMaxMin = max(abs((c(
	dataFull$distance.Manual - dataFull$distance.SED, 
	dataFull$distance.Manual - dataFull$distance.SEDNC, 
	dataFull$distance.Manual - dataFull$distance.PENN))))
axisMaxMin = axisMaxMin + (0.1* axisMaxMin)	
# density
plot(density(dataFull$distance.Manual - dataFull$distance.SED), lwd = 2, col = "blue",
	main = "",
	cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,
	xlim = c(-axisMaxMin, axisMaxMin), ylim = c(0, 2))	
lines(density(dataFull$distance.Manual - dataFull$distance.SEDNC), lwd = 2, col = "red", lty = 2)
lines(density(dataFull$distance.Manual - dataFull$distance.PENN), lwd = 2, col = "black", lty = 4)
legend("topright", c("DLM", "DLM (no classifier)", "HMM"), col = c("blue", "red", "black"),
      lwd  = 2, lty = c(1, 2, 4), cex = 0.85)
dev.off()

# ------------------------------------------------------------------------------
## All data - vowel distance measure

#Mean squared error of predictions: Structured Prediction
mean((dataFull$distance.SED - dataFull$distance.Manual)^2)
# 0.1802755

#Mean squared error of predictions: Structured Prediction (no classifier)
mean((dataFull$distance.SEDNC - dataFull$distance.Manual)^2)
# 0.1933863

#Mean squared error of predictions: Penn aligner
mean((dataFull$distance.PENN - dataFull$distance.Manual)^2)
#  0.2692858

#Compare MSE: Structured prediction vs. Penn aligner
#is the squared error for the penn aligner worse than that of structured prediction?
#bootstrap 95% CI
pairedObs<- data.frame((dataFull$distance.PENN-dataFull$distance.Manual)^2,(dataFull$distance.SED-dataFull$distance.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.2048251
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# -0.01625352 
# Interpretation: interval contains 0, so no evidence for a SED/PENN difference

#Compare MSE: Structured prediction (no classifier) vs. Penn aligner
#bootstrap 95% CI
pairedObs<- data.frame((dataFull$distance.PENN-dataFull$distance.Manual)^2,(dataFull$distance.SEDNC-dataFull$distance.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.2045823 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# -0.03422467
# Interpretation: interval contains 0, so no evidence for a SEDNC/PENN difference

#Compare MSE: structured prediction vs. structured prediction (no classifier)
#bootstrap 95% CI
pairedObs<- data.frame((dataFull$distance.SEDNC-dataFull$distance.Manual)^2,(dataFull$distance.SED-dataFull$distance.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.03929716
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# -0.005832377
# Interpretation: interval contains 0, so no evidence for a SED/SEDNC difference

# ------------------------------------------------------------------------------
## Evaluate ae and C data separately

# For regressions: follow method of Sonderegger+Keshet
# Test 1: after trimming of outliers, compare model parameters (for fit on full set)
# Test 2: compare predictions of models using leave-one-out method

# prep regression analysis - center frequency and density predictors
ae$cLogFreq = ae$LogFreq - mean(ae$LogFreq)
ae$cDensity = ae$Density - mean(ae$Density)

c$cLogFreq = c$LogFreq - mean(c$LogFreq)
c$cDensity = c$Density - mean(c$Density)

# ------------------------------------------------------------------------------
## AE data, duration comparison

#Mean squared error of predictions: Structured Prediction
mean((ae$duration.SED - ae$duration.Manual)^2)
#  0.0008018961

#Mean squared error of predictions: Structured Prediction (no classifier)
mean((ae$duration.SEDNC - ae$duration.Manual)^2)
#  0.001012299

#Mean squared error of predictions: Penn aligner
mean((ae$duration.PENN - ae$duration.Manual)^2)
# 0.0127093

#Compare MSE: Structured prediction vs. Penn aligner
#is the squared error for the penn aligner worse than that of structured prediction?
#bootstrap 95% CI
pairedObs<- data.frame((ae$duration.PENN-ae$duration.Manual)^2,(ae$duration.SED-ae$duration.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
#  0.01667977 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# 0.008207456 
# Interpretation: PENN has higher MSE than SED

#Compare MSE: Structured prediction (no classifier) vs. Penn aligner
#bootstrap 95% CI
pairedObs<- data.frame((ae$duration.PENN-ae$duration.Manual)^2,(ae$duration.SEDNC-ae$duration.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.01623469 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# 0.007895108 
# Interpretation: PENN has higher MSE than SEDNC

#Compare MSE: structured prediction vs. structured prediction (no classifier)
#bootstrap 95% CI
pairedObs<- data.frame((ae$duration.SEDNC-ae$duration.Manual)^2,(ae$duration.SED-ae$duration.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.0005459477 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# -2.538393e-05 
# Interpretation: Interval contains 0, so no evidence of a difference betwen SED and SEDNC

# ------------------------------------------------------------------------------
## AE data, distance, regression models 

# Procedure:
# Fit a regression model, then re-fit excluding observations where model residuals exceed 2.5 standard deviations from mean
# assess significance of each fixed effect term using model comparison

# Plot
pdf(file="figures/AEduration_Density_Clopper_new.pdf", width = 6, height  = 4.5)
cexStandard = 1
axisMaxMin = max(abs((c(
	ae$duration.Manual - ae$duration.SED, 
	ae$duration.Manual - ae$duration.SEDNC, 
	ae$duration.Manual - ae$duration.PENN))))
axisMaxMin = axisMaxMin + (0.1* axisMaxMin)	
# density
plot(density(ae$duration.Manual - ae$duration.SED), lwd = 2, col = "blue",
	main = "Measurement deviance (manual - algorithmic)",
	cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,
	xlim = c(-axisMaxMin, axisMaxMin), 
	ylim = c(0, 35))	
lines(density(ae$duration.Manual - ae$duration.SEDNC), lwd = 2, col = "red", lty = 2)
lines(density(ae$duration.Manual - ae$duration.PENN), lwd = 2, col = "black", lty = 4)
legend("topright", c("DLM", "DLM (no classifier)", "HMM"), col = c("blue", "red", "black"),
      lwd  = 2, lty = c(1, 2, 4))
dev.off()

# For each measure: AE subset
# Fit a regression model, then re-fit excluding observations where model residuals exceed 2.5 standard deviations from mean
# Assess significance of each fixed effect term using model comparison

# Manual fit
dataManualAE.lmer = lmer(distance.Manual~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=ae, REML=F)
manualTrimAE = ae[abs(scale(resid(dataManualAE.lmer)))<2.5,]
dataManualTrimAE.lmer = lmer(distance.Manual~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=manualTrimAE, REML=F)

summary(dataManualTrimAE.lmer)
#                                       Estimate Std. Error t value
# (Intercept)                           1.1049775  0.0786076  14.057
# DialectN.contrast                    -0.3448767  0.1439152  -2.396
# Condition.contrast                    0.0386709  0.1143713   0.338
# cLogFreq                              0.0256745  0.0850910   0.302
# cDensity                             -0.0008004  0.0069353  -0.115
# DialectN.contrast:Condition.contrast  0.1138650  0.0779065   1.462

chiReport.func(anova(dataManualTrimAE.lmer,update(dataManualTrimAE.lmer,.~.-DialectN.contrast)))
# "chisq(1)=5.05, p = 0.0247"
chiReport.func(anova(dataManualTrimAE.lmer,update(dataManualTrimAE.lmer,.~.-Condition.contrast)))
# "chisq(1)=0.11, p = 0.7357"
chiReport.func(anova(dataManualTrimAE.lmer,update(dataManualTrimAE.lmer,.~.-cLogFreq)))
# "chisq(1)=0.09, p = 0.7631"
chiReport.func(anova(dataManualTrimAE.lmer,update(dataManualTrimAE.lmer,.~.-cDensity)))
# "chisq(1)=0.01, p = 0.9081"
chiReport.func(anova(dataManualTrimAE.lmer,update(dataManualTrimAE.lmer,.~.-DialectN.contrast:Condition.contrast)))
# "chisq(1)=2.05, p = 0.1521"

# Structured prediction fit
dataSEDAE.lmer = lmer(distance.SED~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=ae, REML=F)
sedTrimAE = ae[abs(scale(resid(dataSEDAE.lmer)))<2.5,]
dataSEDTrimAE.lmer = lmer(distance.SED~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=sedTrimAE, REML=F)

summary(dataSEDTrimAE.lmer)
#                                       Estimate Std. Error t value
# (Intercept)                           1.2293096  0.0899549  13.666
# DialectN.contrast                    -0.3550101  0.1481552  -2.396
# Condition.contrast                    0.0908564  0.1751270   0.519
# cLogFreq                              0.0356549  0.1186144   0.301
# cDensity                              0.0005756  0.0106438   0.054
# DialectN.contrast:Condition.contrast  0.1380673  0.0818397   1.687

chiReport.func(anova(dataSEDTrimAE.lmer,update(dataSEDTrimAE.lmer,.~.-DialectN.contrast)))
# "chisq(1)=5.04, p = 0.0247"
chiReport.func(anova(dataSEDTrimAE.lmer,update(dataSEDTrimAE.lmer,.~.-Condition.contrast)))
# "chisq(1)=0.27, p = 0.6051"
chiReport.func(anova(dataSEDTrimAE.lmer,update(dataSEDTrimAE.lmer,.~.-cLogFreq)))
# "chisq(1)=0.09, p = 0.764"
chiReport.func(anova(dataSEDTrimAE.lmer,update(dataSEDTrimAE.lmer,.~.-cDensity)))
# "chisq(1)=0, p = 0.9569"
chiReport.func(anova(dataSEDTrimAE.lmer,update(dataSEDTrimAE.lmer,.~.-DialectN.contrast:Condition.contrast)))
# "chisq(1)=2.83, p = 0.0928"

# Structured prediction (no classifier) fit
dataSEDNCAE.lmer = lmer(distance.SEDNC~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=ae, REML=F)
sedncTrimAE = ae[abs(scale(resid(dataSEDNCAE.lmer)))<2.5,]
dataSEDNCTrimAE.lmer = lmer(distance.SEDNC~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=sedncTrimAE, REML=F)

summary(dataSEDNCTrimAE.lmer)
#                                      Estimate Std. Error t value
# (Intercept)                           1.253472   0.092618  13.534
# DialectN.contrast                    -0.276718   0.151416  -1.828
# Condition.contrast                    0.110527   0.182390   0.606
# cLogFreq                              0.013911   0.122716   0.113
# cDensity                              0.001253   0.011209   0.112
# DialectN.contrast:Condition.contrast  0.130869   0.082502   1.586

chiReport.func(anova(dataSEDNCTrimAE.lmer,update(dataSEDNCTrimAE.lmer,.~.-DialectN.contrast)))
# "chisq(1)=3.09, p = 0.0789"
chiReport.func(anova(dataSEDNCTrimAE.lmer,update(dataSEDNCTrimAE.lmer,.~.-Condition.contrast)))
# "chisq(1)=0.36, p = 0.5464"
chiReport.func(anova(dataSEDNCTrimAE.lmer,update(dataSEDNCTrimAE.lmer,.~.-cLogFreq)))
# "chisq(1)=0.01, p = 0.9098"
chiReport.func(anova(dataSEDNCTrimAE.lmer,update(dataSEDNCTrimAE.lmer,.~.-cDensity)))
# "chisq(1)=0.01, p = 0.911"
chiReport.func(anova(dataSEDNCTrimAE.lmer,update(dataSEDNCTrimAE.lmer,.~.-DialectN.contrast:Condition.contrast)))
# "chisq(1)=2.48, p = 0.1155"

# Penn aligner fit
dataPENNAE.lmer = lmer(distance.PENN~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=ae, REML=F)
pennTrimAE = ae[abs(scale(resid(dataPENNAE.lmer)))<2.5,]
dataPENNTrimAE.lmer = lmer(distance.PENN~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=pennTrimAE, REML=F)

summary(dataPENNTrimAE.lmer)
#                                      Estimate Std. Error t value
# DialectN.contrast                  	-0.256561   0.128070  -2.003
# Condition.contrast                   -0.120849   0.143960  -0.839
# cLogFreq                              0.134984   0.102075   1.322
# cDensity                             -0.002619   0.008778  -0.298
# DialectN.contrast:Condition.contrast -0.006593   0.089422  -0.074

chiReport.func(anova(dataPENNTrimAE.lmer,update(dataPENNTrimAE.lmer,.~.-DialectN.contrast)))
# "chisq(1)=3.66, p = 0.0559"
chiReport.func(anova(dataPENNTrimAE.lmer,update(dataPENNTrimAE.lmer,.~.-Condition.contrast)))
# "chisq(1)=0.69, p = 0.4054"
chiReport.func(anova(dataPENNTrimAE.lmer,update(dataPENNTrimAE.lmer,.~.-cLogFreq)))
# "chisq(1)=1.69, p = 0.194"
chiReport.func(anova(dataPENNTrimAE.lmer,update(dataPENNTrimAE.lmer,.~.-cDensity)))
# "chisq(1)=0.09, p = 0.7657"
chiReport.func(anova(dataPENNTrimAE.lmer,update(dataPENNTrimAE.lmer,.~.-DialectN.contrast:Condition.contrast)))
# "chisq(1)=0.01, p = 0.9413"

# Comparison 1 part A. Regression parameters, ae subset

# Comparison 1a. Fixed effects
# Sum squared error on parameters relative to Manual fit: Structured prediction
sum((fixef(dataSEDTrimAE.lmer)[2:6]-fixef(dataManualTrimAE.lmer)[2:6])^2) 
# 0.003513273

# Sum squared error on parameters relative to Manual fit: Structured prediction (no classifier)
sum((fixef(dataSEDNCTrimAE.lmer)[2:6]-fixef(dataManualTrimAE.lmer)[2:6])^2) 
# 0.01024067

# Sum squared error on parameters relative to Manual fit: Penn
sum((fixef(dataPENNTrimAE.lmer)[2:6]-fixef(dataManualTrimAE.lmer)[2:6])^2)
# 0.05970839

# ------------------------------------------------------------------------------
## AE data, distance, leave-one-out prediction models

# Comparison 2: predictions on held-out data (leave-one-out method)
# Generate predictions each of held-out observations
# Note: these take 20-30 minutes each to run on our local machine
obs = c(1:length(ae$Item))
ae2 = cbind(ae, obs)

# Manual predictions
manualPredictAE = double(length(ae$Item))
for(i in 1:length(ae$Item)){
  ae3 = subset(ae2, obs!=i)
  dataManualAE.lmer = lmer(distance.Manual~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data = ae3, REML=F)
  manualTrimAE = ae3[abs(scale(resid(dataManualAE.lmer)))<2.5,]
  dataManualTrimAE.lmer = lmer(distance.Manual~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=manualTrimAE, REML=F)
  # Add warning for any leave-one-out model that does not converge. If this happens, take note of the point and exclude this point from all models
  tt = tryCatch(lmer(distance.Manual~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=manualTrimAE, REML=F), warning=function(w) w)
  if(is(tt,"warning")) print(i)
  manPred = predict(dataManualTrimAE.lmer, newdata = ae2)
  manualPredictAE[i] = manPred[i]
}
write.csv(manualPredictAE, "predictions/manualPredictAE_Distance_new.csv")
# Here is where to exclude observations corresponding to nonconvergence on manual model.
# manualPredictAE_sub = subset...
# However, we encountered no convergence failures for this model.

# Structured prediction predictions
sedPredictAE = double(length(ae$Item))
for(i in 1:length(ae$Item)){
  ae3 = subset(ae2, obs!=i)
  dataSEDAE.lmer = lmer(distance.SED~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data = ae3, REML=F)
  sedTrimAE = ae3[abs(scale(resid(dataSEDAE.lmer)))<2.5,]
  dataSedTrimAE.lmer = lmer(distance.SED~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=sedTrimAE, REML=F)
  sedPred = predict(dataSedTrimAE.lmer, newdata = ae2)
  sedPredictAE[i] = sedPred[i]
}
write.csv(sedPredictAE, "predictions/sedPredictAE_Distance_new.csv")

# Structured prediction (no classifier) predictions
sedncPredictAE = double(length(ae$Item))
for(i in 1:length(ae$Item)){
  ae3 = subset(ae2, obs!=i)
  dataSEDNCAE.lmer = lmer(distance.SEDNC~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data = ae3, REML=F)
  sedncTrimAE = ae3[abs(scale(resid(dataSEDNCAE.lmer)))<2.5,]
  dataSedncTrimAE.lmer = lmer(distance.SEDNC~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=sedncTrimAE, REML=F)
  sedncPred = predict(dataSedncTrimAE.lmer, newdata = ae2)
  sedncPredictAE[i] = sedncPred[i]
}
write.csv(sedncPredictAE, "predictions/sedncPredictAE_Distance_new.csv")
 
# Penn/FAVE predictions
pennPredictAE = double(length(ae$Item))
for(i in 1:length(ae$Item)){
  ae3 = subset(ae2, obs!=i)
  dataPENNAE.lmer = lmer(distance.PENN~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data = ae3, REML=F)
  pennTrimAE = ae3[abs(scale(resid(dataPENNAE.lmer)))<2.5,]
  dataPennTrimAE.lmer = lmer(distance.PENN~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=pennTrimAE, REML=F)
  tt = tryCatch(lmer(distance.PENN~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=pennTrimAE, REML=F), warning=function(w) w)
  if(is(tt,"warning")) print(i)
  pennPred = predict(dataPennTrimAE.lmer, newdata = ae2)
  pennPredictAE[i] = pennPred[i]
}
write.csv(pennPredictAE, "predictions/pennPredictAE_Distance_new.csv")

# If there were non-convergence points to remove, they would be labeled with _sub.
# If there were no non-convergence points to remove, rename each prediction vector
# to match that _sub label and proceed.
manualPredictAE_sub = manualPredictAE
pennPredictAE_sub = pennPredictAE
sedPredictAE_sub = sedPredictAE
sedncPredictAE_sub = sedncPredictAE

#MSE for Structured Prediction
mean((manualPredictAE_sub-sedPredictAE_sub)^2)
#  0.04670629

#MSE for Structured prediction (no classifier)
mean((manualPredictAE_sub-sedncPredictAE_sub)^2)
# 0.06886048

#MSE for Penn aligner
mean((manualPredictAE_sub-pennPredictAE_sub)^2)
# 0.04489729

#Compare MSE: Structured prediction vs. Penn aligner--note that the bootstrap function is different from above
#bootstrap 95% CI
pairedObs<- data.frame((pennPredictAE_sub-manualPredictAE_sub)^2,(sedPredictAE_sub-manualPredictAE_sub)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

#Mean squared error of predictions
mean((pennPredictAE_sub - manualPredictAE_sub)^2 - (sedPredictAE_sub - manualPredictAE_sub)^2 )
# -0.001809005

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.005064988
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# -0.00981661 
# Interpretation: Interval contains 0, no evidence for a SED/Penn difference.

#Compare MSE: Structured prediction (no classifier) vs. Penn aligner
#bootstrap 95% CI
pairedObs<- data.frame((pennPredictAE_sub - manualPredictAE_sub)^2,(sedncPredictAE_sub - manualPredictAE_sub)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

#Mean squared error of predictions
mean((pennPredictAE_sub - manualPredictAE_sub)^2 -(sedncPredictAE_sub - manualPredictAE_sub)^2 )
#  -0.02396319

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# -0.01531529 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# -0.0326678 
# Interpretation: Bigger MSE for SEDNC than Penn

#Compare MSE: Structured prediction vs. no classifier
#bootstrap 95% CI
pairedObs<- data.frame((sedPredictAE_sub - manualPredictAE_sub)^2,(sedncPredictAE_sub - manualPredictAE_sub)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

#Mean squared error of predictions
mean((sedPredictAE_sub - manualPredictAE_sub)^2 -(sedncPredictAE_sub - manualPredictAE_sub)^2 )
# -0.02215418

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# -0.01729091  
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# -0.02725317 
# Interpretation: Bigger MSE for SEDNC than SED


## AE data, distance plots for leave-one-out prediction models

pdf(file="figures/leaveOneOut-AEdistance_Density_Clopper_new.pdf", width = 5.25, height  = 5)
cexStandard = 1.25
axisMaxMin = max(abs((c(
	manualPredictAE_sub - sedPredictAE_sub, 
	manualPredictAE_sub - sedncPredictAE_sub,  
	manualPredictAE_sub - pennPredictAE_sub))))
axisMaxMin = axisMaxMin + (0.1* axisMaxMin)	
# density
plot(density(manualPredictAE_sub - sedPredictAE_sub), lwd = 2, col = "blue",
	main = "",
	cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,
	xlim = c(-axisMaxMin, axisMaxMin), ylim = c(0, 2.5))	
lines(density(manualPredictAE_sub - sedncPredictAE_sub), lwd = 2, col = "red", lty = 2)
lines(density(manualPredictAE_sub - pennPredictAE_sub), lwd = 2, col = "black", lty = 4)
legend("topright", c("DLM", "DLM (no classifier)", "HMM"), col = c("blue", "red", "black"),
      lwd  = 2, lty = c(1, 2, 4), cex = 0.85)
dev.off()

# ------------------------------------------------------------------------------
## C data, vowel duration

#Mean squared error of predictions: Structured Prediction
mean((c$duration.SED - c$duration.Manual)^2)
#  0.001104257

#Mean squared error of predictions: Structured Prediction (no classifier)
mean((c$duration.SEDNC - c$duration.Manual)^2)
# 0.001100801

#Mean squared error of predictions: Penn aligner
mean((c$duration.PENN - c$duration.Manual)^2)
# 0.003372696

#Compare MSE: Structured prediction vs. Penn aligner
#is the squared error for the penn aligner worse than that of structured prediction?
#bootstrap 95% CI
pairedObs<- data.frame((c$duration.PENN-c$duration.Manual)^2,(c$duration.SED-c$duration.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.003228222 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# 0.001394349 
# Interpretation: PENN has higher MSE than SED

#Compare MSE: Structured prediction (no classifier) vs. Penn aligner
#bootstrap 95% CI
pairedObs<- data.frame((c$duration.PENN-c$duration.Manual)^2,(c$duration.SEDNC-c$duration.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.003323766 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# 0.001406084
# Interpretation: PENN has higher MSE than SEDNC

#Compare MSE: structured prediction vs. structured prediction (no classifier)
#bootstrap 95% CI
pairedObs<- data.frame((c$duration.SEDNC-c$duration.Manual)^2,(c$duration.SED-c$duration.Manual)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.0001452125 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# -0.0001722156 
# Interpretation: Interval contains 0, so no evidnece for a difference between SED and SEDNC

## Plot C duration data

# density only - single plot
pdf(file="figures/Cduration_Density_Clopper_new.pdf", width = 6, height  = 4.5)
cexStandard = 1
axisMaxMin = max(abs((c(
	c$duration.Manual - c$duration.SED, 
	c$duration.Manual - c$duration.SEDNC, 
	c$duration.Manual - c$duration.PENN))))
axisMaxMin = axisMaxMin + (0.1* axisMaxMin)	
plot(density(c$duration.Manual - c$duration.SED), lwd = 2, col = "blue",
	main = "Measurement deviance (manual - algorithmic)",
	cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,
	xlim = c(-axisMaxMin, axisMaxMin), 
	ylim = c(0, 30))	
lines(density(c$duration.Manual - c$duration.SEDNC), lwd = 2, col = "red", lty = 2)
lines(density(c$duration.Manual - c$duration.PENN), lwd = 2, col = "black", lty = 4)
legend("topright", c("DLM", "DLM (no classifier)", "HMM"), col = c("blue", "red", "black"),
      lwd  = 2, lty = c(1, 2, 4))
dev.off()

# ------------------------------------------------------------------------------
## C Data, vowel distance, regression models

## Procedure:
# Fit a regression model, then re-fit excluding observations where model residuals exceed 2.5 standard deviations from mean
# assess significance of each fixed effect term using model comparison

# Manual fit
dataManualC.lmer = lmer(distance.Manual~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=c, REML=F)
manualTrimC = c[abs(scale(resid(dataManualC.lmer)))<2.5,]
dataManualTrimC.lmer = lmer(distance.Manual~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=manualTrimC, REML=F)

chiReport.func(anova(dataManualTrimC.lmer,update(dataManualTrimC.lmer,.~.-Dialect.contrast)))
# [1] "chisq(1)=2.48, p = 0.1152"

chiReport.func(anova(dataManualTrimC.lmer,update(dataManualTrimC.lmer,.~.-Condition.contrast)))
# [1] "chisq(1)=12.4, p = 4e-04"

chiReport.func(anova(dataManualTrimC.lmer,update(dataManualTrimC.lmer,.~.-cLogFreq)))
# [1] "chisq(1)=0.62, p = 0.4324"

chiReport.func(anova(dataManualTrimC.lmer,update(dataManualTrimC.lmer,.~.-cDensity)))
# [1] "chisq(1)=0.87, p = 0.3504"

chiReport.func(anova(dataManualTrimC.lmer,update(dataManualTrimC.lmer,.~.-Dialect.contrast:Condition.contrast)))
# [1] "chisq(1)=3.65, p = 0.0561"

# Structured prediction fit
dataSEDC.lmer = lmer(distance.SED~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=c, REML=F)
sedTrimC = c[abs(scale(resid(dataSEDC.lmer)))<2.5,]
dataSEDTrimC.lmer = lmer(distance.SED~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=sedTrimC, REML=F)

chiReport.func(anova(dataSEDTrimC.lmer,update(dataSEDTrimC.lmer,.~.-Dialect.contrast)))
# "chisq(1)=5.07, p = 0.0244"
 
 chiReport.func(anova(dataSEDTrimC.lmer,update(dataSEDTrimC.lmer,.~.-Condition.contrast)))
# "chisq(1)=7.26, p = 0.007"
 
 chiReport.func(anova(dataSEDTrimC.lmer,update(dataSEDTrimC.lmer,.~.-cLogFreq)))
# "chisq(1)=0.7, p = 0.4043"
 
 chiReport.func(anova(dataSEDTrimC.lmer,update(dataSEDTrimC.lmer,.~.-cDensity)))
# "chisq(1)=0.51, p = 0.4772"
 
 chiReport.func(anova(dataSEDTrimC.lmer,update(dataSEDTrimC.lmer,.~.-Dialect.contrast:Condition.contrast)))
# "chisq(1)=4.57, p = 0.0325"

# Structured prediction (no classifier) fit
dataSEDNCC.lmer = lmer(distance.SEDNC~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=c, REML=F)
sedncTrimC = c[abs(scale(resid(dataSEDNCC.lmer)))<2.5,]
dataSEDNCTrimC.lmer = lmer(distance.SEDNC~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=sedncTrimC, REML=F)
 
chiReport.func(anova(dataSEDNCTrimC.lmer,update(dataSEDNCTrimC.lmer,.~.-Dialect.contrast)))
# "chisq(1)=3.54, p = 0.06"
  
 chiReport.func(anova(dataSEDNCTrimC.lmer,update(dataSEDNCTrimC.lmer,.~.-Condition.contrast)))
# "chisq(1)=10.89, p = 0.001"
  
 chiReport.func(anova(dataSEDNCTrimC.lmer,update(dataSEDNCTrimC.lmer,.~.-cLogFreq)))
# "chisq(1)=0.91, p = 0.3407"
  
 chiReport.func(anova(dataSEDNCTrimC.lmer,update(dataSEDNCTrimC.lmer,.~.-cDensity)))
# "chisq(1)=0.87, p = 0.3512"
  
 chiReport.func(anova(dataSEDNCTrimC.lmer,update(dataSEDNCTrimC.lmer,.~.-Dialect.contrast:Condition.contrast)))
# "chisq(1)=3.99, p = 0.0459"

# Penn aligner fit
dataPENNC.lmer = lmer(distance.PENN~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=c, REML=F)
pennTrimC = c[abs(scale(resid(dataPENNC.lmer)))<2.5,]
dataPENNTrimC.lmer = lmer(distance.PENN~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=pennTrimC, REML=F)

chiReport.func(anova(dataPENNTrimC.lmer,update(dataPENNTrimC.lmer,.~.-Dialect.contrast)))
# "chisq(1)=1.14, p = 0.2855"
  
 chiReport.func(anova(dataPENNTrimC.lmer,update(dataPENNTrimC.lmer,.~.-Condition.contrast)))
# "chisq(1)=8.24, p = 0.0041"
 
 chiReport.func(anova(dataPENNTrimC.lmer,update(dataPENNTrimC.lmer,.~.-cLogFreq)))
# "chisq(1)=0.15, p = 0.6994"
  
 chiReport.func(anova(dataPENNTrimC.lmer,update(dataPENNTrimC.lmer,.~.-cDensity)))
# "chisq(1)=0.64, p = 0.4231"
  
 chiReport.func(anova(dataPENNTrimC.lmer,update(dataPENNTrimC.lmer,.~.-Dialect.contrast:Condition.contrast)))
# "chisq(1)=5, p = 0.0253" 

# Comparison 1 part B. Regression parameters, c subset

# Comparison 1a. Fixed effects
summary(dataManualTrimC.lmer) 
#                                   Estimate Std. Error t value
# (Intercept)                          1.393510   0.086298  16.148
# Dialect.contrast                    -0.217877   0.133876  -1.627
# Condition.contrast                   0.554665   0.132266   4.194
# cLogFreq                            -0.055762   0.070523  -0.791
# cDensity                            -0.008791   0.009318  -0.943
# Dialect.contrast:Condition.contrast  0.159558   0.082887   1.925

summary(dataSEDTrimC.lmer)
#                                      Estimate Std. Error t value
# (Intercept)                          1.375886   0.074997  18.346
# Dialect.contrast                    -0.256442   0.106678  -2.404
# Condition.contrast                   0.384733   0.129221   2.977
# cLogFreq                            -0.058742   0.069883  -0.841
# cDensity                            -0.006905   0.009667  -0.714
# Dialect.contrast:Condition.contrast  0.190240   0.088602   2.147

summary(dataSEDNCTrimC.lmer)
# #                                     Estimate Std. Error t value
# (Intercept)                          1.363224   0.075438  18.071
# Dialect.contrast                    -0.219998   0.111732  -1.969
# Condition.contrast                   0.481271   0.125271   3.842
# cLogFreq                            -0.064594   0.067082  -0.963
# cDensity                            -0.008701   0.009250  -0.941
# Dialect.contrast:Condition.contrast  0.179782   0.089758   2.003

summary(dataPENNTrimC.lmer)
#                                      Estimate Std. Error t value
# (Intercept)                          1.482595   0.085391  17.362
# Dialect.contrast                    -0.155967   0.143966  -1.083
# Condition.contrast                   0.376847   0.116908   3.223
# cLogFreq                            -0.024707   0.063850  -0.387
# cDensity                            -0.006756   0.008371  -0.807
# Dialect.contrast:Condition.contrast  0.214873   0.095545   2.249

# Sum squared error on parameters relative to Manual fit: Structured prediction
sum((fixef(dataSEDTrimC.lmer)-fixef(dataManualTrimC.lmer))^2) 
#  0.03162842

# Sum squared error on parameters relative to Manual fit: Structured prediction (no classifier)
sum((fixef(dataSEDNCTrimC.lmer)-fixef(dataManualTrimC.lmer))^2) 
# 0.006795388

# Sum squared error on parameters relative to Manual fit: Penn
sum((fixef(dataPENNTrimC.lmer)-fixef(dataManualTrimC.lmer))^2)
# 0.04741627

# ------------------------------------------------------------------------------
## C data, distance, leave-one-out prediction models

# Comparison 2: predictions on held-out data
obs = c(1:length(c$Item))
c2 = cbind(c, obs)

manualPredictC = double(length(c$Item))
for(i in 1:length(c$Item)){
  c3 = subset(c2, obs!=i)
  dataManualC.lmer = lmer(distance.Manual~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data = c3, REML=F)
  tt = tryCatch(lmer(distance.Manual~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data = c3, REML=F), warning=function(w) w)
  if(is(tt,"warning")) print(i)
  manualTrimC = c3[abs(scale(resid(dataManualC.lmer)))<2.5,]
  dataManualTrimC.lmer = lmer(distance.Manual~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=manualTrimC, REML=F)
  manPred = predict(dataManualC.lmer, newdata = c2)
  manualPredictC[i] = manPred[i]
}
## No convergence errors
manualPredictC_sub = manualPredictC
write.csv(manualPredictC_sub, "predictions/manualPredictC_sub_new.csv")

sedPredictC = double(length(c$Item))
for(i in 1:length(c$Item)){
  c3 = subset(c2, obs!=i)
  dataSEDC.lmer = lmer(distance.SED~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data = c3, REML=F)
  sedTrimC = c3[abs(scale(resid(dataSEDC.lmer)))<2.5,]
  dataSedTrimC.lmer = lmer(distance.SED~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=sedTrimC, REML=F)
  sedPred = predict(dataSedTrimC.lmer, newdata = c2)
  sedPredictC[i] = sedPred[i]
}
# exclude observations corresponding to nonconvergence on manual model (none)
sedPredictC_sub = sedPredictC
write.csv(sedPredictC_sub, "predictions/sedPredictC_sub_new.csv")

sedncPredictC = double(length(c$Item))
for(i in 1:length(c$Item)){
  c3 = subset(c2, obs!=i)
  dataSEDNCC.lmer = lmer(distance.SEDNC~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data = c3, REML=F)
  sedncTrimC = c3[abs(scale(resid(dataSEDNCC.lmer)))<2.5,]
  dataSedncTrimC.lmer = lmer(distance.SEDNC~Dialect.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=sedncTrimC, REML=F)
  sedncPred = predict(dataSedncTrimC.lmer, newdata = c2)
  sedncPredictC[i] = sedncPred[i]
}
# exclude observations corresponding to nonconvergence on manual model (none)
sedncPredictC_sub = sedncPredictC
write.csv(sedncPredictC_sub, "predictions/sedncPredictC_sub_new.csv")

pennPredictC = double(length(c$Item))
for(i in 1:length(c$Item)){
  c3 = subset(c2, obs!=i)
  dataPENNC.lmer = lmer(distance.PENN~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data = c3, REML=F)
  pennTrimC = c3[abs(scale(resid(dataPENNC.lmer)))<2.5,]
  dataPennTrimC.lmer = lmer(distance.PENN~DialectN.contrast*Condition.contrast+cLogFreq+cDensity+(1|Word)+(1|Talker)+(0+cDensity|Talker)+(0+cLogFreq|Talker), data=pennTrimC, REML=F)
  pennPred = predict(dataPennTrimC.lmer, newdata = c2)
  pennPredictC[i] = pennPred[i]
}
# exclude observations corresponding to nonconvergence on manual model (none)
# Note: 3 convergence errors on the penn predictions
pennPredictC_sub = pennPredictC
write.csv(pennPredictC_sub, "predictions/pennPredictC_sub_new.csv")

#MSE for Structured Prediction
mean((manualPredictC_sub-sedPredictC_sub)^2)
# 0.05063068

#MSE for Structured prediction (no classifier)
mean((manualPredictC_sub-sedncPredictC_sub)^2)
# 0.04872751

#MSE for Penn aligner
mean((manualPredictC_sub-pennPredictC_sub)^2)
#  0.04398119

#Compare MSE: Structured prediction vs. Penn aligner--note that the bootstrap function is different from above
#bootstrap 95% CI
pairedObs<- data.frame((pennPredictC_sub-manualPredictC_sub)^2,(sedPredictC_sub-manualPredictC_sub)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

#Mean squared error of predictions
mean((pennPredictC_sub - manualPredictC_sub)^2 - (sedPredictC_sub - manualPredictC_sub)^2 )
# -0.006649493

boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.004349039 

boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# -0.0185153 
# Interpretation: Interval contains 0; no evidence for a SED/PENN difference

#Compare MSE: Structured prediction (no classifier) vs. Penn aligner
#bootstrap 95% CI
pairedObs<- data.frame((pennPredictC_sub - manualPredictC_sub)^2,(sedncPredictC_sub - manualPredictC_sub)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

#Mean squared error of predictions
mean((pennPredictC_sub - manualPredictC_sub)^2 -(sedncPredictC_sub - manualPredictC_sub)^2 )
# -0.004746321
boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.008428024 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# -0.01762337 
# Interpretation: Interval contains 0, no evidence for a SEDNC/Penn difference

#Compare MSE: Structured prediction vs. no classifier
#bootstrap 95% CI
pairedObs<- data.frame((sedPredictC_sub - manualPredictC_sub)^2,(sedncPredictC_sub - manualPredictC_sub)^2)
colnames(pairedObs) <-c("Obs1","Obs2")
boot.results <- boot(data=pairedObs,statistic = boot.mean.dif.fnc,R=1000) #1000 bootstrap replicates

#Mean squared error of predictions
mean((sedPredictC_sub - manualPredictC_sub)^2 -(sedncPredictC_sub - manualPredictC_sub)^2 )
# 0.001903172
boot.ci(boot.results,type="perc")$perc[,5] # upper 95th percentile
# 0.006447073 
boot.ci(boot.results,type="perc")$perc[,4] # lower 95th percentile
# -0.002486035 
# Interpretation: Interval contains 0, no evidence for a SEDNC/SED difference


## C data, distance, plots

pdf(file="figures/leaveOneOut-Cdistance_Density_Clopper_new.pdf", width = 5.25, height  = 5)
cexStandard = 1.25
axisMaxMin = max(abs((c(
	manualPredictC_sub - sedPredictC_sub, 
	manualPredictC_sub - sedncPredictC_sub,  
	manualPredictC_sub - pennPredictC_sub))))
axisMaxMin = axisMaxMin + (0.1* axisMaxMin)	
plot(density(manualPredictC_sub - sedPredictC_sub), lwd = 2, col = "blue",
	main = "Measurement deviance (manual - algorithmic)",
	cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,
	xlim = c(-axisMaxMin, axisMaxMin), ylim = c(0, 2.5))	
lines(density(manualPredictC_sub - sedncPredictC_sub), lwd = 2, col = "red", lty = 2)
lines(density(manualPredictC_sub - pennPredictC_sub), lwd = 2, col = "black", lty = 4)
legend("topright", c("DLM", "DLM (no classifier)", "HMM"), col = c("blue", "red", "black"),
      lwd  = 2, lty = c(1, 2, 4), cex = 0.85)
dev.off()

# ----------------------------------------------------------------------------------------------
## Combining plots - all duration density figures

# cairo_pdf may help with IPA
cairo_pdf(file="figures/allDurationMeaures_DensityTriplet_Clopper_new.pdf", width = 12, height  = 3.5)
par(mfrow = c(1, 3),mar = c(4.5,4,3,1)+0.1)  # margin between plots  (bottom, left, top, right)
cexStandard = 1.5
par(family = "Helvetica")
# All data
axisMaxMin = max(abs((c(
	dataFull$duration.Manual - dataFull$duration.SED, 
	dataFull$duration.Manual - dataFull$duration.SEDNC, 
	dataFull$duration.Manual - dataFull$duration.PENN))))
axisMaxMin = axisMaxMin + (0.1* axisMaxMin)	
# density
plot(density(dataFull$duration.Manual - dataFull$duration.SED), lwd = 2, col = "blue",
	main = "All duration data",
	cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,
	xlim = c(-axisMaxMin, axisMaxMin), ylim = c(0, 35))	
lines(density(dataFull$duration.Manual - dataFull$duration.SEDNC), lwd = 2, col = "red", lty = 2)
lines(density(dataFull$duration.Manual - dataFull$duration.PENN), lwd = 2, col = "black", lty = 4)
legend("topright", c("DLM", "DLM (no classifier)", "FAVE"), col = c("blue", "red", "black"),
      lwd  = 2, lty = c(1, 2, 4))
# AE data
axisMaxMin = max(abs((c(
	ae$duration.Manual - ae$duration.SED, 
	ae$duration.Manual - ae$duration.SEDNC, 
	ae$duration.Manual - ae$duration.PENN))))
axisMaxMin = axisMaxMin + (0.1* axisMaxMin)	
# density
plot(density(ae$duration.Manual - ae$duration.SED), lwd = 2, col = "blue",
	main = "/æ/-/ɛ/ data",
	cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,
	xlim = c(-axisMaxMin, axisMaxMin), ylim = c(0, 35))	
lines(density(ae$duration.Manual - ae$duration.SEDNC), lwd = 2, col = "red", lty = 2)
lines(density(ae$duration.Manual - ae$duration.PENN), lwd = 2, col = "black", lty = 4)
legend("topright", c("DLM", "DLM (no classifier)", "FAVE"), col = c("blue", "red", "black"),
      lwd  = 2, lty = c(1, 2, 4))
# C data
axisMaxMin = max(abs((c(
	c$duration.Manual - c$duration.SED, 
	c$duration.Manual - c$duration.SEDNC, 
	c$duration.Manual - c$duration.PENN))))
axisMaxMin = axisMaxMin + (0.1* axisMaxMin)	
# density
plot(density(c$duration.Manual - c$duration.SED), lwd = 2, col = "blue",
	main = "/ɑ/-/ɔ/ data",
	cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,
	xlim = c(-axisMaxMin, axisMaxMin), ylim = c(0, 35))	
lines(density(c$duration.Manual - c$duration.SEDNC), lwd = 2, col = "red", lty = 2)
lines(density(c$duration.Manual - c$duration.PENN), lwd = 2, col = "black", lty = 4)
legend("topright", c("DLM", "DLM (no classifier)", "FAVE"), col = c("blue", "red", "black"),
      lwd  = 2, lty = c(1, 2, 4))
dev.off()

# --------------------------------------------------------------------------------------------

## LOO plots for both AE and C

# density only - single plot
cairo_pdf(file="figures/leaveOneOut-AEandCdistance_Density_Clopper_new.pdf", width = 10.5, height  = 4.8)
par(mfrow = c(1, 2),mar = c(5,6,4,1)+0.1)  # margin between plots  (bottom, left, top, right)
cexStandard = 1.1

# AE 
axisMaxMin = max(abs((c(
	manualPredictAE_sub - sedPredictAE_sub, 
	manualPredictAE_sub - sedncPredictAE_sub,  
	manualPredictAE_sub - pennPredictAE_sub))))
axisMaxMin = axisMaxMin + (0.1* axisMaxMin)	
# density
plot(density(manualPredictAE_sub - sedPredictAE_sub), lwd = 2, col = "blue",
	main = "/??-�/ predictions",
	cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,
	xlim = c(-axisMaxMin, axisMaxMin), ylim = c(0, 2.5))	
lines(density(manualPredictAE_sub - sedncPredictAE_sub), lwd = 2, col = "red", lty = 2)
lines(density(manualPredictAE_sub - pennPredictAE_sub), lwd = 2, col = "black", lty = 4)
legend("topright", c("DLM", "DLM (no classifier)", "HMM"), col = c("blue", "red", "black"),
      lwd  = 2, lty = c(1, 2, 4), cex = 0.8)

# C
cexStandard = 1.1
#axisMaxMin = max(abs((c(                 # Keep same axes as first panel
#	manualPredictC_sub - sedPredictC_sub, 
#	manualPredictC_sub - sedncPredictC_sub,  
#	manualPredictC_sub - pennPredictC_sub))))
#axisMaxMin = axisMaxMin + (0.1* axisMaxMin)	
# density
plot(density(manualPredictC_sub - sedPredictC_sub), lwd = 2, col = "blue",
  main = "/??-??/ predictions",   
	cex.main = cexStandard+.25, cex.axis = cexStandard, cex.lab = cexStandard,
	xlim = c(-axisMaxMin, axisMaxMin), ylim = c(0, 2.5))	
lines(density(manualPredictC_sub - sedncPredictC_sub), lwd = 2, col = "red", lty = 2)
lines(density(manualPredictC_sub - pennPredictC_sub), lwd = 2, col = "black", lty = 4)
legend("topright", c("DLM", "DLM (no classifier)", "HMM"), col = c("blue", "red", "black"),
      lwd  = 2, lty = c(1, 2, 4), cex = 0.8)
dev.off()
