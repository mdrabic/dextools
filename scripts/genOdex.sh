#!/bin/bash

# gen_odex.sh
# Given a deodexed jar (a jar with classes.dex archived in it), generate the 
# appropriate optimized dex file. 
# 
# Assumptions: 
#	1. Shell has root access on the device
#	2. Busybox is installed and in the PATH on the device
#	3. ADB is in your system PATH
#
# Dependencies:
#	1. basename utility is installed (coreutils pkg)
#	2. dirname utility is installed (coreutils pkg)
#	
# Parameters: 
# 	$1 - Path to the deodexed jar file (ex. ~/Desktop/android.policy.jar)
#	$2 - Path of device Jar file (ex. /system/framework/android.policy.jar)

info () 
{ #Display the input params
	echo "Generate an odex given a deodexed jar"
	echo ""	
	echo "\$1 - Path to the deodexed jar file (ex. ~/Desktop/android.policy.jar)"
	echo "\$2 - Path of device Jar file (ex. /system/framework/android.policy.jar)"
	echo ""	
	echo " Assumptions: "
	echo "	1. Shell has root access on the device"
	echo "	2. ADB is in your system PATH"
	echo ""
	echo " Dependencies:"
	echo "	1. basename utility is installed (coreutils pkg)"
	echo "	2. dirname utility is installed (coreutils pkg)"
	echo ""	
}

if [ -z "$1" ]; then info; exit; fi
if [ -z "$2" ]; then info; exit; fi

#Check ADB is in $PATH
type -P "adb" || echo "[ERROR] ADB is not in PATH"; exit 1;

echo "[GENODEX] Get BOOTCLASSPATH"
bcp=$(adb shell echo \$BOOTCLASSPATH)

echo "[GENODEX] Checking for root"
out=$(adb shell id)

if grep -q "uid=0" <<< "$out" ; then
	echo "[GENODEX] Shell has root access"
else
	echo "[ERROR] Shell does not have root access"
	exit 1
fi

echo "[GENODEX] Remounting /system as R/W"
adb shell mount -o rw,remount system /system

echo "[GENODEX] Backing up files"
adb shell mkdir $(dirname $2)/backup
adb shell cp $2 $(dirname $2)/backup
adb shell cp $(dirname $2)/$(basename $1 .jar).odex $(dirname $2)/backup

echo "[GENODEX] Pushing deodexed Jar file"
adb push $1 $(dirname $2)

echo "[GENODEX] Pushing utilities"
adb push ./dexopt-wrapper /system/bin/
adb shell chmod 775 /system/bin/dexopt-wrapper
adb push ./dd /system/bin/
adb shell chmod 775 /system/bin/dd

echo "[GENODEX] Generating new odex"
adb shell dexopt-wrapper $2 $(dirname $2)/new_$(basename $1 .jar).odex $bcp

echo "[GENODEX] Copy signature into generated odex"
adb shell dd if=$(dirname $2)/$(basename $2 .jar).odex \
					 of=$(dirname $2)/new_$(basename $1 .jar).odex \
					 bs=1 count=20 skip=52 seek=52 conv=notrunc

echo "[GENODEX] Installing new odex file" 
adb shell cp -f $(dirname $2)/new_$(basename $1 .jar).odex \
				$(dirname $2)/$(basename $1 .jar).odex
adb shell cp -f $(dirname $2)/backup/$(basename $2) $2

echo "[GENODEX] Clean up"
adb shell rm $(dirname $2)/new_$(basename $1 .jar).odex
adb shell rm -r $(dirname $2)/backup

echo "[GENODEX] DONE!"

