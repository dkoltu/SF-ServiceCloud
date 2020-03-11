<?xml version="1.0" encoding="utf-8"?><Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>To_Update_email_address</fullName>
        <field>Contact_Search_Email__c</field>
        <formula>Email</formula>
        <name>To Update email address</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Created_By_Method</fullName>
        <field>CreatedByMethod__c</field>
        <formula>'UI'</formula>
        <name>Update Created By Method</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set Created By Details</fullName>
        <actions>
            <name>Update_Created_By_Method</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.CreatedByMethod__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>To Display Email in Contact Search Lookup</fullName>
        <actions>
            <name>To_Update_email_address</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.LastName</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>To Display Email in Contact Search Lookup</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
