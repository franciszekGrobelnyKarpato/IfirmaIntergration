({	
    init : function(component, event, helper) { 
       
        let action = component.get("c.saveAccountInvoices");        
        var recordId = component.get("v.recordId");
    	action.setParams({recordId:recordId});
        
        action.setCallback(this, function(response){
        	let state = response.getState();
                        
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    type: 'Success',
                    message: "State: " + state ,                     
                }); 
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