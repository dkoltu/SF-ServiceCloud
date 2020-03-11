({
  doInit: function(component, event, helper) {
    console.log("***inside doInit");
    var brandNames = component.get("v.brandNames");
    var appEvent = $A.get("e.c:appBrandNameEvent");
    appEvent.setParam("brandName", brandNames);
    appEvent.fire();

    // get the fields API name and pass it to helper function
    var controllingFieldAPI = component.get("v.controllingFieldAPI");
    var dependingFieldAPI = component.get("v.dependingFieldAPI");
    var objDetails = component.get("v.objDetail");
    // call the helper function
    helper.fetchPicklistValues(
      component,
      objDetails,
      controllingFieldAPI,
      dependingFieldAPI
    );
  },

  onControllerFieldChange: function(component, event, helper) {
    var getCountry = component.find("country").get("v.value");

    if (getCountry == "United States of America (USA)") {
      component.set("v.isStateVisible", true);
    } else {
      component.set("v.isStateVisible", false);
      component.set("v.newCase.State_of_Residence__c", null);
    }

    var controllerValueKey = event.getSource().get("v.value"); // get selected controller field value
    var depnedentFieldMap = component.get("v.depnedentFieldMap");

    if (controllerValueKey != "--- None ---") {
      var ListOfDependentFields = depnedentFieldMap[controllerValueKey];

      if (ListOfDependentFields.length > 0) {
        component.set("v.bDisabledDependentFld", false);
        helper.fetchDepValues(component, ListOfDependentFields);
      } else {
        component.set("v.bDisabledDependentFld", true);
        component.set("v.listDependingValues", ["--- None ---"]);
      }
    } else {
      component.set("v.listDependingValues", ["--- None ---"]);
      component.set("v.bDisabledDependentFld", true);
    }
  },

  // this function automatic call by aura:waiting event
  showSpinner: function(component, event, helper) {
    // make Spinner attribute true for display loading spinner
    component.set("v.Spinner", true);
  },

  // this function automatic call by aura:doneWaiting event
  hideSpinner: function(component, event, helper) {
    // make Spinner attribute to false for hide loading spinner
    component.set("v.Spinner", false);
  },

  handleSendMessage: function(component, event, helper) {
    console.log("***Submit Clicked");
    component.find("firstname").setCustomValidity("");
    component.find("firstname").reportValidity();

    component.find("lastname").setCustomValidity("");
    component.find("lastname").reportValidity();

    component.find("email").setCustomValidity("");
    component.find("email").reportValidity();

    component.find("phone").setCustomValidity("");
    component.find("phone").reportValidity();

    component.find("loyaltyID").setCustomValidity("");
    component.find("loyaltyID").reportValidity();

    var typeOfRequest = component.find("typeOfRequest").get("v.value");
    var country = component.find("country").get("v.value");

    if (component.get("v.isStateVisible"))
      var state = component.find("state").get("v.value");

    var firstname = component.find("firstname").get("v.value");
    var lastname = component.find("lastname").get("v.value");
    var getEmail = component.find("email");
    var inputEmail = getEmail.get("v.value");
    var inputPhone = component.find("phone").get("v.value");
    var inputLoyaltyID = component.find("loyaltyID").get("v.value");
    console.log("***typeOfRequest = " + typeOfRequest);
    console.log("***country = " + country);

    if (component.get("v.isStateVisible")) console.log("***state = " + state);

    console.log("***firstname = " + firstname);
    console.log("***lastname = " + lastname);
    console.log("***email = " + inputEmail);
    console.log("***phone = " + inputPhone);
    console.log("***loyalty id = " + inputLoyaltyID);
    var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    //var regExpPhoneformat = /^[0][1-9]\d{9}$|^[1-9]\d{9}$/g
    //var regExpPhoneformat = /^\+(?:[0-9] ?){6,14}[0-9]$/;
    var regExpPhoneformat = /^\+?(?:[0-9\-] ?){6,14}[0-9]$/;
    //var regExpPhoneformatTwo = /1?[\s-]?\(?(\d{3})\)?[\s-]?\d{3}[\s-]?\d{4}/;
    //var regExpPhoneformatThree = /(([+]?[(]?[0-9]{1,3}[)]?)|([(]?[0-9]{4}[)]?))\s*[)]?[-\s\.]?[(]?[0-9]{1,3}[)]?([-\s\.]?[0-9]{3})([-\s\.]?[0-9]{3,4})/;
    // var regExpName = /^[a-zA-Z ]{2,}$/
    var regExpName = new RegExp("^[a-zA-Z]+([-' ][a-zA-Z]+)*$");
    var regExpLoyalty = new RegExp("^[a-zA-Z0-9]*$");

    if (
      !typeOfRequest ||
      !country ||
      !inputEmail ||
      !firstname ||
      !lastname ||
      (component.get("v.isStateVisible") && !state)
    ) {
      var controlAuraIds = ["firstname", "lastname", "email"];
      let isAllValid = controlAuraIds.reduce(function(
        isValidSoFar,
        controlAuraId
      ) {
        var inputCmp = component.find(controlAuraId);
        inputCmp.reportValidity();
        return isValidSoFar && inputCmp.checkValidity();
      },
      true);

      if (component.get("v.isStateVisible") && !state)
        component.find("state").showHelpMessageIfInvalid("");

      if (!country) component.find("country").showHelpMessageIfInvalid("");

      if (!typeOfRequest)
        component.find("typeOfRequest").showHelpMessageIfInvalid("");

      helper.showToast(
        component,
        event,
        helper,
        "error",
        "Error: ",
        "Please provide all of the required information below"
      );
    } else if (inputEmail && !inputEmail.match(regExpEmailformat)) {
      /*
        if(!typeOfRequest && !country && !inputEmail && !firstname &&!lastname)
        {
            
            helper.showToast(component, event, helper,"error", "Error: ","Please Select Type of Request \n Please Select Country \n Please Provide First Name \n Please Provide Last Name \n Please Provide Email");
        }
        
        else if(!country && !firstname && !lastname && !inputEmail)
        {
            
            helper.showToast(component, event, helper,"error", "Error: ","Please Select Country of Residence \n Please Provide First Name \n Please Provide Last Name \n Please Provide Email");
        }
        
        else if(!country && !inputEmail)
        {
            
            helper.showToast(component, event, helper,"error", "Error: ","Please Select Country of Residence \n Please Provide Email");
        }

        
        else if(!typeOfRequest)
        {
            helper.showToast(component, event, helper,"error", "Error: ","Please Select Type of Request");
        }
        else if(!country)
        {
            helper.showToast(component, event, helper,"error", "Error: ","Please Select Country of Residence");
        }
        
        else if(country==='United States of America (USA)' && !state)
        {
            helper.showToast(component, event, helper,"error", "Error: ","Please Select State of Residence");
        }
        
        
        else if((!firstname || !lastname) && !inputEmail)
        {
            helper.showToast(component, event, helper,"error", "Error: ","Please Provide Both: First Name and Last Name \n Please Provide Email");
        }
        
        else if((!firstname || !lastname))
        {
            helper.showToast(component, event, helper,"error", "Error: ","Please Provide Both: First Name and Last Name");
        }
        
        else if(!inputEmail)
        {
                helper.showToast(component, event, helper,"error", "Error: ","Please Provide Email");
        }
        */
      //component.find("email").setCustomValidity("You have entered invalid email");
      //component.find("email").reportValidity();
      helper.showToast(
        component,
        event,
        helper,
        "error",
        "Error: ",
        "Please Provide Valid Email"
      );
    } else if (inputPhone && !inputPhone.match(regExpPhoneformat)) {
      //component.find("phone").setCustomValidity("You have entered invalid phone number");
      //component.find("phone").reportValidity();
      helper.showToast(
        component,
        event,
        helper,
        "error",
        "Error: ",
        "Please Provide Valid Phone Number"
      );
    } else if (inputLoyaltyID && !inputLoyaltyID.match(regExpLoyalty)) {
      component
        .find("loyaltyID")
        .setCustomValidity("You have entered an invalid Loyalty ID");
      component.find("loyaltyID").reportValidity();
      helper.showToast(
        component,
        event,
        helper,
        "error",
        "Error: ",
        "Please Only Enter Letters and Numbers for Loyalty ID"
      );
    } else if (
      firstname &&
      firstname.trim().length < 2 &&
      lastname &&
      lastname.trim().length < 2
    ) {
      component
        .find("firstname")
        .setCustomValidity("First Name must be minimum 2 characters");
      component.find("firstname").reportValidity();

      component
        .find("lastname")
        .setCustomValidity("Last Name must be minimum 2 characters");
      component.find("lastname").reportValidity();
      helper.showToast(
        component,
        event,
        helper,
        "error",
        "Error: ",
        "First Name and Last Name should be minimum 2 characters"
      );
    } else if (firstname && firstname.trim().length < 2) {
      component
        .find("firstname")
        .setCustomValidity("First Name must be minimum 2 characters");
      component.find("firstname").reportValidity();
      helper.showToast(
        component,
        event,
        helper,
        "error",
        "Error: ",
        "First Name must be minimum 2 characters"
      );
    } else if (lastname && lastname.trim().length < 2) {
      component
        .find("lastname")
        .setCustomValidity("Last Name must be minimum 2 characters");
      component.find("lastname").reportValidity();
      helper.showToast(
        component,
        event,
        helper,
        "error",
        "Error: ",
        "Last Name must be minimum 2 characters"
      );
    } else if (
      firstname &&
      !firstname.match(regExpName) &&
      lastname &&
      !lastname.match(regExpName)
    ) {
      component
        .find("firstname")
        .setCustomValidity("Please Provide Valid First Name");
      component.find("firstname").reportValidity();

      component
        .find("lastname")
        .setCustomValidity("Please Provide Valid Last Name");
      component.find("lastname").reportValidity();
      helper.showToast(
        component,
        event,
        helper,
        "error",
        "Error: ",
        "Please Provide Valid First Name and Last Name"
      );
    } else if (firstname && !firstname.match(regExpName)) {
      component
        .find("firstname")
        .setCustomValidity("Please Provide Valid First Name");
      component.find("firstname").reportValidity();
      helper.showToast(
        component,
        event,
        helper,
        "error",
        "Error: ",
        "Please Provide Valid First Name"
      );
    } else if (lastname && !lastname.match(regExpName)) {
      component
        .find("lastname")
        .setCustomValidity("Please Provide Valid Last Name");
      component.find("lastname").reportValidity();
      helper.showToast(
        component,
        event,
        helper,
        "error",
        "Error: ",
        "Please Provide Valid Last Name"
      );
    } else {
      helper.handleCreateCase(component, event, helper);
    }
  }
});