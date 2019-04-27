
.\RB-ProcessLogs.ps1 -ReportName "Performance" -dynamicQuery "Perf |  where TimeGenerated > ago(1d)"

.\RB-ProcessLogs.ps1 -ReportName "Heartbeat" -dynamicQuery "Heartbeat| where TimeGenerated > ago(1d)"

.\RB-ProcessLogs.ps1 -ReportName "Events" -dynamicQuery "Event |  where TimeGenerated > ago(1d)"
		
.\RB-ProcessLogs.ps1 -ReportName "Update" -dynamicQuery "Update |  where TimeGenerated > ago(1d)"

.\RB-ProcessLogs.ps1 -ReportName "ProtectionStatus" -dynamicQuery "ProtectionStatus |  where TimeGenerated > ago(1d)"

.\RB-ProcessLogs.ps1 -ReportName "SecurityEvent" -dynamicQuery "SecurityEvent |  where TimeGenerated > ago(1d)"

.\RB-ProcessLogs.ps1 -ReportName "Usage" -dynamicQuery "Usage |  where TimeGenerated > ago(1d)"