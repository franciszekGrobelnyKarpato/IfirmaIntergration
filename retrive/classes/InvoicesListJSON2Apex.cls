public class InvoicesListJSON2Apex {

	public class Response {
		public String KontrahentNazwa;
		public Integer KontrahentId;
		public String DataWystawienia;
		public String PelnyNumer;
		public Double Brutto;
	}

	public List<Response> response;

	
	public static InvoicesListJSON2Apex parse(String json) {
		return (InvoicesListJSON2Apex) System.JSON.deserialize(json, InvoicesListJSON2Apex.class);
	}
}