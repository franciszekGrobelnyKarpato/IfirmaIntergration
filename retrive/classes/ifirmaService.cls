global  class ifirmaService {

    @TestVisible private static Map<String, List<SingleInvoiceJSON2Apex.Pozycje>> invoiceLineMap = new Map<String, List<SingleInvoiceJSON2Apex.Pozycje>>();
    @TestVisible private static Map<String, Invoice_Custom__c> customInvoiceMap = new Map<String, Invoice_Custom__c>();
    @TestVisible private static Map<String, Account> baseAccountsNIPMap = new Map<String, Account>();   
    @TestVisible private static Map<String, Invoice_Custom__c> baseInvoicesWholeNumberMap = new Map<String, Invoice_Custom__c>();
    @TestVisible private static Map<String, Invoice_Line__c> baseInvoiceLinesWholeNumberMap = new Map<String, Invoice_Line__c>();
    @TestVisible private static Map<String, Invoice_Custom__c> invoiceCustomToUpdate = new Map<String, Invoice_Custom__c>();
    @TestVisible private static Map<String, SingleInvoiceJSON2Apex.Response> ifirmaInvoicesMap = new Map<String, SingleInvoiceJSON2Apex.Response>();
    @TestVisible private static Map<String, List<SingleInvoiceJSON2Apex.Pozycje>>  invoiceLinesToUpdate = new Map<String, List<SingleInvoiceJSON2Apex.Pozycje>>();
    @TestVisible private static Map<String, String> numberURLsMap = new Map<String, String>();  
    @TestVisible private static Map<String, contentVersion> cvMap = new Map<String, contentVersion>();    
    public static String user;
    public static String key;      
    public static Boolean isScheduleFired = false;
    @TestVisible private static Boolean isAccountFired = false;
    @TestVisible private static Id accountId;

    @AuraEnabled
    public static void saveInvoices(){

        setMetaData();
        getWholeInvoicesFromIfirma();
        savePDF();
        prepareData();

        checkAndSendEmailIfAccountsDontExistInDB();
        createOrUpdateInvoiceCustomObject();
        createOrUpdateInvoiceLinesRelatedToInvoiceCustomObject();                 
    }
    @AuraEnabled
    public static void saveAccountInvoices(Id recordId){
    
            accountId = recordId;
            isAccountFired = true;
            saveInvoices(); 
        
    }
    @TestVisible
    private static void savePDF(){        
        AggregateResult invoicesAmount = [select count(Id)amount FROM Invoice_Custom__c];
                                
        for(String numer : numberURLsMap.keySet()){
            String hash = hmacGenerator.generateHmacSHA1('https://www.ifirma.pl/iapi/'+numberURLsMap.get(numer)+'/'+numer+'.pdf.single'+user+'faktura', key);  
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://www.ifirma.pl/iapi/'+numberURLsMap.get(numer)+'/'+numer+'.pdf.single');
            request.setMethod('GET');
            request.setHeader('Accept', 'application/pdf');
            request.setHeader('Content-Type', 'application/pdf; charset=UTF-8');
            request.setHeader('Authentication', 'IAPIS user='+user+', hmac-sha1='+hash);
            HttpResponse response = http.send(request);  

            contentVersion cv = new contentVersion();
            cv.Title = numer.replace('_','/');
            cv.PathOnClient = numer.replace('_','/')+'.pdf';
            cv.ContentLocation = 'S'; 
            cv.VersionData = response.getBodyAsBlob();
            cvMap.put(cv.Title, cv);                                     
        }
        if(Integer.valueOf(invoicesAmount.get('amount')) > 0){
            deleteOldPDfs(cvMap);
        }
        Database.insert(cvMap.values());                                         
    }   
/*
Delete pdf files for existed in org invoice objects
*/
    @TestVisible
    private static void deleteOldPDfs(Map<String, contentVersion> cvMap){
        Set<id> cvSet = new Set<id>();
        List<Invoice_Custom__c> invoices = [SELECT  name 
                                            FROM invoice_Custom__c];
        List<String> invNames = new List<String>();
        for(Invoice_Custom__c inv : invoices){
            invNames.add(inv.Name);
        }
        for(contentVersion conVers : [SELECT id, title, contentDocumentid 
                                      FROM contentVersion]){
            if(cvMap.containsKey(conVers.title)){
                cvSet.add(conVers.contentDocumentid);
            }                          
        }
        
        List<Id> documentIds = new List<Id>(new Map<Id, ContentDocument>([SELECT id 
                                                                          FROM ContentDocument 
                                                                          WHERE id IN :cvSet]).keySet());
        Database.delete(documentIds);                                                                                    
    }

    @TestVisible
    public static void setMetaData(){
        Ifirma_Rest_Data__mdt restdata = [SELECT User__c, Key__c 
                                            FROM Ifirma_Rest_Data__mdt 
                                            WHERE Label='Settings' LIMIT 1];  
        user = restdata.User__c;
        key = restdata.Key__c;
    }
/*
Insert into map invoice number and invoice object donwloaded from ifirma.pl service
*/
    @TestVisible
    private static void getWholeInvoicesFromIfirma(){
        numberURLsMap = getInvoiceNumbersList();
        for(String invoiceNumber : numberURLsMap.keySet()){
            SingleInvoiceJSON2Apex.Response invoice = getInvoiceBy(numberURLsMap.get(invoiceNumber), invoiceNumber); 
            ifirmaInvoicesMap.put(invoice.PelnyNumer.replace('/', '_'), invoice);
        }
    }
/*
Save all needed data from Salesforce Org to global properties
*/
    @TestVisible
    private static void prepareData(){
        List<String> nipsInIfirma = new List<String>();
        List<String> wholeNummbersInIfirma = new List<String>();
        List<String> accountNamesInIfirma = new List<String>();
        List<String> baseInvoiceNames = new List<String>();
        

        for(SingleInvoiceJSON2Apex.Response inv : ifirmaInvoicesMap.values()){            
            nipsInIfirma.add(inv.Kontrahent.NIP);   
            accountNamesInIfirma.add(inv.Kontrahent.Nazwa);                  
            wholeNummbersInIfirma.add(inv.PelnyNumer.replace('/', '_'));                       
        }
        for(Account account : [SELECT id, NIP__c 
                                FROM Account 
                                WHERE NIP__c IN :nipsInIfirma]){               
            baseAccountsNIPMap.put(account.NIP__c, account);  
        }     
        for(Invoice_Custom__c invc : [SELECT id, Whole_Number__c, Name
                                        FROM Invoice_Custom__c 
                                        WHERE Whole_Number__c IN :wholeNummbersInIfirma]){
            baseInvoicesWholeNumberMap.put(invc.Whole_Number__c.replace('_','/'), invc);  
            baseInvoiceNames.add(invc.Name);     
        }  
        for(Invoice_Line__c baseInvoiceLine :[SELECT Id, Name, Invoice_Custom__r.Name
                                                FROM Invoice_Line__c 
                                                WHERE Invoice_Custom__r.Name IN :baseInvoiceNames]){
            baseInvoiceLinesWholeNumberMap.put(baseInvoiceLine.Id, baseInvoiceLine);      
        }
    }
/*
Send email with accounts data not existed in Salsforce Org
*/
    @TestVisible
    private static void checkAndSendEmailIfAccountsDontExistInDB(){
        List<SingleInvoiceJSON2Apex.Response> accountsNotCreatedList = new List<SingleInvoiceJSON2Apex.Response>();

        for(SingleInvoiceJSON2Apex.Response invoice : ifirmaInvoicesMap.values()){      
            if(!baseAccountsNIPMap.keySet().contains(invoice.Kontrahent.NIP)){
                accountsNotCreatedList.add(invoice);    
            }
        } 
        try{
            if(accountsNotCreatedList.size()>0){
                throw new DataNotFullyFilledException();                                         
            }
        }catch(DataNotFullyFilledException e){
            e.sendEmail(accountsNotCreatedList);
        } 
    }   
/*
Create Invoice_Custom Objects and save related pdf files
*/
    @TestVisible
    private static void createOrUpdateInvoiceCustomObject(){
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for(SingleInvoiceJSON2Apex.Response invoice : ifirmaInvoicesMap.values()){  
            if(!baseInvoicesWholeNumberMap.containsKey(invoice.PelnyNumer) && baseAccountsNIPMap.containsKey(invoice.Kontrahent.NIP)){ 
                Invoice_Custom__c invoiceCustom = new Invoice_Custom__c(Name = invoice.PelnyNumer,
                                                                        date_of_invoice__c = Date.valueOf(invoice.DataWystawienia),
                                                                        sale_date__c = Date.valueOf(invoice.DataSprzedazy), 
                                                                        Whole_Number__c = invoice.PelnyNumer.replace('/','_'),                                                                        
                                                                        method_of_payment__c = invoice.SposobZaplaty,
                                                                        Account__c = baseAccountsNIPMap.get(invoice.Kontrahent.NIP).Id,                                                                        
                                                                        CurrencyIsoCode = invoice.Waluta != null ? invoice.Waluta : 'PLN');   
                if(invoice.TerminPlatnosci != null){
                    invoiceCustom.date_of_payment__c = Date.valueOf(invoice.TerminPlatnosci);
                }                        
                customInvoiceMap.put(invoice.PelnyNumer.replace('/','_'), invoiceCustom);  
                invoiceLineMap.put(invoice.PelnyNumer.replace('/','_'), invoice.Pozycje);   

            }else if(baseInvoicesWholeNumberMap.containsKey(invoice.PelnyNumer) && baseAccountsNIPMap.containsKey(invoice.Kontrahent.NIP)){
                Invoice_Custom__c invoiceCustom = baseInvoicesWholeNumberMap.get(invoice.PelnyNumer);
                invoiceCustom.Name = invoice.PelnyNumer;
                invoiceCustom.date_of_invoice__c = Date.valueOf(invoice.DataWystawienia);
                invoiceCustom.sale_date__c = Date.valueOf(invoice.DataSprzedazy);
                invoiceCustom.Whole_Number__c = invoice.PelnyNumer.replace('/','_');                
                invoiceCustom.method_of_payment__c = invoice.SposobZaplaty;
                invoiceCustom.Account__c = baseAccountsNIPMap.get(invoice.Kontrahent.NIP).Id;
                invoiceCustom.CurrencyIsoCode = invoice.Waluta != null ? invoice.Waluta : 'PLN';
                if(invoice.TerminPlatnosci != null){
                    invoiceCustom.date_of_payment__c = Date.valueOf(invoice.TerminPlatnosci);
                }
                invoiceCustomToUpdate.put(invoice.PelnyNumer.replace('/','_'), invoiceCustom);
                invoiceLinesToUpdate.put(invoice.PelnyNumer.replace('/','_'), invoice.Pozycje);
            }     
        }                  
        if(customInvoiceMap.size() > 0){
            Database.insert(customInvoiceMap.values());
        }     
        if(invoiceCustomToUpdate.size() > 0){
            Database.update(invoiceCustomToUpdate.values());
        }  
        for(contentVersion cv : cvMap.values()){            
            if(customInvoiceMap.containsKey(cv.title.replace('/','_'))){
                cdlList.add(getDocumentLInkBy(cv, 'create')) ;
            }
            if(invoiceCustomToUpdate.containsKey(cv.title.replace('/','_'))){
                cdlList.add(getDocumentLInkBy(cv, 'update')) ;
            }                      
        }     
        if(cdlList.size()>0){
            Database.insert(cdlList);  
        }  
    }
/*
Return a ContentDocumentLink for specific contentVersion
*/
    private static ContentDocumentLink getDocumentLInkBy(contentVersion cv, String invoiceType){
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT contentDocumentId 
                                    FROM contentVersion 
                                    WHERE id =:cv.id].contentDocumentId;
        if(invoiceType.equals('create')){
        cdl.LinkedEntityId = customInvoiceMap.get(cv.title.replace('/','_')).id;
        }else if(invoiceType.equals('update')){
        cdl.LinkedEntityId = invoiceCustomToUpdate.get(cv.title.replace('/','_')).id;
        }
        cdl.Visibility = 'AllUsers';
        return cdl;
    }
/*
Create invoice lines for not existed invoice or update(delete before then insert) invoice line for existed invoices
*/
    @TestVisible
    private static void createOrUpdateInvoiceLinesRelatedToInvoiceCustomObject(){   
        List<Invoice_Line__c> invoiceLineToInsert = new List<Invoice_Line__c>();
        List<Invoice_Line__c> invoiceLineToUpdate = new List<Invoice_Line__c>();
        
        if(invoiceLineMap.size() > 0){
            for(String key : invoiceLineMap.keySet()){            
                if( !baseInvoiceLinesWholeNumberMap.containsKey(key)){
                    for(SingleInvoiceJSON2Apex.Pozycje invoiceLine : invoiceLineMap.get(key)){                                            
                        Invoice_Line__c customInvoiceLine = new Invoice_Line__c(Name = invoiceLine.NazwaPelna.length() > 80 ? invoiceLine.NazwaPelna.substring(0,80) : invoiceLine.NazwaPelna,
                                                                                Invoice_Custom__c = customInvoiceMap.get(key).Id,  
                                                                                Unit_Price__c = invoiceLine.CenaJednostkowa,                                                                              
                                                                                Quantity__c = invoiceLine.Ilosc,
                                                                                Discount_Percentage__c = invoiceLine.Rabat,
                                                                                Discounted_Price__c = invoiceLine.CenaZRabatem,                                                                                                                                                             
                                                                                Unit__c = invoiceLine.Jednostka,
                                                                                CurrencyIsoCode = customInvoiceMap.get(key).CurrencyIsoCode,
                                                                                Net_Price__c = (invoiceLine.StawkaVat != null && ifirmaInvoicesMap.get(key).LiczOd == 'BRT') ? (invoiceLine.CenaZRabatem*invoiceLine.Ilosc/(1+invoiceLine.StawkaVat)) : invoiceLine.CenaZRabatem*invoiceLine.Ilosc,
                                                                                Gross_Price__c = (invoiceLine.StawkaVat != null && ifirmaInvoicesMap.get(key).LiczOd == 'NET') ? ((invoiceLine.CenaZRabatem*invoiceLine.Ilosc)+(invoiceLine.CenaZRabatem*invoiceLine.Ilosc*invoiceLine.StawkaVat)) : invoiceLine.CenaZRabatem*invoiceLine.Ilosc ,
                                                                                Vat__c = invoiceLine.StawkaVat != null ? invoiceLine.StawkaVat*100 : 0);                                                                                                                                                                                                                                 
                        
                        invoiceLineToInsert.add(customInvoiceLine);
                    }
                }
            }
        }
        
        if(invoiceLinesToUpdate.size() > 0){
            Database.delete([SELECT Id 
                            FROM Invoice_Line__c 
                            WHERE Invoice_Custom__r.Whole_Number__c IN :invoiceLinesToUpdate.keySet()]);

            for(String key : invoiceLinesToUpdate.keySet()){
                for(SingleInvoiceJSON2Apex.Pozycje invoiceLineC : invoiceLinesToUpdate.get(key)){
                                            
                    Invoice_Line__c invoiceLine = new Invoice_Line__c(Name = invoiceLineC.NazwaPelna.length() > 80 ? invoiceLineC.NazwaPelna.substring(0,80) : invoiceLineC.NazwaPelna,
                                                                      Invoice_Custom__c = baseInvoicesWholeNumberMap.get(key.replace('_','/')).Id,
                                                                      Net_Price__c = (invoiceLineC.StawkaVat != null && ifirmaInvoicesMap.get(key).LiczOd == 'BRT') ? (invoiceLineC.CenaZRabatem*invoiceLineC.Ilosc/(1+invoiceLineC.StawkaVat)) : invoiceLineC.CenaZRabatem*invoiceLineC.Ilosc,
                                                                      Gross_Price__c = (invoiceLineC.StawkaVat != null && ifirmaInvoicesMap.get(key).LiczOd == 'NET') ? ((invoiceLineC.CenaZRabatem*invoiceLineC.Ilosc)+(invoiceLineC.CenaZRabatem*invoiceLineC.Ilosc*invoiceLineC.StawkaVat)) : invoiceLineC.CenaZRabatem*invoiceLineC.Ilosc ,
                                                                      Quantity__c = invoiceLineC.Ilosc,
                                                                      Discount_Percentage__c = invoiceLineC.Rabat,
                                                                      Discounted_Price__c = invoiceLineC.CenaZRabatem,
                                                                      Unit_Price__c = invoiceLineC.CenaJednostkowa,                                                                      
                                                                      Unit__c = invoiceLineC.Jednostka,
                                                                      Vat__c = invoiceLineC.StawkaVat != null ? invoiceLineC.StawkaVat*100 : 0 ,
                                                                      CurrencyIsoCode = invoiceCustomToUpdate.get(key).CurrencyIsoCode);
                                       
                    invoiceLineToUpdate.add(invoiceLine);
                }                                                       
            }
        }             
        
        if(invoiceLineToInsert.size()>0){
            Database.insert(invoiceLineToInsert);
        }
        if(invoiceLineToUpdate.size()>0){
            Database.insert(invoiceLineToUpdate);
        }
    }
/*
Return HttpResponse for a specific url
*/
    private static HttpResponse getRestInfoForGetMethod(String endpoint){  
        String type = 'faktura';
        String body = endpoint.substringBefore('?')+user+type;    
        String hash = hmacGenerator.generateHmacSHA1(body, key);     
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/json; charset=UTF-8');
        request.setHeader('Authentication', 'IAPIS user=' + user + ', hmac-sha1=' + hash);        
        HttpResponse response = http.send(request);
        return response;    
    }
/*
Return an invoice for specific url
*/
    public static SingleInvoiceJSON2Apex.Response getInvoiceBy(String urlSuffix, String invoiceNumber){    
        String endpoint = 'https://www.ifirma.pl/iapi/' + urlSuffix + '/' + invoiceNumber + '.json';  
        HttpResponse response = getRestInfoForGetMethod(endpoint);
      
        return SingleInvoiceJSON2Apex.parse(response.getBody()).response;        
    }
/*
Return a map with invoice whole number and invoice type dependent of date
*/
    public static Map<String, String> getInvoiceNumbersList(){
        Map<String, String> numberURLsMaps = new Map<String, String>();
        String noParameters = '';
        if(isScheduleFired){
            Date weekBeforeToday = Date.today().addDays(-7);
            numberURLsMaps = getNumberMap('?dzienOd='+weekBeforeToday.day()+'&miesiacOd='+weekBeforeToday.month()+'&rokOd='+weekBeforeToday.year());            
        }else{
            numberURLsMaps = getNumberMap(noParameters);
        }         
        return numberURLsMaps;
    }   
/*
Return a map with invoice whole number and invoice type for two urls
dependent if searching invoice for account or not
*/
    @TestVisible
    private static Map<String, String> getNumberMap(String parameters){
        Map<String, String> numMap = new Map<String, String>();
        String accountName;
        if(isAccountFired){
            accountName = [SELECT Name 
                           FROM Account 
                           WHERE id=:accountId].Name;
        }
        HttpResponse response = getRestInfoForGetMethod('https://www.ifirma.pl/iapi/fakturakraj/list.json' + parameters);
        for(InvoicesListJSON2Apex.Response i : InvoicesListJSON2Apex.parse(response.getBody()).response){
            if(isAccountFired){
                if(i.KontrahentNazwa.equals(accountName)){
                numMap.put(i.PelnyNumer.replace('/', '_'),'fakturakraj');
                }
            }else{
                numMap.put(i.PelnyNumer.replace('/', '_'),'fakturakraj');
            }
        }
        HttpResponse response2 = getRestInfoForGetMethod('https://www.ifirma.pl/iapi/fakturaeksportuslugue/list.json' + parameters);
        for(InvoicesListJSON2Apex.Response i : InvoicesListJSON2Apex.parse(response2.getBody()).response){
            if(isAccountFired){
                if(i.KontrahentNazwa.equals(accountName)){
                numMap.put(i.PelnyNumer.replace('/', '_'),'fakturaeksportuslugue');
                }
            }else{
                numMap.put(i.PelnyNumer.replace('/', '_'),'fakturaeksportuslugue');
            }
        }
        return numMap;
    }
/*
Depend of billing Country (Poland,Polska)/other create invoice at ifirma.pl service 
then save invoice to Invoice Custom Object with related Opportunity
*/
    @AuraEnabled
    public static PostResponseWrapper createInvoiceByOpportunity(Id recordId){      
System.debug('metoda odpalona z testu');
        PostResponseWrapper postResponseWrapper = new PostResponseWrapper();            
        Integer newInvoiceIdentify;
        String lineItems = '';
        String endpointPost = '';
        String endpointGet = '';
        String languageLabel = '';
        Map<String, Invoice_Custom__c> invMap =  new Map<String, Invoice_Custom__c>();
 
        Opportunity opportunityToSend = [SELECT Name, AccountId, Publish_Date__c, Sale_Date__c, Payment_Date__c, Date_Of_Tax_Obligation__c, Vat_Percentage__c
                                         FROM Opportunity
                                         WHERE Id =:recordId];
        Account oppAccount = [SELECT Name, Nip__c, BillingCity,BillingCountry,BillingStreet, BillingPostalCode
                              FROM Account 
                              WHERE id=:opportunityToSend.AccountId];  
        
        Map<String, Ifirma_Invoice_Settings__mdt> invoiceRestdata = new Map<String, Ifirma_Invoice_Settings__mdt>();
        for(Ifirma_Invoice_Settings__mdt invoiceSett : [SELECT Label, Country_Names__c, PrefiksUE__c, Authorized_Person__c, Place_Of_Creation__c, Template_Name__c, Bank_Account_Number__c, Currency_Type__c, Currency_Value__c
                                                        FROM Ifirma_Invoice_Settings__mdt]){
            invoiceRestdata.put(invoiceSett.Label, invoiceSett);
        }         
        for(String label : invoiceRestdata.keySet()){
            List<String> countries = invoiceRestdata.get(label).Country_Names__c.split(',');
            for(String country : countries){
                if(oppAccount.BillingCountry.toLowerCase().equals(country.toLowerCase())){
                    languageLabel = invoiceRestdata.get(label).Label;
                }
            }
        }    
        Ifirma_Invoice_Settings__mdt invoiceSetting = [SELECT Label, Country_Names__c, PrefiksUE__c, Authorized_Person__c, Place_Of_Creation__c, Template_Name__c, Bank_Account_Number__c, Currency_Type__c, Currency_Value__c
                                                       FROM Ifirma_Invoice_Settings__mdt
                                                       WHERE label =:languageLabel];     
        List<OpportunityLineItem> oppProductList = [SELECT Unit__c, Unit_Foreign__c,  Quantity, UnitPrice, Product2.Name
                                                    FROM OpportunityLineItem
                                                    WHERE Opportunity.Id =:recordId];
        checkAndChangeAccountingMonth(opportunityToSend.Sale_Date__c);
        String generalData = '"DataWystawienia":"'+DateTime.newInstance(opportunityToSend.Publish_Date__c.year(), opportunityToSend.Publish_Date__c.month(), opportunityToSend.Publish_Date__c.day()).format('yyyy-MM-dd')+'","DataSprzedazy":"'+DateTime.newInstance(opportunityToSend.Sale_Date__c.year(), opportunityToSend.Sale_Date__c.month(), opportunityToSend.Sale_Date__c.day()).format('yyyy-MM-dd')+'","FormatDatySprzedazy":"DZN","SposobZaplaty":"PRZ","RodzajPodpisuOdbiorcy":"OUP","WidocznyNumerGios":false,"Numer":null,"TerminPlatnosci":"'+DateTime.newInstance(opportunityToSend.Payment_Date__c.year(), opportunityToSend.Payment_Date__c.month(), opportunityToSend.Payment_Date__c.day()).format('yyyy-MM-dd')+'"';
        String account = '{"Nazwa":"'+oppAccount.Name+'","NIP":"'+oppAccount.Nip__c+'", "KodPocztowy":"'+oppAccount.BillingPostalCode+'","Kraj":"'+oppAccount.BillingCountry+'"';
        if(languageLabel.equals('Polish')){
            generalData += ',"NazwaSzablonu":"'+invoiceRestdata.get(languageLabel).Template_Name__c+'","MiejsceWystawienia":"'+invoiceRestdata.get(languageLabel).Place_Of_Creation__c+'","PodpisWystawcy":"'+invoiceRestdata.get(languageLabel).Authorized_Person__c+'","Zaplacono":0.00 ,"NIPKontrahenta":"'+oppAccount.Nip__c+'","LiczOd":"NET"';
            endpointPost = 'https://www.ifirma.pl/iapi/fakturakraj.json';
            
            if(invoiceRestdata.get(languageLabel).Bank_Account_Number__c != null){
                generalData += ',"NumerKontaBankowego":"'+invoiceRestdata.get(languageLabel).Bank_Account_Number__c+'"';
            }
        }else{
            generalData += ',"NazwaSzablonu":"'+invoiceRestdata.get(languageLabel).Template_Name__c+'","MiejsceWystawienia":"'+invoiceRestdata.get(languageLabel).Place_Of_Creation__c+'","PodpisWystawcy":"'+invoiceRestdata.get(languageLabel).Authorized_Person__c+'","NIPKontrahenta":"'+oppAccount.Nip__c+'","NazwaUslugi":"'+opportunityToSend.Name+'","Jezyk":"en","DataObowiazkuPodatkowego":"'+DateTime.newInstance(opportunityToSend.Date_Of_Tax_Obligation__c.year(), opportunityToSend.Date_Of_Tax_Obligation__c.month(), opportunityToSend.Date_Of_Tax_Obligation__c.day()).format('yyyy-MM-dd')+'","Waluta":"'+invoiceRestdata.get(languageLabel).Currency_Type__c+'","KursWalutyWidoczny":"false","KursWalutyZDniaPoprzedzajacegoDzienWystawieniaFaktury":'+invoiceRestdata.get(languageLabel).Currency_Value__c+'';
            endpointPost = 'https://www.ifirma.pl/iapi/fakturaeksportuslugue.json';
            
            if(invoiceSetting.PrefiksUE__c != null){
                generalData += ',"PrefiksUEKontrahenta":"'+invoiceSetting.PrefiksUE__c+'"';
                account += ',"PrefiksUE":"'+invoiceSetting.PrefiksUE__c+'"';
            }
            if(invoiceRestdata.get(languageLabel).Bank_Account_Number__c != null){
                generalData += ',"NumerKontaBankowego":"'+invoiceRestdata.get(languageLabel).Bank_Account_Number__c+'"';
            }
        }
        if(oppAccount.BillingCity != null){
            account += ',"Miejscowosc":"'+oppAccount.BillingCity+'"';
        }
        if(oppAccount.BillingStreet != null){
            account += ',"Ulica":"'+oppAccount.BillingStreet+'"';
        }
        account += '}';
        for(Integer i = 0; i < oppProductList.size(); i++){
            OpportunityLineItem oppLI = oppProductList.get(i);
            lineItems += '{"StawkaVat":'+ Integer.valueOf(opportunityToSend.Vat_Percentage__c)/100+',"TypStawkiVat":"PRC","Ilosc":'+oppLI.Quantity+',"CenaJednostkowa":'+oppLI.UnitPrice+',"NazwaPelna":"'+oppLI.Product2.Name+'","Jednostka":"'+oppLI.Unit__c+'"';
            if(languageLabel.equals('Polish')){
                lineItems += ',"PKWiU":""}';
            }else{
                lineItems += ',"NazwaPelnaObca":"'+oppLI.Product2.Name+'","JednostkaObca":"'+oppLI.Unit_Foreign__c+'"}';
            }
            if(i != oppProductList.size()-1){
                lineItems += ',';
            }
        } 
        String restPost = '{'+generalData+',"Pozycje":['+lineItems+'],"Kontrahent":'+account+'}';
        HttpResponse responsePost = getHttpResponse('POST', restPost, endpointPost, 'faktura');
        newInvoiceIdentify = PostResponseJSON2Apex.parse(responsePost.getBody()).response.Identyfikator;  
        if(languageLabel.equals('Polish')){
            endpointGet = 'https://www.ifirma.pl/iapi/fakturakraj/'+newInvoiceIdentify+'.json';
        }else{
            endpointGet = 'https://www.ifirma.pl/iapi/fakturaeksportuslugue/'+newInvoiceIdentify+'.json';
        }
        String invoiceName = InvoiceByIDJSON2Apex.parse(getHttpResponse('GET', '', endpointGet, 'faktura').getBody()).response.PelnyNumer;     
        saveInvoices();
        for(Invoice_Custom__c inv :[SELECT Name, Opportunity__c 
                                    FROM Invoice_Custom__c]){
            invMap.put(inv.Name, inv);
        }
        if(invMap.containsKey(invoiceName)){
            Invoice_Custom__c i = invMap.get(invoiceName);
            i.Opportunity__c = recordId;
            Database.update(i);
        }     
        postResponseWrapper.info = PostResponseJSON2Apex.parse(responsePost.getBody()).response.Informacja;
        postResponseWrapper.responseCode = PostResponseJSON2Apex.parse(responsePost.getBody()).response.Kod;
        return postResponseWrapper; 
    }  
    
    private static void checkAndChangeAccountingMonth(Datetime saleDate){  
System.debug('przed strzeleniem geta o mies ksiegowy');
        String endpoint ='https://www.ifirma.pl/iapi/abonent/miesiacksiegowy.json'; 
        HttpResponse response = getHttpResponse('GET', '', endpoint, 'abonent');
        Integer accountingMonth = AccountingMonthJSON2Apex.parse(response.getBody()).response.MiesiacKsiegowy;
System.debug('accountingMonth '+accountingMonth);
System.debug('saleDate '+saleDate);
        while(saleDate.month() != accountingMonth){
            if(saleDate.month() > accountingMonth){
                response = getHttpResponse('PUT', '{"MiesiacKsiegowy":"NAST","PrzeniesDaneZPoprzedniegoRoku":true}', endpoint, 'abonent');               
                accountingMonth++;
            }else if(saleDate.month() < accountingMonth){
                response = getHttpResponse('PUT', '{"MiesiacKsiegowy":"POPRZ","PrzeniesDaneZPoprzedniegoRoku":true}', endpoint, 'abonent');  
                accountingMonth--;
            }
        }        
    }
    private static HttpResponse getHttpResponse(String colloutType, String rest, String endpoint, String keyType){
        Ifirma_Rest_Data__mdt restdata = [SELECT User__c, Key__c, Abonent_Key__c
                                          FROM Ifirma_Rest_Data__mdt 
                                          WHERE Label='Settings' LIMIT 1];  
        String body = endpoint + restdata.User__c + keyType + rest;  
        Blob hash = Crypto.generateMac('hmacSHA1', Blob.ValueOf(body), EncodingUtil.convertFromHex( keyType == 'faktura' ? restdata.Key__c : restdata.Abonent_Key__c));  
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(colloutType);
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/json; charset=UTF-8');
        request.setHeader('Authentication', 'IAPIS user='+restdata.User__c+', hmac-sha1=' + EncodingUtil.convertToHex(hash));   
        if(colloutType.equals('POST') || colloutType.equals('PUT')){
            request.setBody(rest);
        }          
        HttpResponse response = http.send(request);

        return response;
    }
    @AuraEnabled
    public static List<String> checkFilledFields(Id recordId){       
        List<String> notFilled = new List<String>();
        Map<String, String> oppData = new Map<String, String>();
        Opportunity oppToCreateInvoice = [SELECT Date_Of_Tax_Obligation__c, Account.BillingCountry, Account.BillingCity, Account.BillingPostalCode, Payment_Date__c, Publish_Date__c, Sale_Date__c, Vat_Percentage__c
                                          FROM Opportunity
                                          WHERE ID = :recordId];
        List<Ifirma_Invoice_Settings__mdt> countriesNames = [SELECT Country_Names__c
                                                            FROM Ifirma_Invoice_Settings__mdt];
        Boolean isBillingCountryInMeta = false;
        for(Ifirma_Invoice_Settings__mdt countryNames : countriesNames){            
            List<String> countries = countryNames.Country_Names__c.split(',');
            for(String country : countries){
                if(oppToCreateInvoice.Account.BillingCountry.toLowerCase().equals(country.toLowerCase())){
                    isBillingCountryInMeta = true;
                }
            }
        }                                                        
        
        oppData.put(Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get('Date_Of_Tax_Obligation__c').getDescribe().getLabel(), String.valueOf(oppToCreateInvoice.Date_Of_Tax_Obligation__c));
        oppData.put(Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get('Payment_Date__c').getDescribe().getLabel(), String.valueOf(oppToCreateInvoice.Payment_Date__c));
        oppData.put(Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get('Publish_Date__c').getDescribe().getLabel(), String.valueOf(oppToCreateInvoice.Publish_Date__c));
        oppData.put(Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get('Sale_Date__c').getDescribe().getLabel(), String.valueOf(oppToCreateInvoice.Sale_Date__c));
        oppData.put(Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().get('Vat_Percentage__c').getDescribe().getLabel(), oppToCreateInvoice.Vat_Percentage__c);
        oppData.put(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().get('BillingCity').getDescribe().getLabel(), oppToCreateInvoice.Account.BillingCity);        
        oppData.put(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().get('BillingPostalCode').getDescribe().getLabel(), oppToCreateInvoice.Account.BillingPostalCode);
        for(String fieldKey : oppData.keySet()){
            if(oppData.get(fieldKey) == null){
                notFilled.add(fieldKey);
            }
        }         
        if([SELECT Name 
            FROM OpportunityLineItem 
            WHERE  Opportunity.id = :recordId].size() == 0){
            notFilled.add(' Add Product');
        }
        if(!isBillingCountryInMeta){
            notFilled.add(' meta data for Account Billing Country');
        }
        return notFilled;
    }
    public class PostResponseWrapper{
        @AuraEnabled 
        public String info;
        @AuraEnabled 
        public Integer responseCode;
    }
}