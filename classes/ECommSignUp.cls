/* Json Request
*  {"brandId":"9","firstName":"John","lastName":"Doe","addressLine1":"123 Main Street","addressLine2":"","city":"Albany","state":"NY","zip":"14810","country":"US","emailAddress":"ajay@someEmail.com","phoneNumber":"5555555555","homePhoneNumber":"5555555555","mobilePhoneNumber":"5555555555","birthMonth":"03","birthDay":"06","birthYear":"1969","gender":"Male","location":"CO601","loyaltySignup":"true","emailOptIn":"true","smsOptIn":"true","SMSOptInFrequency":"","SourceSystem":"eComm","WelcomeSource":"1"}
*  https://instance.salesforce.com/services/apexrest/subscriber/SignUp
NASSC-1068,NASSC-1197,NASSC-1311 
*/

@RestResource(urlMapping='/subscriber/SignUp')
global without sharing class ECommSignUp {
    
    static Id emailRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Email').getRecordTypeId(); 
    
    global class EcomRequest{
        public String brandId;
        public String firstName; 
        public String lastName;
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state; 
        public String zip;
        public String country;
        public String emailAddress;
        public String phoneNumber;  
        public String homePhoneNumber;
        public String mobilePhoneNumber;  
        public String birthMonth;
        public String birthDay;
        public String birthYear; 
        public String gender;                          
        public String location;
        public String loyaltySignup;
        public String emailOptIn;
        public String smsOptIn;
        public String SMSOptInFrequency;
        public String SourceSystem;
        public String WelcomeSource;
    }
    
    global class ECommResponse{
        public String code;
        public String message;
        public String ContactId;
        public String LoyaltyId;
        public String ExistingCustomer;
        public String NewsLetterAlreadySignedUp;
        public String LoyaltyAlreadySignedUp;
    }
    
    @HttpPost
    global static ECommResponse doSignup(){
        
        List<Contact> profileUpdateContacts = new List<Contact>();
        Map<Id, Contact> oldContacts = new Map<Id, Contact>();
        List<Contact> newTopBrandContacts = new List<Contact>();
        List<Contact> newSubBrandContacts = new List<Contact>();
        Boolean createParent = false;
        List<SignUpActivity> signUpActivityList = new List<SignUpActivity>();
        List<ID> allContactID = new List<ID>();
       
        List<Contact> allContactList = new List<Contact>();
        Boolean existingCont = false;
        
        List<Contact> searchecdParentContactList = new List<Contact>();
        List<LoyaltySettings__mdt> subBrandloyalitySetting;
        Contact contact = new Contact();
        Date reqBDate;        
        List<Contact> contacts = new List<Contact>();        
        String FileName = 'ECommAPI';
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String requestData = req.requestBody.toString();
        EcomRequest ecomReq = (EcomRequest)json.deserialize(requestData, EcomRequest.class);
        ECommResponse ecomResponse = new ECommResponse();  
        System.debug('### ecomReq:'+ecomReq);
        
        // Brand id or email not present in request, return error message
        if(String.isEmpty(ecomReq.brandId) || String.isEmpty(ecomReq.emailAddress) || String.isBlank(ecomReq.brandId) ||  String.isBlank(ecomReq.emailAddress) ){
            res.statusCode = 400;
            ecomResponse.code = 'INVALID_QUERY';
            ecomResponse.message = 'Missing required parameters:  BrandId or email';
            System.debug('***ecomResponse: ' + ecomResponse);  //do not comment out this statement
            return ecomResponse;
        } else { //Brand id and email present in request            
            
            If(String.isNotBlank(ecomReq.birthYear) && String.isNotBlank(ecomReq.birthMonth) && 
               String.isNotBlank(ecomReq.birthDay) && String.valueOf(ecomReq.birthYear)!='' && 
               String.valueOf(ecomReq.birthMonth)!='' && String.valueOf(ecomReq.birthDay)!=''){
                   reqBDate = Date.newInstance(Integer.valueOf(ecomReq.birthYear), Integer.valueOf(ecomReq.birthMonth), Integer.valueOf(ecomReq.birthDay));
               } else { //if birthDay is null set it to 01, if birthYear is null set it to 1900,if birthMonth is null set BOD to null
                   if(String.valueOf(ecomReq.birthYear)=='' || String.isBlank(ecomReq.birthYear)) ecomReq.birthYear = '1900';
                   if(String.valueOf(ecomReq.birthDay)=='' || String.isBlank(ecomReq.birthDay)) ecomReq.birthDay = '01';
                   if(String.isBlank(ecomReq.birthMonth) || String.valueOf(ecomReq.birthMonth)=='' || Integer.valueOf(ecomReq.birthMonth) > 12) {
                       reqBDate = Null;
                   } else {
                       reqBDate = Date.newInstance(Integer.valueOf(ecomReq.birthYear), Integer.valueOf(ecomReq.birthMonth), Integer.valueOf(ecomReq.birthDay));     
                   } 
               }
            
            //Check for existing contact
            contacts = searchContacts(ecomReq.brandId,ecomReq.emailAddress,emailRecordTypeId);
            System.debug('### contacts' + contacts);
            if(contacts != NULL && contacts.size()>0) {
                contact = contacts[0];
            }
            
            LoyaltySettings__mdt loyaltySetting;
            List<LoyaltySettings__mdt> listLoyaltySettingList = [Select Id,BrandId__c,IsLoyaltyApplicable__c,Parent_Brand__c from LoyaltySettings__mdt where BrandId__c = :ecomReq.brandId ];
            if(listLoyaltySettingList.size()>0) loyaltySetting = listLoyaltySettingList[0];
            
            if(contacts.size()<1){
                //Contact not found
                //Is Top Level Brand
                if(loyaltySetting != null && String.isEmpty(loyaltySetting.Parent_Brand__c)){
                    newTopBrandContacts.add(createContact(ecomReq,reqBDate,loyaltySetting.Parent_Brand__c, createParent));
                    
                    //has subbrands and email optedin
                    if(String.isNotEmpty(ecomReq.emailOptIn) && Boolean.valueOf(ecomReq.emailOptIn) == true){
                        List<LoyaltySettings__mdt> subBrandsLoyaltySetting = [Select Id,BrandId__c,IsLoyaltyApplicable__c,Parent_Brand__c from LoyaltySettings__mdt where Parent_Brand__c  = :ecomReq.brandId ];
                        system.debug('### subBrandsLoyaltySetting '+ subBrandsLoyaltySetting);
                        if(subBrandsLoyaltySetting.size()>0){
                            //has subbrands
                            for(LoyaltySettings__mdt sb: subBrandsLoyaltySetting){                                
                                newSubBrandContacts.add(createContact(ecomReq,reqBDate,sb.BrandId__c, createParent));
                            } //system.debug('### newSubBrandContacts' +newSubBrandContacts);
                        }
                    }
                } else if(loyaltySetting != null && String.isNotEmpty(loyaltySetting.Parent_Brand__c)) {
                    //Not Top Level Brand 
                    //Does Parent Brand Contacts exists in DB
                    searchecdParentContactList = searchContacts(loyaltySetting.Parent_Brand__c,ecomReq.emailAddress,emailRecordTypeId);
                    System.debug('### searchecdParentContactList :'+searchecdParentContactList);
                    if(searchecdParentContactList.size()<1){
                        //Contact does not exist for Parent Brand(with Loyalty Flag = N and Email Status = N)
                        createParent = true;
                        Contact parentCon = createContact(ecomReq,reqBDate,loyaltySetting.Parent_Brand__c, createParent);
                        System.debug('### parentCon:'+parentCon);
                        // add to newTopBrandContacts
                        newTopBrandContacts.add(parentCon);
                        
                        //setup this sub brand contact with flags from req
                        createParent = false;
                        Contact subBrandCon = createContact(ecomReq,reqBDate,ecomReq.brandId, createParent);
                        System.debug('### subBrandCon:'+subBrandCon);
                        // add to newSubBrandContacts list
                        newSubBrandContacts.add(subBrandCon);                        
                    } else {
                        //Parent Brand contact record exist Create Contact record for sub Brand
                        Contact subBrandCon = createContact(ecomReq,reqBDate,ecomReq.brandId, createParent);
                        System.debug('### subBrandCon:'+subBrandCon);
                        // add to newSubBrandContacts list
                        newSubBrandContacts.add(subBrandCon);
                    } 
                }                
            } else { 
                //Contact Record found
                // add to profileUpdateContacts
                existingCont = true;
                oldContacts.put(contact.Id, contact.clone());
                profileUpdateContacts.add(updateContact(contact,ecomReq,reqBDate));
            }
                  
            if(profileUpdateContacts.size()>0) {
                Database.SaveResult[] srList = Database.update(profileUpdateContacts, false);
                ContactUtility.createErrorLogRecords(srList,profileUpdateContacts[0].Latest_Source__c,FileName);
                for(Contact con : profileUpdateContacts){
                    if(con.id!=null) allContactList.add(con);
                }
            }
            
            if(newTopBrandContacts.size()>0){
                Database.SaveResult[] srList = Database.insert(newTopBrandContacts, false);
                ContactUtility.createErrorLogRecords(srList,newTopBrandContacts[0].Latest_Source__c,FileName);
                for(Contact con : newTopBrandContacts){
                    if(con.id!=null) allContactList.add(con);
                }
                
            }
            
            if(newSubBrandContacts.size()>0){
				Database.SaveResult[] srList = Database.insert(newSubBrandContacts, false);
                ContactUtility.createErrorLogRecords(srList,newSubBrandContacts[0].Latest_Source__c,FileName);
                for(Contact con : newSubBrandContacts){
                    if(con.id!=null) allContactList.add(con);
                }
            } 
            
            for(Contact con: allContactList){
                allContactID.add(con.Id);
                signUpActivityList.add(SignUpActivity.signupActivity(con.Id, con.Latest_Source__c, con.Brand_Id__c));
            }
            
            if(signUpActivityList.size()>0) SignUpActivity.logSignUpActivity(signUpActivityList);			   
        }
        
        res.statusCode = 200;
        ecomResponse = returnResponse(existingCont, allContactID, ecomReq.brandId, oldContacts);
        System.debug('***ecomResponse: ' + ecomResponse);  //do not comment out this statement
        return ecomResponse;
    }
    
    //Set contact email preferences
    Static void setContactEmailOptin(Contact cont,Boolean emailOptInFlag){
        if (emailOptInFlag){
            cont.EmailOptInStatus__c = 'Y'; // true;
            cont.EmailOptInDate__c = System.now();
            cont.HasOptedOutOfEmail = false;
            cont.EmailOptOutDate__c = Null;
        } else {
            cont.EmailOptInStatus__c = 'N'; //false;
            cont.EmailOptInDate__c = Null;
            cont.HasOptedOutOfEmail = true;
            cont.EmailOptOutDate__c = System.now();
        }
    }

    //Search Contact record
    Static List<Contact> searchContacts(String brandId, String emails,Id emailRecordTypeId){
        
        System.debug('### Contact search Brand Id:'+brandId);
        System.debug('### Contact search emails: '+emails);
        System.debug('### Contact search emailRecordTypeId: '+emailRecordTypeId);
        List<Contact> searchedContactList =  [SELECT Id, FirstName, LastName, Brand_Id__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, 
                                              Phone, MobilePhone, MailingCountry, Email, HomePhone, Birthdate, HomeStore__c, AccountId,  
                                              LoyaltyID__c, Latest_Source__c, EmailOptInStatus__c, SMSOptinStatus__c, LoyaltyFlag__c, ReportsToId, Source_System__c,
                                              WelcomeSource__c,StoreOfCapture__c
                                              FROM Contact 
                                              WHERE RecordTypeId = :emailRecordTypeId AND Brand_Id__c =:brandId AND Email = :emails];
        
        return ((searchedContactList!=null)?searchedContactList:Null);
    }
    
    //Create New Contact record
    Static Contact createContact(EcomRequest ecomReq, Date reqBDate,String parentBrandId, Boolean createParent){
        
        Contact con = new Contact();

        con.RecordTypeId = emailRecordTypeId;
        con.Birthdate = reqBDate;
        if(String.isNotBlank(ecomReq.sourceSystem)) {
            con.Source_System__c = ecomReq.sourceSystem;
            con.Latest_Source__c = ecomReq.sourceSystem;
        }
        con.createdByMethod__c = 'API';
        con.Status__c = 'ACTIVE';     
        
        if(String.isNotEmpty(parentBrandId)){
            con.Brand_Id__c = parentBrandId;
        } else con.Brand_Id__c = ecomReq.brandId;
        
        if(String.isNotBlank(ecomReq.firstName)) con.FirstName = ecomReq.firstName;
        else if(String.isBlank(ecomReq.firstName) || String.valueOf(ecomReq.firstName) == '') con.firstName = 'Unknown';
        if(String.isNotBlank(ecomReq.lastName)){ con.LastName = ecomReq.lastName; }
        else if(String.isBlank(ecomReq.lastName) || String.valueOf(ecomReq.lastName) == '') con.LastName = 'Unknown';
        if(String.isNotBlank(ecomReq.addressLine1)) con.MailingStreet = ecomReq.addressLine1;
        if(String.isNotBlank(ecomReq.addressLine2)) con.MailingStreet += ' /\n/\r' + ecomReq.addressLine2;
        if(String.isNotBlank(ecomReq.city)) con.MailingCity = ecomReq.city;
        if(String.isNotBlank(ecomReq.state)) con.MailingState = ecomReq.state;
        if(String.isNotBlank(ecomReq.zip)) con.MailingPostalCode = ecomReq.zip;
        if(String.isNotBlank(ecomReq.country)) con.MailingCountry = ecomReq.country;
        if(String.isNotBlank(ecomReq.emailAddress)) con.Email = ecomReq.emailAddress;
        if(String.isNotBlank(ecomReq.phoneNumber)) con.Phone = ecomReq.phoneNumber;
        if(String.isNotBlank(ecomReq.homePhoneNumber)) con.HomePhone = ecomReq.homePhoneNumber;
        if(String.isNotBlank(ecomReq.MobilePhoneNumber)) con.MobilePhone = ecomReq.MobilePhoneNumber;
        if(String.isNotBlank(ecomReq.location)) con.HomeStore__c = ecomReq.location;
        if(String.isNotBlank(ecomReq.location)) con.StoreOfCapture__c = ecomReq.location;
        if(String.isNotBlank(ecomReq.WelcomeSource)) con.WelcomeSource__c = ecomReq.WelcomeSource;
        
        if(String.isNotBlank(ecomReq.emailOptIn) && Boolean.valueOf(ecomReq.emailOptIn) == true){            
            setContactEmailOptin(con,(createParent ? false : true));
        }
        if(String.isNotBlank(ecomReq.emailOptIn) && Boolean.valueOf(ecomReq.emailOptIn) == false){            
            setContactEmailOptin(con,(createParent ? false : false));
        }
        

        if(String.isNotBlank(ecomReq.loyaltySignup)) {
            if (Boolean.valueOf(ecomReq.loyaltySignup) == true) con.LoyaltyFlag__c = (createParent ? false : true);
            if (con.LoyaltyFlag__c) con.Loyalty_Optin_Date__c = System.now();
        }    
        return con;
    }
  
    //Update existing Contact details
    Static Contact updateContact(Contact cont, EcomRequest ecomR, Date reqBDate){
        String addressLine;
        cont.Status__c = 'ACTIVE';
        If(String.isNotBlank(ecomR.firstName) && (!ecomR.firstName.equals(cont.FirstName))) cont.FirstName = ecomR.firstName;
        If(String.isNotBlank(ecomR.lastName) && (!ecomR.lastName.equals(cont.LastName))) cont.LastName = ecomR.lastName;
        if(String.isNotBlank(ecomR.addressLine1)) addressLine = ecomR.addressLine1;
        if(String.isNotBlank(ecomR.addressLine2)) addressLine += ' \r\n' + ecomR.addressLine2;
        If(String.isNotBlank(addressLine) && (addressLine!=cont.MailingStreet)) cont.MailingStreet = addressLine ;
        If(String.isNotBlank(ecomR.city) && (!ecomR.city.equals(cont.MailingCity))) cont.MailingCity = ecomR.city;
        If(String.isNotBlank(ecomR.state) && (!ecomR.state.equals(cont.MailingState))) cont.MailingState = ecomR.state;
        If(String.isNotBlank(ecomR.zip) && (!ecomR.zip.equals(cont.MailingPostalCode))) cont.MailingPostalCode = ecomR.zip;
        If(String.isNotBlank(ecomR.country) && (!ecomR.country.equals(cont.MailingCountry))) cont.MailingCountry = ecomR.country;
        If(String.isNotBlank(ecomR.emailAddress) && (!ecomR.emailAddress.equals(cont.Email))) cont.Email = ecomR.emailAddress;
        If(String.isNotBlank(ecomR.phoneNumber) && (!ecomR.phoneNumber.equals(cont.Phone))) cont.Phone = ecomR.PhoneNumber;
        If(String.isNotBlank(ecomR.homePhoneNumber) && (!ecomR.homePhoneNumber.equals(cont.HomePhone))) cont.HomePhone = ecomR.homePhoneNumber;
        If(String.isNotBlank(ecomR.mobilePhoneNumber) && (!ecomR.mobilePhoneNumber.equals(cont.MobilePhone))) cont.MobilePhone = ecomR.mobilePhoneNumber;
        If(String.isNotBlank(ecomR.sourceSystem)) cont.Latest_Source__c  = ecomR.sourceSystem;
        If(String.isNotBlank(ecomR.location) && (!ecomR.location.equals(cont.HomeStore__c))) cont.HomeStore__c = ecomR.location;
        If(String.isNotBlank(ecomR.location) && (!ecomR.location.equals(cont.StoreOfCapture__c))) cont.StoreOfCapture__c = ecomR.location;
        If(String.isNotBlank(ecomR.WelcomeSource) && (!ecomR.WelcomeSource.equals(cont.WelcomeSource__c))) cont.WelcomeSource__c = ecomR.WelcomeSource;
        
        
        //Check for DOB in Request value and Contact value, if they differ update the Contact DOB, 
        //else check if Contact DOB is Blank update the DOB from Request value
        If(String.isNotBlank(String.valueOf(reqBDate)) && String.isNotBlank(String.valueOf(cont.Birthdate)) && (!reqBDate.isSameDay(cont.Birthdate))){ 
            cont.Birthdate = reqBDate;
        } else If (String.isNotBlank(String.valueOf(reqBDate)) && String.isBlank(String.valueOf(cont.Birthdate))){
            cont.Birthdate = reqBDate;
        } else If(reqBDate == NULL){
            cont.Birthdate = NULL;
        }    
        
        //If Request param 'EmailOptIn' is "true" and Contact.EmailOptinStatus__c is false:
        if(String.isNotBlank(ecomR.emailOptIn) && Boolean.valueOf(ecomR.emailOptIn) == true && cont.EmailOptInStatus__c != 'Y'){
            setContactEmailOptin(cont,true);
        } else if(String.isNotBlank(ecomR.emailOptIn) && Boolean.valueOf(ecomR.EmailOptIn) == false && cont.EmailOptInStatus__c != 'N') {
            // If Request param 'EmailOptIn' is "false" and Contact.EmailOptinStatus__c is true:
            setContactEmailOptin(cont,false);
        }              

        if(String.isNotBlank(ecomR.loyaltySignup)){
            if (Boolean.valueOf(ecomR.loyaltySignup) == true && cont.LoyaltyFlag__c == false){ 
				cont.LoyaltyFlag__c = true;
				cont.Loyalty_Optin_Date__c = System.now();
			}
            else if (Boolean.valueOf(ecomR.loyaltySignup) == false && cont.LoyaltyFlag__c == true) cont.LoyaltyFlag__c = false;
        }
        return cont;
    } 
 
    Static ECommResponse returnResponse(Boolean existingCont, List<Id> allContactID, String brandId, Map<Id, Contact> oldContacts){
        Contact contact;        
        ECommResponse ecomRes = new ECommResponse();
        
        System.debug('***allContactID = '+allContactID);
        System.debug('***Brand_Id__c = '+brandId);
        if(allContactID != null && allContactID.size()>0){
            contact = [SELECT Id, LoyaltyId__c,EmailOptInStatus__c,LoyaltyFlag__c FROM Contact WHERE Id IN :allContactID AND Brand_Id__c = :brandId  ];
                        
            if(existingCont){
                if(oldContacts.containsKey(contact.Id) && oldContacts.get(contact.Id).EmailOptInStatus__c == 'Y'){
                    ecomRes.NewsLetterAlreadySignedUp = 'true';
                } else{//removed check for N for NASSC-1197
                    ecomRes.NewsLetterAlreadySignedUp = 'false';
                }
            } else {
                ecomRes.NewsLetterAlreadySignedUp = 'false';
            }
            
            if(existingCont){
                if(oldContacts.containsKey(contact.Id) && oldContacts.get(contact.Id).LoyaltyFlag__c){
                    ecomRes.LoyaltyAlreadySignedUp = 'true';
                } else if(oldContacts.containsKey(contact.Id) && !oldContacts.get(contact.Id).LoyaltyFlag__c){
                    ecomRes.LoyaltyAlreadySignedUp = 'false';
                }            
            } else {
                ecomRes.LoyaltyAlreadySignedUp = 'false';
            }   
                    
            ecomRes.ContactId = contact.Id;
            ecomRes.LoyaltyId = contact.LoyaltyId__c;               
        }        
        
        ecomRes.code = 'OK';       
        ecomRes.ExistingCustomer = String.valueOf(existingCont);        
        
        return ecomRes;
    }
}