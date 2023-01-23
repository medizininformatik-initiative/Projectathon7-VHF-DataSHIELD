# DataSHIELD Installation

## Organizational Requirements and "Installation"

### Privacy Documentation, DSFA, et al.
Each information processing system used at the hospital requires a concept w.r.t. data privacy and security but also operational procedures.
The concept consists of a **global part** that is generic in a way that it can be used in nearly every hospital, and a **local part** that takes all specifics of the current site.

**_It would be good to leave the slide of Mrs Schmidt here._**

There are documents representing the global part of the overall concept which are available within the TMF Sharepoint. 
You need to have specific credentials to access these documents. In case you already have access, you will find these documents 
following the internal menu path (see menu on the left hand side at the TMF Sharepoint user interface) Taskforces / TF Verteilte Analysen / 05_HandreichungDataSHIELD 

### Non Disclosure Control
tba

## Technical Requirements and Installation

### Overview
The architecture spans over three networks. 
1) The clinical network consists of information systems producing and let capture patient data. Data at this level is the source and need to be transferred to the next network.
2) The MEDIC-network contains all storages and information systems integrating clinical data at the DIC. This network contains the DataSHIELD installation.
3) Part of the DMZ-network is a reverse proxy that is connected to the DataSHIELD installation. A whitelist allows very specifically the access on an IP address basis.

**_It would be good to leave the slide of Mrs Schmidt here._**

Each network is separated and secured by firewalls.
In the following, we will refer to the second network for the DataSHIELD installation.

### DataSHIELD Installation
There is a Docker-Image-based installation available. Each component is represented by a single container. The simplest way to stick and run them together, is to use Docker-Compose. At the Leipzig University, we have used the following bash script to set up all components.

Install the Docker framework first. Then create the following script named by "foo-bar".
```bash
foo bar
```

### More Information and Help
The MII supports a chat for DataSHIELD: https://mii.zulipchat.com/#narrow/stream/313115-DataSHIELD

Official documentation: https://opaldoc.obiba.org/en/dev/admin/installation.html

## Open Questions and Aspects
- **restrictive vs. permissive mode**: The difference is that the first allows to execute very few remote functions making an analysis nearly impossible, whereas the second necessitates often a non-disclosure-control statement. 
  - Which mode of operation (or access and execution mode) should be used is specific at infrastructure level not at project level. 
  - https://data2knowledge.atlassian.net/wiki/spaces/DSDEV/pages/714768398/Disclosure+control
  - We would argue for the permissive mode.
- We need to adapt the available non-disclosure-control for R server package dsBinVal
- What is the overall procedure to get the non-disclosure control accepted locally? 
- Versioning of DataSHIELD installation and packages (dsBase and dsBinVal)
- 