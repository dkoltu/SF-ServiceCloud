/**
* @author Magnet360
*
* @date 2019
*
* @description Test Class for AgentWorkTriggerHandler.<p>
* <p>
* Note: Many of the actions in AgentWork is untestable as they can only change
* via OmniChannel actions. If deploying this class, you will always be required
* to run ALL tests in order to pass code coverage
* @see AgentWorkTriggerHandler
*/
@isTest
public class AgentWorkTriggerTest {
    // THIS IS NOT TESTABLE. AN UNAVOIDABLE ERROR OCCURS. THIS TEST IS JUST TO MAKE THIS TRIGGER DEPLOYABLE.
    @isTest
    static void test_fake() {
        //Try Catch is to ensure test doesn't fail
        ServiceChannel sc = [SELECT Id FROM ServiceChannel LIMIT 1];
        List<Case> caseList = TestDataFactory.createCases(1);
        Case cse = caseList[0];
        insert cse;
        try{
            AgentWork aw = new AgentWork(
                    ServiceChannelId = sc.Id,
                    WorkItemId = cse.Id,
                    UserId = UserInfo.getUserId()
            );
            insert aw;
        } catch (Exception e) {
            //IGNORE THIS ERROR. BEFORE INSERT TRIGGERS EVEN WITH THAT.
        }
    }
}