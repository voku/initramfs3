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
#
# This script must be activated after init start =< 25sec or parameters from /sys/* will not be loaded.

# ==============================================================
# INIT
# ==============================================================
FILE_NAME=$0;
PIDOFCORTEX=$$;
# (since we don't have the recovery source code I can't change the ".siyah" dir, so just leave it there for history)
DATA_DIR=/data/.siyah
WAS_IN_SLEEP_MODE=1;
NOW_CALL_STATE=0;
USB_POWER=0;

# WIFI HELPER
WIFI_HELPER_AWAKE="$DATA_DIR/WIFI_HELPER_AWAKE";
WIFI_HELPER_TMP="$DATA_DIR/WIFI_HELPER_TMP";
echo "1" > $WIFI_HELPER_TMP;

# MOBILE HELPER
MOBILE_HELPER_AWAKE="$DATA_DIR/MOBILE_HELPER_AWAKE";
MOBILE_HELPER_TMP="$DATA_DIR/MOBILE_HELPER_TMP";
echo "1" > $MOBILE_HELPER_TMP;

# change mode
chmod -R 777 /tmp/;
chmod 766 /sys/kernel/mm/uksm/run;
chmod 766 /sys/kernel/mm/uksm/sleep_millisecs;
chmod 766 /sys/kernel/mm/uksm/max_cpu_percentage;
chmod 766 /sys/kernel/mm/uksm/cpu_governor;

# get values from profile
PROFILE=`cat $DATA_DIR/.active.profile`;
. $DATA_DIR/${PROFILE}.profile;

# set initial vm.dirty vales
echo "500" > /proc/sys/vm/dirty_writeback_centisecs;
echo "1000" > /proc/sys/vm/dirty_expire_centisecs;

# check if dumpsys exist in ROM
if [ -e /system/bin/dumpsys ]; then
	DUMPSYS_STATE=1;
else
	DUMPSYS_STATE=0;
fi;

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

			if [ -e $i/queue/nr_requests ]; then
				echo "128" > $i/queue/nr_requests; # default: 128
			fi;
		done;

		# our storage is 16GB, best is 1024KB readahead
		# see https://github.com/Keff/samsung-kernel-msm7x30/commit/a53f8445ff8d947bd11a214ab42340cc6d998600#L1R627
		echo "1024" > /sys/block/mmcblk0/queue/read_ahead_kb;

		if [ -e /sys/block/mmcblk1/queue/read_ahead_kb ]; then
			if [ "$cortexbrain_read_ahead_kb" -eq "0" ]; then

				local SDCARD_SIZE=`cat /tmp/sdcard_size`;
				if [ "$SDCARD_SIZE" -eq "1" ]; then
					echo "256" > /sys/block/mmcblk1/queue/read_ahead_kb;
				elif [ "$SDCARD_SIZE" -eq "4" ]; then
					echo "512" > /sys/block/mmcblk1/queue/read_ahead_kb;
				elif [ "$SDCARD_SIZE" -eq "8" ] || [ "$SDCARD_SIZE" -eq "16" ]; then
					echo "1024" > /sys/block/mmcblk1/queue/read_ahead_kb;
				elif [ "$SDCARD_SIZE" -eq "32" ]; then
					echo "2048" > /sys/block/mmcblk1/queue/read_ahead_kb;
				elif [ "$SDCARD_SIZE" -eq "64" ]; then
					echo "2560" > /sys/block/mmcblk1/queue/read_ahead_kb;
				fi;

			else
				echo "$cortexbrain_read_ahead_kb" > /sys/block/mmcblk1/queue/read_ahead_kb;
			fi;
		fi;

		echo "45" > /proc/sys/fs/lease-break-time;

		log -p i -t $FILE_NAME "*** IO_TWEAKS ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
IO_TWEAKS;

# ==============================================================
# KERNEL-TWEAKS
# ==============================================================
KERNEL_TWEAKS()
{
	local state="$1";

	if [ "$cortexbrain_kernel_tweaks" == on ]; then

		if [ "$state" == "awake" ]; then
			echo "0" > /proc/sys/vm/oom_kill_allocating_task;
			echo "0" > /proc/sys/vm/panic_on_oom;
			echo "60" > /proc/sys/kernel/panic;
		elif [ "$state" == "sleep" ]; then
			echo "0" > /proc/sys/vm/oom_kill_allocating_task;
			echo "0" > /proc/sys/vm/panic_on_oom;
			echo "90" > /proc/sys/kernel/panic;
		else
			echo "0" > /proc/sys/vm/oom_kill_allocating_task;
			echo "0" > /proc/sys/vm/panic_on_oom;
			echo "60" > /proc/sys/kernel/panic;
		fi;

		if [ "$cortexbrain_memory" == on ]; then
			echo "32 32" > /proc/sys/vm/lowmem_reserve_ratio;
		fi;

		log -p i -t $FILE_NAME "*** KERNEL_TWEAKS ***: $state ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
KERNEL_TWEAKS;

# ==============================================================
# SYSTEM-TWEAKS
# ==============================================================
SYSTEM_TWEAKS()
{
	if [ "$cortexbrain_system" == on ]; then
		setprop hwui.render_dirty_regions false;
		setprop windowsmgr.max_events_per_sec 240;
		setprop profiler.force_disable_err_rpt 1;
		setprop profiler.force_disable_ulog 1;

		log -p i -t $FILE_NAME "*** SYSTEM_TWEAKS ***: enabled";

		return 1;
	else
		return 0;
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

		if [ "$LEVEL" -eq "100" ] && [ "$BATTFULL" -eq "1" ]; then
			rm -f /data/system/batterystats.bin;
			log -p i -t $FILE_NAME "battery-calibration done ...";
		fi;

		# LCD: power-reduce
		if [ -e /sys/class/lcd/panel/power_reduce ]; then
			if [ "$power_reduce" == on ]; then
				echo "1" > /sys/class/lcd/panel/power_reduce;
			else
				echo "0" > /sys/class/lcd/panel/power_reduce;
			fi;
		fi;

		# USB: power support
		local POWER_LEVEL=`ls /sys/bus/usb/devices/*/power/control`;
		for i in $POWER_LEVEL; do
			chmod 777 $i;
			echo "auto" > $i;
		done;

		local POWER_AUTOSUSPEND=`ls /sys/bus/usb/devices/*/power/autosuspend`;
		for i in $POWER_AUTOSUSPEND; do
			chmod 777 $i;
			echo "1" > $i;
		done;

		# BUS: power support
		buslist="spi i2c sdio";
		for bus in $buslist; do
			local POWER_CONTROL=`ls /sys/bus/$bus/devices/*/power/control`;
			for i in $POWER_CONTROL; do
				chmod 777 $i;
				echo "auto" > $i;
			done;
		done;

		log -p i -t $FILE_NAME "*** BATTERY_TWEAKS ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
# run this tweak once, if the background-process is disabled
if [ "$cortexbrain_background_process" -eq "0" ]; then
	BATTERY_TWEAKS;
fi;

# ==============================================================
# CPU-TWEAKS
# ==============================================================

CPU_INTELLI_PLUG_TWEAKS()
{
	local SYSTEM_GOVERNOR=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`;
	local intelli_plug_active_tmp="/sys/module/intelli_plug/parameters/intelli_plug_active";

	if [ -e $intelli_plug_active_tmp ]; then
		local IPA_CHECK=`cat $intelli_plug_active_tmp`;

		local hotplug_enable_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_enable";
		if [ ! -e $hotplug_enable_tmp ]; then
			hotplug_enable_tmp="/dev/null";
		fi;

		if [ "a$IPA_CHECK" == "a1" ]; then
			if [ "$hotplug_enable" -eq "1" ] && [ "$SYSTEM_GOVERNOR" == "nightmare" ]; then
				echo "0" > $intelli_plug_active_tmp;
				echo "$hotplug_enable" > $hotplug_enable_tmp;

				log -p i -t $FILE_NAME "*** CPU_INTELLI_PLUG ***: disabled";
			fi;
		else
			if [ "$hotplug_enable" -eq "0" ] || [ "$SYSTEM_GOVERNOR" != "nightmare" ]; then
				echo "1" > $intelli_plug_active_tmp;
				echo "$hotplug_enable" > $hotplug_enable_tmp;

				log -p i -t $FILE_NAME "*** CPU_INTELLI_PLUG ***: enabled";
			fi;
		fi;
	fi;
}

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

		local up_threshold_at_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold_at_min_freq";
		if [ ! -e $up_threshold_at_min_freq_tmp ]; then
			up_threshold_at_min_freq_tmp="/dev/null";
		fi;

		local up_threshold_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold_min_freq";
		if [ ! -e $up_threshold_min_freq_tmp ]; then
			up_threshold_min_freq_tmp="/dev/null";
		fi;

		local inc_cpu_load_at_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/inc_cpu_load_at_min_freq";
		if [ ! -e $inc_cpu_load_at_min_freq_tmp ]; then
			inc_cpu_load_at_min_freq_tmp="/dev/null";
		fi;

		local hotplug_cmp_level_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_compare_level";
		if [ ! -e $hotplug_cmp_level_tmp ]; then
			hotplug_cmp_level_tmp="/dev/null";
		fi;

		local hotplug_freq_fst_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_freq_1_1";
		if [ ! -e $hotplug_freq_fst_tmp ]; then
			hotplug_freq_fst_tmp="/dev/null";
		fi;

		local hotplug_freq_snd_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_freq_2_0";
		if [ ! -e $hotplug_freq_snd_tmp ]; then
			hotplug_freq_snd_tmp="/dev/null";
		fi;

		local hotplug_rq_fst_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_rq_1_1";
		if [ ! -e $hotplug_rq_fst_tmp ]; then
			hotplug_rq_fst_tmp="/dev/null";
		fi;

		local hotplug_rq_snd_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_rq_2_0";
		if [ ! -e $hotplug_rq_snd_tmp ]; then
			hotplug_rq_snd_tmp="/dev/null";
		fi;

		local up_avg_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_avg_load";
		if [ ! -e $up_avg_load_tmp ]; then
			up_avg_load_tmp="/dev/null";
		fi;

		local down_avg_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/down_avg_load";
		if [ ! -e $down_avg_load_tmp ]; then
			down_avg_load_tmp="/dev/null";
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

		local freq_for_responsiveness_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_for_responsiveness";
		if [ ! -e $freq_for_responsiveness_tmp ]; then
			freq_for_responsiveness_tmp="/dev/null";
		fi;

		local freq_responsiveness_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_responsiveness";
		if [ ! -e $freq_responsiveness_tmp ]; then
			freq_responsiveness_tmp="/dev/null";
		fi;

		local freq_for_responsiveness_max_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_for_responsiveness_max";
		if [ ! -e $freq_for_responsiveness_max_tmp ]; then
			freq_for_responsiveness_max_tmp="/dev/null";
		fi;

		local freq_step_at_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step_at_min_freq";
		if [ ! -e $freq_step_at_min_freq_tmp ]; then
			freq_step_at_min_freq_tmp="/dev/null";
		fi;

		local freq_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step";
		if [ ! -e $freq_step_tmp ]; then
			freq_step_tmp="/dev/null";
		fi;

		local freq_step_dec_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step_dec";
		if [ ! -e $freq_step_dec_tmp ]; then
			freq_step_dec_tmp="/dev/null";
		fi;

		local freq_step_dec_at_max_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step_dec_at_max_freq";
		if [ ! -e $freq_step_dec_at_max_freq_tmp ]; then
			freq_step_dec_at_max_freq_tmp="/dev/null";
		fi;

		local freq_for_calc_incr_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_for_calc_incr";
		if [ ! -e $freq_for_calc_incr_tmp ]; then
			freq_for_calc_incr_tmp="/dev/null";
		fi;

		local freq_for_calc_decr_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_for_calc_decr";
		if [ ! -e $freq_for_calc_decr_tmp ]; then
			freq_for_calc_decr_tmp="/dev/null";
		fi;

		local up_sf_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_sf_step";
		if [ ! -e $up_sf_step_tmp ]; then
			up_sf_step_tmp="/dev/null";
		fi;

		local down_sf_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/down_sf_step";
		if [ ! -e $down_sf_step_tmp ]; then
			down_sf_step_tmp="/dev/null";
		fi;

		local inc_cpu_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/inc_cpu_load";
		if [ ! -e $inc_cpu_load_tmp ]; then
			inc_cpu_load_tmp="/dev/null";
		fi;

		local dec_cpu_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/dec_cpu_load";
		if [ ! -e $dec_cpu_load_tmp ]; then
			dec_cpu_load_tmp="/dev/null";
		fi;

		local freq_up_brake_at_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_up_brake_at_min_freq";
		if [ ! -e $freq_up_brake_at_min_freq_tmp ]; then
			freq_up_brake_at_min_freq_tmp="/dev/null";
		fi;

		local freq_up_brake_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_up_brake";
		if [ ! -e $freq_up_brake_tmp ]; then
			freq_up_brake_tmp="/dev/null";
		fi;

		# merge up_threshold_at_min_freq & up_threshold_min_freq => up_threshold_at_min_freq_tmp
		if [ $up_threshold_at_min_freq_tmp == "/dev/null" ] && [ $up_threshold_min_freq_tmp != "/dev/null" ]; then
			up_threshold_at_min_freq_tmp=$up_threshold_min_freq_tmp;
		fi;

		# merge freq_for_responsiveness_tmp & freq_responsiveness_tmp => freq_for_responsiveness_tmp
		if [ $freq_for_responsiveness_tmp == "/dev/null" ] && [ $freq_responsiveness_tmp != "/dev/null" ]; then
			freq_for_responsiveness_tmp=$freq_responsiveness_tmp;
		fi;

		# wake_boost-settings
		if [ "$state" == "wake_boost" ]; then
			echo "20000" > $sampling_rate_tmp;
			echo "10" > $cpu_up_rate_tmp;
			echo "10" > $cpu_down_rate_tmp;
			echo "10" > $down_threshold_tmp;
			echo "40" > $up_threshold_tmp;
			echo "40" > $up_threshold_at_min_freq_tmp;
			echo "100" > $freq_step_tmp;
			echo "800000" > $freq_for_responsiveness_tmp;
			echo "50000" > $sampling_rate_tmp;
		# sleep-settings
		elif [ "$state" == "sleep" ]; then
			echo "$sampling_rate_sleep" > $sampling_rate_tmp;
			echo "$cpu_up_rate_sleep" > $cpu_up_rate_tmp;
			echo "$cpu_down_rate_sleep" > $cpu_down_rate_tmp;
			echo "$up_threshold_sleep" > $up_threshold_tmp;
			echo "$up_threshold_at_min_freq_sleep" > $up_threshold_at_min_freq_tmp;
			echo "$inc_cpu_load_at_min_freq_sleep" > $inc_cpu_load_at_min_freq_tmp;
			echo "$hotplug_cmp_level_sleep" > $hotplug_cmp_level_tmp;
			echo "$hotplug_freq_fst_sleep" > $hotplug_freq_fst_tmp;
			echo "$hotplug_freq_snd_sleep" > $hotplug_freq_snd_tmp;
			echo "$hotplug_rq_fst_sleep" > $hotplug_rq_fst_tmp;
			echo "$hotplug_rq_snd_sleep" > $hotplug_rq_snd_tmp;
			echo "$up_avg_load_sleep" > $up_avg_load_tmp;
			echo "$down_avg_load_sleep" > $down_avg_load_tmp;
			echo "$down_threshold_sleep" > $down_threshold_tmp;
			echo "$sampling_up_factor_sleep" > $sampling_up_factor_tmp;
			echo "$sampling_down_factor_sleep" > $sampling_down_factor_tmp;
			echo "$down_differential_sleep" > $down_differential_tmp;
			echo "$freq_step_at_min_freq_sleep" > $freq_step_at_min_freq_tmp;
			echo "$freq_step_sleep" > $freq_step_tmp;
			echo "$freq_step_dec_sleep" > $freq_step_dec_tmp;
			echo "$freq_step_dec_at_max_freq_sleep" > $freq_step_dec_at_max_freq_tmp;
			echo "$freq_for_responsiveness_sleep" > $freq_for_responsiveness_tmp;
			echo "$freq_for_responsiveness_max_sleep" > $freq_for_responsiveness_max_tmp;
			echo "$freq_for_calc_incr_sleep" > $freq_for_calc_incr_tmp;
			echo "$freq_for_calc_decr_sleep" > $freq_for_calc_decr_tmp;
			echo "$up_sf_step_sleep" > $up_sf_step_tmp;
			echo "$down_sf_step_sleep" > $down_sf_step_tmp;
			echo "$inc_cpu_load_sleep" > $inc_cpu_load_tmp;
			echo "$dec_cpu_load_sleep" > $dec_cpu_load_tmp;
			echo "$freq_up_brake_at_min_freq_sleep" > $freq_up_brake_at_min_freq_tmp;
			echo "$freq_up_brake_sleep" > $freq_up_brake_tmp;
		# awake-settings
		elif [ "$state" == "awake" ]; then
			echo "$sampling_rate" > $sampling_rate_tmp;
			echo "$cpu_up_rate" > $cpu_up_rate_tmp;
			echo "$cpu_down_rate" > $cpu_down_rate_tmp;
			echo "$up_threshold" > $up_threshold_tmp;
			echo "$up_threshold_at_min_freq" > $up_threshold_at_min_freq_tmp;
			echo "$inc_cpu_load_at_min_freq" > $inc_cpu_load_at_min_freq_tmp;
			echo "$hotplug_cmp_level" > $hotplug_cmp_level_tmp;
			echo "$hotplug_freq_fst" > $hotplug_freq_fst_tmp;
			echo "$hotplug_freq_snd" > $hotplug_freq_snd_tmp;
			echo "$hotplug_rq_fst" > $hotplug_rq_fst_tmp;
			echo "$hotplug_rq_snd" > $hotplug_rq_snd_tmp;
			echo "$up_avg_load" > $up_avg_load_tmp;
			echo "$down_avg_load" > $down_avg_load_tmp;
			echo "$down_threshold" > $down_threshold_tmp;
			echo "$sampling_up_factor" > $sampling_up_factor_tmp;
			echo "$sampling_down_factor" > $sampling_down_factor_tmp;
			echo "$down_differential" > $down_differential_tmp;
			echo "$freq_step_at_min_freq" > $freq_step_at_min_freq_tmp;
			echo "$freq_step" > $freq_step_tmp;
			echo "$freq_step_dec" > $freq_step_dec_tmp;
			echo "$freq_step_dec_at_max_freq" > $freq_step_dec_at_max_freq_tmp;
			echo "$freq_for_responsiveness" > $freq_for_responsiveness_tmp;
			echo "$freq_for_responsiveness_max" > $freq_for_responsiveness_max_tmp;
			echo "$freq_for_calc_incr" > $freq_for_calc_incr_tmp;
			echo "$freq_for_calc_decr" > $freq_for_calc_decr_tmp;
			echo "$up_sf_step" > $up_sf_step_tmp;
			echo "$down_sf_step" > $down_sf_step_tmp;
			echo "$inc_cpu_load" > $inc_cpu_load_tmp;
			echo "$dec_cpu_load" > $dec_cpu_load_tmp;
			echo "$freq_up_brake_at_min_freq" > $freq_up_brake_at_min_freq_tmp;
			echo "$freq_up_brake" > $freq_up_brake_tmp;
		fi;

		CPU_INTELLI_PLUG_TWEAKS;

		log -p i -t $FILE_NAME "*** CPU_GOV_TWEAKS: $state ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
# this needed for cpu tweaks apply from STweaks in real time
apply_cpu="$2";
if [ "$apply_cpu" == "update" ] || [ "$cortexbrain_background_process" -eq "0" ]; then
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
		echo "1" > /proc/sys/vm/overcommit_memory; # default: 1
		echo "20" > /proc/sys/vm/overcommit_ratio; # default: 50
		echo "32 32" > /proc/sys/vm/lowmem_reserve_ratio;
		echo "3" > /proc/sys/vm/page-cluster; # default: 3
		echo "8192" > /proc/sys/vm/min_free_kbytes;
		echo "8192" > /proc/sys/vm/mmap_min_addr;

		log -p i -t $FILE_NAME "*** MEMORY_TWEAKS ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
MEMORY_TWEAKS;

# ==============================================================
# ENTROPY-TWEAKS
# ==============================================================

ENTROPY()
{
	local state="$1";
	USED_PROFILE=`cat $DATA_DIR/.active.profile`;

	if [ "$state" == "awake" ]; then
		if [ "$USED_PROFILE" != "battery" ] || [ "$USED_PROFILE" != "extreme_battery" ]; then
			echo "128" > /proc/sys/kernel/random/read_wakeup_threshold;
			echo "256" > /proc/sys/kernel/random/write_wakeup_threshold;
		else
			echo "64" > /proc/sys/kernel/random/read_wakeup_threshold;
			echo "128" > /proc/sys/kernel/random/write_wakeup_threshold;
		fi;
	elif [ "$state" == "sleep" ]; then
		echo "64" > /proc/sys/kernel/random/read_wakeup_threshold;
		echo "128" > /proc/sys/kernel/random/write_wakeup_threshold;
	fi;

	log -p i -t $FILE_NAME "*** ENTROPY ***: $state";
}

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
		echo "3" > /proc/sys/net/ipv4/tcp_keepalive_probes;
		echo "20" > /proc/sys/net/ipv4/tcp_keepalive_intvl;

		log -p i -t $FILE_NAME "*** TCP_TWEAKS ***: enabled";
	fi;

	if [ "$cortexbrain_tcp_ram" == on ]; then
		echo "1048576" > /proc/sys/net/core/wmem_max;
		echo "1048576" > /proc/sys/net/core/rmem_max;
		echo "262144" > /proc/sys/net/core/rmem_default;
		echo "262144" > /proc/sys/net/core/wmem_default;
		echo "20480" > /proc/sys/net/core/optmem_max;
		echo "262144 524288 1048576" > /proc/sys/net/ipv4/tcp_wmem;
		echo "262144 524288 1048576" > /proc/sys/net/ipv4/tcp_rmem;
		echo "4096" > /proc/sys/net/ipv4/udp_rmem_min;
		echo "4096" > /proc/sys/net/ipv4/udp_wmem_min;

		log -p i -t $FILE_NAME "*** TCP_RAM_TWEAKS ***: enabled";
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

		log -p i -t $FILE_NAME "*** FIREWALL_TWEAKS ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
FIREWALL_TWEAKS;

# ==============================================================
# UKSM-TWEAKS
# ==============================================================

UKSMCTL()
{
	local state="$1";
	local uksm_run_tmp="/sys/kernel/mm/uksm/run";
	if [ ! -e $uksm_run_tmp ]; then
		uksm_run_tmp="/dev/null";
	fi;

	if [ "$cortexbrain_uksm_control" == on ] && [ "$uksm_run_tmp" != "/dev/null" ]; then
		echo "1" > $uksm_run_tmp;
		renice -n 10 -p `pidof uksmd`;

		if [ "$state" == "awake" ]; then
			echo "500" > /sys/kernel/mm/uksm/sleep_millisecs; # max: 1000
			echo "medium" > /sys/kernel/mm/uksm/cpu_governor;

			log -p i -t $FILE_NAME "*** uksm: awake, sleep=0,5sec, max_cpu=50% ***";

		elif [ "$state" == "sleep" ]; then
			echo "1000" > /sys/kernel/mm/uksm/sleep_millisecs; # max: 1000
			echo "quiet" > /sys/kernel/mm/uksm/cpu_governor;

			log -p i -t $FILE_NAME "*** uksm: sleep, sleep=1sec, max_cpu=1% ***";
		fi;
	else
		echo "0" > $uksm_run_tmp;
	fi;
}

# ==============================================================
# GLOBAL-FUNCTIONS
# ==============================================================

WIFI_SET()
{
	local state="$1";
	
	if [ "$state" == "off" ]; then
		service call wifi 13 i32 0 > /dev/null;
		svc wifi disable;
		echo "1" > $WIFI_HELPER_AWAKE;
	elif [ "$state" == "on" ]; then
		service call wifi 13 i32 1 > /dev/null;
		svc wifi enable;
	fi;

	log -p i -t $FILE_NAME "*** WIFI ***: $state";
}

WIFI()
{
	local state="$1";

	if [ "$state" == "sleep" ]; then
		if [ "$cortexbrain_auto_tweak_wifi" == on ]; then
			if [ -e /sys/module/dhd/initstate ]; then
				if [ "$cortexbrain_auto_tweak_wifi_sleep_delay" -eq "0" ]; then
					WIFI_SET "off";
				else
					(
						echo "0" > $WIFI_HELPER_TMP;
						# screen time out but user want to keep it on and have wifi
						sleep 10;
						if [ `cat $WIFI_HELPER_TMP` -eq "0" ]; then
							# user did not turned screen on, so keep waiting
							SLEEP_TIME_WIFI=$(( $cortexbrain_auto_tweak_wifi_sleep_delay - 10 ));
							log -p i -t $FILE_NAME "*** DISABLE_WIFI $cortexbrain_auto_tweak_wifi_sleep_delay Sec Delay Mode ***";
							sleep $SLEEP_TIME_WIFI;
							if [ `cat $WIFI_HELPER_TMP` -eq "0" ]; then
								# user left the screen off, then disable wifi
								WIFI_SET "off";
							fi;
						fi;
					)&
				fi;
			else
				echo "0" > $WIFI_HELPER_AWAKE;
			fi;
		fi;
	elif [ "$state" == "awake" ]; then
		if [ "$cortexbrain_auto_tweak_wifi" == on ]; then
			echo "1" > $WIFI_HELPER_TMP;
			if [ `cat $WIFI_HELPER_AWAKE` -eq "1" ]; then
				WIFI_SET "on";
			fi;
		fi;
	fi;
}

MOBILE_DATA_SET()
{
	local state="$1";

	if [ "$state" == "off" ]; then
		svc data disable;
		echo "1" > $MOBILE_HELPER_AWAKE;
	elif [ "$state" == "on" ]; then
		svc data enable;
	fi;

	log -p i -t $FILE_NAME "*** MOBILE DATA ***: $state";
}

MOBILE_DATA_STATE()
{
	if [ $DUMPSYS_STATE -eq "1" ]; then
		local DATA_STATE=`echo "$TELE_DATA" | awk '/mDataConnectionState/ {print $1}'`;

		if [ "$DATA_STATE" != "mDataConnectionState=0" ]; then
			DATA_STATE_CHECK=1;
		else
			DATA_STATE_CHECK=0;
		fi;
	else
		DATA_STATE_CHECK=0;
	fi;
}

MOBILE_DATA()
{
	local state="$1";

	if [ "$cortexbrain_auto_tweak_mobile" == on ]; then
		if [ "$state" == "sleep" ]; then
			MOBILE_DATA_STATE;
			if [ "$DATA_STATE_CHECK" -eq "1" ]; then
				if [ "$cortexbrain_auto_tweak_mobile_sleep_delay" -eq "0" ]; then
					MOBILE_DATA_SET "off";
				else
					(
						echo "0" > $MOBILE_HELPER_TMP;
						# screen time out but user want to keep it on and have mobile data
						sleep 10;
						if [ `cat $MOBILE_HELPER_TMP` -eq "0" ]; then
							# user did not turned screen on, so keep waiting
							SLEEP_TIME_DATA=$(( $cortexbrain_auto_tweak_mobile_sleep_delay - 10 ));
							log -p i -t $FILE_NAME "*** DISABLE_MOBILE $cortexbrain_auto_tweak_mobile_sleep_delay Sec Delay Mode ***";
							sleep $SLEEP_TIME_DATA;
							if [ `cat $MOBILE_HELPER_TMP` -eq "0" ]; then
								# user left the screen off, then disable mobile data
								MOBILE_DATA_SET "off";
							fi;
						fi;
					)&
				fi;
			else
				echo "0" > $MOBILE_HELPER_AWAKE;
			fi;
		elif [ "$state" == "awake" ]; then
			echo "1" > $MOBILE_HELPER_TMP;
			if [ `cat $MOBILE_HELPER_AWAKE` -eq "1" ]; then
				MOBILE_DATA_SET "on";
			fi;
		fi;
	fi;
}

LOGGER()
{
	local state="$1";
	local dev_log_sleep="/dev/log-sleep";
	local dev_log="/dev/log";

	if [ "$state" == "awake" ]; then
		if [ "$android_logger" == auto ] || [ "$android_logger" == debug ]; then
			if [ -e $dev_log_sleep ] && [ ! -e $dev_log ]; then
				mv $dev_log_sleep $dev_log
			fi;
		fi;
	elif [ "$state" == "sleep" ]; then
		if [ "$android_logger" == auto ] || [ "$android_logger" == disabled ]; then
			if [ -e $dev_log ]; then
				mv $dev_log $dev_log_sleep;
			fi;
		fi;
	fi;

	log -p i -t $FILE_NAME "*** LOGGER ***: $state";
}

GESTURES()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		if [ "$gesture_tweak" == on ]; then
			pkill -f "/data/gesture_set.sh";
			pkill -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture";
			nohup /sbin/busybox sh /data/gesture_set.sh;
		fi;
	elif [ "$state" == "sleep" ]; then
		if [ `pgrep -f "/data/gesture_set.sh" | wc -l` != 0 ] || [ `pgrep -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture" | wc -l` != 0 ] || [ "$gesture_tweak" == off ]; then
			pkill -f "/data/gesture_set.sh";
			pkill -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture";
		fi;
	fi;

	log -p i -t $FILE_NAME "*** GESTURE ***: $state";
}

# mount sdcard and emmc, if usb mass storage is used
MOUNT_SD_CARD()
{
	if [ "$auto_mount_sd" == on ]; then
		echo "/dev/block/vold/259:3" > /sys/devices/virtual/android_usb/android0/f_mass_storage/lun0/file;
		if [ -e /dev/block/vold/179:9 ]; then
			echo "/dev/block/vold/179:9" > /sys/devices/virtual/android_usb/android0/f_mass_storage/lun1/file;
		fi;

		log -p i -t $FILE_NAME "*** MOUNT_SD_CARD ***";
	fi;
}

MALI_TIMEOUT()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		echo "$mali_gpu_utilization_timeout" > /sys/module/mali/parameters/mali_gpu_utilization_timeout;
	elif [ "$state" == "sleep" ]; then
		echo "1000" > /sys/module/mali/parameters/mali_gpu_utilization_timeout;
	elif [ "$state" == "wake_boost" ]; then
		echo "250" > /sys/module/mali/parameters/mali_gpu_utilization_timeout;
	fi;

	log -p i -t $FILE_NAME "*** MALI_TIMEOUT: $state ***";
}

BUS_THRESHOLD()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		echo "$busfreq_up_threshold" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;
	elif [ "$state" == "sleep" ]; then
		echo "30" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;
	elif [ "$state" == "wake_boost" ]; then
		echo "23" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;
	fi;

	log -p i -t $FILE_NAME "*** BUS_THRESHOLD: $state ***";
}

VFS_CACHE_PRESSURE()
{
	local state="$1";
	local sys_vfs_cache="/proc/sys/vm/vfs_cache_pressure";

	if [ -e $sys_vfs_cache ]; then
		if [ "$state" == "awake" ]; then
			echo "200" > $sys_vfs_cache;
		elif [ "$state" == "sleep" ]; then
			echo "100" > $sys_vfs_cache;
		fi;

		log -p i -t $FILE_NAME "*** VFS_CACHE_PRESSURE: $state ***";

		return 0;
	fi;

	return 1;
}

TWEAK_HOTPLUG_ECO()
{
	local state="$1";
	local sys_eco="/sys/module/intelli_plug/parameters/eco_mode_active";

	if [ -e $sys_eco ]; then
		if [ "$state" == "awake" ]; then
			echo "0" > $sys_eco;
		elif [ "$state" == "sleep" ]; then
			echo "1" > $sys_eco;
		fi;

		log -p i -t $FILE_NAME "*** TWEAK_HOTPLUG_ECO: $state ***";

		return 0;
	fi;

	return 1;
}

# ==============================================================
# ECO-TWEAKS
# ==============================================================
ECO_TWEAKS()
{
	if [ "$cortexbrain_eco" == on ]; then
		local LEVEL=`cat /sys/class/power_supply/battery/capacity`;
		if [ "$LEVEL" -le "$cortexbrain_eco_level" ]; then
			TWEAK_HOTPLUG_ECO "sleep";
			CPU_GOV_TWEAKS "sleep";

			log -p i -t $FILE_NAME "*** AWAKE: ECO-Mode ***";
		else
			CPU_GOV_TWEAKS "awake";

			log -p i -t $FILE_NAME "*** AWAKE: Normal-Mode ***";
		fi;

		log -p i -t $FILE_NAME "*** ECO_TWEAKS ***: enabled";
	else
		CPU_GOV_TWEAKS "awake";

		log -p i -t $FILE_NAME "*** ECO_TWEAKS ***: disabled";
		log -p i -t $FILE_NAME "*** AWAKE: Normal-Mode ***";
	fi;
}

CENTRAL_CPU_FREQ()
{
	local state="$1";

	if [ "$cortexbrain_cpu" == on ]; then
		if [ "$scaling_max_freq" -eq "1000000" ] && [ "$scaling_max_freq_oc" -gt "1000000" ]; then
			MAX_FREQ=`echo $scaling_max_freq_oc`;
		else
			MAX_FREQ=`echo $scaling_max_freq`;
		fi;

		if [ "$state" == "wake_boost" ]; then
			if [ "$MAX_FREQ" -gt "1000000" ]; then
				echo "$MAX_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
				echo "$MAX_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
				echo "$MAX_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			else
				echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
				echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
				echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			fi;
		elif [ "$state" == "awake_normal" ]; then
			echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$scaling_min_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_suspend_freq;
			echo "$MAX_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
		elif [ "$state" == "standby_freq" ]; then
			echo "$standby_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$standby_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_suspend_freq;
		elif [ "$state" == "sleep_freq" ]; then
			echo "$scaling_min_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$scaling_min_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_suspend_freq;
			echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
		elif [ "$state" == "sleep_call" ]; then
			echo "$standby_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$standby_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_suspend_freq;
			# brain cooking prevention during call
			echo "500000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			echo "500000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
		fi;

		log -p i -t $FILE_NAME "*** CENTRAL_CPU_FREQ: $state ***: done";
	else
		log -p i -t $FILE_NAME "*** CENTRAL_CPU_FREQ: NOT CHANGED ***: done";
	fi;
}

# boost CPU power for fast and no lag wakeup
MEGA_BOOST_CPU_TWEAKS()
{
	if [ "$cortexbrain_cpu" == on ]; then
		CPU_GOV_TWEAKS "wake_boost";
		CENTRAL_CPU_FREQ "wake_boost";

		log -p i -t $FILE_NAME "*** MEGA_BOOST_CPU_TWEAKS ***";
	else
		echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
	fi;
}

BOOST_DELAY()
{
	# check if ROM booting now, then don't wait - creation and deletion of $DATA_DIR/booting @> /sbin/ext/post-init.sh
	if [ "$wakeup_boost" != 0 ] && [ ! -e $DATA_DIR/booting ]; then
		log -p i -t $FILE_NAME "*** BOOST_DELAY: ${wakeup_boost}sec ***";
		sleep $wakeup_boost;
	fi;
}

# set swappiness in case that no root installed, and zram used or disk swap used
SWAPPINESS()
{
	local SWAP_CHECK=`free | grep Swap | awk '{ print $2 }'`;

	if [ "$SWAP_CHECK" -eq "0" ]; then
		echo "0" > /proc/sys/vm/swappiness;
	else
		echo "$swappiness" > /proc/sys/vm/swappiness;
	fi;

	log -p i -t $FILE_NAME "*** SWAPPINESS: $swappiness ***";
}
SWAPPINESS;

# disable/enable ipv6  
IPV6()
{
	local state='';

	if [ -e /data/data/com.cisco.anyconnec* ]; then
		local CISCO_VPN=1;
	else
		local CISCO_VPN=0;
	fi;

	if [ "$cortexbrain_ipv6" == on ] || [ "$CISCO_VPN" -eq "1" ]; then
		echo "0" > /proc/sys/net/ipv6/conf/wlan0/disable_ipv6;
		sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null;
		local state="enabled";
	else
		echo "1" > /proc/sys/net/ipv6/conf/wlan0/disable_ipv6;
		sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null;
		local state="disabled";
	fi;

	log -p i -t $FILE_NAME "*** IPV6 ***: $state";
}

NET()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		echo "3" > /proc/sys/net/ipv4/tcp_keepalive_probes; # default: 3
		echo "1200" > /proc/sys/net/ipv4/tcp_keepalive_time; # default: 7200s
		echo "10" > /proc/sys/net/ipv4/tcp_keepalive_intvl; # default: 75s
		echo "10" > /proc/sys/net/ipv4/tcp_retries2; # default: 15
	elif [ "$state" == "sleep" ]; then
		echo "2" > /proc/sys/net/ipv4/tcp_keepalive_probes;
		echo "300" > /proc/sys/net/ipv4/tcp_keepalive_time;
		echo "5" > /proc/sys/net/ipv4/tcp_keepalive_intvl;
		echo "5" > /proc/sys/net/ipv4/tcp_retries2;
	fi;

	log -p i -t $FILE_NAME "*** NET ***: $state";
}

#KERNEL_SCHED()
#{
#	local state="$1";
#
#	# this is the correct order to input this settings, every value will be x2 after set
#	if [ "$state" == "awake" ]; then
#		sysctl -w kernel.sched_wakeup_granularity_ns=1000000 > /dev/null 2>&1;
#		sysctl -w kernel.sched_min_granularity_ns=750000 > /dev/null 2>&1;
#		sysctl -w kernel.sched_latency_ns=6000000 > /dev/null 2>&1;
#	elif [ "$state" == "sleep" ]; then
#		sysctl -w kernel.sched_wakeup_granularity_ns=1000000 > /dev/null 2>&1;
#		sysctl -w kernel.sched_min_granularity_ns=750000 > /dev/null 2>&1;
#		sysctl -w kernel.sched_latency_ns=6000000 > /dev/null 2>&1;
#	fi;
#
#	log -p i -t $FILE_NAME "*** KERNEL_SCHED ***: $state";
#}

BLN_CORRECTION()
{
	if [ "$notification_enabled" == on ]; then
		echo "1" > /sys/class/misc/notification/notification_enabled;

		if [ "$blnww" == off ]; then
			if [ "$bln_switch" -eq "0" ]; then
				/res/uci.sh bln_switch 0;
			elif [ "$bln_switch" -eq "1" ]; then
				/res/uci.sh bln_switch 1;
			elif [ "$bln_switch" -eq "2" ]; then
				/res/uci.sh bln_switch 2;
			fi;
		else
			/res/uci.sh bln_switch 0 > /dev/null;
			/res/uci.sh generic /sys/class/misc/notification/notification_timeout 0 > /dev/null;
		fi;

		if [ "$dyn_brightness" == on ]; then
			echo "0" > /sys/class/misc/notification/dyn_brightness;
		fi;

		log -p i -t $FILE_NAME "*** BLN_CORRECTION ***";

		return 1;
	else
		return 0;
	fi;
}

TOUCH_KEYS_CORRECTION()
{
	if [ "$dyn_brightness" == on ]; then
		echo "1" > /sys/class/misc/notification/dyn_brightness;
	fi;

	if [ "$led_timeout_ms" -eq "0" ]; then
		echo "0" > /sys/class/misc/notification/led_timeout_ms;
	else
		/res/uci.sh generic /sys/class/misc/notification/led_timeout_ms $led_timeout_ms > /dev/null;
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

		return 1;
	else
		return 0;
	fi;
}

GAMMA_FIX()
{
	local min_gamm_tmp="/sys/class/misc/brightness_curve/min_gamma";
	if [ -e $min_gamm_tmp ]; then
		min_gamm_tmp="/dev/null";
	fi;

	local max_gamma_tmp="/sys/class/misc/brightness_curve/max_gamma";
	if [ -e $max_gamma_tmp ]; then
		max_gamma_tmp="/dev/null";
	fi;

	echo "$min_gamma" > $min_gamm_tmp;
	echo "$max_gamma" > $max_gamma_tmp;

	log -p i -t $FILE_NAME "*** GAMMA_FIX: min: $min_gamma max: $max_gamma ***: done";
}

ENABLEMASK()
{
	local state="$1";
	local enable_mask_tmp="/sys/module/cpuidle_exynos4/parameters/enable_mask";
	if [ -e $enable_mask_tmp ]; then
		enable_mask_tmp="/dev/null";
	fi;

	local tmp_enable_mask=`cat $enable_mask_tmp`;

	if [ "$state" == "awake" ]; then
		if [ "$tmp_enable_mask" != "$enable_mask" ]; then
			echo "$enable_mask" > $enable_mask_tmp;
		fi;
	elif [ "$state" == "sleep" ]; then
		if [ "$tmp_enable_mask" != "$enable_mask_sleep" ]; then
			echo "$enable_mask_sleep" > $enable_mask_tmp;
		fi;
	fi;

	log -p i -t $FILE_NAME "*** ENABLEMASK: $state ***: done";
}

IO_SCHEDULER()
{
	local state="$1";
	local sys_mmc0_scheduler_tmp="/sys/block/mmcblk0/queue/scheduler";
	if [ -e $sys_mmc0_scheduler_tmp ]; then
		sys_mmc0_scheduler_tmp="/dev/null";
	fi;

	local sys_mmc1_scheduler_tmp="/sys/block/mmcblk1/queue/scheduler";
	if [ -e $sys_mmc1_scheduler_tmp ]; then
		sys_mmc1_scheduler_tmp="/dev/null";
	fi;

	local tmp_scheduler=`cat $sys_mmc0_scheduler_tmp`;

	if [ "$state" == "awake" ]; then
		if [ "$tmp_scheduler" != "$scheduler" ]; then
			echo "$scheduler" > $sys_mmc0_scheduler_tmp;
			echo "$scheduler" > $sys_mmc1_scheduler_tmp;
		fi;
	elif [ "$state" == "sleep" ]; then
		if [ "$tmp_scheduler" != "$sleep_scheduler" ]; then
			echo "$sleep_scheduler" > $sys_mmc0_scheduler_tmp;
			echo "$sleep_scheduler" > $sys_mmc1_scheduler_tmp;
		fi;
	fi;

	log -p i -t $FILE_NAME "*** IO_SCHEDULER: $state ***: done";
}

CPU_GOVERNOR()
{
	local state="$1";
	local scaling_governor_tmp="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor";
	local tmp_governor=`cat $scaling_governor_tmp`;

	if [ "$cortexbrain_cpu" == on ]; then
		if [ "$state" == "awake" ]; then
			if [ "$tmp_governor" != $scaling_governor ]; then
				echo "$scaling_governor" > $scaling_governor_tmp;
			fi;
		elif [ "$state" == "sleep" ]; then
			if [ "$tmp_governor" != $scaling_governor_sleep ]; then
				echo "$scaling_governor_sleep" > $scaling_governor_tmp;
			fi;
		fi;

		log -p i -t $FILE_NAME "*** CPU_GOVERNOR: $state ***: done";
	else
		log -p i -t $FILE_NAME "*** CPU_GOVERNOR: NO CHANGED ***: done";
	fi;
}

SLIDE2WAKE_FIX()
{
	local state="$1";

	local tsp_slide2wake_call_tmp="/sys/devices/virtual/sec/sec_touchscreen/tsp_slide2wake_call";
	if [ -e $tsp_slide2wake_call_tmp ]; then
		local SLIDE_STATE=`cat $tsp_slide2wake_call_tmp`;
	fi;

	if [ "$tsp_slide2wake" == on ]; then
		if [ "$state" == "offline" ] && [ "$SLIDE_STATE" -eq "1" ]; then
			echo "0" > $tsp_slide2wake_call_tmp;
			log -p i -t $FILE_NAME "*** SLIDE2WAKE_FIX: $state ***: done";
		elif [ "$state" == "oncall" ]; then
			echo "1" > $tsp_slide2wake_call_tmp;
			log -p i -t $FILE_NAME "*** SLIDE2WAKE_FIX: $state ***: done";
		fi;
	fi;
}

CALL_STATE()
{
	if [ "$DUMPSYS_STATE" -eq "1" ]; then

		# check the call state, not on call = 0, on call = 2
		local state_tmp=`echo "$TELE_DATA" | awk '/mCallState/ {print $1}'`;

		if [ "$state_tmp" != "mCallState=0" ]; then
			NOW_CALL_STATE=1;
		else
			NOW_CALL_STATE=0;
		fi;

		log -p i -t $FILE_NAME "*** CALL_STATE: $NOW_CALL_STATE ***";
	else
		NOW_CALL_STATE=0;
	fi;
}

VIBRATE_FIX()
{
	echo "$vibrator_level" > /sys/vibrator/vibrator_level;

	if [ "$vibrator_level" -eq "9" ]; then
		echo "100" > /sys/vibrator/pwm_val;
	elif [ "$vibrator_level" -eq "7" ]; then
		echo "75" > /sys/vibrator/pwm_val;
	elif [ "$vibrator_level" -eq "5" ]; then
		echo "50" > /sys/vibrator/pwm_val;
	elif [ "$vibrator_level" -eq "3" ]; then
		echo "25" > /sys/vibrator/pwm_val;
	elif [ "$vibrator_level" -eq "-1" ]; then
		echo "0" > /sys/vibrator/pwm_val;
	fi;

	log -p i -t $FILE_NAME "*** VIBRATE_FIX: done ***";
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	# Do not touch this
	CALL_STATE;
	VIBRATE_FIX;
	SLIDE2WAKE_FIX "offline";
	MOUNT_SD_CARD;
	TOUCH_KEYS_CORRECTION;
	GAMMA_FIX;

	# Check call state, if on call dont sleep
	if [ "$NOW_CALL_STATE" -eq "1" ]; then
		CENTRAL_CPU_FREQ "awake_normal";
		NOW_CALL_STATE=0;
	else
		# not on call, check if was powerd by USB on sleep, or didnt sleep at all
		if [ "$WAS_IN_SLEEP_MODE" -eq "1" ] && [ "$USB_POWER" -eq "0" ]; then
			ENABLEMASK "awake";
			CPU_GOVERNOR "awake";
			LOGGER "awake";
			UKSMCTL "awake";
			MALI_TIMEOUT "wake_boost";
			BUS_THRESHOLD "wake_boost";
#			KERNEL_SCHED "awake";
			KERNEL_TWEAKS "awake";
			NET "awake";
			MOBILE_DATA "awake";
			WIFI "awake";
			MEGA_BOOST_CPU_TWEAKS;
			IO_SCHEDULER "awake";
			GESTURES "awake";
			BOOST_DELAY;
			ENTROPY "awake";
			VFS_CACHE_PRESSURE "awake";
			TWEAK_HOTPLUG_ECO "awake";
			CENTRAL_CPU_FREQ "awake_normal";
			MALI_TIMEOUT "awake";
			BUS_THRESHOLD "awake";
			ECO_TWEAKS;
		else
			# Was powered by USB, and half sleep
			ENABLEMASK "awake";
			MEGA_BOOST_CPU_TWEAKS;
			MALI_TIMEOUT "wake_boost";
			GESTURES "awake";
			BOOST_DELAY;
			BATTERY_TWEAKS;
			MALI_TIMEOUT "awake";
			CENTRAL_CPU_FREQ "awake_normal";
			ECO_TWEAKS;
			USB_POWER=0;

			log -p i -t $FILE_NAME "*** USB_POWER_WAKE: done ***";
		fi;
		#Didn't sleep, and was not powered by USB
	fi;
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	WAS_IN_SLEEP_MODE=0;

	# we only read the config when the screen turns off ...
	PROFILE=`cat $DATA_DIR/.active.profile`;
	. $DATA_DIR/${PROFILE}.profile;

	# we only read tele-data when the screen turns off ...
	if [ "$DUMPSYS_STATE" -eq "1" ]; then
		TELE_DATA=`dumpsys telephony.registry`;
	fi;

	# Check call state
	CALL_STATE;

	# Check Early Wakeup
	local TMP_EARLY_WAKEUP=`cat /tmp/early_wakeup`;

	# check if early_wakeup, or we on call
	if [ "$TMP_EARLY_WAKEUP" -eq "0" ] && [ "$NOW_CALL_STATE" -eq "0" ]; then
		WAS_IN_SLEEP_MODE=1;
		ENABLEMASK "sleep";
		CENTRAL_CPU_FREQ "standby_freq";
		MALI_TIMEOUT "sleep";
		GESTURES "sleep";
		BATTERY_TWEAKS;
		BLN_CORRECTION;
		CROND_SAFETY;
		SWAPPINESS;

		# check if we powered by USB, if not sleep
		CHARGING=`cat /sys/class/power_supply/battery/charging_source`;
		if [ "$CHARGING" -eq "0" ]; then
			CPU_GOVERNOR "sleep";
			CENTRAL_CPU_FREQ "sleep_freq";
			CPU_GOV_TWEAKS "sleep";
			IO_SCHEDULER "sleep";
			BUS_THRESHOLD "sleep";
#			KERNEL_SCHED "sleep";
			UKSMCTL "sleep";
			ENTROPY "sleep";
			NET "sleep";
			WIFI "sleep";
			MOBILE_DATA "sleep";
			IPV6;
			TWEAK_HOTPLUG_ECO "sleep";
			VFS_CACHE_PRESSURE "sleep";
			KERNEL_TWEAKS "sleep";

			log -p i -t $FILE_NAME "*** SLEEP mode ***";

			LOGGER "sleep";
		else
			# Powered by USB
			USB_POWER=1;
			log -p i -t $FILE_NAME "*** SLEEP mode: USB CABLE CONNECTED! No real sleep mode! ***";
		fi;
	else
		# Check if on call
		if [ "$NOW_CALL_STATE" -eq "1" ]; then
			CENTRAL_CPU_FREQ "sleep_call";
			SLIDE2WAKE_FIX "oncall";
			NOW_CALL_STATE=1;

			log -p i -t $FILE_NAME "*** on call: SLEEP aborted! ***";
		else
			# Early Wakeup detected
			log -p i -t $FILE_NAME "*** early wake up: SLEEP aborted! ***";
		fi;
	fi;

	# kill wait_for_fb_wake generated by /sbin/ext/wakecheck.sh
	pkill -f "cat /sys/power/wait_for_fb_wake"
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" -eq "1" ] && [ `pgrep -f "cat /sys/power/wait_for_fb_sleep" | wc -l` -eq "0" ] && [ `pgrep -f "cat /sys/power/wait_for_fb_wake" | wc -l` -eq "0" ]; then
	(while [ 1 ]; do
		# AWAKE State. all system ON
		cat /sys/power/wait_for_fb_wake > /dev/null 2>&1;
		AWAKE_MODE;
		sleep 2;

		# SLEEP state. All system to power save
		cat /sys/power/wait_for_fb_sleep > /dev/null 2>&1;
		sleep 2;
		/sbin/ext/wakecheck.sh;
		SLEEP_MODE;
	done &);
else
	if [ "$cortexbrain_background_process" -eq "0" ]; then
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
