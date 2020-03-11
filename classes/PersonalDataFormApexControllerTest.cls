/**
 * @author Magnet360
 *
 * @date 2019
 *
 * @description Test Class for PersonalDataFormApexController class. NASSC-98
 *
 * @see PersonalDataFormApexController
 */
@isTest
public class PersonalDataFormApexControllerTest 
{
	@isTest 
    static void getDependentMapTest() 
    {	
            String brandNames = '2';
        	String sourceCountry = 'US';
            Case caseObj = new Case();
        	PersonalDataFormApexController.getDependentMap(caseObj,'Country_of_Residence__c','State_of_Residence__c',brandNames,sourceCountry);
    }
    
    @isTest 
    static void createCaseTestWithUnsubscribe() 
    {	
        PrivacyCaseTests.makeData();
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                         'Complete',
                                         '[{"ResponseMessage":"NEW CUSTOMER","EmailAddress":"test@test.com"}]',
                                         null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Id recordTypeIdPrivacyRequest = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Privacy_Request').getRecordTypeId();
        Id recordTypeIdSupportCase = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Support_Case').getRecordTypeId();
        String brandName='2';
        String Country='US';
        List<Case> getCaseList = TestDataFactory.createCases(1);
        getCaseList[0].origin='Web';
        getCaseList[0].Country_of_Residence__c='Canada';
        getCaseList[0].State_of_Residence__c=null;
        getCaseList[0].Type='Unsubscribe';
		getCaseList[0].SuppliedEmail='abc@gmail.com';       
        getCaseList[0].SuppliedPhone='9988998899';
        
        PersonalDataFormApexController.createCase(getCaseList[0], 'test name' , brandName, Country);
       
    }
    
    @isTest 
    static void createCaseTestWithOther() 
    {	
        PrivacyCaseTests.makeData();

        Id recordTypeIdPrivacyRequest = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Privacy_Request').getRecordTypeId();
        Id recordTypeIdSupportCase = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Support_Case').getRecordTypeId();
        String brandName='2';
        String Country='US';
        List<Case> getCaseList = TestDataFactory.createCases(1);
        getCaseList[0].origin='Web';
        getCaseList[0].Country_of_Residence__c='Canada';
        getCaseList[0].State_of_Residence__c=null;
        getCaseList[0].Type='Access My Data';
		getCaseList[0].SuppliedEmail='abc@gmail.com';       
        getCaseList[0].SuppliedPhone='9988998899';
        
        PersonalDataFormApexController.createCase(getCaseList[0], 'test name' , brandName,Country);
       
    }
}