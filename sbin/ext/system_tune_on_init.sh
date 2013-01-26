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
$BB chmod 400 /data/tombstones -R;
$BB chown drm:drm /data/tombstones -R;

# critical Permissions fix
$BB chmod 0777 /dev/cpuctl/ -R;
$BB chmod 0766 /data/anr/ -R;
$BB chmod 0777 /data/system/inputmethod/ -R;
$BB chmod 0777 /sys/devices/system/cpu/ -R;
$BB chown root:system /sys/devices/system/cpu/ -R;
$BB chmod 0777 /data/anr -R;
$BB chown system:system /data/anr -R;

# fixing sdcards
LOG_SDCARDS="/log-sdcards";
$BB echo "FIXING STORAGE" > $LOG_SDCARDS;

if [ -e /dev/block/mmcblk1p1 ]; then
	$BB echo "EXTERNAL SDCARD CHECK" >> $LOG_SDCARDS;
	$BB sh -c "/sbin/fsck_msdos -p -f /dev/block/mmcblk1p1" >> $LOG_SDCARDS;
else
	$BB echo "EXTERNAL SDCARD NOT EXIST" >> $LOG_SDCARDS;
fi;

$BB echo "INTERNAL SDCARD CHECK" >> $LOG_SDCARDS;
$BB sh -c "/sbin/fsck_msdos -p -f /dev/block/mmcblk0p11" >> $LOG_SDCARDS;
$BB echo "DONE" >> $LOG_SDCARDS;

# prevent from media storage to dig in clockworkmod backup dir
$BB mount -t vfat /dev/block/mmcblk1p1 /mnt/tmp && ( mkdir -p /mnt/tmp/clockworkmod/blobs/ ) && ( touch /mnt/tmp/clockworkmod/.nomedia ) && ( touch /mnt/tmp/clockworkmod/blobs/.nomedia );
sync;
$BB umount -l /mnt/tmp;

# Start ROM VM boot!
sync;
start;

