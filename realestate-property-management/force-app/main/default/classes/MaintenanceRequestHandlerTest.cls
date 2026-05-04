@isTest
public class MaintenanceRequestHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        List<Vendor__c> vendors = new List<Vendor__c>();
        for (Integer i = 0; i < 3; i++) {
            vendors.add(new Vendor__c(
                Name = 'Vendor ' + i,
                Email__c = 'vendor' + i + '@test.com',
                Phone_Number__c = '555000' + i,
                Active_Requests_Count__c = 0
            ));
        }
        insert vendors;
        
        Property__c property = new Property__c(
            Name = 'Test Property',
            Address__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Postal_Code__c = '12345',
            Country__c = 'Test Country',
            Type__c = 'Residential',
            Status__c = 'Available',
            Monthly_Rent__c = 1000,
            Description__c = 'Test property description'
        );
        insert property;
    }
    
    @isTest
    static void testBulkMaintenanceRequestCreation() {
        Property__c property = [SELECT Id FROM Property__c LIMIT 1];
        
        List<Maintenance_Request__c> requests = new List<Maintenance_Request__c>();
        for (Integer i = 0; i < 200; i++) {
            requests.add(new Maintenance_Request__c(
                Property__c = property.Id,
                Status__c = 'Open',
                Description__c = 'Test request ' + i
            ));
        }
        
        Test.startTest();
        insert requests;
        Test.stopTest();
        
        List<Maintenance_Request__c> insertedRequests = [SELECT Id, Vendor__c FROM Maintenance_Request__c];
        for (Maintenance_Request__c req : insertedRequests) {
            System.assertNotEquals(null, req.Vendor__c);
        }
    }
    
    @isTest
    static void testLoadBalancing() {
        Property__c property = [SELECT Id FROM Property__c LIMIT 1];
        List<Vendor__c> vendors = [SELECT Id FROM Vendor__c ORDER BY Name];
        
        vendors[0].Active_Requests_Count__c = 5;
        vendors[1].Active_Requests_Count__c = 2;
        vendors[2].Active_Requests_Count__c = 10;
        update vendors;
        
        Test.startTest();
        Maintenance_Request__c newRequest = new Maintenance_Request__c(
            Property__c = property.Id,
            Status__c = 'Open',
            Description__c = 'New request'
        );
        insert newRequest;
        Test.stopTest();
        
        Maintenance_Request__c insertedRequest = [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :newRequest.Id];
        System.assertEquals(vendors[1].Id, insertedRequest.Vendor__c);
    }
}
