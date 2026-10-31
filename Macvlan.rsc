:foreach i in=[/interface macvlan find] do={
    :local oldmac [/interface macvlan get $i mac-address]
    :local newmac ("D4:F9:A1:" . [:pick $oldmac 9 17])

    /interface macvlan set $i mac-address=$newmac

    :put ($oldmac . " -> " . $newmac)
}
