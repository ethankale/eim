# Required for the script to work.  Must be installed.
library(sqldf)
library(plyr)
library(ggplot2)
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
        scales = list(y = list(relation = "free")))
      )
dev.off()

# Create tables to summarize data
# Count of Results by method
resultCounts <- sqldf("SELECT `Result_Parameter_Name`, `Sample_Matrix`, `Fraction_Analyzed`, `Result_Method`,
    Count(DISTINCT `Location_ID`) AS Locations, Count(`Result_Value`) AS Results
    FROM `eimData`
    GROUP BY `Result_Parameter_Name`, `Sample_Matrix`, `Fraction_Analyzed`, `Result_Method`")

# Rows with result qualifiers requiring detection & reporting limits
qualifiers <- sqldf("SELECT `Result_Parameter_Name`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`,
    `Result_Data_Qualifier`, `Result_Reporting_Limit`, `Result_Reporting_Limit_Type`,
    `Result_Detection_Limit`, `Result_Detection_Limit_Type`    
    FROM `eimData`
    WHERE length(`Result_Data_Qualifier`) > 0")

# Rows with missing required information (required for all Results, not conditionally required)
missingData <- sqldf("SELECT `Result_Parameter_Name`, `Location_ID`, `Field_Collection_Start_Date`, `Field_Collection_Start_Time`
    FROM `eimData`
    WHERE `Study_ID` = '' OR  `Study_ID` IS NULL
      OR `Location_ID` = '' OR  `Location_ID` IS NULL
      OR `Study_Specific_Location_ID` = '' OR  `Study_Specific_Location_ID` IS NULL
      OR `Field_Collection_Type` = '' OR  `Field_Collection_Type` IS NULL
      OR `Field_Collector` = '' OR  `Field_Collector` IS NULL
      OR `Field_Collection_Start_Date` = '' OR  `Field_Collection_Start_Date` IS NULL
      ")

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