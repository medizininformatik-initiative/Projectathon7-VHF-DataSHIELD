# Projectathon7-VHF-DataSHIELD

## What it is about
This repository contains the source code and configuration for the 
Projectathon7-VHF-DataShield project that is executed within the MII (2023).

It contains source code, mainly in R, for
- the installation of required R packages on the local R server
- the import of data that have been produced by the retrieval pipeline (see below) into the OPAL server and
- the clean-up pipeline removing all imported data and created tabular structures from the OPAL server

## Who should read it and prior required knowledge
In the following, you will find instructions, mainly for the three initial steps, namely installation of required R packages, import data, and cleaning up (if necessary). This should be of interest for **members of Data Integration Centers**.

Everybody, who would like to use the source code should familiar with running R source code. It is not necessary that you are a professional R programmer. However, you should be able to set the local configuration and execute the source code from an R client. You can use any client you want ranging from the command line (which I prefer) over RStudio, Eclipse, Intellij Idea, and any other IDE (Integrated Development Environment) with a plug-in for R.  

Please follow the steps below. In case you have serious questions or find bugs (which I don't believe), please raise issues with a sufficient description.

## Very quick Overview about DataSHIELD
DataSHIELD is a technical infrastructure allowing you to analyze data (not only medical data) in a distributed but interactive mode without having direct access to data on individual level. As a scientist, you write R code analyzing the data at different sites. In this source code, the analysis functions are remotely executed, i.e., at each site the scientist is connected to. The results are then transferred to the scientist in an aggregated form, i.e., not on individual level anymore. 

DataSHIELD infrastructure consists roughly of three components at each site, an OPAL server, an R server, and database(s). The OPAL server is the management component. It has a web-based user interface but also allows HTTP-based function calls. It internally communicates with the database(s) and the R server. While the R server takes over computational tasks, the database(s) manage(s) data.

More general information can be obtained from https://www.datashield.org/

We have collected some specific information about technical and "organizational" [installation](DataSHIELD-Installation.md).

## Prerequisites, you should know about
Before you start working with this source code you need to know
- there is a DataShield instance at your site available (and it is already working)
- the parameters allowing you to access the OPAL server (URL, user, and password)

The user should have enough permissions to take over the different tasks. The permissions you need differ from task to task. The installation of required packages necessitates administrator access, whereas the data import requires permissions to create new projects and having read/write access to it.

Please specify these parameters either in the .Rprofile or directly each of the R scripts directly.

## 1) Installation of required R packages
Before you import data, you need to configure and add the required R packages to the R server. This includes the following R packages:
- DsBase (6.2.0) -https://github.com/datashield/dsBase
- dsBinVal (1.01) https://github.com/difuture-lmu/dsBinVal

There are different ways allowing you to install the packages. The possibly simplest way is to use the web-base user interface of the OPAL server. 
There is a configuration (you need to have permissions to do that) allowing you to see all already installed packages available in specific a version and to upload and, thus, install a new package. Don't install the same package in different version; this is not handleable by the R server. In this case, the older version will be updated by the newer version with potential site effects to current users and programs using this package.

There is also an R script that installs the two R packages listed above on the R server of your DataSHIELD installation.
You can basically go to the directory [installation](./installation), open the R script and run it (executing it on the commend line or within your preferred IDE). 

**TO DO**: Please configure the access to the OPAL server with URL and credentials (username and password).

**START**: To start the installation via script, please go to and execute the R script [install.packages.R](./installation/install.packages.R) in the directory installation. 

## 2) Data import
Importing data consists of two steps. 
1) Generate the data to be imported
2) Import the data

### 2.1 Generate data to be imported
Please use the data export pipeline that is used in the project [Projectathon7-VHF](https://github.com/medizininformatik-initiative/Projectathon7-VHF) to create the required data. As a result of executing this pipeline, there are two files in comma-separated format (CSV, separator is ";").
- cohort.csv
- diagnosis.csv

Please provide these data files in a way you have access to it; you need read permissions. You can manage both files locally in a directory or somewhere on a file server you have access to. The data import script requires a direct file within any file system, i.e., managing the files within an object store, such as MinIO, and using URL (https://...) for the access is currently not an option.

Don't change the file structure of the two generated data files 

### 2.2 Data import
DataSHIELD internally manages data in projects. A project is basically a "container" for data, such as a database. The projects should be uniquely named; this is mandatory. Each project consists of tables managing the data in tabular format. Each table needs to be uniquely named within a project.

The project name and the table names for this projectathon are pre-specified. **Please do not change them!** Both, the project name ("VHF") and all table names ("Patient", "Condition", and "Diagnosis") need to be harmonized over all partners participating a joint (distributed) analysis. If you already use the project name "VHF", come back to us by raising an issue.  

The data import script does the following:
- it loads the data from the two CSV files listed above.
- transforms the data into three internal tables (called DataFrames)
- creates the project VHF in your OPAL server
- creates the three tables Patient, Condition, and Diagnosis
- saves the data into the three tables

**FURTHER INFO**: Your will find some further information about data import
- https://opaldoc.obiba.org/en/dev/cookbook/import-data/r.html

**TO DO**: Please configure the access to the OPAL server with URL and credentials (user name and password).

**START**: To start the data import, execute the R script [ds-data-import.R](./opal-import/ds-data-import.R) in the directory opal-import. 

## 3) Clean-up
If the data import process is canceled in between or finishes with success - please check the command line output for that - there is the need to remove the project, created tables, and loaded data. This is called clean-up. There are multiple ways to do that. 
First, you can execute this clean-up manually using the OPAL web interface. There is an option allowing you to remove the complete project including all tables and data. You need enough permissions to do that. Second, there is a script called [ds-remove-project.R](./clean-up/ds-remove-project.R) in the directory clean-up. Executing this script will remove the VHF project.

**TO DO**: Please configure the access to the OPAL server with URL and credentials (user name and password). 

**START**: To start the clean-up, execute the R script [ds-remove-project.R](./clean-up/ds-remove-project.R) in directory clean-up.

You can also use both ways to remove the data (and the project) after the projectathon has been successfully finished.