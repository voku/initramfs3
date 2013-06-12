#!/bin/bash

MD5FILE="res/SuperSU_md5";

md5sum res/misc/payload/SuperSU.apk | awk '{print $1}' > $MD5FILE;
stat $MD5FILE || exit 1;
chmod 644 $MD5FILE;
cat $MD5FILE;

