/**
* @author Magnet360
*
* @date 2019
*
* @description Collection of utility methods
*
*/
public without sharing class utilityClass {

	/*******************************************************************************************************
	* @description Converts a timestamp in ISO8601 format to a Date/Time object
	* @param iso8601_ts timestamp in ISO8601 format
	* @return DateTime converted Date value
	*/
    public static DateTime convertISO8601(String iso8601_ts)
    {
        DateTime dt = (DateTime) JSON.deserialize(
                                    '"' + iso8601_ts + '"', DateTime.class);
        return DateTime.newInstance( dt.getTime());                            
    }

	/*******************************************************************************************************
	* @description Converts a date string in YYYYMMDD format to a Salesforce Date
	* @param strDate Date as string
	* @return Date value
	* @example
	*/
    public static Date strYYYMMDDtoDate(String strDate){
	    //TODO this should verify that the string is the correct length.
		if(String.isBlank(strDate)) {
			return null;
		}
		if(strDate.contains('T')) {
			return Datetime.valueOf(strDate.replace('T',' ')).date();
		}
        Integer year, month, day;
        year = Integer.valueOf(strDate.left(4));
        month = Integer.valueOf(strDate.substring(4,6));
        day = Integer.valueOf(strDate.right(2));

        Date dtime = Date.newInstance(Integer.valueOf(year), Integer.valueOf(month), Integer.valueOf(day));
        return dtime;

    }

	/*******************************************************************************************************
	* @description Converts a date string in YYYYMMDD format to a Salesforce DateTime
	* @param strDateTime Datetime as String
	* @return DateTime value
	*/
	public static DateTime strYYYMMDDtoDateTime(String strDateTime){
		
		if(strDateTime.contains('T')) {
			return convertISO8601(strDateTime);
		}
		else if (strDateTime.length()==8) {

			Integer year, month, day;
			year = Integer.valueOf(strDateTime.left(4));
			month = Integer.valueOf(strDateTime.substring(4,6));
			day = Integer.valueOf(strDateTime.right(2));

			DateTime dtime = DateTime.newInstance(Integer.valueOf(year), Integer.valueOf(month), Integer.valueOf(day));
			System.debug('**'+dtime);
			return dtime;
		}
		else return system.now();

	}

	/*******************************************************************************************************
	* @description Method to return a random string with a length as inputed
	* @param len length of string to return
	* @return random string of values
	*/
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr ='';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }

	/*******************************************************************************************************
	* @description Checks to see if a TriggerFactoryOverride is enabled for the user/profile and class. If
	* exists will prevent the trigger from running
	* @param className class to check if enabled for user
	* @return Boolean true if the class is enabled to be run False and the trigger will be skipped
	*/
	public static Boolean triggerEnabled(String className){
		List<Profile> usersProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
		if(usersProfile.size() == 0) {
			return true;
		}
		String myProfileName = usersProfile[0].Name;
		List<String> metadataKeys = new List<String>();
		metadataKeys.add(myProfileName + '|' + className); //Profile & Trigger combo override
		metadataKeys.add('*|' + className); //Trigger level override
		metadataKeys.add(myProfileName + '|*'); //Profile level override
		metadataKeys.add('*|*'); //Global override

		//We only need to find one match that has Disable checked to skip the trigger
		List<TriggerFactoryOverride__mdt> tfo =
			[SELECT DisableTrigger__c 
			FROM TriggerFactoryOverride__mdt 
			WHERE ProfileTrigger__c = :metadataKeys AND DisableTrigger__c = true 
			LIMIT 1];


		if (tfo.size() > 0) {
			 System.debug('Skip trigger execution because override found in TriggerFactoryOverride__mdt');
			 return false;
		}
		return true;

	}

	public static Boolean triggerEnabled(Type classType) {
		return triggerEnabled(classType.getName());
	}


 

}