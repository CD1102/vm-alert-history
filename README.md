# VM-Alert-History

PowerShell script to retrieve and analyze Azure VM alerts history across subscriptions.

## Features

- Connects to Azure (prompts login if needed)
- Retrieves alerts via Azure Alerts Management REST API
- Filters alerts by time window (last 30 mins, 24 hours, 7 days, 30 days)
- Groups and counts frequently alerted VMs based on user-defined thresholds
- Allows viewing:
  - Frequently alerted VMs
  - All alerts
  - Both
- Option to export results to Excel with multiple worksheets (Summary, Frequent Alerts, All Alerts)
- Provides error handling and warning messages for failed subscriptions

## Next Steps

- Add **parameter support** for automated runs (e.g., `-TimeRange 7d -Export Excel`)
- Add a more variable time frame (deeper or user defined)
- Add **filtering by resource groups** or **specific VMs**
- Send reports via email or Teams (automation)
- Convert to an **Azure Automation Runbook** for scheduled
