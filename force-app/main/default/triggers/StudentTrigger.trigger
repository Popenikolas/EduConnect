trigger StudentTrigger on Student__c (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // Simple logging or basic operations can be added here
            System.debug('StudentTrigger executed for ' + Trigger.new.size() + ' students');
        }
    }
}