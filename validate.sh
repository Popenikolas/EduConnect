#!/bin/bash
# EduConnect Project Validation Script
# Checks for common errors and inconsistencies

echo "🔍 Starting EduConnect Project Validation..."

# Check for field reference consistency
echo "📋 Checking field references..."

# Check for old field names that should be corrected
echo "  Checking for Current_GPA__c references (should be GPA__c)..."
grep -r "Current_GPA__c" force-app/main/default/ --exclude-dir=node_modules || echo "  ✅ No Current_GPA__c references found"

echo "  Checking for Class_Level__c references (should be Year_Level__c)..."
grep -r "Class_Level__c" force-app/main/default/ --exclude-dir=node_modules || echo "  ✅ No Class_Level__c references found"

# Check that all objects have proper API versions
echo "📄 Checking object API versions..."
for object_file in force-app/main/default/objects/*/*.object-meta.xml; do
    if ! grep -q "http://soap.sforce.com/2006/04/metadata" "$object_file"; then
        echo "  ⚠️  Warning: $object_file may have incorrect namespace"
    fi
done

# Check that all classes have proper structure
echo "🎯 Checking Apex class structure..."
for class_file in force-app/main/default/classes/*.cls; do
    if [[ -f "$class_file" ]]; then
        filename=$(basename "$class_file" .cls)
        
        # Check if sharing declaration exists
        if ! grep -q "with sharing\|without sharing\|inherited sharing" "$class_file"; then
            echo "  ⚠️  Warning: $filename missing sharing declaration"
        fi
        
        # Check if @AuraEnabled methods exist without proper error handling
        if grep -q "@AuraEnabled" "$class_file" && ! grep -q "AuraHandledException" "$class_file"; then
            echo "  ⚠️  Warning: $filename has @AuraEnabled methods but no error handling"
        fi
    fi
done

# Check LWC components for common issues
echo "🎨 Checking Lightning Web Components..."
for lwc_dir in force-app/main/default/lwc/*/; do
    if [[ -d "$lwc_dir" ]]; then
        component_name=$(basename "$lwc_dir")
        
        # Check if JavaScript file exists
        if [[ ! -f "${lwc_dir}${component_name}.js" ]]; then
            echo "  ⚠️  Warning: $component_name missing JavaScript file"
        fi
        
        # Check if HTML file exists
        if [[ ! -f "${lwc_dir}${component_name}.html" ]]; then
            echo "  ⚠️  Warning: $component_name missing HTML file"
        fi
        
        # Check for unused imports
        if [[ -f "${lwc_dir}${component_name}.js" ]]; then
            if grep -q "ShowToastEvent" "${lwc_dir}${component_name}.js" && ! grep -q "dispatchEvent.*ShowToastEvent\|new ShowToastEvent" "${lwc_dir}${component_name}.js"; then
                echo "  ⚠️  Warning: $component_name has unused ShowToastEvent import"
            fi
        fi
    fi
done

# Check for trigger best practices
echo "⚡ Checking triggers..."
for trigger_file in force-app/main/default/triggers/*.trigger; do
    if [[ -f "$trigger_file" ]]; then
        filename=$(basename "$trigger_file" .trigger)
        
        # Check if trigger has handler pattern
        if ! grep -q "Handler\|Service" "$trigger_file"; then
            echo "  ⚠️  Warning: $filename should use handler pattern"
        fi
        
        # Check for DML in trigger (should be in handler)
        if grep -q "insert \|update \|delete \|upsert " "$trigger_file"; then
            echo "  ⚠️  Warning: $filename contains DML operations (should be in handler)"
        fi
    fi
done

# Check package.xml for completeness
echo "📦 Checking package.xml..."
if [[ -f "manifest/package.xml" ]]; then
    # Check if all object types are included
    custom_objects=$(find force-app/main/default/objects -name "*.object-meta.xml" | wc -l)
    package_objects=$(grep -c "<name>.*__c</name>" manifest/package.xml || echo "0")
    
    if [[ $custom_objects -gt $package_objects ]]; then
        echo "  ⚠️  Warning: package.xml may be missing some custom objects"
    fi
else
    echo "  ⚠️  Warning: package.xml not found in manifest directory"
fi

# Final summary
echo ""
echo "🎉 Validation Complete!"
echo ""
echo "📊 Project Summary:"
echo "  Custom Objects: $(find force-app/main/default/objects -name "*.object-meta.xml" | wc -l)"
echo "  Apex Classes: $(find force-app/main/default/classes -name "*.cls" | wc -l)"
echo "  LWC Components: $(find force-app/main/default/lwc -maxdepth 1 -type d | wc -l)"
echo "  Triggers: $(find force-app/main/default/triggers -name "*.trigger" | wc -l)"
echo "  Flows: $(find force-app/main/default/flows -name "*.flow-meta.xml" | wc -l)"
echo ""
echo "✅ Project validation complete!"
echo "📝 Review any warnings above and fix before deployment."