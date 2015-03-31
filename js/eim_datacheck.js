
// Logic to import file, parse it, then append a table
//  to the html document.


var data   = [];
var errors = [];

var monthNames = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

var findErrors = function(data) {
    
    // Loop through each row in the EIM template
    var i = 0;
    
    for (i; i<data.length; i++) {
        
        var dateOfCollection = new Date(data[i]["Field_Collection_Start_Date"]);
        
        var rowName = ["Site " + data[i]["Location_ID"],
            monthNames[dateOfCollection.getMonth()] + " " + dateOfCollection.getDay() + ", " + dateOfCollection.getFullYear(),
            data[i]["Fraction_Analyzed"] + " " + data[i]["Result_Parameter_Name"] + " in " + data[i]["Sample_Matrix"]
            ].join(" | "); 
        
        // Loop through each column in the row
        for (var property in data[i]) {
            if (data[i].hasOwnProperty(property)) {
            
                // Check a field in a row for errors (see eimValidator.js)
                var fieldError = eimValidValue(property, data[i][property]);
                
                if (fieldError.length > 0) {
                
                    var tableLocation = "<ins>Row " + (i+1) + ", Column " + property + "</ins>";
                    errors.push({
                        "fieldError":    fieldError,
                        "property":      property, 
                        "tableLocation": tableLocation, 
                        "rowName":       rowName
                    });
                };
            };
        };
    };
}

var drawErrors = function() {
    
    if (data == false) {
        alert("Upload an EIM file to examine first!");
    } else {
    
        // Clear out the main data panel and add new containers
        $("#sidebar").empty();
        $("#uploadedData").empty();
        $("li#menu-summary").removeClass("pure-menu-selected");
        
        $("#uploadedData").append("<h2>Details</h2>");
        $("#uploadedData").append("<ul id='errorList'></ul>");
        
        $("#sidebar").append("<h2>Summary</h2");
        $("#sidebar").append("<ul id='errorSummary'></ul>");
        
        $("li#menu-errors").addClass("pure-menu-selected");
        
        // Loop through each row in the EIM template
        
        for (var i=0; i<errors.length; i++) {
            
            $("#errorList").append("<li class='error'>" 
                + errors[i]["tableLocation"] + " - "
                + errors[i]["fieldError"]    + "<p class='rowName'>" 
                + errors[i]["rowName"]       + "</p></li>"
            );
        };
        
        // Update the menu and status div
        
        $("#errorSummary").append("<li><strong>" + errors.length + "</strong> total errors.</li>");
        $("#errorSummary").append("<li><strong>" + data.data.length + "</strong> total rows.</li>");
    };
};

var summarizeData = function() {
    
    if (data == false) {
        alert("Upload an EIM file to examine first!");
    } else {
        // State changes - empty out divs & change menu
        $("#uploadedData").empty();
        $("#sidebar").empty();
        $("li#menu-errors").removeClass("pure-menu-selected");
        
        $("#sidebar").append("<h2>Parameters</h2");
        $("#sidebar").append("<ul id='parameters'></ul>");
        
        $("#uploadedData").append("<h2>Details</h2>"
            + "<div id='details'><p>Select a parameter to the left.</p></div>"
        );
        
        $("li#menu-summary").addClass("pure-menu-selected");
        
        var parameterCounts = _.countBy(data.data, "Result_Parameter_Name");
        var parameterCounts = _.chain(data.data).countBy("Result_Parameter_Name")
            .pairs()
            .sortBy(0)
            .value();
        
        for (var i=0; i<parameterCounts.length; i++) {
            
            $("ul#parameters").append("<li><a href='#' data-parameterName='" 
                + parameterCounts[i][0] + "'>" 
                + parameterCounts[i][0] + "</a> <span class='count'>(" 
                + parameterCounts[i][1] + ")</span></li>"
            );
        };
        
        $("ul#parameters li a").click(function() {
            displayParameterDetails(this);
        });
    };
}

var displayParameterDetails = function(elem) {
    //alert($(elem).attr("data-parameterName"));
    
    $("div#details").empty();
    $("div#uploadedData h2").empty();
    
    var theParam = $(elem).attr("data-parameterName");
    var filteredData = _.filter(data.data, 'Result_Parameter_Name', theParam);
    
    var getVal = function(result) {
        return parseFloat(result.Result_Value);
    }
    
    var max = _.max(filteredData, getVal).Result_Value;
    var min = _.min(filteredData, getVal).Result_Value;
    
    $("div#uploadedData h2").append("Details (" + theParam + ")");
    $("div#details").append("Range is from <strong>"
        + min + "</strong> to <strong>"
        + max + "</strong>."
    );
    
    
};

var parseCSV = function(){ 
    
    $("#uploadedData").empty();
    $("#sidebar").empty();
    
    var fileInput = document.querySelector("#fileItem");
    var file = fileInput.files[0];

    Papa.parse(file, {
        
        header: true,
        
        error:  function(err, file) {
            console.log("Error:", err, file);
        },
        
        complete: function(results) {
            
            errors  = [];
            data    = results; 
            
            // Go through each row & check for errors
            findErrors(results.data);
            drawErrors(errors);
            
        }
    });
};

// Register onclick events & generally set up the document
$("#fileItem").change(parseCSV);
$("#menu-summary a").click(summarizeData);
$("#menu-errors a").click(drawErrors);

