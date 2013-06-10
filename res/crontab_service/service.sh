#!/sbin/busybox sh

# Created By Dorimanx and Dairinin

MIUI_JB=0;
JELLY=0;
JB_SAMMY=0;
[ "`grep -i cMIUI /system/build.prop`" ] && MIUI_JB=1;
[ -f /system/lib/ssl/engines/libkeystore.so ] && JELLY=1;

if [ `cat /tmp/sammy_rom` -eq "1" ]; then
	JB_SAMMY=1;
fi;

# allow custom user jobs
if [ ! -e /data/crontab/root ]; then
	mkdir /data/crontab/;
	cp -a /res/crontab_service/root /data/crontab/;
	chown 0:0 /data/crontab/root;
	chmod 777 /data/crontab/root;
fi;

JELLY_MIUI()
{
	if [ ! -e /system/etc/cron.d/crontabs/root ]; then
		mkdir -p /system/etc/cron.d/crontabs/;
		cp -a /data/crontab/root /system/etc/cron.d/crontabs/;
		chown 0:0 /system/etc/cron.d/crontabs/*;
		chmod 777 /system/etc/cron.d/crontabs/*;
	fi;
	echo "root:x:0:0::/system/etc/cron.d/crontabs:/sbin/sh" > /etc/passwd;
}

JB_SAMMY_CRON()
{
	if [ ! -e /var/spool/cron/crontabs/root ]; then
		mkdir -p /var/spool/cron/crontabs/;
		cp -a /data/crontab/root /var/spool/cron/crontabs/;
		chown 0:0 /var/spool/cron/crontabs/*;
		chmod 777 /var/spool/cron/crontabs/*;
	fi;
	echo "root:x:0:0::/var/spool/cron/crontabs:/sbin/sh" > /etc/passwd;
}

if [ "$JB_SAMMY" -eq "1" ]; then
	JB_SAMMY_CRON;
elif [ "$MIUI_JB" -eq "1" ] || [ "$JELLY" -eq "1" ]; then
	JELLY_MIUI;
else
	JB_SAMMY_CRON;
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
	if [ "$JB_SAMMY" -eq "1" ]; then
		nohup /system/xbin/busybox crond -c /var/spool/cron/crontabs/
	elif [ "$MIUI_JB" -eq "1" ] || [ "$JELLY" -eq "1" ]; then
		nohup /system/xbin/busybox crond -c /system/etc/cron.d/crontabs/
	else
		nohup /system/xbin/busybox crond -c /var/spool/cron/crontabs/
	fi;
elif [ -e /system/bin/busybox ]; then
	/sbin/busybox chmod 6755 /system/bin/busybox;
	if [ "$JB_SAMMY" -eq "1" ]; then
		nohup /system/xbin/busybox crond -c /var/spool/cron/crontabs/
	elif [ "$MIUI_JB" -eq "1" ] || [ "$JELLY" -eq "1" ]; then
		nohup /system/bin/busybox crond -c /system/etc/cron.d/crontabs/
	else
		nohup /system/xbin/busybox crond -c /var/spool/cron/crontabs/
	fi;
fi;

