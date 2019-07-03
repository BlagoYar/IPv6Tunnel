#Requires -version 4.0
#Requires -RunAsAdministrator

# PowerShell script to build/rebuild a 6in4 (IPv6-in-IPv4) tunnel with 
# Hurricane Electric Free IPv6 Tunnel Broker (https://tunnelbroker.net/)
# based on https://github.com/snobu/v6ToGo/blob/master/v6ToGo.ps1 
# (Script using deprecated Tunnel Client Endpoint Update APIs
# check https://forums.he.net/index.php?topic=3153.0 for more Details) 
# based on https://tunnelbroker.net ->Tunnel Details
#  -> Example Configurations Tab -> Windows 10 selection

# ISE doesn't like netsh.exe, we'll fix that:
if ($psUnsupportedConsoleApplications) { 
		$psUnsupportedConsoleApplications.Clear() 
}
#++++++++++++++++++++++++++Adjust your configuration here+++++++++++++++++++++++
#
# Your tunnelbroker.net username
$USERNAME = "<>"
#
# Tunnel specific authentication key (Update Key under Tunnel Details 
# -> Advanced tab on the tunnel information page) 
# if one is set, otherwise your tunnelbroker.net password.
$PASSWORD = "<>"
#
# Your Numeric Tunnel ID
$HOSTNAME = "<>"
#
# Update URL
# Used to update the listed tunnel's client endpoint to the IP address making the update request.
$URL = "https://ipv4.tunnelbroker.net/nic/update?username=$USERNAME&password=$PASSWORD&hostname=$HOSTNAME"
# Server IPv4 Address 
# This is the IPv4 endpoint of your Tunnel Server.
$ServerIPv4Address = "<X.X.X.X>"
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
$response = Invoke-WebRequest -UseBasicParsing $URL | select -Expand Content
if ($response -match "ERROR") {
    throw $response
}

# Get connected interface to v4 Internet
# This is the IPv4 address that tunnel is pointing to.
# It should be your publicly facing and accessible address. 
# If you are behind a firewall most likely this is the WAN or INTERNET address.
$ClientIPv4Address = $(Get-NetIPConfiguration |
    ? {$_.NetProfile.IPv4Connectivity -eq 'Internet'}).IPV4Address[0].IPAddress

#Disable 6to4 
netsh interface 6to4 set state disabled
#Disable Teredo
netsh interface teredo set state disabled
#Disable ISATAP
netsh interface isatap set state disabled

Write-Output ("Removing existing IPv6 tunnel interface" + $TUNNELNAME)
netsh interface ipv6 delete interface $TUNNELNAME

Write-Output ("Creating tunnel interface " + $TUNNELNAME)
Write-Host -Foreground Cyan ("Your Client IPv4 Address: "+ $ClientIPv4Address +
			"`n" + "Remote Server IPv4 Address: " + $ServerIPv4Address)
netsh interface ipv6 add v6v4tunnel interface=$TUNNELNAME localaddress=$ClientIPv4Address remoteaddress=$ServerIPv4Address
netsh interface ipv6 add address interface=$TUNNELNAME address=$ClientIPv6Address

Write-Output "Enable IPv6 forwarding"
    netsh interface ipv6 set interface $TUNNELNAME forwarding=enabled

# Only enable if you want to become a router
# Get network adapter name from ncpa.cpl or Get-NetAdapter
#
# netsh interface ipv6 set interface "Ethernet 2" forwarding=enabled
# Write-Host -ForegroundColor Magenta "You are now an IPv6 router."

Write-Output ("Injecting ::/0 via " + $TUNNELNAME)
    netsh interface ipv6 add route prefix=::/0 interface=$TUNNELNAME nexthop=$ServerIPv6Address
