@isTest
public class PropertyControllerTest {
    
    @TestSetup
    static void setupTestData() {
        List<Property__c> properties = new List<Property__c>();
        for (Integer i = 0; i < 30; i++) {
            properties.add(new Property__c(
                Name = 'Property ' + i,
                Address__c = i + ' Test Street',
                City__c = 'Test City',
                State__c = 'Test State',
                Postal_Code__c = '1234' + i,
                Country__c = 'Test Country',
                Type__c = Math.mod(i, 2) == 0 ? 'Residential' : 'Commercial',
                Status__c = Math.mod(i, 2) == 0 ? 'Available' : 'Occupied',
                Furnishing_Status__c = 'Furnished',
                Monthly_Rent__c = 1000 + (i * 100),
                Description__c = 'Test property ' + i
            ));
        }
        insert properties;
    }
    
    @isTest
    static void testGetPropertiesWithPagination() {
        Test.startTest();
        PropertyController.PropertyListResult result = PropertyController.getProperties(1, 25, null, null, 'All', 'All');
        Test.stopTest();
        
        System.assertEquals(25, result.properties.size());
        System.assertEquals(30, result.totalRecords);
        System.assertEquals(2, result.totalPages);
    }
    
    @isTest
    static void testGetPropertiesPage2() {
        Test.startTest();
        PropertyController.PropertyListResult result = PropertyController.getProperties(2, 25, null, null, 'All', 'All');
        Test.stopTest();
        
        System.assertEquals(5, result.properties.size());
    }
    
    @isTest
    static void testFilterByPrice() {
        Test.startTest();
        PropertyController.PropertyListResult result = PropertyController.getProperties(1, 25, 1000, 1500, 'All', 'All');
        Test.stopTest();
        
        System.assert(result.properties.size() > 0);
    }
    
    @isTest
    static void testFilterByStatus() {
        Test.startTest();
        PropertyController.PropertyListResult result = PropertyController.getProperties(1, 25, null, null, 'Available', 'All');
        Test.stopTest();
        
        for (Property__c prop : result.properties) {
            System.assertEquals('Available', prop.Status__c);
        }
    }
    
    @isTest
    static void testFilterByFurnishing() {
        Test.startTest();
        PropertyController.PropertyListResult result = PropertyController.getProperties(1, 25, null, null, 'All', 'Furnished');
        Test.stopTest();
        
        for (Property__c prop : result.properties) {
            System.assertEquals('Furnished', prop.Furnishing_Status__c);
        }
    }
    
    @isTest
    static void testCreatePropertyWithImages() {
        String imageData = EncodingUtil.base64Encode(Blob.valueOf('Test image content'));
        
        List<Map<String, String>> imageList = new List<Map<String, String>>();
        imageList.add(new Map<String, String>{
            'fileName' => 'test-image.jpg',
            'base64Data' => imageData
        });
        
        String imagesJson = JSON.serialize(imageList);
        
        Property__c newProp = new Property__c(
            Name = 'New Property with Image',
            Address__c = '999 Image St',
            City__c = 'Image City',
            State__c = 'Image State',
            Postal_Code__c = '99999',
            Country__c = 'Image Country',
            Type__c = 'Residential',
            Status__c = 'Available',
            Monthly_Rent__c = 3000,
            Description__c = 'Property with image'
        );
        
        Test.startTest();
        String propertyId = PropertyController.createPropertyWithImages(newProp, imagesJson);
        Test.stopTest();
        
        System.assertNotEquals(null, propertyId);
        
        List<ContentDocumentLink> links = [
            SELECT Id 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :propertyId
        ];
        System.assertEquals(1, links.size());
    }
}