public with sharing class AlumniEngagementService {
    
    @AuraEnabled(cacheable=true)
    public static List<Alumni__c> getAvailableMentors(String industry, String major) {
        try {
            String query = 'SELECT Id, Name, Current_Company__c, Current_Position__c, ' +
                          'Industry__c, Major__c, Graduation_Year__c, Engagement_Score__c, ' +
                          'LinkedIn_Profile__c, Email__c FROM Alumni__c WHERE Mentoring_Available__c = true';
            
            if (!String.isBlank(industry)) {
                query += ' AND Industry__c = :industry';
            }
            if (!String.isBlank(major)) {
                query += ' AND Major__c = :major';
            }
            
            query += ' ORDER BY Engagement_Score__c DESC LIMIT 50';
            
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving mentors: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id createMentorship(Id mentorId, Id menteeId, String focusAreas, String frequency) {
        try {
            Mentorship__c mentorship = new Mentorship__c(
                Mentor__c = mentorId,
                Mentee__c = menteeId,
                Focus_Areas__c = focusAreas,
                Meeting_Frequency__c = frequency,
                Status__c = 'Active',
                Start_Date__c = Date.today()
            );
            
            insert mentorship;
            return mentorship.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating mentorship: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Mentorship__c> getActiveMentorships(Id userId, String userType) {
        try {
            List<Mentorship__c> mentorships = new List<Mentorship__c>();
            
            if (userType == 'Alumni') {
                mentorships = [
                    SELECT Id, Name, Mentee__r.Name, Mentee__r.Major__c, 
                           Focus_Areas__c, Meeting_Frequency__c, Status__c, 
                           Start_Date__c, Success_Rating__c
                    FROM Mentorship__c
                    WHERE Mentor__c = :userId AND Status__c = 'Active'
                    ORDER BY Start_Date__c DESC
                ];
            } else if (userType == 'Student') {
                mentorships = [
                    SELECT Id, Name, Mentor__r.Name, Mentor__r.Current_Company__c, 
                           Focus_Areas__c, Meeting_Frequency__c, Status__c, 
                           Start_Date__c, Success_Rating__c
                    FROM Mentorship__c
                    WHERE Mentee__c = :userId AND Status__c = 'Active'
                    ORDER BY Start_Date__c DESC
                ];
            }
            
            return mentorships;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving mentorships: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Alumni__c> getAlumniByIndustry(String industry) {
        try {
            return [
                SELECT Id, Name, Work_Industry__c, Current_Company__c, Current_Position__c
                FROM Alumni__c
                WHERE Work_Industry__c = :industry
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving alumni by industry: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Event__c> getUpcomingAlumniEvents() {
        try {
            return [
                SELECT Id, Name, Event_Type__c, Start_Date_Time__c, End_Date_Time__c,
                       Location__c, Description__c, Max_Capacity__c,
                       Target_Audience__c, Registration_Fee__c
                FROM Event__c
                WHERE Status__c = 'Registration Open' 
                AND Start_Date_Time__c > :System.now()
                AND Target_Audience__c INCLUDES ('Alumni')
                ORDER BY Start_Date_Time__c
                LIMIT 10
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving alumni events: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id registerForEvent(Id eventId, Id alumniId, String specialRequirements) {
        try {
            // Check if already registered
            List<Event_Registration__c> existing = [
                SELECT Id FROM Event_Registration__c
                WHERE Event__c = :eventId AND Alumni__c = :alumniId
            ];
            
            if (!existing.isEmpty()) {
                throw new AuraHandledException('Already registered for this event');
            }
            
            Event_Registration__c registration = new Event_Registration__c(
                Event__c = eventId,
                Alumni__c = alumniId,
                Status__c = 'Registered',
                Special_Requirements__c = specialRequirements,
                Registration_Date__c = Date.today()
            );
            
            insert registration;
            return registration.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error registering for event: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id createDonation(Id donorId, Decimal amount, String campaign, 
                                   String purpose, String paymentMethod, Boolean anonymous) {
        try {
            Donation__c donation = new Donation__c(
                Donor__c = donorId,
                Amount__c = amount,
                Campaign__c = campaign,
                Purpose__c = purpose,
                Payment_Method__c = paymentMethod,
                Status__c = 'Received',
                Anonymous__c = anonymous,
                Tax_Deductible__c = true,
                Donation_Date__c = Date.today()
            );
            
            insert donation;
            
            // Update alumni total donations
            updateAlumniTotalDonations(donorId);
            
            return donation.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating donation: ' + e.getMessage());
        }
    }
    
    private static void updateAlumniTotalDonations(Id alumniId) {
        try {
            List<AggregateResult> results = [
                SELECT SUM(Amount__c) total
                FROM Donation__c
                WHERE Donor__c = :alumniId AND Status__c = 'Received'
            ];
            
            Decimal totalDonations = (Decimal)results[0].get('total');
            if (totalDonations == null) totalDonations = 0;
            
            // Note: Total_Donations__c field not available in current Alumni object schema
            // Alumni__c alumni = new Alumni__c(
            //     Id = alumniId,
            //     Total_Donations__c = totalDonations
            // );
            // update alumni;
            
            System.debug('Total donations for alumni ' + alumniId + ': ' + totalDonations);
        } catch (Exception e) {
            System.debug('Error updating alumni total donations: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAlumniEngagementMetrics(Id alumniId) {
        try {
            Map<String, Object> metrics = new Map<String, Object>();
            
            // Get alumni record
            Alumni__c alumni = [
                SELECT Id, Name, Engagement_Score__c,
                       Willing_to_Mentor__c, Current_Company__c, Work_Industry__c
                FROM Alumni__c
                WHERE Id = :alumniId
            ];
            metrics.put('alumni', alumni);
            
            // Count active mentorships
            Integer activeMentorships = [
                SELECT COUNT()
                FROM Mentorship__c
                WHERE Mentor__c = :alumniId AND Status__c = 'Active'
            ];
            metrics.put('activeMentorships', activeMentorships);
            
            // Count event registrations this year
            Integer eventsThisYear = [
                SELECT COUNT()
                FROM Event_Registration__c
                WHERE Alumni__c = :alumniId AND Registration_Date__c = THIS_YEAR
            ];
            metrics.put('eventsThisYear', eventsThisYear);
            
            // Count donations this year
            Integer donationsThisYear = [
                SELECT COUNT()
                FROM Donation__c
                WHERE Donor__c = :alumniId AND Donation_Date__c = THIS_YEAR
            ];
            metrics.put('donationsThisYear', donationsThisYear);
            
            return metrics;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving engagement metrics: ' + e.getMessage());
        }
    }
}