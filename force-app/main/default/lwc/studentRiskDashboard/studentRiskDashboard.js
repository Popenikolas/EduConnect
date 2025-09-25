import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getStudentsAtRisk from '@salesforce/apex/StudentController.getStudentsAtRisk';

export default class StudentRiskDashboard extends NavigationMixin(LightningElement) {
    @track students = [];
    @track isLoading = false;
    @track selectedRiskLevel = '';
    @track selectedAcademicStatus = '';
    
    // Statistics
    @track highRiskCount = 0;
    @track mediumRiskCount = 0;
    @track lowRiskCount = 0;
    @track totalStudents = 0;

    // Options for filters
    riskLevelOptions = [
        { label: 'All Risk Levels', value: '' },
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
        { label: 'Low', value: 'Low' }
    ];

    academicStatusOptions = [
        { label: 'All Statuses', value: '' },
        { label: 'Good Standing', value: 'Good Standing' },
        { label: 'Academic Warning', value: 'Academic Warning' },
        { label: 'Academic Probation', value: 'Academic Probation' },
        { label: 'Academic Suspension', value: 'Academic Suspension' }
    ];

    // Data table columns
    columns = [
        {
            label: 'Student Name',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            }
        },
        {
            label: 'Student ID',
            fieldName: 'Student_ID__c',
            type: 'text'
        },
        {
            label: 'Risk Level',
            fieldName: 'Risk_Level__c',
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'riskLevelClass' }
            }
        },
        {
            label: 'Risk Score',
            fieldName: 'Risk_Score__c',
            type: 'number',
            typeAttributes: {
                minimumFractionDigits: 1,
                maximumFractionDigits: 1
            }
        },
        {
            label: 'Current GPA',
            fieldName: 'Current_GPA__c',
            type: 'number',
            typeAttributes: {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
            }
        },
        {
            label: 'Academic Status',
            fieldName: 'Academic_Status__c',
            type: 'text'
        },
        {
            label: 'Last Assessment',
            fieldName: 'Last_Risk_Assessment_Date__c',
            type: 'date'
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View Details', name: 'view' },
                    { label: 'Create Task', name: 'create_task' },
                    { label: 'Send Email', name: 'send_email' }
                ]
            }
        }
    ];

    connectedCallback() {
        this.loadStudentData();
    }

    loadStudentData() {
        this.isLoading = true;
        
        getStudentsAtRisk({
            riskLevel: this.selectedRiskLevel,
            academicStatus: this.selectedAcademicStatus
        })
        .then(result => {
            this.processStudentData(result);
        })
        .catch(error => {
            this.showToast('Error', 'Failed to load student data: ' + error.body.message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    processStudentData(data) {
        let highRisk = 0, mediumRisk = 0, lowRisk = 0;
        
        const processedData = data.map(student => {
            // Add navigation URL
            student.recordUrl = `/${student.Id}`;
            
            // Add CSS class based on risk level
            if (student.Risk_Level__c === 'High') {
                student.riskLevelClass = 'slds-text-color_error slds-text-title_bold';
                highRisk++;
            } else if (student.Risk_Level__c === 'Medium') {
                student.riskLevelClass = 'slds-text-color_warning slds-text-title_bold';
                mediumRisk++;
            } else {
                student.riskLevelClass = 'slds-text-color_success';
                lowRisk++;
            }
            
            return student;
        });

        this.students = processedData;
        this.highRiskCount = highRisk;
        this.mediumRiskCount = mediumRisk;
        this.lowRiskCount = lowRisk;
        this.totalStudents = data.length;
    }

    handleRiskLevelChange(event) {
        this.selectedRiskLevel = event.detail.value;
        this.loadStudentData();
    }

    handleAcademicStatusChange(event) {
        this.selectedAcademicStatus = event.detail.value;
        this.loadStudentData();
    }

    handleRefresh() {
        this.loadStudentData();
        this.showToast('Success', 'Student data refreshed', 'success');
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'view':
                this.navigateToRecord(row.Id);
                break;
            case 'create_task':
                this.createFollowUpTask(row);
                break;
            case 'send_email':
                this.sendEmailToAdvisor(row);
                break;
        }
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Student__c',
                actionName: 'view'
            }
        });
    }

    createFollowUpTask(student) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Task',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: {
                    Subject: `High Risk Student Follow-up: ${student.Name}`,
                    WhatId: student.Id,
                    Description: `Student has been flagged as ${student.Risk_Level__c} risk. Current GPA: ${student.Current_GPA__c}, Risk Score: ${student.Risk_Score__c}`,
                    Priority: student.Risk_Level__c === 'High' ? 'High' : 'Normal',
                    ActivityDate: new Date(Date.now() + 24*60*60*1000).toISOString().split('T')[0] // Tomorrow
                }
            }
        });
    }

    sendEmailToAdvisor(student) {
        // This would typically call an Apex method to send email
        this.showToast('Info', 'Email functionality would be implemented with Apex controller', 'info');
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