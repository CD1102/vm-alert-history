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
            try{
            Write-Output "Option 1 selected."
            Write-Output "Starting the VM..."
            Start-AzVM -Name $global:vmname -ResourceGroupName $global:rgname
            Write-Output "VM started."
            }
            catch {
                Write-Output "Error starting the VM: $_"
                exit
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
                Write-Output "Error stopping the VM: $_"
                exit
            }
        }
        3 {
            try{
            Write-Output "Option 3 selected."
            Write-Output "Restarting the VM..."
            Restart-AzVM -Name $global:vmname -ResourceGroupName $global:rgname
            Write-Output "VM restarted."
            }
            catch {
                Write-Output "Error restarting the VM: $_"
                exit
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
                Write-Output "Error getting VM status: $_"
                exit
            }
        }
        5 {
            try{
            Write-output "Option 5 selected."
            start-sleep -seconds 2
            Clear-Host
            Get-RGAndVM
            }
            catch {
                Write-Output "Error changing Resource Group or VM: $_"
                exit
            }
        }
        6 {
            try {
            write-output "Option 6 selected."
            Get-AzSubscription| Select-Object Name
            $subscription = read-host "Select a subscription:"
            Select-AzSubscription -SubscriptionName $subscription
            Write-Output "Switched to subscription: $subscription"
            start-sleep -seconds 3
            Clear-Host
            Get-RGAndVM
            }
            catch {
                Write-Output "Error changing Azure subscription: $_"
                exit
            }
        }
        7 {
            try{
            Write-Output "Option 7 selected."
            Write-Output "Exiting the menu."
            start-sleep -seconds 5
            exit
            }
            catch {
                Write-Output "Error exiting the script: $_"
                exit
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