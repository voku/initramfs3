#!/sbin/busybox sh

# ==============================================================
# I/O related tweaks
# ==============================================================
DM=`ls -d /sys/block/dm*`;

for i in $DM; do

        if [ -e $i/queue/rotational ]; then
                echo "0" > $i/queue/rotational;
        fi;

        if [ -e $i/queue/iostats ]; then
                echo "0" > $i/queue/iostats;
        fi;

        if [ -e $i/queue/rq_affinity ]; then
                echo "1" > $i/queue/rq_affinity;
        fi;

        if [ -e $i/queue/read_ahead_kb ]; then
                echo "1024" >  $i/queue/read_ahead_kb;
        fi;

        if [ -e $i/queue/iosched/writes_starved ]; then
                echo "1" > $i/queue/iosched/writes_starved;
        fi;

        if [ -e $i/queue/iosched/fifo_batch ]; then
                echo "1" > $i/queue/iosched/fifo_batch;
        fi;

        if [ -e $i/queue/iosched/rev_penalty ]; then
                echo "1" > $i/queue/iosched/rev_penalty;
        fi;

done;

# =========
# remount all partitions with noatime, nodiratime
# =========
PARTITIONS=`/sbin/busybox mount | /sbin/busybox grep relatime | /sbin/busybox grep -v /acct | /sbin/busybox grep -v /dev/cpuctl | cut -d " " -f3`
for k in $PARTITIONS; do
        /sbin/busybox mount -o remount,noatime,nodiratime $k;
done;

mount -o remount,rw /system;

# ==============================================================
# CLEANING-TWEAKS
# ==============================================================
rm -rf /emmc/lost+found/* 2> /dev/null;
rm -rf /sdcard/lost+found/* 2> /dev/null;

