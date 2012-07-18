#!/sbin/busybox sh

sync;

# remount all partitions tweked settings.
/sbin/busybox mount -o remount,rw,discard,nodev,inode_readahead_blks=2,nobarrier,commit=360,nobh,noauto_da_alloc,delalloc,journal_ioprio=5 /cache;

/sbin/busybox mount -o remount,rw,discard,nodev,inode_readahead_blks=2,data=ordered,barrier=0,commit=60,noauto_da_alloc,delalloc,journal_ioprio=5 /data;

/sbin/busybox mount -o remount,rw,discard,inode_readahead_blks=2,barrier=0,commit=120,noauto_da_alloc,delalloc,journal_ioprio=5 /system;

/sbin/busybox mount -o remount,rw,discard,inode_readahead_blks=2,barrier=0,commit=120,noauto_da_alloc,delalloc,journal_ioprio=5 /preload;

# remount all partitions with noatime, nodiratime
for k in $(/sbin/busybox mount | /sbin/busybox grep relatime | /sbin/busybox grep -v /acct | /sbin/busybox grep -v /dev/cpuctl | cut -d " " -f3); do
        /sbin/busybox mount -o remount,noatime,nodiratime $k;
done;

# remount ext4 partitions with optimizations
for k in $(/sbin/busybox mount | /sbin/busybox grep ext4 | /sbin/busybox cut -d " " -f3); do
        /sbin/busybox mount -o remount,noatime,nodiratime,commit=30 $k
done;

sync;
