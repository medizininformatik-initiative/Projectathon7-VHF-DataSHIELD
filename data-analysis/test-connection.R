rm(list = ls())

require(DSI)
require(DSOpal)
require(opalr)


# Connect to the OPAL server


# Add login data
builder <- DSI::newDSLoginBuilder()
source("./set-login-data.R")
login.data <- builder$build()

# Login to all OPAL servers
connections <- DSI::datashield.login(logins = login.data)

# Load data from patient table and manage it by temporary variable "patient"
DSI::datashield.assign.table(conns = connections, symbol = "patient", table = "VHF.patient", variables = c("pid", "gender", "age"))



# Logout from the OPAL server
DSI::datashield.logout(connections)

# Clean up
rm(list = ls())
######### End of the script