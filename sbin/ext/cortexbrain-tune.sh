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

# init
FILE_NAME=$0;
PIDOFCORTEX=$$;
DATA_DIR="/data/.siyah";
TELE_DATA=`dumpsys telephony.registry`;
sleeprun=1;

wifi_helper_awake=1;
wifi_helper_tmp="$DATA_DIR/wifi_helper";
echo 1 > $wifi_helper_tmp;

mobile_helper_awake=1;
mobile_helper_tmp="$DATA_DIR/mobile_helper";
echo 1 > $mobile_helper_tmp;

chmod 777 -R /tmp/

# get values from profile
# 
# (since we don't have the recovery source code I can't change the ".siyah" dir, so just leave it there for history)
PROFILE=`cat ${DATA_DIR}/.active.profile`;
. ${DATA_DIR}/${PROFILE}.profile;

# set initial vm.dirty vales
echo "1000" > /proc/sys/vm/dirty_writeback_centisecs;
echo "3000" > /proc/sys/vm/dirty_expire_centisecs;

# check if dumpsys exist in ROM
if [ -e /system/bin/dumpsys ]; then
	DUMPSYS=1;
else
	DUMPSYS=0;
fi;

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

		echo "45" > /proc/sys/fs/lease-break-time;
		echo "289585" > /proc/sys/fs/file-max;
		echo "1048576" > /proc/sys/fs/nr_open;
		echo "16384" > /proc/sys/fs/inotify/max_queued_events;
		echo "128" > /proc/sys/fs/inotify/max_user_instances;
		echo "8192" > /proc/sys/fs/inotify/max_user_watches;

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
		echo "120" > /proc/sys/kernel/panic;
		echo "8192" > /proc/sys/kernel/msgmax;
		echo "5756" > /proc/sys/kernel/msgmni;
		echo "64" > /proc/sys/kernel/random/read_wakeup_threshold;
		echo "128" > /proc/sys/kernel/random/write_wakeup_threshold;
		echo "250 32000 32 128" > /proc/sys/kernel/sem;
		echo "2097152" > /proc/sys/kernel/shmall;
		echo "33554432" > /proc/sys/kernel/shmmax;
		echo "45832" > /proc/sys/kernel/threads-max;
	
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

		# LCD Power-Reduce
		if [ -e /sys/class/lcd/panel/power_reduce ]; then
			if [ "$power_reduce" == on ]; then
				echo "1" > /sys/class/lcd/panel/power_reduce;
			else
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
		local trans_latency_one_core_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/trans_latency_one_core";
		if [ ! -e $trans_latency_one_core_tmp ]; then
			trans_latency_one_core_tmp="/dev/null";
		fi;
		local trans_latency_two_cores_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/trans_latency_two_cores";
		if [ ! -e $trans_latency_two_cores_tmp ]; then
			trans_latency_two_cores_tmp="/dev/null";
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
			up_threshold_at_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold_min_freq";
			if [ ! -e $up_threshold_at_min_freq_tmp ]; then
				up_threshold_at_min_freq_tmp="/dev/null";
			fi;
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
		local freq_for_responsiveness_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_for_responsiveness";
		if [ ! -e $freq_for_responsiveness_tmp ]; then
			freq_for_responsiveness_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_responsiveness";
			if [ ! -e $freq_for_responsiveness_tmp ]; then
				freq_for_responsiveness_tmp="/dev/null";
			fi;
		fi;
		local freq_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step";
		if [ ! -e $freq_step_tmp ]; then
			freq_step_tmp="/dev/null";
		fi;
		local freq_step_dec_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step_dec";
		if [ ! -e $freq_step_dec_tmp ]; then
			freq_step_dec_tmp="/dev/null";
		fi;
		local freq_for_calc_incr_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_for_calc_incr";
		if [ ! -e $freq_for_calc_incr_tmp ]; then
			freq_for_calc_incr_tmp="/dev/null";
		fi;
		local freq_for_calc_decr_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_for_calc_decr";
		if [ ! -e $freq_for_calc_decr_tmp ]; then
			freq_for_calc_decr_tmp="/dev/null";
		fi;
		local inc_cpu_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/inc_cpu_load";
		if [ ! -e $inc_cpu_load_tmp ]; then
			inc_cpu_load_tmp="/dev/null";
		fi;
		local dec_cpu_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/dec_cpu_load";
		if [ ! -e $dec_cpu_load_tmp ]; then
			dec_cpu_load_tmp="/dev/null";
		fi;
		local freq_up_brake_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_up_brake";
		if [ ! -e $freq_up_brake_tmp ]; then
			freq_up_brake_tmp="/dev/null";
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
		local trans_load_l1_scroff_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/trans_load_l1_scroff";
		if [ ! -e $trans_load_l1_scroff_tmp ]; then
			trans_load_l1_scroff_tmp="/dev/null";
		fi;

		# performance-settings
		if [ "${state}" == "performance" ]; then
			echo "200000" > $freq_cpu1on_tmp;
			echo "200000" > $freq_cpu1off_tmp;
			echo "10" > $trans_load_h0_tmp;
			echo "10" > $trans_load_l1_tmp;
			echo "20000" > $sampling_rate_tmp;
			echo "10" > $cpu_up_rate_tmp;
			echo "10" > $cpu_down_rate_tmp;
			echo "10" > $down_threshold_tmp;
			echo "40" > $up_threshold_tmp;
			echo "40" > $up_threshold_at_min_freq_tmp;
			echo "100" > $freq_step_tmp;
			echo "800000" > $freq_for_responsiveness_tmp;
			echo "50000" > $sampling_rate_tmp;
			echo "40000" > $trans_latency_one_core_tmp;
			echo "40000" > $trans_latency_two_cores_tmp;
			echo "800000" > $freq_cpu1on_tmp;
			echo "400000" > $freq_cpu1off_tmp;
		# sleep-settings
		elif [ "${state}" == "sleep" ]; then
			echo "$sampling_rate_sleep" > $sampling_rate_tmp;
			echo "$trans_latency_one_core_sleep" > $trans_latency_one_core_tmp;
			echo "$trans_latency_two_cores_sleep" > $trans_latency_two_cores_tmp;
			echo "$cpu_up_rate_sleep" > $cpu_up_rate_tmp;
			echo "$cpu_down_rate_sleep" > $cpu_down_rate_tmp;
			echo "$up_threshold_sleep" > $up_threshold_tmp;
			echo "$up_threshold_at_min_freq_sleep" > $up_threshold_at_min_freq_tmp;
			echo "$inc_cpu_load_at_min_freq_sleep" > $inc_cpu_load_at_min_freq_tmp;
			echo "$down_threshold_sleep" > $down_threshold_tmp;
			echo "$sampling_up_factor_sleep" > $sampling_up_factor_tmp;
			echo "$sampling_down_factor_sleep" > $sampling_down_factor_tmp;
			echo "$down_differential_sleep" > $down_differential_tmp;
			echo "$freq_step_sleep" > $freq_step_tmp;
			echo "$freq_step_dec_sleep" > $freq_step_dec_tmp;
			echo "$freq_for_responsiveness_sleep" > $freq_for_responsiveness_tmp;
			echo "$freq_for_calc_incr_sleep" > $freq_for_calc_incr_tmp;
			echo "$freq_for_calc_decr_sleep" > $freq_for_calc_decr_tmp;
			echo "$inc_cpu_load_sleep" > $inc_cpu_load_tmp;
			echo "$dec_cpu_load_sleep" > $dec_cpu_load_tmp;
			echo "$freq_cpu1on_sleep" > $freq_cpu1on_tmp;
			echo "$freq_cpu1off_sleep" > $freq_cpu1off_tmp;
			echo "$freq_up_brake_sleep" > $freq_up_brake_tmp;
			echo "$trans_load_h0_scroff" > $trans_load_h0_scroff_tmp;
			echo "$trans_load_l1_scroff" > $trans_load_l1_scroff_tmp;
			echo "$trans_load_rq_sleep" > $trans_load_rq_tmp;
			echo "$trans_rq_sleep" > $trans_rq_tmp;
		# awake-settings
		elif [ "${state}" == "awake" ]; then
			echo "$sampling_rate" > $sampling_rate_tmp;
			echo "$trans_latency_one_core" > $trans_latency_one_core_tmp;
			echo "$trans_latency_two_cores" > $trans_latency_two_cores_tmp;
			echo "$cpu_up_rate" > $cpu_up_rate_tmp;
			echo "$cpu_down_rate" > $cpu_down_rate_tmp;
			echo "$up_threshold" > $up_threshold_tmp;
			echo "$up_threshold_at_min_freq" > $up_threshold_at_min_freq_tmp;
			echo "$inc_cpu_load_at_min_freq" > $inc_cpu_load_at_min_freq_tmp;
			echo "$down_threshold" > $down_threshold_tmp;
			echo "$sampling_up_factor" > $sampling_up_factor_tmp;
			echo "$sampling_down_factor" > $sampling_down_factor_tmp;
			echo "$down_differential" > $down_differential_tmp;
			echo "$freq_step" > $freq_step_tmp;
			echo "$freq_step_dec" > $freq_step_dec_tmp;
			echo "$freq_for_responsiveness" > $freq_for_responsiveness_tmp;
			echo "$freq_for_calc_incr" > $freq_for_calc_incr_tmp;
			echo "$freq_for_calc_decr" > $freq_for_calc_decr_tmp;
			echo "$inc_cpu_load" > $inc_cpu_load_tmp;
			echo "$dec_cpu_load" > $dec_cpu_load_tmp;
			echo "$freq_cpu1on" > $freq_cpu1on_tmp;
			echo "$freq_cpu1off" > $freq_cpu1off_tmp;
			echo "$freq_up_brake" > $freq_up_brake_tmp;
			echo "$trans_load_h0" > $trans_load_h0_tmp;
			echo "$trans_load_l1" > $trans_load_l1_tmp;
			echo "$trans_load_rq" > $trans_load_rq_tmp;
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
		echo "256 256" > /proc/sys/vm/lowmem_reserve_ratio;
		echo "3" > /proc/sys/vm/page-cluster; # default: 3
		echo "4096" > /proc/sys/vm/min_free_kbytes;

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
		echo "3" > /proc/sys/net/ipv4/tcp_keepalive_probes;
		echo "20" > /proc/sys/net/ipv4/tcp_keepalive_intvl;
		echo "1048576" > /proc/sys/net/core/wmem_max;
		echo "1048576" > /proc/sys/net/core/rmem_max;
		echo "262144" > /proc/sys/net/core/rmem_default;
		echo "262144" > /proc/sys/net/core/wmem_default;
		echo "20480" > /proc/sys/net/core/optmem_max;
		echo "262144 524288 1048576" > /proc/sys/net/ipv4/tcp_wmem;
		echo "262144 524288 1048576" > /proc/sys/net/ipv4/tcp_rmem;
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
if [ "$cortexbrain_ksm_control" == on ]; then
	KSM_NPAGES_BOOST=300;
	KSM_NPAGES_DECAY=50;

	KSM_NPAGES_MIN=32;
	KSM_NPAGES_MAX=1000;
	KSM_SLEEP_MSEC=200;
	KSM_SLEEP_MIN=2000;

	KSM_THRES_COEF=30;
	KSM_THRES_CONST=2048;

	KSM_NPAGES=0;
	KSM_TOTAL=`awk '/^MemTotal:/ {print $2}' /proc/meminfo`;
	KSM_THRES=$(( $KSM_TOTAL * $KSM_THRES_COEF / 100 ));

	if [ $KSM_THRES_CONST -gt $KSM_THRES ]; then
		KSM_THRES=$KSM_THRES_CONST;
	fi;

	KSM_TOTAL=$(( $KSM_TOTAL / 1024 ));
	KSM_SLEEP=$(( $KSM_SLEEP_MSEC * 16 * 1024 / $KSM_TOTAL ));

	if [ $KSM_SLEEP -le $KSM_SLEEP_MIN ]; then
		KSM_SLEEP=$KSM_SLEEP_MIN;
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
				renice -n 10 -p "`pidof ksmd`";
			;;
			esac
	}

	INCREASE_NPAGES()
	{
		local delta=${1:-0};

		KSM_NPAGES=$(( $KSM_NPAGES + $delta ));
		if [ $KSM_NPAGES -lt $KSM_NPAGES_MIN ]; then
			KSM_NPAGES=$KSM_NPAGES_MIN;
		elif [ $KSM_NPAGES -gt $KSM_NPAGES_MAX ]; then
			KSM_NPAGES=$KSM_NPAGES_MAX;
		fi;

		echo $KSM_NPAGES;
	}

	ADJUST_KSM()
	{
		local free=`awk '/^(MemFree|Buffers|Cached):/ {free += $2}; END {print free}' /proc/meminfo;`

		if [ $free -gt $KSM_THRES ]; then
			log -p i -t $FILE_NAME "*** ksm: $free > $KSM_THRES ***";
			npages=`INCREASE_NPAGES ${KSM_NPAGES_BOOST}`;
			KSMCTL "stop";
			return 1;
		else
			npages=`INCREASE_NPAGES $KSM_NPAGES_DECAY`;
			log -p i -t $FILE_NAME "*** ksm: $free < $KSM_THRES ***"
			KSMCTL "start" $KSM_NPAGES $KSM_SLEEP;
			return 0;
		fi;
	}
	ADJUST_KSM;
fi;

# ==============================================================
# SCREEN-FUNCTIONS
# ==============================================================

WIFI_PM()
{
	local state="$1";
	if [ "${state}" == "sleep" ]; then
		#if [ "$wifi_pwr" == on ]; then
		#	if [ -e /sys/module/dhd/parameters/wifi_pm ]; then
		#		echo "1" > /sys/module/dhd/parameters/wifi_pm;
		#	fi;
		#fi;

		if [ "$supplicant_scan_interval" -le 180 ]; then
			setprop wifi.supplicant_scan_interval 360;
		else
			setprop wifi.supplicant_scan_interval $supplicant_scan_interval;
		fi;
	elif [ "${state}" == "awake" ]; then
		#if [ -e /sys/module/dhd/parameters/wifi_pm ]; then
		#	echo "0" > /sys/module/dhd/parameters/wifi_pm;
		#fi;

		setprop wifi.supplicant_scan_interval $supplicant_scan_interval;
	fi;

	log -p i -t $FILE_NAME "*** WIFI_PM ***: ${state}";
}

WIFI_SET()
{
	local state="$1";
	
	if [ "${state}" == "off" ]; then
		service call wifi 13 i32 0 > /dev/null;
		# not declared as local - therefore, it's global
		wifi_helper_awake=1;
	elif [ "${state}" == "on" ]; then
		service call wifi 13 i32 1 > /dev/null;
		service call wifi 13 i32 1 > /dev/null;
		service call wifi 13 i32 1 > /dev/null;
		service call wifi 13 i32 1 > /dev/null;
	fi;

	log -p i -t $FILE_NAME "*** WIFI ***: ${state}";
}

WIFI()
{
	local state="$1";

	if [ "${state}" == "sleep" ]; then
		WIFI_PM "sleep";
		if [ "$cortexbrain_auto_tweak_wifi" == on ]; then
			if [ -e /sys/module/dhd/initstate ]; then
				if [ "$cortexbrain_auto_tweak_wifi_sleep_delay" == 0 ]; then
					WIFI_SET "off";
				else
					(
						echo "0" > $wifi_helper_tmp;
						# screen time out but user want to keep it on and have wifi
						sleep 10;
						if [ `cat $wifi_helper_tmp` == 0 ]; then
							# user did not turned screen on, so keep waiting
							SLEEP_TIME_WIFI=$(( $cortexbrain_auto_tweak_wifi_sleep_delay - 10 ));
							log -p i -t $FILE_NAME "*** DISABLE_WIFI $cortexbrain_auto_tweak_wifi_sleep_delay Sec Delay Mode ***";
							sleep $SLEEP_TIME_WIFI;
							if [ `cat $wifi_helper_tmp` == 0 ]; then
								# user left the screen off, then disable wifi
								WIFI_SET "off";
							fi;
						fi;
					)&
				fi;
			else
				wifi_helper_awake=0;
			fi;
		fi;
	elif [ "${state}" == "awake" ]; then
		WIFI_PM "awake";
		if [ "$cortexbrain_auto_tweak_wifi" == on ]; then
			echo "1" > $wifi_helper_tmp;
			if [ "$wifi_helper_awake" == 1 ]; then
				WIFI_SET "on";
			fi;
		fi;
	fi;
}

MOBILE_DATA_SET()
{
	local state="$1";

	if [ "${state}" == "off" ]; then
		svc data disable;
		# not declared as local - therefore, it's global
		mobile_helper_awake=1;
	elif [ "${state}" == "on" ]; then
		svc data enable;
	fi;

	log -p i -t $FILE_NAME "*** MOBILE DATA ***: ${state}";
}

MOBILE_DATA()
{
	local state="$1";
	if [ "$cortexbrain_auto_tweak_mobile" == on ]; then
		if [ "${state}" == "sleep" ]; then
			local DATA_STATE=`echo "$TELE_DATA" | awk '/mDataConnectionState/ {print $1}'`;
			if [ "$DATA_STATE" != "mDataConnectionState=0" ]; then
				if [ "$cortexbrain_auto_tweak_mobile_sleep_delay" == 0 ]; then
					MOBILE_DATA_SET "off";
				else
					(
						echo "0" > $mobile_helper_tmp;
						# screen time out but user want to keep it on and have mobile data
						sleep 10;
						if [ `cat $mobile_helper_tmp` == 0 ]; then
							# user did not turned screen on, so keep waiting
							SLEEP_TIME_DATA=$(( $cortexbrain_auto_tweak_mobile_sleep_delay - 10 ));
							log -p i -t $FILE_NAME "*** DISABLE_MOBILE $cortexbrain_auto_tweak_mobile_sleep_delay Sec Delay Mode ***";
							sleep $SLEEP_TIME_DATA;
							if [ `cat $mobile_helper_tmp` == 0 ]; then
								# user left the screen off, then disable mobile data
								MOBILE_DATA_SET "off";
							fi;
						fi;
					)&
				fi;
			else
				mobile_helper_awake=0;
			fi;
		elif [ "${state}" == "awake" ]; then
			echo "1" > $mobile_helper_tmp;
			if [ "$mobile_helper_awake" == 1 ]; then
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

	if [ "${state}" == "awake" ]; then
		if [ "$android_logger" == auto ] || [ "$android_logger" == debug ]; then
			if [ -e $dev_log_sleep ] && [ ! -e $dev_log ]; then
				mv $dev_log_sleep $dev_log
			fi;
		fi;
	elif [ "${state}" == "sleep" ]; then
		if [ "$android_logger" == auto ] || [ "$android_logger" == disabled ]; then
			if [ -e $dev_log ]; then
				mv $dev_log $dev_log_sleep;
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
	if [ ! -e ${DATA_DIR}/booting ]; then
		if [ "$wakeup_delay" != 0 ]; then
			log -p i -t $FILE_NAME "*** DELAY ${delay}sec ***";
			sleep $wakeup_delay;
		fi;
	fi;

	log -p i -t $FILE_NAME "*** NO DELAY ***";
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

BUS_THRESHOLD()
{
	local state="$1";

	if [ "${state}" == "awake" ]; then
		echo "$busfreq_up_threshold" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;
	elif [ "${state}" == "sleep" ]; then
		echo "80" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;
	elif [ "${state}" == "performance" ]; then
		echo "25" > /sys/devices/system/cpu/cpufreq/busfreq_up_threshold;
	fi;

	log -p i -t $FILE_NAME "*** BUS_THRESHOLD: ${state} ***";
}

VFS_CACHE_PRESSURE()
{
	local state="$1";
	local sys_vfs_cache="/proc/sys/vm/vfs_cache_pressure";

	if [ "${state}" == "awake" ]; then
		echo "10" > $sys_vfs_cache;
	elif [ "${state}" == "sleep" ]; then
		echo "60" > $sys_vfs_cache;
	fi;

	log -p i -t $FILE_NAME "*** VFS_CACHE_PRESSURE: ${state} ***";
}

TWEAK_HOTPLUG_LOAD()
{
	local state="$1";
	local sys_load_h0="/sys/module/stand_hotplug/parameters/load_h0";
	local sys_load_l1="/sys/module/stand_hotplug/parameters/load_l1";

	if [ "${state}" == "awake" ]; then
		echo "$load_h0" > $sys_load_h0;
		echo "$load_l1" > $sys_load_l1;
	elif [ "${state}" == "sleep" ]; then
		echo "50" > $sys_load_h0;
		echo "50" > $sys_load_h1;
	elif [ "${state}" == "performance" ]; then
		echo "20" > $sys_load_h0;
		echo "20" > $sys_load_l1;
	fi;

	log -p i -t $FILE_NAME "*** TWEAK_HOTPLUG_LOAD: ${state} ***";
}

# boost CPU power for fast and no lag wakeup
MEGA_BOOST_CPU_TWEAKS()
{
	if [ "$cortexbrain_cpu" == on ]; then
		echo "$scaling_governor" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;

		CPU_GOV_TWEAKS "performance";

		MALI_TIMEOUT "performance";

		BUS_THRESHOLD "performance";

		TWEAK_HOTPLUG_LOAD "performance";

		if [ "$scaling_max_freq" == 1000000 ] && [ "$scaling_max_freq_oc" -ge 1000000 ]; then
			echo "$scaling_max_freq_oc" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			echo "$scaling_max_freq_oc" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
		elif [ "$scaling_max_freq" -ge 1000000 ]; then
			echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
		else
			echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
			echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
		fi;

		echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
		echo "1000000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_suspend_freq;

		log -p i -t $FILE_NAME "*** MEGA_BOOST_CPU_TWEAKS ***";
	else
		MAX_FREQ=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq`;
		echo "$MAX_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
	fi;
}

BOOST_DELAY()
{
	# check if ROM booting now, then don't wait - creation and deletion of ${DATA_DIR}/booting @> /sbin/ext/post-init.sh
	if [ "$wakeup_boost" != 0 ] && [ ! -e ${DATA_DIR}/booting ]; then
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

NET()
{
	local state="$1";

	if [ "${state}" == "awake" ]; then
		echo "1800" > /proc/sys/net/ipv4/tcp_keepalive_time;
	elif [ "${state}" == "sleep" ]; then
		echo "7200" > /proc/sys/net/ipv4/tcp_keepalive_time;
	fi;

	log -p i -t $FILE_NAME "*** NET ***: ${state}";	
}

KERNEL_SCHED()
{
	local state="$1";

	# this is the correct order to input this settings, every value will be x2 after set
	if [ "${state}" == "awake" ]; then
		sysctl -w kernel.sched_wakeup_granularity_ns=2000000 > /dev/null 2>&1;
		sysctl -w kernel.sched_min_granularity_ns=1500000 > /dev/null 2>&1;
		sysctl -w kernel.sched_latency_ns=12000000 > /dev/null 2>&1;
	elif [ "${state}" == "sleep" ]; then
		sysctl -w kernel.sched_wakeup_granularity_ns=1000000 > /dev/null 2>&1;
		sysctl -w kernel.sched_min_granularity_ns=750000 > /dev/null 2>&1;
		sysctl -w kernel.sched_latency_ns=6000000 > /dev/null 2>&1;
	fi;

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
	echo "$mov_hysti" > /sys/bus/i2c/devices/3-004a/mov_hysti;

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

	log -p i -t $FILE_NAME "*** ENABLEMASK: ${state} ***: done";
}

IO_SCHEDULER()
{
	local state="$1";
	local sys_mmc0_scheduler="/sys/block/mmcblk0/queue/scheduler";
	local sys_mmc1_scheduler="/sys/block/mmcblk1/queue/scheduler";

	if [ "${state}" == "awake" ]; then
		echo "$scheduler" > $sys_mmc0_scheduler;
		echo "$scheduler" > $sys_mmc1_scheduler;
	elif [ "${state}" == "sleep" ]; then
		echo "$sleep_scheduler" > $sys_mmc0_scheduler;
		echo "$sleep_scheduler" > $sys_mmc1_scheduler;
	fi;

	log -p i -t $FILE_NAME "*** IO_SCHEDULER: ${state} ***: done";	
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	ENABLEMASK "awake";

	if [ "$sleeprun" == 1 ]; then

		LOGGER "awake";

		DELAY;

		KERNEL_SCHED "awake";

		NET "awake";

		MOBILE_DATA "awake";

		WIFI "awake";

		MEGA_BOOST_CPU_TWEAKS;

		IO_SCHEDULER "awake";

		GESTURES "awake";

		GAMMA_FIX;

		TOUCH_KEYS_CORRECTION;

		MOUNT_SD_CARD;

		if [ "$cortexbrain_ksm_control" == on ] && [ "$KSM_TOTAL" != "" ]; then
			ADJUST_KSM;
		fi;

		echo "$pwm_val" > /sys/vibrator/pwm_val;

		BOOST_DELAY;

		VFS_CACHE_PRESSURE "awake";

		CPU_GOV_TWEAKS "awake";

		TWEAK_HOTPLUG_LOAD "awake";

		if [ "$cortexbrain_cpu" == on ]; then
			echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_suspend_freq;

			if [ "$scaling_max_freq" == 1000000 ] && [ "$scaling_max_freq_oc" -ge 1000000 ]; then
				echo "$scaling_max_freq_oc" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
				echo "$scaling_max_freq_oc" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
			else
				echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq;
				echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_suspend_freq;
			fi;
		fi;

		MALI_TIMEOUT "awake";

		BUS_THRESHOLD "awake";

		log -p i -t $FILE_NAME "*** AWAKE Normal Mode ***";
	fi;
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	sleeprun=0;

	# we only read the config when screen goes off ...
	PROFILE=`cat ${DATA_DIR}/.active.profile`;
	. ${DATA_DIR}/${PROFILE}.profile;

	DELAY;

	TELE_DATA=`dumpsys telephony.registry`;

	ENABLEMASK "sleep";

	if [ "$DUMPSYS" == 1 ]; then
		# check the call state, not on call = 0, on call = 2
		CALL_STATE=`echo "${TELE_DATA}" | awk '/mCallState/ {print $1}'`;
		if [ "$CALL_STATE" == "mCallState=0" ]; then
			CALL_STATE=0;
		else
			CALL_STATE=2;
		fi;
	else
		CALL_STATE=0;
	fi;

	local TMP_EARLY_WAKEUP=`cat /tmp/early_wakeup`;
	if [ "$TMP_EARLY_WAKEUP" == 0 ] && [ "$CALL_STATE" == 0 ]; then

		sleeprun=1;

		if [ "$cortexbrain_cpu" == on ]; then
			echo "$standby_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
			echo "$standby_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_suspend_freq;
		fi;

		MALI_TIMEOUT "sleep";

		BUS_THRESHOLD "sleep";

		KERNEL_SCHED "sleep";

		NET "sleep";

		WIFI "sleep";

		MOBILE_DATA "sleep";

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

			IO_SCHEDULER "sleep";

			TWEAK_HOTPLUG_LOAD "sleep";

			VFS_CACHE_PRESSURE "sleep";
		
			log -p i -t $FILE_NAME "*** SLEEP mode ***";

			LOGGER "sleep";
		else
			echo "USB CABLE CONNECTED! No real sleep mode!"
			log -p i -t $FILE_NAME "*** SCREEN OFF BUT POWERED mode ***";
		fi;
	else
		log -p i -t $FILE_NAME "*** Early WakeUp (${TMP_EARLY_WAKEUP}), or on call (${CALL_STATE})! SLEEP aborted! ***";

	fi;

	# kill wait_for_fb_wake generated by /sbin/ext/wakecheck.sh
	pkill -f "cat /sys/power/wait_for_fb_wake"
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
		sleep 2;

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
