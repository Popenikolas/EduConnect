public with sharing class StudentSearchController {
    
    @AuraEnabled(cacheable=true)
    public static List<Student__c> searchStudents(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return new List<Student__c>();
        }
        
        String wildcardSearchTerm = '%' + searchTerm + '%';
        
        try {
            return [
                SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Student_ID__c,
                       Major__c, Academic_Status__c, Current_GPA__c, Class_Level__c
                FROM Student__c
                WHERE (First_Name__c LIKE :wildcardSearchTerm
                    OR Last_Name__c LIKE :wildcardSearchTerm
                    OR Email__c LIKE :wildcardSearchTerm
                    OR Student_ID__c LIKE :wildcardSearchTerm
                    OR Major__c LIKE :wildcardSearchTerm)
                AND Academic_Status__c = 'Active'
                ORDER BY Last_Name__c, First_Name__c
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error searching students: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Student__c getStudentById(Id studentId) {
        try {
            return [
                SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Student_ID__c,
                       Major__c, Minor__c, Academic_Status__c, Current_GPA__c, Class_Level__c,
                       Enrollment_Date__c, Expected_Graduation__c, Academic_Program__c,
                       Phone__c, Address_Line_1__c, City__c, State__c, Postal_Code__c,
                       Financial_Aid_Status__c, At_Risk__c, Risk_Score__c
                FROM Student__c
                WHERE Id = :studentId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving student: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getQuickSearchSuggestions(String searchTerm) {
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return new List<Map<String, Object>>();
        }
        
        String wildcardSearchTerm = searchTerm + '%';
        List<Map<String, Object>> suggestions = new List<Map<String, Object>>();
        
        try {
            List<Student__c> students = [
                SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Student_ID__c, Major__c
                FROM Student__c
                WHERE (First_Name__c LIKE :wildcardSearchTerm
                    OR Last_Name__c LIKE :wildcardSearchTerm
                    OR Student_ID__c LIKE :wildcardSearchTerm)
                AND Academic_Status__c = 'Active'
                ORDER BY Last_Name__c, First_Name__c
                LIMIT 10
            ];
            
            for (Student__c student : students) {
                Map<String, Object> suggestion = new Map<String, Object>();
                suggestion.put('id', student.Id);
                suggestion.put('name', student.First_Name__c + ' ' + student.Last_Name__c);
                suggestion.put('studentId', student.Student_ID__c);
                suggestion.put('major', student.Major__c);
                suggestion.put('email', student.Email__c);
                suggestions.add(suggestion);
            }
        } catch (Exception e) {
            System.debug('Error getting search suggestions: ' + e.getMessage());
        }
        
        return suggestions;
    }
}