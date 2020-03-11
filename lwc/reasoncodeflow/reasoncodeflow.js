/**
 * Created by dimitrisavelieff on 2020-01-22.
 */

import {LightningElement, track, api, wire} from 'lwc';
import CASE_OBJECT from '@salesforce/schema/Case';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import getSingleCase from '@salesforce/apex/ReasonCodeFlowController.getSingleCase';

//const CASE_FIELDS = ['Case.Id', 'Case.Status', 'Case.Reason_Code__c', 'Case.Reason_Code_Details__c', 'Case.Reason_Sub_Detail__c'];

export default class ReasonCodeFlow extends LightningElement {
    @api recordId;
    @wire(getSingleCase,{caseId : '$recordId'}) caseRecord;
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT }) caseInfo;
    @track brandOptions = [];
    @track reasonCodeOptions = [];
    @track reasonCodeOptionsBG = [];
    @track reasonCodeDetailOptions = [];
    @track reasonCodeSubDetailOptions = [];
    @track caseWrapper = {fields:{}};
    @track fieldVisibility = {};
    @track error;
    @track val;
    casePicklistValues;
    @wire(getPicklistValuesByRecordType, { objectApiName: CASE_OBJECT, recordTypeId: '$caseRecord.data.RecordTypeId'})
    gettingPicklistValues({error, data}) {
        if(data) {
            this.setWrapperFields();
            this.casePicklistValues = data;
            this.setReasonCodes();
            console.log(JSON.stringify(data.picklistFieldValues['Reason_Sub_detail__c']));
        }
        else if(error) {
            console.log(JSON.stringify(error));
        }
    }
    renderedCallback() {
    }

    setWrapperFields() {
        this.caseWrapper.fields.Id = this.caseRecord.data.Id;
        this.caseWrapper.fields.Status = this.caseRecord.data.Status;
        this.caseWrapper.fields.Reason_Code__c = this.caseRecord.data.Reason_Code__c;
        this.caseWrapper.fields.Reason_Code_Details__c = this.caseRecord.data.Reason_Code_Details__c;
        this.caseWrapper.fields.Reason_Sub_detail__c = this.caseRecord.data.Reason_Sub_detail__c;
        this.caseWrapper.fields.RecordTypeId = this.caseRecord.data.RecordTypeId;
        this.setVisibility();
    }
    setVisibility(){
        this.fieldVisibility.SubDetails = false;
    }

    setReasonCodes() {
        this.reasonCodeOptions = [{label:'--None--', value:null}];
        this.casePicklistValues.picklistFieldValues.Reason_Code__c.values.forEach(key => {
            this.reasonCodeOptions.push({
                label : key.label,
                value: key.value
            })
            this.reasonCodeOptionsBG.push({
                label : key.label,
                value: key.value
            })
        });
        this.setReasonCodeDetail();


    }
    setReasonCodeDetail() {
        if(!this.caseWrapper.fields.Reason_Code__c || this.caseWrapper.fields.Reason_Code__c == null    ) {
            this.caseWrapper.fields.Reason_Code_Details__c = null;
            this.caseWrapper.fields.Reason_Sub_detail__c = null;
            this.reasonCodeDetailOptions = [];
        } else {
            this.reasonCodeDetailOptions = [];
            this.setPicklistValues(this.caseWrapper.fields.Reason_Code__c, 'Reason_Code_Details__c',this.reasonCodeDetailOptions,this.casePicklistValues);
        }
        this.setReasonCodeSubDetail();
    }

    setReasonCodeSubDetail() {
        console.log('SettingSubDetail');
        console.log(this.caseWrapper.fields.Reason_Code_Details__c);
        if(!this.caseWrapper.fields.Reason_Code_Details__c || this.caseWrapper.fields.Reason_Code_Details__c == null) {
            this.fieldVisibility.SubDetails = false;
            this.caseWrapper.fields.Reason_Sub_detail__c = null;
            this.reasonCodeSubDetailOptions = [];
        } else {
            this.reasonCodeSubDetailOptions = [];
            this.setPicklistValues(this.caseWrapper.fields.Reason_Code_Details__c, 'Reason_Sub_detail__c',this.reasonCodeSubDetailOptions,this.casePicklistValues);
            if(this.reasonCodeSubDetailOptions.length > 1){
                this.fieldVisibility.SubDetails = true;
            } else {
                this.caseWrapper.fields.Reason_Sub_detail__c = null;
                this.reasonCodeSubDetailOptions = [];
                this.fieldVisibility.SubDetails = false;
            }
        }
    }

    handleSetReasonCode(event) {
        this.caseWrapper.fields.Reason_Code__c = event.detail.value;
        this.caseWrapper.fields.Reason_Code_Details__c = null;
        this.caseWrapper.fields.Reason_Sub_detail__c = null;
        this.reasonCodeDetailOptions = [];
        this.reasonCodeSubDetailOptions = [];
        this.setReasonCodeDetail();
    }

    handleSetReasonDetail(event) {
        this.caseWrapper.fields.Reason_Code_Details__c = event.detail.value;
        this.caseWrapper.fields.Reason_Sub_detail__c = null;
        this.reasonCodeSubDetailOptions = [];
        this.setReasonCodeSubDetail();
    }

    setPicklistValues(controllingFieldValue, dependentPicklist, optionsArray, picklistValues) {
        console.log('Setting Picklist');
        var controlNum = picklistValues.picklistFieldValues[dependentPicklist].controllerValues[controllingFieldValue];
        console.log(controlNum);
        optionsArray.push({label:'--None--', value:null});
        picklistValues.picklistFieldValues[dependentPicklist].values.forEach(key => {
            //console.log(JSON.stringify(key.validFor));
            if(key.validFor.includes(controlNum)){
                console.log('Adding Value');
                optionsArray.push({
                    label : key.label,
                    value: key.value
                })
            }
        });

    }



}