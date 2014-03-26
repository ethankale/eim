# Required for the script to work.  Can skip installation if already installed.
install.packages("sqldf")
library(sqldf)

# Import data.  Defaults to a test data set.
eimData <- read.csv("test-data-sw.csv")
 
# Create tables to summarize data
# Count of Results by method
resultCounts <- sqldf("SELECT `Result_Parameter_Name`, `Sample_Matrix`, `Fraction_Analyzed`, `Result_Method`,
    Count(DISTINCT `Location_ID`) AS Locations, Count(`Result_Value`) AS Results
    FROM `eimData`
    GROUP BY `Result_Parameter_Name`, `Sample_Matrix`, `Fraction_Analyzed`, `Result_Method`")

# Rows with missing required information (required for all Results, not conditionally required)
qualifiers <- sqldf("SELECT `Result_Parameter_Name`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`
    FROM `eimData`
    WHERE `Study_ID`  '' ")

# Rows with result qualifiers requiring detection & reporting limits
missingData <- sqldf("SELECT `Result_Parameter_Name`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`, 
    `Result_Data_Qualifier`, `Result_Reporting_Limit`, `Result_Reporting_Limit_Type`,
    `Result_Detection_Limit`, `Result_Detection_Limit_Type`
    FROM `eimData`
    WHERE `Study_ID` = '' OR  `Study_ID` IS NULL
      OR `Location_ID` = '' OR  `Location_ID` IS NULL
      OR `Study_Specific_Location_ID` = '' OR  `Study_Specific_Location_ID` IS NULL
      OR `Field_Collection_Type` = '' OR  `Field_Collection_Type` IS NULL
      OR `Field_Collector` = '' OR  `Field_Collector` IS NULL
      OR `Field_Collection_Start_Date` = '' OR  `Field_Collection_Start_Date` IS NULL
      ")