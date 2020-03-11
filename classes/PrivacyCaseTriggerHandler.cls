/**
* @author Magnet360
* @date 2019
*
* @group Case
* @group-content ../../ApexDocContent/Case.htm
*
* @description Privacy-specific case trigger handler. This class only runs once per
* Case DML where the CaseTriggerHandler may run multiple times. The primary reason for this
* class being separate is to ensure we do not send multiple automated emails.
*/
public class PrivacyCaseTriggerHandler {

    public static Boolean isFirstRun = True;
    /***********************************************************************************************
    * @description Primary method, called by CaseTrigger in
    * the AfterUpdate cycle of Insert and Update on case.
    * Determines if work is needed and calls the appropriate methods.
    */
    public static void sendEmailsIfNecessary() {
        List<Case> privacyCases = new List<Case>();
        List<Id> newCaseIds = new List<Id>();
        List<Id> parentIds = new List<Id>();
        List<Id> dataOwnerIds = new List<Id>();
        List<Case> unsubCases = new List<Case>();
        List<Case> newEmailPrivacyCases = new List<Case>();
        for (sObject sobjCase : Trigger.new) {
            Case cse = (Case)sobjCase;
            if (cse.RecordTypeId == Constants.dataOwnerCaseRecordTypeId || cse.RecordTypeId == Constants.privacyRecordTypeId) {
                privacyCases.add(cse);
            } else {
                if (
                    cse.Type == Constants.marketingCaseType &&
                    cse.Sub_Type__c == Constants.unsubscribeRequestSubType
                    ) {
                        System.debug('===adding unsub case' + cse);
                        unsubCases.add(cse);
                    }
                if (
                    cse.Type == Constants.privacyCaseType &&
                    cse.Sub_Type__c == Constants.privacyEmailSubType &&
                    cse.Status == Constants.newPrivacyStatus &&
                    Trigger.isUpdate
                    ) {
                        Case oldCase = (Case)Trigger.oldMap.get(cse.Id);
                        if (String.isNotBlank(cse.emailToAddress__c) && String.isBlank(oldCase.emailToAddress__c)) {
                            newEmailPrivacyCases.add(cse);
                        }
                    }
                continue;
            }
            if (cse.Sub_Type__c == Constants.dataOwnerRequestSubType) {
                System.debug('===dataOwnerCase');
                if (!parentIds.contains(cse.ParentId)) {
                    parentIds.add(cse.ParentId);
                }
                if (!dataOwnerIds.contains(cse.Data_Owner__c)) {
                    System.debug('===adding Data Owner Id ' + cse.Data_Owner__c);
                    dataOwnerIds.add(cse.Data_Owner__c);
                }
            } else {
                if (Trigger.isInsert) {
                    newCaseIds.add(cse.Id);
                }
            }
        }
        if (privacyCases.size() > 0) {
            if (newCaseIds.size() > 0) {
                ContactFuture.processNewPrivacyCases(newCaseIds);
            }
            sendPrivacyEmailsIfNeeded(privacyCases, parentIds, dataOwnerIds);
            if (Trigger.isUpdate) {
                createChildCasesIfNeeded(privacyCases);
            }
        }
        if (unsubCases.size() > 0) {
            processUnsubCases(unsubCases);
        }
        if (newEmailPrivacyCases.size() > 0) {
            processNewEmailPrivacyCases(newEmailPrivacyCases);
        }
    }

    /***********************************************************************************************
    * @description Handles sending autoresponse emails to inbound emails to privacy email
    * addresses.
    * @param newCases List of new Email Privacy cases to send autoresponse emails to
    */
    private static void processNewEmailPrivacyCases(List<Case> newCases) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        PrivacyEmailHandler emailHandler = new PrivacyEmailHandler();
        for (Case cse : newCases) {
            System.debug('===processing new email privacy case' + cse);
            List<Brand_Setting__mdt> brandSetting = [Select Privacy_Auto_Response_Email_Template__c From Brand_Setting__mdt Where Brand_Id__c = :cse.Brand__c];
            if (brandSetting.size() == 0) {
                continue;
            }
            
            Messaging.SingleEmailMessage email = emailHandler.createEmail(cse, brandSetting[0].Privacy_Auto_Response_Email_Template__c, cse.SuppliedEmail);
            if (email == null) {
                System.debug('===null email' + cse);
                continue;
            }
            System.debug('===sending email' + email);
            emailsToSend.add(email);
        }
        emailHandler.sendEmails(emailsToSend);
    }

    /***********************************************************************************************
    * @description Handles sending automated emails for unsub cases.
    * Verification and Case Closed emails
    * @param unsubCases List of unsub cases to send emails for.
    */
    private static void processUnsubCases(List<Case> unsubCases) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        PrivacyEmailHandler emailHandler = new PrivacyEmailHandler();
        for (Case cse : unsubCases) {
            System.debug('===processing unsub case' + cse);
            if (Trigger.isInsert && cse.Status == Constants.newPrivacyStatus) {
                Messaging.SingleEmailMessage email = emailHandler.createEmail(cse, Constants.U1UnsubscribeEmail, cse.SuppliedEmail);
                if (email == null) {
                    continue;
                }
                emailsToSend.add(email);
            } else if (cse.Status == Constants.resolved && Trigger.isUpdate) {
                Case oldCase = (Case)Trigger.oldMap.get(cse.Id);
                if (oldCase.status != Constants.resolved) {
                    if (cse.Resolution_Code__c == Constants.privacyResolvedNoResponse) {
                        Messaging.SingleEmailMessage email = emailHandler.createEmail(cse, Constants.U3UnsubscribeEmail, cse.SuppliedEmail);
                        if (email == null) {
                            continue;
                        }
                        emailsToSend.add(email);
                    } else if (cse.Resolution_Code__c == Constants.privacyResolvedRejectedRequest) {
                        Messaging.SingleEmailMessage email = emailHandler.createEmail(cse, Constants.U2UnsubscribeEmail, cse.SuppliedEmail);
                        if (email == null) {
                            continue;
                        }
                        emailsToSend.add(email);
                    }
                }
            }
        }
        emailHandler.sendEmails(emailsToSend);
    }

    /***********************************************************************************************
    * @description Determines if child cases should be created for the parent case that has
    * reached the appropriate stage. This is determined by type of case (deletion vs access) and 
    * whether the brand account has supplemental data owners. If new cases are needed, call an aync
    * method which handles that. If not, progress to the next appropriate stage.
    * @param cases parent cases to process
    */
    private static void createChildCasesIfNeeded(List<Case> cases) {
        List<Case> casesNeedingUpdate = new List<Case>();
        List<Account> accountsWithSupplementalDataOwners = [Select Name From Account Where Id In (Select AccountId From Contact Where RecordTypeId = :Constants.dataOwnerContactRecordTypeId And System_Type__c = :Constants.dataOwnerSupplemental)];
        List<String> accountNamesWithSupplemental = new List<String>();
        Map<String,String> brandValueMap = new Map<String,String>();
        List<Schema.Picklistentry> fieldResult = Case.Brand__c.getDescribe().getPicklistValues();
        for (Schema.Picklistentry ple: fieldResult) {
            brandValueMap.put(ple.getValue(), ple.getLabel());
        }
        for (Account a : accountsWithSupplementalDataOwners) {
            if (!accountNamesWithSupplemental.contains(a.Name)) {
                accountNamesWithSupplemental.add(a.Name);
            }
        }
        for(Case cse : cases) {
            Case oldCase = (Case)Trigger.oldMap.get(cse.Id);
            System.debug('===casecreatingifneeded' + cse);
            System.debug('===oldcasecreatingifneeded' + oldCase);
            if (
                cse.Type == Constants.privacyCaseType && 
                (cse.Sub_Type__c == Constants.accessRequestSubType || cse.Sub_Type__c == Constants.deletionRequestSubType) && 
                cse.Status == Constants.dataOwnersContacted &&
                oldCase.Status != Constants.dataOwnersContacted
            ) {
                if (cse.Perfect_Match_Found__c) {
                    if (cse.Sub_Type__c == Constants.accessRequestSubType && !accountNamesWithSupplemental.contains(brandValueMap.get(cse.Brand__c))) {
                        //CSR has all data for the brand already
                        Case newCase = new Case(Id=cse.Id);
                        newCase.Status = Constants.reviewResponseStatus;
                        casesNeedingUpdate.add(newCase);
                    } else {
                        //Need to contact data owners for deletion/additional info
                        ChildPrivacyCaseActionsHandler.createChildDataOwnerCases(cse.Id);
                    }
                } else {
                    if (!Constants.privacyNACountries.contains(cse.Country_of_Residence__c)) {
                        // No Match and no NA, resolve the case.
                        Case newCase = new Case(Id=cse.Id);
                        newCase.Status = Constants.resolved;
                        newCase.Resolution_Code__c = Constants.privacyResolvedNoDataFound;
                        casesNeedingUpdate.add(newCase);
                    } else {
                        if (accountNamesWithSupplemental.contains(brandValueMap.get(cse.Brand__c))) {
                            // In NA without a match, but need to see if supplemental owners have data on consumer
                            ChildPrivacyCaseActionsHandler.createChildDataOwnerCases(cse.Id);
                        } else {
                            // In NA, but no supplemental data owners to contact. resolve it.
                            Case newCase = new Case(Id=cse.Id);
                            newCase.Status = Constants.resolved;
                            newCase.Resolution_Code__c = Constants.privacyResolvedNoDataFound;
                            casesNeedingUpdate.add(newCase);
                        }
                    }

                }
            }
        }
        if (casesNeedingUpdate.size() > 0) {
            update casesNeedingUpdate;
        }
    }

    /***********************************************************************************************
    * @description Sends automated privacy emails. Processes access, delete, and data owner cases.
    * @param cases list of cases to process
    * @param parentIds List of parent case ids for data owner cases. (To limit SOQL)
    * @param dataOwnerIds List of data owner ids (contacts) associated with data owner cases.
    */
    private static void sendPrivacyEmailsIfNeeded(List<Case> cases, List<Id> parentIds, List<Id> dataOwnerIds) {
        Map<Id, String> dataOwnerEmailMap = new Map<Id, String>();
        Map<Id, Case> parentCasesMap = new Map<Id, Case>();
        Map<Id, List<String>> dataOwnerAddtionalEmailsMap = new Map<Id, List<String>>();
        if (parentIds.size() > 0) {
            List <Case> parentCases = [Select Id, Sub_Type__c From Case Where Id In :parentIds];
            for (Case parentCase : parentCases) {
                parentCasesMap.put(parentCase.Id, parentCase);
            }
        }
        System.debug('===data Owner Ids ' + dataOwnerIds);
        if (dataOwnerIds.size() > 0) {
            System.debug('===Searching for data owners');
            List<Contact> dataOwners= [Select Id, Email, Additional_Email_1__c, Additional_Email_2__c, Additional_Email_3__c, Additional_Email_4__c From Contact Where Id In :dataOwnerIds];
            System.debug('data Owners ' + dataOwners);
            for (Contact dataOwner : dataOwners) {
                List<String> additionalEmails = new List<String>();
                if (String.isNotBlank(dataOwner.Additional_Email_1__c)) additionalEmails.add(dataOwner.Additional_Email_1__c);
                if (String.isNotBlank(dataOwner.Additional_Email_2__c)) additionalEmails.add(dataOwner.Additional_Email_2__c);
                if (String.isNotBlank(dataOwner.Additional_Email_3__c)) additionalEmails.add(dataOwner.Additional_Email_3__c);
                if (String.isNotBlank(dataOwner.Additional_Email_4__c)) additionalEmails.add(dataOwner.Additional_Email_4__c);
                dataOwnerAddtionalEmailsMap.put(dataOwner.Id, additionalEmails);
                dataOwnerEmailMap.put(dataOwner.Id, dataOwner.Email);
            }
        }
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        PrivacyEmailHandler emailHandler = new PrivacyEmailHandler();
        for (Case cse : cases) {
            System.debug('sending emails for case maybe' + cse);
            System.debug('===case id ' + cse.Id);
            if (cse.Type != Constants.privacyCaseType ) {
                continue;
            }
            if (cse.Sub_Type__c == Constants.accessRequestSubType) {
                emailsToSend = processAccessCases(cse, emailsToSend, emailHandler);
            }
            if (cse.Sub_Type__c == Constants.dataOwnerRequestSubType && String.isNotBlank(cse.Id)) {
                emailsToSend = processDataOwnerCases(cse, emailsToSend, emailHandler, parentCasesMap, dataOwnerAddtionalEmailsMap, dataOwnerEmailMap);
            }
            if (cse.Sub_Type__c == Constants.deletionRequestSubType) {
                emailsToSend = processDeletionCase(cse, emailsToSend, emailHandler);
            }
            
        }
        if (emailsToSend.size() > 0) {
            emailHandler.sendEmails(emailsToSend);
        }
    }

    /***********************************************************************************************
    * @description Adds automated privacy access email to list of emails to be sent
    * @param cse access case to process
    * @param emailsToSend List of emails to be sent after processing all cases
    * @param emailHandler class that generates the email to send
    * @return emailsToSend with another email if one is created
    */
    private static List<Messaging.SingleEmailMessage> processAccessCases(Case cse, List<Messaging.SingleEmailMessage> emailsToSend, PrivacyEmailHandler emailHandler) {
        if (Trigger.isInsert) {
            Messaging.SingleEmailMessage email = emailHandler.createEmail(cse, Constants.A1RequestEmail);
            if (email == null) {
                return emailsToSend;
            }
            emailsToSend.add(email);
        } else if (Trigger.isUpdate) {
            Case oldCase = (Case)Trigger.oldMap.get(cse.Id);
            if (cse.Status == Constants.resolved && oldCase.Status != Constants.resolved) {
                System.debug('===AccessCase ' + cse.Resolution_Code__c);
                Messaging.SingleEmailMessage email;
                if (cse.Resolution_Code__c == Constants.privacyResolvedDataProvided) {
                    // NO AUTOMATED EMAIL, CSR MANUALLY SENDS
                } else if (cse.Resolution_Code__c == Constants.privacyResolvedRejectedRequest) {
                    email = emailHandler.createEmail(cse, Constants.A2RequestEmail);
                    if (email == null) {
                        return emailsToSend;
                    }
                    emailsToSend.add(email);
                } else if (cse.Resolution_Code__c == Constants.privacyResolvedNoResponse) {
                    email = emailHandler.createEmail(cse, Constants.A3RequestEmail);
                    if (email == null) {
                        return emailsToSend;
                    }
                    emailsToSend.add(email);
                } else if (cse.Resolution_Code__c == Constants.privacyResolvedStalled) {
                    email = emailHandler.createEmail(cse, Constants.A10RequestEmail);
                    if (email == null) {
                        return emailsToSend;
                    }
                    emailsToSend.add(email);
                } else if (cse.Resolution_Code__c == Constants.privacyResolvedNoDataFound) {
                    if (Constants.privacyNACountries.contains(cse.Country_of_Residence__c)) {
                        email = emailHandler.createEmail(cse, Constants.A7RequestEmail);
                        if (email == null) {
                            return emailsToSend;
                        }
                        emailsToSend.add(email);
                    } else {
                        email = emailHandler.createEmail(cse, Constants.A8RequestEmail);
                        if (email == null) {
                            return emailsToSend;
                        }
                        emailsToSend.add(email);
                    }
                }
            }
        }
        return emailsToSend;
        
    }

    /***********************************************************************************************
    * @description Adds automated privacy deletion email to list of emails to be sent
    * @param cse access case to process
    * @param emailsToSend List of emails to be sent after processing all cases
    * @param emailHandler class that generates the email to send
    * @return emailsToSend with another email if one is created
    */
    private static List<Messaging.SingleEmailMessage> processDeletionCase(Case cse, List<Messaging.SingleEmailMessage> emailsToSend, PrivacyEmailHandler emailHandler) {
        if (Trigger.isInsert) {
            Messaging.SingleEmailMessage email = emailHandler.createEmail(cse, Constants.D1RequestEmail);
            if (email == null) {
                return emailsToSend;
            }
            emailsToSend.add(email);
        } else if (Trigger.isUpdate) {
            System.debug('===DeletionCase ' + cse.Resolution_Code__c);
            Case oldCase = (Case)Trigger.oldMap.get(cse.Id);
            if (cse.Status == Constants.resolved && oldCase.Status != Constants.resolved) {
                Messaging.SingleEmailMessage email;
                if (cse.Resolution_Code__c == Constants.privacyResolvedDataDeleted) {
                    email = emailHandler.createEmail(cse, Constants.D4RequestEmail);
                    if (email == null) {
                        return emailsToSend;
                    }
                    emailsToSend.add(email);
                } else if (cse.Resolution_Code__c == Constants.privacyResolvedRejectedRequest) {
                    email = emailHandler.createEmail(cse, Constants.D7RequestEmail);
                    if (email == null) {
                        return emailsToSend;
                    }
                    emailsToSend.add(email);
                } else if (cse.Resolution_Code__c == Constants.privacyResolvedNoResponse) {
                    email = emailHandler.createEmail(cse, Constants.D8RequestEmail);
                    if (email == null) {
                        return emailsToSend;
                    }
                    emailsToSend.add(email);
                } else if (cse.Resolution_Code__c == Constants.privacyResolvedStalled) {
                    email = emailHandler.createEmail(cse, Constants.D10RequestEmail);
                    if (email == null) {
                        return emailsToSend;
                    }
                    emailsToSend.add(email);
                } else if (cse.Resolution_Code__c == Constants.privacyResolvedNoDataFound) {
                    if (Constants.privacyNACountries.contains(cse.Country_of_Residence__c)) {
                        email = emailHandler.createEmail(cse, Constants.D5RequestEmail);
                        if (email == null) {
                            return emailsToSend;
                        }
                        emailsToSend.add(email);
                    } else {
                        email = emailHandler.createEmail(cse, Constants.D9RequestEmail);
                        if (email == null) {
                            return emailsToSend;
                        }
                        emailsToSend.add(email);
                    }
                }
            }
        }
        return emailsToSend;
    }

    /***********************************************************************************************
    * @description Adds automated privacy data owner email to list of emails to be sent.
    * If case was resolved, also calls async method to check if parent case has had all
    * child cases resolved.
    * @param cse access case to process
    * @param emailsToSend List of emails to be sent after processing all cases
    * @param emailHandler class that generates the email to send
    * @param parentCasesMap map of parent id to parent case. (Bulkification)
    * @param dataOwnerAddtionalEmailsMap map of addtional data owner id to email address. (Bulkification)
    * dataOwnerEmailMap Map of data owner id to email address (Bulkification)
    * @return emailsToSend with another email if one is created
    */
    private static List<Messaging.SingleEmailMessage> processDataOwnerCases(Case cse, List<Messaging.SingleEmailMessage> emailsToSend, PrivacyEmailHandler emailHandler, Map<Id, Case> parentCasesMap, Map<Id, List<String>> dataOwnerAddtionalEmailsMap, Map<Id, String> dataOwnerEmailMap) {
        Case parentCase = parentCasesMap.get(cse.ParentId);
        if (Trigger.isInsert) {
            String emailTemplate;
            if (parentCase.Sub_Type__c == Constants.accessRequestSubType) {
                emailTemplate = Constants.A5RequestEmail;
            } else {
                emailTemplate = Constants.D3RequestEmail;
            }
            Messaging.SingleEmailMessage email = emailHandler.createEmail(cse, emailTemplate, dataOwnerEmailMap.get(cse.Data_Owner__c));
            if (email == null) {
                return emailsToSend;
            }
            List<String> additionalEmailAddresses = dataOwnerAddtionalEmailsMap.get(cse.Data_Owner__c);
            System.debug('===additional emails' + additionalEmailAddresses);
            if (additionalEmailAddresses.size() > 0) {
                email.setCcAddresses(additionalEmailAddresses);
                    
            }
            emailsToSend.add(email);
        }
        if (Trigger.isUpdate) {
            System.debug('===UPDATING DATA OWNER CASE' + cse);
            if(Constants.privacyCaseCompletedStatuses.contains(cse.Status)) {
                Case oldCase = (Case)Trigger.oldMap.get(cse.Id);
                if (!Constants.privacyCaseCompletedStatuses.contains(oldCase.Status)) {
                    ChildPrivacyCaseActionsHandler.handleChildCaseResolved(cse.Id, cse.parentId);
                }
            }
        }
        return emailsToSend;
    }
}