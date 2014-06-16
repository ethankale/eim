######
# EIM Prescreen script
# Intended for data coordinators in WA ECY to use
# Checks for common violations of business rules in 
#  data formatted to be submitted to EIM as .csv
#
# Assumes the addition of a "Row" column with the 
#  row number (to allow easy reference back to orignal
#  dataset.)
######


######
# Required for the script to work.  Must be installed.
######
library(sqldf)
library(plyr)
library(lattice)
library(gridExtra)

######
# Import data.  Defaults to a test data set.  
######
eimData <- read.csv("Z:/batches/results/G1300075/Ebey'sResults2013Q1-3.xls.xml_1166.csv")

# Optional - handy for my particular setup.
setwd("Z:/ecy-wa-eim-preload")

# Create "New_Name" column to facilitate summaries.
eimData$New_Name <- apply(eimData, 1, function(row) paste(row["Result_Parameter_Name"], row["Sample_Matrix"], row["Result_Value_Units"], sep="\n"))
eimData <- eimData[with(eimData, order(New_Name)), ]

# Parse out sample timelines
eimData$Field_Collection_End_Date <- as.character(eimData$Field_Collection_End_Date)
i = 1

for(endDate in eimData$Field_Collection_End_Date) {
  if(is.na(endDate)) {
    eimData$Field_Collection_End_Date[i] <- as.character(eimData$Field_Collection_Start_Date[i])
  } else {
    eimData$Field_Collection_End_Date[i] <- endDate
  }
  i <- i+1
}

eimData$Collection_Days <- as.numeric(as.Date(eimData$Field_Collection_End_Date, "%m/%d/%Y") - as.Date(eimData$Field_Collection_Start_Date, "%m/%d/%Y"))
eimData$CollectToLab_Days <- as.numeric(as.Date(eimData$Lab_Analysis_Date, "%m/%d/%Y") - as.Date(eimData$Field_Collection_Start_Date, "%m/%d/%Y"))

# Pull in supporting datasets
parameters <- read.csv("parameters.csv")

qualifiers <- read.csv("qualifiers.csv")
colnames(qualifiers) <- c("code", "description")

sampleSources <- read.csv("sampleSources.csv")

######
# Visual summaries of the data (PDF)
######

pdf("latticePlot.pdf", width=8, height=10.5, paper="letter")

# Lattice plot of data qualifiers and location IDs.

qualifiersPlot <- xyplot(Result_Value ~ as.Date(Field_Collection_Start_Date, "%m/%d/%Y") | New_Name,
  data   = eimData, 
  groups = Result_Data_Qualifier,
  main   = "All Results \n Data Qualifier Grouping",
  auto.key = list(columns=3),
  layout = c(3,4),
  xlab   = "Date",
  ylab   = "Value",
  strip  = strip.custom(bg = "gray"),
  as.table = TRUE,
  par.strip.text = list(
    lines = 3.5,
    cex   = .65
  ),
  type    = c("p"),
  scales = list(y = list(relation = "free"))
)
print(qualifiersPlot)

# I'm sure there is a way to reuse these variables; unfortunately, update() doesn't work
#  when you change the group, and I can't figure out any other way to do it.
locationsPlot <- xyplot(Result_Value ~ as.Date(Field_Collection_Start_Date, "%m/%d/%Y") | New_Name,
  data   = eimData, 
  groups = Location_ID,
  main   = "All Results \n Location Grouping",
  auto.key = list(columns=3),
  layout = c(3,4),
  xlab   = "Date",
  ylab   = "Value",
  strip  = strip.custom(bg = "gray"),
  as.table = TRUE,
  par.strip.text = list(
   lines = 3.5,
   cex   = .65
  ),
  type    = c("p"),
  scales = list(y = list(relation = "free"))
)
print(locationsPlot)

# How long were the results held in a lab
holdingPlot <- hist(eimData$CollectToLab_Days, xlab="Days from Sample Start to Lab Analysis", ylab="Number of Results",
                    main="Sample Holding Time", breaks=100)
print(holdingPlot)

# How long did it take to complete sampling
collectionPlot <- hist(eimData$Collection_Days, xlab="Days from Sample Start to Sample End", ylab="Number of Results", 
                       main="Sample Time", breaks=100)
print(collectionPlot)

######
# Create tables to summarize data
######

# Count of Results by method
resultCounts <- sqldf("SELECT `Result_Parameter_Name`, `Sample_Matrix`, `Fraction_Analyzed`, `Result_Method`,
  Count(DISTINCT `Location_ID`) AS Locations, Count(`Result_Value`) AS Results
  FROM `eimData`
  GROUP BY `Result_Parameter_Name`, `Sample_Matrix`, `Fraction_Analyzed`, `Result_Method`")

# List of parameters by field collection type
paramCollectType <- aggregate(eimData$Row, 
                 list(CollectionType = eimData$Field_Collection_Type, 
                      ParameterName  = eimData$Result_Parameter_Name
                      ), 
                 length)

# Summarize subsets of data
# Remove the NA values for Result_Value, to avoid messing up the summary

cleanData <- eimData[-which(is.na(eimData$Result_Value)), ]

summaries <- ddply(
  cleanData, 
  .(Location_ID, Result_Parameter_Name, Result_Value_Units, Sample_Matrix, Fraction_Analyzed, Result_Method), 
  summarize, 
  count = signif(length(Result_Value), digits = 3),
  mean  = signif(mean(Result_Value), digits = 3),
  max   = signif(max(Result_Value), digits = 3),
  min   = signif(min(Result_Value), digits = 3),
  q25   = signif(quantile(Result_Value)[2], digits = 3),
  na.rm = TRUE
)

######
# Create tables of rows with missing/possibly wrong values
######

# Rows with missing required information (required for all Results, not conditionally required)
missingData <- sqldf("SELECT `Row`, `Result_Parameter_Name`, `Location_ID`, `Study_Specific_Location_ID`, `Field_Collection_Type`, `Field_Collector`,
    `Field_Collection_Start_Date`, `Field_Collection_Start_Time`, `Sample_Matrix`, `Sample_Source`, `Result_Parameter_Name`
    `Result_Value`, `Result_Value_Units`, `Result_Method`
  FROM `eimData`
  WHERE `Study_ID` = '' OR  `Study_ID` IS NULL
    OR `Location_ID` = '' OR  `Location_ID` IS NULL
    OR `Study_Specific_Location_ID` = '' OR  `Study_Specific_Location_ID` IS NULL
    OR `Field_Collection_Type` = '' OR  `Field_Collection_Type` IS NULL
    OR `Field_Collector` = '' OR  `Field_Collector` IS NULL
    OR `Field_Collection_Start_Date` = '' OR  `Field_Collection_Start_Date` IS NULL
    OR `Sample_Matrix` IS NULL OR `Sample_Matrix` NOT IN
      ('Air/Gas', 'Other Liquid', 'Habitat', 'Solid/Sediment', 'Tissue', 'Water')
    OR `Sample_Source` IS NULL OR `Sample_Source` NOT IN
      ('Indoor Air', 'Outdoor Air', 'Landfill Gas', 'Soil Gas', 'Animal Tissue', 'Animal Tissue - Lab Exposure', 'Plant Tissue', 
        'Periphyton', 'Freshwater Taxonomy', 'Salt/Marine Taxonomy', 'Habitat Metrics', 'Freshwater Sediment', 'Brackish Sediment', 
        'Salt/Marine Sediment', 'Freshwater Porewater', 'Brackish Porewater', 'Salt/Marine Porewater', 'Elutriate', 'Rock/Gravel', 
        'Soil', 'CSO Outfall ', 'CSS In-Line ', 'CSS Catch Basin', 'Stormwater BMP Effluent ', 'Stormwater BMP Mid ', 'Stormwater BMP Influent', 
        'Stormwater Catch Basin', 'Stormwater In-Line', 'Stormwater Outfall ', 'Stormwater Sheetflow', 'Precipitation', 'Fresh/Surface Water', 
        'Brackish Water', 'Salt/Marine Water', 'Groundwater', 'Pit Water', 'Precipitation', 'Water Supply', 'Industrial Discharge', 'Source - Other', 
        'WWTP Effluent'
      )
    OR `Result_Parameter_Name` = '' OR `Result_Parameter_Name` IS NULL
    OR `Result_Value` = '' OR `Result_Value` IS NULL
    OR `Result_Value_Units` = '' OR `Result_Value_Units` IS NULL
    OR `Result_Method` = '' OR `Result_Method` IS NULL
")

# Rows with result qualifiers requiring detection & reporting limits
qualifiersRequired <- sqldf("SELECT `Row`, `Result_Parameter_Name`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`,
  `Result_Data_Qualifier`, `Result_Reporting_Limit`, `Result_Reporting_Limit_Type`,
  `Result_Detection_Limit`, `Result_Detection_Limit_Type`    
  FROM `eimData`
  WHERE length(`Result_Data_Qualifier`) > 0
    AND (`Result_Detection_Limit` IS NULL OR `Result_Detection_Limit` = ''
          OR `Result_Detection_Limit_Type` IS NULL OR `Result_Detection_Limit_Type` NOT IN
            ('MDL','EDL','LOD','IDL','CRDL','UNKNOWN')
          OR `Result_Reporting_Limit` IS NULL OR `Result_Reporting_Limit` = ''
          OR `Result_Reporting_Limit_Type` IS NULL OR `Result_Reporting_Limit_Type` NOT IN
            ('MRL','PQL','EQL','LOQ','SQL','CRQL','LabDef','UNKNOWN')
        )
")

# Rows with detection limits missing detection limit types
missingDL <- sqldf("SELECT `Row`, `Result_Parameter_Name`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`,
  `Result_Data_Qualifier`, `Result_Reporting_Limit`, `Result_Reporting_Limit_Type`,
  `Result_Detection_Limit`, `Result_Detection_Limit_Type`    
  FROM `eimData`
  WHERE `Result_Detection_Limit` IS NOT NULL
    AND (`Result_Detection_Limit_Type` IS NULL OR `Result_Detection_Limit_Type` = '')
")

# Rows flagged as non-detects or estimates that exceed relevent limits
wrongLimits <- sqldf("SELECT `Row`, `Result_Parameter_Name`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`,
  `Result_Data_Qualifier`, `Result_Reporting_Limit`, `Result_Reporting_Limit_Type`,
  `Result_Detection_Limit`, `Result_Detection_Limit_Type`, `Result_Value`
  FROM `eimData`
  WHERE (`Result_Data_Qualifier` = 'U' AND `Result_Value` > `Result_Detection_Limit`)
  OR (`Result_Data_Qualifier` = 'J' AND `Result_Value` >  `Result_Reporting_Limit`)
")

# Rows with missing stormwater-specific data.
missingStormwater <- sqldf("SELECT `Row`, `New_Name`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`,
  `Storm_Event_Qualifier`, `Sample_Collection_Method`, `Result_Value`
  FROM `eimData`
  WHERE `Storm_Event_Qualifier` IS NULL OR `Storm_Event_Qualifier` = ''
  OR `Sample_Collection_Method` IS NULL OR `Sample_Collection_Method` = ''
")

# Rows with missing sediment-specific data.
missingSediment <- sqldf("SELECT `Row`, `Result_Parameter_Name`, `Sample_Matrix`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`, 
  `Field_Collection_Reference_Point`, `Field_Collection_Upper_Depth`,`Field_Collection_Lower_Depth`,
  `Field_Collection_Depth_Units`, `Result_Basis`, `Sample_Collection_Method`, `Result_Value`
  FROM `eimData`
  WHERE `Sample_Matrix` = 'Solid/Sediment'
  AND (`Field_Collection_Reference_Point` IS NULL OR `Field_Collection_Reference_Point` = ''
  OR `Field_Collection_Upper_Depth` IS NULL OR `Field_Collection_Upper_Depth` = ''
  OR `Field_Collection_Lower_Depth` IS NULL OR `Field_Collection_Lower_Depth` = ''
  OR `Field_Collection_Depth_Units` IS NULL OR `Field_Collection_Depth_Units` = ''
  OR `Result_Basis` IS NULL OR `Result_Basis` = '')
")

# Rows with missing water-specific data.
missingWater <- sqldf("SELECT `Row`, `New_Name`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`, 
  `Fraction_Analyzed`, `Result_Value`
  FROM `eimData`
  WHERE `Sample_Matrix` = 'Water'
  AND `Fraction_Analyzed` IS NULL OR `Fraction_Analyzed` NOT IN 
    ('Total', 'Dissolved', 'Suspended', 'Lab Leachate')
")
# Sample Results with missing values
missingSample <- sqldf("SELECT `Row`, `Result_Parameter_Name`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`,
    `Sample_ID`, `Sample_Composite_Flag`, `Lab_Analysis_Date`, `Result_Lab_Name`
  FROM `eimData`
  WHERE `Field_Collection_Type` = 'Sample'
    AND (`Sample_ID` IS NULL OR `Sample_ID` = ''
      OR `Sample_Composite_Flag` IS NULL OR `Sample_Composite_Flag` = ''
      OR `Lab_Analysis_Date` IS NULL OR `Lab_Analysis_Date` = ''
      OR `Result_Lab_Name` IS NULL OR `Result_Lab_Name` = '')
")

# Sample results with missing sample IDs or composite flags
samples   <- eimData[which(eimData$Field_Collection_Type == "Sample"), ]
missingID <- samples[which((samples$Sample_ID == "") || is.na(samples$Sample_ID)), ]
missingComposite <- samples[which((samples$Sample_Composite_Flag == "") || is.na(samples$Sample_Composite_Flag)), ]

# Missing sample matrix or sample source values
missingMatrix <- eimData[which((eimData$Sample_Matrix == "") || is.na(eimData$Sample_Matrix)), ]
wrongSource   <- eimData[which(!(eimData$Sample_Source %in% sampleSources$Valid.Value)), ]

# List of sample source/location combinations (should be 1 to 1)
locationSource <- aggregate(Row ~ Location_ID + Sample_Source, data = eimData, length)
locationSource <- locationSource[order(locationSource$Location_ID), ]

# Invalid qualifiers
wrongQualifier <- sqldf("SELECT `Row`, `New_Name`, `eimData`.`Location_ID`, `eimData`.`Field_Collection_Start_Date`, `eimData`.`Result_Data_Qualifier`
  FROM `eimData`
    LEFT OUTER JOIN `qualifiers`
    ON `eimData`.`Result_Data_Qualifier` = `qualifiers`.`code`
  WHERE `qualifiers`.`code` IS NULL
    AND NOT `Result_Data_Qualifier` = ''
  ORDER BY `Result_Data_Qualifier` DESC
")

# Collection span is not calculable
missingCollectionSpan <- subset(eimData, is.na(eimData$Collection_Days))

######
# Write tables to PDF.
######

if (nrow(wrongQualifier) > 0) {
  grid.newpage()
  grid.table(wrongQualifier, 
             gpar.coretext = gpar(fontsize=10), 
             gpar.coltext  = gpar(fontsize=12),
             gpar.rowfill  = gpar(fill="white", col="black"), 
             gpar.colfill  = gpar(fill="white", col="white"),
             gpar.corefill = gpar(fill="white", col="white"),
             core.just="left",
             rows=NULL
             )
}

if (nrow(paramCollectType) > 0) {
  grid.newpage()
  grid.table(paramCollectType, 
             gpar.coretext = gpar(fontsize=10), 
             gpar.coltext  = gpar(fontsize=12),
             gpar.rowfill  = gpar(fill="white", col="black"), 
             gpar.colfill  = gpar(fill="white", col="white"),
             gpar.corefill = gpar(fill="white", col="white"),
             core.just="left",
             rows=NULL
  )
}

dev.off()
