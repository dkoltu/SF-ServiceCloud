/**
* @author Magnet360
*
* @date 2019
*
* @description Test class for DeleteOrphanedFilesBatchSchedulable
*
* @see DeleteOrphanedFilesBatchSchedulable
*
*/
@isTest
public class DeleteOrphanedFilesBatchSchTest {
    @isTest static void executeTest(){
        SchedulableContext sc = null;
        DeleteOrphanedFilesBatchSchedulable tsc = new DeleteOrphanedFilesBatchSchedulable();
        tsc.execute(sc);
    }
}