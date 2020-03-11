/**
 * Created by dimitrisavelieff on 2019-09-30.
 */
/**
* @author Magnet360
*
* @date 2019
*
* @description Trigger Handler for AgentWork. This trigger compeltes workflow actions related to OmniChannlel
*  AgentWorkTrigger is run when an agent accepts or declines a case, and when the Tab is closed in Service Console
*
*/
public class AgentWorkTriggerHandler implements ITrigger{
    Private static List<Case> casesToUpdate = new List<Case>(); /**List of cases that will be updated*/
    Private static List<LiveChatTranscript> chatsToUpdate = new List<LiveChatTranscript>();
    /*******************************************************************************************************
    * @description This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger. <p>
    * <p>
    * No actions defined
    * @return void
    */
    public void  bulkBefore(){


    }



    /*******************************************************************************************************
    * @description This method is called prior to execution of an AFTER trigger. Use this to cache
    * any data required into maps prior execution of the trigger. Following Actions take place:<p>
    * <p>
    * AgentWork are split into two groups. Open Agent Work, and Closed Agent work. Open AgentWork is
    * sent to method updateOriginalQueue, Closed AgentWork is sent to method rollupActiveTime
    * @return void
    */
    public void bulkAfter(){
        if(trigger.isUpdate) {
            System.debug('UPDATING RECORDS');
            List<AgentWork> openedWork = new List<AgentWork>();
            List<AgentWork> closedWork = new List<AgentWork>();
            for(SObject so :Trigger.new) {
                AgentWork aw = (AgentWork)so;
                if(aw.Status == 'Opened') {
                    openedWork.add((AgentWork)aw);
                } else if (aw.Status  == 'Closed') {
                    closedWork.add((AgentWork)aw);
                }
            }
            if(!openedWork.isEmpty()) {
                updateOriginalQueue(openedWork);
            }
            if(!closedWork.isEmpty()) {
                rollupActiveTime(closedWork);
            }


        }
    }

    /*******************************************************************************************************
    * @description This method is called iteratively for each record to be inserted during a BEFORE
    * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
    * @return void
    */
    public void  beforeInsert(SObject obj){

    }

    /*******************************************************************************************************
    * @description This method is called iteratively for each record to be updated during a BEFORE
    * trigger.<p>
    * <p>
    *  No actions are currently defined
    * @return void
    */
    public void  beforeUpdate(SObject oldSo, SObject so){


    }

    /*******************************************************************************************************
    * @description This method is called iteratively for each record to be deleted during a BEFORE
    * trigger. <p>
    * <p>
    *  No actions are currently defined
    * @return void
    */

    public void  beforeDelete(SObject so){

    }

    /*******************************************************************************************************
    * @description This method is called iteratively for each record inserted during an AFTER
    * trigger. Always put field validation in the 'After' methods in case another trigger
    * has modified any values. The record is 'read only' by this point.
    *<p>
    * no actions are currently defined
    * @return void
    */
    public void  afterInsert(SObject so){

    }

    /*******************************************************************************************************
    * @description This method is called iteratively for each record deleted during an AFTER
    * trigger.
    *<p>
    * no actions are currently defined
    * @return void
    */
    public void  afterUpdate(SObject oldSo, SObject so){

    }
    /*******************************************************************************************************
    * @description This method is called iteratively for each record deleted during an AFTER
    * trigger.
    *<p>
    * no actions are currently defined
    * @return void
    */
    public void  afterDelete(SObject so){

    }

    /*******************************************************************************************************
    * @description This method is called once all records have been processed by the trigger. Use this
    * method to accomplish any final operations such as creation or updates of other records.
    *<p>
    * DML updates on Case and Chat is defined here
    * @return void
    */
    public void andFinally(){
        try{
            if(!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
            if(!chatsToUpdate.isEmpty()){
                update chatsToUpdate;
            }

        } catch(DmlException e) {
            //Failed to Update records
        }
    }

    /*******************************************************************************************************
    * @description WHen an agent closes an AgentWork, the total Active Time is rolled up on the case
    * @param newWorks list of AgentWorks that are closed
    * @return Boolean on success
    */
    private static Boolean rollupActiveTime(List<AgentWork> newWorks) {
        Map<String,Map<Id, AgentWork>> acceptedWorks = getAcceptedWorks(newWorks, 'Closed');
        casesToUpdate = [Select Id, Total_Active_Time__c from Case where Id in :acceptedWorks.get('Case').keySet()];
        for(Case cse :casesToUpdate) {
            AgentWork aw = acceptedWorks.get('Case').get(cse.Id);
            cse.Total_Active_Time__c = (cse.Total_Active_Time__c == null?aw.ActiveTime:cse.Total_Active_Time__c+aw.ActiveTime);
        }
        return true;
    }

    /*******************************************************************************************************
    * @description WHen an AgentWork is opened, the Queue which the case originated is saved on the Case.
    * Also, if the case is in New status, the case is moved to Open.
    * @param newWorks list of AgentWorks Opened
    * @return boolean - true on success
    */
    private static Boolean updateOriginalQueue(List<AgentWork> newWorks) {
        List<AgentWork> workWithQueueNames = [Select Id, OriginalGroupId, OriginalGroup.Name, WorkItemId, Status from AgentWork where Id in :newWorks];
        System.debug(workWithQueueNames);
        Map<String,Map<Id, AgentWork>> acceptedWorks = getAcceptedWorks(workWithQueueNames, 'Opened');
        system.debug(acceptedWorks);
        casesToUpdate = [Select Id, Originating_Queue_Id__c, Originating_Queue__c, Status, Type from Case where Id in :acceptedWorks.get('Case').keySet()];
        chatsToUpdate = [Select Id from LiveChatTranscript where Id in :acceptedWorks.get('Chat').keySet() AND Originating_Queue_Id__c = null];
        for(Case cse :casesToUpdate) {
            AgentWork aw = acceptedWorks.get('Case').get(cse.Id);
            if(String.isBlank(cse.Originating_Queue_Id__c)) {
                cse.Originating_Queue_Id__c = aw.OriginalGroupId;
                cse.Originating_Queue__c = aw.OriginalGroup.Name;
            }
            //if opening a cse, set status to Open
            if (cse.Type != Constants.privacyCaseType && cse.Status == 'New') {
                cse.Status = 'Open';
            }
        }
        for(LiveChatTranscript chat :chatsToUpdate) {
            AgentWork aw = acceptedWorks.get('Case').get(chat.Id);
            chat.Originating_Queue_Id__c = aw.OriginalGroupId;
            chat.Originating_Queue__c = aw.OriginalGroup.Name;
        }
        return true;
    }

    /*******************************************************************************************************
    * @description Method will organise Agent Works by Work Item Parent Tyoe (either Case or Chat), and set them
    * in a map organized by the parentId
    * @param newWorks list of AgentWorks needing to be organized
    * @param Status the status of the agent works that are to be returned
    * @return Map<String,Map<Id,AgentWork>> Maps of Agent works grouped by ParentId, grouped by Parent Type
    */
    private static Map<String,Map<Id,AgentWork>> getAcceptedWorks(List<AgentWork> newWorks, String Status) {
        Map<String,Map<Id,AgentWork>> acceptedWorks = new Map<String,Map<Id,AgentWork>>{'Case' => new Map<Id,AgentWork>(), 'Chat' => new Map<Id,AgentWork>()};
        for(AgentWork aw :newWorks) {
            if(aw.Status != ((AgentWork)trigger.oldMap.get(aw.Id)).Status && aw.Status == Status) {
                String workItemId = aw.WorkItemId;
                if(workItemId.startsWith('500')) {
                    Map<Id,AgentWork> caseWorks = acceptedWorks.get('Case');
                    caseWorks.put(aw.WorkItemId, aw);
                    acceptedWorks.put('Case', caseWorks);
                } else if (workItemId.startsWith('570')) {
                    Map<Id,AgentWork> caseWorks = acceptedWorks.get('Chat');
                    caseWorks.put(aw.WorkItemId, aw);
                    acceptedWorks.put('Case', caseWorks);
                }
            }
        }
        return acceptedWorks;
    }
}