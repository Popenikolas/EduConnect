@isTest
public class StudentDataServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test student
        Student__c testStudent = new Student__c(
            Name = 'Test Student',
            Student_ID__c = 'TEST001',
            Email__c = 'test@example.com',
            GPA__c = 3.5,
            Risk_Score__c = 25.0,
            Academic_Status__c = 'Good Standing',
            Credits_in_Progress__c = 15,
            Major__c = 'Computer Science',
            Year_Level__c = '3rd Year'
        );
        insert testStudent;
        
        // Create test course
        Course__c testCourse = new Course__c(
            Name = 'Test Course',
            Course_Code__c = 'TEST101',
            Credit_Hours__c = 3,
            Course_Status__c = 'Active'
        );
        insert testCourse;
        
        // Create test enrollment
        Student_Course_Enrollment__c enrollment = new Student_Course_Enrollment__c(
            Student__c = testStudent.Id,
            Course__c = testCourse.Id,
            Grade__c = 'A',
            Semester__c = 'Fall 2024',
            Status__c = 'Enrolled'
        );
        insert enrollment;
        
        // Create test support case
        Student_Support_Case__c supportCase = new Student_Support_Case__c(
            Student__c = testStudent.Id,
            Subject__c = 'Test Support Case',
            Description__c = 'Test case description',
            Status__c = 'Open',
            Priority__c = 'Medium',
            Category__c = 'Academic'
        );
        insert supportCase;
    }
    
    @isTest
    static void testGetStudentRecord() {
        Student__c student = [SELECT Id FROM Student__c LIMIT 1];
        
        Test.startTest();
        Student__c result = StudentDataService.getStudentRecord(student.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Student record should not be null');
        System.assertEquals('Test Student', result.Name, 'Student name should match');
        System.assertEquals(3.5, result.GPA__c, 'GPA should match');
    }
    
    @isTest
    static void testGetCurrentEnrollments() {
        Student__c student = [SELECT Id FROM Student__c LIMIT 1];
        
        Test.startTest();
        List<Student_Course_Enrollment__c> enrollments = 
            StudentDataService.getCurrentEnrollments(student.Id);
        Test.stopTest();
        
        System.assertEquals(1, enrollments.size(), 'Should return one enrollment');
        System.assertEquals('Fall 2024', enrollments[0].Semester__c, 'Semester should match');
    }
    
    @isTest
    static void testGetOpenSupportCases() {
        Student__c student = [SELECT Id FROM Student__c LIMIT 1];
        
        Test.startTest();
        List<Student_Support_Case__c> cases = 
            StudentDataService.getOpenSupportCases(student.Id);
        Test.stopTest();
        
        System.assertEquals(1, cases.size(), 'Should return one open case');
        System.assertEquals('Test Support Case', cases[0].Subject__c, 'Subject should match');
    }
    
    @isTest
    static void testCreateSupportCase() {
        Student__c student = [SELECT Id FROM Student__c LIMIT 1];
        
        Test.startTest();
        Id caseId = StudentDataService.createSupportCase(
            student.Id,
            'New Test Case',
            'New test case description',
            'High',
            'Financial'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, caseId, 'Case ID should not be null');
        
        Student_Support_Case__c createdCase = [
            SELECT Subject__c, Priority__c, Category__c, Status__c
            FROM Student_Support_Case__c 
            WHERE Id = :caseId
        ];
        
        System.assertEquals('New Test Case', createdCase.Subject__c, 'Subject should match');
        System.assertEquals('High', createdCase.Priority__c, 'Priority should match');
        System.assertEquals('Financial', createdCase.Category__c, 'Category should match');
        System.assertEquals('Open', createdCase.Status__c, 'Status should be Open');
    }
    
    @isTest
    static void testGetStudentsAtRisk() {
        // Update student to have higher risk score
        Student__c student = [SELECT Id FROM Student__c LIMIT 1];
        student.Risk_Score__c = 75.0;
        update student;
        
        Test.startTest();
        List<Student__c> riskStudents = StudentDataService.getStudentsAtRisk();
        Test.stopTest();
        
        System.assertEquals(1, riskStudents.size(), 'Should return one at-risk student');
        System.assertEquals(75.0, riskStudents[0].Risk_Score__c, 'Risk score should match');
    }
    
    @isTest
    static void testUpdateRiskScore() {
        Student__c student = [SELECT Id FROM Student__c LIMIT 1];
        
        Test.startTest();
        StudentDataService.updateRiskScore(student.Id, 80.0);
        Test.stopTest();
        
        Student__c updatedStudent = [
            SELECT Risk_Score__c 
            FROM Student__c 
            WHERE Id = :student.Id
        ];
        
        System.assertEquals(80.0, updatedStudent.Risk_Score__c, 'Risk score should be updated');
    }
    
    @isTest
    static void testGetStudentDashboardData() {
        Student__c student = [SELECT Id FROM Student__c LIMIT 1];
        
        Test.startTest();
        Map<String, Object> dashboardData = 
            StudentDataService.getStudentDashboardData(student.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, dashboardData, 'Dashboard data should not be null');
        System.assert(dashboardData.containsKey('student'), 'Should contain student data');
        System.assert(dashboardData.containsKey('enrollments'), 'Should contain enrollments');
        System.assert(dashboardData.containsKey('supportCases'), 'Should contain support cases');
        System.assert(dashboardData.containsKey('upcomingEvents'), 'Should contain upcoming events');
        
        Student__c studentData = (Student__c)dashboardData.get('student');
        System.assertEquals('Test Student', studentData.Name, 'Student name should match');
    }
    
    @isTest
    static void testErrorHandling() {
        Test.startTest();
        try {
            StudentDataService.getStudentRecord('001000000000000'); // Invalid ID
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error retrieving student record'), 
                            'Should contain error message');
        }
        Test.stopTest();
    }
}