#requires -version 5 
 
<#
.SYNOPSIS
  Import-PhoneNumbers is a Powershell script that leverages remote PS sessions on O365 to allow for importing VZ mobile numbers into Azure Active Directory
.DESCRIPTION
  Using A CSV and remote PS sessions on O365 We can import a list of phone numbers to Azure AD
.PARAMETER PhoneNumbers
    PhoneNumber: A file path param it is a string.
    NameField: Tells the script what COL the names are in
    NumberField: Tells the script what COL the phone numbers are in
.INPUTS
  PhoneNumbers.csv
.OUTPUTS
  Log file stored in C:\Windows\Temp\import-PhoneNumbers.log>
.NOTES
  Version:        1.0
  Author:         Jacob Ernst
  Creation Date:  06/12/2019
  Purpose/Change: Initial script development
  Template: https://gist.github.com/9to5IT/9620683
  
.EXAMPLE
  import-PhoneNumbers -PhoneNumbers "C:\windows\Temp\PhoneNumbers.csv"
#> 
 
#---------------------------------------------------------[Initialisations]-------------------------------------------------------- 
 
#Set Error Action to Silently Continue 
$ErrorActionPreference = "SilentlyContinue" 
 
#Dot Source required Function Libraries 
#N/A 
 
#----------------------------------------------------------[Declarations]---------------------------------------------------------- 
 
#Script Version 
$sScriptVersion = "1.0" 
 
#Log File Info 
$sLogPath = "C:\users\%username%\Documents" #TODO Fix %paths%
$sLogName = "import-PhoneNumbers.log" 
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName 
 
#-----------------------------------------------------------[Functions]------------------------------------------------------------ 
 
##### 
#https://stackoverflow.com/questions/7834656/create-log-file-in-powershell 
##### 
Function Write-Log { 
	[CmdletBinding()] 
	Param( 
		[Parameter(Mandatory=$False)] 
		[ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")] 
		[String] 
		$Level = "INFO", 
		 
		[Parameter(Mandatory=$True)] 
		[string] 
		$Message, 
		 
		[Parameter(Mandatory=$False)] 
		[string] 
		$logfile, 
		 
		[Parameter(Mandatory=$False)] 
		[string] 
		$Guid 
	) 
	 
	$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss") 
	$Line = "$Stamp $Level $Guid $Message" 
	If($slogfile) { 
		Add-Content $logfile -Value $Line 
	} 
	Else { 
		Write-host $Line 
	} 
} 
 
### 
#end 
### 
 
 
Function import-RawPhoneNumbers{ 
	 
	Param( 
		[Parameter(Mandatory = $true)][string]$CSV, 
		[Parameter(Mandatory = $true)][string]$nameField, 
		[Parameter(Mandatory = $true)][string]$numberField 
		 
		 
	) 
	 
	Begin{ 
		$funcGuid = New-Guid 
		 
		Write-Log -Level INFO -Guid $funcGuid -Message "Importing CSV To Powershell Object only containing Reletive Data" -logfile $sLogFile 
	} 
	 
	Process{ 
		Try{ 
			$rawData = Import-Csv -Path $CSV 
			$selectedData = $rawData | select -Property "User Name","Wireless Number" 
		} 
		 
		Catch{ 
			Write-Log -Level FATAL -Guid $funcGuid -Message $_.Exception -logfile $sLogFile 
			Break 
		} 
	} 
	 
	End{ 
		If($?){ 
			Write-Log -Level INFO -Guid $funcGuid -Message "Completed Successfully." -logfile $sLogFile 
			return $selectedData 
		} 
	} 
} 
 
 
Function export-PhoneNumbers{ 
	 
	Param( 
		[Parameter(Mandatory = $true)]$PhoneNumbers, 
		[Parameter(Mandatory = $false)]$exclutions 
		 
	) 
	 
	Begin{ 
		$funcGuid = New-Guid 
		 
		Write-Log -Level INFO -Guid $funcGuid -Message "Connection To O365..." -logfile $sLogFile 
	} 
	 
	Process{ 
		Try{ 
			Write-Log -Level INFO -Guid $funcGuid -Message "Prompting For user Creds" -logfile $sLogFile 
			$UserCredential = Get-Credential 
			 
			Write-Log -Level INFO -Guid $funcGuid -Message "Connecting..." -logfile $sLogFile 
			$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection 
			Write-Log -Level INFO -Guid $funcGuid -Message "Importing The Session" -logfile $sLogFile 
			Import-PSSession $Session -DisableNameChecking 
			Write-Log -Level INFO -Guid $funcGuid -Message "Running Import" -logfile $sLogFile 
			 
			############################################ 
			#TODO 
			############################################ 
			 
			 
			$PhoneNumbers = Compare-Object -ReferenceObject $PhoneNumbers -DifferenceObject $exclutions -PassThru -Property "User Name" | select -Property "User Name","Wireless Number" 
			 
			 
		} 
		 
		Catch{ 
			Write-Log -Level FATAL -Guid $funcGuid -Message $_.Exception -logfile $sLogFile 
			Break 
		} 
	} 
	 
	End{ 
		If($?){ 
			Write-Log -Level INFO -Guid $funcGuid -Message "Completed Successfully." -logfile $sLogFile 
			return $selectedData 
		} 
	} 
} 
 
 
 
#-----------------------------------------------------------[Execution]------------------------------------------------------------ 
 
$progGuid = New-Guid 
Write-Log -Level INFO -Guid $progGuid -Message "Starting Script" -logfile $sLogFile 
 
$selectedData = import-RawPhoneNumbers 
 
 
Write-Log -Level INFO -Guid $progGuid -Message "Script Successfully Finished" -logfile $sLogFile 
