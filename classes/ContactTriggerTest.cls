@isTest
private class ContactTriggerTest {

    private static testmethod void ContactTriggerTest() {

        insert new et4ae5__Configuration__c(et4ae5__Support_Ticket_Recipient__c = 'example@example.com');
        Test.startTest();
        Contact c = new Contact(LastName='TestExample',Brand_Id__c='9');
        insert c;
        System.assert(!String.isBlank(c.Id));
        Test.stopTest();

    }

    @isTest static void TestDeleteContact() {
        // Test data setup
        Account acc = new Account();
        acc.Name = 'generic Account' + Math.random();
        insert acc;

        Contact con = new Contact();
        con.email = 'foo@example.com';
        con.lastName = 'generic contact ' + Math.random();
        con.AccountId = acc.id;
        con.Brand_Id__c='9';
        insert con;

        GenericRecords__c genRec = new GenericRecords__c(
                Name = Constants.privacyContactGenericRecordSettingName,
                recordId__c = con.Id
        );
        insert genRec;

        GenericRecords__c genRecAcct = new GenericRecords__c(
                Name = Constants.AccountGenericRecordSettingName,
                recordId__c = acc.Id
        );
        insert genRecAcct;

        Account acct = new Account(
                Name='Test Account ' + Math.random()
        );
        insert acct;
        Contact cont = new Contact(
                LastName='contact ' + Math.random(),
                AccountId=acct.Id,Brand_Id__c='9',
                RecordTypeId=Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Email').getRecordTypeId()
        );
        insert cont;
        Asset a = new Asset(
                ContactId=cont.Id,
                Name='Asset ' + Math.random()
        );
        insert a;
        Case c = new Case(
                ContactId=cont.Id,
                AccountId=acct.Id,
                Origin='Chat',
                Brand__c='2',
                Status='Open',
                RecordTypeId=Constants.supportCaseRecordTypeId,
                AssetId=a.Id
        );
        insert c;
        Contract ct = new Contract(
                CustomerSignedId=cont.Id,
                AccountId=acct.Id
        );
        insert ct;

        // Perform test
        Test.startTest();
        Database.DeleteResult result = Database.delete(cont, false);
        Test.stopTest();
        
        System.assert(result.isSuccess());
    }
    @isTest
    public static void upsertChildContactOnParentupdateTest(){
        Test.startTest();
        Account acct = new Account(Name='Test Account ' + Math.random());
        insert acct;
        Contact cont = new Contact(LastName='contact ' + Math.random(),AccountId=acct.Id,Brand_Id__c='9',
                RecordTypeId=Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Email').getRecordTypeId());
        insert cont;
        cont.EmailOptInStatus__c = 'N';
        update cont;
        cont.EmailOptInStatus__c = 'Y';
        update cont;
        Test.stopTest();
    }
    @istest
    public static void emailPreferenceTest(){
        Test.startTest();
        Account acct = new Account(Name='Test Account ' + Math.random());
        insert acct;
        Contact cont = new Contact(LastName='contact ' + Math.random(),AccountId=acct.Id,Brand_Id__c='2',
                                   StoreOfCapture__c='CK601',WelcomeSource__c='02',
                                   RecordTypeId=Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Email').getRecordTypeId());
        insert cont;
        
        Test.stopTest();
    }
    @isTest
    public static void accountAssociationtest(){
        Test.startTest();
		Id recid = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Email').getRecordTypeId(); 
        Account acct = new Account(Name='Test Account ' + Math.random());
        insert acct;
        Contact cont = new Contact(LastName='contact ' + Math.random(),AccountId=acct.Id,Brand_Id__c='9',
                                   StoreOfCapture__c='601',WelcomeSource__c='02',Email= 'ex@test.com',
                                   RecordTypeId=recid,Status__c ='ACTIVE');

        insert cont;
        List<COntact> cntlist = new List<Contact>();
		Contact cnt = new Contact(FirstName = 'Child',LastName ='Brand84',Email ='ex@test.com',
                                  Brand_Id__c='84',Status__c ='ACTIVE');
		Contact cnt1 = new Contact(FirstName = 'Parent',LastName ='Brand4',Email ='ex@test.com',
                                   Brand_Id__c='4',Status__c ='ACTIVE');
		Contact cnt2 = new Contact(FirstName = 'Parent',LastName ='Bramd3',Email ='exp@ex.com',
                                  Brand_Id__c='1',Status__c ='ACTIVE');
		cntlist.add(cnt2);
		cntlist.add(cnt);
		cntlist.add(cnt1);
		insert cntlist;
        
        Test.stopTest();
    }
}