/system script
add name="Random-PPPoE-Restart" policy=read,write,test source={

    :local selectedIds [:toarray ""]
    :local total 0

    :for i from=1 to=6 do={

        :local candidates [/interface pppoe-client find where running=yes]
        :local count [:len $candidates]

        :if ($count > 0) do={

            :local randomIndex [:rndnum from=0 to=($count - 1)]
            :local index 0

            :foreach id in=$candidates do={

                :if ($index = $randomIndex) do={

                    /interface pppoe-client disable $id
                    :set selectedIds ($selectedIds, $id)
                    :set total ($total + 1)

                    :log warning ("Random PPPoE Disabled: " . [/interface pppoe-client get $id name])

                }

                :set index ($index + 1)
            }
        }
    }

    :log warning ("Total PPPoE Disabled: " . $total)

    :delay 20s

    :foreach id in=$selectedIds do={

        /interface pppoe-client enable $id

        :log warning ("Random PPPoE Enabled: " . [/interface pppoe-client get $id name])

    }

    :log warning "Random PPPoE Restart Completed"
}

/system scheduler
add name="Random-PPPoE-Every-2-Hours" \
interval=2h start-time=00:00:00 \
on-event="Random-PPPoE-Restart" \
policy=read,write,test
