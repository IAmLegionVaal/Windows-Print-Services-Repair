# Windows Print Services Repair

PowerShell diagnostics and repair for Windows printing.

> **Testing note:** This was tested by me to be working. User experience may vary.

## Included

`Repair-WindowsPrintServices.ps1`

## Usage

```powershell
.\Repair-WindowsPrintServices.ps1
.\Repair-WindowsPrintServices.ps1 -Repair
.\Repair-WindowsPrintServices.ps1 -Repair -ClearQueue
```

The default run reports printers, ports, drivers, spooler status and TCP printer connectivity. Repair actions require an elevated PowerShell window and support `-WhatIf`.

Logs are stored in `C:\ProgramData\WindowsPrintRepair\Logs`.

Exit code `0` means success, `1` means a fatal error and `2` means warnings were recorded.

## Disclaimer

Use this project at your own risk. Review pending jobs before using the queue-cleanup option. Printer definitions and drivers are not changed.

## License

MIT
