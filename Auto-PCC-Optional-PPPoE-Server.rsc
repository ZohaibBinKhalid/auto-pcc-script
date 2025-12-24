# ================================
# Auto PCC Load Balancing + Optional PPPoE Server
# Upgrade-Safe Version
# Script by Zohaib Bin Khalid
# ================================

:local totalLines ""
:local baseInterface ""
:local makePPPoE ""
:local readinput do={:return}

/put "\nEnter number of lines:"
:set totalLines [$readinput]

/put "\nEnter base interface (e.g., ether2):"
:set baseInterface [$readinput]

/put "\nDo you want to create PPPoE Server? (Y/N):"
:set makePPPoE [$readinput]

:local pppoeSrvInterface ""
:if ($makePPPoE = "Y" || $makePPPoE = "y") do={
    /put "\nEnter interface for PPPoE Server (e.g., ether10, vlan100):"
    :set pppoeSrvInterface [$readinput]
}

:local existingLines 0
:foreach iface in=[/interface pppoe-client find] do={
    :local name [/interface pppoe-client get $iface name]
    :if ([:find $name "pppoe-out"] != -1) do={
        :local num [:pick $name 9 [:len $name]]
        :if ($num > $existingLines) do={ :set existingLines $num }
    }
}
:put ("Detected " . $existingLines . " existing lines.")

:if ([:len [/interface list find name="WAN"]] = 0) do={
    /interface list add name="WAN"
}

:foreach mc in=[/ip firewall mangle find new-connection-mark!=""] do={ /ip firewall mangle remove $mc }
:foreach mr in=[/ip firewall mangle find new-routing-mark!=""] do={ /ip firewall mangle remove $mr }
:foreach r in=[/ip route find routing-table="to-wan"] do={ /ip route remove $r }
:foreach nr in=[/ip firewall nat find comment="Masquerade all WANs"] do={ /ip firewall nat remove $nr }

:if ([:len [/ip firewall mangle find chain=prerouting in-interface-list=WAN action=accept]] = 0) do={
    /ip firewall mangle add chain=prerouting in-interface-list=WAN action=accept comment="Accept WAN"
    :put "Added Accept WAN mangle rule"
}

:local natCheck [/ip firewall nat find chain=srcnat out-interface-list=WAN action=masquerade]
:if ([:len $natCheck] = 0) do={
    /ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment="Masquerade all WANs"
    :put "Added NAT masquerade rule"
} else={
    :put "NAT masquerade rule already exists, skipping"
}


:for i from=1 to=$totalLines do={
    :local rtname ("to-wan" . $i)
    :if ([:len [/routing table find name=$rtname]] = 0) do={
        /routing table add name=$rtname fib
        :put ("Created routing table: " . $rtname)
    }
}

:for i from=($existingLines + 1) to=$totalLines do={
    :local vlanName ("macvlan" . $i)
    :local pppoeName ("pppoe-out" . $i)
    :local username ("pppoeuser" . $i)
    :local password ("password" . $i)


    :if ([:len [/interface macvlan find name=$vlanName]] = 0) do={
        /interface macvlan add name=$vlanName interface=$baseInterface mode=private
        :put ("Added MAC VLAN: " . $vlanName)
    } else={
        :put ("MAC VLAN exists, skipping: " . $vlanName)
    }

    :if ([:len [/interface pppoe-client find name=$pppoeName]] = 0) do={
        /interface pppoe-client add name=$pppoeName interface=$vlanName user=$username password=$password \
            profile=default-encryption use-peer-dns=no add-default-route=no disabled=no
        /interface list member add list=WAN interface=$pppoeName
        :put ("Added PPPoE client: " . $pppoeName)
    } else={
        /interface pppoe-client enable [find name=$pppoeName]
        :put ("PPPoE client exists, enabled: " . $pppoeName)
    }
}

:for i from=1 to=$totalLines do={
    :local connmark ("wan" . $i . "-conn")
    :local index ($i - 1)

    /ip firewall mangle add chain=prerouting src-address-list=clients connection-mark=no-mark \
        action=mark-connection dst-address-type=!local new-connection-mark=$connmark \
        per-connection-classifier=("both-addresses-and-ports:" . $totalLines . "/" . $index) passthrough=yes
    :delay 0.2
    :put ("Added mark-connection: " . $connmark)
}

:for i from=1 to=$totalLines do={
    :local connmark ("wan" . $i . "-conn")
    :local rtmark ("to-wan" . $i)

    /ip firewall mangle add chain=prerouting connection-mark=$connmark src-address-list=clients \
        action=mark-routing new-routing-mark=$rtmark passthrough=yes
    :delay 0.2
    :put ("Added mark-routing: " . $rtmark)
}

:for i from=1 to=$totalLines do={
    :local pppoeName ("pppoe-out" . $i)
    :local rtmark ("to-wan" . $i)

    :if ([:len [/ip route find dst-address=0.0.0.0/0 gateway=$pppoeName routing-table=$rtmark]] = 0) do={
        /ip route add dst-address=0.0.0.0/0 gateway=$pppoeName routing-table=$rtmark
        :put ("Added route via " . $pppoeName . " in table " . $rtmark)
    }
}

:for i from=1 to=$totalLines do={
    :local pppoeName ("pppoe-out" . $i)
    :if ([:len [/ip route find dst-address=0.0.0.0/0 gateway=$pppoeName routing-table=main]] = 0) do={
        /ip route add dst-address=0.0.0.0/0 gateway=$pppoeName routing-table=main distance=$i
        :put ("Added main route via " . $pppoeName)
    }
}

:if ([:len [/ip firewall address-list find list=clients]] = 0) do={
    /ip firewall address-list add list=clients address=192.168.77.0/24
}

:if ($makePPPoE = "Y" || $makePPPoE = "y") do={

    :put "Creating PPPoE Server setup..."

    
    :if ([:len [/ip pool find name="pppoe-pool"]] = 0) do={
        /ip pool add name=pppoe-pool ranges=10.10.10.2-10.10.10.254
        :put "IP Pool created"
    } else={ :put "IP Pool exists, skipping" }

    
    :if ([:len [/ppp profile find name="default-pppoe"]] = 0) do={
        /ppp profile add name=default-pppoe local-address=10.10.10.1 remote-address=pppoe-pool use-mpls=no use-upnp=no use-ipv6=no
    } else={ :put "Default PPP profile exists, skipping" }

    
    :local speeds {"5";"10";"15";"20";"25";"30";"40";"50";"60";"70";"80";"90";"100"}
    :foreach s in=$speeds do={
        :local profname ("PPPoE-" . $s . "M")
        :local rate ($s . "M/" . $s . "M")
        :if ([:len [/ppp profile find name=$profname]] = 0) do={
            /ppp profile add name=$profname local-address=10.10.10.1 remote-address=pppoe-pool rate-limit=$rate use-mpls=no only-one=yes dns-server=8.8.8.8,1.1.1.1 use-upnp=no use-ipv6=no
        } else={ :put ("Profile exists, skipping: " . $profname) }
    }

    
    :if ([:len [/ppp secret find name="test"]] = 0) do={
        /ppp secret add name="test" password="1234" service=pppoe profile=PPPoE-10M
        :put "Test PPPoE user created (test / 1234)"
    } else={
        /ppp secret enable [find name="test"]
        :put "Test PPPoE user exists, enabled"
    }

    
    :local srv [/interface pppoe-server server find service-name="PPPoE-Server"]
    :if ([:len $srv] = 0) do={
        /interface pppoe-server server add interface=$pppoeSrvInterface service-name="PPPoE-Server" \
            authentication=pap,chap,mschap1,mschap2 one-session-per-host=yes default-profile=default-pppoe \
            max-mru=1480 max-mtu=1480 disabled=no
        :put ("PPPoE Server created on " . $pppoeSrvInterface)
    } else={
        /interface pppoe-server server enable [find service-name="PPPoE-Server"]
        :put ("PPPoE Server exists, enabled on " . $pppoeSrvInterface)
    }

   
:if ([:len [/ip firewall address-list find list=clients address=10.10.10.0/24]] = 0) do={
    /ip firewall address-list add list=clients address=10.10.10.0/24
    :put "Added PPPoE pool to clients address-list"
} else={
    :put "Clients address-list for PPPoE pool already exists, skipping"
}

}


:delay 1
:put "***********************************************************"
:put "*                                                         *"
:put "*    Successfully Installed Auto PCC Script!              *"
:put "*    Whats App: +92323-4127611                            *"
:put "*    Thank you for using this script                      *"
:put "*    Script by: Zohaib Bin Khalid                         *"
:put "*                                                         *"
:put "***********************************************************"
