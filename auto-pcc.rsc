# Ask user for required inputs
:local totalLines ""
:local baseInterface ""
:local readinput do={:return}

/put "\n?? Enter number of lines:"
:set totalLines [$readinput]

/put "\n?? Enter base interface (e.g., ether2):"
/set baseInterface [$readinput]

# Create WAN interface list if not exist
:if ([:len [/interface list find name="WAN"]] = 0) do={
    /interface list add name="WAN" comment="WAN Interfaces for PCC"
}

# Add routing tables
:for i from=1 to=$totalLines do={
    :local rtname ("to-wan" . $i)
    :if ([:len [/routing table find name=$rtname]] = 0) do={
        /routing table add name=$rtname fib
    }
}

# Main loop for MAC VLANs, PPPoE clients, and PCC rules
:for i from=1 to=$totalLines do={

    :local vlanName ("macvlan" . $i)
    :local pppoeName ("pppoe-out" . $i)
    :local username ("pppoeuser" . $i)
    :local password ("password" . $i)
    :local rtmark ("to-wan" . $i)
    :local connmark ("wan" . $i . "-conn")
    :local index ($i - 1)

   /interface macvlan add name=$vlanName interface=$baseInterface mode=private

    /interface pppoe-client add name=$pppoeName interface=$vlanName user=$username password=$password use-peer-dns=no add-default-route=no disabled=no

    /interface list member add list=WAN interface=$pppoeName

    /ip firewall mangle add chain=prerouting src-address-list=pppoe-clients connection-mark=no-mark \
        action=mark-connection new-connection-mark=$connmark \
        per-connection-classifier=("both-addresses-and-ports:" . $totalLines . "/" . $index) passthrough=yes

    /ip firewall mangle add chain=prerouting connection-mark=$connmark src-address-list=pppoe-clients \
        action=mark-routing new-routing-mark=$rtmark passthrough=no

    /ip route add dst-address=0.0.0.0/0 gateway=$pppoeName routing-table=$rtmark check-gateway=ping
}

# Accept WAN traffic early
/ip firewall mangle add chain=prerouting in-interface-list=WAN action=accept place-before=0 comment="Accept WAN"
/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment="Masquerade all WANs"

# Add client IP range to address list (adjust as needed)
/ip firewall address-list add list=pppoe-clients address=192.168.77.0/24 comment="PPPoE Clients"

file/ remove auto-pcc.rsc
