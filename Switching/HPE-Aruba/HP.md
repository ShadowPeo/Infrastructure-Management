HP

#Disable Weaker ciphers
no ip ssh cipher aes128-cbc
no ip ssh cipher 3des-cbc
no ip ssh cipher aes192-cbc
no ip ssh cipher rijndael-cbc@lysator.liu.se
no ip ssh cipher aes128-ctr
no ip ssh cipher aes192-ctr

#Disable Weaker MACs
no ip ssh mac hmac-md5
no ip ssh mac hmac-sha1-96
no ip ssh mac hmac-md5-96

#Set a management VLAN
management-vlan 20

#Explicity disable telnet
no telnet-server

#Inactivity Timeouts
console inactivity-timer 5
idle-timeout 5

#Secure File Transfers (Remove TFTP)
ip ssh filetransfer
no tftp server
no tftp client

#Lockout After X Number of failed login attempts, set the timer
aaa authentication num-attempts 3
aaa authentication num-attempts 2

#Disable Front USB Port
no usb-port

#Disable HTTP
web-management ssl
no web-management plaintext

#Set Web interface to timeout (Seconds)
web-management idle-timeout 300

#Dsiable Web Management (HTTP and HTTPS)
no web-management


#DHCP Snooping - Set DHCP Server(s)
dhcp-snooping authorized-server <<SERVER_IP>>
