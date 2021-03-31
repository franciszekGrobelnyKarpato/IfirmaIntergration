public with sharing class AccountingMonthJSON2Apex {
    public class Response {
		public Integer RokKsiegowy;
		public Integer MiesiacKsiegowy;
	}

	public Response response;

	
	public static AccountingMonthJSON2Apex parse(String json) {
		return (AccountingMonthJSON2Apex) System.JSON.deserialize(json, AccountingMonthJSON2Apex.class);
	}
}