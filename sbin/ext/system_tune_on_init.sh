#!/sbin/busybox sh

# stop ROM VM from booting!
stop;

# set busybox location
BB=/sbin/busybox

# remount all partitions tweked settings
for m in $($BB mount | grep ext[3-4] | cut -d " " -f3); do
	$BB mount -o remount,noatime,nodiratime,noauto_da_alloc,barrier=0 $m;
done;

$BB mount -o remount,rw,nosuid,nodev,discard,journal_async_commit /cache;
$BB mount -o remount,rw,nosuid,nodev,discard,journal_async_commit /data;
$BB mount -o remount,rw /system;

$BB mount -t rootfs -o remount,rw rootfs;

# cleaning
$BB rm -rf /cache/lost+found/* 2> /dev/null;
$BB rm -rf /data/lost+found/* 2> /dev/null;
$BB rm -rf /data/tombstones/* 2> /dev/null;
$BB rm -rf /data/anr/* 2> /dev/null;
$BB chmod -R 400 /data/tombstones;
$BB chown -R drm:drm /data/tombstones;

# critical Permissions fix
$BB chmod -R 0777 /dev/cpuctl/;
$BB chmod -R 0766 /data/anr/;
$BB chmod -R 0777 /data/system/inputmethod/;
$BB chmod -R 0777 /sys/devices/system/cpu/;
$BB chown -R root:system /sys/devices/system/cpu/;
$BB chmod -R 0777 /data/anr;
$BB chown -R system:system /data/anr;

MIUI_JB=0;
JELLY=0;
JBSAMMY=0;
CM_AOKP_10_JB=0;

[ "`$BB grep -i cMIUI /system/build.prop`" ] && MIUI_JB=1;
[ "`$BB grep -i ro.build.PDA=I9100XXLSJ /system/build.prop`" ] && JBSAMMY=1;
[ "`$BB grep -i ro.build.PDA=I9100XWLS8 /system/build.prop`" ] && JBSAMMY=1;
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
		$BB echo "EXTERNAL SDCARD CHECK" >> $LOG_SDCARDS;
		$BB sh -c "$FIX_BINARY -p -f /dev/block/mmcblk1p1" >> $LOG_SDCARDS;
	else
		$BB echo "EXTERNAL SDCARD NOT EXIST" >> $LOG_SDCARDS;
	fi;

	$BB echo "INTERNAL SDCARD CHECK" >> $LOG_SDCARDS;
	$BB sh -c "$FIX_BINARY -p -f /dev/block/mmcblk0p11" >> $LOG_SDCARDS;
	$BB echo "DONE" >> $LOG_SDCARDS;
}

if [ "$MIUI_JB" == "1" ] || [ "$JELLY" == "1" ] || [ "$JBSAMMY" == "1" ] || [ "$CM_AOKP_10_JB" == "1" ]; then
	SDCARD_FIX;
elif [ -e /system/bin/fsck_msdos ]; then
	FIX_BINARY=/system/bin/fsck_msdos
	SDCARD_FIX;
else
	$BB echo "CANT FIX SDCARDS, REPORT TO DM" > $LOG_SDCARDS;
fi;

# prevent from media storage to dig in clockworkmod backup dir
$BB mount -t vfat /dev/block/mmcblk1p1 /mnt/tmp && ( mkdir -p /mnt/tmp/clockworkmod/blobs/ ) && ( touch /mnt/tmp/clockworkmod/.nomedia ) && ( touch /mnt/tmp/clockworkmod/blobs/.nomedia );
sync;
$BB umount -l /mnt/tmp;

# Start ROM VM boot!
sync;
start;

