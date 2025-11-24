Auto PCC + MAC-VLAN + Optional PPPoE Server (MikroTik Script)
📌 Overview

This MikroTik RouterOS script automatically configures load balancing with PCC using MAC-VLAN based PPPoE clients, with an optional PPPoE server setup.
It is designed for ISPs or network admins who want a quick, automated way to deploy multiple WAN lines with efficient bandwidth distribution.

✨ Features

🔹 Auto-create MAC-VLANs on the base interface for each WAN line

🔹 Auto-generate PPPoE clients on VLANs with random MAC addresses

🔹 Add all WAN clients to the WAN interface list

🔹 Mangle rules for PCC load balancing (both-addresses-and-ports)

🔹 Routing marks + connection marks auto-generated per WAN line

🔹 Masquerade NAT rule for WAN interface list

🔹 Optional PPPoE server setup (IP pool, profiles, secrets, and address-list)

🔹 Fully configurable with :local variables at the top of the script

⚙️ Requirements

MikroTik Router (RouterOS v7.x recommended)

Router with working Internet access

Admin access to /system, /interface, /ppp, /ip firewall, /queue, /routing

📥 Installation
1. Download Script

On your MikroTik router, run:
:log info " Downloading auto-pcc.rsc from GitHub/ZohaibBinKhalid"

/tool fetch url="https://raw.githubusercontent.com/ZohaibBinKhalid/auto-pcc-script/new/main/auto-pcc.rsc" mode=https

:delay 2

:log info " Importing the auto-pcc.rsc script..."
/import file-name=auto-pcc.rsc

:delay 3

:log info " Cleaning up temporary file..."
/file remove [find name="auto-pcc.rsc"]
/file remove [find name="auto-pcc-installer.rsc"]
