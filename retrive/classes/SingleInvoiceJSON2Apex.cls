public with sharing class SingleInvoiceJSON2Apex {

	public class Response {		
		public Double Zaplacono;
		public Double ZaplaconoNaDokumencie;
		public String LiczOd;
		public String NumerKontaBankowego;
		public String IdentyfikatorKontrahenta;
		public String PrefiksUEKontrahenta;
		public String NIPKontrahenta;
		public String DataWystawienia;
		public String MiejsceWystawienia;
		public String DataSprzedazy;
		public String FormatDatySprzedazy;
		public String TerminPlatnosci;
		public String SposobZaplaty;
		public String NazwaSeriiNumeracji;
		public String NazwaSzablonu;
		public String RodzajPodpisuOdbiorcy;
		public String PodpisOdbiorcy;
		public String PodpisWystawcy;
		public String Uwagi;
		public Boolean WidocznyNumerGios;
		public Integer Numer;
		public List<Pozycje> Pozycje;
		public Kontrahent Kontrahent;
		public String PelnyNumer;
		public Boolean WidocznyNumerBdo;
		public String WpisDoKpir;
		public Boolean SplitPayment;
		public String Waluta;		
		public Double KursWalutyZDniaWystawieniaFaktury;
		public Double KursWalutyZDniaPoprzedzajacegoDzienWystawieniaFaktury;
		public String Jezyk;
		public String DataObowiazkuPodatkowego;
		public String NazwaUslugi;
		public ProceduryJpk ProceduryJpk;
	}

	public Response response;

	public class Kontrahent {
		public String Nazwa;
		public String Nazwa2;
		public String Identyfikator;
		public String PrefiksUE;
		public String NIP;
		public String Ulica;
		public String KodPocztowy;
		public String Kraj;
		public String Miejscowosc;
		public String Email;
		public String Telefon;
		public Boolean OsobaFizyczna;
		public Boolean ZgodaNaEfaktury;
		public String DataUdzieleniaZgody;
		public String EmailDlaFaktury;
		public Boolean JestDostawca;
		public Boolean JestOdbiorca;
		public Boolean AdresZagraniczny;
		public String OdbiorcaNaFakturze;
		public String Skype;
		public String Faks;
		public String Uwagi;
		public String Www;
		public String NazwaBanku;
		public String NumerKonta;
		public String DrugiTelefon;
		public String AdresKorespondencyjnyUlica;
		public String AdresKorespondencyjnyKodPocztowy;
		public String AdresKorespondencyjnyKraj;
		public String AdresKorespondencyjnyMiejscowosc;
		public Boolean PodmiotPowiazany;
	}

	public class ProceduryJpk {
		public Boolean SW;
		public Boolean EE;
		public Boolean TP;
		public Boolean TT_WNT;
		public Boolean TT_D;
		public Boolean MR_T;
		public Boolean MR_UZ;
		public Boolean I_42;
		public Boolean I_63;
		public Boolean BSPV;
		public Boolean BSPVDostawa;
		public Boolean BMPVProwizja;
		public Boolean MPP;
	}

	public class Pozycje {
		public Integer Id;
		public Double StawkaVat;
		public Integer Ilosc;
		public Double CenaJednostkowa;
		public String NazwaPelna;
		public String NazwaPelnaObca;
		public String Jednostka;
		public String JednostkaObca;
		public String PKWiU;
		public String PodstawaPrawna;
		public String TypStawkiVat;
		public Integer Rabat;
		public Double CenaZRabatem;
		public Double StawkaRyczaltu;
		public Integer MagazynPozycjaId;
		public Integer MagazynMagazynId;
		public Integer MagazynObiektSprzedazyId;
		public String GTU;
	}

	
	public static SingleInvoiceJSON2Apex parse(String json) {
		return (SingleInvoiceJSON2Apex) System.JSON.deserialize(json, SingleInvoiceJSON2Apex.class);
	}
}