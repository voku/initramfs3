#!/sbin/busybox sh

# Created By Dorimanx and Dairinin

MIUI_JB=0;
JELLY=0;
[ "`grep -i cMIUI /system/build.prop`" ] && MIUI_JB=1;
[ -f /system/lib/ssl/engines/libkeystore.so ] && JELLY=1;

if [ ! -e /system/etc/cron.d/crontabs/root ]; then
	mkdir -p /system/etc/cron.d/crontabs/;
	chmod 777 /system/etc/cron.d/crontabs/;
	cp -a /res/crontab_service/root /system/etc/cron.d/crontabs/;
fi;

chown 0:0 /system/etc/cron.d/crontabs/*;
chmod 777 /system/etc/cron.d/crontabs/*;

if [ "$MIUI_JB" == 1 ] || [ "$JELLY" == 1 ]; then
	echo "root:x:0:0::/system/etc/cron.d/crontabs:/sbin/sh" > /etc/passwd;
else
	if [ ! -e /var/spool/cron/crontabs/root ]; then
		mkdir -p /var/spool/cron/crontabs/;
		touch /var/spool/cron/crontabs/root;
		chmod 777 /var/spool/cron/crontabs/*;
		mount -o bind /system/etc/cron.d/crontabs/root /var/spool/cron/crontabs/root;
		echo "root:x:0:0::/var/spool/cron/crontabs:/sbin/sh" > /etc/passwd;
	fi;
fi;

# set timezone
TZ=UTC

# set cron timezone
export TZ

#Set Permissions to scripts
chown 0:0 /data/crontab/cron-scripts/*;
chmod 777 /data/crontab/cron-scripts/*;

# use /system/etc/cron.d/crontabs/ call the crontab file "root" for JB ROMS
# use /var/spool/cron/crontabs/ call the crontab file "root" for ICS ROMS
if [ -e /system/xbin/busybox ]; then
	/sbin/busybox chmod 6755 /system/xbin/busybox;
	if [ "$MIUI_JB" == 1 ] || [ "$JELLY" == 1 ]; then
		nohup /system/xbin/busybox crond -c /system/etc/cron.d/crontabs/
	else
		nohup /system/xbin/busybox crond -c /var/spool/cron/crontabs/
	fi;
elif [ -e /system/bin/busybox ]; then
	/sbin/busybox chmod 6755 /system/bin/busybox;
	if [ "$MIUI_JB" == 1 ] || [ "$JELLY" == 1 ]; then
		nohup /system/bin/busybox crond -c /system/etc/cron.d/crontabs/
	else
		nohup /system/xbin/busybox crond -c /var/spool/cron/crontabs/
	fi;
fi;

