import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class InterventionModal extends LightningElement {
    @api studentData;
    
    @track interventionForm = {
        type: '',
        description: '',
        urgency: 'Medium',
        assignedTo: '',
        followUpDate: '',
        notes: ''
    };
    
    @track isLoading = false;
    
    get interventionTypeOptions() {
        return [
            { label: 'Academic Counseling', value: 'Academic Counseling' },
            { label: 'Financial Aid Review', value: 'Financial Aid Review' },
            { label: 'Mental Health Support', value: 'Mental Health Support' },
            { label: 'Career Guidance', value: 'Career Guidance' },
            { label: 'Tutoring Assignment', value: 'Tutoring Assignment' },
            { label: 'Faculty Meeting', value: 'Faculty Meeting' },
            { label: 'Parent/Guardian Contact', value: 'Parent/Guardian Contact' }
        ];
    }
    
    get urgencyOptions() {
        return [
            { label: 'Low', value: 'Low' },
            { label: 'Medium', value: 'Medium' },
            { label: 'High', value: 'High' },
            { label: 'Critical', value: 'Critical' }
        ];
    }
    
    get modalTitle() {
        return `Intervention Required - Risk Score: ${this.studentData?.riskScore || 'N/A'}`;
    }
    
    get isFormValid() {
        return this.interventionForm.type && 
               this.interventionForm.description && 
               this.interventionForm.followUpDate;
    }
    
    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.interventionForm[field] = value;
    }
    
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
    
    handleSave() {
        if (!this.isFormValid) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }
        
        this.isLoading = true;
        
        // Create intervention record - in real implementation, call Apex method
        try {
            this.dispatchEvent(new CustomEvent('interventioncomplete', {
                detail: {
                    studentId: this.studentData?.id,
                    interventionType: this.interventionForm.type,
                    description: this.interventionForm.description,
                    urgency: this.interventionForm.urgency,
                    assignedTo: this.interventionForm.assignedTo,
                    followUpDate: this.interventionForm.followUpDate,
                    notes: this.interventionForm.notes
                }
            }));
            
            this.showToast('Success', 'Intervention plan created successfully', 'success');
            this.handleClose();
        } catch (error) {
            console.error('Error creating intervention:', error);
            this.showToast('Error', 'Failed to create intervention plan', 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}