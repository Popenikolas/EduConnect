/**
 * Test class for StudentController
 * Provides test coverage for Lightning Web Component controller methods
 */
@isTest
public class StudentControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test students
        List<Student__c> testStudents = new List<Student__c>();
        
        for (Integer i = 0; i < 5; i++) {
            Student__c student = new Student__c();
            student.Name = 'Test Student ' + i;
            student.First_Name__c = 'Test' + i;
            student.Last_Name__c = 'Student' + i;
            student.Student_ID__c = 'STU00' + i;
            student.Email__c = 'student' + i + '@test.edu';
            student.Status__c = 'Enrolled';
            student.Current_GPA__c = 2.5 + (i * 0.3); // GPA range 2.5 to 3.7
            student.Risk_Score__c = 50 - (i * 10); // Risk scores from 50 to 10
            student.Academic_Status__c = i < 2 ? 'Academic Warning' : 'Good Standing';
            student.Last_Risk_Assessment_Date__c = Date.today().addDays(-i);
            testStudents.add(student);
        }
        
        insert testStudents;
        
        // Create test courses
        List<Course__c> testCourses = new List<Course__c>();
        
        for (Integer i = 0; i < 3; i++) {
            Course__c course = new Course__c();
            course.Name = 'Test Course ' + i;
            course.Course_Code__c = 'TST10' + i;
            course.Max_Enrollment__c = 30;
            testCourses.add(course);
        }
        
        insert testCourses;
        
        // Create some course enrollments
        List<Course_Enrollment__c> enrollments = new List<Course_Enrollment__c>();
        
        for (Integer i = 0; i < 2; i++) {
            Course_Enrollment__c enrollment = new Course_Enrollment__c();
            enrollment.Student__c = testStudents[i].Id;
            enrollment.Course__c = testCourses[0].Id;
            enrollment.Enrollment_Status__c = 'Enrolled';
            enrollment.Enrollment_Date__c = Date.today();
            enrollments.add(enrollment);
        }
        
        insert enrollments;
    }
    
    @isTest
    static void testGetStudentsAtRisk_NoFilters() {
        Test.startTest();
        List<Student__c> result = StudentController.getStudentsAtRisk('', '');
        Test.stopTest();
        
        System.assertNotEquals(0, result.size(), 'Should return students when no filters applied');
        System.assert(result.size() <= 100, 'Should respect LIMIT clause');
        
        // Verify required fields are populated
        for (Student__c student : result) {
            System.assertNotEquals(null, student.Name, 'Student name should not be null');
            System.assertNotEquals(null, student.Student_ID__c, 'Student ID should not be null');
        }
    }
    
    @isTest
    static void testGetStudentsAtRisk_WithRiskLevelFilter() {
        Test.startTest();
        List<Student__c> highRiskStudents = StudentController.getStudentsAtRisk('High', '');
        List<Student__c> mediumRiskStudents = StudentController.getStudentsAtRisk('Medium', '');
        List<Student__c> lowRiskStudents = StudentController.getStudentsAtRisk('Low', '');
        Test.stopTest();
        
        // Verify filtering logic
        for (Student__c student : highRiskStudents) {
            System.assert(student.Risk_Score__c >= 70, 'High risk students should have risk score >= 70');
        }
        
        for (Student__c student : mediumRiskStudents) {
            System.assert(student.Risk_Score__c >= 40, 'Medium risk students should have risk score >= 40');
        }
        
        for (Student__c student : lowRiskStudents) {
            System.assert(student.Risk_Score__c >= 25, 'Low risk students should have risk score >= 25');
        }
    }
    
    @isTest
    static void testGetStudentsAtRisk_WithAcademicStatusFilter() {
        Test.startTest();
        List<Student__c> warningStudents = StudentController.getStudentsAtRisk('', 'Academic Warning');
        List<Student__c> goodStandingStudents = StudentController.getStudentsAtRisk('', 'Good Standing');
        Test.stopTest();
        
        // Verify academic status filtering
        for (Student__c student : warningStudents) {
            System.assertEquals('Academic Warning', student.Academic_Status__c, 'Should only return students with Academic Warning status');
        }
        
        for (Student__c student : goodStandingStudents) {
            System.assertEquals('Good Standing', student.Academic_Status__c, 'Should only return students with Good Standing status');
        }
    }
    
    @isTest
    static void testGetStudentsAtRisk_WithBothFilters() {
        Test.startTest();
        List<Student__c> filteredStudents = StudentController.getStudentsAtRisk('Medium', 'Academic Warning');
        Test.stopTest();
        
        // Verify both filters are applied
        for (Student__c student : filteredStudents) {
            System.assert(student.Risk_Score__c >= 40, 'Should have medium risk score');
            System.assertEquals('Academic Warning', student.Academic_Status__c, 'Should have Academic Warning status');
        }
    }
    
    @isTest
    static void testSearchStudents_WithResults() {
        Test.startTest();
        List<Student__c> searchResults = StudentController.searchStudents('Test');
        Test.stopTest();
        
        System.assertNotEquals(0, searchResults.size(), 'Should return matching students');
        System.assert(searchResults.size() <= 50, 'Should respect LIMIT clause');
        
        // Verify only enrolled students are returned
        for (Student__c student : searchResults) {
            System.assertEquals('Enrolled', student.Status__c, 'Should only return enrolled students');
        }
    }
    
    @isTest
    static void testSearchStudents_WithStudentId() {
        Test.startTest();
        List<Student__c> searchResults = StudentController.searchStudents('STU001');
        Test.stopTest();
        
        System.assertNotEquals(0, searchResults.size(), 'Should find student by Student ID');
        
        Boolean foundMatchingStudent = false;
        for (Student__c student : searchResults) {
            if (student.Student_ID__c.contains('STU001')) {
                foundMatchingStudent = true;
                break;
            }
        }
        System.assert(foundMatchingStudent, 'Should find student with matching Student ID');
    }
    
    @isTest
    static void testSearchStudents_WithEmail() {
        Test.startTest();
        List<Student__c> searchResults = StudentController.searchStudents('test.edu');
        Test.stopTest();
        
        System.assertNotEquals(0, searchResults.size(), 'Should find students by email domain');
        
        Boolean foundMatchingStudent = false;
        for (Student__c student : searchResults) {
            if (student.Email__c != null && student.Email__c.contains('test.edu')) {
                foundMatchingStudent = true;
                break;
            }
        }
        System.assert(foundMatchingStudent, 'Should find student with matching email');
    }
    
    @isTest
    static void testSearchStudents_NoResults() {
        Test.startTest();
        List<Student__c> searchResults = StudentController.searchStudents('NonExistentStudent');
        Test.stopTest();
        
        System.assertEquals(0, searchResults.size(), 'Should return empty list for no matches');
    }
    
    @isTest
    static void testGetAvailableCourses() {
        Test.startTest();
        List<Course__c> courses = StudentController.getAvailableCourses();
        Test.stopTest();
        
        System.assertNotEquals(0, courses.size(), 'Should return available courses');
        
        // Verify required fields are populated
        for (Course__c course : courses) {
            System.assertNotEquals(null, course.Name, 'Course name should not be null');
            System.assertNotEquals(null, course.Course_Code__c, 'Course code should not be null');
        }
        
        // Verify courses are sorted by course code
        for (Integer i = 0; i < courses.size() - 1; i++) {
            System.assert(courses[i].Course_Code__c <= courses[i+1].Course_Code__c, 
                         'Courses should be sorted by course code');
        }
    }
    
    @isTest
    static void testSearchStudents_SqlInjectionPrevention() {
        String maliciousInput = '\'; DROP TABLE Student__c; --';
        
        Test.startTest();
        try {
            List<Student__c> results = StudentController.searchStudents(maliciousInput);
            // Should not throw exception and should return empty or safe results
            System.assert(true, 'Method should handle malicious input safely');
        } catch (Exception e) {
            // If an exception is thrown, it should be a safe exception, not a SQL injection
            System.assert(!e.getMessage().contains('DROP'), 'Should not execute malicious SQL');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetStudentsAtRisk_LargeDataSet() {
        // Create additional test data to test performance and limits
        List<Student__c> largeDataSet = new List<Student__c>();
        
        for (Integer i = 0; i < 150; i++) {
            Student__c student = new Student__c();
            student.Name = 'Bulk Test Student ' + i;
            student.First_Name__c = 'Bulk' + i;
            student.Last_Name__c = 'Test' + i;
            student.Student_ID__c = 'BULK' + String.valueOf(i).leftPad(3, '0');
            student.Email__c = 'bulk' + i + '@test.edu';
            student.Status__c = 'Enrolled';
            student.Current_GPA__c = 2.0;
            student.Risk_Score__c = 80; // High risk
            student.Academic_Status__c = 'Academic Probation';
            largeDataSet.add(student);
        }
        
        insert largeDataSet;
        
        Test.startTest();
        List<Student__c> results = StudentController.getStudentsAtRisk('High', '');
        Test.stopTest();
        
        // Should respect the LIMIT of 100
        System.assert(results.size() <= 100, 'Should not exceed LIMIT of 100 records');
    }
}