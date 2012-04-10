#!/sbin/busybox sh

mkdir /data/.siyah
chmod 777 /data/.siyah
[ ! -f /data/.siyah/default.profile ] && cp /res/customconfig/default.profile /data/.siyah
[ ! -f /data/.siyah/battery.profile ] && cp /res/customconfig/battery.profile /data/.siyah
[ ! -f /data/.siyah/performance.profile ] && cp /res/customconfig/performance.profile /data/.siyah


. /res/customconfig/customconfig-helper
read_defaults
read_config

# We need logs. no logs no Android simple debuging.
insmod /lib/modules/logger.ko
renice 10 `pgrep logcat`
#fm radio, I have no idea why it isn't loaded in init -gm
insmod /lib/modules/Si4709_driver.ko
# for ntfs automounting
insmod /lib/modules/fuse.ko
# For ZRAM auto load
insmod /lib/modules/zram.ko num_devices=3

