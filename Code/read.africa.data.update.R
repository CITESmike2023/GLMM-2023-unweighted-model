# read in the PIKE data, MIKE centroid data, carcass summary table, etc.
# make list by MIKEsiteID of which site is in which data source.

#----------------------------------------------
# Get the MIKE centroids and other details.
mike.centers <- readxl::read_excel(file.path("..","Data","2021-10-20_mike_sites_list_UpdatedTo2021.xlsx"),
                                   sheet="mike_sites_lis")

mike.centers <- plyr::rename(mike.centers, c("siteid"="MIKEsiteID",
                                             "name"="MIKEsiteName",
                                             "un_region"="UNRegion",
                                             "subregion"="SubregionName"))
data.source <- data.frame(MIKEsiteID=unique(mike.centers$MIKEsiteID[ mike.centers$UNRegion=="Africa"]), GIS=TRUE, stringsAsFactors=FALSE)
# 1. Set end year
startyear <- 2003
endyear   <- 2022


# 2. Change the name of "carcassummarytable..." file and save file

inputfilename <- file.path("..","Data","carcasssummarytable_2023-07-28.csv")
pike <- read.csv(inputfilename, header=TRUE, as.is=TRUE, strip.white=TRUE)


cat("*** input file name: ", inputfilename, " ****\n")
# analysis only from startyear to endyear
pike <- pike[ pike$year >= startyear,]
pike <- pike[ pike$year <= endyear,]


# select Africa data only
UNRegion.select <- "Africa"
cat("\n\nRestricting PIKE to those countries in ", UNRegion.select, "\n")
pike<- pike[ pike$UNRegion == UNRegion.select,]
cat("\n Here is the number sites reported (including zero carcs.) by year in Africa. \n")
xtabs(~year, data=pike)


pike.original <- pike
# exclude site-years with 0 carcasses reported as not useful for the analysis
select <- pike$TotalNumberOfCarcasses == 0
sum(select)
N.pike.site.years.0.carcasses <- sum(select)  # stat used in the main report
N.pike.site.years.with.carcasses <- sum(select == FALSE) # stat used in the main report
pike <- pike[ !select,]


# find out total number of carcasses reported on
temp <- plyr::ddply(pike, "MIKEsiteID", plyr::summarize,
                    TC =sum(TotalNumberOfCarcasses))
cat("Total number of carcasses reported by site:\n")
temp

# MK -- new code 
cat("Analysis from to:",range(pike$year), "\n")


# << MK - create  mike.pop.est for all possible mike sites with PIKE data across 2003 - endyear

## << MK - create a pop est equal to one for all combination of sites and years
## << MK: head(mike.pop.est)
## MIKEsiteID    year population  SubregionName
## 1        AKG 2003         34 Eastern Africa
## 2        AKG 2006         34 Eastern Africa
# << MK - get all unique site-subregion combo
SSCombo <- unite(pike, col = "keyid", "MIKEsiteID", "SubregionName", sep = "_") %>% 
           select(keyid) %>% unique()
# MK make all SSCombo with all possible years and set population to 1
mike.pop.est <- expand.grid(keyid = SSCombo$keyid, year=2003:endyear, population = 1) %>%
                separate(col="keyid", into = c("MIKEsiteID","SubregionName"), sep="_")

cat("All population estimates set to 1:", all(mike.pop.est$population == 1), "\n" )

# get the base map of africa
# Geographic co-rdinate system is GCS_North_American_1983, projected to NAD_1983_BC_Environment_Albers 
# http://spatialreference.org/ref/sr-org/82/ has the projection string
proj4string = "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs" 

google.map <- ggmap::get_map(c(20,0), maptype="toner-lite",  source="stamen", zoom=3)
base.map <- ggmap(google.map)

google.map2 <- ggmap::get_map(c(20,0), maptype="toner-lite",  source="stamen", zoom=4)
google.map2 <- ggmap::get_map(c(left=-20, bottom=-30, right=50, top =20), 
                              maptype="toner-lite",  source="stamen", zoom=4)
base.map2 <- ggmap(google.map2)



