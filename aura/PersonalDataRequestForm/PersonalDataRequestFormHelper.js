({
    
    fetchPicklistValues: function(component,objDetails,controllerField, dependentField) {
        // call the server side function  
        var action = component.get("c.getDependentMap");
      
        var brandNames = component.get("v.brandNames");
        var caseSourceCountry = component.get("v.caseSourceCountry");
        
        // pass paramerters [object definition , contrller field name ,dependent field name] -
        // to server side function 
        action.setParams({
            'objDetail' : objDetails,
            'contrfieldApiName': controllerField,
            'depfieldApiName': dependentField,
            'brandNames' : brandNames,
            'sourceCountry' : caseSourceCountry,
           
            
        });
        //set callback   
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var getResults = response.getReturnValue();
                console.log('***We got Response = '+getResults);
                //store the return response from server (map<string,List<string>>)  
                var StoreResponse = getResults.mapCountryState;
                console.log('***We got Map = '+StoreResponse);
                // setting the Type
                component.set("v.typeOfRequestList", getResults.listTypeOfRequest);
                component.set("v.brandLabel", getResults.brand_label);
                component.set("v.brandEmail", getResults.brand_email);
                component.set("v.brandPhone", getResults.brand_phone);
                component.set("v.brandPrivacyPolicy", getResults.brand_privacyPolicy);
                component.set("v.brandOptOutInfo", getResults.brand_optOutInfo);
                console.log('Label = '+getResults.brand_label);
                console.log('Email = '+getResults.brand_email);
                console.log('Phone = '+getResults.brand_phone);
                console.log('Privacy Policy = '+getResults.brand_privacyPolicy);
                console.log('Info Opt Out = '+getResults.brand_optOutInfo);

                // once set #StoreResponse to depnedentFieldMap attribute 
                component.set("v.depnedentFieldMap",StoreResponse);
                
                // create a empty array for store map keys(@@--->which is controller picklist values) 
                var listOfkeys = []; // for store all map keys (controller picklist values)
                var ControllerField = []; // for store controller picklist value to set on lightning:select. 
                
                // play a for loop on Return map 
                // and fill the all map key on listOfkeys variable.
                for (var singlekey in StoreResponse) {
                    listOfkeys.push(singlekey);
                }
                
                //set the controller field value for lightning:select
                if (listOfkeys != undefined && listOfkeys.length > 0) {
                    // ControllerField.push('--- None ---');
                }
                
                for (var i = 0; i < listOfkeys.length; i++) {
                    ControllerField.push(listOfkeys[i]);
                }  
                // set the ControllerField variable values to country(controller picklist field)
                component.set("v.listControllingValues", ControllerField);
            }else{
                alert('Something went wrong..');
            }
        });
        $A.enqueueAction(action);
    },
    
    fetchDepValues: function(component, ListOfDependentFields) {
        // create a empty array var for store dependent picklist values for controller field  
        var dependentFields = [];
        //dependentFields.push('--- None ---');
        for (var i = 0; i < ListOfDependentFields.length; i++) {
            dependentFields.push(ListOfDependentFields[i]);
        }
        // set the dependentFields variable values to store(dependent picklist field) on lightning:select
        component.set("v.listDependingValues", dependentFields);
        
    },
    
    handleCreateCase : function(component, event, helper) {
        console.log('***inside save helper');
        var newCase = component.get("v.newCase");
        var fName = component.find("firstname").get("v.value");
        var lName = component.find("lastname").get("v.value");
        var brandNames = component.get("v.brandNames");
        var caseSourceCountry = component.get("v.caseSourceCountry");
        console.log('***Name of Customer = '+fName+' '+lName);
        var saveAction = component.get("c.createCase");
        
        saveAction.setParams({ 
            "getCaseDetail": newCase,
            "name" : fName+' '+lName,
            "brandNames" : brandNames,
            "sourceCountry" : caseSourceCountry
           
        });
        saveAction.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                
                //$A.get('e.force:refreshView').fire(); 
                var result = a.getReturnValue();
                console.log('***Case Created with Id = '+result);
                
                component.set("v.ticketid",result.caseNumber);
                component.set("v.successMessage",result.message_success);
                component.set("v.regards",result.regards_success);
                component.set("v.brandLabel",result.brand_label);
                component.set("v.brandEmail",result.brand_email);
                
                component.set("v.isFinished", true);
                console.log('***get Case Id = '+component.get("v.ticketid"));
                
                
            }
            
            else if (state === "INCOMPLETE") {
                console.log('***INCOMPLETE');
            }
            else if (state === "ERROR") {
                var errors = a.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                        this.showToast(component, event,helper, "error","Error: ","Something Went Wrong.");
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(saveAction)
        
    },
    
    showToast : function(component, event, helper,displayType,displayTitle,errorMessage) {
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type" : displayType,
            "title": displayTitle,
            "message": errorMessage
        });
        toastEvent.fire();
    },	
    
    
})