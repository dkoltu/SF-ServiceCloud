/**
 * Created by bryananderson on 2019-09-09.
 */

public with sharing class pvhPrechatUISnapinController {

    @AuraEnabled
    public static EmbeddedServiceDetail getEmbeddedServiceDetailRecord(String dId) {
        system.debug('dId@@@ ' + dId);

        EmbeddedServiceDetail esdRecord;

        if (String.isNotEmpty(dId)) {
            List<LiveChatDeployment> lcdList = [SELECT DeveloperName,Id FROM LiveChatDeployment WHERE Id = :dId LIMIT 1];
            if (lcdList.size() > 0) {
                String developerName = lcdList[0].DeveloperName;
                system.debug('developerName@@@ ' + developerName);
                if (developerName != null) {
                    esdRecord = [SELECT AvatarImg,DurableId,HeaderBackgroundImg,OfflineCaseBackgroundImg,PrechatBackgroundImg,PrimaryColor,SecondaryColor,SmallCompanyLogoImg,WaitingStateBackgroundImg FROM EmbeddedServiceDetail WHERE DurableId = :developerName LIMIT 1][0];
                    system.debug('esdRecord@@@ ' + esdRecord);
                }
            }
        }

        return esdRecord;
    }
}