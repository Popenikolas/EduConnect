public with sharing class StudentDataService {

    @AuraEnabled(cacheable=true)
    public static Student__c getStudentRecord(Id studentId) {
        try {
            return [
                SELECT Id, Name, Student_ID__c, Email__c, Phone__c, GPA__c, 
                       Risk_Score__c, Academic_Status__c, Credits_in_Progress__c,
                       Major__c, Year_Level__c, Expected_Graduation__c,
                       Enrollment_Date__c, Financial_Aid_Status__c, First_Name__c,
                       Last_Name__c, Risk_Level__c, At_Risk__c, Credits_Earned__c
                FROM Student__c
                WHERE Id = :studentId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving student record: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Student_Course_Enrollment__c> getCurrentEnrollments(Id studentId) {
        try {
            return [
                SELECT Id, Name, Course__r.Name, Course__r.Course_Code__c, 
                       Course__r.Credit_Hours__c, Grade__c, Semester__c, Status__c,
                       Enrollment_Date__c
                FROM Student_Course_Enrollment__c
                WHERE Student__c = :studentId AND Status__c = 'Enrolled'
                ORDER BY Semester__c DESC, Course__r.Course_Code__c
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving enrollments: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Student_Support_Case__c> getOpenSupportCases(Id studentId) {
        try {
            return [
                SELECT Id, Name, Subject__c, Status__c, Priority__c, Category__c,
                       Description__c, Assigned_To__r.Name, Created_Date__c
                FROM Student_Support_Case__c
                WHERE Student__c = :studentId AND Status__c IN ('Open', 'In Progress')
                ORDER BY Priority__c DESC, Created_Date__c DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving support cases: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id createSupportCase(Id studentId, String subject, String description, 
                                      String priority, String category) {
        try {
            Student_Support_Case__c newCase = new Student_Support_Case__c(
                Student__c = studentId,
                Subject__c = subject,
                Description__c = description,
                Priority__c = priority,
                Category__c = category,
                Status__c = 'Open',
                Created_Date__c = Date.today()
            );
            
            insert newCase;
            return newCase.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating support case: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Student__c> getStudentsAtRisk() {
        try {
            return [
                SELECT Id, Name, Student_ID__c, GPA__c, Risk_Score__c, 
                       Academic_Status__c, Major__c, Year_Level__c
                FROM Student__c
                WHERE Risk_Score__c >= 50 
                ORDER BY Risk_Score__c DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving at-risk students: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateRiskScore(Id studentId, Decimal newRiskScore) {
        try {
            Student__c student = new Student__c(
                Id = studentId,
                Risk_Score__c = newRiskScore
            );
            update student;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating risk score: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getStudentDashboardData(Id studentId) {
        try {
            Map<String, Object> dashboardData = new Map<String, Object>();
            
            // Get student record
            Student__c student = getStudentRecord(studentId);
            dashboardData.put('student', student);
            
            // Get current enrollments
            List<Student_Course_Enrollment__c> enrollments = getCurrentEnrollments(studentId);
            dashboardData.put('enrollments', enrollments);
            
            // Get open support cases
            List<Student_Support_Case__c> cases = getOpenSupportCases(studentId);
            dashboardData.put('supportCases', cases);
            
            // Get upcoming events the student is registered for
            List<Event_Registration__c> upcomingEvents = [
                SELECT Id, Event__r.Name, Event__r.Start_Date_Time__c, 
                       Event__r.Location__c, Status__c
                FROM Event_Registration__c
                WHERE Student__c = :studentId 
                AND Event__r.Start_Date_Time__c > :System.now()
                AND Status__c IN ('Registered', 'Confirmed')
                ORDER BY Event__r.Start_Date_Time__c
                LIMIT 5
            ];
            dashboardData.put('upcomingEvents', upcomingEvents);
            
            return dashboardData;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving dashboard data: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getStudentAdditionalInfo(Id studentId) {
        try {
            Map<String, Object> additionalInfo = new Map<String, Object>();
            
            // Get student risk assessment data
            Student__c student = [
                SELECT Id, Risk_Score__c, Academic_Status__c, Last_Risk_Assessment_Date__c
                FROM Student__c 
                WHERE Id = :studentId
                LIMIT 1
            ];
            
            additionalInfo.put('riskScore', student.Risk_Score__c);
            additionalInfo.put('academicStatus', student.Academic_Status__c);
            additionalInfo.put('lastAssessmentDate', student.Last_Risk_Assessment_Date__c);
            
            return additionalInfo;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving additional student info: ' + e.getMessage());
        }
    }
}
