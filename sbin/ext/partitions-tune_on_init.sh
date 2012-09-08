#!/sbin/busybox sh

# stop ROM VM from booting!
stop

# remount all partitions tweked settings.
/sbin/busybox mount -o remount,rw,nodev,barrier=0,commit=360,noauto_da_alloc,delalloc /cache;

/sbin/busybox mount -o remount,rw,nodev,barrier=0,commit=30,noauto_da_alloc,delalloc /data;

/sbin/busybox mount -o remount,rw,barrier=0,commit=30,noauto_da_alloc,delalloc /system;

/sbin/busybox mount -o remount,rw,barrier=0,commit=30,noauto_da_alloc,delalloc /preload;

# set critical dalvik permissions.
/sbin/busybox chmod 777 /data/dalvik-cache/ -R

# Start ROM VM boot!
start

