#!/sbin/busybox sh

# Android logger, (logcat + dmesg)
if [ -e /lib/modules/logger.ko ]; then
	insmod /lib/modules/logger.ko
fi;

# Fm radio, I have no idea why it isn't loaded in init -gm
if [ -e /lib/modules/Si4709_driver.ko ]; then
	insmod /lib/modules/Si4709_driver.ko;
fi;

# Load CIFS with all that needed
if [ -e /lib/modules/cifs.ko ]; then
	insmod /lib/modules/cifs.ko;
fi;

# For ntfs automounting
if [ -e /lib/modules/fuse.ko ]; then
	insmod /lib/modules/fuse.ko;
fi;

# Enable KSM by default.
if [ -e /sys/kernel/mm/ksm/run ]; then
	echo "1" > /sys/kernel/mm/ksm/run;
fi;

