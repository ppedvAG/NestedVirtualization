<#
.Synopsis
   Konfigurieren einer VM für die verschachtelte Virtualisierung
.DESCRIPTION
   Dieses Skript prüft die Voraussetzungen für die Verschachtelte Virtualisierung und konfiguriert diese bei Bedarf.
.Example
    NestedVM.ps1 -VMName <Name der VM>   
    Prüfen ob die VM die Vorraussetzungen erfüllt.
#>

    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Name der zu überprüfenden Virtuellen Maschine
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        [ValidateScript({(Get-VM -VMName $_ ) -gt $null})]
        $VMName,

        # Nur überprüfen
        [switch]
        $check
    )
    
    #prüfen ob wir Administrator sind und wenn nicht als admin neustarten
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath -VMName $VMName`""  -Verb RunAs; exit }

    [bool]$VMS = $false #VM Running Status
    [bool]$PVE = $false #Prozessorstatus Ready?
    [bool]$MAS = $false #Mac Adressen Spoofing aktiviert?
    [bool]$DME = $false #Dynamischer Arbeitsspeicher deaktiviert?    

    #läuft die VM?
    if((Get-VM -Name $VMName).State -eq "Running")
    {
        $VMS = $true
    }

    #VM Prozessor prüfen
    if((Get-VMProcessor -VMName WDS).ExposeVirtualizationExtensions)
    {
        $PVE = $true
    } 
    #MAC Adressen Spoofing prüfen
    foreach($Adapter in (Get-VMNetworkAdapter -VMName $VMName) )
    {
        if($Adapter.MacAdressenSpoofing -eq "off")
        {
            $MAS = $false
        }
    }
    #Prüfen auf dynamischen Arbeitsspeicher
    if((Get-VMMemory -VMName $VMName).DynamicMemoryEnabled)
    {
        $DME = $true

    }
    Write-Host -NoNewline "Status der VM:"
    if($VMS)
    {
        Write-Host  -ForegroundColor Red "Ein"
    }
    else
    {
        Write-Host -ForegroundColor Green "Aus"
    }
    Write-Host -NoNewline "Prozessor Virtualisierungserweiterungen:"
    if($PVE)
    {
        Write-Host -ForegroundColor Green "Aktiviert"
    }
    else
    {
        Write-Host -ForegroundColor Red "Deaktiviert"
    }
    Write-Host -NoNewline "MAC Adressen Spoofing aktiviert:"
    if($MAS)
    {
        Write-Host -ForegroundColor Green "Ja"
    }
    else
    {
        Write-Host -ForegroundColor Yellow "Nein (Nicht zwingend notwendig)"
    }
    Write-Host -NoNewline "Dynamischer Arbeitsspeicher:"
    if($DME)
    {
        Write-Host -ForegroundColor Red "aktiviert"
    }
    else
    {
        Write-Host -ForegroundColor Green "deaktiviert"
    }

 