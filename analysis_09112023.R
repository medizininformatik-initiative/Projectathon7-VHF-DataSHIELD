rm(list = ls())

require(DSI)
require(DSOpal)
require(opalr)
require(dsBaseClient)
#remotes::install_github("difuture-lmu/dsBinVal")
#require(dsBinVal)
# Connect to the OPAL server
# ==eKTxa[U:i3

# Add login data
builder <- DSI::newDSLoginBuilder()
source("/home/user/Documents/Projectathon7-VHF-DataSHIELD/test-login-data.R")
login.data <- builder$build()

#-------------------------------------------------------------------------------
# Login to all OPAL servers
connections <- datashield.login(logins = login.data)

# LOAD DATA --> new analysis table (includes unit conversion and all relevant columns for modeling)
datashield.assign.table(conns = connections,
                        symbol = "analysis.df",
                        table = "VHF.analysis_nt_pro_bnp")
ds.colnames('analysis.df')

#-------------------------------------------------------------------------------
# FILTERING 
# remove missing values and 0
ds.dataFrameSubset(df.name="analysis.df", V1.name="analysis.df$nt_pro_bnp_value", V2.name= "0" , Boolean.operator= '>',keep.NAs=FALSE, newobj ="filtered_analysis.df", datasources=connections)

# SUBSETTING --> subcohorts   NOT WORKING YET
# gender
ds.dataFrameSubset(df.name = "filtered_analysis.df", V1.name = "gender", V2.name = 'male', Boolean.operator = "==", 
                   newobj = "analysis.subset.Males", keep.NAs=FALSE,datasources= connections)
ds.dataFrameSubset(df.name = "filtered_analysis.df", V1.name = "filtered_analysis.df$gender", V2.name = "female", Boolean.operator = "==", newobj = "analysis.subset.Females", datasources= connections)
# age
ds.dataFrameSubset(df.name = "analysis.df", V1.name = "analysis.df$age", V2.name = "80", Boolean.operator = ">", newobj = "analysis.subset.above80", datasources= connections)

#-------------------------------------------------------------------------------

# GLM

# ------------------------------------------------------------------------------
# CREATE SUBCOHORTS
# (0) Diagnose I95.0 (Testdataset)
ds.dataFrameSubset(df.name="filtered_analysis.df", V1.name="filtered_analysis.df$IdiopathicHypotension", V2.name= "1" , Boolean.operator= '==',keep.NAs=FALSE, newobj ="CONDITIONTEST", datasources=connections)
# (1) Diagnose Vorhofflimmern
ds.dataFrameSubset(df.name="filtered_analysis.df", V1.name="filtered_analysis.df$AtrialFibrillation", V2.name= "1" , Boolean.operator= '==',keep.NAs=FALSE, newobj ="CONDITION_VHF", datasources=connections)
# (2) Herzinsuffizienz (heartFailure)
ds.dataFrameSubset(df.name="filtered_analysis.df", V1.name="filtered_analysis.df$HeartFailure", V2.name= "1" , Boolean.operator= '==',keep.NAs=FALSE, newobj ="CONDITION_HIS", datasources=connections)
# (3) Diagnose Vorhofflimmern, Ausschluss Herzinfarkt (MyoInfarction) oder Schlaganfall
ds.dataFrameSubset(df.name='CONDITION_VHF', V1.name="CONDITION_VHF$MyocardialInfarction", V2.name="0", Boolean.operator= '==',keep.NAs=FALSE, newobj="CONDITION_VHFsub",datasources=connections)
ds.dataFrameSubset(df.name='CONDITION_VHFsub', V1.name="CONDITION_VHF$Stroke", V2.name="0", Boolean.operator= '==',keep.NAs=FALSE, newobj="CONDITION_VHF2",datasources=connections)
# (4) Diagnose Herzinsuffizienz, Ausschluss Herzinfarkt und Schlaganfall
ds.dataFrameSubset(df.name='CONDITION_HIS', V1.name="CONDITION_VHF$$MyocardialInfarction", V2.name="0", Boolean.operator= '==',keep.NAs=FALSE, newobj="CONDITION_HISsub",datasources=connections)
ds.dataFrameSubset(df.name='CONDITION_HISsub', V1.name="CONDITION_VHF$$Stroke", V2.name="0", Boolean.operator= '==',keep.NAs=FALSE, newobj="CONDITION_HIS2",datasources=connections)
ds.rm("CONDITION_HISsub")
# (5) Diagnose Vorhofflimmern, Ausschluss aller anderen Diagnosen
ds.dataFrameSubset(df.name='CONDITION_VHF2', V1.name="CONDITION_VHF$HeartFailure", V2.name="0", Boolean.operator= '==',keep.NAs=FALSE, newobj="CONDITION_VHF3",datasources=connections)
ds.rm("CONDITION_VHFsub")

# create two lists to loop through
data_VHF<-c("CONDITION_VHF","CONDITION_VHF2","CONDITION_VHF3")
data_HIS<-c( "CONDITION_HIS","CONDITION_HIS2")

#
# as package "dsBinVal" is not working yet, i tried to solve it with ds.glm from dsBaseClient
#-------------------------------------------------------------------------------
# do it separately for 'Vorhofflimmern' and 'Herzinsuffizienz'
models_VHF<-list()
for (i in 1:length(data_VHF)){
  model_formula<-"AtrialFibrillation~nt_pro_bnp_value+age+gender"
  model<-ds.glm(formula = model_formula, family = "binomial", data = data_VHF[i], maxit= 30, datasources=connections)
  models_VHF[[i]]<-model
}

models_HIS<-list()
for (i in 1:length(data_HIS)){
  model_formula<-"HeartFailure~nt_pro_bnp_value+age+gender"
  model<-ds.glm(formula = model_formula, family = "binomial", data = data_HIS[i], maxit= 30, datasources=connections)
  models_HIS[[i]]<-model
}

data_test<-c("CONDITIONTEST","CONDITIONTEST")

# thresholds nt_pro_bnp
thresholds <- c(1 : 60) * 50
ifelse(data_test[i]$nt_pro_bnp_value < thresholds[j], 0, 1)


model_list<-list()
for (i in 1:length(data_test)){
  for (j in c(1 : length(thresholds))) {
    # set thresholds 
    model_formula<-"IdiopathicHypotension~nt_pro_bnp_value+age+gender"
    print(model_formula)
    model<-ds.glm(formula = model_formula, family = "binomial", data = data_test[i], maxit= 30, datasources=connections)
    model_list[[i]]<-model
  }
}

for(model in 1:length(model_list)){
  a<-predict.glm(model_list[model])
  print(model_list[model][[1]]$coefficients)
}




model_formula="CONDITION~nt_pro_bnp_value+age+gender"
model <- ds.glm(formula = model_formula, family = "binomial", data = 'filtered_analysis.df',
                maxit= 30, datasources=connections)

predict.glm(model)

# TO DO: ppv+npv (positive+negative predicted value), sensitivity, specificity
# TO DO: extract coefficient and calculate log odd
coefficients <- model$coefficients
log_odds <- coefficients[, "Estimate"]
# calculate predicted probability
log_odds <- as.vector(t(log_odds))  
predicted_probs <- plogis(log_odds) 



