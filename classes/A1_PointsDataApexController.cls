/******************************************************************************
* @Description: Show Points Data to Case and Contact Page
* @Author	  : Rounak P
* @Date		  : 01:01.2020
* @JIRA		  : NASSC-1146,1148,1183
*
******************************************************************************/ 

public without sharing class A1_PointsDataApexController {

    /*
    @AuraEnabled
    public static boolean checkPendingPointsStatus(Id recordId){
        System.debug('ID = '+recordId);
        Case getCase = [Select Id,PendingPointsAdjustment__c from Case where Id=:recordId ];
        //System.debug('Pending Point Status = '+getCase.PendingPointsAdjustment__c);
        return getCase.PendingPointsAdjustment__c;
    }
   	*/
    
   
    @AuraEnabled
    public static BooleanWrapper checkPendingPointsStatus(Id recordId){
        BooleanWrapper wrapperObjBoolean = new BooleanWrapper();
        wrapperObjBoolean.isEnableRewardsButton = false;
        //System.debug('ID = '+recordId);
        Case getCase = [Select Id,Contact.Brand_Id__c,PendingPointsAdjustment__c from Case where Id=:recordId ];
        //System.debug('Pending Point Status = '+getCase.PendingPointsAdjustment__c);
        //System.debug('&&&'+getCase.Contact.Brand_Id__c);
        List<LoyaltySettings__mdt> loyaltyData = [Select Id, EnableRewardsButton__c from LoyaltySettings__mdt WHERE
                                                 BrandId__c=:getCase.Contact.Brand_Id__c];
        
        wrapperObjBoolean.isPendingPointAdjustment = getCase.PendingPointsAdjustment__c;
        if(loyaltyData.size()>0) wrapperObjBoolean.isEnableRewardsButton = loyaltyData[0].EnableRewardsButton__c;
        System.debug('***Pending Point = '+wrapperObjBoolean.isPendingPointAdjustment);
        System.debug('***Reward Button = '+wrapperObjBoolean.isEnableRewardsButton);
        return wrapperObjBoolean;
    }
    
    
    @AuraEnabled
    public static List<AgileOne.TransactionRec> getPoints(Id recordIds) {
    	Map<String,String> LoyaltyMap = new Map<String,String>();
        List<AgileOne.TransactionRec> listTransaction = new  List<AgileOne.TransactionRec>(); 
        Contact conRecord;
        Case caseRecord;
        
        Schema.SObjectType token = recordIds.getSObjectType();
        Schema.DescribeSObjectResult dr = token.getDescribe();
		System.debug('Name = '+dr.getName());
        
        if(dr.getName().equals('Contact')){
            conRecord = [Select LoyaltyID__c,Brand_Id__c from Contact WHERE Id=:recordIds];
           
        }
        else if(dr.getName().equals('Case')){
            caseRecord = [Select Contact.LoyaltyID__c,Contact.Brand_Id__c from Case WHERE Id=:recordIds];
           
        }       
        
        if(conRecord!=null && conRecord.LoyaltyID__c !=null && conRecord.Brand_Id__c!=null && !Test.isRunningTest()){
             System.debug('Loyalty Id = '+conRecord.LoyaltyID__c);
			 listTransaction = AgileOne.getC360Data(conRecord.LoyaltyID__c,  conRecord.Brand_Id__c);
               
        }
        else if(caseRecord!=null && caseRecord.Contact.LoyaltyID__c !=null && caseRecord.Contact.Brand_Id__c!=null && !Test.isRunningTest() ){
             System.debug('Loyalty Id = '+caseRecord.Contact.LoyaltyID__c);
             listTransaction = AgileOne.getC360Data(caseRecord.Contact.LoyaltyID__c,caseRecord.Contact.Brand_Id__c);
               
        }
       
       System.debug('***Transaction List = '+listTransaction); 
       return  listTransaction;
    }
    
    
    	
    	public class BooleanWrapper {
        @AuraEnabled
        public boolean isPendingPointAdjustment { get; set; }
        @AuraEnabled
        public boolean isEnableRewardsButton { get; set; }

    }
   
}