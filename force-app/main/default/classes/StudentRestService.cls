/**
 * REST API for Student Data Access
 * Provides external system integration capabilities
 */
@RestResource(urlMapping='/Student/v1/*')
global class StudentRestService {
    
    /**
     * GET method to retrieve student information
     * URL pattern: /services/apexrest/Student/v1/
     */
    @HttpGet
    global static StudentResponse getStudentData() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String studentId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
            
            if (String.isBlank(studentId)) {
                return createErrorResponse(res, 400, 'Student ID is required');
            }
            
            Student__c student = getStudentById(studentId);
            if (student == null) {
                return createErrorResponse(res, 404, 'Student not found');
            }
            
            StudentResponse response = new StudentResponse();
            response.success = true;
            response.student = student;
            response.message = 'Student data retrieved successfully';
            
            res.statusCode = 200;
            return response;
            
        } catch (Exception e) {
            return createErrorResponse(res, 500, 'Internal server error: ' + e.getMessage());
        }
    }
    
    /**
     * POST method to create/update student information
     */
    @HttpPost
    global static StudentResponse createOrUpdateStudent() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String requestBody = req.requestBody.toString();
            StudentRequest studentReq = (StudentRequest)JSON.deserialize(requestBody, StudentRequest.class);
            
            if (studentReq == null || studentReq.student == null) {
                return createErrorResponse(res, 400, 'Invalid request body');
            }
            
            Student__c student = studentReq.student;
            
            // Validate required fields
            if (String.isBlank(student.First_Name__c) || String.isBlank(student.Last_Name__c)) {
                return createErrorResponse(res, 400, 'First Name and Last Name are required');
            }
            
            // Check if student exists for update
            if (String.isNotBlank(student.Student_ID__c)) {
                Student__c existingStudent = getStudentByStudentId(student.Student_ID__c);
                if (existingStudent != null) {
                    student.Id = existingStudent.Id;
                }
            }
            
            upsert student;
            
            StudentResponse response = new StudentResponse();
            response.success = true;
            response.student = student;
            response.message = 'Student ' + (String.isBlank(student.Student_ID__c) ? 'created' : 'updated') + ' successfully';
            
            res.statusCode = 201;
            return response;
            
        } catch (Exception e) {
            return createErrorResponse(res, 500, 'Internal server error: ' + e.getMessage());
        }
    }
    
    /**
     * Helper method to get student by Salesforce ID
     */
    private static Student__c getStudentById(String studentId) {
        try {
            return [SELECT Id, Name, First_Name__c, Last_Name__c, Student_ID__c, 
                          Email__c, Status__c, Current_GPA__c, Risk_Score__c, Risk_Level__c,
                          Academic_Status__c, Major__c, Expected_Graduation__c
                   FROM Student__c 
                   WHERE Id = :studentId 
                   LIMIT 1];
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * Helper method to get student by Student ID
     */
    private static Student__c getStudentByStudentId(String studentIdNumber) {
        try {
            return [SELECT Id, Name, First_Name__c, Last_Name__c, Student_ID__c, 
                          Email__c, Status__c, Current_GPA__c, Risk_Score__c, Risk_Level__c,
                          Academic_Status__c, Major__c, Expected_Graduation__c
                   FROM Student__c 
                   WHERE Student_ID__c = :studentIdNumber 
                   LIMIT 1];
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * Helper method to create error responses
     */
    private static StudentResponse createErrorResponse(RestResponse res, Integer statusCode, String message) {
        res.statusCode = statusCode;
        StudentResponse response = new StudentResponse();
        response.success = false;
        response.message = message;
        return response;
    }
    
    /**
     * Response wrapper class
     */
    global class StudentResponse {
        public Boolean success;
        public String message;
        public Student__c student;
    }
    
    /**
     * Request wrapper class
     */
    global class StudentRequest {
        public Student__c student;
    }
}