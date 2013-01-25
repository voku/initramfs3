#!/sbin/busybox

JBSAMMY=0;
[ "`/sbin/busybox grep -i ro.build.PDA=I9100XXLSJ /system/build.prop`" ] && JBSAMMY=1;
[ "`/sbin/busybox grep -i ro.build.PDA=I9100XWLS8 /system/build.prop`" ] && JBSAMMY=1;

if [ "$JBSAMMY" == 1 ] || [ ! -e /system/etc/dm_kernel ]; then

        mount -o remount,rw /system;

        GPIOKEYS="/system/usr/keylayout/gpio-keys.kl";
        if [ -e $GPIOKEYS ]; then
                KHCOUNT=`cat $GPIOKEYS | grep "102" -c`;
                if [ $KHCOUNT == 1 ]; then
                        sed -i 's/102/172/g' $GPIOKEYS;
                fi;
        fi;
fi;

if [ -e /system/etc/dm_kernel ]; then
	rm -f /system/etc/dm_kernel;
fi;

