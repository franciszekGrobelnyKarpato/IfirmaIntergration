public class PostResponseJSON2Apex {

	public class Response {
		public Integer Kod;
		public String Informacja;
		public Integer Identyfikator;		
	}

	public Response response;

	
	public static PostResponseJSON2Apex parse(String json) {
		return (PostResponseJSON2Apex) System.JSON.deserialize(json, PostResponseJSON2Apex.class);
	}
}