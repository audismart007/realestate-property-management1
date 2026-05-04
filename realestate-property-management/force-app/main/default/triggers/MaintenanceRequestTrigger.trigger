trigger MaintenanceRequestTrigger on Maintenance_Request__c (before insert, after insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        MaintenanceRequestHandler.assignVendorWithLeastWorkload(Trigger.new);
    }
    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        MaintenanceRequestHandler.updateVendorWorkloadCounts(Trigger.new, Trigger.oldMap);
    }
}