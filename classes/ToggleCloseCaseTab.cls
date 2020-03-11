/**
* @author Magnet360
*
* @date 2019
*
* @description Lightning utility class called when an agent closes a tab Service Console.
* If the agent closes the case prematurel, the case is routed back to the agents personal queue
*
*/
public with sharing class ToggleCloseCaseTab {
    /*******************************************************************************************************
    * @description Called when the tab is closed. Returns true if the status of the case tab closed is open
    * @param caseId - the Id of the case being closed
    * @return Boolean - true if the case status is Open
    */
    @AuraEnabled
    public static Boolean getDisableStatus(String caseId){
        Case c = [SELECT Id, Status FROM Case WHERE Id = :caseId];
        if(c.Status == 'Open') {
            return true;
        } else {
            return false;
        }
    }
    /*******************************************************************************************************
    * @description Returns the case into the agents personal queue. Called from the lightning component
    * toggleCloseCaseTab when the case tab is closed while the status is still open
    * @param caseId the ID of the Case record
    * @return string of case information
    */
    @AuraEnabled
    public static String doCaseRouting(String caseId){
        List<Case> cases = [SELECT Id, CaseNumber, Origin, Status, Personal_Queue_Id__c, Originating_Queue_Id__c, OwnerId FROM Case WHERE Id = :caseId];
        if(cases.size() > 0){
            Case c = cases[0];
            if(c.Status == 'Open' && c.OwnerId == UserInfo.getUserId()) {
                if (c.Personal_Queue_Id__c != null) {
                    c.OwnerId = c.Personal_Queue_Id__c;
                } else if (c.Originating_Queue_Id__c != null && c.Origin != 'Chat'){
                    c.OwnerId = c.Originating_Queue_Id__c;
                }
            }
            update c;
            return 'Case Owner Id: ' + c.OwnerId + ' - Case Id: ' + c.Id + ' - Case Number: ' + c.CaseNumber + ' - Case Status: ' + c.Status;
        } else {
            return null;
        }
    }
}