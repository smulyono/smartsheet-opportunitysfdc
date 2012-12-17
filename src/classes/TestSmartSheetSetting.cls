@isTest
private class TestSmartSheetSetting {
	static SmartSheet_Setting__c setting {get;set;}
	
	static {
		setting = new SmartSheet_Setting__c(name='setting-test', url__c='https://localhost', 
			active__c=true, username__c='user1@unittest.com', access_token__c='1234');
		insert(setting);
	}

    static testMethod void testTrigger() {
    		List<SmartSheet_Setting__c> allrecs = [select id from SmartSheet_Setting__c];
    		system.assert(allrecs.size() == 1, 'other record found or initial record not inserted!');
    		SmartSheet_Setting__c newsetting = new SmartSheet_Setting__c(
			name='setting2-test', url__c='https://localhost', 
			active__c=true, username__c='user1@unittest.com', access_token__c ='1234'
    		);
    		// this should fail
    		try {
	    		insert(newsetting);
    		} catch (DMLException ev){
    			//
    		}
    		allrecs = [select id from SmartSheet_Setting__c];
    		system.assert(allrecs.size() == 1, 'new record been inserted although validation should blocked it');
    		
    		newsetting.active__c = false;
    		insert(newsetting);
    		allrecs = [select id from SmartSheet_Setting__c];
    		system.assert(allrecs.size() == 2, 'new record cannot been inserted although no validation should blocked it');
    		
    		List<SmartSheet_Setting__c> addedRecs = new List<SmartSheet_Setting__c>();
    		SmartSheet_Setting__c newsetting2 = new SmartSheet_Setting__c(
			name='setting3-test', url__c='https://localhost', 
			active__c=true, username__c='user1@unittest.com', access_token__c ='1234'
    		);
    		SmartSheet_Setting__c newsetting3 = new SmartSheet_Setting__c(
			name='setting4-test', url__c='https://localhost', 
			active__c=true, username__c='user1@unittest.com', access_token__c ='1234'
    		);
    		addedRecs.add(newsetting2);
    		addedRecs.add(newsetting3);
    		// test for bulk and should fail
    		try {
	    		insert(addedRecs);
    		} catch (DMLException ev){}
    		allrecs = [select id from SmartSheet_Setting__c];
    		system.assert(allrecs.size() == 2, 'new record  inserted although validation should blocked it');
    		
    }
}