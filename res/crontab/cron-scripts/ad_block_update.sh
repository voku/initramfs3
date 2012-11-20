#!/sbin/busybox sh

PROFILE=`cat /data/.siyah/.active.profile`;
. /data/.siyah/$PROFILE.profile;

if [ "$ad_block_update" == "on" ]; then

	TMPFILE=$(mktemp -t);
	HOST_FILE="/system/etc/hosts";

	TESTCONNECTION=`wget http://www.google.com -O $TMPFILE > /dev/null 2>&1`;
	if [ $? != 0 ]; then
		svc wifi enable;
		sleep 10
		TESTCONNECTION=`wget http://www.google.com -O $TMPFILE > /dev/null 2>&1`;
		if [ $? != 0 ]; then
			date +%H:%M-%D-%Z > /data/crontab/cron-ad_block_update;
			echo "Problem: no internet connection!" >> /data/crontab/cron-ad_block_update;
			svc wifi disable;
		else
			mount -o remount,rw /system
			wget http://winhelp2002.mvps.org/hosts.zip -O $TMPFILE > /dev/null 2>&1;
			unzip -p $TMPFILE HOSTS > $HOST_FILE;
			chmod 644 $HOST_FILE;
			svc wifi disable;
			date +%H:%M-%D-%Z > /data/crontab/cron-ad_block_update;
			echo "AD Blocker: Updated" >> /data/crontab/cron-ad_block_update;
		fi;
	else
		mount -o remount,rw /system
		wget http://winhelp2002.mvps.org/hosts.zip -O $TMPFILE > /dev/null 2>&1;
		unzip -p $TMPFILE HOSTS > $HOST_FILE;
		chmod 644 $HOST_FILE;
		date +%H:%M-%D-%Z > /data/crontab/cron-ad_block_update;
		echo "AD Blocker: Updated" >> /data/crontab/cron-ad_block_update;
        fi;
fi;
