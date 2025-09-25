import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, refreshApex } from 'lightning/uiRecordApi';

import getStudentSupportCases from '@salesforce/apex/StudentSupportController.getOpenSupportCases';
import getCourseEnrollments from '@salesforce/apex/StudentDataService.getCurrentEnrollments';

export default class StudentDataDisplay extends LightningElement {
    @api recordId;

    studentRecord;
    supportCases;
    courseEnrollments;

    wiredStudentRecordResult;
    wiredSupportCasesResult;
    wiredCourseEnrollmentsResult;

    // Wire student record
    @wire(getRecord, { recordId: '$recordId', fields: ['Student__c.Name'] })
    wiredStudent(result) {
        this.wiredStudentRecordResult = result;
        this.studentRecord = result.data;
    }

    // Wire support cases
    @wire(getStudentSupportCases, { studentId: '$recordId' })
    wiredCases(result) {
        this.wiredSupportCasesResult = result;
        this.supportCases = result.data;
    }

    // Wire course enrollments
    @wire(getCourseEnrollments, { studentId: '$recordId' })
    wiredCourses(result) {
        this.wiredCourseEnrollmentsResult = result;
        this.courseEnrollments = result.data;
    }

    get hasOpenCases() {
        return this.supportCases && this.supportCases.length > 0;
    }

    get caseCount() {
        return this.supportCases ? this.supportCases.length : 0;
    }

    async handleRefresh() {
        await Promise.all([
            refreshApex(this.wiredStudentRecordResult),
            refreshApex(this.wiredSupportCasesResult),
            refreshApex(this.wiredCourseEnrollmentsResult)
        ]);
    }
}
