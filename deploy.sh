#!/bin/bash
# EduConnect Deployment Script
# This script validates, packages, and deploys the EduConnect platform

set -e  # Exit on any error

echo "🚀 Starting EduConnect Platform Deployment..."

# Check if Salesforce CLI is installed
if ! command -v sf &> /dev/null; then
    echo "❌ Salesforce CLI is not installed. Please install it first."
    echo "Visit: https://developer.salesforce.com/tools/sfdxcli"
    exit 1
fi

echo "✅ Salesforce CLI found"

# Validate the project structure
echo "🔍 Validating project structure..."

# Check for required directories
required_dirs=(
    "force-app/main/default/objects"
    "force-app/main/default/classes" 
    "force-app/main/default/lwc"
    "force-app/main/default/triggers"
    "force-app/main/default/flows"
    "force-app/main/default/permissionsets"
    "force-app/main/default/layouts"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "❌ Required directory not found: $dir"
        exit 1
    fi
done

echo "✅ Project structure validated"

# Validate metadata
echo "🔄 Validating Salesforce metadata..."
sf project validate source --target-org "$1" --wait 10

echo "✅ Metadata validation successful"

# Run Apex tests
echo "🧪 Running Apex tests..."
sf apex run test --target-org "$1" --code-coverage --result-format human --wait 10

echo "✅ Tests completed successfully"

# Deploy to org
echo "📦 Deploying to Salesforce org..."
sf project deploy start --target-org "$1" --wait 10

echo "🎉 EduConnect Platform deployed successfully!"

# Generate deployment summary
echo "📊 Deployment Summary:"
echo "===================="
echo "Custom Objects: 9"
echo "- Student__c"
echo "- Alumni__c" 
echo "- Course__c"
echo "- Student_Course_Enrollment__c"
echo "- Student_Support_Case__c"
echo "- Mentorship__c"
echo "- Event__c"
echo "- Event_Registration__c"
echo "- Donation__c"
echo ""
echo "Apex Classes: 5"
echo "- StudentDataService"
echo "- AlumniEngagementService"
echo "- EventManagementService"
echo "- StudentRiskAssessmentService"
echo "- StudentTriggerHandler"
echo ""
echo "Lightning Web Components: 4"
echo "- studentDashboard"
echo "- studentRiskIndicator"
echo "- supportCasesList" 
echo "- interventionModal"
echo ""
echo "Automation:"
echo "- Student Risk Assessment Flow"
echo "- Student Trigger for risk calculation"
echo ""
echo "Permission Sets: 3"
echo "- EduConnect Student Success Admin"
echo "- EduConnect Student Access"
echo "- EduConnect Alumni Access"
echo ""
echo "✅ Platform ready for use!"
echo ""
echo "Next Steps:"
echo "1. Assign permission sets to users"
echo "2. Create sample data for testing"
echo "3. Configure dashboards and reports"
echo "4. Set up email templates for automation"