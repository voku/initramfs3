#!/sbin/busybox sh
# Logging
#/sbin/busybox cp /data/user.log /data/user.log.bak
/sbin/busybox rm /data/user.log
exec >>/data/user.log
exec 2>&1

mkdir /data/.siyah
chmod 777 /data/.siyah

ccxmlsum=`md5sum /res/customconfig/customconfig.xml | awk '{print $1}'`
if [ "a${ccxmlsum}" != "a`cat /data/.siyah/.ccxmlsum`" ]; then
	rm -f /data/.siyah/*.profile
	echo ${ccxmlsum} > /data/.siyah/.ccxmlsum
fi

# Reset profile in case i messed with it.
#md5battery=`md5sum /res/customconfig/battery.profile | awk '{print $1}'`
#if [ "a${md5battery}" != "a`cat /data/.siyah/.md5battery`" ]; then
#	rm -f /data/.siyah/battery.profile
#	echo ${md5battery} > /data/.siyah/.md5battery
#fi;

#md5default=`md5sum /res/customconfig/default.profile | awk '{print $1}'`
#if [ "a${md5default}" != "a`cat /data/.siyah/.md5default`" ]; then
#        rm -f /data/.siyah/default.profile
#        echo ${md5default} > /data/.siyah/.md5default
#fi;

#md5performance=`md5sum /res/customconfig/performance.profile | awk '{print $1}'`
#if [ "a${md5performance}" != "a`cat /data/.siyah/.md5performance`" ]; then
#        rm -f /data/.siyah/performance.profile
#        echo ${md5performance} > /data/.siyah/.md5performance
#fi;

[ ! -f /data/.siyah/default.profile ] && cp /res/customconfig/default.profile /data/.siyah
[ ! -f /data/.siyah/battery.profile ] && cp /res/customconfig/battery.profile /data/.siyah
[ ! -f /data/.siyah/performance.profile ] && cp /res/customconfig/performance.profile /data/.siyah

#For now static freq 1500->100
echo 1500 1400 1300 1200 1100 1000 900 800 700 600 500 400 300 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies

. /res/customconfig/customconfig-helper
read_defaults
read_config

#cpu undervolting
echo "${cpu_undervolting}" > /sys/devices/system/cpu/cpu0/cpufreq/vdd_levels

#change cpu step count
case "${cpustepcount}" in
	6)
    	echo 1200 1000 800 500 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
    	;;
  	7)
    	echo 1400 1200 1000 800 500 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
    	;;
  	8)
    	echo 1500 1400 1200 1000 800 500 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
    	;;
  	9)
    	echo 1500 1400 1200 1000 800 500 300 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
    	;;
  	15)
    	echo 1500 1400 1300 1200 1100 1000 900 800 700 600 500 400 300 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
    	;;
esac;

# disable debugging on some modules
if [ "$logger" == "off" ]; then
	echo 0 > /sys/module/ump/parameters/ump_debug_level
	echo 0 > /sys/module/mali/parameters/mali_debug_level
	echo 0 > /sys/module/kernel/parameters/initcall_debug
	echo 0 > /sys//module/lowmemorykiller/parameters/debug_level
	echo 0 > /sys/module/earlysuspend/parameters/debug_mask
	echo 0 > /sys/module/alarm/parameters/debug_mask
	echo 0 > /sys/module/alarm_dev/parameters/debug_mask
	echo 0 > /sys/module/binder/parameters/debug_mask
	echo 0 > /sys/module/xt_qtaguid/parameters/debug_mask
fi;

# run my modules
/sbin/busybox sh /sbin/ext/modules.sh

# enable kmem interface for everyone by GM
echo 0 > /proc/sys/kernel/kptr_restrict

# for ntfs automounting
mkdir /mnt/ntfs
mount -t tmpfs tmpfs /mnt/ntfs
chmod 777 /mnt/ntfs

/sbin/busybox sh /sbin/ext/properties.sh

(
/sbin/busybox sh /sbin/ext/install.sh
)&

/sbin/busybox mount -t rootfs -o remount,rw rootfs

##### Critical Permissions fix #####
chmod 666 /data/data/com.android.providers.*/databases/*
chmod 760 /data/system/inputmethod/ -R
chmod 777 /data/local/ -R
chmod 777 /sys/devices/system/cpu/ -R

##### Critical OWNER Permissions fix #####
(
/sbin/fix_permissions -l -v -f ApplicationsProvider.apk
/sbin/fix_permissions -l -v -f Bluetooth.apk
/sbin/fix_permissions -l -v -f Browser.apk
/sbin/fix_permissions -l -v -f Camera.apk
/sbin/fix_permissions -l -v -f Contacts.apk
/sbin/fix_permissions -l -v -f ContactsProvider.apk
/sbin/fix_permissions -l -v -f DrmProvider.apk
/sbin/fix_permissions -l -v -f GoogleContactsSyncAdapter.apk
/sbin/fix_permissions -l -v -f MediaProvider.apk
/sbin/fix_permissions -l -v -f Mms.apk
/sbin/fix_permissions -l -v -f NetworkLocation.apk
/sbin/fix_permissions -l -v -f PackageInstaller.apk
/sbin/fix_permissions -l -v -f Phone.apk
/sbin/fix_permissions -l -v -f Phonesky.apk
/sbin/fix_permissions -l -v -f ROMControl.apk
/sbin/fix_permissions -l -v -f Settings.apk
/sbin/fix_permissions -l -v -f SettingsProvider.apk
/sbin/fix_permissions -l -v -f SharedStorageBackup.apk
/sbin/fix_permissions -l -v -f Superuser.apk
/sbin/fix_permissions -l -v -f SystemUI.apk
/sbin/fix_permissions -l -v -f VpnDialogs.apk
/sbin/fix_permissions -l -v -f VoiceDialer.apk
chmod 666 /data/data/com.android.providers.*/databases/*
)&

#apply last soundgasm level on boot
/res/uci.sh soundgasm_hp $soundgasm_hp

##### Early-init phase tweaks #####
(
sleep 20
/sbin/busybox sh /sbin/ext/partitions-tune_on_init.sh
)&

##### EFS Backup #####
(
/sbin/busybox sh /sbin/ext/efs-backup.sh
)&

# Set color mode to user mode
echo "1" > /sys/devices/platform/samsung-pd.2/mdnie/mdnie/mdnie/user_mode

# Stop uci.sh from running all the PUSH Buttons in extweaks on boot!
/sbin/busybox mount -o remount,rw rootfs
/sbin/busybox chmod 755 /res/customconfig/actions/ -R
/sbin/busybox mv -f /res/customconfig/actions/push-actions/* /res/no-push-on-boot/

(
# apply ExTweaks defaults
# in case we forgot to set permissions, fix them.
/sbin/busybox chmod 755 /res/customconfig/actions/*
echo "booting" > /data/.siyah/booting
/res/uci.sh apply
echo "uci done" > /data/.siyah/uci_loaded
)&

(
while [ ! -e /data/.siyah/uci_loaded ]
do
	echo "Killing extweaks app proccess till all tweaks are loaded."
	pkill -f "com.darekxan.extweaks.app"
	sleep 5
	echo "waiting till UCI finish his work!"
done
# Restore all the PUSH Button Actions back to there location.
/sbin/busybox mount -o remount,rw rootfs
/sbin/busybox mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/
/sbin/busybox rm -f /data/.siyah/uci_loaded
/sbin/busybox rm -f /data/.siyah/booting
##### init scripts #####
/sbin/busybox sh /sbin/ext/run-init-scripts.sh
/sbin/busybox sh /sbin/ext/partitions-tune.sh 
)&

# Change USB mode MTP or Mass Storage
/res/customconfig/actions/usb-mode ${usb_mode}

PIDOFINIT=`pgrep -f "/sbin/ext/post-init.sh"`;
for i in $PIDOFINIT; do
	echo "-600" > /proc/$i/oom_score_adj;
done;

(
sleep 20
PIDOFACORE=`pgrep -f "android.process.acore"`;
for i in $PIDOFACORE; do
        echo "-600" > /proc/$i/oom_score_adj;
	cat /proc/$i/oom_score_adj
done;
)&

