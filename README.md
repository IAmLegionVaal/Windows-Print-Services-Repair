# Windows Print Services Repair

PowerShell diagnostics and repair for Windows printing.

> **Testing note:** This was tested by me to be working. User experience may vary.

## One-click use

1. Download and extract the repository.
2. Double-click `Run-OneClick.bat`.
3. Approve the Windows administrator prompt.
4. The launcher restarts and verifies the Print Spooler directly—there is no menu.
5. Review the exit code and logs in `C:\ProgramData\WindowsPrintRepair\Logs`.

The one-click launcher does **not** clear pending print jobs. Queue cleanup remains an explicit PowerShell option so jobs are not deleted without a deliberate choice.

## Included

`Repair-WindowsPrintServices.ps1`

## PowerShell usage

```powershell
.\Repair-WindowsPrintServices.ps1
.\Repair-WindowsPrintServices.ps1 -Repair
.\Repair-WindowsPrintServices.ps1 -Repair -ClearQueue
.\Repair-WindowsPrintServices.ps1 -Repair -WhatIf
```

The default run reports printers, ports, drivers, jobs, Spooler status and TCP printer connectivity. Repair actions require an elevated PowerShell window. Queue cleanup uses a protected stop/delete/start sequence and attempts to restore the Spooler even if cleanup fails.

Exit code `0` means success, `1` means a fatal error and `2` means warnings were recorded.

## Disclaimer

Use this project at your own risk. Review pending jobs before using the queue-cleanup option. Printer definitions and drivers are not changed.

## License

MIT
