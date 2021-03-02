global class WeeklyIfirma implements Schedulable{
    global void execute(SchedulableContext ctx){
        ifirmaService.isScheduleFired = true;
        saveInvoicesAsync();
        ifirmaService.isScheduleFired = false;
    }
    @future(callout=true)
    private static void saveInvoicesAsync(){
        ifirmaService.saveInvoices();  
    }   
}