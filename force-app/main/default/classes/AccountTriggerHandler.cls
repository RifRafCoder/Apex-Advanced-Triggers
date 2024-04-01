public with sharing class AccountTriggerHandler extends TriggerHandler {

    // Private variable to hold Trigger.new
    private List<Account> newAccounts;

     // Constructor
     public AccountTriggerHandler() {
        this.newAccounts = (List<Account>) Trigger.new;
     }
    
    // Override the beforeInsert method to set account type to 'Prospect'and set rating
    protected override void beforeInsert() {
        AccountHelper.setTypeProspect(newAccounts);
        AccountHelper.setRating(newAccounts);
        AccountHelper.addressCopy(newAccounts);
    }

    // Override the beforeUpdate method to copy shipping address to billing address
    protected override void beforeUpdate() {    
    
    }

    // Override the afterInsert method create default contact
    protected override void afterInsert() {
        AccountHelper.defaultContact(newAccounts);
    }

}
