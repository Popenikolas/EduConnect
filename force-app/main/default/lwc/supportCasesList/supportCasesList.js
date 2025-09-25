import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getOpenSupportCases from '@salesforce/apex/StudentDataService.getOpenSupportCases';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SupportCasesList extends LightningElement {
    @api studentId;
    @api refreshTrigger;
    
    @track cases = [];
    @track isLoading = false;
    @track error;
    
    wiredCasesResult;
    
    @wire(getOpenSupportCases, { studentId: '$studentId' })
    wiredCases(result) {
        this.wiredCasesResult = result;
        if (result.data) {
            this.cases = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.cases = [];
            console.error('Error loading support cases:', result.error);
        }
    }
    
    get hasCases() {
        return this.cases && this.cases.length > 0;
    }
    
    get casesWithPriorityClass() {
        return this.cases.map(caseItem => ({
            ...caseItem,
            priorityClass: this.getPriorityClass(caseItem.Priority__c),
            priorityIcon: this.getPriorityIcon(caseItem.Priority__c),
            formattedDate: this.formatDate(caseItem.Created_Date__c)
        }));
    }
    
    connectedCallback() {
        this.refreshData();
    }
    
    renderedCallback() {
        if (this.refreshTrigger) {
            this.refreshData();
        }
    }
    
    refreshData() {
        this.isLoading = true;
        return refreshApex(this.wiredCasesResult)
            .then(() => {
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'Failed to refresh support cases', 'error');
                console.error('Error refreshing cases:', error);
            });
    }
    
    handleCaseClick(event) {
        const caseId = event.currentTarget.dataset.caseId;
        
        // Navigate to case record page
        this.dispatchEvent(new CustomEvent('caseselected', {
            detail: {
                caseId: caseId
            }
        }));
    }
    
    handleCreateNewCase() {
        this.dispatchEvent(new CustomEvent('createnewcase', {
            detail: {
                studentId: this.studentId
            }
        }));
    }
    
    getPriorityClass(priority) {
        switch (priority) {
            case 'Critical':
                return 'priority-critical';
            case 'High':
                return 'priority-high';
            case 'Medium':
                return 'priority-medium';
            default:
                return 'priority-low';
        }
    }
    
    getPriorityIcon(priority) {
        switch (priority) {
            case 'Critical':
                return 'utility:error';
            case 'High':
                return 'utility:warning';
            case 'Medium':
                return 'utility:info';
            default:
                return 'utility:check';
        }
    }
    
    formatDate(dateValue) {
        if (!dateValue) return '';
        
        const date = new Date(dateValue);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}