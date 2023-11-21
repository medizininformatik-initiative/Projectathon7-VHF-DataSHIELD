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
datashield.assign.table(conns = connections,
                        symbol = "value.df",
                        table = "VHF.observation",
                        variables = c("pid", "nt_pro_bnp_value", "nt_pro_bnp_value_code", "nt_pro_bnp_comparator", "nt_pro_bnp_unit"))

foo <- ds.isNA(x = "value.df$nt_pro_bnp_value", datasources = connections)
foo
ds.unique(x.name = "value.df$nt_pro_bnp_comparator", newobj = "comparator.cnt", datasources = connections)
ds.length(x = "comparator.cnt", datasources = connections)

ds.make(toAssign = "as.data.frame(unit=c('pgmL', 'ngL', 'pgdL', 'pg100mL', 'pg', 'pgL', 'pmolL'), t.fac=c(1, 1, 100, 100, 100, 1000, 0.118))",
        newobj = "unit.tf", datasources = connections)

data.frame(unit=c('pg/mL', 'ng/L', 'pg/dL', 'pg/100mL', 'pg%', 'pg/L', 'pmol/L'), t.fac=c(1, 1, 100, 100, 100, 1000, 0.118))

data.frame(unit=c('pg/mL', 'ng/L', 'pg/dL', 'pg/100mL', 'pg', 'pg/L'))
datashield.errors()

# Logout from the OPAL server
datashield.logout(connections)

# Clean up
rm(list = ls())
######### End of the script