#!/sbin/busybox sh

BB="/sbin/busybox";

# first mod the partitions then boot
$BB sh /sbin/ext/system_tune_on_init.sh;

PIDOFINIT=`pgrep -f "/sbin/ext/post-init.sh"`;
for i in $PIDOFINIT; do
	echo "-600" > /proc/$i/oom_score_adj;
done;

if [ ! -d /data/.siyah ]; then
	$BB mkdir -p /data/.siyah;
fi;

ccxmlsum=`md5sum /res/customconfig/customconfig.xml | awk '{print $1}'`
if [ "a$ccxmlsum" != "a`cat /data/.siyah/.ccxmlsum`" ]; then
	rm -f /data/.siyah/*.profile;
	echo "$ccxmlsum" > /data/.siyah/.ccxmlsum;
fi;

[ ! -f /data/.siyah/default.profile ] && cp -a /res/customconfig/default.profile /data/.siyah/;
[ ! -f /data/.siyah/battery.profile ] && cp -a /res/customconfig/battery.profile /data/.siyah/;
[ ! -f /data/.siyah/performance.profile ] && cp -a /res/customconfig/performance.profile /data/.siyah/;

$BB chmod 0777 /data/.siyah/ -R;

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

#cpu undervolting
echo "$cpu_undervolting" > /sys/devices/system/cpu/cpu0/cpufreq/vdd_levels;

#change cpu step count
case "${cpustepcount}" in
	6)
		echo "1200 1000 800 500 200 100" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies;
	;;
	7)
		echo "1400 1200 1000 800 500 200 100" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies;
	;;
	8)
		echo "1500 1400 1200 1000 800 500 200 100" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies;
	;;
	9)
		echo "1500 1400 1200 1000 800 500 300 200 100" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies;
	;;
	15)
		echo "15 levels already set by default";
	;;
esac;

# disable debugging on some modules
if [ "$logger" == "off" ]; then
	echo "0" > /sys/module/ump/parameters/ump_debug_level;
	echo "0" > /sys/module/mali/parameters/mali_debug_level;
	echo "0" > /sys/module/kernel/parameters/initcall_debug;
	echo "0" > /sys//module/lowmemorykiller/parameters/debug_level;
	echo "0" > /sys/module/earlysuspend/parameters/debug_mask;
	echo "0" > /sys/module/alarm/parameters/debug_mask;
	echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
	echo "0" > /sys/module/binder/parameters/debug_mask;
	echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;
fi;

# for ntfs automounting
mkdir /mnt/ntfs;
mount -t tmpfs tmpfs /mnt/ntfs;
chmod 777 /mnt/ntfs/ -R;

$BB sh /sbin/ext/properties.sh;

(
	$BB sh /sbin/ext/install.sh;
)&

# EFS Backup 
(
	$BB sh /sbin/ext/efs-backup.sh;
)&

# Stop uci.sh from running all the PUSH Buttons in extweaks on boot!
$BB mount -o remount,rw rootfs;
$BB chmod 755 /res/customconfig/actions/ -R;
$BB mv -f /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;

(
	# apply ExTweaks settings
	echo "booting" > /data/.siyah/booting;
	$BB sh /res/uci.sh restore;
	echo "uci done" > /data/.siyah/uci_loaded;
)&

(
	while [ ! -e /data/.siyah/uci_loaded ]
	do
		echo "Killing extweaks app proccess till all tweaks are loaded.";
		pkill -f "com.darekxan.extweaks.app";
		sleep 5;
		echo "Waiting till UCI finish his work!";
	done

	# Restore all the PUSH Button Actions back to there location.
	$BB mount -o remount,rw rootfs;
	$BB mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
	$BB rm -f /data/.siyah/uci_loaded;
	$BB rm -f /data/.siyah/booting;
	# root for root_install
	$BB chmod +s /res/customconfig/actions/push-actions/root_*;
	$BB chown root:root /res/customconfig/actions/push-actions/root_*;
	# ==============================================================
	# EXTWEAKS FIXING
	# ==============================================================

	# apply BLN mods, that get changed by ROM on boot.
	if [ $enabled == "off" ]; then
		echo "0" > /sys/class/misc/backlightnotification/enabled;
		echo "0" > /sys/class/misc/backlightnotification/blinking_enabled;
		echo "0" > /sys/class/misc/backlightnotification/breathing_enabled;
	else
		/res/customconfig/actions/bln_switch bln_switch $bln_switch
	fi;

	# apply touch led time out and led on touch, this is done if changed by ROM.
	/res/customconfig/actions/led_timeout led_timeout $led_timeout;
	##### init scripts #####
	$BB sh /sbin/ext/run-init-scripts.sh;
)&

# change USB mode MTP or Mass Storage
/res/customconfig/actions/usb-mode ${usb_mode};

# set free permission to all system DB. so apps can write there. less problem with perms. and FC
chmod 0777 /data/data/com.android.providers.*/databases/*;

(
	sleep 60;
	PIDOFACORE=`pgrep -f "android.process.acore"`;
	for i in $PIDOFACORE; do
		echo "-600" > /proc/${i}/oom_score_adj;
		renice $i -15;
		$BB sh /sbin/ext/partitions-tune.sh;
	done;
)&

echo "Done Booting" > /data/dm-boot-check;
date >> /data/dm-boot-check;

