#!/sbin/busybox sh

PROFILE=`cat /data/.siyah/.active.profile`;
. /data/.siyah/$PROFILE.profile;

if [ "$ad_block_update" == "on" ]; then

	TMPFILE=$(mktemp -t);
	HOST_FILE="/system/etc/hosts";

	mount -o remount,rw /;
	mount -o remount,rw /system;

	DNS1=`getprop net.rmnet0.dns1`;
	DNS2=`getprop net.rmnet0.dns2`;

	echo "nameserver 8.8.8.8" > /system/etc/resolv.conf;
	echo "nameserver $DNS1" >> /system/etc/resolv.conf;
	echo "nameserver $DNS2" >> /system/etc/resolv.conf;

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
			wget http://winhelp2002.mvps.org/hosts.zip -O $TMPFILE > /dev/null 2>&1;
			unzip -p $TMPFILE HOSTS > $HOST_FILE;
			chmod 644 $HOST_FILE;
			svc wifi disable;
			date +%H:%M-%D-%Z > /data/crontab/cron-ad_block_update;
			echo "AD Blocker: Updated" >> /data/crontab/cron-ad_block_update;
		fi;
	else
		wget http://winhelp2002.mvps.org/hosts.zip -O $TMPFILE > /dev/null 2>&1;
		unzip -p $TMPFILE HOSTS > $HOST_FILE;
		chmod 644 $HOST_FILE;
		date +%H:%M-%D-%Z > /data/crontab/cron-ad_block_update;
		echo "AD Blocker: Updated" >> /data/crontab/cron-ad_block_update;
	fi;

	rm -f $TMPFILE;
fi;
