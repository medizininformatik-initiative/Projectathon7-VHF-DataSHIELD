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
data.analysis <- CreateAnalysisTable(data.cohort, data.diagnosis)
data.diagnosis <- transform.diagnosis(data.cohort, data.diagnosis)
data.analysis <- transform.analysis(data.analysis)
data.analysis <- CodingGender(data.analysis)   # male --> 0 ; female --> 1

rm(data.cohort)


# The project name is internally used in OPAL as unique identifier for the project
# Therefore, we should be sure it is not used for any other project
# This should not be changed since the project needs to be named in the same way at all partner sites !!!
project.name <- "VHF"

# Use the specified import type (see .RProfile)
import.type <- Sys.getenv(IMPORT_TYPE, NA)

if (input.type == Sys.getenv(BATCH_UPLOAD_TO_OPAL)) {
  # Load opal-for-r library
  # You need to install this library first before you can use it.
  require(opalr)
  # resolve credentials to OPAL system, create connection and project as well as upload data finally
  connection <- create.opal.connection()
  create.project(connection, project.name)
  batch.upload.to.opal(connection, project.name, data.patient, data.observation, data.diagnosis, data.analysis)
  close.opal.connection(connection)

} else if (input.type == Sys.getenv(CHUNK_UPLOAD_TO_OPAL)) {
  # Load opal-for-r library
  # You need to install this library first before you can use it.
  require(opalr)
  connection <- create.opal.connection()
  create.project(connection)
  chunk.upload.to.opal(connection, project.name, data.patient, data.observation, data.diagnosis, data.analysis)
  close.opal.connection(connection)

} else if (input.type == Sys.getenv(WRITE_TO_FILE)) {
  # write the normalized data partitions to files
  write.data.to.files(data.patient, data.observation, data.diagnosis, data.analysis)

} else {
  stop(paste("The specified import type is not one of the pre-defined value set. ",
             "Please specify one of the available import types in .RProfile and execute it before ",
             "running the import script or other procedures."))
}

# Clean up
rm(list = ls())

######### End of the script
