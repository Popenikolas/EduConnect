import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class CourseEnrollment extends LightningElement {
    @track searchTerm = '';
    @track selectedStudentId = '';
    @track selectedCourseId = '';
    @track enrollmentDate = new Date().toISOString().split('T')[0];
    @track enrollmentStatus = 'Draft';
    @track selectedCourseInfo = null;
    @track recentEnrollments = [];
    
    // Options for dropdowns
    @track studentOptions = [
        { label: 'John Smith (STU001)', value: 'student1' },
        { label: 'Jane Doe (STU002)', value: 'student2' },
        { label: 'Mike Johnson (STU003)', value: 'student3' }
    ];
    
    @track courseOptions = [
        { label: 'CS101 - Introduction to Computer Science', value: 'course1' },
        { label: 'MATH201 - Calculus I', value: 'course2' },
        { label: 'ENG101 - English Composition', value: 'course3' }
    ];

    statusOptions = [
        { label: 'Draft', value: 'Draft' },
        { label: 'Submitted', value: 'Submitted' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Enrolled', value: 'Enrolled' }
    ];

    // Data table columns for recent enrollments
    enrollmentColumns = [
        {
            label: 'Student Name',
            fieldName: 'studentName',
            type: 'text'
        },
        {
            label: 'Course',
            fieldName: 'courseName',
            type: 'text'
        },
        {
            label: 'Enrollment Date',
            fieldName: 'enrollmentDate',
            type: 'date'
        },
        {
            label: 'Status',
            fieldName: 'status',
            type: 'text'
        },
        {
            label: 'Grade',
            fieldName: 'grade',
            type: 'text'
        }
    ];

    connectedCallback() {
        // Load recent enrollments
        this.loadRecentEnrollments();
    }

    get isEnrollDisabled() {
        return !this.selectedStudentId || !this.selectedCourseId || !this.enrollmentDate;
    }

    handleStudentSearch(event) {
        this.searchTerm = event.target.value;
        // In a real implementation, this would filter the student options
        // based on the search term using an Apex method
    }

    handleStudentChange(event) {
        this.selectedStudentId = event.detail.value;
    }

    handleCourseChange(event) {
        this.selectedCourseId = event.detail.value;
        this.loadCourseInformation();
    }

    handleEnrollmentDateChange(event) {
        this.enrollmentDate = event.detail.value;
    }

    handleStatusChange(event) {
        this.enrollmentStatus = event.detail.value;
    }

    loadCourseInformation() {
        // In a real implementation, this would call an Apex method
        // to get course details from the database
        if (this.selectedCourseId) {
            this.selectedCourseInfo = {
                courseCode: 'CS101',
                credits: 3,
                maxEnrollment: 30,
                currentEnrollment: 25
            };
        } else {
            this.selectedCourseInfo = null;
        }
    }

    handleEnrollStudent() {
        if (this.isEnrollDisabled) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }

        // In a real implementation, this would call an Apex method
        // to create the course enrollment record
        const enrollmentData = {
            studentId: this.selectedStudentId,
            courseId: this.selectedCourseId,
            enrollmentDate: this.enrollmentDate,
            status: this.enrollmentStatus
        };

        // Simulate successful enrollment
        this.showToast('Success', 'Student enrolled successfully!', 'success');
        this.handleClear();
        this.loadRecentEnrollments();
    }

    handleClear() {
        this.selectedStudentId = '';
        this.selectedCourseId = '';
        this.enrollmentDate = new Date().toISOString().split('T')[0];
        this.enrollmentStatus = 'Draft';
        this.selectedCourseInfo = null;
        this.searchTerm = '';
    }

    loadRecentEnrollments() {
        // In a real implementation, this would call an Apex method
        // to get recent enrollment records
        this.recentEnrollments = [
            {
                Id: '1',
                studentName: 'John Smith',
                courseName: 'CS101 - Introduction to Computer Science',
                enrollmentDate: '2024-01-15',
                status: 'Enrolled',
                grade: 'In Progress'
            },
            {
                Id: '2',
                studentName: 'Jane Doe',
                courseName: 'MATH201 - Calculus I',
                enrollmentDate: '2024-01-14',
                status: 'Enrolled',
                grade: 'A'
            },
            {
                Id: '3',
                studentName: 'Mike Johnson',
                courseName: 'ENG101 - English Composition',
                enrollmentDate: '2024-01-13',
                status: 'Approved',
                grade: 'In Progress'
            }
        ];
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}