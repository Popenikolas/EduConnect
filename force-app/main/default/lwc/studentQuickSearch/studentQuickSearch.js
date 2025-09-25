import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import searchStudents from '@salesforce/apex/StudentSearchController.searchStudents';

export default class StudentQuickSearch extends NavigationMixin(LightningElement) {
    @track searchTerm = '';
    @track searchResults = [];
    @track isSearching = false;

    handleSearchInput(event) {
        this.searchTerm = event.target.value;

        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.performSearch();
        }, 300);
    }

    async performSearch() {
        if (this.searchTerm.length < 2) {
            this.searchResults = [];
            return;
        }

        this.isSearching = true;
        try {
            const results = await searchStudents({ 
                searchTerm: this.searchTerm,
                includeRiskScore: true
            });

            this.searchResults = results.map(student => ({
                ...student,
                riskLevelClass: this.getRiskLevelClass(student.riskScore)
            }));
        } catch (error) {
            console.error('Search failed:', error);
        } finally {
            this.isSearching = false;
        }
    }

    handleStudentSelect(event) {
        const studentId = event.currentTarget.dataset.studentId;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: studentId,
                objectApiName: 'Student__c',
                actionName: 'view'
            }
        });

        this.closeUtility();
    }

    getRiskLevelClass(riskScore) {
        if (riskScore >= 70) return 'risk-high';
        if (riskScore >= 40) return 'risk-medium';
        return 'risk-low';
    }

    closeUtility() {
        console.log('Closing utility panel');
    }
}
