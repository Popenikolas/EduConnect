import { createElement } from '@lwc/engine-dom';
import StudentRiskIndicator from 'c/studentRiskIndicator';

describe('c-student-risk-indicator', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders student risk indicator component correctly', () => {
        // Arrange
        const element = createElement('c-student-risk-indicator', {
            is: StudentRiskIndicator
        });

        // Act
        document.body.appendChild(element);

        // Assert - verify component renders without errors
        expect(element).toBeTruthy();
    });
});