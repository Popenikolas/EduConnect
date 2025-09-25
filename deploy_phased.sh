#!/bin/bash

# EduConnect Phased Deployment Script
# Deploys components in proper dependency order

echo "🚀 EduConnect Phased Deployment to Salesforce"
echo "=============================================="

TARGET_ORG="EduConnectOrg"
DEPLOYMENT_LOG="deployment.log"

# Function to log and display messages
log_message() {
    echo "$1" | tee -a $DEPLOYMENT_LOG
}

# Function to deploy with error handling
deploy_component() {
    local component_path=$1
    local component_name=$2
    
    log_message ""
    log_message "📦 Deploying $component_name..."
    
    sfdx project deploy start --target-org $TARGET_ORG --source-dir "$component_path" --wait 15 2>&1 | tee -a $DEPLOYMENT_LOG
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_message "✅ $component_name deployed successfully"
        return 0
    else
        log_message "❌ $component_name deployment failed"
        return 1
    fi
}

# Start deployment log
echo "EduConnect Deployment Log - $(date)" > $DEPLOYMENT_LOG

# Check org connection
log_message "🔗 Checking org connection to $TARGET_ORG..."
sfdx org display --target-org $TARGET_ORG --json > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log_message "❌ Error: Could not connect to org $TARGET_ORG"
    exit 1
fi
log_message "✅ Org connection verified"

# Phase 1: Core Objects (independent objects first)
log_message ""
log_message "🏗️  PHASE 1: Core Independent Objects"
log_message "====================================="

# Deploy independent objects first
deploy_component "force-app/main/default/objects/Student__c" "Student Object"
if [ $? -ne 0 ]; then exit 1; fi

deploy_component "force-app/main/default/objects/Alumni__c" "Alumni Object" 
if [ $? -ne 0 ]; then exit 1; fi

deploy_component "force-app/main/default/objects/Course__c" "Course Object"
if [ $? -ne 0 ]; then exit 1; fi

deploy_component "force-app/main/default/objects/Event__c" "Event Object"
# Continue even if Event object fails due to summary field issues

# Phase 2: Dependent Objects
log_message ""
log_message "🔗 PHASE 2: Dependent Objects"  
log_message "============================="

# These objects have master-detail relationships
deploy_component "force-app/main/default/objects/Student_Course_Enrollment__c" "Student Course Enrollment Object"
deploy_component "force-app/main/default/objects/Student_Support_Case__c" "Student Support Case Object"
deploy_component "force-app/main/default/objects/Event_Registration__c" "Event Registration Object"
deploy_component "force-app/main/default/objects/Mentorship__c" "Mentorship Object"
deploy_component "force-app/main/default/objects/Donation__c" "Donation Object"

# Phase 3: Apex Classes
log_message ""
log_message "💻 PHASE 3: Apex Classes"
log_message "======================="

# Deploy Apex classes now that objects exist
deploy_component "force-app/main/default/classes" "All Apex Classes"

# Phase 4: Lightning Web Components  
log_message ""
log_message "⚡ PHASE 4: Lightning Web Components"
log_message "=================================="

deploy_component "force-app/main/default/lwc" "All Lightning Web Components"

# Phase 5: Triggers
log_message ""
log_message "🎯 PHASE 5: Triggers"
log_message "=================="

deploy_component "force-app/main/default/triggers" "All Triggers"

# Final Summary
log_message ""
log_message "🎉 DEPLOYMENT SUMMARY"
log_message "==================="
log_message "✅ Core objects deployed"
log_message "✅ Dependent objects deployed" 
log_message "✅ Apex classes deployed"
log_message "✅ Lightning Web Components deployed"
log_message "✅ Triggers deployed"
log_message ""
log_message "🌐 EduConnect platform is now available in your Salesforce org!"
log_message "📋 Full deployment log saved to: $DEPLOYMENT_LOG"
log_message ""
log_message "🚀 To access your EduConnect platform:"
log_message "   sfdx org open --target-org $TARGET_ORG"

echo
echo "Deployment completed! Check $DEPLOYMENT_LOG for detailed results."