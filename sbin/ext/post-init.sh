#!/sbin/busybox sh

BB="/sbin/busybox";

# first mod the partitions then boot
$BB sh /sbin/ext/system_tune_on_init.sh;

# start ADB early to see some logs :)
start adbd;

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
[ ! -f /data/.siyah/extreme_performance.profile ] && cp -a /res/customconfig/extreme_performance.profile /data/.siyah/;
[ ! -f /data/.siyah/extreme_battery.profile ] && cp -a /res/customconfig/extreme_battery.profile /data/.siyah/;

$BB chmod 0777 /data/.siyah/ -R;

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

(
	##### init.d scripts early, so my tweaks will fix the mess.#####
	$BB sh /sbin/ext/run-init-scripts.sh;
)&

# cpu undervolting
echo "$cpu_undervolting" > /sys/devices/system/cpu/cpu0/cpufreq/vdd_levels;

# change cpu step count
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

# disable IPv6 on all interfaces!
sysctl -w net.ipv6.conf.all.disable_ipv6=1

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

# sound reset on boot.
/res/uci.sh soundgasm_hp $soundgasm_hp;

# enable kmem interface for everyone by GM
echo "0" > /proc/sys/kernel/kptr_restrict;

(
	# Stop uci.sh from running all the PUSH Buttons in extweaks on boot!
	$BB mount -o remount,rw rootfs;
	$BB chmod 6755 /res/customconfig/actions/ -R;
	$BB chown root:system /res/customconfig/actions/ -R;
	$BB mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;

	# apply ExTweaks settings
	echo "booting" > /data/.siyah/booting;
	echo "1" > /sys/devices/platform/samsung-pd.2/mdnie/mdnie/mdnie/user_mode;
	pkill -f "com.darekxan.extweaks.app";
	$BB sh /res/uci.sh restore;

	# Restore all the PUSH Button Actions back to there location.
	$BB mount -o remount,rw rootfs;
	$BB mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
	pkill -f "com.darekxan.extweaks.app";
	$BB rm -f /data/.siyah/booting;
	# ==============================================================
	# EXTWEAKS FIXING
	# ==============================================================

	# apply volume tweaks. 
	echo "1" > /sys/devices/virtual/sound/sound_mc1n2/update_volume;

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

	# change USB mode MTP or Mass Storage
	/res/customconfig/actions/usb-mode ${usb_mode};
)&

(
	sleep 60;
	PIDOFACORE=`pgrep -f "android.process.acore"`;
	for i in $PIDOFACORE; do
		echo "-600" > /proc/${i}/oom_score_adj;
		renice -15 -p $i;
		$BB sh /sbin/ext/partitions-tune.sh;
	done;
)&

# little function to wait for sdcard mount and load to do some jobs that need sdcard mounted.
while [ ! -e /mnt/sdcard/android ]
do
	echo "waiting till sdcard is mounted and folder android exist";
	sleep 5;
done;

if [ $bootmenu_enabled == "1" ]; then
	if [ -e /sdcard/.nobootlogo ]; then
		rm -f /mnt/sdcard/.nobootlogo;
	fi;
fi;

echo "Done Booting" > /data/dm-boot-check;
date >> /data/dm-boot-check;

