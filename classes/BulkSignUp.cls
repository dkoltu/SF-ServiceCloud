/* * 
*  Json Request
*  {"Count":"2","Subscribes":[{"BrandId":"9","Zeta_Email_Id":"100000021","Zeta_Customer_Id":"40000021","SubscriberKey":"","FirstName":"John","MiddleName":"M","LastName":"Doe","Street":"123 Main Street","City":"Albany","State":"NY","ZIP":"14810","Country":"US","Email":"B1-13@z.com","PrimaryPhone":"5555555555","HomePhone":"5555555555","SMSPhone":"5555555555","BirthDate":"20000101","Gender":"M","CompanyCode":"TX","HomeStore":"CO601","StoreOfCapture":"CO601","SourceSystem":"WiFi","LoyaltyId":"","LoyaltyOptinFlag":"true","LoyaltyOptinDate":"","EmailOptinFlag":"true","EmailSignupDate":"","TransactionDate":"","ZdTnCUserId":"369760957914","ZdPVHUserId":"369760957914","EmailOptinForHESubbrands":"5|81|83|84"},{"BrandId":"1","Zeta_Email_Id":"100000022","Zeta_Customer_Id":"40000022",...}]}
* 
*  https://instance.salesforce.com/services/apexrest/subscribers/SignUp 
    NASSC-1108
    NASSC-1199
    NASSC-1311 ,NASSC-1321
*/

@RestResource(urlmapping='/subscribers/SignUp')
global without sharing class BulkSignUp {
    
    static Id emailRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Email').getRecordTypeId(); 
        
    global class SubRequest {
        public String Count;
        public List<Subscriber> Subscribes;
        public String FileName;
    }    
    global class Subscriber {
        public String BrandId;
        public String Zeta_Email_Id;  //maps to Contact.External_Id__c
        public String Zeta_Customer_Id;  // maps to Contact.Customer_Id__c
        public String SubscriberKey;  // same as Contact's Id
        public String FirstName;
        public String MiddleName;
        public String LastName;
        public String Street;
        public String City;
        public String State;
        public String Zip;
        public String Country;
        public String Email;
        public String PrimaryPhone;  // phone
        public String HomePhone;
        public String OtherPhone;
        public String SMSPhone;   //same as mobile Phone
        public String BirthDate;
        public String Gender;
        public String CompanyCode;
        public String HomeStore;
        public String StoreOfCapture;
        public String SourceSystem;
        public String Source;
        public String LoyaltyId;
        public String LoyaltyOptinFlag;
        public String LoyaltyOptInDate;
        public String EmailOptInFlag;
        public String EmailSignUpDate;
        public String TransactionDate;
        public String Channel;
        public String EmailPreferences;
        public String StorePreference;
        public String DirectMailOptinFlag;
        public String EmailOptInForSubBrands;
        public String A1ChainId;
    }
    
    global class SubResponse{
        public String Code;
        public String Count;
        public List<Subscribes> Subscribes;
        public String Message;
    }
    
    global class Subscribes{
        public String ContactId;
        public String Zeta_Email_Id; 
    }
    
    @HttpPost
    global static SubResponse doSignUp(){
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response; 
        String requestData = req.requestBody.toString();
        System.debug('request data '+requestData);
        List<Contact> newTopBrandContacts = new List<Contact>();
        List<Contact> newSubBrandContacts = new List<Contact>();
        LoyaltySettings__mdt loyaltySetting;
        Boolean createParent = false;
        Boolean createChild = false;
        List<Contact> searchecdParentContactList = new List<Contact>();
        
        SubRequest subReq = (SubRequest)JSON.deserialize(requestData,SubRequest.class);
        System.debug('>>subReq :'+subReq);
        Set <Id> SubsriberKeys = new Set<Id>();
        Set <String> BrandIds = new Set<String>(); 
        Set <String> EmailAddresses = new Set<String>();
        Map <Id,Contact> existingSubkeyContactMap;
        List <Contact> brandEmailContacts = new List<Contact>();        
        Map <String,Map<String,Contact>> BrandToEmailContactMap = new Map <String,Map<String,Contact>>();        
        SubResponse errorResponse = new SubResponse();
        Boolean isError = false;
        if (subReq.Subscribes.size()==0) isError = true; 
        
        List <Contact> profileUpdateContacts = new List <Contact>();
        List <Contact> newContacts = new List<Contact>();
        List<SignUpActivity> signUpActivityList = new List<SignUpActivity>();
        String FileName =    subReq.FileName;
        // Create List of Email and BrandId to be used to get matching contacts        
        for (Subscriber sub : subReq.Subscribes) {
            
            if (String.isEmpty(sub.BrandId) || String.isEmpty(sub.Email)) {
                isError = true;
                break;
            }
            if (String.isNotEmpty(sub.SubscriberKey)) SubsriberKeys.add(Id.valueOf(sub.SubscriberKey));
            else {
                if (String.isNotEmpty(sub.BrandId)) BrandIds.add(sub.BrandId);
                if (String.isNotEmpty(sub.Email)) EmailAddresses.add(sub.Email);
            } 
        }
        if (isError) {
            res.statusCode = 400;
            errorResponse.code = 'INVALID_QUERY';
            errorResponse.Message = 'Missing required parameters:  BrandId or email';
            return errorResponse;
        }        

        if (!SubsriberKeys.isEmpty()) existingSubkeyContactMap = 
            new Map<Id,Contact>([SELECT Id, FirstName, MiddleName, LastName, MailingStreet, MailingCity, MailingState, MailingPostalCode, Company_Code__c,
                                 Brand_Id__c, MailingCountry, Email, Phone, HomePhone, MobilePhone, Birthdate,  HomeStore__c, LoyaltyID__c, External_Id__c, Customer_Id__c,
                                 StoreOfCapture__c, Source_System__c, LoyaltyFlag__c, EmailOptInDate__c, EmailOptInStatus__c, Loyalty_Optin_Date__c, PVHCreatedDate__c, PrefCenterInterests__c,Source__c  
                                 FROM Contact
                                 WHERE Id IN :SubsriberKeys]);
        
        if (!BrandIds.isEmpty() || !EmailAddresses.isEmpty()){
            brandEmailContacts = [SELECT Id, FirstName, MiddleName, LastName, MailingStreet, MailingCity, MailingState, MailingPostalCode, Company_Code__c,
                                  Brand_Id__c, MailingCountry, Email, Phone, HomePhone, MobilePhone, Birthdate,  HomeStore__c, LoyaltyID__c, External_Id__c, Customer_Id__c,
                                  StoreOfCapture__c, Source_System__c, LoyaltyFlag__c, EmailOptInDate__c, AccountId, EmailOptInStatus__c, Loyalty_Optin_Date__c, PVHCreatedDate__c, PrefCenterInterests__c, Source__c
            FROM Contact
                                  WHERE RecordTypeId = :emailRecordTypeId and Brand_Id__c IN :BrandIds and Email IN :EmailAddresses order by Brand_Id__c, Email];
        }
        
        if (!brandEmailContacts.isEmpty()) {            
            for (Contact beCon : brandEmailContacts){
                Map <String,Contact> emailToContactMap = new Map<String,Contact>();
                if (BrandToEmailContactMap.containsKey(beCon.Brand_Id__c)) BrandToEmailContactMap.get(beCon.Brand_Id__c).put(beCon.Email,beCon);
                else {
                    emailToContactMap.put(beCon.Email,beCon);
                    BrandToEmailContactMap.put(beCon.Brand_Id__c, emailToContactMap);
                } 
            }
        }
        
        System.debug('>>BrandToEmailContactMap :'+BrandToEmailContactMap); 
        
        for (Subscriber sub : subReq.Subscribes) {
            Contact thisContact;
            if (String.isNotEmpty(sub.SubscriberKey)){ 
                thisContact =  existingSubkeyContactMap.get(sub.SubscriberKey); 
                if(thisContact != Null) profileUpdateContacts.add(updateContact(thisContact, sub));                
            } else {                
                if (BrandToEmailContactMap.containsKey(sub.BrandId) && BrandToEmailContactMap.get(sub.BrandId).containsKey(sub.Email.toLowerCase())) {
                    thisContact = BrandToEmailContactMap.get(sub.BrandId).get(sub.Email.toLowerCase());
                    if(thisContact != Null) profileUpdateContacts.add(updateContact(thisContact, sub));
                } else {                     
                    //Contact not found
                    //Is Top Level Brand
                    List<LoyaltySettings__mdt> listLoyaltySettingList = [Select Id,BrandId__c,IsLoyaltyApplicable__c,Parent_Brand__c from LoyaltySettings__mdt where BrandId__c = :sub.BrandId ];
                    if(listLoyaltySettingList.size()>0) loyaltySetting = listLoyaltySettingList[0];
                    
                    if(loyaltySetting != null && String.isEmpty(loyaltySetting.Parent_Brand__c)){
                        Contact newParentContact = new Contact();                  
                        createParent = false; createChild = false;
                        newTopBrandContacts.add(createContact(newParentContact,sub, sub.BrandId, createParent, createChild));
                        Boolean emailOptedIn = false;
                        if((String.isNotBlank(sub.SourceSystem) && (sub.SourceSystem=='POS')) || (String.isNotBlank(sub.EmailOptinFlag) && Boolean.valueOf(sub.EmailOptinFlag))) emailOptedIn = true;
                        //has subbrands and email optedin
                  //      if((String.isNotBlank(sub.SourceSystem) && (sub.SourceSystem=='POS')) || (String.isNotBlank(sub.EmailOptinFlag))){
                            if(emailOptedIn){
                                 
                                List<LoyaltySettings__mdt> subBrandsLoyaltySetting = [Select Id,BrandId__c,IsLoyaltyApplicable__c,Parent_Brand__c from LoyaltySettings__mdt where Parent_Brand__c  = :sub.BrandId ];
                                system.debug('### subBrandsLoyaltySetting '+ subBrandsLoyaltySetting);
                                if(subBrandsLoyaltySetting.size()>0){
                                    createParent = false; createChild = true;
                                    //has subbrands
                                    for(LoyaltySettings__mdt sb: subBrandsLoyaltySetting){
                                        Contact newSubBrandContact = new Contact();                                                                  
                                        newSubBrandContacts.add(createContact(newSubBrandContact,sub, sb.BrandId__c, createParent, createChild));
                                    }                                    
                                }
                            }                            
                      //  }
                    } else if(loyaltySetting != null && String.isNotEmpty(loyaltySetting.Parent_Brand__c)) {
                        //Not Top Level Brand 
                        //Does Parent Brand Contacts exists in DB
                        searchecdParentContactList = searchContacts(loyaltySetting.Parent_Brand__c,sub.email,emailRecordTypeId);
                        System.debug('### searchecdParentContactList :'+searchecdParentContactList);
                        if(searchecdParentContactList.size()<1){
                            
                            //Contact does not exist for Parent Brand(with Loyalty Flag = N and Email Status = N)
                            createParent = true; createChild = false;
                            Contact newParentContact = new Contact();
                            Contact parentCon = createContact(newParentContact,sub, loyaltySetting.Parent_Brand__c, createParent, createChild);
                            System.debug('### parentCon:'+parentCon);
                            // add to newTopBrandContacts
                            newTopBrandContacts.add(parentCon);
                        }
                        
                        //setup this sub brand contact with flags from req
                        createParent = false; createChild = false;
                        Contact newSubBrandContact = new Contact();
                        /*if(String.isNotBlank(sub.SourceSystem)){
                            if(sub.SourceSystem.equalsIgnoreCase('WiFi')) newSubBrandContact.PrefCenterInterests__c = loyaltySetting.WiFiEmailPreferences__c;
                        }*/
                        Contact subBrandCon = createContact(newSubBrandContact,sub, sub.BrandId, createParent, createChild);
                        System.debug('### subBrandCon:'+subBrandCon);
                        // add to newSubBrandContacts list
                        newSubBrandContacts.add(subBrandCon);   
                    }            
                }
            }            
        }
        
        List <contact> allContacts = new List<contact>();  
        if (!profileUpdateContacts.isEmpty()) {
            Database.SaveResult[] srList = Database.update(profileUpdateContacts, false);
            for(Contact c : profileUpdateContacts){
                if(c.id != null ) allContacts.add(c);
            }
            ContactUtility.createErrorLogRecords(srList,profileUpdateContacts[0].Latest_Source__c,FileName);
        }
        
        if (!newTopBrandContacts.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(newTopBrandContacts, false);
            for(Contact c : newTopBrandContacts){
                if(c.id != null ) allContacts.add(c);
            }            
          	ContactUtility.createErrorLogRecords(srList,newTopBrandContacts[0].Latest_Source__c,FileName);
        }
        
        if (!newSubBrandContacts.isEmpty()) { 
            Database.SaveResult[] srList = Database.insert(newSubBrandContacts, false);
            for(Contact c : newSubBrandContacts){
                if(c.id != null ) allContacts.add(c);
            }
            ContactUtility.createErrorLogRecords(srList,newSubBrandContacts[0].Latest_Source__c,FileName);
        }
        
        // send HTTP response for all contacts
        SubResponse SuccessResponse = new SubResponse();
        List<Subscribes> subsList = new List<Subscribes>();
        
        for(Contact con : allContacts){
            Subscribes sub = new Subscribes();
            sub.ContactId = con.Id;
            if (con.External_Id__c!=null) sub.Zeta_Email_Id = con.External_Id__c;
            
            subsList.add(sub);
            
            signUpActivityList.add(SignUpActivity.signupActivity(con.Id, con.Latest_Source__c,con.Brand_Id__c));
        }
        
        if(signUpActivityList.size()>0) SignUpActivity.logSignUpActivity(signUpActivityList);
        
        SuccessResponse.Code = 'OK';
        SuccessResponse.Count = String.valueOf(subsList.size());
        SuccessResponse.subscribes = subsList;
        res.statusCode = 200;
        
        return SuccessResponse;
    }
    
    Static List<Contact> searchContacts(String brandId, String emails,Id emailRecordTypeId){
        
        //System.debug('### Contact search Brand Id:'+brandId); System.debug('### Contact search emails: '+emails);System.debug('### Contact search emailRecordTypeId: '+emailRecordTypeId);
        List<Contact> searchedContactList =  [SELECT Id, FirstName, LastName, Brand_Id__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, 
                                              Phone, MobilePhone, MailingCountry, Email, HomePhone, Birthdate, HomeStore__c, AccountId,  
                                              LoyaltyID__c, Latest_Source__c, EmailOptInStatus__c, SMSOptinStatus__c, LoyaltyFlag__c, ReportsToId, Source__c
                                              FROM Contact 
                                              WHERE RecordTypeId = :emailRecordTypeId AND Brand_Id__c =:brandId AND Email = :emails];
        
        return ((searchedContactList!=null)?searchedContactList:Null);
    }
    
    private static Contact updateContact(Contact Con, Subscriber sub){
        // do not update brandId, Email, ExternalId__c, Customer_Id__c fields
        Con.Status__c = 'ACTIVE';
        if(String.isNotBlank(sub.Zeta_Email_Id) && (Con.External_Id__c != sub.Zeta_Email_Id)) Con.External_Id__c = sub.Zeta_Email_Id;
        if(String.isNotBlank(sub.Zeta_Customer_Id) && (Con.Customer_Id__c != sub.Zeta_Customer_Id)) Con.Customer_Id__c = sub.Zeta_Customer_Id;
        if(String.isNotBlank(sub.LoyaltyId) && (Con.LoyaltyId__c != sub.LoyaltyId)) Con.LoyaltyId__c = sub.LoyaltyId;
        if(String.isNotBlank(sub.FirstName) && (Con.FirstName != sub.FirstName)) Con.FirstName = sub.FirstName;
        if(String.isNotBlank(sub.MiddleName) && (Con.MiddleName != sub.MiddleName)) Con.MiddleName = sub.MiddleName;
        if(String.isNotBlank(sub.LastName) && (Con.LastName != sub.LastName)) Con.LastName = sub.LastName;
        if(String.isNotBlank(sub.Street) && (Con.MailingStreet != sub.Street)) Con.MailingStreet = sub.Street;
        if(String.isNotBlank(sub.City) && (Con.MailingCity != sub.City)) Con.MailingCity = sub.City;
        if(String.isNotBlank(sub.State) && (Con.MailingState != sub.State)) Con.MailingState = sub.State;
        if(String.isNotBlank(sub.ZIP) && (Con.MailingPostalCode != sub.ZIP)) Con.MailingPostalCode = sub.ZIP;
        if(String.isNotBlank(sub.Country) && (Con.MailingCountry != sub.Country)) Con.MailingCountry = sub.Country;
        if(String.isNotBlank(sub.PrimaryPhone) && (Con.Phone != sub.PrimaryPhone)) Con.Phone = sub.PrimaryPhone;
        if(String.isNotBlank(sub.HomePhone) && (Con.HomePhone != sub.HomePhone)) Con.HomePhone = sub.HomePhone;
        if(String.isNotBlank(sub.SMSPhone) && (Con.MobilePhone != sub.SMSPhone)) Con.MobilePhone = sub.SMSPhone;
        if(String.isNotBlank(sub.BirthDate) && (Con.Birthdate != UtilityClass.strYYYMMDDtoDate(sub.BirthDate))) Con.Birthdate = UtilityClass.strYYYMMDDtoDate(sub.BirthDate);
        if(String.isNotBlank(sub.HomeStore) && (Con.HomeStore__c != sub.HomeStore)) Con.HomeStore__c = (sub.HomeStore);
        if(String.isNotBlank(sub.StoreOfCapture) && (Con.StoreOfCapture__c != sub.StoreOfCapture)) Con.StoreOfCapture__c = sub.StoreOfCapture;
        if(String.isNotBlank(sub.SourceSystem)) con.Latest_Source__c = sub.SourceSystem;
        if(String.isNotBlank(sub.LoyaltyOptinFlag) && (Con.LoyaltyFlag__c != Boolean.valueOf(sub.LoyaltyOptinFlag))) Con.LoyaltyFlag__c = Boolean.valueOf(sub.LoyaltyOptinFlag);
        if(String.isNotBlank(sub.CompanyCode) && (Con.Company_Code__c != sub.CompanyCode)) Con.Company_Code__c = sub.CompanyCode;
        if(String.isNotBlank(sub.LoyaltyOptInDate) && (Con.Loyalty_Optin_Date__c != UtilityClass.strYYYMMDDtoDateTime(sub.LoyaltyOptInDate))) Con.Loyalty_Optin_Date__c = UtilityClass.strYYYMMDDtoDateTime(sub.LoyaltyOptInDate);

        String subEmailOptinValue;
        if(String.isNotBlank(sub.EmailOptinFlag)) {
            if (Boolean.valueOf(sub.EmailOptinFlag)) subEmailOptinValue= 'Y';
            else subEmailOptinValue= 'N';
        }
        // For POS, Email opt-in is defaulted as 'Y'
        if(String.isNotBlank(sub.SourceSystem) && (sub.SourceSystem=='POS'))  subEmailOptinValue= 'Y';
        if(sub.EmailOptinFlag!=null && Con.EmailOptInStatus__c != subEmailOptinValue) {
            Con.EmailOptInStatus__c = subEmailOptinValue;
            if (subEmailOptinValue=='Y') {
                if(String.isNotBlank(sub.EmailSignupDate)) {
                    Con.EmailOptInDate__c = UtilityClass.strYYYMMDDtoDateTime(sub.EmailSignupDate);
                }
                else {

                    Con.EmailOptInDate__c =System.Now();
                }
                Con.HasOptedOutOfEmail = false;
                Con.EmailOptOutDate__c = Null;                
            } else {
                Con.EmailOptInDate__c = null;
                Con.HasOptedOutOfEmail = true;
                Con.EmailOptOutDate__c = System.Now();
            }
        }
        if(String.isNotBlank(sub.TransactionDate) && Con.PVHCreatedDate__c != UtilityClass.strYYYMMDDtoDateTime(sub.TransactionDate)) Con.PVHCreatedDate__c = UtilityClass.strYYYMMDDtoDateTime(sub.TransactionDate);
        return Con;
    }
    
    private static Contact createContact(Contact newCon, Subscriber sub, String brandId, Boolean createParent, Boolean createChild) {

        newCon.createdByMethod__c = 'API';
        newCon.RecordTypeId = emailRecordTypeId;
        newCon.Status__c = 'ACTIVE';
        if (String.isNotBlank(sub.Zeta_Email_Id)) newCon.External_Id__c = ((createChild || createParent) ? null : sub.Zeta_Email_Id);
        if (String.isNotBlank(sub.Zeta_Customer_Id)) newCon.Customer_Id__c = ((createChild || createParent) ? null : sub.Zeta_Customer_Id);
        if (String.isNotBlank(sub.LoyaltyId)) newCon.LoyaltyId__c = sub.LoyaltyId;
        if (String.isNotBlank(brandId)) newCon.Brand_Id__c = brandId;
        if (String.isNotBlank(sub.Channel)) newCon.Channel__c = (sub.Channel);
        if (String.isNotBlank(sub.FirstName)) newCon.FirstName = sub.FirstName; else newCon.FirstName = 'Unknown';
        if (String.isNotBlank(sub.MiddleName)) newCon.MiddleName = sub.MiddleName;
        if (String.isNotBlank(sub.LastName)) newCon.LastName = sub.LastName; else newCon.LastName = 'Unknown';
        if (String.isNotBlank(sub.Street)) newCon.MailingStreet = sub.Street;
        if (String.isNotBlank(sub.City)) newCon.MailingCity = sub.City;
        if (String.isNotBlank(sub.State)) newCon.MailingState = sub.State;
        if (String.isNotBlank(sub.ZIP)) newCon.MailingPostalCode = sub.ZIP;
        if (String.isNotBlank(sub.Country)) newCon.MailingCountry = sub.Country;
        if (String.isNotBlank(sub.Email)) newCon.Email = sub.Email;
        if (String.isNotBlank(sub.PrimaryPhone)) newCon.Phone = sub.PrimaryPhone;
        if (String.isNotBlank(sub.HomePhone)) newCon.HomePhone = sub.HomePhone;
        if (String.isNotBlank(sub.OtherPhone)) newCon.OtherPhone = sub.OtherPhone;
        if (String.isNotBlank(sub.SMSPhone)) newCon.MobilePhone = sub.SMSPhone;
        if (String.isNotBlank(sub.BirthDate)) newCon.Birthdate = UtilityClass.strYYYMMDDtoDate(sub.BirthDate);
        if (String.isNotBlank(sub.HomeStore)) newCon.HomeStore__c = sub.HomeStore;
        if (String.isNotBlank(sub.StoreOfCapture)) newCon.StoreOfCapture__c = sub.StoreOfCapture;
        if (String.isNotBlank(sub.SourceSystem)) {
            newCon.Source_System__c = sub.SourceSystem;
            newCon.Latest_Source__c = sub.SourceSystem;
        }

        if (String.isNotBlank(sub.Source)) newCon.Source__c = sub.Source;
        if (String.isNotBlank(sub.A1ChainId) && (sub.A1ChainId=='2')) newCon.Channel__c = '1';  // spl condition for TH anchor stores
        if (String.isNotBlank(sub.LoyaltyId)) newCon.LoyaltyID__c = sub.LoyaltyId;
        if (String.isNotBlank(sub.LoyaltyOptinFlag)) {
            newCon.LoyaltyFlag__c = Boolean.valueOf(sub.LoyaltyOptinFlag);
            if (Boolean.valueOf(sub.LoyaltyOptinFlag)) {
                if (String.isNotBlank(sub.LoyaltyOptInDate)) newCon.Loyalty_Optin_Date__c = UtilityClass.strYYYMMDDtoDateTime(sub.LoyaltyOptInDate);
                else if(String.isNotBlank(sub.TransactionDate)) {
                    newCon.Loyalty_Optin_Date__c = UtilityClass.strYYYMMDDtoDateTime(sub.TransactionDate);
                }
                else newCon.Loyalty_Optin_Date__c = System.now();
            }
        }
        if(String.isNotBlank(sub.CompanyCode)) newCon.Company_Code__c = sub.CompanyCode;

        if(String.isNotBlank(sub.StorePreference)) newCon.StorePreference__c = sub.StorePreference;

        if(String.isNotBlank(sub.DirectMailOptinFlag) && Boolean.valueOf(sub.DirectMailOptinFlag)) {
            newCon.DirectMailOptin__c = true;
        }
        if(String.isNotBlank(sub.TransactionDate)) newCon.PVHCreatedDate__c = UtilityClass.strYYYMMDDtoDateTime(sub.TransactionDate);

        if(String.isNotBlank(sub.EmailPreferences)) newCon.PrefCenterInterests__c = sub.EmailPreferences;

        String subEmailOptinValue='N';
        if(String.isNotBlank(sub.EmailOptinFlag)) {
            if (Boolean.valueOf(sub.EmailOptinFlag)) subEmailOptinValue= 'Y';
        }
        // For POS, Email opt-in is defaulted as 'Y'
        if(String.isNotBlank(sub.SourceSystem) && (sub.SourceSystem=='POS'))  subEmailOptinValue= 'Y';
        if(subEmailOptinValue=='Y') {
            newCon.EmailOptInStatus__c = subEmailOptinValue;            
            if(String.isNotBlank(sub.EmailSignupDate)) {
                newCon.EmailOptInDate__c = UtilityClass.strYYYMMDDtoDateTime(sub.EmailSignupDate);
            } else if(String.isNotBlank(sub.TransactionDate)) {
                newCon.EmailOptInDate__c = UtilityClass.strYYYMMDDtoDateTime(sub.TransactionDate);
            } else {
                newCon.EmailOptInDate__c = System.Now();
            }
        } else if(subEmailOptinValue=='N'){
            newCon.EmailOptInStatus__c = 'N';
            newCon.EmailOptInDate__c = Null;
        }
        
        if(createParent){
            newCon.EmailOptInStatus__c = 'N';
            newCon.EmailOptInDate__c = Null;
        }
        
        if(createChild){ // NASSC-1199
            if(String.isNotBlank(sub.SourceSystem) && sub.SourceSystem.equalsIgnoreCase('Outside Lists')){
                List<String> emailOptinSubbrands  = new List<String>();
                if (String.isNotBlank(sub.EmailOptInForSubBrands))  emailOptinSubbrands = sub.EmailOptInForSubBrands.split('\\|');
                if((emailOptinSubbrands.size() > 0) && emailOptinSubbrands.contains(brandId)){
                    newCon.EmailOptInStatus__c = 'Y';
                    if(String.isNotBlank(sub.EmailSignupDate)) {
                        newCon.EmailOptInDate__c = UtilityClass.strYYYMMDDtoDateTime(sub.EmailSignupDate);
                    } else if(String.isNotBlank(sub.TransactionDate)) {
                        newCon.EmailOptInDate__c = UtilityClass.strYYYMMDDtoDateTime(sub.TransactionDate);
                    } else {
                        newCon.EmailOptInDate__c = System.Now();
                    }
                } else {
                    newCon.EmailOptInStatus__c = 'N';
                    newCon.EmailOptInDate__c = Null;
                }
                
            }

        }       
        
        return newCon;
    }
}