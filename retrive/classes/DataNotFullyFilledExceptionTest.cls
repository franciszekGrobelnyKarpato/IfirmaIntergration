@isTest
public with sharing class DataNotFullyFilledExceptionTest {    

    @isTest
    public static void givenInvoiceListWhenThrowExceptionThenSendEmail(){
        //given
        List<SingleInvoiceJSON2Apex.Response> invoices = new List<SingleInvoiceJSON2Apex.Response>();
        for(Integer i=0;i<200;i++) {
            SingleInvoiceJSON2Apex.Response response = new SingleInvoiceJSON2Apex.Response();
            response.PelnyNumer='numer'+i;
            SingleInvoiceJSON2Apex.Kontrahent kontrahent = new SingleInvoiceJSON2Apex.Kontrahent();           
            response.Kontrahent = kontrahent;
            response.Kontrahent.Nazwa = 'nazwa'+i;
            response.Kontrahent.NIP='nip'+i;
            invoices.add(response);
        }
        
        //when
        Test.startTest();
        try{
            throw new DataNotFullyFilledException();
        }catch(DataNotFullyFilledException e){
            e.sendEmail(invoices);
        }
        Integer limits = Limits.getEmailInvocations();
        Test.stopTest();
        //then
        System.assertEquals(1, limits);        
    }
}