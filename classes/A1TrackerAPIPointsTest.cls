@isTest
public class A1TrackerAPIPointsTest {
     static Map<String, String> responseHeaders = new Map<String, String>();     
    static void testDatasetup(){
        Contact con = new Contact(FirstName='Test',LastName='User',Brand_Id__c='2', LoyaltyID__c='123456789',Email='testUser@nomail.com');
        insert con;
        System.debug(con.Id);
        Case cas = new Case(Origin='Email',Status='New',Brand__c='2',Subject='Test Case',ContactId=con.Id);
        insert cas;
        System.debug('Case contact '+cas.ContactId+'--'+cas.Contact.Brand_Id__c);
    }
    
    @isTest
    static void futurePostTrackerAPIEventstest(){
        Test.startTest();
        testDatasetup();
        List<Case> caseList = new List<Case>();
        Contact con = new Contact(FirstName='Test',LastName='User',Brand_Id__c='2', LoyaltyID__c='123456789',Email='testUser@nomail.com');
        insert con;
        Case cas = new Case(Origin='Email',Status='New',Brand__c='2',Subject='Test Case',ContactId=con.Id);
        caseList.add(cas);
        Case cas1 = new Case(Origin='Email',Status='New',Brand__c='2',Subject='Test Case',ContactId=con.Id);
        caseList.add(cas1);
        Case cas2 = new Case(Origin='Email',Status='New',Brand__c='2',Subject='Test Case',ContactId=con.Id);
        caseList.add(cas2);
        Case cas3 = new Case(Origin='Email',Status='New',Brand__c='2',Subject='Test Case',ContactId=con.Id);
        caseList.add(cas3);
        insert caseList;
        responseHeaders.put('Content-Type', 'application/json');
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                 'OK',
                                                 '{"access_token":"ecdc4492-8a1c-4f03-b9ad-6b9db87f61a1","token_type":"bearer","expires_in":15445210}',
                                                 responseHeaders);
        Test.setMock(HttpCalloutMock.class, fakeResponse);  
        Map<Id,Case> cases = new Map<Id,Case>([SELECT Id FROM Case limit 100]);
        List<Id> caseId = new List<Id>(cases.keySet());
        
        A1TrackerAPIPoints.invokePostTrackerAPIPoints(caseId);
        Test.stopTest();
    }

}