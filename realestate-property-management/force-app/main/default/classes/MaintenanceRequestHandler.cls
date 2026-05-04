public class MaintenanceRequestHandler {
    
    public static void assignVendorWithLeastWorkload(List<Maintenance_Request__c> newRequests) {
        List<Vendor__c> vendors = [
            SELECT Id, Active_Requests_Count__c 
            FROM Vendor__c 
            ORDER BY Active_Requests_Count__c ASC NULLS FIRST
            LIMIT 1
        ];
        
        if (vendors.isEmpty()) return;
        
        Vendor__c leastLoadedVendor = vendors[0];
        
        for (Maintenance_Request__c request : newRequests) {
            if (request.Vendor__c == null) {
                request.Vendor__c = leastLoadedVendor.Id;
            }
        }
    }
    
    public static void updateVendorWorkloadCounts(
        List<Maintenance_Request__c> newRequests, 
        Map<Id, Maintenance_Request__c> oldRequestsMap
    ) {
        Set<Id> vendorIds = new Set<Id>();
        
        for (Maintenance_Request__c request : newRequests) {
            if (request.Vendor__c != null) {
                vendorIds.add(request.Vendor__c);
            }
            
            if (oldRequestsMap != null && oldRequestsMap.containsKey(request.Id)) {
                Maintenance_Request__c oldRequest = oldRequestsMap.get(request.Id);
                if (oldRequest.Vendor__c != null && oldRequest.Vendor__c != request.Vendor__c) {
                    vendorIds.add(oldRequest.Vendor__c);
                }
            }
        }
        
        List<Vendor__c> vendorsToUpdate = [SELECT Id FROM Vendor__c WHERE Id IN :vendorIds];
        
        Map<Id, Integer> vendorCountMap = new Map<Id, Integer>();
        
        for (AggregateResult ar : [
            SELECT Vendor__c, COUNT(Id) cnt
            FROM Maintenance_Request__c
            WHERE Vendor__c IN :vendorIds
            AND Status__c IN ('Open', 'In Progress')
            GROUP BY Vendor__c
        ]) {
            vendorCountMap.put((Id)ar.get('Vendor__c'), (Integer)ar.get('cnt'));
        }
        
        for (Vendor__c vendor : vendorsToUpdate) {
            vendor.Active_Requests_Count__c = vendorCountMap.containsKey(vendor.Id) 
                ? vendorCountMap.get(vendor.Id) 
                : 0;
        }
        
        if (!vendorsToUpdate.isEmpty()) {
            update vendorsToUpdate;
        }
    }
}