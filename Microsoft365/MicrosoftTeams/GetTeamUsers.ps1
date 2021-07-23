##*****************  PLEASE READ CAREFULLY *****************
# a) Check Pre-requisites at https://docs.microsoft.com/en-us/microsoftteams/teams-powershell-install
#    You may need to do the following:
#    - Run "PowerShell ISE" with elevated permissions (i.e. as Administrator)
#    - Get latest version of Azure PowerShell from https://aka.ms/installaz
#    - Run commands below to complete the pre-requisites
#       $PSVersionTable.PSVersion
#       Install-Module -Name MicrosoftTeams -Force -AllowClobber # Requires elevated permissions
# b) Legal Disclaimer:
#    This document is for informational purposes only. MICROSOFT MAKES NO WARRANTIES, EXPRESS, IMPLIED, OR STATUTORY, AS TO THE INFORMATION IN THIS DOCUMENT.
#    This document is provided “as-is.” Information and views expressed in this document, including URL and other Internet website references, may change without notice. You bear the risk of using it. 
#    Microsoft and Azure are either registered trademarks or trademarks of Microsoft Corporation in the United States and/or other countries.
#    Copyright © 2021 Microsoft Corporation. All rights reserved.
# c) This script requires you to login to connect to Microsoft Teams
#
# This script does the following: 
# 1) Retrieves details of all users for a given Microsoft Teams team display name
# 2) Saves the user details as CSV
#
################################################### 
# Change values of following variables
###################################################

$teamDisplayName = "ENTER YOUR TEAM DISPLAY NAME HERE"
$reportFolderPath = "c:\temp"

################################################### 
# Script execution starts here
###################################################
Write-Host "Login to Teams..." -ForegroundColor Yellow
Connect-MicrosoftTeams
$sw = [Diagnostics.Stopwatch]::StartNew()
Write-Host "Getting the team information..." -ForegroundColor Cyan
$team = Get-Team -DisplayName $teamDisplayName
$users = Get-TeamUser -GroupId $team.GroupId
$userInfoList = @()

foreach($user in $users) 
{
    $userInfo = New-Object System.Object
    $userInfo | Add-Member -type NoteProperty -name UserName -value $user.Name
    $userInfo | Add-Member -type NoteProperty -name Email -value $user.User
    $userInfo | Add-Member -type NoteProperty -name Role -value $user.Role
    $userInfoList += $userInfo
}

# Write output to CSV file
$outputFile = $reportFolderPath+"\TeamsUserReport_" + $teamDisplayName + "_" + (Get-Date -UFormat "%Y%m%d_%I%M%S_%p").tostring() + ".csv"
Write-Host "Writing user details to '$outputFile' for team '$teamDisplayName'" -ForegroundColor Cyan
$userInfoList | Export-csv -NoType -Append $outputFile -Force

$sw.Stop()
Write-Host "Script execution completed. Time elapsed to run this script is '$($sw.Elapsed)'" -ForegroundColor Yellow 