# EduConnect Salesforce Deployment Commands

## Option 1: Automated Deployment (Recommended)

Run the automated deployment script:
```bash
chmod +x deploy_to_salesforce.sh
./deploy_to_salesforce.sh
```

## Option 2: Manual Step-by-Step Deployment

### Step 1: Verify Org Connection
```bash
# Check available orgs
sfdx org list

# Display current org details
sfdx org display --target-org EduConnectOrg
```

### Step 2: Pre-deployment Validation
```bash
# Validate metadata without deploying
sfdx project deploy validate --target-org EduConnectOrg --source-dir force-app/main/default --wait 10
```

### Step 3: Deploy All Components
```bash
# Deploy everything at once (recommended)
sfdx project deploy start --target-org EduConnectOrg --source-dir force-app/main/default --wait 15
```

### Step 4: Verify Deployment
```bash
# Check deployment status
sfdx project deploy report --target-org EduConnectOrg

# List deployed components
sfdx org list metadata --target-org EduConnectOrg --metadata-type CustomObject
sfdx org list metadata --target-org EduConnectOrg --metadata-type ApexClass
sfdx org list metadata --target-org EduConnectOrg --metadata-type LightningComponentBundle
```

## Option 3: Component-by-Component Deployment (If Needed)

If the full deployment fails, try deploying components in this order:

### 1. Custom Objects First
```bash
sfdx project deploy start --target-org EduConnectOrg --source-dir force-app/main/default/objects --wait 10
```

### 2. Apex Classes
```bash
sfdx project deploy start --target-org EduConnectOrg --source-dir force-app/main/default/classes --wait 10
```

### 3. Lightning Web Components
```bash
sfdx project deploy start --target-org EduConnectOrg --source-dir force-app/main/default/lwc --wait 10
```

### 4. Triggers
```bash
sfdx project deploy start --target-org EduConnectOrg --source-dir force-app/main/default/triggers --wait 10
```

### 5. Flows
```bash
sfdx project deploy start --target-org EduConnectOrg --source-dir force-app/main/default/flows --wait 10
```

### 6. Permission Sets
```bash
sfdx project deploy start --target-org EduConnectOrg --source-dir force-app/main/default/permissionsets --wait 10
```

### 7. Profiles
```bash
sfdx project deploy start --target-org EduConnectOrg --source-dir force-app/main/default/profiles --wait 10
```

## Post-Deployment Verification

### Check Deployed Objects
```bash
# Verify custom objects
sfdx data query --target-org EduConnectOrg --query "SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName LIKE '%__c'"

# Test Apex classes
sfdx apex run test --target-org EduConnectOrg --class-names StudentDataServiceTest --wait 5
```

### Access Your EduConnect Platform
```bash
# Open your org
sfdx org open --target-org EduConnectOrg

# Navigate to:
# - App Launcher → EduConnect
# - Custom Objects: Student, Alumni, Course, Event
# - Lightning Pages with your components
```

## Troubleshooting

### If Deployment Fails:
1. Check the error messages in the deployment output
2. Run validation again: `sfdx project deploy validate --target-org EduConnectOrg --source-dir force-app/main/default`
3. Fix any field references or metadata issues
4. Try component-by-component deployment

### Common Issues and Fixes:
- **Field not found**: Check object metadata for correct field definitions
- **Sharing model error**: Ensure objects have appropriate sharing settings
- **Permission issues**: Verify your user has deployment permissions
- **API version**: Ensure your org supports API version 64.0

## Success Indicators
✅ All components deploy without errors
✅ Custom objects visible in Setup
✅ Apex classes compile successfully
✅ LWC components available in Lightning App Builder
✅ Flows active and running
✅ Permission sets assigned correctly