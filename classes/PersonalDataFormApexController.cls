/**
* @author Magnet360
*
* @date 2019
*
* @description Controller Class to show picklist values to Privacy Data Form and
*				 to create Case after form submission.
*/
public class PersonalDataFormApexController
{

    /*******************************************************************************************************
    * @description Method to fetch below field Values from Case Object and show it to Privacy Data Forms:
    * Country of Residence
    * State of Residence
    * Type of Request (Custom Metadata - Personal Data Request Setting)
    * @param objDetail - Case record as SObject
    * @param contrfieldApiName  - API name of Controlling Field
    * @param depfieldApiName - API Name of Dependent FIeld
    * @param brandNames -Brand Name
    * @param sourceCountry - Country US or CA
    * @return InitialDataWrapper
    */
    @AuraEnabled  
    public static InitialDataWrapper getDependentMap(sObject objDetail, string contrfieldApiName,string depfieldApiName,String brandNames,String sourceCountry) {
        InitialDataWrapper wrapperObj = new InitialDataWrapper();
        
        
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        
        Schema.sObjectType objType = objDetail.getSObjectType();
        if (objType==null){
            
            wrapperObj.mapCountryState = objResults;
        	return wrapperObj;
        	
        }
        
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
           wrapperObj.mapCountryState = objResults;
           return wrapperObj;
         
        }
        
        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
        
        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        //System.debug('***Controlling = '+contrEntries);
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        //System.debug('***Dependent = '+depEntries);
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry ple : contrEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }
        
        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    objResults.get(controllingValues.get(i)).add(label);
                }
            }
        }
        //System.debug('***Final Map = '+objResults);
        wrapperObj.mapCountryState = objResults;
        //System.debug('***Wrapper Obj = '+wrapperObj.mapCountryState);
        
        //Fetching Picklist values for field "Type of Request" from Custom Metadata.
        List<String> listType = new List<String>();
        // List<String> listBrands = new List<String>();
        Schema.sObjectType objTypeCase = Personal_Data_Request_Setting__mdt.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objTypeCase.getDescribe();
        
        map <String, Schema.SObjectField> typeMap = objDescribe.fields.getMap();
        list <Schema.PicklistEntry> values = typeMap.get('Type_of_Request__c').getDescribe().getPickListValues();
        for (Schema.PicklistEntry a: values) 
        {
            listType.add(a.getValue());
        }
        //System.debug('***Got Type = '+listType);
        String brandLabel = (sourceCountry == 'US')?brandNames:brandNames+' '+sourceCountry;
        system.debug('*** brandLabel '+brandLabel);
        //List<Success_Message_Setting__mdt> getMessage = [Select Id,Success_Message_f__c,Regards__c,	MasterLabel,Brand_Email__c from Success_Message_Setting__mdt Where Type__c='P' and Brand_Name__c=:brandNames and Country__c=:sourceCountry];
        List<Brand_Setting__mdt> getMessage = [Select Id, Privacy_Email__c, Brand_Phone__c, Privacy_Policy__c, Personal_Info_Link__c, MasterLabel from Brand_Setting__mdt where Brand_Id__c = :brandLabel];
        if(!getMessage.isEmpty())
        {
            //System.debug('$$$'+getMessage[0].MasterLabel);
            //System.debug('$$$'+getMessage[0].Brand_Email__c);
            //System.debug('***Got Configurd Message');
            wrapperObj.brand_label = getMessage[0].MasterLabel;
            wrapperObj.brand_email = getMessage[0].Privacy_Email__c;
            wrapperObj.brand_phone = getMessage[0].Brand_Phone__c;
            wrapperObj.brand_privacyPolicy = getMessage[0].Privacy_Policy__c;
            wrapperObj.brand_optOutInfo = getMessage[0].Personal_Info_Link__c;
        }

        wrapperObj.listTypeOfRequest = listType;
        system.debug('*** wrapperObj '+wrapperObj);
        return wrapperObj;
    }
    
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }
    
    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
    
    
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }
    
    public class PicklistEntryWrapper{
        public String active {get;set;}
        public String defaultValue {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){            
        }
        
    }
    
    public class InitialDataWrapper
    {   
        @AuraEnabled
        public Map<String, List<String>> mapCountryState {get;set;}
        @AuraEnabled
        public List<String> listTypeOfRequest {get;set;}
       
        @AuraEnabled
        public String brand_label {get;set;}
        @AuraEnabled
        public String brand_email {get;set;}
        @AuraEnabled
        public String brand_phone {get;set;}
        @AuraEnabled
        public String brand_optOutInfo {get;set;}
        @AuraEnabled
        public String brand_privacyPolicy {get;set;}

    }
    
    /* Method to create Case in Salesforce when Privacy Form is submitted and return:
     * WrapperObject with:
     * CaseNumber and 
     * Success Message (Custom Metadata - Success Message Setting)
     * Regards (Custom Metadata - Success Message Setting)
     */
    /*******************************************************************************************************
    * @description Method to create Case in Salesforce when Privacy Form is submitted and return:
    * WrapperObject with:
    * CaseNumber and
    * Success Message (Custom Metadata - Success Message Setting)
    * Regards (Custom Metadata - Success Message Setting)
    * @param getCaseDetail - Case record as SObject
    * @param name - Name of Customer
    * @param brandNames - Brand name
    * @param sourceCountry - Source Country US/CA
    * @return CaseWrapper -
    */
    @AuraEnabled
    public static CaseWrapper createCase(Case getCaseDetail,String name,String brandNames,String sourceCountry)
    {
        //System.debug('***inside createCase');
        CaseWrapper wrapperObj = new CaseWrapper();
        
        Id recordTypeIdPrivacyRequest = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Privacy_Request').getRecordTypeId();
        Id recordTypeIdSupportCase = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Support_Case').getRecordTypeId();
		String typeToSet;
        String subTypeToSet;
        String recordTyeToSet;
        Map<String,String> mapBrandNameLabel = new Map<String,String>();
        
        if(getCaseDetail.Type == 'Access My Data' || getCaseDetail.Type == 'Delete My Data')
        {
            //System.debug('***its Privacy');
            typeToSet = 'Privacy';
            subTypeToSet = getCaseDetail.Type;
            recordTyeToSet = recordTypeIdPrivacyRequest;
        }
        else if(getCaseDetail.Type == 'Unsubscribe')
        {
            //System.debug('***its Marketing');
            typeToSet = 'Marketing';
            subTypeToSet = getCaseDetail.Type;
            recordTyeToSet = recordTypeIdSupportCase;
            
        }
        //System.debug('***We got Brand Name = '+brandNames);
        
        
        //fetch brand name and brand label from custom setting to a map
        List<Brand_Name_Setting__mdt> listBrandNameLabel = [SELECT Id,Brand_Name__c,Brand_Label__c FROM Brand_Name_Setting__mdt];
        if(!listBrandNameLabel.isEmpty())
        {
        	for(Brand_Name_Setting__mdt singleRec : listBrandNameLabel)
            {
                mapBrandNameLabel.put(singleRec.Brand_Name__c,singleRec.Brand_Label__c);
            }
        }
        
        
        //call method to get API name of Brand:
        //String getAPINameBrand = getBrandAPIName(brandNames);
        //System.debug('***We got BrandAPIName = '+getAPINameBrand);
        Case newCases = new Case(Type=typeToSet, 
                                 Sub_Type__c=subTypeToSet, 
                                 Country_of_Residence__c=getCaseDetail.Country_of_Residence__c, 
                                 State_of_Residence__c=getCaseDetail.State_of_Residence__c,
                                 SuppliedName=name, SuppliedEmail=getCaseDetail.SuppliedEmail, 
                                 SuppliedPhone=getCaseDetail.SuppliedPhone,
                                 Loyalty_Account_Number__c=getCaseDetail.Loyalty_Account_Number__c,
                                 Brand__c = brandNames,
                                 Origin = 'Web',
                                 recordTypeId =recordTyeToSet,
                                 Brand_Label__c = mapBrandNameLabel.get(brandNames)
                                 );

        
        try {
            insert newCases;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        
        Case getCase = [Select Id,caseNumber from Case where Id =: newCases.Id];
        //System.debug('***Case inserted with Case Number = '+getCase.CaseNumber);
        List<Success_Message_Setting__mdt> getMessage = [Select Id,Success_Message_f__c,Regards__c from Success_Message_Setting__mdt Where Type__c='P' and Brand_Name__c=:brandNames and Type_of_Request__c=:getCaseDetail.Type and Country__c=:sourceCountry];
        if(!getMessage.isEmpty())
        {
            //System.debug('***Got Configurd Message');
            wrapperObj.message_success = getMessage[0].Success_Message_f__c;
            wrapperObj.regards_success = getMessage[0].Regards__c;
        }
        else
        {
             //System.debug('***No Configurd Message. Default Message is Set');
             wrapperObj.message_success='Thank you for submitting a Personal Data Request. Your case number is <b><ticketid></b>. We will contact you before we begin to process your request.';
             wrapperObj.regards_success='Support Team';
        }
        
        
        wrapperObj.caseNumber = getCase.CaseNumber;
        return wrapperObj;

      
    }
    
    /* NOT using this method 
    public static String getBrandAPIName(String brandNames)
    {
        Map<String,String> mapBrandLabelValue = new Map<String,String>();
        Schema.sObjectType objTypeCase = Case.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objTypeCase.getDescribe();
        map <String, Schema.SObjectField> typeMap = objDescribe.fields.getMap();
        list <Schema.PicklistEntry> brandValues = typeMap.get('Brand__c').getDescribe().getPickListValues();
        for (Schema.PicklistEntry ent: brandValues) 
        {
            mapBrandLabelValue.put(ent.getLabel(),ent.getValue());
        }
        //System.debug('***We got BrandMap = '+mapBrandLabelValue);
        String brandAPIName = mapBrandLabelValue.get(brandNames);
        return brandAPIName;
    }
    */
    
    public class CaseWrapper
    { 
        @AuraEnabled
        public String caseNumber {get;set;}
        @AuraEnabled
        public String message_success {get;set;}
        @AuraEnabled
        public String regards_success {get;set;}
       
    }

}