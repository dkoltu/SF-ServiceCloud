trigger ContactTrigger on Contact (before insert, before update,before delete,after update, after insert, after delete, after undelete) {

    if (utilityClass.triggerEnabled( 'et4ae5' )) {
        //Note the override of the trigger name for marketing cloud integrations.

        If (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
            Organization org = [Select isSandbox from Organization LIMIT 1];
            if (!org.IsSandbox) {
                List <LoyaltySettings__mdt> TSEnabledList = new List<LoyaltySettings__mdt>();
                TSEnabledList = [select BrandId__c from LoyaltySettings__mdt where EnableTriggeredSend__c = true];
                Set <String> TSEnabledBrandsSet = new Set<String>();
                if (TSEnabledList.size()>0) {
                    for (LoyaltySettings__mdt LS : TSEnabledList){
                        TSEnabledBrandsSet.add(LS.BrandId__c);
                    }

                }



                for (Contact c : trigger.new) {
                    if ((c.External_Id__c==null) && (TSEnabledBrandsSet.contains(c.Brand_Id__c)) && (c.Source_System__c == 'WiFi' || c.Source_System__c == 'ChargeItSpot') && (c.EmailOptInStatus__c == 'Y')) {
                        if (trigger.isInsert) et4ae5.triggerUtility.automate('Contact');
                        else if (trigger.isUpdate && Trigger.oldMap.get(c.Id).EmailOptInStatus__c != 'Y') et4ae5.triggerUtility.automate('Contact');

                    }
                }
            }
        }
    }

    TriggerFactory.createAndExecuteHandler(ContactTriggerHandler.class);
    
}