#!/bin/bash

# EduConnect Deployment Script
# This script will deploy the EduConnect project to your Salesforce org

echo "🚀 EduConnect Deployment to Salesforce"
echo "======================================"

# Set the target org (you can change this if needed)
TARGET_ORG="EduConnectOrg"

echo "📋 Pre-deployment validation..."
echo "Target Org: $TARGET_ORG"
echo

# Check org connection
echo "🔗 Checking org connection..."
sfdx org display --target-org $TARGET_ORG
if [ $? -ne 0 ]; then
    echo "❌ Error: Could not connect to org $TARGET_ORG"
    echo "Available orgs:"
    sfdx org list
    exit 1
fi

echo "✅ Org connection verified"
echo

# Validate metadata before deployment
echo "🔍 Validating metadata..."
sfdx project deploy validate --target-org $TARGET_ORG --source-dir force-app/main/default --wait 10

if [ $? -eq 0 ]; then
    echo "✅ Metadata validation successful"
    echo
    
    # Proceed with deployment
    echo "🚀 Starting deployment..."
    echo "Deploying all EduConnect components..."
    
    sfdx project deploy start --target-org $TARGET_ORG --source-dir force-app/main/default --wait 15
    
    if [ $? -eq 0 ]; then
        echo
        echo "🎉 DEPLOYMENT SUCCESSFUL!"
        echo "=============================="
        echo "✅ All EduConnect components deployed successfully"
        echo "✅ Custom Objects: Student__c, Alumni__c, Course__c, Event__c, etc."
        echo "✅ Apex Classes: StudentDataService, AlumniEngagementService, etc."
        echo "✅ Lightning Web Components: studentDashboard, studentRiskIndicator, etc."
        echo "✅ Triggers: StudentTrigger"
        echo "✅ Flows: Student_Risk_Assessment_Flow"
        echo "✅ Permission Sets and Profiles"
        echo
        echo "🌐 Your EduConnect platform is now live in Salesforce!"
        echo "You can access it through your org at: https://$(sfdx org display --target-org $TARGET_ORG --json | jq -r '.result.instanceUrl')"
        
    else
        echo "❌ Deployment failed. Check the errors above."
        echo "Run the deployment again after fixing any issues."
        exit 1
    fi
    
else
    echo "❌ Metadata validation failed"
    echo "Please review and fix the validation errors above before deploying."
    echo
    echo "Common fixes:"
    echo "- Check field references in custom objects"
    echo "- Verify sharing model settings"
    echo "- Ensure all required fields are defined"
    exit 1
fi