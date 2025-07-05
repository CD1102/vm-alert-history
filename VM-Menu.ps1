# Checks to connect to Azure
try{
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

# Continue variable used to loop the menu
$continue = "y"

#Function to get RG and VM names
try{
function Get-RGAndVM {
    write-output " "
    # Lists RG's in subscription with a VM
    Write-output "--------- Resource Groups ---------"
    $vms = get-azvm
    $vmrg = $vms | Select-Object -ExpandProperty ResourceGroupName | Sort-Object -Unique
    $vmrg
    write-output " "
    $global:rgname = Read-Host "Enter the Resource Group name" 
    write-output " "
    # Lists all VM's in the RG
    Write-output "--------- Virtual Machines ---------"
    $vmlist = get-azvm -resourcegroupname $global:rgname
    $vmlist | select-object Name
    write-output " "
    $global:vmname = Read-Host "Enter the VM name" 
}
}
catch {
    Write-Output "Error retrieving Resource Groups or Virtual Machines: $_"
    exit
}
Get-RGAndVM

# Main loop for the menu
while ($continue.ToLower() -eq "y") {
    # Menu options
    Write-output " "
    Write-output "--------- VM Menu for: $global:vmname ---------"
    write-output " "
    write-output "1: Start the VM"
    write-output "2: Stop the VM"
    write-output "3: Restart the VM"
    write-output "4: Get VM Status"
    write-output "5: Change Resource Group or VM"
    write-output "6: Change Azure Subscription"
    write-output "7: Exit"
    write-output " "

    # User input
    $number = Read-Host "Select an option (1-7)"

    # VM Operations
        switch ($number) {
            1 {
                try {
                    Write-Output "Option 1 selected."
                    Write-Output "Starting the VM..."
                    Start-AzVM -Name $global:vmname -ResourceGroupName $global:rgname
                    Write-Output "VM started."
                }
                catch {
                    write-output(" ")
                    Write-Output "Error starting the VM: $($_.Exception.Message)"
                    start-sleep -seconds 2
                    continue
                }
            }
            2 {
                try {
                    Write-Output "Option 2 selected."
                    Write-Output "Stopping the VM..."
                    Stop-AzVM -Name $global:vmname -ResourceGroupName $global:rgname -Force
                    Write-Output "VM stopped."
                }
                catch {
                    write-output(" ")
                    Write-Output "Error stopping the VM: $($_.Exception.Message)"
                    start-sleep -seconds 2
                    continue
                }
            }
            3 {
                try {
                    Write-Output "Option 3 selected."
                    Write-Output "Restarting the VM..."
                    Restart-AzVM -Name $global:vmname -ResourceGroupName $global:rgname -ErrorAction Stop
                    Write-Output "VM restarted."
                }
                catch {
                    write-output(" ")
                    Write-Output "Error restarting the VM: $($_.Exception.Message)"
                    start-sleep -seconds 2
                    continue
                }
            }
            4 {
                try {
                    Write-Output "Option 4 selected."
                    Write-Output "Getting VM Status..."
                    $vm = Get-AzVM -Name $global:vmname -ResourceGroupName $global:rgname -Status
                    $vmStatus = $vm.Statuses[1].DisplayStatus
                    Write-Output "VM Status: $vmStatus"
                }
                catch {
                    write-output(" ")
                    Write-Output "Error getting VM status: $($_.Exception.Message)"
                    start-sleep -seconds 2
                    continue
                }
            }
            5 {
                try {
                    Write-Output "Option 5 selected."
                    start-sleep -seconds 2
                    Clear-Host
                    Get-RGAndVM
                }
                catch {
                    write-output(" ")
                    Write-Output "Error changing Resource Group or VM: $($_.Exception.Message)"
                    start-sleep -seconds 2
                    continue
                }
            }
            6 {
                try {
                    Write-Output "Option 6 selected."
                    Get-AzSubscription | Select-Object Name
                    $subscription = Read-Host "Select a subscription:"
                    Select-AzSubscription -SubscriptionName $subscription
                    Write-Output "Switched to subscription: $subscription"
                    start-sleep -seconds 3
                    Clear-Host
                    Get-RGAndVM
                }
                catch {
                    write-output(" ")
                    Write-Output "Error changing Azure subscription: $($_.Exception.Message)"
                    start-sleep -seconds 2
                    continue
                }
            }
            7 {
                try {
                    Write-Output "Option 7 selected."
                    Write-Output "Exiting the menu."
                    start-sleep -seconds 5
                    exit
                }
                catch {
                    write-output(" ")
                    Write-Output "Error exiting the script: $($_.Exception.Message)"
                    start-sleep -seconds 2
                    continue
                }
            }
            default {
                Write-Output "Invalid option. Please select a number between 1 and 7."
            }
        }

    # Ask if the user wants to continue
    write-output ""
    $continue = read-host "Do you wish to continue? (y/n)"
    if ($continue.tolower() -eq "y") {
        Clear-Host
        continue
    }
    else {
        write-output "Exiting script..."
        start-sleep -seconds 3
        break
    }
}