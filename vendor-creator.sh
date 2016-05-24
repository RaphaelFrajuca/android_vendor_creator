#!/usr/bin/env bash

# Copyright (C) 2016 Raphael Carneiro Frajuca and Sumit Rajdev
#
# This script auto-generates the lists of proprietary blobs necessary to build
# the All ROM`s Project code for a variety of hardware targets.

# It needs to be run from the root of a source tree
# runs builds with and without the vendor tree, and uses the difference
# to generate the lists.

# WARNING: It destroys the source tree. Don't leave anything precious there.

# Caveat: this script does many full builds (2 per device). It takes a while
# to run. It's best # suited for overnight runs on multi-CPU machines
# with a lot of RAM.

echo 
echo
echo "This script compile Android two times for compare files and make vendor blobs"
sleep 3
echo "Connect your device in ADB mode and wait 10 seconds"
adb wait-for-device
echo                                                        
echo "Remain with the device connected to the end of the process"
sleep 5

echo What is your device codename ?
read device_codename; 
echo What is your brand/manufacturer name ?
read brand_name;
sleep 3
echo "How many jobs do you want? (Recommended 4)"
read cores_number;
sleep 3
echo "Copying the necessary files to your tree..."
sleep 5
echo "Your tree is for which ROM? (Example: aokp, cm, aosp, carbon, etc. "cm"_kyleveub, "carbon"_kyleveub, "aokp"_kyleveub, .....)"
read android_rom;
sleep 3
echo "Which version of Android?(Example: 4.4.4, 4.1.2, 4.2.2, 5.0, 5.1, 6.0, 6.1"
read android_version;
sleep 3
echo "This build is for ? (userdebug,user,eng)"
read rom_type;
DEVICE=$device_codename
BRAND_MANUFACTURER_NAME=$brand_name
NUMBER_OF_CORES=$cores_number
DEVICE_TREE_LOCATION=device/$brand_name/$device_codename
ANDROID_ROM=$android_rom
ROM_TYPE=$rom_type
ANDROID_VERSION=$android_version
SCRIPT_VER=STABLE-2

echo Configs:
 echo DEVICE =$DEVICE
 echo BRAND MANUFACTURER NAME =$BRAND_MANUFACTURER_NAME
 echo NUMBER OF CORES =$NUMBER_OF_CORES
 echo DEVICE TREE LOCATION =$DEVICE_TREE_LOCATION
 echo SCRIPT VERSION =$SCRIPT_VER
 echo ANDROID ROM =$ANDROID_ROM
 echo ANDROID VERSION =$ANDROID_VERSION
 echo BUILD TYPE =$ROM_TYPE
sleep 10
if true
then
 cp setup-makefiles.sh device/$brand_name/$device_codename
 cp extract-files.sh device/$brand_name/$device_codename
fi
echo "Starting Process... It can take a long time"
sleep 4

export LC_ALL=C

ARCHIVEDIR=data
if test -d archive-ref
then
  cp -R archive-ref $ARCHIVEDIR
else
  mkdir $ARCHIVEDIR

  . build/envsetup.sh
  for DEVICENAME in $DEVICE
  do
    if test $DEVICENAME = maguro
    then
      lunch yakju-$ROM_TYPE
      make -j$NUMBER_OF_CORES -i bacon
    fi
    if test $DEVICENAME = toro
    then
      lunch mysid-$ROM_TYPE
      make -j$NUMBER_OF_CORES -i bacon
    fi
    echo Starting First Compilation 
    sleep 5
    lunch $ANDROID_ROM"_"$DEVICENAME-$ROM_TYPE
    make bacon -i -j$NUMBER_OF_CORES
    cat out/target/product/$DEVICENAME/installed-files.txt |
      cut -b 23- |
      sort -f > $ARCHIVEDIR/$DEVICENAME-with.txt
  done
  echo Wiping old vendor and other files
  sleep 3
  rm -rf vendor/$brand_name
  rm -rf hardware/qcom/gps
  rm -rf out/target/product/$DEVICENAME/system
  for DEVICENAME in $DEVICE
  do
  echo Starting Second Compilation
    lunch $ANDROID_ROM"_"$DEVICENAME-$ROM_TYPE
    make bacon -i -j$NUMBER_OF_CORES
    cat out/target/product/$DEVICENAME/installed-files.txt |
      cut -b 23- |
      sort -f > $ARCHIVEDIR/$DEVICENAME-without.txt
  done
fi

for DEVICENAME in $DEVICE
do
  if test $brand_name
  then
    (
      echo '# Copyright (C) 2016 Raphael Carneiro Frajuca and Sumit Rajdev'
      echo '# This file is generated by vendor-creator.sh - DO NOT EDIT'
      echo
      diff $ARCHIVEDIR/$DEVICENAME-without.txt $ARCHIVEDIR/$DEVICENAME-with.txt |
        grep -v '\.odex$' |
        grep '>' |
        cut -b 3-
    ) > $ARCHIVEDIR/$DEVICENAME-proprietary-blobs.txt
    cp $ARCHIVEDIR/$DEVICENAME-proprietary-blobs.txt device/$BRAND_MANUFACTURER_NAME/$DEVICENAME/proprietary-blobs.txt

if true
then
mkdir vendor/$BRAND_MANUFACTURER_NAME/$DEVICENAME
cd device/$BRAND_MANUFACTURER_NAME/$DEVICENAME
chmod a+x setup-makefiles.sh
chmod a+x extract-files.sh
./extract-files.sh
fi

if false
then
echo "Maybe some error may have occurred :("
fi
if true
then
echo Sucess!! Vendor tree for $DEVICENAME is created
sleep 3
echo "Script edited by RaphaelFrajuca (www.github.com/RaphaelFrajuca)"
sleep 3
echo Credits: Cyanogenmod Team, Android Open Source Project, RaphaelFrajuca and Grace5921
sleep 3
fi
echo Other Utilities ? yes or no
read other_utilities;
case $other_utilities in
   “yes”)
echo Other Utilities:
 echo
 echo "1-Run make clean"
 echo "2-Delete all script files"
 echo "3-Delete all vendor files"
 echo "4-Build ROM for $DEVICENAME"
 echo "5-Contact Support"
 echo "6-Exit"
read other_select;
     ;;
    “no”)
exit
case $other_select in 
   “1”)
   make clean
sleep 5
      ;;
   “2”)
   rm extract-files.sh
   rm setup-makefiles.sh
   rm vendor-creator.sh
   rm device/$BRAND_MANUFACTURER_NAME/$DEVICENAME/extract-files.sh
   rm device/$BRAND_MANUFACTURER_NAME/$DEVICENAME/setup-makefiles.sh
   rm device/$BRAND_MANUFACTURER_NAME/$DEVICENAME/proprietary-blobs.txt
sleep 5
      ;;
   “3”)
   rm -rf vendor/$BRAND_MANUFACTURER_NAME
sleep 5
      ;;
   “4”)
  lunch $ANDROID_ROM"_"$DEVICENAME-$ROM_TYPE
  make bacon -i -j$NUMBER_OF_CORES
  echo Build suceffuly ;)
      ;;
   “5”)
echo Hangouts: olocogameplays552@gmail.com
echo
echo Whatsapp: +5511949597274
echo
echo Telegram: +5511988415002
echo
echo Facebook: https://www.facebook.com/raphael.frajuca
sleep 5
   “6”)
  echo Ok, Bye Bye ;) 
  exit
  ;;
esac
esac



