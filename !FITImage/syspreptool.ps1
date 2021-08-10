<#Begin Header#>
#requires -version 2
<#
.SYNOPSIS
  <Overview of script>
.DESCRIPTION
  <Brief description of script>
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
.NOTES
  Version:        21.07.16.03
  Author:         Phil Ellis <pellis@fullerinfotech.com>
  Creation Date:  2021-07-16
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>
<#End Header#>

<#Script Specific Variables#>

<#Common Starter & Code Blocks#>
#Guid for random files
$guid =[System.GUID]::NewGuid().ToString().ToUpper()

#Debugging
#$DebugPreference = "Continue"
#Logging feature
#$ErrorActionPreference="SilentlyContinue"

#stop extra transcripts
try { Stop-Transcript | out-null } catch { }

#start a transcript file
try { Start-Transcript -path $scriptLog } catch { }

# TimeStamps
$Date = Get-Date -format "yyyy-MM-dd"
$Time = Get-Date -format "yyyy-MM-dd-hh-mm-ss"

#Compress Example
#Compress-Archive -Path C:\Reference\* -DestinationPath C:\Archives\Draft.zip

#Path variables https://docs.microsoft.com/en-us/dotnet/api/system.environment.getfolderpath?view=net-5.0
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$AllUsersDesktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")

#current script directory
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
#current script name
$path = Get-Location
$scriptName = $MyInvocation.MyCommand.Name
$scriptLog = "$scriptPath\log\$scriptName.log"

<#Functions#>
<#Menu#>
function Show-Menu {
    param (
        [string]$Title = 'FIT Imaging Tools'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Clean AppX Packages (Errors are acceptable)"
    Write-Host "2: Save StartMenu Layout"
    Write-Host "3: Sysprep with unattend"
	Write-Host "4: Reserved"
    Write-Host "Q: Press 'Q' to quit."
}

#checks if powershell is in Administrator mode, if not powershell will fix it  
<#Run-AsAdmin#>
Function Run-AsAdmin
{
	if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {     
		$arguments = "& '" + $myinvocation.mycommand.definition + "'"  
		Start-Process powershell -Verb runAs -ArgumentList $arguments  
		Break  
	}
}
#Example
#Run-AsAdmin

<#Pause#>
#Pause
Function Pause($M="Press any key to continue . . . "){If($psISE){$S=New-Object -ComObject "WScript.Shell";$B=$S.Popup("Click OK to continue.",0,"Script Paused",0);Return};Write-Host -NoNewline $M;$I=16,17,18,20,91,92,93,144,145,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183;While($K.VirtualKeyCode -Eq $Null -Or $I -Contains $K.VirtualKeyCode){$K=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")};Write-Host}
#Example
#Pause

<# Begin Program #>
Run-AsAdmin
Write-Host Things to do:
Write-Host * Run Disk Cleanup as Admin
Write-Host * Clear IE, Edge and Chrome web cache
Write-Host * Manually check for unnecessary files
Write-Host * Remove entries from QuickAccess in Explorer
Write-Host * Clear temp folders, but reboot after doing so
Write-Host This tool helps you clear the AppX packages, capture the start menu and then sysprep the image
Write-Host This file in the C:\!FITImage folder along with the customer unattend.xml, will ensure a good sysprep
Write-Host When you have completed the above:
Pause

$ROwn = Read-Host "Enter Registered Owner:"
$ROrg = Read-Host "Enter Registered Organization:"

$unattendxml = Get-Content -path "$scriptPath\default.xml" -Raw
$newContent1 = $unattendxml -replace 'DefaultOwner', $ROwn
$newContent2 = $newContent1 -replace 'DefaultOrganization', $ROrg
$newContent2 | Set-Content -Path "$scriptPath\unattend.xml"

do
 {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
        '1' {
            Get-AppxPackage -AllUsers | where-object {$_.name -notlike '*store*'} | Remove-AppxPackage
            Get-appxprovisionedpackage -online | where-object {$_.packagename -notlike '*store*'} | Remove-AppxProvisionedPackage -online
        } '2' {
            export-startlayout -path C:\!FITImage\StartMenu.xml
        } '3' {
            $arguments = "/oobe","/shutdown","/unattend:c:\!FITImage\unattend.xml"
            $cmd = "c:\Windows\system32\sysprep\sysprep.exe"
            &$cmd $arguments
            Clear-Host
        } '4' {
            Write-Host "Reserved"
        }
    }
pause
}
until ($selection -eq 'q')

<# End Program #>

<#Begin Footer#>

#Close Transcript log
try { Stop-Transcript | out-null } catch { }
<#End Footer#>

