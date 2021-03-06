#!/bin/bash
echo What is your device name ?
read device_name;
echo What is your brand name ?
read brand_name;
VENDOR=$brand_name
DEVICE=$device_name

echo "Connect your device with ADB enabled"
adb wait-for-device
sleep 5
echo "Extracting vendor files..... (From your device with adb)"
sleep 2

BASE=../../../vendor/$VENDOR/$DEVICE/proprietary
rm -rf $BASE/*

for FILE in `egrep -v '(^#|^$)' proprietary-blobs.txt`; do
    OLDIFS=$IFS IFS=":" PARSING_ARRAY=($FILE) IFS=$OLDIFS
    FILE=${PARSING_ARRAY[0]}
    DEST=${PARSING_ARRAY[1]}
    if [ -z $DEST ]
    then
        DEST=$FILE
    fi
    DIR=`dirname $FILE`
    if [ ! -d $BASE/$DIR ]; then
        mkdir -p $BASE/$DIR
    fi

    if [ -z "$STOCK_ROM_DIR" ]; then
        adb pull /system/$FILE $BASE/$DEST
    else
        cp $STOCK_ROM_DIR/$FILE $BASE/$DEST
    fi

    # if file does not exist try destination
    if [ "$?" != "0" ]
    then
        adb pull /system/$DEST $BASE/$DEST
    fi
done

./setup-makefiles.sh
