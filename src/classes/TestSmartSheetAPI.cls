@isTest
private class TestSmartSheetAPI {
	static SmartSheet_Setting__c setting {get;set;}
	
	static {
		setting = new SmartSheet_Setting__c(name='setting-test', url__c='https://localhost', 
			active__c=true, username__c='user1@unittest.com', access_token__c='1234');
		insert(setting);
	}
	
	static testMethod void testSmartSheet(){
		SmartSheetAPI conn = new SmartSheetAPI();
		
		SmartSheetAPI.SheetObj result;
		
		SmartSheetAPI.HomeObj homeresult = conn.listHomes();
		system.assert(homeresult == null, 'should show null!');
		
		homeresult = new SmartSheetAPI.homeObj();
		homeresult.folders = new List<SmartSheetAPI.folderObj>();
		
		List<SmartSheetAPI.SheetObj> results = conn.listSheet();
		
		result = conn.getSheet('1234');
		system.assert(result == null, 'should return null');
		
		result = conn.createSheet('sheet-place', '1234123');
		system.assert(result == null, 'should return null');
		
		conn.createSheetInWorkspace('sheet-workspace', '1234', '12343');
		
		SmartSheetAPI.CellObj celldata = new SmartSheetAPI.CellObj();
		celldata.columnId = 80090;
		celldata.value = 'new value';
		conn.insertRow('12344', new List<SmartSheetAPI.CellObj>{celldata});	
	}
	
}