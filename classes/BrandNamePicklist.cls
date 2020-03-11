/**
* @author Magnet360
*
* @date 2019
*
* @description Class to Fetch Brand Names and show as Drop Down as Design Attribute
*				 This class is called from BrandForm Design Resource.
*				 Exctends DynamicPicklist - https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_VisualEditor_DynamicPickList.htm
*
*/
global class BrandNamePicklist extends VisualEditor.DynamicPickList{

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
    * @description Returns Brand picklist values for us in lightning aura components
    * @param paramName
    * @return DynamicPickListRows
    * @example
    */
    global override VisualEditor.DynamicPickListRows getValues() {
       
        String fieldName = 'Brand__c';
        VisualEditor.DynamicPickListRows  picklistValues = new VisualEditor.DynamicPickListRows();
        Map<String, Schema.SObjectField> currPageObjectfieldsMap = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();
        
        for(Schema.SObjectField field : currPageObjectfieldsMap.values())
        {
            Schema.DescribeFieldResult descField = field.getDescribe();
            if(String.ValueOf(descField.type)=='PICKLIST' && descField.getName()==fieldName)
            {
                List<Schema.PicklistEntry> valuesList = new List<Schema.PicklistEntry>();
                valuesList = descField.getPicklistValues();
                
                for(Schema.PicklistEntry value : valuesList)
                {
                    VisualEditor.DataRow dataRow = new VisualEditor.DataRow(value.getLabel(), value.getValue());
                    picklistValues.addRow(dataRow);
                }
                break;
            }
            
        }
        
        return picklistValues;
    }
}