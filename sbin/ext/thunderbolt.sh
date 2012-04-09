#!/sbin/busybox sh
#ThunderBolt!
#Credits:
# zacharias.maladroit
# voku1987
# collin_ph@xda
# TAKE NOTE THAT LINES PRECEDED BY A "#" IS COMMENTED OUT!

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
    #   echo "1024" > $i/queue/nr_requests;
    #fi;

    #if [ -e $i/queue/iosched/back_seek_max ];
    #then
    #   echo "1000000000" > $i/queue/iosched/back_seek_max;
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

mount -o noatime,nodiratime,remount,rw,discard,barrier=0,commit=60,noauto_da_alloc,delalloc /cache /cache;
mount -o noatime,nodiratime,remount,rw,discard,barrier=0,commit=60,noauto_da_alloc,delalloc /data /data;

# =========
# TWEAKS: for TCP read/write
# =========
echo "0" > /proc/sys/net/ipv4/tcp_timestamps;
echo "1" > /proc/sys/net/ipv4/tcp_tw_reuse;
echo "1" > /proc/sys/net/ipv4/tcp_sack;
echo "1" > /proc/sys/net/ipv4/tcp_tw_recycle;
echo "1" > /proc/sys/net/ipv4/tcp_window_scaling;
echo "1" > /proc/sys/net/ipv4/tcp_moderate_rcvbuf;
echo "1" > /proc/sys/net/ipv4/route/flush;
echo "5" > /proc/sys/net/ipv4/tcp_keepalive_probes;
echo "30" > /proc/sys/net/ipv4/tcp_keepalive_intvl;
echo "30" > /proc/sys/net/ipv4/tcp_fin_timeout;
echo "404480" > /proc/sys/net/core/wmem_max;
echo "404480" > /proc/sys/net/core/rmem_max;
echo "256960" > /proc/sys/net/core/rmem_default;
echo "256960" > /proc/sys/net/core/wmem_default;
echo "20480" > /proc/sys/net/core/optmem_max;
echo "4096 16384 404480" > /proc/sys/net/ipv4/tcp_wmem;
echo "4096 87380 404480" > /proc/sys/net/ipv4/tcp_rmem;
echo "4096" > /proc/sys/net/ipv4/udp_rmem_min;
echo "4096" > /proc/sys/net/ipv4/udp_wmem_min;
setprop net.tcp.buffersize.default 4096,87380,404480,4096,16384,404480;
setprop net.tcp.buffersize.wifi 4096,87380,404480,4096,16384,404480;
setprop net.tcp.buffersize.umts 4096,87380,404480,4096,16384,404480;

# =========
# TWEAKS: optimized for 3G/Edge speed
# =========
setprop ro.ril.hep 1;
setprop ro.ril.enable.dtm 1;
setprop ro.ril.enable.a53 1;
setprop ro.ril.enable.3g.prefix 1;
setprop ro.ril.enable.a52 1;
setprop ro.ril.enable.a53 1;
setprop ro.ril.emc.mode 2;
setprop ro.ril.hsxpa 2;
setprop ro.ril.hsupa.category 5;
setprop ro.ril.hsdpa.category 8;
setprop ro.ril.gprsclass 12;

# =========
# TWEAKS
# =========
setprop debug.performance.tuning 1; 
setprop video.accelerate.hw 1;
setprop debug.sf.hw 1;
setprop ro.telephony.call_ring.delay 1000;
setprop wifi.supplicant_scan_interval 180;
setprop windowsmgr.max_events_per_sec 60;
setprop ro.media.dec.jpeg.memcap 20000000;
setprop ro.media.enc.jpeg.quality 90,80,70;
setprop dalvik.vm.startheapsize 12m;
setprop dalvik.vm.heapsize 32m;
sysctl -w kernel.sem="500 512000 100 2048";
sysctl -w kernel.shmmax=268435456;
echo "8" > /proc/sys/vm/page-cluster;
echo "1" > /proc/sys/kernel/sched_compat_yield;
echo "0" > /proc/sys/kernel/sched_child_runs_first;
echo "256000" > /proc/sys/kernel/sched_shares_ratelimit;
echo "64000" > /proc/sys/kernel/msgmni;
echo "64000" > /proc/sys/kernel/msgmax;
echo "10" > /proc/sys/fs/lease-break-time;
echo "500 512000 64 2048" > /proc/sys/kernel/sem;
echo "5000" > /proc/sys/kernel/threads-max;
echo "0" > /proc/sys/vm/oom_kill_allocating_task;
echo "0" > /proc/sys/vm/panic_on_oom;

# =========
# MEMORY-TWEAKS
# =========
echo "0" > /proc/sys/vm/swappiness;
echo "50" > /proc/sys/vm/vfs_cache_pressure;
echo "2048" > /proc/sys/vm/min_free_kbytes;
echo "500" > /proc/sys/vm/dirty_expire_centisecs;
echo "3000" > /proc/sys/vm/dirty_writeback_centisecs;
echo "22" > /proc/sys/vm/dirty_ratio;
echo "4" > /proc/sys/vm/dirty_background_ratio;
echo "3" > /proc/sys/vm/drop_caches;
echo "1" > /proc/sys/vm/overcommit_memory;
echo "8" > /proc/sys/vm/min_free_order_shift;
echo "0,1,2,4,6,15" > /sys/module/lowmemorykiller/parameters/adj;
echo "0" > /sys/module/lowmemorykiller/parameters/debug_level;
echo "64" > /sys/module/lowmemorykiller/parameters/cost;
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
echo "$FOREGROUND_APP_MEM,$VISIBLE_APP_MEM,$SECONDARY_SERVER_MEM,$HIDDEN_APP_MEM,$CONTENT_PROVIDER_MEM,$EMPTY_APP_MEM" > /sys/module/lowmemorykiller/parameters/minfree;

