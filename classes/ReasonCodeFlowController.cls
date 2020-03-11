/**
 * Created by dimitrisavelieff on 2020-01-22.
 */

public with sharing class ReasonCodeFlowController {
    @AuraEnabled(cacheable=true)
    public static Case getSingleCase(String caseId){
        system.debug('Looking for case '+caseID);
        return [SELECT Id, Status, Reason_Code__c, Reason_Code_Details__c, Reason_Sub_detail__c, RecordTypeId FROM Case where Id = :caseId];
    }
}