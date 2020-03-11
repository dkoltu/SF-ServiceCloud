({
    doInit : function(component, event, helper) { 
        // get the fields API name and pass it to helper function  
        var controllingFieldAPI = component.get("v.controllingFieldAPI");
        var dependingFieldAPI = component.get("v.dependingFieldAPI");
        var subDependingFieldAPI = component.get("v.subDependingFieldAPI");
        //var productCategoryFieldAPI = component.get("v.productCategoryFieldAPI");
        
        var objDetails = component.get("v.objDetail");
        // call the helper function
        helper.fetchPicklistValues(component,objDetails,controllingFieldAPI, dependingFieldAPI, "v.depnedentFieldMap");
        
        // 2nd and 3rd picklist 
        helper.fetchPicklistValues(component,objDetails,dependingFieldAPI, subDependingFieldAPI, "v.subDepnedentFieldMap");
        //4th picklist
       // helper.fetchPicklistValues(component,objDetails,dependingFieldAPI, productCategoryFieldAPI, "v.productCategoryFieldMap");
      

    },
    
    handleClick: function (cmp, event, helper) {
        var radioGrpValue = cmp.get("v.value");
        // var grandParentField =cmp.find(auraIdField).get("v.label");
        cmp.set("v.grandParentValue" , radioGrpValue);
        //var controllerValueKey = event.getSource().get("v.value"); // get selected controller field value
        var controllerValueKey=cmp.get("v.grandParentValue");
        var depnedentFieldMap = cmp.get("v.depnedentFieldMap");
        if (controllerValueKey != '--- None ---') {
            // disable and reset sub dependent field 
           // cmp.set("v.isparent" ,true);
           var ListOfDependentFields = depnedentFieldMap[controllerValueKey];
           
            if(ListOfDependentFields.length > 0){
                cmp.set("v.bDisabledDependentFld" , false);  
                //cmp.set("isbutton",true);
                helper.fetchDepValues(cmp, ListOfDependentFields,"v.listDependingValues");    
            }else{
                cmp.set("v.bDisabledDependentFld" , true); 
                cmp.set("v.listDependingValues", ['--- None ---']);
            }  
            
        } else {
            cmp.set("v.listDependingValues", ['--- None ---']);
            cmp.set("v.bDisabledDependentFld" , true);
        }
        
            cmp.set("v.bDisabledSubDependentFld" , true);
            cmp.set("v.listSubDependingValues", ['']);
            cmp.set("v.isclicked", true);
         
          if(event.getSource().get("v.label")!="Service"){
                    cmp.set("v.isRequired",false);
                    cmp.set("v.isRequired1",false);
                }
        if(event.getSource().get("v.label")!="Product"){
             cmp.set("v.isRequiredManufacturer",false);
             cmp.set("v.isRequiredProduct",false);
        }
         if(event.getSource().get("v.label")!="Loyalty"){
              cmp.set("v.isAccInfoReason",false);
             
        }
    },
    
    

  
    
    onSubControllerFieldChange : function(component, event, helper) {     
         var controllerValueKey = event.getSource().get("v.value"); // get selected sub controller field value
         var depnedentFieldMap = component.get("v.subDepnedentFieldMap");
        
         
         component.set("v.ischild" ,true);
        
        if (controllerValueKey != '--- None ---') {
           
           component.set("v.ischild" ,true);
           
            
            var ListOfDependentFields = depnedentFieldMap[controllerValueKey];
            if(ListOfDependentFields.length > 0){
                 
               // component.set("v.ischild" ,true);
                component.set("v.bDisabledSubDependentFld" , false);  
                helper.fetchDepValues(component, ListOfDependentFields,"v.listSubDependingValues");
                
            }else{
                component.set("v.bDisabledSubDependentFld" , true); 
                component.set("v.listSubDependingValues", ['']);
            }  
            
         
            
          } else {
            component.set("v.listSubDependingValues", ['']);
           // component.set("v.listproductCategoryValues", ['']);
            component.set("v.bDisabledSubDependentFld" , true);
          }
        
           /*if(parentField!='' || ListOfDependentFields.length > 0){
             component.set("isbutton",true);
           }*/
       
              if((controllerValueKey == "Care Instructions") || 
                (controllerValueKey == "Counterfeit Merchandise") ||
                (controllerValueKey == "Defective Merchandise") ||
                (controllerValueKey == "Product Inquiry") ||
                (controllerValueKey == "Product Repair") ||
                (controllerValueKey == "Sizing Feedback") ||
                (controllerValueKey == "Sizing Question")
               ) {
               
                component.set("v.isRequiredProduct",true);
                helper.fetchPickListVal(component, 'Reason_Code_Product_Category__c', 'productCategory');
                }
            
           
           if(controllerValueKey == "Defective Merchandise"){
               
                component.set("v.isRequiredManufacturer",true);
                helper.fetchPickListVal(component, 'Reason_Code_Manufacturers__c', 'manufacturer');
            }            
            if(controllerValueKey == "Good Service") {
                component.set("v.isRequired",true);
            }
            else if(controllerValueKey == "Poor Service"){
                 component.set("v.isRequired1",true);
            }
            else if(controllerValueKey == "Other" ){
                component.set("v.isRequired",false);
                component.set("v.isRequired1",false);
            }
           if(controllerValueKey == "Edit Account Information"){
                  component.set("v.isAccInfoReason",true);
              }
            else{
               component.set("v.isAccInfoReason",false);
            }
        
        
               
                     
        
          
        
        
        
           /* else {
                    component.set("v.isRequired",false);
                    component.set("v.isRequired1",false);
                    component.set("v.storeNumber", "");
                    component.set("v.districtNumber", "");
                    component.set("v.dateofServiceIssue", "");

                }*/
           
        },
    
    /*fetchPickListVal: function(component,event ,helper) {
       alert('in init helper..');
      var pickvar = component.get("c.getselectOptions");
      /* action.setParams({
           "objObject": component.get("v.objDetail"),
           "fld": fieldName
       });*/
      // var opts = [];
       /* pickvar.setCallback(this, function(response)  {
           alert('in init helper before sucess..');
            var state = response.getState();
           if (state == "SUCCESS") {
               var allValues = response.getReturnValue();
                component.set("v.option", allValues);
           }
       });
       $A.enqueueAction(action);
   },*/
    
    onSubDependentFieldChange: function (cmp, event,helper) {
         var controllerValueKey = event.getSource().get("v.value");
            if(controllerValueKey == "Update Account Info Reason"){
                    cmp.set("v.isAccInfoReason",true);
        }
        else
        {
            cmp.set("v.isAccInfoReason",false);
        }
        
    },
    
    onProCatChange: function (cmp, event,helper) {
         var proCatValue = event.getSource().get("v.value");
         cmp.set("v.productCategoryValue",proCatValue);
    },
    
    onManufacturerChange: function (cmp, event,helper) {
        var manufacturerValue = event.getSource().get("v.value");
         cmp.set("v.manufacturerValue",manufacturerValue);
        
    },
    
     handleSubmit: function (cmp, event,helper) {
        
       var id = cmp.get("v.recordId") ;
        var myText = cmp.get("v.myText");
       //  var dateofServiceIssue=cmp.get("v.dateofServiceIssue");
       //  var storeNumber = cmp.get("v.storeNumber");
         //var districtNumber = cmp.get("v.districtNumber");
        // var updateAccountInfoReason = cmp.get("v.updateAccountInfoReason");
         var parentField = cmp.find("parentField").get("v.value");
         var childField = cmp.find("childField").get("v.value");
         var grandParentField=cmp.get("v.grandParentValue");
      
       if((parentField === 'Good Service') || (parentField === 'Poor Service')){
          var regExpNumberformat=/^[0-9]+$/;
            if(!$A.util.isEmpty(cmp.find("storeNumber").get("v.value"))){
                    //if(storeNumberValue.match(regExpNumberformat)){
                    /* stNumeber=cmp.find("storeNumber").get("v.value");
                   if(stNumeber.length !=0){
                       alert(stNumeber);*/
                   // cmp.set("v.storeNumberatt",cmp.find("storeNumber").get("v.value"));
                   //}
                   cmp.find("storeNumber").set("v.errors", [{message: null}]);
                   $A.util.removeClass(cmp.find("storeNumber"),'slds-has-error');
                 
                    
                }else{
                    $A.util.addClass(cmp.find("storeNumber"), 'slds-has-error');
                    cmp.find("storeNumber").set("v.errors", [{message: "Please Enter Store Number"}]);
                     
               }
               if(!$A.util.isEmpty(cmp.find("districtNumber").get("v.value"))){
                   // var dtNumeber=cmp.find("districtNumber").get("v.value");
                  // cmp.set("v.districtNumberatt",dtNumeber);
                   cmp.find("districtNumber").set("v.errors", [{message: null}]);
                   $A.util.removeClass(cmp.find("districtNumber"),'slds-has-error');
                    
                }else{
                     $A.util.addClass(cmp.find("districtNumber"), 'slds-has-error');
                    cmp.find("districtNumber").set("v.errors", [{message: "Please Enter District Number"}]);
                     
               }
          var action4 = cmp.get("c.updateCase");
          action4.setParams({"recordId":cmp.get("v.recordId"),
                            "dateofServiceIssue":cmp.get("v.dateofServiceIssueatt"),
                            "storeNumber":cmp.find("storeNumber").get("v.value"),
                            "districtNumber":cmp.find("districtNumber").get("v.value"),
                             "manufacturer":cmp.get("v.manufactureratt"),
                             "productCategory":cmp.get("v.productCategoryatt"),
                            "updateAccountInfoReason":cmp.get("v.updateAccountInfoReasonatt"),
                            "parentField":cmp.find("parentField").get("v.value"),
                            "childField":cmp.find("childField").get("v.value"),
                            "grandParent":cmp.get("v.grandParentValue")
                             }); 
           
        } 
         if(parentField === 'Poor Service'){
           var today = new Date();
              if(!$A.util.isEmpty(cmp.find("dateofServiceIssue").get("v.value"))){
                  
                       cmp.find("dateofServiceIssue").set("v.errors", [{message: null}]);
                       $A.util.removeClass(cmp.find("dateofServiceIssue"),'slds-has-error');
                  
                  
              }else{
                     $A.util.addClass(cmp.find("dateofServiceIssue"), 'slds-has-error');
                     cmp.find("dateofServiceIssue").set("v.errors", [{message: "Please Select Date Of Service Issue"}]);
              }
           var action4 = cmp.get("c.updateCase");
          action4.setParams({"recordId":cmp.get("v.recordId"),
                            "dateofServiceIssue":cmp.find("dateofServiceIssue").get("v.value"),
                            "storeNumber":cmp.find("storeNumber").get("v.value"),
                            "districtNumber":cmp.find("districtNumber").get("v.value"),
                            "updateAccountInfoReason":cmp.get("v.updateAccountInfoReasonatt"),
                            "manufacturer":cmp.get("v.manufactureratt"),
                            "productCategory":cmp.get("v.productCategoryatt"),
                            "parentField":cmp.find("parentField").get("v.value"),
                            "childField":cmp.find("childField").get("v.value"),
                            "grandParent":cmp.get("v.grandParentValue")
                             }); 
           
            }
         
         
         if(parentField === 'Defective Merchandise'){
             if(!$A.util.isEmpty(cmp.find("manufacturer").get("v.value"))){
                   cmp.find("manufacturer").set("v.errors", [{message: null}]);
                   $A.util.removeClass(cmp.find("manufacturer"),'slds-has-error');
                 
                    
                }else{
                    $A.util.addClass(cmp.find("manufacturer"), 'slds-has-error');
                    cmp.find("manufacturer").set("v.errors", [{message: "Please Enter Manufacturer"}]);
                     
               }
             if(!$A.util.isEmpty(cmp.find("productCategory").get("v.value"))){
                       cmp.find("productCategory").set("v.errors", [{message: null}]);
                       $A.util.removeClass(cmp.find("productCategory"),'slds-has-error');
              }else{
                    $A.util.addClass(cmp.find("productCategory"), 'slds-has-error');
                    cmp.find("productCategory").set("v.errors", [{message: "Please Enter Product Category"}]);
              }
             var action4 = cmp.get("c.updateCase");
             action4.setParams({"recordId":cmp.get("v.recordId"),
                            "dateofServiceIssue":cmp.get("v.dateofServiceIssueatt"),
                            "storeNumber":cmp.get("v.storeNumberatt"),
                            "districtNumber":cmp.get("v.districtNumberatt"),
                            "updateAccountInfoReason":cmp.get("v.updateAccountInfoReasonatt"),
                            "manufacturer":cmp.get("v.manufacturerValue"),
                            "productCategory":cmp.get("v.productCategoryValue"),
                            "parentField":cmp.find("parentField").get("v.value"),
                            "childField":cmp.find("childField").get("v.value"),
                            "grandParent":cmp.get("v.grandParentValue")
                             });
             
             
         }
           if((parentField === 'Care Instructions') || 
                (parentField === 'Counterfeit Merchandise') ||
                (parentField === 'Product Inquiry') ||
                (parentField === 'Product Repair') ||
                (parentField === 'Sizing Feedback') ||
                (parentField === 'Sizing Question')
             ){      
                  if(!$A.util.isEmpty(cmp.find("productCategory").get("v.value"))){
                       cmp.find("productCategory").set("v.errors", [{message: null}]);
                       $A.util.removeClass(cmp.find("productCategory"),'slds-has-error');
                  }else{
                    $A.util.addClass(cmp.find("productCategory"), 'slds-has-error');
                    cmp.find("productCategory").set("v.errors", [{message: "Please Enter Product Category"}]);
                }
               
           
          var action4 = cmp.get("c.updateCase");
          action4.setParams({"recordId":cmp.get("v.recordId"),
                            "dateofServiceIssue":cmp.get("v.dateofServiceIssueatt"),
                            "storeNumber":cmp.get("v.storeNumberatt"),
                            "districtNumber":cmp.get("v.districtNumberatt"),
                            "updateAccountInfoReason":cmp.get("v.updateAccountInfoReasonatt"),
                            "manufacturer":cmp.get("v.manufactureratt"),
                            "productCategory":cmp.get("v.productCategoryValue"),
                            "parentField":cmp.find("parentField").get("v.value"),
                            "childField":cmp.find("childField").get("v.value"),
                            "grandParent":cmp.get("v.grandParentValue")
                             });   
             } 
         if(parentField === 'Edit Account Information'){
           
              if(!$A.util.isEmpty(cmp.find("updateAccInfoReason").get("v.value"))){
                  
                       cmp.find("updateAccInfoReason").set("v.errors", [{message: null}]);
                       $A.util.removeClass(cmp.find("updateAccInfoReason"),'slds-has-error');
                     
                  
              }else{
                     $A.util.addClass(cmp.find("updateAccInfoReason"), 'slds-has-error');
                     cmp.find("updateAccInfoReason").set("v.errors", [{message: "Please Enter Update Account Info Reason"}]);
              }
             
           var action4 = cmp.get("c.updateCase");
           action4.setParams({"recordId":cmp.get("v.recordId"),
                            "dateofServiceIssue":cmp.get("v.dateofServiceIssueatt"),
                            "manufacturer":cmp.get("v.manufactureratt"),
                            "productCategory":cmp.get("v.productCategoryatt"),
                            "storeNumber":cmp.get("v.storeNumberatt"),
                            "districtNumber":cmp.get("v.districtNumberatt"),
                            "updateAccountInfoReason":cmp.find("updateAccInfoReason").get("v.value"),
                            "parentField":cmp.find("parentField").get("v.value"),
                            "childField":cmp.find("childField").get("v.value"),
                            "grandParent":cmp.get("v.grandParentValue")
                             }); 
               }
         
          
       if((parentField != 'Good Service') && 
          (parentField != 'Poor Service') && 
          (parentField != 'Defective Merchandise') &&
          (parentField != 'Care Instructions') && 
          (parentField != 'Counterfeit Merchandise') &&
          (parentField != 'Product Inquiry') &&
          (parentField != 'Product Repair') &&
          (parentField != 'Sizing Feedback') &&
          (parentField != 'Sizing Question') &&
          (parentField != 'Edit Account Information')
          
         ){
          var action4 = cmp.get("c.updateCase");
          action4.setParams({"recordId":cmp.get("v.recordId"),
                            "dateofServiceIssue":cmp.get("v.dateofServiceIssueatt"),
                            "manufacturer":cmp.get("v.manufactureratt"),
                            "productCategory":cmp.get("v.productCategoryatt"),
                            "storeNumber":cmp.get("v.storeNumberatt"),
                            "districtNumber":cmp.get("v.districtNumberatt"),
                            "updateAccountInfoReason":cmp.get("v.updateAccountInfoReasonatt"),
                            "parentField":cmp.find("parentField").get("v.value"),
                            "childField":cmp.find("childField").get("v.value"),
                            "grandParent":cmp.get("v.grandParentValue")
                             });
       }
               
        action4.setCallback(this, function(response){
         	var status = response.getState();
          
              if(status === "SUCCESS"){
                   
                 // $A.get('e.force:refreshView').fire();
              var workspaceAPI = cmp.find("workspace");
               workspaceAPI.getFocusedTabInfo().then(function(response) {
                            var focusedTabId = response.tabId;
                            workspaceAPI.refreshTab({
                                tabId: focusedTabId,
                                includeAllSubtabs: false,
                                "isEdit":true
                                
                    
                });
            })
            .catch(function(error) {
                console.log(error);
            });
            // cmp.set("v.isSuccess",true);     
                  
                  
                //  cmp.set(cmp.find("parentField").get("v.value"), response.getReturnValue());
                //  cmp.set(cmp.find("childField").get("v.value"), response.getReturnValue());
                   
                  
                 // $A.get('e.force:refreshView').fire();
                  /*var editRecordEvent = $A.get("e.force:editRecord");
                   editRecordEvent.setParams({
                        "v.isEdit": true,
                        "recordId": cmp.get("v.recordId")
                  });*
                  editRecordEvent.fire();
                  $A.get('e.force:refreshView').fire();*/
                  
                 }
             else if(status === "ERROR"){
                //cmp.set(cmp.find("storeNumber").get("v.value"), response.getReturnValue());
             }
            
         });
        $A.enqueueAction(action4);
       
     }, 

    
      handleClearErrors: function(cmp, event, helper) {
      
    },
     isRefreshed: function(cmp, event, helper) {
         cmp.set("v.isEdit",true); 
       
     }, 
        
    isCancel: function(cmp, event, helper) {
          cmp.set("v.isEdit",true); 
          //cmp.set("isCancel",true);
     }, 
    
    handleEdited: function(component, event, helper) {
        component.set("v.isEdit",false);
    },
    recordLoaded: function(cmp, event, helper) {
        
        //
      var eventParams = event.getParams();
        if(eventParams.changeType === "CHANGED") {
            //cmp.find('recordLoader').reloadRecord(true);
           /* $A.get('e.force:refreshView').fire();
            var workspaceAPI = cmp.find("workspace");
            alert('testing workspace');
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.refreshTab({
                    tabId: focusedTabId,
                    includeAllSubtabs: true,
                    
                });
            })
            .catch(function(error) {
                console.log(error);
            });*/
            
            
        } else if(eventParams.changeType === "LOADED") {
            // record is loaded in the cache
        } else if(eventParams.changeType === "REMOVED") {
            //record is deleted.
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        } 
    },
          
})