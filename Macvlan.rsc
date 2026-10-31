:foreach i in=[/interface macvlan find] do={

    :local vendor [:rndnum from=0 to=3]
    :local prefix ""

    :if ($vendor = 0) do={ :set prefix "50:C7:BF" }
    :if ($vendor = 1) do={ :set prefix "C8:3A:35" }
    :if ($vendor = 2) do={ :set prefix "00:19:C6" }
    :if ($vendor = 3) do={ :set prefix "00:E0:FC" }

    :local newmac ""
    :local duplicate true

    :while ($duplicate = true) do={

        :local h1 [:rndstr from="0123456789ABCDEF" length=2]
        :local h2 [:rndstr from="0123456789ABCDEF" length=2]
        :local h3 [:rndstr from="0123456789ABCDEF" length=2]

        :set newmac ($prefix . ":" . $h1 . ":" . $h2 . ":" . $h3)

        :if ([:len [/interface macvlan find where mac-address=$newmac]] = 0) do={
            :set duplicate false
        }
    }

    :local oldmac [/interface macvlan get $i mac-address]
    :local ifname [/interface macvlan get $i name]

    /interface macvlan set $i mac-address=$newmac

    :log warning ("MAC Updated: " . $ifname . " | " . $oldmac . " -> " . $newmac)

    :put ($ifname . " | " . $oldmac . " -> " . $newmac)
}
