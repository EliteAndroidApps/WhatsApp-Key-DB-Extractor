#!/usr/bin/env bash

tput bold;
tput setaf 2;
is_adb=1
[[ -z $(which adb) ]] && { is_adb=0; }
is_curl=1
[[ -z $(which curl) ]] && { is_curl=0; }
is_grep=1
[[ -z $(which grep) ]] && { is_grep=0; }
is_java=1
[[ -z $(which java) ]] && { is_java=0; }
is_tar=1
[[ -z $(which tar) ]] && { is_tar=0; }
is_tr=1
[[ -z $(which tr) ]] && { is_tr=0; }

echo -e "
=========================================================================
= This script will extract the WhatsApp Key file and DB on Android 4.0+ =
= You DO NOT need root for this to work but you DO need Java installed. =
= If your WhatsApp version is greater than 2.11.431 (most likely), then =
= a legacy version will be installed temporarily in order to get backup =
= permissions. You will NOT lose ANY data and your current version will =
= be restored at the end of the extraction process so try not to panic. =
= Script by: TripCode (Greets to all who visit: XDA Developers Forums). =
= Thanks to: dragomerlin for ABE and to Abinash Bishoyi for being cool. =
=         ###          Version: v4.7 (12/10/2016)          ###          =
=========================================================================
"
if (($is_adb == 0)); then
echo -e "\e[0;33m Error: adb is not installed - please install adb and run again!\e[0m"
elif (($is_curl == 0)); then
echo -e "\e[0;33m Error: curl is not installed - please install curl and run again!\e[0m"
elif (($is_grep == 0)); then
echo -e "\e[0;33m Error: grep is not installed - please install grep and run again!\e[0m"
elif (($is_java == 0)); then
echo -e "\e[0;33m Error: java is not installed - please install java and run again!\e[0m"
elif (($is_tar == 0)); then
echo -e "\e[0;33m Error: tar is not installed - please install tar and run again!\e[0m"
elif (($is_tr == 0)); then
echo -e "\e[0;33m Error: tr is not installed - please install tr and run again!\e[0m"
else
echo -e "\nPlease connect your Android device with USB Debugging enabled:\n"
adb kill-server
adb start-server
adb wait-for-device
sdkver=$(adb shell getprop ro.build.version.sdk | tr -d '[[:space:]]')
sdpath=$(adb shell "echo \$EXTERNAL_STORAGE/WhatsApp/Databases/.nomedia" | tr -d '[[:space:]]')
if [ $sdkver -le 13 ]; then
echo -e "\nUnsupported Android Version - this method only works on 4.0 or higher :/\n"
adb kill-server
else
apkpath=$(adb shell pm path com.whatsapp | grep package | tr -d '[[:space:]]')
version=$(adb shell dumpsys package com.whatsapp | grep versionName | tr -d '[[:space:]]')
apkflen=$(curl -sI http://www.cdn.whatsapp.net/android/2.11.431/WhatsApp.apk | grep Content-Length | grep -o '[0-9]*')
if [ $apkflen -eq 18329558 ]; then
apkfurl=http://www.cdn.whatsapp.net/android/2.11.431/WhatsApp.apk
else
apkfurl=http://whatcrypt.com/WhatsApp-2.11.431.apk
fi
apkname=$(basename  ${apkpath/package:/})
if [ ! -f tmp/LegacyWhatsApp.apk ]; then
echo -e "\nDownloading legacy WhatsApp 2.11.431 to local folder\n"
curl -o tmp/LegacyWhatsApp.apk $apkfurl
echo -e ""
else
echo -e "\nFound legacy WhatsApp 2.11.431 in local folder\n"
fi
if [ -z "$apkpath" ]; then
echo -e "\nWhatsApp is not installed on the target device\nExiting ..."
else
echo -e "WhatsApp ${version/versionName=/} installed\n"
if [ $sdkver -ge 11 ]; then
adb shell am force-stop com.whatsapp
else
adb shell am kill com.whatsapp
fi
echo -e "Backing up WhatsApp ${version/versionName=/}"
adb pull ${apkpath/package:/} tmp
echo -e "Backup complete\n"
if [ $sdkver -ge 23 ]; then
echo -e "Removing WhatsApp ${version/versionName=/} skipping data"
adb shell pm uninstall -k com.whatsapp
echo -e "Removal complete\n"
fi
echo -e "Installing legacy WhatsApp 2.11.431"
if [ $sdkver -ge 17 ]; then
adb install -r -d tmp/LegacyWhatsApp.apk
else
adb install -r tmp/LegacyWhatsApp.apk
fi
echo -e "Install complete\n"
if [ $sdkver -ge 23 ]; then
adb backup -f tmp/whatsapp.ab com.whatsapp
else
adb backup -f tmp/whatsapp.ab -noapk com.whatsapp
fi
if [ -f tmp/whatsapp.ab ]; then
echo -e "\nPlease enter your backup password (leave blank for none) and press Enter: "
read password
java -jar bin/abe.jar unpack tmp/whatsapp.ab tmp/whatsapp.tar $password
tar xvf tmp/whatsapp.tar -C tmp apps/com.whatsapp/f/key
tar xvf tmp/whatsapp.tar -C tmp apps/com.whatsapp/db/msgstore.db
tar xvf tmp/whatsapp.tar -C tmp apps/com.whatsapp/db/wa.db
tar xvf tmp/whatsapp.tar -C tmp apps/com.whatsapp/db/axolotl.db
tar xvf tmp/whatsapp.tar -C tmp apps/com.whatsapp/db/chatsettings.db
echo -e "\nSaving whatsapp.cryptkey ..."
cp tmp/apps/com.whatsapp/f/key extracted/whatsapp.cryptkey
echo -e "Saving msgstore.db ..."
cp tmp/apps/com.whatsapp/db/msgstore.db extracted/msgstore.db
echo -e "Saving wa.db ..."
cp tmp/apps/com.whatsapp/db/wa.db extracted/wa.db
echo -e "Saving axolotl.db ..."
cp tmp/apps/com.whatsapp/db/axolotl.db extracted/axolotl.db
echo -e "Saving chatsettings.db ..."
cp tmp/apps/com.whatsapp/db/chatsettings.db extracted/chatsettings.db
echo -e "\nPushing cipher key to: $sdpath"
adb push tmp/apps/com.whatsapp/f/key $sdpath
else
echo -e "Operation failed"
fi
if [ ! -f tmp/$apkname ]; then
echo -e "\nDownloading WhatsApp ${version/versionName=/} to local folder\n"
curl -o tmp/$apkname http://www.cdn.whatsapp.net/android/${version/versionName=/}/WhatsApp.apk
fi
echo -e "\nRestoring WhatsApp ${version/versionName=/}"
if [ $sdkver -ge 17 ]; then
adb install -r -d tmp/$apkname
else
adb install -r tmp/$apkname
fi
echo -e "Restore complete\n\nCleaning up temporary files ..."
rm tmp/whatsapp.ab
rm tmp/whatsapp.tar
rm -rf tmp/apps
rm tmp/$apkname
echo -e "Done\n\nOperation complete\n"
fi
fi
fi
adb kill-server
read -p "Please press Enter to quit..."
exit 0
