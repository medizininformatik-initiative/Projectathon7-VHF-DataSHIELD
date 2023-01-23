# ################################
# Medical Informatics Initiative
# 7th Projectathon
# Project: VHF - DataSHIELD
# Install packages on the R server required for the VHF analysis
#
# Version: 1.0
# Last Update: 19.01.2023
# Toralf Kirsten (tkirsten@uni-leipzig.de)
# ################################

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

# Install required packages on the R server which is maintained by the OPAL server
dsadmin.install_github_package(connection, pkg = "dsBase", username = "datashield", ref = "v6.2.0", profile = "default")
dsadmin.install_github_package(connection, pkg = "dsBinVal", username = "difuture-lmu", ref = "main", profile = "default")

# Logout from the OPAL server
opal.logout(connection)

# Clean up
rm(list = ls())

######### End of the script