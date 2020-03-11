/*  Class: BatchCloseResolvedCase
 *  Description : Batch class to update Case with Status = Resoved to Status = Closed as per the No of Days specified
 *  in the Custom label "GeneralCase_ClosedDays" & "PrivacyCase_ClosedDays" for Privacy and Non Privacy cases.
 */

global class BatchCloseResolvedCase implements Database.Batchable <sObject>{
    Integer GenericCaseClosedDays = Integer.valueOf(System.Label.GeneralCase_ClosedDays);
    //Integer PrivacyCaseClosedDays = Integer.valueOf(System.Label.PrivacyCase_ClosedDays);
    public transient Map<String,Schema.RecordTypeInfo> RecordTypes = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
    //Id PrivacyRecordId = RecordTypes.get('Privacy_Request').getRecordTypeId();
    //Id PrivacyReadOnlyRecordId = RecordTypes.get('Privacy_Request_Read_Only').getRecordTypeId();
    Id SupportRecordId = RecordTypes.get('Support_Case').getRecordTypeId();
    Id SupportReadOnlyRecordId = RecordTypes.get('Support_Case_Read_Only').getRecordTypeId();
    //Id SupportEcommerceId = RecordTypes.get('Support_Case_E_commerce').getRecordTypeId();
    //Id SupportEcommerceReadOnlyId = RecordTypes.get('Support_Case_E_commerce_Read_Only').getRecordTypeId();
    //Id SupportRetailStoreId = RecordTypes.get('Support_Case_Retail_Store').getRecordTypeId();
    //Id SupportRetailStoreReadOnlyId = RecordTypes.get('Support_Case_Retail_Store_Read_Only').getRecordTypeId();
    //Id SupportInternalId = RecordTypes.get('Internal_Email').getRecordTypeId();
    //Id SupportInternalReadOnlyId = RecordTypes.get('Support_Internal_Email_Read_Only').getRecordTypeId();
    //Id SupportTrueNCoId = RecordTypes.get('Support_True_and_Co').getRecordTypeId();
    //Id SupportTrueNCoReadOnlyId = RecordTypes.get('Support_True_and_Co_Read_Only').getRecordTypeId();
    //Id SupportWholesaleId = RecordTypes.get('Support_Wholesale').getRecordTypeId();
    //Id SupportWholesaleReadOnlyId = RecordTypes.get('Support_Wholesale_Read_Only').getRecordTypeId();
    
    String QueryString = Null;
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        //System.debug('GenericCaseClosedDays: '+GenericCaseClosedDays);
        //System.debug('PrivacyCaseClosedDays: '+PrivacyCaseClosedDays);    
        
        QueryString = 'SELECT Id, Status, Type, RecordTypeId, LastModifiedDate, CreatedDate, ClosedDate FROM Case ' + 
            'WHERE Status = \'Resolved\'';
        System.debug('QueryString: '+ QueryString);
        return Database.getQueryLocator(QueryString);
    }
    
    global void execute(Database.BatchableContext bc, List<Case> records){
        if(Test.isRunningTest()){
            GenericCaseClosedDays = 0;
        }
        List<Case> caseList = new List<Case>();
        //System.debug('records: '+records);
        //System.debug('records size: '+records.size());
        for(Case c: records){
            if(c.RecordTypeId == SupportRecordId){
                /*System.debug('>>>Privacy Record Check');
                //System.debug('c.LastModifiedDate:'+c.LastModifiedDate);
                //System.debug('c.LastModifiedDate.addDays(PrivacyCaseClosedDays):'+c.LastModifiedDate.addDays(PrivacyCaseClosedDays));
                if(c.LastModifiedDate.addDays(PrivacyCaseClosedDays) < System.now()){
                    System.debug('>>>Privacy Record Closed');
                    c.Status = 'Closed';
                    c.RecordTypeId = PrivacyReadOnlyRecordId;
                    caseList.add(c);
                }
            } else {*/
                System.debug('>>>Not Privacy Record Check');
                //System.debug('c.LastModifiedDate:'+c.LastModifiedDate);
                //System.debug('c.LastModifiedDate.addDays(GenericCaseClosedDays):'+ c.LastModifiedDate.addDays(GenericCaseClosedDays));
                if(c.LastModifiedDate.addDays(GenericCaseClosedDays) < System.now()){
                    System.debug('>>>Not Privacy Record Closed');
                    if(c.RecordTypeId == SupportRecordId){
                        System.debug('>>>Support Record');
                        c.Status = 'Closed';
                        c.RecordTypeId = SupportReadOnlyRecordId;
                    }
                    /**else if(c.RecordTypeId == SupportEcommerceId){
                        System.debug('>>>SupportEcommerce Record');
                        c.Status = 'Closed';
                        c.RecordTypeId = SupportEcommerceReadOnlyId;
                    }
                    else if(c.RecordTypeId == SupportRetailStoreId){
                        System.debug('>>>SupportRetailStore Record');
                        c.Status = 'Closed';
                        c.RecordTypeId = SupportRetailStoreReadOnlyId;
                    }
                    else if(c.RecordTypeId == SupportInternalId){
                        System.debug('>>>SupportInternal Record');
                        c.Status = 'Closed';
                        c.RecordTypeId = SupportInternalReadOnlyId;
                    }
                    else if(c.RecordTypeId == SupportTrueNCoId){
                        System.debug('>>>SupportTrueNCo Record');
                        c.Status = 'Closed';
                        c.RecordTypeId = SupportTrueNCoReadOnlyId;
                    }
                    else if(c.RecordTypeId == SupportWholesaleId){
                        System.debug('>>>SupportTrueNCo Record');
                        c.Status = 'Closed';
                        c.RecordTypeId = SupportWholesaleReadOnlyId;
                    }**/
                    caseList.add(c);
                }
            }
        }
        System.debug('Caselist size: '+caseList.size());
        
        if(caseList.size()>0){
            List<Database.SaveResult> results = Database.update(caseList, false);
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()){
                    for (Database.Error err : result.getErrors()){
                        System.debug('Error: '+ err.getStatusCode() + ' ' + err.getMessage());
                    }
                }
            }
        }      
    }
    global void finish(Database.BatchableContext bc){
        
    }
}