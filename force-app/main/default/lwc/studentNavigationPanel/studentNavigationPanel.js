import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class StudentNavigationPanel extends NavigationMixin(LightningElement) {
    @api recordId;
    @api studentData;
    
    // Navigate to related records
    navigateToAdvisor() {
        if (this.studentData?.advisorId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.studentData.advisorId,
                    objectApiName: 'Academic_Advisor__c',
                    actionName: 'view'
                }
            });
        }
    }
    
    navigateToProgram() {
        if (this.studentData?.programId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.studentData.programId,
                    objectApiName: 'Academic_Program__c',
                    actionName: 'view'
                }
            });
        }
    }
    
    // Navigate to create new records with pre-populated data
    navigateToCreateCase() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Student_Support_Case__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: {
                    Student__c: this.recordId,
                    Case_Type__c: 'Academic Support',
                    Priority__c: this.getPriorityFromRisk()
                }
            }
        });
    }
    
    // Navigate to list views with filters
    navigateToStudentCases() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Student_Support_Case__c',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent',
                Student__c: this.recordId // Filter by current student
            }
        });
    }
    
    // Navigate to reports with context
    navigateToRiskReport() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Report',
                actionName: 'home'
            }
        });
    }
    
    // Navigate between apps
    navigateToAlumniApp() {
        this[NavigationMixin.Navigate]({
            type: 'standard__app',
            attributes: {
                appTarget: 'EduConnect_Alumni_Relations'
            }
        });
    }
    
    // Utility method
    getPriorityFromRisk() {
        const riskScore = this.studentData?.riskScore || 0;
        if (riskScore >= 70) return 'Urgent';
        if (riskScore >= 40) return 'High';
        return 'Normal';
    }
}