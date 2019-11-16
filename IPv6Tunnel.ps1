# PowerShell script to build/rebuild a 6in4 (IPv6-in-IPv4) tunnel with 
# Hurricane Electric Free IPv6 Tunnel Broker (https://tunnelbroker.net/)
# based on https://github.com/snobu/v6ToGo/blob/master/v6ToGo.ps1 
# (Script using deprecated Tunnel Client Endpoint Update APIs
# check https://forums.he.net/index.php?topic=3153.0 for more Details) 
# based on https://tunnelbroker.net ->Tunnel Details
#  -> Example Configurations Tab -> Windows 10 selection

#Requires -Version 4.0
Write-Output "This Script requires PowerShell Version >= 4.0"
Write-Output "You are running PowerShell Version $($PSVersionTable.PSVersion)."

# Check if we are currently running admin PowerShell with elevated privileges as administrator.
# If not it is self-elevating while preserving the working directory
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";
    exit;
}

# Windows PowerShell ISE doesn't like netsh/netsh.exe, we'll fix that:
if ($psUnsupportedConsoleApplications) { 
		$psUnsupportedConsoleApplications.Clear() 
}

#++++++++++++++++++++++++++Adjust your configuration here+++++++++++++++++++++++
# Please configure $USERNAME, $PASSWORD, $HOSTNAME, $ServerIPv4Address & $ServerIPv6Address
# according to your tunnnelbroker.net IPv6 Tunnel configuration 
# Please configure additionally your desired $TUNNELNAME
#
# Your tunnelbroker.net username
$USERNAME = ""
#
# Tunnel specific authentication key (Update Key under Tunnel Details 
# -> Advanced tab on the tunnel information page) 
# if one is set, otherwise your tunnelbroker.net password.
$PASSWORD = ""
#
# Your Numeric Tunnel ID
$HOSTNAME = ""
#
# Update URL
# Used to update the listed tunnel's client endpoint to the IP address making the update request.
$URL = "https://ipv4.tunnelbroker.net/nic/update?username=$USERNAME&password=$PASSWORD&hostname=$HOSTNAME"
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

#Disable 6to4 
Write-Output "Disable 6to4 tunnel adapter: "
netsh interface 6to4 set state disabled
#Disable Teredo
Write-Output "Disable Teredo tunnel adapter: "
netsh interface teredo set state disabled
#Disable isatap
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
netsh interface ipv6 add address interface=$TUNNELNAME address=$ClientIPv6Address/64

Write-Output "Disable IPv6 forwarding"
netsh interface ipv6 set interface $TUNNELNAME forwarding=disabled
Write-Output "Enable IPv6 forwarding"
netsh interface ipv6 set interface $TUNNELNAME forwarding=enabled

# Only enable if you want to become a router
# Get network adapter name from ncpa.cpl or Get-NetAdapter
#
# netsh interface ipv6 set interface "Ethernet 2" forwarding=disabled
# netsh interface ipv6 set interface "Ethernet 2" forwarding=enabled
# Write-Host -ForegroundColor Magenta "You are now an IPv6 router."

Write-Output ("Removing existing default route (::/0) for $TUNNELNAME")
netsh interface ipv6 delete route prefix=::/0 interface=$TUNNELNAME nexthop=$ServerIPv6Address
Write-Output ("Creating default route (::/0) for $TUNNELNAME with a next-hop address of $ServerIPv6Address")
netsh interface ipv6 add route prefix=::/0 interface=$TUNNELNAME nexthop=$ServerIPv6Address

# Opened admin PowerShell waits for a key press and doesn't close automatically.
Write-Output "Press any key to close this admin shell..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
