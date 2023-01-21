# ################################
# Medical Informatics Initiative
# 7th Projectathon
# Project: VHF - DataSHIELD
# Importing data into OPAL
#
# Version: 1.0
# Last Update: 19.01.2023
# Maintainer: Toralf Kirsten (tkirsten@uni-leipzig.de)
# ################################

require(opalr)


# Connect to the OPAL server
# You need a user account with permissions to create a project and add data
# Don't use self signed certificates (for the OPAL server) - it doesn't work properly
user.name <- "administrator"
pass.word <- "password"
opal.server.url <- "https://mds-compute-1.medizin.uni-leipzig.de"

# Login to the OPAL server
connection <- opal.login(username = user.name,
                         password = pass.word,
                         url = opal.server.url, opts=list(ssl_verifyhost=0,ssl_verifypeer=0))

# Install required packages on the R server which is maintained by the OPAL server
dsadmin.install_github_package(connection, pkg = "dsBase", username = "datashield", ref = "v6.2.0", profile = "default")
dsadmin.install_github_package(connection, pkg = "dsBinVal", username = "difuture-lmu", ref = "main", profile = "default")

# Logout
dsadmin.package_descriptions(connection, profile = "default")

# Clean up
rm(list = ls())

######### End of the script