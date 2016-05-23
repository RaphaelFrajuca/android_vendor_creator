# android_vendor_creator
BETA-1 vendor blobs creator (for Cyanogenmod only)

## How to Create ?

1º Edit vendor-creator.sh and put your device codename in `DEVICES=""`
Ex:`DEVICES="kyleveub"`

2º Put vendor-creator.sh in root Cyanogenmod source

3º Go to your Cyanogenmod source and paste this code in terminal `./vendor-creator.sh --force`

4º After Compile ends go to your device tree home and run `./extract-files.sh` and wait to finish process

5º After process ends your new vendor is in `<your-source-name>/vendor/<brand>/<codename>`

ENJOY !!!
