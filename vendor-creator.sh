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

# Syntax: vendor-creator.sh -f|--force [<server> <branch>]
#
# If the server and branch paramters are both present, the script will upload
# new files (if there's been any change) to the mentioned Gerrit server,
# in the specified branch.

if test "$1" != "-f" -a "$1" != "--force"
then
  echo This script must be run with the --force option
  exit 1
fi
shift

echo "This script compile Android two times for compare files and make vendor blobs"
echo "Script BETA-2 version"
sleep 3
echo "Connect your device in ADB mode and wait"
sleep 10
echo "remain with the device connected to the end of the process"
sleep 3

echo What is your device codename ?
read device_codename; 
echo What is your brand name ?
read brand_name;
sleep 2
echo Put setup-makefiles.sh and extract-files.sh "in" device"/"$MANUFACTURENAME"/"$DEVICES 
sleep 3
echo "Copying the necessary files to your tree..."
sleep 5
if test $DEVICES
then
 cp setup-makefiles.sh device/$MANUFACTURENAME/$DEVICES
 cp extract-files.sh device/$MANUFACTURENAME/$DEVICES
fi
echo "Starting Process... It can take a long time"

DEVICES="$device_codename"
export LC_ALL=C

ARCHIVEDIR=archive-$(date +%s)
if test -d archive-ref
then
  cp -R archive-ref $ARCHIVEDIR
else
  mkdir $ARCHIVEDIR

  . build/envsetup.sh
  for DEVICENAME in $DEVICES
  do
    if test $DEVICENAME = maguro
    then
      lunch yakju-user
      make -j4 bacon
    fi
    if test $DEVICENAME = toro
    then
      lunch mysid-user
      make -j4 bacon
    fi
    lunch cm_$DEVICENAME-userdebug
    make bacon -j4
    cat out/target/product/$DEVICENAME/installed-files.txt |
      cut -b 15- |
      sort -f > $ARCHIVEDIR/$DEVICENAME-with.txt
  done
  for DEVICENAME in $DEVICES
  do
    lunch cm_$DEVICENAME-userdebug
    make bacon -j4
    cat out/target/product/$DEVICENAME/installed-files.txt |
      cut -b 15- |
      sort -f > $ARCHIVEDIR/$DEVICENAME-without.txt
  done
fi

for DEVICENAME in $DEVICES
do
  MANUFACTURERNAME=$brand_name
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
    cp $ARCHIVEDIR/$DEVICENAME-proprietary-blobs.txt device/$MANUFACTURERNAME/$DEVICENAME/proprietary-blobs.txt

    (
      cd device/$MANUFACTURERNAME/$DEVICENAME
      git add .
      git commit -m "$(echo -e 'auto-generated blob list\n\nBug: 4295425')"
      if test "$1" != "" -a "$2" != ""
      then
        echo uploading to server $1 branch $2
        git push ssh://$1:29418/device/$MANUFACTURERNAME/$DEVICENAME.git HEAD:refs/for/$2/autoblobs
      fi
    )
  else
    (
      cd device/$MANUFACTURERNAME/$DEVICENAME
      git commit --allow-empty -m "$(echo -e 'DO NOT SUBMIT - BROKEN BUILD\n\nBug: 4295425')"
      if test "$1" != "" -a "$2" != ""
      then
        echo uploading to server $1 branch $2
        git push ssh://$1:29418/device/$MANUFACTURERNAME/$DEVICENAME.git HEAD:refs/for/$2/autoblobs
      fi
    )
  fi
done

if true
then
cd device/$MANUFACTURERNAME/$DEVICENAME
./setup-makefiles.sh
fi

if true
then
echo Sucess!! Vendor tree for $DEVICENAME is created
echo "Script edited by RaphaelFrajuca (www.github.com/RaphaelFrajuca)"
echo Credits: Cyanogenmod Team, Android Open Source Project and RaphaelFrajuca
fi


