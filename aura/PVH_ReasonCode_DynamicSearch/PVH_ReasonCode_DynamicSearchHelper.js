({
    SearchHelper: function(component, event) {
        var action = component.get("c.fetchReasonCode");
        action.setParams({
            'searchKeyWord': component.get("v.searchKeyword")
        });
        action.setCallback(this, function(response) {
          
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                 alert('Success searchHelper');
                
                if (storeResponse.length == 0) {
                    component.set("v.Message", true);
                } else {
                    component.set("v.Message", false);
                }
                
                
                component.set("v.TotalNumberOfRecord", storeResponse.length);
                
                
                component.set("v.searchResult", storeResponse); 
                
            }else if (state === "INCOMPLETE") {
                alert('Response is Incompleted');
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        alert("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    alert("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
   updateHelper : function(component, event , childRecordsIds) {
       debugger ;
      // var cse = event.getSource().get("v.caseList")
       // console.log('cse-- > ' + JSON.stringify(cse));        
        var action1 = component.get("c.addParentAccount");
        
        action1.setParams({"recordId":component.get("v.recordId"),
                           // "objectType":'Case',
                            "pickListSelected":'Reason_Code__c',
                           "lstOfselectedIds" :'childRecordsIds'
                          });
       
        action1.setCallback(this, function(response){
             alert('Success');
            var state = response.getState();
            if(state === "SUCCESS"){
                var res=response.getReturnValue();
                console.log('res.'+JSON.stringify(res)); 
                component.set('v.picklistValues',res.closeActionValues);
                component.set('v.pickListSelected',res.rsCodeList);
                
                var toastEvent = $A.get("e.force:showToast");
          			toastEvent.setParams({
        				"title": "Success!",
        				"message": "The Child record's has been added successfully."
    				});
                    toastEvent.fire();
              
                // refresh/reload the page view
                $A.get('e.force:refreshView').fire();
                
                // call init function again [clear selected checkboxes]
                this.getCaseList(component,event);
            }
            else if (state === "ERROR") {
                var errors = resp.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } 
                else {
                    console.log(resp.getReturnValue());
                }
            }
        });
        $A.enqueueAction(action1);
    },
    
    getCaseList : function(component, event, helper) { 
      
        console.log('Calling searchReasonCOdeController Controller');
        var action = component.get("c.getCases");
        var recId = component.get("v.recordId");
        console.log('recId==>'+recId);
       
        action.setParams({
            ids: recId
        });
        action.setCallback(this, function(response) {
             var state = response.getState();
               if(state === 'SUCCESS') {
                var caseList = response.getReturnValue();
                   console.log('caseList==>'+response.getReturnValue());
                
                  component.set("v.caseList",caseList);
           }
            else {
                
                alert('Error in getting data');
            }
             $A.enqueueAction(action);
        });
        
       
        }
})