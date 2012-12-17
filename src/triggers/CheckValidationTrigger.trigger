/**
 Unit Test : TestSmartSheetSetting ( 95% )
 Trigger to do validation check, only one active records in the database
 */
trigger CheckValidationTrigger on SmartSheet_Setting__c (before insert, before update) {
	static boolean dejavu = false;
	
	if (dejavu) {
		return;
	} else {
		dejavu = true;
	}
	
	List<SmartSheet_Setting__c> newrecs = Trigger.new;
	
	boolean activeRecFound = false;
	SmartSheet_Setting__c foundRecord = null;
	// check if any of the added records has double active records
	for (SmartSheet_Setting__c rec : Trigger.new){
		if (rec.active__c && activeRecFound == true){
			rec.active__c.addError('Cannot have multiple active records, please fix the problems before continue!');			
		} else

		if (rec.active__c && activeRecFound == false){
			activeRecFound = true;
			foundRecord = rec;
		}
	}
	
	// check for the existing	
	if (activeRecFound && foundRecord != null){
		for (List<SmartSheet_Setting__c> recs : [select id, active__c from SmartSheet_Setting__c
												where active__c = true
												and id != :foundRecord.id]){
			for (SmartSheet_Setting__c rec : recs){
				if (rec.active__c){
					foundRecord.addError('Cannot have multiple active records, please fix the problems before continue!');
					break;
				}
			}											
		
		}
	}
}