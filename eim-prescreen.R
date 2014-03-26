# Required for the script to work.  Can skip installation if already installed.
install.packages("sqldf")
library(sqldf)

# Import data.  Defaults to a test data set.
eimData <- read.csv("test-data-sw.csv")
 
# Create tables to summarize data
resultCounts <- sqldf("SELECT `Result_Parameter_Name`, `Sample_Matrix`, `Fraction_Analyzed`, `Result_Method`,
      Count(DISTINCT `Location_ID`) AS Locations, Count(`Result_Value`) AS Results
      FROM `eimData`
      GROUP BY `Result_Parameter_Name`, `Sample_Matrix`, `Fraction_Analyzed`, `Result_Method`")