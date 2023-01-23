# ################################
# Medical Informatics Initiative
# 7th Projectathon
# Project: VHF - DataSHIELD
# Cleaning up project VHF and data from OPAL
#
# Version: 1.0
# Last Update: 19.01.2023
# Toralf Kirsten (tkirsten@uni-leipzig.de)
# ################################

# Load opal-for-r library
# You need to install this library first before you can use it.
require(opalr)

# Connect to the OPAL server
# You need a user account with permissions to create a project and add data
# Don't use self signed certificates (for the OPAL server) - it doesn't work properly
user.name <- !is.na(Sys.getenv("OPAL_USER_NAME", NA))
pass.word <- !is.na(Sys.getenv("OPAL_USER_PASSWORD", NA))
opal.server.url <- !is.na(Sys.getenv("OPAL_SERVER_URL", NA))

# Login to the OPAL server
connection <- opal.login(username = user.name,
                         password = pass.word,
                         url = opal.server.url, opts=list(ssl_verifyhost=0,ssl_verifypeer=0))

# Please, specify the project name that should be deleted
project.name <- "VHF"

# Remove the project within the OPAL server
if (opal.project_exists(opal = connection, project = project.name)) {
  opal.project_delete(opal = connection, project = project.name)
} else {
  print(paste("The project \"", project.name, "\" doesn't exist."))
}

# Logout from the OPAL server
opal.logout(connection)

# Clean up
rm(list = ls())

######### End of the script