# Structure of Import-Data
## 1) Overview
In the following two section, we show the structure of the relevant data. The data is provided with two data files, cohort.csv and diagnosis.csv. You will find some synthetically generated test data in this [directory](../opal-import/test-data) within this git repository.

All columns with data type date should follow the format ([ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html)) _**_%Y-%m-%d_**_. This format represents the year with four digits and the months and days with leading zeros. An example is **2023-01-01**. Please note, time zones are not represented by this format. The import expects that there is no time zone specification within the date data.

## 2) Structure of Cohort Data
The data file cohort.csv has 16 columns using the structure definition as show by the table below. While all data within a CSV file are of type string, we expect data from the export of a database with the following format. 

The number of columns is checked by the import script. 

| Column Name                          | Data Type          |
|--------------------------------------|--------------------|
| subject                              | character / string |
| NTproBNP.date                        | date               |
| encounter.id                         | character / string |
| NTproBNP.valueQuantity.value         | number             |
| NTproBNP.valueQuantity.comparator    | character / string |
| NTproBNP.valueCodeableConcept.code   | character / string |
| NTproBNP.valueCodeableConcept.system | character / string |
| NTproBNP.code                        | character / string |
| NTproBNP.codeSystem                  | character / string |
| NTproBNP.unit                        | character / string |
| NTproBNP.unitLabel                   | character / string |
| NTproBNP.unitSystem                  | character / string |
| gender                               | character / string |
| birthdate                            | date               |
| encounter.start                      | date               |
| encounter.end                        | date               |


## 3) Structure of Diagnosis Data
The data file diagnosis.csv has 11 columns using the structure definition as show by the table below. While all data within a CSV file are of type string, we expect data from the export of a database with the following format.

The number of columns is checked by the import script.

| Column Name               | Data Type           |
|---------------------------|---------------------|
| condition.id              | character / string  |
| clinicalStatus.code       | character / string  |
| clinicalStatus.system     | character / string  |
| verificationStatus.code   | character / string  |
| verificationStatus.system | character / string  |
| code                      | character / string  |
| code.system               | character / string  |
| subject                   | character / string  |
| encounter.id              | character / string  |
| diagnosis.use.code        | character / string  |
| diagnosis.use.system      | character / string  |
