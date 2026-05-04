import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getProperties from '@salesforce/apex/PropertyController.getProperties';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PropertyList extends NavigationMixin(LightningElement) {
    @track properties = [];
    @track pageNumber = 1;
    @track totalPages = 1;
    @track totalRecords = 0;
    
    @track minPrice;
    @track maxPrice;
    @track statusFilter = 'All';
    @track furnishingFilter = 'All';
    
    pageSize = 25;
    
    statusOptions = [
        { label: 'All', value: 'All' },
        { label: 'Available', value: 'Available' },
        { label: 'Occupied', value: 'Occupied' }
    ];
    
    furnishingOptions = [
        { label: 'All', value: 'All' },
        { label: 'Furnished', value: 'Furnished' },
        { label: 'Semi-Furnished', value: 'Semi-Furnished' },
        { label: 'Unfurnished', value: 'Unfurnished' }
    ];
    
    connectedCallback() {
        this.loadProperties();
    }
    
    loadProperties() {
        getProperties({
            pageNumber: this.pageNumber,
            pageSize: this.pageSize,
            minPrice: this.minPrice,
            maxPrice: this.maxPrice,
            statusFilter: this.statusFilter,
            furnishingFilter: this.furnishingFilter
        })
        .then(result => {
            // Map each property to include a recordUrl for navigation
            this.properties = result.properties.map(p => ({
                ...p,
                recordUrl: '/lightning/r/Property__c/' + p.Id + '/view'
            }));
            this.totalRecords = result.totalRecords;
            this.totalPages = result.totalPages;
        })
        .catch(error => {
            this.showToast('Error', 'Error loading properties', 'error');
        });
    }
    
    handleMinPriceChange(event) {
        this.minPrice = event.target.value;
        this.pageNumber = 1;
        this.loadProperties();
    }
    
    handleMaxPriceChange(event) {
        this.maxPrice = event.target.value;
        this.pageNumber = 1;
        this.loadProperties();
    }
    
    handleStatusChange(event) {
        this.statusFilter = event.detail.value;
        this.pageNumber = 1;
        this.loadProperties();
    }
    
    handleFurnishingChange(event) {
        this.furnishingFilter = event.detail.value;
        this.pageNumber = 1;
        this.loadProperties();
    }
    
    handlePrevious() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.loadProperties();
        }
    }
    
    handleNext() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.loadProperties();
        }
    }
    
    get isPreviousDisabled() {
        return this.pageNumber <= 1;
    }
    
    get isNextDisabled() {
        return this.pageNumber >= this.totalPages;
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}