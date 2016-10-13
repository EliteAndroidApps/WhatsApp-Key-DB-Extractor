$Host.UI.RawUI.WindowTitle = "WhatsApp Key/DB Extractor 4.7 (Official)"
Function TerminateWithReason([String] $reason)
{
"`r`n$reason`r`n`r`nExiting...`r`n"
Invoke-Expression "bin\adb.exe kill-server"
&cmd /c pause
exit
}
"`r`n========================================================================="
"= This script will extract the WhatsApp Key file and DB on Android 4.0+ ="
"= You DO NOT need root for this to work but you DO need Java installed. ="
"= If your WhatsApp version is greater than 2.11.431 (most likely), then ="
"= a legacy version will be installed temporarily in order to get backup ="
"= permissions. You will NOT lose ANY data and your current version will ="
"= be restored at the end of the extraction process so try not to panic. ="
"= Script by: TripCode (Greets to all who visit: XDA Developers Forums). ="
"= Thanks to: dragomerlin for ABE and to Abinash Bishoyi for being cool. ="
"=         ###          Version: v4.7 (12/10/2016)          ###          ="
"=========================================================================`r`n"
If (!(Test-Path "bin"))
{
TerminateWithReason("Unable to locate the bin directory! Did you extract all the files from the`r`narchive (maintaining structure) and are you running from that directory?")
}
"Please connect your Android device with USB Debugging enabled:`r`n"
Invoke-Expression "bin\adb.exe kill-server"
Invoke-Expression "bin\adb.exe start-server"
Invoke-Expression "bin\adb.exe wait-for-device"
$sdkver = Invoke-Expression "bin\adb.exe shell getprop ro.build.version.sdk 2>&1"
$sdpath = Invoke-Expression 'bin\adb.exe shell "echo `$EXTERNAL_STORAGE" 2>&1'
If ($sdkver -le 13)
{
TerminateWithReason("Unsupported Android Version - this method only works on 4.0 or higher :/")
}
$apkpath = Invoke-Expression "bin\adb.exe shell pm path com.whatsapp | bin\grep.exe package 2>&1"
If ($apkpath)
{
$apkpath = $apkpath.Trim() -replace 'package:'
}
$apkname = [System.IO.Path]::GetFileName($apkpath)
$version = Invoke-Expression "bin\adb.exe shell dumpsys package com.whatsapp | bin\grep.exe versionName 2>&1"
If ($version)
{
$version = $version.Trim() -replace 'versionName='
} Else {
TerminateWithReason("WhatsApp is not installed on the target device")
}
$apkflen = Invoke-Expression "bin\curl.exe -sI http://www.cdn.whatsapp.net/android/2.11.431/WhatsApp.apk | bin\grep.exe Content-Length 2>&1"
If ($apklen)
{
$apkflen = $apkflen.Trim() -replace 'Content-Length: '
} Else {
$apkflen = 0;
}
If ($apkflen -eq 18329558)
{
$apkfurl = "http://www.cdn.whatsapp.net/android/2.11.431/WhatsApp.apk"
} Else {
$apkfurl = "http://whatcrypt.com/WhatsApp-2.11.431.apk"
}
"`r`nWhatsApp $version installed`r`n"
If (Test-Path "tmp\LegacyWhatsApp.apk")
{
"Found legacy WhatsApp 2.11.431 in local folder`r`n"
} Else {
"Downloading legacy WhatsApp 2.11.431 to local folder`r`n"
Invoke-Expression "bin\curl.exe -o tmp\LegacyWhatsApp.apk $apkfurl"
""
}
If ($sdkver -ge 11)
{
Invoke-Expression "bin\adb.exe shell am force-stop com.whatsapp"
} Else {
Invoke-Expression "bin\adb.exe shell am kill com.whatsapp"
}
"Backing up WhatsApp $version"
Invoke-Expression "bin\adb.exe pull $apkpath tmp"
"Backup complete`r`n"
If ($sdkver -ge 23)
{
"Removing WhatsApp $version skipping data"
Invoke-Expression "bin\adb.exe shell pm uninstall -k com.whatsapp"
"Removal complete`r`n"
}
"Installing legacy WhatsApp 2.11.431"
If ($sdkver -ge 17)
{
Invoke-Expression "bin\adb.exe install -r -d tmp\LegacyWhatsApp.apk"
} Else {
Invoke-Expression "bin\adb.exe install -r tmp\LegacyWhatsApp.apk"
}
"Install complete`r`n"
If ($sdkver -ge 23)
{
Invoke-Expression "bin\adb.exe backup -f tmp\whatsapp.ab com.whatsapp"
} Else {
Invoke-Expression "bin\adb.exe backup -f tmp\whatsapp.ab -noapk com.whatsapp"
}

If (Test-Path "tmp\whatsapp.ab")
{
""
$password = Read-Host 'Please enter your backup password (leave blank for none) and press Enter'
""
If (!$password)
{
Invoke-Expression "java -jar bin\abe.jar unpack tmp\whatsapp.ab tmp\whatsapp.tar"
} Else {
Invoke-Expression "java -jar bin\abe.jar unpack tmp\whatsapp.ab tmp\whatsapp.tar $password"
}
}
""
Invoke-Expression "bin\tar.exe xvf tmp\whatsapp.tar -C tmp\ apps/com.whatsapp/f/key"
Invoke-Expression "bin\tar.exe xvf tmp\whatsapp.tar -C tmp\ apps/com.whatsapp/db/msgstore.db"
Invoke-Expression "bin\tar.exe xvf tmp\whatsapp.tar -C tmp\ apps/com.whatsapp/db/wa.db"
Invoke-Expression "bin\tar.exe xvf tmp\whatsapp.tar -C tmp\ apps/com.whatsapp/db/axolotl.db"
Invoke-Expression "bin\tar.exe xvf tmp\whatsapp.tar -C tmp\ apps/com.whatsapp/db/chatsettings.db"
""
If (Test-Path "tmp\apps\com.whatsapp\f\key")
{
"Extracting whatsapp.cryptkey ..."
Copy-Item tmp\apps\com.whatsapp\f\key extracted\whatsapp.cryptkey
}
If (Test-Path "tmp\apps\com.whatsapp\db\msgstore.db")
{
"Extracting msgstore.db ..."
Copy-Item tmp\apps\com.whatsapp\db\msgstore.db extracted\msgstore.db
}
If (Test-Path "tmp\apps\com.whatsapp\f\key")
{
"Extracting wa.db ..."
Copy-Item tmp\apps\com.whatsapp\db\wa.db extracted\wa.db
}
If (Test-Path "tmp\apps\com.whatsapp\db\axolotl.db")
{
"Extracting axolotl.db ..."
Copy-Item tmp\apps\com.whatsapp\db\axolotl.db extracted\axolotl.db
}
If (Test-Path "tmp\apps\com.whatsapp\f\key")
{
"Extracting chatsettings.db ..."
Copy-Item tmp\apps\com.whatsapp\db\chatsettings.db extracted\chatsettings.db
}
If (Test-Path "tmp\apps\com.whatsapp\f\key")
{
"`r`nPushing cipher key to: $sdpath/WhatsApp/Databases/.nomedia"
Invoke-Expression "bin\adb.exe push tmp\apps\com.whatsapp\f\key $sdpath/WhatsApp/Databases/.nomedia"
""
}
"Cleaning up temporary files ..."
If (Test-Path "tmp\whatsapp.ab")
{
Remove-Item tmp\whatsapp.ab
}
If (Test-Path "tmp\whatsapp.tar")
{
Remove-Item tmp\whatsapp.tar
}
If (Test-Path "tmp\apps")
{
Remove-Item tmp\apps -recurse
}
"Done`r`n"
if (-Not (Test-Path  "tmp\$apkname"))
{
"Downloading WhatsApp $version to local folder`r`n"
Invoke-Expression "bin\curl.exe -o tmp\$apkname http://www.cdn.whatsapp.net/android/$version/WhatsApp.apk"
}
"Restoring WhatsApp $version"
If ($sdkver -ge 17)
{
Invoke-Expression "bin\adb.exe install -r -d tmp\$apkname"
} Else {
Invoke-Expression "bin\adb.exe install -r tmp\$apkname"
}
"Restore complete`r`n"
"Removing WhatsApp $version temporary apk`r`n"
Remove-Item tmp\$apkname
"`r`nOperation complete`r`n"
Invoke-Expression "bin\adb.exe kill-server"
&cmd /c pause
exit
