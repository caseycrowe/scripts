# Create a working directory if it doesn't already exist
New-Item -ItemType Directory -Force -Path C:\temp\python-patch\ | out-null

# Collect some data about this server
$ServerName = $env:computername
$FQDN = ([System.Net.Dns]::GetHostByName(($env:computerName))).Hostname

# First check if this is a domain controller (returns 4 or 5 if so)
$DomainRole = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty DomainRole

if( $DomainRole -match '4|5' ){

	Import-Module BitsTransfer

	$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
	$osVersion = $osInfo.version

	if ($osVersion -like "6.2*"){
		# Server 2012 Non-R2
		write-host "Server 2012 Non-R2" 
		write-host "Downloading KB4571702.msu" 
		$url = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2020/08/windows8-rt-kb4571702-x64_31d0c26c78ed003e20c197b9f35869069f5f4b56.msu'
		$output = 'C:\temp\python-patch\KB4571702.msu'
		Start-BitsTransfer -Source $url -Destination $output 
		C:\temp\python-patch\KB4571702.msu /quiet /norestart
		Start-Sleep -s 120
		get-hotfix KB4571702 >> 'c:\temp\python-patch\patchlog.txt'
		}
	elseif ($osVersion -like "6.3*"){
		# Server 2012 R2
		write-host "Server 2012 R2" 
		write-host "Downloading KB4566425.msu" 
		$url = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2020/07/windows8.1-kb4566425-x64_243a8843ec4f888de71d0a94ec3deaf4e345f7a5.msu'
		$output = 'c:\temp\python-patch\KB4566425.msu'
		Start-BitsTransfer -Source $url -Destination $output 
		C:\temp\python-patch\KB4566425.msu /quiet /norestart
		Start-Sleep -s 120
		get-hotfix KB4566425 >> 'c:\temp\python-patch\patchlog.txt'
		}
	elseif ($osVersion -like "*14393"){
		# Server 2016
		write-host "Server 2016"
		write-host "Downloading KB4571694.msu"
		$url = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2020/08/windows10.0-kb4571694-x64_220af1e3a18ef36cb4abe3d34a3ce15ce656753b.msu'
		$output = 'c:\temp\python-patch\KB4571694.msu'
		Start-BitsTransfer -Source $url -Destination $output
		C:\temp\python-patch\KB4571694.msu /quiet /norestart
		Start-Sleep -s 120
		get-hotfix KB4571694 >> 'c:\temp\python-patch\patchlog.txt'
		}
	elseif ($osVersion -like "*17763"){
		# Server 2019
		write-host "Server 2019"
		write-host "Downloading KB4566424.msu"
		$url = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2020/08/windows10.0-kb4566424-x64_3d5bfb3e572029861cfb02c69de6b909153f5856.msu'
		$output = 'c:\temp\python-patch\KB4566424.msu'
		Start-BitsTransfer -Source $url -Destination $output
		C:\temp\python-patch\KB4566424.msu /quiet /norestart
		Start-Sleep -s 120
		get-hotfix KB4566424 >> 'c:\temp\python-patch\patchlog.txt'
		}
	else{
		# No match
		write-host "No matching server version." 
		}
	
}else{
	write-host $ServerName + " is not a domain controller."
}

$EmailFrom = $ServerName + "@yourdomain.com"
$EmailTo = "recipient@yourdomain.com"
$Subject = "DC Patch update from " + $FQDN
$Body = Get-Content -Path "C:\temp\python-patch\patchlog.txt" -Encoding UTF8 -Raw
$SMTPServer = "some.mail.server.com"
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
$SMTPClient.EnableSsl = $false
$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)
