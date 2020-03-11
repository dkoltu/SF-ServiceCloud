/**
* @author Magnet360
*
* @date 2019
*
* @description Class to Fetch Case Source Country and show as Drop Down as Design Attribute
*				 This class is called from BrandForm Design Resource
*				 Exctends DynamicPicklist - https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_VisualEditor_DynamicPickList.htm
*
*/
global class CaseSourceCountryPicklist extends VisualEditor.DynamicPickList{
    /*******************************************************************************************************
    * @description Returns the default value for the brand picklist
    * @param none
    * @return DataRow - default value for picklist
    */
    global override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('None', 'None');
        return defaultValue;
    }
    /*******************************************************************************************************
    * @description Returns Case_Source_Country__c picklist values for us in lightning aura components
    * @param paramName
    * @return DynamicPickListRows
    * @example
    */
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DataRow defaultValue = getDefaultValue();
        
        List<String> listCaseSourceCountry = new List<String>();
        Schema.sObjectType objTypeCase = Case.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objTypeCase.getDescribe();
        map <String, Schema.SObjectField> typeMap = objDescribe.fields.getMap();
        list <Schema.PicklistEntry> countryValues = typeMap.get('Case_Source_Country__c').getDescribe().getPickListValues();
        for (Schema.PicklistEntry ent: countryValues) 
        {
            // listBrands.add(ent.getValue());
            listCaseSourceCountry.add(ent.getLabel());
        }
       	System.debug('***Got BrandList = '+listCaseSourceCountry);
        
        VisualEditor.DynamicPickListRows  countryNameList = new VisualEditor.DynamicPickListRows();
        for(String getValue : listCaseSourceCountry)
        {
            VisualEditor.DataRow CountryName = new VisualEditor.DataRow(getValue,getValue);
            countryNameList.addRow(CountryName);
        }
        System.debug('***brandNameList = '+countryNameList);
        return countryNameList;
    }
}