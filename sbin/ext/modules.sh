#!/sbin/busybox sh

# FM radio
Si4709="/lib/modules/Si4709_driver.ko";
if [ -e $Si4709 ]; then
	insmod $Si4709;
fi;

# load CIFS with all that needed
CIFS="/lib/modules/cifs.ko";
if [ -e $CIFS ]; then
	insmod $CIFS;
fi;

# for NFS automounting
FUSE="/lib/modules/fuse.ko";
if [ -e $FUSE ]; then
	insmod $FUSE;
fi;

