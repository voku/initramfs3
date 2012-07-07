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

# Get values from profile.
PROFILE=$(cat /data/.siyah/.active.profile);
. /data/.siyah/$PROFILE.profile;

# overwrite settings if needed ...
if [ "a$1" != "a" ]; then
	cortexbrain_background_process=$1;
fi;

FILE_NAME=$0
MAX_TEMP=500; # -> 50° Celsius
PIDOFCORTEX=`pgrep -f "/sbin/busybox sh /sbin/ext/cortexbrain-tune.sh"`;

# default settings
dirty_expire_centisecs_default=300;
dirty_writeback_centisecs_default=1500;
dirty_background_ratio_default=15;
dirty_ratio_default=10;

# battery settings
dirty_expire_centisecs_battery=0;
dirty_writeback_centisecs_battery=0;
dirty_background_ratio_battery=60;
dirty_ratio_battery=95;

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
# Not needed any more, we have extweaks interface for it! so never enable it!
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
#TOUCHSCREENTUNE; #DISABLED for good, but it's good info. so no delete.

# =========
# Renice - kernel thread responsible for managing the memory
# =========
renice 19 `pidof kswapd0`;
renice 19 `pgrep logcat`;

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

	if [ -e $i/queue/max_sectors_kb ]; then
		echo "512" >  $i/queue/max_sectors_kb; # default: 127
	fi;

done;

for i in $MMC; do

	if [ -e $i/queue/scheduler ]; then
		echo $scheduler > $i/queue/scheduler;
	fi;

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
		echo "1024" >  $i/queue/read_ahead_kb; # default: 128
	fi;

	if [ -e $i/queue/max_sectors_kb ]; then
		echo "1024" >  $i/queue/max_sectors_kb; # default: 512
	fi;

	if [ -e $i/queue/nr_requests ]; then
		echo "128" > $i/queue/nr_requests; # default: 128
	fi;

	if [ -e $i/queue/iosched/writes_starved ]; then
		echo "2" > $i/queue/iosched/writes_starved;
	fi;

	if [ -e $i/queue/iosched/back_seek_max ]; then
		echo "16384" > $i/queue/iosched/back_seek_max; # default: 16384
	fi;

	if [ -e $i/queue/iosched/max_budget_async_rq ]; then
		echo "2" > $i/queue/iosched/max_budget_async_rq; # default: 4
	fi;

	if [ -e $i/queue/iosched/back_seek_penalty ]; then
		echo "1" > $i/queue/iosched/back_seek_penalty; # default: 2
	fi;

	if [ -e $i/queue/iosched/fifo_expire_sync ]; then
		echo "125" > $i/queue/iosched/fifo_expire_sync; # default: 125
	fi;

	if [ -e $i/queue/iosched/timeout_sync ]; then
		echo "4" > $i/queue/iosched/timeout_sync; # default: HZ / 8
	fi;

	if [ -e $i/queue/iosched/fifo_expire_async ]; then
		echo "250" > $i/queue/iosched/fifo_expire_async; # default: 250
	fi;

	if [ -e $i/queue/iosched/timeout_async ]; then
		echo "2" > $i/queue/iosched/timeout_async; # default: HZ / 25
	fi;

	if [ -e $i/queue/iosched/slice_idle ]; then
		echo "2" > $i/queue/iosched/slice_idle; # default: 8
	fi;

	if [ -e $i/queue/iosched/quantum ]; then
		echo "8" > $i/queue/iosched/quantum; # default: 4
	fi;

	if [ -e $i/queue/iosched/slice_async_rq ]; then
		echo "2" > $i/queue/iosched/slice_async_rq; # default: 2
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

SDCARDREADAHEAD=`ls -d /sys/devices/virtual/bdi/179*`;
for i in $SDCARDREADAHEAD; do
	echo 1024 > $i/read_ahead_kb;
done;

if [ -e /sys/devices/virtual/bdi/default/read_ahead_kb ]; then
        echo "512" > /sys/devices/virtual/bdi/default/read_ahead_kb;
fi;

echo "15" > /proc/sys/fs/lease-break-time;

log -p i -t $FILE_NAME "*** filesystem tweaks ***: enabled";
}
if [ $cortexbrain_io == 1 ]; then
	IO_TWEAKS;
fi;

# ==============================================================
# KERNEL-TWEAKS
# ==============================================================
KERNEL_TWEAKS()
{
echo "1" > /proc/sys/vm/oom_kill_allocating_task;
sysctl -w vm.panic_on_oom=0

log -p i -t $FILE_NAME "*** kernel tweaks ***: enabled";
}
if [ $cortexbrain_kernel_tweaks == 1 ]; then
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
setprop windowsmgr.max_events_per_sec 240
setprop profiler.force_disable_err_rpt 1
setprop profiler.force_disable_ulog 1

# Proximity tweak
setprop mot.proximity.delay 15

# more Tweaks
setprop dalvik.vm.execution-mode int:jit
setprop persist.adb.notify 0
setprop wifi.supplicant_scan_interval 360
setprop pm.sleep_mode 1

if [ "`getprop dalvik.vm.heapsize | sed 's/m//g'`" -lt 64 ]; then
	setprop dalvik.vm.heapsize 72m
fi;

log -p i -t $FILE_NAME "*** system tweaks ***: enabled";
}
if [ $cortexbrain_system == 1 ]; then
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
	echo "1" > /sys/module/dhd/parameters/wifi_pm;
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

# TODO: need testing
echo "1" > /sys/class/lcd/panel/power_reduce;

log -p i -t $FILE_NAME "*** battery tweaks ***: enabled";
}
if [ $cortexbrain_battery == 1 ]; then
	BATTERY_TWEAKS;
fi;

# ==============================================================
# CPU-TWEAKS
# ==============================================================

CPU_GOV_TWEAKS()
{
SYSTEM_GOVERNOR=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`

if [ $MORE_BATTERY == 1 ]; then

	echo "${scaling_min_freq}" > /sys/devices/virtual/sec/sec_touchscreen/tsp_touch_freq;

	if [ $SYSTEM_GOVERNOR == "ondemand" ]; then
		echo "95" > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold;
		echo "1" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor;
		echo "1" > /sys/devices/system/cpu/cpufreq/ondemand/down_differential;
		echo "150000" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate;
		echo "${scaling_min_suspend_freq}" > /sys/devices/system/cpu/cpufreq/ondemand/suspend_freq
		echo "20" > /sys/devices/system/cpu/cpufreq/ondemand/freq_step
	fi;

	if [ $SYSTEM_GOVERNOR == "hyper" ]; then
		echo "95" > /sys/devices/system/cpu/cpufreq/hyper/up_threshold;
		echo "1" > /sys/devices/system/cpu/cpufreq/hyper/sampling_down_factor;
		echo "1" > /sys/devices/system/cpu/cpufreq/hyper/down_differential;
		echo "150000" > /sys/devices/system/cpu/cpufreq/hyper/sampling_rate;
		echo "${scaling_min_suspend_freq}" > /sys/devices/system/cpu/cpufreq/hyper/suspend_freq
		echo "20" > /sys/devices/system/cpu/cpufreq/hyper/freq_step
	fi;

 	
	if [ $SYSTEM_GOVERNOR == "lulzactive" ]; then
		echo "90" > /sys/devices/system/cpu/cpufreq/lulzactive/inc_cpu_load;
		echo "200000" > /sys/devices/system/cpu/cpufreq/lulzactive/pump_up_step;
		echo "200000" > /sys/devices/system/cpu/cpufreq/lulzactive/pump_down_step;
		echo "50000" > /sys/devices/system/cpu/cpufreq/lulzactive/up_sample_time;
		echo "40000" > /sys/devices/system/cpu/cpufreq/lulzactive/down_sample_time;
		echo "10" > /sys/devices/system/cpu/cpufreq/lulzactive/screen_off_min_step;
	fi;

	if [ $SYSTEM_GOVERNOR == "conservative" ]; then
		echo "10" > /sys/devices/system/cpu/cpufreq/conservative/freq_step;
		echo "1" > /sys/devices/system/cpu/cpufreq/conservative/sampling_down_factor;
		echo "40" > /sys/devices/system/cpu/cpufreq/conservative/down_threshold;
		echo "95" > /sys/devices/system/cpu/cpufreq/conservative/up_threshold;
		echo "120000" > /sys/devices/system/cpu/cpufreq/conservative/sampling_rate;
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

	if [ $SYSTEM_GOVERNOR == "pegasusq" ]; then
		echo "50" > /sys/devices/system/cpu/cpufreq/pegasusq/cpu_down_rate
		echo "50" > /sys/devices/system/cpu/cpufreq/pegasusq/cpu_up_rate
		echo "95" > /sys/devices/system/cpu/cpufreq/pegasusq/up_threshold
		echo "1" > /sys/devices/system/cpu/cpufreq/pegasusq/down_differential
	fi;

elif [ $DEFAULT_SPEED == 1 ]; then

	if [ $SYSTEM_GOVERNOR == "ondemand" ]; then
		echo "70" > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold;
		echo "2" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor;
		echo "5" > /sys/devices/system/cpu/cpufreq/ondemand/down_differential;
		echo "800000" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate;
		echo "${scaling_min_suspend_freq}" > /sys/devices/system/cpu/cpufreq/ondemand/suspend_freq
		echo "40" > /sys/devices/system/cpu/cpufreq/ondemand/freq_step
	fi;

	if [ $SYSTEM_GOVERNOR == "hyper" ]; then
		echo "70" > /sys/devices/system/cpu/cpufreq/hyper/up_threshold;
 		echo "2" > /sys/devices/system/cpu/cpufreq/hyper/sampling_down_factor;
		echo "5" > /sys/devices/system/cpu/cpufreq/hyper/down_differential;
		echo "80000" > /sys/devices/system/cpu/cpufreq/hyper/sampling_rate;
		echo "${scaling_min_suspend_freq}" > /sys/devices/system/cpu/cpufreq/hyper/suspend_freq
		echo "40" > /sys/devices/system/cpu/cpufreq/hyper/freq_step
	fi;

	if [ $SYSTEM_GOVERNOR == "lulzactive" ]; then
		echo "50" > /sys/devices/system/cpu/cpufreq/lulzactive/inc_cpu_load;
		echo "200000" > /sys/devices/system/cpu/cpufreq/lulzactive/pump_up_step;
		echo "200000" > /sys/devices/system/cpu/cpufreq/lulzactive/pump_down_step;
		echo "50000" > /sys/devices/system/cpu/cpufreq/lulzactive/up_sample_time;
		echo "40000" > /sys/devices/system/cpu/cpufreq/lulzactive/down_sample_time;
		echo "10" > /sys/devices/system/cpu/cpufreq/lulzactive/screen_off_min_step;
	fi;

	if [ $SYSTEM_GOVERNOR == "conservative" ]; then
		echo "40" > /sys/devices/system/cpu/cpufreq/conservative/freq_step;
		echo "1" > /sys/devices/system/cpu/cpufreq/conservative/sampling_down_factor;
		echo "30" > /sys/devices/system/cpu/cpufreq/conservative/down_threshold;
		echo "80" > /sys/devices/system/cpu/cpufreq/conservative/up_threshold;
		echo "100000" > /sys/devices/system/cpu/cpufreq/conservative/sampling_rate;
	fi;

	if [ $SYSTEM_GOVERNOR == "hotplug" ]; then
		echo "1" > /sys/devices/system/cpu/cpufreq/hotplug/down_differential;
		echo "30" > /sys/devices/system/cpu/cpufreq/hotplug/down_threshold;
		echo "80" > /sys/devices/system/cpu/cpufreq/hotplug/up_threshold;
		echo "100000" > /sys/devices/system/cpu/cpufreq/hotplug/sampling_rate;
	fi;

	if [ $SYSTEM_GOVERNOR == "abyssplug" ]; then
		echo "2" > /sys/devices/system/cpu/cpufreq/abyssplug/down_differential;
		echo "30" > /sys/devices/system/cpu/cpufreq/abyssplug/down_threshold;
		echo "80" > /sys/devices/system/cpu/cpufreq/abyssplug/up_threshold;
		echo "100000" > /sys/devices/system/cpu/cpufreq/abyssplug/sampling_rate;
	fi;

	if [ $SYSTEM_GOVERNOR == "pegasusq" ]; then
		echo "${load_l1}" > /sys/devices/system/cpu/cpufreq/pegasusq/cpu_down_rate
		echo "${load_h0}" > /sys/devices/system/cpu/cpufreq/pegasusq/cpu_up_rate
		echo "70" > /sys/devices/system/cpu/cpufreq/pegasusq/up_threshold
		echo "1" > /sys/devices/system/cpu/cpufreq/pegasusq/down_differential
	fi;

elif [ $MORE_SPEED == 1 ]; then

	if [ $SYSTEM_GOVERNOR == "ondemand" ]; then
		echo "60" > /sys/devices/system/cpu/cpufreq/ondemand/up_threshold;
		echo "2" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor;
		echo "5" > /sys/devices/system/cpu/cpufreq/ondemand/down_differential;
		echo "500000" > /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate;
		echo "${scaling_min_suspend_freq}" > /sys/devices/system/cpu/cpufreq/ondemand/suspend_freq
		echo "50" > /sys/devices/system/cpu/cpufreq/ondemand/freq_step
	fi;


	if [ $SYSTEM_GOVERNOR == "hyper" ]; then
		echo "60" > /sys/devices/system/cpu/cpufreq/hyper/up_threshold;
		echo "2" > /sys/devices/system/cpu/cpufreq/hyper/sampling_down_factor;
		echo "5" > /sys/devices/system/cpu/cpufreq/hyper/down_differential;
		echo "50000" > /sys/devices/system/cpu/cpufreq/hyper/sampling_rate;
		echo "${scaling_min_suspend_freq}" > /sys/devices/system/cpu/cpufreq/hyper/suspend_freq
		echo "50" > /sys/devices/system/cpu/cpufreq/hyper/freq_step
	fi;

	if [ $SYSTEM_GOVERNOR == "lulzactive" ]; then
		echo "30" > /sys/devices/system/cpu/cpufreq/lulzactive/inc_cpu_load;
		echo "200000" > /sys/devices/system/cpu/cpufreq/lulzactive/pump_up_step;
		echo "200000" > /sys/devices/system/cpu/cpufreq/lulzactive/pump_down_step;
		echo "10000" > /sys/devices/system/cpu/cpufreq/lulzactive/up_sample_time;
		echo "70000" > /sys/devices/system/cpu/cpufreq/lulzactive/down_sample_time;
		echo "10" > /sys/devices/system/cpu/cpufreq/lulzactive/screen_off_min_step;
	fi;

	if [ $SYSTEM_GOVERNOR == "conservative" ]; then
		echo "50" > /sys/devices/system/cpu/cpufreq/conservative/freq_step;
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

	if [ $SYSTEM_GOVERNOR == "pegasusq" ]; then
		echo "${load_l1}" > /sys/devices/system/cpu/cpufreq/pegasusq/cpu_down_rate
		echo "${load_h0}" > /sys/devices/system/cpu/cpufreq/pegasusq/cpu_up_rate
		echo "60" > /sys/devices/system/cpu/cpufreq/pegasusq/up_threshold
		echo "1" > /sys/devices/system/cpu/cpufreq/pegasusq/down_differential
	fi;

fi;

log -p i -t $FILE_NAME "*** cpu gov tweaks ***: enabled";
}
if [ $cortexbrain_cpu == 1 ]; then
	CPU_GOV_TWEAKS;
fi;

# ==============================================================
# MEMORY-TWEAKS
# ==============================================================
MEMORY_TWEAKS()
{
if [ "$MORE_BATTERY" == "1" ]; then
	echo "$dirty_expire_centisecs_battery" > /proc/sys/vm/dirty_expire_centisecs;
	echo "$dirty_writeback_centisecs_battery" > /proc/sys/vm/dirty_writeback_centisecs;
	echo "$dirty_background_ratio_battery" > /proc/sys/vm/dirty_background_ratio; # default: 10
	echo "$dirty_ratio_battery" > /proc/sys/vm/dirty_ratio; # default: 40
else
	echo "$dirty_expire_centisecs_default" > /proc/sys/vm/dirty_expire_centisecs;
	echo "$dirty_writeback_centisecs_default" > /proc/sys/vm/dirty_writeback_centisecs;
	echo "$dirty_background_ratio_default" > /proc/sys/vm/dirty_background_ratio; # default: 10
	echo "$dirty_ratio_default" > /proc/sys/vm/dirty_ratio; # default: 40
fi;
echo "4" > /proc/sys/vm/min_free_order_shift; # default: 4
echo "0" > /proc/sys/vm/overcommit_memory; # default: 0
echo "1000" > /proc/sys/vm/overcommit_ratio; # default: 50
echo "96 96" > /proc/sys/vm/lowmem_reserve_ratio;
echo "5" > /proc/sys/vm/page-cluster; # default: 3
echo "8192" > /proc/sys/vm/min_free_kbytes
echo "10" > /proc/sys/vm/vfs_cache_pressure; # default: 100
echo "65530" > /proc/sys/vm/max_map_count;
echo "250 32000 32 128" > /proc/sys/kernel/sem; # default: 250 32000 32 128

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
if [ $cortexbrain_memory == 1 ]; then
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
if [ $cortexbrain_tcp == 1 ]; then
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
if [ $cortexbrain_ril == 1 ]; then
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
if [ $cortexbrain_firewall == 1 ]; then
	FIREWALL_TWEAKS;
fi;

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{

# Awake booster!
# Kill the wakeup bug! boost the CPU to MAX allowed.
echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;

echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
echo "1200000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq > /dev/null 2>&1;
echo "1500000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq > /dev/null 2>&1;

# Now boost the screen lock freq to Max Allowed
echo "1000000" > /sys/devices/virtual/sec/sec_touchscreen/tsp_touch_freq;
echo "1200000" > /sys/devices/virtual/sec/sec_touchscreen/tsp_touch_freq > /dev/null 2>&1;
echo "1500000" > /sys/devices/virtual/sec/sec_touchscreen/tsp_touch_freq > /dev/null 2>&1;

sleep 5

# charging & screen is on
CHARGING=`cat /sys/class/power_supply/battery/charging_source`; # [0=battery 1=USB 2=AC];
if [ $CHARGING -gt 0 ]; then

	# cpu - Always dual core
	echo "off" > /sys/devices/virtual/misc/second_core/hotplug_on;
	echo "on" > /sys/devices/virtual/misc/second_core/second_core_on;

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

	# set cpu
	if [ "$secondcore" == "hotplug" ]; then
		echo "on" > /sys/devices/virtual/misc/second_core/hotplug_on;
	else
		echo "off" > /sys/devices/virtual/misc/second_core/hotplug_on;
	fi;

	if [ "$secondcore" == "always-off" ]; then
		echo "off" > /sys/devices/virtual/misc/second_core/hotplug_on;
		echo "off" > /sys/devices/virtual/misc/second_core/second_core_on;
	fi;

	if [ "$secondcore" == "always-on" ]; then
		echo "off" > /sys/devices/virtual/misc/second_core/hotplug_on;
		echo "on" > /sys/devices/virtual/misc/second_core/second_core_on;
	fi;

	# cpu - settings for second core
	echo "${load_h0}" > /sys/module/stand_hotplug/parameters/load_h0;
	echo "${load_l1}" > /sys/module/stand_hotplug/parameters/load_l1;

	# Bus Freq for deep sleep
	echo "${busfreq_asv_group}" > /sys/devices/system/cpu/cpufreq/busfreq_asv_group;
	echo "${busfreq_up_threshold}" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;
	echo "${busfreq_down_threshold}" > /sys/devices/system/cpu/cpufreq/busfreq_down_threshold;

	# CPU Idle State
	echo "${enable_mask}" > /sys/module/cpuidle_exynos4/parameters/enable_mask;

	# value from settings
	echo "${sched_mc_power_savings}" > /sys/devices/system/cpu/sched_mc_power_savings;

	# auto set brightness
	if [ "${cortexbrain_auto_tweak_brightness}" == "1" ]; then
		AUTO_BRIGHTNESS=$(cat /sys/class/backlight/panel/auto_brightness);
		if [ "$AUTO_BRIGHTNESS" != "1" ]; then
			LEVEL=$(cat /sys/class/power_supply/battery/capacity);
			MAX_BRIGHTNESS=$(cat /sys/class/backlight/panel/max_brightness);
			OLD_BRIGHTNESS=$(cat /sys/class/backlight/panel/brightness);
			NEW_BRIGHTNESS=$(( MAX_BRIGHTNESS*LEVEL/100 ));
			if [ "$NEW_BRIGHTNESS" < "$NEW_BRIGHTNESS" ]; then
				echo "$NEW_BRIGHTNESS" > /sys/class/backlight/panel/brightness;
			fi;
		fi;
	fi;

	MODE="AWAKE";
fi;

# set governor & CPU speed
echo "${scaling_governor}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
echo "${scaling_min_freq}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
echo "${scaling_max_freq}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;

if [ "$MORE_BATTERY" == "1" ]; then
	echo "${scaling_min_freq}" > /sys/devices/virtual/sec/sec_touchscreen/tsp_touch_freq;
else
	echo "${scaling_max_freq}" > /sys/devices/virtual/sec/sec_touchscreen/tsp_touch_freq;
fi;

# Restore Smooth Level
kmemhelper -n smooth_level -o 0 -t int ${smooth_level0}

# set default settings
echo "${dirty_expire_centisecs_default}" > /proc/sys/vm/dirty_expire_centisecs;
echo "${dirty_writeback_centisecs_default}" > /proc/sys/vm/dirty_writeback_centisecs;
echo "${dirty_background_ratio_default}" > /proc/sys/vm/dirty_background_ratio; # default: 10
echo "${dirty_ratio_default}" > /proc/sys/vm/dirty_ratio; # default: 40

if [ $cortexbrain_battery == 1 ]; then
	BATTERY_TWEAKS;
fi;

# ==============================================================
# check for temperature
# ==============================================================

CHECK_TEMPERATURE()
{
TEMP=`cat /sys/class/power_supply/battery/batt_temp`;
if [ $TEMP -ge $MAX_TEMP ]; then
	echo "ondemand" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
	echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
	echo "0" > /sys/class/backlight/panel/brightness;
	log -p i -t $FILE_NAME "*** TEMPERATURE over $(( ${MAX_TEMP} / 10 ))C***";
	exit;
fi;
}
CHECK_TEMPERATURE;

# Setting the vibrator force in case it's has been reseted.
echo "${pwm_val}" > /sys/vibrator/pwm_val;

log -p i -t $FILE_NAME "*** $MODE Mode ***";
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{

# charging & screen is off
CHARGING=`cat /sys/class/power_supply/battery/charging_source`;
if [ $CHARGING -ge 1 ]; then

	# CPU-Freq
	echo "${deep_sleep_ac}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;

	MODE="CHARGING";
else

	# CPU-Freq
	echo "${deep_sleep_batt}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;

	MODE="SLEEP";
fi;

# Reduce CPU speed
echo "${scaling_min_suspend_freq}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
echo "${scaling_max_suspend_freq}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
# Reduce deepsleep CPU speed
echo "${scaling_min_suspend_freq}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_suspend_freq;
echo "${scaling_max_suspend_freq}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;

# cpu - second core always-off
echo "off" > /sys/devices/virtual/misc/second_core/hotplug_on;
echo "off" > /sys/devices/virtual/misc/second_core/second_core_on;

# Bus Freq for deep sleep
echo "3" > /sys/devices/system/cpu/cpufreq/busfreq_asv_group;
echo "40" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;
echo "40" > /sys/devices/system/cpu/cpufreq/busfreq_down_threshold;

# Smooth Level set to 800Mhz just in case.
kmemhelper -n smooth_level -o 0 -t int 8;

# set settings for battery -> don't wake up "pdflush daemon"
echo "${dirty_expire_centisecs_battery}" > /proc/sys/vm/dirty_expire_centisecs;
echo "${dirty_writeback_centisecs_battery}" > /proc/sys/vm/dirty_writeback_centisecs;
echo "${dirty_background_ratio_battery}" > /proc/sys/vm/dirty_background_ratio; # default: 10
echo "${dirty_ratio_battery}" > /proc/sys/vm/dirty_ratio; # default: 40

if [ $cortexbrain_battery == 1 ]; then
	BATTERY_TWEAKS;
fi;

# CPU Idle State - AFTR+LPA
echo "3" > /sys/module/cpuidle_exynos4/parameters/enable_mask;

# enable first core overloading
echo "1" > /sys/devices/system/cpu/sched_mc_power_savings;

# Setting the vibrator force in case it's has been reseted.
echo "${pwm_val}" > /sys/vibrator/pwm_val;

log -p i -t $FILE_NAME "*** $MODE mode ***";
}

# ==============================================================
# Background process to check screen state
# ==============================================================
if [ $cortexbrain_background_process == 1 ]; then

	# the process is not considered for OOM-killing
	/system/xbin/echo "-17" > /proc/${PIDOFCORTEX}/oom_adj;
	renice -10 ${PIDOFCORTEX};

	(while [ 1 ]; do
		# AWAKE State! all system ON!
		STATE=$(cat /sys/power/wait_for_fb_wake);
		PROFILE=$(cat /data/.siyah/.active.profile);
		. /data/.siyah/$PROFILE.profile;
		AWAKE_MODE;
		sleep 3;

		# SLEEP state! All system to power save!
		SLEEP_MODE;
		sleep 3;
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
# TODO: add more description, explanations & default vaules ...
#

# ==============================================================
# Explanations
# ==============================================================
#

# oom_kill_allocating_task:	If this is set to zero, the OOM killer will scan through the entire tasklist and select a task based on heuristics to kill.
#
#				This normally selects a rogue memory-hogging task that frees up a large amount of memory when killed. 
#				If this is set to non-zero, the OOM killer simply kills the task that triggered the out-of-memory condition. 
#				This avoids the expensive tasklist scan.
#
# 				echo XXX > /proc/sys/vm/oom_kill_allocating_task;

# dirty_expire_centisecs: This tunable is used to define when dirty data is old enough to be eligible for writeout by the pdflush daemons.
#
#				It is expressed in 100'ths of a second. Data which has been dirty in memory for longer than this interval will be written 
#				out next time a pdflush daemon wakes up.
#
# 				echo XXX > /proc/sys/vm/dirty_expire_centisecs;

# dirty_writeback_centisecs: The pdflush writeback daemons will periodically wake up and write "old" data out to disk.
#
#				This tunable expresses the interval between those wakeups, in 100'ths of a second. 
#				Setting this to zero disables periodic writeback altogether.
#
# 				echo XXX > /proc/sys/vm/dirty_writeback_centisecs;

# drop_caches:		Writing to this will cause the kernel to drop clean caches, dentries and inodes from memory, causing that memory to become free.
#
#				To free pagecache:
# 				echo 1 > /proc/sys/vm/drop_caches
#
#				To free dentries and inodes:
# 				echo 2 > /proc/sys/vm/drop_caches
#
#				To free pagecache, dentries and inodes:
# 				echo 3 > /proc/sys/vm/drop_caches

# page-cluster: 	page-cluster controls the number of pages which are written to swap in a single attempt. The swap I/O size.
#
#				It is a logarithmic value - setting it to zero means "1 page", setting it to 1 means "2 pages", setting it to 2 means "4 pages", etc.
#				The default value is three (eight pages at a time). There may be some small benefits in tuning this to 
#				a different value if your workload is swap-intensive. (default 3)
#
# 				echo XXX > /proc/sys/vm/page-cluster;

# laptop_mode: 		laptop_mode is a knob that controls "laptop mode". When the knob is set, any physical disk I/O
#
#				(that might have caused the hard disk to spin up, see /proc/sys/vm/block_dump) causes Linux to flush all dirty blocks. 
#				The result of this is that after a disk has spun down, it will not be spun up anymore to write dirty blocks, 
#				because those blocks had already been written immediately after the most recent read operation. 
#				The value of the laptop_mode knob determines the time between the occurrence of disk I/O and when the flush is triggered. 
#				A sensible value for the knob is 5 seconds. Setting the knob to 0 disables laptop mode.
#
# 				echo XXX > /proc/sys/vm/laptop_mode;

# rr_interval:		rr_interval or "round robin interval". This is the maximum time two SCHED_OTHER (or SCHED_NORMAL, the common scheduling policy)
#
#				tasks of the same nice level will be running for, or looking at it the other way around, the longest duration two tasks 
#				of the same nice level will be delayed for. When a task requests cpu time, it is given a quota (time_slice) equal to the 
#				rr_interval and a virtual deadline, while increasing it will improve throughput, but at the cost of worsening latencies.
#
# 				echo XXX > /proc/sys/kernel/rr_interval;

# dirty_background_ratio: Contains, as a percentage of total system memory, the number of pages at which the pdflush background writeback daemon will 
#				start writing out dirty data.
#
# 				echo XXX > /proc/sys/vm/dirty_background_ratio;

# dirty_ratio:		Contains, as a percentage of total system memory, the number of pages at which a process which is generating disk writes will itself start writing out dirty data.
#
# 				echo XXX > /proc/sys/vm/dirty_ratio;

# iso_cpu:		Setting this to 100 is the equivalent of giving all users SCHED_RR access and setting it to 0 removes the ability to run any pseudo-realtime tasks.
#
# 				echo XXX > /proc/sys/kernel/iso_cpu;

# ===============
#
# Kernel-Settings
#
# ===============

# msgmni: 		The msgmni tunable specifies the maximum number of system-wide System V IPC message queue identifiers (one per queue).
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

# ===============
#
# CPU-Settings
#
# ===============

# scaling_governor: 	Using Frequency Scaling Governors -> cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
#
# 				-> http://publib.boulder.ibm.com/infocenter/lnxinfo/v3r0m0/index.jsp?topic=/liaai/cpufreq/TheOndemandGovernor.htm
#
# 				conservative - Increases frequency step by step, decreases instantly
# 				ondemand - Uses the highest CPU frequency when tasks are started, decreases step by step
# 				performance - CPU only runs at max frequency regardless of load
# 				powersave - CPU only runs at min frequency regardless of load
#
# 				echo "ondemand" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# sched_latency_ns: 	Targeted preemption latency for CPU-bound tasks.
#
# 				echo XXX > /proc/sys/kernel/sched_latency_ns;

# sched_batch_wakeup_granularity_ns: Wake-up granularity for SCHED_BATCH.
#
# 				echo XXX > /proc/sys/kernel/sched_batch_wakeup_granularity_ns;

# sched_wakeup_granularity_ns: Wake-up granularity for SCHED_OTHER.
#
# 				echo XXX > /proc/sys/kernel/sched_wakeup_granularity_ns;

# sched_compat_yield: 	Applications depending heavily on sched_yield()'s behavior can expect varied performance because of the way CFS changes this, so turning on the sysctls is recommended.
#
# 				echo XXX > /proc/sys/kernel/sched_compat_yield;

# sched_child_runs_first: The child is scheduled next after fork; it's the default. If set to 0, then the parent is given the baton.
#
# 				echo XXX > /proc/sys/kernel/sched_child_runs_first;

# sched_min_granularity_ns: Minimum preemption granularity for CPU-bound tasks.
#
# 				echo XXX > /proc/sys/kernel/sched_min_granularity_ns;

# sched_features: 	NO_NEW_FAIR_SLEEPERS is something that will turn the scheduler into a more classic fair scheduler ?!?
#
# 				echo NO_NORMALIZED_SLEEPER > /sys/kernel/debug/sched_features;

# sched_stat_granularity_ns: Granularity for collecting scheduler statistics. [1/0]
#
# 				echo XXX  > /proc/sys/kernel/sched_stat_granularity_ns;

# sched_rt_period_us: 	The default values for sched_rt_period_us (1000000 or 1s) and sched_rt_runtime_us (950000 or 0.95s).
#
#				This gives 0.05s to be used by SCHED_OTHER (non-RT tasks). These defaults were chosen so that a run-away realtime 
#				tasks will not lock up the machine but leave a little time to recover it. By setting runtime to -1 you get the old behaviour back.

# threads-max: 		Gets/sets the limit on the maximum number of running threads system-wide.
#
# 				echo XXX > /proc/sys/kernel/threads-max;

# ===============
#
# Memory-Settings
#
# ===============

# swappiness: 		Swappiness is a parameter which sets the kernel's balance between reclaiming pages from the page cache and swapping process memory. 
#
#				The default value is 60. If you want kernel to swap out more process memory and thus cache more file contents increase the value. 
#				Otherwise, if you would like kernel to swap less decrease it. A value of 0 means "do not swap unless out of free RAM", 
#				a value of 100 means "swap whenever possible". 
#
# 				echo XXX > /proc/sys/vm/swappiness;

# overcommit_memory: 	Controls overcommit of system memory, possibly allowing processes to allocate (but not use) more memory than is actually available.
#
#				0 - Heuristic overcommit handling. 
#					Obvious overcommits of address space are refused. Used for a typical system. 
#					It ensures a seriously wild allocation fails while allowing overcommit to reduce swap usage. 
#					root is allowed to allocate slighly more memory in this mode. This is the default.
#				1 - Always overcommit. 
#					Appropriate for some scientific applications.
#				2 - Don't overcommit. 
#					The total address space commit for the system is not permitted to exceed swap plus a 
#					configurable percentage (default is 50) of physical RAM. Depending on the percentage you use, 
#					in most situations this means a process will not be killed while attempting to use already-allocated memory but 
#					will receive errors on memory allocation as appropriate.

# overcommit_ratio: 	Percentage of physical memory size to include in overcommit calculations.
#
#				Memory allocation limit = swapspace + physmem * (overcommit_ratio / 100)
#
#				swapspace = total size of all swap areas
#				physmem = size of physical memory in system

# vfs_cache_pressure: 	Controls the tendency of the kernel to reclaim the memory which is used for caching of directory and inode objects.
#
#				At the default value of vfs_cache_pressure = 100 the kernel will attempt to reclaim dentries and inodes at a "fair" rate with respect 
#				to pagecache and swapcache reclaim. Decreasing vfs_cache_pressure causes the kernel to prefer to retain dentry and inode caches. 
#				Increasing vfs_cache_pressure beyond 100 causes the kernel to prefer to reclaim dentries and inodes.
#
# 				echo XXX > /proc/sys/vm/vfs_cache_pressure;

# min_free_kbytes: 	This is used to force the Linux VM to keep a minimum number of kilobytes free. 
#
#				The VM uses this number to compute a pages_min value for each lowmem zone in the system. Each lowmem zone gets a number of reserved 
#				free pages based proportionally on its size.
#
# 				echo XXX > /proc/sys/vm/min_free_kbytes;

# ===============
#
# I/O-Settings
#
# ===============

# read_ahead_kb: 	Optimize for read-throughput (cache-value).
#
# 				example of C-program for finding correct vaules for Linux 
# 				-> http://pastebin.com/Rg6qVJQH
#

# fifo_batch:		Controls the maximum number of requests per batch.
#
# 				This parameter tunes the balance between per-request latency and aggregate
#				throughput.  When low latency is the primary concern, smaller is better (where
#				a value of 1 yields first-come first-served behaviour).  Increasing fifo_batch
#				generally improves throughput, at the cost of latency variation.

# back_seek_max: 	This parameter, given in Kbytes, sets the maximum “distance” for backward seeking.
#
#				By default, this parameter is set to 16 MBytes.
#				This distance is the amount of space from the current head location to the sectors that are backward in terms of distance. 
#				This idea comes from the Anticipatory Scheduler (AS) about anticipating the location of the next request.
#				This parameter allows the scheduler to anticipate requests in the “backward”
#				or opposite direction and consider the requests as being “next” if they are within this distance from the current head location.

# back_seek_penalty: 	This parameter is used to compute the cost of backward seeking. 
#
#				If the backward distance of a request is just (1/back_seek_penalty) from a “front” request, then
#				the seeking cost of the two requests is considered equivalent and the scheduler will not bias toward one or the other
#				(otherwise the scheduler will bias the selection to “front direction requests). 
#				Recall, the CFQ has the concept of elevators so it will try to seek in the current direction as much as possible to avoid the latency associated with a seek.
#				This parameters defaults to 2 so if the distance is only 1/2 of the forward distance, CFQ will consider the backward request to be close enough
#				to the current head location to be “close”. Therefore it will consider it as a forward request.

# fifo_expire_async: 	This particular parameter is used to set the timeout of asynchronous requests.
#
#				Recall that CFQ maintains a fifo (first-in, first-out) list to manage timeout requests. 
#				In addition, CFQ doesn’t check the expired requests from the fifo queue after one timeout is dispatched (i.e. there is a delay in processing the expired request).
#				The default value for this parameter is 250 ms. A smaller value means the timeout is considered much more quickly than a larger value.

# fifo_expire_sync: 	This parameter is the same as fifo_expire_async but for synchronous requests.
#
#				The default value for this parameter is 125 ms.
#				If you want to favor synchronous request over asynchronous requests, then this value should be decreased relative to fifo_expire_asynchronous.

# slice_sync:		Remember that when a queue is selected for execution, the queues IO requests are only executed for a certain amount of time (the time_slice) before switching to another queue.
#
#				This parameter is used to calculate the time slice of the synchronous queue. 
#				The default value for this parameter is 100 ms, but this isn’t the true time slice.
#				Rather the time slice is computed from the following: time_slice = slice_sync + (slice_sync / 5 * 4 – io_priority)).
#				If you want the time slice for the synchronous queue to be longer (perhaps you have more synchronous operations), then increase the value of slice_sync.

# slice_async: 		This parameter is the same as slice_sync but for the asynchronous queue.
#
#				The default is 40 ms. Notice that synchronous operations are preferred over asynchronous operations.

# slice_asyn_rq: 	This parameter is used to limit the dispatching of asynchronous requests to the device request-queue in queue’s slice time. 
#
#				This limits the number of asynchronous requests are executed (dispatched). 
#				The maximum number of requests that are allowed to be dispatched also depends upon the io priority. 
#				The equations for computing the maximum number of requests is, max_nr_requests = 2 * (slice_async_rq + slice_async_rq * (7 – io_priority)). The default for slice_async_rq is 2.

# slice_idle:		This parameter is the idle time for the synchronous queue only.
#
#				In a queue’s time slice (the amount of time operations can be dispatched), when there are no requests in the synchronous queue CFQ will not switch to another queue
#				but will sit idle to wait for the process creating more requests. If there are no new requests submitted within the idle time, then the queue will expire.
#				The default value for this parameter is 8 ms. This parameters can control the amount of time the schedulers waits for synchronous requests.
#				This can be important since synchronous requests tend to block execution of the process until the operation is completed. Consequently,
#				the IO scheduler looks for synchronous requests within the idle window of time that might come from a streaming video application or something that needs synchronous operations.

# quantum:		This parameter controls the number of dispatched requests to the device queue, request-device (i.e. the number of requests that are executed or at least sent for execution). 
#
#				In a queue’s time slice, a request will not be dispatched if the number of requests in the device request-device exceeds this parameter. 
#				For the asynchronous queue, dispatching the requests is also restricted by the parameter slice_async_rq. The default for this parameter is 4.

# ===============
#
# BFQ-Settings
#
# ===============

# timeout_sync, timeout_async: The maximum amount of disk time that can be given to a task once it has been selected for service, respectively for synchronous and asynchronous queues.
#
#				It allows the user to specify a maximum slice length to put an upper bound to the latencies imposed by the scheduler.

# max_budget:		The maximum amount of service, measured in disk sectors, that can be provided to a queue once it is selected (of course within the limits of the above timeouts). 
#
#				According to what we said in the description of the algoritm, larger values increase the throughput for the single tasks and for the system,
#				in proportion to the percentage of sequential requests issued. The price is increasing the maximum latency a request may incur in. 
#				The default value is 0, which enables auto-tuning: BFQ tries to estimate it as the maximum number of sectors that can be served during timeout_sync.

# max_budget_async_rq: In addition to the max_budget, limit, async queues are served for a maximum number of requests, after that a new queue is selected.

# low_latency:	If equal to 1 (default value), interactive and soft real-time applications are privileged and experience a lower latency.


# more Informations can be found here -> http://doc.opensuse.org/documentation/html/openSUSE/opensuse-tuning/part.tuning.kernel.html
