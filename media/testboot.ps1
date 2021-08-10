#Self Elevation
     # Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

$url = "https://www.mobatek.net/exes/MobaLiveCD_v2.1.exe"
$output = "$PSScriptRoot\MobaLiveCD_v2.1.exe"

(New-Object System.Net.WebClient).DownloadFile($url, $output)
Start-Process ("$output")