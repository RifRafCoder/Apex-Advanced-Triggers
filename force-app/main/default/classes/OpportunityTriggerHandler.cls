public with sharing class OpportunityTriggerHandler extends TriggerHandler {
      // Private variable to hold Trigger.new
      private List<Opportunity> newOpp;
      private List<Opportunity> oldOpp;
      private Map<Id, Opportunity> oldMap;
      private Map<Id, Opportunity> newMap;
      // Constructor
      public OpportunityTriggerHandler() {
         this.newOpp = (List<Opportunity>) Trigger.new;
         this.oldOpp = (List<Opportunity>) Trigger.old;
         this.oldMap = (Map<Id,Opportunity>) Trigger.oldMap;
         this.newMap = (Map<Id,Opportunity>) Trigger.newMap;
      }

      //Override the beforeInsert method
      //Set default Type for new Opportunities being inserted
      protected override void beforeInsert() {  
        OpportunityHelper.validateAmount(newOpp);  
        OpportunityHelper.setType(newOpp);
    }

    //Override the afterInsert method
    //Crseate a new Task for newly inserted Opportunities
      protected override void afterInsert() {    
        OpportunityHelper.createTask(newOpp);
    }

    // Override the beforeUpdate method - 
    //When an opportunity is updated validate that the amount is greater than 5000
    //When an opportunity is updated set the primary contact on the opportunity to the contact with the title of 'CEO'.
    protected override void beforeUpdate() {    
        OpportunityHelper.setPrimary(newOpp);
        OpportunityHelper.changeDesc(newOpp, oldMap);
    }

    //Append Stage changes in Opportunity Description after update
    protected override void afterUpdate() { 
    }

    // Override the beforeDelete method - When an opportunity is deleted prevent the deletion of a closed won opportunity if the account industry is 'Banking'.
    protected override void beforeDelete() {    
        OpportunityHelper.preventDeletion(oldOpp);
        OpportunityHelper.validateDelete(oldOpp);
    }

    //Override the afterDelete method - Send email notifications when an Opportunity is deleted
    protected override void afterDelete(){
        OpportunityHelper.notifyOwnersOpportunityDeleted(oldOpp);
        
    }

    //Override the afterDelete method - Send email notifications when an Opportunity is deleted
    protected override void afterUndelete(){
        OpportunityHelper.assignPrimaryContact(newMap);
        
    }


}