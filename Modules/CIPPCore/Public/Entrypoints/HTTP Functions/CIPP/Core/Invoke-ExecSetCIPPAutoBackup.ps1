using namespace System.Net

Function Invoke-ExecSetCIPPAutoBackup {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        CIPP.Backup.Read
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    $Headers = $Request.Headers
    Write-LogMessage -headers $Headers -API $APIName -message 'Accessed this API' -Sev 'Debug'

    $unixtime = [int64](([datetime]::UtcNow) - (Get-Date '1/1/1970')).TotalSeconds
    if ($Request.Body.Enabled -eq $true) {
        $Table = Get-CIPPTable -TableName 'ScheduledTasks'
        $AutomatedCIPPBackupTask = Get-AzDataTableEntity @table -Filter "Name eq 'Automated CIPP Backup'"
        $task = @{
            RowKey       = $AutomatedCIPPBackupTask.RowKey
            PartitionKey = 'ScheduledTask'
        }
        Remove-AzDataTableEntity -Force @Table -Entity $task | Out-Null

        $TaskBody = [pscustomobject]@{
            TenantFilter  = 'PartnerTenant'
            Name          = 'Automated CIPP Backup'
            Command       = @{
                value = 'New-CIPPBackup'
                label = 'New-CIPPBackup'
            }
            Parameters    = [pscustomobject]@{ backupType = 'CIPP' }
            ScheduledTime = $unixtime
            Recurrence    = '1d'
        }
        Add-CIPPScheduledTask -Task $TaskBody -hidden $false
        $Result = @{ 'Results' = 'Scheduled Task Successfully created' }
    }
    Write-LogMessage -headers $Request.Headers -API $Request.Params.CIPPEndpoint -message 'Scheduled automatic CIPP backups' -Sev 'Info'
    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $Result
        })

}
