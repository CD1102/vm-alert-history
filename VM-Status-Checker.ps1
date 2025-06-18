# reminder to connect to Azure Connect-AzAccount
$vm = Get-AzVM -name "test-vm" -ResourceGroupName "rg-1" -Status
$vmStatus = $vm.Statuses[1].DisplayStatus
Write-Output "VM Status: $vmStatus"