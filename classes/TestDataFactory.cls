/**
* @class:       TestDataFactory
* @JIRA:        NA
* @description: Common Factory Class to create Test Data 
*/ 

@isTest
public class TestDataFactory {
    
    //Creating Accounts
    Public Static List<Account> createAccount(Integer count){
        List<Account> accList = new List<Account>();
        for(Integer i=0;i<count;i++){
            Account acc = new Account(Name = 'Test Account'+i);
            accList.add(acc);
        }
        return accList;
    }
    
    //Creating Contacts
    Public Static List<Contact> createContact(Integer count){
        List<Contact> conList = new List<Contact>();
        for(Integer i=0;i<count;i++){
            Contact con = new Contact(LastName = 'ContactLname'+i);
            conList.add(con);
        }
        return conList;
    }
    
    //Creating Cases
    Public Static List<Case> createCases(Integer numCases) {
        List<Case> listCases = new List<Case>();
        
        for(Integer i=0;i<numCases;i++) 
        {
            Case caseRecord = new Case(Priority='Medium',Origin='Web');
            listCases.add(caseRecord);
        }
        return listCases;
    }
    
    //Creating Cases
    Public Static List<Reward__c> createRewards(Integer num) {
        List<Reward__c> listRewards = new List<Reward__c>();
        
        for(Integer i=0;i<num;i++) 
        {
           Reward__c rewObj = new Reward__c(
           LoyaltyId__c = 'C0021733313',
           RewardType__c = '58',
           Status__c = 'Active'
           
         );
          listRewards.add(rewObj); 
        }
       return listRewards;
    }
    
    
}