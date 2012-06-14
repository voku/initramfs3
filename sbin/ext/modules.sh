#!/sbin/busybox sh

#Fm radio, I have no idea why it isn't loaded in init -gm
if [ -e /system/lib/modules/Si4709_driver.ko ]; then
	insmod /system/lib/modules/Si4709_driver.ko;
fi;

# Load CIFS with all that needed
if [ -e /system/lib/modules/cifs.ko ]; then
	insmod /system/lib/modules/cifs.ko;
fi;

# For ntfs automounting
if [ -e /system/lib/modules/fuse.ko ]; then
	insmod /system/lib/modules/fuse.ko;
fi;

# Enable KSM by default.
if [ -e /sys/kernel/mm/ksm/run ]; then
	echo "1" > /sys/kernel/mm/ksm/run;
fi;

