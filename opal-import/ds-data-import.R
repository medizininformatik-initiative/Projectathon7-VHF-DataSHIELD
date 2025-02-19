# ################################
# Medical Informatics Initiative
# 7th Projectathon
# Project: VHF - DataSHIELD
# Importing data into OPAL
#
# Version: 1.0
# Last Update: 19.01.2023
# Toralf Kirsten (tkirsten@uni-leipzig.de)
# Reference: https://opaldoc.obiba.org/en/dev/cookbook/import-data/r.html
# ################################

# Preconditions
# -------------
#
# The necessary data files should be created by available R scripts which have been
# provided for the project "Projectathon7-VHF (distributed)" allowing to export relevant data
# from a FHIR server of your choice. This R data processing pipeline generates two data
# files named with Cohort.csv and Diagnosis.csv. You need to have these two data files at
# hand before you can import data. Therefore, run this script when the data files are
# available.
# Set the name and location of these two data files by setting them directly or using the .Rprofile
# Please don't change the file structire of these dwo data files

# Read the two data files
#file.name.loc.cohort <- "location/Cohort.csv"
#file.name.loc.diagnosis <- "location/Diagnosis.csv"
file.name.loc.cohort <- Sys.getenv("FILE_NAME_LOC_COHORT", NA)
file.name.loc.diagnosis <- Sys.getenv("FILE_NAME_LOC_DIAGNOSIS", NA)

source("./utilities/support-functions.R")
check.file.names(file.name.loc.cohort, file.name.loc.diagnosis)

data.cohort <- read.csv2(file = file.name.loc.cohort, header = T, sep = ";")
if (ncol(data.cohort) != 15) {
  stop(paste("The data file \"", file.name.loc.cohort,
             "\" doesn't have 15 columns. This file doesn't have the structure we expected.\n",
             "Please make sure this file has the appropriate structure first and then try again."))
}

data.diagnosis <- read.csv2(file = , file.name.loc.diagnosis, header = T, sep = ";")
if (ncol(data.diagnosis) != 11) {
  stop(paste("The data file \"", file.name.loc.cohort,
             "\" doesn't have 11 columns. This file doesn't have the structure we expected.\n",
             "Please make sure this file has the appropriate structure first and then try again."))
}

# PRE-PROCESSING
require(dplyr)
source("ds-data-import-functions.R")

data.cohort <- ReplaceNA(data.cohort)
data.patient <- transform.patient(data.cohort)
data.observation <- transform.observation(data.cohort)
data.analysis<- CreateAnalysisTable(data.cohort, data.diagnosis) 
data.diagnosis <- transform.diagnosis(data.cohort, data.diagnosis)
data.analysis<-transform.analysis(data.analysis)
data.analysis<-CodingGender(data.analysis)   # male --> 0 ; female --> 1

rm(data.cohort)


# Load opal-for-r library
# You need to install this library first before you can use it.
require(opalr)


# Connect to the OPAL server
# You need a user account with permissions to create a project and add data
# Don't use self signed certificates (for the OPAL server) - it doesn't work properly
user.name <- Sys.getenv("OPAL_USER_NAME", NA)
pass.word <- Sys.getenv("OPAL_USER_PASSWORD", NA)
opal.server.url <- Sys.getenv("OPAL_SERVER_URL", NA)

check.credentials(user.name, pass.word, opal.server.url)

connection <- opal.login(username = user.name,
                         password = pass.word,
                         url = opal.server.url, opts=list(ssl_verifyhost=0,ssl_verifypeer=0))

# The project name is internally used in OPAL as unique identifier for the project
# Therefore, we should be sure it is not used for any other project
# This should not be changed since the project needs to be named in the same way at all partner sites !!!
project.name <- "VHF"

# Create a project using the specified name before
if (opal.project_exists(opal = connection, project = project.name)) {
  stop(paste("The project \"", project.name, "\" already exists. Unclear status of the project content.\n",
             "Please clean and remove or rename the existing project first and then try again.\n",
             "Please, use the R script ds-remove-project.R to remove all data and the project definitions\n",
             "from the OPAL server. Alternatively, you can clean up the environement using the OPAL user interface."))
} else {
  opal.project_create(opal = connection,
                      project = project.name,
                      database = T,
                      description = "Project VHF of the 7th MII Projectathon",
                      tags = c("MII", "7th Projectathon", "VHF DataSHIELD"))
}

# Import data into three tables, i.e., patient, observation, and diagnosis
import.patient(connection = connection, project.name = project.name, data.patient = data.patient)
import.observation(connection = connection, project.name = project.name, data.observation = data.observation)
import.diagnosis(connection = connection, project.name = project.name, data.diagnosis = data.diagnosis)
import.analysis(connection = connection, project.name = project.name, data.analysis = data.analysis)

# Logout from the OPAL server
opal.logout(connection)

# Clean up
rm(list = ls())

######### End of the script
