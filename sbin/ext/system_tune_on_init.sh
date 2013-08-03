#!/sbin/busybox sh

# stop ROM VM from booting!
stop;

# set busybox location
BB=/sbin/busybox

$BB chmod -R 777 /tmp/;
$BB chmod -R 6755 /sbin/ext/;

mount -o remount,rw,nosuid,nodev /cache;
mount -o remount,rw,nosuid,nodev /data;
mount -o remount,rw /;

# cleaning
$BB rm -rf /cache/lost+found/* 2> /dev/null;
$BB rm -rf /data/lost+found/* 2> /dev/null;
$BB rm -rf /data/tombstones/* 2> /dev/null;
$BB rm -rf /data/anr/* 2> /dev/null;
$BB chmod -R 400 /data/tombstones;

# critical Permissions fix
$BB chmod -R 0777 /dev/cpuctl/;
$BB chmod -R 0777 /data/system/inputmethod/;
$BB chown -R root:system /sys/devices/system/cpu/;
$BB chmod -R 0777 /sys/devices/system/cpu/;
$BB chown -R system:system /data/anr;
$BB chmod -R 0777 /data/anr/;
$BB chmod 744 /proc/cmdline;

MIUI_JB=0;
JELLY=0;
JBSAMMY=0;
CM_AOKP_10_JB=0;

[ "`$BB grep -i cMIUI /system/build.prop`" ] && MIUI_JB=1;
if [ `cat /tmp/sammy_rom` -eq "1" ]; then
	JBSAMMY=1;
fi;
JELLY=`$BB ls /system/lib/ssl/engines/libkeystore.so | wc -l`;
CM_AOKP_10_JB=`$BB ls /system/bin/wfd | wc -l`;

LOG_SDCARDS=/log-sdcards
FIX_BINARY=/sbin/fsck_msdos

SDCARD_FIX()
{
	# fixing sdcards
	$BB date > $LOG_SDCARDS;
	$BB echo "FIXING STORAGE" >> $LOG_SDCARDS;

	if [ -e /dev/block/mmcblk1p1 ]; then
		chmod 777 /proc/self/mounts;
		EXFAT_CHECK=`cat /proc/self/mounts | grep "/dev/block/mmcblk1p1" | wc -l`;
		if [ "$EXFAT_CHECK" -eq "1" ]; then
			if [ `cat /tmp/sammy_rom` -eq "0" ]; then
				$BB mount -t exfat /dev/block/mmcblk1p1 /storage/sdcard1;
			else
				$BB mount -t exfat /dev/block/mmcblk1p1 /storage/extSdCard;
			fi;
			$BB echo "EXTERNAL SDCARD CHECK" >> $LOG_SDCARDS;
			cp /sbin/libexfat_utils.so /system/lib/;
			/sbin/fsck.exfat -R /dev/block/mmcblk1p1 >> $LOG_SDCARDS;
			$BB sed -i "s/dev_mount sdcard1 */#dev_mount sdcard1 /g" /system/etc/vold.fstab;
		else
			$BB sed -i "s/#dev_mount sdcard1 */dev_mount sdcard1 /g" /system/etc/vold.fstab;
			$BB echo "EXTERNAL SDCARD CHECK" >> $LOG_SDCARDS;
			$BB sh -c "$FIX_BINARY -p -f /dev/block/mmcblk1p1" >> $LOG_SDCARDS;
		fi;
	else
		$BB echo "EXTERNAL SDCARD NOT EXIST" >> $LOG_SDCARDS;
	fi;

	$BB echo "INTERNAL SDCARD CHECK" >> $LOG_SDCARDS;
	$BB sh -c "$FIX_BINARY -p -f /dev/block/mmcblk0p11" >> $LOG_SDCARDS;
	$BB echo "DONE" >> $LOG_SDCARDS;
}

BOOT_ROM()
{
	# Start ROM VM boot!
	start;

	# start adb shell
	start adbd;
}

if [ -e /tmp/wrong_kernel ]; then
	mv /res/images/wrong_kernel.png /res/images/icon_clockwork.png;
	/sbin/choose_rom 0;
	sleep 15;
	sync;
	$BB rm -f /tmp/wrong_kernel;
	reboot;
else
	if [ -e /system/bin/fsck_msdos ]; then
		FIX_BINARY=/system/bin/fsck_msdos
		BOOT_ROM;
		SDCARD_FIX;
	else
		BOOT_ROM;
		SDCARD_FIX;
	fi;
fi;

