
// Logic to import file, parse it, then append a table
//  to the html document.


var data   = [];
var errors = [];
var errorGroups = [];

var monthNames = ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

var tooltip = d3.select("body").append("div")   
    .attr("class", "tooltip")               
    .style("opacity", 0);

// Global graphing variables

var margin = {top: 20, right: 40, bottom: 60, left: 60},
    width  = 450 - margin.left - margin.right,
    height = 350 - margin.top - margin.bottom;

var x = d3.time.scale()
    .range([0, width]);

var y = d3.scale.linear()
    .range([height, 0]);

var color = d3.scale.ordinal()
  .domain(["Not Flagged", "J", "U", "Other" ])
  .range(["#018571", "#a6611a", "#dfc27d", "#80cdc1" ]);

var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")
    .ticks(4);

var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left")
    .ticks(6);
    
    
// Loop through each row in the EIM template
//  to find errors
var findErrors = function(data) {
    
    var i = 0;
    
    for (i; i<data.length; i++) {
        
        var dateOfCollection = new Date(data[i]["Field_Collection_Start_Date"]);
        
        var rowName = ["Site " + data[i]["Location_ID"],
            monthNames[dateOfCollection.getMonth()] + " " + dateOfCollection.getDay() + ", " + dateOfCollection.getFullYear(),
            data[i]["Fraction_Analyzed"] + " " + data[i]["Result_Parameter_Name"] + " in " + data[i]["Sample_Matrix"]
            ].join(" | "); 
        
        // Check for whole-row errors; returns a list [property, error] string pairs.
        //  Example: [["Sample_ID", "Missing Sample ID"],["Field_Collection_Upper_Depth", "Value out of range"]]
        var rowErrs = eimRowValidate(data[i]);
        
        if (rowErrs.length > 0) {
            
            for (var j=0; j<rowErrs.length; j++) {
                
                var tableLocation = "<ins>Row " + (i+1) + ", Column " + rowErrs[j][0] + "</ins>";
            
                errors.push({
                    "fieldError":    rowErrs[j][1],
                    "property":      rowErrs[j][0], 
                    "tableLocation": tableLocation, 
                    "rowName":       rowName
                });
            };
        };
        
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
        
        errorGroups = _.chain(errors)
            .countBy("property")
            .pairs()
            .sortBy(0)
            .value();
        
    };
}

//  Currently relies on global variables;  not great,
//    but a lot easier to debug.
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
        

        
        $("li#menu-errors").addClass("pure-menu-selected");
        
        // Loop through every identified error
        for (var i=0; i<errors.length; i++) {
            
            $("#errorList").append("<li class='error'>" 
                + errors[i]["tableLocation"] + " - "
                + errors[i]["fieldError"]    + "<p class='rowName'>" 
                + errors[i]["rowName"]       + "</p></li>"
            );
        };
        
        // Update the sidebar
        
        $("#sidebar").append("<h2>Summary</h2");
        $("#sidebar").append("<ul id='errorSummary'></ul>");
        
        $("#errorSummary").append("<li><strong>" + errors.length + "</strong> total errors.</li>");
        $("#errorSummary").append("<li><strong>" + data.data.length + "</strong> total rows.</li>");
        
        $("#sidebar").append("<h3>Error Types</h3>");
        $("#sidebar").append("<ul id='errorGroups'></ul>");
        
        for (var i=0; i<errorGroups.length; i++) {
            $("#errorGroups").append("<li>" + 
                errorGroups[i][0].replace(/_/g, " ") + "<span class='count'> (" +
                errorGroups[i][1] + ")</span></li>"
            );
        };
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
            + "<div id='summaryGraph'></div>"
            + "<div id='details'><p>Select a parameter to the left.</p></div>"
            
        );
        
        $("li#menu-summary").addClass("pure-menu-selected");
        
        var parameterCounts = _.chain(data.data).countBy("fullParameter")
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
        
        // Set up the graph
        var svg = d3.select("div#summaryGraph").append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
          .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")")
            .attr("class", "graphingArea");
            
        svg.append("g")
          .attr("class", "x axis")
          .attr("transform", "translate(0," + height + ")");

        svg.append("g")
          .attr("class", "y axis");
      
        $("ul#parameters li a").click(function() {
            displayParameterDetails(this);
        });
    };
}

var displayParameterDetails = function(elem) {
    
    $("div#details").empty();
    $("div#uploadedData h2").empty();
    
    var theParam = $(elem).attr("data-parameterName");
    var filteredData = _.filter(data.data, 'fullParameter', theParam);
    
    var getVal = function(result) {
        return parseFloat(result.Result_Value);
    }
    
    var max = _.max(filteredData, getVal).Result_Value;
    var min = _.min(filteredData, getVal).Result_Value;
    
    $("div#uploadedData h2").append("Details of " + theParam);
    $("div#details").append("<p>Range is from <strong>"
        + min + "</strong> to <strong>"
        + max + "</strong></p>."
    );
    
    // Fill in the graph
    
    var svg = d3.select("div#summaryGraph svg g.graphingArea");

    
    x.domain(d3.extent(filteredData, function(d) { return d.dateJS })).nice();
    y.domain(d3.extent(filteredData, function(d) { return d.value  })).nice();
    
    d3.select("svg g.x.axis").call(xAxis);
    d3.select("svg g.y.axis").call(yAxis);
    
    // Data join & update
    var dots = svg.selectAll(".dot")
        .data(filteredData, function(d) { return d.id; })
        .attr("r", 3.5)
        .attr("cx", function(d) { return x(d.dateJS); })
        .attr("cy", function(d) { return y(d.value); });
    
    // Enter
    dots.enter().append("circle")
        .attr("class", "dot")
        .attr("r", 3.5)
        .attr("cx", function(d) { return x(d.dateJS); })
        .attr("cy", function(d) { return y(d.value); })
        .style("fill-opacity", 1e-6)
        .style("fill", function(d) { return color(d.qualifier); })
        .on("mouseover", function(d) {
            tooltip.style("opacity", 0.8);
            tooltip.html(
                d.Location_ID + "<br /> " + 
                d.dateJS.toLocaleString() + "<br />" +
                d.value + " " + d.Result_Value_Units
            )
                .style("left", (d3.event.pageX + 10) + "px")
                .style("top", (d3.event.pageY) + "px")
        })
        .on("mouseout", function(d) {
            tooltip.style("opacity", 0);
        })
      .transition()
        .duration(500)
        .style("fill-opacity", 1);
        
    // Exit
    dots.exit()
      .transition()
        .style("fill-opacity", 1e-6)
        .remove();
    
    var legend = d3.select("div#summaryGraph svg").selectAll(".legend")
        .data(color.domain())
      .enter().append("g")
        .attr("class", "legend")
        .attr("transform", function(d, i) { 
            var left = ((width + margin.left + margin.right) / 2) * -1;
            var xLocation = left + (75 * i) + 20; 
            
            return "translate(" + xLocation + "," + (height + margin.top + 35) + ")"; 
        });
 
    legend.append("circle")
        .attr("cx", width - 18)
        .attr("cy", 10)
        .attr("r", 3.5)
        .style("fill", color);
 
    legend.append("text")
        .attr("x", width - 24)
        .attr("y", 9)
        .attr("dy", ".35em")
        .style("text-anchor", "end")
        .style("font-size", "0.8em")
        .style("fill", "gray")
        .text(function(d) { return d; });
    
};

var parseCSV = function(){ 
    
    $("#uploadedData").empty();
    $("#sidebar").empty();
    
    var fileInput = document.querySelector("#fileItem");
    var file = fileInput.files[0];
    var splitname = file.name.split(".");
    var extension = splitname[splitname.length-1].toLowerCase();
    
    if (extension != "csv") {
        alert("You must select a .csv file.  If using Excel, select 'Save As' and save the document as a CSV first.");
    } else {
    
        Papa.parse(file, {
            header: true,
            skipEmptyLines: true,
            error:  function(err, file) {
                console.log("Error:", err, file);
            },
            complete: function(results) {
                
                // eimColumns is defined in eimValidator.js
                var missingFields = _.difference(eimColumns, _.keys(results.data[0]));
                
                if (missingFields.length > 0) {
                    alert("The supplied file is not in valid EIM format; columns " + missingFields.join(", ") + " are missing.");
                } else {
                
                    errors  = [];
                    data    = results; 
                    i       = 0;
                    
                    // Customize attributes
                    data.data.forEach( function(d) {
                        d.value     = parseFloat(d.Result_Value);
                        
                        try {
                            var theDate = d.Field_Collection_Start_Date
                                .replace(/'/g, '')
                                .split("/");
                            var theTime = d.Field_Collection_Start_Time
                                .replace(/'/g, '')
                                .split(":");
                            d.dateJS    = new Date(
                                theDate[2].slice(0, 4), 
                                parseInt(theDate[0])-1, 
                                theDate[1],
                                theTime[0],
                                theTime[1],
                                theTime[2]
                            );
                        } catch(err) {
                            d.dateJS = "";
                        };
                        
                        d.fullParameter = d.Fraction_Analyzed + " " 
                            + d.Result_Parameter_Name + " in " 
                            + d.Sample_Matrix + " (" 
                            + d.Result_Value_Units + ")";
                        
                        try {
                            var flag = d.Result_Data_Qualifier.toUpperCase();
                            
                            if (flag == "J") {
                                d.qualifier = "J";
                            } else if (flag == "U") {
                                d.qualifier = "U";
                            } else if (!!flag) {
                                d.qualifier = "Other";
                            } else {
                                d.qualifier = "Not Flagged";
                            };
                            
                            /*if (!!flag) {
                                d.qualifier = "Flagged";
                            } else {
                                d.qualifier = "Not Flagged";
                            };*/
                        } catch(err) {
                            d.qualifier = "Other";
                        }
                        
                        d.id = i;
                        i++;
                    });
                    
                    // Go through each row & check for errors
                    findErrors(results.data);
                    drawErrors(errors);
                }
            }
        });
    }
};

// Register onclick events & generally set up the document
$("#fileItem").change(parseCSV);
$("#menu-summary a").click(summarizeData);
$("#menu-errors a").click(drawErrors);

