@isTest
private class WeeklyIfirmaTest {    

    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            if (req.getEndpoint().endsWith('list.json') || req.getEndpoint().endsWith(String.valueOf(Datetime.now().year()))) {
                HTTPResponse res = new HTTPResponse();
                res.setBody('{"response": [{"KontrahentNazwa": "kkktest",'
                                            +'"KontrahentId": 45015903,'
                                            +'"DataWystawienia": "2020-11-30",'
                                            +'"PelnyNumer": "1/2020",'
                                            +'"Brutto": 33}]}');
                res.setStatusCode(200);
                return res;
            } else{
                HTTPResponse res = new HTTPResponse();
                res.setBody('{"response": {"Zaplacono": 0,'
                                            +'"ZaplaconoNaDokumencie": 0,'
                                            +'"LiczOd": "BRT",'
                                            +'"NumerKontaBankowego": null,'
                                            +'"IdentyfikatorKontrahenta": null,'
                                            +'"PrefiksUEKontrahenta": null,'
                                            +'"NIPKontrahenta": null,'
                                            +'"DataWystawienia": "2020-11-24",'
                                            +'"MiejsceWystawienia": null,'
                                            +'"DataSprzedazy": "2020-11-24",'
                                            +'"FormatDatySprzedazy": "DZN",'
                                            +'"TerminPlatnosci": "2020-12-01",'
                                            +'"SposobZaplaty": "PRZ",'
                                            +'"NazwaSeriiNumeracji": "Domyślna roczna",'
                                            +'"NazwaSzablonu": "Logo",'
                                            +'"RodzajPodpisuOdbiorcy": "BPO",'
                                            +'"PodpisOdbiorcy": null,'
                                            +'"PodpisWystawcy": null,'
                                            +'"Uwagi": null,'
                                            +'"WidocznyNumerGios": false,'
                                            +'"Numer": 1,'
                                            +'"Pozycje": [{"Id": 106871869,'
                                            +'           "StawkaVat": null,'
                                            +'           "Ilosc": 12,'
                                            +'           "CenaJednostkowa": 1,'
                                            +'           "NazwaPelna": "samochód zabawka",'
                                            +'           "Jednostka": "1",'
                                            +'           "PKWiU": "Art. 113 ust. 1",'
                                            +'           "PodstawaPrawna": "Art. 113 ust. 1",'
                                            +'           "TypStawkiVat": "ZW",'
                                            +'           "Rabat": null,'
                                            +'           "CenaZRabatem": 1,'
                                            +'           "StawkaRyczaltu": null,'
                                            +'           "MagazynPozycjaId": null,'
                                            +'           "MagazynMagazynId": null,'
                                            +'           "MagazynObiektSprzedazyId": null,'
                                            +'           "GTU": null}],'
                                            +'"Kontrahent": {"Nazwa": "marek",'
                                            +'               "Nazwa2": null,'
                                            +'               "Identyfikator": "MAREK(2)",'
                                            +'               "PrefiksUE": "CZ",'
                                            +'               "NIP": "1231313",'
                                            +'               "Ulica": null,'
                                            +'               "KodPocztowy": "12-100",'
                                            +'               "Kraj": null,'
                                            +'               "Miejscowosc": "Czarkowy Grąd",'
                                            +'               "Email": null,'
                                            +'               "Telefon": null,'
                                            +'               "OsobaFizyczna": false,'
                                            +'               "ZgodaNaEfaktury": true,'
                                            +'               "DataUdzieleniaZgody": null,'
                                            +'               "EmailDlaFaktury": null,'
                                            +'               "JestDostawca": false,'
                                            +'               "JestOdbiorca": true,'
                                            +'               "AdresZagraniczny": false,'
                                            +'               "OdbiorcaNaFakturze": null,'
                                            +'               "Skype": null,'
                                            +'               "Faks": null,'
                                            +'               "Uwagi": null,'
                                            +'               "Www": null,'
                                            +'               "NazwaBanku": null,'
                                            +'               "NumerKonta": null,'
                                            +'               "DrugiTelefon": null,'
                                            +'               "AdresKorespondencyjnyUlica": null,'
                                            +'               "AdresKorespondencyjnyKodPocztowy": null,'
                                            +'               "AdresKorespondencyjnyKraj": null,'
                                            +'               "AdresKorespondencyjnyMiejscowosc": null,'
                                            +'               "PodmiotPowiazany": false},'
                                            +'   "PelnyNumer": "1/2020",'
                                            +'   "WidocznyNumerBdo": false,'
                                            +'   "WpisDoKpir": "TOW",'
                                            +'   "SplitPayment": false,'
                                            +'   "ProceduryJpk": {"SW": false,'
                                            +'                   "EE": false,'
                                            +'                   "TP": false,'
                                            +'                   "TT_WNT": false,'
                                            +'                   "TT_D": false,'
                                            +'                   "MR_T": false,'
                                            +'                   "MR_UZ": false,'
                                            +'                   "I_42": false,'
                                            +'                   "I_63": false,'
                                            +'                   "BSPV": false,'
                                            +'                   "BSPVDostawa": false,'
                                            +'                   "BMPVProwizja": false,'
                                            +'                   "MPP": false'
                                            +'               }'
                                            +'   }'
                                            +'}');
                res.setStatusCode(200);
                return res;
            } 
        }
    } 
    @isTest
    static void givenCronWhenFireScheduleThenCheckScheduleInfo(){

        //given
        String CRON = '0 0 0 15 3 ? 2022';
        
        //when
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
            String jobId = System.schedule('ScheduledApexTest', CRON, new WeeklyIfirma());                                   
        Test.stopTest();

        //then
        System.assertEquals(jobId, [SELECT Id,CronJobDetail.Name
                                    FROM CronTrigger 
                                    WHERE CronJobDetail.Name = 'ScheduledApexTest'].id);
    }
}