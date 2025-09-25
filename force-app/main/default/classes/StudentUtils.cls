/**
 * Student Management Utility Class
 * Contains utility methods for student record management
 */
public class StudentUtils {
    
    /**
     * Calculate student risk score based on various factors
     */
    public static Decimal calculateRiskScore(Student__c student) {
        Decimal riskScore = 0;
        
        // GPA-based risk (40% weight)
        if (student.Current_GPA__c != null) {
            if (student.Current_GPA__c < 2.0) {
                riskScore += 40;
            } else if (student.Current_GPA__c < 2.5) {
                riskScore += 30;
            } else if (student.Current_GPA__c < 3.0) {
                riskScore += 20;
            } else if (student.Current_GPA__c < 3.5) {
                riskScore += 10;
            }
        }
        
        // Academic status-based risk (30% weight)
        if (student.Academic_Status__c == 'Academic Probation') {
            riskScore += 30;
        } else if (student.Academic_Status__c == 'Academic Warning') {
            riskScore += 20;
        }
        
        // Credit progress risk (20% weight)
        if (student.Credits_Earned__c != null && student.Expected_Graduation__c != null) {
            Date today = Date.today();
            Integer monthsToGraduation = student.Expected_Graduation__c.monthsBetween(today);
            Decimal expectedCredits = monthsToGraduation > 0 ? (120 * (48 - monthsToGraduation)) / 48 : 120;
            
            if (student.Credits_Earned__c < expectedCredits * 0.8) {
                riskScore += 20;
            } else if (student.Credits_Earned__c < expectedCredits * 0.9) {
                riskScore += 10;
            }
        }
        
        // Financial aid status (10% weight)
        if (student.Financial_Aid_Status__c == 'Suspended' || student.Financial_Aid_Status__c == 'Denied') {
            riskScore += 10;
        }
        
        return riskScore;
    }
    
    /**
     * Determine risk level based on risk score
     */
    public static String determineRiskLevel(Decimal riskScore) {
        if (riskScore >= 75) {
            return 'High';
        } else if (riskScore >= 50) {
            return 'Medium';
        } else if (riskScore >= 25) {
            return 'Low';
        } else {
            return 'None';
        }
    }
    
    /**
     * Bulk calculate risk scores for multiple students
     */
    public static void calculateBulkRiskScores(List<Student__c> students) {
        for (Student__c student : students) {
            Decimal riskScore = calculateRiskScore(student);
            student.Risk_Score__c = riskScore;
            student.Last_Risk_Calculation__c = Datetime.now();
        }
    }
    
    /**
     * Get students at risk of academic probation
     */
    public static List<Student__c> getStudentsAtRisk() {
        return [SELECT Id, Name, Current_GPA__c, Risk_Score__c, Risk_Level__c, Academic_Advisor__c
                FROM Student__c 
                WHERE Risk_Score__c >= 40
                AND Status__c = 'Enrolled'
                ORDER BY Risk_Score__c DESC];
    }
}