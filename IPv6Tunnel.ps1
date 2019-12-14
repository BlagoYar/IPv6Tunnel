# PowerShell script to build/rebuild a 6in4 (IPv6-in-IPv4) tunnel with 
# Hurricane Electric Free IPv6 Tunnel Broker (https://tunnelbroker.net/)
# based on https://github.com/snobu/v6ToGo/blob/master/v6ToGo.ps1 
# (Script using deprecated Tunnel Client Endpoint Update APIs
# check https://forums.he.net/index.php?topic=3153.0 for more Details) 
# based on https://tunnelbroker.net ->Tunnel Details
#  -> Example Configurations Tab -> Windows 10 selection

# Set strict mode to latest version (>=2.0)
# Ensure that programming best practices are followed (e.g. prohibit uninitialized variables)
Set-StrictMode -Version Latest

# Pre-run check: Checks the minimal version of Windows PowerShell
#Requires -Version 4.0
Write-Output "This Script requires PowerShell Version >= 4.0"
Write-Output "You are running PowerShell $($PSVersionTable.PSEdition) Version $($PSVersionTable.PSVersion)"

# Variables Initialization
[bool]$PowerShell = $false
[bool]$PowerShellCore = $false
[bool]$PowerShell_ISE = $false
[bool]$Administrator = $false

# Checks the runtime environment of the script
if ((($host.name -eq 'ConsoleHost') -XOR ($host.name -like 'Visual Studio*')) -AND ($PSVersionTable.PSEdition -ne "Core")){
    $PowerShell = $true
    Write-Verbose "Running PowerShell=$($PowerShell)"
}
elseif ((($host.name -eq 'ConsoleHost') -XOR ($host.name -like 'Visual Studio*')) -AND ($PSVersionTable.PSEdition -eq "Core")){
    $PowerShellCore = $true
    Write-Verbose "Running PowerShell Core=$($PowerShellCore)"
        if ($IsWindows) {
            Write-Output  "System is running on PowerShell $($PSVersionTable.PSEdition) on platform $($PSVersionTable.Platform)=Win32NT(Windows). Script started."
            }
        else{
            throw "System is not running PowerShell on $($PSVersionTable.PSEdition) on platform $($PSVersionTable.Platform)!=Win32NT(Windows). Script execution aborted."
        }
}
elseif ($host.name -eq 'Windows Powershell ISE Host') {
    $PowerShell_ISE = $true
    Write-Verbose "Running PowerShell ISE=$($PowerShell_ISE)"
}
else {  
        Write-Warning  "Unknown PowerShell runtime environment"
} 

# Check if we are currently running the runtime environment with elevated privileges as administrator.
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    $Administrator = $true
}
else {
    $Administrator = $false
} 

# Check if we are currently running Windows PowerShell with elevated privileges as administrator.
# If not it is self-elevating while preserving the working directory.
if (($PowerShell -eq $true) -AND ($Administrator -eq $false)){
    Write-Warning  "Running Windows PowerShell without admin rights! Restarting PowerShell with admin rights!!!"
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
    Exit
}
# Check if we are currently running PowerShell Core with elevated privileges as administrator.
# If not it is self-elevating while preserving the working directory.
if (($PowerShellCore -eq $true) -AND ($Administrator -eq $false)){
    Write-Warning  "Running PowerShell Core without admin rights! Restarting PowerShell Core with admin rights!!!"
    Start-Process pwsh -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
    Exit
}
# Write-Host "PS Core: If you see this, the Exit didn't work..."

# Check if we are currently running PowerShell ISE with elevated privileges as administrator.
# If not it is self-elevating and starting PowerShell_ISE with the current Script.
# Though you have to re-run the script manually.
if (($PowerShell_ISE -eq $true) -AND ($Administrator -eq $false)) {
    Write-Warning "Running script in PowerShell ISE without admin rights! Restarting PowerShell ISE with admin rights!!!"
    Write-Warning "Please re-run script manually."
    Start-Process PowerShell_ISE -Verb RunAs "-NoProfile -File $PSCommandPath" 
    Exit
}
#Write-Host "ISE: If you see this, the Exit didn't work..."

# Windows PowerShell ISE doesn't like netsh/netsh.exe, we'll fix that:
if ($PowerShell_ISE -eq $true) {
    $psUnsupportedConsoleApplications.Remove("netsh")
    $psUnsupportedConsoleApplications.Remove("netsh.exe")
} 

#++++++++++++++++++++++++++Adjust your configuration here+++++++++++++++++++++++
# Please configure $USERNAME, $UPDATEKEY_OR_PASSWORD, $TUNNEL_ID, 
# $ServerIPv4Address, $ServerIPv6Address & $ClientIPv6Address
# according to your tunnelbroker.net IPv6 Tunnel configuration.
# Please configure additionally your desired $TUNNELNAME
#
# Your tunnelbroker.net username
$USERNAME = ""
#
# Tunnel specific authentication key (Update Key. See Tunnel Details 
# -> Advanced tab on the tunnel information page) 
# if one is set, otherwise your tunnelbroker.net password.
$UPDATEKEY_OR_PASSWORD = ""
#
# Your Numeric Tunnel ID (unique identifier for your tunnel. See Tunnel Details 
# -> IPv6 Tunnel tab on the tunnel information page)
$TUNNEL_ID = ""
#
# Update URL
# Used to update the listed tunnel's client endpoint to the IP address making the update request.
$URL = "https://ipv4.tunnelbroker.net/nic/update?username=$USERNAME&password=$UPDATEKEY_OR_PASSWORD&hostname=$TUNNEL_ID"
#
# IPv6 Tunnel Endpoints: 
# See Tunnel Details 
# -> IPv6 Tunnel tab ->IPv6 Tunnel Endpoints section on the tunnel information page)
# Server IPv4 Address 
# This is the IPv4 endpoint of your Tunnel Server.
$ServerIPv4Address = "X.X.X.X"
# Server IPv6 Address
# This is the IPv6 endpoint of your Tunnel on our Tunnel Server.(/64 allocation)
$ServerIPv6Address = "2001:470:XXXX:YYYY::1"
# Client IPv6 Endpoint
# This is the IPv6 address that identifies your side of the tunnel. 
# It will be what is homed on your endpoint device.
# We utilize a /64 for this because of RFC 3627.
$ClientIPv6Address = "2001:470:XXXX:YYYY::2"
#
# Friendly name to use for interface in Windows 
$TUNNELNAME = "IPv6Tunnel"
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Write-Output 'Contacting tunnelbroker.net to check your Client IPv4 Endpoint'
$response = Invoke-WebRequest -UseBasicParsing $URL | Select-Object -Expand Content
if ($response -match "ERROR") {
    throw $response
}

# Get connected interface to v4 Internet
# This is the IPv4 address that tunnel is pointing to.
# It should be your publicly facing and accessible address. 
# If you are behind a firewall most likely this is the WAN or INTERNET address.
$ClientIPv4Address = $(Get-NetIPConfiguration |
    Where-Object { $_.NetProfile.IPv4Connectivity -eq 'Internet' }).IPV4Address[0].IPAddress

# Disable 6to4 
Write-Output "Disable 6to4 tunnel adapter: "
netsh interface 6to4 set state disabled
# Disable Teredo
Write-Output "Disable Teredo tunnel adapter: "
netsh interface teredo set state disabled
# Disable isatap
Write-Output "Disable isatap tunnel adapter: "
netsh interface isatap set state disabled

Write-Output ("Removing existing IPv6 tunnel IPv6 Address: " + $TUNNELNAME)
netsh interface ipv6 delete address interface=$TUNNELNAME address=$ClientIPv6Address 
Write-Output ("Removing existing IPv6 tunnel interface: " + $TUNNELNAME)
netsh interface ipv6 delete interface $TUNNELNAME

Write-Output ("Creating tunnel interface " + $TUNNELNAME)
Write-Output ("Your Client IPv4 Address: " + $ClientIPv4Address +
    "`n" + "Remote Server IPv4 Address: " + $ServerIPv4Address)
Write-Output ("Your Client IPv6 Address: " + $ClientIPv6Address +
    "`n" + "Remote Server IPv6 Address: " + $ServerIPv6Address)    
netsh interface ipv6 add v6v4tunnel interface=$TUNNELNAME localaddress=$ClientIPv4Address remoteaddress=$ServerIPv4Address
netsh interface ipv6 add address interface=$TUNNELNAME address=$ClientIPv6Address

Write-Output "Disable IPv6 forwarding"
netsh interface ipv6 set interface $TUNNELNAME forwarding=disabled
Write-Output "Enable IPv6 forwarding"
netsh interface ipv6 set interface $TUNNELNAME forwarding=enabled

Write-Output ("Removing existing default route (::/0) for $TUNNELNAME")
netsh interface ipv6 delete route prefix=::/0 interface=$TUNNELNAME nexthop=$ServerIPv6Address
Write-Output ("Creating default route (::/0) for $TUNNELNAME with a next-hop address of $ServerIPv6Address")
netsh interface ipv6 add route prefix=::/0 interface=$TUNNELNAME nexthop=$ServerIPv6Address

# Opened admin PowerShell waits for a key press and doesn't close automatically.
# used if the script is running in PowerShell
if (($PowerShell -eq $true) -OR ($PowerShellCore -eq $true)) {
    Write-Output "Press any key to close this shell..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
# used if the script is running in PowerShell ISE
if ($PowerShell_ISE -eq $true) {
    Read-Host "Press ENTER key to close this PowerShell ISE shell..."
    # Cleanup-add netsh and netsh.exe again to $psUnsupportedConsoleApplications
    $psUnsupportedConsoleApplications.Add("netsh")
    $psUnsupportedConsoleApplications.Add("netsh.exe")
} 
