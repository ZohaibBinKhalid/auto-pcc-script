# 🔄 Default fallbacks
:if ([:typeof $pppoeInterface] = "nothing") do={ :set pppoeInterface "ether2" }
:if ([:typeof $macVlanInterface] = "nothing") do={ :set macVlanInterface "ether2" }
:if ([:typeof $totalLines] = "nothing") do={ :set totalLines 10 }
:if ([:typeof $profileCount] = "nothing") do={ :set profileCount 5 }

# 🛠 Create MAC VLAN interfaces
:for i from=1 to=$totalLines do={
    /interface vlan add name=("macvlan" . $i) interface=$macVlanInterface vlan-id=$i
}

# 🌐 Create PPPoE Clients
:for i from=1 to=$totalLines do={
    /interface pppoe-client add name=("pppoe-out" . $i) interface=("macvlan" . $i) user=("user" . $i) password="123" add-default-route=no use-peer-dns=no disabled=no
}

# 📦 Interface List: WAN
/interface list add name=WAN
:for i from=1 to=$totalLines do={
    /interface list member add interface=("pppoe-out" . $i) list=WAN
}

# 🔄 Mangle Accept Rule First
/ip firewall mangle add chain=prerouting action=accept in-interface-list=WAN place-before=0

# 🔥 NAT Masquerade
/ip firewall nat add action=masquerade chain=srcnat out-interface-list=WAN

# 🧠 PCC Load Balancing
:for i from=1 to=$totalLines do={
    /routing table add name=("toLine" . $i)
/ip firewall mangle add chain=prerouting dst-address-type=!local in-interface-list=LAN connection-mark=no-mark action=mark-connection new-connection-mark=("conn" . $i) passthrough=yes per-connection-classifier=("both-addresses-and-ports:" . $totalLines . "/" . ($i - 1))
/ip firewall mangle add chain=prerouting connection-mark=("conn" . $i) action=mark-routing new-routing-mark=("toLine" . $i) passthrough=yes
/routing rule add src-address=192.168.50.0/24 action=lookup-only-in-table table=("toLine" . $i)
/ip route add dst-address=0.0.0.0/0 gateway=("pppoe-out" . $i) routing-table=("toLine" . $i)
}

# 🛡️ PPPoE Server Setup (optional)
/interface pppoe-server server add interface=$pppoeInterface service-name="pppoe" disabled=no default-profile="default"

/ip pool add name=pppoe-pool ranges=192.168.88.10-192.168.88.200
/ppp profile add name="default" local-address=192.168.88.1 remote-address=pppoe-pool use-mpls=no use-compression=no use-encryption=no only-one=yes

# 👥 Create User Secrets
:for i from=1 to=$profileCount do={
    :local rate ($i * 5) . "M"
    /ppp profile add name=("LB" . $rate) rate-limit=($rate . "/" . $rate) local-address=192.168.88.1 remote-address=pppoe-pool
    /ppp secret add name=("user" . $i) password="123" profile=("LB" . $rate) service=pppoe
}
