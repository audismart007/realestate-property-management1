trigger LeaseAgreementTrigger on Lease_Agreement__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        List<Task> tasksToCreate = new List<Task>();
        
        for (Lease_Agreement__c lease : Trigger.new) {
            Task newTask = new Task(
                Subject = 'Generate Lease Agreement for ' + lease.Name,
                Description = 'Generate and finalize lease agreement document',
                WhatId = lease.Id,
                Status = 'Not Started',
                Priority = 'High',
                ActivityDate = Date.today().addDays(7)
            );
            tasksToCreate.add(newTask);
        }
        
        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
    }
}