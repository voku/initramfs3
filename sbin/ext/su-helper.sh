#!/sbin/busybox sh
# root installation helper by GM
rm /data/.siyah/install-root > /dev/null 2>&1
(
while : ; do
	# keep this running until we have root
	if [ -e /data/.siyah/install-root ] ; then
		rm /data/.siyah/install-root
		/sbin/busybox sh /sbin/ext/install.sh
		# Restore witch if exist
		if [ -e /system/xbin/waswhich-bkp ]; then
		cp /system/xbin/waswhich-bkp /system/xbin/which
		fi
        	exit 0
	fi
	if [ -e /system/xbin/su ] ; then
                exit 0
        fi
        sleep 5
done
) &

