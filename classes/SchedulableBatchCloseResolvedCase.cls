/**
* @author Magnet360
*
* @date 2019
*
* @description NASSC-98
*
*/
global class SchedulableBatchCloseResolvedCase implements Schedulable{ 
    global void execute(SchedulableContext ctx){
        BatchCloseResolvedCase closeCase = new BatchCloseResolvedCase();
        Database.executeBatch(closeCase);
    }
}