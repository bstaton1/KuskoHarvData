# KuskoHarvData

> R package that provides easy access to data collected by the Kuskokwim River in-season subsistence salmon harvest monitoring program. Includes compiled estimates of harvest (by species and area) and effort (by area) for each drift net subsistence fishing opportunity (estimates generated using the '[KuskoHarvEst](https://github.com/bstaton1/KuskoHarvEst)' R package).

> Prior to the construction of this package, these data had been stored in separate places and in various formats. This new standardized and comprehensive format facilitates analyses that may provide greater insights about the behavior of this fishery during short-duration block harvest periods. 

## Installation

Run this code in the R console to install 'KuskoHarvData':

```R
install.packages("remotes")
remotes::install_github("bstaton1/KuskoHarvData")
```

## Accessing the Data

'KuskoHarvData' ships with five data sets:

### Opportunity Meta-Data

>_Data set under construction, check back soon._

### Raw Interview Data

>Contains fisher interview responses gathered during primarily access point creels of completed trips. Example variables include: the date, trip start/end times, active fishing time, net length, and salmon harvest by species.

```R
data(interview_data_master, package = "KuskoHarvData")
```

### Raw Flight Count Data

>Contains aerial counts of drift boats by area of the river.

```R
data(flight_data_master, package = "KuskoHarvData")
```

### Compiled Effort Estimates

>Contains estimates of the total number of drift boat trips that occurred in a day of fishing. Area-specific estimates are included as well.

```R
data(effort_estimate_master, package = "KuskoHarvData")
```

### Compiled Harvest Estimates

>Contains estimates of the total number of salmon harvested by drift boat trips in a day of fishing. Area- and species-specific estimates are included, as are estimates of the bootstrap standard deviation and 95% confidence intervals.

```R
data(harvest_estimate_master, package = "KuskoHarvData")
```

## Acknowledgements

Many organizations and people have collected the data that are contained in this package. These include: the Orutsararmiut Native Council (interviews at the Bethel boat harbor and surrounding fish camps), the Kuskokwim River Inter-Tribal Fish Commission (interviews at various villages), the Alaska Department of Fish and Game (interviews at various villages), and the US Fish and Wildlife Service (aerial counts and some roving interviews). 

Funding for the compilation of existing data sets into this package was provided by the Arctic-Yukon-Kuskokwim Sustainable Salmon Initiative, administered by the Bering Sea Fisherman's Association through grant #AC-2106 to Quantitative Ecological Services, LLC for the project period July 2021 to August 2023.
