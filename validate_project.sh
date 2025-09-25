#!/bin/bash

echo "=== EduConnect Project Validation ==="
echo

# Check for field reference issues
echo "Checking for field reference issues..."

# Check for Current_GPA__c references (should be GPA__c)
echo "=== Checking for Current_GPA__c references ==="
grep -r "Current_GPA__c" force-app/ --include="*.cls" --include="*.js" --include="*.xml" || echo "No Current_GPA__c references found"

# Check for Class_Level__c references (should be Year_Level__c)
echo "=== Checking for Class_Level__c references ==="
grep -r "Class_Level__c" force-app/ --include="*.cls" --include="*.js" --include="*.xml" || echo "No Class_Level__c references found"

# Check for missing field definitions
echo "=== Checking Apex class syntax ==="
find force-app/ -name "*.cls" -exec sh -c 'echo "Checking $1:"; grep -n "SOQL\|SELECT\|FROM" "$1" | head -3' _ {} \;

# Check LWC components
echo "=== Checking LWC components ==="
find force-app/main/default/lwc/ -name "*.js" -exec sh -c 'echo "Checking $1:"; grep -n "import\|@api\|@track" "$1" | head -3' _ {} \;

# Check for common issues
echo "=== Checking for common issues ==="
echo "Checking for sharing declarations..."
grep -r "without sharing\|with sharing" force-app/ --include="*.cls" | wc -l | xargs echo "Classes with sharing declarations:"

echo
echo "=== Validation Complete ==="