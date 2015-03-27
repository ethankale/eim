
// Logic to import file, parse it, then append a table
//  to the html document.


    var data     = [];
    var headings = [];

    var parseCSV = function(){ 
        var fileInput = document.querySelector("#fileItem");
        var file = fileInput.files[0];
        
        
        $("#status").text("Importing and reviewing file " + file.name + "...");

        Papa.parse(file, {
            config: {
                     header: false,
                     worker: true
                     },
            before: function(file) {
                        console.log("Parsing file...", file);
            },
            error: function(err, file) {
                        console.log("Error:", err, file);
            },
            complete: function(results) {
                        
                        data = results;
                        console.log("Row count:" + results.data.length); 
                        
                        // Create header row w/ labels, and a list of labels
                        
                        $("#uploadedData").append('<table id="dataTable" class="pure-table-horizontal">')
                        $("#dataTable").append('<tr id="header">')
                        $("#header").append('<th>Errors</th>')
                        
                        for (var i=0; i<data.data[0].length; i++) {
                            $("#header").append("<th>" + data.data[0][i] + "</th>");
                            headings.push(data.data[0][i]);
                        }
                        
                        // Go through each row, add DOM element & check for errors
                        
                        for (var i=1; i<data.data.length; i++) {
                            $("#dataTable").append('<tr id="row' + i + '">');
                            $("#row" + i).append('<td class="errorCount">');
                            
                            var rowErrors = []
                            
                            for (var j=0; j<data.data[i].length; j++) {
                                field = headings[j]
                                $("#row" + i).append('<td class="' + field + '">' + data.data[i][j] + "</td>");
                                
                                // Find all errors for the field (cell) we're on, add to row errors
                                
                                var fieldError = eimValidValue(field, data.data[i][j])
                                
                                if (fieldError.length > 0) {
                                    rowErrors.push([field, fieldError]);
                                    console.log(fieldError);
                                    $("#row" + i + " ." + field).addClass("error");
                                    $("#row" + i + " .errorCount").addClass("error");
                                    
                                    $("#row" + i + " ." + field).prop("title", fieldError);
                                }
                            }
                            
                            $("#row" + i + " .errorCount").text(rowErrors.length)
                            
                            if (rowErrors.length > 0) {
                                $("#row" + i).addClass("error");
                            }
                            
                        }
                        
                        $("#status").text("Import complete!");
            }

        });
    }
    
    // set the input element onchange to call pullfiles
    document.querySelector("#fileItem").onchange = parseCSV;

