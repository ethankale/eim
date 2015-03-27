
// Logic to import file, parse it, then append a table
//  to the html document.


var data   = [];
var errors = [];

var monthNames = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

var parseCSV = function(){ 
    var fileInput = document.querySelector("#fileItem");
    var file = fileInput.files[0];
    
    
    $("#status").text("Importing and reviewing file " + file.name + "...");

    Papa.parse(file, {
        
        header: true,
        
        error:  function(err, file) {
            console.log("Error:", err, file);
        },
        
        complete: function(results) {
                    
            data = results;
            console.log("Row count:" + results.data.length); 
            
            
            // Go through each row & check for errors
            
            $("#uploadedData").append("<ul id='errorList'></ul>");
            
            for (var i=0; i<data.data.length; i++) {
                
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
                            var tableLocation = "Row " + i + ", Column " + property;
                            $("#errorList").append("<li class='error' title='" + rowName + "'>" 
                                + tableLocation + " - " + fieldError + "</li>");
                        };
                    };
                };
            };
            
            $("#status").text("Import complete!");
        }
    });
};

// set the input element onchange to call pullfiles
document.querySelector("#fileItem").onchange = parseCSV;

