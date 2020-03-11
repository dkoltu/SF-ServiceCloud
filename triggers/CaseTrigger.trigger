trigger CaseTrigger on Case (before insert, before update,before delete,after update, after insert, after delete, after undelete) {
	/*if(Trigger.isBefore && Trigger.isInsert) {
		for(Case cas:Trigger.New){
			System.debug('updating origin');
			System.debug(cas.Origin);
			System.debug(cas.Brand__c);

			if(cas.Origin.startsWithIgnoreCase('Email -') && cas.Brand__c == null){
				cas.Brand__c = cas.Origin.removeStartIgnoreCase('Email -').trim();
				cas.Origin = 'Email';
				System.debug(cas.Origin);
				System.debug(cas.Brand__c);
			}
		}
	}*/
  if(Trigger.isBefore ) {
        if(Trigger.isUpdate || Trigger.isInsert){
            for(Case cse:Trigger.New){
                if(cse.Reason_Code_Details__c=='Good Service'){ 
                      If(cse.ZdPVHStoreNumber__c ==Null || cse.ZdPVHDistrictNumber__c==Null )
                       {
                           cse.addError('Please enter a valid Store Number,District Number');
                        
                    }
                }
                else if(cse.Reason_Code_Details__c=='Poor Service'){
                    If(cse.ZdPVHStoreNumber__c ==Null || cse.ZdPVHDistrictNumber__c==Null || cse.ZdPVHDateofServiceIssue__c==Null)
                       {
                           cse.addError('Please enter a valid Store Number,District Number and Date of service Issue');
                        
                    }
                }
                else if(cse.Reason_Code_Details__c == 'Defective Merchandise'){
                     If((cse.Reason_Code_Manufacturers__c == null  || cse.Reason_Code_Manufacturers__c =='--None--' || cse.Reason_Code_Manufacturers__c == '')||
                        ( cse.Reason_Code_Product_Category__c == null || cse.Reason_Code_Product_Category__c == '--None--' || cse.Reason_Code_Product_Category__c ==''))
                       {
                           cse.addError('Please enter a valid Manufacturer , Product Category');
                        
                    }
                }
                 else if((cse.Reason_Code_Details__c == 'Care Instructions' )||
                       (cse.Reason_Code_Details__c == 'Counterfeit Merchandise') ||
                        (cse.Reason_Code_Details__c == 'Product Inquiry') ||
                        (cse.Reason_Code_Details__c == 'Product Repair') ||
                        (cse.Reason_Code_Details__c == 'Sizing Feedback') ||
                        (cse.Reason_Code_Details__c == 'Sizing Question')
                        
                        ){
                        If(cse.Reason_Code_Product_Category__c == null || cse.Reason_Code_Product_Category__c =='--None--' || cse.Reason_Code_Product_Category__c=='')
                        {
                           cse.addError('Please enter a valid  Product Category');
                        
                    }
                      
                }
                else if(cse.Reason_Code_Details__c =='Edit Account Information'){
                    If(cse.ZdPVHUpdateAccountInfoReason__c ==Null)
                        {
                           cse.addError('Please enter Account Info Reason');
                        
                    }
                }
                else{
                    cse.ZdPVHStoreNumber__c =NULL;
                    cse.ZdPVHDistrictNumber__c=NULL;
                    cse.ZdPVHDateofServiceIssue__c=Null;
                    cse.Reason_Code_Manufacturers__c =NULL;
                    cse.Reason_Code_Product_Category__c=NULL;
                    cse.ZdPVHUpdateAccountInfoReason__c=NULL;
                }
            }
        } 
        
    }
    
    TriggerFactory.createAndExecuteHandler(CaseTriggerHandler.class);
	if (utilityClass.triggerEnabled( String.valueOf(this).substring(0,String.valueOf(this).indexOf(':')))) {
		if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)) {
			System.debug('===isAfter PrivacyCaseTriggerHandler.isFirstRun' + PrivacyCaseTriggerHandler.isFirstRun);
			if(PrivacyCaseTriggerHandler.isFirstRun){
				PrivacyCaseTriggerHandler.isFirstRun = False;
				PrivacyCaseTriggerHandler.sendEmailsIfNecessary();
			}
		}
	}
}