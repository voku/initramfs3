#!/sbin/busybox sh

# remount all partitions with noatime, nodiratime
for k in $(/sbin/busybox mount | /sbin/busybox grep relatime | /sbin/busybox grep -v /acct | /sbin/busybox grep -v /dev/cpuctl | cut -d " " -f3); do
        /sbin/busybox mount -o remount,noatime,nodiratime $k;
done;

# remount ext4 partitions with optimizations
for k in $(/sbin/busybox mount | /sbin/busybox grep ext4 | /sbin/busybox cut -d " " -f3); do
        /sbin/busybox mount -o remount,noatime,nodiratime,commit=30 $k
done;

