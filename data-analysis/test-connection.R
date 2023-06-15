rm(list = ls())

require(DSI)
require(DSOpal)
require(opalr)
require(dsBaseClient)

# Connect to the OPAL server


# Add login data
builder <- DSI::newDSLoginBuilder()
source("data-analysis/set-login-data.R")
login.data <- builder$build()

# Login to all OPAL servers
connections <- datashield.login(logins = login.data)

# Load data from patient table and manage it by temporary variable "patient"
datashield.assign.table(conns = connections, symbol = "patient", table = "VHF.patient", variables = c("pid", "gender", "age"))

# Calculate the mean over the patient's age
ds.mean(x = "patient$age", type = "split", datasources = connections)

# Grab potential errors that have been reported at each DataSHIELD server
datashield.errors()

# Logout from the OPAL server
datashield.logout(connections)

# Clean up
rm(list = ls())
######### End of the script