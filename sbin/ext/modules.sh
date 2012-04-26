#!/sbin/busybox sh

# reduce logcat priority.
renice 10 `pgrep logcat`
#fm radio, I have no idea why it isn't loaded in init -gm
if [ -e /system/lib/modules/Si4709_driver.ko ]; then
insmod /system/lib/modules/Si4709_driver.ko
fi
# for ntfs automounting
if [ -e /system/lib/modules/fuse.ko ]; then
insmod /system/lib/modules/fuse.ko
fi
# Load CIFS with all that needed
if [ -e /system/lib/modules/cifs.ko ]; then
insmod /system/lib/modules/cifs.ko
fi
# for ntfs automounting
if [ -e /system/lib/modules/fuse.ko ]; then
insmod /system/lib/modules/fuse.ko
fi
# For ZRAM auto load
# insmod /lib/modules/zram.ko num_devices=3 (loading at kernel init.)
# Now we load the ZRAM as RAM SWAP and gain 150MB more compressed RAM.
# ZRAM compress ratio is 50% so 300MB will give clean 150MB More RAM, this gives us 1GB RAM device. 
#
# 1 == 0 => off 
if [[ -e /dev/block/zram0 && 1 == 0 ]]; then
	# Setting swappines
	echo 60 > /proc/sys/vm/swappiness 
	# Setting size of each ZRAM swap drives
	echo 100000000 > /sys/block/zram0/disksize
	echo 100000000 > /sys/block/zram1/disksize
	echo 100000000 > /sys/block/zram2/disksize
	# Creating SWAPS from ZRAM drives
	mkswap /dev/block/zram0 >/dev/null
	mkswap /dev/block/zram1 >/dev/null
	mkswap /dev/block/zram2 >/dev/null
	# Activating ZRAM swaps with the same priority to load balance ram swapping (need advanced busybox with swapon -p flag)
	swapon /dev/block/zram0 -p 20 >/dev/null 2>&1
	swapon /dev/block/zram1 -p 20 >/dev/null 2>&1
	swapon /dev/block/zram2 -p 20 >/dev/null 2>&1
	# Show to user that swap is ON
	free
fi

