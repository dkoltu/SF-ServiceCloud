/**
* @author Magnet360
*
* @date 2019
*
* @description Test Class for CaseUtility class.
*
* @see CaseUtility
*/
@isTest
private class CaseUtilityTest {
    
    Static String RecordTypeSupportCaseId = Schema.SObjectType.CASE.getRecordTypeInfosByDeveloperName().get('Support_Case').getRecordTypeId();
    Static String RecordTypePrivacyCaseId = Schema.SObjectType.CASE.getRecordTypeInfosByDeveloperName().get('Privacy_Request').getRecordTypeId();
    
    @isTest
    private static void TestMethod1(){
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                         'Complete',
                                         '[{"ResponseMessage":"NEW CUSTOMER","EmailAddress":"test@test.com"}]',
                                         null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        //New case created for Contact not existing
        List<Case> caseList = TestDataFactory.createCases(1);
        Case case1 = caseList[0];
        case1.SuppliedEmail = 'testuser1@nomail.com';
        case1.SuppliedName = 'testuser1';
        case1.Brand__c = '1';
        case1.RecordTypeId = RecordTypeSupportCaseId;
        
        Test.startTest();
        insert case1;
        Test.stopTest();
        
        List<Case> createdCase = [SELECT Id, SuppliedName, SuppliedEmail, AccountId, ContactId FROM Case];
        List<Account> createdAccount = [SELECT Id, Name FROM Account];
        system.debug(createdAccount);
        List<Contact> createdContact = [SELECT Id, LastName FROM Contact];
        System.assert(createdCase.Size() == 1);
        System.assert(createdAccount.Size() == 1);
        System.assert(createdContact.Size() == 1);
        System.assertEquals(createdCase[0].AccountId, createdAccount[0].Id);
        System.assertEquals(createdCase[0].ContactId, createdContact[0].Id);
        
    }
    
    @isTest
    private static void TestMethod2(){
        //New case created for existing Contact with same brand
        List<Account> accList = TestDataFactory.createAccount(1);
        insert accList;
        
        List<Contact> conList = TestDataFactory.createContact(1);
        Contact con = conList[0];
        con.AccountId = accList[0].Id;
        con.Email = 'testuser1@nomail.com';
        con.LastName = 'testuser1';
        con.Brand_Id__c = '1';
        insert con;
        
        List<Case> caseList = TestDataFactory.createCases(1);
        Case case1 = caseList[0];
        case1.SuppliedEmail = 'testuser1@nomail.com';
        case1.SuppliedName = 'testuser1';
        case1.Brand__c = '1';
        case1.RecordTypeId = RecordTypeSupportCaseId;
        
        Test.startTest();
        insert case1;
        Test.stopTest();
        
        List<Case> createdCase = [SELECT Id, SuppliedName, SuppliedEmail, AccountId, ContactId FROM Case];
        List<Account> createdAccount = [SELECT Id, Name FROM Account];
        List<Contact> createdContact = [SELECT Id, LastName FROM Contact];
        System.assert(createdCase.Size() == 1);
        System.assert(createdAccount.Size() == 1);
        System.assert(createdContact.Size() == 1);
        System.assertEquals(createdCase[0].AccountId, createdAccount[0].Id);
        System.assertEquals(createdCase[0].ContactId, createdContact[0].Id);
    }
    
    @isTest
    private static void TestMethod3(){
        //New case created for existing Contact with different Brand
        List<Account> accList = TestDataFactory.createAccount(1);
        insert accList;
        
        List<Contact> conList = TestDataFactory.createContact(1);
        Contact con = conList[0];
        con.Email = 'testuser1@nomail.com';
        con.LastName = 'testuser1';
        con.Brand_Id__c = '1';
        con.AccountId = accList[0].Id;
        con.Phone='7890789078';
        insert con;
        
        List<Case> caseList = TestDataFactory.createCases(1);
        Case case1 = caseList[0];
        case1.SuppliedEmail = 'testuser1@nomail.com';
        case1.SuppliedName = 'testuser1';
        case1.Brand__c = '2';
        case1.SuppliedPhone ='7890789078';
        case1.RecordTypeId = RecordTypeSupportCaseId;
        
        Test.startTest();
        insert case1;
        Test.stopTest();
        
        List<Case> createdCase = [SELECT Id, SuppliedName, SuppliedEmail, AccountId, ContactId FROM Case];
        List<Account> createdAccount = [SELECT Id, Name FROM Account];
        List<Contact> createdContact = [SELECT Id, LastName FROM Contact];
        List<Contact> createdContactRelated = [SELECT Id, LastName FROM Contact WHERE Brand_Id__c = '2'];
        System.assert(createdCase.Size() == 1);
        System.assert(createdAccount.Size() == 1);
        System.assert(createdContact.Size() == 2);
        System.assertEquals(createdCase[0].AccountId, createdAccount[0].Id);
        System.assertEquals(createdCase[0].ContactId, createdContactRelated[0].Id);           
    }
    
    @isTest
    private static void TestMethod4(){
        //New case created for existing Contact with Same Phone and Brand
        List<Account> accList = TestDataFactory.createAccount(1);
        insert accList;
        
        List<Contact> conList = TestDataFactory.createContact(1);
        Contact con = conList[0];
        con.LastName = 'testuser1';
        con.Brand_Id__c = '2';
        con.Phone='7890789078';
        con.Source_System__c = 'SFSC';
        insert con;
        
        List<Case> caseList = TestDataFactory.createCases(1);
        Case case1 = caseList[0];
        case1.SuppliedEmail = 'testuser1@nomail.com';
        case1.SuppliedName = 'testuser1';
        case1.Brand__c = '2';
        case1.SuppliedPhone ='7890789078';
        case1.RecordTypeId = RecordTypeSupportCaseId;
        
        Test.startTest();
        insert case1;
        Test.stopTest();
        
        List<Case> createdCase = [SELECT Id, SuppliedName, SuppliedEmail, AccountId, ContactId FROM Case];
        System.debug('>>createdCase:'+createdCase);
        List<Account> createdAccount = [SELECT Id, Name FROM Account];
        List<Contact> createdContact = [SELECT Id, LastName FROM Contact WHERE Phone = '7890789078'];
        System.assert(createdCase.Size() == 1);
        System.assert(createdAccount.Size() == 1);
        System.assert(createdContact.Size() == 1);
        //System.assertEquals(createdCase[0].AccountId, createdAccount[0].Id);
        System.assertEquals(createdCase[0].ContactId, createdContact[0].Id);           
    }
    
    @isTest
    private static void TestMethod5(){
        PrivacyCaseTests.makeData();
        //New case created for existing Contact with Same Phone and Brand
        List<Account> accList = TestDataFactory.createAccount(10);
        insert accList;
        
        List<Contact> conListInsert = new List<Contact>();
        List<Contact> conList = TestDataFactory.createContact(10);
        for (Integer i=0;i<accList.size();i++){
            conList[i].Email = 'testuser'+i+'@nomail.com';
            conList[i].LastName = 'testuser'+i;
            conList[i].Brand_Id__c = '4';
            conList[i].Phone='7890789078';
            conList[i].AccountId = accList[i].Id;
            conListInsert.add(conList[i]);
        }
        insert conListInsert;
        
        List<Case> caseListInsert = new List<Case>();
        List<Case> caseList = TestDataFactory.createCases(10);
        for(Integer i=0;i<caseList.size();i++){
            caseList[i].SuppliedEmail = 'testuser'+i+'@nomail.com';
            caseList[i].SuppliedName = 'testuser'+i;
            caseList[i].Brand__c = '4';
            caseList[i].SuppliedPhone ='7890789078';
            caseList[i].RecordTypeId = RecordTypePrivacyCaseId;
            caseList[i].Type = Constants.privacyCaseType;
            caseList[i].Sub_Type__c = Constants.deletionRequestSubType;
            caseListInsert.add(caseList[i]);
        }
        
        Test.startTest();
        insert caseListInsert;
        Test.stopTest();
        
        List<Case> createdCase = [SELECT Id, SuppliedName, SuppliedEmail, AccountId, ContactId FROM Case];
        List<Account> createdAccount = [SELECT Id, Name FROM Account];
        List<Contact> createdContact = [SELECT Id, LastName FROM Contact WHERE Email = 'testuser0@nomail.com'];
        System.assert(createdCase.Size() == 10);         
    }

    @isTest
    private static void TestMethodOneName(){
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                'Complete',
                '[{"ResponseMessage":"NEW CUSTOMER","EmailAddress":"test@test.com"}]',
                null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        //New case created for Contact not existing
        List<Case> caseList = TestDataFactory.createCases(1);
        Case case1 = caseList[0];
        case1.SuppliedEmail = 'testuser1@nomail.com';
        case1.SuppliedName = 'First';
        case1.Brand__c = '1';
        case1.RecordTypeId = RecordTypeSupportCaseId;
        case1.Origin = 'Email';

        Test.startTest();
        insert case1;
        Test.stopTest();

        List<Case> createdCase = [SELECT Id, SuppliedName, SuppliedEmail, AccountId, ContactId, Supplied_First_Name__c, Supplied_Last_Name__c FROM Case];
        List<Account> createdAccount = [SELECT Id, Name FROM Account];
        List<Contact> createdContact = [SELECT Id, FirstName, LastName FROM Contact];
        System.assert(createdCase.Size() == 1);
        System.assert(createdAccount.Size() == 1);
        System.assert(createdContact.Size() == 1);
        System.assertEquals(createdCase[0].AccountId, createdAccount[0].Id);
        System.assertEquals(createdCase[0].ContactId, createdContact[0].Id);

    }

    @isTest
    private static void TestMethodEmailToCaseSetBrand(){
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                'Complete',
                '[{"ResponseMessage":"NEW CUSTOMER","EmailAddress":"test@test.com"}]',
                null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        //New case created for Contact not existing
        List<Case> caseList = TestDataFactory.createCases(1);
        Case case1 = caseList[0];
        case1.SuppliedEmail = 'testuser1@nomail.com';
        case1.SuppliedName = 'First';
        case1.Brand__c = null;
        case1.RecordTypeId = RecordTypeSupportCaseId;
        case1.Origin = 'Email - 1';

        Test.startTest();
        insert case1;
        Test.stopTest();

        List<Case> createdCase = [SELECT Id, Origin, SuppliedName, SuppliedEmail, AccountId, ContactId, Supplied_First_Name__c, Supplied_Last_Name__c,Brand__c FROM Case];
        List<Account> createdAccount = [SELECT Id, Name FROM Account];
        List<Contact> createdContact = [SELECT Id, FirstName, LastName, Brand_Id__c FROM Contact];
        System.assert(createdCase.Size() == 1);
        System.assert(createdAccount.Size() == 1);
        System.assert(createdContact.Size() == 1);
        System.assertEquals(createdCase[0].AccountId, createdAccount[0].Id);
        System.assertEquals(createdCase[0].ContactId, createdContact[0].Id);
        System.assertEquals(createdCase[0].Brand__c, createdContact[0].Brand_Id__c);
        System.assertEquals(createdCase[0].Origin, 'Email');

    }

    @isTest
    private static void TestMethodTwoNames(){
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                'Complete',
                '[{"ResponseMessage":"NEW CUSTOMER","EmailAddress":"test@test.com"}]',
                null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        //New case created for Contact not existing
        List<Case> caseList = TestDataFactory.createCases(1);
        Case case1 = caseList[0];
        case1.SuppliedEmail = 'testuser1@nomail.com';
        case1.SuppliedName = 'First Second';
        case1.Brand__c = '1';
        case1.RecordTypeId = RecordTypeSupportCaseId;
        case1.Origin = 'Email';

        Test.startTest();
        insert case1;
        Test.stopTest();

        List<Case> createdCase = [SELECT Id, SuppliedName, SuppliedEmail, AccountId, ContactId, Supplied_First_Name__c, Supplied_Last_Name__c FROM Case];
        List<Account> createdAccount = [SELECT Id, Name FROM Account];
        List<Contact> createdContact = [SELECT Id, FirstName, LastName FROM Contact];
        System.assert(createdCase.Size() == 1);
        System.assert(createdAccount.Size() == 1);
        System.assert(createdContact.Size() == 1);
        System.assertEquals(createdCase[0].Supplied_First_Name__c,'First');
        System.assertEquals(createdCase[0].Supplied_Last_Name__c,'Second');
        System.assertEquals(createdCase[0].AccountId, createdAccount[0].Id);
        System.assertEquals(createdCase[0].ContactId, createdContact[0].Id);

    }

    @isTest
    private static void TestMethodThreeNames(){
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                'Complete',
                '[{"ResponseMessage":"NEW CUSTOMER","EmailAddress":"test@test.com"}]',
                null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        //New case created for Contact not existing
        List<Case> caseList = TestDataFactory.createCases(1);
        Case case1 = caseList[0];
        case1.SuppliedEmail = 'testuser1@nomail.com';
        case1.SuppliedName = 'First Second Third';
        case1.Brand__c = '1';
        case1.RecordTypeId = RecordTypeSupportCaseId;
        case1.Origin = 'Email';

        Test.startTest();
        insert case1;
        Test.stopTest();

        List<Case> createdCase = [SELECT Id, SuppliedName, SuppliedEmail, AccountId, ContactId, Supplied_First_Name__c, Supplied_Last_Name__c FROM Case];
        List<Account> createdAccount = [SELECT Id, Name FROM Account];
        List<Contact> createdContact = [SELECT Id, FirstName, LastName FROM Contact];
        System.assert(createdCase.Size() == 1);
        System.assert(createdAccount.Size() == 1);
        System.assert(createdContact.Size() == 1);
        System.assertEquals(createdCase[0].Supplied_First_Name__c,'First Second');
        System.assertEquals(createdCase[0].Supplied_Last_Name__c,'Third');
        System.assertEquals(createdCase[0].AccountId, createdAccount[0].Id);
        System.assertEquals(createdCase[0].ContactId, createdContact[0].Id);
        System.assertEquals(createdContact[0].FirstName,'First Second');
        System.assertEquals(createdContact[0].LastName,'Third');

    }
    
}