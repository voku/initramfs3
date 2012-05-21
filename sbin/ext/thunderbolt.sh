#!/sbin/busybox sh
#ThunderBolt!
#Credits:
# zacharias.maladroit
# voku1987
# collin_ph@xda
# TAKE NOTE THAT LINES PRECEDED BY A "#" IS COMMENTED OUT!

# ==============================================================
# ==============================================================
# ==============================================================
# I/O related tweaks 
# ==============================================================
# ==============================================================
# ==============================================================

DM=`ls -d /sys/block/dm*`;
LOOP=`ls -d /sys/block/loop*`;
MMC=`ls -d /sys/block/mmc*`;
ZRM=`ls -d /sys/block/zram*`;
RAM=`ls -d /sys/block/ram*`;

# Optimize non-rotating storage;
for i in $DM $LOOP $MMC $ZRM $RAM;
do
	#IMPORTANT!
	if [ -e $i/queue/rotational ]; 
	then
		echo 0 > $i/queue/rotational; 
	fi;
	if [ -e $i/queue/nr_requests ];
	then
		echo 2048 > $i/queue/nr_requests;
	fi;
	#CFQ specific
	if [ -e $i/queue/iosched/back_seek_penalty ];
	then 
		echo 1 > $i/queue/iosched/back_seek_penalty;
	fi;
	#CFQ specific
	if [ -e $i/queue/iosched/low_latency ];
	then
		echo 1 > $i/queue/iosched/low_latency;
	fi;
	#CFQ Specific
	if [ -e $i/queue/iosched/slice_idle ];
	then 
		echo 1 > $i/queue/iosched/slice_idle; # previous: 1
	fi;
	# deadline/VR/SIO scheduler specific
	if [ -e $i/queue/iosched/fifo_batch ];
	then
		echo 4 > $i/queue/iosched/fifo_batch;
	fi;
	if [ -e $i/queue/iosched/writes_starved ];
	then
		echo 1 > $i/queue/iosched/writes_starved;
	fi;
	#CFQ specific
	if [ -e $i/queue/iosched/quantum ];
	then
		echo 8 > $i/queue/iosched/quantum;
	fi;
	#CFQ specific
	if [ -e $i/queue/iosched/slice_async_rq ];
	then 
		echo 4 > $i/queue/iosched/slice_async_rq;
	fi;
	#CFQ specific
	if [ -e $i/queue/iosched/back_seek_max ];
	then 
		echo 1000000000 > $i/queue/iosched/back_seek_max;
	fi;
	#VR Specific
	if [ -e $i/queue/iosched/rev_penalty ];
	then
		echo 1 > $i/queue/iosched/rev_penalty;
	fi;
	if [ -e $i/queue/rq_affinity ];
	then
	echo "1"   >  $i/queue/rq_affinity;   
	fi;
#disable iostats to reduce overhead  # idea by kodos96 - thanks !
	if [ -e $i/queue/iostats ];
	then
		echo "0" > $i/queue/iostats;
	fi;
# Optimize for read- & write-throughput; 
# Optimize for readahead; 
	if [ -e $i/queue/read_ahead_kb ];
	then
		echo "256" >  $i/queue/read_ahead_kb;
	fi;
# Commented out nomerges (Merges are good). max_sectors_kb to default - don't tweak it
#          echo "0"   >  $i/queue/nomerges
#          echo "128" >  $i/queue/max_sectors_kb
	
# Specifically for NAND devices where reads are faster than writes, writes starved 2:1 is good
	if [ -e $i/queue/iosched/writes_starved ];
	then
		echo 2 > $i/queue/iosched/writes_starved;
	fi;
done;


# =========
# TWEAKS: raising read_ahead_kb cache-value for mounts that are sdcard-like to 1024 
# =========

if [ -e /sys/devices/virtual/bdi/179:0/read_ahead_kb ];
then
    echo "1024" > /sys/devices/virtual/bdi/179:0/read_ahead_kb;
fi;
	
if [ -e /sys/devices/virtual/bdi/179:8/read_ahead_kb ];
  then
    echo "1024" > /sys/devices/virtual/bdi/179:8/read_ahead_kb;
fi;

if [ -e /sys/devices/virtual/bdi/179:16/read_ahead_kb ];
  then
    echo "1024" > /sys/devices/virtual/bdi/179:16/read_ahead_kb;
fi;

if [ -e /sys/devices/virtual/bdi/179:24/read_ahead_kb ];
  then
    echo "1024" > /sys/devices/virtual/bdi/179:24/read_ahead_kb;
fi;

if [ -e /sys/devices/virtual/bdi/default/read_ahead_kb ];
  then
    echo "256" > /sys/devices/virtual/bdi/default/read_ahead_kb;
fi;


# ==============================================================
# ==============================================================
# ==============================================================
# Mount related tweaks (Applied globally)
# ==============================================================
# ==============================================================
# ==============================================================


# Remount all partitions with noatime
for k in $(busybox mount | grep relatime | grep -v /acct | grep -v /dev/cpuctl | cut -d " " -f3);
do
#sync;
busybox mount -o remount,noatime $k;
done;

exit 1

