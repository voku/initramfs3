#!/bin/bash
md5sum res/misc/payload/SuperSU.apk | awk '{print $1}' > res/SuperSU_md5;
chmod 644 res/SuperSU_md5;
cat res/SuperSU_md5;

