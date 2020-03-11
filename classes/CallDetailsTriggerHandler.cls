/**
* @author Magnet360
*
* @date 2019
*
* @description Trigger Handler for CallDetails__c. After a call has been placed, RingCentral updates the Case with fields
* populated from the call. A process builder is than run to copy those values from case to a new CallDetail.
* Once the call detail has been created, the details are wiped from case to accept values from anothercase
*
*/
public class CallDetailsTriggerHandler {
    
    public static boolean RUN_ONCE = true;

    /*******************************************************************************************************
    * @description Wipes call details from the case after the call detail was created
    * @param newCallDetails - Trigger.New values from the CallDetails trigger
    * @return void
    */
    public static void clearCallDetailsOnCase(List<CallDetail__c> newCallDetails){
        System.debug('CallDetailsTriggerHandler->entered clearCallDetailsOnCase method');
        List<Id> caseIds = new List<Id>();
        for(CallDetail__c callDetail:newCallDetails){
            caseIds.add(callDetail.case__c);//capture parent case id's
        }
        System.debug('Parent case ids found '+caseIds);
        List<Case> parentCases =   [select id,CallDirection__c,CallDurationInSeconds__c,CallEndTime__c,CallStartTime__c,Comments__c,
      									SkillName__c, NumberDialed__c,Channel__c  from Case where id in :  caseIds];
        
        for(Case parentCase:parentCases){ //clear call details
            parentCase.CallDirection__c = null;
            parentCase.CallDurationInSeconds__c = null;
            parentCase.CallEndTime__c = null;
            parentCase.CallStartTime__c = null;
            parentCase.Comments__c = null;
            parentCase.SkillName__c = null;
            parentCase.NumberDialed__c = null;
        }
        //update parent cases after call details cleared
        update parentCases;
    }

}