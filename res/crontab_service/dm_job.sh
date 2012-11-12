#!/sbin/busybox sh

# Created By Dorimanx and Dairinin

if [ "a$1" != "a" ] && [ -e /system/xbin/busybox ]; then
	cron_localtime () {
		local localtime=$1;
		shift;
		date -u --date=@$(date --date="$localtime" +%s) "+%-M %-H * * *    $*";
	}

	plan_cron_job () {
		local desired_time=$1;
		shift;
		local your_cron_job=$*;

		local tmpfile=$(mktemp);
		crontab -l > $tmpfile;
		# edit it, for example, cut existing job with sed
		sed -i "\~$your_cron_job~ d" $tmpfile;
		cron_localtime $desired_time $your_cron_job >> $tmpfile;
		crontab $tmpfile;
		rm -f $tmpfile;
	}
	plan_cron_job $1 $2
fi;

