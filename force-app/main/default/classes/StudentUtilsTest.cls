/**
 * Test class for StudentUtils utility class
 * Provides comprehensive test coverage for student utility methods
 */
@isTest
public class StudentUtilsTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test students with various risk profiles
        List<Student__c> testStudents = new List<Student__c>();
        
        // High risk student
        Student__c highRiskStudent = new Student__c();
        highRiskStudent.Name = 'Test High Risk Student';
        highRiskStudent.First_Name__c = 'Test';
        highRiskStudent.Last_Name__c = 'High Risk';
        highRiskStudent.Student_ID__c = 'STU001';
        highRiskStudent.Email__c = 'highrisk@test.edu';
        highRiskStudent.Current_GPA__c = 1.8;
        highRiskStudent.Academic_Status__c = 'Academic Probation';
        highRiskStudent.Status__c = 'Enrolled';
        highRiskStudent.Credits_Earned__c = 45;
        highRiskStudent.Expected_Graduation__c = Date.today().addMonths(12);
        highRiskStudent.Financial_Aid_Status__c = 'Suspended';
        testStudents.add(highRiskStudent);
        
        // Medium risk student
        Student__c mediumRiskStudent = new Student__c();
        mediumRiskStudent.Name = 'Test Medium Risk Student';
        mediumRiskStudent.First_Name__c = 'Test';
        mediumRiskStudent.Last_Name__c = 'Medium Risk';
        mediumRiskStudent.Student_ID__c = 'STU002';
        mediumRiskStudent.Email__c = 'mediumrisk@test.edu';
        mediumRiskStudent.Current_GPA__c = 2.3;
        mediumRiskStudent.Academic_Status__c = 'Academic Warning';
        mediumRiskStudent.Status__c = 'Enrolled';
        mediumRiskStudent.Credits_Earned__c = 75;
        mediumRiskStudent.Expected_Graduation__c = Date.today().addMonths(18);
        mediumRiskStudent.Financial_Aid_Status__c = 'Active';
        testStudents.add(mediumRiskStudent);
        
        // Low risk student
        Student__c lowRiskStudent = new Student__c();
        lowRiskStudent.Name = 'Test Low Risk Student';
        lowRiskStudent.First_Name__c = 'Test';
        lowRiskStudent.Last_Name__c = 'Low Risk';
        lowRiskStudent.Student_ID__c = 'STU003';
        lowRiskStudent.Email__c = 'lowrisk@test.edu';
        lowRiskStudent.Current_GPA__c = 3.7;
        lowRiskStudent.Academic_Status__c = 'Good Standing';
        lowRiskStudent.Status__c = 'Enrolled';
        lowRiskStudent.Credits_Earned__c = 95;
        lowRiskStudent.Expected_Graduation__c = Date.today().addMonths(6);
        lowRiskStudent.Financial_Aid_Status__c = 'Active';
        testStudents.add(lowRiskStudent);
        
        insert testStudents;
    }
    
    @isTest
    static void testCalculateRiskScore_HighRisk() {
        Student__c highRiskStudent = [SELECT Id, Current_GPA__c, Academic_Status__c, 
                                            Credits_Earned__c, Expected_Graduation__c, Financial_Aid_Status__c
                                     FROM Student__c WHERE Student_ID__c = 'STU001' LIMIT 1];
        
        Test.startTest();
        Decimal riskScore = StudentUtils.calculateRiskScore(highRiskStudent);
        Test.stopTest();
        
        // High risk student should have high risk score (GPA < 2.0 = 40, Academic Probation = 30, Financial Aid Suspended = 10)
        // Total expected: 80+
        System.assert(riskScore >= 80, 'High risk student should have risk score >= 80, got: ' + riskScore);
    }
    
    @isTest
    static void testCalculateRiskScore_MediumRisk() {
        Student__c mediumRiskStudent = [SELECT Id, Current_GPA__c, Academic_Status__c, 
                                              Credits_Earned__c, Expected_Graduation__c, Financial_Aid_Status__c
                                       FROM Student__c WHERE Student_ID__c = 'STU002' LIMIT 1];
        
        Test.startTest();
        Decimal riskScore = StudentUtils.calculateRiskScore(mediumRiskStudent);
        Test.stopTest();
        
        // Medium risk student should have moderate risk score (GPA 2.0-2.5 = 30, Academic Warning = 20)
        // Total expected: 50
        System.assert(riskScore >= 40 && riskScore < 75, 'Medium risk student should have risk score between 40-74, got: ' + riskScore);
    }
    
    @isTest
    static void testCalculateRiskScore_LowRisk() {
        Student__c lowRiskStudent = [SELECT Id, Current_GPA__c, Academic_Status__c, 
                                           Credits_Earned__c, Expected_Graduation__c, Financial_Aid_Status__c
                                    FROM Student__c WHERE Student_ID__c = 'STU003' LIMIT 1];
        
        Test.startTest();
        Decimal riskScore = StudentUtils.calculateRiskScore(lowRiskStudent);
        Test.stopTest();
        
        // Low risk student should have low risk score (High GPA, Good Standing, On Track)
        System.assert(riskScore < 25, 'Low risk student should have risk score < 25, got: ' + riskScore);
    }
    
    @isTest
    static void testDetermineRiskLevel() {
        Test.startTest();
        
        String highRisk = StudentUtils.determineRiskLevel(80);
        String mediumRisk = StudentUtils.determineRiskLevel(55);
        String lowRisk = StudentUtils.determineRiskLevel(30);
        String noRisk = StudentUtils.determineRiskLevel(10);
        
        Test.stopTest();
        
        System.assertEquals('High', highRisk, 'Risk score of 80 should be High risk');
        System.assertEquals('Medium', mediumRisk, 'Risk score of 55 should be Medium risk');
        System.assertEquals('Low', lowRisk, 'Risk score of 30 should be Low risk');
        System.assertEquals('None', noRisk, 'Risk score of 10 should be None risk');
    }
    
    @isTest
    static void testCalculateBulkRiskScores() {
        List<Student__c> students = [SELECT Id, Current_GPA__c, Academic_Status__c, 
                                           Credits_Earned__c, Expected_Graduation__c, Financial_Aid_Status__c,
                                           Risk_Score__c, Last_Risk_Calculation__c
                                    FROM Student__c];
        
        Test.startTest();
        StudentUtils.calculateBulkRiskScores(students);
        Test.stopTest();
        
        // Verify all students have updated risk scores and calculation dates
        for (Student__c student : students) {
            System.assertNotEquals(null, student.Risk_Score__c, 'Risk score should be calculated for all students');
            System.assertNotEquals(null, student.Last_Risk_Calculation__c, 'Last calculation date should be set');
        }
    }
    
    @isTest
    static void testGetStudentsAtRisk() {
        Test.startTest();
        List<Student__c> atRiskStudents = StudentUtils.getStudentsAtRisk();
        Test.stopTest();
        
        System.assertNotEquals(0, atRiskStudents.size(), 'Should return at-risk students');
        
        // Verify students are sorted by risk score descending
        for (Integer i = 0; i < atRiskStudents.size() - 1; i++) {
            Decimal currentScore = atRiskStudents[i].Risk_Score__c != null ? atRiskStudents[i].Risk_Score__c : 0;
            Decimal nextScore = atRiskStudents[i+1].Risk_Score__c != null ? atRiskStudents[i+1].Risk_Score__c : 0;
            System.assert(currentScore >= nextScore, 'Students should be sorted by risk score descending');
        }
    }
    
    @isTest
    static void testCalculateRiskScore_NullValues() {
        Student__c studentWithNulls = new Student__c();
        studentWithNulls.Name = 'Test Null Values';
        studentWithNulls.First_Name__c = 'Test';
        studentWithNulls.Last_Name__c = 'Null';
        // Leave most fields null to test null handling
        
        Test.startTest();
        Decimal riskScore = StudentUtils.calculateRiskScore(studentWithNulls);
        Test.stopTest();
        
        System.assertNotEquals(null, riskScore, 'Risk score should handle null values gracefully');
        System.assert(riskScore >= 0, 'Risk score should not be negative');
    }
    
    @isTest
    static void testCalculateRiskScore_EdgeCases() {
        Student__c edgeStudent = new Student__c();
        edgeStudent.Name = 'Test Edge Case';
        edgeStudent.Current_GPA__c = 2.0; // Boundary value
        edgeStudent.Academic_Status__c = 'Good Standing';
        edgeStudent.Financial_Aid_Status__c = 'Active';
        edgeStudent.Credits_Earned__c = 60;
        edgeStudent.Expected_Graduation__c = Date.today().addMonths(24);
        
        Test.startTest();
        Decimal riskScore = StudentUtils.calculateRiskScore(edgeStudent);
        Test.stopTest();
        
        System.assertNotEquals(null, riskScore, 'Risk score should be calculated for edge cases');
    }
}