#!/sbin/busybox sh

extract_payload()
{
	payload_extracted=1
  	/sbin/busybox chmod 755 /sbin/read_boot_headers
  	eval $(/sbin/read_boot_headers /dev/block/mmcblk0p5)
  	load_offset=$boot_offset
  	load_len=$boot_len
  	cd /
  	dd bs=512 if=/dev/block/mmcblk0p5 skip=$load_offset count=$load_len | tar x
}

. /res/customconfig/customconfig-helper
read_defaults
read_config

/sbin/busybox mount -o remount,rw /system
/sbin/busybox mount -t rootfs -o remount,rw rootfs
payload_extracted=0

cd /

if [ "$install_root" == "on" ]; then
	if [ -s /system/xbin/su ]; then
		echo "Superuser already exists"
	else
		if [ "$payload_extracted" == "0" ]; then
			extract_payload
		fi;

		# Clean su traces.
		/sbin/busybox rm -f /system/bin/su > /dev/null 2>&1
		/sbin/busybox rm -f /system/xbin/su > /dev/null 2>&1
		/sbin/busybox mkdir /system/xbin > /dev/null 2>&1
		/sbin/busybox chmod 755 /system/xbin

		# Extract SU binary.
		/sbin/busybox xzcat /res/misc/payload/su.xz > /system/xbin/su
		/sbin/busybox chown 0.0 /system/xbin/su
		/sbin/busybox chmod 6755 /system/xbin/su

		# Clean super user old apps.
		/sbin/busybox rm -f /system/app/*uper?ser.apk > /dev/null 2>&1
		/sbin/busybox rm -f /system/app/?uper?u.apk > /dev/null 2>&1
		/sbin/busybox rm -f /system/app/*chainfire?supersu*.apk > /dev/null 2>&1
		/sbin/busybox rm -f /data/app/*uper?ser.apk > /dev/null 2>&1
		/sbin/busybox rm -f /data/app/?uper?u.apk > /dev/null 2>&1
		/sbin/busybox rm -f /data/app/*chainfire?supersu*.apk > /dev/null 2>&1
		/sbin/busybox rm -rf /data/dalvik-cache/*uper?ser.apk* > /dev/null 2>&1
		/sbin/busybox rm -rf /data/dalvik-cache/*chainfire?supersu*.apk* > /dev/null 2>&1

		# extract super user app.
		/sbin/busybox xzcat /res/misc/payload/Superuser.apk.xz > /system/app/Superuser.apk
		/sbin/busybox chown 0.0 /system/app/Superuser.apk
		/sbin/busybox chmod 644 /system/app/Superuser.apk

		# Restore witch if exist
		if [ -e /system/xbin/waswhich-bkp ]; then
			/sbin/busybox rm -f /system/xbin/which > /dev/null 2>&1
			/sbin/busybox cp /system/xbin/waswhich-bkp /system/xbin/which > /dev/null 2>&1
			/sbin/busybox chmod 755 /system/xbin/which > /dev/null 2>&1
		fi;

		if [ -e /system/xbin/boxman ]; then
			/sbin/busybox rm -f /system/xbin/busybox > /dev/null 2>&1
			/sbin/busybox mv /system/xbin/boxman /system/xbin/busybox > /dev/null 2>&1
			/sbin/busybox chmod 755 /system/xbin/busybox > /dev/null 2>&1
			/sbin/busybox mv /system/bin/boxman /system/bin/busybox > /dev/null 2>&1
			/sbin/busybox chmod 755 /system/bin/busybox > /dev/null 2>&1
		fi;

		# Delete payload and kill superuser pid.
		/sbin/busybox rm -rf /res/misc/payload
		pkill -f "com.noshufou.android.su" > /dev/null 2>&1
	fi;
fi;


# liblights install by force to allow BLN.
if [ ! -e /system/lib/hw/lights.exynos4.so.BAK ]; then
	/sbin/busybox mv /system/lib/hw/lights.exynos4.so /system/lib/hw/lights.exynos4.so.BAK
fi;
echo "Copying liblights"
/sbin/busybox cp -a /res/misc/lights.exynos4.so /system/lib/hw/lights.exynos4.so
/sbin/busybox chown root:root /system/lib/hw/lights.exynos4.so
/sbin/busybox chmod 644 /system/lib/hw/lights.exynos4.so

# add gesture_set.sh with default gustures to data to be used by user.
if [ ! -e /data/gesture_set.sh ]; then
	/sbin/busybox cp -a /res/misc/gesture_set.sh /data/
fi;

# New GM EXTWEAKS, Still not fully ready, lets wait for great app.
GMTWEAKS () {
echo "Checking if STweaks is installed"
if [ ! -f /system/.siyah/stweaks-installed ];
then
	#  if [ "$payload_extracted" == "0" ];then
	#    extract_payload
	#  fi
	/sbin/busybox rm /system/app/STweaks.apk
	/sbin/busybox rm /data/app/com.gokhanmoral.STweaks*.apk
	/sbin/busybox rm /data/dalvik-cache/*STweaks.apk*

	/sbin/busybox cat /res/STweaks.apk > /system/app/STweaks.apk
	/sbin/busybox chown 0.0 /system/app/STweaks.apk
	/sbin/busybox chmod 644 /system/app/STweaks.apk
	/sbin/busybox mkdir /system/.siyah
	/sbin/busybox chmod 755 /system/.siyah
	/sbin/busybox echo 1 > /system/.siyah/stweaks-installed
fi
}
#GMTWEAKS # Disabled for now.

if [ ! -s /system/xbin/ntfs-3g ];
then
	if [ "$payload_extracted" == "0" ];then
		extract_payload
  	fi
		/sbin/busybox xzcat /res/misc/payload/ntfs-3g.xz > /system/xbin/ntfs-3g
		/sbin/busybox chown 0.0 /system/xbin/ntfs-3g
		/sbin/busybox chmod 755 /system/xbin/ntfs-3g
fi

/sbin/busybox rm -rf /res/misc/payload

/sbin/busybox mount -t rootfs -o remount,rw rootfs
/sbin/busybox mount -o remount,rw /system

