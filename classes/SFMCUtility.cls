/******************************************************************************
* @Description: Utility methods for SFMC & SMS related methods
* @Author     : 
* @Date       : 3 March
* @JIRA       : NASSC-1481/NASSC-1485/NASSC-1486
*
******************************************************************************/ 

global class SFMCUtility{
    public static integer countSFMCPostCall = 0;
    
    //method: POST to SFMC
    public static void postToSFMCQueueMOAPI(List <QueueMOData> QueueMODataList){
        QueueMOData QMOData = QueueMODataList[0];

        String KeywordType = QMOData.KeywordType;
        String BrandId = QMOData.BrandId;
        String SmsNumber = QMOData.SmsNumber;
        Id ContactId = QMOData.ContactId;
        String Email = QMOData.Email;

        String requestBody='';
        String keyword='';
        Integer countCalls=0;
        String cacheControl = 'no-cache';
        String requestEndPoint = 'callout:SFMC_QueueMOAPI/';
        
        List<LoyaltySettings__mdt> listLoyalty = [SELECT shortCode__c, chargeItKeyword__c, preferenceCenterKeyword__c, stopKeyword__c
                                                  FROM LoyaltySettings__mdt WHERE BrandId__c=:BrandId];
        
        if(KeywordType == 'chargeIt') keyword = listLoyalty[0].chargeItKeyword__c;
        if(KeywordType == 'preferenceCenter') keyword = listLoyalty[0].preferenceCenterKeyword__c;
        if(KeywordType == 'stop') keyword = listLoyalty[0].stopKeyword__c;
        
        
        if(KeywordType == 'chargeIt' || KeywordType == 'preferenceCenter'){
            requestBody='{"subscribers":[{ "mobilenumber": "'+SmsNumber+'", subscriberkey": "'+ContactId+'" }],"shortCode" : "'+listLoyalty[0].shortCode__c+'","messageText" : "'+keyword+''+ContactId+''+Email+''+BrandId+'"}';
        }
        else if(KeywordType == 'stop'){
            requestBody='{"subscribers":[{ "mobilenumber": "'+SmsNumber+'", subscriberkey": "'+ContactId+'" }],"shortCode" : "'+listLoyalty[0].shortCode__c+'","messageText" : "'+keyword+''+ContactId+'"}';
        }
        
        //getting access token
        String validAccessToken = getSFMCAccessToken();
        System.debug('*****get valid access token = '+validAccessToken);
        String authorization = 'Bearer '+validAccessToken;
        
        //SFMC Callout 1
        HttpResponse getResponse = doCalloutSFMC(requestEndPoint,'POST',requestBody,authorization,cacheControl);
        
        if(getResponse.getStatusCode() == 200) System.debug('*****Successfully POST SFMC Attempt 1');
        
        else if(getResponse.getStatusCode() == 401 || getResponse.getStatusCode() == 403){
            System.debug('*****Error 401 or 403 Posting SFMC');
            if(countSFMCPostCall == 1){
                validAccessToken = getSFMCAccessToken();
                authorization = 'Bearer '+validAccessToken;
                //SFMC Callout 2
                getResponse = doCalloutSFMC(requestEndPoint,'POST',requestBody,authorization,cacheControl);
                if(getResponse.getStatusCode() == 200) System.debug('*****Successfully POST SFMC Attempt 2');
                
                else if((getResponse.getStatusCode() == 401 || getResponse.getStatusCode() == 403) && countSFMCPostCall == 2){
                    createErrorLogs(String.valueOf(getResponse.getStatusCode()),getResponse.getBody());                    
                }                
            }
            else{
                createErrorLogs(String.valueOf(getResponse.getStatusCode()),getResponse.getBody());
            }
            
        }
        
    }
    
    //method: Return unexpired access token
    public static String getSFMCAccessToken()
    {   
        String accessToken = null;        
        List<SFMC_AccessTokens__mdt> tokenRecord = [SELECT Access_Token__c 
                                                    FROM SFMC_AccessTokens__mdt 
                                                    WHERE expires_at__c > :System.now()  LIMIT 1];
        if (tokenRecord.size()>0){
            accessToken = tokenRecord[0].access_token__c;
        } 
        
        else{
            List<SFMC_Credentials__mdt> listSFMCcreds = [SELECT client_id__c, client_secret__c, account_id__c from SFMC_Credentials__mdt LIMIT 1];
            String reqEndPoint  = Null;
            String returnAccessToken  = Null;
            
            //String reqBody = '{"grant_type":"client_credentials","client_id":"<client_id value>","client_secret":"<client_secret value>","account_id":"<account_id value>"}';
            String reqBody = '{"grant_type":"client_credentials","client_id":"'+listSFMCcreds[0].client_id__c+'","client_secret":"'+listSFMCcreds[0].client_secret__c+'","account_id":"'+listSFMCcreds[0].account_id__c+'"}';
            
            reqEndPoint='callout:SFMC_Auth_End_Point/';
            HttpResponse getRes = doCalloutForToken(reqEndPoint,'POST',reqBody);
            if(getRes != null){
                if(getRes.getStatusCode() == 200){
                    responseClass responseClassValue = (responseClass)JSON.deserialize(getRes.getBody(), responseClass.class);   
                    
                    //insert record into SFMC_Tokens_mdt 
                    CreateMetadataRecords.createSFMC_AccessTokens_mdtRecords(responseClassValue);                
                    
                    //assign token
                    accessToken = responseClassValue.access_token;
                }
                else if(String.valueOf(getRes.getStatusCode()).startsWith('4') ||  String.valueOf(getRes.getStatusCode()).startsWith('5')){
                    System.debug('*****ERROR - StatusCode = 4XX OR 5XX');
                    //insert record into Error Log                    
                    createErrorLogs(String.valueOf(getRes.getStatusCode()),getRes.getBody());
                    accessToken=null;
                }
                
            }
            
        }
        
        return accessToken;
    }
    
    //method: Callout for Access Token
    private static HttpResponse doCalloutForToken(String requestEP, String calloutMethod,String inputBody){
        System.debug('*****inside doCalloutForToken()');
        String responseString = Null;
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(requestEP);
        req.setMethod(calloutMethod);
        req.setBody(inputBody);
        Http http = new Http();
        try{
            res = http.send(req);
            responseString = res.getBody();
            System.debug('*****Response Body = '+responseString);
            System.debug('*****Status Code = '+res.getStatusCode());
            
        }catch(System.CalloutException e) {
            System.debug('Callout error: '+ e);
        }
        return res;
    }
    
    //Wrapper class to collect token response
    public class responseClass{
        public String access_token; 
        public Integer expires_in;  
    }
    
    //method: POST callout to SFMC 
    private static HttpResponse doCalloutSFMC(String requestEP, String calloutMethod,String inputBody, String auth, String cacheControl){
        System.debug('*****inside doCalloutSFMC()');
        countSFMCPostCall = countSFMCPostCall + 1;
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', auth);
        req.setHeader('Cache-Control', cacheControl);
        req.setEndpoint(requestEP);
        req.setMethod(calloutMethod);
        req.setBody(inputBody);
        Http http = new Http();
        try{
            res = http.send(req);
            System.debug('*****Status Code = '+res.getStatusCode());
            
        }catch(System.CalloutException e) {
            System.debug('Callout error: '+ e);
        }
        return res;
    }
    
    //method: create logs in ErrorLog__c object
    public static void createErrorLogs(String message, String stackTrace){
        ErrorLog__c logObject = new ErrorLog__c();
        logObject.SourceSystem__c = 'SFSC to SFMC';
        logObject.FileName__c = 'SFMC Auth API call';
        logObject.Message__c = message;
        logObject.StackTrace__c = stackTrace;
        
        try{
            insert logObject;
        }
        catch(Exception e){
            System.debug('Exception has occurred while inserting in ErrorLog Object: ' + e.getMessage());
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


    public class QueueMOData {

        @InvocableVariable
        public String KeywordType;
        @InvocableVariable
        public String BrandId;
        @InvocableVariable
        public String SmsNumber;
        @InvocableVariable
        public Id ContactId;
        @InvocableVariable
        public String Email;
    }


    @InvocableMethod(label='invocable QueueMOAPI' description='pass thru method to call QueueMOAPI')
    public static void invocableQueueMOAPI(List<QueueMOData> QueueMODataList) {

        postToSFMCQueueMOAPI(QueueMODataList);
    }
    
    //method: 
    public static Contact searchSMSBrandContact(String brandId,String SMSNumber){

        List <Contact> conList = [SELECT id, Brand_Id__c, Email, SMSNumber__c, AccountId, StoreOfCapture__c, CountryOfCapture__c,
                LoyaltyID__c, LoyaltyFlag__c, SMSOptinStatus__c, Loyalty_Optin_Date__c, SMSOptInDate__c, Source_System__c, Latest_Source__c
        FROM CONTACT
               WHERE Brand_Id__c=:brandId AND SMSNumber__c=:SMSNumber limit 1];

        if (conList.size()>0) return conList[0];
        else return null;
    }
    
    //method:
    public static Contact searchEmailBrandContact(String brandId,String EmailAddress){

        List <Contact> conList = [SELECT id, Brand_Id__c, Email, SMSNumber__c, AccountId, StoreOfCapture__c, CountryOfCapture__c,
                LoyaltyID__c, LoyaltyFlag__c, SMSOptinStatus__c, Loyalty_Optin_Date__c, SMSOptInDate__c, Source_System__c, Latest_Source__c
               FROM CONTACT 
               WHERE Brand_Id__c=:brandId AND Email=:EmailAddress limit 1];

        if (conList.size()>0) return conList[0];
        else return null;
    }

    public static Id getSiblingAccountId(String brandId,String EmailAddress){

        List <Contact> conList = [SELECT id, AccountId
        FROM CONTACT
        WHERE Email=:EmailAddress AND Brand_Id__c!=:brandId AND AccountId!=null AND Account.Name != 'Dummy Parent Account' limit 1];

        if (conList.size()>0) return conList[0].AccountId;
        else return null;
    }

    //Email validation function
    public static Boolean validateEmail(string emailString){
        System.debug(Pattern.matches('([a-zA-Z0-9_\\-\\.]+)@(((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3}))','emailString'));
        return Pattern.matches('([a-zA-Z0-9_\\-\\.]+)@(((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3}))',emailString);
    }
   
    
}