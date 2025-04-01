#!/bin/bash
#Add Startup Delay to allow services to settle and become available
sleep 5m

#VM Machine Name as per Synology VMM
vmName="<<VM_NAME>>"

#Start the Virtual Machine
response=$(synowebapi --exec api=SYNO.Virtualization.API.Guest.Action version=1 method=poweron runner=sysadmin guest_name="\"$vmName\"")

# Extract success value from JSON response more reliably
success=$(echo "$response" | grep -o '"success"[[:space:]]*:[[:space:]]*[^,}]*' | sed 's/.*:[[:space:]]*\([^[:space:]]*\).*/\1/')
echo "Success value: $success"

if [[ "$success" == "true" ]]; then
    echo "VM '$vmName' successfully powered on"

    # Run ovs-vsctl show and capture the output
    output=$(ovs-vsctl show)

    # Find the line with Bridge "PN..." and extract the PN... part
    pnCode=$(echo "$output" | grep 'Bridge "PN' | sed -E 's/.*Bridge "([^"]+)".*/\1/')

    # Check if we found a match
    if [[ -n "$pnCode" && "$pnCode" =~ ^PN ]]; then
        echo "Found bridge with PN code: $pnCode"

        # Add port to the bridge
        ovs-vsctl add-port "$pnCode" host-int -- set Interface host-int type=internal

        # Configure the interface with IP and bring it up
        ip addr add 172.20.0.2/24 dev host-int
        ip link set host-int up

        echo "Successfully configured host-int interface on bridge $pnCode"
    else
        echo "No bridge with PN code found"
    fi
else
    echo "Error: Failed to power on VM '$vmName'"
    echo "API response: $response"
    exit 1
fi