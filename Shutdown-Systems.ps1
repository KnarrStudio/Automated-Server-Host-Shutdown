#requires -Version 3.0

function Start-VmServerShutdown
{
  <#
      .Synopsis
      Completely automate the Power off procedures in the event that we need to shut down for a power outage.

      .DESCRIPTION
      Automate the Power off procedures in the event that we need to shut down for a power outage.
   
      .EXAMPLE
      Example of how to use this cmdlet
      .EXAMPLE
      Another example of how to use this cmdlet

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Start-PowerOutage

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>

  [OutputType([int])]
  Param
  (
    # 
    [Parameter(Mandatory,HelpMessage = 'Type of shutdown required: Planned, Unplanned, Emergency', ValueFromPipeline,Position = 0)]
    [ValidateSet('Planned', 'Unplanned', 'Emergency', 'DryRun')]
    [String]$Type,

    # Snapshots WithMemory or Without memory.  Snapshots with memory take longer, but if think there might be problems after the restart you will want to use this.  
    # Snapshots Key. Where only some systems with have the memory snapped.  This would be good in an Unplanned or emergency situation
        
    [Parameter(Mandatory,HelpMessage = 'Create Snapshot first')]
    [String]$Snapshots,
    [Switch]$SnapshotsKey
  )

  Begin
  {
  } #END - Begin
  Process
  {
    function script:Move-CriticalVmToPrimaryHost
    {
      param
      (
        [Parameter(Mandatory,HelpMessage = 'Add help message for user')][Object]$HostOne,

        [Parameter(Mandatory,HelpMessage = 'Add help message for user')][Object]$HostTwo
      )

      function Get-VmsFromHost
      {
        param
        (
          [Parameter(Mandatory, ValueFromPipeline, HelpMessage = 'Data to filter')]
          [Object]$InputObject
        )
        process
        {
          if ($InputObject.vmhost.name -eq $HostOne)
          {
            $InputObject
          }
        }
      }

      do
      {
        $servers = get-vm | Get-VmsFromHost
        foreach($server in $servers)
        {
          #Moving $server from $HostOne to $HostTwo
          move-vm $server -Destination $HostTwo
        }
      }while((get-vm | Get-VmsFromHost).count -ne 0)

      Write-Verbose -Message 'Moves Completed!'
    }
  } #END - Process
  End
  { 
  } #END - End
}
function Shutdown-VmServers
{
  <#
      .SYNOPSIS
      Short description of what Shutdown-VmServers does
      .DESCRIPTION
      Detailed description of what Shutdown-VmServers does
      .EXAMPLE
      Shutdown-VmServers -Name 'Server1', 'Server2' -Order 'Tag' -Type 'Planned', 'Unplanned', 'Emergency', 'DryRun'

      Shutdown-VmServers
      .EXAMPLE
      Second example
      Shutdown-VmServers
  #>

  param
  (
    # Parameter description
    [Parameter(Position = 0,HelpMessage = 'Add help message for user', Mandatory,ValueFromPipeline)]
    [string[]]$VmName,

    # Parameter description
    [Parameter(Mandatory = $true,HelpMessage = 'Add help message for user',Position = 1)]
    [string]
    $Order,

    # Parameter description
    [Parameter(Mandatory,HelpMessage = 'Add help message for user')]
    [ValidateSet('Planned', 'Unplanned', 'Emergency','DryRun')]
    [string]
    $Type
  )

  # TODO: place your function code here
  # this code gets executed when the function is called
  # and all parameters have been processed
}
function script:MoveVMsRebootHost
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,HelpMessage = 'Add help message for user')][Object]$HostOne,

    [Parameter(Mandatory = $true,HelpMessage = 'Add help message for user')][Object]$HostTwo
  )
  do
  {
    $servers = get-vm | Where-Object -FilterScript {
$_.vmhost.name -eq $HostOne
}
    foreach($server in $servers)
    {
      #Write-Host "Moving $server from $HostOne to $HostTwo"
      move-vm $server -Destination $HostTwo
    }
  }while((get-vm | Where-Object -FilterScript {
$_.vmhost.name -eq $HostOne
}).count -ne 0)

  if((get-vm | Where-Object -FilterScript {
$_.vmhost.name -eq $HostOne
}).count -eq 0)
  {
    $null = Set-VMHost $HostOne -State Maintenance
    $null = Restart-vmhost $HostOne -confirm:$false 
  }
  do 
  {
    Start-Sleep -Seconds 15
    $ServerState = (get-vmhost $HostOne).ConnectionState
    Write-Host ('Shutting Down {0}' -f $HostOne) -ForegroundColor Magenta
  }
  while ($ServerState -ne 'NotResponding')
  Write-Host ('{0} is Down' -f $HostOne) -ForegroundColor Magenta

  do 
  {
    Start-Sleep -Seconds 60
    $ServerState = (get-vmhost $HostOne).ConnectionState
    Write-Host 'Waiting for Reboot ...'
  }
  while($ServerState -ne 'Maintenance')
  Write-Host ('{0} back online' -f $HostOne)
  $null = Set-VMHost $HostOne -State Connected 
}
