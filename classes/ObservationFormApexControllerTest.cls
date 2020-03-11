/**
 * @class:       ObservationFormApexControllerTest
 * @JIRA:        NASSC-953
 * @description: Test Class for ObservationFormComponentApexController class.
 */ 

@isTest
public class ObservationFormApexControllerTest {
	
    @isTest static void testChatCasesNonTrueandco()
    {
        Case chatCase  = new Case(Origin='Chat', Brand__c='2',Status='New', Priority='Medium',SuppliedName='testName');
        insert chatCase;
        ObservationFormComponentApexController.getCaseOrigin(chatCase.Id);
    }
    @isTest static void testPhoneCases()
    {
        Case phoneCase  = new Case(Origin='Phone', Brand__c='2',Status='New', Priority='Medium',SuppliedName='testName');
        insert phoneCase;
        ObservationFormComponentApexController.getCaseOrigin(phoneCase.Id);
    }
    @isTest static void testEmailWebCasesNonTrueandco()
    {
        Case emailWebCase  = new Case(Origin='Email', Brand__c='2',Status='New', Priority='Medium',SuppliedName='testName');
        insert emailWebCase;
        ObservationFormComponentApexController.getCaseOrigin(emailWebCase.Id);
    }
    @isTest static void testEmailWebCasesTrueandco()
    {
        Case emailWebCaseTrue  = new Case(Origin='Web', Brand__c='11',Status='New', Priority='Medium',SuppliedName='testName');
        insert emailWebCaseTrue;
        ObservationFormComponentApexController.getCaseOrigin(emailWebCaseTrue.Id);
    }
    
    // testing negative scenario
    @isTest static void testChatCasesTrueandco()
    {
        Case chatCaseTrue  = new Case(Origin='Chat', Brand__c='11',Status='New', Priority='Medium',SuppliedName='testName');
        insert chatCaseTrue;
        ObservationFormComponentApexController.getCaseOrigin(chatCaseTrue.Id);
    }
}