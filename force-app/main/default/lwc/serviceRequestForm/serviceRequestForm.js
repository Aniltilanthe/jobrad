import { LightningElement, track  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSessionId from '@salesforce/apex/SessionController.getSessionId';

// Constants for REST endpoints
const REST_API_BASE_URL = '/services/apexrest/servicerequest';

export default class ServiceRequestForm extends LightningElement {
    @track subject = '';
    @track description = '';
    @track serviceRequests = [];// This will be the filtered list displayed to the user
    @track allServiceRequests = []; // This will hold all service requests fetched from the server
    @track isLoading = false;
    @track isSubmitting = false; // Track if the form is being submitted
    @track searchTerm = ''; // Track search term
        
    sessionId;
    
    // connectedCallback is called when the component is inserted into the DOM
    connectedCallback() {
        getSessionId()
            .then(sessionId => {
                this.sessionId = sessionId;
                // Load service requests after getting the session ID
                this.loadServiceRequests();
            })
            .catch(error => console.error(error));
    }
    
    // Getter to check if requests exist
    get hasRequests() {
        return this.serviceRequests && this.serviceRequests.length > 0;
    }

    statusClass(request) {        
        let statusClass = '';
        switch (request.Status__c) {
            case 'New':
                statusClass = 'slds-text-color_error'; // Red for New
                break;
            case 'In Progress':
                statusClass = 'slds-text-color_warning'; // Orange for In Progress
                break;
            case 'Closed':
                statusClass = 'slds-text-color_success'; // Green for Closed
                break;
            default:
                statusClass = '';
        }
        return statusClass;
    }

    /**
     * @description Loads service requests from the REST endpoint.
     * Uses fetch() API for HTTP GET request.
     */
    async loadServiceRequests() {
        this.isLoading = true;
        try {
            const response = await fetch(REST_API_BASE_URL, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'OAuth  ' + this.sessionId,
                },
            });

            if (response.ok) {
                const data = await response.json();
                console.log('Response Data:', data);
                // Process data and add a class for status display, and description truncation logic
                const processedData = data.map(request => {
                    // Format the date
                    const createdDate = new Date(request.CreatedDate);
                    const options = { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' };
                    const CreatedDateFormatted = createdDate.toLocaleDateString('en-US', options);

                    return {
                        ...request,
                        statusClass: this.statusClass(request),
                        CreatedDateFormatted,
                    };
                });
                this.allServiceRequests = processedData; // Store the full list
                this.serviceRequests = [...processedData];
                this.showToast('Requests loaded successfully.', 'success');
            } else {
                this.serviceRequests = null; // Set to null to display the error message
                this.allServiceRequests = null;
                const errorData = await response.json();
                this.showToast('Error loading requests: ${response.status} ${errorData.message}', 'error');
            }
        } catch (error) {
            this.serviceRequests = null; // Set to null to display the error message
            this.allServiceRequests = null;
            console.error(error);
            this.showToast('Error:  ${error}', 'error');
        } finally {
            this.isLoading = false;
        }
    }


    handleInputChange(event) {
        const field = event.target.name;
        if (field === 'subject') {
            this.subject = event.target.value;
        } else if (field === 'description') {
            this.description = event.target.value;
        }
    }


    /**
     * @description Handles changes in the search input field.
     * @param {Event} event The change event.
     */
    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.onClickSearch();
    }

    /**
     * @description Applies the search filter to the service requests.
     * Filters `allServiceRequests` and updates `serviceRequests`.
     */
    onClickSearch() {
        if (!this.allServiceRequests) {
            return; // No requests to filter
        }

        const lowerCaseSearchTerm = this.searchTerm.toLowerCase();

        if (lowerCaseSearchTerm) {
            this.serviceRequests = this.allServiceRequests.filter(request => {
                const subjectMatches = request.Subject__c && request.Subject__c.toLowerCase().includes(lowerCaseSearchTerm);
                const descriptionMatches = request.Description__c && request.Description__c.toLowerCase().includes(lowerCaseSearchTerm);
                return subjectMatches || descriptionMatches;
            });
        } else {
            // If search term is empty, show all requests
            this.serviceRequests = [...this.allServiceRequests];
        }
    }

    /**
     * @description Sends the new service request to the POST endpoint.
     * Uses fetch() API for HTTP POST request.
     */
    async handleSubmitRequest() {
        // Form validation
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) {
            this.showToast('Please fill out all required fields.', 'error');
            return;
        }

        this.isSubmitting = true;
        this.isLoading = true; // Also show loading indicator here
        try {
            const response = await fetch(REST_API_BASE_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'OAuth  ' + this.sessionId,
                },
                body: JSON.stringify({
                    subject: this.subject,
                    description: this.description
                })
            });

            if (response.ok) {
                const data = await response.json();
                this.showToast(data.message || 'Request sent successfully!', 'success');
                // Reset fields
                this.subject = '';
                this.description = '';
                // Reload requests to display the new one
                await this.loadServiceRequests();
            } else {
                const errorData = await response.json();
                console.error('Error :', response.status, errorData);
                this.showToast(errorData.message || 'Error : ${response.status}', 'error');
            }
        } catch (error) {
            console.error('error:', error);
            this.showToast('Error: ${error}', 'error');
        } finally {
            this.isSubmitting = false;
            this.isLoading = false;
        }
    }





    /**
     * @description Displays a temporary feedback message.
     * @param {string} message The message to display.
     * @param {'success' | 'error'} type The type of message (determines color).
     */
    showToast(message, type) {
        const event = new ShowToastEvent({
            title: type == 'success' ? 'Success' : 'Error',
            message: message,
            variant: type
        });
        this.dispatchEvent(event);

        // LightningToast.show({
        //     label: type == 'success' ? 'Success' : 'Error',
        //     message: message,
        //     mode: 'sticky',
        //     variant: type
        // }, this);
    }






}