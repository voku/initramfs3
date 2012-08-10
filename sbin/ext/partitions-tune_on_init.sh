#!/sbin/busybox sh

sync;

# remount all partitions with noatime, nodiratime
PARTITIONS=`/sbin/busybox mount | /sbin/busybox grep -v /acct | /sbin/busybox grep -v /dev/cpuctl | cut -d " " -f3`
for k in $PARTITIONS
do
	/sbin/busybox mount -o remount,noatime,nodiratime $k;
done;

# remount all partitions tweked settings.
/sbin/busybox mount -o remount,rw,discard,nodev,inode_readahead_blks=2,barrier=0,commit=360,journal_async_commit,noauto_da_alloc,delalloc,journal_ioprio=5 /cache;

/sbin/busybox mount -o remount,rw,discard,nodev,inode_readahead_blks=2,barrier=0,commit=30,journal_async_commit,noauto_da_alloc,delalloc,journal_ioprio=5 /data;

/sbin/busybox mount -o remount,rw,discard,inode_readahead_blks=2,barrier=0,commit=30,journal_async_commit,noauto_da_alloc,delalloc,journal_ioprio=5 /system;

/sbin/busybox mount -o remount,rw,discard,inode_readahead_blks=2,barrier=0,commit=30,journal_async_commit,noauto_da_alloc,delalloc,journal_ioprio=5 /preload;

sync;

