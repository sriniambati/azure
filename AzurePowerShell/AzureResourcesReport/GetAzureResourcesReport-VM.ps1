##*****************  PLEASE READ CAREFULLY *****************
# a) Run "PowerShell ISE" with elevated permissions (i.e. as Administrator)
# b) Get latest version of Azure PowerShell from https://aka.ms/installaz
# c) Legal Disclaimer:
#    This document is for informational purposes only. MICROSOFT MAKES NO WARRANTIES, EXPRESS, IMPLIED, OR STATUTORY, AS TO THE INFORMATION IN THIS DOCUMENT.
#    This document is provided “as-is.” Information and views expressed in this document, including URL and other Internet website references, may change without notice. You bear the risk of using it. 
#    Microsoft and Azure are either registered trademarks or trademarks of Microsoft Corporation in the United States and/or other countries.
#    Copyright © 2019 Microsoft Corporation. All rights reserved.
# d) This script requires Subscription level READER permission to retrieve all necessary VM information
#
# This script does the following: 
# 1) Retrieves details of all VMs for a given scope i.e. i) Resource Group; or ii) Subscription; or iii) All Subscriptions that user has access to
# 2) Saves the details as CSV
#
################################################### 
# Change values of following variables
###################################################
# Script uses following variable value as file path to save the details of the VMs as CSV
$reportFolderPath = "c:\temp"
# The scope of the script is restricted to a specific subscription if a Subscription GUID is specified below
$subscriptionId = "484dbcc4-0579-4e2a-8fff-404cc6fc77d8"
# The scope of the script is restricted to a specific resource group if a resource group name is specified below.
$resourceGroupName = "" 

################################################### 
# Script execution starts here
###################################################
Write-Host "Login to Azure..." -ForegroundColor Yellow 
Login-AzAccount 

$sw = [Diagnostics.Stopwatch]::StartNew()
$sqlVMResourceType = "Microsoft.SqlVirtualMachine/SqlVirtualMachines"

Write-Host "Getting Azure subscriptions..." -ForegroundColor Cyan
# Get list of subscriptions
if ($subscriptionId){ 
    $subscriptionList = Get-AzSubscription -WarningAction silentlyContinue -SubscriptionId $subscriptionId  }
else{ 
    $subscriptionList = Get-AzSubscription -WarningAction silentlyContinue }


# Get all VMs in all subscriptions
foreach($subscription in $subscriptionList)
{
    $vmInfoList = @()
    $context = Set-AzContext -SubscriptionId $subscription.Id
    Write-Host "Getting VM Details from Azure subscription '$($subscription.Name)'" -ForegroundColor Cyan

    if ($resourceGroupName){ 
        $vmList = Get-AzVM -WarningAction silentlyContinue -ResourceGroupName $resourceGroupName }
    else{ 
        $vmList = Get-AzVM -WarningAction silentlyContinue }
     

    foreach($vm in $vmList) 
    { 
        Write-Host "Getting details of VM '$($vm.Name)'" -ForegroundColor Green
        $nic = Get-AzNetworkInterface | where {$_.Id -eq $vm.NetworkProfile.NetworkInterfaces.Id}
        $vnet=Get-AzVirtualNetwork | Where { $_.Subnets.ID –match $nic.IpConfigurations.subnet.id }
        $pip = $nic.IPConfigurations.PublicIpAddress.Id
        $managedDisk = if (!($vm.StorageProfile.OsDisk.Vhd).uri) { "Yes" } else {"No"}
        $pipValue = ""
        if($pip){
            $pipValue = (Get-AzPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $pip.Substring($pip.lastindexof('/')+1)).IpAddress
        }
        $vmSize = Get-Azvmsize -location eastus2 | ?{ $_.name -eq $vm.HardwareProfile.VmSize }
        $powerState = ((Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -WarningAction silentlyContinue -Status).Statuses[1]).code
        $nsgName = (Get-AzNetworkSecurityGroup | where { $_.ID -eq $nic.NetworkSecurityGroup.ID }).Name
        $subnetName = ($vnet.Subnets | Where { $_.ID –match $nic.IpConfigurations.subnet.id }).Name
        $sqlLicenseType = ""

        if ($vm.StorageProfile.ImageReference.Offer -match [regex]"SQL(.*)") { 
            $sqlVm = Get-AzResource -ResourceType $sqlVMResourceType -ResourceGroupName $vm.ResourceGroupName -ResourceName $vm.Name -ErrorAction SilentlyContinue
            if($sqlVm){
                $sqlLicenseType = $sqlVm.Properties.sqlServerLicenseType
            }
        }

        $ddNames = ""
        foreach ($i in $vm.StorageProfile.DataDisks) { $ddNames += $i.Name + "; " }

        $vmInfo = New-Object System.Object
        $vmInfo | Add-Member -type NoteProperty -name SubscriptionId -value $subscription.SubscriptionId
        $vmInfo | Add-Member -type NoteProperty -name SubscriptionName -value $subscription.Name
        $vmInfo | Add-Member -type NoteProperty -name ResourceGroupName -value $vm.ResourceGroupName
        $vmInfo | Add-Member -type NoteProperty -name VMName -value $vm.Name
        $vmInfo | Add-Member -type NoteProperty -name OSType -value $vm.StorageProfile.OsDisk.OsType
        $vmInfo | Add-Member -type NoteProperty -name Publisher -value $vm.StorageProfile.ImageReference.Publisher
        $vmInfo | Add-Member -type NoteProperty -name Offer -value $vm.StorageProfile.ImageReference.Offer
        $vmInfo | Add-Member -type NoteProperty -name SKU -value $vm.StorageProfile.ImageReference.Sku
        $vmInfo | Add-Member -type NoteProperty -name AdminUserName -value $vm.OSProfile.AdminUsername
        $vmInfo | Add-Member -type NoteProperty -name VMSize -value $vm.HardwareProfile.VmSize
        $vmInfo | Add-Member -type NoteProperty -name NumberOfCores -value $vmSize.NumberOfCores
        $vmInfo | Add-Member -type NoteProperty -name MemoryInMB -value $vmSize.MemoryInMB
        $vmInfo | Add-Member -type NoteProperty -name MaxDataDiskCount -value $vmSize.MaxDataDiskCount
        $vmInfo | Add-Member -type NoteProperty -name OSDiskSizeInMB -value $vmSize.OSDiskSizeInMB
        $vmInfo | Add-Member -type NoteProperty -name ResourceDiskSizeInMB -value $vmSize.ResourceDiskSizeInMB
        $vmInfo | Add-Member -type NoteProperty -name NSG -value $nsgName
        $vmInfo | Add-Member -type NoteProperty -name PublicIPAddress -value $pipValue
        $vmInfo | Add-Member -type NoteProperty -name PrivateIPAddress -value $nic.IPConfigurations.PrivateIpAddress
        $vmInfo | Add-Member -type NoteProperty -name VNet -value $vnet.Name
        $vmInfo | Add-Member -type NoteProperty -name Subnet -value $subnetName
        $vmInfo | Add-Member -type NoteProperty -name UsingManagedDisk -value $managedDisk
        $vmInfo | Add-Member -type NoteProperty -name OSDiskName -value $vm.StorageProfile.OsDisk.Name
        $vmInfo | Add-Member -type NoteProperty -name OSDiskURI -value ($vm.StorageProfile.OsDisk.Vhd).uri
        $vmInfo | Add-Member -type NoteProperty -name DataDiskNames -value $ddNames
        $vmInfo | Add-Member -type NoteProperty -name PowerState -value $powerState
        $vmInfo | Add-Member -type NoteProperty -name LicenseType -value $vm.LicenseType
        $vmInfo | Add-Member -type NoteProperty -name SqlServerLicenseType -value $sqlLicenseType
        
        $vmInfoList += $vmInfo         
    }
    # Write to CSV file
    Write-Host "Writing VM Details to $outputFile for subscription '$($subscription.Name)'" -ForegroundColor Cyan
    $outputFile = $reportFolderPath+"\AzureVmReport_" + $subscription.SubscriptionId + "_" + (Get-Date -UFormat "%Y%m%d_%I%M%S_%p").tostring() + ".csv"
    $vmInfoList | Export-csv -NoType -Append $outputFile -Force
}

$sw.Stop()
Write-Host "Script execution completed. Time elapsed to run this script is '$($sw.Elapsed)'" -ForegroundColor Yellow 
