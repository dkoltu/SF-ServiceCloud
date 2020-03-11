({
      doInit: function(component, event, helper) {
        // call the helper function on component load
        console.log('Doinit==>');
        helper.getCaseList(component, event);
    }, 
    
    
    
  Search: function(component, event, helper) {
        var searchField = component.find('searchField');
        var isValueMissing = searchField.get('v.validity').valueMissing;
       
        if(isValueMissing) {
            searchField.showHelpMessageIfInvalid();
            searchField.focus();
            
        }else{
          
           helper.SearchHelper(component, event);
        }
      
       
          
                
    },
    Onclick: function(component, event, helper) {
        var tempIDs = [];
        var getAllId = component.find("checkBox");
        alert('getAllId==>'+getAllId);
        for (var i = 0; i < getAllId.length; i++) {
            
       if (getAllId[i].get("v.value") == true) {
                tempIDs.push(getAllId[i].get("v.text"));
           alert('tempIDs==>'+tempIDs);
            }
        }
        
     //  helper.updateHelper(component, event);
 
    },
    
    addSelected: function(component, event, helper) {
      //  debugger ;
        // create array[list] type temp. variable for store child record's id's from selected checkboxes.  
        var tempIDs = [];
 
        // get(find) all checkboxes with aura:id "checkBox"
        var getAllId = component.find("checkBox");
        alert('getAllId==>'+getAllId);
 
        // play a for loop and check every checkbox values 
        // if value is checked(true) then add those Id (store in Text attribute on checkbox) in tempIDs var.
        for (var i = 0; i < getAllId.length; i++) {
            
       if (getAllId[i].get("v.value") == true) {
                tempIDs.push(getAllId[i].get("v.text"));
           alert('tempIDs==>'+tempIDs);
            }
        }
 
        // call the helper function and pass all selected record id's.   
        helper.updateHelper(component, event, tempIDs);
    }
   
})