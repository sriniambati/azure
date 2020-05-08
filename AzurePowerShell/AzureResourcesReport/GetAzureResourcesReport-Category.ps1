##*****************  PLEASE READ CAREFULLY *****************
# a) Get latest version of Azure PowerShell from https://aka.ms/installaz
# b) Legal Disclaimer:
#    This document is for informational purposes only. MICROSOFT MAKES NO WARRANTIES, EXPRESS, IMPLIED, OR STATUTORY, AS TO THE INFORMATION IN THIS DOCUMENT.
#    This document is provided “as-is.” Information and views expressed in this document, including URL and other Internet website references, may change without notice. You bear the risk of using it. 
#    Microsoft and Azure are either registered trademarks or trademarks of Microsoft Corporation in the United States and/or other countries.
#    Copyright © 2019 Microsoft Corporation. All rights reserved.
#
# This script does the following: 
# 1) Retrieves details of all Azure Services from https://azure.microsoft.com/en-us/services/
# 2) Saves the details as CSV
#
################################################### 
# Change values of following variables
###################################################
$reportFolderPath = "c:\temp"
$azServicesUrl = "https://azure.microsoft.com/en-us/services/"

################################################### 
# Script execution starts here
###################################################
$outputFile = $reportFolderPath+"\AzureServicesReport_" + (Get-Date -UFormat "%Y%m%d_%I%M%S_%p").tostring() + ".csv"
$content = Invoke-WebRequest -Uri $azServicesUrl
$xml = [xml]$content.ParsedHTML.GetElementByID('products-list').outerHtml

$services = @()
$categoryName = ""
$serviceName = ""

$nodes = $xml.SelectNodes("//*[@class ='product-category'] | //*[@data-event-property]")

foreach ($node in $nodes) {

    if (($node.attributes["class"]) -and ($node.attributes["class"].value="product-category") -and ($node.InnerText -ne 'Learn More')) { 
        $categoryName = $node.InnerText
    }

    
    if (($node.attributes['data-event-property'])-and ($node.attributes['data-event-property'].value -ne $categoryName)) { 
        $serviceName = $node.attributes['data-event-property'].value
    }

    if($categoryName -and $serviceName){
        $service = new-object psobject -prop @{Category=$categoryName;ServiceName=$serviceName}
        $services += $service
    }
    $serviceName = ""

}
$services

# Write to CSV file
Write-Host "Writing Azure Service Details to $outputFile" -ForegroundColor Cyan
$services | Export-csv -NoType -Append $outputFile -Force