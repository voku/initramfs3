#!/sbin/busybox sh

# FM radio, I have no idea why it isn't loaded in init -gm
Si4709="/lib/modules/Si4709_driver.ko";
if [ -e $Si4709 ]; then
	insmod $Si4709;
fi;

# load CIFS with all that needed
CIFS="/lib/modules/cifs.ko";
if [ -e $CIFS ]; then
	insmod $CIFS;
fi;

# for ntfs automounting
FUSE="/lib/modules/fuse.ko";
if [ -e $FUSE ]; then
	insmod $FUSE;
fi;

# enable KSM by default
KSM="/sys/kernel/mm/ksm/run";
if [ -e $KSM ]; then
	echo "1" > $KSM;
fi;

