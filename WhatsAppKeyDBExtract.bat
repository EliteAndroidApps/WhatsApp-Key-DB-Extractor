@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
color 0a
title WhatsApp Key/DB Extractor 4.7 (Official)
echo.
echo =========================================================================
echo = This script will extract the WhatsApp Key file and DB on Android 4.0+ =
echo = You DO NOT need root for this to work but you DO need Java installed. =
echo = If your WhatsApp version is greater than 2.11.431 (most likely), then =
echo = a legacy version will be installed temporarily in order to get backup =
echo = permissions. You will NOT lose ANY data and your current version will =
echo = be restored at the end of the extraction process so try not to panic. =
echo = Script by: TripCode (Greets to all who visit: XDA Developers Forums). =
echo = Thanks to: dragomerlin for ABE and to Abinash Bishoyi for being cool. =
echo =         ###          Version: v4.7 (12/10/2016)          ###          =
echo =========================================================================
echo.
if not exist bin (
echo Unable to locate the bin directory! Did you extract all the files from the & echo archive ^(maintaining structure^) and are you running from that directory?
echo.
echo Exiting ...
echo.
bin\adb.exe kill-server
pause
exit
)
echo Please connect your Android device with USB Debugging enabled:
echo.
bin\adb.exe kill-server
bin\adb.exe start-server
bin\adb.exe wait-for-device
bin\adb.exe shell getprop ro.build.version.sdk > tmp\sdkver.txt
set /p sdkver=<tmp\sdkver.txt
echo.
if %sdkver% leq 13 (
set sdkver=
echo Unsupported Android Version - this method only works on 4.0 or higher :/
echo.
echo Cleaning up temporary files ...
del tmp\sdkver.txt /s /q
echo.
echo Exiting ...
echo.
bin\adb.exe kill-server
pause
exit
)
bin\adb.exe shell pm path com.whatsapp | bin\grep.exe package > tmp\wapath.txt
bin\adb.exe shell "echo $EXTERNAL_STORAGE" > tmp\sdpath.txt
bin\adb.exe shell dumpsys package com.whatsapp | bin\grep.exe versionName > tmp\wapver.txt
bin\curl.exe -sI http://www.cdn.whatsapp.net/android/2.11.431/WhatsApp.apk | bin\grep.exe Content-Length > tmp\waplen.txt
set /p apkflen=<tmp\waplen.txt
set apkflen=%apkflen:Content-Length: =%
if %apkflen% == 18329558 (
set apkfurl=http://www.cdn.whatsapp.net/android/2.11.431/WhatsApp.apk
) else (
set apkfurl=http://whatcrypt.com/WhatsApp-2.11.431.apk
)
set /p apkpath=<tmp\wapath.txt
set /p sdpath=<tmp\sdpath.txt
set apkpath=%apkpath:package:=%
set /p version=<tmp\wapver.txt
for %%A in ("%apkpath%") do (
set apkname=%%~nxA
)
:nextVar
for /F "tokens=1" %%k in ("%version%") do (
set %%k
set version=%%v
)
for %%A in (wapath.txt) do if %%~zA==0 (
set apkpath=
echo.
echo WhatsApp is not installed on the target device
echo.
echo Exiting ...
echo.
) else (
echo WhatsApp %versionName% installed
echo.
if %versionName% gtr 2.11.431 (
if not exist tmp\LegacyWhatsApp.apk (
echo Downloading legacy WhatsApp 2.11.431 to local folder
bin\curl.exe -o tmp\LegacyWhatsApp.apk %apkfurl%
) else (
echo Found legacy WhatsApp 2.11.431 in local folder
)
echo.
if %sdkver% geq 11 (
bin\adb.exe shell am force-stop com.whatsapp
) else (
bin\adb.exe shell am kill com.whatsapp
)
echo Backing up WhatsApp %versionName%
bin\adb.exe pull %apkpath% tmp
echo Backup complete
echo.
if %sdkver% geq 23 (
echo Removing WhatsApp %versionName% skipping data
bin\adb.exe shell pm uninstall -k com.whatsapp
echo Removal complete
echo.
)
echo Installing legacy WhatsApp 2.11.431
if %sdkver% geq 17 (
bin\adb.exe install -r -d tmp\LegacyWhatsApp.apk
) else (
bin\adb.exe install -r tmp\LegacyWhatsApp.apk
)
echo Install complete
echo.
if %sdkver% geq 23 (
bin\adb.exe backup -f tmp\whatsapp.ab com.whatsapp
) else (
bin\adb.exe backup -f tmp\whatsapp.ab -noapk com.whatsapp
)
if exist tmp\whatsapp.ab (
echo.
set /p password="Please enter your backup password (leave blank for none) and press Enter: "
echo.
if "!password!" == "" (
java -jar bin\abe.jar unpack tmp\whatsapp.ab tmp\whatsapp.tar
) else (
java -jar bin\abe.jar unpack tmp\whatsapp.ab tmp\whatsapp.tar "!password!"
)
bin\tar.exe xvf tmp\whatsapp.tar -C tmp\ apps/com.whatsapp/f/key
bin\tar.exe xvf tmp\whatsapp.tar -C tmp\ apps/com.whatsapp/db/msgstore.db
bin\tar.exe xvf tmp\whatsapp.tar -C tmp\ apps/com.whatsapp/db/wa.db
bin\tar.exe xvf tmp\whatsapp.tar -C tmp\ apps/com.whatsapp/db/axolotl.db
bin\tar.exe xvf tmp\whatsapp.tar -C tmp\ apps/com.whatsapp/db/chatsettings.db
echo.
if exist tmp\apps\com.whatsapp\f\key (
echo Extracting whatsapp.cryptkey ...
copy tmp\apps\com.whatsapp\f\key extracted\whatsapp.cryptkey
echo.
)
if exist tmp\apps\com.whatsapp\db\msgstore.db (
echo Extracting msgstore.db ...
copy tmp\apps\com.whatsapp\db\msgstore.db extracted\msgstore.db
echo.
)
if exist tmp\apps\com.whatsapp\db\wa.db (
echo Extracting wa.db ...
copy tmp\apps\com.whatsapp\db\wa.db extracted\wa.db
echo.
)
if exist tmp\apps\com.whatsapp\db\axolotl.db (
echo Extracting axolotl.db ...
copy tmp\apps\com.whatsapp\db\axolotl.db extracted\axolotl.db
echo.
)
if exist tmp\apps\com.whatsapp\db\chatsettings.db (
echo Extracting chatsettings.db ...
copy tmp\apps\com.whatsapp\db\chatsettings.db extracted\chatsettings.db
echo.
)
if exist tmp\apps\com.whatsapp\f\key (
echo Pushing cipher key to: %sdpath%/WhatsApp/Databases/.nomedia
bin\adb.exe push tmp\apps\com.whatsapp\f\key %sdpath%/WhatsApp/Databases/.nomedia
echo.
)
echo Cleaning up temporary files ...
echo.
if exist tmp\whatsapp.ab (
del tmp\whatsapp.ab /s /q
)
if exist tmp\whatsapp.tar (
del tmp\whatsapp.tar /s /q
)
if exist tmp\waplen.txt (
del tmp\waplen.txt /s /q
)
if exist tmp\sdpath.txt (
del tmp\sdpath.txt /s /q
)
if exist tmp\wapath.txt (
del tmp\wapath.txt /s /q
)
if exist tmp\wapver.txt (
del tmp\wapver.txt /s /q
)
if exist tmp\sdkver.txt (
del tmp\sdkver.txt /s /q
)
if exist tmp\apps (
rmdir tmp\apps /s /q
)
echo.
echo Done
echo.
) else (
echo Operation failed
)
if not exist tmp\%apkname% (
echo Downloading WhatsApp %versionName% to local folder
bin\curl.exe -o tmp\%apkname% http://www.cdn.whatsapp.net/android/%versionName%/WhatsApp.apk
)
if exist tmp\%apkname% (
echo Restoring WhatsApp %versionName%
if %sdkver% geq 17 (
bin\adb.exe install -r -d tmp\%apkname%
) else (
bin\adb.exe install -r tmp\%apkname%
)
echo.
echo Restore complete
echo.
echo Removing WhatsApp %versionName% temporary apk
del tmp\%apkname% /s /q
)
) else (
echo Operation failed
)
)
)
set sdkver=
set apkpath=
set sdpath=
set apkname=
set apkflen=
set apkfurl=
set version=
set versInfo=
set versionName=
set password=
echo.
echo Operation complete
echo.
bin\adb.exe kill-server
pause
exit
