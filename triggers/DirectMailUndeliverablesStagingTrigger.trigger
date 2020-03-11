trigger DirectMailUndeliverablesStagingTrigger on DirectMailUndeliverablesStaging__c (after insert) {
	List<String> LoyaltyIdList = new List<String>();
    List<Contact> updatedContactList = new List<Contact>();
    for(DirectMailUndeliverablesStaging__c dmus :trigger.new){
        LoyaltyIdList.add(dmus.LoyaltyId__c);
    }
    
    System.debug('***LoyaltyIdList:'+LoyaltyIdList);
    List<Contact> contactList = [SELECT Id, LoyaltyID__c, DirectMailUndeliverable__c 
                                 FROM Contact
                                 WHERE LoyaltyID__c IN : LoyaltyIdList AND DirectMailUndeliverable__c = false];
    
    System.debug('***contactList:'+contactList);
    if(contactList.size()>0){
        for(Contact con : contactList){
            con.DirectMailUndeliverable__c = true;
            updatedContactList.add(con);
        }
    }
    
    System.debug('***updatedContactList:'+updatedContactList);
    if(updatedContactList.size() >0) {
       Database.SaveResult[] srList = Database.update(updatedContactList, false);
       ContactUtility.createErrorLogRecords(srList,'MerkleUndeliverables',trigger.new[0].FileName__c);
    }    
}