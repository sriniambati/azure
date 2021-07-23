##*****************  PLEASE READ CAREFULLY *****************
# a) Run "PowerShell ISE" with elevated permissions (i.e. as Administrator)
# b) Get latest version of Azure PowerShell from https://aka.ms/installaz
# c) Legal Disclaimer:
#    This document is for informational purposes only. MICROSOFT MAKES NO WARRANTIES, EXPRESS, IMPLIED, OR STATUTORY, AS TO THE INFORMATION IN THIS DOCUMENT.
#    This document is provided “as-is.” Information and views expressed in this document, including URL and other Internet website references, may change without notice. You bear the risk of using it. 
#    Microsoft and Azure are either registered trademarks or trademarks of Microsoft Corporation in the United States and/or other countries.
#    Copyright © 2019 Microsoft Corporation. All rights reserved.
# d) This script requires OWNER permission to retrieve all necessary Storage Account information
#
# This script does the following: 
# 1) Retrieves details of all storage account details for a given scope i.e. i) Resource Group; or ii) Subscription; or iii) All Subscriptions that user has access to
# 2) Saves the details as CSV
#
################################################### 
# Change values of following variables
###################################################
# Script uses following variable value as file path to save the details as CSV
$reportFolderPath = "c:\temp"
# The scope of the script is restricted to a specific subscription if a Subscription GUID is specified below
$subscriptionId = "484dbcc4-0579-4e2a-8fff-404cc6fc77d8"
# The scope of the script is restricted to a specific resource group if a resource group name is specified below. 
$resourceGroupName = "" 
# Change this option if you want to get container or account level report. Options: account, container, blob. 
$outputLevel = "blob" 

#Login to Azure
Write-Host "Login to Azure..." -ForegroundColor Yellow 
Login-AzAccount

# Get list of subscriptions
If ($subscriptionId)
{ $subscriptionList = Get-AzSubscription -WarningAction silentlyContinue -SubscriptionId $subscriptionId }
Else
{ $subscriptionList = Get-AzSubscription -WarningAction silentlyContinue}

$storageAccountInfoList = @()

# Get all storageAccounts in all subscriptions
foreach($subscription in $subscriptionList)
{
    Select-AzSubscription -SubscriptionName $subscription.Name

    If ($resourceGroupName)
    { $storageAccountlist = Get-AzStorageAccount -ResourceGroupName $resourceGroupName }
    Else
    { $storageAccountlist = Get-AzStorageAccount }
     

    foreach($storageAccount in $storageAccountlist) 
    { 
        $storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -StorageAccountName $storageAccount.StorageAccountName)[0].Value
        $storageContext = New-AzureStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageAccountKey
        $containerList = Get-AzureStorageContainer -Context $storageContext | Select-Object -ExpandProperty Name
        $containerListSize = 0

        foreach ($Container in $containerList) {
           
            $blobList = Get-AzureStorageBlob -Container $container -Context $storageContext
            $blobListSize = 0
            
            foreach ($Blob in $blobList) {

                $blobListSize = $blobListSize + ($Blob.Length / 1048576)

                if ($outputLevel -eq "blob")
                {
                    $storageAccountInfo = New-Object System.Object
                    $storageAccountInfo | Add-Member -type NoteProperty -name SubscriptionId -value $subscription.SubscriptionId
                    $storageAccountInfo | Add-Member -type NoteProperty -name SubscriptionName -value $subscription.Name
                    $storageAccountInfo | Add-Member -type NoteProperty -name ResourceGroupName -value $storageAccount.ResourceGroupName
                    $storageAccountInfo | Add-Member -type NoteProperty -name Location -value $storageAccount.Location
                    $storageAccountInfo | Add-Member -type NoteProperty -name StorageAccountName -value $storageAccount.StorageAccountName
                    $storageAccountInfo | Add-Member -type NoteProperty -name ContainerName -value $container
                    $storageAccountInfo | Add-Member -type NoteProperty -name StorageAccessTier -value $storageAccount.AccessTier
                    $storageAccountInfo | Add-Member -type NoteProperty -name StorageEncryption -value $storageAccount.Encription
                    $storageAccountInfo | Add-Member -type NoteProperty -name StorageKind -value $storageAccount.Kind
                    $storageAccountInfo | Add-Member -type NoteProperty -name StorageSkuName -value $storageAccount.Sku.Name
                    $storageAccountInfo | Add-Member -type NoteProperty -name BlobName -value $blob.Name
                    $storageAccountInfo | Add-Member -type NoteProperty -name ContainerLength -value $blob.Length
                    $storageAccountInfoList += $storageAccountInfo
                }

            }

            if ($outputLevel -eq "container")
            {
                $containerSize = [math]::Round($BlobListSize,2)
                $storageAccountInfo = New-Object System.Object
                $storageAccountInfo | Add-Member -type NoteProperty -name SubscriptionId -value $subscription.SubscriptionId
                $storageAccountInfo | Add-Member -type NoteProperty -name SubscriptionName -value $subscription.Name
                $storageAccountInfo | Add-Member -type NoteProperty -name ResourceGroupName -value $storageAccount.ResourceGroupName
                $storageAccountInfo | Add-Member -type NoteProperty -name Location -value $storageAccount.Location
                $storageAccountInfo | Add-Member -type NoteProperty -name StorageAccountName -value $storageAccount.StorageAccountName
                $storageAccountInfo | Add-Member -type NoteProperty -name ContainerName -value $container
                $storageAccountInfo | Add-Member -type NoteProperty -name StorageAccessTier -value $storageAccount.AccessTier
                $storageAccountInfo | Add-Member -type NoteProperty -name StorageEncryption -value $storageAccount.Encription
                $storageAccountInfo | Add-Member -type NoteProperty -name StorageKind -value $storageAccount.Kind
                $storageAccountInfo | Add-Member -type NoteProperty -name StorageSkuName -value $storageAccount.Sku.Name
                $storageAccountInfo | Add-Member -type NoteProperty -name ContainerLengthInMB -value $containerSize
                $storageAccountInfoList += $storageAccountInfo
            }

            $containerListSize = $containerListSize + $blobListSize
        }

        if ($outputLevel -eq "account")
        {
            $storageAccountSize = [math]::Round($ContainerListSize,2)
            $storageAccountInfo = New-Object System.Object
            $storageAccountInfo | Add-Member -type NoteProperty -name SubscriptionId -value $subscription.SubscriptionId                    
            $storageAccountInfo | Add-Member -type NoteProperty -name SubscriptionName -value $subscription.Name
            $storageAccountInfo | Add-Member -type NoteProperty -name ResourceGroupName -value $storageAccount.ResourceGroupName
            $storageAccountInfo | Add-Member -type NoteProperty -name Location -value $storageAccount.Location         
            $storageAccountInfo | Add-Member -type NoteProperty -name StorageAccountName -value $storageAccount.StorageAccountName
            $storageAccountInfo | Add-Member -type NoteProperty -name StorageAccessTier -value $storageAccount.AccessTier
            $storageAccountInfo | Add-Member -type NoteProperty -name StorageEncryption -value $storageAccount.Encription
            $storageAccountInfo | Add-Member -type NoteProperty -name StorageKind -value $storageAccount.Kind
            $storageAccountInfo | Add-Member -type NoteProperty -name StorageSkuName -value $storageAccount.Sku.Name
            $storageAccountInfo | Add-Member -type NoteProperty -name StorageLengthInMB -value $storageAccountSize            
            $storageAccountInfoList += $storageAccountInfo   
        }                 
    }

    # Write result
    $storageAccountInfoList | Format-Table
    # Write to CSV file
    Write-Host "Writing Storage Details to $outputFile for subscription '$($subscription.Name)'" -ForegroundColor Cyan
    $outputFile = $reportFolderPath+"\AzureStorageReport_" + $subscription.SubscriptionId + "_" + (Get-Date -UFormat "%Y%m%d_%I%M%S_%p").tostring() + ".csv" 
    $storageAccountInfoList | Export-csv -NoType -Append $outputFile -Force
}





