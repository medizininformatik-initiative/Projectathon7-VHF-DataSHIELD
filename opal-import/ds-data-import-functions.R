# This function creates a pid vector for each patient
#
generate.and.join.pid <- function(data.cohort, x) {
  pat <- unique(data.cohort[,c(1,13)])
  pat <- pat[order(pat$subject),]
  pat$pid <- 1:nrow(pat)
  pat$gender <- NULL
  x <- merge(x = x, y = pat, by = "subject")

  return(x)
}

transform.patient <- function(data.cohort) {
  data.patient <- unique(data.cohort[,c(1, 12, 15)])
  data.patient <- data.patient[order(data.patient$subject),]

  # Generate an independent and surrogate id column
  data.patient$id <- 1:nrow(data.patient)
  data.patient$pid <- data.patient$id

  # Transform the data type
  data.patient$subject <- as.character(data.patient$subject)
  data.patient$gender <- as.character(data.patient$gender)
  data.patient$age <- as.numeric(data.patient$age)

  colnames(data.patient) <- c("patient_id", "gender", "age", "id", "pid")
  return(data.patient)
}

transform.observation <- function(data.cohort) {
  data.observation <- unique(data.cohort[,c(1:11, 13, 14)])

  # Generate an independent and surrogate id column
  data.observation$id <- 1:nrow(data.observation)
  # Transform the data type
  data.observation$subject <- as.character(data.observation$subject)
# The next feature has been removed from the data set since it has not been applied for
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
  data.observation$encounter.start <- as.Date(data.observation$encounter.start, format = "%Y-%m-%d")
  data.observation$encounter.end <- as.Date(data.observation$encounter.end, format = "%Y-%m-%d")

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
    "gender", "character", "gender", NA, NA, 0, 2,
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
