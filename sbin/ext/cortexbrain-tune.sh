#!/sbin/busybox sh

#Credits:
# Zacharias.maladroit
# Voku1987
# Collin_ph@xda
# Dorimanx@xda
# Gokhanmoral@xda

# TAKE NOTE THAT LINES PRECEDED BY A "#" IS COMMENTED OUT!
# This script must be activated after init start =< 25sec or parameters from /sys/* will not be loaded!

# read setting from profile
PROFILE=$(cat /data/.siyah/.active.profile);
. /data/.siyah/$PROFILE.profile;

FILE_NAME=$0
MAX_TEMP=500; # -> 50° Celsius
PIDOFCORTEX=$$;

# Functions triggers.
TOUCHSCREENTUNE_ENABLED=0;
IO_TWEAKS_ENABLED=1;
KERNEL_TWEAKS_ENABLED=1;
SYSTEM_TWEAKS_ENABLED=1;
BATTERY_TWEAKS_ENABLED=1;
CPU_GOV_TWEAKS_ENABLED=1;
CPU_SCHED_TWEAKS_ENABLED=0;
MEMORY_TWEAKS_ENABLED=1;
TCP_TWEAKS_ENABLED=1;
RIL_TWEAKS_ENABLED=0;
FIREWALL_TWEAKS_ENABLED=1;
BACKGROUND_PROCESS_ENABLED=0;

# Static sets for functions, they will be changes by other functions later.
if [[ "$PROFILE" == "performance" ]]; then
	MORE_SPEED=1;
	MORE_BATTERY=0;
	DEFAULT_SPEED=0;
elif [[ "$PROFILE" == "default" ]]; then
	MORE_SPEED=0;
	DEFAULT_SPEED=1;
	MORE_BATTERY=0;
else
	MORE_BATTERY=1;
	MORE_SPEED=0;
	DEFAULT_SPEED=0;
fi;

# ==============================================================
# Touch Screen tweaks
# ==============================================================

TOUCHSCREENTUNE() 
{
# touch sensitivity settings. by GokhanMoral
(
# offset 59: MXT224_THRESHOLD_BATT_INIT
kmemhelper -n mxt224_data -t char -o 59 50
# offset 60: MXT224_THRESHOLD_CHRG
kmemhelper -n mxt224_data -t char -o 60 55
# offset 61: MXT224_NOISE_THRESHOLD_BATT
kmemhelper -n mxt224_data -t char -o 61 30
# offset 62: MXT224_NOISE_THRESHOLD_CHRG
kmemhelper -n mxt224_data -t char -o 62 40
# offset 63: MXT224_MOVFILTER_BATT
kmemhelper -n mxt224_data -t char -o 63 11
# offset 64: MXT224_MOVFILTER_CHRG
kmemhelper -n mxt224_data -t char -o 64 46
# offset 67: MXT224E_THRESHOLD_BATT
kmemhelper -n mxt224_data -t char -o 67 50
# offset 77: MXT224E_MOVFILTER_BATT
kmemhelper -n mxt224_data -t char -o 77 46
)&
}
if [ $TOUCHSCREENTUNE_ENABLED == 1 ]; then
	TOUCHSCREENTUNE;
fi;

# =========
# Renice - kernel thread responsible for managing the memory
# =========
renice 10 `pidof kswapd0`;
renice 10 `pgrep logcat`;

# ==============================================================
# I/O-TWEAKS 
# ==============================================================
IO_TWEAKS()
{
MMC=`ls -d /sys/block/mmc*`;
ZRM=`ls -d /sys/block/zram*`;

for z in $ZRM; do

	if [ -e $i/queue/rotational ]; then
		echo "0" > $i/queue/rotational;
	fi;

	if [ -e $i/queue/iostats ]; then
		echo "0" > $i/queue/iostats;
	fi;

	if [ -e $i/queue/rq_affinity ]; then
		echo "1" > $i/queue/rq_affinity;
	fi;

	if [ -e $i/queue/read_ahead_kb ]; then
		echo "512" >  $i/queue/read_ahead_kb;
	fi;

done;

for i in $MMC; do

	if [ -e $i/queue/rotational ]; then
		echo "0" > $i/queue/rotational;
	fi;

	if [ -e $i/queue/iostats ]; then
		echo "0" > $i/queue/iostats;
	fi;

	if [ -e $i/queue/rq_affinity ]; then
		echo "1" > $i/queue/rq_affinity;   
	fi;

	if [ -e $i/queue/read_ahead_kb ]; then
		echo "1024" >  $i/queue/read_ahead_kb;
	fi;

#	if [ -e $i/queue/nr_requests ]; then
#		echo "8192" > $i/queue/nr_requests;
#	fi; # it's not wise to mess with NR and amount is very high. best default 128

	if [ -e $i/queue/iosched/writes_starved ]; then
		echo "2" > $i/queue/iosched/writes_starved;
	fi;

	if [ -e $i/queue/iosched/back_seek_max ]; then
		echo "1000000000" > $i/queue/iosched/back_seek_max;
	fi;

	if [ -e $i/queue/iosched/back_seek_penalty ]; then
		echo "1" > $i/queue/iosched/back_seek_penalty;
	fi;

	if [ -e $i/queue/iosched/slice_idle ]; then
		echo "0" > $i/queue/iosched/slice_idle;
	fi;

	if [ -e $i/queue/iosched/quantum ]; then
		echo "8" > $i/queue/iosched/quantum;
	fi;

	if [ -e $i/queue/iosched/slice_async_rq ]; then
		echo "4" > $i/queue/iosched/slice_async_rq;
	fi;

	if [ -e $i/queue/iosched/fifo_batch ]; then
		echo "1" > $i/queue/iosched/fifo_batch;
	fi;

	if [ -e $i/queue/iosched/rev_penalty ]; then
		echo "1" > $i/queue/iosched/rev_penalty;
	fi;

	if [ -e $i/queue/iosched/low_latency ]; then
		echo "1" > $i/queue/iosched/low_latency;
	fi;

done;

SDCARDREADAHEAD=`ls -d /sys/devices/virtual/bdi/179*`
for i in $SDCARDREADAHEAD; do
	echo 1024 > $i/read_ahead_kb;
done;

if [ -e /sys/devices/virtual/bdi/default/read_ahead_kb ]; then
        echo "512" > /sys/devices/virtual/bdi/default/read_ahead_kb;
fi;

# remount all partitions with noatime, nodiratime
sync;
for k in $(/sbin/busybox mount | /sbin/busybox grep relatime | /sbin/busybox grep -v /acct | /sbin/busybox grep -v /dev/cpuctl | cut -d " " -f3); do
	/sbin/busybox mount -o remount,noatime,nodiratime $k;
done;

# remount ext4 partitions with optimizations
for k in $(/sbin/busybox mount | /sbin/busybox grep ext4 | /sbin/busybox cut -d " " -f3); do
	/sbin/busybox mount -o remount,noatime,nodiratime,commit=30 $k
done;
sync;

/sbin/busybox mount -o remount,rw,discard,nodev,inode_readahead_blks=2,barrier=0,commit=360,noauto_da_alloc,delalloc /cache;

/sbin/busybox mount -o remount,rw,discard,nodev,inode_readahead_blks=2,barrier=0,commit=30,noauto_da_alloc,delalloc /data;

/sbin/busybox mount -o remount,rw,discard,inode_readahead_blks=2,barrier=1,commit=120 /system;
sync;

echo "15" > /proc/sys/fs/lease-break-time;

log -p i -t $FILE_NAME "*** filesystem tweaks ***: enabled";
}
if [ $IO_TWEAKS_ENABLED == 1 ]; then
	IO_TWEAKS;
fi;

# ==============================================================
# KERNEL-TWEAKS
# ==============================================================
KERNEL_TWEAKS()
{
echo "0" > /proc/sys/vm/oom_kill_allocating_task;
sysctl -w vm.panic_on_oom=0
#sysctl -w kernel.sem="500 512000 100 2048";
#sysctl -w kernel.shmmax="268435456";
#echo "0" > /proc/sys/kernel/hung_task_timeout_secs;
#echo "64000" > /proc/sys/kernel/msgmni;
#echo "64000" > /proc/sys/kernel/msgmax;

log -p i -t $FILE_NAME "*** kernel tweaks ***: enabled";
}
if [ $KERNEL_TWEAKS_ENABLED == 1 ]; then
	KERNEL_TWEAKS;
fi;

# ==============================================================
# SYSTEM-TWEAKS
# ==============================================================
SYSTEM_TWEAKS()
{
# enable Hardware Rendering
#setprop video.accelerate.hw 1
#setprop debug.performance.tuning 1
#setprop debug.sf.hw 1
setprop persist.sys.use_dithering 1
#setprop persist.sys.ui.hw true # ->reported as problem maker in some roms.

# render UI with GPU
setprop hwui.render_dirty_regions false
setprop windowsmgr.max_events_per_sec 120
setprop profiler.force_disable_err_rpt 1
setprop profiler.force_disable_ulog 1

# Proximity tweak
setprop mot.proximity.delay 15

# more Tweaks
setprop dalvik.vm.execution-mode int:jit
setprop persist.adb.notify 0
setprop wifi.supplicant_scan_interval 360
setprop pm.sleep_mode 1

log -p i -t $FILE_NAME "*** system tweaks ***: enabled";
}
if [ $SYSTEM_TWEAKS_ENABLED == 1 ]; then
	SYSTEM_TWEAKS;
fi;

# ==============================================================
# CLEANING-TWEAKS
# ==============================================================
rm -rf /data/lost+found/* 2> /dev/null;
rm -rf /system/lost+found/* 2> /dev/null;
rm -rf /preload/lost+found/* 2> /dev/null;
rm -rf /cache/lost+found/* 2> /dev/null;
rm -rf /data/tombstones/* 2> /dev/null;
rm -rf /data/anr/* 2> /dev/null;

# ==============================================================
# BATTERY-TWEAKS
# ==============================================================

# Block access to debugger memory dumps writes, save power and safe flash drive.
chmod 400 /data/tombstones -R
chown drm:drm /data/tombstones -R

# Allow writing to critical folders
chmod 777 /data/anr -R
chown system:system /data/anr -R

BATTERY_TWEAKS()
{
#WIFI PM-FAST Support.
if [ -e /sys/module/dhd/parameters/wifi_pm ]; then
	echo "1" > /sys/module/dhd/parameters/wifi_pm
fi;

LEVEL=$(cat /sys/class/power_supply/battery/capacity);
CURR_ADC=$(cat /sys/class/power_supply/battery/batt_current_adc);
BATTFULL=$(cat /sys/class/power_supply/battery/batt_full_check);
# battery-calibration if battery is full
echo "*** LEVEL: $LEVEL - CUR: $CURR_ADC ***"
if [ "$LEVEL" == "100" ] && [ "$BATTFULL" == "1" ]; then
        rm -f /data/system/batterystats.bin;
		echo "battery-calibration done ...";
fi;

for i in $(ls /sys/bus/usb/devices/*/power/level);
do
	echo "auto" > $i;
done;

log -p i -t $FILE_NAME "*** battery tweaks ***: enabled";
}
if [ $BATTERY_TWEAKS_ENABLED == 1 ]; then
	BATTERY_TWEAKS;
fi;

# ==============================================================
# CPU-TWEAKS
# ==============================================================

CPU_SCHED_TWEAKS()
{
if [ -e /proc/sys/kernel/rr_interval ]; then
	# BFS
	echo "1" > /proc/sys/kernel/rr_interval;
	echo "100" > /proc/sys/kernel/iso_cpu;
else
	# For this to work you need CONFIG_SCHED_DEBUG=y set in kernel settings.
	if [ -e /proc/sys/kernel/sched_latency_ns ]; then
		# CFS
		echo "10000000" > /proc/sys/kernel/sched_latency_ns;
		echo "2000000" > /proc/sys/kernel/sched_wakeup_granularity_ns;
		echo "4000000" > /proc/sys/kernel/sched_min_granularity_ns;
		echo "-1" > /proc/sys/kernel/sched_rt_runtime_us;
		echo "100000" > /proc/sys/kernel/sched_rt_period_us;
	fi;
fi;
log -p i -t $FILE_NAME "*** cpu sched tweaks ***: enabled";
}
if [ $CPU_SCHED_TWEAKS_ENABLED == 1 ]; then
        CPU_SCHED_TWEAKS;
fi;

CPU_GOV_TWEAKS()
{
SYSTEM_GOVERNOR=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`

if [ $MORE_BATTERY == 1 ]; then

	if [ $SYSTEM_GOVERNOR == "ondemand" ]; then
		echo "95" > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold;
		echo "1" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor;
		echo "1" > /sys/devices/system/cpu/cpufreq/ondemand/down_differential;
		echo "160000" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate;
	fi;

        if [ $SYSTEM_GOVERNOR == "hyper" ]; then
                echo "95" > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold;
                echo "1" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor;
                echo "1" > /sys/devices/system/cpu/cpufreq/ondemand/down_differential;
                echo "160000" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate;
        fi;

	if [ $SYSTEM_GOVERNOR == "lulzactive" ]; then
		echo "90" > /sys/devices/system/cpu/cpufreq/lulzactive/inc_cpu_load;
		echo "1" > /sys/devices/system/cpu/cpufreq/lulzactive/pump_up_step;
		echo "2" > /sys/devices/system/cpu/cpufreq/lulzactive/pump_down_step;
		echo "50000" > /sys/devices/system/cpu/cpufreq/lulzactive/up_sample_time;
		echo "40000" > /sys/devices/system/cpu/cpufreq/lulzactive/down_sample_time;
		echo "6" > /sys/devices/system/cpu/cpufreq/lulzactive/screen_off_min_step;
	fi;

	if [ $SYSTEM_GOVERNOR == "smartassV2" ]; then
		echo "800000" > /sys/devices/system/cpu/cpufreq/smartass/awake_ideal_freq;
		echo "100000" > /sys/devices/system/cpu/cpufreq/smartass/sleep_ideal_freq;
		echo "800000" > /sys/devices/system/cpu/cpufreq/smartass/sleep_wakeup_freq
		echo "95" > /sys/devices/system/cpu/cpufreq/smartass/max_cpu_load;
		echo "40" > /sys/devices/system/cpu/cpufreq/smartass/min_cpu_load;
		echo "200000" > /sys/devices/system/cpu/cpufreq/smartass/ramp_up_step;
		echo "200000" > /sys/devices/system/cpu/cpufreq/smartass/ramp_down_step;
		echo "48000" > /sys/devices/system/cpu/cpufreq/smartass/up_rate_us
		echo "49000" > /sys/devices/system/cpu/cpufreq/smartass/down_rate_us
	fi;

	if [ $SYSTEM_GOVERNOR == "conservative" ]; then
		echo "10" > /sys/devices/system/cpu/cpufreq/conservative/freq_step;
		echo "1" > /sys/devices/system/cpu/cpufreq/conservative/sampling_down_factor;
		echo "40" > /sys/devices/system/cpu/cpufreq/conservative/down_threshold;
		echo "95" > /sys/devices/system/cpu/cpufreq/conservative/up_threshold;
		echo "160000" > /sys/devices/system/cpu/cpufreq/conservative/sampling_rate;
	fi;

	if [ $SYSTEM_GOVERNOR == "hotplug" ]; then
		echo "1" > /sys/devices/system/cpu/cpufreq/hotplug/down_differential;
		echo "40" > /sys/devices/system/cpu/cpufreq/hotplug/down_threshold;
		echo "95" > /sys/devices/system/cpu/cpufreq/hotplug/up_threshold;
		echo "160000" > /sys/devices/system/cpu/cpufreq/hotplug/sampling_rate;
	fi;

	if [ $SYSTEM_GOVERNOR == "abyssplug" ]; then
		echo "1" > /sys/devices/system/cpu/cpufreq/abyssplug/down_differential;
		echo "40" > /sys/devices/system/cpu/cpufreq/abyssplug/down_threshold;
		echo "95" > /sys/devices/system/cpu/cpufreq/abyssplug/up_threshold;
		echo "160000" > /sys/devices/system/cpu/cpufreq/abyssplug/sampling_rate;
        fi;

elif [ $DEFAULT_SPEED == 1 ]; then

        if [ $SYSTEM_GOVERNOR == "ondemand" ]; then
                echo "80" > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold;
                echo "2" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor;
                echo "1" > /sys/devices/system/cpu/cpufreq/ondemand/down_differential;
                echo "120000" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate;
        fi;

        if [ $SYSTEM_GOVERNOR == "hyper" ]; then
                echo "60" > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold;
                echo "5" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor;
                echo "1" > /sys/devices/system/cpu/cpufreq/ondemand/down_differential;
                echo "120000" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate;
        fi;

        if [ $SYSTEM_GOVERNOR == "lulzactive" ]; then
                echo "80" > /sys/devices/system/cpu/cpufreq/lulzactive/inc_cpu_load;
                echo "1" > /sys/devices/system/cpu/cpufreq/lulzactive/pump_up_step;
                echo "2" > /sys/devices/system/cpu/cpufreq/lulzactive/pump_down_step;
                echo "50000" > /sys/devices/system/cpu/cpufreq/lulzactive/up_sample_time;
                echo "40000" > /sys/devices/system/cpu/cpufreq/lulzactive/down_sample_time;
                echo "6" > /sys/devices/system/cpu/cpufreq/lulzactive/screen_off_min_step;
        fi;

        if [ $SYSTEM_GOVERNOR == "smartassV2" ]; then
                echo "800000" > /sys/devices/system/cpu/cpufreq/smartass/awake_ideal_freq;
                echo "100000" > /sys/devices/system/cpu/cpufreq/smartass/sleep_ideal_freq;
                echo "800000" > /sys/devices/system/cpu/cpufreq/smartass/sleep_wakeup_freq
                echo "80" > /sys/devices/system/cpu/cpufreq/smartass/max_cpu_load;
                echo "30" > /sys/devices/system/cpu/cpufreq/smartass/min_cpu_load;
                echo "200000" > /sys/devices/system/cpu/cpufreq/smartass/ramp_up_step;
                echo "200000" > /sys/devices/system/cpu/cpufreq/smartass/ramp_down_step;
                echo "48000" > /sys/devices/system/cpu/cpufreq/smartass/up_rate_us
                echo "49000" > /sys/devices/system/cpu/cpufreq/smartass/down_rate_us
        fi;

        if [ $SYSTEM_GOVERNOR == "conservative" ]; then
                echo "30" > /sys/devices/system/cpu/cpufreq/conservative/freq_step;
                echo "1" > /sys/devices/system/cpu/cpufreq/conservative/sampling_down_factor;
                echo "30" > /sys/devices/system/cpu/cpufreq/conservative/down_threshold;
                echo "80" > /sys/devices/system/cpu/cpufreq/conservative/up_threshold;
                echo "120000" > /sys/devices/system/cpu/cpufreq/conservative/sampling_rate;
        fi;

        if [ $SYSTEM_GOVERNOR == "hotplug" ]; then
                echo "1" > /sys/devices/system/cpu/cpufreq/hotplug/down_differential;
                echo "30" > /sys/devices/system/cpu/cpufreq/hotplug/down_threshold;
                echo "80" > /sys/devices/system/cpu/cpufreq/hotplug/up_threshold;
                echo "120000" > /sys/devices/system/cpu/cpufreq/hotplug/sampling_rate;
        fi;

        if [ $SYSTEM_GOVERNOR == "abyssplug" ]; then
                echo "2" > /sys/devices/system/cpu/cpufreq/abyssplug/down_differential;
                echo "30" > /sys/devices/system/cpu/cpufreq/abyssplug/down_threshold;
                echo "80" > /sys/devices/system/cpu/cpufreq/abyssplug/up_threshold;
                echo "120000" > /sys/devices/system/cpu/cpufreq/abyssplug/sampling_rate;
        fi;
else
	if [ $MORE_SPEED == 1 ]; then

		if [ $SYSTEM_GOVERNOR == "ondemand" ]; then
			echo "60" > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold;
			echo "1" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor;
			echo "5" > /sys/devices/system/cpu/cpufreq/ondemand/down_differential;
			echo "100000" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate;
		fi;


		if [ $SYSTEM_GOVERNOR == "hyper" ]; then
 			echo "50" > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold;
			echo "1" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor;
			echo "5" > /sys/devices/system/cpu/cpufreq/ondemand/down_differential;
			echo "100000" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate;
		fi;

		if [ $SYSTEM_GOVERNOR == "lulzactive" ]; then
			echo "60" > /sys/devices/system/cpu/cpufreq/lulzactive/inc_cpu_load;
			echo "4" > /sys/devices/system/cpu/cpufreq/lulzactive/pump_up_step;
			echo "1" > /sys/devices/system/cpu/cpufreq/lulzactive/pump_down_step;
			echo "10000" > /sys/devices/system/cpu/cpufreq/lulzactive/up_sample_time;
			echo "70000" > /sys/devices/system/cpu/cpufreq/lulzactive/down_sample_time;
			echo "5" > /sys/devices/system/cpu/cpufreq/lulzactive/screen_off_min_step;
		fi;

		if [ $SYSTEM_GOVERNOR == "smartassV2" ]; then
			echo "800000" > /sys/devices/system/cpu/cpufreq/smartass/awake_ideal_freq;
			echo "200000" > /sys/devices/system/cpu/cpufreq/smartass/sleep_ideal_freq;
			echo "800000" > /sys/devices/system/cpu/cpufreq/smartass/sleep_wakeup_freq
			echo "60" > /sys/devices/system/cpu/cpufreq/smartass/max_cpu_load;
			echo "30" > /sys/devices/system/cpu/cpufreq/smartass/min_cpu_load;
			echo "0" > /sys/devices/system/cpu/cpufreq/smartass/ramp_up_step;
			echo "0" > /sys/devices/system/cpu/cpufreq/smartass/ramp_down_step;
			echo "24000" > /sys/devices/system/cpu/cpufreq/smartass/up_rate_us;
			echo "99000" > /sys/devices/system/cpu/cpufreq/smartass/down_rate_us;
		fi;

		if [ $SYSTEM_GOVERNOR == "conservative" ]; then
			echo "40" > /sys/devices/system/cpu/cpufreq/conservative/freq_step;
			echo "5" > /sys/devices/system/cpu/cpufreq/conservative/sampling_down_factor;
			echo "20" > /sys/devices/system/cpu/cpufreq/conservative/down_threshold;
			echo "60" > /sys/devices/system/cpu/cpufreq/conservative/up_threshold;
			echo "80000" > /sys/devices/system/cpu/cpufreq/conservative/sampling_rate;
		fi;

		if [ $SYSTEM_GOVERNOR == "hotplug" ]; then
			echo "1" > /sys/devices/system/cpu/cpufreq/hotplug/down_differential;
			echo "25" > /sys/devices/system/cpu/cpufreq/hotplug/down_threshold;
			echo "60" > /sys/devices/system/cpu/cpufreq/hotplug/up_threshold;
			echo "100000" > /sys/devices/system/cpu/cpufreq/hotplug/sampling_rate;
		fi;

		if [ $SYSTEM_GOVERNOR == "abyssplug" ]; then
			echo "1" > /sys/devices/system/cpu/cpufreq/abyssplug/down_differential;
			echo "25" > /sys/devices/system/cpu/cpufreq/abyssplug/down_threshold;
			echo "60" > /sys/devices/system/cpu/cpufreq/abyssplug/up_threshold;
			echo "100000" > /sys/devices/system/cpu/cpufreq/abyssplug/sampling_rate;
		fi;

	fi;

fi;
log -p i -t $FILE_NAME "*** cpu gov tweaks ***: enabled";
}
if [ $CPU_GOV_TWEAKS_ENABLED == 1 ]; then
	CPU_GOV_TWEAKS;
fi;

# ==============================================================
# MEMORY-TWEAKS
# ==============================================================
MEMORY_TWEAKS()
{
echo "300" > /proc/sys/vm/dirty_expire_centisecs;
echo "1500" > /proc/sys/vm/dirty_writeback_centisecs;
echo "15" > /proc/sys/vm/dirty_background_ratio;
echo "10" > /proc/sys/vm/dirty_ratio;
echo "4" > /proc/sys/vm/min_free_order_shift;
echo "0" > /proc/sys/vm/overcommit_memory;
echo "96 96" > /proc/sys/vm/lowmem_reserve_ratio;
echo "3" > /proc/sys/vm/page-cluster;
echo "1000" > /proc/sys/vm/overcommit_ratio;
echo "4096" > /proc/sys/vm/min_free_kbytes
echo "50" > /proc/sys/vm/vfs_cache_pressure;

# Define the memory thresholds at which the above process classes will
# be killed. These numbers are in pages (4k) -> (1 MB * 1024) / 4 = 256
#FOREGROUND_APP_MEM=8192;
#VISIBLE_APP_MEM=10240;
#SECONDARY_SERVER_MEM=12288;
#BACKUP_APP_MEM=12288;
#HOME_APP_MEM=12288;
#HIDDEN_APP_MEM=14336;
#CONTENT_PROVIDER_MEM=16384;
#EMPTY_APP_MEM=20480;
#echo "$FOREGROUND_APP_MEM,$VISIBLE_APP_MEM,$SECONDARY_SERVER_MEM,$HIDDEN_APP_MEM,$CONTENT_PROVIDER_MEM,$EMPTY_APP_MEM" > /sys/module/lowmemorykiller/parameters/minfree;

log -p i -t $FILE_NAME "*** memory tweaks ***: enabled";
}
if [ $MEMORY_TWEAKS_ENABLED == 1 ]; then
	MEMORY_TWEAKS;
fi;

# ==============================================================
# TCP-TWEAKS
# ==============================================================
TCP_TWEAKS()
{
echo "0" > /proc/sys/net/ipv4/tcp_timestamps;
echo "1" > /proc/sys/net/ipv4/tcp_tw_reuse;
echo "1" > /proc/sys/net/ipv4/tcp_sack;
echo "1" > /proc/sys/net/ipv4/tcp_tw_recycle;
echo "1" > /proc/sys/net/ipv4/tcp_window_scaling;
echo "1" > /proc/sys/net/ipv4/tcp_moderate_rcvbuf;
echo "1" > /proc/sys/net/ipv4/route/flush;
echo "5" > /proc/sys/net/ipv4/tcp_keepalive_probes;
echo "30" > /proc/sys/net/ipv4/tcp_keepalive_intvl;
echo "30" > /proc/sys/net/ipv4/tcp_fin_timeout;
echo "256960" > /proc/sys/net/core/wmem_max;
echo "563200" > /proc/sys/net/core/rmem_max;
echo "256960" > /proc/sys/net/core/rmem_default;
echo "256960" > /proc/sys/net/core/wmem_default;
echo "20480" > /proc/sys/net/core/optmem_max;
echo "4096 16384 110208" > /proc/sys/net/ipv4/tcp_wmem;
echo "4096 87380 563200" > /proc/sys/net/ipv4/tcp_rmem;
echo "4096" > /proc/sys/net/ipv4/udp_rmem_min;
echo "4096" > /proc/sys/net/ipv4/udp_wmem_min;
setprop net.tcp.buffersize.default 4096,87380,563200,4096,16384,110208;
setprop net.tcp.buffersize.wifi    4095,87380,563200,4096,16384,110208;
setprop net.tcp.buffersize.umts    4094,87380,563200,4096,16384,110208;
setprop net.tcp.buffersize.edge    4093,26280,35040,4096,16384,35040;
setprop net.tcp.buffersize.gprs    4092,8760,11680,4096,8760,11680;
setprop net.tcp.buffersize.evdo_b  4094,87380,262144,4096,16384,262144;
setprop net.tcp.buffersize.hspa    4092,87380,563200,4096,16384,110208;

log -p i -t $FILE_NAME "*** tcp tweaks ***: enabled";
}
if [ $TCP_TWEAKS_ENABLED == 1 ]; then
	TCP_TWEAKS;
fi;

# ==============================================================
# 3G/Edge - TWEAKS
# ==============================================================
RIL_TWEAKS()
{
setprop ro.ril.hsxpa 2;
setprop ro.ril.hsupa.category 14;
setprop ro.ril.hsdpa.category 6;
setprop ro.ril.gprsclass 12;

log -p i -t $FILE_NAME "*** 3G/Edge tweaks ***: enabled";
}
if [ $RIL_TWEAKS_ENABLED == 1 ]; then
	RIL_TWEAKS;
fi;

# ==============================================================
# FIREWALL-TWEAKS
# ==============================================================
FIREWALL_TWEAKS()
{
# ping/icmp protection
echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts;
echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_all;
echo "1" > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses;

if [ -e /proc/sys/net/ipv6/icmp_echo_ignore_broadcasts ]; then
	echo "1" > /proc/sys/net/ipv6/icmp_echo_ignore_broadcasts;
fi

if [ -e /proc/sys/net/ipv6/icmp_echo_ignore_all ]; then
	echo "1" > /proc/sys/net/ipv6/icmp_echo_ignore_all;
fi

if [ -e /proc/sys/net/ipv6/icmp_ignore_bogus_error_responses ]; then
	echo "1" > /proc/sys/net/ipv6/icmp_ignore_bogus_error_responses;
fi

# syn protection
if [ -e /proc/sys/net/ipv4/tcp_synack_retries ]; then
	echo "10" > /proc/sys/net/ipv4/tcp_synack_retries;
fi

if [ -e /proc/sys/net/ipv6/tcp_synack_retries ]; then
	echo "10" > /proc/sys/net/ipv6/tcp_synack_retries;
fi

if [ -e /proc/sys/net/ipv6/tcp_syncookies ]; then
	echo "0" > /proc/sys/net/ipv6/tcp_syncookies;
fi

if [ -e /proc/sys/net/ipv4/tcp_syncookies ]; then
	echo "3" > /proc/sys/net/ipv4/tcp_syncookies;
fi

# IPv6 privacy tweak
echo "2" > /proc/sys/net/ipv6/conf/all/use_tempaddr;

# drop spoof, redirects, etc
echo "1" > /proc/sys/net/ipv4/conf/all/rp_filter;
echo "1" > /proc/sys/net/ipv4/conf/default/rp_filter;
echo "0" > /proc/sys/net/ipv4/conf/all/send_redirects;
echo "0" > /proc/sys/net/ipv4/conf/default/send_redirects;
echo "0" > /proc/sys/net/ipv4/conf/default/accept_redirects;
echo "0" > /proc/sys/net/ipv4/conf/all/accept_source_route;
echo "0" > /proc/sys/net/ipv4/conf/default/accept_source_route;

if [ -e /proc/sys/net/ipv6/conf/all/rp_filter ]; then
	echo "1" > /proc/sys/net/ipv6/conf/all/rp_filter;
fi

if [ -e /proc/sys/net/ipv6/conf/default/rp_filter ]; then
	echo "1" > /proc/sys/net/ipv6/conf/default/rp_filter;
fi

if [ -e /proc/sys/net/ipv6/conf/all/send_redirects ]; then
	echo "0" > /proc/sys/net/ipv6/conf/all/send_redirects;
fi

if [ -e /proc/sys/net/ipv6/conf/default/send_redirects ]; then
	echo "0" > /proc/sys/net/ipv6/conf/default/send_redirects;
fi

if [ -e /proc/sys/net/ipv6/conf/default/accept_redirects ]; then
	echo "0" > /proc/sys/net/ipv6/conf/default/accept_redirects;
fi

if [ -e /proc/sys/net/ipv6/conf/all/accept_source_route ]; then
	echo "0" > /proc/sys/net/ipv6/conf/all/accept_source_route;
fi

if [ -e /proc/sys/net/ipv6/conf/default/accept_source_route ]; then
	echo "0" > /proc/sys/net/ipv6/conf/default/accept_source_route;
fi

log -p i -t $FILE_NAME "*** firewall-tweaks ***: enabled";
}
if [ $FIREWALL_TWEAKS_ENABLED == 1 ]; then
	FIREWALL_TWEAKS;
fi;

# ==============================================================
# check for temperature
# ==============================================================
CHECK_TEMPERATURE()
{
TEMP=`cat /sys/class/power_supply/battery/batt_temp`;
if [ $TEMP -ge $MAX_TEMP ]; then
	echo "conservative" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
	echo "800000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
	log -p i -t $FILE_NAME "*** TEMPERATURE over $(( ${MAX_TEMP} / 10 ))° ***";
	exit;
fi;
}
CHECK_TEMPERATURE;

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{

# check for temperature
CHECK_TEMPERATURE;

# Restore Smooth Level
kmemhelper -n smooth_level -o 0 -t int $smooth_level0 

# charging & screen is on
CHARGING=`cat /sys/class/power_supply/battery/charging_source`;
if [ $CHARGING -ge 1 ]; then

	# cpu - Always dual core
	echo "off" > /sys/devices/virtual/misc/second_core/hotplug_on;
	echo "on" > /sys/devices/virtual/misc/second_core/second_core_on;

        # CPU-Freq
        echo "hyper" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
	echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;

	# CPU Idle State - IDLE only
	echo "0" > /sys/module/cpuidle_exynos4/parameters/enable_mask;

        # Bus Freq for Powered Mod
        echo "3" > /sys/devices/system/cpu/cpufreq/busfreq_asv_group;
        echo "23" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;
        echo "23" > /sys/devices/system/cpu/cpufreq/busfreq_down_threshold;

        # load balancing - off
        echo "0" > /sys/devices/system/cpu/sched_mc_power_savings;

	MODE="SPEED";
else
	# set governor
        echo "$scaling_governor" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
	echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;

	# cpu - hotplug=1 core online second on demand
	echo "on" > /sys/devices/virtual/misc/second_core/hotplug_on;
	echo "off" > /sys/devices/virtual/misc/second_core/second_core_on;

	# cpu - settings for second core
	echo "$load_h0" > /sys/module/stand_hotplug/parameters/load_h0;
	echo "$load_l1" > /sys/module/stand_hotplug/parameters/load_l1;

	# Bus Freq for deep sleep
	echo "$busfreq_asv_group" > /sys/devices/system/cpu/cpufreq/busfreq_asv_group;
	echo "$busfreq_up_threshold" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;
	echo "$busfreq_down_threshold" > /sys/devices/system/cpu/cpufreq/busfreq_down_threshold;

        # CPU Idle State
        echo "$enable_mask" > /sys/module/cpuidle_exynos4/parameters/enable_mask;

	# value from settings
	echo "$sched_mc_power_savings" > /sys/devices/system/cpu/sched_mc_power_savings;

	MODE="AWAKE";
fi;

if [ $BATTERY_TWEAKS_ENABLED == 1 ]; then
	BATTERY_TWEAKS;
fi;

if [ $CPU_GOV_TWEAKS_ENABLED == 1 ]; then
	if [[ "$PROFILE" == "performance" ]]; then
		MORE_SPEED=1;
		MORE_BATTERY=0;
		DEFAULT_SPEED=0;
	elif [[ "$PROFILE" == "default" ]]; then
		MORE_BATTERY=0;
		DEFAULT_SPEED=1;
		MORE_SPEED=0;
	else
		MORE_BATTERY=1;
		MORE_SPEED=0;
		DEFAULT_SPEED=0;
	fi;
	CPU_GOV_TWEAKS;
fi;

# Setting the vibrator force in case it's has been reseted.
echo "$pwm_val" > /sys/vibrator/pwm_val

log -p i -t $FILE_NAME "*** $MODE Mode ***";
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{

# check for temperature
CHECK_TEMPERATURE;

# charging & screen is off
CHARGING=`cat /sys/class/power_supply/battery/charging_source`;
if [ $CHARGING -ge 1 ]; then

	# CPU-Freq
	echo "$deep_sleep_ac" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;

	MODE="CHARGING";
else

	# CPU-Freq
	echo "$deep_sleep_batt" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;

	MODE="SLEEP";
fi;

# Reduce CPU max Speed to 800Mhz
echo "800000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;

# cpu - second core always-off
echo "off" > /sys/devices/virtual/misc/second_core/hotplug_on;
echo "off" > /sys/devices/virtual/misc/second_core/second_core_on;

# Bus Freq for deep sleep
echo "3" > /sys/devices/system/cpu/cpufreq/busfreq_asv_group
echo "45" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold
echo "45" > /sys/devices/system/cpu/cpufreq/busfreq_down_threshold

# Smooth Level set to 800Mhz just in case.
kmemhelper -n smooth_level -o 0 -t int 8

if [ $BATTERY_TWEAKS_ENABLED == 1 ]; then
	BATTERY_TWEAKS;
fi;
if [ $CPU_GOV_TWEAKS_ENABLED == 1 ]; then
	MORE_BATTERY=1;
	MORE_SPEED=0;
	DEFAULT_SPEED=0;
	CPU_GOV_TWEAKS;
fi;

# CPU Idle State - AFTR+LPA
echo "3" > /sys/module/cpuidle_exynos4/parameters/enable_mask;

# enable first core overloading
echo "1" > /sys/devices/system/cpu/sched_mc_power_savings;

# Setting the vibrator force in case it's has been reseted.
echo "$pwm_val" > /sys/vibrator/pwm_val

log -p i -t $FILE_NAME "*** $MODE mode ***";
}

# ==============================================================
# Background process to check screen state
# ==============================================================
if [ $BACKGROUND_PROCESS_ENABLED == 1 ]; then

	(while [ 1 ]; do
		# AWAKE State! all system ON!
		STATE=$(cat /sys/power/wait_for_fb_wake);
		/system/xbin/echo "-17" > /proc/${PIDOFCORTEX}/oom_adj;
		renice -10 ${PIDOFCORTEX};
		PROFILE=$(cat /data/.siyah/.active.profile);
		. /data/.siyah/$PROFILE.profile;
		AWAKE_MODE;
		sleep 5;

		# SLEEP state! All system to power save!
		STATE=$(cat /sys/power/wait_for_fb_sleep);
		PROFILE=$(cat /data/.siyah/.active.profile);
		. /data/.siyah/$PROFILE.profile;
		SLEEP_MODE;
		sleep 5;
	done &);
fi;

# ==============================================================
# Logic Explanations
#
# This script will manipulate all the system / cpu / battery behavior
# Based on chosen EXTWEAKS profile+tweaks and based on SCREEN ON/OFF state.
#
# When User select battery/default profile all tuning will be toward battery save!
# But user loose performance -20% and get more stable system and more battery left.
#
# When user select performance profile, tuning will be to max performance on screen ON!
# When screen OFF all tuning switched to max power saving! as with battery profile,
# So user gets max performance and max battery save but only on screen OFF.
#
# This script change governors and tuning for them on the fly!
# Also switch on/off hotplug CPU core based on screen on/off.
# This script reset battery stats when battery is 100% charged.
# This script tune Network and System VM settings and ROM settings tuning.
# This script changing default MOUNT options and I/O tweaks for all flash disks and ZRAM.
#
# TODO: add more description.
#

# ==============================================================
# Explanations
# ==============================================================
#
# scaling_governor: Using Frequency Scaling Governors -> cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
#
# 				-> http://publib.boulder.ibm.com/infocenter/lnxinfo/v3r0m0/index.jsp?topic=/liaai/cpufreq/TheOndemandGovernor.htm
#
# 				conservative - Increases frequency step by step, decreases instantly
# 				ondemand - Uses the highest CPU frequency when tasks are started, decreases step by step
# 				performance - CPU only runs at max frequency regardless of load
# 				powersave - CPU only runs at min frequency regardless of load
#
# 				echo "ondemand" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# swappiness: 	swappiness is a parameter which sets the kernel's balance between reclaiming pages from the page cache and swapping process memory. 
#				The default value is 60. If you want kernel to swap out more process memory and thus cache more file contents increase the value. 
#				Otherwise, if you would like kernel to swap less decrease it. A value of 0 means "do not swap unless out of free RAM", 
#				a value of 100 means "swap whenever possible". 
#
# 				echo XXX > /proc/sys/vm/swappiness;

# oom_kill_allocating_task:	If this is set to zero, the OOM killer will scan through the entire tasklist and select a task based on heuristics to kill. 
#				This normally selects a rogue memory-hogging task that frees up a large amount of memory when killed. 
#				If this is set to non-zero, the OOM killer simply kills the task that triggered the out-of-memory condition. 
#				This avoids the expensive tasklist scan.
#
# 				echo XXX > /proc/sys/vm/oom_kill_allocating_task;

# dirty_expire_centisecs: This tunable is used to define when dirty data is old enough to be eligible for writeout by the pdflush daemons. 
#				It is expressed in 100'ths of a second. Data which has been dirty in memory for longer than this interval will be written 
#				out next time a pdflush daemon wakes up.
#
# 				echo XXX > /proc/sys/vm/dirty_expire_centisecs;

# dirty_writeback_centisecs: The pdflush writeback daemons will periodically wake up and write "old" data out to disk. 
#				This tunable expresses the interval between those wakeups, in 100'ths of a second. 
#				Setting this to zero disables periodic writeback altogether.
#
# 				echo XXX > /proc/sys/vm/dirty_writeback_centisecs;

# drop_caches:	Writing to this will cause the kernel to drop clean caches, dentries and inodes from memory, causing that memory to become free.
#
#				To free pagecache:
# 				echo 1 > /proc/sys/vm/drop_caches
#
#				To free dentries and inodes:
# 				echo 2 > /proc/sys/vm/drop_caches
#
#				To free pagecache, dentries and inodes:
# 				echo 3 > /proc/sys/vm/drop_caches

# page-cluster: page-cluster controls the number of pages which are written to swap in a single attempt. The swap I/O size.
#				It is a logarithmic value - setting it to zero means "1 page", setting it to 1 means "2 pages", setting it to 2 means "4 pages", etc.
#				The default value is three (eight pages at a time). There may be some small benefits in tuning this to 
#				a different value if your workload is swap-intensive. (default 3)
#
# 				echo XXX > /proc/sys/vm/page-cluster;

# laptop_mode: 	laptop_mode is a knob that controls "laptop mode". When the knob is set, any physical disk I/O 
#				(that might have caused the hard disk to spin up, see /proc/sys/vm/block_dump) causes Linux to flush all dirty blocks. 
#				The result of this is that after a disk has spun down, it will not be spun up anymore to write dirty blocks, 
#				because those blocks had already been written immediately after the most recent read operation. 
#				The value of the laptop_mode knob determines the time between the occurrence of disk I/O and when the flush is triggered. 
#				A sensible value for the knob is 5 seconds. Setting the knob to 0 disables laptop mode.
#
# 				echo XXX > /proc/sys/vm/laptop_mode;

# rr_interval: 	rr_interval or "round robin interval". This is the maximum time two SCHED_OTHER (or SCHED_NORMAL, the common scheduling policy)
#				tasks of the same nice level will be running for, or looking at it the other way around, the longest duration two tasks 
#				of the same nice level will be delayed for. When a task requests cpu time, it is given a quota (time_slice) equal to the 
#				rr_interval and a virtual deadline, while increasing it will improve throughput, but at the cost of worsening latencies.
#
# 				echo XXX > /proc/sys/kernel/rr_interval;

# dirty_background_ratio: 	Contains, as a percentage of total system memory, the number of pages at which the pdflush background writeback daemon will 
#				start writing out dirty data.
#
# 				echo XXX > /proc/sys/vm/dirty_background_ratio;

# dirty_ratio:	Contains, as a percentage of total system memory, the number of pages at which a process which is generating disk writes will itself start writing out dirty data.
#
# 				echo XXX > /proc/sys/vm/dirty_ratio;

# iso_cpu:		Setting this to 100 is the equivalent of giving all users SCHED_RR access and setting it to 0 removes the
#				ability to run any pseudo-realtime tasks.
#
# 				echo XXX > /proc/sys/kernel/iso_cpu;

# vfs_cache_pressure: Controls the tendency of the kernel to reclaim the memory which is used for caching of directory and inode objects.
#				At the default value of vfs_cache_pressure = 100 the kernel will attempt to reclaim dentries and inodes at a "fair" rate with respect 
#				to pagecache and swapcache reclaim. Decreasing vfs_cache_pressure causes the kernel to prefer to retain dentry and inode caches. 
#				Increasing vfs_cache_pressure beyond 100 causes the kernel to prefer to reclaim dentries and inodes.
#
# 				echo XXX > /proc/sys/vm/vfs_cache_pressure;

# min_free_kbytes: This is used to force the Linux VM to keep a minimum number of kilobytes free. The VM uses this number to compute a pages_min value 
#				for each lowmem zone in the system. Each lowmem zone gets a number of reserved free pages based proportionally on its size.
#
# 				echo XXX > /proc/sys/vm/min_free_kbytes;

# sched_latency_ns: Targeted preemption latency for CPU-bound tasks.
#
# 				echo XXX > /proc/sys/kernel/sched_latency_ns;

# sched_batch_wakeup_granularity_ns: Wake-up granularity for SCHED_BATCH.
#
# 				echo XXX > /proc/sys/kernel/sched_batch_wakeup_granularity_ns;

# sched_wakeup_granularity_ns: 	Wake-up granularity for SCHED_OTHER.
#
# 				echo XXX > /proc/sys/kernel/sched_wakeup_granularity_ns;

# sched_compat_yield: 		Applications depending heavily on sched_yield()'s behavior can expect varied performance because of the way CFS changes this, 
#				so turning on the sysctls is recommended.
#
# 				echo XXX > /proc/sys/kernel/sched_compat_yield;

# sched_child_runs_first: 	The child is scheduled next after fork; it's the default. If set to 0, then the parent is given the baton.
#
# 				echo XXX > /proc/sys/kernel/sched_child_runs_first;

# sched_min_granularity_ns:	Minimum preemption granularity for CPU-bound tasks.
#
# 				echo XXX > /proc/sys/kernel/sched_min_granularity_ns;

# sched_features: NO_NEW_FAIR_SLEEPERS is something that will turn the scheduler into a more classic fair scheduler ?!?
#
# 				echo NO_NORMALIZED_SLEEPER > /sys/kernel/debug/sched_features;

# sched_stat_granularity_ns: Granularity for collecting scheduler statistics. [1/0]
#
# 				echo XXX  > /proc/sys/kernel/sched_stat_granularity_ns;

# sched_rt_period_us: The default values for sched_rt_period_us (1000000 or 1s) and sched_rt_runtime_us (950000 or 0.95s).  
#				This gives 0.05s to be used by SCHED_OTHER (non-RT tasks). These defaults were chosen so that a run-away realtime 
#				tasks will not lock up the machine but leave a little time to recover it. By setting runtime to -1 you get the old behaviour back.

# threads-max: Gets/sets the limit on the maximum number of running threads system-wide.
#
# 				echo XXX > /proc/sys/kernel/threads-max;

# msgmni: 		The msgmni tunable specifies the maximum number of system-wide System V IPC message queue 
#				identifiers (one per queue).
#
# 				echo XXX > /proc/sys/kernel/msgmni;

# sem: 			This file contains 4 numbers defining limits for System V IPC semaphores. These fields are, in order:
#
# 				SEMMSL - the maximum number of semaphores per semaphore set.
# 				SEMMNS - a system-wide limit on the number of semaphores in all semaphore sets.
# 				SEMOPM - the maximum number of operations that may be specified in a semop(2) call.
# 				SEMMNI - a system-wide limit on the maximum number of semaphore identifiers.
#
# 				The default values are "250 32000 32 128".
#
# 				echo XXX XXX XXX XXX > /proc/sys/kernel/sem;

# read_ahead_kb: Optimize for read-throughput (cache-value)
#
# 				example of C program for finding correct vaules for Linux 
# 				-> http://pastebin.com/Rg6qVJQH
#
