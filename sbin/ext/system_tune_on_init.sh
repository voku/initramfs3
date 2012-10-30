#!/sbin/busybox sh

# stop ROM VM from booting!
stop;

# set busybox location
BB="/sbin/busybox";
FP="/sbin/fix_permissions";

# remount all partitions tweked settings
for k in $(busybox mount | busybox grep relatime | busybox cut -d " " -f3); do
	busybox mount -o remount,noatime,nodiratime,noauto_da_alloc,barrier=0 $k;
done;
for m in $(busybox mount | busybox grep ext[3-4] | busybox cut -d " " -f3); do
	busybox mount -o remount,noatime,nodiratime,noauto_da_alloc,barrier=0,commit=30,noauto_da_alloc,delalloc $m;
done;

$BB mount -o remount,rw,noatime,nodiratime,nodev,barrier=0,commit=360,noauto_da_alloc,delalloc /cache;
$BB mount -o remount,rw,noatime,nodiratime,nodev,barrier=0,commit=30,noauto_da_alloc,delalloc /data;
$BB mount -o remount,rw,noatime,nodiratime,barrier=0,commit=30,noauto_da_alloc,delalloc /system;

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

# for now static freq 1500->100
echo "1500 1400 1300 1200 1100 1000 900 800 700 600 500 400 300 200 100" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies;

# Start ROM VM boot!
sync;
start;

