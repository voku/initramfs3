#!/sbin/busybox sh

PROFILE=`cat /data/.siyah/.active.profile`;
. /data/.siyah/$PROFILE.profile;

if [ "$cron_drop_cache" == "on" ]; then

	while [ ! `cat /proc/loadavg | cut -c1-4` \< "3.50" ]; do
		echo "Waiting For CPU to cool down"
		sleep 30;
	done;

	sync;
	sysctl -w vm.drop_caches=3
	sysctl -w vm.drop_caches=1
	sync;
	date > /data/crontab/cron-clear-ram-cache;
	echo "Done! Cleaned RAM Cache" >> /data/crontab/cron-clear-ram-cache;
fi;
