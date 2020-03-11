/*  Class: Batch_PurgeTrackerEvents
*  Description : Batch class to Delete  Tracker Events	Records with CreatedDate > (Today - 21)
*/

global class Batch_PurgeTrackerEvents implements  Database.Batchable <sObject>{
 
    String QueryString = Null;
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        QueryString = 'SELECT Id, CreatedDate FROM TrackerEvents__c ';
        System.debug('QueryString: '+ QueryString);
        return Database.getQueryLocator(QueryString);
    }
    
    global void execute(Database.BatchableContext bc, List<TrackerEvents__c> records){
         List<TrackerEvents__c> TrackerEventsList = new List<TrackerEvents__c>();
        
        for(TrackerEvents__c TE: records){
            date createddate = date.valueOf(TE.CreatedDate);
            date today = date.valueOf(system.now());
            integer datediff = CreatedDate.daysBetween(Today);
                   
                    if(datediff > 21){
                    System.debug('>>>Records Add in TrackerEventsList');
                    TrackerEventsList.add(TE);
                }
            } 
            
        
        System.debug('TrackerEventsList size: '+ TrackerEventsList.size());
        
        if(TrackerEventsList.size()>0){
            List<Database.DeleteResult> results = Database.Delete(TrackerEventsList, false);
            for (Database.DeleteResult result : results) {
                if (!result.isSuccess()){
                    for (Database.Error err : result.getErrors()){
                        System.debug('Error: '+ err.getStatusCode() + ' ' + err.getMessage());
                    }
                }
            }
        } 
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}