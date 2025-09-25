/**
 * Course Management Utility Class
 * Contains utility methods for course and enrollment management
 */
public class CourseUtils {
    
    /**
     * Check course enrollment capacity
     */
    public static Map<Id, Boolean> checkEnrollmentCapacity(Set<Id> courseIds) {
        Map<Id, Boolean> capacityMap = new Map<Id, Boolean>();
        
        // Get course capacity and current enrollments
        List<Course__c> courses = [SELECT Id, Max_Enrollment__c, 
                                          (SELECT Id FROM Course_Course_Enrollments__r WHERE Enrollment_Status__c = 'Enrolled')
                                   FROM Course__c WHERE Id IN :courseIds];
        
        for (Course__c course : courses) {
            Integer currentEnrollments = course.Course_Course_Enrollments__r.size();
            Boolean hasCapacity = (course.Max_Enrollment__c == null || currentEnrollments < course.Max_Enrollment__c);
            capacityMap.put(course.Id, hasCapacity);
        }
        
        return capacityMap;
    }
    
    /**
     * Validate course prerequisites
     */
    public static Boolean validatePrerequisites(Id studentId, Id courseId) {
        // Get course prerequisites
        Course__c course = [SELECT Prerequisites__c FROM Course__c WHERE Id = :courseId LIMIT 1];
        
        if (String.isBlank(course.Prerequisites__c)) {
            return true; // No prerequisites required
        }
        
        // Get student's completed courses with passing grades
        Set<String> completedCourses = new Set<String>();
        List<Course_Enrollment__c> enrollments = [SELECT Course__r.Course_Code__c 
                                                  FROM Course_Enrollment__c 
                                                  WHERE Student__c = :studentId 
                                                  AND Grade__c IN ('A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D')];
        
        for (Course_Enrollment__c enrollment : enrollments) {
            completedCourses.add(enrollment.Course__r.Course_Code__c);
        }
        
        // Check if all prerequisites are met
        List<String> prerequisites = course.Prerequisites__c.split(',');
        for (String prereq : prerequisites) {
            if (!completedCourses.contains(prereq.trim())) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Calculate course enrollment statistics
     */
    public static Map<Id, CourseStats> getCourseStatistics(Set<Id> courseIds) {
        Map<Id, CourseStats> statsMap = new Map<Id, CourseStats>();
        
        List<Course__c> courses = [SELECT Id, Name, Max_Enrollment__c,
                                          (SELECT Grade__c FROM Course_Course_Enrollments__r WHERE Grade__c != 'In Progress')
                                   FROM Course__c WHERE Id IN :courseIds];
        
        for (Course__c course : courses) {
            CourseStats stats = new CourseStats();
            stats.courseId = course.Id;
            stats.courseName = course.Name;
            stats.maxEnrollment = course.Max_Enrollment__c?.intValue() ?? 0;
            stats.currentEnrollment = course.Course_Course_Enrollments__r.size();
            
            // Calculate grade distribution
            Integer aGrades = 0, bGrades = 0, cGrades = 0, dGrades = 0, fGrades = 0;
            
            for (Course_Enrollment__c enrollment : course.Course_Course_Enrollments__r) {
                String grade = enrollment.Grade__c;
                if (grade != null) {
                    if (grade.startsWith('A')) aGrades++;
                    else if (grade.startsWith('B')) bGrades++;
                    else if (grade.startsWith('C')) cGrades++;
                    else if (grade.equals('D')) dGrades++;
                    else if (grade.equals('F')) fGrades++;
                }
            }
            
            stats.gradeDistribution = new Map<String, Integer>{
                'A' => aGrades, 'B' => bGrades, 'C' => cGrades, 'D' => dGrades, 'F' => fGrades
            };
            
            statsMap.put(course.Id, stats);
        }
        
        return statsMap;
    }
    
    /**
     * Inner class for course statistics
     */
    public class CourseStats {
        public Id courseId;
        public String courseName;
        public Integer maxEnrollment;
        public Integer currentEnrollment;
        public Map<String, Integer> gradeDistribution;
    }
}