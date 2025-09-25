import { createElement } from '@lwc/engine-dom';
import StudentDataDisplay from 'c/studentDataDisplay';

describe('c-student-data-display', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders student data display component correctly', () => {
        // Arrange
        const element = createElement('c-student-data-display', {
            is: StudentDataDisplay
        });

        // Act
        document.body.appendChild(element);

        // Assert - verify component renders without errors
        expect(element).toBeTruthy();
    });
});