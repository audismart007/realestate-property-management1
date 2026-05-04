public with sharing class PropertyController {
    
    /**
     * Get properties with pagination and filters
     * Server-side pagination for efficient handling of large datasets
     */
    @AuraEnabled(cacheable=true)
    public static PropertyListResult getProperties(
        Integer pageNumber, 
        Integer pageSize,
        Decimal minPrice,
        Decimal maxPrice,
        String statusFilter,
        String furnishingFilter
    ) {
        // Default pagination values
        if (pageSize == null) pageSize = 25;
        if (pageNumber == null) pageNumber = 1;
        
        // Calculate offset for pagination
        Integer offset = (pageNumber - 1) * pageSize;
        
        // Build dynamic SOQL query
        String query = 'SELECT Id, Name, Address__c, City__c, State__c, Monthly_Rent__c, ' +
                      'Status__c, Furnishing_Status__c, Type__c ' +
                      'FROM Property__c WHERE Id != null';
        
        String countQuery = 'SELECT COUNT() FROM Property__c WHERE Id != null';
        
        // Add filters dynamically
        if (minPrice != null) {
            query += ' AND Monthly_Rent__c >= ' + minPrice;
            countQuery += ' AND Monthly_Rent__c >= ' + minPrice;
        }
        
        if (maxPrice != null) {
            query += ' AND Monthly_Rent__c <= ' + maxPrice;
            countQuery += ' AND Monthly_Rent__c <= ' + maxPrice;
        }
        
        if (String.isNotBlank(statusFilter) && statusFilter != 'All') {
            query += ' AND Status__c = \'' + String.escapeSingleQuotes(statusFilter) + '\'';
            countQuery += ' AND Status__c = \'' + String.escapeSingleQuotes(statusFilter) + '\'';
        }
        
        if (String.isNotBlank(furnishingFilter) && furnishingFilter != 'All') {
            query += ' AND Furnishing_Status__c = \'' + String.escapeSingleQuotes(furnishingFilter) + '\'';
            countQuery += ' AND Furnishing_Status__c = \'' + String.escapeSingleQuotes(furnishingFilter) + '\'';
        }
        
        query += ' ORDER BY CreatedDate DESC LIMIT ' + pageSize + ' OFFSET ' + offset;
        
        // Execute queries
        List<Property__c> properties = Database.query(query);
        Integer totalRecords = Database.countQuery(countQuery);
        
        // Return wrapper with data and pagination info
        PropertyListResult result = new PropertyListResult();
        result.properties = properties;
        result.totalRecords = totalRecords;
        result.pageNumber = pageNumber;
        result.pageSize = pageSize;
        result.totalPages = (Integer)Math.ceil((Decimal)totalRecords / pageSize);
        
        return result;
    }
    
    /**
     * Create property with images
     * Handles bulk image upload using ContentVersion
     */
    @AuraEnabled
    public static String createPropertyWithImages(
        Property__c property,
        String imagesJson
    ) {
        try {
            // Step 1: Insert property
            insert property;
            
            // Step 2: Parse image data
            if (String.isNotBlank(imagesJson)) {
                List<ImageData> images = (List<ImageData>)JSON.deserialize(imagesJson, List<ImageData>.class);
                
                if (images.isEmpty()) {
                    throw new AuraHandledException('At least one image is required');
                }
                
                // Step 3: Create ContentVersions (bulk insert)
                List<ContentVersion> contentVersions = new List<ContentVersion>();
                
                for (ImageData img : images) {
                    ContentVersion cv = new ContentVersion();
                    cv.Title = img.fileName;
                    cv.PathOnClient = img.fileName;
                    cv.VersionData = EncodingUtil.base64Decode(img.base64Data);
                    cv.IsMajorVersion = true;
                    contentVersions.add(cv);
                }
                
                insert contentVersions;
                
                // Step 4: Get ContentDocumentIds
                Set<Id> cvIds = new Set<Id>();
                for (ContentVersion cv : contentVersions) {
                    cvIds.add(cv.Id);
                }
                
                List<ContentVersion> insertedCVs = [
                    SELECT Id, ContentDocumentId 
                    FROM ContentVersion 
                    WHERE Id IN :cvIds
                ];
                
                // Step 5: Link images to property (bulk insert)
                List<ContentDocumentLink> cdLinks = new List<ContentDocumentLink>();
                
                for (ContentVersion cv : insertedCVs) {
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = cv.ContentDocumentId;
                    cdl.LinkedEntityId = property.Id;
                    cdl.ShareType = 'V'; // Viewer permission
                    cdl.Visibility = 'AllUsers';
                    cdLinks.add(cdl);
                }
                
                insert cdLinks;
            } else {
                throw new AuraHandledException('At least one image is required');
            }
            
            return property.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating property: ' + e.getMessage());
        }
    }
    
    /**
     * Wrapper class for property list results
     */
    public class PropertyListResult {
        @AuraEnabled public List<Property__c> properties;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Integer pageNumber;
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public Integer totalPages;
    }
    
    /**
     * Wrapper for image data from LWC
     */
    public class ImageData {
        public String fileName;
        public String base64Data;
    }
}