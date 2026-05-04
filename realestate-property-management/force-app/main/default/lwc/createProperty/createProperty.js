import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createPropertyWithImages from '@salesforce/apex/PropertyController.createPropertyWithImages';

export default class CreateProperty extends NavigationMixin(LightningElement) {

    // Form fields
    @track name = '';
    @track address = '';
    @track city = '';
    @track state = '';
    @track postalCode = '';
    @track country = '';
    @track type = 'Residential';
    @track status = 'Available';
    @track furnishingStatus = 'Unfurnished';
    @track monthlyRent;
    @track description = '';

    // Image handling
    @track uploadedImages = [];
    @track uploadedImageNames = [];
    @track errorMessage = '';
    @track isSaving = false;

    typeOptions = [
        { label: 'Residential', value: 'Residential' },
        { label: 'Commercial', value: 'Commercial' }
    ];

    statusOptions = [
        { label: 'Available', value: 'Available' },
        { label: 'Occupied', value: 'Occupied' }
    ];

    furnishingOptions = [
        { label: 'Furnished', value: 'Furnished' },
        { label: 'Semi-Furnished', value: 'Semi-Furnished' },
        { label: 'Unfurnished', value: 'Unfurnished' }
    ];

    // Field change handlers
    handleNameChange(event)        { this.name = event.target.value; }
    handleAddressChange(event)     { this.address = event.target.value; }
    handleCityChange(event)        { this.city = event.target.value; }
    handleStateChange(event)       { this.state = event.target.value; }
    handlePostalCodeChange(event)  { this.postalCode = event.target.value; }
    handleCountryChange(event)     { this.country = event.target.value; }
    handleRentChange(event)        { this.monthlyRent = event.target.value; }
    handleDescriptionChange(event) { this.description = event.target.value; }
    handleTypeChange(event)        { this.type = event.detail.value; }
    handleStatusChange(event)      { this.status = event.detail.value; }
    handleFurnishingChange(event)  { this.furnishingStatus = event.detail.value; }

    // Image upload handler - reads files as base64
    handleImageUpload(event) {
        const files = event.target.files;
        if (!files || files.length === 0) return;

        this.uploadedImages = [];
        this.uploadedImageNames = [];
        this.errorMessage = '';

        const fileArray = Array.from(files);
        let processedCount = 0;

        fileArray.forEach(file => {
            const reader = new FileReader();
            reader.onload = () => {
                // Strip the data:image/xxx;base64, prefix
                const base64Data = reader.result.split(',')[1];
                this.uploadedImages.push({
                    fileName: file.name,
                    base64Data: base64Data
                });
                this.uploadedImageNames = [...this.uploadedImageNames, file.name];
                processedCount++;
            };
            reader.readAsDataURL(file);
        });
    }

    // Save is disabled if no images or currently saving
    get hasImages() {
        return this.uploadedImages.length > 0;
    }

    get isSaveDisabled() {
        return this.uploadedImages.length === 0 || this.isSaving;
    }

    handleSave() {
        // Validate required fields
        if (!this.name || !this.address || !this.city || !this.state || 
            !this.postalCode || !this.country || !this.monthlyRent || !this.description) {
            this.errorMessage = 'Please fill in all required fields.';
            return;
        }

        if (this.uploadedImages.length === 0) {
            this.errorMessage = 'Please upload at least one property image.';
            return;
        }

        this.isSaving = true;
        this.errorMessage = '';

        // Build property object
        const property = {
            sobjectType: 'Property__c',
            Name: this.name,
            Address__c: this.address,
            City__c: this.city,
            State__c: this.state,
            Postal_Code__c: this.postalCode,
            Country__c: this.country,
            Type__c: this.type,
            Status__c: this.status,
            Furnishing_Status__c: this.furnishingStatus,
            Monthly_Rent__c: this.monthlyRent,
            Description__c: this.description
        };

        createPropertyWithImages({
            property: property,
            imagesJson: JSON.stringify(this.uploadedImages)
        })
        .then(propertyId => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Property created successfully with images!',
                variant: 'success'
            }));
            // Navigate to the new property record
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: propertyId,
                    objectApiName: 'Property__c',
                    actionName: 'view'
                }
            });
        })
        .catch(error => {
            this.errorMessage = error.body ? error.body.message : 'Error creating property.';
            this.isSaving = false;
        });
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Property__c',
                actionName: 'list'
            },
            state: {
                filterName: 'All'
            }
        });
    }
}