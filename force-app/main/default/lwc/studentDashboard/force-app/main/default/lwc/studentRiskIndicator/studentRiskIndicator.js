import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

// Import Student fields
import RISK_SCORE_FIELD from '@salesforce/schema/Student__c.Risk_Score__c';
import GPA_FIELD from '@salesforce/schema/Student__c.GPA__c';
import ACADEMIC_STATUS_FIELD from '@salesforce/schema/Student__c.Academic_Status__c';
import CREDITS_PROGRESS_FIELD from '@salesforce/schema/Student__c.Credits_in_Progress__c';

const FIELDS = [
    RISK_SCORE_FIELD,
    GPA_FIELD, 
    ACADEMIC_STATUS_FIELD,
    CREDITS_PROGRESS_FIELD
];

export default class StudentRiskIndicator extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isProcessing = false;

    // Wire student record
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    student;

    // ======================
    // Computed properties
    // ======================
    get riskScore() {
        return this.student.data?.fields.Risk_Score__c.value || 0;
    }

    get riskLevel() {
        const score = this.riskScore;
        if (score >= 70) return 'HIGH RISK';
        if (score >= 40) return 'MODERATE RISK';
        return 'LOW RISK';
    }

    get riskGaugeClass() {
        const score = this.riskScore;
        if (score >= 70) return 'risk-gauge high-risk';
        if (score >= 40) return 'risk-gauge moderate-risk';
        return 'risk-gauge low-risk';
    }

    get riskLevelClass() {
        const score = this.riskScore;
        if (score >= 70) return 'risk-level high';
        if (score >= 40) return 'risk-level moderate';
        return 'risk-level low';
    }

    get riskFactors() {
        const factors = [];
        if (this.student.data) {
            const gpa = this.student.data.fields.GPA__c.value;
            const status = this.student.data.fields.Academic_Status__c.value;
            const credits = this.student.data.fields.Credits_in_Progress__c.value;

            // GPA Factor
            if (gpa !== null) {
                factors.push({
                    id: 'gpa',
                    label: 'Current GPA',
                    value: gpa,
                    icon: gpa < 2.0 ? 'utility:warning' : 'utility:success',
                    variant: gpa < 2.0 ? 'error' : 'success',
                    cssClass: gpa < 2.0 ? 'factor-high-risk' : 'factor-normal'
                });
            }

            // Academic Status Factor
            if (status) {
                const isRisky = ['Academic Probation', 'Academic Suspension'].includes(status);
                factors.push({
                    id: 'status',
                    label: 'Academic Status',
                    value: status,
                    icon: isRisky ? 'utility:warning' : 'utility:success',
                    variant: isRisky ? 'warning' : 'success',
                    cssClass: isRisky ? 'factor-moderate-risk' : 'factor-normal'
                });
            }

            // Credits Factor
            if (credits !== null) {
                factors.push({
                    id: 'credits',
                    label: 'Credits in Progress',
                    value: credits + ' credits',
                    icon: credits < 12 ? 'utility:info' : 'utility:success',
                    variant: credits < 12 ? 'warning' : 'success',
                    cssClass: credits < 12 ? 'factor-moderate-risk' : 'factor-normal'
                });
            }
        }
        return factors;
    }

    // ======================
    // Event Handlers
    // ======================
    handleCreateCase() {
        // Dispatch custom event to parent
        this.dispatchEvent(new CustomEvent('casecreated', {
            detail: { studentId: this.recordId, riskScore: this.riskScore },
            bubbles: true
        }));
    }

    handleSendAlert() {
        this.dispatchEvent(new CustomEvent('alertrequested', {
            detail: { studentId: this.recordId, riskScore: this.riskScore, urgency: 'high' },
            bubbles: true
        }));
    }
}
