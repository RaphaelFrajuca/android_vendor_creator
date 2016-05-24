#!/usr/bin/env bash

# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script auto-generates the lists of proprietary blobs necessary to build
# the Android Open-Source Project code for a variety of hardware targets.

# It needs to be run from the root of a source tree that can repo sync,
# runs builds with and without the vendor tree, and uses the difference
# to generate the lists.

# It can optionally upload the results to a Gerrit server for review.

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
sleep 10
echo "remain with the device connected to the end of the process"
sleep 3

echo What is your device codename ?
read device_codename; 
echo What is your brand/manufacturer name ?
read brand_name;
sleep 3
echo "How many jobs do you want? (Recommended 4)"
read jobs_number;
sleep 3
echo "Copying the necessary files to your tree..."
sleep 5
echo "Your tree is for ROM? (Example: aokp, cm, aosp, carbon, etc. "cm"_kyleveub, "carbon"_kyleveub, "aokp"_kyleveub, .....)"
read android_rom;
sleep 3
echo "Which version of Android?(Example: 4.4.4, 4.1.2, 4.2.2, 5.0, 5.1, 6.0, 6.1"
read android_version;
sleep 3
DEVICE=$device_codename
BRAND_MANUFACTURER_NAME=$brand_name
JOBS_NUNBER=$jobs_number
DEVICE_TREE_LOCATION=device/$brand_name/$device_codename
ANDROID_ROM=$android_rom
ANDROID_VERSION=$android_version
SCRIPT_VER=BETA-5
echo Configs:
 echo DEVICE = $DEVICE
 echo BRAND MANUFACTURER NAME = $BRAND_MANUFACTURER_NAME
 echo JOBS NUMBER = $JOBS_NUNBER
 echo DEVICE TREE LOCATION = $DEVICE_TREE_LOCATION
 echo SCRIPT VERSION = $SCRIPT_VER
 echo ANDROID ROM = $ANDROID_ROM
 echo ANDROID VERSION = $ANDROID_VERSION
sleep 7
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
      lunch yakju-user
      make -j$JOBS_NUNBER -i bacon
    fi
    if test $DEVICENAME = toro
    then
      lunch mysid-user
      make -j$JOBS_NUNBER -i bacon
    fi
    echo Starting First Compilation 
    sleep 5
    lunch $ANDROID_ROM"_"$DEVICENAME-userdebug
    make bacon -i -j$JOBS_NUNBER
    cat out/target/product/$DEVICENAME/installed-files.txt |
      cut -b 16- |
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
    lunch $ANDROID_ROM"_"$DEVICENAME-userdebug
    make bacon -i -j$JOBS_NUNBER
    cat out/target/product/$DEVICENAME/installed-files.txt |
      cut -b 16- |
      sort -f > $ARCHIVEDIR/$DEVICENAME-without.txt
  done
fi

for DEVICENAME in $DEVICE
do
  if test $brand_name
  then
    (
      echo '# Copyright (C) 2011 The Android Open Source Project'
      echo '#'
      echo '# Licensed under the Apache License, Version 2.0 (the "License");'
      echo '# you may not use this file except in compliance with the License.'
      echo '# You may obtain a copy of the License at'
      echo '#'
      echo '#      http://www.apache.org/licenses/LICENSE-2.0'
      echo '#'
      echo '# Unless required by applicable law or agreed to in writing, software'
      echo '# distributed under the License is distributed on an "AS IS" BASIS,'
      echo '# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.'
      echo '# See the License for the specific language governing permissions and'
      echo '# limitations under the License.'
      echo
      echo '# This file is generated by vendor-creator.sh - DO NOT EDIT'
      echo
      diff $ARCHIVEDIR/$DEVICENAME-without.txt $ARCHIVEDIR/$DEVICENAME-with.txt |
        grep -v '\.odex$' |
        grep '>' |
        cut -b 3-
    ) > $ARCHIVEDIR/$DEVICENAME-proprietary-blobs.txt
    cp $ARCHIVEDIR/$DEVICENAME-proprietary-blobs.txt device/$BRAND_MANUFACTURER_NAME/$DEVICENAME/proprietary-blobs.txt

    (
      cd device/$BRAND_MANUFACTURER_NAME/$DEVICENAME
      git add .
      git commit -m "$(echo -e 'auto-generated blob list\n\nBug: 4295425')"
      if test "$1" != "" -a "$2" != ""
      then
        echo uploading to server $1 branch $2
        git push ssh://$1:29418/device/$BRAND_MANUFACTURER_NAME/$DEVICENAME.git HEAD:refs/for/$2/autoblobs
      fi
    )
  else
    (
      cd device/$BRAND_MANUFACTURER_NAME/$DEVICENAME
      git commit --allow-empty -m "$(echo -e 'DO NOT SUBMIT - BROKEN BUILD\n\nBug: 4295425')"
      if test "$1" != "" -a "$2" != ""
      then
        echo uploading to server $1 branch $2
        git push ssh://$1:29418/device/$BRAND_MANUFACTURER_NAME/$DEVICENAME.git HEAD:refs/for/$2/autoblobs
      fi
    )
  fi
done

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
echo Credits: Cyanogenmod Team, Android Open Source Project and RaphaelFrajuca
sleep 3
exit
fi


