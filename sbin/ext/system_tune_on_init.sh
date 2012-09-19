#!/sbin/busybox sh

# stop ROM VM from booting!
stop

# remount all partitions tweked settings.
/sbin/busybox mount -o remount,rw,nodev,barrier=0,commit=360,noauto_da_alloc,delalloc /cache;

/sbin/busybox mount -o remount,rw,nodev,barrier=0,commit=30,noauto_da_alloc,delalloc /data;

/sbin/busybox mount -o remount,rw,barrier=0,commit=30,noauto_da_alloc,delalloc /system;

/sbin/busybox mount -o remount,rw,barrier=0,commit=30,noauto_da_alloc,delalloc /preload;

/sbin/busybox mount -t rootfs -o remount,rw rootfs

##### Critical Permissions fix #####
/sbin/busybox chmod 0777 /data/dalvik-cache/ -R
/sbin/busybox chmod 0777 /dev/cpuctl/ -R
/sbin/busybox chmod 0766 /data/anr/ -R
/sbin/busybox chmod 0777 /data/data/com.android.providers.*/databases/*
/sbin/busybox chmod 0777 /data/system/inputmethod/ -R
/sbin/busybox chmod 0777 /data/local/ -R
/sbin/busybox chmod 0777 /sys/devices/system/cpu/ -R
/sbin/busybox chown root:system /sys/devices/system/cpu/ -R

(
##### Critical OWNER Permissions fix #####
/sbin/fix_permissions -l -v -f ApplicationsProvider.apk
/sbin/fix_permissions -l -v -f Bluetooth.apk
/sbin/fix_permissions -l -v -f Browser.apk
/sbin/fix_permissions -l -v -f Camera.apk
/sbin/fix_permissions -l -v -f Contacts.apk
/sbin/fix_permissions -l -v -f ContactsProvider.apk
/sbin/fix_permissions -l -v -f DrmProvider.apk
/sbin/fix_permissions -l -v -f Mms.apk
/sbin/fix_permissions -l -v -f NetworkLocation.apk
/sbin/fix_permissions -l -v -f PackageInstaller.apk
/sbin/fix_permissions -l -v -f Phone.apk
/sbin/fix_permissions -l -v -f Phonesky.apk
/sbin/fix_permissions -l -v -f ROMControl.apk
/sbin/fix_permissions -l -v -f Settings.apk
/sbin/fix_permissions -l -v -f SettingsProvider.apk
/sbin/fix_permissions -l -v -f Superuser.apk
/sbin/fix_permissions -l -v -f SystemUI.apk
/sbin/fix_permissions -l -v -f VpnDialogs.apk
)&

# Run my modules
/sbin/busybox sh /sbin/ext/modules.sh

# enable kmem interface for everyone by GM.
echo 0 > /proc/sys/kernel/kptr_restrict

#For now static freq 1500->100
echo 1500 1400 1300 1200 1100 1000 900 800 700 600 500 400 300 200 100 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies

# Set color mode to user mode
echo "1" > /sys/devices/platform/samsung-pd.2/mdnie/mdnie/mdnie/user_mode

# Start ROM VM boot!
start

