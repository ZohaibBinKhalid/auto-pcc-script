:put "MikroTik PCC + MAC VLAN + Optional PPPoE Server Setup"

# === Read user input from comment ===
:local comment [/user get admin comment]
:local totalLines [:tonum [:pick $comment 0 3]]
:local baseInterface [:pick $comment 4 11]
:local enablePPPoEServer [:tonum [:pick $comment 12 13]]

:put "Lines: $totalLines | 🔌 Base Interface: $baseInterface | 🖥 PPPoE Server: $enablePPPoEServer"

# === Create WAN interface list ===
/interface list
:if ([:len [/interface list find name="WAN"]] = 0) do={
    add name=WAN comment="WAN Interfaces for PCC"
}
/interface list member remove [find list=WAN]

# === Loop: Create MAC VLANs + PPPoE Clients + add to WAN list ===
:for i from=1 to=$totalLines do={

    :local vlanName ("macvlan" . $i)
    :local pppoeName ("pppoe-out" . $i)
    :local vlanID $i

    /interface vlan add name=$vlanName interface=$baseInterface vlan-id=$vlanID
    /interface pppoe-client add name=$pppoeName interface=$vlanName user=("pppoeuser" . $i) password=("password" . $i) use-peer-dns=no add-default-route=no disabled=no
    /interface list member add list=WAN interface=$pppoeName
}

# === Accept WAN traffic in Mangle (top position) ===
/ip firewall mangle
add chain=prerouting in-interface-list=WAN action=accept place-before=0 comment="Accept WAN Traffic"

# === Loop: PCC Mangle Rules ===
:for i from=1 to=$totalLines do={
    :local connMark ("wan" . $i . "-conn")
    :local routeMark ("to-wan" . $i)
    /ip firewall mangle add chain=prerouting in-interface=$baseInterface connection-mark=no-mark action=mark-connection new-connection-mark=$connMark per-connection-classifier=both-addresses-and-ports:$totalLines,($i - 1) passthrough=yes
    /ip firewall mangle add chain=prerouting in-interface=$baseInterface connection-mark=$connMark action=mark-routing new-routing-mark=$routeMark passthrough=yes
}

# === Loop: Routing Rules ===
:for i from=1 to=$totalLines do={
    :local pppoeName ("pppoe-out" . $i)
    :local routeMark ("to-wan" . $i)
    /ip route add gateway=$pppoeName routing-mark=$routeMark check-gateway=ping
}

# === NAT Masquerade Rule ===
/ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment="Masquerade WAN"

# === Optional PPPoE Server Setup ===
:if ($enablePPPoEServer = 1) do={

    /ip pool add name=pppoe-pool ranges=192.168.77.2-192.168.77.254
    /ip address add address=192.168.77.1/24 interface=$baseInterface

    /ppp profile
    add name=5Mbps local-address=192.168.77.1 remote-address=pppoe-pool rate-limit=5M/5M
    add name=10Mbps local-address=192.168.77.1 remote-address=pppoe-pool rate-limit=10M/10M

    /ppp secret
    add name=user1 password=123 service=pppoe profile=5Mbps
    add name=user2 password=123 service=pppoe profile=10Mbps

    /interface pppoe-server server
    add interface=$baseInterface service-name=pppoe disabled=no

    /ip firewall address-list
    add list=pppoe-clients address=192.168.77.0/24 comment="PPPoE Pool"
    :put "PPPoE Server Setup Complete"
}

:put "ALL DONE: PCC + MAC VLANs + Optional PPPoE Server"
