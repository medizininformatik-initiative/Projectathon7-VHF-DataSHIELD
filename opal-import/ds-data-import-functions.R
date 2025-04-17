# This function creates a pid vector for each patient
#
generate.and.join.pid <- function(data.cohort, x) {
  pat <- unique(data.cohort[,c(1,12)])
  pat <- pat[order(pat$subject),]
  pat$pid <- 1:nrow(pat)
  pat$gender <- NULL
  x <- merge(x = x, y = pat, by = "subject")

  return(x)
}

# # # set NA/NULL values in NTproBNP.valueQuantity.value to "0" 
# otherwise it causes problems when uploading, 0 will be removed in analysis
ReplaceNA<-function(data.cohort){
  data.cohort$NTproBNP.valueQuantity.value[is.na(data.cohort$NTproBNP.valueQuantity.value)]<-0
  data.cohort$NTproBNP.valueQuantity.value[is.null(data.cohort$NTproBNP.valueQuantity.value)]<-0
  return(data.cohort)
}
data.cohort<-ReplaceNA(data.cohort)

#------------------------------------------------------------------------------------------------------------------------
# # # transform nt_pro_bnp_values to uniform unit pg/mL (regarding the given unit)
unifyUnits <- function(cohort){
  
  # Some DIZ write the SI unit not in the "valueQuantity/code" which was imported
  # in the field "NTproBNP.unit" but in the "valueQuantity/unit" which was
  # imported in the "NTproBNP.unitLabel". This label should only be used in FHIR
  # as a human readable unit description. So we fix this error here.

  if (all(is.na(cohort$NTproBNP.unit))) { # all unit values are NA -> copy the full unitLabel column to unit
    cohort <- cohort %>% mutate(NTproBNP.unit = NTproBNP.unitLabel)
  } else { # some unit values are NA -> replace the NA values in unit by unitLabel
    cohort <- cohort %>% mutate(NTproBNP.unit = ifelse(is.na(NTproBNP.unit), NTproBNP.unitLabel, NTproBNP.unit))
  }
  # remove all rows where the NTproBNP.unit is still NA
  cohort <- cohort[!is.na(cohort$NTproBNP.unit), ]
  
  # All valid NTproBNP units taken from http://www.unitslab.com/node/163
  # All units are checked case insensitive, so for example the correct
  # UCUM unit "pg/mL" includes the invalid unit "pg/ml".
  # The first value describes the code and the number value the conversion
  # factor regarding the reference value in the first line of the table.
  # If necessary then append other (invalid) units at the end of the list.
  units <- c(
    "pg/mL", 1, # Reference Unit as first value. Must always have a conversion value 1.
    "ng/L", 1,
    "pg/dL", 100,
    "pg/100mL", 100,
    "pg%", 100,
    "pg/L", 1000,
    "pmol/L", 0.1182
  )
  # extract unit strings and conversion factors from the table list
  units <- matrix(units, length(units) / 2, 2, byrow = TRUE)
  unitNames <- units[, 1]
  unitFactors <- as.numeric(units[, 2])
  
  # remove data rows with invalid units
  unitsPattern <- paste(unitNames, collapse = "|")
  cohort <- cohort[grepl(unitsPattern, cohort$NTproBNP.unit, ignore.case = TRUE), ]
  
  # now really unify
  for (i in 2 : length(unitNames)) {
    # Convert value
    cohort <- cohort %>%
      mutate(NTproBNP.valueQuantity.value = ifelse(tolower(NTproBNP.unit) == tolower(unitNames[i]), as.numeric(NTproBNP.valueQuantity.value)*unitFactors[i], NTproBNP.valueQuantity.value))
    # Convert unit
    cohort <- cohort %>%
      mutate(NTproBNP.unit = ifelse(tolower(NTproBNP.unit) == tolower(unitNames[i]), unitNames[1], NTproBNP.unit))
  }
  
  # overwrite the unit label with the unified one
  cohort <- cohort %>% mutate(NTproBNP.unitLabel = "picogram per milliliter")
  
  return(cohort)
}

data.cohort<-unifyUnits(data.cohort)
#------------------------------------------------------------------------------------------------------------------------
# Extract some information and recode given diagnosis  
CreateAnalysisTable <- function(cohort, conditions) {
  result <- cohort %>%
    group_by(encounter.id) %>%
    summarize(
      subject = first(subject),
      NTproBNP.valueQuantity.value = max(NTproBNP.valueQuantity.value, na.rm = TRUE),
      NTproBNP.unit = first(NTproBNP.unit),
      NTproBNP.valueQuantity.comparator=NTproBNP.valueQuantity.comparator,
      gender = first(gender),
      age= first(age),
      encounter.start=encounter.start,
      encounter.end=encounter.end
    ) %>%
    unique()
  
  conditionsReduced <- conditions %>%
    group_by(encounter.id) %>%
    summarize(
                                                        # check possible conditions again
      IdiopathicHypotension =as.numeric(any(grepl("I95.0", code))),
      AtrialFibrillation = as.numeric(any(grepl("I48.0|I48.1|I48.2|I48.9", code))),
      MyocardialInfarction = as.numeric(any(grepl("I21|I22|I25.2", code))),
      HeartFailure = as.numeric(any(grepl("I50", code))),
      Stroke = as.numeric(any(grepl("I60|I61|I62|I63|I64|I69", code)))
    )
  
  result <- result %>%
    left_join(conditionsReduced, by = "encounter.id")
  
  result <- result %>%
    mutate(
      IdiopathicHypotension =ifelse(is.na(IdiopathicHypotension), 0, IdiopathicHypotension),
      AtrialFibrillation = ifelse(is.na(AtrialFibrillation), 0, AtrialFibrillation),
      MyocardialInfarction = ifelse(is.na(MyocardialInfarction), 0, MyocardialInfarction),
      HeartFailure = ifelse(is.na(HeartFailure), 0, HeartFailure),
      Stroke = ifelse(is.na(Stroke), 0, Stroke)
    )
  
  return(result)
}

# add 0 and 1 for male and female, otherwise ds.dataFrameSubset causes problems while analysis
reCodeGender<-function(df){
  df$gender[df$gender == "male"] <- 0
  df$gender[df$gender == "female"] <- 1
  df$gender[df$gender != '0' & df$gender != '1'] <- 2
  df$gender <- as.integer(df$gender)
  return(df)
}

format.date.in.char <- function(df, col.name) {
  df[[col.name]] <- format(ymd(df[[col.name]]),"%Y-%m-%d")
  return (df)
}
# --------------------------------------------------------------------------------

transform.patient <- function(data.cohort) {
  data.patient <- unique(data.cohort[,c(1, 12, 15)])
  data.patient <- data.patient[order(data.patient$subject),]

  # Generate an independent and surrogate id column
  data.patient$id <- 1:nrow(data.patient)
  data.patient$pid <- data.patient$id

  # Transform the data type
  data.patient$subject <- as.character(data.patient$subject)
  data.patient <- reCodeGender(data.patient)
  data.patient$age <- as.numeric(data.patient$age)

  colnames(data.patient) <- c("patient_id", "gender", "age", "id", "pid")
  return(data.patient)
}

transform.analysis <- function(data.analysis) {
  # Generate an independent and surrogate id column
  data.analysis$id <- 1:nrow(data.analysis)
  
  # Transform the data type
  data.analysis$encounter.id <- as.character(data.analysis$encounter.id)
  data.analysis$subject <- as.character(data.analysis$subject)
  data.analysis$NTproBNP.valueQuantity.value <- as.numeric(data.analysis$NTproBNP.valueQuantity.value)
  data.analysis$NTproBNP.unit <- as.character(data.analysis$NTproBNP.unit)
  data.analysis$NTproBNP.valueQuantity.comparator <- as.character(data.analysis$NTproBNP.valueQuantity.comparator)
  data.analysis <- reCodeGender(data.analysis)
  data.analysis$age <- as.numeric(data.analysis$age)
  data.analysis$encounter.start <- format.date.in.char(data.analysis, "encounter.start")
  data.analysis$encounter.end <- format.date.in.char(data.analysis, "encounter.end")
  # TO DO: remove conditions that are not needed
  data.analysis$IdiopathicHypotension<-as.numeric(data.analysis$IdiopathicHypotension)
  data.analysis$AtrialFibrillation<-as.numeric(data.analysis$AtrialFibrillation)
  data.analysis$MyocardialInfarction<-as.numeric(data.analysis$MyocardialInfarction)
  data.analysis$HeartFailure<-as.numeric(data.analysis$HeartFailure)
  data.analysis$Stroke<-as.numeric(data.analysis$Stroke)
   # Generate the patient identifier as work around for joining using subject with long strings (disclosure risk)
  data.analysis <- generate.and.join.pid(data.cohort, data.analysis)
  
  colnames(data.analysis) <- c("encounter_id","patient_id","nt_pro_bnp_value","nt_pro_bnp_unit","nt_pro_bnp_comparator",
                               "gender", "age", "encounter_start","encounter_end","IdiopathicHypotension",
                               "AtrialFibrillation","MyocardialInfarction","HeartFailure","Stroke","id","pid")
  return(data.analysis)
}

transform.observation <- function(data.cohort) {
  data.observation <- unique(data.cohort[,c(1:11, 13, 14)])

  # Generate an independent and surrogate id column
  data.observation$id <- 1:nrow(data.observation)
  # Transform the data type
  data.observation$subject <- as.character(data.observation$subject)
# The next feature has been removed from the data set since it has not been requested
# data.observation$NTproBNP.date <- as.Date(data.observation$NTproBNP.date, format = "%Y-%m-%d %H:%M:%S")
  data.observation$encounter.id <- as.character(data.observation$encounter.id)
  data.observation$NTproBNP.valueQuantity.value <- as.numeric(data.observation$NTproBNP.valueQuantity.value)
  data.observation$NTproBNP.valueQuantity.comparator <- as.character(data.observation$NTproBNP.valueQuantity.comparator)
  data.observation$NTproBNP.code <- as.character(data.observation$NTproBNP.code)
  data.observation$NTproBNP.codeSystem <- as.character(data.observation$NTproBNP.codeSystem)
  data.observation$NTproBNP.unit <- as.character(data.observation$NTproBNP.unit)
  data.observation$NTproBNP.unitLabel <- as.character(data.observation$NTproBNP.unitLabel)
  data.observation$NTproBNP.valueCodeableConcept.code <- as.character(data.observation$NTproBNP.valueCodeableConcept.code)
  data.observation$NTproBNP.valueCodeableConcept.system <- as.character(data.observation$NTproBNP.valueCodeableConcept.system)
  data.observation$encounter.start <- format.date.in.char(data.observation, "encounter.start")
  data.observation$encounter.end <- format.date.in.char(data.observation, "encounter.end")

  # Generate the patient identifier as work around for joining using subject with long strings (disclosure risk)
  data.observation <- generate.and.join.pid(data.cohort, data.observation)

  colnames(data.observation) <- c("patient_id", "encounter_id", "nt_pro_bnp_value",
                                  "nt_pro_bnp_comparator", "nt_pro_bnp_value_code", "nt_pro_bnp_value_system",
                                  "nt_pro_bnp_code", "nt_pro_bnp_system", "nt_pro_bnp_unit", "nt_pro_bnp_unit_label",
                                  "nt_pro_bnp_unit_system", "encounter_start", "encounter_end", "id", "pid")
  return(data.observation)
}

transform.diagnosis <- function(data.cohort, data.diagnosis) {
  # Generate an independent and surrogate id column
  data.diagnosis$id <- 1:nrow(data.diagnosis)

  # Transform the data type
  data.diagnosis$condition.id <- as.character(data.diagnosis$condition.id)
  data.diagnosis$clinicalStatus.code <- as.character(data.diagnosis$clinicalStatus.code)
  data.diagnosis$clinicalStatus.system <- as.character(data.diagnosis$clinicalStatus.code)
  data.diagnosis$verificationStatus.code <- as.character(data.diagnosis$clinicalStatus.code)
  data.diagnosis$verificationStatus.system <- as.character(data.diagnosis$clinicalStatus.system)
  data.diagnosis$code <- as.character(data.diagnosis$code)
  data.diagnosis$code.system <- as.character(data.diagnosis$code.system)
  data.diagnosis$subject <- as.character(data.diagnosis$subject)
  data.diagnosis$encounter.id <- as.character(data.diagnosis$encounter.id)
  data.diagnosis$diagnosis.use.code <- as.character(data.diagnosis$diagnosis.use.code)
  data.diagnosis$diagnosis.use.system <- as.character(data.diagnosis$diagnosis.use.system)

  # Generate the patient identifier as work around for joining using subject with long strings (disclosure risk)
  data.diagnosis <- generate.and.join.pid(data.cohort, data.diagnosis)

  colnames(data.diagnosis) <- c("patient_id", "condition_id", "clinical_status_code", "clinical_status_system",
                                  "verification_status_code", "verification_status_system",
                                  "diagnosis_code", "diagnosis_code_system", "encounter_id",
                                  "diagnosis_use_code", "diagnosis_use_system", "id", "pid")
  return(data.diagnosis)
}

######################
# Define the metadata of the expected data structure for data object "patient"
# and save the data into the OPAL server
import.patient <- function (connection, project.name, data.patient) {
  table.name.patient <- "patient"

  features.patient <- tibble::tribble(
    ~name, ~valueType, ~`label:en`, ~`Namespace::Name`, ~unit, ~repeatable, ~index,
    "patient_id", "character", "patient.identifier", NA, NA, 0, 1,
    "gender", "integer", "gender", NA, NA, 0, 2,
    "age", "integer", "age", NA, NA, 0, 3,
    "id", "integer", "id", NA, NA, 0, 4,
    "pid", "integer", "pid", NA, NA, 0, 5
  )

  dict.patient <- dictionary.apply(tibble = tibble::as_tibble(data.patient), variables = features.patient)

  opal.table_save(opal = connection,
                  project = project.name,
                  table = table.name.patient, id.name = "id", type = "Patient",
                  tibble = dict.patient, force = T)
}

######################
# Define the metadata of the expected data structure for data object "observation"
# and save the data into the OPAL server
import.observation <- function(connection, project.name, data.observation) {
  table.name.observation <- "observation"

  features.observation <- tibble::tribble(
    ~name, ~valueType, ~`label:en`, ~`Namespace::Name`, ~unit, ~repeatable, ~index,
    "id", "integer", "id", NA, NA, 0, 15,
    "patient_id", "character", "patient.identifier", NA, NA, 0, 1,
    "pid", "integer", "id", NA, NA, 0, 16,
#    "measurement_date", "date", "measurement.date", NA, NA, 0, 2,
    "nt_pro_bnp_value", "float", "ntprobnp.value", NA, NA, 0, 4,
    "nt_pro_bnp_comparator", "character", "ntprobnp.comparator", NA, NA, 0, 5,
    "nt_pro_bnp_value_code", "character", "ntprobnp.value.code", NA, NA, 0, 6,
    "nt_pro_bnp_value_system", "character", "ntprobnp.value.system", NA, NA, 0, 7,
    "nt_pro_bnp_code", "character", "ntprobnp.code", NA, NA, 0, 8,
    "nt_pro_bnp_system", "character", "ntprobnp.system", NA, NA, 0, 9,
    "nt_pro_bnp_unit", "character", "ntprobnp.unit", NA, NA, 0, 10,
    "nt_pro_bnp_unit_label", "character", "ntprobnp.unit.label", NA, NA, 0, 11,
    "nt_pro_bnp_unit_system", "character", "ntprobnp.unit.system", NA, NA, 0, 12,
    "encounter_id", "character", "encounter.id", NA, NA, 0, 3,
    "encounter_start", "date", "encounter.start", NA, NA, 0, 13,
    "encounter_end", "date", "encounter.end", NA, NA, 0, 14,
  )

  dict.observation <- dictionary.apply(tibble = tibble::as_tibble(data.observation), variables = features.observation)

  opal.table_save(opal = connection,
                  project = project.name,
                  table = table.name.observation, id.name = "id", type = "Observation",
                  tibble = dict.observation, force = T)
}

######################
# Define the metadata of the expected data structure for data object "diagnosis"
# and save the data into the OPAL server
import.diagnosis <- function(connection, project.name, data.diagnosis) {
  table.name.diagnosis <- "diagnosis"

  features.diagnosis <- tibble::tribble(
    ~name, ~valueType, ~`label:en`, ~`Namespace::Name`, ~unit, ~repeatable, ~index,
    "id", "integer", "id", NA, NA, 0, 12,
    "condition_id", "character", "condition.id", NA, NA, 0, 1,
    "clinical_status_code", "character", "clinical.status.code", NA, NA, 0, 2,
    "clinical_status_system", "character", "clinical.status.system", NA, NA, 0, 3,
    "verification_status_code", "character", "verification.status.code", NA, NA, 0, 4,
    "verification_status_system", "character", "verification.status.system", NA, NA, 0, 5,
    "diagnosis_code", "character", "diagnosis.code", NA, NA, 0, 6,
    "diagnosis_code_system", "character", "diagnosis.code.system", NA, NA, 0, 7,
    "patient_id", "character", "patient.id", NA, NA, 0, 8,
    "encounter_id", "character", "encounter.id", NA, NA, 0, 9,
    "diagnosis_use_code", "character", "diagnosis.code", NA, NA, 0, 10,
    "diagnosis_use_system", "character", "diagnosis.system", NA, NA, 0, 11,
    "pid", "integer", "pid", NA, NA, 0, 13
  )

  dict.diagnosis <- dictionary.apply(tibble = tibble::as_tibble(data.diagnosis), variables = features.diagnosis)

  opal.table_save(opal = connection,
                  project = project.name,
                  table = table.name.diagnosis, id.name = "id", type = "Condition",
                  tibble = dict.diagnosis, force = T)
}
######################
# Define the metadata of the expected data structure for data object "analysis_nt_pro_bnp"
# and save the data into the OPAL server
import.analysis <- function(connection, project.name, data.analysis) {
  table.name.analysis <- "analysis_nt_pro_bnp"

  features.analysis <- tibble::tribble(
    ~name, ~valueType, ~`label:en`, ~`Namespace::Name`, ~unit, ~repeatable, ~index,
    "id", "integer", "id", NA, NA, 0, 15,
    "encounter_id", "character", "encounter.id", NA, NA, 0, 1,
    "patient_id", "character", "patient.identifier", NA, NA, 0, 2,
    "nt_pro_bnp_value", "float", "ntprobnp.value", NA, NA, 0, 3,
    "nt_pro_bnp_unit", "character", "ntprobnp.unit", NA, NA, 0, 4,
    "nt_pro_bnp_comparator", "character", "ntprobnp.comparator", NA, NA, 0, 5,
    "gender", "integer", "gender", NA, NA, 0, 6,
    "age", "integer", "age", NA, NA, 0, 7,
    "encounter_start", "date", "encounter.start", NA, NA, 0, 8,
    "encounter_end", "date", "encounter.end", NA, NA, 0, 9,
    "IdiopathicHypotension","integer","IdiopathicHypotension", NA, NA, 0 ,10,
    "AtrialFibrillation","integer","AtrialFibrillation", NA, NA, 0 ,11,
    "MyocardialInfarction","integer","MyocardialInfarction", NA, NA, 0 ,12,
    "HeartFailure","integer","HeartFailure", NA, NA, 0 ,13,
    "Stroke","integer","Stroke", NA, NA, 0 ,14,
    "pid", "integer", "pid", NA, NA, 0, 16
  )
  
  
  # Assuming 'data.unit' now contains a synthetic 'id' column
  dict.analysis <- dictionary.apply(tibble = tibble::as_tibble(data.analysis), variables = features.analysis)
  
  opal.table_save(opal = connection,
                  project = project.name,
                  table = table.name.analysis, id.name = "id", type = "Extension",
                  tibble = dict.analysis, force = TRUE
  )
}

# Creates the connection object usingthe administrator credentials
# All credential details will be set in .RProfile file
# which should be executed before running the import script to set the environment
create.opal.connection <- function() {
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

  return (connection)
}

create.project <- function(connection, project.name) {
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
}

batch.upload.to.opal <- function(connection, project.name, data.patient, data.observation,  data.diagnosis, data.analysis) {
  # Import data into three tables, i.e., patient, observation, and diagnosis
  import.patient(connection = connection, project.name = project.name, data.patient = data.patient)
  import.observation(connection = connection, project.name = project.name, data.observation = data.observation)
  import.diagnosis(connection = connection, project.name = project.name, data.diagnosis = data.diagnosis)
  import.analysis(connection = connection, project.name = project.name, data.analysis = data.analysis)
}

# The source code of the following functions uploading data in chunks has been provided by Raphael Verbuecheln
# and Stefanie Biergans from UK Tuebingen. Thanks to both, large data collection can be uploaded.
# The functions are organized per table which are summarized by chunk.upload.to.opal.
# If you encounter problems in terms of time-outs etc. please modify the chunk size in this function.
chunk.upload.patient <- function(connection, project.name, data.patient, chunk.size) {
  # Patient Upload in chunks
  length.df <- nrow(data.patient)
  for (i in 1 : floor(length.df / chunk.size) ) {
    current.part <- data.patient[((i - 1) * chunk.size + 1) : (i * chunk.size),]
    import.patient(connection = connection, project.name = project.name, data.observation = current.part)
  }
  # Last Chunk
  current.part <- data.patoent[(floor(length.df / chunk.size) * chunk.size + 1) : length.df,]
  import.patient(connection = connection, project.name = project.name, data.observation = current.part)
}

chunk.upload.observation <- function(connection, project.name, data.observation, chunk.size) {
  # Observation Upload in chunks
  for (i in 1 : floor(length.df / chunk.size) ) {
    current.part <- data.observation[((i - 1) * chunk.size + 1) : (i * chunk.size),]
    import.observation(connection = connection, project.name = project.name, data.observation = current.part)
  }
  # Last Chunk
  current.part <- data.observation[(floor(length.df / chunk.size) * chunk.size + 1) : length.df,]
  import.observation(connection = connection, project.name = project.name, data.observation = current.part)
}

chunk.upload.diagnosis <- function(connection, project.name, data.diagnosis, chunk.size) {
  # Diagnosis Upload in Chunks
  length.df <- nrow(data.diagnosis)
  for (i in 1: floor(length.df / chunk.size)) {
    current.part <- data.diagnosis[((i - 1) * chunk.size + 1) : (i * chunk.size),]
    import.diagnosis(connection = connection, project.name = project.name, data.diagnosis = current.part)
  }
  current.part <- data.diagnosis[(floor(length.df / chunk.size) * chunk.size + 1) : length.df,]
  import.diagnosis(connection = connection, project.name = project.name, data.diagnosis = current.part)
}

chunk.upload.analysis <- function(connection, project.name, data.analysis, chunk.size) {
  # Analysis Upload in Chunks
  length.df <- nrow(data.analysis)
  for (i in 1: floor(length.df / chunk.size)){
    current.part <- data.analysis[((i - 1) * chunk.size + 1) : (i * chunk.size),]
    import.analysis(connection = connection, project.name = project.name, data.analysis = current.part)
  }
  current.part <- data.analysis[(floor(length.df / chunk.size) * chunk.size + 1) : length.df,]
  import.analysis(connection = connection, project.name = project.name, data.analysis = current.part)
}

# This function summarizes the data import in chunks using table-specific functions
chunk.upload.to.opal <- function(connection, project.name, data.patient, data.observation,  data.diagnosis, data.analysis) {
  chunk.size <- 10000
  chunk.upload.patient(connection, project.name, data.patient, chunk.size)
  chunk.upload.observation(connection, project.name, data.observation, chunk.size)
  chunk.upload.diagnosis(connection, project.name, data.diagnosis, chunk.size)
  chunk.upload.analysis(connection, project.name, data.analysis, chunk.size)
}

# Logout from the OPAL server
close.opal.connection <- function(connection) {
  opal.logout(connection)
}

# The function saves the data partitions (tables) into data files. File names are prespecified.
write.data.to.files <- function(data.patient, data.observation,  data.diagnosis, data.analysis) {
  write.csv2(data.patient, file = "./data-patient.csv")
  write.csv2(data.observation, file = "./data-observation.csv")
  write.csv2(data.diagnosis, file = "./data-diagnosis.csv")
  write.csv2(data.analysis, file = "./data-analysis.csv")
}