/*
*  {"context":{"locale":"en_US","timezone":"PST8PDT","library":{"name":"analytics-java","version":"analytics/2.0.0-RC3"}},"integrations":{},"messageId":"52b3947f-23bc-4454-96e6-f33bcbf920ae","timestamp":"2018-08-08T14:29:33.795Z","traits":{"brand":"TH Store number 083","email":"YYZ@GMAIL.COM","emailExplicitOptinRequired":"false","emailOptin":"false","location":"TestLocation","serialNumber":"12345","site":"SiteName","smsExplicitOptinRequired":"false","smsOptin":"true","source":"ChargeItSpot","storeNumber":"1234"},"type":"identify","userId":"7785551212","writeKey":"somewritekey","receivedAt":"2018-08-08T14:29:37.795Z","sentAt":"2018-08-08T14:29:37.000Z","originalTimestamp":"2018-08-08T14:29:33+0000"}
* 
* Json request body sample from Segment.io
* {"messageId":"test-message-mkn7f6","timestamp":"2019-07-11T13:26:57.397Z","type":"identify","email":"test@example.org","projectId":"PWJdr2j1VW","traits":{"trait1":1,"trait2":"test","trait3":true},"userId":"test-user-wtg88h"}
* Note: For HMAC authentication json format changes the digest
* 
* Header
* X-Signature: 61438bde8f48b89b310aa972fd92d7831d2d70c7
* 
* https://instance.salesforce.com/services/apexrest/ChargeItSpot/SignUp

ChageItSpot request comes only for brand 1 (Tommy (TH))
* 	NASSC-1087
	NASSC-1138: Update ChageItSpot for brand parameter changes
	NASSC-1311 
*/

@RestResource(urlMapping='/ChargeItSpot/SignUp')
global without sharing class ChargeItSpotSignUp {
    static DateTime chargeItTimeStamp;
    static Id intOwnerId;


    global class ChargItReq{
        public context context;
        public integration integrations;
        public String messageId;
        public String timestamp;
        public trait traits;
        public String type;
        public String userId;  //represents SMS Phone number
        public String writeKey;
        public String receivedAt;
        public String sentAt;
        public String originalTimestamp;       
    }
    
    global class context{
        public String locale;
        public String timezone;
        public library library;
    }
    
    global class library{
        public String name;
        public String version;
    }
    
    global class integration{}
    
    global class trait{
        public String brand;
        public String email;
        public String emailExplicitOptinRequired;
        public String emailOptin;
        public String location;
        public String serialNumber;
        public String site;
        public String smsExplicitOptinRequired;
        public String smsOptin;
        public String source;
        public String storeNumber;
    }
    
    global class ChargeItResponse{
        public String code;
        public String message;
    }
    
    global static boolean authenticateRequest(RestRequest req){
        Boolean validRequester = false;
        
        string sharedSecret =  [SELECT Secret__c FROM SharedSecret__mdt WHERE DeveloperName = 'ChargeItSpot' LIMIT 1].Secret__c;
        system.debug('sharedSecret: ' + sharedSecret);
        
        String xsignature = req.headers.get('X-Signature');
        system.debug('*Request xsignature: ' + xsignature);
        
        if(xsignature != Null && String.isNotBlank(xsignature)){
            Blob digest = Crypto.generateMac('hmacSHA1', req.requestBody, Blob.valueOf(sharedSecret));   
            system.debug('digest hex: '+ EncodingUtil.convertToHex(digest));  
            if(EncodingUtil.convertToHex(digest) == xsignature) validRequester = true;
        } 
        return validRequester;    
    }    
    
    @HttpPost
    global static ChargeItResponse doSignUp(){
        Boolean authenticated = false;  
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        ChargeItResponse chargeItResponse = new ChargeItResponse();

        Contact SMSMatchedContact = new Contact();
        Contact emailMatchedContact = new Contact();
        Boolean smsAndEmailExactMatch = false;
        List<SignUpActivity> signUpActivityList = new List<SignUpActivity>();
        String brandId;
        Contact newContact;
        Contact toBeUpdatedContact;
        
        authenticated = authenticateRequest(req);
        
        if(authenticated){
            String requestData = req.requestBody.toString();
            ChargItReq chgItReq = (ChargItReq)json.deserialize(requestData, ChargItReq.class);
            
            // Brand, email or userId not present in request, return error message
            if(String.isBlank(chgItReq.traits.brand) || String.isBlank(chgItReq.traits.email) || String.isBlank(chgItReq.userId) || !SFMCUtility.validateEmail(chgItReq.traits.email))
            {
                res.statusCode = 400;
                chargeItResponse.code = 'MISSING_REQ_PARAMS';
                chargeItResponse.message = 'Missing brand/email/userId or invalid email';
                return chargeItResponse;
            }
            // if both emailOptin & smsOptin are missing, or if both are false, do nothing..
            else if ((String.isBlank(chgItReq.traits.emailOptin) && String.isBlank(chgItReq.traits.smsOptin)) && (!Boolean.valueOf(chgItReq.traits.emailOptin) && !Boolean.valueOf(chgItReq.traits.smsOptin)) )
            {
                // do nothing..

            }
            else { //all req params exist
                
                String[] reqBrandArray = chgItReq.traits.brand.split(' ');
                String reqBrand = reqBrandArray[0];
                System.debug('### reqBrand: ' + reqBrand);
                if (String.isBlank(chgItReq.timestamp)) chargeItTimeStamp = UtilityClass.strYYYMMDDtoDateTime(chgItReq.timestamp);

                List <User> IntegrationUsers = [SELECT Id FROM User WHERE Profile.Name='PVHIntegrationAPIUser' AND IsActive = true LIMIT 1];
                if (IntegrationUsers.size()>0) {
                    intOwnerId = IntegrationUsers[0].Id;
                }

                List<LoyaltySettings__mdt> listLoyaltySettingList = [Select Id,BrandId__c,IsLoyaltyApplicable__c,Parent_Brand__c, DeveloperName 
                                                                     FROM LoyaltySettings__mdt 
                                                                     WHERE DeveloperName  = :reqBrand ];
                if(listLoyaltySettingList.size()>0) {
                    

                    brandId = listLoyaltySettingList[0].BrandId__c;


                    SMSMatchedContact = SFMCUtility.searchSMSBrandContact(brandId,chgItReq.userId);
                    emailMatchedContact = SFMCUtility.searchEmailBrandContact(brandId, chgItReq.traits.email);
                    if (SMSMatchedContact!=null && SMSMatchedContact.Email!=null && SMSMatchedContact.Email==chgItReq.traits.email) smsAndEmailExactMatch = true;

                    if (!Boolean.valueOf(chgItReq.traits.smsOptin) && Boolean.valueOf(chgItReq.traits.emailOptin)) {

                        if (emailMatchedContact==null){
                            // create new contact with email, smsnumber, emailoptin, loyaltyopin

                        } else {
                            // update contact with SMS number, emailoptin, loyalty optin
                        }


                    } else if (Boolean.valueOf(chgItReq.traits.smsOptin)) {

                        if (smsAndEmailExactMatch) {
                            // reoptin#1  - update SMSMatchedContact with smsOptin = 'P', loyalty opin - callout

                        } else if (SMSMatchedContact==null && emailMatchedContact==null){
                            // optin#1 - create new contact with email, smsnumber, smsOptin='P', emailoptin, loyaltyopin - callout

                        } else if (SMSMatchedContact!=null && emailMatchedContact==null){
                            //only sms match found
                            if (SMSMatchedContact.Email==null){
                                // reoptin#5  - update SMSMatchedContact with Email, smsOptin = 'P', loyalty opin, emailOptin - callout
                            } else {
                                // reoptin#4A  - update SMSMatchedContact with  smsOptin = 'P', loyalty opin - callout

                                if (Boolean.valueOf(chgItReq.traits.emailOptin)) {
                                    // reoptin#4B - create new contact with email, emailoptin, loyaltyopin; accId & loyaltyId from smsMatchedContact
                                }

                            }

                        } else if (SMSMatchedContact==null && emailMatchedContact!=null){
                            //only email match found
                            // optin#2,3
                            if (emailMatchedContact.SMSNumber__c==null){
                                // optin#2 - update emailMatchedContact with SMSNumber, SMSOptin = 'P', loyalty flag, email optin -- callout




                            } else {
                                // optin#3
                                // create new contact with smsnumber, smsOptin = Y, loyaltyopin; accId & loyalty id from emailMatchedContact
                                newContact = createNewSMSOnlyContact(chgItReq, brandId);

                                if (Boolean.valueOf(chgItReq.traits.emailOptin)) {
                                    //update emailMatchedContact's loyalty optin & emailoptin
                                }

                            }

                        } else if (SMSMatchedContact!=null && emailMatchedContact!=null && !smsAndEmailExactMatch){
                                //separate sms and email matched contacts found
                                // reoptin#2, 3, 6, 7 - updated SMSMatchedContact smsOptin = 'P', loyalty -- callout
                                if (Boolean.valueOf(chgItReq.traits.emailOptin)) {
                                    //update emailMatchedContact's loyalty optin & emailoptin
                                }

                        }

                    }


  /**                  contacts = [SELECT Id, FirstName, LastName, Email, Brand_Id__c, Source_System__c, Latest_Source__c, StoreOfCapture__c, HomeStore__c, EmailOptInStatus__c, SMSOptinStatus__c, MobilePhone
                                FROM Contact 
                                WHERE Brand_Id__c =: BrandId AND Email =: chgItReq.traits.email LIMIT 1];
                    //Check for existing Contact information, if Present update it, else create New Contact
                    if(contacts.size()>0){ 
                        Contact updatedContact = updateContact(contacts[0],chgItReq);
                        signUpActivityList.add(SignUpActivity.signupActivity(updatedContact.Id, updatedContact.Latest_Source__c,updatedContact.Brand_Id__c));
                        res.statusCode = 200;
                        chargeItResponse.code = 'OK';
                        chargeItResponse.message = 'Success';
                    } else{
                        Contact createdContact = createContact(chgItReq, BrandId);
                        signUpActivityList.add(SignUpActivity.signupActivity(createdContact.Id, createdContact.Latest_Source__c,createdContact.Brand_Id__c));
                        res.statusCode = 200;
                        chargeItResponse.code = 'OK';
                        chargeItResponse.message = 'Success';
                    }
       **/

                    if(signUpActivityList.size()>0) SignUpActivity.logSignUpActivity(signUpActivityList);                    
                }
            }            
        } else { //Invalid Shared Secret key
            res.statusCode = 400;
            chargeItResponse.code = 'AUTHENTICATION_FAILED';
            chargeItResponse.message = 'Incorrect shared secret';
        }
        return chargeItResponse;
    }
    
    

    
    
    //Create Contact
    Static Contact createNewSMSOnlyContact(ChargItReq chgItReq, String brandId){

        Contact con = new Contact();

        if(intOwnerId!=null) con.OwnerId = intOwnerId;
        if(String.isNotBlank(chgItReq.traits.email)) con.Email = chgItReq.traits.email;
        con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Email').getRecordTypeId();

        con.Source_System__c = 'ChargeItSpot'; //chgItReq.traits.source;
        con.Latest_Source__c = 'ChargeItSpot'; //chgItReq.traits.source;


        con.Source__c = 'ChargeItSpot';
        con.Brand_Id__c = brandId;
        con.createdByMethod__c = 'API';
        if (chargeItTimeStamp!=null) con.PVHCreatedDate__c = chargeItTimeStamp;

        con.Status__c = 'ACTIVE';
        con.LastName = 'Unknown';   //LastName is set to 'Unknown'
        con.FirstName = 'Unknown';   //LastName is set to 'Unknown'
        if(String.isNotBlank(chgItReq.traits.storeNumber)) con.HomeStore__c = chgItReq.traits.storeNumber;
        if(String.isNotBlank(chgItReq.traits.storeNumber)) con.StoreOfCapture__c = chgItReq.traits.storeNumber;

        if(String.isNotBlank(chgItReq.userId)) con.MobilePhone = chgItReq.userId;
        if(String.isNotBlank(chgItReq.traits.smsOptin) && Boolean.valueOf(chgItReq.traits.smsOptin) == true){
            con.SMSOptinStatus__c = 'P'; //true;
            con.LoyaltyFlag__c = true;
            if (chargeItTimeStamp!=null) {
                con.SMSOptInDate__c = chargeItTimeStamp;
                con.Loyalty_Optin_Date__c = chargeItTimeStamp;
            }


        }


       return con;
       
    
    }

    public static Contact createNewSMSAndEmailContact(ChargItReq chgItReq, String brandId){
        Contact con = createNewSMSOnlyContact(chgItReq, brandId);
        con.Email = chgItReq.traits.email;

        if(String.isNotBlank(chgItReq.traits.emailOptIn) && Boolean.valueOf(chgItReq.traits.emailOptIn) == true){

            con.EmailOptInStatus__c = 'Y'; //true;
            if (!con.LoyaltyFlag__c) con.LoyaltyFlag__c = true;
            if (chargeItTimeStamp!=null) con.EmailOptInDate__c = chargeItTimeStamp;
        }
        return con;

    }
    
    //Set contact email preferences
    Static void setContactEmailOptin(Contact cont,Boolean emailOptInFlag){
        if (emailOptInFlag){ 
            cont.EmailOptInStatus__c = 'Y'; //true;
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
    
    
    //Set contact SMS preferences
    Static void setContactSMSOptin(Contact cont,Boolean smsOptInFlag){
        if (smsOptInFlag){ 
            cont.SMSOptinStatus__c = 'Y'; //true;
            cont.SMSOptInDate__c = System.now();
            cont.SMSOptOutDate__c = Null;
        } else {
            cont.SMSOptinStatus__c = 'N'; //false;
            cont.SMSOptInDate__c = Null;
            cont.SMSOptOutDate__c = System.now();
        }
    }
    

    
    
}