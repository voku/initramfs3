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

	if [ -e $i/queue/read_ahead_kb ]; then
		echo "2048" >  $i/queue/read_ahead_kb;
	fi;

	if [ -e $i/queue/iosched/writes_starved ]; then
		echo "1" > $i/queue/iosched/writes_starved;
	fi;

	if [ -e $i/queue/iosched/fifo_batch ]; then
		echo "1" > $i/queue/iosched/fifo_batch;
	fi;
done;

mount -o remount,rw /system;
mount -o remount,rw /;

if [ -e /sbin/ext/jb-installed ]; then
	rm -f /sbin/ext/jb-installed;
	mount -o remount,utf8 /storage/sdcard1;
	mount -o remount,utf8 /storage/sdcard0;
else
	mount -o remount,utf8 /mnt/sdcard;
	mount -o remount,utf8 /mnt/emmc;
fi;

