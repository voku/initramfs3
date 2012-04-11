#!/sbin/busybox sh

# =========
# Optimize io scheduler
# =========

STL=`ls -d /sys/block/stl*`;
BML=`ls -d /sys/block/bml*`;
MMC=`ls -d /sys/block/mmc*`;
ZRM=`ls -d /sys/block/zram*`;
MTD=`ls -d /sys/block/mtd*`;

# Optimize non-rotating storage; 
for i in $STL $BML $MMC $ZRM $MTD;
do
	if [ -e $i/queue/rotational ]; 
	then
		echo "0" > $i/queue/rotational; 
	fi;

	if [ -e $i/queue/iostats ];
	then
		echo "0" > $i/queue/iostats;
	fi;

	#if [ -e $i/queue/iosched/group_isolation ];
	#then
	#	echo "0" > $i/queue/iosched/group_isolation;
	#fi;

	#if [ -e $i/queue/iosched/slice_idle ];
	#then
	#	echo "0" > $i/queue/iosched/slice_idle;
	#fi;

	#if [ -e $i/queue/iosched/back_seek_penalty ];
	#then
	#	echo "1" > $i/queue/iosched/back_seek_penalty;
	#fi;

	if [ -e $i/queue/iosched/low_latency ];
	then
		echo "1" > $i/queue/iosched/low_latency;
	fi;

	if [ -e $i/queue/iosched/fifo_batch ];
	then
		echo "1" > $i/queue/iosched/fifo_batch;
	fi;

	if [ -e $i/queue/iosched/writes_starved ];
	then
		echo "1" > $i/queue/iosched/writes_starved;
	fi;

	if [ -e $i/queue/iosched/rev_penalty ];
	then
		echo "1" > $i/queue/iosched/rev_penalty;
	fi;

	if [ -e $i/queue/rq_affinity ];
	then
		echo "1" > $i/queue/rq_affinity;   
	fi;

	if [ -e $i/queue/iosched/slice_async_rq ];
	then
		echo "2" > $i/queue/iosched/slice_async_rq;
	fi;

	if [ -e $i/queue/iosched/quantum ];
	then
		echo "8" > $i/queue/iosched/quantum;
	fi;

	#if [ -e $i/queue/nr_requests ];
	#then
	#	echo "1024" > $i/queue/nr_requests;
	#fi;

	#if [ -e $i/queue/iosched/back_seek_max ];
	#then
	#	echo "1000000000" > $i/queue/iosched/back_seek_max;
	#fi;

done;

# =========
# TWEAKS: raising read_ahead_kb cache-value for mounts that are sdcard-like to 1024 
# =========
if [ -e /sys/devices/virtual/bdi/179:16/read_ahead_kb ];
  then
    echo "1024" > /sys/devices/virtual/bdi/179:16/read_ahead_kb;
fi;

if [ -e /sys/devices/virtual/bdi/179:24/read_ahead_kb ];
  then
    echo "1024" > /sys/devices/virtual/bdi/179:24/read_ahead_kb;
fi;

# =========
# Remount all partitions
# =========
for k in $(busybox mount | grep relatime | cut -d " " -f3);
do
	sync;
	busybox mount -o remount,noatime,nodiratime $k;
done;

for l in $(busybox mount | grep ext[3-4] | cut -d " " -f3);
do
	sync;
	busybox mount -o remount,noatime,nodiratime,delalloc,noauto_da_alloc,commit=15 $l;
done;
mount -o remount,rw,noatime,nodiratime,nodev,nobh,nouser_xattr,inode_readahead_blks=1,discard,barrier=0,commit=60,noauto_da_alloc,delalloc /cache /cache;
mount -o remount,rw,noatime,nodiratime,nodev,nobh,nouser_xattr,inode_readahead_blks=1,discard,barrier=0,commit=60,noauto_da_alloc,delalloc /data /data;

# =========
# TWEAKS
# =========
setprop ro.media.dec.jpeg.memcap 20000000;
setprop ro.media.enc.jpeg.quality 90,80,70;

# =========
# MEMORY-TWEAKS
# =========
#echo "50" > /proc/sys/vm/swappiness;
#echo "50" > /proc/sys/vm/vfs_cache_pressure;
#echo "0" > /sys/module/lowmemorykiller/parameters/debug_level;
# Define the memory thresholds at which the above process classes will
# be killed. These numbers are in pages (4k) -> (1 MB * 1024) / 4 = 256
FOREGROUND_APP_MEM=8192;
VISIBLE_APP_MEM=10240;
SECONDARY_SERVER_MEM=12288;
BACKUP_APP_MEM=12288;
HOME_APP_MEM=12288;
HIDDEN_APP_MEM=14336;
CONTENT_PROVIDER_MEM=16384;
EMPTY_APP_MEM=20480;
#echo "$FOREGROUND_APP_MEM,$VISIBLE_APP_MEM,$SECONDARY_SERVER_MEM,$HIDDEN_APP_MEM,$CONTENT_PROVIDER_MEM,$EMPTY_APP_MEM" > /sys/module/lowmemorykiller/parameters/minfree;

# =========
# Renice - kernel thread responsible for managing the memory
# =========
renice 19 `pidof kswapd0`;

# =========
# CleanUp
# =========
#drop caches to free some memory
sync;
/system/xbin/echo "3" > /proc/sys/vm/drop_caches;
sleep 1;
/system/xbin/echo "1" > /proc/sys/vm/drop_caches; 
