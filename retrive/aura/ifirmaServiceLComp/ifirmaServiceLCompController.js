({    
	saveInvoicesLComp : function(component, event, helper) {  
        component.set("v.loaded", true);
        let action = component.get("c.saveInvoices");
       
        action.setCallback(this, function(response){
            let state = response.getState();
            if (state === "SUCCESS") {
                
                component.set("v.loaded", false);                 
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        type: 'Success',
                        message: "State: " + state,                     
                    });
                    toastEvent.fire();
            }else {              
                
                let errors = response.getError();
                let message = "Uknown error";
                 
                if (errors && Array.isArray(errors) && errors.length > 0) {
    				message = errors[0].message;                    
				}                
                component.set("v.loaded", false);                 
                  var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        type: 'Error',
                        message: "State: " + state + ' - ' + message,                     
                    });
                    toastEvent.fire();
            }
        });

		$A.enqueueAction(action);        
	}   
})