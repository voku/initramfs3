#!/sbin/busybox sh

BB=/sbin/busybox

# first mod the partitions then boot
$BB sh /sbin/ext/system_tune_on_init.sh;

PIDOFINIT=`pgrep -f "/sbin/ext/post-init.sh"`;
for i in $PIDOFINIT; do
	echo "-600" > /proc/$i/oom_score_adj;
done;

if [ ! -d /data/.siyah ]; then
	$BB mkdir -p /data/.siyah;
fi;

# reset config-backup-restore
if [ -f /data/.siyah/restore_running ]; then
	rm -f /data/.siyah/restore_running;
fi;

ccxmlsum=`md5sum /res/customconfig/customconfig.xml | awk '{print $1}'`
if [ "a$ccxmlsum" != "a`cat /data/.siyah/.ccxmlsum`" ]; then
	rm -f /data/.siyah/*.profile;
	echo "$ccxmlsum" > /data/.siyah/.ccxmlsum;
fi;

[ ! -f /data/.siyah/default.profile ] && cp -a /res/customconfig/default.profile /data/.siyah/default.profile;
[ ! -f /data/.siyah/battery.profile ] && cp -a /res/customconfig/battery.profile /data/.siyah/battery.profile;
[ ! -f /data/.siyah/performance.profile ] && cp -a /res/customconfig/performance.profile /data/.siyah/performance.profile;
[ ! -f /data/.siyah/extreme_performance.profile ] && cp -a /res/customconfig/extreme_performance.profile /data/.siyah/extreme_performance.profile;
[ ! -f /data/.siyah/extreme_battery.profile ] && cp -a /res/customconfig/extreme_battery.profile /data/.siyah/extreme_battery.profile;

$BB chmod -R 0777 /data/.siyah/;

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

# mdnie sharpness tweak
if [ "$mdniemod" == "on" ]; then
	. /sbin/ext/mdnie-sharpness-tweak.sh;
fi;

# dual core hotplug
echo "on" > /sys/devices/virtual/misc/second_core/hotplug_on;
echo "off" > /sys/devices/virtual/misc/second_core/second_core_on;

# oom and mem perm fix
$BB chmod 777 /sys/module/lowmemorykiller/parameters/cost;
$BB chmod 777 /proc/sys/vm/mmap_min_addr;

# some nice thing for dev
$BB ln -s /sys/devices/system/cpu/cpu0/cpufreq /cpufreq;
$BB ln -s /sys/devices/system/cpu/cpufreq/ /cpugov;

# Cortex parent should be ROOT/INIT and not STweaks
nohup /sbin/ext/cortexbrain-tune.sh; 

# create init.d folder if missing
if [ ! -d /system/etc/init.d ]; then
	mkdir /system/etc/init.d/
	$BB chmod -R 755 /system/etc/init.d/;
fi;

(
	PROFILE=`cat /data/.siyah/.active.profile`;
	. /data/.siyah/$PROFILE.profile;

	MIUI_JB=0;
	[ "`$BB grep -i cMIUI /system/build.prop`" ] && MIUI_JB=1;

	if [ $init_d == on ] || [ "$MIUI_JB" == 1 ]; then
		$BB sh /sbin/ext/run-init-scripts.sh;
	fi;
)&

# disable debugging on some modules
if [ "$logger" == "off" ]; then
	echo "0" > /sys/module/ump/parameters/ump_debug_level;
	echo "0" > /sys/module/mali/parameters/mali_debug_level;
	echo "0" > /sys/module/kernel/parameters/initcall_debug;
	echo "0" > /sys/module/lowmemorykiller/parameters/debug_level;
	echo "0" > /sys/module/earlysuspend/parameters/debug_mask;
	echo "0" > /sys/module/alarm/parameters/debug_mask;
	echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
	echo "0" > /sys/module/binder/parameters/debug_mask;
	echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;
fi;

######################################
# Loading Modules
######################################
$BB chmod -R 755 /lib;

(
	sleep 30;
	# order of modules load is important.
	$BB insmod /lib/modules/j4fs.ko;

	sleep 5;
	mount -t j4fs /dev/block/mmcblk0p4 /mnt/.lfs
	$BB insmod /lib/modules/Si4709_driver.ko;
	$BB insmod /lib/modules/usbserial.ko;
	$BB insmod /lib/modules/ftdi_sio.ko;
	$BB insmod /lib/modules/pl2303.ko;
	$BB insmod /lib/modules/usbnet.ko;
	$BB insmod /lib/modules/asix.ko;
	$BB insmod /lib/modules/cifs.ko;
)&

# disable cpuidle log
echo "0" > /sys/module/cpuidle_exynos4/parameters/log_en;

# for ntfs automounting
mkdir /mnt/ntfs;
$BB chmod -R 777 /mnt/ntfs/;
mount -t tmpfs -o mode=0777,gid=1000 tmpfs /mnt/ntfs

$BB sh /sbin/ext/properties.sh;

(
	$BB sh /sbin/ext/install.sh;
)&

# EFS Backup 
(
	$BB sh /sbin/ext/efs-backup.sh;
)&

# enable kmem interface for everyone by GM
echo "0" > /proc/sys/kernel/kptr_restrict;

(
	# Stop uci.sh from running all the PUSH Buttons in stweaks on boot.
	$BB mount -o remount,rw rootfs;
	$BB chown -R root:system /res/customconfig/actions/;
	$BB chmod 6755 /res/customconfig/actions/*;
	$BB mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
	$BB chmod 6755 /res/no-push-on-boot/*;

	# set root access script.
	$BB chmod 6755 /sbin/ext/cortexbrain-tune.sh;

	# apply STweaks settings
	echo "booting" > /data/.siyah/booting;
	echo "1" > /sys/devices/platform/samsung-pd.2/mdnie/mdnie/mdnie/user_mode;
	pkill -f "com.gokhanmoral.stweaks.app";
	$BB sh /res/uci.sh restore;

	# restore all the PUSH Button Actions back to there location
	$BB mount -o remount,rw rootfs;
	$BB mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
	pkill -f "com.gokhanmoral.stweaks.app";
	$BB rm -f /data/.siyah/booting;

	# Temp fix for sound bug at JB Sammy ROMS.
	JB_ROM=`cat /tmp/jbsammy_installed`;
	if [ "$JB_ROM" == "1" ]; then
		$BB sh /res/uci.sh generic /sys/module/cpuidle_exynos4/parameters/enable_mask 1;
		$BB sh /res/uci.sh generic_cortex /tmp/enable_mask_sleep 1;
	fi;
	echo "0" > /tmp/jbsammy_installed;

	# change USB mode MTP or Mass Storage
	$BB sh /res/uci.sh usb-mode ${usb_mode};
)&

(
	# ###############################################################
	# JB Low Sound Fix.
	# ###############################################################

	sleep 50;
	# JB Sound Bug fix, 3 push VOL DOWN, 4 push VOL UP. and sound is fixed.
	MIUI_JB=0;
	JELLY=0;
	[ "`$BB grep -i cMIUI /system/build.prop`" ] && MIUI_JB=1;
	[ -f /system/lib/ssl/engines/libkeystore.so ] && JELLY=1;
	if [ "$JELLY" == "1" ] || [ "$MIUI_JB" == "1" ]; then
		if [ "$jb_sound_fix" == "on" ]; then
			input keyevent 25
			input keyevent 25
			input keyevent 25
			input keyevent 24
			input keyevent 24
			input keyevent 24
			input keyevent 24
		fi;
	fi;
)&

(
	while [ "`cat /proc/loadavg | cut -c1`" -ge "3" ]; do
		echo "Waiting For CPU to cool down";
		sleep 30;
	done;

	PIDOFACORE=`pgrep -f "android.process.acore"`;
	for i in $PIDOFACORE; do
		echo "-800" > /proc/${i}/oom_score_adj;
		renice -15 -p $i;
		log -p i -t boot "*** do not kill -> android.process.acore ***";
	done;

	# run partitions tune after full boot
	/sbin/ext/partitions-tune.sh

	echo "Done Booting" > /data/dm-boot-check;
	date >> /data/dm-boot-check;
)&

