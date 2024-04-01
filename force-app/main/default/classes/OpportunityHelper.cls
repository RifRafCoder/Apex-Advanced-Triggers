public with sharing class OpportunityHelper {
    /*
    * Opportunity Trigger
    * When an opportunity is updated validate that the amount is greater than 5000.
    * Trigger should only fire on update.
    */
    public static void validateAmount(List<Opportunity> Opportunity){
        for(Opportunity opp : Opportunity){
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

     /*
    * Opportunity Trigger
    * When an opportunity is deleted prevent the deletion of a closed won opportunity if the account industry is 'Banking'.
    * OR is closed 
    * Trigger should only fire on delete.
    */
    public static void preventDeletion(List<Opportunity> Opportunity){
        //Account related to the opportunities 
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :Opportunity)]);
        for(Opportunity opp : Opportunity){
            if(opp.StageName == 'Closed Won'){
                if(accounts.get(opp.AccountId).Industry == 'Banking'){
                    opp.addError('Cannot delete closed opportunity');
                }
            }
        }
    }

    /*
    * Opportunity Trigger
    * When an opportunity is updated set the primary contact on the opportunity to the contact with the title of 'CEO'.
    * Trigger should only fire on update.
    */
    public static void setPrimary(List<Opportunity> Opportunity){
        //Get contacts related to the opportunity account
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : Opportunity){
            accountIds.add(opp.AccountId);
        }
        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        for(Opportunity opp : Opportunity){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }

    }

    /*Another Opportunity Trigger */

    // Set default Type for new Opportunities
    public static void setType(List<Opportunity> Opportunity){
        for(Opportunity opp : Opportunity){
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }   
        }   
    }

    // Prevent deletion of closed Opportunities -  
    public static void validateDelete(List<Opportunity> oldOpps){
        for (Opportunity oldOpp : oldOpps){
            if (oldOpp.IsClosed){
                oldOpp.addError('Cannot delete closed opportunity');
            }
        }
    }

    // Create a new Task for newly inserted Opportunities
    public static void createTask(List<Opportunity> Opportunity){
        List<Task> tasksToInsert = new List<Task>();
        for (Opportunity opp : Opportunity){
            Task tsk = new Task();
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = opp.Id;
            tsk.WhoId = opp.Primary_Contact__c;
            tsk.OwnerId = opp.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3);
            tasksToInsert.add(tsk);
        }
        insert tasksToInsert;
    }            

    // Append Stage changes in Opportunity Description
    public static void changeDesc(List<Opportunity> Opportunity, Map<Id,Opportunity> oldOppMap){

        for (Opportunity opp : Opportunity){
            //Trigger.oldMap<Id, Opportunity>
            Opportunity oldOpp = oldOppMap.get(opp.Id); // holds all old opps info
            if (opp.StageName != oldOpp.StageName){
                opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
            }                
        }
    }

    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */
    public static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        // Query User records using Maps
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email FROM User]);
        for (Opportunity opp : opps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // Get the email address for the owner from the map
            User oppOwner = userMap.get(opp.OwnerId);
            String[] toAddresses = new List<String>{oppOwner.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }

    }

    /*
    assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact.
    */
    public static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Set<Id> oppAccountIds = new Set<Id>();
        for(Opportunity opp : oppNewMap.values()){
            oppAccountIds.add(opp.AccountId);
        }
        List<Contact> primaryContacts = [SELECT Id, AccountId FROM Contact WHERE Title = 'VP Sales' AND AccountId IN :oppAccountIds];
        //Creat map to align accountIds with contacts
        Map<Id,Contact> accountIdToContactMap = new Map<Id,Contact>();
        //loop over primary contacts
        for(Contact cont : primaryContacts){
            accountIdToContactMap.put(cont.AccountId, cont);
        }

        for (Opportunity opp : oppNewMap.values()){            
            if (opp.Primary_Contact__c == null){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                //accountIdToContactMap.get(opp.AccountId) - holds entire contact info - need to access Id to set contact
                oppToUpdate.Primary_Contact__c = accountIdToContactMap.get(opp.AccountId).Id;
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
        update oppMap.values();
    }
}