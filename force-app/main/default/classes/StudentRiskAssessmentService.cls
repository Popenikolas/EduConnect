public without sharing class StudentRiskAssessmentService {
    
    @AuraEnabled
    public static void calculateRiskScore(Id studentId) {
        try {
            Student__c student = [
                SELECT Id, GPA__c, Academic_Status__c, 
                       Credits_in_Progress__c, Year_Level__c
                FROM Student__c
                WHERE Id = :studentId
            ];
            
            Decimal riskScore = 0;
            
            // GPA factor (40% weight)
            if (student.GPA__c != null) {
                if (student.GPA__c < 2.0) {
                    riskScore += 40;
                } else if (student.GPA__c < 2.5) {
                    riskScore += 30;
                } else if (student.GPA__c < 3.0) {
                    riskScore += 20;
                } else if (student.GPA__c < 3.5) {
                    riskScore += 10;
                }
            }
            
            // Academic Status factor (30% weight)
            if (student.Academic_Status__c == 'Academic Suspension') {
                riskScore += 30;
            } else if (student.Academic_Status__c == 'Academic Probation') {
                riskScore += 25;
            } else if (student.Academic_Status__c == 'Academic Warning') {
                riskScore += 15;
            }
            
            // Course Load factor (20% weight)
            if (student.Credits_in_Progress__c != null) {
                if (student.Credits_in_Progress__c < 12) {
                    riskScore += 15;
                } else if (student.Credits_in_Progress__c > 18) {
                    riskScore += 10;
                }
            }
            
            // Support case factor (10% weight)
            Integer openCases = [
                SELECT COUNT()
                FROM Student_Support_Case__c
                WHERE Student__c = :studentId 
                AND Status__c IN ('Open', 'In Progress')
                AND Priority__c IN ('High', 'Critical')
            ];
            
            if (openCases > 2) {
                riskScore += 10;
            } else if (openCases > 0) {
                riskScore += 5;
            }
            
            // Update student risk score
            student.Risk_Score__c = riskScore;
            update student;
            
            // Create intervention if high risk
            if (riskScore >= 70) {
                createInterventionAlert(studentId, riskScore);
            }
            
        } catch (Exception e) {
            System.debug('Error calculating risk score: ' + e.getMessage());
            throw new AuraHandledException('Error calculating risk score: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void createInterventionAlert(Id studentId, Decimal riskScore) {
        try {
            String priority = riskScore >= 80 ? 'Critical' : 'High';
            String subject = 'Student At Risk - Risk Score: ' + riskScore;
            String description = 'Student has been identified as at-risk with a score of ' + 
                               riskScore + '. Immediate intervention recommended.';
            
            Student_Support_Case__c alertCase = new Student_Support_Case__c(
                Student__c = studentId,
                Subject__c = subject,
                Description__c = description,
                Priority__c = priority,
                Category__c = 'Academic',
                Status__c = 'Open',
                Created_Date__c = Date.today()
            );
            
            insert alertCase;
            
            // Send email notification to advisors
            sendAdvisorNotification(studentId, riskScore);
            
        } catch (Exception e) {
            System.debug('Error creating intervention alert: ' + e.getMessage());
        }
    }
    
    private static void sendAdvisorNotification(Id studentId, Decimal riskScore) {
        try {
            Student__c student = [
                SELECT Name, Student_ID__c, Email__c, Major__c
                FROM Student__c
                WHERE Id = :studentId
            ];
            
            // Get advisor email (simplified - in real implementation, you'd have advisor assignment logic)
            List<User> advisors = [
                SELECT Email
                FROM User
                WHERE Profile.Name = 'Academic Advisor' AND IsActive = true
                LIMIT 1
            ];
            
            if (!advisors.isEmpty()) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{advisors[0].Email});
                email.setSubject('URGENT: Student Risk Alert - ' + student.Name);
                
                String emailBody = 'Dear Advisor,\n\n' +
                                  'Student ' + student.Name + ' (ID: ' + student.Student_ID__c + ') ' +
                                  'has been identified as at-risk with a score of ' + riskScore + '.\n\n' +
                                  'Student Details:\n' +
                                  '- Name: ' + student.Name + '\n' +
                                  '- Major: ' + student.Major__c + '\n' +
                                  '- Email: ' + student.Email__c + '\n\n' +
                                  'Please review and take appropriate intervention actions immediately.\n\n' +
                                  'Best regards,\n' +
                                  'EduConnect Student Success System';
                
                email.setPlainTextBody(emailBody);
                
                if (!Test.isRunningTest()) {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                }
            }
        } catch (Exception e) {
            System.debug('Error sending advisor notification: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Student__c> getStudentsRequiringIntervention() {
        try {
            return [
                SELECT Id, Name, Student_ID__c, GPA__c, Risk_Score__c,
                       Academic_Status__c, Major__c, Year_Level__c, Email__c
                FROM Student__c
                WHERE Risk_Score__c >= 70
                ORDER BY Risk_Score__c DESC
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving students requiring intervention: ' + e.getMessage());
        }
    }
    
    @future
    public static void batchCalculateRiskScores() {
        try {
            List<Student__c> activeStudents = [
                SELECT Id
                FROM Student__c
                WHERE Academic_Status__c != 'Graduated'
                LIMIT 200
            ];
            
            for (Student__c student : activeStudents) {
                try {
                    calculateRiskScore(student.Id);
                } catch (Exception e) {
                    System.debug('Error calculating risk for student ' + student.Id + ': ' + e.getMessage());
                }
            }
        } catch (Exception e) {
            System.debug('Error in batch risk calculation: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> getRiskAnalytics() {
        try {
            Map<String, Object> analytics = new Map<String, Object>();
            
            // Risk distribution - calculate in Apex since CASE is not supported in SOQL
            List<Student__c> activeStudents = [
                SELECT Risk_Score__c
                FROM Student__c
                WHERE Academic_Status__c != 'Graduated'
                AND Risk_Score__c != null
            ];
            
            Map<String, Integer> riskLevels = new Map<String, Integer>{
                'Critical' => 0,
                'High' => 0,
                'Medium' => 0,
                'Low' => 0
            };
            
            for (Student__c student : activeStudents) {
                if (student.Risk_Score__c >= 80) {
                    riskLevels.put('Critical', riskLevels.get('Critical') + 1);
                } else if (student.Risk_Score__c >= 60) {
                    riskLevels.put('High', riskLevels.get('High') + 1);
                } else if (student.Risk_Score__c >= 40) {
                    riskLevels.put('Medium', riskLevels.get('Medium') + 1);
                } else {
                    riskLevels.put('Low', riskLevels.get('Low') + 1);
                }
            }
            
            analytics.put('riskDistribution', riskLevels);
            
            // Intervention success rate
            Integer totalInterventions = [
                SELECT COUNT()
                FROM Student_Support_Case__c
                WHERE Category__c = 'Academic' AND Priority__c IN ('High', 'Critical')
            ];
            
            Integer successfulInterventions = [
                SELECT COUNT()
                FROM Student_Support_Case__c
                WHERE Category__c = 'Academic' 
                AND Priority__c IN ('High', 'Critical')
                AND Status__c = 'Resolved'
            ];
            
            Decimal successRate = totalInterventions > 0 ? 
                (Decimal.valueOf(successfulInterventions) / Decimal.valueOf(totalInterventions)) * 100 : 0;
            analytics.put('interventionSuccessRate', successRate);
            
            return analytics;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving risk analytics: ' + e.getMessage());
        }
    }
}