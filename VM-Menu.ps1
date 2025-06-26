# Checks to connect to Azure
$connected = Read-Host "Are you connected to Azure? (yes/no)"
if ($connected.ToLower() -ne "yes") {
    Write-Output "You must be connected to Azure to run this script. A login option will show up shortly...."
    Connect-AzAccount
}

# Continue variable used to loop the menu
$continue = "y"

# VM details and location
write-output " "
# Lists RG's in subscription with a VM
Write-output "--------- Resource Groups ---------"
$vms = get-azvm
$vmrg = $vms | Select-Object -ExpandProperty ResourceGroupName | Sort-Object -Unique
$vmrg
write-output " "
$rgname = Read-Host "Enter the Resource Group name" 
write-output " "
# Lists all VM's in the RG
Write-output "--------- Virtual Machines ---------"
$vmlist = get-azvm -resourcegroupname $rgname
$vmlist | select-object Name
write-output " "
$vmname = Read-Host "Enter the VM name" 

# Main loop for the menu
while ($continue.ToLower() -eq "y") {
    # Menu options
    Write-output " "
    Write-output "--------- VM Menu for: $vmname ---------"
    write-output " "
    write-output "1: Start the VM"
    write-output "2: Stop the VM"
    write-output "3: Restart the VM"
    write-output "4: Get VM Status"
    write-output "5: Exit"
    write-output " "

    # User input
    $number = Read-Host "Select an option (1-5)"

    # VM Operations
    switch ($number) {
        1 {
            Write-Output "Option 1 selected."
            Write-Output "Starting the VM..."
            Start-AzVM -Name $vmname -ResourceGroupName $rgname
            Write-Output "VM started."
        }
        2 {
            Write-Output "Option 2 selected."
            Write-Output "Stopping the VM..."
            Stop-AzVM -Name $vmname -ResourceGroupName $rgname -Force
            Write-Output "VM stopped."
        }
        3 {
            Write-Output "Option 3 selected."
            Write-Output "Restarting the VM..."
            Restart-AzVM -Name $vmname -ResourceGroupName $rgname
            Write-Output "VM restarted."
        }
        4 {
            Write-Output "Option 4 selected."
            Write-Output "Getting VM Status..."
            $vm = Get-AzVM -Name $vmname -ResourceGroupName $rgname -Status
            $vmStatus = $vm.Statuses[1].DisplayStatus
            Write-Output "VM Status: $vmStatus"
        }
        5 {
            Write-Output "Option 5 selected."
            Write-Output "Exiting the menu."
            start-sleep -seconds 5
            exit
        }
        default {
            Write-Output "Invalid option. Please select a number between 1 and 5."
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