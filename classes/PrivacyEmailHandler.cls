/**
* @author Magnet360
* @date 2019
*
* @group Case
* @group-content ../../ApexDocContent/Case.htm
*
* @description Generates Privacy Emails, sends and logs them.
*/
public class PrivacyEmailHandler {
    Map<String,String> brandValueMap = new Map<String,String>();
    Map<String, Id> templateNameToIdMap = new Map<String, Id>();
    Map<String, OrgWideEmailAddress> owaMap = new Map<String, OrgWideEmailAddress>();
    Map<Id, OrgWideEmailAddress> caseToOWAMap = new Map<Id, OrgWideEmailAddress>();
    String genericContactId;

    /***********************************************************************************************
    * @description Init method. Creates maps and performs soql queries to enable bulk use.
    */
    public PrivacyEmailHandler() {
        List<Schema.Picklistentry> fieldResult = Case.Brand__c.getDescribe().getPicklistValues();
        for (Schema.Picklistentry ple: fieldResult) {
            this.brandValueMap.put(ple.getValue(), ple.getLabel());
        }
        List<EmailTemplate> templates = [Select Id, Name from EmailTemplate limit 1000];
        for (EmailTemplate template : templates) {
            this.templateNameToIdMap.put(template.Name, template.Id);
        }
        List<OrgWideEmailAddress> owaList = [Select Id, DisplayName, Address From OrgWideEmailAddress limit 1000];
        for (OrgWideEmailAddress owa : owaList) {
            this.owaMap.put(owa.DisplayName, owa);
        }

        GenericRecords__c genericContactRecord = GenericRecords__c.getValues(Constants.privacyContactGenericRecordSettingName);
        this.genericContactId = genericContactRecord.recordId__c;

    }

    // THIS METHOD WAS BUILT ASSUMING ALL CASE EMAILS GO TO SUPPLIEDEMAIL.
    // CALL THE OTHER METHOD MOVING FORWARD AND BE EXPLICIT
    /***********************************************************************************************
    * @description DEPRECATED. This method assumes emails are always sent to case SuppliedEmail
    * Use the explicit method instead moving forward.
    * @param cse Privacy case for which to send the email
    * @param emailTemplateName Name of the email template to be used.
    * @return generated, but not sent, email
    */
    public Messaging.SingleEmailMessage createEmail(Case cse, String emailTemplateName) {
        Messaging.SingleEmailMessage mail = createEmail(cse, emailTemplateName, cse.SuppliedEmail);
        return mail;
    }

    /***********************************************************************************************
    * @description generates and returns a Privacy email to be sent.
    * @param cse Privacy case for which to send the email
    * @param emailTemplateName Name of the email template to be used.
    * @param emailAddress
    * @return generated, but not sent, email
    */
    public Messaging.SingleEmailMessage createEmail(Case cse, String emailTemplateName, String emailAddress) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        Id templateId = this.templateNameToIdMap.get(emailTemplateName);
        mail.setTemplateId(templateId);

        String brandName = this.brandValueMap.get(cse.Brand__c);
        OrgWideEmailAddress owa = this.owaMap.get(cse.Brand_Privacy_OWA_Name__c);
        if (owa == null) {
            // LOG THIS SOMEWHERE
            return null;
        }
        mail.setOrgWideEmailAddressId(owa.Id);
        this.caseToOWAMap.put(cse.Id, owa);

        mail.setToAddresses(new List<String>{emailAddress});
        mail.setSaveAsActivity(false);
        if (String.isNotBlank(cse.ContactId)) {
            mail.setTargetObjectId(cse.ContactId);
        } else {
            mail.setTargetObjectId(this.genericContactId);
        }
        
        mail.setWhatId(cse.Id);
        mail.setUseSignature(false);
        mail.setTreatTargetObjectAsRecipient(false);
        return mail;

    }

    /***********************************************************************************************
    * @description sends the emails and calls the method to log them.
    * @param emails List of emails to send and log
    */
    public void sendEmails(List<Messaging.SingleEmailMessage> emails) {
        Messaging.sendEmail(emails);
        this.logEmails(emails);
    }

    /***********************************************************************************************
    * @description Logs the email sends on the case
    * @param emails List of emails to send and log
    */
    private void logEmails(List<Messaging.SingleEmailMessage> emails) {
        List<EmailMessage> emailLog = new List<EmailMessage>();
        for (Messaging.SingleEmailMessage email : emails) {
            EmailMessage emailToLog = new EmailMessage();
            String toAsString='';
            Boolean check = false;
            for (String s : email.getToAddresses()) {
                if (check) toAsString += ',';           
                toAsString += s;
                check = true;
            }
            emailToLog.ToAddress = toAsString;
            emailToLog.Subject = email.getSubject();
            emailToLog.HtmlBody = email.getHtmlBody();
            emailToLog.Incoming = false;
            emailToLog.ParentId = email.getWhatId();
            emailToLog.MessageDate = System.now();
            emailToLog.FromAddress = this.caseToOWAMap.get(email.getWhatId()).Address;
            emailLog.add(emailToLog);
        }
        insert emailLog;

    }

}