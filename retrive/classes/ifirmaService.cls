public  class ifirmaService {

    @TestVisible private static Map<String, List<SingleInvoiceJSON2Apex.Pozycje>> invoiceLineMap = new Map<String, List<SingleInvoiceJSON2Apex.Pozycje>>();
    @TestVisible private static Map<String, Invoice_Custom__c> customInvoiceMap = new Map<String, Invoice_Custom__c>();
    @TestVisible private static Map<String, Account> baseAccountsNIPMap = new Map<String, Account>();   
    @TestVisible private static Map<String, Invoice_Custom__c> baseInvoicesWholeNumberMap = new Map<String, Invoice_Custom__c>();
    @TestVisible private static Map<String, Invoice_Line__c> baseInvoiceLinesWholeNumberMap = new Map<String, Invoice_Line__c>();
    @TestVisible private static Map<String, Invoice_Custom__c> invoiceCustomToUpdate = new Map<String, Invoice_Custom__c>();
    @TestVisible private static Map<String, SingleInvoiceJSON2Apex.Response> ifirmaInvoicesMap = new Map<String, SingleInvoiceJSON2Apex.Response>();
    @TestVisible private static Map<String, List<SingleInvoiceJSON2Apex.Pozycje>>  invoiceLinesToUpdate = new Map<String, List<SingleInvoiceJSON2Apex.Pozycje>>();
    public static Map<String, String> numberURLsMap = new Map<String, String>();  
    public static Map<String, contentVersion> cvMap = new Map<String, contentVersion>();    
    @TestVisible public static String user;
    @TestVisible public static String key;      

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
    @TestVisible
    private static void savePDF(){        
        AggregateResult invoicesAmount = [select count(Id)amount FROM Invoice_Custom__c];
        if(Integer.valueOf(invoicesAmount.get('amount')) > 0){ 
               
        
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
            
            deleteOldPDfs(cvMap);
            Database.insert(cvMap.values());    
                  
        }    
    }   
    
    @TestVisible
    private static void deleteOldPDfs(Map<String, contentVersion> cvMap){
        Set<id> cvSet = new Set<id>();
        List<Invoice_Custom__c> invoices = [SELECT  name FROM invoice_Custom__c];
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
                                            WHERE Label='Meta' LIMIT 1];  
        user = restdata.User__c;
        key = restdata.Key__c;
    }

    @TestVisible
    private static void getWholeInvoicesFromIfirma(){
        numberURLsMap = getInvoiceNumbersList();
        for(String invoiceNumber : numberURLsMap.keySet()){
            SingleInvoiceJSON2Apex.Response invoice = getInvoiceBy(numberURLsMap.get(invoiceNumber), invoiceNumber); 
            ifirmaInvoicesMap.put(invoice.PelnyNumer.replace('/', '_'), invoice);
        }
    }

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

    @TestVisible
    private static void createOrUpdateInvoiceCustomObject(){
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();

        for(SingleInvoiceJSON2Apex.Response invoice : ifirmaInvoicesMap.values()){    
            if(!baseInvoicesWholeNumberMap.containsKey(invoice.PelnyNumer) && baseAccountsNIPMap.containsKey(invoice.Kontrahent.NIP)){ 
                Invoice_Custom__c invoiceCustom = new Invoice_Custom__c(Name = invoice.PelnyNumer,
                                                                        date_of_invoice__c = Date.valueOf(invoice.DataWystawienia),
                                                                        sale_date__c = Date.valueOf(invoice.DataSprzedazy), 
                                                                        Whole_Number__c = invoice.PelnyNumer.replace('/','_'),
                                                                        date_of_payment__c = Date.valueOf(invoice.TerminPlatnosci),
                                                                        method_of_payment__c = invoice.SposobZaplaty,
                                                                        Account__c = baseAccountsNIPMap.get(invoice.Kontrahent.NIP).Id,
                                                                        CurrencyIsoCode = invoice.Waluta != null ? invoice.Waluta : 'PLN');                
                customInvoiceMap.put(invoice.PelnyNumer.replace('/','_'), invoiceCustom);  
                invoiceLineMap.put(invoice.PelnyNumer.replace('/','_'), invoice.Pozycje);   
                
            }else if(baseInvoicesWholeNumberMap.containsKey(invoice.PelnyNumer) && baseAccountsNIPMap.containsKey(invoice.Kontrahent.NIP)){
                Invoice_Custom__c invoiceCustom = baseInvoicesWholeNumberMap.get(invoice.PelnyNumer);
                invoiceCustom.Name = invoice.PelnyNumer;
                invoiceCustom.date_of_invoice__c = Date.valueOf(invoice.DataWystawienia);
                invoiceCustom.sale_date__c = Date.valueOf(invoice.DataSprzedazy);
                invoiceCustom.Whole_Number__c = invoice.PelnyNumer.replace('/','_');
                invoiceCustom.date_of_payment__c = Date.valueOf(invoice.TerminPlatnosci);
                invoiceCustom.method_of_payment__c = invoice.SposobZaplaty;
                invoiceCustom.Account__c = baseAccountsNIPMap.get(invoice.Kontrahent.NIP).Id;

                if(invoice.Waluta != null){
                    invoiceCustom.CurrencyIsoCode = invoice.Waluta;
                }else{
                    invoiceCustom.CurrencyIsoCode = 'PLN';
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
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT contentDocumentId 
                                     FROM contentVersion 
                                     WHERE id =:cv.id].contentDocumentId;
            if(customInvoiceMap.containsKey(cv.title.replace('/','_'))){
                cdl.LinkedEntityId = customInvoiceMap.get(cv.title.replace('/','_')).id;
            }
            if(invoiceCustomToUpdate.containsKey(cv.title.replace('/','_'))){
                cdl.LinkedEntityId = invoiceCustomToUpdate.get(cv.title.replace('/','_')).id;
            }            
            cdl.Visibility = 'AllUsers';
            cdlList.add(cdl);
        }       
        Database.insert(cdlList);  
    }

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
                                                                                Legal_Basis__c = invoiceLine.PodstawaPrawna,
                                                                                Unit__c = invoiceLine.Jednostka,
                                                                                CurrencyIsoCode = customInvoiceMap.get(key).CurrencyIsoCode,
                                                                                Net_Price__c = (invoiceLine.StawkaVat != null && ifirmaInvoicesMap.get(key).LiczOd == 'BRT') ? (invoiceLine.CenaZRabatem*invoiceLine.Ilosc/(1+invoiceLine.StawkaVat)) : invoiceLine.CenaZRabatem*invoiceLine.Ilosc,
                                                                                Gross_Price__c = (invoiceLine.StawkaVat != null && ifirmaInvoicesMap.get(key).LiczOd == 'NET') ? ((invoiceLine.CenaZRabatem*invoiceLine.Ilosc)+(invoiceLine.CenaZRabatem*invoiceLine.Ilosc*invoiceLine.StawkaVat)) : invoiceLine.CenaZRabatem*invoiceLine.Ilosc ,
                                                                                Vat__c = invoiceLine.StawkaVat);                                                                                                                                                 
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
                                                                      Legal_Basis__c = invoiceLineC.PodstawaPrawna,
                                                                      Unit__c = invoiceLineC.Jednostka,
                                                                      Vat__c = invoiceLineC.StawkaVat,
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

    private static HttpResponse getRestInfoForGetMethod(String endpoint){  
        String type = 'faktura';
        String body = endpoint+user+type;    
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

    public static SingleInvoiceJSON2Apex.Response getInvoiceBy(String urlSuffix, String invoiceNumber){    
        String endpoint = 'https://www.ifirma.pl/iapi/' + urlSuffix + '/' + invoiceNumber + '.json';  
        HttpResponse response = getRestInfoForGetMethod(endpoint);
      
        return SingleInvoiceJSON2Apex.parse(response.getBody()).response;        
    }

    public static Map<String, String> getInvoiceNumbersList(){
        Map<String, String> numberURLsMaps = new Map<String, String>();
 
        String endpoint = 'https://www.ifirma.pl/iapi/fakturakraj/list.json';
        HttpResponse response = getRestInfoForGetMethod(endpoint);
        for(InvoicesListJSON2Apex.Response i : InvoicesListJSON2Apex.parse(response.getBody()).response){
            numberURLsMaps.put(i.PelnyNumer.replace('/', '_'),'fakturakraj');
        }
        HttpResponse response2 = getRestInfoForGetMethod('https://www.ifirma.pl/iapi/fakturaeksportuslugue/list.json');
        for(InvoicesListJSON2Apex.Response i : InvoicesListJSON2Apex.parse(response2.getBody()).response){
            numberURLsMaps.put(i.PelnyNumer.replace('/', '_'),'fakturaeksportuslugue');
        }  
               
        return numberURLsMaps;
    }   
}