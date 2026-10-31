# All MacVlan change just run this command
# just replace XX:XX:XX any OUI first 3 
:foreach i in=[/interface macvlan find] do={
    :local oldmac [/interface macvlan get $i mac-address]
    :local newmac ("XX:XX:XX:" . [:pick $oldmac 9 17])

    /interface macvlan set $i mac-address=$newmac

    :put ($oldmac . " -> " . $newmac)
}
