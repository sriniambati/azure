##*****************  PLEASE READ CAREFULLY *****************
# a) Get latest version of Azure PowerShell from https://aka.ms/installaz
# b) Also, ensure you have latest version of "Az.Resources" by executing "Install-Module -Name Az.Resources -Force -Allowclobber" with Elevated Permissions.
#    Ref: https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources - Azure PowerShell offers two commands for applying tags - New-AzTag and Update-AzTag. You must have the Az.Resources module 1.12.0 or later. You can check your version with Get-Module Az.Resources. You can install that module or install Azure PowerShell 3.6.1 or later.
# c) Legal Disclaimer:
#    This document is for informational purposes only. MICROSOFT MAKES NO WARRANTIES, EXPRESS, IMPLIED, OR STATUTORY, AS TO THE INFORMATION IN THIS DOCUMENT.
#    This document is provided “as-is.” Information and views expressed in this document, including URL and other Internet website references, may change without notice. You bear the risk of using it.
#    Test this script in non-production environments, and make changes, as necessary. 
#    Microsoft and Azure are either registered trademarks or trademarks of Microsoft Corporation in the United States and/or other countries.
#    Copyright © 2021 Microsoft Corporation. All rights reserved.
# d) This script requires Subscription level READER permission to retrieve all necessary information
#
# This script does the following: 
# 1) Retrieves resource name, group, type, id, and created date for all resources in a given subscription;
# 2) Save the details as CSV
# 3) Create a CreatedDate Tag (if not already exits) for easy reporting.
#
################################################### 
# Change values of following variables
###################################################
$SP_NAME = "sriniscriptingsp1003"
$CSVFILEPATH = "C:\\Temp\\CreatedDateOutput.csv"
$CREATE_CREATEDDATE_TAG = "yes"
$TAGNAME_CREATEDDATE = "CreatedDate"

################################################### 
# Login and choose a subscription
###################################################
Connect-AzAccount
$subscription = (Get-AzSubscription | Out-GridView -Title "Select an Azure Subscription ..." -PassThru)
Set-AzContext -SubscriptionId $subscription.Id
$TENANT_ID = $subscription.TenantId
$SUBSCRIPTION_ID = $subscription.Id

################################################### 
# Script execution starts here
###################################################

# Create Service Principal
$SP = New-AzADServicePrincipal -DisplayName $SP_NAME
$CLIENT_SECRET_BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SP.Secret)
$CLIENT_SECRET = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($CLIENT_SECRET_BSTR)
$CLIENT_ID = $SP.ApplicationId
Write-Host "Created Service Principal '$SP_NAME'" -ForegroundColor Cyan

# Uncomment following lines, if you want to use existing Service Principal
#$CLIENT_SECRET='.-4VPTHSd~3.Z-9NyM4cGl29H0Ci.BM2.5'
#$CLIENT_ID='184a837c-02dc-4d7f-bbee-8a4476487c04'

# Call Azure Resource Manager to get details
$BODY = "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&resource=https://management.azure.com/"
$BEARERTOKEN = Invoke-RestMethod -Method Post -body $BODY -Uri https://login.microsoftonline.com/$TENANT_ID/oauth2/token
$HEADERS = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$HEADERS.Add("Authorization", "Bearer $($BEARERTOKEN.access_token)")
$HEADERS.Add("Content-Type", "application/json")
$RESULT = Invoke-RestMethod -Method Get -Headers $HEADERS -Uri "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resources?api-version=2020-06-01&%24expand=createdTime" 

# Display results
$PATTERN = "/resourceGroups/(.*?)/providers/"
$RESULT.value | Select name, @{Label = 'ResourceGroup'; Expression = {[regex]::Match($_.id, $PATTERN).Groups[1].value}}, type, createdTime 
Write-Host "Completed Invoke-RestMethod and displayed results" -ForegroundColor Cyan

# Export results to CSV
$CSVFILEPATH = $CSVFILEPATH -replace ".csv", ("_"+ (Get-Date –Format 'yyyyMMdd_HHmmss') + ".csv")
$RESULT.value | Select @{Label = "tenantId"; Expression = {$TENANT_ID}}, @{Label = "subscriptionId"; Expression = {$SUBSCRIPTION_ID}}, @{Label = 'resourceGroup'; Expression = {[regex]::Match($_.id, $PATTERN).Groups[1].value}}, @{Label = "resourceName"; Expression = {$_.name}}, @{Label = "resourceType"; Expression = {$_.type}}, createdTime, id | Export-Csv $CSVFILEPATH -Delimiter "," -NoTypeInformation
Write-Host "Generated file '$CSVFILEPATH'" -ForegroundColor Cyan

# Delete Service Principal
Remove-AzADServicePrincipal -ObjectId $SP.Id
Write-Host "Deleted Service Principal '$SP_NAME'" -ForegroundColor Cyan


#Create Tags
ie($CREATE_CREATEDDATE_TAG="yes")
{
    foreach($RESOURCE in $RESULT.value) 
    { 
        $RESOURCEGROUP = [regex]::Match($RESOURCE.id, $PATTERN).Groups[1].value
        $TAGS = (Get-AzResource -ResourceGroupName $RESOURCEGROUP -Name $RESOURCE.name -ResourceType $RESOURCE.type).Tags

        if($TAGS -eq $null)
        {
            Write-Host "No tags found for resource: '$RESOURCE'." 
            $TAGS = @{$TAGNAME_CREATEDDATE=$RESOURCE.createdTime}
            New-AzTag -ResourceId $RESOURCE.id -Tag $TAGS
        }
        else
        {
            if($TAGS.CreatedDate -eq $null)
            {
                Write-Host "CreatedDate tag not found for resource: $RESOURCE." 
                $TAGS += @{$TAGNAME_CREATEDDATE=$RESOURCE.createdTime} 
                Set-AzResource -ResourceId $RESOURCE.id -Tag $TAGS -Force
            }
            else
            {
                Write-Host "CreatedDate tag found!" 
            }
        }
    }
}

Write-Host "Script execution is complete'" -ForegroundColor Cyan







