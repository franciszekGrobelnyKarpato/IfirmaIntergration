@isTest
private class ifirmaServiceTest {

    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            if (req.getEndpoint().endsWith('list.json') || req.getEndpoint().endsWith(String.valueOf(Datetime.now().year()))) {
                HTTPResponse res = new HTTPResponse();
                res.setBody('{"response": [{"KontrahentNazwa": "kkktest","KontrahentId": 45015903,"DataWystawienia": "2020-11-30","PelnyNumer": "1/2020","Brutto": 33}]}');
                res.setStatusCode(200);
                return res;
            } else if(req.getEndpoint().endsWith('miesiacksiegowy.json')){
                HTTPResponse res = new HTTPResponse();
                res.setBody('{"response": {"RokKsiegowy": 2021,"MiesiacKsiegowy": 3}}');
                res.setStatusCode(200);
                return res;
            }else{
                HTTPResponse res = new HTTPResponse();
                res.setBody('{"response": {"Zaplacono": 0,"ZaplaconoNaDokumencie": 0,"LiczOd": "BRT","NumerKontaBankowego": null,"IdentyfikatorKontrahenta": null,"PrefiksUEKontrahenta": null,"NIPKontrahenta": null,"DataWystawienia": "2020-11-24","MiejsceWystawienia": null,"DataSprzedazy": "2020-11-24","FormatDatySprzedazy": "DZN","TerminPlatnosci": "2020-12-01","SposobZaplaty": "PRZ","NazwaSeriiNumeracji": "Domyślna roczna","NazwaSzablonu": "Logo","RodzajPodpisuOdbiorcy": "BPO","PodpisOdbiorcy": null,"PodpisWystawcy": null,"Uwagi": null,"WidocznyNumerGios": false,"Numer": 1,"Pozycje": [{"Id": 106871869,"StawkaVat": null,"Ilosc": 12,"CenaJednostkowa": 1,"NazwaPelna": "samochód zabawka","Jednostka": "1","PKWiU": "Art. 113 ust. 1","PodstawaPrawna": "Art. 113 ust. 1","TypStawkiVat": "ZW","Rabat": null,"CenaZRabatem": 1,"StawkaRyczaltu": null,"MagazynPozycjaId": null,"MagazynMagazynId": null,"MagazynObiektSprzedazyId": null,"GTU": null}],"Kontrahent": {"Nazwa": "marek","Nazwa2": null,"Identyfikator": "MAREK(2)","PrefiksUE": "CZ","NIP": "1231313","Ulica": null,"KodPocztowy": "12-100","Kraj": null,"Miejscowosc": "Czarkowy Grąd","Email": null,"Telefon": null,"OsobaFizyczna": false,"ZgodaNaEfaktury": true,"DataUdzieleniaZgody": null,"EmailDlaFaktury": null,"JestDostawca": false,"JestOdbiorca": true,"AdresZagraniczny": false,"OdbiorcaNaFakturze": null,"Skype": null,"Faks": null,"Uwagi": null,"Www": null,"NazwaBanku": null,"NumerKonta": null,"DrugiTelefon": null,"AdresKorespondencyjnyUlica": null,"AdresKorespondencyjnyKodPocztowy": null,"AdresKorespondencyjnyKraj": null,"AdresKorespondencyjnyMiejscowosc": null,"PodmiotPowiazany": false},"PelnyNumer": "1/2020","WidocznyNumerBdo": false,"WpisDoKpir": "TOW","SplitPayment": false,"ProceduryJpk": {"SW": false,"EE": false,"TP": false,"TT_WNT": false,"TT_D": false,"MR_T": false,"MR_UZ": false,"I_42": false,"I_63": false,"BSPV": false,"BSPVDostawa": false,"BMPVProwizja": false,"MPP": false}}}');
                res.setStatusCode(200);
                return res;
            }
        }
    }   
    @isTest
    static void givenInvoiceWhenSavingPDFThenCheckIfContentVersionCreated(){
        //given
        Ifirma_Rest_Data__mdt restdata = [SELECT User__c, Key__c 
                                            FROM Ifirma_Rest_Data__mdt 
                                            WHERE Label='Settings' LIMIT 1]; 
        ifirmaService.key = restdata.Key__c;
        ifirmaService.user = restdata.User__c;

        ifirmaService.numberURLsMap.put('1_2021','kraj');
        Invoice_Custom__c inv = new Invoice_Custom__c(Name = 'not relevant');
        Database.insert(inv);

        //when
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        ifirmaService.savePDF();
        Test.stopTest();  

        //then
        System.assertEquals('1/2021', ifirmaService.cvMap.get('1/2021').title);
    }

    @isTest
    static void givenDocumentWhenDeletePDFThenCheckIfDelted(){
        //given
        Invoice_Custom__c inv = new Invoice_Custom__c(Name = 'not relevant');
        Database.insert(inv); 
        ContentVersion cv = new ContentVersion(title='1/2021', pathOnClient='not relevant', versionData=Blob.ValueOf('not relevant'));
        ifirmaService.cvMap.put(cv.Title, cv);  
        Database.insert(ifirmaService.cvMap.values()); 
        //ContentDocument cd = new ContentDocument();
               
        //when
        ifirmaService.deleteOldPDfs(ifirmaService.cvMap);

        //then
        List<ContentDocument> cdList = [select id from ContentDocument];
        System.assertEquals(0, [select id from ContentDocument].size());
    }
    @isTest
     static void givenRestdataWhenSetMetadataThenSetUserAndKey(){  
         //given
         Ifirma_Rest_Data__mdt restdata = [SELECT User__c, Key__c 
                                            FROM Ifirma_Rest_Data__mdt 
                                            WHERE Label='Settings' LIMIT 1]; 
         //when             
        ifirmaService.setMetaData();

        //then
        System.assertEquals(restdata.User__c, ifirmaService.user);
        System.assertEquals(restdata.Key__c, ifirmaService.key);
    }

    @isTest
     static void whenGetingInvoicesFromIfirmaThenReturnNotNullInvoicesList(){
        //when
        Test.setMock(HttpCalloutMock.class, new Mock());
        ifirmaService.key = '5BC3A3E1F5382899';
        Test.startTest();
        ifirmaService.getWholeInvoicesFromIfirma();    
        Test.stopTest();

        //then
        System.assertNotEquals(0, ifirmaService.ifirmaInvoicesMap.size());
        System.assertEquals(1, ifirmaService.ifirmaInvoicesMap.size());
        System.assertEquals('1/2020', ifirmaService.ifirmaInvoicesMap.get('1_2020').PelnyNumer);
    }

    @isTest
    static void givenNullValuesWhenPrepareDataThenFillMapsWithValues(){
        //given
        SingleInvoiceJSON2Apex.Response response = new SingleInvoiceJSON2Apex.Response();
        SingleInvoiceJSON2Apex.Kontrahent kontrahent = new SingleInvoiceJSON2Apex.Kontrahent();   
        Invoice_Custom__c inv = new Invoice_Custom__c(Name = 'not relevant', Whole_Number__c = '1_2020');
        response.PelnyNumer = '1/2020';
        response.Kontrahent = kontrahent;
        response.Kontrahent.Nazwa = 'marek';
        response.Kontrahent.NIP = '1231313';
        ifirmaService.ifirmaInvoicesMap.put(response.PelnyNumer.replace('/', '_'), response);
        Database.insert(new Account(Name = 'not relevant', NIP__c = '1231313'));
        Database.insert(inv);
        Database.insert(new Invoice_Line__c(Name = 'samochód', Invoice_Custom__c = inv.Id));
        
        //when
        Test.startTest();
        ifirmaService.prepareData();
        Test.stopTest();

        //then
        System.assertEquals(1, ifirmaService.baseAccountsNIPMap.size());
        System.assertEquals(1, ifirmaService.baseInvoicesWholeNumberMap.size());
        System.assertEquals(1, ifirmaService.baseInvoiceLinesWholeNumberMap.size());
        System.assertEquals('1231313', ifirmaService.baseAccountsNIPMap.get('1231313').NIP__c);
        System.assertEquals(inv.Whole_Number__c, ifirmaService.baseInvoicesWholeNumberMap.get('1/2020').Whole_Number__c);
        
     
    }

    @isTest
    static void givenIfirmaInvoicesListWhenCheckingIfAccountNotExistThenSendEmail(){
        //given
        for(Integer i=0;i<200;i++) {
            SingleInvoiceJSON2Apex.Response response = new SingleInvoiceJSON2Apex.Response();
            SingleInvoiceJSON2Apex.Kontrahent kontrahent = new SingleInvoiceJSON2Apex.Kontrahent();  
            response.PelnyNumer = 'numer'+i;
            response.Kontrahent = kontrahent;
            response.Kontrahent.Nazwa = 'nazwa'+i;
            response.Kontrahent.NIP = 'nip'+i;
            ifirmaService.ifirmaInvoicesMap.put(response.PelnyNumer.replace('/', '_'), response);
        }  
        //when
        Test.startTest();
        ifirmaService.checkAndSendEmailIfAccountsDontExistInDB();
        Integer limits = Limits.getEmailInvocations();
        Test.stopTest();

        //then
        System.assertEquals(1, limits);
    }

    @isTest
    static void givenNotExistedInvoiceWhenCreateOrUpdateThenAddToCreateList(){
      //given
        SingleInvoiceJSON2Apex.Response response = new SingleInvoiceJSON2Apex.Response();        
        SingleInvoiceJSON2Apex.Kontrahent kontrahent = new SingleInvoiceJSON2Apex.Kontrahent();           
        response.PelnyNumer = '1_2020';
        response.Waluta = 'PLN';
        response.DataWystawienia = '2020-11-24';
        response.DataSprzedazy = '2020-11-24';
        response.Kontrahent = kontrahent;
        response.Kontrahent.Nazwa = 'marek';
        response.TerminPlatnosci = '2020-11-24';
        response.Kontrahent.NIP = '1231313';
        ifirmaService.ifirmaInvoicesMap.put(response.PelnyNumer.replace('/', '_'), response);                        
        ifirmaService.baseAccountsNIPMap.put('1231313', new Account(Name='not relevant', NIP__c='1231313'));

        //when
        Test.startTest();
        ifirmaService.createOrUpdateInvoiceCustomObject();
        Test.stopTest();

        //then
        System.assertEquals(1, ifirmaService.customInvoiceMap.size());
        System.assertEquals('1_2020', ifirmaService.customInvoiceMap.get('1_2020').Whole_Number__c);
        System.assertEquals(0, ifirmaService.invoiceCustomToUpdate.size());
   }
   @isTest
    static void givenNotExistedInvoiceWithNullWalutaWhenCreateOrUpdateThenAddToCreateList(){
      //given
        SingleInvoiceJSON2Apex.Response response = new SingleInvoiceJSON2Apex.Response();        
        SingleInvoiceJSON2Apex.Kontrahent kontrahent = new SingleInvoiceJSON2Apex.Kontrahent();           
        response.PelnyNumer = '1_2020';
        response.Waluta = null;
        response.DataWystawienia = '2020-11-24';
        response.DataSprzedazy = '2020-11-24';
        response.Kontrahent = kontrahent;
        response.Kontrahent.Nazwa = 'marek';
        response.TerminPlatnosci = '2020-11-24';
        response.Kontrahent.NIP = '1231313';
        ifirmaService.ifirmaInvoicesMap.put(response.PelnyNumer.replace('/', '_'), response);                        
        ifirmaService.baseAccountsNIPMap.put('1231313', new Account(Name='not relevant', NIP__c='1231313'));
        
        //when
        Test.startTest();
        ifirmaService.createOrUpdateInvoiceCustomObject();
        Test.stopTest();

        //then
        System.assertEquals(1, ifirmaService.customInvoiceMap.size());
        System.assertEquals('1_2020', ifirmaService.customInvoiceMap.get('1_2020').Whole_Number__c);
        System.assertEquals(0, ifirmaService.invoiceCustomToUpdate.size());
   }

   @isTest
    static void givenExistedInvoiceWhenCreateOrUpdateThenAddToUpdateList(){
        //given
        SingleInvoiceJSON2Apex.Response response = new SingleInvoiceJSON2Apex.Response();       
        SingleInvoiceJSON2Apex.Kontrahent kontrahent = new SingleInvoiceJSON2Apex.Kontrahent();  
        Invoice_Custom__c inv = new Invoice_Custom__c(Name = 'not relevant');
        response.PelnyNumer = '1_2020';
        response.Waluta = 'PLN';
        response.DataWystawienia = '2020-11-24';
        response.DataSprzedazy = '2020-11-24';
        response.Kontrahent = kontrahent;
        response.Kontrahent.Nazwa = 'marek';
        response.Kontrahent.NIP = '1231313';
        response.TerminPlatnosci = '2020-11-24';
        Database.insert(inv);
        ifirmaService.ifirmaInvoicesMap.put(response.PelnyNumer.replace('/', '_'), response);                         
        ifirmaService.baseAccountsNIPMap.put('1231313', new Account(Name = 'not relevant', NIP__c = '1231313'));
        ifirmaService.baseInvoicesWholeNumberMap.put('1_2020',inv);

        //when
        Test.startTest();
        ifirmaService.createOrUpdateInvoiceCustomObject();
        Test.stopTest();

        //then
        System.assertEquals(0, ifirmaService.customInvoiceMap.size());
        System.assertEquals(1, ifirmaService.invoiceCustomToUpdate.size());
        System.assertEquals('1_2020', ifirmaService.invoiceCustomToUpdate.get('1_2020').Whole_Number__c);
   }
   @isTest
   static void givenExistedInvoiceWithNullWalutaWhenCreateOrUpdateThenAddToUpdateList(){
       //given
       SingleInvoiceJSON2Apex.Response response = new SingleInvoiceJSON2Apex.Response();       
       SingleInvoiceJSON2Apex.Kontrahent kontrahent = new SingleInvoiceJSON2Apex.Kontrahent();  
       Invoice_Custom__c inv = new Invoice_Custom__c(Name = 'not relevant');
       response.PelnyNumer = '1_2020';
       response.Waluta = null;
       response.DataWystawienia = '2020-11-24';
       response.DataSprzedazy = '2020-11-24';
       response.Kontrahent = kontrahent;
       response.Kontrahent.Nazwa = 'marek';
       response.Kontrahent.NIP = '1231313';
       response.TerminPlatnosci = '2020-11-24';
       Database.insert(inv);
       ifirmaService.ifirmaInvoicesMap.put(response.PelnyNumer.replace('/', '_'), response);                    
       ifirmaService.baseAccountsNIPMap.put('1231313', new Account(Name = 'not relevant', NIP__c = '1231313'));
       ifirmaService.baseInvoicesWholeNumberMap.put('1_2020',inv);
       
       //when
       Test.startTest();
       ifirmaService.createOrUpdateInvoiceCustomObject();
       Test.stopTest();

       //then
       System.assertEquals(0, ifirmaService.customInvoiceMap.size());
       System.assertEquals(1, ifirmaService.invoiceCustomToUpdate.size());
       System.assertEquals('1_2020', ifirmaService.invoiceCustomToUpdate.get('1_2020').Whole_Number__c);
    }

    @isTest
    static void givenInvoiceWithContentVersionWhenUpdateInvoiceThenCreateContentDocument(){
        //given
        
        SingleInvoiceJSON2Apex.Response response = new SingleInvoiceJSON2Apex.Response();       
        SingleInvoiceJSON2Apex.Kontrahent kontrahent = new SingleInvoiceJSON2Apex.Kontrahent();  
        Invoice_Custom__c inv = new Invoice_Custom__c(Name = 'not relevant');
        response.PelnyNumer = '1_2020';
        response.Waluta = null;
        response.DataWystawienia = '2020-11-24';
        response.DataSprzedazy = '2020-11-24';
        response.Kontrahent = kontrahent;
        response.Kontrahent.Nazwa = 'marek';
        response.Kontrahent.NIP = '1231313';
        response.TerminPlatnosci = '2020-11-24';
        Database.insert(inv);
        ifirmaService.ifirmaInvoicesMap.put(response.PelnyNumer.replace('/', '_'), response);                    
        ifirmaService.baseAccountsNIPMap.put('1231313', new Account(Name = 'not relevant', NIP__c = '1231313'));
        ifirmaService.baseInvoicesWholeNumberMap.put('1_2020',inv);

        ContentVersion cv = new ContentVersion(title='1/2020', pathOnClient='not relevant', versionData=Blob.ValueOf('not relevant'));
        ifirmaService.cvMap.put(cv.Title, cv);  
        Database.insert(ifirmaService.cvMap.values()); 
       
        //when
        Test.startTest();
        ifirmaService.createOrUpdateInvoiceCustomObject();
        Test.stopTest();

        //then
        System.assertNotEquals(0, [select id from ContentDocument].size());
        System.assertEquals(1, [select id from ContentDocument].size());
    }
    @isTest
    static void givenContentVersionWhenUpdateInvoiceThenCreateContentDocument(){
        //given
        
        SingleInvoiceJSON2Apex.Response response = new SingleInvoiceJSON2Apex.Response();        
        SingleInvoiceJSON2Apex.Kontrahent kontrahent = new SingleInvoiceJSON2Apex.Kontrahent();           
        response.PelnyNumer = '1_2020';
        response.Waluta = null;
        response.DataWystawienia = '2020-11-24';
        response.DataSprzedazy = '2020-11-24';
        response.Kontrahent = kontrahent;
        response.Kontrahent.Nazwa = 'marek';
        response.TerminPlatnosci = '2020-11-24';
        response.Kontrahent.NIP = '1231313';
        ifirmaService.ifirmaInvoicesMap.put(response.PelnyNumer.replace('/', '_'), response);                        
        ifirmaService.baseAccountsNIPMap.put('1231313', new Account(Name='not relevant', NIP__c='1231313'));

        ContentVersion cv = new ContentVersion(title='1/2020', pathOnClient='not relevant', versionData=Blob.ValueOf('not relevant'));
        ifirmaService.cvMap.put(cv.Title, cv);  
        Database.insert(ifirmaService.cvMap.values()); 
       
        //when
        Test.startTest();
        ifirmaService.createOrUpdateInvoiceCustomObject();
        Test.stopTest();

        //then
        System.assertNotEquals(0, [select id from ContentDocument].size());
        System.assertEquals(1, [select id from ContentDocument].size());
    }
    @isTest
    static void givenNotExistedInvoiceLinesWhenCreateOrUpdateThenCheckIfCreated(){
        //given
        Invoice_Custom__c invoice = new Invoice_Custom__c(Whole_Number__c = '1_2020', Name = 'not relevant', CurrencyIsoCode = 'PLN');
        SingleInvoiceJSON2Apex.Response response = new SingleInvoiceJSON2Apex.Response();
        List<SingleInvoiceJSON2Apex.Pozycje> pozycje = new List<SingleInvoiceJSON2Apex.Pozycje>();       
        SingleInvoiceJSON2Apex.Pozycje p = new SingleInvoiceJSON2Apex.Pozycje();
        p.NazwaPelna = '1_2020';
        p.CenaZRabatem = 23;
        p.Ilosc = 3;
        p.Rabat = 2;    
        p.CenaJednostkowa = 30;
        p.PodstawaPrawna = 'oij';
        p.Jednostka = 'a';
        response.Pozycje = pozycje; 
        response.Pozycje.add(p);
        Database.insert(invoice);
        ifirmaService.customInvoiceMap.put('1_2020',invoice);
        ifirmaService.invoiceLineMap.put('1_2020',response.Pozycje);

        //when
        Test.startTest();
        ifirmaService.createOrUpdateInvoiceLinesRelatedToInvoiceCustomObject();
        Test.stopTest();
        List<Invoice_Line__c> createdLine = [SELECT id 
                                             FROM Invoice_Line__c LIMIT 1];

        //then
        System.assertNotEquals(0, ifirmaService.invoiceLineMap.size());
        System.assertEquals(0, ifirmaService.invoiceLinesToUpdate.size());
        System.assertEquals(1, createdLine.size());
    }

    @isTest
    static void givenExistedInvoiceLinesWhenCreateOrUpdateThenCheckIfUpdated(){

        //given
        Invoice_Custom__c invoice = new Invoice_Custom__c(Whole_Number__c = '1_2020', Name = 'not relevant', CurrencyIsoCode = 'PLN');
        SingleInvoiceJSON2Apex.Response response = new SingleInvoiceJSON2Apex.Response();
        List<SingleInvoiceJSON2Apex.Pozycje> pozycje = new List<SingleInvoiceJSON2Apex.Pozycje>();       
        SingleInvoiceJSON2Apex.Pozycje p = new SingleInvoiceJSON2Apex.Pozycje();
        p.NazwaPelna = '1_2020';
        p.CenaZRabatem = 23;
        p.Ilosc = 3;
        p.Rabat = 2;    
        p.CenaJednostkowa = 30;
        p.PodstawaPrawna = 'oij';
        p.Jednostka = 'a';
        response.Pozycje = pozycje; 
        response.Pozycje.add(p);
        Database.insert(invoice);
        ifirmaService.invoiceLinesToUpdate.put('1_2020',response.Pozycje);
        ifirmaService.baseInvoicesWholeNumberMap.put('1/2020', invoice);
        ifirmaService.customInvoiceMap.put('1_2020', invoice);
        ifirmaService.invoiceCustomToUpdate.put('1_2020', invoice);

        //when
        Test.startTest();
        ifirmaService.createOrUpdateInvoiceLinesRelatedToInvoiceCustomObject();
        Test.stopTest();  
        List<Invoice_Line__c> updatedLine = [SELECT id 
                                             FROM Invoice_Line__c];
        //then
        System.assertNotEquals(0, ifirmaService.invoiceLinesToUpdate.size());
        System.assertEquals(0, ifirmaService.invoiceLineMap.size());
        System.assertEquals(1, updatedLine.size());
    }

    @isTest
    static void givenRestDataWhenMainMethodThenCheckCustomMetaData(){
        //given
        Ifirma_Rest_Data__mdt restdata = [SELECT User__c, Key__c 
                                            FROM Ifirma_Rest_Data__mdt 
                                            WHERE Label='Settings' LIMIT 1];  
        Invoice_Custom__c invoice = new Invoice_Custom__c(Whole_Number__c = '1_2020', Name = 'not relevant', CurrencyIsoCode = 'PLN');                
        Database.insert(invoice);        
        
        ifirmaService.baseAccountsNIPMap.put('1231313', new Account(Name='not relevant', NIP__c='1231313'));

        //when
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        ifirmaService.saveInvoices();
        Test.stopTest();          
        
        //then
        System.assertEquals(restdata.User__c, ifirmaService.user);
        System.assertEquals(restdata.Key__c, ifirmaService.key);
    }    
    @isTest
    static void givenMetaDataWhenFiredByScheduleThenCheckIfAnyInvoicesAddedToMap(){
        //given
        Ifirma_Rest_Data__mdt restdata = [SELECT User__c, Key__c 
                                            FROM Ifirma_Rest_Data__mdt 
                                            WHERE Label='Settings' LIMIT 1]; 
        ifirmaService.user = restdata.User__c;
        ifirmaService.key = restdata.Key__c;
        ifirmaService.isScheduleFired = true;
        //when
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        Map<String, String> numberURLsMaps = ifirmaService.getInvoiceNumbersList();
        Test.stopTest();          
        
        //then
        System.assertNotEquals(0, numberURLsMaps.size());
    }   
    @isTest
    static void givenMetaDataAndAccountWhenGettingInvoicesListThenCheckIfForAccouontServiceSentData(){
        //given
        Ifirma_Rest_Data__mdt restdata = [SELECT User__c, Key__c 
                                            FROM Ifirma_Rest_Data__mdt 
                                            WHERE Label='Settings' LIMIT 1]; 
        ifirmaService.user = restdata.User__c;
        ifirmaService.key = restdata.Key__c;  
        ifirmaService.isAccountFired = true;
        Account a = new Account(Name='kkktest', NIP__c='23423423');
        Database.insert(a);
        ifirmaService.accountId = a.id;  
        //when
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        Map<String, String> numberURLsMaps = ifirmaService.getNumberMap('');
        Test.stopTest();          
        
        //then
        System.assertNotEquals(0, numberURLsMaps.size());
    }  
    @isTest
    static void givenAccountAndInvoiceWhenSavingInvoicesForGivenAccountThenCheckIfAnySaved(){
        //given
        Ifirma_Rest_Data__mdt restdata = [SELECT User__c, Key__c 
                                            FROM Ifirma_Rest_Data__mdt 
                                            WHERE Label='Settings' LIMIT 1]; 
        ifirmaService.user = restdata.User__c;
        ifirmaService.key = restdata.Key__c;  
        ifirmaService.isAccountFired = true;
        Account account = new Account(Name='kkktest', NIP__c='23423423');
        Database.insert(account);
        ifirmaService.accountId = account.id;  
        Invoice_Custom__c invoice = new Invoice_Custom__c(Whole_Number__c = '1_2020', Name = 'not relevant', CurrencyIsoCode = 'PLN');                
        Database.insert(invoice);                
        ifirmaService.baseAccountsNIPMap.put('1231313', new Account(Name='not relevant', NIP__c='1231313'));
        //when
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        ifirmaService.saveAccountInvoices(account.id);
        Test.stopTest();          
        
        //then
        System.assertNotEquals(0, ifirmaService.numberURLsMap.size());
    }
    @isTest
    static void givenOpportunityAndPolishAccountWhenCreatingInvoiceForOpportunityThenCheckIfInvocieRelatedToOpportunity(){
    //given 
        Account account = new Account(Name='not relevant acc',
                                      Nip__c = '121212',                                     
                                      BillingCity = 'Wrocław', 
                                      BillingCountry = 'Polska', 
                                      BillingPostalCode = '11-111');
        Database.insert(account);
        Product2 prod = new Product2(Name = 'samochodzik');
        Database.insert(prod);    
        Id pbId = Test.getStandardPricebookId();   
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pbId,
                                                Product2Id = prod.Id,
                                                UnitPrice = 1,
                                                IsActive = TRUE);
        Database.insert(pbe);
        Opportunity opp = new Opportunity(Name = 'not relevant opp',
                                          Pricebook2Id = pbId,                                          
                                          AccountId = account.Id,
                                          Publish_Date__c = Date.newInstance(2021, 04, 30),
                                          Sale_Date__c = Date.newInstance(2021, 04, 30),                                          
                                          Payment_Date__c = Date.newInstance(2021, 05, 14),
                                          Date_Of_Tax_Obligation__c = Date.newInstance(2021, 04, 30),
                                          StageName = 'Prospecting', 
                                          Vat_Percentage__c = '23',                                          
                                          CloseDate = Date.newInstance(2021, 04, 04));        
        Database.insert(opp);
        OpportunityLineItem oppProduct = new OpportunityLineItem(Product2Id = prod.Id,
                                                                 OpportunityId = opp.Id,                                                               
                                                                 Unit__c = 'szt',
                                                                 Unit_Foreign__c = 'pcs',
                                                                 Quantity = 1,
                                                                 UnitPrice = 1);
        Database.insert(oppProduct);
        Invoice_Custom__c inv = new Invoice_Custom__c(Name = '1/2020');
        Database.insert(inv);
    //when
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        ifirmaService.createInvoiceByOpportunity(opp.Id);
        Test.stopTest();
    //then
        System.assertNotEquals(null, [select name, opportunity__c from Invoice_Custom__c where name =:inv.Name].Opportunity__c);
        System.assertEquals(opp.Id, [select name, opportunity__c from Invoice_Custom__c where name =:inv.Name].Opportunity__c);
    }
    @isTest
    static void givenOpportunityAndForeignAccountWhenCreatingInvoiceForOpportunityThenCheckIfInvocieRelatedToOpportunity(){  
        //given
        Account account = new Account(Name='not relevant acc',
                                      Nip__c = '121212',                                      
                                      BillingCity = 'Wrocław', 
                                      BillingCountry = 'Great Britain', 
                                      BillingPostalCode = '11-111',
                                      BillingStreet='street');
        Database.insert(account);
        Product2 prod = new Product2(Name = 'samochodzik');
        Database.insert(prod);   
        Product2 prod2 = new Product2(Name = 'samochodzik');
        Database.insert(prod2);  
        Id pbId = Test.getStandardPricebookId();   
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pbId,
                                                Product2Id = prod.Id,
                                                UnitPrice = 1,
                                                IsActive = TRUE);
        Database.insert(pbe);
        PricebookEntry pbe2 = new PricebookEntry(Pricebook2Id = pbId,
                                                Product2Id = prod2.Id,
                                                UnitPrice = 1,
                                                IsActive = TRUE);
        Database.insert(pbe2);
        Opportunity opp = new Opportunity(Name = 'not relevant opp',
                                          Pricebook2Id = pbId,          
                                          AccountId = account.Id,
                                          Publish_Date__c = Date.newInstance(2021, 02, 28),
                                          Sale_Date__c = Date.newInstance(2021, 02, 28),                                          
                                          Payment_Date__c = Date.newInstance(2021, 03, 14),
                                          Date_Of_Tax_Obligation__c = Date.newInstance(2021, 02, 28),
                                          StageName = 'Prospecting',  
                                          Vat_Percentage__c = '23',                                                                                  
                                          CloseDate = Date.newInstance(2021, 04, 04));        
        Database.insert(opp);
        OpportunityLineItem oppProduct = new OpportunityLineItem(Product2Id = prod.Id,
                                                                 OpportunityId = opp.Id,                                                               
                                                                 Unit__c = 'szt',
                                                                 Unit_Foreign__c = 'pcs',
                                                                 Quantity = 1,
                                                                 UnitPrice = 1);
        Database.insert(oppProduct);
        OpportunityLineItem oppProduct2 = new OpportunityLineItem(Product2Id = prod2.Id,
                                                                 OpportunityId = opp.Id,                                                               
                                                                 Unit__c = 'szt',
                                                                 Unit_Foreign__c = 'pcs',
                                                                 Quantity = 1,
                                                                 UnitPrice = 1);
        Database.insert(oppProduct2);
        Invoice_Custom__c inv = new Invoice_Custom__c(Name = '1/2020');
        Database.insert(inv);
    //when
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        ifirmaService.createInvoiceByOpportunity(opp.Id);
        Test.stopTest();
    //then
        System.assertNotEquals(null, [select name, opportunity__c from Invoice_Custom__c where name =:inv.Name].Opportunity__c);
        System.assertEquals(opp.Id, [select name, opportunity__c from Invoice_Custom__c where name =:inv.Name].Opportunity__c);
    }
    @isTest
    static void givenNotFilledAccountCountryInMetaAndOpportunityWithoutNeededFieldsToCreateInvoiceWhenCheckingIfNotFilledThenReturnListWithAllFields(){
        //given        
        Account acc = new Account(Name='not relevant',
                                  BillingCountry='koko maroko');                     
        Database.insert(acc);
        Opportunity opp = new Opportunity(Name='not relevant',
                                          StageName='Prospecting', 
                                          CloseDate=Date.newInstance(2021, 02, 04),
                                          AccountId=acc.Id);
        Database.insert(opp);

        //when
        List<String> notFilledFieldsList = ifirmaService.checkFilledFields(opp.Id);
        //then
        System.assertNotEquals(null, notFilledFieldsList);
        System.assertEquals(9, notFilledFieldsList.size());
        System.assertNotEquals(0, notFilledFieldsList.size());
    }
    @isTest
    static void givenFilledAccountCountryInMetaAndOpportunityWithoutNeededFieldsToCreateInvoiceWhenCheckingIfNotFilledThenReturnListWithAllFields(){
        //given        
        Account acc = new Account(Name='not relevant',
                                  BillingCountry='Poland');                     
        Database.insert(acc);
        Opportunity opp = new Opportunity(Name='not relevant',
                                          StageName='Prospecting', 
                                          CloseDate=Date.newInstance(2021, 02, 04),
                                          AccountId=acc.Id);
        Database.insert(opp);

        //when
        List<String> notFilledFieldsList = ifirmaService.checkFilledFields(opp.Id);
        //then
        System.assertNotEquals(null, notFilledFieldsList);
        System.assertEquals(8, notFilledFieldsList.size());
        System.assertNotEquals(0, notFilledFieldsList.size());
    }
}