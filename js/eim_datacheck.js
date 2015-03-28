
// Logic to import file, parse it, then append a table
//  to the html document.


var data   = [];

var monthNames = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

var drawErrors = function() {
    
    // Clear out the main data panel and add new containers
    $("#sidebar").empty();
    $("#uploadedData").empty();
    $("li#menu-summary").removeClass("pure-menu-selected");
    
    $("#uploadedData").append("<div id='errorSummary'></div>");
    $("#uploadedData").append("<ul id='errorList'></ul>");
    $("li#menu-errors").addClass("pure-menu-selected");
    
    // Loop through each row in the EIM template
    var i = 0;
    var errors = [];
    
    for (i; i<data.data.length; i++) {
        
        var dateOfCollection = new Date(data.data[i]["Field_Collection_Start_Date"]);
        
        var rowName = ["Site " + data.data[i]["Location_ID"],
            monthNames[dateOfCollection.getMonth()] + " " + dateOfCollection.getDay() + ", " + dateOfCollection.getFullYear(),
            data.data[i]["Fraction_Analyzed"] + " " + data.data[i]["Result_Parameter_Name"] + " in " + data.data[i]["Sample_Matrix"]
            ].join(" | "); 
        
        // Loop through each column in the row
        for (var property in data.data[i]) {
            if (data.data[i].hasOwnProperty(property)) {
            
                // Check a field in a row for errors (see eimValidator.js)
                var fieldError = eimValidValue(property, data.data[i][property]);
                
                if (fieldError.length > 0) {
                    errors.push(fieldError);
                    var tableLocation = "<ins>Row " + i + ", Column " + property + "</ins>";
                    $("#errorList").append("<li class='error'>" + tableLocation + " - " + fieldError 
                        + "<p class='rowName'>" + rowName + "</p></li>");
                };
            };
        };
    };
    
    // Update the menu and status div
    
    $("#errorSummary").append("<p>There were <strong>" + errors.length + "</strong> errors in <strong>"
        + data.data.length + "</strong> rows. </p>");
};

var parseCSV = function(){ 
    var fileInput = document.querySelector("#fileItem");
    var file = fileInput.files[0];

    Papa.parse(file, {
        
        header: true,
        
        error:  function(err, file) {
            console.log("Error:", err, file);
        },
        
        complete: function(results) {
        
            data = results; 
            
            // Go through each row & check for errors
            drawErrors();
            
        }
    });
};

var summarizeData = function() {
    
    // State changes - empty out divs & change menu
    $("#uploadedData").empty();
    $("#sidebar").empty();
    $("li#menu-errors").removeClass("pure-menu-selected");
    
    $("#sidebar").append("<h2>Parameters</h2");
    $("#sidebar").append("<ul id='parameters'></ul>");
    $("li#menu-summary").addClass("pure-menu-selected");
    
    var parameterCounts = _.countBy(data.data, function(n) { return n.Result_Parameter_Name });
    
    for (var parameter in parameterCounts) {
        if (parameterCounts.hasOwnProperty(parameter)) {
            $("ul#parameters").append("<li>" + parameter + " <span class='count'>(" + parameterCounts[parameter] + ")</span></li>");
        };
    };
    
}

$("#fileItem").change(parseCSV);
$("#menu-summary a").click(summarizeData);
$("#menu-errors a").click(drawErrors);

