#!/sbin/busybox sh

BB=/sbin/busybox

extract_payload()
{
  	$BB chmod 755 /sbin/read_boot_headers;
  	eval $(/sbin/read_boot_headers /dev/block/mmcblk0p5);
  	load_offset=$boot_offset;
  	load_len=$boot_len;
  	cd /;
  	dd bs=512 if=/dev/block/mmcblk0p5 skip=$load_offset count=$load_len | tar x;
}

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

$BB mount -o remount,rw /system;
$BB mount -t rootfs -o remount,rw rootfs;

cd /;

# copy cron files
$BB cp -a /res/crontab/ /data/
$BB rm -rf /data/crontab/cron/ > /dev/null 2>&1;
if [ ! -e /data/crontab/custom_jobs ]; then
	$BB touch /data/crontab/custom_jobs;
	$BB chmod 777 /data/crontab/custom_jobs;
fi;

if [ "$install_root" == "on" ]; then
	if [ -e /system/xbin/su ]; then
		echo "Superuser already exists";
	else
		# clean su traces
		$BB rm -f /system/bin/su > /dev/null 2>&1;
		$BB rm -f /system/xbin/su > /dev/null 2>&1;
		$BB mkdir /system/xbin > /dev/null 2>&1;
		$BB chmod 755 /system/xbin;

		# extract SU binary
		$BB cp -a /res/misc/payload/su /system/xbin/su;
		$BB chown 0.0 /system/xbin/su;
		$BB chmod 6755 /system/xbin/su;

		# clean super user old apps
		$BB rm -f /system/app/*uper?ser.apk > /dev/null 2>&1;
		$BB rm -f /system/app/?uper?u.apk > /dev/null 2>&1;
		$BB rm -f /system/app/*chainfire?supersu*.apk > /dev/null 2>&1;
		$BB rm -f /data/app/*uper?ser.apk > /dev/null 2>&1;
		$BB rm -f /data/app/?uper?u.apk > /dev/null 2>&1;
		$BB rm -f /data/app/*chainfire?supersu*.apk > /dev/null 2>&1;
		$BB rm -f /data/dalvik-cache/*uper?ser.apk* > /dev/null 2>&1;
		$BB rm -f /data/dalvik-cache/*chainfire?supersu*.apk* > /dev/null 2>&1;
		$BB rm -rf /data/data/com.noshufou.android.su > /dev/null 2>&1;
		$BB rm -rf /data/data/eu.chinfire.supersu > /dev/null 2>&1;

		# extract super user app
		$BB cp -a /res/misc/payload/SuperSU.apk /system/app/SuperSU.apk;
		$BB chown 0.0 /system/app/SuperSU.apk;
		$BB chmod 644 /system/app/SuperSU.apk;

		# restore witch if exist
		if [ -e /system/xbin/waswhich-bkp ]; then
			$BB rm -f /system/xbin/which;
			$BB cp /system/xbin/waswhich-bkp /system/xbin/which;
			$BB chmod 755 /system/xbin/which;
		fi;

		if [ -e /system/xbin/boxman ]; then
			$BB rm -f /system/xbin/busybox;
			$BB mv /system/xbin/boxman /system/xbin/busybox;
			$BB chmod 755 /system/xbin/busybox;
			$BB mv /system/bin/boxman /system/bin/busybox;
			$BB chmod 755 /system/bin/busybox;
		fi;

		# kill superuser pid
		pkill -f "com.noshufou.android.su";
		pkill -f "eu.chinfire.supersu";
	fi;
fi;

if [ ! -e /system/app/CWMManager.apk ]; then
	$BB rm -f /data/app/CWMManager.apk > /dev/null 2>&1;
	$BB rm -f /data/dalvik-cache/*CWMManager.apk* > /dev/null 2>&1;
	$BB rm -f /data/app/eu.chainfire.cfroot.cwmmanager*.apk > /dev/null 2>&1;
	$BB rm -rf /data/data/eu.chainfire.cfroot.cwmmanage* > /dev/null 2>&1;

	$BB cp -a /res/misc/payload/CWMManager.apk /system/app/CWMManager.apk;
	$BB chown 0.0 /system/app/CWMManager.apk;
	$BB chmod 644 /system/app/CWMManager.apk;
fi;

# liblights install by force to allow BLN
if [ ! -e /system/lib/hw/lights.exynos4.so.BAK ]; then
	$BB mv /system/lib/hw/lights.exynos4.so /system/lib/hw/lights.exynos4.so.BAK;
fi;
echo "Copying liblights";
$BB cp -a /res/misc/lights.exynos4.so /system/lib/hw/lights.exynos4.so;
$BB chown root:root /system/lib/hw/lights.exynos4.so;
$BB chmod 644 /system/lib/hw/lights.exynos4.so;

# add gesture_set.sh with default gustures to data to be used by user.
if [ ! -e /data/gesture_set.sh ]; then
	$BB cp -a /res/misc/gesture_set.sh /data/;
fi;

GMTWEAKS()
{

	if [ -f /system/app/STweaks.apk ]; then
		stmd5sum=`/sbin/busybox md5sum /system/app/STweaks.apk | /sbin/busybox awk '{print $1}'`
		stmd5sum_kernel=`cat /res/stweaks_md5`;
		if [ "$stmd5sum" != "$stmd5sum_kernel" ]; then
			$BB rm -f /system/app/STweaks.apk > /dev/null 2>&1;
			$BB rm -f /data/app/com.gokhanmoral.*weaks*.apk > /dev/null 2>&1;
			$BB rm -f /data/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
			$BB rm -f /cache/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
		fi;
	fi;

	if [ ! -f /system/app/STweaks.apk ]; then
		$BB rm -f /data/app/com.gokhanmoral.*weak*.apk > /dev/null 2>&1;
		$BB rm -rf /data/data/com.gokhanmoral.*weak* > /dev/null 2>&1;
		$BB rm -f /data/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
		$BB rm -f /cache/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
		$BB cp -a /res/misc/payload/STweaks.apk /system/app/STweaks.apk;
		$BB chown 0.0 /system/app/STweaks.apk;
		$BB chmod 644 /system/app/STweaks.apk;
	fi;
}
GMTWEAKS;

EXTWEAKS_CLEAN()
{
	if [ -f /system/app/Extweaks.apk ] || [ -f /data/app/com.darekxan.extweaks.ap*.apk ]; then
		$BB rm -f /system/app/Extweaks.apk > /dev/null 2>&1;
		$BB rm -f /data/app/com.darekxan.extweaks.ap*.apk > /dev/null 2>&1;
		$BB rm -rf /data/data/com.darekxan.extweaks.app > /dev/null 2>&1;
		$BB rm -f /data/dalvik-cache/*com.darekxan.extweaks.app* > /dev/null 2>&1;
	fi;
}
EXTWEAKS_CLEAN;

if [ ! -s /system/xbin/ntfs-3g ]; then
		$BB cp -a /res/misc/payload/ntfs-3g /system/xbin/ntfs-3g;
		$BB chown 0.0 /system/xbin/ntfs-3g;
		$BB chmod 755 /system/xbin/ntfs-3g;
fi;

$BB mount -t rootfs -o remount,rw rootfs;
$BB mount -o remount,rw /system;

