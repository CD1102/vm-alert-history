# Connect to Azure
try {
    $connected = Read-Host "Are you connected to Azure? (yes/no)"
    if ($connected.ToLower() -ne "yes") {
        Write-Output "You must be connected to Azure to run this script. A login option will show up shortly...."
        Connect-AzAccount
    }
}
catch {
    Write-Output "Error connecting to Azure: $_"
    exit
}

# Function to get alert history
function Get-Alert-History {
    $token = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token
    $plainTextToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
    )

    $tokenText = $plainTextToken
    $headers = @{
        Authorization = "Bearer $tokenText"
    }

    $subscriptionId = (get-azcontext).Subscription.Id

    # list alerts filtered by VM resource type
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.AlertsManagement/alerts?api-version=2019-05-05-preview"

    # Call API and perform loop to
    $response = @()

    do {
        $apiresponse = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        $response += $apiresponse.value
        $uri = $apiresponse.nextLink
    } while ($uri)

    return $response
}

$subscriptions = Get-AzSubscription

# Creates columns via hash tables derived from API objects
$startTime = @{Name = "StartTime"; Expression = { [datetime]$_.properties.essentials.startDateTime } }
$resourceType = @{Name = "ResourceType"; Expression = { $_.properties.essentials.targetResourceType } }
$resourceName = @{Name = "ResourceName"; Expression = { $_.properties.essentials.targetResourceName } }
$subscriptionName = @{Name = "Subscription"; Expression = { $_.SubscriptionName } }

# Formats the table properties based on user's preferences
$useresponse = read-host "Do you want alerts from last 30 mins (30M), 24 hours (24), 7 days (7) or 30 days (30D)?"
write-output "`nAlert History Is Being Retrieved, Please Wait..."

# Determine cutoff time based on user input
switch ($useresponse.ToLower()) {
    "30m" { $cutoffTime = (Get-Date).AddMinutes(-30) }
    "24"  { $cutoffTime = (Get-Date).AddHours(-24) }
    "7"   { $cutoffTime = (Get-Date).AddDays(-7) }
    "30d" { $cutoffTime = (Get-Date).AddDays(-30) }
    default { $cutoffTime = $null }
}

$allAlerts = @()


foreach ($sub in $subscriptions) {
    try {
        Set-AzContext -SubscriptionId $sub.Id | Out-Null
        $response = Get-Alert-History

        $vmAlerts = $response | Where-Object {
            $_.properties.essentials.targetResourceType -eq "virtualmachines"
        }

        if ($cutoffTime) {
            $vmAlerts = $vmAlerts | Where-Object {
                [datetime]$_.properties.essentials.startDateTime -gt $cutoffTime
            }
        }

        # Add subscription name to each alert
        $vmAlerts | ForEach-Object {
            $_ | Add-Member -NotePropertyName "SubscriptionName" -NotePropertyValue $sub.Name -Force
            $allAlerts += $_
        }
    }
    catch {
        Write-Warning "Failed to process subscription $($sub.Name): $_"
    }
}


$response2 = Read-Host "`nWould you like to see Frequently Alerted VMs (1), All Alerts (2), or Both (3)? "
if ($response2 -eq "1" -or $response2 -eq "3") {
    $threshold = Read-Host "`nEnter the minimum number of alerts to consider a VM as frequently alerted (e.g., 30)"
}
if ($response2 -eq "1") {
    # Group alerts by VM name and count
    $vmAlertCounts = $allAlerts | Group-Object {
        "$($_.properties.essentials.targetResourceName)|$($_.name)"
    } | Where-Object { $_.Count -ge $threshold } | Sort-Object Count -Descending

    $frequentVMs = $vmAlertCounts | ForEach-Object {
        $parts = $_.Name -split '\|'
        [PSCustomObject]@{
            VMName     = $parts[0]
            AlertName  = $parts[1]
            AlertCount = $_.Count
        }
    }

    # Display VMs with the met threshold of alerts
    Write-Output "`nVMs with more than $threshold instances of the same alert in the selected time window:"
    $vmAlertCounts | ForEach-Object {
        Write-Output "`VM: $($_.Name) - Alert Count: $($_.Count)"
        start-sleep -seconds 3
    }
}
elseif ($response2 -eq "2") {
    # Create table and count alerts
    $allAlerts | Format-Table name, $resourceName, $resourceType, $subscriptionName, $startTime
    $allAlerts.count
}
elseif ($response2 -eq "3") {
    # Group alerts by VM name and alert rule
    $vmAlertCounts = $allAlerts | Group-Object {
        "$($_.properties.essentials.targetResourceName)|$($_.name)"
    } | Where-Object { $_.Count -ge $threshold } | Sort-Object Count -Descending

    # Format frequent alerts
    $frequentVMs = $vmAlertCounts | ForEach-Object {
        $parts = $_.Name -split '\|'
        [PSCustomObject]@{
            VMName     = $parts[0]
            AlertName  = $parts[1]
            AlertCount = $_.Count
        }
    }

    # Display frequent alerts
    Write-Output "`VMs with more than $threshold instances of the same alert:"
    $frequentVMs | Format-Table -AutoSize

    # Display all alerts
    Write-Output "`All alerts in the selected time window:"
    $allAlerts | Format-Table name, $resourceName, $resourceType, $subscriptionName, $startTime
    Write-Output "`Total alerts: $($allAlerts.Count)"
}

$export = Read-Host "`nWould you like to export the results to Excel? (yes/no)"

if ($export.ToLower() -eq "yes") {
    $filePath1 = "VM_Frequent_Alerts_Report.xlsx"
    $filePath2 = "VM_Alert_History_Report.xlsx"
    $filePath = "VM_Alerts_Report.xlsx"

    try {
        Write-Output "`nChecking to see whether Excel Module is installed..."
        Import-Module ImportExcel -ErrorAction Stop
    }
    catch {
        Write-Host "`nImportExcel module not found. Attempting to install..."
        try {
            Install-Module ImportExcel -Scope CurrentUser -Force -ErrorAction Stop
            Import-Module ImportExcel -ErrorAction Stop
            Write-Host "ImportExcel module installed successfully."
        }
        catch {
            Write-Error "Failed to install ImportExcel module. Exiting script."
            exit
        }
    }

    # Determine readable time range
    switch ($useresponse.ToLower()) {
        "30m" { $timeRangeText = "Last 30 minutes" }
        "24" { $timeRangeText = "Last 24 hours" }
        "7" { $timeRangeText = "Last 7 days" }
        "30d" { $timeRangeText = "Last 30 days" }
        default { $timeRangeText = "Unknown" }
    }

    # Create summary object
    $summary = [PSCustomObject]@{
        "Time Range Selected"           = $timeRangeText
        "Threshold for Frequent Alerts" = $threshold
        "Total Alerts Retrieved"        = $allAlerts.Count
        "Report Generated On"           = (Get-Date)
    }


    if ($response2 -eq "1") {
        write-output "`nExcel File Currently Being Created, Please Wait..."
        # Export frequent alerts only
        $summary | Export-Excel -Path $filePath1 -WorksheetName "Summary" -AutoSize
        $frequentVMs | Export-Excel -Path $filePath1 -WorksheetName "Frequent Alerts" -AutoSize
        Write-Output "Exported frequent alerts to: $filePath1"
    }
    elseif ($response2 -eq "2") {
        write-output "`nExcel File Currently Being Created, Please Wait..."
        # Export all alerts only
        $summary | Export-Excel -Path $filePath2 -WorksheetName "Summary" -AutoSize
        $allAlerts | Select-Object name, $resourceName, $resourceType, $subscriptionName, $startTime |
        Export-Excel -Path $filePath2 -WorksheetName "All Alerts" -AutoSize
        Write-Output "Exported all alerts to: $filePath2"
    }
    elseif ($response2 -eq "3") {
        write-output "`nExcel File Currently Being Created, Please Wait..."
        # Export summary and both
        $summary | Export-Excel -Path $filePath -WorksheetName "Summary" -AutoSize
        $frequentVMs | Export-Excel -Path $filePath -WorksheetName "Frequent Alerts" -AutoSize
        $allAlerts | Select-Object name, $resourceName, $resourceType, $subscriptionName, $startTime |
        Export-Excel -Path $filePath -WorksheetName "All Alerts" -AutoSize
        write-output "Exported frequent alerts and all alerts to: $filePath"
    }
}

# ensure no abrupt closure
Read-Host "`nenter any key to exit the script"
