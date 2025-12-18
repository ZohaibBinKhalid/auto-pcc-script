# ================================
# Auto PCC Load Balancing Script
# Upgrade-Friendly Version
# Script by: Zohaib Bin Khalid
# ================================

# -------- User Input --------
:local totalLines ""
:local baseInterface ""
:local readinput do={:return}

/put "\n?? Enter number of lines:"
:set totalLines [$readinput]

/put "\n?? Enter base interface (e.g., ether2):"
/set baseInterface [$readinput]

# -------- Detect existing lines --------
:local existingLines 0
:foreach iface in=[/interface pppoe-client find] do={
    :local name [/interface pppoe-client get $iface name]
    :if ([:find $name "pppoe-out"] != nil) do={
        :local num [:pick $name 9 [:len $name]]
        :if ($num > $existingLines) do={ :set existingLines $num }
    }
}
:put ("?? Detected " . $existingLines . " existing lines.")

# -------- Create WAN list if not exist --------
:if ([:len [/interface list find name="WAN"]] = 0) do={
    /interface list add name="WAN"
}

# -------- Create routing tables --------
:for i from=1 to=$totalLines do={
    :local rtname ("to-wan" . $i)
    :if ([:len [/routing table find name=$rtname]] = 0) do={
        /routing table add name=$rtname fib
    }
}

# -------- Step 1: Create NEW lines only --------
:for i from=($existingLines + 1) to=$totalLines do={

    :local vlanName ("macvlan" . $i)
    :local pppoeName ("pppoe-out" . $i)
    :local username ("pppoeuser" . $i)
    :local password ("password" . $i)

    /interface macvlan add name=$vlanName interface=$baseInterface mode=private
    /interface pppoe-client add name=$pppoeName interface=$vlanName user=$username password=$password profile=default-encryption use-peer-dns=no add-default-route=no disabled=no
    /interface list member add list=WAN interface=$pppoeName

    :put ("? Added new line: " . $pppoeName)
}

# -------- Step 2: Connection-Marks --------
:for i from=1 to=$totalLines do={
    :local connmark ("wan" . $i . "-conn")
    :local index ($i - 1)

    :if ([:len [/ip firewall mangle find new-connection-mark=$connmark]] = 0) do={
        /ip firewall mangle add chain=prerouting src-address-list=clients connection-mark=no-mark \
            action=mark-connection dst-address-type=!local new-connection-mark=$connmark \
            per-connection-classifier=("both-addresses-and-ports:" . $totalLines . "/" . $index) passthrough=yes
    }
}

# -------- Step 3: Routing-Marks + Routes --------
:for i from=1 to=$totalLines do={
    :local pppoeName ("pppoe-out" . $i)
    :local rtmark ("to-wan" . $i)
    :local connmark ("wan" . $i . "-conn")

    :if ([:len [/ip firewall mangle find new-routing-mark=$rtmark]] = 0) do={
        /ip firewall mangle add chain=prerouting connection-mark=$connmark src-address-list=clients \
            action=mark-routing new-routing-mark=$rtmark passthrough=yes
    }

    :if ([:len [/ip route find gateway=$pppoeName routing-table=$rtmark]] = 0) do={
        /ip route add dst-address=0.0.0.0/0 gateway=$pppoeName routing-table=$rtmark
    }
}

# -------- Step 3b: Default routes in main --------
:for i from=1 to=$totalLines do={
    :local pppoeName ("pppoe-out" . $i)
    :if ([:len [/ip route find gateway=$pppoeName routing-table=main]] = 0) do={
        /ip route add dst-address=0.0.0.0/0 gateway=$pppoeName routing-table=main distance=$i
    }
}

# -------- Step 4: WAN Accept + NAT --------
# --- Ensure Accept rule for WAN in Mangle ---
:if ([:len [/ip firewall mangle find where chain=prerouting action=accept in-interface-list=WAN]] = 0) do={
    /ip firewall mangle add chain=prerouting in-interface-list=WAN action=accept comment="Accept WAN"
    :put "? Added Accept WAN mangle rule"
} else={
    :put "?? Accept WAN mangle rule already exists, skipping"
}

# --- Ensure Masquerade NAT for WAN ---
:if ([:len [/ip firewall nat find where chain=srcnat action=masquerade out-interface-list=WAN]] = 0) do={
    /ip firewall nat add chain=srcnat out-interface-list=WAN action=masquerade comment="Masquerade all WANs"
    :put "? Added NAT masquerade rule"
} else={
    :put "?? NAT masquerade rule already exists, skipping"
}


# -------- Step 5: Clients Address-List --------
:if ([:len [/ip firewall address-list find list=clients]] = 0) do={
    /ip firewall address-list add list=clients address=192.168.77.0/24
}

# -------- Final Success Banner --------
:delay 1
:put "*******************************************************"
:put "*                                                     *"
:put "*    * Successfully Installed Auto PCC Script!        *"
:put "*    **  Whats App: +92323-4127611                    *"
:put "*    *** Thank you for using my script                *"
:put "*    **** Script by: Zohaib Bin Khalid                *"
:put "*                                                     *"
:put "*******************************************************"

# -------- Cleanup --------
:delay 2
:local scriptFileName "auto-pcc.rsc"
/file remove [find name=$scriptFileName]
:delay 3
:local scriptFileName2 "auto-pcc-installer.rsc"
/file remove [find name=$scriptFileName2]
