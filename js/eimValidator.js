//
// Returns a list
//  of error numbers & descriptions.  If the list is empty,
//  no errors.

// a: Value missing
// b: Value too long

function eimValidValue(field, value) {
    var err = ""
    
    if (field == "Study_ID") {
    
        if (value.length < 1) {
            err = "Missing Study ID";
        }
        
        if (value.length > 20) {
            err = "Study ID greater than 20 characters";
        }
        
    } else if (field == "Location_ID") {
    
        if (value.length < 1) {
            err = "Missing Location ID";
        }
        
        if (value.length > 15) {
            err = "Location ID greater than 15 characters";
        }
        
    } else if (field == "Study_Specific_Location_ID") {
    
        if (value.length < 1) {
            err = "Missing Study-Specific Location ID";
        }
        
        if (value.length > 40) {
            err = "Location ID greater than 40 characters";
        }
        
    } else if (field == "Field_Collection_Type") {
    
        if (value.length < 1) {
            err = "Missing Field Collection Type";
        }
        
        if (["sample", "measurement", "observation"].indexOf(value.toLowerCase()) == -1 ) {
            err = "Value of Field Collection Type not in list (sample, measurement, or observation)";
        }
        
    } else if (field == "Field_Collector") {
    
        if (value.length < 1) {
            err = "Missing Field Collector";
        }
        
        if (value.length > 15) {
            err = "Field Collector greater than 15 characters";
        }
    }
    
    return(err)

}