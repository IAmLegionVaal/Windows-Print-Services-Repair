<#
.SYNOPSIS
Diagnoses and repairs common Windows printing problems.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Repair,
    [switch]$ClearQueue,
    [string]$LogRoot="$env:ProgramData\WindowsPrintRepair\Logs"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$runPath=Join-Path $LogRoot (Get-Date -Format 'yyyyMMdd_HHmmss')
$warnings=New-Object System.Collections.Generic.List[string]
$transcript=$false

function Test-Admin{
    $id=[Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

try{
    if($env:OS -ne 'Windows_NT'){throw 'Windows is required.'}
    if(($Repair -or $ClearQueue) -and -not(Test-Admin)){throw 'Run PowerShell as Administrator for repair actions.'}
    New-Item $runPath -ItemType Directory -Force|Out-Null
    Start-Transcript -Path (Join-Path $runPath 'Transcript.txt') -Force|Out-Null
    $transcript=$true

    $spooler=Get-Service Spooler
    $spooler|Select-Object Name,Status,StartType|Export-Csv (Join-Path $runPath 'Spooler.csv') -NoTypeInformation

    if(Get-Command Get-Printer -ErrorAction SilentlyContinue){
        Get-Printer|Select-Object Name,DriverName,PortName,PrinterStatus,WorkOffline,Shared|
            Export-Csv (Join-Path $runPath 'Printers.csv') -NoTypeInformation
        Get-PrinterPort|Select-Object Name,Description,PrinterHostAddress,PortNumber,SNMPEnabled|
            Export-Csv (Join-Path $runPath 'Ports.csv') -NoTypeInformation
        Get-PrinterDriver|Select-Object Name,Manufacturer,MajorVersion,DriverPath|
            Export-Csv (Join-Path $runPath 'Drivers.csv') -NoTypeInformation

        $connectivity=foreach($port in Get-PrinterPort|Where-Object{$_.PrinterHostAddress}){
            try{
                $test=Test-NetConnection -ComputerName $port.PrinterHostAddress -Port 9100 -WarningAction SilentlyContinue
                [pscustomobject]@{Port=$port.Name;Address=$port.PrinterHostAddress;Tcp9100=$test.TcpTestSucceeded}
            }catch{
                $warnings.Add("Port $($port.Name): $($_.Exception.Message)")
            }
        }
        $connectivity|Export-Csv (Join-Path $runPath 'PrinterConnectivity.csv') -NoTypeInformation
    }else{
        $warnings.Add('PrintManagement cmdlets are unavailable.')
    }

    if($Repair -and $PSCmdlet.ShouldProcess('Print Spooler','Restart service')){
        Restart-Service Spooler -Force -ErrorAction Stop
    }

    if($Repair -and $ClearQueue -and $PSCmdlet.ShouldProcess('Pending print jobs','Clear spool files')){
        Stop-Service Spooler -Force
        $spoolPath=Join-Path $env:SystemRoot 'System32\spool\PRINTERS'
        Get-ChildItem $spoolPath -File -ErrorAction SilentlyContinue|
            Remove-Item -Force -ErrorAction Stop
        Start-Service Spooler
    }

    Get-Service Spooler|Select-Object Name,Status,StartType|
        Export-Csv (Join-Path $runPath 'Spooler-After.csv') -NoTypeInformation
    $warnings|Out-File (Join-Path $runPath 'Warnings.txt') -Encoding UTF8

    if($transcript){Stop-Transcript|Out-Null;$transcript=$false}
    if($warnings.Count -gt 0){Write-Host "[WARN] Completed with warnings. Logs: $runPath" -ForegroundColor Yellow;exit 2}
    Write-Host "[OK] Completed. Logs: $runPath" -ForegroundColor Green;exit 0
}catch{
    if($transcript){try{Stop-Transcript|Out-Null}catch{}}
    Write-Error $_.Exception.Message;exit 1
}
