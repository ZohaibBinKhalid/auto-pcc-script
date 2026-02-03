:log info " Downloading auto-pcc.rsc from GitHub/ZohaibBinKhalid" 
/tool fetch url="https://raw.githubusercontent.com/ZohaibBinKhalid/auto-pcc-script/main/auto-pcc.rsc" mode=https

:delay 2

:log info " Importing the auto-pcc.rsc script..." 

/import file-name=auto-pcc.rsc
