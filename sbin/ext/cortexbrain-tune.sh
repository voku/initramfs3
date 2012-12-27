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

# set not yet known values for functions
power_performance=0;
sleep_power_save=0;

FILE_NAME=$0;
PIDOFCORTEX=$$;

# wifi timer helpers
echo "WIFI_STATE_AWAKE=0" > /data/.siyah/wifi_helper;
echo "WIFI_STATE=0" > /data/.siyah/wifi_helper_awake;
chmod 777 /data/.siyah/wifi_helper /data/.siyah/wifi_helper_awake;

# default settings (1000 = 10 seconds)
dirty_expire_centisecs_default=1000;
dirty_writeback_centisecs_default=1000;

# battery settings
dirty_expire_centisecs_battery=0;
dirty_writeback_centisecs_battery=0;

# =========
# Renice - kernel thread responsible for managing the swap memory and logs
# =========
renice 15 -p `pgrep -f "kswapd0"`;
renice 15 -p `pgrep -f "logcat"`;

# replace kernel version info for repacked kernels
cat /proc/version | grep infra && (kmemhelper -t string -n linux_proc_banner -o 15 `cat /res/version`);

# ==============================================================
# I/O-TWEAKS 
# ==============================================================
IO_TWEAKS()
{
	if [ "$cortexbrain_io" == on ]; then
		MMC=`ls -d /sys/block/mmc*`;
		ZRM=`ls -d /sys/block/zram*`;

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

			if [ -e $z/queue/read_ahead_kb ]; then
				echo "512" >  $z/queue/read_ahead_kb;
			fi;

			if [ -e $z/queue/max_sectors_kb ]; then
				echo "512" >  $z/queue/max_sectors_kb; # default: 127
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

			if [ -e $i/queue/read_ahead_kb ]; then
				echo "2048" >  $i/queue/read_ahead_kb; # default: 128
			fi;

			if [ -e $i/queue/nr_requests ]; then
				echo "20" > $i/queue/nr_requests; # default: 128
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
			echo "2048" > /sys/devices/virtual/bdi/default/read_ahead_kb;
		fi;

		SDCARDREADAHEAD=`ls -d /sys/devices/virtual/bdi/179*`;
		for i in $SDCARDREADAHEAD; do
			echo "2048" > $i/read_ahead_kb;
		done;

		echo "45" > /proc/sys/fs/lease-break-time;
#		echo "524288" > /proc/sys/fs/file-max;
#		echo "32000" > /proc/sys/fs/inotify/max_queued_events;
#		echo "256" > /proc/sys/fs/inotify/max_user_instances;
#		echo "10240" > /proc/sys/fs/inotify/max_user_watches;

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
		echo "1" > /proc/sys/vm/oom_kill_allocating_task;
		sysctl -w vm.panic_on_oom=0;
#		echo "65536" > /proc/sys/kernel/msgmax;
#		echo "2048" > /proc/sys/kernel/msgmni;
#		echo "128" > /proc/sys/kernel/random/read_wakeup_threshold;
#		echo "256" > /proc/sys/kernel/random/write_wakeup_threshold;
#		echo "500 512000 64 2048" > /proc/sys/kernel/sem;
#		echo "2097152" > /proc/sys/kernel/shmall;
#		echo "268435456" > /proc/sys/kernel/shmmax;
#		echo "524288" > /proc/sys/kernel/threads-max;
	
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
		setprop windowsmgr.max_events_per_sec 150;
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
		LEVEL=`cat /sys/class/power_supply/battery/capacity`;
		CURR_ADC=`cat /sys/class/power_supply/battery/batt_current_adc`;
		BATTFULL=`cat /sys/class/power_supply/battery/batt_full_check`;
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
		for i in `ls /sys/bus/usb/devices/*/power/level`; do
			chmod 777 $i;
			echo "auto" > $i;
		done;
		for i in `ls /sys/bus/usb/devices/*/power/autosuspend`; do
			chmod 777 $i;
			echo "1" > $i;
		done;

		# BUS power support
		buslist="spi i2c sdio";
		for bus in $buslist; do
			for i in `ls /sys/bus/$bus/devices/*/power/control`; do
				chmod 777 $i;
				echo "auto" > $i;
			done;
		done;

		log -p i -t $FILE_NAME "*** BATTERY_TWEAKS ***: enabled";
	fi;
}

# ==============================================================
# CPU-TWEAKS
# ==============================================================

CPU_GOV_TWEAKS()
{
	if [ "$cortexbrain_cpu" == on ]; then
		SYSTEM_GOVERNOR=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`;
		
		sampling_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/sampling_rate";
		if [ ! -e $sampling_rate_tmp ]; then
			sampling_rate_tmp="/dev/null";
		fi;
		cpu_up_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/cpu_up_rate";
		if [ ! -e $cpu_up_rate_tmp ]; then
			cpu_up_rate_tmp="/dev/null";
		fi;
		cpu_down_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/cpu_down_rate";
		if [ ! -e $cpu_down_rate_tmp ]; then
			cpu_down_rate_tmp="/dev/null";
		fi;
		up_threshold_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold";
		if [ ! -e $up_threshold_tmp ]; then
			up_threshold_tmp="/dev/null";
		fi;
		up_threshold_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold_min_freq";
		if [ ! -e $up_threshold_min_freq_tmp ]; then
			up_threshold_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold_at_min_freq";
		fi;
		if [ ! -e $up_threshold_min_freq_tmp ]; then
			up_threshold_min_freq_tmp="/dev/null";
		fi;
		inc_cpu_load_at_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/inc_cpu_load_at_min_freq";
		if [ ! -e $inc_cpu_load_at_min_freq_tmp ]; then
			inc_cpu_load_at_min_freq_tmp="/dev/null";
		fi;
		down_threshold_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/down_threshold";
		if [ ! -e $down_threshold_tmp ]; then
			down_threshold_tmp="/dev/null";
		fi;
		sampling_down_factor_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/sampling_down_factor";
		if [ ! -e $sampling_down_factor_tmp ]; then
			sampling_down_factor_tmp="/dev/null";
		fi;
		sampling_up_factor_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/sampling_up_factor";
		if [ ! -e $sampling_up_factor_tmp ]; then
			sampling_up_factor_tmp="/dev/null";
		fi;
		down_differential_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/down_differential";
		if [ ! -e $down_differential_tmp ]; then
			down_differential_tmp="/dev/null";
		fi;
		freq_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step";
		if [ ! -e $freq_step_tmp ]; then
			freq_step_tmp="/dev/null";
		fi;
		freq_step_dec_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step_dec";
		if [ ! -e $freq_step_dec_tmp ]; then
			freq_step_dec_tmp="/dev/null";
		fi;
		freq_responsiveness_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_responsiveness";
		if [ ! -e $freq_responsiveness_tmp ]; then
			freq_responsiveness_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_for_responsiveness";
		fi;
		if [ ! -e $freq_responsiveness_tmp ]; then
			freq_responsiveness_tmp="/dev/null";
		fi;		
		inc_cpu_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/inc_cpu_load";
		if [ ! -e $inc_cpu_load_tmp ]; then
			inc_cpu_load_tmp="/dev/null";
		fi;
		dec_cpu_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/dec_cpu_load";
		if [ ! -e $dec_cpu_load_tmp ]; then
			dec_cpu_load_tmp="/dev/null";
		fi;
		up_sample_time_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_sample_time";
		if [ ! -e $up_sample_time_tmp ]; then
			up_sample_time_tmp="/dev/null";
		fi;
		down_sample_time_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/down_sample_time";
		if [ ! -e $down_sample_time_tmp ]; then
			down_sample_time_tmp="/dev/null";
		fi;
		hispeed_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hispeed_freq";
		if [ ! -e $hispeed_freq_tmp ]; then
			hispeed_freq_tmp="/dev/null";
		fi;
		hotplug_sampling_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_sampling_rate";
		if [ ! -e $hotplug_sampling_rate_tmp ]; then
			hotplug_sampling_rate_tmp="/dev/null";
		fi;
		hotplug_freq_1_1_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_freq_1_1";
		if [ ! -e $hotplug_freq_1_1_tmp ]; then
			hotplug_freq_1_1_tmp="/dev/null";
		fi;
		hotplug_freq_2_0_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_freq_2_0";
		if [ ! -e $hotplug_freq_2_0_tmp ]; then
			hotplug_freq_2_0_tmp="/dev/null";
		fi;
		hotplug_rq_1_1_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_rq_1_1";
		if [ ! -e $hotplug_rq_1_1_tmp ]; then
			hotplug_rq_1_1_tmp="/dev/null";
		fi;
		hotplug_rq_2_0_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_rq_2_0";
		if [ ! -e $hotplug_rq_2_0_tmp ]; then
			hotplug_rq_2_0_tmp="/dev/null";
		fi;
		hotplug_compare_level_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_compare_level";
		if [ ! -e $hotplug_compare_level_tmp ]; then
			hotplug_compare_level_tmp="/dev/null";
		fi;
		freq_up_brake_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_up_brake";
		if [ ! -e $freq_up_brake_tmp ]; then
			freq_up_brake_tmp="/dev/null";
		fi;
		pump_up_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_up_step";
		if [ ! -e $pump_up_step_tmp ]; then
			pump_up_step_tmp="/dev/null";
		fi;
		pump_down_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_down_step";
		if [ ! -e $pump_down_step_tmp ]; then
			pump_down_step_tmp="/dev/null";
		fi;
		screen_off_min_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/screen_off_min_step";
		if [ ! -e $screen_off_min_step_tmp ]; then
			screen_off_min_step_tmp="/dev/null";
		fi;		
		max_cpu_lock_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/max_cpu_lock";
		if [ ! -e $max_cpu_lock_tmp ]; then
			max_cpu_lock_tmp="/dev/null";
		fi;
		dvfs_debug_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/dvfs_debug";
		if [ ! -e $dvfs_debug_tmp ]; then
			dvfs_debug_tmp="/dev/null";
		fi;
		hotplug_lock_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/hotplug_lock";
		if [ ! -e $hotplug_lock_tmp ]; then	
			hotplug_lock_tmp="/dev/null";
		fi;
		up_avg_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_avg_load";
		if [ ! -e $up_avg_load_tmp ]; then	
			up_avg_load_tmp="/dev/null";
		fi;
		down_avg_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/down_avg_load";
		if [ ! -e $down_avg_load_tmp ]; then	
			down_avg_load_tmp="/dev/null";
		fi;

		# power_performance
		if [ "$power_performance" == 1 ]; then

			echo "20000" > $sampling_rate_tmp;
			echo "10" > $cpu_up_rate_tmp;
			echo "10" > $cpu_down_rate_tmp;
			echo "10" > $down_threshold_tmp;
			echo "40" > $up_threshold_tmp;
			echo "20" > $up_threshold_min_freq_tmp;
			echo "100" > $freq_step_tmp;
			echo "800000" > $freq_responsiveness_tmp;

		# sleep-settings
		elif [ "$sleep_power_save" == 1 ]; then

			echo "$sampling_rate_sleep" > $sampling_rate_tmp;
			echo "$cpu_up_rate_sleep" > $cpu_up_rate_tmp;
			echo "$cpu_down_rate_sleep" > $cpu_down_rate_tmp;
			echo "$up_threshold_sleep" > $up_threshold_tmp;
			echo "$up_threshold_at_min_freq_sleep" > $up_threshold_min_freq_tmp;
			echo "$inc_cpu_load_at_min_freq_sleep" > $inc_cpu_load_at_min_freq_tmp;
			echo "$down_threshold_sleep" > $down_threshold_tmp;
			echo "$sampling_down_factor_sleep" > $sampling_down_factor_tmp;
			echo "$sampling_up_factor_sleep" > $sampling_up_factor_tmp;
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
			echo "$hotplug_compare_level_sleep" > $hotplug_compare_level_tmp;
			echo "$freq_up_brake_sleep" > $freq_up_brake_tmp;
			echo "$pump_up_step_sleep" > $pump_up_step_tmp;
			echo "$pump_down_step_sleep" > $pump_down_step_tmp;
			echo "$up_avg_load_sleep" > $up_avg_load_tmp;
			echo "$down_avg_load_sleep" > $down_avg_load_tmp;			
			echo "$max_cpu_lock" > $max_cpu_lock_tmp;
			echo "0" > $dvfs_debug_tmp;
			echo "0" > $hotplug_lock_tmp;						

		# awake-settings
		else

			echo "$sampling_rate" > $sampling_rate_tmp;
			echo "$cpu_up_rate" > $cpu_up_rate_tmp;
			echo "$cpu_down_rate" > $cpu_down_rate_tmp;
			echo "$up_threshold" > $up_threshold_tmp;
			echo "$up_threshold_at_min_freq" > $up_threshold_min_freq_tmp;
			echo "$inc_cpu_load_at_min_freq" > $inc_cpu_load_at_min_freq_tmp;
			echo "$down_threshold" > $down_threshold_tmp;
			echo "$sampling_down_factor" > $sampling_down_factor_tmp;
			echo "$sampling_up_factor" > $sampling_up_factor_tmp;
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
			echo "$hotplug_compare_level" > $hotplug_compare_level_tmp;
			echo "$freq_up_brake" > $freq_up_brake_tmp;
			echo "$pump_up_step" > $pump_up_step_tmp;
			echo "$pump_down_step" > $pump_down_step_tmp;
			echo "$up_avg_load" > $up_avg_load_tmp;
			echo "$down_avg_load" > $down_avg_load_tmp;
			echo "$screen_off_min_step" > $screen_off_min_step_tmp;
			echo "$max_cpu_lock" > $max_cpu_lock_tmp;
			echo "0" > $dvfs_debug_tmp;
			echo "0" > $hotplug_lock_tmp;

		fi;

		# reset
		power_performance=0;
		sleep_power_save=0;

		log -p i -t $FILE_NAME "*** CPU_GOV_TWEAKS ***: enabled";
	fi;
}

# ==============================================================
# MEMORY-TWEAKS
# ==============================================================
MEMORY_TWEAKS()
{
	if [ "$cortexbrain_memory" == on ]; then
		echo "$dirty_expire_centisecs_default" > /proc/sys/vm/dirty_expire_centisecs;
		echo "$dirty_writeback_centisecs_default" > /proc/sys/vm/dirty_writeback_centisecs;
		echo "20" > /proc/sys/vm/dirty_background_ratio; # default: 10
		echo "20" > /proc/sys/vm/dirty_ratio; # default: 20
		echo "4" > /proc/sys/vm/min_free_order_shift; # default: 4
		echo "1" > /proc/sys/vm/overcommit_memory; # default: 0
		echo "50" > /proc/sys/vm/overcommit_ratio; # default: 50
		echo "128 128" > /proc/sys/vm/lowmem_reserve_ratio;
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
# SCREEN-FUNCTIONS
# ==============================================================

DISABLE_WIFI()
{
	if [ -e /sys/module/dhd/initstate ]; then
		if [ "$cortexbrain_auto_tweak_wifi" == on ]; then
			if [ "$cortexbrain_auto_tweak_wifi_sleep_delay" == 0 ]; then
				svc wifi disable;
				echo "WIFI_STATE=1" > /data/.siyah/wifi_helper_awake;
				log -p i -t $FILE_NAME "*** WIFI ***: disabled";
			else
				(
					echo "WIFI_STATE_AWAKE=0" > /data/.siyah/wifi_helper;
					# screen time out but user want to keep it on and have wifi
					sleep 10;
					if [ `cat /data/.siyah/wifi_helper` == "WIFI_STATE_AWAKE=0" ]; then
						# user did not turned screen on, so keep waiting
						SLEEP_TIME=$(($cortexbrain_auto_tweak_wifi_sleep_delay - 10));
						log -p i -t $FILE_NAME "*** DISABLE_WIFI $cortexbrain_auto_tweak_wifi_sleep_delay Sec Delay Mode ***";
						sleep $SLEEP_TIME;
						if [ `cat /data/.siyah/wifi_helper` == "WIFI_STATE_AWAKE=0" ]; then
							# user left the screen off, then disable wifi
							svc wifi disable;
							echo "WIFI_STATE=1" > /data/.siyah/wifi_helper_awake;
							log -p i -t $FILE_NAME "*** WIFI ***: disabled";
						fi;
					fi;
				)&
			fi;
		fi;
	else
		echo "WIFI_STATE=0" > /data/.siyah/wifi_helper_awake;
	fi;
}

ENABLE_WIFI()
{
	echo "WIFI_STATE_AWAKE=1" > /data/.siyah/wifi_helper;
	if [ `cat /data/.siyah/wifi_helper_awake` == "WIFI_STATE=1" ]; then
		if [ "$cortexbrain_auto_tweak_wifi" == on ]; then
			svc wifi enable;
			log -p i -t $FILE_NAME "*** WIFI ***: enabled";
		fi;
	fi;
}

ENABLE_WIFI_PM()
{
	if [ "$wifi_pwr" == on ]; then
		if [ -e /sys/module/dhd/parameters/wifi_pm ]; then
			echo "1" > /sys/module/dhd/parameters/wifi_pm;
		fi;
		log -p i -t $FILE_NAME "*** WIFI_PM ***: enabled";
	fi;
}

DISABLE_WIFI_PM()
{
	if [ -e /sys/module/dhd/parameters/wifi_pm ]; then
		echo "0" > /sys/module/dhd/parameters/wifi_pm;
		log -p i -t $FILE_NAME "*** WIFI_PM ***: disabled";
	fi;
}

ENABLE_LOGGER()
{
	if [ "$android_logger" == auto ] || [ "$android_logger" == debug ]; then
		if [ -e /dev/log-sleep ] && [ ! -e /dev/log ]; then
			mv /dev/log-sleep/ /dev/log/
			log -p i -t $FILE_NAME "*** LOGGER ***: enabled";
		fi;
	fi;
}

DISABLE_LOGGER()
{
	if [ "$android_logger" == auto ] || [ "$android_logger" == disabled ]; then
		if [ -e /dev/log ]; then
			mv /dev/log/ /dev/log-sleep/;
			log -p i -t $FILE_NAME "*** LOGGER ***: disabled";
		fi;
	fi;
}

ENABLE_GESTURES()
{
	if [ "$gesture_tweak" == on ]; then
		echo "1" > /sys/devices/virtual/misc/touch_gestures/gestures_enabled;
		pkill -f "/data/gesture_set.sh";
		pkill -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture";
		nohup /sbin/busybox sh /data/gesture_set.sh;
		log -p i -t $FILE_NAME "*** GESTURE ***: enabled";
	fi;
}

DISABLE_GESTURES()
{
	if [ `pgrep -f "/data/gesture_set.sh" | wc -l` != "0" ] || [ `pgrep -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture" | wc -l` != "0" ] || [ "$gesture_tweak" == off ]; then
		pkill -f "/data/gesture_set.sh";
		pkill -f "/sys/devices/virtual/misc/touch_gestures/wait_for_gesture";
	fi;
	echo "0" > /sys/devices/virtual/misc/touch_gestures/gestures_enabled;
	log -p i -t $FILE_NAME "*** GESTURE ***: disabled";
}


# please don't kill "cortexbrain"
DONT_KILL_CORTEX()
{
	PIDOFCORTEX=`pgrep -f "/sbin/ext/cortexbrain-tune.sh"`;
	for i in $PIDOFCORTEX; do
		echo "-950" > /proc/${i}/oom_score_adj;
	done;
	log -p i -t $FILE_NAME "*** DONT_KILL_CORTEX ***";
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

# set wakeup booster delay to prevent mp3 music shattering when screen turned ON
WAKEUP_DELAY()
{
	if [ "$wakeup_delay" != 0 ] && [ ! -e /data/.siyah/booting ]; then
		log -p i -t $FILE_NAME "*** WAKEUP_DELAY ${wakeup_delay}sec ***";
		sleep $wakeup_delay
	fi;
}

WAKEUP_DELAY_SLEEP()
{
	if [ "$wakeup_delay" != 0 ] && [ ! -e /data/.siyah/booting ]; then
		log -p i -t $FILE_NAME "*** WAKEUP_DELAY_SLEEP ${wakeup_delay}sec ***";
		sleep $wakeup_delay;
	else
		log -p i -t $FILE_NAME "*** WAKEUP_DELAY_SLEEP 3sec ***";
		sleep 3;
	fi;
}

# check if ROM booting now, then don't wait - creation and deletion of /data/.siyah/booting @> /sbin/ext/post-init.sh
WAKEUP_BOOST_DELAY()
{
	if [ ! -e /data/.siyah/booting ] && [ "$wakeup_boost" != 0 ]; then
		log -p i -t $FILE_NAME "*** WAKEUP_BOOST_DELAY ${wakeup_boost}sec ***";
		sleep $wakeup_boost;
	fi;
}

# boost CPU power for fast and no lag wakeup
MEGA_BOOST_CPU_TWEAKS()
{
	if [ "$cortexbrain_cpu" == on ]; then

		echo "$scaling_governor" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;

		power_performance=1;
		CPU_GOV_TWEAKS;

		# bus freq to 400MHZ in low load
		echo "25" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;

		# GPU utilization to min delay
		echo "100" > /sys/module/mali/parameters/mali_gpu_utilization_timeout;

		# cpu-settings for second core online at booster time
		echo "20" > /sys/module/stand_hotplug/parameters/load_h0;
		echo "20" > /sys/module/stand_hotplug/parameters/load_l1;

		if [ "$scaling_max_freq" \> 1100000 ]; then
			echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
		else
			echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
		fi;
		echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;

		log -p i -t $FILE_NAME "*** MEGA_BOOST_CPU_TWEAKS ***";
	fi;
}

# set less brightnes is battery is low
AUTO_BRIGHTNESS()
{
	if [ "$cortexbrain_auto_tweak_brightness" == on ]; then
		LEVEL=`cat /sys/class/power_supply/battery/capacity`;
		MAX_BRIGHTNESS=`cat /sys/class/backlight/panel/max_brightness`;
		OLD_BRIGHTNESS=`cat /sys/class/backlight/panel/brightness`;
		NEW_BRIGHTNESS=`$(( MAX_BRIGHTNESS*LEVEL/100 ))`;
		if [ "$NEW_BRIGHTNESS" -le "$OLD_BRIGHTNESS" ]; then
			echo "$NEW_BRIGHTNESS" > /sys/class/backlight/panel/brightness;
		fi;
		log -p i -t $FILE_NAME "*** AUTO_BRIGHTNESS ***";
	fi;
}


# set swappiness in case that no root installed, and zram used or disk swap used
SWAPPINESS()
{
	SWAP_CHECK=`free | grep Swap | awk '{ print $2 }'`;
	if [ "$zramtweaks" == 4 ] || [ "$SWAP_CHECK" == 0 ]; then
		echo "0" > /proc/sys/vm/swappiness;
		log -p i -t $FILE_NAME "*** SWAPPINESS ***: disabled";
	else
		echo "80" > /proc/sys/vm/swappiness;
		log -p i -t $FILE_NAME "*** SWAPPINESS ***: enabled";
	fi;
}

TUNE_IPV6()
{
	CISCO_VPN=`find /data/data/com.cisco.anyconnec* | wc -l`;
	if [ "$cortexbrain_ipv6" == on ] || [ "$CISCO_VPN" != 0 ]; then
		echo "0" > /proc/sys/net/ipv6/conf/wlan0/disable_ipv6;
		sysctl -w net.ipv6.conf.all.disable_ipv6=0
		log -p i -t $FILE_NAME "*** TUNE_IPV6 ***: enabled";
	else
		echo "1" > /proc/sys/net/ipv6/conf/wlan0/disable_ipv6;
		sysctl -w net.ipv6.conf.all.disable_ipv6=1
		log -p i -t $FILE_NAME "*** TUNE_IPV6 ***: disabled";
	fi;
}

KERNEL_SCHED_AWAKE()
{
	echo "18000000" > /proc/sys/kernel/sched_latency_ns;
	echo "3000000" > /proc/sys/kernel/sched_wakeup_granularity_ns;
	echo "1500000" > /proc/sys/kernel/sched_min_granularity_ns;
	log -p i -t $FILE_NAME "*** KERNEL_SCHED ***: awake";
}

KERNEL_SCHED_SLEEP()
{
	echo "20000000" > /proc/sys/kernel/sched_latency_ns;
	echo "4000000" > /proc/sys/kernel/sched_wakeup_granularity_ns;
	echo "2000000" > /proc/sys/kernel/sched_min_granularity_ns;
	log -p i -t $FILE_NAME "*** KERNEL_SCHED ***: sleep";
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

	if [ "$led_timeout_ms" == -1 ]; then
		echo "-1" > /sys/class/misc/notification/led_timeout_ms;
	else
		/res/uci.sh led_timeout_ms $led_timeout_ms;
	fi;

	log -p i -t $FILE_NAME "*** TOUCH_KEYS_CORRECTION ***";
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

DISABLE_NMI()
{
	if [ -e /proc/sys/kernel/nmi_watchdog ]; then
		echo "0" > /proc/sys/kernel/nmi_watchdog;
		log -p i -t $FILE_NAME "*** NMI ***: disable";
	fi;
}

ENABLE_NMI()
{
	if [ -e /proc/sys/kernel/nmi_watchdog ]; then
		echo "1" > /proc/sys/kernel/nmi_watchdog;
		log -p i -t $FILE_NAME "*** NMI ***: enabled";
	fi;
}


# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	ENABLE_LOGGER;

	ENABLE_WIFI;

	KERNEL_SCHED_AWAKE;

	TOUCH_KEYS_CORRECTION;

	WAKEUP_DELAY;

	MEGA_BOOST_CPU_TWEAKS;

	MOUNT_SD_CARD;

	ENABLE_GESTURES;

	WAKEUP_BOOST_DELAY;

	# set default values
	echo "$dirty_expire_centisecs_default" > /proc/sys/vm/dirty_expire_centisecs;
	echo "$dirty_writeback_centisecs_default" > /proc/sys/vm/dirty_writeback_centisecs;

	# set I/O-Scheduler
	echo "$scheduler" > /sys/block/mmcblk0/queue/scheduler;
	echo "$scheduler" > /sys/block/mmcblk1/queue/scheduler;

	echo "20" > /proc/sys/vm/vfs_cache_pressure;

	DISABLE_WIFI_PM;

	TUNE_IPV6;

	CPU_GOV_TWEAKS;

	# bus freq back to normal
	echo "$busfreq_up_threshold" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;

	# cpu-settings for second core
	echo "$load_h0" > /sys/module/stand_hotplug/parameters/load_h0;
	echo "$load_l1" > /sys/module/stand_hotplug/parameters/load_l1;

	if [ "$cortexbrain_cpu" == on ]; then
		# set CPU speed
		echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
		echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
	fi;

	echo "$mali_gpu_utilization_timeout" > /sys/module/mali/parameters/mali_gpu_utilization_timeout;

	# set wifi.supplicant_scan_interval
	setprop wifi.supplicant_scan_interval $supplicant_scan_interval;

	# set the vibrator - force in case it's has been reseted
	echo "$pwm_val" > /sys/vibrator/pwm_val;

	ENABLE_NMI;

	AUTO_BRIGHTNESS;

	DONT_KILL_CORTEX;

	log -p i -t $FILE_NAME "*** AWAKE Normal Mode ***";
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	# we only read the config when screen goes off ...
	PROFILE=`cat /data/.siyah/.active.profile`;
	. /data/.siyah/$PROFILE.profile;

	WAKEUP_DELAY_SLEEP;

	if [ "$cortexbrain_cpu" == on ]; then
		echo "$standby_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
	fi;

	echo "500" > /sys/module/mali/parameters/mali_gpu_utilization_timeout;

	KERNEL_SCHED_SLEEP;

	DISABLE_GESTURES;

	TUNE_IPV6;

	BATTERY_TWEAKS;

	BLN_CORRECTION;

	CROND_SAFETY;

	SWAPPINESS;

	CHARGING=`cat /sys/class/power_supply/battery/charging_source`;
	if [ $CHARGING == 0 ]; then

		ENABLE_WIFI_PM;

		if [ "$cortexbrain_cpu" == on ]; then
			# set CPU-Governor
			echo "$deep_sleep" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;

			# reduce deepsleep CPU speed, SUSPEND mode
			echo "$scaling_min_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_suspend_freq;
			echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
			echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;

			# set CPU-Tweak
			sleep_power_save=1;
			CPU_GOV_TWEAKS;
		fi;

		# bus freq to min 133Mhz
		echo "90" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;

		# set disk I/O sched to noop simple and battery saving.
		echo "$sleep_scheduler" > /sys/block/mmcblk0/queue/scheduler;
		echo "$sleep_scheduler" > /sys/block/mmcblk1/queue/scheduler;

		# cpu-settings for second core
		echo "50" > /sys/module/stand_hotplug/parameters/load_h0;
		echo "50" > /sys/module/stand_hotplug/parameters/load_l1;

		# set wifi.supplicant_scan_interval
		if [ "$supplicant_scan_interval" \< 180 ]; then
			setprop wifi.supplicant_scan_interval 360;
		fi;

		# set settings for battery -> don't wake up "pdflush daemon"
		echo "$dirty_expire_centisecs_battery" > /proc/sys/vm/dirty_expire_centisecs;
		echo "$dirty_writeback_centisecs_battery" > /proc/sys/vm/dirty_writeback_centisecs;

		# set battery value
		echo "10" > /proc/sys/vm/vfs_cache_pressure; # default: 100
		
		# set the vibrator - 0
		echo "0" > /sys/vibrator/pwm_val;

		DISABLE_NMI;

		DISABLE_WIFI;

		log -p i -t $FILE_NAME "*** SLEEP mode ***";

		DISABLE_LOGGER;
	else
		echo "USB CABLE CONNECTED! No real sleep mode!"
		log -p i -t $FILE_NAME "*** SCREEN OFF BUT POWERED mode ***";
	fi;
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" == 1 ] && [ `pgrep -f "cat /sys/power/wait_for_fb_sleep" | wc -l` == 0 ] && [ `pgrep -f "cat /sys/power/wait_for_fb_wake" | wc -l` == 0 ]; then
	(while [ 1 ]; do
		# AWAKE State. all system ON.
		cat /sys/power/wait_for_fb_wake > /dev/null 2>&1;
		AWAKE_MODE;
		sleep 3;

		# SLEEP state. All system to power save.
		cat /sys/power/wait_for_fb_sleep > /dev/null 2>&1;
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
