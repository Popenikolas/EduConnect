public class StudentTriggerHandler {
    
    @future
    public static void calculateRiskScoresAsync(Set<Id> studentIds) {
        for (Id studentId : studentIds) {
            try {
                StudentRiskAssessmentService.calculateRiskScore(studentId);
            } catch (Exception e) {
                System.debug('Error calculating risk score for student ' + studentId + ': ' + e.getMessage());
            }
        }
    }
    
    public static void updateEngagementScores(List<Student__c> students) {
        try {
            for (Student__c student : students) {
                // Calculate engagement score based on various activities
                Decimal engagementScore = 0;
                
                // Event participation (30% weight)
                Integer eventParticipation = [
                    SELECT COUNT()
                    FROM Event_Registration__c
                    WHERE Student__c = :student.Id
                    AND Status__c = 'Attended'
                    AND Registration_Date__c = THIS_YEAR
                ];
                engagementScore += Math.min(eventParticipation * 5, 30);
                
                // Support case resolution (20% weight)
                Integer resolvedCases = [
                    SELECT COUNT()
                    FROM Student_Support_Case__c
                    WHERE Student__c = :student.Id
                    AND Status__c = 'Resolved'
                    AND Created_Date__c = THIS_YEAR
                ];
                engagementScore += Math.min(resolvedCases * 10, 20);
                
                // Academic performance (50% weight)
                if (student.GPA__c != null) {
                    engagementScore += (student.GPA__c / 4.0) * 50;
                }
                
                // Update student record (you'd add an Engagement_Score__c field)
                // student.Engagement_Score__c = engagementScore;
            }
            
        } catch (Exception e) {
            System.debug('Error updating engagement scores: ' + e.getMessage());
        }
    }
}