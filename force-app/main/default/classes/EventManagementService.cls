public with sharing class EventManagementService {
    
    @AuraEnabled(cacheable=true)
    public static List<Event__c> getUpcomingEvents(String targetAudience) {
        try {
            String query = 'SELECT Id, Name, Event_Type__c, Start_Date_Time__c, End_Date_Time__c, ' +
                          'Location__c, Description__c, Max_Capacity__c, ' +
                          'Target_Audience__c, Registration_Fee__c, Status__c ' +
                          'FROM Event__c WHERE Start_Date_Time__c > :System.now() ' +
                          'AND Status__c IN (\'Registration Open\', \'Planning\')';
            
            if (!String.isBlank(targetAudience)) {
                query += ' AND Target_Audience__c INCLUDES (\'' + targetAudience + '\')';
            }
            
            query += ' ORDER BY Start_Date_Time__c LIMIT 20';
            
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving events: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id createEvent(String name, String eventType, DateTime startDateTime, 
                                DateTime endDateTime, String location, String description,
                                Integer maxCapacity, String targetAudience, Decimal registrationFee) {
        try {
            Event__c event = new Event__c(
                Name = name,
                Event_Type__c = eventType,
                Start_Date_Time__c = startDateTime,
                End_Date_Time__c = endDateTime,
                Location__c = location,
                Description__c = description,
                Max_Capacity__c = maxCapacity,
                Target_Audience__c = targetAudience,
                Registration_Fee__c = registrationFee,
                Status__c = 'Planning',
                Event_Organizer__c = UserInfo.getUserId()
            );
            
            insert event;
            return event.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating event: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id registerStudentForEvent(Id eventId, Id studentId, String specialRequirements) {
        try {
            // Check capacity
            Event__c event = [
                SELECT Max_Capacity__c
                FROM Event__c
                WHERE Id = :eventId
            ];
            
            // Count current registrations
            Integer currentRegistrations = [
                SELECT COUNT()
                FROM Event_Registration__c
                WHERE Event__c = :eventId
            ];
            
            if (event.Max_Capacity__c != null && 
                currentRegistrations >= event.Max_Capacity__c) {
                throw new AuraHandledException('Event is at full capacity');
            }
            
            // Check if already registered
            List<Event_Registration__c> existing = [
                SELECT Id FROM Event_Registration__c
                WHERE Event__c = :eventId AND Student__c = :studentId
            ];
            
            if (!existing.isEmpty()) {
                throw new AuraHandledException('Student already registered for this event');
            }
            
            Event_Registration__c registration = new Event_Registration__c(
                Event__c = eventId,
                Student__c = studentId,
                Status__c = 'Registered',
                Special_Requirements__c = specialRequirements,
                Registration_Date__c = Date.today(),
                Payment_Status__c = event.Registration_Fee__c > 0 ? 'Pending' : 'N/A'
            );
            
            insert registration;
            return registration.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error registering for event: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Event_Registration__c> getEventRegistrations(Id eventId) {
        try {
            return [
                SELECT Id, Name, Student__r.Name, Student__r.Student_ID__c, Student__r.Email__c,
                       Alumni__r.Name, Alumni__r.Email__c, Status__c, Payment_Status__c,
                       Special_Requirements__c, Registration_Date__c
                FROM Event_Registration__c
                WHERE Event__c = :eventId
                ORDER BY Registration_Date__c DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving event registrations: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateEventStatus(Id eventId, String newStatus) {
        try {
            Event__c event = new Event__c(
                Id = eventId,
                Status__c = newStatus
            );
            update event;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating event status: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void markAttendance(Id registrationId, Boolean attended) {
        try {
            Event_Registration__c registration = new Event_Registration__c(
                Id = registrationId,
                Status__c = attended ? 'Attended' : 'No Show'
            );
            update registration;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating attendance: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getEventAnalytics(Id eventId) {
        try {
            Map<String, Object> analytics = new Map<String, Object>();
            
            // Get event details
            Event__c event = [
                SELECT Id, Name, Event_Type__c, Start_Date_Time__c, Max_Capacity__c,
                       Status__c
                FROM Event__c
                WHERE Id = :eventId
            ];
            analytics.put('event', event);
            
            // Registration statistics
            List<AggregateResult> regStats = [
                SELECT Status__c, COUNT(Id) registrationCount
                FROM Event_Registration__c
                WHERE Event__c = :eventId
                GROUP BY Status__c
            ];
            
            Map<String, Integer> statusCount = new Map<String, Integer>();
            for (AggregateResult ar : regStats) {
                statusCount.put((String)ar.get('Status__c'), (Integer)ar.get('registrationCount'));
            }
            analytics.put('registrationStats', statusCount);
            
            // Attendance rate
            Integer totalRegistrations = [SELECT COUNT() FROM Event_Registration__c WHERE Event__c = :eventId];
            Integer attended = statusCount.get('Attended') != null ? statusCount.get('Attended') : 0;
            Decimal attendanceRate = totalRegistrations > 0 ? 
                (Decimal.valueOf(attended) / Decimal.valueOf(totalRegistrations)) * 100 : 0;
            analytics.put('attendanceRate', attendanceRate);
            
            return analytics;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving event analytics: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Event__c> getEventsByOrganizer(Id organizerId) {
        try {
            return [
                SELECT Id, Name, Event_Type__c, Start_Date_Time__c, Status__c,
                       Max_Capacity__c
                FROM Event__c
                WHERE Event_Organizer__c = :organizerId
                ORDER BY Start_Date_Time__c DESC
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving organizer events: ' + e.getMessage());
        }
    }
}