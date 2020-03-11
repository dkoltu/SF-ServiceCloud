public class searchReasonCodeController {

@AuraEnabled 
    public static List<Case> getCases(List<Id> Ids) {
         List<Case> caseList = new List<Case> ();
        
            for(Case cs : [select Id, Reason_Code__c, Reason_Code_Details__c,Reason_Sub_detail__c from Case WHERE Id In :Ids])
            {
               caseList.add(cs); 
            }
        system.debug('caseList==>'+caseList);
         return caseList ;    
    }
    
    @AuraEnabled
  public static List<Case> addParentAccount(String recordId , List<String> lstOfselectedIds){
      system.debug('entered');
      system.debug('lstOfselectedIds==>'+lstOfselectedIds);
    list<Case> lselected = new list<Case>();
      lselected = [select Id, Reason_Code__c, Reason_Code_Details__c,Reason_Sub_detail__c from case where Id =: recordId];
      if( lstOfselectedIds.size() != 0)
      {
      for(Case sId : lselected){
       
        sId.Reason_Code__c = '';
          sID.Reason_Code_Details__c ='';
        
        system.debug('updated');
   }
      }
   update lselected;
      return lselected;
 }
    
    @AuraEnabled
    Public static CaseWrapper getAllCases(string recordId,String objectType, String selectedField){
        List<String> pickListValuesList = new List<String>();
        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(selectedField).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     
       // return pickListValuesList;
        //String PicklistSelected = '';        
       list<Case> caseList = new list<Case>();
      caseList = [select Id, Reason_Code__c, Reason_Code_Details__c,Reason_Sub_detail__c from case where Id =: recordId ];
        
        CaseWrapper relatedCase = new CaseWrapper(Caselist, pickListValuesList); 
        return relatedCase;
    }
        
           @AuraEnabled
         public static List < Case > fetchReasonCode(String searchKeyWord) {
              String searchKey = searchKeyWord + '%';
              List < Case > returnList = new List < Case > ();
             
            //select Reason_Code__c,Reason_Code_Details__c,Reason_Sub_detail__c from ReasonCodeConfiguration__c
              List < Case > lstOfCase = [select Reason_Code__c,Reason_Code_Details__c,Reason_Sub_detail__c from case
                                               where(Reason_Code__c LIKE: searchKey 
                                                     OR Reason_Code_Details__c LIKE: searchKey 
                                                     OR Reason_Sub_detail__c LIKE: searchKey
                                                     ) LIMIT 500];
              for (Case cse: lstOfCase) {
                   returnList.add(cse);
              }
              return returnList;
         }
    
    
   public class CaseWrapper{
        @AuraEnabled
        public list<case> Caselist {get;set;}
        @AuraEnabled
        public list<String> rsCodeList {get;set;}
       // public list<String> rsCodeDetailList {get;set;}
       // public list<String> rsCodeSubList {get;set;}
       public CaseWrapper(list<case> Caselist, list<String> rsCodeList){
       // public CaseWrapper(list<case> Caselist, list<String> rsCodeList, list<String> rsCodeDetailList, list<String> rsCodeSubList){
            this.Caselist = Caselist;
            this.rsCodeList = rsCodeList;
           // this.rsCodeDetailList = rsCodeDetailList;
          //  this.rsCodeSubList = rsCodeSubList;
        }
    }
    
    
    
    
    
    @AuraEnabled
    public static Map<String,String> saveCaseList(List<Case> caseList) {
       
        Map<String,String> resultMap = new Map<String,String>();
       
        try {
               
            update caseList;
            
            resultMap.put('status', 'success');
                resultMap.put('message', 'Case Updated Successfully');        
        }
        catch(Exception e) {
            
            resultMap.put('status', 'error');
                        resultMap.put('message',e.getMessage());
        }
       
        return resultMap;
    }
}