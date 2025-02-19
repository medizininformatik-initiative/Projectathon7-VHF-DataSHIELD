check.user.name <- function(user.name) {
  if (is.na(user.name)) {
    stop("The user name to access the OPAL server is missing. Check your settings or your environment.")
  }
}

check.password <- function(pass.word) {
  if (is.na(pass.word)) {
    stop("The password to access the OPAL server is missing. Check your settings or your environment.")
  }
}

check.opal.url <- function(url) {
  if (is.na(url)) {
    stop("The URL to access the OPAL server is missing. Check your settings or your environment.")
  }
}

check.credentials <- function(user.name, pass.word, opal.server.url) {
  check.user.name(user.name)
  check.password(pass.word)
  check.opal.url(opal.server.url)
}

check.cohort.file.name <- function(file.loc) {
  if (is.na(file.loc)) {
    stop("The location and the file name to access cohort file is missing. Check your settings or your environment.")
  }
}

check.diagnosis.file.name <- function(file.loc) {
  if (is.na(file.loc)) {
    stop("The location and the file name to access diagnosis file is missing. Check your settings or your environment.")
  }
}

check.file.names <- function(cohort.file.name, diagnosis.file.name) {
  check.cohort.file.name(cohort.file.name)
  check.diagnosis.file.name(diagnosis.file.name)
}