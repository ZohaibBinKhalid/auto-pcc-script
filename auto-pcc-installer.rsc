:log info " Downloading auto-pcc.rsc from GitHub/ZohaibBinKhalid" 
/tool fetch url="https://raw.githubusercontent.com/ZohaibBinKhalid/auto-pcc-script/new/main/auto-pcc.rsc" mode=https

:delay 2

:log info " Importing the auto-pcc.rsc script..." /import file-name=auto-pcc.rsc

:delay 3

:log info " Cleaning up temporary file..." /file remove [find name="auto-pcc.rsc"] /file remove [find name="auto-pcc-installer.rsc"]
