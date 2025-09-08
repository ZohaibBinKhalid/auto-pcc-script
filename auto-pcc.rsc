# User Input
:local totalLines ""
:local baseInterface ""
:local readinput do={:return}

/put "\n?? Enter number of lines:"
:set totalLines [$readinput]

/put "\n?? Enter base interface (e.g., ether2):"
/set baseInterface [$readinput]

# Create WAN interface list if not exist
:if ([:len [/interface list find name="WAN"]] = 0) do={
    /interface list add name="WAN"
}

# Create Routing Tables First
:for i from=1 to=$totalLines do={
    :local rtname ("to-wan" . $i)
    :if ([:len [/routing table find name=$rtname]] = 0) do={
        /routing table add name=$rtname fib
    }
}

# Step 1: Create all MAC VLANs, PPPoE clients, add to WAN list
:for i from=1 to=$totalLines do={

    :local vlanName ("macvlan" . $i)
    :local pppoeName ("pppoe-out" . $i)
    :local username ("pppoeuser" . $i)
    :local password ("password" . $i)

    /interface macvlan add name=$vlanName interface=$baseInterface mode=private
    /interface pppoe-client add name=$pppoeName interface=$vlanName user=$username password=$password profile=default-encryption use-peer-dns=no add-default-route=no disabled=no
    /interface list member add list=WAN interface=$pppoeName
}

# Step 2: Create all connection-marks
:for i from=1 to=$totalLines do={

    :local connmark ("wan" . $i . "-conn")
    :local index ($i - 1)

    /ip firewall mangle add chain=prerouting src-address-list=clients connection-mark=no-mark \
        action=mark-connection new-connection-mark=$connmark \
        per-connection-classifier=("both-addresses-and-ports:" . $totalLines . "/" . $index) passthrough=yes
}

# Step 3: Create all routing-marks and routes
:for i from=1 to=$totalLines do={

    :local pppoeName ("pppoe-out" . $i)
    :local rtmark ("to-wan" . $i)
    :local connmark ("wan" . $i . "-conn")

    /ip firewall mangle add chain=prerouting connection-mark=$connmark src-address-list=clients \
        action=mark-routing new-routing-mark=$rtmark passthrough=yes

    /ip route add dst-address=0.0.0.0/0 gateway=$pppoeName routing-table=$rtmark
    
}
:for i from=1 to=$totalLines do={
:local pppoeName ("pppoe-out" . $i)
/ip route add dst-address=0.0.0.0/0 gateway=$pppoeName routing-table=main distance=$i
}
# WAN Accept Rule (for load balancing return traffic)
/ip firewall mangle add chain=prerouting in-interface-list=WAN action=accept comment="Accept WAN"

# NAT Masquerade
/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment="Masquerade all WANs"

# Add clients to address list (update range if needed)
/ip firewall address-list add list=clients address=192.168.77.0/24

# Step 4: Show Success Message
:delay 1
:put "************************************************"
:put "*                                              *"
:put "*    Successfully Installed Auto PCC Script!   *"
:put "*                                              *"
:put "*    Thank you for using my script           *"
:put "*    Script by: Zohaib Bin Khalid            *"
:put "*                                              *"
:put "************************************************"


# Step 5: Delete script file after execution
:delay 2
:local scriptFileName "auto-pcc.rsc"
/file remove [find name=$scriptFileName]
:delay 3
:local scriptFileName2 "auto-pcc-installer.rsc"
/file remove [find name=$scriptFileName2]
