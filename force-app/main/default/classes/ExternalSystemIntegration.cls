/**
 * Integration Service for External Academic Systems
 * Handles callouts to external student information systems
 */
public class ExternalSystemIntegration {
    
    private static final String EXTERNAL_SYSTEM_ENDPOINT = 'https://api.university.edu/students/';
    private static final String API_KEY_HEADER = 'X-API-Key';
    
    /**
     * Sync student data with external academic system
     */
    @future(callout=true)
    public static void syncStudentWithExternalSystem(Id studentId) {
        try {
            Student__c student = [SELECT Id, Name, Student_ID__c, Email__c, First_Name__c, Last_Name__c,
                                        Status__c, Current_GPA__c, Academic_Status__c, Major__c
                                 FROM Student__c WHERE Id = :studentId LIMIT 1];
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(EXTERNAL_SYSTEM_ENDPOINT + student.Student_ID__c);
            req.setMethod('PUT');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader(API_KEY_HEADER, getApiKey());
            
            ExternalStudentData extData = new ExternalStudentData();
            extData.studentId = student.Student_ID__c;
            extData.firstName = student.First_Name__c;
            extData.lastName = student.Last_Name__c;
            extData.email = student.Email__c;
            extData.status = student.Status__c;
            extData.gpa = student.Current_GPA__c;
            extData.academicStatus = student.Academic_Status__c;
            extData.major = student.Major__c;
            
            req.setBody(JSON.serialize(extData));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                System.debug('Successfully synced student ' + student.Student_ID__c + ' with external system');
                
                // Update sync status on student record
                student.Last_External_Sync__c = Datetime.now();
                update student;
            } else {
                System.debug('Failed to sync student: ' + res.getStatusCode() + ' - ' + res.getBody());
                createIntegrationLog(student.Id, 'SYNC_ERROR', res.getStatusCode() + ': ' + res.getBody());
            }
            
        } catch (Exception e) {
            System.debug('Error syncing student: ' + e.getMessage());
            createIntegrationLog(studentId, 'SYNC_EXCEPTION', e.getMessage());
        }
    }
    
    /**
     * Fetch student grades from external gradebook system
     */
    @future(callout=true)
    public static void fetchStudentGrades(Id studentId) {
        try {
            Student__c student = [SELECT Student_ID__c FROM Student__c WHERE Id = :studentId LIMIT 1];
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(EXTERNAL_SYSTEM_ENDPOINT + student.Student_ID__c + '/grades');
            req.setMethod('GET');
            req.setHeader(API_KEY_HEADER, getApiKey());
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                List<ExternalGradeData> grades = (List<ExternalGradeData>)JSON.deserialize(
                    res.getBody(), List<ExternalGradeData>.class
                );
                
                updateStudentEnrollmentGrades(studentId, grades);
            } else {
                createIntegrationLog(studentId, 'GRADE_FETCH_ERROR', res.getStatusCode() + ': ' + res.getBody());
            }
            
        } catch (Exception e) {
            createIntegrationLog(studentId, 'GRADE_FETCH_EXCEPTION', e.getMessage());
        }
    }
    
    /**
     * Send at-risk notification to external intervention system
     */
    @future(callout=true)
    public static void notifyExternalInterventionSystem(Id studentId, Decimal riskScore) {
        try {
            Student__c student = [SELECT Student_ID__c, Name, Email__c 
                                 FROM Student__c WHERE Id = :studentId LIMIT 1];
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://intervention.university.edu/alerts');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader(API_KEY_HEADER, getApiKey());
            
            InterventionAlert alert = new InterventionAlert();
            alert.studentId = student.Student_ID__c;
            alert.studentName = student.Name;
            alert.riskScore = riskScore;
            alert.advisorEmail = student.Email__c;
            alert.alertLevel = riskScore >= 75 ? 'HIGH' : 'MEDIUM';
            alert.timestamp = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            
            req.setBody(JSON.serialize(alert));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 201) {
                System.debug('Successfully sent intervention alert for student ' + student.Student_ID__c);
            } else {
                createIntegrationLog(studentId, 'INTERVENTION_ERROR', res.getStatusCode() + ': ' + res.getBody());
            }
            
        } catch (Exception e) {
            createIntegrationLog(studentId, 'INTERVENTION_EXCEPTION', e.getMessage());
        }
    }
    
    /**
     * Helper method to get API key from custom settings
     */
    private static String getApiKey() {
        // In a real implementation, this would retrieve from Custom Settings or Named Credentials
        return 'mock-api-key-12345';
    }
    
    /**
     * Update course enrollment grades based on external data
     */
    private static void updateStudentEnrollmentGrades(Id studentId, List<ExternalGradeData> grades) {
        Map<String, String> courseGradeMap = new Map<String, String>();
        
        for (ExternalGradeData gradeData : grades) {
            courseGradeMap.put(gradeData.courseCode, gradeData.grade);
        }
        
        List<Course_Enrollment__c> enrollments = [SELECT Id, Course__r.Course_Code__c, Grade__c
                                                  FROM Course_Enrollment__c 
                                                  WHERE Student__c = :studentId 
                                                  AND Course__r.Course_Code__c IN :courseGradeMap.keySet()];
        
        for (Course_Enrollment__c enrollment : enrollments) {
            enrollment.Grade__c = courseGradeMap.get(enrollment.Course__r.Course_Code__c);
        }
        
        if (!enrollments.isEmpty()) {
            update enrollments;
        }
    }
    
    /**
     * Create integration log record for troubleshooting
     */
    private static void createIntegrationLog(Id studentId, String logType, String message) {
        // In a real implementation, this would create a custom Integration_Log__c record
        System.debug('Integration Log - Type: ' + logType + ', Student: ' + studentId + ', Message: ' + message);
    }
    
    /**
     * Data wrapper classes for external system integration
     */
    public class ExternalStudentData {
        public String studentId;
        public String firstName;
        public String lastName;
        public String email;
        public String status;
        public Decimal gpa;
        public String academicStatus;
        public String major;
    }
    
    public class ExternalGradeData {
        public String courseCode;
        public String courseName;
        public String grade;
        public Decimal points;
        public String semester;
    }
    
    public class InterventionAlert {
        public String studentId;
        public String studentName;
        public Decimal riskScore;
        public String advisorEmail;
        public String alertLevel;
        public String timestamp;
    }
}