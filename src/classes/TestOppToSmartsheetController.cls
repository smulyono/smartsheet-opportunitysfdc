@isTest
private class TestOppToSmartsheetController {
	static SmartSheet_Setting__c setting ;
	static Opportunity newopp;
	
	static {
		setting = new SmartSheet_Setting__c(name='setting-test', url__c='https://localhost', 
			active__c=true, username__c='user1@unittest.com', access_token__c='1234');
		insert(setting);
		
		newopp = new Opportunity(
			name='test-opportunity',
			closedate= Date.today(),
			stagename= 'test-stage',
			probability=0.25
		);
		insert(newopp);
	}

    static testMethod void testPage() {
    		OppToSmartSheetController opc = new OppToSmartSheetController();
		List<Opportunity> allopps  = [select id from Opportunity];
		system.assert(allopps.size() == 1, 'initial opportunity not exists!');
		
		opc.filterProbability = true;
		opc.filterRec.Probability = 0.25;
		
		opc.filterCloseDate = true;
		opc.filterRec.CloseDate = Date.Today();		    		
    		opc.filterRecords();
    		
    		opc.selectedToSheet='1234';
    		opc.populateSheetMetadata();
		
		opc.newSheetName='new-sheet';
		opc.selectedSheet='9001';
		opc.selectedFolder = '-'; // do it in  root folder
    		opc.createNewSpreadsheet();

		opc.selectedFolder = 'W:12345'; // do it inside workspace
    		opc.createNewSpreadsheet();

    		opc.selectedToSheet='12344';
    		opc.resultRecords = [SELECT ID, CloseDate, Name, StageName, Probability FROM Opportunity];
    		opc.exportSpreadsheet();
    		
    }
}