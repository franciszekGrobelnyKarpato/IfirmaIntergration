({	
    init : function(component, event, helper) { 
       
        let action = component.get("c.createInvoiceByOpportunity");        
        var recordId = component.get("v.recordId");
    	action.setParams({recordId:recordId});
        
        action.setCallback(this, function(response){
        	let state = response.getState();                 
            let responseCode = JSON.stringify(response.getReturnValue().responseCode);
                        
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                if(responseCode === "0"){
                    toastEvent.setParams({                
                        type: 'Success',                                        
                        title: JSON.stringify(response.getReturnValue().info) ,                          
                        message:'Login into Ifirma.pl service to edit or delete invoice.'                   
                    }); 
                }else{
                    toastEvent.setParams({                
                        type: 'Error',                                        
                        message: JSON.stringify(response.getReturnValue().info) ,  
                        mode: 'Sticky',                                                                
                    }); 
                }                
                toastEvent.fire(); 
            }else {              
                
                let errors = response.getError();
                let message = "Uknown error";
                
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;                    
                }                                                   
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    type: 'Error',
                    message: "State: " + state + ' - ' + message,                     
                });
                toastEvent.fire();
            }
                       
    		component.set("v.loaded", false);   
            $A.get("e.force:closeQuickAction").fire();
        });

		$A.enqueueAction(action);   
	}
})