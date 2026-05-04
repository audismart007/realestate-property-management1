/**
 * Scheduled class to send email reminders 30 days before lease expiry
 * Schedule: Run daily at 8 AM
 */
public class LeaseExpiryEmailScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        sendLeaseExpiryEmails();
    }
    
    /**
     * Sends email to tenants whose lease expires in 30 days
     * BULK-SAFE: Handles multiple lease agreements at once
     */
    public static void sendLeaseExpiryEmails() {
        
        // Calculate date 30 days from now
        Date thirtyDaysFromNow = Date.today().addDays(30);
        
        // Query leases expiring in 30 days that haven't been emailed yet
        List<Lease_Agreement__c> expiringLeases = [
            SELECT Id, Name, Tenant__c, Tenant__r.Tenant_Full_Name__c, 
                   Tenant__r.Email__c, Property__r.Name, End_Date__c,
                   Agreed_Monthly_Rent__c
            FROM Lease_Agreement__c
            WHERE End_Date__c = :thirtyDaysFromNow
            AND Email_Sent__c = false
            AND Tenant__r.Email__c != null
        ];
        
        if (expiringLeases.isEmpty()) {
            return; // No leases expiring
        }
        
        // Prepare emails (bulk operation)
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Lease_Agreement__c> leasesToUpdate = new List<Lease_Agreement__c>();
        
        for (Lease_Agreement__c lease : expiringLeases) {
            
            // Create email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { lease.Tenant__r.Email__c });
            email.setSubject('Lease Agreement Expiring Soon - ' + lease.Property__r.Name);
            
            String emailBody = 'Dear ' + lease.Tenant__r.Tenant_Full_Name__c + ',\n\n';
            emailBody += 'This is a reminder that your lease agreement for property "' + lease.Property__r.Name + '" ';
            emailBody += 'is expiring on ' + lease.End_Date__c.format() + ' (30 days from today).\n\n';
            emailBody += 'Lease Agreement: ' + lease.Name + '\n';
            emailBody += 'Monthly Rent: $' + lease.Agreed_Monthly_Rent__c + '\n\n';
            emailBody += 'Please contact us if you wish to renew your lease or discuss next steps.\n\n';
            emailBody += 'Best regards,\nProperty Management Team';
            
            email.setPlainTextBody(emailBody);
            emails.add(email);
            
            // Mark as emailed
            lease.Email_Sent__c = true;
            leasesToUpdate.add(lease);
        }
        
        // Send all emails at once (BULK-SAFE!)
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
        
        // Update lease records to prevent duplicate emails
        if (!leasesToUpdate.isEmpty()) {
            update leasesToUpdate;
        }
    }
}