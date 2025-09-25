import { createElement } from 'lwc';
import StudentDashboard from 'c/studentDashboard';

// Mock student ID
const MOCK_STUDENT_ID = '001xx000003DGbYAAW';

describe('Student Dashboard Integration', () => {
    afterEach(() => {
        // Clean up DOM after each test
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    test('dashboard components communicate correctly', async () => {
        // Create parent dashboard component
        const dashboard = createElement('c-student-dashboard', {
            is: StudentDashboard
        });
        dashboard.recordId = MOCK_STUDENT_ID;
        document.body.appendChild(dashboard);

        // Wait for reactivity
        await Promise.resolve();

        // Find child component
        const riskIndicator = dashboard.shadowRoot.querySelector('c-student-risk-indicator');
        expect(riskIndicator).toBeTruthy();

        // Simulate high-risk scenario
        const highRiskEvent = new CustomEvent('alertrequested', {
            detail: {
                studentId: MOCK_STUDENT_ID,
                riskScore: 85,
                urgency: 'high'
            }
        });
        riskIndicator.dispatchEvent(highRiskEvent);

        await Promise.resolve();

        // Verify intervention modal is displayed
        const interventionModal = dashboard.shadowRoot.querySelector('c-intervention-modal');
        expect(interventionModal).toBeTruthy();

        // Verify support cases list refreshes
        const supportCasesList = dashboard.shadowRoot.querySelector('c-support-cases-list');
        expect(supportCasesList.refreshTrigger).toBeGreaterThan(0);
    });
});
