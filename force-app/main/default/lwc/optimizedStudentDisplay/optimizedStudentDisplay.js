import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getStudentAdditionalInfo from '@salesforce/apex/StudentDataService.getStudentAdditionalInfo';

const STUDENT_FIELDS = [
    'Student__c.Name',
    'Student__c.Risk_Score__c',
    'Student__c.GPA__c',
    'Student__c.Academic_Status__c'
];

export default class OptimizedStudentDisplay extends LightningElement {
    @api recordId;

    // Internal state
    _studentData;
    _additionalData;
    _riskAssessment;
    _cacheExpiry = 5 * 60 * 1000; // 5 minutes
    _lastFetch;

    @track isLoading = false;

    // Wire to get student record
    @wire(getRecord, { recordId: '$recordId', fields: STUDENT_FIELDS })
    wiredStudent({ error, data }) {
        if (data) {
            this._studentData = data;
            this._lastFetch = Date.now();
        } else if (error) {
            console.error('Error loading student data', error);
        }
    }

    // Computed property for risk assessment
    @api
    get riskAssessment() {
        if (!this._riskAssessment && this._studentData) {
            this._riskAssessment = this.calculateRiskAssessment(this._studentData);
        }
        return this._riskAssessment;
    }

    calculateRiskAssessment(student) {
        const riskScore = student.fields.Risk_Score__c.value || 0;
        if (riskScore >= 70) return 'High Risk';
        if (riskScore >= 40) return 'Moderate Risk';
        return 'Low Risk';
    }

    // Lazy load additional info
    async loadAdditionalData() {
        if (this.shouldRefreshCache()) {
            this.isLoading = true;
            try {
                this._additionalData = await getStudentAdditionalInfo({ studentId: this.recordId });
            } catch (error) {
                console.warn('Failed to load additional data:', error);
            } finally {
                this.isLoading = false;
                this._lastFetch = Date.now();
            }
        }
    }

    shouldRefreshCache() {
        return !this._lastFetch || (Date.now() - this._lastFetch) > this._cacheExpiry;
    }

    // Simple search handler without debounce to avoid setTimeout restriction
    handleSearchTermChange(searchTerm) {
        console.log('Searching for:', searchTerm);
    }

    disconnectedCallback() {
        // Clear cached data
        this._studentData = null;
        this._riskAssessment = null;
        this._additionalData = null;
    }
}
