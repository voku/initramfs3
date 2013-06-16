#!/bin/bash

MD5FILE="res/stweaks_md5";

md5sum res/misc/payload/STweaks.apk | awk '{print $1}' > $MD5FILE;
stat $MD5FILE || exit 1;
chmod 644 $MD5FILE;
cat $MD5FILE;

