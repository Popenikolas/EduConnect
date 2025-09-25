import { LightningElement, track } from 'lwc';
import getAcademicEvents from '@salesforce/apex/AcademicEventController.getAcademicEvents';

export default class AcademicCalendar extends LightningElement {
    @track currentDate = new Date();
    @track calendarEvents = [];
    @track selectedDate = null;

    connectedCallback() {
        this.loadCalendarEvents();
    }

    async loadCalendarEvents() {
        try {
            const events = await getAcademicEvents({ 
                startDate: this.getMonthStart(),
                endDate: this.getMonthEnd()
            });

            this.calendarEvents = events.map(event => ({
                ...event,
                cssClass: this.getEventClass(event.type)
            }));
        } catch (error) {
            console.error('Failed to load events:', error);
        }
    }

    handleDateSelect(event) {
        this.selectedDate = event.detail.selectedDate;

        const dayEvents = this.calendarEvents.filter(
            evt => evt.eventDate === this.selectedDate
        );
        if (dayEvents.length > 0) {
            this.showDayEvents(dayEvents);
        }
    }

    handlePreviousMonth() {
        this.currentDate = new Date(
            this.currentDate.getFullYear(),
            this.currentDate.getMonth() - 1,
            1
        );
        this.loadCalendarEvents();
    }

    handleNextMonth() {
        this.currentDate = new Date(
            this.currentDate.getFullYear(),
            this.currentDate.getMonth() + 1,
            1
        );
        this.loadCalendarEvents();
    }

    getEventClass(eventType) {
        const typeClasses = {
            Registration: 'event-registration',
            Deadline: 'event-deadline', 
            Holiday: 'event-holiday',
            Graduation: 'event-graduation'
        };
        return typeClasses[eventType] || 'event-default';
    }

    getMonthStart() {
        return new Date(this.currentDate.getFullYear(), this.currentDate.getMonth(), 1);
    }

    getMonthEnd() {
        return new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() + 1, 0);
    }

    showDayEvents(events) {
        this.dispatchEvent(
            new CustomEvent('showdayevents', {
                detail: { events, date: this.selectedDate }
            })
        );
    }

    // ✅ Getter for template use instead of direct function call
    get formattedMonthYear() {
        return this.currentDate.toLocaleString('default', {
            month: 'long',
            year: 'numeric'
        });
    }
}
