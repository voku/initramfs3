#!/sbin/busybox sh
if [ -d /system/etc/init.d ]; then
	chmod 755 /system/etc/init.d/*
	/sbin/busybox run-parts /system/etc/init.d/
fi;

if [ -f /system/bin/customboot.sh ]; then
	chmod 755 /system/bin/customboot.sh
	/sbin/busybox sh /system/bin/customboot.sh
fi;

if [ -f /system/xbin/customboot.sh ]; then
	chmod 755 /system/xbin/customboot.sh
	/sbin/busybox sh /system/xbin/customboot.sh
fi;

if [ -f /data/local/customboot.sh ]; then
	chmod 755 /data/local/customboot.sh
	/sbin/busybox sh /data/local/customboot.sh
fi;

