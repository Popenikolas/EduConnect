public with sharing class AcademicEventController {
    
    @AuraEnabled(cacheable=true)
    public static List<Event__c> getAcademicEvents() {
        try {
            return [
                SELECT Id, Name, Start_Date_Time__c, End_Date_Time__c, Location__c, 
                       Event_Type__c, Description__c, Status__c
                FROM Event__c 
                WHERE Event_Type__c = 'Academic' 
                  AND Start_Date_Time__c >= TODAY 
                ORDER BY Start_Date_Time__c ASC
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving academic events: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Event__c> getUpcomingEvents() {
        try {
            return [
                SELECT Id, Name, Start_Date_Time__c, End_Date_Time__c, Location__c, 
                       Event_Type__c, Description__c, Status__c, Max_Capacity__c
                FROM Event__c 
                WHERE Start_Date_Time__c >= :System.now() 
                  AND Status__c IN ('Registration Open', 'Planning')
                ORDER BY Start_Date_Time__c ASC
                LIMIT 10
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving upcoming events: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id createEvent(String name, DateTime startDateTime, DateTime endDateTime, 
                                String location, String eventType, String description) {
        try {
            Event__c newEvent = new Event__c(
                Name = name,
                Start_Date_Time__c = startDateTime,
                End_Date_Time__c = endDateTime,
                Location__c = location,
                Event_Type__c = eventType,
                Description__c = description,
                Status__c = 'Planning'
            );
            
            insert newEvent;
            return newEvent.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating event: ' + e.getMessage());
        }
    }
}