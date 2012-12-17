public with sharing class OppToSmartsheetController {
	// for easy filtering, use blank records to ask for input
	public Opportunity filterRec {get;set;}
	// holds the end date range
	public Date endDate {get;set;}
	public String strendDate {get;set;}
	
	public List<Selectoption> availableSheets {get;set;}
	public String selectedSheet {get;set;}

	public List<Selectoption> availableFolders {get;set;}
	public String selectedFolder {get;set;}

	public String newSheetName {get;set;}
	
	// only for export / append to existing sheets
	public List<Selectoption> availableToSheets {get;set;}
	public String selectedToSheet {get;set;}
	public String sheetLink {get;set;}
	
	public List<SelectOption> columnOptions {get;set;}

	// shows which filter is enabled
	public Boolean filterStage {get;set;}
	public Boolean filterProbability {get;set;}
	public Boolean filterCloseDate {get;set;}
	
	public boolean showMapping {get;set;}
	
	public List<Opportunity> resultRecords {get;set;}
	
	// configuration for smartsheet connection
	public SmartSheet_Setting__c ss_setting {get;set;}
	
	// the connection api to smart sheet
	private SmartSheetAPI conn;
	
	public Map<String, String> columnMapping {get;set;}
				
	public OppToSmartsheetController(){
		filterRec = new Opportunity();
		// initiate result records as empty list
		resultRecords = new List<Opportunity>();
		filterStage = true;
		filterProbability = filterCloseDate = false;
		
		strendDate = '';
		
		// 
		conn = new SmartSheetAPI();
		ss_setting = conn.activeSetting;
		
		initPage();
	}
	
	private void initPage(){
		availableSheets = new List<SelectOption>();
		availableToSheets = new List<SelectOption>();
		availableToSheets.add(new SelectOption('-','-- None --'));
		
		availableFolders = new List<SelectOption>();
		availableFolders.add(new SelectOption('-', '-- Root Folder --'));
		
		SmartSheetAPI.HomeObj homes = conn.listHomes();
		if (homes != null && homes.templates != null){
			for (SmartSheetAPI.SheetObj item : homes.templates){
				availableSheets.add(new SelectOption(item.id, 'Templates : ' + item.name));
			}
		}
		
		// Get all sheets from all folder and workspaces
		List<SmartSheetAPI.SheetObj> sheetreturns = conn.listSheet();
		if (sheetreturns != null){
			for (SmartSheetAPI.SheetObj item : sheetReturns){
				availableSheets.add(new SelectOption(item.id, 'Sheet : ' + item.name));
				availableToSheets.add(new SelectOption(item.id, 'Sheet : ' + item.name));
			}
		}
		
		// get the workspace too ( ONLY root folder)
		if (homes != null && homes.workspaces != null){
			for (SmartSheetAPI.SheetObj item : homes.workspaces){
				availableFolders.add(new SelectOption('W:' + item.id, 'Workspace : ' + item.name));
			}
		}
		
		// prepare / initialize for mapping
		columnMapping = new Map<String, String>();
		columnOptions = new List<SelectOption>();
		columnOptions.add(new SelectOption('ID', 'Probability ID'));
		columnOptions.add(new SelectOption('CloseDate', 'Close Date'));
		columnOptions.add(new SelectOption('Name', 'Opportunity Name'));
		columnOptions.add(new SelectOption('StageName', 'Stage Name'));
		columnOptions.add(new SelectOption('Probability', 'Probability'));
		
		showMapping = false;
		sheetLink = '';
	}
	
	public PageReference filterRecords(){
		String filterQuery = 'SELECT ID, CloseDate, Name, StageName, Probability FROM Opportunity';
		String conditionQuery = '';
		if (filterStage){
			if (conditionQuery.trim().length() > 0){
				conditionQuery += ' AND ';
			}
			String stageName = filterRec.stageName;
			conditionQuery += 'stageName=:stageName';
		}
		if (filterProbability){
			if (conditionQuery.trim().length() > 0){
				conditionQuery += ' AND ';
			}
			Decimal Probability = filterRec.Probability;
			conditionQuery +='probability=:Probability';
		}
		if (filterCloseDate){
			if (filterRec.closeDate != null){
				if (conditionQuery.trim().length() > 0){
					conditionQuery += ' AND ';
				}
				Date startDate = filterRec.closeDate;
				conditionQuery += 'closedate>=:startDate';
			}
			if (strEndDate != null && strEndDate.trim().length() > 0){
				// use date type
				endDate = Date.parse(strendDate);
				if (conditionQuery.trim().length() > 0){
					conditionQuery += ' AND ';
				}
				conditionQuery += 'closedate<=:endDate';
			}
		}
		
		if (ConditionQuery.trim().length() > 0){
			filterQuery += ' WHERE ' + conditionQuery;
		}
		
		resultRecords = Database.query(filterQuery);
 		return null;
	}
	
	public PageReference createNewSpreadsheet(){
		// find where to create the spreadsheet
		SmartSheetAPI.SheetObj retval = null;
		if (selectedFolder.equalsIgnoreCase('-')){
			retval = conn.createSheet(newSheetName, selectedSheet);
		} else if (selectedFolder != null && !selectedFolder.equals('')){
			if (selectedFolder.startsWith('W:')){
				String workspaceid = selectedFolder.removeStart('W:');
				retval = conn.createSheetInWorkspace(newSheetName, selectedSheet, workspaceId);
			}
		}
		if (retval != null){
	 		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'Sheet Created!'));
	 		initPage();
		} else {
	 		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Something wrong during creating spreadsheet in SmartSheet'));		
		}
		return null;
	}
	
	public PageReference populateSheetMetadata(){
		columnMapping = new Map<String, String>();
		showMapping = false;
		if (selectedToSheet != null || selectedToSheet.equals('-')){
			SmartSheetAPI.SheetObj retval = conn.getSheet(selectedToSheet);
			if (retval != null && retval.columns != null && retval.columns.size() > 0){
				sheetLink = retval.permalink;
				for (SmartSheetAPI.ColumnObj col : retval.columns){
					columnMapping.put(String.valueOf(col.id) + '-' + col.title, '');
					showMapping= true;
				}
			}
		} 
		return null;
	}
	
	public PageReference exportSpreadsheet(){
		if (columnMapping != null && !selectedToSheet.equals('-')){
			List<SmartSheetAPI.RowObj> rowsdata = new List<SmartSheetAPI.RowObj>();
			for (Opportunity transferrec : resultRecords){
				SmartSheetAPI.RowObj rowdata = new SmartSheetAPI.RowObj();
				rowdata.cells = new List<SmartSheetAPI.CellObj>();
				for (String key : columnMapping.keySet()){
					// get the first one before '-'
					String idnumber = key.split('-', 0)[0];
					if (transferrec.get(columnMapping.get(key)) != null ){
						SmartSheetAPI.CellObj celldatum = new SmartSheetAPI.CellObj();
						celldatum.columnId = Long.valueOf(idnumber);
						celldatum.value=String.valueOf(transferrec.get(columnMapping.get(key)));
						rowdata.cells.add(celldatum);
					}
				}
				rowsdata.add(rowdata);
			}
			if (rowsdata.size() > 0){
				// only able to send synch message of 10 times, so to avoid any error or limit
				boolean allsuccess = true;
				for (SmartSheetAPI.RowObj rowdata : rowsdata){
					if (Limits.getCallouts() < Limits.getLimitCallouts()){
						SmartSheetAPI.RowObj rowresult = conn.insertRow(selectedToSheet, rowdata.cells);
						if (rowresult == null){
							allsuccess = false;
					 		break;		
						}
					} else {
				 		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'Only first 10 records has been successfully sent!'));
				 		break;
					}
				}
				if (!allsuccess){
			 		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'There is something wrong during inserting data!'));
				} else {
			 		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'Row succesfully Inserted!'));
				}
			}
		} else {
	 		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Select sheet to export and the mapping first!'));
		}
		
		return null;
	}
}