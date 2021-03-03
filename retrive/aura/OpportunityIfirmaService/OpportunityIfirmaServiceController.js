({	
    init : function(component, event, helper) { 
        let action = component.get("c.checkFilledFields");        
        var recordId = component.get("v.recordId");
    	action.setParams({recordId:recordId});

        action.setCallback(this, function(response){
        	let state = response.getState();    
            if(state === "SUCCESS"){
                let toastEvent = $A.get("e.force:showToast");
                let answer = response.getReturnValue() 
                if(answer.length != 0){                    
                    toastEvent.setParams({                
                        type: 'Error',                                                                                                                  
                        message:'Fill fields '+answer ,
                        mode: 'Sticky'                
                    });
                    toastEvent.fire(); 
                    component.set("v.loaded", false); 
                    $A.get("e.force:closeQuickAction").fire();
                }   
                else{                                       
                    helper.createInvoice(component);
                }                     
            }               
        });
        $A.enqueueAction(action); 
	}
})