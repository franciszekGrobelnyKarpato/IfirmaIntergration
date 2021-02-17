public with sharing class DataNotFullyFilledException extends Exception {   

    public void sendEmail(List<SingleInvoiceJSON2Apex.Response> accountsToCreate){         
        String emailBody = '';
        for(SingleInvoiceJSON2Apex.Response invoice : accountsToCreate){
            emailBody+= 'Faktura: ' + invoice.PelnyNumer + ' nie zostala utworzona, poniewaz brakuje w pelnij uzupelnionych pól. NIP: ' + invoice.Kontrahent.NIP + ' i/lub nazwa firmy: ' + invoice.Kontrahent.Nazwa + '\n';
        }
        sendEmailWith(emailBody);    
    }
   
    private void sendEmailWith(String emailBody){
        Ifirma_Rest_Data__mdt restdata = [SELECT Email_Addresser__c 
                                            FROM Ifirma_Rest_Data__mdt 
                                            WHERE Label='Meta' LIMIT 1];

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new string[]{restdata.Email_Addresser__c});       
        email.setSubject('komunikat: Ifirma');
        email.setPlainTextBody(emailBody) ;  
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email}); 
    }
}