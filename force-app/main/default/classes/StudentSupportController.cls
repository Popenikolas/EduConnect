public with sharing class StudentSupportController {
    
    @AuraEnabled(cacheable=true)
    public static List<Student_Support_Case__c> getStudentSupportCases(Id studentId) {
        try {
            return [
                SELECT Id, Name, Subject__c, Category__c, Status__c, Priority__c,
                       Description__c, Created_Date__c, Resolution__c, 
                       Assigned_Advisor__c, Follow_Up_Required__c, Follow_Up_Date__c
                FROM Student_Support_Case__c
                WHERE Student__c = :studentId
                ORDER BY Created_Date__c DESC
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving support cases: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id createSupportCase(String subject, String category, String priority, 
                                     String description, Id studentId) {
        try {
            Student_Support_Case__c newCase = new Student_Support_Case__c(
                Subject__c = subject,
                Category__c = category,
                Priority__c = priority,
                Description__c = description,
                Student__c = studentId,
                Status__c = 'Open',
                Created_Date__c = Date.today()
            );
            
            insert newCase;
            return newCase.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating support case: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateSupportCase(Id caseId, String status, String resolution) {
        try {
            Student_Support_Case__c caseToUpdate = new Student_Support_Case__c(
                Id = caseId,
                Status__c = status
            );
            
            if (String.isNotBlank(resolution)) {
                caseToUpdate.Resolution__c = resolution;
            }
            
            update caseToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating support case: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getSupportCaseStats(Id studentId) {
        try {
            Map<String, Object> stats = new Map<String, Object>();
            
            // Get total cases
            Integer totalCases = [
                SELECT COUNT()
                FROM Student_Support_Case__c
                WHERE Student__c = :studentId
            ];
            
            // Get open cases
            Integer openCases = [
                SELECT COUNT()
                FROM Student_Support_Case__c
                WHERE Student__c = :studentId AND Status__c = 'Open'
            ];
            
            // Get high priority cases
            Integer highPriorityCases = [
                SELECT COUNT()
                FROM Student_Support_Case__c
                WHERE Student__c = :studentId AND Priority__c = 'High' AND Status__c != 'Closed'
            ];
            
            stats.put('totalCases', totalCases);
            stats.put('openCases', openCases);
            stats.put('highPriorityCases', highPriorityCases);
            stats.put('closedCases', totalCases - openCases);
            
            return stats;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving support case statistics: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCasesByCategory(Id studentId) {
        try {
            List<AggregateResult> results = [
                SELECT Category__c category, COUNT(Id) caseCount
                FROM Student_Support_Case__c
                WHERE Student__c = :studentId
                GROUP BY Category__c
                ORDER BY COUNT(Id) DESC
            ];
            
            List<Map<String, Object>> categoryData = new List<Map<String, Object>>();
            for (AggregateResult result : results) {
                Map<String, Object> categoryInfo = new Map<String, Object>();
                categoryInfo.put('category', result.get('category'));
                categoryInfo.put('count', result.get('caseCount'));
                categoryData.add(categoryInfo);
            }
            
            return categoryData;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving case category data: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Student_Support_Case__c> getOpenSupportCases(Id studentId) {
        try {
            return [
                SELECT Id, Name, Subject__c, Category__c, Priority__c, 
                       Description__c, Created_Date__c, Assigned_Advisor__c
                FROM Student_Support_Case__c
                WHERE Student__c = :studentId AND Status__c = 'Open'
                ORDER BY Priority__c, Created_Date__c DESC
                LIMIT 25
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving open support cases: ' + e.getMessage());
        }
    }
}