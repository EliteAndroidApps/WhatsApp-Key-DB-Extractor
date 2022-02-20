@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
color 0a
title WhatsApp Key/DB Extractor 4.7 Enhanced 1.0 (Unofficial by p4r4d0x86)
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
echo =         ###       Version: v4.7-E1.0 (08/05/2019)        ###          =
echo =========================================================================
echo.
if not exist bin (
	echo Unable to locate the bin directory! Did you extract all the files from the & echo archive ^(maintaining structure^) and are you running from that directory?
	goto exit
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
	goto exit
)

REM Getting variables
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

for /F "tokens=1" %%k in ("%version%") do (
	set %%k
	set version=%%v
)

echo.
echo ##### WhatsApp installation and version checks #####
REM FIXME == or EQU ? This test is not working correctly 
for %%A in (tmp\wapath.txt) do if %%~zA==0 (
	set apkpath=
	echo.
	echo WhatsApp is not installed on the target device
	
	if exist tmp\base.apk (
		:base
		echo A backuped version has been found in /tmp folder and could be restored
		echo Legacy application can't be directly installed on Android 7.0+
		set /p base=" Do you want to restore previous WhatsApp version (Y/N)? "
		echo.
		if /i "!base!" == "N" goto exit
		if /i "!base!" == "Y" (
			echo Restoring WhatsApp previous version
			if %sdkver% geq 17 (
				bin\adb.exe install -r -d tmp\base.apk
			) else (
				bin\adb.exe install -r tmp\base.apk
			)
			echo Restore complete
			echo Please restart the script
			goto exit
		) else (
			echo Unsupported option
			goto base
		)
	)
) 
	
echo WhatsApp %versionName% installed

if %versionName% gtr 2.11.431 (
	echo WhatsApp downgrade required
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
	REM FIXME : add a more secure check
	bin\adb.exe pull %apkpath% tmp
	echo Backup complete
	echo.
	if %sdkver% geq 23 (
		echo Removing WhatsApp %versionName% skipping data
		bin\adb.exe shell pm uninstall -k com.whatsapp
		REM FIXME : add a more secure check
		echo Removal complete
		echo.
	)

	REM Legacy WhatsApp installation
	echo Installing legacy WhatsApp 2.11.431
	if %sdkver% geq 24 (
		echo Android version 7.0 or higher detected
		echo Device may have to be rebooted to downgrade and avoid failure 
		echo like ^"[INSTALL_FAILED_VERSION_DOWNGRADE]^"
		echo.
		:reboot
		set /p reboot="Do you want to reboot (Y/N)? "
		echo.
		if /i "!reboot!" == "Y" goto rebootY
		if /i "!reboot!" == "N" goto rebootN
		echo Unsupported option
		goto reboot

		:rebootY 
		bin\adb.exe reboot
		bin\adb.exe wait-for-device
		echo Press any key once device is ready (to avoid error ^"can't find package ...^")
		pause

		:rebootN
		if %sdkver% geq 17 (
			bin\adb.exe install -r -d tmp\LegacyWhatsApp.apk
		) else (
			bin\adb.exe install -r tmp\LegacyWhatsApp.apk
		)
	)
	
	REM Test if downgrade was successfull
	bin\adb.exe shell dumpsys package com.whatsapp | bin\grep.exe versionName > tmp\newwapver.txt
	set /p currentversion=<tmp\newwapver.txt
	for /F "tokens=1" %%j in ("%currentversion%") do (
		set %%j
		set currentversion=%%v
	)
	if %versionName% equ 2.11.431 (
		echo Legacy WhatsApp correctly downgraded
	) else (
		goto exit
	)
) else (
	echo No downgrade required
)

echo Please start/launch downgraded WhatsApp application
echo It seems to help avoiding empty or incomplete backup via ^"adb backup^" command
echo Press any key once started
pause 


echo.
echo ##### Backup Creation #####

:backup
echo You can backup using "adb backup" command (option A)
echo or you can use "bu" command and then "adb pull" (option B) (need enough storage on sdcard)
set /p backup=" A or B ? "
echo.
if /i "!backup!" == "A" (
	if %sdkver% geq 23 (
		bin\adb.exe backup -f tmp\whatsapp.ab com.whatsapp
	) else (
		bin\adb.exe backup -f tmp\whatsapp.ab -noapk com.whatsapp
	)
) else (
	if /i "!backup!" == "B" (
		if %sdkver% geq 28 (
			echo Android 9.0 or higher
			bin\adb.exe shell "bu backup com.whatsapp ^> /sdcard/whatsapp.ab"
			bin\adb.exe pull /sdcard/whatsapp.ab tmp/whatsapp.ab
		) else (
			if %sdkver% geq 23 (
				echo Android 6 to 8.1
				bin\adb.exe shell "bu 1 backup com.whatsapp ^> /sdcard/whatsapp.ab"
				bin\adb.exe pull /sdcard/whatsapp.ab tmp/whatsapp.ab
			) else (
				echo Android before 6
				bin\adb.exe shell "bu 1 backup -noapk com.whatsapp ^> /sdcard/whatsapp.ab"
				bin\adb.exe pull /sdcard/whatsapp.ab tmp/whatsapp.ab
			)
		)
	) else (
		echo Unsupported option
		goto backup
	)
)

REM Test on backup size
For %%f in (tmp\whatsapp.ab) do (
	echo Size of tmp\whatsapp.ab is %%~zf bytes
	if %%~zf equ 0 (
		echo Backup is empty
		echo Backup extraction skipped
		goto clean
	)
)

echo.
echo ##### Backup extraction #####
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
) else (
	echo Backup extraction failed
)

:clean	
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
if exist tmp\newwapver.txt (
	del tmp\newwapver.txt /s /q
)
if exist tmp\sdkver.txt (
	del tmp\sdkver.txt /s /q
)
if exist tmp\apps (
	rmdir tmp\apps /s /q
)
echo Done


echo.
echo ##### Restore previous WhatsApp version #####
if not exist tmp\%apkname% (
	echo Downloading WhatsApp %versionName% to local folder
	bin\curl.exe -o tmp\%apkname% http://www.cdn.whatsapp.net/android/%versionName%/WhatsApp.apk
)


if exist tmp\%apkname% (
	:restore
	echo When debugging or on error, you might save time by not restoring the updated version.
	set /p restore="Do you want to restore previous WhatsApp version (Y/N)? "
	echo.
	if /i "!restore!" == "Y" goto restoreY
	if /i "!restore!" == "N" goto exit
	echo Unsupported option
	goto :restore

	:restoreY
	echo Restoring WhatsApp previous version
	if %sdkver% geq 17 (
		bin\adb.exe install -r -d tmp\%apkname%
	) else (
		bin\adb.exe install -r tmp\%apkname%
	)
	echo.
	echo Restore complete
	echo.
	echo Removing WhatsApp previous version temporary apk
	del tmp\%apkname% /s /q
)


:exit
echo.
echo Exiting ...
echo.
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
bin\adb.exe kill-server
pause
exit
