#!/sbin/busybox sh

# Created By Dorimanx and Dairinin

if [ ! -e /system/etc/cron.d/crontabs/root ]; then
	mkdir -p /system/etc/cron.d/crontabs;
	chmod 777 /system/etc/cron.d/crontabs;
	cp -a /res/crontab_service/root /system/etc/cron.d/crontabs/;
fi;

# enable crond
echo "root:x:0:0::/system/etc/cron.d/crontabs:/sbin/sh" > /etc/passwd;

# set timezone
TZ=UTC

# set cron timezone
export TZ

#Set Permissions to scripts
chown 0:0 /system/etc/cron.d/crontabs/*;
chown 0:0 /data/crontab/cron-scripts/*;
chmod 777 /system/etc/cron.d/crontabs/*;
chmod 777 /data/crontab/cron-scripts/*;
# use /system/etc/cron.d/crontabs/ call the crontab file "root"
if [ -e /system/xbin/busybox ]; then
	/sbin/busybox chmod 6755 /system/xbin/busybox;
	nohup /system/xbin/busybox crond -c /system/etc/cron.d/crontabs/
elif [ -e /system/bin/busybox ]; then
	/sbin/busybox chmod 6755 /system/bin/busybox;
	nohup /system/bin/busybox crond -c /system/etc/cron.d/crontabs/
fi;

