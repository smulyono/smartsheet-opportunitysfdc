/*
SmartSheet API class

Controls and interact with smartsheet api endpoint

Based on Documentation at : http://www.smartsheet.com/developers/api-documentation

*/
public with sharing class SmartSheetAPI {
	// Smartsheet connection setting, only picked up the active one
	public SmartSheet_Setting__c activeSetting {get;set;}
	
	// constructor, also prepare the smartsheet connections
	public SmartSheetAPI(){
		List<SmartSheet_Setting__c> ss_settings = [select id, name, access_token__c, active__c, url__c, username__c
												  from SmartSheet_Setting__c 
												  where active__c = true];
	    if (ss_settings.size() > 0){
	    		activeSetting = ss_settings[0];
	    } else {
	    		// shows some error
	    		activeSetting = null;
	    }
	}
	
	// retrieve homes object, where we could get the list of workspaces, folders and sheets
	public HomeObj listHomes(){
		String response = sendMessage(activeSetting.URL__c + '/home?include=templates', 'GET', '');
		if (response == null || response.trim().equals('')){
			return null;
		}
		try {
			HomeObj resp = (HomeObj)JSON.deserialize(response, HomeObj.class);
			if (resp != null){
				return resp;
			}
		}catch (JSONException ev){
			return null;
		}
		return null;
	}
	
	// retrieve all available sheets 
	// one benefit is that it will retrieve all sheets which under workspaces, folders without
	// having to traversing the home object
	public List<SheetObj> listSheet(){
		String response = sendMessage(activeSetting.URL__c + '/sheets', 'GET','');
		if (response == null || response.trim().equals('')){
			return null;
		}
		try {
			List<SheetObj> resp = (List<SheetObj>)JSON.deserialize(response, List<SheetObj>.class);
			if (resp != null){
				return resp;
			}
		}catch (JSONException ev){
			return null;
		}
		return null;
	}
	
	// create new sheet based on sheet or template id
	public SheetObj createSheet(String name, String idreference){
		// construct json
		String response = sendMessage(activeSetting.URL__c + '/sheets', 'POST', createSheetParameter(name, idreference));
		return revalidateReturnValue(response);
	}

	// create new sheet based on sheet or template id
	// also put them in the workspace based on workspace id being supplied
	public SheetObj createSheetInWorkspace(String name, String idreference, String workspaceId){
		String response = sendMessage(activeSetting.URL__c + '/workspace/' + workspaceId +'/sheets', 'POST', createSheetParameter(name, idreference));
		return revalidateReturnValue(response);
	}

	// retrieve singular sheet and all of their information
	public SheetObj getSheet(String sheetId){
		String response = sendMessage(activeSetting.URL__c + '/sheet/' + sheetId, 'GET', '');
		return revalidateReturnValue(response);
	}
	
	// to insert individual row to particular sheets
	// each row contains multiple cell and column, the parameter will
	// contains the data 
	public RowObj insertRow(String sheetId, List<CellObj> celldata){
		// construct json for column parameter
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('cells');
        gen.writeStartArray();
        for (CellObj cell : celldata){
        		gen.writeStartObject();
        		gen.writeNumberField('columnId', cell.columnId);
        		gen.writeStringField('value', cell.value);
        		gen.writeEndObject();
        }
        gen.writeEndArray();
		gen.writeEndObject();
		
		// receive connection from the endpoint
		String response = sendMessage(activeSetting.URL__c + '/sheet/' + sheetId + '/rows', 'POST', gen.getAsString());
		if (response == null || response.trim().equals('')){
			return null;
		}
		try {
			RowObj resp = (RowObj)JSON.deserialize(response, RowObj.class);
			if (resp != null){
				return resp;
			}
		}catch (JSONException ev){
			return null;
		}
		return null;
	}
	
	// standard json for parameter used in creating new sheets
	private String createSheetParameter(String name, String idreference){
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('name');
        gen.writeString(name);
        gen.writeFieldName('fromId');
        gen.writeString(idreference);
		gen.writeEndObject();
		return gen.getAsString();		
	}
	
	// this methods will be used to check the return value from
	// operation to create new sheet
	private SheetObj revalidateReturnValue(String response){
		if (response == null || response.trim().equals('')){
			return null;
		}
		try {
			SheetObj resp = (SheetObj)JSON.deserialize(response, SheetObj.class);
			if (resp != null){
				return resp;
			}
		}catch (JSONException ev){
			return null;
		}
		return null;
	}
	
    // Method to send HTTP message
    private String sendMessage(String url , String method, String body){
    	   Map<String, String> stdHeaders = new Map<String, String>();
    	   // adding the headers for authentication
    	   stdHeaders.put('Authorization', 'Bearer ' + activeSetting.Access_Token__c);
    	   stdHeaders.put('Assume-User', ActiveSetting.Username__c);
    	   if (method.equalsIgnoreCase('post')){
    	   		stdHeaders.put('Content-Type', 'application/json');
    	   }
    	   Httpresponse resp = sendCalloutUrl(url, method ,body, stdHeaders);
    	   if (resp.getStatusCode() != 200){
    	       	return 'ERROR';
    	   }
    	   return resp.getBody();
    }	
	
	// methods to sending the actual HTTPrequest to smartsheet api endpoint
    private HttpResponse sendCalloutUrl(String url, String method, String body, Map<String, String> headers){
        Http hp = new HTTP();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        for (String key : headers.keySet()){
        		req.setHeader(key, headers.get(key));
        }
        if (method.equalsIgnoreCase('post')){
	        req.setBody(body);
        }
        
        if (!Test.isRunningTest()){
            return hp.send(req);
        } else {
        	   Httpresponse newresp = new Httpresponse();
        	   newresp.setStatusCode(404);
        	   return newresp;
        }
    } 	
	
	
	// Several data type for output
	// only handles the one needed
	// combine with template for simplicity 
	// All datat types are constructed based on API documentation from SmartSheet
	public class SheetObj {
		public String id ;
		public String name ;
		public List<ColumnObj> columns;
		public String accessLevel;
		public String permalink ;
		public DateTime createdAt ;
		public DateTime modifiedAt ;
		public Long version ;
		public SheetObj(){}
	}
	
	public class ColumnObj {
		public Long id ;
		public Long index ;
		public String title ;
		public Boolean primary ;
		public String type ;
		public List<String> options ;
		public String symbol ;
		public ColumnObj(){}
	}
	
	public class RowObj {
		public Long id ;
		public Long sheetId ;
		public Long rowNumber ;
		public Long parentRowNumber ;
		public List<ColumnObj> columns ;
		public List<CellObj> cells ;
		public Datetime createdAt ;
		public Datetime modifiedAt ;
	}
	
	public Class CellObj {
		public String type ;
		public String value ;
		public Long columnId ;
		public Long rowId ;
		public String formula ;
	}
	
	public Class LinkObj {
		public String type ;
		public String url;
		public Long sheetId ;
		public Long columnId ;
		public Long rowId ;
	}
	public class FolderObj{
		public List<FolderObj> folders ;
		public String id ;
		public String name ;
		public List<SheetObj> reports ;
		public List<SheetObj> sheets ;
		public List<SheetObj> templates ;
	}
	
	// for simplicity only support folder, workspace, templates and sheets
	public class HomeObj {
		public List<SheetObj> sheets ;
		public LIst<FolderObj> folders ;
		public List<SheetObj> templates ;
		public List<SheetObj> workspaces ;
		public HomeObj(){}
	}
}