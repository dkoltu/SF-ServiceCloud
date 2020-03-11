@isTest
public class AgileOneTest {
    static Map<String, String> responseHeaders = new Map<String, String>();    
	@isTest
    public static void getC360DataTest(){
        Test.startTest();
        responseHeaders.put('Content-Type', 'application/json');
        SingleRequestMock fakeResponse = new SingleRequestMock(200,
                                                 'OK',
                                                 '{"customerIds":["C0021733313","0031U00000U7ZjxQAF","2019101706050100104305CK"]}',
                                                 responseHeaders);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);   
        AgileOne.getC360Data('C0021733313','2');
        Test.stopTest();
    }
    
    @isTest
    public static void getTrackerAPIAccesskeyTest(){
        Test.startTest();
        String brandId = '2';
        List<A1_TrackerAPI_creds__mdt> trackerCred = [select id,BrandId__c from A1_TrackerAPI_creds__mdt where BrandId__c=: brandId];
        AgileOne.getTrackerAPIAccesskey(trackerCred[0]);
        Test.stopTest();
    }
    @isTest
    public static void getRewardsDataTest(){
        Test.startTest();
        Reward__c rew = new Reward__c(TransactionId__c='TR101',Status__c='Redeemed',LoyaltyId__c='CK1235999',RewardType__c='33');
        insert rew;
        AgileOne.getRewardsData('CK1235999');
        Test.stopTest();
    }
    /*@isTest
    public static void parseresourceJSONTest(){
        Test.startTest();
        String response ='{"customerIds": ["C0021733313","0031U00000U7ZjxQAF","2019101706050100104305CK"],'+
    			'"{"displayResourceKey":\"$customerTransaction360\",\"resource\":\"transaction\",\"layout\":\"customer\"}": ['+
        		'{"rowKey": "\\x0E\\x00\\x00\\x0A\\xE1\\x90\\xD2\\x1C\\x94\\xD0s\\xF1I\\xD9\\xF1H",'+
            	'"values": [{"udmColumn": "transaction.c_transactionBarcode","value": "9990206050010043058"},'+
                '{"udmColumn": "transaction.TransactionTimestamp","value": "1571313600000"},{"udmColumn": "transaction.SourceTransactionNumber","value": "51632660"},'+
                '{"udmColumn": "transaction.Total","value": "64"},{"udmColumn": "transaction.Type","value": "Purchase"}],'+
            	'"children": [[{"udmColumn": "transactionitem.Subtype","value": "Shipped"},'+
                '{"udmColumn": "transactionitem.SaleRevenue","value": "28"},{"udmColumn": "product.Name","value": "BIKINI CUSTOMIZATION"},'+
                '{"udmColumn": "product.SourceProductNumber","value": "01153198702921"}{"udmColumn": "product.BrandName","value": "CK"},'+
                '{"udmColumn": "transactionitem.ShippingRevenue","value": null},{"udmColumn": "transactionitem.Discount","value": "0"}]]'+
            	'"ignore": false}'+
    			'],{"displayResourceKey":\"$customersummaryAttributes\",\"resource\":\"customersummary\",\"layout\":\"customer\"}: ['+
        		'{"rowKey": "\\x07\\x00\\x00\\x00\\x10\\xFF\\xFF\\xFF\\x00\\x00\\x00\\x00\\x00",'+
            	'"values": [{"udmColumn": "customersummary.c_balancePoints","value": "0"}, ],}]}';
        		AgileOne.parseresourceJSON(response);
        		Test.stopTest();
    }*/
}