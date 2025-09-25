import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class StudentDashboard extends LightningElement {
    @api recordId;
    @track refreshTrigger = 0;
    @track showInterventionModal = false;
    @track selectedStudent = null;

    // Handle events from child components
    handleCaseCreated(event) {
        const { studentId, riskScore } = event.detail;

        this.refreshTrigger = Date.now(); // Trigger refresh on child components
        this.showToast('Success', 'Support case created successfully', 'success');
        this.updateDashboardMetrics();
    }

    handleRiskAlertRequested(event) {
        const { studentId, riskScore, urgency } = event.detail;

        if (urgency === 'high' || urgency === 'critical') {
            this.showInterventionModal = true;
            this.selectedStudent = { id: studentId, riskScore };
        }

        this.logRiskAlert(studentId, riskScore);
    }

    handleInterventionComplete(event) {
        this.showInterventionModal = false;
        this.refreshTrigger = Date.now(); // refresh child components
        this.notifyAdvisor(event.detail);
    }

    handleModalClose() {
        this.showInterventionModal = false;
    }

    // =========================
    // Utility Methods
    // =========================
    updateDashboardMetrics() {
        const dashboardComponents = this.template.querySelectorAll('c-dashboard-metrics');
        dashboardComponents.forEach(component => {
            if (component.refresh) {
                component.refresh();
            }
        });
    }

    logRiskAlert(studentId, riskScore) {
        console.log(`High-risk alert logged for student ${studentId} with score ${riskScore}`);
    }

    notifyAdvisor(interventionDetails) {
        console.log('Advisor notified of intervention:', interventionDetails);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
