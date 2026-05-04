@isTest
public class LeaseExpiryEmailSchedulerTest {
    
    @TestSetup
    static void setupTestData() {
        Property__c property = new Property__c(
            Name = 'Test Property',
            Address__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Postal_Code__c = '12345',
            Country__c = 'Test Country',
            Type__c = 'Residential',
            Status__c = 'Occupied',
            Monthly_Rent__c = 1500,
            Description__c = 'Test property'
        );
        insert property;
        
        Tenant__c tenant = new Tenant__c(
            Tenant_Full_Name__c = 'John Doe',
            Email__c = 'john@test.com',
            Phone_Number__c = '5551234567'
        );
        insert tenant;
        
        Lease_Agreement__c lease = new Lease_Agreement__c(
            Property__c = property.Id,
            Tenant__c = tenant.Id,
            Start_Date__c = Date.today().addDays(-335),
            End_Date__c = Date.today().addDays(30),
            Agreed_Monthly_Rent__c = 1500,
            Terms__c = 'Test terms',
            Email_Sent__c = false
        );
        insert lease;
    }
    
    @isTest
    static void testEmailSent() {
        Test.startTest();
        LeaseExpiryEmailScheduler.sendLeaseExpiryEmails();
        Test.stopTest();
        
        Lease_Agreement__c lease = [SELECT Email_Sent__c FROM Lease_Agreement__c LIMIT 1];
        System.assertEquals(true, lease.Email_Sent__c);
    }
}
