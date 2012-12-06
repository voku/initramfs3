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
$BB mount -o remount,rw /data
$BB mount -o remount,rw /cache

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

# Start ROM VM boot!
sync;
start;

