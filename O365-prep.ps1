<#
Office 365 migration prep script
This script will collect various information from an Exchange server and export
to a folder for import into Office 365 or another Exchange environment. Run from 
an elevated Exchange Management Shell.
#>

clear-host

#Set variables
$dir = "c:\temp\migrationprep"

write-host "Office 365 migration prep script" -ForegroundColor White
write-host `r`n

#Create output folder
write-host "Creating output folder at: C:\temp\migrationprep if it doesn't exist" -ForegroundColor Cyan
write-host `r`n

if(!(Test-Path -Path $dir )){
    New-Item -ItemType directory -Path $dir
                New-Item -ItemType directory -Path "c:\temp\migrationprep\distribution_lists\"
    Write-Host "Migration prep folder created." -ForegroundColor Cyan
    Write-Host `r`n
}
else
{
  Write-Host "Folder already exists" -ForegroundColor Red
  Write-Host `r`n
}

#Collect general environment information
write-host "Collecting some information about the Exchange environment, and saving to environment_info.txt." -ForegroundColor Cyan
Write-Host `r`n
echo "Accepted domains:" >> C:\temp\migrationprep\environment_info.txt
Get-AcceptedDomain >> c:\temp\migrationprep\environment_info.txt
#Store the accepted domains
$exchdomains = get-accepteddomain

#Collect mailbox sizes
write-host "Collecting a list of all used mailboxes, exporting to user-mailbox-sizes.csv." -ForegroundColor Cyan
Write-Host `r`n
Get-MailboxDatabase | Get-MailboxStatistics | Select DisplayName, ItemCount, TotalItemSize | Sort-Object TotalItemSize -Descending | export-csv c:\temp\migrationprep\user-mailbox-sizes.csv -NoTypeInformation

#Collect Userlist formatted for O365 Import
write-host "Collecting Mailboxes and exporting appropriate fields to o365userlist.csv for import into O365" -ForegroundColor Cyan
Write-Host `r`n
$mailboxes = Get-Mailbox -resultSize unlimited
$mailboxes | foreach { Get-User $_ | select WindowsEmailAddress, FirstName, LastName, DisplayName, JobTitle, Department, OfficeNumber, OfficePhone, MobilePhone, Fax, AlternateEmailAddress, Address, City, StateOrProvince, ZipOrPostalCode, CountryOrRegion} | export-csv -NoTypeInformation c:\temp\migrationprep\o365userlist.csv -Encoding unicode
#Remove Quotes from created file
(gc C:\temp\migrationprep\o365userlist.csv) | % {$_ -replace '"', ""} | out-file c:\temp\migrationprep\o365userlist.csv -Fo -En ascii


#Collect alises
write-host "Collecting a list of aliases, exporting to alias-list.csv." -ForegroundColor Cyan
Write-Host `r`n
get-mailbox | sort-object alias | select -expand emailaddresses alias | where-object {$_.isprimaryaddress -Eq $false} | export-csv c:\temp\migrationprep\alias-list.csv -notypeinformation

#Collect list of Distribution Groups
write-host "Collecting distribution lists, exporting to distribution_lists\distribution_lists.csv." -ForegroundColor Cyan
Write-Host `r`n
Get-DistributionGroup | select name,displayname, grouptype, primarysmtpaddress | export-csv c:\temp\migrationprep\distribution_lists\distribution_lists.csv -notypeinformation

#Collect members in each distribution list
write-host "Collecting distribution list members, exporting to .csv by name." -ForegroundColor Cyan
Write-Host `r`n
foreach($i in Get-distributiongroup | select){

    $Distro_list_name = Get-distributiongroup | select Name
    write-host $export_name -ForegroundColor Cyan
    Get-DistributionGroupMember -Identity $i | Select displayName, alias, PrimarySMTPAddress | export-csv -Path c:\temp\migrationprep\distribution_lists\${i}.csv -notypeinformation
}

#Collect contacts
write-host "Collecting contacts, exporting to contacts.csv." -ForegroundColor Cyan
Write-Host `r`n
get-contact | select displayname, Firstname, Lastname, windowsemailaddress, name | export-csv c:\temp\migrationprep\contacts.csv -notypeinformation 

#collect forwards
write-host "Collecting mailbox forwards, exporting to forwards.csv." -ForegroundColor Cyan
Write-Host `r`n
Get-mailbox | select DisplayName,ForwardingAddress | where {$_.ForwardingAddress -ne $Null} | export-csv c:\temp\migrationprep\forwards.csv -notypeinformation

#Check for Exchange transport rules
write-host "Checking server for transport rules and appending to environment_info.txt." -ForegroundColor Cyan
Write-Host `r`n
echo "Transport rules:" >> C:\temp\migrationprep\environment_info.txt
Get-TransportRule >> c:\temp\migrationprep\environment_info.txt

#Check for SPF record
write-host "Checking DNS for SPF records and appending to environment_info.txt." -ForegroundColor Cyan
Write-Host `r`n
echo "SPF records:" >> C:\temp\migrationprep\environment_info.txt
$exchdomains = get-accepteddomain
foreach ($domain in $exchdomains.name) {
  $spfrecord = nslookup -type=TXT $domain 8.8.8.8 2>null| select-string -pattern "spf"
  echo $spfrecord >> C:\temp\migrationprep\environment_info.txt
}

#Check for users with permissions to other mailboxes
write-host "Checking for users with permissions to other mailboxes, exporting to mailbox-permissions.csv" -ForegroundColor Cyan
Write-Host `r`n
Get-Mailbox | Get-MailboxPermission | where {$_.user.tostring() -ne "NT AUTHORITY\SELF" -and $_.IsInherited -eq $false} | Select Identity,User,@{Name='Access Rights';Expression={[string]::join(', ', $_.AccessRights)}} | Export-Csv -NoTypeInformation mailbox-permissions.csv

#Finished
write-host "Script complete." -ForegroundColor White
Write-Host `r`n
