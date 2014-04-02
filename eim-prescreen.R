# Required for the script to work.  Must be installed.
library(sqldf)
library(plyr)
library(lattice)

# Import data.  Defaults to a test data set.  Make some derivative data sets.
eimData <- read.csv("test-data-sw.csv")
eimData$New_Name <- apply(eimData, 1, function(row) paste(row["Result_Parameter_Name"], row["Sample_Matrix"], row["Result_Value_Units"], sep="\n"))
eimData <- eimData[with(eimData, order(New_Name)), ]

# Visual summaries of the data
pdf("latticePlot.pdf", width=8, height=10.5, paper="letter")
print(xyplot(Result_Value ~ as.Date(Field_Collection_Start_Date, "%m/%d/%Y") | New_Name,
        data   = eimData, 
        layout = c(3,4),
        xlab   = "Date",
        ylab   = "Value",
        strip  = strip.custom(bg = "gray"),
        as.table = TRUE,
        par.strip.text = list(
          lines = 3.5,
          cex   = .65
        ),
        type    = c("g", "p"),
        scales = list(y = list(relation = "free")))
      )
dev.off()

######
# Create tables to summarize data
######

# Count of Results by method
resultCounts <- sqldf("SELECT `Result_Parameter_Name`, `Sample_Matrix`, `Fraction_Analyzed`, `Result_Method`,
  Count(DISTINCT `Location_ID`) AS Locations, Count(`Result_Value`) AS Results
  FROM `eimData`
  GROUP BY `Result_Parameter_Name`, `Sample_Matrix`, `Fraction_Analyzed`, `Result_Method`")

# Summarize subsets of data
summaries <- ddply(
  eimData, 
  .(Location_ID, Result_Parameter_Name, Result_Value_Units, Sample_Matrix, Fraction_Analyzed, Result_Method), 
  summarize, 
  count = signif(length(Result_Value), digits = 3),
  mean  = signif(mean(Result_Value), digits = 3),
  max   = signif(max(Result_Value), digits = 3),
  min   = signif(min(Result_Value), digits = 3),
  q25   = signif(quantile(Result_Value)[2], digits = 3)
)

######
# Create tables of rows with missing values
######

# Rows with result qualifiers requiring detection & reporting limits
qualifiers <- sqldf("SELECT `Result_Parameter_Name`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`,
  `Result_Data_Qualifier`, `Result_Reporting_Limit`, `Result_Reporting_Limit_Type`,
  `Result_Detection_Limit`, `Result_Detection_Limit_Type`    
  FROM `eimData`
  WHERE length(`Result_Data_Qualifier`) > 0
    AND (`Result_Detection_Limit` IS NULL OR `Result_Detection_Limit` = ''
          OR `Result_Detection_Limit_Type` IS NULL OR `Result_Detection_Limit_Type` = ''
          OR `Result_Reporting_Limit` IS NULL OR `Result_Reporting_Limit` = ''
          OR `Result_Reporting_Limit_Type` IS NULL OR `Result_Reporting_Limit_Type` = ''
        )
")

# Rows with missing required information (required for all Results, not conditionally required)
missingData <- sqldf("SELECT `Result_Parameter_Name`, `Location_ID`, `Study_Specific_Location_ID`, `Field_Collection_Type`, `Field_Collector`,
    `Field_Collection_Start_Date`, `Field_Collection_Start_Time`, `Sample_Matrix`, `Sample_Source`, `Result_Parameter_Name`
    `Result_Value`, `Result_Value_Units`, `Result_Method`
  FROM `eimData`
  WHERE `Study_ID` = '' OR  `Study_ID` IS NULL
    OR `Location_ID` = '' OR  `Location_ID` IS NULL
    OR `Study_Specific_Location_ID` = '' OR  `Study_Specific_Location_ID` IS NULL
    OR `Field_Collection_Type` = '' OR  `Field_Collection_Type` IS NULL
    OR `Field_Collector` = '' OR  `Field_Collector` IS NULL
    OR `Field_Collection_Start_Date` = '' OR  `Field_Collection_Start_Date` IS NULL
    OR `Sample_Matrix` = '' OR `Sample_Matrix` IS NULL
    OR `Sample_Source` = '' OR `Sample_Source` IS NULL
    OR `Result_Parameter_Name` = '' OR `Result_Parameter_Name` IS NULL
    OR `Result_Value` = '' OR `Result_Value` IS NULL
    OR `Result_Value_Units` = '' OR `Result_Value_Units` IS NULL
    OR `Result_Method` = '' OR `Result_Method` IS NULL
")

# Sample Results with missing values
missingSample <- sqldf("SELECT `Result_Parameter_Name`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`,
    `Sample_ID`, `Sample_Composite_Flag`, `Lab_Analysis_Date`, `Result_Lab_Name`
  FROM `eimData`
  WHERE `Field_Collection_Type` = 'Sample'
    AND `Sample_ID` IS NULL OR `Sample_ID` = ''
      OR `Sample_Composite_Flag` IS NULL OR `Sample_Composite_Flag` = ''
      OR `Lab_Analysis_Date` IS NULL OR `Lab_Analysis_Date` = ''
      OR `Result_Lab_Name` IS NULL OR `Result_Lab_Name` = ''