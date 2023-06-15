######### Specify the login data

# Don't use self signed certificates (for the OPAL server) - it doesn't work properly
project.name <- "VHF"
user.name <- "vhfdatashield"
opal.driver <- "OpalDriver"
options <- "list(ssl_verifyhost=0, ssl_verifypeer=0)"

# UKL
builder$append(server = project.name,
               url = "",
               user = user.name,
               password = "",
               driver = opal.driver,
               options = options)
# Charite
builder$append(server = project.name,
               url = "",
               user = user.name,
               password = "",
               driver = opal.driver,
               options = options)
# ...