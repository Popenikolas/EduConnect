/**
 * Controller for Student Lightning Web Components
 */
public with sharing class StudentController {
    
    /**
     * Get students at risk based on filters
     */
    @AuraEnabled(cacheable=true)
    public static List<Student__c> getStudentsAtRisk(String riskLevel, String academicStatus) {
        String query = 'SELECT Id, Name, Student_ID__c, Risk_Level__c, Risk_Score__c, ' +
                      'Current_GPA__c, Academic_Status__c, Last_Risk_Assessment_Date__c ' +
                      'FROM Student__c WHERE Status__c = \'Enrolled\'';
        
        List<String> conditions = new List<String>();
        
        // Add risk level filter if provided
        if (String.isNotBlank(riskLevel)) {
            conditions.add('Risk_Score__c >= ' + (riskLevel == 'High' ? '70' : (riskLevel == 'Medium' ? '40' : '25')));
        }
        
        // Add academic status filter if provided
        if (String.isNotBlank(academicStatus)) {
            conditions.add('Academic_Status__c = \'' + String.escapeSingleQuotes(academicStatus) + '\'');
        }
        
        if (!conditions.isEmpty()) {
            query += ' AND ' + String.join(conditions, ' AND ');
        }
        
        query += ' ORDER BY Risk_Score__c DESC NULLS LAST LIMIT 100';
        
        return Database.query(query);
    }
    
    /**
     * Get student data for search/selection
     */
    @AuraEnabled(cacheable=true)
    public static List<Student__c> searchStudents(String searchTerm) {
        String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        
        return [SELECT Id, Name, Student_ID__c, Email__c, Status__c
                FROM Student__c 
                WHERE (Name LIKE :searchPattern 
                       OR Student_ID__c LIKE :searchPattern 
                       OR Email__c LIKE :searchPattern)
                AND Status__c = 'Enrolled'
                ORDER BY Name
                LIMIT 50];
    }
    
    /**
     * Get course data for enrollment
     */
    @AuraEnabled(cacheable=true)
    public static List<Course__c> getAvailableCourses() {
        return [SELECT Id, Name, Course_Code__c, Max_Enrollment__c,
                       (SELECT Id FROM Course_Course_Enrollments__r WHERE Enrollment_Status__c = 'Enrolled')
                FROM Course__c 
                ORDER BY Course_Code__c];
    }
}