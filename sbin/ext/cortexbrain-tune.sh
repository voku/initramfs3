#!/sbin/busybox sh

#Credits:
# Zacharias.maladroit
# Voku1987
# Collin_ph@xda
# Dorimanx@xda
# Gokhanmoral@xda
# Johnbeetee
# Alucard_24@xda

# TAKE NOTE THAT LINES PRECEDED BY A "#" IS COMMENTED OUT.
# This script must be activated after init start =< 25sec or parameters from /sys/* will not be loaded.

# read setting from profile

# Get values from profile. since we dont have the recovery source code i cant change the .siyah dir, so just leave it there for history.
PROFILE=`cat /data/.siyah/.active.profile`;
. /data/.siyah/$PROFILE.profile;

FILE_NAME=$0;
PIDOFCORTEX=$$;

# wifi timer helpers
echo "0" > /data/.siyah/wifi_helper;
echo "0" > /data/.siyah/wifi_helper_awake;
chmod 777 /data/.siyah/wifi_helper /data/.siyah/wifi_helper_awake;

# init sleeprun for first script load.
# init for ksm
mount -o remount,rw /
echo "1" > /tmp/sleeprun;
echo "0" > /tmp/ksm;
chmod 666 /tmp/*;

# replace kernel version info for repacked kernels
cat /proc/version | grep infra && (kmemhelper -t string -n linux_proc_banner -o 15 `cat /res/version`);

# ==============================================================
# I/O-TWEAKS 
# ==============================================================
IO_TWEAKS()
{
	if [ "$cortexbrain_io" == on ]; then

		local ZRM=`ls -d /sys/block/zram*`;
		for z in $ZRM; do
			if [ -e $z/queue/rotational ]; then
				echo "0" > $z/queue/rotational;
			fi;

			if [ -e $z/queue/iostats ]; then
				echo "0" > $z/queue/iostats;
			fi;

			if [ -e $z/queue/rq_affinity ]; then
				echo "1" > $z/queue/rq_affinity;
			fi;
		done;

		local MMC=`ls -d /sys/block/mmc*`;
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

			if [ -e $i/queue/read_ahead_kb ]; then
				echo "$cortexbrain_read_ahead_kb" >  $i/queue/read_ahead_kb; # default: 128
			fi;

			if [ "$scheduler" == "sio" ] || [ "$scheduler" == "zen" ]; then
				if [ -e $i/queue/nr_requests ]; then
					echo "64" > $i/queue/nr_requests; # default: 128
				fi;
			fi;

			if [ -e $i/queue/iosched/back_seek_penalty ]; then
				echo "1" > $i/queue/iosched/back_seek_penalty; # default: 2
			fi;

			if [ -e $i/queue/iosched/slice_idle ]; then
				echo "2" > $i/queue/iosched/slice_idle; # default: 8
			fi;

			if [ -e $i/queue/iosched/fifo_batch ]; then
				echo "1" > $i/queue/iosched/fifo_batch;
			fi;
		done;

		if [ -e /sys/devices/virtual/bdi/default/read_ahead_kb ]; then
			echo "$cortexbrain_read_ahead_kb" > /sys/devices/virtual/bdi/default/read_ahead_kb;
		fi;

		local SDCARDREADAHEAD=`ls -d /sys/devices/virtual/bdi/179*`;
		for i in $SDCARDREADAHEAD; do
			echo "$cortexbrain_read_ahead_kb" > $i/read_ahead_kb;
		done;

		echo "20" > /proc/sys/fs/lease-break-time;
		echo "524288" > /proc/sys/fs/file-max;
		echo "1048576" > /proc/sys/fs/nr_open;
		echo "32000" > /proc/sys/fs/inotify/max_queued_events;
		echo "256" > /proc/sys/fs/inotify/max_user_instances;
		echo "10240" > /proc/sys/fs/inotify/max_user_watches;

		log -p i -t $FILE_NAME "*** IO_TWEAKS ***: enabled";
	fi;
}
IO_TWEAKS;

# ==============================================================
# KERNEL-TWEAKS
# ==============================================================
KERNEL_TWEAKS()
{
	if [ "$cortexbrain_kernel_tweaks" == on ]; then
		echo "0" > /proc/sys/vm/oom_kill_allocating_task;
		echo "0" > /proc/sys/vm/panic_on_oom;
		echo "30" > /proc/sys/kernel/panic;
		echo "65536" > /proc/sys/kernel/msgmax;
		echo "2048" > /proc/sys/kernel/msgmni;
		echo "128" > /proc/sys/kernel/random/read_wakeup_threshold;
		echo "256" > /proc/sys/kernel/random/write_wakeup_threshold;
		echo "500 512000 64 2048" > /proc/sys/kernel/sem;
		echo "2097152" > /proc/sys/kernel/shmall;
		echo "268435456" > /proc/sys/kernel/shmmax;
		echo "524288" > /proc/sys/kernel/threads-max;
	
		log -p i -t $FILE_NAME "*** KERNEL_TWEAKS ***: enabled";
	fi;
}
KERNEL_TWEAKS;

# ==============================================================
# SYSTEM-TWEAKS
# ==============================================================
SYSTEM_TWEAKS()
{
	if [ "$cortexbrain_system" == on ]; then
		# render UI with GPU
		setprop hwui.render_dirty_regions false;
		setprop windowsmgr.max_events_per_sec 180;
		setprop profiler.force_disable_err_rpt 1;
		setprop profiler.force_disable_ulog 1;

		log -p i -t $FILE_NAME "*** SYSTEM_TWEAKS ***: enabled";
	fi;
}
SYSTEM_TWEAKS;

# ==============================================================
# BATTERY-TWEAKS
# ==============================================================
BATTERY_TWEAKS()
{
	if [ "$cortexbrain_battery" == on ]; then
		# battery-calibration if battery is full
		local LEVEL=`cat /sys/class/power_supply/battery/capacity`;
		local CURR_ADC=`cat /sys/class/power_supply/battery/batt_current_adc`;
		local BATTFULL=`cat /sys/class/power_supply/battery/batt_full_check`;
		log -p i -t $FILE_NAME "*** BATTERY - LEVEL: $LEVEL - CUR: $CURR_ADC ***";
		if [ "$LEVEL" == 100 ] && [ "$BATTFULL" == 1 ]; then
			rm -f /data/system/batterystats.bin;
			log -p i -t $FILE_NAME "battery-calibration done ...";
		fi;

		if [ "$power_reduce" == on ]; then
			# LCD Power-Reduce
			if [ -e /sys/class/lcd/panel/power_reduce ]; then
				echo "1" > /sys/class/lcd/panel/power_reduce;
			fi;
		else
			if [ -e /sys/class/lcd/panel/power_reduce ]; then
				echo "0" > /sys/class/lcd/panel/power_reduce;
			fi;
		fi;

		# USB power support
		local POWER_LEVEL=`ls /sys/bus/usb/devices/*/power/level`;
		for i in $POWER_LEVEL; do
			chmod 777 $i;
			echo "auto" > $i;
		done;

		local POWER_AUTOSUSPEND=`ls /sys/bus/usb/devices/*/power/autosuspend`;
		for i in $POWER_AUTOSUSPEND; do
			chmod 777 $i;
			echo "1" > $i;
		done;

		# BUS power support
		buslist="spi i2c sdio";
		for bus in $buslist; do
			local POWER_CONTROL=`ls /sys/bus/$bus/devices/*/power/control`;
			for i in $POWER_CONTROL; do
				chmod 777 $i;
				echo "auto" > $i;
			done;
		done;

		log -p i -t $FILE_NAME "*** BATTERY_TWEAKS ***: enabled";
	fi;
}
if [ "$cortexbrain_background_process" == 0 ]; then
	BATTERY_TWEAKS;
fi;

# ==============================================================
# CPU-TWEAKS
# ==============================================================

CPU_GOV_TWEAKS()
{
    local state="$1";
	if [ "$cortexbrain_cpu" == on ]; then
		local SYSTEM_GOVERNOR=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`;
		
		local sampling_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/sampling_rate";
		if [ ! -e $sampling_rate_tmp ]; then
			sampling_rate_tmp="/dev/null";
		fi;
		local cpu_up_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/cpu_up_rate";
		if [ ! -e $cpu_up_rate_tmp ]; then
			cpu_up_rate_tmp="/dev/null";
		fi;
		local cpu_down_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/cpu_down_rate";
		if [ ! -e $cpu_down_rate_tmp ]; then
			cpu_down_rate_tmp="/dev/null";
		fi;
		local up_threshold_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold";
		if [ ! -e $up_threshold_tmp ]; then
			up_threshold_tmp="/dev/null";
		fi;
		local up_threshold_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold_min_freq";
		if [ ! -e $up_threshold_min_freq_tmp ]; then
			up_threshold_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold_at_min_freq";
		fi;
		if [ ! -e $up_threshold_min_freq_tmp ]; then
			up_threshold_min_freq_tmp="/dev/null";
		fi;
		local inc_cpu_load_at_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/inc_cpu_load_at_min_freq";
		if [ ! -e $inc_cpu_load_at_min_freq_tmp ]; then
			inc_cpu_load_at_min_freq_tmp="/dev/null";
		fi;
		local down_threshold_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/down_threshold";
		if [ ! -e $down_threshold_tmp ]; then
			down_threshold_tmp="/dev/null";
		fi;
		local sampling_up_factor_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/sampling_up_factor";
		if [ ! -e $sampling_up_factor_tmp ]; then
			sampling_up_factor_tmp="/dev/null";
		fi;
		local sampling_down_factor_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/sampling_down_factor";
		if [ ! -e $sampling_down_factor_tmp ]; then
			sampling_down_factor_tmp="/dev/null";
		fi;
		local down_differential_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/down_differential";
		if [ ! -e $down_differential_tmp ]; then
			down_differential_tmp="/dev/null";
		fi;
		local freq_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step";
		if [ ! -e $freq_step_tmp ]; then
			freq_step_tmp="/dev/null";
		fi;
		local freq_step_dec_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step_dec";
		if [ ! -e $freq_step_dec_tmp ]; then
			freq_step_dec_tmp="/dev/null";
		fi;
		local freq_responsiveness_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_responsiveness";
		if [ ! -e $freq_responsiveness_tmp ]; then
			freq_responsiveness_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_for_responsiveness";
		fi;
		if [ ! -e $freq_responsiveness_tmp ]; then
			freq_responsiveness_tmp="/dev/null";
		fi;		
		local inc_cpu_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/inc_cpu_load";
		if [ ! -e $inc_cpu_load_tmp ]; then
			inc_cpu_load_tmp="/dev/null";
		fi;
		local dec_cpu_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/dec_cpu_load";
		if [ ! -e $dec_cpu_load_tmp ]; then
			dec_cpu_load_tmp="/dev/null";
		fi;
		local up_sample_time_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_sample_time";
		if [ ! -e $up_sample_time_tmp ]; then
			up_sample_time_tmp="/dev/null";
		fi;
		local down_sample_time_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/down_sample_time";
		if [ ! -e $down_sample_time_tmp ]; then
			down_sample_time_tmp="/dev/null";
		fi;
		local hispeed_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hispeed_freq";
		if [ ! -e $hispeed_freq_tmp ]; then
			hispeed_freq_tmp="/dev/null";
		fi;
		local hotplug_sampling_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_sampling_rate";
		if [ ! -e $hotplug_sampling_rate_tmp ]; then
			hotplug_sampling_rate_tmp="/dev/null";
		fi;
		local hotplug_freq_1_1_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_freq_1_1";
		if [ ! -e $hotplug_freq_1_1_tmp ]; then
			hotplug_freq_1_1_tmp="/dev/null";
		fi;
		local hotplug_freq_2_0_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_freq_2_0";
		if [ ! -e $hotplug_freq_2_0_tmp ]; then
			hotplug_freq_2_0_tmp="/dev/null";
		fi;
		local hotplug_rq_1_1_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_rq_1_1";
		if [ ! -e $hotplug_rq_1_1_tmp ]; then
			hotplug_rq_1_1_tmp="/dev/null";
		fi;
		local hotplug_rq_2_0_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_rq_2_0";
		if [ ! -e $hotplug_rq_2_0_tmp ]; then
			hotplug_rq_2_0_tmp="/dev/null";
		fi;
		local check_rate_scroff_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/check_rate_scroff";
		if [ ! -e $check_rate_scroff_tmp ]; then
			check_rate_scroff_tmp="/dev/null";
		fi;
		local freq_up_brake_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_up_brake";
		if [ ! -e $freq_up_brake_tmp ]; then
			freq_up_brake_tmp="/dev/null";
		fi;
		local pump_up_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_up_step";
		if [ ! -e $pump_up_step_tmp ]; then
			pump_up_step_tmp="/dev/null";
		fi;
		local pump_down_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_down_step";
		if [ ! -e $pump_down_step_tmp ]; then
			pump_down_step_tmp="/dev/null";
		fi;
		local screen_off_min_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/screen_off_min_step";
		if [ ! -e $screen_off_min_step_tmp ]; then
			screen_off_min_step_tmp="/dev/null";
		fi;		
		local max_cpu_lock_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/max_cpu_lock";
		if [ ! -e $max_cpu_lock_tmp ]; then
			max_cpu_lock_tmp="/dev/null";
		fi;
		local min_cpu_lock_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/min_cpu_lock";
		if [ ! -e $min_cpu_lock_tmp ]; then
			min_cpu_lock_tmp="/dev/null";
		fi;
		local hotplug_lock_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_lock";
		if [ ! -e $hotplug_lock_tmp ]; then
			hotplug_lock_tmp="/dev/null";
		fi;
		local dvfs_debug_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/dvfs_debug";
		if [ ! -e $dvfs_debug_tmp ]; then
			dvfs_debug_tmp="/dev/null";
		fi;
		local hotplug_lock_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_lock";
		if [ ! -e $hotplug_lock_tmp ]; then
			hotplug_lock_tmp="/dev/null";
		fi;
		local check_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/check_rate";
		if [ ! -e $check_rate_tmp ]; then
			check_rate_tmp="/dev/null";
		fi;
		local check_rate_cpuon_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/check_rate_cpuon";
		if [ ! -e $check_rate_cpuon_tmp ]; then
			check_rate_cpuon_tmp="/dev/null";
		fi;
		local freq_cpu1on_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_cpu1on";
		if [ ! -e $freq_cpu1on_tmp ]; then
			freq_cpu1on_tmp="/dev/null";
		fi;
		local freq_cpu1off_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_cpu1off";
		if [ ! -e $freq_cpu1off_tmp ]; then
			freq_cpu1off_tmp="/dev/null";
		fi;
		local trans_load_h0_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/trans_load_h0";
		if [ ! -e $trans_load_h0_tmp ]; then
			trans_load_h0_tmp="/dev/null";
		fi;
		local trans_load_h1_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/trans_load_h1";
		if [ ! -e $trans_load_h1_tmp ]; then
			trans_load_h1_tmp="/dev/null";
		fi;
		local trans_load_l1_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/trans_load_l1";
		if [ ! -e $trans_load_l1_tmp ]; then
			trans_load_l1_tmp="/dev/null";
		fi;
		local trans_load_rq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/trans_load_rq";
		if [ ! -e $trans_load_rq_tmp ]; then
			trans_load_rq_tmp="/dev/null";
		fi;
		local trans_rq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/trans_rq";
		if [ ! -e $trans_rq_tmp ]; then
			trans_rq_tmp="/dev/null";
		fi;
		local trans_load_h0_scroff_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/trans_load_h0_scroff";
		if [ ! -e $trans_load_h0_scroff_tmp ]; then
			trans_load_h0_scroff_tmp="/dev/null";
		fi;
		local trans_load_h1_scroff_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/trans_load_h1_scroff";
		if [ ! -e $trans_load_h1_scroff_tmp ]; then
			trans_load_h1_scroff_tmp="/dev/null";
		fi;
		local trans_load_l1_scroff_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/trans_load_l1_scroff";
		if [ ! -e $trans_load_l1_scroff_tmp ]; then
			trans_load_l1_scroff_tmp="/dev/null";
		fi;

		# performance-settings
		if [ "${state}" == "performance" ]; then
			echo "0" > $min_cpu_lock_tmp;
			echo "0" > $hotplug_lock_tmp;
			echo "200000" > $freq_cpu1on_tmp;
			echo "200000" > $freq_cpu1off_tmp;
			echo "10" > $trans_load_h0_tmp;
			echo "10" > $trans_load_l1_tmp;
			echo "20000" > $sampling_rate_tmp;
			echo "10" > $cpu_up_rate_tmp;
			echo "10" > $cpu_down_rate_tmp;
			echo "10" > $down_threshold_tmp;
			echo "40" > $up_threshold_tmp;
			echo "20" > $up_threshold_min_freq_tmp;
			echo "100" > $freq_step_tmp;
			echo "800000" > $freq_responsiveness_tmp;
		# sleep-settings
		elif [ "${state}" == "sleep" ]; then
			echo "$sampling_rate_sleep" > $sampling_rate_tmp;
			echo "$cpu_up_rate_sleep" > $cpu_up_rate_tmp;
			echo "$cpu_down_rate_sleep" > $cpu_down_rate_tmp;
			echo "$up_threshold_sleep" > $up_threshold_tmp;
			echo "$up_threshold_at_min_freq_sleep" > $up_threshold_min_freq_tmp;
			echo "$inc_cpu_load_at_min_freq_sleep" > $inc_cpu_load_at_min_freq_tmp;
			echo "$down_threshold_sleep" > $down_threshold_tmp;
			echo "$sampling_up_factor_sleep" > $sampling_up_factor_tmp;
			echo "$sampling_down_factor_sleep" > $sampling_down_factor_tmp;
			echo "$down_differential_sleep" > $down_differential_tmp;
			echo "$freq_step_sleep" > $freq_step_tmp;
			echo "$freq_step_dec_sleep" > $freq_step_dec_tmp;
			echo "$freq_for_responsiveness_sleep" > $freq_responsiveness_tmp;
			echo "$inc_cpu_load_sleep" > $inc_cpu_load_tmp;
			echo "$dec_cpu_load_sleep" > $dec_cpu_load_tmp;
			echo "$up_sample_time_sleep" > $up_sample_time_tmp;
			echo "$down_sample_time_sleep" > $down_sample_time_tmp;
			echo "$hispeed_freq_sleep" > $hispeed_freq_tmp;
			echo "$hotplug_sampling_rate_sleep" > $hotplug_sampling_rate_tmp;
			echo "$hotplug_freq_1_1_sleep" > $hotplug_freq_1_1_tmp;
			echo "$hotplug_freq_2_0_sleep" > $hotplug_freq_2_0_tmp;
			echo "$hotplug_rq_1_1_sleep" > $hotplug_rq_1_1_tmp;
			echo "$hotplug_rq_2_0_sleep" > $hotplug_rq_2_0_tmp;
			echo "$check_rate_scroff" > $check_rate_scroff_tmp;
			echo "$freq_up_brake_sleep" > $freq_up_brake_tmp;
			echo "$pump_up_step_sleep" > $pump_up_step_tmp;
			echo "$pump_down_step_sleep" > $pump_down_step_tmp;
			echo "$check_rate_sleep" > $check_rate_tmp;
			echo "$check_rate_cpuon_sleep" > $check_rate_cpuon_tmp;
			echo "0" > $max_cpu_lock_tmp;
			echo "0" > $dvfs_debug_tmp;
			echo "$hotplug_lock_sleep" > $min_cpu_lock_tmp;
			echo "$hotplug_lock_sleep" > $hotplug_lock_tmp;
			echo "$freq_cpu1on_sleep" > $freq_cpu1on_tmp;
			echo "$freq_cpu1off_sleep" > $freq_cpu1off_tmp;
			echo "$trans_load_h0_scroff" > $trans_load_h0_scroff_tmp;
			echo "$trans_load_h1_scroff" > $trans_load_h1_scroff_tmp;
			echo "$trans_load_l1_scroff" > $trans_load_l1_scroff_tmp;
			echo "$trans_rq_sleep" > $trans_rq_tmp;
		# awake-settings
		elif [ "${state}" == "awake" ]; then
			echo "$sampling_rate" > $sampling_rate_tmp;
			echo "$cpu_up_rate" > $cpu_up_rate_tmp;
			echo "$cpu_down_rate" > $cpu_down_rate_tmp;
			echo "$up_threshold" > $up_threshold_tmp;
			echo "$up_threshold_at_min_freq" > $up_threshold_min_freq_tmp;
			echo "$inc_cpu_load_at_min_freq" > $inc_cpu_load_at_min_freq_tmp;
			echo "$down_threshold" > $down_threshold_tmp;
			echo "$sampling_up_factor" > $sampling_up_factor_tmp;
			echo "$sampling_down_factor" > $sampling_down_factor_tmp;
			echo "$down_differential" > $down_differential_tmp;
			echo "$freq_step" > $freq_step_tmp;
			echo "$freq_step_dec" > $freq_step_dec_tmp;
			echo "$freq_for_responsiveness" > $freq_responsiveness_tmp;
			echo "$inc_cpu_load" > $inc_cpu_load_tmp;
			echo "$dec_cpu_load" > $dec_cpu_load_tmp;
			echo "$up_sample_time" > $up_sample_time_tmp;
			echo "$down_sample_time" > $down_sample_time_tmp;
			echo "$hispeed_freq" > $hispeed_freq_tmp;
			echo "$hotplug_sampling_rate" > $hotplug_sampling_rate_tmp;
			echo "$hotplug_freq_1_1" > $hotplug_freq_1_1_tmp;
			echo "$hotplug_freq_2_0" > $hotplug_freq_2_0_tmp;
			echo "$hotplug_rq_1_1" > $hotplug_rq_1_1_tmp;
			echo "$hotplug_rq_2_0" > $hotplug_rq_2_0_tmp;
			echo "$freq_cpu1on" > $freq_cpu1on_tmp;
			echo "$freq_cpu1off" > $freq_cpu1off_tmp;
			echo "$freq_up_brake" > $freq_up_brake_tmp;
			echo "$pump_up_step" > $pump_up_step_tmp;
			echo "$pump_down_step" > $pump_down_step_tmp;
			echo "$check_rate" > $check_rate_tmp;
			echo "$check_rate_cpuon" > $check_rate_cpuon_tmp;
			echo "$screen_off_min_step" > $screen_off_min_step_tmp;
			echo "0" > $max_cpu_lock_tmp;
			echo "0" > $dvfs_debug_tmp;
			echo "$hotplug_lock" > $min_cpu_lock_tmp;
			echo "$hotplug_lock" > $hotplug_lock_tmp;
			echo "$trans_load_h0" > $trans_load_h0_tmp;
			echo "$trans_load_h1" > $trans_load_h1_tmp;
			echo "$trans_load_l1" > $trans_load_l1_tmp;
			echo "$trans_rq" > $trans_rq_tmp;
		fi;

		log -p i -t $FILE_NAME "*** CPU_GOV_TWEAKS: ${state} ***: enabled";
	fi;
}
if [ "$cortexbrain_background_process" == 0 ]; then
	CPU_GOV_TWEAKS "awake";
fi;

# this needed for cpu tweaks apply from STweaks in real time
apply_cpu=$2;
if [ "${apply_cpu}" == "update" ]; then
	CPU_GOV_TWEAKS "awake";
fi;

# ==============================================================
# MEMORY-TWEAKS
# ==============================================================
MEMORY_TWEAKS()
{
	if [ "$cortexbrain_memory" == on ]; then
		echo "$dirty_background_ratio" > /proc/sys/vm/dirty_background_ratio; # default: 10
		echo "$dirty_ratio" > /proc/sys/vm/dirty_ratio; # default: 20
		echo "4" > /proc/sys/vm/min_free_order_shift; # default: 4
		echo "0" > /proc/sys/vm/overcommit_memory; # default: 0
		echo "50" > /proc/sys/vm/overcommit_ratio; # default: 50
		echo "96 96" > /proc/sys/vm/lowmem_reserve_ratio;
		echo "3" > /proc/sys/vm/page-cluster; # default: 3
		echo "8192" > /proc/sys/vm/min_free_kbytes;

		log -p i -t $FILE_NAME "*** MEMORY_TWEAKS ***: enabled";
	fi;
}
MEMORY_TWEAKS;

# ==============================================================
# TCP-TWEAKS
# ==============================================================
TCP_TWEAKS()
{
	if [ "$cortexbrain_tcp" == on ]; then
		echo "0" > /proc/sys/net/ipv4/tcp_timestamps;
		echo "1" > /proc/sys/net/ipv4/tcp_tw_reuse;
		echo "1" > /proc/sys/net/ipv4/tcp_sack;
		echo "1" > /proc/sys/net/ipv4/tcp_tw_recycle;
		echo "1" > /proc/sys/net/ipv4/tcp_window_scaling;
		echo "1" > /proc/sys/net/ipv4/tcp_moderate_rcvbuf;
		echo "1" > /proc/sys/net/ipv4/route/flush;
		echo "2" > /proc/sys/net/ipv4/tcp_syn_retries;
		echo "2" > /proc/sys/net/ipv4/tcp_synack_retries;
		echo "10" > /proc/sys/net/ipv4/tcp_fin_timeout;
		echo "0" > /proc/sys/net/ipv4/tcp_ecn;
		echo "524288" > /proc/sys/net/core/wmem_max;
		echo "524288" > /proc/sys/net/core/rmem_max;
		echo "262144" > /proc/sys/net/core/rmem_default;
		echo "262144" > /proc/sys/net/core/wmem_default;
		echo "20480" > /proc/sys/net/core/optmem_max;
		echo "6144 87380 524288" > /proc/sys/net/ipv4/tcp_wmem;
		echo "6144 87380 524288" > /proc/sys/net/ipv4/tcp_rmem;
		echo "4096" > /proc/sys/net/ipv4/udp_rmem_min;
		echo "4096" > /proc/sys/net/ipv4/udp_wmem_min;

		log -p i -t $FILE_NAME "*** TCP_TWEAKS ***: enabled";
	fi;
}
TCP_TWEAKS;

# ==============================================================
# FIREWALL-TWEAKS
# ==============================================================
FIREWALL_TWEAKS()
{
	if [ "$cortexbrain_firewall" == on ]; then
		# ping/icmp protection
		echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts;
		echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_all;
		echo "1" > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses;

		# drop spoof, redirects, etc
		#echo "1" > /proc/sys/net/ipv4/conf/all/rp_filter;
		#echo "1" > /proc/sys/net/ipv4/conf/default/rp_filter;
		#echo "0" > /proc/sys/net/ipv4/conf/all/send_redirects;
		#echo "0" > /proc/sys/net/ipv4/conf/default/send_redirects;
		#echo "0" > /proc/sys/net/ipv4/conf/default/accept_redirects;
		#echo "0" > /proc/sys/net/ipv4/conf/all/accept_source_route;
		#echo "0" > /proc/sys/net/ipv4/conf/default/accept_source_route;

		log -p i -t $FILE_NAME "*** FIREWALL_TWEAKS ***: enabled";
	fi;
}
FIREWALL_TWEAKS;

# ==============================================================
# KSM-TWEAKS
# ==============================================================
KSM_MONITOR_INTERVAL=60;
KSM_NPAGES_BOOST=300;
KSM_NPAGES_DECAY=50;

KSM_NPAGES_MIN=32;
KSM_NPAGES_MAX=1000;
KSM_SLEEP_MSEC=200;
KSM_SLEEP_MIN=2000;

KSM_THRES_COEF=30;
KSM_THRES_CONST=2048;

npages=0;
total=`awk '/^MemTotal:/ {print $2}' /proc/meminfo`;
thres=$(( $total * $KSM_THRES_COEF / 100 ));

if [ $KSM_THRES_CONST -gt $thres ]; then
	thres=$KSM_THRES_CONST;
fi;

total=$(( $total / 1024 ));
sleep=$(( $KSM_SLEEP_MSEC * 16 * 1024 / $total ));

if [ $sleep -le $KSM_SLEEP_MIN ]; then
	sleep=$KSM_SLEEP_MIN;
fi;

KSMCTL()
{
	case x${1} in
		xstop)
			log -p i -t $FILE_NAME "*** ksm: stop ***";
			echo 0 > /sys/kernel/mm/ksm/run;
		;;
		xstart)
			log -p i -t $FILE_NAME "*** ksm: start ${2} ${3} ***";
			echo ${2} > /sys/kernel/mm/ksm/pages_to_scan;
			echo ${3} > /sys/kernel/mm/ksm/sleep_millisecs;
			echo 1 > /sys/kernel/mm/ksm/run;
			renice 10 -p "`pidof ksmd`";
		;;
	esac
}

FREE_MEM()
{
	awk '/^(MemFree|Buffers|Cached):/ {free += $2}; END {print free}' /proc/meminfo;
}

INCREASE_NPAGES()
{
	local delta=${1:-0};
	npages=$(( $npages + $delta ));
	if [ $npages -lt $KSM_NPAGES_MIN ]; then
		npages=$KSM_NPAGES_MIN;
	elif [ $npages -gt $KSM_NPAGES_MAX ]; then
		npages=$KSM_NPAGES_MAX;
	fi;
	echo $npages;
}

ADJUST_KSM()
{
	local free=`FREE_MEM`;
	if [ $free -gt $thres ]; then
		log -p i -t $FILE_NAME "*** ksm: $free > $thres ***";
		npages=`INCREASE_NPAGES ${KSM_NPAGES_BOOST}`;
		KSMCTL "stop";
		return 1;
	else
		npages=`INCREASE_NPAGES $KSM_NPAGES_DECAY`;
		log -p i -t $FILE_NAME "*** ksm: $free < $thres ***"
		KSMCTL "start" $npages $sleep;
		return 0;
	fi;
}

if [ "$cortexbrain_ksm_control" == on ]; then
	ADJUST_KSM;
fi;

# ==============================================================
# SCREEN-FUNCTIONS
# ==============================================================

WIFI_PM()
{
	local state="$1";
	if [ "${state}" == "sleep" ]; then
		if [ "$wifi_pwr" == on ]; then
			if [ -e /sys/module/dhd/parameters/wifi_pm ]; then
				echo "1" > /sys/module/dhd/parameters/wifi_pm;
			fi;
		fi;

		if [ "$supplicant_scan_interval" -le 180 ]; then
			setprop wifi.supplicant_scan_interval 360;
		fi;
	elif [ "${state}" == "awake" ]; then
		if [ -e /sys/module/dhd/parameters/wifi_pm ]; then
			echo "0" > /sys/module/dhd/parameters/wifi_pm;
		fi;

		setprop wifi.supplicant_scan_interval $supplicant_scan_interval;
	fi;

	log -p i -t $FILE_NAME "*** WIFI_PM ***: ${state}";
}

WIFI()
{
	local state="$1";
	if [ "${state}" == "sleep" ]; then
		WIFI_PM "sleep";
		if [ -e /sys/module/dhd/initstate ]; then
			if [ "$cortexbrain_auto_tweak_wifi" == on ]; then
				if [ "$cortexbrain_auto_tweak_wifi_sleep_delay" == 0 ]; then
					svc wifi disable;
					echo "1" > /data/.siyah/wifi_helper_awake;
					log -p i -t $FILE_NAME "*** WIFI ***: disabled";
				else
					(
						echo "0" > /data/.siyah/wifi_helper;
						# screen time out but user want to keep it on and have wifi
						sleep 10;
						if [ `cat /data/.siyah/wifi_helper` == "0" ]; then
							# user did not turned screen on, so keep waiting
							SLEEP_TIME=$(( $cortexbrain_auto_tweak_wifi_sleep_delay - 10 ));
							log -p i -t $FILE_NAME "*** DISABLE_WIFI $cortexbrain_auto_tweak_wifi_sleep_delay Sec Delay Mode ***";
							sleep $SLEEP_TIME;
							if [ `cat /data/.siyah/wifi_helper` == "0" ]; then
								# user left the screen off, then disable wifi
								svc wifi disable;
								echo "1" > /data/.siyah/wifi_helper_awake;
								log -p i -t $FILE_NAME "*** WIFI ***: disabled";
							fi;
						fi;
					)&
				fi;
			fi;
		else
			echo "0" > /data/.siyah/wifi_helper_awake;
		fi;
	elif [ "${state}" == "awake" ]; then
		WIFI_PM "awake";
		echo "1" > /data/.siyah/wifi_helper;
		if [ `cat /data/.siyah/wifi_helper_awake` == "1" ]; then
			if [ "$cortexbrain_auto_tweak_wifi" == on ]; then
				svc wifi enable;
				log -p i -t $FILE_NAME "*** WIFI ***: enabled";
			fi;
		fi;
	fi;
}

LOGGER()
{
	local state="$1";
	if [ "${state}" == "awake" ]; then
		if [ "$android_logger" == auto ] || [ "$android_logger" == debug ]; then
			if [ -e /dev/log-sleep ] && [ ! -e /dev/log ]; then
				mv /dev/log-sleep/ /dev/log/
			fi;
		fi;
	elif [ "${state}" == "sleep" ]; then
		if [ "$android_logger" == auto ] || [ "$android_logger" == disabled ]; then
			if [ -e /dev/log ]; then
				mv /dev/log/ /dev/log-sleep/;
			fi;
		fi;
	fi;

	log -p i -t $FILE_NAME "*** LOGGER ***: ${state}";
}

GESTURES()
{
	local state="$1";
	if [ "${state}" == "awake" ]; then
		if [ "$gesture_tweak" == on ]; then
			pkill -f "/data/gesture_set.sh";
			pkill -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture";
			nohup /sbin/busybox sh /data/gesture_set.sh;
		fi;
	elif [ "${state}" == "sleep" ]; then
		if [ `pgrep -f "/data/gesture_set.sh" | wc -l` != 0 ] || [ `pgrep -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture" | wc -l` != 0 ] || [ "$gesture_tweak" == off ]; then
			pkill -f "/data/gesture_set.sh";
			pkill -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture";
		fi;
	fi;

	log -p i -t $FILE_NAME "*** GESTURE ***: ${state}";
}

# mount sdcard and emmc, if usb mass storage is used
MOUNT_SD_CARD()
{
	if [ "$auto_mount_sd" == on ]; then
		echo "/dev/block/vold/259:3" > /sys/devices/virtual/android_usb/android0/f_mass_storage/lun0/file;
		if [ -e /dev/block/vold/179:25 ]; then
			echo "/dev/block/vold/179:25" > /sys/devices/virtual/android_usb/android0/f_mass_storage/lun1/file;
		fi;

		log -p i -t $FILE_NAME "*** MOUNT_SD_CARD ***";
	fi;
}

# set delay to prevent mp3-music shattering when screen turned ON
DELAY()
{
	if [ ! -e /data/.siyah/booting ]; then
		if [ "$wakeup_delay" != 0 ]; then
			log -p i -t $FILE_NAME "*** DELAY ${delay}sec ***";
			sleep $wakeup_delay;
		fi;
	fi;
}

MALI_TIMEOUT()
{
	local state="$1";
	if [ "${state}" == "awake" ]; then
		echo "$mali_gpu_utilization_timeout" > /sys/module/mali/parameters/mali_gpu_utilization_timeout;
	elif [ "${state}" == "sleep" ]; then
		echo "250" > /sys/module/mali/parameters/mali_gpu_utilization_timeout;
	elif [ "${state}" == "performance" ]; then
		echo "100" > /sys/module/mali/parameters/mali_gpu_utilization_timeout;
	fi;

	log -p i -t $FILE_NAME "*** MALI_TIMEOUT: ${state} ***";
}

# boost CPU power for fast and no lag wakeup
MEGA_BOOST_CPU_TWEAKS()
{
	if [ "$cortexbrain_cpu" == on ]; then
		echo "$scaling_governor" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;

		CPU_GOV_TWEAKS "performance";

		echo "25" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;

		MALI_TIMEOUT "performance";

		echo "20" > /sys/module/stand_hotplug/parameters/load_h0;
		echo "20" > /sys/module/stand_hotplug/parameters/load_l1;

		if [ "$scaling_max_freq" == 1200000 ] && [ "$scaling_max_freq_oc" -ge 1200000 ]; then
			echo "$scaling_max_freq_oc" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
		elif [ "$scaling_max_freq" -ge 1000000 ]; then
			echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
		else
			echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
		fi;

		echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;

		log -p i -t $FILE_NAME "*** MEGA_BOOST_CPU_TWEAKS ***";
	fi;
}

BOOST_DELAY()
{
	# check if ROM booting now, then don't wait - creation and deletion of /data/.siyah/booting @> /sbin/ext/post-init.sh
	if [ "$wakeup_boost" != 0 ] && [ ! -e /data/.siyah/booting ]; then
		log -p i -t $FILE_NAME "*** MEGA_BOOST_DELAY ${wakeup_boost}sec ***";
		sleep $wakeup_boost;
	fi;
}

# set swappiness in case that no root installed, and zram used or disk swap used
SWAPPINESS()
{
	local SWAP_CHECK=`free | grep Swap | awk '{ print $2 }'`;
	if [ "$SWAP_CHECK" == 0 ]; then
		echo "0" > /proc/sys/vm/swappiness;
	else
		echo "$swappiness" > /proc/sys/vm/swappiness;
	fi;

	log -p i -t $FILE_NAME "*** SWAPPINESS: $swappiness ***";
}

# disable/enable ipv6  
IPV6()
{
	local CISCO_VPN=`find /data/data/com.cisco.anyconnec* | wc -l`;
	local state='';
	if [ "$cortexbrain_ipv6" == on ] || [ "$CISCO_VPN" != 0 ]; then
		echo "0" > /proc/sys/net/ipv6/conf/wlan0/disable_ipv6;
		sysctl -w net.ipv6.conf.all.disable_ipv6=0;
		state='enabled';
	else
		echo "1" > /proc/sys/net/ipv6/conf/wlan0/disable_ipv6;
		sysctl -w net.ipv6.conf.all.disable_ipv6=1;
		state='disabled';
	fi;

	log -p i -t $FILE_NAME "*** IPV6 ***: ${state}";
}

KERNEL_SCHED()
{
	local state="$1";

	if [ "${state}" == "awake" ]; then
		echo "0" > /proc/sys/kernel/sched_child_runs_first;
		echo "1000000" > /proc/sys/kernel/sched_latency_ns;
		echo "100000" > /proc/sys/kernel/sched_min_granularity_ns;
		echo "2000000" > /proc/sys/kernel/sched_wakeup_granularity_ns;
	elif [ "${state}" == "sleep" ]; then
		echo "1" > /proc/sys/kernel/sched_child_runs_first;
		echo "5000000" > /proc/sys/kernel/sched_latency_ns;
		echo "1500000" > /proc/sys/kernel/sched_min_granularity_ns;
		echo "2000000" > /proc/sys/kernel/sched_wakeup_granularity_ns;
	fi;
	echo "-1" > /proc/sys/kernel/sched_rt_runtime_us;

	log -p i -t $FILE_NAME "*** KERNEL_SCHED ***: ${state}";
}

BLN_CORRECTION()
{
	if [ "$notification_enabled" == on ]; then
		echo "1" > /sys/class/misc/notification/notification_enabled;

		if [ "$blnww" == off ]; then
			if [ "$bln_switch" == 0 ]; then
				/res/uci.sh bln_switch 0;
			elif [ "$bln_switch" == 1 ]; then
				/res/uci.sh bln_switch 1;
			elif [ "$bln_switch" == 2 ]; then
				/res/uci.sh bln_switch 2;
			fi;
		else
			/res/uci.sh bln_switch 0;
		fi;

		if [ "$dyn_brightness" == on ]; then
			echo "0" > /sys/class/misc/notification/dyn_brightness;
		fi;

		log -p i -t $FILE_NAME "*** BLN_CORRECTION ***";
	fi;
}

TOUCH_KEYS_CORRECTION()
{
	if [ "$dyn_brightness" == on ]; then
		echo "1" > /sys/class/misc/notification/dyn_brightness;
	fi;

	if [ "$led_timeout_ms" == 0 ]; then
		echo "0" > /sys/class/misc/notification/led_timeout_ms;
	else
		/res/uci.sh generic /sys/class/misc/notification/led_timeout_ms $led_timeout_ms;
	fi;

	log -p i -t $FILE_NAME "*** TOUCH_KEYS_CORRECTION: $dyn_brightness - ${led_timeout_ms}ms ***";
}

# if crond used, then give it root perent - if started by STweaks, then it will be killed in time
CROND_SAFETY()
{
	if [ "$crontab" == on ]; then
		pkill -f "crond";
		/res/crontab_service/service.sh;
		log -p i -t $FILE_NAME "*** CROND_SAFETY ***";
	fi;
}

GAMMA_FIX()
{
	echo "$min_gamma" > /sys/class/misc/brightness_curve/min_gamma;
	echo "$max_gamma" > /sys/class/misc/brightness_curve/max_gamma;

	log -p i -t $FILE_NAME "*** GAMMA_FIX: min: $min_gamma max: $max_gamma ***: done";
}

ENABLEMASK()
{
	local state="$1";
	if [ "${state}" == "awake" ]; then
		echo "$enable_mask" > /sys/module/cpuidle_exynos4/parameters/enable_mask;
	elif [ "${state}" == "sleep" ]; then
		echo "$enable_mask_sleep" > /sys/module/cpuidle_exynos4/parameters/enable_mask;
	fi;

	log -p i -t $FILE_NAME "*** ENABLEMASK ${state} ***: done";
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	if [ `cat /tmp/sleeprun` == 1 ]; then

		LOGGER "awake";

		DELAY;

		ENABLEMASK "awake";

		KERNEL_SCHED "awake";

		MEGA_BOOST_CPU_TWEAKS;

		echo "$scheduler" > /sys/block/mmcblk0/queue/scheduler;
		echo "$scheduler" > /sys/block/mmcblk1/queue/scheduler;

		WIFI "awake";

		GESTURES "awake";

		GAMMA_FIX;

		TOUCH_KEYS_CORRECTION;

		MOUNT_SD_CARD;

		if [ "$cortexbrain_ksm_control" == on ]; then
			ADJUST_KSM;
		fi;

		echo "$pwm_val" > /sys/vibrator/pwm_val;

		BOOST_DELAY;

		echo "100" > /proc/sys/vm/vfs_cache_pressure;

		CPU_GOV_TWEAKS "awake";

		echo "$busfreq_up_threshold" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;

		echo "$load_h0" > /sys/module/stand_hotplug/parameters/load_h0;
		echo "$load_l1" > /sys/module/stand_hotplug/parameters/load_l1;

		if [ "$cortexbrain_cpu" == on ]; then
			echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;

			if [ "$scaling_max_freq" == 1200000 ] && [ "$scaling_max_freq_oc" -ge 1200000 ]; then
				echo "$scaling_max_freq_oc" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			else
				echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			fi;
		fi;

		MALI_TIMEOUT "awake";

		log -p i -t $FILE_NAME "*** AWAKE Normal Mode ***";
	fi;
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	mount -o remount,rw /
	echo "0" > /tmp/sleeprun;

	# we only read the config when screen goes off ...
	PROFILE=`cat /data/.siyah/.active.profile`;
	. /data/.siyah/$PROFILE.profile;

	DELAY;

	ENABLEMASK "sleep";

	if [ `cat /tmp/early_wakeup` == 0 ]; then

		if [ "$cortexbrain_cpu" == on ]; then
			echo "$standby_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
		fi;

		MALI_TIMEOUT "sleep";

		KERNEL_SCHED "sleep";

		GESTURES "sleep";

		IPV6;

		BATTERY_TWEAKS;

		BLN_CORRECTION;

		CROND_SAFETY;

		if [ "$cortexbrain_ksm_control" == on ]; then
			KSMCTL "stop";
		else
			echo 2 > /sys/kernel/mm/ksm/run;
		fi;

		SWAPPINESS;

		CHARGING=`cat /sys/class/power_supply/battery/charging_source`;
		if [ "$CHARGING" == 0 ]; then
			if [ "$cortexbrain_cpu" == on ]; then
				echo "$deep_sleep" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
				echo "$scaling_min_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_suspend_freq;
				echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
				echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
				CPU_GOV_TWEAKS "sleep";
			fi;

			echo "80" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;

			echo "$sleep_scheduler" > /sys/block/mmcblk0/queue/scheduler;
			echo "$sleep_scheduler" > /sys/block/mmcblk1/queue/scheduler;

			echo "50" > /sys/module/stand_hotplug/parameters/load_h0;
			echo "50" > /sys/module/stand_hotplug/parameters/load_l1;

			echo "10" > /proc/sys/vm/vfs_cache_pressure; # default: 100
		
			WIFI "sleep";

			log -p i -t $FILE_NAME "*** SLEEP mode ***";

			LOGGER "sleep";
		else
			echo "USB CABLE CONNECTED! No real sleep mode!"
			log -p i -t $FILE_NAME "*** SCREEN OFF BUT POWERED mode ***";
		fi;

		echo "1" > /tmp/sleeprun;
		pkill -f "cat /sys/power/wait_for_fb_wake"

	else
		log -p i -t $FILE_NAME "*** Early WakeUp detected! SLEEP aborted! ***";
	fi;
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" == 1 ] && [ `pgrep -f "cat /sys/power/wait_for_fb_sleep" | wc -l` == 0 ] && [ `pgrep -f "cat /sys/power/wait_for_fb_wake" | wc -l` == 0 ]; then
	(while [ 1 ]; do
		# AWAKE State. all system ON
		cat /sys/power/wait_for_fb_wake > /dev/null 2>&1;
		AWAKE_MODE;
		sleep 3;

		# SLEEP state. All system to power save
		cat /sys/power/wait_for_fb_sleep > /dev/null 2>&1;
		sleep 3;
		/sbin/ext/wakecheck.sh;
		SLEEP_MODE;
	done &);
else
	if [ "$cortexbrain_background_process" == 0 ]; then
		echo "Cortex background disabled!"
	else
		echo "Cortex background process already running!";
	fi;
fi;

# ==============================================================
# Logic Explanations
#
# This script will manipulate all the system / cpu / battery behavior
# Based on chosen STWEAKS profile+tweaks and based on SCREEN ON/OFF state.
#
# When User select battery/default profile all tuning will be toward battery save.
# But user loose performance -20% and get more stable system and more battery left.
#
# When user select performance profile, tuning will be to max performance on screen ON.
# When screen OFF all tuning switched to max power saving. as with battery profile,
# So user gets max performance and max battery save but only on screen OFF.
#
# This script change governors and tuning for them on the fly.
# Also switch on/off hotplug CPU core based on screen on/off.
# This script reset battery stats when battery is 100% charged.
# This script tune Network and System VM settings and ROM settings tuning.
# This script changing default MOUNT options and I/O tweaks for all flash disks and ZRAM.
#
# TODO: add more description, explanations & default vaules ...
#
